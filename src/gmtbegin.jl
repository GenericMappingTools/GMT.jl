"""
    gmtbegin(name::String=""; fmt)

Start a GMT session in modern mode (GMT >= 6).
'name' contains the figure name with or without extension. If an extension is used 
(e.g. "map.pdf") it is used to select the image format.

As an alternative use 'fmt' as a string or symbol containing the format (ps, pdf, png, PNG, tif, jpg, eps).

By default name="GMTplot" and fmt="ps"
"""
function gmtbegin(name::String=""; fmt=nothing, verbose=nothing)
	global IamModern = true
 
    cmd = "begin"       # Default name (GMTplot.ps) is set in gmt_main()
    if (name != "")  cmd *= " " * get_format(name, fmt)  end
    if (verbose !== nothing)  cmd *= " -V" * string(verbose)  end
    gmt(cmd)
    return nothing
end

"""
    gmtend(show=false, verbose=nothing)

Ends a GMT session in modern mode (GMT >= 6) and optionaly shows the figure
"""
function gmtend(; show::Bool=false, verbose=nothing)
    global IamModern = false
    cmd = "end"
    if (show)  cmd *= " show"  end
    if (verbose !== nothing)  cmd *= " -V" * string(verbose)  end
    gmt(cmd)
    return nothing
end
 
function get_format(name, fmt=nothing, d=nothing)
    # Get the fig name and format. If format not specified, default to FMT (ps)
    # NAME is supposed to always exist (otherwise, errors)
    fname, ext = splitext(string(name))
    if (ext != "")
        fname *= " " * ext[2:end]
    elseif (fmt !== nothing)
        fname *= " " * string(fmt)      # No checking
    elseif (d !== nothing)
        if (haskey(d, :fmt))  fname *= " " * string(d[:fmt])
        else                  fname *= " " * FMT		# Then use default format
        end
    else
        fname *= " " * FMT
    end
    return fname
end