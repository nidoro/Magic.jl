# get_jobs

Retrieves the ids of all jobs of the current session.

### Function Signature

```julia
function get_jobs()::Vector{String}
```

### Return Value

A `Vector{String}` with the ids of the jobs created with `@job` in the current session.
