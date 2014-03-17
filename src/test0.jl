using GMT

API=GMT_Create_Session();

#=
dim=uint64([2,9,2]);
V = GMT_Create_Data (API, GMT_IS_VECTOR, GMT_IS_POINT, 0, dim)
Vb = unsafe_load(V)
=#

#=
wesn = zeros(6);
dim=uint64([3,9,1]);
M = GMT_Create_Data (API, GMT_IS_MATRIX, GMT_IS_SURFACE, 0, dim)
Mb = unsafe_load(M)
print([Mb.n_rows,Mb.n_columns,Mb.n_layers])
=#

#=
dim=uint64([1,2,3,4]);
D = GMT_Create_Data (API, GMT_IS_DATASET, GMT_IS_POINT, 0, dim)
Db = unsafe_load(D)
print([Db.n_tables,Db.n_segments,Db.n_records,Db.n_columns])
=#

#ID = GMT_Register_IO(API, GMT_IS_VECTOR, GMT_IS_REFERENCE, GMT_IS_POINT)

#=
GMT_Call_Module(API)		# This fails
GMT_Call_Module(API, "pscoast", GMT_MODULE_EXIST)
GMT_Call_Module(API, "pscoast", GMT_MODULE_PURPOSE)
GMT_Call_Module(API, "pscoast", GMT_MODULE_CMD,"-R-10/0/35/45 -Di -W1p -JM14c -Gbrown -P > lixo.ps")
=#

#=
val = Array(Uint8, 8);
GMT_Get_Default(API, "PROJ_LENGTH_UNIT", val)
print(bytestring(val))		# Response is 'poluted' (not clipped at \0)
=#

#GMT_Option(API, "R,J")

##=
# This a netCDF file in my machine. Change it for an example of yours
input = "C:\\progs_cygw\\GMTdev\\gmt5\\trunk\\build\\dist.nc";
wesn = zeros(6);
G = GMT_Read_Data(API, GMT_IS_GRID, GMT_IS_FILE, GMT_IS_SURFACE, GMT_GRID_ALL, wesn, input, C_NULL)
G = convert(Ptr{GMT_GRID}, G)
Gb = unsafe_load(G)
hdr = unsafe_load(Gb.header)
#=#