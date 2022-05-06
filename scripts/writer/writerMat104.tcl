# Writes the concrete NLMM104 block.
#
# @param nlmm104 List of nlmm104 materials.
proc Writer::WriteNLMM104 {nlmm104} {
    variable fg ; variable fi ; variable fs

    Writer::WriteLine "<NLMM104>" 2

    if {$Writer::comment} {
        Writer::WriteLine "## Keyword: _NLMM104" 3
        Writer::WriteLine "## Properties of the NLMM104 material model" 3
        Writer::WriteLine "COUNT =  [llength $nlmm104] ; # N. of NLMM104 materials" 3
        Writer::WriteLine
        Writer::WriteLine "## Content of each column:" 3
        Writer::WriteLine "#  A -> Counter" 3
        Writer::WriteLine "#  B -> Name of the material model" 3
        Writer::WriteLine "#  C -> Mass per unit volume" 3
        Writer::WriteLine "#  D -> Temperature coefficient" 3
        Writer::WriteLine "#  E -> Poisson's coefficient" 3
        Writer::WriteLine "#  F -> Young's modulus" 3
        Writer::WriteLine "#  G -> Compressive strength" 3
        Writer::WriteLine "#  H -> Tensile strength" 3
        Writer::WriteLine "#  I -> Type of tensile-softening diagram" 3
        Writer::WriteLine "#       - Available keywords: _TRILINEAR, _QUADRILINEAR or _CORNELISSEN" 3
        Writer::WriteLine "#  J -> Ratio between the strain at the first post-peak point and the" 3
        Writer::WriteLine "#       ultimate strain of the trilinear/quadrilinear tensile-softening diagram (fracture mode I)" 3
        Writer::WriteLine "#  K -> Ratio between the stress at the first post-peak point and the" 3
        Writer::WriteLine "#       tensile strength of the trilinear/quadrilinear tensile-softening diagram (fracture mode I)" 3
        Writer::WriteLine "#  L -> Ratio between the strain at the second post-peak point and the" 3
        Writer::WriteLine "#       ultimate strain of the trilinear/quadrilinear tensile-softening diagram (fracture mode I)" 3
        Writer::WriteLine "#  M -> Ratio between the stress at the second post-peak point and the" 3
        Writer::WriteLine "#       tensile strength of the trilinear/quadrilinear tensile-softening diagram (fracture mode I)" 3
        Writer::WriteLine "#  N -> Ratio between the strain at the third post-peak point and the" 3
        Writer::WriteLine "#       ultimate strain of the quadrilinear tensile-softening diagram (fracture mode I)" 3
        Writer::WriteLine "#  O -> Ratio between the stress at the third post-peak point and the" 3
        Writer::WriteLine "#       tensile strength of the quadrilinear tensile-softening diagram (fracture mode I)" 3
        Writer::WriteLine "#  P -> Mode I fracture energy (Gf)" 3
        Writer::WriteLine "#  Q -> Type of mode I fracture energy update law" 3
        Writer::WriteLine "#       - Available keywords: _NONE, _LINEAR, _QUADRATIC or _CUBIC" 3
        Writer::WriteLine "#  R -> Ultimate crack shear sliding (keyword or constant value)" 3
        Writer::WriteLine "#       - Available keywords: _MAXIMUM_CRACKWIDTH" 3
        Writer::WriteLine "#  S -> Parameter to define the mode I fracture energy available to the new crack" 3
        Writer::WriteLine "#  T -> Type of shear-softening diagram" 3
        Writer::WriteLine "#       - Available keywords: _NONE or _LINEAR" 3
        Writer::WriteLine "#  U -> Type of shear retention factor law (keyword or constant value)" 3
        Writer::WriteLine "#       - Available keywords: _LINEAR, _QUADRATIC or _CUBIC" 3
        Writer::WriteLine "#  V -> Type of crack shear modelling appoach (used in shear retention model)" 3
        Writer::WriteLine "#       - Available keywords: _INCREMENTAL or _TOTAL" 3
        Writer::WriteLine "#  W -> Crack shear strength" 3
        Writer::WriteLine "#  X -> Shear fracture energy (Gfs=GfII) (in nonlinear Mindlin shell: In-plane shear fracture energy)" 3
        Writer::WriteLine "#  Y -> Type of unloading/reloading diagram" 3
        Writer::WriteLine "#       - Available keywords: _SECANT or _ELASTIC" 3
        Writer::WriteLine "#  Z -> Crack band width for the fracture mode I (keyword or constant value)" 3
        Writer::WriteLine "#       - Available keywords: _SQRT_ELEMENT, _SQRT_IP, _OLIVER_ELEMENT or _OLIVER_IP" 3
        Writer::WriteLine "# AA -> Maximum n. of cracks" 3
        Writer::WriteLine "# AB -> Threshold angle (degress)" 3
        Writer::WriteLine "#" 3
        Writer::WriteLine "# Out-of-plane shear data:" 3
        Writer::WriteLine "#    -> Used in nonlinear Mindlin shell" 3
        Writer::WriteLine "#" 3
        Writer::WriteLine "# AC -> Type of out-of-plane shear-softening diagram" 3
        Writer::WriteLine "#       - Available keywords: _NONE, _LINEAR, _TRILINEAR or _CORNELISSEN" 3
        Writer::WriteLine "# AD -> Minimum out-of-plane shear stress for softening behavior" 3
        Writer::WriteLine "# AE -> Out-of-plane shear fracture energy" 3
        Writer::WriteLine "# AF -> Ratio between the out-of-plane shear strain at the first" 3
        Writer::WriteLine "#       post-peak point and the ultimate out-of-plane shear strain" 3
        Writer::WriteLine "#       trilinear out-of-plane shear-softening diagram" 3
        Writer::WriteLine "# AG -> Ratio between the out-of-plane shear stress at the first" 3
        Writer::WriteLine "#       post-peak point and the out-of-plane shear strength of the" 3
        Writer::WriteLine "#       trilinear out-of-plane shear-softening diagram" 3
        Writer::WriteLine "# AH -> Ratio between the out-of-plane shear strain at the second" 3
        Writer::WriteLine "#       post-peak point and the ultimate out-of-plane shear strain" 3
        Writer::WriteLine "#       of the trilinear out-of-plane shear-softening diagram" 3
        Writer::WriteLine "# AI -> Ratio between the out-of-plane shear stress at the second" 3
        Writer::WriteLine "#       post-peak point and the out-of-plane shear strength of the" 3
        Writer::WriteLine "#       trilinear out-of-plane shear-softening diagram" 3
    } else {
        Writer::WriteLine "COUNT =  [llength $nlmm104] ;" 3
    }

    set count 1

    foreach item $nlmm104 {
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
        # Fracture mode I data. Columns H-S
        set fct [SpdAux::GetNodeValue $child ".//value\[@n='fct']"]
        set ten_diag _[SpdAux::GetNodeValue $child ".//value\[@n='ten_diagram']"]
        set x1 [SpdAux::GetNodeValue $child ".//value\[@n='x1']"]
        set a1 [SpdAux::GetNodeValue $child ".//value\[@n='a1']"]
        set x2 [SpdAux::GetNodeValue $child ".//value\[@n='x2']"]
        set a2 [SpdAux::GetNodeValue $child ".//value\[@n='a2']"]
        set x3 [SpdAux::GetNodeValue $child ".//value\[@n='x3']"]
        set a3 [SpdAux::GetNodeValue $child ".//value\[@n='a3']"]
        set gf [SpdAux::GetNodeValue $child ".//value\[@n='gf']"]
        set p1 _[SpdAux::GetNodeValue $child ".//value\[@n='p1']"]
        set sliding [SpdAux::GetNodeValue $child ".//value\[@n='sliding']"]
        set sliding [Femix::CheckValue $sliding {MAXIMUM_CRACKWIDTH}]
        set p2 [SpdAux::GetNodeValue $child ".//value\[@n='p2']"]
        # Fracture mode II data. Columns T-X
        set shear_diag _[SpdAux::GetNodeValue $child ".//value\[@n='shear_diagram']"]
        set retention [SpdAux::GetNodeValue $child ".//value\[@n='retention']"]
        set retention [Femix::CheckValue $retention {LINEAR QUADRATIC CUBIC}]
        set approach _[SpdAux::GetNodeValue $child ".//value\[@n='approach']"]
        set shear_strength [SpdAux::GetNodeValue $child ".//value\[@n='shear_strength']"]
        set shear_fracture [SpdAux::GetNodeValue $child ".//value\[@n='shear_fracture']"]
        # Miscellaneous data. Columns Y-AB
        set load_diag _[SpdAux::GetNodeValue $child ".//value\[@n='load_diagram']"]
        set crack_band [SpdAux::GetNodeValue $child ".//value\[@n='crack_band']"]
        set crack_band [Femix::CheckValue $crack_band {SQRT_ELEMENT SQRT_IP OLIVER_ELEMENT OLIVER_IP}]
        set crack_num [SpdAux::GetNodeValue $child ".//value\[@n='crack_num']"]
        set crack_num [expr int($crack_num)] ; # make sure it is an integer number.
        set crack_angle_rad [SpdAux::GetNodeValue $child ".//value\[@n='crack_angle']"]
        set crack_angle [gid_groups_conds::convert_unit_value Angle $crack_angle_rad rad deg]; # convert to degree
        # Out-of-plane Shear data. Columns AC-AI
        set out_diag _[SpdAux::GetNodeValue $child ".//value\[@n='out_diagram']"]
        set out_stress [SpdAux::GetNodeValue $child ".//value\[@n='out_stress']"]
        set out_fracture [SpdAux::GetNodeValue $child ".//value\[@n='out_fracture']"]
        set z1 [SpdAux::GetNodeValue $child ".//value\[@n='z1']"]
        set l1 [SpdAux::GetNodeValue $child ".//value\[@n='l1']"]
        set z2 [SpdAux::GetNodeValue $child ".//value\[@n='z2']"]
        set l2 [SpdAux::GetNodeValue $child ".//value\[@n='l2']"]

        # Printing data to file...
        if {$Writer::comment} {
            WriteLine [format "#$fs $fs $fs $fs $fs $fs $fs $fs" A B C D E F G H] 3
        }
        set fmt   [format " $fi $fs $fg $fg $fg $fg $fg $fg" $count $item $rho $alpha $nu $e $fc $fct]
        Writer::WriteLine $fmt 3

        if {$Writer::comment} {
            WriteLine [format "#$fs $fs $fs $fs $fs $fs $fs $fs $fs $fs $fs" I J K L M N O P Q R S] 3
        }
        set fmt   [format " $fs $fg $fg $fg $fg $fg $fg $fg $fs $fs $fg" $ten_diag $x1 $a1 $x2 $a2 $x3 $a3 $gf $p1 $sliding $p2]
        Writer::WriteLine $fmt 3
        
        if {$Writer::comment} {
            WriteLine [format "#$fs $fs $fs $fs $fs" T U V W X] 3
        }
        set fmt   [format " $fs $fs $fs $fg $fg" $shear_diag $retention $approach $shear_strength $shear_fracture]
        Writer::WriteLine $fmt 3

        if {$Writer::comment} {
            WriteLine [format "#$fs $fs $fs $fs" Y Z AA AB] 3
        }
        set fmt   [format " $fs $fs $fi $fg" $load_diag $crack_band $crack_num $crack_angle]
        Writer::WriteLine $fmt 3

        if {$Writer::comment} {
            WriteLine [format "#$fs $fs $fs $fs $fs $fs $fs" AC AD AE AF AG AH AI] 3
        }
        set fmt   [format " $fs $fg $fg $fg $fg $fg $fg ;" $out_diag $out_stress $out_fracture $z1 $l1 $z2 $l2]
        Writer::WriteLine $fmt 3

        incr count
    }

    Writer::WriteLine "</NLMM104>\n" 2
}