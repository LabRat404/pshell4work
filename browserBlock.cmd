@echo off

:: Disable Scripting
::reg add "HKCU\Software\Policies\Microsoft\Windows\System" /v "DisableCMD" /t REG_DWORD /d "1" /f
reg add "HKCU\Software\Microsoft\Windows Script Host\Settings" /v "Enabled" /t REG_DWORD /d "0" /f

:: Block Websites
reg add "HKEY_CURRENT_USER\Software\Policies\BraveSoftware\Brave\URLBlocklist" /v "1" /t REG_SZ /d "symmetry.host" /f
reg add "HKEY_CURRENT_USER\Software\Policies\BraveSoftware\Brave\URLBlocklist" /v "2" /t REG_SZ /d "options-it.com" /f
reg add "HKEY_CURRENT_USER\Software\Policies\BraveSoftware\Edge\URLBlocklist" /v "1" /t REG_SZ /d "symmetry.host" /f
reg add "HKEY_CURRENT_USER\Software\Policies\BraveSoftware\Edge\URLBlocklist" /v "2" /t REG_SZ /d "options-it.com" /f
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Edge\URLBlocklist" /v "1" /t REG_SZ /d "symmetry.host" /f
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Edge\URLBlocklist" /v "2" /t REG_SZ /d "options-it.com" /f

:: Disable PowerShell
reg add "HKLM\Software\Microsoft\PowerShell\1\ShellIds\ScriptedDiagnostics" /v "ExecutionPolicy" /t REG_SZ /d "Restricted" /f
reg add "HKLM\Software\WOW6432Node\Microsoft\PowerShell\1\ShellIds\ScriptedDiagnostics" /v "ExecutionPolicy" /t REG_SZ /d "Restricted" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\PowerShell" /v "EnableScripts" /t REG_DWORD /d "0" /f
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" /v "__PSLockDownPolicy" /t REG_SZ /d "4" /f

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "DisallowRun" /t REG_DWORD /d "1" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v "1" /t REG_SZ /d "powershell.exe" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v "2" /t REG_SZ /d "powershell_ise.exe" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v "3" /t REG_SZ /d "powershellcustomhost.exe" /f

:: Disable user installation
reg add "HKCU\Software\Policies\Microsoft\Windows\Installer" /v "DisableMSI" /t REG_DWORD /d "1" /f
reg add "HKCU\Software\Policies\Microsoft\Windows\Installer" /v "DisableUserInstalls" /t REG_DWORD /d "1" /f
reg add "HKCU\Software\Policies\Microsoft\Windows\Installer" /v "SafeForScripting" /t REG_DWORD /d "1" /f
reg add "HKCU\Software\Policies\Microsoft\Windows\Installer" /v "AlwaysInstallElevated" /t REG_DWORD /d "1" /f

exit