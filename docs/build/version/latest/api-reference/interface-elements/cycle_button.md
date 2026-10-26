# cycle_button

Display a button that cycles through a list of options. Each click selects the next option, going back to the first one after the last.

### Function Signature

```julia
function cycle_button(
    options         ::Union{AbstractVector, Tuple};
    labels          ::Union{AbstractVector, Tuple, Nothing} =nothing,
    id              ::Union{AbstractString, Nothing}        =nothing,
    initial_value   ::Union{AbstractString, Nothing}        =nothing,
    style           ::AbstractString                        ="secondary",
    fill_width      ::Bool                                  =false,
    onchange        ::Function                              =()->(),
    args            ::Union{AbstractVector, Tuple}          =[],
    css             ::AbstractDict                          =Dict(),
)::String
```

| Argument        | Description                                                                                                                                                                                                                                                                                                                                                            |
|:--------------- |:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `options`       | An `AbstractVector` or `Tuple` of `String`s. These are the possible values of the widget, in the order they are cycled through.                                                                                                                                                                                                                                        |
| `labels`        | An optional `AbstractVector` or `Tuple` of `String`s, with the same length as `options`, specifying what is displayed inside the button for each option. Labels can contain HTML. If `nothing` (default), the options themselves are displayed.                                                                                                                        |
| `id`            | An optional `String` identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like [`get_value()`](/docs/version/latest/api-reference/interface-elements/get_value) and [`set_value()`](/docs/version/latest/api-reference/interface-elements/get_value#setvalue).                               |
| `initial_value` | The value that should be initially selected. If provided, it should match one of the values in `options`. If `nothing` (default), the default value set with [`set_default_value()`](/docs/version/latest/api-reference/interface-elements/get_value#setdefaultvalue) will be selected if one was provided. Otherwise, the first option in `options` will be selected. |
| `style`         | A `String` specifying the predefined style to be applied to the button. Possible values: `primary`, `secondary` (default), or `naked`.                                                                                                                                                                                                                                 |
| `fill_width`    | A `Bool` indicating whether the button should expand to fill the available horizontal space. Default: `false`.                                                                                                                                                                                                                                                         |
| `onchange`      | A callback `Function`. This function is called when the value changes, before the app script is rerun.                                                                                                                                                                                                                                                                 |
| `args`          | A `Vector` or `Tuple` of arguments that will be passed to the `onchange` callback function.                                                                                                                                                                                                                                                                            |
| `css`           | A `Dict` of additional CSS properties applied to the button element.                                                                                                                                                                                                                                                                                                   |

### Return Value

The currently selected value from `options`.

### Example

```julia
using Magic

mode = cycle_button(["light", "dark"], labels=["☀️ Light", "🌙 Dark"])
text("Current mode: $(mode)")
```
