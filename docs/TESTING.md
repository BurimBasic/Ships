# SHIPS v0.7 — TESTING (12 November 2026)

## Evidence actually collected

1. GNU `as --32` with `.arch i8086` built `src/ships.S`; `ld -m elf_i386 -Ttext 0x100 --oformat binary` produced a valid **38,944-byte** DOS COM. The binary is below **57,344 bytes**. Rebuild SHA256: `d3b4e9c130dfbb54effbad3d33f91d806ce4d6e93ca2aa2d50caf2e07ea2f575`.
2. On **SLOW1** with **DOSBox-X 2026.10.01**, CGA mode, emulated **8086**, fixed **240 cycles/ms**, `SHV07.COM /TEST` returned DOS **ERRORLEVEL 0** and logged `SHIPS /TEST PASS`.
3. Captured actual 16,384-byte B800 VRAM at start / after 120 simulation steps, converted without filtering to PNG. Viewed the captures manually and verified ship sprites, navy-blue sea, land, rocks, wake and HUD.
4. A dedicated diagnostic candidate, **not the shipped binary**, adjusted just the `/CAP` simulation count from 120 to 600 steps. Three initial enemy coordinates changed substantially, including one arriving around **(135,138)**; a later frame visibly showed **HARBOR LOST**. This confirms enemy movement and loss behavior, not balancing or a complete win.
5. Atomic-on-volume installation on SLOW1: `C:\Ships\SHIPS.COM`, exactly 38,944 bytes. Previous COM backed up under `C:\Ships\backups\`. Installed `SHIPS.COM /TEST` reran in DOSBox-X at 240 cycles/ms and **PASS**; post-install SHA256 matched. SLOW1's separate TANKS directory was untouched.

## Not yet accepted

- Physical IBM PC XT 4.77 MHz speed and memory checks; 240 emulator cycles/ms is a repeatable testing configuration, **not proof of a real 8088's instruction timing**.
- Complete player-controlled stage clear, 10-minute input/audio endurance, cooperative mode, native EGA/VGA.
- Full future audio: AdLib, Sound Blaster auto detection, music. Only PC Speaker effects implemented.
- No unrelated adapter screenshot should be fabricated. Use actual screenshots per backend when a backend exists.

## Repro commands (SLOW1)

`C:\Ships\RUN-CGA.cmd` — interactive DOSBox-X CGA/8086.

`C:\Ships\RUN-XT.cmd` — lower-speed diagnostic profile.

From a separate DOSBox-X CGA machine: mount `C:\Ships` as C:, run `SHIPS.COM /TEST`, inspect ERRORLEVEL immediately (zero is PASS). Run `SHIPS.COM` without parameters for manual play. Use R for restart and P for pause.

Static Linux CI checks `make clean all test` and exact binary SHA. CI is not a substitute for DOSBox gameplay checks.
