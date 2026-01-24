@testset "FOURCOLORS" begin

	println("	FOURCOLORS")

	# Test _bbox_overlap
	bb1 = [0.0, 10.0, 0.0, 10.0]
	bb2 = [5.0, 15.0, 5.0, 15.0]   # overlaps with bb1
	bb3 = [20.0, 30.0, 0.0, 10.0]  # no overlap (right of bb1)
	bb4 = [0.0, 10.0, 20.0, 30.0]  # no overlap (above bb1)

	@test GMT._bbox_overlap(bb1, bb2) == true
	@test GMT._bbox_overlap(bb1, bb3) == false
	@test GMT._bbox_overlap(bb1, bb4) == false
	@test GMT._bbox_overlap(bb2, bb3) == false

	# Test _color_graph with simple cases
	# Two disconnected nodes - should get different colors (balanced distribution)
	adj2 = falses(2, 2)
	colors2 = GMT._color_graph(adj2, 4)
	@test length(colors2) == 2
	@test all(1 .<= colors2 .<= 4)

	# Two connected nodes - must have different colors
	adj2_conn = falses(2, 2)
	adj2_conn[1,2] = adj2_conn[2,1] = true
	colors2_conn = GMT._color_graph(adj2_conn, 4)
	@test colors2_conn[1] != colors2_conn[2]

	# Triangle (3 nodes all connected) - needs 3 different colors
	adj3 = trues(3, 3)
	for i in 1:3
		adj3[i,i] = false
	end
	colors3 = GMT._color_graph(adj3, 4)
	@test length(unique(colors3)) == 3

	# Square (4 nodes in cycle) - only needs 2 colors
	adj4 = falses(4, 4)
	adj4[1,2] = adj4[2,1] = true
	adj4[2,3] = adj4[3,2] = true
	adj4[3,4] = adj4[4,3] = true
	adj4[4,1] = adj4[1,4] = true
	colors4 = GMT._color_graph(adj4, 4)
	@test colors4[1] != colors4[2]
	@test colors4[2] != colors4[3]
	@test colors4[3] != colors4[4]
	@test colors4[4] != colors4[1]

	# Complete graph K4 (4 nodes all connected) - needs exactly 4 colors
	adj4_complete = trues(4, 4)
	for i in 1:4
		adj4_complete[i,i] = false
	end
	colors4_complete = GMT._color_graph(adj4_complete, 4)
	@test length(unique(colors4_complete)) == 4

	# Test _polygons_adjacent with synthetic polygons
	# Two adjacent squares sharing an edge
	p1 = GMT.GMTdataset(data=[0.0 0.0; 1.0 0.0; 1.0 1.0; 0.0 1.0; 0.0 0.0], bbox=[0.0, 1.0, 0.0, 1.0])
	p2 = GMT.GMTdataset(data=[1.0 0.0; 2.0 0.0; 2.0 1.0; 1.0 1.0; 1.0 0.0], bbox=[1.0, 2.0, 0.0, 1.0])
	@test GMT._polygons_adjacent(p1, p2) == true

	# Two squares sharing only a corner (not adjacent)
	p3 = GMT.GMTdataset(data=[1.0 1.0; 2.0 1.0; 2.0 2.0; 1.0 2.0; 1.0 1.0], bbox=[1.0, 2.0, 1.0, 2.0])
	@test GMT._polygons_adjacent(p1, p3) == false

	# Two completely separate squares
	p4 = GMT.GMTdataset(data=[5.0 5.0; 6.0 5.0; 6.0 6.0; 5.0 6.0; 5.0 5.0], bbox=[5.0, 6.0, 5.0, 6.0])
	@test GMT._polygons_adjacent(p1, p4) == false

	# Test _build_adjacency
	polys = [p1, p2, p3, p4]
	adj = GMT._build_adjacency(polys)
	@test adj[1,2] == true   # p1 and p2 are adjacent
	@test adj[2,1] == true
	@test adj[1,3] == false  # p1 and p3 share only corner
	@test adj[1,4] == false  # p1 and p4 are far apart
	@test adj[2,3] == true   # p2 and p3 are adjacent

	# Test fourcolorsindex with synthetic data
	color_idx = GMT.fourcolorsindex(polys, groupby="")
	@test length(color_idx) == 4
	@test all(1 .<= color_idx .<= 4)
	@test color_idx[1] != color_idx[2]  # adjacent polygons have different colors

	# Test with grouping
	p1.attrib = Dict{String,String}("CODE" => "A")
	p2.attrib = Dict{String,String}("CODE" => "A")  # Same group as p1
	p3.attrib = Dict{String,String}("CODE" => "B")
	p4.attrib = Dict{String,String}("CODE" => "C")
	polys_grouped = [p1, p2, p3, p4]

	color_idx_grouped = GMT.fourcolorsindex(polys_grouped, groupby="CODE")
	@test color_idx_grouped[1] == color_idx_grouped[2]  # Same group = same color

	# Test with more colors
	color_idx_7 = GMT.fourcolorsindex(polys, groupby="", ncolors=7)
	@test all(1 .<= color_idx_7 .<= 7)

	# Test that non-adjacent polygons can have any color but adjacent must differ
	for i in 1:4
		for j in i+1:4
			if adj[i,j]
				@test color_idx[i] != color_idx[j]
			end
		end
	end

	# Test larger grid of polygons (3x3 grid)
	grid_polys = GMT.GMTdataset[]
	for i in 0:2
		for j in 0:2
			x0, y0 = Float64(i), Float64(j)
			data = [x0 y0; x0+1 y0; x0+1 y0+1; x0 y0+1; x0 y0]
			p = GMT.GMTdataset(data=data, bbox=[x0, x0+1, y0, y0+1])
			push!(grid_polys, p)
		end
	end

	color_idx_grid = GMT.fourcolorsindex(grid_polys, groupby="")
	@test length(color_idx_grid) == 9
	@test all(1 .<= color_idx_grid .<= 4)

	# Verify no two adjacent cells have the same color
	adj_grid = GMT._build_adjacency(grid_polys)
	for i in 1:9
		for j in i+1:9
			if adj_grid[i,j]
				@test color_idx_grid[i] != color_idx_grid[j]
			end
		end
	end

	D = getdcw("PT,ES,FR", file=:ODS);
	fourcolors(D, show=false);
	D = getdcw("AU", states=true, file=:ODS);
end
