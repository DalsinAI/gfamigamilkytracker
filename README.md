# GFAmigaMilkyTracker

MilkyTracker, the FastTracker II style music tracker, for GFOS (AmigaOS 3.2.3 with GFOpenUp), installed as a GFOpenUp part.

- Needs a 68040 (the FPU is used when there is one) and the GFOpenGPU part, whose SDL 2 draws the window and plays the sound.
- Install: `GFOpenUpTool INSTALL Parts/MilkyTracker`. It goes to `SYS:Utilities/MilkyTracker`, with upstream's free example songs in `Songs`.
- Settings are kept in `PROGDIR:User/MilkyTracker.config`; temporary files go to `T:`.
- The file browser understands AmigaDOS paths: Parent goes up a drawer, Root goes to the volume.
- `MilkyTracker -headless -output RAM:song.wav Songs/milky.xm` renders a song to a WAV file without a window.
- Not yet: opening modules from inside .zip, .gz or .lha archives, and MIDI input.

Build with a stove: `STOVE=.../os32-gcc16-open6 OUT=out ./build-amiga.sh`. MilkyTracker itself is fetched at the commit in `milkytracker.lock` and patched with `patches/`; nothing third-party is kept here. Host tests: `make -C tests test`.

MilkyTracker is GPL 3 or later (see LICENSE); so is this port.

Designed, tested and delivered by The AmiCradle Team.
