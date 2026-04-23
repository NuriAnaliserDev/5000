@echo off
:: Loyiha papkasiga o'tish
cd /d "C:\5000\geotag_pro_flutter"

set ADB_EXE="C:\Users\New\Desktop\platform-tools\adb.exe"

echo -------------------------------------------------------
echo TELEFONDA LOGLARNI KO'RISH (DEBUG)
echo -------------------------------------------------------
echo 1. Telefoningizda Wi-Fi debugging yoqing.
echo 2. Telefon ekranidagi "IP manzil va port"ni to'liq kiriting.
echo    (Masalan: 192.168.13.65:40185)
echo.

set /p FULL_ADDRESS="Manzilni kiriting: "

echo.
echo Ulanmoqda: %FULL_ADDRESS%...
%ADB_EXE% disconnect
%ADB_EXE% connect %FULL_ADDRESS%

echo.
echo 3. Dastur o'rnatilmoqda va loglar boshlanmoqda...
:: pubspec.yaml borligini tekshirish
if not exist pubspec.yaml (
    echo Xatolik: pubspec.yaml topilmadi!
    echo Iltimos, bat faylni loyiha papkasiga joylang.
    pause
    exit /b
)

call flutter run -d %FULL_ADDRESS%

pause
