// SPDX-License-Identifier: GPL-3.0-or-later

#include "dockthemevalidator.h"

#include <QColor>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QRegularExpression>
#include <QVariantList>

namespace
{
constexpr int maximumGradientStops = 8;
const QStringList separatorStyles{
    QStringLiteral("line"),
    QStringLiteral("dot"),
    QStringLiteral("capsule"),
};
const QStringList separatorPatternStyles{
    QStringLiteral("none"),
    QStringLiteral("dashed"),
    QStringLiteral("hazard"),
    QStringLiteral("centerLine"),
};

DockThemeValidator::Result failure(const QString &errorCode)
{
    return {false, {}, errorCode};
}

bool isAllowedColor(const QString &value)
{
    static const QRegularExpression colorPattern(QStringLiteral("^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$"));
    return colorPattern.match(value).hasMatch() && QColor::isValidColorName(value);
}

QString normalizedColor(const QString &value)
{
    const QColor color(value);
    return color.name(QColor::HexArgb);
}

bool readNumber(const QJsonObject &object, const QString &key, double defaultValue,
    double minimum, double maximum, double *result)
{
    if (!object.contains(key)) {
        *result = defaultValue;
        return true;
    }

    const QJsonValue value = object.value(key);
    if (!value.isDouble()) {
        return false;
    }

    const double number = value.toDouble();
    if (!qIsFinite(number) || number < minimum || number > maximum) {
        return false;
    }

    *result = number;
    return true;
}

bool readColor(const QJsonObject &object, const QString &key,
    const QString &defaultValue, QString *result)
{
    if (!object.contains(key)) {
        *result = defaultValue;
        return true;
    }

    const QJsonValue value = object.value(key);
    if (!value.isString() || !isAllowedColor(value.toString())) {
        return false;
    }

    *result = normalizedColor(value.toString());
    return true;
}

QString normalizedMetadataText(const QJsonObject &metadata, const QString &key,
    int maximumLength, bool required, bool *ok)
{
    const QJsonValue value = metadata.value(key);
    if (value.isUndefined() && !required) {
        return {};
    }
    if (!value.isString()) {
        *ok = false;
        return {};
    }

    const QString text = value.toString().trimmed();
    if ((required && text.isEmpty()) || text.size() > maximumLength) {
        *ok = false;
        return {};
    }
    return text;
}
}

DockThemeValidator::Result DockThemeValidator::validate(const QByteArray &data)
{
    if (data.isEmpty()) {
        return failure(QStringLiteral("emptyFile"));
    }
    if (data.size() > maximumFileSize) {
        return failure(QStringLiteral("fileTooLarge"));
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(data, &parseError);
    if (parseError.error != QJsonParseError::NoError) {
        return failure(QStringLiteral("invalidJson"));
    }
    if (!document.isObject()) {
        return failure(QStringLiteral("invalidRoot"));
    }

    const QJsonObject root = document.object();
    const QJsonValue schemaVersion = root.value(QStringLiteral("schemaVersion"));
    if (!schemaVersion.isDouble() || schemaVersion.toInt(-1) != 1
        || schemaVersion.toDouble() != 1.0) {
        return failure(QStringLiteral("unsupportedSchema"));
    }

    const QJsonValue metadataValue = root.value(QStringLiteral("metadata"));
    if (!metadataValue.isObject()) {
        return failure(QStringLiteral("invalidMetadata"));
    }

    bool metadataOk = true;
    const QJsonObject metadata = metadataValue.toObject();
    const QString name = normalizedMetadataText(metadata, QStringLiteral("name"), 80, true, &metadataOk);
    const QString author = normalizedMetadataText(metadata, QStringLiteral("author"), 80, false, &metadataOk);
    const QString version = normalizedMetadataText(metadata, QStringLiteral("version"), 32, false, &metadataOk);
    if (!metadataOk) {
        return failure(QStringLiteral("invalidMetadata"));
    }

    const QJsonValue rendererValue = root.value(QStringLiteral("renderer"));
    if (!rendererValue.isString()
        || (rendererValue.toString() != QLatin1String("flat")
            && rendererValue.toString() != QLatin1String("shelf"))) {
        return failure(QStringLiteral("unsupportedRenderer"));
    }
    const QString renderer = rendererValue.toString();

    const QJsonValue surfaceValue = root.value(QStringLiteral("surface"));
    if (!surfaceValue.isObject()) {
        return failure(QStringLiteral("invalidSurface"));
    }

    const QJsonObject surface = surfaceValue.toObject();
    QString surfaceColor;
    double radius = 0;
    if (!readColor(surface, QStringLiteral("color"), QStringLiteral("#e620242a"), &surfaceColor)
        || !readNumber(surface, QStringLiteral("radius"), 16, 0, 48, &radius)) {
        return failure(QStringLiteral("invalidSurface"));
    }

    QVariantList gradientStops;
    QString gradientDirection = QStringLiteral("vertical");
    const QJsonValue gradientValue = surface.value(QStringLiteral("gradient"));
    if (!gradientValue.isUndefined()) {
        if (!gradientValue.isObject()) {
            return failure(QStringLiteral("invalidGradient"));
        }

        const QJsonObject gradient = gradientValue.toObject();
        const QJsonValue directionValue = gradient.value(QStringLiteral("direction"));
        if (!directionValue.isUndefined()) {
            if (!directionValue.isString()
                || (directionValue.toString() != QLatin1String("vertical")
                    && directionValue.toString() != QLatin1String("horizontal"))) {
                return failure(QStringLiteral("invalidGradient"));
            }
            gradientDirection = directionValue.toString();
        }

        const QJsonValue stopsValue = gradient.value(QStringLiteral("stops"));
        if (!stopsValue.isArray()) {
            return failure(QStringLiteral("invalidGradient"));
        }

        const QJsonArray stops = stopsValue.toArray();
        if (stops.size() < 2 || stops.size() > maximumGradientStops) {
            return failure(QStringLiteral("invalidGradient"));
        }

        double previousPosition = -1;
        for (const QJsonValue &stopValue : stops) {
            if (!stopValue.isObject()) {
                return failure(QStringLiteral("invalidGradient"));
            }

            const QJsonObject stop = stopValue.toObject();
            double position = 0;
            QString color;
            if (!readNumber(stop, QStringLiteral("position"), -1, 0, 1, &position)
                || position < previousPosition
                || !readColor(stop, QStringLiteral("color"), QString(), &color)) {
                return failure(QStringLiteral("invalidGradient"));
            }

            previousPosition = position;
            gradientStops.append(QVariantMap{
                {QStringLiteral("position"), position},
                {QStringLiteral("color"), color},
            });
        }
    }

    if (gradientStops.isEmpty()) {
        gradientStops.append(QVariantMap{
            {QStringLiteral("position"), 0.0},
            {QStringLiteral("color"), surfaceColor},
        });
        gradientStops.append(QVariantMap{
            {QStringLiteral("position"), 1.0},
            {QStringLiteral("color"), surfaceColor},
        });
    }

    QVariantMap borderMap{
        {QStringLiteral("width"), 0.0},
        {QStringLiteral("color"), QStringLiteral("#00000000")},
    };
    const QJsonValue borderValue = surface.value(QStringLiteral("border"));
    if (!borderValue.isUndefined()) {
        if (!borderValue.isObject()) {
            return failure(QStringLiteral("invalidBorder"));
        }

        double borderWidth = 0;
        QString borderColor;
        const QJsonObject border = borderValue.toObject();
        if (!readNumber(border, QStringLiteral("width"), 0, 0, 4, &borderWidth)
            || !readColor(border, QStringLiteral("color"), QStringLiteral("#00000000"), &borderColor)) {
            return failure(QStringLiteral("invalidBorder"));
        }
        borderMap = {
            {QStringLiteral("width"), borderWidth},
            {QStringLiteral("color"), borderColor},
        };
    }

    QVariantMap shadowMap{
        {QStringLiteral("color"), QStringLiteral("#00000000")},
        {QStringLiteral("size"), 0.0},
        {QStringLiteral("xOffset"), 0.0},
        {QStringLiteral("yOffset"), 0.0},
    };
    const QJsonValue shadowValue = root.value(QStringLiteral("shadow"));
    if (!shadowValue.isUndefined()) {
        if (!shadowValue.isObject()) {
            return failure(QStringLiteral("invalidShadow"));
        }

        const QJsonObject shadow = shadowValue.toObject();
        QString shadowColor;
        double shadowSize = 0;
        double shadowXOffset = 0;
        double shadowYOffset = 0;
        if (!readColor(shadow, QStringLiteral("color"), QStringLiteral("#00000000"), &shadowColor)
            || !readNumber(shadow, QStringLiteral("size"), 0, 0, 8, &shadowSize)
            || !readNumber(shadow, QStringLiteral("xOffset"), 0, -4, 4, &shadowXOffset)
            || !readNumber(shadow, QStringLiteral("yOffset"), 0, -4, 4, &shadowYOffset)) {
            return failure(QStringLiteral("invalidShadow"));
        }
        shadowMap = {
            {QStringLiteral("color"), shadowColor},
            {QStringLiteral("size"), shadowSize},
            {QStringLiteral("xOffset"), shadowXOffset},
            {QStringLiteral("yOffset"), shadowYOffset},
        };
    }

    QVariantMap shelfMap;
    if (renderer == QLatin1String("shelf")) {
        const QJsonValue shelfValue = root.value(QStringLiteral("shelf"));
        if (!shelfValue.isObject()) {
            return failure(QStringLiteral("invalidShelf"));
        }

        const QJsonObject shelf = shelfValue.toObject();
        const QJsonValue geometryValue = shelf.value(QStringLiteral("geometry"));
        const QJsonValue edgeValue = shelf.value(QStringLiteral("edge"));
        const QJsonValue rimValue = shelf.value(QStringLiteral("rim"));
        if (!geometryValue.isObject() || !edgeValue.isObject() || !rimValue.isObject()) {
            return failure(QStringLiteral("invalidShelf"));
        }

        const QJsonObject geometry = geometryValue.toObject();
        double topAngle = 0;
        double edgeAngle = 0;
        double edgeDepth = 0;
        double rimThickness = 0;
        double horizontalInset = 0;
        double topDepthRatio = 0;
        double backInset = 0;
        double sideBevel = 0;
        if (!readNumber(geometry, QStringLiteral("topAngle"), 58, 35, 75, &topAngle)
            || !readNumber(geometry, QStringLiteral("edgeAngle"), -24, -45, -10, &edgeAngle)
            || !readNumber(geometry, QStringLiteral("edgeDepth"), 18, 8, 28, &edgeDepth)
            || !readNumber(geometry, QStringLiteral("rimThickness"), 3, 1, 8, &rimThickness)
            || !readNumber(geometry, QStringLiteral("horizontalInset"), 4, 0, 16, &horizontalInset)
            || !readNumber(geometry, QStringLiteral("topDepthRatio"), 0.56, 0.3, 0.8, &topDepthRatio)
            || !readNumber(geometry, QStringLiteral("backInset"), 20, 4, 48, &backInset)
            || !readNumber(geometry, QStringLiteral("sideBevel"), 5, 0, 12, &sideBevel)) {
            return failure(QStringLiteral("invalidShelf"));
        }

        const QJsonObject edge = edgeValue.toObject();
        QString edgeColor;
        double edgeRadius = 0;
        if (!readColor(edge, QStringLiteral("color"), QStringLiteral("#ff204860"), &edgeColor)
            || !readNumber(edge, QStringLiteral("radius"), 6, 0, 16, &edgeRadius)) {
            return failure(QStringLiteral("invalidShelf"));
        }

        QString edgeGradientDirection = QStringLiteral("vertical");
        QVariantList edgeGradientStops;
        const QJsonValue edgeGradientValue = edge.value(QStringLiteral("gradient"));
        if (!edgeGradientValue.isUndefined()) {
            if (!edgeGradientValue.isObject()) {
                return failure(QStringLiteral("invalidShelf"));
            }

            const QJsonObject edgeGradient = edgeGradientValue.toObject();
            const QJsonValue directionValue = edgeGradient.value(QStringLiteral("direction"));
            if (!directionValue.isUndefined()) {
                if (!directionValue.isString()
                    || (directionValue.toString() != QLatin1String("vertical")
                        && directionValue.toString() != QLatin1String("horizontal"))) {
                    return failure(QStringLiteral("invalidShelf"));
                }
                edgeGradientDirection = directionValue.toString();
            }

            const QJsonValue stopsValue = edgeGradient.value(QStringLiteral("stops"));
            if (!stopsValue.isArray()) {
                return failure(QStringLiteral("invalidShelf"));
            }

            const QJsonArray stops = stopsValue.toArray();
            if (stops.size() < 2 || stops.size() > maximumGradientStops) {
                return failure(QStringLiteral("invalidShelf"));
            }

            double previousPosition = -1;
            for (const QJsonValue &stopValue : stops) {
                if (!stopValue.isObject()) {
                    return failure(QStringLiteral("invalidShelf"));
                }

                const QJsonObject stop = stopValue.toObject();
                double position = 0;
                QString color;
                if (!readNumber(stop, QStringLiteral("position"), -1, 0, 1, &position)
                    || position < previousPosition
                    || !readColor(stop, QStringLiteral("color"), QString(), &color)) {
                    return failure(QStringLiteral("invalidShelf"));
                }
                previousPosition = position;
                edgeGradientStops.append(QVariantMap{
                    {QStringLiteral("position"), position},
                    {QStringLiteral("color"), color},
                });
            }
        }

        if (edgeGradientStops.isEmpty()) {
            edgeGradientStops.append(QVariantMap{
                {QStringLiteral("position"), 0.0},
                {QStringLiteral("color"), edgeColor},
            });
            edgeGradientStops.append(QVariantMap{
                {QStringLiteral("position"), 1.0},
                {QStringLiteral("color"), edgeColor},
            });
        }

        QVariantMap edgeBorderMap{
            {QStringLiteral("width"), 0.0},
            {QStringLiteral("color"), QStringLiteral("#00000000")},
        };
        const QJsonValue edgeBorderValue = edge.value(QStringLiteral("border"));
        if (!edgeBorderValue.isUndefined()) {
            if (!edgeBorderValue.isObject()) {
                return failure(QStringLiteral("invalidShelf"));
            }
            const QJsonObject edgeBorder = edgeBorderValue.toObject();
            double edgeBorderWidth = 0;
            QString edgeBorderColor;
            if (!readNumber(edgeBorder, QStringLiteral("width"), 0, 0, 3, &edgeBorderWidth)
                || !readColor(edgeBorder, QStringLiteral("color"), QStringLiteral("#00000000"), &edgeBorderColor)) {
                return failure(QStringLiteral("invalidShelf"));
            }
            edgeBorderMap = {
                {QStringLiteral("width"), edgeBorderWidth},
                {QStringLiteral("color"), edgeBorderColor},
            };
        }

        const QJsonObject rim = rimValue.toObject();
        QString rimColor;
        double rimOpacity = 0;
        if (!readColor(rim, QStringLiteral("color"), QStringLiteral("#ffa7edff"), &rimColor)
            || !readNumber(rim, QStringLiteral("opacity"), 1, 0, 1, &rimOpacity)) {
            return failure(QStringLiteral("invalidShelf"));
        }

        QVariantMap rimGlowMap{
            {QStringLiteral("size"), 0.0},
            {QStringLiteral("color"), QStringLiteral("#00000000")},
        };
        const QJsonValue rimGlowValue = rim.value(QStringLiteral("glow"));
        if (!rimGlowValue.isUndefined()) {
            if (!rimGlowValue.isObject()) {
                return failure(QStringLiteral("invalidShelf"));
            }
            const QJsonObject glow = rimGlowValue.toObject();
            double glowSize = 0;
            QString glowColor;
            if (!readNumber(glow, QStringLiteral("size"), 0, 0, 12, &glowSize)
                || !readColor(glow, QStringLiteral("color"), QStringLiteral("#00000000"), &glowColor)) {
                return failure(QStringLiteral("invalidShelf"));
            }
            rimGlowMap = {
                {QStringLiteral("size"), glowSize},
                {QStringLiteral("color"), glowColor},
            };
        }

        shelfMap = {
            {QStringLiteral("geometry"), QVariantMap{
                {QStringLiteral("topAngle"), topAngle},
                {QStringLiteral("edgeAngle"), edgeAngle},
                {QStringLiteral("edgeDepth"), edgeDepth},
                {QStringLiteral("rimThickness"), rimThickness},
                {QStringLiteral("horizontalInset"), horizontalInset},
                {QStringLiteral("topDepthRatio"), topDepthRatio},
                {QStringLiteral("backInset"), backInset},
                {QStringLiteral("sideBevel"), sideBevel},
            }},
            {QStringLiteral("edge"), QVariantMap{
                {QStringLiteral("color"), edgeColor},
                {QStringLiteral("radius"), edgeRadius},
                {QStringLiteral("gradient"), QVariantMap{
                    {QStringLiteral("direction"), edgeGradientDirection},
                    {QStringLiteral("stops"), edgeGradientStops},
                }},
                {QStringLiteral("border"), edgeBorderMap},
            }},
            {QStringLiteral("rim"), QVariantMap{
                {QStringLiteral("color"), rimColor},
                {QStringLiteral("opacity"), rimOpacity},
                {QStringLiteral("glow"), rimGlowMap},
            }},
        };
    }

    bool blurRequested = false;
    const QJsonValue effectsValue = root.value(QStringLiteral("effects"));
    if (!effectsValue.isUndefined()) {
        if (!effectsValue.isObject()) {
            return failure(QStringLiteral("invalidEffects"));
        }

        const QJsonValue blurValue = effectsValue.toObject().value(QStringLiteral("blurRequested"));
        if (!blurValue.isUndefined()) {
            if (!blurValue.isBool()) {
                return failure(QStringLiteral("invalidEffects"));
            }
            blurRequested = blurValue.toBool();
        }
    }

    QVariantMap separatorMap;
    const QJsonValue separatorValue = root.value(QStringLiteral("separator"));
    if (!separatorValue.isUndefined()) {
        if (!separatorValue.isObject()) {
            return failure(QStringLiteral("invalidSeparator"));
        }

        const QJsonObject separator = separatorValue.toObject();
        const QJsonValue styleValue = separator.value(QStringLiteral("style"));
        if (!styleValue.isString() || !separatorStyles.contains(styleValue.toString())) {
            return failure(QStringLiteral("invalidSeparator"));
        }

        QString separatorColor;
        double separatorThickness = 0;
        double separatorLengthRatio = 0;
        double separatorOpacity = 0;
        double separatorRadius = 0;
        if (!readColor(separator, QStringLiteral("color"), QStringLiteral("#66ffffff"), &separatorColor)
            || !readNumber(separator, QStringLiteral("thickness"), 2, 1, 28, &separatorThickness)
            || !readNumber(separator, QStringLiteral("lengthRatio"), 0.72, 0.2, 1, &separatorLengthRatio)
            || !readNumber(separator, QStringLiteral("opacity"), 1, 0, 1, &separatorOpacity)
            || !readNumber(separator, QStringLiteral("radius"), separatorThickness / 2, 0, 28, &separatorRadius)) {
            return failure(QStringLiteral("invalidSeparator"));
        }

        QString separatorGradientDirection = QStringLiteral("vertical");
        QVariantList separatorGradientStops;
        const QJsonValue separatorGradientValue = separator.value(QStringLiteral("gradient"));
        if (!separatorGradientValue.isUndefined()) {
            if (!separatorGradientValue.isObject()) {
                return failure(QStringLiteral("invalidSeparator"));
            }

            const QJsonObject separatorGradient = separatorGradientValue.toObject();
            const QJsonValue directionValue = separatorGradient.value(QStringLiteral("direction"));
            if (!directionValue.isUndefined()) {
                if (!directionValue.isString()
                    || (directionValue.toString() != QLatin1String("vertical")
                        && directionValue.toString() != QLatin1String("horizontal"))) {
                    return failure(QStringLiteral("invalidSeparator"));
                }
                separatorGradientDirection = directionValue.toString();
            }

            const QJsonValue stopsValue = separatorGradient.value(QStringLiteral("stops"));
            if (!stopsValue.isArray()) {
                return failure(QStringLiteral("invalidSeparator"));
            }

            const QJsonArray stops = stopsValue.toArray();
            if (stops.size() < 2 || stops.size() > maximumGradientStops) {
                return failure(QStringLiteral("invalidSeparator"));
            }

            double previousPosition = -1;
            for (const QJsonValue &stopValue : stops) {
                if (!stopValue.isObject()) {
                    return failure(QStringLiteral("invalidSeparator"));
                }

                const QJsonObject stop = stopValue.toObject();
                double position = 0;
                QString color;
                if (!readNumber(stop, QStringLiteral("position"), -1, 0, 1, &position)
                    || position < previousPosition
                    || !readColor(stop, QStringLiteral("color"), QString(), &color)) {
                    return failure(QStringLiteral("invalidSeparator"));
                }

                previousPosition = position;
                separatorGradientStops.append(QVariantMap{
                    {QStringLiteral("position"), position},
                    {QStringLiteral("color"), color},
                });
            }
        }

        if (separatorGradientStops.isEmpty()) {
            separatorGradientStops.append(QVariantMap{
                {QStringLiteral("position"), 0.0},
                {QStringLiteral("color"), separatorColor},
            });
            separatorGradientStops.append(QVariantMap{
                {QStringLiteral("position"), 1.0},
                {QStringLiteral("color"), separatorColor},
            });
        }

        QVariantMap separatorBorderMap{
            {QStringLiteral("width"), 0.0},
            {QStringLiteral("color"), QStringLiteral("#00000000")},
        };
        const QJsonValue separatorBorderValue = separator.value(QStringLiteral("border"));
        if (!separatorBorderValue.isUndefined()) {
            if (!separatorBorderValue.isObject()) {
                return failure(QStringLiteral("invalidSeparator"));
            }

            double separatorBorderWidth = 0;
            QString separatorBorderColor;
            const QJsonObject separatorBorder = separatorBorderValue.toObject();
            if (!readNumber(separatorBorder, QStringLiteral("width"), 0, 0, 2, &separatorBorderWidth)
                || !readColor(separatorBorder, QStringLiteral("color"), QStringLiteral("#00000000"), &separatorBorderColor)) {
                return failure(QStringLiteral("invalidSeparator"));
            }
            separatorBorderMap = {
                {QStringLiteral("width"), separatorBorderWidth},
                {QStringLiteral("color"), separatorBorderColor},
            };
        }

        QVariantMap separatorGlowMap{
            {QStringLiteral("size"), 0.0},
            {QStringLiteral("color"), QStringLiteral("#00000000")},
        };
        const QJsonValue separatorGlowValue = separator.value(QStringLiteral("glow"));
        if (!separatorGlowValue.isUndefined()) {
            if (!separatorGlowValue.isObject()) {
                return failure(QStringLiteral("invalidSeparator"));
            }

            double glowSize = 0;
            QString glowColor;
            const QJsonObject glow = separatorGlowValue.toObject();
            if (!readNumber(glow, QStringLiteral("size"), 0, 0, 12, &glowSize)
                || !readColor(glow, QStringLiteral("color"), QStringLiteral("#00000000"), &glowColor)) {
                return failure(QStringLiteral("invalidSeparator"));
            }
            separatorGlowMap = {
                {QStringLiteral("size"), glowSize},
                {QStringLiteral("color"), glowColor},
            };
        }

        QVariantMap separatorPatternMap{
            {QStringLiteral("style"), QStringLiteral("none")},
            {QStringLiteral("primaryColor"), QStringLiteral("#ffffffff")},
            {QStringLiteral("secondaryColor"), QStringLiteral("#00000000")},
            {QStringLiteral("segmentSize"), 4.0},
            {QStringLiteral("gapSize"), 4.0},
            {QStringLiteral("thickness"), 2.0},
        };
        const QJsonValue separatorPatternValue = separator.value(QStringLiteral("pattern"));
        if (!separatorPatternValue.isUndefined()) {
            if (!separatorPatternValue.isObject()) {
                return failure(QStringLiteral("invalidSeparator"));
            }

            const QJsonObject pattern = separatorPatternValue.toObject();
            const QJsonValue patternStyleValue = pattern.value(QStringLiteral("style"));
            if (!patternStyleValue.isString()
                || !separatorPatternStyles.contains(patternStyleValue.toString())) {
                return failure(QStringLiteral("invalidSeparator"));
            }

            QString primaryColor;
            QString secondaryColor;
            double segmentSize = 0;
            double gapSize = 0;
            double patternThickness = 0;
            if (!readColor(pattern, QStringLiteral("primaryColor"), QStringLiteral("#ffffffff"), &primaryColor)
                || !readColor(pattern, QStringLiteral("secondaryColor"), QStringLiteral("#00000000"), &secondaryColor)
                || !readNumber(pattern, QStringLiteral("segmentSize"), 4, 2, 12, &segmentSize)
                || !readNumber(pattern, QStringLiteral("gapSize"), 4, 0, 12, &gapSize)
                || !readNumber(pattern, QStringLiteral("thickness"), 2, 1, 8, &patternThickness)) {
                return failure(QStringLiteral("invalidSeparator"));
            }
            separatorPatternMap = {
                {QStringLiteral("style"), patternStyleValue.toString()},
                {QStringLiteral("primaryColor"), primaryColor},
                {QStringLiteral("secondaryColor"), secondaryColor},
                {QStringLiteral("segmentSize"), segmentSize},
                {QStringLiteral("gapSize"), gapSize},
                {QStringLiteral("thickness"), patternThickness},
            };
        }

        separatorMap = {
            {QStringLiteral("style"), styleValue.toString()},
            {QStringLiteral("color"), separatorColor},
            {QStringLiteral("thickness"), separatorThickness},
            {QStringLiteral("lengthRatio"), separatorLengthRatio},
            {QStringLiteral("opacity"), separatorOpacity},
            {QStringLiteral("radius"), separatorRadius},
            {QStringLiteral("gradient"), QVariantMap{
                {QStringLiteral("direction"), separatorGradientDirection},
                {QStringLiteral("stops"), separatorGradientStops},
            }},
            {QStringLiteral("border"), separatorBorderMap},
            {QStringLiteral("glow"), separatorGlowMap},
            {QStringLiteral("pattern"), separatorPatternMap},
        };
    }

    QVariantMap metadataMap{
        {QStringLiteral("name"), name},
    };
    if (!author.isEmpty()) {
        metadataMap.insert(QStringLiteral("author"), author);
    }
    if (!version.isEmpty()) {
        metadataMap.insert(QStringLiteral("version"), version);
    }

    QVariantMap normalizedTheme{
        {QStringLiteral("schemaVersion"), 1},
        {QStringLiteral("metadata"), metadataMap},
        {QStringLiteral("renderer"), renderer},
        {QStringLiteral("surface"), QVariantMap{
            {QStringLiteral("color"), surfaceColor},
            {QStringLiteral("radius"), radius},
            {QStringLiteral("gradient"), QVariantMap{
                {QStringLiteral("direction"), gradientDirection},
                {QStringLiteral("stops"), gradientStops},
            }},
            {QStringLiteral("border"), borderMap},
        }},
        {QStringLiteral("shadow"), shadowMap},
        {QStringLiteral("effects"), QVariantMap{
            {QStringLiteral("blurRequested"), blurRequested},
        }},
    };
    if (!separatorMap.isEmpty()) {
        normalizedTheme.insert(QStringLiteral("separator"), separatorMap);
    }
    if (!shelfMap.isEmpty()) {
        normalizedTheme.insert(QStringLiteral("shelf"), shelfMap);
    }

    return {true, normalizedTheme, {}};
}
