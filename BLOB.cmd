@echo off
rem BLOB OPTIMIZER launcher for cmd.exe / double-click.
rem Runs BLOB.ps1 from this folder; it asks Windows for administrator rights (UAC).
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0BLOB.ps1" %*
