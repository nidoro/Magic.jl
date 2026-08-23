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

const PORT = 3443

@testset "start_app(...) input validation" begin
    @info """
    ------------------------------------------------------------------
    Test: start_app(...) input validation
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

@testset "Function as entry point" begin
    @info """
    ------------------------------------------------------------------
    Test: Function as entry point
    ------------------------------------------------------------------------
    """
    function test_app()
        button("Ok!")
    end

    @test start_app(test_app, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true) === nothing
end

@testset "button(...) input validation" begin
    @info """
    ------------------------------------------------------------------
    Test: button(...) input validation
    ------------------------------------------------------------------------
    """
    function test_style()   button("Button", style="INVALID_STYLE") end
    function test_icon()    button("Button", icon="INVALID_ICON") end
    function test_onclick() button("Button", onclick=()->(), args=(1,2,3)) end

    @test_throws Magic.InvalidArgument start_app(test_style, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
    @test_throws Magic.InvalidArgument start_app(test_icon, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
    @test_throws Magic.InvalidArgument start_app(test_onclick, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
end

@testset "selectbox(...) input validation" begin
    @info """
    ------------------------------------------------------------------
    Test: selectbox(...) input validation
    ------------------------------------------------------------------------
    """
    if false
        function test_return()
            set_default_value("slc", 4)
            val = selectbox("Select Box", [1, 2, 3, "abc", 3.14], initial_value=5, id="slc")
        end

        start_app(test_return, port=PORT, dev_mode=true, init_and_quit=false, rethrow_rerun_exceptions=true)
    end
end

@testset "Examples dry run" begin
    @info """
    ------------------------------------------------------------------
    Test: Examples dry run
    ------------------------------------------------------------------------
    """
    @test start_app("../examples/app.jl", dot_magic_dir="../examples", port=PORT, dev_mode=true, init_and_quit=true) === nothing
end

@testset "examples/01-counter.jl + 01-counter.js" begin
    @info """
    ------------------------------------------------------------------
    Test: examples/01-counter.jl + 01-counter.js
    ------------------------------------------------------------------------
    """
    ENV["MAGIC_TEST_PAGE"] = "01-counter.jl"
    ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "01-counter.js"
    ENV["MAGIC_TEST_CLIENTS"] = 10
    @test start_app("src/test_examples.jl", dot_magic_dir="../examples", port=PORT, dev_mode=true) === nothing
    @test Magic.g.test_successfull
end

@testset "examples/02-todo.jl + 02-todo.js" begin
    @info """
    ------------------------------------------------------------------
    Test: examples/02-todo.jl + 02-todo.js
    ------------------------------------------------------------------------
    """
    ENV["MAGIC_TEST_PAGE"] = "02-todo.jl"
    ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "02-todo.js"
    ENV["MAGIC_TEST_CLIENTS"] = 8
    @test start_app("src/test_examples.jl", dot_magic_dir="../examples", port=PORT, dev_mode=true) === nothing
    @test Magic.g.test_successfull
end

@testset "examples/05-curves.jl + 05-curves.js" begin
    @info """
    ------------------------------------------------------------------
    Test: examples/05-curves.jl + 05-curves.js
    ------------------------------------------------------------------------
    """
    ENV["MAGIC_TEST_PAGE"] = "05-curves.jl"
    ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "05-curves.js"
    ENV["MAGIC_TEST_CLIENTS"] = 8
    @test start_app("src/test_examples.jl", dot_magic_dir="../examples", port=PORT, dev_mode=true) === nothing
    @test Magic.g.test_successfull
end

@testset "examples/07-probability.jl + 07-probability.js" begin
    @info """
    ------------------------------------------------------------------
    Test: examples/07-probability.jl + 07-probability.js
    ------------------------------------------------------------------------
    """
    ENV["MAGIC_TEST_PAGE"] = "07-probability.jl"
    ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "07-probability.js"
    ENV["MAGIC_TEST_CLIENTS"] = 6
    @test start_app("src/test_examples.jl", dot_magic_dir="../examples", port=PORT, dev_mode=true) === nothing
    @test Magic.g.test_successfull
end

@testset "examples/20-image-filters.jl 20-image-filters.js" begin
    @info """
    ------------------------------------------------------------------
    Test: examples/20-image-filters.jl 20-image-filters.js
    ------------------------------------------------------------------------
    """
    ENV["MAGIC_TEST_PAGE"] = "20-image-filters.jl"
    ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "20-image-filters.js"
    ENV["MAGIC_TEST_CLIENTS"] = 5
    @test start_app("src/test_examples.jl", dot_magic_dir="../examples", port=PORT, dev_mode=true) === nothing
    @test Magic.g.test_successfull
end

end
