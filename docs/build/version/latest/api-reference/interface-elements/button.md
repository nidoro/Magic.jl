# button

Display a button widget.

### Function Signature

```julia
function button(
    label           ::String                    ="";
    style           ::String                    ="secondary",
    icon            ::String                    ="",
    fill_width      ::Bool                      =false,
    font_weight     ::Union{String, Nothing}    =nothing,
    padding         ::Union{String, Nothing}    =nothing,
    justify_content ::Union{String, Nothing}    =nothing,
    background      ::Union{String, Nothing}    =nothing,
    hover_background::Union{String, Nothing}    =nothing,
    onclick         ::Function                  =()->(),
    args            ::Union{Vector, Tuple}      =Vector(),
    css             ::Dict                      =Dict()
)::Bool
```

| Argument           | Description                                                                                                                                                                                  |
|:------------------ |:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `label`            | A `String` to be displayed inside the button. It can contain HTML.                                                                                                                           |
| `style`            | A `String` specifying the predefined style to be applied to the button. Possible values: `primary`, `secondary` (default), or `naked`.                                                       |
| `icon`             | A `String` in the format `material/icon_name`. Example: `material/thumb_up`.<br/><br/>Check out https://fonts.google.com/icons?icon.set=Material+Icons to learn the icon names.              |
| `fill_width`       | A `Bool` indicating whether the button should expand to fill the available horizontal space. Default: `false`.                                                                               |
| `font_weight`      | An optional `String` specifying the font weight of the button label. Corresponds to the CSS `font-weight` property. Example values: `"normal"`, `"bold"`, `"600"`.                           |
| `padding`          | An optional `String` specifying the inner spacing of the button. Corresponds to the CSS `padding` property. Example: `"0.5rem 1rem"`.                                                        |
| `justify_content`  | An optional `String` controlling the horizontal alignment of the button content. Corresponds to the CSS `justify-content` property. Example values: `flex-start`, `center`, `space-between`. |
| `background`       | An optional `String` specifying the background color of the button using a CSS color value. Overrides the color defined by `style`.                                                          |
| `hover_background` | An optional `String` specifying the background color of the button when the mouse hovers over it, using a CSS color value.                                                                   |
| `onclick`          | A callback `Function`. This function will be called when the button is clicked, before the app script is rerun.                                                                              |
| `args`             | A `Vector` or `Tuple` of arguments that will be passed to the `onclick` callback function.                                                                                                   |
| `css`              | A `Dict` of additional CSS properties applied to the button element.                                                                                                                         |

### Return Value

`true` if the button was clicked, `false` otherwise.
