# dialog

Displays a dialog, that is, a popup window shown in front of everything.

The dialog stays open for as long as `dialog()` keeps being called on each rerun, which usually means as long as the user don't interact with a button that reruns the entire script, like `x_button()`.

Once a rerun no longer calls it, the dialog is closed. Only one dialog can be open at a time.

### Function Signature

```julia
function dialog(
    inner_func      ::Function                  =()->(),
    id              ::Union{String, Nothing}    =nothing;
    fragment_wrapper::Bool                      =true
)::Union{Fragment, Nothing}
```

| Argument           | Description                                                                                                                                                                                                                   |
|:------------------ |:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `inner_func`       | A do-block `Function` defining the content of the dialog: <pre>dialog() do<br/>  # dialog content<br/>end</pre>                                                                                                               |
| `id`               | An optional `String` used as the id of the fragment that wraps the dialog content. If `nothing` (default), an id is generated from the file and line where `inner_func` is defined. Ignored if `fragment_wrapper` is `false`. |
| `fragment_wrapper` | A `Bool`. If `true` (default), the dialog content is wrapped in a fragment (see `fragment()`), so interacting with widgets inside the dialog reruns only the dialog instead of the entire app.                                |

### Return Value

The `Fragment` wrapping the dialog content if `fragment_wrapper` is `true`, or `nothing` otherwise.

### Example

```julia
if button("Open Dialog")
    dialog() do
        x_button()
        h2("Dialog")
        text_input("Enter your name", fill_width=true, id="name")
        if button("Confirm", style="primary")
            rerun()
        end
    end
end
```

In the example above, clicking "Open Dialog" opens the dialog. Clicking on either "Confirm" or in the `X` close button in the top right created by `x_button` reruns the app, when then `button("Open Dialog")` will return `false`, so `dialog()` is not called and the dialog is closed.
