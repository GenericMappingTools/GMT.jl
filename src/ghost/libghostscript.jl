struct gsapi_revision_s
	product::Cstring
	copyright::Cstring
	revision::Clong
	revisiondate::Clong
end

@enum __JL_Ctag_1::UInt32 begin
	GS_ARG_ENCODING_LOCAL = 0
	GS_ARG_ENCODING_UTF8 = 1
	GS_ARG_ENCODING_UTF16LE = 2
end

@enum gs_set_param_type::Int32 begin
	gs_spt_invalid = -1
	gs_spt_null = 0
	gs_spt_bool = 1
	gs_spt_int = 2
	gs_spt_float = 3
	gs_spt_name = 4
	gs_spt_string = 5
	gs_spt_long = 6
	gs_spt_i64 = 7
	gs_spt_size_t = 8
	gs_spt_parsed = 9
	gs_spt_more_to_come = -2147483648
end

@enum __JL_Ctag_4::UInt32 begin
	GS_PERMIT_FILE_READING = 0
	GS_PERMIT_FILE_WRITING = 1
	GS_PERMIT_FILE_CONTROL = 2
end

struct gsapi_fs_t
	open_file::Ptr{Cvoid}
	open_pipe::Ptr{Cvoid}
	open_scratch::Ptr{Cvoid}
	open_printer::Ptr{Cvoid}
	open_handle::Ptr{Cvoid}
end

gsapi_revision(pr, len) = ccall((:gsapi_revision, gslib), Cint, (Ptr{gsapi_revision_s}, Cint), pr, len)

function gsapi_new_instance(pinstance, caller_handle)
	ccall((:gsapi_new_instance, gslib), Cint, (Ptr{Ptr{Cvoid}}, Ptr{Cvoid}), pinstance, caller_handle)
end

gsapi_delete_instance(instance) = ccall((:gsapi_delete_instance, gslib), Cvoid, (Ptr{Cvoid},), instance)

function gsapi_set_stdio(instance, stdin_fn, stdout_fn, stderr_fn)
	ccall((:gsapi_set_stdio, gslib), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), instance, stdin_fn, stdout_fn, stderr_fn)
end

function gsapi_set_stdio_with_handle(instance, stdin_fn, stdout_fn, stderr_fn, caller_handle)
	ccall((:gsapi_set_stdio_with_handle, gslib), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
		instance, stdin_fn, stdout_fn, stderr_fn, caller_handle)
end

gsapi_set_poll(instance, poll_fn) = ccall((:gsapi_set_poll, gslib), Cint, (Ptr{Cvoid}, Ptr{Cvoid}), instance, poll_fn)

function gsapi_set_poll_with_handle(instance, poll_fn, caller_handle)
	ccall((:gsapi_set_poll_with_handle, gslib), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), instance, poll_fn, caller_handle)
end

function gsapi_set_display_callback(instance, callback)
	ccall((:gsapi_set_display_callback, gslib), Cint, (Ptr{Cvoid}, Ptr{Cvoid}), instance, callback)
end

function gsapi_register_callout(instance, callout, callout_handle)
	ccall((:gsapi_register_callout, gslib), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), instance, callout, callout_handle)
end

function gsapi_deregister_callout(instance, callout, callout_handle)
	ccall((:gsapi_deregister_callout, gslib), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), instance, callout, callout_handle)
end

function gsapi_set_default_device_list(instance, list, listlen)
	ccall((:gsapi_set_default_device_list, gslib), Cint, (Ptr{Cvoid}, Cstring, Cint), instance, list, listlen)
end

function gsapi_get_default_device_list(instance, list, listlen)
	ccall((:gsapi_get_default_device_list, gslib), Cint, (Ptr{Cvoid}, Ptr{Cstring}, Ptr{Cint}), instance, list, listlen)
end

function gsapi_set_arg_encoding(instance, encoding)
	ccall((:gsapi_set_arg_encoding, gslib), Cint, (Ptr{Cvoid}, Cint), instance, encoding)
end

function gsapi_init_with_args(instance, argc, argv)
	ccall((:gsapi_init_with_args, gslib), Cint, (Ptr{Cvoid}, Cint, Ptr{Cstring}), instance, argc, argv)
end

function gsapi_init_with_argsA(instance, argc, argv)
	ccall((:gsapi_init_with_argsA, gslib), Cint, (Ptr{Cvoid}, Cint, Ptr{Cstring}), instance, argc, argv)
end

function gsapi_init_with_argsW(instance, argc, argv)
	ccall((:gsapi_init_with_argsW, gslib), Cint, (Ptr{Cvoid}, Cint, Ptr{Ptr{Cwchar_t}}), instance, argc, argv)
end

function gsapi_run_string_begin(instance, user_errors, pexit_code)
	ccall((:gsapi_run_string_begin, gslib), Cint, (Ptr{Cvoid}, Cint, Ptr{Cint}), instance, user_errors, pexit_code)
end

function gsapi_run_string_continue(instance, str, length, user_errors, pexit_code)
	ccall((:gsapi_run_string_continue, gslib), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Cuint, Cint, Ptr{Cint}), instance, str, length, user_errors, pexit_code)
end

function gsapi_run_string_end(instance, user_errors, pexit_code)
	ccall((:gsapi_run_string_end, gslib), Cint, (Ptr{Cvoid}, Cint, Ptr{Cint}), instance, user_errors, pexit_code)
end

function gsapi_run_string_with_length(instance, str, length, user_errors, pexit_code)
	ccall((:gsapi_run_string_with_length, gslib), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Cuint, Cint, Ptr{Cint}), instance, str, length, user_errors, pexit_code)
end

function gsapi_run_string(instance, str, user_errors, pexit_code)
	ccall((:gsapi_run_string, gslib), Cint, (Ptr{Cvoid}, Cstring, Cint, Ptr{Cint}), instance, str, user_errors, pexit_code)
end

function gsapi_run_file(instance, file_name, user_errors, pexit_code)
	ccall((:gsapi_run_file, gslib), Cint, (Ptr{Cvoid}, Cstring, Cint, Ptr{Cint}), instance, file_name, user_errors, pexit_code)
end

function gsapi_run_fileA(instance, file_name, user_errors, pexit_code)
	ccall((:gsapi_run_fileA, gslib), Cint, (Ptr{Cvoid}, Cstring, Cint, Ptr{Cint}), instance, file_name, user_errors, pexit_code)
end

function gsapi_run_fileW(instance, file_name, user_errors, pexit_code)
	ccall((:gsapi_run_fileW, gslib), Cint, (Ptr{Cvoid}, Ptr{Cwchar_t}, Cint, Ptr{Cint}), instance, file_name, user_errors, pexit_code)
end

gsapi_exit(instance) = ccall((:gsapi_exit, gslib), Cint, (Ptr{Cvoid},), instance)

function gsapi_set_param(instance, param, value, type)
	ccall((:gsapi_set_param, gslib), Cint, (Ptr{Cvoid}, Cstring, Ptr{Cvoid}, gs_set_param_type), instance, param, value, type)
end

function gsapi_get_param(instance, param, value, type)
	ccall((:gsapi_get_param, gslib), Cint, (Ptr{Cvoid}, Cstring, Ptr{Cvoid}, gs_set_param_type), instance, param, value, type)
end

function gsapi_enumerate_params(instance, iterator, key, type)
	ccall((:gsapi_enumerate_params, gslib), Cint, (Ptr{Cvoid}, Ptr{Ptr{Cvoid}}, Ptr{Cstring}, Ptr{gs_set_param_type}), instance, iterator, key, type)
end

function gsapi_add_control_path(instance, type, path)
	ccall((:gsapi_add_control_path, gslib), Cint, (Ptr{Cvoid}, Cint, Cstring), instance, type, path)
end

function gsapi_remove_control_path(instance, type, path)
	ccall((:gsapi_remove_control_path, gslib), Cint, (Ptr{Cvoid}, Cint, Cstring), instance, type, path)
end

function gsapi_purge_control_paths(instance, type)
	ccall((:gsapi_purge_control_paths, gslib), Cvoid, (Ptr{Cvoid}, Cint), instance, type)
end

function gsapi_activate_path_control(instance, enable)
	ccall((:gsapi_activate_path_control, gslib), Cvoid, (Ptr{Cvoid}, Cint), instance, enable)
end

function gsapi_is_path_control_active(instance)
	ccall((:gsapi_is_path_control_active, gslib), Cint, (Ptr{Cvoid},), instance)
end

function gsapi_add_fs(instance, fs, secret)
	ccall((:gsapi_add_fs, gslib), Cint, (Ptr{Cvoid}, Ptr{gsapi_fs_t}, Ptr{Cvoid}), instance, fs, secret)
end

function gsapi_remove_fs(instance, fs, secret)
	ccall((:gsapi_remove_fs, gslib), Cvoid, (Ptr{Cvoid}, Ptr{gsapi_fs_t}, Ptr{Cvoid}), instance, fs, secret)
end
