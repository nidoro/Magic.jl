top_bar() do
    row(fill_width=true, max_width="100%", align_items="center", css=Dict("flex-wrap" => "wrap")) do
        row(link="/").image("/Magic.jl/images/magic-logo-and-grey-text.svg", max_width="150px")
        link("Examples", "/examples", style="naked")
        link("Getting Started", "/docs/version/latest/getting-started/install", style="naked")
        link("Documentation", "/docs", style="naked")
        link("GitHub", "https://github.com/nidoro/Magic.jl", style="naked", new_tab=true)
    end
end
