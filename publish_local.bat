@echo off
setLocal EnableDelayedExpansion


REM -------------BEGIN: CHANGE THESE -----------------
SET PATH_TRC=C:\TRC\git
SET PATH_TEMP=C:\TRC\temp

SET PATH_WWW_ROOT=C:\TRC
SET PUBLISHFOLDER=WWW
REM -------------END: CHANGE THESE -----------------


REM ------------ VERIFY VARIABLES ---------------
VERIFY OTHER 2>nul
SETLOCAL ENABLEEXTENSIONS
IF ERRORLEVEL 1 ECHO Unable to enable extensions
IF NOT DEFINED PATH_TRC (goto VARNOTDEF)
IF NOT DEFINED PATH_TEMP (goto VARNOTDEF)
IF NOT DEFINED PATH_WWW_ROOT (goto VARNOTDEF)
IF NOT DEFINED PUBLISHFOLDER (goto VARNOTDEF)
ENDLOCAL
GOTO GOOD
REM ------------ VERIFY VARIABLES ---------------

:VARNOTDEF
ECHO ONE OF THE VARIABLES IS NOT DEFINED PROPERLY.
EXIT /b 1

:GOOD

SET CURRENT_PATH=!CD!
SET PATH_WWW=!PATH_WWW_ROOT!\!PUBLISHFOLDER!

ECHO ************************
ECHO *** START DEPLOYMENT ***
ECHO ************************


ECHO.
ECHO *** 1) OCTOPACKING !PATH_TRC!\trc.web\trc.web.csproj ***
ECHO.
if not exist "!PATH_TRC!\obj\NUL" mkdir "!PATH_TRC!\obj"
if not exist "!PATH_TRC!\Environment Specific Configs\NUL" mkdir "!PATH_TRC!\Environment Specific Configs"
if not exist "!PATH_TRC!\Environment Specific Configs\TRC.Web" mkdir "!PATH_TRC!\Environment Specific Configs\TRC.Web"
"!ProgramFiles(x86)!\MSBuild\14.0\Bin\MSBuild.exe" !PATH_TRC!\trc.web\trc.web.csproj /t:Build /v:m /p:Configuration=Release /p:RunOctoPack=true /p:OctoPackEnforceAddingFiles=true "/p:OctoPackNuGetProperties=prefix="



ECHO.
ECHO *** 2) CLEAR TEMP FOLDER '!PATH_TEMP!' ***
ECHO.
if not exist !PATH_TEMP!\NUL mkdir !PATH_TEMP!
del /q "!PATH_TEMP!\*"
FOR /D %%p IN ("!PATH_TEMP!\*.*") DO rmdir "%%p" /s /q



ECHO.
ECHO *** 3) UNPACKING TRC TO '!PATH_TRC!\trc.web\obj\octopacked\' ***
ECHO.
nuget install TRC.Web -Source !PATH_TRC!\trc.web\obj\octopacked\ -OutputDirectory !PATH_TEMP!


REM ---------- clear publish folder ----------
if not exist !PATH_WWW!\NUL mkdir !PATH_WWW!
del /q "!PATH_WWW!\*"
FOR /D %%p IN ("!PATH_WWW!\*.*") DO rmdir "%%p" /s /q



REM ---------- move temp to publish folder ----------
REM loop needed because we do not have a handle on the unpacked folder generated in #3
REM this should always only include one folder since we empty the temp directory in #2
CD /D !PATH_TEMP!
FOR /D %%a IN (*) DO (
	REN %%a !PUBLISHFOLDER!
	ECHO.
	ECHO *** "4) ROBOCOPY !PATH_TEMP!\!PUBLISHFOLDER! TO !PATH_WWW!" ***
	ECHO.
	robocopy !PUBLISHFOLDER! !PATH_WWW! /E /IS /MOVE /PURGE /NFL /NDL /NJH /NC /NS /NP
)

if not exist "!PATH_WWW!\obj\NUL" mkdir "!PATH_WWW!\obj"
if not exist "!PATH_WWW!\Environment Specific Configs\NUL" mkdir "!PATH_WWW!\Environment Specific Configs"

cd !CURRENT_PATH!


ECHO **********************
ECHO *** END DEPLOYMENT ***
ECHO **********************

pause