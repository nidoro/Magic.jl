---
sidebar_position: 15
---

# checkboxes

Display a checkbox group widget.

### Function Signature

```julia
function checkboxes(
    label        ::String,
    options      ::Union{Vector, Tuple};
    id           ::Any                              =nothing,
    initial_value::Union{Vector, Tuple, Nothing}    =nothing,
    onchange     ::Function                         =()->(),
    args         ::Vector                           =Vector()
)::Union{Vector, Tuple}
```

 Argument          | Description
------------------ | -----------
 `label`           | A `String` to be displayed next to the checkbox. It can contain HTML.
 `options`         | A `Vector` or `Tuple` of selectable options. Each selectable option should be either a `String` or a `Real`, and will be displayed using its `String` representation.
 `id`              | An optional identifier for the checkbox. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `initial_value`   | Either a `Vector`/`Tuple` indicating which options in `options` should be initially checked, or `nothing`. If `nothing`, the default value set with `set_default_value()` will be used, if any; otherwise, the initial value will be an empty `Vector`.
 `onchange`        | A callback `Function`. This function is called when the checkbox value changes, before the app script is rerun.
 `args`            | A `Vector` of arguments that will be passed to the `onchange` callback function.

### Return Value

A `Vector`/`Tuple` indicating which options in `options` are checked.

### Example

See [Seattle Weather](https://magic.coisasdodavi.net/seattle-weather).
