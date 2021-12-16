# Writes the materials blocks to the input file.
proc Writer::Materials {} {
    variable listMat

    # Material lists. Each material type is stored in its respective list.
    set liniso [];
    # Concrete
    set nlmm101 []; set nlmm104 []; set nlmm111 [];
    # Steel
    set nlmm201 [];
    # Interface
    set nlmm301 []; set nlmm305 [];

    # Adds the materials to their respective lists.
    foreach item $listMat {
        set type [SpdAux::GetDbValue materials material $item type]

        if {$type == "_LIN_ISO"} { lappend liniso $item } 
        if {$type == "_NLMM101"} { lappend nlmm101 $item }
        if {$type == "_NLMM104"} { lappend nlmm104 $item }
        if {$type == "_NLMM111"} { lappend nlmm111 $item }
        if {$type == "_NLMM201"} { lappend nlmm201 $item }
        if {$type == "_NLMM301"} { lappend nlmm301 $item }
        if {$type == "_NLMM305"} { lappend nlmm305 $item }
    }

    # Writes the materials to file.
    if {[llength $liniso] > 0} { WriteLinIso $liniso }
    if {[llength $nlmm101] > 0} { WriteNLMM101 $nlmm101 }
    if {[llength $nlmm104] > 0} { WriteNLMM104 $nlmm104 }
    if {[llength $nlmm111] > 0} { WriteNLMM111 $nlmm111 }
    if {[llength $nlmm201] > 0} { WriteNLMM201 $nlmm201 }
    if {[llength $nlmm301] > 0} { WriteNLMM301 $nlmm301 }
    if {[llength $nlmm305] > 0} { WriteNLMM301 $nlmm305 }
}

# Writes the linear isotropic block.
#
# @param liniso List of lin iso materials. 
proc Writer::WriteLinIso {liniso} {
    variable fg ; variable fi ; variable fs

    Writer::WriteLine "<LINEAR_ISOTROPIC_MATERIALS>" 2

    if {$Writer::comment} {
        Writer::WriteLine "## Keyword: _LIN_ISO" 3
        Writer::WriteLine "## Properties of the linear isotropic materials" 3
        Writer::WriteLine "COUNT =  [llength $liniso] ; # N. of linear isotropic materials" 3
        Writer::WriteLine
        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> Material name" 3
        Writer::WriteLine "#  C -> Mass per unit volume" 3
        Writer::WriteLine "#  D -> Temperature coefficient" 3
        Writer::WriteLine "#  E -> Young's modulus" 3
        Writer::WriteLine "#  F -> Poisson's coefficient" 3
        WriteLine [format "#$fs $fs $fs $fs $fs $fs" A B C D E F] 3
    } else {
        Writer::WriteLine "COUNT =  [llength $liniso] ;" 3
    }

    set count 1

    foreach item $liniso {
        set rho [SpdAux::GetDbValue materials material $item rho] 
        set alpha [SpdAux::GetDbValue materials material $item alpha]
        set e [SpdAux::GetDbValue materials material $item e]
        set nu [SpdAux::GetDbValue materials material $item nu]
        set fmt   [format " $fi $fs $fg $fg $fg $fg ;" $count $item $rho $alpha $e $nu]
        Writer::WriteLine $fmt 3

        incr count
    }

    Writer::WriteLine "</LINEAR_ISOTROPIC_MATERIALS>\n" 2
}
