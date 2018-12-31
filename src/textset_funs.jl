# These are only used by GMT5, so keep them in a separate file to not screw the coverage

# ---------------------------------------------------------------------------------------------------
function get_textset_(API::Ptr{Nothing}, object::Ptr{Nothing})
# Given a GMT GMT_TEXTSET T, build a Julia array of segment structure and assign values.
# Each segment will have 6 items:
# header:	Text string with the segment header (could be empty)
# data:	Matrix with any converted data for this segment (n_rows by n_columns)
# text:	Cell array with the text items
# comment:	Cell array with any comments
# proj4:	String with any proj4 information
# wkt:		String with any WKT information

	if (object == C_NULL)  error("programming error, textset is NULL")  end

	T = unsafe_load(convert(Ptr{GMT_TEXTSET}, object))		# GMT_TEXTSET
	flag = [GMT.GMT_LAX_CONVERSION, 0, 0]
	n_columns = 0
	have_numerical = false

	D = GMT_Convert_Data(API, object, GMT_IS_TEXTSET, NULL, GMT_IS_DATASET, Ref(pointer(flag),1))	# Ptr{Nothing}

	if (D != NULL)											# Ptr{GMT_DATASET}
		DS = unsafe_load(convert(Ptr{GMT_DATASET}, D))		# GMT_DATASET
		Dtab = unsafe_load(unsafe_load(DS.table))			# GMT_DATATABLE
		Dseg = unsafe_load(unsafe_load(Dtab.segment))		# GMT_DATASEGMENT
		pCols = pointer_to_array(Dseg.data, DS.n_columns)	# Pointer to the columns
		for col = 1:DS.n_columns							# Now determine number of non-NaN columns from first row
			if (!isnan(unsafe_load(pCols[col])))
				n_columns = n_columns + 1
			end
		end
		have_numerical = true
	end

	seg_out = 0
	for tbl = 1:T.n_tables
		Ttab = unsafe_load(unsafe_load(T.table), tbl)	# GMT.GMT_TEXTTABLE
		for seg = 1:Ttab.n_segments
			Ttab_Seg = unsafe_load(unsafe_load(Ttab.segment), seg)		# GMT_TEXTSEGMENT
			if (Ttab_Seg.n_rows > 0)  seg_out = seg_out + 1  end
		end
	end

	Ttab_1 = unsafe_load(unsafe_load(T.table), 1)
	n_headers = Ttab_1.n_headers

	Darr = [GMTdataset() for i = 1:seg_out]			# Create the array of DATASETS

	seg_out = 1
	Tab = unsafe_wrap(Array, T.table, T.n_tables)		# D.n_tables-element Array{Ptr{GMT.GMT_DATATABLE},1}
	for tbl = 1:T.n_tables
		Ttab = unsafe_load(unsafe_load(T.table), tbl)	# GMT.GMT_TEXTTABLE
		for seg = 1:Ttab.n_segments
			Ttab_Seg = unsafe_load(unsafe_load(Ttab.segment), seg)		# GMT_TEXTSEGMENT
			if (Ttab_Seg.n_rows == 0)	continue 	end # Skip empty segments

			if (have_numerical)							# We have numerial data to consider
				Dtab_Seg = unsafe_load(unsafe_load(Dtab.segment), seg)	# Shorthand to the corresponding data segment
				dest = zeros(Ttab_Seg.n_rows, n_columns)
				for col = 1:n_columns					# Copy the data columns
					unsafe_copy!(pointer(dest, Ttab_Seg.n_rows * (col - 1) + 1), unsafe_load(Dtab_Seg.data, col), Ttab_Seg.n_rows)
				end
				Darr[seg].data = dest
			end

			if (!have_numerical)
				dest = Array{Any}(undef, Ttab_Seg.n_rows)
				for row = 1:Ttab_Seg.n_rows
					t = unsafe_load(Ttab_Seg.data, row)	# Ptr{UInt8}
					dest[row] = unsafe_string(t)
				end
				Darr[seg_out].text = dest
			end

			#headers = pointer_to_array(Ttab_1.header, Ttab_1.n_headers)	# n_headers-element Array{Ptr{UInt8},1}
			headers = unsafe_wrap(Array, Ttab_1.header, Ttab_1.n_headers)	# n_headers-element Array{Ptr{UInt8},1}
			dest = Array{Any}(undef, length(headers))
			for k = 1:n_headers
				dest[k] = unsafe_string(headers[k])
			end
			Darr[seg_out].comment = dest

			seg_out = seg_out + 1
		end
	end

	if (have_numerical && GMT_Destroy_Data(API, Ref([D])) != 0)
		println("Warning: Failure to delete intermediate D in GMTMEX_Get_Textset\n")
	end

	return Darr
end


# ---------------------------------------------------------------------------------------------------
function text_init_(API::Ptr{Nothing}, module_input, Darr, dir::Integer, family::Integer=GMT_IS_TEXTSET)
#
	if (dir == GMT_OUT)
		GMT_CREATE_MODE = (get_GMTversion(API) > 5.3) ? GMT_IS_OUTPUT : 0
		if ((T = GMT_Create_Data(API, GMT_IS_TEXTSET, GMT_IS_NONE, GMT_CREATE_MODE, NULL, NULL, NULL, 0, 0, NULL)) == NULL)
			error("Failure to alloc GMT blank TEXTSET container for holding output TEXT")
		end
		return T
	end

	if (isa(Darr, Array{GMTdataset,1}))
		dim = [1 0 0]
		dim[GMT.GMT_SEG+1] = length(Darr)		# Number of segments
		if (dim[GMT.GMT_SEG+1] == 0) error("Input has zero segments where it can't be")	end
		pdim = pointer(dim)
		if ((T = GMT_Create_Data(API, GMT_IS_TEXTSET, GMT_IS_PLP, 0, pdim, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("Failure to alloc GMT destination dataset.")
		end
		GMT_Report(API, GMT_MSG_DEBUG, @sprintf("text_init_: Allocated GMT textset %s", T))

		TS = unsafe_load(convert(Ptr{GMT_TEXTSET}, T))
		TT = unsafe_load(unsafe_load(TS.table))				# GMT.GMT_TEXTTABLE

		for seg = 1:dim[GMT.GMT_SEG+1] 						# Each incoming structure is a new data segment
			dim[GMT.GMT_ROW+1] = size(Darr[seg].data, 1)	# Number of rows in matrix
			TSv = convert(Ptr{Nothing}, unsafe_load(TT.segment, seg))		# TT.segment = Ptr{Ptr{GMT.GMT_TEXTSEGMENT}}

			if (length(Darr[seg].text) == 0)
				add_text = false
			else
				dim[GMT_ROW+1] = size(Darr[seg].text,1)		# Number of rows found
				add_text = true
			end
			n_cols = size(Darr[seg].data, 2)				# Number of data cols, if any

			# Allocate new text segment and hook it up to the table
			S = GMT_Alloc_Segment(API, GMT_IS_TEXTSET, dim[GMT.GMT_ROW+1], 0, Darr[seg].header, TSv) # Ptr{GMT_TEXTSET}
			Sb = unsafe_load(S)								# GMT_TEXTSEGMENT;		Sb.data -> Ptr{Ptr{UInt8}}

			# Combine any data and cell arrays into text records
			for row = 1:Sb.n_rows
				# First deal with the [optional] data matrix for leading columns
				if (n_cols > 0)
					buff = join([@sprintf("%s\t", Darr[seg].data[row,k]) for k=1:n_cols])
				end
				if (add_text)				# Then append the optional text strings
					buff = buff * Darr[seg].text[row]
				else
					buff = rstrip(buff)		# Strip last '\t'
				end
				unsafe_store!(Sb.data, GMT_Duplicate_String(API, buff), row)	# This allows shared mem
			end

			if (seg == 1 && length(Darr[1].comment) > 0)	# First segment may have dataset information
				for k = 1:size(Darr[1].comment,1)
					if (GMT_Set_Comment(API, GMT_IS_TEXTSET, GMT_COMMENT_IS_TEXT, convert(Ptr{Nothing}, pointer(Darr[1].comment[k])),
					                    convert(Ptr{Nothing}, T)) != 0)
						println("text_init_: Failed to set a textset header")
					end
				end
			end
			unsafe_store!(S, Sb)
			unsafe_store!(TT.segment, S, seg)
		end
	else
		T = text_init(API, module_input, Darr, dir)
	end

	return T
end

# ---------------------------------------------------------------------------------------------------
function text_init(API::Ptr{Nothing}, module_input, txt, dir::Integer, family::Integer=GMT_IS_TEXTSET)
	# Used to Create an empty Textset container to hold a GMT TEXTSET.
 	# If direction is GMT_IN then we are given a Julia cell array and can determine its size, etc.
	# If direction is GMT_OUT then we allocate an empty GMT TEXTSET as a destination.


	# Disclaimer: This code is absolutely diabolic. Thanks to immutables.

	if (dir == GMT_IN)	# Dimensions are known from the input pointer

		#if (module_input) family |= GMT_VIA_MODULE_INPUT;	gmtmex_parser.c has this which is not ported yet

		if (!isa(txt, Array{Any}) && isa(txt, String))
			txt = Any[txt]
		elseif (isa(txt[1], Number))
			txt = num2str(txt)			# Convert the numeric matrix into a cell array of strings
		end
		if (VERSION.minor > 4)
			if (!isa(txt, Array{Any}) && !(eltype(txt) == String))
				error(@sprintf("Expected a Cell array or a String for input, got a \"%s\"", typeof(txt)))
			end
		end

		dim = [1 1 0]
		dim[3] = size(txt, 1)
		if (dim[3] == 1)                # Check if we got a transpose arrangement or just one record
			rec = size(txt, 2)          # Also possibly number of records
			if (rec > 1) dim[3] = rec end  # User gave row-vector of cells
		end

		if ((T = GMT_Create_Data(API, family, GMT_IS_NONE, 0, pointer(dim), C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("Failure to alloc GMT source TEXTSET for input")
		end
		mutateit(API, T, "alloc_mode", GMT_ALLOC_EXTERNALLY)	# Don't know if this is still used

		T0 = unsafe_load(T)				# GMT.GMT_TEXTSET

		TTABLE  = unsafe_load(unsafe_load(T0.table,1),1)		# ::GMT.GMT_TEXTTABLE
		S0 = unsafe_load(unsafe_load(TTABLE.segment,1),1)		# ::GMT.GMT_TEXTSEGMENT

		for rec = 1:dim[3]
			unsafe_store!(S0.data, pointer(txt[rec]), rec)
		end

		mutateit(API, unsafe_load(TTABLE.segment,1), "n_rows", dim[3])

	else 	# Just allocate an empty container to hold an output grid (signal this by passing NULLs)
		GMT_CREATE_MODE = (get_GMTversion(API) > 5.3) ? GMT_IS_OUTPUT : 0
		if ((T = GMT_Create_Data(API, GMT_IS_TEXTSET, GMT_IS_NONE, GMT_CREATE_MODE, C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("Failure to alloc GMT blank TEXTSET container for holding output TEXT")
		end
	end

	return T
end