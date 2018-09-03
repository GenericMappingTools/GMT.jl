"""
    gmtset(cmd0::String="", kwargs...)

Adjust individual GMT defaults settings in the current directory’s gmt.conf file.

Full option list at [`gmtinfo`](http://gmt.soest.hawaii.edu/doc/latest/gmtset.html)

Parameters
----------

- **D** : **units** : -- Str or [] --  

    Modify the GMT defaults based on the system settings. Append u for US defaults or s for SI defaults.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/gmtinfo.html#d)
- **G** : **defaultsfile** : -- Str --

    Name of specific gmt.conf file to read and modify. 
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/gmtinfo.html#g)
- $(GMT.opt_V)
- $(GMT.opt_write)
"""
function gmtset(cmd0::String=""; kwargs...)

	length(kwargs) == 0 && return monolitic("gmtset", cmd0)	# Speedy mode

	d = KW(kwargs)
	cmd = parse_V("", d)

	cmd = add_opt(cmd, 'D', d, [:D :units], true)
	cmd = add_opt(cmd, 'G', d, [:G :defaultsfile], true)
 
	key = collect(keys(d))
	for k = 1:length(d)
		if (key[k] == :Vd)	continue	end
		cmd = cmd * " " * string(key[k]) * " " * string(d[key[k]])
	end

	(haskey(d, :Vd)) && println(@sprintf("\tgmtset %s", cmd))

	gmt("gmtset " * cmd)
end