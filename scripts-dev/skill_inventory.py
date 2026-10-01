#!/usr/bin/env python3
"""Validate project skills and maintain their deterministic inventory."""

from __future__ import annotations

import argparse
import ast
import json
import os
import re
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any


EXIT_OK = 0
EXIT_VALIDATION = 1
EXIT_USAGE = 2

ALLOWED_ROLES = {"orchestrator", "domain", "alias", "template"}
PATH_KINDS = {
    "repo_root",
    "skill_root",
    "document_relative",
    "generated",
    "negative",
    "placeholder",
    "unclassified",
}
VERIFIABLE_PATH_KINDS = {"repo_root", "skill_root", "document_relative"}
REPO_PATH_PREFIXES = (
    ".agents/",
    "contents/",
    "docs/",
    "po/",
    "scripts-dev/",
    "scripts-user/",
    "src/",
    "tests/",
)
REPO_PATH_FILES = {
    ".gitignore",
    ".kpackageignore",
    "AGENTS.md",
    "CHANGELOG.md",
    "CMakeLists.txt",
    "LICENSE",
    "metadata.json",
    "README.md",
}
SKILL_PATH_PREFIXES = ("agents/", "assets/", "references/", "scripts/")
GENERATED_PATH_PREFIXES = ("build/", "dist/", "contents/locale/")
TEXT_RESOURCE_SUFFIXES = {".md", ".yaml", ".yml", ".py", ".sh", ".json"}

FRONT_MATTER_RE = re.compile(r"\A---\s*\n(.*?)\n---\s*(?:\n|\Z)", re.DOTALL)
MARKDOWN_LINK_RE = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
INLINE_CODE_RE = re.compile(r"(?<!`)`([^`\n]+)`(?!`)")
SKILL_PROMPT_RE = re.compile(r"\$([a-z0-9][a-z0-9-]*)")
SKILL_NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


class InventoryError(Exception):
    """Raised when an input cannot be parsed safely."""


@dataclass(frozen=True)
class PathCandidate:
    """One local-path reference discovered in a skill resource."""

    source: str
    value: str
    kind: str
    origin: str


def parse_scalar(raw_value: str, source: Path, line_number: int) -> Any:
    """Parse the deliberately small scalar subset used by project metadata."""
    value = raw_value.strip()
    if not value:
        raise InventoryError(f"{source}:{line_number}: missing scalar value")
    if value.startswith("["):
        if not value.endswith("]"):
            raise InventoryError(f"{source}:{line_number}: unterminated inline list")
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [parse_scalar(item, source, line_number) for item in inner.split(",")]
    if value.startswith('"'):
        try:
            parsed = json.loads(value)
        except json.JSONDecodeError as error:
            raise InventoryError(f"{source}:{line_number}: invalid quoted string") from error
        if not isinstance(parsed, str):
            raise InventoryError(f"{source}:{line_number}: expected a string")
        return parsed
    if value.startswith("'"):
        try:
            parsed = ast.literal_eval(value)
        except (SyntaxError, ValueError) as error:
            raise InventoryError(f"{source}:{line_number}: invalid quoted string") from error
        if not isinstance(parsed, str):
            raise InventoryError(f"{source}:{line_number}: expected a string")
        return parsed
    if value == "true":
        return True
    if value == "false":
        return False
    if value in {"null", "~"}:
        return None
    if re.fullmatch(r"-?[0-9]+", value):
        return int(value)
    if " #" in value:
        value = value.split(" #", 1)[0].rstrip()
    return value


def split_mapping_line(line: str, source: Path, line_number: int) -> tuple[str, str]:
    """Split one YAML-style mapping line without interpreting its scalar."""
    if ":" not in line:
        raise InventoryError(f"{source}:{line_number}: expected key: value")
    key, value = line.split(":", 1)
    key = key.strip()
    if not key:
        raise InventoryError(f"{source}:{line_number}: empty mapping key")
    return key, value.strip()


def parse_flat_mapping(text: str, source: Path) -> dict[str, Any]:
    """Parse top-level scalar metadata such as SKILL.md front matter."""
    result: dict[str, Any] = {}
    for line_number, raw_line in enumerate(text.splitlines(), 1):
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        if raw_line != raw_line.lstrip():
            raise InventoryError(
                f"{source}:{line_number}: nested front matter is not supported"
            )
        key, raw_value = split_mapping_line(raw_line, source, line_number)
        if key in result:
            raise InventoryError(f"{source}:{line_number}: duplicate key {key!r}")
        result[key] = parse_scalar(raw_value, source, line_number)
    return result


def parse_front_matter(path: Path) -> tuple[dict[str, Any], str]:
    """Read and validate a skill front matter block."""
    text = path.read_text(encoding="utf-8")
    match = FRONT_MATTER_RE.match(text)
    if not match:
        raise InventoryError(f"{path}: missing YAML front matter")
    return parse_flat_mapping(match.group(1), path), text


def parse_openai_yaml(path: Path) -> dict[str, dict[str, Any]]:
    """Parse the flat two-level schema currently supported by openai.yaml."""
    result: dict[str, dict[str, Any]] = {}
    current_section: str | None = None
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        indent = len(raw_line) - len(raw_line.lstrip(" "))
        if "\t" in raw_line[:indent]:
            raise InventoryError(f"{path}:{line_number}: tabs are not supported")
        if indent == 0:
            key, raw_value = split_mapping_line(raw_line, path, line_number)
            if raw_value:
                raise InventoryError(
                    f"{path}:{line_number}: top-level values must be mappings"
                )
            if key in result:
                raise InventoryError(f"{path}:{line_number}: duplicate section {key!r}")
            result[key] = {}
            current_section = key
            continue
        if indent != 2 or current_section is None:
            raise InventoryError(
                f"{path}:{line_number}: unsupported YAML structure or indentation"
            )
        key, raw_value = split_mapping_line(raw_line.strip(), path, line_number)
        if key in result[current_section]:
            raise InventoryError(f"{path}:{line_number}: duplicate key {key!r}")
        result[current_section][key] = parse_scalar(raw_value, path, line_number)
    return result


def parse_skills_map(path: Path) -> dict[str, Any]:
    """Parse the project-owned, deliberately constrained skills-map schema."""
    data: dict[str, Any] = {
        "schema_version": None,
        "families": {},
        "skills": [],
        "path_overrides": [],
    }
    section: str | None = None
    current_family: str | None = None
    current_item: dict[str, Any] | None = None

    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        indent = len(raw_line) - len(raw_line.lstrip(" "))
        line = raw_line.strip()

        if indent == 0:
            key, raw_value = split_mapping_line(line, path, line_number)
            current_family = None
            current_item = None
            if key == "schema_version":
                data[key] = parse_scalar(raw_value, path, line_number)
                section = None
            elif key in {"families", "skills", "path_overrides"} and not raw_value:
                section = key
            else:
                raise InventoryError(f"{path}:{line_number}: unsupported top-level key {key!r}")
            continue

        if section == "families":
            if indent == 2 and line.endswith(":"):
                current_family = line[:-1]
                if current_family in data["families"]:
                    raise InventoryError(
                        f"{path}:{line_number}: duplicate family {current_family!r}"
                    )
                data["families"][current_family] = {}
                continue
            if indent == 4 and current_family is not None:
                key, raw_value = split_mapping_line(line, path, line_number)
                if key in data["families"][current_family]:
                    raise InventoryError(f"{path}:{line_number}: duplicate key {key!r}")
                data["families"][current_family][key] = parse_scalar(
                    raw_value, path, line_number
                )
                continue

        if section in {"skills", "path_overrides"}:
            if indent == 2 and line.startswith("- "):
                key, raw_value = split_mapping_line(line[2:], path, line_number)
                current_item = {key: parse_scalar(raw_value, path, line_number)}
                data[section].append(current_item)
                continue
            if indent == 4 and current_item is not None:
                key, raw_value = split_mapping_line(line, path, line_number)
                if key in current_item:
                    raise InventoryError(f"{path}:{line_number}: duplicate key {key!r}")
                current_item[key] = parse_scalar(raw_value, path, line_number)
                continue

        raise InventoryError(f"{path}:{line_number}: unsupported YAML structure")

    return data


def normalize_relative_path(path: Path, root: Path) -> str:
    """Return a stable POSIX path relative to the repository root."""
    return path.relative_to(root).as_posix()


def is_within(path: Path, root: Path) -> bool:
    """Return whether a resolved path remains within an approved root."""
    try:
        path.relative_to(root)
    except ValueError:
        return False
    return True


def classify_inline_path(value: str, skill_dir: Path, project_root: Path) -> str | None:
    """Conservatively classify an inline-code token that looks like a path."""
    if any(character.isspace() for character in value):
        return None
    if value.startswith(("http://", "https://", "file://", "#")):
        return None
    if any(marker in value for marker in ("<", ">", "${", "$(", "*", "?")):
        return "placeholder"
    if value.startswith(GENERATED_PATH_PREFIXES):
        return "generated"
    if value.startswith(REPO_PATH_PREFIXES) or value in REPO_PATH_FILES:
        target = (project_root / value).resolve()
        return "repo_root" if target.exists() else "unclassified"
    if value.startswith(SKILL_PATH_PREFIXES) or value == "SKILL.md":
        target = (skill_dir / value).resolve()
        return "skill_root" if target.exists() else "unclassified"
    if value.startswith(("./", "../")):
        return "unclassified"
    return None


def extract_path_candidates(
    skill_dir: Path, project_root: Path
) -> dict[tuple[str, str], PathCandidate]:
    """Extract only explicit links and high-confidence inline path tokens."""
    candidates: dict[tuple[str, str], PathCandidate] = {}
    for path in sorted(item for item in skill_dir.rglob("*") if item.is_file()):
        if path.suffix not in TEXT_RESOURCE_SUFFIXES:
            continue
        source = path.relative_to(skill_dir).as_posix()
        text = path.read_text(encoding="utf-8")
        for match in MARKDOWN_LINK_RE.finditer(text):
            value = match.group(1).strip().split("#", 1)[0]
            if not value or value.startswith(("http://", "https://", "mailto:", "#")):
                continue
            kind = "placeholder" if any(marker in value for marker in ("<", ">", "${")) else "document_relative"
            candidates[(source, value)] = PathCandidate(source, value, kind, "markdown_link")
        for match in INLINE_CODE_RE.finditer(text):
            value = match.group(1).strip().rstrip(".,;:")
            kind = classify_inline_path(value, skill_dir, project_root)
            if kind is None:
                continue
            candidates.setdefault(
                (source, value), PathCandidate(source, value, kind, "inline_code")
            )
    return candidates


def resolve_candidate(
    candidate: PathCandidate, skill_dir: Path, project_root: Path
) -> Path | None:
    """Resolve a classified path without following it outside the repository."""
    source_path = skill_dir / candidate.source
    if candidate.kind == "repo_root":
        return (project_root / candidate.value).resolve()
    if candidate.kind == "skill_root":
        return (skill_dir / candidate.value).resolve()
    if candidate.kind == "document_relative":
        return (source_path.parent / candidate.value).resolve()
    return None


def inventory_resources(skill_dir: Path) -> dict[str, list[str]]:
    """List skill-owned resources without duplicating SKILL.md or openai.yaml."""
    resources: dict[str, list[str]] = {
        "references": [],
        "assets": [],
        "scripts": [],
        "other": [],
    }
    for path in sorted(item for item in skill_dir.rglob("*") if item.is_file()):
        relative = path.relative_to(skill_dir).as_posix()
        if relative in {"SKILL.md", "agents/openai.yaml"}:
            continue
        first = relative.split("/", 1)[0]
        bucket = first if first in {"references", "assets", "scripts"} else "other"
        resources[bucket].append(relative)
    return resources


def render_inventory(data: dict[str, Any]) -> str:
    """Render the canonical JSON representation."""
    return json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def build_inventory(project_root: Path) -> tuple[dict[str, Any], list[str], list[str]]:
    """Validate source data and build the complete expected inventory."""
    errors: list[str] = []
    warnings: list[str] = []
    agents_root = project_root / ".agents"
    skills_root = agents_root / "skills"
    map_path = agents_root / "skills-map.yaml"

    try:
        map_data = parse_skills_map(map_path)
    except (OSError, UnicodeError, InventoryError) as error:
        return {}, [str(error)], warnings

    if map_data["schema_version"] != 1:
        errors.append("skills-map.yaml: schema_version must be 1")

    families = map_data["families"]
    for family_name, family_data in sorted(families.items()):
        if not SKILL_NAME_RE.fullmatch(family_name):
            errors.append(f"skills-map.yaml: invalid family name {family_name!r}")
        description = family_data.get("description")
        if not isinstance(description, str) or not description.strip():
            errors.append(f"skills-map.yaml: family {family_name!r} needs a description")
        for key in sorted(set(family_data) - {"description"}):
            errors.append(
                f"skills-map.yaml: family {family_name!r} has unknown key {key!r}"
            )

    skill_dirs = sorted(path for path in skills_root.iterdir() if path.is_dir())
    actual_names = {path.name for path in skill_dirs}
    map_entries: dict[str, dict[str, Any]] = {}
    for entry in map_data["skills"]:
        name = entry.get("name")
        if not isinstance(name, str) or not SKILL_NAME_RE.fullmatch(name):
            errors.append(f"skills-map.yaml: invalid skill name {name!r}")
            continue
        if name in map_entries:
            errors.append(f"skills-map.yaml: duplicate skill {name!r}")
            continue
        map_entries[name] = entry

    mapped_names = set(map_entries)
    for name in sorted(actual_names - mapped_names):
        errors.append(f"skills-map.yaml: unclassified skill {name!r}")
    for name in sorted(mapped_names - actual_names):
        errors.append(f"skills-map.yaml: orphan map entry {name!r}")

    for name, entry in sorted(map_entries.items()):
        allowed_keys = {"name", "family", "role", "canonical", "references"}
        for key in sorted(set(entry) - allowed_keys):
            errors.append(f"skills-map.yaml: {name}: unknown key {key!r}")
        family = entry.get("family")
        role = entry.get("role")
        canonical = entry.get("canonical")
        references = entry.get("references")
        if not isinstance(family, str) or family not in families:
            errors.append(f"skills-map.yaml: {name}: unknown family {family!r}")
        if not isinstance(role, str) or role not in ALLOWED_ROLES:
            errors.append(f"skills-map.yaml: {name}: invalid role {role!r}")
        if role == "alias":
            if not isinstance(canonical, str) or not canonical:
                errors.append(f"skills-map.yaml: {name}: alias requires canonical")
        elif "canonical" in entry:
            errors.append(f"skills-map.yaml: {name}: canonical is only valid for aliases")
        if not isinstance(references, list) or any(
            not isinstance(reference, str) for reference in references
        ):
            errors.append(f"skills-map.yaml: {name}: references must be a list of names")
            entry["references"] = []
        elif len(references) != len(set(references)):
            errors.append(f"skills-map.yaml: {name}: duplicate structured reference")
        for reference in entry.get("references", []):
            if reference not in actual_names:
                errors.append(
                    f"skills-map.yaml: {name}: unknown structured reference {reference!r}"
                )
            if reference == name:
                errors.append(f"skills-map.yaml: {name}: self-reference is not allowed")

    for name, entry in sorted(map_entries.items()):
        if entry.get("role") != "alias":
            continue
        canonical = entry.get("canonical")
        if not isinstance(canonical, str):
            continue
        if canonical not in map_entries:
            errors.append(f"skills-map.yaml: {name}: unknown canonical {canonical!r}")
        elif map_entries[canonical].get("role") == "alias":
            errors.append(f"skills-map.yaml: {name}: alias-to-alias is not allowed")

    for start in sorted(map_entries):
        seen: set[str] = set()
        current = start
        while current in map_entries and map_entries[current].get("role") == "alias":
            if current in seen:
                errors.append(f"skills-map.yaml: alias cycle includes {current!r}")
                break
            seen.add(current)
            canonical = map_entries[current].get("canonical")
            if not isinstance(canonical, str):
                break
            current = canonical

    inverse_aliases: dict[str, list[str]] = {name: [] for name in actual_names}
    for name, entry in map_entries.items():
        canonical = entry.get("canonical")
        if entry.get("role") == "alias" and canonical in inverse_aliases:
            inverse_aliases[canonical].append(name)
    for aliases in inverse_aliases.values():
        aliases.sort()

    overrides_by_skill: dict[str, dict[tuple[str, str], dict[str, Any]]] = {}
    for override in map_data["path_overrides"]:
        skill = override.get("skill")
        source = override.get("source")
        value = override.get("value")
        kind = override.get("kind")
        for key in sorted(set(override) - {"skill", "source", "value", "kind"}):
            errors.append(f"skills-map.yaml: path override has unknown key {key!r}")
        if not isinstance(skill, str) or skill not in actual_names:
            errors.append(f"skills-map.yaml: path override has unknown skill {skill!r}")
            continue
        if not all(isinstance(item, str) and item for item in (source, value, kind)):
            errors.append(f"skills-map.yaml: invalid path override for {skill!r}")
            continue
        if not isinstance(kind, str) or kind not in PATH_KINDS:
            errors.append(f"skills-map.yaml: invalid path kind {kind!r}")
            continue
        key = (source, value)
        skill_overrides = overrides_by_skill.setdefault(skill, {})
        if key in skill_overrides:
            errors.append(f"skills-map.yaml: duplicate path override for {skill}:{source}:{value}")
            continue
        skill_overrides[key] = override

    all_openai_files = set(skills_root.rglob("openai.yaml"))
    expected_openai_files = {
        skill_dir / "agents" / "openai.yaml"
        for skill_dir in skill_dirs
        if (skill_dir / "agents" / "openai.yaml").exists()
    }
    for orphan in sorted(all_openai_files - expected_openai_files):
        errors.append(f"orphan or misplaced openai.yaml: {normalize_relative_path(orphan, project_root)}")

    inventory_skills: list[dict[str, Any]] = []
    seen_front_names: set[str] = set()
    for skill_dir in skill_dirs:
        name = skill_dir.name
        skill_md = skill_dir / "SKILL.md"
        front_matter: dict[str, Any] = {}
        skill_text = ""
        if not skill_md.is_file():
            errors.append(f"{normalize_relative_path(skill_dir, project_root)}: missing SKILL.md")
        else:
            try:
                front_matter, skill_text = parse_front_matter(skill_md)
            except (OSError, UnicodeError, InventoryError) as error:
                errors.append(str(error))

        front_name = front_matter.get("name")
        description = front_matter.get("description")
        if front_name != name:
            errors.append(f"{skill_md}: front matter name {front_name!r} != {name!r}")
        if isinstance(front_name, str):
            if front_name in seen_front_names:
                errors.append(f"{skill_md}: duplicate front matter name {front_name!r}")
            seen_front_names.add(front_name)
        if not isinstance(description, str) or not description.strip():
            errors.append(f"{skill_md}: description must be a non-empty string")

        openai_path = skill_dir / "agents" / "openai.yaml"
        openai_data: dict[str, dict[str, Any]] = {}
        openai_record: dict[str, Any] = {
            "exists": openai_path.exists(),
            "display_name": None,
            "short_description": None,
            "default_prompt_skill_ref": None,
            "allow_implicit_invocation": "unspecified",
        }
        if openai_path.exists():
            try:
                openai_data = parse_openai_yaml(openai_path)
            except (OSError, UnicodeError, InventoryError) as error:
                errors.append(str(error))
            interface = openai_data.get("interface", {})
            policy = openai_data.get("policy", {})
            for field in ("display_name", "short_description", "default_prompt"):
                field_value = interface.get(field)
                if not isinstance(field_value, str) or not field_value.strip():
                    errors.append(f"{openai_path}: interface.{field} must be a non-empty string")
            display_name = interface.get("display_name")
            short_description = interface.get("short_description")
            default_prompt = interface.get("default_prompt")
            openai_record["display_name"] = display_name if isinstance(display_name, str) else None
            openai_record["short_description"] = (
                short_description if isinstance(short_description, str) else None
            )
            prompt_refs = SKILL_PROMPT_RE.findall(default_prompt or "")
            if prompt_refs != [name]:
                errors.append(
                    f"{openai_path}: default_prompt must reference exactly ${name}"
                )
            else:
                openai_record["default_prompt_skill_ref"] = name
            if "allow_implicit_invocation" in policy:
                implicit = policy["allow_implicit_invocation"]
                if not isinstance(implicit, bool):
                    errors.append(
                        f"{openai_path}: policy.allow_implicit_invocation must be true or false"
                    )
                else:
                    openai_record["allow_implicit_invocation"] = implicit

        candidates = extract_path_candidates(skill_dir, project_root)
        for key, override in overrides_by_skill.get(name, {}).items():
            source, value = key
            source_path = skill_dir / source
            if not source_path.is_file():
                errors.append(f"skills-map.yaml: {name}: override source does not exist: {source}")
            else:
                source_text = source_path.read_text(encoding="utf-8")
                if value not in source_text:
                    errors.append(
                        f"skills-map.yaml: {name}: override value not found in {source}: {value}"
                    )
            candidates[key] = PathCandidate(source, value, override["kind"], "map_override")

        path_records: list[dict[str, Any]] = []
        for candidate in sorted(candidates.values(), key=lambda item: (item.source, item.value)):
            target = resolve_candidate(candidate, skill_dir, project_root)
            exists: bool | None = None
            resolved: str | None = None
            if target is not None:
                if not is_within(target, project_root.resolve()):
                    errors.append(
                        f"{name}:{candidate.source}: path escapes repository: {candidate.value}"
                    )
                else:
                    exists = target.exists()
                    resolved = normalize_relative_path(target, project_root.resolve())
                    if candidate.kind in VERIFIABLE_PATH_KINDS and not exists:
                        errors.append(
                            f"{name}:{candidate.source}: missing {candidate.kind} path: {candidate.value}"
                        )
            if candidate.kind == "unclassified":
                warnings.append(
                    f"{name}:{candidate.source}: unclassified path candidate: {candidate.value}"
                )
            path_records.append(
                {
                    "source": candidate.source,
                    "value": candidate.value,
                    "kind": candidate.kind,
                    "origin": candidate.origin,
                    "resolved": resolved,
                    "exists": exists,
                }
            )

        map_entry = map_entries.get(name, {})
        inventory_skills.append(
            {
                "name": name,
                "path": normalize_relative_path(skill_dir, project_root),
                "description": description if isinstance(description, str) else None,
                "family": map_entry.get("family"),
                "role": map_entry.get("role"),
                "is_alias": map_entry.get("role") == "alias",
                "canonical": map_entry.get("canonical"),
                "aliases": inverse_aliases.get(name, []),
                "references": sorted(map_entry.get("references", [])),
                "front_matter": {
                    "status": "valid" if front_matter else "invalid",
                    "keys": sorted(front_matter),
                },
                "openai": openai_record,
                "resources": inventory_resources(skill_dir),
                "paths": path_records,
            }
        )

    inventory = {
        "schema_version": 1,
        "skills_root": ".agents/skills",
        "skill_count": len(skill_dirs),
        "families": [
            {"name": name, "description": families[name].get("description")}
            for name in sorted(families)
        ],
        "skills": inventory_skills,
    }
    return inventory, errors, sorted(set(warnings))


def write_inventory(path: Path, content: str) -> None:
    """Atomically replace only the generated inventory file."""
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary_path, 0o644)
        os.replace(temporary_path, path)
    finally:
        if temporary_path.exists():
            temporary_path.unlink()


def print_diagnostics(errors: list[str], warnings: list[str]) -> None:
    """Print stable diagnostics to standard error."""
    for warning in warnings:
        print(f"WARNING: {warning}", file=sys.stderr)
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)


def main(argv: list[str] | None = None) -> int:
    """Run the read-only check or the inventory-only update."""
    parser = argparse.ArgumentParser(
        description="Validate .agents skills and maintain the generated inventory."
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="validate without writing")
    mode.add_argument(
        "--update",
        action="store_true",
        help="validate sources and replace only .agents/skills-inventory.json",
    )
    args = parser.parse_args(argv)

    project_root = Path(__file__).resolve().parent.parent
    inventory_path = project_root / ".agents" / "skills-inventory.json"
    try:
        inventory, errors, warnings = build_inventory(project_root)
    except (OSError, UnicodeError) as error:
        print(f"ERROR: cannot read project skill infrastructure: {error}", file=sys.stderr)
        return EXIT_USAGE

    if errors:
        print_diagnostics(errors, warnings)
        return EXIT_VALIDATION

    expected = render_inventory(inventory)
    if args.update:
        try:
            write_inventory(inventory_path, expected)
        except OSError as error:
            print(f"ERROR: cannot update {inventory_path}: {error}", file=sys.stderr)
            return EXIT_USAGE
        print(f"Updated {inventory_path.relative_to(project_root)} ({inventory['skill_count']} skills)")
        print_diagnostics([], warnings)
        return EXIT_OK

    try:
        current = inventory_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        errors.append(".agents/skills-inventory.json is missing; run --update")
    except (OSError, UnicodeError) as error:
        print(f"ERROR: cannot read {inventory_path}: {error}", file=sys.stderr)
        return EXIT_USAGE
    else:
        if current != expected:
            errors.append(".agents/skills-inventory.json is stale; run --update")

    print_diagnostics(errors, warnings)
    if errors:
        return EXIT_VALIDATION
    print(f"Skill inventory check passed ({inventory['skill_count']} skills)")
    return EXIT_OK


if __name__ == "__main__":
    raise SystemExit(main())
