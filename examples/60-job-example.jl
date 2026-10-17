using Magic

if button("Simple job with spinner")
    job_id = repr(length(get_jobs())+1)
    @job(job_id) do
        sleep(2)
        return "job finished!"
    end
end

if button("Simple job with progress bar")
    job_id = repr(length(get_jobs())+1)
    @job(job_id, dialog="progress_bar") do
        count = 2
        for i in 1:count
            sleep(1)
            set_progress(Float64(i)/count)
        end
        return "job finished!"
    end
end

if button("Job with error")
    job_id = repr(length(get_jobs())+1)
    @job(job_id) do
        sleep(1)
        MISSING_FUNCTION()
        return nothing
    end
end

checkbox("Job 1 stopped", id="cbx_1")
checkbox("Job 2 not running and done", id="cbx_2")
checkbox("Job 3 errored", id="cbx_3")

set_value("cbx_1",  is_stopped("1"))
set_value("cbx_2", !is_running("2") && is_done("2"))
set_value("cbx_3",  is_errored("3"))
