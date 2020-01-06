 @echo off

rem Covert ZX snapshot to AGD file
 copy ..\snapshots\%1.sna convert
 cd convert
 convert %1
 copy %1.agd ..\
 del %1.sna
 cd ..
