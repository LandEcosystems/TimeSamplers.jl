using Pkg
using Base: DEPOT_PATH
cd(@__DIR__)
Pkg.activate(".")
# Ensure OmniTools is available (for CI/CD where it's not registered)
try
    using OmniTools
catch
    @info "OmniTools not available, adding from git..."
    Pkg.develop(PackageSpec(url = "https://github.com/LandEcosystems/OmniTools.jl.git"))
    # Checkout the main branch after developing
    omni_tools_path = joinpath(DEPOT_PATH[1], "dev", "OmniTools")
    if isdir(omni_tools_path)
        cd(omni_tools_path) do
            run(`git checkout main`)
        end
    end
    using OmniTools
end
Pkg.resolve()
Pkg.instantiate()

using TimeSamplers
using InteractiveUtils

# Get the source directory
src_dir = joinpath(@__DIR__, "..", "src")

# Function to extract function code from a source file
# Returns all methods of the function
function extract_function_code(file_path::String, func_name::String)
    if !isfile(file_path)
        return nothing
    end
    
    code = read(file_path, String)
    lines = split(code, '\n')
    
    # Find all function definitions - look for "function func_name"
    # Escape special regex characters in function name
    escaped_name = escape_string(func_name, raw"\^$[]().*+?{}|")
    func_pattern = Regex("^\\s*function\\s+$escaped_name(\\s|\\(|\$)")
    
    function_starts = Int[]
    for (i, line) in enumerate(lines)
        if occursin(func_pattern, line)
            push!(function_starts, i)
        end
    end
    
    if isempty(function_starts)
        return nothing
    end
    
    # Extract all methods
    all_methods = String[]
    for function_start in function_starts
        # A one line declaration has no body to show
        occursin(Regex("^\\s*function\\s+$escaped_name\\s+end\\s*\$"), lines[function_start]) && continue
        # Extract function body until matching 'end' at same or less indentation
        function_lines = String[]
        start_line = lines[function_start]
        start_indent_match = match(r"^(\s*)", start_line)
        base_indent = start_indent_match === nothing ? 0 : length(start_indent_match.captures[1])
        
        for i in function_start:length(lines)
            line = lines[i]
            push!(function_lines, line)
            
            # Check for 'end' at the same or less indentation (but not the first line)
            if i > function_start
                end_match = match(r"^(\s*)end\s*$", line)
                if end_match !== nothing
                    end_indent = length(end_match.captures[1])
                    if end_indent <= base_indent
                        break
                    end
                end
            end
        end
        
        method_code = join(function_lines, '\n')
        # Skip empty function declarations (like "function create_TimeSampler end")
        # Check if it's just an empty declaration
        # Empty declaration can be: "function name end" on one line or two lines
        trimmed_code = strip(method_code)
        # Remove all whitespace for comparison
        no_ws = replace(trimmed_code, r"\s" => "")
        is_empty_single = no_ws == "function$(func_name)end"
        
        # Check for two-line empty declaration (function on one line, end on next)
        non_empty_lines = [strip(l) for l in function_lines if !isempty(strip(l))]
        is_empty_two = length(non_empty_lines) == 2 && 
                      occursin(Regex("^function\\s+$escaped_name\\s*\$"), non_empty_lines[1]) &&
                      non_empty_lines[2] == "end"
        
        is_empty = is_empty_single || is_empty_two
        
        # Only include if not empty and has actual implementation (more than just function/end)
        if !is_empty && length(non_empty_lines) > 2
            push!(all_methods, method_code)
        end
    end
    
    if isempty(all_methods)
        return nothing
    end
    
    # Remove duplicates while preserving order
    unique_methods = String[]
    seen = Set{String}()
    for method in all_methods
        if !(method in seen)
            push!(unique_methods, method)
            push!(seen, method)
        end
    end
    
    # Return all unique methods joined together
    return join(unique_methods, "\n\n")
end

# Find the source files that define a function
function find_function_files(func_name::String)
    escaped_name = escape_string(func_name, raw"\^$[]().*+?{}|")
    func_pattern = Regex("(?m)^\\s*function\\s+$escaped_name(\\s|\\(|\$)")
    source_files = sort(filter(f -> endswith(f, ".jl"), readdir(src_dir)))
    return [joinpath(src_dir, f) for f in source_files if occursin(func_pattern, read(joinpath(src_dir, f), String))]
end

# Generate API documentation
api_path = joinpath(@__DIR__, "src", "api.md")
open(api_path, "w") do io
    write(io, "```@meta\n")
    write(io, "CurrentModule = TimeSamplers\n")
    write(io, "```\n\n")
    write(io, "# API\n\n")
    write(io, "```@docs\nTimeSamplers\n```\n\n")
    
    # Get all exported functions
    exported_names = names(TimeSamplers, all=false)
    
    # Filter for functions
    func_names = Symbol[]
    for name in exported_names
        try
            val = getfield(TimeSamplers, name)
            if isa(val, Function)
                push!(func_names, name)
            end
        catch
            continue
        end
    end
    
    # Sort functions alphabetically
    sort!(func_names, by=string)
    
    # Generate @docs for each function with code section right after
    for func_name in func_names
        # Write @docs block for the function
        write(io, "```@docs\n")
        write(io, "$func_name\n")
        write(io, "```\n\n")
        
        # Add code section right after the docstring
        func_codes = [extract_function_code(f, string(func_name)) for f in find_function_files(string(func_name))]
        func_codes = filter(c -> c !== nothing && strip(c) != "", func_codes)
        if !isempty(func_codes)
            write(io, "::: details Code\n\n")
            write(io, "```julia\n")
            write(io, join(func_codes, "\n\n"))
            write(io, "\n```\n\n")
            write(io, ":::\n\n")
        end
    end
end

println("Generated API documentation at: $api_path")
