# #############################################################################
# Export.tcl --
#
# GiD-FEMIX problem type.
#
# This file implements functions to export the model.
#
# #############################################################################

namespace eval Export { }

# Export mesh to file.
#
# @param filename It is the name of the file.
proc Export::ExportMesh {filename} {
    # Open file for writting
    GiD_WriteCalculationFile init $filename

    # Print nodes coordinates.
    set nn [GiD_WriteCalculationFile coordinates -count ""] ;
    GiD_WriteCalculationFile puts "$nn"
    GiD_WriteCalculationFile coordinates "%d %g %g %g\n"

    # Print elements connectivities.
    set ne [GiD_WriteCalculationFile all_connectivities -count ""] ;
    GiD_WriteCalculationFile puts "$ne"
    for {set index 1} {$index <= $ne} {incr index} {
        set nodes [GiD_Mesh get element $index connectivities]
        set size [llength $nodes]
        set conn [format "%s" $nodes]
        GiD_WriteCalculationFile puts [format "%d %d %s" $index $size $conn]
    }


    if {[Femix::IsQuadratic] == 0} {
        GiD_WriteCalculationFile all_connectivities -elemtype Linear "id: %d connectivities: %d %d\n"
        GiD_WriteCalculationFile all_connectivities -elemtype Triangle "id: %d connectivities: %d %d %d\n"
        GiD_WriteCalculationFile all_connectivities -elemtype Quadrilateral "id: %d connectivities: %d %d %d %d\n"
    } else {
        GiD_WriteCalculationFile all_connectivities -elemtype Linear "id: %d connectivities: %d %d %d\n"
        GiD_WriteCalculationFile all_connectivities -elemtype Triangle -connec_ordering corner_face_corner_face "id: %d connectivities: %d %d %d %d %d %d\n"
        GiD_WriteCalculationFile all_connectivities -elemtype Quadrilateral -connec_ordering corner_face_corner_face "id: %d connectivities: %d %d %d %d %d %d %d %d\n"
    }

    # Finish writting
    GiD_WriteCalculationFile end
}