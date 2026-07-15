// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include "spectrumanalyzer.h"

#include <cstdint>
#include <memory>

class PipeWireAudioBackend
{
public:
    enum class State : std::uint8_t {
        Stopped,
        Connecting,
        Paused,
        Streaming,
        Error,
    };

    PipeWireAudioBackend();
    ~PipeWireAudioBackend();

    PipeWireAudioBackend(const PipeWireAudioBackend &) = delete;
    PipeWireAudioBackend &operator=(const PipeWireAudioBackend &) = delete;

    bool start();
    void stop();

    State state() const;
    std::uint64_t generation() const;
    SpectrumAnalyzer::Levels levels() const;

private:
    class Private;
    std::unique_ptr<Private> d;
};
