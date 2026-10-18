# stop

Requests a job to stop.

Stopping is cooperative: the job actually stops the next time it calls [`set_progress()`](/docs/version/latest/api-reference/jobs/set_progress). A job that never calls `set_progress()` runs until it finishes. Once a stop is requested, [`is_stopped()`](/docs/version/latest/api-reference/jobs/is_running) returns `true`.

### Function Signature

```julia
function stop(job::Union{AsyncJob, String})::Nothing
```

| Argument | Description                                                                                                                                                                                        |
|:-------- |:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `job`    | Either the `AsyncJob` returned by [`@job`](/docs/version/latest/api-reference/jobs/@job) or a `String` with the job id. If no job with the passed id exists, an `InvalidArgument` error is thrown. |

### Return Value

Nothing.
