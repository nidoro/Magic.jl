
function buffer_to_string(buffer::NTuple{N, UInt8}) where N
    # Find the null terminator
    null_pos = findfirst(==(0x00), buffer)
    if null_pos === nothing
        # No null terminator, use entire buffer
        return String(collect(buffer))
    else
        # Convert only up to null terminator
        return String(collect(buffer[1:null_pos-1]))
    end
end

function string_to_buffer(::Val{N}, s::AbstractString)::NTuple{N, UInt8} where N
    bytes = codeunits(s)
    maxlen = N - 1
    len = min(length(bytes), maxlen)

    return ntuple(i ->
        i <= len ? bytes[i] :
        i == len + 1 ? 0x00 :
        0x00,
        N
    )
end

function remove_lines_starting_with(err::String, prefix::String)::String
    lines = split(err, '\n')
    keep = filter(l -> !startswith(lstrip(l), prefix), lines)
    return join(keep, '\n')
end

function try_rm(path::String; kwargs...)::Bool
    try
        rm(path; kwargs...)
        return true
        catch e
        return false
    end
end

# NOTE: functions to open browser. Copied from LiveServer.jl
#-------------------------------------------------------------
function detectwsl()
    Sys.islinux() &&
    isfile("/proc/sys/kernel/osrelease") &&
    occursin(r"Microsoft|WSL"i, read("/proc/sys/kernel/osrelease", String))
end

function open_in_default_browser(url::AbstractString)::Bool
    try
        if Sys.isapple()
            Base.run(`open $url`)
            true
        elseif Sys.iswindows() || detectwsl()
            Base.run(`cmd.exe /s /c start "" /b $url`)
            true
        elseif Sys.islinux()
            Base.run(`xdg-open $url`)
            true
        else
            false
        end
    catch
        false
    end
end

function is_valid_hostname(hostname::String)
    # Overall length limit
    length(hostname) > 253 && return false
    isempty(hostname) && return false

    # Split into labels and validate each
    labels = split(hostname, '.')
    for label in labels
        isempty(label) && return false
        length(label) > 63 && return false
        # Must start/end with alphanumeric, may contain hyphens in the middle
        occursin(r"^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?$", label) || return false
    end

    return true
end

function assert_string_in_list(arg::Tuple, white_list::Tuple)::Nothing
    arg[2] in white_list || throw(InvalidArgument(arg, "`$(arg[1])` should be one of these: $(white_list)."))
    return nothing
end

function assert_key_in_dict(arg::Tuple, dict::Dict)::Nothing
    haskey(dict, arg[2]) || throw(InvalidArgument(arg, "`$(arg[1])` : $(white_list)."))
    return nothing
end

function assert_valid_material_icon(args::Tuple)::Nothing
    if !startswith(args[2], "material/")
        throw(InvalidArgument(args, "`icon` must have the format \"material/icon_name\". Example: \"material/person\""))
    end

    icon_name = replace(args[2], "material/" => "")
    if !haskey(MATERIAL_ICON_CODEPOINTS, icon_name)
        throw(InvalidArgument(args, "\"$(icon_name)\" is not a valid icon name. Checkout https://fonts.google.com/icons?icon.set=Material+Icons to find the name of the icon you want."))
    end
    return nothing
end

function function_accepts_arg_count(f::Function, arg_count::Int)::Bool
    ms = methods(f)
    ok = any(ms) do m
        m.nargs-1 == arg_count
    end
    return ok
end

function get_item_by_its_stringified_version(list::Union{Vector, Tuple}, rep::String)::Any
    for entry in list
        if typeof(entry) <: Number
            rep_number = tryparse(typeof(entry), rep)
            if !isnothing(rep_number)
                if isapprox(entry, rep_number, atol=0.000000001)
                    return entry
                end
            end
        elseif entry == rep
            return entry
        end
    end
    return missing
end

function print_stacktrace(;skip::Int=0)::Nothing
    frames = stacktrace()
    println(sprint(Base.show_backtrace, frames[(skip+1):end]))
    return nothing
end

function caller_location()::String
    frame = stacktrace()[4]
    return "$(frame.file):$(frame.line)"
end

function coalesce(args...)
    for arg in args
        if arg !== nothing && arg !== missing
            return arg
        end
    end
    return nothing
end
