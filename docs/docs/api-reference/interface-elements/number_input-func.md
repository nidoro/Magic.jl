---
sidebar_position: 27
---

# number_input

Display a number input widget.

### Function Signature

```julia
function number_input(
    label               ::String;
    initial_value       ::Union{Real, Nothing}=nothing,
    placeholder         ::Union{String, Nothing}=nothing,
    num_type            ::Type{<:Real}=Float64,
    precision           ::Integer=1,
    min                 ::Union{Real, Nothing}=nothing,
    max                 ::Union{Real, Nothing}=nothing,
    step                ::Real=1.0,
    decimal_separator   ::String=".",
    thousands_separator ::String=",",
    show_label          ::Bool=true,
    fill_width          ::Bool=false,
    id                  ::Any=nothing,
    css                 ::Dict=Dict()
)::Union{Real, Nothing}
```

 Argument           | Description
------------------ | -----------
 `label`            | A `String` to be displayed as the label for the text input. It can contain HTML.
 `initial_value`    | Either a `Real` specifying the initial value of the input, or `nothing` (default). If `nothing` is provided (default), the initial value will be the default value previously set with `set_default_value()` if any; otherwise, the widget will be initialized with value `nothing`.
 `placeholder`      | A `String` shown as placeholder when the widget's value is `nothing`. Default: `nothing`.
 `num_type`       | A subtype of `Real` indicating how the widget value should be interpreted and returned. Default: `Float64`.
 `precision`       | An `Integer` specifying how many decimal places should be displayed by the widget. If `num_type` is an `Integer`, this parameter is ignored.
 `min`       | A `Real` specifying the minimum value allowed in the widget, or `nothing` (default) indicating there is no minimum value.
 `max`       | A `Real` specifying the maximum value allowed in the widget, or `nothing` (default) indicating there is no maximum value.
 `step`       | A `Real` specifying the size of the increment/decrement applied when clicking the `-` and `+` buttons in the widget.
 `decimal_separator`       | A `String` specifying the character that should be used as decimal separator. Default: `"."`.
 `thousands_separator`       | A `String` specifying the character that should be used as decimal separator; Default: `"."`.
 `show_label`       | A `Bool` indicating whether the label should be displayed. Default: `true`.
 `fill_width`       | A `Bool` indicating whether the text input should expand to fill the available horizontal space. Default: `false`.
 `id`              | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `css`               | A `Dict` of additional CSS properties applied to the input element.

### Return Value

The current value of the number input interpreted as `num_type`; or `nothing`.
