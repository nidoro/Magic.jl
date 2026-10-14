using Magic
using DataFrames

function comment_lines(s::AbstractString)
    join(("# " * line for line in split(strip(s), '\n')), '\n')
end

@app_startup begin
     add_page(["/", "/home"])
     add_page("/examples")
#     add_page("/examples/counter")
#     add_page("/examples/todo")
#     add_page("/examples/curves")
#     add_page("/examples/probability-density")
#     add_page("/examples/avatar")
#     add_page("/examples/forecast")
     add_page("/examples/seattle-weather")
#     add_page("/examples/image-filters")
#     add_page("/examples/fragment-example")
end

if is_on_page("/")
    set_page_layout("wide", top_bar="fixed")
    column(fill_width=true, align_items="center") do
        column(fill_width=true, max_width="1200px") do

            column(fill_width=true, align_items="center") do
                h1("🚀 The easiest way of creating Julia web apps", show_anchor_link=false, css=Dict("margin-bottom" => "2rem", "text-align" => "center"))

                column() do
                    markdown("Create an `app.jl` file and start your app from the REPL:")
                end

                code("""
                    > using Magic
                    > start_app()
                    """, fill_width=false)

                space(height="1.5rem")
            end

            h2("Basic widgets")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")

                @push cols[2]
                    style = row().radio("Radio", ["primary", "secondary", "naked"], initial_value="secondary")

                    optional_code = style != "secondary" ? ", style=\"$(style)\"" : ""

                    code("""
                        if button("Button"$(optional_code))
                            text("Clicked!")
                        end
                        """)
                @pop

                cols(1) do
                    row(align_items="center") do
                        if button("Button", style=style)
                            text("Clicked!")
                        end
                    end
                end

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")

                opt_row = cols[2].row()
                multiple = opt_row.checkbox("multiple")
                fill_width = opt_row.checkbox("fill_width")
                show_label = opt_row.checkbox("show_label", initial_value=true)

                optional_code = ""
                optional_code *= multiple ? ", multiple=$(multiple)" : ""
                optional_code *= fill_width ? ", fill_width=$(fill_width)" : ""
                optional_code *= !show_label ? ", show_label=$(show_label)" : ""

                option = cols[1].selectbox("Selectbox", ["A", "B", "C"], multiple=multiple, fill_width=fill_width, show_label=show_label)
                cols[2].code("""
                            option = selectbox("Selectbox", ["A", "B", "C"]$(optional_code))
                            # option = $(option)
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")

                checked = cols[1].checkbox("Checkbox")
                cols[2].code("""
                            checked = checkbox("Checkbox")
                            # checked = $(checked)
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                option = cols[1].row().radio("Radio", ["A", "B", "C"])
                cols[2].code("""
                            option = radio("Radio", ["A", "B", "C"])
                            # option = $(repr(option))
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                opt_row = cols[2].row()
                fill_width = opt_row.checkbox("fill_width")
                show_label = opt_row.checkbox("show_label", initial_value=true)

                optional_code = ""
                optional_code *= fill_width ? ", fill_width=$(fill_width)" : ""
                optional_code *= !show_label ? ", show_label=$(show_label)" : ""

                txt = cols[1].text_input("Text input", fill_width=fill_width, show_label=show_label)
                cols[2].code("""
                            text = text_input("Text input"$(optional_code))
                            # text = $(repr(txt))
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                opt_row = cols[2].row()
                step_range = opt_row.checkbox("step and range")
                fill_width = opt_row.checkbox("fill_width")
                show_label = opt_row.checkbox("show_label", initial_value=true)

                optional_code = ""
                optional_code *= step_range ? ", step=0.1, min=1, max=10" : ""
                optional_code *= fill_width ? ", fill_width=$(fill_width)" : ""
                optional_code *= !show_label ? ", show_label=$(show_label)" : ""

                number = cols[1].number_input("Number input", fill_width=fill_width, show_label=show_label, step=step_range ? 0.1 : 1, min=step_range ? 1 : nothing, max=step_range ? 10 : nothing)
                cols[2].code("""
                            number = number_input("Number input"$(optional_code))
                            # number = $(repr(number))
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                opt_row = cols[2].row()
                step_range = opt_row.checkbox("step and range")
                fill_width = opt_row.checkbox("fill_width")
                show_label = opt_row.checkbox("show_label", initial_value=true)

                optional_code = ""
                optional_code *= step_range ? ", step=1, min=1, max=10" : ""
                optional_code *= fill_width ? ", fill_width=$(fill_width)" : ""
                optional_code *= !show_label ? ", show_label=$(show_label)" : ""

                number = cols[1].slider("Slider", show_label=show_label, fill_width=fill_width, step=step_range ? 1 : nothing, min=step_range ? 1 : 0.0, max=step_range ? 10 : 1.0)
                cols[2].code("""
                            number = slider("Slider"$(optional_code))
                            # number = $(repr(number))
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                opt_row = cols[2].row()
                fill_width = opt_row.checkbox("fill_width")
                show_label = opt_row.checkbox("show_label", initial_value=true)

                optional_code = ""
                optional_code *= fill_width ? ", fill_width=$(fill_width)" : ""
                optional_code *= !show_label ? ", show_label=$(show_label)" : ""

                color = cols[1].color_picker("Color picker", show_label=show_label, fill_width=fill_width)
                cols[2].code("""
                            color = color_picker("Color picker"$(optional_code))
                            # color = $(repr(color))
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            space(height="3rem")
            h2("DataFrame")

            @session_startup begin
                df = DataFrame(
                    Name = String["Alice", "Bob", "Carol"],
                    Age  = Int[25, 32, 28],
                    City = String["Lisbon", "Paris", "Berlin"]
                )
                set_session_data("df", df)
            end

            row(fill_width=true, align_items="center") do
                df = get_session_data("df")
                cols = columns(2, justify_content="center")
                editable = cols[2].checkbox("editable", initial_value=true)
                cols[1].dataframe(df, editable=editable)

                optional_code = editable ? ", editable=$(editable)" : ""

                cols[2].code("""
                            @session_startup begin
                                df = DataFrame(
                                    name = String["Alice", "Bob", "Carol"],
                                    age  = Int[25, 32, 28],
                                    city = String["Lisbon", "Paris", "Berlin"]
                                )
                                set_session_data("df", df)
                            end
                            df = get_session_data("df")
                            dataframe(df$(optional_code))
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            space(height="3rem")
            h2("File upload/download")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                opt_row = cols[2].row()
                fill_width = opt_row.checkbox("fill_width")

                optional_code = ""
                optional_code *= fill_width ? ", fill_width=$(fill_width)" : ""

                uploaded_file = cols[1].file_uploader("File uploader", fill_width=fill_width)
                cols[2].code("""
                            file = file_uploader("File uploader"$(optional_code))
                            # file = $(comment_lines(repr(uploaded_file)))
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            file_path = ".Magic/served-files/images/chart.png"

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                opt_row = cols[2].row()
                #fill_width = opt_row.checkbox("fill_width")

                optional_code = ""
                #optional_code *= fill_width ? ", fill_width=$(fill_width)" : ""

                cols[1].download_button("Download", file_path)
                cols[2].code("""
                            file_path = $(repr(file_path))
                            download_button("Download", file_path$(optional_code))
                            """)

               link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            space(height="3rem")
            h2("Image")

            row(fill_width=true, align_items="center", css=Dict("flex-shrink" => "1")) do
                cols = columns(2, justify_content="center")
                opt_row = cols[2].row()
                fill_width = opt_row.checkbox("fill_width")

                optional_code = ""
                optional_code *= fill_width ? ", fill_width=$(fill_width)" : ""

                cols[1].image(file_path, fill_width=fill_width)
                cols[2].code("""
                            file_path = $(repr(file_path))
                            image(file_path$(optional_code))
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            space(height="3rem")
            h2("Text and Markdown")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")

                cols[1].h1("Heading")
                cols[1].h2("Heading")
                cols[1].h3("Heading")
                cols[1].h4("Heading")
                cols[1].h5("Heading")
                cols[1].h6("Heading")

                cols[2].code("""
                            h1("Heading")
                            h2("Heading")
                            h3("Heading")
                            h4("Heading")
                            h5("Heading")
                            h6("Heading")
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")

                cols[1].text("Regular text")
                cols[2].code("""text("Regular text")""")

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")

                cols[1].markdown("""
                                This markdown text has **bold**, *italic*, and ***bold italic*** styling.

                                - This is a list item.
                                - So is this.
                                - And this.

                                > This is a quote.
                                """)

                cols[2].code("""
                            markdown(\"""
                                This markdown text has **bold**, *italic*, and ***bold italic*** styling.

                                - This is a list item.
                                - So is this.
                                - And this.

                                > This is a quote.
                            \""")
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            space(height="3rem")
            h2("Flexible Layout")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                selected_container = cols[2].row().radio("Radio", ["column", "row"])

                opt_row = cols[2].row()
                fill_width = opt_row.checkbox("fill_width", initial_value=true)
                fill_height = opt_row.checkbox("fill_height", initial_value=true)
                show_border = opt_row.checkbox("show_border", initial_value=true)
                padding = opt_row.checkbox("padding")

                opt_row = cols[2].row(align_items="center")
                opt_row.text("align_items:")
                align_items = opt_row.radio("Align", ["flex-start", "center", "flex-end"], initial_value="center")

                opt_row = cols[2].row(align_items="center")
                opt_row.text("justify_content:")
                justify_content = opt_row.radio("Justify", ["flex-start", "center", "flex-end"], initial_value="center")

                cnt = selected_container == "column" ?
                    cols[1].column(fill_width=fill_width, fill_height=fill_height, show_border=show_border, justify_content=justify_content, align_items=align_items, padding=padding ? "20px" : "none") :
                    cols[1].row(fill_width=fill_width, fill_height=fill_height, show_border=show_border, justify_content=justify_content, align_items=align_items, padding=padding ? "20px" : "none")

                arguments = []
                if fill_width push!(arguments, "fill_width=true") end
                if fill_height push!(arguments, "fill_height=true") end
                if show_border push!(arguments, "show_border=true") end
                if padding push!(arguments, "padding=\"20px\"") end
                if align_items != "flex-start" push!(arguments, "align_items=$(repr(align_items))") end
                if justify_content != "flex-start" push!(arguments, "justify_content=$(repr(justify_content))") end

                @push cnt
                    text("Text")
                    button("Button")
                    checkbox("Checkbox")
                @pop

                cols[2].code("""
                            $(selected_container)($(join(arguments, ", "))) do
                                text("Text")
                                button("Button")
                                checkbox("Checkbox")
                            end
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                opt_row = cols[2].row(align_items="center")
                opt_row.text("columns: ")
                num_columns = opt_row.radio("Cols", [2, 3, 4, 5, 6])
                cs = cols[1].columns(num_columns, fill_width=true, fill_height=true, show_border=true, justify_content="center", align_items="center")

                for c in 1:num_columns
                    cs[c].text(c)
                end

                if num_columns == 2
                    cols[2].code("""
                                cols = columns(2, fill_width=true, fill_height=true, show_border=true, justify_content="center", align_items="center")
                                cols(1) do
                                    text(1)
                                end
                                cols(2) do
                                    text(2)
                                end
                                """)
                else
                    cols[2].code("""
                                cols = columns($(num_columns), fill_width=true, fill_height=true, show_border=true, justify_content="center", align_items="center")
                                for c in 1:$(num_columns)
                                    cols(c) do
                                        text(c)
                                    end
                                end
                                """)
                end

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            space(height="3rem")
            h2("Expander")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center", fill_height=true)

                cols[1].expander("Expander") do
                    link("Github", "https://github.com/nidoro/Magic.jl")
                    link("Docs", "https://github.com/nidoro/Magic.jl")
                    link("Examples", "https://github.com/nidoro/Magic.jl")
                end

                cols[2].code("""
                            expander("Expander") do
                                link("Github", "https://github.com/nidoro/Magic.jl")
                                link("Docs", "https://github.com/nidoro/Magic.jl")
                                link("Examples", "https://github.com/nidoro/Magic.jl")
                            end
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            space(height="3rem")
            h2("Dialog")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")

                if cols[1].button("Open Dialog")
                    dialog() do
                        h2("Dialog")
                        text_input("Enter your name", fill_width=true, id="name")
                        if button("Confirm", style="primary")
                            rerun()
                        end
                    end
                end

                cols[2].code("""
                            if button("Open Dialog")
                                dialog() do
                                    h2("Dialog")
                                    text_input("Enter your name", fill_width=true, id="name")
                                    if button("Confirm", style="primary")
                                        rerun()
                                    end
                                end
                            end
                            # get_value("name") = $(repr(get_value("name")))
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            space(height="3rem")
            h2("Long running jobs")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")

                if cols[1].button("Start Job")
                    @job("heavy_work") do
                        sleep(3)
                        return "job finished!"
                    end
                end

                cols[2].code("""
                            if button("Start Job")
                                @job("heavy_work") do
                                    sleep(3)
                                    return "job finished!"
                                end
                            end
                            # get_result("heavy_work") = $(repr(get_result("heavy_work")))
                            """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            space(height="3rem")
            h2("HTML")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")

                cols[1].html(
                    "div",
                    "Inner HTML",
                    css=Dict("height" => "100%", "width" => "100%", "background" => "pink", "cursor" => "pointer"),
                    attributes=Dict("onclick" => "javascript:alert('Hello!')")
                )

                cols[2].code("""
                             html(
                                 "div",
                                 "Inner HTML",
                                 css=Dict("height" => "100%", "width" => "100%", "background" => "pink", "cursor" => "pointer"),
                                 attributes=Dict("onclick" => "javascript:alert('Hello!')")
                             )
                             """)

                link("Learn more", "google.com", new_tab=true)
            end

            markdown("---")

            space(height="3rem")
        end
    end

    top_bar() do
        row(fill_width=true, max_width="100%", align_items="center", css=Dict("flex-wrap" => "wrap")) do
            image("/Magic.jl/images/magic-logo-and-black-text.svg", max_width="150px")
            link("Examples", "/examples", style="naked")
            link("Getting Started", "/docs/build/docs/getting-started/install", style="naked")
            link("Documentation", "/docs", style="naked")
            link("GitHub", "https://github.com/nidoro/Magic.jl", style="naked")
        end
    end
elseif startswith(get_url_path(), "/examples")
    page_script = "01-counter.jl"
    layout_style = "centered"

    if is_on_page("/examples")
        page_script = @__FILE__
    elseif is_on_page("/examples/counter")
        page_script = "01-counter.jl"
    elseif is_on_page("/examples/todo")
        page_script = "02-todo.jl"
    elseif is_on_page("/examples/curves")
        page_script = "05-curves.jl"
    elseif is_on_page("/examples/probability-density")
        page_script = "07-probability.jl"
    elseif is_on_page("/examples/avatar")
        page_script = "10-avatar.jl"
    elseif is_on_page("/examples/forecast")
        page_script = "13-forecast.jl"
        layout_style = "wide"
    elseif is_on_page("/examples/seattle-weather")
        page_script = "15-seattle-weather.jl"
        layout_style = "wide"
    elseif is_on_page("/examples/image-filters")
        page_script = "20-image-filters.jl"
        layout_style = "wide"
    elseif is_on_page("/examples/fragment-example")
        page_script = "50-fragment-example.jl"
    end

    set_page_layout(
        layout_style,
        left_sidebar_initial_state="open",
        right_sidebar_initial_state="closed",
        right_sidebar_position="overlay",
        right_sidebar_initial_width="50%",
        right_sidebar_toggle_labels=(
            "VIEW SOURCE <lt-icon lt-icon='material/code'></lt-icon>",
            nothing
        ),
        top_bar="static"
    )

    if is_on_page("/examples")
        @page_startup begin
            set_title("Magic Examples | Magic.jl")
            set_description("Magic Examples | Magic.jl")
        end

        column(fill_width=true, padding="0 0 3rem 0") do
            h1("Examples Gallery")
            text("A few simple apps that showcase Magic.jl features!")
            text("Each one contains its own source code on the right sidebar for you to explore.")

            space(height=".5rem")

            cols = columns(2, show_border=true, padding=".8rem", justify_content="space-between")

            cols(1) do
                h5("Counter")
                text("Basic interactivity")
                link("Open", "/examples/counter", style="primary")
            end

            cols(2) do
                h5("To-Do List")
                text("text_input and checkbox")
                link("Open", "/examples/todo", style="primary")
            end

            cols = columns(2, show_border=true, padding=".8rem", justify_content="space-between")

            cols(1) do
                h5("Sliding Curves")
                text("Fun with sliders")
                link("Open", "/examples/curves", style="primary")

            end

            cols(2) do
                h5("Probability Viewer")
                text("number_input and selectbox")
                link("Open", "/examples/probability-density", style="primary")
            end

            cols = columns(2, show_border=true, padding=".8rem", justify_content="space-between")

            cols(1) do
                h5("Avatar Creator")
                text("image, selectbox, color_picker and custom fonts")
                link("Open", "/examples/avatar", style="primary")
            end

            cols(2) do
                h5("Brazil Forecast")
                text("Interactive dataframe, image and integration with other libraries")
                link("Open", "/examples/forecast", style="primary")
            end

            cols = columns(2, show_border=true, padding=".8rem", justify_content="space-between")

            cols(1) do
                h5("Seattle Weather")
                text("Dashboard with metric, checkboxes, plots and dataframe")
                link("Open", "/examples/seattle-weather", style="primary")
            end

            cols(2) do
                h5("Image Filters")
                text("file_uploader and download_button")
                link("Open", "/examples/image-filters", style="primary")
            end
        end
    else
        include(page_script)
    end

    left_sidebar() do
        column(fill_width=true, gap="0px") do
            space(height="3rem")
            h5("Magic Examples", css=Dict("margin" => "0 0 .8rem .8rem", "white-space" => "nowrap", "color" => "#444"))
            link("Overview", "/examples", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("Counter", "/examples/counter", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("To-Do List", "/examples/todo", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("Sliding Curves", "/examples/curves", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("Probability Viewer", "/examples/probability-density", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("Avatar Creator", "/examples/avatar", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("Brazil Forecast", "/examples/forecast", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("Seattle Weather", "/examples/seattle-weather", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("Image Filters", "/examples/image-filters", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
        end
    end

    right_sidebar() do
        code(initial_value_file=joinpath(@__DIR__, page_script))
    end

    top_bar() do
        row(fill_width=true, max_width="100%", align_items="center", css=Dict("flex-wrap" => "wrap")) do
            image("/Magic.jl/images/magic-logo-and-black-text.svg", max_width="150px")
            link("Examples", "/examples", style="naked")
            link("Getting Started", "/docs/build/docs/getting-started/install", style="naked")
            link("Documentation", "/docs", style="naked")
            link("GitHub", "https://github.com/nidoro/Magic.jl", style="naked")
        end
    end
end
