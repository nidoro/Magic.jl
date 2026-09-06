
function (container_interface::ContainerInterface)(inner_func::Function)::Nothing
    push_container(container_interface)
    inner_func()
    pop_container()
    return nothing
end

function define_widget_func(interface, func_name)
    f = function(args...; kwargs...)
        push_container(interface)
        value = getfield(Magic, func_name)(args...; kwargs...)
        pop_container()
        return value
    end

    setfield!(interface, func_name, f)
end

function create_interface(container::Dict)::ContainerInterface
    interface = ContainerInterface()
    interface.container = container

    task = task_local_storage("app_task")
    widgets = task.session.widgets

    for func in CONTAINER_INTERFACE_FUNCS
        define_widget_func(interface, func)
    end

    return interface
end

function create_container(
    parent::Dict,
    css::Dict,
    attributes::Dict,
    fragment_id::String="",
    is_fragment_container::Bool=false
)::ContainerInterface

    container = Dict(
        "type" => "container",
        "children" => Vector{Dict{String, Any}}(),
        "id" => "$(parent["id"])/$(length(parent["children"]))",
        "css" => css,
        "attributes" => attributes,
        "is_fragment_container" => is_fragment_container,
        "fragment_id" => fragment_id,
    )

    push!(parent["children"], container)

    return create_interface(container)
end

"""
# container

Insert a generic container.

`container()` imposes minimal layout behavior by default. It can be styled
and customized using CSS properties and HTML attributes, and can be used as a
building block for more specialized layouts. `column()` and `row()` are
specializations of `container()`.

### Function Signature

```julia
function container(
    inner_func  ::Function =()->();
    css         ::Dict     =Dict(),
    attributes  ::Dict     =Dict()
)::ContainerInterface
```

 Argument        | Description
---------------- |-------------
 `inner_func`   | An optional do-block `Function`, so you can define a container and its children like this: <pre>container() do<br/>  # children here<br/>end</pre> which is basically the same as: <pre>@push container()<br/># children here<br/>@pop</pre>In both cases, elements created inside the `do-end`/`push-pop` blocks will be placed inside the container returned by `container()`, with the difference that `push-pop` does not define a new scope, and thus variables created inside that block can be accessed after `@pop`.
 `css`          | A `Dict` of CSS properties to apply to the container.
 `attributes`   | A `Dict` of additional HTML attributes to attach to the container.

### Return Value

A `ContainerInterface` representing the container.

### Usage

Child elements can be inserted
either by using the methods shown in the description of the `inner_func` argument
or by calling element creation functions directly from the returned
`ContainerInterface`. Example:

```julia
my_container = container()
my_container.button("Button inside my_container")
```

which is equivalent to:

```julia
my_container = container()
my_container() do
    button("Button inside my_container")
end
```
"""
function container(
    inner_func  ::Function      =()->();
    css         ::AbstractDict  =Dict(),
    attributes  ::AbstractDict  =Dict()
)::ContainerInterface

    # Input validation
    #--------------------
    assert_valid_css_or_attr_dict(@named(css))
    assert_valid_css_or_attr_dict(@named(attributes))

    css_norm = normalize_css_or_attr_dict(css)

    combined_css = Dict{String, Union{String, Real}}(
        "display" => "flex",
        "flex-direction" => "column",
        "align-items" => "flex-start",
        "justify-content" => "flex-start",
        "gap" => ".8rem",
    )

    merge!(combined_css, css_norm)
    i_container = create_container(top_container(), combined_css, attributes)

    push_container(i_container)
    inner_func()
    pop_container()
    return i_container
end

"""
# Push/Pop Container

## The `@push` and `@pop` macros

The `@push` and `@pop` macros are mechanisms through which you begin and end
blocks of container content. Every element created inside a `@push`/`@pop` block
will be placed inside the pushed container. Example:

```julia
button("Before column()")

@push column()
    # children of the column
    button("Inside column()")
@pop

button("After column()")
```

Containers can be nested. Example:

```julia
@push column()
    # children of the column
    button("Inside column()")

    @push row()
        button("Inside row()")
    @pop

    # more children of the column
    button("Also Inside column()")
@pop
```

> ⚠️ **IMPORTANT**: Make sure to pop any pushed container.

## `do-end` blocks

Another way to begin and end blocks of container content is by using `do-end`
blocks with a container. Example:

```julia
column() do
    button("Inside column()")
end
```

`do-end` blocks also work by pushing and poping the container to the container
stack, so you can also have nested `do-end` blocks. Example:

```julia
column() do
    button("Inside column()")
    row() do
        button("Inside row()")
    end
end
```

The most important difference between `do-end` blocks and `@push`/`@pop` blocks
is that a `do-end` block defines a new scope, so julia variables created inside
it will not be visible after the block ends.

## The `push_container()` function

Internally, the `@push` macro works by calling the functions `push_container()`
with the passed container.

### Function Signature

```julia
function push_container(container::ContainerInterface)::ContainerInterface
```

Argument  | Description
---------- |-------------
 `container` | A `ContainerInterface` to push to the top of the container stack.

### Return Value

The same container that was passed to it.

## The `pop_container()` function

Internally, the `@pop` macro works by calling the functions `pop_container()`
with the passed container.

### Function Signature

```julia
function pop_container()::ContainerInterface
```

### Return Value

The container on the top of the container stack.
"""
function push_container(i_container::ContainerInterface)::ContainerInterface
    task = task_local_storage("app_task")
    push!(task.container_stack, i_container)
    return i_container
end

@doc @doc(push_container) pop_container
function pop_container()::ContainerInterface
    task = task_local_storage("app_task")
    return pop!(task.container_stack)
end

function top_container()::Dict
    task = task_local_storage("app_task")
    return task.container_stack[end].container
end

macro push(container)
    :(Magic.push_container($(esc(container))))
end

macro pop()
    :(Magic.pop_container())
end

# Containers collection
#--------------------------
function (containers::Containers)(inner_func::Function, column_index::Int)
    push_container(containers.containers[column_index])
    inner_func()
    pop_container()
    return nothing
end

# Containers
#---------------
function get_css_value(element::Dict, property::String)
    if haskey(element, "css") && haskey(element["css"], property)
        return element["css"][property]
    else
        return missing
    end
end

function set_css_if_not_set(css::Dict, key::String, value::Union{String, Number})::Nothing
    if !haskey(css, key)
        css[key] = value
    end
    return nothing
end

function set_css_to_achieve_layout(css::Dict, parent::Dict, fill_width::Bool, fill_height::Bool)
    flex_grow = "0"
    min_width = nothing
    min_height = nothing
    width = nothing
    height = nothing

    if fill_width
        if get_css_value(parent, "flex-direction") == "row"
            flex_grow = "1"
            min_width = "0"
        else
            width = "100%"
        end
    end

    if fill_height
        if get_css_value(parent, "flex-direction") == "row"
            height = "100%"
        else
            flex_grow = "1"
            min_height = "0"
        end
    end

    css["flex-grow"] = flex_grow
    if min_width !== nothing css["min-width"] = min_width end
    if min_height !== nothing css["min-height"] = min_height end
    if width !== nothing css["width"] = width end
    if height !== nothing css["height"] = height end
end

"""
# column

Insert a container that stacks its children vertically.

See also [`row()`](/docs/build/docs/api-reference/layout-elements/row-func),
which returns a container that stacks its children horizontally.

### Function Signature

```julia
function column(
    inner_func      ::Function =()->();
    fill_width      ::Bool     =false,
    fill_height     ::Bool     =false,
    align_items     ::String   ="flex-start",
    justify_content ::String   ="flex-start",
    gap             ::String   =".8rem",
    max_width       ::String   ="100%",
    max_height      ::String   ="initial",
    show_border     ::Bool     =false,
    border          ::String   ="1px solid #d6d6d6",
    padding         ::String   ="none",
    margin          ::String   ="none",
    css             ::Dict     =Dict(),
    attributes      ::Dict     =Dict()
)::ContainerInterface
```

 Argument        | Description
---------------- |-------------
 `inner_func`        | An optional do-block `Function`, so you can define a column and its children like this: <pre>column() do<br/>  # children here<br/>end</pre> which is basically the same as: <pre>@push column()<br/># children here<br/>@pop</pre>In both cases, elements created inside the `do-end`/`push-pop` blocks will be placed inside the column returned by `column()`, with the difference that `push-pop` does not define a new scope, and thus variables created inside that block can be accessed after `@pop`.
 `fill_width`        | A `Bool`. If `true`, the column expands to fill the available horizontal space.
 `fill_height`       | A `Bool`. If `true`, the column expands to fill the available vertical space.
 `align_items`       | A `String` controlling horizontal alignment of children. Corresponds to the CSS `align-items` property. Example values: `flex-start`, `center`, `flex-end`.
 `justify_content`   | A `String` controlling vertical alignment of children. Corresponds to the CSS `justify-content` property. Example values: `flex-start`, `center`, `space-between`.
 `gap`               | A `String` specifying the spacing between child elements. Corresponds to the CSS `gap` property.
 `max_width`         | A `String` specifying the maximum width of the column. Corresponds to the CSS `max-width` property.
 `max_height`        | A `String` specifying the maximum height of the column. Corresponds to the CSS `max-height` property.
 `show_border`       | A `Bool`. If `true`, a border is displayed around the column using the value of `border`.
 `border`            | A `String` defining the CSS border style used when `show_border` is `true`. Corresponds to the CSS `border` property.
 `padding`           | A `String` defining the CSS padding of the column. Corresponds to the CSS `padding` property.
 `margin`            | A `String` defining the CSS margin of the column. Corresponds to the CSS `margin` property.
 `css`               | A `Dict` of additional CSS properties to apply to the column.
 `attributes`        | A `Dict` of additional HTML attributes to attach to the column container.

### Return Value

A `ContainerInterface` representing the container.

### Usage

Child elements can be inserted
either by using the methods shown in the description of the `inner_func` argument
or by calling element creation functions directly from the returned
`ContainerInterface`. Example:

```julia
my_col = column()
my_col.button("Button inside my_col")
```
which is equivalent to:
```julia
my_col = column()
my_col() do
    button("Button inside my_col")
end
```
"""
function column(
    inner_func      ::Function      =()->();
    fill_width      ::Bool          =false,
    fill_height     ::Bool          =false,
    align_items     ::String        ="flex-start",
    justify_content ::String        ="flex-start",
    gap             ::String        =".8rem",
    max_width       ::String        ="100%",
    max_height      ::String        ="initial",
    show_border     ::Bool          =false,
    border          ::String        ="1px solid #d6d6d6",
    padding         ::String        ="none",
    margin          ::String        ="none",
    css             ::AbstractDict  =Dict(),
    attributes      ::AbstractDict  =Dict()
)::ContainerInterface

    # Validate input
    #-------------------
    assert_valid_css_or_attr_dict(@named(css))
    assert_valid_css_or_attr_dict(@named(attributes))

    css_norm = normalize_css_or_attr_dict(css)

    combined_css = Dict{String, Union{String, Number}}(
        "gap" => gap,
        "align-items" => align_items,
        "justify-content" => justify_content,
        "max-width" => max_width,
        "border" => show_border ? border : "none",
        "border-radius" => "0.5rem",
        "padding" => padding,
        "margin" => margin,
        "min-width" => "0",
    )

    set_css_to_achieve_layout(combined_css, top_container(), fill_width, fill_height)
    set_css_if_not_set(css_norm, "max-height", max_height)
    merge!(combined_css, css_norm)

    return container(inner_func, css=combined_css, attributes=attributes)
end

"""
# row

Insert a container that stacks its children horizontally.

See also [`column()`](/docs/build/docs/api-reference/layout-elements/column-func),
which returns a container that stacks its children vertically.

### Function Signature

```julia
function row(
    inner_func         ::Function   =()->();
    fill_width         ::Bool       =false,
    fill_height        ::Bool       =false,
    align_items        ::String     ="flex-start",
    justify_content    ::String     ="flex-start",
    gap                ::String     ="0.8rem",
    margin             ::String     ="0",
    css                ::Dict       =Dict()
)::ContainerInterface
```

 Argument        | Description
---------------- |-------------
 `inner_func`        | An optional do-block `Function`, so you can define a row and its children like this: <pre>row() do<br/>  # children here<br/>end</pre> which is basically the same as: <pre>@push row()<br/># children here<br/>@pop</pre>In both cases, elements created inside the `do-end`/`push-pop` blocks will be placed inside the row returned by `row()`, with the difference that `push-pop` does not define a new scope, and thus variables created inside that block can be accessed after `@pop`.
 `fill_width`        | A `Bool`. If `true`, the row expands to fill the available horizontal space.
 `fill_height`       | A `Bool`. If `true`, the row expands to fill the available vertical space.
 `align_items`       | A `String` controlling vertical alignment of children. Corresponds to the CSS `align-items` property. Example values: `flex-start`, `center`, `flex-end`.
 `justify_content`   | A `String` controlling horizontal alignment of children. Corresponds to the CSS `justify-content` property. Example values: `flex-start`, `center`, `space-between`.
 `margin`            | A `String` defining the CSS margin of the row. Corresponds to the CSS `margin` property.
 `gap`               | A `String` specifying the spacing between child elements. Corresponds to the CSS `gap` property.
 `css`               | A `Dict` of additional CSS properties to apply to the row.

### Return Value

A `ContainerInterface` representing the container.

### Usage

Child elements can be inserted
either by using the methods shown in the description of the `inner_func` argument
or by calling element creation functions directly from the returned
`ContainerInterface`. Example:

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
"""
function row(
    inner_func      ::Function      =()->();
    fill_width      ::Bool          =false,
    fill_height     ::Bool          =false,
    align_items     ::String        ="flex-start",
    justify_content ::String        ="flex-start",
    gap             ::String        ="0.8rem",
    max_width       ::String        ="100%",
    max_height      ::String        ="initial",
    show_border     ::Bool          =false,
    border          ::String        ="1px solid #d6d6d6",
    padding         ::String        ="none",
    margin          ::String        ="none",
    css             ::AbstractDict  =Dict(),
    attributes      ::AbstractDict  =Dict()
)::ContainerInterface

    # Validate input
    #-------------------
    assert_valid_css_or_attr_dict(@named(css))
    assert_valid_css_or_attr_dict(@named(attributes))

    css_norm = normalize_css_or_attr_dict(css)

    combined_css = Dict{String, Union{String, Number}}(
        "flex-direction" => "row",
        "gap" => gap,
        "align-items" => align_items,
        "justify-content" => justify_content,
        "max-height" => max_height,
        "border" => show_border ? border : "none",
        "border-radius" => "0.5rem",
        "padding" => padding,
        "margin" => margin,
        "min-width" => "0",
    )

    set_css_to_achieve_layout(combined_css, top_container(), fill_width, fill_height)
    set_css_if_not_set(css_norm, "max-width", max_width)
    merge!(combined_css, css_norm)

    return container(inner_func, css=combined_css, attributes=attributes)
end

"""
# columns

Insert multiple column containers side by side.

This function is a convenience wrapper for creating a horizontal layout with
multiple columns at once. It returns a collection of containers that can be
used to insert child elements independently into each column.

### Function Signature

```julia
function columns(
    amount_or_widths ::Union{Int, Vector};
    kwargs...
)::Containers
```

 Argument              | Description
--------------------- |-------------
 `amount_or_widths` | Either an `Int`, specifying the number of equally sized columns to create, or a `Vector{Number}` specifying the width of each column relative to eachother.<br/><br/>For `Vector{Number}`, the width of a column is calculated based on the available space on the parent container and the proportion of its width relative to the sum of all relative widths. For instance, `columns([70,30])` will return two columns: the first one with width `70/100 = 0.7`, taking 70% of the available space, and the second with width `30/100 = 0.3`, taking 30% of the available space.
 `kwargs`              | Keyword arguments forwarded to each individual column container. These correspond to the keyword arguments accepted by `column()`, such as alignment, spacing, borders, CSS, and attributes.

### Return Value

A `Containers` object representing the created columns. Each element of the
returned collection is a `ContainerInterface` corresponding to one column.

### Usage

You can define `do-end` blocks for each column like this:

```julia
cols = columns(3)

cols(1) do
    button("Left")
end

cols(2) do
    button("Center")
end

cols(3) do
    button("Right")
end
```

Alternativelly, you can call element creation functions directly from the
returned columns like this:

```julia
cols = columns(3)
cols[1].button("Left")
cols[2].button("Center")
cols[3].button("Right")
```
"""
function columns(amount_or_widths::Union{Int, Vector}; kwargs...)::Containers
    columns = Containers()

    @push row(fill_width=true)
        if amount_or_widths isa Int
            w = 1.0/amount_or_widths
            css = Dict("flex" => "$w", "align-self" => "stretch")
            if haskey(kwargs, :css)
                merge!(css, kwargs[:css])
            end

            for c in 1:amount_or_widths
                col = column(css=css; kwargs...)
                push!(columns.containers, col)
            end
        else
            for w in amount_or_widths
                css = Dict("flex" => "$w", "align-self" => "stretch", "min-width" => "0")

                if haskey(kwargs, :css)
                    merge!(css, kwargs[:css])
                end

                col = column(css=css; kwargs...)
                push!(columns.containers, col)
            end
        end
    @pop

    return columns
end

function create_sidebar(
    initial_state::String,
    side::String,
    initial_width::String,
    position::String,
    labels::Tuple{Union{String, Nothing}, Union{String, Nothing}}
)::ContainerInterface

    state_class = initial_state == "open" ? "mg-show" : ""
    side_class = "mg-$(side)"
    position_class = position == "slide-out" ? "mg-slide-out" : "mg-overlay"

    open_label = "<mg-icon mg-icon='material/arrow_forward_ios'></mg-icon>"
    close_label = "<mg-icon mg-icon='material/arrow_back_ios'></mg-icon>"

    if side == "right"
        open_label, close_label = close_label, open_label
    end

    open_label  = labels[1] != nothing ? labels[1] : open_label
    close_label = labels[2] != nothing ? labels[2] : close_label

    sidebar_wrapper = column(
        fill_height=true,
        max_height="100vh",
        attributes=Dict("class" => "mg-sidebar $(side_class) $(state_class) $(position_class)", "data-mg-open-label" => open_label, "data-mg-close-label" => close_label),
        css=Dict("--sidebar-width" => initial_width)
    )
    sidebar_lining = sidebar_wrapper.column(fill_width=true, fill_height=true, attributes=Dict("class" => "mg-sidebar-lining"))
    sidebar_lining.html("dd-button", "", attributes=Dict("onclick" => "MG_ToggleSidebar(event)", "class" => "mg-sidebar-toggle-button"))
    sidebar = sidebar_lining.column(fill_width=true, fill_height=true, attributes=Dict("class" => "mg-sidebar-content"))
    return sidebar
end

"""
# set_page_layout

Configure the overall page layout.

This function defines the global layout of the page, including the main content
area and optional left and right sidebars. The containers corresponding to each
of these regions can be accessed via the API functions `main_area()`,
`left_sidebar()` and `right_sidebar()`, and they can be used like any other
function that returns a `ContainerInterface`. See usage example below.

### Function Signature

```julia
function set_page_layout(
    style                         ::String                 ="basic";
    max_width                     ::String                 ="600px",

    left_sidebar_initial_state    ::Union{Nothing, String} =nothing,
    left_sidebar_initial_width    ::String                 ="300px",
    left_sidebar_position         ::String                 ="slide-out",
    left_sidebar_toggle_labels    ::Tuple{Union{String, Nothing}, Union{String, Nothing}} =(nothing, nothing),

    right_sidebar_initial_state   ::Union{Nothing, String} =nothing,
    right_sidebar_initial_width   ::String                 ="300px",
    right_sidebar_position        ::String                 ="slide-out",
    right_sidebar_toggle_labels   ::Tuple{Union{String, Nothing}, Union{String, Nothing}} =(nothing, nothing),
)::Containers
```

 Argument                              | Description
------------------------------------ |-------------
 `style`                           | A `String` for selecting the overall layout style. The default `"basic"` style imposes minimal layout behaviour on the `main_area()` container. Possible values: `"basic"`, `"centered"`, `"wide"`.
 `max_width`                      | A `String` specifying the maximum width of the container returned by `main_area()`.
 `left_sidebar_initial_state`   | Either `nothing` or a `String` specifying the initial state of the left sidebar (`"open"` or `"closed"`). If `nothing`, the sidebar is disabled.
 `left_sidebar_initial_width`   | A `String` specifying the initial width of the left sidebar.
 `left_sidebar_position`         | A `String` specifying how the left sidebar is positioned relative to the main content (`"slide-out"` or `"overlay"`).
 `left_sidebar_toggle_labels`   | A `Tuple` of two optional `String` values defining the labels for opening and closing the left sidebar toggle button.
 `right_sidebar_initial_state`   | Either `nothing` or a `String` specifying the initial state of the right sidebar (`"open"` or `"closed"`). If `nothing`, the sidebar is disabled.
 `right_sidebar_initial_width`   | A `String` specifying the initial width of the right sidebar.
 `right_sidebar_position`         | A `String` specifying how the right sidebar is positioned relative to the main content (`"slide-out"` or `"overlay"`).
 `right_sidebar_toggle_labels`   | A `Tuple` of two optional `String` values defining the labels for opening and closing the right sidebar toggle button.

### Return Value

A `Containers` object representing the layout regions created by the page
layout.

### Usage

The `Container`s created by `set_page_layout()` can be accessed via the API
functions:

- `main_area()`
- `left_sidebar()`
- `right_sidebar()`

After calling `set_page_layout()` you can insert elements inside these regions
using the functions above. Example:

```julia
set_page_layout("centered", left_sidebar_initial_state="open")

main_area() do # Optional call to main_area()
    # main area content
end

left_sidebar() do
    # left sidebar content
end
```

> **TIP**: In general, you don't have to explicitly call `main_area()` to place
> elements into the main area. After calling `set_page_layout()`, any element
> created in the top-level of your app is placed inside `main_area()`.
"""
function set_page_layout(
    style                       ::String                    ="basic";
    max_width                   ::String                    ="600px",

    left_sidebar_initial_state  ::Union{Nothing, String}    =nothing,
    left_sidebar_initial_width  ::String                    ="300px",
    left_sidebar_position       ::String                    ="slide-out",
    left_sidebar_toggle_labels  ::Tuple{Union{String, Nothing}, Union{String, Nothing}}=(nothing, nothing),

    right_sidebar_initial_state ::Union{Nothing, String}    =nothing,
    right_sidebar_initial_width ::String                    ="300px",
    right_sidebar_position      ::String                    ="slide-out",
    right_sidebar_toggle_labels ::Tuple{Union{String, Nothing}, Union{String, Nothing}}=(nothing, nothing),
)::Containers

    # Input validation
    #---------------------
    assert_string_in_list(@named(style), ("basic", "centered", "wide"))::Nothing
    assert_string_in_list(@named(left_sidebar_position), ("slide-out", "overlay"))::Nothing
    assert_string_in_list(@named(right_sidebar_position), ("slide-out", "overlay"))::Nothing

    # Initialize sidebars
    #------------------------
    left_sidebar, right_sidebar = nothing, nothing

    @push row(fill_width=true, fill_height=true, gap="0px")
        if left_sidebar_initial_state != nothing
            left_sidebar = create_sidebar(left_sidebar_initial_state, "left", left_sidebar_initial_width, left_sidebar_position, left_sidebar_toggle_labels)
        end

        main_area = column(fill_width=true, fill_height=true)

        if right_sidebar_initial_state != nothing
            right_sidebar = create_sidebar(right_sidebar_initial_state, "right", right_sidebar_initial_width, right_sidebar_position, right_sidebar_toggle_labels)
        end
    @pop

    # Initialize main area
    #-------------------------
    if style == "basic"
        # Nothing to do
    elseif style == "centered"
        @push main_area
            @push column(fill_width=true, fill_height=true, align_items="center", padding="3rem 5px 5px 5px", css=Dict("overflow" => "auto"))
                main_area = column(fill_width=true, fill_height=true, align_items="center", max_width=max_width, css=Dict("align-items" => "center"))
            @pop
        @pop
    elseif style == "wide"
        @push main_area
            @push column(fill_width=true, fill_height=true, align_items="center", padding="3rem 0 0 0", css=Dict("overflow" => "auto"))
                main_area = column(fill_width=true, fill_height=true, css=Dict("padding" => "0 5%"))
            @pop
        @pop
    end

    push_container(main_area)
    # NOTE: here we don't pop the container, so main_area() is essentially the
    # new root container where top-level elements are placed.

    containers = Containers()
    containers.containers = [main_area, left_sidebar, right_sidebar]
    containers.main_area = main_area
    containers.left_sidebar = left_sidebar
    containers.right_sidebar = right_sidebar

    task = task_local_storage("app_task")
    task.layout = containers

    return containers
end

"""
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
"""
function main_area(inner_func::Function)::ContainerInterface
    task = task_local_storage("app_task")
    push_container(task.layout.main_area)
    inner_func()
    pop_container()
    return task.layout.main_area
end

"""
# Sidebars

Pair of functions to retrieve the left and right sidebar `ContainerInterface`s:

- `left_sidebar()`
- `right_sidebar()`

The sidebars are disabled by default. In order to enable them, you must set
their initial state by calling the function `set_page_layout()`. Example:

```julia
set_page_layout("centered", left_sidebar_initial_state="open")
```

### Function Signature

```julia
function left_sidebar (inner_func::Function=()->())::ContainerInterface
function right_sidebar(inner_func::Function=()->())::ContainerInterface
```

 Argument                              | Description
------------------------------------ |-------------
 `inner_func`                      | An optional do-block `Function`, so you can add content to the sidebar like this: <pre>left_sidebar() do<br/>  # sidebar content<br/>end</pre> which is basically the same as: <pre>@push left_sidebar()<br/># sidebar content<br/>@pop</pre>In both cases, elements created inside the `do-end`/`push-pop` blocks will be placed inside the container returned by `left_sidebar()` or `right_sidebar()`, with the difference that `push-pop` does not define a new scope, and thus variables created inside that block can be accessed after `@pop`.

### Return Value

The `ContainerInterface` of the sidebar.

### Usage

After setting the sidebar initial state using `set_page_layout()` you can insert
inside the sidebars using `left_sidebar()` or `right_sidebar()`. Example:

```julia
set_page_layout(
    "centered",
    left_sidebar_initial_state="open",
    right_sidebar_initial_state="closed"
)

left_sidebar() do
    # left sidebar content
end

right_sidebar() do
    # right sidebar content
end
```
"""
function left_sidebar(inner_func::Function)::ContainerInterface
    task = task_local_storage("app_task")
    if task.layout.left_sidebar == nothing
        throw(ArgumentError(
            "Your layout does not have a left sidebar. To create one,\n" *
            "first call `set_page_layout()` with the desired `left_sidebar` parameters."
        ))
    end
    push_container(task.layout.left_sidebar)
    inner_func()
    pop_container()
    return task.layout.left_sidebar
end

@doc @doc(left_sidebar) right_sidebar
function right_sidebar(inner_func::Function)::ContainerInterface
    task = task_local_storage("app_task")
    if task.layout.right_sidebar == nothing
        throw(ArgumentError(
            "Your layout does not have a left sidebar. To create one,\n" *
            "first call `set_page_layout()` with the desired `right_sidebar` parameters."
        ))
    end
    push_container(task.layout.right_sidebar)
    inner_func()
    pop_container()
    return task.layout.right_sidebar
end
