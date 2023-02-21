const Void = Cvoid
const NULL = C_NULL

#= 
# These are not used anymore, I think.
const DOUBLE_CLASS = 1
const SINGLE_CLASS = 2
const INT64_CLASS  = 3
const UINT64_CLASS = 4
const INT32_CLASS  = 5
const UINT32_CLASS = 6
const INT16_CLASS  = 7
const UINT16_CLASS = 8
const INT8_CLASS   = 9
const UINT8_CLASS  = 10 =#

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
	# end::NTuple{2,GMT_LINE_END}
	end_::NTuple{2,Ptr{Cvoid}}		# This is a dangereous thing. If accessed, will crash Julia
	GMT_PEN(width, offset, rgb, style, mode, cptmode, end_) = new(width, offset, rgb, style, mode, cptmode, end_)
	GMT_PEN() = new(0.0, 0.0, (0.0, 0.0, 0.0, 0.0), map(UInt8, (repeat('\0', 128)...,)), 0, 0, (pointer([0]), pointer([0])))
end

mutable struct GMT_GRID_HEADER
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
	type::UInt32
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

mutable struct GMT_GRID
	header::Ptr{GMT_GRID_HEADER}
	data::Ptr{Cfloat}
	x::Ptr{Cdouble}
	y::Ptr{Cdouble}
	hidden::Ptr{Cvoid}
end

mutable struct GMT_CUBE
	header::Ptr{GMT_GRID_HEADER}
	data::Ptr{Cfloat}
	x::Ptr{Cdouble}
	y::Ptr{Cdouble}
	hidden::Ptr{Cvoid}
	mode::UInt32
	z_range::NTuple{2,Cdouble}
	z_inc::Cdouble
	z::Ptr{Cdouble}
	name::NTuple{80,UInt8}
	units::NTuple{80,UInt8}
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

mutable struct GMT_IMAGE
	type::UInt32
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

struct GMT_FILL
	rgb::NTuple{4,Cdouble}
	f_rgb::NTuple{4,Cdouble}
	b_rgb::NTuple{4,Cdouble}
	use_pattern::Bool
	pattern_no::Int32
	dpi::UInt32
	dim::NTuple{3,UInt32}
	pattern::NTuple{1024,UInt8}		# was char pattern[PATH_MAX];
	image::Ptr{UInt8}
	I::Ptr{GMT_IMAGE}
end

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

struct GMT_BFN
	rgb::NTuple{4,Cdouble}
	hsv::NTuple{4,Cdouble}
	skip::UInt32
	fill::Ptr{GMT_FILL}
end

mutable struct GMT_PALETTE
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

mutable struct GMT_POSTSCRIPT
	n_bytes::Csize_t
	mode::UInt32
	n_headers::UInt32
	data::Ptr{UInt8}
	header::Ptr{Ptr{UInt8}}
	hidden::Ptr{Cvoid}
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

struct GMT_VECTOR
	n_columns::UInt64
	n_rows::UInt64
	n_headers::UInt32
	registration::UInt32
	type::Ptr{UInt32}
	range::NTuple{2,Cdouble}
	# data::Ptr{GMT_UNIVECTOR}
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

mutable struct GMT_MATRIX
	n_rows::UInt64
	n_columns::UInt64
	n_layers::UInt64
	n_headers::UInt32
	shape::UInt32
	registration::UInt32
	dim::Csize_t
	size::Csize_t
	type::UInt32
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

mutable struct GMT_RESOURCE
	family::UInt32          # GMT data family, i.e., GMT_IS_DATASET, GMT_IS_GRID, etc.
	geometry::UInt32        # One of the recognized GMT geometries
	direction::UInt32       # Either GMT_IN or GMT_OUT
	option::Ptr{GMT_OPTION} # Pointer to the corresponding module option
	name::NTuple{32,UInt8}  # Object ID returned by GMT_Register_IO
	pos::Cint               # Corresponding index into external object in|out arrays
	mode::Cint              # Either primary (0) or secondary (1) resource
	object::Ptr{Cvoid}      # Pointer to the actual GMT object
end

struct GMTAPI_DATA_OBJECT
	# Information for each input or output data entity, including information
	# needed while reading/writing from a table (file or array)
	rec::UInt64                 # Current rec to read [GMT_DATASET to/from MATRIX/VECTOR only]
	n_rows::UInt64              # Number or rows in this array [GMT_DATASET to/from MATRIX/VETOR only]
	n_columns::UInt64			# Number of columns to process in this dataset [GMT_DATASET only]
	n_expected_fields::UInt64	# Number of expected columns for this dataset [GMT_DATASET only]
	delay::UInt64				# Number of leading NaN-records we oculd not write initially before knowning the row dim
	n_alloc::Csize_t			# Number of items allocated so far if writing to memory
	ID::UInt32					# Unique identifier which is >= 0
	alloc_level::UInt32			# Nested module level when object was allocated
	status::UInt32				# 0 when first registered, 1 after reading/writing has started, 2 when finished
	orig_pad::NTuple{4,UInt32}	# Original grid pad
	reset_pad::UInt32			# 1 for input memory grids from which a subregion was requested
	h_delay::Bool				# We must delay writing table headers until memory allocated
	s_delay::Bool				# We must delay writing segment header until memory allocated
	selected::Bool				# true if requested by current module, false otherwise
	close_file::Bool			# true if we opened source as a file and thus need to close it when done
	region::Bool				# true if wesn was passed, false otherwise
	no_longer_owner::Bool		# true if the data pointed to by the object was passed on to another object
	messenger::Bool				# true for output objects passed from the outside to receive data from GMT. If true we destroy data pointer before writing
	module_input::Bool			# true for input objects that will serve as module input(s) and not option inputs */
	alloc_mode::UInt32			# GMT_ALLOCATED_{BY_GMT|EXTERNALLY}
	direction::UInt32			# GMT_IN or GMT_OUT
	family::UInt32				# One of GMT_IS_{DATASET|TEXTSET|CPT|IMAGE|GRID|MATRIX|VECTOR|COORD}
	actual_family::UInt32		# May be GMT_IS_MATRIX|VECTOR when one of the others are created via those
	type::UInt32				# Desired output array type for auto-allocated VECTOR and MATRIX
	method::UInt32              # One of GMT_IS_{FILE,STREAM,FDESC,DUPLICATE,REFERENCE} or sum with enum GMT_enum_via (GMT_VIA_{NONE,VECTOR,MATRIX,OUTPUT}); using unsigned type because sum exceeds enum GMT_enum_method
	geometry::UInt32			# One of GMT_IS_{POINT|LINE|POLY|PLP|SURFACE|NONE}
	wesn::NTuple{6,Cdouble}		# Active Grid domain limits
	orig_wesn::NTuple{6,Cdouble}# Original Grid domain limits
	resource::Ptr{Cvoid}		# Points to registered filename, memory location, etc., where data can be obtained from with GMT_Get_Data.
	data::Ptr{Cvoid}			# Points to GMT object that was read from a resource
	# FILE *fp;					# Pointer to source/destination stream [For rec-by-rec procession, NULL if memory location]
	fp::Ptr{Cvoid}				# Pointer to source/destination stream [For rec-by-rec procession, NULL if memory location]
	filename::Ptr{UInt8}		# Filename, stream, of file handle (otherwise NULL)
	# Cvoid *(*import) (struct GMT_CTRL *, FILE *, uint64_t *, int *);	# Pointer to input function (for DATASET/TEXTSET only)
	ifun::Ptr{Cvoid} 			# Pointer to input function (for DATASET/TEXTSET only)
	# Start of temporary variables for API debug - They are only set when building GMT with /DEBUG
	G::Ptr{Cvoid}				# struct GMT_GRID *G;
	D::Ptr{Cvoid}				# struct GMT_DATASET *D;
	C::Ptr{Cvoid}				# struct GMT_PALETTE *C;
	P::Ptr{Cvoid}				# struct GMT_POSTSCRIPT *P;
	M::Ptr{Cvoid}				# struct GMT_MATRIX *M;
	V::Ptr{Cvoid}				# struct GMT_VECTOR *V;
	I::Ptr{Cvoid}				# struct GMT_IMAGE *I;
	U::Ptr{Cvoid}				# struct GMT_CUBE *U;
end

struct Gmt_libinfo
	name::Ptr{UInt8}	# Library tag name [without leading "lib" and extension], e.g. "gmt", "gmtsuppl" */
	path::Ptr{UInt8}	# Full path to library as given in GMT_CUSTOM_LIBS */
	skip::Ptr{Bool}		# true if we tried to open it and it was not available the first time */
	handle::Ptr{Cvoid}	# Handle to the shared library, returned by dlopen or dlopen_special */
end

struct OGR_FEATURES
	n_rows::Cint
	n_cols::Cint
	n_layers::Cint
	n_filled::Cint
	is3D::Cint
	np::Cuint
	att_number::Cint
	n_islands::Cint				# Number of islands in a polygon
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

struct OGRREAD_CTRL
	info::Cint					# If != 0 gmt_ogrread will return only Info
	layer::Cint					# If > 0 will return only data from that layer. Use negative to return all layers
	name::Ptr{UInt8}			# Vector file name
	region::NTuple{6,Cdouble}	# For when a sub-region is required
end

struct COMMON_R
	active::NTuple{4,Bool}
	oblique::Bool
	registration::Csize_t
	row_oder::Cint
	mode::Cuint
	wesn::NTuple{6,Cdouble}
	wesn_orig::NTuple{4,Cdouble}
	inc::NTuple{2,Cdouble}
	string::NTuple{256,UInt8}
end

#=
struct GMT_INTERNAL
	func_level::UInt32				# Keeps track of what level in a nested GMT_func calling GMT_func etc we are.
	mem_set::Bool					# true when we have initialized the tmp memory already */
	sample_along_arc::Bool			# true when sample1d need exact sampling along the arc */
	mem_cols::Csize_t				# Current number of allocated columns for temp memory */
	mem_rows::Csize_t				# Current number of allocated rows for temp memory */
	mem_txt_alloc::Csize_t
	mem_txt_dup::Csize_t
	mem_coord::Ptr{Ptr{Cdouble}}	# Columns of temp memory */
	mem_txt::Ptr{Ptr{UInt8}}		# For temp text */
end
=#

## 
if (GMTver >= v"6.5")

	struct GMT_CTRL
		# Master structure for a GMT invocation.  All internal settings for GMT is accessed here
		PSL::Ptr{Cvoid}				# struct GMT_POSTSCRIPT Pointer to the PSL structure [or NULL]
		parent::Ptr{Cvoid}			# struct GMTAPI_CTRL. Owner of this structure [or NULL];
		#session::GMT_SESSION		# Structure with all values that do not change throughout a session
		#init::GMT_INIT				# Structure with all values that do not change in a GMT_func call
		#common::GMT_COMMON			# Structure with all the common GMT command settings (-R -J ..)
		#current::GMT_CURRENT		# Structure with all the GMT items that can change during execution,
		#hidden::GMT_INTERNAL		# Internal global variables that are not to be changed directly by users
	end

	struct GMT_JULIA_POCKET
		gwf_dir::Ptr{UInt8}				# In API->gwf_dir. GMT WorkFlow dir (NULL if not running in modern mode). 4GMT.jl */
		col_type::NTuple{2*64, UInt32};	# Type of column on input and output: Time, geographic, etc. 4GMT.jl */
	end

	struct GMTAPI_CTRL
		# Master controller which holds all GMT API related information at run-time for a single session.
		# Users can run several GMT sessions concurrently; each session requires its own structure.
		# Use GMTAPI_Create_Session to initialize a new session and GMTAPI_Destroy_Session to end it.

		jl_pocket::GMT_JULIA_POCKET	# ...
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
		n_tmp_headers::Cint         # Number of temporarily held table headers
		terminal_width::Cint        # Width of the terminal
		verbose::UInt32             # Used until GMT is set up
		registered::NTuple{2,Bool}	# true if at least one source/destination has been registered (in and out)
		io_enabled::NTuple{2,Bool}	# true if access has been allowed (in and out)
		module_input::Bool          # true when we are about to read inputs to the module (command line) */
		usage::Bool                 # Flag when 1-liner modern mode modules just want usage
		allow_reuse::Bool           # Flag when get_region_from_data can read a file and not flag it as "used"
		is_file::Bool               # True if current rec-by-rec i/o is from a physical file
		cache::Bool                 # true if we want to read a cache file via GDAL
		no_history::Bool            # true if we want to disable the gmt.history mechanism
		got_remote_wesn::Bool       # true if we obtained w/e/sn via a remote grid/image with no resolution given
		use_gridline_registration::Bool       # true if default remote grid registration should be gridline, not pixel
		use_gridline_registration_warn::Bool  # true if we should warn about the above
		n_objects_alloc::Csize_t	# Allocation counter for data objects
		error::Int32				# Error code from latest API call [GMT_OK]
		last_error::Int32			# Error code from previous API call [GMT_OK]
		shelf::Int32				# Place to pass hidden values within API
		log_level::UInt32           # 0 = stderr, 1 = just this module, 2 = set until unset
		io_mode::NTuple{2,UInt32}	# 1 if access as set, 0 if record-by-record
		tile_wesn::NTuple{6,Cdouble}  # Original region used when getting tiles (perhaps result of -Roblique -J)
		tile_inc::Cdouble           # Remote grid increment in degrees
		tile_reg::UInt8             # Remote grid registration */
		GMT::Ptr{Cvoid}				# Ptr{GMT_CTRL}, maybe one day. Till than just keep it as Cvoid
		object::Ptr{Ptr{Cvoid}}		# Ptr{Ptr{GMTAPI_DATA_OBJECT}}. List of registered data objects
		session_tag::Ptr{UInt8}		# Name tag for this session (or NULL)
		session_name::Ptr{UInt8}    # Unique name for modern mode session (NULL for classic) */
		tmp_dir::Ptr{UInt8}         # System tmp_dir (NULL if not found)
		session_dir::Ptr{UInt8}     # GMT Session dir (NULL if not running in modern mode)
		gwf_dir::Ptr{UInt8}         # GMT WorkFlow dir (NULL if not running in modern mode)
		tmp_header::Ptr{Ptr{UInt8}} # Temporary table headers held until we are able to write them to destination */
		tmp_segmentheader::Ptr{UInt8} # Temporary segment header held until we are able to write it to destination */
		message::Ptr{UInt8}         # To be allocated by Create_Session and used for messages */
		error_msg::NTuple{4096,UInt8} # The cached last error message */
		internal::Bool				# true if session was initiated by gmt.c
		deep_debug::Bool			# temporary for debugging
		parker_fft_default::Bool    # Used to alter the default in -N FFT settings */
		#int (*print_func) (FILE *, const char *);	# Pointer to fprintf function (may be reset by external APIs like MEX)
		pf::Ptr{Cvoid}				# Don't know what to put here, so let it be *void
		do_not_exit::UInt32			# 0 by default, meaning it is OK to call exit  (may be reset by external APIs like MEX to call return instead)
		lib::Ptr{Cvoid}				# Ptr{GMT_LIBINFO}. List of shared libs to consider
		n_shared_libs::UInt32		# How many in lib
	end
end
