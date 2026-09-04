@testset "set_page_layout(...) input validation and initialization" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: set_page_layout(...) input validation and initialization
    ------------------------------------------------------------------------
    """

    # Tests that don't throw exceptions
    #--------------------------------------
    tests = [
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
        # Test that it will fail when given invalid style
        function ()
            set_page_layout("INVALID_STYLE")
        end,
        # Test that it will fail when given invalid left_side_bar_position
        function ()
            set_page_layout("wide", left_sidebar_position="INVALID_POSITION")
        end,
        # Test that it will fail when given invalid right_side_bar_position
        function ()
            set_page_layout("wide", right_sidebar_position="INVALID_POSITION")
        end,
    ]

    @maybe_suppress begin
        for test in tests
            @test_throws Magic.InvalidArgument start_app(test, port=PORT, dev_mode=true, init_and_quit=true, rethrow_rerun_exceptions=true)
        end
    end
end
