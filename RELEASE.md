### v0.8.0 (xxxx-xx-xx)

- Breaking: complete rewrite of the `metric` widget.
- New: `inject_html` function, which allows users to inject arbitrary HTML code
into the HTML page served to clients.
- New: multiselect `selectbox`, `checkboxes` and `radio` now can be initialized
with an heterogeneous list of values, and its value(s) will assume the value of
the selected option(s).
- New: `row` function now accepts the same arguments accepted by `column`.
- New: new optional argument `open_browser` of `start_app` that indicates
whether the app should be opened using the OS default browser or not.
- Change: implemented type inference for `number_input` and `slider` based on
the provided `initial_value`/`default_value`.
- Change: most elements API exported functions now throw when given invalid
arguments.
- Bug-fix: `get_current_page()` always returned `g.base_page_config`.
- Bug-fix: `slider` was not present in the `ContainerInterface` struct.
- Internal: tests implemented for most public API functions.
- Internal: new dependency `Printf`.
- Internal: partial automation of public API web documentation generation.
