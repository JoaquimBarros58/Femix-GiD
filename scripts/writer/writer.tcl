# #############################################################################
# Writer.tcl --
#
# GiD-FEMIX problem type.
#
# This file implements functions to write the Femix input file.
#
# #############################################################################

namespace eval Writer {
    variable file;        # Input filename.
    variable listMat;     # List of used materials.
    variable listGeom;    # List of used geomtries.
    variable listRule;    # List of used integration rules.
    variable arrElem ;    # Array of elements

    # Format
    # -------
    variable fg "%-20g";    # Format for float numbers
    variable fi "%-20d" ;   # Format for integer numbers
    variable fs "%-20s" ;   # Format for strings

    # Settings
    # ---------
    variable comment 1; # If true the comments will be printed.
}

# Prints data to the .dat calculation file.
#
# @param filename It is the name of the file.
proc Writer::WriteInputFile {filename} {
    # Init global variables.
    Writer::Init $filename
    
    # Open file for writting
    GiD_WriteCalculationFile init $::Writer::file

    # Check if the mesh was generate before write the input file.
    if {[GiD_Info Mesh] == 0} {
        WarnWin "Please generate the mesh."
        return
    }

    WriteLine <FEMIX_DATA_FILE_V4.0>

    # Write the main parameters block.
    Writer::MainParameters
    
    WriteLine <MESH> 1

    # Write the group names block.
    Writer::Groups

    # Write the point coordinates block.
    Writer::Nodes

    # Write supports.
    set nbc [Writer::Supports]
    if {$nbc == 0} {
        WarnWin "The model does not have supports."
    }

    if {[llength $::Writer::listGeom] > 0} {
        Writer::Geometry
    }

    if {$::Writer::listRule > 0} { Writer::Integration }
    Writer::Materials
    Writer::ElementNodes
    Writer::ElementProperties

    WriteLine "</MESH>\n" 1

    Writer::Loads

    WriteLine </FEMIX_DATA_FILE_V4.0>
    
    # Finish writting
    GiD_WriteCalculationFile end
}

# Writes the groups block.
proc Writer::Groups {} {
    variable fs; variable fi

    # Get groups
    set grpList [GiD_Groups list ""]

    Writer::WriteLine <GROUP_NAMES> 2

    # Print comments?
    if {$::Writer::comment} {
        Writer::WriteLine "## Declaration of the names of the groups" 3
        Writer::WriteLine "COUNT = [llength $grpList] ; # N. of groups" 3
        Writer::WriteLine
        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> Name" 3
        Writer::WriteLine [format "#$fs $fs" A B] 3
    } else {
        Writer::WriteLine "COUNT = [llength $grpList] ;" 3 
    }

    set count 1
    foreach item $grpList {
        # Replace spaces by undescore character.
        set name [join $item _]
        Writer::WriteLine [format " $fi $fs ;" $count $name] 3
        incr count
    }

    WriteLine "</GROUP_NAMES>\n" 2
}

# Writes the nodes coordinates block.
proc Writer::Nodes {} {
    variable fg ; variable fi ; variable fs

    set nn [GiD_Info Mesh MaxNumNodes]
    set ndim [Femix::GetNumDimension] 

    Writer::WriteLine <POINT_COORDINATES> 2
    
    # Print comments?
    if {$::Writer::comment} {
        Writer::WriteLine "## Point coordinates (global coordinate system)" 3
        Writer::WriteLine "COUNT = $nn ; # N. of points" 3
        Writer::WriteLine
        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> Coordinate - XG1" 3
        Writer::WriteLine "#  C -> Coordinate - XG2" 3
        Writer::WriteLine "#  D -> Coordinate - XG3" 3
        Writer::WriteLine [format "#$fs $fs $fs $fs" A B C D] 3
    } else {
        Writer::WriteLine "COUNT = $nn ;" 3
    }

    # Converts to the current unit.
    set unitOrigin [gid_groups_conds::give_mesh_unit]
    set unitDest [gid_groups_conds::give_active_unit L]
    set meshFac [gid_groups_conds::convert_unit_value L 1.0 $unitOrigin $unitDest]
    # Gets the coordinates of the mesh.
    set xyz [GiD_WriteCalculationFile coordinates -factor $meshFac -return "%d %g %g %g\n"]

    # Prints the coordiantes.
    for {set i 0}  {$i < [llength $xyz]} {incr i 4} {
        set id [lindex $xyz $i]
        set x [lindex $xyz [expr $i + 1]]
        set y [lindex $xyz [expr $i + 2]]
        set z [lindex $xyz [expr $i + 3]]

        if {$ndim == 2} {
            set fmt [format " $fi $fg $fg $fg ;" $id $z $x $y]
        } else {
            set fmt [format " $fi $fg $fg $fg ;" $id $x $y $z]
        }
        Writer::WriteLine $fmt 3
    }

    Writer::WriteLine </POINT_COORDINATES> 2
    Writer::WriteLine
}

# Initialises the namespace variables for future usage.
proc Writer::Init {filename} {
    variable file
    variable femixVars

    # Set the input filename.
    set file $filename

    # Init global variables
    set Writer::listMat []
    set Writer::listGeom []
    set Writer::listRule []
    if {[array size Writer::arrElem] > 0} {
        unset Writer::arrElem
    }
    global Writer::arrElem

    Writer::Parts 1
    Writer::Parts 2
    Writer::Parts 3
}

# Inits the list of elements. Basically, this procedure gets all groups from
# a given part (1,2 or 3), thus for each elment of the group it reads the values
# associated to it (i.e. material, integration rule, etc) and save these values
# to a dictionary. Finally, it stores the dictionary to the element list.
# 
# @param part The number of the part 1, 2 or 3.
proc Writer::Parts {part} {
    # xpath for parts_1d node.
    if {$part == 1} {
        set xp1 {./container[@n="parts"]/condition[@n="parts_1d"]/group}
    } elseif {$part == 2} {
        set xp1 {./container[@n="parts"]/condition[@n="parts_2d"]/group}
    } else {
        set xp1 {./container[@n="parts"]/condition[@n="parts_3d"]/group}
    }

    set root [$::gid_groups_conds::doc documentElement]

    # Loop over the group nodes of the part
    foreach gNode [$root selectNodes $xp1] {
        set grpName [get_domnode_attribute $gNode n]

        # Gets element values
        set valueElement [$gNode selectNodes {value[@n="element"]}]
        set elTypeName [get_domnode_attribute $valueElement v]
        set valueMat [$gNode selectNodes {value[@n="material"]}]
        set elMatName [get_domnode_attribute $valueMat v]
        set valueRule [$gNode selectNodes {value[@n="integration"]}]
        set elRule [get_domnode_attribute $valueRule v]
        set valueGeo [$gNode selectNodes {value[@n="geometry"]}]
        set elGeom [get_domnode_attribute $valueGeo v]
        
        # Adds the geometry to the used geometry list.
        if {[lsearch -exact $Writer::listGeom $elGeom] == -1 && $part <= 2} {
            lappend Writer::listGeom $elGeom
        }

        # Adds the integration rule to the rule list.
        if {[lsearch -exact $Writer::listRule $elRule] == -1} {
            lappend Writer::listRule $elRule
        }

        # Adds the material to the used materials list.
        if {[lsearch -exact $Writer::listMat $elMatName] == -1} {
            lappend Writer::listMat $elMatName
        }

        # Loop over the elements of the group.
        set elGroup [GiD_EntitiesGroups get $grpName elements]

        # Find maximum and minimum element id.
        set range [Femix::GetRange $elGroup]

        # Populating the element array
        foreach id $elGroup {
            # Get the element connectivities.
            # It converts from gid to femix before saving.
            set elConn [Femix::GetConn $id]

            # Store data into the elements dictionary.
            # Dictionary specs:
            # -----------------
            # part: Element part, it can be 1, 2 or 3.
            # id: Element id.
            # conn: connectivity list.
            # type: linear or quadratic.
            # mat_name: Material name.
            # geom: Element geometry.
            # group: Element group.
            # rule: Element rule.
            set Writer::arrElem($id) [dict create part $part id $id conn $elConn \
                    type $elTypeName mat_name $elMatName \
                    geom $elGeom group [join $grpName _] rule $elRule]
        }
    }
}

# Writes a string to the input file.
# 
# @param str String to be written. If no string is provided a blank line will
#        be printed.
# @param ind  Indentation level, it can be 0, 1, 2, 3 or 4. Default is 0, 
#        i.e. no indentation.
# @param file If 1 prints to file, if 0 returns a string instead.
# @param c Caracter used for indentation. Default is a space. 
proc Writer::WriteLine {{str ""} {ind 0} {file 1} {c " "}} {
    set s ""

    for {set i 0}  {$i < $ind} {incr i} {
        append s $c
    }

    append s $str

    if {$file == 1} {
        GiD_WriteCalculationFile puts $s
    } else {
        return $s
    }
}