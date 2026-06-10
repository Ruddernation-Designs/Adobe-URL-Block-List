@echo off
setlocal

:: Applies the Adobe blocklist to the system hosts file on Windows.
::
:: The records are wrapped in marker comments so re-running this script
:: replaces the previous block instead of appending duplicates, and so
:: revert.bat can remove them cleanly.
::
:: Usage: run as Administrator

set "adobe_hosts_file=%~dp0hosts"
set "backup_hosts_file=%~dp0hosts.bak"
set "sys_hosts_file=%windir%\System32\drivers\etc\hosts"
:: Overridable so the scripts can be tested without touching the real hosts file
if defined ADOBE_BLOCKLIST_HOSTS_FILE set "sys_hosts_file=%ADOBE_BLOCKLIST_HOSTS_FILE%"

set "start_marker=## ADOBE_BLOCKLIST_START ##"
set "end_marker=## ADOBE_BLOCKLIST_END ##"

echo.

if not exist "%adobe_hosts_file%" (
  echo Blocklist file not found at %adobe_hosts_file%
  exit /b 1
)

:: Check for admin privileges, skipped when targeting a custom hosts file
if defined ADOBE_BLOCKLIST_HOSTS_FILE goto create_backup

net session >nul 2>&1
if errorlevel 1 (
  echo You're not running as administrator. Please re-run this script as Administrator or a terminal with elevated privileges.
  exit /b 1
)

:create_backup
if not exist "%backup_hosts_file%" (
  copy /y "%sys_hosts_file%" "%backup_hosts_file%" >nul
  echo Created hosts.bak
)

:: Remove a previously applied block so re-running never duplicates records
findstr /c:"%start_marker%" "%sys_hosts_file%" >nul 2>&1
if errorlevel 1 goto append_block

powershell -NoProfile -Command "$lines = Get-Content '%sys_hosts_file%'; $in = $false; $out = foreach ($l in $lines) { if ($l -eq '%start_marker%') { $in = $true } elseif ($l -eq '%end_marker%') { $in = $false } elseif (-not $in) { $l } }; Set-Content -Path '%sys_hosts_file%' -Value $out"
if errorlevel 1 (
  echo Failed to update %sys_hosts_file%
  exit /b 1
)
echo Removed previously applied records

:append_block
powershell -NoProfile -Command "$records = Get-Content '%adobe_hosts_file%' | Where-Object { $_ -notmatch '^\s*(#|$)' }; Add-Content -Path '%sys_hosts_file%' -Value (@('%start_marker%') + $records + '%end_marker%')"
if errorlevel 1 (
  echo Failed to write to %sys_hosts_file%
  exit /b 1
)

:: Skip the DNS flush when targeting a test file rather than the real hosts file
if not defined ADOBE_BLOCKLIST_HOSTS_FILE (
  ipconfig /flushdns >nul
  echo Flushed DNS cache
)

echo Applied records to %sys_hosts_file%
exit /b 0
