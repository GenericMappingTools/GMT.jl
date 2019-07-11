const Void = Cvoid
const NULL = C_NULL

const GMT_SESSION_NORMAL   = 0   # Typical mode to GMT_Create_Session
const GMT_SESSION_NOEXIT   = 1   # Call return and not exit when error
const GMT_SESSION_EXTERNAL = 2   # Called by an external API (e.g., Matlab, Julia, Python).
const GMT_SESSION_COLMAJOR = 4   # External API uses column-major formats (e.g., Julai, MATLAB, Fortran). [Row-major format]
const GMT_SESSION_LOGERRORS = 8
const GMT_SESSION_RUNMODE  = 16	 # If set enable GMT's modern runmode. [Classic]
const GMT_SESSION_BEGIN    = 32  # Begin a new session. [Sets modern mode]
const GMT_SESSION_END      = 64  # End a session. [Ends modern mode]
const GMT_SESSION_CLEAR    = 128 # Clear session files/directories
const GMT_SESSION_FIGURE   = 256 # Add a figure to the session queue. [Modern mode only]
# begin enum GMT_enum_runmode
const GMT_CLASSIC        = 0     # Select Classic GMT behavior with -O -K -R -J
const GMT_MODERN         = 1     # Select Modern behavior where -O -K are disabled and -R -J optional if possible
# begin enum GMT_enum_type
const GMT_CHAR = 0
const GMT_UCHAR = 1
const GMT_SHORT = 2
const GMT_USHORT = 3
const GMT_INT = 4
const GMT_UINT = 5
const GMT_LONG = 6
const GMT_ULONG = 7
const GMT_FLOAT = 8
const GMT_DOUBLE = 9
const GMT_TEXT = 10
const GMT_DATETIME = 11
const GMT_N_TYPES = 12
const GMT_VIA_CHAR = 100         # int8_t, 1-byte signed integer type */
const GMT_VIA_UCHAR = 200        # uint8_t, 1-byte unsigned integer type */
const GMT_VIA_SHORT = 300        # int16_t, 2-byte signed integer type */
const GMT_VIA_USHORT = 400       # uint16_t, 2-byte unsigned integer type */
const GMT_VIA_INT = 500          # int32_t, 4-byte signed integer type */
const GMT_VIA_UINT = 600         # uint32_t, 4-byte unsigned integer type */
const GMT_VIA_LONG = 700         # int64_t, 8-byte signed integer type */
const GMT_VIA_ULONG = 800        # uint64_t, 8-byte unsigned integer type */
const GMT_VIA_FLOAT = 900        # 4-byte data float type */
const GMT_VIA_DOUBLE = 1000
# end enum GMT_enum_type
# begin enum GMT_enum_opt
const GMT_OPT_INFILE = 60
# end enum GMT_enum_opt

# begin enum GMT_enum_method
const GMT_IS_OUTPUT = 1024
# end enum GMT_enum_method

# begin enum GMT_enum_via
const GMT_VIA_NONE = 0
const GMT_VIA_MODULE_INPUT = 64
const GMT_VIA_VECTOR = 128
const GMT_VIA_MATRIX = 256
# end enum GMT_enum_via

# GMT_enum_container
const GMT_CONTAINER_AND_DATA = 0    # Create|Read|write both container and the data array
const GMT_CONTAINER_ONLY     = 1    # Create|read|write the container but no data array
const GMT_DATA_ONLY          = 2    # Create|Read|write the container's array only
const GMT_WITH_STRINGS       = 32   # Allocate string array also [DATASET, MATRIX, VECTOR only]
const GMT_NO_STRINGS         = 0 

# GMT_enum_read
const GMT_READ_NORMAL = 0	# Normal read mode [Default]
const GMT_READ_DATA   = 1	# Read ASCII data record and return double array
const GMT_READ_TEXT   = 2	# Read ASCII data record and return text string
const GMT_READ_MIXED  = 3   # Read ASCII data record and return double array but tolerate conversion errors
const GMT_READ_FILEBREAK = 4

# begin enum GMT_enum_family
const GMT_IS_DATASET = 0
const GMT_IS_GRID = 1
const GMT_IS_IMAGE = 2
const GMT_IS_CPT = 3				# To be removed whem >= GMT5.3 only
const GMT_IS_PALETTE = 3
const GMT_IS_POSTSCRIPT = 4
const GMT_IS_TEXTSET = 5
const GMT_IS_MATRIX = 6 - (GMTver >= 6)		# FCK, I hate this
const GMT_IS_VECTOR = 7 - (GMTver >= 6)
# begin enum GMT_enum_comment
const GMT_COMMENT_IS_TEXT = 0
# end enum GMT_enum_comment
# begin enum GMT_api_err_enum
const GMT_NOTSET = -1
const GMT_NOERROR = 0
# end enum GMT_api_err_enum
const GMT_SYNOPSIS = 1
const GMT_OPT_USAGE = Int('?')
# begin enum GMT_module_enum
const GMT_MODULE_USAGE	  = -6
const GMT_MODULE_SYNOPSIS = -5
const GMT_MODULE_LIST     = -4
const GMT_MODULE_EXIST    = -3
const GMT_MODULE_PURPOSE  = -2
const GMT_MODULE_OPT      = -1
const GMT_MODULE_CMD      = 0
# end enum GMT_module_enum
# begin enum GMT_io_enum
const GMT_IN = 0
const GMT_OUT = 1
const GMT_ERR = 2
# end enum GMT_io_enum
# begin enum GMT_enum_dimensions
const GMT_X = 0
const GMT_Y = 1
const GMT_Z = 2
# end enum GMT_enum_dimensions

const GMT_ALLOC_EXTERNALLY = 0    # Allocated outside of GMT: We cannot reallocate or free this memory
const GMT_ALLOC_INTERNALLY = 1    # Allocated by GMT: We may reallocate as needed and free when no longer needed
# begin enum GMT_enum_write
const GMT_STRICT_CONVERSION = 1024
const GMT_LAX_CONVERSION = 2048
# end enum GMT_enum_write
# begin enum GMT_enum_verbose
const GMT_MSG_QUIET = 0
const GMT_MSG_NORMAL = 1
const GMT_MSG_TICTOC = 2
const GMT_MSG_COMPAT = 3
const GMT_MSG_VERBOSE = 4
const GMT_MSG_LONG_VERBOSE = 5
const GMT_MSG_DEBUG = 6
# end enum GMT_enum_verbose
# begin enum GMT_enum_reg
const GMT_GRID_NODE_REG = 0
const GMT_GRID_PIXEL_REG = 1
# end enum GMT_enum_reg
# begin enum GMT_enum_gridindex
const GMT_XLO = 0
const GMT_XHI = 1
const GMT_YLO = 2
const GMT_YHI = 3
const GMT_ZLO = 4
const GMT_ZHI = 5
# end enum GMT_enum_gridindex
# begin enum GMT_enum_dimindex
const GMT_TBL = 0
const GMT_SEG = 1
const GMT_ROW = 2
const GMT_COL = 3
# end enum GMT_enum_dimindex

# begin enum GMT_enum_gridio
const GMT_GRID_ALL = 0
# end enum GMT_enum_gridio

const DOUBLE_CLASS = 1
const SINGLE_CLASS = 2
const INT64_CLASS  = 3
const UINT64_CLASS = 4
const INT32_CLASS  = 5
const UINT32_CLASS = 6
const INT16_CLASS  = 7
const UINT16_CLASS = 8
const INT8_CLASS   = 9
const UINT8_CLASS  = 10

# begin enum GMT_enum_fmt
if (GMTver < 6.0)
	const GMT_IS_ROW_FORMAT = 0
	const GMT_IS_COL_FORMAT = 1
else
	const GMT_IS_ROW_FORMAT = 1
	const GMT_IS_COL_FORMAT = 2
end
# end enum GMT_enum_fmt

# begin enum GMT_enum_geometry
const GMT_IS_POINT = 1
const GMT_IS_LINE = 2
const GMT_IS_POLY = 4
const GMT_IS_PLP = 7
const GMT_IS_SURFACE = 8
const GMT_IS_NONE = 16
# end enum GMT_enum_geometry

# begin enum GMT_enum_color
const GMT_RGB = 0
const GMT_CMYK = 1
const GMT_HSV = 2
# end enum GMT_enum_color

# GMT_enum_cptflags
const GMT_CPT_NO_BNF     = 1
const GMT_CPT_EXTEND_BNF = 2
const GMT_CPT_HINGED     = 4
const GMT_CPT_TIME       = 8

struct GMT_OPTION			# Structure for a single GMT command option
	option::UInt8			# 1-char command line -<option> (e.g. D in -D) identifying the option (* if file)
	arg::Cstring			# If not NULL, contains the argument for this option
	next::Ptr{GMT_OPTION}
	previous::Ptr{GMT_OPTION}
end

mutable struct GMT_PEN		# Structure to hold pen attributes
	width::Cdouble			# In points
	offset::Cdouble			# In points
	rgb::NTuple{4,Cdouble}	# RGB color of pen + Transparency 0-1 [0 = opaque] */
	style::NTuple{128,UInt8}
	# For line modifications
	mode::UInt32			# Line-type: PSL_LINEAR [0; default] or PSL_BEZIER [1]
	cptmode::UInt32		# How a cpt affects pens and fills: 0-none, 1=use CPT for line, 2 = use CPT for fill, 3 = both
	#end::NTuple{2,GMT_LINE_END}
	end_::NTuple{2,Ptr{Cvoid}}		# This is a dangereous thing. If accessed, will crash Julia
	GMT_PEN(width, offset, rgb, style, mode, cptmode, end_) = new(width, offset, rgb, style, mode, cptmode, end_)
	GMT_PEN() = new(0.0, 0.0, (0.0, 0.0, 0.0, 0.0), map(UInt8, (repeat('\0', 128)...,)), 0, 0, (pointer([0]), pointer([0])))
end

mutable struct GMT_GRID_HEADER_v6
	n_columns::UInt32
	n_rows::UInt32
	registration::UInt32
	wesn::NTuple{4,Cdouble}
	z_min::Cdouble
	z_max::Cdouble
	inc::NTuple{2,Cdouble}
	z_scale_factor::Cdouble
	z_add_offset::Cdouble
	x_unit::NTuple{80,UInt8}
	y_unit::NTuple{80,UInt8}
	z_unit::NTuple{80,UInt8}
	title::NTuple{80,UInt8}
	command::NTuple{320,UInt8}
	remark::NTuple{160,UInt8}
	# Items not stored in the data file for grids but explicitly used in macros computing node numbers
	nm::Csize_t 			# Number of data items in this grid (n_columns * n_rows) [padding is excluded]
	size::Csize_t 			# Actual number of items required to hold this grid (= mx * my)
	bits::UInt32
	complex_mode::UInt32
	_type::UInt32
	n_bands::UInt32
	mx::UInt32 				# Actual dimensions of the grid in memory, allowing for the padding
	my::UInt32
	pad::NTuple{4,UInt32}
	mem_layout::NTuple{4,UInt8}
	nan_value::Cfloat
	xy_off::Cdouble
	ProjRefPROJ4::Ptr{UInt8}
	ProjRefWKT::Ptr{UInt8}
	ProjRefEPSG::Cint
	hidden::Ptr{Cvoid}		# Lower-level information for GMT use only
end

mutable struct GMT_GRID_HEADER_v5
	n_columns::UInt32
	n_rows::UInt32
	registration::UInt32
	wesn::NTuple{4,Cdouble}
	z_min::Cdouble
	z_max::Cdouble
	inc::NTuple{2,Cdouble}
	z_scale_factor::Cdouble
	z_add_offset::Cdouble
	x_unit::NTuple{80,UInt8}
	y_unit::NTuple{80,UInt8}
	z_unit::NTuple{80,UInt8}
	title::NTuple{80,UInt8}
	command::NTuple{320,UInt8}
	remark::NTuple{160,UInt8}
	# Variables "hidden" from the API. This section is flexible and considered private
	_type::UInt32
	bits::UInt32
	complex_mode::UInt32
	mx::UInt32 				# Actual dimensions of the grid in memory, allowing for the padding
	my::UInt32
	nm::Csize_t 			# Number of data items in this grid (n_columns * n_rows) [padding is excluded]
	size::Csize_t 			# Actual number of items required to hold this grid (= mx * my)
	n_alloc::Csize_t
	trendmode::UInt32
	arrangement::UInt32
	n_bands::UInt32
	pad::NTuple{4,UInt32}
	BC::NTuple{4,UInt32}
	grdtype::UInt32
	reset_pad::UInt32
	name::NTuple{256,UInt8}
	varname::NTuple{80,UInt8}
	ProjRefPROJ4::Ptr{UInt8}
	ProjRefWKT::Ptr{UInt8}
	row_order::Cint
	z_id::Cint
	ncid::Cint
	xy_dim::NTuple{2,Cint}
	t_index::NTuple{3,Csize_t}
	data_offset::Csize_t
	stride::UInt32
	nan_value::Cfloat
	xy_off::Cdouble
	r_inc::NTuple{2,Cdouble}
	flags::NTuple{4,UInt8}
	pocket::Ptr{UInt8}
	mem_layout::NTuple{4,UInt8}
	bcr_threshold::Cdouble
	has_NaNs::UInt32
	bcr_interpolant::UInt32
	bcr_n::UInt32
	nxp::UInt32
	nyp::UInt32
	no_BC::UInt32
	gn::UInt32
	gs::UInt32
	is_netcdf4::UInt32
	z_chunksize::NTuple{2,Csize_t}
	z_shuffle::UInt32
	z_deflate_level::UInt32
	z_scale_autoadust::UInt32
	z_offset_autoadust::UInt32
	xy_adjust::NTuple{2,UInt32}
	xy_mode::NTuple{2,UInt32}
	xy_unit::NTuple{2,UInt32}
	xy_unit_to_meter::NTuple{2,Cdouble}
	index_function::Ptr{Cvoid}
end

if (GMTver < 6.0)
	const GMT_GRID_HEADER = GMT_GRID_HEADER_v5
else
	const GMT_GRID_HEADER = GMT_GRID_HEADER_v6
end

mutable struct GMT_GRID_v5
	header::Ptr{GMT_GRID_HEADER}
	data::Ptr{Cfloat}
	id::UInt32
	alloc_level::UInt32
	alloc_mode::UInt32
	x::Ptr{Cdouble}
	y::Ptr{Cdouble}
	extra::Ptr{Cvoid}
end

mutable struct GMT_GRID_v6
	header::Ptr{GMT_GRID_HEADER}
	data::Ptr{Cfloat}
	x::Ptr{Cdouble}
	y::Ptr{Cdouble}
	hidden::Ptr{Cvoid}
end

if (GMTver < 6.0)
	const GMT_GRID = GMT_GRID_v5
else
	const GMT_GRID = GMT_GRID_v6
end

if (GMTver < 6.0)
	struct GMT_OGR
		geometry::UInt32
		n_aspatial::UInt32
		region::Ptr{UInt8}
		proj::NTuple{4,Ptr{UInt8}}
		_type::Ptr{UInt32}
		name::Ptr{Ptr{UInt8}}
		pol_mode::UInt32
		tvalue::Ptr{Ptr{UInt8}}
		dvalue::Ptr{Cdouble}
	end
	struct GMT_OGR_SEG
		pol_mode::UInt32
		n_aspatial::UInt32
		tvalue::Ptr{Ptr{UInt8}}
		dvalue::Ptr{Cdouble}
	end

	mutable struct GMT_DATASEGMENT
		n_rows::UInt64
		n_columns::UInt64
		min::Ptr{Cdouble}
		max::Ptr{Cdouble}
		data::Ptr{Ptr{Cdouble}}
		label::Ptr{UInt8}
		header::Ptr{UInt8}
		text::Ptr{Ptr{UInt8}}
		mode::UInt32
		pol_mode::UInt32
		id::UInt64
		n_alloc::Csize_t
		range::Cint
		pole::Cint
		dist::Cdouble
		lat_limit::Cdouble
		ogr::Ptr{GMT_OGR_SEG}
		next::Ptr{GMT_DATASEGMENT}
		alloc_mode::UInt32
		file::NTuple{2,Ptr{UInt8}}
	end

	mutable struct GMT_DATATABLE
		n_headers::UInt32
		n_columns::UInt64
		n_segments::UInt64
		n_records::UInt64
		min::Ptr{Cdouble}
		max::Ptr{Cdouble}
		header::Ptr{Ptr{UInt8}}
		segment::Ptr{Ptr{GMT_DATASEGMENT}}
		id::UInt64
		n_alloc::Csize_t
		mode::UInt32
		ogr::Ptr{GMT_OGR}
		file::NTuple{2,Ptr{UInt8}}
	end

	mutable struct GMT_DATASET
		n_tables::UInt64
		n_columns::UInt64
		n_segments::UInt64
		n_records::UInt64
		min::Ptr{Cdouble}
		max::Ptr{Cdouble}
		table::Ptr{Ptr{GMT_DATATABLE}}
		id::UInt64
		n_alloc::Csize_t
		dim::NTuple{4,UInt64}
		geometry::UInt32
		alloc_level::UInt32
		io_mode::UInt32
		alloc_mode::UInt32
		file::NTuple{2,Ptr{UInt8}}
	end

else			# GMT6

	mutable struct GMT_DATASEGMENT
		n_rows::UInt64
		n_columns::UInt64
		min::Ptr{Cdouble}
		max::Ptr{Cdouble}
		data::Ptr{Ptr{Cdouble}}
		label::Ptr{UInt8}
		header::Ptr{UInt8}
		text::Ptr{Ptr{UInt8}}
		hidden::Ptr{Cvoid}
	end

	mutable struct GMT_DATATABLE
		n_headers::UInt32
		n_columns::UInt64
		n_segments::UInt64
		n_records::UInt64
		min::Ptr{Cdouble}
		max::Ptr{Cdouble}
		header::Ptr{Ptr{UInt8}}
		segment::Ptr{Ptr{GMT_DATASEGMENT}}
		hidden::Ptr{Cvoid}
	end

	mutable struct GMT_DATASET
		n_tables::UInt64
		n_columns::UInt64
		n_segments::UInt64
		n_records::UInt64
		min::Ptr{Cdouble}
		max::Ptr{Cdouble}
		table::Ptr{Ptr{GMT_DATATABLE}}
		type_::UInt32
		geometry::UInt32
		ProjRefPROJ4::Ptr{UInt8}
		ProjRefWKT::Ptr{UInt8}
		ProjRefEPSG::Cint
		hidden::Ptr{Cvoid}
	end
end

mutable struct GMT_TEXTSEGMENT
	n_rows::UInt64
	data::Ptr{Ptr{UInt8}}
	label::Ptr{UInt8}
	header::Ptr{UInt8}
	id::UInt64
	mode::UInt32
	n_alloc::Csize_t
	file::NTuple{2,Ptr{UInt8}}
	tvalue::Ptr{Ptr{UInt8}}
end
mutable struct GMT_TEXTTABLE
	n_headers::UInt32
	n_segments::UInt64
	n_records::UInt64
	header::Ptr{Ptr{UInt8}}
	segment::Ptr{Ptr{GMT_TEXTSEGMENT}}
	id::UInt64
	n_alloc::Csize_t
	mode::UInt32
	file::NTuple{2,Ptr{UInt8}}
end
mutable struct GMT_TEXTSET
	n_tables::UInt64
	n_segments::UInt64
	n_records::UInt64
	table::Ptr{Ptr{GMT_TEXTTABLE}}
	id::UInt64
	n_alloc::Csize_t
	geometry::UInt32
	alloc_level::UInt32
	io_mode::UInt32
	alloc_mode::UInt32
	file::NTuple{2,Ptr{UInt8}}
end
struct GMT_FILL
	rgb::NTuple{4,Cdouble}
	f_rgb::NTuple{4,Cdouble}
	b_rgb::NTuple{4,Cdouble}
	use_pattern::Bool
	pattern_no::Int32
	dpi::UInt32
	pattern::NTuple{256,UInt8}		# was char pattern[GMT_BUFSIZ];
end
if (GMTver < 6.0)
	struct GMT_LUT
		z_low::Cdouble
		z_high::Cdouble
		i_dz::Cdouble
		rgb_low::NTuple{4,Cdouble}
		rgb_high::NTuple{4,Cdouble}
		rgb_diff::NTuple{4,Cdouble}
		hsv_low::NTuple{4,Cdouble}
		hsv_high::NTuple{4,Cdouble}
		hsv_diff::NTuple{4,Cdouble}
		annot::UInt32
		skip::UInt32
		fill::Ptr{GMT_FILL}
		label::Ptr{UInt8}
	end
else
	struct GMT_LUT
		z_low::Cdouble
		z_high::Cdouble
		i_dz::Cdouble
		rgb_low::NTuple{4,Cdouble}
		rgb_high::NTuple{4,Cdouble}
		rgb_diff::NTuple{4,Cdouble}
		hsv_low::NTuple{4,Cdouble}
		hsv_high::NTuple{4,Cdouble}
		hsv_diff::NTuple{4,Cdouble}
		annot::UInt32
		skip::UInt32
		fill::Ptr{GMT_FILL}
		label::Ptr{UInt8}
		key::Ptr{UInt8}
	end
end
struct GMT_BFN
	rgb::NTuple{4,Cdouble}
	hsv::NTuple{4,Cdouble}
	skip::UInt32
	fill::Ptr{GMT_FILL}
end
mutable struct GMT_PALETTE_v5
	n_headers::UInt32
	n_colors::UInt32
	mode::UInt32
	data::Ptr{GMT_LUT}
	bfn::NTuple{3,GMT_BFN}
	header::Ptr{Ptr{UInt8}}
	id::UInt64
	alloc_mode::UInt32
	alloc_level::UInt32
	auto_scale::UInt32
	model::UInt32
	is_wrapping::UInt32
	is_gray::UInt32
	is_bw::UInt32
	is_continuous::UInt32
	has_pattern::UInt32
	has_hinge::UInt32
	has_range::UInt32
	skip::UInt32
	categorical::UInt32
	z_adjust::NTuple{2,UInt32}
	z_mode::NTuple{2,UInt32}
	z_unit::NTuple{2,UInt32}
	z_unit_to_meter::NTuple{2,Cdouble}
	minmax::NTuple{2,Cdouble}
	hinge::Cdouble
	wrap_length::Cdouble
end
mutable struct GMT_PALETTE_v6
	data::Ptr{GMT_LUT}
	bfn::NTuple{3,GMT_BFN}
	n_headers::UInt32
	n_colors::UInt32
	mode::UInt32
	model::UInt32
	is_wrapping::UInt32
	is_gray::UInt32
	is_bw::UInt32
	is_continuous::UInt32
	has_pattern::UInt32
	has_hinge::UInt32
	has_range::UInt32
	categorical::UInt32
	minmax::NTuple{2,Cdouble}
	hinge::Cdouble
	wrap_length::Cdouble
	header::Ptr{Ptr{UInt8}}
	hidden::Ptr{Cvoid}
end

if (GMTver < 6.0)
	const GMT_PALETTE = GMT_PALETTE_v5
else
	const GMT_PALETTE = GMT_PALETTE_v6
end

mutable struct GMT_IMAGE_v5
	_type::UInt32
	colormap::Ptr{Cint}
	n_indexed_colors::Cint
	header::Ptr{GMT_GRID_HEADER}
	data::Ptr{Cuchar}
	alpha::Ptr{Cuchar}
	id::UInt64
	alloc_level::UInt32
	alloc_mode::UInt32
	color_interp::Ptr{UInt8}
	x::Ptr{Cdouble}
	y::Ptr{Cdouble}
end

mutable struct GMT_IMAGE_v6
	_type::UInt32
	colormap::Ptr{Cint}
	n_indexed_colors::Cint
	header::Ptr{GMT_GRID_HEADER}
	data::Ptr{Cuchar}
	alpha::Ptr{Cuchar}
	color_interp::Ptr{UInt8}
	x::Ptr{Cdouble}
	y::Ptr{Cdouble}
	hidden::Ptr{Cvoid}
end

if (GMTver < 6.0)
	const GMT_IMAGE = GMT_IMAGE_v5
else
	const GMT_IMAGE = GMT_IMAGE_v6
end

mutable struct GMT_POSTSCRIPT_v5
	n_alloc::Csize_t
	n_bytes::Csize_t
	mode::UInt32
	n_headers::UInt32
	data::Ptr{UInt8}
	header::Ptr{Ptr{UInt8}}
	id::UInt64
	alloc_level::UInt32
	alloc_mode::UInt32
end
mutable struct GMT_POSTSCRIPT_v6
	n_bytes::Csize_t
	mode::UInt32
	n_headers::UInt32
	data::Ptr{UInt8}
	header::Ptr{Ptr{UInt8}}
	hidden::Ptr{Cvoid}
end

if (GMTver < 6.0)
	const GMT_POSTSCRIPT = GMT_POSTSCRIPT_v5
else
	const GMT_POSTSCRIPT = GMT_POSTSCRIPT_v6
end

struct GMT_UNIVECTOR
	uc1::Ptr{UInt8}
	sc1::Ptr{Int8}
	ui2::Ptr{UInt16}
	si2::Ptr{Int16}
	ui4::Ptr{UInt32}
	si4::Ptr{Int32}
	ui8::Ptr{UInt64}
	si8::Ptr{Int64}
	f4::Ptr{Float32}
	f8::Ptr{Float64}
end

struct GMT_VECTOR_v6
	n_columns::UInt64
	n_rows::UInt64
	n_headers::UInt32
	registration::UInt32
	_type::Ptr{UInt32}
	range::NTuple{2,Cdouble}
	#data::Ptr{GMT_UNIVECTOR}
	data::Ptr{Ptr{Cvoid}}
	text::Ptr{Ptr{UInt8}};			# Pointer to optional array of strings [NULL]
	command::NTuple{320,UInt8}
	remark::NTuple{160,UInt8}
	header::Ptr{Ptr{UInt8}};		# Array with all Vector header records, if any)
	ProjRefPROJ4::Ptr{UInt8}
	ProjRefWKT::Ptr{UInt8}
	ProjRefEPSG::Cint
	hidden::Ptr{Cvoid}
end

struct GMT_VECTOR_v5
	n_columns::UInt64
	n_rows::UInt64
	registration::UInt32
	_type::Ptr{UInt32}
	#data::Ptr{GMT_UNIVECTOR}
	data::Ptr{Ptr{Cvoid}}
	range::NTuple{2,Cdouble}
	command::NTuple{320,UInt8}
	remark::NTuple{160,UInt8}
	id::UInt64
	alloc_level::UInt32
	alloc_mode::UInt32
end

if (GMTver < 6.0)
	const GMT_VECTOR = GMT_VECTOR_v5
else
	const GMT_VECTOR = GMT_VECTOR_v6
end

mutable struct GMT_MATRIX_v6
	n_rows::UInt64
	n_columns::UInt64
	n_layers::UInt64
	n_headers::UInt32
	shape::UInt32
	registration::UInt32
	dim::Csize_t
	size::Csize_t
	_type::UInt32
	range::NTuple{6,Cdouble}
	inc::NTuple{3,Cdouble}
#	data::GMT_UNIVECTOR
	data::Ptr{Cvoid}
	text::Ptr{Ptr{UInt8}}
	command::NTuple{320,UInt8}
	remark::NTuple{160,UInt8}
	header::Ptr{Ptr{UInt8}};		# Array with all Matrix header records, if any)
	ProjRefPROJ4::Ptr{UInt8}
	ProjRefWKT::Ptr{UInt8}
	ProjRefEPSG::Cint
	hidden::Ptr{Cvoid}
end

mutable struct GMT_MATRIX_v5
	n_rows::UInt64
	n_columns::UInt64
	n_layers::UInt64
	shape::UInt32
	registration::UInt32
	dim::Csize_t
	size::Csize_t
	_type::UInt32
	range::NTuple{6,Cdouble}
#	data::GMT_UNIVECTOR
	data::Ptr{Cvoid}
	command::NTuple{320,UInt8}
	remark::NTuple{160,UInt8}
	id::UInt64
	alloc_level::UInt32
	alloc_mode::UInt32
end

if (GMTver < 6.0)
	const GMT_MATRIX = GMT_MATRIX_v5
else
	const GMT_MATRIX = GMT_MATRIX_v6
end

mutable struct GMT_RESOURCE
	family::UInt32          # GMT data family, i.e., GMT_IS_DATASET, GMT_IS_GRID, etc.
	geometry::UInt32        # One of the recognized GMT geometries
	direction::UInt32       # Either GMT_IN or GMT_OUT
	option::Ptr{GMT_OPTION} # Pointer to the corresponding module option
	name::NTuple{16,UInt8}  # Object ID returned by GMT_Register_IO
	pos::Cint               # Corresponding index into external object in|out arrays
	mode::Cint              # Either primary (0) or secondary (1) resource
	object::Ptr{Cvoid}      # Pointer to the actual GMT object
end


struct GMTAPI_DATA_OBJECT
	# Information for each input or output data entity, including information
	# needed while reading/writing from a table (file or array)
	rec::UInt64                 # Current rec to read [GMT_DATASET and GMT_TEXTSET to/from MATRIX/VECTOR only]
	n_rows::UInt64              # Number or rows in this array [GMT_DATASET and GMT_TEXTSET to/from MATRIX/VETOR only]
	n_columns::UInt64			# Number of columns to process in this dataset [GMT_DATASET only]
	n_expected_fields::UInt64	# Number of expected columns for this dataset [GMT_DATASET only]
	n_alloc::Csize_t			# Number of items allocated so far if writing to memory
	ID::UInt32					# Unique identifier which is >= 0
	alloc_level::UInt32			# Nested module level when object was allocated
	status::UInt32				# 0 when first registered, 1 after reading/writing has started, 2 when finished
	selected::Cint				# true if requested by current module, false otherwise
	close_file::Cint			# true if we opened source as a file and thus need to close it when done
	region::Cint				# true if wesn was passed, false otherwise
	no_longer_owner::Cint		# true if the data pointed to by the object was passed on to another object
	messenger::Cint				# true for output objects passed from the outside to receive data from GMT. If true we destroy data pointer before writing
	alloc_mode::UInt32			# GMT_ALLOCATED_{BY_GMT|EXTERNALLY}
	direction::UInt32			# GMT_IN or GMT_OUT
	family::UInt32				# One of GMT_IS_{DATASET|TEXTSET|CPT|IMAGE|GRID|MATRIX|VECTOR|COORD}
	actual_family::UInt32		# May be GMT_IS_MATRIX|VECTOR when one of the others are created via those
	method::UInt32              # One of GMT_IS_{FILE,STREAM,FDESC,DUPLICATE,REFERENCE} or sum with enum GMT_enum_via (GMT_VIA_{NONE,VECTOR,MATRIX,OUTPUT}); using unsigned type because sum exceeds enum GMT_enum_method
	geometry::UInt32			# One of GMT_IS_{POINT|LINE|POLY|PLP|SURFACE|NONE}
	wesn::NTuple{4,Cdouble}	# Grid domain limits
	resource::Ptr{Cvoid}			# Points to registered filename, memory location, etc., where data can be obtained from with GMT_Get_Data.
	data::Ptr{Cvoid}				# Points to GMT object that was read from a resource
	#FILE *fp;					# Pointer to source/destination stream [For rec-by-rec procession, NULL if memory location]
	fp::Ptr{Cvoid}				# Pointer to source/destination stream [For rec-by-rec procession, NULL if memory location]
	filename::Ptr{UInt8}		# Filename, stream, of file handle (otherwise NULL)
	#Cvoid *(*import) (struct GMT_CTRL *, FILE *, uint64_t *, int *);	# Pointer to input function (for DATASET/TEXTSET only)
	ifun::Ptr{Cvoid} 			# Pointer to input function (for DATASET/TEXTSET only)
	# Start of temporary variables for API debug - They are only set when building GMT with /DEBUG
	G::Ptr{Cvoid}				# struct GMT_GRID *G;
	D::Ptr{Cvoid}				# struct GMT_DATASET *D;
	T::Ptr{Cvoid}				# struct GMT_TEXTSET *T;
	C::Ptr{Cvoid}				# struct GMT_PALETTE *C;
	M::Ptr{Cvoid}				# struct GMT_MATRIX *M;
	V::Ptr{Cvoid}				# struct GMT_VECTOR *V;
	I::Ptr{Cvoid}				# struct GMT_IMAGE *I;
end

struct Gmt_libinfo
	name::Ptr{UInt8}	# Library tag name [without leading "lib" and extension], e.g. "gmt", "gmtsuppl" */
	path::Ptr{UInt8}	# Full path to library as given in GMT_CUSTOM_LIBS */
	skip::Ptr{Bool}		# true if we tried to open it and it was not available the first time */
	handle::Ptr{Cvoid}	# Handle to the shared library, returned by dlopen or dlopen_special */
end

mutable struct OGR_FEATURES
	n_rows::Cint
	n_cols::Cint
	n_layers::Cint
	n_filled::Cint
	is3D::Cint
	np::Cuint
	att_number::Cint
	name::Ptr{UInt8} 
	wkt::Ptr{UInt8} 
	proj4::Ptr{UInt8} 
	type::Ptr{UInt8}            # Geometry type. E.g. Point, Polygon or LineString
	att_names::Ptr{Ptr{UInt8}}  # Names of the attributes of a Feature
	att_values::Ptr{Ptr{UInt8}} # Values of the attributes of a Feature as strings
	att_types::Ptr{Cint}
	islands::Ptr{Cint}
	BoundingBox::NTuple{6,Cdouble}
	BBgeom::Ptr{Cdouble};       # Not currently assigned (would be the BoundingBox of each individual geometry)
	x::Ptr{Cdouble}
	y::Ptr{Cdouble}
	z::Ptr{Cdouble}
end

#=
mutable struct GMTAPI_CTRL
	# Master controller which holds all GMT API related information at run-time for a single session.
	# Users can run several GMT sessions concurrently; each session requires its own structure.
	# Use GMTAPI_Create_Session to initialize a new session and GMTAPI_Destroy_Session to end it.

	current_rec::NTuple{2,UInt64}	# Current record number >= 0 in the combined virtual dataset (in and out)
	n_objects::UInt32			# Number of currently active input and output data objects
	unique_ID::UInt32			# Used to create unique IDs for duration of session
	session_ID::UInt32			# ID of this session
	unique_var_ID::UInt32		# Used to create unique object IDs (grid,dataset, etc) for duration of session
	current_item::NTuple{2,Cint}	# Array number of current dataset being processed (in and out)
	pad::UInt32					# Session default for number of rows/cols padding for grids [2]
	external::UInt32			# 1 if called via external API (MATLAB, Python) [0]
	runmode::UInt32				# nonzero for GMT modern runmode [0 = classic]
	shape::Cint                 # GMT_IS_COL_FORMAT (1) if column-major (MATLAB, Fortran), GMT_IS_ROW_FORMAT (0) if row-major
	leave_grid_scaled::UInt32	# 1 if we dont want to unpack a grid after we packed it for writing [0]
	n_cores::UInt32             # Number of available cores on this system
	verbose::UInt32             # Used until GMT is set up
	registered::NTuple{2,Bool}	# true if at least one source/destination has been registered (in and out)
	io_enabled::NTuple{2,Bool}	# true if access has been allowed (in and out)
	module_input::Bool          # true when we are about to read inputs to the module (command line) */
	n_objects_alloc::Csize_t	# Allocation counter for data objects
	error::Int32				# Error code from latest API call [GMT_OK]
	last_error::Int32			# Error code from previous API call [GMT_OK]
	shelf::Int32				# Place to pass hidden values within API
	io_mode::NTuple{2,UInt32}	# 1 if access as set, 0 if record-by-record
	PPID::Cint                  # The Process ID of the parent (e.g., shell) or the external caller
	#GMT::Ptr{GMT_CTRL}			# Key structure with low-level GMT internal parameters
	GMT::Ptr{Cvoid}				# Maybe one day. Till than just keep it as Cvoid
	object::Ptr{Ptr{GMTAPI_DATA_OBJECT}}	# List of registered data objects
	session_tag::Ptr{UInt8}		# Name tag for this session (or NULL)
	tmp_dir::Ptr{UInt8}         # System tmp_dir (NULL if not found)
	gwf_dir::Ptr{UInt8}         # GMT WorkFlow dir (NULL if not running in modern mode)
	internal::Bool				# true if session was initiated by gmt.c
	deep_debug::Bool			# temporary for debugging
	#int (*print_func) (FILE *, const char *);	# Pointer to fprintf function (may be reset by external APIs like MEX)
	pf::Ptr{Cvoid}				# Don't know what to put here, so ley it be *void
	do_not_exit::UInt32			# 0 by default, mieaning it is OK to call exit  (may be reset by external APIs like MEX to call return instead)
	lib::Ptr{Gmt_libinfo}		# List of shared libs to consider
	n_shared_libs::UInt32		# How many in lib
end
=#