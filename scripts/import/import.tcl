# #############################################################################
# Import.tcl --
#
# GiD-FEMIX problem type.
#
# This namespace implements procedures to convert femix result files in GiD 
# result file.
#
# #############################################################################

namespace eval Import {
    variable resFile;     # Handle to GiD file, filename.pos.res
    variable resFilename; # .pos.res filename
}

# Inits the namespace variables and add the GiD header to the file.
#
# Arguments:
# ----------
# rtype: Result type. It will be used as suffix of the post.res file. 
#        e.g. if the rtype is "di" thus the result file will be 
#        named mymodel_di.post.res 
#
proc Import::Init {rtype {file ""}} {
    set dir [Femix::GetProjecDir $file]
    set model [Femix::GetModelName $file]_$rtype
    set Import::resFilename [file join $dir "$model.post.res"]
    set Import::resFile [open $Import::resFilename w+]

    puts $Import::resFile "GiD Post Results File 1.0\n"
}

# Closes the result file and displays the results.
proc Import::Close {} {
    # Closes res file.
    close $Import::resFile
}

# Converts femix mesh file to GiD mesh file. 
#
# Arguments:
# ----------
# rtype: Result type, e.g. di, se, sa, etc.
# mesh: Type of mesh associated to the pva file, it can be connected (me) mesh
#       or unconnected (um) mesh.
# file: Mesh file to be imported. If the file is not provided, it will scan
#       the project directory and search for files with "mtype" extensions, i.e.
#       me.s3d or um.s3d.
#
# Return:
# --------
# 0 if the mesh is successfully imported, or 0 otherwise.
#
proc Import::Mesh {rtype mtype {file ""}} {
    set dir [Femix::GetProjecDir $file]
    set model [Femix::GetModelName $file]_
    set mshFile [file join $dir "$model$mtype.s3d"]

    # Checks if the femix mesh file exist.
    if {[file exists $mshFile] == 0} {
        WarnWin "You need to generate the mesh file first.\nRun Posfemix to create the mesh file."
        return 1; # Error creating mesh.
    }

    # Opens the input mesh file.
    set inFile [open $mshFile r]
    # Opens the output mesh file.
    set outFile [open [file join $dir "$model$rtype.post.msh"] w+]

    set xyz [];   # coordinates
    set nn 0;     # number of nodes
    set ne 0;     # number of elements
    set count 1;  # counter
    set nTypes 0; # number of elements types.

    # Reads each line of the femix mesh file and stores the data 
    # for future printing.
    while { [gets $inFile line] >= 0 } {
        set row [String::GetList $line]

        # Skip the line if it is a text.
        if {![string is integer [lindex $row 0]]} { 
            continue 
        }
        # Read the number of elements and nodes.
        if {[llength $row] == 3} {
            set ne [lindex $row 0]
            set nn [lindex $row 1]
            continue
        }
        # Now it reads the elements and nodes lines.
        set id [lindex $row 0]
        if {$count <= $ne} {
            set nc [lindex $row 1]
            set conn [lrange $row 2 end]
            set elType ""

            if {$nc == 2 || $nc == 3} { 
                set elType "Line"
            } elseif {$nc == 5} { 
                set elType "Quadrilateral"
                set conn [lreplace $conn end end]
                set nc [expr $nc-1]
            } elseif {$nc == 9} { 
                set elType "Quadrilateral"
                set conn [lreplace $conn end end]
                set conn [Femix::ElemConnOrdering $conn]
                set nc [expr $nc-1]
            } elseif {$nc == 8} {
                set elType "Hexahedra" 
            } elseif {$nc == 20} {
                set elType "Hexahedra" 
                set conn [Femix::ElemConnOrdering $conn]
            }

            lappend elem($nc) [list $elType $nc $id $conn]
        } elseif {$count > $ne && $count <= [expr $ne + $nn]} {
            set coord [lrange $row 1 end]
            lappend xyz [format "%s %s" $id $coord]
        } else {
            continue
        }

        incr count
    }
    close $inFile

    # Gets the names of the arrays.
    set names [array names elem]
  
    # Flag used to indicate the first time the program enters in the loop.
    # This will allow us to identify if we need to print the coordinates.
    set first 1

    # Prints the data to GiD mesh file.
    foreach name [array names elem] {
        # Gets all elmements of the current array.
        set all $elem($name)

        set fe [lindex $all 0] ; # First element of the current array.
        set type [lindex $fe 0]
        set nn [lindex $fe 1]
        set ndim [Femix::GetNumDimension]

        if {$first} {
            puts $outFile "MESH \"Default\" dimension 3 ElemType $type Nnode $nn"
            puts $outFile "Coordinates"
            foreach item $xyz {
                puts $outFile $item
            }
            puts $outFile "end coordinates\n"
        } else {
            puts $outFile "MESH \"Default\" dimension 3 ElemType $type Nnode $nn"
            puts $outFile "Coordinates"
            puts $outFile "#no coordinates then they are already in the first MESH"
            puts $outFile "end coordinates\n"
        }

        puts $outFile "Elements"
        foreach e $all {
            set id [lindex $e 2]
            set conn [lindex $e 3]
            puts $outFile "$id $conn 1"
        }
        puts $outFile "end elements\n"

        set first 0
    }

    close $outFile

    # Mesh created successfully.
    return 0
}

# Import PVA files.
#
# Arguments:
# ----------
# rtype: Result type, e.g. di, se, sa, etc.
# mesh: Type of mesh associated to the pva file, it can be connected (me) mesh
#       or unconnected (um) mesh.
# file: Pva file to be imported. If the file is not provided, it will scan the
#       project directory and search for pva files with "rtype" extensions, i.e.
#       se.pva, sa.pva, di.pva, etc.
#
# Return:
# --------
# 0 if the pva and mesh files are successfully imported, or 0 otherwise.
#
proc Import::PvaResults {rtype mesh {file ""}} {
    # Creates the mesh associated to the res.
    if {[Import::Mesh $rtype $mesh $file] == 1} {
        return 1; # Error creating mesh file.
    }

    # Get all pva files with extension rtype.
    if {$file == ""} {
        set dir [Femix::GetProjecDir]
        set modelName [Femix::GetModelName]
        set allFiles [glob -nocomplain -directory $dir $modelName*_$rtype.pva]
    } else {
        set allFiles $file
    }

    # Checks if the dipva files exist. If not the post.res file will not be
    # created and a message to the user will be displayed.
    if {$allFiles == ""} {
        WarnWin "Result \"_$rtype.pva\" file not found.\nPlease run Posfemix to export the results to file."
        return 1; # Error reading files.
    }

    # Groups the files by laod type (LCase or Comb)
    foreach f $allFiles {
        # Split the name of the file by _
        set words [split $f _]
        
        if {$rtype == "di"} {
            set ltype [lindex $words end-2]; # LCase or Comb
            set cname [lindex $words end-1]; # Compoenet name, e.g. D1, D2, etc
            lappend groups($ltype) [dict create elem "None" comp $cname fname $f]
        } else {
            set ename [lindex $words end-3]; # Element name, e.g. SolidHexa, etc
            set ltype [lindex $words end-2]; # LCase or Comb
            set cname [lindex $words end-1]; # Compoenet name, e.g. Sigma1, Tau12, etc
            lappend groups($ltype) [dict create elem $ename comp $cname fname $f]
        }
    }

    # Writing the res file.
    # ---------------------
    Import::Init $rtype $file
    set fres $Import::resFile

    # Loop over the groups of files.
    foreach name [array names groups] {
        set files $groups($name)

        set compNames ""; # Result component labels.

        # Opens each file of the group, then it reads each line of the file
        # and appends the value to "lines". Note that the values of each 
        # file corresponds to a column in "lines".
        foreach item $files {
            set row 0; # line number id.
            set eltype [dict get $item elem];
            set fn [dict get $item fname];
            # Stores the label corresponding to this result file.
            append compNames "\"[dict get $item comp]\", "
            
            set fp [open $fn r]
            while { [gets $fp line] >= 0 } {
                scan $line "%d %f" id val
                lappend lines($row) $val
                incr row
            }

            incr nfiles
        }

        if {$rtype == "di"} {set anaName "Displacements"}
        if {$rtype == "se"} {set anaName "Stresses"}
        if {$rtype == "sa"} {set anaName "Strains"}

        # Splits LCase1 or Comb1 into the result name and step. 
        scan $name {%[a-zA-Z]%d} resName step

        # Defines the result type.
        if {$file != ""} {
            set resultType "Scalar"
        } else {
            if {$rtype == "di" || $eltype == "PlaneStressQuad"} {
                set resultType "Vector" 
            } else {
                set resultType "Matrix"
            }
        }

        # Print to file
        # --------------
        puts $fres "Result \"$anaName\" \"$resName\" $step $resultType OnNodes"
        puts $fres "ComponentNames $compNames"
        puts $fres "Values"
        # Now we can print to file...
        for {set i 0} {$i < [array size lines]} {incr i} {
            puts $fres "[expr $i+1] $lines($i)" 
        }
        puts $fres "End Values"

        # Cleaning lines for next load case or comb...
        unset -nocomplain lines
    }

    # Import::Close
    close $fres

    return 0
}
