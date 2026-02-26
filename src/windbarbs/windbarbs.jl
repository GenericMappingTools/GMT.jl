"""
    windbarbs(arg1; kwargs...)
or

    windbarbs(u, v; kwargs...)

Plot wind barbs in either 2D or 3D, from table data or two u,v grids.

- `polar | A`: (grids method)
- `color | C`:
- `offset | D`:
- `fill | G`:
- `intens | I`: (table method)
- `spacing | I`: (grids method)
- `noclip | N`:
- `barbs | Q`:
- `pen | W`:
- `azimuths | Z`: (grids method)

### Example
```julia

```
"""
windbarbs(cmd0::String=""; first=true, kw...) = windbarbs(gmtread(cmd0, data=true); first=first, kw...)
function windbarbs(arg1; first=true, kw...)
	d, K, O = init_module(first, kw...)		# Also checks if the user wants ONLY the HELP mode
	windbarbs(arg1, O, K, d)
end
function windbarbs(arg1, O::Bool, K::Bool, d::Dict{Symbol, Any})

	gmt_proggy = (IamModern[]) ? "barb " : "psbarb "

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O)
	cmd = parse_common_opts(d, cmd, [:UVXY :a :bi :di :e :f :h :i :p :t :yx :params]; first=!O)[1]
	cmd = parse_these_opts(cmd, d, [[:D :offset], [:I :intens], [:N :no_clip :noclip]])
	cmd = add_opt(d, cmd, "Q", [:Q :barbs], (len=("", arg2str, 1), length=("", arg2str, 1), angle="+a", fill=("+g", add_opt_fill), pen=("+p", add_opt_pen), just="+j", speed="+s", width="+w", uv="+z", cartesian="+z"))
	cmd *= opt_pen(d, 'W', [:W :pen])
	cmd = add_opt_fill(cmd, d, [:G :fill], "G")
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, CPTaliases, 'C', 1, arg1)

	(!isa(arg1, GDtype) && !isa(arg1, Matrix{<:Real})) && (arg1 = tabletypes2ds(arg1))
	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R, = read_data(d, "", cmd, arg1, opt_R)

	_cmd = [gmt_proggy * cmd]
	_cmd = frame_opaque(_cmd, gmt_proggy, opt_B, opt_R, opt_J)		# No -t in frame
	_cmd = finish_PS_nested(d, _cmd)
	((r = check_dbg_print_cmd(d, _cmd)) !== nothing) && return r
	prep_and_call_finish_PS_module(d, _cmd, "", K, O, true, arg1, arg2)
end

function windbarbs(arg1::Union{String, GMTgrid}, arg2::Union{String, GMTgrid}; first=true, kw...)
	d, K, O = init_module(first, kw...)
	windbarbs(arg1, arg2, O, K, d)
end
function windbarbs(arg1::Union{String, GMTgrid}, arg2::Union{String, GMTgrid}, O::Bool, K::Bool, d::Dict{Symbol, Any})
	d[:barbs] = true
	d, cmd, arg1, arg2, arg3 = grdvector_helper(arg1, arg2, K, O, d)	# arg3 is a possible CPT
	cmd[1] = replace(cmd[1], "grdvector" => "grdbarb")
	cmd[1] = add_opt(d, cmd[1], "Q", [:Q :barbs], (len=("", arg2str, 1), length=("", arg2str, 1), angle="+a", fill=("+g", add_opt_fill), pen=("+p", add_opt_pen), just="+j", justify="+j", speed="+s", width="+w"))
	delete!(d, :barbs)			# Because if we used 'Q', 'barbs' was still in the dictionary
	cmd[1] = parse_these_opts(cmd[1], d, [[:A :polar], [:T :signs :sign_scale], [:Z :azim :azimuth :azimuths]])

	((r = check_dbg_print_cmd(d, cmd)) !== nothing) && return r
	prep_and_call_finish_PS_module(d, cmd, "", K, O, true, arg1, arg2, arg3)
end
