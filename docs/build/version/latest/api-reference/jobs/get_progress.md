# Job progress functions

Family of functions that retrieve the progress of a job created with `@job`, as reported by `set_progress()`:

  * `get_progress()`: returns the progress, a `Float64` between `0` and `1`.
  * `get_progress_message()`: returns the progress message.
  * `get_progress_data()`: returns the data attached to the progress.
  * `get_progress_snapshot()`: returns the whole `ProgressSnapshot`, with fields

`progress`, `message` and `data`.

During a rerun triggered by a progress report, these functions return the progress that triggered it, so all fragments display the same progress. Otherwise, they return the latest reported progress. Before any progress is reported, the progress is `0.0`, the message is a non-breaking space (`&nbsp;`) and the data is `nothing`.

### Function Signature

```julia
function get_progress         (job::Union{AsyncJob, String})::Float64
function get_progress_message (job::Union{AsyncJob, String})::String
function get_progress_data    (job::Union{AsyncJob, String})::Any
function get_progress_snapshot(job::Union{AsyncJob, String})::ProgressSnapshot
```

| Argument | Description                                                                                                                                        |
|:-------- |:-------------------------------------------------------------------------------------------------------------------------------------------------- |
| `job`    | Either the `AsyncJob` returned by `@job` or a `String` with the job id. If no job with the passed id exists, an `InvalidArgument` error is thrown. |

### Example

```julia
fragment("status") do
    if job_exists("my_job")
        progress_bar(get_progress("my_job"))
        text(get_progress_message("my_job"))
    end
end
```
