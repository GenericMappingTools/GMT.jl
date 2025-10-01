"""
    grdmath(cmd::String, args...)

Call grdmath with all commands in a single string 'cmd'.
This is not useful in itself as compared to call gmt("grdmath ....") but it's very useful
in 'movie' because it can generate shell scripts from the julai command

See full GMT docs at [`grdmath`]($(GMTdoc)grdmath.html)
"""
function grdmath(cmd::String, args...)

	d = KW()
	cmd = "grdmath " * cmd
	(dbg_print_cmd(d, cmd) !== nothing) && return cmd		# The real useful bit od this fun
	gmt(cmd, args...)
end

"""
    gmtmath(cmd::String, args...)

Call gmtmath with all commands in a single string 'cmd'.
This is not useful in itself as compared to call gmt("gmtmath ....") but it's very useful
in 'movie' because it can generate shell scripts from the julai command

See full GMT docs at [`grdmath`]($(GMTdoc)grdmath.html)
"""
function gmtmath(cmd::String, args...)

	d = KW()
	cmd = "gmtmath " * cmd
	(dbg_print_cmd(d, cmd) !== nothing) && return cmd
	gmt(cmd, args...)
end