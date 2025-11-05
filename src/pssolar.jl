"""
	solar(cmd0::String="", arg1=nothing; kwargs...)

Calculate and plot the day-night terminator and the civil, nautical and astronomical twilights.

See full GMT docs at [`solar`]($(GMTdoc)solar.html)

Parameters
----------

- $(_opt_J)
- $(_opt_B)
- **C** | **format** :: [Type => Bool]

- **G** | **fill** :: [Type => Str | Number]

- **I** | **sun** :: [Type => Bool | Tuple | NamedTuple]

- $(opt_P)
- **M** | **dump** :: [Type => Bool]

- $(_opt_R)
- **N** | **invert** :: [Type => Bool]

- **T** | **terminators** :: [Type => Bool | Tuple | NamedTuple]

- **W** | **pen** :: [Type => Str | Tuple]

- $(opt_U)
- $(opt_V)
- $(opt_X)
- $(opt_Y)
- $(opt_bo)
- $(_opt_h)
- $(opt_o)
- $(_opt_p)
- $(_opt_t)
- $(opt_savefig)

To see the full documentation type: ``@? solar``
"""
function solar(cmd0::String="", arg1=nothing; first=true, kwargs...)

	gmt_proggy = (IamModern[]) ? "solar " : "pssolar "
	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	def_J = (isempty(d)) ? " -JG0/0/14c" : " -JX14cd/0d"
	(isempty(d)) && (d[:coast] = true; d[:T] = :d; d[:G] = "navy@75"; d[:show] = true)
	cmd, _, opt_J, = parse_BJR(d, "", "", O, def_J)
	cmd, = parse_common_opts(d, cmd, [:bo :c :h :o :p :t :UVXY :params]; first=first)
	cmd  = parse_these_opts(cmd, d, [[:C :format], [:M :dump], [:N :invert]])

	cmd  = add_opt_fill(cmd, d, [:G :fill], 'G')
	cmd  = add_opt(d, cmd, "I", [:I :sun], (pos="",date="+d",TZ="+z"))
	cmd  = add_opt(d, cmd, "T", [:T :terminators], (term="",date="+d",TZ="+z"))
	cmd *= opt_pen(d, 'W', [:W :pen])

	opt_extra = "";		finish = true
	if (occursin("-I", cmd) || occursin("-I", cmd0))
		opt_extra = "-I";		finish = false;	cmd = replace(cmd, opt_J => "")
	end
	_cmd = (opt_extra != "-I" && (!occursin("-M", cmd) && !occursin("-M", cmd0)) && (!occursin("-T", cmd) && !occursin("-T", cmd0))) ?
	finish_PS_nested(d, [gmt_proggy * cmd]) : [gmt_proggy * cmd]
	(length(_cmd) > 1 && startswith(_cmd[2], (IamModern[]) ? "coast" : "pscoast") && !contains(_cmd[1], " -R") &&
		contains(_cmd[2], " -R ")) && (_cmd[2] = replace(_cmd[2], "-R" => "-Rd"))		# Apparently solar defaults to -Rd but only internally in C
	((r = check_dbg_print_cmd(d, _cmd)) !== nothing) && return r
	(length(_cmd) == 1 && (contains(_cmd[1], " -I") || contains(_cmd[1], " -M"))) && return gmt(_cmd[1], arg1)	# The dump case is different
	prep_and_call_finish_PS_module(d, _cmd, opt_extra, K, O, finish, arg1)
end

# ---------------------------------------------------------------------------------------------------
solar!(cmd0::String="", arg1=nothing; kw...) = solar(cmd0, arg1; first=false, kw...)

const pssolar  = solar				# Alias
const pssolar! = solar!				# Alias