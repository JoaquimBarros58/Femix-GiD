###############################################################################
# menus.tcl --
#
# GiD-FEMIX problem type.
#
# This file contains the Femix menu definition.
# The menu’s name should follow GiD standard. See GiD menus for examples on
# how you should name new menus.
# 
###############################################################################

# Adds the Femix menu option to the main menu.
proc Femix::ChangeMenus {} {
    variable femixVars

    # ---------------
    # Femix menu.
    # ---------------
    set found [GiDMenu::_FindIndex "Femix" PREPOST]
    if {$found > 0} {GiDMenu::Delete "Femix" PREPOST}
    GiDMenu::Create "Femix" PREPOST
    set pos -1

    # Open menu
    GiDMenu::InsertOption "Femix" [list "Open..." ] [incr pos] PREPOST [list] "" "" replace =
    # Separator
    GiDMenu::InsertOption "Femix" [list "---"] [incr pos] PREPOST "" "" "" replace = 
    # Femix menu
    GiDMenu::InsertOption "Femix" [list "Prefemix..."] [incr pos] PREPOST [list Event::RunExec "prefemix"] "" "" replace =
    GiDMenu::InsertOption "Femix" [list "Femix..."] [incr pos] PREPOST [list Event::RunExec "femix"] "" "" replace =
    GiDMenu::InsertOption "Femix" [list "Posfemix..."] [incr pos] PREPOST [list Event::RunExec "posfemix"] "" "" replace =
    # Separator
    GiDMenu::InsertOption "Femix" [list "---"] [incr pos] PREPOST "" "" "" replace = 
    # Tools menu
    GiDMenu::InsertOption "Femix" [list "Tools"] [incr pos] PREPOST "" "" "" insert _
    GiDMenu::InsertOption "Femix" [list "Tools" "Write input file"] 0 PREPOST [list Event::WriteInputFile] "" "" replace =
    GiDMenu::InsertOption "Femix" [list "Tools" "Clean project"] 1 PREPOST [list Event::CleanProject] "" "" replace =   
    GiDMenu::InsertOption "Femix" [list "Tools" "Export mesh only"] 2 PREPOST [list Event::ExportMesh] "" "" replace =   
    # Separator
    GiDMenu::InsertOption "Femix" [list "---"] [incr pos] PREPOST "" "" "" replace =
    # About menu
    GiDMenu::InsertOption "Femix" [list "About Femix" ] [incr pos] PREPOST [list Event::About] "" "" replace =
    if {$::Femix::femixVars(DevMode) == "dev"} {
        GiDMenu::InsertOption "Femix" [list "---"] [incr pos] PREPOST "" "" "" replace =
        GiDMenu::InsertOption "Femix" [list "Debug" ] [incr pos] PREPOST [list Event::Debug] "" "" replace =
    }
    
    # -------------------------------
    # Remove submenus from Data menu.
    # -------------------------------
    GidChangeDataLabel "Data units" ""
    GidChangeDataLabel "Interval" ""
    GidChangeDataLabel "Conditions" ""
    GidChangeDataLabel "Materials" ""
    GidChangeDataLabel "Interval Data" ""
    GidChangeDataLabel "Problem Data" ""
    GidChangeDataLabel "Local axes" ""
    # Add new options to data menu.
    GidAddUserDataOptions "---" ""
    GidAddUserDataOptions "Combinations" "CombWin::Open"

    # Adds the FEMIX website to Help menu.
    GiDMenu::InsertOption "Help" [list ---] end PREPOST {} "" "" insertafter
    GiDMenu::InsertOption "Help" [list [_ "Visit %s web..." FEMIX]] end PREPOST [list VisitWeb "http://gidfemix.civil.uminho.pt"] "" "" insertafter
    
    GiDMenu::UpdateMenus
}