### v0.9.0 (2026-10-17)

- New: `@job` macro for running long running computations with visual
progress feedback.
- New: `dialog` function for creating modal-style container.
- New: `expander` function to create an expandable container.
- New: `markdown` function for rendering markdown as HTML.
- New: `top_bar` function for displaying a top bar. Must be initialized in
`set_page_layout`.
- New: `rerun` function for reruning the app or a specific fragment.
- New: `column` and `row` can now take a `link` argument.
- Breaking: `fragment` signature change.
- Change: `set_app_data`, `set_page_data` and `set_session_data` can now hold
keyed data. Their respective getters can now accept a key `String` for
retrieving keyed data.
- Change: new styling arguments for `button` and `link`.
- Change: `dataframe` widget now fits data height by default. `height` argument
became optional. It also accepts other arguments.
- Bug-fix: Percent-encoded URL query params now decode UTF-8 correctly.
- Bug-fix: Page title and description are escaped in the generated HTML.
- Bug-fix: selectbox passes args to onchange.
- Bug-fix: link icon is rendered properly.
- Bug-fix: icon(weight=...) works.
- Bug-fix: Several functions no longer fail when given SubStrings.
- Bug-fix: Widgets of removed nested fragments are cleaned up.
- Bug-fix: HTTPS URI mapping works with any number of pages.
- Bug-fix: The net layer frees its memory and shuts down cleanly.
- Bug-fix: The fragment opacity fade now goes back to fully visible smoothly.
- Internal: New example `TSP` for showcasing `@job`.
- Internal: Documentation and website are now self-hosted!
