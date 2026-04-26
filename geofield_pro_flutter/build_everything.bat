@echo off
setlocal
cd /d "C:\5000\geofield_pro_flutter"

echo =======================================================
echo   GEOFIELD PRO - TO'LIQ QURILISH (BUILD) JARAYONI
echo =======================================================

echo.
echo 1. Eski fayllarni tozalamoqda (Clean)...
call flutter clean

echo.
echo 2. Paketlarni yuklamoqda (Pub get)...
call flutter pub get

echo.
echo 3. Kod generatorlarini ishga tushirmoqda (Build Runner)...
:: Hive va boshqa modellar uchun kod yaratish
call dart run build_runner build --delete-conflicting-outputs

echo.
echo 4. Ilova ikonkasini o'rnatmoqda (Launcher Icons)...
call dart run flutter_launcher_icons

echo.
echo 5. APK fayli yaratilmoqda (Build APK)...
call flutter build apk --release --tree-shake-icons

echo.
echo 6. AppBundle yaratilmoqda (Google Play uchun)...
call flutter build appbundle --release

echo.
echo =======================================================
echo   MUVAFFAQIYATLI YAKUNLANDI!
echo =======================================================
echo.
echo APK manzili:
echo   build\app\outputs\flutter-apk\app-release.apk
echo.
echo AppBundle manzili:
echo   build\app\outputs\bundle\release\app-release.aab
echo.
echo =======================================================
pause
