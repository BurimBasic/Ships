# SHIPS — 8086 XT/CGA naval defense

**First playable developer prototype v0.1 (2026-11-12).** Pure DOS `.COM`, original 8086 assembly, 320×200×4 CGA. The target is an IBM PC XT 4.77 MHz. **Physical XT throughput is not yet measured.**

## Get started

- [Download the current development SHIPS.COM](dist/SHIPS.COM) — 20,907 bytes, SHA256 `2f28d989fe967c71b7a2dffb767438c8bc37b792f2f9753f38bec3febf865149`.
- On SLOW1: `C:\Ships\RUN-CGA.cmd` (DOSBox-X with CGA/8086, 1000 cycles/ms, convenient play) or `C:\Ships\RUN-XT.cmd` (240 cycles/ms, exploratory low-speed profile).
- With any DOSBox-X: mount a directory containing `SHIPS.COM` as C:, choose CGA and cputype=8086, run `SHIPS.COM`.
- Built-in self-check: `SHIPS.COM /TEST`. Confirm **DOS errorlevel 0**; the result has been verified on SLOW1 with DOSBox-X 2026.10.01, CGA, 8086, fixed 240 cycles/ms (PASS). This is a limited unit smoke test, not an end-to-end campaign benchmark.

## Gameplay

Defend the **HARBOR** in the lower part of an ocean map: **a shell or torpedo hitting it means immediate defeat.** The player is a destroyer with **three lives**; ramming another ship kills the player and enemy, with respawn while lives remain. The first stage contains **12 enemies**, including surface destroyers and submerged submarines.

- Blue/cyan ocean is navigable; magenta rocks can be destroyed with shells or torpedoes; pale shoals/land are impassable and cannot be destroyed.
- The ship **accelerates automatically** during sustained motion: low, medium and full ahead appear as HUD stage **1/2/3**. These stages are **not selectable keys**. On releasing controls, the ship coasts and slows because of inertia. Turns redirect thrust instead of teleporting the ship.
- The destroyer fires in its facing direction. There is only **one active player shell**, and it splashes/sinks after ~96 pixels of travel, so it cannot cross the whole map.
- A **mine** is dropped at the ship and remains until a ship detonates it; only **one active mine** may exist. The player can also hit its own armed mine.
- Submarines are represented by a small periscope/water ring rather than a full hull, and launch torpedoes shown with a bubble trail. The AI approaches the harbor, reacts to rocks and avoids simple stuck states; behavioral difficulty has not been calibrated with a full win test.
- PC Speaker sound effects are implemented, and can be disabled. **AdLib, Sound Blaster and music playback are not implemented in v0.1**, despite being intended future features.

## Controls

| Key | Action |
|---|---|
| **W A S D** | Push in north, west, south, east direction; automatic acceleration and coasting |
| **Either Shift** | Fire forward (only if previous shell has disappeared) |
| **Ctrl** | Lay mine (one active at a time) |
| **P** | Pause/resume |
| **R** | Restart campaign |
| **Space** | Advance after clearing a wave |
| **Esc** | Quit to DOS |

The current executable includes a sound effect but `M` sound muting is reserved for a later version.

## Platform and testing honesty

| Platform | Status |
|---|---|
| DOSBox-X, 8086, CGA mode 4 | **/TEST PASS** on SLOW1; visual gameplay not yet fully accepted |
| Physical XT 4.77MHz + CGA | **Not tested** |
| EGA/VGA in CGA compatibility mode | **Not tested for SHIPS** |
| Native EGA 16-color / native VGA 256-color | **Not implemented** |
| AdLib / Sound Blaster | **Not implemented** |

A screenshot of the actual v0.1 gameplay has **not** been captured. Do not mistake artwork or source diagrams for tested emulator screenshots. The code uses a dedicated 16,384-byte background image in memory and a dirty-sprite restoration path; workload FPS/performance has not yet been measured against a physical XT or formal reference.

## Source and development

`src/ships.S` uses GNU binutils (`as --32` and `ld -m elf_i386 -Ttext 0x100 --oformat binary`); `.arch i8086` rejects non-8086 instructions. Run `make clean all test`. Static verification enforces the source architecture, binary size, and DOS header shape. See [AGENTS.md](AGENTS.md) and [testing](docs/TESTING.md).

This is a **development snapshot**, not a formally validated v1.0 release. The previous **TANKS** project and its files are independent and unchanged.
