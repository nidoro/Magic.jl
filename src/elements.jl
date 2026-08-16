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

"""
# button

Display a button widget.

### Function Signature

```julia
function button(
    label   ::String    ="";
    style   ::String    ="secondary",
    icon    ::String    ="",
    onclick ::Function  =(args...; kwargs...)->(),
    args    ::Vector    =Vector()
)::Bool
```

 Argument  | Description
---------- |-------------
 `label`   | A `String` to be displayed inside the button. It can contain HTML.
 `style`   | A `String`. Should be either `primary`, `secondary`, or `naked`. Default: `secondary`.
 `icon`    | A `String` in the format `material/icon_name`. Example: `material/thumb_up`.<br/><br/>Check out https://fonts.google.com/icons?icon.set=Material+Icons to learn the icon names.
 `onclick` | A callback `Function`. This function will be called when the button is clicked, before the app script is rerun.
 `args`    | A `Vector` of arguments that will be passed to the `onclick` callback function.

### Return Value

`true` if the button was clicked, `false` otherwise.
"""
function button(label::String=""; style::String="secondary", icon::String="", onclick::Function=(args...; kwargs...)->(), args::Vector=Vector())::Bool
    task = task_local_storage("app_task")
    widgets = task.session.widgets
    return create_button(widgets, top_container(), label, style, icon, onclick, args, nothing, nothing)
end

# Download Button
#-----------------
"""
# download_button

Creates a download button widget. It behaves similarly to
[`button()`](/docs/build/docs/api-reference/interface-elements/button-func),
with the additional effect of starting a download.

### Function Signature

```julia
function download_button(
    label       ::String,
    file_path   ::String;
    file_name   ::Union{String, Nothing}=nothing,
    style       ::String="secondary",
    icon        ::String="material/download",
    onclick     ::Function=(args...; kwargs...)->(),
    args        ::Vector=Vector()
)::Bool
```

 Argument     | Description
------------------ | -----------
 `label`   | A `String` to be displayed inside the button. It can contain HTML.
 `file_path`    | A `String` specifying the file to be downloaded. The file must live inside `.Magic/served-files/` somewhere.
 `file_name`    | A `String` specifying the name with which the file should be saved in the user side.
 `style`   | A `String`. Should be either `primary`, `secondary`, or `naked`. Default: `secondary`.
 `icon`    | A `String` in the format `material/icon_name`. Example: `material/thumb_up`.<br/><br/>Check out https://fonts.google.com/icons?icon.set=Material+Icons to learn the icon names.
 `onclick` | A callback `Function`. This function will be called when the button is clicked, before the app script is rerun.
 `args`    | A `Vector` of arguments that will be passed to the `onclick` callback function.

### Return Value

`true` if the button was clicked, `false` otherwise.

### Generating downloadable files

The provided `file_path` does not necessarily need to point to an existing file;
it can point to a path inside `.Magic/served-files` where the file will be
generated when the download button is clicked. Example:

```julia
serveable_path = gen_serveable_path(".png")
if download_button("Download", serveable_path)
    # Generate file here and save it at `serveable_path`
end
```

Alternatively, you can generate the file within the `onclick` callback. Example:

```julia
function gen_file(path)
    # Generate file here and save it at `path`
end

serveable_path = gen_serveable_path(".png")
download_button("Download", serveable_path, onclick=gen_file, args=[serveable_path])
```

### Example

See [Image Filters Demo](https://magic.coisasdodavi.net/image-filters) for a
`download_button` usage example.
"""
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

"""
# text_input

Display a text input widget.

### Function Signature

```julia
function text_input(
    label          ::String;
    id             ::Any      = nothing,
    show_label     ::Bool     = true,
    fill_width     ::Bool     = false,
    initial_value  ::Union{String, Nothing}=nothing,
    placeholder    ::Union{String, Nothing}=nothing,
    css            ::Dict     = Dict()
)::Union{String, Nothing}
```

 Argument           | Description
------------------ | -----------
 `label`            | A `String` to be displayed as the label for the text input. It can contain HTML.
 `id`              | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `show_label`       | A `Bool` indicating whether the label should be displayed. Default: `true`.
 `fill_width`       | A `Bool` indicating whether the text input should expand to fill the available horizontal space. Default: `false`.
 `initial_value`    | Either a `String` specifying the initial text value of the input, or `nothing` (default). If `nothing` is provided, the initial value will be the default value previously set with `set_default_value()` if any; otherwise, the widget will be initialized with value `nothing`.
 `placeholder`      | A `String` shown as placeholder text when the widget's value is `nothing`.
 `css`               | A `Dict` of additional CSS properties applied to the text input element.

### Return Value

The current value of the text input as a `String` or `nothing`.
"""
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

"""
# number_input

Display a number input widget.

### Function Signature

```julia
function number_input(
    label               ::String;
    initial_value       ::Union{Real, Nothing}=nothing,
    placeholder         ::Union{String, Nothing}=nothing,
    num_type            ::Type{<:Real}=Float64,
    precision           ::Integer=1,
    min                 ::Union{Real, Nothing}=nothing,
    max                 ::Union{Real, Nothing}=nothing,
    step                ::Real=1.0,
    decimal_separator   ::String=".",
    thousands_separator ::String=",",
    show_label          ::Bool=true,
    fill_width          ::Bool=false,
    id                  ::Any=nothing,
    css                 ::Dict=Dict()
)::Union{Real, Nothing}
```

 Argument           | Description
------------------ | -----------
 `label`            | A `String` to be displayed as the label for the text input. It can contain HTML.
 `initial_value`    | Either a `Real` specifying the initial value of the input, or `nothing` (default). If `nothing` is provided (default), the initial value will be the default value previously set with `set_default_value()` if any; otherwise, the widget will be initialized with value `nothing`.
 `placeholder`      | A `String` shown as placeholder when the widget's value is `nothing`. Default: `nothing`.
 `num_type`       | A subtype of `Real` indicating how the widget value should be interpreted and returned. Default: `Float64`.
 `precision`       | An `Integer` specifying how many decimal places should be displayed by the widget. If `num_type` is an `Integer`, this parameter is ignored.
 `min`       | A `Real` specifying the minimum value allowed in the widget, or `nothing` (default) indicating there is no minimum value.
 `max`       | A `Real` specifying the maximum value allowed in the widget, or `nothing` (default) indicating there is no maximum value.
 `step`       | A `Real` specifying the size of the increment/decrement applied when clicking the `-` and `+` buttons in the widget.
 `decimal_separator`       | A `String` specifying the character that should be used as decimal separator. Default: `"."`.
 `thousands_separator`       | A `String` specifying the character that should be used as decimal separator; Default: `"."`.
 `show_label`       | A `Bool` indicating whether the label should be displayed. Default: `true`.
 `fill_width`       | A `Bool` indicating whether the text input should expand to fill the available horizontal space. Default: `false`.
 `id`              | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `css`               | A `Dict` of additional CSS properties applied to the input element.

### Return Value

The current value of the number input interpreted as `num_type`; or `nothing`.
"""
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

"""
# slider

Display a slider widget.

> **NOTE:** Make sure that parameters `min`, `max`, `step` and `initial_value`
> all have the same Real subtype.

### Function Signature

```julia
function slider(
    label               ::String;
    initial_value       ::Union{T, Nothing}=nothing,
    min                 ::T=zero(T),
    max                 ::T=one(T),
    step                ::Union{T, Nothing}=nothing,
    precision           ::Integer=2,
    decimal_separator   ::String=".",
    thousands_separator ::String=",",
    show_label          ::Bool=true,
    fill_width          ::Bool=false,
    id                  ::Any=nothing,
    css                 ::Dict=Dict()
)::Union{Real, Nothing} where {T <: Real}
```

 Argument           | Description
------------------ | -----------
 `label`            | A `String` to be displayed as the label for the slider. It can contain HTML.
 `initial_value`    | Either a value of type `T` specifying the initial value of the slider, or `nothing` (default). If `nothing` is provided (default), the initial value will be the default value previously set with `set_default_value()` if any; otherwise, the widget will be initialized with `min`.
 `min`              | A value of type `T` specifying the minimum value of the slider range. Default: `zero(T)`.
 `max`              | A value of type `T` specifying the maximum value of the slider range. Default: `one(T)`.
 `step`             | Either a value of type `T` specifying the increment size for the slider, or `nothing` (default) to automatically determine the step size, in which case it will be set to `1` if `T` is an `Integer` subtype or `0.01` otherwise.
 `precision`        | An `Integer` specifying how many decimal places should be displayed for the slider value. Default: `2`.
 `decimal_separator`   | A `String` specifying the character that should be used as decimal separator. Default: `"."`.
 `thousands_separator` | A `String` specifying the character that should be used as thousands separator. Default: `","`.
 `show_label`       | A `Bool` indicating whether the label should be displayed. Default: `true`.
 `fill_width`       | A `Bool` indicating whether the slider should expand to fill the available horizontal space. Default: `false`.
 `id`               | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `css`              | A `Dict` of additional CSS properties applied to the slider element.

### Return Value

The current value of the slider as a `Real` number; or `nothing`.
"""
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

"""
# selectbox

Display a select box (dropdown) widget.

### Function Signature

```julia
function selectbox(
    label           ::String,
    options         ::Vector;
    initial_value   ::Union{String, Vector, Nothing}=nothing,
    id              ::Any      = nothing,
    multiple        ::Bool     = false,
    show_label      ::Bool     = true,
    placeholder     ::Union{String, Nothing}=nothing,
    fill_width      ::Bool     = false,
    onchange        ::Function = (args...; kwargs...)->(),
    css             ::Dict     = Dict()
)::Union{String, Vector, Nothing}
```

 Argument        | Description
------------------ | -----------
 `label`        | A `String` to be displayed as the label for the select box. It can contain HTML.
 `options`      | A `Vector` of selectable values. Each element represents one option and will be displayed using its string representation.
 `initial_value`    | The value that should be initially selected. If `multiple` is `false` (default), this should be a `String` matching an option in `options`. If `multiple` is `true`, the value should be a `Vector` of `String`s in `options`.
 `id`              | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `multiple`     | A `Bool` indicating whether multiple options can be selected. Default: `false`.
 `show_label`   | A `Bool` indicating whether the label should be displayed. Default: `true`.
 `placeholder`  | A `String` shown as placeholder text when the selectbox is empty.
 `fill_width`   | A `Bool` indicating whether the select box should expand to fill the available horizontal space. Default: `false`.
 `onchange`     | A callback `Function`. This function is called when the selected value changes, before the app script is rerun.
 `css`          | A `Dict` of additional CSS properties applied to the select box element.

### Return Value

The currently selected value. If `multiple` is `false`, this is either a single `String` value from `options` or `nothing`. If `multiple` is `true`, this is either a `Vector` of selected values or `nothing`.
"""
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

"""
# color_picker

Display a color picker input widget.

### Function Signature

```julia
function color_picker(
    label           ::String;
    initial_value   ::Union{String, Nothing}=nothing,
    id              ::Any      =nothing,
    show_label      ::Bool     =true,
    fill_width      ::Bool     =false,
    onchange        ::Function =(args...; kwargs...)->(),
    css             ::Dict     =Dict()
)::String
```

 Argument        | Description
---------------- |-------------
 `label`       | A `String` used as the label for the color picker.
 `initial_value`    | Either a `String` specifying the initial hexadecimal color value of the input, or `nothing` (default). If `nothing` is provided, the initial value will be the default value previously set with `set_default_value()` if any; otherwise, the widget will be initialized with a grey color.
 `id`          | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `show_label`   | A `Bool` indicating whether the label should be displayed. Default: `true`.
 `fill_width`   | A `Bool` indicating whether the select box should expand to fill the available horizontal space. Default: `false`.
 `onchange`     | A callback `Function`. This function is called when the selected color changes, before the app script is rerun.
 `css`         | A `Dict` of additional CSS properties to apply to the color picker widget.

### Return Value

Returns the currently selected color value as a `String` in a hexadecimal format
such as `"#ff0000"`.
"""
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

"""
# checkbox

Display a checkbox widget.

### Function Signature

```julia
function checkbox(
    label         ::String;
    id            ::Any       = nothing,
    initial_value ::Union{Bool, Nothing}=nothing,
    onchange      ::Function  = (args...; kwargs...)->(),
    args          ::Vector    = Vector()
)::Bool
```

 Argument          | Description
------------------ | -----------
 `label`           | A `String` to be displayed next to the checkbox. It can contain HTML.
 `id`              | An optional identifier for the checkbox. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `initial_value`   | The checkbox initial value. If `nothing`, the default value set with `set_default_value()` will be used, if any; otherwise, the initial value will be `false`.
 `onchange`        | A callback `Function`. This function is called when the checkbox value changes, before the app script is rerun.
 `args`            | A `Vector` of arguments that will be passed to the `onchange` callback function.

### Return Value

The current value of the checkbox (`true` if checked, `false` otherwise).
"""
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

"""
# checkboxes

Display a checkbox group widget.

### Function Signature

```julia
function checkboxes(
    label           ::String,
    options         ::Vector;
    id              ::Any       =nothing,
    initial_value   ::Union{Vector, Nothing}=nothing,
    onchange        ::Function  =(args...; kwargs...)->(),
    args            ::Vector    =Vector()
)::Vector
```

 Argument          | Description
------------------ | -----------
 `label`           | A `String` to be displayed next to the checkbox. It can contain HTML.
 `options`         | A `Vector` specifying the selectable options. One checkbox for each option will be created.
 `id`              | An optional identifier for the checkbox. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `initial_value`   | A either a `Vector` indicating which options in `options` are initially checked, or `nothing`. If `nothing` is provided, the default value set with `set_default_value()` will be used, if any; otherwise, the initial value will be an empty `Vector` `[]`.
 `onchange`        | A callback `Function`. This function is called when the checkbox value changes, before the app script is rerun.
 `args`            | A `Vector` of arguments that will be passed to the `onchange` callback function.

### Return Value

A `Vector` indicating which options in `options` are checked.
"""
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

"""
# radio

Display a radio button group widget.

### Function Signature

```julia
function radio(
    label          ::String,
    options        ::Vector;
    id             ::Any = nothing,
    initial_value  ::Union{String, Nothing}=nothing
)::Union{String, Nothing}
```

 Argument           | Description
------------------  | -----------
 `label`            | A `String` to be displayed as the label for the radio button group. It can contain HTML.
 `options`          | A `Vector` of selectable values. Each element represents one radio option and will be displayed using its string representation.
 `id`              | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `initial_value`    | The value that should be initially selected. If provided, it should match one of the values in `options`. If `nothing`, the default value set with `set_default_value()` will be selected if one was provided. Otherwise, first option in `options` will be selected.

### Return Value

The currently selected value from `options`, or `nothing` if no option is selected.
"""
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

"""
# image

Display an image.

### Function Signature

```julia
function image(
    src_or_path ::String;
    fill_width  ::Bool                   = false,
    max_width   ::String                 = "100%",
    width       ::Union{Number, Nothing} = nothing,
    height      ::Union{Number, Nothing} = nothing,
    css         ::Dict                   = Dict("height" => "auto")
)::String
```

 Argument          | Description
------------------ | -----------
 `src_or_path`    | A `String` representing either a URL or a local file path to the image source.<br/><br/>Only images inside `.Magic/served-files` and subdirectories can be served. If it is a static image that does not change across sessions, a good practice is to place it inside `.Magic/served-files/static/images`. If it is a generated image, e.g. a plot that changes across app reruns, a good practice is to place it inside `.Magic/served-files/cache`.<br/><br/>For the common situation of regenerating and serving a new image on each rerun, there is a helper function `gen_serveable_path(ext)` that generates a file path with a random name and with the given extension `ext` inside `.Magic/served-files/cache`. This function returns the path that you should use to save your image and then pass to `image()` to place it in the app.
 `fill_width`     | A `Bool` indicating whether the image should expand to fill the available horizontal space. Default: `false`.
 `max_width`      | A `String` specifying the maximum width of the image using a CSS value (for example, `"100%"` or `"600px"`). Default: `"100%"`.
 `width`          | An optional numeric width to be used as the `width` attribute of the `img` tag.
 `height`         | An optional numeric height to be used as the `height` attribute of the `img` tag.
 `css`            | A `Dict` of additional CSS properties applied to the `img` tag. By default, the height is set to `"auto"`.

### Return Value

A `String` containing the rendered HTML for the image.
"""
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

    if !startswith(src_or_path, "$(g.dot_magic_dir)/.Magic/served-files") && isfile(src_or_path)
        src_or_path = make_serveable_copy(src_or_path)
    end

    src = src_or_path
    if startswith(src_or_path, "$(g.dot_magic_dir)/.Magic/served-files")
        src = replace(src_or_path, "$(g.dot_magic_dir)/.Magic/served-files" => "")
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

"""
# dataframe

Display a `DataFrame` from package [`DataFrames.jl`](https://dataframes.juliadata.org/stable/).

### Function Signature

```julia
function dataframe(
    data            ::DataFrame;
    column_config   ::Dict      =Dict(),
    height          ::String    ="400px",
    id              ::Union{String, Nothing}=nothing,
    onchange        ::Function  =(args...; kwargs...)->(),
    args            ::Vector    =Vector()
)::Widget
```

 Argument     | Description
------------------ | -----------
 `data`      | A `DataFrame` to be displayed.
 `column_config` | A `Dict` used to configure column behavior and appearance. Each entry of this `Dict` should be a column name paired with a `Dict` of configurations. These are the supported configuration options: <ul><li>`"editable"`: A `Bool`. If `true`, the cells of the column will be editable (double-click to edit). Default: `false`.</li><li>`"required"`: A `Bool` indicating wether a valid non-empty value is required. Default: `false`.</li></ul>
 `height`    | A `String` specifying the height of the table using a CSS value (for example, `"400px"`).
 `id`              | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `onchange`        | A callback `Function`. This function is called when any cell value changes, before the app script is rerun.
 `args`            | A `Vector` of arguments that should be passed to the `onchange` callback function.

### Return Value

The same `DataFrame` used as input (`data`).

### Example

The example below displays a `DataFrame` with two columns with different types
and makes the column `Age` editable:

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
"""
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

"""
# file_uploader

Creates a file input widget.

### Function Signature

```julia
function file_uploader(
    label           ::String;
    types           ::Vector{String}=Vector{String}(),
    multiple        ::Bool=false,
    max_file_size   ::Union{Int, Nothing}=nothing,
    max_files       ::Union{Int, Nothing}=nothing,
    fill_width      ::Bool=false,
    show_label      ::Bool=true,
    id              ::Union{String, Nothing}=nothing,
    onchange        ::Function=(args...; kwargs...)->(),
    args            ::Vector=Vector(),
    css             ::Dict=Dict()
)::Union{Vector{UploadedFile}, UploadedFile, Nothing}
```

 Argument     | Description
------------------ | -----------
 `label`        | A `String` to be displayed as the label for the file uploader. It can contain HTML.
 `types`        | A `Vector{String}` containing a list of acceptable file extensions and/or mimetypes. Example: `[".png", ".jpg", "application/pdf"]`. Tip: use `*` wildcard to accept all mimetypes begining with a prefix, e.g. `"image/*"`.
 `multiple`     | A `Bool` indicating wether to accept multiple files or not. Default `false`.
 `max_file_size`| An optional `Int` specifying the maximum file size accepted by the widget. If `nothing` (default), the limit set by `start_app()` is used.
 `max_files`    | An optional `Int` specifying the maximum number of file accepted by the widget. If `nothing` (default), the limit set by `start_app()` is used.
 `fill_width`   | A `Bool` indicating whether the widget should expand to fill the available horizontal space. Default: `false`.
 `show_label`   | A `Bool` indicating whether the label should be displayed. Default: `true`.
 `id`              | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `onchange`        | A callback `Function`. This function is called when any cell value changes, before the app script is rerun.
 `args`            | A `Vector` of arguments that should be passed to the `onchange` callback function.
 `css`          | A `Dict` of additional CSS properties applied to the widget element.

### Return Value

If `multiple` is `false`, a single [`UploadedFile`](#uploadedfile) instance is returned if a
file was provided. If `multiple` is `true`, a `Vector{UploadedFile}` is returned
if any file was provided. If no file was provided, it returns `nothing`.

## UploadedFile

```julia
mutable struct UploadedFile
    id              ::String # unique id of the file generated by the app
    name            ::String # name of the file
    extension       ::String # file extension
    path            ::String # file path inside `.Magic/uploaded-files`
    type            ::String # mimetype, e.g. "image/png"
    size            ::Int    # file size
    last_modified   ::Int    # last modification date timestamp
end
```

### Example

See [Image Filters Demo](https://magic.coisasdodavi.net/image-filters) for a
`file_uploader()` example.
"""
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

"""
# html

Render a raw HTML element.

### Function Signature

```julia
function html(
    tag         ::String,
    inner_html  ::String;
    attributes  ::Dict = Dict(),
    css         ::Dict = Dict()
)::Nothing
```

 Argument          | Description
------------------ | -----------
 `tag`             | A `String` specifying the HTML tag name to render (for example, `"div"`, `"span"`, or `"p"`).
 `inner_html`      | A `String` containing the raw HTML content to be placed inside the element.
 `attributes`      | A `Dict` of HTML attributes to apply to the element. Keys are attribute names and values are their corresponding values.
 `css`             | A `Dict` of CSS properties applied inline to the element.

### Return Value

Nothing.
"""
function html(tag::String, inner_html::String; attributes::Dict=Dict(), css::Dict=Dict())::Nothing
    create_html(top_container(), tag, inner_html, attributes, css)
    return nothing
end

"""
# link

Display a link styled as a button.

### Function Signature

```julia
function link(
    label      ::String,
    url        ::String;
    style      ::String = "secondary",
    fill_width ::Bool   = false,
    new_tab    ::Bool   = false,
    css        ::Dict   = Dict()
)::Nothing
```

 Argument        | Description
------------------ | -----------
 `label`        | A `String` to be displayed as the link text. It can contain HTML.
 `url`          | A `String` specifying the destination URL of the link.
 `style`        | A `String` defining the visual style of the link. Accepted values: `"primary"`, `"secondary"`, or `"naked"`. Default: `"secondary"`.
 `fill_width`   | A `Bool` indicating whether the link should expand to fill the available horizontal space. Default: `false`.
 `new_tab`      | A `Bool` indicating whether the link should open in a new browser tab. Default: `false`.
 `css`          | A `Dict` of CSS properties applied inline to the element.

### Return Value

Nothing.
"""
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

"""
# space

Inserts an empty space in the page.

### Function Signature

```julia
function space(; width::String="1px", height::String="1px")::Nothing
```

 Argument               | Description
---------------------- | -----------
 `width`    | A `String` specifying the width of the empty space using CSS units like `px` or `rem`.
 `height`    | A `String` specifying the height of the empty space using CSS units like `px` or `rem`.

### Return Value

Nothing.
"""
space(; width::String="1px", height::String="1px") = html("div", "", css=Dict("width" => width, "height" => height))

# Text, headers and icons
#-----------------------------
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

"""
# headers

Family of functions `h1`, `h2`, `h3`, `h4`, `h5` and `h6` to display the 6 different levels of heading.

### Function Signature

```julia
# same signature for h1, h2, h3, h4, h5 and h6

function h1(
    text        ::String;
    icon        ::String = "",
    icon_color  ::String = "",
    css         ::Dict   = Dict()
)::Nothing
```

 Argument        | Description
------------------ | -----------
 `text`         | A `String` containing the heading text. It can contain HTML.
 `icon`    | A `String` in the format `material/icon_name`. Example: `material/thumb_up`.<br/><br/>Check out https://fonts.google.com/icons?icon.set=Material+Icons to learn the icon names.
 `icon_color`   | An optional `String` specifying the color of the icon using a CSS color value.
 `css`          | A `Dict` of additional CSS properties applied to the heading element.

### Return Value

Nothing.
"""
h1(text::String; icon::String="", icon_color::String="", css=Dict()) = html("h1", maybe_prepend_icon(text, icon, icon_color), css=css)

@doc @doc(h1) h2
h2(text::String; icon::String="", icon_color::String="", css=Dict()) = html("h2", maybe_prepend_icon(text, icon, icon_color), css=css)

@doc @doc(h1) h3
h3(text::String; icon::String="", icon_color::String="", css=Dict()) = html("h3", maybe_prepend_icon(text, icon, icon_color), css=css)

@doc @doc(h1) h4
h4(text::String; icon::String="", icon_color::String="", css=Dict()) = html("h4", maybe_prepend_icon(text, icon, icon_color), css=css)

@doc @doc(h1) h5
h5(text::String; icon::String="", icon_color::String="", css=Dict()) = html("h5", maybe_prepend_icon(text, icon, icon_color), css=css)

@doc @doc(h1) h6
h6(text::String; icon::String="", icon_color::String="", css=Dict()) = html("h6", maybe_prepend_icon(text, icon, icon_color), css=css)

"""
# icon

Display an icon.

### Function Signature

```julia
function icon(
    icon   ::String;
    color  ::String = "inherit",
    size   ::String = "inherit",
    weight ::String = "inherit"
)::Nothing
```

 Argument    | Description
------------------ | -----------
 `icon`    | A `String` in the format `material/icon_name`. Example: `material/thumb_up`.<br/><br/>Check out https://fonts.google.com/icons?icon.set=Material+Icons to learn the icon names.
 `color`    | A `String` specifying the icon color using a CSS value. Default: `"inherit"`.
 `size`     | A `String` specifying the icon size using a CSS value. Default: `"inherit"`.
 `weight`   | A `String` specifying the icon weight or thickness, depending on the icon set. Default: `"inherit"`.

### Return Value

Nothing.
"""
icon(icon::String; color::String="inherit", size::String="inherit", weight::String="inherit") =
    html("mg-icon", "", attributes=Dict("mg-icon" => icon), css=Dict("color" => color, "font-size" => size, "font-weight" => "bold"))

"""
# text

Display a text.

### Function Signature

```julia
function text(text::Any)::Nothing
```

 Argument    | Description
------------------ | -----------
 `text`     | The content to be displayed. If the value is a `String`, it is rendered as-is. Otherwise, its string representation is obtained using `repr()`.

### Return Value

Nothing.
"""
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

"""
# code

Display a code block.

### Function Signature

```julia
function code(
    initial_value      ::String   = "";
    initial_value_file ::Union{String, Nothing} = nothing,
    fill_width         ::Bool     = true,
    max_width          ::String   = "100%",
    max_height         ::String   = "initial",
    padding            ::String   = "0",
    strip_whitespace   ::Bool     = true,
    css                ::Dict     = Dict("overflow-y" => "auto")
)::String
```

 Argument               | Description
---------------------- | -----------
 `initial_value`        | A `String` containing the initial code content to display.
 `initial_value_file`   | An optional path to a file whose contents will be loaded as the initial code value. If provided, it takes precedence over `initial_value`.
 `fill_width`           | A `Bool` indicating whether the code block should expand to fill the available horizontal space. Default: `true`.
 `max_width`            | A `String` specifying the maximum width of the code block using a CSS value (for example, `"100%"` or `"800px"`).
 `max_height`           | A `String` specifying the maximum height of the code block using a CSS value. If the content exceeds this height, it becomes scrollable.
 `padding`              | A `String` specifying the padding applied inside the code block using a CSS value.
 `strip_whitespace`     | A `Bool` indicating whether leading and trailing whitespace should be removed from the initial code content. Default: `true`.
 `css`                  | A `Dict` of additional CSS properties applied to the code block.

### Return Value

A `String` containing the current code content.
"""
function code(
    initial_value::String="";
    initial_value_file::Union{String, Nothing}=nothing,
    fill_width::Bool=true,
    max_width::String="100%",
    max_height::String="initial",
    padding::String="0",
    strip_whitespace::Bool=true,
    show_line_numbers::Bool=false,
    css::Dict=Dict("overflow-y" => "auto")
)::String

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
"""
# metric

Display a metric value with an optional delta indicator.

### Function Signature

```julia
function metric(
    label             ::String,
    value             ::String,
    delta             ::String = "",
    higher_is_better  ::Bool   = true
)::Nothing
```

 Argument               | Description
---------------------- | -----------
 `label`               | A `String` used as the label for the metric.
 `value`               | A `String` representing the main value of the metric.
 `delta`               | An optional `String` representing the change or difference associated with the metric (for example, `"+5%"` or `"-2"`).
 `higher_is_better`    | A `Bool` indicating whether an increase in the metric value should be considered positive. Default: `true`.

### Return Value

Nothing.
"""
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

DOC_WIDGET_VALUE = """
# Widget Value

You can get and set the value of uniquely identified widgets via the
[`get_value()`](#get_value) and [`set_value()`](#set_value) functions.

All widget creation functions accept a user-defined `id` as an argument.
A widget is uniquely identified if, at the moment of its creation, a user
defined `id` was provided. Example:

```julia
selectbox("Selectbox", initial_value="C", options=["A", "B", "C"], id="my_selectbox")
set_value("my_selectbox", "B")
value = get_value("my_selectbox") # value = "B"
````

`get_value()` can be called even before the creation of a widget, in which case
it will return either `missing` or, if the widget has a default value previously
set with [`set_default_value()`](#set_default_value), its default value. So, as you might have
guessed, `set_default_value()` can also be called before the creation of a
widget. Example:

```julia
set_default_value("my_selectbox", "B")
value = get_value("my_selectbox") # value = "B"
selectbox("Selectbox", options=["A", "B", "C"], id="my_selectbox")
````

The rationale behind this API behaviour is that, by setting a default value
before the creation of a widget, you can guarantee that `get_value()` will
always return the value of the widget, regardless if it has been already
created or not: if it has been created, it returns its actual value, and if it
hasn't been created yet, it returns the value it will be assigned when it is
created.

## `get_value()`

Retrieves the value of a uniquely identified widget.

### Function Signature

```julia
function get_value(id::String)::Any
```

 Argument  | Description
---------- |-------------
 `id` | User-defined widget id.

### Return Value

If a widget with the passed id already exists, it returns the value of the
widget.

If it doesn't exists yet but a default value has been assigned to it via
a previous call to `set_default_value()`, it returns the default value.

Otherwise, it returns `missing`.

## `set_value()`

Sets the value of a uniquely identified widget.

### Function Signature

```julia
function set_value(id::String, value::Any)::Nothing
```

 Argument  | Description
---------- |-------------
 `id` | User-defined widget id.
 `value` | The value that should be assigned to the widget. Its type must be compatible with the widget's kind.

## `get_default_value()`

Retrieves the default value of a uniquely identified widget. A widget has a
default value if, and only if, it has been assigned one via a
`set_default_value()` call.

### Function Signature

```julia
function get_default_value(id::String)::Any
```

 Argument  | Description
---------- |-------------
 `id` | User-defined widget id.

### Return Value

Returns the default value assigned to the widget associated with the `id` via
a previous call to `set_default_value()`.

## `set_default_value()`

Sets the default value of a uniquely identified widget.

### Function Signature

```julia
function set_default_value(id::String, value::Any)::Nothing
```

 Argument  | Description
---------- |-------------
 `id` | User-defined widget id.
 `value` | The default value that should be assigned to the widget. Its type must be compatible with the widget's kind.
"""

@doc DOC_WIDGET_VALUE set_default_value
function set_default_value(user_id::String, value::Any)::Nothing
    task = task_local_storage("app_task")
    task.session.widget_defaults[user_id] = value
    widget = get_widget_by_user_id(task.session.widgets, user_id)
    if widget !== missing
        widget.props["default_value"] = value
    end
    return nothing
end

@doc DOC_WIDGET_VALUE get_default_value
function get_default_value(user_id::String)::Any
    task = task_local_storage("app_task")
    if haskey(task.session.widget_defaults, user_id)
        return task.session.widget_defaults[user_id]
    end
    return missing
end

@doc DOC_WIDGET_VALUE set_value
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

@doc DOC_WIDGET_VALUE get_value
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
