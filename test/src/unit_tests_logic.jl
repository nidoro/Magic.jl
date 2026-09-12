
# For single session run tests
#---------------------------------
mutable struct AppData
    chromium_instances::Vector{Base.Process}
end

function single_session_rerun_callback(reason::Magic.CallbackReason, args...)
    app_data = get_app_data()

    if     reason == Magic.CallbackReason_ServerReady
        app_data = AppData([])
        set_app_data(app_data)
        spawn_chromium_instance()
    elseif reason == Magic.CallbackReason_ErrorDuringRerun || reason == Magic.CallbackReason_TaskFinished
        kill_all_chromium_instances()
    end
end

@testset "start_app(...) input validation" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: start_app(...) input validation
    ------------------------------------------------------------------------
    """
    @maybe_suppress begin
        @test_throws Magic.InvalidArgument start_app("__NON_EXISTING_FILE__", dev_mode=true, init_and_quit=true)
        @test_throws Magic.InvalidArgument start_app("src/test_examples.jl", host_name="__INVALID_HOSTNAME__", dev_mode=true, init_and_quit=true)
        @test_throws Magic.InvalidArgument start_app("src/test_examples.jl", port=-1, dev_mode=true, init_and_quit=true)
        @test_throws Magic.InvalidArgument start_app("src/test_examples.jl", port=65535+1, dev_mode=true, init_and_quit=true)
        @test_throws Magic.InvalidArgument start_app("src/test_examples.jl", upload_max_size=-1, dev_mode=true, init_and_quit=true)
        @test_throws Magic.InvalidArgument start_app("src/test_examples.jl", upload_max_files=-1, dev_mode=true, init_and_quit=true)
        @test_throws Magic.InvalidArgument start_app("src/test_examples.jl", dot_magic_dir="__NON_EXISTING_DIR__", dev_mode=true, init_and_quit=true)
        @test_throws Magic.InvalidArgument start_app("src/test_examples.jl", docs_path="__NON_EXISTING_DIR__", dev_mode=true, init_and_quit=true)
    end

    # Test function as entry-point
    @maybe_suppress @test start_app(()->(button("Button")), port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true) === nothing
end

@testset "add_page(...) and page static settings" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: add_page(...)
    ------------------------------------------------------------------------
    """

    @maybe_suppress begin
        # Test that it is ok to pass to add_page a uri that does not starts with '/'
        @test start_app(()->(@app_startup begin add_page("foo") end), dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true) === nothing

        # Test that add_page fails if uris list contains non-Strings
        @test_throws Magic.InvalidArgument start_app(()->(add_page(["/foo", Dict()])), dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)

        # Test that add_page fails if it is called outside @app_startup
        @test_throws Magic.PastStartupCall start_app(()->(add_page("/foo")), dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)

        # Test that set_title fails if it is called outside @page_startup
        @test_throws Magic.PastStartupCall start_app(
            ()->(set_title("Title")),
            port=PORT,
            dev_mode=true,
            callback=single_session_rerun_callback,
            rethrow_rerun_exceptions=true,
            throw_client_side_error=true
        )

        # Test that set_description fails if it is called outside @page_startup
        @test_throws Magic.PastStartupCall start_app(
            ()->(set_description("Description")),
            port=PORT,
            dev_mode=true,
            callback=single_session_rerun_callback,
            rethrow_rerun_exceptions=true,
            throw_client_side_error=true
        )

        # Test that add_font fails if it is called outside @page_startup
        @test_throws Magic.PastStartupCall start_app(
            ()->(add_font("Pacifico", "../examples/.Magic/served-files/fonts/Pacifico-Regular.ttf")),
            port=PORT,
            dev_mode=true,
            callback=single_session_rerun_callback,
            rethrow_rerun_exceptions=true,
            throw_client_side_error=true
        )

        # Test that add_font fails with empty string name
        @test_throws Magic.InvalidArgument start_app(
            ()->(add_font("", "../examples/.Magic/served-files/fonts/Pacifico-Regular.ttf")),
            port=PORT,
            dev_mode=true,
            init_and_quit=true,
            rethrow_rerun_exceptions=true,
            throw_client_side_error=true
        )

        # Test that add_css_rule fails if it is called outside @page_startup
        @test_throws Magic.PastStartupCall start_app(
            ()->(add_css_rule("")),
            port=PORT,
            dev_mode=true,
            callback=single_session_rerun_callback,
            rethrow_rerun_exceptions=true,
            throw_client_side_error=true
        )

        # Test that inject_html fails if called non-UTF8 file
        @test_throws Magic.InvalidArgument start_app(
            ()->(inject_html(file_path="../examples/.Magic/served-files/fonts/Pacifico-Regular.ttf")),
            port=PORT,
            dev_mode=true,
            init_and_quit=true,
            rethrow_rerun_exceptions=true,
            throw_client_side_error=true
        )

        # Test that inject_html fails if it is called outside @page_startup
        @test_throws Magic.PastStartupCall start_app(
            ()->(inject_html()),
            port=PORT,
            dev_mode=true,
            callback=single_session_rerun_callback,
            rethrow_rerun_exceptions=true,
            throw_client_side_error=true
        )
    end
end

@testset "other public logic functions" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: other public logic functions
    ------------------------------------------------------------------------
    """

    @maybe_suppress begin
        @test_throws Magic.InvalidArgument gen_serveable_path(lifetime="INVALID_LIFETIME")

        temp_dir = mktempdir()
        temp_file = tempname()
        touch(temp_file)

        @test_throws Magic.InvalidArgument make_serveable_copy(temp_dir)
        @test_throws Magic.InvalidArgument make_serveable_copy(temp_file, lifetime="INVALID_LIFETIME")

        @test_throws Magic.InvalidArgument move_to_serveable_dir(temp_dir)
        @test_throws Magic.InvalidArgument move_to_serveable_dir(temp_file, lifetime="INVALID_LIFETIME")
    end
end

