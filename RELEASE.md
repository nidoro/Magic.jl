### v0.9.4 (2026-xx-xx)

- New: `set_favicon` function for using an emoji as the favicon of a page or of the entire app.
- New: TLS support with the `tls_cert_path` and `tls_key_path` arguments of `start_app`, and the `--tls-cert-path` and `--tls-key-path` command-line options.
- Bug-fix: command-line entry point failing on every launch. The obsolete `--docs-path` option was removed.
