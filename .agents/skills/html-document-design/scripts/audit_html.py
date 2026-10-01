#!/usr/bin/env python3
"""Audit a self-contained public HTML document without network access."""

from __future__ import annotations

import argparse
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlparse


class DocumentAudit(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.ids: list[str] = []
        self.links: list[str] = []
        self.resources: list[tuple[str, str]] = []
        self.images: list[dict[str, str]] = []
        self.scripts = 0
        self.lang = ""
        self.has_title = False
        self.has_viewport = False
        self.has_description = False
        self.has_main = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = {key: value or "" for key, value in attrs}
        if tag == "html":
            self.lang = values.get("lang", "").strip()
        if tag == "title":
            self.has_title = True
        if tag == "main":
            self.has_main = True
        if tag == "meta" and values.get("name", "").lower() == "viewport":
            self.has_viewport = bool(values.get("content", "").strip())
        if tag == "meta" and values.get("name", "").lower() == "description":
            self.has_description = bool(values.get("content", "").strip())
        if "id" in values:
            self.ids.append(values["id"])
        if tag == "a" and "href" in values:
            self.links.append(values["href"])
        if tag == "img":
            self.images.append(values)
            if values.get("src"):
                self.resources.append(("image", values["src"]))
        if tag == "link" and values.get("href"):
            self.resources.append(("stylesheet", values["href"]))
        if tag == "script":
            self.scripts += 1
            if values.get("src"):
                self.resources.append(("script", values["src"]))
        if tag == "use" and values.get("href"):
            self.resources.append(("svg", values["href"]))


def is_remote(value: str) -> bool:
    parsed = urlparse(value)
    return parsed.scheme in {"http", "https", "ftp"} or value.startswith("//")


def local_target(document: Path, value: str) -> Path | None:
    path_value = value.split("#", 1)[0].split("?", 1)[0]
    if not path_value or path_value.startswith("data:") or path_value.startswith("#"):
        return None
    return document.parent / unquote(path_value)


def audit(document: Path, allow_scripts: bool) -> list[str]:
    parser = DocumentAudit()
    parser.feed(document.read_text(encoding="utf-8"))
    errors: list[str] = []

    if not parser.lang:
        errors.append("missing html lang attribute")
    if not parser.has_title:
        errors.append("missing title element")
    if not parser.has_viewport:
        errors.append("missing viewport meta")
    if not parser.has_description:
        errors.append("missing description meta")
    if not parser.has_main:
        errors.append("missing main landmark")
    if parser.scripts and not allow_scripts:
        errors.append(f"scripts are not allowed ({parser.scripts} found)")

    duplicates = sorted({value for value in parser.ids if parser.ids.count(value) > 1})
    if duplicates:
        errors.append("duplicate ids: " + ", ".join(duplicates))

    broken_anchors = sorted(
        href for href in parser.links if href.startswith("#") and href[1:] not in parser.ids
    )
    if broken_anchors:
        errors.append("broken internal links: " + ", ".join(broken_anchors))

    for index, image in enumerate(parser.images, start=1):
        source = image.get("src", f"image {index}")
        if "alt" not in image:
            errors.append(f"image missing alt attribute: {source}")
        if not image.get("width") or not image.get("height"):
            errors.append(f"image missing intrinsic dimensions: {source}")

    for kind, value in parser.resources:
        if is_remote(value):
            errors.append(f"remote {kind} resource is not allowed: {value}")
            continue
        target = local_target(document, value)
        if target is not None and not target.is_file():
            errors.append(f"missing local {kind} resource: {value}")

    return errors


def main() -> int:
    argument_parser = argparse.ArgumentParser(description=__doc__)
    argument_parser.add_argument("document", type=Path)
    argument_parser.add_argument("--allow-scripts", action="store_true")
    args = argument_parser.parse_args()

    document = args.document.resolve()
    if not document.is_file():
        argument_parser.error(f"document does not exist: {document}")

    errors = audit(document, args.allow_scripts)
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1

    print(f"OK: {document}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
