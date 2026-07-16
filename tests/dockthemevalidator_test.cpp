// SPDX-License-Identifier: GPL-3.0-or-later

#include "dockthemevalidator.h"

#include <QFile>
#include <QVariantList>

#include <iostream>

namespace
{
bool expect(bool condition, const char *message)
{
    if (!condition) {
        std::cerr << "FAILED: " << message << '\n';
    }
    return condition;
}
}

int main(int argc, char **argv)
{
    const QByteArray validTheme = R"json(
{
  "schemaVersion": 1,
  "metadata": {
    "name": "Obsidiana 2D",
    "author": "Punchi",
    "version": "1.0"
  },
  "renderer": "flat",
  "surface": {
    "color": "#1d2127",
    "radius": 24,
    "gradient": {
      "direction": "vertical",
      "stops": [
        { "position": 0, "color": "#1d2127" },
        { "position": 1, "color": "#ff050709" }
      ]
    },
    "border": {
      "width": 1,
      "color": "#1fffffff"
    }
  },
  "shadow": {
    "color": "#8c000000",
    "size": 8,
    "xOffset": 0,
    "yOffset": 4
  },
  "effects": {
    "blurRequested": true
  },
  "separator": {
    "style": "capsule",
    "color": "#2ccce0",
    "thickness": 8,
    "lengthRatio": 0.9,
    "opacity": 0.85,
    "radius": 4,
    "gradient": {
      "direction": "vertical",
      "stops": [
        { "position": 0, "color": "#9beeff" },
        { "position": 0.5, "color": "#278ca5" },
        { "position": 1, "color": "#9beeff" }
      ]
    },
    "border": {
      "width": 1,
      "color": "#80ffffff"
    },
    "glow": {
      "size": 5,
      "color": "#802ccce0"
    },
    "pattern": {
      "style": "centerLine",
      "primaryColor": "#ffffffff",
      "thickness": 2
    }
  }
}
)json";

    bool passed = true;
    const DockThemeValidator::Result validResult = DockThemeValidator::validate(validTheme);
    passed &= expect(validResult.ok, "valid theme accepted");
    passed &= expect(validResult.theme.value(QStringLiteral("renderer")).toString() == QLatin1String("flat"),
        "renderer normalized");
    passed &= expect(validResult.theme.value(QStringLiteral("metadata")).toMap()
        .value(QStringLiteral("name")).toString() == QLatin1String("Obsidiana 2D"),
        "theme name preserved");
    passed &= expect(validResult.theme.value(QStringLiteral("surface")).toMap()
        .value(QStringLiteral("gradient")).toMap().value(QStringLiteral("stops")).toList().size() == 2,
        "gradient stops preserved");
    const QVariantMap separator = validResult.theme.value(QStringLiteral("separator")).toMap();
    passed &= expect(separator.value(QStringLiteral("style")).toString() == QLatin1String("capsule"),
        "separator style preserved");
    passed &= expect(separator.value(QStringLiteral("gradient")).toMap()
        .value(QStringLiteral("stops")).toList().size() == 3,
        "separator gradient stops preserved");
    passed &= expect(separator.value(QStringLiteral("pattern")).toMap()
        .value(QStringLiteral("style")).toString() == QLatin1String("centerLine"),
        "separator pattern preserved");

    const QByteArray invalidCssColor = validTheme;
    QByteArray cssColorTheme = invalidCssColor;
    cssColorTheme.replace("#8c000000", "rgba(0,0,0,0.55)");
    const DockThemeValidator::Result cssColorResult = DockThemeValidator::validate(cssColorTheme);
    passed &= expect(!cssColorResult.ok && cssColorResult.errorCode == QLatin1String("invalidShadow"),
        "CSS color rejected");

    QByteArray unsupportedRenderer = validTheme;
    unsupportedRenderer.replace("\"flat\"", "\"external\"");
    const DockThemeValidator::Result rendererResult = DockThemeValidator::validate(unsupportedRenderer);
    passed &= expect(!rendererResult.ok && rendererResult.errorCode == QLatin1String("unsupportedRenderer"),
        "unsupported renderer rejected");

    QByteArray excessiveShadow = validTheme;
    excessiveShadow.replace("\"size\": 8", "\"size\": 200");
    const DockThemeValidator::Result shadowResult = DockThemeValidator::validate(excessiveShadow);
    passed &= expect(!shadowResult.ok && shadowResult.errorCode == QLatin1String("invalidShadow"),
        "out-of-range shadow rejected");

    const DockThemeValidator::Result malformedResult = DockThemeValidator::validate("{");
    passed &= expect(!malformedResult.ok && malformedResult.errorCode == QLatin1String("invalidJson"),
        "malformed JSON rejected");

    const QByteArray oversizedTheme(DockThemeValidator::maximumFileSize + 1, ' ');
    const DockThemeValidator::Result oversizedResult = DockThemeValidator::validate(oversizedTheme);
    passed &= expect(!oversizedResult.ok && oversizedResult.errorCode == QLatin1String("fileTooLarge"),
        "oversized theme rejected");

    QByteArray invalidSeparatorStyle = validTheme;
    invalidSeparatorStyle.replace("\"capsule\"", "\"externalQml\"");
    const DockThemeValidator::Result invalidSeparatorStyleResult =
        DockThemeValidator::validate(invalidSeparatorStyle);
    passed &= expect(!invalidSeparatorStyleResult.ok
        && invalidSeparatorStyleResult.errorCode == QLatin1String("invalidSeparator"),
        "unknown separator style rejected");

    QByteArray excessiveSeparatorThickness = validTheme;
    excessiveSeparatorThickness.replace("\"thickness\": 8", "\"thickness\": 80");
    const DockThemeValidator::Result excessiveSeparatorThicknessResult =
        DockThemeValidator::validate(excessiveSeparatorThickness);
    passed &= expect(!excessiveSeparatorThicknessResult.ok
        && excessiveSeparatorThicknessResult.errorCode == QLatin1String("invalidSeparator"),
        "out-of-range separator thickness rejected");

    const QByteArray themeWithoutSeparator = R"json(
{
  "schemaVersion": 1,
  "metadata": { "name": "Legacy Theme" },
  "renderer": "flat",
  "surface": { "color": "#20242a" }
}
)json";
    const DockThemeValidator::Result legacyResult =
        DockThemeValidator::validate(themeWithoutSeparator);
    passed &= expect(legacyResult.ok
        && !legacyResult.theme.contains(QStringLiteral("separator")),
        "theme without separator keeps Plasma fallback");

    const QByteArray shelfTheme = R"json(
{
  "schemaVersion": 1,
  "metadata": {
    "name": "Integrated Glass 3D"
  },
  "renderer": "shelf",
  "surface": {
    "color": "#603092c2",
    "radius": 10,
    "gradient": {
      "direction": "vertical",
      "stops": [
        { "position": 0, "color": "#7372dcf8" },
        { "position": 1, "color": "#403092c2" }
      ]
    },
    "border": {
      "width": 1,
      "color": "#ccd6f6ff"
    }
  },
  "shadow": {
    "color": "#52000000",
    "size": 8,
    "xOffset": 0,
    "yOffset": 4
  },
  "shelf": {
    "geometry": {
      "topAngle": 61,
      "edgeAngle": -29,
      "edgeDepth": 22,
      "rimThickness": 4,
      "horizontalInset": 6,
      "topDepthRatio": 0.58,
      "backInset": 22,
      "sideBevel": 5
    },
    "edge": {
      "color": "#ff0a5884",
      "radius": 8,
      "gradient": {
        "direction": "vertical",
        "stops": [
          { "position": 0, "color": "#ff48a7d0" },
          { "position": 1, "color": "#ff0a5884" }
        ]
      },
      "border": {
        "width": 1,
        "color": "#ff6bc8ee"
      }
    },
    "rim": {
      "color": "#ffa7edff",
      "opacity": 1,
      "glow": {
        "size": 5,
        "color": "#80a7edff"
      }
    }
  }
}
)json";
    const DockThemeValidator::Result shelfResult =
        DockThemeValidator::validate(shelfTheme);
    passed &= expect(shelfResult.ok
        && shelfResult.theme.value(QStringLiteral("renderer")).toString() == QLatin1String("shelf"),
        "shelf renderer accepted");
    passed &= expect(shelfResult.theme.value(QStringLiteral("shelf")).toMap()
        .value(QStringLiteral("geometry")).toMap()
        .value(QStringLiteral("edgeDepth")).toDouble() == 22,
        "shelf geometry normalized");
    passed &= expect(shelfResult.theme.value(QStringLiteral("shelf")).toMap()
        .value(QStringLiteral("geometry")).toMap()
        .value(QStringLiteral("backInset")).toDouble() == 22,
        "shelf trapezoid geometry normalized");

    QByteArray invalidShelfAngle = shelfTheme;
    invalidShelfAngle.replace("\"topAngle\": 61", "\"topAngle\": 89");
    const DockThemeValidator::Result invalidShelfAngleResult =
        DockThemeValidator::validate(invalidShelfAngle);
    passed &= expect(!invalidShelfAngleResult.ok
        && invalidShelfAngleResult.errorCode == QLatin1String("invalidShelf"),
        "out-of-range shelf geometry rejected");

    QByteArray invalidBackInset = shelfTheme;
    invalidBackInset.replace("\"backInset\": 22", "\"backInset\": 90");
    const DockThemeValidator::Result invalidBackInsetResult =
        DockThemeValidator::validate(invalidBackInset);
    passed &= expect(!invalidBackInsetResult.ok
        && invalidBackInsetResult.errorCode == QLatin1String("invalidShelf"),
        "out-of-range shelf perspective rejected");

    for (int argumentIndex = 1; argumentIndex < argc; ++argumentIndex) {
        const QString filePath = QString::fromLocal8Bit(argv[argumentIndex]);
        QFile themeFile(filePath);
        if (!themeFile.open(QIODevice::ReadOnly)) {
            std::cerr << "FAILED: could not read " << filePath.toStdString() << '\n';
            passed = false;
            continue;
        }

        const DockThemeValidator::Result fileResult = DockThemeValidator::validate(themeFile.readAll());
        if (!fileResult.ok) {
            std::cerr << "FAILED: " << filePath.toStdString()
                      << " rejected with " << fileResult.errorCode.toStdString() << '\n';
            passed = false;
        }
    }

    return passed ? 0 : 1;
}
