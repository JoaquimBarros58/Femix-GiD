# #############################################################################
# combwin.tcl --
#
# Combinations window.
#
# This file implements a window for the user to define the combination data. 
# The data will be saved in a combination file (.cmb) for future usage during
# the generation of the final input file of the model.
# 
# The combination file contains a list of dictionaries.
# 
# #############################################################################

namespace eval CombWin {
    # Namespace variables declaration
    set win "";          # Window handle.
    set combinations {}; # Combination list.
    set maxLcs 350;      # Maximum number of load cases.
    set cw 10;           # Component base width.
    set editId -1;       # Index of the combination for editing.
    set keys {title group start end phase factors}; # Dictionary keys.
}

# Check if the value is an integer.
# 
# @param newval Value to be checked.
# @return 1 if the value is an integer, otherwise it returns 0.
proc CheckInteger {newval} {
   return [expr {[regexp {^[0-9]*$} $newval]}]
}

proc CheckRange {newval} {
   return [expr {[regexp {^[0-9]{0,9}(\-[0-9]{0,9})?$} $newval]}]
}

# Check if the value is a float.
# 
# @param newval Value to be checked.
# @return 1 if the value is a float, otherwise it returns 0.
proc CheckFloat {newval} {
   return [expr {[regexp {[+-]?([0-9]*[.])?[0-9]+} $newval]}]
}

# Creates the window and opens it.
proc CombWin::Open {} {
    set path [Femix::GetProjecDir]
    set name [Femix::GetModelName].cmb
    set filename [file join $path $name]

    variable win
    variable combinations
    variable cw

    if { $combinations == "" && [file exists $filename] } {
        CombWin::Read
    }

    set win .gid.combwin
    InitWindow $win [= "Combinations"] "" "" "" 1
    if { ![winfo exists $win] } return ;

    wm resizable $win 0 0

    ttk::frame $win.main -relief ridge -borderwidth 0

    # ------------
    # Inputs
    # ------------
    ttk::frame $win.main.frminp -relief ridge -borderwidth 0

    ttk::label $win.main.frminp.labelTitle -text [= "Title:"]
    ttk::entry $win.main.frminp.textTitle -width [expr 2*$cw]

    ttk::label $win.main.frminp.labelGrpName -text [= "Group Name"]
    ttk::combobox $win.main.frminp.comboGrpName -values [GiD_Groups list] -width $cw 
 
    ttk::label $win.main.frminp.labelRange -text [= "Range"]
    ttk::entry $win.main.frminp.textRange -width $cw -validate key -validatecommand "CheckRange %P"

    ttk::label $win.main.frminp.labelPhase -text [= "Phase"]
    ttk::entry $win.main.frminp.textPhase -width $cw -validate key -validatecommand "CheckInteger %P"
 
    ttk::label $win.main.frminp.labelNumLoad -text [= "No. of Load Cases"]
    # # Creates a list from 0 to num. load cases.
    set lst {}
     for {set i 1} {$i <= [SpdAux::GetNumLoadCases]} {incr i} {lappend lst $i}
    # Adds the list ot comboNumLoad.
    ttk::combobox $win.main.frminp.comboNumLoad -values $lst -width $cw
 
    grid $win.main.frminp.labelTitle   -row 0 -column 0 -padx 1 -pady 1 -sticky nw
    grid $win.main.frminp.textTitle    -row 0 -column 1 -padx 1 -pady 1 -sticky ne
    grid $win.main.frminp.labelGrpName -row 1 -column 0 -padx 1 -pady 1 -sticky nw
    grid $win.main.frminp.comboGrpName -row 1 -column 1 -padx 1 -pady 1 -sticky ne
    grid $win.main.frminp.labelRange   -row 2 -column 0 -padx 1 -pady 1 -sticky nw
    grid $win.main.frminp.textRange    -row 2 -column 1 -padx 1 -pady 1 -sticky ne
    grid $win.main.frminp.labelPhase   -row 3 -column 0 -padx 1 -pady 1 -sticky nw
    grid $win.main.frminp.textPhase    -row 3 -column 1 -padx 1 -pady 1 -sticky ne
    grid $win.main.frminp.labelNumLoad -row 4 -column 0 -padx 1 -pady 1 -sticky nw
    grid $win.main.frminp.comboNumLoad -row 4 -column 1 -padx 1 -pady 1 -sticky ne

    # ------------
    # Factors
    # ------------
    ttk::frame $win.main.frcnv
    # create canvas with scrollbars
    canvas $win.main.frcnv.c -width 180 -height 300 -yscrollcommand "$win.main.frcnv.yscroll set"
    ttk::scrollbar $win.main.frcnv.yscroll -command "$win.main.frcnv.c yview"
    pack $win.main.frcnv.yscroll -side right -fill y
    pack $win.main.frcnv.c -expand yes -fill both -side top

    # The height of the canvas frame defines the maximum scroll allowed in this component, 
    # i.e.if the height is too small it will not show many lines. Using height = 11000 is 
    # possible to scroll up to 350 lines.
    ttk::frame $win.main.frcnv.c.frWidgets -borderwidth 0 -width 180 -height 11000

    set lcs [SpdAux::GetLoadCasesNames]
    ttk::combobox $win.main.frcnv.c.frWidgets.combo1 -values $lcs -width [expr $cw / 2 + $cw]
    ttk::entry $win.main.frcnv.c.frWidgets.en1 -width [expr $cw / 2] -validate key -validatecommand "CheckFloat %P"

    grid $win.main.frcnv.c.frWidgets.combo1 -padx 2 -pady 0 -row $i -column 0
    grid $win.main.frcnv.c.frWidgets.en1    -padx 2 -pady 0 -row $i -column 1
    
    $win.main.frcnv.c create window 0 0 -anchor n -window $win.main.frcnv.c.frWidgets 

    # Determine the scrollregion
    $win.main.frcnv.c configure -scrollregion [$win.main.frcnv.c bbox all]

    # ------------
    # List
    # ------------
    tk::listbox $win.main.listComb -width [expr 3*$cw] -height 18
    foreach d $combinations {
        set title [dict get $d title]
        $win.main.listComb insert end $title
    }

    # Colorize alternating lines of the listbox
    for {set i 0} {$i<[llength $combinations]} {incr i 2} {
        $win.main.listComb itemconfigure $i -background #f0f0ff
    }

    grid $win.main.frminp   -row 0 -column 0 -padx 5 -sticky n
    grid $win.main.frcnv    -row 0 -column 1 -padx 5 -sticky n
    grid $win.main.listComb -row 0 -column 2 -padx 5 -sticky ns

    # ------------
    # Buttons 
    # ------------
    ttk::frame $win.bottom
    ttk::button $win.bottom.close -text [= "Close"] -command "destroy $win"
    ttk::button $win.bottom.new -text [= "New"] -command "CombWin::Action new" 
    ttk::button $win.bottom.apply -text [= "Apply"] -command "CombWin::Action apply" 
    ttk::button $win.bottom.edit -text [= "Edit"] -command "CombWin::Action edit" 
    ttk::button $win.bottom.remove -text [= "Remove"] -command "CombWin::Action del"
    grid $win.bottom.new $win.bottom.edit $win.bottom.remove $win.bottom.apply $win.bottom.close -padx 6

    grid $win.main   -sticky new -padx 5 -pady 5
    grid $win.bottom -sticky sew -padx 5 -pady 5

    if { $::tcl_version >= 8.5 } { grid anchor $win.bottom center }
    grid rowconfigure $win 1 -weight 1
    grid columnconfigure $win 0 -weight 1

    CombWin::SetFields

    bind $win.main.frminp.comboNumLoad <<ComboboxSelected>> {
        set numLoad [$::CombWin::win.main.frminp.comboNumLoad get]
        CombWin::SetFactorsFields $numLoad
    }
}

# Sets the input fields.
proc CombWin::SetFields {{title ""} {group "Default"} {range ""} {phase 1} {factors {}}} {
    variable win

    $win.main.frminp.textTitle delete 0 end
    $win.main.frminp.textRange delete 0 end
    $win.main.frminp.textPhase delete 0 end

    $win.main.frminp.textTitle insert 0 $title
    $win.main.frminp.textRange insert 0 $range
    $win.main.frminp.textPhase insert 0 $phase
    $win.main.frminp.comboGrpName set $group

    set size [llength $factors]
    if {$size > 0} {
        set nlc [expr [llength $factors] / 2]; # number of load cases.
    } else {
        set nlc 1
    }

    $win.main.frminp.comboNumLoad set $nlc

    CombWin::SetFactorsFields $nlc
}

# Sets the factors input fields.
proc CombWin::SetFactorsFields {numLoad} {
    set win $::CombWin::win
    variable cw

    for {set i 1} {$i <= $::CombWin::maxLcs} {incr i} {
        destroy $win.main.frcnv.c.frWidgets.combo$i
        destroy $win.main.frcnv.c.frWidgets.en$i
    }

    set lcs [SpdAux::GetLoadCasesNames]

    for {set i 1} {$i <= $numLoad} {incr i} {
        ttk::combobox $win.main.frcnv.c.frWidgets.combo$i -values $lcs -width [expr $cw / 2 + $cw]
        $win.main.frcnv.c.frWidgets.combo$i set [lindex $lcs 0]

        ttk::entry $win.main.frcnv.c.frWidgets.en$i -width [expr $cw / 2] -validate key -validatecommand "CheckFloat %P"

        grid $win.main.frcnv.c.frWidgets.combo$i -row $i -column 0 -padx 2 -pady 0 
        grid $win.main.frcnv.c.frWidgets.en$i    -row $i -column 1 -padx 2 -pady 0 
    }
}

# Buttons actions.
# 
# @param cmd The command to be executed. 
proc CombWin::Action {cmd} {
    if {![Femix::IsModelSaved]} { return }

    variable win

    if {$cmd == "new"} {
        CombWin::SetFields
    } elseif {$cmd == "edit"} {
        CombWin::Edit
    } elseif {$cmd == "apply"} {
        if {[CombWin::Validate]} { return }

        if {$::CombWin::editId >= 0} {
            CombWin::Update
        } else {
            CombWin::Add
        }

        set $::CombWin::editId -1

        CombWin::Save
    } elseif {$cmd == "del"} {
        CombWin::Remove
        CombWin::Save 
    }

    if {$cmd == "apply"} {
        $win.bottom.apply configure -state disabled
    } else {
        $win.bottom.apply configure -state normal
    }
}

# Create a new combination dictionary. The dictionary is created using the 
# current values from the dialogue.
# 
# @return A combination dictionary.
proc CombWin::CreateComb {} {
    variable win
    variable keys

    # Getting the input values.
    set values {}
    set title [$win.main.frminp.textTitle get]
    lappend values "$title"
    lappend values [$win.main.frminp.comboGrpName get]


    set lr [split [$win.main.frminp.textRange get] -]
    if {[llength $lr] == 2} {
        lappend values [lindex $lr 0] [lindex $lr 1]
    } else {
        lappend values [lindex $lr 0] [lindex $lr 0]
    }

    lappend values [$win.main.frminp.textPhase get]

    set numLoad [$::CombWin::win.main.frminp.comboNumLoad get]
    set comb [dict create]

    # Creates the dict using the keys: title group start end phase factors
    for {set i 0} {$i < [llength $keys]} {incr i} {
        set key [lindex $keys $i]

        if {$key == "factors" } {
            set val {}
            for {set j 1} {$j <= $numLoad} {incr j} {
                set id [SpdAux::GetLoadCaseId [$win.main.frcnv.c.frWidgets.combo$j get]]
                lappend val [expr $id + 1]
                lappend val [$win.main.frcnv.c.frWidgets.en$j  get]
            }
        } else {
            set val [lindex $values $i]
        }

        dict set comb $key $val
    }

    return $comb
}

proc CombWin::Remove {} {
    variable win
    variable combinations

    set id [$win.main.listComb curselection] 
    if { $id == "" } { return }

    set combinations [lreplace $combinations $id $id]

    $win.main.listComb delete $id
}

# Gets the values from the input fields and inserts into the combination list.
proc CombWin::Add {} {
    variable win
    variable combinations

    set comb [CombWin::CreateComb] 
    lappend combinations $comb
    $win.main.listComb insert end [dict get $comb title]
}

# Edit the combinations parameters. It gets the values from the dictionary and
# sets the inputs fields. 
proc CombWin::Edit {} {
    variable win 
    variable combinations 
    variable editId

    set selectedCombIndex [$win.main.listComb curselection] 

    if { $selectedCombIndex == "" } { return }

    set editId $selectedCombIndex

    set comb [lindex $combinations $editId]
    set title [dict get $comb title]
    set phase [dict get $comb phase]
    set group [dict get $comb group]
    set factors [dict get $comb factors] 
    set start [dict get $comb start] 
    set end [dict get $comb end] 

    if {$start == $end} {
        set range $start
    } else {
        set range "$start-$end"
    }

    CombWin::SetFields $title $group $range $phase $factors
    set nlc [expr [llength $factors] / 2]; # number of load cases.

    set lcs [SpdAux::GetLoadCasesNames]
    set j 0
    for {set i 1} {$i <= $nlc} {incr i} {
        set id [expr [lindex $factors $j] - 1]
        $win.main.frcnv.c.frWidgets.combo$i set [lindex $lcs $id]
        incr j
        $win.main.frcnv.c.frWidgets.en$i delete 0 end
        $win.main.frcnv.c.frWidgets.en$i insert 0 [lindex $factors $j]
        incr j
    }
}

proc CombWin::Update {} {
    variable editId
    variable combinations
    set comb [CombWin::CreateComb] 
    set combinations [lreplace $combinations $editId $editId $comb]
}

# Reads the combinations data from file and stores in the combinations list.
proc CombWin::Read {} {
    set path [Femix::GetProjecDir]
    set name [Femix::GetModelName].cmb
    set filename [file join $path $name]

    if {![file exists $filename]} { 
        ErrorWin "Combination file not found!"
        return 
    }

    # Reads the file.
    set file [open $filename "r"]
    set data [read $file]
    close $file

    # Creates a dict from each line of the file and adds it to the 
    # combinations list.
    foreach item $data {
        lappend CombWin::combinations [General::ListToDict $item]
    }
}

# Saves the data to file.
proc CombWin::Save {} {
    set path [Femix::GetProjecDir]
    set name [Femix::GetModelName].cmb
    set file [open [file join $path $name] "w"]

    foreach c $::CombWin::combinations { puts $file "{$c}" }
    
    close $file
}

proc CombWin::Validate {} {
    set win $::CombWin::win

    if {[$win.main.frminp.textTitle get] == ""} {
        ErrorWin "Please define a title"
        return 1
    }

    if {[$win.main.frminp.textRange get] == ""} {
        ErrorWin "Please define the range.\nIt can be a single value e.g., 1 or an interval e.g., 1-10"
        return 1
    }
    

    return 0
}