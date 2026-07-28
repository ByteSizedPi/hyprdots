#!/usr/bin/env bash
# Check a Noctalia plugin before enabling it: manifest lint AND Luau syntax.
#
# WHY: `noctalia plugins lint` does NOT check syntax. Measured 2026-07-28 — appending
# literal garbage to a .luau entry still gave "0 errors, 0 warnings", because lint's
# job is only cross-checking declared settings against getConfig() calls. Worse,
# Noctalia gives no CLI signal at runtime either: a plugin whose entry fails to parse
# still reports `enabled`, and `panel-toggle` still answers `ok`. You just get an
# empty panel and no explanation.
#
# So this adds the missing half. There's no luau binary here, so entries are checked
# with Lua 5.4's parser after rewriting Luau's backtick interpolation (`a {b} c`) into
# concatenation. That covers ordinary syntax errors — unbalanced brackets, stray
# tokens, bad statements. It will NOT understand Luau-only syntax beyond backticks
# (type annotations, `continue`), so a false positive means "check by hand", not
# "broken".
#
# Usage: scripts/noctalia-plugin-check.sh [plugin-dir ...]
#        defaults to noctalia/.config/noctalia/plugins/*
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dirs=("$@")
if [ ${#dirs[@]} -eq 0 ]; then
  mapfile -t dirs < <(find "$repo/noctalia/.config/noctalia/plugins" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
fi
[ ${#dirs[@]} -gt 0 ] || {
  echo "no plugin directories found"
  exit 0
}

fail=0

for dir in "${dirs[@]}"; do
  echo "== $(basename "$dir")"

  if command -v noctalia >/dev/null 2>&1; then
    if ! noctalia plugins lint "$dir" 2>&1 | sed 's/^/   /'; then
      fail=1
    fi
  else
    echo "   (noctalia not on PATH — skipping manifest lint)"
  fi

  if ! command -v luac >/dev/null 2>&1; then
    echo "   (luac not installed — skipping syntax check; dnf install lua)"
    continue
  fi

  while IFS= read -r entry; do
    tmp="$(mktemp --suffix=.lua)"
    python3 - "$entry" >"$tmp" <<'PY'
import re, sys
src = open(sys.argv[1]).read().replace("--!nonstrict", "").replace("--!strict", "")

def conv(m):
    body, parts, buf, i = m.group(1), [], "", 0
    while i < len(body):
        if body[i] == "{":
            depth, j = 1, i + 1
            while j < len(body) and depth:
                depth += (body[j] == "{") - (body[j] == "}")
                j += 1
            if buf:
                parts.append('"%s"' % buf.replace('"', '\\"'))
                buf = ""
            parts.append("tostring(%s)" % body[i + 1 : j - 1])
            i = j
        else:
            buf += body[i]
            i += 1
    if buf:
        parts.append('"%s"' % buf.replace('"', '\\"'))
    return "(" + (" .. ".join(parts) if parts else '""') + ")"

sys.stdout.write(re.sub(r"`([^`]*)`", conv, src))
PY
    if err="$(luac -p "$tmp" 2>&1)"; then
      printf '   syntax ok  %s\n' "$(basename "$entry")"
    else
      printf '   SYNTAX ERROR in %s\n' "$(basename "$entry")"
      # line numbers refer to the rewritten file, but the message and the token
      # are the useful parts
      printf '     %s\n' "${err#luac: }"
      fail=1
    fi
    rm -f "$tmp"
  done < <(find "$dir" -name "*.luau" -type f)
done

exit "$fail"
