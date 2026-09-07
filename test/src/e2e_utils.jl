
function spawn_chromium_instance()::Nothing
    app_data = get_app_data()

    n = length(app_data.chromium_instances)+1
    test_url = "$(get_server_origin())/?chromium_instance=$(n)"
    mkpath("./log")

    command_line = "chromium --headless --disable-gpu --enable-logging=stderr --ignore-certificate-errors $test_url"
    cmd = Cmd(String.(split(command_line)))
    proc = run(pipeline(cmd, stdout="./log/chromium_$(n).log", stderr="./log/chromium_$(n).log"), wait=false)

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
