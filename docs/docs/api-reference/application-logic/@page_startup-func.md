---
sidebar_position: 3
---

# @page_startup

Macro to define a code block that is only executed at the startup (dry-run) of the current page being run, that is, the page associated with the URL path returned by `get_url_path()`). Usage:

```julia
@page_startup begin
    # page initialization logic
end
```

Internally, this macro is implemented by checking the result of [`is_page_first_pass()`](/docs/build/docs/api-reference/application-logic/is_app_first_pass-func) and running the `@page_startup` code block only if it returns `true`.

## Usage

You can define multiple `@page_startup` code blocks, but we recommend you to keep all of your page initialization logic inside a single `@page_startup` block near the top of your page script file (or, if you have all of your pages in a single file, near the top of where the page's logic begins).

Although pages are not required to have `@page_startup` code blocks, some initialization tasks can only be performed inside `@page_startup` code blocks. See below what you are expected to do inside `@page_startup` code blocks.

### 1. Page static settings

Page static settings are persistent settings that are defined at the page's dry-run. These are initialized once and that cannot be changed later, and include, among other things, the page title and description. The static settings related functions can only be called inside `@page_startup` blocks. See [Page static settings](/docs/build/docs/api-reference/application-logic/set_title-func) to learn more.

Example:

```julia
@app_startup begin
    add_page("/foo")
end

if is_on_page("/foo")
    @page_startup begin
        set_title("My Magic App")
        set_description("An awesome app built with Magic.jl")
    end
end
```

Internally, these static settings are used to build the static HTML that is served when a user accesses the page's URL.

### 2. Initialization of page persistent data

Page persistent data is a user defined data that is bound to a page and whose lifetime is the lifetime of the app, that is, as long as the app is running the data will persist. Page persistent data can be retrieved at any moment using `get_page_data()` and is shared accross sessions.

You can store data that you want to be available to all the sessions of a page via the `set_page_data()` function, and retrieve it using the `get_page_data()` function. See [Page persistent data](/docs/build/docs/api-reference/application-logic/set_page_data-func) to learn more.

Example:

```julia
mutable struct PageFoo
    data::Any
end

@app_startup begin
    add_page("/foo")
end

if is_on_page("/foo")
    @page_startup begin
        page_data = PageFoo("data")
        set_page_data(page_data)
    end
end
```

## See also

  * [`@app_startup`](/docs/build/docs/api-reference/application-logic/@app_startup-func)
  * [`@session_startup`](/docs/build/docs/api-reference/application-logic/@session_startup-func)
