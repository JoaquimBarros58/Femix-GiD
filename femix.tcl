# #############################################################################
# Femix.tcl --
#
# GiD-FEMIX problem type.
#
# Main TCL file
# Contains the GiD initialization routines and Femix namespace.
# #############################################################################

namespace eval Femix {
    variable femixVars; # Femix data.
}

# Minimum GiD Version is 14
if {[GidUtils::VersionCmp "14.0.1"] >= 0 } {
    if {[GidUtils::VersionCmp "14.1.1"] >= 0 } {
        # GiD Developer versions
        proc GiD_Event_InitProblemtype {dir} {
            Femix::Event_InitProblemtype $dir
        }
    } {
        # GiD Official versions
        proc InitGIDProject {dir} {
            Femix::Event_InitProblemtype $dir
        }
    }
} {
    # GiD versions previous to 14 are no longer allowed
    # As we dont register the event InitProblemtype, the rest of events are also unregistered
    # So no chance to open anything in GiD 13.x or earlier
    WarnWin "The minimum GiD Version for Femix is 14 or later \nUpdate at gidhome.com"
}

# Called when the problem type is loaded.
#
# @param dir femix.gid directory.
proc Femix::Event_InitProblemtype {dir} {
    variable femixVars

    # Init Femix problemtype global vars with default values.
    Femix::InitGlobalVariables $dir
    # Load all common tcl files (not the app ones)
    Femix::LoadCommonScripts
    # GiD Versions earlier than recommended get a message
    Femix::WarnAboutVersion
    # Register the rest of events
    Femix::Events
    # Customize GiD menus to add the Femix entry
    Femix::ChangeMenus
    # Open data tree
    GidUtils::OpenWindow CUSTOMLIB

    # Creates a default group.
    if {[GiD_Groups exists Default] == 0} {
        GiD_Groups create $femixVars(Group)
    }
}

# Init GiD events.
proc Femix::Events {} {
    variable femixVars

    # Recommended GiD Version is the latest developer always
    if {[GidUtils::VersionCmp "14.1.4d"] < 0 } {
        set dir [file dirname [info script]]
        # uplevel #0 [list source [file join $femixVars(Path) scripts DeprecatedEvents.tcl]]
        #Event::ModifyPreferencesWindowOld
    } {
        Femix::RegisterGiDEvents
    }
}

# Init femix private variables.
#
# @param: femix.gid directory.
proc Femix::InitGlobalVariables {dir} {
    variable femixVars

    # clean and start private variables array
    unset -nocomplain femixVars
    set femixVars(Path) $dir ; # Stores the problem type directory.
    # Set mesh renumbering method
    set femixVars(RenumberMethod) [GiD_Info variables RenumberMethod]
    # User environment
    set femixVars(DevMode) "release" ; #can be dev or release
    # Default group
    set femixVars(Group) Default ; 
    # Variables from the problemtype definition (femix.xml)
    array set femixVars [ReadProblemtypeXml [file join $femixVars(Path) femix.xml] Infoproblemtype {Name Version CheckMinimumGiDVersion}]
    
    # Load the Femix problemtype global and user preferences
    Femix::LoadPreferences
}

# Load all tcl scripts.
proc Femix::LoadCommonScripts {} {
    variable femixVars
    set root $femixVars(Path)

    # Append to auto_path only folders that must include tcl packages (loaded on demand with package require mechanism)
    if { [lsearch -exact $::auto_path [file join $root scripts]] == -1 } {
        lappend ::auto_path [file join $root scripts]
    }  
    # Femix scripts
    set dir [file join $root scripts]
    foreach script [glob [file join $dir femix *.tcl]] {
        uplevel #0 [list source $script]
    }
    # Import scripts
    foreach script [glob [file join $dir import *.tcl]] {
        uplevel #0 [list source $script]
    }
    # Export scripts
    foreach script [glob [file join $dir export *.tcl]] {
        uplevel #0 [list source $script]
    }
    # Spd scripts
    set dir [file join $root scripts]
    foreach script [glob [file join $dir spd *.tcl]] {
        uplevel #0 [list source $script]
    }
    # Utilities scripts
    set dir [file join $root scripts]
    foreach script [glob [file join $dir utilities *.tcl]] {
        uplevel #0 [list source $script]
    }
    # Writer scripts
    set dir [file join $root scripts]
    foreach script [glob [file join $dir writer *.tcl]] {
        uplevel #0 [list source $script]
    }
}

# Register GiD events. A 'Event procedure' is a Tcl procedure that is invoked
# from GiD when doing some actions.
proc Femix::RegisterGiDEvents {} {
    # Unregister previous events
    GiD_UnRegisterEvents PROBLEMTYPE Femix
    # Run
    GiD_RegisterEvent GiD_Event_BeforeRunCalculation Event::BeforeRunCalculation PROBLEMTYPE Femix
    GiD_RegisterEvent GiD_Event_AfterRunCalculation Event::AfterRunCalculation PROBLEMTYPE Femix
    # Write
    GiD_RegisterEvent GiD_Event_BeforeWriteCalculationFile Event::BeforeWriteCalculationFile PROBLEMTYPE Femix
    GiD_RegisterEvent GiD_Event_AfterWriteCalculationFile Event::AfterWriteCalculationFile PROBLEMTYPE Femix
    # End
    GiD_RegisterEvent GiD_Event_EndProblemtype Event::EndProblemtype PROBLEMTYPE Femix
    # Preferences window
    GiD_RegisterPluginPreferencesProc Event::ModifyPreferencesWindow
    CreateWidgetsFromXml::ClearCachePreferences
}

# Saves users preferences to file. 
proc Femix::SavePreferences { } {
    #do not save preferences starting with flag gid.exe -c (that specify read only an alternative file)
    if { [GiD_Set SaveGidDefaults] } {
        variable femixVars
        set varsToSave [list DevMode RenumberMethod]
        set preferences [dict create]
        foreach v $varsToSave {
            if {[info exists femixVars($v)]} {
                dict set preferences $v $femixVars($v)
            }
        }
        
        if {[llength [dict keys $preferences]] > 0} {
            set fp [open [Femix::GetPrefsFilePath] w]
            if {[catch {set data [puts $fp [Femix::tcl2json $preferences]]} ]} {W "Problems saving user prefecences"; W $data}
            close $fp
        }
    }
}

# Loads users preferences from file.
proc Femix::LoadPreferences { } {
    variable femixVars

    # Init variables
    set data ""
    
    catch {
        # Try to open the preferences file
        set fp [open [Femix::GetPrefsFilePath] r]
        # Read the preferences
        set data [read $fp]
        # Close the file
        close $fp
    }
    # Preferences are written in json format
    foreach {k v} [Femix::json2dict $data] {
        # Foreach pair key value, restore it
        set femixVars($k) $v
    }
}


package require json::write

proc Femix::json2dict {JSONtext} {
    string range [
        string trim [
            string trimleft [
                string map {\t {} \n {} \r {} , { } : { } \[ \{ \] \}} $JSONtext
                ] {\uFEFF}
            ]
        ] 1 end-1
}

proc Femix::tcl2json { value } {
    # Guess the type of the value; deep *UNSUPPORTED* magic!
    # display the representation of a Tcl_Obj for debugging purposes. Do not base the behavior of any command on the results of this one; it does not conform to Tcl's value semantics!
    regexp {^value is a (.*?) with a refcount} [::tcl::unsupported::representation $value] -> type
    if {$value eq ""} {return [json::write array {*}[lmap v $value {tcl2json $v}]]}
    switch $type {
        string {
            if {$value eq "false"} {return [expr "false"]}
            if {$value eq "true"} {return [expr "true"]}
            if {$value eq "null"} {return null}
            if {$value eq "dictnull"} {return {{}}}
            return [json::write string $value]
        }
        dict {
            return [json::write object {*}[
                    dict map {k v} $value {tcl2json $v}]]
        }
        list {
            return [json::write array {*}[lmap v $value {tcl2json $v}]]
        }
        int - double {
            return [expr {$value}]
        }
        booleanString {
            if {[isBooleanFalse $value]} {return [expr "false"]}
            if {[isBooleanTrue $value]} {return [expr "true"]}
            return [json::write string $value]
            #return [expr {$value ? "true" : "false"}]
        }
        default {
            # Some other type; do some guessing...
            if {$value eq "null"} {
                # Tcl has *no* null value at all; empty strings are semantically
                # different and absent variables aren't values. So cheat!
                return $value
            } elseif {[string is integer -strict $value]} {
                return [expr {$value}]
            } elseif {[string is double -strict $value]} {
                return [expr {$value}]
            } elseif {[string is boolean -strict $value]} {
                return [expr {$value ? "true" : "false"}]
            }
            return [json::write string $value]
        }
    }
}