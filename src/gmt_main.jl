using GMT

global API			# OK, so next times we'll use this one

function gmt(cmd::String, args...)

	# ----------- Minimal error checking ------------------------
	if (~isa(cmd, String))
		error("gmt: first argument must always be a string")
	end
	n_argin = length(args)
	if (n_argin > 0 && isa(args[1], String))		# TO BE CORRECT, SHOULD BE any(isa('char'))
		error("gmt: second argument when exists must be numeric")
	end
	# -----------------------------------------------------------

	#try
		#a=API		# Must test here if it's a valid one
	#catch
		API = GMT_Create_Session("GMT5", 0)
		if (API == C_NULL)
			error("Failure to create a GMT5 Session")
		end
	#end

	# 2. Get arguments, if any, and extract the GMT module name
	# First argument is the command string, e.g., "blockmean -R0/5/0/5 -I1" or just "help"
	g_module,r = strtok(cmd)
	LL = GMT_Create_Options(API, 0, r)	# We use also the fact that GMT parses and check options
	if (LL == C_NULL)
		error("Error creating the linked list of options. Probably a bad usage.")
	end

	r = create_cmd(LL)
	if (GMT_Destroy_Options(API, pointer([LL])) != 0)
		warn("Failed to destroy the linked list of options")
	end

	options = cell(12)			# 12 should be enough for the max number of options
	i = 0
	while (~isempty(r))
		i = i + 1
		options[i],r = strtok(r)
	end
	options = options[1:i]		# Remove extra allocated cells

	# 3. Determine the GMT module ID, or list module usages and return if module is not found
	module_id, use_prefix = GMTJL_find_module(API, g_module)
	if (module_id == -1)
		error(g_module, " is not a GMT module\n")
	end

	if (use_prefix != 0)
		module_name = @sprintf("gmt%s", g_module)
	else
		module_name = g_module
	end

	# 5. Parse the command, update GMT option lists, and register in/out resources, and return X array
	n_items, info = GMTJL_pre_process(API, module_name, module_id, options, args...)
	if (n_items < 0)
		error ("Failure to parse the JL command options")
	end

	# 6. Run GMT module; give usage message if errors arise during parsing
	println("options = ", options)
	options = join(options, " ")
	status = GMT_Call_Module(API, module_name, GMT_MODULE_CMD, options)
	println("merda ", status)

	# 7. Hook up module output to Matlab plhs arguments
	OUT = GMTJL_post_process (API, info, n_items)

	return OUT
end

# ---------------------------------------------------------------------------------------------------
function create_cmd(LL)
	# Takes a LinkedList LL of gmt options created by GMT_Create_Options() and join them in a single
	# string but taking care that all options start with the '-' char and insert '<' if necessary
	# For example "-Tg lixo.grd" will become "-Tg -<lixo.grd"
	LL_up = unsafe_load(LL);
	done = false
	a = IOBuffer()
	while (!done)
		print(a, '-', char(LL_up.option))
		print(a, bytestring(LL_up.arg))
		if (LL_up.next != C_NULL)
			print(a, " ")
			LL_up = unsafe_load(LL_up.next);
		else
			done = true
		end
	end
	return takebuf_string(a)
end

# ---------------------------------------------------------------------------------------------------
function strtok(args, delim::ASCIIString=" ")
# A Matlab like strtok function
	tok = "";	r = ""
	if (~is_valid_ascii(args))
		return tok, r
	end

	ind = search(args, delim)
	if (isempty(ind))
		return lstrip(args,collect(delim)), r		# Always clip delimiters at the begining
	end
	tok = lstrip(args[1:ind[1]-1], collect(delim))	#		""
	r = lstrip(args[ind[1]:end], collect(delim))

	return tok,r
end
