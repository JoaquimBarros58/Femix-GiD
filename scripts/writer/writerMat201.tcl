# Writes the material NLMM201 block.
#
# @param nlmm201 List of nlmm201 materials.
proc Writer::WriteNLMM201 {nlmm201} {
    variable fg; variable fi; variable fs

    Writer::WriteLine "<NLMM201>" 2

    if {$Writer::comment} {
        Writer::WriteLine "## Keyword: _NLMM201" 3
        Writer::WriteLine "## Properties of the NLMM201 material model" 3
        Writer::WriteLine "COUNT =  [llength $nlmm201] ; # N. of NLMM201 materials" 3
        Writer::WriteLine
        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> Name of the material model" 3
        Writer::WriteLine "#  C -> Mass per unit volume" 3
        Writer::WriteLine "#  D -> Temperature coefficient" 3
        Writer::WriteLine "#  E -> Strain at the end of the first branch" 3
        Writer::WriteLine "#  F -> Stress at the end of the first branch" 3
        Writer::WriteLine "#  G -> Strain at the end of the second branch" 3
        Writer::WriteLine "#  H -> Stress at the end of the second branch" 3
        Writer::WriteLine "#  I -> Strain at the end of the third branch" 3
        Writer::WriteLine "#  J -> Stress at the end of the third branch" 3
        Writer::WriteLine "#  K -> Third branch exponent" 3
        WriteLine [format "#$fs $fs $fs $fs $fs $fs $fs $fs $fs $fs $fs" A B C D E F G H I J K] 3
    } else {
        Writer::WriteLine "COUNT =  [llength $nlmm201] ;" 3
    }

    set count 1

    foreach item $nlmm201 {
        # Gets the material node.
        set xp1 "./container\[@n='materials'\]/blockdata\[@name='$item'\]"
        set root [$::gid_groups_conds::doc documentElement]
        set child [$root selectNodes $xp1]

        set rho [SpdAux::GetNodeValue $child ".//value\[@n='rho']"]
        set alpha [SpdAux::GetNodeValue $child ".//value\[@n='alpha']"]
        set esy [SpdAux::GetNodeValue $child ".//value\[@n='esy']"]
        set fsy [SpdAux::GetNodeValue $child ".//value\[@n='fsy']"]
        set esh [SpdAux::GetNodeValue $child ".//value\[@n='esh']"]
        set fsh [SpdAux::GetNodeValue $child ".//value\[@n='fsh']"]
        set esu [SpdAux::GetNodeValue $child ".//value\[@n='esu']"]
        set fsu [SpdAux::GetNodeValue $child ".//value\[@n='fsu']"]
        set n [SpdAux::GetNodeValue $child ".//value\[@n='n']"]

        set fmt   [format " $fi $fs $fg $fg $fg $fg $fg $fg $fg $fg $fg ;" $count $item $rho $alpha $esy $fsy $esh $fsh $esu $fsu $n]
        Writer::WriteLine $fmt 3

        incr count
    }

    Writer::WriteLine "</NLMM201>\n" 2
}