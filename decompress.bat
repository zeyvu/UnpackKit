@ECHO OFF
REM Extracts .\Output\fg-01.arc into .\Extracted (FreeArc + lolz).
REM Uses the DECOMPRESSOR build: tools\unpack\arc.exe
REM This is the same command the installer runs (see RunArc in setup.iss).
cd /d "%~dp0tools\unpack"

arc.exe x -o+ -dp"%~dp0Extracted" "%~dp0Output\fg-01.arc"

PAUSE
