@echo off
rem Run unit test
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0\AllTests.ps1'"
pause