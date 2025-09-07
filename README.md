# Unreal Project Packaging Tool

![Static Badge](https://img.shields.io/badge/Version-2.2-blue) ![Static Badge](https://img.shields.io/badge/Platform-Windows-0078d7)

A Windows batch script that packages Unreal Engine projects so you don't have to remember the UAT command line arguments.

## How to Use

1.  Download the `.bat` file.
2.  Run it. It will ask you where your Unreal Engine is installed and where you keep your projects.
3.  It finds all your `.uproject` files and lets you pick one.
4.  Choose a version number and some build settings.
5.  It runs the build and puts the result in a `Build` folder, sorted by version.

The script saves your paths so you only have to set it up once.

## What It Does

*   Finds all your Unreal projects automatically.
*   Remembers your engine and project folder paths.
*   Runs `RunUAT.bat BuildCookRun` with the right flags.
*   Keeps different versions of your builds separate (V1, V2, V3...).
*   Saves a log file every time, so you can see why a build failed.