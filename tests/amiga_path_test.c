/* Host test for compat/amiga_path.c: the file browser's AmigaDOS steps.
 * Copyright (c) 2026 AmiCradle Team. GPL 3 or later, like MilkyTracker. */
#include <stdio.h>
#include <string.h>
#include "amiga_path.h"

static int fails;

static void check(const char *what, const char *in, const char *got, const char *want)
{
    if (strcmp(got, want)) {
        printf("FAIL: %s(\"%s\") = \"%s\", want \"%s\"\n", what, in, got, want);
        fails++;
    }
}

static void drawer(const char *in, const char *want)
{
    char b[64]; strcpy(b, in); amiga_path_drawer(b, sizeof(b)); check("drawer", in, b, want);
}
static void parent(const char *in, const char *want)
{
    char b[64]; strcpy(b, in); amiga_path_parent(b); check("parent", in, b, want);
}
static void root(const char *in, const char *want)
{
    char b[64]; strcpy(b, in); amiga_path_root(b, sizeof(b)); check("root", in, b, want);
}

int main(void)
{
    char tight[5] = "abcd";

    drawer("Work:", "Work:");               /* never "Work:/": the parent */
    drawer("Work:Music", "Work:Music/");
    drawer("Work:Music/", "Work:Music/");
    drawer("", "");
    amiga_path_drawer(tight, sizeof(tight)); /* no room: left alone */
    check("drawer", "abcd", tight, "abcd");

    parent("Work:Music/Mods/", "Work:Music/");
    parent("Work:Music/Mods", "Work:Music/");
    parent("Work:Music/", "Work:");
    parent("Work:", "Work:");               /* a root has nothing above it */
    parent("Mods/", "Mods/");               /* no volume, nothing to go to */

    root("Work:Music/Mods/", "Work:");
    root("DH0:", "DH0:");
    root("Mods/", "SYS:");

    if (!fails)
        printf("AmigaDOS paths: all checks passed\n");
    return fails != 0;
}
