@echo off
REM Create HR360 master + tenant databases (XAMPP MySQL)
set MYSQL=D:\xampp\mysql\bin\mysql.exe

echo Creating hr360_master...
"%MYSQL%" -u root < "%~dp001_master.sql"
if errorlevel 1 goto fail

echo Creating hr360_demo tenant...
"%MYSQL%" -u root < "%~dp002_tenant_demo.sql"
if errorlevel 1 goto fail

echo Done.
echo.
echo Login in Flutter (Demo mode OFF):
echo   Organization: demo   OR   scfnew
echo   Username: admin
echo   Password: admin123
echo.
echo Staff user: staff / staff123
goto end

:fail
echo FAILED - is MySQL running in XAMPP?
exit /b 1

:end
