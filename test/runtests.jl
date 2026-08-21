using Test
using Magic

const TESTS_TO_RUN = isempty(ARGS) ? nothing : ARGS

function should_run(name::String)::Bool
    return TESTS_TO_RUN === nothing || name in TESTS_TO_RUN
end

should_run("start_app") && @testset "function start_app(...) input validation" begin
    @test_throws Magic.InvalidFile              start_app("__NON_EXISTING_FILE__", dev_mode=true, init_and_quit=true)
    @test_throws Magic.InvalidHostname          start_app("test_examples.jl", host_name="__INVALID_HOSTNAME__", dev_mode=true, init_and_quit=true)
    @test_throws Magic.InvalidPort              start_app("test_examples.jl", port=-1, dev_mode=true, init_and_quit=true)
    @test_throws Magic.InvalidPort              start_app("test_examples.jl", port=65535+1, dev_mode=true, init_and_quit=true)
    @test_throws Magic.InvalidUploadMaxSize     start_app("test_examples.jl", upload_max_size=-1, dev_mode=true, init_and_quit=true)
    @test_throws Magic.InvalidUploadMaxFiles    start_app("test_examples.jl", upload_max_files=-1, dev_mode=true, init_and_quit=true)
    @test_throws Magic.InvalidDirectory         start_app("test_examples.jl", dot_magic_dir="__NON_EXISTING_DIR__", dev_mode=true, init_and_quit=true)
    @test_throws Magic.InvalidDirectory         start_app("test_examples.jl", docs_path="__NON_EXISTING_DIR__", dev_mode=true, init_and_quit=true)
end

should_run("examples_dry_run") && @testset "Examples dry run" begin
    @test start_app("../examples/app.jl", dot_magic_dir="../examples", dev_mode=true, init_and_quit=true) === nothing
end

should_run("01-counter.jl + 01-counter.js") && @testset "Example: 01-counter.jl + 01-counter.js" begin
    ENV["MAGIC_TEST_PAGE"] = "01-counter.jl"
    ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "01-counter.js"
    ENV["MAGIC_TEST_CLIENTS"] = 10
    @test start_app("test_examples.jl", dev_mode=true) === nothing
    @test Magic.g.test_successfull
end

should_run("02-todo.jl + 02-todo.js") && @testset "Example: 01-counter.jl + 01-counter.js" begin
    ENV["MAGIC_TEST_PAGE"] = "02-todo.jl"
    ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "02-todo.js"
    ENV["MAGIC_TEST_CLIENTS"] = 5
    @test start_app("test_examples.jl", dev_mode=true) === nothing
    @test Magic.g.test_successfull
end
