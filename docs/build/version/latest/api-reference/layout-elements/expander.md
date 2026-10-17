# expander

Inserts an expander: a container with a clickable label that expands or collapses its content.

### Function Signature

```julia
function expander(
    inner_func              ::Function,                 # optional
    label                   ::AbstractString;
    initial_state           ::AbstractString            ="closed",
    fill_width              ::Bool                      =false,
    show_border             ::Bool                      =false,
    gap                     ::String                    =".8rem",
    label_size              ::String                    ="1rem",
    label_color             ::Union{String, Nothing}    =nothing,
    label_weight            ::String                    ="normal",
    label_padding           ::String                    ="0",
    label_hover_background  ::Union{String, Nothing}    =nothing,
    label_css               ::Dict                      =Dict(),
)::ContainerInterface
```

| Argument                 | Description                                                                                                                                                                                                                          |
|:------------------------ |:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `inner_func`             | A do-block `Function` defining the content of the expander: <pre>expander("Click to Expand") do<br/>  # expander content<br/>end</pre>If omitted, the expander is created empty, and content can be added to the returned container. |
| `label`                  | A `String` displayed in the clickable label of the expander. It can contain HTML.                                                                                                                                                    |
| `initial_state`          | A `String` specifying the initial state of the expander: `"closed"` (default) or `"expanded"`.                                                                                                                                       |
| `fill_width`             | A `Bool` indicating whether the expander should expand to fill the available horizontal space. Default: `false`.                                                                                                                     |
| `show_border`            | A `Bool`. If `true`, a border is displayed around the expander. Default: `false`.                                                                                                                                                    |
| `gap`                    | A `String` specifying the spacing between the label and the content. Corresponds to the CSS `gap` property.                                                                                                                          |
| `label_size`             | A `String` specifying the font size of the label. Corresponds to the CSS `font-size` property.                                                                                                                                       |
| `label_color`            | An optional `String` specifying the color of the label using a CSS color value.                                                                                                                                                      |
| `label_weight`           | A `String` specifying the font weight of the label. Corresponds to the CSS `font-weight` property.                                                                                                                                   |
| `label_padding`          | A `String` specifying the inner spacing of the label. Corresponds to the CSS `padding` property.                                                                                                                                     |
| `label_hover_background` | An optional `String` specifying the background color of the label when the mouse hovers over it, using a CSS color value.                                                                                                            |
| `label_css`              | A `Dict` of additional CSS properties applied to the label.                                                                                                                                                                          |

### Return Value

The `ContainerInterface` holding the content of the expander.

### Example

```julia
expander("Click to Expand") do
    link("Github", "https://github.com/nidoro/Magic.jl")
    link("Examples", "https://github.com/nidoro/Magic.jl")
end
```
