/* Taken into every MilkyTracker source (-include): what libnix leaves out.
 * Copyright (c) 2026 AmiCradle Team. GPL 3 or later, like MilkyTracker. */
#ifndef AMIGA_COMPAT_H
#define AMIGA_COMPAT_H
#include <limits.h>
#include <stdlib.h>
#ifndef PATH_MAX
#define PATH_MAX 1024
#endif
#ifdef __cplusplus
extern "C" {
#endif
/* the full AmigaDOS name of an object that exists (NameFromLock) */
char *amiga_realpath(const char *path, char *resolved);
#ifdef __cplusplus
}
#endif
#define realpath(p, r) amiga_realpath((p), (r))
#endif
