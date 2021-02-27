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

using GMT

#const cacert = joinpath(@__DIR__, "cacert.pem")

@static Sys.iswindows() ?
	(Sys.WORD_SIZE == 64 ? (const libgdal = "gdal_w64") : (const libgdal = "gdal_w32")) : (
		Sys.isapple() ? (const libgdal = Symbol(split(readlines(pipeline(`otool -L $(GMT.thelib)`, `grep libgdal`))[1])[1])) : (
			Sys.isunix() ? (const libgdal = Symbol(split(readlines(pipeline(`ldd $(GMT.thelib)`, `grep libgdal`))[1])[3])) :
			error("Don't know how to install this package in this OS.")
		)
	)

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

const GDAL_OF_READONLY = 0x00				# Open in read-only mode
const GDAL_OF_VERBOSE_ERROR = 0x40			# Emit error message in case of failed open

const OAMS_TRADITIONAL_GIS_ORDER = Int32(0)

struct GDALRasterIOExtraArg
	nVersion::Cint
	eResampleAlg::UInt32
	pfnProgress::Ptr{Cvoid}
	pProgressData::Ptr{Cvoid}
	bFloatingPointWindowValidity::Cint
	dfXOff::Cdouble
	dfYOff::Cdouble
	dfXSize::Cdouble
	dfYSize::Cdouble
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

GDALAllRegister() = aftercare(ccall((:GDALAllRegister, libgdal), Cvoid, ()))
GDALDestroyDriverManager() = aftercare(ccall((:GDALDestroyDriverManager, libgdal), Cvoid, ()))

CPLErrorReset() = ccall((:CPLErrorReset, libgdal), Cvoid, ())
CPLGetLastErrorType() = ccall((:CPLGetLastErrorType, libgdal), Cint, ())
CPLGetLastErrorNo()   = ccall((:CPLGetLastErrorNo, libgdal), Cint, ())
CPLGetLastErrorMsg()  = unsafe_string(ccall((:CPLGetLastErrorMsg, libgdal), Cstring, ()))

VSIFree(arg1) = aftercare(ccall((:VSIFree, libgdal), Cvoid, (Ptr{Cvoid},), arg1))

function Base.showerror(io::IO, err::GDALError)
	err = string("GDALError (", err.class, ", code ", err.code, "):\n\t", err.msg)
	println(io, err)
end

function aftercare(x)
	maybe_throw()
	x
end

function aftercare(ptr::Cstring, free::Bool)	# For string pointers, load them to String, and free them if we should.
	maybe_throw()
	(ptr == C_NULL) && return nothing
	s = unsafe_string(ptr)
	free && VSIFree(convert(Ptr{Cvoid}, ptr))
	return s
end

function aftercare(ptr::Ptr{Cstring})
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
	# TODO it seems that, like aftercare(::Cstring), we need to
	# free the memory ourselves with CSLDestroy (not currently wrapped)
	# not sure if that is true for some or all functions
	strings
end

function maybe_throw()		# Check the last error type and throw a GDALError if it is a failure
	(CPLGetLastErrorType() === CE_Failure) && throw(GDALError())
	nothing
end

GDALDestroyDriver(arg1) = aftercare(ccall((:GDALDestroyDriver, libgdal), Cvoid, (Ptr{Cvoid},), arg1))

function GDALCreate(hDriver, arg1, arg2, arg3, arg4, arg5, arg6)
	aftercare(ccall((:GDALCreate, libgdal), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring, Cint, Cint, Cint, UInt32, Ptr{Cstring}), hDriver, arg1, arg2, arg3, arg4, arg5, arg6))
end

GDALSetProjection(a1, a2) = aftercare(ccall((:GDALSetProjection, libgdal), UInt32, (Ptr{Cvoid}, Cstring), a1, a2))

function GDALGetRasterBand(arg1, arg2)
	aftercare(ccall((:GDALGetRasterBand, libgdal), Ptr{Cvoid}, (Ptr{Cvoid}, Cint), arg1, arg2))
end

GDALGetRasterDataType(arg1) = aftercare(ccall((:GDALGetRasterDataType, libgdal), UInt32, (Ptr{Cvoid},), arg1))
GDALGetProjectionRef(arg1) = aftercare(ccall((:GDALGetProjectionRef, libgdal), Cstring, (Ptr{Cvoid},), arg1), false)
GDALGetDatasetDriver(arg1) = aftercare(ccall((:GDALGetDatasetDriver, libgdal), Ptr{Cvoid}, (Ptr{Cvoid},), arg1))
GDALGetDriver(arg1) = aftercare(ccall((:GDALGetDriver, libgdal), Ptr{Cvoid}, (Cint,), arg1))
GDALGetDriverByName(arg1) = aftercare(ccall((:GDALGetDriverByName, libgdal), Ptr{Cvoid}, (Cstring,), arg1))
GDALGetDriverShortName(arg1) = aftercare(ccall((:GDALGetDriverShortName, libgdal), Cstring, (Ptr{Cvoid},), arg1), false)
GDALGetDriverLongName(arg1) = aftercare(ccall((:GDALGetDriverLongName, libgdal), Cstring, (Ptr{Cvoid},), arg1), false)
GDALGetDriverCreationOptionList(arg1) = aftercare(ccall((:GDALGetDriverCreationOptionList, libgdal), Cstring, (Ptr{Cvoid},), arg1), false)
function GDALDatasetGetLayer(arg1, arg2)
	aftercare(ccall((:GDALDatasetGetLayer, libgdal), Ptr{Cvoid}, (Ptr{Cvoid}, Cint), arg1, arg2))
end
function GDALDatasetGetLayerByName(arg1, arg2)
	aftercare(ccall((:GDALDatasetGetLayerByName, libgdal), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring), arg1, arg2))
end
GDALGetRasterBandXSize(arg1) = aftercare(ccall((:GDALGetRasterBandXSize, libgdal), Cint, (Ptr{Cvoid},), arg1))
GDALGetRasterBandYSize(arg1) = aftercare(ccall((:GDALGetRasterBandYSize, libgdal), Cint, (Ptr{Cvoid},), arg1))
GDALGetRasterXSize(arg1)     = aftercare(ccall((:GDALGetRasterXSize, libgdal), Cint, (Ptr{Cvoid},), arg1))
GDALGetRasterYSize(arg1)     = aftercare(ccall((:GDALGetRasterYSize, libgdal), Cint, (Ptr{Cvoid},), arg1))
GDALDatasetGetLayerCount(arg1) = aftercare(ccall((:GDALDatasetGetLayerCount, libgdal), Cint, (Ptr{Cvoid},), arg1))
GDALGetRasterCount(arg1)  = aftercare(ccall((:GDALGetRasterCount, libgdal), Cint, (Ptr{Cvoid},), arg1))
GDALGetFileList(arg1)     = aftercare(ccall((:GDALGetFileList, libgdal), Ptr{Cstring}, (Ptr{Cvoid},), arg1))
GDALGetRasterAccess(arg1) = aftercare(ccall((:GDALGetRasterAccess, libgdal), UInt32, (Ptr{Cvoid},), arg1))
GDALGetBandNumber(arg1)   = aftercare(ccall((:GDALGetBandNumber, libgdal), Cint, (Ptr{Cvoid},), arg1))
GDALGetDriverCount()      = aftercare(ccall((:GDALGetDriverCount, libgdal), Cint, ()))

function GDALGetRasterColorInterpretation(arg1)
	aftercare(ccall((:GDALGetRasterColorInterpretation, libgdal), UInt32, (Ptr{Cvoid},), arg1))
end

function GDALGetColorInterpretationName(a1)
	aftercare(ccall((:GDALGetColorInterpretationName, libgdal), Cstring, (UInt32,), a1), false)
end
function GDALGetPaletteInterpretationName(a1)
	aftercare(ccall((:GDALGetPaletteInterpretationName, libgdal), Cstring, (UInt32,), a1), false)
end

function GDALGetGeoTransform(arg1, arg2)
	aftercare(ccall((:GDALGetGeoTransform, libgdal), UInt32, (Ptr{Cvoid}, Ptr{Cdouble}), arg1, arg2))
end
function GDALSetGeoTransform(arg1, arg2)
	aftercare(ccall((:GDALSetGeoTransform, libgdal), UInt32, (Ptr{Cvoid}, Ptr{Cdouble}), arg1, arg2))
end

function GDALOpenEx(pszFilename, nOpenFlags, papszAllowedDrivers, papszOpenOptions, papszSiblingFiles)
	aftercare(ccall((:GDALOpenEx, libgdal), Ptr{Cvoid}, (Cstring, UInt32, Ptr{Cstring}, Ptr{Cstring}, Ptr{Cstring}), pszFilename, nOpenFlags, papszAllowedDrivers, papszOpenOptions, papszSiblingFiles))
end

GDALClose(a1) = aftercare(ccall((:GDALClose, libgdal), Cvoid, (Ptr{Cvoid},), a1))
GDALVersionInfo(a1) = aftercare(ccall((:GDALVersionInfo, libgdal), Cstring, (Cstring,), a1), false)

function GDALRasterIOEx(hRBand, eRWFlag, nDSXOff, nDSYOff, nDSXSize, nDSYSize, pBuffer, nBXSize, nBYSize, eBDataType, nPixelSpace, nLineSpace, psExtraArg)
	aftercare(ccall((:GDALRasterIOEx, libgdal), UInt32, (Ptr{Cvoid}, UInt32, Cint, Cint, Cint, Cint, UInt32, Cint, Cint, Ptr{Cvoid}, Clonglong, Clonglong, Ptr{GDALRasterIOExtraArg}), hRBand, eRWFlag, nDSXOff, nDSYOff, nDSXSize, nDSYSize, pBuffer, nBXSize, nBYSize, eBDataType, nPixelSpace, nLineSpace, psExtraArg))
end

function GDALDatasetRasterIOEx(hDS, eRWFlag, nDSXOff, nDSYOff, nDSXSize, nDSYSize, pBuffer, nBXSize, nBYSize, eBDataType, nBandCount, panBandCount, nPixelSpace, nLineSpace, nBandSpace, psExtraArg)
	aftercare(ccall((:GDALDatasetRasterIOEx, libgdal), UInt32, (Ptr{Cvoid}, UInt32, Cint, Cint, Cint, Cint, Ptr{Cvoid}, Cint, Cint, UInt32, Cint, Ptr{Cint}, Clonglong, Clonglong, Clonglong, Ptr{GDALRasterIOExtraArg}), hDS, eRWFlag, nDSXOff, nDSYOff, nDSXSize, nDSYSize, pBuffer, nBXSize, nBYSize, eBDataType, nBandCount, panBandCount, nPixelSpace, nLineSpace, nBandSpace, psExtraArg))
end

CPLSetConfigOption(a1, a2) = aftercare(ccall((:CPLSetConfigOption, libgdal), Cvoid, (Cstring, Cstring), a1, a2))

OSRDestroySpatialReference(a1) = aftercare(ccall((:OSRDestroySpatialReference, libgdal), Cvoid, (Ptr{Cvoid},), a1))
function OCTDestroyCoordinateTransformation(arg1)
	aftercare(ccall((:OCTDestroyCoordinateTransformation, libgdal), Cvoid, (Ptr{Cvoid},), arg1))
end

OSRExportToWkt(a1, a2) = aftercare(ccall((:OSRExportToWkt, libgdal), Cint, (Ptr{Cvoid}, Ptr{Cstring}), a1, a2))

function OSRExportToPrettyWkt(arg1, arg2, arg3)
	aftercare(ccall((:OSRExportToPrettyWkt, libgdal), Cint, (Ptr{Cvoid}, Ptr{Cstring}, Cint), arg1, arg2, arg3))
end

OSRExportToProj4(a1, a2) = aftercare(ccall((:OSRExportToProj4, libgdal), Cint, (Ptr{Cvoid}, Ptr{Cstring}), a1, a2))
OSRImportFromWkt(a1, a2) = aftercare(ccall((:OSRImportFromWkt, libgdal), Cint, (Ptr{Cvoid}, Ptr{Cstring}), a1, a2))
OSRImportFromProj4(a1, a2) = aftercare(ccall((:OSRImportFromProj4, libgdal), Cint, (Ptr{Cvoid}, Cstring), a1, a2))
OSRImportFromEPSG(a1, a2) = aftercare(ccall((:OSRImportFromEPSG, libgdal), Cint, (Ptr{Cvoid}, Cint), a1, a2))
OSRNewSpatialReference(a1) = aftercare(ccall((:OSRNewSpatialReference, libgdal), Ptr{Cvoid}, (Cstring,), a1))

function OSRSetAxisMappingStrategy(hSRS, strategy)
	(Gdal.GDALVERSION[] < v"3.0.0") && return
	aftercare(ccall((:OSRSetAxisMappingStrategy, libgdal), Cvoid, (Ptr{Cvoid}, UInt32), hSRS, strategy))
end

OGR_FD_GetName(a1) = aftercare(ccall((:OGR_FD_GetName, libgdal), Cstring, (Ptr{Cvoid},), a1), false)
OGR_L_GetName(a1)  = aftercare(ccall((:OGR_L_GetName, libgdal), Cstring, (Ptr{Cvoid},), a1), false)
OGR_Fld_GetNameRef(a1)    = aftercare(ccall((:OGR_Fld_GetNameRef, libgdal), Cstring, (Ptr{Cvoid},), a1), false)
OGR_FD_GetGeomType(a1)    = aftercare(ccall((:OGR_FD_GetGeomType, libgdal), UInt32, (Ptr{Cvoid},), a1))
OGR_L_GetGeomType(a1)     = aftercare(ccall((:OGR_L_GetGeomType, libgdal), UInt32, (Ptr{Cvoid},), a1))
OGR_G_GetGeometryType(a1) = aftercare(ccall((:OGR_G_GetGeometryType, libgdal), UInt32, (Ptr{Cvoid},), a1))
#OGR_GetFieldTypeName(a1)  = aftercare(ccall((:OGR_GetFieldTypeName, libgdal), Cstring, (UInt32,), a1), false)
#OGR_GetFieldSubTypeName(a1) = aftercare(ccall((:OGR_GetFieldSubTypeName, libgdal), Cstring, (UInt32,), a1), false)
OGRGetDriverCount() = aftercare(ccall((:OGRGetDriverCount, libgdal), Cint, ()))

function OGR_L_GetFeatureCount(arg1, arg2)
	aftercare(ccall((:OGR_L_GetFeatureCount, libgdal), Clonglong, (Ptr{Cvoid}, Cint), arg1, arg2))
end

function GDALInfoOptionsNew(pArgv, psOFB)
	aftercare(ccall((:GDALInfoOptionsNew, libgdal), Ptr{Cvoid}, (Ptr{Cstring}, Ptr{Cvoid}), pArgv, psOFB))
end

GDALInfoOptionsFree(psO) = aftercare(ccall((:GDALInfoOptionsFree, libgdal), Cvoid, (Ptr{Cvoid},), psO))

function GDALInfo(hDataset, psO)
	aftercare(ccall((:GDALInfo, libgdal), Cstring, (Ptr{Cvoid}, Ptr{Cvoid}), hDataset, psO), true)
end

function GDALTranslateOptionsNew(pArgv, psOFB)
	aftercare(ccall((:GDALTranslateOptionsNew, libgdal), Ptr{Cvoid}, (Ptr{Cstring}, Ptr{Cvoid}), pArgv, psOFB))
end

function GDALTranslate(pszDestFilename, hSrcDataset, psOptions, pbUsageError)
	aftercare(ccall((:GDALTranslate, libgdal), Ptr{Cvoid}, (Cstring, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint}), pszDestFilename, hSrcDataset, psOptions, pbUsageError))
end

GDALTranslateOptionsFree(psO) = aftercare(ccall((:GDALTranslateOptionsFree, libgdal), Cvoid, (Ptr{Cvoid},), psO))

function GDALDEMProcessingOptionsNew(pArgv, psOFB)
	aftercare(ccall((:GDALDEMProcessingOptionsNew, libgdal), Ptr{Cvoid}, (Ptr{Cstring}, Ptr{Cvoid}), pArgv, psOFB))
end

function GDALDEMProcessingOptionsFree(psO)
	aftercare(ccall((:GDALDEMProcessingOptionsFree, libgdal), Cvoid, (Ptr{Cvoid},), psO))
end

function GDALDEMProcessing(pszDestFilename, hSrcDataset, pszProcessing, pszColorFilename, psOptions, pbUE)
	aftercare(ccall((:GDALDEMProcessing, libgdal), Ptr{Cvoid}, (Cstring, Ptr{Cvoid}, Cstring, Cstring, Ptr{Cvoid}, Ptr{Cint}), pszDestFilename, hSrcDataset, pszProcessing, pszColorFilename, psOptions, pbUE))
end

function GDALGridOptionsNew(pArgv, psOFB)
	aftercare(ccall((:GDALGridOptionsNew, libgdal), Ptr{Cvoid}, (Ptr{Cstring}, Ptr{Cvoid}), pArgv, psOFB))
end

GDALGridOptionsFree(psO) = aftercare(ccall((:GDALGridOptionsFree, libgdal), Cvoid, (Ptr{Cvoid},), psO))

function GDALGrid(pDest, hSrcDS, psO, pbUE)
	aftercare(ccall((:GDALGrid, libgdal), Ptr{Cvoid}, (Cstring, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint}), pDest, hSrcDS, psO, pbUE))
end

function GDALVectorTranslateOptionsNew(pArgv, psOFB)
	aftercare(ccall((:GDALVectorTranslateOptionsNew, libgdal), Ptr{Cvoid}, (Ptr{Cstring}, Ptr{Cvoid}), pArgv, psOFB))
end

function GDALVectorTranslateOptionsFree(psO)
	aftercare(ccall((:GDALVectorTranslateOptionsFree, libgdal), Cvoid, (Ptr{Cvoid},), psO))
end

function GDALVectorTranslate(pszDest, hDstDS, nSrcCount, pahSrcDS, psO, pbUE)
	aftercare(ccall((:GDALVectorTranslate, libgdal), Ptr{Cvoid}, (Cstring, Ptr{Cvoid}, Cint, Ptr{Ptr{Cvoid}}, Ptr{Cvoid}, Ptr{Cint}), pszDest, hDstDS, nSrcCount, pahSrcDS, psO, pbUE))
end

function GDALWarp(pszDest, hDstDS, nSrcCount, pahSrcDS, psO, pbUE)
	aftercare(ccall((:GDALWarp, libgdal), Ptr{Cvoid}, (Cstring, Ptr{Cvoid}, Cint, Ptr{Ptr{Cvoid}}, Ptr{Cvoid}, Ptr{Cint}), pszDest, hDstDS, nSrcCount, pahSrcDS, psO, pbUE))
end

GDALWarpAppOptionsFree(psO) = aftercare(ccall((:GDALWarpAppOptionsFree, libgdal), Cvoid, (Ptr{Cvoid},), psO))

function GDALWarpAppOptionsNew(pArgv, psOFB)
	aftercare(ccall((:GDALWarpAppOptionsNew, libgdal), Ptr{Cvoid}, (Ptr{Cstring}, Ptr{Cvoid}), pArgv, psOFB))
end

# ------------------------------------------- ArchGDAL stuff ----------------------------------------------------------

abstract type AbstractDataset end			# needs to have a `ptr::GDALDataset` attribute
abstract type AbstractSpatialRef end		# needs to have a `ptr::GDALSpatialRef` attribute
#abstract type AbstractRasterBand{T} <: AbstractDiskArray{T,2} end # needs to have a `ptr::GDALDataset` attribute
abstract type AbstractRasterBand{T} end		# needs to have a `ptr::GDALDataset` attribute
#abstract type AbstractGeometry <: GeoInterface.AbstractGeometry end	# needs to have a `ptr::GDALGeometry` attribute
abstract type AbstractGeometry  end			# needs to have a `ptr::GDALGeometry` attribute
abstract type AbstractFeatureDefn end		# needs to have a `ptr::GDALFeatureDefn` attribute
abstract type AbstractFeatureLayer end		# needs to have a `ptr::GDALDataset` attribute
abstract type AbstractFieldDefn end			# needs to have a `ptr::GDALFieldDefn` attribute
abstract type AbstractGeomFieldDefn end		# needs to have a `ptr::GDALGeomFieldDefn` attribute

	mutable struct CoordTransform
		ptr::Ptr{Cvoid}
	end

	mutable struct Dataset <: AbstractDataset
		ptr::Ptr{Cvoid}
		Dataset(ptr::Ptr{Cvoid}=C_NULL) = new(ptr)
	end

	mutable struct IDataset <: AbstractDataset
		ptr::Ptr{Cvoid}
		function IDataset(ptr::Ptr{Cvoid}=C_NULL)
			dataset = new(ptr)
			finalizer(destroy, dataset)
			return dataset
		end
	end

	mutable struct Driver
		ptr::Ptr{Cvoid}
	end

	mutable struct RasterBand{T} <: AbstractRasterBand{T}
		ptr::Ptr{Cvoid}
	end
	function RasterBand(ptr::Ptr{Cvoid})
		t = _JLTYPE[GDALGetRasterDataType(ptr)]
		RasterBand{t}(ptr)
	end

	mutable struct IRasterBand{T} <: AbstractRasterBand{T}
		ptr::Ptr{Cvoid}
		ownedby::AbstractDataset
		function IRasterBand{T}(ptr::Ptr{Cvoid}=C_NULL; ownedby::AbstractDataset=Dataset()) where T
			rasterband = new(ptr, ownedby)
			finalizer(destroy, rasterband)
			return rasterband
		end
	end

	function IRasterBand(ptr::Ptr{Cvoid}; ownedby = Dataset())
		t = _JLTYPE[GDALGetRasterDataType(ptr)]
		IRasterBand{t}(ptr, ownedby=ownedby)
	end

	mutable struct SpatialRef <: AbstractSpatialRef
		ptr::Ptr{Cvoid}
		SpatialRef(ptr::Ptr{Cvoid} = C_NULL) = new(ptr)
	end

	mutable struct ISpatialRef <: AbstractSpatialRef
		ptr::Ptr{Cvoid}
		function ISpatialRef(ptr::Ptr{Cvoid}=C_NULL)
			spref = new(ptr)
			finalizer(destroy, spref)
			return spref
		end
	end

	mutable struct FeatureLayer <: AbstractFeatureLayer
		ptr::Ptr{Cvoid}
	end

	mutable struct IFeatureLayer <: AbstractFeatureLayer
		ptr::Ptr{Cvoid}
		ownedby::AbstractDataset
		spatialref::AbstractSpatialRef
		function IFeatureLayer(ptr::Ptr{Cvoid}=C_NULL; ownedby::AbstractDataset=Dataset(),
				spatialref::AbstractSpatialRef=SpatialRef())
			layer = new(ptr, ownedby, spatialref)
			finalizer(destroy, layer)
			return layer
		end
	end

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
		GDT_Float64    => Float64)

	macro cplerr(code, message)
		return quote
			($(esc(code)) != CE_None) && error($message)
		end
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

	function setproj!(dataset::AbstractDataset, projstring::AbstractString)
		result = GDALSetProjection(dataset.ptr, projstring)
		@cplerr result "Could not set projection"
		return dataset
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
		OSRDestroySpatialReference(spref.ptr)
		spref.ptr = C_NULL
	end
	
	function destroy(obj::CoordTransform)
		OCTDestroyCoordinateTransformation(obj.ptr)
		obj.ptr = C_NULL
	end

	function destroy(band::AbstractRasterBand)
		band.ptr = Ptr{Cvoid}(C_NULL)
		return band
	end

	function destroy(band::IRasterBand)
		band.ptr = Ptr{Cvoid}(C_NULL)
		band.ownedby = Dataset()
		return band
	end

	function create(fname::AbstractString; driver::Driver=identifydriver(fname), width::Integer=0,
		height::Integer=0, nbands::Integer=0, dtype::DataType=Any, options=Ptr{Cstring}(C_NULL), I::Bool=true)
		r = GDALCreate(driver.ptr, fname, width, height, nbands, _GDALTYPE[dtype], options)
		return (I) ? IDataset(r) : Dataset(r)
	end
	unsafe_create(fname::AbstractString; driver::Driver=identifydriver(fname), width::Integer=0,
		height::Integer=0, nbands::Integer=0, dtype::DataType=Any, options=Ptr{Cstring}(C_NULL), I::Bool=false) =
		create(fname; driver=driver, width=width, height=height, nbands=nbands, dtype=dtype, options=options, I=I)

	function create(driver::Driver; fname::AbstractString=string("/vsimem/$(gensym())"), width::Integer=0,
		height::Integer=0, nbands::Integer=0, dtype::DataType=Any, options=Ptr{Cstring}(C_NULL), I::Bool=true)
		r = GDALCreate(driver.ptr, fname, width, height, nbands, _GDALTYPE[dtype], options)
		return (I) ? IDataset(r) : Dataset(r)
	end
	unsafe_create(driver::Driver; fname::AbstractString=string("/vsimem/$(gensym())"), width::Integer=0,
		height::Integer=0, nbands::Integer=0, dtype::DataType=Any, options=Ptr{Cstring}(C_NULL), I::Bool=false) =
		create(driver; fname=fname, width=width, height=height, nbands=nbands, dtype=dtype, options=options, I=I)

	function read(filename::AbstractString; flags = GDAL_OF_READONLY | GDAL_OF_VERBOSE_ERROR,
		alloweddrivers=Ptr{Cstring}(C_NULL), options=Ptr{Cstring}(C_NULL), siblingfiles=Ptr{Cstring}(C_NULL), I::Bool=true)
		r = GDALOpenEx(filename, Int(flags), alloweddrivers, options, siblingfiles)
		return (I) ? IDataset(r) : Dataset(r)
	end
	unsafe_read(fname::AbstractString; flags = GDAL_OF_READONLY | GDAL_OF_VERBOSE_ERROR, alloweddrivers=Ptr{Cstring}(C_NULL),
		options=Ptr{Cstring}(C_NULL), siblingfiles=Ptr{Cstring}(C_NULL), I::Bool=false) =
		read(fname=fname; flags=flags, alloweddrivers=alloweddrivers, options=options, siblingfiles=siblingfiles, I=I)

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
	#read!(ds::IDataset, buffer::Array{<:Real, 3}) = read!(Dataset(ds.ptr), buffer)
	
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
					bandspace::Integer=0, extraargs=Ptr{GDALRasterIOExtraArg}(C_NULL))
				(dataset == C_NULL) && error("Can't read invalid rasterband")
				xbsize, ybsize, zbsize = size(buffer)
				nband = length(bands)
				bands = isa(bands, Vector{Cint}) ? bands : Cint.(collect(bands))
				@assert nband == zbsize
				result = ccall((:GDALDatasetRasterIOEx,libgdal), UInt32, (Ptr{Cvoid}, UInt32, Cint, Cint, Cint, Cint,
							   Ptr{Cvoid}, Cint, Cint, UInt32, Cint, UInt32, Clonglong, Clonglong, Clonglong,
							   Ptr{GDALRasterIOExtraArg}), dataset.ptr, access, xoffset, yoffset, xsize, ysize,
							   pointer(buffer), xbsize, ybsize, $GT, nband, pointer(bands), pxspace, linespace,
							   bandspace, extraargs)
				@cplerr result "Access in DatasetRasterIO failed."
				return buffer
			end
	
			function rasterio!(rasterband::AbstractRasterBand, buffer::Matrix{$T}, xoffset::Int, yoffset::Int,
					xsize::Integer, ysize::Integer, access::UInt32=GF_Read, pxspace::Integer=0,
					linespace::Integer=0, extraargs=Ptr{GDALRasterIOExtraArg}(C_NULL))
				(rasterband == C_NULL) && error("Can't read invalid rasterband")
				xbsize, ybsize = size(buffer)
				result = ccall((:GDALRasterIOEx,libgdal),UInt32,
					(Ptr{Cvoid},UInt32,Cint,Cint,Cint,Cint,Ptr{Cvoid}, Cint,Cint,UInt32,Clonglong, Clonglong,
					Ptr{GDALRasterIOExtraArg}),
					rasterband.ptr,access,xoffset, yoffset,xsize,ysize,pointer(buffer),xbsize,ybsize,$GT,pxspace,
					linespace,extraargs)
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

	getdriver(dataset::AbstractDataset) = Driver(GDALGetDatasetDriver(dataset.ptr))
	getdriver(i::Integer) = Driver(GDALGetDriver(i))
	getdriver(name::AbstractString) = Driver(GDALGetDriverByName(name))

	getband(dataset::AbstractDataset, i::Integer=1) = IRasterBand(GDALGetRasterBand(dataset.ptr, i), ownedby=dataset)
	getband(ds::RasterDataset, i::Integer=1) = getband(ds.ds, i)
	getproj(dataset::AbstractDataset) = GDALGetProjectionRef(dataset.ptr)
	readraster(s::String; kwargs...) = RasterDataset(read(s; kwargs...))

	shortname(drv::Driver) = GDALGetDriverShortName(drv.ptr)
	longname(drv::Driver) = GDALGetDriverLongName(drv.ptr)
	options(drv::Driver) = GDALGetDriverCreationOptionList(drv.ptr)
	driveroptions(name::AbstractString) = options(getdriver(name))

	function gdalwarp(datasets::Vector{Dataset}, options=String[]; dest = "/vsimem/tmp")
		options = GDALWarpAppOptionsNew(options, C_NULL)
		usage_error = Ref{Cint}()
		result = GDALWarp(dest, C_NULL, length(datasets), [ds.ptr for ds in datasets], options, usage_error)
		GDALWarpAppOptionsFree(options)
		return Dataset(result)
	end
	gdalwarp(ds::Dataset, opts=String[]; dest="/vsimem/tmp") = gdalwarp([ds], opts; dest=dest)
	gdalwarp(ds::IDataset, opts=String[]; dest="/vsimem/tmp") = gdalwarp([Dataset(ds.ptr)], opts; dest=dest)

	function gdaltranslate(dataset::Dataset, options = String[]; dest = "/vsimem/tmp")
		options = GDALTranslateOptionsNew(options, C_NULL)
		usage_error = Ref{Cint}()
		result = GDALTranslate(dest, dataset.ptr, options, usage_error)
		GDALTranslateOptionsFree(options)
		return Dataset(result)
	end
	gdaltranslate(ds::IDataset, opts=String[]; dest="/vsimem/tmp") = gdaltranslate(Dataset(ds.ptr), opts; dest=dest)

	function gdalinfo(ds::Dataset, options=String[])
		options = GDALInfoOptionsNew(options, C_NULL)
		result = GDALInfo(ds.ptr, options)
		GDALInfoOptionsFree(options)
		return result
	end
	gdalinfo(ds::IDataset, opts=String[]) = gdalinfo(Dataset(ds.ptr), opts)

	function gdaldem(dataset::Dataset, processing::String, options=String[]; dest="/vsimem/tmp", colorfile=C_NULL)
		if processing == "color-relief"
			@assert colorfile != C_NULL
		end
		options = GDALDEMProcessingOptionsNew(options, C_NULL)
		usage_error = Ref{Cint}()
		result = GDALDEMProcessing(dest, dataset.ptr, processing, colorfile, options, usage_error)
		GDALDEMProcessingOptionsFree(options)
		return Dataset(result)
	end
	gdaldem(ds::IDataset, processing::String, opts=String[]; dest="/vsimem/tmp", colorfile=C_NULL) = gdaldem(Dataset(ds.ptr), processing, opts; dest=dest, colorfile=colorfile)

	function gdalgrid(dataset::Dataset, options=String[]; dest="/vsimem/tmp")
		options = GDALGridOptionsNew(options, C_NULL)
		usage_error = Ref{Cint}()
		result = GDALGrid(dest, dataset.ptr, options, usage_error)
		GDALGridOptionsFree(options)
		return Dataset(result)
	end
	gdalgrid(ds::IDataset, opts=String[]; dest="/vsimem/tmp") = gdalgrid(Dataset(ds.ptr), opts; dest=dest)

	function gdalvectortranslate(datasets::Vector{Dataset}, options=String[]; dest="/vsimem/tmp")
		options = GDALVectorTranslateOptionsNew(options, C_NULL)
		usage_error = Ref{Cint}()
		result = GDALVectorTranslate(dest, C_NULL, length(datasets), [ds.ptr for ds in datasets], options, usage_error)
		GDALVectorTranslateOptionsFree(options)
		return Dataset(result)
	end
	gdalvectortranslate(ds::Dataset, opts=String[]; dest="/vsimem/tmp") = gdalvectortranslate([ds], opts; dest=dest)
	gdalvectortranslate(ds::IDataset, opts=String[]; dest="/vsimem/tmp") = gdalvectortranslate([Dataset(ds.ptr)], opts; dest=dest)

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

	function toPROJ4(spref::AbstractSpatialRef)
		projptr = Ref{Cstring}()
		result = OSRExportToProj4(spref.ptr, projptr)
		@ogrerr result "Failed to export this SRS to PROJ.4 format"
		return unsafe_string(projptr[])
	end

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

	getlayer(dataset::AbstractDataset, i::Integer) = IFeatureLayer(GDALDatasetGetLayer(dataset.ptr, i), ownedby=dataset)
	function getlayer(dataset::AbstractDataset, name::AbstractString)
		return IFeatureLayer(GDALDatasetGetLayerByName(dataset.ptr, name), ownedby = dataset)
	end
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
	getname(fielddefn::AbstractFieldDefn) = OGR_Fld_GetNameRef(fielddefn.ptr)
	getname(obj::UInt32)   = GDALGetColorInterpretationName(obj)
	#getname(obj::GDALPaletteInterp) = GDALGetPaletteInterpretationName(obj)
	#getname(obj::OGRFieldType)      = OGR_GetFieldTypeName(obj)
	#getname(obj::OGRFieldSubType)   = OGR_GetFieldSubTypeName(obj)

	getgeomtype(featuredefn::AbstractFeatureDefn) = OGR_FD_GetGeomType(featuredefn.ptr)
	getgeomtype(layer::AbstractFeatureLayer) = OGR_L_GetGeomType(layer.ptr)
	getgeomtype(geom::AbstractGeometry)  = OGR_G_GetGeometryType(geom.ptr)

	accessflag(band::AbstractRasterBand) = GDALGetRasterAccess(band.ptr)
	indexof(band::AbstractRasterBand)    = GDALGetBandNumber(band.ptr)
	pixeltype(band::AbstractRasterBand{T}) where T = T
	getcolorinterp(band::AbstractRasterBand) = GDALGetRasterColorInterpretation(band.ptr)


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
				layergeomtype = getgeomtype(layer)
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

	#Base.show(io::IO, raster::RasterDataset) = show(io, raster.ds)
	#Base.show(io::IO, ::MIME"text/plain", raster::RasterDataset) = show(io, raster.ds)

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

	# ------------ Aliases ------------
	const creategd = create
	const ogr2ogr  = gdalvectortranslate
	const readgd   = read
	const readgd!  = read!
	const writegd! = write!
	# ---------------------------------

	export
		creategd, getband, getdriver, getproj, getgeotransform, toPROJ4, toWKT, importPROJ4, importWKT,
		importEPSG, gdalinfo, gdalwarp, gdaldem, gdaltranslate, gdalgrid, gdalvectortranslate, ogr2ogr,
		readgd, readgd!, readraster, writegd!, setgeotransform!, setproj!

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
For the time being this sub-module is not intended to much direct use so it has no further
documentation. Interested people should consult the GDAL & ArchGDAL docs.
"""
Gdal

end			# End module