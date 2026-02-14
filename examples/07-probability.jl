using Magic
using VegaLite
using Distributions
using DataFrames

const CHART_WIDTH           = 600
const CHART_HEIGHT          = 400
const TICK_FONT_SIZE        = 14
const AXIS_LABEL_FONT_SIZE  = 16
const TITLE_FONT_SIZE       = 18

column(fill_width=true, align_items="flex-start") do
    h3("📊 Probability Density Function Viewer")

    distr = selectbox("Function", ["Normal", "Student's", "Exponential", "Gamma", "Beta"], initial_value="Normal", fill_width=true)

    chart = nothing

    if distr == "Normal"
        @push row(fill_width=true)
            mean = number_input("Mean (µ)", initial_value=0)
            std = number_input("Standard Deviation (σ)", initial_value=1, min=0.01, precision=2)
        @pop

        if mean !== nothing && std !== nothing
            df = DataFrame(
                x = range(mean-4*std, mean+4*std, length=200)
            )
            df.y = pdf.(Normal(mean, std), df.x)

            chart = df |> @vlplot(
                mark={:area, color="#4682B4", opacity=0.05, line=true},
                x={:x, scale={domain=[minimum(df.x), maximum(df.x)], nice=false}},
                y={:y, scale={domain=[minimum(df.y), maximum(df.y)], nice=false}, axis={format=".2f"}, title="Density"},
                width=CHART_WIDTH,
                height=CHART_HEIGHT,
                title="Normal",
                config={
                    axis={
                        labelFontSize=TICK_FONT_SIZE,
                        titleFontSize=AXIS_LABEL_FONT_SIZE
                    },
                    title={
                        fontSize=TITLE_FONT_SIZE,
                    }
                }
            )
        end

    elseif distr == "Student's"
        freedom = number_input("Degrees of freedom", initial_value=5, min=0.01, precision=2)

        if freedom !== nothing
            x = range(-freedom, freedom, length=200)
            df = DataFrame(x=x, y=pdf.(TDist(freedom), x))

            chart = df |> @vlplot(
                :line,
                x={:x, scale={domain=[minimum(df.x), maximum(df.x)], nice=false}},
                y={:y, scale={domain=[minimum(df.y), maximum(df.y)], nice=false}, axis={format=".2f"}, title="Density"},
                width=CHART_WIDTH,
                height=CHART_HEIGHT,
                title="Student's t-Distribution",
                config={
                    axis={
                        labelFontSize=TICK_FONT_SIZE,
                        titleFontSize=AXIS_LABEL_FONT_SIZE
                    },
                    title={
                        fontSize=TITLE_FONT_SIZE,
                    }
                }
            )
        end

    elseif distr == "Exponential"
        rate = number_input("Rate (λ)", initial_value=1.0, min=0.01, precision=2)

        if rate !== nothing
            # For exponential, use x range from 0 to ~5/rate (covers most of the distribution)
            x_max = 5 / rate
            x = range(0, x_max, length=200)
            df = DataFrame(x=x, y=pdf.(Exponential(1/rate), x))

            chart = df |> @vlplot(
                mark={:area, color="#4682B4", opacity=0.05, line=true},
                x={:x, scale={domain=[minimum(df.x), maximum(df.x)], nice=false}},
                y={:y, scale={domain=[minimum(df.y), maximum(df.y)], nice=false}, axis={format=".2f"}, title="Density"},
                width=CHART_WIDTH,
                height=CHART_HEIGHT,
                title="Exponential",
                config={
                    axis={
                        labelFontSize=TICK_FONT_SIZE,
                        titleFontSize=AXIS_LABEL_FONT_SIZE
                    },
                    title={
                        fontSize=TITLE_FONT_SIZE,
                    }
                }
            )
        end

    elseif distr == "Gamma"
        @push row(fill_width=true)
            shape = number_input("Shape (α)", initial_value=2.0, min=0.01, precision=2)
            rate = number_input("Rate (β)", initial_value=1.0, min=0.01, precision=2)
        @pop

        if shape !== nothing && rate !== nothing
            x_max = max(10, (shape/rate) * 4)
            x = range(0, x_max, length=200)
            df = DataFrame(x=x, y=pdf.(Gamma(shape, 1/rate), x))

            chart = df |> @vlplot(
                mark={:area, color="#4682B4", opacity=0.05, line=true},
                x={:x, scale={domain=[minimum(df.x), maximum(df.x)], nice=false}},
                y={:y, scale={domain=[minimum(df.y), maximum(df.y)], nice=false}, axis={format=".2f"}, title="Density"},
                width=CHART_WIDTH,
                height=CHART_HEIGHT,
                title="Gamma Distribution",
                config={
                    axis={
                        labelFontSize=TICK_FONT_SIZE,
                        titleFontSize=AXIS_LABEL_FONT_SIZE
                    },
                    title={
                        fontSize=TITLE_FONT_SIZE,
                    }
                }
            )
        end

    elseif distr == "Beta"
        @push row(fill_width=true)
            alpha = number_input("Alpha (α)", initial_value=2.0, min=0.01, precision=2)
            beta_param = number_input("Beta (β)", initial_value=2.0, min=0.01, precision=2)
        @pop

        if alpha !== nothing && beta_param !== nothing
            # Beta is defined on [0, 1]
            x = range(0, 1, length=200)
            df = DataFrame(x=x, y=pdf.(Beta(alpha, beta_param), x))

            chart = df |> @vlplot(
                mark={:area, color="#4682B4", opacity=0.05, line=true},
                x={:x, scale={domain=[minimum(df.x), maximum(df.x)], nice=false}},
                y={:y, scale={domain=[minimum(df.y), maximum(df.y)], nice=false}, axis={format=".2f"}, title="Density"},
                width=CHART_WIDTH,
                height=CHART_HEIGHT,
                title="Beta Distribution",
                config={
                    axis={
                        labelFontSize=TICK_FONT_SIZE,
                        titleFontSize=AXIS_LABEL_FONT_SIZE
                    },
                    title={
                        fontSize=TITLE_FONT_SIZE,
                    }
                }
            )
        end
    end

    if chart !== nothing
        chart_path = gen_serveable_path("png")
        save(chart_path, chart)
        image(chart_path, fill_width=true)
    end
end
