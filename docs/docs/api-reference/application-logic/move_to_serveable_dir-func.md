---
sidebar_position: 53
---

# move_to_serveable_dir

Moves a file to somewhere inside `.Magic/served-files/`. This is a
convenience function that calls `gen_serveable_path()` and `mv()` to move the
file to the app's serveable directory. If you want to create a serveable copy
of the file instead of moving the file itself, call
[`make_serveable_copy()`](/docs/build/docs/api-reference/application-logic/make_serveable_copy-func)
instead.

See [`gen_serveable_path()`](/docs/build/docs/api-reference/application-logic/gen_serveable_path-func)
to learn more.

### Function Signature

```julia
function move_to_serveable_dir(file_path::String; lifetime::String="session")::String
```

 Argument  | Description
---------- |-------------
 `file_path` | A `String` with the path of the file that should be moved.
 `lifetime` | A `String` indicating the lifetime of the generated copy. Possible values: `"session"` (default) or `"app"`. If `"session"` is provided, the file will become unavailable after the session is ended. If `"app"` is provided, the file copy will become unavailable (deleted) after the app is stopped.

### Return Value

A `String` with the new path to the file provided.
