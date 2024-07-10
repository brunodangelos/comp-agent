@echo off

set "taskname=Monitoramento Veeam"
set "ps1path=C:\compmon\scripts\VeeamPS.ps1"

schtasks /Create /SC MINUTE /MO 5 /TN "%taskname%" /TR "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%ps1path%\"" /RU SYSTEM /RL HIGHEST /NP
