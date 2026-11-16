/* What libnix leaves out, for MilkyTracker; see amiga_compat.h.
 * Copyright (c) 2026 AmiCradle Team. GPL 3 or later, like MilkyTracker. */
#include <string.h>
#include <proto/dos.h>
#include "amiga_compat.h"

/* a Shell gives 4 KB of stack; libnix's startup sets this much up instead */
unsigned long __stack = 512 * 1024;
static const char version[] __attribute__((used)) = "$VER: MilkyTracker 1.05.01 Amiga (16.11.2026)";

char *amiga_realpath(const char *path, char *resolved)
{
    BPTR lock = Lock((CONST_STRPTR)path, ACCESS_READ);
    if (!lock)
        return NULL;
    if (!NameFromLock(lock, (STRPTR)resolved, PATH_MAX)) {
        UnLock(lock);
        return NULL;
    }
    UnLock(lock);
    return resolved;
}
