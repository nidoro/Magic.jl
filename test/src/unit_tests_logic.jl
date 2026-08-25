
@testset "start_app(...) input validation" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: start_app(...) input validation
    ------------------------------------------------------------------------
    """
    @maybe_suppress begin
        @test_throws Magic.InvalidFile              start_app("__NON_EXISTING_FILE__", dev_mode=true, init_and_quit=true)
        @test_throws Magic.InvalidHostname          start_app("src/test_examples.jl", host_name="__INVALID_HOSTNAME__", dev_mode=true, init_and_quit=true)
        @test_throws Magic.InvalidPort              start_app("src/test_examples.jl", port=-1, dev_mode=true, init_and_quit=true)
        @test_throws Magic.InvalidPort              start_app("src/test_examples.jl", port=65535+1, dev_mode=true, init_and_quit=true)
        @test_throws Magic.InvalidUploadMaxSize     start_app("src/test_examples.jl", upload_max_size=-1, dev_mode=true, init_and_quit=true)
        @test_throws Magic.InvalidUploadMaxFiles    start_app("src/test_examples.jl", upload_max_files=-1, dev_mode=true, init_and_quit=true)
        @test_throws Magic.InvalidDirectory         start_app("src/test_examples.jl", dot_magic_dir="__NON_EXISTING_DIR__", dev_mode=true, init_and_quit=true)
        @test_throws Magic.InvalidDirectory         start_app("src/test_examples.jl", docs_path="__NON_EXISTING_DIR__", dev_mode=true, init_and_quit=true)
    end

    # Test function as entry-point
    @maybe_suppress @test start_app(()->(button("Button")), port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true) === nothing
end
