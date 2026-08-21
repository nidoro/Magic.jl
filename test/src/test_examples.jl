using Magic

test_page = ENV["MAGIC_TEST_PAGE"]
test_actions_script = ENV["MAGIC_TEST_ACTIONS_SCRIPT"]
test_clients = parse(Int, ENV["MAGIC_TEST_CLIENTS"])

function test_successfull(client_id::Cint)::Tuple{Bool, String}
    if (test_page, test_actions_script) == ("01-counter.jl", "01-counter.js")
        session_data = get_session_data(client_id)
        if session_data != 30
            return (false, "Click count should be 30, but it is $(session_data)")
        end
        return (true, "")

    elseif (test_page, test_actions_script) == ("02-todo.jl", "02-todo.js")
        expected_items = (Item("New item 2", false), Item("New item 3", false), Item("New item 4", false))

        session_data = get_session_data(client_id)

        if length(session_data.items) == length(expected_items)
            for i in range(1, length(expected_items))
                if session_data.items[i].name != expected_items[i].name || session_data.items[i].status != expected_items[i].status
                    return (false, "Item $(i) should be $(expected_items[i]), but it is $(session_data.items[i]).")
                end
            end
        else
            return (false, "Expected $(length(expected_items)) items on the list, but got $(length(session_data.items)).")
        end
        return (true, "")

    elseif (test_page, test_actions_script) == ("05-curves.jl", "05-curves.js")
        expected = (2.0, 4.1, 1.6, 2.0)
        realized = (
            round(Magic.get_widget_by_label(client_id, "🔴 Curve Shift").value; digits=1),
            round(Magic.get_widget_by_label(client_id, "🟢 Curve Shift").value; digits=1),
            round(Magic.get_widget_by_label(client_id, "🔴 Curve Scale").value; digits=1),
            round(Magic.get_widget_by_label(client_id, "🟢 Curve Scale").value; digits=1),
        )

        if expected != realized
            return (false, "Expected slider values to be $(expected), but they are $(realized)")
        end

        return (true, "")

    elseif (test_page, test_actions_script) == ("07-probability.jl", "07-probability.js")
        expected = ("Gamma", 2.5, 3.0)
        realized = (
            Magic.get_widget_by_label(client_id, "Function").value,
            round(Magic.get_widget_by_label(client_id, "Shape (α)").value; digits=1),
            round(Magic.get_widget_by_label(client_id, "Rate (β)").value; digits=1),
        )

        if expected != realized
            return (false, "Expected widget values to be $(expected), but they are $(realized)")
        end

        return (true, "")
    end

    # NOTE: We should never reach here
    return (false, "Test not found!")
end

function start_test()::Nothing
    app_data = get_app_data()

    test_url = "$(get_server_origin())/?chromium_instance=$(length(app_data.chromium_instances)+1)"

    cmd = "chromium --headless --disable-gpu $test_url"
    proc = run(Cmd(String.(split(cmd))), wait=false)

    sleep(0.25)
    if process_running(proc)
        push!(app_data.chromium_instances, proc)
    else
        throw(Magic.TestFailed(test_url, "Failed to spawn a chromium instance"))
    end

    return nothing
end

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
        for i in range(1, test_clients)
            start_test()
        end
    elseif reason == Magic.CallbackReason_ClientLeft
        client_id = args[1]

        query = get_query_params(client_id)
        if haskey(query, "chromium_instance")
            p = parse(Int, query["chromium_instance"])
            proc = app_data.chromium_instances[p]
            kill_chromium_instance(proc)
            app_data.done += 1

            test_url = "$(get_server_origin())/?chromium_instance=$(p)"

            success, feedback = test_successfull(client_id)

            if !success
                kill_all_chromium_instances()
                throw(Magic.TestFailed(test_url, feedback))
            end

            if app_data.done == length(app_data.chromium_instances)
                Magic.g.test_successfull = true
                stop_app()
            end
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

    Magic.set_callback(callback)
end

@page_startup begin
    inject_html(html="<script>")
    inject_html(file_path=joinpath(@__DIR__, test_actions_script))
    inject_html(html="</script>")
end

include("../../examples/$(test_page)")

