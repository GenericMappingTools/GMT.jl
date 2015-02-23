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
typealias GMT_enum_api Uint32
const GMT_USAGE = 0
const GMT_SYNOPSIS = 1
const GMT_STR16 = 16
# end enum GMT_enum_api
const GMT_SESSION_NORMAL   = 0   # Typical mode to GMT_Create_Session
const GMT_SESSION_NOEXIT   = 1   # Call return and not exit when error
const GMT_SESSION_EXTERNAL = 2   # Called by an external API (e.g., Matlab, Julia, Python).
# begin enum GMT_enum_type
typealias GMT_enum_type Uint32
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
typealias GMT_enum_opt Uint32
const GMT_OPT_USAGE = 63
const GMT_OPT_SYNOPSIS = 94
const GMT_OPT_PARAMETER = 45
const GMT_OPT_INFILE = 60
const GMT_OPT_OUTFILE = 62
# end enum GMT_enum_opt
immutable GMT_OPTION			# Structure for a single GMT command option
    option::Uint8				# 1-char command line -<option> (e.g. D in -D) identifying the option (* if file)
    arg::Ptr{Uint8}				# If not NULL, contains the argument for this option
    next::Ptr{GMT_OPTION}
    previous::Ptr{GMT_OPTION}
end
# begin enum GMT_enum_method
typealias GMT_enum_method Uint32
const GMT_IS_FILE = 0
const GMT_IS_STREAM = 1
const GMT_IS_FDESC = 2
const GMT_IS_DUPLICATE = 3
const GMT_IS_REFERENCE = 4
# end enum GMT_enum_method
# begin enum GMT_enum_via
typealias GMT_enum_via Uint32
const GMT_VIA_NONE = 0
const GMT_VIA_VECTOR = 100
const GMT_VIA_MATRIX = 200
const GMT_VIA_OUTPUT = 2048
# end enum GMT_enum_via
# begin enum GMT_enum_family
typealias GMT_enum_family Uint32
const GMT_IS_DATASET = 0
const GMT_IS_TEXTSET = 1
const GMT_IS_GRID = 2
const GMT_IS_CPT = 3
const GMT_IS_IMAGE = 4
const GMT_IS_VECTOR = 5
const GMT_IS_MATRIX = 6
const GMT_IS_COORD = 7
const GMT_IS_PS = 8
# end enum GMT_enum_family
# begin enum GMT_enum_comment
typealias GMT_enum_comment Uint32
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
typealias GMT_io_enum Uint32
const GMT_IN = 0
const GMT_OUT = 1
const GMT_ERR = 2
# end enum GMT_io_enum
# begin enum GMT_enum_dimensions
typealias GMT_enum_dimensions Uint32
const GMT_X = 0
const GMT_Y = 1
const GMT_Z = 2
# end enum GMT_enum_dimensions
# begin enum GMT_enum_freg
typealias GMT_enum_freg Uint32
const GMT_ADD_FILES_IF_NONE = 1
const GMT_ADD_FILES_ALWAYS = 2
const GMT_ADD_STDIO_IF_NONE = 4
const GMT_ADD_STDIO_ALWAYS = 8
const GMT_ADD_EXISTING = 16
const GMT_ADD_DEFAULT = 6
# end enum GMT_enum_freg
# begin enum GMT_enum_ioset
typealias GMT_enum_ioset Uint32
const GMT_IO_DONE = 0
const GMT_IO_ASCII = 512
const GMT_IO_RESET = 32768
const GMT_IO_UNREG = 16384
# end enum GMT_enum_ioset
# begin enum GMT_enum_read
typealias GMT_enum_read Uint32
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
typealias GMT_enum_write Uint32
const GMT_WRITE_DOUBLE = 0
const GMT_WRITE_TEXT = 1
const GMT_WRITE_SEGMENT_HEADER = 2
const GMT_WRITE_TABLE_HEADER = 3
const GMT_WRITE_TABLE_START = 4
const GMT_WRITE_NOLF = 16
# end enum GMT_enum_write
# begin enum GMT_enum_header
typealias GMT_enum_header Uint32
const GMT_HEADER_OFF = 0
const GMT_HEADER_ON = 1
# end enum GMT_enum_header
# begin enum GMT_enum_dest
typealias GMT_enum_dest Uint32
const GMT_WRITE_SET = 0
const GMT_WRITE_OGR = 1
const GMT_WRITE_TABLE = 2
const GMT_WRITE_SEGMENT = 3
const GMT_WRITE_TABLE_SEGMENT = 4
# end enum GMT_enum_dest
# begin enum GMT_enum_alloc
typealias GMT_enum_alloc Uint32
const GMT_ALLOCATED_EXTERNALLY = 0
const GMT_ALLOCATED_BY_GMT = 1
# end enum GMT_enum_alloc
# begin enum GMT_enum_duplicate
typealias GMT_enum_duplicate Uint32
const GMT_DUPLICATE_NONE = 0
const GMT_DUPLICATE_ALLOC = 1
const GMT_DUPLICATE_DATA = 2
# end enum GMT_enum_duplicate
# begin enum GMT_enum_shape
typealias GMT_enum_shape Uint32
const GMT_ALLOC_NORMAL = 0
const GMT_ALLOC_VERTICAL = 4
const GMT_ALLOC_HORIZONTAL = 8
# end enum GMT_enum_shape
# begin enum GMT_enum_out
typealias GMT_enum_out Uint32
const GMT_WRITE_NORMAL = 0
const GMT_WRITE_HEADER = 1
const GMT_WRITE_SKIP = 2
# end enum GMT_enum_out
# begin enum GMT_FFT_mode
typealias GMT_FFT_mode Uint32
const GMT_FFT_FWD = 0
const GMT_FFT_INV = 1
const GMT_FFT_REAL = 0
const GMT_FFT_COMPLEX = 1
# end enum GMT_FFT_mode
# begin enum GMT_time_mode
typealias GMT_time_mode Uint32
const GMT_TIME_NONE = 0
const GMT_TIME_CLOCK = 1
const GMT_TIME_ELAPSED = 2
const GMT_TIME_RESET = 4
# end enum GMT_time_mode
# begin enum GMT_enum_verbose
typealias GMT_enum_verbose Uint32
const GMT_MSG_QUIET = 0
const GMT_MSG_NORMAL = 1
const GMT_MSG_TICTOC = 2
const GMT_MSG_COMPAT = 3
const GMT_MSG_VERBOSE = 4
const GMT_MSG_LONG_VERBOSE = 5
const GMT_MSG_DEBUG = 6
# end enum GMT_enum_verbose
# begin enum GMT_enum_reg
typealias GMT_enum_reg Uint32
const GMT_GRID_NODE_REG = 0
const GMT_GRID_PIXEL_REG = 1
const GMT_GRID_DEFAULT_REG = 1024
# end enum GMT_enum_reg
# begin enum GMT_enum_gridindex
typealias GMT_enum_gridindex Uint32
const GMT_XLO = 0
const GMT_XHI = 1
const GMT_YLO = 2
const GMT_YHI = 3
const GMT_ZLO = 4
const GMT_ZHI = 5
# end enum GMT_enum_gridindex
# begin enum GMT_enum_dimindex
typealias GMT_enum_dimindex Uint32
const GMT_TBL = 0
const GMT_SEG = 1
const GMT_ROW = 2
const GMT_COL = 3
# end enum GMT_enum_dimindex
# begin enum GMT_enum_gridio
typealias GMT_enum_gridio Uint32
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
typealias GMT_enum_grdlen Uint32
const GMT_GRID_UNIT_LEN80 = 80
const GMT_GRID_TITLE_LEN80 = 80
const GMT_GRID_VARNAME_LEN80 = 80
const GMT_GRID_COMMAND_LEN320 = 320
const GMT_GRID_REMARK_LEN160 = 160
const GMT_GRID_NAME_LEN256 = 256
const GMT_GRID_HEADER_SIZE = 892
# end enum GMT_enum_grdlen

typealias Gmt_api_error_code Uint32
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
const GMT_NOT_A_VALID_TYPE = 37
const GMT_NOT_INPUT_OBJECT = 38
const GMT_NOT_OUTPUT_OBJECT = 39
const GMT_NO_GRDHEADER = 40
const GMT_NO_INPUT = 41
const GMT_NO_OUTPUT = 42
const GMT_NO_PARAMETERS = 43
const GMT_NO_RESOURCES = 44
const GMT_N_COLS_NOT_SET = 45
const GMT_N_COLS_VARY = 46
const GMT_N_ROWS_NOT_SET = 47
const GMT_OBJECT_NOT_FOUND = 48
const GMT_OGR_ONE_TABLE_ONLY = 49
const GMT_ONLY_ONE_ALLOWED = 50
const GMT_OPTION_EXIST = 51
const GMT_OPTION_HISTORY_ERROR = 52
const GMT_OPTION_IS_NULL = 53
const GMT_OPTION_LIST_NULL = 54
const GMT_OPTION_NOT_FOUND = 55
const GMT_OPTION_SORT_ERROR = 56
const GMT_OUTPUT_NOT_SET = 57
const GMT_PADDING_NOT_ALLOWED = 58
const GMT_PARSE_ERROR = 59
const GMT_PROG_NOT_FOUND = 60
const GMT_PTR_IS_NULL = 61
const GMT_PTR_NOT_NULL = 62
const GMT_PTR_NOT_UNIQUE = 63
const GMT_READ_ONCE = 64
const GMT_RUNTIME_ERROR = 65
const GMT_SIZE_IS_ZERO = 66
const GMT_STREAM_NOT_ALLOWED = 67
const GMT_SUBSET_NOT_ALLOWED = 68
const GMT_VALUE_NOT_SET = 69
const GMT_WRITTEN_ONCE = 70
# end enum Gmt_api_error_code

immutable Array_4_Cdouble
    d1::Cdouble
    d2::Cdouble
    d3::Cdouble
    d4::Cdouble
end
immutable Array_2_Cdouble
    d1::Cdouble
    d2::Cdouble
end
immutable Array_80_Uint8
    d1::Uint8
    d2::Uint8
    d3::Uint8
    d4::Uint8
    d5::Uint8
    d6::Uint8
    d7::Uint8
    d8::Uint8
    d9::Uint8
    d10::Uint8
    d11::Uint8
    d12::Uint8
    d13::Uint8
    d14::Uint8
    d15::Uint8
    d16::Uint8
    d17::Uint8
    d18::Uint8
    d19::Uint8
    d20::Uint8
    d21::Uint8
    d22::Uint8
    d23::Uint8
    d24::Uint8
    d25::Uint8
    d26::Uint8
    d27::Uint8
    d28::Uint8
    d29::Uint8
    d30::Uint8
    d31::Uint8
    d32::Uint8
    d33::Uint8
    d34::Uint8
    d35::Uint8
    d36::Uint8
    d37::Uint8
    d38::Uint8
    d39::Uint8
    d40::Uint8
    d41::Uint8
    d42::Uint8
    d43::Uint8
    d44::Uint8
    d45::Uint8
    d46::Uint8
    d47::Uint8
    d48::Uint8
    d49::Uint8
    d50::Uint8
    d51::Uint8
    d52::Uint8
    d53::Uint8
    d54::Uint8
    d55::Uint8
    d56::Uint8
    d57::Uint8
    d58::Uint8
    d59::Uint8
    d60::Uint8
    d61::Uint8
    d62::Uint8
    d63::Uint8
    d64::Uint8
    d65::Uint8
    d66::Uint8
    d67::Uint8
    d68::Uint8
    d69::Uint8
    d70::Uint8
    d71::Uint8
    d72::Uint8
    d73::Uint8
    d74::Uint8
    d75::Uint8
    d76::Uint8
    d77::Uint8
    d78::Uint8
    d79::Uint8
    d80::Uint8
end
immutable Array_320_Uint8
    d1::Uint8
    d2::Uint8
    d3::Uint8
    d4::Uint8
    d5::Uint8
    d6::Uint8
    d7::Uint8
    d8::Uint8
    d9::Uint8
    d10::Uint8
    d11::Uint8
    d12::Uint8
    d13::Uint8
    d14::Uint8
    d15::Uint8
    d16::Uint8
    d17::Uint8
    d18::Uint8
    d19::Uint8
    d20::Uint8
    d21::Uint8
    d22::Uint8
    d23::Uint8
    d24::Uint8
    d25::Uint8
    d26::Uint8
    d27::Uint8
    d28::Uint8
    d29::Uint8
    d30::Uint8
    d31::Uint8
    d32::Uint8
    d33::Uint8
    d34::Uint8
    d35::Uint8
    d36::Uint8
    d37::Uint8
    d38::Uint8
    d39::Uint8
    d40::Uint8
    d41::Uint8
    d42::Uint8
    d43::Uint8
    d44::Uint8
    d45::Uint8
    d46::Uint8
    d47::Uint8
    d48::Uint8
    d49::Uint8
    d50::Uint8
    d51::Uint8
    d52::Uint8
    d53::Uint8
    d54::Uint8
    d55::Uint8
    d56::Uint8
    d57::Uint8
    d58::Uint8
    d59::Uint8
    d60::Uint8
    d61::Uint8
    d62::Uint8
    d63::Uint8
    d64::Uint8
    d65::Uint8
    d66::Uint8
    d67::Uint8
    d68::Uint8
    d69::Uint8
    d70::Uint8
    d71::Uint8
    d72::Uint8
    d73::Uint8
    d74::Uint8
    d75::Uint8
    d76::Uint8
    d77::Uint8
    d78::Uint8
    d79::Uint8
    d80::Uint8
    d81::Uint8
    d82::Uint8
    d83::Uint8
    d84::Uint8
    d85::Uint8
    d86::Uint8
    d87::Uint8
    d88::Uint8
    d89::Uint8
    d90::Uint8
    d91::Uint8
    d92::Uint8
    d93::Uint8
    d94::Uint8
    d95::Uint8
    d96::Uint8
    d97::Uint8
    d98::Uint8
    d99::Uint8
    d100::Uint8
    d101::Uint8
    d102::Uint8
    d103::Uint8
    d104::Uint8
    d105::Uint8
    d106::Uint8
    d107::Uint8
    d108::Uint8
    d109::Uint8
    d110::Uint8
    d111::Uint8
    d112::Uint8
    d113::Uint8
    d114::Uint8
    d115::Uint8
    d116::Uint8
    d117::Uint8
    d118::Uint8
    d119::Uint8
    d120::Uint8
    d121::Uint8
    d122::Uint8
    d123::Uint8
    d124::Uint8
    d125::Uint8
    d126::Uint8
    d127::Uint8
    d128::Uint8
    d129::Uint8
    d130::Uint8
    d131::Uint8
    d132::Uint8
    d133::Uint8
    d134::Uint8
    d135::Uint8
    d136::Uint8
    d137::Uint8
    d138::Uint8
    d139::Uint8
    d140::Uint8
    d141::Uint8
    d142::Uint8
    d143::Uint8
    d144::Uint8
    d145::Uint8
    d146::Uint8
    d147::Uint8
    d148::Uint8
    d149::Uint8
    d150::Uint8
    d151::Uint8
    d152::Uint8
    d153::Uint8
    d154::Uint8
    d155::Uint8
    d156::Uint8
    d157::Uint8
    d158::Uint8
    d159::Uint8
    d160::Uint8
    d161::Uint8
    d162::Uint8
    d163::Uint8
    d164::Uint8
    d165::Uint8
    d166::Uint8
    d167::Uint8
    d168::Uint8
    d169::Uint8
    d170::Uint8
    d171::Uint8
    d172::Uint8
    d173::Uint8
    d174::Uint8
    d175::Uint8
    d176::Uint8
    d177::Uint8
    d178::Uint8
    d179::Uint8
    d180::Uint8
    d181::Uint8
    d182::Uint8
    d183::Uint8
    d184::Uint8
    d185::Uint8
    d186::Uint8
    d187::Uint8
    d188::Uint8
    d189::Uint8
    d190::Uint8
    d191::Uint8
    d192::Uint8
    d193::Uint8
    d194::Uint8
    d195::Uint8
    d196::Uint8
    d197::Uint8
    d198::Uint8
    d199::Uint8
    d200::Uint8
    d201::Uint8
    d202::Uint8
    d203::Uint8
    d204::Uint8
    d205::Uint8
    d206::Uint8
    d207::Uint8
    d208::Uint8
    d209::Uint8
    d210::Uint8
    d211::Uint8
    d212::Uint8
    d213::Uint8
    d214::Uint8
    d215::Uint8
    d216::Uint8
    d217::Uint8
    d218::Uint8
    d219::Uint8
    d220::Uint8
    d221::Uint8
    d222::Uint8
    d223::Uint8
    d224::Uint8
    d225::Uint8
    d226::Uint8
    d227::Uint8
    d228::Uint8
    d229::Uint8
    d230::Uint8
    d231::Uint8
    d232::Uint8
    d233::Uint8
    d234::Uint8
    d235::Uint8
    d236::Uint8
    d237::Uint8
    d238::Uint8
    d239::Uint8
    d240::Uint8
    d241::Uint8
    d242::Uint8
    d243::Uint8
    d244::Uint8
    d245::Uint8
    d246::Uint8
    d247::Uint8
    d248::Uint8
    d249::Uint8
    d250::Uint8
    d251::Uint8
    d252::Uint8
    d253::Uint8
    d254::Uint8
    d255::Uint8
    d256::Uint8
    d257::Uint8
    d258::Uint8
    d259::Uint8
    d260::Uint8
    d261::Uint8
    d262::Uint8
    d263::Uint8
    d264::Uint8
    d265::Uint8
    d266::Uint8
    d267::Uint8
    d268::Uint8
    d269::Uint8
    d270::Uint8
    d271::Uint8
    d272::Uint8
    d273::Uint8
    d274::Uint8
    d275::Uint8
    d276::Uint8
    d277::Uint8
    d278::Uint8
    d279::Uint8
    d280::Uint8
    d281::Uint8
    d282::Uint8
    d283::Uint8
    d284::Uint8
    d285::Uint8
    d286::Uint8
    d287::Uint8
    d288::Uint8
    d289::Uint8
    d290::Uint8
    d291::Uint8
    d292::Uint8
    d293::Uint8
    d294::Uint8
    d295::Uint8
    d296::Uint8
    d297::Uint8
    d298::Uint8
    d299::Uint8
    d300::Uint8
    d301::Uint8
    d302::Uint8
    d303::Uint8
    d304::Uint8
    d305::Uint8
    d306::Uint8
    d307::Uint8
    d308::Uint8
    d309::Uint8
    d310::Uint8
    d311::Uint8
    d312::Uint8
    d313::Uint8
    d314::Uint8
    d315::Uint8
    d316::Uint8
    d317::Uint8
    d318::Uint8
    d319::Uint8
    d320::Uint8
end
immutable Array_160_Uint8
    d1::Uint8
    d2::Uint8
    d3::Uint8
    d4::Uint8
    d5::Uint8
    d6::Uint8
    d7::Uint8
    d8::Uint8
    d9::Uint8
    d10::Uint8
    d11::Uint8
    d12::Uint8
    d13::Uint8
    d14::Uint8
    d15::Uint8
    d16::Uint8
    d17::Uint8
    d18::Uint8
    d19::Uint8
    d20::Uint8
    d21::Uint8
    d22::Uint8
    d23::Uint8
    d24::Uint8
    d25::Uint8
    d26::Uint8
    d27::Uint8
    d28::Uint8
    d29::Uint8
    d30::Uint8
    d31::Uint8
    d32::Uint8
    d33::Uint8
    d34::Uint8
    d35::Uint8
    d36::Uint8
    d37::Uint8
    d38::Uint8
    d39::Uint8
    d40::Uint8
    d41::Uint8
    d42::Uint8
    d43::Uint8
    d44::Uint8
    d45::Uint8
    d46::Uint8
    d47::Uint8
    d48::Uint8
    d49::Uint8
    d50::Uint8
    d51::Uint8
    d52::Uint8
    d53::Uint8
    d54::Uint8
    d55::Uint8
    d56::Uint8
    d57::Uint8
    d58::Uint8
    d59::Uint8
    d60::Uint8
    d61::Uint8
    d62::Uint8
    d63::Uint8
    d64::Uint8
    d65::Uint8
    d66::Uint8
    d67::Uint8
    d68::Uint8
    d69::Uint8
    d70::Uint8
    d71::Uint8
    d72::Uint8
    d73::Uint8
    d74::Uint8
    d75::Uint8
    d76::Uint8
    d77::Uint8
    d78::Uint8
    d79::Uint8
    d80::Uint8
    d81::Uint8
    d82::Uint8
    d83::Uint8
    d84::Uint8
    d85::Uint8
    d86::Uint8
    d87::Uint8
    d88::Uint8
    d89::Uint8
    d90::Uint8
    d91::Uint8
    d92::Uint8
    d93::Uint8
    d94::Uint8
    d95::Uint8
    d96::Uint8
    d97::Uint8
    d98::Uint8
    d99::Uint8
    d100::Uint8
    d101::Uint8
    d102::Uint8
    d103::Uint8
    d104::Uint8
    d105::Uint8
    d106::Uint8
    d107::Uint8
    d108::Uint8
    d109::Uint8
    d110::Uint8
    d111::Uint8
    d112::Uint8
    d113::Uint8
    d114::Uint8
    d115::Uint8
    d116::Uint8
    d117::Uint8
    d118::Uint8
    d119::Uint8
    d120::Uint8
    d121::Uint8
    d122::Uint8
    d123::Uint8
    d124::Uint8
    d125::Uint8
    d126::Uint8
    d127::Uint8
    d128::Uint8
    d129::Uint8
    d130::Uint8
    d131::Uint8
    d132::Uint8
    d133::Uint8
    d134::Uint8
    d135::Uint8
    d136::Uint8
    d137::Uint8
    d138::Uint8
    d139::Uint8
    d140::Uint8
    d141::Uint8
    d142::Uint8
    d143::Uint8
    d144::Uint8
    d145::Uint8
    d146::Uint8
    d147::Uint8
    d148::Uint8
    d149::Uint8
    d150::Uint8
    d151::Uint8
    d152::Uint8
    d153::Uint8
    d154::Uint8
    d155::Uint8
    d156::Uint8
    d157::Uint8
    d158::Uint8
    d159::Uint8
    d160::Uint8
end
immutable Array_4_Uint32
    d1::Uint32
    d2::Uint32
    d3::Uint32
    d4::Uint32
end
immutable Array_256_Uint8
    d1::Uint8
    d2::Uint8
    d3::Uint8
    d4::Uint8
    d5::Uint8
    d6::Uint8
    d7::Uint8
    d8::Uint8
    d9::Uint8
    d10::Uint8
    d11::Uint8
    d12::Uint8
    d13::Uint8
    d14::Uint8
    d15::Uint8
    d16::Uint8
    d17::Uint8
    d18::Uint8
    d19::Uint8
    d20::Uint8
    d21::Uint8
    d22::Uint8
    d23::Uint8
    d24::Uint8
    d25::Uint8
    d26::Uint8
    d27::Uint8
    d28::Uint8
    d29::Uint8
    d30::Uint8
    d31::Uint8
    d32::Uint8
    d33::Uint8
    d34::Uint8
    d35::Uint8
    d36::Uint8
    d37::Uint8
    d38::Uint8
    d39::Uint8
    d40::Uint8
    d41::Uint8
    d42::Uint8
    d43::Uint8
    d44::Uint8
    d45::Uint8
    d46::Uint8
    d47::Uint8
    d48::Uint8
    d49::Uint8
    d50::Uint8
    d51::Uint8
    d52::Uint8
    d53::Uint8
    d54::Uint8
    d55::Uint8
    d56::Uint8
    d57::Uint8
    d58::Uint8
    d59::Uint8
    d60::Uint8
    d61::Uint8
    d62::Uint8
    d63::Uint8
    d64::Uint8
    d65::Uint8
    d66::Uint8
    d67::Uint8
    d68::Uint8
    d69::Uint8
    d70::Uint8
    d71::Uint8
    d72::Uint8
    d73::Uint8
    d74::Uint8
    d75::Uint8
    d76::Uint8
    d77::Uint8
    d78::Uint8
    d79::Uint8
    d80::Uint8
    d81::Uint8
    d82::Uint8
    d83::Uint8
    d84::Uint8
    d85::Uint8
    d86::Uint8
    d87::Uint8
    d88::Uint8
    d89::Uint8
    d90::Uint8
    d91::Uint8
    d92::Uint8
    d93::Uint8
    d94::Uint8
    d95::Uint8
    d96::Uint8
    d97::Uint8
    d98::Uint8
    d99::Uint8
    d100::Uint8
    d101::Uint8
    d102::Uint8
    d103::Uint8
    d104::Uint8
    d105::Uint8
    d106::Uint8
    d107::Uint8
    d108::Uint8
    d109::Uint8
    d110::Uint8
    d111::Uint8
    d112::Uint8
    d113::Uint8
    d114::Uint8
    d115::Uint8
    d116::Uint8
    d117::Uint8
    d118::Uint8
    d119::Uint8
    d120::Uint8
    d121::Uint8
    d122::Uint8
    d123::Uint8
    d124::Uint8
    d125::Uint8
    d126::Uint8
    d127::Uint8
    d128::Uint8
    d129::Uint8
    d130::Uint8
    d131::Uint8
    d132::Uint8
    d133::Uint8
    d134::Uint8
    d135::Uint8
    d136::Uint8
    d137::Uint8
    d138::Uint8
    d139::Uint8
    d140::Uint8
    d141::Uint8
    d142::Uint8
    d143::Uint8
    d144::Uint8
    d145::Uint8
    d146::Uint8
    d147::Uint8
    d148::Uint8
    d149::Uint8
    d150::Uint8
    d151::Uint8
    d152::Uint8
    d153::Uint8
    d154::Uint8
    d155::Uint8
    d156::Uint8
    d157::Uint8
    d158::Uint8
    d159::Uint8
    d160::Uint8
    d161::Uint8
    d162::Uint8
    d163::Uint8
    d164::Uint8
    d165::Uint8
    d166::Uint8
    d167::Uint8
    d168::Uint8
    d169::Uint8
    d170::Uint8
    d171::Uint8
    d172::Uint8
    d173::Uint8
    d174::Uint8
    d175::Uint8
    d176::Uint8
    d177::Uint8
    d178::Uint8
    d179::Uint8
    d180::Uint8
    d181::Uint8
    d182::Uint8
    d183::Uint8
    d184::Uint8
    d185::Uint8
    d186::Uint8
    d187::Uint8
    d188::Uint8
    d189::Uint8
    d190::Uint8
    d191::Uint8
    d192::Uint8
    d193::Uint8
    d194::Uint8
    d195::Uint8
    d196::Uint8
    d197::Uint8
    d198::Uint8
    d199::Uint8
    d200::Uint8
    d201::Uint8
    d202::Uint8
    d203::Uint8
    d204::Uint8
    d205::Uint8
    d206::Uint8
    d207::Uint8
    d208::Uint8
    d209::Uint8
    d210::Uint8
    d211::Uint8
    d212::Uint8
    d213::Uint8
    d214::Uint8
    d215::Uint8
    d216::Uint8
    d217::Uint8
    d218::Uint8
    d219::Uint8
    d220::Uint8
    d221::Uint8
    d222::Uint8
    d223::Uint8
    d224::Uint8
    d225::Uint8
    d226::Uint8
    d227::Uint8
    d228::Uint8
    d229::Uint8
    d230::Uint8
    d231::Uint8
    d232::Uint8
    d233::Uint8
    d234::Uint8
    d235::Uint8
    d236::Uint8
    d237::Uint8
    d238::Uint8
    d239::Uint8
    d240::Uint8
    d241::Uint8
    d242::Uint8
    d243::Uint8
    d244::Uint8
    d245::Uint8
    d246::Uint8
    d247::Uint8
    d248::Uint8
    d249::Uint8
    d250::Uint8
    d251::Uint8
    d252::Uint8
    d253::Uint8
    d254::Uint8
    d255::Uint8
    d256::Uint8
end

immutable Array_2_Csize_t
	d1::Csize_t
	d2::Csize_t
end
immutable Array_3_Csize_t
	d1::Csize_t
	d2::Csize_t
	d3::Csize_t
end

immutable Array_2_Cint
    d1::Cint
    d2::Cint
end
immutable Array_3_Cint
    d1::Cint
    d2::Cint
    d3::Cint
end
immutable Array_4_Uint8
    d1::Uint8
    d2::Uint8
    d3::Uint8
    d4::Uint8
end
immutable Array_2_Uint32
    d1::Uint32
    d2::Uint32
end
immutable Array_2_Uint64
	d1::Uint64
	d2::Uint64
end
immutable Array_2_Cbool
	d1::Bool
	d2::Bool
end

type GMT_GRID_HEADER
    nx::Uint32
    ny::Uint32
    registration::Uint32
    wesn::Array_4_Cdouble
    z_min::Cdouble
    z_max::Cdouble
    inc::Array_2_Cdouble
    z_scale_factor::Cdouble
    z_add_offset::Cdouble
    x_units::Array_80_Uint8
    y_units::Array_80_Uint8
    z_units::Array_80_Uint8
    title::Array_80_Uint8
    command::Array_320_Uint8
    remark::Array_160_Uint8
    _type::Uint32
    bits::Uint32
    complex_mode::Uint32
    mx::Uint32
    my::Uint32
    nm::Csize_t
    size::Csize_t
    n_alloc::Csize_t
    trendmode::Uint32
    arrangement::Uint32
    n_bands::Uint32
    pad::Array_4_Uint32
    BC::Array_4_Uint32
    grdtype::Uint32
    name::Array_256_Uint8
    varname::Array_80_Uint8
    ProjRefPROJ4::Ptr{Uint8}
    ProjRefWKT::Ptr{Uint8}
    row_order::Cint
    z_id::Cint
    ncid::Cint
    xy_dim::Array_2_Cint
    t_index::Array_3_Csize_t
    data_offset::Csize_t
    stride::Uint32
    nan_value::Cfloat
    xy_off::Cdouble
    r_inc::Array_2_Cdouble
    flags::Array_4_Uint8
    pocket::Ptr{Uint8}
    bcr_threshold::Cdouble
    bcr_interpolant::Uint32
    bcr_n::Uint32
    nxp::Uint32
    nyp::Uint32
    no_BC::Uint32
    gn::Uint32
    gs::Uint32
    is_netcdf4::Uint32
    z_chunksize::Array_2_Csize_t
    z_shuffle::Uint32
    z_deflate_level::Uint32
    z_scale_autoadust::Uint32
    z_offset_autoadust::Uint32
    xy_adjust::Array_2_Uint32
    xy_mode::Array_2_Uint32
    xy_unit::Array_2_Uint32
    xy_unit_to_meter::Array_2_Cdouble
end
type GMT_GRID
    header::Ptr{GMT_GRID_HEADER}
    data::Ptr{Cfloat}
    id::Uint32
    alloc_level::Uint32
    alloc_mode::GMT_enum_alloc
    extra::Ptr{Void}
end
# begin enum GMT_enum_geometry
typealias GMT_enum_geometry Uint32
const GMT_IS_POINT = 1
const GMT_IS_LINE = 2
const GMT_IS_POLY = 4
const GMT_IS_PLP = 7
const GMT_IS_SURFACE = 8
const GMT_IS_NONE = 16
# end enum GMT_enum_geometry
# begin enum GMT_enum_pol
typealias GMT_enum_pol Uint32
const GMT_IS_PERIMETER = 0
const GMT_IS_HOLE = 1
# end enum GMT_enum_pol
# begin enum GMT_enum_ascii_input_return
typealias GMT_enum_ascii_input_return Uint32
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
immutable Array_4_Ptr
    d1::Ptr{Uint8}
    d2::Ptr{Uint8}
    d3::Ptr{Uint8}
    d4::Ptr{Uint8}
end
immutable GMT_OGR
    geometry::Uint32
    n_aspatial::Uint32
    region::Ptr{Uint8}
    proj::Array_4_Ptr
    _type::Ptr{Uint32}
    name::Ptr{Ptr{Uint8}}
    pol_mode::GMT_enum_pol
    tvalue::Ptr{Ptr{Uint8}}
    dvalue::Ptr{Cdouble}
end
immutable GMT_OGR_SEG
    pol_mode::GMT_enum_pol
    n_aspatial::Uint32
    tvalue::Ptr{Ptr{Uint8}}
    dvalue::Ptr{Cdouble}
end
immutable Array_2_Ptr
    d1::Ptr{Uint8}
    d2::Ptr{Uint8}
end
immutable GMT_DATASEGMENT
    n_rows::Uint64
    n_columns::Uint64
    min::Ptr{Cdouble}
    max::Ptr{Cdouble}
    coord::Ptr{Ptr{Cdouble}}
    label::Ptr{Uint8}
    header::Ptr{Uint8}
    mode::GMT_enum_out
    pol_mode::GMT_enum_pol
    id::Uint64
    n_alloc::Cint
    range::Cint
    pole::Cint
    dist::Cdouble
    lat_limit::Cdouble
    ogr::Ptr{GMT_OGR_SEG}
    next::Ptr{GMT_DATASEGMENT}
    file::Array_2_Ptr
end
immutable GMT_DATATABLE
    n_headers::Uint32
    n_columns::Uint64
    n_segments::Uint64
    n_records::Uint64
    min::Ptr{Cdouble}
    max::Ptr{Cdouble}
    header::Ptr{Ptr{Uint8}}
    segment::Ptr{Ptr{GMT_DATASEGMENT}}
    id::Uint64
    n_alloc::Cint
    mode::GMT_enum_out
    ogr::Ptr{GMT_OGR}
    file::Array_2_Ptr
end
immutable Array_4_Uint64
    d1::Uint64
    d2::Uint64
    d3::Uint64
    d4::Uint64
end
immutable GMT_DATASET
    n_tables::Uint64
    n_columns::Uint64
    n_segments::Uint64
    n_records::Uint64
    min::Ptr{Cdouble}
    max::Ptr{Cdouble}
    table::Ptr{Ptr{GMT_DATATABLE}}
    id::Uint64
    n_alloc::Cint
    dim::Array_4_Uint64
    geometry::Uint32
    alloc_level::Uint32
    io_mode::GMT_enum_dest
    alloc_mode::GMT_enum_alloc
    file::Array_2_Ptr
end
immutable GMT_TEXTSEGMENT
    n_rows::Uint64
    record::Ptr{Ptr{Uint8}}
    label::Ptr{Uint8}
    header::Ptr{Uint8}
    id::Uint64
    mode::GMT_enum_out
    n_alloc::Cint
    file::Array_2_Ptr
    tvalue::Ptr{Ptr{Uint8}}
end
immutable GMT_TEXTTABLE
    n_headers::Uint32
    n_segments::Uint64
    n_records::Uint64
    header::Ptr{Ptr{Uint8}}
    segment::Ptr{Ptr{GMT_TEXTSEGMENT}}
    id::Uint64
    n_alloc::Cint
    mode::GMT_enum_out
    file::Array_2_Ptr
end
immutable GMT_TEXTSET
    n_tables::Uint64
    n_segments::Uint64
    n_records::Uint64
    table::Ptr{Ptr{GMT_TEXTTABLE}}
    id::Uint64
    n_alloc::Cint
    geometry::Uint32
    alloc_level::Uint32
    io_mode::GMT_enum_dest
    alloc_mode::GMT_enum_alloc
    file::Array_2_Ptr
end
# begin enum GMT_enum_color
typealias GMT_enum_color Uint32
const GMT_RGB = 0
const GMT_CMYK = 1
const GMT_HSV = 2
const GMT_COLORINT = 4
const GMT_NO_COLORNAMES = 8
# end enum GMT_enum_color
# begin enum GMT_enum_bfn
typealias GMT_enum_bfn Uint32
const GMT_BGD = 0
const GMT_FGD = 1
const GMT_NAN = 2
# end enum GMT_enum_bfn
# begin enum GMT_enum_cpt
typealias GMT_enum_cpt Uint32
const GMT_CPT_REQUIRED = 0
const GMT_CPT_OPTIONAL = 1
# end enum GMT_enum_cpt
# begin enum GMT_enum_cptflags
typealias GMT_enum_cptflags Uint32
const GMT_CPT_NO_BNF = 1
const GMT_CPT_EXTEND_BNF = 2
# end enum GMT_enum_cptflags
immutable GMT_FILL
	rgb::Array_4_Cdouble
	f_rgb::Array_4_Cdouble
	b_rgb::Array_4_Cdouble
	use_pattern::Bool
	pattern_no::Int32
	dpi::Uint32
	pattern::Array_256_Uint8		# was char pattern[GMT_BUFSIZ];
end
immutable GMT_LUT
    z_low::Cdouble
    z_high::Cdouble
    i_dz::Cdouble
    rgb_low::Array_4_Cdouble
    rgb_high::Array_4_Cdouble
    rgb_diff::Array_4_Cdouble
    hsv_low::Array_4_Cdouble
    hsv_high::Array_4_Cdouble
    hsv_diff::Array_4_Cdouble
    annot::Uint32
    skip::Uint32
    fill::Ptr{GMT_FILL}
    label::Ptr{Uint8}
end
immutable GMT_BFN_COLOR
    rgb::Array_4_Cdouble
    hsv::Array_4_Cdouble
    skip::Uint32
    fill::Ptr{GMT_FILL}
end
immutable Array_3_GMT_BFN_COLOR
    d1::GMT_BFN_COLOR
    d2::GMT_BFN_COLOR
    d3::GMT_BFN_COLOR
end
immutable GMT_PALETTE
    n_headers::Uint32
    n_colors::Uint32
    cpt_flags::Uint32
    range::Ptr{GMT_LUT}
    patch::Array_3_GMT_BFN_COLOR
    header::Ptr{Ptr{Uint8}}
    id::Uint64
    alloc_mode::GMT_enum_alloc
    alloc_level::Uint32
    model::Uint32
    is_gray::Uint32
    is_bw::Uint32
    is_continuous::Uint32
    has_pattern::Uint32
    skip::Uint32
    categorical::Uint32
    z_adjust::Array_2_Uint32
    z_mode::Array_2_Uint32
    z_unit::Array_2_Uint32
    z_unit_to_meter::Array_2_Cdouble
end
immutable GMT_IMAGE
    _type::GMT_enum_type
    ColorMap::Ptr{Cint}
    header::Ptr{GMT_GRID_HEADER}
    data::Ptr{Cuchar}
    id::Uint64
    alloc_level::Uint32
    alloc_mode::GMT_enum_alloc
    ColorInterp::Ptr{Uint8}
end
immutable GMT_UNIVECTOR
	uc1::Ptr{Uint8}
	sc1::Ptr{Int8}
	ui2::Ptr{Uint16}
	si2::Ptr{Int16}
	ui4::Ptr{Uint32}
	si4::Ptr{Int32}
	ui8::Ptr{Uint64}
	si8::Ptr{Int64}
	f4::Ptr{Float32}
	f8::Ptr{Float64}
end

immutable GMT_VECTOR
    n_columns::Uint64
    n_rows::Uint64
    registration::GMT_enum_reg
    _type::Ptr{GMT_enum_type}
    data::Ptr{GMT_UNIVECTOR}
    range::Array_2_Cdouble
    command::Array_320_Uint8
    remark::Array_160_Uint8
    id::Uint64
    alloc_level::Uint32
    alloc_mode::GMT_enum_alloc
end
# begin enum GMT_enum_fmt
typealias GMT_enum_fmt Uint32
const GMT_IS_ROW_FORMAT = 0
const GMT_IS_COL_FORMAT = 1
# end enum GMT_enum_fmt
immutable Array_6_Cdouble
    d1::Cdouble
    d2::Cdouble
    d3::Cdouble
    d4::Cdouble
    d5::Cdouble
    d6::Cdouble
end

type GMT_MATRIX
	n_rows::Uint64
	n_columns::Uint64
	n_layers::Uint64
	shape::Uint32
	registration::Uint32
	dim::Csize_t
	size::Csize_t
	_type::Uint32
	range::Array_6_Cdouble
#	data::GMT_UNIVECTOR
#	data::Union(Ptr{Uint8},Ptr{Int8},Ptr{Uint16},Ptr{Int16},Ptr{Uint32},Ptr{Int32},
#		Ptr{Uint64},Ptr{Int64},Ptr{Float32},Ptr{Float64})
    data::Ptr{Void}
	command::Array_320_Uint8
	remark::Array_160_Uint8
	id::Uint64
	alloc_level::Uint32
	alloc_mode::Uint32
end

type GMT_RESOURCE
    family::Uint32          # GMT data family, i.e., GMT_IS_DATASET, GMT_IS_GRID, etc.
    geometry::Uint32        # One of the recognized GMT geometries
    direction::Uint32       # Either GMT_IN or GMT_OUT
    option::Ptr{GMT_OPTION} # Pointer to the corresponding module option
    object_ID::Cint         # Object ID returned by GMT_Register_IO
    pos::Cint               # Corresponding index into external object in|out arrays
    object::Ptr{Void}       # Pointer to the registered GMT object
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

immutable Gmt_libinfo
	name::Ptr{Uint8}	# Library tag name [without leading "lib" and extension], e.g. "gmt", "gmtsuppl" */
	path::Ptr{Uint8}	# Full path to library as given in GMT_CUSTOM_LIBS */
	skip::Ptr{Bool}		# true if we tried to open it and it was not available the first time */
	handle::Ptr{Void}	# Handle to the shared library, returned by dlopen or dlopen_special */
end

struct GMT_SESSION {
	# These are parameters that is set once at the start of a GMT session and
	# are essentially read-only constants for the duration of the session */
	FILE *std[3];			/* Pointers for standard input, output, and error */
	void *(*input_ascii) (struct GMT_CTRL *, FILE *, uint64_t *, int *);	/* Pointer to function reading ascii tables only */
	int (*output_ascii) (struct GMT_CTRL *, FILE *, uint64_t, double *);	/* Pointer to function writing ascii tables only */
	n_fonts::Uint32				# Total number of fonts returned by GMT_init_fonts */
	n_user_media::Uint32		# Total number of user media returned by gmt_load_user_media */
	min_meminc::Csize_t			# with -DMEMDEBUG, sets min/max memory increments */
	max_meminc::Csize_t
	f_NaN::Float32				# Holds the IEEE NaN for floats */
	d_NaN::Float64				# Holds the IEEE NaN for doubles */
	no_rgb::Array_4_Cdouble		# To hold {-1, -1, -1, 0} when needed */
	double u2u[4][4];		/* u2u is the 4x4 conversion matrix for cm, inch, m, pt */
	char unit_name[4][8];		/* Full name of the 4 units cm, inch, m, pt */
	struct GMT_HASH rgb_hashnode[GMT_N_COLOR_NAMES];/* Used to translate colornames to r/g/b */
	rgb_hashnode_init::Bool		# true once the rgb_hashnode array has been loaded; false otherwise */
	n_shorthands::Uint32		# Length of arrray with shorthand information */
	char *grdformat[GMT_N_GRD_FORMATS];	/* Type and description of grid format */
	int (*readinfo[GMT_N_GRD_FORMATS]) (struct GMT_CTRL *, struct GMT_GRID_HEADER *);	/* Pointers to grid read header functions */
	int (*updateinfo[GMT_N_GRD_FORMATS]) (struct GMT_CTRL *, struct GMT_GRID_HEADER *);	/* Pointers to grid update header functions */
	int (*writeinfo[GMT_N_GRD_FORMATS]) (struct GMT_CTRL *, struct GMT_GRID_HEADER *);	/* Pointers to grid write header functions */
	int (*readgrd[GMT_N_GRD_FORMATS]) (struct GMT_CTRL *, struct GMT_GRID_HEADER *, float *, double *, unsigned int *, unsigned int);	/* Pointers to grid read functions */
	int (*writegrd[GMT_N_GRD_FORMATS]) (struct GMT_CTRL *, struct GMT_GRID_HEADER *, float *, double *, unsigned int *, unsigned int);	/* Pointers to grid read functions */
	int (*fft1d[k_n_fft_algorithms]) (struct GMT_CTRL *, float *, unsigned int, int, unsigned int);	/* Pointers to available 1-D FFT functions (or NULL if not configured) */
	int (*fft2d[k_n_fft_algorithms]) (struct GMT_CTRL *, float *, unsigned int, unsigned int, int, unsigned int);	/* Pointers to available 2-D FFT functions (or NULL if not configured) */
	# This part contains pointers that may point to additional memory outside this struct
	DCWDIR::Ptr{Uint8}				# Path to the DCW directory
	GSHHGDIR::Ptr{Uint8}			# Path to the GSHHG directory
	SHAREDIR::Ptr{Uint8}			# Path to the GMT share directory
	HOMEDIR::Ptr{Uint8}				# Path to the user's home directory
	USERDIR::Ptr{Uint8}				# Path to the user's GMT settings directory
	DATADIR::Ptr{Uint8}				# Path to one or more directories with data sets
	TMPDIR::Ptr{Uint8}				# Path to the directory directory for isolation mode
	CUSTOM_LIBS::Ptr{Uint8}			# Names of one or more comma-separated GMT-compatible shared libraries
	user_media_name::Ptr{Ptr{Uint8}}		# Length of array with custom media dimensions
	font::Ptr{GMT_FONTSPEC}			# Array with font names and height specification
	user_media::Ptr{GMT_MEDIA}		# Array with custom media dimensions
	shorthand::Ptr{GMT_SHORTHAND}	# Array with info about shorthand file extension magic
};

struct GMT_COMMON {
	/* Structure with all information given via the common GMT command-line options -R -J .. */
	struct synopsis {	/* \0 (zero) or ^ */
		bool active;
		bool extended;	/* + to also show non-common options */
	} synopsis;
	struct B {	/* -B<params> */
		bool active[2];	/* 0 = primary annotation, 1 = secondary annotations */
		int mode;	/* 5 = GMT 5 syntax, 4 = GMT 4 syntax, 1 = Either, -1 = mix (error), 0 = not set yet */
		char string[2][GMT_LEN256];
	} B;	
	struct API_I {	/* -I<xinc>[/<yinc>] grids only, and for API use only */
		bool active;
		double inc[2];
	} API_I;	
	struct J {	/* -J<params> */
		bool active, zactive;
		unsigned int id;
		double par[6];
		char string[GMT_LEN256];
	} J;		
	struct K {	/* -K */
		bool active;
	} K;	
	struct O {	/* -O */
		bool active;
	} O;
	struct P {	/* -P */
		bool active;
	} P;
	struct R {	/* -Rw/e/s/n[/z_min/z_max][r] */
		bool active;
		bool oblique;	/* true when -R...r was given (oblique map, probably), else false (map borders are meridians/parallels) */
		double wesn[6];		/* Boundaries of west, east, south, north, low-z and hi-z */
		char string[GMT_LEN256];
	} R;
	struct U {	/* -U */
		bool active;
		unsigned int just;
		double x, y;
		char *label;		/* Content not counted by sizeof (struct) */
	} U;
	struct V {	/* -V */
		bool active;
	} V;
	struct X {	/* -X */
		bool active;
		double off;
		char mode;	/* r, a, or c */
	} X;
	struct Y {	/* -Y */
		bool active;
		double off;
		char mode;	/* r, a, or c */
	} Y;
	struct a {	/* -a<col>=<name>[:<type>][,col>=<name>[:<type>], etc][+g<geometry>] */
		bool active;
		unsigned int geometry;
		unsigned int n_aspatial;
		bool clip;		/* true if we wish to clip lines/polygons at Dateline [false] */
		bool output;		/* true when we wish to build OGR output */
		int col[MAX_ASPATIAL];	/* Col id, include negative items such as GMT_IS_T (-5) */
		int ogr[MAX_ASPATIAL];	/* Column order, or -1 if not set */
		unsigned int type[MAX_ASPATIAL];
		char *name[MAX_ASPATIAL];
	} a;
	struct b {	/* -b[i][o][s|S][d|D][#cols][cvar1/var2/...] */
		bool active[2];		/* true if current input/output is in native binary format */
		bool o_delay;		/* true if we dont know number of output columns until we have read at least one input record */
		enum GMT_swap_direction swab[2];	/* k_swap_in or k_swap_out if current binary input/output must be byte-swapped, else k_swap_none */
		uint64_t ncol[2];		/* Number of expected columns of input/output
						   0 means it will be determined by program */
		char type[2];			/* Default column type, if set [d for double] */
		char varnames[GMT_BUFSIZ];	/* List of variable names to be input/output in netCDF mode [GMT4 COMPATIBILITY ONLY] */
	} b;
	struct c {	/* -c */
		bool active;
		unsigned int copies;
	} c;
	struct f {	# -f[i|o]<col>|<colrange>[t|T|g],.. */
		bool active[2];	/* For GMT_IN|OUT */
	} f;
	struct g {	/* -g[+]x|x|y|Y|d|Y<gap>[unit]  */
		bool active;
		unsigned int n_methods;			/* How many different criteria to apply */
		uint64_t n_col;				/* Largest column-number needed to be read */
		bool match_all;			/* If true then all specified criteria must be met to be a gap [default is any of them] */
		enum GMT_enum_gaps method[GMT_N_GAP_METHODS];	/* How distances are computed for each criteria */
		uint64_t col[GMT_N_GAP_METHODS];	/* Which column to use (-1 for x,y distance) */
		double gap[GMT_N_GAP_METHODS];		/* The critical distances for each criteria */
		double (*get_dist[GMT_N_GAP_METHODS]) (struct GMT_CTRL *GMT, uint64_t);	/* Pointers to functions that compute those distances */
	} g;
	struct h {	/* -h[i|o][<nrecs>][+d][+c][+r<remark>][+t<title>] */
		bool active;
		bool add_colnames;
		unsigned int mode;
		unsigned int n_recs;
		char *title;
		char *remark;
		char *colnames;	/* Not set by -h but maintained here */
	} h;	
	struct i {	/* -i<col>|<colrange>,.. */
		bool active;
		uint64_t n_cols;
	} i;
	struct n {	/* -n[b|c|l|n][+a][+b<BC>][+c][+t<threshold>] */
		bool active;
		bool antialias;	/* Defaults to true, if supported */
		bool truncate;	/* Defaults to false */
		unsigned int interpolant;	/* Defaults to BCR_BICUBIC */
		bool bc_set;	/* true if +b was parsed */
		char BC[4];		/* For BC settings via +bg|n[x|y]|p[x|y] */
		double threshold;	/* Defaults to 0.5 */
	} n;
	struct o {	/* -o<col>|<colrange>,.. */
		bool active;
		uint64_t n_cols;
	} o;
	struct p {	/* -p<az>/<el>[+wlon0/lat0[/z0]][+vx0[cip]/y0[cip]] */
		bool active;
	} p;
	struct r {	/* -r */
		bool active;
		unsigned int registration;
	} r;
	struct s {	/* -s[r] */
		bool active;
	} s;
	struct t {	/* -t<transparency> */
		bool active;
		double value;
	} t;
	struct x {	/* -x+a|[-]n */
		bool active;
		int n_threads;
	} x;
	struct colon {	/* -:[i|o] */
		bool active;
		bool toggle[2];
	} colon;
};

struct GMT_INIT { /* Holds misc run-time parameters */
	n_custom_symbols::Uint32
	module_name::Ptr{Uint8}			# Name of current module or NULL if not set */
	module_lib::Ptr{Uint8}			# Name of current shared library or NULL if not set */
	# The rest of the struct contains pointers that may point to memory not included by this struct */
	runtime_bindir::Ptr{Uint8}		# Directory that contains the main exe at run-time */
	runtime_libdir::Ptr{Uint8}		# Directory that contains the main shared lib at run-time */
	char *history[GMT_N_UNIQUE];	# The internal gmt.history information */
	struct GMT_CUSTOM_SYMBOL **custom_symbol; /* For custom symbol plotting in psxy[z]. */
};

struct GMT_CURRENT {
	# These are internal parameters that need to be passed around between
	# many GMT functions.  These values may change by user interaction. */
	struct GMT_DEFAULTS setting;	/* Holds all GMT defaults parameters */
	struct GMT_IO io;		/* Holds all i/o-related parameters */
	struct GMT_PROJ proj;		/* Holds all projection-related parameters */
	struct GMT_MAP map;		/* Holds all projection-related parameters */
	struct GMT_PLOT plot;		/* Holds all plotting-related parameters */
	struct GMT_TIME_CONV time;	/* Holds all time-related parameters */
	struct GMT_PS ps;		/* Hold parameters related to PS setup */
	struct GMT_OPTION *options;	/* Pointer to current program's options */
	struct GMT_FFT_HIDDEN fft;	/* Structure with info that must survive between FFT calls */
};

struct GMT_INTERNAL {
	# These are internal parameters that need to be passed around between
	# many GMT functions.  These may change during execution but are not
	# modified directly by user interaction.
	func_level::Uint32		# Keeps track of what level in a nested GMT_func calling GMT_func etc we are.  0 is top function
	mem_cols::Csize_t		# Current number of allocated columns for temp memory
	mem_rows::Csize_t		# Current number of allocated rows for temp memory
	mem_coord::Ptr{Ptr{Float64}}		# Columns of temp memory
#ifdef MEMDEBUG
	struct MEMORY_TRACKER *mem_keeper;
#endif
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


type GMTAPI_CTRL
	# Master controller which holds all GMT API related information at run-time for a single session.
	# Users can run several GMT sessions concurrently; each session requires its own structure.
	# Use GMTAPI_Create_Session to initialize a new session and GMTAPI_Destroy_Session to end it.

	current_rec::Array_2_Uint64		# Current record number >= 0 in the combined virtual dataset (in and out)
	n_objects::Uint32			# Number of currently active input and output data objects
	unique_ID::Uint32			# Used to create unique IDs for duration of session
	session_ID::Uint32			# ID of this session
	unique_var_ID::Uint32		# Used to create unique object IDs (grid,dataset, etc) for duration of session
	current_item::Array_2_Uint32	# Array number of current dataset being processed (in and out)
	pad::Uint32					# Session default for number of rows/cols padding for grids [2]
	mode::Uint32				# 1 if called via external API (Matlab, Python) [0]
	leave_grid_scaled::Uint32	# 1 if we dont want to unpack a grid after we packed it for writing [0]
	registered::Array_2_Cbool	# true if at least one source/destination has been registered (in and out)
	io_enabled::Array_2_Cbool	# true if access has been allowed (in and out)
	n_objects_alloc::Csize_t	# Allocation counter for data objects
	error::Int32				# Error code from latest API call [GMT_OK]
	last_error::Int32			# Error code from previous API call [GMT_OK]
	shelf::Int32				# Place to pass hidden values within API
	io_mode::Array_2_Uint32		# 1 if access as set, 0 if record-by-record
	GMT::Ptr{GMT_CTRL}			# Key structure with low-level GMT internal parameters
	object::Ptr{Ptr{GMTAPI_DATA_OBJECT}}	# List of registered data objects
	session_tag::Ptr{Uint8}		# Name tag for this session (or NULL)
	internal::Bool				# true if session was initiated by gmt.c
	deep_debug::Bool			# temporary for debugging
	#int (*print_func) (FILE *, const char *);	# Pointer to fprintf function (may be reset by external APIs like MEX)
	pf::Ptr{Void}				# Don't know what to put here, so ley it be *void
	do_not_exit::Uint32			# 0 by default, mieaning it is OK to call exit  (may be reset by external APIs like MEX to call return instead)
	lib::Ptr{Gmt_libinfo}		# List of shared libs to consider
	n_shared_libs::Uint32		# How many in lib
end

immutable GMTAPI_DATA_OBJECT
	# Information for each input or output data entity, including information
	# needed while reading/writing from a table (file or array)
	n_rows::Uint64				# Number or rows in this array [GMT_DATASET and GMT_TEXTSET to/from MATRIX/VETOR only]
	n_columns::Uint64			# Number of columns to process in this dataset [GMT_DATASET only]
	n_expected_fields::Uint64	# Number of expected columns for this dataset [GMT_DATASET only]
	n_alloc::Csize_t			# Number of items allocated so far if writing to memory
	ID::Uint32					# Unique identifier which is >= 0
	alloc_level::Uint32			# Nested module level when object was allocated
	status::Uint32				# 0 when first registered, 1 after reading/writing has started, 2 when finished
	selected::Cbool				# true if requested by current module, false otherwise
	close_file::Cbool			# true if we opened source as a file and thus need to close it when done
	region::Cbool				# true if wesn was passed, false otherwise
	no_longer_owner::Cbool		# true if the data pointed to by the object was passed on to another object
	messenger::Cbool			# true for output objects passed from the outside to receive data from GMT. If true we destroy data pointer before writing
	alloc_mode::GMT_enum_alloc	# GMT_ALLOCATED_{BY_GMT|EXTERNALLY}
	direction::GMT_io_enum		# GMT_IN or GMT_OUT
	family::GMT_enum_family		# One of GMT_IS_{DATASET|TEXTSET|CPT|IMAGE|GRID|MATRIX|VECTOR|COORD}
	actual_family::GMT_enum_family	# May be GMT_IS_MATRIX|VECTOR when one of the others are created via those
	unsigned method::Uint32		# One of GMT_IS_{FILE,STREAM,FDESC,DUPLICATE,REFERENCE} or sum with enum GMT_enum_via (GMT_VIA_{NONE,VECTOR,MATRIX,OUTPUT}); using unsigned type because sum exceeds enum GMT_enum_method
	geometry::GMT_enum_geometry	# One of GMT_IS_{POINT|LINE|POLY|PLP|SURFACE|NONE}
	wesn::Array_4_Cdouble		# Grid domain limits
	resource::Ptr{Void}			# Points to registered filename, memory location, etc., where data can be obtained from with GMT_Get_Data.
	data::Ptr{Void}				# Points to GMT object that was read from a resource
	#FILE *fp;					# Pointer to source/destination stream [For rec-by-rec procession, NULL if memory location]
	fp::Ptr{Void}				# Pointer to source/destination stream [For rec-by-rec procession, NULL if memory location]
	filename::Ptr{Uint8}		# Filename, stream, of file handle (otherwise NULL)
	#void *(*import) (struct GMT_CTRL *, FILE *, uint64_t *, int *);	# Pointer to input function (for DATASET/TEXTSET only)
	ifun::Ptr{Void} 			# Pointer to input function (for DATASET/TEXTSET only)
#ifdef DEBUG
	G::Ptr{Void}				# struct GMT_GRID *G;
	D::Ptr{Void}				# struct GMT_DATASET *D;
	T::Ptr{Void}				# struct GMT_TEXTSET *T;
	C::Ptr{Void}				# struct GMT_PALETTE *C;
	M::Ptr{Void}				# struct GMT_MATRIX *M;
	V::Ptr{Void}				# struct GMT_VECTOR *V;
#endif
	I::Ptr{Void}				# struct GMT_IMAGE *I;
end
=#

# Container to hold the info needed to talk in/out with gmtjl_parser
type GMT_grd_container
	nx::Int
	ny::Int
	grd::Ptr{Float32}
	hdr::Ptr{Float64}
end

