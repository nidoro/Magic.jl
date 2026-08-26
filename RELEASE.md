### v0.7.3 (xxxx-xx-xx)

- New: multiselect `selectbox`, `checkboxes` and `radio` now can be initialized
with an heterogeneous list of values, and its value(s) will assume the value of
the selected option(s).
- Change: implemented type inference for `number_input` and `slider` based on
the provided `initial_value`/`default_value`.
- Change: `button`, `selectbox`, `checkbox`, `checkboxes`, `radio`,
`text_input`, `number_input`, `slider` now throw when given invalid arguments.
- Internal: new tests for `button`, `selectbox`, `checkbox`, `checkboxes`,
`radio`, `text_input`, `number_input`, `slider`.
