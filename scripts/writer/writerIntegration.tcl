# Writes the integration rule block.
# 
proc Writer::Integration {} {
    variable fs ; variable fi ; 
    variable listRule

    if {[llength $listRule] <= 0} { return }

    Writer::WriteLine <NUMERICAL_INTEGRATION> 2

    if {$Writer::comment} {
        Writer::WriteLine "## Keywords: _GLEG, _GLOB or _NCOTES" 3
        Writer::WriteLine "## Numerical integration definition" 3
        Writer::WriteLine "COUNT =  [llength $listRule] ; # N. of layouts of integration points" 3
        Writer::WriteLine

        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> Name of the layout" 3
        Writer::WriteLine "#  C -> N. of keywords defining the layout" 3
        Writer::WriteLine "#  D -> Keywords defining the type of term and the n. of points in each direction" 3
        Writer::WriteLine "#" 3
        Writer::WriteLine "#  Valid syntax for D is the following:" 3
        Writer::WriteLine "#     _i_Sj_k" 3
        Writer::WriteLine "#" 3
        Writer::WriteLine "#     i: type of terms" 3
        Writer::WriteLine "#       G -> General use (stiffness matrix, springs and load vector)" 3
        Writer::WriteLine "#       M -> Membrane terms (stiffness matrix)" 3
        Writer::WriteLine "#       S -> Shear terms (stiffness matrix)" 3
        Writer::WriteLine "#       T -> Torsional terms (stiffness matrix)" 3
        Writer::WriteLine "#       B -> Bending terms (stiffness matrix)" 3
        Writer::WriteLine "#" 3
        Writer::WriteLine "#     j: direction" 3
        Writer::WriteLine "#       1 -> direction s1" 3
        Writer::WriteLine "#       2 -> direction s2" 3
        Writer::WriteLine "#       3 -> direction s3" 3
        Writer::WriteLine "#" 3
        Writer::WriteLine "#     k: n. of points in the specified direction" 3
        Writer::WriteLine "#" 3
        Writer::WriteLine "#     Note: k must be in the range \[1,10\]" 3
        Writer::WriteLine "#" 3
        Writer::WriteLine "#     Examples: _G_S1_5, _M_S2_1, _S_S3_2, _T_S1_7, _B_S2_10" 3
        Writer::WriteLine "#" 3
        Writer::WriteLine [format "#$fs $fs $fs $fs" A B C D] 3
    } else {
        Writer::WriteLine "COUNT =  [llength $listRule] ;" 3
    }

    set count 1

    foreach item $listRule {
        set dime [SpdAux::GetDbValue integrations rule $item dime]
        # Replace space by underscore.
        set name [join $item _]

        set term [SpdAux::GetDbValue integrations rule $item term]
        set pts [SpdAux::GetDbValue integrations rule $item points]
        set r1 [format "_%s_S1_%s" $term $pts]

        if {$dime == 1} {
            set fmt [format " $fi $fs $fi $fs ;" $count $name 1 $r1]
        } elseif {$dime == 2} {
            set term2 [SpdAux::GetDbValue integrations rule $item term2]
            set pts2 [SpdAux::GetDbValue integrations rule $item points2]
            set r2 [format "_%s_S2_%s" $term2 $pts2]

            set fmt [format " $fi $fs $fi $fs $fs ;" $count $name 2 $r1 $r2]
        } elseif {$dime == 3} {
            set term2 [SpdAux::GetDbValue integrations rule $item term2]
            set pts2 [SpdAux::GetDbValue integrations rule $item points2]
            set r2 [format "_%s_S2_%s" $term2 $pts2]

            set term3 [SpdAux::GetDbValue integrations rule $item term3]
            set pts3 [SpdAux::GetDbValue integrations rule $item points3]
            set r3 [format "_%s_S3_%s" $term3 $pts3]

            set fmt [format " $fi $fs $fi $fs $fs $fs ;" $count $name 3 $r1 $r2 $r3]
        }

        Writer::WriteLine $fmt 3
        incr count
    }
    
    Writer::WriteLine </NUMERICAL_INTEGRATION> 2
    Writer::WriteLine
}
