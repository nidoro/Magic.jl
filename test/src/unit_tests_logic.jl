
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

    @test_throws Magic.IncorrectUsage set_title("Title")
    @test_throws Magic.IncorrectUsage set_description("Description")
    @test_throws Magic.IncorrectUsage set_favicon("🚀")
    @test_throws Magic.IncorrectUsage add_font("Pacifico", "../examples/.Magic/served-files/fonts/Pacifico-Regular.ttf")
    @test_throws Magic.IncorrectUsage add_css_rule("")
    @test_throws Magic.IncorrectUsage inject_html("")

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

        # Test that set_favicon fails if it is called outside @page_startup
        @test_throws Magic.PastStartupCall start_app(
            ()->(set_favicon("🚀")),
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

@testset "favicon" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: favicon
    ------------------------------------------------------------------------
    """

    # is_emoji
    for s in ("🚀", "🚀🚀", "❤️", "⭐", "👍🏽", "👨‍👩‍👧", "🇧🇷", "1️⃣", "#️⃣")
        @test Magic.is_emoji(s)
    end

    for s in ("", "a", "1", "#", "a🚀", "🚀 ", "logo.png", "/images/logo.png", "https://foo.com/logo.ico")
        @test !Magic.is_emoji(s)
    end

    # Static HTML
    page_html = function(page::Magic.PageConfig)
        path = tempname()
        Magic.create_page_html(page, path)
        return read(path, String)
    end

    default_tag = "href=\"/Magic.jl/images/favicon.ico\""
    emoji_tag = "<text y='.9em' font-size='90'>🚀</text>"

    html = page_html(Magic.PageConfig())
    @test occursin(default_tag, html)
    @test !occursin("data:image/svg+xml", html)

    html = page_html(Magic.PageConfig(favicon="🚀"))
    @test occursin(emoji_tag, html)
    @test !occursin(default_tag, html)

    html = page_html(Magic.PageConfig(favicon="logo.png"))
    @test occursin(default_tag, html)
    @test !occursin("logo.png", html)

    # Regenerating a page does not duplicate the tag
    page = Magic.PageConfig(favicon="🚀")
    page_html(page)
    @test count(emoji_tag, page_html(page)) == 1

    # `#` must not end the data URL
    html = page_html(Magic.PageConfig(favicon="#️⃣"))
    @test occursin("font-size='90'>%23", html)
    @test !occursin("font-size='90'>#", html)

    # App-wide favicon and page override
    @test :set_favicon in Magic.PAGE_CONFIG_FUNCS

    @maybe_suppress start_app(
        ()->begin
            if is_app_first_pass()
                add_page("/before")
                set_favicon("🚀")
                add_page("/after")
                add_page("/override").set_favicon("🎉")
                add_page("/do-block") do
                    set_favicon("🎈")
                end
            end
        end,
        port=PORT,
        dev_mode=true,
        init_and_quit=true,
        rethrow_rerun_exceptions=true
    )

    favicon_of(uri) = Magic.get_page(uri).favicon
    @test Magic.g.base_page_config.favicon == "🚀"
    @test favicon_of("/before") == "🚀"
    @test favicon_of("/after") == "🚀"
    @test favicon_of("/override") == "🎉"
    @test favicon_of("/do-block") == "🎈"

    path = tempname()
    Magic.create_404_html(path)
    @test occursin(emoji_tag, read(path, String))
end

@testset "other public logic functions" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: other public logic functions
    ------------------------------------------------------------------------
    """

    temp_dir = mktempdir()
    temp_file = tempname()
    touch(temp_file)

    @test_throws Magic.IncorrectUsage gen_serveable_path()
    @test_throws Magic.IncorrectUsage make_serveable_copy(temp_file)
    @test_throws Magic.IncorrectUsage move_to_serveable_dir(temp_file)

    @test_throws Magic.IncorrectUsage get_url_path()
    @test_throws Magic.IncorrectUsage get_url_search()
    @test_throws Magic.IncorrectUsage get_query_params()

    @test_throws Magic.IncorrectUsage rerun()

    @maybe_suppress begin
        @test_throws Magic.InvalidArgument gen_serveable_path(lifetime="INVALID_LIFETIME")

        @test_throws Magic.InvalidArgument make_serveable_copy(temp_dir)
        @test_throws Magic.InvalidArgument make_serveable_copy(temp_file, lifetime="INVALID_LIFETIME")

        @test_throws Magic.InvalidArgument move_to_serveable_dir(temp_dir)
        @test_throws Magic.InvalidArgument move_to_serveable_dir(temp_file, lifetime="INVALID_LIFETIME")
    end
end

