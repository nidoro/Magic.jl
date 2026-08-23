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
    init_and_quit       ::Bool=false,
    verbose             ::Bool=false,
)::Nothing
```

 Argument        | Description
---------------- |-------------
 `script_or_func` | A `String` specifying the path to the entry point script or `Function` specifying the entry point function. Default: "app.jl".
 `host_name`   | A `String` specifying the hostname or IP address the server should bind to. Default is `"localhost"`.
 `port`        | An `Int` specifying the port number on which the server will listen. Default is `3443`.
 `upload_max_size` | An `Int` specifying the maximum file size acceptable by `file_uploader` widgets. Default is 25 MiB.
 `upload_max_files` | An `Int` specifying the maximum number of file acceptable by `file_uploader` widgets. Default is 10.
 `init_and_quit` | A `Bool`. If `true`, Magic will initialize the server and immediately return. Useful for automating dry-run tests.
 `verbose`    | A `Bool`. If `true`, Magic will log more information.

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
    rethrow_rerun_exceptions::Bool=false,
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
    g.rethrow_rerun_exceptions = rethrow_rerun_exceptions

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

    # First dry-run attempt
    #-----------------------
    execute_dry_runs()

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

    if g.dry_run_error === nothing
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
    return nothing
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
                    elseif widget.kind == WidgetKind_Selectbox
                        if isnothing(front_event["new_value"])
                            widget.value = nothing
                        elseif !widget.props["multiple"]
                            widget.value = get_item_by_its_stringified_version(widget.props["options"], front_event["new_value"])
                        else
                            new_value = []
                            for val in front_event["new_value"]
                                push!(new_value, get_item_by_its_stringified_version(widget.props["options"], val))
                            end
                            widget.value = new_value
                        end
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

        if g.rethrow_rerun_exceptions
            rethrow()
        end
    end

    return session.rerun_task
end

function wait_rerun(task::Task)::Nothing
    try
        wait(task)
    catch e
        if e isa TaskFailedException
            original = e.task.result
            rethrow(original)
        else
            rethrow()
        end
    end
    return nothing
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
    wait_rerun(rerun(Cint(0), dry_run_payload))
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

            wait_rerun(rerun(Cint(0), dry_run_payload))
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

function stop_app()
    app_event = create_app_event(AppEventType_ServerStopRequested, Cint(0), nothing)
    push_app_event(app_event)
    write(g.ipc_connection, " ")
end

"""
# First pass functions

Family of `Bool` returning functions:

- `is_app_first_pass()`: returns `true` it is the first time the app is being
run, and `false` otherwise. See also: `@app_startup`.
- `is_page_first_pass()`: returns `true` it is the first time the current page
is being run, and `false` otherwise. See also: `@page_startup`.
- `is_session_first_pass()`: returns `true` it is the first time the session
is being run, and `false` otherwise. See also: `@session_startup`.
"""
function is_app_first_pass()::Bool
    return g.first_pass
end

"""
# @app_startup

Macro to define a code block that should only be executed at the startup of the
application (app dry-run). Usage:

```julia
@app_startup begin
    # app initialization logic
end
```

Internally, this macro is implemented by checking the result of
[`is_app_first_pass()`](/docs/build/docs/api-reference/application-logic/is_first_pass-func)
and running the `@app_startup` code block only if it returns `true`.

## Usage

You can define multiple `@app_startup` code blocks, but we recommend you to keep
all of your app initialization logic inside a single `@app_startup` block near
the top of your entry-point script (`app.jl` by default).

Although apps are not required to have `@app_startup` code blocks, some
initialization tasks should be only performed inside `@app_startup`
code blocks. See below what you are expected to do inside `@app_startup` code blocks.

### 1. Definition of the app pages

> **🛈 NOTE**: This is only needed if your app has multiple pages.

```julia
@app_startup begin
    add_page("/first-page")
    add_page("/second-page")
    add_page("/third-page")
end
```

### 2. Initialization of app persistent data

App persistent data is an user defined data whose lifetime is the lifetime of
the app, i.e., as long as the app is running the data will persist. App
persistent data can be retrieved at any moment using `get_app_data()` and is
shared accross sessions.

You can store data that you want to be globally available through all of your
app's pages and sessions via the `set_app_data()` function, and retrieve it
using the `get_app_data()` function.
See [App persistent data](/docs/build/docs/api-reference/application-logic/app-persistent-data)
to learn more.

## See also

- [`@page_startup`](/docs/build/docs/api-reference/application-logic/page_startup-macro)
- [`@session_startup`](/docs/build/docs/api-reference/application-logic/session_startup-macro)
"""
macro app_startup(block)
    return :(
        if Magic.is_app_first_pass()
            $(esc(block))
        end
    )
end

# Fragment
#-----------------------
function push_fragment(frag::Fragment)::Nothing
    task = task_local_storage("app_task")
    push!(task.fragment_stack, frag)
    return nothing
end

function pop_fragment()::Fragment
    task = task_local_storage("app_task")
    return pop!(task.fragment_stack)
end

function top_fragment()::Fragment
    task = task_local_storage("app_task")
    return task.fragment_stack[end]
end

"""
# Fragments

A fragment is a function that can be rerun independently of the full app. It
can be created using the the `fragment()` function or the `@fragment` macro.

Use fragments to avoid rerunning the entire app script on every widget
interaction.

### The `fragment()` function

Turns a function into a fragment.

#### Function Signature

```julia
function fragment(func::Function; id::String=String(nameof(func)))
```

 Argument  | Description
---------- |-------------
 `func`   | The `Function` that will be isolated from the rest of the app.
 `id`   | A `String` to uniquely identify the fragment.

### The `@fragment` macro

Turns a code block into a fragment. Usage:

```julia
@fragment begin
    # code block
end
```

Internally, `@fragment` creates a function with the passed code block as its
body, and then calls the function `fragment()` to register the function as
a fragment.

## Example

[Live example here](https://magic.coisasdodavi.net/fragment-example).

```julia
using Magic

@once mutable struct SessionData
    app_reruns::Int
    fragment_reruns::Int
end

@session_startup begin
    session = SessionData(0, 0)
    set_session_data(session)
end

session = get_session_data()
button("Outside Button")
session.app_reruns += 1
text("App reruns: \$(session.app_reruns)")

@fragment begin
    session = get_session_data()
    button("Inside Button")
    session.fragment_reruns += 1
    text("Fragment reruns: \$(session.fragment_reruns)")
end
```

In the above example, everytime the `Outside Button` is clicked, both counters
`session.app_reruns` and `session.fragment_reruns` are incremented. But when
the `Inside Button` is clicked, only the `session.fragment_reruns` counter is
incremented.
"""
function fragment(func::Function; id::String=String(nameof(func)))
    task = task_local_storage("app_task")

    wrapper = create_container(
        top_container(),
        Dict(
            "display" => "contents",
            "flex-direction" => get_css_value(top_container(), "flex-direction")
        ),
        Dict(),
        id,
        true
    )

    frag = Fragment()
    frag.id = id
    frag.func = func
    frag.container_props = wrapper.container

    task.session.fragments[id] = frag

    push_fragment(frag)
    push_container(wrapper)
    func()
    pop_container()
    pop_fragment()
end

@doc @doc(fragment)
macro fragment(block)
    file = replace(String(__source__.file), r"[^A-Za-z0-9]" => "_")
    name = Symbol("fragment_", file, "_", __source__.line)
    return :(
        Magic.fragment(function $(esc(name))()
            $(esc(block))
        end)
    )
end

"""
# Session persistent data

Session persistent data is an user defined data that is bound to a session and
whose lifetime is the lifetime of the session, i.e., as long as the session
stays active the data will persist. Session persistent data can be retrieved at
any moment using `get_session_data()` and is only visible to the current
session.

Although the session persistent data can be either mutable or immutable, a
common practice is to define a mutable struct to store all of your sessions's
data and store it with `set_session_data()` at the session startup. Example:

```julia
# Define the struct to hold the session persistent data
mutable struct SessionData
    foo::String
    bar::Int
end

@session_startup begin
    # Initialize the session persistent data
    session = SessionData("hello", 32)
    set_session_data(session)
end

# now `get_session_data()` can be called from anywhere
# to retrieve the current session data
```

In the example above, since the persistent data is a mutable struct, every time
`get_session_data()` is called the same `SessionData` object instance stored with
`set_session_data()` at the session startup is returned, and thus you can modify its
members without having to call `set_session_data()` ever again.

## `set_session_data()`

Stores session persistent data.

### Function Signature

```julia
function set_session_data(session_data::Any)::Nothing
```

 Argument  | Description
---------- |-------------
 `session_data` | Data of `Any` type.

## `get_session_data()`

Retrieves the previously stored session persistent data.

### Function Signature

```julia
function get_session_data()::Any
```
"""
function get_session_data()::Any
    task = task_local_storage("app_task")
    return task.session.user_session_data
end

function get_session(client_id::Cint)::Session
    return g.sessions[client_id]
end

function get_session_data(client_id::Cint)::Any
    session = get_session(client_id)
    return session.user_session_data
end

@doc @doc(get_session_data) set_session_data
function set_session_data(session_data::Any)::Nothing
    task = task_local_storage("app_task")
    task.session.user_session_data = session_data
    return nothing
end

@doc @doc(is_app_first_pass) is_session_first_pass
function is_session_first_pass()::Bool
    task = task_local_storage("app_task")
    return task.session.first_pass
end

"""
# @session_startup

Macro to define a code block that should only executed at a session's first run.
Usage:

```julia
@session_startup begin
    # session initialization logic
end
```

Internally, this macro is implemented by checking the result of
[`is_session_first_pass()`](/docs/build/docs/api-reference/application-logic/is_first_pass-func)
and running the `@session_startup` code block only if it returns `true`.

## Usage

You can define multiple `@session_startup` code blocks, but we recommend you to
keep all of your session initialization logic inside a single `@session_startup`
block after the page initialization logic.

Although sessions are not required to have `@session_startup` code blocks, some
initialization tasks should be only performed inside `@session_startup`
code blocks. See below what you are expected to do inside `@session_startup`
code blocks.

### 1. Initialization of session persistent data

Session persistent data is a user defined data that is bound to a session and
whose lifetime is the lifetime of the session, i.e., as long as the session is
active the data will persist. Session persistent data can be retrieved at any
moment using `get_page_data()`.

You can store data that you want to be available within a session via the
`set_session_data()` function, and retrieve it using the `get_session_data()`
function. See [Session persistent data](/docs/build/docs/api-reference/application-logic/session-persistent-data)
to learn more.

## See also

- [`@app_startup`](/docs/build/docs/api-reference/application-logic/app_startup-macro)
- [`@page_startup`](/docs/build/docs/api-reference/application-logic/page_startup-macro)
"""
macro session_startup(block)
    return :(
        if Magic.is_session_first_pass()
            $(esc(block))
        end
    )
end

function get_url_path()::String
    task = task_local_storage("app_task")
    return task.session.location["pathname"]
end

function parse_query(query::AbstractString)::Dict{String,String}
    d = Dict{String,String}()
    q = startswith(query, "?") ? query[2:end] : query
    isempty(q) && return d

    for pair in split(q, "&")
        isempty(pair) && continue
        kv = split(pair, "=", limit=2)
        key = unescape_uri(kv[1])
        value = length(kv) > 1 ? unescape_uri(kv[2]) : ""
        d[key] = value
    end
    return d
end

function unescape_uri(s::AbstractString)::String
    s = replace(s, "+" => " ")
    io = IOBuffer()
    i = firstindex(s)
    while i <= lastindex(s)
        c = s[i]
        if c == '%' && i + 2 <= lastindex(s)
            hex = s[i+1:i+2]
            write(io, Char(parse(UInt8, hex, base=16)))
            i = nextind(s, i, 3)
        else
            write(io, c)
            i = nextind(s, i)
        end
    end
    return String(take!(io))
end

function get_url_search()::String
    task = task_local_storage("app_task")
    return task.session.location["search"]
end

function get_url_search(client_id::Cint)::String
    session = g.sessions[client_id]
    return session.location["search"]
end

function get_query_params()::Dict
    return parse_query(get_url_search())
end

function get_query_params(client_id::Cint)::Dict
    return parse_query(get_url_search(client_id))
end

function define_page_config_func(page, func_name)
    f = function(args...; kwargs...)
        begin_page_config(page)
        getfield(Magic, func_name)(page, args...; kwargs...)
        end_page_config()
        return page
    end

    setfield!(page, func_name, f)
end

function get_page(uri)::Union{PageConfig, Missing}
    for page in g.pages
        if uri in page.uris
            return page
        end
    end
    return missing
end

"""
# Page persistent data

Page persistent data is an user defined data that is bound to a page and
whose lifetime is the lifetime of the app, i.e., as long as the app is running
the data will persist. Page persistent data can be retrieved at any moment using
`get_page_data()` and is shared accross sessions.

Although the page persistent data can be either mutable or immutable, a common
practice is to define a mutable struct to store all of your page's data and
store it with `set_page_data()` at the page startup. Example:

```julia
# Define the struct to hold the page persistent data
mutable struct PageData
    foo::String
    bar::Int
end

@page_startup begin
    # Initialize the page persistent data
    page = PageData("hello", 32)
    set_page_data(page)
end

# now `get_page_data()` can be called from anywhere to retrieve the page data
```

In the example above, since the persistent data is a mutable struct, every time
`get_page_data()` is called the same `PageData` object instance stored with
`set_page_data()` at the page startup is returned, and thus you can modify its
members without having to call `set_page_data()` ever again.

## `set_page_data()`

Stores page persistent data.

### Function Signature

```julia
function set_page_data(page_data::Any)::Nothing
```

 Argument  | Description
---------- |-------------
 `page_data` | Data of `Any` type.

## `get_page_data()`

Retrieves the previously stored page persistent data.

### Function Signature

```julia
function get_page_data()::Any
```
"""
function get_page_data()::Any
    page = get_page(get_url_path())
    return page.user_page_data
end

@doc @doc(get_page_data) set_page_data
function set_page_data(page_data::Any)::Nothing
    page = get_page(get_url_path())
    page.user_page_data = page_data
    return nothing
end

function add_page(inner_func::Union{Function, Nothing}, uri::Union{String, Vector{String}}; title::String="", description::String="")::PageConfig
    page = PageConfig()
    page.id = get_random_string(6)
    page.uris = uri isa Vector{String} ? uri : [uri]
    page.title = title
    page.description = description

    for func in [:set_title, :set_description, :add_font, :add_css_rule]
        define_page_config_func(page, func)
    end

    push!(g.pages, page)

    if inner_func != nothing
        begin_page_config(page)
        inner_func()
        end_page_config()
    end

    return page
end

add_page(uri::Union{String, Vector{String}}; title::String="", description::String="") = add_page(nothing, uri, title=title, description=description)

function strip_prefix(str::String, prefix::String)::String
    if startswith(str, prefix)
        return replace(str, prefix => "")
    end
    return str
end

DOC_PAGE_STATIC_SETTINGS = """
# Page static settings

Page static settings are persistent page settings that can only be defined
at the page's dry-run (`@page_startup`). The page static settings are used to
build the static HTML that is served when a user accesses one of the page's
URLs, which is why they cannot be changed after the page's dry-run.

Example:

```julia
@page_startup begin
    set_title("My Magic App")
    set_description("An awesome app built with Magic.jl")
end
```

See below functions to customize different page static settings.

## set_title

Sets the title of the current page (i.e. the HTML `<title>` tag).

### Function Signature

```julia
function set_title(title::String)::Nothing
```

Argument        | Description
---------------- |-------------
 `title`        | `String`. Title to be assigned to the current page.

## set_description

Sets the description of the current page (i.e. the HTML
`<meta property="og:description">` tag).

### Function Signature

```julia
function set_description(description::String)::Nothing
```

Argument        | Description
---------------- |-------------
 `description`        | `String`. Description to be assigned to the current page.

## add_font

Makes a font available in the current page, adding the necessary CSS
`@font-face` configuration in the `head` of the current page.

### Function Signature

```julia
function add_font(font_name::String, src_or_path::String)::Nothing
```

Argument        | Description
---------------- |-------------
 `font_name`        | `String`. The name that should be associated with the font.
 `src_or_path` | `String`. Either an external URL or a local serveable path inside the project's `.Magic/served-files/` directory. We recommend that you place all of your font files inside `.Magic/served-files/fonts/`.

## add_css_rule

Appends CSS rule(s) to the `head` of the current page.

Example:

```julia
add_css_rule(\"""
    label {
        font-weight: bold;
    }
    pre {
        border: 1px solid black;
    }
\""")
```

### Function Signature

```julia
function add_css_rule(rule::String)::Nothing
```

Argument        | Description
---------------- |-------------
 `rule`        | `String`. A valid CSS rule. Example: <pre>h1, h2, h3, h4, h5, h6 \\{<br/>  color: navy;<br/>\\}</pre>

## inject_html

Injects arbitrary code into the HTML page served to the clients.

Example:

```julia
inject_html(html="<div>Hello!</div>")
```

### Function Signature

```julia
function inject_html(;
    html::String="",
    file_path::Union{String, Nothing}=nothing,
    location::String="body_bottom"
)::Nothing
```

Argument        | Description
---------------- |-------------
 `html`        | `String` with the HTML code to be injected into the page.
 `file_path`   | `String` specifying the file containing the HTML that should be injected into the page.
 `location`   | `String` specifying the location *in the page* where the HTML should be injected. Possible values: `"body_bottom"` (default, injects near the bottom of the HTML body), `"body_top"` (injects near the top of the HTML body), `"head_bottom"` (injects near the bottom of the HTML head), `"head_top"` (injects near the top of the HTML head).
"""

@doc DOC_PAGE_STATIC_SETTINGS
function set_title(page::PageConfig, title::String)::Nothing
    page.title = title
    return nothing
end

@doc DOC_PAGE_STATIC_SETTINGS
function set_title(title::String)::Nothing
    task = task_local_storage("app_task")
    return set_title(task.current_page, title)
end

@doc DOC_PAGE_STATIC_SETTINGS
function set_description(page::PageConfig, description::String)::Nothing
    page.description = description
    return nothing
end

@doc DOC_PAGE_STATIC_SETTINGS
function set_description(description::String)::Nothing
    task = task_local_storage("app_task")
    return set_description(task.current_page, description)
end

@doc DOC_PAGE_STATIC_SETTINGS
function add_font(page::PageConfig, font_name::String, src_or_path::String)::Nothing
    if isfile(src_or_path)
        src_or_path = realpath(src_or_path)
    end

    add_css_rule(page, """
        @font-face {
            font-family: "$(font_name)";
            src: url($(strip_prefix(src_or_path, "$(g.dot_magic_dir)/.Magic/served-files")));
        }
    """)
    return nothing
end

@doc DOC_PAGE_STATIC_SETTINGS
function add_font(font_name::String, src_or_path::String)::Nothing
    task = task_local_storage("app_task")
    add_font(task.current_page, font_name, src_or_path)
    return nothing
end

@doc DOC_PAGE_STATIC_SETTINGS
function add_css_rule(page::PageConfig, style::String)::Nothing
    page.style *= style
    return nothing
end

@doc DOC_PAGE_STATIC_SETTINGS
function add_css_rule(style::String)::Nothing
    task = task_local_storage("app_task")
    return add_css_rule(task.current_page, style)
end

@doc DOC_PAGE_STATIC_SETTINGS
function inject_html(page::PageConfig; html::String="", file_path::Union{String, Nothing}=nothing, location::String="body_bottom")::Nothing
    if file_path !== nothing
        html *= read(file_path, String)
    end
    get!(page.html_injection, location, "")
    page.html_injection[location] *= html
    return nothing
end

@doc DOC_PAGE_STATIC_SETTINGS
function inject_html(; html::String="", file_path::Union{String, Nothing}=nothing, location::String="body_bottom")::Nothing
    task = task_local_storage("app_task")
    return inject_html(task.current_page, html=html, file_path=file_path, location=location)
end

function begin_page_config(page::PageConfig)::Nothing
    task = task_local_storage("app_task")
    task.current_page = page
    return nothing
end

function end_page_config()::Nothing
    task = task_local_storage("app_task")
    task.current_page = g.base_page_config
    return nothing
end

function create_page_html(page::PageConfig, output_path::String)::Nothing
    template = read(joinpath(@__DIR__, "../served-files/MagicPageTemplate.html"), String)

    title = length(page.title) > 0 ? page.title : g.base_page_config.title
    description = length(page.description) > 0 ? page.description : g.base_page_config.description

    get!(page.html_injection, "head_top", "")
    get!(page.html_injection, "head_bottom", "")
    get!(page.html_injection, "body_top", "")
    get!(page.html_injection, "body_bottom", "")

    page_html = replace(
        template,
        "<title>Magic App</title>" => "<title>$(title)</title>",
        "<meta property=\"og:description\" content=\"Web app made with Magic.jl\">" => "<meta property=\"og:description\" content=\"$(description)\">",
        "<!-- MAGIC PAGE STYLE -->" => "<style>$(page.style)</style>",
        "<!-- HTML HEAD TOP INJECTION -->" => page.html_injection["head_top"],
        "<!-- HTML HEAD BOTTOM INJECTION -->" => page.html_injection["head_bottom"],
        "<!-- HTML BODY TOP INJECTION -->" => page.html_injection["body_top"],
        "<!-- HTML BODY BOTTOM INJECTION -->" => page.html_injection["body_bottom"],
    )

    write(output_path, page_html)
    page.file_path = output_path
    return nothing
end

function create_404_html(output_path::String)::Nothing
    template = read(joinpath(@__DIR__, "../served-files/Magic404Template.html"), String)

    title = g.base_page_config.title
    description = g.base_page_config.description

    page_html = replace(
        template,
        "<title>Magic App</title>" => "<title>$(title)</title>",
        "<meta property=\"og:description\" content=\"Web app made with Magic.jl\">" => "<meta property=\"og:description\" content=\"$(description)\">",
    )

    write(output_path, page_html)
    return nothing
end

@doc @doc(is_app_first_pass) is_page_first_pass
function is_page_first_pass()::Bool
    page = get_current_page()
    if page !== missing
        return page.first_pass
    end
    return false
end

"""
# @page_startup

Macro to define a code block that should only be executed at the startup
(dry-run) of the current page being run (i.e. the page associated with the URL
path returned by `get_url_path()`). Usage:

```julia
@page_startup begin
    # page initialization logic
end
```

Internally, this macro is implemented by checking the result of
[`is_page_first_pass()`](/docs/build/docs/api-reference/application-logic/is_first_pass-func)
and running the `@page_startup` code block only if it returns `true`.

## Usage

You can define multiple `@page_startup` code blocks, but we recommend you to
keep all of your page initialization logic inside a single `@page_startup` block
near the top of your page script file (or, if you have all of your pages in a
single file, near the top of where the page's logic begins).

Although pages are not required to have `@page_startup` code blocks, some
initialization tasks should be only performed inside `@page_startup`
code blocks. See below what you are expected to do inside `@page_startup` code
blocks.

### 1. Page static settings

Page static settings are persistent settings that are defined at the page's
dry-run and that cannot be changed later. These include the page title,
description, extra fonts and extra styles. The static settings related functions
below can only be called inside `@page_startup` blocks
(see [Page static settings](/docs/build/docs/api-reference/application-logic/page-static-settings)
to learn more).

- `set_title()`
- `set_description()`
- `add_font()`
- `add_css_rule()`

Example:

```julia
@page_startup begin
    set_title("My Magic App")
    set_description("An awesome app built with Magic.jl")
end
```

Internally, these static settings are used to build the static HTML that is
served when a user accesses the page's URL.

### 2. Initialization of page persistent data

Page persistent data is a user defined data that is bound to a page and
whose lifetime is the lifetime of the app, i.e., as long as the app is running
the data will persist. Page persistent data can be retrieved at any moment using
`get_page_data()` and is shared accross sessions.

You can store data that you want to be available to all the sessions of a page
via the `set_page_data()` function, and retrieve it using the `get_page_data()`
function. See [Page persistent data](/docs/build/docs/api-reference/application-logic/page-persistent-data)
to learn more.

## See also

- [`@app_startup`](/docs/build/docs/api-reference/application-logic/app_startup-macro)
- [`@session_startup`](/docs/build/docs/api-reference/application-logic/session_startup-macro)
"""
macro page_startup(block)
    return :(
        if Magic.is_page_first_pass()
            Magic.begin_page_config(get_page(get_url_path()))
            $(esc(block))
            Magic.end_page_config()
        end
    )
end

get_current_page()::Union{PageConfig, Missing} = get_page(get_url_path())

"""
# is_on_page

Checks if the current page is the page associated with a given path.

## Function Signature

```julia
function is_on_page(path::String)::Bool
```

Argument        | Description
---------------- |-------------
 `path`        | `String`. A path associated with a page of the app.

## Return Value

`true` if the current page is the page associated with `path`.

The current page is the page associated with the URL path returned by
`get_url_path()`. `is_on_page()` will return `true` if `path` is any of the
paths associated with the current page, regardless of which URL path the user
used to reach the page.

## Example

The code below defines two pages, the first one being associated with two paths
(`/` and `/page-1`):

```julia
@app_startup begin
    add_page(["/", "/page-1"])
    add_page("/page-2")
end

if     is_on_page("/")        # if the current URL path is either `/` or
    include("page-1.jl")      # `/page-1`, this will return true.
elseif is_on_page("/page-2")
    include("page-2.jl")
end
```

If the user accessed the page via `/page-1`, `is_on_page("/")` will return
`true`, because the current page is in fact associated with both `/` and
`/page-1`.
"""
function is_on_page(page_path::String)::Bool
    page = get_current_page()
    if page !== missing
        return page_path in page.uris
    end
    return false
end

# App data
#--------------
"""
# App persistent data

App persistent data is an user defined data whose lifetime is the lifetime of
the app, i.e., as long as the app is running the data will persist. App
persistent data can be retrieved at any moment using `get_app_data()` and is
shared accross pages and sessions.

Although the app persistent data can be either mutable or immutable, a common
practice is to define a mutable struct to store all of your app's data and store
it with `set_app_data()` at the application startup. Example:

```julia
# Define the struct to hold the app persistent data
mutable struct AppData
    foo::String
    bar::Int
end

@app_startup begin
    # Initialize the app persistent data
    app = AppData("hello", 32)
    set_app_data(app)
end

# now `get_app_data()` can be called from anywhere to retrieve the app data
```

In the example above, since the persistent data is a mutable struct, every time
`get_app_data()` is called the same `AppData` object instance stored with
`set_app_data()` at the app startup is returned, and thus you can modify its
members without having to call `set_app_data()` ever again.

## `set_app_data()`

Stores app persistent data.

### Function Signature

```julia
function set_app_data(app_data::Any)::Nothing
```

 Argument  | Description
---------- |-------------
 `app_data` | Data of `Any` type.

## `get_app_data()`

Retrieves the previously stored app persistent data.

### Function Signature

```julia
function get_app_data()::Any
```
"""
function get_app_data()::Any
    return g.user_app_data
end

@doc @doc(get_app_data) set_app_data
function set_app_data(app_data::Any)::Nothing
    g.user_app_data = app_data
    return nothing
end

function set_callback(callback::Function)::Nothing
    g.callback = callback
    return nothing
end

function get_server_origin()::String
    return "http$(is_https_enabled() ? "s" : "")://$(g.host_name):$(g.port)"
end

# Misc
#------------
"""
# get_dot_magic_dir

Returns the location of the app's .Magic directory. By default, the .Magic
directory is created in the process working directory, but this can be changed
in the call to start_app() or via the command line.
"""
function get_dot_magic_dir()::String
    return g.dot_magic_dir
end

"""
# get_dot_magic_path

Returns the app's .Magic directory path. This is the same as
`joinpath(get_dot_magic_dir(), ".Magic")`
"""
function get_dot_magic_path()::String
    return joinpath(g.dot_magic_dir, ".Magic")
end

function get_random_string(n::Integer)::String
    CHARSET = ['0':'9'; 'A':'Z'; 'a':'z']
    return String(rand(CHARSET, n))
end

"""
# gen_serveable_path

Generates a file path where you can save a file to be served in your app.

## When to use this function

### 1. Generate a serveable path

Some widgets serve files to the client, such as
[`image`](/docs/build/docs/api-reference/interface-elements/image-func),
which serves an image in a given system path. Such widgets can only serve
resources that live inside your project's `.Magic/served-files/` directory and
subdirectories.

`gen_serveable_path()` is a convenience function to be used when you want
don't care for the name of the file you want to serve, nor where it lives, as
long as it is "serveable", i.e. it lives somewhere inside `.Magic/served-files/`.
`gen_serveable_path()` generates a path with a random file name with a given
extension inside `.Magic/served-files/generated`. You are then supposed to save your
file in the returned path and pass this path to the wiget you want.

For instance, consider an app that displays a plot given some user input. The
app's logic will look something like this:

```julia
plot_object = generate_fancy_plot(...)       # 1. Generate the plot
serveable_path = gen_serveable_path("png")   # 2. Generate a file path with `.png` extension
save_fancy_plot(plot_object, serveable_path) # 3. Save the plot at `serveable_path`
image(plot_path)                             # 4. Serve the plot image
```

### 2. Avoid Browser Caching

Aside from conveniently giving you a serveable file path, `gen_serveable_path()`
also helps to avoid browser caching issues. For instance, in the above example,
suppose that instead of saving the plot in a random serveable path everytime the
plot is regenerated we always saved it in the same serveable path. Most browsers
will automatically cache the image associated with a path, so newly generated
images in the same path would never be requested by these browsers.
Serving the newly generated plot in the path returned by `gen_serveable_path()`
prevents that from happening.

### Function Signature

```julia
function gen_serveable_path(extension::String; lifetime::String="session")::String
```

 Argument  | Description
---------- |-------------
 `extension` | File extension `String` to be appended to the randomly generated path.
 `lifetime` | A `String` indicating the lifetime of the resource. Possible values: `"session"` (default) or `"app"`. If `"session"` is provided, the file will become unavailable after the session is ended. If `"app"` is provided, the file will become unavailable after the app is stopped.

### Return Value

A random file path inside `.Magic/served-files/generated/` with extension
`extension`.
"""
function gen_serveable_path(extension::String=""; lifetime::String="session")::String
    task = task_local_storage("app_task")
    if length(extension) > 0
        if extension[1] != '.'
            extension = '.' * extension
        end
    end

    file_name = "$(get_random_string(32))$(extension)"

    dir_path = "$(g.dot_magic_dir)/.Magic/served-files/generated/$(task.session.session_id)"
    if lifetime == "app"
        dir_path = "$(g.dot_magic_dir)/.Magic/served-files/generated/app"
    end

    return "$(dir_path)/$(file_name)"
end

"""
# make_serveable_copy

Saves a serveable copy of a file inside `.Magic/served-files/`. This is a
convenience function that calls `gen_serveable_path()` and `cp()` to create a
serveable copy of a file. If you want to move the file to make it serveable
instead of creating a serveable copy, call
[`move_to_serveable_dir()`](/docs/build/docs/api-reference/application-logic/move_to_serveable_dir-func)
instead.

See [`gen_serveable_path()`](/docs/build/docs/api-reference/application-logic/gen_serveable_path-func)
to learn more.

### Function Signature

```julia
function make_serveable_copy(file_path::String; lifetime::String="session")::String
```

 Argument  | Description
---------- |-------------
 `file_path` | A `String` with the path of the file that should be copied.
 `lifetime` | A `String` indicating the lifetime of the generated copy. Possible values: `"session"` (default) or `"app"`. If `"session"` is provided, the file copy will become unavailable after the session is ended. If `"app"` is provided, the file copy will become unavailable after the app is stopped.

### Return Value

A `String` with the path to the file copy.
"""
function make_serveable_copy(file_path::String; lifetime::String="session")::String
    serveable_path = gen_serveable_path(lifetime=lifetime) * splitext(file_path)[2]
    cp(file_path, serveable_path, force=true)
    return serveable_path
end

"""
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
"""
function move_to_serveable_dir(file_path::String; lifetime::String="session")::String
    serveable_path = gen_serveable_path(lifetime=lifetime) * splitext(file_path)[2]
    mv(file_path, serveable_path, force=true)
    return serveable_path
end

"""
# DEPRECATED @once

Macro to prevent structs from being redefined on script reruns.

Pass a struct definition to this macro to prevent it from being redefined
on script reruns. Example:

```julia
@once mutable struct Foo
    bar::String
    baz::Int
end
```

## Explanation

Struct redefinitions can cause problems, especially on session persistent data.
Consider the following example:

```julia
mutable struct Foo
    bar::Int
end

mutable struct SessionData
    foo::Foo
end

@session_startup begin
    session = SessionData(Foo(0))
    set_session_data(session)
end

session.foo = Foo(rand(1:10))
```

The above code will work on the first session pass but will fail in the next
one with the following message:

> LoadError:
>   MethodError: Cannot \`convert\` an object of type **Main.MagicApp.Foo**
>   to an object of type **Main.MagicApp.Foo**.

This means that `Foo` was redefined and its new definition cannot be converted
to the original one that is being used in the session persistent data.

To avoid this issue, we simply prepend `@once` to the definition of `Foo`.
"""
macro once(def)
    struct_name = def.args[2]

    return esc(quote
        if haskey(Magic.USER_TYPES, $(QuoteNode(struct_name)))
            global $struct_name = Magic.USER_TYPES[$(QuoteNode(struct_name))]
        else
            $def

            Magic.USER_TYPES[$(QuoteNode(struct_name))] = $struct_name
        end
    end)
end
