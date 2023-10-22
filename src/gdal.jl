# This sub-module is made entirely with code 'subtracted' from the GDAL (https://github.com/JuliaGeo/GDAL.jl)
# and ArcgGDAL https://github.com/yeesian/ArchGDAL.jl packages so credits goes entirely for the authors
# of those packages (Martijn Visser @visr and Yeesian Ng @yeesian).
#
# Why this 'stealing' instead of adding those packages as dependencies?
# Well, first because I wanted to use only a small subset of the full GDAL wrapper and didn't want to add
# a bunch of new dependencies.
# Second because I don't like the idea that the GDAL binary has to come from GDAL_JLL which has a significantly
# lower number of drivers then the system installed ones, especially on Windows. And also, why install a bunch
# more of files if GMT already has them?
#
# It turned out that this file grew more than I anticipated, so maybe I'll revert the decision ... but not yet.

module Gdal

using GMT, Printf
using Tables: Tables

#const cacert = joinpath(@__DIR__, "cacert.pem")

const pVoid   = Ptr{Cvoid}
const pDouble = Ptr{Cdouble}

const GDT_Unknown = UInt32(0)
const GDT_Byte = UInt32(1)
const GDT_UInt16 = UInt32(2)
const GDT_Int16 = UInt32(3)
const GDT_UInt32 = UInt32(4)
const GDT_Int32 = UInt32(5)
const GDT_Float32 = UInt32(6)
const GDT_Float64 = UInt32(7)
const GDT_CInt16 = UInt32(8)
const GDT_CInt32 = UInt32(9)
const GDT_CFloat32 = UInt32(10)
const GDT_CFloat64 = UInt32(11)
const GDT_TypeCount = UInt32(12)

const CE_None = UInt32(0)
const CE_Debug = UInt32(1)
const CE_Warning = UInt32(2)
const CE_Failure = UInt32(3)
const CE_Fatal = UInt32(4)
const OGRERR_NONE = UInt32(0)

const GF_Read  = UInt32(0)
const GF_Write = UInt32(1)

const GDAL_OF_UPDATE = 0x01		# Open in update mode
const GDAL_OF_ALL = 0x00		# Allow raster and vector drivers to be used
const GMF_ALL_VALID = 0x01		# Flag returned by GDALGetMaskFlags() to indicate that all pixels are valid
const GMF_PER_DATASET = 0x02	# Flag returned by GDALGetMaskFlags() to indicate that the mask band is valid for all bands
const GMF_ALPHA = 0x04			# Flag returned by GDALGetMaskFlags() to indicate that the mask band is an alpha band
const GMF_NODATA = 0x08		# Flag returned by GDALGetMaskFlags() to indicate that the mask band is computed from nodata values
const GDAL_OF_READONLY = 0x00			# Open in read-only mode
const GDAL_OF_RASTER = 0x02				# "Allow raster drivers to be used"
const GDAL_OF_VECTOR = 0x04				# "Allow vector drivers to be used"
const GDAL_OF_VERBOSE_ERROR = 0x40		# Emit error message in case of failed open
const GDAL_OF_INTERNAL = 0x80			# "Open as internal dataset"

const OAMS_TRADITIONAL_GIS_ORDER = Int32(0)

const OFTInteger = UInt32(0)
const OFTIntegerList = UInt32(1)
const OFTReal = UInt32(2)
const OFTRealList = UInt32(3)
const OFTString = UInt32(4)
const OFTStringList = UInt32(5)
const OFTWideString = UInt32(6)
const OFTWideStringList = UInt32(7)
const OFTBinary = UInt32(8)
const OFTDate = UInt32(9)
const OFTTime = UInt32(10)
const OFTDateTime = UInt32(11)
const OFTInteger64 = UInt32(12)
const OFTInteger64List = UInt32(13)
const OFTMaxType = UInt32(13)

const wkbUnknown = UInt32(0)
const wkbPoint = UInt32(1)
const wkbLineString = UInt32(2)
const wkbPolygon = UInt32(3)
const wkbMultiPoint = UInt32(4)
const wkbMultiLineString = UInt32(5)
const wkbMultiPolygon = UInt32(6)
const wkbGeometryCollection = UInt32(7)
const wkbCircularString = UInt32(8)
const wkbCompoundCurve = UInt32(9)
const wkbCurvePolygon = UInt32(10)
const wkbMultiCurve = UInt32(11)
const wkbMultiSurface = UInt32(12)
const wkbCurve = UInt32(13)
const wkbSurface = UInt32(14)
const wkbPolyhedralSurface = UInt32(15)
const wkbTIN = UInt32(16)
const wkbTriangle = UInt32(17)
const wkbNone = UInt32(100)
const wkbLinearRing = UInt32(101)
const wkbPointZ = UInt32(1001)
const wkbLineStringZ = UInt32(1002)
const wkbMultiPointZ = UInt32(1004)
const wkbMultiLineStringZ = UInt32(1005)
const wkbCircularStringZ = UInt32(1008)
const wkbCompoundCurveZ = UInt32(1009)
const wkbCurvePolygonZ = UInt32(1010)
const wkbMultiCurveZ = UInt32(1011)
const wkbMultiSurfaceZ = UInt32(1012)
const wkbCurveZ = UInt32(1013)
const wkbSurfaceZ = UInt32(1014)
const wkbPolyhedralSurfaceZ = UInt32(1015)
const wkbTINZ = UInt32(1016)
const wkbTriangleZ = UInt32(1017)
const wkbPointM = UInt32(2001)
const wkbLineStringM = UInt32(2002)
const wkbPolygonM = UInt32(2003)
const wkbMultiPointM = UInt32(2004)
const wkbMultiLineStringM = UInt32(2005)
const wkbMultiPolygonM = UInt32(2006)
const wkbGeometryCollectionM = UInt32(2007)
const wkbCircularStringM = UInt32(2008)
const wkbCompoundCurveM = UInt32(2009)
const wkbCurvePolygonM = UInt32(2010)
const wkbMultiCurveM = UInt32(2011)
const wkbMultiSurfaceM = UInt32(2012)
const wkbCurveM = UInt32(2013)
const wkbSurfaceM = UInt32(2014)
const wkbPolyhedralSurfaceM = UInt32(2015)
const wkbTINM = UInt32(2016)
const wkbTriangleM = UInt32(2017)
const wkbPointZM = UInt32(3001)
const wkbLineStringZM = UInt32(3002)
const wkbPolygonZM = UInt32(3003)
const wkbMultiPointZM = UInt32(3004)
const wkbMultiLineStringZM = UInt32(3005)
const wkbMultiPolygonZM = UInt32(3006)
const wkbGeometryCollectionZM = UInt32(3007)
const wkbCircularStringZM = UInt32(3008)
const wkbCompoundCurveZM = UInt32(3009)
const wkbCurvePolygonZM = UInt32(3010)
const wkbMultiCurveZM = UInt32(3011)
const wkbMultiSurfaceZM = UInt32(3012)
const wkbCurveZM = UInt32(3013)
const wkbSurfaceZM = UInt32(3014)
const wkbPolyhedralSurfaceZM = UInt32(3015)
const wkbTINZM = UInt32(3016)
const wkbTriangleZM = UInt32(3017)
const wkbPoint25D = UInt32(2147483649)
const wkbLineString25D = UInt32(2147483650)
const wkbPolygon25D = UInt32(2147483651)
const wkbMultiPoint25D = UInt32(2147483652)
const wkbMultiLineString25D = UInt32(2147483653)
const wkbMultiPolygon25D = UInt32(2147483654)
const wkbGeometryCollection25D = UInt32(2147483655)

const _FETCHGEOM = Dict{UInt32, String}(
	wkbUnknown            => "Unknown",
	wkbPoint              => "Point",
	wkbLineString         => "Line String",
	wkbPolygon            => "Polygon",
	wkbMultiPoint         => "Multi Point",
	wkbMultiLineString    => "Multi Line String",
	wkbMultiPolygon       => "Multi Polygon",
	wkbGeometryCollection => "Geometry Collection",
	wkbCircularString     => "Circular String",
	wkbCompoundCurve      => "Compound Curve",
	wkbCurvePolygon       => "Curve Polygon"
)

struct OGREnvelope
	MinX::Cdouble
	MaxX::Cdouble
	MinY::Cdouble
	MaxY::Cdouble
end

struct OGREnvelope3D
	MinX::Cdouble
	MaxX::Cdouble
	MinY::Cdouble
	MaxY::Cdouble
	MinZ::Cdouble
	MaxZ::Cdouble
end

struct GDALRasterIOExtraArg
	nVersion::Cint
	eResampleAlg::UInt32
	pfnProgress::pVoid
	pProgressData::pVoid
	bFloatingPointWindowValidity::Cint
	dfXOff::Cdouble
	dfYOff::Cdouble
	dfXSize::Cdouble
	dfYSize::Cdouble
end

struct GDALColorEntry
	c1::Int16
	c2::Int16
	c3::Int16
	c4::Int16
end

struct GDALError <: Exception
	class::Cint
	code::Cint
	msg::String
	# reset GDAL's error stack on construction
	function GDALError(class, code, msg)
		CPLErrorReset()
		new(class, code, msg)
	end
end

function GDALError()
	class = CPLGetLastErrorType()
	code = CPLGetLastErrorNo()
	msg = CPLGetLastErrorMsg()
	GDALError(class, code, msg)
end

GDALAllRegister() = acare(ccall((:GDALAllRegister, libgdal), Cvoid, ()))
GDALDestroyDriverManager() = acare(ccall((:GDALDestroyDriverManager, libgdal), Cvoid, ()))

CPLErrorReset() = ccall((:CPLErrorReset, libgdal), Cvoid, ())
CPLGetLastErrorType() = ccall((:CPLGetLastErrorType, libgdal), Cint, ())
CPLGetLastErrorNo()   = ccall((:CPLGetLastErrorNo, libgdal), Cint, ())
CPLGetLastErrorMsg()  = unsafe_string(ccall((:CPLGetLastErrorMsg, libgdal), Cstring, ()))
CPLPushErrorHandler(a1) = ccall((:CPLPushErrorHandler, libgdal), Cvoid, (pVoid,), a1)
CPLQuietErrorHandler(a1, a2, a3) = ccall((:CPLQuietErrorHandler, libgdal), Cvoid, (UInt32, Cint, Cstring), a1, a2, a3)
CPLPopErrorHandler() = ccall((:CPLPopErrorHandler, libgdal), Cvoid, ())

VSIFree(a1) = acare(ccall((:VSIFree, libgdal), Cvoid, (pVoid,), a1))

Base.showerror(io::IO, err::GDALError) =
	println(io, string("GDALError (", err.class, ", code ", err.code, "):\n\t", err.msg))

function acare(x)
	maybe_throw()
	x
end

function acare(ptr::Cstring, free::Bool)	# For string pointers, load them to String, and free them if we should.
	maybe_throw()
	(ptr == C_NULL) && return nothing
	s = unsafe_string(ptr)
	free && VSIFree(convert(pVoid, ptr))
	return s
end

function acare(ptr::Ptr{Cstring})
	maybe_throw()
	strings = Vector{String}()
	(ptr == C_NULL) && return strings
	i = 1
	cstring = unsafe_load(ptr, i)
	while cstring != C_NULL
		push!(strings, unsafe_string(cstring))
		i += 1
		cstring = unsafe_load(ptr, i)
	end
	# TODO it seems that, like acare(::Cstring), we need to
	# free the memory ourselves with CSLDestroy (not currently wrapped)
	# not sure if that is true for some or all functions
	strings
end

function maybe_throw()		# Check the last error type and throw a GDALError if it is a failure
	(CPLGetLastErrorType() === CE_Failure) && throw(GDALError())
	nothing
end

GDALDestroyDriver(a1) = acare(ccall((:GDALDestroyDriver, libgdal), Cvoid, (pVoid,), a1))

function GDALCreate(hDriver, a1, a2, a3, a4, a5, a6)
	acare(ccall((:GDALCreate, libgdal), pVoid, (pVoid, Cstring, Cint, Cint, Cint, UInt32, Ptr{Cstring}), hDriver, a1, a2, a3, a4, a5, a6))
end

#GDALGetDataTypeName(arg1) = acare(ccall((:GDALGetDataTypeName, libgdal), Cstring, (UInt32,), arg1), false)
GDALGetDataTypeByName(a1) = acare(ccall((:GDALGetDataTypeByName, libgdal), UInt32, (Cstring,), a1))
GDALGetRasterBand(a1, a2) = acare(ccall((:GDALGetRasterBand, libgdal), pVoid, (pVoid, Cint), a1, a2))

GDALSetProjection(a1, a2) = acare(ccall((:GDALSetProjection, libgdal), UInt32, (pVoid, Cstring), a1, a2))

GDALGetRasterDataType(a1) = acare(ccall((:GDALGetRasterDataType, libgdal), UInt32, (pVoid,), a1))
GDALGetProjectionRef(a1) = acare(ccall((:GDALGetProjectionRef, libgdal), Cstring, (pVoid,), a1), false)
GDALGetSpatialRef(a1) = acare(ccall((:GDALGetSpatialRef, libgdal), pVoid, (pVoid,), a1))
GDALGetDatasetDriver(a1) = acare(ccall((:GDALGetDatasetDriver, libgdal), pVoid, (pVoid,), a1))
GDALGetDescription(a1) = acare(ccall((:GDALGetDescription, libgdal), Cstring, (pVoid,), a1), false)
GDALGetMetadata(a1, a2) = acare(ccall((:GDALGetMetadata, libgdal), Ptr{Cstring}, (pVoid, Cstring), a1, a2))
GDALGetMetadataDomainList(a1) = acare(ccall((:GDALGetMetadataDomainList, libgdal), Ptr{Cstring}, (pVoid,), a1))
GDALGetDriver(a1) = acare(ccall((:GDALGetDriver, libgdal), pVoid, (Cint,), a1))
GDALGetDriverByName(a1) = acare(ccall((:GDALGetDriverByName, libgdal), pVoid, (Cstring,), a1))
GDALGetDriverShortName(a1) = acare(ccall((:GDALGetDriverShortName, libgdal), Cstring, (pVoid,), a1), false)
GDALGetDriverLongName(a1) = acare(ccall((:GDALGetDriverLongName, libgdal), Cstring, (pVoid,), a1), false)
GDALGetDriverCreationOptionList(a1) = acare(ccall((:GDALGetDriverCreationOptionList, libgdal), Cstring, (pVoid,), a1), false)
GDALDatasetExecuteSQL(a1, a2, a3, a4) =
	acare(ccall((:GDALDatasetExecuteSQL, libgdal), pVoid, (pVoid, Cstring, pVoid, Cstring), a1, a2, a3, a4))
GDALDatasetGetLayer(a1, a2) = acare(ccall((:GDALDatasetGetLayer, libgdal), pVoid, (pVoid, Cint), a1, a2))
GDALDatasetGetLayerByName(a1, a2) = acare(ccall((:GDALDatasetGetLayerByName, libgdal), pVoid, (pVoid, Cstring), a1, a2))
GDALDatasetReleaseResultSet(a1, a2) = acare(ccall((:GDALDatasetReleaseResultSet, libgdal), Cvoid, (pVoid, pVoid), a1, a2))
GDALGetRasterBandXSize(a1) = acare(ccall((:GDALGetRasterBandXSize, libgdal), Cint, (pVoid,), a1))
GDALGetRasterBandYSize(a1) = acare(ccall((:GDALGetRasterBandYSize, libgdal), Cint, (pVoid,), a1))
GDALGetRasterXSize(a1)     = acare(ccall((:GDALGetRasterXSize, libgdal), Cint, (pVoid,), a1))
GDALGetRasterYSize(a1)     = acare(ccall((:GDALGetRasterYSize, libgdal), Cint, (pVoid,), a1))
GDALGetRasterColorTable(a1) = acare(ccall((:GDALGetRasterColorTable, libgdal), pVoid, (pVoid,), a1))
GDALDatasetGetLayerCount(a1) = acare(ccall((:GDALDatasetGetLayerCount, libgdal), Cint, (pVoid,), a1))
GDALGetRasterCount(a1)  = acare(ccall((:GDALGetRasterCount, libgdal), Cint, (pVoid,), a1))
GDALGetFileList(a1)     = acare(ccall((:GDALGetFileList, libgdal), Ptr{Cstring}, (pVoid,), a1))
GDALGetRasterAccess(a1) = acare(ccall((:GDALGetRasterAccess, libgdal), UInt32, (pVoid,), a1))
GDALGetBandNumber(a1)   = acare(ccall((:GDALGetBandNumber, libgdal), Cint, (pVoid,), a1))
GDALGetDriverCount()    = acare(ccall((:GDALGetDriverCount, libgdal), Cint, ()))

GDALGetRasterColorInterpretation(a1) = acare(ccall((:GDALGetRasterColorInterpretation, libgdal), UInt32, (pVoid,), a1))
GDALGetRasterNoDataValue(a1, a2) = acare(ccall((:GDALGetRasterNoDataValue, libgdal), Cdouble, (pVoid, Ptr{Cint}), a1, a2))

GDALGetColorInterpretationName(a1) =
	acare(ccall((:GDALGetColorInterpretationName, libgdal), Cstring, (UInt32,), a1), false)
GDALGetPaletteInterpretationName(a1) =
	acare(ccall((:GDALGetPaletteInterpretationName, libgdal), Cstring, (UInt32,), a1), false)
GDALGetPaletteInterpretation(a1) = acare(ccall((:GDALGetPaletteInterpretation, libgdal), UInt32, (pVoid,), a1))
GDALGetColorEntryCount(a1) = acare(ccall((:GDALGetColorEntryCount, libgdal), Cint, (pVoid,), a1))
GDALGetColorEntry(a1, a2) = acare(ccall((:GDALGetColorEntry, libgdal), Ptr{GDALColorEntry}, (pVoid, Cint), a1, a2))

GDALGetGeoTransform(a1, a2) = acare(ccall((:GDALGetGeoTransform, libgdal), UInt32, (pVoid, Ptr{Cdouble}), a1, a2))
GDALSetGeoTransform(a1, a2) = acare(ccall((:GDALSetGeoTransform, libgdal), UInt32, (pVoid, Ptr{Cdouble}), a1, a2))

function GDALOpenEx(pFilename, nOpenFlags, pAllowedDrivers, pOpenOptions, pSiblingFiles)
	acare(ccall((:GDALOpenEx, libgdal), pVoid, (Cstring, UInt32, Ptr{Cstring}, Ptr{Cstring}, Ptr{Cstring}), pFilename, nOpenFlags, pAllowedDrivers, pOpenOptions, pSiblingFiles))
end

GDALClose(a1) = acare(ccall((:GDALClose, libgdal), Cvoid, (pVoid,), a1))
GDALVersionInfo(a1) = acare(ccall((:GDALVersionInfo, libgdal), Cstring, (Cstring,), a1), false)

GDALRasterIOEx(hRBand, eRWFlag, nDSXOff, nDSYOff, nDSXSize, nDSYSize, pBuffer, nBXSize, nBYSize, eBDataType, nPixelSpace, nLineSpace, psExtraArg) =
	acare(ccall((:GDALRasterIOEx, libgdal), UInt32, (pVoid, UInt32, Cint, Cint, Cint, Cint, UInt32, Cint, Cint, pVoid, Clonglong, Clonglong, Ptr{GDALRasterIOExtraArg}), hRBand, eRWFlag, nDSXOff, nDSYOff, nDSXSize, nDSYSize, pBuffer, nBXSize, nBYSize, eBDataType, nPixelSpace, nLineSpace, psExtraArg))

GDALDatasetRasterIOEx(hDS, eRWFlag, nDSXOff, nDSYOff, nDSXSize, nDSYSize, pBuffer, nBXSize, nBYSize, eBDataType, nBandCount, panBandCount, nPixelSpace, nLineSpace, nBandSpace, psExtraArg) =
	acare(ccall((:GDALDatasetRasterIOEx, libgdal), UInt32, (pVoid, UInt32, Cint, Cint, Cint, Cint, pVoid, Cint, Cint, UInt32, Cint, Ptr{Cint}, Clonglong, Clonglong, Clonglong, Ptr{GDALRasterIOExtraArg}), hDS, eRWFlag, nDSXOff, nDSYOff, nDSXSize, nDSYSize, pBuffer, nBXSize, nBYSize, eBDataType, nBandCount, panBandCount, nPixelSpace, nLineSpace, nBandSpace, psExtraArg))

GDALSetRasterColorTable(a1, a2) = acare(ccall((:GDALSetRasterColorTable, libgdal), UInt32, (pVoid, pVoid), a1, a2))
GDALSetRasterNoDataValue(a1, a2) = acare(ccall((:GDALSetRasterNoDataValue, libgdal), UInt32, (pVoid, Cdouble), a1, a2))

GDALDummyProgress(a1, a2, a3) = acare(ccall((:GDALDummyProgress, libgdal), Cint, (Cdouble, Cstring, pVoid), a1, a2, a3))
function GDALCreateCopy(a1, a2, a3, a4, a5, a6, a7)
	acare(ccall((:GDALCreateCopy, libgdal), pVoid, (pVoid, Cstring, pVoid, Cint, Ptr{Cstring}, pVoid, pVoid), a1, a2, a3, a4, a5, a6, a7))
end

GDALCreateColorTable(a1) = acare(ccall((:GDALCreateColorTable, libgdal), pVoid, (UInt32,), a1))
function GDALCreateColorRamp(hTable, nStartIndex, psStartColor, nEndIndex, psEndColor)
	acare(ccall((:GDALCreateColorRamp, libgdal), Cvoid, (pVoid, Cint, Ptr{GDALColorEntry}, Cint, Ptr{GDALColorEntry}), hTable, nStartIndex, psStartColor, nEndIndex, psEndColor))
end
GDALSetColorEntry(a1, a2, a3) =
	acare(ccall((:GDALSetColorEntry, libgdal), Cvoid, (pVoid, Cint, Ptr{GDALColorEntry}), a1, a2, a3))

CPLSetConfigOption(a1, a2) = acare(ccall((:CPLSetConfigOption, libgdal), Cvoid, (Cstring, Cstring), a1, a2))
CPLGetConfigOption(a1, a2) = acare(ccall((:CPLGetConfigOption, libgdal), Cstring, (Cstring, Cstring), a1, a2), false)

CSLFetchNameValue(a1, a2) = acare(ccall((:CSLFetchNameValue, libgdal), Cstring, (Ptr{Cstring}, Cstring), a1, a2))
function fetchnamevalue(strlist::Vector{String}, name::String="")::String
	item = CSLFetchNameValue(strlist, name)
	return item == C_NULL ? "" : unsafe_string(item)
end

GDALSetDescription(a1, a2) = acare(ccall((:GDALSetDescription, libgdal), Cvoid, (pVoid, Cstring), a1, a2))
GDALSetMetadata(a1, a2, a3) = acare(ccall((:GDALSetMetadata, libgdal), UInt32, (pVoid, Ptr{Cstring}, Cstring), a1, a2, a3))

GDALGetMetadataItem(a1, a2, a3) = acare(ccall((:GDALGetMetadataItem, libgdal), Cstring, (pVoid, Cstring, Cstring), a1, a2, a3), false)
GDALSetMetadataItem(a1, a2, a3, a4) =
    acare(ccall((:GDALSetMetadataItem, libgdal), UInt32, (pVoid, Cstring, Cstring, Cstring), a1, a2, a3, a4))

OSRDestroySpatialReference(a1) = acare(ccall((:OSRDestroySpatialReference, libgdal), Cvoid, (pVoid,), a1))
OCTDestroyCoordinateTransformation(a1) = acare(ccall((:OCTDestroyCoordinateTransformation, libgdal), Cvoid, (pVoid,), a1))

OSRExportToWkt(a1, a2) = acare(ccall((:OSRExportToWkt, libgdal), Cint, (pVoid, Ptr{Cstring}), a1, a2))

function OSRExportToPrettyWkt(a1, a2, a3)
	acare(ccall((:OSRExportToPrettyWkt, libgdal), Cint, (pVoid, Ptr{Cstring}, Cint), a1, a2, a3))
end

OSRExportToProj4(a1, a2) = acare(ccall((:OSRExportToProj4, libgdal), Cint, (pVoid, Ptr{Cstring}), a1, a2))
OSRImportFromWkt(a1, a2) = acare(ccall((:OSRImportFromWkt, libgdal), Cint, (pVoid, Ptr{Cstring}), a1, a2))
OSRImportFromProj4(a1, a2) = acare(ccall((:OSRImportFromProj4, libgdal), Cint, (pVoid, Cstring), a1, a2))
OSRImportFromEPSG(a1, a2) = acare(ccall((:OSRImportFromEPSG, libgdal), Cint, (pVoid, Cint), a1, a2))
OSRNewSpatialReference(a1) = acare(ccall((:OSRNewSpatialReference, libgdal), pVoid, (Cstring,), a1))

function OSRSetAxisMappingStrategy(hSRS, strategy)
	#(Gdal.GDALVERSION[] < v"3.0.0") && return	# This breakes precompile if called from one PrecompileTools call
	acare(ccall((:OSRSetAxisMappingStrategy, libgdal), Cvoid, (pVoid, UInt32), hSRS, strategy))
end

OGRGetDriverByName(a1) = acare(ccall((:OGRGetDriverByName, libgdal), pVoid, (Cstring,), a1))

OGR_F_Create(a1) = acare(ccall((:OGR_F_Create, libgdal), pVoid, (pVoid,), a1))
OGR_F_Destroy(a1) = acare(ccall((:OGR_F_Destroy, libgdal), Cvoid, (pVoid,), a1))
OGR_F_GetDefnRef(a1) = acare(ccall((:OGR_F_GetDefnRef, libgdal), pVoid, (pVoid,), a1))
OGR_F_GetGeometryRef(a1) = acare(ccall((:OGR_F_GetGeometryRef, libgdal), pVoid, (pVoid,), a1))
OGR_F_GetGeomFieldCount(hFeat) = acare(ccall((:OGR_F_GetGeomFieldCount, libgdal), Cint, (pVoid,), hFeat))
OGR_F_GetFieldCount(a1) = acare(ccall((:OGR_F_GetFieldCount, libgdal), Cint, (pVoid,), a1))
OGR_F_GetFieldDefnRef(a1, a2) = acare(ccall((:OGR_F_GetFieldDefnRef, libgdal), pVoid, (pVoid, Cint), a1, a2))
OGR_F_GetFieldIndex(a1, a2) = acare(ccall((:OGR_F_GetFieldIndex, libgdal), Cint, (pVoid, Cstring), a1, a2))
OGR_F_IsFieldSet(a1, a2) = acare(ccall((:OGR_F_IsFieldSet, libgdal), Cint, (pVoid, Cint), a1, a2))
OGR_F_GetFieldAsInteger(a1, a2) = acare(ccall((:OGR_F_GetFieldAsInteger, libgdal), Cint, (pVoid, Cint), a1, a2))
OGR_F_GetFieldAsInteger64(a1, a2) = acare(ccall((:OGR_F_GetFieldAsInteger64, libgdal), Clonglong, (pVoid, Cint), a1, a2))
OGR_F_GetFieldAsDouble(a1, a2) = acare(ccall((:OGR_F_GetFieldAsDouble, libgdal), Cdouble, (pVoid, Cint), a1, a2))
OGR_F_GetFieldAsString(a1, a2) = acare(ccall((:OGR_F_GetFieldAsString, libgdal), Cstring, (pVoid, Cint), a1, a2), false)
OGR_F_GetFieldAsStringList(a1, a2) = acare(ccall((:OGR_F_GetFieldAsStringList, libgdal), Ptr{Cstring}, (pVoid, Cint), a1, a2))
OGR_F_GetFieldAsIntegerList(a1, a2, a3) =
	acare(ccall((:OGR_F_GetFieldAsIntegerList, libgdal), Ptr{Cint}, (pVoid, Cint, Ptr{Cint}), a1, a2, a3))

OGR_F_GetFieldAsInteger64List(a1, a2, a3) =
	acare(ccall((:OGR_F_GetFieldAsInteger64List, libgdal), Ptr{Clonglong}, (pVoid, Cint, Ptr{Cint}), a1, a2, a3))

OGR_F_GetFieldAsDoubleList(a1, a2, a3) =
	acare(ccall((:OGR_F_GetFieldAsDoubleList, libgdal), Ptr{Cdouble}, (pVoid, Cint, Ptr{Cint}), a1, a2, a3))

OGR_F_GetFieldAsBinary(a1, a2, a3) =
	acare(ccall((:OGR_F_GetFieldAsBinary, libgdal), Ptr{Cuchar}, (pVoid, Cint, Ptr{Cint}), a1, a2, a3))

OGR_F_GetFieldAsDateTime(a1, a2, a3, a4, arg5, arg6, arg7, arg8, arg9) =
	acare(ccall((:OGR_F_GetFieldAsDateTime, libgdal), Cint, (pVoid, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), a1, a2, a3, a4, arg5, arg6, arg7, arg8, arg9))

OGR_F_GetGeomFieldDefnRef(hFeat, iField) =
	acare(ccall((:OGR_F_GetGeomFieldDefnRef, libgdal), pVoid, (pVoid, Cint), hFeat, iField))

OGR_F_GetGeomFieldRef(hFeat, iField) =
	acare(ccall((:OGR_F_GetGeomFieldRef, libgdal), pVoid, (pVoid, Cint), hFeat, iField))

OGR_F_SetGeometry(a1, a2) = acare(ccall((:OGR_F_SetGeometry, libgdal), Cint, (pVoid, pVoid), a1, a2))
OGR_F_SetGeomField(hFeat, iField, hGeom) =
	acare(ccall((:OGR_F_SetGeomField, libgdal), Cint, (pVoid, Cint, pVoid), hFeat, iField, hGeom))

OGR_FD_AddFieldDefn(a1, a2) = acare(ccall((:OGR_FD_AddFieldDefn, libgdal), Cvoid, (pVoid, pVoid), a1, a2))
OGR_FD_Destroy(a1) = acare(ccall((:OGR_FD_Destroy, libgdal), Cvoid, (pVoid,), a1))
OGR_FD_GetFieldCount(a1) = acare(ccall((:OGR_FD_GetFieldCount, libgdal), Cint, (pVoid,), a1))
OGR_FD_GetFieldDefn(a1, a2) = acare(ccall((:OGR_FD_GetFieldDefn, libgdal), pVoid, (pVoid, Cint), a1, a2))
OGR_FD_GetFieldIndex(a1, a2) = acare(ccall((:OGR_FD_GetFieldIndex, libgdal), Cint, (pVoid, Cstring), a1, a2))
OGR_FD_GetName(a1) = acare(ccall((:OGR_FD_GetName, libgdal), Cstring, (pVoid,), a1), false)
OGR_FD_GetGeomType(a1)    = acare(ccall((:OGR_FD_GetGeomType, libgdal), UInt32, (pVoid,), a1))
OGR_FD_GetGeomFieldCount(hFDefn) = acare(ccall((:OGR_FD_GetGeomFieldCount, libgdal), Cint, (pVoid,), hFDefn))
OGR_FD_GetGeomFieldDefn(hFDefn, i) = acare(ccall((:OGR_FD_GetGeomFieldDefn, libgdal), pVoid, (pVoid, Cint), hFDefn, i))
OGR_Fld_Create(a1, a2) = acare(ccall((:OGR_Fld_Create, libgdal), pVoid, (Cstring, UInt32), a1, a2))
OGR_Fld_Destroy(a1) = acare(ccall((:OGR_Fld_Destroy, libgdal), Cvoid, (pVoid,), a1))
OGR_Fld_GetDefault(hDefn) = acare(ccall((:OGR_Fld_GetDefault, libgdal), Cstring, (pVoid,), hDefn), false)
OGR_Fld_GetNameRef(a1) = acare(ccall((:OGR_Fld_GetNameRef, libgdal), Cstring, (pVoid,), a1), false)
OGR_Fld_GetType(a1) = acare(ccall((:OGR_Fld_GetType, libgdal), UInt32, (pVoid,), a1))
OGR_GFld_Destroy(a1) = acare(ccall((:OGR_GFld_Destroy, libgdal), Cvoid, (pVoid,), a1))
OGR_GFld_GetType(a1) = acare(ccall((:OGR_GFld_GetType, libgdal), UInt32, (pVoid,), a1))
OGR_Fld_Set(a1, a2, a3, a4, a5, a6) =
	acare(ccall((:OGR_Fld_Set, libgdal), Cvoid, (pVoid, Cstring, UInt32, Cint, Cint, UInt32), a1, a2, a3, a4, a5, a6))

OGR_G_Area(a1) = acare(ccall((:OGR_G_Area, libgdal), Cdouble, (pVoid,), a1))
OGR_G_ApproximateArcAngles(x0, y0, z0, r1, r2, rot, a1, a2, inc) = 
	acare(ccall((:OGR_G_ApproximateArcAngles, libgdal), pVoid, (Cdouble,Cdouble,Cdouble,Cdouble,Cdouble,Cdouble,Cdouble,Cdouble,Cdouble), x0,y0,z0,r1,r2,rot,a1,a2,inc))
OGR_G_AddGeometry(a1, a2) = acare(ccall((:OGR_G_AddGeometry, libgdal), Cint, (pVoid, pVoid), a1, a2))
OGR_G_AddGeometryDirectly(a1, a2) = acare(ccall((:OGR_G_AddGeometryDirectly, libgdal), Cint, (pVoid, pVoid), a1, a2))
OGR_G_Boundary(a1) = acare(ccall((:OGR_G_Boundary, libgdal), pVoid, (pVoid,), a1))
OGR_G_Buffer(a1, a2, a3) = acare(ccall((:OGR_G_Buffer, libgdal), pVoid, (pVoid, Cdouble, Cint), a1, a2, a3))
OGR_G_Centroid(a1, a2) = acare(ccall((:OGR_G_Centroid, libgdal), Cint, (pVoid, pVoid), a1, a2))
OGR_G_Clone(a1) = acare(ccall((:OGR_G_Clone, libgdal), pVoid, (pVoid,), a1))
OGR_G_Contains(a1, a2) = acare(ccall((:OGR_G_Contains, libgdal), Cint, (pVoid, pVoid), a1, a2))
OGR_G_ConvexHull(a1) = acare(ccall((:OGR_G_ConvexHull, libgdal), pVoid, (pVoid,), a1))
OGR_G_ConcaveHull(a1, a2, a3) = acare(ccall((:OGR_G_ConcaveHull, libgdal), pVoid, (pVoid, Cdouble, Bool), a1, a2, a3))
OGR_G_CreateGeometry(a1) = acare(ccall((:OGR_G_CreateGeometry, libgdal), pVoid, (UInt32,), a1))
OGR_G_Crosses(a1, a2) = acare(ccall((:OGR_G_Crosses, libgdal), Cint, (pVoid, pVoid), a1, a2))
OGR_G_DelaunayTriangulation(hThis, tol, edges) = acare(ccall((:OGR_G_DelaunayTriangulation, libgdal), pVoid, (pVoid, Cdouble, Cint), hThis, tol, edges))
OGR_G_Simplify(hThis, tolerance) = acare(ccall((:OGR_G_Simplify, libgdal), pVoid, (pVoid, Cdouble), hThis, tolerance))
OGR_G_DestroyGeometry(a1) = acare(ccall((:OGR_G_DestroyGeometry, libgdal), Cvoid, (pVoid,), a1))
OGR_G_Difference(a1, a2) = acare(ccall((:OGR_G_Difference, libgdal), pVoid, (pVoid, pVoid), a1, a2))
OGR_G_Distance(a1, a2) = acare(ccall((:OGR_G_Distance, libgdal), Cdouble, (pVoid, pVoid), a1, a2))
OGR_G_Disjoint(a1, a2) = acare(ccall((:OGR_G_Disjoint, libgdal), Cint, (pVoid, pVoid), a1, a2))
OGR_G_Equals(a1, a2) = acare(ccall((:OGR_G_Equals, libgdal), Cint, (pVoid, pVoid), a1, a2))
OGR_G_SymDifference(a1, a2) = acare(ccall((:OGR_G_SymDifference, libgdal), pVoid, (pVoid, pVoid), a1, a2))
OGR_G_ExportToWkt(a1, a2) = acare(ccall((:OGR_G_ExportToWkt, libgdal), Cint, (pVoid, Ptr{Cstring}), a1, a2))
OGR_G_ExportToKML(a1, altMode) = acare(ccall((:OGR_G_ExportToKML, libgdal), Cstring, (pVoid, Cstring), a1, altMode), false)
OGR_G_FlattenTo2D(a1) = acare(ccall((:OGR_G_FlattenTo2D, libgdal), pVoid, (pVoid,), a1)) 
OGR_G_ForceTo(hGeom, eTargetType, pOpts) =
	acare(ccall((:OGR_G_ForceTo, libgdal), pVoid, (pVoid, UInt32, Ptr{Cstring}), hGeom, eTargetType, pOpts))
OGR_G_ForceToPolygon(a1) = acare(ccall((:OGR_G_ForceToPolygon, libgdal), pVoid, (pVoid,), a1))
OGR_G_ForceToMultiPolygon(a1) = acare(ccall((:OGR_G_ForceToMultiPolygon, libgdal), pVoid, (pVoid,), a1))
OGR_G_ForceToMultiPoint(a1) = acare(ccall((:OGR_G_ForceToMultiPoint, libgdal), pVoid, (pVoid,), a1))
OGR_G_GetCoordinateDimension(a1) = acare(ccall((:OGR_G_GetCoordinateDimension, libgdal), Cint, (pVoid,), a1))
OGR_G_GetEnvelope(a1, a2) = acare(ccall((:OGR_G_GetEnvelope, libgdal), Cvoid, (pVoid, Ptr{OGREnvelope}), a1, a2))
OGR_G_GetEnvelope3D(a1, a2) = acare(ccall((:OGR_G_GetEnvelope3D, libgdal), Cvoid, (pVoid, Ptr{OGREnvelope3D}), a1, a2))
OGR_G_GetGeometryCount(a1) = acare(ccall((:OGR_G_GetGeometryCount, libgdal), Cint, (pVoid,), a1))
OGR_G_GetGeometryType(a1) = acare(ccall((:OGR_G_GetGeometryType, libgdal), UInt32, (pVoid,), a1))
OGR_G_GetGeometryName(a1) = acare(ccall((:OGR_G_GetGeometryName, libgdal), Cstring, (pVoid,), a1), false)
OGR_G_GetGeometryRef(a1, a2) = acare(ccall((:OGR_G_GetGeometryRef, libgdal), pVoid, (pVoid, Cint), a1, a2))
OGR_G_GetPointCount(a1) = acare(ccall((:OGR_G_GetPointCount, libgdal), Cint, (pVoid,), a1))
OGR_G_GetX(a1, a2) = acare(ccall((:OGR_G_GetX, libgdal), Cdouble, (pVoid, Cint), a1, a2))
OGR_G_GetY(a1, a2) = acare(ccall((:OGR_G_GetY, libgdal), Cdouble, (pVoid, Cint), a1, a2))
OGR_G_GetZ(a1, a2) = acare(ccall((:OGR_G_GetZ, libgdal), Cdouble, (pVoid, Cint), a1, a2))
OGR_G_GetPoint(a1, iPoint, a2, a3, a4) =
	acare(ccall((:OGR_G_GetPoint, libgdal), Cvoid, (pVoid, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}), a1, iPoint, a2, a3, a4))

OGR_G_Intersection(a1, a2) = acare(ccall((:OGR_G_Intersection, libgdal), pVoid, (pVoid, pVoid), a1, a2))
OGR_G_Intersects(a1, a2) = acare(ccall((:OGR_G_Intersects, libgdal), Cint, (pVoid, pVoid), a1, a2))
OGR_G_Length(a1) = acare(ccall((:OGR_G_Length, libgdal), Cdouble, (pVoid,), a1))
OGR_G_Overlaps(a1, a2) = acare(ccall((:OGR_G_Overlaps, libgdal), Cint, (pVoid, pVoid), a1, a2))
OGR_G_Polygonize(a1) = acare(ccall((:OGR_G_Polygonize, libgdal), pVoid, (pVoid,), a1))
OGR_G_Touches(a1, a2) = acare(ccall((:OGR_G_Touches, libgdal), Cint, (pVoid, pVoid), a1, a2))
OGR_G_Value(a1, dist) = acare(ccall((:OGR_G_Value, libgdal), pVoid, (pVoid, Cdouble), a1, dist))
OGR_G_Union(a1, a2) = acare(ccall((:OGR_G_Union, libgdal), pVoid, (pVoid, pVoid), a1, a2))
OGR_G_Within(a1, a2) = acare(ccall((:OGR_G_Within, libgdal), Cint, (pVoid, pVoid), a1, a2))

OGR_G_SetPoints(hGeom, nPointsIn, pabyX, nXStride, pabyY, nYStride, pabyZ, nZStride) =
	acare(ccall((:OGR_G_SetPoints, libgdal), Cvoid, (pVoid, Cint, pVoid, Cint, pVoid, Cint, pVoid, Cint), hGeom, nPointsIn, pabyX, nXStride, pabyY, nYStride, pabyZ, nZStride))

OGR_G_SetPoint(a1, iPt, a2, a3, a4) =
	acare(ccall((:OGR_G_SetPoint, libgdal), Cvoid, (pVoid, Cint, Cdouble, Cdouble, Cdouble), a1, iPt, a2, a3, a4))

OGR_G_SetPoint_2D(a1, iPt, a2, a3) =
	acare(ccall((:OGR_G_SetPoint_2D, libgdal), Cvoid, (pVoid, Cint, Cdouble, Cdouble), a1, iPt, a2, a3))

OGR_L_CreateFeature(a1, a2) = acare(ccall((:OGR_L_CreateFeature, libgdal), Cint, (pVoid, pVoid), a1, a2))
OGR_L_GetFeature(a1, a2) = acare(ccall((:OGR_L_GetFeature, libgdal), pVoid, (pVoid, Clonglong), a1, a2))
OGR_L_GetFeatureCount(a1, a2) = acare(ccall((:OGR_L_GetFeatureCount, libgdal), Clonglong, (pVoid, Cint), a1, a2))
OGR_L_GetName(a1)  = acare(ccall((:OGR_L_GetName, libgdal), Cstring, (pVoid,), a1), false)
OGR_L_GetGeomType(a1)  = acare(ccall((:OGR_L_GetGeomType, libgdal), UInt32, (pVoid,), a1))
OGR_L_GetLayerDefn(a1) = acare(ccall((:OGR_L_GetLayerDefn, libgdal), pVoid, (pVoid,), a1))
OGR_L_GetSpatialRef(a1) = acare(ccall((:OGR_L_GetSpatialRef, libgdal), pVoid, (pVoid,), a1))
OGR_L_GetNextFeature(a1) = acare(ccall((:OGR_L_GetNextFeature, libgdal), pVoid, (pVoid,), a1))
OGR_L_ResetReading(a1) = acare(ccall((:OGR_L_ResetReading, libgdal), Cvoid, (pVoid,), a1))
OGR_L_SetFeature(a1, a2) = acare(ccall((:OGR_L_SetFeature, libgdal), Cint, (pVoid, pVoid), a1, a2))
#OGR_GetFieldTypeName(a1)  = acare(ccall((:OGR_GetFieldTypeName, libgdal), Cstring, (UInt32,), a1), false)
#OGR_GetFieldSubTypeName(a1) = acare(ccall((:OGR_GetFieldSubTypeName, libgdal), Cstring, (UInt32,), a1), false)
OGRGetDriverCount() = acare(ccall((:OGRGetDriverCount, libgdal), Cint, ()))

OGR_G_AddPoint(a1, a2, a3, a4) =
	acare(ccall((:OGR_G_AddPoint, libgdal), Cvoid, (pVoid, Cdouble, Cdouble, Cdouble), a1, a2, a3, a4))

OGR_G_AddPoint_2D(a1, a2, a3) = acare(ccall((:OGR_G_AddPoint_2D, libgdal), Cvoid, (pVoid, Cdouble, Cdouble), a1, a2, a3))

OGR_L_CreateField(a1, a2, a3) = acare(ccall((:OGR_L_CreateField, libgdal), Cint, (pVoid, pVoid, Cint), a1, a2, a3))
OGR_L_FindFieldIndex(a1, a2, bExactMatch) =
	acare(ccall((:OGR_L_FindFieldIndex, libgdal), Cint, (pVoid, Cstring, Cint), a1, a2, bExactMatch))

OGR_F_SetFieldInteger(a1, a2, a3) = acare(ccall((:OGR_F_SetFieldInteger, libgdal), Cvoid, (pVoid, Cint, Cint), a1, a2, a3))
OGR_F_Clone(a1) = acare(ccall((:OGR_F_Clone, libgdal), pVoid, (pVoid,), a1))
OGR_F_SetFieldInteger64(a1, a2, a3) = acare(ccall((:OGR_F_SetFieldInteger64, libgdal), Cvoid, (pVoid, Cint, Clonglong), a1, a2, a3))
OGR_F_SetFieldDouble(a1, a2, a3) = acare(ccall((:OGR_F_SetFieldDouble, libgdal), Cvoid, (pVoid, Cint, Cdouble), a1, a2, a3))
OGR_F_SetFieldString(a1, a2, a3) = acare(ccall((:OGR_F_SetFieldString, libgdal), Cvoid, (pVoid, Cint, Cstring), a1, a2, a3))
OGR_F_SetFieldIntegerList(a1, a2, a3, a4) =
	acare(ccall((:OGR_F_SetFieldIntegerList, libgdal), Cvoid, (pVoid, Cint, Cint, Ptr{Cint}), a1, a2, a3, a4))

OGR_F_SetFieldInteger64List(a1, a2, a3, a4) =
	acare(ccall((:OGR_F_SetFieldInteger64List, libgdal), Cvoid, (pVoid, Cint, Cint, Ptr{Clonglong}), a1, a2, a3, a4))

OGR_F_SetFieldDoubleList(a1, a2, a3, a4) =
	acare(ccall((:OGR_F_SetFieldDoubleList, libgdal), Cvoid, (pVoid, Cint, Cint, Ptr{Cdouble}), a1, a2, a3, a4))

OGR_F_SetFieldStringList(a1, a2, a3) =
	acare(ccall((:OGR_F_SetFieldStringList, libgdal), Cvoid, (pVoid, Cint, Ptr{Cstring}), a1, a2, a3))

OGR_F_SetFieldBinary(a1, a2, a3, a4) =
	acare(ccall((:OGR_F_SetFieldBinary, libgdal), Cvoid, (pVoid, Cint, Cint, pVoid), a1, a2, a3, a4))

OGR_F_SetFieldDateTime(a1, a2, a3, a4, a5, a6, a7, a8, a9) =
	acare(ccall((:OGR_F_SetFieldDateTime, libgdal), Cvoid, (pVoid, Cint, Cint, Cint, Cint, Cint, Cint, Cint, Cint), a1, a2, a3, a4, a5, a6, a7, a8, a9))

OGR_Dr_DeleteDataSource(a1, a2) = acare(ccall((:OGR_Dr_DeleteDataSource, libgdal), Cint, (pVoid, Cstring), a1, a2))

OSRClone(arg1) = acare(ccall((:OSRClone, libgdal), pVoid, (pVoid,), arg1))

GDALDeleteDataset(a1, a2) = acare(ccall((:GDALDeleteDataset, libgdal), Cint, (pVoid, Cstring), a1, a2))

GDALDatasetCreateLayer(a1, a2, a3, a4, a5) =
	acare(ccall((:GDALDatasetCreateLayer, libgdal), pVoid, (pVoid, Cstring, pVoid, UInt32, Ptr{Cstring}), a1, a2, a3, a4, a5))

GDALDatasetTestCapability(a1, a2) = acare(ccall((:GDALDatasetTestCapability, libgdal), Cint, (pVoid, Cstring), a1, a2))

GDALComputeMedianCutPCT(hRed, hGreen, hBlue, pfnIncPix, nColors, hColorTable, pfnProgress, pProgArg) =
	acare(ccall((:GDALComputeMedianCutPCT, libgdal), Cint, (pVoid, pVoid, pVoid, pVoid, Cint, pVoid, pVoid, pVoid), hRed, hGreen, hBlue, pfnIncPix, nColors, hColorTable, pfnProgress, pProgArg))

GDALDitherRGB2PCT(hRed, hGreen, hBlue, hTarget, hColorTable, pfnProgress, pProgArg) =
	acare(ccall((:GDALDitherRGB2PCT, libgdal), Cint, (pVoid, pVoid, pVoid, pVoid, pVoid, pVoid, pVoid), hRed, hGreen, hBlue, hTarget, hColorTable, pfnProgress, pProgArg))

GDALInfoOptionsNew(pArgv, psOFB) =
	acare(ccall((:GDALInfoOptionsNew, libgdal), pVoid, (Ptr{Cstring}, pVoid), pArgv, psOFB))

GDALInfoOptionsFree(psO) = acare(ccall((:GDALInfoOptionsFree, libgdal), Cvoid, (pVoid,), psO))
GDALInfo(hDataset, psO) = acare(ccall((:GDALInfo, libgdal), Cstring, (pVoid, pVoid), hDataset, psO), true)

#function GDALIdentifyDriver(pFname, pFList)
	#acare(ccall((:GDALIdentifyDriver, libgdal), pVoid, (Cstring, Ptr{Cstring}), pFname, pFList))
#end

GDALTranslateOptionsNew(pArgv, psOFB) =
	acare(ccall((:GDALTranslateOptionsNew, libgdal), pVoid, (Ptr{Cstring}, pVoid), pArgv, psOFB))

function GDALTranslate(pszDestFilename, hSrcDataset, psOptions, pbUsageError)
	acare(ccall((:GDALTranslate, libgdal), pVoid, (Cstring, pVoid, pVoid, Ptr{Cint}), pszDestFilename, hSrcDataset, psOptions, pbUsageError))
end

GDALTranslateOptionsFree(psO) = acare(ccall((:GDALTranslateOptionsFree, libgdal), Cvoid, (pVoid,), psO))

GDALDEMProcessingOptionsNew(pArgv, psOFB) =
	acare(ccall((:GDALDEMProcessingOptionsNew, libgdal), pVoid, (Ptr{Cstring}, pVoid), pArgv, psOFB))

GDALDEMProcessingOptionsFree(psO) = acare(ccall((:GDALDEMProcessingOptionsFree, libgdal), Cvoid, (pVoid,), psO))

function GDALDEMProcessing(pszDestFilename, hSrcDataset, pszProcessing, pszColorFilename, psOptions, pbUE)
	acare(ccall((:GDALDEMProcessing, libgdal), pVoid, (Cstring, pVoid, Cstring, Cstring, pVoid, Ptr{Cint}), pszDestFilename, hSrcDataset, pszProcessing, pszColorFilename, psOptions, pbUE))
end

GDALGrid(pDest, hSrcDS, psO, pbUE) =
	acare(ccall((:GDALGrid, libgdal), pVoid, (Cstring, pVoid, pVoid, Ptr{Cint}), pDest, hSrcDS, psO, pbUE))

GDALGridOptionsFree(psO) = acare(ccall((:GDALGridOptionsFree, libgdal), Cvoid, (pVoid,), psO))
GDALGridOptionsNew(pArgv, psOFB) = acare(ccall((:GDALGridOptionsNew, libgdal), pVoid, (Ptr{Cstring}, pVoid), pArgv, psOFB))

GDALVectorTranslateOptionsNew(pArgv, psOFB) =
	acare(ccall((:GDALVectorTranslateOptionsNew, libgdal), pVoid, (Ptr{Cstring}, pVoid), pArgv, psOFB))

GDALVectorTranslateOptionsFree(psO) = acare(ccall((:GDALVectorTranslateOptionsFree, libgdal), Cvoid, (pVoid,), psO))

function GDALVectorTranslate(pszDest, hDstDS, nSrcCount, pahSrcDS, psO, pbUE)
	acare(ccall((:GDALVectorTranslate, libgdal), pVoid, (Cstring, pVoid, Cint, Ptr{pVoid}, pVoid, Ptr{Cint}), pszDest, hDstDS, nSrcCount, pahSrcDS, psO, pbUE))
end

function GDALWarp(pszDest, hDstDS, nSrcCount, pahSrcDS, psO, pbUE)
	acare(ccall((:GDALWarp, libgdal), pVoid, (Cstring, pVoid, Cint, Ptr{pVoid}, pVoid, Ptr{Cint}), pszDest, hDstDS, nSrcCount, pahSrcDS, psO, pbUE))
end

GDALWarpAppOptionsFree(psO) = acare(ccall((:GDALWarpAppOptionsFree, libgdal), Cvoid, (pVoid,), psO))
GDALWarpAppOptionsNew(pArgv, psOFB) =
	acare(ccall((:GDALWarpAppOptionsNew, libgdal), pVoid, (Ptr{Cstring}, pVoid), pArgv, psOFB))

GDALRasterizeOptionsNew(pArgv, pOptsBin) =
    acare(ccall((:GDALRasterizeOptionsNew, libgdal), pVoid, (Ptr{Cstring}, pVoid), pArgv, pOptsBin))
GDALRasterize(pszDest, hDstDS, hSrcDS, pOpts, pUError) =
    acare(ccall((:GDALRasterize, libgdal), pVoid, (Cstring, pVoid, pVoid, pVoid, Ptr{Cint}), pszDest, hDstDS, hSrcDS, pOpts, pUError))
GDALRasterizeOptionsFree(pOpts) = acare(ccall((:GDALRasterizeOptionsFree, libgdal), Cvoid, (pVoid,), pOpts))

GDALBuildVRTOptionsNew(papszArgv, psOFB) =
	acare(ccall((:GDALBuildVRTOptionsNew, libgdal), pVoid, (Ptr{Cstring}, pVoid), papszArgv, psOFB))
GDALBuildVRT(pszDest, nSrcCount, pahSrcDS, pSrcDSNames, pOpts, pUError) =
    acare(ccall((:GDALBuildVRT, libgdal), pVoid, (Cstring, Cint, Ptr{pVoid}, Ptr{Cstring}, pVoid, Ptr{Cint}), pszDest, nSrcCount, pahSrcDS, pSrcDSNames, pOpts, pUError))
GDALBuildVRTOptionsFree(pOpts) = acare(ccall((:GDALBuildVRTOptionsFree, libgdal), Cvoid, (pVoid,), pOpts))

#function GDALViewshedGenerate(hBand, pDriverName, pTargetName, pCreationOpts, obsX, obsY, obsH, dfTargetHeight, dfVisibleVal, dfInvVal, dfOutOfRangeVal, dfNoDataVal, dfCurvCoeff, eMode, dfMaxDist, pfnProgress, pProgArg, heightMode, pExtraOpts)
	#acare(ccall((:GDALViewshedGenerate, thelib), pVoid, (pVoid, Cstring, Cstring, Ptr{Cstring}, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, UInt32, Cdouble, pVoid, pVoid, UInt32, Ptr{Cstring}), hBand, pDriverName, pTargetName, pCreationOpts, obsX, obsY, obsH, dfTargetHeight, dfVisibleVal, dfInvVal, dfOutOfRangeVal, dfNoDataVal, dfCurvCoeff, eMode, dfMaxDist, pfnProgress, pProgArg, heightMode, pExtraOpts))
#end

VSICurlClearCache() = acare(ccall((:VSICurlClearCache, libgdal), Cvoid, ()))
VSIUnlink(pszFilename) = acare(ccall((:VSIUnlink, libgdal), Cint, (Cstring,), pszFilename))

# ------------------------------------------- ArchGDAL stuff ----------------------------------------------------------

abstract type AbstractDataset end			# needs to have a `ptr::GDALDataset` attribute
abstract type AbstractSpatialRef end		# needs to have a `ptr::GDALSpatialRef` attribute
#abstract type AbstractRasterBand{T} <: AbstractDiskArray{T,2} end # needs to have a `ptr::GDALDataset` attribute
abstract type AbstractRasterBand{T} end		# needs to have a `ptr::GDALDataset` attribute
#abstract type AbstractGeometry <: GeoInterface.AbstractGeometry end	# needs to have a `ptr::GDALGeometry` attribute
abstract type AbstractGeometry  end			# needs to have a `ptr::GDALGeometry` attribute
abstract type AbstractFeature end			# needs to have a `ptr::GDAL.OGRFeatureH` attribute
abstract type AbstractFeatureDefn end		# needs to have a `ptr::GDALFeatureDefn` attribute
abstract type AbstractFeatureLayer end		# needs to have a `ptr::GDALDataset` attribute
abstract type AbstractFieldDefn end			# needs to have a `ptr::GDALFieldDefn` attribute
abstract type AbstractGeomFieldDefn end		# needs to have a `ptr::GDALGeomFieldDefn` attribute

	mutable struct CoordTransform
		ptr::pVoid
	end

	mutable struct Dataset <: AbstractDataset
		ptr::pVoid
		Dataset(ptr::pVoid=C_NULL) = new(ptr)
	end

	mutable struct IDataset <: AbstractDataset
		ptr::pVoid
		function IDataset(ptr::pVoid=C_NULL)
			dataset = new(ptr)
			finalizer(destroy, dataset)
			return dataset
		end
	end

	mutable struct Driver
		ptr::pVoid
	end

	mutable struct FieldDefn <: AbstractFieldDefn
		ptr::pVoid
	end

	mutable struct IFieldDefnView <: AbstractFieldDefn
		ptr::pVoid
		function IFieldDefnView(ptr::pVoid = C_NULL)
			fielddefn = new(ptr)
			finalizer(destroy, fielddefn)
			return fielddefn
		end
	end

	mutable struct RasterBand{T} <: AbstractRasterBand{T}
		ptr::pVoid
	end
	function RasterBand(ptr::pVoid)
		t = _JLTYPE[GDALGetRasterDataType(ptr)]
		RasterBand{t}(ptr)
	end

	mutable struct IRasterBand{T} <: AbstractRasterBand{T}
		ptr::pVoid
		ownedby::AbstractDataset
		function IRasterBand{T}(ptr::pVoid=C_NULL; ownedby::AbstractDataset=Dataset()) where T
			rasterband = new(ptr, ownedby)
			finalizer(destroy, rasterband)
			return rasterband
		end
	end

	function IRasterBand(ptr::pVoid; ownedby = Dataset())
		t = _JLTYPE[GDALGetRasterDataType(ptr)]
		IRasterBand{t}(ptr, ownedby=ownedby)
	end

	mutable struct SpatialRef <: AbstractSpatialRef
		ptr::pVoid
		SpatialRef(ptr::pVoid = C_NULL) = new(ptr)
	end

	mutable struct ISpatialRef <: AbstractSpatialRef
		ptr::pVoid
		function ISpatialRef(ptr::pVoid=C_NULL)
			spref = new(ptr)
			finalizer(destroy, spref)
			return spref
		end
	end

	mutable struct Geometry <: AbstractGeometry
		ptr::pVoid
		Geometry(ptr::pVoid = C_NULL) = new(ptr)
	end
	
	mutable struct IGeometry <: AbstractGeometry
		ptr::pVoid
		function IGeometry(ptr::pVoid=C_NULL)
			geom = new(ptr)
			finalizer(destroy, geom)
			return geom
		end
	end

	mutable struct FeatureLayer <: AbstractFeatureLayer
		ptr::pVoid
	end

	mutable struct IFeatureLayer <: AbstractFeatureLayer
		ptr::pVoid
		ownedby::AbstractDataset
		spatialref::AbstractSpatialRef
		function IFeatureLayer(ptr::pVoid=C_NULL; ownedby::AbstractDataset=Dataset(),
				spatialref::AbstractSpatialRef=SpatialRef())
			layer = new(ptr, ownedby, spatialref)
			finalizer(destroy, layer)
			return layer
		end
	end

	mutable struct Feature
		ptr::pVoid
	end
	
	mutable struct FeatureDefn <: AbstractFeatureDefn
		ptr::pVoid
	end
	
	mutable struct IFeatureDefnView <: AbstractFeatureDefn
		ptr::pVoid
		function IFeatureDefnView(ptr::pVoid=C_NULL)
			featuredefn = new(ptr)
			finalizer(destroy, featuredefn)
			return featuredefn
		end
	end

	mutable struct IGeomFieldDefnView <: AbstractGeomFieldDefn
		ptr::pVoid
		function IGeomFieldDefnView(ptr::pVoid=C_NULL)
			geomdefn = new(ptr)
			finalizer(destroy, geomdefn)
			return geomdefn
		end
	end

	mutable struct GeomFieldDefn <: AbstractGeomFieldDefn
		ptr::pVoid
		spatialref::AbstractSpatialRef
		function GeomFieldDefn(ptr::pVoid=C_NULL; spatialref::AbstractSpatialRef=SpatialRef())
			return new(ptr, spatialref)
		end
	end

	mutable struct ColorTable ptr::pVoid end

	mutable struct DriverManager
		function DriverManager()
			drivermanager = new()
			GDALAllRegister()
			finalizer((dm,) -> GDALDestroyDriverManager(), drivermanager)
			return drivermanager
		end
	end

	const _GDALTYPE = Dict{DataType, Int32}(
		Any     => GDT_Unknown,
		UInt8   => GDT_Byte,
		UInt16  => GDT_UInt16,
		Int16   => GDT_Int16,
		UInt32  => GDT_UInt32,
		Int32   => GDT_Int32,
		Float32 => GDT_Float32,
		Float64 => GDT_Float64)

	const _JLTYPE = Dict{Int32, DataType}(
		GDT_Unknown    => Any,
		GDT_Byte       => UInt8,
		GDT_UInt16     => UInt16,
		GDT_Int16      => Int16,
		GDT_UInt32     => UInt32,
		GDT_Int32      => Int32,
		GDT_Float32    => Float32,
		GDT_Float64    => Float64,
		UInt32(14)     => UInt8)		# TEMPORARY to workaround a GDAL BUG

	macro gdal(args...)
		@assert length(args) > 0
		@assert args[1].head == :(::)
		fhead = (args[1].args[1], libgdal)
		returntype = args[1].args[2]
		argtypes = Expr(:tuple, [esc(a.args[2]) for a in args[2:end]]...)
		args = [esc(a.args[1]) for a in args[2:end]]
		return quote ccall($fhead, $returntype, $argtypes, $(args...)) end
	end

	macro cplerr(code, message)
		return quote
			($(esc(code)) != CE_None) && error($message)
		end
	end

	macro cplwarn(code, message)
		return quote
			($(esc(code)) != CE_None) && @warn $message
		end
	end

	macro cplprogress(progressfunc)
		@cfunction($(esc(progressfunc)),Cint,(Cdouble,Cstring,pVoid))
	end

	macro ogrerr(code, message)
		return quote
			($(esc(code)) != OGRERR_NONE) && error($message)
		end
	end

	struct RasterDataset{T,DS}
		ds::DS
		size::Tuple{Int,Int,Int}
	end

	RasterDataset(ds::RasterDataset) = RasterDataset(ds.ds)

	function RasterDataset(ds::AbstractDataset)
		iszero(nraster(ds)) && throw(ArgumentError("The Dataset does not contain any raster bands"))
		s = _common_size(ds)
		RasterDataset{_dataset_type(ds), typeof(ds)}(ds, s)
	end

	# Forward a few functions
	# Here we try to include all functions that are relevant for raster-like datasets.
	for f in (:getgeotransform, :nraster, :getband, :getproj,
		:width, :height, :destroy, :getdriver, :filelist, :listcapability, 
		:ngcp, :copy, :write, :testcapability, :setproj!, :buildoverviews!)
		eval(:($(f)(x::RasterDataset, args...; kwargs...) = $(f)(x.ds, args...; kwargs...)))
	end

	testcapability(ds::AbstractDataset, ability::AbstractString) = Bool(GDALDatasetTestCapability(ds.ptr, ability))
	function listcapability(dataset::AbstractDataset, capabilities = ("CreateLayer", "DeleteLayer",
			"CreateGeomFieldAfterCreateLayer", "CurveGeometries", "Transactions", "EmulatedTransactions"))
		return Dict{String, Bool}(c => testcapability(dataset, c) for c in capabilities)
	end

	function getgeotransform!(dataset::AbstractDataset, transform::Vector{Cdouble})
		@assert length(transform) == 6
		result = GDALGetGeoTransform(dataset.ptr, pointer(transform))
		@cplerr result "Failed to get geotransform"
		return transform
	end
	getgeotransform(dataset::AbstractDataset) = getgeotransform!(dataset, Array{Cdouble}(undef, 6))
	
	function setgeotransform!(dataset::AbstractDataset, transform::Vector{Cdouble})
		@assert length(transform) == 6
		result = GDALSetGeoTransform(dataset.ptr, pointer(transform))
		@cplerr result "Failed to transform raster dataset"
		return dataset
	end

	function createlayer(; name::AbstractString="", dataset::AbstractDataset=create(getdriver("Memory")),
		geom::UInt32=wkbUnknown, spatialref::AbstractSpatialRef=SpatialRef(), options=Ptr{Cstring}(C_NULL))
		return IFeatureLayer(GDALDatasetCreateLayer(dataset.ptr, name, spatialref.ptr, geom, options),
							 ownedby=dataset, spatialref=spatialref)
	end
	#= function unsafe_createlayer(; name::AbstractString="", dataset::AbstractDataset=create(getdriver("Memory")),
		geom::UInt32=wkbUnknown, spatialref::AbstractSpatialRef=SpatialRef(), options=Ptr{Cstring}(C_NULL))
	return FeatureLayer(GDAL.gdaldatasetcreatelayer(dataset.ptr, name, spatialref.ptr, geom, options))
	end =#

	function ComputeMedianCutPCT(red::AbstractRasterBand, green::AbstractRasterBand, blue::AbstractRasterBand, nColors::Integer, hColorTable::ColorTable, pfnIncPix=C_NULL, pfnProg=C_NULL, pProgArg=C_NULL)
		GDALComputeMedianCutPCT(red.ptr, green.ptr, blue.ptr, pfnIncPix, nColors, hColorTable.ptr, pfnProg, pProgArg)
	end

	function DitherRGB2PCT(red::AbstractRasterBand, green::AbstractRasterBand, blue::AbstractRasterBand, hTarget::AbstractRasterBand, hColorTable::ColorTable, pfnProg=C_NULL, pProgArg=C_NULL)
		GDALDitherRGB2PCT(red.ptr, green.ptr, blue.ptr, hTarget.ptr, hColorTable.ptr, pfnProg, pProgArg)
	end

	unsafe_createfielddefn(name::AbstractString, etype::UInt32) = FieldDefn(OGR_Fld_Create(name, etype))

	function addfielddefn!(layer::AbstractFeatureLayer, name::AbstractString, etype::UInt32; nwidth::Integer=0,
						   nprecision::Integer=0, justify::UInt32=UInt32(0), approx::Bool=false)
		fielddefn = unsafe_createfielddefn(name, etype)
		setparams!(fielddefn, name, etype, nwidth=nwidth, nprecision=nprecision, justify=justify)
		addfielddefn!(layer, fielddefn)
		destroy(fielddefn)
		layer
	end

	function addfielddefn!(featuredefn::FeatureDefn, fielddefn::FieldDefn)
		OGR_FD_AddFieldDefn(featuredefn.ptr, fielddefn.ptr)
		return featuredefn
	end

	function addfielddefn!(layer::AbstractFeatureLayer, field::AbstractFieldDefn, approx::Bool=false)
		result = OGR_L_CreateField(layer.ptr, field.ptr, approx)
		@ogrerr result "Failed to create new field"
		return layer
	end

	function createfeature(f::Function, featuredefn::FeatureDefn)
		feature = unsafe_createfeature(featuredefn)
		reference(featuredefn)
		try
			f(feature)
		finally
			destroy(feature)
			dereference(featuredefn)
		end
	end

	unsafe_createfeature(layer::AbstractFeatureLayer) = unsafe_createfeature(layerdefn(layer))
	unsafe_createfeature(featuredefn::AbstractFeatureDefn) = Feature(pVoid(OGR_F_Create(featuredefn.ptr)))

	function createfeature(f::Function, layer::AbstractFeatureLayer)
		feature = unsafe_createfeature(layer)
		try
			f(feature)
			setfeature!(layer, feature)
		finally
			destroy(feature)
		end
	end

	function setfeature!(layer::AbstractFeatureLayer, feature::Feature)
		result = OGR_L_SetFeature(layer.ptr, feature.ptr)
		@ogrerr result "Failed to set feature."
		return layer
	end

	function addfeature!(layer::AbstractFeatureLayer, feature::Feature)
		result = OGR_L_CreateFeature(layer.ptr, feature.ptr)
		@ogrerr result "Failed to create and write feature in layer."
		return layer
	end

	getfeaturedefn(feature::Feature) = IFeatureDefnView(OGR_F_GetDefnRef(feature.ptr))
	unsafe_getfeature(layer::AbstractFeatureLayer, i::Integer) = Feature(pVoid(OGR_L_GetFeature(layer.ptr, i)))

	function getspatialref(layer::AbstractFeatureLayer)::ISpatialRef
		result = OGR_L_GetSpatialRef(layer.ptr)
		# NOTE(yeesian): we make a clone here so that the spatialref does not depend on the FeatureLayer/Dataset.
		return (result == C_NULL) ? ISpatialRef() : ISpatialRef(OSRClone(result))
	end

	function unsafe_getspatialref(layer::AbstractFeatureLayer)::SpatialRef
		result = OGR_L_GetSpatialRef(layer.ptr)
		# NOTE(yeesian): we make a clone here so that the spatialref does not depend on the FeatureLayer/Dataset.
		return (result == C_NULL) ? SpatialRef() : SpatialRef(OSRClone(result))
	end

	function setparams!(fielddefn::FieldDefn, name::AbstractString, etype::UInt32;
						nwidth::Integer=0, nprecision::Integer=0, justify::UInt32=UInt32(0))
		OGR_Fld_Set(fielddefn.ptr, name, etype, nwidth, nprecision, justify)
		return fielddefn
	end

	function setpoint!(geom::AbstractGeometry, i::Integer, x::Real, y::Real, z::Real)
		OGR_G_SetPoint(geom.ptr, i, x, y, z);	return geom
	end

	function setpoint!(geom::AbstractGeometry, i::Integer, x::Real, y::Real)
		OGR_G_SetPoint_2D(geom.ptr, i, x, y);	return geom
	end

	function _dataset_type(ds::AbstractDataset)
		alldatatypes = map(1:nraster(ds)) do i
			b = getband(ds, i)
			pixeltype(b)
		end
		reduce(promote_type, alldatatypes)
	end

	function _common_size(ds::AbstractDataset)
		nr = nraster(ds)
		allsizes = map(1:nr) do i
			b = getband(ds, i)
			size(b)
		end
		s = unique(allsizes)
		length(s) == 1 || throw(DimensionMismatch("Can not coerce bands to single dataset, different sizes found"))
		Int.((s[1]..., nr))
	end

	function destroy(drv::Driver)
		GDALDestroyDriver(drv.ptr);	drv.ptr = C_NULL
	end

	function destroy(dataset::AbstractDataset)
		GDALClose(dataset.ptr);		dataset.ptr = C_NULL
	end

	function destroy(spref::AbstractSpatialRef)
		OSRDestroySpatialReference(spref.ptr);		spref.ptr = C_NULL
	end
	
	function destroy(obj::CoordTransform)
		OCTDestroyCoordinateTransformation(obj.ptr)
		obj.ptr = C_NULL
	end

	function destroy(band::AbstractRasterBand)
		band.ptr = pVoid(C_NULL);		return band
	end

	function destroy(band::IRasterBand)
		band.ptr = pVoid(C_NULL)
		band.ownedby = Dataset()
		return band
	end

	function destroy(layer::AbstractFeatureLayer)
		layer.ptr = pVoid(C_NULL)
	end
	
	function destroy(layer::IFeatureLayer)
		layer.ptr = pVoid(C_NULL)
		layer.ownedby = Dataset()
		layer.spatialref = SpatialRef()
	end

	function destroy(featuredefn::IFeatureDefnView)
		featuredefn.ptr = C_NULL;	return featuredefn
	end

	function destroy(feature::Feature)
		OGR_F_Destroy(feature.ptr)
		feature.ptr = C_NULL
	end

	function destroy(featuredefn::FeatureDefn)
		OGR_FD_Destroy(featuredefn.ptr)
		featuredefn.ptr = C_NULL
		return featuredefn
	end

	function destroy(geom::AbstractGeometry)
		OGR_G_DestroyGeometry(geom.ptr)
		geom.ptr = C_NULL
	end

	function destroy(fielddefn::FieldDefn)
		OGR_Fld_Destroy(fielddefn.ptr)
		fielddefn.ptr = C_NULL
		return fielddefn
	end

	function destroy(geomdefn::GeomFieldDefn)
		OGR_GFld_Destroy(geomdefn.ptr)
		geomdefn.ptr = C_NULL
		geomdefn.spatialref = SpatialRef()
		return geomdefn
	end

	function destroy(fielddefn::IFieldDefnView)
		fielddefn.ptr = C_NULL
		return fielddefn
	end	

	function destroy(geomdefn::IGeomFieldDefnView)
		geomdefn.ptr = C_NULL
		return geomdefn
	end

	identifydriver(fname::AbstractString) = Driver(GDALIdentifyDriver(fname, C_NULL))

	function create(fname::AbstractString; driver::Driver=identifydriver(fname), width::Integer=0,
		height::Integer=0, nbands::Integer=0, dtype::DataType=Any, options=Ptr{Cstring}(C_NULL), I::Bool=true)
		r = GDALCreate(driver.ptr, fname, width, height, nbands, _GDALTYPE[dtype], options)
		return (I) ? IDataset(r) : Dataset(r)
	end
	unsafe_create(fname::AbstractString; driver::Driver=identifydriver(fname), width::Integer=0,
		height::Integer=0, nbands::Integer=0, dtype::DataType=Any, options=Ptr{Cstring}(C_NULL), I::Bool=false) =
		create(fname; driver=driver, width=width, height=height, nbands=nbands, dtype=dtype, options=options, I=I)

	function create(driver::Driver; filename::AbstractString=string("/vsimem/$(gensym())"), width::Integer=0,
		height::Integer=0, nbands::Integer=0, dtype::DataType=Any, options=Ptr{Cstring}(C_NULL), I::Bool=true)
		r = GDALCreate(driver.ptr, filename, width, height, nbands, _GDALTYPE[dtype], options)
		return (I) ? IDataset(r) : Dataset(r)
	end
	unsafe_create(driver::Driver; filename::AbstractString=string("/vsimem/$(gensym())"), width::Integer=0,
		height::Integer=0, nbands::Integer=0, dtype::DataType=Any, options=Ptr{Cstring}(C_NULL), I::Bool=false) =
		create(driver; filename=filename, width=width, height=height, nbands=nbands, dtype=dtype, options=options, I=I)

	copy(dataset::AbstractDataset; filename::AbstractString=string("/vsimem/$(gensym())"), driver::Driver=getdriver(dataset),
		strict::Bool=false, options=Ptr{Cstring}(C_NULL), progressfunc::Function=GDALDummyProgress, progressdata=C_NULL)::IDataset =
		IDataset(DALCreateCopy(driver.ptr, filename, dataset.ptr, strict, options, C_NULL, progressdata))

	unsafe_copy(dataset::AbstractDataset; filename::AbstractString=string("/vsimem/$(gensym())"),
		driver::Driver=getdriver(dataset), strict::Bool=false, options=Ptr{Cstring}(C_NULL),
		progressfunc::Function=GDALDummyProgress, progress=C_NULL)::Dataset =
		Dataset(GDALCreateCopy(driver.ptr, filename, dataset.ptr, strict, options, C_NULL, progress))

	function read(fname::AbstractString; flags = GDAL_OF_READONLY | GDAL_OF_VERBOSE_ERROR,
		alloweddrivers=Ptr{Cstring}(C_NULL), options=Ptr{Cstring}(C_NULL), siblingfiles=Ptr{Cstring}(C_NULL), I::Bool=true)
		# The COOKIEFILE (and other options) is crucial for authenticated accesses. The shit is that if we asked once
		# without the necessary options: "GDAL_DISABLE_READDIR_ON_OPEN","YES"; "CPL_VSIL_CURL_ALLOWED_EXTENSIONS","TIF";
		# "CPL_VSIL_CURL_USE_HEAD","FALSE"; "GDAL_HTTP_COOKIEFILE", "..."; "GDAL_HTTP_COOKIEJAR","...", big shit follows
		# Next line is a patch to try to catch that situation by cleaning the vsi cache. Maybe it will backfire, who knows.
		(startswith(fname, "/vsi") && CPLGetConfigOption("GDAL_HTTP_COOKIEFILE", C_NULL) !== nothing) && VSICurlClearCache()
		r = GDALOpenEx(fname, Int(flags), alloweddrivers, options, siblingfiles)
		return (I) ? IDataset(r) : Dataset(r)
	end
	unsafe_read(fname::AbstractString; flags=GDAL_OF_READONLY | GDAL_OF_VERBOSE_ERROR, alloweddrivers=Ptr{Cstring}(C_NULL),
		options=Ptr{Cstring}(C_NULL), siblingfiles=Ptr{Cstring}(C_NULL), I::Bool=false) =
		read(fname; flags=flags, alloweddrivers=alloweddrivers, options=options, siblingfiles=siblingfiles, I=I)

	read!(rb::AbstractRasterBand, buffer::Matrix{<:Real}) = rasterio!(rb, buffer, GF_Read)

	function read!(rb::AbstractRasterBand, buffer::Matrix{<:Real}, xoffset::Integer, yoffset::Integer,
			xsize::Integer, ysize::Integer)
		rasterio!(rb, buffer, xoffset, yoffset, xsize, ysize)
		return buffer
	end

	function read!(rb::AbstractRasterBand, buffer::Matrix{<:Real}, rows::UnitRange{<:Integer}, cols::UnitRange{<:Integer})
		rasterio!(rb, buffer, rows, cols);		return buffer
	end

	read(rb::AbstractRasterBand) = rasterio!(rb, Array{pixeltype(rb)}(undef, width(rb), height(rb)))

	function read(rb::AbstractRasterBand, xoffset::Integer, yoffset::Integer, xsize::Integer, ysize::Integer)
		buffer = Array{pixeltype(rb)}(undef, xsize, ysize)
		rasterio!(rb, buffer, xoffset, yoffset, xsize, ysize);		return buffer
	end

	function read(rb::AbstractRasterBand, rows::UnitRange{<:Integer}, cols::UnitRange{<:Integer})
		buffer = Array{pixeltype(rb)}(undef, length(cols), length(rows))
		rasterio!(rb, buffer, rows, cols);		return buffer
	end

	function read!(dataset::AbstractDataset, buffer::Matrix{<:Real}, i::Integer)
		read!(getband(dataset, i), buffer);		return buffer
	end
	
	function read!(dataset::AbstractDataset, buffer::Array{<:Real, 3}, indices)
		rasterio!(dataset, buffer, indices, GF_Read);	return buffer
	end
	
	function read!(dataset::AbstractDataset, buffer::Array{<:Real, 3})
		nband = nraster(dataset)
		@assert size(buffer, 3) == nband
		rasterio!(dataset, buffer, collect(Cint, 1:nband), GF_Read)
		return buffer
	end
	read!(ds::IDataset, buffer::Array{<:Real, 3}) = read!(Dataset(ds.ptr), buffer)
	
	function read!(dataset::AbstractDataset, buffer::Matrix{<:Real}, i::Integer, xoffset::Integer,
			yoffset::Integer, xsize::Integer, ysize::Integer)
		read!(getband(dataset, i), buffer, xoffset, yoffset, xsize, ysize)
		return buffer
	end
	
	function read!(dataset::AbstractDataset, buffer::Array{<:Real, 3}, indices, xoffset::Integer,
			yoffset::Integer, xsize::Integer, ysize::Integer)
		rasterio!(dataset, buffer, indices, xoffset, yoffset, xsize, ysize)
		return buffer
	end
	
	function read!(dataset::AbstractDataset, buffer::Matrix{<:Real}, i::Integer,
			rows::UnitRange{<:Integer}, cols::UnitRange{<:Integer})
		read!(getband(dataset, i), buffer, rows, cols)
		return buffer
	end
	
	function read!(dataset::AbstractDataset, buffer::Array{<:Real, 3}, indices,
			rows::UnitRange{<:Integer}, cols::UnitRange{<:Integer})
		rasterio!(dataset, buffer, indices, rows, cols);	return buffer
	end
	
	read(dataset::AbstractDataset, i::Integer) = read(getband(dataset, i))
	
	function read(dataset::AbstractDataset, indices)
		buffer = Array{pixeltype(getband(dataset, indices[1]))}(undef, width(dataset), height(dataset), length(indices))
		rasterio!(dataset, buffer, indices);		return buffer
	end
	
	function read(dataset::AbstractDataset)
		buffer = Array{pixeltype(getband(dataset, 1))}(undef, width(dataset), height(dataset), nraster(dataset))
		read!(dataset, buffer);		return buffer
	end
	read(dataset::RasterDataset) = read(dataset.ds)
	
	function read(dataset::AbstractDataset, i::Integer, xoffset::Integer, yoffset::Integer, xsize::Integer, ysize::Integer)
		buffer = read(getband(dataset, i), xoffset, yoffset, xsize, ysize)
		return buffer
	end
	
	function read(dataset::AbstractDataset, indices, xoffset::Integer, yoffset::Integer, xsize::Integer, ysize::Integer)
		buffer = Array{pixeltype(getband(dataset, indices[1]))}(undef, xsize, ysize, length(indices))
		rasterio!(dataset, buffer, indices, xsize, ysize, xoffset, yoffset)
		return buffer
	end
	
	function read(dataset::AbstractDataset, i::Integer, rows::UnitRange{<:Integer}, cols::UnitRange{<:Integer})
		buffer = read(getband(dataset, i), rows, cols);		return buffer
	end
	
	function read(dataset::AbstractDataset, indices, rows::UnitRange{<:Integer}, cols::UnitRange{<:Integer})
		buffer = Array{pixeltype(getband(dataset, indices[1]))}(undef, length(cols), length(rows), length(indices))
		rasterio!(dataset, buffer, indices, rows, cols);	return buffer
	end

	function rasterio!(dataset::AbstractDataset, buffer::Array{<:Real, 3}, bands, access::UInt32=GF_Read,
		pxspace::Integer=0, linespace::Integer=0, bandspace::Integer=0)
		rasterio!(dataset, buffer, bands, 0, 0, size(buffer, 1), size(buffer, 2), access, pxspace, linespace, bandspace)
		return buffer
	end

	function rasterio!(dataset::AbstractDataset, buffer::Array{<:Real, 3}, bands, rows::UnitRange{<:Integer},
			cols::UnitRange{<:Integer}, access::UInt32=GF_Read, pxspace::Integer=0, linespace::Integer=0, bandspace::Integer=0)
		xsize = cols[end] - cols[1] + 1; xsize < 0 && error("invalid window width")
		ysize = rows[end] - rows[1] + 1; ysize < 0 && error("invalid window height")
		rasterio!(dataset, buffer, bands, cols[1], rows[1], xsize, ysize, access, pxspace, linespace, bandspace)
		return buffer
	end

	function rasterio!(rasterband::AbstractRasterBand, buffer::Matrix{<:Real}, access::UInt32=GF_Read,
			pxspace::Integer=0, linespace::Integer=0)
		rasterio!(rasterband, buffer, 0, 0, width(rasterband), height(rasterband), access, pxspace, linespace)
		return buffer
	end

	function rasterio!(rasterband::AbstractRasterBand, buffer::Matrix{<:Real}, rows::UnitRange{<:Integer},
			cols::UnitRange{<:Integer}, access::UInt32=GF_Read, pxspace::Integer=0, linespace::Integer=0)
		xsize = length(cols); xsize < 1 && error("invalid window width")
		ysize = length(rows); ysize < 1 && error("invalid window height")
		rasterio!(rasterband, buffer, cols[1]-1, rows[1]-1, xsize, ysize, access, pxspace, linespace)
		return buffer
	end

	for (T,GT) in _GDALTYPE
		eval(quote
			function rasterio!(dataset::AbstractDataset, buffer::Array{$T, 3}, bands, xoffset::Int, yoffset::Int,
					xsize::Integer, ysize::Integer, access::UInt32=GF_Read, pxspace::Integer=0, linespace::Integer=0,
					bandspace::Integer=0, extraargs=Ptr{GDALRasterIOExtraArg}(C_NULL), pad::Int=0)
				(dataset == C_NULL) && error("Can't read invalid rasterband")
				xbsize, ybsize, zbsize = size(buffer)
				nband = length(bands)
				bands = isa(bands, Vector{Cint}) ? bands : Cint.(collect(bands))
				@assert nband == zbsize
				poffset = 0
				if (pad != 0)
					linespace = xbsize * sizeof($T)
					poffset = (pad * xbsize + pad) * sizeof($T)
					xbsize, ybsize = xsize, ysize
				end
				result = ccall((:GDALDatasetRasterIOEx,libgdal), UInt32, 
							   (pVoid, UInt32, Cint, Cint, Cint, Cint, pVoid, Cint, Cint, UInt32, Cint,
							   Ptr{Cint}, Clonglong, Clonglong, Clonglong, Ptr{GDALRasterIOExtraArg}),
							   dataset.ptr, access, xoffset, yoffset, xsize, ysize, pointer(buffer)+poffset, xbsize,
							   ybsize, $GT, nband, pointer(bands), pxspace, linespace, bandspace, extraargs)
				@cplerr result "Access in DatasetRasterIO failed."
				return buffer
			end

			function rasterio!(rasterband::AbstractRasterBand, buffer::Matrix{$T}, xoffset::Integer, yoffset::Integer,
					xsize::Integer, ysize::Integer, access::UInt32=GF_Read, pxspace::Integer=0,
					linespace::Integer=0, extraargs=Ptr{GDALRasterIOExtraArg}(C_NULL), pad::Int=0)
				(rasterband == C_NULL) && error("Can't read invalid rasterband")
				xbsize, ybsize = size(buffer)
				poffset = 0
				if (pad != 0)
					linespace = xbsize * sizeof($T)
					poffset = (pad * xbsize + pad) * sizeof($T)
					xbsize, ybsize = xsize, ysize
				end
				result = ccall((:GDALRasterIOEx,libgdal),UInt32,
					(pVoid,UInt32,Cint,Cint,Cint,Cint,pVoid, Cint,Cint,UInt32,Clonglong, Clonglong,
					Ptr{GDALRasterIOExtraArg}),
					rasterband.ptr,access,xoffset, yoffset,xsize,ysize,pointer(buffer)+poffset,xbsize,ybsize,$GT,
					pxspace, linespace, extraargs)
				@cplerr result "Access in RasterIO failed."
				return buffer
			end
		end)
	end

	function write!(rb::AbstractRasterBand, buffer::Matrix{<:Real})
		rasterio!(rb, buffer, GF_Write)
		return buffer
	end

	function write!(rb::AbstractRasterBand, buffer::Matrix{<:Real}, xoffset::Integer, yoffset::Integer,
		xsize::Integer, ysize::Integer)
		rasterio!(rb, buffer, xoffset, yoffset, xsize, ysize, GF_Write)
		return buffer
	end

	function write!(rb::AbstractRasterBand, buffer::Matrix{<:Real}, rows::UnitRange{<:Integer}, cols::UnitRange{<:Integer})
		rasterio!(rb, buffer, rows, cols, GF_Write)
		return buffer
	end

	function write!(dataset::AbstractDataset, buffer::Matrix{<:Real}, i::Integer)
		write!(getband(dataset, i), buffer)
		return dataset
	end

	function write!(dataset::AbstractDataset, buffer::Array{<:Real, 3}, indices)
		rasterio!(dataset, buffer, indices, GF_Write)
		return dataset
	end

	function write!(dataset::AbstractDataset, buffer::Matrix{<:Real}, i::Integer, xoffset::Integer,
			yoffset::Integer, xsize::Integer, ysize::Integer)
		write!(getband(dataset, i), buffer, xoffset, yoffset, xsize, ysize)
		return dataset
	end

	function write!(dataset::AbstractDataset, buffer::Array{<:Real, 3}, indices, xoffset::Integer,
			yoffset::Integer, xsize::Integer, ysize::Integer)
		rasterio!(dataset, buffer, indices, xoffset, yoffset, xsize, ysize, GF_Write)
		return dataset
	end

	function write!(dataset::AbstractDataset, buffer::Matrix{<:Real}, i::Integer,
			rows::UnitRange{<:Integer}, cols::UnitRange{<:Integer})
		write!(getband(dataset, i), buffer, rows, cols)
		return dataset
	end

	function write!(dataset::AbstractDataset, buffer::Array{<:Real, 3}, indices,
			rows::UnitRange{<:Integer}, cols::UnitRange{<:Integer})
		rasterio!(dataset, buffer, indices, rows, cols, GF_Write)
		return dataset
	end

	write(ds::AbstractDataset, fname::AbstractString; kw...) = destroy(unsafe_copy(ds, filename=fname; kw...))

	getdriver(ds::AbstractDataset) = Driver(GDALGetDatasetDriver(ds.ptr))
	getdriver(i::Integer) = Driver(GDALGetDriver(i))
	getdriver(name::AbstractString) = Driver(GDALGetDriverByName(name))

	getband(dataset::AbstractDataset, i::Integer=1) = IRasterBand(GDALGetRasterBand(dataset.ptr, i), ownedby=dataset)
	getband(ds::RasterDataset, i::Integer=1) = getband(ds.ds, i)
	getproj(ds::AbstractDataset) = GDALGetProjectionRef(ds.ptr)
	getproj(layer::AbstractFeatureLayer) = SpatialRef(OGR_L_GetSpatialRef(layer.ptr))
	function getproj(name::AbstractString; proj4::Bool=false, wkt::Bool=false, epsg::Bool=false)
		ds = unsafe_read(name)
		prj = getproj(ds)
		GDALClose(ds.ptr)
		return (!proj4) ? prj : startswith(prj, "PROJCS") ? toPROJ4(importWKT(prj)) : prj
	end
	function _getproj(G_I, proj4::Bool, wkt::Bool, epsg::Bool)
		prj, _prj = "", 0
		if (proj4)
			(G_I.proj4 != "") && (prj = G_I.proj4)
			(prj == "" && G_I.wkt  != "") && (prj = toPROJ4(importWKT(G_I.wkt)))
			(prj == "" && G_I.epsg != 0)  && (prj = toPROJ4(importEPSG(G_I.epsg)))
		elseif (wkt)
			(G_I.wkt != "") && (prj = G_I.wkt)
			(prj == "" && G_I.proj4 != "") && (prj = toWKT(importPROJ4(G_I.proj4)))
			(prj == "" && G_I.epsg  != 0)  && (prj = toWKT(importEPSG(G_I.epsg)))
		elseif (epsg)
			(G_I.epsg != 0) && (_prj = G_I.epsg)
			(_prj == 0 && G_I.wkt   != "") && (_prj = toEPSG(importWKT(G_I.wkt)))
			(_prj == 0 && G_I.proj4 != "") && (_prj = toEPSG(importPROJ4(G_I.proj4)))
		end
		return (_prj != 0) ? _prj : prj
		#prj = G_I.proj4
		#(prj == "") && (prj = G_I.wkt)
		#return (!proj4) ? prj : startswith(prj, "PROJCS") ? toPROJ4(importWKT(prj)) : prj
	end
	getproj(G::GMT.GMTgrid;  proj4::Bool=false, wkt::Bool=false, epsg::Bool=false) = _getproj(G, proj4, wkt, epsg)
	getproj(I::GMT.GMTimage; proj4::Bool=false, wkt::Bool=false, epsg::Bool=false) = _getproj(I, proj4, wkt, epsg)
	getproj(D::GMT.GMTdataset; proj4::Bool=false, wkt::Bool=false, epsg::Bool=false) = _getproj(D, proj4, wkt, epsg)
	getproj(D::Vector{<:GMT.GMTdataset}; proj4::Bool=false, wkt::Bool=false, epsg::Bool=false) = _getproj(D[1], proj4, wkt, epsg)

	getmetadata(ds::AbstractDataset) = GDALGetMetadata(ds.ptr, C_NULL)
	function getmetadata(name::AbstractString)
		ds = unsafe_read(name)
		meta = GDALGetMetadata(ds.ptr, C_NULL)
		GDALClose(ds.ptr)
		meta
	end

	function getmetadataitem(obj, name::AbstractString; domain::AbstractString="")::String
		item = GDALGetMetadataItem(obj.ptr, name, domain)
		return item === nothing ? "" : item
	end

	setmetadataitem(obj, name::AbstractString, value::AbstractString; domain::AbstractString="")::UInt32 =
		GDALSetMetadataItem(obj.ptr, name, value, domain)

	getpoint(geom::AbstractGeometry, i::Integer) = getpoint!(geom, i, Ref{Cdouble}(), Ref{Cdouble}(), Ref{Cdouble}())
	function getpoint!(geom::AbstractGeometry, i::Integer, x, y, z)
		OGR_G_GetPoint(geom.ptr, i, x, y, z)
		return (x[], y[], z[])
	end
	getx(geom::AbstractGeometry, i::Integer) = OGR_G_GetX(geom.ptr, i)
	gety(geom::AbstractGeometry, i::Integer) = OGR_G_GetY(geom.ptr, i)
	getz(geom::AbstractGeometry, i::Integer) = OGR_G_GetZ(geom.ptr, i)
#=
function OGR_G_GetPoints(hGeom, pabyX, nXStride, pabyY, nYStride, pabyZ, nZStride)
	acare(ccall((:OGR_G_GetPoints, libgdal), Cint, (pVoid, pVoid, Cint, pVoid, Cint, pVoid, Cint),
					 hGeom, pabyX, nXStride, pabyY, nYStride, pabyZ, nZStride))
end

	getpoints(geom::AbstractGeometry) = getpoints!(geom, Ref{Cdouble}(), nx, Ref{Cdouble}(), nx, Ref{Cdouble}(), nz)
	function getpoints!(hGeom::Ptr{pVoid}, x, nXStride::Integer, y, nYStride::Integer, z, nZStride::Integer)
		OGR_G_GetPoints(geom.ptr, x, nXstride, y, nYstride, z, nZstride)
		return (x[], y[], z[])
	end
=#

	readraster(s::String; kwargs...) = RasterDataset(read(s; kwargs...))
	readraster(args...; kwargs...) = RasterDataset(unsafe_read(args...; kwargs...))

	shortname(drv::Driver) = GDALGetDriverShortName(drv.ptr)
	longname(drv::Driver) = GDALGetDriverLongName(drv.ptr)
	options(drv::Driver) = GDALGetDriverCreationOptionList(drv.ptr)
	driveroptions(name::AbstractString) = options(getdriver(name))

	function unsafe_executesql(dataset::AbstractDataset, query::AbstractString; dialect::AbstractString="",
        spatialfilter::Geometry=Geometry(pVoid(C_NULL)))
    	return FeatureLayer(pVoid(GDALDatasetExecuteSQL(dataset.ptr, query, spatialfilter.ptr, dialect)))
	end
	function executesql(f::Function, dataset::Dataset, args...)
		result = unsafe_executesql(dataset, args...)
		try
			f(result)
		finally
			releaseresultset(dataset, result)
		end
	end

	function releaseresultset(dataset::AbstractDataset, layer::FeatureLayer)
		# This function should only be used to deallocate OGRLayers resulting from an
		# ExecuteSQL() call on the same GDALDataset. Failure to deallocate a results set
		# before destroying the GDALDataset may cause errors.
		GDALDatasetReleaseResultSet(dataset.ptr, layer.ptr)
		destroy(layer)
	end

	function inspect(query, filename)
		# This function was 'stealed' from ArchGDAL future documentation
		read(filename) do dataset
			executesql(dataset, query) do results
				print(results)
			end
		end
	end

	function gdalwarp(datasets::Vector{Dataset}, options=String[]; dest="/vsimem/tmp", gdataset=false, save::AbstractString="")
		(save != "") && (dest = save)
		options = GDALWarpAppOptionsNew(options, C_NULL)
		usage_error = Ref{Cint}()
		result = GDALWarp(dest, C_NULL, length(datasets), [ds.ptr for ds in datasets], options, usage_error)
		GDALWarpAppOptionsFree(options)
		if (dest != "/vsimem/tmp")
			GDALClose(result);		return nothing
		end
		return (gdataset) ? IDataset(result) : gd2gmt(IDataset(result))
	end
	gdalwarp(ds::Dataset, opts=String[]; dest="/vsimem/tmp", gdataset=false) = gdalwarp([ds], opts; dest=dest, gdataset=gdataset)
	gdalwarp(ds::IDataset, opts=String[]; dest="/vsimem/tmp", gdataset=false) = gdalwarp([Dataset(ds.ptr)], opts; dest=dest, gdataset=gdataset)

	function gdaltranslate(dataset::Dataset, options=String[]; dest="/vsimem/tmp", gdataset=false, save::AbstractString="")
		(save != "") && (dest = save)
		_options = GDALTranslateOptionsNew(options, C_NULL)
		usage_error = Ref{Cint}()
		result = GDALTranslate(dest, dataset.ptr, _options, usage_error)
		GDALTranslateOptionsFree(_options)
		result == C_NULL && (return nothing)
		if (dest != "/vsimem/tmp")
			GDALClose(result);		return nothing
		end
		return (gdataset) ? IDataset(result) : gd2gmt(IDataset(result))
	end
	function gdaltranslate(ds::IDataset, opts=String[]; dest="/vsimem/tmp", gdataset=false, save::AbstractString="")
		(save != "") && (dest = save)
		gdaltranslate(Dataset(ds.ptr), opts; dest=dest, gdataset=gdataset)
	end

	#=
	function gdalviewshed(dataset::Dataset, obsX, obsY, obsH=0, driver=C_NULL, pCreationOpts=String[], TargetHeight=0, VisibleVal=255, InvVal=0, OutOfRangeVal=NaN, nodata=NaN, CurvCoeff=0.85714, eMode=2, MaxDist=0, pfnProgress=C_NULL, pProgArg=0, heightMode=1, pExtraOpts=""; dest = "/vsimem/tmp")
		result = GDALViewshedGenerate(dataset, driver, dest, pCreationOpts, obsX, obsY, obsH, TargetHeight, VisibleVal, InvVal, OutOfRangeVal, nodata, CurvCoeff, eMode, MaxDist, pfnProgress, pProgArg, heightMode, pExtraOpts)
		return Dataset(result)
	end
	gdalviewshed(ds::IDataset, opts=String[]; dest="/vsimem/tmp") = gdalviewshed(Dataset(ds.ptr), opts; dest=dest)
	=#

	function gdalinfo(ds::Dataset, options::Vector{String}=String[])
		o = GDALInfoOptionsNew(options, C_NULL)
		return try
			GDALInfo(ds.ptr, o)
		finally
			GDALInfoOptionsFree(o)
		end
	end
	gdalinfo(ds::IDataset, opts::Vector{String}=String[]) = gdalinfo(Dataset(ds.ptr), opts)
	function gdalinfo(fname::AbstractString, opts=String[])
		CPLPushErrorHandler(@cfunction(CPLQuietErrorHandler, Cvoid, (UInt32, Cint, Cstring)))	# WTF is this needed?
		o = gdalinfo(unsafe_read(fname; options=opts), opts)
		CPLPopErrorHandler();
		return o
	end

	function gdaldem(dataset::Dataset, processing::String, options::Vector{String}=String[]; dest="/vsimem/tmp", gdataset=false, colorfile=C_NULL, save::AbstractString="")
		(save != "") && (dest = save)
		if processing == "color-relief"
			@assert colorfile != C_NULL
		end
		options = GDALDEMProcessingOptionsNew(options, C_NULL)
		usage_error = Ref{Cint}()
		result = GDALDEMProcessing(dest, dataset.ptr, processing, colorfile, options, usage_error)
		GDALDEMProcessingOptionsFree(options)
		if (dest != "/vsimem/tmp")
			GDALClose(result);		return nothing
		end
		return (gdataset) ? IDataset(result) : gd2gmt(IDataset(result))
	end
	gdaldem(ds::IDataset, processing::String, opts::Vector{String}=String[]; dest="/vsimem/tmp", gdataset=false, colorfile=C_NULL) =
		gdaldem(Dataset(ds.ptr), processing, opts; dest=dest, gdataset=gdataset, colorfile=colorfile)

	function gdalgrid(dataset::Dataset, options::Vector{String}=String[]; dest="/vsimem/tmp", gdataset=false, save::AbstractString="")
		(save != "") && (dest = save)
		options = GDALGridOptionsNew(options, C_NULL)
		usage_error = Ref{Cint}()
		result = GDALGrid(dest, dataset.ptr, options, usage_error)
		GDALGridOptionsFree(options)

		(dest != "/vsimem/tmp") && (GDALClose(result);	return nothing)
		return (gdataset) ? IDataset(result) : gd2gmt(IDataset(result))
	end
	gdalgrid(ds::IDataset, opts::Vector{String}=String[]; dest="/vsimem/tmp", gdataset=false) =
		gdalgrid(Dataset(ds.ptr), opts; dest=dest, gdataset=gdataset)

	gdalrasterize(dataset::GMT.GDtype, options::Vector{String}=String[]; dest = "/vsimem/tmp", gdataset=false, save::AbstractString="", layout::String="") =
		gdalrasterize(gmt2gd(dataset), options; dest=dest, gdataset=gdataset, save=save, layout=layout)
	function gdalrasterize(dataset::AbstractDataset, options::Vector{String}=String[]; dest = "/vsimem/tmp", gdataset=false, save::AbstractString="", layout::String="")
		(save != "") && (dest = save)
		options = GDALRasterizeOptionsNew(options, C_NULL)
		usage_error = Ref{Cint}()
		result = GDALRasterize(dest, C_NULL, dataset.ptr, options, usage_error)
		GDALRasterizeOptionsFree(options)
		if (dest != "/vsimem/tmp")
			GDALClose(result);		return nothing
		end
		return (gdataset) ? IDataset(result) : gd2gmt(IDataset(result), layout=layout)
	end

	function gdalbuildvrt(datasets::Vector{<:AbstractDataset}, options::Vector{String}=String[]; dest = "/vsimem/tmp", save::AbstractString="")
		(save != "") && (dest = save)
		options = GDALBuildVRTOptionsNew(options, C_NULL)
		usage_error = Ref{Cint}()
		result = GDALBuildVRT(dest, length(datasets), [ds.ptr for ds in datasets], C_NULL, options, usage_error)
		GDALBuildVRTOptionsFree(options)
		if (dest != "/vsimem/tmp")
			GDALClose(result);		return nothing
		end
    	return IDataset(result)
	end

#=
	for gdalfunc in (:boundary, :buffer, :centroid, :clone, :convexhull, :create, :createcolortable,
		:createcoordtrans, :copy, :createfeaturedefn, :createfielddefn, :creategeom, :creategeomcollection,
		:creategeomfieldcollection, :creategeomdefn, :createlayer, :createlinearring, :createlinestring,
		:createmultilinestring, :createmultipoint, :createmultipolygon, :createmultipolygon_noholes, :createpoint,
		:createpolygon, :createRAT, :createstylemanager, :createstyletable, :createstyletool, :curvegeom,
		:delaunaytriangulation, :difference, :forceto, :fromGML, :fromJSON, :fromWKB, :fromWKT, :gdalbuildvrt, :gdaldem,
		:gdalgrid, :gdalnearblack, :gdalrasterize, :gdaltranslate, :gdalvectortranslate, :gdalwarp, :getband, :getcolortable,
		:getfeature, :getgeom, :getlayer, :getmaskband, :getoverview, :getpart, :getspatialref, :importCRS, :intersection,
		:importEPSG, :importEPSGA, :importESRI, :importPROJ4, :importWKT, :importXML, :importURL, :lineargeom, :newspatialref,
		:nextfeature, :pointalongline, :pointonsurface, :polygonfromedges, :polygonize, :read, :sampleoverview, :simplify,
		:simplifypreservetopology, :symdifference, :union, :update, :readraster,)
=#
	# We don't have unsafe_ versions for most of the above make the list much shorter
	for gdalfunc in (:clone, :copy, :createfielddefn, :creategeom, :getfeature, :getlayer, :getspatialref, :read)
		eval(quote
			function $(gdalfunc)(f::Function, args...; kwargs...)
				obj = $(Symbol("unsafe_$gdalfunc"))(args...; kwargs...)
				try
					f(obj)
				finally
					destroy(obj)
				end
			end
		end)
	end

	function gdalvectortranslate(datasets::Vector{Dataset}, options::Vector{String}=String[]; dest="/vsimem/tmp", gdataset=false, save::AbstractString="")
		(save != "") && (dest = save)
		options = GDALVectorTranslateOptionsNew(options, C_NULL)
		usage_error = Ref{Cint}()
		result = GDALVectorTranslate(dest, C_NULL, length(datasets), [ds.ptr for ds in datasets], options, usage_error)
		GDALVectorTranslateOptionsFree(options)
		if (dest != "/vsimem/tmp")
			GDALClose(result);		return nothing
		end
		return (gdataset) ? IDataset(result) : gd2gmt(IDataset(result))
	end
	gdalvectortranslate(ds::Dataset, opts::Vector{String}=String[]; dest="/vsimem/tmp", gdataset=false, save="") =
		gdalvectortranslate([ds], opts; dest=dest, gdataset=gdataset, save=save)
	gdalvectortranslate(ds::IDataset, opts::Vector{String}=String[]; dest="/vsimem/tmp", gdataset=false, save="") =
		gdalvectortranslate([Dataset(ds.ptr)], opts; dest=dest, gdataset=gdataset, save=save)
	gdalvectortranslate(ds::GMT.GMTdataset, opts::Vector{String}=String[]; dest="/vsimem/tmp", gdataset=false, save="") = 				gdalvectortranslate([ds], opts; dest=dest, gdataset=gdataset, save=save)
	function gdalvectortranslate(ds::Vector{GMT.GMTdataset}, opts::Vector{String}=String[]; dest="/vsimem/tmp", gdataset=false, save="")
		o = gdalvectortranslate(GMT.gmt2gd(ds), opts; dest=dest, gdataset=gdataset, save=save)
		(!isa(o, GMT.GDtype) && dest == "/vsimem/tmp") && deletedatasource(o, "/vsimem/tmp")	# WTF do I need to do this?
		o
	end

	geomname(geom::AbstractGeometry) = OGR_G_GetGeometryName(geom.ptr)

	function fromWKT(data::Vector{String})
		geom = Ref{pVoid}()
		result = @gdal(OGR_G_CreateFromWkt::Cint, data::Ptr{Cstring}, C_NULL::pVoid, geom::Ptr{pVoid})
		@ogrerr result "Failed to create geometry from WKT"
		return IGeometry(geom[])
	end
	fromWKT(data::String, args...) = fromWKT([data], args...)

	function toWKT(spref::AbstractSpatialRef)
		wktptr = Ref{Cstring}()
		result = OSRExportToWkt(spref.ptr, wktptr)
		@ogrerr result "Failed to convert this SRS into WKT format"
		return unsafe_string(wktptr[])
	end

	function toWKT(spref::AbstractSpatialRef, simplify::Bool)
		wktptr = Ref{Cstring}()
		result = OSRExportToPrettyWkt(spref.ptr, wktptr, simplify)
		@ogrerr result "Failed to convert this SRS into pretty WKT"
		return unsafe_string(wktptr[])
	end

	function toWKT(geom::AbstractGeometry)
		wkt_ptr = Ref(Cstring(C_NULL))
		result = OGR_G_ExportToWkt(geom.ptr, wkt_ptr)
		@ogrerr result "OGRErr $result: failed to export geometry to WKT"
		wkt = unsafe_string(wkt_ptr[])
		VSIFree(pointer(wkt_ptr[]))
		return wkt
	end

	function toPROJ4(spref::AbstractSpatialRef)
		(spref.ptr == C_NULL) && return ""
		projptr = Ref{Cstring}()
		result = OSRExportToProj4(spref.ptr, projptr)
		@ogrerr result "Failed to export this SRS to PROJ.4 format"
		return unsafe_string(projptr[])
	end

	toKML(geom::AbstractGeometry, altitudemode=C_NULL) = OGR_G_ExportToKML(geom.ptr, altitudemode)

	function importWKT!(spref::AbstractSpatialRef, wktstr::AbstractString)
		result = OSRImportFromWkt(spref.ptr, [wktstr])
		@ogrerr result "Failed to initialize SRS based on WKT string"
		return spref
	end
	importWKT(wktstr::AbstractString; kwargs...) = newspatialref(wktstr; kwargs...)

	function importEPSG!(spref::AbstractSpatialRef, code::Integer)
		result = OSRImportFromEPSG(spref.ptr, code)
		@ogrerr result "Failed to initialize SRS based on EPSG"
		return spref
	end
	importEPSG(code::Integer; kwargs...) = importEPSG!(newspatialref(; kwargs...), code)

	newspatialref(wkt::AbstractString = ""; order=:trad) = maybesetaxisorder!(ISpatialRef(OSRNewSpatialReference(wkt)), order)

	function importPROJ4!(spref::AbstractSpatialRef, projstr::AbstractString)
		result = OSRImportFromProj4(spref.ptr, projstr)
		@ogrerr result "Failed to initialize SRS based on PROJ4 string"
		return spref
	end
	importPROJ4(projstr::AbstractString; kwargs...) = importPROJ4!(newspatialref(; kwargs...), projstr)

	function maybesetaxisorder!(sr::AbstractSpatialRef, order)
		if order == :trad
			OSRSetAxisMappingStrategy(sr.ptr, OAMS_TRADITIONAL_GIS_ORDER)
		elseif order != :compliant
			throw(ArgumentError("order $order is not supported. Use :trad or :compliant"))
		end
		sr
	end

	getlayer(ds::AbstractDataset, i::Integer) = IFeatureLayer(GDALDatasetGetLayer(ds.ptr, i), ownedby=ds)
	getlayer(ds::AbstractDataset, name::AbstractString) = IFeatureLayer(GDALDatasetGetLayerByName(ds.ptr, name), ownedby = ds)

	unsafe_getlayer(ds::AbstractDataset, i::Integer) = FeatureLayer(GDALDatasetGetLayer(ds.ptr, i))
	unsafe_getlayer(ds::AbstractDataset, name::AbstractString) = FeatureLayer(GDALDatasetGetLayerByName(ds.ptr, name))

	width(band::AbstractRasterBand)    = GDALGetRasterBandXSize(band.ptr)
	width(dataset::AbstractDataset)    = GDALGetRasterXSize(dataset.ptr)
	height(band::AbstractRasterBand)   = GDALGetRasterBandYSize(band.ptr)
	height(dataset::AbstractDataset)   = GDALGetRasterYSize(dataset.ptr)
	nlayer(dataset::AbstractDataset)   = GDALDatasetGetLayerCount(dataset.ptr)
	nraster(dataset::AbstractDataset)  = GDALGetRasterCount(dataset.ptr)
	filelist(dataset::AbstractDataset) = GDALGetFileList(dataset.ptr)
	nfeature(layer::AbstractFeatureLayer, force::Bool = false) = OGR_L_GetFeatureCount(layer.ptr, force)

	getname(featuredefn::AbstractFeatureDefn) = OGR_FD_GetName(featuredefn.ptr)
	getname(layer::AbstractFeatureLayer)  = OGR_L_GetName(layer.ptr)
	#getname(fielddefn::AbstractFieldDefn) = OGR_Fld_GetNameRef(fielddefn.ptr)
	function getname(fielddefn::AbstractFieldDefn)
		# Issue reported here https://github.com/JuliaLang/julia/issues/47003 but answer ... don't be rude
		(VERSION > v"1.8") && println(IOBuffer(maxsize=0), fielddefn.ptr);		# TEMP to avoid 1.9 bug
		OGR_Fld_GetNameRef(fielddefn.ptr)
	end
	getname(obj::UInt32) = GDALGetColorInterpretationName(obj)
	#getname(geomdefn::AbstractGeomFieldDefn) = OGR_Fld_GetNameRef(geomdefn.ptr)
	function getname(geomdefn::AbstractGeomFieldDefn)
		(VERSION > v"1.8") && println(IOBuffer(maxsize=0), geomdefn.ptr);		# TEMP to avoid 1.9 bug
		OGR_Fld_GetNameRef(geomdefn.ptr)
	end

	#getname(obj::UInt32) = GDALGetPaletteInterpretationName(obj)
	#getname(obj::OGRFieldType)      = OGR_GetFieldTypeName(obj)
	#getname(obj::OGRFieldSubType)   = OGR_GetFieldSubTypeName(obj)

	getgeomtype(featuredefn::AbstractFeatureDefn) = OGR_FD_GetGeomType(featuredefn.ptr)
	getgeomtype(layer::AbstractFeatureLayer) = OGR_L_GetGeomType(layer.ptr)
	getgeomtype(geom::AbstractGeometry)  = OGR_G_GetGeometryType(geom.ptr)

	#typename(dt::UInt32)::String = GDALGetDataTypeName(dt)

	gettype(name::AbstractString) = GDALGetDataTypeByName(name)
	#gettype(fielddefn::AbstractFieldDefn) = OGR_Fld_GetType(fielddefn.ptr)
	function gettype(fielddefn::AbstractFieldDefn)
		(VERSION > v"1.8") && println(IOBuffer(maxsize=0), fielddefn.ptr);		# TEMP to avoid 1.9 bug
		OGR_Fld_GetType(fielddefn.ptr)
	end
	gettype(geomdefn::AbstractGeomFieldDefn) = OGR_GFld_GetType(geomdefn.ptr)

	accessflag(band::AbstractRasterBand) = GDALGetRasterAccess(band.ptr)
	indexof(band::AbstractRasterBand)    = GDALGetBandNumber(band.ptr)
	pixeltype(band::AbstractRasterBand{T}) where T = T
	getcoorddim(geom::AbstractGeometry) = OGR_G_GetCoordinateDimension(geom.ptr)

	getcolorinterp(band::AbstractRasterBand) = GDALGetRasterColorInterpretation(band.ptr)
	getcolortable(band::AbstractRasterBand) = ColorTable(pVoid(GDALGetRasterColorTable(band.ptr)))
	function setcolortable!(band::AbstractRasterBand, colortable::ColorTable)
		result = GDALSetRasterColorTable(band.ptr, colortable.ptr)
		@cplwarn result "CPLError $(result): action is unsupported by the driver"
		return band
	end
	createcolortable(palette::Integer) = ColorTable(GDALCreateColorTable(UInt32(palette)))	# WAS UNSAFE_
	function createcolorramp!(ct::ColorTable, startind::Integer, startcolor::GDALColorEntry, endind::Integer, endcolor::GDALColorEntry)
    	return GDALCreateColorRamp(ct.ptr, startind, Ref{GDALColorEntry}(startcolor), endind, Ref{GDALColorEntry}(endcolor))
	end
	function setcolorentry!(ct::ColorTable, i::Integer, entry::GDALColorEntry)
		GDALSetColorEntry(ct.ptr, i, Ref{GDALColorEntry}(entry))
		return ct
	end
	function setnodatavalue!(band::AbstractRasterBand, value::Real)
		result = GDALSetRasterNoDataValue(band.ptr, value)
		@cplerr result "Could not set nodatavalue"
		return band
	end
	function getnodatavalue(band::AbstractRasterBand)
		hasnodatavalue = Ref(Cint(0))
		nodatavalue = GDALGetRasterNoDataValue(band.ptr, hasnodatavalue)
		return (Bool(hasnodatavalue[])) ? nodatavalue : nothing
	end

	paletteinterp(ct::ColorTable) = GDALGetPaletteInterpretation(ct.ptr)
	ncolorentry(ct::ColorTable) = GDALGetColorEntryCount(ct.ptr)
	getcolorentry(ct::ColorTable, i::Integer) = unsafe_load(GDALGetColorEntry(ct.ptr, i))
	metadata(obj; domain::AbstractString="") = GDALGetMetadata(obj.ptr, domain)
	metadatadomainlist(obj)::Vector{String} = GDALGetMetadataDomainList(obj.ptr)
	function metadataitem(obj, name::AbstractString; domain::AbstractString="",)::String
		item = GDALGetMetadataItem(obj.ptr, name, domain)
		return item === nothing ? "" : item
	end

	function setconfigoption(option::AbstractString, value)::Nothing
		CPLSetConfigOption(option, value)
		return nothing
	end
	function clearconfigoption(option::AbstractString)::Nothing
		setconfigoption(option, C_NULL)
		return nothing
	end
	function getconfigoption(option::AbstractString, default=C_NULL)::String
		result = @gdal(CPLGetConfigOption::Cstring, option::Cstring, default::Cstring)
		return (result == C_NULL) ? "" : unsafe_string(result)
	end

	asint(feature::Feature, i::Integer) = OGR_F_GetFieldAsInteger(feature.ptr, i)
	asint64(feature::Feature, i::Integer) = OGR_F_GetFieldAsInteger64(feature.ptr, i)
	asdouble(feature::Feature, i::Integer) = OGR_F_GetFieldAsDouble(feature.ptr, i)
	asstring(feature::Feature, i::Integer) = OGR_F_GetFieldAsString(feature.ptr, i)
	asstringlist(feature::Feature, i::Integer) = OGR_F_GetFieldAsStringList(feature.ptr, i)
	function asintlist(feature::Feature, i::Integer)
		n = Ref{Cint}()
		ptr = OGR_F_GetFieldAsIntegerList(feature.ptr, i, n)
		return (n.x == 0) ? Int32[] : unsafe_wrap(Array{Int32}, ptr, n.x)
	end
	function asint64list(feature::Feature, i::Integer)
		n = Ref{Cint}()
		ptr = OGR_F_GetFieldAsInteger64List(feature.ptr, i, n)
		return (n.x == 0) ? Int64[] : unsafe_wrap(Array{Int64}, ptr, n.x)
	end
	function asdoublelist(feature::Feature, i::Integer)
		n = Ref{Cint}()
		ptr = OGR_F_GetFieldAsDoubleList(feature.ptr, i, n)
		return (n.x == 0) ? Float64[] : unsafe_wrap(Array{Float64}, ptr, n.x)
	end
	function asbinary(feature::Feature, i::Integer)
		n = Ref{Cint}()
		ptr = OGR_F_GetFieldAsBinary(feature.ptr, i, n)
		return (n.x == 0) ? UInt8[] : unsafe_wrap(Array{UInt8}, ptr, n.x)
	end
	function asdatetime(feature::Feature, i::Integer)
		pyr = Ref{Cint}(); pmth = Ref{Cint}(); pday = Ref{Cint}()
		phr = Ref{Cint}(); pmin = Ref{Cint}(); psec = Ref{Cint}(); ptz=Ref{Cint}()
		result = Bool(OGR_F_GetFieldAsDateTime(feature.ptr, i, pyr, pmth, pday, phr, pmin, psec, ptz))
		(result == false) && error("Failed to fetch datetime at index $i")
		return DateTime(pyr[], pmth[], pday[], phr[], pmin[], psec[])
	end

	layerdefn(layer::AbstractFeatureLayer) = IFeatureDefnView(OGR_L_GetLayerDefn(layer.ptr))
	ngeom(feature::Feature) = OGR_F_GetGeomFieldCount(feature.ptr)
	ngeom(featuredefn::AbstractFeatureDefn) = OGR_FD_GetGeomFieldCount(featuredefn.ptr)
	ngeom(layer::AbstractFeatureLayer) = ngeom(layerdefn(layer))
	function ngeom(geom::AbstractGeometry)
		n = OGR_G_GetPointCount(geom.ptr)
		n == 0 ? OGR_G_GetGeometryCount(geom.ptr) : n
	end
	function ngeom(dataset::Gdal.AbstractDataset)
		# Count the total number of geometries in dataset
		n_tot = 0
		for k = 1:nlayer(dataset)
			layer = getlayer(dataset, k-1)
			resetreading!(layer)
			while ((feature = nextfeature(layer)) !== nothing)
				# Count all geoms, including those in the Multis
				for n = 1:ngeom(feature)
					n_multies = OGR_G_GetGeometryCount(getgeom(feature,n-1).ptr)
					this_n = (n_multies == 0) ? 1 : n_multies
					n_tot += this_n
				end
			end
		end
		return n_tot
	end

	getgeomdefn(feature::Feature, i::Integer) = IGeomFieldDefnView(OGR_F_GetGeomFieldDefnRef(feature.ptr, i))
	getgeomdefn(fdfn::FeatureDefn, i::Integer = 0) = GeomFieldDefn(OGR_FD_GetGeomFieldDefn(fdfn.ptr, i))
	getgeomdefn(fdfn::IFeatureDefnView, i::Integer = 0) = IGeomFieldDefnView(OGR_FD_GetGeomFieldDefn(fdfn.ptr, i))

	function getgeom(feature::Feature)
		result = OGR_F_GetGeometryRef(feature.ptr)
		return (result == C_NULL) ? IGeometry() : IGeometry(OGR_G_Clone(result))
	end

	function getgeom(feature::Feature, i::Integer)
		result = OGR_F_GetGeomFieldRef(feature.ptr, i)
		return (result == C_NULL) ? IGeometry() : IGeometry(OGR_G_Clone(result))
	end

	function getgeom(geom::AbstractGeometry, i::Integer)
		# NOTE(yeesian): GDAL.ogr_g_getgeometryref(geom, i) returns an handle to a
		# geometry within the container. The returned geometry remains owned by the
		# container, and should not be modified. The handle is only valid until the
		# next change to the geometry container. Use OGR_G_Clone() to make a copy.
		(geom.ptr == C_NULL) && return Geometry()
		result = OGR_G_GetGeometryRef(geom.ptr, i)
		if (result == C_NULL)  return IGeometry()
		else                   return IGeometry(OGR_G_Clone(result))
		end
	end

	function setgeom!(feature::Feature, geom::AbstractGeometry)
		result = OGR_F_SetGeometry(feature.ptr, geom.ptr)
		@ogrerr result "OGRErr $result: Failed to set feature geometry."
	end
	function setgeom!(feature::Feature, i::Integer, geom::AbstractGeometry)
		result = OGR_F_SetGeomField(feature.ptr, i, geom.ptr)
		@ogrerr result "OGRErr $result: Failed to set feature geometry"
		return feature
	end

	function addpoint!(geom::AbstractGeometry, x::Real, y::Real, z::Real)
		OGR_G_AddPoint(geom.ptr, x, y, z);	return geom
	end
	function addpoint!(geom::AbstractGeometry, x::Real, y::Real)
		OGR_G_AddPoint_2D(geom.ptr, x, y);	return geom
	end

	function addgeom!(geomcontainer::AbstractGeometry, subgeom::AbstractGeometry)
		result = OGR_G_AddGeometry(geomcontainer.ptr, subgeom.ptr)
		@ogrerr result "Failed to add geometry. The geometry type could be illegal"
		return geomcontainer
	end

	"""
	wrapgeom(geom::AbstractGeometry, proj="")

		Wrap an geometry type into a GDAL dataset. Optionaly provide the SRS (proj4) via the PROJ option.
		Handy function for saving a geometry on disk or visualize it with plot()
	"""
	function wrapgeom(geom::AbstractGeometry, proj::String="")
		(proj != "" && !startswith(proj, "+proj=")) && error("Projection info must be in proj4 format.")
		ds = create(getdriver("MEMORY"))
		sr = (proj == "") ? ISpatialRef(C_NULL) : importPROJ4(proj)
		layer = createlayer(name="layer1", dataset=ds, geom=getgeomtype(geom), spatialref=sr)
		feature = unsafe_createfeature(layer)
		setgeom!(feature, geom)
		setfeature!(layer, feature)
		destroy(feature)
		return ds
	end

	nfield(feature::Feature) = OGR_F_GetFieldCount(feature.ptr)
	nfield(featuredefn::AbstractFeatureDefn) = OGR_FD_GetFieldCount(featuredefn.ptr)
	nfield(layer::AbstractFeatureLayer) = nfield(layerdefn(layer))

	getfielddefn(feature::Feature, i::Integer) = IFieldDefnView(OGR_F_GetFieldDefnRef(feature.ptr, i))
	getfielddefn(featuredefn::FeatureDefn, i::Integer) = FieldDefn(OGR_FD_GetFieldDefn(featuredefn.ptr, i))
	getfielddefn(featuredefn::IFeatureDefnView, i::Integer) = IFieldDefnView(OGR_FD_GetFieldDefn(featuredefn.ptr, i))

	function getfield(feature::Feature, i::Integer)
		if isfieldset(feature, i)
			_fieldtype = gettype(getfielddefn(feature, i))
			_fetchfield = get(_FETCHFIELD, _fieldtype, getdefault)
			return _fetchfield(feature, i)
		else
			return getdefault(feature, i)
		end
	end
	getfield(feature::Feature, name::Union{AbstractString, Symbol}) = getfield(feature, findfieldindex(feature, name))
	getfield(feature::AbstractFeature, i::Nothing)::Missing = missing

	function setfield!(feature::Feature, i::Integer, value::Cint)
		OGR_F_SetFieldInteger(feature.ptr, i, value);	return feature
	end
	
	function setfield!(feature::Feature, i::Integer, value::Int64)
		OGR_F_SetFieldInteger64(feature.ptr, i, value);	return feature
	end
	
	function setfield!(feature::Feature, i::Integer, value::Cdouble)
		OGR_F_SetFieldDouble(feature.ptr, i, value);	return feature
	end
	
	function setfield!(feature::Feature, i::Integer, value::AbstractString)
		OGR_F_SetFieldString(feature.ptr, i, value);	return feature
	end
	
	function setfield!(feature::Feature, i::Integer, value::Vector{Cint})
		OGR_F_SetFieldIntegerList(feature.ptr, i, length(value), value);	return feature
	end
	
	function setfield!(feature::Feature, i::Integer, value::Vector{Clonglong})
		OGR_F_SetFieldInteger64List(feature.ptr, i, length(value), value);	return feature
	end
	
	function setfield!(feature::Feature, i::Integer, value::Vector{Cdouble})
		OGR_F_SetFieldDoubleList(feature.ptr, i, length(value), value);		return feature
	end
	
	function setfield!(feature::Feature, i::Integer, value::Vector{T}) where T <: AbstractString
		OGR_F_SetFieldStringList(feature.ptr, i, value);	return feature
	end

	function setfield!(feature::Feature, i::Integer, value::Vector{Cuchar})
		OGR_F_SetFieldBinary(feature.ptr, i, sizeof(value), value);	return feature
	end

	#=
	function setfield!(feature::Feature, i::Integer, dt::DateTime, tzflag::Int = 0)
		OGR_F_SetFieldDateTime(feature.ptr, i, Dates.year(dt), Dates.month(dt), Dates.day(dt), Dates.hour(dt), Dates.minute(dt), Dates.second(dt), tzflag)
		return feature
	end
	=#

	isfieldset(feature::Feature, i::Integer) = Bool(OGR_F_IsFieldSet(feature.ptr, i))
	getdefault(feature::Feature, i::Integer) = getdefault(getfielddefn(feature, i))

	findfieldindex(feature::Feature, name::Union{AbstractString, Symbol}) = OGR_F_GetFieldIndex(feature.ptr, name)
	findfieldindex(fdefn::AbstractFeatureDefn, name::Union{AbstractString, Symbol}) = OGR_FD_GetFieldIndex(fdefn.ptr, name)
	function findfieldindex(layer::AbstractFeatureLayer, field::Union{AbstractString, Symbol}, exactmatch::Bool)
		return OGR_L_FindFieldIndex(layer.ptr, field, exactmatch)
	end

	const _FETCHFIELD = Dict{UInt32, Function}(
		OFTInteger       => asint,           #0-
		OFTIntegerList   => asintlist,       #1-
		OFTReal          => asdouble,        #2-
		OFTRealList      => asdoublelist,    #3-
		OFTString        => asstring,        #4-
		OFTStringList    => asstringlist,    #5-
		OFTBinary        => asbinary,        #8-
		OFTDateTime      => asdatetime,      #11
		OFTInteger64     => asint64,         #12-
		OFTInteger64List => asint64list      #13-
	)
	const FETCHFIELD_ = Dict{UInt32, String}(
		OFTInteger       => "Integer",
		OFTIntegerList   => "IntegerList",
		OFTReal          => "Real",
		OFTRealList      => "RealList",
		OFTString        => "String",
		OFTStringList    => "StringList",
		OFTBinary        => "Binary",
		OFTDateTime      => "DateTime",
		OFTInteger64     => "nteger64",
		OFTInteger64List => "Integer64List"
	)

	function getdefault(fielddefn::AbstractFieldDefn)
		result = @gdal(OGR_Fld_GetDefault::Cstring, fielddefn.ptr::pVoid)
		return (result == C_NULL) ? "" : unsafe_string(result)
	end

	function resetreading!(layer::AbstractFeatureLayer)
		OGR_L_ResetReading(layer.ptr)
		return layer
	end	

	creategeom(geomtype::UInt32) = IGeometry(OGR_G_CreateGeometry(geomtype))
	unsafe_creategeom(geomtype::UInt32) = Geometry(OGR_G_CreateGeometry(geomtype))

	function forceto(geom::AbstractGeometry, targettype::UInt32, options=Ptr{Cstring}(C_NULL))
		IGeometry(OGR_G_ForceTo(unsafe_clone(geom).ptr, targettype, options))
	end

	clone(spref::AbstractSpatialRef) = (spref.ptr == C_NULL) ? IGeometry() : IGeometry(OGR_G_Clone(spref.ptr))
	unsafe_clone(spref::AbstractSpatialRef) = (spref.ptr == C_NULL) ? Geometry() : Geometry(OGR_G_Clone(spref.ptr))

	clone(geom::AbstractGeometry) = (geom.ptr == C_NULL) ? IGeometry() : IGeometry(OGR_G_Clone(geom.ptr))
	unsafe_clone(geom::AbstractGeometry) = (geom.ptr == C_NULL) ? Geometry() : Geometry(OGR_G_Clone(geom.ptr))

	unsafe_clone(feature::Feature) = Feature(OGR_F_Clone(feature.ptr))

	function deletedatasource(ds::AbstractDataset, name::AbstractString)
		(OGR_Dr_DeleteDataSource(getdriver(ds).ptr, name) != OGRERR_NONE) && @warn("Failed to remove $name")
		return nothing
	end

	for (geom, wkbgeom) in ((:geomcollection,       wkbGeometryCollection),
							(:linestring,           wkbLineString),
							(:linearring,           wkbLinearRing),
							(:multilinestring,      wkbMultiLineString),
							(:multipoint,           wkbMultiPoint),
							(:multipolygon,         wkbMultiPolygon),
							(:multipolygon_noholes, wkbMultiPolygon),
							(:point,                wkbPoint),
							(:polygon,              wkbPolygon))
		eval(quote
			$(Symbol("create$geom"))() = creategeom($wkbgeom)
			$(Symbol("unsafe_create$geom"))() = unsafe_creategeom($wkbgeom)
		end)
	end

	for f in (:create, :unsafe_create)
		for (args, typedargs) in ( ((:x,:y), (:(x::Real),:(y::Real))), ((:x,:y,:z), (:(x::Real),:(y::Real),:(z::Real))))
			eval(quote
				function $(Symbol("$(f)point"))($(typedargs...))
					geom = $(Symbol("$(f)point"))()
					addpoint!(geom, $(args...))
					return geom
				end
			end)
		end

		for (args, typedargs) in ( ((:xs,:ys), (:(xs::Vector{Cdouble}), :(ys::Vector{Cdouble}))),
				((:xs,:ys,:zs), (:(xs::Vector{Cdouble}), :(ys::Vector{Cdouble}), :(zs::Vector{Cdouble}))))
			for geom in (:linestring, :linearring)
				eval(quote
					function $(Symbol("$f$geom"))($(typedargs...))
						geom = $(Symbol("$f$geom"))()
						for pt in zip($(args...))
							addpoint!(geom, pt...)
						end
						return geom
					end
				end)
			end

			for (geom,component) in ((:polygon, :linearring),)
				eval(quote
					function $(Symbol("$f$geom"))($(typedargs...))
						geom = $(Symbol("$f$geom"))()
						subgeom = $(Symbol("unsafe_create$component"))($(args...))
						result = OGR_G_AddGeometryDirectly(geom.ptr, subgeom.ptr)
						@ogrerr result "Failed to add $component."
						return geom
					end
				end)
			end

			for (geom,component) in ((:multipoint, :point),)
				eval(quote
					function $(Symbol("$f$geom"))($(typedargs...))
						geom = $(Symbol("$f$geom"))()
						for pt in zip($(args...))
							subgeom = $(Symbol("unsafe_create$component"))(pt)
							result = OGR_G_AddGeometryDirectly(geom.ptr, subgeom.ptr)
							@ogrerr result "Failed to add point."
						end
						return geom
					end
				end)
			end
		end

		for typeargs in (Vector{<:Real}, Tuple{<:Real,<:Real}, Tuple{<:Real,<:Real,<:Real})
			eval(quote
				function $(Symbol("$(f)point"))(coords::$typeargs)
					geom = $(Symbol("$(f)point"))()
					addpoint!(geom, coords...)
					return geom
				end
			end)
		end

		for typeargs in (Vector{Tuple{Cdouble,Cdouble}}, Vector{Tuple{Cdouble,Cdouble,Cdouble}}, Vector{Vector{Cdouble}})
			for geom in (:linestring, :linearring)
				eval(quote
					function $(Symbol("$f$geom"))(coords::$typeargs)
						geom = $(Symbol("$f$geom"))()
						for coord in coords
							addpoint!(geom, coord...)
						end
						return geom
					end
				end)
			end

			for (geom,component) in ((:polygon, :linearring),)
				eval(quote
					function $(Symbol("$f$geom"))(coords::$typeargs)
						geom = $(Symbol("$f$geom"))()
						subgeom = $(Symbol("unsafe_create$component"))(coords)
						result = OGR_G_AddGeometryDirectly(geom.ptr, subgeom.ptr)
						@ogrerr result "Failed to add $component."
						return geom
					end
				end)
			end
		end

		for (variants,typeargs) in (
				(((:multipoint, :point),),
				 (Vector{Tuple{Cdouble,Cdouble}}, Vector{Tuple{Cdouble,Cdouble,Cdouble}}, Vector{Vector{Cdouble}})),
	
				(((:polygon, :linearring), (:multilinestring, :linestring), (:multipolygon_noholes, :polygon)),
				 (Vector{Vector{Tuple{Cdouble,Cdouble}}}, Vector{Vector{Tuple{Cdouble,Cdouble,Cdouble}}},
				  Vector{Vector{Vector{Cdouble}}})),
	
				(((:multipolygon, :polygon),), (Vector{Vector{Vector{Tuple{Cdouble,Cdouble}}}},
				  Vector{Vector{Vector{Tuple{Cdouble,Cdouble,Cdouble}}}}, Vector{Vector{Vector{Vector{Cdouble}}}}) )
			)
			for typearg in typeargs, (geom, component) in variants
				eval(quote
					function $(Symbol("$f$geom"))(coords::$typearg)
						geom = $(Symbol("$f$geom"))()
						for coord in coords
							subgeom = $(Symbol("unsafe_create$component"))(coord)
							result = OGR_G_AddGeometryDirectly(geom.ptr, subgeom.ptr)
							@ogrerr result "Failed to add $component."
						end
						return geom
					end
				end)
			end
		end
	end

	Base.size(band::AbstractRasterBand) = (width(band), height(band))
	Base.size(dataset::RasterDataset) = dataset.size

	function Base.show(io::IO, drv::Driver)
		drv.ptr == C_NULL && (return print(io, "NULL Driver"))
		print(io, "Driver: $(shortname(drv))/$(longname(drv))")
	end

	function Base.show(io::IO, dataset::AbstractDataset)
		dataset.ptr == C_NULL && (return print(io, "NULL Dataset"))
		println(io, "GDAL Dataset ($(getdriver(dataset)))")
		println(io, "File(s): ")
		for (i,filename) in enumerate(filelist(dataset))
			println(io, "  $filename")
			if i > 5
				println(io, "  ...")
				break
			end
		end
		nrasters = nraster(dataset)
		if nrasters > 0
			print(io, "\nDataset (width x height): ")
			println(io, "$(width(dataset)) x $(height(dataset)) (pixels)")
			println(io, "Number of raster bands: $nrasters")
			for i = 1:min(nrasters, 3)
				print(io, "  ")
				summarize(io, getband(dataset, i))
			end
			nrasters > 3 && println(io, "  ...")
		end

		nlayers = nlayer(dataset)
		if nlayers > 0
			println(io, "\nNumber of feature layers: $nlayers")
			ndisplay = min(nlayers, 5) # display up to 5 layers
			for i = 1:ndisplay
				layer = getlayer(dataset, i-1)
				layergeomtype = get(_FETCHGEOM, getgeomtype(layer), getgeomtype(layer))
				println(io, "  Layer $(i-1): $(getname(layer)) ($layergeomtype)")
			end
			if nlayers > 5
				print(io, "  Remaining layers: ")
				for i = 6:nlayers
					print(io, "$(getname(getlayer(dataset, i-1))) ")
					if i % 5 == 0 println() end		# display up to 5 layer names per line
				end
			end
		end
	end

	Base.show(io::IO, raster::RasterDataset) = show(io, raster.ds)
	Base.show(io::IO, ::MIME"text/plain", raster::RasterDataset) = show(io, raster.ds)

	function summarize(io::IO, rasterband::AbstractRasterBand)
		(rasterband.ptr == C_NULL) && return print(io, "NULL RasterBand")
		access = accessflag(rasterband)
		color = getname(getcolorinterp(rasterband))
		xsize = width(rasterband)
		ysize = height(rasterband)
		i = indexof(rasterband)
		pxtype = pixeltype(rasterband)
		println(io, "[$access] Band $i ($color): $xsize x $ysize ($pxtype)")
	end

	# assumes that the layer is reset, and will reset it after display
	function Base.show(io::IO, layer::AbstractFeatureLayer)
		layer.ptr == C_NULL && (return println(io, "NULL Layer"))
		layergeomtype = getgeomtype(layer)
		println(io, "Layer: $(getname(layer)) ($layergeomtype)")
		featuredefn = layerdefn(layer)

		# Print Geometries
		n = ngeom(featuredefn)
		ngeomdisplay = min(n, 3)
		for i in 1:ngeomdisplay
			gfd = getgeomdefn(featuredefn, i-1)
			display = "  Geometry $(i-1) ($(getname(gfd))): [$(gettype(gfd))]"
			if length(display) > 75
				println(io, "$display[1:70]...")
				continue
			end
			if ngeomdisplay == 1 # only support printing of a single geom column
				for f in layer
					geomwkt = toWKT(getgeom(f))
					length(geomwkt) > 25 && (geomwkt = "$(geomwkt[1:20])...)")
					newdisplay = "$display, $geomwkt"
					if length(newdisplay) > 75
						display = "$display, ..."
						break
					else
						display = newdisplay
					end
				end
			end
			println(io, display)
			resetreading!(layer)
		end
		n > 3 && println(io, "  ...\n  Number of Geometries: $n")

		# Print Features
		n = nfield(featuredefn)
		nfielddisplay = min(n, 5)
		for i in 1:nfielddisplay
			fd = getfielddefn(featuredefn, i-1)
			display = "     Field $(i-1) ($(getname(fd))): [$(get(FETCHFIELD_, gettype(fd), "9999"))]"
			if length(display) > 75
				println(io, "$display[1:70]...")
				continue
			end
			for f in layer
				field = string(getfield(f, i-1))
				length(field) > 25 && (field = "$(field[1:20])...")
				newdisplay = "$display, $field"
				if length(newdisplay) > 75
					display = "$display, ..."
					break
				else
					display = newdisplay
				end
			end
			println(io, display)
			resetreading!(layer)
		end
		n > 5 && print(io, "...\n Number of Fields: $n")
	end

	function Base.show(io::IO, featuredefn::AbstractFeatureDefn)
		featuredefn.ptr == C_NULL && (return print(io, "NULL FeatureDefn"))
		n = ngeom(featuredefn)
		ngeomdisplay = min(n, 3)
		for i in 1:ngeomdisplay
			gfd = getgeomdefn(featuredefn, i-1)
			println(io, "  Geometry (index $(i-1)): $gfd")
		end
		n > 3 && println(io, "  ...\n  Number of Geometries: $n")

		n = nfield(featuredefn)
		nfielddisplay = min(n, 5)
		for i in 1:nfielddisplay
			fd = getfielddefn(featuredefn, i-1)
			println(io, "     Field (index $(i-1)): $fd")
		end
		n > 5 && print(io, "...\n Number of Fields: $n")
	end

	function Base.show(io::IO, fd::AbstractFieldDefn)
		fd.ptr == C_NULL && (return print(io, "NULL FieldDefn"))
		print(io, "$(getname(fd)) ($(gettype(fd)))")
	end

	function Base.show(io::IO, gfd::AbstractGeomFieldDefn)
		gfd.ptr == C_NULL && (return print(io, "NULL GeomFieldDefn"))
		print(io, "$(getname(gfd)) ($(gettype(gfd)))")
	end

	function Base.show(io::IO, feature::Feature)
		feature.ptr == C_NULL && (return println(io, "NULL Feature"))
		println(io, "Feature")
		n = ngeom(feature)
		for i in 1:min(n, 3)
			println(io, "  (index $(i-1)) geom => $(geomname(getgeom(feature, i-1)))")
		end
		n > 3 && println(io, "...\n Number of geometries: $n")
		n = nfield(feature)
		for i in 1:min(n, 10)
			print(io, "  (index $(i-1)) $(getname(getfielddefn(feature, i-1))) => ")
			println(io, "$(getfield(feature, i-1))")
		end
		n > 10 && print(io, "...\n Number of Fields: $n")
	end

	function Base.show(io::IO, spref::AbstractSpatialRef)
		spref.ptr == C_NULL && (return print(io, "NULL Spatial Reference System"))
		projstr = toPROJ4(spref)
		(length(projstr) <= 45) && (print(io, "Spatial Reference System: $projstr");  return)
		print(io, "Spatial Reference System: $(projstr[1:35]) ... $(projstr[end-4:end])")
	end

	function Base.show(io::IO, geom::AbstractGeometry)
		geom.ptr == C_NULL && (return print(io, "NULL Geometry"))
		compact = get(io, :compact, false)

		if !compact
			print(io, "Geometry: ")
			geomwkt = toWKT(geom)
			if (length(geomwkt) > 60)  print(io, "$(geomwkt[1:50]) ... $(geomwkt[end-4:end])")
			else                       print(io, "$geomwkt")
			end
		else
			print(io, "Geometry: $(getgeomtype(geom))")
		end
	end

	#Base.eltype(layer::AbstractFeatureLayer) = Feature
	function Base.iterate(layer::AbstractFeatureLayer, state::Int=0)
		layer.ptr == C_NULL && return nothing
		state == 0 && resetreading!(layer)
		ptr = OGR_L_GetNextFeature(layer.ptr)
		if ptr == C_NULL
			resetreading!(layer)
			return nothing
		else
			return (Feature(ptr), state+1)
		end
	end

	# This function is quite similar to iterate above but for some f reason I can't call iterate (via enumerate)
	# from gdal_utils (the annoying permanent "no method matching"), so I did this trick
	function nextfeature(layer::AbstractFeatureLayer)
		layer.ptr == C_NULL && return nothing
		ptr = OGR_L_GetNextFeature(layer.ptr)
		if ptr == C_NULL
			resetreading!(layer)
			return nothing
		else
			return Feature(ptr)
		end
	end

	function resetdrivers()			# Because some GMT functions call GDALDestroyDriverManager() 
		#DRIVER_MANAGER[] = DriverManager()
		DriverManager()
		return nothing
	end

	include("gdal_extensions.jl")
	include("gdal_tools.jl")
	include("tables_gdal.jl")

	# ------------ Aliases ------------
	const ogr2ogr  = gdalvectortranslate
	const delaunay = delaunaytriangulation
	# ---------------------------------

	export
		getband, getdriver, getlayer, getproj, getgeom, getgeotransform, toPROJ4, toWKT, importPROJ4,
		importWKT, importEPSG, gdalinfo, gdalwarp, gdaldem, gdaltranslate, gdalgrid, gdalvectortranslate, ogr2ogr,
		gdalrasterize, gdalbuildvrt, readraster, setgeotransform!, setproj!, destroy, arcellipse, arccircle,
		delaunay, dither, buffer, centroid, intersection, intersects, polyunion, fromWKT,
		concavehull, convexhull, difference, symdifference, distance, geomarea, pointalongline, polygonize, simplify,
		boundary, crosses, disjoint, equals, envelope, envelope3d, geomlength, overlaps, touches, within,
		wkbUnknown, wkbPoint, wkbPointZ, wkbLineString, wkbPolygon, wkbMultiPoint, wkbMultiPointZ, wkbMultiLineString,
		wkbMultiPolygon, wkbGeometryCollection, wkbPoint25D, wkbLineString25D, wkbPolygon25D, wkbMultiPoint25D,
		wkbMultiLineString25D, wkbMultiPolygon25D, wkbGeometryCollection25D


	const DRIVER_MANAGER = Ref{DriverManager}()
	const GDALVERSION = Ref{VersionNumber}()

	function __init__()

		versionstring = GDALVersionInfo("RELEASE_NAME")
		GDALVERSION[] = VersionNumber(versionstring)

		DRIVER_MANAGER[] = DriverManager()
		CPLSetConfigOption("GDAL_HTTP_UNSAFESSL", "YES")
	end

"""
Small subset of the GDAL and ArcGDAL packages but with no extra dependencies.
For the time being this sub-module is not intended to much direct use except some
documented functions. Interested people should consult the GDAL & ArchGDAL docs.
"""
Gdal

end			# End module