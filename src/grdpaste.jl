"""
	grdpaste(cmd0::String="", G1=nothing, G2=nothing, kwargs...)

Combine grids ``grid1`` and ``grid2`` into ``grid3`` by pasting them together along their common edge.
Both grids must have the same dx, dy and have one edge in common.

See full GMT docs at [`grdpaste`]($(GMTdoc)grdpaste.html)

Parameters
----------

- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdpaste(....) form.
- $(opt_V)
- $(_opt_f)

To see the full documentation type: ``@? grdpaste``
"""
function grdpaste(G1::GItype, G2::GItype; kw...)
	(G1.layout != "" && G1.layout[2] == 'R') && error("Pasting row oriented grids (such those produced by GDAL) is not implemented.")
	d = init_module(false, kw...)[1]
	grdpaste(G1, G2, d)
end
function grdpaste(G1::GItype, G2::GItype, d::Dict{Symbol, Any})
	cmd, = parse_common_opts(d, "", [:G :V_params :f])
	cmd *= " -S"
	side::GMTdataset = common_grd(d, "grdpaste " * cmd, G1, G2)		# Finish build cmd and run it
	_side = side.data[1]
	(_side == 11 || _side == 22 || _side == 33 || side == 44) && (@warn("Method ($_side) not yet implemented. Please open an issue."); return nothing)
	if (_side == 1 || _side == 10)				# 1- "B is on top of A"
		_z2 = (G1.registration == 0) ? ((_side == 10) ? G2.z : G2.z[2:end, :]) : G2.z
		G3 = mat2grid([G1.z; _z2], G2); G3.range[3] = G1.range[3]
	elseif (_side == 2 || _side == 21)			# 2- "A is on top of B"
		_z2 = (G1.registration == 0) ? ((_side == 21) ? G1.z : G1.z[2:end, :]) : G1.z
		G3 = mat2grid([G2.z; _z2], G1); G3.range[3] = G2.range[3]
	elseif (_side == 3 || _side == 32)			# 3- "A is on the right of B"
		_z2 = (G1.registration == 0) ? ((_side == 32) ? G1.z : view(G1.z, :, 2:size(G2.z,2))) : G1.z
		G3 = mat2grid([G2.z _z2], G1); G3.range[1] = G2.range[1]
	elseif (_side == 4 || _side == 43)			# 4- "A is on the left of B"
		_z2 = (G1.registration == 0) ? ((_side == 43) ? G2.z : view(G2.z, :, 2:size(G2.z,2))) : G2.z
		G3 = mat2grid([G1.z _z2], G1); G3.range[2] = G2.range[2]
	end
	(_side != 3 && _side != 4 && _side < 25) && (G3.y = collect(linspace(G3.range[3], G3.range[4], size(G3,1)+G3.registration)))
	(_side == 3 || _side == 4 || _side > 30) && (G3.x = collect(linspace(G3.range[1], G3.range[2], size(G3,2)+G3.registration)))
	G3
end

# ---------------------------------------------------------------------------------------------------
grdpaste(G1::String, G2::GItype; kw...) = grdpaste(gmtread(G1), G2; kw...)
grdpaste(G1::GItype, G2::String; kw...) = grdpaste(G1, gmtread(G2); kw...)

# ---------------------------------------------------------------------------------------------------
function grdpaste(G1::String, G2::String; kw...)
	# This method lets pass two file names and either return the pasted grid or save in on disk.
	d = init_module(false, kw...)[1]
	grdpaste(G1, G2, d)
end
function grdpaste(G1::String, G2::String, d::Dict{Symbol, Any})
	cmd, = parse_common_opts(d, "", [:G :V_params :f])
	cmd != "" && (cmd = " " * cmd)
	gmt("grdpaste " * G1 * " " * G2 * cmd)
end