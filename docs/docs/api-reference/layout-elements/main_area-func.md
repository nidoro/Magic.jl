---
sidebar_position: 27
---

# main_area

Retrieves the `Container` corresponding to the page main area created by
`set_page_layout()`.

See `set_page_layout()` for more information.

### Function Signature

```julia
function main_area(inner_func::Function=()->())::ContainerInterface
```

 Argument                              | Description
------------------------------------ |-------------
 `inner_func`                      | An optional do-block `Function`, so you can define the page main area and its children like this: <pre>main_area() do<br/>  # main area content<br/>end</pre> which is basically the same as: <pre>@push main_area()<br/># main area content<br/>@pop</pre>In both cases, elements created inside the `do-end`/`push-pop` blocks will be placed inside the container returned by `main_area()`, with the difference that `push-pop` does not define a new scope, and thus variables created inside that block can be accessed after `@pop`.

### Return Value

The `ContainerInterface` of the page's main area.

### Usage

This function is used to place elements inside the main container created by
`set_page_layout()`, but in most cases it is not needed because you can just
place the elements in the top-level of your script and they will be placed
inside the main container.

One use case for this function is if you are already inside a container and
wants to place elements in the main area without leaving said container context.
**This kind of program logic is not encouraged**, but is supported.

Example:

```julia
set_page_layout("centered")

left_sidebar() do
    # left sidebar content

    main_area() do
        # main area content
    end

    # more left sidebar content
end
```
