# job_exists

Checks if a job with the given id exists in the current session.

### Function Signature

```julia
function job_exists(id::AbstractString)::Bool
```

| Argument | Description                        |
|:-------- |:---------------------------------- |
| `id`     | A `String` with the id of the job. |

### Return Value

`true` if a job with the passed `id` exists in the current session, `false` otherwise.
