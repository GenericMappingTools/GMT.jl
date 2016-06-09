const GMT_B_OPT = "-B<args>"
const GMT_I_OPT = "-I<xinc>[<unit>][=|+][/<yinc>[<unit>][=|+]]"
const GMT_J_OPT = "-J<args>"
const GMT_R2_OPT = "-R[<unit>]<xmin>/<xmax>/<ymin>/<ymax>[r]"
const GMT_R3_OPT = "-R[<unit>]<xmin>/<xmax>/<ymin>/<ymax>[/<zmin>/<zmax>][r]"
const GMT_U_OPT = "-U[<just>/<dx>/<dy>/][c|<label>]"
const GMT_V_OPT = "-V[<level>]"
const GMT_X_OPT = "-X[a|c|r]<xshift>[<unit>]"
const GMT_Y_OPT = "-Y[a|c|r]<yshift>[<unit>]"
const GMT_a_OPT = "-a<col>=<name>[,...]"
const GMT_b_OPT = "-b[i|o][<ncol>][t][w][+L|B]"
const GMT_c_OPT = "-c<ncopies>"
const GMT_f_OPT = "-f[i|o]<info>"
const GMT_g_OPT = "-g[a]x|y|d|X|Y|D|[<col>]z[-|+]<gap>[<unit>]"
const GMT_h_OPT = "-h[i|o][<nrecs>][+c][+d][+r<remark>][+t<title>]"
const GMT_i_OPT = "-i<cols>[l][s<scale>][o<offset>][,...]"
const GMT_n_OPT = "-n[b|c|l|n][+a][+b<BC>][+c][+t<threshold>]"
const GMT_o_OPT = "-o<cols>[,...]"
const GMT_p_OPT = "-p[x|y|z]<azim>/<elev>[/<zlevel>][+w<lon0>/<lat0>[/<z0>][+v<x0>/<y0>]"
const GMT_r_OPT = "-r"
const GMT_s_OPT = "-s[<cols>][a|r]"
const GMT_t_OPT = "-t<transp>"
const GMT_colon_OPT = "-:[i|o]"
const GMT_FFT_OPT = "[f|q|s|<nx>/<ny>][+a|d|l][+e|m|n][+t<width>][+w<suffix>][+z[p]]"
# Skipping MacroDefinition: GMT_tic(C){if(C->current.setting.verbose>=GMT_MSG_TICTOC)GMT_Message(C->parent,GMT_TIME_RESET,"");}
# Skipping MacroDefinition: GMT_toc(C,...){if(C->current.setting.verbose>=GMT_MSG_TICTOC)GMT_Message(C->parent,GMT_TIME_ELAPSED,"(%s) | %s\n",C->init.module_name,__VA_ARGS__);}
# begin enum GMT_enum_api
typealias GMT_enum_api UInt32
const GMT_USAGE = 0
const GMT_SYNOPSIS = 1
const GMT_STR16 = 16
# end enum GMT_enum_api
const GMT_SESSION_NORMAL   = 0   # Typical mode to GMT_Create_Session
const GMT_SESSION_NOEXIT   = 1   # Call return and not exit when error
const GMT_SESSION_EXTERNAL = 2   # Called by an external API (e.g., Matlab, Julia, Python).
const GMT_SESSION_COLMAJOR = 4   # External API uses column-major formats (e.g., Julai, MATLAB, Fortran). [Row-major format]
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
# end enum GMT_enum_type
# begin enum GMT_enum_opt
typealias GMT_enum_opt UInt32
const GMT_OPT_USAGE = 63
const GMT_OPT_SYNOPSIS = 94
const GMT_OPT_PARAMETER = 45
const GMT_OPT_INFILE = 60
const GMT_OPT_OUTFILE = 62
# end enum GMT_enum_opt
immutable GMT_OPTION			# Structure for a single GMT command option
	option::UInt8				# 1-char command line -<option> (e.g. D in -D) identifying the option (* if file)
	arg::Ptr{UInt8}				# If not NULL, contains the argument for this option
	next::Ptr{GMT_OPTION}
	previous::Ptr{GMT_OPTION}
end
# begin enum GMT_enum_method
typealias GMT_enum_method UInt32
const GMT_IS_FILE = 0
const GMT_IS_STREAM = 1
const GMT_IS_FDESC = 2
const GMT_IS_DUPLICATE = 3
const GMT_IS_REFERENCE = 4
# end enum GMT_enum_method
# begin enum GMT_enum_via
typealias GMT_enum_via UInt32
const GMT_VIA_NONE = 0
const GMT_VIA_VECTOR = 100
const GMT_VIA_MATRIX = 200
const GMT_VIA_OUTPUT = 2048
# end enum GMT_enum_via
# begin enum GMT_enum_family
typealias GMT_enum_family UInt32
const GMT_IS_DATASET = 0
const GMT_IS_TEXTSET = 1
const GMT_IS_GRID = 2
const GMT_IS_CPT = 3
const GMT_IS_IMAGE = 4
const GMT_IS_VECTOR = 5
const GMT_IS_MATRIX = 6
const GMT_IS_COORD = 7
const GMT_IS_PS = 8
const GMT_N_FAMILIES = 9
# end enum GMT_enum_family
# begin enum GMT_enum_comment
typealias GMT_enum_comment UInt32
const GMT_COMMENT_IS_TEXT = 0
const GMT_COMMENT_IS_OPTION = 1
const GMT_COMMENT_IS_COMMAND = 2
const GMT_COMMENT_IS_REMARK = 4
const GMT_COMMENT_IS_TITLE = 8
const GMT_COMMENT_IS_NAME_X = 16
const GMT_COMMENT_IS_NAME_Y = 32
const GMT_COMMENT_IS_NAME_Z = 64
const GMT_COMMENT_IS_COLNAMES = 128
const GMT_COMMENT_IS_RESET = 256
# end enum GMT_enum_comment
# begin enum GMT_api_err_enum
typealias GMT_api_err_enum Cint
const GMT_NOTSET = -1
const GMT_NOERROR = 0
# end enum GMT_api_err_enum
# begin enum GMT_module_enum
typealias GMT_module_enum Cint
const GMT_MODULE_EXIST = -3
const GMT_MODULE_PURPOSE = -2
const GMT_MODULE_OPT = -1
const GMT_MODULE_CMD = 0
# end enum GMT_module_enum
# begin enum GMT_io_enum
typealias GMT_io_enum UInt32
const GMT_IN = 0
const GMT_OUT = 1
const GMT_ERR = 2
# end enum GMT_io_enum
# begin enum GMT_enum_dimensions
typealias GMT_enum_dimensions UInt32
const GMT_X = 0
const GMT_Y = 1
const GMT_Z = 2
# end enum GMT_enum_dimensions
# begin enum GMT_enum_freg
typealias GMT_enum_freg UInt32
const GMT_ADD_FILES_IF_NONE = 1
const GMT_ADD_FILES_ALWAYS = 2
const GMT_ADD_STDIO_IF_NONE = 4
const GMT_ADD_STDIO_ALWAYS = 8
const GMT_ADD_EXISTING = 16
const GMT_ADD_DEFAULT = 6
# end enum GMT_enum_freg
# begin enum GMT_enum_ioset
typealias GMT_enum_ioset UInt32
const GMT_IO_DONE = 0
const GMT_IO_ASCII = 512
const GMT_IO_RESET = 32768
const GMT_IO_UNREG = 16384
# end enum GMT_enum_ioset
# begin enum GMT_enum_read
typealias GMT_enum_read UInt32
const GMT_READ_DOUBLE = 0
const GMT_READ_NORMAL = 0
const GMT_READ_TEXT = 1
const GMT_READ_MIXED = 2
const GMT_FILE_BREAK = 4
# end enum GMT_enum_read

const GMT_ALLOC_EXTERNALLY = 0    # Allocated outside of GMT: We cannot reallocate or free this memory
const GMT_ALLOC_INTERNALLY = 1    # Allocated by GMT: We may reallocate as needed and free when no longer needed
const GMT_ALLOC_NORMAL = 0        # Normal allocation of new dataset based on shape of input dataset
const GMT_ALLOC_VERTICAL = 4      # Allocate a single table for data set to hold all input tables by vertical concatenation */
const GMT_ALLOC_HORIZONTAL = 8
# begin enum GMT_enum_write
typealias GMT_enum_write UInt32
const GMT_WRITE_DOUBLE = 0
const GMT_WRITE_TEXT = 1
const GMT_WRITE_SEGMENT_HEADER = 2
const GMT_WRITE_TABLE_HEADER = 3
const GMT_WRITE_TABLE_START = 4
const GMT_WRITE_NOLF = 16
# end enum GMT_enum_write
# begin enum GMT_enum_header
typealias GMT_enum_header UInt32
const GMT_HEADER_OFF = 0
const GMT_HEADER_ON = 1
# end enum GMT_enum_header
# begin enum GMT_enum_dest
typealias GMT_enum_dest UInt32
const GMT_WRITE_SET = 0
const GMT_WRITE_OGR = 1
const GMT_WRITE_TABLE = 2
const GMT_WRITE_SEGMENT = 3
const GMT_WRITE_TABLE_SEGMENT = 4
# end enum GMT_enum_dest
# begin enum GMT_enum_alloc
const GMT_ALLOCATED_EXTERNALLY = 0
const GMT_ALLOCATED_BY_GMT = 1
# end enum GMT_enum_alloc
# begin enum GMT_enum_duplicate
typealias GMT_enum_duplicate UInt32
const GMT_DUPLICATE_NONE = 0
const GMT_DUPLICATE_ALLOC = 1
const GMT_DUPLICATE_DATA = 2
# end enum GMT_enum_duplicate
# begin enum GMT_enum_shape
typealias GMT_enum_shape UInt32
const GMT_ALLOC_NORMAL = 0
const GMT_ALLOC_VERTICAL = 4
const GMT_ALLOC_HORIZONTAL = 8
# end enum GMT_enum_shape
# begin enum GMT_enum_out
typealias GMT_enum_out UInt32
const GMT_WRITE_NORMAL = 0
const GMT_WRITE_HEADER = 1
const GMT_WRITE_SKIP = 2
# end enum GMT_enum_out
# begin enum GMT_FFT_mode
typealias GMT_FFT_mode UInt32
const GMT_FFT_FWD = 0
const GMT_FFT_INV = 1
const GMT_FFT_REAL = 0
const GMT_FFT_COMPLEX = 1
# end enum GMT_FFT_mode
# begin enum GMT_time_mode
typealias GMT_time_mode UInt32
const GMT_TIME_NONE = 0
const GMT_TIME_CLOCK = 1
const GMT_TIME_ELAPSED = 2
const GMT_TIME_RESET = 4
# end enum GMT_time_mode
# begin enum GMT_enum_verbose
typealias GMT_enum_verbose UInt32
const GMT_MSG_QUIET = 0
const GMT_MSG_NORMAL = 1
const GMT_MSG_TICTOC = 2
const GMT_MSG_COMPAT = 3
const GMT_MSG_VERBOSE = 4
const GMT_MSG_LONG_VERBOSE = 5
const GMT_MSG_DEBUG = 6
# end enum GMT_enum_verbose
# begin enum GMT_enum_reg
typealias GMT_enum_reg UInt32
const GMT_GRID_NODE_REG = 0
const GMT_GRID_PIXEL_REG = 1
const GMT_GRID_DEFAULT_REG = 1024
# end enum GMT_enum_reg
# begin enum GMT_enum_gridindex
typealias GMT_enum_gridindex UInt32
const GMT_XLO = 0
const GMT_XHI = 1
const GMT_YLO = 2
const GMT_YHI = 3
const GMT_ZLO = 4
const GMT_ZHI = 5
# end enum GMT_enum_gridindex
# begin enum GMT_enum_dimindex
typealias GMT_enum_dimindex UInt32
const GMT_TBL = 0
const GMT_SEG = 1
const GMT_ROW = 2
const GMT_COL = 3
# end enum GMT_enum_dimindex
# begin enum GMT_enum_gridio
typealias GMT_enum_gridio UInt32
const GMT_GRID_IS_REAL = 0
const GMT_GRID_ALL = 0
const GMT_GRID_HEADER_ONLY = 1
const GMT_GRID_DATA_ONLY = 2
const GMT_GRID_IS_COMPLEX_REAL = 4
const GMT_GRID_IS_COMPLEX_IMAG = 8
const GMT_GRID_IS_COMPLEX_MASK = 12
const GMT_GRID_NO_HEADER = 16
const GMT_GRID_ROW_BY_ROW = 32
const GMT_GRID_ROW_BY_ROW_MANUAL = 64
# end enum GMT_enum_gridio
# begin enum GMT_enum_grdlen
typealias GMT_enum_grdlen UInt32
const GMT_GRID_UNIT_LEN80 = 80
const GMT_GRID_TITLE_LEN80 = 80
const GMT_GRID_VARNAME_LEN80 = 80
const GMT_GRID_COMMAND_LEN320 = 320
const GMT_GRID_REMARK_LEN160 = 160
const GMT_GRID_NAME_LEN256 = 256
const GMT_GRID_HEADER_SIZE = 892
# end enum GMT_enum_grdlen

typealias Gmt_api_error_code UInt32
const GMT_OK = 0
const GMT_WRONG_MATRIX_SHAPE = 1
const GMT_ACCESS_NOT_ENABLED = 2
const GMT_ARGV_LIST_NULL = 3
const GMT_ARG_IS_NULL = 4
const GMT_COUNTER_IS_NEGATIVE = 5
const GMT_BAD_GEOMETRY = 6
const GMT_BAD_PERMISSION = 7
const GMT_CPT_READ_ERROR = 8
const GMT_DATA_READ_ERROR = 9
const GMT_DATA_WRITE_ERROR = 10
const GMT_DIM_TOO_LARGE = 11
const GMT_DIM_TOO_SMALL = 12
const GMT_ERROR_ON_FCLOSE = 13
const GMT_ERROR_ON_FDOPEN = 14
const GMT_ERROR_ON_FOPEN = 15
const GMT_FILE_NOT_FOUND = 16
const GMT_GRID_BC_ERROR = 17
const GMT_GRID_READ_ERROR = 18
const GMT_GRID_WRITE_ERROR = 19
const GMT_ID_TOO_LARGE = 20
const GMT_IMAGE_BC_ERROR = 21
const GMT_IMAGE_READ_ERROR = 22
const GMT_MEMORY_ERROR = 23
const GMT_FREE_EXTERNAL_NOT_ALLOWED = 24
const GMT_FREE_WRONG_LEVEL = 25
const GMT_NOT_A_SESSION = 26
const GMT_NOT_A_VALID_ARG = 27
const GMT_NOT_A_VALID_DIRECTION = 28
const GMT_NOT_A_VALID_FAMILY = 29
const GMT_NOT_A_VALID_ID = 30
const GMT_NOT_A_VALID_IO_ACCESS = 31
const GMT_NOT_A_VALID_IO_MODE = 32
const GMT_NOT_A_VALID_IO_SESSION = 33
const GMT_NOT_A_VALID_METHOD = 34
const GMT_NOT_A_VALID_MODE = 35
const GMT_NOT_A_VALID_MODULE = 36
const GMT_NOT_A_VALID_PARAMETER = 37
const GMT_NOT_A_VALID_TYPE = 38
const GMT_NOT_INPUT_OBJECT = 39
const GMT_NOT_OUTPUT_OBJECT = 40
const GMT_NO_GRDHEADER = 41
const GMT_NO_INPUT = 42
const GMT_NO_OUTPUT = 43
const GMT_NO_PARAMETERS = 44
const GMT_NO_RESOURCES = 45
const GMT_N_COLS_NOT_SET = 46
const GMT_N_COLS_VARY = 47
const GMT_N_ROWS_NOT_SET = 48
const GMT_OBJECT_NOT_FOUND = 49
const GMT_OGR_ONE_TABLE_ONLY = 50
const GMT_ONLY_ONE_ALLOWED = 51
const GMT_OPTION_EXIST = 52
const GMT_OPTION_HISTORY_ERROR = 53
const GMT_OPTION_IS_NULL = 54
const GMT_OPTION_LIST_NULL = 55
const GMT_OPTION_NOT_FOUND = 56
const GMT_OPTION_SORT_ERROR = 57
const GMT_OUTPUT_NOT_SET = 58
const GMT_PADDING_NOT_ALLOWED = 59
const GMT_PARSE_ERROR = 60
const GMT_PROG_NOT_FOUND = 61
const GMT_PTR_IS_NULL = 62
const GMT_PTR_NOT_NULL = 63
const GMT_PTR_NOT_UNIQUE = 64
const GMT_READ_ONCE = 65
const GMT_RUNTIME_ERROR = 66
const GMT_SIZE_IS_ZERO = 67
const GMT_STREAM_NOT_ALLOWED = 68
const GMT_SUBSET_NOT_ALLOWED = 69
const GMT_VALUE_NOT_SET = 70
const GMT_WRITTEN_ONCE = 71
# end enum Gmt_api_error_code

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

type GMT_GRID_HEADER
	nx::UInt32
	ny::UInt32
	registration::UInt32
	wesn::NTuple{4, Cdouble}
	z_min::Cdouble
	z_max::Cdouble
	inc::NTuple{2, Cdouble}
	z_scale_factor::Cdouble
	z_add_offset::Cdouble
	x_units::NTuple{80, UInt8}
	y_units::NTuple{80, UInt8}
	z_units::NTuple{80, UInt8}
	title::NTuple{80, UInt8}
	command::NTuple{320, UInt8}
	remark::NTuple{160, UInt8}
	# Variables "hidden" from the API. This section is flexible and considered private
	_type::UInt32
	bits::UInt32
	complex_mode::UInt32
	mx::UInt32
	my::UInt32
	nm::Csize_t
	size::Csize_t
	n_alloc::Csize_t
	trendmode::UInt32
	arrangement::UInt32
	n_bands::UInt32
	pad::NTuple{4, UInt32}
	BC::NTuple{4, UInt32}
	grdtype::UInt32
	name::NTuple{256, UInt8}
	varname::NTuple{80, UInt8}
	ProjRefPROJ4::Ptr{UInt8}
	ProjRefWKT::Ptr{UInt8}
	row_order::Cint
	z_id::Cint
	ncid::Cint
	xy_dim::NTuple{2, Cint}
	t_index::NTuple{3, Csize_t}
	data_offset::Csize_t
	stride::UInt32
	nan_value::Cfloat
	xy_off::Cdouble
	r_inc::NTuple{2, Cdouble}
	flags::NTuple{4, UInt8}
	pocket::Ptr{UInt8}
	mem_layout::NTuple{4, UInt8}
	bcr_threshold::Cdouble
	bcr_interpolant::UInt32
	bcr_n::UInt32
	nxp::UInt32
	nyp::UInt32
	no_BC::UInt32
	gn::UInt32
	gs::UInt32
	is_netcdf4::UInt32
	z_chunksize::NTuple{2, Csize_t}
	z_shuffle::UInt32
	z_deflate_level::UInt32
	z_scale_autoadust::UInt32
	z_offset_autoadust::UInt32
	xy_adjust::NTuple{2, UInt32}
	xy_mode::NTuple{2, UInt32}
	xy_unit::NTuple{2, UInt32}
	xy_unit_to_meter::NTuple{2, Cdouble}
end
type GMT_GRID
	header::Ptr{GMT_GRID_HEADER}
	data::Ptr{Cfloat}
	id::UInt32
	alloc_level::UInt32
	alloc_mode::UInt32
	extra::Ptr{Void}
end
# begin enum GMT_enum_geometry
typealias GMT_enum_geometry UInt32
const GMT_IS_POINT = 1
const GMT_IS_LINE = 2
const GMT_IS_POLY = 4
const GMT_IS_PLP = 7
const GMT_IS_SURFACE = 8
const GMT_IS_NONE = 16
# end enum GMT_enum_geometry
# begin enum GMT_enum_pol
typealias GMT_enum_pol UInt32
const GMT_IS_PERIMETER = 0
const GMT_IS_HOLE = 1
# end enum GMT_enum_pol
# begin enum GMT_enum_ascii_input_return
typealias GMT_enum_ascii_input_return UInt32
const GMT_IO_DATA_RECORD = 0
const GMT_IO_TABLE_HEADER = 1
const GMT_IO_SEGMENT_HEADER = 2
const GMT_IO_ANY_HEADER = 3
const GMT_IO_MISMATCH = 4
const GMT_IO_EOF = 8
const GMT_IO_NAN = 16
const GMT_IO_NEW_SEGMENT = 18
const GMT_IO_GAP = 32
const GMT_IO_LINE_BREAK = 58
const GMT_IO_NEXT_FILE = 64
# end enum GMT_enum_ascii_input_return
immutable GMT_OGR
	geometry::UInt32
	n_aspatial::UInt32
	region::Ptr{UInt8}
	proj::NTuple{4, Ptr{UInt8}}
	_type::Ptr{UInt32}
	name::Ptr{Ptr{UInt8}}
	pol_mode::GMT_enum_pol
	tvalue::Ptr{Ptr{UInt8}}
	dvalue::Ptr{Cdouble}
end
immutable GMT_OGR_SEG
	pol_mode::GMT_enum_pol
	n_aspatial::UInt32
	tvalue::Ptr{Ptr{UInt8}}
	dvalue::Ptr{Cdouble}
end
immutable GMT_DATASEGMENT
	n_rows::UInt64
	n_columns::UInt64
	min::Ptr{Cdouble}
	max::Ptr{Cdouble}
	coord::Ptr{Ptr{Cdouble}}
	label::Ptr{UInt8}
	header::Ptr{UInt8}
	mode::GMT_enum_out
	pol_mode::GMT_enum_pol
	id::UInt64
	n_alloc::Cint
	range::Cint
	pole::Cint
	dist::Cdouble
	lat_limit::Cdouble
	ogr::Ptr{GMT_OGR_SEG}
	next::Ptr{GMT_DATASEGMENT}
	file::NTuple{2, Ptr{UInt8}}
end
immutable GMT_DATATABLE
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
	mode::GMT_enum_out
	ogr::Ptr{GMT_OGR}
	file::NTuple{2, Ptr{UInt8}}
end
immutable GMT_DATASET
	n_tables::UInt64
	n_columns::UInt64
	n_segments::UInt64
	n_records::UInt64
	min::Ptr{Cdouble}
	max::Ptr{Cdouble}
	table::Ptr{Ptr{GMT_DATATABLE}}
	id::UInt64
	n_alloc::Cint
	dim::NTuple{4, UInt64}
	geometry::UInt32
	alloc_level::UInt32
	io_mode::UInt32
	alloc_mode::UInt32
	file::NTuple{2, Ptr{UInt8}}
end
immutable GMT_TEXTSEGMENT
	n_rows::UInt64
	record::Ptr{Ptr{UInt8}}
	label::Ptr{UInt8}
	header::Ptr{UInt8}
	id::UInt64
	mode::UInt32
	n_alloc::Cint
	file::NTuple{2, Ptr{UInt8}}
	tvalue::Ptr{Ptr{UInt8}}
end
immutable GMT_TEXTTABLE
	n_headers::UInt32
	n_segments::UInt64
	n_records::UInt64
	header::Ptr{Ptr{UInt8}}
	segment::Ptr{Ptr{GMT_TEXTSEGMENT}}
	id::UInt64
	n_alloc::Cint
	mode::UInt32
	file::NTuple{2, Ptr{UInt8}}
end
immutable GMT_TEXTSET
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
	file::NTuple{2, Ptr{UInt8}}
end
# begin enum GMT_enum_color
typealias GMT_enum_color UInt32
const GMT_RGB = 0
const GMT_CMYK = 1
const GMT_HSV = 2
const GMT_COLORINT = 4
const GMT_NO_COLORNAMES = 8
# end enum GMT_enum_color
# begin enum GMT_enum_bfn
typealias GMT_enum_bfn UInt32
const GMT_BGD = 0
const GMT_FGD = 1
const GMT_NAN = 2
# end enum GMT_enum_bfn
# begin enum GMT_enum_cpt
typealias GMT_enum_cpt UInt32
const GMT_CPT_REQUIRED = 0
const GMT_CPT_OPTIONAL = 1
# end enum GMT_enum_cpt
# begin enum GMT_enum_cptflags
typealias GMT_enum_cptflags UInt32
const GMT_CPT_NO_BNF = 1
const GMT_CPT_EXTEND_BNF = 2
# end enum GMT_enum_cptflags
immutable GMT_FILL
	rgb::NTuple{4, Cdouble}
	f_rgb::NTuple{4, Cdouble}
	b_rgb::NTuple{4, Cdouble}
	use_pattern::Bool
	pattern_no::Int32
	dpi::UInt32
	pattern::NTuple{256, UInt8}		# was char pattern[GMT_BUFSIZ];
end
immutable GMT_LUT
	z_low::Cdouble
	z_high::Cdouble
	i_dz::Cdouble
	rgb_low::NTuple{4, Cdouble}
	rgb_high::NTuple{4, Cdouble}
	rgb_diff::NTuple{4, Cdouble}
	hsv_low::NTuple{4, Cdouble}
	hsv_high::NTuple{4, Cdouble}
	hsv_diff::NTuple{4, Cdouble}
	annot::UInt32
	skip::UInt32
	fill::Ptr{GMT_FILL}
	label::Ptr{UInt8}
end
immutable GMT_BFN_COLOR
	rgb::NTuple{4, Cdouble}
	hsv::NTuple{4, Cdouble}
	skip::UInt32
	fill::Ptr{GMT_FILL}
end
immutable GMT_PALETTE
	n_headers::UInt32
	n_colors::UInt32
	cpt_flags::UInt32
	range::Ptr{GMT_LUT}
	patch::NTuple{3, GMT_BFN_COLOR}
	header::Ptr{Ptr{UInt8}}
	id::UInt64
	alloc_mode::UInt32
	alloc_level::UInt32
	auto_scale::UInt32
	model::UInt32
	is_gray::UInt32
	is_bw::UInt32
	is_continuous::UInt32
	has_pattern::UInt32
	skip::UInt32
	categorical::UInt32
	z_adjust::NTuple{2, UInt32}
	z_mode::NTuple{2, UInt32}
	z_unit::NTuple{2, UInt32}
	z_unit_to_meter::NTuple{2, Cdouble}
end
immutable GMT_IMAGE
	_type::UInt32
	ColorMap::Ptr{Cint}
	nIndexedColors::Cint
	header::Ptr{GMT_GRID_HEADER}
	data::Ptr{Cuchar}
	id::UInt64
	alloc_level::UInt32
	alloc_mode::UInt32
	ColorInterp::Ptr{UInt8}
end
type GMT_PS
	n_alloc::Csize_t
	n::Csize_t
	mode::UInt32
	data::Ptr{UInt8}
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

immutable GMT_VECTOR
	n_columns::UInt64
	n_rows::UInt64
	registration::UInt32
	_type::Ptr{UInt32}
	#data::Ptr{GMT_UNIVECTOR}
	data::Ptr{Ptr{Void}}
	range::NTuple{2, Cdouble}
	command::NTuple{320, UInt8}
	remark::NTuple{160, UInt8}
	id::UInt64
	alloc_level::UInt32
	alloc_mode::UInt32
end
# begin enum GMT_enum_fmt
typealias GMT_enum_fmt UInt32
const GMT_IS_ROW_FORMAT = 0
const GMT_IS_COL_FORMAT = 1
# end enum GMT_enum_fmt

type GMT_MATRIX
	n_rows::UInt64
	n_columns::UInt64
	n_layers::UInt64
	shape::UInt32
	registration::UInt32
	dim::Csize_t
	size::Csize_t
	_type::UInt32
	range::NTuple{6, Cdouble}
#	data::GMT_UNIVECTOR
#	data::Union(Ptr{UInt8},Ptr{Int8},Ptr{UInt16},Ptr{Int16},Ptr{UInt32},Ptr{Int32},
#		Ptr{UInt64},Ptr{Int64},Ptr{Float32},Ptr{Float64})
	data::Ptr{Void}
	command::NTuple{320, UInt8}
	remark::NTuple{160, UInt8}
	id::UInt64
	alloc_level::UInt32
	alloc_mode::UInt32
end

type GMT_RESOURCE
	family::UInt32          # GMT data family, i.e., GMT_IS_DATASET, GMT_IS_GRID, etc.
	geometry::UInt32        # One of the recognized GMT geometries
	direction::UInt32       # Either GMT_IN or GMT_OUT
	option::Ptr{GMT_OPTION} # Pointer to the corresponding module option
	object_ID::Cint         # Object ID returned by GMT_Register_IO
	pos::Cint               # Corresponding index into external object in|out arrays
#	mode::Cint              # Either primary (0) or secondary (1) resource
	object::Ptr{Void}       # Pointer to the registered GMT object
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
	direction::GMT_io_enum		# GMT_IN or GMT_OUT
	family::GMT_enum_family		# One of GMT_IS_{DATASET|TEXTSET|CPT|IMAGE|GRID|MATRIX|VECTOR|COORD}
	actual_family::GMT_enum_family	# May be GMT_IS_MATRIX|VECTOR when one of the others are created via those
	method::UInt32              # One of GMT_IS_{FILE,STREAM,FDESC,DUPLICATE,REFERENCE} or sum with enum GMT_enum_via (GMT_VIA_{NONE,VECTOR,MATRIX,OUTPUT}); using unsigned type because sum exceeds enum GMT_enum_method
	geometry::GMT_enum_geometry	# One of GMT_IS_{POINT|LINE|POLY|PLP|SURFACE|NONE}
	wesn::NTuple{4, Cdouble}	# Grid domain limits
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

	current_rec::NTuple{2, UInt64}	# Current record number >= 0 in the combined virtual dataset (in and out)
	n_objects::UInt32			# Number of currently active input and output data objects
	unique_ID::UInt32			# Used to create unique IDs for duration of session
	session_ID::UInt32			# ID of this session
	unique_var_ID::UInt32		# Used to create unique object IDs (grid,dataset, etc) for duration of session
	current_item::NTuple{2, UInt32}	# Array number of current dataset being processed (in and out)
	pad::UInt32					# Session default for number of rows/cols padding for grids [2]
	mode::UInt32				# 1 if called via external API (Matlab, Python) [0]
	leave_grid_scaled::UInt32	# 1 if we dont want to unpack a grid after we packed it for writing [0]
	registered::NTuple{2, Cint}	# true if at least one source/destination has been registered (in and out)
	io_enabled::NTuple{2, Cint}	# true if access has been allowed (in and out)
	n_objects_alloc::Csize_t	# Allocation counter for data objects
	error::Int32				# Error code from latest API call [GMT_OK]
	last_error::Int32			# Error code from previous API call [GMT_OK]
	shelf::Int32				# Place to pass hidden values within API
	io_mode::NTuple{2, UInt32}	# 1 if access as set, 0 if record-by-record
	#GMT::Ptr{GMT_CTRL}			# Key structure with low-level GMT internal parameters
	GMT::Ptr{Void}				# Maybe one day. Till than just keep it as void
	object::Ptr{Ptr{GMTAPI_DATA_OBJECT}}	# List of registered data objects
	session_tag::Ptr{UInt8}		# Name tag for this session (or NULL)
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
	struct GMT_PS ps;		# Hold parameters related to PS setup
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
