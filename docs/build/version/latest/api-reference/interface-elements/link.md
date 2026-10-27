# link

Display a link styled as a button.

### Function Signature

```julia
function link(
    label           ::String,
    url             ::String;
    style           ::String                    ="secondary",
    new_tab         ::Bool                      =false,
    icon            ::String                    ="",
    fill_width      ::Bool                      =false,
    font_weight     ::Union{String, Nothing}    =nothing,
    padding         ::Union{String, Nothing}    =nothing,
    justify_content ::Union{String, Nothing}    =nothing,
    background      ::Union{String, Nothing}    =nothing,
    hover_background::Union{String, Nothing}    =nothing,
    css             ::Dict                      =Dict()
)::Nothing
```

| Argument           | Description                                                                                                                                                                                                                                                                                             |
|:------------------ |:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `label`            | A `String` to be displayed as the link text. It can contain HTML.                                                                                                                                                                                                                                       |
| `url`              | A `String` specifying the destination URL of the link.                                                                                                                                                                                                                                                  |
| `style`            | A `String` defining the visual style of the link. Accepted values: `"primary"`, `"secondary"`, or `"naked"`. Default: `"secondary"`.                                                                                                                                                                    |
| `new_tab`          | A `Bool` indicating whether the link should open in a new browser tab. Default: `false`.                                                                                                                                                                                                                |
| `icon`             | A `String` in the format `material/icon_name`, displayed after the label. Example: `material/thumb_up`. If empty and `new_tab` is `true`, the `material/open_in_new` icon is used.<br/><br/>Check out [Material Icons](https://fonts.google.com/icons?icon.set=Material+Icons) to learn the icon names. |
| `fill_width`       | A `Bool` indicating whether the link should expand to fill the available horizontal space. Default: `false`.                                                                                                                                                                                            |
| `font_weight`      | An optional `String` specifying the font weight of the link label. Corresponds to the CSS `font-weight` property. Example values: `"normal"`, `"bold"`, `"600"`.                                                                                                                                        |
| `padding`          | An optional `String` specifying the inner spacing of the link. Corresponds to the CSS `padding` property. Example: `"0.5rem 1rem"`.                                                                                                                                                                     |
| `justify_content`  | An optional `String` controlling the horizontal alignment of the link content. Corresponds to the CSS `justify-content` property. Example values: `flex-start`, `center`, `space-between`.                                                                                                              |
| `background`       | An optional `String` specifying the background color of the link using a CSS color value. Overrides the color defined by `style`.                                                                                                                                                                       |
| `hover_background` | An optional `String` specifying the background color of the link when the mouse hovers over it, using a CSS color value. Overrides the color defined by `style`.                                                                                                                                        |
| `css`              | A `Dict` of CSS properties applied inline to the element.                                                                                                                                                                                                                                               |

### Return Value

Nothing.
