---
sidebar_position: 28
---

# slider

Display a slider widget.

### Function Signature

```julia
function slider(
    label               ::String;
    initial_value       ::Union{Real, Nothing}          =nothing,
    min                 ::Real                          =0.0,
    max                 ::Real                          =1.0,
    step                ::Union{Real, Nothing}          =nothing,
    precision           ::Integer                       =2,
    num_type            ::Union{Type{<:Real}, Nothing}  =nothing,
    decimal_separator   ::String                        =".",
    thousands_separator ::String                        ="",
    show_label          ::Bool                          =true,
    fill_width          ::Bool                          =false,
    id                  ::Any                           =nothing,
    css                 ::Dict                          =Dict()
)::Real
```

 Argument           | Description
------------------ | -----------
 `label`            | A `String` to be displayed as the label for the slider. It can contain HTML.
 `initial_value`    | Either a `Real` specifying the initial value of the slider, or `nothing` (default). If `nothing`, the initial value will be the default value previously set with `set_default_value()` if any; otherwise, the widget will be initialized with the provided `min`.
 `min`              | A `Real` specifying the minimum value of the slider range. Default: `0.0`.
 `max`              | A `Real` specifying the maximum value of the slider range. Default: `1.0`.
 `step`       | A `Real` specifying the size of the increment/decrement when moving the slider, or `nothing` indicating that no fixed step is set, unless `num_type` turns out to be an `Integer`, in which case the step will be automatically set to `1`.
 `precision`        | An `Integer` specifying how many decimal places should be displayed for the slider value. Default: `2`.
 `num_type`       | A subtype of `Real` indicating the concrete type to which the widget parameters should be converted. If `nothing`, the concrete type is infered from the parameters of the widget, prioritizing `AbstractFloat` subtypes over `Integer`.
 `decimal_separator`   | A `String` specifying the character that should be used as decimal separator. Default: `"."`.
 `thousands_separator` | A `String` specifying the character that should be used as thousands separator. Default: `","`.
 `show_label`       | A `Bool` indicating whether the label should be displayed. Default: `true`.
 `fill_width`       | A `Bool` indicating whether the slider should expand to fill the available horizontal space. Default: `false`.
 `id`               | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `css`              | A `Dict` of additional CSS properties applied to the slider element.

### Return Value

The current `Real` value of the slider.

### Example

See [Sliding Curves](https://magic.coisasdodavi.net/curves).

