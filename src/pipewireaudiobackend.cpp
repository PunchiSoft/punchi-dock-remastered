// SPDX-License-Identifier: GPL-3.0-or-later

#include "pipewireaudiobackend.h"

#include <algorithm>
#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>

#include <pipewire/pipewire.h>
#include <spa/param/audio/format-utils.h>

class PipeWireAudioBackend::Private
{
public:
    Private()
    {
        for (auto &level : atomicLevels) {
            level.store(0.0F, std::memory_order_relaxed);
        }
    }

    ~Private()
    {
        stop();
    }

    bool start()
    {
        if (threadLoop) {
            return true;
        }

        state.store(State::Connecting, std::memory_order_release);
        pw_init(nullptr, nullptr);
        pipeWireInitialized = true;

        threadLoop = pw_thread_loop_new("punchi-dock-spectrum", nullptr);
        if (!threadLoop) {
            failStart();
            return false;
        }

        context = pw_context_new(pw_thread_loop_get_loop(threadLoop), nullptr, 0);
        if (!context) {
            failStart();
            return false;
        }

        core = pw_context_connect(context, nullptr, 0);
        if (!core) {
            failStart();
            return false;
        }

        stream = pw_stream_new(core,
                               "Punchi Dock spectrum",
                               pw_properties_new(PW_KEY_MEDIA_TYPE,
                                                 "Audio",
                                                 PW_KEY_MEDIA_CATEGORY,
                                                 "Monitor",
                                                 PW_KEY_MEDIA_ROLE,
                                                 "DSP",
                                                 PW_KEY_NODE_NAME,
                                                 "org.punchi.dock.spectrum",
                                                 PW_KEY_NODE_DESCRIPTION,
                                                 "Punchi Dock audio visualizer",
                                                 PW_KEY_NODE_PASSIVE,
                                                 "true",
                                                 PW_KEY_STREAM_CAPTURE_SINK,
                                                 "true",
                                                 PW_KEY_STREAM_MONITOR,
                                                 "true",
                                                 nullptr));
        if (!stream) {
            failStart();
            return false;
        }

        static const pw_stream_events streamEvents = [] {
            pw_stream_events events{};
            events.version = PW_VERSION_STREAM_EVENTS;
            events.state_changed = handleStateChanged;
            events.param_changed = handleParamChanged;
            events.process = handleProcess;
            return events;
        }();
        pw_stream_add_listener(stream, &streamListener, &streamEvents, this);

        spa_audio_info_raw requestedFormat{};
        requestedFormat.format = SPA_AUDIO_FORMAT_F32;
        requestedFormat.rate = 48000;
        requestedFormat.channels = 2;
        requestedFormat.position[0] = SPA_AUDIO_CHANNEL_FL;
        requestedFormat.position[1] = SPA_AUDIO_CHANNEL_FR;

        std::array<std::uint8_t, 1024> formatBuffer{};
        spa_pod_builder builder = SPA_POD_BUILDER_INIT(formatBuffer.data(), formatBuffer.size());
        const spa_pod *params[] = {
            spa_format_audio_raw_build(&builder, SPA_PARAM_EnumFormat, &requestedFormat),
        };

        const auto flags = static_cast<pw_stream_flags>(PW_STREAM_FLAG_AUTOCONNECT | PW_STREAM_FLAG_MAP_BUFFERS);
        if (!params[0] || pw_stream_connect(stream, PW_DIRECTION_INPUT, PW_ID_ANY, flags, params, 1) < 0) {
            failStart();
            return false;
        }

        if (pw_thread_loop_start(threadLoop) < 0) {
            failStart();
            return false;
        }

        loopStarted = true;
        return true;
    }

    void stop()
    {
        state.store(State::Stopped, std::memory_order_release);
        clearLevels();

        if (threadLoop && loopStarted) {
            pw_thread_loop_stop(threadLoop);
            loopStarted = false;
        }
        if (stream) {
            spa_hook_remove(&streamListener);
            pw_stream_destroy(stream);
            stream = nullptr;
        }
        if (core) {
            pw_core_disconnect(core);
            core = nullptr;
        }
        if (context) {
            pw_context_destroy(context);
            context = nullptr;
        }
        if (threadLoop) {
            pw_thread_loop_destroy(threadLoop);
            threadLoop = nullptr;
        }
        if (pipeWireInitialized) {
            pw_deinit();
            pipeWireInitialized = false;
        }
        state.store(State::Stopped, std::memory_order_release);
    }

    void failStart()
    {
        stop();
        state.store(State::Error, std::memory_order_release);
    }

    static void handleStateChanged(void *userData, pw_stream_state, pw_stream_state newState, const char *)
    {
        auto *self = static_cast<Private *>(userData);
        switch (newState) {
        case PW_STREAM_STATE_CONNECTING:
            self->state.store(State::Connecting, std::memory_order_release);
            break;
        case PW_STREAM_STATE_PAUSED:
            self->state.store(State::Paused, std::memory_order_release);
            self->clearLevels();
            break;
        case PW_STREAM_STATE_STREAMING:
            self->state.store(State::Streaming, std::memory_order_release);
            break;
        case PW_STREAM_STATE_ERROR:
            self->state.store(State::Error, std::memory_order_release);
            self->clearLevels();
            break;
        case PW_STREAM_STATE_UNCONNECTED:
            self->state.store(State::Connecting, std::memory_order_release);
            self->clearLevels();
            break;
        }
    }

    static void handleParamChanged(void *userData, std::uint32_t id, const spa_pod *param)
    {
        if (id != SPA_PARAM_Format || !param) {
            return;
        }

        auto *self = static_cast<Private *>(userData);
        spa_audio_info_raw parsedFormat{};
        if (spa_format_audio_raw_parse(param, &parsedFormat) < 0 || parsedFormat.format != SPA_AUDIO_FORMAT_F32
            || parsedFormat.rate == 0 || parsedFormat.channels == 0) {
            self->formatValid = false;
            return;
        }

        self->format = parsedFormat;
        self->analyzer.configure(parsedFormat.rate);
        self->formatValid = true;
    }

    static void handleProcess(void *userData)
    {
        auto *self = static_cast<Private *>(userData);
        pw_buffer *pipeWireBuffer = pw_stream_dequeue_buffer(self->stream);
        if (!pipeWireBuffer) {
            return;
        }

        spa_buffer *buffer = pipeWireBuffer->buffer;
        if (self->formatValid && buffer && buffer->n_datas > 0) {
            spa_data &data = buffer->datas[0];
            if (data.data && data.chunk && data.chunk->offset < data.maxsize) {
                const std::size_t available = std::min<std::size_t>(data.chunk->size, data.maxsize - data.chunk->offset);
                const std::size_t bytesPerFrame = sizeof(float) * self->format.channels;
                const std::size_t frameCount = bytesPerFrame > 0 ? available / bytesPerFrame : 0;
                const auto *samples = reinterpret_cast<const float *>(static_cast<const std::uint8_t *>(data.data) + data.chunk->offset);
                if (self->analyzer.processInterleaved(samples, frameCount, self->format.channels)) {
                    self->publishLevels(self->analyzer.levels());
                }
            }
        }

        pw_stream_queue_buffer(self->stream, pipeWireBuffer);
    }

    void publishLevels(const SpectrumAnalyzer::Levels &levels)
    {
        for (std::size_t band = 0; band < levels.size(); ++band) {
            atomicLevels[band].store(levels[band], std::memory_order_relaxed);
        }
        levelGeneration.fetch_add(1, std::memory_order_release);
    }

    void clearLevels()
    {
        analyzer.reset();
        for (auto &level : atomicLevels) {
            level.store(0.0F, std::memory_order_relaxed);
        }
        levelGeneration.fetch_add(1, std::memory_order_release);
    }

    SpectrumAnalyzer::Levels readLevels() const
    {
        SpectrumAnalyzer::Levels result{};
        for (std::size_t band = 0; band < result.size(); ++band) {
            result[band] = atomicLevels[band].load(std::memory_order_relaxed);
        }
        return result;
    }

    pw_thread_loop *threadLoop = nullptr;
    pw_context *context = nullptr;
    pw_core *core = nullptr;
    pw_stream *stream = nullptr;
    spa_hook streamListener{};
    spa_audio_info_raw format{};
    SpectrumAnalyzer analyzer;
    std::array<std::atomic<float>, SpectrumAnalyzer::BandCount> atomicLevels{};
    std::atomic<std::uint64_t> levelGeneration = 0;
    std::atomic<State> state = State::Stopped;
    bool formatValid = false;
    bool loopStarted = false;
    bool pipeWireInitialized = false;
};

PipeWireAudioBackend::PipeWireAudioBackend()
    : d(std::make_unique<Private>())
{
}

PipeWireAudioBackend::~PipeWireAudioBackend() = default;

bool PipeWireAudioBackend::start()
{
    return d->start();
}

void PipeWireAudioBackend::stop()
{
    d->stop();
}

PipeWireAudioBackend::State PipeWireAudioBackend::state() const
{
    return d->state.load(std::memory_order_acquire);
}

std::uint64_t PipeWireAudioBackend::generation() const
{
    return d->levelGeneration.load(std::memory_order_acquire);
}

SpectrumAnalyzer::Levels PipeWireAudioBackend::levels() const
{
    return d->readLevels();
}
