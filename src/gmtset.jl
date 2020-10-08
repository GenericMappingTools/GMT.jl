"""
    gmtset(cmd0::String="", kwargs...)

Adjust individual GMT defaults settings in the current directory’s gmt.conf file.

Full option list at [`gmtset`]($(GMTdoc)gmtset.html)

Parameters
----------

- **D** | **units** :: [Type => Str | []]

    Modify the GMT defaults based on the system settings. Append u for US defaults or s for SI defaults.
    ($(GMTdoc)gmtinfo.html#d)
- **G** | **defaultsfile** :: [Type => Str]

    Name of specific gmt.conf file to read and modify. 
    ($(GMTdoc)gmtinfo.html#g)
- $(GMT.opt_V)
- $(GMT.opt_write)
"""
function gmtset(cmd0::String=""; kwargs...)

	length(kwargs) == 0 && return monolitic("gmtset", cmd0)

	d = KW(kwargs)
	help_show_options(d)			# Check if user wants ONLY the HELP mode
	cmd = parse_V(d, "")

	cmd = add_opt(cmd, 'D', d, [:D :units], nothing, true)
	cmd = add_opt(cmd, 'G', d, [:G :defaultsfile], nothing, true)
 
	key = collect(keys(d))
	for k = 1:length(d)
		(key[k] == :Vd)	&& continue
		cmd *= " " * string(key[k]) * " " * string(d[key[k]])
		delete!(d, key[k])
	end

	cmd = "gmtset " * cmd
	if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end
	gmt(cmd)
	gmt("destroy")
end