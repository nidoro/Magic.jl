using Magic
using JuMP
using HiGHS
using Random

const SVG_SIZE = 400
const SVG_MARGIN = 20

function generate_instance(n::Int)::Vector{Tuple{Float64, Float64}}
    return [(rand(), rand()) for _ in 1:n]
end

function distance(a::Tuple{Float64, Float64}, b::Tuple{Float64, Float64})::Float64
    return sqrt((a[1] - b[1])^2 + (a[2] - b[2])^2)
end

function tour_length(points::Vector{Tuple{Float64, Float64}}, tour::Vector{Int})::Float64
    return sum(distance(points[tour[i]], points[tour[mod1(i + 1, length(tour))]]) for i in eachindex(tour))
end

# Splits the selected edges of a solution into connected components (subtours)
function find_subtours(edges::Vector{Tuple{Int, Int}}, n::Int)::Vector{Vector{Int}}
    neighbors = [Int[] for _ in 1:n]
    for (i, j) in edges
        push!(neighbors[i], j)
        push!(neighbors[j], i)
    end

    visited = falses(n)
    subtours = Vector{Vector{Int}}()
    for start in 1:n
        visited[start] && continue
        subtour = Int[]
        stack = [start]
        while !isempty(stack)
            i = pop!(stack)
            visited[i] && continue
            visited[i] = true
            push!(subtour, i)
            append!(stack, neighbors[i])
        end
        push!(subtours, subtour)
    end
    return subtours
end

# Walks the edges of a single cycle to get the order in which cities are visited
function edges_to_tour(edges::Vector{Tuple{Int, Int}}, n::Int)::Vector{Int}
    neighbors = [Int[] for _ in 1:n]
    for (i, j) in edges
        push!(neighbors[i], j)
        push!(neighbors[j], i)
    end

    tour = [1]
    previous, current = 0, 1
    while length(tour) < n
        next = neighbors[current][1] == previous ? neighbors[current][2] : neighbors[current][1]
        push!(tour, next)
        previous, current = current, next
    end
    return tour
end

# Solves the TSP by iteratively adding subtour elimination constraints.
# This function runs inside a job, so it reports its progress with
# set_progress(), which also lets the user stop the job between iterations.
function solve_tsp(points::Vector{Tuple{Float64, Float64}})::Vector{Int}
    n = length(points)

    set_progress(0.0, message="Building model...")
    model = Model(HiGHS.Optimizer)
    set_silent(model)

    @variable(model, x[i=1:n, j=i+1:n], Bin)
    @objective(model, Min, sum(distance(points[i], points[j]) * x[i, j] for i in 1:n, j in i+1:n))
    @constraint(model, [k=1:n], sum(x[min(i, k), max(i, k)] for i in 1:n if i != k) == 2)

    iteration = 0
    while true
        iteration += 1
        optimize!(model)

        edges = [(i, j) for i in 1:n for j in i+1:n if value(x[i, j]) > 0.5]
        subtours = find_subtours(edges, n)

        if length(subtours) == 1
            set_progress(1.0, message="Optimal tour found!")
            return edges_to_tour(edges, n)
        end

        for subtour in subtours
            @constraint(model, sum(x[min(i, j), max(i, j)] for i in subtour, j in subtour if i < j) <= length(subtour) - 1)
        end

        set_progress(iteration / (iteration + 5), message="Iteration $(iteration): eliminated $(length(subtours)) subtours")
    end
end

function to_svg_coords(p::Tuple{Float64, Float64})::Tuple{Float64, Float64}
    scale = SVG_SIZE - 2 * SVG_MARGIN
    return (SVG_MARGIN + p[1] * scale, SVG_MARGIN + p[2] * scale)
end

function instance_svg(points::Vector{Tuple{Float64, Float64}}, tour::Union{Vector{Int}, Nothing})::String
    svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $(SVG_SIZE) $(SVG_SIZE)" width="100%" style="max-width: $(SVG_SIZE)px; background: white; border: 1px solid #d6d6d6; border-radius: .5rem">"""

    if !isnothing(tour)
        path_points = join(["$(x),$(y)" for (x, y) in to_svg_coords.(points[tour])], " ")
        svg *= """<polygon points="$(path_points)" fill="none" stroke="#3b82f6" stroke-width="2"/>"""
    end

    for p in points
        x, y = to_svg_coords(p)
        svg *= """<circle cx="$(x)" cy="$(y)" r="5" fill="#ef4444"/>"""
    end

    return svg * "</svg>"
end

# App
#-------
column(fill_width=true, align_items="center", css=Dict("text-align" => "center")) do
    h1("Traveling Salesman Problem")
    markdown("Powered by [JuMP](https://github.com/jump-dev/JuMP.jl) and [HiGHS](https://ergo-code.github.io/HiGHS/dev/interfaces/julia/).")
end

# NOTE: the solver call blocks the thread it runs on, so with a single thread
# the job would also block the app until the solver returns.
if Threads.nthreads() == 1
    markdown("Tip: start Julia with multiple threads (e.g. `julia -t auto`) to keep the app responsive while the problem is being solved.")
end

@push row(align_items="flex-end", fill_width=true)
    set_default_value("slc_cities", 75)
    num_cities = selectbox("Number of cities", [25, 50, 75, 100], fill_width=true, id="slc_cities")
    regenerate = button("New instance", icon="material/refresh")
    solve = button("Solve", style="primary", icon="material/route")
@pop

if regenerate || get_session_data("num_cities") !== num_cities
    set_session_data("num_cities", num_cities)
    set_session_data("points", generate_instance(num_cities))
    set_session_data("instance_id", randstring(8))
end

points = get_session_data("points")

# Each instance has its own job id, so the solution of an old instance is never
# displayed for a new one.
job_id = "tsp_$(get_session_data("instance_id"))"

if solve
    instance = copy(points)
    @job(job_id, dialog_title="Solving TSP") do
        return solve_tsp(instance)
    end
end

tour = nothing
if job_exists(job_id) && is_done(job_id) && get_result(job_id) isa Vector{Int}
    tour = get_result(job_id)
end

html("div", instance_svg(points, tour))

if !isnothing(tour)
    text("Tour length: $(round(tour_length(points, tour), digits=3))")
elseif job_exists(job_id) && is_errored(job_id)
    text("Something went wrong while solving the problem.")
end
