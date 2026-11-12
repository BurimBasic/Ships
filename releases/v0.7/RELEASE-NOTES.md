# SHIPS v0.7 — 2026-11-12 (XT/CGA development release)

**Installed on SLOW1**: `C:\Ships\SHIPS.COM`, size **38,944 bytes**, SHA256 `d3b4e9c130dfbb54effbad3d33f91d806ce4d6e93ca2aa2d50caf2e07ea2f575`.

### Changed from v0.1

- Completely rewritten top-down CGA graphics: navy ocean, less aggressive colors, original 24×24 detailed destroyer graphics in all directions, distinct enemy destroyers/submarines, static rocky reefs, improved docks and irregular coastline.
- Gradual slow/medium/full ahead with drifting momentum; moved from 8×8 icons toward recognizable warship silhouettes. Surface ship wakes, enemy acceleration and persistent obstacle-flank steering.
- Real DOSBox video captures in `docs/screenshots`.
- Deterministic `/TEST` PASS before and after guarded deployment; 600-step diagnostic confirms enemies advancing and reaching harbor-loss condition.

### Controls

WASD propulsion; Shift shell; Ctrl one mine; P pause; R restart; M sound; Space next stage; Esc exit. Slow/medium/full ahead are **automatic**, not selectable hotkeys.

### Tested and untested

CGA and 8086 under DOSBox-X 2026.10.01, 240 cycles/ms, /TEST PASS. Screenshot/longer AI diagnostic PASS. A full natural player victory, physical XT 4.77 MHz timing, native EGA/VGA and AdLib/Sound Blaster support are **not verified or not implemented**. PC Speaker only.

### Rollback

Previous installed COM backed up in `C:\Ships\backups\SHIPS-before-v07-07BE2FF42FDB.COM`; make a copy before any future deploy and restore atomically if new checks fail. Do **not** modify TANKS.
