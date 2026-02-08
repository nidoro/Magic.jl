### v0.6.0 (2026-02-08)

- Breaking-change: Removed argument `inner_func` from `set_page_layout()` and
thus the ability to have a `do-end` block with this function. If you want a
`do-end` block that does the same, implement it with `main_area()` instead,
after calling `set_page_layout()`.
- New: New widget `number_input()`.
- New: Example `probability.jl`.
- Bug-fix: Fixes `file_uploader()` bug where selecting a file, clearing the
selection and selecting the same file didn't work.
https://github.com/nidoro/Magic.jl/issues/8
- Bug-fix: Fixes `file_uploader()` bug where canceling the file dialog when a
file was selected triggered a change callback, when it shouldn't.
- Bug-fix: Dry-run logic was breaking trying to access session 0 after the
`handle_client_left(Cint(0))` has been called.
