# progress_bar

Displays a progress bar.

### Function Signatures

```julia
function progress_bar(
    progress    ::Real;
    message     ::Union{AbstractString, Nothing}=nothing,
    show_label  ::Bool                          =true,
    max_width   ::String                        ="100%"
)::Nothing

function progress_bar(
    progress    ::ProgressSnapshot,
    show_label  ::Bool      =true,
    max_width   ::String    ="100%"
)::Nothing

function progress_bar(
    job_id      ::String,
    show_label  ::Bool      =true,
    max_width   ::String    ="100%"
)::Nothing
```

| Argument     | Description                                                                                                                                                                               |
|:------------ |:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `progress`   | Either a `Real` between `0` and `1` specifying the progress to be displayed, or a `ProgressSnapshot`, as returned by `get_progress_snapshot()`, whose progress and message are displayed. |
| `job_id`     | A `String` with the id of a job created with `@job`. The current progress of the job is displayed. If the job does not exist, an empty progress bar is displayed.                         |
| `message`    | An optional `String` displayed above the bar. If `nothing` (default), the progress percentage is displayed (for example, `"42%"`).                                                        |
| `show_label` | A `Bool` indicating whether the message should be displayed above the bar. Default: `true`.                                                                                               |
| `max_width`  | A `String` specifying the maximum width of the progress bar using a CSS value. Default: `"100%"`.                                                                                         |

### Return Value

Nothing.

### Examples

```julia
progress_bar(0.42)
progress_bar(0.75, message="Loading data...")
```
