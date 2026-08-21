### v0.-.- (---)

- New: New function `inject_html` that allows users (that is, developers using
Magic.jl) to inject custom HTML into pages served to their clients.
- New: `start_app` now can accept either a path to a script or a `Function` as
the app entry point.
- New: new boolean argument `init_and_quit` for `start_app`. If true,
`start_app` will only initialize the server and immediately return. Useful for
automated tests of dry-runs.
- New: port 0 can now be passed to `start_app` to let the OS pick an available
port for the server.
- Internal: Introduces the first tests to the package, some unit tests, some
end-to-end tests.
- Internal: New dependencies backward.hpp, elfutils, xz, bzip2 and zstd, used
for stacktrace printing on fatal error on, the net-layer on linux.
- Internal: New crash recovery mechanism on dev mode on linux.
