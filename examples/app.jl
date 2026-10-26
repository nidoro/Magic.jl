using Magic
using DataFrames

@app_startup begin
    add_page(["/", "/home"])
    add_page("/examples")
    add_page("/examples/counter")
    add_page("/examples/todo")
    add_page("/examples/curves")
    add_page("/examples/probability-density")
    add_page("/examples/avatar")
    add_page("/examples/forecast")
    add_page("/examples/seattle-weather")
    add_page("/examples/image-filters")
    add_page("/examples/fragment-example")
    add_page("/examples/optimization")
end

if is_on_page("/")
    include("home.jl")
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
    elseif is_on_page("/examples/optimization")
        page_script = "70-optimization.jl"
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
        top_bar="fixed"
    )

    include("top-bar.jl")

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

            cols = columns(2, show_border=true, padding=".8rem", justify_content="space-between")

            cols(1) do
                h5("TSP Optimization")
                text("Long running async jobs")
                link("Open", "/examples/optimization", style="primary")
            end

            cols[2].container["css"]["opacity"] = 0;
        end
    else
        include(page_script)
    end

    left_sidebar() do
        column(fill_width=true, gap="0px") do
            space(height="3rem")
            h5("Magic Examples", css=Dict("margin" => "0 0 .8rem .8rem", "white-space" => "nowrap", "opacity" => "0.6"))
            link("Overview", "/examples", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("Counter", "/examples/counter", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("To-Do List", "/examples/todo", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("Sliding Curves", "/examples/curves", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("Probability Viewer", "/examples/probability-density", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("Avatar Creator", "/examples/avatar", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("Brazil Forecast", "/examples/forecast", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("Seattle Weather", "/examples/seattle-weather", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("Image Filters", "/examples/image-filters", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
            link("TSP Optimization", "/examples/optimization", style="naked", fill_width=true, css=Dict("justify-content" => "flex-start"))
        end
    end

    right_sidebar() do
        code(initial_value_file=joinpath(@__DIR__, page_script))
    end
end
