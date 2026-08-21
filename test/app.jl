using Magic

function kill_chromium_instance(instance::Base.Process)::Nothing
    if process_running(instance)
        kill(instance)
    end
    return nothing
end

function kill_all_chromium_instances()::Nothing
    app_data = get_app_data()

    for instance in app_data.chromium_instances
        kill_chromium_instance(instance)
    end

    return nothing
end

function callback(reason::Magic.CallbackReason, args...)
    app_data = get_app_data()

    if     reason == Magic.CallbackReason_ServerReady
        for i in 1:10
            test_url = "$(get_server_origin())/01-counter?chromium_instance=$(i)"

            cmd = "chromium --headless --disable-gpu $test_url"
            proc = run(Cmd(String.(split(cmd))), wait=false)

            sleep(0.25)
            if process_running(proc)
                push!(app_data.chromium_instances, proc)
            else
                throw(Magic.TestFailed(test_url, "Failed to spawn a chromium instance"))
            end
        end
    elseif reason == Magic.CallbackReason_ClientLeft
        client_id = args[1]

        query = get_query_params(client_id)
        p = parse(Int, query["chromium_instance"])
        proc = app_data.chromium_instances[p]
        kill_chromium_instance(proc)
        app_data.done += 1

        test_url = "$(get_server_origin())/01-counter?chromium_instance=$(p)"

        session_data = get_session_data(client_id)
        if session_data != 30
            kill_all_chromium_instances()
            throw(Magic.TestFailed(test_url, "Click count should be 30, but it is $(session_data)"))
        end

        if app_data.done == length(app_data.chromium_instances)
            stop_app()
        end
    elseif reason == Magic.CallbackReason_ClientSideError
        client_id, session_id, payload = args
        throw(Magic.ClientSideError(payload))
    end
end

mutable struct AppData
    chromium_instances::Vector{Base.Process}
    done::Int
end

@app_startup begin
    app_data = AppData([], 0)
    set_app_data(app_data)

    add_page("/01-counter")
    Magic.set_callback(callback)
end

page = get_current_page()

@page_startup begin
    inject_html(html="<script>")
    inject_html(file_path=joinpath(@__DIR__, ".$(page.uris[1]).js"))
    inject_html(html="</script>")
end

if page !== missing
    include("../examples$(page.uris[1]).jl")
end
