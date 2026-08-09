/*
    SPDX-FileCopyrightText: 2026 punchisoft

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// Rounded-rectangle SDF. The derivative-sized transition keeps the edge close
// to one physical pixel across fractional display scales.

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 roundedGeometry;
};
layout(binding = 1) uniform sampler2D imageTexture;
layout(location = 0) out vec4 fragColor;

void main()
{
    highp vec2 surfaceSize = max(roundedGeometry.xy, vec2(1.0));
    highp float radius = clamp(roundedGeometry.z, 0.0,
        min(surfaceSize.x, surfaceSize.y) * 0.5);
    highp vec2 centeredPosition = qt_TexCoord0 * surfaceSize
        - surfaceSize * 0.5;
    highp vec2 distanceVector = abs(centeredPosition)
        - (surfaceSize * 0.5 - vec2(radius));
    highp float signedDistance = length(max(distanceVector, vec2(0.0)))
        + min(max(distanceVector.x, distanceVector.y), 0.0) - radius;
    highp float antialiasWidth = max(fwidth(signedDistance), 0.0001);
    highp float coverage = 1.0 - smoothstep(
        -antialiasWidth, antialiasWidth, signedDistance);

    fragColor = texture(imageTexture, qt_TexCoord0)
        * coverage * qt_Opacity;
}
