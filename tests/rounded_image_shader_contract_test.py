#!/usr/bin/env python3

from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def require(source: str, fragment: str, message: str) -> None:
    if fragment not in source:
        raise AssertionError(message)


def main() -> int:
    rounded_image = (
        PROJECT_ROOT / "contents/ui/components/RoundedImage.qml"
    ).read_text()
    replacement_card = (
        PROJECT_ROOT / "contents/ui/components/MprisReplacementCard.qml"
    ).read_text()
    shader = (PROJECT_ROOT / "src/shaders/RoundedImage.frag").read_text()
    native_build = (PROJECT_ROOT / "src/CMakeLists.txt").read_text()

    for fragment, message in (
        ("GraphicsInfo.api === GraphicsInfo.Software",
         "RoundedImage must retain an explicit software fallback"),
        ("sourceSize: Qt.size(",
         "RoundedImage must request a device-scaled source texture"),
        ("Screen.devicePixelRatio",
         "RoundedImage must respect the active display scale"),
        ("smooth: true", "RoundedImage must enable smooth image sampling"),
        ("mipmap: true", "RoundedImage must retain scaled-image mipmaps"),
        ("ShaderEffectSource {", "The GPU path must expose one source texture"),
        ("supportsAtlasTextures: true", "The shader must remain atlas-safe"),
        ("RoundedImage.frag.qsb", "The GPU path must use the embedded shader"),
        ("Effects.MultiEffect {", "Software rendering must retain a mask fallback"),
        ("layer.samples: 8", "The software mask must use bounded supersampling"),
        ("antialiasing: true", "The software mask edge must be antialiased"),
    ):
        require(rounded_image, fragment, message)

    for fragment, message in (
        ("RoundedImage {", "fullCard must consume the rounded image primitive"),
        ("id: fullCoverArtwork", "fullCard must expose one artwork owner"),
        ("radius: root.cornerRadius", "The shader must follow the reactive card radius"),
        ("visible: !fullCoverArtwork.ready",
         "The established fallback must follow shader image readiness"),
    ):
        require(replacement_card, fragment, message)
    if replacement_card.count("RoundedImage {") != 1:
        raise AssertionError(
            "The experiment must remain limited to the fullCard profile"
        )
    for forbidden in ("id: fullCoverMask", "id: fullCoverSource"):
        if forbidden in replacement_card:
            raise AssertionError(
                "fullCard must not keep its previous parallel mask pipeline"
            )

    for fragment, message in (
        ("vec4 roundedGeometry", "The shader must receive packed stable geometry"),
        ("signedDistance", "The shader must calculate a rounded-rectangle SDF"),
        ("fwidth(signedDistance)",
         "The antialias transition must follow physical fragment derivatives"),
        ("smoothstep(", "The SDF edge must use a continuous alpha transition"),
        ("texture(imageTexture, qt_TexCoord0)",
         "Artwork sampling and clipping must happen in one shader pass"),
    ):
        require(shader, fragment, message)

    for fragment, message in (
        ("PUNCHI_ROUNDED_IMAGE_SHADER_SOURCE",
         "The native build must own the rounded shader source"),
        ("--qsbversion 65", "The shader must retain Qt 6.6-compatible QSB"),
        ('QT_RESOURCE_ALIAS "RoundedImage.frag.qsb"',
         "The shader resource alias must match the QML path"),
        ('PREFIX "/qt/qml/org/punchi/dock/shaders"',
         "The shader must share the established embedded resource prefix"),
    ):
        require(native_build, fragment, message)

    print("Rounded image shader contracts are consistent")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
