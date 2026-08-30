"""
# Magic

A simple framework to create Julia web apps.

## 🎓 Documentation

- [Getting Started](https://magic.coisasdodavi.net/docs/build/docs/getting-started/install)
- [Demo Web Apps](https://magic.coisasdodavi.net/)
- [API Reference](https://magic.coisasdodavi.net/docs/build/docs/category/api-reference)

## —͟͟͞͞★ Quick start

### 1. Implement `app.jl`:

```julia
# app.jl
using Magic
if button("Click me")
    text("Button Clicked!")
end
```

### 2. Start the app

From REPL (recommended for faster app restart during development):

```julia
> using Magic
> start_app()
```

Or from the terminal (requires Julia 1.12):

```bash
\$ julia -m Magic
```

### 3. Open the app in your browser

The default address is http://localhost:3443
"""
module Magic

using ArgParse
using Libdl
using Parameters
using Sockets
using Logging
using JSON
using SHA
using Tables
using DataFrames
using Random
using Artifacts
using TOML

# Layout Elements
#-------------------
export set_page_layout, main_area, left_sidebar, right_sidebar, row, column,
columns, container, @push, @pop, push_container, pop_container

# Interface Elements
#--------------------
export html, text, h1, h2, h3, h4, h5, h6, icon, link, space, metric, button,
download_button, image, dataframe, selectbox, radio, checkbox, checkboxes,
text_input, number_input, slider, file_uploader, code, color_picker, get_value,
set_value, get_changes

# Application Logic
#--------------------
export start_app, @app_startup, @page_startup, @session_startup, @once,
set_app_data, get_app_data, set_page_data, get_page_data, set_session_data,
get_session_data, get_default_value, set_default_value,
is_app_first_pass, is_page_first_pass, is_session_first_pass,
gen_serveable_path, make_serveable_copy, move_to_serveable_dir,
fragment, @fragment, get_url_path, is_on_page, get_current_page, add_page,
add_css_rule, add_font, begin_page_config, end_page_config, set_title,
set_description, UploadedFile, get_dot_magic_dir, get_dot_magic_path,
inject_html, get_url_search, get_query_params, get_server_origin, stop_app,
make_uploaded_file

# Includes
#------------
include("types.jl")
include("utils.jl")
include("net_layer.jl")
include("layout.jl")
include("elements.jl")
include("logic.jl")

# Entry points
#---------------
function __init__()
    # Check if the host system is supported.
    if !((Sys.islinux() && Sys.ARCH === :x86_64) || (Sys.iswindows() && Sys.ARCH === :x86_64))
        printstyled("Error: ", color=:red, bold=true)
        println("Currently, Magic.jl is only supported on Windows and Linux x86_64.")
        println("       Your platform: $(Sys.KERNEL) $(Sys.ARCH).")
    end
end

function main(_args::Vector{String} #= not used =#)
    cli = ArgParseSettings()

    @add_arg_table! cli begin
        "script"
            help = "Entry point script"
            arg_type = String
            default = "app.jl"

        "--hostname", "-H"
            help = "Host name to bind to"
            arg_type = String
            default = "localhost"

        "--port", "-p"
            help = "Port number"
            arg_type = Int
            default = 3443

        "--upload-max-size", "-U"
            help = "Maximum size of files provided via file_uploader"
            arg_type = Int
            default = 25*MiB

        "--upload-max-files", "-F"
            help = "Maximum number of files provided via file_uploader"
            arg_type = Int
            default = 10

        "--dot-magic-dir", "-m"
            help = "Path to '.Magic' dir. If none is provided, it is assumed to be the same directory of 'script'"
            arg_type = String
            default = nothing

        "--init-and-quit", "-q"
            help = "Initialize the server and quit immediately after"
            action = :store_true

        "--docs-path", "-d"
            help = "Path to built Magic.jl documentation to be served"
            arg_type = String
            default = nothing

        "--dev", "-D"
            help = "Enable development mode"
            action = :store_true
    end

    parsed = parse_args(cli)

    if parsed["script"] != nothing
        start_app(
            parsed["script"];
            host_name=parsed["hostname"],
            port=parsed["port"],
            upload_max_size=parsed["upload-max-size"],
            upload_max_files=parsed["upload-max-files"],
            dot_magic_dir=parsed["dot-magic-dir"],
            init_and_quit=parsed["init-and-quit"],
            docs_path=parsed["docs-path"],
            dev_mode=parsed["dev"]
        )
    end
end

# For compatibility with older julia versions that didn't have @main
#-------------------------------------------------
if !@isdefined(var"@main")
    macro main(args...)
        if !isempty(args)
            error("USAGE: `@main` is expected to be used as `(@main)` without macro arguments.")
        end
        Core.eval(__module__, quote
            # Force the binding to resolve to this module
            global main
            global var"#__main_is_entrypoint__#"::Bool = true
        end)
        esc(:main)
    end
end

@main

end # module
