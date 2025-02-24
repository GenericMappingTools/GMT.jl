"""
    gmtspectrum1d(cmd0::String="", arg1=nothing, kwargs...)

Compute auto- [and cross- ] spectra from one [or two] time-series.

See full GMT (not the `GMT.jl` one) docs at [`spectrum1d`]($(GMTdoc)spectrum1d.html)

Parameters
----------

- **S** | **size** :: [Type => Str]        ``Arg = segment_size``

    ``segment_size`` is a radix-2 number of samples per window for ensemble averaging.
- **C** | **output** :: [Type => Str | []]        ``Arg = [xycnpago]``

    Read the first two columns of input as samples of two time-series, X(t) and Y(t).
    Consider Y(t) to be the output and X(t) the input in a linear system with noise.
- **D** | **sample_dist** :: [Type => Number]   ``Arg = dt``

    Set the spacing between samples in the time-series [Default = 1].
- **L** | **leave_trend** :: [Type => Str | []]     ``Arg = [h|m]``

Leave trend alone. By default, a linear trend will be removed prior to the transform.
- **N** | **name** :: [Type => Int]      ``Arg = t_col``

    Indicates which
- **T** :: [Type => Bool]

    Disable the writing of a single composite results file to stdout.
- **W** | **wavelength** :: [Type => Bool | Str]

    Write Wavelength rather than frequency in column 1 of the output file[s] [Default = frequency, (cycles / dt)].
- $(opt_V)
- $(opt_write)
- $(opt_append)
- $(opt_b)
- $(opt_d)
- $(opt_e)
- $(_opt_f)
- $(opt_g)
- $(_opt_h)
- $(_opt_i)
- $(opt_swap_xy)

To see the full documentation type: ``@? spectrum1d``
"""
spectrum1d(cmd0::String; kw...) = spectrum1d_helper(cmd0, nothing; kw...)
spectrum1d(arg1; kw...)         = spectrum1d_helper("", arg1; kw...)

# ---------------------------------------------------------------------------------------------------
function spectrum1d_helper(cmd0::String, arg1; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd = parse_common_opts(d, "", [:V_params :b :d :e :g :h :i :yx])[1]
	cmd = parse_these_opts(cmd, d, [[:D :sample_dist], [:L :leave_trend], [:N :name], [:S :size], [:T :multifiles], [:W :wavelength]])
	opt_C = add_opt(d, "", "C", [:C :components :output],
					(xpower="_x", ypower="_y", cpower="_c", npower="_n", phase="_p", admitt="_a", gain="_g", coh="_o"))
	if (!contains(cmd, " -T"))                  # Return vars, otherwise it saves them in disk files
		flags = (opt_C == "") ? "x" : opt_C[4:end]
		cnames = Vector{String}(undef, 2*length(flags) + 1)
		cnames[1] = contains(cmd, " -W") ? "Wavelength" : "Frequency"
		for k = 1:numel(flags)
			if     (flags[k] == 'x') cnames[2*k] = "Xpower"; cnames[2*k+1] = "σ_Xpow"
			elseif (flags[k] == 'y') cnames[2*k] = "Ypower"; cnames[2*k+1] = "σ_Ypow"
			elseif (flags[k] == 'c') cnames[2*k] = "Cpower"; cnames[2*k+1] = "σ_Cpow"
			elseif (flags[k] == 'n') cnames[2*k] = "Npower"; cnames[2*k+1] = "σ_Npow"
			elseif (flags[k] == 'p') cnames[2*k] = "Phase";  cnames[2*k+1] = "σ_Phase"
			elseif (flags[k] == 'a') cnames[2*k] = "Admit";  cnames[2*k+1] = "σ_Admit"
			elseif (flags[k] == 'g') cnames[2*k] = "Gain";   cnames[2*k+1] = "σ_Gain"
			elseif (flags[k] == 'o') cnames[2*k] = "Coher";  cnames[2*k+1] = "σ_Coher"
			end
		end
	end
	(opt_C != "") && (cmd *= opt_C)

	D = common_grd(d, cmd0, cmd, "spectrum1d ", arg1)		# Finish build cmd and run it
	isa(D, GMTdataset) && (D.colnames = cnames)
	return D
end
