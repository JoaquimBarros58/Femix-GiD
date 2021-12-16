# #############################################################################
# general.tcl --
#
# GiD-FEMIX problem type.
#
# General utilities procedures.
# #############################################################################

namespace eval General { }

# Compares two lists.
# 
# @param list1 First list
# @param list2 Second list
# @return: 0 if the list are equals or 1 otherwise.
proc General::ListCompare {list1 list2} {
    set diff [lmap n [concat $list1 $list2] {
        # Skip the elements that are in both lists
        if {$n in $list1 && $n in $list2} continue
        set n
    }]

    if {[llength $diff] > 0} {
        return 1 ; # different 
    } else {
        return 0 ; # equal
    }
}

# Create a dictionary from a string
# 
# @param s List containaing a pair key1 value1, e.g {key1 1 key2 {my string} key3 {1 2}}
# @return A dictionary constructed from the given list.
proc General::ListToDict {s} {
    set d [dict create]
    for {set i 0} {$i < [llength $s]} {incr i 2} {
        dict set d [lindex $s $i] [lindex $s [expr $i + 1]]
    }
    return $d
}