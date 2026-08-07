/*
    SPDX-FileCopyrightText: 2014 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>
    SPDX-FileCopyrightText: 2023 David Redondo <kde@david-redondo.de>
    SPDX-FileCopyrightText: 2026 punchisoft

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

// Adapted from Plasma Workspace's UserDelegate shader. The avatar, border and
// transparent edge are blended in one pass to keep their circular boundaries
// aligned at subpixel precision.

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 colorBorder;
};
layout(binding = 1) uniform sampler2D avatarTexture;
layout(location = 0) out vec4 fragColor;

const highp float blend = 0.01;
const highp float innerRadius = 0.47;
const highp float outerRadius = 0.49;
const lowp vec4 colorEmpty = vec4(0.0, 0.0, 0.0, 0.0);

void main()
{
    lowp vec4 colorSource = texture(avatarTexture, qt_TexCoord0);
    highp vec2 centeredCoordinate = qt_TexCoord0 - vec2(0.5, 0.5);
    highp float distanceFromCenter = length(centeredCoordinate);

    if (distanceFromCenter < innerRadius) {
        fragColor = colorSource;
    } else if (distanceFromCenter < innerRadius + blend) {
        fragColor = mix(colorSource, colorBorder,
            (distanceFromCenter - innerRadius) / blend);
    } else if (distanceFromCenter < outerRadius) {
        fragColor = colorBorder;
    } else if (distanceFromCenter < outerRadius + blend) {
        fragColor = mix(colorBorder, colorEmpty,
            (distanceFromCenter - outerRadius) / blend);
    } else {
        fragColor = colorEmpty;
    }

    fragColor *= qt_Opacity;
}
