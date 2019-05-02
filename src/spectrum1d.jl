"""
	gmtspectrum1d(cmd0::String="", arg1=nothing, kwargs...)

Compute auto- [and cross- ] spectra from one [or two] time-series.

Full option list at [`spectrum1d`](http://gmt.soest.hawaii.edu/doc/latest/spectrum1d.html)

Parameters
----------

- **S** : **size** : -- Str --        Flags = segment_size

    ``segment_size`` is a radix-2 number of samples per window for ensemble averaging.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/spectrum1d.html#s)
- **C** : **response_fun** : -- Str or [] --        Flags = [xycnpago]

    Read the first two columns of input as samples of two time-series, X(t) and Y(t).
    Consider Y(t) to be the output and X(t) the input in a linear system with noise.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/spectrum1d.html#c)
- **D** : **sample_dist** : -- Number --   Flags = dt

    Set the spacing between samples in the time-series [Default = 1].
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/spectrum1d.html#d)
- **L** : **leave_trend** : -- Str or [] --     Flags = [h|m]

    Leave trend alone. By default, a linear trend will be removed prior to the transform.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/spectrum1d.html#l)
- **N** : **time_col** : -- Int --      Flags = t_col

    Indicates which
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/spectrum1d.html#n)
- **T** :  -- Bool or [] --

    Disable the writing of a single composite results file to stdout.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/spectrum1d.html#t)
- **W** : **wavelength** : -- Bool or Str --

    Write Wavelength rather than frequency in column 1 of the output file[s] [Default = frequency, (cycles / dt)].
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/spectrum1d.html#w)
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_swap_xy)
"""
function spectrum1d(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("spectrum1d", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:V_params :b :d :e :g :h :i :yx])
	cmd = parse_these_opts(cmd, d, [[:C :response_fun], [:D :sample_dist], [:L :leave_trend], [:N :time_col],
				[:S :size], [:T], [:W :wavelength]])

	common_grd(d, cmd0, cmd, "spectrum1d ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
spectrum1d(arg1, cmd0::String=""; kw...) = spectrum1d(cmd0, arg1; kw...)