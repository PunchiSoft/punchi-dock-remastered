// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <array>
#include <cstddef>
#include <cstdint>

class SpectrumAnalyzer
{
public:
    static constexpr std::size_t BandCount = 24;
    static constexpr std::size_t WindowSize = 1024;
    using Levels = std::array<float, BandCount>;

    SpectrumAnalyzer();

    void configure(std::uint32_t sampleRate);
    void reset();
    bool processInterleaved(const float *samples, std::size_t frameCount, std::uint32_t channelCount);

    const Levels &levels() const;

private:
    void analyzeWindow();

    std::array<float, WindowSize> m_samples{};
    std::array<float, BandCount> m_coefficients{};
    Levels m_levels{};
    std::size_t m_sampleIndex = 0;
    std::uint32_t m_sampleRate = 48000;
};
