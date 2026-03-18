@set ver=2.0
@setlocal DisableDelayedExpansion
@echo off



::============================================================================
::
::        IDM Activation Script 
::
::          activate IDM 
::
::      
::
::============================================================================



::  To activate, run the script with "/act" parameter or change 0 to 1 in below line
set _activate=0

::  To Freeze the 30 days trial period, run the script with "/frz" parameter or change 0 to 1 in below line
set _freeze=0

::  To reset the activation and trial, run the script with "/res" parameter or change 0 to 1 in below line
set _reset=0

::  If value is changed in above lines or parameter is used then script will run in unattended mode

::========================================================================================================================================

::  Set Path variable, it helps if it is misconfigured in the system

set "PATH=%SystemRoot%\System32;%SystemRoot%\System32\wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "PATH=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%PATH%"
)

:: Re-launch the script with x64 process if it was initiated by x86 process on x64 bit Windows
:: or with ARM64 process if it was initiated by x86/ARM32 process on ARM64 Windows

set "_cmdf=%~f0"
for %%# in (%*) do (
if /i "%%#"=="r1" set r1=1
if /i "%%#"=="r2" set r2=1
)

if exist %SystemRoot%\Sysnative\cmd.exe if not defined r1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %* r1"
exit /b
)

:: Re-launch the script with ARM32 process if it was initiated by x64 process on ARM64 Windows

if exist %SystemRoot%\SysArm32\cmd.exe if %PROCESSOR_ARCHITECTURE%==AMD64 if not defined r2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %* r2"
exit /b
)

::========================================================================================================================================

set "blank="
set "mas=https://github.com/znzied"

::  Check if Null service is working, it's important for the batch script

sc query Null | find /i "RUNNING"
if %errorlevel% NEQ 0 (
echo:
echo Null service is not running, script may crash...
echo:
echo:
echo Help - %mas%ZIED-Help#troubleshoot
echo:
echo:
ping 127.0.0.1 -n 10
)
cls

::  Check LF line ending

pushd "%~dp0"
>nul findstr /v "$" "%~nx0" && (
echo:
echo Error: Script either has LF line ending issue or an empty line at the end of the script is missing.
echo:
ping 127.0.0.1 -n 6 >nul
popd
exit /b
)
popd

::========================================================================================================================================

cls
color 07
title  IDM Freezer ^& Manager v%ver%

set _args=
set _elev=
set _unattended=0

set _args=%*
if defined _args set _args=%_args:"=%
if defined _args (
for %%A in (%_args%) do (
if /i "%%A"=="-el"  set _elev=1
if /i "%%A"=="/res" set _reset=1
if /i "%%A"=="/frz" set _freeze=1
if /i "%%A"=="/act" set _activate=1
if /i "%%A"=="/sts" goto :_check_status
if /i "%%A"=="/upd" goto :_check_updates
)
)

for %%A in (%_activate% %_freeze% %_reset%) do (if "%%A"=="1" set _unattended=1)

::========================================================================================================================================

set "nul1=1>nul"
set "nul2=2>nul"
set "nul6=2^>nul"
set "nul=>nul 2>&1"

set psc=powershell.exe
set winbuild=1
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G

set _NCS=1
if %winbuild% LSS 10586 set _NCS=0
if %winbuild% GEQ 10586 reg query "HKCU\Console" /v ForceV2 %nul2% | find /i "0x0" %nul1% && (set _NCS=0)

if %_NCS% EQU 1 (
for /F %%a in ('echo prompt $E ^| cmd') do set "esc=%%a"
set     "Red="41;97m""
set    "Gray="100;97m""
set   "Green="42;97m""
set    "Blue="44;97m""
set  "_White="40;37m""
set  "_Green="40;92m""
set "_Yellow="40;93m""
) else (
set     "Red="Red" "white""
set    "Gray="Darkgray" "white""
set   "Green="DarkGreen" "white""
set    "Blue="Blue" "white""
set  "_White="Black" "Gray""
set  "_Green="Black" "Green""
set "_Yellow="Black" "Yellow""
)

set "nceline=echo: &echo ==== ERROR ==== &echo:"
set "eline=echo: &call :_color %Red% "==== ERROR ====" &echo:"
set "line=___________________________________________________________________________________________________"
set "_buf={$W=$Host.UI.RawUI.WindowSize;$B=$Host.UI.RawUI.BufferSize;$W.Height=34;$B.Height=300;$Host.UI.RawUI.WindowSize=$W;$Host.UI.RawUI.BufferSize=$B;}"

::========================================================================================================================================

if %winbuild% LSS 7600 (
%nceline%
echo Unsupported OS version Detected [%winbuild%].
echo Project is supported only for Windows 7/8/8.1/10/11 and their Server equivalent.
goto done2
)

for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" (
%nceline%
echo Unable to find powershell.exe in the system.
goto done2
)

::========================================================================================================================================

::  Fix for the special characters limitation in path name

set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

set "_batf=%~f0"
set "_batp=%_batf:'=''%"

set _PSarg="""%~f0""" -el %_args%
set _PSarg=%_PSarg:'=''%

set "_appdata=%appdata%"
set "_ttemp=%userprofile%\AppData\Local\Temp"

setlocal EnableDelayedExpansion

::========================================================================================================================================

echo "!_batf!" | find /i "!_ttemp!" %nul1% && (
if /i not "!_work!"=="!_ttemp!" (
%eline%
echo Script is launched from the temp folder,
echo Most likely you are running the script directly from the archive file.
echo:
echo Extract the archive file and launch the script from the extracted folder.
goto done2
)
)

::========================================================================================================================================

::  Check PowerShell

REM :PowerShellTest: $ExecutionContext.SessionState.LanguageMode :PowerShellTest:

%psc% "$f=[io.file]::ReadAllText('!_batp!') -split ':PowerShellTest:\s*';iex ($f[1])" | find /i "FullLanguage" %nul1% || (
%eline%
%psc% $ExecutionContext.SessionState.LanguageMode
echo:
echo PowerShell is not working. Aborting...
echo If you have applied restrictions on Powershell then undo those changes.
echo:
echo Check this page for help. %mas%ZIE-Help#troubleshoot
goto done2
)

::========================================================================================================================================

::  Elevate script as admin and pass arguments and preventing loop

%nul1% fltmc || (
if not defined _elev %psc% "start cmd.exe -arg '/c \"!_PSarg!\"' -verb runas" && exit /b
%eline%
echo This script requires admin privileges.
echo To do so, right click on this script and select 'Run as administrator'.
goto done2
)

::========================================================================================================================================

::  Disable QuickEdit and launch from conhost.exe to avoid Terminal app

set quedit=
set terminal=

if %_unattended%==1 (
set quedit=1
set terminal=1
)

for %%# in (%_args%) do (if /i "%%#"=="-qedit" set quedit=1)

if %winbuild% LSS 10586 (
reg query HKCU\Console /v QuickEdit %nul2% | find /i "0x0" %nul1% && set quedit=1
)

if %winbuild% GEQ 17763 (
set "launchcmd=start conhost.exe %psc%"
) else (
set "launchcmd=%psc%"
)

set "d1=$t=[AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1).DefineDynamicModule(2, $False).DefineType(0);"
set "d2=$t.DefinePInvokeMethod('GetStdHandle', 'kernel32.dll', 22, 1, [IntPtr], @([Int32]), 1, 3).SetImplementationFlags(128);"
set "d3=$t.DefinePInvokeMethod('SetConsoleMode', 'kernel32.dll', 22, 1, [Boolean], @([IntPtr], [Int32]), 1, 3).SetImplementationFlags(128);"
set "d4=$k=$t.CreateType(); $b=$k::SetConsoleMode($k::GetStdHandle(-10), 0x0080);"

if defined quedit goto :skipQE
%launchcmd% "%d1% %d2% %d3% %d4% & cmd.exe '/c' '!_PSarg! -qedit'" &exit /b
:skipQE

::========================================================================================================================================

cls
title  IDM Freezer ^& Manager v%ver%

echo:
echo Initializing...

::  Check WMI

%psc% "Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property CreationClassName" %nul2% | find /i "computersystem" %nul1% || (
%eline%
%psc% "Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property CreationClassName"
echo:
echo WMI is not working. Aborting...
echo:
echo Check this page for help. %mas%ZIE-Help#troubleshoot
goto done2
)

::  Check user account SID

set _sid=
for /f "delims=" %%a in ('%psc% "([System.Security.Principal.NTAccount](Get-WmiObject -Class Win32_ComputerSystem).UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value" %nul6%') do (set _sid=%%a)

reg query HKU\%_sid%\Software %nul% || (
for /f "delims=" %%a in ('%psc% "$explorerProc = Get-Process -Name explorer | Where-Object {$_.SessionId -eq (Get-Process -Id $pid).SessionId} | Select-Object -First 1; $sid = (gwmi -Query ('Select * From Win32_Process Where ProcessID=' + $explorerProc.Id)).GetOwnerSid().Sid; $sid" %nul6%') do (set _sid=%%a)
)

reg query HKU\%_sid%\Software %nul% || (
%eline%
echo:
echo [%_sid%]
echo User Account SID not found. Aborting...
echo:
echo Check this page for help. %mas%ZIE-Help#troubleshoot
goto done2
)

::========================================================================================================================================

::  Check if the current user SID is syncing with the HKCU entries

%nul% reg delete HKCU\ZIE_TEST /f
%nul% reg delete HKU\%_sid%\ZIE_TEST /f

set HKCUsync=$null
%nul% reg add HKCU\ZIE_TEST
%nul% reg query HKU\%_sid%\ZIE_TEST && (
set HKCUsync=1
)

%nul% reg delete HKCU\ZIE_TEST /f
%nul% reg delete HKU\%_sid%\ZIE_TEST /f

::  Below code also works for ARM64 Windows 10 (including x64 bit emulation)

for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do set arch=%%b
if /i not "%arch%"=="x86" set arch=x64

if "%arch%"=="x86" (
set "CLSID=HKCU\Software\Classes\CLSID"
set "CLSID2=HKU\%_sid%\Software\Classes\CLSID"
set "HKLM=HKLM\Software\Internet Download Manager"
) else (
set "CLSID=HKCU\Software\Classes\Wow6432Node\CLSID"
set "CLSID2=HKU\%_sid%\Software\Classes\Wow6432Node\CLSID"
set "HKLM=HKLM\SOFTWARE\Wow6432Node\Internet Download Manager"
)

for /f "tokens=2*" %%a in ('reg query "HKU\%_sid%\Software\DownloadManager" /v ExePath %nul6%') do call set "IDMan=%%b"

if not exist "%IDMan%" (
if %arch%==x64 set "IDMan=%ProgramFiles(x86)%\Internet Download Manager\IDMan.exe"
if %arch%==x86 set "IDMan=%ProgramFiles%\Internet Download Manager\IDMan.exe"
)

if not exist %SystemRoot%\Temp md %SystemRoot%\Temp
set "idmcheck=tasklist /fi "imagename eq idman.exe" | findstr /i "idman.exe" %nul1%"

::  Check CLSID registry access

%nul% reg add %CLSID2%\ZIE_TEST
%nul% reg query %CLSID2%\ZIE_TEST || (
%eline%
echo Failed to write in %CLSID2%
echo:
echo Check this page for help. %mas%ZIE-Help#troubleshoot
goto done2
)

%nul% reg delete %CLSID2%\ZIE_TEST /f

::========================================================================================================================================


::========================================================================================================================================
::  Initialize directories and config
::========================================================================================================================================

set "_logdir=!_work!\Logs"
set "_bakdir=!_work!\IDM_Backup"
set "_cfgfile=!_work!\idm_config.cfg"

if not exist "!_logdir!" md "!_logdir!"
if not exist "!_bakdir!" md "!_bakdir!"

set "_cfg_logging=1"
set "_cfg_autobak=1"
set "_cfg_updstart=0"

if exist "!_cfgfile!" (
    for /f "usebackq tokens=1,2 delims==" %%a in ("!_cfgfile!") do (
        if /i "%%a"=="logging"  set "_cfg_logging=%%b"
        if /i "%%a"=="autobak"  set "_cfg_autobak=%%b"
        if /i "%%a"=="updstart" set "_cfg_updstart=%%b"
    )
)

set "_today="
for /f %%a in ('%psc% "Get-Date -Format yyyyMMdd"') do set "_today=%%a"

call :_log "IDM Freezer Manager started"

if "!_cfg_updstart!"=="1" call :_updates_silent_check

:_premenu
if %_reset%==1 goto :_reset
if %_activate%==1 (set frz=0 & goto :_activate)
if %_freeze%==1 (set frz=1 & goto :_activate)

:MainMenu

cls
title  IDM Freezer ^& Manager v%ver%
if not defined terminal mode 80, 36

echo:
echo:
call :_color2 %_White% "              " %_Green% "   IDM Freezer ^& Manager v%ver%  -  By ZIED   "
echo:             ____________________________________________________
echo:
echo:                            ACTIVATE IDM 
echo:                 INTERNET DOWNLOAD MANAGER ACTIVATOR
echo:             ____________________________________________________
echo:
echo:               [1]  Activate IDM
echo:               [2]  Freeze Trial  (Recommended)
echo:               [3]  Reset Activation / Trial
echo:               [4]  Check IDM Status
echo:               [5]  Backup / Restore IDM Settings
echo:             ____________________________________________
echo:
echo:               [6]  Download IDM
echo:               [7]  Check for Updates
echo:               [8]  Settings
echo:               [0]  Exit
echo:             ____________________________________________________
echo:
call :_color2 %_White% "              " %_Green% " Enter option [0-8] "
choice /C:012345678 /N
set _erl=%errorlevel%

if %_erl%==1 (call :_log "Exited" & exit /b)
if %_erl%==2 (set frz=0 & goto :_activate)
if %_erl%==3 (set frz=1 & goto :_activate)
if %_erl%==4 goto :_reset
if %_erl%==5 goto :_check_status
if %_erl%==6 goto :_backup_restore
if %_erl%==7 start https://www.internetdownloadmanager.com/download.html & goto :MainMenu
if %_erl%==8 goto :_check_updates
if %_erl%==9 goto :_settings
goto :MainMenu

::========================================================================================================================================
::  SILENT UPDATE CHECK
::========================================================================================================================================

:_updates_silent_check

set _sint=
for /f "delims=[] tokens=2" %%# in ('ping -n 1 github.com') do (if not [%%#]==[] set _sint=1)
if not defined _sint exit /b

set "_sver="
%psc% "$ErrorActionPreference='Stop';try{$r=Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/zinzied/IDM-Freezer/main/version.txt' -UseBasicParsing;Write-Output $r.Content.Trim()}catch{Write-Output 'err'}" > "!_ttemp!\idm_sv.txt" 2>nul
set /p _sver=<"!_ttemp!\idm_sv.txt"
del /f /q "!_ttemp!\idm_sv.txt" 2>nul

if not defined _sver exit /b
if "!_sver!"=="err" exit /b
if "%ver%"=="!_sver!" exit /b

echo:
call :_color %_Yellow% " New version v!_sver! available - https://github.com/zinzied/IDM-Freezer "
echo:
timeout /t 4 %nul1%
exit /b

:_check_updates

cls
if not defined terminal mode 113, 35
if not defined terminal %psc% "&%_buf%" %nul%

echo:
echo Checking for updates...
echo:

set _int=
for /f "delims=[] tokens=2" %%# in ('ping -n 1 github.com') do (if not [%%#]==[] set _int=1)

if not defined _int (
    call :_color %Red% "Unable to connect to GitHub. Please check your internet connection."
    goto done
)

echo Current version: %ver%
echo:

%psc% "$ErrorActionPreference = 'Stop'; try { $response = Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/zinzied/IDM-Freezer/main/version.txt' -UseBasicParsing; $latestVersion = $response.Content.Trim(); Write-Output $latestVersion } catch { Write-Output 'Error' }" > "%temp%\idm_version.txt"

set /p _latest_ver=<"%temp%\idm_version.txt"
del /f /q "%temp%\idm_version.txt" %nul%

if "!_latest_ver!"=="Error" (
    call :_color %Red% "Failed to check for updates. Please try again later."
    goto done
)

echo Latest version: !_latest_ver!
echo:

if "%ver%"=="!_latest_ver!" (
    call :_color %Green% "You are running the latest version!"
) else (
    call :_color %_Yellow% "A new version is available!"
    echo:
    echo Visit https://github.com/zinzied/IDM-Freezer to download the latest version.
)

echo %line%
echo:
call :_color %Green% "Update check completed."

goto done

:_check_status

cls
if not defined terminal mode 113, 35
if not defined terminal %psc% "&%_buf%" %nul%

echo:
echo Checking IDM Status...
echo:

if not exist "%IDMan%" (
    call :_color %Red% "IDM [Internet Download Manager] is not Installed."
    echo You can download it from  https://www.internetdownloadmanager.com/download.html
    goto done
)

echo IDM Installation Path: "%IDMan%"
echo:

for /f "tokens=2*" %%a in ('reg query "HKU\%_sid%\Software\DownloadManager" /v idmvers %nul6%') do (
    echo IDM Version: %%b
    echo:
)

for /f "tokens=2*" %%a in ('reg query "HKU\%_sid%\Software\DownloadManager" /v Serial %nul6%') do (
    call :_color %Green% "IDM is registered with a serial key."
    echo Serial: %%b
    set _status=registered
    echo:
)

if not defined _status (
    for /f "tokens=2*" %%a in ('reg query "HKU\%_sid%\Software\DownloadManager" /v tvfrdt %nul6%') do (
        call :_color %_Yellow% "IDM is in trial mode."
        echo Trial data: %%b
        set _status=trial
        echo:
    )
)

if not defined _status (
    call :_color %Red% "IDM status could not be determined."
    echo:
)

echo %line%

goto done

::========================================================================================================================================

:_reset

cls
if not defined terminal mode 113, 35
if not defined terminal %psc% "&%_buf%" %nul%

echo:
%idmcheck% && taskkill /f /im idman.exe

::  Auto-backup IDM settings before reset (if enabled in Settings)
if "!_cfg_autobak!"=="1" (
    set "_abtime="
    for /f %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd_HHmmss')"') do set "_abtime=%%a"
    set "_autoback=!_bakdir!\IDM_AutoBackup_!_abtime!.reg"
    reg export "HKCU\Software\DownloadManager" "!_autoback!" /y %nul2%
    if exist "!_autoback!" echo Auto-backup saved: !_autoback!
)

set _time=
for /f %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd-HHmmssfff')"') do set _time=%%a

echo:
echo Creating backup of CLSID registry keys in %SystemRoot%\Temp

reg export %CLSID% "%SystemRoot%\Temp\_Backup_HKCU_CLSID_%_time%.reg"
if not %HKCUsync%==1 reg export %CLSID2% "%SystemRoot%\Temp\_Backup_HKU-%_sid%_CLSID_%_time%.reg"

call :delete_queue
%psc% "$sid = '%_sid%'; $HKCUsync = %HKCUsync%; $lockKey = $null; $deleteKey = 1; $f=[io.file]::ReadAllText('!_batp!') -split ':regscan\:.*';iex ($f[1])"

call :add_key

echo:
echo %line%
echo:
call :_color %Green% "The IDM reset process has been completed."
call :_log "IDM reset completed"

goto done

:delete_queue

echo:
echo Deleting IDM registry keys...
echo:

for %%# in (
""HKCU\Software\DownloadManager" "/v" "FName""
""HKCU\Software\DownloadManager" "/v" "LName""
""HKCU\Software\DownloadManager" "/v" "Email""
""HKCU\Software\DownloadManager" "/v" "Serial""
""HKCU\Software\DownloadManager" "/v" "scansk""
""HKCU\Software\DownloadManager" "/v" "tvfrdt""
""HKCU\Software\DownloadManager" "/v" "radxcnt""
""HKCU\Software\DownloadManager" "/v" "LstCheck""
""HKCU\Software\DownloadManager" "/v" "ptrk_scdt""
""HKCU\Software\DownloadManager" "/v" "LastCheckQU""
"%HKLM%"
) do for /f "tokens=* delims=" %%A in ("%%~#") do (
set "reg="%%~A"" &reg query !reg! %nul% && call :del
)

if not %HKCUsync%==1 for %%# in (
""HKU\%_sid%\Software\DownloadManager" "/v" "FName""
""HKU\%_sid%\Software\DownloadManager" "/v" "LName""
""HKU\%_sid%\Software\DownloadManager" "/v" "Email""
""HKU\%_sid%\Software\DownloadManager" "/v" "Serial""
""HKU\%_sid%\Software\DownloadManager" "/v" "scansk""
""HKU\%_sid%\Software\DownloadManager" "/v" "tvfrdt""
""HKU\%_sid%\Software\DownloadManager" "/v" "radxcnt""
""HKU\%_sid%\Software\DownloadManager" "/v" "LstCheck""
""HKU\%_sid%\Software\DownloadManager" "/v" "ptrk_scdt""
""HKU\%_sid%\Software\DownloadManager" "/v" "LastCheckQU""
) do for /f "tokens=* delims=" %%A in ("%%~#") do (
set "reg="%%~A"" &reg query !reg! %nul% && call :del
)

exit /b

:del

reg delete %reg% /f %nul%

if "%errorlevel%"=="0" (
set "reg=%reg:"=%"
echo Deleted - !reg!
) else (
set "reg=%reg:"=%"
call :_color2 %Red% "Failed - !reg!"
)

exit /b

::========================================================================================================================================

:_activate

cls
if not %HKCUsync%==1 (
if not defined terminal mode 153, 35
) else (
if not defined terminal mode 113, 35
)
if not defined terminal %psc% "&%_buf%" %nul%

if %frz%==0 if %_unattended%==0 (
echo:
echo %line%
echo:
echo      Activation is not working for some users and IDM may show fake serial nag screen.
echo:
call :_color2 %_White% "     " %_Green% "Its recommended to use Freeze Trial option instead."
echo %line%
echo:
choice /C:19 /N /M ">    [1] Go Back [9] Activate : "
if !errorlevel!==1 goto :MainMenu
cls
)

echo:
if not exist "%IDMan%" (
call :_color %Red% "IDM [Internet Download Manager] is not Installed."
echo You can download it from  https://www.internetdownloadmanager.com/download.html
goto done
)

:: Internet check with internetdownloadmanager.com ping and port 80 test

set _int=
for /f "delims=[] tokens=2" %%# in ('ping -n 1 internetdownloadmanager.com') do (if not [%%#]==[] set _int=1)

if not defined _int (
%psc% "$t = New-Object Net.Sockets.TcpClient;try{$t.Connect("""internetdownloadmanager.com""", 80)}catch{};$t.Connected" | findstr /i "true" %nul1% || (
call :_color %Red% "Unable to connect internetdownloadmanager.com, aborting..."
goto done
)
call :_color %Gray% "Ping command failed for internetdownloadmanager.com"
echo:
)

for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul') do set "regwinos=%%b"
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do set "regarch=%%b"
for /f "tokens=6-7 delims=[]. " %%i in ('ver') do if "%%j"=="" (set fullbuild=%%i) else (set fullbuild=%%i.%%j)
for /f "tokens=2*" %%a in ('reg query "HKU\%_sid%\Software\DownloadManager" /v idmvers %nul6%') do set "IDMver=%%b"

echo Checking Info - [%regwinos% ^| %fullbuild% ^| %regarch% ^| IDM: %IDMver%]

%idmcheck% && (echo: & taskkill /f /im idman.exe)

set _time=
for /f %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd-HHmmssfff')"') do set _time=%%a

echo:
echo Creating backup of CLSID registry keys in %SystemRoot%\Temp

reg export %CLSID% "%SystemRoot%\Temp\_Backup_HKCU_CLSID_%_time%.reg"
if not %HKCUsync%==1 reg export %CLSID2% "%SystemRoot%\Temp\_Backup_HKU-%_sid%_CLSID_%_time%.reg"

call :delete_queue
call :add_key

%psc% "$sid = '%_sid%'; $HKCUsync = %HKCUsync%; $lockKey = 1; $deleteKey = $null; $toggle = 1; $f=[io.file]::ReadAllText('!_batp!') -split ':regscan\:.*';iex ($f[1])"

if %frz%==0 call :register_IDM

call :download_files
if not defined _fileexist (
%eline%
echo Error: Unable to download files with IDM.
echo:
echo Help: %mas%ZIE-Help#troubleshoot
goto :done
)

%psc% "$sid = '%_sid%'; $HKCUsync = %HKCUsync%; $lockKey = 1; $deleteKey = $null; $f=[io.file]::ReadAllText('!_batp!') -split ':regscan\:.*';iex ($f[1])"

echo:
echo %line%
echo:
if %frz%==0 (
call :_color %Green% "The IDM Activation process has been completed."
echo:
call :_color %Gray% "If the fake serial screen appears, use the Freeze Trial option instead."
) else (
call :_color %Green% "The IDM 30 days trial period is successfully freezed for Lifetime."
echo:
call :_color %Gray% "If IDM is showing a popup to register, reinstall IDM."
)

::========================================================================================================================================

:done

echo %line%
echo:
echo:
if %_unattended%==1 timeout /t 2 & exit /b

if defined terminal (
call :_color %_Yellow% "Press 0 key to return..."
choice /c 0 /n
) else (
call :_color %_Yellow% "Press any key to return..."
pause %nul1%
)
goto MainMenu

:done2

if %_unattended%==1 timeout /t 2 & exit /b

if defined terminal (
echo Press 0 key to exit...
choice /c 0 /n
) else (
echo Press any key to exit...
pause %nul1%
)
exit /b


::========================================================================================================================================
::  BACKUP / RESTORE
::========================================================================================================================================

:_backup_restore

cls
title  IDM Freezer ^& Manager - Backup/Restore
if not defined terminal mode 80, 30

echo:
echo:
call :_color2 %_White% "              " %_Green% "   BACKUP / RESTORE IDM SETTINGS   "
echo:             ____________________________________________________
echo:
echo:               [1]  Backup IDM Settings Now
echo:               [2]  Restore IDM Settings
echo:               [3]  List All Backups
echo:               [0]  Return to Main Menu
echo:             ____________________________________________________
echo:
call :_color2 %_White% "              " %_Green% " Enter option [0-3] "
choice /C:0123 /N
set _erl=%errorlevel%

if %_erl%==1 goto :MainMenu
if %_erl%==2 goto :_backup_now
if %_erl%==3 goto :_restore_menu
if %_erl%==4 goto :_list_backups
goto :_backup_restore

:_backup_now

cls
echo:
echo Backing up IDM registry settings...
echo:

if not exist "!_bakdir!" md "!_bakdir!"

set "_btime="
for /f %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd_HHmmss')"') do set "_btime=%%a"
set "_bakfile=!_bakdir!\IDM_Settings_!_btime!.reg"

reg export "HKCU\Software\DownloadManager" "!_bakfile!" /y %nul2%

if exist "!_bakfile!" (
    echo:
    call :_color %Green% "Backup completed successfully!"
    echo:
    echo Saved : !_bakfile!
    call :_log "Backup created: IDM_Settings_!_btime!.reg"
) else (
    echo:
    call :_color %Red% "Backup failed. Make sure IDM is installed."
    call :_log "Backup failed"
)

echo:
echo %line%
echo:
call :_color %_Yellow% "Press any key to continue..."
pause %nul1%
goto :_backup_restore

:_restore_menu

cls
echo:
echo Available backups:
echo:

set _ridx=0
for /f "delims=" %%f in ('dir /b /o-d "!_bakdir!\IDM_Settings_*.reg" 2^>nul') do (
    set /a _ridx+=1
    set "_rbak_!_ridx!=%%f"
    echo    [!_ridx!] %%f
)

if %_ridx%==0 (
    echo:
    call :_color %Red% "No backup files found."
    echo:
    call :_color %_Yellow% "Press any key to return..."
    pause %nul1%
    goto :_backup_restore
)

echo:
echo    [0] Cancel
echo:
set "_rchoice="
set /p _rchoice="Enter number: "

if not defined _rchoice goto :_backup_restore
if "!_rchoice!"=="0" goto :_backup_restore

set "_rchoice_val=0"
set /a "_rchoice_val=!_rchoice!" 2>nul

if !_rchoice_val! LSS 1 goto :_restore_bad
if !_rchoice_val! GTR !_ridx! goto :_restore_bad

call set "_rfile=%%_rbak_!_rchoice!%%"

if not defined _rfile goto :_restore_bad

echo:
call :_color %_Yellow% "Restoring: !_rfile!"
echo:
set /p _rconfirm="Are you sure? (y/n): "
if /i not "!_rconfirm!"=="y" goto :_backup_restore

reg import "!_bakdir!\!_rfile!" 2>nul

if "%errorlevel%"=="0" (
    echo:
    call :_color %Green% "Restore completed successfully!"
    call :_log "Restore done: !_rfile!"
) else (
    echo:
    call :_color %Red% "Restore failed. Try running as administrator."
    call :_log "Restore failed: !_rfile!"
)

echo:
call :_color %_Yellow% "Press any key to return..."
pause %nul1%
goto :_backup_restore

:_restore_bad
echo:
call :_color %Red% "Invalid selection."
echo:
call :_color %_Yellow% "Press any key to return..."
pause %nul1%
goto :_backup_restore

:_list_backups

cls
echo:
echo Backup folder: !_bakdir!
echo:

set _vidx=0
for /f "delims=" %%f in ('dir /b /o-d "!_bakdir!\*.reg" 2^>nul') do (
    set /a _vidx+=1
    echo    [!_vidx!] %%f
)

if %_vidx%==0 (
    call :_color %Red% "No backup files found."
) else (
    echo:
    echo Total: !_vidx! backup(s).
)

echo:
echo %line%
echo:
call :_color %_Yellow% "Press any key to return..."
pause %nul1%
goto :_backup_restore

::========================================================================================================================================
::  SETTINGS
::========================================================================================================================================

:_settings

cls
title  IDM Freezer ^& Manager - Settings
if not defined terminal mode 80, 30

if "!_cfg_logging!"=="1"  (set "_lbl_log=ON ") else (set "_lbl_log=OFF")
if "!_cfg_autobak!"=="1"  (set "_lbl_bak=ON ") else (set "_lbl_bak=OFF")
if "!_cfg_updstart!"=="1" (set "_lbl_upd=ON ") else (set "_lbl_upd=OFF")

echo:
echo:
call :_color2 %_White% "              " %_Green% "   SETTINGS   "
echo:             ____________________________________________________
echo:
echo:               [1]  Logging                 : [!_lbl_log!]
echo:               [2]  Auto-Backup on Reset    : [!_lbl_bak!]
echo:               [3]  Check Updates on Start  : [!_lbl_upd!]
echo:               [4]  View Log Files
echo:               [5]  Clear All Logs
echo:               [0]  Return to Main Menu
echo:             ____________________________________________________
echo:
call :_color2 %_White% "              " %_Green% " Enter option [0-5] "
choice /C:012345 /N
set _erl=%errorlevel%

if %_erl%==1 goto :MainMenu
if %_erl%==2 (
    if "!_cfg_logging!"=="1" (set "_cfg_logging=0") else (set "_cfg_logging=1")
    call :_save_config & goto :_settings
)
if %_erl%==3 (
    if "!_cfg_autobak!"=="1" (set "_cfg_autobak=0") else (set "_cfg_autobak=1")
    call :_save_config & goto :_settings
)
if %_erl%==4 (
    if "!_cfg_updstart!"=="1" (set "_cfg_updstart=0") else (set "_cfg_updstart=1")
    call :_save_config & goto :_settings
)
if %_erl%==5 goto :_view_logs
if %_erl%==6 goto :_clear_logs
goto :_settings

:_view_logs

cls
echo:
echo Log files in: !_logdir!
echo:

set _lidx=0
for /f "delims=" %%f in ('dir /b /o-d "!_logdir!\*.log" 2^>nul') do (
    set /a _lidx+=1
    set "_llog_!_lidx!=%%f"
    echo    [!_lidx!] %%f
)

if %_lidx%==0 (
    call :_color %Red% "No log files found."
    echo:
    call :_color %_Yellow% "Press any key to return..."
    pause %nul1%
    goto :_settings
)

echo:
echo    [0] Cancel
echo:
set "_lchoice="
set /p _lchoice="Enter number to view: "

if not defined _lchoice goto :_settings
if "!_lchoice!"=="0" goto :_settings

set "_lchoice_val=0"
set /a "_lchoice_val=!_lchoice!" 2>nul

if !_lchoice_val! LSS 1 goto :_settings
if !_lchoice_val! GTR !_lidx! goto :_settings

call set "_lfile=%%_llog_!_lchoice!%%"

if not defined _lfile goto :_settings

echo:
echo ============================================================
echo  Last 50 lines of: !_lfile!
echo ============================================================
echo:
%psc% "Get-Content '!_logdir!\!_lfile!' -Tail 50 -ErrorAction SilentlyContinue"
echo:
call :_color %_Yellow% "Press any key to return..."
pause %nul1%
goto :_settings

:_clear_logs

cls
echo:
call :_color %_Yellow% "This will delete ALL log files in: !_logdir!"
echo:
set /p _clc="Are you sure? (y/n): "
if /i "!_clc!"=="y" (
    del /f /q "!_logdir!\*.log" %nul%
    echo:
    call :_color %Green% "All log files cleared."
    echo:
)
call :_color %_Yellow% "Press any key to return..."
pause %nul1%
goto :_settings

::========================================================================================================================================
::  CONFIG + LOG HELPERS
::========================================================================================================================================

:_save_config
(
echo logging=!_cfg_logging!
echo autobak=!_cfg_autobak!
echo updstart=!_cfg_updstart!
) > "!_cfgfile!"
exit /b

::========================================================================================================================================

:_log
if not defined _logdir exit /b
if not defined _today  exit /b
if "!_cfg_logging!"=="0" exit /b
>> "!_logdir!\idm_manager_!_today!.log" echo [%time:~0,8%] %~1
exit /b

::========================================================================================================================================

:_rcont

reg add %reg% %nul%
call :add
exit /b

:register_IDM

echo:
echo Applying registration details...
echo:

set /a fname = %random% %% 9999 + 1000
set /a lname = %random% %% 9999 + 1000
set email=%fname%.%lname%@tonec.com

for /f "delims=" %%a in ('%psc% "$key = -join ((Get-Random -Count  20 -InputObject ([char[]]('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'))));$key = ($key.Substring(0,  5) + '-' + $key.Substring(5,  5) + '-' + $key.Substring(10,  5) + '-' + $key.Substring(15,  5) + $key.Substring(20));Write-Output $key" %nul6%') do (set key=%%a)

set "reg=HKCU\SOFTWARE\DownloadManager /v FName /t REG_SZ /d "%fname%"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v LName /t REG_SZ /d "%lname%"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v Email /t REG_SZ /d "%email%"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v Serial /t REG_SZ /d "%key%"" & call :_rcont

if not %HKCUsync%==1 (
set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v FName /t REG_SZ /d "%fname%"" & call :_rcont
set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v LName /t REG_SZ /d "%lname%"" & call :_rcont
set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v Email /t REG_SZ /d "%email%"" & call :_rcont
set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v Serial /t REG_SZ /d "%key%"" & call :_rcont
)
exit /b

:download_files

echo:
echo Triggering a few downloads to create certain registry keys, please wait...
echo:

set "file=%SystemRoot%\Temp\temp.png"
set _fileexist=

set link=https://www.internetdownloadmanager.com/images/idm_box_min.png
call :download
set link=https://www.internetdownloadmanager.com/register/IDMlib/images/idman_logos.png
call :download
set link=https://www.internetdownloadmanager.com/pictures/idm_about.png
call :download

echo:
timeout /t 3 %nul1%
%idmcheck% && taskkill /f /im idman.exe
if exist "%file%" del /f /q "%file%"
exit /b

:download

set /a attempt=0
if exist "%file%" del /f /q "%file%"
start "" /B "%IDMan%" /n /d "%link%" /p "%SystemRoot%\Temp" /f temp.png

:check_file

timeout /t 1 %nul1%
set /a attempt+=1
if exist "%file%" set _fileexist=1&exit /b
if %attempt% GEQ 20 exit /b
goto :Check_file

::========================================================================================================================================

:add_key

echo:
echo Adding registry key...
echo:

set "reg="%HKLM%" /v "AdvIntDriverEnabled2""

reg add %reg% /t REG_DWORD /d "1" /f %nul%

:add

if "%errorlevel%"=="0" (
set "reg=%reg:"=%"
echo Added - !reg!
) else (
set "reg=%reg:"=%"
call :_color2 %Red% "Failed - !reg!"
)
exit /b

::========================================================================================================================================

:regscan:
$finalValues = @()

$arch = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').PROCESSOR_ARCHITECTURE
if ($arch -eq "x86") {
  $regPaths = @("HKCU:\Software\Classes\CLSID", "Registry::HKEY_USERS\$sid\Software\Classes\CLSID")
} else {
  $regPaths = @("HKCU:\Software\Classes\WOW6432Node\CLSID", "Registry::HKEY_USERS\$sid\Software\Classes\Wow6432Node\CLSID")
}

foreach ($regPath in $regPaths) {
    if (($regPath -match "HKEY_USERS") -and ($HKCUsync -ne $null)) {
        continue
    }

	Write-Host
	Write-Host "Searching IDM CLSID Registry Keys in $regPath"
	Write-Host

    $subKeys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue -ErrorVariable lockedKeys | Where-Object { $_.PSChildName -match '^\{[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}\}$' }

    foreach ($lockedKey in $lockedKeys) {
        $leafValue = Split-Path -Path $lockedKey.TargetObject -Leaf
        $finalValues += $leafValue
        Write-Output "$leafValue - Found Locked Key"
    }

    if ($subKeys -eq $null) {
	continue
	}

	$subKeysToExclude = "LocalServer32", "InProcServer32", "InProcHandler32"

    $filteredKeys = $subKeys | Where-Object { !($_.GetSubKeyNames() | Where-Object { $subKeysToExclude -contains $_ }) }

    foreach ($key in $filteredKeys) {
        $fullPath = $key.PSPath
        $keyValues = Get-ItemProperty -Path $fullPath -ErrorAction SilentlyContinue
        $defaultValue = $keyValues.PSObject.Properties | Where-Object { $_.Name -eq '(default)' } | Select-Object -ExpandProperty Value

        if (($defaultValue -match "^\d+$") -and ($key.SubKeyCount -eq 0)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - Found Digit In Default and No Subkeys"
            continue
        }
        if (($defaultValue -match "\+|=") -and ($key.SubKeyCount -eq 0)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - Found + or = In Default and No Subkeys"
            continue
        }
        $versionValue = Get-ItemProperty -Path "$fullPath\Version" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty '(default)' -ErrorAction SilentlyContinue
        if (($versionValue -match "^\d+$") -and ($key.SubKeyCount -eq 1)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - Found Digit In \Version and No Other Subkeys"
            continue
        }
        $keyValues.PSObject.Properties | ForEach-Object {
            if ($_.Name -match "MData|Model|scansk|Therad") {
                $finalValues += $($key.PSChildName)
                Write-Output "$($key.PSChildName) - Found MData Model scansk Therad"
                continue
            }
        }
        if (($key.ValueCount -eq 0) -and ($key.SubKeyCount -eq 0)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - Found Empty Key"
            continue
        }
    }
}

$finalValues = @($finalValues | Select-Object -Unique)

if ($finalValues -ne $null) {
    Write-Host
    if ($lockKey -ne $null) {
        Write-Host "Locking IDM CLSID Registry Keys..."
    }
    if ($deleteKey -ne $null) {
        Write-Host "Deleting IDM CLSID Registry Keys..."
    }
    Write-Host
} else {
    Write-Host "IDM CLSID Registry Keys are not found."
	Exit
}

if (($finalValues.Count -gt 20) -and ($toggle -ne $null)) {
	$lockKey = $null
	$deleteKey = 1
    Write-Host "The IDM keys count is more than 20. Deleting them now instead of locking..."
	Write-Host
}

function Take-Permissions {
    param($rootKey, $regKey)
    $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule(2, $False)
    $TypeBuilder = $ModuleBuilder.DefineType(0)

    $TypeBuilder.DefinePInvokeMethod('RtlAdjustPrivilege', 'ntdll.dll', 'Public, Static', 1, [int], @([int], [bool], [bool], [bool].MakeByRefType()), 1, 3) | Out-Null
    9,17,18 | ForEach-Object { $TypeBuilder.CreateType()::RtlAdjustPrivilege($_, $true, $false, [ref]$false) | Out-Null }

    $SID = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
    $IDN = ($SID.Translate([System.Security.Principal.NTAccount])).Value
    $Admin = New-Object System.Security.Principal.NTAccount($IDN)

    $everyone = New-Object System.Security.Principal.SecurityIdentifier('S-1-1-0')
    $none = New-Object System.Security.Principal.SecurityIdentifier('S-1-0-0')

    $key = [Microsoft.Win32.Registry]::$rootKey.OpenSubKey($regkey, 'ReadWriteSubTree', 'TakeOwnership')

    $acl = New-Object System.Security.AccessControl.RegistrySecurity
    $acl.SetOwner($Admin)
    $key.SetAccessControl($acl)

    $key = $key.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule($everyone, 'FullControl', 'ContainerInherit', 'None', 'Allow')
    $acl.ResetAccessRule($rule)
    $key.SetAccessControl($acl)

    if ($lockKey -ne $null) {
        $acl = New-Object System.Security.AccessControl.RegistrySecurity
        $acl.SetOwner($none)
        $key.SetAccessControl($acl)

        $key = $key.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule($everyone, 'FullControl', 'Deny')
        $acl.ResetAccessRule($rule)
        $key.SetAccessControl($acl)
    }
}

foreach ($regPath in $regPaths) {
    if (($regPath -match "HKEY_USERS") -and ($HKCUsync -ne $null)) {
        continue
    }
    foreach ($finalValue in $finalValues) {
        $fullPath = Join-Path -Path $regPath -ChildPath $finalValue
        if ($fullPath -match 'HKCU:') {
            $rootKey = 'CurrentUser'
        } else {
            $rootKey = 'Users'
        }

        $position = $fullPath.IndexOf("\")
        $regKey = $fullPath.Substring($position + 1)

        if ($lockKey -ne $null) {
            if (-not (Test-Path -Path $fullPath -ErrorAction SilentlyContinue)) { New-Item -Path $fullPath -Force -ErrorAction SilentlyContinue | Out-Null }
            Take-Permissions $rootKey $regKey
            try {
                Remove-Item -Path $fullPath -Force -Recurse -ErrorAction Stop
                Write-Host -back 'DarkRed' -fore 'white' "Failed - $fullPath"
            }
            catch {
                Write-Host "Locked - $fullPath"
            }
        }

        if ($deleteKey -ne $null) {
            if (Test-Path -Path $fullPath) {
                Remove-Item -Path $fullPath -Force -Recurse -ErrorAction SilentlyContinue
                if (Test-Path -Path $fullPath) {
                    Take-Permissions $rootKey $regKey
                    try {
                        Remove-Item -Path $fullPath -Force -Recurse -ErrorAction Stop
                        Write-Host "Deleted - $fullPath"
                    }
                    catch {
                        Write-Host -back 'DarkRed' -fore 'white' "Failed - $fullPath"
                    }
                }
                else {
                    Write-Host "Deleted - $fullPath"
                }
            }
        }
    }
}
:regscan:

::========================================================================================================================================

:_color

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[0m
) else (
%psc% write-host -back '%1' -fore '%2' '%3'
)
exit /b

:_color2

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[%~3%~4%esc%[0m
) else (
%psc% write-host -back '%1' -fore '%2' '%3' -NoNewline; write-host -back '%4' -fore '%5' '%6'
)
exit /b

::========================================================================================================================================
:: Leave empty line below
