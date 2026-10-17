# x_button

Special button to be used within a `dialog()`. Displays a close button (an "X" icon) in the top-right of the dialog. When clicked, the entire app is rerun, which closes the dialog unless the app calls `dialog()` again.

### Function Signature

```julia
function x_button()::Bool
```

### Return Value

`true` if the button was clicked, `false` otherwise.

### Example

```julia
if button("Open Dialog")
    dialog() do
        x_button()
        h2("Dialog")
        text("Click the X to close this dialog.")
    end
end
```
