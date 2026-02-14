### v0.6.1 (2026-02-14)

- New: Widget `slider()`.
- New: Sliding curves example.
- Bug-fix: on small screens, `row`s had overflow problems similar to what
columns used to have. It seems that the flex model (at least on chrome) works
with a default `min-width` based on "intrinsic width of child elements",
whatever that is. The fix is to enforce a `min-width` of `0` on our layout
elements.
- Bug-fix: various fixes on documentation.
