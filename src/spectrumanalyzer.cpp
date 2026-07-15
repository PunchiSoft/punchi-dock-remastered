// SPDX-License-Identifier: GPL-3.0-or-later

#include "spectrumanalyzer.h"

#include <algorithm>
#include <cmath>
#include <numbers>

namespace
{
constexpr std::array<float, SpectrumAnalyzer::BandCount> bandFrequencies = {
    50.0F,
    63.0F,
    80.0F,
    100.0F,
    125.0F,
    160.0F,
    200.0F,
    250.0F,
    315.0F,
    400.0F,
    500.0F,
    630.0F,
    800.0F,
    1000.0F,
    1250.0F,
    1600.0F,
    2000.0F,
    2500.0F,
    3150.0F,
    4000.0F,
    5000.0F,
    6300.0F,
    8000.0F,
    10000.0F,
};

constexpr float minimumDecibels = -65.0F;
constexpr float decibelRange = 55.0F;
}

SpectrumAnalyzer::SpectrumAnalyzer()
{
    configure(m_sampleRate);
}

void SpectrumAnalyzer::configure(std::uint32_t sampleRate)
{
    m_sampleRate = std::max<std::uint32_t>(sampleRate, 8000);
    for (std::size_t band = 0; band < BandCount; ++band) {
        const float normalizedFrequency = bandFrequencies[band] / static_cast<float>(m_sampleRate);
        m_coefficients[band] = 2.0F * std::cos(2.0F * std::numbers::pi_v<float> * normalizedFrequency);
    }
    reset();
}

void SpectrumAnalyzer::reset()
{
    m_samples.fill(0.0F);
    m_levels.fill(0.0F);
    m_sampleIndex = 0;
}

bool SpectrumAnalyzer::processInterleaved(const float *samples, std::size_t frameCount, std::uint32_t channelCount)
{
    if (!samples || frameCount == 0 || channelCount == 0) {
        return false;
    }

    bool analyzed = false;
    const std::uint32_t channelsToMix = std::min<std::uint32_t>(channelCount, 8);
    for (std::size_t frame = 0; frame < frameCount; ++frame) {
        float monoSample = 0.0F;
        const std::size_t frameOffset = frame * channelCount;
        for (std::uint32_t channel = 0; channel < channelsToMix; ++channel) {
            const float sample = samples[frameOffset + channel];
            monoSample += std::isfinite(sample) ? sample : 0.0F;
        }

        m_samples[m_sampleIndex++] = monoSample / static_cast<float>(channelsToMix);
        if (m_sampleIndex == WindowSize) {
            analyzeWindow();
            m_sampleIndex = 0;
            analyzed = true;
        }
    }
    return analyzed;
}

const SpectrumAnalyzer::Levels &SpectrumAnalyzer::levels() const
{
    return m_levels;
}

void SpectrumAnalyzer::analyzeWindow()
{
    for (std::size_t band = 0; band < BandCount; ++band) {
        float previous = 0.0F;
        float previousPrevious = 0.0F;
        const float coefficient = m_coefficients[band];

        for (std::size_t sampleIndex = 0; sampleIndex < WindowSize; ++sampleIndex) {
            const float phase = static_cast<float>(sampleIndex) / static_cast<float>(WindowSize - 1);
            const float window = 0.5F - 0.5F * std::cos(2.0F * std::numbers::pi_v<float> * phase);
            const float current = (m_samples[sampleIndex] * window) + (coefficient * previous) - previousPrevious;
            previousPrevious = previous;
            previous = current;
        }

        const float power = std::max(0.0F,
                                     (previous * previous) + (previousPrevious * previousPrevious)
                                         - (coefficient * previous * previousPrevious));
        const float amplitude = (2.0F * std::sqrt(power)) / static_cast<float>(WindowSize);
        const float decibels = 20.0F * std::log10(std::max(amplitude, 0.000001F));
        float normalized = std::clamp((decibels - minimumDecibels) / decibelRange, 0.0F, 1.0F);
        if (normalized < 0.015F) {
            normalized = 0.0F;
        }

        const float smoothing = normalized > m_levels[band] ? 0.62F : 0.20F;
        m_levels[band] += (normalized - m_levels[band]) * smoothing;
        if (m_levels[band] < 0.005F) {
            m_levels[band] = 0.0F;
        }
    }
}
