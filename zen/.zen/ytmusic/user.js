// Prefs for the YouTube Music web app profile (~/.zen/ytmusic).
//
// This profile is launched by the special:youtube workspace rule in
// hyprland/.config/hypr/modules/scratchpads.lua with `--name zen-ytmusic`, which
// gives the window its own Wayland app_id. It is NOT registered in profiles.ini,
// so the profile manager and the main Zen window never see it.

// Load chrome/userChrome.css (Noctalia theme + transparency + hidden chrome).

// Same transparent window as the main profile.
user_pref("zen.widget.linux.transparency", true);
user_pref("browser.tabs.allow_transparent_browser", true);

// Web-app look: compact mode hides the sidebar and the toolbar. Both come back
// when the pointer touches the left edge, so the URL bar is still reachable.
user_pref("zen.view.compact.enable-at-startup", true);
user_pref("zen.view.compact.hide-tabbar", true);
user_pref("zen.view.compact.hide-toolbar", true);

// Open YouTube Music on every start and restore nothing else.
user_pref("browser.startup.page", 1);
user_pref("browser.startup.homepage", "https://music.youtube.com/");
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("zen.welcome-screen.seen", true);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.shell.checkDefaultBrowser", false);

// Enable the .xpi files copied into extensions/ without a prompt. Scope 1 is
// the profile. The default (15) disables sideloaded add-ons until approved.
user_pref("extensions.autoDisableScopes", 0);

// No welcome page, privacy page, or "what's new" page on first start or after
// a Zen update. The first test start opened the Zen changelog without these.
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
user_pref("startup.homepage_override_url", "");
user_pref("browser.startup.homepage_override.mstone", "ignore");

// Transparent Zen mod (chrome/zen-themes/, copied from the main profile, not
// tracked). Zen Internet makes the page transparent, this mod makes the
// browser area behind the page transparent. Without it the page stays opaque.
// Values copied from the main profile prefs.js on 2026-10-07.
user_pref("mod.sameerasw.zen_bg_blur", "3px");
user_pref("mod.sameerasw.zen_bg_color_enabled", true);
user_pref("mod.sameerasw.zen_bg_img", "url('https://github.com/sameerasw/my-internet/blob/main/wallpapers/zen-coral-01.jpeg?raw=true')");
user_pref("mod.sameerasw.zen_bg_img_enabled", false);
user_pref("mod.sameerasw.zen_bg_img_not_fullscreen", false);
user_pref("mod.sameerasw.zen_bg_opacity", "0.8");
user_pref("mod.sameerasw.zen_compact_sidebar_width", "165px");
user_pref("mod.sameerasw.zen_no_shadow", false);
user_pref("mod.sameerasw.zen_notab_img", "url('https://github.com/sameerasw/my-internet/blob/main/wave-light.png?raw=true')");
user_pref("mod.sameerasw.zen_notab_img_opacity", "1");
user_pref("mod.sameerasw.zen_notab_img_size", "150px");
user_pref("mod.sameerasw.zen_tab_switch_anim", false);
user_pref("mod.sameerasw.zen_trackpad_anim", false);
user_pref("mod.sameerasw.zen_transparency_color", "#00000000");
user_pref("mod.sameerasw.zen_transparent_glance_enabled", false);
user_pref("mod.sameerasw.zen_transparent_sidebar_enabled", true);
user_pref("mod.sameerasw.zen_urlbar_zoom_anim", false);
user_pref("mod.sameerasw_zen_animations", "1");
user_pref("mod.sameerasw_zen_compact_sidebar_type", "0");
user_pref("mod.sameerasw_zen_empty_tab_logo", "0");
user_pref("mod.sameerasw_zen_light_tint", "2");
user_pref("devtools.chrome.enabled", true);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
