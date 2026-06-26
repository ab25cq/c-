#include <ctype.h>
#include <errno.h>
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#if defined(__GNUC__)
#pragma GCC diagnostic ignored "-Woverlength-strings"
#endif

#define PATH_MAX_LEN 1024
#define VALUE_MAX_LEN 512
#define MAX_SOURCES 128

#define LEAK_CFLAGS "-g -fno-omit-frame-pointer -fsanitize=address,leak"
#define LEAK_RUN_PREFIX "env ASAN_OPTIONS=detect_leaks=1:halt_on_error=1:exitcode=99 LSAN_OPTIONS=exitcode=99"
#define LEAK_FALLBACK_TO_VALGRIND 1

struct Manifest {
    char name[VALUE_MAX_LEN];
    char version[VALUE_MAX_LEN];
    char src[PATH_MAX_LEN];
    char out[PATH_MAX_LEN];
    char compiler[VALUE_MAX_LEN];
    char cflags[VALUE_MAX_LEN];
    char ldflags[VALUE_MAX_LEN];
};

struct SourceList {
    char path[MAX_SOURCES][PATH_MAX_LEN];
    int count;
};

static void shell_quote(char *out, size_t out_size, const char *s);
static int starts_word_text(const char *s, const char *word);

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

static int dir_exists(const char *path)
{
    struct stat st;
    return stat(path, &st) == 0 && S_ISDIR(st.st_mode);
}

static int has_suffix(const char *s, const char *suffix)
{
    size_t len = strlen(s);
    size_t suffix_len = strlen(suffix);

    return len >= suffix_len && strcmp(s + len - suffix_len, suffix) == 0;
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

static int copy_file_if_exists(const char *src, const char *dst)
{
    FILE *in;
    FILE *out;
    char buf[4096];
    size_t n;

    if (src == NULL || src[0] == '\0' || !file_exists(src)) {
        return 0;
    }
    in = fopen(src, "rb");
    if (in == NULL) {
        return 0;
    }
    out = fopen(dst, "wb");
    if (out == NULL) {
        fclose(in);
        return 0;
    }
    while ((n = fread(buf, 1, sizeof(buf), in)) > 0) {
        if (fwrite(buf, 1, n, out) != n) {
            fclose(in);
            fclose(out);
            return 0;
        }
    }
    fclose(in);
    if (fclose(out) != 0) {
        return 0;
    }
    return 1;
}

static void source_list_add(struct SourceList *sources, const char *path)
{
    int i;

    for (i = 0; i < sources->count; i++) {
        if (strcmp(sources->path[i], path) == 0) {
            return;
        }
    }
    if (sources->count >= MAX_SOURCES) {
        die("cpm: too many source files");
    }
    strncpy(sources->path[sources->count], path, PATH_MAX_LEN - 1);
    sources->path[sources->count][PATH_MAX_LEN - 1] = '\0';
    sources->count++;
}

static void collect_sources_dir(struct SourceList *sources, const char *dir)
{
    DIR *dp;
    struct dirent *ent;

    dp = opendir(dir);
    if (dp == NULL) {
        return;
    }
    while ((ent = readdir(dp)) != NULL) {
        char path[PATH_MAX_LEN];

        if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0) {
            continue;
        }
        snprintf(path, sizeof(path), "%s/%s", dir, ent->d_name);
        if (dir_exists(path)) {
            collect_sources_dir(sources, path);
        } else if (has_suffix(path, ".c-")) {
            source_list_add(sources, path);
        }
    }
    closedir(dp);
}

static void collect_sources(struct SourceList *sources, const char *main_src)
{
    memset(sources, 0, sizeof(*sources));
    source_list_add(sources, main_src);
    collect_sources_dir(sources, "src");
}

static void generated_c_path(char *out, size_t out_size, const char *src, const struct Manifest *m)
{
    size_t i;
    size_t n;

    if (strcmp(src, m->src) == 0) {
        snprintf(out, out_size, "target/debug/%s.c", m->name);
        return;
    }
    snprintf(out, out_size, "target/debug/%s", src);
    n = strlen(out);
    if (n >= 3 && strcmp(out + n - 3, ".c-") == 0) {
        out[n - 1] = '\0';
    } else if (n + 3 < out_size) {
        strcat(out, ".c");
    }
    for (i = strlen("target/debug/"); out[i] != '\0'; i++) {
        if (out[i] == '/') {
            out[i] = '_';
        }
    }
}

static void append_generated_c_paths(char *cmd, size_t cmd_size, struct SourceList *sources, const struct Manifest *m)
{
    int i;

    for (i = 0; i < sources->count; i++) {
        char c_path[PATH_MAX_LEN];
        char q_c[PATH_MAX_LEN * 2];

        generated_c_path(c_path, sizeof(c_path), sources->path[i], m);
        shell_quote(q_c, sizeof(q_c), c_path);
        if (strlen(cmd) + strlen(q_c) + 2 >= cmd_size) {
            die("cpm: command too long");
        }
        strcat(cmd, " ");
        strcat(cmd, q_c);
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

static int starts_word_text(const char *s, const char *word)
{
    size_t n = strlen(word);
    return strncmp(s, word, n) == 0 &&
           !isalnum((unsigned char)s[n]) && s[n] != '_';
}

static void strip_owned_marker(char *s)
{
    char *w = s;

    while (*s != '\0') {
        if (starts_word_text(s, "owned")) {
            s += 5;
            while (isspace((unsigned char)*s)) {
                s++;
            }
            continue;
        }
        if (starts_word_text(s, "borrow")) {
            s += 6;
            while (isspace((unsigned char)*s)) {
                s++;
            }
            continue;
        }
        if (*s != '%') {
            *w++ = *s;
        }
        s++;
    }
    *w = '\0';
}

static void strip_uniq_marker(char *s)
{
    char *p = trim(s);

    if (starts_word_text(p, "uniq")) {
        memmove(p, p + 4, strlen(p + 4) + 1);
        p = trim(p);
        memmove(s, p, strlen(p) + 1);
    }
}

static void strip_default_parameter_values(char *s)
{
    char *out = s;
    int paren = 0;
    int skipping = 0;

    while (*s != '\0') {
        if (*s == '(') {
            paren++;
            skipping = 0;
            *out++ = *s++;
        } else if (*s == ')') {
            if (paren > 0) {
                paren--;
            }
            skipping = 0;
            *out++ = *s++;
        } else if (paren > 0 && *s == '=') {
            skipping = 1;
            s++;
        } else if (skipping && (*s == ',' || *s == ')')) {
            skipping = 0;
            if (*s == ')') {
                if (paren > 0) {
                    paren--;
                }
            }
            *out++ = *s++;
        } else if (!skipping) {
            *out++ = *s++;
        } else {
            s++;
        }
    }
    *out = '\0';
}

static int looks_like_function_signature(const char *s)
{
    const char *open = strchr(s, '(');
    const char *close = strrchr(s, ')');

    if (open == NULL || close == NULL || close < open) {
        return 0;
    }
    if (starts_word_text(s, "if") || starts_word_text(s, "for") ||
        starts_word_text(s, "while") || starts_word_text(s, "switch")) {
        return 0;
    }
    if (starts_word_text(s, "struct") || starts_word_text(s, "union") ||
        starts_word_text(s, "enum")) {
        return 0;
    }
    if (starts_word_text(s, "static")) {
        return 0;
    }
    return 1;
}

static void emit_common_decl(FILE *out, const char *text)
{
    char buf[4096];
    char *s;
    size_t len;

    if (strlen(text) >= sizeof(buf)) {
        return;
    }
    strcpy(buf, text);
    s = trim(buf);
    if (*s == '\0' || *s == '#') {
        return;
    }
    if (starts_word_text(s, "generic")) {
        return;
    }
    strip_owned_marker(s);
    strip_uniq_marker(s);
    strip_default_parameter_values(s);
    len = strlen(s);
    while (len > 0 && isspace((unsigned char)s[len - 1])) {
        s[--len] = '\0';
    }
    if (len == 0) {
        return;
    }
    if (s[len - 1] == ';') {
        if (strchr(s, '=') != NULL && !starts_word_text(s, "typedef")) {
            return;
        }
        if (looks_like_function_signature(s) || starts_word_text(s, "extern") ||
            starts_word_text(s, "typedef")) {
            fprintf(out, "%s\n", s);
        }
    } else if (looks_like_function_signature(s)) {
        fprintf(out, "%s;\n", s);
    }
}

static void generate_common_header(struct SourceList *sources)
{
    FILE *out;
    int i;

    out = fopen("target/debug/common.h", "w");
    if (out == NULL) {
        die_errno("target/debug/common.h");
    }
    fputs("#ifndef C_MINUS_COMMON_H\n#define C_MINUS_COMMON_H\n\n", out);
    for (i = 0; i < sources->count; i++) {
        FILE *fp = fopen(sources->path[i], "r");
        char line[1024];
        char stmt[4096];
        size_t stmt_len = 0;
        int depth = 0;

        if (fp == NULL) {
            continue;
        }
        stmt[0] = '\0';
        while (fgets(line, sizeof(line), fp) != NULL) {
            char *s = trim(line);
            char *p;

            if (*s == '\0' || *s == '#') {
                continue;
            }
            if (depth == 0 && stmt_len + strlen(s) + 2 < sizeof(stmt)) {
                memcpy(stmt + stmt_len, s, strlen(s));
                stmt_len += strlen(s);
                stmt[stmt_len++] = ' ';
                stmt[stmt_len] = '\0';
            }
            for (p = s; *p != '\0'; p++) {
                if (*p == '{') {
                    if (depth == 0) {
                        char *brace = strchr(stmt, '{');
                        if (brace != NULL) {
                            *brace = '\0';
                        }
                        emit_common_decl(out, stmt);
                        stmt_len = 0;
                        stmt[0] = '\0';
                    }
                    depth++;
                } else if (*p == '}') {
                    if (depth > 0) {
                        depth--;
                    }
                } else if (*p == ';' && depth == 0) {
                    emit_common_decl(out, stmt);
                    stmt_len = 0;
                    stmt[0] = '\0';
                }
            }
        }
        fclose(fp);
    }
    fputs("\n#endif\n", out);
    if (fclose(out) != 0) {
        die_errno("target/debug/common.h");
    }
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
    m->ldflags[0] = '\0';
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
            } else if (strcmp(section, "build") == 0 && strcmp(key, "ldflags") == 0) {
                unquote_value(m->ldflags, sizeof(m->ldflags), value);
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
             "cflags = \"-std=gnu99 -Wall -Wextra\"\n"
             "ldflags = \"\"\n",
             name);
    write_file("C-.toml", text);
}

static void write_main_source(void)
{
    write_file("src/main.c-",
               "#include <stdio.h>\n"
               "#include <stdlib.h>\n"
               "#include <c-.h>\n"
               "\n"
               "int main(void)\n"
               "{\n"
               "    int* value = new int;\n"
               "    *value = 123;\n"
               "    if (*value == 123) {\n"
               "        puts(\"value 123\");\n"
               "    }\n"
               "    return 0;\n"
               "}\n");
}

static void write_stdlib_source(void)
{
    const char *stdlib_path;

    mkdir_p("lib");
    if (!file_exists("lib/c-.h")) {
        stdlib_path = getenv("CPM_STDLIB");
        if (copy_file_if_exists(stdlib_path, "lib/c-.h") ||
            copy_file_if_exists("/home/ab25cq/c-/lib/c-.h", "lib/c-.h")) {
            return;
        }
        write_file("lib/c-.h",
                   "#include <stdlib.h>\n"
                   "#include <stdio.h>\n"
                   "#include <execinfo.h>\n"
                   "\n"
                   "uniq void cminus_panic(const char* message, const char* file, int line)\n"
                   "{\n"
                   "    void* frames[64];\n"
                   "    int count;\n"
                   "\n"
                   "    fprintf(stderr, \"panic: %s at %s:%d\\n\", message, file, line);\n"
                   "    count = backtrace(frames, 64);\n"
                   "    backtrace_symbols_fd(frames, count, 2);\n"
                   "    abort();\n"
                   "}\n"
                   "\n"
                   "enum __CMinusIndex<T> {\n"
                   "    Some(T),\n"
                   "    None,\n"
                   "};\n"
                   "\n"
                   "generic<T>\n"
                   "struct Vec {\n"
                   "    T* data;\n"
                   "    int len;\n"
                   "    int cap;\n"
                   "};\n"
                   "\n"
                   "generic<T>\n"
                   "struct Vec<T>* Vec_new(void)\n"
                   "{\n"
                   "    return calloc(1, sizeof(struct Vec<T>));\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "void Vec_push(struct Vec<T>* self, T value)\n"
                   "{\n"
                   "    T* next;\n"
                   "    int next_cap = self->cap == 0 ? 4 : self->cap * 2;\n"
                   "\n"
                   "    if (self->len >= self->cap) {\n"
                   "        next = realloc(self->data, sizeof(T) * next_cap);\n"
                   "        if (next == NULL) {\n"
                   "            abort();\n"
                   "        }\n"
                   "        self->data = next;\n"
                   "        self->cap = next_cap;\n"
                   "    }\n"
                   "    self->data[self->len++] = value;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "int Vec_len(struct Vec<T>* self)\n"
                   "{\n"
                   "    return self == NULL ? 0 : self->len;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "int Vec_capacity(struct Vec<T>* self)\n"
                   "{\n"
                   "    return self == NULL ? 0 : self->cap;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "int Vec_is_empty(struct Vec<T>* self)\n"
                   "{\n"
                   "    return self == NULL || self->len == 0;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "void Vec_clear(struct Vec<T>* self)\n"
                   "{\n"
                   "    if (self != NULL) {\n"
                   "        self->len = 0;\n"
                   "    }\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "int Vec_reserve(struct Vec<T>* self, int cap)\n"
                   "{\n"
                   "    T* next;\n"
                   "\n"
                   "    if (self == NULL) {\n"
                   "        return 0;\n"
                   "    }\n"
                   "    if (cap <= self->cap) {\n"
                   "        return 1;\n"
                   "    }\n"
                   "    next = realloc(self->data, sizeof(T) * cap);\n"
                   "    if (next == NULL) {\n"
                   "        return 0;\n"
                   "    }\n"
                   "    self->data = next;\n"
                   "    self->cap = cap;\n"
                   "    return 1;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "struct __CMinusIndex<T> Vec_pop_opt(struct Vec<T>* self)\n"
                   "{\n"
                   "    if (self == NULL || self->len <= 0) {\n"
                   "        return new __CMinusIndex<T>.None();\n"
                   "    }\n"
                   "    self->len--;\n"
                   "    return new __CMinusIndex<T>.Some(self->data[self->len]);\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "void Vec_delete(struct Vec<T>* self)\n"
                   "{\n"
                   "    if (self != NULL) {\n"
                   "        free(self->data);\n"
                   "    }\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "T Vec_first(struct Vec<T>* self)\n"
                   "{\n"
                   "    return self->data[0];\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "T Vec_last(struct Vec<T>* self)\n"
                   "{\n"
                   "    return self->data[self->len - 1];\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "T Vec_get(struct Vec<T>* self, int index)\n"
                   "{\n"
                   "    return self->data[index];\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "int Vec_set(struct Vec<T>* self, int index, T value)\n"
                   "{\n"
                   "    if (self == NULL || index < 0 || index >= self->len) {\n"
                   "        return 0;\n"
                   "    }\n"
                   "    self->data[index] = value;\n"
                   "    return 1;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "struct __CMinusIndex<T> Vec_get_opt(struct Vec<T>* self, int index)\n"
                   "{\n"
                   "    if (self == NULL || index < 0 || index >= self->len) {\n"
                   "        return new __CMinusIndex<T>.None();\n"
                   "    }\n"
                   "    return new __CMinusIndex<T>.Some(self->data[index]);\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "struct ListNode {\n"
                   "    T value;\n"
                   "    struct ListNode<T>* next;\n"
                   "};\n"
                   "\n"
                   "generic<T>\n"
                   "struct List {\n"
                   "    struct ListNode<T>* head;\n"
                   "    struct ListNode<T>* tail;\n"
                   "    int len;\n"
                   "};\n"
                   "\n"
                   "generic<T>\n"
                   "struct List<T>* List_new(void)\n"
                   "{\n"
                   "    return calloc(1, sizeof(struct List<T>));\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "void List_push(struct List<T>* self, T value)\n"
                   "{\n"
                   "    struct ListNode<T>* node = calloc(1, sizeof(struct ListNode<T>));\n"
                   "\n"
                   "    if (node == NULL) {\n"
                   "        abort();\n"
                   "    }\n"
                   "    node->value = value;\n"
                   "    if (self->tail == NULL) {\n"
                   "        self->head = node;\n"
                   "        self->tail = node;\n"
                   "    } else {\n"
                   "        self->tail->next = node;\n"
                   "        self->tail = node;\n"
                   "    }\n"
                   "    self->len++;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "void List_push_front(struct List<T>* self, T value)\n"
                   "{\n"
                   "    struct ListNode<T>* node = calloc(1, sizeof(struct ListNode<T>));\n"
                   "\n"
                   "    if (node == NULL) {\n"
                   "        abort();\n"
                   "    }\n"
                   "    node->value = value;\n"
                   "    node->next = self->head;\n"
                   "    self->head = node;\n"
                   "    if (self->tail == NULL) {\n"
                   "        self->tail = node;\n"
                   "    }\n"
                   "    self->len++;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "int List_len(struct List<T>* self)\n"
                   "{\n"
                   "    return self == NULL ? 0 : self->len;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "int List_is_empty(struct List<T>* self)\n"
                   "{\n"
                   "    return self == NULL || self->len == 0;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "void List_clear(struct List<T>* self)\n"
                   "{\n"
                   "    struct ListNode<T>* node;\n"
                   "\n"
                   "    if (self == NULL) {\n"
                   "        return;\n"
                   "    }\n"
                   "    node = self->head;\n"
                   "    while (node != NULL) {\n"
                   "        struct ListNode<T>* next = node->next;\n"
                   "        free(node);\n"
                   "        node = next;\n"
                   "    }\n"
                   "    self->head = NULL;\n"
                   "    self->tail = NULL;\n"
                   "    self->len = 0;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "struct __CMinusIndex<T> List_pop_front_opt(struct List<T>* self)\n"
                   "{\n"
                   "    struct ListNode<T>* node;\n"
                   "    T value;\n"
                   "\n"
                   "    if (self == NULL || self->head == NULL) {\n"
                   "        return new __CMinusIndex<T>.None();\n"
                   "    }\n"
                   "    node = self->head;\n"
                   "    value = node->value;\n"
                   "    self->head = node->next;\n"
                   "    if (self->head == NULL) {\n"
                   "        self->tail = NULL;\n"
                   "    }\n"
                   "    self->len--;\n"
                   "    free(node);\n"
                   "    return new __CMinusIndex<T>.Some(value);\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "void List_delete(struct List<T>* self)\n"
                   "{\n"
                   "    struct ListNode<T>* node;\n"
                   "\n"
                   "    if (self == NULL) {\n"
                   "        return;\n"
                   "    }\n"
                   "    node = self->head;\n"
                   "    while (node != NULL) {\n"
                   "        struct ListNode<T>* next = node->next;\n"
                   "        free(node);\n"
                   "        node = next;\n"
                   "    }\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "T List_first(struct List<T>* self)\n"
                   "{\n"
                   "    return self->head->value;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "T List_last(struct List<T>* self)\n"
                   "{\n"
                   "    return self->tail->value;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "T List_get(struct List<T>* self, int index)\n"
                   "{\n"
                   "    struct ListNode<T>* node = self->head;\n"
                   "    int i = 0;\n"
                   "\n"
                   "    while (i < index) {\n"
                   "        node = node->next;\n"
                   "        i++;\n"
                   "    }\n"
                   "    return node->value;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "int List_set(struct List<T>* self, int index, T value)\n"
                   "{\n"
                   "    struct ListNode<T>* node;\n"
                   "    int i;\n"
                   "\n"
                   "    if (self == NULL || index < 0 || index >= self->len) {\n"
                   "        return 0;\n"
                   "    }\n"
                   "    node = self->head;\n"
                   "    i = 0;\n"
                   "    while (i < index) {\n"
                   "        node = node->next;\n"
                   "        i++;\n"
                   "    }\n"
                   "    node->value = value;\n"
                   "    return 1;\n"
                   "}\n"
                   "\n"
                   "generic<T>\n"
                   "struct __CMinusIndex<T> List_get_opt(struct List<T>* self, int index)\n"
                   "{\n"
                   "    struct ListNode<T>* node;\n"
                   "    int i;\n"
                   "\n"
                   "    if (self == NULL || index < 0 || index >= self->len) {\n"
                   "        return new __CMinusIndex<T>.None();\n"
                   "    }\n"
                   "    node = self->head;\n"
                   "    i = 0;\n"
                   "    while (i < index) {\n"
                   "        node = node->next;\n"
                   "        i++;\n"
                   "    }\n"
                   "    return new __CMinusIndex<T>.Some(node->value);\n"
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

static int file_has_main_function(const char *path)
{
    FILE *fp = fopen(path, "r");
    char line[1024];

    if (fp == NULL) {
        return 0;
    }
    while (fgets(line, sizeof(line), fp) != NULL) {
        char *p = line;

        while ((p = strstr(p, "main")) != NULL) {
            char before = p == line ? '\0' : p[-1];
            char *after = p + 4;

            if ((before == '\0' || !(isalnum((unsigned char)before) || before == '_')) &&
                !(isalnum((unsigned char)*after) || *after == '_')) {
                while (isspace((unsigned char)*after)) {
                    after++;
                }
                if (*after == '(') {
                    fclose(fp);
                    return 1;
                }
            }
            p += 4;
        }
    }
    fclose(fp);
    return 0;
}

static void write_c_with_common_include(const char *dst, const char *src, int include_common)
{
    FILE *in = fopen(src, "r");
    FILE *out;
    char line[4096];
    int inserted = 0;
    int saw_common = 0;

    if (in == NULL) {
        die_errno(src);
    }
    out = fopen(dst, "w");
    if (out == NULL) {
        fclose(in);
        die_errno(dst);
    }
    while (fgets(line, sizeof(line), in) != NULL) {
        char tmp[4096];
        char *s;

        strncpy(tmp, line, sizeof(tmp) - 1);
        tmp[sizeof(tmp) - 1] = '\0';
        s = trim(tmp);
        if (!inserted) {
            if (strncmp(s, "#include", 8) == 0) {
                if (strstr(s, "\"common.h\"") != NULL || strstr(s, "<common.h>") != NULL) {
                    saw_common = 1;
                }
                fputs(line, out);
                continue;
            }
            if (*s == '\0' || strncmp(s, "#define", 7) == 0) {
                fputs(line, out);
                continue;
            }
            if (include_common && !saw_common) {
                fputs("#include \"common.h\"\n", out);
            }
            inserted = 1;
        }
        fputs(line, out);
    }
    if (ferror(in)) {
        fclose(in);
        fclose(out);
        die_errno(src);
    }
    if (!inserted) {
        if (include_common && !saw_common) {
            fputs("#include \"common.h\"\n", out);
        }
    }
    if (fclose(in) != 0) {
        fclose(out);
        die_errno(src);
    }
    if (fclose(out) != 0) {
        die_errno(dst);
    }
}

static int cmd_build_with_flags(const char *extra_cflags)
{
    struct Manifest m;
    char q_translator[PATH_MAX_LEN * 2];
    char q_out[PATH_MAX_LEN * 2];
    char cmd[PATH_MAX_LEN * 12];
    char *slash;
    const char *translator = getenv("CPM_C_MINUS");
    struct SourceList sources;
    int i;

    if (translator == NULL || translator[0] == '\0') {
        translator = "c-";
    }
    read_manifest(&m);
    mkdir_p("target/debug");
    collect_sources(&sources, m.src);
    generate_common_header(&sources);

    shell_quote(q_translator, sizeof(q_translator), translator);
    shell_quote(q_out, sizeof(q_out), m.out);

    for (i = 0; i < sources.count; i++) {
        char c_path[PATH_MAX_LEN];
        char tmp_path[PATH_MAX_LEN + 5];
        char q_src[PATH_MAX_LEN * 2];
        char q_c[PATH_MAX_LEN * 2];
        int emit_uniq = file_has_main_function(sources.path[i]);

        generated_c_path(c_path, sizeof(c_path), sources.path[i], &m);
        snprintf(tmp_path, sizeof(tmp_path), "%s.tmp", c_path);
        shell_quote(q_src, sizeof(q_src), sources.path[i]);
        shell_quote(q_c, sizeof(q_c), tmp_path);
        snprintf(cmd, sizeof(cmd), "C_MINUS_EMIT_UNIQ=%d %s %s > %s",
                 emit_uniq, q_translator, q_src, q_c);
        if (run_cmd(cmd) != 0) {
            return 1;
        }
        write_c_with_common_include(c_path, tmp_path, sources.count > 1);
        unlink(tmp_path);
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
        snprintf(cmd, sizeof(cmd), "%s %s %s -Itarget/debug", m.compiler, m.cflags, extra_cflags);
    } else {
        snprintf(cmd, sizeof(cmd), "%s %s -Itarget/debug", m.compiler, m.cflags);
    }
    append_generated_c_paths(cmd, sizeof(cmd), &sources, &m);
    if (strlen(cmd) + strlen(q_out) + 5 >= sizeof(cmd)) {
        die("cpm: command too long");
    }
    strcat(cmd, " -o ");
    strcat(cmd, q_out);
    if (m.ldflags[0] != '\0') {
        if (strlen(cmd) + strlen(m.ldflags) + 2 >= sizeof(cmd)) {
            die("cpm: command too long");
        }
        strcat(cmd, " ");
        strcat(cmd, m.ldflags);
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
