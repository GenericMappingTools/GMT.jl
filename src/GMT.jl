__precompile__()

module GMT

const GMTver = 6.0
const FMT = "ps"

export
	GMTver,
	GMT_Call_Module,
	GMT_Create_Args,
	GMT_Create_Session,
	GMT_Create_Options,
	GMT_Create_Cmd,
	GMT_Create_Data,
	GMT_Destroy_Options,
	GMT_Destroy_Args,
	GMT_Destroy_Session,
	GMT_Get_Default,
	GMT_Option,
	GMT_Register_IO,
	GMT_Destroy_Data,
	GMT_Write_Data,
	GMT_Init_VirtualFile, GMT_Open_VirtualFile, GMT_Close_VirtualFile, GMT_Read_VirtualFile,
	GMT_Get_Matrix, GMT_Put_Matrix, GMT_Get_Vector, GMT_Put_Vector,
	GMT_DATASET, GMT_GRID, GMT_MATRIX, GMT_PALETTE, GMT_UNIVECTOR,
	GMT_RESOURCE, GMTAPI_CTRL, GMTAPI_DATA_OBJECT,
	GMTgrid, GMTimage, GMTcpt, GMTdataset, GMTps,	
	GMT_Encode_Options, GMT_Expand_Option, gmtlib_grd_flip_vertical,
	gmt, grid_type,
	basemap, basemap!, coast, coast!, logo, logo!, xy, xy!, grdcontour, grdcontour!, grdimage,
	grdimage!, grdtrack, grdview, grdview!, makecpt, histogram, histogram!, image, image!, psconvert,
	colorbar, colorbar!, rose, rose!, solar, solar!, text, text!, gmtinfo, grdinfo, surface,
	triangulate, nearneighbor, imshow, imshow!, plot, plot!, splitxyz, wiggle, wiggle!,
	text_record,
	NULL

include("common_docs.jl")
include("libgmt_h.jl")
include("libgmt.jl")
include("gmt_main.jl")
include("common_options.jl")
include("gmtinfo.jl")
include("gmtlogo.jl")
include("grdcontour.jl")
include("grdinfo.jl")
include("grdimage.jl")
include("grdtrack.jl")
include("grdview.jl")
include("imshow.jl")
include("makecpt.jl")
include("nearneighbor.jl")
include("psbasemap.jl")
include("pscoast.jl")
include("psconvert.jl")
include("pshistogram.jl")
include("psimage.jl")
include("psscale.jl")
include("psrose.jl")
include("pssolar.jl")
include("pstext.jl")
include("psxy.jl")
include("pswiggle.jl")
include("plot.jl")
include("splitxyz.jl")
include("surface.jl")
include("triangulate.jl")

end # module
