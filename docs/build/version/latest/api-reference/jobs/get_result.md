# get_result

Retrieves the value returned by the function of a job.

### Function Signature

```julia
function get_result(job::Union{AsyncJob, AbstractString})::Any
```

| Argument | Description                                                                                                             |
|:-------- |:----------------------------------------------------------------------------------------------------------------------- |
| `job`    | Either the `AsyncJob` returned by [`@job`](/docs/version/latest/api-reference/jobs/@job) or a `String` with the job id. |

### Return Value

The value returned by the job function, or `missing` if the job hasn't finished, threw an error, or no job with the passed id exists.
