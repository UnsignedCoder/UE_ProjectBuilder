@echo off
setlocal enabledelayedexpansion

REM Configuration file to store paths
set "CONFIG_FILE=%~dp0UnrealBuilder_Config.txt"

REM Initialize paths as empty
set "ENGINE="
set "PROJECT_BASE="

REM Load configuration if it exists
if exist "%CONFIG_FILE%" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%CONFIG_FILE%") do (
        if "%%A"=="ENGINE" set "ENGINE=%%B"
        if "%%A"=="PROJECT_BASE" set "PROJECT_BASE=%%B"
    )
)

echo ========================================
echo UNREAL PROJECT BUILD TOOL v2.2
echo ========================================
echo.

REM Check if we need to configure paths
set "NEEDS_CONFIG=false"
if "%ENGINE%"=="" set "NEEDS_CONFIG=true"
if "%PROJECT_BASE%"=="" set "NEEDS_CONFIG=true"

REM Validate existing paths if they're set
if not "%ENGINE%"=="" (
    if not exist "%ENGINE%" (
        echo Warning: Previously configured engine path no longer exists: %ENGINE%
        set "NEEDS_CONFIG=true"
        set "ENGINE="
    )
)

if not "%PROJECT_BASE%"=="" (
    if not exist "%PROJECT_BASE%" (
        echo Warning: Previously configured project directory no longer exists: %PROJECT_BASE%
        set "NEEDS_CONFIG=true"
        set "PROJECT_BASE="
    )
)

REM First-time setup or reconfiguration
if "%NEEDS_CONFIG%"=="true" (
    echo ========================================
    echo FIRST-TIME SETUP
    echo ========================================
    echo This appears to be your first time running this script,
    echo or your previous configuration is invalid.
    echo.
    echo Please provide the required paths:
    echo.
    
    REM Get Engine Path
    :get_engine_path
    echo Engine Path Configuration:
    echo ----------------------------------------
    if not "%ENGINE%"=="" (
        echo Current: %ENGINE% [INVALID]
    )
    echo Example: C:\Engines\UnrealEngine\UE_5.6
    echo          C:\Program Files\Epic Games\UE_5.4
    echo.
    set /p "NEW_ENGINE=Enter your Unreal Engine installation path: "
    
    REM Validate engine path
    if "%NEW_ENGINE%"=="" (
        echo Error: Engine path cannot be empty.
        goto :get_engine_path
    )
    
    if not exist "%NEW_ENGINE%" (
        echo Error: Path does not exist: %NEW_ENGINE%
        echo Please enter a valid path to your Unreal Engine installation.
        goto :get_engine_path
    )
    
    REM Check for UnrealBuildTool
    if not exist "%NEW_ENGINE%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" (
        echo Error: This doesn't appear to be a valid Unreal Engine installation.
        echo Could not find UnrealBuildTool.exe at:
        echo %NEW_ENGINE%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe
        echo.
        echo Please verify you've entered the correct Unreal Engine root directory.
        goto :get_engine_path
    )
    
    set "ENGINE=%NEW_ENGINE%"
    echo Engine path validated: %ENGINE%
    echo.
    
    REM Get Project Base Path
    :get_project_path
    echo Project Directory Configuration:
    echo ----------------------------------------
    if not "%PROJECT_BASE%"=="" (
        echo Current: %PROJECT_BASE% [INVALID]
    )
    echo Example: C:\GameDevProjects\UnrealProjects
    echo          D:\MyProjects\Unreal
    echo.
    echo This should be the folder containing your Unreal project folders.
    echo Each project folder should contain a .uproject file.
    echo.
    set /p "NEW_PROJECT_BASE=Enter your projects base directory: "
    
    REM Validate project base path
    if "%NEW_PROJECT_BASE%"=="" (
        echo Error: Project base path cannot be empty.
        goto :get_project_path
    )
    
    if not exist "%NEW_PROJECT_BASE%" (
        echo Error: Directory does not exist: %NEW_PROJECT_BASE%
        echo.
        set /p CREATE_DIR="Would you like to create this directory? (Y/n): "
        if /i "!CREATE_DIR!"=="n" goto :get_project_path
        
        mkdir "%NEW_PROJECT_BASE%" 2>nul
        if !errorlevel! neq 0 (
            echo Error: Failed to create directory: %NEW_PROJECT_BASE%
            echo Please check permissions or enter a different path.
            goto :get_project_path
        )
        echo Directory created: %NEW_PROJECT_BASE%
    )
    
    set "PROJECT_BASE=%NEW_PROJECT_BASE%"
    echo Project base directory set: %PROJECT_BASE%
    echo.
    
    REM Save configuration
    echo Saving configuration...
    (
        echo ENGINE=%ENGINE%
        echo PROJECT_BASE=%PROJECT_BASE%
    ) > "%CONFIG_FILE%"
    
    if exist "%CONFIG_FILE%" (
        echo Configuration saved to: %CONFIG_FILE%
        echo.
        echo ========================================
        echo SETUP COMPLETE
        echo ========================================
        echo Engine: %ENGINE%
        echo Projects: %PROJECT_BASE%
        echo.
        echo Configuration will be automatically loaded on future runs.
        echo To reconfigure paths, delete: %CONFIG_FILE%
        echo.
        echo Restarting build tool with new configuration...
        echo.
        pause
        
        REM Restart the script with new configuration
        "%~f0"
        exit /b
    ) else (
        echo Error: Failed to save configuration file.
        echo You may need to run this script as administrator.
        pause
        exit /b 1
    )
)

REM Display current configuration
echo Current Configuration:
echo ----------------------------------------
echo Engine: %ENGINE%
echo Projects: %PROJECT_BASE%
echo Config file: %CONFIG_FILE%
echo.

REM Path to UnrealBuildTool and UnrealAutomationTool
set "UBT=%ENGINE%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"
set "UAT_BAT=%ENGINE%\Engine\Build\BatchFiles\RunUAT.bat"

REM Final validation checks
if not exist "%UBT%" (
    echo Error: UnrealBuildTool not found at: %UBT%
    echo Your engine configuration may be incorrect.
    echo Delete %CONFIG_FILE% to reconfigure paths.
    pause
    exit /b 1
)

if not exist "%UAT_BAT%" (
    echo Error: UnrealAutomationTool not found at: %UAT_BAT%
    echo Your engine configuration may be incorrect.
    echo Delete %CONFIG_FILE% to reconfigure paths.
    pause
    exit /b 1
)

echo Scanning for Unreal projects in: %PROJECT_BASE%
echo.

REM Discover all project folders with .uproject files
set PROJECT_COUNT=0

echo Available Unreal Projects:
echo ----------------------------------------

for /d %%d in ("%PROJECT_BASE%\*") do (
    for %%f in ("%%d\*.uproject") do (
        set /a PROJECT_COUNT+=1
        set "PROJECT_!PROJECT_COUNT!_NAME=%%~nd"
        set "PROJECT_!PROJECT_COUNT!_PATH=%%d"
        set "PROJECT_!PROJECT_COUNT!_FILE=%%f"
        echo [!PROJECT_COUNT!] %%~nd
    )
)

echo ----------------------------------------

if %PROJECT_COUNT%==0 (
    echo No Unreal projects found in "%PROJECT_BASE%"
    echo Make sure your projects contain .uproject files.
    echo.
    echo To reconfigure your project directory, delete: %CONFIG_FILE%
    pause
    exit /b 1
)

echo.
echo Found %PROJECT_COUNT% project(s).
echo.

REM Project selection
:project_selection
set /p PROJECT_CHOICE="Select project number (1-%PROJECT_COUNT%), 'c' to reconfigure paths, or 'q' to quit: "

if /i "%PROJECT_CHOICE%"=="q" goto :end
if /i "%PROJECT_CHOICE%"=="c" goto :reconfigure

REM Validate selection
if "%PROJECT_CHOICE%"=="" goto :invalid_selection
set /a CHOICE_NUM=%PROJECT_CHOICE% 2>nul
if %CHOICE_NUM% lss 1 goto :invalid_selection
if %CHOICE_NUM% gtr %PROJECT_COUNT% goto :invalid_selection

REM Set selected project variables
call set "PROJECT_NAME=%%PROJECT_%PROJECT_CHOICE%_NAME%%"
call set "PROJECT_DIR=%%PROJECT_%PROJECT_CHOICE%_PATH%%"
call set "PROJECT_FILE=%%PROJECT_%PROJECT_CHOICE%_FILE%%"

echo.
echo Selected project: %PROJECT_NAME%
echo Project path: %PROJECT_DIR%
echo Project file: %PROJECT_FILE%
echo.

REM ========================================
REM SIMPLE TARGET SETUP
REM ========================================
echo Setting up build target...

REM Use project name as game target (standard Unreal convention)
set "BUILD_TARGET=%PROJECT_NAME%"

echo Build Target: %BUILD_TARGET%
echo.

goto :continue_build

:reconfigure
echo.
echo Deleting configuration file: %CONFIG_FILE%
if exist "%CONFIG_FILE%" del "%CONFIG_FILE%"
echo Restarting for reconfiguration...
echo.
pause
"%~f0"
exit /b

:invalid_selection
echo Invalid selection. Please enter a number between 1 and %PROJECT_COUNT%, 'c' to reconfigure, or 'q' to quit.
goto :project_selection

:continue_build
REM Create Build and BuildLogs directories
set "BUILD_DIR=%PROJECT_DIR%\Build"
set "LOG_DIR=%PROJECT_DIR%\BuildLogs"
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM ========================================
REM VERSION MANAGEMENT
REM ========================================
set "VERSION_FILE=%PROJECT_DIR%\build_version.txt"

REM Get current version from file for display
set "CURRENT_VERSION=1"
if exist "%VERSION_FILE%" (
    set /p CURRENT_VERSION=<"%VERSION_FILE%"
    REM Validate version is numeric
    set /a TEST_VERSION=%CURRENT_VERSION% 2>nul
    if !errorlevel! neq 0 set "CURRENT_VERSION=1"
)

echo ========================================
echo VERSION MANAGEMENT
echo ========================================
echo Current latest version: %CURRENT_VERSION%
echo.

REM Show existing versions in Build folder
if exist "%BUILD_DIR%" (
    echo Existing build versions:
    echo ----------------------------------------
    set VERSION_EXISTS=false
    for /d %%d in ("%BUILD_DIR%\V*") do (
        set VERSION_EXISTS=true
        echo %%~nd
    )
    if "!VERSION_EXISTS!"=="false" (
        echo No previous builds found
    )
    echo ----------------------------------------
    echo.
)

REM Ask user for build version
:version_input
set /p USER_VERSION="Enter version number for this build (e.g., 1, 2, 1.5): "

if "%USER_VERSION%"=="" (
    echo Error: Version cannot be empty.
    goto :version_input
)

REM Check if version directory already exists
set "VERSION_BUILD_DIR=%BUILD_DIR%\V%USER_VERSION%"
if exist "%VERSION_BUILD_DIR%" (
    echo.
    echo ERROR: Version V%USER_VERSION% already exists!
    echo Directory: %VERSION_BUILD_DIR%
    echo.
    echo Please choose a different version number.
    goto :version_input
)

echo.
echo Build will be created in: %VERSION_BUILD_DIR%
set /p VERSION_CONFIRM="Is version %USER_VERSION% correct? (Y/n): "
if /i "%VERSION_CONFIRM%"=="n" goto :version_input

REM Create the version-specific build directory
mkdir "%VERSION_BUILD_DIR%"

echo.
echo Version V%USER_VERSION% confirmed.
echo.

REM Generate timestamp for logs
for /f "tokens=1-6 delims=/:. " %%a in ('echo %date% %time%') do (
    set "TIMESTAMP=%%c%%a%%b_%%d%%e%%f"
)

REM Ask for preset choice
echo.
echo Choose build configuration:
echo [1] Default Preset (Windows, Development, x64)
echo [2] Custom Configuration
echo.
set /p PRESET_CHOICE="Enter choice (1 or 2): "

if "%PRESET_CHOICE%"=="1" goto :default_preset
if "%PRESET_CHOICE%"=="2" goto :custom_preset
echo Invalid choice. Using default preset.
goto :default_preset

:default_preset
set "TARGET_PLATFORM=Win64"
set "BUILD_CONFIG=Development"
set "ARCHITECTURE=x64"
set "CLIENT_CONFIG=true"
set "SERVER_CONFIG=false"
set "STAGE_ONLY=false"
set "ARCHIVE=true"
set "FOR_DISTRIBUTION=false"
set "COMPRESS=false"
goto :build_project

:custom_preset
echo.
echo Custom Configuration Setup:
echo.

REM Target Platform Selection
echo.
echo Available platforms:
echo [1] Win64 (recommended)
echo [2] Linux
echo [3] Mac
echo [4] Android
echo [5] iOS
echo.
:platform_selection
set /p PLATFORM_CHOICE="Select platform (1-5): "

if "%PLATFORM_CHOICE%"=="1" set "TARGET_PLATFORM=Win64" & goto :config_selection
if "%PLATFORM_CHOICE%"=="2" set "TARGET_PLATFORM=Linux" & goto :config_selection
if "%PLATFORM_CHOICE%"=="3" set "TARGET_PLATFORM=Mac" & goto :config_selection
if "%PLATFORM_CHOICE%"=="4" set "TARGET_PLATFORM=Android" & goto :config_selection
if "%PLATFORM_CHOICE%"=="5" set "TARGET_PLATFORM=iOS" & goto :config_selection
echo Invalid selection. Please enter a number between 1 and 5.
goto :platform_selection

REM Build Configuration Selection
:config_selection
echo.
echo Available configurations:
echo [1] Development (recommended)
echo [2] Debug
echo [3] DebugGame
echo [4] Shipping
echo [5] Test
echo.
:config_choice
set /p CONFIG_CHOICE="Select configuration (1-5): "

if "%CONFIG_CHOICE%"=="1" set "BUILD_CONFIG=Development" & goto :arch_selection
if "%CONFIG_CHOICE%"=="2" set "BUILD_CONFIG=Debug" & goto :arch_selection
if "%CONFIG_CHOICE%"=="3" set "BUILD_CONFIG=DebugGame" & goto :arch_selection
if "%CONFIG_CHOICE%"=="4" set "BUILD_CONFIG=Shipping" & goto :arch_selection
if "%CONFIG_CHOICE%"=="5" set "BUILD_CONFIG=Test" & goto :arch_selection
echo Invalid selection. Please enter a number between 1 and 5.
goto :config_choice

REM Architecture Selection
:arch_selection
echo.
echo Available architectures:
echo [1] x64 (recommended)
echo [2] x86
echo [3] ARM64
echo [4] ARM
echo.
choice /c 1234 /n /m "Select architecture (1-4): "
set ARCH_CHOICE=%errorlevel%

if %ARCH_CHOICE%==1 set "ARCHITECTURE=x64"
if %ARCH_CHOICE%==2 set "ARCHITECTURE=x86"
if %ARCH_CHOICE%==3 set "ARCHITECTURE=ARM64"
if %ARCH_CHOICE%==4 set "ARCHITECTURE=ARM"

REM Client/Server build options
:client_server_options
echo.
set /p CLIENT_INPUT="Build Client? (Y/n): "
if /i "%CLIENT_INPUT%"=="n" (
    set "CLIENT_CONFIG=false"
) else (
    set "CLIENT_CONFIG=true"
)

set /p SERVER_INPUT="Build Server? (y/N): "
if /i "%SERVER_INPUT%"=="y" (
    set "SERVER_CONFIG=true"
) else (
    set "SERVER_CONFIG=false"
)

REM Additional options
set /p STAGE_INPUT="Stage only (no packaging)? (y/N): "
if /i "%STAGE_INPUT%"=="y" (
    set "STAGE_ONLY=true"
) else (
    set "STAGE_ONLY=false"
)

set /p ARCHIVE_INPUT="Archive build? (Y/n): "
if /i "%ARCHIVE_INPUT%"=="n" (
    set "ARCHIVE=false"
) else (
    set "ARCHIVE=true"
)

set /p DIST_INPUT="For Distribution? (y/N): "
if /i "%DIST_INPUT%"=="y" (
    set "FOR_DISTRIBUTION=true"
) else (
    set "FOR_DISTRIBUTION=false"
)

set /p COMPRESS_INPUT="Compress packages? (y/N): "
if /i "%COMPRESS_INPUT%"=="y" (
    set "COMPRESS=true"
) else (
    set "COMPRESS=false"
)

:build_project
echo.
echo ========================================
echo BUILD CONFIGURATION SUMMARY
echo ========================================
echo Project: %PROJECT_NAME%
echo Target: %BUILD_TARGET%
echo Platform: %TARGET_PLATFORM%
echo Configuration: %BUILD_CONFIG%
echo Architecture: %ARCHITECTURE%
echo Client Build: %CLIENT_CONFIG%
echo Server Build: %SERVER_CONFIG%
echo Stage Only: %STAGE_ONLY%
echo Archive: %ARCHIVE%
echo For Distribution: %FOR_DISTRIBUTION%
echo Compress: %COMPRESS%
echo Build Version: %USER_VERSION%
echo Output Directory: %VERSION_BUILD_DIR%
echo ========================================
echo.

set /p CONFIRM="Proceed with build? (Y/n): "
if /i "%CONFIRM%"=="n" goto :end

REM ========================================
REM SETUP LOG FILES
REM ========================================
set "BUILD_LOG_BASE=%LOG_DIR%\Build_v%USER_VERSION%_%TIMESTAMP%"
set "BUILD_LOG_BUILDING=%BUILD_LOG_BASE%_BUILDING.log"
set "BUILD_LOG_SUCCESS=%BUILD_LOG_BASE%_SUCCESS.log"
set "BUILD_LOG_FAILED=%BUILD_LOG_BASE%_FAILED.log"

REM ========================================
REM PACKAGING COMMAND
REM ========================================
REM Use RunUAT.bat BuildCookRun like the editor does
set "PACKAGE_CMD="%UAT_BAT%" BuildCookRun"
set "PACKAGE_CMD=!PACKAGE_CMD! -project="%PROJECT_FILE%""
set "PACKAGE_CMD=!PACKAGE_CMD! -noP4 -platform=%TARGET_PLATFORM%"
set "PACKAGE_CMD=!PACKAGE_CMD! -configuration=%BUILD_CONFIG%"
set "PACKAGE_CMD=!PACKAGE_CMD! -cook -build -stage"

if "%STAGE_ONLY%"=="false" set "PACKAGE_CMD=!PACKAGE_CMD! -package"
if "%ARCHIVE%"=="true" set "PACKAGE_CMD=!PACKAGE_CMD! -archive"
if "%FOR_DISTRIBUTION%"=="true" set "PACKAGE_CMD=!PACKAGE_CMD! -distribution"
if "%COMPRESS%"=="true" set "PACKAGE_CMD=!PACKAGE_CMD! -compressed"

REM Point the archive directory to our version-specific folder
set "PACKAGE_CMD=!PACKAGE_CMD! -archivedirectory="%VERSION_BUILD_DIR%""

echo Starting packaging process...
echo Target: %BUILD_TARGET%
echo Version: %USER_VERSION%
echo Command: !PACKAGE_CMD!
echo.
echo Build log: %BUILD_LOG_BUILDING%
echo.

REM Write build info to log
echo ======================================== > "%BUILD_LOG_BUILDING%"
echo UNREAL BUILD LOG >> "%BUILD_LOG_BUILDING%"
echo ======================================== >> "%BUILD_LOG_BUILDING%"
echo Build started at %date% %time% >> "%BUILD_LOG_BUILDING%"
echo Project: %PROJECT_NAME% >> "%BUILD_LOG_BUILDING%"
echo Target: %BUILD_TARGET% >> "%BUILD_LOG_BUILDING%"
echo Platform: %TARGET_PLATFORM% >> "%BUILD_LOG_BUILDING%"
echo Configuration: %BUILD_CONFIG% >> "%BUILD_LOG_BUILDING%"
echo Version: %USER_VERSION% >> "%BUILD_LOG_BUILDING%"
echo Output: %VERSION_BUILD_DIR% >> "%BUILD_LOG_BUILDING%"
echo Command: !PACKAGE_CMD! >> "%BUILD_LOG_BUILDING%"
echo. >> "%BUILD_LOG_BUILDING%"

REM Execute the build command with real-time progress in current window
echo Executing build command...
echo This may take several minutes...
echo.
echo ========================================
echo    REAL-TIME BUILD PROGRESS
echo    %PROJECT_NAME% v%USER_VERSION%
echo    %TARGET_PLATFORM% / %BUILD_CONFIG%
echo ========================================
echo.

REM Use PowerShell to tee the output (show on screen AND log to file)
powershell -Command "& { !PACKAGE_CMD! } | Tee-Object -FilePath '%BUILD_LOG_BUILDING%' -Append"
set BUILD_EXIT_CODE=!errorlevel!

REM Check build result and rename log file accordingly
if !BUILD_EXIT_CODE! neq 0 (
    echo. >> "!BUILD_LOG_BUILDING!"
    echo ======================================== >> "!BUILD_LOG_BUILDING!"
    echo [FAILED] Build failed at %date% %time% >> "!BUILD_LOG_BUILDING!"
    echo [ERROR] Exit code: !BUILD_EXIT_CODE! >> "!BUILD_LOG_BUILDING!"
    echo ======================================== >> "!BUILD_LOG_BUILDING!"
    
    REM Rename to failed log
    move "!BUILD_LOG_BUILDING!" "!BUILD_LOG_FAILED!" >nul
    
    REM Remove the version directory since build failed
    if exist "%VERSION_BUILD_DIR%" (
        echo Removing failed build directory...
        rmdir /s /q "%VERSION_BUILD_DIR%"
    )
    
    echo.
    echo ========================================
    echo BUILD FAILED! (Version !USER_VERSION!)
    echo ========================================
    echo Build failed at %date% %time%
    echo Exit code: !BUILD_EXIT_CODE!
    echo Target: !BUILD_TARGET!
    echo Version: !USER_VERSION!
    echo.
    
    REM Show relevant error info
    echo Checking for common issues...
    findstr /i "error" "!BUILD_LOG_FAILED!" | findstr /v "warning" > nul
    if !errorlevel! equ 0 (
        echo.
        echo Critical errors found:
        echo ----------------------------------------
        findstr /i "error" "!BUILD_LOG_FAILED!" | findstr /v "warning"
    )
    
    echo ----------------------------------------
    echo.
    echo Full build log: !BUILD_LOG_FAILED!
    
) else (
    REM Update the version file with the current build version (latest successful)
    echo %USER_VERSION% > "%VERSION_FILE%"
    
    echo. >> "!BUILD_LOG_BUILDING!"
    echo ======================================== >> "!BUILD_LOG_BUILDING!"
    echo [SUCCESS] Build completed at %date% %time% >> "!BUILD_LOG_BUILDING!"
    echo [INFO] Version !USER_VERSION! packaged successfully >> "!BUILD_LOG_BUILDING!"
    echo [INFO] Version file updated to !USER_VERSION! >> "!BUILD_LOG_BUILDING!"
    echo ======================================== >> "!BUILD_LOG_BUILDING!"
    
    REM Rename to success log
    move "!BUILD_LOG_BUILDING!" "!BUILD_LOG_SUCCESS!" >nul
    
    echo.
    echo ========================================
    echo BUILD SUCCESSFUL! (Version !USER_VERSION!)
    echo ========================================
    echo Build completed at %date% %time%
    echo Target: !BUILD_TARGET!
    echo Version: !USER_VERSION!
    echo Output: !VERSION_BUILD_DIR!
    echo Latest version updated to: !USER_VERSION!
    echo.
    
    REM Show build artifacts
    if exist "!VERSION_BUILD_DIR!" (
        echo Build artifacts in V!USER_VERSION!:
        echo ----------------------------------------
        dir /b "!VERSION_BUILD_DIR!"
        echo ----------------------------------------
        echo.
    )
    
    echo Build log: !BUILD_LOG_SUCCESS!
)

:end
echo.
pause