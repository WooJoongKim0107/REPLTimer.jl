# REPLTimer.jl

Prints elapsed time in the Julia REPL after any evaluation that exceeds a configurable threshold (default: 10 seconds).

```
julia> sleep(11)
[11.001 sec]
```

The timing line replaces the trailing blank line, so the output stays compact.

## Installation

Not yet registered in the Julia General Registry. Install directly from GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/WooJoongKim0107/REPLTimer.jl")
```

## Usage

Add the following to `~/.julia/config/startup.jl`:

```julia
using REPLTimer

atreplinit() do repl
    if !isdefined(repl, :interface)
        repl.interface = REPL.setup_interface(repl)
    end
    enable_timed_repl(repl)        # default threshold: 10 seconds
    # enable_timed_repl(repl, 0.5) # custom threshold in seconds
end
```
