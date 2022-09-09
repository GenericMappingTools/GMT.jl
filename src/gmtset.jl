"""
    gmtset(; kwargs...)

Adjust individual GMT defaults settings in the current directory’s gmt.conf file.

Full option list at [`gmtset`]($(GMTdoc)gmtset.html)

Parameters
----------

- **D** | **units** :: [Type => Str | []]

    Modify the GMT defaults based on the system settings. Append u for US defaults or s for SI defaults.
    ($(GMTdoc)gmtinfo.html#d)
- **G** | **defaultsfile** :: [Type => Str]

    Name of specific gmt.conf file to read and modify. 
    ($(GMTdoc)gmtset.html#g)
- $(GMT.opt_V)
- $(GMT.opt_write)

### Example:

    gmtset(FONT_ANNOT_PRIMARY="12p,Helvetica", MAP_GRID_CROSS_SIZE_PRIMARY=0.25)
"""
function gmtset(; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd = parse_V(d, "")
	cmd = add_opt(d, cmd, "D", [:D :units], nothing, true)
	cmd = add_opt(d, cmd, "G", [:G :defaultsfile], nothing, true)
 
	key = collect(keys(d))
	for k = 1:length(d)
		(key[k] == :Vd)	&& continue
		cmd *= " " * string(key[k]) * " " * string(d[key[k]])
		delete!(d, key[k])
	end

	cmd = "gmtset " * cmd
	if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end
	gmt(cmd)
end