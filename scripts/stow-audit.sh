#!/usr/bin/env bash
# Check that every file in every stow package actually reaches $HOME as a symlink
# back into this repo.
#
# WHY THIS EXISTS: a config file that stops being a symlink stops being managed —
# silently. The repo copy still looks authoritative, git stays clean, and the live
# file drifts. Found twice on this machine:
#
#   kitty.conf          `kitten themes` rewrites it in place, leaving a .bak. Cost
#                       us `map ctrl+shift+t no_op` for weeks (2026-07-28).
#   yazi/theme.toml     an older Noctalia community template used mktemp + mv, which
#   zen/user.js         replaces the symlink rather than writing through it. Both
#                       upstream scripts now `cat tmp > target` instead — yazi's even
#                       carries the comment "Write through a symlink instead of
#                       replacing it via mv".
#
# So: any tool that writes atomically (temp file + rename) to a stowed path will
# quietly un-manage it. Run this after adding a package, or when a config change
# "doesn't take".
#
# Usage: scripts/stow-audit.sh          (exit 1 if anything drifted)
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
not_packages="docs scripts themes"

drift=0
missing=0
ok=0

for pkg_dir in "$repo"/*/; do
  pkg="$(basename "$pkg_dir")"
  case " $not_packages " in *" $pkg "*) continue ;; esac

  while IFS= read -r file; do
    rel="${file#"$pkg_dir"}"

    # Stow's built-in ignore list — these never get linked, and that's correct.
    # (Full list also covers RCS/CVS/.svn/.hg/backup files; these are the ones that
    # actually show up here.)
    case "$rel" in
      README* | LICENSE* | COPYING) continue ;;
      .git | .gitignore | .gitmodules | *'~' | .claude/* | */.claude/*) continue ;;
    esac

    target="$HOME/$rel"
    want="$(readlink -f "$file")"

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
      printf '  NOT STOWED  %-12s %s\n' "$pkg" "$rel"
      missing=$((missing + 1))
    elif [ "$(readlink -f "$target")" = "$want" ]; then
      ok=$((ok + 1))
    else
      printf '  DRIFTED     %-12s %s\n' "$pkg" "$rel"
      printf '              repo: %s\n' "$want"
      printf '              live: %s\n' "$(readlink -f "$target")"
      drift=$((drift + 1))
    fi
  done < <(find "$pkg_dir" -type f)
done

echo
printf '  linked: %d   drifted: %d   not stowed: %d\n' "$ok" "$drift" "$missing"

if [ "$drift" -gt 0 ]; then
  echo
  echo "  To fix one: check the repo copy is what you want (the LIVE file may have"
  echo "  changes worth keeping first — diff them), then:"
  echo "      cp <live> <repo>     # only if live is ahead"
  echo "      rm <live> && stow -R <package>"
  exit 1
fi
