# stop

Requests a job to stop.

Stopping is cooperative: the job actually stops the next time it calls `set_progress()`. A job that never calls `set_progress()` runs until it finishes. Once a stop is requested, `is_stopped()` returns `true`.

### Function Signature

```julia
function stop(job::Union{AsyncJob, String})::Nothing
```

| Argument | Description                                                                                                                                        |
|:-------- |:-------------------------------------------------------------------------------------------------------------------------------------------------- |
| `job`    | Either the `AsyncJob` returned by `@job` or a `String` with the job id. If no job with the passed id exists, an `InvalidArgument` error is thrown. |

### Return Value

Nothing.
