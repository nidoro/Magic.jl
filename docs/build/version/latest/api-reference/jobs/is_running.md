# Job status functions

Family of `Bool` returning functions that check the status of a job created with `@job`:

  * `is_started()`: returns `true` if the job has started running.
  * `is_running()`: returns `true` if the job hasn't finished yet, including

when its task hasn't started yet.

  * `is_done()`: returns `true` if the job has finished without throwing an

error. A job that was stopped with `stop()` also counts as done.

  * `is_errored()`: returns `true` if the job threw an error.
  * `is_stopped()`: returns `true` if the job was stopped or if a stop was

requested with `stop()`.

### Function Signature

```julia
function is_started(job::Union{AsyncJob, AbstractString})::Bool
function is_running(job::Union{AsyncJob, AbstractString})::Bool
function is_done   (job::Union{AsyncJob, AbstractString})::Bool
function is_errored(job::Union{AsyncJob, AbstractString})::Bool
function is_stopped(job::Union{AsyncJob, AbstractString})::Bool
```

| Argument | Description                                                                                                                                |
|:-------- |:------------------------------------------------------------------------------------------------------------------------------------------ |
| `job`    | Either the `AsyncJob` returned by `@job` or a `String` with the job id. If no job with the passed id exists, all functions return `false`. |

### Example

```julia
if is_running("my_job")
    text("Working on it...")
elseif is_done("my_job")
    text(get_result("my_job"))
elseif is_errored("my_job")
    text("Something went wrong.")
end
```
