## Description #############################################################################
#
# Tests of default printing.
#
############################################################################################

@testset "Default" begin

data = Any[1    false      1.0     0x01 ;
           2     true      2.0     0x02 ;
           3    false      3.0     0x03 ;
           4     true      4.0     0x04 ;
           5    false      5.0     0x05 ;
           6     true      6.0     0x06 ;]

    expected = """
┌────────┬────────┬────────┬────────┐
│ Col. 1 │ Col. 2 │ Col. 3 │ Col. 4 │
├────────┼────────┼────────┼────────┤
│      1 │  false │    1.0 │      1 │
│      2 │   true │    2.0 │      2 │
│      3 │  false │    3.0 │      3 │
│      4 │   true │    4.0 │      4 │
│      5 │  false │    5.0 │      5 │
│      6 │   true │    6.0 │      6 │
└────────┴────────┴────────┴────────┘
"""
    result = prettytable(String, data)
    @test result == expected

    # Without a newline at end.
    expected = """
┌────────┬────────┬────────┬────────┐
│ Col. 1 │ Col. 2 │ Col. 3 │ Col. 4 │
├────────┼────────┼────────┼────────┤
│      1 │  false │    1.0 │      1 │
│      2 │   true │    2.0 │      2 │
│      3 │  false │    3.0 │      3 │
│      4 │   true │    4.0 │      4 │
│      5 │  false │    5.0 │      5 │
│      6 │   true │    6.0 │      6 │
└────────┴────────┴────────┴────────┘"""

    result = prettytable(String, data, newline_at_end = false)
    @test result == expected
end

@testset "Pre-defined formats" begin

data = Any[1    false      1.0     0x01 ;
           2     true      2.0     0x02 ;
           3    false      3.0     0x03 ;
           4     true      4.0     0x04 ;
           5    false      5.0     0x05 ;
           6     true      6.0     0x06 ;]

    # == ascii_dots ========================================================================

    expected = """
.....................................
: Col. 1 : Col. 2 : Col. 3 : Col. 4 :
:........:........:........:........:
:      1 :  false :    1.0 :      1 :
:      2 :   true :    2.0 :      2 :
:      3 :  false :    3.0 :      3 :
:      4 :   true :    4.0 :      4 :
:      5 :  false :    5.0 :      5 :
:      6 :   true :    6.0 :      6 :
:........:........:........:........:
"""
    result = prettytable(String, data, tf = GMT.tf_ascii_dots)
    @test result == expected

    # == ascii_rounded =====================================================================

    expected = """
.--------.--------.--------.--------.
| Col. 1 | Col. 2 | Col. 3 | Col. 4 |
:--------+--------+--------+--------:
|      1 |  false |    1.0 |      1 |
|      2 |   true |    2.0 |      2 |
|      3 |  false |    3.0 |      3 |
|      4 |   true |    4.0 |      4 |
|      5 |  false |    5.0 |      5 |
|      6 |   true |    6.0 |      6 |
'--------'--------'--------'--------'
"""
    result = prettytable(String, data, tf = GMT.tf_ascii_rounded)
    @test result == expected

    # == borderless ========================================================================

    expected = """
  Col. 1   Col. 2   Col. 3   Col. 4

       1    false      1.0        1
       2     true      2.0        2
       3    false      3.0        3
       4     true      4.0        4
       5    false      5.0        5
       6     true      6.0        6
"""
    result = prettytable(String, data, tf = GMT.tf_borderless)
    @test result == expected

    # == compact ===========================================================================

    expected = """
 -------- -------- -------- --------
  Col. 1   Col. 2   Col. 3   Col. 4
 -------- -------- -------- --------
       1    false      1.0        1
       2     true      2.0        2
       3    false      3.0        3
       4     true      4.0        4
       5    false      5.0        5
       6     true      6.0        6
 -------- -------- -------- --------
"""
    result = prettytable(String, data, tf = GMT.tf_compact)
    @test result == expected

    # == matrix ============================================================================

    expected = """
┌                  ┐
│ 1  false  1.0  1 │
│ 2   true  2.0  2 │
│ 3  false  3.0  3 │
│ 4   true  4.0  4 │
│ 5  false  5.0  5 │
│ 6   true  6.0  6 │
└                  ┘
"""
    result = prettytable(String, data, tf = GMT.tf_matrix, show_header = false)
    @test result == expected

    # == simple ============================================================================

    expected = """
========= ======== ======== =========
  Col. 1   Col. 2   Col. 3   Col. 4
========= ======== ======== =========
       1    false      1.0        1
       2     true      2.0        2
       3    false      3.0        3
       4     true      4.0        4
       5    false      5.0        5
       6     true      6.0        6
========= ======== ======== =========
"""
    result = prettytable(String, data, tf = GMT.tf_simple)
    @test result == expected

    # == unicode_rounded ===================================================================

    expected = """
╭────────┬────────┬────────┬────────╮
│ Col. 1 │ Col. 2 │ Col. 3 │ Col. 4 │
├────────┼────────┼────────┼────────┤
│      1 │  false │    1.0 │      1 │
│      2 │   true │    2.0 │      2 │
│      3 │  false │    3.0 │      3 │
│      4 │   true │    4.0 │      4 │
│      5 │  false │    5.0 │      5 │
│      6 │   true │    6.0 │      6 │
╰────────┴────────┴────────┴────────╯
"""
    result = prettytable(String, data, tf = GMT.tf_unicode_rounded)
    @test result == expected

    # == Custom formats ====================================================================

    expected = """
│ Col. 1 │ Col. 2 │ Col. 3 │ Col. 4 │
├────────┼────────┼────────┼────────┤
│      1 │  false │    1.0 │      1 │
│      2 │   true │    2.0 │      2 │
│      3 │  false │    3.0 │      3 │
│      4 │   true │    4.0 │      4 │
│      5 │  false │    5.0 │      5 │
│      6 │   true │    6.0 │      6 │
"""

    tf = GMT.TextFormat(hlines = [:header])
    result = prettytable(String, data, tf = tf)
    @test result == expected

    expected = """
┌────────┬────────┬────────┬────────┐
│ Col. 1 │ Col. 2 │ Col. 3 │ Col. 4 │
│      1 │  false │    1.0 │      1 │
│      2 │   true │    2.0 │      2 │
│      3 │  false │    3.0 │      3 │
│      4 │   true │    4.0 │      4 │
│      5 │  false │    5.0 │      5 │
│      6 │   true │    6.0 │      6 │
└────────┴────────┴────────┴────────┘
"""

    tf = GMT.TextFormat(hlines = [:begin,:end])
    result = prettytable(String, data, tf = tf)
    @test result == expected
end

@testset "Dictionaries" begin
    dict = Dict{Int64,String}(
        1 => "Jan",
        2 => "Feb",
        3 => "Mar",
        4 => "Apr",
        5 => "May",
        6 => "Jun"
    )

    expected = """
┌───────┬────────┐
│  Keys │ Values │
│ Int64 │ String │
├───────┼────────┤
│     1 │    Jan │
│     2 │    Feb │
│     3 │    Mar │
│     4 │    Apr │
│     5 │    May │
│     6 │    Jun │
└───────┴────────┘
"""

    result = prettytable(String, dict, sortkeys = true)
    @test result == expected
end

@testset "Vectors" begin

    vec = 0:1:10

    expected = """
┌────────┐
│ Col. 1 │
├────────┤
│      0 │
│      1 │
│      2 │
│      3 │
│      4 │
│      5 │
│      6 │
│      7 │
│      8 │
│      9 │
│     10 │
└────────┘
"""

    result = prettytable(String, vec)
    @test result == expected

    expected = """
┌─────┬────────┐
│ Row │ Col. 1 │
├─────┼────────┤
│   1 │   0    │
│   2 │   1    │
│   3 │   2    │
│   4 │   3    │
│   5 │   4    │
│   6 │   5    │
│   7 │   6    │
│   8 │   7    │
│   9 │   8    │
│  10 │   9    │
│  11 │   10   │
└─────┴────────┘
"""

    result = prettytable(String, vec; alignment = :c, show_row_number = true)
    @test result == expected

    expected = """
┌────────────┐
│     Header │
│ Sub-header │
├────────────┤
│          0 │
│          1 │
│          2 │
│          3 │
│          4 │
│          5 │
│          6 │
│          7 │
│          8 │
│          9 │
│         10 │
└────────────┘
"""

    result = prettytable(String, vec; header = (["Header"], ["Sub-header"]))
    @test result == expected

    @test_throws Exception prettytable( vec; header = ["1", "1"])
end

@testset "Print missing, nothing, and #undef" begin

    matrix = Matrix{Any}(undef,3,3)
    matrix[1,1:2] .= missing
    matrix[2,1:2] .= nothing
    matrix[3,1]   = missing
    matrix[3,2]   = nothing

    expected = """
┌─────────┬─────────┬────────┐
│  Col. 1 │  Col. 2 │ Col. 3 │
├─────────┼─────────┼────────┤
│ missing │ missing │ #undef │
│ nothing │ nothing │ #undef │
│ missing │ nothing │ #undef │
└─────────┴─────────┴────────┘
"""

    result = prettytable(String, matrix)
    @test result == expected
end

@testset "Overwrite" begin
data = Any[1    false      1.0     0x01 ;
           2     true      2.0     0x02 ;
           3    false      3.0     0x03 ;
           4     true      4.0     0x04 ;
           5    false      5.0     0x05 ;
           6     true      6.0     0x06 ;]

    result = prettytable(
        String,
        data;
        header = (["A", "B", "C", "D"], ["E", "F", "G", "H"]),
        body_hlines = collect(1:1:6)
    )

    num_lines = length(findall(x->x == '\n', result))

    io = IOBuffer()
    prettytable(
        io,
        data;
        header = (["A", "B", "C", "D"], ["E", "F", "G", "H"]),
        body_hlines = collect(1:1:6),
        overwrite = true
    )

    io_result = String(take!(io))

    @test io_result == ("\e[1F\e[2K"^(num_lines) * result)

    GMT._next_string_state('a', :escape_state_begin)
    GMT._next_string_state('a', :escape_state_opening)
    GMT._next_string_state('a', :escape_state_1)
    GMT._next_string_state('a', :escape_state_2)
    GMT._next_string_state('a', :escape_state_3)
    GMT._next_string_state('a', :escape_hyperlink_opening)
    GMT._next_string_state('a', :escape_hyperlink_1)
    GMT._next_string_state('a', :escape_hyperlink_2)
    GMT._next_string_state('a', :escape_hyperlink_1)
    GMT._next_string_state('a', :escape_hyperlink_3)
    GMT._next_string_state('a', :escape_hyperlink_end)
    GMT._next_string_state('a', :escape_state_end)
end
