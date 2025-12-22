# ✨ Lit.jl

## A new way of creating Julia web apps!

> 🧪 **Experimental**:
> This package is in early stage of development. You are welcomed to try it out
> and give us your feedback!

## Quick start
### 0. Install:
```julia
using Pkg
Pkg.add(url="https://github.com/nidoro/Lit.jl")
```

### 1. Implement `app.jl`:
```julia
# app.jl
using Main.Lit
if button("Click me")
    text("Button Clicked!")
end
```

### 2. Start REPL and run `app.jl`
```julia
using Lit
@start
```

## Demo Web Apps

