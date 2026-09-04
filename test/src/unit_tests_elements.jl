
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
        # Test that it will fail when given empty options
        function ()
            selectbox("Select Box", [], initial_value=5)
        end,

        # Test that it will fail when options contains invalid elements
        function ()
            selectbox("Select Box", [1, 2, 3, nothing])
        end,

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
        # Test that it will fail when given empty options
        function ()
            selectbox("Select Box", [])
        end,

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

@testset "checkbox(...) input validation and initialization" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: checkbox(...) input validation and initialization
    ------------------------------------------------------------------------
    """

    # Tests that don't throw exceptions
    #--------------------------------------
    tests = [
        # Test that the value assigned at initialization is the returned value
        function ()
            val = checkbox("Checkbox", initial_value=true)
            Magic.g.test_successfull = val == true
        end,

        function ()
            val = checkbox("Checkbox", initial_value=false)
            Magic.g.test_successfull = val == false
        end,

        # Test that default_value will be used if initial_value is not provided
        function ()
            set_default_value("cbx", true)
            val = checkbox("Checkbox", id="cbx")
            Magic.g.test_successfull = val == true
        end,

        function ()
            set_default_value("cbx", false)
            val = checkbox("Checkbox", id="cbx")
            Magic.g.test_successfull = val == false
        end,

        # Test that set_value will work when given valid arguments
        function ()
            checkbox("Checkbox", id="cbx", initial_value=false)
            set_value("cbx", true)
            val = get_value("cbx")
            Magic.g.test_successfull = val == true
        end,

        function ()
            checkbox("Checkbox", id="cbx", initial_value=true)
            set_value("cbx", false)
            val = get_value("cbx")
            Magic.g.test_successfull = val == false
        end,

        # Test that set_value with nothing is equivalent to set_value with false
        function ()
            checkbox("Checkbox", initial_value=true, id="cbx")
            set_value("cbx", nothing)
            val = get_value("cbx")
            Magic.g.test_successfull = val == false
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
        # Test that it will fail when given a default_value that is not a Bool
        function ()
            set_default_value("cbx", 3.14)
            checkbox("Checkbox", id="cbx")
        end,

        # Test that set_value will fail when trying to assign a value that is not a Bool
        function ()
            checkbox("Checkbox", id="cbx")
            set_value("cbx", 3.14)
        end,

        # Test that it will fail when given an onclick callback that accepts a different number of arguments from length(args)
        function ()
            checkbox("Checkbox", onchange=(a::Int, b::Int)->(), args=[])
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test_throws Magic.InvalidArgument start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        end
    end
end

@testset "checkboxes(...) input validation and initialization" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: checkboxes(...) input validation and initialization
    ------------------------------------------------------------------------
    """

    # Tests that don't throw exceptions
    #--------------------------------------
    tests = [
        # Test that the value assigned at initialization is the returned value
        function ()
            val = checkboxes("Checkboxes", [1, 2, 3, "abc", 3.14], initial_value=("abc", 3.14))
            Magic.g.test_successfull = val == ("abc", 3.14)
        end,

        # Test that default_value will be used if initial_value is not provided
        function ()
            set_default_value("cbx", ("abc", 3.14))
            val = checkboxes("Checkboxes", (1, 2, 3, "abc", 3.14), id="cbx")
            Magic.g.test_successfull = val == ("abc", 3.14)
        end,

        # Test that set_value will work when given valid arguments
        function ()
            checkboxes("Checkboxes", (1, 2, 3, "abc", 3.14), id="cbx")
            set_value("cbx", ("abc", 3.14))
            val = get_value("cbx")
            Magic.g.test_successfull = val == ("abc", 3.14)
        end,

        # Test that set_value with empty list works
        function ()
            checkboxes("Checkboxes", (1, 2, 3, "abc", 3.14), id="cbx")
            set_value("cbx", [])
            val = get_value("cbx")
            Magic.g.test_successfull = isempty(val)
        end,

        # Test that set_value with nothing is equivalent to set_value with empty list
        function ()
            checkboxes("Checkboxes", (1, 2, 3, "abc", 3.14), id="cbx")
            set_value("cbx", nothing)
            val = get_value("cbx")
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
        # Test that it will fail when given empty options
        function ()
            checkboxes("Checkboxes", [])
        end,

        # Test that it will fail when options contains invalid elements
        function ()
            checkboxes("Checkboxes", [1, 2, 3, nothing])
        end,

        # Test that it will fail when given an initial_value that contains values that are not in options
        function ()
            checkboxes("Checkboxes", [1, 2, 3, "abc", 3.14], initial_value=[1, "invalid", 3.14])
        end,

        # Test that it will fail when given a default_value that contains values that are not in options
        function ()
            set_default_value("cbx", [1, "invalid", 3.14])
            checkboxes("Checkboxes", [1, 2, 3, "abc", 3.14], id="cbx")
        end,

        # Test that it will fail when given a default_value that is not a Vector or Tuple
        function ()
            set_default_value("cbx", 3.14)
            checkboxes("Checkboxes", [1, 2, 3, "abc", 3.14], id="cbx")
        end,

        # Test that set_value will fail when trying to assign a value that does not a Vector or Tuple
        function ()
            checkboxes("Checkboxes", [1, 2, 3, "abc", 3.14], id="cbx")
            set_value("cbx", 2)
        end,

        # Test that set_value will fail when trying to assign a value that does not exist in options
        function ()
            checkboxes("Checkboxes", [1, 2, 3, "abc", 3.14], id="cbx")
            set_value("cbx", [1, "invalid", 3.14])
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test_throws Magic.InvalidArgument start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        end
    end
end

@testset "radio(...) input validation and initialization" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: radio(...) input validation and initialization
    ------------------------------------------------------------------------
    """

    # Tests that don't throw exceptions
    #--------------------------------------
    tests = [
        # Test that the value assigned at initialization is the returned value
        function ()
            val = radio("Radio", [1, 2, 3, "abc", 3.14], initial_value=3.14)
            Magic.g.test_successfull = val == 3.14
        end,

        # Test that default_value will be used if initial_value is not provided
        function ()
            set_default_value("rad", 3.14)
            val = radio("Radio", (1, 2, 3, "abc", 3.14), id="rad")
            Magic.g.test_successfull = val == 3.14
        end,

        # Test that set_value will work when given valid arguments
        function ()
            radio("Radio", (1, 2, 3, "abc", 3.14), id="rad")
            set_value("rad", 3.14)
            val = get_value("rad")
            Magic.g.test_successfull = val == 3.14
        end,

        # Test that set_value with nothing will assign the first value of the list of options
        function ()
            radio("Radio", (1, 2, 3, "abc", 3.14), id="rad")
            set_value("rad", nothing)
            val = get_value("rad")
            Magic.g.test_successfull = val == 1
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
        # Test that it will fail when given empty options
        function ()
            radio("Radio", [])
        end,

        # Test that it will fail when options contains invalid elements
        function ()
            radio("Radio", [1, 2, 3, Dict()])
        end,

        # Test that it will fail when given an initial_value that contains values that are not in options
        function ()
            radio("Radio", [1, 2, 3, "abc", 3.14], initial_value="invalid")
        end,

        # Test that it will fail when given a default_value that contains values that are not in options
        function ()
            set_default_value("rad", "invalid")
            radio("Radio", [1, 2, 3, "abc", 3.14], id="rad")
        end,

        # Test that it will fail when given a default_value that is not a String or Number
        function ()
            set_default_value("rad", Dict())
            radio("Radio", [1, 2, 3, "abc", 3.14], id="rad")
        end,

        # Test that set_value will fail when trying to assign a value that is not a String or Number
        function ()
            radio("Radio", [1, 2, 3, "abc", 3.14], id="rad")
            set_value("rad", [])
        end,

        # Test that set_value will fail when trying to assign a value that does not exist in options
        function ()
            radio("Radio", [1, 2, 3, "abc", 3.14], id="rad")
            set_value("rad", "invalid")
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test_throws Magic.InvalidArgument start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        end
    end
end

@testset "text_input(...) input validation and initialization" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: text_input(...) input validation and initialization
    ------------------------------------------------------------------------
    """

    # Tests that don't throw exceptions
    #--------------------------------------
    tests = [
        # Test that the value assigned at initialization is the returned value
        function ()
            val = text_input("Text Input", initial_value="initial value")
            Magic.g.test_successfull = val == "initial value"
        end,

        # Test that default_value will be used if initial_value is not provided
        function ()
            set_default_value("txt", "default value")
            val = text_input("Text Input", id="txt")
            Magic.g.test_successfull = val == "default value"
        end,

        # Test that set_value will work when given valid arguments
        function ()
            text_input("Text Input", id="txt")
            set_value("txt", "set value")
            val = get_value("txt")
            Magic.g.test_successfull = val == "set value"
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
        # Test that it will fail when given a default_value that is not a String or Number
        function ()
            set_default_value("txt", Dict())
            text_input("Text Input", id="txt")
        end,

        # Test that set_value will fail when trying to assign a value that is not a String or Nothing
        function ()
            text_input("Text Input", id="txt")
            set_value("txt", [])
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test_throws Magic.InvalidArgument start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        end
    end
end

@testset "number_input(...) input validation and initialization" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: number_input(...) input validation and initialization
    ------------------------------------------------------------------------
    """

    # Tests that don't throw exceptions
    #--------------------------------------
    tests = [
        # Test that the value assigned at initialization is the returned value
        function ()
            val = number_input("Number Input", initial_value=3.14)
            Magic.g.test_successfull = val == 3.14
        end,

        # Test that default_value will be used if initial_value is not provided
        function ()
            set_default_value("num", 3.14)
            val = number_input("Number Input", id="num")
            Magic.g.test_successfull = val == 3.14
        end,

        # Test that set_value will work when given valid arguments
        function ()
            number_input("Number Input", id="num")
            set_value("num", 3.14)
            val = get_value("num")
            Magic.g.test_successfull = val == 3.14
        end,

        # Test that set_value will clamp if given a value outside the number_input range
        function ()
            number_input("Number Input", min=12, max=24, initial_value=15, id="num")
            set_value("num", 100)
            val = get_value("num")
            Magic.g.test_successfull = val == 24
        end,

        function ()
            number_input("Number Input", min=12, max=24, initial_value=15, id="num")
            set_value("num", 1)
            val = get_value("num")
            Magic.g.test_successfull = val == 12
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
        # Test that it will fail when given a default_value that is not a String or Number
        function ()
            set_default_value("num", Dict())
            number_input("Number Input", id="num")
        end,

        # Test that set_value will fail when trying to assign a value that is not a String or Nothing
        function ()
            number_input("Number Input", id="num")
            set_value("num", [])
        end,

        # Test that it will fail when given a range with min >= max
        function ()
            number_input("Number Input", min=20, max=10)
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test_throws Magic.InvalidArgument start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        end
    end
end

@testset "slider(...) input validation and initialization" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: slider(...) input validation and initialization
    ------------------------------------------------------------------------
    """

    # Tests that don't throw exceptions
    #--------------------------------------
    tests = [
        # Test that the value assigned at initialization is the returned value
        function ()
            val = slider("Slider", initial_value=0.67)
            Magic.g.test_successfull = val == 0.67
        end,

        # Test that default_value will be used if initial_value is not provided
        function ()
            set_default_value("sld", 0.67)
            val = slider("Slider", id="sld")
            Magic.g.test_successfull = val == 0.67
        end,

        # Test that set_value will work when given valid arguments
        function ()
            slider("Slider", id="sld")
            set_value("sld", 0.67)
            val = get_value("sld")
            Magic.g.test_successfull = val == 0.67
        end,

        # Test type inference when initial_value is provided
        function ()
            val = slider("Slider", initial_value=Float32(0.67))
            Magic.g.test_successfull = val isa Float32
        end,

        # Test type inference when default_value is provided
        function ()
            set_default_value("sld", Float32(0.67))
            val = slider("Slider", id="sld")
            Magic.g.test_successfull = val isa Float32
        end,

        # Test that the infered type is enforced on set_value
        function ()
            slider("Slider", initial_value=Float32(0.67), id="sld")
            set_value("sld", Int(1))
            val = get_value("sld")
            Magic.g.test_successfull = val isa Float32 && val == one(Float32)
        end,

        # Test that set_value with nothing sets to the slider min
        function ()
            slider("Slider", min=12, max=24, initial_value=15, id="sld")
            set_value("sld", nothing)
            val = get_value("sld")
            Magic.g.test_successfull = val == 12
        end,

        # Test that set_value will clamp if given a value outside the slider range
        function ()
            slider("Slider", min=12, max=24, initial_value=15, id="sld")
            set_value("sld", 100)
            val = get_value("sld")
            Magic.g.test_successfull = val == 24
        end,

        function ()
            slider("Slider", min=12, max=24, initial_value=15, id="sld")
            set_value("sld", 1)
            val = get_value("sld")
            Magic.g.test_successfull = val == 12
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
        # Test that it will fail when given a default_value that is not a Number
        function ()
            set_default_value("sld", Dict())
            slider("Slider", id="sld")
        end,

        # Test that set_value will fail when trying to assign a value that is not a Number or Nothing
        function ()
            slider("Slider", id="sld")
            set_value("sld", [])
        end,

        # Test that set_value will fail when trying to assign a value that is not a Number or Nothing
        function ()
            slider("Slider", id="sld")
            set_value("sld", [])
        end,

        # Test that it will fail when given a range with min >= max
        function ()
            slider("Slider", min=20, max=10)
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test_throws Magic.InvalidArgument start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        end
    end
end

@testset "file_uploader(...) input validation" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: file_uploader(...) input validation
    ------------------------------------------------------------------------
    """
    # Tests that throw InvalidArgument
    #-----------------------------------
    tests = [
        # Test that it will fail when given a negative max_file_size
        function ()
            file_uploader("File Uploader", max_file_size=-1)
        end,
        # Test that it will fail when given a max_file_size of zero
        function ()
            file_uploader("File Uploader", max_file_size=0)
        end,
        # Test that it will fail when given a negative max_files
        function ()
            file_uploader("File Uploader", max_files=-1, multiple=true)
        end,
        # Test that it will fail when given a max_files of zero
        function ()
            file_uploader("File Uploader", max_files=0, multiple=true)
        end,
        # Test that it will fail when given an empty string in types
        function ()
            file_uploader("File Uploader", types=[""])
        end,
        # Test that it will fail when given a malformed extension in types
        function ()
            file_uploader("File Uploader", types=["png"])  # missing leading dot
        end,
        # Test that it will fail when given a malformed mimetype in types
        function ()
            file_uploader("File Uploader", types=["image/"])
        end,
        # Test that it will fail when given a mimetype missing a subtype and slash
        function ()
            file_uploader("File Uploader", types=["image"])
        end,
        # Test that it will fail when one valid entry is mixed with one invalid entry
        function ()
            file_uploader("File Uploader", types=[".png", "NOT_VALID"])
        end,
    ]
    @maybe_suppress begin
        for test in tests
            @test_throws Magic.InvalidArgument start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        end
    end
end

@testset "download_button(...) input validation" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: download_button(...) input validation
    ------------------------------------------------------------------------
    """

    # Tests that throw InvalidArgument
    #-----------------------------------
    tests = [
        # Test that it will fail when given an empty file_path
        function ()
            download_button("Download", "")
        end,
        # Test that it will fail when given a file_path that doesn't exist
        function ()
            download_button("Download", "/nonexistent/path/to/file.txt")
        end,
        # Test that it will fail when given a file_path that points to a directory
        function ()
            download_button("Download", tempdir())
        end,
        # Test that it will fail when given an invalid file_name
        function ()
            valid_file = make_serveable_copy("../examples/.Magic/served-files/images/liberty.jpg")
            download_button("Download", valid_file; file_name="")
        end,
        function ()
            valid_file = make_serveable_copy("../examples/.Magic/served-files/images/liberty.jpg")
            download_button("Download", valid_file; file_name=".")
        end,
        # Test that it will fail when given an invalid style
        function ()
            valid_file = make_serveable_copy("../examples/.Magic/served-files/images/liberty.jpg")
            download_button("Download", valid_file; style="not_a_valid_style")
        end,
        function ()
            valid_file = make_serveable_copy("../examples/.Magic/served-files/images/liberty.jpg")
            download_button("Download", valid_file; style="")
        end,
        function ()
            valid_file = make_serveable_copy("../examples/.Magic/served-files/images/liberty.jpg")
            download_button("Download", valid_file; icon="download")
        end,
        # Test that it will fail when given an onclick callback that accepts a different number of arguments from length(args)
        function ()
            valid_file = make_serveable_copy("../examples/.Magic/served-files/images/liberty.jpg")
            download_button("Download", valid_file; onclick=()->(), args=(1,2,3))
        end,
    ]
    @maybe_suppress begin
        for test in tests
            @test_throws Magic.InvalidArgument start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        end
    end
end

@testset "link(...) input validation" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: link(...) input validation
    ------------------------------------------------------------------------
    """
    function test_style()   link("Link", "https://google.com", style="INVALID_STYLE") end

    @maybe_suppress begin
        @test_throws Magic.InvalidArgument start_app(test_style, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
    end
end

@testset "color_picker(...) input validation and initialization" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: color_picker(...) input validation and initialization
    ------------------------------------------------------------------------
    """

    # Tests that don't throw exceptions
    #--------------------------------------
    tests = [
        # Test that the value assigned at initialization is the returned value
        function ()
            val = color_picker("Color Picker", initial_value="abc")
            Magic.g.test_successfull = val == "#aabbcc"
        end,

        # Test that default_value will be used if initial_value is not provided
        function ()
            set_default_value("clr", "#aBc")
            val = color_picker("Color Picker", id="clr")
            Magic.g.test_successfull = val == "#aabbcc"
        end,

        # Test that set_value will work when given valid arguments
        function ()
            color_picker("Color Picker", id="clr")
            val = set_value("clr", "ABC")
            Magic.g.test_successfull = val == "#aabbcc"
        end,

        # Test that set_value will fallback to the default value if nothing is given
        function ()
            set_default_value("clr", "abc")
            color_picker("Color Picker", initial_value="cba", id="clr")
            val = set_value("clr", nothing)
            Magic.g.test_successfull = val == "#aabbcc"
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
        # Test that it will fail when given a default_value that is not a String
        function ()
            set_default_value("clr", Dict())
            color_picker("Color Picker", id="clr")
        end,

        # Test that it will fail when given a default_value that is not a valid hex color
        function ()
            set_default_value("clr", "aboba")
            color_picker("Color Picker", id="clr")
        end,

        # Test that set_value will fail when trying to assign a value that is not a String
        function ()
            color_picker("Color Picker", id="clr")
            set_value("clr", [])
        end,

        # Test that set_value will fail when trying to assign a value that is not a valid hex color
        function ()
            color_picker("Color Picker", id="clr")
            set_value("clr", "")
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test_throws Magic.InvalidArgument start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        end
    end
end

@testset "image(...) input validation and initialization" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: image(...) input validation and initialization
    ------------------------------------------------------------------------
    """

    # Tests that don't throw exceptions
    #--------------------------------------
    tests = [
        # Test that when given an image inside '.Magic/served-files', it will serve exactly that image.
        function ()
            val = image("$(get_dot_magic_path())/served-files/images/liberty.jpg")
            Magic.g.test_successfull = val == "/images/liberty.jpg"
        end,
        # Test that when given an image outside '.Magic/served-files', a serveable copy is created.
        function ()
            val = image("../examples/.Magic/served-files/images/liberty.jpg")
            path = "$(get_dot_magic_path())/served-files$(val)"
            Magic.g.test_successfull = isfile(path)
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true) == nothing
            @test Magic.g.test_successfull
        end
    end
end

@testset "h1(...), icon(...) input validation and initialization" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: h1(...), icon(...) input validation and initialization
    ------------------------------------------------------------------------
    """

    # Tests that throw exceptions
    #--------------------------------------
    tests = [
        # Test that it will fail if given an invalid icon
        function ()
            h1("H1", icon="INVALID_ICON")
        end,
        # Test that it will fail if given an invalid icon
        function ()
            icon("INVALID_ICON")
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test_throws Magic.InvalidArgument start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        end
    end
end

@testset "code(...) input validation and initialization" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: code(...) input validation and initialization
    ------------------------------------------------------------------------
    """

    # Tests that throw exceptions
    #--------------------------------------
    tests = [
        # Test that it will fail if given a path to something that is not a file
        function ()
            code(initial_value_file=".")
        end,
        # Test that it will fail if given a non-utf8 file
        function ()
            code(initial_value_file="../examples/.Magic/served-files/images/liberty.jpg")
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test_throws Magic.InvalidArgument start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        end
    end
end
