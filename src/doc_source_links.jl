# Documentation utility function for generating source code links.
# Written by claude.ai

"""
	doc_source_links(function_name::String; github_base="https://github.com/GenericMappingTools/GMT.jl/blob/master")

Generate markdown links to source code for GMT.jl documentation.

This function is designed for use in Quarto documentation with the `#| output: asis` directive.
It automatically finds all methods of a function and creates clickable links to their source
code on GitHub, with the exact file and line number.

### Arguments
- `function_name`: Name of the GMT.jl function (as a string)
- `github_base`: Base URL for GitHub repository (default: GMT.jl master branch)

### Returns
Nothing. Prints markdown-formatted source code links to stdout.

### Example
In a Quarto .qmd file:
```julia
#| echo: false
#| output: asis
GMT.doc_source_links("grdimage")
```

This will generate a "Source Code" section with links to all methods of `grdimage`.

### Notes
- Uses `methods()` to get current source locations, so links are always up-to-date
- Silently fails if the function is not found (useful for functions defined elsewhere)
- Line numbers are extracted from Julia's method introspection
- Links are regenerated at documentation build time, ensuring accuracy
"""
function doc_source_links(function_name::String; silent=false,
                          github_base::String="https://github.com/GenericMappingTools/GMT.jl/blob/master")
	try
		func = getfield(GMT, Symbol(function_name))
		method_list = methods(func)

		!silent && println("\n## Source Code\n")

		methods_info = Tuple{String,String,String}[]
		for m in method_list
			method_str = string(m)
			if occursin(" @ ", method_str)
				parts = split(method_str, " @ ")
				if length(parts) >= 2 && length(parts[2]) > 0
					signature = strip(parts[1])
					loc_parts = split(strip(parts[2]), " ", limit=2)

					if length(loc_parts) >= 2 && occursin(":", loc_parts[2])
						file_parts = rsplit(loc_parts[2], ":", limit=2)
						filepath = file_parts[1]

						# Extract relative path from GMT package source
						m_src = match(r"[/\\](src[/\\].+)$", filepath)
						if m_src !== nothing
							rel_path = replace(String(m_src.captures[1]), "\\" => "/")
							push!(methods_info, (signature, rel_path, file_parts[2]))
						end
					end
				end
			end
		end

		if length(methods_info) == 1
			sig, path, line = methods_info[1]
			!silent && println("View the [source code]($github_base/$path#L$line) for this function.\n")
		elseif length(methods_info) > 1
			!silent && println("This function has multiple methods:\n")
			for (sig, path, line) in methods_info
				!silent && println("- [`$sig`]($github_base/$path#L$line) - $(basename(path)):$line")
			end
			!silent && println()
		end
	catch
		# Silently fail if function not found or other error
		!silent && println("\n")
	end
	nothing
end
