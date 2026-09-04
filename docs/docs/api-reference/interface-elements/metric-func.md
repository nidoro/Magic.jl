---
sidebar_position: 60
---

# metric

Display a metric value with an optional delta indicator.

### Function Signature

```julia
function metric(
    label               ::String,
    value               ::Real,
    unit                ::String                    ="";
    delta               ::Union{Real, Nothing}      =nothing,
    delta_unit          ::Union{String, Nothing}    =nothing,
    higher_is_better    ::Bool                      =true,
    precision           ::Union{Int, Nothing}       =nothing,
    delta_precision     ::Union{Int, Nothing}       =nothing,
    decimal_separator   ::String                    =".",
    thousands_separator ::String                    =""
)::Nothing
```

 Argument               | Description
---------------------- | -----------
 `label`               | A `String` used as the label for the metric.
 `value`               | A `Real` representing the main value of the metric.
 `unit`               | An optional `String` representing the measurement unit of `value`. Examples: `ºC`, `m/s`.
 `delta`               | An optional `String` representing the change of the metric value.
 `delta_unit`               | An optional `String` representing the measurement unit of `delta`. If `nothing` (default), the same value of `unit` is used.
 `higher_is_better`    | A `Bool` indicating whether an increase in the metric value should be considered positive. Default: `true`.
 `precision`           | An optional `Integer` indicating with how many decimal places `value` should be displayed.
 `delta_precision`     | An optional `Integer` indicating with how many decimal places `delta` should be displayed. If `nothing` (default), the same value of `precision` is used.
 `decimal_separator`       | A `String` specifying the character that should be used as decimal separator. Default: `"."`.
 `thousands_separator`       | A `String` specifying the character that should be used as decimal separator. Default: `""`.

### Return Value

Nothing.

### Examples

See [Seattle Weather](https://magic.coisasdodavi.net/seattle-weather).
