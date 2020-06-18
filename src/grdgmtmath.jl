"""
    grdmath(cmd::String)

Call grdmath with all commands in a single string 'cmd'.
This is not useful in itself as compared to call gmt("grdmath ....") but it's very useful
in 'movie' because it can generate shell scripts from the julai command

Full option list at [`grdmath`]($(GMTdoc)grdmath.html)
"""
function grdmath(cmd::String)

	d = KW()
	cmd = "grdmath " * cmd
	if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end		# The real useful bit od this fun
	gmt(cmd)
end

"""
    gmtmath(cmd::String)

Call gmtmath with all commands in a single string 'cmd'.
This is not useful in itself as compared to call gmt("gmtmath ....") but it's very useful
in 'movie' because it can generate shell scripts from the julai command

Full option list at [`grdmath`]($(GMTdoc)grdmath.html)
"""
function gmtmath(cmd::String)

	d = KW()
	cmd = "gmtmath " * cmd
	if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end
	gmt(cmd)
end