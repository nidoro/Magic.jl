# radio

Display a radio button group widget.

### Function Signature

```julia
function radio(
    label           ::String,
    options         ::Union{AbstractVector, Tuple};
    id              ::Any                               =nothing,
    show_label      ::Bool                              =true,
    horizontal      ::Bool                              =false,
    initial_value   ::Union{String, Number, Nothing}    =nothing,
    onchange        ::Function                          =()->(),
    args            ::Union{AbstractVector, Tuple}      =Vector()
)::Union{String, Number}
```

| Argument        | Description                                                                                                                                                                                                                                                                                                                                                        |
|:--------------- |:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `label`         | A `String` to be displayed as the label for the radio button group. It can contain HTML.                                                                                                                                                                                                                                                                           |
| `options`       | An `AbstractVector` or `Tuple` of selectable values. Each element represents one radio option and will be displayed using its string representation.                                                                                                                                                                                                               |
| `id`            | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like [`get_value()`](/docs/version/latest/api-reference/interface-elements/get_value) and [`set_value()`](/docs/version/latest/api-reference/interface-elements/get_value#setvalue).                                    |
| `show_label`    | A `Bool` indicating whether the label should be displayed. Default: `true`.                                                                                                                                                                                                                                                                                        |
| `horizontal`    | A `Bool` indicating whether the radio options should be placed side by side (`true`) or stacked vertically (`false`). Default: `false`.                                                                                                                                                                                                                            |
| `initial_value` | The value that should be initially selected. If provided, it should match one of the values in `options`. If `nothing` (default), the default value set with [`set_default_value()`](/docs/version/latest/api-reference/interface-elements/get_value#setdefaultvalue) will be selected if one was provided. Otherwise, first option in `options` will be selected. |
| `onchange`      | A callback `Function`. This function is called when the selected value changes, before the app script is rerun.                                                                                                                                                                                                                                                    |
| `args`          | A `Vector` or `Tuple` of arguments that will be passed to the `onchange` callback function.                                                                                                                                                                                                                                                                        |

### Return Value

The currently selected value from `options`.
