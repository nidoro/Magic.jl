# make_serveable_copy

Saves a serveable copy of a file inside `.Magic/served-files/`. This is a convenience function that calls [`gen_serveable_path()`](/docs/version/latest/api-reference/application-logic/gen_serveable_path) and `cp()` to create a serveable copy of a file. If you want to move the file to make it serveable instead of creating a serveable copy, use [`move_to_serveable_dir()`](/docs/version/latest/api-reference/application-logic/move_to_serveable_dir) instead.

See [`gen_serveable_path()`](/docs/version/latest/api-reference/application-logic/gen_serveable_path) to learn more.

### Function Signature

```julia
function make_serveable_copy(file_path::String; lifetime::String="session")::String
```

| Argument    | Description                                                                                                                                                                                                                                                                                        |
|:----------- |:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `file_path` | A `String` with the path of the file that should be copied.                                                                                                                                                                                                                                        |
| `lifetime`  | A `String` indicating the lifetime of the generated copy. Possible values: `"session"` (default) or `"app"`. If `"session"` is provided, the file copy will become unavailable after the session is ended. If `"app"` is provided, the file copy will become unavailable after the app is stopped. |

### Return Value

A `String` with the path to the file copy.
