# Writes the material NLMM301 block (Interface 2D).
#
# @param nlmm301 List of nlmm301 materials.
proc Writer::WriteNLMM301 {nlmm301} {
    variable fg; variable fi; variable fs

    Writer::WriteLine "<NLMM301>" 2

    if {$Writer::comment} {
        Writer::WriteLine "## Keyword: _NLMM301" 3
        Writer::WriteLine "## Properties of the NLMM301 material model" 3
        Writer::WriteLine "COUNT =  [llength $nlmm301] ; # N. of NLMM301 materials" 3
        Writer::WriteLine

        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> Name of the material model" 3
        Writer::WriteLine "#  C -> Slip at the end of the linear bond stress-slip relationship" 3
        Writer::WriteLine "#  D -> Slip at peak bond stress" 3
        Writer::WriteLine "#  E -> Peak bond stress" 3
        Writer::WriteLine "#  F -> Parameter used in the definition of the pre-peak bond stress-slip relationship" 3
        Writer::WriteLine "#  G -> Parameter used in the definition of the post-peak bond stress-slip relationship" 3
        Writer::WriteLine "#  H -> Normal stiffness" 3
        WriteLine [format "#$fs $fs $fs $fs $fs $fs $fs $fs" A B C D E F G H] 3
    } else {
        Writer::WriteLine "COUNT =  [llength $nlmm301] ;" 3
    }

    set count 1

    foreach item $nlmm301 {
        # Gets the material node.
        set xp1 "./container\[@n='materials'\]/blockdata\[@name='$item'\]"
        set root [$::gid_groups_conds::doc documentElement]
        set child [$root selectNodes $xp1]

        set s0 [SpdAux::GetNodeValue $child ".//value\[@n='s0']"]
        set sm [SpdAux::GetNodeValue $child ".//value\[@n='sm']"]
        set tm [SpdAux::GetNodeValue $child ".//value\[@n='tm']"]
        set a [SpdAux::GetNodeValue $child ".//value\[@n='a']"]
        set b [SpdAux::GetNodeValue $child ".//value\[@n='b']"]
        set kn [SpdAux::GetNodeValue $child ".//value\[@n='kn']"]

        set fmt   [format " $fi $fs $fg $fg $fg $fg $fg $fg ;" $count $item $s0 $sm $tm $a $b $kn]
        Writer::WriteLine $fmt 3

        incr count
    }

    Writer::WriteLine "</NLMM301>\n" 2
}