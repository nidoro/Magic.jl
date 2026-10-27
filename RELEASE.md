### v0.9.2 (2026-10-26)

- New: dark theme and theme related functions `set_default_theme`, `set_theme`, `get_theme`.
- New: `highlight` argument on `link` function.
- New: `cycle_button` widget, a button that cycles through a list of options on each click.
- New: `onchange` and `args` arguments on `radio` function.
- New: `show_label` and `horizontal` arguments on `radio` function.
- New: `"static"` option for the `top_bar` argument of `set_page_layout`, for a top bar that scrolls with the page.
- Change: `radio` now displays its label by default, and stacks its options vertically by default. Use `horizontal=true` to place them side by side.
- Deprecated: `top_bar="fixed"` on `set_page_layout`. It now prints a deprecation warning and behaves like `top_bar="sticky"`.
- Bug-fix: top bar not shrinking when a sidebar is expanded.
