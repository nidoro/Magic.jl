using Test
using Magic

@testset "function start_app(...)" begin
    @test_throws Magic.FileNotFoundError        start_app("__NON_EXISTING_FILE__", dot_magic_dir="../examples")
    @test_throws Magic.InvalidHostnameError     start_app("../examples/app.jl", host_name="__INVALID_HOSTNAME__", dot_magic_dir="../examples")
    @test_throws Magic.InvalidPortError         start_app("../examples/app.jl", port=-1, dot_magic_dir="../examples")
    @test_throws Magic.InvalidPortError         start_app("../examples/app.jl", port=65535+1, dot_magic_dir="../examples")
    @test_throws Magic.InvalidUploadMaxSize     start_app("../examples/app.jl", upload_max_size=-1, dot_magic_dir="../examples")
    @test_throws Magic.InvalidUploadMaxFiles    start_app("../examples/app.jl", upload_max_files=-1, dot_magic_dir="../examples")
    @test_throws Magic.DirectoryNotFoundError   start_app("../examples/app.jl", dot_magic_dir="__NON_EXISTING_DIR__")
    @test_throws Magic.DirectoryNotFoundError   start_app("../examples/app.jl", docs_path="__NON_EXISTING_DIR__", dot_magic_dir="../examples")
end
