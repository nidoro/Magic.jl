### v0.9.4 (2026-11-02)

- New: `set_favicon` function for using an emoji as the favicon of a page or of the entire app.
- New: TLS support with the `tls_cert_path` and `tls_key_path` arguments of `start_app`, and the `--tls-cert-path` and `--tls-key-path` command-line options.
- New: `choices` widget, a group of connected buttons for selecting one option or, with `multiple=true`, several options.
- New: `allow_nothing` argument of `radio`, which lets the user deselect the selected option, making the value `nothing`.
- New: `show_label` and `horizontal` arguments of `checkboxes`.
- Change: `checkboxes` now displays its `label` above the options, like `radio`. Use `show_label=false` to hide it.
- Bug-fix: command-line entry point failing on every launch. The obsolete `--docs-path` option was removed.
