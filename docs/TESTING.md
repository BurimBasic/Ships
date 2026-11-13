# SHIPS v0.8 testing evidence — 2026-11-13

**Release binary** `dist/SHIPS.COM` and SLOW1 `C:\Ships\SHIPS.COM`:
- SHA256: `75575e760b0390df7a9fc76bcf29534f1b7f9872aa36aeadb88eb158ec096d60`
- Bytes: **41,171**
- CPU: **8086/8088** (GNU `.arch i8086`, no 186+ instructions)
- Video: **CGA 320×200, 4 colors**.

## Test sequence

1. Build on SLOW1 using MSYS2 GNU Binutils 2.47 (`as --32`, PE intermediate with custom DOS image linker script, `objcopy -O binary`); the Windows intermediate COM was 41,172 bytes ending in one linker padding NOP (0x90); the released image trims that final NOP to 41,171 bytes to be byte-identical to the Linux ELF image. The source is independently buildable with Linux `make clean all test`.
2. On DOSBox-X 2026.10.01, 8086, CGA, `cycles=fixed 240`: `SHV13.COM /TEST` produced `SHIPS /TEST PASS` and exit code 0.
3. **Unattended 600-step /CAP run** in DOSBox-X, 8086, CGA at 2000 cycles/ms; saved 3 B800 VRAM frames and all four 12-byte enemy records at six sampling points. No overlaps found at samples 100,200,300,400,500,600, using a 23×21 hull-spacing check.
4. At step 600, the four active enemies were in distinct positions: **(136,109), (88,136), (184,136), (136,88)**. Recorded movement in multiple earlier intervals; no standing stack at the harbor.
5. Actual video framebuffer PNGs were viewed and compared. The original visible erase–draw–erase phase was eliminated in source; new board uses dirty spans from an offscreen 16KB DOS memory allocation.
6. Paired performance run on same SLOW1 and DOSBox-X profile, 120-step diagnostic `/CAP`, fixed240: v0.7 7.724s and 7.720s, median 7.722s; v0.8 9.576s and 9.558s, median 9.567s, ratio 1.239. Faster than the intermediate 13.47s candidate, still **24% slower than old v0.7** at this artificial low-cycles stress profile. Do not conflate this with measured actual XT FPS.

## Correctness caveats

- No-input simulations intentionally lose the harbor when an enemy shell reaches it. They **do not** prove a human can win wave 1 or that all 12 enemies can be sunk.
- The 600-step simulation checks *sampled* positions, not every intermediate frame. The object collision routine separately rejects a 23×21 predicted hull overlap before movement.
- Emulated cycles and DOSBox-X do not certify actual IBM PC XT timings. Real XT 4.77MHz testing and controlled keypress/audio tests still needed.
- Native EGA/VGA, automatic AdLib/Sound Blaster detection and original music are **not yet implemented**.

## Rollback

On SLOW1 the previous installed SHIPS.COM is backed up under `C:\Ships\backups\`. Use a separate folder from TANKS. Never overwrite installed release before release checksum and `/TEST` are successful.

Reproducibility repair: the Windows PE-based linker introduced one trailing NOP, absent from the Linux link result. The padded and unpadded images both passed real DOSBox-X /TEST. The distributed file is the **unpadded 41,171-byte version**, matching Linux SHA256 exactly.
