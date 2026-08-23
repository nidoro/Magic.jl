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
const SUPPRESS_OUTPUT = true

macro maybe_suppress(ex)
    quote
        if SUPPRESS_OUTPUT
            redirect_stdout(devnull) do
                redirect_stderr(devnull) do
                    $(esc(ex))
                end
            end
        else
            $(esc(ex))
        end
    end
end

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
end

@testset "Function as entry point" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: Function as entry point
    ------------------------------------------------------------------------
    """
    function test_app()
        button("Ok!")
    end

    @maybe_suppress begin
        @test start_app(test_app, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true) === nothing
    end
end

@testset "button(...) input validation" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: button(...) input validation
    ------------------------------------------------------------------------
    """
    function test_style()   button("Button", style="INVALID_STYLE") end
    function test_icon()    button("Button", icon="INVALID_ICON") end
    function test_onclick() button("Button", onclick=()->(), args=(1,2,3)) end

    @maybe_suppress begin
        @test_throws Magic.InvalidArgument start_app(test_style, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        @test_throws Magic.InvalidArgument start_app(test_icon, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        @test_throws Magic.InvalidArgument start_app(test_onclick, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
    end
end

@testset "simple selectbox(...) input validation and initialization" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: simple selectbox(...) input validation and initialization
    ------------------------------------------------------------------------
    """

    # Tests that don't throw exceptions
    #--------------------------------------
    tests = [
        # Test that the type of the value assigned at initialization matches the value of its corresponding option
        function ()
            val = selectbox("Select Box", [1, 2, 3, "abc", 3.14], initial_value=3)
            Magic.g.test_successfull = val == 3 && typeof(val) == typeof(3)
        end,

        function ()
            val = selectbox("Select Box", [1, 2, 3, "abc", 3.14], initial_value=3.14)
            Magic.g.test_successfull = val == 3.14 && typeof(val) == typeof(3.14)
        end,

        # Test that set_value will work when given valid arguments
        function ()
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], id="slc")
            set_value("slc", 3.14)
            val = get_value("slc")
            Magic.g.test_successfull = val == 3.14 && typeof(val) == typeof(3.14)
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true) == nothing
            @test Magic.g.test_successfull
        end
    end

    # Tests that throw InvalidArgument
    #-----------------------------------
    tests = [
        # Test that it will fail when given an initial_value that is not in options
        function ()
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], initial_value=5)
        end,

        # Test that it will fail when given an initial_value that is not a String or Number
        function ()
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], initial_value=[1])
        end,

        # Test that it will fail when given a default_value that it is not in options
        function ()
            set_default_value("slc", 5)
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], id="slc")
        end,

        # Test that it will fail when given a default_value that it is not a String or Number
        function ()
            set_default_value("slc", [1])
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], id="slc")
        end,

        # Test that set_value will fail when trying to assign a value that does not a String or Number
        function ()
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], id="slc")
            set_value("slc", [])
        end,

        # Test that set_value will fail when trying to assign a value that does not exist in options
        function ()
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], id="slc")
            set_value("slc", "invalid")
        end,

        # Test that it will fail when given an onclick callback that accepts a different number of arguments from length(args)
        function ()
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], onchange=()->(), args=[1,2,3])
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test_throws Magic.InvalidArgument start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        end
    end
end

@testset "multiselect selectbox(...) input validation and initialization" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: multiselect selectbox(...) input validation and initialization
    ------------------------------------------------------------------------
    """

    # Tests that don't throw exceptions
    #--------------------------------------
    tests = [
        # Test that the type of the value assigned at initialization matches the value of its corresponding option
        function ()
            val = selectbox("Select Box", [1, 2, 3, "abc", 3.14], multiple=true, initial_value=[2, "abc"])
            Magic.g.test_successfull = Tuple(typeof.(val)) == (typeof(2), String)
        end,

        function ()
            val = selectbox("Select Box", [1, 2, 3, "abc", 3.14], multiple=true, initial_value=(1, 3.14))
            Magic.g.test_successfull = Tuple(typeof.(val)) == (typeof(1), typeof(3.14))
        end,

        # Test that set_value will work when given valid arguments
        function ()
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], multiple=true, id="slc")
            set_value("slc", [3.14, "abc"])
            val = get_value("slc")
            Magic.g.test_successfull = Tuple(typeof.(val)) == (typeof(3.14), String)
        end,

        # Test that set_value will work when given empty list as argument
        function ()
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], multiple=true, id="slc")
            set_value("slc", [])
            val = get_value("slc")
            Magic.g.test_successfull = isempty(val)
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true) == nothing
            @test Magic.g.test_successfull
        end
    end

    # Tests that throw InvalidArgument
    #-----------------------------------
    tests = [
        # Test that it will fail when given an initial_value that contains values that are not in options
        function ()
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], multiple=true, initial_value=[1, "invalid", 3.14])
        end,

        # Test that it will fail when given an initial_value that contains values that is not a Vector or Tuple
        function ()
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], multiple=true, initial_value=1)
        end,

        # Test that it will fail when given a default_value that contains values that are not in options
        function ()
            set_default_value("slc", [1, "invalid", 3.14])
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], multiple=true, id="slc")
        end,

        # Test that it will fail when given a default_value that is not a Vector or Tuple
        function ()
            set_default_value("slc", 3.14)
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], multiple=true, id="slc")
        end,

        # Test that set_value will fail when trying to assign a value that does not a Vector or Tuple
        function ()
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], multiple=true, id="slc")
            set_value("slc", 2)
        end,

        # Test that set_value will fail when trying to assign a value that does not exist in options
        function ()
            selectbox("Select Box", [1, 2, 3, "abc", 3.14], multiple=true, id="slc")
            set_value("slc", [1, "invalid", 3.14])
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test_throws Magic.InvalidArgument start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        end
    end
end

@testset "Examples dry run" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: Examples dry run
    ------------------------------------------------------------------------
    """
    @test @maybe_suppress start_app("../examples/app.jl", dot_magic_dir="../examples", port=PORT, dev_mode=true, init_and_quit=true) === nothing
end

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
