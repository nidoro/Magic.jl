
function get_net_layer_func(func_sym::Symbol)::Ptr
    lib = Libdl.dlopen(g.MAGIC_SO)
    return Libdl.dlsym(lib, func_sym)
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
        get_net_layer_func(:MG_InitNetLayer),
        Cvoid,
        (Cstring, Cint, Cint, Cstring, Cint, Cint, Cstring, Cint, Cstring, Cint, Cint, Cint, Cint),
        host_name, Cint(sizeof(host_name)), port, docs_path, Cint(sizeof(docs_path)), Cint(ipc_port), dot_magic_dir, Cint(sizeof(dot_magic_dir)), package_root_dir, Cint(sizeof(package_root_dir)), Cint(upload_max_size), Cint(verbose), Cint(dev_mode)
    )
end

function create_app_event(event_type::AppEventType, client_id::Cint, payload::Union{String, Nothing})::AppEvent
    payload_ptr = payload !== nothing ? payload : Ptr{Cchar}(0)
    payload_size = payload !== nothing ? Cint(sizeof(payload)) : Cint(0)
    return ccall(get_net_layer_func(:MG_CreateAppEvent), AppEvent, (AppEventType, Cint, Ptr{Cchar}, Cint), event_type, client_id, payload_ptr, payload_size)
end

function destroy_net_event(ev::NetEvent)::Nothing
    ccall(get_net_layer_func(:MG_DestroyNetEvent), Cvoid, (NetEvent,), ev)
end

function server_is_running()::Bool
    return ccall(get_net_layer_func(:MG_ServerIsRunning), Cint, ())
end

function do_service_work()::Int
    return ccall(get_net_layer_func(:MG_DoServiceWork), Cint, ())
end

function stop_server()
    return ccall(get_net_layer_func(:MG_StopServer), Cvoid, ())
end

"""
# get\\_server\\_port

Returns the port being listened by the web server.

### Function Signature

```julia
function get_server_port()::Int
```

## See also

- [`get_server_host`](/docs/build/docs/api-reference/application-logic/get_server_host-func)
- [`get_server_origin`](/docs/build/docs/api-reference/application-logic/get_server_origin-func)
- [`get_url_search`](/docs/build/docs/api-reference/application-logic/get_url_search-func)
- [`get_query_params`](/docs/build/docs/api-reference/application-logic/get_query_params-func)
"""
function get_server_port()::Int
    return ccall(get_net_layer_func(:MG_GetServerPort), Cint, ())
end

function is_tls_enabled()::Bool
    return ccall(get_net_layer_func(:MG_IsTLSEnabled), Cint, ())
end

function is_https_enabled()::Bool
    if g.net_layer_ready
        return ccall(get_net_layer_func(:MG_IsHTTPSEnabled), Cint, ())
    else
        return false
    end
end

function lock_client(client_id::Cint)::Nothing
    ccall(get_net_layer_func(:MG_LockClient), Cvoid, (Cint,), client_id)
    return nothing
end

function unlock_client(client_id::Cint)::Nothing
    ccall(get_net_layer_func(:MG_UnlockClient), Cvoid, (Cint,), client_id)
    return nothing
end

function pop_net_event()::NetEvent
    return ccall(get_net_layer_func(:MG_PopNetEvent), NetEvent, ())
end

function push_app_event(app_event::AppEvent)::Nothing
    ccall(get_net_layer_func(:MG_PushAppEvent), Cvoid, (AppEvent,), app_event)
    return nothing
end

function push_uri_mapping(uri::String, resource_path::String)::Nothing
    ccall(get_net_layer_func(:MG_PushURIMapping), Cvoid, (Cstring, Cint, Cstring, Cint), uri, Cint(sizeof(uri)), resource_path, Cint(sizeof(resource_path)))
    return nothing
end

function clear_uri_mapping()::Nothing
    ccall(get_net_layer_func(:MG_ClearURIMapping), Cvoid, ())
    return nothing
end

function get_mime_type(file_path::AbstractString)::String
    result = ccall(
        get_net_layer_func(:MG_GetMimeType),
        Cstring,
        (Cstring,),
        file_path
    )
    return unsafe_string(result)
end
