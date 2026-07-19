// SPDX-License-Identifier: GPL-3.0-or-later

#include "spectrumanalyzer.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <iostream>
#include <numbers>
#include <vector>

namespace
{
constexpr std::uint32_t sampleRate = 48000;

bool allBelow(const SpectrumAnalyzer::Levels &levels, float limit)
{
    return std::all_of(levels.cbegin(), levels.cend(), [limit](float level) {
        return level < limit;
    });
}

bool testSilence()
{
    SpectrumAnalyzer analyzer;
    std::vector<float> silence(SpectrumAnalyzer::WindowSize * 2 * 2, 0.0F);
    analyzer.processInterleaved(silence.data(), SpectrumAnalyzer::WindowSize * 2, 2);
    return allBelow(analyzer.levels(), 0.001F);
}

bool testOneKilohertzBand()
{
    SpectrumAnalyzer analyzer;
    std::vector<float> samples(SpectrumAnalyzer::WindowSize * 4 * 2);
    for (std::size_t frame = 0; frame < SpectrumAnalyzer::WindowSize * 4; ++frame) {
        const float sample = 0.7F * std::sin(2.0F * std::numbers::pi_v<float> * 1000.0F
                                            * static_cast<float>(frame) / static_cast<float>(sampleRate));
        samples[frame * 2] = sample;
        samples[(frame * 2) + 1] = sample;
    }

    analyzer.processInterleaved(samples.data(), SpectrumAnalyzer::WindowSize * 4, 2);
    const auto &levels = analyzer.levels();
    const auto strongest = static_cast<std::size_t>(std::distance(levels.cbegin(), std::max_element(levels.cbegin(), levels.cend())));
    return strongest == 13 && levels[strongest] > 0.75F;
}

bool testInvalidSamplesRemainFinite()
{
    SpectrumAnalyzer analyzer;
    std::vector<float> samples(SpectrumAnalyzer::WindowSize * 2, std::numeric_limits<float>::quiet_NaN());
    analyzer.processInterleaved(samples.data(), SpectrumAnalyzer::WindowSize, 2);
    return std::all_of(analyzer.levels().cbegin(), analyzer.levels().cend(), [](float level) {
        return std::isfinite(level);
    });
}
}

int main()
{
    const std::array tests = {
        std::pair{"silence", testSilence()},
        std::pair{"one kilohertz", testOneKilohertzBand()},
        std::pair{"invalid samples", testInvalidSamplesRemainFinite()},
    };

    bool passed = true;
    for (const auto &[name, result] : tests) {
        if (!result) {
            std::cerr << "FAILED: " << name << '\n';
            passed = false;
        }
    }
    return passed ? 0 : 1;
}
