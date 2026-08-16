#include <limits.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// ---------------------------------------------------------------------------

struct PathParser {
    const char * pos;
    const char * begin;
    const char * end;
};

struct PathElement {
    const char * pos;
    size_t       size;
};

struct PathPair {
    struct PathElement front;
    struct PathElement current;
};

__attribute__((always_inline)) inline
static int PathPair_is_valid(struct PathPair * self) {
    return self->current.pos != 0;
}

__attribute__((always_inline)) inline
static void PathParser_init(struct PathParser * self, const char * path) {
    size_t len  = strlen(path);
    self->pos   = path + len - 1;
    self->begin = path;
    self->end   = path + len;
}

__attribute__((always_inline)) inline
static struct PathPair PathParser_next(struct PathParser * self) {
    static const struct PathElement empty_elem = { 0, 0 };
    static const struct PathPair    empty_pair = { empty_elem, empty_elem };
    const char ch = '/';
    const char * pos   = self->pos;
    const char * end   = pos;
    const char * begin = self->begin;
    for (; pos != begin; --pos) {
        if (*pos == ch) {
            struct PathElement front = { begin, pos - begin };
            --pos;
            self->pos = pos;
            pos += 2;
            struct PathElement curr  = { pos, end - pos + 1 };
            return (struct PathPair){ front, curr };
        }
    }
    return empty_pair;
}

static struct PathPair PathParser_next_n(struct PathParser * self, size_t n) {
    if (n > 1) {
        n -= 1;
        for (size_t i = 0; i < n; ++i) PathParser_next(self);
    }
    return PathParser_next(self);
}

static void PathPair_print(const struct PathPair * self) {
    printf("FRONT: %d: %.*s\n", (int)self->front.size, (int)self->front.size, self->front.pos);
    printf("CURR:  %d: %.*s\n", (int)self->current.size, (int)self->current.size, self->current.pos);
}

// ---------------------------------------------------------------------------

static char   exename[32];
static size_t exelen = 0;
static char   basepathname[128];
static size_t basepathlen = 0;
static char   exepathname[256];
static size_t exepathlen = 0;

static char   libpathbuffer[1024];
static char   ldexename[160];

static void clearpaths(int line) {
    printf("ERROR @%d: BASEPATH=%s\nEXE=%s\n", line, basepathname, exename);
    exename[0] = 0;
    exelen = 0;
    basepathname[0] = 0;
    basepathlen = 0;
    exepathname[0] = 0;
    exepathlen = 0;
}

static void splitpath(const char * appname, size_t len) {
    // ---- basepathname and exename
    struct PathParser parser;
    struct PathPair   pair;
    PathParser_init(&parser, appname);

    pair = PathParser_next(&parser);
    if (!PathPair_is_valid(&pair)) {
        clearpaths(__LINE__);
        return;
    }
    //PathPair_print(&pair);
    exelen = pair.current.size;
    memcpy(exename, pair.current.pos, pair.current.size);
    pair = PathParser_next_n(&parser, 2);

    if (!PathPair_is_valid(&pair)) {
        clearpaths(__LINE__);
        return;
    }
    //PathPair_print(&pair);
    basepathlen = pair.current.size;
    memcpy(basepathname, pair.front.pos, pair.front.size);

    exepathlen = snprintf(exepathname, sizeof(exepathname), "%s/bin/%s", basepathname, exename);
    return;

error:
    printf("encapsulate error: %s\n", appname);
    printf("BASEPATH=%s\nEXE=%s\n", basepathname, exename);
    clearpaths(__LINE__);
}

#define DEBUG 0

int main(
    int argc,
    const char * argv[],
    const char * envp[]
) {
#if DEBUG
    printf("START %d %s\n", argc, argv[0]);
#endif
    char buffer[512];
    char path[PATH_MAX];
    ssize_t length = readlink("/proc/self/exe", path, sizeof(path) - 1);
    if (length == -1) {
        perror("readlink /proc/self/exe");
    }
    path[length] = '\0';
    splitpath(path, length);

    snprintf(
        ldexename, sizeof(ldexename),
        "%s/wrapper/lib/${LD_LINUX_SO}", basepathname
    );
    snprintf(
        libpathbuffer, sizeof(libpathbuffer),
        "LD_LIBRARY_PATH=%s/wrapper/lib/:%s/lib/lib:%s/lib:%s/lib64",
        basepathname, basepathname, basepathname, basepathname
    );
    bool is_ldexe = 0 == strcmp(path, ldexename);

    char ** args;
    size_t len = argc;
    void * array = 0;
    if (!is_ldexe) {
        len = argc + 3;
        size_t slen = argc * sizeof(char*);
        size_t dlen = len * sizeof(char*);
        array = malloc(dlen);
        args = (char **)array;
        memcpy(args + 3, argv + 1, slen);
        args[0] = exepathname;
        //args[1] = "--library-path";
        //args[2] = libpathbuffer + 16; // skip LD_LIBRARY_PATH=
        args[1] = path;
        args[2] = exepathname;
    }
    else {
        len  = argc - 1;
        args = (char**)argv + 1;
    }

#if DEBUG
    for (int i = 0; i < len; ++i) {
        printf("ARG: %d: %s\n", i, args[i]);
    }
#endif

    int ret;
    if (!is_ldexe) {
        ret = execv(ldexename, args);
        free(array);
    }
    else {
        const char **senv;
        for (senv = envp; *senv != 0; ++senv) {}
        size_t lenv = (senv - envp + 2);
        const char ** menv = (const char **)malloc(lenv * sizeof(char**));
        const char ** denv = menv;
        for (senv = envp; *senv != 0; ++senv, ++denv) {
            if (0 != strncmp("LD_LIBRARY_PATH=", *senv, 16)) {
                *denv = *senv;
            }
        }
        *denv++ = libpathbuffer;
        *denv++ = 0;

        ret = execve(args[0], args, (char**)menv);
        free(menv);
    }

    return ret;
}
