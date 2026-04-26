@echo off
:: Loyiha papkasiga o'tish
cd /d "C:\5000\geofield_pro_flutter"

:: ADB manzili (Siz ko'rsatgan Desktopdagi joy)
set ADB_EXE="C:\Users\New\Desktop\platform-tools\adb.exe"

echo -------------------------------------------------------
echo TELEFONDA LOGLARNI KO'RISH (DEBUG)
echo -------------------------------------------------------
echo 1. Telefoningizda Wi-Fi debugging yoqilganligini tekshiring.
echo 2. IP manzil va PORTni kiriting.
echo.

set /p FULL_ADDRESS="Manzilni kiriting (Masalan: 192.168.13.63:37253): "

echo.
echo Ulanmoqda: %FULL_ADDRESS%...
%ADB_EXE% disconnect
%ADB_EXE% connect %FULL_ADDRESS%

echo.
echo Ilova yuklanmoqda va loglar boshlanmoqda...
:: pubspec.yaml borligini tekshirish
if not exist pubspec.yaml (
    echo Xatolik: pubspec.yaml topilmadi!
    pause
    exit /b
)

:: Ilovani yurgizish
call flutter run -d %FULL_ADDRESS%

pause
