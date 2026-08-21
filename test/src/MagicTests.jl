#-------------------------------------------------------------------------------
# How to run these tests
#-------------------------------------------------------------------------------
#
# > cd test
# > julia --project
# pkg> dev ..
# pkg> instantiate
# julia> using Revise, Magic, MagicTests, ReTest
# julia> retest(#= test name or number =#)
#
#-------------------------------------------------------------------------------
module MagicTests

using ReTest
using Magic

@testset "function start_app(...) input validation" begin
    @info """
    ------------------------------------------------------------------
    Test: function start_app(...) input validation
    ------------------------------------------------------------------------
    """
    @test_throws Magic.InvalidFile              start_app("__NON_EXISTING_FILE__", dev_mode=true, init_and_quit=true)
    @test_throws Magic.InvalidHostname          start_app("src/test_examples.jl", host_name="__INVALID_HOSTNAME__", dev_mode=true, init_and_quit=true)
    @test_throws Magic.InvalidPort              start_app("src/test_examples.jl", port=-1, dev_mode=true, init_and_quit=true)
    @test_throws Magic.InvalidPort              start_app("src/test_examples.jl", port=65535+1, dev_mode=true, init_and_quit=true)
    @test_throws Magic.InvalidUploadMaxSize     start_app("src/test_examples.jl", upload_max_size=-1, dev_mode=true, init_and_quit=true)
    @test_throws Magic.InvalidUploadMaxFiles    start_app("src/test_examples.jl", upload_max_files=-1, dev_mode=true, init_and_quit=true)
    @test_throws Magic.InvalidDirectory         start_app("src/test_examples.jl", dot_magic_dir="__NON_EXISTING_DIR__", dev_mode=true, init_and_quit=true)
    @test_throws Magic.InvalidDirectory         start_app("src/test_examples.jl", docs_path="__NON_EXISTING_DIR__", dev_mode=true, init_and_quit=true)
end

@testset "Examples dry run" begin
    @info """
    ------------------------------------------------------------------
    Test: Examples dry run
    ------------------------------------------------------------------------
    """
    @test start_app("../examples/app.jl", dot_magic_dir="../examples", dev_mode=true, init_and_quit=true) === nothing
end

@testset "Example: 01-counter.jl + 01-counter.js" begin
    @info """
    ------------------------------------------------------------------
    Test: Example: 01-counter.jl + 01-counter.js
    ------------------------------------------------------------------------
    """
    ENV["MAGIC_TEST_PAGE"] = "01-counter.jl"
    ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "01-counter.js"
    ENV["MAGIC_TEST_CLIENTS"] = 10
    @test start_app("src/test_examples.jl", dev_mode=true) === nothing
    @test Magic.g.test_successfull
end

@testset "Example: 02-todo.jl + 02-todo.js" begin
    @info """
    ------------------------------------------------------------------
    Test: Example: 02-todo.jl + 02-todo.js
    ------------------------------------------------------------------------
    """
    ENV["MAGIC_TEST_PAGE"] = "02-todo.jl"
    ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "02-todo.js"
    ENV["MAGIC_TEST_CLIENTS"] = 5
    @test start_app("src/test_examples.jl", dev_mode=true) === nothing
    @test Magic.g.test_successfull
end

# @testset "Example: 05-curves.jl + 05-curves.js" begin
#     ENV["MAGIC_TEST_PAGE"] = "05-curves.jl"
#     ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "05-curves.js"
#     ENV["MAGIC_TEST_CLIENTS"] = 0
#     @test start_app("test_examples.jl", dev_mode=true) === nothing
#     @test Magic.g.test_successfull
# end

end
