# SHIPS v0.1 testing evidence (2026-11-12)

## Completed
- Original source assembled with `as --32` and linked with `ld -m elf_i386 -Ttext 0x100 --oformat binary`; `.arch i8086` assembly PASS.
- DOSBox-X 2026.10.01 on SLOW1, cputype 8086, machine CGA, 240 cycles/ms, `SHIPS.COM /TEST`: **PASS**, DOS batch checks ERRORLEVEL 0.
- Actual installed binary: `C:\Ships\SHIPS.COM`, 20907 bytes.
- SHA256 installed: `2f28d989fe967c71b7a2dffb767438c8bc37b792f2f9753f38bec3febf865149`.
- `C:\Ships\RUN-CGA.cmd` and `RUN-XT.cmd` are separate from the TANKS installation.

## Not yet verified
- Native XT 4.77 MHz hardware FPS and memory tests.
- A fully played 12-enemy wave and collision behavior observed via screen capture.
- Native EGA/VGA, AdLib/Sound Blaster music and sound, CGA sound effects audibility.
- True cycle/clock-accuracy claim (240 cycles/ms is a consistency setting only).

Do not promote this developer snapshot to a fully accepted formal release without these checks.
