"""
	solar(cmd0::String="", arg1=[]; kwargs...)

Calculate and plot the day-night terminator and the civil, nautical and astronomical twilights.


Parameters
----------

- $(GMT.opt_J)
- $(GMT.opt_B)
- **C** : **format** : -- ::Bool --

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
function solar(cmd0::String="", arg1=[]; K=false, O=false, first=true, kwargs...)

	arg2 = []		# May be needed if GMTcpt type is sent in via C
	N_args = isempty_(arg1) ? 0 : 1

	length(kwargs) == 0 && N_args == 0 && isempty(data) && return monolitic("pssolar", cmd0, arg1)	# Speedy mode

    d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12cd/0d")
	cmd = parse_common_opts(d, cmd, [:bo :h :o :p :t :UVXY :params])

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	cmd = add_opt(cmd, 'C', d, [:C :format])
    cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
    cmd = add_opt(cmd, 'I', d, [:I :sun], (pos="",date="+d",TZ="+z"))
	cmd = add_opt(cmd, 'M', d, [:M :dump])
	cmd = add_opt(cmd, 'N', d, [:N :invert])
	cmd = add_opt(cmd, 'T', d, [:T :terminators], (term="",date="+d",TZ="+z"))
	cmd = cmd * opt_pen(d, 'W', [:W :pen])

    opt_extra = ""
    if (occursin( "-I", cmd) || occursin("-I", cmd0))
        output = "";    opt_extra = "-I"
    end
	cmd = finish_PS(d, cmd, output, K, O)
    return finish_PS_module(d, cmd, opt_extra, output, fname_ext, opt_T, K, "pssolar", arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
solar!(cmd0::String="", arg1=[]; K=true, O=true,  first=false, kw...) =
	solar(cmd0, arg1; K=K, O=O,  first=first, kw...)

pssolar  = solar				# Alias
pssolar! = solar!				# Alias