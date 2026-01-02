@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0devkit.ps1' %*"
