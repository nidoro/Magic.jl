# bind_fragment

Binds a fragment to a job, so the fragment is rerun every time the job reports progress with `set_progress()` and when the job finishes. A job can have many fragments bound to it.

### Function Signature

```julia
function bind_fragment(job::AsyncJob, fragment_id::String)::Nothing
function bind_fragment(job::AsyncJob, frag::Fragment)::Nothing
function bind_fragment(job_id::String, fragment_id::String)::Nothing
```

| Argument      | Description                                                                                      |
|:------------- |:------------------------------------------------------------------------------------------------ |
| `job`         | The `AsyncJob` returned by `@job`.                                                               |
| `job_id`      | A `String` with the job id. If no job with this id exists, an `InvalidArgument` error is thrown. |
| `fragment_id` | A `String` with the id of the fragment to be bound. Pass `""` to bind the entire app.            |
| `frag`        | A `Fragment`, as returned by `fragment()`.                                                       |

### Return Value

Nothing.

### Example

```julia
fragment("status") do
    text("Progress: $(get_progress_message("my_job"))")
end

if button("Start job")
    job = @job("my_job", on_progress="status") do
        # job code
    end
    bind_fragment(job, "other_fragment")
end
```
