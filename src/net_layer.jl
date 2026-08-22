
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

function create_app_event(event_type::AppEventType, client_id::Cint, payload::Union{String, Nothing})::AppEvent
    payload_ptr = payload !== nothing ? payload : Ptr{Cchar}(0)
    payload_size = payload !== nothing ? Cint(sizeof(payload)) : Cint(0)
    return ccall((:MG_CreateAppEvent, g.MAGIC_SO), AppEvent, (AppEventType, Cint, Ptr{Cchar}, Cint), event_type, client_id, payload_ptr, payload_size)
end

function destroy_net_event(ev::NetEvent)::Nothing
    ccall((:MG_DestroyNetEvent, g.MAGIC_SO), Cvoid, (NetEvent,), ev)
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
