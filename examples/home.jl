
function comment_lines(s::AbstractString)::String
    join(("# " * line for line in split(strip(s), '\n')), '\n')
end

function section_separator()::Nothing
    space(height="1.5rem")
    markdown("---")
    space(height="1rem")
    return nothing
end

set_page_layout("wide", top_bar="sticky")
include("top-bar.jl")

column(fill_width=true, align_items="center") do
    column(fill_width=true, max_width="1300px") do

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

        h2("Theme")

        row(fill_width=true, align_items="center") do
            cols = columns(2, justify_content="center")

            cols(1) do
                radio("Theme", ["auto", "light", "dark"], id="theme_example", horizontal=true, show_label=false, onchange=update_theme, args=["theme_example"])
            end

            cols(2) do
                code("""
                    set_theme($(repr(get_value("theme_example"))))
                    """)
            end

            link("Learn more", "/docs/version/latest/api-reference/application-logic/set_theme", new_tab=true)
        end

        markdown("---")

        h2("Basic widgets")

        fragment() do
            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")

                @push cols[2]
                    style = radio("style", ["primary", "secondary", "naked"], show_label=false, horizontal=true, initial_value="secondary")

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

                link("Learn more", "/docs/version/latest/api-reference/interface-elements/button", new_tab=true)
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
                            # option = $(repr(option))
                            """)

                link("Learn more", "/docs/version/latest/api-reference/interface-elements/selectbox", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")

                checked = cols[1].checkbox("Checkbox")
                cols[2].code("""
                            checked = checkbox("Checkbox")
                            # checked = $(checked)
                            """)

                link("Learn more", "/docs/version/latest/api-reference/interface-elements/checkbox", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                option = cols[1].radio("Radio", ["A", "B", "C"], horizontal=true)
                cols[2].code("""
                            option = radio("Radio", ["A", "B", "C"], horizontal=true)
                            # option = $(repr(option))
                            """)

                link("Learn more", "/docs/version/latest/api-reference/interface-elements/radio", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                opt_row = cols[2].row()
                fill_width = opt_row.checkbox("fill_width")

                optional_code = ""
                optional_code *= fill_width ? ", fill_width=$(fill_width)" : ""

                @push cols[1]
                    text("Cycle Button")
                    state = cycle_button(["Run", "Pause"], labels=["▶️ Run", "⏸️ Pause"], fill_width=fill_width)
                @pop

                cols[2].code("""
                            state = cycle_button(["Run", "Pause"], labels=["▶️ Run", "⏸️ Pause"]$(optional_code))
                            # state = $(repr(state))
                            """)

                link("Learn more", "/docs/version/latest/api-reference/interface-elements/cycle_button", new_tab=true)
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

                link("Learn more", "/docs/version/latest/api-reference/interface-elements/text_input", new_tab=true)
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

                number = cols[1].number_input("Number input", fill_width=fill_width, show_label=show_label, step=step_range ? 0.1 : 1, min=step_range ? 1 : nothing,     max=step_range ? 10 : nothing)
                cols[2].code("""
                            number = number_input("Number input"$(optional_code))
                            # number = $(repr(number))
                            """)

                link("Learn more", "/docs/version/latest/api-reference/interface-elements/number_input", new_tab=true)
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

                number = cols[1].slider("Slider", show_label=show_label, fill_width=fill_width, step=step_range ? 1 : nothing, min=step_range ? 1 : 0.0, max=step_range ? 10     : 1.0)
                cols[2].code("""
                            number = slider("Slider"$(optional_code))
                            # number = $(repr(number))
                            """)

                link("Learn more", "/docs/version/latest/api-reference/interface-elements/slider", new_tab=true)
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

                link("Learn more", "/docs/version/latest/api-reference/interface-elements/color_picker", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                opt_row = cols[2].row()
                new_tab = opt_row.checkbox("new_tab", initial_value=true)

                optional_code = ""
                optional_code *= new_tab ? ", new_tab=$(new_tab)" : ""

                color = cols[1].link("Link", "https://github.com/nidoro/Magic.jl", new_tab=new_tab)
                cols[2].code("""
                                link("Link", "https://github.com/nidoro/Magic.jl"$(optional_code))
                                """)

                link("Learn more", "/docs/version/latest/api-reference/interface-elements/link", new_tab=true)
            end
        end

        section_separator()
        h2("DataFrame")

        @session_startup begin
            df = DataFrame(
                Name = String["Alice", "Bob", "Carol"],
                Age  = Int[25, 32, 28],
                City = String["Lisbon", "Paris", "Berlin"]
            )
            set_session_data("df", df)
        end

        fragment() do
            row(fill_width=true, align_items="center") do
                df = get_session_data("df")
                cols = columns(2, justify_content="center")
                editable = cols[2].checkbox("editable", initial_value=true)
                cols[1].dataframe(df, editable=editable)

                optional_code = editable ? ", editable=$(editable)" : ""

                cols[2].code("""
                                using DataFrames
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

                link("Learn more", "/docs/version/latest/api-reference/interface-elements/dataframe", new_tab=true)
            end
        end

        section_separator()
        h2("File upload/download")
        file_path = joinpath(get_dot_magic_path(), "served-files/images/chart.png")

        fragment() do
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

                link("Learn more", "/docs/version/latest/api-reference/interface-elements/file_uploader", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                opt_row = cols[2].row()
                #fill_width = opt_row.checkbox("fill_width")

                optional_code = ""
                #optional_code *= fill_width ? ", fill_width=$(fill_width)" : ""

                cols[1].download_button("Download", file_path)
                cols[2].code("""
                                file_path = joinpath(get_dot_magic_path(), "served-files/images/chart.png")
                                download_button("Download", file_path$(optional_code))
                                """)

            link("Learn more", "/docs/version/latest/api-reference/interface-elements/download_button", new_tab=true)
            end
        end

        section_separator()

        h2("Image")

        row(fill_width=true, align_items="center", css=Dict("flex-shrink" => "1")) do
            cols = columns(2, justify_content="center")
            opt_row = cols[2].row()
            fill_width = opt_row.checkbox("fill_width")

            optional_code = ""
            optional_code *= fill_width ? ", fill_width=$(fill_width)" : ""

            cols[1].image(file_path, fill_width=fill_width)
            cols[2].code("""
                        file_path = joinpath(get_dot_magic_path(), "served-files/images/chart.png")
                        image(file_path$(optional_code))
                        """)

            link("Learn more", "/docs/version/latest/api-reference/interface-elements/image", new_tab=true)
        end

        section_separator()

        h2("Text and Markdown")

        row(fill_width=true, align_items="center") do
            cols = columns(2, justify_content="center")

            cols[1].h1("Heading 1")
            cols[1].h2("Heading 2")
            cols[1].h3("Heading 3")
            cols[1].h4("Heading 4")
            cols[1].h5("Heading 5")
            cols[1].h6("Heading 6")

            cols[2].code("""
                        h1("Heading")
                        h2("Heading")
                        h3("Heading")
                        h4("Heading")
                        h5("Heading")
                        h6("Heading")
                        """)

            link("Learn more", "/docs/version/latest/api-reference/interface-elements/h1", new_tab=true)
        end

        markdown("---")

        row(fill_width=true, align_items="center") do
            cols = columns(2, justify_content="center")

            cols[1].text("Regular text")
            cols[2].code("""text("Regular text")""")

            link("Learn more", "/docs/version/latest/api-reference/interface-elements/text", new_tab=true)
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

            link("Learn more", "/docs/version/latest/api-reference/interface-elements/markdown", new_tab=true)
        end

        markdown("---")

        fragment() do
            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                higher_is_better = cols[2].checkbox("higher_is_better", initial_value=true)

                optional_code = !higher_is_better ? ", higher_is_better=$(higher_is_better)" : ""

                cols[1].metric("Metric", 23.4, "ºC", delta=1.2, higher_is_better=higher_is_better)
                cols[2].code("""
                            metric("Metric", 23.4, "ºC", delta=1.2$(optional_code))
                            """)

                link("Learn more", "/docs/version/latest/api-reference/interface-elements/metric", new_tab=true)
            end
        end

        section_separator()

        h2("Flexible Layout")

        fragment() do
            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                selected_container = cols[2].radio("container", ["column", "row"], horizontal=true)

                opt_row = cols[2].row()
                fill_width = opt_row.checkbox("fill_width", initial_value=true)
                fill_height = opt_row.checkbox("fill_height", initial_value=true)
                show_border = opt_row.checkbox("show_border", initial_value=true)
                padding = opt_row.checkbox("padding")

                align_items = cols[2].radio("align_items", ["flex-start", "center", "flex-end"], horizontal=true, initial_value="center")

                justify_content = cols[2].radio("justify_content", ["flex-start", "center", "flex-end"], horizontal=true, initial_value="center")

                cnt = selected_container == "column" ?
                    cols[1].column(fill_width=fill_width, fill_height=fill_height, show_border=show_border, justify_content=justify_content, align_items=align_items,     padding=padding ? "20px" : "none") :
                    cols[1].row(fill_width=fill_width, fill_height=fill_height, show_border=show_border, justify_content=justify_content, align_items=align_items,     padding=padding ? "20px" : "none")

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

                link("Learn more", "/docs/version/latest/api-reference/layout-elements/$(selected_container)", new_tab=true)
            end

            markdown("---")

            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")
                num_columns = cols[2].radio("columns", [2, 3, 4, 5, 6], horizontal=true)
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

                link("Learn more", "/docs/version/latest/api-reference/layout-elements/columns", new_tab=true)
            end
        end

        section_separator()
        h2("Expander")

        fragment() do
            row(fill_width=true, align_items="center") do
                cols = columns(2, fill_height=true)

                cols[1].expander("Click to Expand") do
                    link("Github", "https://github.com/nidoro/Magic.jl")
                    link("Docs", "https://github.com/nidoro/Magic.jl")
                    link("Examples", "https://github.com/nidoro/Magic.jl")
                end

                cols[2].code("""
                                expander("Click to Expand") do
                                    link("Github", "https://github.com/nidoro/Magic.jl")
                                    link("Docs", "https://github.com/nidoro/Magic.jl")
                                    link("Examples", "https://github.com/nidoro/Magic.jl")
                                end
                                """)

                link("Learn more", "/docs/version/latest/api-reference/layout-elements/expander", new_tab=true)
            end
        end

        section_separator()
        h2("Dialog")

        fragment("dialog_example") do
            row(fill_width=true, align_items="center") do
                cols = columns(2, justify_content="center")

                if cols[1].button("Open Dialog")
                    dialog() do
                        h2("Dialog")
                        text_input("Enter your name", fill_width=true, id="name")
                        if button("Confirm", style="primary")
                            rerun("dialog_example")
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

                link("Learn more", "/docs/version/latest/api-reference/layout-elements/dialog", new_tab=true)
            end
        end

        section_separator()
        h2("Long running jobs")

        fragment() do
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

                link("Learn more", "/docs/version/latest/api-reference/jobs/@job", new_tab=true)
            end
        end

        section_separator()
        h2("Fragments")

        row(fill_width=true, align_items="center") do
            cols = columns(2, justify_content="center")

            @session_startup begin
                set_session_data("inner_reruns", 0)
                set_session_data("outer_reruns", 0)
            end

            cols(1) do
                fragment() do
                    fragment() do
                        button("Inner Fragment Button")
                        inner_reruns = get_session_data("inner_reruns") + 1
                        text("Inner reruns: $(inner_reruns)")
                        set_session_data("inner_reruns", inner_reruns)
                    end

                    button("Outer Fragment Button")
                    outer_reruns = get_session_data("outer_reruns") + 1
                    text("Outer reruns: $(outer_reruns)")
                    set_session_data("outer_reruns", outer_reruns)
                end
            end

            cols[2].code("""
                            @session_startup begin
                                set_session_data("inner_reruns", 0)
                                set_session_data("outer_reruns", 0)
                            end

                            fragment() do
                                fragment() do
                                    button("Inner Fragment Button")
                                    inner_reruns = get_session_data("inner_reruns") + 1
                                    text("Inner reruns: \$(inner_reruns)")
                                    set_session_data("inner_reruns", inner_reruns)
                                end

                                button("Outer Fragment Button")
                                outer_reruns = get_session_data("outer_reruns") + 1
                                text("Outer reruns: \$(outer_reruns)")
                                set_session_data("outer_reruns", outer_reruns)
                            end
                            """)

            link("Learn more", "/docs/version/latest/api-reference/application-logic/@fragment", new_tab=true)
        end

        section_separator()
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

            link("Learn more", "/docs/version/latest/api-reference/interface-elements/html", new_tab=true)
        end

        markdown("---")

        space(height="3rem")
        h1("Get started now!", css=Dict("align-self" => "center"))

        row(fill_width=true, justify_content="center") do
            link("Get Started", "/docs/version/latest/getting-started/install", new_tab=true, style="primary")
            link("Issues", "https://github.com/nidoro/Magic.jl/issues", new_tab=true)
        end

        space(height="4rem")
        column(fill_width=true, align_items="center") do
            column() do
                markdown("Made with [Magic.jl](https://github.com/nidoro/Magic.jl)")
            end
        end
        space(height="1rem")
    end
end
