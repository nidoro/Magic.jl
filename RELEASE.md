### v0.8.0 (xxxx-xx-xx)

- Breaking: complete rewrite of `metric`.
- New: multiselect `selectbox`, `checkboxes` and `radio` now can be initialized
with an heterogeneous list of values, and its value(s) will assume the value of
the selected option(s).
- New: new optional argument `open_browser` of `start_app` that indicates
whether the app should be opened using the OS default browser or not.
- Change: implemented type inference for `number_input` and `slider` based on
the provided `initial_value`/`default_value`.
- Change: most elements API exported functions now throw when given invalid
arguments.
- Internal: new tests for `button`, `selectbox`, `checkbox`, `checkboxes`,
`radio`, `text_input`, `number_input`, `slider`.
- Internal: new dependency: `Printf`.
