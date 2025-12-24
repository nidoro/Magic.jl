---
sidebar_position: 5
---

# dataframe

Display a data table widget.

### Function Signature

```julia
function dataframe(
    data    ::Any;
    columns ::Dict   = Dict(),
    height  ::String = "400px"
)::Widget
```

 Argument     | Description
------------------ | -----------
 `data`      | The data to be displayed in the table. It must be compatible with the Julia Tables interface (i.e. implement the Tables.jl API), such as a `DataFrame`, a matrix, or any other Tables-compatible source.
 `columns`   | A `Dict` used to configure column behavior and appearance.
 `height`    | A `String` specifying the height of the table using a CSS value (for example, `"400px"`).

### Return Value

A `Widget` representing the rendered dataframe.
