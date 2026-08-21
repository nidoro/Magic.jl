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
inject_html, get_url_search, get_query_params, get_server_origin, stop_app

# Includes
#------------
include("types.jl")
include("layout.jl")
include("elements.jl")
include("logic.jl")

function buffer_to_string(buffer::NTuple{N, UInt8}) where N
    # Find the null terminator
    null_pos = findfirst(==(0x00), buffer)
    if null_pos === nothing
        # No null terminator, use entire buffer
        return String(collect(buffer))
    else
        # Convert only up to null terminator
        return String(collect(buffer[1:null_pos-1]))
    end
end

function string_to_buffer(::Val{N}, s::AbstractString)::NTuple{N, UInt8} where N
    bytes = codeunits(s)
    maxlen = N - 1
    len = min(length(bytes), maxlen)

    return ntuple(i ->
        i <= len ? bytes[i] :
        i == len + 1 ? 0x00 :
        0x00,
        N
    )
end

function get_rerun_error(e::Exception)::RerunError
    bt = catch_backtrace()
    frames = filtered_stacktrace(bt)
    message = remove_lines_starting_with(sprint(showerror, e), "in expression starting")
    strace = sprint(Base.show_backtrace, frames)
    return RerunError(message, strace)
end

function print_rerun_error(err::RerunError)::Nothing
    println(stderr, err.message)
    println(stderr, err.stacktrace)
    return nothing
end

function display_rerun_error(err::RerunError)::Nothing
    column(gap=".3em", padding="1em", margin="0 0 2rem 0", fill_width=true, max_width="100%", css=Dict("font-family" => "monospace", "white-space" => "pre", "background" => "#fdeded", "color" => "#89454a", "overflow-x" => "auto")) do
        html("span", err.message)
        html("span", err.stacktrace)
    end
    return nothing
end

function get_dyn_lib_path()::String
    if g.dev_mode
        if Sys.islinux()
            return joinpath(@__DIR__, "../build/linux-x86_64/artifacts-linux-x86_64/libmagic.so")
        elseif Sys.iswindows()
            return joinpath(@__DIR__, "../build/win64/artifacts-win64/libmagic.dll")
        else
            @error "Unsupported OS: $(Sys.KERNEL) $(Sys.ARCH)"
        end
    else
        @static if isfile(joinpath(@__DIR__, "../Artifacts.toml"))
            if Sys.islinux()
                return joinpath(artifact"artifacts", "libmagic.so")
            elseif Sys.iswindows()
                return joinpath(artifact"artifacts", "libmagic.dll")
            else
                @error "Unsupported OS: $(Sys.KERNEL) $(Sys.ARCH)"
            end
        end
    end
    return ""
end

function handle_new_client(client_id::Cint, session_id::String)::Nothing
    session = Session()
    session.client_id = client_id
    session.session_id = session_id
    session.first_pass = true

    root_container_props = Dict(
        "type" => "container",
        "is_fragment_container" => true,
        "fragment_id" => "",
        "children" => Vector{Dict{String,Any}}(),
        "id" => "0",
        "css" => Dict(
            "display" => "flex",
            "flex-direction" => "column",
            "align-items" => "flex-start",
            "justify-content" => "flex-start",
            "width" => "100%",
            "height" => "100%",
            "overflow" => "auto",
        ),
        "attributes" => Dict()
    )

    root_frag = Fragment()
    root_frag.id = ""
    root_frag.func = run_user_script
    root_frag.container_props = root_container_props
    session.fragments[""] = root_frag

    g.sessions[client_id] = session

    Core.eval(session.app_mod, quote
        using Base
        using Core
        const include = path -> Base.include(MagicApp, path)
    end)

    mkpath("$(g.dot_magic_dir)/.Magic/served-files/generated/$(session_id)")
    mkpath("$(g.dot_magic_dir)/.Magic/uploaded-files/$(session_id)")

    return nothing
end

function try_rm(path::String; kwargs...)::Bool
    try
        rm(path; kwargs...)
        return true
    catch e
        return false
    end
end

function handle_client_left(client_id::Cint)::Nothing
    session = g.sessions[client_id]
    session.client_left = true
    try_rm("$(g.dot_magic_dir)/.Magic/served-files/generated/$(session.session_id)", recursive=true, force=true)
    try_rm("$(g.dot_magic_dir)/.Magic/uploaded-files/$(session.session_id)", recursive=true, force=true)
    delete!(g.sessions, client_id)
    return nothing
end

function run_user_script()::Nothing
    task = task_local_storage("app_task")
    if g.script_or_func isa String
        Base.include(task.session.app_mod, g.script_or_func)
    else
        Base.invokelatest(g.script_or_func)
    end
    return nothing
end

function filtered_stacktrace(bt; cutoff_file = nothing)
    frames = stacktrace(bt)

    frames = filter(f -> f.func != :include, frames)

    if cutoff_file !== nothing
        i = findfirst(f -> occursin(cutoff_file, String(f.file)), frames)
        if i !== nothing
            frames = frames[1:i-1]
        end
    end

    return frames
end

function remove_lines_starting_with(err::String, prefix::String)::String
    lines = split(err, '\n')
    keep = filter(l -> !startswith(lstrip(l), prefix), lines)
    return join(keep, '\n')
end

function rerun(client_id::Cint, payload::Dict)::Task
    session = g.sessions[client_id]

    if payload["location"] !== nothing
        session.location = payload["location"]
    end

    session.rerun_task = Threads.@spawn try
        task = AppTask()
        task_local_storage("app_task", task)
        task.task = current_task()
        task.client_id = client_id
        task.session = session
        task.payload = payload
        task.current_page = g.base_page_config

        # Identify and initialize fragment
        #------------------------------------
        fragment_id = ""

        for front_event in payload["events"]
            widget = session.widgets[front_event["widget_id"]]
            fragment_id = widget.fragment_id
        end

        frag = session.fragments[fragment_id]
        frag.container_props["children"] = Vector{Dict{String, Any}}()

        task.state = Dict("root" => frag.container_props)
        root_interface = create_interface(task.state["root"])
        push_container(root_interface)
        push_fragment(frag)

        task.layout = Containers()
        task.layout.main_area = root_interface

        if g.dry_run_error !== nothing
            display_rerun_error(g.dry_run_error)
        else
            # Handle events
            #------------------
            for widget in values(session.widgets)
                widget.clicked = false
                if widget.kind == WidgetKind_Button
                    widget.value = false
                end
                if widget.fragment_id == fragment_id
                    widget.alive = false
                end
            end

            # TODO: Although we receive a list of events from the front-end, at the
            # moment we don't expect it to have more than one event.
            for front_event in payload["events"]
                widget = session.widgets[front_event["widget_id"]]
                if front_event["type"] == "click"
                    widget.clicked = true
                    if widget.kind == WidgetKind_Button
                        widget.value = true
                        invokelatest(widget.onclick, widget.args...)
                    end
                elseif front_event["type"] == "change"
                    if widget.kind == WidgetKind_Checkboxes
                        if widget.props["multiple"]
                            widget.value = front_event["new_value"]
                        else
                            widget.value = (length(front_event["new_value"]) > 0)
                        end
                        invokelatest(widget.onchange, widget.args...)
                    elseif widget.kind == WidgetKind_FileUploader
                        new_value = nothing

                        if length(front_event["new_value"]) > 0
                            new_value = Vector{UploadedFile}()

                            for entry in front_event["new_value"]
                                file = UploadedFile()
                                file.id = entry["id"]
                                file.name = entry["name"]
                                file.extension = entry["extension"]
                                file.path = "$(g.dot_magic_dir)/.Magic/uploaded-files/$(task.session.session_id)/$(file.id)$(file.extension)"
                                file.type = entry["type"]
                                file.size = entry["size"]
                                file.last_modified = entry["last_modified"]

                                if widget.props["multiple"]
                                    push!(new_value, file)
                                else
                                    new_value = file
                                    break
                                end
                            end
                        end

                        widget.value = new_value

                        invokelatest(widget.onchange, widget.args...)
                    elseif widget.kind in [WidgetKind_Selectbox, WidgetKind_Radio, WidgetKind_TextInput, WidgetKind_ColorPicker]
                        widget.value = front_event["new_value"]
                        invokelatest(widget.onchange, widget.args...)
                    elseif widget.kind == WidgetKind_NumberInput
                        new_value = front_event["new_value"]
                        if new_value != nothing
                            if widget.props["num_type"] <: Integer
                                new_value = round(widget.props["num_type"], new_value)
                            else
                                new_value = convert(widget.props["num_type"], new_value)
                            end
                        end
                        widget.value = new_value
                        invokelatest(widget.onchange, widget.args...)
                    elseif widget.kind == WidgetKind_Slider
                        new_value = front_event["new_value"]
                        if widget.props["num_type"] <: Integer
                            new_value = round(widget.props["num_type"], new_value)
                        else
                            new_value = convert(widget.props["num_type"], new_value)
                        end
                        widget.value = new_value
                        invokelatest(widget.onchange, widget.args...)
                    elseif widget.kind == WidgetKind_DataFrame
                        for change in front_event["changes"]
                            column_config = widget.props["column_config"][change["column_name"]]
                            new_value = change["new_value"]

                            if column_config["type"] == "Number" && !(new_value in ["", nothing])
                                if column_config["julia_type"] <: Integer
                                    new_value = round(column_config["julia_type"], new_value)
                                end
                            end

                            if (column_config["type"] == "Number" && (new_value == "" || new_value == nothing)) ||
                            (column_config["type"] == "String" && (new_value == nothing))
                                if column_config["empty_value"] == "<nothing>"
                                    new_value = nothing
                                elseif column_config["empty_value"] == "<missing>"
                                    new_value = missing
                                else
                                    new_value = column_config["empty_value"]
                                end
                            end

                            row_changes = get!(widget.changes, change["row_index"], Dict{String, Any}())
                            row_changes[change["column_name"]] = new_value

                            widget.value[change["row_index"], change["column_name"]] = new_value
                        end

                        invokelatest(widget.onchange, widget.args...)
                    end
                end
            end

            # Run user fragment
            #-------------------
            if is_session_first_pass()
                Base.invokelatest(g.callback, CallbackReason_BeforeSessionFirstPass, client_id, session.session_id)
            end

            invokelatest(frag.func)

            if is_session_first_pass()
                Base.invokelatest(g.callback, CallbackReason_AfterSessionFirstPass, client_id, session.session_id)
            end

            # Remove dead widgets
            #-------------------------
            filter!(p -> p.second.alive, session.widgets)

            g.first_pass = false
            session.first_pass = false
            page = get_current_page()
            if page !== missing
                page.first_pass = false
            end
        end

        if payload["request_id"] != 0
            put!(g.internal_events, InternalEvent(InternalEventType_Task, task))
        end

    catch e
        task = task_local_storage("app_task")

        if !task.session.client_left
            session.rerun_error = get_rerun_error(e)
            print_rerun_error(session.rerun_error)
            display_rerun_error(session.rerun_error)

            filter!(p -> p.second.alive, task.session.widgets)
            put!(g.internal_events, InternalEvent(InternalEventType_Task, task))
        else
            @debug "TaskStoped | Client=$(client_id) | Session=$(task.session.session_id)"
        end
    end

    return session.rerun_task
end

function lock_client(client_id::Cint)::Nothing
    ccall((:MG_LockClient, g.MAGIC_SO), Cvoid, (Cint,), client_id)
    return nothing
end

function unlock_client(client_id::Cint)::Nothing
    ccall((:MG_UnlockClient, g.MAGIC_SO), Cvoid, (Cint,), client_id)
    return nothing
end

function pop_net_event()::NetEvent
    return ccall((:MG_PopNetEvent, g.MAGIC_SO), NetEvent, ())
end

function push_app_event(app_event::AppEvent)::Nothing
    ccall((:MG_PushAppEvent, g.MAGIC_SO), Cvoid, (AppEvent,), app_event)
    return nothing
end

function push_uri_mapping(uri::String, resource_path::String)::Nothing
    ccall((:MG_PushURIMapping, g.MAGIC_SO), Cvoid, (Cstring, Cint, Cstring, Cint), uri, Cint(sizeof(uri)), resource_path, Cint(sizeof(resource_path)))
    return nothing
end

function clear_uri_mapping()::Nothing
    ccall((:MG_ClearURIMapping, g.MAGIC_SO), Cvoid, ())
    return nothing
end

# NOTE: functions to open browser. Copied from LiveServer.jl
#-------------------------------------------------------------
function detectwsl()
    Sys.islinux() &&
    isfile("/proc/sys/kernel/osrelease") &&
    occursin(r"Microsoft|WSL"i, read("/proc/sys/kernel/osrelease", String))
end

function open_in_default_browser(url::AbstractString)::Bool
    try
        if Sys.isapple()
            Base.run(`open $url`)
            true
        elseif Sys.iswindows() || detectwsl()
            Base.run(`cmd.exe /s /c start "" /b $url`)
            true
        elseif Sys.islinux()
            Base.run(`xdg-open $url`)
            true
        else
            false
        end
    catch
        false
    end
end

function is_rerun_request_valid(session::Session, request::RerunRequest)::Bool
    payload = request.payload
    for front_event in payload["events"]
        if !haskey(session.widgets, front_event["widget_id"])
            return false
        end
    end
    return true
end

function return_invalid_request(client_id::Cint, request_id::Int)::Nothing
    payload = Dict(
        "type" => "response_rerun",
        "dev_mode" => g.dev_mode,
        "request_id" => request_id,
        "error" => Dict(
            "type" => "InvalidState",
        )
    )
    payload_string = JSON.json(payload)
    app_event = create_app_event(AppEventType_NewPayload, client_id, payload_string)
    push_app_event(app_event)
    write(g.ipc_connection, " ")
    g.sessions[client_id].waiting_invalid_state_ack = true
    return nothing
end

function execute_dry_runs()::Bool
    g.dry_run_error = nothing

    dry_run_payload = Dict(
        "type" => "request_rerun",
        "request_id" => 0,
        "events" => [],
        "location" => Dict(
            "href" => "https://$(g.host_name):$(g.port)",
            "pathname" => "",
            "host" => "$(g.host_name):$(g.port)",
            "hostname" => g.host_name,
            "search" => ""
        )
    )

    add_page("/", title="Magic App", description="Magic App")

    handle_new_client(Cint(0), "0")
    @info "Dry Run: First pass over '$(g.script_name)'.\n$(AC_Green("@app_startup")) code blocks will run now."
    wait(rerun(Cint(0), dry_run_payload))
    rerun_error = g.sessions[Cint(0)].rerun_error
    handle_client_left(Cint(0))

    if rerun_error !== nothing
        @error "Dry run of app '$(g.script_name)' failed."
    else
        if length(g.pages) > 1
            popfirst!(g.pages)
        end

        for page in g.pages
            handle_new_client(Cint(0), "0")
            @info "Dry Run: First pass over '$(g.script_name)' as if loading page '$(page.uris[1])'.\n$(AC_Green("@page_startup")) code blocks will run now."

            dry_run_payload["location"]["href"] = "https://$(g.host_name):$(g.port)" * page.uris[1]
            dry_run_payload["location"]["pathname"] = page.uris[1]

            wait(rerun(Cint(0), dry_run_payload))
            rerun_error = g.sessions[Cint(0)].rerun_error
            handle_client_left(Cint(0))

            if rerun_error !== nothing
                @error "Dry run of page '$(page.uris[1])' failed."
                break
            end
        end
    end

    if rerun_error !== nothing
        g.dry_run_error = rerun_error
        g.first_pass = true
        g.pages = Vector{PageConfig}()
        return false
    else
        g.dry_run_error = nothing
        return true
    end
end

function create_static_pages()::Nothing
    create_page_html(g.base_page_config, "$(g.dot_magic_dir)/.Magic/served-files/generated/app/pages/base.html")

    for page in g.pages
        create_page_html(page, "$(g.dot_magic_dir)/.Magic/served-files/generated/app/pages/$(page.id).html")
    end

    clear_uri_mapping()

    if length(g.pages) > 0
        # User explicitly configured app pages
        for page in g.pages
            for uri in page.uris
                push_uri_mapping(uri, replace(page.file_path, "$(g.dot_magic_dir)/.Magic/served-files" => ""))
            end
        end
    else
        push_uri_mapping("/", replace(g.base_page_config.file_path, "$(g.dot_magic_dir)/.Magic/served-files" => ""))
    end

    # Create 404.html
    #-------------------
    create_404_html("$(g.dot_magic_dir)/.Magic/served-files/generated/app/pages/404.html")

    return nothing
end

function is_valid_hostname(hostname::String)
    # Overall length limit
    length(hostname) > 253 && return false
    isempty(hostname) && return false

    # Split into labels and validate each
    labels = split(hostname, '.')
    for label in labels
        isempty(label) && return false
        length(label) > 63 && return false
        # Must start/end with alphanumeric, may contain hyphens in the middle
        occursin(r"^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?$", label) || return false
    end

    return true
end

"""
# start_app

Start the application server.

Call this function from the REPL to start the web app. Example:

```julia
> using Magic
> start_app("my-app.jl")
```

### Function Signature

```julia
function start_app(
    script_or_func      ::String="app.jl";
    host_name           ::String="localhost",
    port                ::Int=3443,
    upload_max_size     ::Int=25*MiB,
    upload_max_files    ::Int=10,
    docs_path           ::Union{String, Nothing}=nothing,
    init_and_quit       ::Bool=false,
    verbose             ::Bool=false,
    dev_mode            ::Bool=false
)::Nothing
```

 Argument        | Description
---------------- |-------------
 `script_or_func` | A `String` specifying the path to the entry point script or `Function` specifying the entry point function. Default: "app.jl".
 `host_name`   | A `String` specifying the hostname or IP address the server should bind to. Default is `"localhost"`.
 `port`        | An `Int` specifying the port number on which the server will listen. Default is `3443`.
 `upload_max_size` | An `Int` specifying the maximum file size acceptable by `file_uploader` widgets. Default is 25 MiB.
 `upload_max_files` | An `Int` specifying the maximum number of file acceptable by `file_uploader` widgets. Default is 10.
 `docs_path`   | A `String` specifying a path to Magic's docs where it has been built, or `nothing` (default). If a `String` is passed, the docs will be served under `/docs`.
 `init_and_quit` | A `Bool`. If `true`, Magic will initialize the server and immediately return. Useful for automating dry-run tests.
 `verbose`    | A `Bool`. If `true`, Magic will log more information.
 `dev_mode`    | A `Bool`. If `true`, development mode is enabled. This activates features such as more verbose error reporting and loading of locally built `libmagic.so`.

### Return Value

Returns `nothing`.

Once called, this function blocks the current process and keeps the server
running until it is stopped with `Ctrl+C`.
"""
function start_app(
    script_or_func::Union{String, Function}="app.jl";
    host_name::String="localhost",
    port::Int=3443,
    upload_max_size::Int=25*MiB,
    upload_max_files::Int=10,
    dot_magic_dir::Union{String, Nothing}=nothing,
    docs_path::Union{String, Nothing}=nothing,
    init_and_quit::Bool=false,
    callback::Union{Function, Nothing}=nothing,
    verbose::Bool=false,
    dev_mode::Bool=false,
)::Nothing

    # Input validation
    #----------------------
    if !is_valid_hostname(host_name)
        throw(InvalidHostname(host_name))
    end

    if port < 0 || port > 65535
        throw(InvalidPort(port))
    end

    if upload_max_size < 0
        throw(InvalidUploadMaxSize(upload_max_size))
    end

    if upload_max_files < 0
        throw(InvalidUploadMaxFiles(upload_max_files))
    end

    global g = Global()
    g.dev_mode = dev_mode
    g.verbose = verbose
    g.callback = callback !== nothing ? callback : (reason, args...) -> ()

    if g.dev_mode
        @warn "Starting Magic.jl on dev mode"
    end

    g.MAGIC_SO = get_dyn_lib_path()
    g.LIBMAGIC = Libdl.dlopen(g.MAGIC_SO, Libdl.RTLD_NOW)
    g.sessions = Dict{Ptr{Cvoid}, Session}()
    g.first_pass = true
    g.initialized = true
    if script_or_func isa String
        g.script_or_func = joinpath(pwd(), expanduser(script_or_func))
        g.script_name = basename(script_or_func)
    else
        g.script_or_func = script_or_func
        g.script_name = String(nameof(script_or_func))
    end
    g.host_name = host_name
    g.port = port
    g.upload_max_size = upload_max_size
    g.upload_max_files = upload_max_files

    if script_or_func isa String && !isfile(g.script_or_func)
        throw(InvalidFile(g.script_or_func))
    end

    if dot_magic_dir === nothing
        g.dot_magic_dir = pwd()
    else
        g.dot_magic_dir = joinpath(pwd(), expanduser(dot_magic_dir))
    end

    if !isdir(g.dot_magic_dir)
        throw(InvalidDirectory(g.dot_magic_dir))
    end

    g.dot_magic_dir = realpath(g.dot_magic_dir)

    if docs_path === nothing
        docs_path = ""
    else
        docs_path = joinpath(pwd(), docs_path)
        if !isdir(docs_path)
            throw(InvalidDirectory(docs_path))
            return nothing
        end
    end

    @info """
        $(AC_Bold("Configuration"))
        App script/function  : $(g.script_or_func)
        Hostname             : $(g.host_name)
        Port                 : $(g.port) $(g.port == 0 ? "(let the OS pick a port)" : "")
        Upload max size      : $(Float64(g.upload_max_size)/MiB) MiB
        Upload max files     : $(g.upload_max_files)
        Process working dir  : $(pwd())
        Directory of '.Magic': $(g.dot_magic_dir)
        """

    # Setup net layer connection
    #--------------------------------
    ipc_server = listen(IPv4(127,0,0,1), 0)
    ipc_port = getsockname(ipc_server)[2]

    init_net_layer(
        g.host_name,
        g.port,
        docs_path,
        Int(ipc_port),
        g.dot_magic_dir,
        joinpath(@__DIR__, ".."),
        g.upload_max_size,
        g.verbose,
        g.dev_mode
    )
    g.ipc_connection = accept(ipc_server)
    push_uri_mapping("/", "/generated/app/pages/first.html")

    # Generate directories and files
    #-----------------------------------
    try_rm("$(g.dot_magic_dir)/.Magic/served-files/generated", recursive=true, force=true)
    try_rm("$(g.dot_magic_dir)/.Magic/uploaded-files", recursive=true, force=true)
    mkpath("$(g.dot_magic_dir)/.Magic/served-files/generated/app/pages")
    cp(joinpath(@__DIR__, "../served-files/MagicPageTemplate.html"), "$(g.dot_magic_dir)/.Magic/served-files/generated/app/pages/first.html", force=true)

    if !isfile("$(g.dot_magic_dir)/.Magic/.gitignore")
        write("$(g.dot_magic_dir)/.Magic/.gitignore", DOT_MAGIC_GITIGNORE)
    end

    g.base_page_config.title = "Magic App"
    g.base_page_config.description = "Web app made with Magic.jl"

    if execute_dry_runs()
        create_static_pages()
    end

    # Net-layer IPC listener loop.
    # When a net-layer event happens, it forwards the event to the App-layer
    # loop by pushing the event to the `internal_events` channel.
    #---------------------------------------------------------------------------
    Threads.@spawn begin
        stop_loop = false

        while isopen(g.ipc_connection) && !stop_loop
            read(g.ipc_connection, UInt8)

            ev = pop_net_event()
            while ev.ev_type != NetEventType_None
                put!(g.internal_events, InternalEvent(InternalEventType_Network, ev))
                ev = pop_net_event()

                if ev.ev_type == NetEventType_ServerLoopInterrupted
                    stop_loop = true
                end
            end
        end
    end

    # App-layer loop.
    # It handles events that are pushed to the `internal_events` channel. These
    # can be either net-layer events (e.g. client connection) or app-layer
    # events (e.g. rerun finished).
    #---------------------------------------------------------------------------
    try
        while isopen(g.ipc_connection)
            ev = take!(g.internal_events)

            if ev.ev_type == InternalEventType_Network
                if ev.data.ev_type == NetEventType_ServerReady
                    g.port = get_server_port()

                    println()
                    @info "NetLayerStarted\nNow serving at $(get_server_origin())"

                    Base.invokelatest(g.callback, CallbackReason_ServerReady)

                    if init_and_quit
                        stop_app()
                    end
                elseif ev.data.ev_type == NetEventType_NewClient
                    session_id = buffer_to_string(ev.data.session_id)
                    @debug "NetEventType_NewClient | ClientId=$(ev.data.client_id) | SessionId=$(session_id)"
                    handle_new_client(ev.data.client_id, session_id)

                    Base.invokelatest(g.callback, CallbackReason_NewClient, ev.data.client_id)
                elseif ev.data.ev_type == NetEventType_ClientLeft
                    @debug "NetEventType_ClientLeft | ClientId=$(ev.data.client_id)"
                    Base.invokelatest(g.callback, CallbackReason_ClientLeft, ev.data.client_id)
                    handle_client_left(ev.data.client_id)
                elseif ev.data.ev_type == NetEventType_NewPayload
                    @debug "NetEventType_NewPayload | ClientId=$(ev.data.client_id)"
                    payload_string = unsafe_string(ev.data.payload, ev.data.payload_size)

                    # NOTE: Now that we've copied the payload, it is safe to destroy the event.
                    destroy_net_event(ev.data)

                    payload = Dict(JSON.parse(payload_string))
                    #@show payload

                    session = g.sessions[ev.data.client_id]

                    if payload["type"] == "request_rerun"
                        if !session.waiting_invalid_state_ack
                            rerun_request = RerunRequest(payload)

                            if g.dry_run_error !== nothing
                                if execute_dry_runs()
                                    create_static_pages()
                                    session.refresh = true
                                end
                            end

                            if session.refresh
                                payload_string = JSON.json(Dict("type" => "please_refresh"))
                                app_event = create_app_event(AppEventType_NewPayload, session.client_id, payload_string)
                                push_app_event(app_event)
                                write(g.ipc_connection, " ")
                            elseif session.rerun_task === nothing
                                if is_rerun_request_valid(session, rerun_request)
                                    rerun(ev.data.client_id, payload)
                                else
                                    return_invalid_request(ev.data.client_id, payload["request_id"])
                                end
                            else
                                @debug "Rerun already happening. Queueing rerun request. Current queue size: $(length(session.rerun_queue))"
                                push!(session.rerun_queue, RerunRequest(payload))
                            end
                        else
                            # Nothing to do. Just wait for ack.
                        end
                    elseif payload["type"] == "ack_invalid_state"
                        session.waiting_invalid_state_ack = false
                    elseif payload["type"] == "hello"
                        @debug "HelloFromClient | ClientId=$(session.client_id) | SessionId=$(session.session_id)"
                        payload = Dict(
                            "type" => "response_hello",
                            "session_id" => session.session_id,
                            "dev_mode" => g.dev_mode,
                            "upload_max_size" => g.upload_max_size,
                            "upload_max_files" => g.upload_max_files,
                        )
                        payload_string = JSON.json(payload)
                        app_event = create_app_event(AppEventType_NewPayload, session.client_id, payload_string)
                        push_app_event(app_event)
                        write(g.ipc_connection, " ")
                    elseif payload["type"] == "error"
                        @debug "ClientSideError | ClientId=$(session.client_id) | SessionId=$(session.session_id)"
                        Base.invokelatest(g.callback, CallbackReason_ClientSideError, ev.data.client_id, session.session_id, payload)
                    elseif payload["type"] == "disconnect"
                        @debug "DisconnectRequested | ClientId=$(session.client_id) | SessionId=$(session.session_id) | Reason=$(payload["reason"])"
                        Base.invokelatest(g.callback, CallbackReason_DisconnectRequested, ev.data.client_id, session.session_id, payload)

                        app_event = create_app_event(AppEventType_DisconnectRequested, session.client_id, nothing)
                        push_app_event(app_event)
                        write(g.ipc_connection, " ")
                    else
                        @error "Unknown payload type '$(payload["type"])'"
                    end

                    Base.invokelatest(g.callback, CallbackReason_NewPayload, ev.data.client_id, session.session_id, payload)
                elseif ev.data.ev_type == NetEventType_ServerLoopInterrupted
                    @info "NetEventType_ServerLoopInterrupted"
                    close(g.ipc_connection)
                end
            elseif ev.ev_type == InternalEventType_Task
                if ev.data.client_id != Cint(0)
                    session = ev.data.session

                    if !session.client_left
                        @debug "TaskFinished | ClientId=$(ev.data.client_id)"

                        payload = Dict(
                            "type" => "response_rerun",
                            "dev_mode" => g.dev_mode,
                            "request_id" => ev.data.payload["request_id"],
                            "root" => ev.data.state["root"],
                            "error" => nothing
                        )

                        payload_string = JSON.json(payload)
                        app_event = create_app_event(AppEventType_NewPayload, session.client_id, payload_string)
                        push_app_event(app_event)

                        session.rerun_task = nothing

                        # Start next rerun request on queue, if any
                        #-------------------------------------------
                        if length(session.rerun_queue) > 0
                            rerun_request = popfirst!(session.rerun_queue)
                            if is_rerun_request_valid(session, rerun_request)
                                @debug "Running next rerun request in queue"
                                rerun(session.client_id, rerun_request.payload)
                            else
                                @debug "Next rerun request in queue is invalid"
                                return_invalid_request(session.client_id, ev.data.payload["request_id"])
                            end
                        end

                        # Notify if download is ready
                        #-------------------------------
                        for front_event in ev.data.payload["events"]
                            if haskey(session.widgets, front_event["widget_id"])
                                widget = session.widgets[front_event["widget_id"]]
                                if widget.kind == WidgetKind_Button && typeof(widget.props["download_path"]) <: AbstractString
                                    if widget.clicked
                                        app_event = create_app_event(AppEventType_DownloadReady, session.client_id, nothing)
                                        app_event.download_path = string_to_buffer(Val(MG_PATH_MAX+1), widget.props["download_path"])
                                        push_app_event(app_event)
                                    end
                                end
                            end
                        end

                        write(g.ipc_connection, " ")

                        Base.invokelatest(g.callback, CallbackReason_TaskFinished, ev.data.client_id)
                    else
                        @debug "ClientlessTaskFinished | ClientId=$(ev.data.client_id)"
                        try_rm("$(g.dot_magic_dir)/.Magic/served-files/generated/$(session.session_id)", recursive=true, force=true)
                    end
                end
            end
        end
    catch e
        if !(e isa InterruptException)
            app_event = create_app_event(AppEventType_FatalError, Cint(0), nothing)
            push_app_event(app_event)
            write(g.ipc_connection, " ")

            rethrow()
        end
    end

    Libdl.dlclose(g.LIBMAGIC)

    @info "ServerLoopStopped"
end

function stop_app()
    app_event = create_app_event(AppEventType_ServerStopRequested, Cint(0), nothing)
    push_app_event(app_event)
    write(g.ipc_connection, " ")
end

function create_app_event(event_type::AppEventType, client_id::Cint, payload::Union{String, Nothing})::AppEvent
    payload_ptr = payload !== nothing ? payload : Ptr{Cchar}(0)
    payload_size = payload !== nothing ? Cint(sizeof(payload)) : Cint(0)
    return ccall((:MG_CreateAppEvent, g.MAGIC_SO), AppEvent, (AppEventType, Cint, Ptr{Cchar}, Cint), event_type, client_id, payload_ptr, payload_size)
end

function destroy_net_event(ev::NetEvent)::Nothing
    ccall((:MG_DestroyNetEvent, g.MAGIC_SO), Cvoid, (NetEvent,), ev)
end

function init_net_layer(
    host_name::String,
    port::Int,
    docs_path::String,
    ipc_port::Int,
    dot_magic_dir::String,
    package_root_dir::String,
    upload_max_size::Int,
    verbose::Bool,
    dev_mode::Bool
)

    ccall(
        (:MG_InitNetLayer, g.MAGIC_SO),
        Cvoid,
        (Cstring, Cint, Cint, Cstring, Cint, Cint, Cstring, Cint, Cstring, Cint, Cint, Cint, Cint),
        host_name, Cint(sizeof(host_name)), port, docs_path, Cint(sizeof(docs_path)), Cint(ipc_port), dot_magic_dir, Cint(sizeof(dot_magic_dir)), package_root_dir, Cint(sizeof(package_root_dir)), Cint(upload_max_size), Cint(verbose), Cint(dev_mode)
    )
end

function server_is_running()::Bool
    return ccall((:MG_ServerIsRunning, g.MAGIC_SO), Cint, ())
end

function do_service_work()::Int
    return ccall((:MG_DoServiceWork, g.MAGIC_SO), Cint, ())
end

function stop_server()
    return ccall((:MG_StopServer, g.MAGIC_SO), Cvoid, ())
end

function get_server_port()::Int
    return ccall((:MG_GetServerPort, g.MAGIC_SO), Cint, ())
end

function is_tls_enabled()::Bool
    return ccall((:MG_IsTLSEnabled, g.MAGIC_SO), Cint, ())
end

function is_https_enabled()::Bool
    return ccall((:MG_IsHTTPSEnabled, g.MAGIC_SO), Cint, ())
end

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
