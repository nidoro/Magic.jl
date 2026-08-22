
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
