@echo off

set "adobe_hosts_file=%cd%\hosts"
set "backup_hosts_file=%cd%\hosts.bak"
set "sys_hosts_file=%windir%\System32\drivers\etc\hosts"

echo.

if not exist %backup_hosts_file% (
  echo No hosts backup file
  goto term_error
)

:: Check for admin privilages
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo You're not running as administrator. Please re-run this script as Administrator or a terminal with elevated privilages.
  goto term_error
)

:term_error
echo.
exit /b 1