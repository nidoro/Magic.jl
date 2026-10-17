# Basic Concepts

## Sessions

A session is a connection to your app. A session is started when a browser tab
is open in your app's address, and ends when that browser tab connection
is closed in any way (when the tab is closed, or is used to open
another website, or is refreshed, or internet connection is lost, etc).
Everything that happens in between, happens within the session.

You can have separate persistent data for each session. See
[Session persistent data](/docs/version/latest/api-reference/application-logic/set_session_data)
to learn more.

`Magic.jl` web apps are julia scripts that run from top to bottom. This happens
whenever a new session is started and whenever the user interacts with an
element of your app.

## Initialization code blocks

`Magic.jl` web apps are julia scripts that run from top to bottom. But
initialization tasks should only be executed once, at the appropriate time.

`Magic.jl` defines three macros that you can use to enclose code blocks that
should only be executed at the initialization moment.

- [`@app_startup`](/docs/version/latest/api-reference/application-logic/@app_startup):
used to define a code block that runs only when the app is started and a dry-run
of the app script is executed.
- [`@page_startup`](/docs/version/latest/api-reference/application-logic/@page_startup):
used to define a code block that runs only when a dry run of the current page is
executed.
- [`@session_startup`](/docs/version/latest/api-reference/application-logic/@session_startup):
used to define a code block that runs only when the session is starting, i.e.
the script is being executed for the first time for the current session.

For instance, very often you will want to associate some data to a session.
Session persistent data can be initialized and stored in `@session_startup`
blocks, and retrieved from anywhere using
[`get_session_data()`](/docs/version/latest/api-reference/application-logic/set_session_data#getsessiondata).
See [`@session_startup`](/docs/version/latest/api-reference/application-logic/@session_startup)
to learn more.

## Layout

The overall layout of a page can be set with
[`set_page_layout()`](/docs/version/latest/api-reference/layout-elements/set_page_layout).
At the moment, there are three predefined page layout styles that you can set:

- `set_page_layout("basic")`: Basic layout with minimal layout behaviour (default).
- `set_page_layout("centered")`: Narrow layout with centered content.
- `set_page_layout("wide")`: Wide layout with small padding.

These overall layout styles alter how the [`main_area()`](/docs/version/latest/api-reference/layout-elements/main_area) container looks and
behaves, but it is up to you to arrange the main area content.

In short, if you want to stack elements vertically, use [`columns()`](/docs/version/latest/api-reference/layout-elements/columns) or
[`column()`](/docs/version/latest/api-reference/layout-elements/column). If you want to stack elements horizontally, use [`row()`](/docs/version/latest/api-reference/layout-elements/row).

Containers can be nested to create more intricate layouts. For instance, the
example below creates an app with `"wide"` layout with two columns, and the
first of these columns contains other two columns:

```julia
set_page_layout("wide")

main_area() do # Optional main_area() call. See tip below.
    cols = columns(2)

    cols(1) do
        # Main column 1 content

        cols = columns(2)

        cols(1) do
            # Nested column 1 content
        end

        cols(2) do
            # Nested column 2 content
        end
    end

    cols(2) do
        # Main column 2 content
    end
end
```

> **TIP**: In general, you don't have to explicitly call `main_area()` to place
> elements into the main area. After calling `set_page_layout()`, any element
> created in the top-level of your app is placed inside `main_area()`.

For more control over the layout of the `main_area()`, you can
`set_page_layout("basic")`, which imposes almost no layout behaviour
`main_area()` container.

## Widgets, reruns and callbacks

Widgets are interactable interface elements, such as [`button()`](/docs/version/latest/api-reference/interface-elements/button), [`checkbox()`](/docs/version/latest/api-reference/interface-elements/checkbox)
and [`selectbox()`](/docs/version/latest/api-reference/interface-elements/selectbox). Widget creation functions typically return its current value.
Example:

```julia
selected = selectbox("Selectbox", ["Option A", "Option B", "Option C"])
text(selected) # will display whatever option is currently selected

if button("Click me")
    # button() returns `true` when clicked.
    # Do something here.
end
```

Everytime a button is clicked or the value of a widget is changed, the app
script is rerun from top to bottom, letting you take action in response to the
user input.

Sometimes it is useful to take action in response to user input even before the
script is rerun from top to bottom. For those situations, you can bind a
callback function to the widget, using the `onclick` argument of buttons or the
`onchange` argument of widgets that support it, such as `selectbox()` and
`checkbox()`. For instance:

```julia
function click_handler()
    # Do something when the button is clicked.
end

button("Click me", onclick=click_handler)
```

Callbacks are executed *before* reruning the app script from top to bottom, so
in the example above, by the time the execution of the app script starts,
`click_handler()` will already have been executed. Use callbacks to anticipate
actions that will affect how the app looks and behaves.

## Multiple Pages

`Magic.jl` web apps can have multiple pages. Each page is bound to one or more
URL paths by calling the [`add_page()`](/docs/version/latest/api-reference/application-logic/set_title#addpage)
function at a [`@app_startup`](/docs/version/latest/api-reference/application-logic/@app_startup)
code block. Example:

```julia
using Magic

@app_startup begin
    add_page(["/", "/home"])
    add_page("/analyser")
end

if     is_on_page("/")
    # Run the `/home` page logic here.
    # You can also place the logic in a separate script and call
    # `include("home.jl")` here.
elseif is_on_page("/analyser")
    # Run the `/analyser` page logic
end
```

Each page can have its own static configuration and persistent data. See
[Page static settings](/docs/version/latest/api-reference/application-logic/set_title)
and [Page persistent data](/docs/version/latest/api-reference/application-logic/set_page_data)
to learn more.

## The `.Magic` directory

When starting an app, `Magic.jl` will automatically create a `.Magic`
directory, if one is not found or provided, to store various files needed for
the proper functioning of the app. By default, this directory is created at the
process working directory, but this can be changed via the `dot_magic_dir`
argument of the [`start_app`](/docs/version/latest/api-reference/application-logic/start_app) function. You can get the `.Magic` location by
calling [`get_dot_magic_dir()`](/docs/version/latest/api-reference/application-logic/get_dot_magic_dir) to retrieve `.Magic`'s parent directory or
[`get_dot_magic_path()`](/docs/version/latest/api-reference/application-logic/get_dot_magic_path) to retrieve its full path including `.Magic`.

Feel free to use this same directory to store whatever files you may need in a
your app, but **stay out** of the following temporary subdirectories, which are
wiped on the app startup:
- `served-files/generated`: Files served to clients that are auto-generated by
`Magic.jl`.
- `uploaded-files`: Temporary location for files uploaded by clients.

