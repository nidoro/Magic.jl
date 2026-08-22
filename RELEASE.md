### v0.7.2 (2026-08-22)

- Bug-fix: due to the net-layer new signal handlers and julia's own gc changes,
net-layer's thread was causing the process to crash on julia 1.12.
