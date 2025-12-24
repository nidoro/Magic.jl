---
sidebar_position: 2
---

# checkbox

Display a checkbox widget.

### Function Signature

```julia
function checkbox(
    label         ::String;
    id            ::Any       = nothing,
    initial_value ::Bool      = false,
    onchange      ::Function  = (args...; kwargs...)->(),
    args          ::Vector    = Vector()
)::Bool
```

 Argument          | Description
------------------ | -----------
 `label`           | A `String` to be displayed next to the checkbox. It can contain HTML.
 `id`              | An optional identifier for the checkbox. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `initial_value`   | A `Bool` indicating whether the checkbox is initially checked. Default: `false`.
 `onchange`        | A callback `Function`. This function is called when the checkbox value changes, before the app script is rerun.
 `args`            | A `Vector` of arguments that will be passed to the `onchange` callback function.

### Return Value

The current value of the checkbox (`true` if checked, `false` otherwise).
