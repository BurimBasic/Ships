# SHIPS development and release rules

- Develop **real-mode 8086/8088, XT 4.77MHz, CGA 320×200** first. No 186+ instructions or DOS extenders, no external game assets. Do not modify TANKS or share its game directory. Keep `C:\Ships` isolated on SLOW1.
- Ship a real **DOS .COM** below 56 KiB, reserve stack room in the 64KiB COM segment. Verify with GNU `.arch i8086`, a reproducible build, checksum and `SHIPS.COM /TEST` under DOSBox-X.
- New features must have **real DOSBox-X visual captures**, and test behavior over a full simulated wave where practical. A /TEST PASS **alone never certifies gameplay**.
- **No frame flickering**: render offscreen, mark dirty CGA spans, commit final pixels. Watch expensive VRAM operations on XT. Compare old/new frame timings under the same settings. Do not claim fixed emulated cycles imply real 4.77MHz performance.
- **No frozen or overlapping NPC stacks**: path clearance must account for the *full* ship hull, not just tile center; test enemy separation at multiple simulation frames. Enemy ship behavior must be winnable, with varied paths and tactical positioning.
- Player controls: WASD helm, Shift shell, Ctrl one active mine. Slow, medium, full ahead happen automatically as motion builds. Model inertia, drag and delayed turns. Never map gear modes to keys 1/2/3.
- Use SLOW1 isolated `C:\Ships\work\<version>` build stage, install backup and checksum; deploy only after DOSBox /TEST PASS and reviewed CGA captures, then **retest installed binary**. No claim of success without actual proof.
- Keep README and notes synchronized with the exact shipped build and tests. Statuses: CGA/8086 software and PC Speaker effects implemented; physical XT acceptance, native EGA/VGA, AdLib/Sound Blaster auto-detection/music remain **open**.
