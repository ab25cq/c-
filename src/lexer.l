%option noyywrap noinput nounput yylineno

%top{
#define _POSIX_C_SOURCE 200809L
}

%{
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct Text {
    char *text;
    size_t len;
    size_t cap;
    int tail_return;
    struct Node *ast;
};

#include "parser.h"

static char *pending;
static size_t pending_len;
static size_t pending_cap;
static int new_type_scan;
static int object_init_depth;
static FILE *include_files[16];
static int include_lines[16];
static int include_depth;

void cminus_push_include(FILE *fp)
{
    if (include_depth >= 16) {
        fputs("c-: include depth exceeded\n", stderr);
        exit(1);
    }
    if (YY_CURRENT_BUFFER == NULL && yyin != NULL) {
        yy_switch_to_buffer(yy_create_buffer(yyin, YY_BUF_SIZE));
    }
    include_files[include_depth] = fp;
    include_lines[include_depth] = yylineno;
    include_depth++;
    yypush_buffer_state(yy_create_buffer(fp, YY_BUF_SIZE));
    yylineno = 1;
}

static void *lex_xmalloc(size_t size)
{
    void *p = malloc(size);
    if (p == NULL) {
        fputs("out of memory\n", stderr);
        exit(1);
    }
    return p;
}

static void pending_reserve(size_t need)
{
    char *p;
    if (pending_cap == 0) {
        pending_cap = 256;
        pending = lex_xmalloc(pending_cap);
        pending[0] = '\0';
    }
    while (pending_cap < need) {
        pending_cap *= 2;
    }
    p = realloc(pending, pending_cap);
    if (p == NULL) {
        fputs("out of memory\n", stderr);
        exit(1);
    }
    pending = p;
}

static void pending_add(const char *text, size_t len)
{
    if (pending_len + len + 1 > pending_cap) {
        pending_reserve(pending_len + len + 1);
    }
    memcpy(pending + pending_len, text, len);
    pending_len += len;
    pending[pending_len] = '\0';
}

static struct Text *lex_node_new(void)
{
    struct Text *node = lex_xmalloc(sizeof(*node));
    node->cap = 64;
    node->len = 0;
    node->tail_return = 0;
    node->ast = NULL;
    node->text = lex_xmalloc(node->cap);
    node->text[0] = '\0';
    return node;
}

static void lex_node_reserve(struct Text *node, size_t need)
{
    char *p;
    while (node->cap < need) {
        node->cap *= 2;
    }
    p = realloc(node->text, node->cap);
    if (p == NULL) {
        fputs("out of memory\n", stderr);
        exit(1);
    }
    node->text = p;
}

static void lex_node_add(struct Text *node, const char *text, size_t len)
{
    if (node->len + len + 1 > node->cap) {
        lex_node_reserve(node, node->len + len + 1);
    }
    memcpy(node->text + node->len, text, len);
    node->len += len;
    node->text[node->len] = '\0';
}

static struct Text *token_node(const char *text, size_t len)
{
    struct Text *node = lex_node_new();
    if (pending_len > 0) {
        lex_node_add(node, pending, pending_len);
        pending_len = 0;
        pending[0] = '\0';
    }
    lex_node_add(node, text, len);
    return node;
}

static int is_c_keyword_text(const char *text, size_t len)
{
    static const char *words[] = {
        "auto", "break", "case", "char", "const", "continue", "default",
        "do", "double", "else", "enum", "extern", "float", "for", "goto",
        "if", "inline", "int", "long", "register", "restrict", "short",
        "signed", "sizeof", "static", "struct", "switch", "typedef",
        "union", "unsigned", "void", "volatile", "while", "_Bool",
        "_Complex", "_Imaginary", "_Static_assert", NULL
    };
    int i;
    for (i = 0; words[i] != NULL; i++) {
        if (strlen(words[i]) == len && strncmp(words[i], text, len) == 0) {
            return 1;
        }
    }
    return 0;
}

static int emit_token(int token)
{
    yylval.node = token_node(yytext, (size_t)yyleng);
    return token;
}
%}

DIGIT      [0-9]
ID_START   [A-Za-z_]
ID_CONT    [A-Za-z0-9_]
WS         [ \t\r\f\v\n]+
LINE       "//"[^\n]*
BLOCK      "/*"([^*]|\*+[^*/])*\*+"/"
PP         ^[ \t\r\f\v]*#[^\n]*(\\\n[^\n]*)*(\n)?
HEX        0[xX][0-9A-Fa-f]+([uUlL]*)?
NUMBER     (({DIGIT}+(\.{DIGIT}*)?)|(\.{DIGIT}+))([eEpP][+-]?{DIGIT}+)?[uUlLfF]*
STRING     L?\"(\\.|[^\\\"\n])*\"
CHAR       L?\'(\\.|[^\\\'\n])*\'

%%

<<EOF>>     {
                if (include_depth > 0) {
                    include_depth--;
                    fclose(include_files[include_depth]);
                    yypop_buffer_state();
                    yylineno = include_lines[include_depth];
                    if (YY_CURRENT_BUFFER != NULL) {
                        return yylex();
                    }
                } else {
                    yyterminate();
                }
                yyterminate();
            }

{PP}        { return emit_token(PP_LINE); }
{WS}        { pending_add(yytext, (size_t)yyleng); }
{LINE}      { pending_add(yytext, (size_t)yyleng); }
{BLOCK}     { pending_add(yytext, (size_t)yyleng); }

"return"    { return emit_token(RETURN); }
{ID_START}{ID_CONT}* {
                if (strcmp(yytext, "new") == 0) {
                    new_type_scan = 1;
                }
                if (is_c_keyword_text(yytext, (size_t)yyleng)) {
                    return emit_token(KEYWORD);
                }
                return emit_token(IDENT);
            }

{HEX}       { return emit_token(NUMBER); }
{NUMBER}    { return emit_token(NUMBER); }
{STRING}    { return emit_token(STRING_LITERAL); }
{CHAR}      { return emit_token(CHAR_LITERAL); }

"++"|"--"|"+="|"-="|"=="|"!="|"<="|">="|"&&"|"||"|"<<"|">>"|"*="|"/="|"%="|"&="|"|="|"^="|"->"|"::"|"..." {
                return emit_token(OP);
            }

"{"         {
                if (new_type_scan || object_init_depth > 0) {
                    new_type_scan = 0;
                    object_init_depth++;
                    return emit_token(OTHER);
                }
                return emit_token(LBRACE);
            }
"}"         {
                if (object_init_depth > 0) {
                    object_init_depth--;
                    return emit_token(OTHER);
                }
                return emit_token(RBRACE);
            }
"("         { return emit_token(LPAREN); }
")"         { new_type_scan = 0; return emit_token(RPAREN); }
"["         { return emit_token(LBRACKET); }
"]"         { return emit_token(RBRACKET); }
";"         { new_type_scan = 0; return emit_token(SEMI); }
","         {
                if (object_init_depth > 0) {
                    return emit_token(OTHER);
                }
                new_type_scan = 0;
                return emit_token(COMMA);
            }
"="         { return emit_token(EQUAL); }
"%"         { return emit_token(PERCENT); }
"<"/[A-Za-z_] { return emit_token(LT); }
">"         { return emit_token(GT); }

[+\-*/!^&|<>?:.~] {
                return emit_token(OP);
            }

.           { return emit_token(OTHER); }

%%
