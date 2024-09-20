
Base.@kwdef struct earth_age
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "g"]
end

Base.@kwdef struct earth_geoid
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "g"]
end

Base.@kwdef struct earth_mag
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "p"]
end
 
Base.@kwdef struct earth_gebco
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m", "30s", "15s", "03s", "01s"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "p",   "g",   "g"]
end

Base.@kwdef struct earth_gebcosi
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m", "30s", "15s", "03s", "01s"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "p",   "g",   "g"]
end

Base.@kwdef struct earth_mask
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m", "30s", "15s"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp"]
end

Base.@kwdef struct earth_dist
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "g"]
end

Base.@kwdef struct earth_faa
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "p"]
end

Base.@kwdef struct earth_faaerror
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "p"]
end

Base.@kwdef struct earth_edefl
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "p"]
end

Base.@kwdef struct earth_ndefl
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "p"]
end

Base.@kwdef struct earth_mss
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "g"]
end

Base.@kwdef struct earth_mdt
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "07m"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "g"]
end

Base.@kwdef struct earth_relief
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m", "30s", "15s", "03s", "01s"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "p",   "g",   "g"]
end

Base.@kwdef struct earth_synbath
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m", "30s", "15s", "03s", "01s"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "p",   "g",   "g"]
end

Base.@kwdef struct earth_vgg
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "p"]
end

Base.@kwdef struct earth_wdmam
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "g"]
end

Base.@kwdef struct earth_day
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m", "30s"]
end

Base.@kwdef struct earth_night
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m", "30s"]
end

Base.@kwdef struct mars_relief
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m", "30s", "15s", "12s"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "p",   "p"]
end

Base.@kwdef struct mercury_relief
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m", "56s"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "p"]
end

Base.@kwdef struct moon_relief
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m", "30s", "15s", "14s"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "p"]
end

Base.@kwdef struct pluto_relief
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m", "52s"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "p"]
end

Base.@kwdef struct venus_relief
	res::Vector{String} = ["01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m", "02m", "01m"]
	reg::Vector{String} = ["gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp",  "gp"]
end


# ----------------------------------------------------------------------------------------------------------------
"""
    remotegrid(name, res_p::String=""; res::String="", reg::String="", info=false)

Generate the full name of a GMT "Remote Data Grid" convenient to use in other GMT functions that deal with grids.

A "Remote Data Sets" set is a grid that is stored on one or more remote servers.
It may be a single grid file or a collection of subset tiles making up a larger grid. They are not distributed with GMT
or installed during the installation procedures. GMT offers several remote global data grids that you can access via
our remote file mechanism. The first time you access one of these files, GMT will download the file (or a subset tile)
from the selected GMT server and save it to the server directory under your GMT user directory [~/.gmt]. From then on
we read the local file from there. See more at: https://docs.generic-mapping-tools.org/dev/datasets/remote-data.html#currently-available-remote-data-sets

This function lets you access the GMT "Remote Data Sets" grids via simplified syntax. Note that it won't download the
data but generates and returns the full grid name that can be used in other GMT functions (``gmtread``, ``grdimage``,
``grdcontour``, ``grdcut``, etc.).

### Parameters
- `name`: The grid name. One of:

  - `earth_age`, `earth_geoid`, `earth_mag`, `earth_gebco`, `earth_gebcosi`, `earth_mask`, `earth_dist`, `earth_faa`, `earth_faaerror`, `earth_edefl`, `earth_ndefl`, `earth_mss`, `earth_mdt`, `earth_relief`, `earth_synbath`, `earth_vgg`, `earth_wdmam`, `earth_day`, `earth_night`, 
  - `mars_relief`, `mercury_relief`, `moon_relief`, `pluto_relief`, `venus_relief`.

### Keyword Arguments
- `rest_p` or `res`: Grid resolution. One of "01d", "30m", "20m", "15m", "10m", "06m", "05m", "04m", "03m" or higher
  for the grids that have finer resolution. Use the `info` option to inquiry all available resolutions of a grid.
  The suffix ``d``, ``m``, and ``s`` stand for arc-degrees, arc-minutes, and arc-seconds, respectively.
	
- `reg`: Grid registration. Choose between 'g'rid or 'p'ixel registration or leave blank for modules to picking the indicated one.
  By default, a gridline-registered grid is selected unless only the pixel-registered grid is available.
	
- `info`: Print grid information (true) or just the full grid name (false). Cannot be used with the option `res`.

To get only the list of available grid names, type ``remotegrid()``.

As sated above this function does not download any data but is a convenient helper for those who do. However, one need
to be very carefull with the grid sizes. For example, the ``earth_relief`` at "15s" weights 2.6 GB ... and 45 GB at "01s".
So, for those high resolution grids you should use the the ``region`` option provided by the ``grdcut`` or ``gmtread``.

### Examples

See the Moon grid at "6m" resolution
```julia
G = gmtread(remotegrid("moon", res="6m"))
viz(G, shade=true)
```

See a region over Oman of the "earth_relief" at "15s" resolution
```julia
G = gmtread(remotegrid("earth_relief", res="15s"), region=(55,60,23,28))
viz(G, shade=true, coast=true)
```

See all details of the "earth_relief" grid
```julia
@? remotegrid("earth_relief", info=true)
```
	
"""
function remotegrid(name, res_p::String=""; res::String="", reg::String="", info=false)::String
	earth_names = ["earth_age", "earth_geoid", "earth_mag", "earth_gebco", "earth_gebcosi", "earth_mask", "earth_dist", "earth_faa", "earth_faaerror", "earth_edefl", "earth_ndefl", "earth_mss", "earth_mdt", "earth_relief", "earth_synbath", "earth_vgg", "earth_wdmam", "earth_day", "earth_night"]
	planet_names = ["mercury_relief", "venus_relief", "mars_relief", "moon_relief"]
	(res == "") && (res = res_p)	# Accept both positional and kwarg but later takes precedence
	
	n_under = count_chars(name, '_')
	if ((_ind = findfirst(contains.(earth_names, name))) !== nothing)		# OK, a terrestrial grid
		(n_under == 0) && (name = "earth_" * name)
		(n_under == 1 && !contains(name, "earth_")) && (name = "earth_" * name)
	elseif ((_ind = findfirst(contains.(planet_names, name))) !== nothing)	# A planet grid
		(n_under == 0) && (name *= "_relief")
		(n_under == 1 && !contains(name, "_relief")) && (name = planet_names[_ind] * "_relief" * name[findfirst(name, '_'):end])
	else
		error("$(name) not a valid Earth or Planetary grid name")
	end
	(name[1] == '@') && (name = name[2:end])	# Strip off the leading '@' that would complicate a lot remaining code

	# OK, here we know that 'name' is a valid grid name but it still can contain, or not, the res and reg codes
	n_under = count_chars(name, '_')			# Count them again because 'name' may have changed. And it must be >= 1
	if (n_under == 1)
		thisgrid = eval(Symbol(name))()			# To be used also if info == false
		if (info == 1)
			println("Resolutions available for \"$(name)\":\n\t$(thisgrid.res)")
			println("Registrations ('g'rid, 'p'ixel):\n\t$(thisgrid.reg)")
			println("For more information (sizes, technical details), see:")
			t = "https://www.generic-mapping-tools.org/remote-datasets/" * replace(name, "_" => "-") * ".html"
			println("\t$t\n")
			return t
		end
	end
	(info == 1 && n_under > 1) && (@warn("No information for $(name) available when resolution was also specified"); return "")

	function check_reg(name, grdtype, reg, ind)
		# Check if 'reg' is valid for 'name' and 'grdtype' and set 'name' accordingly
		_reg = lowercase(reg[1])
		(_reg != 'p' && _reg != 'g') && error("Bad registration code $(reg). Must be one of 'grid' or 'pixel'")
		contains(grdtype.reg[ind], _reg) ? (name *= "_" * _reg) :
			@warn("This grid does not support the registration code '$(reg)' at resolution '$(res)'. Using the available registration '$(grdtype.reg[ind])' instead.")
		return name
	end

	if (n_under == 1)							# name & type. No res or reg
		(res == "") && error("Must provide a grid resolution")
		thisgrid_res = thisgrid.res
		((_ind = findfirst(contains.(thisgrid_res, res))) === nothing) && error("Bad resolution code $(res). Must be one of $thisgrid_res.")
		ind::Int = _ind							# Fck Anys
		(res != "5m") ? (res = thisgrid_res[ind]) : (res = "05m")	# 5m is an exception because it may be miscatch by 15m
		name *= "_" * res
		(reg != "") && (name = check_reg(name, thisgrid, reg, ind))
	elseif (n_under == 2 && reg != "")			# name & type & res
		ind_res::Int = findlast(name, '_')
		thisgrid = eval(Symbol(name[1:ind_res-1]))
		res = name[ind_res+1:end]
		length(res) == 2 && (res = "0" * res)	# To allow both 01d and 1d
		((_ind = findfirst(contains.(thisgrid_res, res))) === nothing) && error("Bad resolution code $(res). Must be one of $thisgrid_res.")
		ind = _ind
		name = check_reg(name, thisgrid, reg, ind)
	end

	return "@" * name
end

function remotegrid()
	# A method just for help
	println("Available Remote Grids:")
	println("    ",["earth_age", "earth_geoid", "earth_mag", "earth_gebco", "earth_gebcosi", "earth_mask", "earth_dist", "earth_faa", "earth_edefl", "earth_ndefl", "earth_mss", "earth_mdt", "earth_relief", "earth_synbath", "earth_vgg", "earth_wdmam", "earth_day", "earth_night"])
	println("    ",["mercury_relief", "venus_relief", "mars_relief", "moon_relief"])
	println("To get information about resolutions and registrations of grid \"name\", type:")
	printstyled("    remotegrid(\"name\", info=true)\n"; color = :yellow)
	return nothing
end