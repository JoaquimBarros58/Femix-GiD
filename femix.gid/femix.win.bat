rem @ECHO OFF
rem Identification for arguments
rem basename                          = %1
rem Project directory                 = %2
rem Problem directory                 = %3
 
rem OutputFile: "%2\%1.log"
rem ErrorFile: "%2\%1.err"
 
rem Deleteting old files...
del "%2\%1.log"
del "%2\%1.err"

rem Creates a new input file with femix extension.
copy %1.dat %1_gl.dat

rem Running femix...
%3\bin\prefemix.exe %2\%1 > "%2\%1.log"
%3\bin\femix.exe %2\%1 >> "%2\%1.log"

rem Run posfemix via this bat file.
If exist pos.bat call pos.bat