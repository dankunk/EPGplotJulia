# EPG Signal Plotting in Julia 🚀

*A personal sandbox for playing around with EPG signal plotting in Julia. (Not a working build)*

---

## Overview

This repository contains experimental Julia scripts and functions for loading and plotting Electropenetrography (EPG) signals. 

### Key Points ✨

- **Load `.D##` Files**: Functions to automatically read `.D01`, `.D02`, etc., files from a directory and create a combined signal.
- **Time Vector Creation**: Generates a corresponding time vector for each segment (assuming 100 Hz sampling).
- **Plotting**: Uses [Plots.jl](https://github.com/JuliaPlots/Plots.jl) to visualize signal chunks.

### Disclaimers ⚠️

- **Sandbox**: This is an experimental playground and **not** a production-ready solution. 
- **Not a Working Build**: While the scripts may run and produce plots, they are subject to frequent changes and breakages.

---

## Getting Started 🏁

1. **Clone or Download** this repository.
2. **Install Julia** (tested on version 1.x).
3. **Install Dependencies**:
   ```julia
   using Pkg
   Pkg.add("DataFrames")
   Pkg.add("Plots")
4. **Run Some Code**
   ```julia
   include("load_and_plot_d0x_files.jl")
   df = load_d0x_files("path/to/yourfile.D01"; sampling_rate=100.0)
   plt = plot_signal(df, plot_type=:line, title="EPG Signal")
   display(plt)
   
## License 📄
This project is a personal sandbox; no official license is applied.
If you wish to reuse or modify the code, feel free to do so at your own risk.
