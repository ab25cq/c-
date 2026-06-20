#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define PATH_MAX_LEN 1024
#define VALUE_MAX_LEN 512

#if defined(__APPLE__)
#define LEAK_CFLAGS "-g -fno-omit-frame-pointer -fsanitize=address"
#define LEAK_RUN_PREFIX "env ASAN_OPTIONS=detect_leaks=1:halt_on_error=1:exitcode=99 LSAN_OPTIONS=exitcode=99"
#define LEAK_FALLBACK_TO_VALGRIND 0
#else
#define LEAK_CFLAGS "-g -fno-omit-frame-pointer -fsanitize=address,leak"
#define LEAK_RUN_PREFIX "env ASAN_OPTIONS=detect_leaks=1:halt_on_error=1:exitcode=99 LSAN_OPTIONS=exitcode=99"
#define LEAK_FALLBACK_TO_VALGRIND 1
#endif

struct Manifest {
    char name[VALUE_MAX_LEN];
    char version[VALUE_MAX_LEN];
    char src[PATH_MAX_LEN];
    char out[PATH_MAX_LEN];
    char compiler[VALUE_MAX_LEN];
    char cflags[VALUE_MAX_LEN];
};

static void die(const char *msg)
{
    fputs(msg, stderr);
    fputc('\n', stderr);
    exit(1);
}

static void die_errno(const char *msg)
{
    perror(msg);
    exit(1);
}

static int file_exists(const char *path)
{
    struct stat st;
    return stat(path, &st) == 0;
}

static void mkdir_one(const char *path)
{
    if (mkdir(path, 0777) != 0 && errno != EEXIST) {
        die_errno(path);
    }
}

static void mkdir_p(const char *path)
{
    char tmp[PATH_MAX_LEN];
    char *p;

    if (strlen(path) >= sizeof(tmp)) {
        die("cpm: path too long");
    }
    strcpy(tmp, path);
    for (p = tmp + 1; *p != '\0'; p++) {
        if (*p == '/') {
            *p = '\0';
            mkdir_one(tmp);
            *p = '/';
        }
    }
    mkdir_one(tmp);
}

static void write_file(const char *path, const char *text)
{
    FILE *fp = fopen(path, "w");
    if (fp == NULL) {
        die_errno(path);
    }
    fputs(text, fp);
    if (fclose(fp) != 0) {
        die_errno(path);
    }
}

static const char *base_name(const char *path)
{
    const char *slash = strrchr(path, '/');
    return slash == NULL ? path : slash + 1;
}

static void shell_quote(char *out, size_t out_size, const char *s)
{
    size_t n = 0;

    if (out_size < 3) {
        die("cpm: quote buffer too small");
    }
    out[n++] = '\'';
    while (*s != '\0') {
        if (*s == '\'') {
            const char *q = "'\\''";
            while (*q != '\0') {
                if (n + 1 >= out_size) {
                    die("cpm: command too long");
                }
                out[n++] = *q++;
            }
        } else {
            if (n + 1 >= out_size) {
                die("cpm: command too long");
            }
            out[n++] = *s;
        }
        s++;
    }
    if (n + 2 >= out_size) {
        die("cpm: command too long");
    }
    out[n++] = '\'';
    out[n] = '\0';
}

static int run_cmd(const char *cmd)
{
    int rc;

    puts(cmd);
    rc = system(cmd);
    if (rc != 0) {
        fprintf(stderr, "cpm: command failed: %s\n", cmd);
        return 1;
    }
    return 0;
}

static char *trim(char *s)
{
    char *end;

    while (isspace((unsigned char)*s)) {
        s++;
    }
    end = s + strlen(s);
    while (end > s && isspace((unsigned char)end[-1])) {
        end--;
    }
    *end = '\0';
    return s;
}

static void unquote_value(char *dst, size_t dst_size, const char *src)
{
    size_t len;

    src = trim((char *)src);
    len = strlen(src);
    if (len >= 2 && src[0] == '"' && src[len - 1] == '"') {
        src++;
        len -= 2;
    }
    if (len >= dst_size) {
        len = dst_size - 1;
    }
    memcpy(dst, src, len);
    dst[len] = '\0';
}

static void manifest_defaults(struct Manifest *m)
{
    memset(m, 0, sizeof(*m));
    strcpy(m->name, "app");
    strcpy(m->version, "0.1.0");
    strcpy(m->src, "src/main.c-");
    strcpy(m->compiler, "cc");
    strcpy(m->cflags, "-std=gnu99 -Wall -Wextra");
}

static void manifest_finish(struct Manifest *m)
{
    if (m->out[0] == '\0') {
        snprintf(m->out, sizeof(m->out), "target/debug/%s", m->name);
    }
}

static void read_manifest(struct Manifest *m)
{
    FILE *fp;
    char line[1024];
    char section[VALUE_MAX_LEN] = "";

    manifest_defaults(m);
    fp = fopen("C-.toml", "r");
    if (fp == NULL) {
        die("cpm: C-.toml not found");
    }
    while (fgets(line, sizeof(line), fp) != NULL) {
        char *s = trim(line);
        char *eq;

        if (*s == '\0' || *s == '#') {
            continue;
        }
        if (*s == '[') {
            char *r = strchr(s, ']');
            if (r != NULL) {
                *r = '\0';
                strncpy(section, s + 1, sizeof(section) - 1);
                section[sizeof(section) - 1] = '\0';
            }
            continue;
        }
        eq = strchr(s, '=');
        if (eq == NULL) {
            continue;
        }
        *eq = '\0';
        {
            char *key = trim(s);
            char *value = trim(eq + 1);
            if (strcmp(section, "package") == 0 && strcmp(key, "name") == 0) {
                unquote_value(m->name, sizeof(m->name), value);
            } else if (strcmp(section, "package") == 0 && strcmp(key, "version") == 0) {
                unquote_value(m->version, sizeof(m->version), value);
            } else if (strcmp(section, "build") == 0 && strcmp(key, "src") == 0) {
                unquote_value(m->src, sizeof(m->src), value);
            } else if (strcmp(section, "build") == 0 && strcmp(key, "out") == 0) {
                unquote_value(m->out, sizeof(m->out), value);
            } else if (strcmp(section, "build") == 0 && strcmp(key, "compiler") == 0) {
                unquote_value(m->compiler, sizeof(m->compiler), value);
            } else if (strcmp(section, "build") == 0 && strcmp(key, "cflags") == 0) {
                unquote_value(m->cflags, sizeof(m->cflags), value);
            }
        }
    }
    fclose(fp);
    manifest_finish(m);
}

static void write_manifest(const char *name)
{
    char text[2048];

    snprintf(text, sizeof(text),
             "[package]\n"
             "name = \"%s\"\n"
             "version = \"0.1.0\"\n"
             "edition = \"2026\"\n"
             "\n"
             "[build]\n"
             "src = \"src/main.c-\"\n"
             "compiler = \"cc\"\n"
             "cflags = \"-std=gnu99 -Wall -Wextra\"\n",
             name);
    write_file("C-.toml", text);
}

static void write_main_source(void)
{
    write_file("src/main.c-",
               "#include <stdio.h>\n"
               "#include <stdlib.h>\n"
               "#include <c-/vec.c->\n"
               "\n"
               "int main(void)\n"
               "{\n"
               "    int*% value = new int;\n"
               "    *value = 123;\n"
               "    if (*value == 123) {\n"
               "        puts(\"value 123\");\n"
               "    }\n"
               "    return 0;\n"
               "}\n");
}

static void write_stdlib_source(void)
{
    mkdir_p("lib/c-");
    if (!file_exists("lib/c-/vec.c-")) {
        write_file("lib/c-/vec.c-",
                   "generic<T>\n"
                   "struct Vec {\n"
                   "    T* data;\n"
                   "    int len;\n"
                   "};\n"
                   "\n"
                   "generic<T>\n"
                   "T Vec_first(struct Vec<T>* self)\n"
                   "{\n"
                   "    return self->data[0];\n"
                   "}\n");
    }
}

static int cmd_init(const char *name)
{
    if (file_exists("C-.toml")) {
        die("cpm: C-.toml already exists");
    }
    mkdir_p("src");
    write_manifest(name);
    if (!file_exists("src/main.c-")) {
        write_main_source();
    }
    write_stdlib_source();
    if (!file_exists(".gitignore")) {
        write_file(".gitignore", "target/\n");
    }
    printf("created package `%s`\n", name);
    return 0;
}

static int cmd_new(const char *name)
{
    if (file_exists(name)) {
        die("cpm: destination already exists");
    }
    mkdir_p(name);
    if (chdir(name) != 0) {
        die_errno(name);
    }
    return cmd_init(base_name(name));
}

static int cmd_build_with_flags(const char *extra_cflags)
{
    struct Manifest m;
    char c_path[PATH_MAX_LEN];
    char q_translator[PATH_MAX_LEN * 2];
    char q_src[PATH_MAX_LEN * 2];
    char q_c[PATH_MAX_LEN * 2];
    char q_out[PATH_MAX_LEN * 2];
    char cmd[PATH_MAX_LEN * 12];
    char *slash;
    const char *translator = getenv("CPM_C_MINUS");

    if (translator == NULL || translator[0] == '\0') {
        translator = "c-";
    }
    read_manifest(&m);
    snprintf(c_path, sizeof(c_path), "target/debug/%s.c", m.name);
    mkdir_p("target/debug");

    shell_quote(q_translator, sizeof(q_translator), translator);
    shell_quote(q_src, sizeof(q_src), m.src);
    shell_quote(q_c, sizeof(q_c), c_path);
    shell_quote(q_out, sizeof(q_out), m.out);

    snprintf(cmd, sizeof(cmd), "%s %s > %s", q_translator, q_src, q_c);
    if (run_cmd(cmd) != 0) {
        return 1;
    }
    slash = strrchr(m.out, '/');
    if (slash != NULL) {
        char dir[PATH_MAX_LEN];
        size_t n = (size_t)(slash - m.out);
        if (n >= sizeof(dir)) {
            die("cpm: output path too long");
        }
        memcpy(dir, m.out, n);
        dir[n] = '\0';
        mkdir_p(dir);
    }
    if (extra_cflags != NULL && extra_cflags[0] != '\0') {
        snprintf(cmd, sizeof(cmd), "%s %s %s %s -o %s", m.compiler, m.cflags, extra_cflags, q_c, q_out);
    } else {
        snprintf(cmd, sizeof(cmd), "%s %s %s -o %s", m.compiler, m.cflags, q_c, q_out);
    }
    if (run_cmd(cmd) != 0) {
        return 1;
    }
    printf("built %s\n", m.out);
    return 0;
}

static int cmd_build(void)
{
    return cmd_build_with_flags(NULL);
}

static int run_manifest_output(int argc, char **argv, const char *prefix)
{
    struct Manifest m;
    char q_out[PATH_MAX_LEN * 2];
    char cmd[PATH_MAX_LEN * 12];
    int i;

    read_manifest(&m);
    shell_quote(q_out, sizeof(q_out), m.out);
    if (prefix != NULL && prefix[0] != '\0') {
        snprintf(cmd, sizeof(cmd), "%s %s", prefix, q_out);
    } else {
        snprintf(cmd, sizeof(cmd), "%s", q_out);
    }
    for (i = 0; i < argc; i++) {
        char q_arg[PATH_MAX_LEN * 2];
        shell_quote(q_arg, sizeof(q_arg), argv[i]);
        if (strlen(cmd) + strlen(q_arg) + 2 >= sizeof(cmd)) {
            die("cpm: command too long");
        }
        strcat(cmd, " ");
        strcat(cmd, q_arg);
    }
    return run_cmd(cmd);
}

static int cmd_run(int argc, char **argv)
{
    if (cmd_build() != 0) {
        return 1;
    }
    return run_manifest_output(argc, argv, NULL);
}

static int cmd_val(int argc, char **argv)
{
    const char *valgrind = getenv("CPM_VALGRIND");
    char q_valgrind[PATH_MAX_LEN * 2];
    char prefix[PATH_MAX_LEN * 4];

    if (cmd_build() != 0) {
        return 1;
    }
    if (valgrind == NULL || valgrind[0] == '\0') {
        valgrind = "valgrind";
    }
    shell_quote(q_valgrind, sizeof(q_valgrind), valgrind);
    snprintf(prefix, sizeof(prefix),
             "%s --leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=definite,possible --error-exitcode=99",
             q_valgrind);
    return run_manifest_output(argc, argv, prefix);
}

static int cmd_leak(int argc, char **argv)
{
    int rc;

    if (cmd_build_with_flags(LEAK_CFLAGS) != 0) {
        fputs("cpm: compiler leak sanitizer build failed\n", stderr);
        if (LEAK_FALLBACK_TO_VALGRIND) {
            fputs("cpm: falling back to valgrind\n", stderr);
            return cmd_val(argc, argv);
        }
        return 1;
    }
    rc = run_manifest_output(argc, argv, LEAK_RUN_PREFIX);
    if (rc != 0) {
        fputs("cpm: compiler leak sanitizer run failed\n", stderr);
        if (LEAK_FALLBACK_TO_VALGRIND) {
            fputs("cpm: falling back to valgrind\n", stderr);
            return cmd_val(argc, argv);
        }
        return rc;
    }
    return 0;
}

static int cmd_clean(void)
{
    return run_cmd("rm -rf target");
}

static void usage(void)
{
    fputs("usage: cpm <new|init|build|run|test|val|leak|clean> [args]\n", stderr);
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        usage();
        return 2;
    }
    if (strcmp(argv[1], "new") == 0) {
        if (argc != 3) {
            usage();
            return 2;
        }
        return cmd_new(argv[2]);
    }
    if (strcmp(argv[1], "init") == 0) {
        return cmd_init(argc >= 3 ? argv[2] : base_name("."));
    }
    if (strcmp(argv[1], "build") == 0) {
        return cmd_build();
    }
    if (strcmp(argv[1], "run") == 0) {
        return cmd_run(argc - 2, argv + 2);
    }
    if (strcmp(argv[1], "test") == 0) {
        return cmd_run(0, NULL);
    }
    if (strcmp(argv[1], "val") == 0) {
        return cmd_val(argc - 2, argv + 2);
    }
    if (strcmp(argv[1], "leak") == 0) {
        return cmd_leak(argc - 2, argv + 2);
    }
    if (strcmp(argv[1], "clean") == 0) {
        return cmd_clean();
    }
    usage();
    return 2;
}
