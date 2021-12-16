# #############################################################################
# string.tcl --
#
# GiD-FEMIX problem type.
#
# String utilities procedures.
# #############################################################################

namespace eval String { }

# Checks if a string is a number.
# 
# @param values A given string.
# 
# @return The number if the string is a number or an empty list if the string
# is not a number.
proc String::IsNumeric {value} {
    set value [string trim $value]
    # Use [string is double] to accept Inf and NaN
    if {[string is double -strict $value]} {
        return $value
    }
    regsub {^\s*([+-])*0[BOXbox]?0*([^[:space:]]*)\s*$} $value {\1\2} value
    if {[string is double -strict $value]} {
        return $value
    }
    return {} 
}

# Counts the number of occurrences  of a character.
#
# @param args first argument is the searched character and second argument is the
#        string.
#
# @return It returns the number of characters found in the string. If the option
#         -inline is used it returns a list with the position of the characters in
#         the string
#
# Example:
#    >> string_occurrences "_" "aaa_bbb_ccc"
#    >> string_occurrences -inline "_" "aaa_bbb_ccc"
proc String::NumCharsOccur {args} {
    set opt [lindex $args 0]
    set needleString [lindex $args end-1]
    set haystackString [lindex $args end]

    set j [string first $needleString $haystackString 0]

    if {$j == -1} {return ""}
    append res $j

    set i 0
    set d [string length $needleString]
    while {$j != -1 } {
        set j [string first $needleString $haystackString [incr j]]
        incr i $d
        if {$j != -1} { lappend res $j }
    }

    if { $opt eq "-inline" } { return $res }
    return $i
}

# Splits a string by a delimeter and returns a list containing the splitted 
# values.
# 
# @param str String to be splitted.
# @param delimeter String used to split the variable.
# 
# @return A list containing the splitted values. Note that all empty list values will 
#         be removed from the returned list.
proc String::GetList {str {delimeter " "}} {
    return [lsearch -all -inline -not -exact [split $str $delimeter] {}] ; 
}

# Gets a substring from 0 up to a given position.
#
# @param s String
# @param c Delimeter character.
# @param n Number of occurrences.
#
# @param A substring from 0 up to the nth position. The last occurrence of the 
#        character is not included.
#
# Example:
#    >> puts [GetUpTo "aa_bb_cc_dd" "_" 2]
#    >> aa_bb  
proc String::GetUpTo {s c n} {
    set name ""
    
    set count 0
    foreach char [split $s ""] {
        if {$count < $n} {
            append name $char
            if {$char == $c} {
                incr count
            }
        }
    }
    
    return [string range $name 0 end-1]
}

# Check if the string is an integer.
# 
# @param newval Value to be checked.
# @return 1 if the value is an integer, otherwise it returns 0.
proc CheckInteger {newval} {
   return [expr {[regexp {^[0-9]*$} $newval]}]
}

# Check if the string is a float.
# 
# @param newval Value to be checked.
# @return 1 if the value is a float, otherwise it returns 0.
proc CheckFloat {newval} {
   return [expr {[regexp {[+-]?([0-9]*[.])?[0-9]+} $newval]}]
}

# Gets the values of the range, the range has the following format: 1-10.
# 
# @param s Range string.
# @return A list containing the start and end of the range, e.g. 1-10 => {1 10}.
#         If the given string is not in the correct format it returns null.
proc String::GetRange {s} {
    set s1 [string map {" " ""} $s]
    set v [split $s1 -]

    if {[llength $v] != 2} {return}
    
    foreach i $v {
        set checked [CheckInteger [string trim $i]]
        if {!$checked} {return}
    }
    
    return $v
}



