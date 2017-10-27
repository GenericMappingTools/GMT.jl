"""
    grdinfo(cmd0::String="", arg1=[], kwargs...)

Reads a 2-D grid file and reports metadata and various statistics for the (x,y,z) data in the grid file

Full option list at [`grdinfo`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html)

Parameters
----------

- **C** : **numeric** : -- Str or Number --
    Formats the report using tab-separated fields on a single line.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html#c)
- **D** : **tiles** : -- Number or Str --  
    Divide a single grid’s domain (or the -R domain, if no grid given) into tiles of size
    dx times dy (set via -I).
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html#d)
- **F** : -- Bool or [] --
    Report grid domain and x/y-increments in world mapping format.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html#f)
- **I** : **nearest_multiple** : -- Number or Str --
    Report the min/max of the region to the nearest multiple of dx and dy, and output
    this in the form -Rw/e/s/n 
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html#i)
- **L** : **force_scan** : -- Number or Str --
    Report stats after actually scanning the data.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html#l)
- **M** : **zmin_max** : -- Bool or [] --
    Find and report the location of min/max z-values.
    [`-M`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html#m)
- $(GMT.opt_R)
- **T** : **nan_t** : -- Number or Str --
    Determine min and max z-value.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html#t)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
# ---------------------------------------------------------------------------------------------------
function grdinfo(cmd0::String="", arg1=[]; data=[], kwargs...)

	if (length(kwargs) == 0)		# Good, speed mode
		return gmt("grdinfo " * cmd0)
	end

	if (!isempty_(data) && !isa(data, GMTgrid))
		error("When using 'data', it MUST contain a GMTgrid data type")
	end

	d = KW(kwargs)
	cmd = ""
	cmd, opt_R = parse_R(cmd, d)
	cmd = parse_V(cmd, d)
	cmd = parse_f(cmd, d)

	cmd = add_opt(cmd, 'C', d, [:C :numeric])
	cmd = add_opt(cmd, 'D', d, [:D :tiles])
	cmd = add_opt(cmd, 'F', d, [:F])
	cmd = add_opt(cmd, 'I', d, [:I :nearest_multiple])
	cmd = add_opt(cmd, 'L', d, [:L :force_scan])
	cmd = add_opt(cmd, 'M', d, [:M :location])
	cmd = add_opt(cmd, 'T', d, [:T :zmin_max])

	if (!isempty_(data))
		if (!isempty_(arg1))
			warn("Conflicting ways of providing input data. Both a file name via positional and
				  a data array via kwyword args were provided. Ignoring later argument")
		else
			if (isa(data, String)) 		# OK, we have data via file
				cmd = cmd * " " * data
			else
				arg1 = data				# Whatever this is
			end
		end
	end

	(haskey(d, :Vd)) && println(@sprintf("\tgrdinfo %s", cmd))

	if (!isempty_(arg1))  R = gmt("grdinfo " * cmd, arg1)
	else                  R = gmt("grdinfo " * cmd)
	end
	return R
end

# ---------------------------------------------------------------------------------------------------
grdinfo(arg1::GMTgrid, cmd0::String=""; data=[], kw...) = grdinfo(cmd0, arg1; data=data, kw...)