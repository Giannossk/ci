@echo off

set WORKDIR=%TEMP%\%~n0
rmdir /S /Q %WORKDIR%
mkdir %WORKDIR%

REM Install Chocolatey (will also install refreshenv command)
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
set AddToUserPATH=%ALLUSERSPROFILE%\chocolatey\bin


REM Install CI specific dependencies
choco install -y jre8


REM Install SOFA dependencies with Chocolatey
choco install -y git --version=2.25.1
REM choco install -y zip
REM choco install -y unzip
REM choco install -y curl
choco install -y wget --version=1.20.3.20190531
choco install -y ninja --version=1.10.0
choco install -y cmake --version=3.16.2 --installargs 'ADD_CMAKE_TO_PATH=System'
choco install -y python2 --version=2.7.17
call refreshenv && echo OK
python -m pip install --upgrade pip
python -m pip install numpy scipy
call refreshenv && echo OK


REM Install plugins dependencies
choco install -y cuda --version=10.2.89.20191206
REM Bullet: source code to build: https://github.com/bulletphysics/bullet3/releases
REM Pybind: source code to build: https://github.com/pybind/pybind11/releases
call refreshenv && echo OK


REM Install clcache
powershell Invoke-WebRequest https://github.com/frerich/clcache/releases/download/v4.2.0/clcache-4.2.0.zip -OutFile %WORKDIR%\clcache.zip
powershell Expand-Archive %WORKDIR%\clcache.zip -DestinationPath C:\clcache
REM if not exist "J:\clcache\" mkdir "J:\clcache"
REM setx CLCACHE_OBJECT_CACHE_TIMEOUT_MS 3600000
REM setx CLCACHE_DIR J:\clcache
REM setx CLCACHE_BASEDIR J:\workspace
REM (
  REM echo {
  REM echo "MaximumCacheSize": 34359738368
  REM echo }
REM ) > J:\clcache\config.txt
set AddToUserPATH=%AddToUserPATH%;C:\clcache


REM Install Visual Studio Build Tools 2017
REM To see component names, run Visual Studio Installer and play with configuration export.
REM Use --passive instead of --quiet when testing (GUI will appear with progress bar).
powershell Invoke-WebRequest https://raw.githubusercontent.com/guparan/DockerSofaBuilder/master/sofabuilder_windows_vs2017/wait_process_to_end.bat -OutFile %WORKDIR%\wait_process_to_end.bat
powershell Invoke-WebRequest https://aka.ms/vs/15/release/vs_buildtools.exe -OutFile %WORKDIR%\vs_buildtools.exe
%WORKDIR%\vs_buildtools.exe ^
    --wait --quiet --norestart --nocache ^
    --installPath C:\VSBuildTools ^
    --add Microsoft.VisualStudio.Workload.VCTools ^
    --add microsoft.visualstudio.component.vc.cmake.project ^
    --add microsoft.visualstudio.component.testtools.buildtools ^
    --add microsoft.visualstudio.component.vc.atlmfc ^
    --add microsoft.visualstudio.component.vc.cli.support ^
    --includeRecommended ^
   & call %WORKDIR%\wait_process_to_end.bat "vs_bootstrapper.exe" ^
   & call %WORKDIR%\wait_process_to_end.bat "vs_BuildTools.exe" ^
   & call %WORKDIR%\wait_process_to_end.bat "vs_buildtools.exe" ^
   & call %WORKDIR%\wait_process_to_end.bat "vs_installer.exe"

setx VS150COMNTOOLS C:\VSBuildTools\Common7\Tools\
setx VSINSTALLDIR C:\VSBuildTools\
call refreshenv && echo OK


REM Install Qt
set QT_MAJOR=5
set QT_MINOR=12
set QT_PATCH=6
REM setx QTDIR "C:\Qt\%QT_MAJOR%.%QT_MINOR%.%QT_PATCH%\msvc2017_64"
REM setx QTDIR64 %QTDIR%
REM setx Qt5_DIR %QTDIR%
call refreshenv && echo OK
if not exist "%APPDATA%\Qt\" mkdir %APPDATA%\Qt
powershell Invoke-WebRequest https://raw.githubusercontent.com/guparan/DockerSofaBuilder/master/sofabuilder_windows_vs2017/qtaccount.ini -OutFile %APPDATA%\Qt\qtaccount.ini
powershell Invoke-WebRequest https://download.qt.io/official_releases/online_installers/qt-unified-windows-x86-online.exe -OutFile %WORKDIR%\qtinstaller.exe
powershell Invoke-WebRequest https://raw.githubusercontent.com/guparan/DockerSofaBuilder/master/sofabuilder_windows_vs2017/qtinstaller_controlscript_template.qs -OutFile %WORKDIR%\qtinstaller_controlscript_template.qs
powershell -Command "(gc %WORKDIR%\qtinstaller_controlscript_template.qs) -replace '_QTVERSION_', %QT_MAJOR%%QT_MINOR%%QT_PATCH% | Out-File -encoding ASCII %WORKDIR%\qtinstaller_controlscript.qs"
%WORKDIR%\qtinstaller.exe --script %WORKDIR%\qtinstaller_controlscript.qs


REM Install Boost
set BOOST_MAJOR=1
set BOOST_MINOR=69
set BOOST_PATCH=0
call refreshenv && echo OK
powershell Invoke-WebRequest https://raw.githubusercontent.com/guparan/DockerSofaBuilder/master/sofabuilder_windows_vs2017/wait_process_to_end.bat -OutFile %WORKDIR%\wait_process_to_end.bat
powershell Invoke-WebRequest https://boost.teeks99.com/bin/%BOOST_MAJOR%.%BOOST_MINOR%.%BOOST_PATCH%/boost_%BOOST_MAJOR%_%BOOST_MINOR%_%BOOST_PATCH%-msvc-14.1-64.exe -OutFile %WORKDIR%\boostinstaller.exe
%WORKDIR%\boostinstaller.exe /NORESTART /VERYSILENT /DIR=C:\boost & %WORKDIR%\wait_process_to_end.bat "boostinstaller.exe"


REM Install Assimp
set ASSIMP_MAJOR=4
set ASSIMP_MINOR=1
set ASSIMP_PATCH=0
call refreshenv && echo OK
powershell Invoke-WebRequest https://raw.githubusercontent.com/guparan/DockerSofaBuilder/master/sofabuilder_windows_vs2017/wait_process_to_end.bat -OutFile %WORKDIR%\wait_process_to_end.bat
powershell Invoke-WebRequest https://github.com/assimp/assimp/releases/download/v%ASSIMP_MAJOR%.%ASSIMP_MINOR%.%ASSIMP_PATCH%/assimp-sdk-%ASSIMP_MAJOR%.%ASSIMP_MINOR%.%ASSIMP_PATCH%-setup.exe -OutFile %WORKDIR%\assimpinstaller.exe
%WORKDIR%\assimpinstaller.exe /NORESTART /VERYSILENT /DIR=C:\assimp & %WORKDIR%\wait_process_to_end.bat "assimpinstaller.exe"
set AddToUserPATH=%AddToUserPATH%;C:\assimp


REM Install CGAL
set CGAL_MAJOR=5
set CGAL_MINOR=0
set CGAL_PATCH=2
call refreshenv && echo OK
powershell Invoke-WebRequest https://raw.githubusercontent.com/guparan/DockerSofaBuilder/master/sofabuilder_windows_vs2017/wait_process_to_end.bat -OutFile %WORKDIR%\wait_process_to_end.bat
powershell Invoke-WebRequest https://github.com/CGAL/cgal/releases/download/releases/CGAL-%CGAL_MAJOR%.%CGAL_MINOR%.%CGAL_PATCH%/CGAL-%CGAL_MAJOR%.%CGAL_MINOR%.%CGAL_PATCH%-Setup.exe -OutFile %WORKDIR%\cgalinstaller.exe
%WORKDIR%\cgalinstaller.exe /S /D=C:\CGAL & %WORKDIR%\wait_process_to_end.bat "cgalinstaller.exe"
set AddToUserPATH=%AddToUserPATH%;C:\CGAL


REM Install OpenCascade
set OCC_MAJOR=7
set OCC_MINOR=4
set OCC_PATCH=0
call refreshenv && echo OK
powershell Invoke-WebRequest https://raw.githubusercontent.com/guparan/DockerSofaBuilder/master/sofabuilder_windows_vs2017/wait_process_to_end.bat -OutFile %WORKDIR%\wait_process_to_end.bat
powershell Invoke-WebRequest http://transfer.sofa-framework.org/opencascade-%OCC_MAJOR%.%OCC_MINOR%.%OCC_PATCH%-vc14-64.exe -OutFile %WORKDIR%\occinstaller.exe
%WORKDIR%\occinstaller.exe /NORESTART /VERYSILENT /DIR=C:\OpenCascade & %WORKDIR%\wait_process_to_end.bat "occinstaller.exe"
set AddToUserPATH=%AddToUserPATH%;C:\OpenCascade\opencascade-%OCC_MAJOR%.%OCC_MINOR%.%OCC_PATCH%


REM Finalize environment
call refreshenv && echo OK
setx PYTHONIOENCODING UTF-8
REM set AddToUserPATH="%AddToUserPATH%;C:\Qt\%QT_MAJOR%.%QT_MINOR%.%QT_PATCH%\msvc2017_64\bin"
REM set AddToUserPATH="%AddToUserPATH%;C:\boost"
REM set AddToUserPATH="%AddToUserPATH%;C:\boost\lib64-msvc-14.1"
set AddToUserPATH=%AddToUserPATH%;C:\Program Files\Git\bin
REM set AddToUserPATH="%AddToUserPATH%;C:\Windows\System32\downlevel"

set "UserPATH=" & for /F "skip=2 tokens=1,2*" %N in ('%SystemRoot%\System32\reg.exe query "HKCU\Environment" /v "Path" 2^>nul') do (if /I "%N" == "Path" (set "UserPATH=%P"))
setx PATH "%UserPATH%;%AddToUserPATH%"
