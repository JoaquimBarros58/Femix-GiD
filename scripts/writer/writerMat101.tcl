# Writes the concrete NLMM101 block.
#
# @param nlmm101 List of nlmm101 materials.
proc Writer::WriteNLMM101 {nlmm101} {
    variable fg ; variable fi ; variable fs

    Writer::WriteLine "<NLMM101>" 2

    if {$Writer::comment} {
        Writer::WriteLine "## Keyword: _NLMM101" 3
        Writer::WriteLine "## Properties of the NLMM101 material model" 3
        Writer::WriteLine "COUNT =  [llength $nlmm101] ; # N. of NLMM101 materials" 3
        Writer::WriteLine
        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> Name of the material model" 3
        Writer::WriteLine "#  C -> Mass per unit volume" 3
        Writer::WriteLine "#  D -> Temperature coefficient" 3
        Writer::WriteLine "#  E -> Poisson's coefficient" 3
        Writer::WriteLine "#  F -> Initial Young's modulus" 3
        Writer::WriteLine "#  G -> Compression strength" 3
        Writer::WriteLine "#  H ->	Tensile strength" 3
        Writer::WriteLine "#  I -> Type of tensile-softening diagram" 3
        Writer::WriteLine "#       - Available keywords: _TRILINEAR or _CORNELISSEN" 3
        Writer::WriteLine "#  J -> Ratio between the strain at the first post-peak point and the" 3
        Writer::WriteLine "#       ultimate strain of the trilinear tensile-softening diagram (fracture mode I)" 3
        Writer::WriteLine "#  K -> Ratio between the stress at the first post-peak point and the" 3
        Writer::WriteLine "#       tensile strength of the trilinear tensile-softening diagram (fracture mode I)" 3
        Writer::WriteLine "#  L -> Ratio between the strain at the second post-peak point and the" 3
        Writer::WriteLine "#       ultimate strain of the trilinear tensile-softening diagram (fracture mode I)" 3
        Writer::WriteLine "#  M -> Ratio between the stress at the second post-peak point and the" 3
        Writer::WriteLine "#       tensile strength of the trilinear tensile-softening diagram (fracture mode I)" 3
        Writer::WriteLine "#  N -> Mode I fracture energy (Gf)" 3
        Writer::WriteLine "#  O -> Parameter to define the mode I fracture energy available to the new crack" 3
        Writer::WriteLine "#  P -> Type of shear retention factor law (keyword or constant value)" 3
        Writer::WriteLine "#       - Available keywords: _LINEAR, _QUADRATIC or _CUBIC" 3
        Writer::WriteLine "#  Q -> Type of unloading and reloading diagram" 3
        Writer::WriteLine "#       - Available keywords: _SECANT or _ELASTIC" 3
        Writer::WriteLine "#  R -> Crack band width for the fracture mode I (keyword or constant value)" 3
        Writer::WriteLine "#       - Available keywords: _SQRT_ELEMENT or _SQRT_IP" 3
        Writer::WriteLine "#  S -> Maximum n. of cracks" 3
        Writer::WriteLine "#  T -> Threshold angle (degress)" 3
    } else {
        Writer::WriteLine "COUNT =  [llength $nlmm101] ;" 3
    }

    set count 1

    foreach item $nlmm101 {
        # Gets the material node.
        set xp1 "./container\[@n='materials'\]/blockdata\[@name='$item'\]"
        set root [$::gid_groups_conds::doc documentElement]
        set child [$root selectNodes $xp1]
        # General data. Columns C-G
        set rho [SpdAux::GetNodeValue $child ".//value\[@n='rho']"]
        set alpha [SpdAux::GetNodeValue $child ".//value\[@n='alpha']"]
        set e [SpdAux::GetNodeValue $child ".//value\[@n='e']"]
        set nu [SpdAux::GetNodeValue $child ".//value\[@n='nu']"]
        set fc [SpdAux::GetNodeValue $child ".//value\[@n='fc']"]
        # Fracture mode I data. Columns H-P
        set fct [SpdAux::GetNodeValue $child ".//value\[@n='fct']"]
        set ten_diag _[SpdAux::GetNodeValue $child ".//value\[@n='ten_diag']"]
        set x1 [SpdAux::GetNodeValue $child ".//value\[@n='x1']"]
        set a1 [SpdAux::GetNodeValue $child ".//value\[@n='a1']"]
        set x2 [SpdAux::GetNodeValue $child ".//value\[@n='x2']"]
        set a2 [SpdAux::GetNodeValue $child ".//value\[@n='a2']"]
        set gf [SpdAux::GetNodeValue $child ".//value\[@n='gf']"]
        set p1 _[SpdAux::GetNodeValue $child ".//value\[@n='p1']"]
        set p2 [SpdAux::GetNodeValue $child ".//value\[@n='p2']"]
        # Miscellaneous data. Columns Q-T
        set load_diag _[SpdAux::GetNodeValue $child ".//value\[@n='load_diag']"]
        set crack_band [SpdAux::GetNodeValue $child ".//value\[@n='crack_band']"]
        # Checking if the crack band width is valid.
        set val [String::IsNumeric $crack_band ]
        if {$val != ""} { # is the value a number...
            set crack_band $val
        } else { # or it is a available keyword.
            if {$val == "SQRT_ELEMENT" || $val == "SQRT_IP"} {
                set crack_band _$val
            } else {
                set crack_band _SQRT_IP
            }
        }
        set crack_num [SpdAux::GetNodeValue $child ".//value\[@n='crack_num']"]
        set crack_num [expr int($crack_num)] ; # make sure it is an integer number.
        set crack_angle [SpdAux::GetNodeValue $child ".//value\[@n='crack_angle']"]

        # Printing data to file...
        if {$Writer::comment} {
            WriteLine [format "#$fs $fs $fs $fs $fs $fs $fs $fs" A B C D E F G H] 3
        }
        set fmt   [format " $fi $fs $fg $fg $fg $fg $fg $fg" $count $item $rho $alpha $nu $e $fc $fct]
        Writer::WriteLine $fmt 3

        if {$Writer::comment} {
            WriteLine [format "#$fs $fs $fs $fs $fs" I J K L M] 3
        }
        set fmt   [format " $fs $fg $fg $fg $fg" $ten_diag $x1 $a1 $x2 $a2]
        Writer::WriteLine $fmt 3

        if {$Writer::comment} {
            WriteLine [format "#$fs $fs $fs $fs $fs $fs $fs" N O P Q R S T] 3
        }
        set fmt   [format " $fg $fg $fs $fs $fs $fi $fg ;" $gf $p2 $p1 $load_diag $crack_band $crack_num $crack_angle]
        Writer::WriteLine $fmt 3

        incr count
    }

    Writer::WriteLine "</NLMM101>\n" 2
}