# Writes the geometry blocks to the input file.
# 
proc Writer::Geometry {} {
    variable listGeom
    set cross []
    set f2d []
    set f3d []
    set lam []

    foreach item $listGeom {
        set type [SpdAux::GetDbType geometries geometry $item]

        if {$type == "_CS_AREA"} {
            lappend cross $item
        } elseif {$type == "_CS_2D"} {
            lappend f2d $item
        } elseif {$type == "_CS_3D"} {
            lappend f3d $item
        } elseif {$type == "_LAM_THICK"} {
            lappend lam $item
        }
    }

    if {[llength $cross] > 0} { WriteCross $cross }
    if {[llength $lam] > 0} { WriteLaminate $lam }
}

# Writes the cross-section areas
#
# Arguments:
# ----------
# cross: List of cross-section areas.
# 
proc Writer::WriteCross {cross} {
    variable fs; variable fi; variable fg

    Writer::WriteLine <CROSS_SECTION_AREAS> 2
    if {$Writer::comment} {
        Writer::WriteLine "## Keyword: _CS_AREA" 3
        Writer::WriteLine "## Cross section areas" 3
        Writer::WriteLine "COUNT =  [llength $cross] ; # N. of cross section areas" 3
        Writer::WriteLine
    } else {
        Writer::WriteLine "COUNT =  [llength $cross] ;" 3
    }

    set count 1

    if {$Writer::comment} {
        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> Name of the cross section" 3
        Writer::WriteLine "#  C -> Area" 3
        Writer::WriteLine [format "#$fs $fs $fs" A B C] 3
    }
    foreach item $cross {
        set fmt [format " $fi $fs $fg ;" $count $item [SpdAux::GetDbValue geometries geometry $item area]]
        Writer::WriteLine $fmt 3
        incr count
    }

    Writer::WriteLine "</CROSS_SECTION_AREAS>" 2
    Writer::WriteLine
}

proc Writer::WriteLaminate {lam} {
    variable fs ; variable fi ; variable fg

    Writer::WriteLine <LAMINATE_THICKNESSES> 2
    if {$Writer::comment} {
        Writer::WriteLine "## Keyword: _LAM_THICK" 3
        Writer::WriteLine "## Thickness of the laminate elements" 3
        Writer::WriteLine "COUNT =  [llength $lam] ; # N. of nodal thicknesses" 3
        Writer::WriteLine
    } else {
        Writer::WriteLine "COUNT =  [llength $lam] ;" 3
    }

    set count 1

    if {$Writer::comment} {
        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> Name of the thickness" 3
        Writer::WriteLine "#  C -> thickness" 3
        Writer::WriteLine [format "#$fs $fs $fs" A B C] 3
    }
    foreach item $lam {
        set fmt [format " $fi $fs $fg ;" $count $item [SpdAux::GetDbValue geometries geometry $item thick]]
        Writer::WriteLine $fmt 3
        incr count
    }

    Writer::WriteLine </LAMINATE_THICKNESSES> 2
    Writer::WriteLine
}