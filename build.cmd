@echo off
cd tools
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '.\build.ps1'"
exit /B %errorlevel%
