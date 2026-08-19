### v0.-.- (---)

- New: new boolean argument `init_and_quit` for `start_app`. If true,
`start_app` will only initialize the server and immediately return. Useful for
automated tests.
- Bug-fix: port 0 can now be passed to start_app to let the OS pick an available
port for the server.
- Internal: examples dry run test.
