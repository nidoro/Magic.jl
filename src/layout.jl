
# ContainerInterface
#------------------------
@with_kw mutable struct ContainerInterface
    container       ::Union{Dict, Nothing} = nothing

    columns         ::Function = (args...; kwargs...)->()
    column          ::Function = (args...; kwargs...)->()
    row             ::Function = (args...; kwargs...)->()
    button          ::Function = (args...; kwargs...)->()
    download_button ::Function = (args...; kwargs...)->()
    image           ::Function = (args...; kwargs...)->()
    html            ::Function = (args...; kwargs...)->()
    h1              ::Function = (args...; kwargs...)->()
    h2              ::Function = (args...; kwargs...)->()
    h3              ::Function = (args...; kwargs...)->()
    h4              ::Function = (args...; kwargs...)->()
    h5              ::Function = (args...; kwargs...)->()
    h6              ::Function = (args...; kwargs...)->()
    dataframe       ::Function = (args...; kwargs...)->()
    checkbox        ::Function = (args...; kwargs...)->()
    checkboxes      ::Function = (args...; kwargs...)->()
    selectbox       ::Function = (args...; kwargs...)->()
    radio           ::Function = (args...; kwargs...)->()
    file_uploader   ::Function = (args...; kwargs...)->()
    text_input      ::Function = (args...; kwargs...)->()
    link            ::Function = (args...; kwargs...)->()
    color_picker    ::Function = (args...; kwargs...)->()
    text            ::Function = (args...; kwargs...)->()
    metric          ::Function = (args...; kwargs...)->()
    code            ::Function = (args...; kwargs...)->()
    icon            ::Function = (args...; kwargs...)->()
    space           ::Function = (args...; kwargs...)->()
end

CONTAINER_INTERFACE_FUNCS = [
    :columns, :column, :row, :button, :download_button, :image, :html, :radio, :selectbox,
    :h1, :h2, :h3, :h4, :h5, :h6, :dataframe, :checkbox, :checkboxes,
    :file_uploader, :text_input, :link, :color_picker, :text, :metric, :code,
    :icon, :space
]

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

function container(
    inner_func::Function=()->();
    css::Dict=Dict(),
    attributes::Dict=Dict()
)::ContainerInterface

    combined_css = Dict(
        "display" => "flex",
        "flex-direction" => "column",
        "align-items" => "flex-start",
        "justify-content" => "flex-start",
        "gap" => ".8rem",
    )

    merge!(combined_css, css)
    i_container = create_container(top_container(), combined_css, attributes)

    push_container(i_container)
    inner_func()
    pop_container()
    return i_container
end

function push_container(i_container::ContainerInterface)::ContainerInterface
    task = task_local_storage("app_task")
    push!(task.container_stack, i_container)
    return i_container
end

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
@with_kw mutable struct Containers
    containers      ::Vector{Union{ContainerInterface, Nothing}} = Vector{Union{ContainerInterface, Nothing}}()

    main_area       ::Union{ContainerInterface, Nothing} = nothing
    left_sidebar    ::Union{ContainerInterface, Nothing} = nothing
    right_sidebar   ::Union{ContainerInterface, Nothing} = nothing
end

Base.getindex(containers::Containers, i) = containers.containers[i]

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

function set_css_if_not_set(css::Dict, key::String, value::String)::Nothing
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

function column(
    inner_func::Function=()->();
    fill_width::Bool=false,
    fill_height::Bool=false,
    align_items::String="flex-start",
    justify_content::String="flex-start",
    gap::String=".8rem",
    max_width::String="100%",
    max_height::String="initial",
    show_border::Bool=false,
    border::String="1px solid #d6d6d6",
    padding::String="none",
    margin::String="none",
    css::Dict=Dict(),
    attributes::Dict=Dict()
)::ContainerInterface

    combined_css = Dict(
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
    set_css_if_not_set(css, "max-height", max_height)
    merge!(combined_css, css)

    return container(inner_func, css=combined_css, attributes=attributes)
end

function row(
    inner_func::Function=()->();
    fill_width::Bool=false,
    fill_height::Bool=false,
    align_items::String="flex-start",
    justify_content::String="flex-start",
    gap::String="0.8rem",
    margin::String="0",
    css::Dict=Dict()
)::ContainerInterface

    combined_css = Dict(
        "flex-direction" => "row",
        "gap" => gap,
        "align-items" => align_items,
        "justify-content" => justify_content,
        "margin" => margin,
        "min-width" => "0",
    )

    set_css_to_achieve_layout(combined_css, top_container(), fill_width, fill_height)

    merge!(combined_css, css)
    return container(inner_func, css=combined_css)
end

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

function set_page_layout(
    style::String="basic";
    max_width::String="600px",

    left_sidebar_initial_state::Union{Nothing, String}=nothing,
    left_sidebar_initial_width::String="300px",
    left_sidebar_position::String="slide-out",
    left_sidebar_toggle_labels::Tuple{Union{String, Nothing}, Union{String, Nothing}}=(nothing, nothing),

    right_sidebar_initial_state::Union{Nothing, String}=nothing,
    right_sidebar_initial_width::String="300px",
    right_sidebar_position::String="slide-out",
    right_sidebar_toggle_labels::Tuple{Union{String, Nothing}, Union{String, Nothing}}=(nothing, nothing),
)::Containers

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

function main_area(inner_func::Function)::ContainerInterface
    task = task_local_storage("app_task")
    push_container(task.layout.main_area)
    inner_func()
    pop_container()
    return task.layout.main_area
end

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
