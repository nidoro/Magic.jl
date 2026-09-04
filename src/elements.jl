# Button
#-----------
function create_button(
    widgets::Dict{String, Widget},
    parent::Dict,
    label::String,
    style::String,
    icon::String,
    onclick::Function,
    args::Union{Vector, Tuple},
    download_path::Union{String, Nothing},
    download_name::Union{String, Nothing}
)::Bool

    # Input validation
    #---------------------
    assert_string_in_list(@named(style), ("primary", "secondary", "naked"))

    if !isempty(icon)
        assert_valid_material_icon(@named(icon))
    end

    if !function_accepts_arg_count(onclick, length(args))
        throw(InvalidArgument(@named(onclick), "`onclick` should accept the same number of arguments passed in `args` ($(length(args)))."))
    end

    if !isnothing(download_path)
        if isfile(download_path)
            served_files_path = joinpath(get_dot_magic_path(), "served-files/")
            full_path = realpath(download_path)
            if !startswith(full_path, served_files_path)
                throw(InvalidArgument(@named(download_path), "The file to be downloaded must live inside .Magic at \"$(served_files_path)\".\nThese functions might help you: gen_serveable_path(...), make_serveable_copy(...), move_to_serveable_dir(...).\nCheck out the download_button() documentation to learn more."))
            end
            download_path = full_path
        else
            throw(InvalidArgument(@named(download_path), "The file does not exist or is not a file."))
        end
    end

    if !isnothing(download_name)
        if !is_valid_filename(download_name)
            throw(InvalidArgument(@named(download_name), "That is not a valid file name."))
        end
    end

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
    onclick ::Function  =()->(),
    args::Union{Vector, Tuple}=Vector()
)::Bool
```

 Argument  | Description
---------- |-------------
 `label`   | A `String` to be displayed inside the button. It can contain HTML.
 `style`   | A `String` specifying the predefined style to be applied to the button. Possible values: `primary`, `secondary` (default), or `naked`.
 `icon`    | A `String` in the format `material/icon_name`. Example: `material/thumb_up`.<br/><br/>Check out https://fonts.google.com/icons?icon.set=Material+Icons to learn the icon names.
 `onclick` | A callback `Function`. This function will be called when the button is clicked, before the app script is rerun.
 `args`    | A `Vector` of arguments that will be passed to the `onclick` callback function.

### Return Value

`true` if the button was clicked, `false` otherwise.
"""
function button(
    label::String="";
    style::String="secondary",
    icon::String="",
    onclick::Function=()->(),
    args::Union{Vector, Tuple}=Vector()
)::Bool

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
    onclick::Function=()->(),
    args::Union{Vector, Tuple}=Vector()
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

    # Input validation
    #-------------------
    default_value = maybe_get_default_value(user_id)
    if !isnothing(default_value) && !ismissing(default_value)
        if !(default_value isa AbstractString)
            throw(InvalidArgument(@named(default_value), "You tried to assign to a text_input a default value that is not an AbstractString."))
        end
    end

    props = Dict(
        "type" => "text_input",
        "user_id" => user_id,
        "label" => label,
        "default_value" => default_value,
        "initial_value" => initial_value,
        "placeholder" => placeholder,
        "css" => css,
    )

    if props["placeholder"] == nothing
        props["placeholder"] = coalesce(default_value, "")
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

    return coalesce(widget.value, default_value)
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
    num_type::Union{Type{<:Real}, Nothing},
    precision::Int,
    min::Union{Real, Nothing},
    max::Union{Real, Nothing},
    step::Real,
    decimal_separator::String,
    thousands_separator::String,
    css=Dict
)::Union{Real, Nothing}

    # Input validation
    #--------------------
    default_value = maybe_get_default_value(user_id)
    if !ismithing(default_value)
        if !(default_value isa Real)
            throw(InvalidArgument(@named(default_value), "You tried to assign to a number_input a default value that is not a Real."))
        end
    end

    # Infer num_type and enforce it
    #----------------------------------
    if isnothing(num_type)
        if     initial_value isa AbstractFloat num_type = typeof(initial_value)
        elseif default_value isa AbstractFloat num_type = typeof(default_value)
        elseif min isa AbstractFloat           num_type = typeof(min)
        elseif max isa AbstractFloat           num_type = typeof(max)
        elseif !ismithing(initial_value)       num_type = typeof(initial_value)
        elseif !ismithing(default_value)       num_type = typeof(default_value)
        else                                   num_type = Float64 end
    end

    if !ismithing(initial_value) initial_value = convert(num_type, initial_value) end
    if !ismithing(default_value) default_value = convert(num_type, default_value) end
    if !ismithing(min)           min           = convert(num_type, min) end
    if !ismithing(max)           max           = convert(num_type, max) end
    step                                       = convert(num_type, step)

    # Range validation
    if !ismithing(min) && !ismithing(max)
        if min >= max
            min_max = (min, max)
            throw(InvalidArgument(@named(min_max), "Invalid number_input interval. `min` should be lesser than `max`."))
        end
    end

    if !ismithing(min)
        if !ismithing(initial_value) initial_value = Base.max(min, initial_value) end
        if !ismithing(default_value) default_value = Base.max(min, default_value) end
    end

    if !ismithing(max)
        if !ismithing(initial_value) initial_value = Base.min(max, initial_value) end
        if !ismithing(default_value) default_value = Base.min(max, default_value) end
    end

    # Ensure step for integer type
    if num_type <: Integer
        if ismithing(step) step = one(num_type) end
    end

    props = Dict(
        "type" => "number_input",
        "user_id" => user_id,
        "label" => label,
        "default_value" => default_value,
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

    if isnothing(props["placeholder"])
        props["placeholder"] = coalesce(default_value, "")
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
        widget.value = !isnothing(initial_value) ? convert(num_type, initial_value) : nothing
        widgets[props["id"]] = widget
    end

    props["value"] = widget.value
    widget.props = props

    return coalesce(widget.value, default_value)
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
    num_type::Union{Type{<:Real}, Nothing}=nothing,
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
    num_type::Union{Type{<:Real}, Nothing},
    precision::Int,
    min::Real,
    max::Real,
    step::Union{Real, Nothing},
    decimal_separator::String,
    thousands_separator::String,
    css=Dict
)::Real

    # Input validation
    #--------------------
    default_value = maybe_get_default_value(user_id)
    if !ismithing(default_value)
        if !(default_value isa Real)
            throw(InvalidArgument(@named(default_value), "You tried to assign to a slider a default value that is not a Real."))
        end
    end

    # Infer num_type and enforce it
    #----------------------------------
    if isnothing(num_type)
        if     !ismithing(initial_value) num_type = typeof(initial_value)
        elseif !ismithing(default_value) num_type = typeof(default_value)
        else                             num_type = Float64 end
    end

    if !ismithing(initial_value) initial_value = convert(num_type, initial_value) end
    if !ismithing(default_value) default_value = convert(num_type, default_value) end
    if !ismithing(step)          step          = convert(num_type, step) end
    min                                        = convert(num_type, min)
    max                                        = convert(num_type, max)

    # Range validation
    if min >= max
        min_max = (min, max)
        throw(InvalidArgument(@named(min_max), "Invalid slider interval. `min` should be lesser than `max`."))
    end

    # Value clamping
    if !ismithing(initial_value) initial_value = clamp(initial_value, min, max) end
    if !ismithing(default_value) default_value = clamp(default_value, min, max) end

    # Ensure step for integer type
    if num_type <: Integer
        if ismithing(step) step = one(num_type) end
    end

    props = Dict(
        "type" => "slider",
        "user_id" => user_id,
        "label" => label,
        "default_value" => default_value,
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

    if isnothing(props["initial_value"])
        props["initial_value"] = coalesce(default_value, props["min"])
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
    initial_value::Union{Real, Nothing}=nothing,
    min::Real=0.0,
    max::Real=1.0,
    step::Union{Real, Nothing}=nothing,
    precision::Integer=2,
    num_type::Union{Type{<:Real}, Nothing}=nothing,
    decimal_separator::String=".",
    thousands_separator::String=",",
    show_label::Bool=true,
    fill_width::Bool=false,
    id::Any=nothing,
    css::Dict=Dict()
)::Real

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

    return create_slider(widgets, parent, id, label, initial_value, num_type, precision, min, max, step, decimal_separator, thousands_separator, css)
end

# Selectbox
#-----------
function create_selectbox(
    widgets::Dict{String, Widget},
    parent::Dict,
    user_id::Any,
    label::String,
    options::Union{Vector, Tuple},
    initial_value::Union{String, Number, Vector, Tuple, Nothing},
    multiple::Bool,
    placeholder::Union{String, Nothing},
    onchange::Function,
    args::Union{Vector, Tuple},
    css=Dict,
    caller_loc::String="",
)::Union{String, Number, Vector, Tuple, Nothing}

    # Input validation
    #---------------------

    # onchange validation
    if !function_accepts_arg_count(onchange, length(args))
        throw(InvalidArgument(@named(onchange), "`onchange` should accept the same number of arguments passed in `args` ($(length(args)))."))
    end

    # options validation
    if isempty(options)
        throw(InvalidArgument(@named(options), "`options` can't be empty"))
    end

    if !all(x -> x isa Union{String, Number}, options)
        throw(InvalidArgument(@named(options), "`options` contains elements that are not String or Number"))
    end

    # Default value validation
    default_value = maybe_get_default_value(user_id)
    if !isnothing(default_value) && !ismissing(default_value)
        if !multiple
            if default_value isa Union{String, Number}
                if !(default_value in options)
                    throw(InvalidArgument(@named(default_value), "$(caller_loc):\nYou tried to assign a default value to this selectbox that is not in the provided `options`."))
                end
            else
                throw(InvalidArgument(@named(default_value), "$(caller_loc):\nYou tried to assign a default value to this selectbox that is not a String or Number."))
            end
        else
            if default_value isa Union{Vector, Tuple}
                for v in default_value
                    if !(v in options)
                        throw(InvalidArgument(@named(default_value), "$(caller_loc):\nYou tried to assign a default value to this multiselect selectbox that contains entries that are not in the provided `options`."))
                    end
                end
            else
                throw(InvalidArgument(@named(default_value), "$(caller_loc):\nYou tried to assign a default value to this multiselect selectbox that is not a Vector or Tuple."))
            end
        end
    end

    # Initial value validation
    if !isnothing(initial_value)
        if !multiple
            if initial_value isa Union{String, Number}
                if !(initial_value in options)
                    throw(InvalidArgument(@named(initial_value), "$(caller_loc):\nYou tried to assign an initial value to this selectbox that is not in the provided `options`."))
                end
            else
                throw(InvalidArgument(@named(initial_value), "$(caller_loc):\nYou tried to assign an initial value to this selectbox that is not a String or Number."))
            end
        else
            if initial_value isa Union{Vector, Tuple}
                for v in initial_value
                    if !(v in options)
                        throw(InvalidArgument(@named(initial_value), "$(caller_loc):\nYou tried to assign an initial value to this multiselect selectbox that contains entries that are not in the provided `options`."))
                    end
                end
            else
                throw(InvalidArgument(@named(initial_value), "$(caller_loc):\nYou tried to assign an initial value to this multiselect selectbox that is not a Vector or Tuple."))
            end
        end
    end

    props = Dict(
        "type" => "selectbox",
        "user_id" => user_id,
        "default_value" => default_value,
        "initial_value" => initial_value,
        "label" => label,
        "options" => options,
        "multiple" => multiple,
        "placeholder" => placeholder,
        "css" => css,
    )

    if props["placeholder"] == nothing
        if !isnothing(default_value) && !ismissing(default_value)
            if typeof(default_value) == String
                props["placeholder"] = default_value
            elseif typeof(default_value) <: Number
                props["placeholder"] = repr(default_value)
            else
                props["placeholder"] = join([replace(option, "\"" => "") for option in repr.(default_value)], ", ")
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

    return coalesce(widget.value, default_value)
end

"""
# selectbox

Display a select box (dropdown) widget.

### Function Signature

```julia
function selectbox(
    label           ::String,
    options         ::Union{Vector, Tuple};
    initial_value   ::Union{String, Number, Vector, Tuple, Nothing}=nothing,
    id              ::Any                   =nothing,
    multiple        ::Bool                  =false,
    show_label      ::Bool                  =true,
    placeholder     ::Union{String, Nothing}=nothing,
    fill_width      ::Bool                  =false,
    onchange        ::Function              =()->(),
    args            ::Union{Vector, Tuple}  =Vector(),
    css             ::Dict                  =Dict()
)::Union{String, Vector, Nothing}
```

 Argument        | Description
------------------ | -----------
 `label`        | A `String` to be displayed as the label for the select box. It can contain HTML.
 `options`      | A `Vector` or `Tuple` of selectable options. Each element represents one option and will be displayed using its string representation.
 `initial_value`| The value(s) that should be initially selected. If `multiple` is `false` (default), this should be a `String` or `Number` in `options`. If `multiple` is `true`, the value should be a `Vector` of `String`s or `Number`s in `options`.
 `id`           | An optional identifier for the widget. If provided, it is used to uniquely identify the widget so you can reference it in other functions, like `get_value()` and `set_value()`.
 `multiple`     | A `Bool` indicating whether multiple options can be selected. Default: `false`.
 `show_label`   | A `Bool` indicating whether the label should be displayed. Default: `true`.
 `placeholder`  | A `String` shown as placeholder text when the selectbox is empty.
 `fill_width`   | A `Bool` indicating whether the select box should expand to fill the available horizontal space. Default: `false`.
 `onchange`     | A callback `Function`. This function is called when the selected value changes, before the app script is rerun.
 `css`          | A `Dict` of additional CSS properties applied to the select box element.

### Return Value

The currently selected value. If `multiple` is `false`, this is a `String`/`Number` value from `options` or `nothing`. If `multiple` is `true`, this is either a `Vector`/`Tuple` of selected values or `nothing`.
"""
function selectbox(
    label::String,
    options::Union{Vector, Tuple};
    initial_value::Union{String, Number, Vector, Tuple, Nothing}=nothing,
    id::Any=nothing,
    multiple::Bool=false,
    show_label::Bool=true,
    placeholder::Union{String, Nothing}=nothing,
    fill_width::Bool=false,
    onchange::Function=()->(),
    args::Union{Vector, Tuple}=Vector(),
    css::Dict=Dict()
)::Union{String, Number, Vector, Tuple, Nothing}

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

    return create_selectbox(widgets, parent, id, label, options, initial_value, multiple, placeholder, onchange, args, css, caller_location())
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

    # Input validation
    #----------------------
    default_value = maybe_get_default_value(user_id)
    if !ismithing(default_value)
        if default_value isa String
            normalized = normalize_html_color(default_value)
            if isnothing(normalized)
                throw(InvalidArgument(@named(default_value), "Not a valid hexadecimal color."))
            end
            default_value = normalized
        else
            throw(InvalidArgument(@named(default_value), "You tried to provide to a color_picker a default_value that is not a String."))
        end
    end

    if !isnothing(initial_value)
        normalized = normalize_html_color(initial_value)
        if isnothing(normalized)
            throw(InvalidArgument(@named(initial_value), "Not a valid hexadecimal color."))
        end
        initial_value = normalized
    else
        initial_value = coalesce(default_value, "#000000")
    end

    props = Dict(
        "type" => "color_picker",
        "user_id" => user_id,
        "default_value" => default_value,
        "initial_value" => initial_value,
        "label" => label,
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
    options::Union{Vector, Tuple},
    initial_value::Union{Vector, Tuple, Nothing},
    multiple::Bool,
    onchange::Function,
    args::Vector,
    caller_loc::String="",
)::Union{Bool, Vector, Tuple}

    # Input validation
    #--------------------

    # onchange validation
    if !function_accepts_arg_count(onchange, length(args))
        throw(InvalidArgument(@named(onchange), "`onchange` should accept the same number of arguments passed in `args` ($(length(args)))."))
    end

    # options validation
    if isempty(options)
        throw(InvalidArgument(@named(options), "`options` can't be empty"))
    end

    if !all(x -> x isa Union{String, Number}, options)
        throw(InvalidArgument(@named(options), "`options` contains elements that are not String or Number"))
    end

    # Default value validation
    default_value = maybe_get_default_value(user_id)
    if !isnothing(default_value) && !ismissing(default_value)
        if !multiple
            if !(default_value isa Bool)
                throw(InvalidArgument(@named(default_value), "$(caller_loc):\nYou tried to assign a default value to this checkbox that is not a Bool."))
            end
        else
            if default_value isa Union{Vector, Tuple}
                for v in default_value
                    if !(v in options)
                        throw(InvalidArgument(@named(default_value), "$(caller_loc):\nYou tried to assign a default value to this checkboxes that contains entries that are not in the provided `options`."))
                    end
                end
            else
                throw(InvalidArgument(@named(default_value), "$(caller_loc):\nYou tried to assign a default value to this checkboxes that is not a Vector or Tuple."))
            end
        end
    end

    # Initial value validation
    if !isnothing(initial_value)
        for v in initial_value
            if !(v in options)
                if multiple
                    throw(InvalidArgument(@named(initial_value), "$(caller_loc):\nYou tried to assign an initial value to this checkboxes that contains entries that are not in the provided `options`."))
                else
                    # UNREACHABLE: this should never happen because this is an internal function,
                    # so we are the ones setting an invalid parameter to initial_value.
                    throw(InvalidArgument(@named(initial_value), "$(caller_loc):\nWe tried to assign an initial value to this checkbox that is not a valid option. This is a Magic.jl bug, please report."))
                end
            end
        end
    end

    props = Dict(
        "type" => "checkboxes",
        "label" => label,
        "options" => options,
        "initial_value" => initial_value,
        "multiple" => multiple,
        "user_id" => user_id,
    )

    if isnothing(props["initial_value"])
        if !isnothing(default_value) && !ismissing(default_value)
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
    onchange      ::Function  = ()->(),
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
    onchange::Function=()->(),
    args::Vector=Vector()
)::Bool

    task = task_local_storage("app_task")
    widgets = task.session.widgets

    init_value = nothing

    if !isnothing(initial_value)
        init_value = initial_value ? Union{String, Number}[label] : Union{String, Number}[]
    end

    return create_checkboxes(widgets, top_container(), id, label, Union{String, Number}[label], init_value, false, onchange, args, caller_location())
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
    onchange        ::Function  =()->(),
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
    options::Union{Vector, Tuple};
    id::Any=nothing,
    initial_value::Union{Vector, Tuple, Nothing}=nothing,
    onchange::Function=()->(),
    args::Vector=Vector()
)::Union{Vector, Tuple}

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
    options::Union{AbstractVector, Tuple},
    initial_value::Union{String, Number, Nothing},
    caller_loc::String="",
)::Union{String, Number, Nothing}

    # Input validation
    #----------------------
    if isempty(options)
        throw(InvalidArgument(@named(options), "$(caller_loc):\n`options` can't be empty."))
    end

    if !all(entry -> entry isa Union{String, Number}, options)
        throw(InvalidArgument(@named(options), "$(caller_loc):\n`options` contains elements that are not String or Number."))
    end

    default_value = maybe_get_default_value(user_id)
    if !isnothing(default_value) && !ismissing(default_value)
        if !(default_value isa Union{String, Number})
            throw(InvalidArgument(@named(default_value), "$(caller_loc):\nYou tried to assign a default value to this radio that is not a String or Number."))
        end
        if !(default_value in options)
            throw(InvalidArgument(@named(default_value), "$(caller_loc):\nYou tried to assign a default value to this radio that is not one of the possible radio values provided in `options`."))
        end
    end

    if !isnothing(initial_value)
        if !(initial_value in options)
            throw(InvalidArgument(@named(initial_value), "$(caller_loc):\nYou tried to assign an initial value to this radio that is not one of the possible radio values provided in `options`."))
        end
    end

    props = Dict(
        "type" => "radio",
        "label" => label,
        "options" => options,
        "user_id" => user_id,
        "initial_value" => initial_value,
    )

    if isnothing(props["initial_value"])
        props["initial_value"] = coalesce(default_value, options[1])
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
    options::Union{AbstractVector, Tuple};
    id::Any=nothing,
    initial_value::Union{String, Number, Nothing}=nothing
)::Union{String, Number, Nothing}

    task = task_local_storage("app_task")
    widgets = task.session.widgets
    return create_radio(widgets, top_container(), id, label, options, initial_value, caller_location())
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
 `src_or_path`    | A `String` representing either an image URL or a local file path to the image source.<br/><br/>Only images inside `.Magic/served-files` and subdirectories can be served. If it is a static image that does not change across sessions, a good practice is to place it inside `.Magic/served-files/static/images`. If it is a generated image, e.g. a plot that changes across app reruns, a good practice is to place it inside `.Magic/served-files/cache`.<br/><br/>For the common situation of regenerating and serving a new image on each rerun, there is a helper function `gen_serveable_path(ext)` that generates a file path with a random name and with the given extension `ext` inside `.Magic/served-files/cache`. This function returns the path that you should use to save your image and then pass to `image()` to place it in the app.
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

    if isfile(src_or_path)
        src_or_path = realpath(src_or_path)
        if !startswith(src_or_path, "$(g.dot_magic_dir)/.Magic/served-files")
            src_or_path = make_serveable_copy(src_or_path)
        end
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

    # Input validation
    #---------------------
    if max_file_size <= 0
        throw(InvalidArgument(@named(max_file_size), "max_file_size must be a number greater than 0."))
    end

    if max_files <= 0
        throw(InvalidArgument(@named(max_files), "max_files must be a number greater than 0."))
    end

    # onchange validation
    if !function_accepts_arg_count(onchange, length(args))
        throw(InvalidArgument(@named(onchange), "`onchange` must accept the same number of arguments passed in `args` ($(length(args)))."))
    end

    for t in types
        if !is_valid_mime_or_extension(t)
            throw(InvalidArgument(@named(types), "Invalid file type: \"$(t)\". Each type in `types` must be a valid mimetype (e.g. \"image/png\", \"image/*\") or extension (e.g. \".png\")."))
        end
    end

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

    widget = nothing

    if haskey(widgets, props["id"])
        widget = widgets[props["id"]]
        widget.alive = true
        props = widget.props
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
        props["error"] = nothing
    end

    if !ismithing(widget.value)
        props["value"] = safe_serialization(widget.value)
    else
        props["value"] = nothing
    end
    widget.props = props

    push!(parent["children"], props)

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
    onchange        ::Function=()->(),
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
    onchange::Function=()->(),
    args::Vector=Vector(),
    css::Dict=Dict(),
)::Union{Vector{UploadedFile}, UploadedFile, Nothing}

    max_file_size = isnothing(max_file_size) ? g.upload_max_size : max_file_size
    max_files = !multiple ? 1 : max_files
    max_files = isnothing(max_files) ? g.upload_max_files : max_files

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

function make_uploaded_file(file_path::String)::UploadedFile
    if !isfile(file_path) throw(InvalidArgument(@named(file_path), "`file_path` must be a valid existing file.")) end

    file_path = realpath(file_path)

    result = UploadedFile()
    result.id = "file_" * get_random_string(32-length("file_")-1)
    result.name = basename(file_path)
    result.extension = splitext(result.name)[2]
    result.path = file_path
    result.type = get_mime_type(file_path)
    info = stat(file_path)
    result.size = info.size
    result.last_modified = floor(Int, info.mtime)
    return result
end

function safe_serialization(uploaded_file::UploadedFile)::Dict
    # Returns a "serialization" of UploadedFile that is safe to be sent back
    # to the client.
    return Dict(
        "id" => uploaded_file.id,
        "name" => uploaded_file.name,
        "extension" => uploaded_file.extension,
        "type" => uploaded_file.type,
        "size" => uploaded_file.size,
        "last_modified" => uploaded_file.last_modified,
    )
end

function safe_serialization(uploaded_files::Union{Vector, Tuple})::Vector{Dict}
    result = Vector{Dict}()
    for uploaded_file in uploaded_files
        push!(result, safe_serialization(uploaded_file))
    end
    return result
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
    # Input validation
    #---------------------
    assert_string_in_list(@named(style), ("primary", "secondary", "naked"))

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
        assert_valid_material_icon(@named(icon))

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
function icon(icon::String; color::String="inherit", size::String="inherit", weight::String="inherit")::Nothing
    assert_valid_material_icon(@named(icon))
    html("mg-icon", "", attributes=Dict("mg-icon" => icon), css=Dict("color" => color, "font-size" => size, "font-weight" => "bold"))
    return nothing
end

"""
# text

Display a text.

### Function Signature

```julia
function text(anything::Any)::Nothing
```

 Argument    | Description
------------------ | -----------
 `text`     | The content to be displayed. If the value is a `AbstractString`, it is rendered as-is. Otherwise, its string representation is obtained using `repr()`.

### Return Value

Nothing.
"""
text(anything::Any) = html("p", anything isa AbstractString ? anything : repr(anything))

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

    if !isnothing(initial_value_file)
        initial_value = assert_valid_utf8_file(@named(initial_value_file))
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
function create_metric(
    label::String,
    value_html::String,
    delta_html::Union{String, Nothing},
    delta_color::Union{String, Nothing},
    delta_background::Union{String, Nothing}
)::Nothing

    @push column(gap="0")
        html("label", label, css=Dict("font-size" => "0.85rem"))
        html("span", value_html, css=Dict("font-size" => "1.8rem"))
        if !isnothing(delta_html)
            html(
                "span",
                delta_html,
                css=Dict(
                    "font-size" => "0.85rem",
                    "color" => delta_color,
                    "background" => delta_background,
                    "border-radius" => "100vw",
                    "padding" => ".2em .4em",
                    "display" => "flex",
                    "align-items" => "center"
                )
            )
        end
    @pop

    return nothing
end

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
function metric(
    label::String,
    value::Real,
    unit::String="";
    delta::Union{Real, Nothing}=nothing,
    delta_unit::Union{String, Nothing}=nothing,
    higher_is_better::Bool=true,
    precision::Union{Int, Nothing}=nothing,
    delta_precision::Union{Int, Nothing}=nothing,
    thousands_separator::String="",
    decimal_separator::String=".",
)::Nothing

    if isnothing(delta_unit)
        delta_unit = unit
    end

    if isnothing(delta_precision)
        delta_precision = precision
    end

    delta_html = nothing
    color, background = "#555555", "#dddddd"

    if !isnothing(delta)
        if higher_is_better
            if delta > 0
                color, background = "#0b8a07", "#a6f9a6"
            elseif delta < 0
                color, background = "#bf0b0b", "#fbacac"
            end
        else
            if delta > 0
                color, background = "#bf0b0b", "#fbacac"
            elseif delta < 0
                color, background = "#0b8a07", "#a6f9a6"
            end
        end

        icon = "material/trending_flat"

        if delta > 0
            icon = "material/arrow_upward"
        elseif delta < 0
            icon = "material/arrow_downward"
        end

        icon_html = "<mg-icon mg-icon='$icon' style='font-size: 1.1em; color: $color; background: $background'></mg-icon>"
        delta_html = icon_html * " " * stringify(delta, precision=delta_precision, decimal_separator=decimal_separator, thousands_separator=thousands_separator) * delta_unit
    end

    value_html = stringify(value, precision=precision, decimal_separator=decimal_separator, thousands_separator=thousands_separator) * unit

    return create_metric(label, value_html, delta_html, color, background)
end

metric(label::String, value::String)::Nothing = create_metric(label, value, nothing, nothing, nothing)

# Misc
#---------
maybe_get_default_value = (user_id::Union{String, Nothing}) -> (user_id != nothing ? get_default_value(user_id) : nothing)

function get_widget_by_user_id(widgets::Dict{String, Widget}, user_id::String)::Union{Widget, Missing}
    for widget in values(widgets)
        if widget.user_id == user_id
            return widget
        end
    end
    return missing
end

function get_widget_by_label(client_id::Cint, label::String)::Union{Widget, Missing}
    session = get_session(client_id)

    for widget in values(session.widgets)
        props = widget.props
        if haskey(props, "label") && props["label"] == label
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

function get_widget_default_value(session::Session, user_id::String)::Any
    if haskey(session.widget_defaults, user_id)
        return session.widget_defaults[user_id]
    end
    return missing
end

@doc DOC_WIDGET_VALUE get_default_value
function get_default_value(user_id::String)::Any
    task = task_local_storage("app_task")
    return get_widget_default_value(task.session, user_id)
end

@doc DOC_WIDGET_VALUE set_value
function set_value(user_id::String, value::Any)::Any
    task = task_local_storage("app_task")
    widget = get_widget_by_user_id(task.session.widgets, user_id)
    if !ismithing(widget)
        if widget.kind == WidgetKind_Selectbox
            if !isnothing(value)
                if !widget.props["multiple"]
                    if value isa Union{String, Number}
                        if value in widget.props["options"]
                            widget.value = value
                        else
                            throw(InvalidArgument(@named(value), "You tried to assign to a selectbox a value that is not one of the options of the selecbox."))
                        end
                    else
                        throw(InvalidArgument(@named(value), "You tried to assign to a selectbox a value is not a String or Number."))
                    end
                else
                    if value isa Union{Vector, Tuple}
                        for v in value
                            if !(v in widget.props["options"])
                                throw(InvalidArgument(@named(value), "You tried to assign to a multiselect selectbox one or more values that are not one of the options of the selecbox: `$(v)`."))
                            end
                        end
                        widget.value = value
                    else
                        throw(InvalidArgument(@named(value), "You tried to assign to a multiselect selectbox a value is not a Vector or Tuple."))
                    end
                end
            else
                widget.value = value
            end
        elseif widget.kind == WidgetKind_Checkboxes
            if !isnothing(value)
                if !widget.props["multiple"]
                    if value isa Bool
                        widget.value = value
                    else
                        throw(InvalidArgument(@named(value), "You tried to assign to a checkbox a value is not a Bool."))
                    end
                else
                    if value isa Union{Vector, Tuple}
                        for v in value
                            if !(v in widget.props["options"])
                                throw(InvalidArgument(@named(value), "You tried to assign to a checkboxes one or more values that are not one of the options of the checkboxes: `$(v)`."))
                            end
                        end
                        widget.value = value
                    else
                        throw(InvalidArgument(@named(value), "You tried to assign to a checkboxes a value is not a Vector or Tuple."))
                    end
                end
            else
                if !widget.props["multiple"]
                    widget.value = false
                else
                    widget.value = []
                end
            end
        elseif widget.kind == WidgetKind_Radio
            if !isnothing(value)
                if value isa Union{String, Number}
                    if value in widget.props["options"]
                        widget.value = value
                    else
                        throw(InvalidArgument(@named(value), "You tried to assign to a radio a value is not one of its possible value options."))
                    end
                else
                    throw(InvalidArgument(@named(value), "You tried to assign to a radio a value is not a String or Number."))
                end
            else
                widget.value = widget.props["options"][1]
            end
        elseif widget.kind == WidgetKind_TextInput
            if !isnothing(value)
                if value isa AbstractString
                    widget.value = value
                else
                    throw(InvalidArgument(@named(value), "You tried to assign to a text_input a value is not an AbstractString."))
                end
            else
                widget.value = nothing
            end
        elseif widget.kind == WidgetKind_NumberInput
            if !isnothing(value)
                if value isa Real
                    widget.value = convert(widget.props["num_type"], value)
                    if !ismithing(widget.props["min"]) widget.value = convert(widget.props["num_type"], max(widget.value, widget.props["min"])) end
                    if !ismithing(widget.props["max"]) widget.value = convert(widget.props["num_type"], min(widget.value, widget.props["max"])) end
                else
                    throw(InvalidArgument(@named(value), "You tried to assign to a number_input a value is not an Real."))
                end
            else
                widget.value = nothing
            end
        elseif widget.kind == WidgetKind_Slider
            if !isnothing(value)
                if value isa Real
                    widget.value = convert(widget.props["num_type"], clamp(value, widget.props["min"], widget.props["max"]))
                else
                    throw(InvalidArgument(@named(value), "You tried to assign to a slider a value is not an Real."))
                end
            else
                widget.value = widget.props["min"]
            end
        elseif widget.kind == WidgetKind_FileUploader
            if !isnothing(value)
                if !widget.props["multiple"]
                    if value isa UploadedFile
                        # TODO: check if the value is valid, i.e., validate the value of each struct field.
                        widget.value = value
                    else
                        throw(InvalidArgument(@named(value), "You tried to assign to a file_uploader a value is not an UploadedFile."))
                    end
                else
                    if value isa Union{Vector, Tuple}
                        for up in value
                            if up isa UploadedFile
                                # TODO: check if the value is valid, i.e., validate the value of each struct field.
                                widget.value = value
                            else
                                throw(InvalidArgument(@named(value), "You tried to assign to a file_uploader a value is not an UploadedFile."))
                            end
                        end
                    else
                        throw(InvalidArgument(@named(value), "You tried to assign to a multi-file file_uploader a value is not a Vector or Tuple."))
                    end
                end
            else
                widget.value = nothing
            end

            widget.props["error"] = nothing
        elseif widget.kind == WidgetKind_ColorPicker
            if !isnothing(value)
                if value isa String
                    normalized = normalize_html_color(value)
                    if isnothing(normalized)
                        throw(InvalidArgument(@named(value), "Not a valid hexadecimal color."))
                    end
                    widget.value = normalized
                else
                    throw(InvalidArgument(@named(value), "You tried to assign to a color_picker a value that is not a String."))
                end
            else
                widget.value = coalesce(widget.props["default_value"], "#000000")
            end
        else
            widget.value = value
        end
    else
        throw(InvalidArgument(@named(user_id), "No widget with this id was found: \"$(user_id)\"."))
    end

    if widget.value isa UploadedFile
        # NOTE: The reason why we don't assign widget.value to props["value"]
        # when value is an UploadedFile is not because of serialization, because
        # JSON can serialize structs just fine, but because UploadedFile holds
        # server-side information, like path. From a security stand-point,
        # giving away such information is not good, even though it is not
        # automatically critially bad.
        widget.props["value"] = safe_serialization(widget.value)
    else
        widget.props["value"] = widget.value
    end

    return widget.value
end

function get_widget_value(session::Session, user_id::String)::Any
    widget = get_widget_by_user_id(session.widgets, user_id)
    if widget === missing
        return get_widget_default_value(session, user_id)
    elseif widget.value === nothing
        def_value = get_widget_default_value(session, user_id)
        if def_value !== missing
            return def_value
        else
            return nothing
        end
    end
    return widget.value
end

@doc DOC_WIDGET_VALUE get_value
function get_value(user_id::String)::Any
    task = task_local_storage("app_task")
    return get_widget_value(task.session, user_id)
end

function get_widget_value(client_id::Cint, user_id::String)::Any
    session = get_session(client_id)
    return get_widget_value(session, user_id)
end

function get_changes(user_id::String)::Union{Missing, Dict{Int, Dict{String, Any}}}
    task = task_local_storage("app_task")
    widget = get_widget_by_user_id(task.session.widgets, user_id)
    if widget === missing
        return missing
    end
    return widget.changes
end
