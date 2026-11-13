# SHIPS v0.8 — playable XT/CGA development build

**Date**: 2026-11-13. **File**: `dist/SHIPS.COM`, 41,172 bytes. **SHA256**: `4ad4cfe08e56c5c6d0c1e04855b28b4e8ac9fb727b1d1ca0dd9533ad2b8a117c`.

### Changes

- Offscreen 16KB CGA scene, dirty-scanline compositor, no black/blank frames during object restoration. Removed flashing invulnerability hull.
- Automatic slow/medium/full ahead, longer inertia/coast, momentum-dependent heading change. No separate throttle keys.
- Reworked naval chart: expanded ocean channels for 24×24 warships, destructible rocks and solid land preserved.
- Four separate shortest-path maps with clearance for the full hull, different attack stations, timed patrol, wait-on-block instead of crowding at one point, more deliberate spawn pacing and firing.
- Run launchers restored to realistic *nominal* DOSBox-X cycles instead of extreme slow 240 cycles/ms used only for stress tests. Nominal cycle speed is not cycle-accurate proof of a physical 8088.

### QA

DOSBox-X 8086/CGA `/TEST` PASS; 600-step automatic run with zero overlapping enemy pairs in six snapshots; verified actual in-emulator CGA images. 120-step stress benchmark +24% vs old flickering engine (not a real hardware performance test). A full player-completed wave is outstanding.

### Controls

WASD helm/acceleration; Shift forward gun; Ctrl mine; P pause; R restart; M PC Speaker toggle; Space continue; Esc quit.

### Roadmap

Physical XT 4.77MHz acceptance; separate native EGA/VGA; AdLib/Sound Blaster auto-detect; more tactical AI and combat balance. None of these are claimed as complete.
