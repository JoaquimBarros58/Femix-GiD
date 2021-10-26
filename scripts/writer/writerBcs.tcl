# Writes the support block.
# 
# @return The number of supports.
proc Writer::Supports {} {
    variable fs; variable fi;
    variable comment

    set ndim [Femix::GetNumDimension]

    Writer::WriteLine <SUPPORTS> 2

    # xpath for node "Supports\Displacement".
    set xp1 {./container[@n="bcs"]/condition[@n="bc_disp"]/group}

    # Gets all nodes from supports\displacement node.
    set root [$::gid_groups_conds::doc documentElement]

    set lines ""; # Bcs lines of the block.
    set count 1;  # Counter

    # Loop over root nodes, i.e. boundary condition nodes.
    # Each children of the root is a group node.
    foreach gNode [$root selectNodes $xp1] {
        # dof block to be written in each row, i.e. _D1, _D2, etc
        set dofs ""
         # number of degree of freedom
        set ndof 0
        # List of xpath words representing the values of the group node.
        set xpld {x-disp y-disp z-disp x-rot y-rot z-rot}

        if {$ndim == 2} {
            # dof keyword to be written in the input file.
            set tags {_D2 _D3 _D1 _R2 _R3 _R1}
        } else {
            # dof keyword to be written in the input file.
            set tags {_D1 _D2 _D3 _R1 _R2 _R3}
        }

        set size [llength $xpld]
        # Loop over the values of each group node.
        for {set i 0} {$i < $size} {incr i} {
            set dispVal [SpdAux::GetNodeValue $gNode ".//value\[@n='[lindex $xpld $i]']"]
            if {$dispVal == "Yes"} {
                append dofs [format "$fs" [lindex $tags $i]]
                incr ndof
            }
        }

        if {$ndof > 0} {
            set groupName [get_domnode_attribute $gNode n]
            set formatByGroup [dict create $groupName "%d,"]
            # Stores the results of GiD_WriteCalculationFile nodes to the temp list.
            # This command will return a list of string fomated according to the specified
            # by the variable formatByGroup. If the current tree node has more than one 
            # topology node associated to it. If the tree group node has only one topology 
            # node, thus it wil return a list containing only one string. 
            set mesh [GiD_WriteCalculationFile nodes -return $formatByGroup]
            set nodes [String::GetList $mesh ,] ; # list of node ids.

            # Replace spaces by undescore character.
            set name [join $groupName _]

            foreach e $nodes {
                append lines [Writer::WriteLine [format " $fi $fs $fi $fi $fi $fs ;\n" $count $name 1 $e $ndof $dofs] 3 0]
                incr count
            }
        }
    }

    set nbcs [expr $count - 1]

    # Print comments?
    if {$comment} {
        Writer::WriteLine "## Points with fixed degrees of freedom" 3
        Writer::WriteLine "COUNT = $nbcs ; # N. of points with fixed degrees of freedom" 3
        Writer::WriteLine
        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter (or counter range)" 3
        Writer::WriteLine "#  B -> Group name" 3
        Writer::WriteLine "#  C -> Phase (or phase range)" 3
        Writer::WriteLine "#  D -> Point number (or point number range)" 3
        Writer::WriteLine "#  E -> N. of fixed degrees of freedom in the current point(s)" 3
        Writer::WriteLine "#  F -> Fixed degrees of freedom:" 3
        Writer::WriteLine "#       Available keywords: _D1, _D2, _D3, _R1, _R2 or _R3" 3
        Writer::WriteLine [format "#$fs $fs $fs $fs $fs $fs" A B C D E F] 3
    } else {
        Writer::WriteLine "COUNT = $nbcs ;" 3
    }

    append lines [Writer::WriteLine </SUPPORTS> 2 0]

    Writer::WriteLine $lines

    Writer::WriteLine

    return $nbcs
}