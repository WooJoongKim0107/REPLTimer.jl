# REPLTimer.jl

Prints elapsed time in the Julia REPL after any evaluation that takes longer than a threshold.

```
julia> sleep(11)

[11.001 sec]
```

The timer line overwrites the trailing newline so output stays compact.

## Usage

Call `enable_timed_repl` inside `atreplinit` in your `startup.jl`:

```julia
using REPLTimer

atreplinit() do repl
    if !isdefined(repl, :interface)
        repl.interface = REPL.setup_interface(repl)
    end
    enable_timed_repl(repl)          # default threshold: 10 seconds
    # enable_timed_repl(repl, 0.5)   # show timing for anything over 0.5 s
end
```

## Installation

```julia
using Pkg
Pkg.add("REPLTimer")
```
