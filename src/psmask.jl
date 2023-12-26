"""
	mask(cmd0::String="", arg1=nothing; kwargs...)

Clip or mask map areas with no data table coverage

See full GMT (not the `GMT.jl` one) docs at [`psmask`]($(GMTdoc)mask.html)

Parameters
----------

- $(GMT.opt_I)
- $(GMT._opt_R)

- $(GMT._opt_B)
- **C** | **endclip** | **end_clip_path** :: [Type => Bool]

    Mark end of existing clip path. No input file is needed.
- **D** | **dump** :: [Type => Str]

    Dump the (x,y) coordinates of each clipping polygon to one or more output files
    (or stdout if template is not given).
- **F** | **oriented** :: [Type => Str | []]

    Force clip contours (polygons) to be oriented so that data points are to the left (-Fl [Default]) or right (-Fr) 
- **G** | **fill** :: [Type => Number | Str]

    Set fill shade, color or pattern for positive and/or negative masks [Default is no fill].
- $(GMT._opt_J)
- $(GMT.opt_Jz)
- **L** | **nodegrid** :: [Type => Str]

    Save the internal grid with ones (data constraint) and zeros (no data) to the named nodegrid.
- **N** | **invert** | **inverse** :: [Type => Bool]

    Invert the sense of the test, i.e., clip regions where there is data coverage.
- $(GMT.opt_P)
- **Q** | **cut** | **cut_number** :: [Type => Number | Str]

    Do not dump polygons with less than cut number of points [Dumps all polygons].
- **S** | **search_radius** :: [Type => Number | Str]

    Sets radius of influence. Grid nodes within radius of a data point are considered reliable.
- **T** | **tiles** :: [Type => Bool]

    Plot tiles instead of clip polygons. Use -G to set tile color or pattern. Cannot be used with -D.
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT._opt_bi)
- $(GMT._opt_di)
- $(GMT.opt_e)
- $(GMT._opt_h)
- $(GMT._opt_i)
- $(GMT._opt_p)
- $(GMT.opt_r)
- $(GMT._opt_t)
- $(GMT.opt_w)
- $(GMT.opt_swap_xy)

To see the full documentation type: ``@? mask``
"""
function mask(cmd0::String="", arg1=nothing; first=true, kwargs...)

    gmt_proggy = (IamModern[1]) ? "mask "  : "psmask "

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	cmd, _, _, opt_R = parse_BJR(d, "", "", O, " -JX12c/12c")
	cmd, = parse_common_opts(d, cmd, [:I :UVXY :JZ :c :e :p :r :t :w :params], first)
	cmd  = parse_these_opts(cmd, d, [[:C :endclip :end_clip_path], [:D :dump], [:L :nodegrid], [:N :invert :inverse],
	                                 [:Q :cut :cut_number], [:S :search_radius], [:T :tiles]])

	if ((val = find_in_dict(d, [:F :oriented])[1]) !== nothing)
        cmd = (string(val)[1] == 'r') ? cmd * " -Fr" : cmd * " -Fl"
    end

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)

	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')

	return finish_PS_module(d, gmt_proggy * cmd, "", K, O, true, arg1)
end

# ---------------------------------------------------------------------------------------------------
mask!(cmd0::String="", arg1=nothing; kw...) = mask(cmd0, arg1; first=false, kw...)
mask(arg1; kw...)  = mask("", arg1; first=true, kw...)
mask!(arg1; kw...) = mask("", arg1; first=false, kw...)

# ---------------------------------------------------------------------------------------------------
# This method has nothing to do with psmask, but can be seen as an extension to it.
function mask(GI::GItype, D::GDtype; touches=false, inverse::Bool=false)
	prj1 = GI.proj4
	prj2 = isa(D, GMTdataset) ? D.proj4 : D[1].proj4
    geog1, geog2 = isgeog(prj1), isgeog(prj2)
	(prj1 != "" && prj2 != "" && prj1 != prj2 && !(geog1 && geog2)) &&   # Tricky these geog
        (D = (geog1) ? xy2lonlat(D, t_srs=prj1) : lonlat2xy(D, t_srs=prj1))
	_GI = GMT.crop(GI, region = isa(D, GMTdataset) ? D.bbox : D[1].ds_bbox)[1]
	height, width = dims(_GI)
	maska = maskgdal(D, width, height, touches=touches, layout=_GI.layout, inverse=!inverse)	# !inverse to mask oceans by default
	(isa(GI, GMTgrid)) && (_GI[maska] .= NaN)
	if (isa(GI, GMTimage))        # Here, if image is RGB we may say insitu=true to get the alpha added to original
		(size(_GI,3) == 1) && (_GI = ind2rgb(_GI))
		maska = reinterpret(UInt8, .!maska) * UInt8(255)	# Now we do !maska because full tranparency is = 255 (Shit is alpha = opacity)
		image_alpha!(_GI, alpha_band=maska)
	end
	return _GI
end

const psmask  = mask			# Alias
const psmask! = mask!			# Alias
