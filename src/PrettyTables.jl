## #########################################################################################
# A fishing on PrettyTabels 2.4 of the functions need to print tables in GMT.jl.
# Only Text mode backend and dropped all dependencies.
#
# With this, we escape the PT v2 vs v3 transition, drop several dependencies and shave
# a ~0.2 Mb from the GMT.jl precomp cache as well as improve load times in > 0.1 seconds
# and no longer need a > 10 MB PT precomp cache DLL.
############################################################################################

export pretty_table

#const _REGEX_ANSI_SEQUENCES = r"\x1B(?:]8;;[^\x1B]*\x1B\\|[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])"

function printable_textwidth(str::AbstractString)
	return str |> remove_decorations |> textwidth
end
function printable_textwidth_per_line(str::AbstractString)
	lines       = split(str, '\n')
	num_lines   = length(lines)
	lines_width = zeros(Int, num_lines)

	@inbounds for k in 1:num_lines
		lines_width[k] = printable_textwidth(lines[k])
	end

	return lines_width
end
function remove_decorations(str::AbstractString)
	return replace(str, r"\x1B(?:]8;;[^\x1B]*\x1B\\|[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])" => "")
end

function crop_width_to_fit_string_in_field(str::AbstractString, field_width::Int; add_continuation_char::Bool = true,
	add_space_in_continuation_char::Bool = false, continuation_char::Char = '…', printable_string_width::Int = -1)
	str_width = if printable_string_width < 0
		printable_textwidth(str)
	else
		printable_string_width
	end

	Δ = str_width - field_width

	# If the field is larger than the string, we do not need to crop.
	(Δ ≤ 0) && return 0

	# If the user is asking for the continuation char, we must crop the string to account
	# for the continuation char.
	cont_str = ""

	if add_continuation_char
		cont_str_width = textwidth(continuation_char)

		add_space_in_continuation_char && (cont_str_width += 1)

		Δ += cont_str_width

		# If we are left with no space, then we must crop the entire string.
		(Δ > str_width) && return str_width
	end

	return Δ
end

function fit_string_in_field(str::AbstractString, field_width::Int; add_continuation_char::Bool = true, add_space_in_continuation_char::Bool = false,
	continuation_char::Char = '…', crop_side::Symbol = :right, field_margin::Int = 0, keep_escape_seq::Bool = true, printable_string_width::Int = -1)
	str_width = if printable_string_width < 0
		printable_textwidth(str)
	else
		printable_string_width
	end

	crop = crop_width_to_fit_string_in_field(str, field_width - field_margin; add_continuation_char, add_space_in_continuation_char,
		continuation_char, printable_string_width = str_width)

	(crop ≤ field_margin) && return str

	cont_str = add_continuation_char ? string(continuation_char) : ""

	# == Crop From the Right ===============================================================

	if crop_side == :right
		cropped_str, ansi = right_crop(str, crop; keep_escape_seq, printable_string_width = str_width)
		add_space_in_continuation_char && return cropped_str * " " * cont_str * ansi

		return cropped_str * cont_str * ansi

	# == Crop from The Left ================================================================

	else
		ansi, cropped_str = left_crop(str, crop)
		result = keep_escape_seq ? ansi : ""

		add_space_in_continuation_char && return result * cont_str * " " * cropped_str

		return result * cont_str * cropped_str
	end
end

function padding_for_string_alignment(str::AbstractString, field_width::Int, alignment::Symbol; fill::Bool = false, printable_string_width::Int = -1)
	str_width = if printable_string_width < 0
		printable_textwidth(str)
	else
		printable_string_width
	end

	(field_width ≤ str_width) && return nothing

	# Compute the padding given the alignment type.
	if (alignment == :l) && fill
		rpad = field_width - str_width
		return 0, rpad

	elseif alignment == :c
		lpad = div(field_width - str_width, 2)
		rpad = fill ? (field_width - str_width - lpad) : 0
		return lpad, rpad

	elseif alignment == :r
		lpad = field_width - str_width
		return lpad, 0
	end

	return nothing
end

function _next_string_state(c::Char, state::Symbol = :text)
    if state == :text
        # Here, we need to check if an escape sequence is found.
        c == '\x1B' && return :escape_state_begin

    elseif state == :escape_state_begin
        (c == '[') && return :escape_state_opening
        (c == ']') && return :escape_hyperlink_opening
        (('@' ≤ c ≤ 'Z') || ('\\' ≤ c ≤ '_')) && return :escape_state_1

    elseif state == :escape_state_opening
        return _next_string_state(c, :escape_state_1)

    elseif state == :escape_state_1
        ('0' ≤ c ≤ '?') && return :escape_state_1
        return _next_string_state(c, :escape_state_2)

    elseif state == :escape_state_2
        (' ' ≤ c ≤ '/') && return :escape_state_2
        return _next_string_state(c, :escape_state_3)

    elseif state == :escape_state_3
        ('@' ≤ c ≤ '~') && return :escape_state_end

    elseif state == :escape_hyperlink_opening
        (c == '8') && return :escape_hyperlink_1

    elseif state == :escape_hyperlink_1
        (c == ';') && return :escape_hyperlink_2

    elseif state == :escape_hyperlink_2
        (c == ';') && return :escape_hyperlink_3

    elseif state ∈ (:escape_hyperlink_3, :escape_hyperlink_url)
        (c == '\x1B') && return :escape_hyperlink_end
        return :escape_hyperlink_url

    elseif state == :escape_hyperlink_end
        (c == '\\') && return :escape_state_end

    elseif state == :escape_state_end
        # We need to recall this function because the next character can be the beginning of
        # a new ANSI escape sequence.
        return _next_string_state(c, :text)
    end

    return :text
end

function left_crop(str::AbstractString, crop_width::Int)
	buf_ansi = IOBuffer()
	buf_str  = IOBuffer(sizehint = floor(Int, sizeof(str) - crop_width))
	state    = :text

	for c in str
		if crop_width ≤ 0
			write(buf_str, c)
			continue
		end

		state = _next_string_state(c, state)

		# If we are not in a text section, just write the character to the ANSI buffer.
		if state != :text
			write(buf_ansi, c)
			continue
		end

		crop_width -= textwidth(c)

		# If `crop_width` is negative, it means that we have a character that occupies
		# more than 1 character. In this case, we fill the string with space.
		if crop_width < 0
			write(buf_str, " "^(-crop_width))
			crop_width = 0
		end
	end

	return String(take!(buf_ansi)), String(take!(buf_str))
end

function right_crop(str::AbstractString, crop_width::Int; keep_escape_seq::Bool = true, printable_string_width::Int = -1)
	buf_ansi = IOBuffer()
	buf_str  = IOBuffer(sizehint = floor(Int, max(0, sizeof(str) - crop_width)))
	state    = :text

	str_width = if printable_string_width < 0
		printable_textwidth(str)
	else
		printable_string_width
	end

	remaining_chars = str_width - crop_width

	for c in str
		state = _next_string_state(c, state)

		if remaining_chars <= 0
			!keep_escape_seq && break
			state != :text && write(buf_ansi, c)
			continue
		end

		# If we are not in a text section, just write the character to the ANSI buffer.
		if state != :text
			write(buf_str, c)
			continue
		end

		Δ = textwidth(c)
		remaining_chars -= Δ

		# If `remaining_chars` is negative, it means that we have a character that
		# occupies more than 1 character. In this case, we fill the string with space.
		if remaining_chars < 0
			write(buf_str, " "^(-remaining_chars))
			remaining_chars = 0
			continue
		end

		write(buf_str, c)
	end

	return String(take!(buf_str)), String(take!(buf_ansi))
end

function align_string(str::AbstractString, field_width::Int, alignment::Symbol; fill::Bool = false, printable_string_width::Int = -1)
	padding = padding_for_string_alignment(str, field_width, alignment; fill, printable_string_width)

	isnothing(padding) && return str

	lpad, rpad = padding
	return " "^lpad * str * " "^rpad
end

function pretty_table(@nospecialize(data::Any); kwargs...)
	io = stdout isa Base.TTY ? IOContext(stdout, :limit => true) : stdout
	pretty_table(io, data; kwargs...)
end

function pretty_table(::Type{String}, @nospecialize(data::Any); color::Bool = false, kwargs...)
	io = IOContext(IOBuffer(), :color => color)
	pretty_table(io, data; kwargs...)
	return String(take!(io.io))
end

function pretty_table(@nospecialize(io::IO), @nospecialize(data::Any); header::Union{Nothing, AbstractVector, Tuple} = nothing, kwargs...)
	istable = Tables.istable(data)

	if istable
		if Tables.columnaccess(data)
			pdata, pheader = _preprocess_column_tables_jl(data, header)
		else
			# If we do not have column access, let's just assume row access as indicated here:
			#   https://github.com/ronisbr/PrettyTables.jl/issues/220
			pdata, pheader = _preprocess_row_tables_jl(data, header)
		end

	elseif data isa AbstractVecOrMat
		pdata, pheader = _preprocess_vec_or_mat(data, header)

	elseif data isa AbstractDict
		sortkeys = get(kwargs, :sortkeys, false)
		pdata, pheader = _preprocess_dict(data, header; sortkeys = sortkeys)

	else
		error("The type $(typeof(data)) is not supported.")
	end

	return _print_table(io, pdata; header = pheader, kwargs...)
end

# --------------------------------------------------------------------------------
@kwdef struct TextFormat
	up_right_corner::Char                  = '┐'
	up_left_corner::Char                   = '┌'
	bottom_left_corner::Char               = '└'
	bottom_right_corner::Char              = '┘'
	up_intersection::Char                  = '┬'
	left_intersection::Char                = '├'
	right_intersection::Char               = '┤'
	middle_intersection::Char              = '┼'
	bottom_intersection::Char              = '┴'
	column::Char                           = '│'
	row::Char                              = '─'
	hlines::Vector{Symbol}                 = [:begin, :header, :end]
	vlines::Union{Symbol, Vector{Symbol}}  = :all
end

@kwdef mutable struct Display
	size::Tuple{Int,Int}  = (-1, -1)
	row::Int              = 1
	column::Int           = 0
	has_color::Bool       = false
	cont_char::Char       = '⋯'
	cont_reset::Bool      = true
	cont_space_char::Char = ' '

	# Buffer that stores the current line.
	buf_line::IOBuffer = IOBuffer()
	# Buffer that stores the entire output.
	buf::IOBuffer = IOBuffer()
end

abstract type CustomTextCell end

@kwdef mutable struct RowPrintingState
	state::Symbol = :top_horizontal_line
	i::Int = 0
	l::Int = 0
	continuation_line_drawn::Bool = false
	printed_lines::Int = 1
	i_pt::Int = 0
end

const tf_unicode = TextFormat()

const tf_ascii_dots = TextFormat(
	up_right_corner     = '.',
	up_left_corner      = '.',
	bottom_left_corner  = ':',
	bottom_right_corner = ':',
	up_intersection     = '.',
	left_intersection   = ':',
	right_intersection  = ':',
	middle_intersection = ':',
	bottom_intersection = ':',
	column              = ':',
	row                 = '.'
)

const tf_ascii_rounded = TextFormat(
	up_right_corner     = '.',
	up_left_corner      = '.',
	bottom_left_corner  = ''',
	bottom_right_corner = ''',
	up_intersection     = '.',
	left_intersection   = ':',
	right_intersection  = ':',
	middle_intersection = '+',
	bottom_intersection = ''',
	column              = '|',
	row                 = '-'
)

const tf_borderless = TextFormat(
	up_right_corner     = ' ',
	up_left_corner      = ' ',
	bottom_left_corner  = ' ',
	bottom_right_corner = ' ',
	up_intersection     = ' ',
	left_intersection   = ' ',
	right_intersection  = ' ',
	middle_intersection = ' ',
	bottom_intersection = ' ',
	column              = ' ',
	row                 = ' ',
	hlines              = [:header]
)

const tf_compact = TextFormat(
	up_right_corner     = ' ',
	up_left_corner      = ' ',
	bottom_left_corner  = ' ',
	bottom_right_corner = ' ',
	up_intersection     = ' ',
	left_intersection   = ' ',
	right_intersection  = ' ',
	middle_intersection = ' ',
	bottom_intersection  = ' ',
	column              = ' ',
	row                 = '-'
   )

const tf_simple = TextFormat(
	up_right_corner     = '=',
	up_left_corner      = '=',
	bottom_left_corner  = '=',
	bottom_right_corner = '=',
	up_intersection     = ' ',
	left_intersection   = '=',
	right_intersection  = '=',
	middle_intersection = ' ',
	bottom_intersection  = ' ',
	column              = ' ',
	row                 = '='
)

const tf_unicode_rounded = TextFormat(
	up_right_corner     = '╮',
	up_left_corner      = '╭',
	bottom_left_corner  = '╰',
	bottom_right_corner = '╯',
	up_intersection     = '┬',
	left_intersection   = '├',
	right_intersection  = '┤',
	middle_intersection = '┼',
	bottom_intersection = '┴',
	column              = '│',
	row                 = '─'
)

const tf_matrix = TextFormat(
	left_intersection   = '│',
	right_intersection  = '│',
	row                 = ' ',
	vlines              = [:begin, :end],
	hlines              = [:begin, :end]
)

struct ColumnTable
	data::Any                    # .......................................... Original table
	table::Any                   # ................... Table converted using `Tables.column`
	column_names::Vector{Symbol} # ............................................ Column names
	size::Tuple{Int, Int}        # ....................................... Size of the table
end

struct RowTable
	data::Any                    # .......................................... Original table
	table::Any                   # ..................... Table converted using `Tables.rows`
	column_names::Vector{Symbol} # ............................................ Column names
	size::Tuple{Int, Int}        # ....................................... Size of the table
end

Base.@kwdef mutable struct ProcessedTable
	data::Any
	header::Any

	# == Private Fields ====================================================================

	_additional_column_id::Vector{Symbol} = Symbol[]
	_additional_data_columns::Vector{Any} = Any[]
	_additional_header_columns::Vector{Vector{String}} = Vector{String}[]
	_additional_column_alignment::Vector{Symbol} = Symbol[]
	_additional_column_header_alignment::Vector{Symbol} = Symbol[]
	_data_alignment::Union{Symbol, Vector{Symbol}} = :r
	_data_cell_alignment::Tuple = ()
	_header_alignment::Union{Symbol, Vector{Symbol}} = :s
	_header_cell_alignment::Tuple = ()
	_max_num_of_rows::Int = -1
	_max_num_of_columns::Int = -1
	_num_data_rows::Int = -1
	_num_data_columns::Int = -1
	_num_header_rows::Int = -1
	_num_header_columns::Int = -1
end

struct PrintInfo
	ptable::ProcessedTable
	io::IOContext
	formatters::Ref{Any}
	compact_printing::Bool
	title::String
	title_alignment::Symbol
	cell_first_line_only::Bool
	renderer::Union{Val{:print}, Val{:show}}
	limit_printing::Bool
end

struct PrettyTablesConf
	confs::Dict{Symbol, Any}
end

struct UndefinedCell end

const _UNDEFINED_CELL = UndefinedCell()

PrettyTablesConf() = PrettyTablesConf(Dict{Symbol, Any}())

const T_BACKENDS = Union{Val{:auto}, Val{:text}}

############################################################################################
#                                    Private Functions                                     #
############################################################################################

# This function creates the structure that holds the global print information.
function _print_info(
	@nospecialize(data::Any),
	@nospecialize(io::IOContext);
	alignment::Union{Symbol, Vector{Symbol}} = :r,
	cell_alignment::Union{Nothing, Dict{Tuple{Int, Int}, Symbol}, Function, Tuple } = nothing,
	cell_first_line_only::Bool = false,
	compact_printing::Bool = true,
	formatters::Union{Nothing, Function, Tuple} = nothing,
	header::Union{Nothing, AbstractVector, Tuple} = nothing,
	header_alignment::Union{Symbol, Vector{Symbol}} = :s,
	header_cell_alignment::Union{Nothing, Dict{Tuple{Int, Int}, Symbol}, Function, Tuple } = nothing,
	limit_printing::Bool = true,
	max_num_of_columns::Int = -1,
	max_num_of_rows::Int = -1,
	renderer::Symbol = :print,
	row_labels::Union{Nothing, AbstractVector} = nothing,
	row_label_alignment::Symbol = :r,
	row_label_column_title::AbstractString = "",
	row_number_alignment::Symbol = :r,
	row_number_column_title::AbstractString = "Row",
	show_header::Bool = true,
	show_row_number::Bool = false,
	show_subheader::Bool = true,
	title::AbstractString = "",
	title_alignment::Symbol = :l
)

	_header = header isa Tuple ? header : (header,)

	# Create the processed table, which holds additional information about how we must print
	# the table.
	ptable = ProcessedTable(data, _header;
		alignment             = alignment,
		cell_alignment        = cell_alignment,
		header_alignment      = header_alignment,
		header_cell_alignment = header_cell_alignment,
		max_num_of_columns    = max_num_of_columns,
		max_num_of_rows       = max_num_of_rows,
		show_header           = show_header,
		show_subheader        = show_subheader,
	)

	# Add the additional columns if requested.
	if show_row_number
		_add_column!(ptable, axes(data)[1] |> collect, [row_number_column_title]; alignment = row_number_alignment, id = :row_number)
	end

	if row_labels !== nothing
		_add_column!(ptable, row_labels, [row_label_column_title]; alignment = row_label_alignment, id = :row_label)
	end

	# Make sure that `formatters` is a tuple.
	formatters === nothing  && (formatters = ())
	typeof(formatters) <: Function && (formatters = (formatters,))

	# Render.
	renderer_val = renderer == :show ? Val(:show) : Val(:print)

	# Create the structure that stores the print information.
	pinfo = PrintInfo(ptable, io, formatters, compact_printing, title, title_alignment, cell_first_line_only, renderer_val, limit_printing)

	return pinfo
end

# This is the low level function that prints the table. In this case, `data` must be
# accessed by `[i, j]` and the size of the `header` must be equal to the number of columns
# in `data`.
function _print_table(
	@nospecialize(io::IO),
	@nospecialize(data::Any);
	alignment::Union{Symbol, Vector{Symbol}} = :r,
	backend::T_BACKENDS = Val(:auto),
	cell_alignment::Union{Nothing, Dict{Tuple{Int, Int}, Symbol}, Function, Tuple } = nothing,
	cell_first_line_only::Bool = false,
	compact_printing::Bool = true,
	formatters::Union{Nothing, Function, Tuple} = nothing,
	header::Union{Nothing, AbstractVector, Tuple} = nothing,
	header_alignment::Union{Symbol, Vector{Symbol}} = :s,
	header_cell_alignment::Union{Nothing, Dict{Tuple{Int, Int}, Symbol}, Function, Tuple } = nothing,
	limit_printing::Bool = true,
	max_num_of_columns::Int = -1,
	max_num_of_rows::Int = -1,
	renderer::Symbol = :print,
	row_labels::Union{Nothing, AbstractVector} = nothing,
	row_label_alignment::Symbol = :r,
	row_label_column_title::AbstractString = "",
	row_number_alignment::Symbol = :r,
	row_number_column_title::AbstractString = "Row",
	show_header::Bool = true,
	show_row_number::Bool = false,
	show_subheader::Bool = true,
	title::AbstractString = "",
	title_alignment::Symbol = :l,
	kwargs...
)

	if backend === Val(:auto)
		# In this case, if we do not have the `tf` keyword, then we just fallback to the
		# text back end. Otherwise, check if the type of `tf`.
		if haskey(kwargs, :tf)
			tf = kwargs[:tf]

			if tf isa TextFormat
				backend = Val(:text)
			else
				throw(TypeError(:_pt, TextFormat, typeof(tf)))
			end
		else
			backend = Val(:text)
		end
	end

	context = IOContext(io, :__PRETTY_TABLES_DATA__ => Any[_getdata(data)])

	# Create the structure that stores the print information.
	pinfo = _print_info(data, context;
		alignment               = alignment,
		cell_alignment          = cell_alignment,
		cell_first_line_only    = cell_first_line_only,
		compact_printing        = compact_printing,
		formatters              = formatters,
		header                  = header,
		header_alignment        = header_alignment,
		header_cell_alignment   = header_cell_alignment,
		max_num_of_columns      = max_num_of_columns,
		max_num_of_rows         = max_num_of_rows,
		limit_printing          = limit_printing,
		renderer                = renderer,
		row_labels              = row_labels,
		row_label_alignment     = row_label_alignment,
		row_label_column_title  = row_label_column_title,
		row_number_alignment    = row_number_alignment,
		row_number_column_title = row_number_column_title,
		show_header             = show_header,
		show_row_number         = show_row_number,
		show_subheader          = show_subheader,
		title                   = title,
		title_alignment         = title_alignment
	)

	# Select the appropriate back end.
	_print_table_with_text_back_end(pinfo; kwargs...)

	return nothing
end

# ----------------------------------------------------------------------------------------------------
## Description #############################################################################
#
# Print function of the text backend.
#
############################################################################################

# Low-level function to print the table using the text back end.
function _print_table_with_text_back_end(
	pinfo::PrintInfo;
	alignment_anchor_fallback::Symbol = :l,
	alignment_anchor_fallback_override::Dict{Int, Symbol} = Dict{Int, Symbol}(),
	alignment_anchor_regex::Dict{Int, T} where T <:AbstractVector{Regex} = Dict{Int, Vector{Regex}}(),
	autowrap::Bool = false,
	body_hlines::Vector{Int} = Int[],
	body_hlines_format::Union{Nothing, NTuple{4, Char}} = nothing,
	continuation_row_alignment::Symbol = :c,
	crop::Symbol = get(pinfo.io, :limit, false) ? :both : :none,
	crop_subheader::Bool = false,
	columns_width::Union{Int, AbstractVector{Int}} = 0,
	display_size::Tuple{Int, Int} = displaysize(pinfo.io),
	equal_columns_width::Bool = false,
	ellipsis_line_skip::Integer = 0,
	highlighters::Tuple = (),
	hlines::Union{Nothing, Symbol, AbstractVector} = nothing,
	linebreaks::Bool = false,
	maximum_columns_width::Union{Int, AbstractVector{Int}} = 0,
	minimum_columns_width::Union{Int, AbstractVector{Int}} = 0,
	newline_at_end::Bool = true,
	overwrite::Bool = false,
	reserved_display_lines::Int = 0,
	show_omitted_cell_summary::Bool = true,
	sortkeys::Bool = false,
	tf::TextFormat = tf_unicode,
	title_autowrap::Bool = false,
	title_same_width_as_table::Bool = false,
	vcrop_mode::Symbol = :bottom,
	vlines::Union{Nothing, Symbol, AbstractVector} = nothing,
)
	# Unpack fields of `pinfo`.
	ptable               = pinfo.ptable
	cell_first_line_only = pinfo.cell_first_line_only
	compact_printing     = pinfo.compact_printing
	formatters           = pinfo.formatters
	io                   = pinfo.io
	limit_printing       = pinfo.limit_printing
	renderer             = pinfo.renderer
	title                = pinfo.title
	title_alignment      = pinfo.title_alignment

	# Get size information from the processed table.
	num_rows, num_columns = _data_size(ptable)
	num_header_rows, ~ = _header_size(ptable)

	# == Input Variables Verification and Initial Setup ====================================

	# Let's create a `IOBuffer` to write everything and then transfer to `io`.
	io_has_color = get(io, :color, false)::Bool
	display      = Display(has_color = io_has_color)

	# Check which type of cropping the user wants.
	if crop == :both
		display.size = display_size
	elseif crop == :vertical
		display.size = (display_size[1], -1)
	elseif crop == :horizontal
		display.size = (-1, display_size[2])
	else
		# If the table will not be cropped, we should never show an omitted cell summary.
		show_omitted_cell_summary = false
	end

	# Make sure that `vcrop_mode` is valid.
	vcrop_mode ∉ [:bottom, :middle] && (vcrop_mode = :bottom)

	reserved_display_lines < 0 && (reserved_display_lines = 0)

	# Make sure that `highlighters` is always a Ref{Any}(Tuple).
	if !(highlighters isa Tuple)
		highlighters = Ref{Any}((highlighters,))
	else
		highlighters = Ref{Any}(highlighters)
	end

	# Make sure that `maximum_columns_width` is always a vector.
	if maximum_columns_width isa Integer
		maximum_columns_width = fill(maximum_columns_width, num_columns)
	end

	# Make sure that `minimum_columns_width` is always a vector.
	if minimum_columns_width isa Integer
		minimum_columns_width = fill(minimum_columns_width, num_columns)
	end

	# Check which columns must have fixed sizes.
	columns_width isa Integer && (columns_width = fill(columns_width, num_columns))

	(length(columns_width) != num_columns) && error("The length of `columns_width` must be the same as the number of columns.")

	# The number of lines that must be skipped from printing ellipsis must be greater of equal 0.
	(ellipsis_line_skip < 0) && (ellipsis_line_skip = 0)

	# Get the number of rows and columns in the processed table.
	num_rows, num_columns = _size(ptable)

	# == Process Lines =====================================================================

	if hlines === nothing
		hlines = tf.hlines
	end
	hlines = _process_hlines(ptable, hlines)

	if vlines === nothing
		vlines = tf.vlines
	end
	vlines = _process_vlines(ptable, vlines)

	# == Number of Rows and Columns that Must be Rendered ==================================

	num_rendered_rows = num_rows
	num_rendered_columns = num_columns

	if display.size[1] > 0
		num_rendered_rows = min(num_rows, display.size[1])

		# We must render at least the header.
		num_rendered_rows = max(num_header_rows, num_rendered_rows)
	end

	if display.size[2] > 0
		num_rendered_columns = min(num_columns, ceil(Int, display.size[2] / 4))
	end

	# == Create the String Matrix with the Rendered Cells ==================================

	# In text back end, we must convert all the matrix to text before printing. This
	# procedure is necessary to obtain the column width for example so that we can align the table lines.
	table_str = Matrix{Vector{String}}(undef, num_rendered_rows, num_rendered_columns)

	# Vector that must contain the width of each column. Notice that the vector
	# `columns_width` is the user specification and must not be modified.
	actual_columns_width = ones(Int, num_rendered_columns)

	# Vector that must contain the number of lines in each rendered row.
	num_lines_in_row = zeros(Int, num_rendered_rows)

	# NOTE: Algorithm to compute the table size and number of lines in the rows.
	# Previously, the algorithm to compute the table size and the number of lines in the
	# rows was a function called after the conversion of the input matrix to the string
	# matrix. Although this approach was cleaner, we had problems when computing how many
	# columns we can fit on the display to avoid unnecessary processing. Hence, the
	# functions that fill the data are also responsible to compute the size of each column.

	# -- Table Data ------------------------------------------------------------------------

	# Fill the string matrix with the rendered cells. This function also returns the updated
	# number of rendered rows and columns given the user specifications about cropping.
	num_rendered_rows, num_rendered_columns = _text_fill_string_matrix!(
		io,
		table_str,
		ptable,
		actual_columns_width,
		display,
		formatters,
		num_lines_in_row,
		# Configuration options.
		autowrap,
		cell_first_line_only,
		columns_width,
		compact_printing,
		crop_subheader,
		limit_printing,
		linebreaks,
		maximum_columns_width,
		minimum_columns_width,
		renderer,
		vcrop_mode
	)

	# -- Column Alignment Regex ------------------------------------------------------------

	_apply_alignment_anchor_regex!(ptable, table_str, actual_columns_width, alignment_anchor_fallback,
		alignment_anchor_fallback_override, alignment_anchor_regex, columns_width, maximum_columns_width, minimum_columns_width)

	# If the user wants all the columns with the same size, select the larger.
	if equal_columns_width
		actual_columns_width = fill(maximum(actual_columns_width), num_rendered_columns)
	end

	# -- Compute Where the Horizontal and Vertical Lines Must be Drawn ---------------------

	# Create the format of the horizontal lines.
	if body_hlines_format === nothing
		body_hlines_format = (tf.left_intersection, tf.middle_intersection, tf.right_intersection, tf.row)
	end

	# Check if the last horizontal line must be drawn. This is required when computing the
	# moment that the display will be cropped.
	draw_last_hline = _check_hline(ptable, hlines, body_hlines, num_rows)

	# -- Compute the Table Width and Height ------------------------------------------------

	table_width = _compute_table_width(ptable, vlines, actual_columns_width,)
	table_height = _compute_table_height(ptable, hlines, body_hlines, num_lines_in_row)

	# -- Process the Title -----------------------------------------------------------------

	title_tokens = _tokenize_title(title, display.size[2], table_width,
		title_alignment, title_autowrap, title_same_width_as_table)

	# == Print the Table ===================================================================

	# -- Title -----------------------------------------------------------------------------

	_print_title!(display, title_tokens)

	# If there is no column and no row to be printed, just exit.
	if _data_size(ptable) == (0, 0)
		@goto print_to_output
	end

	# -- Table -----------------------------------------------------------------------------

	# Number of additional lines that must be consider to crop the display vertically.
	Δdisplay_lines = 1 + newline_at_end + reserved_display_lines + length(title_tokens)

	# Compute the number of omitted columns. We need this information to check if we need to
	# reserve a line after the table to print the omitted cell summary
	num_omitted_columns = _compute_omitted_columns(ptable, display, actual_columns_width, vlines)

	need_omitted_cell_summary = show_omitted_cell_summary && (num_omitted_columns > 0)

	# Compute the position of the continuation line with respect to the printed table line.
	if vcrop_mode != :middle
		continuation_row_line = _compute_continuation_row_in_bottom_vcrop(
			ptable,
			display,
			hlines,
			body_hlines,
			num_lines_in_row,
			table_height,
			draw_last_hline,
			need_omitted_cell_summary,
			show_omitted_cell_summary,
			Δdisplay_lines
		)
	else
		continuation_row_line = _compute_continuation_row_in_middle_vcrop(
			ptable,
			display,
			hlines,
			body_hlines,
			num_lines_in_row,
			table_height,
			need_omitted_cell_summary,
			show_omitted_cell_summary,
			Δdisplay_lines
		)
	end

	need_omitted_cell_summary = show_omitted_cell_summary && ((num_omitted_columns > 0) || (continuation_row_line > 0))

	# Now we can compute the number of omitted rows because we already computed the
	# continuation line.
	num_omitted_rows = _compute_omitted_rows(ptable, display, continuation_row_line, num_lines_in_row, body_hlines,
		hlines, need_omitted_cell_summary, Δdisplay_lines)

	# Number of lines that must be saved before the title and after printing the table.
	num_lines_around_table = need_omitted_cell_summary + newline_at_end + reserved_display_lines

	# Print the table.
	_text_print_table!(display, ptable, table_str, actual_columns_width, continuation_row_line, num_lines_in_row, num_lines_around_table,
		# Configurations.
		body_hlines, body_hlines_format, continuation_row_alignment, ellipsis_line_skip, highlighters, hlines, tf, vlines)

	# -- Summary of the Omitted Cells ------------------------------------------------------

	_print_omitted_cell_summary(display, num_omitted_columns, num_omitted_rows,
		show_omitted_cell_summary, table_width)

	@label print_to_output

	# -- Print the Buffer ------------------------------------------------------------------
	_flush_display!(io, display, overwrite, newline_at_end, display.row)

	return nothing
end

compact_type_str(T) = string(T)

function compact_type_str(T::Union)
	str = T >: Missing ? string(nonmissingtype(T)) * "?" : string(T)
	return replace(str, "Union" => "U")
end

############################################################################################
#                                    Private Functions                                     #
############################################################################################

function _aprint(buf::IO, v::String, indentation::Int = 0, nspaces::Int = 2, minify::Bool = false)
	tokens  = split(v, '\n')
	ntokens = length(tokens)

	if !minify
		padding = " "^(indentation * nspaces)

		@inbounds for i in 1:ntokens
			# If the token is empty, then we do nothing to avoid unnecessary white spaces.
			if length(tokens[i]) != 0
				print(buf, padding)
				print(buf, tokens[i])
			end
			i != ntokens && println(buf)
		end
	else
		@inbounds for i in 1:ntokens
			if length(tokens[i]) != 0
				print(buf, strip(tokens[i]))
			end
		end
	end

	return nothing
end

function _aprint(buf::IO, indentation::Int = 0, nspaces::Int = 2, minify::Bool = false)
	if !minify
		padding = " "^(indentation*nspaces)
		print(buf, padding)
	end

	return nothing
end

function _aprintln(buf::IO, v::String, indentation::Int = 0, nspaces::Int = 2, minify::Bool = false)
	if !minify
		tokens  = split(v, '\n')
		padding = " "^(indentation * nspaces)
		ntokens = length(tokens)

		@inbounds for i = 1:ntokens
			# If the token is empty, then we do nothing to avoid unnecessary white spaces.
			if length(tokens[i]) != 0
				print(buf, padding)
				println(buf, tokens[i])
			else
				println(buf)
			end
		end
	else
		_aprint(buf, v, indentation, nspaces, minify)
	end

	return nothing
end

function _aprintln(buf::IO, indentation::Int = 0, nspaces::Int = 2, minify::Bool = false)
	if !minify
		padding = " "^(indentation*nspaces)
		println(buf, padding)
	end

	return nothing
end

function _check_hline(ptable::ProcessedTable, hlines::Vector{Int}, body_hlines::AbstractVector, i::Int)
	num_header_rows = _header_size(ptable)[1]

	if (i == 0) && (0 ∈ hlines)
		return true

	elseif (num_header_rows > 0) && (i <= num_header_rows)
		if (i == num_header_rows)
			if 1 ∈ hlines
				return true
			elseif 0 ∈ body_hlines
				return true
			end
		end

	else
		Δ = num_header_rows > 0 ? 1 : 0
		i = i - num_header_rows + Δ

		if (i ∈ hlines)
			return true

		elseif ((i - Δ) ∈ body_hlines)
			return true
		end
	end

	return false
end

function _check_hline(ptable::ProcessedTable, hlines::Symbol, body_hlines::AbstractVector, i::Int)
	if hlines == :all
		return true
	elseif hlines == :none
		return _check_hline(ptable, Int[], body_hlines, i)
	else
		error("`hlines` must be `:all`, `:none`, or a vector of integers.")
	end
end

function _check_vline(ptable::ProcessedTable, vlines::AbstractVector, j::Int)
	num_printed_columns = _size(ptable)[2]

	if (j == 0) && (:begin ∈ vlines)
		return true
	elseif (j == num_printed_columns) && (:end ∈ vlines)
		return true
	elseif (j ∈ vlines)
		return true
	else
		return false
	end
end

function _check_vline(ptable::ProcessedTable, vlines::Symbol, j::Int)
	if vlines == :all
		return true
	elseif vlines == :none
		return false
	else
		error("`vlines` must be `:all`, `:none`, or a vector of integers.")
	end
end

function _count_hlines(ptable::ProcessedTable, hlines::Vector{Int}, body_hlines::Vector{Int})
	num_header_lines = _header_size(ptable)[1]
	num_rows = _size(ptable)[1]
	Δ = num_header_lines > 0 ? 1 : 0

	merged_hlines = unique(sort(vcat(hlines, body_hlines .+ Δ)))

	total_hlines = 0

	for h in merged_hlines
		if 0 ≤ h ≤ num_rows
			total_hlines += 1
		end
	end

	return total_hlines
end

function _count_hlines(ptable::ProcessedTable, hlines::Symbol, body_hlines::Vector{Int})
	num_rows = _size(ptable)[1]

	if hlines == :all
		return num_rows + 1

	elseif hlines == :none
		num_header_lines = _header_size(ptable)[1]
		Δ = num_header_lines > 0 ? 1 : 0
		merged_hlines = unique(sort(body_hlines .+ Δ))
		total_hlines = 0

		for h in merged_hlines
			if 0 ≤ h ≤ num_rows
				total_hlines += 1
			end
		end

		return total_hlines
	end
end

function _count_vlines(ptable::ProcessedTable, vlines::Vector{Int})
	num_columns = _size(ptable)[2]
	total_vlines = 0

	for h in vlines
		if 0 ≤ h ≤ num_columns
			total_vlines += 1
		end
	end

	return total_vlines
end

function _count_vlines(ptable::ProcessedTable, vlines::Symbol)
	num_columns = _size(ptable)[2]

	if vlines == :all
		return num_columns + 1

	elseif vlines == :none
		return 0

	end
end

# Return the string with the information about the number of omitted cells.
function _get_omitted_cell_string(num_omitted_rows::Int, num_omitted_columns::Int)
	cs_str_col = ""
	cs_str_and = ""
	cs_str_row = ""

	if num_omitted_columns > 0
		cs_str_col = string(num_omitted_columns)
		cs_str_col *= num_omitted_columns > 1 ? " columns" : " column"
	end

	if num_omitted_rows > 0
		cs_str_row = string(num_omitted_rows)
		cs_str_row *= num_omitted_rows > 1 ? " rows" : " row"
		num_omitted_columns > 0 && (cs_str_and = " and ")
	end

	cs_str = cs_str_col * cs_str_and * cs_str_row * " omitted"

	return cs_str
end

@inline function _process_hlines(ptable::ProcessedTable, hlines::Symbol)
	return hlines
end

@inline function _process_hlines(ptable::ProcessedTable, hlines::AbstractVector)
	# The symbol `:begin` is replaced by 0, the symbol `:header` by the line after the
	# header, and the symbol `:end` is replaced by the last row.
	num_header_rows = _header_size(ptable)[1]
	num_rows = _size(ptable)[1]
	Δ  = num_header_rows > 0 ? 1 : 0

	hlines = replace(hlines, :begin  => 0, :header => num_header_rows > 0 ? 1 : -1, :end    => num_rows - num_header_rows + Δ)

	return Vector{Int}(hlines)
end

@inline function _process_vlines(ptable::ProcessedTable, vlines::Symbol)
	return vlines
end

function _process_vlines(ptable::ProcessedTable, vlines::AbstractVector)
	# The symbol `:begin` is replaced by 0 and the symbol `:end` is replaced by the last column.
	vlines = replace(vlines, :begin => 0, :end   => _size(ptable)[2])
	return Vector{Int}(vlines)
end

#--------------------------------------------------------------------------------------------
## Description #############################################################################
#
# Functions to process and print the table title.
#
############################################################################################

# Print the table title to the display.
function _print_title!(display::Display, title_tokens::Vector{String})
	num_tokens = length(title_tokens)
	num_tokens == 0 && return nothing

	@inbounds for i in 1:num_tokens
		_write_to_display!(display, string(rstrip(title_tokens[i])), "")

		# In the last line we must not add the new line character because we need to reset
		# the crayon first if the display supports colors.
		i != num_tokens && _nl!(display)
	end

	_nl!(display)

	return nothing
end

function _str_autowrap(tokens_raw::Vector{String}, width::Int = 0)
    width <= 0 && error("If `autowrap` is true, then the width must not be positive.")
    tokens = String[]

    for token in tokens_raw
        sub_tokens = String[]
        length_tok = length(token)

        # Get the list of valid indices to handle UTF-8 strings. In this case, the n-th
        # character of the string can be accessed by `token[tok_ids[n]]`.
        tok_ids = collect(eachindex(token))

        if length_tok > width
            # First, let's analyze from the beginning of the token up to the field width.
            #
            # k₀ is the character that will start the sub-token.
            # k₁ is the character that will end the sub-token.
            k₀ = 1
            k₁ = k₀ + width - 1

            while k₀ <= length_tok
                # Check if the remaining string fit in the available space.
                if k₁ == length_tok
                    push!(sub_tokens, token[tok_ids[k₀:k₁]])

                else
                    # If the remaining string does not fit into the available space, then we
                    # search for spaces to crop.
                    Δ = 0
                    for k = k₁:-1:k₀
                        if token[tok_ids[k]] == ' '
                            # If a space is found, then select `k₁` as this character and
                            # use `Δ` to remove it when printing, so that we hide the space.
                            k₁ = k
                            Δ  = 1
                            break
                        end
                    end

                    push!(sub_tokens, token[tok_ids[k₀:k₁-Δ]])
                end

                # Move to the next analysis window.
                k₀ = k₁+1
                k₁ = clamp(k₀ + width - 1, 0, length_tok)
            end
            push!(tokens, sub_tokens...)
        else
            push!(tokens, token)
        end
    end

    return tokens
end

# Split the table title into tokens considering the line break character.
function _tokenize_title(title::AbstractString, display_width::Int, table_width::Int,
	# Configurations
	title_alignment::Symbol, title_autowrap::Bool, title_same_width_as_table::Bool)
	# Process the title separating the tokens.
	title_tokens = String[]

	if length(title) > 0
		# Compute the title width.
		title_width = title_same_width_as_table ? table_width : display_width

		# If the title width is not higher than 0, then we should only print the title.
		if title_width ≤ 0
			push!(title_tokens, title)

			# Otherwise, we must check for the alignments.
		else
			title_tokens_raw = string.(split(title, '\n'))
			title_autowrap && (title_tokens_raw = _str_autowrap(title_tokens_raw, title_width))
			num_tokens = length(title_tokens_raw)

			@inbounds for i in 1:num_tokens
				token = title_tokens_raw[i]

				# Align and crop the title.
				token_pw  = printable_textwidth(token)
				token_str = align_string(token, title_width, title_alignment; printable_string_width = token_pw)
				token_str = fit_string_in_field(token_str, title_width; printable_string_width = token_pw)

				push!(title_tokens, token_str)
			end
		end
	end

	return title_tokens
end

# --------------------------------------------------------------------------------------------

# Return `true` if the `alignment` is valid. Otherwise, return `false`.
function _is_alignment_valid(alignment::Symbol)
	return (alignment == :l) || (alignment == :c) || (alignment == :r) ||
		   (alignment == :L) || (alignment == :C) || (alignment == :R)
end

_is_alignment_valid(alignment) = false

function _is_cell_alignment_overridden(ptable::ProcessedTable, i::Int, j::Int)

	# Get the identification of the row and column.
	row_id = _get_row_id(ptable, i)
	column_id = _get_column_id(ptable, j)

	# Verify if we are at header.
	if (row_id == :__HEADER__) || (row_id == :__SUBHEADER__)
		if column_id == :__ORIGINAL_DATA__
			header_alignment_override = nothing

			# Get the cell index in the original table.
			jr = _get_data_column_index(ptable, j)

			# Search for alignment overrides in this cell.
			for f in ptable._header_cell_alignment
				header_alignment_override =
					f(ptable.header, i, jr)::Union{Nothing, Symbol}

				if _is_alignment_valid(header_alignment_override)
					return true
				end
			end
		end
	else
		if column_id == :__ORIGINAL_DATA__
			alignment_override = nothing

			# Get the cell index in the original table.
			ir = _get_data_row_index(ptable, i)
			jr = _get_data_column_index(ptable, j)

			# Search for alignment overrides in this cell.
			for f in ptable._data_cell_alignment
				alignment_override = f(_getdata(ptable.data), ir, jr)::Union{Nothing, Symbol}
				if _is_alignment_valid(alignment_override)
					return true
				end
			end
		end
	end

	return false
end

# Return `true` if the `row_id` is from the header.
function _is_header_row(row_id::Symbol)
	return (row_id == :__HEADER__) || (row_id == :__SUBHEADER__)
end

# Return `true` if the `i`th row in `ptable` is from the header.
function _is_header_row(ptable::ProcessedTable, i::Int)
	row_id = _get_row_id(ptable, i)
	return _is_header_row(row_id)
end

## Description #############################################################################
#
# Fill the string matrix that will be printed in the text back end.
#
############################################################################################

# Fill the the string matrix table.
function _text_fill_string_matrix!(
	@nospecialize(io::IOContext),
	table_str::Matrix{Vector{String}},
	ptable::ProcessedTable,
	actual_columns_width::Vector{Int},
	display::Display,
	@nospecialize(formatters::Ref{Any}),
	num_lines_in_row::Vector{Int},
	# Configuration options.
	autowrap::Bool,
	cell_first_line_only::Bool,
	columns_width::Vector{Int},
	compact_printing::Bool,
	crop_subheader::Bool,
	limit_printing::Bool,
	linebreaks::Bool,
	maximum_columns_width::Vector{Int},
	minimum_columns_width::Vector{Int},
	renderer::Union{Val{:print}, Val{:show}},
	vcrop_mode::Symbol
)
	num_rows, ~ = _size(ptable)
	num_header_rows, ~ = _header_size(ptable)
	num_rendered_rows, num_rendered_columns = size(table_str)

	# This variable stores the predicted table width. If the user wants horizontal cropping,
	# it can be use to avoid unnecessary processing of columns that will not be displayed.
	pred_table_width = 0

	@inbounds for j in 1:num_rendered_columns
		# Get the identification of the current column.
		column_id = _get_column_id(ptable, j)

		# Here we store the number of processed lines. This is used to save processing if
		# the user wants to crop the output and has cells with multiple lines.
		num_processed_lines = 0

		# Get the column index in the original data. Notice that this is ignored if the
		# column is not from the original data.
		jr = _get_data_column_index(ptable, j)

		# Store the largest cell width in this column. This leads to a double computation of
		# the cell size, here and in the `_compute_table_size_data`. However, we need this
		# to stop processing columns when cropping horizontally.
		if (column_id == :__ORIGINAL_DATA__)
			largest_cell_width = minimum_columns_width[jr] ≤ 0 ?  0 : minimum_columns_width[jr]
		else
			largest_cell_width = 0
		end

		for i in 1:num_rendered_rows
			# We need to force `cell_str` to `Vector{String}` to avoid type instabilities.
			local cell_str::Vector{String}

			# Get the identification of the current row.
			row_id = _get_row_id(ptable, i)

			# Get the row number given the crop mechanism. `i_ts` is the row index in the
			# `table_str` whereas `i_pt` is the row index in the `ptable`.
			i_ts, i_pt = _vcrop_row_number(vcrop_mode, num_rows, num_header_rows, num_rendered_rows, i)

			# Get the cell data.
			cell_data = _get_element(ptable, i_pt, j);

			if (row_id == :__HEADER__) || (row_id == :__SUBHEADER__)
				cell_str = _text_parse_cell(io, cell_data; autowrap = false, cell_first_line_only = false, column_width = -1,
					compact_printing = compact_printing, has_color = display.has_color, limit_printing = limit_printing,
					linebreaks = false, renderer = Val(:print))

			elseif (column_id == :row_label)
				cell_str = _text_parse_cell(io, cell_data; autowrap = false, cell_first_line_only = false, column_width = -1,
					compact_printing = compact_printing, has_color = display.has_color, limit_printing = limit_printing,
					linebreaks = false, renderer = Val(:print))

			elseif (column_id == :__ORIGINAL_DATA__) && (row_id == :__ORIGINAL_DATA__)
				# Get the row index in the original data.
				ir = _get_data_row_index(ptable, i_pt)

				# Check if this is a column with fixed size.
				fixed_column_width = columns_width[jr] > 0

				# Get the original type of the cell, which is used in some special cases in the renderers.
				cell_data_type = typeof(cell_data)

				# Apply the formatters.

				# Notice that `(ir, jr)` are the indices of the printed data. It means that
				# it refers to the ir-th data row and jr-th data column that will be
				# printed. We need to convert those indices to the actual indices in the input table.
				tir, tjr = _convert_axes(ptable.data, ir, jr)

				for f in formatters.x
					cell_data = f(cell_data, tir, tjr)
				end

				# Render the cell.
				cell_str = _text_parse_cell(
					io,
					cell_data,
					autowrap = autowrap && fixed_column_width,
					cell_data_type = cell_data_type,
					cell_first_line_only = cell_first_line_only,
					column_width = columns_width[jr],
					compact_printing = compact_printing,
					has_color = display.has_color,
					limit_printing = limit_printing,
					linebreaks = linebreaks,
					renderer = renderer
				)

			else
				cell_str = [string(cell_data)]

			end

			table_str[i_ts, j] = cell_str

			# Update the size of the largest cell in this column to draw the table.
			# If we are at the subheader and the user wants to crop it, just skip this computation.
			if (row_id != :__SUBHEADER__) || !crop_subheader
				largest_cell_width = max(largest_cell_width, maximum(textwidth.(cell_str)))
			end

			# Compute the number of lines so that we can avoid process unnecessary cells due
			# to cropping.
			num_lines = length(cell_str)
			num_processed_lines += num_lines
			num_lines_in_row[i_ts] = max(num_lines_in_row[i_ts], num_lines)

			# We must ensure that all header lines are processed.
			if !_is_header_row(row_id)
				# If the crop mode if `:middle`, then we need to always process a row in the
				# top and in another in the bottom before stopping due to display size. This
				# is required to avoid printing from a cell that is undefined. Notice that
				# due to the printing order in `jvec` we just need to check if `k` is even.
				if ((vcrop_mode == :bottom) || ((vcrop_mode == :middle))) &&
					(display.size[1] > 0) && (num_processed_lines ≥ display.size[1])
					break
				end
			end
		end

		if (column_id == :__ORIGINAL_DATA__)
			# Compute the column width given the user's configuration.
			actual_columns_width[j] = _update_column_width(actual_columns_width[j], largest_cell_width, columns_width[jr],
				maximum_columns_width[jr], minimum_columns_width[jr])
		else
			actual_columns_width[j] = max(actual_columns_width[j], largest_cell_width)
		end

		# If the user horizontal cropping, check if we need to process another column.
		#
		# TODO: Should we take into account the dividers?
		if display.size[2] > 0
			pred_table_width += actual_columns_width[j]

			if pred_table_width > display.size[2]
				num_rendered_columns = j
				break
			end
		end
	end

	return num_rendered_rows, num_rendered_columns
end

## Description #############################################################################
#
# Functions related to cell alignment.
#
############################################################################################

# Apply the column alignment obtained from regex to the data after conversion to string.
function _apply_alignment_anchor_regex!(ptable::ProcessedTable, table_str::Matrix{Vector{String}}, actual_column_width::Vector{Int},
	# Configurations.
	alignment_anchor_fallback::Symbol,
	alignment_anchor_fallback_override::Dict{Int, Symbol},
	alignment_anchor_regex::Dict{Int, T} where T<:AbstractVector{Regex},
	columns_width::Vector{Int},
	maximum_columns_width::Vector{Int},
	minimum_columns_width::Vector{Int}
)
	num_rendered_rows, num_rendered_columns = size(table_str)

	# If we have a key `0`, then it will be used to align all the columns.
	alignment_keys = sort(collect(keys(alignment_anchor_regex)))

	@inbounds for key in alignment_keys
		if key == 0
			regex = alignment_anchor_regex[0]
			column_vector = 1:num_rendered_columns

		else
			j = _get_table_column_index(ptable, key)
			isnothing(j) && continue
			j > num_rendered_columns && continue
			regex = alignment_anchor_regex[key]
			column_vector = j:j
		end

		for j in column_vector
			# We must not process a columns that is not part of the data, i.e., the row
			# labels or the row numbers.
			_get_column_id(ptable, j) !== :__ORIGINAL_DATA__ && continue

			# Store in which column we must align the match.
			alignment_column = 0

			jr = _get_data_column_index(ptable, j)

			# We need to pass through the entire row searching for matches to compute in
			# which column we need to align the matches.
			for i in 1:num_rendered_rows
				# We must not process a row that is a header.
				_get_row_id(ptable, i) != :__ORIGINAL_DATA__ && continue

				!isassigned(table_str, i, j) && continue
				_is_cell_alignment_overridden(ptable, i, j) && continue

				for l in 1:length(table_str[i, j])
					line = table_str[i, j][l]

					m = nothing

					for r in regex
						m_r = findfirst(r, line)
						if m_r !== nothing
							m = m_r
							break
						end
					end

					if m !== nothing
						alignment_column_i = textwidth(@views(line[1:first(m)]))
					else
						# If a match is not found, the alignment column depends on the user
						# selection.

						fallback = haskey(alignment_anchor_fallback_override, jr) ?
							alignment_anchor_fallback_override[jr] :
							alignment_anchor_fallback

						if fallback == :c
							line_len = textwidth(line)
							alignment_column_i = cld(line_len, 2)

						elseif fallback == :r
							line_len = textwidth(line)
							alignment_column_i = line_len + 1

						else
							alignment_column_i = 0
						end
					end

					if alignment_column_i > alignment_column
						alignment_column = alignment_column_i
					end
				end
			end

			# Variable to store the largest width of a cell.
			largest_cell_width = 0

			# Now, we need to pass again applying the alignments.
			for i in 1:num_rendered_rows
				# We must not process a row that is a header.
				_get_row_id(ptable, i) != :__ORIGINAL_DATA__ && continue

				!isassigned(table_str, i, j) && continue
				_is_cell_alignment_overridden(ptable, i, j) && continue

				for l in 1:length(table_str[i, j])
					line = table_str[i, j][l]

					m = nothing

					for r in regex
						m_r = findfirst(r, line)
						if m_r !== nothing
							m = m_r
							break
						end
					end

					if m !== nothing
						match_column_k = textwidth(@views(line[1:first(m)]))
						pad = alignment_column - match_column_k
					else
						# If a match is not found, the alignment column depends on the user
						# selection.

						fallback = haskey(alignment_anchor_fallback_override, jr) ?  alignment_anchor_fallback_override[jr] :
							alignment_anchor_fallback

						if fallback == :c
							line_len = textwidth(line)
							pad = alignment_column - cld(line_len, 2)
						elseif fallback == :r
							line_len = textwidth(line)
							pad = alignment_column - line_len - 1
						else
							pad = alignment_column
						end
					end

					# Make sure `pad` is positive.
					if pad < 0
						pad = 0
					end

					table_str[i, j][l]  = " "^pad * line
					line_len = textwidth(table_str[i, j][l])

					if line_len > largest_cell_width
						largest_cell_width = line_len
					end
				end
			end

			# The third pass aligns the elements correctly. This is performed by adding
			# spaces to the right so that all the cells have the same width.
			for i in 1:num_rendered_rows
				# We must not process a row that is a header.
				_get_row_id(ptable, i) != :__ORIGINAL_DATA__ && continue

				!isassigned(table_str, i, j) && continue
				_is_cell_alignment_overridden(ptable, i, j) && continue

				for l in 1:length(table_str[i, j])
					pad = largest_cell_width - textwidth(table_str[i, j][l])
					pad < 0 && (pad = 0)
					table_str[i, j][l] = table_str[i, j][l] * " "^pad
				end
			end

			# Since the alignemnt can change the column size, we need to recompute it
			# considering the user's configuration. Notice that the old value in
			# `cols_width` must be considered here because the header width is not taken
			# into account when calculating `largest_cell_width`.
			actual_column_width[j] = _update_column_width(actual_column_width[j], largest_cell_width, columns_width[jr],
														  maximum_columns_width[jr], minimum_columns_width[jr]
			)
		end

		# If the key 0 is present, we should not process any other regex.
		# TODO: Can we allow this here?
		key == 0 && break
	end

	return nothing
end

## Description #############################################################################
#
# Miscellaneous functions related to the Text back end.
#
############################################################################################

# Compute the table height.
function _compute_table_height(ptable::ProcessedTable, hlines::Union{Symbol, Vector{Int}}, body_hlines::Union{Symbol, Vector{Int}}, num_lines_in_row::Vector{Int})
	table_height = sum(num_lines_in_row) + _count_hlines(ptable, hlines, body_hlines)
	return table_height
end

# Compute the table width.
function _compute_table_width(ptable::ProcessedTable, vlines::Union{Symbol, Vector{Int}}, columns_width::Vector{Int})
	# Sum the width of the columns.
	table_width = sum(columns_width) + 2length(columns_width) + _count_vlines(ptable, vlines)

	return table_width
end

# Compute the position of the continuation row if the vertical crop is selected with the
# bottom crop mode.
function _compute_continuation_row_in_bottom_vcrop(
	ptable::ProcessedTable,
	display::Display,
	hlines::Union{Symbol, Vector{Int}},
	body_hlines::Vector{Int},
	num_lines_in_row::Vector{Int},
	table_height::Int,
	draw_last_hline::Bool,
	need_omitted_cell_summary::Bool,
	show_omitted_cell_summary::Bool,
	Δdisplay_lines::Int
)
	if display.size[1] > 0
		available_display_lines = display.size[1] - Δdisplay_lines

		if table_height > available_display_lines - need_omitted_cell_summary
			# Count the number of lines in the header considering that lines before and after it.
			num_header_lines = _count_header_lines(ptable, hlines, body_hlines, num_lines_in_row)

			# In this case, we will have to save one line to print the omitted cell summary.
			continuation_row_line = available_display_lines - draw_last_hline - show_omitted_cell_summary

			# We must print at least the header.
			continuation_row_line = max(continuation_row_line, num_header_lines)
		else
			continuation_row_line = -1
		end
	else
		continuation_row_line = -1
	end

	return continuation_row_line
end

# Compute the position of the continuation row if the vertical crop is selected with the
# middle crop mode.
function _compute_continuation_row_in_middle_vcrop(
	ptable::ProcessedTable,
	display::Display,
	hlines::Union{Symbol, Vector{Int}},
	body_hlines::Vector{Int},
	num_lines_in_row::Vector{Int},
	table_height::Int,
	need_omitted_cell_summary::Bool,
	show_omitted_cell_summary::Bool,
	Δdisplay_lines::Int
)
	# Get size information from the processed table.
	num_rows = _size(ptable)[1]

	if display.size[1] > 0
		available_display_lines = display.size[1] - Δdisplay_lines

		if table_height > available_display_lines - need_omitted_cell_summary
			# Count the number of lines in the header considering that lines
			# before and after it.
			num_header_lines = _count_header_lines(ptable, hlines, body_hlines, num_lines_in_row)

			# Number of rows available to draw table data. In this case, we will have to
			# save one line to print the omitted cell summary. In this case, the horizontal
			# lines are also considered table data. However, we must remove the last line,
			# if it must be printed, because it is always printing regardeless the display size.
			draw_last_hline = _check_hline(ptable, hlines, body_hlines, num_rows)

			available_rows_for_data = available_display_lines - num_header_lines - show_omitted_cell_summary - draw_last_hline

			# If there is no available rows for data, we need to print at least the header.
			if available_rows_for_data > 0
				continuation_row_line = div(available_rows_for_data + 1, 2, RoundUp) + num_header_lines
			else
				# We must print at least the header.
				continuation_row_line = num_header_lines
			end
		else
			continuation_row_line = -1
		end
	else
		continuation_row_line = -1
	end

	return continuation_row_line
end

# Compute the number of omitted columns.
function _compute_omitted_columns(ptable::ProcessedTable, display::Display, columns_width::Vector{Int}, vlines::Union{Symbol, Vector{Int}},)
	~, num_columns         = _size(ptable)
	num_additional_columns = _num_additional_columns(ptable)
	num_rendered_columns   = length(columns_width)

	@inbounds @views if display.size[2] > 0
		available_display_columns = display.size[2]

		fully_printed_columns = 0

		if _check_vline(ptable, vlines, 0)
			available_display_columns -= 1
		end

		for j = 1:num_rendered_columns
			# Take into account the column width plus the padding before the column.
			available_display_columns -= columns_width[j] + 1

			available_display_columns < 2 && break

			# We should neglect the additional columns when computing the number of fully
			# printed columns.
			if j > num_additional_columns
				fully_printed_columns += 1
			end

			# Take into account the column width plus the padding after the column.
			available_display_columns -= 1

			# Take into account a vertical line after the columns
			if _check_vline(ptable, vlines, j)
				available_display_columns -= 1
			end
		end

		num_omitted_columns = (num_columns - num_additional_columns) - fully_printed_columns
	else
		num_omitted_columns = 0
	end

	return num_omitted_columns
end

# Compute the number of omitted rows.
function _compute_omitted_rows(ptable::ProcessedTable, display::Display, continuation_row_line::Int, num_lines_in_row::Vector{Int},
	body_hlines::Vector{Int}, hlines::Union{Symbol, Vector{Int}}, need_omitted_cell_summary::Bool, Δdisplay_lines::Int)
	num_rows, ~       = _size(ptable)
	num_header_rows   = _header_size(ptable)[1]
	num_rendered_rows = length(num_lines_in_row)

	@views if continuation_row_line > 0
		# If we have a continuation line, we just need to pass the table from the beginning
		# to end until we reach this line. Then we pass the table from end to the
		# continuation line. In those passes, we count the number of fully displayed rows.
		# This algorithm works for both bottom and middle cropping.

		# Number of available line.
		available_display_lines = display.size[1] - Δdisplay_lines

		# Count the number of lines in the header.
		num_header_lines = _count_header_lines(ptable, hlines, body_hlines, num_lines_in_row)

		# Update the number of available lines.
		available_display_lines -= num_header_lines

		fully_printed_rows = 0
		current_line = num_header_lines

		# First pass: go from the beginning of the table to the continuation line.
		for i = (num_header_rows + 1):num_rendered_rows
			current_line += num_lines_in_row[i]

			if current_line ≥ continuation_row_line
				available_display_lines -= num_lines_in_row[i] - (current_line - continuation_row_line)
				break
			end

			available_display_lines -= num_lines_in_row[i]
			fully_printed_rows += 1

			if _check_hline(ptable, hlines, body_hlines, i)
				current_line += 1
				available_display_lines -= 1
			end
		end

		# Second pass: go from the end of the table to the continuationl line. Notice that
		# we know rows are cropped, hence we must reserve a line for the omitted cell
		# summary if the user wants.

		available_display_lines -= need_omitted_cell_summary

		for i = num_rendered_rows:-1:1
			Δi = num_rendered_rows - i

			if _check_hline(ptable, hlines, body_hlines, num_rows - Δi)
				available_display_lines -= 1
			end

			available_display_lines -= num_lines_in_row[i]
			available_display_lines < 0 && break

			fully_printed_rows += 1
		end

		num_omitted_rows = (num_rows - num_header_rows) - fully_printed_rows
	else
		num_omitted_rows = 0
	end

	return num_omitted_rows
end

# Count the number of lines in the header. It contains the first horizontal line and the
# line after the last subheader.
function _count_header_lines(ptable::ProcessedTable, hlines::Union{Symbol, Vector{Int}}, body_hlines::Vector{Int}, num_lines_in_row::Vector{Int})
	num_header_lines = 0

	@inbounds @views begin
		num_header_rows = _header_size(ptable)[1]

		if _check_hline(ptable, hlines, body_hlines, 0)
			num_header_lines += 1
		end

		num_header_lines += sum(num_lines_in_row[1:num_header_rows])

		if _check_hline(ptable, hlines, body_hlines, num_header_rows)
			num_header_lines += 1
		end
	end

	return num_header_lines
end

# Compute the column width `column_width` considering the largest cell width in the column
# `largest_cell_width`, the user specification in `column_width_specification`, and the
# maximum and minimum allowed column width in `maximum_column_width` and
# `minimum_column_width`, respectively.
function _update_column_width(column_width::Int, largest_cell_width::Int, column_width_specification::Int, maximum_column_width::Int, minimum_column_width::Int)
	if column_width_specification ≤ 0
		# The columns width must never be lower than 1.
		column_width = max(column_width, largest_cell_width)

		# Make sure that the maximum column width is respected.
		if (maximum_column_width > 0) && (maximum_column_width < column_width)
			column_width = maximum_column_width
		end

		# Make sure that the minimum column width is respected.
		(minimum_column_width > 0) && (minimum_column_width > column_width) && (column_width = minimum_column_width)
	else
		column_width = column_width_specification
	end

	return column_width
end

# Return the indices in the `table_str` and `ptable` related to the `i`th processed row.
function _vcrop_row_number(vcrop_mode::Symbol, num_rows::Int, num_header_rows::Int, num_printed_rows::Int, i::Int)
	if (vcrop_mode != :middle)
		return i, i
	else
		if i ≤ num_header_rows
			return i, i
		else
			i = i - num_header_rows

			if i % 2 == 1
				i_ts = div(i, 2, RoundDown) + num_header_rows + 1
				i_pt = i_ts
				return i_ts, i_pt
			else
				Δi = div(i, 2) - 1
				i_ts = num_printed_rows - Δi
				i_pt = num_rows - Δi
				return i_ts, i_pt
			end
		end
	end
end

# Return the available rows in `display`. If there is no row limit, this function returns -1.
function _available_rows(display::Display)
	return (display.size[1] > 0) ? (display.size[1] - display.row) : -1
end

# Draw the continuation row when the table has filled the vertical space available. This
# function prints in each column the character `⋮` with the alignment in `alignment`.
function _draw_continuation_line(display::Display, ptable::ProcessedTable, tf::TextFormat,
	columns_width::Vector{Int}, vlines::Union{Symbol, Vector{Int}}, alignment::Symbol)
	# In case of a continuation row, we want the last character to indicate that the table
	# continues both vertically and horizontally in case the text is cropped.
	old_cont_char = display.cont_char
	display.cont_char = '⋱'

	num_cols = length(columns_width)

	_check_vline(ptable, vlines, 0) && _p!(display, string(tf.column))

	@inbounds for j in 1:num_cols
		str = " " * align_string("⋮", columns_width[j], alignment; fill = true) * " "
		final_line_print = j == num_cols

		_p!(display, str, false) && break

		if _check_vline(ptable, vlines, j)
			_p!(display, string(tf.column), final_line_print, 1) && break
		end
	end

	_nl!(display)

	display.cont_char = old_cont_char

	return nothing
end

# Draw a vertical line in internal line buffer of `display` and then flush to the `io`.
function _draw_line!(display::Display, ptable::ProcessedTable, left::Char, intersection::Char, right::Char, row::Char,
	columns_width::Vector{Int}, vlines::Union{Symbol, AbstractVector},)
	# We does not want to add ellipsis when drawing lines.
	old_cont_char           = display.cont_char
	old_cont_space_char     = display.cont_space_char
	display.cont_char       = row
	display.cont_space_char = row
	display.cont_reset      = false

	num_cols = length(columns_width)

	_check_vline(ptable, vlines, 0) && _p!(display, string(left))

	@inbounds for i in 1:num_cols
		# Check the alignment and print.
		_p!(display, row^(columns_width[i] + 2)) && break

		if i != num_cols
			if _check_vline(ptable, vlines, i)
				_p!(display, string(intersection), false, 1) && break
			end
		end
	end

	if _check_vline(ptable, vlines, num_cols)
		_p!(display, string(right), true, 1)
	end

	_nl!(display)

	display.cont_char       = old_cont_char
	display.cont_space_char = old_cont_space_char
	display.cont_reset      = true

	return nothing
end

# Return `true` if the cursor is at the end of line or `false` otherwise.
function _eol(display::Display)
	return (display.size[2] > 0) && (display.column >= display.size[2])
end

# Return the string and the suffix to be printed in the display. It ensures that the return
# data will fit the `display`.
#
# The parameter `final_line_print` must be set to `true` if this is the last string that
# will be printed in the line. This is necessary for the algorithm to select whether or not
# to include the continuation character.
#
# The size of the string can be passed to `lstr` to save computational burden.  If
# `lstr = -1`, then the string length will be computed inside the function.
#
# The line buffer can be flushed to an `io` using the function `_nl!`.
#
# # Return
#
# - The new string, which is `str` cropped to fit the display.
# - The suffix to be appended to the cropped string.
# - The number of columns that will be used to print the string and the suffix.
function _fit_string_in_display(display::Display, str::String, final_line_print::Bool = false, lstr::Int = -1)
	# Get the size of the string if required.
	lstr < 0 && (lstr = textwidth(str))

	@inbounds if display.size[2] > 0
		# We need to check the continuation string that the user wants to display. The width
		# of this string must be used as a margin to the cropping algorithm.
		cont_str     = string(display.cont_space_char) * string(display.cont_char)
		field_margin = textwidth(cont_str)

		# Get the number of characters we need to crop to fit the display.
		crop = crop_width_to_fit_string_in_field(str, display.size[2] - display.column - field_margin;
			add_continuation_char = false, continuation_char = display.cont_char, printable_string_width = lstr)

		# There are two situations in which we do not need to crop the string:
		#
		#   1. If the number of characters that must be cropped is 0, it means that we have
		#      enough size to display the string plus the continuation characters. Thus, we
		#      just print the current string now. If the continuation characters are needed,
		#      they will be printed in the next cell.
		#   2. If the number of characters that must be cropped equals the size of the
		#      continuation string and we are at the final line print, we just need to print
		#      the string.

		if (final_line_print && (crop ≤ field_margin)) || (crop == 0)
			suffix = ""
			num_columns = lstr
		else
			suffix = cont_str
			str, ~ = right_crop(str, crop; keep_escape_seq = false, printable_string_width = lstr)
			num_columns = lstr - crop + field_margin
		end
	else
		suffix = ""
		num_columns = lstr
	end

	return str, suffix, num_columns
end

# Flush the content of the display buffer into `io`.
function _flush_display!(io::IO, display::Display, overwrite::Bool, newline_at_end::Bool, num_displayed_rows::Int)
	# If `overwrite` is `true`, then delete the exact number of lines of the table. This can
	# be used to replace the table in the display continuously.
	str_overwrite = overwrite ? "\e[1F\e[2K"^(num_displayed_rows - 1) : ""

	output_str = String(take!(display.buf))

	# Check if the user does not want a newline at end.
	!newline_at_end && (output_str = String(chomp(output_str)))

	print(io, str_overwrite * output_str)

	return nothing
end

# Flush the internal line buffer of `display`. It correspond to a new line in the buffer.
function _nl!(display::Display)
	# Update the information about the current columns and row of the display.
	display.row += 1
	display.column = 0

	# Flush the current line to the buffer removing any trailing space.
	str = String(rstrip(String(take!(display.buf_line))))
	println(display.buf, str)

	return nothing
end

# appends a `suffix`, resetting the decoration if required.
function _write_to_display!(display::Display, str::String, suffix::String, num_printed_text_columns::Int = -1)
	# If we reached end-of-line, just return.
	_eol(display) && return true

	if num_printed_text_columns < 0
		num_printed_text_columns = textwidth(str) + textwidth(suffix)
	end

	# Print the with correct formating.
	buf_line = display.buf_line

	write(buf_line, str, suffix)

	# Update the current column in the display.
	display.column += num_printed_text_columns

	# Return if we reached the end of line.
	return _eol(display)
end

function _p!(display::Display, str::String, final_line_print::Bool = false, lstr::Int = -1)
	_eol(display) && return true
	lstr < 0 && (lstr = textwidth(str))

	str, suffix, num_columns = _fit_string_in_display(display, str, final_line_print, lstr)

	return _write_to_display!(display, str, suffix, num_columns)
end

# Iterate the row printing state machine.
function _iterate_row_printing_state!(rps::RowPrintingState, ptable::ProcessedTable, display::Display, num_lines_in_row::Vector{Int},
	num_rendered_rows::Int, hlines::Union{Symbol, AbstractVector}, body_hlines::Vector{Int}, draw_last_hline::Bool,
	num_lines_around_table::Int, continuation_row_line::Int)
	# Loop until we find a state that must generate an action.
	action = :nop

	while action == :nop
		if rps.printed_lines == continuation_row_line
			rps.state = :continuation_line
			action = :continuation_line
			rps.printed_lines += 1
			break

		elseif rps.state == :top_horizontal_line
			rps.state = :table_line
			rps.i = 1
			rps.i_pt = 1
			rps.l = 0

			if _check_hline(ptable, hlines, body_hlines, 0)
				action = :top_horizontal_line
				rps.printed_lines += 1
				break
			else
				continue
			end

		elseif rps.state == :middle_horizontal_line
			if rps.i ≤ num_rendered_rows
				rps.state = :table_line
				rps.i += 1
				rps.i_pt += 1
				rps.l = 0
			else
				rps.state = :row_finished
			end

			continue

		elseif rps.state == :table_line
			rps.l += 1

			if rps.i ≤ num_rendered_rows
				if (rps.l ≤ num_lines_in_row[rps.i])
					action = :table_line
					rps.printed_lines += 1
					break
				else
					rps.state = :row_finished
					continue
				end
			else
				rps.state = :row_finished
				continue
			end

		elseif rps.state == :continuation_line
			# If we reached the continuation line, then we must search backwards how much
			# lines we can print and select the correct row/line indices to continue printing.

			num_rows = _size(ptable)[1]

			# Notice that here we must not consider the number of lines in the title here
			# because it is taken into account in the display (it was already printed).
			Δrows = _available_rows(display) - num_lines_around_table
			Δi = 0
			new_l = 0
			total_lines = 0

			if Δrows ≤ 0
				if draw_last_hline
					rps.state = :bottom_horizontal_line
					action = :bottom_horizontal_line
				else
					rps.state = :finish
					action = :finish
				end
				break
			end

			while (Δrows - total_lines) ≥ 0
				if _check_hline(ptable, hlines, body_hlines, num_rows - Δi)
					total_lines += 1

					if total_lines ≥ Δrows
						rps.state = :row_finished
						break
					end
				end

				total_lines += num_lines_in_row[num_rendered_rows - Δi]

				if total_lines ≥ Δrows
					new_l = total_lines - Δrows
					rps.state = :table_line
					break
				else
					Δi += 1
					new_l = 0
				end
			end

			rps.i = num_rendered_rows - Δi
			rps.i_pt = num_rows - Δi
			rps.l = new_l

			continue

		elseif rps.state == :row_finished
			has_hline = _check_hline(ptable, hlines, body_hlines, rps.i_pt)

			if rps.i < num_rendered_rows
				if has_hline
					action = :middle_horizontal_line
					rps.state = :middle_horizontal_line
					rps.printed_lines += 1
					break
				else
					rps.state = :table_line
					rps.i += 1
					rps.i_pt += 1
					rps.l = 0
					continue
				end
			else
				rps.state = :finish

				if draw_last_hline
					action = :bottom_horizontal_line
				else
					action = :finish
				end
			end

		elseif rps.state == :bottom_horizontal_line
			action = :finish
			rps.state = :finish
			break
		end
	end

	return action
end


# --------------------------------------------------------------------------------------------
#
# Auxiliary functions to print the table.
#

# Print the entire table data.
function _text_print_table!(display::Display, ptable::ProcessedTable, table_str::Matrix{Vector{String}}, actual_columns_width::Vector{Int},
	continuation_row_line::Int, num_lines_in_row::Vector{Int}, num_lines_around_table::Int,
	# Configurations.
	body_hlines::Vector{Int},
	body_hlines_format::NTuple{4, Char},
	continuation_row_alignment::Symbol,
	ellipsis_line_skip::Integer,
	@nospecialize(highlighters::Ref{Any}),
	hlines::Union{Symbol, AbstractVector},
	tf::TextFormat,
	vlines::Union{Symbol, AbstractVector}
)
	# Get size information from the processed table.
	num_rows = _size(ptable)[1]
	num_rendered_rows, num_rendered_columns = size(table_str)

	# Check if the last horizontal line must be drawn, which must happen **after** the
	# continuation line in `vcrop_mode = :bottom`.
	draw_last_hline = _check_hline(ptable, hlines, body_hlines, num_rows)

	# This variable is used to decide whether to print the continuation
	# characters.
	line_count = 0

	# Initialize the row printing state machine.
	rps = RowPrintingState()

	while rps.state ≠ :finish

		# == Row Printing State Machine ====================================================

		action = _iterate_row_printing_state!(rps, ptable, display, num_lines_in_row, num_rendered_rows, hlines, body_hlines,
			draw_last_hline, num_lines_around_table, continuation_row_line)

		# == Render the Top Line ===========================================================

		if action == :top_horizontal_line
			_draw_line!(display, ptable, tf.up_left_corner, tf.up_intersection, tf.up_right_corner, tf.row,
				actual_columns_width, vlines)

		# == Render the Middle Line ========================================================

		elseif action == :middle_horizontal_line
			# If the row is from the header, we must draw the line from the table format.
			# Otherwise, we must use the user configuration in `body_hlines_format`.
			if _is_header_row(ptable, rps.i)
				_draw_line!(display, ptable, tf.left_intersection, tf.middle_intersection, tf.right_intersection, tf.row,
					actual_columns_width, vlines)
			else
				_draw_line!(display, ptable, body_hlines_format..., actual_columns_width, vlines)
			end

		# == Render the Bottom Line ========================================================

		elseif action == :bottom_horizontal_line
			_draw_line!(display, ptable, tf.bottom_left_corner, tf.bottom_intersection, tf.bottom_right_corner, tf.row,
				actual_columns_width, vlines)

		# == Render the Continuation Line ==================================================

		elseif action == :continuation_line
			_draw_continuation_line(display, ptable, tf, actual_columns_width, vlines, continuation_row_alignment)

		# == Render a Table Line ===========================================================

		elseif (action == :table_line) || (action == :table_line_row_finished)
			i = rps.i
			l = rps.l
			row_id = _get_row_id(ptable, i)

			ir = (row_id == :__ORIGINAL_DATA__) ?  _get_data_row_index(ptable, rps.i_pt) : 0

			# Select the continuation character for this line.
			if (ellipsis_line_skip ≤ 0) || _is_header_row(row_id)
				display.cont_char = '⋯'
			else
				display.cont_char = line_count % (ellipsis_line_skip + 1) == 0 ?  '⋯' : ' '
				line_count += 1
			end

			# Check if we need to print a vertical line at the beginning of the line.
			if _check_vline(ptable, vlines, 0)
				_p!(display, string(tf.column), false, 1)
			end

			# -- Render the Cells in Each Column -------------------------------------------
			for j in 1:num_rendered_columns
				has_vline = _check_vline(ptable, vlines, j)
				final_line_print = j == num_rendered_columns && !has_vline

				# If this cell has less than `l` lines, then we just need to align it.
				if length(table_str[i, j]) < l
					# Align the text in the column.
					cell_processed_str = " "^actual_columns_width[j]

					# Print the cell with the spacing.
					_p!(display, " " * cell_processed_str * " ", false, actual_columns_width[j] + 2) && break

				else
					column_id = _get_column_id(ptable, j)

					jr = (column_id == :__ORIGINAL_DATA__) ?  _get_data_column_index(ptable, j) : 0

					# Get the alignment for this cell.
					cell_alignment = _get_cell_alignment(ptable, rps.i_pt, j)

					# Select the rendering algorithm based on the type of the cell.
					if _is_header_row(row_id) || (column_id != :__ORIGINAL_DATA__)
						table_str_ij_l = table_str[i, j][l]
						actual_columns_width_j = actual_columns_width[j]

						# Get the string printable width. Notice that, in this case, we know
						# that we do not have any invisible characters inside the string.
						str_printable_width = textwidth(table_str_ij_l)

						# Align the text in the column.
						cell_processed_str = align_string(table_str_ij_l, actual_columns_width_j, cell_alignment; fill = true, printable_string_width = str_printable_width)

						# Crop the string the make sure it fits the cell. Notice that we
						# ensure that there is not ANSI escape sequences inside this string.
						cell_processed_str = fit_string_in_field(cell_processed_str, actual_columns_width_j; keep_escape_seq = false, printable_string_width = str_printable_width)

						# Print the cell with the spacing.
						_p!(display, " " * cell_processed_str * " ", false, actual_columns_width[j] + 2) && break

					else
						# In this case, we need to process the cell to apply the correct
						# alignment and highlighters before rendering it.
						cell_data = _get_element(ptable, rps.i_pt, j)

						cell_processed_str = _text_process_data_cell(
							ptable, cell_data, table_str[i, j][l], ir, jr, l, actual_columns_width[j], cell_alignment, highlighters)

						if !(cell_data isa CustomTextCell)
							_p!(display, " " * cell_processed_str * " ", false, actual_columns_width[j] + 2) && break
						else
							# If we have a custom cell, we need a custom printing function.
							_print_custom_text_cell!(display, cell_data, cell_processed_str, l, highlighters) && break
						end
					end
				end

				# Check if we need to print a vertical line after the column.
				if has_vline
					final_line_print = j == num_rendered_columns
					_p!(display, string(tf.column), final_line_print, 1)
				end
			end

			_nl!(display)

		# == End State =====================================================================

		elseif action == :finish
			break
		end
	end

	return nothing
end

# Print the custom rext cell to the display.
#
# NOTE: `cell_str` must contain the printable text cell always.
function _print_custom_text_cell!(display::Display, cell_data::CustomTextCell, cell_processed_str::String,
	l::Int, @nospecialize(highlighters::Ref{Any}),)
	cell_printable_textwidth = printable_textwidth(cell_processed_str)

	# Print the padding character before the cell.
	_p!(display, " ", false, 1)

	# Compute the new string given the display size.
	str, suffix, ~ = _fit_string_in_display(display, cell_processed_str, false, cell_printable_textwidth)

	new_lstr = textwidth(str)

	# Check if we need to crop the string to fit the display.
	if cell_printable_textwidth > new_lstr
		crop_line!(cell_data, l, cell_printable_textwidth - new_lstr)
	end

	# Get the rendered text.
	rendered_str = get_rendered_line(cell_data, l)::String

	# Write it to the display.
	_write_to_display!(display, rendered_str, suffix, new_lstr + textwidth(suffix))

	# Print the padding character after the cell and return if the display has reached
	# end-of-line.
	return _p!(display, " ", false, 1)
end

# Print the summary of the omitted rows and columns.
function _print_omitted_cell_summary(display::Display, num_omitted_cols::Int, num_omitted_rows::Int,
	show_omitted_cell_summary::Bool, table_width::Int)
	if show_omitted_cell_summary && ((num_omitted_cols + num_omitted_rows) > 0)
		cs_str = _get_omitted_cell_string(num_omitted_rows, num_omitted_cols)

		table_display_width = (display.size[2] > 0) ? min(table_width, display.size[2]) : table_width

		if textwidth(cs_str) < table_display_width
			cs_str = align_string(cs_str, table_display_width, :r)
		end

		_write_to_display!(display, cs_str, "")
		_nl!(display)
	end

	return nothing
end

# Process the cell by applying the correct alignment and also verifying the highlighters.
function _text_process_data_cell(ptable::ProcessedTable, cell_data::Any, cell_str::String, i::Int, j::Int, l::Int,
	column_width::Int, alignment::Symbol, @nospecialize(highlighters::Ref{Any}))
	# Notice that `(i, j)` are the indices of the printed data. It means that it refers to
	# the ith data row and jth data column that will be printed. We need to convert those
	# indices to the actual indices in the input table.
	ti, tj = _convert_axes(ptable.data, i, j)

	# For Markdown cells, we will overwrite alignment and highlighters.
	lstr = textwidth(cell_str)

	if cell_data isa CustomTextCell
		# To align a custom text cell, we need to compute the alignment and cropping data
		# and apply it using the API functions.
		padding = padding_for_string_alignment(cell_str, column_width, alignment; fill = true, printable_string_width = lstr)

		if !isnothing(padding)
			left_pad, right_pad = padding
			crop_chars = 0
		else
			left_pad, right_pad = 0, 0
			crop_chars = crop_width_to_fit_string_in_field(cell_str, column_width; add_continuation_char = false, printable_string_width = lstr)
		end

		if crop_chars > 0
			apply_line_padding!(cell_data, l, 0, 0)
			crop_line!(cell_data, l, crop_chars + 1)
			append_suffix_to_line!(cell_data, l, "…")
		else
			apply_line_padding!(cell_data, l, left_pad, right_pad)
		end

		cell_str = get_printable_cell_line(cell_data, l)::String
	else
		# Align and crop the string to be printed.
		cell_str = align_string(cell_str, column_width, alignment; fill = true, printable_string_width = lstr)

		# If this is not a custom cell, we ensure it does not have any ANSI escape sequence.
		# Hence, we do not need to keep it after the cropping.
		cell_str = fit_string_in_field(cell_str, column_width; keep_escape_seq = false, printable_string_width = lstr)
	end

	return cell_str
end

# Those functions apply some pre-processing algorithms to the supported data types in
# PrettyTables.jl.

# == Vector or Matrices ====================================================================

function _preprocess_vec_or_mat(data::AbstractVecOrMat, header::Union{Nothing, AbstractVector, Tuple})
	if header === nothing
		pheader = (["Col. " * string(i) for i in axes(data, 2)],)
	elseif header isa AbstractVector
		pheader = (header,)
	else
		pheader = header
	end

	return data, pheader
end

# == Dictionaries ==========================================================================

function _preprocess_dict(dict::AbstractDict{K, V}, header::Union{Nothing, AbstractVector, Tuple}; sortkeys::Bool = false) where {K, V}
	if header === nothing
		pheader = (["Keys", "Values"], [compact_type_str(K), compact_type_str(V)])
	elseif header isa AbstractVector
		pheader = (header,)
	else
		pheader = header
	end

	k = collect(keys(dict))
	v = collect(values(dict))

	if sortkeys
		ind = sortperm(collect(keys(dict)))
		vk  = k[ind]
		vv  = v[ind]
	else
		vk = k
		vv = v
	end

	pdata = hcat(vk, vv)

	return pdata, pheader
end

# == Tables.jl =============================================================================

# -- Tables.jl with Column Access ----------------------------------------------------------

function _preprocess_column_tables_jl(data::Any, header::Union{Nothing, AbstractVector, Tuple})
	# Access the table using the columns.
	table = Tables.columns(data)

	# Get the column names.
	names = collect(Symbol, Tables.columnnames(table))

	# Compute the table size and get the column types.
	size_j::Int = length(names)
	size_i::Int = Tables.rowcount(table)

	pdata = ColumnTable(data, table, names, (size_i, size_j))

	# For the header, we have the following priority:
	#
	#     1. If the user passed a vector `header`, then use it.
	#     2. Otherwise, check if the table defines a schema to create the header.
	#     3. If the table does not have a schema, then build a default header based on the
	#        column name and type.
	if header === nothing
		sch = Tables.schema(data)

		if sch !== nothing
			types::Vector{String} = compact_type_str.([sch.types...])
			pheader = (names, types)
		else
			pheader = (pdata.column_names,)
		end
	elseif header isa AbstractVector
		pheader = (header,)
	else
		pheader = header
	end

	return pdata, pheader
end

# -- Tables.jl with Row Access -------------------------------------------------------------

function _preprocess_row_tables_jl(data::Any, header::Union{Nothing, AbstractVector, Tuple})
	# Access the table using the rows.
	table = Tables.rows(data)

	# Compute the number of rows.
	size_i::Int = length(table)

	# If we have at least one row, we can obtain the number of columns by fetching the row.
	# Otherwise, we try to use the schema.
	if size_i > 0
		row₁ = first(table)

		# Get the column names.
		names = collect(Symbol, Tables.columnnames(row₁))
	else
		sch = Tables.schema(data)

		if sch === nothing
			# In this case, we do not have a row and we do not have a schema.  Thus, we can
			# do nothing. Hence, we assume there is no row or column.
			names = Symbol[]
		else
			names = [sch.names...]
		end
	end

	size_j::Int = length(names)

	pdata = RowTable(data, table, names, (size_i, size_j))

	# For the header, we have the following priority:
	#
	#     1. If the user passed a vector `header`, then use it.
	#     2. Otherwise, check if the table defines a schema to create the header.
	#     3. If the table does not have a schema, then build a default header based on the
	#        column name and type.
	if header === nothing
		sch = Tables.schema(data)

		if sch !== nothing
			types::Vector{String} = compact_type_str.([sch.types...])
			pheader = (names, types)
		else
			pheader = (pdata.column_names,)
		end
	elseif header isa AbstractVector
		pheader = (header,)
	else
		pheader = header
	end

	return pdata, pheader
end

# -----------------------------------------------------------------------------------
# Function related to the API of Tables.jl inside PrettyTables.jl.
_getdata(ptable::ProcessedTable) = _getdata(ptable.data)
_getdata(ctable::ColumnTable) = ctable.data
_getdata(rtable::RowTable) = rtable.data
_getdata(data) = data

function ProcessedTable(data::Any, header::Any;
	alignment::Union{Symbol, Vector{Symbol}} = :r,
	cell_alignment::Union{Nothing, Dict{Tuple{Int, Int}, Symbol}, Function, Tuple } = nothing,
	header_alignment::Union{Symbol, Vector{Symbol}} = :s,
	header_cell_alignment::Union{Nothing, Dict{Tuple{Int, Int}, Symbol}, Function, Tuple } = nothing, max_num_of_rows::Int = -1,
	max_num_of_columns::Int = -1, show_header::Bool = true, show_subheader::Bool = true)
	# Get information about the table we have to print based on the format of `data`, which
	# must be an `AbstractMatrix` or an `AbstractVector`.
	dims     = size(data)
	num_dims = length(dims)

	if num_dims == 1
		num_data_rows = dims[1]
		num_data_columns = 1

	elseif num_dims == 2
		num_data_rows = dims[1]
		num_data_columns = dims[2]

	else
		throw(ArgumentError("`data` must not have more than 2 dimensions."))
	end

	# Process the header and subheader.
	num_header_rows = 0
	num_header_columns = num_data_columns

	if header !== nothing
		# Check the corner case where the header is empty.
		if length(header) == 0
			num_header_columns = 0
			num_header_rows = 0

		elseif show_header
			num_header_columns = length(first(header))

			if num_data_columns != num_header_columns
				error("The number of columns in the header ($num_header_columns) must be equal to that of the table ($num_data_columns).")
			end

			num_header_rows = show_subheader ? length(header) : 1
		end
	end

	# Make sure that `cell_alignment` is a tuple.
	if cell_alignment === nothing
		cell_alignment = ()

	elseif typeof(cell_alignment) <: Dict
		# If it is a `Dict`, then `cell_alignment[(i,j)]` contains the desired alignment for
		# the cell `(i,j)`. Thus, we need to create a wrapper function.
		cell_alignment_dict = copy(cell_alignment)
		cell_alignment = ((data, i, j) -> begin
			if haskey(cell_alignment_dict, (i, j))
				return cell_alignment_dict[(i, j)]
			else
				return nothing
			end
		end,)

	elseif typeof(cell_alignment) <: Function
		cell_alignment = (cell_alignment,)
	end

	# Make sure that `header_cell_alignment` is a tuple.
	if header_cell_alignment === nothing
		header_cell_alignment = ()

	elseif typeof(header_cell_alignment) <: Dict
		# If it is a `Dict`, then `header_cell_alignment[(i,j)]` contains the desired
		# alignment for the cell `(i,j)`. Thus, we need to create a wrapper function.
		header_cell_alignment_dict = copy(header_cell_alignment)
		header_cell_alignment = ((data, i, j) -> begin
			if haskey(header_cell_alignment_dict, (i, j))
				return header_cell_alignment_dict[(i, j)]
			else
				return nothing
			end
		end,)

	elseif typeof(header_cell_alignment) <: Function
		header_cell_alignment = (header_cell_alignment,)
	end

	# Check if the user does not want to process all the rows and columns.
	if max_num_of_rows > 0
		max_num_of_rows = min(max_num_of_rows, num_data_rows)

		# If the number of hidden rows is only 1, we should not hide any row because we will
		# need an additional row to show the continuation line.
		if (num_data_rows - max_num_of_rows) == 1
			max_num_of_rows = num_data_rows
		end
	end

	(max_num_of_columns > 0) && (max_num_of_columns = min(max_num_of_columns, num_data_columns))

	return ProcessedTable(
		data = data,
		header = header,
		_data_alignment = alignment,
		_data_cell_alignment = cell_alignment,
		_header_alignment = header_alignment,
		_header_cell_alignment = header_cell_alignment,
		_max_num_of_rows = max_num_of_rows,
		_max_num_of_columns = max_num_of_columns,
		_num_data_rows = num_data_rows,
		_num_data_columns = num_data_columns,
		_num_header_columns = num_header_columns,
		_num_header_rows = num_header_rows
	)
end

function _add_column!(ptable::ProcessedTable, new_column::AbstractVector, new_header::Vector{String} = String[""];
	alignment::Symbol = :r, header_alignment::Symbol = :s, id::Symbol = :additional_column)

	# The length of the new column must match the number of rows in the initial
	# data.
	num_rows, ~ = _data_size(ptable)

	(num_rows != length(new_column)) && error("The size of the new column does not match the size of the table.")

	# The symbol cannot be `:__ORIGINAL_DATA__` because it is used to identified
	# if a column is part of the original data.
	(id == :__ORIGINAL_DATA__) && error("The new column identification symbol cannot be `:__ORIGINAL_DATA__`.")

	push!(ptable._additional_column_id, id)
	push!(ptable._additional_data_columns, new_column)
	push!(ptable._additional_header_columns, new_header)
	push!(ptable._additional_column_alignment, alignment)
	push!(ptable._additional_column_header_alignment, header_alignment)

	return nothing
end

function _data_size(ptable::ProcessedTable)
	return ptable._num_data_rows, ptable._num_data_columns
end

function _header_size(ptable::ProcessedTable)
	return ptable._num_header_rows, ptable._num_header_columns
end

function _num_additional_columns(ptable::ProcessedTable)
	return length(ptable._additional_data_columns)
end

function _size(ptable::ProcessedTable)
	total_columns = ptable._max_num_of_columns > 0 ?
		ptable._max_num_of_columns :
		ptable._num_data_columns

	total_columns += length(ptable._additional_data_columns)

	total_rows = ptable._max_num_of_rows > 0 ?
		ptable._max_num_of_rows :
		ptable._num_data_rows

	total_rows += ptable._num_header_rows

	return total_rows, total_columns
end

function _total_size(ptable::ProcessedTable)
	total_columns = ptable._num_data_columns + length(ptable._additional_data_columns)
	total_rows = ptable._num_data_rows + ptable._num_header_rows
	return total_rows, total_columns
end

# --------------------------------------------------------------------------------------------
function _get_column_id(ptable::ProcessedTable, j::Int)
	Δc = length(ptable._additional_data_columns)

	# Check if we are in the additional columns.
	if j ≤ Δc
		return ptable._additional_column_id[j]
	else
		return :__ORIGINAL_DATA__
	end
end

function _get_data_column_index(ptable::ProcessedTable, j::Int)
	Δc = length(ptable._additional_data_columns)
	return j - Δc
end

function _get_data_row_index(ptable::ProcessedTable, i::Int)
	return i - ptable._num_header_rows
end
function _get_num_of_hidden_columns(ptable::ProcessedTable)
	if ptable._max_num_of_columns > 0
		return ptable._num_data_columns - ptable._max_num_of_columns
	else
		return 0
	end
end
function _get_row_id(ptable::ProcessedTable, j::Int)
	# Check if we are in the header columns.
	if j ≤ ptable._num_header_rows
		if j == 1
			return :__HEADER__
		else
			return :__SUBHEADER__
		end
	else
		return :__ORIGINAL_DATA__
	end
end

function _get_element(ptable::ProcessedTable, i::Int, j::Int)
	Δc = length(ptable._additional_data_columns)

	# Check if we need to return an additional column or the real data.
	if j ≤ Δc

		if i ≤ ptable._num_header_rows
			aj = _convert_axes(ptable._additional_header_columns, j)
			hj = ptable._additional_header_columns[aj]
			l  = length(hj)

			if i ≤ l
				ai = _convert_axes(hj, i)
				return hj[ai]
			else
				return ""
			end
		else
			aj  = _convert_axes(ptable._additional_data_columns, j)
			dj  = ptable._additional_data_columns[aj]
			id  = _get_data_row_index(ptable, i)
			aid = _convert_axes(dj, id)

			if isassigned(dj, aid)
				return dj[aid]
			else
				return _UNDEFINED_CELL
			end
		end
	else
		jd = _get_data_column_index(ptable, j)

		if i ≤ ptable._num_header_rows
			hi = ptable.header[i]

			# Get the data index inside the header.
			ajd = _convert_axes(hi, jd)

			return hi[ajd]
		else
			id = _get_data_row_index(ptable, i)

			# Get the data index inside the table.
			aid, ajd = _convert_axes(ptable.data, id, jd)

			if isassigned(ptable.data, aid, ajd)
				return ptable.data[aid, ajd]
			else
				return _UNDEFINED_CELL
			end
		end
	end
end

function _convert_axes(data::Any, i::Int)
	ax  = axes(data)
	ti = first(ax[1]) + i - 1
	return ti
end

function _convert_axes(data::Any, i::Int, j::Int)
	ax  = axes(data)
	ti = first(ax[1]) + i - 1
	tj = (length(ax) == 1) ? 1 : first(ax[2]) + j - 1
	return ti, tj
end

# Parse the table `cell` of type `T` and return a vector of `String` with the parsed cell
# text, one component per line.
function _text_parse_cell(@nospecialize(io::IOContext), cell::Any;
	autowrap::Bool = true,
	cell_data_type::DataType = Nothing,
	cell_first_line_only::Bool = false,
	column_width::Integer = -1,
	compact_printing::Bool = true,
	limit_printing::Bool = true,
	linebreaks::Bool = false,
	renderer::Union{Val{:print}, Val{:show}} = Val(:print),
	kwargs...
)
	isstring = cell_data_type <: AbstractString

	# Convert to string using the desired renderer.
	#
	# Due to the non-specialization of `data`, `cell` here is inferred as `Any`. However,
	# we know that the output of `_text_render_cell` must be a vector of String.
	cell_vstr::Vector{String} = _text_render_cell(renderer, io, cell, compact_printing = compact_printing, isstring = isstring,
		limit_printing = limit_printing, linebreaks = linebreaks || cell_first_line_only)

	# Check if we must autowrap the text.
	autowrap && (cell_vstr = _str_autowrap(cell_vstr, column_width))

	# Check if the user only wants the first line.
	cell_first_line_only && (cell_vstr  = [first(cell_vstr)])

	return cell_vstr
end

function _text_parse_cell(@nospecialize(io::IOContext), cell::CustomTextCell; kwargs...)
	# Call the API function to reset all the fields in the custom text cell.
	reset!(cell)
	cell_vstr = parse_cell_text(cell; kwargs...)
	return cell_vstr
end

_text_parse_cell(@nospecialize(io::IOContext), cell::Missing; kwargs...) = ["missing"]
_text_parse_cell(@nospecialize(io::IOContext), cell::Nothing; kwargs...) = ["nothing"]
_text_parse_cell(@nospecialize(io::IOContext), cell::UndefinedCell; kwargs...) = ["#undef"]

# --------------------------------------------------------------------------------------------

function _text_render_cell(::Val{:print}, @nospecialize(io::IOContext), v::Any;
	compact_printing::Bool = true, isstring::Bool = false, limit_printing::Bool = true, linebreaks::Bool = false)
	# Create the context that will be used when rendering the cell. Notice that the
	# `IOBuffer` will be neglected.
	context = IOContext(io, :compact => compact_printing, :limit => limit_printing)

	str = sprint(print, v; context = context)

	return _text_render_cell(Val(:print), io, str;
		compact_printing = compact_printing, isstring = isstring, linebreaks = linebreaks)
end

function _text_render_cell(::Val{:print}, @nospecialize(io::IOContext), str::AbstractString;
	compact_printing::Bool = true, isstring::Bool = false, limit_printing::Bool = true, linebreaks::Bool = false)
	vstr = linebreaks ? string.(split(str, '\n')) : [str]

	# NOTE: Here we cannot use `escape_string(str)` because it also adds the character `"`
	# to the list of characters to be escaped.
	output_str = Vector{String}(undef, length(vstr))

	@inbounds for i in 1:length(vstr)
		s = vstr[i]
		output_str[i] = sprint(escape_string, s, "", sizehint = lastindex(s))
	end

	return output_str
end

function _text_render_cell(::Val{:show}, @nospecialize(io::IOContext), v::Any;
	compact_printing::Bool = true, linebreaks::Bool = false, limit_printing::Bool = true, isstring::Bool = false)
	# Create the context that will be used when rendering the cell.
	context = IOContext(io, :compact => compact_printing, :limit => limit_printing)

	str  = sprint(show, v; context = context)

	return _text_render_cell(Val(:show), io, str;
		compact_printing = compact_printing, linebreaks = linebreaks, limit_printing = limit_printing, isstring = isstring)
end

function _text_render_cell(::Val{:show}, @nospecialize(io::IOContext), v::AbstractString; compact_printing::Bool = true,
	linebreaks::Bool = false, limit_printing::Bool = true, isstring::Bool = false)
	# Create the context that will be used when rendering the cell.
	context = IOContext(io, :compact => compact_printing, :limit => limit_printing)

	aux  = linebreaks ? string.(split(v, '\n')) : [v]
	vstr = sprint.(show, aux; context = context)

	if !isstring
		for i in 1:length(vstr)
			aux_i   = first(vstr[i], length(vstr[i]) - 1)
			vstr[i] = last(aux_i, length(aux_i) - 1)
		end
	end

	return vstr
end

# --------------------------------------------------------------------------------------------
function _get_cell_alignment(ptable::ProcessedTable, i::Int, j::Int)
	# Get the identification of the row and column.
	row_id = _get_row_id(ptable, i)
	column_id = _get_column_id(ptable, j)

	# Verify if we are at header.
	if (row_id == :__HEADER__) || (row_id == :__SUBHEADER__)
		if column_id == :__ORIGINAL_DATA__
			header_alignment_override = nothing

			# Get the cell index in the original table.
			jr  = _get_data_column_index(ptable, j)

			# Get the data index inside the header.
			ajr = _convert_axes(ptable.header[i], jr)

			# Search for alignment overrides in this cell.
			for f in ptable._header_cell_alignment
				header_alignment_override =
					f(ptable.header, i, ajr)::Union{Nothing, Symbol}

				if _is_alignment_valid(header_alignment_override)
					return header_alignment_override
				end
			end

			# The apparently unnecessary conversion to `Symbol` avoids type
			# instability.
			ptable_header_alignment = ptable._header_alignment

			header_alignment = ptable_header_alignment isa Symbol ?
				Symbol(ptable_header_alignment) :
				Symbol(ptable_header_alignment[jr])

			if (header_alignment == :s) || (header_alignment == :S)
				# The apparently unnecessary conversion to `Symbol` avoids type
				# instability.
				ptable_data_alignment = ptable._data_alignment

				header_alignment = ptable_data_alignment isa Symbol ?
					Symbol(ptable_data_alignment) :
					Symbol(ptable_data_alignment[jr])
			end

			return header_alignment
		else
			header_alignment = ptable._additional_column_header_alignment[j]

			if (header_alignment == :s) || (header_alignment == :S)
				header_alignment = ptable._additional_column_alignment[j]
			end

			return header_alignment
		end
	else
		if column_id == :__ORIGINAL_DATA__
			alignment_override = nothing

			# Get the cell index in the original table.
			ir = _get_data_row_index(ptable, i)
			jr = _get_data_column_index(ptable, j)

			# Get the data index inside the table.
			air, ajr = _convert_axes(ptable.data, ir, jr)

			# Search for alignment overrides in this cell.
			for f in ptable._data_cell_alignment
				alignment_override = f(_getdata(ptable.data), air, ajr)::Union{Nothing, Symbol}

				if _is_alignment_valid(alignment_override)
					return alignment_override
				end
			end

			# The apparently unnecessary conversion to `Symbol` avoids type instability.
			ptable_data_alignment = ptable._data_alignment

			alignment = ptable_data_alignment isa Symbol ?
				Symbol(ptable_data_alignment) :
				Symbol(ptable_data_alignment[jr])

			return alignment
		else
			return ptable._additional_column_alignment[j]
		end
	end
end

function _get_column_alignment(ptable::ProcessedTable, j::Int)
	# Get the identification of the row and column.
	column_id = _get_column_id(ptable, j)

	# Verify if we are at header.
	if column_id == :__ORIGINAL_DATA__
		# In this case, we must find the column index in the original data.
		jr = _get_data_column_index(ptable, j)

		# The apparently unnecessary conversion to `Symbol` avoids type instability.
		ptable_data_alignment = ptable._data_alignment
		alignment = ptable_data_alignment isa Symbol ?  Symbol(ptable_data_alignment) : Symbol(ptable_data_alignment[jr])

		return alignment
	else
		return ptable._additional_column_alignment[j]
	end
end

function _get_header_element(ptable::ProcessedTable, j::Int)
	Δc = length(ptable._additional_data_columns)

	# Check if we need to return an additional column or the real data.
	if j ≤ Δc
		return ptable._additional_header_columns[j]
	else
		# Get the data index inside the header.
		jd  = _get_data_column_index(ptable, j - Δc)
		ajd = _convert_axes(first(ptable.header), jd)

		return ptable.header[ajd]
	end
end

function _get_num_of_hidden_rows(ptable::ProcessedTable)
	if ptable._max_num_of_rows > 0
		return ptable._num_data_rows - ptable._max_num_of_rows
	else
		return 0
	end
end

function _get_table_column_index(ptable::ProcessedTable, jr::Int)
	if 0 < jr ≤ ptable._num_data_columns
		return jr + length(ptable._additional_data_columns)
	else
		return nothing
	end
end
