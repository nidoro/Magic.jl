using Magic

if button("Simple Job")
    job_id = repr(length(get_jobs())+1)
    @job(job_id) do
        sleep(2)
        return "job finished!"
    end
end

if button("Job with error")
    job_id = repr(length(get_jobs())+1)
    @job(job_id) do
        sleep(1)
        INVALID_FUNCTION()
        return nothing
    end
end

checkbox("Job 1 Stoped", id="cbx_1")
checkbox("Job 2 Finished", id="cbx_2")
checkbox("Job 2 Done", id="cbx_3")
checkbox("Job 3 Errored", id="cbx_4")

set_value("cbx_1",  is_stopped("1"))
set_value("cbx_2", !is_running("2"))
set_value("cbx_3",  is_done("2"))
set_value("cbx_4",  is_errored("3"))
