# top_bar

Retrieves the `ContainerInterface` of the page top bar created by `set_page_layout()`.

The top bar is disabled by default. In order to enable it, you must set its style by calling `set_page_layout()` with the `top_bar` argument. Example:

```julia
set_page_layout("centered", top_bar="fixed")
```

Calling `top_bar()` when the layout does not have a top bar throws an `ArgumentError`.

### Function Signature

```julia
function top_bar(inner_func::Function=()->())::ContainerInterface
```

| Argument     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|:------------ |:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `inner_func` | An optional do-block `Function`, so you can add content to the top bar like this: <pre>top_bar() do<br/>  # top bar content<br/>end</pre> which is essentially the same as: <pre>@push top_bar()<br/># top bar content<br/>@pop</pre>In both cases, elements created inside the `do-end`/`push-pop` blocks will be placed inside the container returned by `top_bar()`, with the difference that `push-pop` does not define a new scope, and thus variables created inside that block can be accessed after `@pop`. |

### Return Value

The `ContainerInterface` of the top bar.

### Example

```julia
set_page_layout("wide", top_bar="fixed")

top_bar() do
    row(fill_width=true, align_items="center") do
        link("Home", "/", style="naked")
        link("Examples", "/examples", style="naked")
        link("GitHub", "https://github.com/nidoro/Magic.jl", style="naked", new_tab=true)
    end
end
```
