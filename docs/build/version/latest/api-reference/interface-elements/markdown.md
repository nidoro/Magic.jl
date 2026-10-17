# markdown

Renders Markdown content as HTML.

The Markdown is parsed with [CommonMark.jl](https://github.com/MichaelHatherly/CommonMark.jl), with support for tables and footnotes. Headings are automatically given an `id` based on their text, so they can be linked to with a URL fragment.

### Function Signature

```julia
function markdown(
    markdown_text   ::AbstractString                ="";
    file            ::Union{AbstractString, Nothing}=nothing
)::Nothing

function markdown(md::Markdown.MD)::Nothing

function markdown(ast::CommonMark.Node)::Nothing
```

| Argument        | Description                                                                                                                |
|:--------------- |:-------------------------------------------------------------------------------------------------------------------------- |
| `markdown_text` | A `String` containing the Markdown to be rendered.                                                                         |
| `file`          | An optional `String` with the path of a UTF-8 Markdown file to be rendered. If provided, `markdown_text` is ignored.       |
| `md`            | A `Markdown.MD` object, such as the ones created with the `md"..."` string macro from Julia's `Markdown` standard library. |
| `ast`           | A `CommonMark.Node` with an already parsed Markdown document.                                                              |

### Return Value

Nothing.

### Example

```julia
markdown("""
## Title

Some **bold** text and a [link](https://github.com/nidoro/Magic.jl).

---
""")

markdown(file="README.md")
```
