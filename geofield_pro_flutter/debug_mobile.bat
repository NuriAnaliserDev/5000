@echo off
title GeoField Pro Mobile Debugger
echo ==========================================
echo   GeoField Pro: AI Lithology Debugger
echo ==========================================
echo [DEVICE]: 24116RACCG (Android 16)
echo [JDK]: C:\jdk-26_windows-x64_bin\jdk-26.0.1
echo [MODE]: DEBUG
echo ------------------------------------------

:: Set Java Path
set JAVA_HOME=C:\jdk-26_windows-x64_bin\jdk-26.0.1
set PATH=%JAVA_HOME%\bin;%PATH%

:: Ilovani ishga tushirish
flutter run -d emeqibamq449yd89 --debug

echo ------------------------------------------
echo Debug sessiyasi yakunlandi.
pause
