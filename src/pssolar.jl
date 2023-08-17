"""
	solar(cmd0::String="", arg1=nothing; kwargs...)

Calculate and plot the day-night terminator and the civil, nautical and astronomical twilights.

See full GMT (not the `GMT.jl` one) docs at [`solar`]($(GMTdoc)solar.html)

Parameters
----------

- $(GMT._opt_J)
- $(GMT._opt_B)
- **C** | **format** :: [Type => Bool]

- **G** | **fill** :: [Type => Str | Number]

- **I** | **sun** :: [Type => Bool | Tuple | NamedTuple]

- $(GMT.opt_P)
- **M** | **dump** :: [Type => Bool]

- $(GMT._opt_R)
- **N** | **invert** :: [Type => Bool]

- **T** | **terminators** :: [Type => Bool | Tuple | NamedTuple]

- **W** | **pen** :: [Type => Str | Tuple]

- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bo)
- $(GMT._opt_h)
- $(GMT.opt_o)
- $(GMT._opt_p)
- $(GMT._opt_t)
- $(GMT.opt_savefig)

To see the full documentation type: ``@? solar``
"""
function solar(cmd0::String="", arg1=nothing; first=true, kwargs...)

	gmt_proggy = (IamModern[1]) ? "solar " : "pssolar "
	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	def_J = (isempty(d)) ? " -JG0/0/14c" : " -JX14cd/0d"
	(isempty(d)) && (d[:coast] = true; d[:T] = :d; d[:G] = "navy@75"; d[:show] = true)
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, def_J)
	cmd, = parse_common_opts(d, cmd, [:bo :c :h :o :p :t :UVXY :params], first)
	cmd  = parse_these_opts(cmd, d, [[:C :format], [:M :dump], [:N :invert]])

	cmd  = add_opt_fill(cmd, d, [:G :fill], 'G')
	cmd  = add_opt(d, cmd, "I", [:I :sun], (pos="",date="+d",TZ="+z"))
	cmd  = add_opt(d, cmd, "T", [:T :terminators], (term="",date="+d",TZ="+z"))
	cmd *= opt_pen(d, 'W', [:W :pen])

	opt_extra = "";		do_finish = true
	if (occursin("-I", cmd) || occursin("-I", cmd0))
		opt_extra = "-I";		do_finish = false;	cmd = replace(cmd, opt_J => "")
	end
	_cmd = (opt_extra != "-I" && (!occursin("-M", cmd) && !occursin("-M", cmd0)) && (!occursin("-T", cmd) && !occursin("-T", cmd0))) ?
	finish_PS_nested(d, [gmt_proggy * cmd]) : [gmt_proggy * cmd]
	(length(_cmd) > 1 && startswith(_cmd[2], (IamModern[1]) ? "coast" : "pscoast") && !contains(_cmd[1], " -R") &&
		contains(_cmd[2], " -R ")) && (_cmd[2] = replace(_cmd[2], "-R" => "-Rd"))		# Apparently solar defaults to -Rd but only internally in C
	return finish_PS_module(d, _cmd, opt_extra, K, O, do_finish, arg1)
end

# ---------------------------------------------------------------------------------------------------
solar!(cmd0::String="", arg1=nothing; kw...) = solar(cmd0, arg1; first=false, kw...)

const pssolar  = solar				# Alias
const pssolar! = solar!				# Alias