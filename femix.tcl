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
# Arguments:
# ----------
# dir: femix.gid directory.
#
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
# 
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
# Arguments:
# ----------
# dir: femix.gid directory.
# 
proc Femix::InitGlobalVariables {dir} {
    variable femixVars

    # clean and start private variables array
    unset -nocomplain femixVars
    set femixVars(Path) $dir ; # Stores the problem type directory.
    # Set mesh renumbering method
    set femixVars(RenumberMethod) [GiD_Info variables RenumberMethod]
    # User environment
    set femixVars(DevMode) "dev" ; #can be dev or release
    # Default group
    set femixVars(Group) Default ; 
    # Variables from the problemtype definition (femix.xml)
    array set femixVars [ReadProblemtypeXml [file join $femixVars(Path) femix.xml] Infoproblemtype {Name Version CheckMinimumGiDVersion}]
}

# Load all tcl scripts.
# 
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
# 
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