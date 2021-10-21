# #############################################################################
# utils.tcl --
#
# GiD-FEMIX problem type.
#
# Utilities procedures.
# #############################################################################

# Warning about minimum recommended GiD version.
# 
proc Femix::WarnAboutVersion {} {
    variable femixVars

    if { [GidUtils::VersionCmp $femixVars(CheckMinimumGiDVersion)] < 0 } {
        W "Warning: femix interface requires GiD $femixVars(CheckMinimumGiDVersion) or later."
        if { [GidUtils::VersionCmp 14.0.0] < 0 } {
            W "If you are still using a GiD version 13.1.7d or later, you can still use most of the features, but think about upgrading to GiD 14." 
        } {
            W "If you are using an official version of GiD 14, we recommend to use the latest developer version"
        }
        W "Download it from: https://www.gidhome.com/download/developer-versions/"
    }
}

# Gets the model name.
# 
# Arguments:
# ----------
# file: Absolute path of the model filename. If this argument is not provided
#       then it will return the current project directory path.
#
# Return
# -------
# The name of the model.
#
proc Femix::GetModelName {{file ""}} {
    if {$file == ""} {
        return [file tail [GiD_Info project ModelName]]
    } else {
        set dir [file dirname $file]; 
        set filename [file tail $file]; 
        set first [string first "_" $filename]
        set ext [file extension $file]
        set last [string last "_" $filename]
        set ext [string range $filename $last end]

        # Model name being extracted from a di.pva file.
        if {$ext == "_di.pva"} {
            set nu 2
        # from a se.pva or sa.pva.
        } elseif {$ext == "_se.pva" || $ext == "_sa.pva"} {
            set nu 3
        # general file.
        } else {
            set nu 0
        }

        set n [expr [String::NumCharsOccur "_" $file] - $nu]
        return [String::GetUpTo $file "_" $n]
    }
    
}

# Gets the project directory.
# 
# Arguments:
# ----------
# file: Absolute path of the model filename. If this argument is not provided
#       then it will return the current project directory path.
#
# Return
# -------
# The path to the project directory.
#
proc Femix::GetProjecDir {{file ""}} {
    if {$file == ""} {
        return "[GiD_Info Project ModelName].gid"
    } else {
        return [file dirname $file]; 
    }
}

# Gets the current job, i.e. the absolute path to femix dat file.
#
# Return
# -------
# The name of the femix dat file containing the absolute path to it.
# For example:
#    C:\Data\Projects\beam
#
proc Femix::GetJob {} {
    return [file join [Femix::GetProjecDir] [Femix::GetModelName]]
}

# Gets the dimension number of the model.
# 
# Return
# -------
# 2 for 2D or 3 for 3D
# 
proc Femix::GetNumDimension {} {
    set bbox [GiD_Info bounding_box]
    set check [expr {[lindex $bbox 5] - [lindex $bbox 4]}]
    if {$check > 0.0} {
        return 3
    } else {
        return 2
    }
}

# Checks if the model is saved.
# 
# Return
# -------
# It returns 1 if saved, or 0 otherwise.
# 
proc Femix::IsModelSaved {} {  
    # Model must be saved
    if {[GiD_Info Project Modelname] eq "UNNAMED"} {
        WarnWin "Save your model first!"
        return 0 ; 
    } else {
        return 1 ;
    }
}

# Gets the range of a given list of integers.
#
# Arguments:
# ----------
# items: List of integer values.
# 
# Return:
# ----------
# The minimum and maximum integer formated according to femix range style.
# e.g. [1-56]
# 
proc Femix::GetRange {items} {
    if {$items == ""} { return "" }

    set min [tcl::mathfunc::min {*}$items]
    set max [tcl::mathfunc::max {*}$items]
    return "\[$min-$max\]"
}

# This procedure checks if a value is allowed or not, i.e. if the given value 
# is not a mumber the procedure checks if it is valid. Numeric values are 
# always allowed. However, if the given value is a string it should exist in 
# the list of allowed words. This situation happens when femix allows
# a keyword or constant value.
#
# Arguments:
# ----------
# value: Value to be checked.
# lst: List of allowed values.
# 
# Return:
# ----------
# The numeric value or the allowed word.
# 
proc Femix::CheckValue {value lst} {
    set val [String::IsNumeric $value]
    if {$val != ""} { # is the value a number?...
        return $value
    } else { # or is it a available keyword?
        if {$val in $lst} {
            return _$value
        } 
        return _[lindex $lst 0]
    }
}

# Checks if the mesh elements are quadratic or linear.
#
# Return:
# ----------
# 1 if quadratic or 0 if linear.
# 
proc Femix::IsQuadratic {} {
    return [GiD_Info Project Quadratic]
}

# Converts the quadratic element connectivity ordering from GiD to Femix.
# 
# Example:
#   GiD                Femix
#   4----7----3        7----6----5
#   |         |        |         |
#   8         6   =>   8         4
#   |         |        |         |
#   1----5----2        1----2----3
#
# Arguments:
# ----------
# id: Element id.
# 
# Return:
# ----------
# The connectivity according to femix ordering.
# 
proc Femix::GetConn {id} {
    set elConn [GiD_Mesh get element $id connectivities]
    set nn [llength $elConn]
    set conn {}

    if {[Femix::IsQuadratic] == 1} {
        if {$nn == 3} { # linear
            lappend conn [lindex $elConn 0]
            lappend conn [lindex $elConn 2]
            lappend conn [lindex $elConn 1]
            return $conn
        } elseif {$nn == 8} { # Quadrilaterals
            set size [expr [llength $elConn] / 2 ]
            for {set index 0} {$index < $size} {incr index} {
                lappend conn [lindex $elConn $index]
                lappend conn [lindex $elConn [expr $index + $size]]
            }
        } elseif {$nn == 20 } { # Hexahedra
            for {set i 0} {$i < 4} {incr i} {
                lappend conn [lindex $elConn $i]
                lappend conn [lindex $elConn [expr $i+8]]
            }
            for {set i 12} {$i < 16} {incr i} {
                lappend conn [lindex $elConn $i]
            }
            for {set i 4} {$i < 8} {incr i} {
                lappend conn [lindex $elConn $i]
                lappend conn [lindex $elConn [expr $i+12]]
            }
        }

        return $conn
    } else {
        # For 1D element, we must print the nodes of the connectivities in 
        # ascendent order, i.e. from the smaller node id towards the bigger id.
        if {[llength $elConn] == 2} {
            return [lsort -integer -increasing $elConn]
        }

        return $elConn
    }
}
# ============================================================================
# Converts from GiD
# TODO: WRITE FUNCTION TO CONVERT CONNECTIVITIES FROM GID TO FEMIX
#
#
proc Femix::ElemConnOrdering {c} {
    set size [llength $c]
    set newc {}
    
    if {$size == 8} { # Quadrilateral
        for {set i 0} {$i < [llength $c]} {incr i 2} {
            lappend newc [lindex $c $i]
        }
        for {set i 1} {$i < [llength $c]} {incr i 2} {
            lappend newc [lindex $c $i]
        }
    } elseif {$size == 20} { # Hexahedra
        return [FemixToGid $c]
    }

    return $newc
}

proc FemixToGid {c} {
    set size [llength $c]
    set newc {}
    
    if {$size == 8} { # Quadrilateral
        for {set i 0} {$i < [llength $c]} {incr i 2} {
            lappend newc [lindex $c $i]
        }
        for {set i 1} {$i < [llength $c]} {incr i 2} {
            lappend newc [lindex $c $i]
        }
    } elseif {$size == 20} { # Hexahedra
        for {set i 0} {$i < 8} {incr i 2} {
            lappend newc [lindex $c $i]
        }
        for {set i 12} {$i < 20} {incr i 2} {
            lappend newc [lindex $c $i]
        }
        for {set i 1} {$i < 8} {incr i 2} {
            lappend newc [lindex $c $i]
        }
        for {set i 8} {$i < 12} {incr i} {
            lappend newc [lindex $c $i]
        }
        for {set i 13} {$i < 20} {incr i 2} {
            lappend newc [lindex $c $i]
        }
    }

    return $newc
}

proc GidToFemix {c} {
    set size [llength $c]
    set newc {}
    
    if {$size == 8} { # Quadrilateral
        set size [expr [llength $c]/2]
        for {set i 0} {$i < $size} {incr i} {
            lappend newc [lindex $c $i]
            lappend newc [lindex $c [expr $i+4]]
        }
    } elseif {$size == 20} { # Hexahedra
        for {set i 0} {$i < 4} {incr i} {
            lappend newc [lindex $c $i]
            lappend newc [lindex $c [expr $i+8]]
        }
        for {set i 12} {$i < 16} {incr i} {
            lappend newc [lindex $c $i]
        }
        for {set i 4} {$i < 8} {incr i} {
            lappend newc [lindex $c $i]
            lappend newc [lindex $c [expr $i+12]]
        }
    }

    return $newc
}
# ============================================================================

# Creates the posfemix bat file and saves it to the project folder.
# 
proc Femix::CreatePosBat {} {
    set dir [Femix::GetProjecDir]
    set model [Femix::GetModelName]
    # Posfemix bat filename.
    set batFilename [file join $dir "pos.bat"]
    # Creates the posfemix bat file.
    set batFile [open $batFilename w+]
    set f $batFile 

    puts $f "@echo off"
    puts $f "set JOBNAME=[file join $dir $model]"
    puts $f "set PATH_POSFEMIX=[file join $Femix::femixVars(Path) bin]"

    # Writes connected mesh.
    puts $f "echo mes3d >> ans_pos.txt"
    puts $f "echo n >> ans_pos.txt"
    # Writes unconnected mesh.
    # Posfemix automatically generates the unconnected mesh when the command
    # sepva is used.
    puts $f "echo sepva >> ans_pos.txt"
    puts $f "echo y >> ans_pos.txt"
    puts $f "echo 1 >> ans_pos.txt"
    puts $f "echo y >> ans_pos.txt"
    puts $f "echo n >> ans_pos.txt"
    puts $f "echo 1 >> ans_pos.txt"
    # Closes posfemix
    puts $f "echo end >> ans_pos.txt"
    puts $f "type ans_pos.txt | \"%PATH_POSFEMIX%/posfemix.exe\" \"%JOBNAME%\""
    puts $f "del ans_pos.txt"

    # Closes the bat file.
    close $f
}


