// NOTE: This script is inlined at the top of the body of the page and 404
// templates, so that the theme is applied before the first paint. Do not
// reference anything from Magic.js here.

function getCachedPreferences() {
    try {
        const preferences = JSON.parse(localStorage.getItem("mg_preferences"));
        if (["auto", "light", "dark"].includes(preferences?.theme)) {
            return preferences;
        }
    } catch (err) {
        console.warn("Failed to read cached preferences", err);
    }

    let theme = document.body.classList.contains("mg-theme-dark")
              ? "dark"
              : document.body.classList.contains("mg-theme-light")
              ? "light"
              : "auto";

    return {theme};
}

function applyTheme(theme) {
    document.body.classList.remove("mg-theme-light", "mg-theme-dark");

    if (theme == "auto") {
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        theme = prefersDark ? 'dark' : 'light';
    }

    document.body.classList.add(`mg-theme-${theme}`);
}

var mgCachedPreferences = getCachedPreferences();
applyTheme(mgCachedPreferences.theme);
