@echo off
rem Pack d'installation EVINTERTECH : installe le certificat EVINTERTECH sur ce PC,
rem puis la dernière version du logiciel publiée sur www.evintertech.com/logiciels
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer.ps1"
pause
