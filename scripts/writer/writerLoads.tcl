proc Writer::Loads {} {
    Writer::LoadCases
}

# Prints all load cases defined in the Load Cases node of the tree.
proc Writer::LoadCases {} {
    set count 1

    # Gets the root node of the tree.
    set root [$::gid_groups_conds::doc documentElement]

    Writer::WriteLine <LOAD> 1

    # Xpath to the load cases node.
    set xp "/*/container\[@n = 'lcases' \]/blockdata"
    foreach node [$root selectNodes $xp] { # loop over the load cases node.
        set load_title [get_domnode_attribute $node name]

        Writer::WriteLine "<LOAD_CASE>\n" 2

        # Gets the group name
        set group [SpdAux::GetNodeValue $node "./value\[@n = 'group' \]"]
        set itype [SpdAux::GetNodeValue $node "./value\[@n = 'itype' \]"]
        set iname _[SpdAux::GetNodeValue $node "./value\[@n = 'iname' \]"]

        Writer::WriteLine "<LOAD_CASE_PARAMETERS>" 3
        Writer::WriteLine "LOAD_CASE_NUMBER = $count ;" 4
        Writer::WriteLine "LOAD_CASE_TITLE = $load_title ;" 4
        Writer::WriteLine "LOAD_CASE_GROUP = [join $group _] ;" 4
        Writer::WriteLine
        if {$::Writer::comment} {
            Writer::WriteLine "INTEGRATION_TYPE = $itype ; # Keywords: _GLEG, _GLOB, or _NCOTES" 4
            Writer::WriteLine "INTEGRATION_NAME = $iname ; # Defined in the <NUMERICAL_INTEGRATION> block or _DEFAULT" 4
        } else {
            Writer::WriteLine "INTEGRATION_TYPE = $itype ;" 4
            Writer::WriteLine "INTEGRATION_NAME = $iname ;" 4
        }
        Writer::WriteLine "</LOAD_CASE_PARAMETERS>\n" 3

        # Prints the gravity load block.
        Writer::GravityLoad $node

        # Prints only loads that belongs to the load case.
        Writer::PointLoad $load_title
        Writer::FaceLoad $load_title
        Writer::TempVarLoad $load_title
        
        Writer::WriteLine "</LOAD_CASE>\n" 2

        incr count
    }

    Writer::WriteLine "</LOAD>\n" 1
}

# Prints the Point Load block.
# 
# @param load_case The name of the load case title.
proc Writer::PointLoad {load_case} {
    # If no point load is found, thus do not print this block.
    set nloads [SpdAux::Count "/*/container\[@n = 'loads' \]/condition\[@n = 'point' \]/group"]
    if {$nloads <= 0} { return }

    variable fg; variable fi; variable fs;

    set ndim [Femix::GetNumDimension]   
    set root [$::gid_groups_conds::doc documentElement]
    set loads {}

    # XPath to point load nodes.
    set xp {/*/container[@n="loads"]//condition[@n="point"]/group}
    # Scan the point load node to find any ocurr ance of the load_case
    foreach gnode [$root selectNodes $xp] {
        set group_name [get_domnode_attribute $gnode n] ;
        # Gets the name of the load case associate to this group.
        set case [SpdAux::GetNodeValue $gnode "./value\[@n = 'case'\]"]
        # Gets the mesh nodes associated to this group.
        set mesh [GiD_WriteCalculationFile nodes -return [dict create $group_name "%d,"]]
        set mesh [String::GetList $mesh ,] ; # list of mesh nodes.

        if {$load_case == $case} {
            set xf [format $fg [SpdAux::GetNodeValue $gnode "./value\[@n = 'x-force'\]"]]
            set yf [format $fg [SpdAux::GetNodeValue $gnode "./value\[@n = 'y-force'\]"]]
            set zf [format $fg [SpdAux::GetNodeValue $gnode "./value\[@n = 'z-force'\]"]]
            set xm [format $fg [SpdAux::GetNodeValue $gnode "./value\[@n = 'x-mom'\]"]]
            set ym [format $fg [SpdAux::GetNodeValue $gnode "./value\[@n = 'y-mom'\]"]]
            set zm [format $fg [SpdAux::GetNodeValue $gnode "./value\[@n = 'z-mom'\]"]]

            foreach id $mesh {
                lappend loads [dict create id $id xf $xf yf $yf zf $zf xm $xm ym $ym zm $zm]
            }
        }
    }
    
    # If no load cases were found with the lc title provided to the procedure, 
    # thus nothing is printed.
    if {[llength $loads] == 0} { return }

    if {$::Writer::comment} {
        Writer::WriteLine "<POINT_LOADS>" 3
        Writer::WriteLine "## Point loads (global coordinate system)" 4
        Writer::WriteLine "COUNT = [llength $loads] ; # N. of point loads\n" 4
        Writer::WriteLine "## Content of each column:" 4
        Writer::WriteLine "#  A -> Counter (or counter range)" 4
        Writer::WriteLine "#  B -> Loaded point (or loaded point range)" 4
        Writer::WriteLine "#  C -> Force - XG1" 4
        Writer::WriteLine "#  D -> Force - XG2" 4
        Writer::WriteLine "#  E -> Force - XG3" 4
        Writer::WriteLine "#  F -> Moment - XG1" 4
        Writer::WriteLine "#  G -> Moment - XG2" 4
        Writer::WriteLine "#  H -> Moment - XG3" 4
        Writer::WriteLine [format "#$fs $fs $fs $fs $fs $fs $fs $fs" A B C D E F G H] 4
    } else {
        Writer::WriteLine "COUNT = [llength $loads] ;" 4
    }

    set count 1
    foreach e $loads {
        set id [dict get $e id]
        set xf [dict get $e xf]
        set yf [dict get $e yf]
        set zf [dict get $e zf] 
        set xm [dict get $e xm]
        set ym [dict get $e ym]
        set zm [dict get $e zm]

        # For 2d, femix considers the model in the yz plane, thus we need to
        # swap the coordinates. 
        if {$ndim == 2} {
            Writer::WriteLine [format " $fi $fi $fg $fg $fg $fg $fg $fg ;" $count $id $zf $xf $yf $zm $xm $ym] 4
        } else {
            Writer::WriteLine [format " $fi $fi $fg $fg $fg $fg $fg $fg ;" $count $id $xf $yf $zf $xm $ym $zm] 4
        }

        incr count
    }

    Writer::WriteLine "</POINT_LOADS>\n" 3
}

# Prints the Prescribed Temperature Load block.
# 
# @param load_case The name of the load case title. 
proc Writer::TempVarLoad {load_case} {
    # If there is no load of this type found in the tree, thus do not print this block.
    set nloads [SpdAux::Count "/*/container\[@n = 'loads' \]/condition\[@n = 'temp_var' \]/group"]
    if {$nloads <= 0} { return }

    set root [$::gid_groups_conds::doc documentElement]
    set loads {}

    # XPath to temperature variation nodes.
    set xp {/*/container[@n="loads"]//condition[@n="temp_var"]/group}
    # Scan the point load node to find any ocurr ance of the load_case
    foreach gnode [$root selectNodes $xp] {
        set group_name [get_domnode_attribute $gnode n] ;
        # Gets the name of the load case associate to this group.
        set case [SpdAux::GetNodeValue $gnode "./value\[@n = 'case'\]"]
        set mesh [GiD_WriteCalculationFile elements -return [dict create $group_name "%d,"]]
        set mesh [String::GetList $mesh ,] ; # list of mesh nodes.

        if {$load_case == $case} {
            set temp [format $fg [SpdAux::GetNodeValue $gnode "./value\[@n = 'temp'\]"]]
            foreach id $mesh {
                lappend loads [dict create id $id temp $temp]
            }
        }
    }

    # If no load cases were found with the lc title provided to the procedure, 
    # thus nothing is printed.
    if {[llength $loads] == 0} { return }

    variable fg; variable fi; variable fs

    if {$::Writer::comment} {
        Writer::WriteLine "<TEMPERATURE_VARIATION>" 3
        Writer::WriteLine "## Elements with temperature variation)" 4
        Writer::WriteLine "COUNT = [llength $loads] ; # N. of elements with temperature variation\n" 4
        Writer::WriteLine "## Content of each column:" 4
        Writer::WriteLine "#  A -> Counter (or counter range)" 4
        Writer::WriteLine "#  B -> Loaded element (or loaded element range)" 4
        Writer::WriteLine "#  C -> N. of nodes of the element" 4
        Writer::WriteLine "#  D -> Temperature variation values" 4
        Writer::WriteLine "#" 4
        Writer::WriteLine "#  Note: when C is equal to 1 the temperature variation is the same for all the element nodes" 4
        Writer::WriteLine "#" 4
        Writer::WriteLine [format "#$fs $fs $fs $fs" A B C D] 4
    } else {
        Writer::WriteLine "COUNT = [llength $loads] ;"
    }

    set count 1
    foreach e $loads {
        set id [dict get $e id]
        set temp [dict get $e temp]
        Writer::WriteLine [format " $fi $fi $fg $fg ;" $count $id 1 $temp] 4
        incr count
    }

    Writer::WriteLine "</TEMPERATURE_VARIATION>\n" 3
}

# Prints the Gravity Load block.
# 
# @param load_case The name of the load case title.
proc Writer::GravityLoad {node} {
    variable fg; variable fi; variable fs;

    if {[SpdAux::GetNodeValue $node "./value\[@n = 'gravity' \]"] == "No"} {
        return
    }

    if {$::Writer::comment} {
        Writer::WriteLine "<GRAVITY_LOAD>" 3
        Writer::WriteLine "## Gravity acceleration (global coordinate system)" 4
        Writer::WriteLine "## Content of each column:" 4
        Writer::WriteLine "#  A -> Acceleration - XG1" 4
        Writer::WriteLine "#  B -> Acceleration - XG2" 4
        Writer::WriteLine "#  C -> Acceleration - XG3" 4 
        Writer::WriteLine "#" 4
        Writer::WriteLine [format "#$fs $fs $fs" A B C] 4
    }

    set gx [SpdAux::GetNodeValue $node "./value\[@n = 'x-accel' \]"]
    set gy [SpdAux::GetNodeValue $node "./value\[@n = 'y-accel' \]"]
    set gz [SpdAux::GetNodeValue $node "./value\[@n = 'z-accel' \]"]

    Writer::WriteLine [format " $fg $fg $fg ;" $gx $gy $gz] 4

    Writer::WriteLine "</GRAVITY_LOAD>\n" 3
}