---
sidebar_position: 4
---

# row

Insert a container that stacks its children horizontally.

See also [`column()`](/docs/build/docs/api-reference/layout-elements/column-func), which returns a container that stacks its children vertically.

### Function Signature

```julia
function row(
    inner_func      ::Function      =()->();
    fill_width      ::Bool          =false,
    fill_height     ::Bool          =false,
    align_items     ::String        ="flex-start",
    justify_content ::String        ="flex-start",
    gap             ::String        ="0.8rem",
    max_width       ::String        ="initial",
    max_height      ::String        ="none",
    show_border     ::Bool          =false,
    border          ::String        ="1px solid #d6d6d6",
    padding         ::String        ="none",
    margin          ::String        ="none",
    css             ::AbstractDict  =Dict(),
    attributes      ::AbstractDict  =Dict()
)::ContainerInterface
```

| Argument          | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
|:----------------- |:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `inner_func`      | An optional do-block `Function`, so you can define a row and its children like this: <pre>row() do<br/>  # children here<br/>end</pre> which is basically the same as: <pre>@push row()<br/># children here<br/>@pop</pre>In both cases, elements created inside the `do-end`/`push-pop` blocks will be placed inside the row returned by `row()`, with the difference that `push-pop` does not define a new scope, and thus variables created inside that block can be accessed after `@pop`. |
| `fill_width`      | A `Bool`. If `true`, the row expands to fill the available horizontal space.                                                                                                                                                                                                                                                                                                                                                                                                                   |
| `fill_height`     | A `Bool`. If `true`, the row expands to fill the available vertical space.                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `align_items`     | A `String` controlling vertical alignment of children. Corresponds to the CSS `align-items` property. Example values: `flex-start`, `center`, `flex-end`.                                                                                                                                                                                                                                                                                                                                      |
| `justify_content` | A `String` controlling horizontal alignment of children. Corresponds to the CSS `justify-content` property. Example values: `flex-start`, `center`, `space-between`.                                                                                                                                                                                                                                                                                                                           |
| `gap`             | A `String` specifying the spacing between child elements. Corresponds to the CSS `gap` property.                                                                                                                                                                                                                                                                                                                                                                                               |
| `max_width`       | A `String` specifying the maximum width of the column. Corresponds to the CSS `max-width` property.                                                                                                                                                                                                                                                                                                                                                                                            |
| `max_height`      | A `String` specifying the maximum height of the column. Corresponds to the CSS `max-height` property.                                                                                                                                                                                                                                                                                                                                                                                          |
| `show_border`     | A `Bool`. If `true`, a border is displayed around the column using the value of `border`.                                                                                                                                                                                                                                                                                                                                                                                                      |
| `border`          | A `String` defining the CSS border style used when `show_border` is `true`. Corresponds to the CSS `border` property.                                                                                                                                                                                                                                                                                                                                                                          |
| `padding`         | A `String` defining the CSS padding of the column. Corresponds to the CSS `padding` property.                                                                                                                                                                                                                                                                                                                                                                                                  |
| `margin`          | A `String` defining the CSS margin of the row. Corresponds to the CSS `margin` property.                                                                                                                                                                                                                                                                                                                                                                                                       |
| `css`             | A `Dict` of additional CSS properties to apply to the row.                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `attributes`      | A `Dict` of additional HTML attributes to attach to the column container.                                                                                                                                                                                                                                                                                                                                                                                                                      |

### Return Value

A `ContainerInterface` representing the container.

### Usage

Child elements can be inserted either by using the methods shown in the description of the `inner_func` argument or by calling element creation functions directly from the returned `ContainerInterface`. Example:

```julia
my_row = row()
my_row.button("Button inside my_row")
```

which is equivalent to:

```julia
my_row = row()
my_row() do
    button("Button inside my_row")
end
```
