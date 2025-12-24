---
sidebar_position: 3
---

# radio

Display a radio button group widget.

### Function Signature

```julia
function radio(
    label          ::String,
    options        ::Vector;
    id             ::Any = nothing,
    initial_value  ::Any = nothing
)::Any
```

 Argument           | Description
------------------  | -----------
 `label`            | A `String` to be displayed as the label for the radio button group. It can contain HTML.
 `options`          | A `Vector` of selectable values. Each element represents one radio option and will be displayed using its string representation.
 `id`              | An optional identifier for the checkbox. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `initial_value`    | The value that should be initially selected. If provided, it should match one of the values in `options`. If `nothing`, its value will be set to the first option.

### Return Value

The currently selected value from `options`, or `nothing` if no option is selected.
