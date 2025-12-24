---
sidebar_position: 7
---

# text_input

Display a text input widget.

### Function Signature

```julia
function text_input(
    label          ::String;
    id             ::Any      = nothing,
    show_label     ::Bool     = true,
    fill_width     ::Bool     = false,
    initial_value  ::String   = "",
    placeholder    ::String   = "",
    css            ::Dict     = Dict()
)::String
```

 Argument           | Description
------------------ | -----------
 `label`            | A `String` to be displayed as the label for the text input. It can contain HTML.
 `id`              | An optional identifier for the checkbox. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `show_label`       | A `Bool` indicating whether the label should be displayed. Default: `true`.
 `fill_width`       | A `Bool` indicating whether the text input should expand to fill the available horizontal space. Default: `false`.
 `initial_value`    | A `String` specifying the initial text value of the input. Default: an empty string.
 `placeholder`      | A `String` shown as placeholder text when the input is empty.
 `css`               | A `Dict` of additional CSS properties applied to the text input element.

### Return Value

The current value of the text input as a `String`.
