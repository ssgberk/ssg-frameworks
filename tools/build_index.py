#!/usr/bin/env python3
"""Build, validate and check generators.json (spec: docs/specs/004-generator-metadata).

Python 3 standard library only.

    python3 tools/build_index.py              # write generators.json
    python3 tools/build_index.py --check      # exit 1 (with a diff) if stale or invalid
    python3 tools/build_index.py --validate   # validate generator.json files only

Options: --root DIR, --ref REF|none (generatedFrom), --raw-base URL.
"""
from __future__ import annotations

import argparse
import difflib
import json
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlparse

SCHEMA_VERSION = "1.0.0"
SOURCE = "https://github.com/ssgberk/ssg-frameworks"
DEFAULT_RAW_BASE = "https://raw.githubusercontent.com/ssgberk/ssg-frameworks/master/"
INDEX_FILE = "generators.json"
PROPOSED_FILE = "tools/proposed.json"

# Runtime name prefix in generator.json `runtime` -> dockerfile ARG pinning it.
RUNTIME_ARGS = {
    "Node.js": "NODE_VERSION",
    "Python": "PYTHON_VERSION",
    "Ruby": "RUBY_VERSION",
    "Go": "GO_VERSION",
    "PHP": "PHP_VERSION",
    "Deno": "DENO_VERSION",
    "Bun": "BUN_VERSION",
    "Rust": "RUST_VERSION",
}


# --------------------------------------------------------------------------
# Minimal JSON Schema (draft 2020-12) validator for the keyword subset we use.
# --------------------------------------------------------------------------

class SchemaError(Exception):
    """The schema uses a keyword this validator does not implement."""


ANNOTATIONS = {"$schema", "$id", "$defs", "title", "description"}
SUPPORTED = ANNOTATIONS | {
    "$ref", "type", "properties", "required", "additionalProperties", "items", "enum", "const",
    "pattern", "format", "minLength", "minItems", "uniqueItems", "minimum", "maximum",
}
TYPES = {
    "object": lambda v: isinstance(v, dict),
    "array": lambda v: isinstance(v, list),
    "string": lambda v: isinstance(v, str),
    "boolean": lambda v: isinstance(v, bool),
    "integer": lambda v: isinstance(v, int) and not isinstance(v, bool),
    "number": lambda v: isinstance(v, (int, float)) and not isinstance(v, bool),
    "null": lambda v: v is None,
}


def check_schema(schema, path="#"):
    """Raise SchemaError if any (sub)schema uses an unsupported keyword."""
    if not isinstance(schema, dict):
        raise SchemaError(f"{path}: schema must be an object")
    unknown = set(schema) - SUPPORTED
    if unknown:
        raise SchemaError(f"{path}: unsupported keyword(s) {sorted(unknown)}")
    if schema.get("additionalProperties", False) is not False:
        raise SchemaError(f"{path}: only additionalProperties: false is supported")
    if "$ref" in schema and not schema["$ref"].startswith("#/$defs/"):
        raise SchemaError(f"{path}: only local #/$defs/ refs are supported")
    if schema.get("format", "uri") != "uri":
        raise SchemaError(f"{path}: only format: uri is supported")
    for key in ("properties", "$defs"):
        for name, sub in schema.get(key, {}).items():
            check_schema(sub, f"{path}/{key}/{name}")
    if "items" in schema:
        check_schema(schema["items"], f"{path}/items")


def _is_uri(value):
    try:
        parsed = urlparse(value)
    except ValueError:
        return False
    return parsed.scheme in ("http", "https") and bool(parsed.netloc) and not re.search(r"\s", value)


def validate(instance, schema, root=None, pointer=""):
    """Return a list of '<pointer>: <message>' errors (empty when valid)."""
    if root is None:
        check_schema(schema)
        root = schema
    errors = []
    where = pointer or "/"

    if "$ref" in schema:
        target = root
        for part in schema["$ref"][2:].split("/"):
            target = target[part]
        errors += validate(instance, target, root, pointer)

    if "type" in schema:
        types = schema["type"] if isinstance(schema["type"], list) else [schema["type"]]
        if not any(TYPES[t](instance) for t in types):
            return errors + [f"{where}: expected type {'/'.join(types)}, got {type(instance).__name__}"]
    if "const" in schema and instance != schema["const"]:
        errors.append(f"{where}: must equal {schema['const']!r}")
    if "enum" in schema and instance not in schema["enum"]:
        errors.append(f"{where}: {instance!r} is not one of {schema['enum']}")

    if isinstance(instance, str):
        if "minLength" in schema and len(instance) < schema["minLength"]:
            errors.append(f"{where}: shorter than {schema['minLength']}")
        if "pattern" in schema and not re.search(schema["pattern"], instance):
            errors.append(f"{where}: {instance!r} does not match {schema['pattern']}")
        if schema.get("format") == "uri" and not _is_uri(instance):
            errors.append(f"{where}: {instance!r} is not an http(s) URL")
    if isinstance(instance, (int, float)) and not isinstance(instance, bool):
        if "minimum" in schema and instance < schema["minimum"]:
            errors.append(f"{where}: less than {schema['minimum']}")
        if "maximum" in schema and instance > schema["maximum"]:
            errors.append(f"{where}: greater than {schema['maximum']}")
    if isinstance(instance, list):
        if "minItems" in schema and len(instance) < schema["minItems"]:
            errors.append(f"{where}: fewer than {schema['minItems']} items")
        if schema.get("uniqueItems"):
            seen = [json.dumps(i, sort_keys=True) for i in instance]
            if len(seen) != len(set(seen)):
                errors.append(f"{where}: items are not unique")
        if "items" in schema:
            for i, item in enumerate(instance):
                errors += validate(item, schema["items"], root, f"{pointer}/{i}")
    if isinstance(instance, dict):
        props = schema.get("properties", {})
        for name in schema.get("required", []):
            if name not in instance:
                errors.append(f"{where}: required property {name!r} is missing")
        for name, value in instance.items():
            if name in props:
                errors += validate(value, props[name], root, f"{pointer}/{name}")
            elif schema.get("additionalProperties") is False:
                errors.append(f"{where}: additional property {name!r} is not allowed")
    return errors


# --------------------------------------------------------------------------
# Version extraction
# --------------------------------------------------------------------------

def _strip_v(version):
    return version[1:] if re.match(r"^v\d", version) else version


def _pep503(name):
    return re.sub(r"[-_.]+", "-", name).lower()


def _read(path):
    return path.read_text(encoding="utf-8") if path.is_file() else None


def _from_dockerfile(gen_dir, arg):
    text = _read(gen_dir / f"{gen_dir.name}.dockerfile")
    if text is None:
        return None
    m = re.search(rf"^\s*ARG\s+{re.escape(arg)}=\"?([^\s\"]+)\"?\s*$", text, re.M)
    return m.group(1) if m else None


def _from_npm(gen_dir, name):
    lock = _read(gen_dir / "package-lock.json")
    if lock is not None:
        data = json.loads(lock)
        pkg = data.get("packages", {}).get(f"node_modules/{name}")
        if pkg and pkg.get("version"):
            return pkg["version"]
        dep = data.get("dependencies", {}).get(name)
        if isinstance(dep, dict) and dep.get("version"):
            return dep["version"]
        return None
    manifest = _read(gen_dir / "package.json")
    if manifest is not None:
        spec = json.loads(manifest).get("dependencies", {}).get(name, "")
        if re.fullmatch(r"\d+\.\d+\.\d+([-+][0-9A-Za-z.-]+)?", spec):
            return spec
    return None


def _from_gem(gen_dir, name):
    text = _read(gen_dir / "Gemfile.lock")
    if text is None:
        return None
    m = re.search(rf"^    {re.escape(name)} \(([^)\s]+)\)$", text, re.M)
    return m.group(1) if m else None


def _from_composer(gen_dir, name):
    text = _read(gen_dir / "composer.lock")
    if text is None:
        return None
    for pkg in json.loads(text).get("packages", []):
        if pkg.get("name") == name or pkg.get("name", "").endswith("/" + name):
            return pkg.get("version")
    return None


def _from_pip(gen_dir, name):
    text = _read(gen_dir / "requirements.txt")
    if text is None:
        return None
    for line in text.splitlines():
        m = re.match(r"^\s*([A-Za-z0-9][A-Za-z0-9._-]*)\s*==\s*([^\s;#]+)", line)
        if m and _pep503(m.group(1)) == _pep503(name):
            return m.group(2)
    return None


SOURCES = {
    "dockerfile": _from_dockerfile,
    "npm": _from_npm,
    "gem": _from_gem,
    "composer": _from_composer,
    "pip": _from_pip,
}


def extract_version(gen_dir, gen_id, version_from=None):
    """Return the pinned generator version, or None. See plan.md 'Version extraction'."""
    gen_dir = Path(gen_dir)
    if version_from:
        found = SOURCES[version_from["source"]](gen_dir, version_from["name"])
        return _strip_v(found) if found else None
    candidates = list(dict.fromkeys([gen_id, gen_id.split("-")[0]]))
    for source, fn in SOURCES.items():
        for cand in candidates:
            key = cand.upper().replace("-", "_") + "_VERSION" if source == "dockerfile" else cand
            found = fn(gen_dir, key)
            if found:
                return _strip_v(found)
    return None


# --------------------------------------------------------------------------
# Build
# --------------------------------------------------------------------------

def _load_schema(root, name):
    return json.loads((root / "schema" / name).read_text(encoding="utf-8"))


def discover(root):
    """Generator dirs: <Lang>/<name>/ containing benchmark_config.json (same glob as the toolset)."""
    return sorted(p.parent for p in root.glob("*/*/benchmark_config.json") if not p.parts[-3].startswith("."))


def _load_json(path, rel, errors):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        errors.append(f"{rel}: missing")
    except json.JSONDecodeError as exc:
        errors.append(f"{rel}: invalid JSON ({exc})")
    return None


def _runtime_errors(rel, runtime, gen_dir):
    for prefix, arg in RUNTIME_ARGS.items():
        if runtime == prefix or runtime.startswith(prefix + " "):
            pinned = _from_dockerfile(gen_dir, arg)
            m = re.match(rf"^{re.escape(prefix)} v?(\d+(?:\.\d+)*)", runtime)
            if pinned and m and m.group(1) != pinned:
                return [f"{rel}: /runtime: {runtime!r} disagrees with dockerfile {arg}={pinned}"]
    return []


def _order(obj, schema, root_schema):
    """Recursively order dict keys by schema 'properties' order."""
    while "$ref" in schema:
        target = root_schema
        for part in schema["$ref"][2:].split("/"):
            target = target[part]
        schema = target
    if isinstance(obj, dict):
        props = schema.get("properties", {})
        keys = [k for k in props if k in obj] + sorted(k for k in obj if k not in props)
        return {k: _order(obj[k], props.get(k, {}), root_schema) for k in keys}
    if isinstance(obj, list):
        return [_order(i, schema.get("items", {}), root_schema) for i in obj]
    return obj


_INDEX_SCHEMA_CACHE = {}


def order(index, root=None):
    root = Path(root) if root else Path(__file__).resolve().parents[1]
    schema = _INDEX_SCHEMA_CACHE.setdefault(root, _load_schema(root, "generators.schema.json"))
    return _order(index, schema, schema)


def build(root, raw_base=DEFAULT_RAW_BASE, generated_from=None):
    """Return (index, errors). errors is a list of human-readable strings."""
    root = Path(root)
    gen_schema = _load_schema(root, "generator.schema.json")
    idx_schema = _load_schema(root, "generators.schema.json")
    errors, generators = [], []
    if not raw_base.endswith("/"):
        errors.append(f"--raw-base must end with '/': {raw_base}")

    for gen_dir in discover(root):
        rel = gen_dir.relative_to(root).as_posix()
        meta = _load_json(gen_dir / "generator.json", f"{rel}/generator.json", errors)
        config = _load_json(gen_dir / "benchmark_config.json", f"{rel}/benchmark_config.json", errors)
        if meta is None or config is None:
            continue
        where = f"{rel}/generator.json"
        schema_errors = validate(meta, gen_schema)
        errors += [f"{where}: {e}" for e in schema_errors]
        if schema_errors:
            continue
        name = gen_dir.name
        if meta["id"] != name:
            errors.append(f"{where}: /id {meta['id']!r} does not match directory {name!r}")
        if config.get("framework") != meta["id"]:
            errors.append(f"{where}: /id {meta['id']!r} does not match benchmark_config.json framework "
                          f"{config.get('framework')!r}")
        for required in (f"{name}.dockerfile", "README.md"):
            if not (gen_dir / required).is_file():
                errors.append(f"{rel}: {required} is missing")
        errors += _runtime_errors(where, meta["runtime"], gen_dir)
        version = extract_version(gen_dir, name, meta.get("versionFrom"))
        if not version:
            errors.append(f"{where}: no pinned version found for {name!r} (dockerfile ARG or lockfile); "
                          f"add versionFrom")
        try:
            default = config["tests"][0]["default"]
            content = config["content"][0]
            cfg = config["config"][0]
            derived_bench = {
                "displayName": default["display_name"],
                "versus": default["versus"],
                "contentType": content["type"],
                "contentFolder": content["folder"],
                "buildCommand": cfg["build_command"],
                "outputFolder": cfg["output_folder"],
                "outputGlob": cfg["output_glob"],
                "cacheFolders": list(cfg.get("cache_folders", [])),
            }
        except (KeyError, IndexError, TypeError) as exc:
            errors.append(f"{rel}/benchmark_config.json: missing field {exc}")
            continue
        base = f"{raw_base}{rel}/"
        entry = dict(meta)
        entry.pop("$schema", None)
        entry["path"] = rel
        entry["version"] = version
        entry["benchmark"] = {**meta["benchmark"], **derived_bench}
        entry["files"] = {
            "dockerfile": f"{base}{name}.dockerfile",
            "benchmarkConfig": f"{base}benchmark_config.json",
            "readme": f"{base}README.md",
            "generatorJson": f"{base}generator.json",
        }
        generators.append(entry)

    proposed = _load_json(root / PROPOSED_FILE, PROPOSED_FILE, errors) if (root / PROPOSED_FILE).exists() else []
    proposed = proposed or []
    if not isinstance(proposed, list):
        errors.append(f"{PROPOSED_FILE}: must be a JSON array")
        proposed = []
    gen_ids = {g["id"] for g in generators} | {d.name for d in discover(root)}
    seen = set()
    for i, item in enumerate(proposed):
        sub = {"$ref": "#/$defs/proposed", "$defs": idx_schema["$defs"]}
        errors += [f"{PROPOSED_FILE}: {e}" for e in validate(item, sub, pointer=f"/{i}")]
        pid = item.get("id") if isinstance(item, dict) else None
        if pid in gen_ids:
            errors.append(f"{PROPOSED_FILE}: proposed id {pid!r} is already a generator; remove it from proposed")
        if pid in seen:
            errors.append(f"{PROPOSED_FILE}: duplicate proposed id {pid!r}")
        seen.add(pid)

    index = {
        "schemaVersion": SCHEMA_VERSION,
        "generatedFrom": generated_from,
        "source": SOURCE,
        "generators": sorted(generators, key=lambda g: g["id"]),
        "proposed": sorted(proposed, key=lambda p: str(p.get("id", "")) if isinstance(p, dict) else ""),
    }
    if not errors:
        errors += [f"{INDEX_FILE}: {e}" for e in validate(index, idx_schema)]
    return _order(index, idx_schema, idx_schema), errors


def render(index):
    return json.dumps(index, indent=2, ensure_ascii=False) + "\n"


def _git_sha(root, ref):
    try:
        out = subprocess.run(["git", "rev-parse", "--verify", f"{ref}^{{commit}}"], cwd=root,
                             capture_output=True, text=True, check=True)
    except (OSError, subprocess.CalledProcessError):
        return None
    return out.stdout.strip() or None


def _without_generated_from(text):
    data = json.loads(text)
    if isinstance(data, dict):
        data["generatedFrom"] = None
    return render(data)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="exit 1 with a diff if generators.json is stale or invalid")
    mode.add_argument("--validate", action="store_true", help="validate generator.json files only")
    parser.add_argument("--root", default=str(Path(__file__).resolve().parents[1]), help="repository root")
    parser.add_argument("--ref", help="git ref for generatedFrom (default: HEAD; 'none' for null)")
    parser.add_argument("--raw-base", default=DEFAULT_RAW_BASE, help="base URL for files.* (must end with /)")
    args = parser.parse_args(argv)
    root = Path(args.root).resolve()

    generated_from = None
    if not (args.check or args.validate) and args.ref != "none":
        generated_from = _git_sha(root, args.ref or "HEAD")
        if args.ref and generated_from is None:
            if re.fullmatch(r"[0-9a-f]{40}", args.ref):
                generated_from = args.ref
            else:
                print(f"error: cannot resolve --ref {args.ref!r}", file=sys.stderr)
                return 2

    index, errors = build(root, raw_base=args.raw_base, generated_from=generated_from)
    if errors:
        for e in errors:
            print(f"error: {e}", file=sys.stderr)
        print(f"{len(errors)} error(s); {INDEX_FILE} not {'checked' if args.check else 'written'}.",
              file=sys.stderr)
        return 1
    if args.validate:
        print(f"ok: {len(index['generators'])} generator(s), {len(index['proposed'])} proposed; all valid.")
        return 0

    target = root / INDEX_FILE
    fresh = render(index)
    current = target.read_text(encoding="utf-8") if target.exists() else None

    if args.check:
        if current is None:
            print(f"{INDEX_FILE} is missing; run: python3 tools/build_index.py")
            return 1
        try:
            current_norm = _without_generated_from(current)
        except json.JSONDecodeError:
            current_norm = current
        fresh_norm = _without_generated_from(fresh)
        if current_norm != fresh_norm:
            sys.stdout.writelines(difflib.unified_diff(
                current_norm.splitlines(True), fresh_norm.splitlines(True),
                f"{INDEX_FILE} (committed)", f"{INDEX_FILE} (expected)"))
            print(f"\n{INDEX_FILE} is stale; run: python3 tools/build_index.py")
            return 1
        print(f"ok: {INDEX_FILE} is up to date ({len(index['generators'])} generators, "
              f"{len(index['proposed'])} proposed).")
        return 0

    if current is not None:
        try:
            if _without_generated_from(current) == _without_generated_from(fresh):
                print(f"{INDEX_FILE} unchanged.")
                return 0
        except json.JSONDecodeError:
            pass
    target.write_text(fresh, encoding="utf-8")
    print(f"wrote {INDEX_FILE} ({len(index['generators'])} generators, {len(index['proposed'])} proposed).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
