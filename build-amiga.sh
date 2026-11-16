#!/bin/sh
# Builds MilkyTracker for GFOS (AmigaOS 3.2.3 with GFOpenUp, on the GFOpenKick
# ROM or a Kickstart) with a stove: 68040, soft float with the FPU taken when
# there is one (fpuauto), on the stove's SDL 2 (GFOpenGPU's link stubs).
#   STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh
# MilkyTracker and fpuauto are fetched at the commits milkytracker.lock gives;
# nothing third-party is kept here. The build tree is kept, so a run that stops
# at BUDGET_TOTAL seconds goes on next time.
# OUT gets Parts/MilkyTracker: a GFOpenUp part (its Part file and the files it
# puts in SYS:Utilities/MilkyTracker; it needs the GFOpenGPU part, whose
# SDL2.module draws the window and plays the sound), installed with
#   GFOpenUpTool INSTALL Parts/MilkyTracker
# The songs upstream ships (resources/music, free) go in its Songs drawer.
# MilkyTracker -headless -output T:x.wav Songs/milky.xm renders a song with no
# window and no sound device: the lab check.
# Copyright (c) 2026 AmiCradle Team. GPL 3 or later, like MilkyTracker.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/milkytracker.lock"
STOVE=${STOVE:-"$HOME/AmiCradle/stoves/os32-gcc16-open6"}
# outside the checkout: Cradle cleans it (git clean -ffdx) before every job
WORK="${WORK:-$HOME/.cache/gfamigamilkytracker/build}"; OUT="${OUT:-$WORK/out}"; JOBS=${JOBS:-12}
TC="$STOVE/prefix"; PATH="$TC/bin:$PATH"; export PATH
mkdir -p "$WORK/deps" "$OUT"; OUT=$(cd "$OUT" && pwd)
t0=$(date +%s)

# a repository at one commit, fetched once (SPARSE: only those folders)
fetch() {
    d="$WORK/deps/$1"
    if [ "$(git -C "$d" rev-parse HEAD 2>/dev/null)" != "$3" ]; then
        rm -rf "${d:?}"; mkdir -p "$d"
        git -C "$d" init -q
        if [ -n "${4:-}" ]; then
            git -C "$d" config core.sparseCheckout true
            echo "$4" > "$d/.git/info/sparse-checkout"
            git -C "$d" fetch -q --depth 1 --filter=blob:none "$2" "$3"
        else
            git -C "$d" fetch -q --depth 1 "$2" "$3"
        fi
        git -C "$d" checkout -q FETCH_HEAD
        [ "$(git -C "$d" rev-parse HEAD)" = "$3" ] || { echo "$1: commit mismatch"; exit 1; }
    fi
}

# --- fpuauto: libfpuauto.a and its link specs ---------------------------------
fetch fpuauto "$FPA_REPO" "$FPA_COMMIT" "/common/fpuauto/"
FA="$WORK/deps/fpuauto/common/fpuauto"; FAL="$WORK/fpuauto"
if [ ! -f "$FAL/libfpuauto.a" ] || [ "$(cat "$FAL/.rev" 2>/dev/null)" != "$FPA_COMMIT" ]; then
    rm -rf "$FAL"; mkdir -p "$FAL/obj"
    m68k-amigaos-gcc -m68040 -DFPUAUTO_COMMON -c "$FA/fpuauto.S" -o "$FAL/obj/fa_common.o"
    for n in $(sed 's/^--wrap=//' "$FA/fpuauto.wraps"); do
        m68k-amigaos-gcc -m68040 -DR_$n -c "$FA/fpuauto.S" -o "$FAL/obj/fa_$n.o"
    done
    m68k-amigaos-ar rcs "$FAL/libfpuauto.a" "$FAL"/obj/fa_*.o
    echo "$FPA_COMMIT" > "$FAL/.rev"
fi

# --- MilkyTracker at its pinned commit, with patches/ -------------------------
# (no submodules: zlib, zziplib, lhasa and RtAudio are left out, so .gz/.zip/
# .lha modules are not opened from inside the archive yet)
SRC="$WORK/milkytracker"
PSUM=$( (cat "$HERE"/patches/*.patch; cat "$HERE"/compat/*) | sha256sum | cut -c1-16)
if [ "$(cat "$SRC/.patched" 2>/dev/null)" != "$MT_COMMIT-$PSUM" ]; then
    rm -rf "$SRC"; mkdir -p "$SRC"
    git -C "$SRC" init -q
    git -C "$SRC" fetch -q --depth 1 "$MT_GIT" "$MT_COMMIT"
    git -C "$SRC" checkout -q FETCH_HEAD
    [ "$(git -C "$SRC" rev-parse HEAD)" = "$MT_COMMIT" ] || { echo "commit mismatch"; exit 1; }
    for p in "$HERE"/patches/*.patch; do
        patch -s -d "$SRC" -p1 < "$p" || { echo "patch failed: $p"; exit 1; }
    done
    echo "$MT_COMMIT-$PSUM" > "$SRC/.patched"
    rm -rf "$WORK/obj"
fi

# version.h, as upstream's CMakeLists.txt makes it from version.h.in
X=${MT_VERSION%%.*}; YZ=${MT_VERSION#*.}; YY=${YZ%%.*}; ZZ=${YZ#*.}
mkdir -p "$WORK/gen"
sed -e "s/\${VER_X}/$X/g" -e "s/\${VER_YY}/$YY/g" -e "s/\${VER_ZZ}/$ZZ/g" \
    "$SRC/src/tracker/version.h.in" > "$WORK/gen/version.h.new"
cmp -s "$WORK/gen/version.h.new" "$WORK/gen/version.h" 2>/dev/null || mv "$WORK/gen/version.h.new" "$WORK/gen/version.h"

# --- SDL 2 from the stove's SDK ------------------------------------------------
SDK="$TC/m68k-amigaos"
for f in include/SDL2/SDL.h lib/libSDL2.a; do
    [ -f "$SDK/$f" ] || { echo "the stove has no $f"; exit 2; }
done

# --- the sources, as upstream's CMake lists them for an SDL build -------------
S="$SRC/src"
MP="AudioDriverBase AudioDriverManager AudioDriver_NULL AudioDriver_WAVWriter ChannelMixer ExporterXM LittleEndian
 Loader669 LoaderAMF LoaderAMS LoaderCBA LoaderDBM LoaderDIGI LoaderDSM LoaderDTM LoaderFAR LoaderGDM LoaderIMF LoaderIT
 LoaderMDL LoaderMOD LoaderMTM LoaderMXM LoaderOKT LoaderPLM LoaderPSM LoaderPTM LoaderS3M LoaderSTM LoaderULT LoaderUNI
 LoaderXM MasterMixer PlayerBase PlayerFAR PlayerGeneric PlayerIT PlayerSTD ResamplerFactory SampleLoaderAIFF
 SampleLoaderALL SampleLoaderAbstract SampleLoaderGeneric SampleLoaderIFF SampleLoaderWAV SampleLoaderSF2 XIInstrument
 XMFile XModule drivers/sdl/AudioDriver_SDL"
PPUI="Button CheckBox CheckBoxLabel Container ContextMenu Control DialogBase DialogFileSelector Dictionary DictionaryKey
 Event Font Graphics_15BIT Graphics_16BIT Graphics_24bpp_generic Graphics_32bpp_generic Graphics_ARGB32 Graphics_BGR24
 Graphics_BGR24_SLOW KeyboardBindingHandler ListBox ListBoxFileBrowser Menu MessageBoxContainer PPUIConfig RadioGroup
 Screen Scrollbar Seperator Slider StaticText Tools TransparentContainer sdl/DisplayDeviceFB_SDL sdl/DisplayDevice_SDL
 osinterface/PPPathFactory
 osinterface/posix/PPPath_POSIX osinterface/posix/PPSystem_POSIX osinterface/sdl/PPMessageBox_SDL osinterface/sdl/PPMutex
 osinterface/sdl/PPOpenPanel_SDL osinterface/sdl/PPQuitSaveAlert_SDL osinterface/sdl/PPSavePanel_SDL
 osinterface/sdl/SDL_ModalLoop"
FX="Camera Filter Fire Math3d ParticleBlobs ParticleEmitter ParticleFX ParticleFun ParticleScene Starfield TCBSpline
 TCBSplineTest Texture TexturedGrid TexturedPlane Twister TwisterFX fpmath"
CMP="Decompressor DecompressorLZX DecompressorPP20 DecompressorUMX PP20 unlzx"
TRK="ModuleServices SongLengthEstimator TrackerSettingsDatabase wav/WAVExporter wav/WAVExportArgs wav/WAVUtils
 ../cli/CLIParser
 AnimatedFXControl ColorExportImport ColorPaletteContainer fx/Convolver DialogHelp DialogChannelSelector DialogEQ
 DialogGroupSelection DialogHandlers DialogListBox DialogPanning DialogQuickChooseInstrument DialogResample
 DialogWithValues DialogZap DialogSliders fx/EQConstants EditorBase EnvelopeContainer EnvelopeEditor
 EnvelopeEditorControl fx/Equalizer FileExtProvider FileIdentificator GlobalColorConfig InputControlListener LogoBig
 LogoSmall ModuleEditor PatternEditor PatternEditorClipBoard PatternEditorControl PatternEditorControlEventListener
 PatternEditorControlKeyboard PatternEditorControlTransposeHandler PatternEditorTools PatternTools Addon
 PeakLevelControl Piano PianoControl PlayerController PlayerLogic PlayerMaster RecPosProvider RecorderLogic
 ResamplerHelper VolumeRampHelper SampleEditor SampleEditorControl SampleEditorControlToolHandler SampleEditorResampler
 SamplePlayer ScopesControl SectionAbout SectionAbstract SectionAdvancedEdit SectionDiskMenu SectionHDRecorder
 SectionInstruments SectionOptimize SectionQuickOptions SectionSamples SectionSettings SectionSwitcher SectionTranspose
 SectionUpperLeft SystemMessage fx/Filter TabHeaderControl TabManager TabTitleProvider TitlePageManager
 ToolInvokeHelper Tracker TrackerConfig TrackerInit TrackerKeyboard TrackerSettings TrackerShortCuts TrackerShutDown
 TrackerStartUp TrackerUpdate Undo VRand Zapper synth/SynthFM Synth Synths sdl/SDL_KeyTranslation sdl/SDL_Main"

# --- one Makefile ----------------------------------------------------------------
LATE=""
if m68k-amigaos-gcc -fno-late-combine-instructions -S -o /dev/null -x c /dev/null 2>/dev/null; then LATE="-fno-late-combine-instructions"; fi
CF="-noixemul -m68040 -O2 -fno-delete-null-pointer-checks -fno-tree-loop-distribute-patterns $LATE -DNDEBUG -D__amigaos__"
INC="-I$HERE/compat -I$WORK/gen -I$S/milkyplay -I$S/milkyplay/drivers/sdl -I$S/ppui -I$S/ppui/sdl -I$S/ppui/osinterface
 -I$S/ppui/osinterface/sdl -I$S/ppui/osinterface/posix -I$S/fx -I$S/compression -I$S/tracker -I$S/tracker/sdl
 -I$S/tracker/wav -I$S/cli -I$SDK/include/SDL2"
O="$WORK/obj"; mkdir -p "$O"
M="$O/Makefile"
{
    echo "CXXF = $CF -std=gnu++17 -include $HERE/compat/amiga_compat.h -DMILKYTRACKER -DSYNTH $(echo $INC) -Wno-deprecated-declarations"
    echo "CF = $CF -include $HERE/compat/amiga_compat.h -I$HERE/compat"
    ALL=""
    rule() {  # rule <prefix> <dir> <names>
        for f in $3; do
            o="$1_$(echo "$f" | sed 's#\.\./##g; s#/#_#g').o"; ALL="$ALL $o"
            printf '%s: %s\n\tm68k-amigaos-g++ $(CXXF) -MMD -c $< -o $@\n' "$o" "$2/$f.cpp"
        done
    }
    rule mp "$S/milkyplay" "$MP"; rule ui "$S/ppui" "$PPUI"; rule fx "$S/fx" "$FX"
    rule cz "$S/compression" "$CMP"; rule tr "$S/tracker" "$TRK"
    for f in amiga_compat amiga_path; do
        ALL="$ALL c_$f.o"
        printf 'c_%s.o: %s\n\tm68k-amigaos-gcc $(CF) -MMD -c $< -o $@\n' "$f" "$HERE/compat/$f.c"
    done
    echo "OBJS =$ALL"
    echo "all: \$(OBJS)"
    echo "-include *.d"
} > "$M"
left=$(( ${BUDGET_TOTAL:-840} - ($(date +%s) - t0) ))
[ "$left" -gt 60 ] || { echo "no time left this run"; exit 0; }
set +e
(cd "$O" && timeout "$left" nice -n 19 make -k -j"$JOBS" all > make.log 2>&1)
rc=$?
set -e
grep -E -B2 'error|Error' "$O/make.log" | head -80
[ "$rc" = 0 ] || { [ "$rc" = 124 ] && echo "out of time: run again to go on"; tail -20 "$O/make.log"; echo "compile: $(( $(date +%s) - t0 )) s"; exit "$rc"; }
echo "compile: $(( $(date +%s) - t0 )) s, $(ls "$O"/*.o | wc -l) objects"

# --- the link: soft-float specs, then fpuauto's ----------------------------------
LINK="m68k-amigaos-g++ -noixemul -m68040 -specs=$HERE/scripts/m68k-soft-m68040.specs -specs=$FA/fpuauto.specs -L$FAL"
# shellcheck disable=SC2046
$LINK -o "$O/MilkyTracker.debug" $(cd "$O" && for f in $(sed -n 's/^OBJS =//p' Makefile); do echo "$O/$f"; done) \
    -L"$SDK/lib" -lSDL2 -lGL -lpthread -latomic > "$O/link.log" 2>&1 || { grep -v '^\s*$' "$O/link.log" | head -60; exit 1; }

# --- the GFOpenUp part: Parts/MilkyTracker --------------------------------------
P="$OUT/Parts/MilkyTracker"; D="$P/Utilities/MilkyTracker"; rm -rf "$P"; mkdir -p "$D/Songs" "$D/Docs"
m68k-amigaos-strip -o "$D/MilkyTracker" "$O/MilkyTracker.debug"
cp "$SRC/COPYING" "$D/COPYING"
cp "$HERE/README.md" "$D/ReadMe"
cp "$SRC"/resources/music/*.xm "$D/Songs/"
for f in MilkyTracker.html FAQ.html ChangeLog.html readme_unix; do
    [ -f "$SRC/docs/$f" ] && cp "$SRC/docs/$f" "$D/Docs/"
done
sh "$HERE/scripts/write-part.sh" "$P" "$MT_VERSION"
ls -l "$D/MilkyTracker"
echo "part: $(grep -c '^copy' "$P/Part") files, $(du -sk "$P" | cut -f1) KB"
echo "fpuauto: $(m68k-amigaos-nm "$O/MilkyTracker.debug" | grep -c ' T ___wrap_') wrapped routines"
echo "total: $(( $(date +%s) - t0 )) s"
