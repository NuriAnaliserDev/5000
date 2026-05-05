@echo off
title GeoField Pro: Install & Logcat
echo ==========================================
echo   GeoField Pro: AI Lithology System
echo ==========================================
echo [DEVICE]: 24116RACCG (Android 16)
echo [JDK]: C:\jdk-26_windows-x64_bin\jdk-26.0.1
echo ------------------------------------------

:: Java yo'lini sozlash
set JAVA_HOME=C:\jdk-26_windows-x64_bin\jdk-26.0.1
set PATH=%JAVA_HOME%\bin;%PATH%

echo [1/2] Ilova yig'ilmoqda va o'rnatilmoqda...
:: -v (verbose) loglarni batafsil ko'rish uchun
flutter run -d emeqibamq449yd89 --debug

echo ------------------------------------------
echo Build yakunlandi yoki to'xtatildi.
pause
