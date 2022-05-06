# GiD-FEMIX

FEMIX is a FEM-based computer program for advanced structural analysis.

## Instruction for developers

The problem type is organised in folders and files. Each file has a brief
description explaining its purpose, we also documented each procedure and variables in each file. The structure of the source code is:

- bin: Folder containing femix executables.
- images: Folder containing the icons and images files.
- scripts: Folder containing the Tcl scripts. Each namespace is saved in its respective folder
  - export: Procedures to export the model to other formats.
  - femix: Menus, toolbars, and all procedures related to femix namespace.
  - import: Procedures used to convert the results from femix to GiD format.
  - spd: Procedures used to access and manage the spd tree.
  - utilities: Utility procedures.
  - writer: Procedures to write the gid data to femix input file.
- xml: Folder containing the xml files describing the tree structure.
- femix_default.spd Main configuration file of the data tree, XML-based.
- femix.bas Information for the data input file. It is an empty file.
- femix.tcl Main TCL file, initialization.
- femix.cnd Conditions definition. It should not be modified by the user.

### How to implement a new material

1. Create a new file in xml\materials folder named nlmmXXX.xml, where XXX is
   the number of the new NLMM material.
1. Add the new material to the material container in the femix_default.spd
   file.
1. Create a new file in the writer folder named writerMatXXX.tcl, where XXX is
   the number of the NLMM material.
1. Create the material variable and the call to the writerMatXXX.tcl in the
   procedure Materials in the file writerMat.tcl.
