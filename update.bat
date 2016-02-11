::
::     Utility to update Brandt projects
::     Bob Brandt <projects@brandt.ie>
::          

@ECHO OFF
SETLOCAL


:: script global variables
SET me=%~n0
SET _version=1.2
SET _base=c:\brandt
SET _location=Work
SET _gitURL=https://github.com/robertwbrandt

:: If using a Proxy Server
SET HTTP_PROXY=http://webproxy.i.opw.ie:3128/
SET HTTPS_PROXY=http://webproxy.i.opw.ie:3128/
git config --global http.proxy %HTTP_PROXY%
git config --global https.proxy %HTTPS_PROXY%
git config --global user.email "bob@brandt.ie"
git config --global user.name "Bob Brandt"


if "%1" == "/h"    CALL :usage 0
if "%1" == "/help" CALL :usage 0
if "%1" == "/v"       CALL :version 0
if "%1" == "/version" CALL :version 0

SET _cmd=
if "%1" == "/p"    SET _cmd=push
if "%1" == "/push" SET _cmd=push
if "%1" == "/pull" SET _cmd=pull
if "%1" == "/clone" SET _cmd=clone

if "%_cmd_" == "" (
	SET _cmd=pull
) ELSE (
	SHIFT
)
if "$1" == "" (

) ELSE (
	if "%_cmd%" == "pull"  CALL :pull 
	if "%_cmd%" == "push"  CALL :push
	if "%_cmd%" == "clone" CALL :clone
)

:: force execution to quit at the end of the "main" logic
EXIT /B %ERRORLEVEL%



:: Show Usage Message
:usage
ECHO "Usage: %me% [options] [project]"
ECHO "     /pull         pull/load this project"
ECHO "     /clone        clone/download this project"
ECHO " /p, /push         push/save this project"
ECHO " /h, /help         display this help and exit"
ECHO " /v, /version      output version information and exit"
EXIT %1

:: Show version and license
:version
ECHO "%me% %_version%"
ECHO "Copyright (C) 2013 Free Software Foundation, Inc."
ECHO "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>."
ECHO "This program is free software: you can redistribute it and/or modify it under"
ECHO "the terms of the GNU General Public License as published by the Free Software"
ECHO "Foundation, either version 3 of the License, or (at your option) any later"
ECHO "version."
ECHO "This program is distributed in the hope that it will be useful, but WITHOUT ANY"
ECHO "WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A"
ECHO "PARTICULAR PURPOSE.  See the GNU General Public License for more details."
ECHO.
ECHO "Written by Bob Brandt <projects@brandt.ie>."
EXIT 0

:: Pull directory from GIT repository
:pull
SET _dir=%1
for /F %%i in ("%_dir%") do SET _basedir=%%~nxi
IF EXIST %_dir%\ IF EXIST %_dir%\.git\ (
	ECHO "Pulling from %_gitURL%/%_basedir%.git"
	PUSHD "$1"
 	::git pull --all -v || git fetch --all -v
	SET RC=%ERRORLEVEL%
	REM ::git reset --hard origin/master
	POPD
	EXIT /B %RC%
)
ECHO "Either directory (%_dir%) does not exist or is not a GIT project folder!" 1>&2
EXIT /B 1



