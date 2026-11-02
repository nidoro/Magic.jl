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
    allow_nothing   ::Bool                              =false,
    onchange        ::Function                          =()->(),
    args            ::Union{AbstractVector, Tuple}      =Vector()
)::Union{String, Number, Nothing}
```

| Argument        | Description                                                                                                                                                                                                                                                                                                                                                                                                                                          |
|:--------------- |:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `label`         | A `String` to be displayed as the label for the radio button group. It can contain HTML.                                                                                                                                                                                                                                                                                                                                                             |
| `options`       | An `AbstractVector` or `Tuple` of selectable values. Each element represents one radio option and will be displayed using its string representation.                                                                                                                                                                                                                                                                                                 |
| `id`            | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like [`get_value()`](/docs/version/latest/api-reference/interface-elements/get_value) and [`set_value()`](/docs/version/latest/api-reference/interface-elements/get_value#setvalue).                                                                                                                      |
| `show_label`    | A `Bool` indicating whether the label should be displayed. Default: `true`.                                                                                                                                                                                                                                                                                                                                                                          |
| `horizontal`    | A `Bool` indicating whether the radio options should be placed side by side (`true`) or stacked vertically (`false`). Default: `false`.                                                                                                                                                                                                                                                                                                              |
| `initial_value` | The value that should be initially selected. If provided, it should match one of the values in `options`. If `nothing` (default), the default value set with [`set_default_value()`](/docs/version/latest/api-reference/interface-elements/get_value#setdefaultvalue) will be selected if one was provided. Otherwise, no option will be selected if `allow_nothing` is `true`, and the first option in `options` will be selected if it is `false`. |
| `allow_nothing` | A `Bool` indicating whether the radio can have no option selected, in which case its value is `nothing`. If `true`, the user can click on the selected option to deselect it, and calling [`set_value()`](/docs/version/latest/api-reference/interface-elements/get_value#setvalue) with `nothing` deselects all options. If `false`, calling `set_value()` with `nothing` selects the first option in `options`. Default: `false`.                  |
| `onchange`      | A callback `Function`. This function is called when the selected value changes, before the app script is rerun.                                                                                                                                                                                                                                                                                                                                      |
| `args`          | A `Vector` or `Tuple` of arguments that will be passed to the `onchange` callback function.                                                                                                                                                                                                                                                                                                                                                          |

### Return Value

The currently selected value from `options`, or `nothing` if no option is selected (only possible when `allow_nothing` is `true`).
