
@testset "Examples dry run" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: Examples dry run
    ------------------------------------------------------------------------
    """
    @test @maybe_suppress start_app("../examples/app.jl", dot_magic_dir="../examples", port=PORT, dev_mode=true, init_and_quit=true) === nothing
end

@testset "End-to-end tests" begin
    @testset "examples/01-counter.jl + 01-counter.js" begin
        @maybe_suppress @info """
        ------------------------------------------------------------------
        Test: examples/01-counter.jl + 01-counter.js
        ------------------------------------------------------------------------
        """
        ENV["MAGIC_TEST_PAGE"] = "01-counter.jl"
        ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "01-counter.js"
        ENV["MAGIC_TEST_CLIENTS"] = 10
        @test @maybe_suppress start_app("src/test_examples.jl", dot_magic_dir="../examples", port=PORT, dev_mode=true) === nothing
        @test Magic.g.test_successfull
    end

    @testset "examples/02-todo.jl + 02-todo.js" begin
        @maybe_suppress @info """
        ------------------------------------------------------------------
        Test: examples/02-todo.jl + 02-todo.js
        ------------------------------------------------------------------------
        """
        ENV["MAGIC_TEST_PAGE"] = "02-todo.jl"
        ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "02-todo.js"
        ENV["MAGIC_TEST_CLIENTS"] = 8
        @test @maybe_suppress start_app("src/test_examples.jl", dot_magic_dir="../examples", port=PORT, dev_mode=true) === nothing
        @test Magic.g.test_successfull
    end

    @testset "examples/05-curves.jl + 05-curves.js" begin
        @maybe_suppress @info """
        ------------------------------------------------------------------
        Test: examples/05-curves.jl + 05-curves.js
        ------------------------------------------------------------------------
        """
        ENV["MAGIC_TEST_PAGE"] = "05-curves.jl"
        ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "05-curves.js"
        ENV["MAGIC_TEST_CLIENTS"] = 8
        @test @maybe_suppress start_app("src/test_examples.jl", dot_magic_dir="../examples", port=PORT, dev_mode=true) === nothing
        @test Magic.g.test_successfull
    end

    @testset "examples/07-probability.jl + 07-probability.js" begin
        @maybe_suppress @info """
        ------------------------------------------------------------------
        Test: examples/07-probability.jl + 07-probability.js
        ------------------------------------------------------------------------
        """
        ENV["MAGIC_TEST_PAGE"] = "07-probability.jl"
        ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "07-probability.js"
        ENV["MAGIC_TEST_CLIENTS"] = 6
        @test @maybe_suppress start_app("src/test_examples.jl", dot_magic_dir="../examples", port=PORT, dev_mode=true) === nothing
        @test Magic.g.test_successfull
    end

    @testset "examples/20-image-filters.jl 20-image-filters.js" begin
        @maybe_suppress @info """
        ------------------------------------------------------------------
        Test: examples/20-image-filters.jl 20-image-filters.js
        ------------------------------------------------------------------------
        """
        ENV["MAGIC_TEST_PAGE"] = "20-image-filters.jl"
        ENV["MAGIC_TEST_ACTIONS_SCRIPT"] = "20-image-filters.js"
        ENV["MAGIC_TEST_CLIENTS"] = 5
        @test @maybe_suppress start_app("src/test_examples.jl", dot_magic_dir="../examples", port=PORT, dev_mode=true) === nothing
        @test Magic.g.test_successfull
    end
end
