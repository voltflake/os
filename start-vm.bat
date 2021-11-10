@echo off
call build.bat
if %errorlevel% neq 0 goto buildfail
VBoxManage controlvm "MyVM" poweroff
if %errorlevel% equ 0 (
    echo waiting for vm to shutdown...
    ping -n 3 127.0.0.1>nul
)
start /b "" "C:\Program Files\Oracle\VirtualBox\VirtualBoxVM.exe" --startvm "{491f34da-b341-44cf-8301-f5145605c061}"
cls
echo Build completed succeesfuly.
echo Starting Virtual Machine...
goto :EOF

:buildfail
exit /b %errorlevel%