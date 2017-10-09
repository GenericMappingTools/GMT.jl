"""
	makecpt(cmd0::String="", arg1=[]; data=[], portrait=true, kwargs...)
	
Make static color palette tables (CPTs).
"""
# ---------------------------------------------------------------------------------------------------
function makecpt(cmd0::String="", arg1=[]; Vd=false, data=[], portrait=true, kwargs...)

	d = KW(kwargs)
	cmd = ""
	cmd = parse_V(cmd, d)
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_i = parse_i(cmd, d)

	# Read in the 'data'
	if (isa(data, String))
		if (GMTver >= 6)				# Due to a bug in GMT5, gmtread has no -i option 
			data = gmt("read -Td " * opt_i * opt_bi * " " * data)
			if (!isempty(opt_i))		# Remove the -i option from cmd. It has done its job
				cmd = replace(cmd, opt_i, "")
				opt_i = ""
			end
		else
			data = gmt("read -Td " * opt_bi * " " * data)
		end
	end
	if (!isempty(data)) arg1 = data  end

	for sym in [:C :color]
		if (haskey(d, sym))
			if (isa(d[sym], GMT.GMTcpt))
				cmd = cmd * " -C"
				arg1 = d[sym]
			else
				cmd = cmd * " -C" * arg2str(d[sym])
			end
			break
		end
	end

	for sym in [:E :data_levels]
		if (haskey(d, sym))
			if (isempty_(arg1) && isempty_(data))
				error("E option requires that a data table is provided as well")
			else
				cmd = cmd * " -E" * arg2str(d[sym])
			end
			break
		end
	end

	cmd = add_opt(cmd, 'A', d, [:A :alpha :transparency])
	cmd = add_opt(cmd, 'D', d, [:D])
	cmd = add_opt(cmd, 'F', d, [:F :force])
	cmd = add_opt(cmd, 'G', d, [:G :truncate])
	cmd = add_opt(cmd, 'I', d, [:I :inverse :reverse])
	cmd = add_opt(cmd, 'N', d, [:N :nobg])
	cmd = add_opt(cmd, 'Q', d, [:Q :log])
	cmd = add_opt(cmd, 'S', d, [:S :auto])
	cmd = add_opt(cmd, 'T', d, [:T :range])
	cmd = add_opt(cmd, 'W', d, [:W :wrap :categorical])
	cmd = add_opt(cmd, 'Z', d, [:Z :continuous])

	if (haskey(d, :cptname))
		cmd = cmd * " > " * d[:cptname]
		C = gmt("makecpt " * cmd)
		Vd && println(@sprintf("\tmakecpt %s", cmd))
	else
		Vd && println(@sprintf("\tmakecpt %s", cmd))
		if (isempty_(arg1))
			C = gmt("makecpt " * cmd)
		else
			C = gmt("makecpt " * cmd, arg1)
		end
	end
end

# ---------------------------------------------------------------------------------------------------
# Version to use with the -E option
makecpt(arg1=[]; Vd=false, data=[], portrait=true, kw...) = makecpt("", arg1; Vd=Vd, data=data, portrait=portrait, kw...)