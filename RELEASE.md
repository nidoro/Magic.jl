### v0.-.- (---)

- New: New function `inject_html` that allows users (that is, developers using
Magic.jl) to inject custom HTML into pages served to their clients.
- New: `start_app` now can accept either a path to a script or a `Function` as
the app entry point.
- New: new boolean argument `init_and_quit` for `start_app`. If true,
`start_app` will only initialize the server and immediately return. Useful for
automated tests.
- New: port 0 can now be passed to start_app to let the OS pick an available
port for the server.
- Internal: examples dry run test.
- Internal: 01-counter E2E test.
- Internal: Stacktrace print on fatal error on linux.
- Internal: New crash recovery mechanism on dev mode on linux.
