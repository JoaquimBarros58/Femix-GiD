# Prints the Face Load block.
# 
# @param load_case The name of the load case title. 
proc Writer::FaceLoad {load_case} {
    # If no face load is found, thus do not print this block.
    set nloads [SpdAux::Count "/*/container\[@n = 'loads' \]/condition\[@n = 'face' \]/group"]
    if {$nloads <= 0} { return }

    variable fg; variable fi; variable fs;

    set ndim [Femix::GetNumDimension]

    set root [$::gid_groups_conds::doc documentElement]
    set loads {}

    # XPath to face loads node.
    set xp {/*/container[@n="loads"]//condition[@n="face"]/group}
    # Scan the face load node to find any ocurrance of the load_case.
    foreach gnode [$root selectNodes $xp] {
        set group_name [get_domnode_attribute $gnode n] ;
        # Gets the name of the load case associate to this group.
        set case [SpdAux::GetNodeValue $gnode "./value\[@n = 'case'\]"]

        if {$load_case == $case} {
            # Gets the mesh nodes associated to this group.
            set mesh [GiD_WriteCalculationFile elements -return -elements_faces faces [dict create $group_name "%d %d,"]]
            set faces [String::GetList $mesh ,] ; # list of element and faces.

            # Get node values.
            set vector [SpdAux::GetNodeValue $gnode "./value\[@n = 'vector'\]"]
            set type [SpdAux::GetNodeValue $gnode "./value\[@n = 'type'\]"]
            set value [format $fg [SpdAux::GetNodeValue $gnode "./value\[@n = 'value'\]"]]

            if {$type == "Force"} {
                set type _FORC
            } else {
                set type _MOM
            }

            if {$vector == "Global"} {
                set dir _[SpdAux::GetNodeValue $gnode "./value\[@n = 'dir_global'\]"]
            } elseif {$vector == "Solid/Shell"} {
                set dir _[SpdAux::GetNodeValue $gnode "./value\[@n = 'dir_solid'\]"]
            } elseif {$vector == "Plane stress/Plane strain/Axisymmetry"} {
                set dir _[SpdAux::GetNodeValue $gnode "./value\[@n = 'dir_plane'\]"]
            }

            Start $group_name

            set count 1
            foreach e $faces {
                # Splits the list to get the element and face ids.
                set elId [split [lindex $e 0]]; # element id
                set faceId [split [lindex $e 1]]; # face id
                Writer::WriteLine [format " $fi $fi $fi $fs $fs $fi $fg ;" $count $elId [expr $faceId+1] $dir $type 1 $value] 4
                incr count
            }

            End
        }
    }
}

proc Start {group_name} {
    set fg $Writer::fg; 
    set fi $Writer::fi;
    set fs $Writer::fs;

    set count [GiD_WriteCalculationFile elements -count -elements_faces faces [dict create $group_name ""]]
    
    if {$::Writer::comment} {
        Writer::WriteLine "<FACE_LOADS>" 3
        Writer::WriteLine "COUNT = $count ; # N. of face loads\n" 4
        Writer::WriteLine "## Content of each column:" 4
        Writer::WriteLine "#  A -> Counter (or counter range)" 4
        Writer::WriteLine "#  B -> Loaded element (or loaded element range)" 4
        Writer::WriteLine "#  C -> Loaded face" 4
        Writer::WriteLine "#  D -> Direction vector:" 4
        Writer::WriteLine "#       - Global: _XG1, _XG2 or _XG3" 4
        Writer::WriteLine "#       - Solid/Shell: _L1, _L2 or _N" 4
        Writer::WriteLine "#       - Plane stress/Plane strain/Axisymmetry: _L1 or _L2" 4
        Writer::WriteLine "#       - Specified: vector from the <AUXILIARY_VECTORS> block" 4
        Writer::WriteLine "#  E -> Type of generalized force (_FORC - Force; _MOM - Moment)" 4
        Writer::WriteLine "#  F -> N. of nodes of the face of the element" 4
        Writer::WriteLine "#  G -> Load values" 4
        Writer::WriteLine "#" 4
        Writer::WriteLine "#  Note: when F is equal to 1 the load is constant" 4
        Writer::WriteLine "#" 4
        Writer::WriteLine "#  Direction vector keywords:" 4
        Writer::WriteLine "#     _L1 - tangential to the face and following the l1 local axis" 4
        Writer::WriteLine "#     _L2 - tangential to the face and following the l2 local axis" 4
        Writer::WriteLine "#     _N  - normal to the face" 4
        Writer::WriteLine "#" 4
        Writer::WriteLine [format "#$fs $fs $fs $fs $fs $fs $fs" A B C D E F G] 4
    } else {
        Writer::WriteLine "COUNT = $count ;"
    }
}

proc End {} {
    Writer::WriteLine "</FACE_LOADS>\n" 3
}