"""
# First pass functions

Family of `Bool` returning functions:

- `is_app_first_pass()`: returns `true` it is the first time the app is being
run, and `false` otherwise. See also: `@app_startup`.
- `is_page_first_pass()`: returns `true` it is the first time the current page
is being run, and `false` otherwise. See also: `@page_startup`.
- `is_session_first_pass()`: returns `true` it is the first time the session
is being run, and `false` otherwise. See also: `@session_startup`.
"""
function is_app_first_pass()::Bool
    return g.first_pass
end

"""
# @app_startup

Macro to define a code block that should only be executed at the startup of the
application (app dry-run). Usage:

```julia
@app_startup begin
    # app initialization logic
end
```

Internally, this macro is implemented by checking the result of
[`is_app_first_pass()`](/docs/build/docs/api-reference/application-logic/is_first_pass-func)
and running the `@app_startup` code block only if it returns `true`.

## Usage

You can define multiple `@app_startup` code blocks, but we recommend you to keep
all of your app initialization logic inside a single `@app_startup` block near
the top of your entry-point script (`app.jl` by default).

Although apps are not required to have `@app_startup` code blocks, some
initialization tasks should be only performed inside `@app_startup`
code blocks. See below what you are expected to do inside `@app_startup` code blocks.

### 1. Definition of the app pages

> **🛈 NOTE**: This is only needed if your app has multiple pages.

```julia
@app_startup begin
    add_page("/first-page")
    add_page("/second-page")
    add_page("/third-page")
end
```

### 2. Initialization of app persistent data

App persistent data is an user defined data whose lifetime is the lifetime of
the app, i.e., as long as the app is running the data will persist. App
persistent data can be retrieved at any moment using `get_app_data()` and is
shared accross sessions.

You can store data that you want to be globally available through all of your
app's pages and sessions via the `set_app_data()` function, and retrieve it
using the `get_app_data()` function.
See [App persistent data](/docs/build/docs/api-reference/application-logic/app-persistent-data)
to learn more.

## See also

- [`@page_startup`](/docs/build/docs/api-reference/application-logic/page_startup-macro)
- [`@session_startup`](/docs/build/docs/api-reference/application-logic/session_startup-macro)
"""
macro app_startup(block)
    return :(
        if Magic.is_app_first_pass()
            $(esc(block))
        end
    )
end

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

"""
# Fragments

A fragment is a function that can be rerun independently of the full app. It
can be created using the the `fragment()` function or the `@fragment` macro.

Use fragments to avoid rerunning the entire app script on every widget
interaction.

### The `fragment()` function

Turns a function into a fragment.

#### Function Signature

```julia
function fragment(func::Function; id::String=String(nameof(func)))
```

 Argument  | Description
---------- |-------------
 `func`   | The `Function` that will be isolated from the rest of the app.
 `id`   | A `String` to uniquely identify the fragment.

### The `@fragment` macro

Turns a code block into a fragment. Usage:

```julia
@fragment begin
    # code block
end
```

Internally, `@fragment` creates a function with the passed code block as its
body, and then calls the function `fragment()` to register the function as
a fragment.

## Example

[Live example here](https://magic.coisasdodavi.net/fragment-example).

```julia
using Magic

@once mutable struct SessionData
    app_reruns::Int
    fragment_reruns::Int
end

@session_startup begin
    session = SessionData(0, 0)
    set_session_data(session)
end

session = get_session_data()
button("Outside Button")
session.app_reruns += 1
text("App reruns: \$(session.app_reruns)")

@fragment begin
    session = get_session_data()
    button("Inside Button")
    session.fragment_reruns += 1
    text("Fragment reruns: \$(session.fragment_reruns)")
end
```

In the above example, everytime the `Outside Button` is clicked, both counters
`session.app_reruns` and `session.fragment_reruns` are incremented. But when
the `Inside Button` is clicked, only the `session.fragment_reruns` counter is
incremented.
"""
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

@doc @doc(fragment)
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

"""
# Session persistent data

Session persistent data is an user defined data that is bound to a session and
whose lifetime is the lifetime of the session, i.e., as long as the session
stays active the data will persist. Session persistent data can be retrieved at
any moment using `get_session_data()` and is only visible to the current
session.

Although the session persistent data can be either mutable or immutable, a
common practice is to define a mutable struct to store all of your sessions's
data and store it with `set_session_data()` at the session startup. Example:

```julia
# Define the struct to hold the session persistent data
mutable struct SessionData
    foo::String
    bar::Int
end

@session_startup begin
    # Initialize the session persistent data
    session = SessionData("hello", 32)
    set_session_data(session)
end

# now `get_session_data()` can be called from anywhere
# to retrieve the current session data
```

In the example above, since the persistent data is a mutable struct, every time
`get_session_data()` is called the same `SessionData` object instance stored with
`set_session_data()` at the session startup is returned, and thus you can modify its
members without having to call `set_session_data()` ever again.

## `set_session_data()`

Stores session persistent data.

### Function Signature

```julia
function set_session_data(session_data::Any)::Nothing
```

 Argument  | Description
---------- |-------------
 `session_data` | Data of `Any` type.

## `get_session_data()`

Retrieves the previously stored session persistent data.

### Function Signature

```julia
function get_session_data()::Any
```
"""
function get_session_data()::Any
    task = task_local_storage("app_task")
    return task.session.user_session_data
end

@doc @doc(get_session_data) set_session_data
function set_session_data(session_data::Any)::Nothing
    task = task_local_storage("app_task")
    task.session.user_session_data = session_data
    return nothing
end

@doc @doc(is_app_first_pass) is_session_first_pass
function is_session_first_pass()::Bool
    task = task_local_storage("app_task")
    return task.session.first_pass
end

"""
# @session_startup

Macro to define a code block that should only executed at a session's first run.
Usage:

```julia
@session_startup begin
    # session initialization logic
end
```

Internally, this macro is implemented by checking the result of
[`is_session_first_pass()`](/docs/build/docs/api-reference/application-logic/is_first_pass-func)
and running the `@session_startup` code block only if it returns `true`.

## Usage

You can define multiple `@session_startup` code blocks, but we recommend you to
keep all of your session initialization logic inside a single `@session_startup`
block after the page initialization logic.

Although sessions are not required to have `@session_startup` code blocks, some
initialization tasks should be only performed inside `@session_startup`
code blocks. See below what you are expected to do inside `@session_startup`
code blocks.

### 1. Initialization of session persistent data

Session persistent data is a user defined data that is bound to a session and
whose lifetime is the lifetime of the session, i.e., as long as the session is
active the data will persist. Session persistent data can be retrieved at any
moment using `get_page_data()`.

You can store data that you want to be available within a session via the
`set_session_data()` function, and retrieve it using the `get_session_data()`
function. See [Session persistent data](/docs/build/docs/api-reference/application-logic/session-persistent-data)
to learn more.

## See also

- [`@app_startup`](/docs/build/docs/api-reference/application-logic/app_startup-macro)
- [`@page_startup`](/docs/build/docs/api-reference/application-logic/page_startup-macro)
"""
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

"""
# Page persistent data

Page persistent data is an user defined data that is bound to a page and
whose lifetime is the lifetime of the app, i.e., as long as the app is running
the data will persist. Page persistent data can be retrieved at any moment using
`get_page_data()` and is shared accross sessions.

Although the page persistent data can be either mutable or immutable, a common
practice is to define a mutable struct to store all of your page's data and
store it with `set_page_data()` at the page startup. Example:

```julia
# Define the struct to hold the page persistent data
mutable struct PageData
    foo::String
    bar::Int
end

@page_startup begin
    # Initialize the page persistent data
    page = PageData("hello", 32)
    set_page_data(page)
end

# now `get_page_data()` can be called from anywhere to retrieve the page data
```

In the example above, since the persistent data is a mutable struct, every time
`get_page_data()` is called the same `PageData` object instance stored with
`set_page_data()` at the page startup is returned, and thus you can modify its
members without having to call `set_page_data()` ever again.

## `set_page_data()`

Stores page persistent data.

### Function Signature

```julia
function set_page_data(page_data::Any)::Nothing
```

 Argument  | Description
---------- |-------------
 `page_data` | Data of `Any` type.

## `get_page_data()`

Retrieves the previously stored page persistent data.

### Function Signature

```julia
function get_page_data()::Any
```
"""
function get_page_data()::Any
    page = get_page(get_url_path())
    return page.user_page_data
end

@doc @doc(get_page_data) set_page_data
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

function strip_prefix(str::String, prefix::String)::String
    if startswith(str, prefix)
        return replace(str, prefix => "")
    end
    return str
end

DOC_PAGE_STATIC_SETTINGS = """
# Page static settings

Page static settings are persistent page settings that can only be defined
at the page's dry-run (`@page_startup`). The page static settings are used to
build the static HTML that is served when a user accesses one of the page's
URLs, which is why they cannot be changed after the page's dry-run.

Example:

```julia
@page_startup begin
    set_title("My Magic App")
    set_description("An awesome app built with Magic.jl")
end
```

See below functions to customize different page static settings.

## set_title

Sets the title of the current page (i.e. the HTML `<title>` tag).

### Function Signature

```julia
function set_title(title::String)::Nothing
```

Argument        | Description
---------------- |-------------
 `title`        | `String`. Title to be assigned to the current page.

## set_description

Sets the description of the current page (i.e. the HTML
`<meta property="og:description">` tag).

### Function Signature

```julia
function set_description(description::String)::Nothing
```

Argument        | Description
---------------- |-------------
 `description`        | `String`. Description to be assigned to the current page.

## add_font

Makes a font available in the current page, adding the necessary CSS
`@font-face` configuration in the `head` of the current page.

### Function Signature

```julia
function add_font(font_name::String, src_or_path::String)::Nothing
```

Argument        | Description
---------------- |-------------
 `font_name`        | `String`. The name that should be associated with the font.
 `src_or_path` | `String`. Either an external URL or a local serveable path inside the project's `.Magic/served-files/` directory. We recommend that you place all of your font files inside `.Magic/served-files/fonts/`.

## add_css_rule

Appends CSS rule(s) to the `head` of the current page.

Example:

```julia
add_css_rule(\"\"\"
    label {
        font-weight: bold;
    }
    pre {
        border: 1px solid black;
    }
\"\"\")
```

### Function Signature

```julia
function add_css_rule(rule::String)::Nothing
```

Argument        | Description
---------------- |-------------
 `rule`        | `String`. A valid CSS rule. Example: <pre>h1, h2, h3, h4, h5, h6 \\{<br/>  color: navy;<br/>\\}</pre>
"""

@doc DOC_PAGE_STATIC_SETTINGS
function set_title(page::PageConfig, title::String)::Nothing
    page.title = title
    return nothing
end

@doc DOC_PAGE_STATIC_SETTINGS
function set_title(title::String)::Nothing
    task = task_local_storage("app_task")
    return set_title(task.current_page, title)
end

@doc DOC_PAGE_STATIC_SETTINGS
function set_description(page::PageConfig, description::String)::Nothing
    page.description = description
    return nothing
end

@doc DOC_PAGE_STATIC_SETTINGS
function set_description(description::String)::Nothing
    task = task_local_storage("app_task")
    return set_description(task.current_page, description)
end

@doc DOC_PAGE_STATIC_SETTINGS
function add_font(page::PageConfig, font_name::String, src_or_path::String)::Nothing
    add_css_rule(page, """
        @font-face {
            font-family: "$(font_name)";
            src: url($(strip_prefix(src_or_path, "$(g.dot_magic_dir)/.Magic/served-files")));
        }
    """)
    return nothing
end

@doc DOC_PAGE_STATIC_SETTINGS
function add_font(font_name::String, src_or_path::String)::Nothing
    task = task_local_storage("app_task")
    add_font(task.current_page, font_name, src_or_path)
    return nothing
end

@doc DOC_PAGE_STATIC_SETTINGS
function add_css_rule(page::PageConfig, style::String)::Nothing
    page.style *= style
    return nothing
end

@doc DOC_PAGE_STATIC_SETTINGS
function add_css_rule(style::String)::Nothing
    task = task_local_storage("app_task")
    return add_css_rule(task.current_page, style)
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

@doc @doc(is_app_first_pass) is_page_first_pass
function is_page_first_pass()::Bool
    page = get_current_page()
    if page !== missing
        return page.first_pass
    end
    return false
end

"""
# @page_startup

Macro to define a code block that should only be executed at the startup
(dry-run) of the current page being run (i.e. the page associated with the URL
path returned by `get_url_path()`). Usage:

```julia
@page_startup begin
    # page initialization logic
end
```

Internally, this macro is implemented by checking the result of
[`is_page_first_pass()`](/docs/build/docs/api-reference/application-logic/is_first_pass-func)
and running the `@page_startup` code block only if it returns `true`.

## Usage

You can define multiple `@page_startup` code blocks, but we recommend you to
keep all of your page initialization logic inside a single `@page_startup` block
near the top of your page script file (or, if you have all of your pages in a
single file, near the top of where the page's logic begins).

Although pages are not required to have `@page_startup` code blocks, some
initialization tasks should be only performed inside `@page_startup`
code blocks. See below what you are expected to do inside `@page_startup` code
blocks.

### 1. Page static settings

Page static settings are persistent settings that are defined at the page's
dry-run and that cannot be changed later. These include the page title,
description, extra fonts and extra styles. The static settings related functions
below can only be called inside `@page_startup` blocks
(see [Page static settings](/docs/build/docs/api-reference/application-logic/page-static-settings)
to learn more).

- `set_title()`
- `set_description()`
- `add_font()`
- `add_css_rule()`

Example:

```julia
@page_startup begin
    set_title("My Magic App")
    set_description("An awesome app built with Magic.jl")
end
```

Internally, these static settings are used to build the static HTML that is
served when a user accesses the page's URL.

### 2. Initialization of page persistent data

Page persistent data is a user defined data that is bound to a page and
whose lifetime is the lifetime of the app, i.e., as long as the app is running
the data will persist. Page persistent data can be retrieved at any moment using
`get_page_data()` and is shared accross sessions.

You can store data that you want to be available to all the sessions of a page
via the `set_page_data()` function, and retrieve it using the `get_page_data()`
function. See [Page persistent data](/docs/build/docs/api-reference/application-logic/page-persistent-data)
to learn more.

## See also

- [`@app_startup`](/docs/build/docs/api-reference/application-logic/app_startup-macro)
- [`@session_startup`](/docs/build/docs/api-reference/application-logic/session_startup-macro)
"""
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

"""
# is_on_page

Checks if the current page is the page associated with a given path.

## Function Signature

```julia
function is_on_page(path::String)::Bool
```

Argument        | Description
---------------- |-------------
 `path`        | `String`. A path associated with a page of the app.

## Return Value

`true` if the current page is the page associated with `path`.

The current page is the page associated with the URL path returned by
`get_url_path()`. `is_on_page()` will return `true` if `path` is any of the
paths associated with the current page, regardless of which URL path the user
used to reach the page.

## Example

The code below defines two pages, the first one being associated with two paths
(`/` and `/page-1`):

```julia
@app_startup begin
    add_page(["/", "/page-1"])
    add_page("/page-2")
end

if     is_on_page("/")        # if the current URL path is either `/` or
    include("page-1.jl")      # `/page-1`, this will return true.
elseif is_on_page("/page-2")
    include("page-2.jl")
end
```

If the user accessed the page via `/page-1`, `is_on_page("/")` will return
`true`, because the current page is in fact associated with both `/` and
`/page-1`.
"""
function is_on_page(page_path::String)::Bool
    page = get_current_page()
    if page !== missing
        return page_path in page.uris
    end
    return false
end

# App data
#--------------
"""
# App persistent data

App persistent data is an user defined data whose lifetime is the lifetime of
the app, i.e., as long as the app is running the data will persist. App
persistent data can be retrieved at any moment using `get_app_data()` and is
shared accross pages and sessions.

Although the app persistent data can be either mutable or immutable, a common
practice is to define a mutable struct to store all of your app's data and store
it with `set_app_data()` at the application startup. Example:

```julia
# Define the struct to hold the app persistent data
mutable struct AppData
    foo::String
    bar::Int
end

@app_startup begin
    # Initialize the app persistent data
    app = AppData("hello", 32)
    set_app_data(app)
end

# now `get_app_data()` can be called from anywhere to retrieve the app data
```

In the example above, since the persistent data is a mutable struct, every time
`get_app_data()` is called the same `AppData` object instance stored with
`set_app_data()` at the app startup is returned, and thus you can modify its
members without having to call `set_app_data()` ever again.

## `set_app_data()`

Stores app persistent data.

### Function Signature

```julia
function set_app_data(app_data::Any)::Nothing
```

 Argument  | Description
---------- |-------------
 `app_data` | Data of `Any` type.

## `get_app_data()`

Retrieves the previously stored app persistent data.

### Function Signature

```julia
function get_app_data()::Any
```
"""
function get_app_data()::Any
    return g.user_app_data
end

@doc @doc(get_app_data) set_app_data
function set_app_data(app_data::Any)::Nothing
    g.user_app_data = app_data
    return nothing
end

# Misc
#------------
"""
# get_dot_magic_dir

Returns the location of the app's .Magic directory. By default, the .Magic
directory is created in the process working directory, but this can be changed
in the call to start_app() or via the command line.
"""
function get_dot_magic_dir()::String
    return g.dot_magic_dir
end

"""
# get_dot_magic_path

Returns the app's .Magic directory path. This is the same as
`joinpath(get_dot_magic_dir(), ".Magic")`
"""
function get_dot_magic_path()::String
    return joinpath(g.dot_magic_dir, ".Magic")
end

function get_random_string(n::Integer)::String
    CHARSET = ['0':'9'; 'A':'Z'; 'a':'z']
    return String(rand(CHARSET, n))
end

"""
# gen_serveable_path

Generates a file path where you can save a file to be served in your app.

## When to use this function

### 1. Generate a serveable path

Some widgets serve files to the client, such as
[`image`](/docs/build/docs/api-reference/interface-elements/image-func),
which serves an image in a given system path. Such widgets can only serve
resources that live inside your project's `.Magic/served-files/` directory and
subdirectories.

`gen_serveable_path()` is a convenience function to be used when you want
don't care for the name of the file you want to serve, nor where it lives, as
long as it is "serveable", i.e. it lives somewhere inside `.Magic/served-files/`.
`gen_serveable_path()` generates a path with a random file name with a given
extension inside `.Magic/served-files/generated`. You are then supposed to save your
file in the returned path and pass this path to the wiget you want.

For instance, consider an app that displays a plot given some user input. The
app's logic will look something like this:

```julia
plot_object = generate_fancy_plot(...)       # 1. Generate the plot
serveable_path = gen_serveable_path("png")   # 2. Generate a file path with `.png` extension
save_fancy_plot(plot_object, serveable_path) # 3. Save the plot at `serveable_path`
image(plot_path)                             # 4. Serve the plot image
```

### 2. Avoid Browser Caching

Aside from conveniently giving you a serveable file path, `gen_serveable_path()`
also helps to avoid browser caching issues. For instance, in the above example,
suppose that instead of saving the plot in a random serveable path everytime the
plot is regenerated we always saved it in the same serveable path. Most browsers
will automatically cache the image associated with a path, so newly generated
images in the same path would never be requested by these browsers.
Serving the newly generated plot in the path returned by `gen_serveable_path()`
prevents that from happening.

### Function Signature

```julia
function gen_serveable_path(extension::String; lifetime::String="session")::String
```

 Argument  | Description
---------- |-------------
 `extension` | File extension `String` to be appended to the randomly generated path.
 `lifetime` | A `String` indicating the lifetime of the resource. Possible values: `"session"` (default) or `"app"`. If `"session"` is provided, the file will become unavailable after the session is ended. If `"app"` is provided, the file will become unavailable after the app is stopped.

### Return Value

A random file path inside `.Magic/served-files/generated/` with extension
`extension`.
"""
function gen_serveable_path(extension::String=""; lifetime::String="session")::String
    task = task_local_storage("app_task")
    if length(extension) > 0
        if extension[1] != '.'
            extension = '.' * extension
        end
    end

    file_name = "$(get_random_string(32))$(extension)"

    dir_path = "$(g.dot_magic_dir)/.Magic/served-files/generated/$(task.session.session_id)"
    if lifetime == "app"
        dir_path = "$(g.dot_magic_dir)/.Magic/served-files/generated/app"
    end

    return "$(dir_path)/$(file_name)"
end

"""
# make_serveable_copy

Saves a serveable copy of a file inside `.Magic/served-files/`. This is a
convenience function that calls `gen_serveable_path()` and `cp()` to create a
serveable copy of a file. If you want to move the file to make it serveable
instead of creating a serveable copy, call
[`move_to_serveable_dir()`](/docs/build/docs/api-reference/application-logic/move_to_serveable_dir-func)
instead.

See [`gen_serveable_path()`](/docs/build/docs/api-reference/application-logic/gen_serveable_path-func)
to learn more.

### Function Signature

```julia
function make_serveable_copy(file_path::String; lifetime::String="session")::String
```

 Argument  | Description
---------- |-------------
 `file_path` | A `String` with the path of the file that should be copied.
 `lifetime` | A `String` indicating the lifetime of the generated copy. Possible values: `"session"` (default) or `"app"`. If `"session"` is provided, the file copy will become unavailable after the session is ended. If `"app"` is provided, the file copy will become unavailable after the app is stopped.

### Return Value

A `String` with the path to the file copy.
"""
function make_serveable_copy(file_path::String; lifetime::String="session")::String
    serveable_path = gen_serveable_path(lifetime=lifetime) * splitext(file_path)[2]
    cp(file_path, serveable_path, force=true)
    return serveable_path
end

"""
# move_to_serveable_dir

Moves a file to somewhere inside `.Magic/served-files/`. This is a
convenience function that calls `gen_serveable_path()` and `mv()` to move the
file to the app's serveable directory. If you want to create a serveable copy
of the file instead of moving the file itself, call
[`make_serveable_copy()`](/docs/build/docs/api-reference/application-logic/make_serveable_copy-func)
instead.

See [`gen_serveable_path()`](/docs/build/docs/api-reference/application-logic/gen_serveable_path-func)
to learn more.

### Function Signature

```julia
function move_to_serveable_dir(file_path::String; lifetime::String="session")::String
```

 Argument  | Description
---------- |-------------
 `file_path` | A `String` with the path of the file that should be moved.
 `lifetime` | A `String` indicating the lifetime of the generated copy. Possible values: `"session"` (default) or `"app"`. If `"session"` is provided, the file will become unavailable after the session is ended. If `"app"` is provided, the file copy will become unavailable (deleted) after the app is stopped.

### Return Value

A `String` with the new path to the file provided.
"""
function move_to_serveable_dir(file_path::String; lifetime::String="session")::String
    serveable_path = gen_serveable_path(lifetime=lifetime) * splitext(file_path)[2]
    mv(file_path, serveable_path, force=true)
    return serveable_path
end

"""
# DEPRECATED @once

Macro to prevent structs from being redefined on script reruns.

Pass a struct definition to this macro to prevent it from being redefined
on script reruns. Example:

```julia
@once mutable struct Foo
    bar::String
    baz::Int
end
```

## Explanation

Struct redefinitions can cause problems, especially on session persistent data.
Consider the following example:

```julia
mutable struct Foo
    bar::Int
end

mutable struct SessionData
    foo::Foo
end

@session_startup begin
    session = SessionData(Foo(0))
    set_session_data(session)
end

session.foo = Foo(rand(1:10))
```

The above code will work on the first session pass but will fail in the next
one with the following message:

> LoadError:
>   MethodError: Cannot \`convert\` an object of type **Main.MagicApp.Foo**
>   to an object of type **Main.MagicApp.Foo**.

This means that `Foo` was redefined and its new definition cannot be converted
to the original one that is being used in the session persistent data.

To avoid this issue, we simply prepend `@once` to the definition of `Foo`.
"""
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
