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
# Arguments:
# ----------
# list1: First list
# list2: Second list
# 
# Return:
# -------
# 0 if the list are equals or 1 otherwise.
# 
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