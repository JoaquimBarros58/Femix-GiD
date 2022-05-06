# #############################################################################
# spdAux.tcl --
#
# GiD-FEMIX problem type.
#
# This file implements functions related to the structure of the problem type.
# 
# #############################################################################

namespace eval SpdAux {
    # Namespace variables declaration
}

# Gets a femix keyword from the data tree. It gets the value from the 
# data tree, thus it converts the value to uppercase and adds an underscore at
# the beginning of the keyword. For example: if the data tree value is "static"
# the function will return "_STATIC".
# 
# @param xp String with the path to the node.
# 
# @return The femix keyword.
proc SpdAux::GetTag {xp} {
    return _[string toupper [SpdAux::GetValue $xp]]
}

# Converts Yes/No data tree value to femix keyword _YES/_NO.
# 
# @param xp String with the path to the node.
# 
# @return Thee femix keyword.
# 
# Example:
#    set path {/*/container[@n="main_parameters"]//value[@n="analysis_type"]}
#    SpdAux::GetTagYesNo $path
proc SpdAux::GetTagYesNo {xp} {
    if {[SpdAux::GetValue $xp] == "Yes"} { 
        return "_Y" 
    } else { 
        return "_N" 
    }
}

# Get a value from the data tree.
# 
# @param xp String with the path to the node.
# @param att Attribute, default is v. It can be n for name or v for value.
# 
# @return The node value.
# 
# Example:
#    set path {/*/container[@n="main_parameters"]//value[@n="analysis_type"]}
#    SpdAux::GetValue $path
# 
proc SpdAux::GetValue {xp {att v}} {
    set root [$::gid_groups_conds::doc documentElement]
    set child [$root selectNodes $xp]
    return [get_domnode_attribute $child $att]
}

# Gets the values from a specific node.
# 
# @param node Data tree node.
# @param xp String with the xpath to the node.
# 
# @return The value (with units) correspondent to the given data tree node.
# 
# Example:
#    SpdAux::GetNodeValue $gNode ".//value\[@n='[lindex $xpld $i]']"
proc SpdAux::GetNodeValue {node xp} {
    set value [$node selectNodes $xp]
    # return [get_domnode_attribute $value v]
    return [gid_groups_conds::convert_value_to_active $value] 
}

# Gets the type of a database node.
#
# @param cname Name of the container which gather all nodes of the database.
# @param block Name of the blockdata used to represent the database.
# @param name Name of the database node.
# 
# @return The corresponding type of the database node. For example, to get the type of 
#         the LIN_ISO material node in the database materials we do:
#         SpdAux::GetType materials material LIN_ISO
#         The procedure will return: _LIN_ISO
proc SpdAux::GetDbType {cname block name} {
    set root [$::gid_groups_conds::doc documentElement]
    set xp {/*/container[@n=$cname]//}
    append xp [format_xpath {blockdata[@n=%s and @name=%s]/value[@n="type"]} $block $name]
    set valueNode [$root selectNodes $xp]
    return [gid_groups_conds::convert_value_to_default $valueNode]
}

# Gets a value from a specific database node.
#
# @param cname Name of the container which gather all nodes of the database.
# @param block Name of the blockdata used to represent the database.
# @param name Name of the database node.
# @param value Value of the node field.
# 
# @return The corresponding value.
proc SpdAux::GetDbValue {cname block name value} {
    set root [$::gid_groups_conds::doc documentElement]
    set xp1 {/*/container[@n=$cname]//}
    append xp1 [format_xpath {blockdata[@n=%s and @name=%s]/value[@n=%s]} $block $name $value]
    set valueNode [$root selectNodes $xp1]
    return [gid_groups_conds::convert_value_to_active $valueNode]
}

# Counts the number of Load Cases.
# 
# @return The number of load cases in the Load Cases node.
proc SpdAux::GetNumLoadCases {} {
    return [SpdAux::Count "/*/container\[@n = 'lcases' \]/blockdata"]
}

# Get the loads cases names.
# 
# @return The names of the load cases.
proc SpdAux::GetLoadCasesNames {} {
    set root [$::gid_groups_conds::doc documentElement]
    set lcs [SpdAux::GetLoadCases $root]
    set names {}

    foreach l [split $lcs ,] {
        lappend names [lindex $l 1]
    }

    return $names
}

# Gets the id of a given load case name. The id is its position in the tree.
# 
# @param name The load case name.
# @return The index of the load case.
proc SpdAux::GetLoadCaseId {name} {
    set lcs [SpdAux::GetLoadCasesNames]
    for {set i 1} {$i <= [llength $lcs]} {incr i} {
        if {[lindex $lcs $i] == $name} {
            return $i
        }
    }
}

# Counts the number of children of a given node.
# 
# @param xp Xpath to the node.
# 
# @return The number of childrens.
proc SpdAux::Count {xpath} {
    set root [$::gid_groups_conds::doc documentElement]
    set nodes [$root selectNodes $xpath]
    return [llength $nodes]
}

# -----------------------------------------------
# Procedures called from the spd file.
# -----------------------------------------------

# Auxiliary procs invoked from the tree (see .spd xml description)
# This procedure return the list of materials stored in the material tree node.
proc SpdAux::GetMaterials {domNode args} {
    set xPath {//container[@n="materials"]}
    set domMaterials [$domNode selectNodes $xPath]
    if { $domMaterials == "" } {
        error [= "xpath '%s' not found in the spd file" $xPath]
    }

    # Image displayed in the dropdown list.
    set image materials
    set result [list]
    foreach node [$domMaterials childNodes] {
        set name [$node @name] 
        lappend result [list 0 $name $name $image 1]
    }

    return [join $result ,]
}

# This procedure return the list of gemetries stored in the geometry
# tree node.
proc SpdAux::GetGeom1D {domNode args} {
    set xPath {//container[@n="geometries"]}
    set domGeoms [$domNode selectNodes $xPath]
    if { $domGeoms == "" } {
        error [= "xpath '%s' not found in the spd file" $xPath]
    }

    # Image displayed in the dropdown list.
    set image sections
    set result [list]
    foreach node [$domGeoms childNodes] {
        set name [$node @name] 
        # Gets only cross, frame2d and frame3d geometries.
        # _LAM_THICK is not a 1D geometry but it will be added becuase of the 
        # interface 2d element.
        set type [GetNodeValue $node ".//value\[@n='type']"]
        if {$type == "_CS_AREA" || $type == "_CS_2D" || $type == "_CS_3D" || $type == "_LAM_THICK"} {
            lappend result [list 0 $name $name $image 1]
        }
    }

    return [join $result ,]
}

# This procedure return the list of geometries stored in the geometry
# tree node.
proc SpdAux::GetGeom2D {domNode args} {
    set xPath {//container[@n="geometries"]}
    set domGeoms [$domNode selectNodes $xPath]
    if { $domGeoms == "" } {
        error [= "xpath '%s' not found in the spd file" $xPath]
    }

    # Image displayed in the dropdown list.
    set image sections
    set result [list]
    foreach node [$domGeoms childNodes] {
        set name [$node @name] 
        # Gets only laminates sections.
        set type [GetNodeValue $node ".//value\[@n='type']"]
        if {$type == "_LAM_THICK" || $type == "plaminate"} {
            lappend result [list 0 $name $name $image 1]
        }
    }

    return [join $result ,]
}

# This procedure return the list of integration rules stored in the 
# integrations tree node.
proc SpdAux::GetIntegrations {domNode args} {
    set xPath {//container[@n="integrations"]}
    set domIntegrations [$domNode selectNodes $xPath]
    if { $domIntegrations == "" } {
        error [= "xpath '%s' not found in the spd file" $xPath]
    }

    # Image displayed in the dropdown list.
    set image rules
    set result [list]
    foreach node [$domIntegrations childNodes] {
        set name [$node @name] 
        lappend result [list 0 $name $name $image 1]
    }

    return [join $result ,]
}

# Gets the name of all groups created in the tree.
proc SpdAux::GetGroups {} {
    set grpList [GiD_Groups list ""]
    return [join $grpList ,]
}

# Finds the id of a group in the group list.
# 
# @param name Name of the group.
# 
# @return The index of the group in the group list.
proc SpdAux::GetGroupId {name} {
    set grpList [GiD_Groups list ""]
    return [lsearch $grpList $name]
}

# Gets the load cases nodes.
proc SpdAux::GetLoadCases {domNode args} {
    set xPath {//container[@n="lcases"]}
    set domLcases [$domNode selectNodes $xPath]
    if { $domLcases == "" } {
        error [= "xpath '%s' not found in the spd file" $xPath]
    }

    # Image displayed in the dropdown list.
    set image lcases
    set result [list]
    foreach node [$domLcases childNodes] {
        set name [$node @name] 
        lappend result [list 0 $name $name $image 1]
    }

    return [join $result ,]
}