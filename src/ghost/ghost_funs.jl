"""
	ghost_funs.jl — PostScript rasterization and utilities via Ghostscript C API.

	Uses GMT's bundled libgs (gsdll64.dll) via libghostscript.jl.

	┌────────────┬──────────────────────────────────────────┬───────────────────────────────────────────┐
	│ Function   │ Input                                    │ Output                                    │
	├────────────┼──────────────────────────────────────────┼───────────────────────────────────────────┤
	│ ps2image   │ PS content (String/Vector{UInt8}),       │ Array{UInt8,3} H×W×3 (or H×W if gray)     │
	│            │ dpi, gray                                │                                           │
	├────────────┼──────────────────────────────────────────┼───────────────────────────────────────────┤
	│ ps2raster  │ PS file path (String),                   │ output file path (String)                 │
	│            │ outfile, fmt, dpi, gray                  │                                           │
	├────────────┼──────────────────────────────────────────┼───────────────────────────────────────────┤
	│ psbbox     │ PS file path or PS content               │ (llx, lly, urx, ury) in PS points         │
	│            │ (String/Vector{UInt8})                   │ Float64 NamedTuple                        │
	├────────────┼──────────────────────────────────────────┼───────────────────────────────────────────┤
	│ psview     │ PS content or GMTps, dpi                 │ nothing — native window (Win32/x11/aqua)  │
	└────────────┴──────────────────────────────────────────┴───────────────────────────────────────────┘
"""

# Include libghostscript.jl in GMT's own scope so that all ccalls use GMT's `libgs`,
# not Ghostscript_jll's libgs-9.dll which lacks the bbox device.
#include(joinpath(dirname(Base.find_package("Ghostscript")), "libghostscript.jl"))

# ── Display format flags (gdevdsp.h) ─────────────────────────────────────────
# RGB 24-bit, no alpha, big-endian, top row first = 0x00000804
const _GS_FMT_RGB24   = 0x00000004 | 0x00000800
const _GS_FMT_GRAY8   = 0x00000002 | 0x00000800

# ── Raster capture state ──────────────────────────────────────────────────────
# Global because @cfunction callbacks can't carry Julia closures.
mutable struct _GSRasterState
	width   :: Int
	height  :: Int
	raster  :: Int           # bytes per row (may include padding)
	format  :: UInt32
	pimage  :: Ptr{UInt8}    # GS-owned pixel buffer, valid during display_page
	data    :: Vector{UInt8} # our copy, filled in display_page callback
	ready   :: Bool
end

isdefined(@__MODULE__, :_GS_STATE) || const _GS_STATE = _GSRasterState(0, 0, 0, 0, C_NULL, UInt8[], false)

function _gs_state_reset!()
	_GS_STATE.width  = 0;  _GS_STATE.height = 0;  _GS_STATE.raster = 0
	_GS_STATE.format = 0;  _GS_STATE.pimage = C_NULL
	_GS_STATE.data   = UInt8[];  _GS_STATE.ready = false
end

# ── display_callback struct (gdevdsp.h display_callback_s, version 2.0) ──────
# Must match C layout exactly. size field = sizeof(this struct).
struct _GSDisplayCallback
	size               :: Cint
	version_major      :: Cint
	version_minor      :: Cint
	display_open       :: Ptr{Cvoid}
	display_preclose   :: Ptr{Cvoid}
	display_close      :: Ptr{Cvoid}
	display_presize    :: Ptr{Cvoid}
	display_size       :: Ptr{Cvoid}
	display_sync       :: Ptr{Cvoid}
	display_page       :: Ptr{Cvoid}
	display_update     :: Ptr{Cvoid}
	display_memalloc   :: Ptr{Cvoid}  # C_NULL → GS uses its own allocator
	display_memfree    :: Ptr{Cvoid}  # C_NULL
	display_separation :: Ptr{Cvoid}
end

# ── C callbacks ───────────────────────────────────────────────────────────────

_gs_cb_open(handle::Ptr{Cvoid}, device::Ptr{Cvoid})::Cint = Cint(0)
_gs_cb_preclose(handle::Ptr{Cvoid}, device::Ptr{Cvoid})::Cint = Cint(0)
_gs_cb_close(handle::Ptr{Cvoid}, device::Ptr{Cvoid})::Cint = Cint(0)
_gs_cb_presize(handle::Ptr{Cvoid}, device::Ptr{Cvoid}, w::Cint, h::Cint, r::Cint, fmt::Cuint)::Cint = Cint(0)
_gs_cb_sync(handle::Ptr{Cvoid}, device::Ptr{Cvoid})::Cint = Cint(0)
_gs_cb_update(handle::Ptr{Cvoid}, device::Ptr{Cvoid}, x::Cint, y::Cint, w::Cint, h::Cint)::Cint = Cint(0)

# GS calls this when it allocates the image buffer. Capture dims + pointer.
function _gs_cb_size(handle::Ptr{Cvoid}, device::Ptr{Cvoid},
					 width::Cint, height::Cint, raster::Cint,
					 format::Cuint, pimage::Ptr{Cuchar})::Cint
	_GS_STATE.width  = Int(width)
	_GS_STATE.height = Int(height)
	_GS_STATE.raster = Int(raster)
	_GS_STATE.format = UInt32(format)
	_GS_STATE.pimage = Ptr{UInt8}(pimage)
	Cint(0)
end

# GS calls this when showpage fires. Buffer is complete — copy to Julia.
function _gs_cb_page(handle::Ptr{Cvoid}, device::Ptr{Cvoid}, copies::Cint, flush::Cint)::Cint
	if _GS_STATE.pimage != C_NULL && _GS_STATE.width > 0 && _GS_STATE.height > 0
		nbytes = _GS_STATE.raster * _GS_STATE.height
		_GS_STATE.data  = copy(unsafe_wrap(Vector{UInt8}, _GS_STATE.pimage, nbytes; own=false))
		_GS_STATE.ready = true
	end
	Cint(0)
end

# Build callback struct. Returns Ref to keep it GC-pinned for the GS session.
function _gs_make_callback_ref()
	Ref(_GSDisplayCallback(
		Cint(sizeof(_GSDisplayCallback)),
		Cint(2), Cint(0),   # version 2.0
		@cfunction(_gs_cb_open,     Cint, (Ptr{Cvoid}, Ptr{Cvoid})),
		@cfunction(_gs_cb_preclose, Cint, (Ptr{Cvoid}, Ptr{Cvoid})),
		@cfunction(_gs_cb_close,    Cint, (Ptr{Cvoid}, Ptr{Cvoid})),
		@cfunction(_gs_cb_presize,  Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Cint, Cint, Cint, Cuint)),
		@cfunction(_gs_cb_size,     Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Cint, Cint, Cint, Cuint, Ptr{Cuchar})),
		@cfunction(_gs_cb_sync,     Cint, (Ptr{Cvoid}, Ptr{Cvoid})),
		@cfunction(_gs_cb_page,     Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Cint, Cint)),
		@cfunction(_gs_cb_update,   Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Cint, Cint, Cint, Cint)),
		C_NULL,  # display_memalloc
		C_NULL,  # display_memfree
		C_NULL,  # display_separation
	))
end


function _gs_run_ps_str(inst::Ptr{Cvoid}, ps_data::Union{String, AbstractVector{UInt8}}, errbuf_fn::Function)
	n         = ps_data isa String ? ncodeunits(ps_data) : length(ps_data)
	exit_code = Ref{Cint}(0)
	_GS_CHUNK = 65536
	GC.@preserve ps_data begin
		ptr = Ptr{UInt8}(pointer(ps_data))
		if n <= _GS_CHUNK
			rc = gsapi_run_string_with_length(inst, ptr, Cuint(n), Cint(0), exit_code)
			rc < 0 && error("gsapi_run_string_with_length failed: $rc (exit=$(exit_code[]))\n$(errbuf_fn())")
			return
		end
		rc = gsapi_run_string_begin(inst, Cint(0), exit_code)
		rc < 0 && error("gsapi_run_string_begin failed: $rc\n$(errbuf_fn())")
		offset = 0
		while offset < n
			len = min(_GS_CHUNK, n - offset)
			gsapi_run_string_continue(inst, ptr + offset, Cuint(len), Cint(0), exit_code)
			offset += len
		end
		rc = gsapi_run_string_end(inst, Cint(0), exit_code)
		rc < 0 && error("gsapi_run_string_end failed: $rc\n$(errbuf_fn())")
	end
end

function _gs_session(args::Vector{String}, action::Function; setup::Function=(_)->nothing, display_cb=nothing)
	inst_ref = Ref{Ptr{Cvoid}}(C_NULL)
	rc = gsapi_new_instance(inst_ref, C_NULL)
	rc < 0 && error("gsapi_new_instance failed: $rc")
	inst = inst_ref[]
	try
		gsapi_set_arg_encoding(inst, GS_ARG_ENCODING_UTF8)
		if display_cb !== nothing
			rc = gsapi_set_display_callback(inst, display_cb)
			rc < 0 && error("gsapi_set_display_callback failed: $rc")
		end
		setup(inst)
		#args_c = [Base.cconvert(Cstring, s) for s in args]
		#argv   = [Base.unsafe_convert(Cstring, s) for s in args_c]
		GC.@preserve display_cb begin
			rc = gsapi_init_with_args(inst, Cint(length(args)), args)
			rc < 0 && error("gsapi_init_with_args failed: $rc")
			action(inst)
		end
	finally
		gsapi_exit(inst)
		gsapi_delete_instance(inst)
	end
end

# ── Public API ────────────────────────────────────────────────────────────────

"""
	ps2image(ps_data; dpi=300, gray=false) -> Array{UInt8,3}

Rasterize PostScript data using the Ghostscript C API.

- `ps_data` : `String` or `Vector{UInt8}` with PostScript source.
- `dpi`     : output resolution (default 300).
- `gray`    : return grayscale `Array{UInt8,2}` instead of RGB.

Returns `(height, width, 3)` UInt8 array suitable for `mat2img()`.

```julia
img = mat2img(ps2image(read("figure.ps"); dpi=300))
imshow(img)
```
"""
function ps2image(ps_data::Union{String, AbstractVector{UInt8}}; dpi::Int=300, gray::Bool=false)
	fmt_int = gray ? _GS_FMT_GRAY8 : _GS_FMT_RGB24
	nch     = gray ? 1 : 3
	_gs_state_reset!()
	cb_ref = _gs_make_callback_ref()
	args = ["gs", "-dNOPAUSE", "-dNOPROMPT", "-dQUIET", "-dSCANCONVERTERTYPE=2",
	        "-dUseFastColor=true", "-dGraphicsAlphaBits=4", "-dTextAlphaBits=4",
	        "-sDEVICE=display", "-dDisplayFormat=$(fmt_int)", "-r$(dpi)"]
	_gs_session(args, inst -> _gs_run_ps_str(inst, ps_data, () -> ""); display_cb=cb_ref)
	_GS_STATE.ready || error("Ghostscript produced no output — check PostScript validity.")
	W = _GS_STATE.width;  H = _GS_STATE.height;  R = _GS_STATE.raster
	img = if R == W * nch
		permutedims(reshape(_GS_STATE.data, nch, W, H), (3, 2, 1))
	else
		out = Array{UInt8}(undef, H, W, nch)
		@inbounds Threads.@threads for row in 1:H
			row0 = (row - 1) * R
			for col in 1:W
				px = row0 + (col - 1) * nch
				for c in 1:nch
					out[row, col, c] = _GS_STATE.data[px + c]
				end
			end
		end
		out
	end
	gray ? img[:, :, 1] : img
end

# ─────────────────────────────────────────────────────────────────────────────
"""
	ps2raster(ps_file; outfile=nothing, fmt="png", dpi=300, gray=false) -> String

Convert a PostScript or EPS file to a raster image using the Ghostscript C API.
Equivalent to running `gs -sDEVICE=png16m -sOutputFile=... -r300 file.ps`.

- `ps_file` : path to a PS or EPS file.
- `outfile` : output path. Defaults to `ps_file` with the extension replaced.
			 For multi-page output use a `%d` pattern (e.g. `"page%02d.png"`).
- `fmt`     : output format — `"png"` (default), `"jpg"`/`"jpeg"`, `"tif"`/`"tiff"`.
- `dpi`     : output resolution in dots per inch (default 300).
- `gray`    : render in grayscale (uses `pnggray` / `tiffgray` device).

Returns the output file path (the `outfile` string as given or auto-generated).

```julia
outpath = ps2raster("figure.ps"; dpi=300, fmt="png")
outpath = ps2raster("figure.ps"; outfile="out%02d.png", dpi=200)  # multi-page
```
"""
function ps2raster(ps_file::String; outfile=nothing, fmt::String="png", dpi::Int=300, gray::Bool=false)
	isfile(ps_file) || error("File not found: $ps_file")
	fmt_lc = lowercase(strip(fmt, '.'))
	device = if fmt_lc == "png"
		gray ? "pnggray" : "png16m"
	elseif fmt_lc in ("jpg", "jpeg")
		"jpeg"
	elseif fmt_lc in ("tif", "tiff")
		gray ? "tiffgray" : "tiff24nc"
	else
		error("Unsupported format \"$fmt\". Use \"png\", \"jpg\", or \"tif\".")
	end
	ext     = fmt_lc in ("jpg", "jpeg") ? ".jpg" : fmt_lc in ("tif", "tiff") ? ".tif" : ".png"
	outpath = outfile !== nothing ? string(outfile) : splitext(ps_file)[1] * ext
	args = ["gs", "-dNOPAUSE", "-dNOPROMPT", "-dQUIET", "-dBATCH",
			"-sDEVICE=$(device)", "-sOutputFile=$(outpath)", "-r$(dpi)"]
	_gs_session(args, inst -> begin
		exit_code = Ref{Cint}(0)
		rc = gsapi_run_file(inst, ps_file, Cint(0), exit_code)
		rc < 0 && error("gsapi_run_file failed: $rc (exit=$(exit_code[]))")
	end)
	!occursin('%', outpath) && !isfile(outpath) && error("Ghostscript produced no output — check PostScript validity.")
	outpath
end

# ─────────────────────────────────────────────────────────────────────────────

# Stderr capture buffer for psbbox. @cfunction can't close over locals.
isdefined(@__MODULE__, :_GS_BBOX_BUF) || const _GS_BBOX_BUF = Ref{Vector{UInt8}}(UInt8[])

function _gs_bbox_stderr_cb(h::Ptr{Cvoid}, str::Ptr{Cchar}, len::Cint)::Cint
	append!(_GS_BBOX_BUF[], unsafe_wrap(Vector{UInt8}, Ptr{UInt8}(str), Int(len); own=false))
	len
end

"""
	psbbox(ps_data) -> NamedTuple{(:llx,:lly,:urx,:ury), NTuple{4,Float64}}

Compute the high-resolution bounding box of a PostScript document using the
Ghostscript `bbox` device via direct `ccall` to `libgs` (the GMT-bundled GS).
No files are written — stderr is captured in-process.

- `ps_data` : file path (`String`) **or** in-memory PS (`String`/`Vector{UInt8}`).
			  File paths are passed directly to GS via `gsapi_run_file`.

Returns `(llx, lly, urx, ury)` in PostScript points (Float64).

```julia
bb = psbbox("figure.ps")
bb = psbbox(read("figure.ps"))
@show bb.urx - bb.llx, bb.ury - bb.lly   # width, height in points
```
"""
function psbbox(ps_data::Union{String, AbstractVector{UInt8}})
	is_file = ps_data isa String && ncodeunits(ps_data) <= 4096 && isfile(ps_data)
	_GS_BBOX_BUF[] = UInt8[]
	args = ["gs", "-dQUIET", "-dNOPROMPT", "-dNOSAFER", "-dNOPAUSE", "-sDEVICE=bbox", "-dPSL_no_pagefill",
			"-dMaxBitmap=2147483647", "-dUseFastColor=true"]
	_gs_session(args,
		inst -> begin
			exit_code = Ref{Cint}(0)
			if is_file
				rc = gsapi_run_file(inst, ps_data, Cint(0), exit_code)
				rc < 0 && error("gsapi_run_file failed: $rc\n$(String(_GS_BBOX_BUF[]))")
			else
				_gs_run_ps_str(inst, ps_data, () -> String(_GS_BBOX_BUF[]))
			end
		end;
		setup = inst -> begin
			rc = gsapi_set_stdio(inst, C_NULL, C_NULL, @cfunction(_gs_bbox_stderr_cb, Cint, (Ptr{Cvoid}, Ptr{Cchar}, Cint)))
			rc < 0 && error("gsapi_set_stdio failed: $rc")
		end)
	output = String(_GS_BBOX_BUF[])
	m = match(r"%%HiResBoundingBox:\s+([\d.eE+\-]+)\s+([\d.eE+\-]+)\s+([\d.eE+\-]+)\s+([\d.eE+\-]+)", output)
	if (m === nothing)
		m = match(r"%%BoundingBox:\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)", output)
		(m === nothing) && error("No BoundingBox in GS output.\nGS stderr:\n$output")
	end
	llx, lly, urx, ury = parse.(Float64, m.captures)
	(llx=llx, lly=lly, urx=urx, ury=ury)
end

# ── Win32 viewer (Windows only) ───────────────────────────────────────────────
# Equivalent to `gswin64c file.ps`: GS rasterizes via display device callbacks,
# we paint the result to a native window with SetDIBitsToDevice.

@static if Sys.iswindows()

# Windows structs — must match C layout exactly on 64-bit.

struct _BITMAPINFOHEADER          # 40 bytes
	biSize          :: UInt32
	biWidth         :: Int32
	biHeight        :: Int32      # negative = top-down DIB
	biPlanes        :: UInt16
	biBitCount      :: UInt16
	biCompression   :: UInt32
	biSizeImage     :: UInt32
	biXPelsPerMeter :: Int32
	biYPelsPerMeter :: Int32
	biClrUsed       :: UInt32
	biClrImportant  :: UInt32
end

struct _PAINTSTRUCT               # 68 bytes on 64-bit
	hdc        :: Ptr{Cvoid}      # offset  0, size 8
	fErase     :: Int32           # offset  8, size 4
	rcLeft     :: Int32           # offset 12
	rcTop      :: Int32           # offset 16
	rcRight    :: Int32           # offset 20
	rcBottom   :: Int32           # offset 24
	fRestore   :: Int32           # offset 28
	fIncUpdate :: Int32           # offset 32
	reserved   :: NTuple{32,UInt8}# offset 36, size 32
end

struct _WNDCLASSEXW               # 80 bytes on 64-bit
	cbSize        :: UInt32
	style         :: UInt32
	lpfnWndProc   :: Ptr{Cvoid}
	cbClsExtra    :: Int32
	cbWndExtra    :: Int32
	hInstance     :: Ptr{Cvoid}
	hIcon         :: Ptr{Cvoid}
	hCursor       :: Ptr{Cvoid}
	hbrBackground :: Ptr{Cvoid}
	lpszMenuName  :: Ptr{Cwchar_t}
	lpszClassName :: Ptr{Cwchar_t}
	hIconSm       :: Ptr{Cvoid}
end

# GS gives RGB; Windows DIB expects BGR, rows 4-byte aligned.
function _gs_make_bgr_dib(W::Int, H::Int, raster::Int, src::Vector{UInt8})
	stride = (W * 3 + 3) ÷ 4 * 4
	buf    = Vector{UInt8}(undef, stride * H)
	for row in 0:H-1, col in 0:W-1
		s = row * raster + col * 3
		d = row * stride + col * 3
		buf[d+1] = src[s+3]   # B ← R
		buf[d+2] = src[s+2]   # G
		buf[d+3] = src[s+1]   # R ← B
	end
	buf
end

# Shared BGR buffer — filled after GS runs, read by WM_PAINT.
isdefined(@__MODULE__, :_GS_BGR)      || const _GS_BGR      = Ref(UInt8[])
isdefined(@__MODULE__, :_GS_SCROLL_X) || const _GS_SCROLL_X = Ref{Int32}(Int32(0))
isdefined(@__MODULE__, :_GS_SCROLL_Y) || const _GS_SCROLL_Y = Ref{Int32}(Int32(0))
isdefined(@__MODULE__, :_GS_CLIENT_W) || const _GS_CLIENT_W = Ref{Int32}(Int32(0))
isdefined(@__MODULE__, :_GS_CLIENT_H) || const _GS_CLIENT_H = Ref{Int32}(Int32(0))
isdefined(@__MODULE__, :_GS_ZOOM)     || const _GS_ZOOM     = Ref{Float64}(1.0)

struct _SCROLLINFO   # 28 bytes
	cbSize    :: UInt32
	fMask     :: UInt32
	nMin      :: Int32
	nMax      :: Int32
	nPage     :: UInt32
	nPos      :: Int32
	nTrackPos :: Int32
end

function _gs_resize_to_zoom(hwnd::Ptr{Cvoid})
	zoom   = _GS_ZOOM[]
	new_cw = round(Int, _GS_STATE.width  * zoom)
	new_ch = round(Int, _GS_STATE.height * zoom)
	# Non-client area (title bar + borders + scrollbars)
	wrect = zeros(Int32, 4);  crect = zeros(Int32, 4)
	GC.@preserve wrect crect begin
		ccall((:GetWindowRect, "user32"), Bool, (Ptr{Cvoid}, Ptr{Int32}), hwnd, pointer(wrect))
		ccall((:GetClientRect, "user32"), Bool, (Ptr{Cvoid}, Ptr{Int32}), hwnd, pointer(crect))
	end
	nc_w = (wrect[3] - wrect[1]) - crect[3]
	nc_h = (wrect[4] - wrect[2]) - crect[4]
	# Clamp to work area (excludes taskbar)
	workrect = zeros(Int32, 4)
	GC.@preserve workrect begin
		ccall((:SystemParametersInfoW, "user32"), Bool,
			  (UInt32, UInt32, Ptr{Int32}, UInt32),
			  UInt32(0x0030), UInt32(0), pointer(workrect), UInt32(0))
	end
	wa_x = Int(workrect[1]);  wa_y = Int(workrect[2])
	wa_w = Int(workrect[3]) - wa_x
	wa_h = Int(workrect[4]) - wa_y
	new_ww = min(new_cw + nc_w, wa_w)
	new_wh = min(new_ch + nc_h, wa_h)
	new_wx = wa_x + max(0, (wa_w - new_ww) ÷ 2)   # re-center horizontally
	new_wy = wa_y                                    # keep at top of work area
	ccall((:SetWindowPos, "user32"), Bool,
		  (Ptr{Cvoid}, Ptr{Cvoid}, Cint, Cint, Cint, Cint, UInt32),
		  hwnd, C_NULL, Cint(new_wx), Cint(new_wy), Cint(new_ww), Cint(new_wh),
		  UInt32(0x0014))   # SWP_NOZORDER|SWP_NOACTIVATE (no NOMOVE)
end

function _gs_update_scroll_ranges(hwnd::Ptr{Cvoid})
	zoom = _GS_ZOOM[]
	W  = _GS_STATE.width;   H  = _GS_STATE.height
	zW = round(Int, W*zoom); zH = round(Int, H*zoom)
	cw = Int(_GS_CLIENT_W[]); ch = Int(_GS_CLIENT_H[])
	sv = Ref(_SCROLLINFO(UInt32(28), UInt32(0x0003), Int32(0), Int32(max(0,zH-1)), UInt32(ch), Int32(0), Int32(0)))
	sh = Ref(_SCROLLINFO(UInt32(28), UInt32(0x0003), Int32(0), Int32(max(0,zW-1)), UInt32(cw), Int32(0), Int32(0)))
	ccall((:SetScrollInfo, "user32"), Cint, (Ptr{Cvoid}, Cint, Ref{_SCROLLINFO}, Bool), hwnd, Cint(1), sv, true)
	ccall((:SetScrollInfo, "user32"), Cint, (Ptr{Cvoid}, Cint, Ref{_SCROLLINFO}, Bool), hwnd, Cint(0), sh, true)
end

function _gs_set_hscroll(hwnd::Ptr{Cvoid}, pos::Int)
	zW  = round(Int, _GS_STATE.width * _GS_ZOOM[])
	pos = clamp(pos, 0, max(0, zW - Int(_GS_CLIENT_W[])))
	_GS_SCROLL_X[] = Int32(pos)
	si = Ref(_SCROLLINFO(UInt32(28), UInt32(0x0004), Int32(0), Int32(0), UInt32(0), Int32(pos), Int32(0)))
	ccall((:SetScrollInfo, "user32"), Cint, (Ptr{Cvoid}, Cint, Ref{_SCROLLINFO}, Bool), hwnd, Cint(0), si, true)
	ccall((:InvalidateRect, "user32"), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Bool), hwnd, C_NULL, false)
end

function _gs_set_vscroll(hwnd::Ptr{Cvoid}, pos::Int)
	zH  = round(Int, _GS_STATE.height * _GS_ZOOM[])
	pos = clamp(pos, 0, max(0, zH - Int(_GS_CLIENT_H[])))
	_GS_SCROLL_Y[] = Int32(pos)
	si = Ref(_SCROLLINFO(UInt32(28), UInt32(0x0004), Int32(0), Int32(0), UInt32(0), Int32(pos), Int32(0)))
	ccall((:SetScrollInfo, "user32"), Cint, (Ptr{Cvoid}, Cint, Ref{_SCROLLINFO}, Bool), hwnd, Cint(1), si, true)
	ccall((:InvalidateRect, "user32"), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Bool), hwnd, C_NULL, false)
end

function _gs_paint_to_dc(hdc::Ptr{Cvoid}, xoff::Int=0, yoff::Int=0)
	_GS_STATE.ready && !isempty(_GS_BGR[]) || return
	W    = _GS_STATE.width;  H = _GS_STATE.height
	zoom = _GS_ZOOM[]
	zW   = round(Int, W * zoom);  zH = round(Int, H * zoom)
	bmi  = _BITMAPINFOHEADER(40, Int32(W), Int32(-H), 1, 24, 0, 0, 0, 0, 0, 0)
	r    = Ref(bmi)
	bgr  = _GS_BGR[]
	ccall((:SetStretchBltMode, "gdi32"), Cint, (Ptr{Cvoid}, Cint), hdc, Cint(4))  # HALFTONE
	GC.@preserve r bgr begin
		ccall((:StretchDIBits, "gdi32"), Cint,
			  (Ptr{Cvoid}, Cint, Cint, Cint, Cint, Cint, Cint, Cint, Cint,
			   Ptr{UInt8}, Ptr{_BITMAPINFOHEADER}, UInt32, UInt32),
			  hdc, Cint(-xoff), Cint(-yoff), Cint(zW), Cint(zH),
			  Cint(0), Cint(0), Cint(W), Cint(H),
			  pointer(bgr), r, UInt32(0), UInt32(0x00CC0020))  # DIB_RGB_COLORS, SRCCOPY
	end
end

function _gs_wndproc(hwnd::Ptr{Cvoid}, msg::UInt32, wp::UInt64, lp::Int64)::Int64
	if msg == 0x000F            # WM_PAINT
		ps = zeros(UInt8, 68)
		GC.@preserve ps begin
			hdc = ccall((:BeginPaint, "user32"), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{UInt8}), hwnd, pointer(ps))
			_gs_paint_to_dc(hdc, Int(_GS_SCROLL_X[]), Int(_GS_SCROLL_Y[]))
			ccall((:EndPaint, "user32"), Bool, (Ptr{Cvoid}, Ptr{UInt8}), hwnd, pointer(ps))
		end
		return Int64(0)

	elseif msg == 0x0005        # WM_SIZE
		_GS_CLIENT_W[] = Int32(lp & 0xFFFF)
		_GS_CLIENT_H[] = Int32((lp >> 16) & 0xFFFF)
		_gs_update_scroll_ranges(hwnd)
		_gs_set_vscroll(hwnd, Int(_GS_SCROLL_Y[]))
		_gs_set_hscroll(hwnd, Int(_GS_SCROLL_X[]))
		ccall((:InvalidateRect, "user32"), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Bool), hwnd, C_NULL, false)
		return Int64(0)

	elseif msg == 0x0114        # WM_HSCROLL
		code = UInt32(wp & 0xFFFF)
		cw   = Int(_GS_CLIENT_W[])
		pos  = Int(_GS_SCROLL_X[])
		pos  = if     code == 0; pos - 20
			   elseif code == 1; pos + 20
			   elseif code == 2; pos - cw
			   elseif code == 3; pos + cw
			   elseif code == 4 || code == 5
				   Int(reinterpret(Int16, UInt16((wp >> 16) & 0xFFFF)))
			   else pos end
		_gs_set_hscroll(hwnd, pos)
		ccall((:InvalidateRect, "user32"), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Bool), hwnd, C_NULL, false)
		return Int64(0)

	elseif msg == 0x0115        # WM_VSCROLL
		code = UInt32(wp & 0xFFFF)
		ch   = Int(_GS_CLIENT_H[])
		pos  = Int(_GS_SCROLL_Y[])
		pos  = if     code == 0; pos - 20                        # SB_LINEUP
			   elseif code == 1; pos + 20                        # SB_LINEDOWN
			   elseif code == 2; pos - ch                        # SB_PAGEUP
			   elseif code == 3; pos + ch                        # SB_PAGEDOWN
			   elseif code == 4 || code == 5                     # SB_THUMB*
				   Int(reinterpret(Int16, UInt16((wp >> 16) & 0xFFFF)))
			   else pos end
		_gs_set_vscroll(hwnd, pos)
		ccall((:InvalidateRect, "user32"), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Bool), hwnd, C_NULL, false)
		return Int64(0)

	elseif msg == 0x020A        # WM_MOUSEWHEEL
		delta    = reinterpret(Int16, UInt16((wp >> 16) & 0xFFFF))
		keystate = UInt32(wp & 0xFFFF)
		if keystate & 0x0008 != 0   # MK_CONTROL — zoom toward cursor
			old_zoom = _GS_ZOOM[]
			factor   = delta > 0 ? 1.25 : 1.0/1.25
			new_zoom = clamp(old_zoom * factor, 0.05, 20.0)
			_GS_ZOOM[] = new_zoom
			# cursor in screen coords from lParam; convert to client coords
			pt = [Int32(reinterpret(Int16, UInt16(lp & 0xFFFF))),
				  Int32(reinterpret(Int16, UInt16((lp >> 16) & 0xFFFF)))]
			GC.@preserve pt begin
				ccall((:ScreenToClient, "user32"), Bool, (Ptr{Cvoid}, Ptr{Int32}), hwnd, pointer(pt))
			end
			cx, cy = Int(pt[1]), Int(pt[2])
			# keep image point under cursor fixed
			new_sx = round(Int, (Int(_GS_SCROLL_X[]) + cx) / old_zoom * new_zoom - cx)
			new_sy = round(Int, (Int(_GS_SCROLL_Y[]) + cy) / old_zoom * new_zoom - cy)
			# pre-set scroll positions; WM_SIZE fired by SetWindowPos will clamp + update scrollbars
			_GS_SCROLL_X[] = Int32(new_sx)
			_GS_SCROLL_Y[] = Int32(new_sy)
			_gs_resize_to_zoom(hwnd)
		elseif keystate & 0x0004 != 0   # MK_SHIFT — horizontal scroll
			_gs_set_hscroll(hwnd, Int(_GS_SCROLL_X[]) - Int(delta) * 40 ÷ 120)
			ccall((:InvalidateRect, "user32"), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Bool), hwnd, C_NULL, false)
		else                            # plain wheel — scroll vertically
			_gs_set_vscroll(hwnd, Int(_GS_SCROLL_Y[]) - Int(delta) * 40 ÷ 120)
			ccall((:InvalidateRect, "user32"), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Bool), hwnd, C_NULL, false)
		end
		return Int64(0)

	elseif msg == 0x020E        # WM_MOUSEHSCROLL — trackpad horizontal swipe
		delta = reinterpret(Int16, UInt16((wp >> 16) & 0xFFFF))
		_gs_set_hscroll(hwnd, Int(_GS_SCROLL_X[]) + Int(delta) * 40 ÷ 120)
		ccall((:InvalidateRect, "user32"), Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Bool), hwnd, C_NULL, false)
		return Int64(0)

	elseif msg == 0x0002        # WM_DESTROY
		ccall((:PostQuitMessage, "user32"), Cvoid, (Cint,), 0)
		return Int64(0)

	elseif msg == 0x0100 && wp == 0x1B   # WM_KEYDOWN + VK_ESCAPE
		ccall((:DestroyWindow, "user32"), Bool, (Ptr{Cvoid},), hwnd)
		return Int64(0)
	end
	ccall((:DefWindowProcW, "user32"), Int64, (Ptr{Cvoid}, UInt32, UInt64, Int64), hwnd, msg, wp, lp)
end

# ----------------------------------------------------------------------------------------
"""
	psview(ps_data; dpi=300)

Display PostScript in a native Win32 window — equivalent to `gswin64c file.ps`.
GS rasterizes via display device; pixels are painted with `SetDIBitsToDevice`.
Close the window or press Escape to exit.
"""
psview(ps_data::GMTps; dpi::Int=300) = psview(ps_data.postscript; dpi=dpi)
function psview(ps_data::Union{String, AbstractVector{UInt8}}; dpi::Int=300)
	_gs_state_reset!()
	cb_ref = _gs_make_callback_ref()
	args = ["gs", "-dNOPAUSE", "-dNOPROMPT", "-dQUIET", "-dSCANCONVERTERTYPE=2",
	        "-dUseFastColor=true", "-dGraphicsAlphaBits=4", "-dTextAlphaBits=4",
	        "-sDEVICE=display", "-dDisplayFormat=$(_GS_FMT_RGB24)", "-r$(dpi)"]
	_gs_session(args, inst -> _gs_run_ps_str(inst, ps_data, () -> ""); display_cb=cb_ref)
	_GS_STATE.ready || error("Ghostscript produced no output.")
	_GS_BGR[] = _gs_make_bgr_dib(_GS_STATE.width, _GS_STATE.height, _GS_STATE.raster, _GS_STATE.data)

	# ── Create Win32 window ───────────────────────────────────────────────────
	_GS_SCROLL_X[] = Int32(0);  _GS_SCROLL_Y[] = Int32(0)
	_GS_CLIENT_W[] = Int32(0);  _GS_CLIENT_H[] = Int32(0)
	W = _GS_STATE.width;  H = _GS_STATE.height

	# Work area = screen minus taskbar/docks (SPI_GETWORKAREA = 0x0030)
	# Returns RECT {left, top, right, bottom} as four Int32.
	workrect = zeros(Int32, 4)
	GC.@preserve workrect begin
		ccall((:SystemParametersInfoW, "user32"), Bool,
			  (UInt32, UInt32, Ptr{Int32}, UInt32),
			  UInt32(0x0030), UInt32(0), pointer(workrect), UInt32(0))
	end
	wa_x = Int(workrect[1]);  wa_y = Int(workrect[2])
	wa_w = Int(workrect[3]) - wa_x
	wa_h = Int(workrect[4]) - wa_y

	# Non-client chrome: title bar + borders
	nc_w = Int(ccall((:GetSystemMetrics, "user32"), Cint, (Cint,), Cint(2))) * 2   # SM_CXSIZEFRAME
	nc_h = Int(ccall((:GetSystemMetrics, "user32"), Cint, (Cint,), Cint(4))) * 2 + # SM_CYSIZEFRAME
		   Int(ccall((:GetSystemMetrics, "user32"), Cint, (Cint,), Cint(31)))       # SM_CYCAPTION

	# Initial zoom: fit image in work area
	zoom_fit = min((wa_w - nc_w) / W, (wa_h - nc_h) / H, 1.0)
	_GS_ZOOM[] = max(zoom_fit, 0.05)

	win_w = round(Int, W * _GS_ZOOM[]) + nc_w
	win_h = round(Int, H * _GS_ZOOM[]) + nc_h
	win_x = wa_x + max(0, (wa_w - win_w) ÷ 2)  # centered in work area
	win_y = wa_y                                  # top of work area (below menu bar on Mac)

	hmod      = ccall((:GetModuleHandleW, "kernel32"), Ptr{Cvoid}, (Ptr{Cwchar_t},), C_NULL)
	classname = transcode(UInt16, "GhostscriptViewer\0")
	wndtitle  = transcode(UInt16, "Ghostscript Viewer  [Esc to close]\0")
	cursor    = ccall((:LoadCursorW, "user32"), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cwchar_t}), C_NULL, Ptr{Cwchar_t}(32512))

	wc_ref = Ref(_WNDCLASSEXW(
		UInt32(sizeof(_WNDCLASSEXW)), UInt32(3),   # CS_HREDRAW|CS_VREDRAW
		@cfunction(_gs_wndproc, Int64, (Ptr{Cvoid}, UInt32, UInt64, Int64)),
		Int32(0), Int32(0), hmod,
		C_NULL, cursor, Ptr{Cvoid}(6),             # COLOR_WINDOW+1 for background
		C_NULL, pointer(classname), C_NULL))

	GC.@preserve classname wndtitle wc_ref begin
		ccall((:RegisterClassExW, "user32"), UInt16, (Ptr{_WNDCLASSEXW},), wc_ref)

		hwnd = ccall((:CreateWindowExW, "user32"), Ptr{Cvoid},
					 (UInt32, Ptr{Cwchar_t}, Ptr{Cwchar_t}, UInt32, Cint, Cint, Cint, Cint,
					  Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
					 UInt32(0),
					 pointer(classname), pointer(wndtitle),
					 UInt32(0x10FF0000),             # WS_OVERLAPPEDWINDOW | WS_VISIBLE | WS_VSCROLL | WS_HSCROLL
					 Cint(win_x), Cint(win_y), Cint(win_w), Cint(win_h),
					 C_NULL, C_NULL, hmod, C_NULL)
		hwnd == C_NULL && error("CreateWindowExW failed")
		ccall((:UpdateWindow, "user32"), Bool, (Ptr{Cvoid},), hwnd)

		# Message loop — blocks until window closed
		msg = zeros(UInt8, 48)   # MSG struct is 48 bytes on Windows 64-bit
		while ccall((:GetMessageW, "user32"), Int32, (Ptr{UInt8}, Ptr{Cvoid}, UInt32, UInt32), msg, C_NULL, 0, 0) > 0
			ccall((:TranslateMessage, "user32"), Bool, (Ptr{UInt8},), msg)
			ccall((:DispatchMessageW, "user32"), Int64, (Ptr{UInt8},), msg)
		end
	end
	nothing
end

end  # @static if Sys.iswindows()

@static if !Sys.iswindows()
"""
	psview(ps_data; dpi=300)

Display PostScript using Ghostscript's native window (x11 on Linux, aqua on macOS).
Blocks until the viewer window is closed.
"""
function psview(ps_data::Union{String, AbstractVector{UInt8}}; dpi::Int=300)
	device = Sys.islinux() ? "x11" : "aqua"
	args = ["gs", "-dNOPAUSE", "-dQUIET", "-sDEVICE=$(device)", "-r$(dpi)"]
	_gs_session(args, inst -> begin
		_gs_run_ps_str(inst, ps_data, () -> "")
		exit_code = Ref{Cint}(0)
		rc = 0
		while rc >= 0
			rc = gsapi_run_string_with_length(inst, "\n", Cuint(1), Cint(0), exit_code)
			sleep(0.05)
		end
	end)
	nothing
end
end  # @static if !Sys.iswindows()
