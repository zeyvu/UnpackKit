@ECHO OFF
REM Compresses the contents of .\Game into .\Output\fg-01.arc (FreeArc + lolz).
REM Uses the COMPRESSOR build: tools\arc.exe
cd /d "%~dp0"

IF NOT EXIST ".\Output" MKDIR ".\Output"

SET options=-r --dirs -s; -ep1 -di=acmwfdte# -i1 -lc- -w.\

.\tools\arc.exe a %options% -m=lolz:mtt0:mt3:d64m ".\Output\fg-01.arc" ".\Game\*"

PAUSE
