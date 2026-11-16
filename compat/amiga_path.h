/* AmigaDOS path steps for MilkyTracker's file browser (PPPath_POSIX):
 * "Work:" is a volume's root, "Work:Music/" a drawer; there is no "/" root
 * and no "..", and a "/" straight after "Work:" means the parent.
 * Copyright (c) 2026 AmiCradle Team. GPL 3 or later, like MilkyTracker. */
#ifndef AMIGA_PATH_H
#define AMIGA_PATH_H
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif
/* adds the "/" a drawer needs; a root ("Work:") or "" is left as it is */
void amiga_path_drawer(char *path, size_t size);
/* "Work:Music/Mods/" -> "Work:Music/", "Work:Music/" -> "Work:"; a root stays */
void amiga_path_parent(char *path);
/* "Work:Music/Mods/" -> "Work:"; no volume -> "SYS:" */
void amiga_path_root(char *path, size_t size);
#ifdef __cplusplus
}
#endif
#endif
