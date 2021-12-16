# Writes the element nodes connectivity to the input file.
#
# This procedure firstly sorts the array of elements by id, then it prints the
# elements’ connectivities one by one. This is not the faster method for 
# printing, but the GiD procedure for printing all connectivities (faster) does
# not provide a way to control some aspects related to specific elements, 
# e.g. ordering of the nodes for truss elements, interface numbering, etc.
proc Writer::ElementNodes {} {
    variable fi; variable fs;
    variable arrElem

    Writer::WriteLine <ELEMENT_NODES> 2

    if {$Writer::comment} {
        Writer::WriteLine "## Nodes defining the elements" 3
        Writer::WriteLine "COUNT = [GiD_Info Mesh NumElements] ; # N. of elements" 3
        Writer::WriteLine
        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> N. of nodes of the element" 3
        Writer::WriteLine "#  C -> Nodes of the element" 3
        Writer::WriteLine [format "#%8s  %s  %-s" A B C] 3
    } else {
        Writer::WriteLine "COUNT = [GiD_Info Mesh NumElements] ;" 3
    }

    set count 1

    # Sorting the array of elements by element id.
    set sorted [lsort -integer -increasing [array names arrElem]]

    foreach i $sorted  {
        set e $Writer::arrElem($i)
        set etype _[dict get $e type]
        set id [dict get $e id]
        set size [llength [dict get $e conn]]
        set conn [dict get $e conn]

        # If the element is interface 2D we need to change the nodes numbering
        # order.
        if {$etype == "_INTERFACE_LINE_2D"} {
            if {[Femix::IsQuadratic] == 0} { # linear interface
                set conn [lreplace $conn end-1 end [lindex $conn end] [lindex $conn end-1]]
            } else { # quadratic element
            }
        }

        set fmt [format " %8s  %d  %-s ;" $count $size $conn]
        Writer::WriteLine $fmt 3

        incr count
    }

    Writer::WriteLine "</ELEMENT_NODES>\n" 2
}

# Using this procedure the connectivities will not be printed in ascending 
# order (from id=1 to id=N), e.g. if a linear element has an id = 30 it will be
# the first one to be printed, this will happen because the linear elements are
# being called first in this code. 
proc Writer::ElementNodesWrite {} {
    variable fi; variable fs;

    Writer::WriteLine <ELEMENT_NODES> 2

    if {$Writer::comment} {
        Writer::WriteLine "## Nodes defining the elements" 3
        Writer::WriteLine "COUNT = [GiD_Info Mesh NumElements] ; # N. of elements" 3
        Writer::WriteLine
        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> N. of nodes of the element" 3
        Writer::WriteLine "#  C -> Nodes of the element" 3
        Writer::WriteLine [format "#%8s  %s  %-s" A B C] 3
    } else {
        Writer::WriteLine "COUNT = [GiD_Info Mesh NumElements] ;" 3
    }

    if {[Femix::IsQuadratic] == 0} {
        GiD_WriteCalculationFile connectivities -elemtype Linear "%d %d %d\n"
        GiD_WriteCalculationFile connectivities -elemtype Triangle "%d %d %d %d\n"
        GiD_WriteCalculationFile connectivities -elemtype Quadrilateral "%d %d %d %d %d\n"
    } else {
        GiD_WriteCalculationFile onnectivities -elemtype Linear "%d %d %d %d\n"
        GiD_WriteCalculationFile connectivities -elemtype Triangle -connec_ordering corner_face_corner_face "%d %d %d %d %d %d %d\n"
        GiD_WriteCalculationFile connectivities -elemtype Quadrilateral -connec_ordering corner_face_corner_face "%d %d %d %d %d %d %d %d %d\n"
    }

    Writer::WriteLine "</ELEMENT_NODES>\n" 2
}

# Writes the element properties to the input file.
# This procedure prints the element properties using femix range feature, i.e. 
# if the elements have the same properties they will be written in one single
# line, e.g. [1-10].
proc Writer::ElementProperties {} {
    variable fs ; variable fi
    variable arrElem

    Writer::WriteLine <ELEMENT_PROPERTIES> 2

    set lines "";
    set count 1;
    set start 1; # Initial element in range
    set end 1; # final elemen
    
    while {$end <= [array size arrElem]} {
        set isSeq 1 ; # If the properties are the same this flag is equal to 1.

        # Defines the element range.
        while {$isSeq && $end <= [array size arrElem]} {
            set list1 [Writer::GetArrayItem $end]
            set list2 [Writer::GetArrayItem [expr $end + 1]]
            # Removing itens that we do not to compare from lists.
            set list1 [lreplace $list1 0 1]
            set list2 [lreplace $list2 0 1]

            if {[General::ListCompare $list1 $list2] == 1} {
                set isSeq 0
            }

            incr end
        }

        set vs [Writer::GetArrayItem $start] ; # Initial element from range.
        set eids [lindex $vs 1]

        set ve [Writer::GetArrayItem [expr $end - 1]] ; # Final element from range.
        set eide [lindex $ve 1]

        if {$start == [expr $end - 1]} {
            set range $eids
        } else {
            set range "\[$eids-$eide\]"
        }

        # Printing element properties...
        set fmt [format " $fi $fs $fi $fs $fs $fs $fs $fs $fs $fs $fs ;\n" \
        $count [lindex $vs 0] 1 $range [lindex $vs 2] [lindex $vs 3] [lindex $vs 4] \
        [lindex $vs 5] [lindex $vs 6] [lindex $vs 7] [lindex $vs 8]]

        append lines [Writer::WriteLine $fmt 3 0]
        
        incr count
        set start $end
    }
 
    if {$Writer::comment} {
        Writer::WriteLine "## Specification of the element properties" 3
        Writer::WriteLine "COUNT = [expr $count - 1] ; # N. of specifications" 3
        Writer::WriteLine
        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> Group name" 3
        Writer::WriteLine "#  C -> Phase (or phase range)" 3
        Writer::WriteLine "#  D -> Element (or element range)" 3
        Writer::WriteLine "#  E -> Element type" 3
        Writer::WriteLine "#  F -> Material type" 3
        Writer::WriteLine "#  G -> Material name" 3
        Writer::WriteLine "#  H -> Geometry type" 3
        Writer::WriteLine "#  I -> Geometry name" 3
        Writer::WriteLine "#  J -> Integration type (stiffness matrix)" 3
        Writer::WriteLine "#  K -> Integration name (stiffness matrix" 3
        Writer::WriteLine [format "#$fs $fs $fs $fs $fs $fs $fs $fs $fs $fs $fs" A B C D E F G H I J K] 3
    } else {
        Writer::WriteLine "COUNT = [expr $count - 1] ;" 3
    }

    append lines [Writer::WriteLine "</ELEMENT_PROPERTIES>" 2 0]

    Writer::WriteLine $lines
}

# Gets an element from the element array.
# 
# @param i Index of the array.
# 
# @return
# A list containing the following data:
# index 0: group name
# index 1: element id
# index 2: element type
# index 3: material type
# index 4: material name
# index 5: geometry type
# index 6: geometry name
# index 7: rule type
# index 8: rule name
# index 9: part name
# 
proc Writer::GetArrayItem {i} {
    if {$i > [array size Writer::arrElem]} {
        return [list]
    }

    set e $::Writer::arrElem($i)

    set id [dict get $e id]
    set etype _[dict get $e type]
    set eid [dict get $e id]
    set etype _[dict get $e type]
    set part [dict get $e part]
    set mat_name [dict get $e mat_name]
    set mat_type [SpdAux::GetDbType materials material $mat_name]
    set group [dict get $e group]
    set rule [dict get $e rule]
    set rule_type _[SpdAux::GetDbType integrations rule $rule]

    if {$part == 1} {
        if {$etype == "_TRUSS_2D" || $etype == "_TRUSS_3D" ||
            $etype == "_FRAME_2D" || $etype == "_FRAME_3D"} {
            set rule _NONE
            set rule_type _NONE
        }
    }

    if {$part == 3} {
        set geom _NONE
        set geom_type _NONE
    } else {
        set geom [dict get $e geom]
        set geom_type [SpdAux::GetDbType geometries geometry $geom]
    }

    return [list $group $eid $etype $mat_type $mat_name $geom_type $geom $rule_type [join $rule _] $part]
}

# Writes the element properties to the input file. 
# This procedure prints one line per element property.
proc Writer::ElementPropSingle {} {
    variable fs ; variable fi
    variable arrElem

    Writer::WriteLine <ELEMENT_PROPERTIES> 2

    if {$Writer::comment} {
        Writer::WriteLine "## Specification of the element properties" 3
        Writer::WriteLine "COUNT = [array size arrElem] ; # N. of specifications" 3
        Writer::WriteLine
        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> Group name" 3
        Writer::WriteLine "#  C -> Phase (or phase range)" 3
        Writer::WriteLine "#  D -> Element (or element range)" 3
        Writer::WriteLine "#  E -> Element type" 3
        Writer::WriteLine "#  F -> Material type" 3
        Writer::WriteLine "#  G -> Material name" 3
        Writer::WriteLine "#  H -> Geometry type" 3
        Writer::WriteLine "#  I -> Geometry name" 3
        Writer::WriteLine "#  J -> Integration type (stiffness matrix)" 3
        Writer::WriteLine "#  K -> Integration name (stiffness matrix" 3
        Writer::WriteLine [format "#$fs $fs $fs $fs $fs $fs $fs $fs $fs $fs $fs" A B C D E F G H I J K] 3
    } else {
        Writer::WriteLine "COUNT = [array size arrElem] ;" 3
    }

    set count 1

    # Print to file.
    foreach i [lsort -integer -increasing [array names Writer::arrElem]]  {
        set e $Writer::arrElem($i)

        set id [dict get $e id]
        set etype _[dict get $e type]
        set eid [dict get $e id]
        set etype _[dict get $e type]
        set part [dict get $e part]
        set mat_name [dict get $e mat_name]
        set mat_type [SpdAux::GetDbType materials material $mat_name]
        set group [dict get $e group]
        set rule [dict get $e rule]
        set rule_type _[SpdAux::GetDbType integrations rule $rule]
        if {$part == 3} {
            set geom _NONE
            set geom_type _NONE
        } else {
            set geom [dict get $e geom]
            set geom_type [SpdAux::GetDbType geometries geometry $geom]
        }

        # Print 1d parts.
        if {$part == 1} {
            if {$etype == "_TRUSS_2D" || $etype == "_TRUSS_3D" ||
                $etype == "_FRAME_2D" || $etype == "_FRAME_3D"} {
                set rule _NONE
                set rule_type _NONE
            }
        }

        # Print 2d parts.
        if {$part == 2} {}

        # Print 3d parts.
        if {$part == 3} {}

        set fmt [format " $fi $fs $fi $fi $fs $fs $fs $fs $fs $fs $fs ;" \
        $count $group 1 $eid $etype $mat_type $mat_name $geom_type $geom $rule_type [join $rule _]]
        Writer::WriteLine $fmt 3

        incr count
    }
 
    Writer::WriteLine "</ELEMENT_PROPERTIES>\n" 2
}

