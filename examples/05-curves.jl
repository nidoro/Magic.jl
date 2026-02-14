using Magic
using DataFrames
using VegaLite

const MIN_SHIFT = -10.0
const MAX_SHIFT =  10.0
const MIN_SCALE = 0.1
const MAX_SCALE = 4.0

struct ExpFunction{A,B}
    scale::A
    shift::B
end

(m::ExpFunction)(x) = m.scale * exp(-(x - m.shift)^2)

h1("Sliding Curves")

cols = columns(2)

@push cols[1]
    f1_shift = slider("🔴 Curve Shift", initial_value=-2.2, step=0.1, min=MIN_SHIFT, max=MAX_SHIFT, precision=1, fill_width=true)
    f2_shift = slider("🟢 Curve Shift", initial_value=0.0, step=0.1, min=MIN_SHIFT, max=MAX_SHIFT, precision=1, fill_width=true)
@pop

@push cols[2]
    f1_scale = slider("🔴 Curve Scale", initial_value=3.0, step=0.1, min=MIN_SCALE, max=MAX_SCALE, precision=1, fill_width=true)
    f2_scale = slider("🟢 Curve Scale", initial_value=1.5, step=0.1, min=MIN_SCALE, max=MAX_SCALE, precision=1, fill_width=true)
@pop

f1 = ExpFunction(f1_scale, f1_shift)
f2 = ExpFunction(f2_scale, f2_shift)

x_values = range(MIN_SHIFT, MAX_SHIFT, length=200)

# Create DataFrame with all three curves
data = DataFrame(
    x = repeat(x_values, 3),
    y = vcat(
        f1.(x_values),
        f2.(x_values),
        (f1.(x_values) .+ f2.(x_values))
    ),
    function_name = vcat(
        fill("f1", length(x_values)),
        fill("f2", length(x_values)),
        fill("sum", length(x_values))
    ),
    line_style = vcat(
        fill("dotted", length(x_values)),
        fill("dotted", length(x_values)),
        fill("solid", length(x_values))
    )
)

chart = data |> @vlplot(
    mark = {:line, clip=true},
    x = :x,
    y = {:y, scale={domain=[0, 4]}},
    color = {
        :function_name,
        scale = {
            domain = ["f1", "f2", "sum"],
            range = ["red", "green", "blue"]
        }
    },
    strokeDash = {
        :line_style,
        scale = {
            domain = ["solid", "dotted"],
            range = [[0], [5, 5]]
        },
        legend = nothing
    },
    width = 600,
    height = 300,
    config = {legend = {disable = true}}
)

chart_path = gen_serveable_path("png")
save(chart_path, chart)

h5("🔵 = 🔴 + 🟢")
image(chart_path, fill_width=true)
