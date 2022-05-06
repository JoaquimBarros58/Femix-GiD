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
    variable arrElem;     # Array of elements
    variable arrElemInt;  # Array of interface elements

    # Format
    # -------
    variable fg "%20g";    # Format for float numbers
    variable fi "%20d" ;   # Format for integer numbers
    variable fs "%20s" ;   # Format for strings

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

    Writer::ArcLength

    Writer::Loads

    Writer::Combinations

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

# Prints the arc length block
proc Writer::ArcLength {} {
    set path "container\[@n = 'main_parameters' \]/container\[@n = 'arcl' \]/value\[@n = 'activate' \]"
    set arc [SpdAux::GetValue $path]
    if {$arc == "No"} { return }

    Writer::WriteLine <ARC_LENGTH_PARAMETERS> 1

    Writer::WriteLine "DISPLACEMENT_CONTROL = _Y ;" 2
    set path "container\[@n = 'main_parameters' \]/container\[@n = 'arcl' \]/value\[@n = 'node' \]"
    Writer::WriteLine "POINT_NUMBER = [SpdAux::GetValue $path] ;" 2
    set path "container\[@n = 'main_parameters' \]/container\[@n = 'arcl' \]/value\[@n = 'dof' \]"
    set dof _[Femix::GetDirectionLabel [SpdAux::GetValue $path]]
    Writer::WriteLine "DEGREE_OF_FREEDOM = $dof ;" 2
    set path "container\[@n = 'main_parameters' \]/container\[@n = 'arcl' \]/value\[@n = 'incr' \]"
    Writer::WriteLine "DISPLACEMENT_INCREMENT = [SpdAux::GetValue $path] ;" 2
    
    Writer::WriteLine </ARC_LENGTH_PARAMETERS> 1
    Writer::WriteLine
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

    set Writer::comment $::Femix::femixVars(WriterComment)
    set Writer::fs "$::Femix::femixVars(WriterStrFmt)"
    set Writer::fi "$::Femix::femixVars(WriterIntFmt)"
    set Writer::fg "$::Femix::femixVars(WriterDblFmt)"

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
    if {[array size Writer::arrElemInt] > 0} {
        unset Writer::arrElemInt
    }
    global Writer::arrElemInt

    Writer::Parts 1
    Writer::Parts 2
    Writer::Parts 3

    Writer::InterfaceElements
}

# Inits the list of elements. Basically, this procedure gets all groups from
# a given part (1,2 or 3), thus for each elment of the group it reads the values
# associated to it (i.e. material, integration rule, etc) and save these values
# to a dictionary. Finally, it stores the dictionary to the element list.
# 
# @param part The number of the part 1, 2 or 3.
proc Writer::Parts {part} {
    # xpath for part nodes.
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
            # It converts from gid numbering order to femix numbering order before saving.
            set elConn [Femix::GetConn $id]

            # Save interface elements to a different array to avoid overwriting existing elements. 
            # This will happen when interface elements are assigned to existing elements.
            # This array needs to be merged to the arrElem array later on.
            if {$elTypeName == {INTERFACE_LINE_2D} && $part == 1} {
                set Writer::arrElemInt($id) [dict create part $part id $id conn $elConn \
                type $elTypeName mat_name $elMatName \
                geom $elGeom group [join $grpName _] rule $elRule] 
            } else {
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
}

# Merge the array of interface elements into the element array. 
# Note that the new elements added to the element array will have 
# a new id to avoid overwriting existing elements.
proc Writer::InterfaceElements {} {
    set ne [array size Writer::arrElem]
    foreach index [array names Writer::arrElemInt] {
        dict set Writer::arrElemInt($index) id [incr ne]
        set conn [Writer::CreateInterElement $Writer::arrElemInt($index)]
        dict set Writer::arrElemInt($index) conn $conn
        set Writer::arrElem($ne) $Writer::arrElemInt($index)
    }
}

# Create the interface elements. 
# This function will take the nodes of the given element (elem) and 
# will search into the model's list of nodes the ones which have the same 
# coordinates as the nodes of the given element. The new nodes will be 
# added to the given element to build the interface element.
# 
# @param elem Element dictionary.
# @return The connectivities of the interface element.
proc Writer::CreateInterElement {elem} {
    variable arrElem
    set econn [dict get $elem conn]; # element connections
    set nn [GiD_Info Mesh MaxNumNodes]; # number of nodes
    set newIds []
    
    # Checks if the node of the current element is equal to a node of nn list.
    for {set i 0} {$i < [llength $econn]} {incr i} {
        set found 0
        set count 1
        set eid [lindex $econn $i]
        set exyz [GiD_Mesh get node $eid]
        
        while {$count <= $nn && $found == 0} {
            set xyz [GiD_Mesh get node $count]

            if {[lindex $xyz 1] == [lindex $exyz 1] && [lindex $xyz 2] == [lindex $exyz 2] && [lindex $xyz 3] == [lindex $exyz 3] && $count != $eid} {
                set found 1
                lappend newIds $count
            }

            incr count
        }
    }

    if {[llength $newIds] > 0} {
        return [concat $econn $newIds] 
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
