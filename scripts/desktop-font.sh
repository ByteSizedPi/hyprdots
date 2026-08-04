#!/usr/bin/env bash
# Switch the monospace font on every layer that sets one, in one command.
#
# Four layers set a font on this machine, and they disagree by default:
#
#   kitty          kitty/.config/kitty/kitty.conf     (stow tree, git-tracked)
#   noctalia       ~/.local/state/noctalia/settings.toml  (GUI state, NOT stowed)
#   GTK 3 / GTK 4  ~/.config/gtk-{3,4}.0/settings.ini (NOT stowed)
#   Qt / KDE       ~/.config/kdeglobals                (NOT stowed)
#
# WHY THE POSTSCRIPT NAMES ARE LOOKED UP, NOT SPELT OUT
# kitty's `font_features` is keyed by PostScript name, and the naming is not
# consistent across families: CommitMono is `CommitMonoNFM`, Victor Mono is
# `VictorMonoNFM-Regular`. A wrong name is silent — kitty keeps rendering, just
# without ligatures. So every name here comes from fc-scan on the actual file.
#
# NOT A THEME REPLACEMENT. `bar.*` and `shell.font_family` are theme keys (see
# scripts/desktop-theme/keys.conf), so the next `desktop-theme/apply.sh <name>`
# puts that theme's banked font back. To keep a font, bank it:
#   scripts/desktop-theme/save.sh <theme> --force
#
# Usage:
#   desktop-font.sh <id>       apply everywhere
#   desktop-font.sh --list     ids, and whether each is installed
#   desktop-font.sh --show     what each layer is set to right now
#   desktop-font.sh --restore  put back the pre-demo GTK/Qt files

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
state="${XDG_STATE_HOME:-$HOME/.local/state}"

kitty_conf="$repo/kitty/.config/kitty/kitty.conf"
settings="$state/noctalia/settings.toml"
gtk3="$cfg/gtk-3.0/settings.ini"
gtk4="$cfg/gtk-4.0/settings.ini"
kde="$cfg/kdeglobals"

# id -> the family stem Nerd Fonts uses. "CommitMono" yields the families
# "CommitMono Nerd Font Mono" and "CommitMono Nerd Font Propo".
declare -A STEM=(
  [commitmono]=CommitMono
  [zedmono]=ZedMono
  [victormono]=VictorMono
  [caskaydia]=CaskaydiaCove
  [firacode]=FiraCode
  [jetbrains]=JetBrainsMono
  [hurmit]=Hurmit
)

# Point size per layer. kitty counts in points, GTK and Qt in points, noctalia
# scales its own way and takes no size here.
KITTY_SIZE=11.0
UI_SIZE=10

die() {
  echo "error: $*" >&2
  exit 1
}

# Exact family match. The list is captured first on purpose: under `set -o
# pipefail` a `grep -q` that exits early SIGPIPEs the upstream command and the
# whole pipeline reports failure, so every font would look missing.
have_family() {
  local list
  list="$(fc-list : family | tr ',' '\n' | sed 's/^ *//;s/ *$//')"
  grep -qxF "$1" <<<"$list"
}

# PostScript names of the four styles kitty maps to, for one family, one per
# line. Absent styles are simply skipped: FiraCode Nerd Font Mono ships no
# italic at all.
#
# fc-list, not fc-match: fc-match ALWAYS returns a font, so an unknown style
# silently answers with Regular, and kitty then gets four lines that all name
# the regular face. The suffixes are not predictable either — Regular is
# `CaskaydiaCoveNFM-Regular` in one family and `FiraCodeNFM-Reg` in the next.
ps_names() {
  local family="$1"
  fc-list -f '%{family[0]}\t%{style[0]}\t%{postscriptname}\n' "$family" |
    awk -F'\t' -v fam="$family" '
      $1 == fam && ($2 == "Regular" || $2 == "Bold" || $2 == "Italic" || $2 == "Bold Italic") { print $3 }
    ' | sort -u
}

backup_once() {
  local f="$1"
  [ -f "$f" ] || return 0
  [ -f "$f.pre-font-demo" ] && return 0
  cp -p "$f" "$f.pre-font-demo"
  echo "  backed up $f -> $(basename "$f").pre-font-demo"
}

# ------------------------------------------------------------------- modes ---

do_list() {
  local id stem
  for id in $(printf '%s\n' "${!STEM[@]}" | sort); do
    stem="${STEM[$id]}"
    if have_family "$stem Nerd Font Mono"; then
      printf '  %-12s %-32s installed\n' "$id" "$stem Nerd Font Mono"
    else
      printf '  %-12s %-32s MISSING\n' "$id" "$stem Nerd Font Mono"
    fi
  done
}

do_show() {
  printf '  %-14s %s\n' kitty "$(sed -n 's/^font_family family="\(.*\)"/\1/p' "$kitty_conf")"
  printf '  %-14s %s\n' "noctalia bar" \
    "$(awk '/^\[/{s=$0} s=="[bar.default]" && /^font_family/{gsub(/.*= *"|"$/,""); print; exit}' "$settings")"
  printf '  %-14s %s\n' "noctalia shell" \
    "$(awk '/^\[/{s=$0} s=="[shell]" && /^font_family/{gsub(/.*= *"|"$/,""); print; exit}' "$settings")"
  printf '  %-14s %s\n' gtk3 "$(sed -n 's/^gtk-font-name=//p' "$gtk3")"
  printf '  %-14s %s\n' gtk4 "$(sed -n 's/^gtk-font-name=//p' "$gtk4")"
  printf '  %-14s %s\n' qt/kde "$(sed -n 's/^font=//p' "$kde")"
}

do_restore() {
  local f n=0
  for f in "$gtk3" "$gtk4" "$kde"; do
    [ -f "$f.pre-font-demo" ] || continue
    # A stowed path must never be replaced by mv — that is what un-manages it.
    # Once a file is in a stow package, git is the way back, not this backup.
    if [ -L "$f" ]; then
      echo "  skipped $f — now stowed, revert with: git -C $repo restore gtk/"
      continue
    fi
    mv "$f.pre-font-demo" "$f"
    echo "  restored $f"
    n=$((n + 1))
  done
  [ "$n" -gt 0 ] || echo "  nothing to restore"
  echo "  kitty.conf is git-tracked: git -C $repo restore kitty/"
  echo "  noctalia: scripts/desktop-theme/apply.sh \$(cat $repo/themes/active)"
}

# ------------------------------------------------------------------ layers ---

set_kitty() {
  local mono="$1" style ps
  local tmp
  tmp="$(mktemp)"

  # Rewrite the family, drop every old font_features line, then re-emit one per
  # style that actually exists in the new family.
  sed -e "s|^font_family family=\".*\"|font_family family=\"$mono\"|" \
    -e "s|^font_size .*|font_size $KITTY_SIZE|" \
    -e '/^font_features /d' "$kitty_conf" >"$tmp"

  local block=""
  while read -r ps; do
    [ -n "$ps" ] || continue
    block+="font_features $ps +liga +calt"$'\n'
  done < <(ps_names "$mono")
  [ -n "$block" ] || die "no PostScript names resolved for '$mono' — refusing to write kitty.conf"

  # Put the block back where the old one was: after `disable_ligatures never`.
  # The blank lines the deleted block left behind are eaten, and one is re-emitted
  # after the new block, so repeated runs do not grow a gap.
  awk -v block="$block" '
    eating { if ($0 == "") next; eating = 0 }
    { print }
    !done && /^disable_ligatures / { print ""; printf "%s\n", block; done = 1; eating = 1 }
  ' "$tmp" >"$kitty_conf"
  rm -f "$tmp"

  printf '%s' "$block" | sed 's/^/    /'
  pkill -SIGUSR1 -x kitty 2>/dev/null || true
}

set_noctalia() {
  local propo="$1" nf="$2" candidate
  candidate="$(mktemp)"

  python3 - "$settings" "$candidate" "$propo" "$nf" <<'PY'
import sys

src, dst, propo, nf = sys.argv[1:5]
want = {("[bar.default]", "font_family"): propo, ("[shell]", "font_family"): nf}
seen, section, out = set(), None, []

for line in open(src, encoding="utf-8"):
    if line.startswith("["):
        section = line.strip()
    stripped = line.split("=", 1)[0].strip()
    key = (section, stripped)
    if key in want and key not in seen:
        out.append('%s = "%s"\n' % (stripped, want[key]))
        seen.add(key)
    else:
        out.append(line)

missing = set(want) - seen
if missing:
    sys.exit("settings.toml has no %s" % ", ".join("%s %s" % m for m in sorted(missing)))

open(dst, "w", encoding="utf-8").writelines(out)
PY

  # Never go live with a file the shell cannot parse.
  local sbx
  sbx="$(mktemp -d)"
  mkdir -p "$sbx/state/noctalia" "$sbx/config/noctalia"
  cp "$candidate" "$sbx/state/noctalia/settings.toml"
  cp "$cfg/noctalia"/*.toml "$sbx/config/noctalia/" 2>/dev/null || true
  if ! NOCTALIA_CONFIG_HOME="$sbx/config" NOCTALIA_STATE_HOME="$sbx/state" \
    noctalia config validate >/dev/null 2>&1; then
    rm -rf "$sbx" "$candidate"
    die "candidate settings.toml failed 'noctalia config validate' — nothing written"
  fi
  rm -rf "$sbx"

  cp -p "$settings" "$settings.bak"
  mv "$candidate" "$settings"
  noctalia msg config-reload >/dev/null 2>&1 ||
    echo "  note: noctalia not running, change lands on next start" >&2
}

set_gtk() {
  local propo="$1" f
  for f in "$gtk3" "$gtk4"; do
    [ -f "$f" ] || continue
    backup_once "$f"
    # --follow-symlinks is load-bearing: these files are stowed (the `gtk`
    # package), and plain `sed -i` writes a temp file and renames it over the
    # target, which REPLACES the symlink with a regular file and silently
    # un-manages it. Same failure stow-audit.sh was written to catch.
    sed -i --follow-symlinks "s|^gtk-font-name=.*|gtk-font-name=$propo,  $UI_SIZE|" "$f"
  done
}

set_qt() {
  local propo="$1" mono="$2"
  [ -f "$kde" ] || return 0
  backup_once "$kde"
  # KDE stores a font as a comma-separated spec; only the family and size move.
  # kdeglobals is deliberately NOT stowed (KConfig saves by rename, which would
  # break the symlink), but --follow-symlinks costs nothing and keeps the two
  # writers here consistent.
  sed -i --follow-symlinks \
    -e "s|^font=[^,]*,[0-9]*,|font=$propo,$UI_SIZE,|" \
    -e "s|^fixed=[^,]*,[0-9]*,|fixed=$mono,$UI_SIZE,|" \
    -e "s|^menuFont=[^,]*,[0-9]*,|menuFont=$propo,$UI_SIZE,|" \
    -e "s|^toolBarFont=[^,]*,[0-9]*,|toolBarFont=$propo,9,|" \
    -e "s|^smallestReadableFont=[^,]*,[0-9]*,|smallestReadableFont=$propo,8,|" \
    -e "s|^activeFont=[^,]*,[0-9]*,|activeFont=$propo,$UI_SIZE,|" \
    "$kde"
}

# -------------------------------------------------------------------- main ---

arg="${1:-}"
case "$arg" in
  --list) do_list; exit 0 ;;
  --show) do_show; exit 0 ;;
  --restore) do_restore; exit 0 ;;
  "" | -h | --help)
    echo "usage: desktop-font.sh <id>|--list|--show|--restore"
    do_list
    exit 0
    ;;
esac

stem="${STEM[$arg]:-}"
[ -n "$stem" ] || die "unknown id '$arg' (try --list)"

mono="$stem Nerd Font Mono"
propo="$stem Nerd Font Propo"
nf="$stem Nerd Font"

have_family "$mono" || die "'$mono' is not installed — sudo dnf install ${arg}-nerd-fonts"
have_family "$propo" || die "'$propo' is not installed"
have_family "$nf" || nf="$propo" # a few families ship no unsuffixed cut

echo "applying $stem"
echo "  kitty          $mono @ ${KITTY_SIZE}pt"
set_kitty "$mono"
echo "  noctalia bar   $propo (weight 700)"
echo "  noctalia shell $nf"
set_noctalia "$propo" "$nf"
echo "  gtk 3/4        $propo @ ${UI_SIZE}pt"
set_gtk "$propo"
echo "  qt/kde         $propo @ ${UI_SIZE}pt"
set_qt "$propo" "$mono"
echo
echo "kitty reloaded. GTK and Qt apps pick it up on their next start."
