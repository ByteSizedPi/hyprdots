// Enable legacy userChrome.css / userContent.css customizations so the
// Noctalia "zen-browser" community template (@import'd into chrome/userChrome.css
// and chrome/userContent.css) is actually applied. Without this, Zen ignores
// those files entirely.

// Make the browser window itself transparent on Linux/Wayland so the 0.8 chrome
// backgrounds in chrome/noctalia-transparency.css reveal the Hyprland blur behind
// them. These two prefs were previously provided by the "Transparent Zen" mod;
// pinned here so transparency no longer depends on that mod being active.
user_pref("zen.widget.linux.transparency", true);
user_pref("browser.tabs.allow_transparent_browser", true);

// Transparent Zen mod: tint its transparency with the theme base at ~0.8 alpha
// (CC = 0.8). Acts as the safety net for Zen surfaces our userChrome can't reach.
// NOTE: hardcoded to the current palette base (#181825); update the hex if the
// theme changes, or we can later auto-sync it from a Noctalia post-hook.
user_pref("mod.sameerasw.zen_bg_color_enabled", true);
user_pref("mod.sameerasw.zen_transparency_color", "#00000000");
user_pref("mod.sameerasw.zen_transparent_sidebar_enabled", true);
user_pref("devtools.chrome.enabled", true);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
