# get_changes

Retrieves the cell edits made by the user on a uniquely identified `dataframe()` widget.

### Function Signature

```julia
function get_changes(id::String)::Union{Dict{Int, Dict{String, Any}}, Missing}
```

| Argument | Description                                         |
|:-------- |:--------------------------------------------------- |
| `id`     | User-defined widget id, as passed to `dataframe()`. |

### Return Value

If no widget with the passed id exists, returns `missing`.

Otherwise, returns a `Dict` mapping each edited row index in the current rerun to a `Dict` that maps each edited column name in that row to its new value.

### Example

```julia
function change_callback()
    changes = get_changes("my_df")
    for (row, cols) in changes
        for (col, value) in cols
            println("Row $row, column $col: $value")
        end
    end
end

dataframe(df, editable=true, id="my_df", onchange=change_callback)
```
