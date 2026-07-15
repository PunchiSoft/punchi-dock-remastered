// SPDX-License-Identifier: GPL-3.0-or-later

#include "audiospectrumcontroller.h"

#include "pipewireaudiobackend.h"

#include <QSet>
#include <QTimer>

#include <algorithm>

class AudioSpectrumManager : public QObject
{
public:
    AudioSpectrumManager()
    {
        m_pollTimer.setInterval(40);
        m_pollTimer.setTimerType(Qt::CoarseTimer);
        connect(&m_pollTimer, &QTimer::timeout, this, [this] {
            pollBackend();
        });
    }

    ~AudioSpectrumManager() override
    {
        m_backend.stop();
    }

    void addConsumer(AudioSpectrumController *controller)
    {
        if (!controller || m_consumers.contains(controller)) {
            return;
        }

        m_consumers.insert(controller);
        if (m_consumers.size() == 1) {
            m_lastGeneration = 0;
            m_lastState = PipeWireAudioBackend::State::Stopped;
            m_retryTicks = 0;
            m_backend.start();
            m_pollTimer.start();
        }
        pollBackend();
    }

    void removeConsumer(AudioSpectrumController *controller)
    {
        m_consumers.remove(controller);
        if (m_consumers.isEmpty()) {
            m_pollTimer.stop();
            m_backend.stop();
            m_lastGeneration = 0;
            m_lastState = PipeWireAudioBackend::State::Stopped;
        }
    }

private:
    void pollBackend()
    {
        if (m_consumers.isEmpty()) {
            return;
        }

        auto state = m_backend.state();
        const bool connectionNeedsRecovery = state == PipeWireAudioBackend::State::Error
            || state == PipeWireAudioBackend::State::Connecting
            || state == PipeWireAudioBackend::State::Stopped;
        if (connectionNeedsRecovery) {
            ++m_retryTicks;
            if (m_retryTicks >= 125) {
                m_retryTicks = 0;
                m_backend.stop();
                m_backend.start();
                state = m_backend.state();
            }
        } else {
            m_retryTicks = 0;
        }

        const std::uint64_t generation = m_backend.generation();
        if (generation == m_lastGeneration && state == m_lastState) {
            return;
        }

        m_lastGeneration = generation;
        m_lastState = state;
        const bool available = state == PipeWireAudioBackend::State::Paused
            || state == PipeWireAudioBackend::State::Streaming;

        SpectrumAnalyzer::Levels nativeLevels{};
        if (state == PipeWireAudioBackend::State::Streaming) {
            nativeLevels = m_backend.levels();
        }

        QVariantList levels;
        levels.reserve(static_cast<qsizetype>(nativeLevels.size()));
        float strongestLevel = 0.0F;
        for (const float level : nativeLevels) {
            levels.append(level);
            strongestLevel = std::max(strongestLevel, level);
        }
        const bool active = available && strongestLevel >= 0.02F;

        const auto consumers = m_consumers;
        for (AudioSpectrumController *controller : consumers) {
            if (controller) {
                controller->applySnapshot(levels, available, active);
            }
        }
    }

    PipeWireAudioBackend m_backend;
    QTimer m_pollTimer;
    QSet<AudioSpectrumController *> m_consumers;
    std::uint64_t m_lastGeneration = 0;
    PipeWireAudioBackend::State m_lastState = PipeWireAudioBackend::State::Stopped;
    int m_retryTicks = 0;
};

namespace
{
AudioSpectrumManager &sharedManager()
{
    static auto *manager = new AudioSpectrumManager;
    return *manager;
}

QVariantList silentLevels()
{
    QVariantList levels;
    levels.reserve(static_cast<qsizetype>(SpectrumAnalyzer::BandCount));
    for (std::size_t band = 0; band < SpectrumAnalyzer::BandCount; ++band) {
        levels.append(0.0F);
    }
    return levels;
}
}

AudioSpectrumController::AudioSpectrumController(QObject *parent)
    : QObject(parent)
    , m_levels(silentLevels())
{
}

AudioSpectrumController::~AudioSpectrumController()
{
    if (m_enabled) {
        sharedManager().removeConsumer(this);
    }
}

bool AudioSpectrumController::enabled() const
{
    return m_enabled;
}

void AudioSpectrumController::setEnabled(bool enabled)
{
    if (m_enabled == enabled) {
        return;
    }

    m_enabled = enabled;
    if (m_enabled) {
        sharedManager().addConsumer(this);
    } else {
        sharedManager().removeConsumer(this);
        clearSnapshot();
    }
    Q_EMIT enabledChanged();
}

bool AudioSpectrumController::available() const
{
    return m_available;
}

bool AudioSpectrumController::active() const
{
    return m_active;
}

QVariantList AudioSpectrumController::levels() const
{
    return m_levels;
}

void AudioSpectrumController::applySnapshot(const QVariantList &levels, bool available, bool active)
{
    if (!m_enabled) {
        return;
    }

    if (m_levels != levels) {
        m_levels = levels;
        Q_EMIT levelsChanged();
    }
    if (m_available != available) {
        m_available = available;
        Q_EMIT availableChanged();
    }
    if (m_active != active) {
        m_active = active;
        Q_EMIT activeChanged();
    }
}

void AudioSpectrumController::clearSnapshot()
{
    const QVariantList levels = silentLevels();
    if (m_levels != levels) {
        m_levels = levels;
        Q_EMIT levelsChanged();
    }
    if (m_available) {
        m_available = false;
        Q_EMIT availableChanged();
    }
    if (m_active) {
        m_active = false;
        Q_EMIT activeChanged();
    }
}
