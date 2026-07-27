#!/usr/bin/env bash
#
# Follow the AC adapter with the system power profile.
#
#   AC plugged in  -> performance
#   on battery     -> power-saver
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
# no root at all. Profile switching itself is allowed because polkit grants
# org.freedesktop.UPower.PowerProfiles.switch-profile to any *active* session,
# and the systemd --user manager session counts as active.
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

log() { printf '%s\n' "$*" >&2; }

on_battery() {
    [[ $(busctl --system get-property "$UPOWER_NAME" "$UPOWER_PATH" \
             "$UPOWER_NAME" OnBattery) == 'b true' ]]
}

# busctl prints strings as: s "performance"
current_profile() {
    local raw
    raw=$(busctl --system get-property "$PPD_NAME" "$PPD_PATH" \
              "$PPD_NAME" ActiveProfile)
    raw=${raw#s \"}
    printf '%s' "${raw%\"}"
}

wanted_profile() {
    if on_battery; then printf '%s' "$BATTERY_PROFILE"
    else printf '%s' "$AC_PROFILE"
    fi
}

apply() {
    local want have
    want=$(wanted_profile)
    have=$(current_profile)

    if [[ $have == "$want" ]]; then
        log "on $(on_battery && echo battery || echo AC): already $want"
        return 0
    fi

    if busctl --system set-property "$PPD_NAME" "$PPD_PATH" \
             "$PPD_NAME" ActiveProfile s "$want"; then
        log "on $(on_battery && echo battery || echo AC): $have -> $want"
    else
        log "FAILED to set profile $want (was $have)"
        return 1
    fi
}

# Re-check on every UPower PropertiesChanged, but only act when the AC state
# actually flipped. UPower emits on the root object for more than OnBattery, and
# a single plug event can produce several signals; comparing against the last
# seen state keeps a manual mid-cycle choice from being clobbered.
watch() {
    local last now
    last=$(on_battery && echo battery || echo ac)
    log "starting: AC state=$last, ${AC_PROFILE}(AC)/${BATTERY_PROFILE}(battery)"
    apply || true

    gdbus monitor --system --dest "$UPOWER_NAME" --object-path "$UPOWER_PATH" |
        while read -r line; do
            [[ $line == *OnBattery* ]] || continue
            now=$(on_battery && echo battery || echo ac)
            [[ $now == "$last" ]] && continue
            last=$now
            apply || true
        done
}

case "${1:-watch}" in
    watch) watch ;;
    once)  apply ;;
    status)
        printf 'AC state : %s\n' "$(on_battery && echo battery || echo plugged-in)"
        printf 'profile  : %s\n' "$(current_profile)"
        printf 'would be : %s\n' "$(wanted_profile)"
        ;;
    *)
        printf 'Usage: %s {watch|once|status}\n' "${0##*/}" >&2
        exit 2
        ;;
esac
