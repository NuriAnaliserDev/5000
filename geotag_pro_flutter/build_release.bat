@echo off
cd /d "C:\5000\geotag_pro_flutter"

echo 1. Keraksiz fayllarni tozalamoqda (Cleaning)...
call flutter clean

echo.
echo 2. Dependency-larni yangilamoqda (Pub get)...
call flutter pub get

echo.
echo 3. Release APK faylini yaratish boshlandi (Bu bir necha daqiqa vaqt olishi mumkin)...
call flutter build apk --release

echo.
echo -------------------------------------------------------
echo TAYYOR!
echo Release APK fayli quyidagi manzilda joylashgan:
echo C:\5000\geotag_pro_flutter\build\app\outputs\flutter-apk\app-release.apk
echo -------------------------------------------------------
echo.
pause
