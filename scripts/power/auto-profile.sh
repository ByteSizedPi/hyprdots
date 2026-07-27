#!/usr/bin/env bash
#
# Follow the AC adapter with the system power profile and the laptop backlight.
#
#   AC plugged in  -> performance   + internal panel at 100%
#   on battery     -> power-saver   + internal panel at 50%
#
# Applied ONLY on a transition (and once at startup). Anything you select by
# hand in between is left alone until the next plug/unplug — this is a default,
# not a policy.
#
# Why not a udev rule: udev has no per-user rule directory. It runs as root out
# of /usr/lib/udev/rules.d and /etc/udev/rules.d only, so a real udev rule means
# sudo + a SYSTEM.md entry. UPower is already the userspace consumer of exactly
# those power_supply udev events and re-publishes them on the system bus as
# OnBattery, so watching UPower is the same event one hop downstream — and needs
# no root at all. Profile switching is allowed because polkit grants
# org.freedesktop.UPower.PowerProfiles.switch-profile to any *active* session,
# and the systemd --user manager session counts as active; brightnessctl reaches
# the backlight through logind from that same session.
#
# Driven by systemd/.config/systemd/user/power-profile-auto.service.
# See docs/power-profiles.md.

set -euo pipefail

PPD_NAME=org.freedesktop.UPower.PowerProfiles
PPD_PATH=/org/freedesktop/UPower/PowerProfiles
UPOWER_NAME=org.freedesktop.UPower
UPOWER_PATH=/org/freedesktop/UPower

# Override in the unit (or a drop-in) if you want different targets.
AC_PROFILE=${POWER_PROFILE_AC:-performance}
BATTERY_PROFILE=${POWER_PROFILE_BATTERY:-power-saver}

# Internal panel only. This is the eDP-1 backlight (card1-eDP-1); external
# monitors have no sysfs backlight and would need ddcutil/DDC-CI instead.
BACKLIGHT=${POWER_BACKLIGHT_DEVICE:-intel_backlight}
AC_BRIGHTNESS=${POWER_BRIGHTNESS_AC:-100}
BATTERY_BRIGHTNESS=${POWER_BRIGHTNESS_BATTERY:-50}
# Set to 0 to have startup/restart sync the profile but leave brightness alone.
BRIGHTNESS_ON_START=${POWER_BRIGHTNESS_ON_START:-1}

log() { printf '%s\n' "$*" >&2; }

on_battery() {
    [[ $(busctl --system get-property "$UPOWER_NAME" "$UPOWER_PATH" \
             "$UPOWER_NAME" OnBattery) == 'b true' ]]
}

ac_state() { on_battery && printf 'battery' || printf 'AC'; }

# busctl prints strings as: s "performance"
current_profile() {
    local raw
    raw=$(busctl --system get-property "$PPD_NAME" "$PPD_PATH" \
              "$PPD_NAME" ActiveProfile)
    raw=${raw#s \"}
    printf '%s' "${raw%\"}"
}

have_backlight() {
    command -v brightnessctl >/dev/null 2>&1 &&
        [[ -e /sys/class/backlight/$BACKLIGHT ]]
}

current_brightness_pct() {
    local now max
    now=$(< "/sys/class/backlight/$BACKLIGHT/brightness")
    max=$(< "/sys/class/backlight/$BACKLIGHT/max_brightness")
    printf '%s' $(( now * 100 / max ))
}

set_profile() {
    local state=$1 want=$2 have
    have=$(current_profile)

    if [[ $have == "$want" ]]; then
        log "on $state: profile already $want"
        return 0
    fi

    if busctl --system set-property "$PPD_NAME" "$PPD_PATH" \
             "$PPD_NAME" ActiveProfile s "$want"; then
        log "on $state: profile $have -> $want"
    else
        log "on $state: FAILED to set profile $want (was $have)"
    fi
}

set_brightness() {
    local state=$1 want=$2 have

    if ! have_backlight; then
        log "on $state: no backlight '$BACKLIGHT' (or no brightnessctl), skipping"
        return 0
    fi

    have=$(current_brightness_pct)
    if brightnessctl --device="$BACKLIGHT" --quiet set "${want}%"; then
        log "on $state: brightness ${have}% -> ${want}%"
    else
        log "on $state: FAILED to set brightness ${want}% (was ${have}%)"
    fi
}

# $1: "start" or "transition" — startup may skip the backlight, so that a
# service restart doesn't yank a brightness you set by hand.
apply() {
    local when=${1:-transition} state profile brightness
    state=$(ac_state)

    if [[ $state == battery ]]; then
        profile=$BATTERY_PROFILE brightness=$BATTERY_BRIGHTNESS
    else
        profile=$AC_PROFILE brightness=$AC_BRIGHTNESS
    fi

    set_profile "$state" "$profile"

    if [[ $when == start && $BRIGHTNESS_ON_START != 1 ]]; then
        log "on $state: brightness left alone (POWER_BRIGHTNESS_ON_START=0)"
    else
        set_brightness "$state" "$brightness"
    fi
}

# Re-check on every UPower PropertiesChanged, but only act when the AC state
# actually flipped. UPower emits on the root object for more than OnBattery, and
# a single plug event can produce several signals; comparing against the last
# seen state keeps a manual mid-cycle choice from being clobbered.
watch() {
    local last now
    last=$(ac_state)
    log "starting: AC state=$last; profile ${AC_PROFILE}/${BATTERY_PROFILE}, brightness ${AC_BRIGHTNESS}%/${BATTERY_BRIGHTNESS}% (AC/battery)"
    apply start || true

    gdbus monitor --system --dest "$UPOWER_NAME" --object-path "$UPOWER_PATH" |
        while read -r line; do
            [[ $line == *OnBattery* ]] || continue
            now=$(ac_state)
            [[ $now == "$last" ]] && continue
            last=$now
            apply transition || true
        done
}

case "${1:-watch}" in
    watch) watch ;;
    once)  apply transition ;;
    status)
        printf 'AC state   : %s\n' "$(on_battery && echo battery || echo plugged-in)"
        printf 'profile    : %s (would set %s)\n' "$(current_profile)" \
            "$(on_battery && printf '%s' "$BATTERY_PROFILE" || printf '%s' "$AC_PROFILE")"
        if have_backlight; then
            printf 'brightness : %s%% (would set %s%%)\n' "$(current_brightness_pct)" \
                "$(on_battery && printf '%s' "$BATTERY_BRIGHTNESS" || printf '%s' "$AC_BRIGHTNESS")"
        else
            printf 'brightness : no backlight device "%s"\n' "$BACKLIGHT"
        fi
        ;;
    *)
        printf 'Usage: %s {watch|once|status}\n' "${0##*/}" >&2
        exit 2
        ;;
esac
