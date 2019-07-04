"""
	solar(cmd0::String="", arg1=nothing; kwargs...)

Calculate and plot the day-night terminator and the civil, nautical and astronomical twilights.


Parameters
----------

- $(GMT.opt_J)
- $(GMT.opt_B)
- **C** : **formated** : -- ::Bool --

    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/pssolar.html#c)
- **G** : **fill** : -- Number or Str --

    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/pssolar.html#g)
- **I** : **sun** : -- ::Bool or ::Tuple or ::NamedTuple --

    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/pssolar.html#i)
- $(GMT.opt_P)
- **M** : **dump** : -- ::Bool --

    [`-M`](http://gmt.soest.hawaii.edu/doc/latest/pssolar.html#M)
- $(GMT.opt_R)
- **N** : **invert** : -- ::Bool --

    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/pssolar.html#n)
- **T** : **terminators** : -- ::Bool or ::Tuple or ::NamedTuple --

    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/pssolar.html#t)
- **W** : **pen** : -- Str or tuple --

    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/pssolar.html#w)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bo)
- $(GMT.opt_h)
- $(GMT.opt_o)
- $(GMT.opt_p)
- $(GMT.opt_t)

[`Full man page`](https://genericmappingtools.github.io/GMT.jl/latest/solar/)
[`GMT man page`](http://gmt.soest.hawaii.edu/doc/latest/solar.html)
"""
function solar(cmd0::String="", arg1=nothing; first=true, kwargs...)

	arg2 = nothing		# May be needed if GMTcpt type is sent in via C
	N_args = (arg1 === nothing) ? 0 : 1

	length(kwargs) == 0 && N_args == 0 && return monolitic("pssolar", cmd0, arg1)

	d = KW(kwargs)
	output, opt_T, fname_ext, K, O = fname_out(d, first)		# OUTPUT may have been an extension only

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12cd/0d")
	cmd = parse_common_opts(d, cmd, [:bo :c :h :o :p :t :UVXY :params], first)
	cmd = parse_these_opts(cmd, d, [[:C :formated], [:M :dump], [:N :invert]])

	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	cmd = add_opt(cmd, 'I', d, [:I :sun], (pos="",date="+d",TZ="+z"))
	cmd = add_opt(cmd, 'T', d, [:T :terminators], (term="",date="+d",TZ="+z"))
	cmd *= opt_pen(d, 'W', [:W :pen])

	opt_extra = ""
	if (occursin( "-I", cmd) || occursin("-I", cmd0))
		output = "";    opt_extra = "-I"
		cmd = replace(cmd, opt_J => "")
	end
	cmd, K = finish_PS_nested(d, "pssolar " * cmd, output, K, O, [:coast])
	return finish_PS_module(d, cmd, opt_extra, output, fname_ext, opt_T, K, O, false, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
solar!(cmd0::String="", arg1=nothing; kw...) = solar(cmd0, arg1; first=false, kw...)

const pssolar  = solar				# Alias
const pssolar! = solar!				# Alias