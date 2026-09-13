### v0.8.0 (xxxx-xx-xx)

- Breaking: complete rewrite of the `metric` widget, changing its signature.
- Breaking: implemented type inference for `number_input` and `slider` based on
the provided `initial_value`/`default_value`.
- New: `inject_html` function, which allows users to inject arbitrary HTML code
into the HTML page served to clients.
- New: multiselect `selectbox`, `checkboxes` and `radio` now can be initialized
with an heterogeneous list of values, and its value(s) will assume the value of
the selected option(s).
- New: `get_query_params` and `get_url_search` functions to inspect the query
parameters of the current session.
- New: `get_server_host` and `get_server_origin` functions to retrieve server
address info.
- New: `row` function now accepts the same arguments accepted by `column`.
- New: new optional argument `open_browser` of `start_app` that indicates
whether the app should be opened using the OS default browser or not.
- Change: most elements API exported functions now throw when given invalid
arguments.
- Bug-fix: `get_current_page()` always returned `g.base_page_config`.
- Bug-fix: `slider` was not present in the `ContainerInterface` struct.
- Internal: new dependency `Printf`.
- Internal: tests implemented for most public API functions.
- Internal: partial automation of public API web documentation generation.
