---
sidebar_position: 5
---

# selectbox

Display a select box (dropdown) widget.

### Function Signature

```julia
function selectbox(
    label        ::String,
    options      ::Union{Vector, Tuple};
    initial_value::Union{String, Number, Vector, Tuple, Nothing}=nothing,
    id           ::Any                    =nothing,
    multiple     ::Bool                   =false,
    show_label   ::Bool                   =true,
    placeholder  ::Union{String, Nothing} =nothing,
    fill_width   ::Bool                   =false,
    onchange     ::Function               =()->(),
    args         ::Union{Vector, Tuple}   =Vector(),
    css          ::Dict                   =Dict()
)::Union{String, Number, Vector, Tuple, Nothing}
```

 Argument        | Description
------------------ | -----------
 `label`        | A `String` to be displayed as the label for the select box. It can contain HTML.
 `options`      | A `Vector` or `Tuple` of selectable options. Each selectable option should be either a `String` or a `Real`, and will be displayed using its `String` representation.
 `initial_value`| The value(s) that should be initially selected. If `multiple` is `false` (default), this should be a `String` or `Number` in `options`. Otherwise, the value should be a `Vector` or `Tuple` of `String`s or `Number`s in `options`.
 `id`           | An optional `String` identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `multiple`     | A `Bool` indicating whether multiple options can be selected. Default: `false`.
 `show_label`   | A `Bool` indicating whether the label should be displayed. Default: `true`.
 `placeholder`  | A `String` shown as placeholder text when the selectbox is empty.
 `fill_width`   | A `Bool` indicating whether the select box should expand to fill the available horizontal space. Default: `false`.
 `onchange`     | A callback `Function`. This function is called when the selected value changes, before the app script is rerun.
 `css`          | A `Dict` of additional CSS properties applied to the select box element.

### Return Value

The currently selected value(s). If `multiple` is `false`, this is either a `String`/`Real` value in `options` or `nothing`. If `multiple` is `true`, this is either a `Vector`/`Tuple` of selected values or `nothing`.

### Examples

See [Avatar Creator](https://magic.coisasdodavi.net/avatar) and
[Probability Viewer](https://magic.coisasdodavi.net/probability-density).

