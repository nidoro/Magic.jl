
function update_theme(widget_id::String)::Nothing
    theme = get_value(widget_id)
    set_theme(theme)
    Magic.set_value("btn_theme", theme)
    if is_on_page("/home")
        set_value("theme_example", theme)
    end
    return nothing
end

top_bar() do
    row(fill_width=true, align_items="center", max_width="100%", css=Dict("flex-wrap" => "wrap")) do
        row(link="/").image("/Magic.jl/images/magic-logo-and-grey-text.svg", max_width="150px")
        link("Examples", "/examples", style="naked")
        link("Getting Started", "/docs/version/latest/getting-started/install", style="naked")
        link("Documentation", "/docs", style="naked")
        link("GitHub", "https://github.com/nidoro/Magic.jl", style="naked", new_tab=true)
        cycle_button(
            ["auto", "light", "dark"],
            style="naked",
            labels=["<mg-icon mg-icon='material/light_mode'></mg-icon>", "<mg-icon mg-icon='material/dark_mode'></mg-icon>", "<mg-icon mg-icon='material/brightness_4'></mg-icon>"],
            id="btn_theme",
            onchange=update_theme,
            args=["btn_theme"],
            css=Dict("margin-left" => "auto")
        )
    end
end

