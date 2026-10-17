# get_current_page

Retrieves the `PageConfig` of the page associated with the current URL path.

### Function Signature

```julia
function get_current_page()::Union{PageConfig, Missing}
```

### Return Value

The `PageConfig` of the page registered with `add_page()` for the current URL path, or `missing` if no page is associated with it.
