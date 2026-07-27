#!/usr/bin/env python3
"""TOML surgery for the Noctalia theme system.

Noctalia's precedence is state/settings.toml > config/noctalia/config.toml
(verified: config.toml only fills keys settings.toml does NOT mention). So a
theme cannot live in config.toml — it has to be written INTO settings.toml,
which is also GUI-managed and full of machine-specific keys we must not clobber.
Hence this tool: it splits settings.toml along the theme/not-theme line defined
in scripts/desktop-theme/keys.conf.

Output is always flat dotted-key TOML ("bar.default.border_width = 2.0"), which
Noctalia's parser accepts (checked with `noctalia config validate`) and which is
trivial to diff in git — one line per setting, no nesting to reshuffle.

Commands:
  extract <settings.toml> <keys.conf>              theme keys only        -> stdout
  strip   <settings.toml> <keys.conf>              everything else        -> stdout
  merge   <settings.toml> <keys.conf> <theme.toml> strip + theme applied  -> stdout

Only stdlib (tomllib, 3.11+) — no tomlkit/tomli-w to install on a new machine.
"""
import fnmatch
import re
import sys
import tomllib

BARE_KEY = re.compile(r"^[A-Za-z0-9_-]+$")  # TOML bare-key charset; else must quote


def load_patterns(path):
    """Read keys.conf into (includes, excludes) glob lists."""
    inc, exc = [], []
    with open(path) as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()  # strip trailing comments
            if not line:
                continue
            (exc if line.startswith("!") else inc).append(line.lstrip("!"))
    return inc, exc


def is_theme_key(key, inc, exc):
    """True if this dotted key is part of the theme surface. Exclusions win."""
    if any(fnmatch.fnmatchcase(key, p) for p in exc):
        return False
    return any(fnmatch.fnmatchcase(key, p) for p in inc)


def flatten(obj, prefix=""):
    """Walk nested tables into (dotted_key, value) leaves.

    Lists are treated as leaves, not descended into — an array of tables like
    bar.default.capsule_group round-trips as a single inline-table array, which
    Noctalia accepts and which keeps one setting on one line.
    """
    if isinstance(obj, dict) and obj:
        for k, v in obj.items():
            yield from flatten(v, f"{prefix}.{k}" if prefix else k)
    else:
        yield prefix, obj


def fmt_key(dotted):
    """Quote any path segment that isn't a legal TOML bare key."""
    return ".".join(s if BARE_KEY.match(s) else f'"{s}"' for s in dotted.split("."))


def fmt_val(v):
    """Render a Python value as a TOML value expression."""
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, str):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(v, float):
        # Noctalia writes float-typed settings; keep them floats so the schema
        # still sees a float after a round-trip (repr keeps 2.0 as "2.0").
        return repr(v)
    if isinstance(v, int):
        return str(v)
    if isinstance(v, list):
        return "[ " + ", ".join(fmt_val(x) for x in v) + " ]" if v else "[]"
    if isinstance(v, dict):
        return "{ " + ", ".join(f"{fmt_key(k)} = {fmt_val(x)}" for k, x in v.items()) + " }"
    raise SystemExit(f"settings-toml: cannot serialise {type(v).__name__} at value {v!r}")


def emit(pairs, header=None):
    """Print dotted-key TOML, sorted so git diffs stay stable."""
    if header:
        print(header)
    for k, v in sorted(pairs):
        print(f"{fmt_key(k)} = {fmt_val(v)}")


def read(path):
    with open(path, "rb") as fh:
        return dict(flatten(tomllib.load(fh)))


def main():
    if len(sys.argv) < 4:
        raise SystemExit(__doc__)
    cmd, settings, keys = sys.argv[1], sys.argv[2], sys.argv[3]
    inc, exc = load_patterns(keys)
    live = read(settings)

    if cmd == "extract":
        emit((k, v) for k, v in live.items() if is_theme_key(k, inc, exc))

    elif cmd == "strip":
        emit((k, v) for k, v in live.items() if not is_theme_key(k, inc, exc))

    elif cmd == "merge":
        if len(sys.argv) < 5:
            raise SystemExit("merge needs <theme.toml>")
        theme = read(sys.argv[4])
        # Refuse to apply a theme file that reaches outside the theme surface —
        # that would silently rewrite behaviour or machine config.
        stray = sorted(k for k in theme if not is_theme_key(k, inc, exc))
        if stray:
            raise SystemExit(
                "settings-toml: theme file sets non-theme keys, refusing:\n  "
                + "\n  ".join(stray)
                + "\n(add them to keys.conf, or remove them from the theme)"
            )
        kept = {k: v for k, v in live.items() if not is_theme_key(k, inc, exc)}
        kept.update(theme)  # theme owns its surface outright
        emit(kept.items())

    else:
        raise SystemExit(f"settings-toml: unknown command {cmd!r}")


if __name__ == "__main__":
    main()
