
@testset "job related functions" begin
    @maybe_suppress @info """
    ------------------------------------------------------------------
    Test: job related functions
    ------------------------------------------------------------------------
    """

    @test_throws Magic.IncorrectUsage get_progress("")
    @test_throws Magic.IncorrectUsage get_result("")
    @test_throws Magic.IncorrectUsage job_exists("")
    @test_throws Magic.IncorrectUsage is_started("")
    @test_throws Magic.IncorrectUsage is_done("")
    @test_throws Magic.IncorrectUsage is_running("")
    @test_throws Magic.IncorrectUsage is_errored("")
    @test_throws Magic.IncorrectUsage stop("")

    @test_throws Magic.IncorrectUsage set_progress(0.5)
    @test_throws Magic.IncorrectUsage get_jobs()
end
