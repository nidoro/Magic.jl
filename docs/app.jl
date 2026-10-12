using CommonMark
using Magic
using TOML

markdown = Magic.markdown

mutable struct Page
    url_path::String
    file_path::String
    title::Union{String, Nothing}
    description::Union{String, Nothing}
    subpages::Vector{String}
end

function node_text(node)
    io = IOBuffer()
    for (n, entering) in node
        if entering && (n.t isa CommonMark.Text || n.t isa CommonMark.Code)
            print(io, n.literal)
            elseif entering && (n.t isa CommonMark.SoftBreak || n.t isa CommonMark.LineBreak)
            print(io, ' ')
        end
    end
    return String(take!(io))
end

function first_heading_and_paragraph(source::AbstractString)
    ast = Parser()(source)
    heading = nothing
    paragraph = nothing
    for (node, entering) in ast
        entering || continue
        if heading === nothing && node.t isa CommonMark.Heading
            heading = node_text(node)
        elseif paragraph === nothing && node.t isa CommonMark.Paragraph
            paragraph = node_text(node)
        end
        (heading !== nothing && paragraph !== nothing) && break
    end
    return (; heading, paragraph)
end

function directory_tree(root::AbstractString, path::AbstractString)::Union{Dict, Nothing}
    tree = Dict{String,Any}()
    for name in readdir(path)
        full = joinpath(path, name)
        if isdir(full)
            tree[name] = directory_tree(root, full)
        else
            tree[name] = replace(full, root => "")
        end
    end
    return tree
end

function recursive_add_page(pages::Dict, dt::Dict, parent::AbstractString, root::AbstractString)::Nothing
    for (key, value) in dt
        dir_path = joinpath(parent, key)
        if value isa AbstractString && endswith(value, ".md")
            file_path = joinpath(root, lstrip(value, '/'))
            url_path = replace(file_path, root => "", ".md" => "")
            add_page(url_path)
            md = read(file_path, String)
            heading, paragraph = first_heading_and_paragraph(md)
            pages[url_path] = Page(url_path, file_path, heading, paragraph, [])
        elseif value isa Dict
            file_path = joinpath(root, lstrip(dir_path, '/'), "index.toml")
            if isfile(file_path)
                add_page(dir_path)
                config = TOML.parsefile(file_path)
                display(dir_path)
                display(config)
                pages[dir_path] = Page(dir_path, file_path, config["title"], config["description"], config["subpages"])
            end
            recursive_add_page(pages, value, dir_path, root)
        end
    end
    return nothing
end

function sidebar_links(section::AbstractString="/", section_title::AbstractString="", level::Int=0)
    current_path = get_url_path()
    expander_state = startswith(current_path, section) ? "expanded" : "closed"

    cnt = level == 0 ?
          column(fill_width=true) :
          expander(uppercase(section_title), fill_width=true, initial_state=expander_state, gap="0", label_padding=".3em .8em .3em .8em", label_weight="bold", label_color="#777", label_size=".9rem", label_hover_background="#ddd")

    @push cnt
        column(fill_width=true, gap="0px", padding="0 0 0 $(level*0.5)em") do
            sec = get_page(section)
            for subpage in sec.subpages
                page = get_page(joinpath(section, splitext(subpage)[1]))
                if !ismissing(page)
                    if isempty(page.subpages)
                        link(
                            page.title,
                            page.url_path,
                            style="naked",
                            fill_width=true,
                            padding=".2em .5em .2em .5em",
                            justify_content="flex-start",
                            background=page.url_path == current_path ? "#ddd" : nothing,
                        )
                    else
                        sidebar_links(page.url_path, page.title, level+1)
                    end
                end
            end
        end
    @pop
end

function get_page(url_path::AbstractString)
    pages = get_app_data("pages")
    if haskey(pages, url_path)
        return pages[url_path]
    end
    return missing
end

@app_startup begin
    root = joinpath(@__DIR__, "build")
    dir_tree = directory_tree(root, root)
    pages = Dict()

    add_page("/")
    recursive_add_page(pages, dir_tree, "/", root)

    set_app_data("pages", pages)
    set_app_data("dir_tree", dir_tree)

    display(pages)
end

set_page_layout("wide", left_sidebar_initial_state="open", top_bar="static")

if is_on_page("/")
    pages = get_app_data("pages")
    for (url_path, page) in pages
        text(url_path)
        text(page)
    end
else
    page = get_page(get_url_path())

    if !ismissing(page)
        @page_startup begin
            set_title(page.title * " | Magic Documentation")
            set_description(page.description * " | Magic Documentation")
        end

        left_sidebar() do
            column(fill_width=true, padding="4rem 0 0 0") do
                h6("Documentation", css=Dict("padding-left" => ".8em"))
                sidebar_links("/version/latest")
            end
        end

        column(fill_width=true, max_width="958px") do
            markdown(file=page.file_path)
        end
    end
end

top_bar() do
    row(fill_width=true, align_items="center") do
        image("/Magic.jl/images/magic-logo-and-black-text.svg", max_width="150px")
        link("Examples", "/", style="naked")
        link("Getting Started", "/docs/build/docs/getting-started/install", style="naked")
        link("Documentation", "/docs/build/docs/category/api-reference", style="naked")
        link("GitHub", "https://github.com/nidoro/Magic.jl", style="naked")
    end
end
