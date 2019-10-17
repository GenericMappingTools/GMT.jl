"""
	grdfft(cmd0::String="", arg1=nothing, [arg2=nothing,] kwargs...)

Take the 2-D forward Fast Fourier Transform and perform one or more mathematical operations
in the frequency domain before transforming back to the space domain.

Full option list at [`grdfft`]($(GMTdoc)grdfft.html)

Parameters
----------

- **A** | **azim** :: [Type => Number]    Flags = azim

    Take the directional derivative in the azimuth direction measured in degrees CW from north.
    ($(GMTdoc)grdfft.html#a)
- **C** | **upward** :: [Type => Number]    Flags = zlevel

    Upward (for zlevel > 0) or downward (for zlevel < 0) continue the field zlevel meters.
    ($(GMTdoc)grdfft.html#c)
- **D** | **dfdz** :: [Type => Str or Number]		Flags = [scale|g]

    Differentiate the field, i.e., take d(field)/dz. This is equivalent to multiplying by kr in
    the frequency domain (kr is radial wave number).
    ($(GMTdoc)grdfft.html#d)
- **E** | **radial_power** :: [Type => Str]         Flags = [r|x|y][+w[k]][+n]

    Estimate power spectrum in the radial direction [r]. Place x or y immediately after E to
    compute the spectrum in the x or y direction instead.
    ($(GMTdoc)grdfft.html#e)
- **F** | **filter** :: [Type => Str or List--        Flags = [r|x|y]params

    Filter the data. Place x or y immediately after -F to filter x or y direction only; default is
    isotropic [r]. Choose between a cosine-tapered band-pass, a Gaussian band-pass filter, or a
    Butterworth band-pass filter.
    ($(GMTdoc)grdfft.html#f)
- **G** | **outgrid** | **table** :: [Type => Str]

    Output grid file name (or table if **radial_power** is used). Note that this is optional and to
    be used only when saving the result directly on disk. Otherwise, just use the G = grdfft(....) form.
    ($(GMTdoc)grdfft.html#g)
- **I** | **integrate** :: [Type => Str or Number]		Flags = [scale|g]

    Integrate the field, i.e., compute integral_over_z (field * dz). This is equivalent to divide
    by kr in the frequency domain (kr is radial wave number).
    ($(GMTdoc)grdfft.html#i)
- **N** | **inquire** :: [Type => Str]         Flags = [a|f|m|r|s|nx/ny][+a|[+d|h|l][+e|n|m][+twidth][+v][+w[suffix]][+z[p]]

    Choose or inquire about suitable grid dimensions for FFT and set optional parameters. Control the FFT dimension:
    ($(GMTdoc)grdfft.html#n)
- **S** | **scale** :: [Type => Number]			Flags = scale

    Multiply each element by scale in the space domain (after the frequency domain operations).
    ($(GMTdoc)grdfft.html#s)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
function grdfft(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("grdfft", cmd0, arg1, arg2)

	d = KW(kwargs)

	cmd = parse_common_opts(d, "", [:V_params :f])
	cmd = parse_these_opts(cmd, d, [[:A :azim], [:C :upward], [:D :dfdz], [:E :radial_power], [:F :filter],
	                                [:G :outgrid :table], [:I :integrate], [:N :inquire], [:S :scale]])

	cmd, got_fname, arg1, arg2 = find_data(d, cmd0, cmd, arg1, arg2)
	if (isa(arg1, Array{<:Number}))		arg1 = mat2grid(arg1)	end
	if (!occursin(" -E", cmd))          # Simpler case
		return common_grd(d, "grdfft " * cmd, arg1)		# Finish build cmd and run it
	else
		# Here several cases can happen: 1) arg1 only; 2) arg1 && arg2; 3) grid(s) provided via fname
		if (isa(arg2, Array{<:Number}))  arg2 = mat2grid(arg2)  end
		return common_grd(d, "grdfft " * cmd, arg1, arg2)
	end
end

# ---------------------------------------------------------------------------------------------------
grdfft(arg1, arg2=nothing, cmd0::String=""; kw...) = grdfft(cmd0, arg1, arg2; kw...)