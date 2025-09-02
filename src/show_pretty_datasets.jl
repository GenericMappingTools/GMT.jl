# The code here was "stealed" from DataFrames and choped out for non-usable (here) parts
# and adapted for GMTdataset's.

Base.show(io::IO, D::GMTdataset;
		  allrows::Bool = !get(io, :limit, false),
		  allcols::Bool = !get(io, :limit, false),
		  rowlabel::Symbol = :Row,
		  summary::Bool = true,
		  eltypes::Bool = true,
		  truncate::Int = 32,
		  attrib_table::Matrix{String} = Matrix{String}(undef, 0, 0),
		  text_colname::String = "",
		  kwargs...) =
	_show(io, D; allrows=allrows, allcols=allcols, rowlabel=rowlabel, summary=summary, eltypes=eltypes, truncate=truncate, attrib_table=attrib_table, text_colname=text_colname, kwargs...)

Base.show(D::GMTdataset;
          allrows::Bool = !get(stdout, :limit, true),
          allcols::Bool = !get(stdout, :limit, true),
          rowlabel::Symbol = :Row,
          summary::Bool = true,
          eltypes::Bool = true,
          truncate::Int = 32,
		  attrib_table::Matrix{String} = Matrix{String}(undef, 0, 0),
		  text_colname::String = "",
          kwargs...) =
    show(stdout, D; allrows=allrows, allcols=allcols, rowlabel=rowlabel, summary=summary, eltypes=eltypes, truncate=truncate, attrib_table=attrib_table, text_colname=text_colname, kwargs...)

function _show(io::IO,
			   D::GMTdataset;
			   allrows::Bool = !get(io, :limit, false),
			   allcols::Bool = !get(io, :limit, false),
			   rowlabel::Symbol = :Row,
			   summary::Bool = true,
			   eltypes::Bool = true,
			   truncate::Int = 32,
			   attrib_table::Matrix{String}  = Matrix{String}(undef, 0, 0),
			   text_colname::String = "",
			   kwargs...)

	# For example a grdinfo(...) or a pure text dataset. In those cases just print the .text & return.
	if (isempty(D.data))
		(~all(isempty.(D.comment))) && println("Comment:\t", D.comment)
		(D.header != "")      && println("Header:\t", D.header)
		display(D.text)
		return nothing
	end

	is_named_region = (!isempty(D.comment) && endswith(D.comment[1], "code-region-ref")) # A special DS with named regions

	names_str = !isempty(D.colnames) ? copy(D.colnames) : ["col.$i" for i=1:size(D,2)]
	if (is_named_region)
		names_str[end] = "Code";	append!(names_str, ["Region", "Ref"])
	end
	names_len = Int[textwidth(n) for n in names_str]
	maxwidth = Int[max(9, nl) for nl in names_len]
	types = Any[eltype(c) for c in eachcol(D)]
	#(length(types) == length(names_len) - 1) && push!(types, String)
	types_str = batch_compacttype(types, maxwidth)

	if (allcols && allrows) crop = :none
	elseif (allcols)        crop = :vertical
	elseif (allrows)        crop = :horizontal
	else                    crop = :both
	end

	# For consistency, if `kwargs` has `compact_printng`, we must use it.
	compact_printing::Bool = get(kwargs, :compact_printing, get(io, :compact, true))

	num_cols = size(D, 2)

	# By default, we align the columns to the left unless they are numbers, which is checked in the following.
	alignment = fill(:l, num_cols)

	# Create the dictionary with the anchor regex that is used to align the floating points.
	alignment_anchor_regex = Dict{Int, Vector{Regex}}()

	# Regex to align real numbers.
	alignment_regex_real = [r"\."]

	for i = 1:num_cols
		if types[i] <: Real
			alignment_anchor_regex[i] = alignment_regex_real
			alignment[i] = :r
		elseif types[i] <: Number
			alignment[i] = :r
		end
	end

	# Make sure that `truncate` does not hide the type and the column name.
	maximum_columns_width = Int[truncate == 0 ? 0 : max(truncate + 1, l, textwidth(t))
								for (l, t) in zip(names_len, types_str)]

	# Check if the user wants to display a summary about the DataFrame that is
	# being printed. This will be shown using the `title` option of `pretty_table`.
	title = summary ? Base.summary(D) : ""

	show_row_number::Bool = get(kwargs, :show_row_number, true)
	row_names = nothing

	# If the columns with row numbers is not shown, then we should not
	# display a vertical line after the first column.
	vlines = fill(1, show_row_number)

	if (!is_named_region)
		(~all(isempty.(D.comment))) && println("Comment:\t", D.comment)
		if (~isempty(D.attrib))
			hdr, tit = vec(string.(keys(D.attrib))), "Attribute table"
			if (!isempty(attrib_table))
				pretty_table(attrib_table; header=hdr, alignment=:l, show_row_number=true, title=tit, vcrop_mode=:middle)
			else
				# If we have string vector attributes don't print its contents, just reference them by column number
				vals = values(D.attrib)
				ind = findall(isa.(vals, Vector))
				t_vec = vec(string.(vals))
				for k = 1:numel(ind)
					t_vec[ind[k]] = "In col" * string(size(D, 2) + !isempty(D.text) + ind[k])
				end
				(hdr != ["Timecol"]) && pretty_table(reshape(t_vec, 1, length(D.attrib)), header=hdr, title=tit)
			end
		end
		(~isempty(D.bbox))    && println("BoundingBox: ", D.bbox)
		(~isempty(D.bbox) && D.bbox != D.ds_bbox) && println("Global BoundingBox: ", D.ds_bbox)
		(D.proj4  != "")      && println("PROJ: ", D.proj4)
		(D.wkt    != "")      && println("WKT: ", D.wkt)
		(D.header != "")      && println("Header:\t", D.header)
		println("")
	end

	# See if we have attribs as vector of strings to be displayed as columns in the table.
	function add_att_cols(D, Dt, names_str, types_str)
		isempty(D.attrib) && return Dt, names_str, types_str
		ky = (get(D.attrib, "att_order", "") != "") ? collect(split(D.attrib["att_order"], ",")) : collect(keys(D.attrib))
		for k = 1:numel(ky)
			!isa(D.attrib[ky[k]], Vector{String}) && continue
			push!(names_str, ky[k]*" (att)")
			push!(alignment, :r)
			push!(types_str, "String")
			t = D.attrib[ky[k]]
			(length(t) < size(D.data, 1)) && (t = vcat(t, fill("", size(D, 1) - length(t))))	# Accept shorter vectors
			length(t) > 100 && (t = [t[1:40]; t[end-40:end]])		# Make it same length as Dt (trimmed before to 80 rows) 
			Dt = [Dt t]
		end
		return Dt, names_str, types_str
	end

	skipd_rows = 0
	if (~isempty(D.text))
		if (length(names_str) == length(types_str))		# Otherwise it keeps adding a "Text" everytime this fun is executed
			push!(names_str, (text_colname != "" ? text_colname : "Text"))
		end
		push!(alignment, :r)
		push!(types_str, "String")
		if (is_named_region)
			append!(alignment, [:c, :c])
			append!(types_str, ["String", "String"])
		end
		if (size(D,1) > 100)	# Since only dataset's begining and end is displayed do not make a potentially big copy
			Dt = [[D.data[1:40, :]; D.data[end-40:end, :]] [D.text[1:40, :]; D.text[end-40:end, :]]]
			skipd_rows = size(D,1) - size(Dt,1)
		else
			if (!is_named_region)
				Dt = [D.data D.text]
			else
				nr = Matrix{String}(undef, numel(D.text), 3)
				for k = 1:numel(D.text)
					nr[k,:] = string.(split(D.text[k],','))				# Can't find a clever way of doing this
				end
				Dt = [D.data nr]
			end
		end
	else
		if (size(D,1) > 100)	# Since only dataset's begining and end is displayed do not make a potentially big copy
			Dt = [D.data[1:40, :]; D.data[end-40:end, :]]
			skipd_rows = size(D,1) - size(Dt,1)
		else
			Dt = D.data
		end
	end

	Dt, names_str, types_str = add_att_cols(D, Dt, names_str, types_str)	# Check for string vector attributes

	if ((Tc = get(D.attrib, "Timecol", "")) != "")
		Td = (get(D.attrib, "DateOnly", "") != "")	# When it is known that the time column contains only date values
		Tcn = parse.(Int, split(Tc, ","))
		WTS = get(D.attrib, "what_time_sys", "")	# If other than Unix time is being used. Currently only decimal year is supported
		if (WTS == "YearDecimal0000")  fun = yeardecimal
		else                           fun = unix2datetime
		end
		if (size(Dt,1) > 100)
			newTcs = !Td ? string.(fun.([Dt[1:40, Tcn]; Dt[end-40:end, Tcn]])) : string.(Date.(fun.([Dt[1:40, Tcn]; Dt[end-40:end, Tcn]])))
			Dt = [Dt[1:40, :]; Dt[end-40:end, :]]
			(skipd_rows == 0) && (skipd_rows = size(D,1) - size(Dt,1))
		else
			newTcs = !Td ? string.(fun.(Dt[:, Tcn])) : string.(Date.(fun.(Dt[:, Tcn])))
		end

		Dt = (length(Tcn) == 1) ? [Dt[:,1:Tcn[1]-1] newTcs[:,1] Dt[:,Tcn[1]+1:end]] : (length(Tcn) == 2) ? 
		                          [Dt[:,1:Tcn[1]-1] newTcs[:,1] Dt[:,Tcn[1]+1:Tcn[2]-1] newTcs[:,2] Dt[:,Tcn[2]+1:end]] : (length(Tcn) == 3) ?
								  [Dt[:,1:Tcn[1]-1] newTcs[:,1] Dt[:,Tcn[1]+1:Tcn[2]-1] newTcs[:,2] Dt[:,Tcn[2]+1:Tcn[3]-1] newTcs[:,3] Dt[:,Tcn[3]+1:end]] : (length(Tcn) == 4) ?
								  [Dt[:,1:Tcn[1]-1] newTcs[:,1] Dt[:,Tcn[1]+1:Tcn[2]-1] newTcs[:,2] Dt[:,Tcn[2]+1:Tcn[3]-1] newTcs[:,3] Dt[:,Tcn[3]+1:Tcn[4]-1] newTcs[:,4] Dt[:,Tcn[4]+1:end]] : (length(Tcn) == 5) ?
								  [Dt[:,1:Tcn[1]-1] newTcs[:,1] Dt[:,Tcn[1]+1:Tcn[2]-1] newTcs[:,2] Dt[:,Tcn[2]+1:Tcn[3]-1] newTcs[:,3] Dt[:,Tcn[3]+1:Tcn[4]-1] newTcs[:,4] Dt[:,Tcn[4]+1:Tcn[5]-1] newTcs[:,5] Dt[:,Tcn[5]+1:end]] :
								  [Dt[:,1:Tcn[1]-1] newTcs[:,1] Dt[:,Tcn[1]+1:Tcn[2]-1] newTcs[:,2] Dt[:,Tcn[2]+1:Tcn[3]-1] newTcs[:,3] Dt[:,Tcn[3]+1:Tcn[4]-1] newTcs[:,4] Dt[:,Tcn[4]+1:Tcn[5]-1] newTcs[:,5] Dt[:,Tcn[5]+1:Tcn[6]-1] newTcs[:,6] Dt[:,Tcn[6]+1:end]]
	end

	# Print the table with the selected options.
	pretty_table(io, Dt;
				 alignment                   = alignment,
				 alignment_anchor_fallback   = :r,
				 alignment_anchor_regex      = alignment_anchor_regex,
				 compact_printing            = compact_printing,
				 crop                        = crop,
				 reserved_display_lines      = 2,
				 ellipsis_line_skip          = 3,
				 formatters                  = (_pretty_tables_general_formatter,),
				 header                      = (names_str, types_str),
				 header_alignment            = alignment,
				 hlines                      = [:header],
				 #highlighters                = (_PRETTY_TABLES_HIGHLIGHTER,),
				 maximum_columns_width       = maximum_columns_width,
				 newline_at_end              = false,
				 show_subheader              = !eltypes,
				 row_label_alignment         = :r,
				 #row_label_crayon            = Crayon(),
				 row_label_column_title      = string(rowlabel),
				 row_labels                  = row_names,
				 row_number_alignment        = :r,
				 row_number_column_title     = string(rowlabel),
				 show_row_number             = show_row_number,
				 title                       = title,
				 vcrop_mode                  = :middle,
				 vlines                      = vlines,
				 kwargs...)

	(skipd_rows > 0) && println("\nTo avoid a large array copy, $(skipd_rows) rows have been skipped in the above table.\nThis means that last line should read $(size(D,1)) instead of $(size(Dt,1))")
	return nothing
end

# For most data frames, especially wide, columns having the same element type
# occur multiple times. batch_compacttype ensures that we compute string
# representation of a specific column element type only once and then reuse it.

function batch_compacttype(types::Vector{Any}, maxwidths::Vector{Int})
	maxwidths = maxwidths[1:length(types)]		# Bloody bug that comes from ether
	#@assert length(types) == length(maxwidths)
	cache = Dict{Any, String}()
	return map(types, maxwidths) do T, maxwidth
		get!(cache, T) do
			compacttype(T, maxwidth)
		end
	end
end

#=
function batch_compacttype(types::Vector{Any}, maxwidth::Int)
	cache = Dict{Type, String}()
	return map(types) do T
		get!(cache, T) do
			compacttype(T, maxwidth)
		end
	end
end
=#

"""
	compacttype(T::Type, maxwidth::Int=8, initial::Bool=true)

Return compact string representation of type `T`.
For displaying data frame we do not want string representation of type to be
longer than `maxwidth`. This function implements rules how type names are
cropped if they are longer than `maxwidth`.
"""
function compacttype(@nospecialize(T::Type), maxwidth::Int)
	maxwidth = max(8, maxwidth)

	T === Any && return "Any"

	sT = string(T)
	textwidth(sT) ≤ maxwidth && return sT
	suffix = "";	maxwidth -= 1	# we will add "…" at the end

	# This is only type display shortening so we
	# are OK with any T whose name starts with CategoricalValue here
	if startswith(sT, "CategoricalValue") || startswith(sT, "CategoricalArrays.CategoricalValue")
		sT = string(nameof(T))
		if textwidth(sT) ≤ maxwidth
			return sT * "…" * suffix
		else
			return (maxwidth ≥ 11 ? "Categorical…" : "Cat…") * suffix
		end
	else
		sTfull = sT
		sT = string(nameof(T))
	end

	# handle the case when the type printed is not parametric but string(T)
	# prefixed it with the module name which caused it to be overlong
	textwidth(sT) ≤ maxwidth + 1 && endswith(sTfull, sT) && return sT

	cumwidth, stop = 0, 0
	for (i, c) in enumerate(sT)
		cumwidth += textwidth(c)
		if cumwidth ≤ maxwidth
			stop = i
		else
			break
		end
		#(cumwidth ≤ maxwidth) ? (stop = i) : break
	end
	return first(sT, stop) * "…" * suffix
end

##############################################################################
##
## Functions related to the interface with PrettyTables.jl.
##
##############################################################################

# Default DataFrames highlighter for text backend.
#
# This highlighter changes the text color to gray in cells with `nothing`,
# `missing`, `#undef`, and types related to DataFrames.jl.
function _pretty_tables_highlighter_func(data, i::Integer, j::Integer)
    try
        cell = data[i, j]
        return cell === nothing || cell isa GDtype
    catch e
        isa(e, UndefRefError) ? (return true) : rethrow(e)
    end
end

#const _PRETTY_TABLES_HIGHLIGHTER = Highlighter(_pretty_tables_highlighter_func, Crayon(foreground = :dark_gray))

# Default DataFrames formatter for text backend.
#
# This formatter changes how the following types are presented when rendering
# the data frame:
#     - missing;
#     - nothing;
#     - Cells with types related to DataFrames.jl.
function _pretty_tables_general_formatter(v, i::Integer, j::Integer)
	(v === nothing) && return ""
    if typeof(v) <: GMTdataset
        # Here, we must not use `print` or `show`. Otherwise, we will call
        # `_pretty_table` to render the current table leading to a stack overflow.
        return sprint(summary, v)
    else
        return v
    end
	#return (typeof(v) <: GMTdataset) ? sprint(summary, v) : v
end