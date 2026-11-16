/* The stack and version string for MilkyTracker.
 * Copyright (c) 2026 AmiCradle Team. GPL 3 or later, like MilkyTracker. */
#include "amiga_compat.h"

/* a Shell gives 4 KB of stack; libnix's startup sets this much up instead */
unsigned long __stack = 512 * 1024;
static const char version[] __attribute__((used)) = "$VER: MilkyTracker 1.05.01 Amiga (16.11.2026)";
