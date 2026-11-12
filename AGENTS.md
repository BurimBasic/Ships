# AGENTS.md — SHIPS development and release rules

- Ship a real DOS `.COM` for **8086/8088, 4.77MHz XT, CGA 320x200 mode 4** first; no 186/286+, protected mode, external runtime, 32-bit prefixes, or DOS extenders. Use `.arch i8086` in GNU as and verify all emitted instructions.
- Keep the binary **strictly less than 56 KiB**, and preserve ~4 KiB of stack space in the 64 KiB COM segment. All game graphics, maps, state and configuration must work from memory with no mandatory external data files.
- Performance matters: use fixed ticks from the BIOS clock, bounded enemy counts, static arrays, dirty-sprite restore; test at fixed 240 cycles/ms in DOSBox-X (8086 CGA) and separately compare responsiveness with the real XT. DOSBox cycles are NOT cycle-accurate proof of 4.77MHz physical hardware.
- Never confuse CGA-compatible operation under EGA/VGA with native video support. Implement native EGA/VGA rendering as separate tested backends later.
- Protect the earlier TANKS installation. Use dedicated `C:\Ships` on SLOW1 and reuse only the DOSBox-X executable; no shared game data or overwrite.
- Must pass `make clean all test`, 8086 ISA inspection, `SHIPS.COM /TEST` in DOSBox-X, visual gameplay and first-wave full-clear checks, performance tests, followed by install+SHA256 verification and installed-file retest **before** labeling a formal release. Include captures and caveats.
- For each released version update README with exact features, full key table, download link to exact tested binary, build SHA, screenshots from the actual emulator, tested adapter modes, known gaps and rollback details. Do not assert any unperformed test.
- Do not invent a feature status. AdLib/Sound Blaster automatic detect, music, native EGA/VGA, enemy AI balancing and physical XT acceptance are future work until proven.
- Use user controls: WASD, Shift forward shell, Ctrl one mine; automatic acceleration through low/medium/full ahead, with inertia. The engine stages are displayed, **never mapped to 1/2/3 hotkeys**.
