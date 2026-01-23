"""
    fourcolors(polys; groupby="", colors=["red", "green", "blue", "yellow"], index=false, kw...) -> Vector{Int}

Apply graph coloring to assign colors to polygons such that no two adjacent polygons share the same color.

### Arguments
- `polys`: Vector of GMTdataset polygons, or a filename with polygons.

### Keywords
- `groupby`: Attribute name to group polygons (e.g., country code). All polygons with the same
             attribute value get the same color. Use `""` to treat each polygon independently.
             Default: "CODE"
- `ncolors`: Number of colors to use. Default: 4 (four color theorem). Use more for fewer regions
             (e.g., 7 for continents) to get distinct colors for each.
- `colors`: Vector of color names or RGB tuples. Default: ["red", "green", "blue", "yellow"]
            If `ncolors` > length(colors), colors will cycle.
- `index`: If true, return only the color indices without plotting. Default: false
- `kw...`: Additional keyword arguments passed to `plot` for visualization.

### Returns
- Nothing if `index=false`. Otherwise, return `Vector{Int}`: Color indices (1-ncolors) for each polygon.

### Example
```julia
# Color countries with 4 colors (sufficient for any map)
polys = coast(region=:europe, dump=true, dcw="AT,DE,FR,IT,ES,PT,CH,BE,NL,PL,CZ")
fourcolors(polys, groupby="CODE")

# Color continents with 7 distinct colors
continents = ...  # 7 continent polygons
fourcolors(continents, ncolors=7, colors=["red","orange","yellow","green","blue","purple","brown"])
```
"""
function fourcolors(polys; index=false, groupby="CODE", ncolors::Int=4, colors=["red", "green", "blue", "yellow"], kw...)
	D = isa(polys, String) ? gmtread(polys) : polys
	!isa(D, Vector{GMTdataset}) || length(D) <= 1 && error("Input must be a vector of GMTdataset polygons or a filename")
	(index == 1) && return fourcolorsindex(D; groupby=groupby, ncolors=ncolors)
	nc = max(ncolors, length(colors))  # Use at least as many colors as provided
	c = join(colors, ",")
	(count_chars(c, ',') < 4) && error("At least four colors must be provided for four color theorem")
	_fourcolors(D, groupby, nc, c, kw...)
end
function _fourcolors(D, groupby, ncolors, colors, kw...)
	color_idx = fourcolorsindex(D; groupby=groupby, ncolors=ncolors)
	C = makecpt(T=(1, ncolors), C=colors)
	plot(D; level=color_idx, cmap=C, kw...)
end


# -------------------------------------------------------------------------------------------------------
function fourcolorsindex(polys, gb=""; groupby="", ncolors::Int=4)
	D = isa(polys, String) ? gmtread(polys) : polys
	!isa(D, Vector{GMTdataset}) || length(D) <= 1 && error("Input must be a vector of GMTdataset polygons or a filename")
	_gb = (groupby !== "") ? groupby : gb		# May use either positional or keyword argument. Later takes precedence
	_fourcolorsindex(D, string(_gb), ncolors)
end

function _fourcolorsindex(polys, groupby, ncolors::Int)

	if groupby === ""					# No grouping - each polygon is independent
		adj = _build_adjacency(polys)
		coloring = _color_graph(adj, ncolors)

	else								# Group polygons by attribute
		groups = Dict{String, Vector{Int}}()
		n = length(polys)
		for i in 1:n
			key = get(polys[i].attrib, groupby, "UNKNOWN_$i")
			if !haskey(groups, key)
				groups[key] = Int[]
			end
			push!(groups[key], i)
		end

		group_keys = collect(keys(groups))
		ngroups = length(group_keys)

		# Build adjacency matrix at group level
		adj = _build_adjacency_grouped(polys, groups, group_keys)

		# Use min(ncolors, ngroups) - no need for more colors than groups
		actual_colors = min(ncolors, ngroups)
		group_coloring = _color_graph(adj, actual_colors)

		# Map group colors back to polygons
		coloring = zeros(Int, n)
		for (gi, key) in enumerate(group_keys)
			for pi in groups[key]
				coloring[pi] = group_coloring[gi]
			end
		end
	end

	return coloring
end


# Check if two bounding boxes overlap
function _bbox_overlap(bb1::Vector{Float64}, bb2::Vector{Float64})
	# bbox format: [xmin, xmax, ymin, ymax, ...]
	((bb1[2] < bb2[1]) || (bb2[2] < bb1[1]) || (bb1[4] < bb2[3]) || (bb2[4] < bb1[3])) ? false : true
end

# -------------------------------------------------------------------------------------------------------
# Build adjacency matrix from polygons (no grouping)
function _build_adjacency(polys)
	n = length(polys)
	adj = falses(n, n)

	bboxes = [p.bbox for p in polys]

	@inbounds for i in 1:n-1
		@inbounds for j in i+1:n
			!_bbox_overlap(bboxes[i], bboxes[j]) && continue
			if _polygons_adjacent(polys[i], polys[j])
				adj[i, j] = adj[j, i] = true
			end
		end
	end
	return adj
end

# -------------------------------------------------------------------------------------------------------
# Build adjacency matrix at group level
function _build_adjacency_grouped(polys, groups::Dict{String, Vector{Int}}, group_keys::Vector{String})
	ngroups = length(group_keys)
	adj = falses(ngroups, ngroups)

	# Pre-extract bboxes
	bboxes = [p.bbox for p in polys]

	# For each pair of groups, check if any of their polygons are adjacent
	@inbounds for gi in 1:ngroups-1
		polys_i = groups[group_keys[gi]]
		@inbounds for gj in gi+1:ngroups
			polys_j = groups[group_keys[gj]]
			found = false
			@inbounds for pi in polys_i
				found && break
				@inbounds for pj in polys_j
					!_bbox_overlap(bboxes[pi], bboxes[pj]) && continue
					if _polygons_adjacent(polys[pi], polys[pj])
						adj[gi, gj] = adj[gj, gi] = true
						found = true
						break
					end
				end
			end
		end
	end
	return adj
end

# -------------------------------------------------------------------------------------------------------
# Check if two polygons are adjacent (share an edge, not just a point)
# Uses spatial hashing for O(n1 + n2) instead of O(n1 * n2)
function _polygons_adjacent(p1::GMTdataset, p2::GMTdataset)
	x1, y1 = view(p1.data, :, 1), view(p1.data, :, 2)
	x2, y2 = view(p2.data, :, 1), view(p2.data, :, 2)
	n1, n2 = length(x1), length(x2)

	# Grid cell size based on bbox (tolerance for snapping)
	bb = p1.bbox
	cell = length(bb) >= 4 ? 0.0001 * sqrt((bb[2]-bb[1])^2 + (bb[4]-bb[3])^2) : 1e-6
	cell = max(cell, 1e-10)
	inv_cell = 1.0 / cell

	# Build hash table of polygon 2 vertices (discretized to grid cells)
	p2_cells = Dict{Tuple{Int,Int}, Bool}()
	@inbounds for j in 1:n2
		key = (round(Int, x2[j] * inv_cell), round(Int, y2[j] * inv_cell))
		p2_cells[key] = true
	end

	# Find vertices in polygon 1 that match polygon 2 (check cell and 8 neighbors)
	shared_1 = Int[]
	@inbounds for i in 1:n1
		cx, cy = round(Int, x1[i] * inv_cell), round(Int, y1[i] * inv_cell)
		found = false
		for dx in -1:1
			found && break
			for dy in -1:1
				if haskey(p2_cells, (cx + dx, cy + dy))
					push!(shared_1, i)
					found = true
					break
				end
			end
		end
	end

	length(shared_1) < 2 && return false

	# Check for consecutive indices (shared edge)
	sort!(shared_1)
	@inbounds for i in 1:length(shared_1)-1
		shared_1[i+1] - shared_1[i] == 1 && return true
	end
	# Check wrap-around
	(shared_1[1] == 1 && shared_1[end] == n1) && return true
	return false
end

# -------------------------------------------------------------------------------------------------------
# Graph coloring using greedy algorithm (iterative, no recursion)
# Distributes colors evenly by preferring less-used colors
function _color_graph(adj::BitMatrix, max_colors::Int)
	n = size(adj, 1)
	coloring = zeros(Int, n)
	color_count = zeros(Int, max_colors)  # Track usage of each color

	# Sort nodes by degree (most connected first)
	degrees = [sum(adj[i, :]) for i in 1:n]
	order = sortperm(degrees, rev=true)

	# Color each node in order
	for node in order
		# Find colors used by neighbors
		used = falses(max_colors)
		for j in 1:n
			if adj[node, j] && coloring[j] > 0
				used[coloring[j]] = true
			end
		end

		# Find available colors and pick the least used one
		assigned = false
		best_color = 0
		best_count = typemax(Int)
		for c in 1:max_colors
			if !used[c] && color_count[c] < best_count
				best_color = c
				best_count = color_count[c]
			end
		end

		if best_color > 0
			coloring[node] = best_color
			color_count[best_color] += 1
			assigned = true
		end

		# If no color available, try to recolor a neighbor
		if !assigned
			for c in 1:max_colors
				for j in 1:n
					if adj[node, j] && coloring[j] == c
						neighbor_used = falses(max_colors)
						for k in 1:n
							if adj[j, k] && coloring[k] > 0 && k != node
								neighbor_used[coloring[k]] = true
							end
						end
						for c2 in 1:max_colors
							if c2 != c && !neighbor_used[c2]
								color_count[coloring[j]] -= 1
								coloring[j] = c2
								color_count[c2] += 1
								coloring[node] = c
								color_count[c] += 1
								assigned = true
								break
							end
						end
						assigned && break
					end
				end
				assigned && break
			end
		end

		!assigned && error("Could not color node $node with $max_colors colors")
	end

	return coloring
end
