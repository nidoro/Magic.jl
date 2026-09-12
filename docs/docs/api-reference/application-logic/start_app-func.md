---
sidebar_position: 1
---

# start_app

Start the application server.

Once called, this function blocks the current process and keeps the server running until it is stopped with `Ctrl+C`.

### Function Signature

```julia
function start_app(
    script_or_func      ::String="app.jl";
    host_name           ::String="localhost",
    port                ::Int=3443,
    upload_max_size     ::Int=25*MiB,
    upload_max_files    ::Int=10,
    init_and_quit       ::Bool=false,
    verbose             ::Bool=false,
)::Nothing
```

| Argument           | Description                                                                                                                    |
|:------------------ |:------------------------------------------------------------------------------------------------------------------------------ |
| `script_or_func`   | A `String` specifying the path to the entry point script or `Function` specifying the entry point function. Default: "app.jl". |
| `host_name`        | A `String` specifying the hostname or IP address the server should bind to. Default is `"localhost"`.                          |
| `port`             | An `Int` specifying the port number on which the server will listen. Default is `3443`.                                        |
| `upload_max_size`  | An `Int` specifying the maximum file size acceptable by `file_uploader` widgets. Default is 25 MiB.                            |
| `upload_max_files` | An `Int` specifying the maximum number of file acceptable by `file_uploader` widgets. Default is 10.                           |
| `init_and_quit`    | A `Bool`. If `true`, Magic will initialize the server and immediately return. Useful for automating dry-run tests.             |
| `verbose`          | A `Bool`. If `true`, Magic will log more information.                                                                          |

### Return Value

Returns `nothing`.

### Example

Call this function from the REPL to start the web app:

```julia
> using Magic
> start_app("my-app.jl")
```
