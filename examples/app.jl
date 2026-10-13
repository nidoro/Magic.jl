using Magic
using DataFrames

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
                h1("The easiest way of creating Julia web apps", show_anchor_link=false, css=Dict("margin-bottom" => "2rem", "text-align" => "center"))

                column() do
                    markdown("Create an `app.jl` file and start your app from the REPL:")
                end

                code("""
                    > using Magic
                    > start_app()
                    """, fill_width=false)

                space(height="1.5rem")
            end

            h3("Basic widgets")

            cols = columns(2, justify_content="center")
            cols(1) do
                row(align_items="center") do
                    if button("Button")
                        text("Clicked!")
                    end
                end
            end
            cols(2) do
                code("""
                    if button("Button")
                        text("Clicked!")
                    end
                    """)
            end

            markdown("---")

            cols = columns(2, justify_content="center")
            cols(1) do
                option = selectbox("Selectbox", ["A", "B", "C"])
                markdown("`option = $(option)`")
            end
            cols(2) do
                code("""option = selectbox("Selectbox", ["A", "B", "C"])""")
            end

            markdown("---")

            cols = columns(2, justify_content="center")
            cols(1) do
                checked = checkbox("Checkbox")
                markdown("`checked = $(checked)`")
            end
            cols(2) do
                code("""checked = checkbox("Checkbox")""")
            end

            markdown("---")

            cols = columns(2, justify_content="center")
            cols(1) do
                option = nothing
                row() do
                    option = radio("Radio", ["A", "B", "C"])
                end
                markdown("`option = $(option)`")
            end
            cols(2) do
                code("""option = radio("Radio", ["A", "B", "C"])""")
            end

            markdown("---")

            cols = columns(2, justify_content="center")
            cols(1) do
                text = text_input("Text input")
                markdown("`text = $(text)`")
            end
            cols(2) do
                code("""text = text_input("Text input")""")
            end

            markdown("---")

            cols = columns(2, justify_content="center")
            cols(1) do
                number = number_input("Number input")
                markdown("`number = $(number)`")
            end
            cols(2) do
                code("""number = number_input("Number input")""")
            end

            markdown("---")

            cols = columns(2, justify_content="center")
            cols(1) do
                number = slider("Slider")
                markdown("`number = $(number)`")
            end
            cols(2) do
                code("""number = slider("Slider")""")
            end

            markdown("---")
            space(height="1rem")

            h3("DataFrame")

            cols = columns(2, justify_content="center")
            cols(1) do
                @session_startup begin
                    df = DataFrame(
                        Name = String["Alice", "Bob", "Carol"],
                        Age  = Int[25, 32, 28],
                        City = String["Lisbon", "Paris", "Berlin"]
                    )
                    set_session_data("df", df)
                end

                df = get_session_data("df")
                dataframe(df, column_config=Dict("Age" => Dict("editable" => true)))
                markdown("`df = 👇`")
                code(repr(df), fill_width=false)
            end
            cols(2) do
                code("""
                    @session_startup begin
                        df = DataFrame(
                            name = String["Alice", "Bob", "Carol"],
                            age  = Int[25, 32, 28],
                            city = String["Lisbon", "Paris", "Berlin"]
                        )
                        set_session_data("df", df)
                    end
                    df = get_session_data("df")
                    dataframe(df, column_config=Dict("age" => Dict("editable" => true)))
                    """)
            end

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
