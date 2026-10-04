"""Tests for tools/build_index.py (spec docs/specs/004-generator-metadata).

Run: python3 -m pytest tests/metadata -q
The tool itself is stdlib-only; pytest is a dev dependency.
"""
import copy
import importlib.util
import json
import shutil
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("build_index", REPO / "tools" / "build_index.py")
bi = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(bi)


# ---------------------------------------------------------------- fixtures

DOCKERFILE = """FROM ubuntu:24.04
ARG HYPERFINE_VERSION=1.20.0
ARG NODE_VERSION=24.21.0
"""


def bench_config(name, lang="JavaScript", cache=None):
    cfg = {
        "metadata_dateslug": "date",
        "metadata_layout": "",
        "build_command": f"{name} build",
        "build_verbose": "",
        "output_folder": "public",
        "output_glob": "posts/*/index.html",
    }
    if cache is not None:
        cfg["cache_folders"] = cache
    return {
        "framework": name,
        "tests": [{"default": {
            "approach": "Realistic", "classification": "Micro", "framework": name,
            "language": lang, "display_name": name.title(), "notes": "", "versus": lang.lower(),
        }}],
        "content": [{"folder": "content/posts", "type": "3minus", "extension": "md"}],
        "config": [cfg],
    }


def meta(name, **over):
    m = {
        "id": name,
        "name": name.title(),
        "description": f"{name} is a test generator.",
        "homepage": f"https://{name}.example.org",
        "repository": f"https://github.com/example/{name}",
        "license": "MIT",
        "language": "JavaScript",
        "runtime": "Node.js 24.21.0",
        "templateEngines": ["Nunjucks"],
        "contentFormats": ["markdown"],
        "category": "general",
        "maintained": True,
        "benchmark": {"status": "active"},
    }
    m.update(over)
    return m


def add_generator(root, lang, name, *, metadata=True, dockerfile=DOCKERFILE, files=None, cache=None, **over):
    d = root / lang / name
    (d / "src").mkdir(parents=True)
    (d / "benchmark_config.json").write_text(json.dumps(bench_config(name, lang, cache)))
    (d / f"{name}.dockerfile").write_text(dockerfile)
    (d / "README.md").write_text(f"# {name}\n")
    (d / "build.sh").write_text("#!/bin/bash\n")
    for rel, content in (files or {}).items():
        (d / rel).write_text(content)
    if metadata:
        (d / "generator.json").write_text(json.dumps(meta(name, **over), indent=2) + "\n")
    return d


def lock_v3(pkg, version):
    return json.dumps({"lockfileVersion": 3, "packages": {
        "": {"dependencies": {pkg: version}},
        f"node_modules/{pkg}": {"version": version},
        f"node_modules/{pkg}/node_modules/other": {"version": "9.9.9"},
    }})


@pytest.fixture
def repo(tmp_path):
    root = tmp_path / "repo"
    (root / "tools").mkdir(parents=True)
    shutil.copytree(REPO / "schema", root / "schema")
    (root / "tools" / "proposed.json").write_text("[]\n")
    add_generator(root, "JavaScript", "zeta", files={"package-lock.json": lock_v3("zeta", "2.0.1")})
    add_generator(root, "Go", "alpha", dockerfile=DOCKERFILE + "ARG ALPHA_VERSION=0.5.0\n",
                  language="Go", runtime="Go binary", cache=["resources/_gen"])
    return root


def run(root, *args):
    return bi.main(["--root", str(root), *args])


# ------------------------------------------------------- version extraction

@pytest.mark.parametrize("gid,files,dockerfile,expected", [
    ("alpha", {}, DOCKERFILE + "ARG ALPHA_VERSION=0.167.0\n", "0.167.0"),
    ("meta-variant", {}, DOCKERFILE + "ARG META_VERSION=1.2.3\n", "1.2.3"),
    ("gats", {"package-lock.json": lock_v3("gats", "5.16.1")}, DOCKERFILE, "5.16.1"),
    ("ms-hbs", {"package-lock.json": lock_v3("ms", "2.7.0")}, DOCKERFILE, "2.7.0"),
    ("old", {"package-lock.json": json.dumps({"lockfileVersion": 1, "dependencies": {"old": {"version": "1.0.0"}}})},
     DOCKERFILE, "1.0.0"),
    ("pj", {"package.json": json.dumps({"dependencies": {"pj": "3.1.4"}})}, DOCKERFILE, "3.1.4"),
    ("jek", {"Gemfile.lock": "GEM\n  remote: https://rubygems.org/\n  specs:\n    jek (4.4.1)\n"
             "      liquid (~> 4.0)\n    liquid (4.0.4)\n\nDEPENDENCIES\n  jek (= 4.4.1)\n"}, DOCKERFILE, "4.4.1"),
    ("jig", {"composer.lock": json.dumps({"packages": [{"name": "illuminate/view", "version": "v13.0.0"},
                                                       {"name": "tightenco/jig", "version": "v1.8.8"}]})},
     DOCKERFILE, "1.8.8"),
    ("nik-mako", {"requirements.txt": "Mako==1.4.3\nNik==8.3.3\n"}, DOCKERFILE, "8.3.3"),
    ("py-dots", {"requirements.txt": "py.dots==0.1\n"}, DOCKERFILE, "0.1"),
])
def test_version_extraction(tmp_path, gid, files, dockerfile, expected):
    d = add_generator(tmp_path, "X", gid, dockerfile=dockerfile, files=files, metadata=False)
    assert bi.extract_version(d, gid) == expected


def test_version_dockerfile_wins_over_lockfiles(tmp_path):
    d = add_generator(tmp_path, "X", "dup", dockerfile=DOCKERFILE + "ARG DUP_VERSION=1.0.0\n",
                      files={"package-lock.json": lock_v3("dup", "2.0.0")}, metadata=False)
    assert bi.extract_version(d, "dup") == "1.0.0"


def test_version_package_json_range_is_not_a_pin(tmp_path):
    d = add_generator(tmp_path, "X", "rng", files={"package.json": json.dumps({"dependencies": {"rng": "^3.1.4"}})},
                      metadata=False)
    assert bi.extract_version(d, "rng") is None


def test_version_from_override(tmp_path):
    d = add_generator(tmp_path, "X", "nextjs-export",
                      files={"package-lock.json": lock_v3("next", "16.3.8")}, metadata=False)
    assert bi.extract_version(d, "nextjs-export") is None
    assert bi.extract_version(d, "nextjs-export", {"source": "npm", "name": "next"}) == "16.3.8"


def test_version_from_override_dockerfile(tmp_path):
    d = add_generator(tmp_path, "X", "zz", dockerfile=DOCKERFILE + "ARG ZOLA_VERSION=0.23.6\n", metadata=False)
    assert bi.extract_version(d, "zz", {"source": "dockerfile", "name": "ZOLA_VERSION"}) == "0.23.6"


def test_missing_version_is_an_error(repo):
    add_generator(repo, "Ruby", "nover", runtime="Ruby 3.2 (Ubuntu 24.04 apt)")
    _, errors = bi.build(repo)
    assert any("nover" in e and "version" in e for e in errors)


# ---------------------------------------------------------- validation

def _errors_for(repo, name, **over):
    add_generator(repo, "JavaScript", name, files={"package-lock.json": lock_v3(name, "1.0.0")}, **over)
    _, errors = bi.build(repo)
    return [e for e in errors if name in e]


def test_valid_repo_has_no_errors(repo):
    _, errors = bi.build(repo)
    assert errors == []


def test_missing_required_field(repo):
    d = add_generator(repo, "JavaScript", "nolic", files={"package-lock.json": lock_v3("nolic", "1.0.0")})
    m = json.loads((d / "generator.json").read_text())
    del m["license"]
    (d / "generator.json").write_text(json.dumps(m))
    _, errors = bi.build(repo)
    assert any("nolic" in e and "license" in e and "required" in e for e in errors)


def test_extra_property(repo):
    errs = _errors_for(repo, "extra", stars=12)
    assert any("stars" in e and "additional" in e for e in errs)


def test_derived_field_in_generator_json_is_rejected(repo):
    errs = _errors_for(repo, "derv", version="1.0.0")
    assert any("version" in e and "additional" in e for e in errs)


def test_bad_url(repo):
    errs = _errors_for(repo, "badurl", homepage="not a url")
    assert any("/homepage" in e for e in errs)


def test_non_http_url(repo):
    errs = _errors_for(repo, "ftpurl", repository="ftp://example.org/x")
    assert any("/repository" in e for e in errs)


def test_bad_spdx(repo):
    errs = _errors_for(repo, "badspdx", license="MIT license, probably")
    assert any("/license" in e for e in errs)


def test_spdx_expression_ok(repo):
    assert _errors_for(repo, "dual", license="MIT OR Apache-2.0") == []


def test_bad_enum(repo):
    errs = _errors_for(repo, "badcat", category="cms")
    assert any("/category" in e for e in errs)


def test_id_mismatch_with_dir(repo):
    errs = _errors_for(repo, "mydir", id="otherid")
    assert any("mydir" in e and "directory" in e for e in errs)


def test_id_mismatch_with_framework(repo):
    d = add_generator(repo, "JavaScript", "fw", files={"package-lock.json": lock_v3("fw", "1.0.0")})
    cfg = json.loads((d / "benchmark_config.json").read_text())
    cfg["framework"] = "something-else"
    (d / "benchmark_config.json").write_text(json.dumps(cfg))
    _, errors = bi.build(repo)
    assert any("fw" in e and "framework" in e for e in errors)


def test_runtime_drift_against_dockerfile(repo):
    errs = _errors_for(repo, "drift", runtime="Node.js 22.0.0")
    assert any("NODE_VERSION" in e for e in errs)


def test_runtime_without_version_is_fine(repo):
    assert _errors_for(repo, "nover2", runtime="Node.js") == []


def test_invalid_json_is_reported(repo):
    d = add_generator(repo, "JavaScript", "broken", files={"package-lock.json": lock_v3("broken", "1.0.0")})
    (d / "generator.json").write_text("{nope")
    _, errors = bi.build(repo)
    assert any("broken" in e and "JSON" in e for e in errors)


def test_proposed_duplicate_of_generator(repo):
    (repo / "tools" / "proposed.json").write_text(json.dumps([{
        "id": "alpha", "name": "Alpha", "language": "Go", "repository": "https://github.com/example/alpha",
        "status": "proposed", "issue": "https://github.com/ssgberk/ssg-frameworks/issues/1"}]))
    _, errors = bi.build(repo)
    assert any("alpha" in e and "proposed" in e for e in errors)


def test_proposed_entry_validated(repo):
    (repo / "tools" / "proposed.json").write_text(json.dumps([{"id": "p1", "name": "P1"}]))
    _, errors = bi.build(repo)
    assert any("proposed" in e and "required" in e for e in errors)


def test_validator_rejects_unknown_keywords():
    with pytest.raises(bi.SchemaError):
        bi.validate({}, {"type": "object", "oneOf": []})


def test_validator_type_and_ref():
    schema = {"$defs": {"s": {"type": "string", "minLength": 2}},
              "type": "object", "properties": {"a": {"$ref": "#/$defs/s"}}, "additionalProperties": False}
    assert bi.validate({"a": "ok"}, schema) == []
    assert bi.validate({"a": "x"}, schema)
    assert bi.validate({"a": 1}, schema)
    assert bi.validate({"b": "ok"}, schema)
    assert bi.validate(True, {"type": "integer"})  # bool is not an integer


def test_schema_const_matches_tool():
    s = json.loads((REPO / "schema" / "generators.schema.json").read_text())
    assert s["properties"]["schemaVersion"]["const"] == bi.SCHEMA_VERSION


def test_schemas_stay_in_sync():
    gen = json.loads((REPO / "schema" / "generator.schema.json").read_text())
    idx = json.loads((REPO / "schema" / "generators.schema.json").read_text())
    entry = idx["$defs"]["generator"]
    for key, definition in gen["properties"].items():
        if key in ("$schema", "benchmark"):
            continue
        assert entry["properties"][key] == definition, key
    assert set(gen["required"]) <= set(entry["required"])
    for key, definition in gen["properties"]["benchmark"]["properties"].items():
        assert entry["properties"]["benchmark"]["properties"][key] == definition
    for key in gen.get("$defs", {}):
        assert idx["$defs"][key] == gen["$defs"][key], key


def test_both_schemas_use_only_supported_keywords():
    for name in ("generator.schema.json", "generators.schema.json"):
        s = json.loads((REPO / "schema" / name).read_text())
        bi.check_schema(s)  # raises SchemaError on unsupported keywords
        assert s["$schema"] == "https://json-schema.org/draft/2020-12/schema"


# ---------------------------------------------------------- derived fields

def test_derived_fields(repo):
    index, errors = bi.build(repo)
    assert errors == []
    alpha = next(g for g in index["generators"] if g["id"] == "alpha")
    assert alpha["path"] == "Go/alpha"
    assert alpha["version"] == "0.5.0"
    assert alpha["benchmark"] == {
        "status": "active", "displayName": "Alpha", "versus": "go", "contentType": "3minus",
        "contentFolder": "content/posts", "buildCommand": "alpha build", "outputFolder": "public",
        "outputGlob": "posts/*/index.html", "cacheFolders": ["resources/_gen"],
    }
    base = "https://raw.githubusercontent.com/ssgberk/ssg-frameworks/master/Go/alpha/"
    assert alpha["files"] == {
        "dockerfile": base + "alpha.dockerfile",
        "benchmarkConfig": base + "benchmark_config.json",
        "readme": base + "README.md",
        "generatorJson": base + "generator.json",
    }
    zeta = next(g for g in index["generators"] if g["id"] == "zeta")
    assert zeta["benchmark"]["cacheFolders"] == []
    assert zeta["version"] == "2.0.1"


def test_custom_raw_base(repo):
    index, _ = bi.build(repo, raw_base="https://example.org/raw/v1/")
    assert index["generators"][0]["files"]["readme"] == "https://example.org/raw/v1/Go/alpha/README.md"


def test_top_level(repo):
    index, _ = bi.build(repo, generated_from="a" * 40)
    assert list(index)[:4] == ["schemaVersion", "generatedFrom", "source", "generators"]
    assert index["schemaVersion"] == bi.SCHEMA_VERSION
    assert index["generatedFrom"] == "a" * 40
    assert index["source"] == "https://github.com/ssgberk/ssg-frameworks"
    assert [g["id"] for g in index["generators"]] == ["alpha", "zeta"]


def test_index_validates_against_index_schema(repo):
    index, _ = bi.build(repo)
    schema = json.loads((REPO / "schema" / "generators.schema.json").read_text())
    assert bi.validate(index, schema) == []
    bad = copy.deepcopy(index)
    bad["generators"][0]["files"]["readme"] = "nope"
    assert bi.validate(bad, schema)


def test_wip_three_levels_deep_is_ignored(repo):
    add_generator(repo / "_wip", "Ruby", "halfway", metadata=False)
    index, errors = bi.build(repo)
    assert errors == []
    assert "halfway" not in [g["id"] for g in index["generators"]]


# ---------------------------------------------------------- determinism

def test_deterministic_bytes(repo):
    assert run(repo, "--ref", "none") == 0
    first = (repo / "generators.json").read_bytes()
    (repo / "generators.json").unlink()
    assert run(repo, "--ref", "none") == 0
    second = (repo / "generators.json").read_bytes()
    assert first == second
    text = first.decode()
    assert text.endswith("}\n") and not text.endswith("\n\n")
    assert '\n  "generators": [' in text  # 2-space indent


def test_render_key_order_is_stable(repo):
    index, _ = bi.build(repo)
    shuffled = json.loads(json.dumps(index, sort_keys=True))
    assert bi.render(bi.order(shuffled)) == bi.render(index)


# ---------------------------------------------------------- modes

def test_check_passes_on_fresh_index(repo, capsys):
    assert run(repo) == 0
    assert run(repo, "--check") == 0


def test_check_detects_stale_index(repo, capsys):
    assert run(repo) == 0
    df = repo / "Go" / "alpha" / "alpha.dockerfile"
    df.write_text(df.read_text().replace("ALPHA_VERSION=0.5.0", "ALPHA_VERSION=0.6.0"))
    capsys.readouterr()
    assert run(repo, "--check") == 1
    out = capsys.readouterr().out
    assert '-      "version": "0.5.0"' in out and '+      "version": "0.6.0"' in out


def test_check_detects_missing_index(repo, capsys):
    assert run(repo, "--check") == 1


def test_check_detects_missing_generator_json(repo, capsys):
    assert run(repo) == 0
    (repo / "Go" / "alpha" / "generator.json").unlink()
    capsys.readouterr()
    assert run(repo, "--check") == 1
    out = capsys.readouterr()
    assert "Go/alpha" in out.out + out.err and "generator.json" in out.out + out.err


def test_check_ignores_generated_from(repo):
    assert run(repo, "--ref", "b" * 40) == 0
    assert json.loads((repo / "generators.json").read_text())["generatedFrom"] == "b" * 40
    assert run(repo, "--check") == 0


def test_write_does_not_churn_generated_from(repo):
    assert run(repo, "--ref", "c" * 40) == 0
    before = (repo / "generators.json").read_bytes()
    assert run(repo, "--ref", "d" * 40) == 0
    assert (repo / "generators.json").read_bytes() == before


def test_write_refuses_on_errors(repo):
    (repo / "Go" / "alpha" / "generator.json").unlink()
    assert run(repo) == 1
    assert not (repo / "generators.json").exists()


def test_validate_mode(repo):
    assert run(repo, "--validate") == 0
    assert not (repo / "generators.json").exists()
    (repo / "Go" / "alpha" / "generator.json").write_text(json.dumps(meta("alpha", license="??")))
    assert run(repo, "--validate") == 1

