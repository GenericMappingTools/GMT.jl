# THESE 4 CANNOT BE CHANGED BY GMT
const global GMT_SESSION_NORMAL   = 0   # Typical mode to GMT_Create_Session
const global GMT_SESSION_NOEXIT   = 1   # Call return and not exit when error
const global GMT_SESSION_EXTERNAL = 2   # Called by an external API
const global GMT_SESSION_COLMAJOR = 4   # External API uses column-major formats. [Row-major format]

API = GMT_Create_Session("GMT", 2, GMT_SESSION_NOEXIT + GMT_SESSION_EXTERNAL + GMT_SESSION_COLMAJOR)
if (API == C_NULL)  error("Failure to create a GMT Session")  end

enu = GMT_Get_Enum(API, "GMT_CHAR");	const global GMT_CHAR  = (enu != -99999) ? enu : 0
enu = GMT_Get_Enum(API, "GMT_UCHAR");	const global GMT_UCHAR  = (enu != -99999) ? enu : 1
enu = GMT_Get_Enum(API, "GMT_SHORT");	const global GMT_SHORT  = (enu != -99999) ? enu : 2
enu = GMT_Get_Enum(API, "GMT_USHORT");	const global GMT_USHORT  = (enu != -99999) ? enu : 3
enu = GMT_Get_Enum(API, "GMT_INT");		const global GMT_INT  = (enu != -99999) ? enu : 4
enu = GMT_Get_Enum(API, "GMT_UINT");	const global GMT_UINT  = (enu != -99999) ? enu : 5
enu = GMT_Get_Enum(API, "GMT_LONG");	const global GMT_LONG  = (enu != -99999) ? enu : 6
enu = GMT_Get_Enum(API, "GMT_ULONG");	const global GMT_ULONG  = (enu != -99999) ? enu : 7
enu = GMT_Get_Enum(API, "GMT_FLOAT");	const global GMT_FLOAT  = (enu != -99999) ? enu : 8
enu = GMT_Get_Enum(API, "GMT_DOUBLE");	const global GMT_DOUBLE  = (enu != -99999) ? enu : 9
enu = GMT_Get_Enum(API, "GMT_TEXT");	const global GMT_TEXT  = (enu != -99999) ? enu : 10

enu = GMT_Get_Enum(API, "GMT_OPT_INFILE");	const global GMT_OPT_INFILE = (enu != -99999) ? enu : 60
enu = GMT_Get_Enum(API, "GMT_IS_OUTPUT");	const global GMT_IS_OUTPUT  = (enu != -99999) ? enu : 1024
enu = GMT_Get_Enum(API, "GMT_VIA_MATRIX");	const global GMT_VIA_MATRIX = (enu != -99999) ? enu : 256

# GMT_enum_container
enu = GMT_Get_Enum(API, "GMT_WITH_STRINGS");	const global GMT_WITH_STRINGS  = (enu != -99999) ? enu : 32
enu = GMT_Get_Enum(API, "GMT_NO_STRINGS");		const global GMT_NO_STRINGS  = (enu != -99999) ? enu : 0

# GMT_enum_read
enu = GMT_Get_Enum(API, "GMT_READ_DATA");	const global GMT_READ_DATA  = (enu != -99999) ? enu : 1
enu = GMT_Get_Enum(API, "GMT_READ_TEXT");	const global GMT_READ_TEXT  = (enu != -99999) ? enu : 2
enu = GMT_Get_Enum(API, "GMT_READ_MIXED");	const global GMT_READ_MIXED = (enu != -99999) ? enu : 3

# begin enum GMT_enum_family
enu = GMT_Get_Enum(API, "GMT_IS_DATASET");	const global GMT_IS_DATASET = (enu != -99999) ? enu : 0
enu = GMT_Get_Enum(API, "GMT_IS_GRID");		const global GMT_IS_GRID  = (enu != -99999) ? enu : 1
enu = GMT_Get_Enum(API, "GMT_IS_IMAGE");	const global GMT_IS_IMAGE = (enu != -99999) ? enu : 2
enu = GMT_Get_Enum(API, "GMT_IS_PALETTE");		const global GMT_IS_PALETTE = (enu != -99999) ? enu : 3
enu = GMT_Get_Enum(API, "GMT_IS_POSTSCRIPT");	const global GMT_IS_POSTSCRIPT = (enu != -99999) ? enu : 4
enu = GMT_Get_Enum(API, "GMT_IS_MATRIX");		const global GMT_IS_MATRIX = (enu != -99999) ? enu : 5
enu = GMT_Get_Enum(API, "GMT_IS_VECTOR");		const global GMT_IS_VECTOR = (enu != -99999) ? enu : 6

enu = GMT_Get_Enum(API, "GMT_COMMENT_IS_TEXT");		const global GMT_COMMENT_IS_TEXT = (enu != -99999) ? enu : 0
enu = GMT_Get_Enum(API, "GMT_IMAGE_ALPHA_LAYER");	const global GMT_IMAGE_ALPHA_LAYER = (enu != -99999) ? enu : 8192

# begin enum GMT_module_enum
enu = GMT_Get_Enum(API, "GMT_MODULE_EXIST");	const global GMT_MODULE_EXIST = (enu != -99999) ? enu : -3
enu = GMT_Get_Enum(API, "GMT_MODULE_OPT");	const global GMT_MODULE_OPT = (enu != -99999) ? enu : -1
enu = GMT_Get_Enum(API, "GMT_MODULE_CMD");	const global GMT_MODULE_CMD = (enu != -99999) ? enu : 0
enu = GMT_Get_Enum(API, "GMT_SYNOPSIS");	const global GMT_SYNOPSIS = (enu != -99999) ? enu : 1

# begin enum GMT_io_enum
enu = GMT_Get_Enum(API, "GMT_IN");	const global GMT_IN = (enu != -99999) ? enu : 0
enu = GMT_Get_Enum(API, "GMT_OUT");	const global GMT_OUT = (enu != -99999) ? enu : 1

enu = GMT_Get_Enum(API, "GMT_ALLOC_EXTERNALLY");	const global GMT_ALLOC_EXTERNALLY = (enu != -99999) ? enu : 0
# begin enum GMT_enum_dimindex
enu = GMT_Get_Enum(API, "GMT_SEG");	const global GMT_SEG = (enu != -99999) ? enu : 1
enu = GMT_Get_Enum(API, "GMT_ROW");	const global GMT_ROW = (enu != -99999) ? enu : 2
enu = GMT_Get_Enum(API, "GMT_COL");	const global GMT_COL = (enu != -99999) ? enu : 3

const global GMT_GRID_ALL = 0		# This one is a #define

# begin enum GMT_enum_fmt
enu = GMT_Get_Enum(API, "GMT_IS_COL_FORMAT");	const global GMT_IS_COL_FORMAT = (enu != -99999) ? enu : 2

# begin enum GMT_enum_geometry
enu = GMT_Get_Enum(API, "GMT_IS_PLP");	const global GMT_IS_PLP = (enu != -99999) ? enu : 7
enu = GMT_Get_Enum(API, "GMT_IS_SURFACE");	const global GMT_IS_SURFACE = (enu != -99999) ? enu : 8
enu = GMT_Get_Enum(API, "GMT_IS_NONE");	const global GMT_IS_NONE = (enu != -99999) ? enu : 16

# begin enum GMT_enum_color
enu = GMT_Get_Enum(API, "GMT_RGB");		const global GMT_RGB  = (enu != -99999) ? enu : 0
enu = GMT_Get_Enum(API, "GMT_CMYK");	const global GMT_CMYK = (enu != -99999) ? enu : 1
enu = GMT_Get_Enum(API, "GMT_HSV");		const global GMT_HSV = (enu != -99999) ? enu : 2

# GMT_enum_cptflags
enu = GMT_Get_Enum(API, "GMT_CPT_HINGED");	const global GMT_CPT_HINGED = (enu != -99999) ? enu : 4

GMT_Destroy_Session(API);