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
# begin enum GMT_enum_family
const GMT_IS_DATASET = 0
const GMT_IS_GRID = 1
const GMT_IS_IMAGE = 2
const GMT_IS_CPT = 3				# To be removed whem >= GMT5.3 only
const GMT_IS_PALETTE = 3
const GMT_IS_POSTSCRIPT = 4
const GMT_IS_TEXTSET = 5
const GMT_IS_MATRIX = 6
const GMT_IS_VECTOR = 7
# begin enum GMT_enum_comment
const GMT_COMMENT_IS_TEXT = 0
# end enum GMT_enum_comment
# begin enum GMT_api_err_enum
const GMT_NOTSET = -1
const GMT_NOERROR = 0
# end enum GMT_api_err_enum
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
const GMT_IS_ROW_FORMAT = 0
const GMT_IS_COL_FORMAT = 1
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

immutable GMT_OPTION			# Structure for a single GMT command option
	option::UInt8				# 1-char command line -<option> (e.g. D in -D) identifying the option (* if file)
	arg::Ptr{UInt8}				# If not NULL, contains the argument for this option
	next::Ptr{GMT_OPTION}
	previous::Ptr{GMT_OPTION}
end

type GMT_GRID_HEADER_v6
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
	orig_datatype::UInt32
	z_chunksize::NTuple{2,Csize_t}
	z_shuffle::UInt32
	z_deflate_level::UInt32
	z_scale_autoadust::UInt32
	z_offset_autoadust::UInt32
	xy_adjust::NTuple{2,UInt32}
	xy_mode::NTuple{2,UInt32}
	xy_unit::NTuple{2,UInt32}
	xy_unit_to_meter::NTuple{2,Cdouble}
	index_function::Ptr{Void}
end

type GMT_GRID_HEADER_v5
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
	index_function::Ptr{Void}
end

if (GMTver >= 6.0)
	const GMT_GRID_HEADER = GMT_GRID_HEADER_v6
else
	const GMT_GRID_HEADER = GMT_GRID_HEADER_v5
end

type GMT_GRID
	header::Ptr{GMT_GRID_HEADER}
	data::Ptr{Cfloat}
	id::UInt32
	alloc_level::UInt32
	alloc_mode::UInt32
	x::Ptr{Cdouble}
	y::Ptr{Cdouble}
	extra::Ptr{Void}
end

immutable GMT_OGR
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
immutable GMT_OGR_SEG
	pol_mode::UInt32
	n_aspatial::UInt32
	tvalue::Ptr{Ptr{UInt8}}
	dvalue::Ptr{Cdouble}
end
type GMT_DATASEGMENT
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
	n_alloc::Cint
	range::Cint
	pole::Cint
	dist::Cdouble
	lat_limit::Cdouble
	ogr::Ptr{GMT_OGR_SEG}
	next::Ptr{GMT_DATASEGMENT}
	alloc_mode::UInt32
	file::NTuple{2,Ptr{UInt8}}
end
type GMT_DATATABLE
	n_headers::UInt32
	n_columns::UInt64
	n_segments::UInt64
	n_records::UInt64
	min::Ptr{Cdouble}
	max::Ptr{Cdouble}
	header::Ptr{Ptr{UInt8}}
	segment::Ptr{Ptr{GMT_DATASEGMENT}}
	id::UInt64
	n_alloc::Cint
	mode::UInt32
	ogr::Ptr{GMT_OGR}
	file::NTuple{2,Ptr{UInt8}}
end
type GMT_DATASET
	n_tables::UInt64
	n_columns::UInt64
	n_segments::UInt64
	n_records::UInt64
	min::Ptr{Cdouble}
	max::Ptr{Cdouble}
	table::Ptr{Ptr{GMT_DATATABLE}}
	id::UInt64
	n_alloc::Cint
	dim::NTuple{4,UInt64}
	geometry::UInt32
	alloc_level::UInt32
	io_mode::UInt32
	alloc_mode::UInt32
	file::NTuple{2,Ptr{UInt8}}
end
type GMT_TEXTSEGMENT
	n_rows::UInt64
	data::Ptr{Ptr{UInt8}}
	label::Ptr{UInt8}
	header::Ptr{UInt8}
	id::UInt64
	mode::UInt32
	n_alloc::Cint
	file::NTuple{2,Ptr{UInt8}}
	tvalue::Ptr{Ptr{UInt8}}
end
type GMT_TEXTTABLE
	n_headers::UInt32
	n_segments::UInt64
	n_records::UInt64
	header::Ptr{Ptr{UInt8}}
	segment::Ptr{Ptr{GMT_TEXTSEGMENT}}
	id::UInt64
	n_alloc::Cint
	mode::UInt32
	file::NTuple{2,Ptr{UInt8}}
end
type GMT_TEXTSET
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
immutable GMT_FILL
	rgb::NTuple{4,Cdouble}
	f_rgb::NTuple{4,Cdouble}
	b_rgb::NTuple{4,Cdouble}
	use_pattern::Bool
	pattern_no::Int32
	dpi::UInt32
	pattern::NTuple{256,UInt8}		# was char pattern[GMT_BUFSIZ];
end
immutable GMT_LUT
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
immutable GMT_BFN
	rgb::NTuple{4,Cdouble}
	hsv::NTuple{4,Cdouble}
	skip::UInt32
	fill::Ptr{GMT_FILL}
end
type GMT_PALETTE
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
type GMT_IMAGE
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
type GMT_POSTSCRIPT
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
immutable GMT_UNIVECTOR
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

immutable GMT_VECTOR_v6
	n_columns::UInt64
	n_rows::UInt64
	registration::UInt32
	_type::Ptr{UInt32}
	range::NTuple{2,Cdouble}
	#data::Ptr{GMT_UNIVECTOR}
	data::Ptr{Ptr{Void}}
	text::Ptr{Ptr{UInt8}};			# Pointer to optional array of strings [NULL] */
	command::NTuple{320,UInt8}
	remark::NTuple{160,UInt8}
	id::UInt64
	alloc_level::UInt32
	alloc_mode::UInt32
end

immutable GMT_VECTOR_v5
	n_columns::UInt64
	n_rows::UInt64
	registration::UInt32
	_type::Ptr{UInt32}
	#data::Ptr{GMT_UNIVECTOR}
	data::Ptr{Ptr{Void}}
	range::NTuple{2,Cdouble}
	command::NTuple{320,UInt8}
	remark::NTuple{160,UInt8}
	id::UInt64
	alloc_level::UInt32
	alloc_mode::UInt32
end

if (GMTver >= 6.0)
	const GMT_VECTOR = GMT_VECTOR_v6
else
	const GMT_VECTOR = GMT_VECTOR_v5
end

type GMT_MATRIX_v6
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
	data::Ptr{Void}
	text::Ptr{Ptr{UInt8}}
	command::NTuple{320,UInt8}
	remark::NTuple{160,UInt8}
	id::UInt64
	alloc_level::UInt32
	alloc_mode::UInt32
end

type GMT_MATRIX_v5
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
	data::Ptr{Void}
	command::NTuple{320,UInt8}
	remark::NTuple{160,UInt8}
	id::UInt64
	alloc_level::UInt32
	alloc_mode::UInt32
end

if (GMTver >= 6.0)
	const GMT_MATRIX = GMT_MATRIX_v6
else
	const GMT_MATRIX = GMT_MATRIX_v5
end

type GMT_RESOURCE
	family::UInt32          # GMT data family, i.e., GMT_IS_DATASET, GMT_IS_GRID, etc.
	geometry::UInt32        # One of the recognized GMT geometries
	direction::UInt32       # Either GMT_IN or GMT_OUT
	option::Ptr{GMT_OPTION} # Pointer to the corresponding module option
	name::NTuple{16,UInt8} # Object ID returned by GMT_Register_IO
	pos::Cint               # Corresponding index into external object in|out arrays
	mode::Cint              # Either primary (0) or secondary (1) resource
	object::Ptr{Void}       # Pointer to the actual GMT object
end


immutable GMTAPI_DATA_OBJECT
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
	resource::Ptr{Void}			# Points to registered filename, memory location, etc., where data can be obtained from with GMT_Get_Data.
	data::Ptr{Void}				# Points to GMT object that was read from a resource
	#FILE *fp;					# Pointer to source/destination stream [For rec-by-rec procession, NULL if memory location]
	fp::Ptr{Void}				# Pointer to source/destination stream [For rec-by-rec procession, NULL if memory location]
	filename::Ptr{UInt8}		# Filename, stream, of file handle (otherwise NULL)
	#void *(*import) (struct GMT_CTRL *, FILE *, uint64_t *, int *);	# Pointer to input function (for DATASET/TEXTSET only)
	ifun::Ptr{Void} 			# Pointer to input function (for DATASET/TEXTSET only)
	# Start of temporary variables for API debug - They are only set when building GMT with /DEBUG
	G::Ptr{Void}				# struct GMT_GRID *G;
	D::Ptr{Void}				# struct GMT_DATASET *D;
	T::Ptr{Void}				# struct GMT_TEXTSET *T;
	C::Ptr{Void}				# struct GMT_PALETTE *C;
	M::Ptr{Void}				# struct GMT_MATRIX *M;
	V::Ptr{Void}				# struct GMT_VECTOR *V;
	I::Ptr{Void}				# struct GMT_IMAGE *I;
end

immutable Gmt_libinfo
	name::Ptr{UInt8}	# Library tag name [without leading "lib" and extension], e.g. "gmt", "gmtsuppl" */
	path::Ptr{UInt8}	# Full path to library as given in GMT_CUSTOM_LIBS */
	skip::Ptr{Bool}		# true if we tried to open it and it was not available the first time */
	handle::Ptr{Void}	# Handle to the shared library, returned by dlopen or dlopen_special */
end

type GMTAPI_CTRL
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
	GMT::Ptr{Void}				# Maybe one day. Till than just keep it as void
	object::Ptr{Ptr{GMTAPI_DATA_OBJECT}}	# List of registered data objects
	session_tag::Ptr{UInt8}		# Name tag for this session (or NULL)
	tmp_dir::Ptr{UInt8}         # System tmp_dir (NULL if not found)
	gwf_dir::Ptr{UInt8}         # GMT WorkFlow dir (NULL if not running in modern mode)
	internal::Bool				# true if session was initiated by gmt.c
	deep_debug::Bool			# temporary for debugging
	#int (*print_func) (FILE *, const char *);	# Pointer to fprintf function (may be reset by external APIs like MEX)
	pf::Ptr{Void}				# Don't know what to put here, so ley it be *void
	do_not_exit::UInt32			# 0 by default, mieaning it is OK to call exit  (may be reset by external APIs like MEX to call return instead)
	lib::Ptr{Gmt_libinfo}		# List of shared libs to consider
	n_shared_libs::UInt32		# How many in lib
end

#=
immutable GMT_CTRL
	# Master structure for a GMT invokation.  All internal settings for GMT is accessed here
	session::GMT_SESSION     # Structure with all values that do not change throughout a session
	init::GMT_INIT           # Structure with all values that do not change in a GMT_func call
	common::GMT_COMMON       # Structure with all the common GMT command settings (-R -J ..)
	current::GMT_CURRENT     # Structure with all the GMT items that can change during execution, such as defaults settings (pens, colors, fonts.. )
	hidden::GMT_INTERNAL     # Internal global variables that are not to be changed directly by users
	PSL::Ptr{PSL_CTRL}       # Pointer to the PSL structure [or NULL]
	parent::Ptr{GMTAPI_CTRL} # Owner of this structure [or NULL]; gives access to the API from functions being passed *GMT only
end

struct GMT_SESSION {
	# These are parameters that is set once at the start of a GMT session and
	# are essentially read-only constants for the duration of the session */
	FILE *std[3];			/* Pointers for standard input, output, and error */
	void *(*input_ascii) (struct GMT_CTRL *, FILE *, uint64_t *, int *);	/* Pointer to function reading ascii tables only */
	int (*output_ascii) (struct GMT_CTRL *, FILE *, uint64_t, double *);	/* Pointer to function writing ascii tables only */
	n_fonts::UInt32				# Total number of fonts returned by GMT_init_fonts */
	n_user_media::UInt32		# Total number of user media returned by gmt_load_user_media */
	min_meminc::Csize_t			# with -DMEMDEBUG, sets min/max memory increments */
	max_meminc::Csize_t
	f_NaN::Float32				# Holds the IEEE NaN for floats */
	d_NaN::Float64				# Holds the IEEE NaN for doubles */
	no_rgb::NTuple{4, Cdouble}	# To hold {-1, -1, -1, 0} when needed */
	double u2u[4][4];		/* u2u is the 4x4 conversion matrix for cm, inch, m, pt */
	char unit_name[4][8];		/* Full name of the 4 units cm, inch, m, pt */
	struct GMT_HASH rgb_hashnode[GMT_N_COLOR_NAMES];/* Used to translate colornames to r/g/b */
	rgb_hashnode_init::Bool		# true once the rgb_hashnode array has been loaded; false otherwise */
	n_shorthands::UInt32		# Length of arrray with shorthand information */
	char *grdformat[GMT_N_GRD_FORMATS];	/* Type and description of grid format */
	int (*readinfo[GMT_N_GRD_FORMATS]) (struct GMT_CTRL *, struct GMT_GRID_HEADER *);	/* Pointers to grid read header functions */
	int (*updateinfo[GMT_N_GRD_FORMATS]) (struct GMT_CTRL *, struct GMT_GRID_HEADER *);	/* Pointers to grid update header functions */
	int (*writeinfo[GMT_N_GRD_FORMATS]) (struct GMT_CTRL *, struct GMT_GRID_HEADER *);	/* Pointers to grid write header functions */
	int (*readgrd[GMT_N_GRD_FORMATS]) (struct GMT_CTRL *, struct GMT_GRID_HEADER *, float *, double *, unsigned int *, unsigned int);	/* Pointers to grid read functions */
	int (*writegrd[GMT_N_GRD_FORMATS]) (struct GMT_CTRL *, struct GMT_GRID_HEADER *, float *, double *, unsigned int *, unsigned int);	/* Pointers to grid read functions */
	int (*fft1d[k_n_fft_algorithms]) (struct GMT_CTRL *, float *, unsigned int, int, unsigned int);	/* Pointers to available 1-D FFT functions (or NULL if not configured) */
	int (*fft2d[k_n_fft_algorithms]) (struct GMT_CTRL *, float *, unsigned int, unsigned int, int, unsigned int);	/* Pointers to available 2-D FFT functions (or NULL if not configured) */
	# This part contains pointers that may point to additional memory outside this struct
	DCWDIR::Ptr{UInt8}				# Path to the DCW directory
	GSHHGDIR::Ptr{UInt8}			# Path to the GSHHG directory
	SHAREDIR::Ptr{UInt8}			# Path to the GMT share directory
	HOMEDIR::Ptr{UInt8}				# Path to the user's home directory
	USERDIR::Ptr{UInt8}				# Path to the user's GMT settings directory
	DATADIR::Ptr{UInt8}				# Path to one or more directories with data sets
	TMPDIR::Ptr{UInt8}				# Path to the directory directory for isolation mode
	CUSTOM_LIBS::Ptr{UInt8}			# Names of one or more comma-separated GMT-compatible shared libraries
	user_media_name::Ptr{Ptr{UInt8}}		# Length of array with custom media dimensions
	font::Ptr{GMT_FONTSPEC}			# Array with font names and height specification
	user_media::Ptr{GMT_MEDIA}		# Array with custom media dimensions
	shorthand::Ptr{GMT_SHORTHAND}	# Array with info about shorthand file extension magic
};

struct GMT_COMMON {
	# Structure with all information given via the common GMT command-line options -R -J ..
	struct synopsis {	# \0 (zero) or ^ */
		bool active;
		bool extended;	# + to also show non-common options */
	} synopsis;
	struct B {	# -B<params> */
		bool active[2];	# 0 = primary annotation, 1 = secondary annotations */
		int mode;	# 5 = GMT 5 syntax, 4 = GMT 4 syntax, 1 = Either, -1 = mix (error), 0 = not set yet */
		char string[2][GMT_LEN256];
	} B;	
	struct API_I {	# -I<xinc>[/<yinc>] grids only, and for API use only */
		bool active;
		double inc[2];
	} API_I;	
	struct J {	# -J<params>
		bool active, zactive;
		unsigned int id;
		double par[6];
		char string[GMT_LEN256];
	} J;		
	struct K {	# -K
		bool active;
	} K;	
	struct O {	# -O
		bool active;
	} O;
	struct P {	# -P
		bool active;
	} P;
	struct R {	# -Rw/e/s/n[/z_min/z_max][r] */
		bool active;
		bool oblique;	# true when -R...r was given (oblique map, probably), else false (map borders are meridians/parallels) */
		double wesn[6];		# Boundaries of west, east, south, north, low-z and hi-z */
		char string[GMT_LEN256];
	} R;
	struct U {	# -U */
		bool active;
		unsigned int just;
		double x, y;
		char *label;		# Content not counted by sizeof (struct)
	} U;
	struct V {	# -V */
		bool active;
	} V;
	struct X {	# -X */
		bool active;
		double off;
		char mode;	# r, a, or c */
	} X;
	struct Y {	# -Y */
		bool active;
		double off;
		char mode;	# r, a, or c */
	} Y;
	struct a {	# -a<col>=<name>[:<type>][,col>=<name>[:<type>], etc][+g<geometry>] */
		bool active;
		unsigned int geometry;
		unsigned int n_aspatial;
		bool clip;		# true if we wish to clip lines/polygons at Dateline [false] */
		bool output;		# true when we wish to build OGR output */
		int col[MAX_ASPATIAL];	# Col id, include negative items such as GMT_IS_T (-5) */
		int ogr[MAX_ASPATIAL];	# Column order, or -1 if not set */
		unsigned int type[MAX_ASPATIAL];
		char *name[MAX_ASPATIAL];
	} a;
	struct b {	# -b[i][o][s|S][d|D][#cols][cvar1/var2/...] */
		bool active[2];		# true if current input/output is in native binary format */
		bool o_delay;		# true if we dont know number of output columns until we have read at least one input record */
		enum GMT_swap_direction swab[2];	# k_swap_in or k_swap_out if current binary input/output must be byte-swapped, else k_swap_none */
		uint64_t ncol[2];		# Number of expected columns of input/output 0 means it will be determined by program
		char type[2];			# Default column type, if set [d for double] */
		char varnames[GMT_BUFSIZ];	# List of variable names to be input/output in netCDF mode [GMT4 COMPATIBILITY ONLY] */
	} b;
	struct c {	# -c */
		bool active;
		unsigned int copies;
	} c;
	struct f {	# -f[i|o]<col>|<colrange>[t|T|g],..
		bool active[2];	# For GMT_IN|OUT
	} f;
	struct g {	# -g[+]x|x|y|Y|d|Y<gap>[unit] 
		bool active;
		unsigned int n_methods;			# How many different criteria to apply
		uint64_t n_col;				# Largest column-number needed to be read */
		bool match_all;			# If true then all specified criteria must be met to be a gap [default is any of them] */
		enum GMT_enum_gaps method[GMT_N_GAP_METHODS];	# How distances are computed for each criteria */
		uint64_t col[GMT_N_GAP_METHODS];	# Which column to use (-1 for x,y distance) */
		double gap[GMT_N_GAP_METHODS];		# The critical distances for each criteria */
		double (*get_dist[GMT_N_GAP_METHODS]) (struct GMT_CTRL *GMT, uint64_t);	# Pointers to functions that compute those distances */
	} g;
	struct h {	# -h[i|o][<nrecs>][+d][+c][+r<remark>][+t<title>] */
		bool active;
		bool add_colnames;
		unsigned int mode;
		unsigned int n_recs;
		char *title;
		char *remark;
		char *colnames;	# Not set by -h but maintained here */
	} h;	
	struct i {	# -i<col>|<colrange>,.. */
		bool active;
		uint64_t n_cols;
	} i;
	struct n {	# -n[b|c|l|n][+a][+b<BC>][+c][+t<threshold>] */
		bool active;
		bool antialias;	# Defaults to true, if supported */
		bool truncate;	# Defaults to false */
		unsigned int interpolant;	# Defaults to BCR_BICUBIC */
		bool bc_set;	# true if +b was parsed */
		char BC[4];		# For BC settings via +bg|n[x|y]|p[x|y] */
		double threshold;	# Defaults to 0.5 */
	} n;
	struct o {	# -o<col>|<colrange>,.. */
		bool active;
		uint64_t n_cols;
	} o;
	struct p {	# -p<az>/<el>[+wlon0/lat0[/z0]][+vx0[cip]/y0[cip]] */
		bool active;
	} p;
	struct r {	# -r */
		bool active;
		unsigned int registration;
	} r;
	struct s {	# -s[r] */
		bool active;
	} s;
	struct t {	# -t<transparency> */
		bool active;
		double value;
	} t;
	struct x {	# -x+a|[-]n */
		bool active;
		int n_threads;
	} x;
	struct colon {	# -:[i|o] */
		bool active;
		bool toggle[2];
	} colon;
};

struct GMT_INIT 	# Holds misc run-time parameters */
	n_custom_symbols::UInt32
	module_name::Ptr{UInt8}			# Name of current module or NULL if not set */
	module_lib::Ptr{UInt8}			# Name of current shared library or NULL if not set */
	# The rest of the struct contains pointers that may point to memory not included by this struct */
	runtime_bindir::Ptr{UInt8}		# Directory that contains the main exe at run-time */
	runtime_libdir::Ptr{UInt8}		# Directory that contains the main shared lib at run-time */
	char *history[GMT_N_UNIQUE];	# The internal gmt.history information */
	struct GMT_CUSTOM_SYMBOL **custom_symbol; # For custom symbol plotting in psxy[z]. */
end

struct GMT_CURRENT {
	# These are internal parameters that need to be passed around between
	# many GMT functions.  These values may change by user interaction.
	struct GMT_DEFAULTS setting;	# Holds all GMT defaults parameters
	struct GMT_IO io;		# Holds all i/o-related parameters
	struct GMT_PROJ proj;		# Holds all projection-related parameters
	struct GMT_MAP map;		# Holds all projection-related parameters
	struct GMT_PLOT plot;		# Holds all plotting-related parameters
	struct GMT_TIME_CONV time;	# Holds all time-related parameters
	struct GMT_POSTSCRIPT ps;		# Hold parameters related to PS setup
	struct GMT_OPTION *options;	# Pointer to current program's options
	struct GMT_FFT_HIDDEN fft;	# Structure with info that must survive between FFT calls
#ifdef HAVE_GDAL
	struct GMT_GDALREAD_IN_CTRL  gdal_read_in;  # Hold parameters related to options transmitted to gdalread */ 
	struct GMT_GDALREAD_OUT_CTRL gdal_read_out; # Hold parameters related to options transmitted from gdalread */ 
	struct GMT_GDALWRITE_CTRL    gdal_write;    # Hold parameters related to options transmitted to gdalwrite */ 
#endif
};

struct GMT_INTERNAL {
	# These are internal parameters that need to be passed around between
	# many GMT functions.  These may change during execution but are not
	# modified directly by user interaction.
	func_level::UInt32		# Keeps track of what level in a nested GMT_func calling GMT_func etc we are.  0 is top function
	mem_cols::Csize_t		# Current number of allocated columns for temp memory
	mem_rows::Csize_t		# Current number of allocated rows for temp memory
	mem_coord::Ptr{Ptr{Float64}}		# Columns of temp memory
	struct MEMORY_TRACKER *mem_keeper;
};

immutable GMT_CTRL
	# Master structure for a GMT invokation. All internal settings for GMT is accessed here
	session::GMT_SESSION	# Structure with all values that do not change throughout a session */
	init::GMT_INIT			# Structure with all values that do not change in a GMT_func call */
	common::GMT_COMMON		# Structure with all the common GMT command settings (-R -J ..) */
	current::GMT_CURRENT	# Structure with all the GMT items that can change during execution, such as defaults settings (pens, colors, fonts.. ) */
	hidden::GMT_INTERNAL	# Internal global variables that are not to be changed directly by users */
	PSL::Ptr{PSL_CTRL}		# Pointer to the PSL structure [or NULL] */
	parent::Ptr{GMTAPI_CTRL}	# Owner of this structure [or NULL]; gives access to the API from functions being passed *GMT only */
end
=#
