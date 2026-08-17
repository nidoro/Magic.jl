### v0.7.0 (2026-08-17)

- New: Docstrings for every public function so that users can get help from a
Julia's REPL session.
- New: `get_dot_magic_dir()` and `get_dot_magic_path()`.
- Change: `.Magic` default location changed to be the process working directory.
More about `.Magic` in the "Basic Concepts" section of the documentation.
- Internal: Tests implemented for `start_app()` input arguments.
- Internal: Code refactoring. Moved code from `Magic.jl` to the newly created
source files `layout.jl`, `elements.jl` and `logic.jl`.
