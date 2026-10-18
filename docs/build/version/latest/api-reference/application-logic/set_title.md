# Page static settings

Page static settings are persistent page settings. These can only be defined at the page's dry-run, inside [`@page_startup`](/docs/version/latest/api-reference/application-logic/@page_startup) code blocks. The page static settings are used to build the static HTML that is served when a user accesses the page, and include things like the page title and description.

Example:

```julia
@app_startup begin
    add_page("/my-app")
end

if is_on_page("/my-app")
    @page_startup begin
        set_title("My Magic App")
        set_description("An awesome app built with Magic.jl")
    end
end
```

See below what functions to use to customize different page static settings.

## add_page

Registers a new page in the app, associating it with one or more URL paths. Unlike the other functions in this section, `add_page()` can only be called at the app's dry-run, inside [`@app_startup`](/docs/version/latest/api-reference/application-logic/@app_startup) code blocks.

### Function Signature

function add_page(     uri         ::Union{AbstractString, AbstractVector, Tuple};     title       ::String            ="",     description ::String            ="" )

```

Argument        | Description
:---------------- |:-------------
 `uri`          | Either a `String` with the URL path of the page, or a `Vector` or `Tuple` of `String`s with all the URL paths that should be associated with the page. A leading `/` is added to each path if missing.
 `title`        | `String`. Title to be assigned to the page. If empty (default), the app's default title is used.
 `description`  | `String`. Description to be assigned to the page. If empty (default), the app's default description is used.

```

## set_title

Sets the title of the current page, that is, the inner HTML of the `<title>` element.

### Function Signature

```julia
function set_title(title::String)::Nothing
```

| Argument | Description                                         |
|:-------- |:--------------------------------------------------- |
| `title`  | `String`. Title to be assigned to the current page. |

## set_description

Sets the description of the current page, that is, the inner HTML of the `<meta property="og:description">` element.

### Function Signature

```julia
function set_description(description::String)::Nothing
```

| Argument      | Description                                               |
|:------------- |:--------------------------------------------------------- |
| `description` | `String`. Description to be assigned to the current page. |

## add_font

Makes a font available in the current page, adding the necessary CSS `@font-face` configuration in the `head` of the current page.

### Function Signature

```julia
function add_font(font_name::String, src_or_path::String)::Nothing
```

| Argument      | Description                                                                                                                                                                                               |
|:------------- |:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `font_name`   | `String`. The name that should be associated with the font.                                                                                                                                               |
| `src_or_path` | `String`. Either an external URL or a local serveable path inside the project's `.Magic/served-files/` directory. We recommend that you place all of your font files inside `.Magic/served-files/fonts/`. |

## add_css_rule

Appends CSS rule(s) to a style element inside the `head` of the current page.

Example:

```julia
add_css_rule("""
    label {
        font-weight: bold;
    }
    pre {
        border: 1px solid black;
    }
""")
```

### Function Signature

```julia
function add_css_rule(rule::String)::Nothing
```

| Argument | Description                                                                                                     |
|:-------- |:--------------------------------------------------------------------------------------------------------------- |
| `rule`   | `String`. A valid CSS rule. Example: <pre>h1, h2, h3, h4, h5, h6 &lbrace;<br/>  color: navy;<br/>&rbrace;</pre> |

## inject_html

Injects arbitrary code into the HTML page served to the clients.

Example:

```julia
inject_html("<div>Hello!</div>")
```

### Function Signature

```julia
function inject_html(
    html::String="";
    file_path::Union{String, Nothing}=nothing,
    location::String="body_bottom"
)::Nothing
```

| Argument    | Description                                                                                                                                                                                                                                                                                                                                                   |
|:----------- |:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `html`      | `String` with the HTML code to be injected into the page. If the `file_path` argument is provided, this is ignored.                                                                                                                                                                                                                                           |
| `file_path` | `String` specifying the file containing the HTML that should be injected into the page. If this is provided, the `html` argument is ignored.                                                                                                                                                                                                                  |
| `location`  | `String` specifying the location *in the HTML page* where the provided HTML should be injected. Possible values: `"body_bottom"` (default, injects near the bottom of the HTML body), `"body_top"` (injects near the top of the HTML body), `"head_bottom"` (injects near the bottom of the HTML head), `"head_top"` (injects near the top of the HTML head). |
