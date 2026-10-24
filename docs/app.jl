import CommonMark
using Magic
using TOML

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
    ast = CommonMark.Parser()(source)
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

function recursive_add_page(pages::Dict, dt::Dict, parent::AbstractString, root::AbstractString, url_prefix::AbstractString)::Nothing
    for (key, value) in dt
        dir_path = joinpath(parent, key)
        if value isa AbstractString && endswith(value, ".md")
            file_path = joinpath(root, lstrip(value, '/'))
            url_path = joinpath(url_prefix, lstrip(replace(file_path, root => "", ".md" => ""), '/'))
            add_page(url_path)
            md = read(file_path, String)
            heading, paragraph = first_heading_and_paragraph(md)
            pages[url_path] = Page(url_path, file_path, heading, paragraph, [])
        elseif value isa Dict
            file_path = joinpath(root, lstrip(dir_path, '/'), "index.toml")
            if isfile(file_path)
                url_path = joinpath(url_prefix, lstrip(dir_path, '/'))
                add_page(url_path)
                config = TOML.parsefile(file_path)
                pages[url_path] = Page(url_path, file_path, config["title"], config["description"], config["subpages"])
            end
            recursive_add_page(pages, value, dir_path, root, url_prefix)
        end
    end
    return nothing
end

function sidebar_links(section::AbstractString="/", section_title::AbstractString="", level::Int=0)
    current_path = get_url_path()
    expander_state = startswith(current_path, section) || section_title == "API Reference" ? "expanded" : "closed"

    cnt = level == 0 ?
          column(fill_width=true) :
          expander(uppercase(section_title), fill_width=true, initial_state=expander_state, gap="0", label_padding=".3em .8em .3em .8em", label_weight="bold",  label_size=".9rem")

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
                            highlight=(page.url_path == current_path),
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

    add_page("/docs")
    recursive_add_page(pages, dir_tree, "/", root, "/docs")

    set_app_data("pages", pages)
    set_app_data("dir_tree", dir_tree)
end

function doc_section(title::AbstractString, url_prefix::AbstractString)
    h2(title)
    category = get_page(url_prefix)
    subpages = category.subpages
    pairs = [i < length(subpages) ? (subpages[i], subpages[i+1]) : (subpages[i],) for i in 1:2:length(subpages)]

    for pair in pairs
        cols = columns(2, show_border=true, padding=".8rem", justify_content="space-between")
        cols(1) do
            url_path = joinpath(url_prefix, splitext(pair[1])[1])
            page = get_page(url_path)
            column(fill_width=true, fill_height=true, link=url_path) do
                h3(page.title, show_anchor_link=false)
                text(page.description)
            end
        end

        if length(pair) > 1
            cols(2) do
                url_path = joinpath(url_prefix, splitext(pair[2])[1])
                page = get_page(url_path)
                column(fill_width=true, fill_height=true, link=url_path) do
                    h3(page.title, show_anchor_link=false)
                    text(page.description)
                end
            end
        else
            cols[2].container["css"]["visibility"] = "hidden"
        end
    end
    space(height="3rem")
end

if startswith(get_url_path(), "/docs")
    set_page_layout("wide", left_sidebar_initial_state="open", top_bar="fixed")

    if is_on_page("/docs")
        column(fill_width=true, max_width="958px", padding="0 0 3rem 0") do
            h1("API Reference", show_anchor_link=false)

            doc_section("Interface Elements", "/docs/version/latest/api-reference/interface-elements")
            doc_section("Layout Elements", "/docs/version/latest/api-reference/layout-elements")
            doc_section("App Logic", "/docs/version/latest/api-reference/application-logic")
            doc_section("Jobs", "/docs/version/latest/api-reference/jobs")
        end
    else
        page = get_page(get_url_path())

        if !ismissing(page)
            @page_startup begin
                set_title(page.title * " | Magic Documentation")
                set_description(page.description * " | Magic Documentation")
            end

            column(fill_width=true, max_width="958px", padding="0 0 3rem 0") do
                markdown(file=page.file_path)
            end
        end
    end

    left_sidebar() do
        column(fill_width=true, padding="4rem 0 0 0") do
            h6("Documentation", show_anchor_link=false, css=Dict("padding-left" => ".8em"))
            sidebar_links("/docs/version/latest")
        end
    end

    include(joinpath(@__DIR__, "../examples/top-bar.jl"))
end
