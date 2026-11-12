@echo off
setlocal
set "EMU=C:\XT-Battle-City\tools\dosbox-x\mingw-build\mingw-sdl2\dosbox-x.exe"
if not exist "%EMU%" (echo DOSBox-X not found & exit /b 1)
"%EMU%" -defaultconf -set "machine=cga" -set "cputype=8086" -set "cycles=fixed 240" -set "captures=C:\Ships\captures" -c "mount c C:\Ships" -c "c:" -c "SHIPS.COM"
