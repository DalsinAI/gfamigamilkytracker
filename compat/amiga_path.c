/* AmigaDOS path steps for MilkyTracker's file browser; see amiga_path.h.
 * Copyright (c) 2026 AmiCradle Team. GPL 3 or later, like MilkyTracker. */
#include <string.h>
#include "amiga_path.h"

void amiga_path_drawer(char *path, size_t size)
{
    size_t n = strlen(path);
    if (n && path[n - 1] != ':' && path[n - 1] != '/' && n + 1 < size) {
        path[n] = '/';
        path[n + 1] = 0;
    }
}

void amiga_path_parent(char *path)
{
    size_t n = strlen(path), keep;
    if (n && path[n - 1] == '/')
        n--;
    keep = n;
    while (keep && path[keep - 1] != '/' && path[keep - 1] != ':')
        keep--;
    if (keep)                       /* "Work:" alone has nothing above it */
        path[keep] = 0;
}

void amiga_path_root(char *path, size_t size)
{
    char *colon = strchr(path, ':');
    if (colon)
        colon[1] = 0;
    else if (size > 4)
        strcpy(path, "SYS:");
}
