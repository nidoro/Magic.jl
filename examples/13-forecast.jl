ENV["GMT_USERDIR"] = mktempdir()
using GMT
using Random
using Printf

function polygon_centroid(st)
    x = st.data[:, 1]
    y = st.data[:, 2]
    n = length(x)

    A  = 0.0
    Cx = 0.0
    Cy = 0.0

    for i in 1:n-1
        cross = x[i] * y[i+1] - x[i+1] * y[i]
        A  += cross
        Cx += (x[i] + x[i+1]) * cross
        Cy += (y[i] + y[i+1]) * cross
    end

    # close polygon (last → first)
    cross = x[n] * y[1] - x[1] * y[n]
    A  += cross
    Cx += (x[n] + x[1]) * cross
    Cy += (y[n] + y[1]) * cross

    A *= 0.5

    return Cx / (6A), Cy / (6A)
end

# Clamp helper
clamp01(x) = max(0.0, min(1.0, x))

function temp_to_rgb(temp)
    tmin = 5.0
    tmax = 35.0

    α = clamp01((temp - tmin) / (tmax - tmin))

    # Yellow (255,255,0) → muted red (200,40,40)
    r = round(Int, 255*(1-α) + 200*α)
    g = round(Int, 255*(1-α) +  40*α)
    b = round(Int,   0*(1-α) +  40*α)

    return "$(r)/$(g)/$(b)"
end

function outlined_text!(
    x, y, label;
    font = "10p,Helvetica-Bold",
    textcolor = "black",
    outlinecolor = "white",
    outlinesize = 0.2,   # in plot units
    justify = :CM
)
    # Offsets around the text
    offsets = [
        (-outlinesize, 0),
        ( outlinesize, 0),
        (0, -outlinesize),
        (0,  outlinesize),
        (-outlinesize, -outlinesize),
        (-outlinesize,  outlinesize),
        ( outlinesize, -outlinesize),
        ( outlinesize,  outlinesize),
    ]

    # Draw outline (layered)
    for (dx, dy) in offsets
        text!(
            [x+dx y+dy];
            text = label,
            font = "$font,$outlinecolor",
            justify = :CM
        )
    end

    # Draw main text on top
    text!(
        [x y];
        text = label,
        font = "$font,$textcolor",
        justify = :CM
    )
end

states = gmtread("data/gadm41_BRA_shp/gadm41_BRA_1.shp")

best = Dict{String, GMTdataset}()

for st in states
    id = st.attrib["Feature_ID"]
    npts = size(st.data, 1)

    if !haskey(best, id) || npts > size(best[id].data, 1)
        best[id] = st
    end
end

states_max_points = collect(values(best))

temps = Dict{String, Float64}()

for st in states_max_points
    id = st.attrib["Feature_ID"]
    temps[id] = rand(15.0:0.1:35.0)
end

colors = [
    "lightblue", "lightgreen", "lightyellow", "lightpink",
    "lightsalmon", "lightcyan", "khaki", "plum"
]

gmtbegin("brazil_states_last_polygon.png")

basemap(region=:BR, proj=:Mercator, frame=0)

for (i, st) in enumerate(states_max_points)
    id   = st.attrib["Feature_ID"]
    temp = temps[id]
    fill = temp_to_rgb(temp)

    plot!(
        st,
        fill = fill,
        pen  = "0.25p,black"
    )
end

for (i, st) in enumerate(states_max_points)
    id   = st.attrib["Feature_ID"]
    temp = temps[id]
    label = @sprintf("%.0f\\260C", temp)
    cx, cy = polygon_centroid(st)

    outlined_text!(
        cx, cy, label;
        font = "10p,Helvetica-Bold",
        textcolor = "darkred",
        outlinecolor = "white",
        outlinesize = 0.075
    )
end

gmtend()
