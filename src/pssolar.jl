"""
	solar(cmd0::String="", arg1=nothing; kwargs...)

Calculate and plot the day-night terminator and the civil, nautical and astronomical twilights.

Full option list at [`solar`]($(GMTdoc)solar.html)

Parameters
----------

- $(GMT.opt_J)
- $(GMT.opt_B)
- **C** | **formated** :: [Type => Bool]

    ($(GMTdoc)solar.html#c)
- **G** | **fill** :: [Type => Str | Number]

    ($(GMTdoc)solar.html#g)
- **I** | **sun** :: [Type => Bool | Tuple | NamedTuple]

    ($(GMTdoc)solar.html#i)
- $(GMT.opt_P)
- **M** | **dump** :: [Type => Bool]

    ($(GMTdoc)solar.html#m)
- $(GMT.opt_R)
- **N** | **invert** :: [Type => Bool]

    ($(GMTdoc)solar.html#n)
- **T** | **terminators** :: [Type => Bool | Tuple | NamedTuple]

    ($(GMTdoc)solar.html#t)
- **W** | **pen** :: [Type => Str | Tuple]

    ($(GMTdoc)solar.html#w)
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
function solar(cmd0::String="", arg1=nothing; first=true, kwargs...)

	arg2 = nothing		# May be needed if GMTcpt type is sent in via C
	N_args = (arg1 === nothing) ? 0 : 1

	gmt_proggy = (IamModern[1]) ? "solar "  : "pssolar "
	length(kwargs) == 0 && N_args == 0 && return monolitic(gmt_proggy, cmd0, arg1)

	d = KW(kwargs)
	help_show_options(d)		# Check if user wants ONLY the HELP mode
	K, O = set_KO(first)		# Set the K O dance

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12cd/0d")
	cmd, = parse_common_opts(d, cmd, [:bo :c :h :o :p :t :UVXY :params], first)
	cmd  = parse_these_opts(cmd, d, [[:C :formated], [:M :dump], [:N :invert]])

	cmd  = add_opt_fill(cmd, d, [:G :fill], 'G')
	cmd  = add_opt(cmd, 'I', d, [:I :sun], (pos="",date="+d",TZ="+z"))
	cmd  = add_opt(cmd, 'T', d, [:T :terminators], (term="",date="+d",TZ="+z"))
	cmd *= opt_pen(d, 'W', [:W :pen])

	opt_extra = "";		do_finish = true
	if (occursin("-I", cmd) || occursin("-I", cmd0))
		opt_extra = "-I";		do_finish = false;	cmd = replace(cmd, opt_J => "")
	end
	cmd, K = finish_PS_nested(d, gmt_proggy * cmd, K, O, [:coast :logo :text])
	return finish_PS_module(d, cmd, opt_extra, K, O, do_finish, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
solar!(cmd0::String="", arg1=nothing; kw...) = solar(cmd0, arg1; first=false, kw...)

const pssolar  = solar				# Alias
const pssolar! = solar!				# Alias