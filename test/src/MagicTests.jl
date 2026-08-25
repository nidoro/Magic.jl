#-------------------------------------------------------------------------------
# How to run these tests
#-------------------------------------------------------------------------------
#
# > cd test
# > julia --project
# pkg> dev ..
# pkg> instantiate
# julia> using Revise, Magic, MagicTests, ReTest
# julia> retest(#= optional test name or number =#)
#
#-------------------------------------------------------------------------------
module MagicTests

using ReTest
using Magic

const PORT = 0
const SUPPRESS_OUTPUT = false

macro maybe_suppress(ex)
    quote
        if SUPPRESS_OUTPUT
            redirect_stdout(devnull) do
                redirect_stderr(devnull) do
                    $(esc(ex))
                end
            end
        else
            $(esc(ex))
        end
    end
end

include("unit_tests_logic.jl")
include("unit_tests_elements.jl")
include("e2e_tests_examples.jl")

end
