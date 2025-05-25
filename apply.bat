@echo off

set "adobe_hosts_file=%cd%\hosts"
set "backup_hosts_file=%cd%\hosts.bak"
set "sys_hosts_file=%windir%\System32\drivers\etc\hosts"

echo.

:: Check for admin privilages
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo You're not running as administrator. Please re-run this script as Administrator or a terminal with elevated privilages.
  goto term_error
)

if not exist %backup_hosts_file% (
  echo Created hosts.bak
  xcopy /s %sys_hosts_file% %backup_hosts_file%
  goto term_ok
)

:add_hosts_record


:term_error
echo.
exit /b 1

:term_ok
echo.
exit