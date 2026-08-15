
# Widget
#-----------------
const WidgetKind                = Int
const WidgetKind_None           = 0
const WidgetKind_Button         = 1
const WidgetKind_Selectbox      = 2
const WidgetKind_Checkboxes     = 3
const WidgetKind_Radio          = 4
const WidgetKind_Image          = 5
const WidgetKind_DataFrame      = 6
const WidgetKind_TextInput      = 7
const WidgetKind_NumberInput    = 8
const WidgetKind_ColorPicker    = 9
const WidgetKind_Code           = 10
const WidgetKind_FileUploader   = 11
const WidgetKind_Slider         = 12

@with_kw mutable struct Widget
    id          ::String                    = ""
    user_id     ::Union{String, Nothing}    = nothing
    kind        ::WidgetKind                = WidgetKind_None
    clicked     ::Bool                      = false
    value       ::Any                       = nothing
    changes     ::Dict{Int, Dict{String, Any}} = Dict{Int, Dict{String, Any}}()
    alive       ::Bool                      = true
    fragment_id ::String                    = ""

    onclick     ::Function                  = (args...; kwargs...)->()
    onchange    ::Function                  = (args...; kwargs...)->()
    args        ::Vector                    = Vector()

    props::Dict = Dict()
end

# Button
#-----------
function create_button(
    widgets::Dict{String, Widget},
    parent::Dict,
    label::String,
    style::String,
    icon::String,
    onclick::Function,
    args::Vector,
    download_path::Union{String, Nothing},
    download_name::Union{String, Nothing}
)::Bool

    props = Dict{String, Any}(
        "type" => "button",
        "label" => label,
        "style" => style,
        "icon" => icon,
    )

    props["local_id"] = bytes2hex(sha256(JSON.json(props)))
    props["container_id"] = parent["id"]
    props["id"] = "$(props["container_id"])/$(props["local_id"])"

    props["download_path"] = download_path
    props["download_name"] = download_name

    push!(parent["children"], props)

    widget = nothing

    if haskey(widgets, props["id"])
        widget = widgets[props["id"]]
        widget.alive = true
    else
        widget = Widget()
        widget.kind = WidgetKind_Button
        widget.id = props["id"]
        widget.fragment_id = top_fragment().id
        widget.value = false
        widget.onclick = onclick
        widget.args = args
        widgets[props["id"]] = widget
    end

    widget.props = props

    return widget.value
end

function button(label::String=""; style::String="secondary", icon::String="", onclick::Function=(args...; kwargs...)->(), args::Vector=Vector())::Bool
    task = task_local_storage("app_task")
    widgets = task.session.widgets
    return create_button(widgets, top_container(), label, style, icon, onclick, args, nothing, nothing)
end

# Download Button
#-----------------
function download_button(
    label::String,
    file_path::String;
    file_name::Union{String, Nothing}=nothing,
    style::String="secondary",
    icon::String="material/download",
    onclick::Function=(args...; kwargs...)->(),
    args::Vector=Vector()
)::Bool

    task = task_local_storage("app_task")
    widgets = task.session.widgets
    if file_name === nothing
        file_name = basename(file_path)
    end
    return create_button(widgets, top_container(), label, style, icon, onclick, args, file_path, file_name)
end

# Text Input
#-----------
function create_text_input(
    widgets::Dict{String, Widget},
    parent::Dict,
    user_id::Any,
    label::String,
    initial_value::Union{String, Nothing},
    placeholder::Union{String, Nothing},
    css=Dict
)::Union{String, Nothing}

    props = Dict(
        "type" => "text_input",
        "user_id" => user_id,
        "label" => label,
        "default_value" => maybe_get_default_value(user_id),
        "initial_value" => initial_value,
        "placeholder" => placeholder,
        "css" => css,
    )

    if props["placeholder"] == nothing
        props["placeholder"] = coalesce(props["default_value"], "")
    end

    props["local_id"] = bytes2hex(sha256(JSON.json(props)))
    props["container_id"] = parent["id"]
    props["id"] = "$(props["container_id"])/$(props["local_id"])"

    push!(parent["children"], props)

    widget = nothing

    if haskey(widgets, props["id"])
        widget = widgets[props["id"]]
        widget.alive = true
    else
        widget = Widget()
        widget.kind = WidgetKind_TextInput
        widget.id = props["id"]
        widget.fragment_id = top_fragment().id
        widget.user_id = props["user_id"]
        widget.value = props["initial_value"]
        widgets[props["id"]] = widget
    end

    props["value"] = widget.value
    widget.props = props

    return coalesce(widget.value, props["default_value"])
end

function text_input(
    label::String;
    id::Any=nothing,
    show_label::Bool=true,
    fill_width::Bool=false,
    initial_value::Union{String, Nothing}=nothing,
    placeholder::Union{String, Nothing}=nothing,
    css::Dict=Dict()
)::Union{String, Nothing}

    task = task_local_storage("app_task")
    parent = top_container()
    widgets = task.session.widgets

    container_css = Dict()
    set_css_to_achieve_layout(container_css, parent, fill_width, false)

    if !isempty(label) && show_label
        col = column(gap="0.3em", css=container_css)
        col.html("label", label, css=Dict("font-size" => "0.9rem"))
        parent = col.container
    else
        merge!(css, container_css)
    end

    return create_text_input(widgets, parent, id, label, initial_value, placeholder, css)
end

# Number Input
#---------------
function create_number_input(
    widgets::Dict{String, Widget},
    parent::Dict,
    user_id::Any,
    label::String,
    initial_value::Union{Real, Nothing},
    placeholder::Union{String, Nothing},
    num_type::Type{<:Real},
    precision::Int,
    min::Union{Real, Nothing},
    max::Union{Real, Nothing},
    step::Real,
    decimal_separator::String,
    thousands_separator::String,
    css=Dict
)::Union{Real, Nothing}

    props = Dict(
        "type" => "number_input",
        "user_id" => user_id,
        "label" => label,
        "default_value" => maybe_get_default_value(user_id),
        "initial_value" => initial_value,
        "placeholder" => placeholder,
        "num_type" => num_type,
        "precision" => num_type <: Integer ? 0 : precision,
        "min" => min,
        "max" => max,
        "step" => step,
        "decimal_separator" => decimal_separator,
        "thousands_separator" => thousands_separator,
        "css" => css,
    )

    if props["placeholder"] == nothing
        props["placeholder"] = coalesce(props["default_value"], "")
    end

    props["local_id"] = bytes2hex(sha256(JSON.json(props)))
    props["container_id"] = parent["id"]
    props["id"] = "$(props["container_id"])/$(props["local_id"])"

    push!(parent["children"], props)

    widget = nothing

    if haskey(widgets, props["id"])
        widget = widgets[props["id"]]
        widget.alive = true
    else
        widget = Widget()
        widget.kind = WidgetKind_NumberInput
        widget.id = props["id"]
        widget.fragment_id = top_fragment().id
        widget.user_id = props["user_id"]
        widget.value = props["initial_value"]
        widgets[props["id"]] = widget
    end

    props["value"] = widget.value
    widget.props = props

    return coalesce(widget.value, props["default_value"])
end

function number_input(
    label::String;
    initial_value::Union{Real, Nothing}=nothing,
    placeholder::Union{String, Nothing}=nothing,
    num_type::Type{<:Real}=Float64,
    precision::Integer=1,
    min::Union{Real, Nothing}=nothing,
    max::Union{Real, Nothing}=nothing,
    step::Real=1.0,
    decimal_separator::String=".",
    thousands_separator::String=",",
    show_label::Bool=true,
    fill_width::Bool=false,
    id::Any=nothing,
    css::Dict=Dict()
)::Union{Real, Nothing}

    if num_type <: Integer && !(typeof(step) <: Integer)
        throw(ArgumentError(
            "Incompatible types of `num_type` ($(num_type)) and `step` ($(typeof(step)) $(step)).\n" *
            "Please provide an Integer `step` for Integer `num_type`."
        ))
    end

    task = task_local_storage("app_task")
    parent = top_container()
    widgets = task.session.widgets

    container_css = Dict()
    set_css_to_achieve_layout(container_css, parent, fill_width, false)

    if !isempty(label) && show_label
        col = column(gap="0.3em", css=container_css)
        col.html("label", label, css=Dict("font-size" => "0.9rem"))
        parent = col.container
    else
        merge!(css, container_css)
    end

    return create_number_input(widgets, parent, id, label, initial_value, placeholder, num_type, precision, min, max, step, decimal_separator, thousands_separator, css)
end

# Slider
#----------
function create_slider(
    widgets::Dict{String, Widget},
    parent::Dict,
    user_id::Any,
    label::String,
    initial_value::Union{Real, Nothing},
    num_type::Type{<:Real},
    precision::Int,
    min::Real,
    max::Real,
    step::Real,
    decimal_separator::String,
    thousands_separator::String,
    css=Dict
)::Real

    props = Dict(
        "type" => "slider",
        "user_id" => user_id,
        "label" => label,
        "default_value" => maybe_get_default_value(user_id),
        "initial_value" => initial_value,
        "num_type" => num_type,
        "precision" => num_type <: Integer ? 0 : precision,
        "min" => min,
        "max" => max,
        "step" => step,
        "decimal_separator" => decimal_separator,
        "thousands_separator" => thousands_separator,
        "css" => css,
    )

    if props["initial_value"] === nothing
        props["initial_value"] = coalesce(props["default_value"], props["min"])
    end

    props["local_id"] = bytes2hex(sha256(JSON.json(props)))
    props["container_id"] = parent["id"]
    props["id"] = "$(props["container_id"])/$(props["local_id"])"

    push!(parent["children"], props)

    widget = nothing

    if haskey(widgets, props["id"])
        widget = widgets[props["id"]]
        widget.alive = true
    else
        widget = Widget()
        widget.kind = WidgetKind_Slider
        widget.id = props["id"]
        widget.fragment_id = top_fragment().id
        widget.user_id = props["user_id"]
        widget.value = props["initial_value"]
        widgets[props["id"]] = widget
    end

    props["value"] = widget.value
    widget.props = props

    return widget.value
end

function slider(
    label::String;
    initial_value::Union{T, Nothing}=nothing,
    min::T=0.0,
    max::T=1.0,
    step::Union{T, Nothing}=nothing,
    precision::Integer=2,
    decimal_separator::String=".",
    thousands_separator::String=",",
    show_label::Bool=true,
    fill_width::Bool=false,
    id::Any=nothing,
    css::Dict=Dict()
)::Real where {T <: Real}

    if initial_value !== nothing
        if !(min <= initial_value <= max)
            throw(ArgumentError(
                "`initial_value` ($(initial_value)) is not between `min` ($(min)) and `max` ($(max))"
            ))
        end
    end

    if step === nothing
        if T <: Integer
            step = 1
        else
            step = 0.01
        end
    end

    task = task_local_storage("app_task")
    parent = top_container()
    widgets = task.session.widgets

    container_css = Dict()
    set_css_to_achieve_layout(container_css, parent, fill_width, false)

    if !isempty(label) && show_label
        if !fill_width
            container_css["width"] = "200px"
        end

        col = column(gap="0.3em", css=container_css)
        col.html("label", label, css=Dict("font-size" => "0.9rem"))
        parent = col.container
    else
        merge!(css, container_css)
    end

    return create_slider(widgets, parent, id, label, initial_value, T, precision, min, max, step, decimal_separator, thousands_separator, css)
end

# Selectbox
#-----------
function create_selectbox(
    widgets::Dict{String, Widget},
    parent::Dict,
    user_id::Any,
    label::String,
    options::Vector,
    initial_value::Union{String, Vector, Nothing},
    multiple::Bool,
    placeholder::Union{String, Nothing},
    onchange::Function,
    css=Dict
)::Union{String, Vector, Nothing}

    props = Dict(
        "type" => "selectbox",
        "user_id" => user_id,
        "default_value" => maybe_get_default_value(user_id),
        "initial_value" => initial_value,
        "label" => label,
        "options" => options,
        "multiple" => multiple,
        "placeholder" => placeholder,
        "css" => css,
    )

    if props["placeholder"] == nothing
        if props["default_value"] !== nothing && props["default_value"] !== missing
            if typeof(props["default_value"]) == String
                props["placeholder"] = props["default_value"]
            else
                props["placeholder"] = join([replace(option, "\"" => "") for option in repr.(props["default_value"])], ", ")
            end
        else
            props["placeholder"] = ""
        end
    end

    props["local_id"] = bytes2hex(sha256(JSON.json(props)))
    props["container_id"] = parent["id"]
    props["id"] = "$(props["container_id"])/$(props["local_id"])"

    push!(parent["children"], props)

    widget = nothing

    if haskey(widgets, props["id"])
        widget = widgets[props["id"]]
        widget.alive = true
    else
        widget = Widget()
        widget.kind = WidgetKind_Selectbox
        widget.id = props["id"]
        widget.fragment_id = top_fragment().id
        widget.user_id = props["user_id"]
        widget.value = initial_value
        widget.onchange = onchange
        widgets[props["id"]] = widget
    end

    props["value"] = widget.value
    widget.props = props

    return coalesce(widget.value, props["default_value"])
end

function selectbox(
        label::String,
        options::Vector;
        initial_value::Union{String, Vector, Nothing}=nothing,
        id::Any=nothing,
        multiple::Bool=false,
        show_label::Bool=true,
        placeholder::Union{String, Nothing}=nothing,
        fill_width::Bool=false,
        onchange::Function=(args...; kwargs...)->(),
        css::Dict=Dict()
    )::Union{String, Vector, Nothing}

    task = task_local_storage("app_task")
    parent = top_container()
    widgets = task.session.widgets

    container_css = Dict()
    set_css_to_achieve_layout(container_css, parent, fill_width, false)

    if !isempty(label) && show_label
        col = column(gap="0.3em", css=container_css)
        col.html("label", label, css=Dict("font-size" => "0.9rem"))
        parent = col.container
    else
        merge!(css, container_css)
    end

    return create_selectbox(widgets, parent, id, label, options, initial_value, multiple, placeholder, onchange, css)
end

# Color Picker
#-------------------
function create_color_picker(
    widgets::Dict{String, Widget},
    parent::Dict,
    user_id::Any,
    label::String,
    initial_value::Union{String, Nothing},
    onchange::Function,
    css=Dict
)::String

    props = Dict(
        "type" => "color_picker",
        "user_id" => user_id,
        "default_value" => maybe_get_default_value(user_id),
        "initial_value" => initial_value,
        "label" => label,
        "css" => css,
    )

    # NOTE: Color picker can't have "no" value, so initial value must be
    # set to something.
    if props["initial_value"] === nothing
        props["initial_value"] = coalesce(props["default_value"], "#999999")
    end

    props["local_id"] = bytes2hex(sha256(JSON.json(props)))
    props["container_id"] = parent["id"]
    props["id"] = "$(props["container_id"])/$(props["local_id"])"

    push!(parent["children"], props)

    widget = nothing

    if haskey(widgets, props["id"])
        widget = widgets[props["id"]]
        widget.alive = true
    else
        widget = Widget()
        widget.kind = WidgetKind_ColorPicker
        widget.id = props["id"]
        widget.user_id = props["user_id"]
        widget.fragment_id = top_fragment().id
        widget.value = props["initial_value"]
        widget.onchange = onchange
        widgets[props["id"]] = widget
    end

    props["value"] = widget.value
    widget.props = props

    return widget.value
end

function color_picker(
    label::String;
    initial_value::Union{String, Nothing}=nothing,
    id::Any=nothing,
    show_label::Bool=true,
    fill_width::Bool=false,
    onchange::Function=(args...; kwargs...)->(),
    css::Dict=Dict()
)::String

    task = task_local_storage("app_task")
    parent = top_container()
    widgets = task.session.widgets

    container_css = Dict()
    set_css_to_achieve_layout(container_css, parent, fill_width, false)

    if !isempty(label) && show_label
        col = column(gap="0.3em", css=container_css)
        col.html("label", label, css=Dict("font-size" => "0.9rem"))
        parent = col.container
        if !haskey(css, "align-self") && !haskey(css, "width")
            css["align-self"] = "stretch"
            css["width"] = "initial"
        end
    else
        merge!(css, container_css)
    end

    return create_color_picker(widgets, parent, id, label, initial_value, onchange, css)
end

# Checkbox
#-----------
function create_checkboxes(
    widgets::Dict{String, Widget},
    parent::Dict,
    user_id::Any,
    label::String,
    options::Vector,
    initial_value::Union{Vector, Nothing},
    multiple::Bool,
    onchange::Function,
    args::Vector
)::Union{Bool, Vector}

    props = Dict(
        "type" => "checkboxes",
        "label" => label,
        "options" => options,
        "initial_value" => initial_value,
        "multiple" => multiple,
        "user_id" => user_id,
    )

    if props["initial_value"] === nothing
        default_value = maybe_get_default_value(user_id)
        if default_value !== nothing
            if multiple
                props["initial_value"] = default_value
            else
                props["initial_value"] = default_value ? [label] : []
            end
        else
            props["initial_value"] = []
        end
    end

    props["local_id"] = bytes2hex(sha256(JSON.json(props)))
    props["container_id"] = parent["id"]
    props["id"] = "$(props["container_id"])/$(props["local_id"])"

    push!(parent["children"], props)

    widget = nothing

    if haskey(widgets, props["id"])
        widget = widgets[props["id"]]
        widget.alive = true
    else
        widget = Widget()
        widget.kind = WidgetKind_Checkboxes
        widget.id = props["id"]
        widget.user_id = props["user_id"]
        widget.fragment_id = top_fragment().id
        if multiple
            widget.value = props["initial_value"]
        else
            widget.value = (length(props["initial_value"]) > 0)
        end
        widget.onchange = onchange
        widget.args = args
        widgets[props["id"]] = widget
    end

    props["value"] = widget.value
    widget.props = props

    return widget.value
end

function checkbox(
    label::String;
    id::Any=nothing,
    initial_value::Union{Bool, Nothing}=nothing,
    onchange::Function=(args...; kwargs...)->(),
    args::Vector=Vector()
)::Bool

    task = task_local_storage("app_task")
    widgets = task.session.widgets

    init_value = nothing

    if initial_value !== nothing
        init_value = initial_value ? [label] : []
    end

    return create_checkboxes(widgets, top_container(), id, label, [label], init_value, false, onchange, args)
end

function checkboxes(
    label::String,
    options::Vector;
    id::Any=nothing,
    initial_value::Union{Vector, Nothing}=nothing,
    onchange::Function=(args...; kwargs...)->(),
    args::Vector=Vector()
)::Vector

    task = task_local_storage("app_task")
    widgets = task.session.widgets
    return create_checkboxes(widgets, top_container(), id, label, options, initial_value, true, onchange, args)
end

# Radio
#-----------
function create_radio(
    widgets::Dict{String, Widget},
    parent::Dict,
    user_id::Any,
    label::String,
    options::Vector,
    initial_value::Union{String, Nothing}
)::Union{String, Nothing}

    props = Dict(
        "type" => "radio",
        "label" => label,
        "options" => options,
        "user_id" => user_id,
        "initial_value" => initial_value,
    )

    if props["initial_value"] === nothing
        props["initial_value"] = coalesce(maybe_get_default_value(user_id), options[1])
    end

    props["local_id"] = bytes2hex(sha256(JSON.json(props)))
    props["container_id"] = parent["id"]
    props["id"] = "$(props["container_id"])/$(props["local_id"])"

    push!(parent["children"], props)

    widget = nothing

    if haskey(widgets, props["id"])
        widget = widgets[props["id"]]
        widget.alive = true
    else
        widget = Widget()
        widget.kind = WidgetKind_Radio
        widget.id = props["id"]
        widget.user_id = props["user_id"]
        widget.fragment_id = top_fragment().id
        widget.value = props["initial_value"]
        widgets[props["id"]] = widget
    end

    props["value"] = widget.value
    widget.props = props

    return widget.value
end

function radio(
    label::String,
    options::Vector;
    id::Any=nothing,
    initial_value::Union{String, Nothing}=nothing
)::Union{String, Nothing}

    task = task_local_storage("app_task")
    widgets = task.session.widgets
    return create_radio(widgets, top_container(), id, label, options, initial_value)
end

# Image
#-----------
function get_file_sha256(path::AbstractString)
    open(path, "r") do io
        return bytes2hex(sha256(io))
    end
end

function create_image(widgets::Dict{String, Widget}, parent::Dict, src::String, width::Union{Number, Nothing}, height::Union{Number, Nothing}, css::Dict)::String
    props = Dict(
        "type" => "image",
        "src" => src,
        "width" => width,
        "height" => height,
        "css" => css,
    )

    props["local_id"] = bytes2hex(sha256(JSON.json(props)))
    props["container_id"] = parent["id"]
    props["id"] = "$(props["container_id"])/$(props["local_id"])"
    props["src"] = src

    push!(parent["children"], props)

    widget = nothing

    if haskey(widgets, props["id"])
        widget = widgets[props["id"]]
        widget.alive = true
    else
        widget = Widget()
        widget.kind = WidgetKind_Image
        widget.id = props["id"]
        widget.fragment_id = top_fragment().id
        widget.value = props["src"]
        widgets[props["id"]] = widget
    end

    props["value"] = widget.value
    widget.props = props

    return widget.value
end

function image(
    src_or_path::String;
    fill_width::Bool=false,
    max_width::String="100%",
    width::Union{Number, Nothing}=nothing,
    height::Union{Number, Nothing}=nothing,
    css::Dict=Dict("height" => "auto")
)::String

    task = task_local_storage("app_task")
    widgets = task.session.widgets

    if !haskey(css, "flex-grow") && !haskey(css, "width")
        set_css_to_achieve_layout(css, top_container(), fill_width, false)
    end

    css["height"] = "auto"

    if width != nothing && height != nothing && !haskey(css, "aspect-ratio")
        css["aspect-ratio"] = "$width / $height"
    end

    if !haskey(css, "max-width")
        css["max-width"] = max_width
    end

    if !startswith(src_or_path, ".Magic/served-files") && isfile(src_or_path)
        src_or_path = make_serveable_copy(src_or_path)
    end

    src = src_or_path
    if startswith(src_or_path, ".Magic/served-files")
        src = replace(src_or_path, ".Magic/served-files" => "")
    end

    return create_image(widgets, top_container(), src, width, height, css)
end
# Dataframe
#--------------------
function create_dataframe(
    widgets::Dict{String, Widget},
    parent::Dict,
    user_id::Any,
    data::DataFrame,
    column_config::Dict,
    height::String,
    onchange::Function,
    args::Vector
)::DataFrame

    props = Dict(
        "type" => "dataframe",
        "data_ptr" => repr(pointer_from_objref(data)),
        "column_config" => column_config,
        "height" => height,
        "user_id" => user_id,
    )

    props["local_id"] = bytes2hex(sha256(JSON.json(props)))
    props["container_id"] = parent["id"]
    props["id"] = "$(props["container_id"])/$(props["local_id"])"

    push!(parent["children"], props)

    widget = nothing

    if haskey(widgets, props["id"])
        widget = widgets[props["id"]]
        widget.alive = true
    else
        widget = Widget()
        widget.kind = WidgetKind_DataFrame
        widget.id = props["id"]
        widget.fragment_id = top_fragment().id
        widget.user_id = props["user_id"]
        widget.onchange = onchange
        widget.args = args
        widget.value = data
        widgets[props["id"]] = widget
        props["initial_value"] = Tables.collect(Tables.rowtable(data))
    end

    widget.props = props

    return widget.value
end

function dataframe(
    data::DataFrame;
    column_config::Dict=Dict(),
    height::String="400px",
    id::Union{String, Nothing}=nothing,
    onchange::Function=(args...; kwargs...)->(),
    args::Vector=Vector()
)::DataFrame

    task = task_local_storage("app_task")
    widgets = task.session.widgets

    cc = Dict()

    for column_name in names(data)
        cc[column_name] = Dict()

        if column_name in keys(column_config)
            merge!(cc[column_name], column_config[column_name])
        end

        column_type = eltype(data[:, column_name])
        cc[column_name]["julia_type"] = column_type

        if !("type" in keys(cc[column_name]))
            if Number <: column_type || Int <: column_type || Real <: column_type
                cc[column_name]["type"] = "Number"
            else
                cc[column_name]["type"] = "String"
            end
        end

        if !("empty_value" in keys(cc[column_name]))
            if Nothing <: column_type
                cc[column_name]["empty_value"] = "<nothing>"
            elseif Missing <: column_type
                cc[column_name]["empty_value"] = "<missing>"
            else
                cc[column_name]["empty_value"] = ""
                cc[column_name]["required"] = true
            end
        end
    end

    return create_dataframe(widgets, top_container(), id, data, cc, height, onchange, args)
end

# File uploader
#-----------------
@with_kw mutable struct UploadedFile
    id::String          = ""
    name::String        = ""
    extension::String   = ""
    path::String        = ""
    type::String        = ""
    size::Int           = 0
    last_modified::Int  = 0
end

function create_file_uploader(
    widgets::Dict{String, Widget},
    parent::Dict,
    user_id::Any,
    label::String,
    types::Vector{String},
    multiple::Bool,
    max_file_size::Int,
    max_files::Int,
    onchange::Function,
    args::Vector,
    css::Dict
)::Union{Vector{UploadedFile}, UploadedFile, Nothing}

    props = Dict(
        "type" => "file_uploader",
        "user_id" => user_id,
        "label" => label,
        "types" => types,
        "multiple" => multiple,
        "max_file_size" => max_file_size,
        "max_files" => max_files,
        "css" => css,
    )

    props["local_id"] = bytes2hex(sha256(JSON.json(props)))
    props["container_id"] = parent["id"]
    props["id"] = "$(props["container_id"])/$(props["local_id"])"

    push!(parent["children"], props)

    widget = nothing

    if haskey(widgets, props["id"])
        widget = widgets[props["id"]]
        widget.alive = true
    else
        widget = Widget()
        widget.kind = WidgetKind_FileUploader
        widget.id = props["id"]
        widget.fragment_id = top_fragment().id
        widget.user_id = props["user_id"]
        widget.onchange = onchange
        widget.args = args
        widget.value = nothing
        widgets[props["id"]] = widget
    end

    widget.props = props

    return widget.value
end

function file_uploader(
    label::String;
    types::Vector{String}=Vector{String}(),
    multiple::Bool=false,
    max_file_size::Union{Int, Nothing}=nothing,
    max_files::Union{Int, Nothing}=nothing,
    fill_width::Bool=false,
    show_label::Bool=true,
    id::Union{String, Nothing}=nothing,
    onchange::Function=(args...; kwargs...)->(),
    args::Vector=Vector(),
    css::Dict=Dict(),
)::Union{Vector{UploadedFile}, UploadedFile, Nothing}

    max_file_size = max_file_size === nothing ? g.upload_max_size : max_file_size
    max_files = max_files === nothing ? g.upload_max_files : max_files

    task = task_local_storage("app_task")
    widgets = task.session.widgets
    parent = top_container()

    container_css = Dict()
    set_css_to_achieve_layout(container_css, parent, fill_width, false)

    if !isempty(label) && show_label
        col = column(gap="0.3em", css=container_css)
        col.html("label", label, css=Dict("font-size" => "0.9rem"))
        parent = col.container
    end

    merge!(css, container_css)

    return create_file_uploader(widgets, parent, id, label, types, multiple, max_file_size, max_files, onchange, args, css)
end

# HTML
#----------------
function create_html(parent::Dict, tag::String, inner_html::String, attributes::Dict, css::Dict)
    html = Dict(
        "type" => "html",
        "tag" => tag,
        "inner_html" => inner_html,
        "attributes" => attributes,
        "css" => css,
    )

    push!(parent["children"], html)
    return nothing
end

function html(tag::String, inner_html::String; attributes::Dict=Dict(), css::Dict=Dict())::Nothing
    create_html(top_container(), tag, inner_html, attributes, css)
    return nothing
end

function link(label::String, url::String; style::String="secondary", fill_width=false, new_tab::Bool=false, css::Dict=Dict())::Nothing
    icon = ""
    if new_tab
        icon = "<mg-icon mg-icon='material/open_in_new'></mg-icon>"
    end

    combined_css = Dict("white-space" => "nowrap")
    set_css_to_achieve_layout(css, top_container(), fill_width, false)

    merge!(combined_css, css)

    html("a", "$label$icon", css=combined_css, attributes=Dict("class" => "mg-link dd-button mg-button-style-$(style)", "href" => url, "target" => new_tab ? "_blank" : ""))
    return nothing
end

space(; width::String="1px", height::String="1px") = html("div", "", css=Dict("width" => width, "height" => height))

# Text
#----------
function maybe_prepend_icon(text::String, icon::String, icon_color::String)::String
    if length(icon) > 0
        style = ""
        if length(icon_color) > 0
            style = "color: $icon_color"
        end
        result = "<mg-icon mg-icon='$icon' style='$(style)'></mg-icon> $text"
        return result
    end
    return text
end

h1(text::String; icon::String="", icon_color::String="", css=Dict()) = html("h1", maybe_prepend_icon(text, icon, icon_color), css=css)
h2(text::String; icon::String="", icon_color::String="", css=Dict()) = html("h2", maybe_prepend_icon(text, icon, icon_color), css=css)
h3(text::String; icon::String="", icon_color::String="", css=Dict()) = html("h3", maybe_prepend_icon(text, icon, icon_color), css=css)
h4(text::String; icon::String="", icon_color::String="", css=Dict()) = html("h4", maybe_prepend_icon(text, icon, icon_color), css=css)
h5(text::String; icon::String="", icon_color::String="", css=Dict()) = html("h5", maybe_prepend_icon(text, icon, icon_color), css=css)
h6(text::String; icon::String="", icon_color::String="", css=Dict()) = html("h6", maybe_prepend_icon(text, icon, icon_color), css=css)

icon(icon::String; color::String="inherit", size::String="inherit", weight::String="inherit") =
    html("mg-icon", "", attributes=Dict("mg-icon" => icon), css=Dict("color" => color, "font-size" => size, "font-weight" => "bold"))

text(text::Any) = html("p", typeof(text) == String ? text : repr(text))

# Code
#------------
function create_code(widgets::Dict{String, Widget}, parent::Dict, initial_value::String, show_line_numbers::Bool, css::Dict)::String
    props = Dict(
        "type" => "code",
        "initial_value" => initial_value,
        "show_line_numbers" => show_line_numbers,
        "css" => css,
    )

    props["local_id"] = bytes2hex(sha256(JSON.json(props)))
    props["container_id"] = parent["id"]
    props["id"] = "$(props["container_id"])/$(props["local_id"])"

    push!(parent["children"], props)

    widget = nothing

    if haskey(widgets, props["id"])
        widget = widgets[props["id"]]
        widget.alive = true
    else
        widget = Widget()
        widget.kind = WidgetKind_Code
        widget.id = props["id"]
        widget.fragment_id = top_fragment().id
        widget.value = initial_value
        widgets[props["id"]] = widget
    end

    widget.props = props

    return widget.value
end

function code(initial_value::String=""; initial_value_file::Union{String, Nothing}=nothing, fill_width::Bool=true, max_width::String="100%", max_height::String="initial", padding::String="0", strip_whitespace::Bool=true, show_line_numbers::Bool=false, css::Dict=Dict("overflow-y" => "auto"))::String
    task = task_local_storage("app_task")
    widgets = task.session.widgets

    if initial_value_file != nothing
        initial_value = read(initial_value_file, String)
    end

    if !haskey(css, "flex-grow") && !haskey(css, "width")
        set_css_to_achieve_layout(css, top_container(), fill_width, false)
    end

    set_css_if_not_set(css, "padding", padding)
    set_css_if_not_set(css, "max-width", max_width)
    set_css_if_not_set(css, "max-height", max_height)

    if strip_whitespace
        initial_value = String(strip(initial_value))
    end

    return create_code(widgets, top_container(), initial_value, show_line_numbers, css)
end

# Metric
#-------------
function metric(label::String, value::String, delta::String="", higher_is_better::Bool=true)::Nothing
    deltaHTML = ""
    color, background = "#0b8a07", "#a6f9a6"

    if length(delta) > 0
        if startswith(delta, "-") || !higher_is_better
            color, background = "#bf0b0b", "#fbacac"
        end

        icon = startswith(delta, "-") ? "material/arrow_downward" : "material/arrow_upward"

        iconHTML = "<mg-icon mg-icon='$icon' style='font-size: 1.1em; color: $color; background: $background'></mg-icon>"
        deltaHTML = "$iconHTML $delta"
    end

    @push column(gap="0")
        html("label", label, css=Dict("font-size" => "0.85rem"))
        html("span", value, css=Dict("font-size" => "1.8rem"))
        if length(deltaHTML) > 0
            html("span", deltaHTML, css=Dict("font-size" => "0.85rem", "color" => color, "background" => background, "border-radius" => "100vw", "padding" => ".2em .4em", "display" => "flex", "align-items" => "center"))
        end
    @pop

    return nothing
end

# Misc
#---------
maybe_get_default_value = (user_id::Union{String, Nothing}) -> (user_id != nothing ? get_default_value(user_id) : nothing)

function coalesce(args...)
    for arg in args
        if arg !== nothing && arg !== missing
            return arg
        end
    end
    return nothing
end

function get_widget_by_user_id(widgets::Dict{String, Widget}, user_id::String)::Union{Widget, Missing}
    for widget in values(widgets)
        if widget.user_id == user_id
            return widget
        end
    end
    return missing
end

function set_default_value(user_id::String, value::Any)::Nothing
    task = task_local_storage("app_task")
    task.session.widget_defaults[user_id] = value
    widget = get_widget_by_user_id(task.session.widgets, user_id)
    if widget !== missing
        widget.props["default_value"] = value
    end
    return nothing
end

function get_default_value(user_id::String)::Any
    task = task_local_storage("app_task")
    if haskey(task.session.widget_defaults, user_id)
        return task.session.widget_defaults[user_id]
    end
    return missing
end

function set_value(user_id::String, value::Any)::Nothing
    task = task_local_storage("app_task")
    widget = get_widget_by_user_id(task.session.widgets, user_id)
    if widget !== missing
        widget.value = value
        widget.props["value"] = value
    else
        # TODO: Handle widget not found
    end
    return nothing
end

function get_value(user_id::String)::Any
    task = task_local_storage("app_task")
    widget = get_widget_by_user_id(task.session.widgets, user_id)
    if widget === missing
        return get_default_value(user_id)
    elseif widget.value === nothing
        def_value = get_default_value(user_id)
        if def_value !== missing
            return def_value
        else
            return nothing
        end
    end
    return widget.value
end

function get_changes(user_id::String)::Union{Missing, Dict{Int, Dict{String, Any}}}
    task = task_local_storage("app_task")
    widget = get_widget_by_user_id(task.session.widgets, user_id)
    if widget === missing
        return missing
    end
    return widget.changes
end
