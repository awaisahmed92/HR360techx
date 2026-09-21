@echo off
REM HR360 schema helper for local XAMPP.
REM
REM   db check              show anything missing in the local DB (changes nothing)
REM   db apply              apply every pending/changed database\*.sql file
REM   db capture <name>      turn hand-made local DB changes into a new SQL file
REM   db new <name>          scaffold an empty numbered SQL file
REM   db force               re-apply every SQL file
REM
setlocal
cd /d "%~dp0backend"

if not defined DB_HOST set DB_HOST=127.0.0.1
if not defined DB_PORT set DB_PORT=3306
if not defined DB_DATABASE set DB_DATABASE=hr360_demo
if not defined DB_USERNAME set DB_USERNAME=root
if not defined DB_MASTER_DATABASE set DB_MASTER_DATABASE=hr360_master

if /i "%1"=="check"   goto check
if /i "%1"=="apply"   goto apply
if /i "%1"=="force"   goto force
if /i "%1"=="capture" goto capture
if /i "%1"=="new"     goto new
goto usage

:check
php bootstrap-hr.php --check
exit /b %ERRORLEVEL%

:apply
php bootstrap-hr.php
exit /b %ERRORLEVEL%

:force
php bootstrap-hr.php --force
exit /b %ERRORLEVEL%

:capture
if "%2"=="" (
  echo Usage: db capture ^<name^>    e.g. db capture employee_photos
  exit /b 1
)
php bootstrap-hr.php --capture=%2
exit /b %ERRORLEVEL%

:new
if "%2"=="" (
  echo Usage: db new ^<name^>        e.g. db new employee_photos
  exit /b 1
)
php bootstrap-hr.php --new=%2
exit /b %ERRORLEVEL%

:usage
echo HR360 schema helper  ^(database: %DB_DATABASE%^)
echo.
echo   db check              list missing tables/columns, change nothing
echo   db apply              apply pending or changed database\*.sql files
echo   db capture ^<name^>     write a SQL file for changes you made by hand
echo   db new ^<name^>         scaffold an empty numbered SQL file
echo   db force              re-apply every SQL file
exit /b 1
