@echo off
REM Firebase Firestore qoidalarini default loyihaga yuboradi.
REM Talab: firebase CLI va firebase login
cd /d "%~dp0\.."
firebase deploy --only firestore:rules
if errorlevel 1 exit /b 1
echo.
echo OK: firestore rules deployed.
pause
