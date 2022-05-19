# Collect generic utility functions in this file

""" Return the decimal part of a float number `x`"""
getdecimal(x::AbstractFloat) = x - trunc(Int, x)
