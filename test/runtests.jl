using Test
using REPLTimer

# Minimal mock of the REPL interface that enable_timed_repl accesses:
#   repl.interface.modes[1].on_done
mutable struct MockMode
    on_done::Function
end

mutable struct MockInterface
    modes::Vector{Any}
end

mutable struct MockREPL
    interface::MockInterface
end

function mock_repl(f=(s, buf, ok) -> nothing)
    mode = MockMode(f)
    MockREPL(MockInterface(Any[mode])), mode
end

function capture_stdout(f)
    path = tempname()
    open(path, "w") do io
        redirect_stdout(f, io)
    end
    s = read(path, String)
    rm(path)
    s
end

@testset "REPLTimer" begin

    @testset "enable_timed_repl replaces on_done" begin
        repl, mode = mock_repl()
        original = mode.on_done
        enable_timed_repl(repl)
        @test mode.on_done !== original
    end

    @testset "original on_done is still called" begin
        called = Ref(false)
        repl, mode = mock_repl((s, buf, ok) -> (called[] = true))
        enable_timed_repl(repl)
        mode.on_done(nothing, nothing, true)
        @test called[]
    end

    @testset "original return value is preserved" begin
        repl, mode = mock_repl((s, buf, ok) -> 42)
        enable_timed_repl(repl)
        @test mode.on_done(nothing, nothing, true) == 42
    end

    @testset "prints timing when threshold exceeded" begin
        repl, mode = mock_repl()
        enable_timed_repl(repl, -1.0)  # negative threshold always triggers
        out = capture_stdout(() -> mode.on_done(nothing, nothing, true))
        @test occursin(r"\[\d+\.\d+ sec\]", out)
    end

    @testset "no output when below threshold" begin
        repl, mode = mock_repl()
        enable_timed_repl(repl, 9999.0)  # threshold far above any real elapsed time
        out = capture_stdout(() -> mode.on_done(nothing, nothing, true))
        @test isempty(out)
    end

    @testset "default threshold is 10 seconds" begin
        # Verify the default: a fast call produces no output
        repl, mode = mock_repl()
        enable_timed_repl(repl)  # default thr_sec = 10
        out = capture_stdout(() -> mode.on_done(nothing, nothing, true))
        @test isempty(out)
    end

    @testset "exception from evaluation propagates" begin
        repl, mode = mock_repl((s, buf, ok) -> error("boom"))
        enable_timed_repl(repl)
        @test_throws ErrorException mode.on_done(nothing, nothing, true)
    end

    @testset "prints timing even when evaluation throws" begin
        repl, mode = mock_repl((s, buf, ok) -> error("boom"))
        enable_timed_repl(repl, -1.0)  # negative threshold always triggers
        out = capture_stdout() do
            try
                mode.on_done(nothing, nothing, true)
            catch
            end
        end
        @test occursin(r"\[\d+\.\d+ sec\]", out)
    end

end
