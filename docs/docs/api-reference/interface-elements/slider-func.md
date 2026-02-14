---
sidebar_position: 28
---

# slider

Display a slider widget.

> **NOTE:** Make sure that parameters `min`, `max`, `step` and `initial_value`
> all have the same Real subtype.

### Function Signature

```julia
function slider(
    label               ::String;
    initial_value       ::Union{T, Nothing}=nothing,
    min                 ::T=zero(T),
    max                 ::T=one(T),
    step                ::Union{T, Nothing}=nothing,
    precision           ::Integer=2,
    decimal_separator   ::String=".",
    thousands_separator ::String=",",
    show_label          ::Bool=true,
    fill_width          ::Bool=false,
    id                  ::Any=nothing,
    css                 ::Dict=Dict()
)::Union{Real, Nothing} where {T <: Real}
```

 Argument           | Description
------------------ | -----------
 `label`            | A `String` to be displayed as the label for the slider. It can contain HTML.
 `initial_value`    | Either a value of type `T` specifying the initial value of the slider, or `nothing` (default). If `nothing` is provided (default), the initial value will be the default value previously set with `set_default_value()` if any; otherwise, the widget will be initialized with `min`.
 `min`              | A value of type `T` specifying the minimum value of the slider range. Default: `zero(T)`.
 `max`              | A value of type `T` specifying the maximum value of the slider range. Default: `one(T)`.
 `step`             | Either a value of type `T` specifying the increment size for the slider, or `nothing` (default) to automatically determine the step size, in which case it will be set to `1` if `T` is an `Integer` subtype or `0.01` otherwise.
 `precision`        | An `Integer` specifying how many decimal places should be displayed for the slider value. Default: `2`.
 `decimal_separator`   | A `String` specifying the character that should be used as decimal separator. Default: `"."`.
 `thousands_separator` | A `String` specifying the character that should be used as thousands separator. Default: `","`.
 `show_label`       | A `Bool` indicating whether the label should be displayed. Default: `true`.
 `fill_width`       | A `Bool` indicating whether the slider should expand to fill the available horizontal space. Default: `false`.
 `id`               | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `css`              | A `Dict` of additional CSS properties applied to the slider element.

### Return Value

The current value of the slider as a `Real` number; or `nothing`.


