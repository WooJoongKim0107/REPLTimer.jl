using REPLTimer
using Test

# What it tests:
#
# The package feature is a small REPL hook: enable_timed_repl replaces
# repl.interface.modes[1].on_done with a wrapper that times each evaluation.
# These tests use a minimal mock REPL with that same field path instead of
# launching an interactive Julia REPL.
#
# The suite verifies that the wrapper is installed, delegates the original
# arguments, preserves the original return value, prints timing output only
# when the threshold is exceeded, and still propagates exceptions. It does not
# test the visual terminal behavior of cursor-control escape sequences in a
# real interactive REPL.
mutable struct MockMode
    on_done::Function
end

struct MockInterface
    modes::Vector{MockMode}
end

struct MockREPL
    interface::MockInterface
end

mock_repl(on_done=(s, buf, ok) -> nothing) = begin
    mode = MockMode(on_done)
    MockREPL(MockInterface([mode])), mode
end

call_on_done(mode; s=nothing, buf=nothing, ok=true) = mode.on_done(s, buf, ok)

function captured_stdout(f)
    path, io = mktemp()
    try
        redirect_stdout(io) do
            f()
        end
        close(io)
        return read(path, String)
    finally
        isopen(io) && close(io)
        isfile(path) && rm(path)
    end
end

@testset "REPLTimer.jl" begin
    @testset "enable_timed_repl installs a wrapper" begin
        repl, mode = mock_repl()
        original_on_done = mode.on_done

        enable_timed_repl(repl)

        @test mode.on_done isa Function
        @test mode.on_done !== original_on_done
    end

    @testset "wrapped on_done delegates arguments and return value" begin
        seen = Ref{Tuple{Any,Any,Bool}}()
        repl, mode = mock_repl() do s, buf, ok
            seen[] = (s, buf, ok)
            :result
        end

        enable_timed_repl(repl)

        state = (prompt=:julia,)
        buffer = IOBuffer("1 + 1")
        @test call_on_done(mode; s=state, buf=buffer, ok=false) === :result
        @test seen[] === (state, buffer, false)
    end

    @testset "output respects threshold" begin
        repl, mode = mock_repl()
        enable_timed_repl(repl, Inf)

        @test captured_stdout(() -> call_on_done(mode)) == ""

        repl, mode = mock_repl()
        enable_timed_repl(repl, -Inf)

        output = captured_stdout(() -> call_on_done(mode))
        @test occursin(r"\e\[1A\r\e\[2K\e\[90m\[\d+\.\d+ sec\]\e\[0m\n", output)
    end

    @testset "default threshold suppresses fast evaluations" begin
        repl, mode = mock_repl()
        enable_timed_repl(repl)

        @test captured_stdout(() -> call_on_done(mode)) == ""
    end

    @testset "exceptions propagate after timing cleanup" begin
        repl, mode = mock_repl() do _s, _buf, _ok
            error("boom")
        end

        enable_timed_repl(repl, Inf)
        @test_throws ErrorException call_on_done(mode)

        repl, mode = mock_repl() do _s, _buf, _ok
            error("boom")
        end

        enable_timed_repl(repl, -Inf)
        output = captured_stdout() do
            try
                call_on_done(mode)
            catch err
                @test err isa ErrorException
            end
        end

        @test occursin(r"\[\d+\.\d+ sec\]", output)
    end
end
