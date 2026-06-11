@echo off
setlocal

:: Reverts the Adobe blocklist from the system hosts file on Windows.
::
:: Removes the block between the marker comments that apply.bat added,
:: leaving the rest of the hosts file untouched.
::
:: Usage: run as Administrator

set "backup_hosts_file=%~dp0hosts.bak"
set "sys_hosts_file=%windir%\System32\drivers\etc\hosts"
:: Overridable so the scripts can be tested without touching the real hosts file
if defined ADOBE_BLOCKLIST_HOSTS_FILE set "sys_hosts_file=%ADOBE_BLOCKLIST_HOSTS_FILE%"

set "start_marker=## ADOBE_BLOCKLIST_START ##"
set "end_marker=## ADOBE_BLOCKLIST_END ##"

echo.

findstr /c:"%start_marker%" "%sys_hosts_file%" >nul 2>&1
if errorlevel 1 (
  echo No blocklist markers found in %sys_hosts_file%, nothing to revert.
  if exist "%backup_hosts_file%" echo If you applied the records manually, you can restore the backup from hosts.bak as Administrator.
  exit /b 1
)

:: Check for admin privileges, skipped when targeting a custom hosts file
if defined ADOBE_BLOCKLIST_HOSTS_FILE goto remove_block

net session >nul 2>&1
if errorlevel 1 (
  echo You're not running as administrator. Please re-run this script as Administrator or a terminal with elevated privileges.
  exit /b 1
)

:remove_block
powershell -NoProfile -Command "$lines = Get-Content '%sys_hosts_file%'; $in = $false; $out = foreach ($l in $lines) { if ($l -eq '%start_marker%') { $in = $true } elseif ($l -eq '%end_marker%') { $in = $false } elseif (-not $in) { $l } }; Set-Content -Path '%sys_hosts_file%' -Value $out"
if errorlevel 1 (
  echo Failed to update %sys_hosts_file%
  exit /b 1
)

:: Skip the DNS flush when targeting a test file rather than the real hosts file
if not defined ADOBE_BLOCKLIST_HOSTS_FILE (
  ipconfig /flushdns >nul
  echo Flushed DNS cache
)

echo Reverted %sys_hosts_file%
exit /b 0
