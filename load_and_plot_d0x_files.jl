using DataFrames
using Plots  # Make sure you have run `Pkg.add("Plots")`.

"""
    load_d0x_files(file_path::AbstractString; sampling_rate=100.0) -> DataFrame

Loads all .D## files in the same directory as `file_path`.

1. Reads & discards 3 header lines.
2. Interprets remaining bytes as Float32 data.
3. Builds a time vector for each file (100 Hz by default).
4. Concatenates all signals and times into one DataFrame with columns `:time` and `:signal`.
"""
function load_d0x_files(file_path::AbstractString; sampling_rate::Float64=100.0)
    # -- 1. Confirm file exists
    if !isfile(file_path)
        error("File not found: $file_path")
    end

    # -- 2. Identify directory and base name
    dir_path = dirname(file_path)
    file_name = basename(file_path)

    # Example: "8hr_0zt_2022-10-01-ch4.D01" => base_name = "8hr_0zt_2022-10-01-ch4"
    base_name = replace(file_name, r"\.D\d+$" => "")

    # -- 3. Find all .D## files matching that base name
    files_all = readdir(dir_path, join=true)
    files_matched = filter(f ->
        startswith(basename(f), base_name) &&
        occursin(r"\.D\d+$", basename(f)),
        files_all
    )
    sort!(files_matched)
    if isempty(files_matched)
        error("No matching .D## files found in directory `$dir_path` for base name `$base_name`.")
    end

    # -- 4. Read each file and accumulate signal/time
    signal_list = Vector{Vector{Float32}}()
    time_list   = Vector{Vector{Float64}}()
    total_samples = 0

    for (i, f) in pairs(files_matched)
        println("Processing file $i: $f")

        data = open(f, "r") do io
            # Skip 3 header lines
            readline(io)
            readline(io)
            readline(io)
            # Read remaining as raw bytes & reinterpret as Float32
            raw_data = read(io)
            reinterpret(Float32, raw_data)
        end

        n_samples = length(data)
        println("  - read $n_samples samples")

        # Build time vector exactly n_samples long
        start_time = total_samples / sampling_rate
        t = range(start_time, step=1/sampling_rate, length=n_samples)

        push!(signal_list, data)
        push!(time_list, collect(t))

        total_samples += n_samples
    end

    # -- 5. Concatenate
    signal = vcat(signal_list...)
    time   = vcat(time_list...)

    # Double-check lengths
    @assert length(signal) == length(time) "signal/time length mismatch!"

    # -- 6. Create DataFrame with Symbol column names
    df = DataFrame(:time => time, :signal => signal)

    # Debugging print—uncomment if you want to confirm column names & types:
    # println("Created DataFrame with columns: ", names(df))
    # println("First 5 rows:\n", first(df, 5))

    return df
end

"""
    plot_signal(df::DataFrame; plot_type=:line, title="EPG Signal")

Plots the signal from a DataFrame with columns `:time` and `:signal`.

Arguments:
- `df`: DataFrame with `:time`, `:signal`
- `plot_type`: `:line` (default) or `:scatter`
- `title`: String for the plot title

Returns the plot object so you can display or further modify it.
"""
function plot_signal(df::DataFrame; plot_type=:line, title="EPG Signal")
    # Convert DataFrame column names to symbols for a robust check
    colnames_sym = Symbol.(names(df))
    required_cols = (:time, :signal)

    # Check presence of :time and :signal
    if !all(c -> c in colnames_sym, required_cols)
        error("DataFrame must have columns :time and :signal")
    end

    if plot_type == :line
        plt = plot(
            df[:,:time], df[:,:signal],  # Use column symbols
            xlabel="Time (s)",
            ylabel="Signal",
            title=title,
            legend=false
        )
    elseif plot_type == :scatter
        plt = scatter(
            df[:,:time], df[:,:signal],
            xlabel="Time (s)",
            ylabel="Signal",
            title=title,
            legend=false
        )
    else
        error("Unsupported plot_type: $plot_type. Choose :line or :scatter.")
    end

    return plt
end

"""
    plot_signal_chunk(df::DataFrame; start_s=0.0, duration=10.0, plot_type=:line)

Plots just a chunk of the data (e.g., 10 seconds).
Useful for zooming in on a specific region.

Arguments:
- `start_s`: start time in seconds (default 0.0)
- `duration`: length of the window in seconds (default 10.0)
- `plot_type`: `:line` or `:scatter`
"""
function plot_signal_chunk(df::DataFrame; start_s=0.0, duration=10.0, plot_type=:line)
    # Convert column names to symbols for check
    colnames_sym = Symbol.(names(df))
    required_cols = (:time, :signal)
    if !all(c -> c in colnames_sym, required_cols)
        error("DataFrame must have columns :time and :signal")
    end

    # Filter rows where time is in [start_s, start_s + duration)
    subset = df[(df[:,:time] .>= start_s) .& (df[:,:time] .< start_s + duration), :]
    return plot_signal(subset; plot_type=plot_type,
                       title="EPG Signal ($(start_s)s - $(start_s+duration)s)")
end

# -------------------------------------------------------------------------
# EXAMPLE USAGE (Manually call in REPL or remove comments below):
# -------------------------------------------------------------------------
# file_path = "C:/Users/danie/Desktop/julia-EPG/8hr_0zt_2022-10-01-ch4.D01"
# df = load_d0x_files(file_path; sampling_rate=100.0)
# plt_full = plot_signal(df, plot_type=:line, title="Full EPG Signal")
# display(plt_full)
# plt_chunk = plot_signal_chunk(df; start_s=0.0, duration=60.0, plot_type=:scatter)
# display(plt_chunk)
