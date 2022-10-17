"""
	grdfft(cmd0::String="", arg1=nothing, [arg2=nothing,] kwargs...)

Take the 2-D forward Fast Fourier Transform and perform one or more mathematical operations
in the frequency domain before transforming back to the space domain.

Full option list at [`grdfft`]($(GMTdoc)grdfft.html)

Parameters
----------

- **A** | **azim** :: [Type => Number]    ``Arg = azim``

    Take the directional derivative in the azimuth direction measured in degrees CW from north.
    ($(GMTdoc)grdfft.html#a)
- **C** | **upward** :: [Type => Number]    ``Arg = zlevel``

    Upward (for zlevel > 0) or downward (for zlevel < 0) continue the field zlevel meters.
    ($(GMTdoc)grdfft.html#c)
- **D** | **dfdz** :: [Type => Str or Number]		``Arg = [scale|g]``

    Differentiate the field, i.e., take d(field)/dz. This is equivalent to multiplying by kr in
    the frequency domain (kr is radial wave number).
    ($(GMTdoc)grdfft.html#d)
- **E** | **radial_power** :: [Type => Str]         ``Arg = [r|x|y][+w[k]][+n]``

    Estimate power spectrum in the radial direction [r]. Place x or y immediately after E to
    compute the spectrum in the x or y direction instead.
    ($(GMTdoc)grdfft.html#e)
- **F** | **filter** :: [Type => Str or List--        ``Arg = [r|x|y]params``

    Filter the data. Place x or y immediately after -F to filter x or y direction only; default is
    isotropic [r]. Choose between a cosine-tapered band-pass, a Gaussian band-pass filter, or a
    Butterworth band-pass filter.
    ($(GMTdoc)grdfft.html#f)
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name (or table if **radial_power** is used). Note that this is optional and to
    be used only when saving the result directly on disk. Otherwise, just use the G = grdfft(....) form.
    ($(GMTdoc)grdfft.html#g)
- **I** | **integrate** :: [Type => Str or Number]		``Arg = [scale|g]``

    Integrate the field, i.e., compute integral_over_z (field * dz). This is equivalent to divide
    by kr in the frequency domain (kr is radial wave number).
    ($(GMTdoc)grdfft.html#i)
- **N** | **inquire** :: [Type => Str]         ``Arg = [a|f|m|r|s|nx/ny][+a|[+d|h|l][+e|n|m][+twidth][+v][+w[suffix]][+z[p]]``

    Choose or inquire about suitable grid dimensions for FFT and set optional parameters. Control the FFT dimension:
    ($(GMTdoc)grdfft.html#n)
- **S** | **scale** :: [Type => Number]			``Arg = scale``

    Multiply each element by scale in the space domain (after the frequency domain operations).
    ($(GMTdoc)grdfft.html#s)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
function grdfft(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

    (GMTver < v"6.4.0") && (@warn("Sorry but you need at least GMT 6.4 to use this module. Previous version had a bug that prevented Julia wrapper to work."); return nothing)
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_common_opts(d, "", [:G :V_params :f])
	cmd  = parse_these_opts(cmd, d, [[:A :azim], [:C :upward], [:D :dfdz], [:E :radial_power], [:F :filter],
	                                 [:I :integrate], [:N :inquire], [:S :scale]])

	cmd, _, arg1, arg2 = find_data(d, cmd0, cmd, arg1, arg2)
	(isa(arg1, Matrix{<:Real})) && (arg1 = mat2grid(arg1))
	if (!occursin(" -E", cmd))          # Simpler case
		return common_grd(d, "grdfft " * cmd, arg1)		# Finish build cmd and run it
	else
		# Here several cases can happen: 1) arg1 only; 2) arg1 && arg2; 3) grid(s) provided via fname
		(isa(arg2, Array{<:Number})) && (arg2 = mat2grid(arg2))
		return common_grd(d, "grdfft " * cmd, arg1, arg2)
	end
end

# ---------------------------------------------------------------------------------------------------
grdfft(arg1, arg2=nothing; kw...) = grdfft("", arg1, arg2; kw...)