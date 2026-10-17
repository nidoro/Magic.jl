# dataframe

Display a `DataFrame` from package [`DataFrames.jl`](https://dataframes.juliadata.org/stable/).

### Function Signature

```julia
function dataframe(
    data                ::DataFrame;
    column_config       ::Dict                      =Dict(),
    editable            ::Bool                      =false,
    fill_height         ::Bool                      =false,
    height              ::Union{String, Nothing}    =nothing,
    max_height          ::Union{String, Nothing}    =nothing,
    precision           ::Int                       =1,
    decimal_separator   ::String                    =".",
    thousands_separator ::String                    ="",
    id                  ::Union{String, Nothing}    =nothing,
    onchange            ::Function                  =()->(),
    args                ::Vector                    =Vector()
)::DataFrame
```

| Argument              | Description                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|:--------------------- |:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `data`                | A `DataFrame` to be displayed.                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `column_config`       | A `Dict` used to configure column behavior and appearance. Each entry of this `Dict` should be a column name paired with a `Dict` of configurations. These are the supported configuration options: <ul><li>`"editable"`: A `Bool`. If `true`, the cells of the column will be editable (double-click to edit). Default: `false`.</li><li>`"required"`: A `Bool` indicating wether a valid non-empty value is required. Default: `false`.</li></ul> |
| `editable`            | A `Bool`. If `true`, the cells of all columns will be editable (double-click to edit). Can be overridden per column through the `"editable"` option of `column_config`. Default: `false`.                                                                                                                                                                                                                                                           |
| `fill_height`         | A `Bool` indicating whether the table should expand to fill the available vertical space. Default: `false`.                                                                                                                                                                                                                                                                                                                                         |
| `height`              | An optional `String` specifying the height of the table using a CSS value (for example, `"400px"`). If `nothing` (default), the table grows to fit its content.                                                                                                                                                                                                                                                                                     |
| `max_height`          | An optional `String` specifying the maximum height of the table using a CSS value (for example, `"300px"`). If the content exceeds this height, the table becomes scrollable.                                                                                                                                                                                                                                                                       |
| `precision`           | An `Int` specifying how many decimal places should be displayed in floating point columns. Can be overridden per column through the `"precision"` option of `column_config`. Default: `1`.                                                                                                                                                                                                                                                          |
| `decimal_separator`   | A `String` specifying the character that should be used as decimal separator. Default: `"."`.                                                                                                                                                                                                                                                                                                                                                       |
| `thousands_separator` | A `String` specifying the character that should be used as thousands separator. Default: `""`.                                                                                                                                                                                                                                                                                                                                                      |
| `id`                  | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.                                                                                                                                                                                                                                                                    |
| `onchange`            | A callback `Function`. This function is called when any cell value changes, before the app script is rerun.                                                                                                                                                                                                                                                                                                                                         |
| `args`                | A `Vector` of arguments that should be passed to the `onchange` callback function.                                                                                                                                                                                                                                                                                                                                                                  |

### Return Value

The same `DataFrame` used as input (`data`).

### Example

The example below displays a `DataFrame` with two columns with different types and makes the column `Age` editable:

```julia
data = DataFrame(
    Name = String["Ana", "Bob", "Carl"],
    Age  = Number[21, 23, 33]
)

dataframe(
    data,
    column_config=Dict(
        "Age" => Dict("editable" => true)
    )
)
```
