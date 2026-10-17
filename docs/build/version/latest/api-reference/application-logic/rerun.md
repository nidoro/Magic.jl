# rerun

Requests a rerun of a fragment or of the entire app for the current session.

The request is asynchronous: `rerun()` returns immediately, and the rerun happens after the request is processed by the server.

### Function Signature

```julia
function rerun(fragment_id::String="")::Nothing
```

| Argument      | Description                                                                                               |
|:------------- |:--------------------------------------------------------------------------------------------------------- |
| `fragment_id` | A `String` with the id of the fragment that should be rerun. If empty (default), the entire app is rerun. |

### Return Value

Nothing.

### Example

```julia
fragment("counter") do
    count = coalesce(get_session_data("count"), 0)
    text("Count: $count")
    if button("Increment")
        set_session_data("count", count + 1)
        rerun("counter")
    end
end
```
