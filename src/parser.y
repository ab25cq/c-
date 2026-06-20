%{
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern FILE *yyin;
extern int yylineno;

#define NAME_MAX_LEN 64
#define MAX_OWNED 128
#define MAX_FUNCS 128
#define MAX_SYMBOLS 256
#define MAX_TAGS 128
#define MAX_FINALIZERS 128
#define MAX_FIELDS 64

struct Text {
    char *text;
    size_t len;
    size_t cap;
    int tail_return;
    struct Node *ast;
};

enum TypeKind {
    TY_UNKNOWN,
    TY_VOID,
    TY_CHAR,
    TY_SHORT,
    TY_INT,
    TY_LONG,
    TY_FLOAT,
    TY_DOUBLE,
    TY_STRUCT,
    TY_UNION,
    TY_ENUM
};

struct Type {
    enum TypeKind kind;
    struct Type *base;
    int ptr;
    int owned;
    int size;
    int align;
    char tag[NAME_MAX_LEN];
};

struct Owned {
    char name[MAX_OWNED][NAME_MAX_LEN];
    struct Type type[MAX_OWNED];
    int count;
};

struct OwnedField {
    char name[NAME_MAX_LEN];
    struct Type type;
};

struct StructFinalizer {
    char tag[NAME_MAX_LEN];
    struct OwnedField fields[MAX_FIELDS];
    int count;
};

struct StructFinalizers {
    struct StructFinalizer fin[MAX_FINALIZERS];
    int count;
};

struct StructClones {
    struct StructFinalizer fin[MAX_FINALIZERS];
    int count;
};

enum NodeKind {
    ND_NULL_EXPR,
    ND_BLOCK,
    ND_EXPR_STMT,
    ND_RETURN,
    ND_DECL,
    ND_ASSIGN,
    ND_FUNCALL,
    ND_IF,
    ND_WHILE,
    ND_DO,
    ND_S_STRING,
    ND_RAW
};

struct Obj {
    struct Obj *next;
    char name[NAME_MAX_LEN];
    struct Type *ty;
    int is_local;
    int is_function;
};

struct VarScope {
    struct VarScope *next;
    char name[NAME_MAX_LEN];
    struct Obj *var;
};

struct TagScope {
    struct TagScope *next;
    char name[NAME_MAX_LEN];
    struct Type *ty;
};

struct Node {
    enum NodeKind kind;
    struct Node *next;
    struct Node *lhs;
    struct Node *rhs;
    struct Node *body;
    struct Node *cond;
    struct Node *then;
    struct Node *els;
    struct Type *ty;
    struct Obj *var;
    char *tok;
};

struct Funcs {
    char name[MAX_FUNCS][NAME_MAX_LEN];
    struct Type ret[MAX_FUNCS];
    int count;
};

struct Symbol {
    char name[NAME_MAX_LEN];
    struct Type type;
    struct Obj *var;
};

struct Symbols {
    struct Symbol sym[MAX_SYMBOLS];
    int count;
};

struct Tag {
    enum TypeKind kind;
    char name[NAME_MAX_LEN];
    struct Type *ty;
};

struct Tags {
    struct Tag tag[MAX_TAGS];
    int count;
};

static struct Text *g_output;
static struct Owned g_owned;
static struct Owned g_finalized_locals;
static struct Funcs g_malloc_funcs;
static struct Symbols g_globals;
static struct Symbols g_locals;
static struct Tags g_tags;
static struct StructFinalizers g_struct_finalizers;
static struct StructClones g_struct_clones;
static struct Obj *g_objs;
static struct VarScope *g_var_scope;
static struct TagScope *g_tag_scope;
static int g_in_function;
static int g_top_block_is_function;
static int g_in_aggregate_struct;
static int g_skip_next_semi;
static char g_current_struct_tag[NAME_MAX_LEN];
static int g_right_value_id;
static int g_need_string_h;
static int g_need_string_typedef;

int yylex(void);
static void yyerror(const char *msg);

static void die(const char *msg);
static void *xmalloc(size_t size);
static struct Text *text_new(void);
static void text_add_n(struct Text *n, const char *p, size_t len);
static void text_add(struct Text *n, const char *p);
static void text_add_ch(struct Text *n, char c);
static struct Text *text_join(struct Text *a, struct Text *b);
static struct Text *text_join3(struct Text *a, struct Text *b, struct Text *c);
static struct Text *text_join4(struct Text *a, struct Text *b, struct Text *c, struct Text *d);
static void text_free(struct Text *n);
static struct Node *ast_new(enum NodeKind kind, const char *tok);
static struct Node *ast_append(struct Node *head, struct Node *node);
static struct Node *ast_raw(enum NodeKind kind, const char *tok);
static struct Node *ast_block(struct Node *body);
static struct Type *type_copy(struct Type type);
static struct Obj *obj_new(const char *name, struct Type type, int is_local, int is_function);
static void begin_function(void);
static void begin_top_block(struct Text *head);
static struct Text *process_standalone_semi(struct Text *semi);
static struct Text *finish_top_block(struct Text *head, struct Text *lb, struct Text *body, struct Text *rb);
static struct Text *process_statement(struct Text *stmt, struct Text *semi);
static struct Text *process_return(struct Text *ret, struct Text *expr, struct Text *semi);
static struct Text *process_external_decl(struct Text *decl, struct Text *semi);
static struct Text *process_control_head(struct Text *head);
static int find_assignment(const char *s);
static int malloc_func_index(const char *name);
static void append_indent_from(const char *s, struct Text *out);
static int rhs_has_malloc_call(const char *rhs, char *func_name);
static int rhs_has_new_expr(const char *rhs, struct Type *type);
static int rhs_has_clone_expr(const char *rhs, struct Type *type);
static struct Text *strip_attributes(struct Text *in);
static struct Text *remove_percent(struct Text *in);
static void check_owned_pointer_arithmetic(const char *stmt);
static int struct_field_type(const char *tag, const char *field, struct Type *type);
static struct StructFinalizer *struct_clone_find(const char *tag);
static struct StructFinalizer *struct_clone_get(const char *tag);
static struct Text *add_zero_initializer(struct Text *in);
static struct Text *rewrite_new_expressions(struct Text *in);
static struct Text *rewrite_clone_expressions(struct Text *in);
static struct Text *rewrite_method_calls(struct Text *in);
static void append_struct_clone_name(struct Text *out, const char *tag);
static void append_struct_clone_definition(struct Text *out, struct StructFinalizer *clone);
static void append_finalize_for_type(struct Text *out, const char *indent, const char *expr, struct Type type);
static struct Text *prepend_owned_assignment_release(struct Text *stmt, const char *original, const char *lhs_expr, struct Type type);
static void append_zero_clear_after_decl(struct Text *stmt, const char *original, const char *name);
%}

%code requires {
struct Text;
}

%union {
    struct Text *node;
}

%token <node> IDENT NUMBER STRING_LITERAL CHAR_LITERAL PP_LINE RETURN KEYWORD OP
%token <node> LBRACE RBRACE LPAREN RPAREN LBRACKET RBRACKET SEMI COMMA EQUAL PERCENT OTHER

%type <node> translation_unit external_item top_seq top_part token token_no_comma
%type <node> paren_group paren_items paren_part bracket_group bracket_items bracket_part
%type <node> compound_items compound_item stmt_seq stmt_part return_statement

%start translation_unit

%%

translation_unit
    : /* empty */
        { $$ = text_new(); }
    | translation_unit external_item
        { $$ = text_join($1, $2); g_output = $$; }
    ;

external_item
    : PP_LINE
        { $$ = $1; }
    | SEMI
        { $$ = process_standalone_semi($1); }
    | top_seq SEMI
        { $$ = process_external_decl($1, $2); }
    | top_seq LBRACE
        { begin_top_block($1); }
      compound_items RBRACE
        { $$ = finish_top_block($1, $2, $4, $5); }
    ;

top_seq
    : top_part
        { $$ = $1; }
    | top_seq top_part
        { $$ = text_join($1, $2); }
    ;

top_part
    : token_no_comma
        { $$ = $1; }
    | paren_group
        { $$ = $1; }
    | bracket_group
        { $$ = $1; }
    ;

compound_items
    : /* empty */
        { $$ = text_new(); }
    | compound_items compound_item
        { $$ = text_join($1, $2); }
    ;

compound_item
    : PP_LINE
        { $$ = $1; }
    | SEMI
        { $$ = $1; }
    | return_statement
        { $$ = $1; }
    | stmt_seq SEMI
        { $$ = process_statement($1, $2); }
    | stmt_seq COMMA
        { $$ = text_join($1, $2); $$->tail_return = 0; }
    | LBRACE compound_items RBRACE
        { $$ = text_join3($1, $2, $3); $$->tail_return = 0; }
    | stmt_seq LBRACE compound_items RBRACE
        { $$ = text_join4(process_control_head($1), $2, $3, $4); $$->tail_return = 0; }
    ;

return_statement
    : RETURN SEMI
        { $$ = process_return($1, text_new(), $2); }
    | RETURN stmt_seq SEMI
        { $$ = process_return($1, $2, $3); }
    ;

stmt_seq
    : stmt_part
        { $$ = $1; }
    | stmt_seq stmt_part
        { $$ = text_join($1, $2); }
    ;

stmt_part
    : token_no_comma
        { $$ = $1; }
    | paren_group
        { $$ = $1; }
    | bracket_group
        { $$ = $1; }
    ;

paren_group
    : LPAREN paren_items RPAREN
        { $$ = text_join3($1, $2, $3); }
    ;

paren_items
    : /* empty */
        { $$ = text_new(); }
    | paren_items paren_part
        { $$ = text_join($1, $2); }
    ;

paren_part
    : token
        { $$ = $1; }
    | paren_group
        { $$ = $1; }
    | bracket_group
        { $$ = $1; }
    ;

bracket_group
    : LBRACKET bracket_items RBRACKET
        { $$ = text_join3($1, $2, $3); }
    ;

bracket_items
    : /* empty */
        { $$ = text_new(); }
    | bracket_items bracket_part
        { $$ = text_join($1, $2); }
    ;

bracket_part
    : token
        { $$ = $1; }
    | paren_group
        { $$ = $1; }
    | bracket_group
        { $$ = $1; }
    ;

token
    : IDENT
        { $$ = $1; }
    | NUMBER
        { $$ = $1; }
    | STRING_LITERAL
        { $$ = $1; }
    | CHAR_LITERAL
        { $$ = $1; }
    | KEYWORD
        { $$ = $1; }
    | OP
        { $$ = $1; }
    | COMMA
        { $$ = $1; }
    | EQUAL
        { $$ = $1; }
    | PERCENT
        { $$ = $1; }
    | OTHER
        { $$ = $1; }
    ;

token_no_comma
    : IDENT
        { $$ = $1; }
    | NUMBER
        { $$ = $1; }
    | STRING_LITERAL
        { $$ = $1; }
    | CHAR_LITERAL
        { $$ = $1; }
    | KEYWORD
        { $$ = $1; }
    | OP
        { $$ = $1; }
    | EQUAL
        { $$ = $1; }
    | PERCENT
        { $$ = $1; }
    | OTHER
        { $$ = $1; }
    ;

%%

static void die(const char *msg)
{
    fputs(msg, stderr);
    fputc('\n', stderr);
    exit(1);
}

static void *xmalloc(size_t size)
{
    void *p = malloc(size);
    if (p == NULL) {
        die("out of memory");
    }
    return p;
}

static struct Text *text_new(void)
{
    struct Text *n = xmalloc(sizeof(*n));
    n->cap = 64;
    n->len = 0;
    n->tail_return = 0;
    n->ast = NULL;
    n->text = xmalloc(n->cap);
    n->text[0] = '\0';
    return n;
}

static void text_reserve(struct Text *n, size_t need)
{
    char *p;
    while (n->cap < need) {
        n->cap *= 2;
    }
    p = realloc(n->text, n->cap);
    if (p == NULL) {
        die("out of memory");
    }
    n->text = p;
}

static void text_add_n(struct Text *n, const char *p, size_t len)
{
    if (n->len + len + 1 > n->cap) {
        text_reserve(n, n->len + len + 1);
    }
    memcpy(n->text + n->len, p, len);
    n->len += len;
    n->text[n->len] = '\0';
}

static void text_add(struct Text *n, const char *p)
{
    text_add_n(n, p, strlen(p));
}

static void text_add_ch(struct Text *n, char c)
{
    text_add_n(n, &c, 1);
}

static struct Text *text_join(struct Text *a, struct Text *b)
{
    text_add_n(a, b->text, b->len);
    a->tail_return = b->tail_return;
    a->ast = ast_append(a->ast, b->ast);
    text_free(b);
    return a;
}

static struct Text *text_join3(struct Text *a, struct Text *b, struct Text *c)
{
    return text_join(text_join(a, b), c);
}

static struct Text *text_join4(struct Text *a, struct Text *b, struct Text *c, struct Text *d)
{
    return text_join(text_join3(a, b, c), d);
}

static void text_free(struct Text *n)
{
    if (n != NULL) {
        free(n->text);
        free(n);
    }
}

static char *xstrdup(const char *s)
{
    size_t len;
    char *p;

    if (s == NULL) {
        return NULL;
    }
    len = strlen(s) + 1;
    p = xmalloc(len);
    memcpy(p, s, len);
    return p;
}

static char *xstrndup(const char *s, size_t len)
{
    char *p = xmalloc(len + 1);

    memcpy(p, s, len);
    p[len] = '\0';
    return p;
}

static struct Node *ast_new(enum NodeKind kind, const char *tok)
{
    struct Node *node = xmalloc(sizeof(*node));

    memset(node, 0, sizeof(*node));
    node->kind = kind;
    node->tok = xstrdup(tok);
    return node;
}

static struct Node *ast_append(struct Node *head, struct Node *node)
{
    struct Node *p;

    if (head == NULL) {
        return node;
    }
    if (node == NULL) {
        return head;
    }
    for (p = head; p->next != NULL; p = p->next) {
    }
    p->next = node;
    return head;
}

static struct Node *ast_raw(enum NodeKind kind, const char *tok)
{
    return ast_new(kind, tok);
}

static struct Node *ast_block(struct Node *body)
{
    struct Node *node = ast_new(ND_BLOCK, NULL);

    node->body = body;
    return node;
}

static struct Type *type_copy(struct Type type)
{
    struct Type *copy = xmalloc(sizeof(*copy));

    *copy = type;
    return copy;
}

static struct Obj *obj_new(const char *name, struct Type type, int is_local, int is_function)
{
    struct Obj *obj = xmalloc(sizeof(*obj));

    memset(obj, 0, sizeof(*obj));
    strncpy(obj->name, name, NAME_MAX_LEN - 1);
    obj->name[NAME_MAX_LEN - 1] = '\0';
    obj->ty = type_copy(type);
    obj->is_local = is_local;
    obj->is_function = is_function;
    obj->next = g_objs;
    g_objs = obj;
    return obj;
}

static void var_scope_push(const char *name, struct Obj *var)
{
    struct VarScope *scope = xmalloc(sizeof(*scope));

    memset(scope, 0, sizeof(*scope));
    strncpy(scope->name, name, NAME_MAX_LEN - 1);
    scope->name[NAME_MAX_LEN - 1] = '\0';
    scope->var = var;
    scope->next = g_var_scope;
    g_var_scope = scope;
}

static void tag_scope_push(const char *name, struct Type type)
{
    struct TagScope *scope = xmalloc(sizeof(*scope));

    memset(scope, 0, sizeof(*scope));
    strncpy(scope->name, name, NAME_MAX_LEN - 1);
    scope->name[NAME_MAX_LEN - 1] = '\0';
    scope->ty = type_copy(type);
    scope->next = g_tag_scope;
    g_tag_scope = scope;
}

static int is_ident_start(int c)
{
    return isalpha((unsigned char)c) || c == '_';
}

static int is_ident(int c)
{
    return isalnum((unsigned char)c) || c == '_';
}

static void yyerror(const char *msg)
{
    fprintf(stderr, "cauto: parse error near line %d: %s\n", yylineno, msg);
}

static int starts_word(const char *s, const char *word)
{
    size_t n = strlen(word);
    return strncmp(s, word, n) == 0 && !is_ident((unsigned char)s[n]);
}

static const char *skip_ws(const char *s)
{
    while (isspace((unsigned char)*s)) {
        s++;
    }
    return s;
}

static const char *read_name(const char *s, char *name)
{
    const char *p = s;
    size_t n;
    name[0] = '\0';
    if (!is_ident_start((unsigned char)*p)) {
        return s;
    }
    p++;
    while (is_ident((unsigned char)*p)) {
        p++;
    }
    n = (size_t)(p - s);
    if (n >= NAME_MAX_LEN) {
        n = NAME_MAX_LEN - 1;
    }
    memcpy(name, s, n);
    name[n] = '\0';
    return p;
}

static struct Type type_make(enum TypeKind kind, int ptr, const char *tag)
{
    struct Type t;
    t.kind = kind;
    t.base = NULL;
    t.ptr = ptr;
    t.owned = 0;
    t.size = 0;
    t.align = 1;
    t.tag[0] = '\0';
    if (tag != NULL) {
        strncpy(t.tag, tag, NAME_MAX_LEN - 1);
        t.tag[NAME_MAX_LEN - 1] = '\0';
    }
    switch (kind) {
    case TY_CHAR:
        t.size = 1;
        t.align = 1;
        break;
    case TY_SHORT:
        t.size = 2;
        t.align = 2;
        break;
    case TY_INT:
    case TY_FLOAT:
    case TY_ENUM:
        t.size = 4;
        t.align = 4;
        break;
    case TY_LONG:
    case TY_DOUBLE:
        t.size = 8;
        t.align = 8;
        break;
    case TY_VOID:
        t.size = 1;
        t.align = 1;
        break;
    default:
        t.size = 0;
        t.align = 1;
        break;
    }
    if (ptr > 0) {
        struct Type base = t;
        int depth;
        base.ptr = 0;
        base.owned = 0;
        t.size = 8;
        t.align = 8;
        for (depth = 0; depth < ptr; depth++) {
            t.base = type_copy(base);
        }
    }
    return t;
}

static struct Type type_unknown(void)
{
    return type_make(TY_UNKNOWN, 0, NULL);
}

static int type_is_known(struct Type t)
{
    return t.kind != TY_UNKNOWN;
}

static int type_is_string(struct Type t)
{
    return t.kind == TY_CHAR && t.ptr == 1 && t.owned;
}

static const char *type_kind_name(enum TypeKind kind)
{
    switch (kind) {
    case TY_VOID:
        return "void";
    case TY_CHAR:
        return "char";
    case TY_SHORT:
        return "short";
    case TY_INT:
        return "int";
    case TY_LONG:
        return "long";
    case TY_FLOAT:
        return "float";
    case TY_DOUBLE:
        return "double";
    case TY_STRUCT:
        return "struct";
    case TY_UNION:
        return "union";
    case TY_ENUM:
        return "enum";
    default:
        return "unknown";
    }
}

static void type_to_string(struct Type t, char *buf, size_t size)
{
    char stars[16];
    int i;
    size_t off;

    stars[0] = '\0';
    for (i = 0; i < t.ptr && i < (int)sizeof(stars) - 1; i++) {
        stars[i] = '*';
    }
    stars[i] = '\0';

    if (t.kind == TY_STRUCT || t.kind == TY_UNION || t.kind == TY_ENUM) {
        snprintf(buf, size, "%s %s%s", type_kind_name(t.kind), t.tag, stars);
    } else {
        snprintf(buf, size, "%s%s", type_kind_name(t.kind), stars);
    }
    off = strlen(buf);
    if (t.owned && off + 1 < size) {
        buf[off] = '%';
        buf[off + 1] = '\0';
    }
}

static void append_c_type(struct Text *out, struct Type t)
{
    int i;

    if (t.kind == TY_STRUCT || t.kind == TY_UNION || t.kind == TY_ENUM) {
        text_add(out, type_kind_name(t.kind));
        if (t.tag[0] != '\0') {
            text_add(out, " ");
            text_add(out, t.tag);
        }
    } else {
        text_add(out, type_kind_name(t.kind));
    }
    for (i = 0; i < t.ptr; i++) {
        text_add_ch(out, '*');
    }
}

static int type_same_unowned(struct Type a, struct Type b)
{
    if (a.kind != b.kind || a.ptr != b.ptr) {
        return 0;
    }
    if (a.kind == TY_STRUCT || a.kind == TY_UNION || a.kind == TY_ENUM) {
        return strcmp(a.tag, b.tag) == 0;
    }
    return 1;
}

static int type_compatible(struct Type lhs, struct Type rhs)
{
    if (!type_is_known(lhs) || !type_is_known(rhs)) {
        return 1;
    }
    if (type_same_unowned(lhs, rhs)) {
        return 1;
    }
    if (lhs.ptr > 0 && rhs.ptr > 0 && (lhs.kind == TY_VOID || rhs.kind == TY_VOID)) {
        return 1;
    }
    if (lhs.kind == TY_ENUM && rhs.kind == TY_INT && lhs.ptr == 0 && rhs.ptr == 0) {
        return 1;
    }
    return 0;
}

static void type_error(const char *what, struct Type lhs, struct Type rhs)
{
    char lbuf[128];
    char rbuf[128];
    type_to_string(lhs, lbuf, sizeof(lbuf));
    type_to_string(rhs, rbuf, sizeof(rbuf));
    fprintf(stderr, "cauto: type error: cannot assign %s to %s in %s\n", rbuf, lbuf, what);
    exit(1);
}

static void tag_add(enum TypeKind kind, const char *name)
{
    int i;
    struct Type type;
    if (name[0] == '\0') {
        return;
    }
    for (i = 0; i < g_tags.count; i++) {
        if (g_tags.tag[i].kind == kind && strcmp(g_tags.tag[i].name, name) == 0) {
            return;
        }
    }
    if (g_tags.count >= MAX_TAGS) {
        die("too many struct/union/enum tags");
    }
    g_tags.tag[g_tags.count].kind = kind;
    strncpy(g_tags.tag[g_tags.count].name, name, NAME_MAX_LEN - 1);
    g_tags.tag[g_tags.count].name[NAME_MAX_LEN - 1] = '\0';
    type = type_make(kind, 0, name);
    g_tags.tag[g_tags.count].ty = type_copy(type);
    tag_scope_push(name, type);
    g_tags.count++;
}

static void register_tag_after_keyword(const char *p, enum TypeKind kind)
{
    char name[NAME_MAX_LEN];
    p = skip_ws(p);
    if (is_ident_start((unsigned char)*p)) {
        read_name(p, name);
        tag_add(kind, name);
    }
}

static void register_tags_in_text(const char *s)
{
    const char *p = s;
    while (*p != '\0') {
        if ((p == s || !is_ident((unsigned char)p[-1])) && starts_word(p, "struct")) {
            register_tag_after_keyword(p + 6, TY_STRUCT);
            p += 6;
        } else if ((p == s || !is_ident((unsigned char)p[-1])) && starts_word(p, "union")) {
            register_tag_after_keyword(p + 5, TY_UNION);
            p += 5;
        } else if ((p == s || !is_ident((unsigned char)p[-1])) && starts_word(p, "enum")) {
            register_tag_after_keyword(p + 4, TY_ENUM);
            p += 4;
        } else {
            p++;
        }
    }
}

static struct Symbol *symbol_find_in(struct Symbols *symbols, const char *name)
{
    int i;
    for (i = symbols->count - 1; i >= 0; i--) {
        if (strcmp(symbols->sym[i].name, name) == 0) {
            return &symbols->sym[i];
        }
    }
    return NULL;
}

static struct Symbol *symbol_find(const char *name)
{
    struct Symbol *s;
    if (g_in_function) {
        s = symbol_find_in(&g_locals, name);
        if (s != NULL) {
            return s;
        }
    }
    return symbol_find_in(&g_globals, name);
}

static void symbol_add_to(struct Symbols *symbols, const char *name, struct Type type)
{
    struct Symbol *old = symbol_find_in(symbols, name);
    struct Obj *var;
    if (name[0] == '\0') {
        return;
    }
    if (old != NULL) {
        old->type = type;
        if (old->var != NULL) {
            old->var->ty = type_copy(type);
        }
        return;
    }
    if (symbols->count >= MAX_SYMBOLS) {
        die("too many symbols");
    }
    strncpy(symbols->sym[symbols->count].name, name, NAME_MAX_LEN - 1);
    symbols->sym[symbols->count].name[NAME_MAX_LEN - 1] = '\0';
    symbols->sym[symbols->count].type = type;
    var = obj_new(name, type, g_in_function, 0);
    symbols->sym[symbols->count].var = var;
    var_scope_push(name, var);
    symbols->count++;
}

static void symbol_add(const char *name, struct Type type)
{
    if (g_in_function) {
        symbol_add_to(&g_locals, name, type);
    } else {
        symbol_add_to(&g_globals, name, type);
    }
}

static int skip_decl_word(const char *word)
{
    static const char *words[] = {
        "auto", "extern", "register", "static", "typedef", "const", "volatile",
        "restrict", "inline", "signed", "unsigned", "_Atomic", NULL
    };
    int i;
    for (i = 0; words[i] != NULL; i++) {
        if (strcmp(word, words[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

static enum TypeKind keyword_type(const char *word)
{
    if (strcmp(word, "void") == 0) {
        return TY_VOID;
    }
    if (strcmp(word, "char") == 0) {
        return TY_CHAR;
    }
    if (strcmp(word, "short") == 0) {
        return TY_SHORT;
    }
    if (strcmp(word, "int") == 0) {
        return TY_INT;
    }
    if (strcmp(word, "long") == 0) {
        return TY_LONG;
    }
    if (strcmp(word, "float") == 0) {
        return TY_FLOAT;
    }
    if (strcmp(word, "double") == 0) {
        return TY_DOUBLE;
    }
    return TY_UNKNOWN;
}

struct DeclInfo {
    int is_decl;
    int is_function;
    int has_init;
    const char *init;
    char name[NAME_MAX_LEN];
    struct Type type;
};

static int parse_base_type_prefix(const char *s, const char **base_end, struct Type *type)
{
    const char *p = skip_ws(s);
    char word[NAME_MAX_LEN];
    enum TypeKind kind = TY_UNKNOWN;
    char tag[NAME_MAX_LEN];

    tag[0] = '\0';
    while (is_ident_start((unsigned char)*p)) {
        const char *next = read_name(p, word);
        if (!skip_decl_word(word)) {
            break;
        }
        p = skip_ws(next);
    }

    if (starts_word(p, "struct")) {
        kind = TY_STRUCT;
        p = skip_ws(p + 6);
        if (is_ident_start((unsigned char)*p)) {
            p = read_name(p, tag);
            tag_add(kind, tag);
        }
    } else if (starts_word(p, "union")) {
        kind = TY_UNION;
        p = skip_ws(p + 5);
        if (is_ident_start((unsigned char)*p)) {
            p = read_name(p, tag);
            tag_add(kind, tag);
        }
    } else if (starts_word(p, "enum")) {
        kind = TY_ENUM;
        p = skip_ws(p + 4);
        if (is_ident_start((unsigned char)*p)) {
            p = read_name(p, tag);
            tag_add(kind, tag);
        }
    } else if (is_ident_start((unsigned char)*p)) {
        const char *next = read_name(p, word);
        if (strcmp(word, "string") == 0) {
            *base_end = next;
            *type = type_make(TY_CHAR, 1, NULL);
            type->owned = 1;
            g_need_string_typedef = 1;
            return 1;
        }
        kind = keyword_type(word);
        if (kind == TY_UNKNOWN) {
            return 0;
        }
        p = next;
        if (kind == TY_LONG) {
            const char *q = skip_ws(p);
            if (starts_word(q, "long")) {
                p = q + 4;
            } else if (starts_word(q, "int")) {
                p = q + 3;
            }
        } else if (kind == TY_SHORT) {
            const char *q = skip_ws(p);
            if (starts_word(q, "int")) {
                p = q + 3;
            }
        }
    } else {
        return 0;
    }

    *base_end = p;
    *type = type_make(kind, 0, tag);
    return 1;
}

static int parse_function_signature(const char *s, char *name, struct Type *ret)
{
    const char *base_end;
    const char *p;
    const char *open = NULL;
    const char *name_start;
    const char *name_end;
    struct Type base;
    int depth = 0;

    name[0] = '\0';
    *ret = type_unknown();
    if (!parse_base_type_prefix(s, &base_end, &base)) {
        return 0;
    }
    for (p = base_end; *p != '\0'; p++) {
        if (*p == '(' && depth == 0) {
            open = p;
            break;
        }
        if (*p == '[') {
            depth++;
        } else if (*p == ']' && depth > 0) {
            depth--;
        } else if (*p == ';' || *p == '=') {
            return 0;
        }
    }
    if (open == NULL) {
        return 0;
    }
    name_end = open;
    while (name_end > base_end && isspace((unsigned char)name_end[-1])) {
        name_end--;
    }
    name_start = name_end;
    while (name_start > base_end && is_ident((unsigned char)name_start[-1])) {
        name_start--;
    }
    if (name_start == name_end || !is_ident_start((unsigned char)*name_start)) {
        return 0;
    }
    if ((size_t)(name_end - name_start) >= NAME_MAX_LEN) {
        return 0;
    }
    memcpy(name, name_start, (size_t)(name_end - name_start));
    name[name_end - name_start] = '\0';

    *ret = base;
    for (p = base_end; p < name_start; p++) {
        if (*p == '*') {
            ret->ptr++;
        } else if (*p == '%') {
            ret->owned = 1;
        }
    }
    return 1;
}

static int parse_decl(const char *s, struct DeclInfo *decl)
{
    const char *p = skip_ws(s);
    const char *base_end;
    const char *limit;
    const char *scan;
    const char *name_start = NULL;
    const char *name_end = NULL;
    char word[NAME_MAX_LEN];
    int eq;
    int ptr = 0;
    struct Type base_type;

    memset(decl, 0, sizeof(*decl));
    decl->type = type_unknown();

    (void)word;
    if (!parse_base_type_prefix(p, &base_end, &base_type)) {
        return 0;
    }
    eq = find_assignment(s);
    limit = s + strlen(s);
    if (eq >= 0) {
        limit = s + eq;
        decl->has_init = 1;
        decl->init = s + eq + 1;
    }
    for (scan = base_end; scan < limit; scan++) {
        if (*scan == '*') {
            ptr++;
        }
        if (*scan == '%') {
            decl->type.owned = 1;
        }
        if (is_ident_start((unsigned char)*scan)) {
            char tmp[NAME_MAX_LEN];
            const char *end = read_name(scan, tmp);
            if (keyword_type(tmp) == TY_UNKNOWN && !skip_decl_word(tmp) &&
                strcmp(tmp, "struct") != 0 && strcmp(tmp, "union") != 0 && strcmp(tmp, "enum") != 0) {
                name_start = scan;
                name_end = end;
            }
            scan = end - 1;
        }
    }
    if (name_start == NULL) {
        decl->is_decl = 1;
        decl->type = base_type;
        decl->type.ptr += ptr;
        return 1;
    }
    if ((size_t)(name_end - name_start) >= NAME_MAX_LEN) {
        return 0;
    }
    memcpy(decl->name, name_start, (size_t)(name_end - name_start));
    decl->name[name_end - name_start] = '\0';
    decl->type = base_type;
    decl->type.ptr += ptr;
    decl->type.owned = base_type.owned || strchr(base_end, '%') != NULL;
    scan = skip_ws(name_end);
    if (*scan == '(' && eq < 0) {
        decl->is_function = 1;
    }
    decl->is_decl = 1;
    return 1;
}

static int is_string_typedef_decl(const char *s)
{
    struct DeclInfo decl;
    const char *p = skip_ws(s);

    if (!starts_word(p, "typedef")) {
        return 0;
    }
    if (!parse_decl(s, &decl)) {
        return 0;
    }
    return strcmp(decl.name, "string") == 0;
}

static int extract_lhs_name(const char *s, int eq, char *name)
{
    const char *p = s + eq;
    const char *end;
    while (p > s && isspace((unsigned char)p[-1])) {
        p--;
    }
    end = p;
    while (p > s && is_ident((unsigned char)p[-1])) {
        p--;
    }
    if (p == end || !is_ident_start((unsigned char)*p)) {
        name[0] = '\0';
        return 0;
    }
    if ((size_t)(end - p) >= NAME_MAX_LEN) {
        return 0;
    }
    memcpy(name, p, (size_t)(end - p));
    name[end - p] = '\0';
    return 1;
}

static char *slice_lhs_expr(const char *s, int eq)
{
    const char *p = s;
    const char *end = s + eq;

    while (p < end && isspace((unsigned char)*p)) {
        p++;
    }
    while (end > p && isspace((unsigned char)end[-1])) {
        end--;
    }
    return xstrndup(p, (size_t)(end - p));
}

static struct Type lhs_type_before_eq(const char *s, int eq, char *name)
{
    const char *p = s;
    const char *limit = s + eq;
    int deref = 0;
    struct Symbol *sym;
    struct Type t;

    while (p < limit && isspace((unsigned char)*p)) {
        p++;
    }
    while (p < limit && *p == '*') {
        deref++;
        p++;
        while (p < limit && isspace((unsigned char)*p)) {
            p++;
        }
    }
    if (!extract_lhs_name(s, eq, name)) {
        return type_unknown();
    }
    {
        const char *field_start = s + eq;
        const char *q;
        const char *op;
        const char *owner_end;
        const char *owner_start;
        char owner[NAME_MAX_LEN];
        struct Type field_type;

        while (field_start > s && isspace((unsigned char)field_start[-1])) {
            field_start--;
        }
        while (field_start > s && is_ident((unsigned char)field_start[-1])) {
            field_start--;
        }
        q = field_start;
        while (q > s && isspace((unsigned char)q[-1])) {
            q--;
        }
        op = NULL;
        if (q > s && q[-1] == '.') {
            op = q - 1;
        } else if (q > s + 1 && q[-1] == '>' && q[-2] == '-') {
            op = q - 2;
        }
        if (op != NULL) {
            owner_end = op;
            while (owner_end > s && isspace((unsigned char)owner_end[-1])) {
                owner_end--;
            }
            owner_start = owner_end;
            while (owner_start > s && is_ident((unsigned char)owner_start[-1])) {
                owner_start--;
            }
            if (owner_start < owner_end && (size_t)(owner_end - owner_start) < NAME_MAX_LEN) {
                memcpy(owner, owner_start, (size_t)(owner_end - owner_start));
                owner[owner_end - owner_start] = '\0';
                sym = symbol_find(owner);
                if (sym != NULL && sym->type.kind == TY_STRUCT &&
                    struct_field_type(sym->type.tag, name, &field_type)) {
                    return field_type;
                }
            }
        }
    }
    sym = symbol_find(name);
    if (sym == NULL) {
        return type_unknown();
    }
    t = sym->type;
    while (deref > 0 && t.ptr > 0) {
        t.ptr--;
        deref--;
    }
    if (deref > 0) {
        return type_unknown();
    }
    t.owned = 0;
    return t;
}

static struct Type expr_type(const char *s)
{
    char name[NAME_MAX_LEN];
    struct Symbol *sym;
    struct Type t;
    const char *p = skip_ws(s);

    if (*p == 's') {
        const char *q = skip_ws(p + 1);
        if (*q == '"') {
            t = type_make(TY_CHAR, 1, NULL);
            t.owned = 1;
            return t;
        }
    }
    if (rhs_has_new_expr(p, &t)) {
        return t;
    }
    if (*p == '"') {
        return type_make(TY_CHAR, 1, NULL);
    }
    if (isdigit((unsigned char)*p) || (*p == '\'')) {
        return type_make(TY_INT, 0, NULL);
    }
    if (*p == '&') {
        p = skip_ws(p + 1);
        if (is_ident_start((unsigned char)*p)) {
            read_name(p, name);
            sym = symbol_find(name);
            if (sym != NULL) {
                t = sym->type;
                t.ptr++;
                t.owned = 0;
                return t;
            }
        }
        return type_unknown();
    }
    if (*p == '*') {
        p = skip_ws(p + 1);
        if (is_ident_start((unsigned char)*p)) {
            read_name(p, name);
            sym = symbol_find(name);
            if (sym != NULL && sym->type.ptr > 0) {
                t = sym->type;
                t.ptr--;
                t.owned = 0;
                return t;
            }
        }
        return type_unknown();
    }
    if (is_ident_start((unsigned char)*p)) {
        const char *end = read_name(p, name);
        p = skip_ws(end);
        sym = symbol_find(name);
        if (sym != NULL) {
            t = sym->type;
            while (*p == '.' || (*p == '-' && p[1] == '>')) {
                char field[NAME_MAX_LEN];
                const char *field_end;

                if (*p == '.') {
                    p++;
                } else {
                    p += 2;
                }
                p = skip_ws(p);
                if (!is_ident_start((unsigned char)*p)) {
                    return type_unknown();
                }
                field_end = read_name(p, field);
                if (t.kind != TY_STRUCT || !struct_field_type(t.tag, field, &t)) {
                    return type_unknown();
                }
                p = skip_ws(field_end);
            }
            if (*p == '(') {
                if (malloc_func_index(name) >= 0) {
                    return g_malloc_funcs.ret[malloc_func_index(name)];
                }
                return type_unknown();
            }
            return t;
        }
        if (*p == '(') {
            if (malloc_func_index(name) >= 0) {
                return g_malloc_funcs.ret[malloc_func_index(name)];
            }
            return type_unknown();
        }
    }
    return type_unknown();
}

static void check_assignment_type(const char *what, struct Type lhs, struct Type rhs)
{
    if (!type_compatible(lhs, rhs)) {
        type_error(what, lhs, rhs);
    }
}

static int looks_like_aggregate_head(const char *s)
{
    const char *p = skip_ws(s);
    return starts_word(p, "struct") || starts_word(p, "union") || starts_word(p, "enum");
}

static int parse_struct_head(const char *s, char *tag)
{
    const char *p = skip_ws(s);
    char word[NAME_MAX_LEN];

    tag[0] = '\0';
    while (is_ident_start((unsigned char)*p)) {
        const char *next = read_name(p, word);
        if (!skip_decl_word(word)) {
            break;
        }
        p = skip_ws(next);
    }
    if (!starts_word(p, "struct")) {
        return 0;
    }
    p = skip_ws(p + 6);
    if (!is_ident_start((unsigned char)*p)) {
        return 0;
    }
    read_name(p, tag);
    return tag[0] != '\0';
}

static struct StructFinalizer *struct_finalizer_find(const char *tag)
{
    int i;

    if (tag[0] == '\0') {
        return NULL;
    }
    for (i = 0; i < g_struct_finalizers.count; i++) {
        if (strcmp(g_struct_finalizers.fin[i].tag, tag) == 0) {
            return &g_struct_finalizers.fin[i];
        }
    }
    return NULL;
}

static struct StructFinalizer *struct_finalizer_get(const char *tag)
{
    struct StructFinalizer *fin = struct_finalizer_find(tag);

    if (fin != NULL) {
        return fin;
    }
    if (g_struct_finalizers.count >= MAX_FINALIZERS) {
        die("too many struct finalizers");
    }
    fin = &g_struct_finalizers.fin[g_struct_finalizers.count++];
    memset(fin, 0, sizeof(*fin));
    strncpy(fin->tag, tag, NAME_MAX_LEN - 1);
    fin->tag[NAME_MAX_LEN - 1] = '\0';
    return fin;
}

static int type_has_finalizer(struct Type type)
{
    struct StructFinalizer *fin;

    if (type.kind != TY_STRUCT || type.tag[0] == '\0') {
        return 0;
    }
    fin = struct_finalizer_find(type.tag);
    return fin != NULL && fin->count > 0;
}

static int struct_field_type(const char *tag, const char *field, struct Type *type)
{
    struct StructFinalizer *fin = struct_finalizer_find(tag);
    struct StructFinalizer *clone = struct_clone_find(tag);
    int i;

    if (fin == NULL) {
        fin = clone;
    }
    if (fin == NULL) {
        return 0;
    }
    for (i = 0; i < fin->count; i++) {
        if (strcmp(fin->fields[i].name, field) == 0) {
            *type = fin->fields[i].type;
            return 1;
        }
    }
    return 0;
}

static void struct_finalizer_add_field(const char *tag, const char *field, struct Type type)
{
    struct StructFinalizer *fin = struct_finalizer_get(tag);
    int i;

    if (field[0] == '\0') {
        return;
    }
    for (i = 0; i < fin->count; i++) {
        if (strcmp(fin->fields[i].name, field) == 0) {
            fin->fields[i].type = type;
            return;
        }
    }
    if (fin->count >= MAX_FIELDS) {
        die("too many owned fields in one struct");
    }
    strncpy(fin->fields[fin->count].name, field, NAME_MAX_LEN - 1);
    fin->fields[fin->count].name[NAME_MAX_LEN - 1] = '\0';
    fin->fields[fin->count].type = type;
    fin->count++;
}

static struct StructFinalizer *struct_clone_find(const char *tag)
{
    int i;

    if (tag[0] == '\0') {
        return NULL;
    }
    for (i = 0; i < g_struct_clones.count; i++) {
        if (strcmp(g_struct_clones.fin[i].tag, tag) == 0) {
            return &g_struct_clones.fin[i];
        }
    }
    return NULL;
}

static struct StructFinalizer *struct_clone_get(const char *tag)
{
    struct StructFinalizer *clone = struct_clone_find(tag);

    if (clone != NULL) {
        return clone;
    }
    if (g_struct_clones.count >= MAX_FINALIZERS) {
        die("too many struct clones");
    }
    clone = &g_struct_clones.fin[g_struct_clones.count++];
    memset(clone, 0, sizeof(*clone));
    strncpy(clone->tag, tag, NAME_MAX_LEN - 1);
    clone->tag[NAME_MAX_LEN - 1] = '\0';
    return clone;
}

static void struct_clone_add_field(const char *tag, const char *field, struct Type type)
{
    struct StructFinalizer *clone = struct_clone_get(tag);
    int i;

    if (field[0] == '\0') {
        return;
    }
    for (i = 0; i < clone->count; i++) {
        if (strcmp(clone->fields[i].name, field) == 0) {
            clone->fields[i].type = type;
            return;
        }
    }
    if (clone->count >= MAX_FIELDS) {
        die("too many fields in one struct clone");
    }
    strncpy(clone->fields[clone->count].name, field, NAME_MAX_LEN - 1);
    clone->fields[clone->count].name[NAME_MAX_LEN - 1] = '\0';
    clone->fields[clone->count].type = type;
    clone->count++;
}

static int type_has_clone(struct Type type)
{
    struct StructFinalizer *clone;

    if (type.kind != TY_STRUCT || type.tag[0] == '\0') {
        return 0;
    }
    clone = struct_clone_find(type.tag);
    return clone != NULL;
}

static void begin_function(void)
{
    g_owned.count = 0;
    g_finalized_locals.count = 0;
    g_locals.count = 0;
    g_in_function = 1;
}

static void begin_top_block(struct Text *head)
{
    char name[NAME_MAX_LEN];
    struct Type ret;
    register_tags_in_text(head->text);
    g_top_block_is_function = parse_function_signature(head->text, name, &ret) || !looks_like_aggregate_head(head->text);
    g_in_aggregate_struct = 0;
    g_current_struct_tag[0] = '\0';
    if (g_top_block_is_function) {
        begin_function();
    } else if (parse_struct_head(head->text, name)) {
        g_in_aggregate_struct = 1;
        strncpy(g_current_struct_tag, name, NAME_MAX_LEN - 1);
        g_current_struct_tag[NAME_MAX_LEN - 1] = '\0';
        struct_finalizer_get(name);
        struct_clone_get(name);
    }
}

static struct Text *process_standalone_semi(struct Text *semi)
{
    if (g_skip_next_semi) {
        struct Text *out = text_new();
        g_skip_next_semi = 0;
        text_free(semi);
        return out;
    }
    return semi;
}

static int owned_index_in(struct Owned *owned, const char *name)
{
    int i;
    for (i = 0; i < owned->count; i++) {
        if (strcmp(owned->name[i], name) == 0) {
            return i;
        }
    }
    return -1;
}

static void owned_add_to(struct Owned *owned, const char *name, struct Type type)
{
    if (name[0] == '\0' || owned_index_in(owned, name) >= 0) {
        return;
    }
    if (owned->count >= MAX_OWNED) {
        die("too many owned variables in one function");
    }
    strncpy(owned->name[owned->count], name, NAME_MAX_LEN - 1);
    owned->name[owned->count][NAME_MAX_LEN - 1] = '\0';
    owned->type[owned->count] = type;
    owned->count++;
}

static void owned_add(const char *name, struct Type type)
{
    owned_add_to(&g_owned, name, type);
}

static void finalized_local_add(const char *name, struct Type type)
{
    owned_add_to(&g_finalized_locals, name, type);
}

static int malloc_func_index(const char *name)
{
    int i;
    for (i = 0; i < g_malloc_funcs.count; i++) {
        if (strcmp(g_malloc_funcs.name[i], name) == 0) {
            return i;
        }
    }
    return -1;
}

static void owned_func_add_type(const char *name, struct Type ret)
{
    int index = malloc_func_index(name);
    if (name[0] == '\0') {
        return;
    }
    if (index >= 0) {
        g_malloc_funcs.ret[index] = ret;
        return;
    }
    if (g_malloc_funcs.count >= MAX_FUNCS) {
        die("too many malloc attributed functions");
    }
    strncpy(g_malloc_funcs.name[g_malloc_funcs.count], name, NAME_MAX_LEN - 1);
    g_malloc_funcs.name[g_malloc_funcs.count][NAME_MAX_LEN - 1] = '\0';
    g_malloc_funcs.ret[g_malloc_funcs.count] = ret;
    g_malloc_funcs.count++;
}

static int text_has_word(const char *s, const char *word)
{
    size_t n = strlen(word);
    const char *p = s;
    while ((p = strstr(p, word)) != NULL) {
        if ((p == s || !is_ident((unsigned char)p[-1])) && !is_ident((unsigned char)p[n])) {
            return 1;
        }
        p += n;
    }
    return 0;
}

static void register_owned_function_signature(const char *s)
{
    char name[NAME_MAX_LEN];
    struct Type ret;

    if (!parse_function_signature(s, name, &ret)) {
        return;
    }
    if (ret.owned) {
        if (ret.ptr <= 0) {
            ret = type_make(TY_VOID, 1, NULL);
        }
        ret.owned = 1;
        owned_func_add_type(name, ret);
    }
}

static struct Text *strip_attributes(struct Text *in)
{
    struct Text *out = text_new();
    size_t i = 0;
    out->ast = in->ast;
    while (i < in->len) {
        if (strncmp(in->text + i, "__attribute__", 13) == 0) {
            size_t j = i + 13;
            int depth = 0;
            while (isspace((unsigned char)in->text[j])) {
                j++;
            }
            if (in->text[j] == '(') {
                do {
                    if (in->text[j] == '(') {
                        depth++;
                    } else if (in->text[j] == ')') {
                        depth--;
                    }
                    j++;
                } while (in->text[j] != '\0' && depth > 0);
                i = j;
                continue;
            }
        }
        text_add_ch(out, in->text[i]);
        i++;
    }
    text_free(in);
    return out;
}

static int find_assignment(const char *s)
{
    size_t i;
    int depth = 0;
    for (i = 0; s[i] != '\0'; i++) {
        char c = s[i];
        if (c == '(' || c == '[') {
            depth++;
        } else if (c == ')' || c == ']') {
            if (depth > 0) {
                depth--;
            }
        } else if (c == '=' && depth == 0) {
            if (s[i + 1] == '=' || (i > 0 && (s[i - 1] == '!' || s[i - 1] == '<' || s[i - 1] == '>'))) {
                continue;
            }
            return (int)i;
        }
    }
    return -1;
}

static int rhs_has_malloc_call(const char *rhs, char *func_name)
{
    size_t i;
    int f;
    for (i = 0; rhs[i] != '\0'; i++) {
        if (!is_ident_start((unsigned char)rhs[i])) {
            continue;
        }
        for (f = 0; f < g_malloc_funcs.count; f++) {
            size_t n = strlen(g_malloc_funcs.name[f]);
            size_t j;
            if (strncmp(rhs + i, g_malloc_funcs.name[f], n) != 0) {
                continue;
            }
            if ((i > 0 && is_ident((unsigned char)rhs[i - 1])) || is_ident((unsigned char)rhs[i + n])) {
                continue;
            }
            j = i + n;
            while (isspace((unsigned char)rhs[j])) {
                j++;
            }
            if (rhs[j] == '(') {
                strcpy(func_name, g_malloc_funcs.name[f]);
                return 1;
            }
        }
    }
    func_name[0] = '\0';
    return 0;
}

static int parse_new_expr(const char *rhs, const char **new_start, const char **new_end,
                          struct Type *type, struct Text *sizeof_type)
{
    const char *p = skip_ws(rhs);
    const char *type_start;
    const char *base_end;
    const char *end;
    struct Type base;
    int ptr = 0;

    if (!starts_word(p, "new")) {
        return 0;
    }
    type_start = skip_ws(p + 3);
    if (!parse_base_type_prefix(type_start, &base_end, &base)) {
        return 0;
    }
    end = base_end;
    while (isspace((unsigned char)*end)) {
        end++;
    }
    while (*end == '*') {
        ptr++;
        end++;
        while (isspace((unsigned char)*end)) {
            end++;
        }
    }
    *type = base;
    type->ptr += ptr + 1;
    type->owned = 1;

    while (end > type_start && isspace((unsigned char)end[-1])) {
        end--;
    }
    text_add_n(sizeof_type, type_start, (size_t)(end - type_start));

    if (new_start != NULL) {
        *new_start = p;
    }
    if (new_end != NULL) {
        *new_end = end;
    }
    return 1;
}

static int rhs_has_new_expr(const char *rhs, struct Type *type)
{
    struct Text *sizeof_type = text_new();
    int ok = parse_new_expr(rhs, NULL, NULL, type, sizeof_type);

    text_free(sizeof_type);
    return ok;
}

static const char *scan_clone_source_end(const char *s)
{
    const char *p = s;
    int paren = 0;
    int bracket = 0;
    int brace = 0;

    while (*p != '\0') {
        if (*p == '"') {
            p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p == '"') {
                    p++;
                    break;
                }
                p++;
            }
            continue;
        }
        if (*p == '\'') {
            p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p == '\'') {
                    p++;
                    break;
                }
                p++;
            }
            continue;
        }
        if (*p == '(') {
            paren++;
        } else if (*p == ')') {
            if (paren == 0 && bracket == 0 && brace == 0) {
                break;
            }
            if (paren > 0) {
                paren--;
            }
        } else if (*p == '[') {
            bracket++;
        } else if (*p == ']') {
            if (paren == 0 && bracket == 0 && brace == 0) {
                break;
            }
            if (bracket > 0) {
                bracket--;
            }
        } else if (*p == '{') {
            brace++;
        } else if (*p == '}') {
            if (paren == 0 && bracket == 0 && brace == 0) {
                break;
            }
            if (brace > 0) {
                brace--;
            }
        } else if (paren == 0 && bracket == 0 && brace == 0 && (*p == ';' || *p == ',')) {
            break;
        }
        p++;
    }
    while (p > s && isspace((unsigned char)p[-1])) {
        p--;
    }
    return p;
}

static struct Text *build_clone_expression(const char *source, struct Type source_type)
{
    struct Text *out = text_new();
    char src_tmp[NAME_MAX_LEN];
    char dst_tmp[NAME_MAX_LEN];
    struct Type base = source_type;

    snprintf(src_tmp, sizeof(src_tmp), "__right_value_src%d", g_right_value_id++);
    if (source_type.ptr > 0) {
        snprintf(dst_tmp, sizeof(dst_tmp), "__right_value%d", g_right_value_id++);
        base.ptr--;
        text_add(out, "({ ");
        append_c_type(out, source_type);
        text_add(out, " ");
        text_add(out, src_tmp);
        text_add(out, " = ");
        text_add(out, source);
        text_add(out, "; ");
        append_c_type(out, source_type);
        text_add(out, " ");
        text_add(out, dst_tmp);
        text_add(out, " = NULL; ");
        text_add(out, "if (");
        text_add(out, src_tmp);
        text_add(out, " != NULL) { ");
        text_add(out, dst_tmp);
        if (base.kind == TY_STRUCT) {
            if (!type_has_clone(base)) {
                text_free(out);
                return NULL;
            }
            text_add(out, " = ");
            append_struct_clone_name(out, base.tag);
            text_add(out, "(");
            text_add(out, src_tmp);
            text_add(out, "); ");
        } else if (type_is_string(source_type)) {
            g_need_string_h = 1;
            text_add(out, " = calloc(strlen(");
            text_add(out, src_tmp);
            text_add(out, ") + 1, sizeof(char)); ");
            text_add(out, "strncpy(");
            text_add(out, dst_tmp);
            text_add(out, ", ");
            text_add(out, src_tmp);
            text_add(out, ", strlen(");
            text_add(out, src_tmp);
            text_add(out, ") + 1); ");
        } else {
            text_add(out, " = calloc(1, sizeof(");
            append_c_type(out, base);
            text_add(out, ")); ");
            text_add(out, "*");
            text_add(out, dst_tmp);
            text_add(out, " = ");
            text_add(out, "*");
            text_add(out, src_tmp);
            text_add(out, "; ");
        }
        text_add(out, "} ");
        text_add(out, dst_tmp);
        text_add(out, "; })");
    } else if (source_type.kind == TY_STRUCT) {
        if (!type_has_clone(source_type)) {
            text_free(out);
            return NULL;
        }
        text_add(out, "({ ");
        append_c_type(out, source_type);
        text_add(out, " ");
        text_add(out, src_tmp);
        text_add(out, " = ");
        text_add(out, source);
        text_add(out, "; ");
        append_struct_clone_name(out, source_type.tag);
        text_add(out, "(&");
        text_add(out, src_tmp);
        text_add(out, "); })");
    } else {
        text_free(out);
        return NULL;
    }
    return out;
}

static int parse_clone_expr(const char *rhs, const char **clone_start, const char **clone_end, struct Type *type, char *source_name)
{
    const char *p = skip_ws(rhs);
    const char *src;
    const char *end;
    struct Type source_type;
    char *tmp;

    if (!starts_word(p, "clone")) {
        return 0;
    }
    src = skip_ws(p + 5);
    end = scan_clone_source_end(src);
    if (end <= src) {
        return 0;
    }
    tmp = xstrndup(src, (size_t)(end - src));
    source_type = expr_type(tmp);
    free(tmp);
    if (source_type.kind == TY_UNKNOWN) {
        return 0;
    }
    if (source_type.ptr == 0 && source_type.kind != TY_STRUCT) {
        return 0;
    }
    if (source_type.kind == TY_STRUCT && !type_has_clone(source_type)) {
        return 0;
    }
    if (source_type.ptr > 0 && source_type.kind == TY_STRUCT) {
        struct Type base = source_type;
        base.ptr--;
        if (!type_has_clone(base)) {
            return 0;
        }
    }
    if (source_name != NULL) {
        source_name[0] = '\0';
    }
    if (type != NULL) {
        *type = source_type;
        if (source_type.kind == TY_STRUCT && source_type.ptr == 0) {
            type->ptr = 1;
            type->owned = 1;
        } else if (source_type.ptr > 0) {
            type->owned = 1;
            if (source_type.kind != TY_STRUCT) {
                type->owned = 1;
            }
        }
    }
    if (clone_start != NULL) {
        *clone_start = p;
    }
    if (clone_end != NULL) {
        *clone_end = end;
    }
    return 1;
}

static int rhs_has_clone_expr(const char *rhs, struct Type *type)
{
    return parse_clone_expr(rhs, NULL, NULL, type, NULL);
}

static struct Text *rewrite_clone_expressions(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    while (*p != '\0') {
        const char *clone_start;
        const char *clone_end;
        struct Text *replacement = NULL;
        struct Type type;

        if ((p == in->text || !is_ident((unsigned char)p[-1])) &&
            parse_clone_expr(p, &clone_start, &clone_end, &type, NULL)) {
            char *source;
            struct Text *built;

            source = xstrndup(skip_ws(clone_start + 5), (size_t)(clone_end - skip_ws(clone_start + 5)));
            built = build_clone_expression(source, type);
            free(source);
            if (built != NULL) {
                text_add(out, built->text);
                text_free(built);
                p = clone_end;
                changed = 1;
                continue;
            }
        }
        text_free(replacement);
        text_add_ch(out, *p);
        p++;
    }

    if (!changed) {
        text_free(out);
        return in;
    }
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    text_free(in);
    return out;
}

static struct Text *rewrite_new_expressions(struct Text *in)
{
    const char *new_start;
    const char *new_end;
    const char *p;
    struct Type type;
    struct Text *sizeof_type = text_new();
    struct Text *out;

    new_start = NULL;
    new_end = NULL;
    for (p = in->text; *p != '\0'; p++) {
        if ((p == in->text || !is_ident((unsigned char)p[-1])) && starts_word(p, "new") &&
            parse_new_expr(p, &new_start, &new_end, &type, sizeof_type)) {
            break;
        }
    }
    if (new_start == NULL) {
        text_free(sizeof_type);
        return in;
    }

    out = text_new();
    text_add_n(out, in->text, (size_t)(new_start - in->text));
    text_add(out, "calloc(1, sizeof(");
    text_add(out, sizeof_type->text);
    text_add(out, "))");
    text_add(out, new_end);
    out->tail_return = in->tail_return;
    out->ast = in->ast;

    text_free(sizeof_type);
    text_free(in);
    return out;
}

static const char *find_s_string_literal(const char *rhs)
{
    const char *p = skip_ws(rhs);
    if (*p != 's') {
        return NULL;
    }
    if (p > rhs && is_ident((unsigned char)p[-1])) {
        return NULL;
    }
    p = skip_ws(p + 1);
    if (*p != '"') {
        return NULL;
    }
    return p;
}

static int rhs_has_s_string(const char *rhs)
{
    return find_s_string_literal(rhs) != NULL;
}

static int find_next_s_string(const char *from, const char **s_start, const char **quote_start, const char **after)
{
    const char *p = from;
    int in_str = 0;
    int in_chr = 0;

    while (*p != '\0') {
        if (in_str) {
            if (*p == '\\' && p[1] != '\0') {
                p += 2;
                continue;
            }
            if (*p == '"') {
                in_str = 0;
            }
            p++;
            continue;
        }
        if (in_chr) {
            if (*p == '\\' && p[1] != '\0') {
                p += 2;
                continue;
            }
            if (*p == '\'') {
                in_chr = 0;
            }
            p++;
            continue;
        }
        if (*p == '"') {
            in_str = 1;
            p++;
            continue;
        }
        if (*p == '\'') {
            in_chr = 1;
            p++;
            continue;
        }
        if (*p == 's' && (p == from || !is_ident((unsigned char)p[-1]))) {
            const char *q = skip_ws(p + 1);
            if (*q == '"') {
                const char *e = q + 1;
                while (*e != '\0') {
                    if (*e == '\\' && e[1] != '\0') {
                        e += 2;
                        continue;
                    }
                    if (*e == '"') {
                        *s_start = p;
                        *quote_start = q;
                        *after = e + 1;
                        return 1;
                    }
                    e++;
                }
            }
        }
        p++;
    }
    return 0;
}

static int text_has_s_string(const char *text)
{
    const char *s_start;
    const char *quote_start;
    const char *after;
    return find_next_s_string(text, &s_start, &quote_start, &after);
}

static void node_add_escaped_format_char(struct Text *fmt, char c)
{
    if (c == '%') {
        text_add(fmt, "%%");
    } else {
        text_add_ch(fmt, c);
    }
}

static int build_s_format(const char *quote, struct Text *fmt, struct Text *args)
{
    const char *p = quote + 1;
    int depth;

    text_add_ch(fmt, '"');
    while (*p != '\0') {
        if (*p == '"') {
            text_add_ch(fmt, '"');
            return 1;
        }
        if (*p == '\\' && p[1] == '{') {
            const char *expr_start;
            const char *expr_end;
            p += 2;
            expr_start = p;
            depth = 1;
            while (*p != '\0' && depth > 0) {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p == '{') {
                    depth++;
                } else if (*p == '}') {
                    depth--;
                    if (depth == 0) {
                        break;
                    }
                }
                p++;
            }
            if (*p != '}') {
                return 0;
            }
            expr_end = p;
            text_add(fmt, "%d");
            text_add(args, ", ");
            text_add_n(args, expr_start, (size_t)(expr_end - expr_start));
            p++;
            continue;
        }
        if (*p == '\\' && p[1] != '\0') {
            text_add_ch(fmt, *p);
            p++;
            text_add_ch(fmt, *p);
            p++;
            continue;
        }
        node_add_escaped_format_char(fmt, *p);
        p++;
    }
    return 0;
}

static struct Text *build_asprintf_statement(const char *lhs_name, const char *rhs, const char *original)
{
    const char *quote = find_s_string_literal(rhs);
    struct Text *stmt = text_new();
    struct Text *fmt = text_new();
    struct Text *args = text_new();
    struct Text *indent = text_new();

    if (quote == NULL || !build_s_format(quote, fmt, args)) {
        fprintf(stderr, "cauto: invalid s string literal\n");
        exit(1);
    }

    append_indent_from(original, indent);
    text_add(stmt, indent->text);
    text_add(stmt, "asprintf(&");
    text_add(stmt, lhs_name);
    text_add(stmt, ", ");
    text_add(stmt, fmt->text);
    text_add(stmt, args->text);
    text_add(stmt, ");");
    stmt->ast = ast_raw(ND_S_STRING, stmt->text);

    text_free(indent);
    text_free(fmt);
    text_free(args);
    return stmt;
}

static void append_asprintf_for_quote(struct Text *out, const char *name, const char *quote, const char *indent)
{
    struct Text *fmt = text_new();
    struct Text *args = text_new();

    if (!build_s_format(quote, fmt, args)) {
        fprintf(stderr, "cauto: invalid s string literal\n");
        exit(1);
    }
    text_add(out, indent);
    text_add(out, "asprintf(&");
    text_add(out, name);
    text_add(out, ", ");
    text_add(out, fmt->text);
    text_add(out, args->text);
    text_add(out, ");\n");

    text_free(fmt);
    text_free(args);
}

static struct Text *rewrite_s_string_temporaries(struct Text *stmt)
{
    const char *leading_end = skip_ws(stmt->text);
    const char *cursor = leading_end;
    const char *p;
    const char *last_nl = NULL;
    const char *s_start;
    const char *quote_start;
    const char *after;
    struct Text *prefix = text_new();
    struct Text *rewritten = text_new();
    struct Text *suffix = text_new();
    struct Text *indent = text_new();
    int count = 0;

    if (!text_has_s_string(stmt->text)) {
        text_free(prefix);
        text_free(rewritten);
        text_free(suffix);
        text_free(indent);
        return stmt;
    }

    append_indent_from(stmt->text, indent);
    for (p = stmt->text; p < leading_end; p++) {
        if (*p == '\n') {
            last_nl = p;
        }
    }
    if (last_nl != NULL) {
        text_add_n(prefix, stmt->text, (size_t)(last_nl + 1 - stmt->text));
    }
    text_add(rewritten, indent->text);
    while (find_next_s_string(cursor, &s_start, &quote_start, &after)) {
        char tmp[NAME_MAX_LEN];
        snprintf(tmp, sizeof(tmp), "__right_value%d", g_right_value_id++);
        text_add_n(rewritten, cursor, (size_t)(s_start - cursor));
        text_add(rewritten, tmp);

        text_add(prefix, indent->text);
        text_add(prefix, "char* ");
        text_add(prefix, tmp);
        text_add(prefix, " = NULL;\n");
        append_asprintf_for_quote(prefix, tmp, quote_start, indent->text);

        text_add(suffix, "\n");
        text_add(suffix, indent->text);
        text_add(suffix, "free(");
        text_add(suffix, tmp);
        text_add(suffix, ");");

        cursor = after;
        count++;
    }
    text_add(rewritten, cursor);
    if (count > 0) {
        text_add(prefix, rewritten->text);
        text_add(prefix, suffix->text);
        prefix->ast = ast_raw(ND_S_STRING, prefix->text);
        text_free(stmt);
        stmt = prefix;
    } else {
        text_free(prefix);
    }
    text_free(rewritten);
    text_free(suffix);
    text_free(indent);
    return stmt;
}

static const char *find_condition_keyword(const char *s)
{
    const char *p = s;
    const char *found = NULL;
    int in_str = 0;
    int in_chr = 0;

    while (*p != '\0') {
        if (in_str) {
            if (*p == '\\' && p[1] != '\0') {
                p += 2;
                continue;
            }
            if (*p == '"') {
                in_str = 0;
            }
            p++;
            continue;
        }
        if (in_chr) {
            if (*p == '\\' && p[1] != '\0') {
                p += 2;
                continue;
            }
            if (*p == '\'') {
                in_chr = 0;
            }
            p++;
            continue;
        }
        if (*p == '"') {
            in_str = 1;
            p++;
            continue;
        }
        if (*p == '\'') {
            in_chr = 1;
            p++;
            continue;
        }
        if ((p == s || !is_ident((unsigned char)p[-1])) &&
            ((strncmp(p, "if", 2) == 0 && !is_ident((unsigned char)p[2])) ||
             (strncmp(p, "while", 5) == 0 && !is_ident((unsigned char)p[5])))) {
            found = p;
        }
        p++;
    }
    return found;
}

static const char *matching_paren(const char *open)
{
    const char *p = open;
    int depth = 0;
    int in_str = 0;
    int in_chr = 0;

    while (*p != '\0') {
        if (in_str) {
            if (*p == '\\' && p[1] != '\0') {
                p += 2;
                continue;
            }
            if (*p == '"') {
                in_str = 0;
            }
            p++;
            continue;
        }
        if (in_chr) {
            if (*p == '\\' && p[1] != '\0') {
                p += 2;
                continue;
            }
            if (*p == '\'') {
                in_chr = 0;
            }
            p++;
            continue;
        }
        if (*p == '"') {
            in_str = 1;
        } else if (*p == '\'') {
            in_chr = 1;
        } else if (*p == '(') {
            depth++;
        } else if (*p == ')') {
            depth--;
            if (depth == 0) {
                return p;
            }
        }
        p++;
    }
    return NULL;
}

static const char *scan_string_end(const char *quote)
{
    const char *p = quote + 1;

    while (*p != '\0') {
        if (*p == '\\' && p[1] != '\0') {
            p += 2;
            continue;
        }
        if (*p == '"') {
            return p + 1;
        }
        p++;
    }
    return NULL;
}

static int try_rewrite_string_method(const char *s, const char **end, struct Text *replacement)
{
    const char *receiver_end;
    const char *dot;
    const char *method_start;
    const char *method_end;
    const char *open;
    const char *close;
    char method[NAME_MAX_LEN];

    if (*s != '"') {
        return 0;
    }
    receiver_end = scan_string_end(s);
    if (receiver_end == NULL) {
        return 0;
    }
    dot = skip_ws(receiver_end);
    if (*dot != '.') {
        return 0;
    }
    method_start = skip_ws(dot + 1);
    if (!is_ident_start((unsigned char)*method_start)) {
        return 0;
    }
    method_end = read_name(method_start, method);
    open = skip_ws(method_end);
    if (*open != '(') {
        return 0;
    }
    close = matching_paren(open);
    if (close == NULL) {
        return 0;
    }

    text_add(replacement, method);
    text_add_ch(replacement, '(');
    text_add_n(replacement, s, (size_t)(receiver_end - s));
    if (close > open + 1) {
        text_add(replacement, ", ");
        text_add_n(replacement, open + 1, (size_t)(close - open - 1));
    }
    text_add_ch(replacement, ')');
    *end = close + 1;
    return 1;
}

static int try_rewrite_struct_method(const char *s, const char **end, struct Text *replacement)
{
    const char *name_end;
    const char *dot;
    const char *method_start;
    const char *method_end;
    const char *open;
    const char *close;
    char obj[NAME_MAX_LEN];
    char method[NAME_MAX_LEN];
    struct Symbol *sym;

    if (!is_ident_start((unsigned char)*s)) {
        return 0;
    }
    name_end = read_name(s, obj);
    sym = symbol_find(obj);
    if (sym == NULL || sym->type.kind != TY_STRUCT) {
        return 0;
    }
    dot = skip_ws(name_end);
    if (*dot != '.') {
        return 0;
    }
    method_start = skip_ws(dot + 1);
    if (!is_ident_start((unsigned char)*method_start)) {
        return 0;
    }
    method_end = read_name(method_start, method);
    open = skip_ws(method_end);
    if (*open != '(') {
        return 0;
    }
    close = matching_paren(open);
    if (close == NULL) {
        return 0;
    }

    text_add(replacement, sym->type.tag);
    text_add_ch(replacement, '_');
    text_add(replacement, method);
    text_add_ch(replacement, '(');
    if (sym->type.ptr > 0) {
        text_add(replacement, obj);
    } else {
        text_add_ch(replacement, '&');
        text_add(replacement, obj);
    }
    if (close > open + 1) {
        text_add(replacement, ", ");
        text_add_n(replacement, open + 1, (size_t)(close - open - 1));
    }
    text_add_ch(replacement, ')');
    *end = close + 1;
    return 1;
}

static struct Text *rewrite_method_calls(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    while (*p != '\0') {
        const char *end = NULL;
        struct Text *replacement = text_new();

        if (try_rewrite_string_method(p, &end, replacement) ||
            try_rewrite_struct_method(p, &end, replacement)) {
            text_add(out, replacement->text);
            p = end;
            changed = 1;
            text_free(replacement);
            continue;
        }
        text_free(replacement);
        text_add_ch(out, *p);
        p++;
    }

    if (!changed) {
        text_free(out);
        return in;
    }
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    text_free(in);
    return out;
}

static struct Text *build_condition_expr(const char *expr, size_t len)
{
    const char *cursor;
    const char *s_start;
    const char *quote_start;
    const char *after;
    const char *end = expr + len;
    struct Text *prefix = text_new();
    struct Text *rewritten = text_new();
    struct Text *suffix = text_new();
    struct Text *out = text_new();
    char cond_name[NAME_MAX_LEN];
    int count = 0;

    cursor = expr;
    while (cursor < end && find_next_s_string(cursor, &s_start, &quote_start, &after) && s_start < end) {
        char tmp[NAME_MAX_LEN];
        snprintf(tmp, sizeof(tmp), "__right_value%d", g_right_value_id++);
        text_add_n(rewritten, cursor, (size_t)(s_start - cursor));
        text_add(rewritten, tmp);
        text_add(prefix, "char* ");
        text_add(prefix, tmp);
        text_add(prefix, " = NULL; ");
        append_asprintf_for_quote(prefix, tmp, quote_start, "");
        if (prefix->len > 0 && prefix->text[prefix->len - 1] == '\n') {
            prefix->text[--prefix->len] = '\0';
            text_add_ch(prefix, ' ');
        }
        text_add(suffix, "free(");
        text_add(suffix, tmp);
        text_add(suffix, "); ");
        cursor = after;
        count++;
    }
    text_add_n(rewritten, cursor, (size_t)(end - cursor));
    if (count == 0) {
        text_free(prefix);
        text_free(suffix);
        text_add_n(out, expr, len);
        text_free(rewritten);
        return out;
    }

    snprintf(cond_name, sizeof(cond_name), "__right_value_cond%d", g_right_value_id++);
    text_add(out, "({ ");
    text_add(out, prefix->text);
    text_add(out, "int ");
    text_add(out, cond_name);
    text_add(out, " = ");
    text_add(out, rewritten->text);
    text_add(out, "; ");
    text_add(out, suffix->text);
    text_add(out, cond_name);
    text_add(out, "; })");

    text_free(prefix);
    text_free(rewritten);
    text_free(suffix);
    return out;
}

static struct Text *rewrite_control_condition(struct Text *head)
{
    const char *kw;
    const char *open;
    const char *close;
    struct Text *cond;
    struct Text *out;

    if (!text_has_s_string(head->text)) {
        return head;
    }
    kw = find_condition_keyword(head->text);
    if (kw == NULL) {
        return head;
    }
    open = strchr(kw, '(');
    if (open == NULL) {
        return head;
    }
    close = matching_paren(open);
    if (close == NULL) {
        return head;
    }
    cond = build_condition_expr(open + 1, (size_t)(close - open - 1));
    out = text_new();
    text_add_n(out, head->text, (size_t)(open + 1 - head->text));
    text_add(out, cond->text);
    text_add(out, close);
    out->ast = head->ast;
    text_free(cond);
    text_free(head);
    return out;
}

static struct Text *process_control_head(struct Text *head)
{
    enum NodeKind kind = ND_RAW;
    const char *p = skip_ws(head->text);

    if (starts_word(p, "if") || starts_word(p, "else")) {
        kind = ND_IF;
    } else if (starts_word(p, "while")) {
        kind = ND_WHILE;
    } else if (starts_word(p, "do")) {
        kind = ND_DO;
    }
    check_owned_pointer_arithmetic(head->text);
    head = rewrite_method_calls(head);
    head = rewrite_control_condition(head);
    head->ast = ast_raw(kind, head->text);
    return head;
}

static struct Text *build_decl_without_initializer(const char *stmt, int eq)
{
    const char *end = stmt + eq;
    struct Text *out = text_new();

    while (end > stmt && isspace((unsigned char)end[-1])) {
        end--;
    }
    text_add_n(out, stmt, (size_t)(end - stmt));
    text_add_ch(out, ';');
    out = remove_percent(strip_attributes(out));
    return out;
}

static int lhs_is_plain_name(const char *stmt, int eq, const char *name)
{
    const char *p = skip_ws(stmt);
    const char *end = stmt + eq;
    size_t n = strlen(name);

    while (end > stmt && isspace((unsigned char)end[-1])) {
        end--;
    }
    return (size_t)(end - p) == n && strncmp(p, name, n) == 0;
}

static int extract_owned_decl_name(const char *s, char *name)
{
    const char *p = strchr(s, '%');
    name[0] = '\0';
    if (p == NULL) {
        return 0;
    }
    p++;
    while (isspace((unsigned char)*p)) {
        p++;
    }
    if (!is_ident_start((unsigned char)*p)) {
        return 0;
    }
    {
        const char *start = p;
        while (is_ident((unsigned char)*p)) {
            p++;
        }
        if ((size_t)(p - start) >= NAME_MAX_LEN) {
            return 0;
        }
        memcpy(name, start, (size_t)(p - start));
        name[p - start] = '\0';
    }
    return 1;
}

static struct Text *remove_percent(struct Text *in)
{
    struct Text *out = text_new();
    size_t i;
    out->ast = in->ast;
    for (i = 0; i < in->len; i++) {
        if (in->text[i] != '%') {
            text_add_ch(out, in->text[i]);
        }
    }
    text_free(in);
    return out;
}

static struct Text *add_zero_initializer(struct Text *in)
{
    struct Text *out = text_new();
    const char *semi = in->text + in->len;

    while (semi > in->text && isspace((unsigned char)semi[-1])) {
        semi--;
    }
    if (semi > in->text && semi[-1] == ';') {
        semi--;
        while (semi > in->text && isspace((unsigned char)semi[-1])) {
            semi--;
        }
        text_add_n(out, in->text, (size_t)(semi - in->text));
        text_add(out, " = {0}");
        text_add(out, semi);
    } else {
        text_add(out, in->text);
    }
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    text_free(in);
    return out;
}

static void append_struct_finalizer_name(struct Text *out, const char *tag)
{
    text_add(out, tag);
    text_add(out, "_finalize");
}

static void append_struct_clone_name(struct Text *out, const char *tag)
{
    text_add(out, tag);
    text_add(out, "_clone");
}

static void append_finalize_for_type(struct Text *out, const char *indent, const char *expr, struct Type type)
{
    if (!type_has_finalizer(type)) {
        return;
    }
    text_add(out, indent);
    append_struct_finalizer_name(out, type.tag);
    text_add_ch(out, '(');
    if (type.ptr > 0) {
        text_add(out, expr);
    } else {
        text_add_ch(out, '&');
        text_add(out, expr);
    }
    text_add(out, ");\n");
}

static void append_release_pointer(struct Text *out, const char *indent, const char *expr, struct Type type)
{
    struct Text *inner = text_new();

    text_add(out, indent);
    text_add(out, "if (");
    text_add(out, expr);
    text_add(out, " != NULL) {\n");
    text_add(inner, indent);
    text_add(inner, "    ");
    append_finalize_for_type(out, inner->text, expr, type);
    text_add(out, inner->text);
    text_add(out, "free(");
    text_add(out, expr);
    text_add(out, ");\n");
    text_add(out, indent);
    text_add(out, "}\n");
    text_free(inner);
}

static void append_struct_finalizer_definition(struct Text *out, struct StructFinalizer *fin)
{
    int i;

    if (fin == NULL || fin->count == 0) {
        return;
    }
    text_add(out, "\n\nstatic void ");
    append_struct_finalizer_name(out, fin->tag);
    text_add(out, "(struct ");
    text_add(out, fin->tag);
    text_add(out, "* self)\n{\n");
    text_add(out, "    if (self == NULL) {\n");
    text_add(out, "        return;\n");
    text_add(out, "    }\n");
    for (i = 0; i < fin->count; i++) {
        struct Type type = fin->fields[i].type;
        struct Text *expr = text_new();

        text_add(expr, "self->");
        text_add(expr, fin->fields[i].name);
        if (type.ptr > 0 && type.owned) {
            append_release_pointer(out, "    ", expr->text, type);
            text_add_ch(out, '\n');
        } else {
            append_finalize_for_type(out, "    ", expr->text, type);
        }
        text_free(expr);
    }
    text_add(out, "}\n");
}

static void append_struct_clone_field(struct Text *out, struct Type type, const char *field_name, int index)
{
    struct Text *expr = text_new();

    text_add(expr, "self->");
    text_add(expr, field_name);
    if (type.kind == TY_STRUCT && type.ptr == 0) {
        char tmp[NAME_MAX_LEN];

        snprintf(tmp, sizeof(tmp), "__clone_field%d", index);
        text_add(out, "    {\n");
        text_add(out, "        struct ");
        text_add(out, type.tag);
        text_add(out, "* ");
        text_add(out, tmp);
        text_add(out, " = ");
        append_struct_clone_name(out, type.tag);
        text_add(out, "(&");
        text_add(out, expr->text);
        text_add(out, ");\n");
        text_add(out, "        if (");
        text_add(out, tmp);
        text_add(out, " != NULL) {\n");
        text_add(out, "            copy->");
        text_add(out, field_name);
        text_add(out, " = *");
        text_add(out, tmp);
        text_add(out, ";\n");
        text_add(out, "            free(");
        text_add(out, tmp);
        text_add(out, ");\n");
        text_add(out, "        }\n");
        text_add(out, "    }\n");
    } else if (type.ptr > 0 && type.owned) {
        struct Type base = type;

        base.ptr--;
        if (type_is_string(type)) {
            g_need_string_h = 1;
            text_add(out, "    if (");
            text_add(out, expr->text);
            text_add(out, " != NULL) {\n");
            text_add(out, "        copy->");
            text_add(out, field_name);
            text_add(out, " = calloc(strlen(");
            text_add(out, expr->text);
            text_add(out, ") + 1, sizeof(char));\n");
            text_add(out, "        strncpy(copy->");
            text_add(out, field_name);
            text_add(out, ", ");
            text_add(out, expr->text);
            text_add(out, ", strlen(");
            text_add(out, expr->text);
            text_add(out, ") + 1);\n");
            text_add(out, "    }\n");
            text_free(expr);
            return;
        }
        text_add(out, "    if (");
        text_add(out, expr->text);
        text_add(out, " != NULL) {\n");
        text_add(out, "        copy->");
        text_add(out, field_name);
        text_add(out, " = ");
        if (base.kind == TY_STRUCT) {
            append_struct_clone_name(out, base.tag);
            text_add(out, "(");
            text_add(out, expr->text);
            text_add(out, ");\n");
        } else {
            text_add(out, "calloc(1, sizeof(");
            append_c_type(out, base);
            text_add(out, "));\n");
            text_add(out, "        ");
            text_add(out, "*copy->");
            text_add(out, field_name);
            text_add(out, " = ");
            text_add(out, "*");
            text_add(out, expr->text);
            text_add(out, ";\n");
        }
        text_add(out, "    }\n");
    } else if (type.kind == TY_STRUCT && type.ptr > 0) {
        text_add(out, "    copy->");
        text_add(out, field_name);
        text_add(out, " = ");
        text_add(out, expr->text);
        text_add(out, ";\n");
    } else {
        text_add(out, "    copy->");
        text_add(out, field_name);
        text_add(out, " = ");
        text_add(out, expr->text);
        text_add(out, ";\n");
    }
    text_free(expr);
}

static void append_struct_clone_definition(struct Text *out, struct StructFinalizer *clone)
{
    int i;

    if (clone == NULL) {
        return;
    }
    text_add(out, "\n\nstatic __attribute__((unused)) struct ");
    text_add(out, clone->tag);
    text_add(out, "* ");
    append_struct_clone_name(out, clone->tag);
    text_add(out, "(struct ");
    text_add(out, clone->tag);
    text_add(out, "* self)\n{\n");
    text_add(out, "    struct ");
    text_add(out, clone->tag);
    text_add(out, "* copy = calloc(1, sizeof(struct ");
    text_add(out, clone->tag);
    text_add(out, "));\n");
    text_add(out, "    if (copy == NULL || self == NULL) {\n");
    text_add(out, "        return copy;\n");
    text_add(out, "    }\n");
    for (i = 0; i < clone->count; i++) {
        append_struct_clone_field(out, clone->fields[i].type, clone->fields[i].name, i);
    }
    text_add(out, "    return copy;\n");
    text_add(out, "}\n");
}

static void append_free_after_statement(struct Text *stmt, const char *original, const char *name, struct Type type)
{
    struct Text *indent = text_new();
    append_indent_from(original, indent);
    text_add_ch(stmt, '\n');
    append_release_pointer(stmt, indent->text, name, type);
    text_free(indent);
}

static struct Text *prepend_owned_assignment_release(struct Text *stmt, const char *original, const char *lhs_expr, struct Type type)
{
    struct Text *out = text_new();
    struct Text *indent = text_new();
    char tmp[NAME_MAX_LEN];

    snprintf(tmp, sizeof(tmp), "__owned_old%d", g_right_value_id++);
    append_indent_from(original, indent);
    text_add(out, indent->text);
    text_add(out, "void* ");
    text_add(out, tmp);
    text_add(out, " = ");
    text_add(out, lhs_expr);
    text_add(out, ";\n");
    text_add(out, stmt->text);
    text_add_ch(out, '\n');
    append_release_pointer(out, indent->text, tmp, type);
    text_add_ch(out, '\n');
    out->tail_return = stmt->tail_return;
    out->ast = stmt->ast;
    text_free(indent);
    text_free(stmt);
    return out;
}

static void append_zero_clear_after_decl(struct Text *stmt, const char *original, const char *name)
{
    struct Text *indent = text_new();

    g_need_string_h = 1;
    append_indent_from(original, indent);
    text_add_ch(stmt, '\n');
    text_add(stmt, indent->text);
    text_add(stmt, "memset(&");
    text_add(stmt, name);
    text_add(stmt, ", 0, sizeof(");
    text_add(stmt, name);
    text_add(stmt, "));");
    text_add_ch(stmt, '\n');
    text_free(indent);
}

static int prev_nonspace_is_plus_or_minus(const char *start, const char *p)
{
    while (p > start && isspace((unsigned char)p[-1])) {
        p--;
    }
    if (p > start && (p[-1] == '+' || p[-1] == '-')) {
        if (p[-1] == '-' && p > start + 1 && p[-2] == '>') {
            return 0;
        }
        return 1;
    }
    return 0;
}

static int next_is_owned_arith(const char *p)
{
    p = skip_ws(p);
    if (p[0] == '+' || p[0] == '-') {
        if (p[0] == '-' && p[1] == '>') {
            return 0;
        }
        return 1;
    }
    return 0;
}

static void check_owned_pointer_arithmetic(const char *stmt)
{
    int i;
    for (i = 0; i < g_locals.count; i++) {
        const char *p = stmt;
        const char *name = g_locals.sym[i].name;
        size_t n = strlen(name);
        if (!g_locals.sym[i].type.owned || g_locals.sym[i].type.ptr <= 0) {
            continue;
        }
        while ((p = strstr(p, name)) != NULL) {
            if ((p == stmt || !is_ident((unsigned char)p[-1])) && !is_ident((unsigned char)p[n])) {
                if (prev_nonspace_is_plus_or_minus(stmt, p) || next_is_owned_arith(p + n)) {
                    fprintf(stderr, "cauto: type error: pointer arithmetic is forbidden for owned pointer '%s'\n", name);
                    exit(1);
                }
            }
            p += n;
        }
    }
}

static void append_indent_from(const char *s, struct Text *out)
{
    const char *p = s;
    const char *last_nl = NULL;
    while (isspace((unsigned char)*p)) {
        if (*p == '\n') {
            last_nl = p;
        }
        p++;
    }
    if (last_nl == NULL) {
        text_add(out, "    ");
        return;
    }
    text_add_n(out, last_nl + 1, (size_t)(p - last_nl - 1));
}

static void append_leading_newlines(const char *s, struct Text *out)
{
    const char *p = s;
    int saw_nl = 0;
    while (isspace((unsigned char)*p)) {
        if (*p == '\n') {
            text_add_ch(out, '\n');
            saw_nl = 1;
        }
        p++;
    }
    if (!saw_nl) {
        text_add_ch(out, '\n');
    }
}

static const char *skip_leading_space(const char *s)
{
    while (isspace((unsigned char)*s)) {
        s++;
    }
    return s;
}

static void emit_frees(struct Text *out, const char *indent)
{
    int i;
    for (i = g_finalized_locals.count - 1; i >= 0; i--) {
        append_finalize_for_type(out, indent, g_finalized_locals.name[i], g_finalized_locals.type[i]);
    }
    for (i = g_owned.count - 1; i >= 0; i--) {
        append_release_pointer(out, indent, g_owned.name[i], g_owned.type[i]);
        text_add_ch(out, '\n');
    }
}

static struct Text *process_external_decl(struct Text *decl, struct Text *semi)
{
    char func_name[NAME_MAX_LEN];
    struct DeclInfo info;
    struct Type ret;
    struct Text *all = text_join(decl, semi);
    int is_func_sig;

    register_tags_in_text(all->text);
    is_func_sig = parse_function_signature(all->text, func_name, &ret);
    register_owned_function_signature(all->text);
    if (is_string_typedef_decl(all->text)) {
        struct Text *out = text_new();
        g_need_string_typedef = 1;
        text_free(all);
        return out;
    }
    if (!is_func_sig && parse_decl(all->text, &info) && info.name[0] != '\0' && !info.is_function) {
        symbol_add_to(&g_globals, info.name, info.type);
    }
    all->ast = ast_raw(ND_DECL, all->text);
    return remove_percent(strip_attributes(all));
}

static struct Text *process_statement(struct Text *stmt, struct Text *semi)
{
    char owned_name[NAME_MAX_LEN];
    char func_name[NAME_MAX_LEN];
    char lhs_name[NAME_MAX_LEN];
    struct DeclInfo decl;
    struct Symbol *lhs;
    struct Type lhs_type;
    struct Type rhs_type;
    struct Type new_type;
    struct Text *all = text_join(stmt, semi);
    int eq = find_assignment(all->text);
    int post_free = 0;
    char post_free_name[NAME_MAX_LEN];
    struct Type post_free_type;
    int owned_assign = 0;
    struct Type owned_assign_type;
    char *owned_assign_lhs = NULL;

    post_free_name[0] = '\0';
    owned_name[0] = '\0';
    func_name[0] = '\0';
    lhs_name[0] = '\0';
    post_free_type = type_unknown();
    owned_assign_type = type_unknown();
    new_type = type_unknown();
    register_tags_in_text(all->text);
    if (!g_in_function) {
        if (g_in_aggregate_struct && g_current_struct_tag[0] != '\0' &&
            parse_decl(all->text, &decl) && decl.is_decl && decl.name[0] != '\0' &&
            decl.type.ptr >= 0) {
            struct_clone_add_field(g_current_struct_tag, decl.name, decl.type);
            if (decl.type.owned || type_has_finalizer(decl.type)) {
            struct_finalizer_add_field(g_current_struct_tag, decl.name, decl.type);
            }
        }
        all->tail_return = 0;
        all->ast = ast_raw(ND_RAW, all->text);
        return remove_percent(strip_attributes(all));
    }
    check_owned_pointer_arithmetic(all->text);

    if (parse_decl(all->text, &decl) && decl.is_decl && decl.name[0] != '\0' && !decl.is_function) {
        if (decl.has_init) {
            rhs_type = expr_type(decl.init);
            if (rhs_has_s_string(decl.init)) {
                struct Text *out;
                struct Text *call;
                if (decl.type.ptr <= 0 || decl.type.kind != TY_CHAR) {
                    fprintf(stderr, "cauto: type error: s string requires a char pointer declaration for '%s'\n", decl.name);
                    text_free(all);
                    exit(1);
                }
                if (decl.type.owned) {
                    owned_add(decl.name, decl.type);
                } else {
                    post_free = 1;
                    strcpy(post_free_name, decl.name);
                    post_free_type = decl.type;
                }
                check_assignment_type(decl.name, decl.type, rhs_type);
                symbol_add(decl.name, decl.type);
                out = build_decl_without_initializer(all->text, eq);
                call = build_asprintf_statement(decl.name, decl.init, all->text);
                text_add_ch(out, '\n');
                out = text_join(out, call);
                if (post_free) {
                    append_free_after_statement(out, all->text, post_free_name, post_free_type);
                }
                out->ast = ast_raw(ND_S_STRING, out->text);
                text_free(all);
                return out;
            } else if (rhs_has_clone_expr(decl.init, &new_type)) {
                rhs_type = new_type;
                if (new_type.ptr > 0) {
                    if (decl.type.ptr <= 0) {
                        fprintf(stderr, "cauto: type error: clone result requires a pointer %% declaration for '%s'\n", decl.name);
                        text_free(all);
                        exit(1);
                    }
                    if (decl.type.owned) {
                        owned_add(decl.name, decl.type);
                    } else {
                        post_free = 1;
                        strcpy(post_free_name, decl.name);
                        post_free_type = decl.type;
                    }
                }
            } else if (rhs_has_malloc_call(decl.init, func_name) || rhs_has_new_expr(decl.init, &new_type)) {
                if (decl.type.ptr <= 0) {
                    if (func_name[0] != '\0') {
                        fprintf(stderr, "cauto: type error: malloc result requires a pointer %% declaration for '%s'\n", decl.name);
                    } else {
                        fprintf(stderr, "cauto: type error: new result requires a pointer %% declaration for '%s'\n", decl.name);
                    }
                    text_free(all);
                    exit(1);
                }
                if (decl.type.owned) {
                    owned_add(decl.name, decl.type);
                } else {
                    post_free = 1;
                    strcpy(post_free_name, decl.name);
                    post_free_type = decl.type;
                }
            }
            check_assignment_type(decl.name, decl.type, rhs_type);
        }
        symbol_add(decl.name, decl.type);
        if (decl.type.ptr == 0 && type_has_finalizer(decl.type)) {
            finalized_local_add(decl.name, decl.type);
        }
        all->tail_return = 0;
        all->ast = ast_raw(ND_DECL, all->text);
        all = remove_percent(strip_attributes(all));
        all = rewrite_method_calls(all);
        all = rewrite_control_condition(all);
        all = rewrite_s_string_temporaries(all);
        all = rewrite_clone_expressions(all);
        all = rewrite_new_expressions(all);
        if (!decl.has_init) {
            all = add_zero_initializer(all);
            append_zero_clear_after_decl(all, all->text, decl.name);
        }
        if (post_free) {
            append_free_after_statement(all, all->text, post_free_name, post_free_type);
        }
        return all;
    }

    if (eq >= 0 && rhs_has_s_string(all->text + eq + 1)) {
        if (!extract_lhs_name(all->text, eq, lhs_name) || !lhs_is_plain_name(all->text, eq, lhs_name)) {
            fprintf(stderr, "cauto: type error: s string requires a plain char pointer lvalue\n");
            text_free(all);
            exit(1);
        }
        lhs = symbol_find(lhs_name);
        lhs_type = lhs_type_before_eq(all->text, eq, lhs_name);
        rhs_type = expr_type(all->text + eq + 1);
        if (lhs == NULL || lhs_type.ptr <= 0 || lhs_type.kind != TY_CHAR) {
            fprintf(stderr, "cauto: type error: s string requires a char pointer lvalue for '%s'\n", lhs_name);
            text_free(all);
            exit(1);
        }
        check_assignment_type(lhs_name, lhs_type, rhs_type);
        if (lhs != NULL && lhs->type.owned) {
            owned_add(lhs_name, lhs->type);
            owned_assign = 1;
            owned_assign_type = lhs->type;
            owned_assign_lhs = slice_lhs_expr(all->text, eq);
        } else if (lhs_type.owned) {
            owned_assign = 1;
            owned_assign_type = lhs_type;
            owned_assign_lhs = slice_lhs_expr(all->text, eq);
        } else {
            post_free = 1;
            strcpy(post_free_name, lhs_name);
            post_free_type = lhs_type;
        }
        all = build_asprintf_statement(lhs_name, all->text + eq + 1, all->text);
        if (post_free) {
            append_free_after_statement(all, all->text, post_free_name, post_free_type);
        }
        all->ast = ast_raw(ND_S_STRING, all->text);
        return all;
    } else if (eq >= 0 && rhs_has_clone_expr(all->text + eq + 1, &new_type)) {
        rhs_type = new_type;
        if (extract_owned_decl_name(all->text, owned_name)) {
            lhs = symbol_find(owned_name);
            if (lhs != NULL && lhs->type.ptr <= 0) {
                fprintf(stderr, "cauto: type error: clone result requires a pointer %% declaration for '%s'\n", owned_name);
                text_free(all);
                exit(1);
            }
            lhs_type = lhs != NULL ? lhs->type : type_unknown();
        } else if (extract_lhs_name(all->text, eq, lhs_name)) {
            lhs = symbol_find(lhs_name);
            lhs_type = lhs_type_before_eq(all->text, eq, lhs_name);
            if (new_type.ptr > 0 && (!type_is_known(lhs_type) || lhs_type.ptr <= 0)) {
                fprintf(stderr, "cauto: type error: clone result requires a pointer lvalue for '%s'\n", lhs_name);
                text_free(all);
                exit(1);
            }
            check_assignment_type(lhs_name, lhs_type, rhs_type);
            if (new_type.ptr > 0) {
                if (lhs != NULL && lhs->type.owned) {
                    strcpy(owned_name, lhs_name);
                    owned_assign = 1;
                    owned_assign_type = lhs->type;
                    owned_assign_lhs = slice_lhs_expr(all->text, eq);
                } else if (lhs_type.owned) {
                    owned_assign = 1;
                    owned_assign_type = lhs_type;
                    owned_assign_lhs = slice_lhs_expr(all->text, eq);
                } else {
                    post_free = 1;
                    strcpy(post_free_name, lhs_name);
                    post_free_type = lhs_type;
                    owned_name[0] = '\0';
                }
            }
        } else {
            fprintf(stderr, "cauto: result of clone must be assigned to a matching declaration\n");
            text_free(all);
            exit(1);
        }
        if (owned_name[0] != '\0') {
            owned_add(owned_name, lhs != NULL ? lhs->type : lhs_type);
        }
    } else if (eq >= 0 && (rhs_has_malloc_call(all->text + eq + 1, func_name) ||
                           rhs_has_new_expr(all->text + eq + 1, &new_type))) {
        if (extract_owned_decl_name(all->text, owned_name)) {
            lhs = symbol_find(owned_name);
            if (lhs != NULL && lhs->type.ptr <= 0) {
                fprintf(stderr, "cauto: type error: malloc result requires a pointer %% declaration for '%s'\n", owned_name);
                text_free(all);
                exit(1);
            }
            lhs_type = lhs != NULL ? lhs->type : type_unknown();
        } else if (extract_lhs_name(all->text, eq, lhs_name)) {
            lhs = symbol_find(lhs_name);
            lhs_type = lhs_type_before_eq(all->text, eq, lhs_name);
            rhs_type = expr_type(all->text + eq + 1);
            if (!type_is_known(lhs_type) || lhs_type.ptr <= 0) {
                fprintf(stderr, "cauto: type error: malloc result requires a pointer lvalue for '%s'\n", lhs_name);
                text_free(all);
                exit(1);
            }
            check_assignment_type(lhs_name, lhs_type, rhs_type);
            if (lhs != NULL && lhs->type.owned) {
                strcpy(owned_name, lhs_name);
                owned_assign = 1;
                owned_assign_type = lhs->type;
                owned_assign_lhs = slice_lhs_expr(all->text, eq);
            } else if (lhs_type.owned) {
                owned_assign = 1;
                owned_assign_type = lhs_type;
                owned_assign_lhs = slice_lhs_expr(all->text, eq);
            } else {
                post_free = 1;
                strcpy(post_free_name, lhs_name);
                post_free_type = lhs_type;
                owned_name[0] = '\0';
            }
        } else {
            if (func_name[0] != '\0') {
                fprintf(stderr, "cauto: result of owned function '%s' must be assigned to a %% pointer declaration\n", func_name);
            } else {
                fprintf(stderr, "cauto: result of new must be assigned to a %% pointer declaration\n");
            }
            text_free(all);
            exit(1);
        }
        if (owned_name[0] != '\0') {
            owned_add(owned_name, lhs != NULL ? lhs->type : lhs_type);
        }
    } else if (eq >= 0 && extract_lhs_name(all->text, eq, lhs_name)) {
        lhs = symbol_find(lhs_name);
        if (lhs != NULL) {
            lhs_type = lhs_type_before_eq(all->text, eq, lhs_name);
            rhs_type = expr_type(all->text + eq + 1);
            check_assignment_type(lhs_name, lhs_type, rhs_type);
        }
    }
    all->tail_return = 0;
    all->ast = ast_raw(eq >= 0 ? ND_ASSIGN : ND_EXPR_STMT, all->text);
    all = remove_percent(strip_attributes(all));
    all = rewrite_method_calls(all);
    all = rewrite_clone_expressions(all);
    all = rewrite_control_condition(all);
    all = rewrite_s_string_temporaries(all);
    all = rewrite_new_expressions(all);
    if (owned_assign) {
        all = prepend_owned_assignment_release(all, all->text, owned_assign_lhs, owned_assign_type);
        free(owned_assign_lhs);
        owned_assign_lhs = NULL;
    }
    if (post_free) {
        append_free_after_statement(all, all->text, post_free_name, post_free_type);
    }
    return all;
}

static int return_uses_owned(const char *s)
{
    int i;
    for (i = 0; i < g_owned.count; i++) {
        if (text_has_word(s, g_owned.name[i])) {
            return 1;
        }
    }
    return 0;
}

static struct Text *process_return(struct Text *ret, struct Text *expr, struct Text *semi)
{
    struct Text *all = text_join3(ret, expr, semi);
    all->ast = ast_raw(ND_RETURN, all->text);
    check_owned_pointer_arithmetic(all->text);
    all = rewrite_method_calls(all);
    if ((g_owned.count > 0 || g_finalized_locals.count > 0) && !return_uses_owned(all->text)) {
        struct Text *out = text_new();
        struct Text *indent = text_new();
        append_leading_newlines(all->text, out);
        append_indent_from(all->text, indent);
        emit_frees(out, indent->text);
        text_add(out, indent->text);
        text_add(out, skip_leading_space(all->text));
        out->tail_return = 1;
        out->ast = ast_raw(ND_RETURN, out->text);
        text_free(indent);
        text_free(all);
        return out;
    }
    all->tail_return = 1;
    return all;
}

static struct Text *finish_top_block(struct Text *head, struct Text *lb, struct Text *body, struct Text *rb)
{
    struct Text *out;
    struct Node *body_ast = body->ast;
    char name[NAME_MAX_LEN];

    if (!g_top_block_is_function) {
        struct StructFinalizer *fin = struct_finalizer_find(g_current_struct_tag);
        struct StructFinalizer *clone = struct_clone_find(g_current_struct_tag);
        register_tags_in_text(head->text);
        out = text_join3(head, lb, body);
        out = text_join(out, rb);
        if (g_in_aggregate_struct && g_current_struct_tag[0] != '\0') {
            text_add(out, ";");
            if (fin != NULL && fin->count > 0) {
                append_struct_finalizer_definition(out, fin);
            }
            append_struct_clone_definition(out, clone);
            g_skip_next_semi = 1;
        }
        out->ast = ast_block(body_ast);
        g_top_block_is_function = 0;
        g_in_aggregate_struct = 0;
        g_current_struct_tag[0] = '\0';
        return out;
    }

    (void)name;
    register_owned_function_signature(head->text);
    head = remove_percent(strip_attributes(head));
    {
        int body_tail_return = body->tail_return;
        out = text_join3(head, lb, body);
        if ((g_owned.count > 0 || g_finalized_locals.count > 0) && !body_tail_return) {
            const char *last = out->len > 0 ? out->text + out->len - 1 : out->text;
            if (out->len == 0 || *last != '\n') {
                text_add_ch(out, '\n');
            }
            emit_frees(out, "    ");
        }
    }
    out = text_join(out, rb);
    out->ast = ast_block(body_ast);
    g_owned.count = 0;
    g_finalized_locals.count = 0;
    g_locals.count = 0;
    g_in_function = 0;
    return out;
}

int main(int argc, char **argv)
{
    int rc;

    if (argc != 2) {
        fputs("usage: cauto input.c > output.c\n", stderr);
        return 2;
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        perror(argv[1]);
        return 1;
    }
    yylineno = 1;
    g_output = text_new();
    g_malloc_funcs.count = 0;
    g_right_value_id = 0;
    g_need_string_h = 0;
    g_need_string_typedef = 0;

    rc = yyparse();
    if (rc != 0) {
        fclose(yyin);
        return 1;
    }

    {
        const char *p = g_output->text;
        while (strncmp(p, "#define", 7) == 0) {
            const char *nl = strchr(p, '\n');
            if (nl == NULL) {
                fputs(p, stdout);
                p += strlen(p);
                break;
            }
            fwrite(p, 1, (size_t)(nl + 1 - p), stdout);
            p = nl + 1;
        }
        if (g_need_string_h) {
            fputs("#include <string.h>\n", stdout);
        }
        if (g_need_string_typedef) {
            fputs("typedef char* string;\n", stdout);
        }
        fputs(p, stdout);
    }
    text_free(g_output);
    fclose(yyin);
    return 0;
}
