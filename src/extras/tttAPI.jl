"""
    tttAPI.jl - Tsunami Travel Time API (Julia port)

    Original C code by Paul Wessel, Geoware, 2005-2018 (v4.0.1)
    Julia conversion with deobfuscated variable/function names.

    Computes tsunami travel times from epicenters using the shallow-water
    wave approximation: velocity = sqrt(depth * gravity).
    Uses a Huygens wavefront construction with up to 120 stencil nodes
    and a BST-based priority queue (Dijkstra-like propagation).
"""


# ──────────────────── Constants ────────────────────

const TTT_VERSION = "4.0.1 [Julia]"
const TTT_PAD = 13                          # Grid padding
const TTT_MAX_NODES = 120                   # Maximum Huygens stencil nodes
const N_STENCIL_TOTAL = 256             # Total stencil points (including auxiliary)
const N_DEP_SETS = 8                    # Number of dependency bitmask sets
const SEARCH_S_RADIUS = 1.12415         # Default station search radius (degrees)

const TTT_EARTH_RADIUS = 6371007.181        # meters
const DEG_TO_M = 2π * TTT_EARTH_RADIUS / 360.0   # meters per degree
const DEG_TO_KM = 0.001 * DEG_TO_M           # km per degree
# NOTE: D2R is defined once for the whole module in extras/wave_travel_time.jl
const R2D = 180.0 / π                   # radians to degrees
const TTT_EPS = 1.0e-8                      # Small epsilon for floating-point comparisons

# Gravity formula constants (Somigliana/WGS84-like)
const GRAV_A = 9.7803267715
const GRAV_B = 0.0052790414
const GRAV_C = 0.0000232718

# Sentinel values for travel time tracking array (matching C: h733636, c748660, i634697)
const EXCLUDED_TT = 1.0e35     # Padding/land/NaN nodes (permanently excluded)
const SETTLED_TT  = 1.0e34     # Node already settled (BST removed)
const UNSEEN_TT   = 1.0e33     # Node not yet reached by wavefront

# ──────────────────── Error codes ────────────────────

@enum TTTError begin
    TTT_SUCCESS = 0
    TTT_ERROR_WESN_CHECK = 2
    TTT_ERROR_INC_CHECK = 3
    TTT_ERROR_DIM_CHECK = 4
    TTT_ERROR_SOURCE_LAND = 5
    TTT_ERROR_SOURCE_OUTSIDE = 6
    TTT_ERROR_SOURCE_BAD_SEARCH = 7
    TTT_ERROR_BAD_VERBOSITY = 8
    TTT_ERROR_BAD_NODES = 9
    TTT_ERROR_BAD_RADIUS = 10
    TTT_ERROR_BAD_DEPTH = 11
    TTT_ERROR_STATION_OUTSIDE = 27
    TTT_ERROR_BAD_MINDEPTH = 30
    TTT_ERROR_NO_SOURCE = 32
end

# ──────────────────── Public Structs ────────────────────

"""Information about a station for TTTeta calculation."""
mutable struct TTTeta
    lon::Float64            # Station longitude
    lat::Float64            # Station latitude
    lon2::Float64           # Shifted longitude (depth search)
    lat2::Float64           # Shifted latitude (depth search)
    depth::Float64          # Depth at station
    ttt::Float64            # Travel time in hours
    dist::Float64           # Distance to nearest travel-time node (km)
    slope::Float64          # Steepest gradient at node (sec/km)
    text::String            # Station name/description
    TTTeta() = new(0.0, 0.0, 0.0, 0.0, 0.0, NaN, 0.0, 0.0, "")
end

"""Information about the earthquake."""
mutable struct TTTquake
    lon::Vector{Float64}    # Epicenter longitude(s)
    lat::Vector{Float64}    # Epicenter latitude(s)
    ttt_slope::Float64      # Steepest gradient at quake (sec/km)
    origin::DateTime        # Origin time
    utc::Bool               # true if UTC time
    n_sources::Int          # Number of source points
    TTTquake() = new(Float64[], Float64[], 0.0, DateTime(0), false, 0)
end

# ──────────────────── Internal Structs ────────────────────

"""GMT-style grid header (binary format)."""
mutable struct TTThdr
    nx::Int32               # Number of columns
    ny::Int32               # Number of rows
    pixel_reg::Int32        # 0=gridline, 1=pixel registration
    xy_off::Float64         # 0.5 for pixel, 0.0 for gridline
    is_global::Bool         # True if grid spans 360 degrees
    has_north_pole::Bool    # True if grid reaches North Pole
    has_south_pole::Bool    # True if grid reaches South Pole
    west::Float64
    east::Float64
    south::Float64
    north::Float64
    zmin::Float64
    zmax::Float64
    dx::Float64             # Grid spacing in x
    dy::Float64             # Grid spacing in y
    z_scale::Float64
    z_offset::Float64
    x_unit::String
    y_unit::String
    z_unit::String
    title::String
    command::String
    remark::String
    TTThdr() = new(0, 0, 0, 0.0, false, false, false, 0.0, 0.0, 0.0, 0.0,
                       Inf, -Inf, 0.0, 0.0, 1.0, 0.0, "", "", "", "", "", "")
end

"""BST node for the priority queue."""
mutable struct BSTNode
    travel_time::Float64    # Key: travel time value
    grid_index::Int         # Grid node linear index (1-based)
    left::Union{BSTNode, Nothing}
    right::Union{BSTNode, Nothing}
end

"""Distance arrays for Huygens stencil at each row."""
struct DistanceArrays
    dx_half::Vector{Float64}          # Half-cell distance in x at each row
    dy_half::Float64                  # Half-cell distance in y (constant)
    diag_1_1::Vector{Float64}         # hypot(dx_half, dy_half)
    # Node-pair distances for 16-node stencil
    diag_05_1::Vector{Float64}        # hypot(0.5*dx_half, dy_half)
    diag_1_05::Vector{Float64}        # hypot(dx_half, 0.5*dy_half)
    # 32-node stencil
    diag_13_1::Vector{Float64}        # hypot(1/3*dx, dy)
    diag_1_13::Vector{Float64}        # hypot(dx, 1/3*dy)
    diag_23_1::Vector{Float64}        # hypot(2/3*dx, dy)
    diag_1_23::Vector{Float64}        # hypot(dx, 2/3*dy)
    # 48-node stencil
    diag_025_1::Vector{Float64}       # hypot(0.25*dx, dy)
    diag_1_025::Vector{Float64}       # hypot(dx, 0.25*dy)
    diag_075_1::Vector{Float64}       # hypot(0.75*dx, dy)
    diag_1_075::Vector{Float64}       # hypot(dx, 0.75*dy)
    # 64-node stencil
    diag_02_1::Vector{Float64}        # hypot(0.2*dx, dy)
    diag_1_02::Vector{Float64}        # hypot(dx, 0.2*dy)
    diag_04_1::Vector{Float64}        # hypot(0.4*dx, dy)
    diag_1_04::Vector{Float64}        # hypot(dx, 0.4*dy)
    # 120-node stencil (additional)
    diag_06_1::Vector{Float64}
    diag_1_06::Vector{Float64}
    diag_16_1::Vector{Float64}        # hypot(1/6*dx, dy)
    diag_1_16::Vector{Float64}        # hypot(dx, 1/6*dy)
    diag_08_1::Vector{Float64}
    diag_1_08::Vector{Float64}
    diag_37_1::Vector{Float64}        # hypot(3/7*dx, dy)
    diag_1_37::Vector{Float64}        # hypot(dx, 3/7*dy)
    diag_0125_1::Vector{Float64}
    diag_1_0125::Vector{Float64}
    diag_67_1::Vector{Float64}        # hypot(6/7*dx, dy)
    diag_1_67::Vector{Float64}        # hypot(dx, 6/7*dy)
    diag_113_1::Vector{Float64}       # hypot(1/13*dx, dy)
    diag_1_113::Vector{Float64}       # hypot(dx, 1/13*dy)
end

"""Main TTT control structure."""
mutable struct TTTState
    normalize::Bool         # Apply bias correction
    n_nodes::Int            # Number of Huygens nodes (8/16/32/48/64/120)
    n_stencil_used::Int     # Actual stencil points used
    registration::Int       # 0 = gridline, 1 = pixel
    verbose::Int            # Verbosity level
    do_search::Bool         # Search for water node if source on land
    mx::Int                 # Padded grid width
    my::Int                 # Padded grid height
    mxy::Int                # Total padded grid size
    dim_prime::Int          # Prime dimension for I/O ordering
    source_indices::Vector{Int}   # Padded grid indices of sources (1-based)
    n_sources::Int
    slowness::Vector{Float32}     # Slowness grid (padded)
    source_depth::Float64         # Source must be at least this deep
    search_radius::Float64        # Search radius for source relocation
    ttt_slope::Float64            # Travel time gradient at source
    source_bathy::Vector{Float64} # Depth at each source
    source_dist::Vector{Float64}  # Distance source was moved
    depth_threshold::Float64      # Minimum water depth ramp
    header::TTThdr
    dep_masks::Array{UInt32, 2}   # Dependency bitmasks [N_DEP_SETS, TTT_MAX_NODES]
    TTTState() = new(true, 120, 0, 0, 0, false, 0, 0, 0, 0,
                     Int[], 0, Float32[], 0.0, 0.0, 0.0,
                     Float64[], Float64[], 0.0, TTThdr(),
                     zeros(UInt32, N_DEP_SETS, TTT_MAX_NODES))
end

# ──────────────────── Utility Functions ────────────────────

"""Convert x coordinate to column index (0-based)."""
@inline function lon_to_col(x, x0, dx, off, nx)
    return round(Int, (x - x0) / dx - off)
end

"""Convert y coordinate to row index (0-based, top-to-bottom)."""
@inline function lat_to_row(y, y0, dy, off, ny)
    return ny - 1 - round(Int, (y - y0) / dy - off)
end

"""Convert column index to x coordinate."""
@inline function col_to_lon(i, x0, x1, dx, off, nx)
    return (i == nx - 1) ? x1 - off * dx : x0 + (i + off) * dx
end

"""Convert row index to y coordinate."""
@inline function row_to_lat(j, y0, y1, dy, off, ny)
    return (j == ny - 1) ? y0 + off * dy : y1 - (j + off) * dy
end

"""Compute 1-based padded grid index from (i,j) 0-based coordinates."""
@inline function padded_index(i, j, mx, pad)
    return (j + pad) * mx + (i + pad) + 1   # +1 for Julia 1-based
end

"""Compute bitmask for a stencil node index."""
@inline function bitmask(node_idx)
    return UInt32(1) << (node_idx % 32)
end

"""Spherical distance between two points in degrees."""
function spherical_distance(lon1, lat1, lon2, lat2)
    if lat1 == lat2 && lon1 == lon2
        return 0.0
    end
    a = D2R * (90.0 - lat2)
    b = D2R * (90.0 - lat1)
    C = D2R * (lon2 - lon1)
    sina = sin(a); cosa = cos(a)
    sinb = sin(b); cosb = cos(b)
    cosC = cos(C)
    cosc = cosa * cosb + sina * sinb * cosC
    c = cosc < -1.0 ? π : (cosc > 1.0 ? 0.0 : acos(cosc))
    return c * R2D
end

"""Latitude-dependent normal gravity (Somigliana formula)."""
function normal_gravity(lat)
    s = sin(lat * D2R)
    s2 = s * s
    return GRAV_A * (1.0 + GRAV_B * s2 + GRAV_C * s2 * s2)
end

"""Compute travel time gradient (slope) at a point in sec/km."""
function compute_slope(h::TTThdr, dims, tt, col, row)
    search_r = min(0.25, 2.0 * h.dx)
    y0 = row_to_lat(row, h.south, h.north, h.dy, h.xy_off, h.ny)
    x0 = col_to_lon(col, h.west, h.east, h.dx, h.xy_off, h.nx)
    dx_deg = h.dx * cos(y0 * D2R)
    i_lo = max(0, col - ceil(Int, search_r / dx_deg))
    i_hi = min(h.nx - 1, col + ceil(Int, search_r / dx_deg))
    j_lo = max(0, row - ceil(Int, search_r / h.dy))
    j_hi = min(h.ny - 1, row + ceil(Int, search_r / h.dy))
    ij0 = row * dims + col + 1
    t0 = tt[ij0]
    sr = 0.0; st = 0.0
    for j in j_lo:j_hi
        y = row_to_lat(j, h.south, h.north, h.dy, h.xy_off, h.ny)
        for i in i_lo:i_hi
            ij = j * dims + i + 1
            isnan(tt[ij]) && continue
            x = col_to_lon(i, h.west, h.east, h.dx, h.xy_off, h.nx)
            d = spherical_distance(x0, y0, x, y)
            d > search_r && continue
            sr += d
            st += abs(tt[ij] - t0)
        end
    end
    return sr > 0.0 ? 3600.0 * (st / sr) * (R2D / (0.001 * TTT_EARTH_RADIUS)) : 0.0
end

# ──────────────────── BST Priority Queue ────────────────────

mutable struct BSTPriorityQueue
    head::BSTNode       # Sentinel head
    tail::BSTNode       # Sentinel tail (leaf sentinel)
end

function BSTPriorityQueue()
    tail = BSTNode(-1.0, -1, nothing, nothing)
    tail.left = tail; tail.right = tail    # Self-referencing sentinel
    head = BSTNode(-1.0, -1, nothing, tail)
    return BSTPriorityQueue(head, tail)
end

"""Insert a node with given travel_time and grid_index into the BST."""
function bst_insert!(pq::BSTPriorityQueue, tt::Float64, idx::Int)
    p = pq.head
    x = pq.head.right
    tail = pq.tail
    while x !== tail
        p = x
        x = tt < x.travel_time ? x.left : x.right
    end
    node = BSTNode(tt, idx, tail, tail)
    if tt < p.travel_time
        p.left = node
    else
        p.right = node
    end
end

"""Find and return the minimum travel_time and its grid_index (without removing)."""
function bst_find_min(pq::BSTPriorityQueue)
    x = pq.head.right
    tail = pq.tail
    while x.left !== tail
        x = x.left
    end
    return x.travel_time, x.grid_index
end

"""Delete a specific node (tt, idx) from the BST."""
function bst_delete!(pq::BSTPriorityQueue, tt::Float64, idx::Int)
    tail = pq.tail
    tail.travel_time = tt
    tail.grid_index = idx
    p = pq.head
    x = pq.head.right
    # Find the node
    while !(x.travel_time == tt && x.grid_index == idx)
        p = x
        x = tt < x.travel_time ? x.left : x.right
    end
    t = x  # Node to delete
    if t.right === tail
        x = x.left
    elseif t.right.left === tail
        x = x.right
        x.left = t.left
    else
        c = x.right
        while c.left.left !== tail
            c = c.left
        end
        x = c.left
        c.left = x.right
        x.left = t.left
        x.right = t.right
    end
    if tt < p.travel_time
        p.left = x
    else
        p.right = x
    end
end

"""Check if BST is empty (only sentinels remain)."""
@inline function bst_isempty(pq::BSTPriorityQueue)
    return pq.head.right === pq.tail
end

# ──────────────────── Stencil Node Offsets ────────────────────
# These are the (di, dj) offsets for each of the 256 stencil positions.
# di = column offset, dj = row offset (positive = up in grid)

const STENCIL_DI = Int[
    1, -1, 0, 0, 1, -1, 1, -1,                           # 0-7 (8 nodes)
    2, -2, 2, -2, 1, -1, 1, -1,                           # 8-15 (16 nodes)
    3, -3, 3, -3, 1, -1, 1, -1, 3, -3, 3, -3, 2, -2, 2, -2,  # 16-31 (32 nodes)
    4, -4, 4, -4, 1, -1, 1, -1, 4, -4, 4, -4, 3, -3, 3, -3,  # 32-47 (48 nodes)
    5, -5, 5, -5, 1, -1, 1, -1, 5, -5, 5, -5, 2, -2, 2, -2,  # 48-63 (64 nodes)
    5, -5, 5, -5, 3, -3, 3, -3, 6, -6, 6, -6, 1, -1, 1, -1,  # 64-79
    5, -5, 5, -5, 4, -4, 4, -4, 7, -7, 7, -7, 3, -3, 3, -3,  # 80-95
    8, -8, 8, -8, 1, -1, 1, -1, 7, -7, 7, -7, 6, -6, 6, -6,  # 96-111
    13, -13, 13, -13, 1, -1, 1, -1,                       # 112-119
    # Auxiliary nodes (120-255) used in stencil sum formulas
    2, -2, 0, 0, 2, -2, 2, -2,                            # 120-127
    3, -3, 0, 0, 4, -4, 0, 0,                             # 128-135
    3, -3, 3, -3, 4, -4, 4, -4, 2, -2, 2, -2,             # 136-147
    5, -5, 0, 0, 4, -4, 4, -4,                            # 148-155
    6, -6, 0, 0, 6, -6, 6, -6, 2, -2, 2, -2,             # 156-167
    6, -6, 6, -6, 3, -3, 3, -3, 6, -6, 6, -6,             # 168-175
    7, -7, 0, 0, 5, -5, 5, -5,                            # 176-183
    7, -7, 7, -7, 1, -1, 1, -1, 6, -6, 6, -6, 5, -5, 5, -5, # 184-199
    8, -8, 0, 0, 6, -6, 6, -6,                            # 200-207
    9, -9, 0, 0, 9, -9, 9, -9, 1, -1, 1, -1,             # 208-219
    10, -10, 0, 0, 10, -10, 10, -10, 1, -1, 1, -1,        # 220-231
    11, -11, 0, 0, 11, -11, 11, -11, 1, -1, 1, -1,        # 232-243
    12, -12, 0, 0, 12, -12, 12, -12, 1, -1, 1, -1         # 244-255
]

const STENCIL_DJ = Int[
    0, 0, 1, -1, 1, -1, -1, 1,                           # 0-7
    1, -1, -1, 1, 2, -2, -2, 2,                           # 8-15
    1, -1, -1, 1, 3, -3, -3, 3, 2, -2, -2, 2, 3, -3, -3, 3,  # 16-31
    1, -1, -1, 1, 4, -4, -4, 4, 3, -3, -3, 3, 4, -4, -4, 4,  # 32-47
    1, -1, -1, 1, 5, -5, -5, 5, 2, -2, -2, 2, 5, -5, -5, 5,  # 48-63
    3, -3, -3, 3, 5, -5, -5, 5, 1, -1, -1, 1, 6, -6, -6, 6,  # 64-79
    4, -4, -4, 4, 5, -5, -5, 5, 3, -3, -3, 3, 7, -7, -7, 7,  # 80-95
    1, -1, -1, 1, 8, -8, -8, 8, 6, -6, -6, 6, 7, -7, -7, 7,  # 96-111
    1, -1, -1, 1, 13, -13, -13, 13,                       # 112-119
    # Auxiliary nodes (120-255)
    0, 0, 2, -2, 2, -2, -2, 2,                            # 120-127
    0, 0, 3, -3, 0, 0, 4, -4,                             # 128-135
    3, -3, -3, 3, 2, -2, -2, 2, 4, -4, -4, 4,             # 136-147
    0, 0, 5, -5, 4, -4, -4, 4,                            # 148-155
    0, 0, 6, -6, 2, -2, -2, 2, 6, -6, -6, 6,             # 156-167
    3, -3, -3, 3, 6, -6, -6, 6, 0, 0, 7, -7,             # 168-175
    0, 0, 7, -7, 5, -5, -5, 5,                            # 176-183
    1, -1, -1, 1, 7, -7, -7, 7, 5, -5, -5, 5, 6, -6, -6, 6, # 184-199
    0, 0, 8, -8, 6, -6, -6, 6,                            # 200-207
    0, 0, 9, -9, 1, -1, -1, 1, 9, -9, -9, 9,             # 208-219
    0, 0, 10, -10, 1, -1, -1, 1, 10, -10, -10, 10,        # 220-231
    0, 0, 11, -11, 1, -1, -1, 1, 11, -11, -11, 11,        # 232-243
    0, 0, 12, -12, 1, -1, -1, 1, 12, -12, -12, 12         # 244-255
]

# ──────────────────── Stencil Slowness Sums ────────────────────
# Each Huygens stencil node requires a weighted sum of slowness values
# at the node and its neighbors. The S(k) macro from C becomes s[ij + p[k+1]].
# Here we implement them as functions.

"""
Compute the weighted slowness sum for stencil node `node` at padded index `ij`.
`s` = slowness grid, `p` = stencil offset array (1-based), `ij` = center padded index.
Returns the sum used to compute the travel time increment.
"""
function stencil_sum(s::Vector{Float32}, ij::Int, p::Vector{Int}, node::Int)
    @inline S(k) = s[ij + p[k+1]]  # k is 0-based stencil index, p is 1-based
    sij = s[ij]
    # Node indices 0-7: 8-node stencil (nearest neighbors)
    if node == 0; return sij + S(0)
    elseif node == 1; return sij + S(1)
    elseif node == 2; return sij + S(2)
    elseif node == 3; return sij + S(3)
    elseif node == 4; return sij + S(4)
    elseif node == 5; return sij + S(5)
    elseif node == 6; return sij + S(6)
    elseif node == 7; return sij + S(7)
    # 8-15: 16-node stencil
    elseif node == 8;  return sij + S(0) + S(4) + S(8)
    elseif node == 9;  return sij + S(1) + S(5) + S(9)
    elseif node == 10; return sij + S(0) + S(6) + S(10)
    elseif node == 11; return sij + S(1) + S(7) + S(11)
    elseif node == 12; return sij + S(2) + S(4) + S(12)
    elseif node == 13; return sij + S(3) + S(5) + S(13)
    elseif node == 14; return sij + S(3) + S(6) + S(14)
    elseif node == 15; return sij + S(2) + S(7) + S(15)
    # 16-31: 32-node stencil
    elseif node == 16; return sij + 2/3*(S(120)+S(4)) + 4/3*(S(0)+S(8)) + S(16)
    elseif node == 17; return sij + 2/3*(S(121)+S(5)) + 4/3*(S(1)+S(9)) + S(17)
    elseif node == 18; return sij + 2/3*(S(120)+S(6)) + 4/3*(S(0)+S(10)) + S(18)
    elseif node == 19; return sij + 2/3*(S(121)+S(7)) + 4/3*(S(1)+S(11)) + S(19)
    elseif node == 20; return sij + 2/3*(S(122)+S(4)) + 4/3*(S(2)+S(12)) + S(20)
    elseif node == 21; return sij + 2/3*(S(123)+S(5)) + 4/3*(S(3)+S(13)) + S(21)
    elseif node == 22; return sij + 2/3*(S(123)+S(6)) + 4/3*(S(3)+S(14)) + S(22)
    elseif node == 23; return sij + 2/3*(S(122)+S(7)) + 4/3*(S(2)+S(15)) + S(23)
    elseif node == 24; return sij + 0.5*(S(0)+S(124)) + 1.5*(S(4)+S(8)) + S(24)
    elseif node == 25; return sij + 0.5*(S(1)+S(125)) + 1.5*(S(5)+S(9)) + S(25)
    elseif node == 26; return sij + 0.5*(S(0)+S(126)) + 1.5*(S(6)+S(10)) + S(26)
    elseif node == 27; return sij + 0.5*(S(1)+S(127)) + 1.5*(S(7)+S(11)) + S(27)
    elseif node == 28; return sij + 0.5*(S(2)+S(124)) + 1.5*(S(4)+S(12)) + S(28)
    elseif node == 29; return sij + 0.5*(S(3)+S(125)) + 1.5*(S(5)+S(13)) + S(29)
    elseif node == 30; return sij + 0.5*(S(3)+S(126)) + 1.5*(S(6)+S(14)) + S(30)
    elseif node == 31; return sij + 0.5*(S(2)+S(127)) + 1.5*(S(7)+S(15)) + S(31)
    # 32-47: 48-node stencil
    elseif node == 32; return sij + 0.5*(S(128)+S(4)) + 1.5*(S(0)+S(16)) + S(120) + S(8) + S(32)
    elseif node == 33; return sij + 0.5*(S(129)+S(5)) + 1.5*(S(1)+S(17)) + S(121) + S(9) + S(33)
    elseif node == 34; return sij + 0.5*(S(128)+S(6)) + 1.5*(S(0)+S(18)) + S(120) + S(10) + S(34)
    elseif node == 35; return sij + 0.5*(S(129)+S(7)) + 1.5*(S(1)+S(19)) + S(121) + S(11) + S(35)
    elseif node == 36; return sij + 0.5*(S(130)+S(4)) + 1.5*(S(2)+S(20)) + S(122) + S(12) + S(36)
    elseif node == 37; return sij + 0.5*(S(131)+S(5)) + 1.5*(S(3)+S(21)) + S(123) + S(13) + S(37)
    elseif node == 38; return sij + 0.5*(S(131)+S(6)) + 1.5*(S(3)+S(22)) + S(123) + S(14) + S(38)
    elseif node == 39; return sij + 0.5*(S(130)+S(7)) + 1.5*(S(2)+S(23)) + S(122) + S(15) + S(39)
    elseif node == 40; return sij + 1/3*(S(0)+S(136)) + 5/3*(S(4)+S(24)) + S(8) + S(124) + S(40)
    elseif node == 41; return sij + 1/3*(S(1)+S(137)) + 5/3*(S(5)+S(25)) + S(9) + S(125) + S(41)
    elseif node == 42; return sij + 1/3*(S(0)+S(138)) + 5/3*(S(6)+S(26)) + S(10) + S(126) + S(42)
    elseif node == 43; return sij + 1/3*(S(1)+S(139)) + 5/3*(S(7)+S(27)) + S(11) + S(127) + S(43)
    elseif node == 44; return sij + 1/3*(S(2)+S(136)) + 5/3*(S(4)+S(28)) + S(12) + S(124) + S(44)
    elseif node == 45; return sij + 1/3*(S(3)+S(137)) + 5/3*(S(5)+S(29)) + S(13) + S(125) + S(45)
    elseif node == 46; return sij + 1/3*(S(3)+S(138)) + 5/3*(S(6)+S(30)) + S(14) + S(126) + S(46)
    elseif node == 47; return sij + 1/3*(S(2)+S(139)) + 5/3*(S(7)+S(31)) + S(15) + S(127) + S(47)
    # 48-63: 64-node stencil
    elseif node == 48; return sij + 1.6*(S(0)+S(32)) + 0.4*(S(4)+S(132)) + 0.8*(S(8)+S(128)) + 1.2*(S(16)+S(120)) + S(48)
    elseif node == 49; return sij + 1.6*(S(1)+S(33)) + 0.4*(S(5)+S(133)) + 0.8*(S(9)+S(129)) + 1.2*(S(17)+S(121)) + S(49)
    elseif node == 50; return sij + 1.6*(S(0)+S(34)) + 0.4*(S(6)+S(132)) + 0.8*(S(10)+S(128)) + 1.2*(S(18)+S(120)) + S(50)
    elseif node == 51; return sij + 1.6*(S(1)+S(35)) + 0.4*(S(7)+S(133)) + 0.8*(S(11)+S(129)) + 1.2*(S(19)+S(121)) + S(51)
    elseif node == 52; return sij + 1.6*(S(2)+S(36)) + 0.4*(S(4)+S(134)) + 0.8*(S(12)+S(130)) + 1.2*(S(20)+S(122)) + S(52)
    elseif node == 53; return sij + 1.6*(S(3)+S(37)) + 0.4*(S(5)+S(135)) + 0.8*(S(13)+S(131)) + 1.2*(S(21)+S(123)) + S(53)
    elseif node == 54; return sij + 1.6*(S(3)+S(38)) + 0.4*(S(6)+S(135)) + 0.8*(S(14)+S(131)) + 1.2*(S(22)+S(123)) + S(54)
    elseif node == 55; return sij + 1.6*(S(2)+S(39)) + 0.4*(S(7)+S(134)) + 0.8*(S(15)+S(130)) + 1.2*(S(23)+S(122)) + S(55)
    elseif node == 56; return sij + 1.2*(S(0)+S(140)) + 0.8*(S(4)+S(32)) + 1.7*(S(8)+S(16)) + 0.3*(S(24)+S(120)) + S(56)
    elseif node == 57; return sij + 1.2*(S(1)+S(141)) + 0.8*(S(5)+S(33)) + 1.7*(S(9)+S(17)) + 0.3*(S(25)+S(121)) + S(57)
    elseif node == 58; return sij + 1.2*(S(0)+S(142)) + 0.8*(S(6)+S(34)) + 1.7*(S(10)+S(18)) + 0.3*(S(26)+S(120)) + S(58)
    elseif node == 59; return sij + 1.2*(S(1)+S(143)) + 0.8*(S(7)+S(35)) + 1.7*(S(11)+S(19)) + 0.3*(S(27)+S(121)) + S(59)
    elseif node == 60; return sij + 1.2*(S(2)+S(144)) + 0.8*(S(4)+S(36)) + 1.7*(S(12)+S(20)) + 0.3*(S(28)+S(122)) + S(60)
    elseif node == 61; return sij + 1.2*(S(3)+S(145)) + 0.8*(S(5)+S(37)) + 1.7*(S(13)+S(21)) + 0.3*(S(29)+S(123)) + S(61)
    elseif node == 62; return sij + 1.2*(S(3)+S(146)) + 0.8*(S(6)+S(38)) + 1.7*(S(14)+S(22)) + 0.3*(S(30)+S(123)) + S(62)
    elseif node == 63; return sij + 1.2*(S(2)+S(147)) + 0.8*(S(7)+S(39)) + 1.7*(S(15)+S(23)) + 0.3*(S(31)+S(122)) + S(63)
    # 64-119: 120-node stencil (most complex sums)
    elseif node == 64; return sij + 2/3*(S(0)+S(40)) + 4/3*(S(4)+S(140)) + 26/15*(S(8)+S(24)) + 4/15*(S(16)+S(124)) + S(64)
    elseif node == 65; return sij + 2/3*(S(1)+S(41)) + 4/3*(S(5)+S(141)) + 26/15*(S(9)+S(25)) + 4/15*(S(17)+S(125)) + S(65)
    elseif node == 66; return sij + 2/3*(S(0)+S(42)) + 4/3*(S(6)+S(142)) + 26/15*(S(10)+S(26)) + 4/15*(S(18)+S(126)) + S(66)
    elseif node == 67; return sij + 2/3*(S(1)+S(43)) + 4/3*(S(7)+S(143)) + 26/15*(S(11)+S(27)) + 4/15*(S(19)+S(127)) + S(67)
    elseif node == 68; return sij + 2/3*(S(2)+S(44)) + 4/3*(S(4)+S(144)) + 26/15*(S(12)+S(28)) + 4/15*(S(20)+S(124)) + S(68)
    elseif node == 69; return sij + 2/3*(S(3)+S(45)) + 4/3*(S(5)+S(145)) + 26/15*(S(13)+S(29)) + 4/15*(S(21)+S(125)) + S(69)
    elseif node == 70; return sij + 2/3*(S(3)+S(46)) + 4/3*(S(6)+S(146)) + 26/15*(S(14)+S(30)) + 4/15*(S(22)+S(126)) + S(70)
    elseif node == 71; return sij + 2/3*(S(2)+S(47)) + 4/3*(S(7)+S(147)) + 26/15*(S(15)+S(31)) + 4/15*(S(23)+S(127)) + S(71)
    elseif node == 72; return sij + 5/3*(S(0)+S(48)) + 4/3*(S(32)+S(120)) + S(16) + S(128) + 2/3*(S(8)+S(132)) + 1/3*(S(4)+S(148)) + S(72)
    elseif node == 73; return sij + 5/3*(S(1)+S(49)) + 4/3*(S(33)+S(121)) + S(17) + S(129) + 2/3*(S(9)+S(133)) + 1/3*(S(5)+S(149)) + S(73)
    elseif node == 74; return sij + 5/3*(S(0)+S(50)) + 4/3*(S(34)+S(120)) + S(18) + S(128) + 2/3*(S(10)+S(132)) + 1/3*(S(6)+S(148)) + S(74)
    elseif node == 75; return sij + 5/3*(S(1)+S(51)) + 4/3*(S(35)+S(121)) + S(19) + S(129) + 2/3*(S(11)+S(133)) + 1/3*(S(7)+S(149)) + S(75)
    elseif node == 76; return sij + 5/3*(S(2)+S(52)) + 4/3*(S(36)+S(122)) + S(20) + S(130) + 2/3*(S(12)+S(134)) + 1/3*(S(4)+S(150)) + S(76)
    elseif node == 77; return sij + 5/3*(S(3)+S(53)) + 4/3*(S(37)+S(123)) + S(21) + S(131) + 2/3*(S(13)+S(135)) + 1/3*(S(5)+S(151)) + S(77)
    elseif node == 78; return sij + 5/3*(S(3)+S(54)) + 4/3*(S(38)+S(123)) + S(22) + S(131) + 2/3*(S(14)+S(135)) + 1/3*(S(6)+S(151)) + S(78)
    elseif node == 79; return sij + 5/3*(S(2)+S(55)) + 4/3*(S(39)+S(122)) + S(23) + S(130) + 2/3*(S(15)+S(134)) + 1/3*(S(7)+S(150)) + S(79)
    elseif node == 80; return sij + 0.25*(S(0)+S(152)) + 0.75*(S(8)+S(136)) + 1.25*(S(124)+S(24)) + 1.75*(S(4)+S(40)) + S(80)
    elseif node == 81; return sij + 0.25*(S(1)+S(153)) + 0.75*(S(9)+S(137)) + 1.25*(S(125)+S(25)) + 1.75*(S(5)+S(41)) + S(81)
    elseif node == 82; return sij + 0.25*(S(0)+S(154)) + 0.75*(S(10)+S(138)) + 1.25*(S(126)+S(26)) + 1.75*(S(6)+S(42)) + S(82)
    elseif node == 83; return sij + 0.25*(S(1)+S(155)) + 0.75*(S(11)+S(139)) + 1.25*(S(127)+S(27)) + 1.75*(S(7)+S(43)) + S(83)
    elseif node == 84; return sij + 0.25*(S(2)+S(152)) + 0.75*(S(12)+S(136)) + 1.25*(S(124)+S(28)) + 1.75*(S(4)+S(44)) + S(84)
    elseif node == 85; return sij + 0.25*(S(3)+S(153)) + 0.75*(S(13)+S(137)) + 1.25*(S(125)+S(29)) + 1.75*(S(5)+S(45)) + S(85)
    elseif node == 86; return sij + 0.25*(S(3)+S(154)) + 0.75*(S(14)+S(138)) + 1.25*(S(126)+S(30)) + 1.75*(S(6)+S(46)) + S(86)
    elseif node == 87; return sij + 0.25*(S(2)+S(155)) + 0.75*(S(15)+S(139)) + 1.25*(S(127)+S(31)) + 1.75*(S(7)+S(47)) + S(87)
    elseif node == 88; return sij + 8/7*(S(0)+S(168)) + 6/7*(S(4)+S(160)) + 38/21*(S(8)+S(56)) + 4/21*(S(120)+S(64)) + 32/21*(S(16)+S(140)) + 10/21*(S(24)+S(32)) + S(88)
    elseif node == 89; return sij + 8/7*(S(1)+S(169)) + 6/7*(S(5)+S(161)) + 38/21*(S(9)+S(57)) + 4/21*(S(121)+S(65)) + 32/21*(S(17)+S(141)) + 10/21*(S(25)+S(33)) + S(89)
    elseif node == 90; return sij + 8/7*(S(0)+S(170)) + 6/7*(S(6)+S(162)) + 38/21*(S(10)+S(58)) + 4/21*(S(120)+S(66)) + 32/21*(S(18)+S(142)) + 10/21*(S(26)+S(34)) + S(90)
    elseif node == 91; return sij + 8/7*(S(1)+S(171)) + 6/7*(S(7)+S(163)) + 38/21*(S(11)+S(59)) + 4/21*(S(121)+S(67)) + 32/21*(S(19)+S(143)) + 10/21*(S(27)+S(35)) + S(91)
    elseif node == 92; return sij + 8/7*(S(2)+S(172)) + 6/7*(S(4)+S(164)) + 38/21*(S(12)+S(60)) + 4/21*(S(122)+S(68)) + 32/21*(S(20)+S(144)) + 10/21*(S(28)+S(36)) + S(92)
    elseif node == 93; return sij + 8/7*(S(3)+S(173)) + 6/7*(S(5)+S(165)) + 38/21*(S(13)+S(61)) + 4/21*(S(123)+S(69)) + 32/21*(S(21)+S(145)) + 10/21*(S(29)+S(37)) + S(93)
    elseif node == 94; return sij + 8/7*(S(3)+S(174)) + 6/7*(S(6)+S(166)) + 38/21*(S(14)+S(62)) + 4/21*(S(123)+S(70)) + 32/21*(S(22)+S(146)) + 10/21*(S(30)+S(38)) + S(94)
    elseif node == 95; return sij + 8/7*(S(2)+S(175)) + 6/7*(S(7)+S(167)) + 38/21*(S(15)+S(63)) + 4/21*(S(122)+S(71)) + 32/21*(S(23)+S(147)) + 10/21*(S(31)+S(39)) + S(95)
    elseif node == 96;  return sij + 1.75*(S(0)+S(184)) + 1.5*(S(120)+S(72)) + 1.25*(S(128)+S(48)) + S(32)+S(132) + 0.75*(S(16)+S(148)) + 0.5*(S(8)+S(156)) + 0.25*(S(4)+S(176)) + S(96)
    elseif node == 97;  return sij + 1.75*(S(1)+S(185)) + 1.5*(S(121)+S(73)) + 1.25*(S(129)+S(49)) + S(33)+S(133) + 0.75*(S(17)+S(149)) + 0.5*(S(9)+S(157)) + 0.25*(S(5)+S(177)) + S(97)
    elseif node == 98;  return sij + 1.75*(S(0)+S(186)) + 1.5*(S(120)+S(74)) + 1.25*(S(128)+S(50)) + S(34)+S(132) + 0.75*(S(18)+S(148)) + 0.5*(S(10)+S(156)) + 0.25*(S(6)+S(176)) + S(98)
    elseif node == 99;  return sij + 1.75*(S(1)+S(187)) + 1.5*(S(121)+S(75)) + 1.25*(S(129)+S(51)) + S(35)+S(133) + 0.75*(S(19)+S(149)) + 0.5*(S(11)+S(157)) + 0.25*(S(7)+S(177)) + S(99)
    elseif node == 100; return sij + 1.75*(S(2)+S(188)) + 1.5*(S(122)+S(76)) + 1.25*(S(130)+S(52)) + S(36)+S(134) + 0.75*(S(20)+S(150)) + 0.5*(S(12)+S(158)) + 0.25*(S(4)+S(178)) + S(100)
    elseif node == 101; return sij + 1.75*(S(3)+S(189)) + 1.5*(S(123)+S(77)) + 1.25*(S(131)+S(53)) + S(37)+S(135) + 0.75*(S(21)+S(151)) + 0.5*(S(13)+S(159)) + 0.25*(S(5)+S(179)) + S(101)
    elseif node == 102; return sij + 1.75*(S(3)+S(190)) + 1.5*(S(123)+S(78)) + 1.25*(S(131)+S(54)) + S(38)+S(135) + 0.75*(S(22)+S(151)) + 0.5*(S(14)+S(159)) + 0.25*(S(6)+S(179)) + S(102)
    elseif node == 103; return sij + 1.75*(S(2)+S(191)) + 1.5*(S(122)+S(79)) + 1.25*(S(130)+S(55)) + S(39)+S(134) + 0.75*(S(23)+S(150)) + 0.5*(S(15)+S(158)) + 0.25*(S(7)+S(178)) + S(103)
    elseif node == 104; return sij + 1/6*(S(0)+S(204)) + 11/6*(S(4)+S(192)) + 0.5*(S(8)+S(180)) + 1.5*(S(124)+S(80)) + 5/6*(S(24)+S(152)) + 7/6*(S(136)+S(40)) + S(104)
    elseif node == 105; return sij + 1/6*(S(1)+S(205)) + 11/6*(S(5)+S(193)) + 0.5*(S(9)+S(181)) + 1.5*(S(125)+S(81)) + 5/6*(S(25)+S(153)) + 7/6*(S(137)+S(41)) + S(105)
    elseif node == 106; return sij + 1/6*(S(0)+S(206)) + 11/6*(S(6)+S(194)) + 0.5*(S(10)+S(182)) + 1.5*(S(126)+S(82)) + 5/6*(S(26)+S(154)) + 7/6*(S(138)+S(42)) + S(106)
    elseif node == 107; return sij + 1/6*(S(1)+S(207)) + 11/6*(S(7)+S(195)) + 0.5*(S(11)+S(183)) + 1.5*(S(127)+S(83)) + 5/6*(S(27)+S(155)) + 7/6*(S(139)+S(43)) + S(107)
    elseif node == 108; return sij + 1/6*(S(2)+S(204)) + 11/6*(S(4)+S(196)) + 0.5*(S(12)+S(180)) + 1.5*(S(124)+S(84)) + 5/6*(S(28)+S(152)) + 7/6*(S(136)+S(44)) + S(108)
    elseif node == 109; return sij + 1/6*(S(3)+S(205)) + 11/6*(S(5)+S(197)) + 0.5*(S(13)+S(181)) + 1.5*(S(125)+S(85)) + 5/6*(S(29)+S(153)) + 7/6*(S(137)+S(45)) + S(109)
    elseif node == 110; return sij + 1/6*(S(3)+S(206)) + 11/6*(S(6)+S(198)) + 0.5*(S(14)+S(182)) + 1.5*(S(126)+S(86)) + 5/6*(S(30)+S(154)) + 7/6*(S(138)+S(46)) + S(110)
    elseif node == 111; return sij + 1/6*(S(2)+S(207)) + 11/6*(S(7)+S(199)) + 0.5*(S(15)+S(183)) + 1.5*(S(127)+S(87)) + 5/6*(S(31)+S(155)) + 7/6*(S(139)+S(47)) + S(111)
    elseif node == 112; return sij + 24/13*(S(0)+S(248)) + 22/13*(S(120)+S(236)) + 20/13*(S(128)+S(224)) + 18/13*(S(132)+S(212)) + 16/13*(S(148)+S(96)) + 14/13*(S(156)+S(184)) + 12/13*(S(176)+S(72)) + 10/13*(S(200)+S(48)) + 8/13*(S(208)+S(32)) + 6/13*(S(220)+S(16)) + 4/13*(S(232)+S(8)) + 2/13*(S(244)+S(4)) + S(112)
    elseif node == 113; return sij + 24/13*(S(1)+S(249)) + 22/13*(S(121)+S(237)) + 20/13*(S(129)+S(225)) + 18/13*(S(133)+S(213)) + 16/13*(S(149)+S(97)) + 14/13*(S(157)+S(185)) + 12/13*(S(177)+S(73)) + 10/13*(S(201)+S(49)) + 8/13*(S(209)+S(33)) + 6/13*(S(221)+S(17)) + 4/13*(S(233)+S(9)) + 2/13*(S(245)+S(5)) + S(113)
    elseif node == 114; return sij + 24/13*(S(0)+S(250)) + 22/13*(S(120)+S(238)) + 20/13*(S(128)+S(226)) + 18/13*(S(132)+S(214)) + 16/13*(S(148)+S(98)) + 14/13*(S(156)+S(186)) + 12/13*(S(176)+S(74)) + 10/13*(S(200)+S(50)) + 8/13*(S(208)+S(34)) + 6/13*(S(220)+S(18)) + 4/13*(S(232)+S(10)) + 2/13*(S(244)+S(6)) + S(114)
    elseif node == 115; return sij + 24/13*(S(1)+S(251)) + 22/13*(S(121)+S(239)) + 20/13*(S(129)+S(227)) + 18/13*(S(133)+S(215)) + 16/13*(S(149)+S(99)) + 14/13*(S(157)+S(187)) + 12/13*(S(177)+S(75)) + 10/13*(S(201)+S(51)) + 8/13*(S(209)+S(35)) + 6/13*(S(221)+S(19)) + 4/13*(S(233)+S(11)) + 2/13*(S(245)+S(7)) + S(115)
    elseif node == 116; return sij + 24/13*(S(2)+S(252)) + 22/13*(S(122)+S(240)) + 20/13*(S(130)+S(228)) + 18/13*(S(134)+S(216)) + 16/13*(S(150)+S(100)) + 14/13*(S(158)+S(188)) + 12/13*(S(178)+S(76)) + 10/13*(S(202)+S(52)) + 8/13*(S(210)+S(36)) + 6/13*(S(222)+S(20)) + 4/13*(S(234)+S(12)) + 2/13*(S(246)+S(4)) + S(116)
    elseif node == 117; return sij + 24/13*(S(3)+S(253)) + 22/13*(S(123)+S(241)) + 20/13*(S(131)+S(229)) + 18/13*(S(135)+S(217)) + 16/13*(S(151)+S(101)) + 14/13*(S(159)+S(189)) + 12/13*(S(179)+S(77)) + 10/13*(S(203)+S(53)) + 8/13*(S(211)+S(37)) + 6/13*(S(223)+S(21)) + 4/13*(S(235)+S(13)) + 2/13*(S(247)+S(5)) + S(117)
    elseif node == 118; return sij + 24/13*(S(3)+S(254)) + 22/13*(S(123)+S(242)) + 20/13*(S(131)+S(230)) + 18/13*(S(135)+S(218)) + 16/13*(S(151)+S(102)) + 14/13*(S(159)+S(190)) + 12/13*(S(179)+S(78)) + 10/13*(S(203)+S(54)) + 8/13*(S(211)+S(38)) + 6/13*(S(223)+S(22)) + 4/13*(S(235)+S(14)) + 2/13*(S(247)+S(6)) + S(118)
    elseif node == 119; return sij + 24/13*(S(2)+S(255)) + 22/13*(S(122)+S(243)) + 20/13*(S(130)+S(231)) + 18/13*(S(134)+S(219)) + 16/13*(S(150)+S(103)) + 14/13*(S(158)+S(191)) + 12/13*(S(178)+S(79)) + 10/13*(S(202)+S(55)) + 8/13*(S(210)+S(39)) + 6/13*(S(222)+S(23)) + 4/13*(S(234)+S(15)) + 2/13*(S(246)+S(7)) + S(119)
    else
        return 0.0
    end
end

"""
Get the distance array value for a given stencil node index and row j (0-based).
Returns the geometric distance from center to that stencil node.
"""
function stencil_distance(D::DistanceArrays, node::Int, j::Int)
    j1 = j + 1  # Julia 1-based
    if node < 2;      return D.dx_half[j1]       # E/W
    elseif node < 4;  return D.dy_half            # N/S
    elseif node < 8;  return D.diag_1_1[j1]      # diagonal
    elseif node < 12; return D.diag_1_05[j1]     # 2:1 ratio
    elseif node < 16; return D.diag_05_1[j1]     # 1:2 ratio
    elseif node < 20; return D.diag_1_13[j1]     # 3:1
    elseif node < 24; return D.diag_13_1[j1]     # 1:3
    elseif node < 28; return D.diag_1_23[j1]     # 3:2
    elseif node < 32; return D.diag_23_1[j1]     # 2:3
    elseif node < 36; return D.diag_1_025[j1]    # 4:1
    elseif node < 40; return D.diag_025_1[j1]    # 1:4
    elseif node < 44; return D.diag_1_075[j1]    # 4:3
    elseif node < 48; return D.diag_075_1[j1]    # 3:4
    elseif node < 52; return D.diag_1_02[j1]     # 5:1
    elseif node < 56; return D.diag_02_1[j1]     # 1:5
    elseif node < 60; return D.diag_1_04[j1]     # 5:2
    elseif node < 64; return D.diag_04_1[j1]     # 2:5
    elseif node < 68; return D.diag_1_06[j1]     # 5:3 → 0.6
    elseif node < 72; return D.diag_06_1[j1]     # 3:5
    elseif node < 76; return D.diag_1_16[j1]     # 6:1 → 1/6
    elseif node < 80; return D.diag_16_1[j1]     # 1:6
    elseif node < 84; return D.diag_1_08[j1]     # 5:4 → 0.8
    elseif node < 88; return D.diag_08_1[j1]     # 4:5
    elseif node < 92; return D.diag_1_37[j1]     # 7:3 → 3/7
    elseif node < 96; return D.diag_37_1[j1]     # 3:7
    elseif node < 100; return D.diag_1_0125[j1]  # 8:1 → 0.125
    elseif node < 104; return D.diag_0125_1[j1]  # 1:8
    elseif node < 108; return D.diag_1_67[j1]    # 7:6 → 6/7
    elseif node < 112; return D.diag_67_1[j1]    # 6:7
    elseif node < 120; return D.diag_1_113[j1]   # 13:1 → 1/13
    else
        return 0.0
    end
end

# ──────────────────── Core Functions ────────────────────

"""Initialize grid header from wesn bounds and dimensions."""
function init_header!(h::TTThdr, wesn, dims, registration)
    h.west = wesn[1]; h.east = wesn[2]; h.south = wesn[3]; h.north = wesn[4]
    if h.west >= h.east || h.south >= h.north
        return TTT_ERROR_WESN_CHECK
    end
    h.nx = dims[1]; h.ny = dims[2]
    if h.nx <= 0 || h.ny <= 0
        return TTT_ERROR_DIM_CHECK
    end
    h.pixel_reg = registration == 0 ? 1 : 0   # Invert: C code uses !registration
    h.dx = (h.east - h.west) / (h.nx - registration)
    h.dy = (h.north - h.south) / (h.ny - registration)
    if h.dx <= 0 || h.dy <= 0
        return TTT_ERROR_INC_CHECK
    end
    h.xy_off = 0.5 * h.pixel_reg
    return TTT_SUCCESS
end

"""Parse parameters array into TTTState."""
function parse_params!(T::TTTState, params)
    T.normalize = round(Int, params[5]) != 1
    T.n_nodes = round(Int, params[1])
    if !(T.n_nodes in (8, 16, 32, 48, 64, 120))
        return TTT_ERROR_BAD_NODES
    end
    T.do_search = round(Int, params[2]) == 1
    T.search_radius = params[3]
    T.search_radius < 0 && return TTT_ERROR_BAD_RADIUS
    T.source_depth = params[4]
    T.source_depth > 0 && return TTT_ERROR_BAD_DEPTH
    T.verbose = round(Int, params[6])
    T.verbose < 0 && return TTT_ERROR_BAD_VERBOSITY
    T.depth_threshold = params[8]
    T.depth_threshold > 0 && return TTT_ERROR_BAD_MINDEPTH
    return TTT_SUCCESS
end

"""Load bathymetry into padded grid with wrapping at boundaries."""
function load_bathymetry!(T::TTTState, wesn, dims, registration, z)
    err = init_header!(T.header, wesn, dims, registration)
    err != TTT_SUCCESS && return err
    h = T.header
    T.mx = h.nx + 2 * TTT_PAD
    T.my = h.ny + 2 * TTT_PAD
    T.mxy = T.mx * T.my
    T.dim_prime = dims[3]
    T.slowness = fill(Float32(NaN), T.mxy)

    # Copy data into padded grid
    for j in 0:h.ny-1
        for i in 0:h.nx-1
            to = padded_index(i, j, T.mx, TTT_PAD)
            # Source format index (row-major, top-to-bottom)
            from = j * T.dim_prime + i + 1
            T.slowness[to] = z[from]
        end
    end

    gridline_adj = h.pixel_reg == 1 ? 1 : 0
    # Wrap in longitude if global
    if abs(h.east - h.west - 360.0) < TTT_EPS
        h.is_global = true
        for j in 0:h.ny-1
            k = padded_index(0, j, T.mx, TTT_PAD)
            for p in 1:TTT_PAD
                T.slowness[k + h.nx + p - 1] = T.slowness[k + p - gridline_adj]
                T.slowness[k - p] = T.slowness[k + h.nx - p - 1 + gridline_adj]
            end
        end
    end

    half_nx = h.nx ÷ 2
    # North pole wrapping
    if abs(h.north - 90.0) < TTT_EPS && h.is_global
        h.has_north_pole = true
        k = padded_index(0, 0, T.mx, TTT_PAD)
        for i in -TTT_PAD:(h.nx + TTT_PAD - 1)
            mirror = i + half_nx
            if mirror >= T.mx; mirror -= T.mx; end
            for p in 1:TTT_PAD
                T.slowness[k + i - p * T.mx] = T.slowness[k + mirror + (p - gridline_adj) * T.mx]
            end
        end
    end
    # South pole wrapping
    if abs(h.south + 90.0) < TTT_EPS && h.is_global
        h.has_south_pole = true
        k = padded_index(0, h.ny - 1, T.mx, TTT_PAD)
        for i in -TTT_PAD:(h.nx + TTT_PAD - 1)
            mirror = i + half_nx
            if mirror >= T.mx; mirror -= T.mx; end
            for p in 1:TTT_PAD
                T.slowness[k + i + p * T.mx] = T.slowness[k + mirror - (p - gridline_adj) * T.mx]
            end
        end
    end
    return TTT_SUCCESS
end

"""Check and validate source locations; relocate from land if needed."""
function check_sources!(T::TTTState, n_sources, lons, lats)
    n_sources <= 0 && return TTT_ERROR_NO_SOURCE
    h = T.header
    T.source_bathy = zeros(n_sources)
    T.source_dist = zeros(n_sources)
    T.source_indices = zeros(Int, n_sources)
    T.n_sources = n_sources

    for k in 1:n_sources
        (lats[k] < h.south || lats[k] > h.north) && return TTT_ERROR_SOURCE_OUTSIDE
        lon = lons[k]
        while lon > h.west; lon -= 360.0; end
        while lon < h.west; lon += 360.0; end
        lon > h.east && return TTT_ERROR_SOURCE_OUTSIDE

        col = lon_to_col(lon, h.west, h.dx, h.xy_off, h.nx)
        row = lat_to_row(lats[k], h.south, h.dy, h.xy_off, h.ny)
        ij = padded_index(col, row, T.mx, TTT_PAD)
        T.source_indices[k] = ij
        is_land = isnan(T.slowness[ij]) || T.slowness[ij] >= 0.0
        if is_land && !T.do_search
            return TTT_ERROR_SOURCE_LAND
        end
        T.source_bathy[k] = T.slowness[ij]
        too_shallow = T.source_bathy[k] > T.source_depth
        if too_shallow; is_land = true; end
        if !is_land; continue; end

        # Search for nearest water node
        dx_deg = h.dx * cos(lats[k] * D2R)
        i_lo = max(0, col - ceil(Int, T.search_radius / dx_deg))
        i_hi = min(h.nx - 1, col + ceil(Int, T.search_radius / dx_deg))
        j_lo = max(0, row - ceil(Int, T.search_radius / h.dy))
        j_hi = min(h.ny - 1, row + ceil(Int, T.search_radius / h.dy))
        best_dist = 180.0
        best_x = best_y = best_z = 0.0
        best_ij = ij
        for j in j_lo:j_hi
            y = row_to_lat(j, h.south, h.north, h.dy, h.xy_off, h.ny)
            for i in i_lo:i_hi
                ij2 = padded_index(i, j, T.mx, TTT_PAD)
                (isnan(T.slowness[ij2]) || T.slowness[ij2] >= 0.0) && continue
                T.slowness[ij2] >= T.source_depth && continue
                x = col_to_lon(i, h.west, h.east, h.dx, h.xy_off, h.nx)
                d = spherical_distance(lons[k], lats[k], x, y)
                if d < best_dist
                    best_dist = d; best_x = x; best_y = y; best_z = T.slowness[ij2]; best_ij = ij2
                end
            end
        end
        best_dist == 180.0 && return TTT_ERROR_SOURCE_BAD_SEARCH
        lons[k] = best_x; lats[k] = best_y
        T.source_bathy[k] = best_z
        T.source_dist[k] = best_dist
        T.source_indices[k] = best_ij
    end
    return TTT_SUCCESS
end

"""Convert bathymetry depth to slowness: s = sign / sqrt(-depth * gravity)."""
function depth_to_slowness!(h::TTThdr, s::Vector{Float32}, sign_val::Float64, depth_thresh::Float64)
    mx = h.nx + 2 * TTT_PAD
    my = h.ny + 2 * TTT_PAD
    gridline_adj = h.pixel_reg == 1 ? 1 : 0
    use_ramp = depth_thresh > 0.00001
    a_ramp = use_ramp ? 0.25 / depth_thresh : 0.0
    double_thresh = 2.0 * depth_thresh

    # Pre-compute latitudes for each padded row
    lats = Vector{Float64}(undef, my)
    for j in 0:h.ny-1
        lats[j + TTT_PAD + 1] = row_to_lat(j, h.south, h.north, h.dy, h.xy_off, h.ny)
    end
    for p in 1:TTT_PAD
        lats[TTT_PAD + 1 - p] = lats[TTT_PAD + 1 + p - gridline_adj]
        lats[my - TTT_PAD + p] = lats[my - TTT_PAD - p + gridline_adj]
    end

    k = 1
    for j in 0:my-1
        g = normal_gravity(lats[j + 1])
        for i in 0:mx-1
            if s[k] >= 0.0
                s[k] = Float32(NaN)
            elseif use_ramp && s[k] >= double_thresh
                z_eff = a_ramp * s[k] * s[k] + depth_thresh
                s[k] = Float32(sign_val / sqrt(-z_eff * g))
            else
                s[k] = Float32(sign_val / sqrt(Float64(-s[k]) * g))
            end
            k += 1
        end
    end
end

"""Compute distance arrays for the Huygens stencil at each latitude row."""
function compute_distances(T::TTTState)
    h = T.header
    ny = h.ny
    alloc(n) = Vector{Float64}(undef, n)

    dx_half = alloc(ny)
    dy_half_val = 0.5 * h.dy * DEG_TO_M
    diag_1_1 = alloc(ny)

    # Always needed (>8 nodes)
    diag_05_1 = T.n_nodes > 8 ? alloc(ny) : Float64[]
    diag_1_05 = T.n_nodes > 8 ? alloc(ny) : Float64[]
    # >16
    d13_1 = T.n_nodes > 16 ? alloc(ny) : Float64[]
    d1_13 = T.n_nodes > 16 ? alloc(ny) : Float64[]
    d23_1 = T.n_nodes > 16 ? alloc(ny) : Float64[]
    d1_23 = T.n_nodes > 16 ? alloc(ny) : Float64[]
    # >32
    d025_1 = T.n_nodes > 32 ? alloc(ny) : Float64[]
    d1_025 = T.n_nodes > 32 ? alloc(ny) : Float64[]
    d075_1 = T.n_nodes > 32 ? alloc(ny) : Float64[]
    d1_075 = T.n_nodes > 32 ? alloc(ny) : Float64[]
    # >48
    d02_1 = T.n_nodes > 48 ? alloc(ny) : Float64[]
    d1_02 = T.n_nodes > 48 ? alloc(ny) : Float64[]
    d04_1 = T.n_nodes > 48 ? alloc(ny) : Float64[]
    d1_04 = T.n_nodes > 48 ? alloc(ny) : Float64[]
    # >64 (120 nodes)
    d06_1  = T.n_nodes > 64 ? alloc(ny) : Float64[]
    d1_06  = T.n_nodes > 64 ? alloc(ny) : Float64[]
    d16_1  = T.n_nodes > 64 ? alloc(ny) : Float64[]
    d1_16  = T.n_nodes > 64 ? alloc(ny) : Float64[]
    d08_1  = T.n_nodes > 64 ? alloc(ny) : Float64[]
    d1_08  = T.n_nodes > 64 ? alloc(ny) : Float64[]
    d37_1  = T.n_nodes > 64 ? alloc(ny) : Float64[]
    d1_37  = T.n_nodes > 64 ? alloc(ny) : Float64[]
    d0125_1 = T.n_nodes > 64 ? alloc(ny) : Float64[]
    d1_0125 = T.n_nodes > 64 ? alloc(ny) : Float64[]
    d67_1  = T.n_nodes > 64 ? alloc(ny) : Float64[]
    d1_67  = T.n_nodes > 64 ? alloc(ny) : Float64[]
    d113_1 = T.n_nodes > 64 ? alloc(ny) : Float64[]
    d1_113 = T.n_nodes > 64 ? alloc(ny) : Float64[]

    for j in 0:ny-1
        lat = h.north - j * h.dy
        dx_half[j+1] = 0.5 * h.dx * DEG_TO_M * cos(D2R * lat)
        diag_1_1[j+1] = hypot(dx_half[j+1], dy_half_val)
        T.n_nodes <= 8 && continue
        diag_05_1[j+1] = hypot(0.5 * dx_half[j+1], dy_half_val)
        diag_1_05[j+1] = hypot(dx_half[j+1], 0.5 * dy_half_val)
        T.n_nodes <= 16 && continue
        d13_1[j+1] = hypot(1/3 * dx_half[j+1], dy_half_val)
        d1_13[j+1] = hypot(dx_half[j+1], 1/3 * dy_half_val)
        d23_1[j+1] = hypot(2/3 * dx_half[j+1], dy_half_val)
        d1_23[j+1] = hypot(dx_half[j+1], 2/3 * dy_half_val)
        T.n_nodes <= 32 && continue
        d025_1[j+1] = hypot(0.25 * dx_half[j+1], dy_half_val)
        d1_025[j+1] = hypot(dx_half[j+1], 0.25 * dy_half_val)
        d075_1[j+1] = hypot(0.75 * dx_half[j+1], dy_half_val)
        d1_075[j+1] = hypot(dx_half[j+1], 0.75 * dy_half_val)
        T.n_nodes <= 48 && continue
        d02_1[j+1] = hypot(0.2 * dx_half[j+1], dy_half_val)
        d1_02[j+1] = hypot(dx_half[j+1], 0.2 * dy_half_val)
        d04_1[j+1] = hypot(0.4 * dx_half[j+1], dy_half_val)
        d1_04[j+1] = hypot(dx_half[j+1], 0.4 * dy_half_val)
        T.n_nodes <= 64 && continue
        d06_1[j+1]  = hypot(0.6 * dx_half[j+1], dy_half_val)
        d1_06[j+1]  = hypot(dx_half[j+1], 0.6 * dy_half_val)
        d16_1[j+1]  = hypot(1/6 * dx_half[j+1], dy_half_val)
        d1_16[j+1]  = hypot(dx_half[j+1], 1/6 * dy_half_val)
        d08_1[j+1]  = hypot(0.8 * dx_half[j+1], dy_half_val)
        d1_08[j+1]  = hypot(dx_half[j+1], 0.8 * dy_half_val)
        d37_1[j+1]  = hypot(3/7 * dx_half[j+1], dy_half_val)
        d1_37[j+1]  = hypot(dx_half[j+1], 3/7 * dy_half_val)
        d0125_1[j+1] = hypot(0.125 * dx_half[j+1], dy_half_val)
        d1_0125[j+1] = hypot(dx_half[j+1], 0.125 * dy_half_val)
        d67_1[j+1]  = hypot(6/7 * dx_half[j+1], dy_half_val)
        d1_67[j+1]  = hypot(dx_half[j+1], 6/7 * dy_half_val)
        d113_1[j+1] = hypot(1/13 * dx_half[j+1], dy_half_val)
        d1_113[j+1] = hypot(dx_half[j+1], 1/13 * dy_half_val)
    end

    return DistanceArrays(dx_half, dy_half_val, diag_1_1,
        diag_05_1, diag_1_05, d13_1, d1_13, d23_1, d1_23,
        d025_1, d1_025, d075_1, d1_075, d02_1, d1_02, d04_1, d1_04,
        d06_1, d1_06, d16_1, d1_16, d08_1, d1_08, d37_1, d1_37,
        d0125_1, d1_0125, d67_1, d1_67, d113_1, d1_113)
end

"""Compute stencil offset array p[k] = -dj*mx + di for each stencil position."""
function setup_stencil_offsets(T::TTTState)
    p = Vector{Int}(undef, N_STENCIL_TOTAL)
    for k in 1:N_STENCIL_TOTAL
        p[k] = -STENCIL_DJ[k] * T.mx + STENCIL_DI[k]
    end
    # Return number of stencil points actually used
    n_used = Dict(8 => 8, 16 => 16, 32 => 128, 48 => 140, 64 => 148, 120 => 256)
    T.n_stencil_used = get(n_used, T.n_nodes, 0)
    return p
end

"""Initialize dependency bitmasks for stencil nodes (which nodes must be water)."""
function init_dep_masks!(T::TTTState)
    # Direct translation of the C u694020 function.
    # The dependency masks encode which stencil nodes must be water/valid
    # for each higher-order stencil node to be usable.
    # d[set, node] where set is 1-based (C uses 0-based), node is 1-based (C uses 0-based).
    # In C: T->d162994[set][node], here: d[set+1, node+1]
    d = T.dep_masks
    fill!(d, UInt32(0))

    bm(n) = bitmask(n)  # shorthand: UInt32(1) << (n % 32)

    # Nodes 0-7: each only depends on itself (set 0)
    for i in 0:7; d[1, i+1] = bm(i); end

    # Nodes 8-15 (16-node stencil, set 0 only)
    d[1, 9]  = bm(0) + bm(4) + bm(8)
    d[1, 10] = bm(1) + bm(5) + bm(9)
    d[1, 11] = bm(0) + bm(6) + bm(10)
    d[1, 12] = bm(1) + bm(7) + bm(11)
    d[1, 13] = bm(2) + bm(4) + bm(12)
    d[1, 14] = bm(3) + bm(5) + bm(13)
    d[1, 15] = bm(3) + bm(6) + bm(14)
    d[1, 16] = bm(2) + bm(7) + bm(15)

    # Nodes 16-23 (32-node stencil, sets 0 and 3)
    d[1, 17] = d[1, 9]  + bm(16);  d[4, 17] = bm(120)
    d[1, 18] = d[1, 10] + bm(17);  d[4, 18] = bm(121)
    d[1, 19] = d[1, 11] + bm(18);  d[4, 19] = bm(120)
    d[1, 20] = d[1, 12] + bm(19);  d[4, 20] = bm(121)
    d[1, 21] = d[1, 13] + bm(20);  d[4, 21] = bm(122)
    d[1, 22] = d[1, 14] + bm(21);  d[4, 22] = bm(123)
    d[1, 23] = d[1, 15] + bm(22);  d[4, 23] = bm(123)
    d[1, 24] = d[1, 16] + bm(23);  d[4, 24] = bm(122)

    # Nodes 24-31 (sets 0 and 3)
    d[1, 25] = d[1, 9]  + bm(24);  d[4, 25] = bm(124)
    d[1, 26] = d[1, 10] + bm(25);  d[4, 26] = bm(125)
    d[1, 27] = d[1, 11] + bm(26);  d[4, 27] = bm(126)
    d[1, 28] = d[1, 12] + bm(27);  d[4, 28] = bm(127)
    d[1, 29] = d[1, 13] + bm(28);  d[4, 29] = bm(124)
    d[1, 30] = d[1, 14] + bm(29);  d[4, 30] = bm(125)
    d[1, 31] = d[1, 15] + bm(30);  d[4, 31] = bm(126)
    d[1, 32] = d[1, 16] + bm(31);  d[4, 32] = bm(127)

    # Nodes 32-39 (48-node stencil, sets 0, 1, 3, 4)
    d[1, 33] = d[1, 17]; d[2, 33] = bm(32); d[4, 33] = bm(120); d[5, 33] = bm(128)
    d[1, 34] = d[1, 18]; d[2, 34] = bm(33); d[4, 34] = bm(121); d[5, 34] = bm(129)
    d[1, 35] = d[1, 19]; d[2, 35] = bm(34); d[4, 35] = bm(120); d[5, 35] = bm(128)
    d[1, 36] = d[1, 20]; d[2, 36] = bm(35); d[4, 36] = bm(121); d[5, 36] = bm(129)
    d[1, 37] = d[1, 21]; d[2, 37] = bm(36); d[4, 37] = bm(122); d[5, 37] = bm(130)
    d[1, 38] = d[1, 22]; d[2, 38] = bm(37); d[4, 38] = bm(123); d[5, 38] = bm(131)
    d[1, 39] = d[1, 23]; d[2, 39] = bm(38); d[4, 39] = bm(123); d[5, 39] = bm(131)
    d[1, 40] = d[1, 24]; d[2, 40] = bm(39); d[4, 40] = bm(122); d[5, 40] = bm(130)

    # Nodes 40-47 (sets 0, 1, 3, 4)
    d[1, 41] = d[1, 25]; d[2, 41] = bm(40); d[4, 41] = bm(124); d[5, 41] = bm(136)
    d[1, 42] = d[1, 26]; d[2, 42] = bm(41); d[4, 42] = bm(125); d[5, 42] = bm(137)
    d[1, 43] = d[1, 27]; d[2, 43] = bm(42); d[4, 43] = bm(126); d[5, 43] = bm(138)
    d[1, 44] = d[1, 28]; d[2, 44] = bm(43); d[4, 44] = bm(127); d[5, 44] = bm(139)
    d[1, 45] = d[1, 29]; d[2, 45] = bm(44); d[4, 45] = bm(124); d[5, 45] = bm(136)
    d[1, 46] = d[1, 30]; d[2, 46] = bm(45); d[4, 46] = bm(125); d[5, 46] = bm(137)
    d[1, 47] = d[1, 31]; d[2, 47] = bm(46); d[4, 47] = bm(126); d[5, 47] = bm(138)
    d[1, 48] = d[1, 32]; d[2, 48] = bm(47); d[4, 48] = bm(127); d[5, 48] = bm(139)

    # Nodes 48-55 (64-node stencil, sets 0, 1, 3, 4)
    d[1, 49] = d[1, 17]; d[2, 49] = bm(32)+bm(48); d[4, 49] = bm(120); d[5, 49] = bm(128)+bm(132)
    d[1, 50] = d[1, 18]; d[2, 50] = bm(33)+bm(49); d[4, 50] = bm(121); d[5, 50] = bm(129)+bm(133)
    d[1, 51] = d[1, 19]; d[2, 51] = bm(34)+bm(50); d[4, 51] = bm(120); d[5, 51] = bm(128)+bm(132)
    d[1, 52] = d[1, 20]; d[2, 52] = bm(35)+bm(51); d[4, 52] = bm(121); d[5, 52] = bm(129)+bm(133)
    d[1, 53] = d[1, 21]; d[2, 53] = bm(36)+bm(52); d[4, 53] = bm(122); d[5, 53] = bm(130)+bm(134)
    d[1, 54] = d[1, 22]; d[2, 54] = bm(37)+bm(53); d[4, 54] = bm(123); d[5, 54] = bm(131)+bm(135)
    d[1, 55] = d[1, 23]; d[2, 55] = bm(38)+bm(54); d[4, 55] = bm(123); d[5, 55] = bm(131)+bm(135)
    d[1, 56] = d[1, 24]; d[2, 56] = bm(39)+bm(55); d[4, 56] = bm(122); d[5, 56] = bm(130)+bm(134)

    # Nodes 56-63 (sets 0, 1, 3, 4)
    d[1, 57] = d[1, 17]+bm(24); d[2, 57] = bm(32)+bm(56); d[4, 57] = bm(120); d[5, 57] = bm(140)
    d[1, 58] = d[1, 18]+bm(25); d[2, 58] = bm(33)+bm(57); d[4, 58] = bm(121); d[5, 58] = bm(141)
    d[1, 59] = d[1, 19]+bm(26); d[2, 59] = bm(34)+bm(58); d[4, 59] = bm(120); d[5, 59] = bm(142)
    d[1, 60] = d[1, 20]+bm(27); d[2, 60] = bm(35)+bm(59); d[4, 60] = bm(121); d[5, 60] = bm(143)
    d[1, 61] = d[1, 21]+bm(28); d[2, 61] = bm(36)+bm(60); d[4, 61] = bm(122); d[5, 61] = bm(144)
    d[1, 62] = d[1, 22]+bm(29); d[2, 62] = bm(37)+bm(61); d[4, 62] = bm(123); d[5, 62] = bm(145)
    d[1, 63] = d[1, 23]+bm(30); d[2, 63] = bm(38)+bm(62); d[4, 63] = bm(123); d[5, 63] = bm(146)
    d[1, 64] = d[1, 24]+bm(31); d[2, 64] = bm(39)+bm(63); d[4, 64] = bm(122); d[5, 64] = bm(147)

    # Nodes 64-71 (120-node stencil, sets 0, 1, 2, 3, 4)
    d[1, 65] = d[1, 57]; d[2, 65] = bm(40); d[3, 65] = bm(64);  d[4, 65] = bm(124); d[5, 65] = bm(140)
    d[1, 66] = d[1, 58]; d[2, 66] = bm(41); d[3, 66] = bm(65);  d[4, 66] = bm(125); d[5, 66] = bm(141)
    d[1, 67] = d[1, 59]; d[2, 67] = bm(42); d[3, 67] = bm(66);  d[4, 67] = bm(126); d[5, 67] = bm(142)
    d[1, 68] = d[1, 60]; d[2, 68] = bm(43); d[3, 68] = bm(67);  d[4, 68] = bm(127); d[5, 68] = bm(143)
    d[1, 69] = d[1, 61]; d[2, 69] = bm(44); d[3, 69] = bm(68);  d[4, 69] = bm(124); d[5, 69] = bm(144)
    d[1, 70] = d[1, 62]; d[2, 70] = bm(45); d[3, 70] = bm(69);  d[4, 70] = bm(125); d[5, 70] = bm(145)
    d[1, 71] = d[1, 63]; d[2, 71] = bm(46); d[3, 71] = bm(70);  d[4, 71] = bm(126); d[5, 71] = bm(146)
    d[1, 72] = d[1, 64]; d[2, 72] = bm(47); d[3, 72] = bm(71);  d[4, 72] = bm(127); d[5, 72] = bm(147)

    # Nodes 72-79 (sets 0, 1, 2, 3, 4)
    d[1, 73] = d[1, 49]; d[2, 73] = bm(32)+bm(48); d[3, 73] = bm(72);  d[4, 73] = bm(120); d[5, 73] = bm(128)+bm(132)+bm(148)
    d[1, 74] = d[1, 50]; d[2, 74] = bm(33)+bm(49); d[3, 74] = bm(73);  d[4, 74] = bm(121); d[5, 74] = bm(129)+bm(133)+bm(149)
    d[1, 75] = d[1, 51]; d[2, 75] = bm(34)+bm(50); d[3, 75] = bm(74);  d[4, 75] = bm(120); d[5, 75] = bm(128)+bm(132)+bm(148)
    d[1, 76] = d[1, 52]; d[2, 76] = bm(35)+bm(51); d[3, 76] = bm(75);  d[4, 76] = bm(121); d[5, 76] = bm(129)+bm(133)+bm(149)
    d[1, 77] = d[1, 53]; d[2, 77] = bm(36)+bm(52); d[3, 77] = bm(76);  d[4, 77] = bm(122); d[5, 77] = bm(130)+bm(134)+bm(150)
    d[1, 78] = d[1, 54]; d[2, 78] = bm(37)+bm(53); d[3, 78] = bm(77);  d[4, 78] = bm(123); d[5, 78] = bm(131)+bm(135)+bm(151)
    d[1, 79] = d[1, 55]; d[2, 79] = bm(38)+bm(54); d[3, 79] = bm(78);  d[4, 79] = bm(123); d[5, 79] = bm(131)+bm(135)+bm(151)
    d[1, 80] = d[1, 56]; d[2, 80] = bm(39)+bm(55); d[3, 80] = bm(79);  d[4, 80] = bm(122); d[5, 80] = bm(130)+bm(134)+bm(150)

    # Nodes 80-87 (sets 0, 1, 2, 3, 4)
    d[1, 81] = d[1, 41]; d[2, 81] = bm(40); d[3, 81] = bm(80);  d[4, 81] = bm(124); d[5, 81] = bm(136)+bm(152)
    d[1, 82] = d[1, 42]; d[2, 82] = bm(41); d[3, 82] = bm(81);  d[4, 82] = bm(125); d[5, 82] = bm(137)+bm(153)
    d[1, 83] = d[1, 43]; d[2, 83] = bm(42); d[3, 83] = bm(82);  d[4, 83] = bm(126); d[5, 83] = bm(138)+bm(154)
    d[1, 84] = d[1, 44]; d[2, 84] = bm(43); d[3, 84] = bm(83);  d[4, 84] = bm(127); d[5, 84] = bm(139)+bm(155)
    d[1, 85] = d[1, 45]; d[2, 85] = bm(44); d[3, 85] = bm(84);  d[4, 85] = bm(124); d[5, 85] = bm(136)+bm(152)
    d[1, 86] = d[1, 46]; d[2, 86] = bm(45); d[3, 86] = bm(85);  d[4, 86] = bm(125); d[5, 86] = bm(137)+bm(153)
    d[1, 87] = d[1, 47]; d[2, 87] = bm(46); d[3, 87] = bm(86);  d[4, 87] = bm(126); d[5, 87] = bm(138)+bm(154)
    d[1, 88] = d[1, 48]; d[2, 88] = bm(47); d[3, 88] = bm(87);  d[4, 88] = bm(127); d[5, 88] = bm(139)+bm(155)

    # Nodes 88-95 (sets 0, 1, 2, 3, 4, 5)
    d[1, 89] = d[1, 57]; d[2, 89] = bm(32)+bm(56); d[3, 89] = bm(64)+bm(88); d[4, 89] = bm(120); d[5, 89] = bm(140); d[6, 89] = bm(160)+bm(168)
    d[1, 90] = d[1, 58]; d[2, 90] = bm(33)+bm(57); d[3, 90] = bm(65)+bm(89); d[4, 90] = bm(121); d[5, 90] = bm(141); d[6, 90] = bm(161)+bm(169)
    d[1, 91] = d[1, 59]; d[2, 91] = bm(34)+bm(58); d[3, 91] = bm(66)+bm(90); d[4, 91] = bm(120); d[5, 91] = bm(142); d[6, 91] = bm(162)+bm(170)
    d[1, 92] = d[1, 60]; d[2, 92] = bm(35)+bm(59); d[3, 92] = bm(67)+bm(91); d[4, 92] = bm(121); d[5, 92] = bm(143); d[6, 92] = bm(163)+bm(171)
    d[1, 93] = d[1, 61]; d[2, 93] = bm(36)+bm(60); d[3, 93] = bm(68)+bm(92); d[4, 93] = bm(122); d[5, 93] = bm(144); d[6, 93] = bm(164)+bm(172)
    d[1, 94] = d[1, 62]; d[2, 94] = bm(37)+bm(61); d[3, 94] = bm(69)+bm(93); d[4, 94] = bm(123); d[5, 94] = bm(145); d[6, 94] = bm(165)+bm(173)
    d[1, 95] = d[1, 63]; d[2, 95] = bm(38)+bm(62); d[3, 95] = bm(70)+bm(94); d[4, 95] = bm(123); d[5, 95] = bm(146); d[6, 95] = bm(166)+bm(174)
    d[1, 96] = d[1, 64]; d[2, 96] = bm(39)+bm(63); d[3, 96] = bm(71)+bm(95); d[4, 96] = bm(122); d[5, 96] = bm(147); d[6, 96] = bm(167)+bm(175)

    # Nodes 96-103 (sets 0, 1, 2, 3, 4, 5)
    d[1, 97]  = d[1, 73]; d[2, 97]  = d[2, 49]; d[3, 97]  = bm(72); d[4, 97]  = bm(96)+bm(120);  d[5, 97]  = bm(128)+bm(132)+bm(148)+bm(156); d[6, 97]  = bm(176)+bm(184)
    d[1, 98]  = d[1, 74]; d[2, 98]  = d[2, 50]; d[3, 98]  = bm(73); d[4, 98]  = bm(97)+bm(121);  d[5, 98]  = bm(129)+bm(133)+bm(149)+bm(157); d[6, 98]  = bm(177)+bm(185)
    d[1, 99]  = d[1, 75]; d[2, 99]  = d[2, 51]; d[3, 99]  = bm(74); d[4, 99]  = bm(98)+bm(120);  d[5, 99]  = bm(128)+bm(132)+bm(148)+bm(156); d[6, 99]  = bm(176)+bm(186)
    d[1, 100] = d[1, 76]; d[2, 100] = d[2, 52]; d[3, 100] = bm(75); d[4, 100] = bm(99)+bm(121);  d[5, 100] = bm(129)+bm(133)+bm(149)+bm(157); d[6, 100] = bm(177)+bm(187)
    d[1, 101] = d[1, 77]; d[2, 101] = d[2, 53]; d[3, 101] = bm(76); d[4, 101] = bm(100)+bm(122); d[5, 101] = bm(130)+bm(134)+bm(150)+bm(158); d[6, 101] = bm(178)+bm(188)
    d[1, 102] = d[1, 78]; d[2, 102] = d[2, 54]; d[3, 102] = bm(77); d[4, 102] = bm(101)+bm(123); d[5, 102] = bm(131)+bm(135)+bm(151)+bm(159); d[6, 102] = bm(179)+bm(189)
    d[1, 103] = d[1, 79]; d[2, 103] = d[2, 55]; d[3, 103] = bm(78); d[4, 103] = bm(102)+bm(123); d[5, 103] = bm(131)+bm(135)+bm(151)+bm(159); d[6, 103] = bm(179)+bm(190)
    d[1, 104] = d[1, 80]; d[2, 104] = d[2, 56]; d[3, 104] = bm(79); d[4, 104] = bm(103)+bm(122); d[5, 104] = bm(130)+bm(134)+bm(150)+bm(158); d[6, 104] = bm(178)+bm(191)

    # Nodes 104-111 (sets 0, 1, 2, 3, 4, 5, 6)
    d[1, 105] = d[1, 57]; d[2, 105] = bm(40); d[3, 105] = bm(80); d[4, 105] = bm(104)+bm(124); d[5, 105] = bm(136)+bm(152); d[6, 105] = bm(180); d[7, 105] = bm(192)+bm(204)
    d[1, 106] = d[1, 58]; d[2, 106] = bm(41); d[3, 106] = bm(81); d[4, 106] = bm(105)+bm(125); d[5, 106] = bm(137)+bm(153); d[6, 106] = bm(181); d[7, 106] = bm(193)+bm(205)
    d[1, 107] = d[1, 59]; d[2, 107] = bm(42); d[3, 107] = bm(82); d[4, 107] = bm(106)+bm(126); d[5, 107] = bm(138)+bm(154); d[6, 107] = bm(182); d[7, 107] = bm(194)+bm(206)
    d[1, 108] = d[1, 60]; d[2, 108] = bm(43); d[3, 108] = bm(83); d[4, 108] = bm(107)+bm(127); d[5, 108] = bm(139)+bm(155); d[6, 108] = bm(183); d[7, 108] = bm(195)+bm(207)
    d[1, 109] = d[1, 61]; d[2, 109] = bm(44); d[3, 109] = bm(84); d[4, 109] = bm(108)+bm(124); d[5, 109] = bm(136)+bm(152); d[6, 109] = bm(180); d[7, 109] = bm(196)+bm(204)
    d[1, 110] = d[1, 62]; d[2, 110] = bm(45); d[3, 110] = bm(85); d[4, 110] = bm(109)+bm(125); d[5, 110] = bm(137)+bm(153); d[6, 110] = bm(181); d[7, 110] = bm(197)+bm(205)
    d[1, 111] = d[1, 63]; d[2, 111] = bm(46); d[3, 111] = bm(86); d[4, 111] = bm(110)+bm(126); d[5, 111] = bm(138)+bm(154); d[6, 111] = bm(182); d[7, 111] = bm(198)+bm(206)
    d[1, 112] = d[1, 64]; d[2, 112] = bm(47); d[3, 112] = bm(87); d[4, 112] = bm(111)+bm(127); d[5, 112] = bm(139)+bm(155); d[6, 112] = bm(183); d[7, 112] = bm(199)+bm(207)

    # Nodes 112-119 (sets 0, 1, 2, 3, 4, 5, 6, 7)
    d[1, 113] = d[1, 73]; d[2, 113] = bm(32)+bm(48); d[3, 113] = bm(72); d[4, 113] = bm(96)+bm(112)+bm(120); d[5, 113] = bm(128)+bm(132)+bm(148)+bm(156); d[6, 113] = bm(176)+bm(184); d[7, 113] = bm(200)+bm(208)+bm(212)+bm(220); d[8, 113] = bm(224)+bm(232)+bm(236)+bm(244)+bm(248)
    d[1, 114] = d[1, 74]; d[2, 114] = bm(33)+bm(49); d[3, 114] = bm(73); d[4, 114] = bm(97)+bm(113)+bm(121); d[5, 114] = bm(129)+bm(133)+bm(149)+bm(157); d[6, 114] = bm(177)+bm(185); d[7, 114] = bm(201)+bm(209)+bm(213)+bm(221); d[8, 114] = bm(225)+bm(233)+bm(237)+bm(245)+bm(249)
    d[1, 115] = d[1, 75]; d[2, 115] = bm(34)+bm(50); d[3, 115] = bm(74); d[4, 115] = bm(98)+bm(114)+bm(120); d[5, 115] = bm(128)+bm(132)+bm(148)+bm(156); d[6, 115] = bm(176)+bm(186); d[7, 115] = bm(200)+bm(208)+bm(214)+bm(220); d[8, 115] = bm(226)+bm(232)+bm(238)+bm(244)+bm(250)
    d[1, 116] = d[1, 76]; d[2, 116] = bm(35)+bm(51); d[3, 116] = bm(75); d[4, 116] = bm(99)+bm(115)+bm(121); d[5, 116] = bm(129)+bm(133)+bm(149)+bm(157); d[6, 116] = bm(177)+bm(187); d[7, 116] = bm(201)+bm(209)+bm(215)+bm(221); d[8, 116] = bm(227)+bm(233)+bm(239)+bm(245)+bm(251)
    d[1, 117] = d[1, 77]; d[2, 117] = bm(36)+bm(52); d[3, 117] = bm(76); d[4, 117] = bm(100)+bm(116)+bm(122); d[5, 117] = bm(130)+bm(134)+bm(150)+bm(158); d[6, 117] = bm(178)+bm(188); d[7, 117] = bm(202)+bm(210)+bm(216)+bm(222); d[8, 117] = bm(228)+bm(234)+bm(240)+bm(246)+bm(252)
    d[1, 118] = d[1, 78]; d[2, 118] = bm(37)+bm(53); d[3, 118] = bm(77); d[4, 118] = bm(101)+bm(117)+bm(123); d[5, 118] = bm(131)+bm(135)+bm(151)+bm(159); d[6, 118] = bm(179)+bm(189); d[7, 118] = bm(203)+bm(211)+bm(217)+bm(223); d[8, 118] = bm(229)+bm(235)+bm(241)+bm(247)+bm(253)
    d[1, 119] = d[1, 79]; d[2, 119] = bm(38)+bm(54); d[3, 119] = bm(78); d[4, 119] = bm(102)+bm(118)+bm(123); d[5, 119] = bm(131)+bm(135)+bm(151)+bm(159); d[6, 119] = bm(179)+bm(190); d[7, 119] = bm(203)+bm(211)+bm(218)+bm(223); d[8, 119] = bm(230)+bm(235)+bm(242)+bm(247)+bm(254)
    d[1, 120] = d[1, 80]; d[2, 120] = bm(39)+bm(55); d[3, 120] = bm(79); d[4, 120] = bm(103)+bm(119)+bm(122); d[5, 120] = bm(130)+bm(134)+bm(150)+bm(158); d[6, 120] = bm(178)+bm(191); d[7, 120] = bm(202)+bm(210)+bm(219)+bm(222); d[8, 120] = bm(231)+bm(234)+bm(243)+bm(246)+bm(255)
end

"""
Main wavefront propagation using Dijkstra-like algorithm with BST priority queue.
This is the heart of the TTT computation.

Follows the C t151398() function exactly:
- Uses a separate tt[] tracking array with sentinels (EXCLUDED/SETTLED/UNSEEN)
- Overwrites s[] (slowness) with travel time in hours when a node is settled
- Settled nodes become s[ij] >= 0, so stencil dependency checks flag them as "land",
  preventing stencil paths from crossing already-settled nodes.
"""
function propagate!(T::TTTState, p::Vector{Int}, D::DistanceArrays)
    h = T.header
    s = T.slowness
    do_normalize = T.normalize
    half_nx = h.nx ÷ 2
    wrap_limit = h.pixel_reg == 1 ? h.nx : h.nx - 1
    gridline_adj = h.pixel_reg == 1 ? 1 : 0
    secs_per_hour = 1.0 / 3600.0
    is_global_gridline_edge = h.is_global && h.pixel_reg == 0

    # Travel time tracking array (separate from slowness grid s[])
    tt = fill(UNSEEN_TT, T.mxy)

    # Mark padding, land, NaN, and global-gridline-edge nodes as excluded
    remaining = T.mxy
    edge_col = T.mx - TTT_PAD - 1   # rightmost non-pad column for gridline global grids
    for j in 0:T.my-1
        in_pad_y = j < TTT_PAD || j >= T.my - TTT_PAD
        for i in 0:T.mx-1
            k = j * T.mx + i + 1
            in_pad_x = i < TTT_PAD || i >= T.mx - TTT_PAD
            is_edge = is_global_gridline_edge && i == edge_col
            if in_pad_x || in_pad_y || is_edge || isnan(s[k])
                tt[k] = EXCLUDED_TT
                remaining -= 1
            end
        end
    end

    progress_scale = 100.0 / remaining

    # Initialize BST priority queue
    pq = BSTPriorityQueue()

    # Insert source nodes with travel time = 0
    for k in 1:T.n_sources
        idx = T.source_indices[k]
        tt[idx] == 0.0 && continue   # already inserted
        tt[idx] = 0.0
        bst_insert!(pq, 0.0, idx)
    end

    # Extract first minimum
    min_tt, ij = bst_find_min(pq)
    bst_delete!(pq, min_tt, ij)
    tt[ij] = SETTLED_TT

    # Stencil level cutoffs (matching C j340653[])
    nodes_to_use = T.n_nodes
    cutoffs = (min(16, nodes_to_use), min(32, nodes_to_use), min(64, nodes_to_use),
               min(88, nodes_to_use), min(104, nodes_to_use), min(112, nodes_to_use),
               min(120, nodes_to_use))
    n_dep_check = Int(ceil(T.n_stencil_used / 32.0))

    remaining -= 1
    settled_count = 1
    last_pct = 0

    while remaining > 0
        j0 = (ij - 1) ÷ T.mx - TTT_PAD    # 0-based row in unpadded grid
        i0 = (ij - 1) % T.mx - TTT_PAD     # 0-based col in unpadded grid

        # --- Build land/NaN bitmask for all stencil positions ---
        land_bits = zeros(UInt32, N_DEP_SETS)
        for bset in 0:n_dep_check-1
            for su in 0:31
                u = bset * 32 + su
                u >= N_STENCIL_TOTAL && break
                idx = ij + p[u + 1]
                if isnan(s[idx]) || s[idx] >= 0.0
                    land_bits[bset + 1] |= bitmask(u)
                end
            end
        end

        # --- Determine which stencil nodes are valid via dependency masks ---
        # Each stencil level requires progressively more dependency mask sets.
        # This matches the C code's 7-level switch/fallthrough.
        ok = falses(TTT_MAX_NODES)
        # Level 1: nodes 0..cutoffs[1]-1 — check set 0 only
        for u in 0:cutoffs[1]-1
            ok[u+1] = (land_bits[1] & T.dep_masks[1, u+1]) == 0
        end
        # Level 2: nodes cutoffs[1]..cutoffs[2]-1 — check sets 0,3
        for u in cutoffs[1]:cutoffs[2]-1
            ok[u+1] = (land_bits[1] & T.dep_masks[1, u+1]) == 0 &&
                       (land_bits[4] & T.dep_masks[4, u+1]) == 0
        end
        # Level 3: nodes cutoffs[2]..cutoffs[3]-1 — check sets 0,1,3,4
        for u in cutoffs[2]:cutoffs[3]-1
            ok[u+1] = (land_bits[1] & T.dep_masks[1, u+1]) == 0 &&
                       (land_bits[2] & T.dep_masks[2, u+1]) == 0 &&
                       (land_bits[4] & T.dep_masks[4, u+1]) == 0 &&
                       (land_bits[5] & T.dep_masks[5, u+1]) == 0
        end
        # Level 4: nodes cutoffs[3]..cutoffs[4]-1 — check sets 0,1,2,3,4
        for u in cutoffs[3]:cutoffs[4]-1
            ok[u+1] = (land_bits[1] & T.dep_masks[1, u+1]) == 0 &&
                       (land_bits[2] & T.dep_masks[2, u+1]) == 0 &&
                       (land_bits[3] & T.dep_masks[3, u+1]) == 0 &&
                       (land_bits[4] & T.dep_masks[4, u+1]) == 0 &&
                       (land_bits[5] & T.dep_masks[5, u+1]) == 0
        end
        # Level 5: nodes cutoffs[4]..cutoffs[5]-1 — check sets 0,1,2,3,4,5
        for u in cutoffs[4]:cutoffs[5]-1
            ok[u+1] = (land_bits[1] & T.dep_masks[1, u+1]) == 0 &&
                       (land_bits[2] & T.dep_masks[2, u+1]) == 0 &&
                       (land_bits[3] & T.dep_masks[3, u+1]) == 0 &&
                       (land_bits[4] & T.dep_masks[4, u+1]) == 0 &&
                       (land_bits[5] & T.dep_masks[5, u+1]) == 0 &&
                       (land_bits[6] & T.dep_masks[6, u+1]) == 0
        end
        # Level 6: nodes cutoffs[5]..cutoffs[6]-1 — check sets 0,1,2,3,4,5,6
        for u in cutoffs[5]:cutoffs[6]-1
            ok[u+1] = (land_bits[1] & T.dep_masks[1, u+1]) == 0 &&
                       (land_bits[2] & T.dep_masks[2, u+1]) == 0 &&
                       (land_bits[3] & T.dep_masks[3, u+1]) == 0 &&
                       (land_bits[4] & T.dep_masks[4, u+1]) == 0 &&
                       (land_bits[5] & T.dep_masks[5, u+1]) == 0 &&
                       (land_bits[6] & T.dep_masks[6, u+1]) == 0 &&
                       (land_bits[7] & T.dep_masks[7, u+1]) == 0
        end
        # Level 7: nodes cutoffs[6]..nodes_to_use-1 — check sets 0,1,2,3,4,5,6,7
        for u in cutoffs[6]:nodes_to_use-1
            ok[u+1] = (land_bits[1] & T.dep_masks[1, u+1]) == 0 &&
                       (land_bits[2] & T.dep_masks[2, u+1]) == 0 &&
                       (land_bits[3] & T.dep_masks[3, u+1]) == 0 &&
                       (land_bits[4] & T.dep_masks[4, u+1]) == 0 &&
                       (land_bits[5] & T.dep_masks[5, u+1]) == 0 &&
                       (land_bits[6] & T.dep_masks[6, u+1]) == 0 &&
                       (land_bits[7] & T.dep_masks[7, u+1]) == 0 &&
                       (land_bits[8] & T.dep_masks[8, u+1]) == 0
        end

        # --- Compute travel time increments dt[] for valid stencil nodes ---
        # dt[k] = distance * stencil_sum  (negative, because slowness has sign=-1)
        dt = zeros(Float64, TTT_MAX_NODES)
        for u in 0:nodes_to_use-1
            !ok[u+1] && continue
            ss = stencil_sum(s, ij, p, u)
            dist = stencil_distance(D, u, j0)
            dt[u+1] = Float64(dist * ss)
        end

        # --- Settle current node: overwrite slowness with travel time in hours ---
        # This is critical: C line 720: s[ij] = (float)(c451578 * f611458)
        s[ij] = Float32(secs_per_hour * min_tt)
        remaining -= 1

        # --- Update neighbors ---
        for k in 0:nodes_to_use-1
            !ok[k+1] && continue
            # Compute neighbor index with wrapping
            if h.is_global
                i_k = i0 + STENCIL_DI[k+1]
                if i_k < 0
                    i_k += wrap_limit
                elseif i_k >= h.nx
                    i_k -= wrap_limit
                end
                j_k = j0 - STENCIL_DJ[k+1]
                # Pole wrapping
                if h.has_north_pole && j_k < 0
                    j_k = gridline_adj - j_k
                    i_k = (i_k + half_nx) % h.nx
                elseif h.has_south_pole && j_k >= h.ny
                    j_k = 2 * h.ny - j_k - 2 + gridline_adj
                    i_k = (i_k + half_nx) % h.nx
                end
                kk = padded_index(i_k, j_k, T.mx, TTT_PAD)
            else
                kk = ij + p[k+1]
            end

            # Skip settled and excluded nodes (C: if (o378835[kk] > i634697) continue)
            tt[kk] > UNSEEN_TT && continue

            # Candidate travel time: C uses l959344 = f611458 - dt[k]
            # Since slowness is negative (sign=-1), dt[k] is negative,
            # so f611458 - dt[k] = f611458 + |dt[k]| = positive increment.
            candidate = min_tt - dt[k+1]

            if tt[kk] == UNSEEN_TT
                # First visit: insert into BST
                bst_insert!(pq, candidate, kk)
                tt[kk] = candidate
            elseif candidate < tt[kk]
                # Better path found: update BST
                bst_delete!(pq, tt[kk], kk)
                bst_insert!(pq, candidate, kk)
                tt[kk] = candidate
            end
        end

        # --- Get next minimum ---
        if bst_isempty(pq)
            remaining > 0 && @warn "TTT: $remaining landlocked nodes not reached"
            remaining = 0
        else
            min_tt, ij = bst_find_min(pq)
            bst_delete!(pq, min_tt, ij)
            tt[ij] = SETTLED_TT
        end

        # Progress reporting
        if T.verbose > 0
            settled_count += 1
            pct = round(Int, progress_scale * settled_count)
            if pct != last_pct
                @printf(stderr, "TTT: Completed %3d %%\r", pct)
                last_pct = pct
            end
        end
    end

    # Settle the last extracted node (C line 782: if (ij >= 0) s[ij] = ...)
    if ij >= 1
        s[ij] = Float32(secs_per_hour * min_tt)
    end

    # Handle global gridline edge column: copy from first column (C line 783-785)
    # For gridline registration, east edge == west edge. Copy i=0 to i=nx-1.
    if is_global_gridline_edge
        for j in 0:T.my-1
            k = j * T.mx   # 0-based row start (matching C)
            s[k + edge_col + 1] = s[k + TTT_PAD + 1]   # +1 for Julia 1-based indexing
        end
    end

    if T.verbose > 0
        @printf(stderr, "TTT: Completed %3d %%.\n", last_pct)
    end

    # Normalization factor: sin(2π/N) / (2π/N)
    f = 2π / T.n_nodes
    norm_factor = sqrt(sin(f) / f)
    if do_normalize && T.verbose > 0
        @printf(stderr, "TTT: Normalization factor = %g.\n", norm_factor)
    end

    if T.verbose > 0
        t = secs_per_hour * min_tt
        hr = floor(Int, t)
        mi = floor(Int, (t - hr) * 60.0)
        ss = floor(Int, (t - hr - mi / 60.0) * 3600.0)
        @printf(stderr, "TTT: Maximum travel time = %d:%2.2d:%2.2d.\n", hr, mi, ss)
    end

    # Post-processing: normalize settled nodes, mark unreachable as NaN
    # (C lines 798-813)
    for j in 0:h.ny-1
        for i in 0:h.nx-1
            k = padded_index(i, j, T.mx, TTT_PAD)
            isnan(s[k]) && continue
            if s[k] < 0.0
                # Still has negative slowness → not reached by wavefront → NaN
                s[k] = Float32(NaN)
            elseif do_normalize
                # Settled node with travel time → apply normalization
                s[k] *= Float32(norm_factor)
            end
        end
    end

    return TTT_SUCCESS
end

"""Copy padded grid values back to output array."""
function copy_to_output!(T::TTTState, z::Vector{Float32})
    h = T.header
    for j in 0:h.ny-1
        for i in 0:h.nx-1
            from = padded_index(i, j, T.mx, TTT_PAD)
            to = j * h.nx + i + 1
            z[to] = T.slowness[from]
        end
    end
end

# ──────────────────── Public API ────────────────────

"""
    calc_ttt!(wesn, dims, registration, z, quake, params)

Calculate tsunami travel times from source(s) to all grid points.
- `wesn`: [west, east, south, north]
- `dims`: [nx, ny, prime_dim]
- `registration`: 0=pixel, 1=gridline
- `z`: bathymetry array (Float32), modified in-place to contain travel times
- `quake`: TTTquake struct with source location(s)
- `params`: [n_nodes, search, search_radius, source_depth, ignore_bias, verbose, -, depth_threshold]
"""
function calc_ttt!(wesn, dims, registration, z::Vector{Float32}, quake::TTTquake, params)
    T = TTTState()
    err = parse_params!(T, params)
    err != TTT_SUCCESS && return err
    err = load_bathymetry!(T, wesn, dims, registration, z)
    err != TTT_SUCCESS && return err
    err = check_sources!(T, quake.n_sources, quake.lon, quake.lat)
    err != TTT_SUCCESS && return err

    # Compute
    T.verbose > 0 && @info "TTT: Calculate slowness."
    depth_to_slowness!(T.header, T.slowness, -1.0, T.depth_threshold)

    T.verbose > 0 && @info "TTT: Initialize stencil offsets."
    p = setup_stencil_offsets(T)
    init_dep_masks!(T)
    D = compute_distances(T)

    T.verbose > 0 && @info "TTT: Calculate travel times."
    err = propagate!(T, p, D)
    err != TTT_SUCCESS && return err

    copy_to_output!(T, z)

    # Compute slope at source
    if quake.n_sources == 1
        lon = quake.lon[1]
        while lon > T.header.west; lon -= 360.0; end
        while lon < T.header.west; lon += 360.0; end
        col = lon_to_col(lon, T.header.west, T.header.dx, T.header.xy_off, T.header.nx)
        row = lat_to_row(quake.lat[1], T.header.south, T.header.dy, T.header.xy_off, T.header.ny)
        quake.ttt_slope = compute_slope(T.header, dims[1], z, col, row)
        params[7] = quake.ttt_slope
    else
        params[7] = NaN
    end
    return TTT_SUCCESS
end

"""
    calc_eta!(wesn, dims, registration, ttt, depth, zdepth, n_sites, eta)

Calculate estimated times of arrival at station sites.
"""
function calc_eta!(wesn, dims, registration, ttt::Vector{Float32},
                   depth::Union{Vector{Float32}, Nothing}, zdepth::Float64,
                   n_sites::Int, eta::Vector{TTTeta})
    h = TTThdr()
    err = init_header!(h, wesn, dims, registration)
    err != TTT_SUCCESS && return err

    do_depth_search = !isnothing(depth)

    for k in 1:n_sites
        (eta[k].lat < h.south || eta[k].lat > h.north) && return TTT_ERROR_STATION_OUTSIDE
        lon = eta[k].lon
        while lon > h.west; lon -= 360.0; end
        while lon < h.west; lon += 360.0; end
        lon > h.east && return TTT_ERROR_STATION_OUTSIDE

        col = lon_to_col(lon, h.west, h.dx, h.xy_off, h.nx)
        row = lat_to_row(eta[k].lat, h.south, h.dy, h.xy_off, h.ny)
        ij = row * h.nx + col + 1

        if do_depth_search || isnan(ttt[ij])
            # Search for nearest valid node
            search_r = max(SEARCH_S_RADIUS, 2.0 * h.dx)
            dx_deg = h.dx * cos(D2R * eta[k].lat)
            i_lo = max(0, col - ceil(Int, search_r / dx_deg))
            i_hi = min(h.nx - 1, col + ceil(Int, search_r / dx_deg))
            j_lo = max(0, row - ceil(Int, search_r / h.dy))
            j_hi = min(h.ny - 1, row + ceil(Int, search_r / h.dy))
            best_dist = 180.0
            x0 = y0 = 0.0
            for j in j_lo:j_hi
                y = row_to_lat(j, h.south, h.north, h.dy, h.xy_off, h.ny)
                for i in i_lo:i_hi
                    ij2 = j * h.nx + i + 1
                    isnan(ttt[ij2]) && continue
                    if do_depth_search && (isnan(depth[ij2]) || depth[ij2] >= zdepth)
                        continue
                    end
                    x = col_to_lon(i, h.west, h.east, h.dx, h.xy_off, h.nx)
                    d = spherical_distance(eta[k].lon, eta[k].lat, x, y)
                    if d < best_dist
                        ij = ij2; x0 = x; y0 = y
                        col = i; row = j
                        best_dist = d
                    end
                end
            end
            if best_dist == 180.0
                @warn "Station $(eta[k].text) exceeds max distance, no TTTeta"
                eta[k].ttt = eta[k].dist = eta[k].slope = NaN
                continue
            end
            if do_depth_search; eta[k].depth = depth[ij]; end
            eta[k].lon2 = x0; eta[k].lat2 = y0
        else
            x0 = col_to_lon(col, h.west, h.east, h.dx, h.xy_off, h.nx)
            y0 = row_to_lat(row, h.south, h.north, h.dy, h.xy_off, h.ny)
            best_dist = spherical_distance(eta[k].lon, eta[k].lat, x0, y0)
        end

        best_dist < 1e-5 && (best_dist = 0.0)
        best_dist *= DEG_TO_KM

        # Bilinear interpolation over the cell that actually contains the station.
        # NOTE: (col,row) is the NEAREST node (lon_to_col/lat_to_row round), so the station may lie
        # on either side of it and fx,fy are in [-0.5,0.5]. Pick the neighbours by the sign of the
        # offset and weight with |fx|,|fy|; using ij+1 / ij-h.nx unconditionally would extrapolate.
        fx = (lon - x0) / h.dx
        fy = (eta[k].lat - y0) / h.dy
        afx = abs(fx);        afy = abs(fy)
        di  = (fx >= 0) ? 1 : -1                 # +1 = node to the east
        dj  = (fy >= 0) ? -h.nx : h.nx           # rows run north->south, so north is -nx
        ci  = col + di
        rj  = row + ((fy >= 0) ? -1 : 1)
        can_i = 0 <= ci <= h.nx - 1
        can_j = 0 <= rj <= h.ny - 1
        wsum = tsum = 0.0
        if !isnan(ttt[ij]); w = (1.0-afx)*(1.0-afy); tsum += w*ttt[ij]; wsum += w; end
        if can_i && !isnan(ttt[ij+di]); w = afx*(1.0-afy); tsum += w*ttt[ij+di]; wsum += w; end
        if can_j && !isnan(ttt[ij+dj]); w = (1.0-afx)*afy; tsum += w*ttt[ij+dj]; wsum += w; end
        if can_i && can_j && !isnan(ttt[ij+di+dj]); w = afx*afy; tsum += w*ttt[ij+di+dj]; wsum += w; end

        if wsum == 0.0
            @warn "Station $(eta[k].text) has NaN travel times"
            eta[k].ttt = eta[k].dist = eta[k].slope = NaN
        else
            eta[k].ttt = tsum / wsum
            eta[k].dist = best_dist
            eta[k].slope = compute_slope(h, h.nx, ttt, col, row)
        end
    end
    sort!(eta, by=e -> isnan(e.ttt) ? Inf : e.ttt)
    return TTT_SUCCESS
end

"""Return TTT API version string."""
function ttt_version()
    return "ttt API version $TTT_VERSION compiled for Julia Float64 precision"
end

"""Print error message for a TTT error code."""
function ttt_message(prefix::String, err::TTTError)
    msg = Dict(
        TTT_ERROR_BAD_NODES => "Nodes not 8|16|32|48|64|120!",
        TTT_ERROR_WESN_CHECK => "West, east, south, and north not in proper order!",
        TTT_ERROR_DIM_CHECK => "Grid nodes zero or negative!",
        TTT_ERROR_INC_CHECK => "Grid increment is <= 0!",
        TTT_ERROR_NO_SOURCE => "No epicenter(s) given!",
        TTT_ERROR_SOURCE_LAND => "Epicenter lies on land!",
        TTT_ERROR_SOURCE_OUTSIDE => "Epicenter lies outside selected region!",
        TTT_ERROR_SOURCE_BAD_SEARCH => "Unable to relocate epicenter to nearest deep water node!",
        TTT_ERROR_BAD_RADIUS => "Search radius is negative!",
        TTT_ERROR_BAD_DEPTH => "Epicenter depth threshold is above sealevel!",
        TTT_ERROR_STATION_OUTSIDE => "Station location outside selected region!",
        TTT_ERROR_BAD_MINDEPTH => "Shallow depth threshold is above sealevel!",
        TTT_ERROR_BAD_VERBOSITY => "Verbosity level is negative!"
    )
    m = get(msg, err, "Unknown error code!")
    error("$prefix: [err=$(Int(err))] $m")
end

# ──────────────────── GMT.jl public API ────────────────────
# Grid in, grid out. No file I/O, no out-params, no error codes leaking to the user.

"""
    Gtt = ttt(G::GMTgrid, source; nodes=120, search=false, search_radius=0.0,
              source_depth=0.0, min_depth=0.0, bias=true, verbose=0)

Compute tsunami travel times from `source` over the bathymetry grid `G`, using Wessel's
Huygens/Dijkstra wavefront construction (`ttt` API 4.0.1).

- `G`: GMTgrid with bathymetry in meters, z positive up (land > 0, ocean < 0).
- `source`: `(lon,lat)`, `[lon lat]`, or an Mx2 matrix for several source points.
- `nodes`: size of the Huygens stencil, one of 8, 16, 32, 48, 64, 120. More nodes = more
  accurate but slower.
- `search`: if `true`, relocate a source that falls on land to the nearest water node.
- `search_radius`: max search distance in degrees used when `search=true`.
- `source_depth`: source must be at least this deep (meters, <= 0).
- `min_depth`: shallow-water depth threshold (meters, <= 0).
- `bias`: apply the wavefront bias correction (default `true`).
- `verbose`: 0 = quiet.

Returns a GMTgrid of travel times in **hours** (NaN on land and where the wave does not reach).
The travel-time gradient at the source (sec/km) is stored in the `remark` field.

### Example
```julia
G = gmtread("@earth_relief_10m", region=(-100,-60,-40,0));
Gtt = ttt(G, (-75.0, -15.0))
viz(Gtt, contour=true, colorbar=true, coast=true)
```

See also [`tttimes`](@ref), [`wave_travel_time`](@ref).
"""
function ttt(G::GMTgrid, source; nodes::Int=120, search::Bool=false, search_radius=0.0,
             source_depth=0.0, min_depth=0.0, bias::Bool=true, verbose::Int=0)
    lons, lats = ttt_parse_source(source)
    q = TTTquake(); q.lon = lons; q.lat = lats; q.n_sources = length(lons)

    nx = length(G.x) - G.registration
    ny = length(G.y) - G.registration
    z, flip_y = grid2rowmajor_north(G, nx, ny)

    wesn = Float64[G.range[1], G.range[2], G.range[3], G.range[4]]
    dims = Int[nx, ny, nx]
    # GMT registration is 0=gridline, 1=pixel; the TTT core wants the opposite. Convert HERE,
    # once, so no caller has to know about it.
    reg  = (G.registration == 0) ? 1 : 0
    params = Float64[nodes, search ? 1 : 0, search_radius, source_depth,
                     bias ? 0 : 1, verbose, 0.0, min_depth]

    err = calc_ttt!(wesn, dims, reg, z, q, params)
    (err != TTT_SUCCESS) && ttt_message("ttt", err)

    Gtt = rowmajor_north2grid(G, z, nx, ny, flip_y, "ttt")
    Gtt.remark = isnan(params[7]) ? "Hours from source" :
                 @sprintf("Hours from source; slope at source = %.4g sec/km", params[7])
    return Gtt
end

# --------------------------------------------------------------------------
"""
    D = tttimes(Gtt::GMTgrid, stations; names=String[], origin=DateTime(0), utc=false,
                Gdepth=nothing, max_depth=0.0)

Estimated times of arrival at `stations`, read off the travel-time grid `Gtt` returned by
[`ttt`](@ref).

- `stations`: `(lon,lat)` or an Mx2 matrix of station coordinates.
- `names`: optional station names, one per row of `stations`.
- `origin`: earthquake origin time. When given, arrival times are absolute instead of elapsed.
- `utc`: label the arrival column as UTC.
- `Gdepth`: optional bathymetry grid; when given, each station is snapped to the nearest node
  deeper than `max_depth`.
- `max_depth`: depth threshold (meters, negative down) used with `Gdepth`.

Returns a GMTdataset sorted by arrival time, with columns `lat, lon, ttt_hours, dist_km, slope_s_km`
(plus `depth_m` when `Gdepth` is given) and the station name + arrival time as text.
Write it with `gmtwrite`, or just display it.

### Example
```julia
Gtt = ttt(G, (-75.0, -15.0));
D = tttimes(Gtt, [-77.0 -12.0; -70.9 -53.1], names=["Callao", "Punta Arenas"])
```
"""
function tttimes(Gtt::GMTgrid, stations; names::Vector{String}=String[], origin::DateTime=DateTime(0),
                 utc::Bool=false, Gdepth=nothing, max_depth=0.0)
    slon, slat = ttt_parse_source(stations)
    n = length(slon)
    (!isempty(names) && length(names) != n) &&
        error("tttimes: got $(length(names)) names for $n stations.")

    nx = length(Gtt.x) - Gtt.registration
    ny = length(Gtt.y) - Gtt.registration
    tt, _ = grid2rowmajor_north(Gtt, nx, ny)

    dep = nothing
    if (Gdepth !== nothing)
        (length(Gdepth.x) - Gdepth.registration != nx || length(Gdepth.y) - Gdepth.registration != ny) &&
            error("tttimes: the 'Gdepth' grid must have the same size as the travel time grid.")
        dep, _ = grid2rowmajor_north(Gdepth, nx, ny)
    end

    eta = [TTTeta() for _ = 1:n]
    for k = 1:n
        eta[k].lon = slon[k];    eta[k].lat = slat[k]
        eta[k].text = isempty(names) ? "" : names[k]
    end

    wesn = Float64[Gtt.range[1], Gtt.range[2], Gtt.range[3], Gtt.range[4]]
    dims = Int[nx, ny, nx]
    reg  = (Gtt.registration == 0) ? 1 : 0		# GMT -> TTT convention (see ttt())
    err  = calc_eta!(wesn, dims, reg, tt, dep, Float64(max_depth), n, eta)
    (err != TTT_SUCCESS) && ttt_message("tttimes", err)

    return eta2ds(eta, origin, utc)
end

# --------------------------------------------------------------------------
"""Accept (lon,lat), [lon lat] or an Mx2 matrix and return two Float64 vectors."""
function ttt_parse_source(source)::Tuple{Vector{Float64}, Vector{Float64}}
    if (isa(source, Tuple))
        return Float64[source[1]], Float64[source[2]]
    elseif (isa(source, GMTdataset))
        return Float64.(source.data[:,1]), Float64.(source.data[:,2])
    elseif (isa(source, AbstractMatrix))
        (size(source,2) < 2) && error("Source/station matrix must have at least 2 columns (lon, lat).")
        return Float64.(source[:,1]), Float64.(source[:,2])
    elseif (isa(source, AbstractVector))
        (length(source) < 2) && error("Source/station vector must have 2 elements (lon, lat).")
        return Float64[source[1]], Float64[source[2]]
    end
    error("Don't know how to use a $(typeof(source)) as a source/station location.")
end

# --------------------------------------------------------------------------
"""Turn the solved TTTeta vector into a GMTdataset (replaces the old save_eta())."""
function eta2ds(eta::Vector{TTTeta}, origin::DateTime, utc::Bool)
    has_origin = origin != DateTime(0)
    has_depth  = any(e -> e.depth != 0.0, eta)
    n = length(eta)

    ncols = has_depth ? 6 : 5
    mat = Matrix{Float64}(undef, n, ncols)
    texts = Vector{String}(undef, n)

    for (k, e) in enumerate(eta)
        # lon2/lat2 are only set when the station was snapped to another node
        moved = (e.lon2 != 0.0 || e.lat2 != 0.0)
        mat[k,1] = moved ? e.lat2 : e.lat
        mat[k,2] = moved ? e.lon2 : e.lon
        mat[k,3] = e.ttt					# travel time in hours (NaN if unreachable)
        mat[k,4] = e.dist
        mat[k,5] = e.slope
        has_depth && (mat[k,6] = e.depth)

        name = isempty(e.text) ? "N/A" : e.text
        if isnan(e.ttt)
            arr = "N/A"
        elseif !has_origin
            hr = floor(Int, e.ttt)
            mi = floor(Int, (e.ttt - hr) * 60)
            ss = floor(Int, ((e.ttt - hr) * 60 - mi) * 60)
            arr = @sprintf("%2dh %02dm %02ds", hr, mi, ss)
        else
            arr = Dates.format(origin + Second(round(Int, e.ttt * 3600.0)), "e u dd HH:MM:SS yyyy")
        end
        texts[k] = name * " | " * arr
    end

    D = mat2ds(mat, txtcol=texts)
    D.colnames = has_depth ? ["lat", "lon", "ttt_hours", "dist_km", "slope_s_km", "depth_m"] :
                             ["lat", "lon", "ttt_hours", "dist_km", "slope_s_km"]
    D.comment = [has_origin ? "Station | $(utc ? "UTC " : "")arrival time" : "Station | elapsed time"]
    return D
end
