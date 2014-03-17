const EXTERN_MSC = 
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
immutable GMT_OPTION
    option::Uint8
    arg::Ptr{Uint8}
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
bitstype int(WORD_SIZE/8)*sizeof(Cdouble)*4 Array_4_Cdouble__
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
immutable GMT_GRID_HEADER
    nx::Uint32
    ny::Uint32
    registration::Uint32
    wesn::Array_4_Cdouble__
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
immutable GMT_GRID
    header::Ptr{GMT_GRID_HEADER}
    data::Ptr{Cfloat}
    id::Uint32
    alloc_level::Uint32
    alloc_mode::GMT_enum_alloc
    extra::Ptr{None}
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
immutable GMT_MATRIX
    n_rows::Uint64
    n_columns::Uint64
    n_layers::Uint64
    shape::GMT_enum_fmt
    registration::GMT_enum_reg
    dim::Csize_t
    size::Csize_t
    _type::GMT_enum_type
    range::Array_6_Cdouble
    data::GMT_UNIVECTOR
    command::Array_320_Uint8
    remark::Array_160_Uint8
    id::Uint64
    alloc_level::Uint32
    alloc_mode::GMT_enum_alloc
end
