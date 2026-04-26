@echo off
cd /d "C:\5000\geofield_pro_flutter"

echo -------------------------------------------------------
echo QURILMALARNI BOSHQARISH
echo -------------------------------------------------------
echo 1. Ulangan qurilmalar ro'yxati:
call flutter devices

echo.
echo -------------------------------------------------------
echo TANLANG:
echo [1] Ikkala qurilmada baravar ishga tushirish (Run on ALL)
echo [2] Faqat Pixel 9 (Emulator) da ishga tushirish
echo [3] Faqat USB dagi telefonda ishga tushirish
echo -------------------------------------------------------
echo.

set /p CHOICE="Tanlovingizni kiriting (1, 2 yoki 3): "

if "%CHOICE%"=="1" (
    echo Ikkala qurilmaga o'rnatilmoqda...
    call flutter run -d all
)
if "%CHOICE%"=="2" (
    echo Pixel 9 ga o'rnatilmoqda...
    :: Odatda emulyator ID si emulator-5554 bo'ladi
    call flutter run -d emulator
)
if "%CHOICE%"=="3" (
    echo USB telefonga o'rnatilmoqda...
    :: Jismoniy qurilmani avtomatik tanlash uchun
    call flutter run -d android
)

pause
