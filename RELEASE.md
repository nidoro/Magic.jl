### v0.5.0 (2026-01-31)

- Breaking-change: renamed `gen_resource_path` to `gen_serveable_path`.
Additionally, this function now generates file names without extension when
an empty string is passed to extension, which is now the default value of the
argument.
- New: Widget `file_uploader()`.
- New: Widget `download_button()`.
- New: Function `make_serveable_copy()`.
- New: Function `move_to_serveable_dir()`.
- New: Example `image-filters.jl`.
- New: A `.gitignore` file is now automatically generated inside `.Magic` if
it doesn't exist.
- New: New `start_app()` arguments `upload_max_size` and `upload_max_files`.
- Change: if a non-serveable path is passed to `image()` and the path points
to an existing file, a serveable copy is automatically created using
`make_serveable_copy()`.
- Change: Dry-run errors do not kill the server anymore. Rather, the user can
see the error when accessing the web app, and work on the fix while using the
hot-reloading mechanism.
- Performance: The temporary module where the user script is evaluated is now
session-persistent rather then recreated on every rerun.
- Deprecated: `@once` macro is deprecated, as it turns out it is not needed now
that the app module is session-persistent.
