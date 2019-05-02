"""
	grdfft(cmd0::String="", arg1=nothing, [arg2=nothing,] kwargs...)

Take the 2-D forward Fast Fourier Transform and perform one or more mathematical operations
in the frequency domain before transforming back to the space domain.

Full option list at [`grdfft`](http://gmt.soest.hawaii.edu/doc/latest/grdfft.html)

Parameters
----------

- **A** : **azim** : -- Number --    Flags = azim

    Take the directional derivative in the azimuth direction measured in degrees CW from north.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/grdfft.html#a)
- **C** : **upward** : -- Number --    Flags = zlevel

    Upward (for zlevel > 0) or downward (for zlevel < 0) continue the field zlevel meters.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/grdfft.html#c)
- **D** : **dfdz** : -- Str or Number --		Flags = [scale|g]

    Differentiate the field, i.e., take d(field)/dz. This is equivalent to multiplying by kr in
    the frequency domain (kr is radial wave number).
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdfft.html#d)
- **E** : **radial_power** : -- Str --         Flags = [r|x|y][+w[k]][+n]

    Estimate power spectrum in the radial direction [r]. Place x or y immediately after E to
    compute the spectrum in the x or y direction instead.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/grdfft.html#e)
- **F** : **filter** : -- Str or List--        Flags = [r|x|y]params

    Filter the data. Place x or y immediately after -F to filter x or y direction only; default is
    isotropic [r]. Choose between a cosine-tapered band-pass, a Gaussian band-pass filter, or a
    Butterworth band-pass filter.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/grdfft.html#f)
- **G** : **outgrid** : **table**-- Str --

    Output grid file name (or table if **radial_power** is used). Note that this is optional and to
    be used only when saving the result directly on disk. Otherwise, just use the G = grdfft(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdfft.html#g)
- **I** : **integrate** : -- Str or Number --		Flags = [scale|g]

    Integrate the field, i.e., compute integral_over_z (field * dz). This is equivalent to divide
    by kr in the frequency domain (kr is radial wave number).
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grdfft.html#i)
- **N** : **inquire** : -- Str --         Flags = [a|f|m|r|s|nx/ny][+a|[+d|h|l][+e|n|m][+twidth][+v][+w[suffix]][+z[p]]

    Choose or inquire about suitable grid dimensions for FFT and set optional parameters. Control the FFT dimension:
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdfft.html#n)
- **S** : **scale** : -- Number --			Flags = scale

    Multiply each element by scale in the space domain (after the frequency domain operations).
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/grdfft.html#s)
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