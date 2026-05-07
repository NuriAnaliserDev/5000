@echo off
setlocal
cd /d "%~dp0.."

echo == flutter analyze ==
call flutter analyze || exit /b 1
echo == flutter test ==
call flutter test || exit /b 1
echo == flutter build apk --debug ==
call flutter build apk --debug || exit /b 1
echo == OK ==
exit /b 0
