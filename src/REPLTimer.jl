module REPLTimer

export enable_timed_repl

# Wraps julia_mode.on_done to print elapsed time after each evaluation exceeding thr_sec.
function enable_timed_repl(repl, thr_sec=10)
    julia_mode = repl.interface.modes[1]

    old_on_done = julia_mode.on_done
    julia_mode.on_done = function (s, buf, ok)
        t0 = time()
        try
            return old_on_done(s, buf, ok)
        finally
            elapsed_sec = time() - t0
            if elapsed_sec > thr_sec
                print("\033[1A")
                print("\r")
                print("\033[2K")
                print("\033[90m[$(round(elapsed_sec; digits=4)) sec]\033[0m\n")
            end
        end
    end
end

end # module REPLTimer
