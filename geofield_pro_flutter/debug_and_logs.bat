@echo off
setlocal EnableDelayedExpansion
:: Batch fayl qayerda turgan bo'lsa, shu loyiha ildiziga o'tish (pubspec.yaml shu yerda)
cd /d "%~dp0"

:: ADB (o'zgartiring agar boshqa joyda bo'lsa)
set "ADB_EXE=C:\platform-tools\adb.exe"

echo -------------------------------------------------------
echo TELEFONDA LOGLARNI KO'RISH (DEBUG^)
echo Loyiha: %CD%
echo -------------------------------------------------------
echo 1. Telefoningizda Wi-Fi debugging yoqing.
echo 2. Telefon ekranidagi "IP manzil va port"ni kiriting.
echo    (Masalan: 192.168.13.65:40185^)
echo.

if not exist "%ADB_EXE%" (
    echo Xatolik: ADB topilmadi: %ADB_EXE%
    echo platform-tools yuklab, yo'lni skript boshida to'g'rilang.
    pause
    exit /b 1
)

if not exist "pubspec.yaml" (
    echo Xatolik: pubspec.yaml topilmadi!
    echo Joriy papka: %CD%
    echo Bu .bat faylni geofield_pro_flutter ildiziga qo'ying.
    pause
    exit /b 1
)

set /p FULL_ADDRESS="Manzilni kiriting: "

echo.
echo Ulanmoqda: !FULL_ADDRESS!...
"%ADB_EXE%" disconnect
"%ADB_EXE%" connect !FULL_ADDRESS!

echo.
echo 3. Dastur o'rnatilmoqda va loglar boshlanmoqda...
call flutter run -d !FULL_ADDRESS!

pause
endlocal
