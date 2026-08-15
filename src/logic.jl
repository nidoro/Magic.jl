
# Fragment
#-----------------------
@with_kw mutable struct Fragment
    id              ::String   = ""
    func            ::Function = ()->()
    container_props ::Dict     = Dict()
end

function push_fragment(frag::Fragment)::Nothing
    task = task_local_storage("app_task")
    push!(task.fragment_stack, frag)
    return nothing
end

function pop_fragment()::Fragment
    task = task_local_storage("app_task")
    return pop!(task.fragment_stack)
end

function top_fragment()::Fragment
    task = task_local_storage("app_task")
    return task.fragment_stack[end]
end

function fragment(func::Function; id::String=String(nameof(func)))
    task = task_local_storage("app_task")

    wrapper = create_container(top_container(), Dict("display" => "contents", "flex-direction" => get_css_value(top_container(), "flex-direction")), Dict(), id, true)

    frag = Fragment()
    frag.id = id
    frag.func = func
    frag.container_props = wrapper.container

    task.session.fragments[id] = frag

    push_fragment(frag)
    push_container(wrapper)
    func()
    pop_container()
    pop_fragment()
end

macro fragment(block)
    file = replace(String(__source__.file), r"[^A-Za-z0-9]" => "_")
    name = Symbol("fragment_", file, "_", __source__.line)
    return :(
        Magic.fragment(function $(esc(name))()
            $(esc(block))
        end)
    )
end

# Session
#-------------
@with_kw mutable struct RerunRequest
    payload::Dict = Dict()
end

@with_kw struct RerunError
    message     ::String = ""
    stacktrace  ::String = ""
end

@with_kw mutable struct Session
    client_id                   ::Cint                      = 0
    session_id                  ::String                    = ""
    widgets                     ::Dict{String, Widget}      = Dict{String, Widget}()
    fragments                   ::Dict{String, Fragment}    = Dict{String, Fragment}()
    location                    ::Dict                      = Dict()
    user_session_data           ::Any                       = nothing
    first_pass                  ::Bool                      = true
    widget_defaults             ::Dict{String, Any}         = Dict{String, Any}()
    rerun_task                  ::Union{Task, Nothing}      = nothing
    rerun_queue                 ::Vector{RerunRequest}      = Vector{RerunRequest}()
    waiting_invalid_state_ack   ::Bool                      = false
    client_left                 ::Bool                      = false
    rerun_error                 ::Union{RerunError, Nothing} = nothing
    refresh                     ::Bool                      = false
    app_mod                     ::Module                    = Module(:MagicApp)
end

function get_session_data()::Any
    task = task_local_storage("app_task")
    return task.session.user_session_data
end

function set_session_data(session_data::Any)::Nothing
    task = task_local_storage("app_task")
    task.session.user_session_data = session_data
    return nothing
end

function is_session_first_pass()::Bool
    task = task_local_storage("app_task")
    return task.session.first_pass
end

macro session_startup(block)
    return :(
        if Magic.is_session_first_pass()
            $(esc(block))
        end
    )
end

function get_url_path()::String
    task = task_local_storage("app_task")
    return task.session.location["pathname"]
end

# PageConfig
#---------------------
@with_kw mutable struct PageConfig
    id              ::String = ""
    uris            ::Vector{String} = Vector{String}()
    title           ::String = "Magic App"
    description     ::String = "Web app made with Magic.jl"
    style           ::String = ""
    file_path       ::String = ""
    first_pass      ::Bool   = true
    user_page_data  ::Any    = nothing

    set_title       ::Function = (args...; kwargs...)->()
    set_description ::Function = (args...; kwargs...)->()
    add_font        ::Function = (args...; kwargs...)->()
    add_css_rule    ::Function = (args...; kwargs...)->()
end

function define_page_config_func(page, func_name)
    f = function(args...; kwargs...)
        begin_page_config(page)
        getfield(Magic, func_name)(page, args...; kwargs...)
        end_page_config()
        return page
    end

    setfield!(page, func_name, f)
end

function get_page(uri)::Union{PageConfig, Missing}
    for page in g.pages
        if uri in page.uris
            return page
        end
    end
    return missing
end

function get_page_data()::Any
    page = get_page(get_url_path())
    return page.user_page_data
end

function set_page_data(page_data::Any)::Nothing
    page = get_page(get_url_path())
    page.user_page_data = page_data
    return nothing
end

function add_page(inner_func::Union{Function, Nothing}, uri::Union{String, Vector{String}}; title::String="", description::String="")::PageConfig
    page = PageConfig()
    page.id = get_random_string(6)
    page.uris = uri isa Vector{String} ? uri : [uri]
    page.title = title
    page.description = description

    for func in [:set_title, :set_description, :add_font, :add_css_rule]
        define_page_config_func(page, func)
    end

    push!(g.pages, page)

    if inner_func != nothing
        begin_page_config(page)
        inner_func()
        end_page_config()
    end

    return page
end

add_page(uri::Union{String, Vector{String}}; title::String="", description::String="") = add_page(nothing, uri, title=title, description=description)

function add_css_rule(page::PageConfig, style::String)::Nothing
    page.style *= style
    return nothing
end

function add_css_rule(style::String)::Nothing
    task = task_local_storage("app_task")
    return add_css_rule(task.current_page, style)
end

function strip_prefix(str::String, prefix::String)::String
    if startswith(str, prefix)
        return replace(str, prefix => "")
    end
    return str
end

function add_font(page::PageConfig, font_name::String, src_or_path::String)::Nothing
    add_css_rule(page, """
        @font-face {
            font-family: "$(font_name)";
            src: url($(strip_prefix(src_or_path, ".Magic/served-files")));
        }
    """)
    return nothing
end

function add_font(font_name::String, src_or_path::String)::Nothing
    task = task_local_storage("app_task")
    add_font(task.current_page, font_name, src_or_path)
    return nothing
end

function set_title(page::PageConfig, title::String)::Nothing
    page.title = title
    return nothing
end

function set_title(title::String)::Nothing
    task = task_local_storage("app_task")
    return set_title(task.current_page, title)
end

function set_description(page::PageConfig, description::String)::Nothing
    page.description = description
    return nothing
end

function set_description(description::String)::Nothing
    task = task_local_storage("app_task")
    return set_description(task.current_page, description)
end

function begin_page_config(page::PageConfig)::Nothing
    task = task_local_storage("app_task")
    task.current_page = page
    return nothing
end

function end_page_config()::Nothing
    task = task_local_storage("app_task")
    task.current_page = g.base_page_config
    return nothing
end

function create_page_html(page::PageConfig, output_path::String)::Nothing
    template = read(joinpath(@__DIR__, "../served-files/MagicPageTemplate.html"), String)

    title = length(page.title) > 0 ? page.title : g.base_page_config.title
    description = length(page.description) > 0 ? page.description : g.base_page_config.description

    page_html = replace(
        template,
        "<title>Magic App</title>" => "<title>$(title)</title>",
        "<meta property=\"og:description\" content=\"Web app made with Magic.jl\">" => "<meta property=\"og:description\" content=\"$(description)\">",
        "<!-- MAGIC PAGE STYLE -->" => "<style>$(page.style)</style>"
    )

    write(output_path, page_html)
    page.file_path = output_path
    return nothing
end

function create_404_html(output_path::String)::Nothing
    template = read(joinpath(@__DIR__, "../served-files/Magic404Template.html"), String)

    title = g.base_page_config.title
    description = g.base_page_config.description

    page_html = replace(
        template,
        "<title>Magic App</title>" => "<title>$(title)</title>",
        "<meta property=\"og:description\" content=\"Web app made with Magic.jl\">" => "<meta property=\"og:description\" content=\"$(description)\">",
    )

    write(output_path, page_html)
    return nothing
end

function is_page_first_pass()::Bool
    page = get_current_page()
    if page !== missing
        return page.first_pass
    end
    return false
end

macro page_startup(block)
    return :(
        if Magic.is_page_first_pass()
            Magic.begin_page_config(get_page(get_url_path()))
            $(esc(block))
            Magic.end_page_config()
        end
    )
end

get_current_page()::Union{PageConfig, Missing} = get_page(get_url_path())
function is_on_page(page_path::String)::Bool
    page = get_current_page()
    if page !== missing
        return page_path in page.uris
    end
    return false
end

# App data
#--------------
function get_app_data()::Any
    return g.user_app_data
end

function set_app_data(app_data::Any)::Nothing
    g.user_app_data = app_data
    return nothing
end

# Misc
#------------
function get_random_string(n::Integer)::String
    CHARSET = ['0':'9'; 'A':'Z'; 'a':'z']
    return String(rand(CHARSET, n))
end

function gen_serveable_path(extension::String=""; lifetime::String="session")::String
    task = task_local_storage("app_task")
    if length(extension) > 0
        if extension[1] != '.'
            extension = '.' * extension
        end
    end

    file_name = "$(get_random_string(32))$(extension)"

    dir_path = ".Magic/served-files/generated/$(task.session.session_id)"
    if lifetime == "app"
        dir_path = ".Magic/served-files/generated/app"
    end

    return "$(dir_path)/$(file_name)"
end

function make_serveable_copy(file_path::String; lifetime::String="session")::String
    serveable_path = gen_serveable_path(lifetime=lifetime) * splitext(file_path)[2]
    cp(file_path, serveable_path, force=true)
    return serveable_path
end

function move_to_serveable_dir(file_path::String; lifetime::String="session")::String
    serveable_path = gen_serveable_path(lifetime=lifetime) * splitext(file_path)[2]
    mv(file_path, serveable_path, force=true)
    return serveable_path
end

function is_app_first_pass()::Bool
    return g.first_pass
end

macro app_startup(block)
    return :(
        if Magic.is_app_first_pass()
            $(esc(block))
        end
    )
end

# DEPRECATED: once
#--------------------
macro once(def)
    struct_name = def.args[2]

    return esc(quote
        if haskey(Magic.USER_TYPES, $(QuoteNode(struct_name)))
            global $struct_name = Magic.USER_TYPES[$(QuoteNode(struct_name))]
        else
            $def

            Magic.USER_TYPES[$(QuoteNode(struct_name))] = $struct_name
        end
    end)
end
