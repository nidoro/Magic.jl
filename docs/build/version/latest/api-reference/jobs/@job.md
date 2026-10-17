# @job

Runs a function asynchronously as a job, so that long running tasks don't block the app and proper progress visual feedback can be given.

The job is bound to the current session and starts running in a separate task right after the current rerun finishes. While the job runs, the app keeps responding to the user. Every time the job reports progress with `set_progress()`, and when it finishes, the fragments bound to it are rerun so the interface can be updated.

By default, a dialog displaying the job progress is shown while the job runs (see the `dialog` argument to disable it). The dialog is closed automatically when the job finishes and contains a close button that stops the job.

Job tasks can't modify the interface directly in any way, and trying to do so by calling element creating functions will result in an error. Instead, you communicate job progress by calling `set_progress` from within the job, which triggers a rerun of the fragments that are bound to it, and then you can update the interface accordingly. When the job is finished, it's return value can be accessed using `get_result`.

### Function Signature

```julia
@job(
    func            ::Function,
    id              ::Union{AbstractString, Nothing}    =nothing;
    dialog          ::Union{AbstractString, Nothing}    ="spinner",
    dialog_title    ::Union{String, Nothing}            =nothing,
    on_progress     ::Union{AbstractString, Nothing}    =nothing
)::AsyncJob
```

The function is usually passed as a do-block:

```julia
@job("my_job") do
    # job code
end
```

| Argument       | Description                                                                                                                                                                                                                                                                                                                                                           |
|:-------------- |:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `func`         | The `Function` to be run as a job. It takes no arguments, and its return value can be retrieved with `get_result()`.                                                                                                                                                                                                                                                  |
| `id`           | An optional `String` to uniquely identify the job within the session. If `nothing` (default), a random id is generated. If a job with the same id already exists, it is stopped (if running) and replaced.                                                                                                                                                            |
| `dialog`       | Either `nothing` or a `String` selecting the kind of progress dialog shown while the job runs: `"spinner"` (default) displays a spinner and the current progress message, and `"progress_bar"` displays a progress bar. If `nothing`, no dialog is shown and the entire app is rerun when the job reports progress or finishes. Ignored if `on_progress` is provided. |
| `dialog_title` | An optional `String` displayed as the title of the progress dialog. If `nothing` (default), `"Please wait"` is used.                                                                                                                                                                                                                                                  |
| `on_progress`  | An optional `String` with the id of a fragment to be rerun when the job reports progress or finishes. If provided, no progress dialog is shown. Pass `""` to rerun the entire app. More fragments can be bound to the job with `bind_fragment()`.                                                                                                                     |

### Return Value

The `AsyncJob` representing the job. Functions that take a job, such as `is_done()` or `get_result()`, accept either this object or the job `id`.

### Example

```julia
if button("Start job")
    @job("my_job", dialog="progress_bar") do
        count = 10
        for i in 1:count
            sleep(1)
            set_progress(i/count, message="Step $i of $count")
        end
        return "job finished!"
    end
end

if is_done("my_job")
    text(get_result("my_job"))
end
```

Most of Magic's functions, such as the ones that create interface elements, can't be called from inside a job. To communicate with the interface, use `set_progress()`.
