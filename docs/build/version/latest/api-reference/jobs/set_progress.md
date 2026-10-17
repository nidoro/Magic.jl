# set_progress

Reports the progress of the job it is called from.

Every call reruns the fragments bound to the job, so the interface can display the new progress. To avoid overloading the app, these reruns happen at most once every 0.4 seconds.

This is also how jobs are stopped: if a stop has been requested with `stop()`, `set_progress()` throws a `JobStopped` exception, which ends the job.

### Function Signature

```julia
function set_progress(
    progress    ::Real;
    message     ::Union{AbstractString, Nothing}    =nothing,
    data        ::Any                               =nothing
)::ProgressSnapshot

function set_progress(
    job         ::AsyncJob,
    progress    ::Real,
    message     ::Union{AbstractString, Nothing}    =nothing,
    data        ::Any                               =nothing
)::ProgressSnapshot
```

| Argument   | Description                                                                                                                                                                                     |
|:---------- |:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `job`      | The `AsyncJob` whose progress should be reported. If omitted, the job `set_progress()` is called from is used. Calling it outside a job without this argument throws an `IncorrectUsage` error. |
| `progress` | A `Real` between `0` and `1` specifying the progress of the job.                                                                                                                                |
| `message`  | An optional `String` describing the current progress. If `nothing` (default), the progress percentage is used (for example, `"42%"`).                                                           |
| `data`     | Optional data of `Any` type to be attached to the progress, which can be retrieved with `get_progress_data()`.                                                                                  |

### Return Value

The `ProgressSnapshot` created with the passed values.

### Example

```julia
@job("my_job") do
    files = readdir("data")
    for (i, file) in enumerate(files)
        process(file)
        set_progress(i/length(files), message="Processed $file")
    end
end
```
