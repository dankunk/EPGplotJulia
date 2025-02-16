using DataFrames

"""
    load_d0x_files(file_path::AbstractString; sampling_rate=100.0) -> DataFrame

Loads all .D## files in the same directory as `file_path`.

1. Reads & discards 3 header lines.
2. Interprets remaining bytes as Float32 data.
3. Builds a time vector for each file (100 Hz by default).
4. Concatenates all signals and times into one DataFrame.
"""
function load_d0x_files(file_path::AbstractString; sampling_rate::Float64=100.0)
    # 1. Confirm file exists.
    if !isfile(file_path)
        error("File not found: $file_path")
    end

    # 2. Derive the directory and file name.
    dir_path = dirname(file_path)
    file_name = basename(file_path)

    # 3. Strip ".D##" to get base_name (e.g. "8hr_0zt_2022-10-01-ch4").
    base_name = replace(file_name, r"\.D\d+$" => "")

    # 4. Get *all* files in the directory, then filter those that start with base_name and end with .D##.
    files_all = readdir(dir_path, join=true)

    files_matched = filter(f ->
        startswith(basename(f), base_name) &&
        occursin(r"\.D\d+$", basename(f)),
        files_all
    )

    # Sort them (D01, D02, D03, etc.).
    sort!(files_matched)

    println("files_matched = ", files_matched)
    if isempty(files_matched)
        error("No matching .D## files found for base name '$base_name' in directory '$dir_path'")
    end

    signal_list = Vector{Vector{Float32}}()
    time_list   = Vector{Vector{Float64}}()
    total_samples = 0  # To track continuous time across files

    # 5. Loop through each matched file
    for (i, f) in pairs(files_matched)
        println("Processing file $i: $f")

        data = open(f, "r") do io
            # Skip 3 header lines
            readline(io)
            readline(io)
            readline(io)
            # Read the remainder as raw bytes & reinterpret as Float32
            raw_data = read(io)
            reinterpret(Float32, raw_data)
        end

        n_samples = length(data)
        println("  - read $n_samples samples")

        # Build a time vector *exactly* length = n_samples
        start_time = total_samples / sampling_rate
        t = range(start_time, step=1/sampling_rate, length=n_samples)
        
        # Append to lists
        push!(signal_list, data)
        push!(time_list, collect(t))

        total_samples += n_samples
    end

    # 6. Concatenate all signals and times
    signal = vcat(signal_list...)
    time   = vcat(time_list...)

    # Double-check that signal and time match lengths
    @assert length(signal) == length(time) "signal/time length mismatch!"

    # 7. Create a DataFrame
    df = DataFrame(time=time, signal=signal)
    return df
end

# Example usage:
file_path = "C:/Users/danie/Desktop/julia-EPG/8hr_0zt_2022-10-01-ch4.D01"
df = load_d0x_files(file_path)
println("DataFrame has $(nrow(df)) rows.")
println("First 10 rows:")
println(first(df, 10))
