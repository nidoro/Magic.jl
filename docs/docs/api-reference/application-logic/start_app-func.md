---
sidebar_position: 1
---

# start_app

Start the application server.

### Function Signature

```julia
function start_app(
    script_or_func              ::Union{String, Function}   ="app.jl";
    host_name                   ::String                    ="localhost",
    port                        ::Int                       =3443,
    upload_max_size             ::Int                       =25*MiB,
    upload_max_files            ::Int                       =10,
    dot_magic_dir               ::Union{String, Nothing}    =nothing,
    open_browser                ::Bool                      =true
)::Nothing
```

| Argument           | Description                                                                                                                                                                                       |
|:------------------ |:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `script_or_func`   | A `String` specifying the path to the entry point script or `Function` specifying the entry point function. Default: "app.jl".                                                                    |
| `host_name`        | A `String` specifying the hostname or IP address the server should bind to. Default is `"localhost"`.                                                                                             |
| `port`             | An `Int` specifying the port number on which the server will listen. Default is `3443`.                                                                                                           |
| `upload_max_size`  | An `Int` specifying the maximum file size acceptable by `file_uploader` widgets. Default is 25 MiB.                                                                                               |
| `upload_max_files` | An `Int` specifying the maximum number of file acceptable by `file_uploader` widgets. Default is 10.                                                                                              |
| `dot_magic_dir`    | A `String` specifying the [`.Magic` directory](/docs/build/docs/getting-started/basic-concepts#the-magic-directory) location. If `nothing` (default), the current working directory will be used. |
| `open_browser`     | A `Bool` indicating whether the default system browser should be open in the web app or not.                                                                                                      |
| *                  | Other arguments have been ommited here because they are for developers only.                                                                                                                      |

### Return Value

Returns `nothing`. Once called, this function blocks the current process and keeps the server running until it is stopped with `Ctrl+C`.

### Example

From the REPL:

```julia
> using Magic
> start_app("my-app.jl")
```
