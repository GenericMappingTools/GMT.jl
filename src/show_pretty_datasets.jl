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
			hdr, tit = vec(string.(keys(D.attrib))), "Attribute table (Dict{String, String})"
			if (!isempty(attrib_table))
				pretty_table(attrib_table; header=hdr, alignment=:l, show_row_number=true, title=tit, vcrop_mode=:middle)
			else
				pretty_table(reshape(vec(string.(values(D.attrib))),1,length(D.attrib)), header=hdr, title=tit)
			end
		end
		(~isempty(D.bbox))    && println("BoundingBox: ", D.bbox)
		(~isempty(D.bbox) && D.bbox != D.ds_bbox) && println("Global BoundingBox: ", D.ds_bbox)
		(D.proj4  != "")      && println("PROJ: ", D.proj4)
		(D.wkt    != "")      && println("WKT: ", D.wkt)
		(D.header != "")      && println("Header:\t", D.header)
		(!isempty(D.comment)) && println("Comment:\t", D.comment)
		println("")
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
		if (size(D,1) > 250)	# Since only dataset's begining and end is displayed do not make a potentially big copy
			Dt = [[D.data[1:50, :]; D.data[end-50:end, :]] [D.text[1:50, :]; D.text[end-50:end, :]]]
			skipd_rows = size(D,1) - size(Dt,1)
		else
			if (!is_named_region)
				Dt = [D.data D.text]
			else
				nr = Matrix{String}(undef, numel(D.text), 3)
				for k = 1:numel(D.text)
					nr[k,:] = string.(split(D.text[k],','))		# Can't find a clever way of doing this
				end
				Dt = [D.data nr]
			end
		end
	else
		Dt = D.data
	end

	if ((Tc = get(D.attrib, "Timecol", "")) != "")
		Tcn = parse.(Int, split(Tc, ","))
		if (size(Dt,1) > 250)
			newTcs = string.(unix2datetime.([Dt[1:50, Tcn]; Dt[end-50:end, Tcn]]))
			Dt = [D.data[1:50, :]; D.data[end-50:end, :]]
			(skipd_rows == 0) && (skipd_rows = size(D,1) - size(Dt,1))
		else
			newTcs = string.(unix2datetime.(Dt[:, Tcn]))
		end
		Dt = (length(Tcn) == 1) ? [Dt[:,1:Tcn[1]-1] newTcs[:,1] Dt[:,Tcn[1]+1:end]] :
		                          [Dt[:,1:Tcn[1]-1] newTcs[:,1] Dt[:,Tcn[1]+1:Tcn[2]-1] newTcs[:,2] Dt[:,Tcn[2]+1:end]]
	end

	# Print the table with the selected options.
	pretty_table(io, Dt;
				 alignment                   = alignment,
				 alignment_anchor_fallback   = :r,
				 alignment_anchor_regex      = alignment_anchor_regex,
				 compact_printing            = compact_printing,
				 crop                        = crop,
				 reserved_display_lines = 2,
				 ellipsis_line_skip          = 3,
				 formatters                  = (_pretty_tables_general_formatter,),
				 header                      = (names_str, types_str),
				 header_alignment            = alignment,
				 hlines                      = [:header],
				 highlighters                = (_PRETTY_TABLES_HIGHLIGHTER,),
				 maximum_columns_width       = maximum_columns_width,
				 newline_at_end              = false,
				 show_subheader                 = !eltypes,
				 row_label_alignment          = :r,
				 row_label_crayon             = Crayon(),
				 row_label_column_title       = string(rowlabel),
				 row_labels                   = row_names,
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
function compacttype(T::Type, maxwidth::Int)
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

const _PRETTY_TABLES_HIGHLIGHTER = Highlighter(_pretty_tables_highlighter_func, Crayon(foreground = :dark_gray))

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