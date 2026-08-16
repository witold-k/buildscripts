#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h> // getcwd

#define BUFFER_SIZE 1024

static const char * back_find(const char* begin, const char * pos, const char ch) {
    for (; pos != begin; --pos) {
        if (*pos == ch) return pos;
    }
    return 0;
}

static const char * forward_find(const char * pos, const char ch) {
    for (; *pos != 0; ++pos) {
        if (*pos == ch) return pos;
    }
    return 0;
}

// ---------------------------------------------------------------------------

static char   exename[256];
static size_t exelen = 0;
static char   exepathname[256];
static size_t exepathlen = 0;
static char   toolspathname[256];
static size_t toolspathlen = 0;
static char   toolsprefixname[64];
static size_t toolsprefixlen = 0;
static char   basetoolname[16];
static size_t basetoollen = 0;

static void clearpaths() {
    printf("ERROR: EXEPATH=%s\nEXE=%s\nTOOLPATH=%s\nPREFIX=%s\nBASE=%s\n", exepathname, exename, toolspathname, toolsprefixname, basetoolname);
    exename[0] = 0;
    exelen = 0;
    exepathname[0] = 0;
    exepathlen = 0;
    toolspathname[0] = 0;
    toolspathlen = 0;
    toolsprefixname[0] = 0;
    toolsprefixlen = 0;
    basetoolname[0] = 0;
    basetoollen = 0;
}
static void splitpath(const char * appname) {
    // ---- exepathname and exename
    size_t len = strlen(appname);
    const char * delim = back_find(appname, appname + len - 1, '/');
    if (0 == delim) {
        clearpaths();
        return;
    }
    ++delim;
    exepathlen = delim - appname;
    memcpy(exepathname, appname, delim - appname);
    exepathname[exepathlen] = 0;

    exelen = len - exepathlen;
    memcpy(exename, appname + exepathlen, exelen);
    exename[exelen] = 0;

    // ---- toolspathname
    delim = back_find(exepathname, exepathname + exepathlen - 2, '/');
    if (0 == delim) {
        goto error;
    }
    ++delim;
    toolspathlen = delim - exepathname;
    memcpy(toolspathname, exepathname, toolspathlen);
    toolspathname[toolspathlen] = 0;

    // ---- toolprefixname
    delim = back_find(toolspathname, toolspathname + toolspathlen - 2, '/');
    if (0 == delim) {
        goto error;
    }
    toolsprefixlen = toolspathname + toolspathlen - delim - 2;
    memcpy(toolsprefixname, toolspathname + toolspathlen - toolsprefixlen - 1, toolsprefixlen);
    toolsprefixname[toolsprefixlen] = 0;

    // ---- basetool
    delim = back_find(exename, exename + exelen - 1, '_');
    if (0 == delim) {
        goto error;
    }
    basetoollen = exename + exelen - delim - 1;
    memcpy(basetoolname, exename + exelen - basetoollen, basetoollen);
    basetoolname[basetoollen] = 0;
    return;

error:
    printf("gccwrapper error: %s\n", appname);
    printf("EXEPATH=%s\nEXE=%s\nTOOLPATH=%s\nPREFIX=%s\nBASE=%s\n", exepathname, exename, toolspathname, toolsprefixname, basetoolname);
    clearpaths();
}

// ---------------------------------------------------------------------------

static int is_valid_arg(const char * arg) {
    if (arg == 0) return 0;
    if (strlen(arg) <= 2) return 1;

    if ((0 == memcmp(arg, "-I", 2)) || (0 == memcmp(arg, "-L", 2))) {
        arg += 2;
    }
    if (0 == strcmp(arg, "/usr/include")) return 0;
    if (0 == strcmp(arg, "/usr/lib")) return 0;
    return 1;
}

/**
 * some buildprocesses injects /usr/include and /usr/lib
 * to command line, this must be removed
 */
static int cleanup_args(int argc, char ** argv) {
    char ** r = argv + 2;
    char ** w = r;
    char ** e = argv + argc;
    for (; r != e; ++r) {
        if (is_valid_arg(*r)) {
            *w = *r;
            ++w;
        }
    }
    *w = 0;
    return w - argv;
}

// ---------------------------------------------------------------------------

int main(
    int argc,
    const char * argv[]
) {
    splitpath(argv[0]);

    char cmd[512];
    snprintf(
        cmd, sizeof(cmd),
        "%s%s-%s",
        exepathname, toolsprefixname, basetoolname
    );

    char sysroot[512];
    snprintf(
        sysroot, sizeof(sysroot),
        "--sysroot=%s%s/sysroot",
        toolspathname, toolsprefixname
    );

    size_t len = sizeof(char *) * argc;
    void * array = malloc(sizeof(char *) + len + len);
    char ** args = (char **)array;
    memcpy(args + 1, argv, len);
    args[0] = cmd;
    args[1] = sysroot;
    args[argc + 1] = 0;
    argc = cleanup_args(argc + 2, args);
/*
    for (int i = 0; i <= argc; ++i) {
        printf("ARG: %s\n", args[i]);
    }
*/
    int ret = execv(cmd, args);
    free(array);
    return ret;
}

