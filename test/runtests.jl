using Test
using Magic

@testset "function start_app(...) input validation" begin
    @test_throws Magic.InvalidFile              start_app("__NON_EXISTING_FILE__", dot_magic_dir="../examples")
    @test_throws Magic.InvalidHostname          start_app("../examples/app.jl", host_name="__INVALID_HOSTNAME__", dot_magic_dir="../examples")
    @test_throws Magic.InvalidPort              start_app("../examples/app.jl", port=-1, dot_magic_dir="../examples")
    @test_throws Magic.InvalidPort              start_app("../examples/app.jl", port=65535+1, dot_magic_dir="../examples")
    @test_throws Magic.InvalidUploadMaxSize     start_app("../examples/app.jl", upload_max_size=-1, dot_magic_dir="../examples")
    @test_throws Magic.InvalidUploadMaxFiles    start_app("../examples/app.jl", upload_max_files=-1, dot_magic_dir="../examples")
    @test_throws Magic.InvalidDirectory         start_app("../examples/app.jl", dot_magic_dir="__NON_EXISTING_DIR__")
    @test_throws Magic.InvalidDirectory         start_app("../examples/app.jl", docs_path="__NON_EXISTING_DIR__", dot_magic_dir="../examples")
end

@testset "Examples dry run" begin
    @test start_app("../examples/app.jl", dot_magic_dir="../examples", dev_mode=true, init_and_quit=true) === nothing
end
