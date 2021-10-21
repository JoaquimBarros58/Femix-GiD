# Writes the material NLMM305 block (Interface 3D).
#
# Arguments:
# ----------
# nlmm305: List of nlmm305 materials.
# 
proc Writer::WriteNLMM305 {nlmm305} {
    variable fg; variable fi; variable fs

    Writer::WriteLine "<NLMM305>" 2

    if {$Writer::comment} {
        Writer::WriteLine "## Keyword: _NLMM305" 3
        Writer::WriteLine "## Properties of the NLMM305 material model" 3
        Writer::WriteLine "COUNT =  [llength $nlmm305] ; # N. of NLMM305 materials" 3
        Writer::WriteLine

        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> Name of the material model" 3
        Writer::WriteLine "#  C -> Slip at the end of the linear bond stress-slip relationship" 3
        Writer::WriteLine "#  D -> Slip at peak bond stress" 3
        Writer::WriteLine "#  E -> Material cohesion" 3
        Writer::WriteLine "#  F -> Friction angle between materials in contact" 3
        Writer::WriteLine "#  G -> Parameter used in the definition of the pre-peak bond stress-slip relationship" 3
        Writer::WriteLine "#  H -> Parameter used in the definition of the post-peak bond stress-slip relationship" 3
        Writer::WriteLine "#  I -> Normal stiffness" 3
        WriteLine [format "#$fs $fs $fs $fs $fs $fs $fs $fs $fs" A B C D E F G H I] 3
    } else {
        Writer::WriteLine "COUNT =  [llength $nlmm305] ;" 3
    }

    set count 1

    foreach item $nlmm305 {
        # Gets the material node.
        set xp1 "./container\[@n='materials'\]/blockdata\[@name='$item'\]"
        set root [$::gid_groups_conds::doc documentElement]
        set child [$root selectNodes $xp1]

        set s0 [SpdAux::GetNodeValue $child ".//value\[@n='s0']"]
        set sm [SpdAux::GetNodeValue $child ".//value\[@n='sm']"]
        set c [SpdAux::GetNodeValue $child ".//value\[@n='c']"]
        set af [SpdAux::GetNodeValue $child ".//value\[@n='af']"]
        set a [SpdAux::GetNodeValue $child ".//value\[@n='a']"]
        set b [SpdAux::GetNodeValue $child ".//value\[@n='b']"]
        set kn [SpdAux::GetNodeValue $child ".//value\[@n='kn']"]

        set fmt   [format " $fi $fs $fg $fg $fg $fg $fg $fg $fg ;" $count $item $s0 $sm $c $af $a $b $kn]
        Writer::WriteLine $fmt 3

        incr count
    }

    Writer::WriteLine "</NLMM305>\n" 2
}