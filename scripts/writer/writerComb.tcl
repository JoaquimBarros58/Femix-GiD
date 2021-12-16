# Writes the combination block.
proc Writer::Combinations {} {
    set listComb {}

    set path [Femix::GetProjecDir]
    set name [Femix::GetModelName].cmb
    set filename [file join $path $name]
    if {![file exists $filename]} { 
        # There is no combination file, thus it is not necessary
        # to print this block.
        return
    } else {
        # Reads the file.
        set file [open $filename "r"]
        set data [read $file]
        close $file

        # Creates a dict from each line of the file and adds it to the 
        # combinations list.
        foreach item $data {
            lappend listComb [General::ListToDict $item]
        }
    }

    Writer::WriteLine "<LOAD_CASE_COMBINATIONS>\n" 1

    foreach c $listComb { WriteComb $c }

    Writer::WriteLine "</LOAD_CASE_COMBINATIONS>\n" 1

    unset -nocomplain listComb
}

proc WriteComb {c} {
    variable Writer::fg; variable Writer::fi; variable Writer::fs;

    # Init variables
    set title [dict get $c title]
    set start [dict get $c start]
    set end [dict get $c end]
    set group [dict get $c group]
    set phase [dict get $c phase]
    set factors [dict get $c factors]
    set numFac [expr [llength $factors] / 2]

    Writer::WriteLine "<COMBINATION>" 2

    Writer::WriteLine "<COMBINATION_PARAMETERS>" 3
    if {$start == $end} {
        Writer::WriteLine "COMBINATION_NUMBER = $start ;" 4
    } else {
        Writer::WriteLine "COMBINATION_RANGE = \[$start-$end\] ;" 4
    }
    Writer::WriteLine "COMBINATION_TITLE = $title ;" 4
    Writer::WriteLine "COMBINATION_GROUP = $group ;" 4
    Writer::WriteLine "</COMBINATION_PARAMETERS>\n" 3

    Writer::WriteLine "<LOAD_CASE_FACTORS>" 3
    if {$::Writer::comment} {
        Writer::WriteLine "## Load case factors defining a combination" 4
        Writer::WriteLine "COUNT = [llength $numFac]; # N. of load cases in the combination\n" 4
        Writer::WriteLine "## Content of each column:" 4
        Writer::WriteLine "#  A -> Counter (or counter range)" 4
        Writer::WriteLine "#  B -> Load case number (or load case range)" 4
        Writer::WriteLine "#  C -> Load case factor" 4
        Writer::WriteLine [format "#$fs $fs $fs" A B C] 4
    } else {
        Writer::WriteLine "COUNT = [llength $numFac] ;" 4
    }

    # Print combination values
    for {set index 0; set a 1} {$index <= $numFac} {incr index 2; incr a} {
        set b [lindex $factors $index] 
        set c [lindex $factors [expr $index + 1]] 
        Writer::WriteLine [format " $fi $fi $fg ;" $a $b $c] 4
    }
    
    Writer::WriteLine "</LOAD_CASE_FACTORS>" 3

    Writer::WriteLine "</COMBINATION>\n" 2
}