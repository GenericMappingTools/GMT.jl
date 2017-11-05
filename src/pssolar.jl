"""
	solar(cmd0::String="", arg1=[]; fmt="", kwargs...)

Calculate and plot the day-night terminator and the civil, nautical and astronomical twilights.

Full option list at [`pssolar`](http://gmt.soest.hawaii.edu/doc/latest/pssolar.html)

Parameters
----------

- $(GMT.opt_J)
- $(GMT.opt_B)
- **C** : **vectors** : -- Str --
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/pssolar.html#c)
- **G** : **fill** : -- Number or Str --
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/pssolar.html#g)
- **I** : **inquire** : -- Bool or [] --
	[`-I`](http://gmt.soest.hawaii.edu/doc/latest/pssolar.html#i)
- $(GMT.opt_P)
- **M** : **alpha** : -- Str or [] --
	[`-M`](http://gmt.soest.hawaii.edu/doc/latest/pssolar.html#M)
- $(GMT.opt_R)
- **N** : **radius** : -- Bool or [] --
	[`-N`](http://gmt.soest.hawaii.edu/doc/latest/pssolar.html#n)
- **T** : -- Bool or [] --
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
"""
# ---------------------------------------------------------------------------------------------------
function solar(cmd0::String="", arg1=[]; fmt::String="", K=false, O=false, first=true, kwargs...)

	arg2 = []		# May be needed if GMTcpt type is sent in via C
	N_args = isempty_(arg1) ? 0 : 1

	length(kwargs) == 0 && N_args == 0 && isempty(data) && return monolitic("pssolar", cmd0, arg1)	# Speedy mode
	output, opt_T, fname_ext = fname_out(fmt)		# OUTPUT may have been an extension only

    d = KW(kwargs)
    cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd0, "", "", O, " -JX12cd/0d")
	cmd = parse_UVXY(cmd, d)
	cmd = parse_bo(cmd, d)
	cmd = parse_h(cmd, d)
	cmd = parse_o(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	cmd = add_opt(cmd, 'C', d, [:C :])
    cmd = add_opt(cmd, 'G', d, [:G :fill])
    cmd = add_opt(cmd, 'I', d, [:I :sun])
	cmd = add_opt(cmd, 'M', d, [:M :dump])
	cmd = add_opt(cmd, 'N', d, [:M :invert])
	cmd = add_opt(cmd, 'T', d, [:T :terminators])
	cmd = cmd * opt_pen(d, 'W', [:W :pen])

    opt_extra = ""
    if (contains(cmd , "-I") || contains(cmd0, "-I"))
        output = "";    opt_extra = "-I"
    end
	cmd = finish_PS(d, cmd0, cmd, output, K, O)
    return finish_PS_module(d, cmd, opt_extra, arg1, arg2, [], [], [], [], output, fname_ext, opt_T, K, "pssolar")
end

# ---------------------------------------------------------------------------------------------------
solar!(cmd0::String="", arg1=[]; fmt::String="", K=true, O=true,  first=false, kw...) =
	solar(cmd0, arg1; fmt=fmt, K=K, O=O,  first=first, kw...)
