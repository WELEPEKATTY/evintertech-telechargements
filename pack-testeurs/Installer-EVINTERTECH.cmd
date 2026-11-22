@echo off
rem Pack testeurs EVINTERTECH : installe le certificat EVINTERTECH sur ce PC, puis propose
rem d'installer la dernière version de chaque logiciel Windows publié sur www.evintertech.com/logiciels
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer-evintertech.ps1"
pause
