// SPDX-License-Identifier: GPL-3.0-or-later

#include "pipewireaudiobackend.h"

#include <algorithm>
#include <chrono>
#include <iostream>
#include <thread>

namespace
{
const char *stateName(PipeWireAudioBackend::State state)
{
    switch (state) {
    case PipeWireAudioBackend::State::Stopped:
        return "stopped";
    case PipeWireAudioBackend::State::Connecting:
        return "connecting";
    case PipeWireAudioBackend::State::Paused:
        return "paused";
    case PipeWireAudioBackend::State::Streaming:
        return "streaming";
    case PipeWireAudioBackend::State::Error:
        return "error";
    }
    return "unknown";
}
}

int main()
{
    PipeWireAudioBackend backend;
    if (!backend.start()) {
        std::cerr << "PipeWire backend could not start\n";
        return 1;
    }

    float strongestLevel = 0.0F;
    PipeWireAudioBackend::State lastState = backend.state();
    for (int attempt = 0; attempt < 150; ++attempt) {
        std::this_thread::sleep_for(std::chrono::milliseconds(20));
        lastState = backend.state();
        const auto levels = backend.levels();
        strongestLevel = std::max(strongestLevel, *std::max_element(levels.cbegin(), levels.cend()));
        if (lastState == PipeWireAudioBackend::State::Error) {
            break;
        }
    }

    backend.stop();
    std::cout << "state=" << stateName(lastState) << " strongestLevel=" << strongestLevel << '\n';
    return lastState == PipeWireAudioBackend::State::Paused
            || lastState == PipeWireAudioBackend::State::Streaming
        ? 0
        : 1;
}
