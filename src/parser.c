/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison implementation for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output, and Bison version.  */
#define YYBISON 30802

/* Bison version string.  */
#define YYBISON_VERSION "3.8.2"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1




/* First part of user prologue.  */
#line 1 "src/parser.y"

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
#define MAX_PARAMS 32
#define MAX_GENERIC_TEMPLATES 128
#define MAX_GENERIC_INSTANCES 128
#define MAX_ENUM_VARIANTS 64
#define DEFAULT_EXPR_MAX 256

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

struct ParamInfo {
    char name[NAME_MAX_LEN];
    char def[DEFAULT_EXPR_MAX];
};

struct FunctionParams {
    char name[NAME_MAX_LEN];
    struct ParamInfo param[MAX_PARAMS];
    int count;
};

struct FunctionParamTable {
    struct FunctionParams fn[MAX_FUNCS];
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

struct GenericInstance {
    char arg[NAME_MAX_LEN];
    char concrete[NAME_MAX_LEN];
};

struct GenericTemplate {
    char param[NAME_MAX_LEN];
    char name[NAME_MAX_LEN];
    char head[DEFAULT_EXPR_MAX * 2];
    char *body;
    struct GenericInstance inst[MAX_GENERIC_INSTANCES];
    int inst_count;
};

struct GenericTemplates {
    struct GenericTemplate tmpl[MAX_GENERIC_TEMPLATES];
    int count;
};

struct PayloadVariant {
    char name[NAME_MAX_LEN];
    char payload[NAME_MAX_LEN];
    int has_payload;
};

struct PayloadEnum {
    char param[NAME_MAX_LEN];
    char name[NAME_MAX_LEN];
    struct PayloadVariant variant[MAX_ENUM_VARIANTS];
    int variant_count;
    struct GenericInstance inst[MAX_GENERIC_INSTANCES];
    int inst_count;
};

struct PayloadEnums {
    struct PayloadEnum en[MAX_GENERIC_TEMPLATES];
    int count;
};

static struct Text *g_output;
static struct Text *g_defines;
static struct Owned g_owned;
static struct Owned g_finalized_locals;
static struct Funcs g_malloc_funcs;
static struct FunctionParamTable g_param_funcs;
static struct Symbols g_globals;
static struct Symbols g_locals;
static struct Tags g_tags;
static struct GenericTemplates g_generic_structs;
static struct GenericTemplates g_generic_funcs;
static struct PayloadEnums g_payload_enums;
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
static int g_need_stdlib_h;
static int g_need_string_typedef;
static int g_current_generic_kind;
static int g_current_payload_enum;
static int g_foreach_id;
static int g_index_id;
static int g_need_stdio_h;
static int g_need_execinfo_h;
static int g_emit_uniq;
static int g_function_returns_move;
static char g_current_function_name[NAME_MAX_LEN];
static struct Type g_current_function_ret;
static const char *g_input_path;

int yylex(void);
void cminus_push_include(FILE *fp);
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
static struct Type type_make(enum TypeKind kind, int ptr, const char *tag);
static struct Obj *obj_new(const char *name, struct Type type, int is_local, int is_function);
static void tag_add(enum TypeKind kind, const char *name);
static void symbol_add(const char *name, struct Type type);
static void begin_function(void);
static void begin_top_block(struct Text *head);
static int source_has_cminus_include(FILE *fp);
static struct Text *process_pp_line(struct Text *line);
static struct Text *process_standalone_semi(struct Text *semi);
static struct Text *finish_top_block(struct Text *head, struct Text *lb, struct Text *body, struct Text *rb);
static struct Text *process_statement(struct Text *stmt, struct Text *semi);
static struct Text *process_return(struct Text *ret, struct Text *expr, struct Text *semi);
static struct Text *process_external_decl(struct Text *decl, struct Text *semi);
static struct Text *process_control_head(struct Text *head);
static int find_assignment(const char *s);
static int parse_function_signature(const char *s, char *name, struct Type *ret);
static int malloc_func_index(const char *name);
static void owned_func_add_type(const char *name, struct Type ret);
static void append_indent_from(const char *s, struct Text *out);
static void append_leading_newlines(const char *s, struct Text *out);
static int rhs_has_malloc_call(const char *rhs, char *func_name);
static int rhs_has_function_call(const char *rhs);
static int rhs_has_new_expr(const char *rhs, struct Type *type);
static int rhs_has_clone_expr(const char *rhs, struct Type *type);
static int decl_has_borrow(const char *s);
static int extract_move_name(const char *s, char *name);
static void remove_moved_locals(const char *s);
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
static struct Text *rewrite_index_access(struct Text *in);
static struct Text *rewrite_parameter_calls(struct Text *in);
static struct Text *rewrite_generics(struct Text *in);
static struct Text *rewrite_foreach_head(struct Text *head);
static const char *matching_paren(const char *open);
static int is_generic_decl_head(const char *s);
static int parse_generic_struct_head(const char *s, char *param, char *name);
static int parse_generic_function_head(const char *s, char *param, char *name);
static int parse_generic_angle_arg(const char *p, char *arg, const char **after);
static void emit_generic_instances(FILE *out);
static int parse_payload_enum_head(const char *s, char *param, char *name);
static void emit_payload_enum_instances(FILE *out);
static struct Text *rewrite_payload_enum_constructors(struct Text *in);
static struct Text *try_rewrite_auto_payload_enum_decl(struct Text *in);
static int is_uniq_decl(const char *s);
static struct Text *strip_uniq(struct Text *in);
static struct Text *uniq_extern_decl(struct Text *in);
static const char *generic_template_body_start(const char *head, char *param);
static void append_struct_clone_name(struct Text *out, const char *tag);
static void append_struct_clone_definition(struct Text *out, struct StructFinalizer *clone);
static void append_finalize_for_type(struct Text *out, const char *indent, const char *expr, struct Type type);
static struct Text *prepend_owned_assignment_release(struct Text *stmt, const char *original, const char *lhs_expr, struct Type type);
static void append_zero_clear_after_decl(struct Text *stmt, const char *original, const char *name);

#line 403 "src/parser.c"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif

#include "parser.h"
/* Symbol kind.  */
enum yysymbol_kind_t
{
  YYSYMBOL_YYEMPTY = -2,
  YYSYMBOL_YYEOF = 0,                      /* "end of file"  */
  YYSYMBOL_YYerror = 1,                    /* error  */
  YYSYMBOL_YYUNDEF = 2,                    /* "invalid token"  */
  YYSYMBOL_IDENT = 3,                      /* IDENT  */
  YYSYMBOL_NUMBER = 4,                     /* NUMBER  */
  YYSYMBOL_STRING_LITERAL = 5,             /* STRING_LITERAL  */
  YYSYMBOL_CHAR_LITERAL = 6,               /* CHAR_LITERAL  */
  YYSYMBOL_PP_LINE = 7,                    /* PP_LINE  */
  YYSYMBOL_RETURN = 8,                     /* RETURN  */
  YYSYMBOL_KEYWORD = 9,                    /* KEYWORD  */
  YYSYMBOL_OP = 10,                        /* OP  */
  YYSYMBOL_LBRACE = 11,                    /* LBRACE  */
  YYSYMBOL_RBRACE = 12,                    /* RBRACE  */
  YYSYMBOL_LPAREN = 13,                    /* LPAREN  */
  YYSYMBOL_RPAREN = 14,                    /* RPAREN  */
  YYSYMBOL_LBRACKET = 15,                  /* LBRACKET  */
  YYSYMBOL_RBRACKET = 16,                  /* RBRACKET  */
  YYSYMBOL_LT = 17,                        /* LT  */
  YYSYMBOL_GT = 18,                        /* GT  */
  YYSYMBOL_SEMI = 19,                      /* SEMI  */
  YYSYMBOL_COMMA = 20,                     /* COMMA  */
  YYSYMBOL_EQUAL = 21,                     /* EQUAL  */
  YYSYMBOL_PERCENT = 22,                   /* PERCENT  */
  YYSYMBOL_OTHER = 23,                     /* OTHER  */
  YYSYMBOL_YYACCEPT = 24,                  /* $accept  */
  YYSYMBOL_translation_unit = 25,          /* translation_unit  */
  YYSYMBOL_external_item = 26,             /* external_item  */
  YYSYMBOL_27_1 = 27,                      /* $@1  */
  YYSYMBOL_top_seq = 28,                   /* top_seq  */
  YYSYMBOL_top_part = 29,                  /* top_part  */
  YYSYMBOL_compound_items = 30,            /* compound_items  */
  YYSYMBOL_compound_item = 31,             /* compound_item  */
  YYSYMBOL_return_statement = 32,          /* return_statement  */
  YYSYMBOL_stmt_seq = 33,                  /* stmt_seq  */
  YYSYMBOL_stmt_part = 34,                 /* stmt_part  */
  YYSYMBOL_paren_group = 35,               /* paren_group  */
  YYSYMBOL_paren_items = 36,               /* paren_items  */
  YYSYMBOL_paren_part = 37,                /* paren_part  */
  YYSYMBOL_bracket_group = 38,             /* bracket_group  */
  YYSYMBOL_bracket_items = 39,             /* bracket_items  */
  YYSYMBOL_bracket_part = 40,              /* bracket_part  */
  YYSYMBOL_angle_group = 41,               /* angle_group  */
  YYSYMBOL_angle_items = 42,               /* angle_items  */
  YYSYMBOL_angle_part = 43,                /* angle_part  */
  YYSYMBOL_token = 44,                     /* token  */
  YYSYMBOL_token_no_comma = 45             /* token_no_comma  */
};
typedef enum yysymbol_kind_t yysymbol_kind_t;




#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

/* Work around bug in HP-UX 11.23, which defines these macros
   incorrectly for preprocessor constants.  This workaround can likely
   be removed in 2023, as HPE has promised support for HP-UX 11.23
   (aka HP-UX 11i v2) only through the end of 2022; see Table 2 of
   <https://h20195.www2.hpe.com/V2/getpdf.aspx/4AA4-7673ENW.pdf>.  */
#ifdef __hpux
# undef UINT_LEAST8_MAX
# undef UINT_LEAST16_MAX
# define UINT_LEAST8_MAX 255
# define UINT_LEAST16_MAX 65535
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))


/* Stored state numbers (used for stacks). */
typedef yytype_int8 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif


#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YY_USE(E) ((void) (E))
#else
# define YY_USE(E) /* empty */
#endif

/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
#if defined __GNUC__ && ! defined __ICC && 406 <= __GNUC__ * 100 + __GNUC_MINOR__
# if __GNUC__ * 100 + __GNUC_MINOR__ < 407
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")
# else
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# endif
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if !defined yyoverflow

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* !defined yyoverflow */

#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  2
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   272

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  24
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  22
/* YYNRULES -- Number of rules.  */
#define YYNRULES  75
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  87

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   278


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK                     \
   ? YY_CAST (yysymbol_kind_t, yytranslate[YYX])        \
   : YYSYMBOL_YYUNDEF)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23
};

#if YYDEBUG
/* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,   355,   355,   356,   361,   363,   365,   368,   367,   374,
     376,   381,   383,   385,   387,   393,   394,   399,   401,   403,
     405,   407,   409,   411,   416,   418,   423,   425,   430,   432,
     434,   436,   441,   447,   448,   453,   455,   457,   459,   464,
     470,   471,   476,   478,   480,   482,   487,   493,   494,   499,
     501,   503,   505,   510,   512,   514,   516,   518,   520,   522,
     524,   526,   528,   530,   532,   537,   539,   541,   543,   545,
     547,   549,   551,   553,   555,   557
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if YYDEBUG || 0
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "\"end of file\"", "error", "\"invalid token\"", "IDENT", "NUMBER",
  "STRING_LITERAL", "CHAR_LITERAL", "PP_LINE", "RETURN", "KEYWORD", "OP",
  "LBRACE", "RBRACE", "LPAREN", "RPAREN", "LBRACKET", "RBRACKET", "LT",
  "GT", "SEMI", "COMMA", "EQUAL", "PERCENT", "OTHER", "$accept",
  "translation_unit", "external_item", "$@1", "top_seq", "top_part",
  "compound_items", "compound_item", "return_statement", "stmt_seq",
  "stmt_part", "paren_group", "paren_items", "paren_part", "bracket_group",
  "bracket_items", "bracket_part", "angle_group", "angle_items",
  "angle_part", "token", "token_no_comma", YY_NULLPTR
};

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  return yytname[yysymbol];
}
#endif

#define YYPACT_NINF (-67)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-72)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     -67,    39,   -67,   -67,   -67,   -67,   -67,   -67,   -67,   -67,
     -67,   -67,    -6,   -67,   -67,   -67,   -67,   -67,   -67,   144,
     -67,   -67,   -67,   -67,   -67,   165,   186,   207,   -67,   -67,
     -67,   -67,   -67,   -67,   -67,   -67,   -67,   -67,    -8,   -67,
     -67,   -67,   -67,   -67,   -67,   -67,   -67,   -67,   -67,   -67,
     -67,   -67,   -67,   -67,   -67,   -67,   -67,   -67,   -67,   -67,
     -67,   -67,    60,   -67,   228,   -67,   -67,   -67,   -67,   -67,
     123,   -67,   -67,   -67,   -67,   -67,   -67,   249,    81,   -67,
     -67,   -67,   -67,   -67,   -67,   102,   -67
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_int8 yydefact[] =
{
       2,     0,     1,    65,    66,    67,    68,     4,    69,    70,
      33,    40,    47,    72,     5,    73,    74,    75,     3,     0,
       9,    12,    13,    14,    11,     0,     0,     0,     7,     6,
      10,    53,    54,    55,    56,    57,    58,    32,    47,    60,
      61,    62,    63,    64,    36,    34,    37,    38,    35,    39,
      43,    44,    41,    45,    42,    46,    50,    51,    52,    48,
      49,    15,     0,    17,     0,    15,     8,    18,    16,    19,
       0,    26,    29,    30,    31,    28,    24,     0,     0,    15,
      20,    21,    27,    25,    22,     0,    23
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int8 yypgoto[] =
{
     -67,   -67,   -67,   -67,   -67,   -12,   -63,   -67,   -67,   -50,
     -66,    -1,   -67,   -67,     2,   -67,   -67,    11,   -67,   -67,
     -17,     0
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int8 yydefgoto[] =
{
       0,     1,    18,    61,    19,    20,    62,    68,    69,    70,
      71,    72,    25,    45,    73,    26,    52,    74,    27,    59,
      48,    75
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int8 yytable[] =
{
      21,    24,    78,    22,    82,   -71,   -59,    30,   -59,    54,
      60,    82,    23,   -71,    77,     0,    85,     0,    21,    24,
       0,    22,     0,     0,    44,    50,    56,    46,    51,    57,
      23,     0,     0,     0,     0,     0,    47,    53,    58,     2,
       0,     0,     3,     4,     5,     6,     7,     0,     8,     9,
       0,     0,    10,     0,    11,     0,    12,    13,    14,     0,
      15,    16,    17,     3,     4,     5,     6,    63,    64,     8,
       9,    65,    66,    10,     0,    11,     0,    12,    13,    67,
       0,    15,    16,    17,     3,     4,     5,     6,    63,    64,
       8,     9,    65,    84,    10,     0,    11,     0,    12,    13,
      67,     0,    15,    16,    17,     3,     4,     5,     6,    63,
      64,     8,     9,    65,    86,    10,     0,    11,     0,    12,
      13,    67,     0,    15,    16,    17,     3,     4,     5,     6,
       0,     0,     8,     9,    79,     0,    10,     0,    11,     0,
      12,    13,    80,    81,    15,    16,    17,     3,     4,     5,
       6,     0,     0,     8,     9,    28,     0,    10,     0,    11,
       0,    12,    13,    29,     0,    15,    16,    17,    31,    32,
      33,    34,     0,     0,    35,    36,     0,     0,    10,    37,
      11,     0,    38,    39,     0,    40,    41,    42,    43,    31,
      32,    33,    34,     0,     0,    35,    36,     0,     0,    10,
       0,    11,    49,    38,    39,     0,    40,    41,    42,    43,
      31,    32,    33,    34,     0,     0,    35,    36,     0,     0,
      10,     0,    11,     0,    38,    55,     0,    40,    41,    42,
      43,     3,     4,     5,     6,     0,     0,     8,     9,     0,
       0,    10,     0,    11,     0,    12,    13,    76,     0,    15,
      16,    17,     3,     4,     5,     6,     0,     0,     8,     9,
       0,     0,    10,     0,    11,     0,    12,    13,    83,     0,
      15,    16,    17
};

static const yytype_int8 yycheck[] =
{
       1,     1,    65,     1,    70,    11,    14,    19,    16,    26,
      27,    77,     1,    19,    64,    -1,    79,    -1,    19,    19,
      -1,    19,    -1,    -1,    25,    26,    27,    25,    26,    27,
      19,    -1,    -1,    -1,    -1,    -1,    25,    26,    27,     0,
      -1,    -1,     3,     4,     5,     6,     7,    -1,     9,    10,
      -1,    -1,    13,    -1,    15,    -1,    17,    18,    19,    -1,
      21,    22,    23,     3,     4,     5,     6,     7,     8,     9,
      10,    11,    12,    13,    -1,    15,    -1,    17,    18,    19,
      -1,    21,    22,    23,     3,     4,     5,     6,     7,     8,
       9,    10,    11,    12,    13,    -1,    15,    -1,    17,    18,
      19,    -1,    21,    22,    23,     3,     4,     5,     6,     7,
       8,     9,    10,    11,    12,    13,    -1,    15,    -1,    17,
      18,    19,    -1,    21,    22,    23,     3,     4,     5,     6,
      -1,    -1,     9,    10,    11,    -1,    13,    -1,    15,    -1,
      17,    18,    19,    20,    21,    22,    23,     3,     4,     5,
       6,    -1,    -1,     9,    10,    11,    -1,    13,    -1,    15,
      -1,    17,    18,    19,    -1,    21,    22,    23,     3,     4,
       5,     6,    -1,    -1,     9,    10,    -1,    -1,    13,    14,
      15,    -1,    17,    18,    -1,    20,    21,    22,    23,     3,
       4,     5,     6,    -1,    -1,     9,    10,    -1,    -1,    13,
      -1,    15,    16,    17,    18,    -1,    20,    21,    22,    23,
       3,     4,     5,     6,    -1,    -1,     9,    10,    -1,    -1,
      13,    -1,    15,    -1,    17,    18,    -1,    20,    21,    22,
      23,     3,     4,     5,     6,    -1,    -1,     9,    10,    -1,
      -1,    13,    -1,    15,    -1,    17,    18,    19,    -1,    21,
      22,    23,     3,     4,     5,     6,    -1,    -1,     9,    10,
      -1,    -1,    13,    -1,    15,    -1,    17,    18,    19,    -1,
      21,    22,    23
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,    25,     0,     3,     4,     5,     6,     7,     9,    10,
      13,    15,    17,    18,    19,    21,    22,    23,    26,    28,
      29,    35,    38,    41,    45,    36,    39,    42,    11,    19,
      29,     3,     4,     5,     6,     9,    10,    14,    17,    18,
      20,    21,    22,    23,    35,    37,    38,    41,    44,    16,
      35,    38,    40,    41,    44,    18,    35,    38,    41,    43,
      44,    27,    30,     7,     8,    11,    12,    19,    31,    32,
      33,    34,    35,    38,    41,    45,    19,    33,    30,    11,
      19,    20,    34,    19,    12,    30,    12
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr1[] =
{
       0,    24,    25,    25,    26,    26,    26,    27,    26,    28,
      28,    29,    29,    29,    29,    30,    30,    31,    31,    31,
      31,    31,    31,    31,    32,    32,    33,    33,    34,    34,
      34,    34,    35,    36,    36,    37,    37,    37,    37,    38,
      39,    39,    40,    40,    40,    40,    41,    42,    42,    43,
      43,    43,    43,    44,    44,    44,    44,    44,    44,    44,
      44,    44,    44,    44,    44,    45,    45,    45,    45,    45,
      45,    45,    45,    45,    45,    45
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     0,     2,     1,     1,     2,     0,     5,     1,
       2,     1,     1,     1,     1,     0,     2,     1,     1,     1,
       2,     2,     3,     4,     2,     3,     1,     2,     1,     1,
       1,     1,     3,     0,     2,     1,     1,     1,     1,     3,
       0,     2,     1,     1,     1,     1,     3,     0,     2,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1
};


enum { YYENOMEM = -2 };

#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab
#define YYNOMEM         goto yyexhaustedlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == YYEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Backward compatibility with an undocumented macro.
   Use YYerror or YYUNDEF. */
#define YYERRCODE YYUNDEF


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)




# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Kind, Value); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
  if (!yyvaluep)
    return;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo,
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  yy_symbol_value_print (yyo, yykind, yyvaluep);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp,
                 int yyrule)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       YY_ACCESSING_SYMBOL (+yyssp[yyi + 1 - yynrhs]),
                       &yyvsp[(yyi + 1) - (yynrhs)]);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args) ((void) 0)
# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif






/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep)
{
  YY_USE (yyvaluep);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yykind, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/* Lookahead token kind.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;
/* Number of syntax errors so far.  */
int yynerrs;




/*----------.
| yyparse.  |
`----------*/

int
yyparse (void)
{
    yy_state_fast_t yystate = 0;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus = 0;

    /* Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* Their size.  */
    YYPTRDIFF_T yystacksize = YYINITDEPTH;

    /* The state stack: array, bottom, top.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss = yyssa;
    yy_state_t *yyssp = yyss;

    /* The semantic value stack: array, bottom, top.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs = yyvsa;
    YYSTYPE *yyvsp = yyvs;

  int yyn;
  /* The return value of yyparse.  */
  int yyresult;
  /* Lookahead symbol kind.  */
  yysymbol_kind_t yytoken = YYSYMBOL_YYEMPTY;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;



#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yychar = YYEMPTY; /* Cause a token to be read.  */

  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END
  YY_STACK_PRINT (yyss, yyssp);

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    YYNOMEM;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        YYNOMEM;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          YYNOMEM;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */


  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:
  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either empty, or end-of-input, or a valid lookahead.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token\n"));
      yychar = yylex ();
    }

  if (yychar <= YYEOF)
    {
      yychar = YYEOF;
      yytoken = YYSYMBOL_YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else if (yychar == YYerror)
    {
      /* The scanner already issued an error message, process directly
         to error recovery.  But do not keep the error token as
         lookahead, it is too special and may lead us to an endless
         loop in error recovery. */
      yychar = YYUNDEF;
      yytoken = YYSYMBOL_YYerror;
      goto yyerrlab1;
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 2: /* translation_unit: %empty  */
#line 355 "src/parser.y"
        { (yyval.node) = text_new(); }
#line 1533 "src/parser.c"
    break;

  case 3: /* translation_unit: translation_unit external_item  */
#line 357 "src/parser.y"
        { (yyval.node) = text_join((yyvsp[-1].node), (yyvsp[0].node)); g_output = (yyval.node); }
#line 1539 "src/parser.c"
    break;

  case 4: /* external_item: PP_LINE  */
#line 362 "src/parser.y"
        { (yyval.node) = process_pp_line((yyvsp[0].node)); }
#line 1545 "src/parser.c"
    break;

  case 5: /* external_item: SEMI  */
#line 364 "src/parser.y"
        { (yyval.node) = process_standalone_semi((yyvsp[0].node)); }
#line 1551 "src/parser.c"
    break;

  case 6: /* external_item: top_seq SEMI  */
#line 366 "src/parser.y"
        { (yyval.node) = process_external_decl((yyvsp[-1].node), (yyvsp[0].node)); }
#line 1557 "src/parser.c"
    break;

  case 7: /* $@1: %empty  */
#line 368 "src/parser.y"
        { begin_top_block((yyvsp[-1].node)); }
#line 1563 "src/parser.c"
    break;

  case 8: /* external_item: top_seq LBRACE $@1 compound_items RBRACE  */
#line 370 "src/parser.y"
        { (yyval.node) = finish_top_block((yyvsp[-4].node), (yyvsp[-3].node), (yyvsp[-1].node), (yyvsp[0].node)); }
#line 1569 "src/parser.c"
    break;

  case 9: /* top_seq: top_part  */
#line 375 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1575 "src/parser.c"
    break;

  case 10: /* top_seq: top_seq top_part  */
#line 377 "src/parser.y"
        { (yyval.node) = text_join((yyvsp[-1].node), (yyvsp[0].node)); }
#line 1581 "src/parser.c"
    break;

  case 11: /* top_part: token_no_comma  */
#line 382 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1587 "src/parser.c"
    break;

  case 12: /* top_part: paren_group  */
#line 384 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1593 "src/parser.c"
    break;

  case 13: /* top_part: bracket_group  */
#line 386 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1599 "src/parser.c"
    break;

  case 14: /* top_part: angle_group  */
#line 388 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1605 "src/parser.c"
    break;

  case 15: /* compound_items: %empty  */
#line 393 "src/parser.y"
        { (yyval.node) = text_new(); }
#line 1611 "src/parser.c"
    break;

  case 16: /* compound_items: compound_items compound_item  */
#line 395 "src/parser.y"
        { (yyval.node) = text_join((yyvsp[-1].node), (yyvsp[0].node)); }
#line 1617 "src/parser.c"
    break;

  case 17: /* compound_item: PP_LINE  */
#line 400 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1623 "src/parser.c"
    break;

  case 18: /* compound_item: SEMI  */
#line 402 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1629 "src/parser.c"
    break;

  case 19: /* compound_item: return_statement  */
#line 404 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1635 "src/parser.c"
    break;

  case 20: /* compound_item: stmt_seq SEMI  */
#line 406 "src/parser.y"
        { (yyval.node) = process_statement((yyvsp[-1].node), (yyvsp[0].node)); }
#line 1641 "src/parser.c"
    break;

  case 21: /* compound_item: stmt_seq COMMA  */
#line 408 "src/parser.y"
        { (yyval.node) = text_join((yyvsp[-1].node), (yyvsp[0].node)); (yyval.node)->tail_return = 0; }
#line 1647 "src/parser.c"
    break;

  case 22: /* compound_item: LBRACE compound_items RBRACE  */
#line 410 "src/parser.y"
        { (yyval.node) = text_join3((yyvsp[-2].node), (yyvsp[-1].node), (yyvsp[0].node)); (yyval.node)->tail_return = 0; }
#line 1653 "src/parser.c"
    break;

  case 23: /* compound_item: stmt_seq LBRACE compound_items RBRACE  */
#line 412 "src/parser.y"
        { (yyval.node) = text_join4(process_control_head((yyvsp[-3].node)), (yyvsp[-2].node), (yyvsp[-1].node), (yyvsp[0].node)); (yyval.node)->tail_return = 0; }
#line 1659 "src/parser.c"
    break;

  case 24: /* return_statement: RETURN SEMI  */
#line 417 "src/parser.y"
        { (yyval.node) = process_return((yyvsp[-1].node), text_new(), (yyvsp[0].node)); }
#line 1665 "src/parser.c"
    break;

  case 25: /* return_statement: RETURN stmt_seq SEMI  */
#line 419 "src/parser.y"
        { (yyval.node) = process_return((yyvsp[-2].node), (yyvsp[-1].node), (yyvsp[0].node)); }
#line 1671 "src/parser.c"
    break;

  case 26: /* stmt_seq: stmt_part  */
#line 424 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1677 "src/parser.c"
    break;

  case 27: /* stmt_seq: stmt_seq stmt_part  */
#line 426 "src/parser.y"
        { (yyval.node) = text_join((yyvsp[-1].node), (yyvsp[0].node)); }
#line 1683 "src/parser.c"
    break;

  case 28: /* stmt_part: token_no_comma  */
#line 431 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1689 "src/parser.c"
    break;

  case 29: /* stmt_part: paren_group  */
#line 433 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1695 "src/parser.c"
    break;

  case 30: /* stmt_part: bracket_group  */
#line 435 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1701 "src/parser.c"
    break;

  case 31: /* stmt_part: angle_group  */
#line 437 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1707 "src/parser.c"
    break;

  case 32: /* paren_group: LPAREN paren_items RPAREN  */
#line 442 "src/parser.y"
        { (yyval.node) = text_join3((yyvsp[-2].node), (yyvsp[-1].node), (yyvsp[0].node)); }
#line 1713 "src/parser.c"
    break;

  case 33: /* paren_items: %empty  */
#line 447 "src/parser.y"
        { (yyval.node) = text_new(); }
#line 1719 "src/parser.c"
    break;

  case 34: /* paren_items: paren_items paren_part  */
#line 449 "src/parser.y"
        { (yyval.node) = text_join((yyvsp[-1].node), (yyvsp[0].node)); }
#line 1725 "src/parser.c"
    break;

  case 35: /* paren_part: token  */
#line 454 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1731 "src/parser.c"
    break;

  case 36: /* paren_part: paren_group  */
#line 456 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1737 "src/parser.c"
    break;

  case 37: /* paren_part: bracket_group  */
#line 458 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1743 "src/parser.c"
    break;

  case 38: /* paren_part: angle_group  */
#line 460 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1749 "src/parser.c"
    break;

  case 39: /* bracket_group: LBRACKET bracket_items RBRACKET  */
#line 465 "src/parser.y"
        { (yyval.node) = text_join3((yyvsp[-2].node), (yyvsp[-1].node), (yyvsp[0].node)); }
#line 1755 "src/parser.c"
    break;

  case 40: /* bracket_items: %empty  */
#line 470 "src/parser.y"
        { (yyval.node) = text_new(); }
#line 1761 "src/parser.c"
    break;

  case 41: /* bracket_items: bracket_items bracket_part  */
#line 472 "src/parser.y"
        { (yyval.node) = text_join((yyvsp[-1].node), (yyvsp[0].node)); }
#line 1767 "src/parser.c"
    break;

  case 42: /* bracket_part: token  */
#line 477 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1773 "src/parser.c"
    break;

  case 43: /* bracket_part: paren_group  */
#line 479 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1779 "src/parser.c"
    break;

  case 44: /* bracket_part: bracket_group  */
#line 481 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1785 "src/parser.c"
    break;

  case 45: /* bracket_part: angle_group  */
#line 483 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1791 "src/parser.c"
    break;

  case 46: /* angle_group: LT angle_items GT  */
#line 488 "src/parser.y"
        { (yyval.node) = text_join3((yyvsp[-2].node), (yyvsp[-1].node), (yyvsp[0].node)); }
#line 1797 "src/parser.c"
    break;

  case 47: /* angle_items: %empty  */
#line 493 "src/parser.y"
        { (yyval.node) = text_new(); }
#line 1803 "src/parser.c"
    break;

  case 48: /* angle_items: angle_items angle_part  */
#line 495 "src/parser.y"
        { (yyval.node) = text_join((yyvsp[-1].node), (yyvsp[0].node)); }
#line 1809 "src/parser.c"
    break;

  case 49: /* angle_part: token  */
#line 500 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1815 "src/parser.c"
    break;

  case 50: /* angle_part: paren_group  */
#line 502 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1821 "src/parser.c"
    break;

  case 51: /* angle_part: bracket_group  */
#line 504 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1827 "src/parser.c"
    break;

  case 52: /* angle_part: angle_group  */
#line 506 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1833 "src/parser.c"
    break;

  case 53: /* token: IDENT  */
#line 511 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1839 "src/parser.c"
    break;

  case 54: /* token: NUMBER  */
#line 513 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1845 "src/parser.c"
    break;

  case 55: /* token: STRING_LITERAL  */
#line 515 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1851 "src/parser.c"
    break;

  case 56: /* token: CHAR_LITERAL  */
#line 517 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1857 "src/parser.c"
    break;

  case 57: /* token: KEYWORD  */
#line 519 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1863 "src/parser.c"
    break;

  case 58: /* token: OP  */
#line 521 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1869 "src/parser.c"
    break;

  case 59: /* token: LT  */
#line 523 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1875 "src/parser.c"
    break;

  case 60: /* token: GT  */
#line 525 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1881 "src/parser.c"
    break;

  case 61: /* token: COMMA  */
#line 527 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1887 "src/parser.c"
    break;

  case 62: /* token: EQUAL  */
#line 529 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1893 "src/parser.c"
    break;

  case 63: /* token: PERCENT  */
#line 531 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1899 "src/parser.c"
    break;

  case 64: /* token: OTHER  */
#line 533 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1905 "src/parser.c"
    break;

  case 65: /* token_no_comma: IDENT  */
#line 538 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1911 "src/parser.c"
    break;

  case 66: /* token_no_comma: NUMBER  */
#line 540 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1917 "src/parser.c"
    break;

  case 67: /* token_no_comma: STRING_LITERAL  */
#line 542 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1923 "src/parser.c"
    break;

  case 68: /* token_no_comma: CHAR_LITERAL  */
#line 544 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1929 "src/parser.c"
    break;

  case 69: /* token_no_comma: KEYWORD  */
#line 546 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1935 "src/parser.c"
    break;

  case 70: /* token_no_comma: OP  */
#line 548 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1941 "src/parser.c"
    break;

  case 71: /* token_no_comma: LT  */
#line 550 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1947 "src/parser.c"
    break;

  case 72: /* token_no_comma: GT  */
#line 552 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1953 "src/parser.c"
    break;

  case 73: /* token_no_comma: EQUAL  */
#line 554 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1959 "src/parser.c"
    break;

  case 74: /* token_no_comma: PERCENT  */
#line 556 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1965 "src/parser.c"
    break;

  case 75: /* token_no_comma: OTHER  */
#line 558 "src/parser.y"
        { (yyval.node) = (yyvsp[0].node); }
#line 1971 "src/parser.c"
    break;


#line 1975 "src/parser.c"

      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", YY_CAST (yysymbol_kind_t, yyr1[yyn]), &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;

  *++yyvsp = yyval;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYSYMBOL_YYEMPTY : YYTRANSLATE (yychar);
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
      yyerror (YY_("syntax error"));
    }

  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= YYEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == YYEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval);
          yychar = YYEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;
  ++yynerrs;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  /* Pop stack until we find a state that shifts the error token.  */
  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYSYMBOL_YYerror;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYSYMBOL_YYerror)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;


      yydestruct ("Error: popping",
                  YY_ACCESSING_SYMBOL (yystate), yyvsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", YY_ACCESSING_SYMBOL (yyn), yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturnlab;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturnlab;


/*-----------------------------------------------------------.
| yyexhaustedlab -- YYNOMEM (memory exhaustion) comes here.  |
`-----------------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  goto yyreturnlab;


/*----------------------------------------------------------.
| yyreturnlab -- parsing is finished, clean up and return.  |
`----------------------------------------------------------*/
yyreturnlab:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif

  return yyresult;
}

#line 561 "src/parser.y"


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
    fprintf(stderr, "c-: parse error near line %d: %s\n", yylineno, msg);
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

static void copy_trimmed(char *out, size_t out_size, const char *start, const char *end)
{
    size_t n;

    while (start < end && isspace((unsigned char)*start)) {
        start++;
    }
    while (end > start && isspace((unsigned char)end[-1])) {
        end--;
    }
    n = (size_t)(end - start);
    if (n >= out_size) {
        n = out_size - 1;
    }
    memcpy(out, start, n);
    out[n] = '\0';
}

static void mangle_type_arg(char *out, size_t out_size, const char *arg)
{
    const char *p = skip_ws(arg);
    size_t n = 0;

    if (starts_word(p, "struct")) {
        p = skip_ws(p + 6);
    } else if (starts_word(p, "union")) {
        p = skip_ws(p + 5);
    } else if (starts_word(p, "enum")) {
        p = skip_ws(p + 4);
    }
    while (*p != '\0' && n + 1 < out_size) {
        if (isalnum((unsigned char)*p)) {
            out[n++] = *p;
        } else if (*p == '*') {
            const char *word = "ptr";
            if (n > 0 && out[n - 1] != '_') {
                out[n++] = '_';
            }
            while (*word != '\0' && n + 1 < out_size) {
                out[n++] = *word++;
            }
        } else if (*p == '_' || isspace((unsigned char)*p) || *p == ',' || *p == '<' || *p == '>') {
            if (n > 0 && out[n - 1] != '_') {
                out[n++] = '_';
            }
        }
        p++;
    }
    while (n > 0 && out[n - 1] == '_') {
        n--;
    }
    if (n == 0 && out_size > 1) {
        out[n++] = 'T';
    }
    out[n] = '\0';
}

static void make_concrete_name(char *out, size_t out_size, const char *name, const char *arg)
{
    char mangled[NAME_MAX_LEN];

    mangle_type_arg(mangled, sizeof(mangled), arg);
    snprintf(out, out_size, "%s_%s", name, mangled);
}

static const char *parse_generic_prefix(const char *s, char *param)
{
    const char *p = skip_ws(s);
    const char *open;
    const char *close;

    param[0] = '\0';
    if (!starts_word(p, "generic")) {
        return NULL;
    }
    p = skip_ws(p + 7);
    if (*p != '<') {
        return NULL;
    }
    open = p;
    close = strchr(open + 1, '>');
    if (close == NULL) {
        return NULL;
    }
    copy_trimmed(param, NAME_MAX_LEN, open + 1, close);
    if (param[0] == '\0') {
        return NULL;
    }
    return skip_ws(close + 1);
}

static int parse_generic_struct_head(const char *s, char *param, char *name)
{
    const char *p = parse_generic_prefix(s, param);
    const char *end;

    name[0] = '\0';
    if (p == NULL || !starts_word(p, "struct")) {
        return 0;
    }
    p = skip_ws(p + 6);
    if (!is_ident_start((unsigned char)*p)) {
        return 0;
    }
    end = read_name(p, name);
    if (*skip_ws(end) != '\0') {
        name[0] = '\0';
        return 0;
    }
    return name[0] != '\0';
}

static int parse_generic_function_head(const char *s, char *param, char *name)
{
    const char *p = parse_generic_prefix(s, param);
    const char *open = NULL;
    const char *name_end;
    const char *name_start;

    name[0] = '\0';
    if (p == NULL) {
        return 0;
    }
    while (*p != '\0') {
        if (*p == '(') {
            open = p;
            break;
        }
        if (*p == ';' || *p == '=') {
            return 0;
        }
        p++;
    }
    if (open == NULL) {
        return 0;
    }
    name_end = open;
    while (name_end > s && isspace((unsigned char)name_end[-1])) {
        name_end--;
    }
    name_start = name_end;
    while (name_start > s && is_ident((unsigned char)name_start[-1])) {
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
    return 1;
}

static int is_generic_decl_head(const char *s)
{
    char param[NAME_MAX_LEN];

    return parse_generic_prefix(s, param) != NULL;
}

static int parse_payload_enum_head(const char *s, char *param, char *name)
{
    const char *p = skip_ws(s);
    const char *name_end;
    const char *after;

    param[0] = '\0';
    name[0] = '\0';
    if (!starts_word(p, "enum")) {
        return 0;
    }
    p = skip_ws(p + 4);
    if (!is_ident_start((unsigned char)*p)) {
        return 0;
    }
    name_end = read_name(p, name);
    if (!parse_generic_angle_arg(name_end, param, &after)) {
        name[0] = '\0';
        return 0;
    }
    if (*skip_ws(after) != '\0') {
        return 0;
    }
    return name[0] != '\0';
}

static struct GenericTemplate *generic_find(struct GenericTemplates *templates, const char *name)
{
    int i;

    for (i = 0; i < templates->count; i++) {
        if (strcmp(templates->tmpl[i].name, name) == 0) {
            return &templates->tmpl[i];
        }
    }
    return NULL;
}

static struct PayloadEnum *payload_enum_find(const char *name)
{
    int i;

    for (i = 0; i < g_payload_enums.count; i++) {
        if (strcmp(g_payload_enums.en[i].name, name) == 0) {
            return &g_payload_enums.en[i];
        }
    }
    return NULL;
}

static struct GenericInstance *payload_enum_instance_get(struct PayloadEnum *en, const char *arg)
{
    int i;
    char clean_arg[NAME_MAX_LEN];

    copy_trimmed(clean_arg, sizeof(clean_arg), arg, arg + strlen(arg));
    if (clean_arg[0] == '\0') {
        strcpy(clean_arg, "void");
    }
    for (i = 0; i < en->inst_count; i++) {
        if (strcmp(en->inst[i].arg, clean_arg) == 0) {
            return &en->inst[i];
        }
    }
    if (en->inst_count >= MAX_GENERIC_INSTANCES) {
        die("too many payload enum instantiations");
    }
    strncpy(en->inst[en->inst_count].arg, clean_arg, NAME_MAX_LEN - 1);
    make_concrete_name(en->inst[en->inst_count].concrete,
                       sizeof(en->inst[en->inst_count].concrete),
                       en->name, clean_arg);
    return &en->inst[en->inst_count++];
}

static void payload_enum_add_variant(struct PayloadEnum *en, const char *name, const char *payload)
{
    struct PayloadVariant *v;

    if (en->variant_count >= MAX_ENUM_VARIANTS) {
        die("too many payload enum variants");
    }
    v = &en->variant[en->variant_count++];
    memset(v, 0, sizeof(*v));
    strncpy(v->name, name, NAME_MAX_LEN - 1);
    v->name[NAME_MAX_LEN - 1] = '\0';
    if (payload != NULL && payload[0] != '\0') {
        v->has_payload = 1;
        strncpy(v->payload, payload, NAME_MAX_LEN - 1);
        v->payload[NAME_MAX_LEN - 1] = '\0';
    }
}

static struct PayloadVariant *payload_enum_variant_find(struct PayloadEnum *en, const char *name)
{
    int i;

    for (i = 0; i < en->variant_count; i++) {
        if (strcmp(en->variant[i].name, name) == 0) {
            return &en->variant[i];
        }
    }
    return NULL;
}

static void payload_enum_add(const char *param, const char *name, const char *body)
{
    struct PayloadEnum *en;
    const char *p = body;

    if (g_payload_enums.count >= MAX_GENERIC_TEMPLATES) {
        die("too many payload enums");
    }
    en = &g_payload_enums.en[g_payload_enums.count++];
    memset(en, 0, sizeof(*en));
    strncpy(en->param, param, NAME_MAX_LEN - 1);
    strncpy(en->name, name, NAME_MAX_LEN - 1);

    while (*p != '\0') {
        char variant[NAME_MAX_LEN];
        char payload[NAME_MAX_LEN];
        const char *name_end;
        const char *q;

        p = skip_ws(p);
        if (*p == ',') {
            p++;
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            p++;
            continue;
        }
        name_end = read_name(p, variant);
        q = skip_ws(name_end);
        payload[0] = '\0';
        if (*q == '(') {
            const char *close = matching_paren(q);
            if (close == NULL) {
                die("invalid payload enum variant");
            }
            copy_trimmed(payload, sizeof(payload), q + 1, close);
            p = close + 1;
        } else {
            p = q;
        }
        payload_enum_add_variant(en, variant, payload);
        while (*p != '\0' && *p != ',') {
            p++;
        }
    }
}

static int parse_payload_enum_constructor(const char *p,
                                          char *enum_name,
                                          char *arg,
                                          char *variant,
                                          const char **args_open)
{
    const char *name_end;
    const char *after;
    const char *dot;
    const char *variant_end;

    enum_name[0] = '\0';
    arg[0] = '\0';
    variant[0] = '\0';
    p = skip_ws(p);
    if (!starts_word(p, "new")) {
        return 0;
    }
    p = skip_ws(p + 3);
    if (!is_ident_start((unsigned char)*p)) {
        return 0;
    }
    name_end = read_name(p, enum_name);
    if (!parse_generic_angle_arg(name_end, arg, &after)) {
        after = name_end;
        strcpy(arg, "void");
    }
    dot = skip_ws(after);
    if (*dot != '.') {
        return 0;
    }
    dot = skip_ws(dot + 1);
    if (!is_ident_start((unsigned char)*dot)) {
        return 0;
    }
    variant_end = read_name(dot, variant);
    *args_open = skip_ws(variant_end);
    return **args_open == '(';
}

static struct Text *rewrite_payload_enum_constructors(struct Text *in)
{
    struct Text *out = text_new();
    const char *p = in->text;
    int changed = 0;

    while (*p != '\0') {
        char enum_name[NAME_MAX_LEN];
        char arg[NAME_MAX_LEN];
        char variant[NAME_MAX_LEN];
        const char *open;
        const char *close;
        struct PayloadEnum *en;
        struct PayloadVariant *v;

        if (starts_word(p, "new") &&
            parse_payload_enum_constructor(p, enum_name, arg, variant, &open) &&
            (en = payload_enum_find(enum_name)) != NULL &&
            (v = payload_enum_variant_find(en, variant)) != NULL &&
            (close = matching_paren(open)) != NULL) {
            struct GenericInstance *inst = payload_enum_instance_get(en, arg);

            (void)v;
            text_add(out, inst->concrete);
            text_add_ch(out, '_');
            text_add(out, variant);
            text_add_ch(out, '(');
            text_add_n(out, open + 1, (size_t)(close - open - 1));
            text_add_ch(out, ')');
            p = close + 1;
            changed = 1;
            continue;
        }
        text_add_ch(out, *p++);
    }
    if (!changed) {
        text_free(out);
        return in;
    }
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(in);
    return out;
}

static struct Text *try_rewrite_auto_payload_enum_decl(struct Text *in)
{
    const char *p = skip_ws(in->text);
    const char *name_start;
    const char *name_end;
    const char *eq;
    char var[NAME_MAX_LEN];
    char enum_name[NAME_MAX_LEN];
    char arg[NAME_MAX_LEN];
    char variant[NAME_MAX_LEN];
    const char *open;
    struct PayloadEnum *en;
    struct GenericInstance *inst;
    struct Text *rhs;
    struct Text *out;
    struct Type type;

    if (!starts_word(p, "auto")) {
        return in;
    }
    p = skip_ws(p + 4);
    if (!is_ident_start((unsigned char)*p)) {
        return in;
    }
    name_start = p;
    name_end = read_name(p, var);
    eq = skip_ws(name_end);
    if (*eq != '=') {
        return in;
    }
    if (!parse_payload_enum_constructor(eq + 1, enum_name, arg, variant, &open)) {
        return in;
    }
    en = payload_enum_find(enum_name);
    if (en == NULL) {
        return in;
    }
    inst = payload_enum_instance_get(en, arg);
    rhs = text_new();
    text_add(rhs, eq + 1);
    rhs = rewrite_payload_enum_constructors(rhs);

    out = text_new();
    append_leading_newlines(in->text, out);
    append_indent_from(in->text, out);
    text_add(out, "struct ");
    text_add(out, inst->concrete);
    text_add_ch(out, ' ');
    text_add_n(out, name_start, (size_t)(name_end - name_start));
    text_add(out, " = ");
    text_add(out, skip_ws(rhs->text));
    out->tail_return = in->tail_return;
    out->ast = in->ast;

    type = type_make(TY_STRUCT, 0, inst->concrete);
    symbol_add(var, type);
    tag_add(TY_STRUCT, inst->concrete);

    text_free(rhs);
    in->ast = NULL;
    text_free(in);
    return out;
}

static struct GenericTemplate *generic_struct_find_by_concrete(const char *concrete,
                                                               struct GenericInstance **inst_out)
{
    int i;
    int j;

    for (i = 0; i < g_generic_structs.count; i++) {
        struct GenericTemplate *tmpl = &g_generic_structs.tmpl[i];
        for (j = 0; j < tmpl->inst_count; j++) {
            if (strcmp(tmpl->inst[j].concrete, concrete) == 0) {
                if (inst_out != NULL) {
                    *inst_out = &tmpl->inst[j];
                }
                return tmpl;
            }
        }
    }
    return NULL;
}

static struct GenericTemplate *generic_add(struct GenericTemplates *templates,
                                           const char *param,
                                           const char *name,
                                           const char *head,
                                           const char *body)
{
    struct GenericTemplate *tmpl;

    if (templates->count >= MAX_GENERIC_TEMPLATES) {
        die("too many generic templates");
    }
    tmpl = &templates->tmpl[templates->count++];
    memset(tmpl, 0, sizeof(*tmpl));
    strncpy(tmpl->param, param, NAME_MAX_LEN - 1);
    strncpy(tmpl->name, name, NAME_MAX_LEN - 1);
    strncpy(tmpl->head, head, sizeof(tmpl->head) - 1);
    tmpl->body = xstrdup(body);
    return tmpl;
}

static struct GenericInstance *generic_instance_get(struct GenericTemplate *tmpl, const char *arg)
{
    int i;
    char clean_arg[NAME_MAX_LEN];

    copy_trimmed(clean_arg, sizeof(clean_arg), arg, arg + strlen(arg));
    for (i = 0; i < tmpl->inst_count; i++) {
        if (strcmp(tmpl->inst[i].arg, clean_arg) == 0) {
            return &tmpl->inst[i];
        }
    }
    if (tmpl->inst_count >= MAX_GENERIC_INSTANCES) {
        die("too many generic instantiations");
    }
    strncpy(tmpl->inst[tmpl->inst_count].arg, clean_arg, NAME_MAX_LEN - 1);
    make_concrete_name(tmpl->inst[tmpl->inst_count].concrete,
                       sizeof(tmpl->inst[tmpl->inst_count].concrete),
                       tmpl->name, clean_arg);
    return &tmpl->inst[tmpl->inst_count++];
}

static int generic_method_concrete_name(const char *struct_concrete,
                                        const char *method,
                                        char *out,
                                        size_t out_size)
{
    struct GenericInstance *struct_inst = NULL;
    struct GenericTemplate *struct_tmpl = generic_struct_find_by_concrete(struct_concrete, &struct_inst);
    char func_name[NAME_MAX_LEN];
    struct GenericTemplate *func_tmpl;
    struct GenericInstance *func_inst;

    if (struct_tmpl == NULL || struct_inst == NULL) {
        return 0;
    }
    if (strlen(struct_tmpl->name) + strlen(method) + 2 > sizeof(func_name)) {
        return 0;
    }
    strcpy(func_name, struct_tmpl->name);
    strcat(func_name, "_");
    strcat(func_name, method);
    func_tmpl = generic_find(&g_generic_funcs, func_name);
    if (func_tmpl == NULL) {
        return 0;
    }
    func_inst = generic_instance_get(func_tmpl, struct_inst->arg);
    strncpy(out, func_inst->concrete, out_size - 1);
    out[out_size - 1] = '\0';
    return 1;
}

static int parse_generic_angle_arg(const char *p, char *arg, const char **after)
{
    const char *start;
    int depth = 1;

    p = skip_ws(p);
    if (*p != '<') {
        return 0;
    }
    start = ++p;
    while (*p != '\0') {
        if (*p == '<') {
            depth++;
        } else if (*p == '>') {
            depth--;
            if (depth == 0) {
                copy_trimmed(arg, NAME_MAX_LEN, start, p);
                *after = p + 1;
                return arg[0] != '\0';
            }
        }
        p++;
    }
    return 0;
}

static int split_generic_list(const char *list, char items[][NAME_MAX_LEN], int max_items)
{
    const char *start = list;
    const char *p = list;
    int depth = 0;
    int count = 0;

    while (1) {
        if (*p == '<') {
            depth++;
        } else if (*p == '>') {
            if (depth > 0) {
                depth--;
            }
        }
        if ((*p == ',' && depth == 0) || *p == '\0') {
            if (count >= max_items) {
                return -1;
            }
            copy_trimmed(items[count], NAME_MAX_LEN, start, p);
            if (items[count][0] == '\0') {
                return -1;
            }
            count++;
            if (*p == '\0') {
                break;
            }
            start = p + 1;
        }
        p++;
    }
    return count;
}

static struct Text *replace_param_and_generics(const char *s,
                                               const char *param,
                                               const char *arg,
                                               const char *old_name,
                                               const char *new_name)
{
    struct Text *out = text_new();
    char params[4][NAME_MAX_LEN];
    char args[4][NAME_MAX_LEN];
    int param_count = split_generic_list(param, params, 4);
    int arg_count = split_generic_list(arg, args, 4);
    size_t old_len = strlen(old_name);
    const char *p = s;

    while (*p != '\0') {
        int replaced_param = 0;
        if (old_len > 0 && strncmp(p, old_name, old_len) == 0 && !is_ident((unsigned char)p[old_len]) &&
            (p == s || !is_ident((unsigned char)p[-1]))) {
            const char *after;
            char old_arg[NAME_MAX_LEN];
            if (parse_generic_angle_arg(p + old_len, old_arg, &after)) {
                text_add(out, new_name);
                p = after;
                continue;
            }
            text_add(out, new_name);
            p += old_len;
        } else {
            int i;
            if (param_count > 0 && param_count == arg_count) {
                for (i = 0; i < param_count; i++) {
                    size_t param_len = strlen(params[i]);
                    if (param_len > 0 && strncmp(p, params[i], param_len) == 0 &&
                        !is_ident((unsigned char)p[param_len]) &&
                        (p == s || !is_ident((unsigned char)p[-1]))) {
                        text_add(out, args[i]);
                        p += param_len;
                        replaced_param = 1;
                        break;
                    }
                }
            }
            if (replaced_param) {
                continue;
            }
            text_add_ch(out, *p++);
        }
    }
    out = rewrite_generics(out);
    return out;
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
    fprintf(stderr, "c-: type error: cannot assign %s to %s in %s\n", rbuf, lbuf, what);
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
        "restrict", "inline", "signed", "unsigned", "_Atomic", "uniq", "borrow", "owned", NULL
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

static int has_decl_word_before(const char *s, const char *limit, const char *word)
{
    const char *p = s;
    size_t n = strlen(word);
    while ((p = strstr(p, word)) != NULL && p < limit) {
        if ((p == s || !is_ident((unsigned char)p[-1])) && !is_ident((unsigned char)p[n])) {
            return 1;
        }
        p += n;
    }
    return 0;
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
    char arg[NAME_MAX_LEN];
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
        const char *after;
        struct GenericTemplate *tmpl = generic_find(&g_generic_structs, word);
        if (tmpl != NULL && parse_generic_angle_arg(next, arg, &after)) {
            struct GenericInstance *inst = generic_instance_get(tmpl, arg);
            *base_end = after;
            *type = type_make(TY_STRUCT, 0, inst->concrete);
            return 1;
        }
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

static int parse_new_type_prefix(const char *s, const char **base_end, struct Type *type)
{
    char name[NAME_MAX_LEN];
    const char *end;
    int i;

    if (parse_base_type_prefix(s, base_end, type)) {
        return 1;
    }
    s = skip_ws(s);
    if (!is_ident_start((unsigned char)*s)) {
        return 0;
    }
    end = read_name(s, name);
    for (i = 0; i < g_tags.count; i++) {
        if (g_tags.tag[i].kind == TY_STRUCT && strcmp(g_tags.tag[i].name, name) == 0) {
            *base_end = end;
            *type = type_make(TY_STRUCT, 0, name);
            return 1;
        }
    }
    return 0;
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
    if (has_decl_word_before(s, name_start, "owned")) {
        ret->owned = 1;
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
    decl->type.owned = base_type.owned || strchr(base_end, '%') != NULL ||
        has_decl_word_before(s, name_start, "owned");
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
    if (is_generic_decl_head(p)) {
        char param[NAME_MAX_LEN];
        p = parse_generic_prefix(p, param);
    }
    return starts_word(p, "struct") || starts_word(p, "union") || starts_word(p, "enum");
}

static int parse_struct_head(const char *s, char *tag)
{
    const char *p = skip_ws(s);
    char word[NAME_MAX_LEN];

    tag[0] = '\0';
    if (is_generic_decl_head(p)) {
        char param[NAME_MAX_LEN];
        p = parse_generic_prefix(p, param);
    }
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

static struct Text *rewrite_generics(struct Text *in)
{
    struct Text *out = text_new();
    const char *p = in->text;

    while (*p != '\0') {
        if (is_ident_start((unsigned char)*p)) {
            char name[NAME_MAX_LEN];
            char arg[NAME_MAX_LEN];
            const char *name_end = read_name(p, name);
            const char *after;
            const char *member;
            struct GenericTemplate *struct_tmpl = generic_find(&g_generic_structs, name);

            if (struct_tmpl != NULL && parse_generic_angle_arg(name_end, arg, &after)) {
                if (strcmp(arg, struct_tmpl->param) == 0) {
                    text_add_n(out, p, (size_t)(after - p));
                    p = after;
                    continue;
                }
                member = skip_ws(after);
                if (*member == '.') {
                    char method[NAME_MAX_LEN];
                    char func_name[NAME_MAX_LEN];
                    struct GenericTemplate *func_tmpl;
                    const char *method_start = skip_ws(member + 1);
                    const char *method_end;
                    const char *call;

                    if (is_ident_start((unsigned char)*method_start)) {
                        method_end = read_name(method_start, method);
                        call = skip_ws(method_end);
                        if (*call == '(' && strlen(name) + strlen(method) + 2 < sizeof(func_name)) {
                            strcpy(func_name, name);
                            strcat(func_name, "_");
                            strcat(func_name, method);
	                            func_tmpl = generic_find(&g_generic_funcs, func_name);
	                            if (func_tmpl != NULL) {
	                                struct GenericInstance *func_inst = generic_instance_get(func_tmpl, arg);
	                                char func_param[NAME_MAX_LEN];
	                                char concrete_func_name[NAME_MAX_LEN];
	                                struct Type ret;
	                                const char *func_head = generic_template_body_start(func_tmpl->head, func_param);
	                                struct Text *concrete_head = replace_param_and_generics(func_head,
	                                                                                         func_tmpl->param,
	                                                                                         arg,
	                                                                                         func_tmpl->name,
	                                                                                         func_inst->concrete);
	                                if (parse_function_signature(concrete_head->text, concrete_func_name, &ret) &&
	                                    ret.owned) {
	                                    owned_func_add_type(concrete_func_name, ret);
	                                }
	                                text_free(concrete_head);
	                                text_add(out, func_inst->concrete);
	                                text_add_n(out, method_end, (size_t)(call - method_end));
	                                p = call;
	                                continue;
	                            }
                        }
                    }
                }
                {
                    struct GenericInstance *inst = generic_instance_get(struct_tmpl, arg);
                text_add(out, "struct ");
                text_add(out, inst->concrete);
                }
                p = after;
                continue;
            }
        }
        if (starts_word(p, "struct")) {
            const char *q = skip_ws(p + 6);
            char name[NAME_MAX_LEN];
            char arg[NAME_MAX_LEN];
            const char *name_end;
            const char *after;
            struct GenericTemplate *tmpl;
            struct PayloadEnum *payload_en;

            if (is_ident_start((unsigned char)*q)) {
                name_end = read_name(q, name);
                tmpl = generic_find(&g_generic_structs, name);
                if (tmpl != NULL && parse_generic_angle_arg(name_end, arg, &after)) {
                    struct GenericInstance *inst = generic_instance_get(tmpl, arg);
                    text_add(out, "struct ");
                    text_add(out, inst->concrete);
                    p = after;
                    continue;
                }
                payload_en = payload_enum_find(name);
                if (payload_en != NULL && parse_generic_angle_arg(name_end, arg, &after)) {
                    struct GenericInstance *inst = payload_enum_instance_get(payload_en, arg);
                    text_add(out, "struct ");
                    text_add(out, inst->concrete);
                    p = after;
                    continue;
                }
            }
        }
        if (is_ident_start((unsigned char)*p)) {
            char name[NAME_MAX_LEN];
            char arg[NAME_MAX_LEN];
            const char *name_end = read_name(p, name);
            const char *after;
            const char *call;
            struct GenericTemplate *tmpl = generic_find(&g_generic_funcs, name);

            if (tmpl != NULL && parse_generic_angle_arg(name_end, arg, &after)) {
                call = skip_ws(after);
                if (*call == '(') {
                    struct GenericInstance *inst = generic_instance_get(tmpl, arg);
                    text_add(out, inst->concrete);
                    text_add_n(out, after, (size_t)(call - after));
                    p = call;
                    continue;
                }
            }
        }
        text_add_ch(out, *p++);
    }
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(in);
    return out;
}

static struct Text *rewrite_foreach_head(struct Text *head)
{
    const char *p = skip_ws(head->text);
    const char *open;
    const char *close;
    const char *in_kw;
    const char *var_end;
    const char *var_start;
    char type[NAME_MAX_LEN];
    char var[NAME_MAX_LEN];
    char collection[NAME_MAX_LEN];
    char data_op[3];
    char tmp[128];
    int id;
    struct Symbol *collection_sym = NULL;
    struct Text *type_text;
    struct Text *out;

    if (!starts_word(p, "foreach")) {
        return head;
    }
    open = strchr(p, '(');
    if (open == NULL) {
        return head;
    }
    close = matching_paren(open);
    if (close == NULL) {
        return head;
    }
    in_kw = open + 1;
    while ((in_kw = strstr(in_kw, " in ")) != NULL) {
        break;
    }
    if (in_kw == NULL) {
        return head;
    }
    var_end = in_kw;
    while (var_end > open + 1 && isspace((unsigned char)var_end[-1])) {
        var_end--;
    }
    var_start = var_end;
    while (var_start > open + 1 && is_ident((unsigned char)var_start[-1])) {
        var_start--;
    }
    if (var_start == var_end || !is_ident_start((unsigned char)*var_start)) {
        return head;
    }
    copy_trimmed(type, sizeof(type), open + 1, var_start);
    copy_trimmed(var, sizeof(var), var_start, var_end);
    copy_trimmed(collection, sizeof(collection), in_kw + 4, close);
    if (type[0] == '\0' || var[0] == '\0' || collection[0] == '\0') {
        return head;
    }

    type_text = text_new();
    text_add(type_text, type);
    type_text = rewrite_generics(type_text);

    id = g_foreach_id++;
    strcpy(data_op, ".");
    collection_sym = symbol_find(collection);
    if (collection_sym != NULL && collection_sym->type.ptr > 0) {
        strcpy(data_op, "->");
    }
    out = text_new();
    append_leading_newlines(head->text, out);
    append_indent_from(head->text, out);
    if (collection_sym != NULL && collection_sym->type.kind == TY_STRUCT) {
        struct GenericInstance *list_inst = NULL;
        struct GenericTemplate *list_tmpl = generic_struct_find_by_concrete(collection_sym->type.tag, &list_inst);

        if (list_tmpl != NULL && list_inst != NULL && strcmp(list_tmpl->name, "List") == 0) {
            struct GenericTemplate *node_tmpl = generic_find(&g_generic_structs, "ListNode");
            struct GenericInstance *node_inst;

            if (node_tmpl == NULL) {
                die("ListNode generic template not found");
            }
            node_inst = generic_instance_get(node_tmpl, list_inst->arg);
            text_add(out, "for (struct ");
            text_add(out, node_inst->concrete);
            snprintf(tmp, sizeof(tmp), "* __foreach_node%d = ", id);
            text_add(out, tmp);
            text_add(out, collection);
            text_add(out, data_op);
            snprintf(tmp, sizeof(tmp), "head; __foreach_node%d != NULL; ", id);
            text_add(out, tmp);
            snprintf(tmp, sizeof(tmp), "__foreach_node%d = __foreach_node%d->next) ", id, id);
            text_add(out, tmp);
            snprintf(tmp, sizeof(tmp), "for (int __foreach_once%d = 1; ", id);
            text_add(out, tmp);
            snprintf(tmp, sizeof(tmp), "__foreach_once%d; __foreach_once%d = 0) for (", id, id);
            text_add(out, tmp);
            text_add(out, type_text->text);
            text_add(out, " ");
            text_add(out, var);
            snprintf(tmp, sizeof(tmp),
                     " = __foreach_node%d->value; __foreach_once%d; __foreach_once%d = 0)",
                     id, id, id);
            text_add(out, tmp);
            out->ast = head->ast;
            head->ast = NULL;
            text_free(type_text);
            text_free(head);
            return out;
        }
    }
    snprintf(tmp, sizeof(tmp), "for (int __foreach%d = 0, __foreach_once%d = 0; __foreach%d < ", id, id, id);
    text_add(out, tmp);
    text_add(out, collection);
    text_add(out, data_op);
    snprintf(tmp, sizeof(tmp), "len; __foreach%d++) for (__foreach_once%d = 1; __foreach_once%d; __foreach_once%d = 0) for (",
             id, id, id, id);
    text_add(out, tmp);
    text_add(out, type_text->text);
    text_add(out, " ");
    text_add(out, var);
    text_add(out, " = ");
    text_add(out, collection);
    text_add(out, data_op);
    snprintf(tmp, sizeof(tmp), "data[__foreach%d]; __foreach_once%d; __foreach_once%d = 0)",
             id, id, id);
    text_add(out, tmp);
    out->ast = head->ast;
    head->ast = NULL;
    text_free(type_text);
    text_free(head);
    return out;
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

    if (fin != NULL) {
        for (i = 0; i < fin->count; i++) {
            if (strcmp(fin->fields[i].name, field) == 0) {
                *type = fin->fields[i].type;
                return 1;
            }
        }
    }
    if (clone != NULL) {
        for (i = 0; i < clone->count; i++) {
            if (strcmp(clone->fields[i].name, field) == 0) {
                *type = clone->fields[i].type;
                return 1;
            }
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
    g_function_returns_move = 0;
    g_current_function_name[0] = '\0';
    g_current_function_ret = type_unknown();
    g_in_function = 1;
}

static void begin_top_block(struct Text *head)
{
    char name[NAME_MAX_LEN];
    char param[NAME_MAX_LEN];
    struct Type ret;
    register_tags_in_text(head->text);
    g_current_generic_kind = 0;
    g_current_payload_enum = 0;
    if (parse_payload_enum_head(head->text, param, name)) {
        g_current_payload_enum = 1;
        g_top_block_is_function = 0;
        g_in_function = 0;
    } else if (parse_generic_struct_head(head->text, param, name)) {
        g_current_generic_kind = 1;
        g_top_block_is_function = 0;
    } else if (parse_generic_function_head(head->text, param, name)) {
        g_current_generic_kind = 2;
        g_top_block_is_function = 1;
    } else {
        g_top_block_is_function = parse_function_signature(head->text, name, &ret) || !looks_like_aggregate_head(head->text);
    }
    g_in_aggregate_struct = 0;
    g_current_struct_tag[0] = '\0';
    if (g_current_payload_enum) {
        g_in_function = 0;
    } else if (g_current_generic_kind == 1) {
        g_in_function = 0;
    } else if (g_top_block_is_function) {
        begin_function();
        if (parse_function_signature(head->text, name, &ret)) {
            strncpy(g_current_function_name, name, NAME_MAX_LEN - 1);
            g_current_function_name[NAME_MAX_LEN - 1] = '\0';
            g_current_function_ret = ret;
        }
    } else if (parse_struct_head(head->text, name)) {
        g_in_aggregate_struct = 1;
        strncpy(g_current_struct_tag, name, NAME_MAX_LEN - 1);
        g_current_struct_tag[NAME_MAX_LEN - 1] = '\0';
        struct_finalizer_get(name);
        struct_clone_get(name);
    }
}

static int parse_cminus_include(const char *line, char *path, size_t path_size)
{
    const char *p = skip_ws(line);
    const char *start;
    const char *end;
    size_t n;

    if (strncmp(p, "#include", 8) != 0) {
        return 0;
    }
    p = skip_ws(p + 8);
    if (strncmp(p, "<c-.h>", 6) != 0) {
        return 0;
    }
    start = p + 1;
    end = strchr(start, '>');
    if (end == NULL) {
        return 0;
    }
    n = (size_t)(end - start);
    if (n >= path_size) {
        n = path_size - 1;
    }
    memcpy(path, start, n);
    path[n] = '\0';
    return 1;
}

static int is_stdlib_include(const char *line)
{
    const char *p = skip_ws(line);

    if (strncmp(p, "#include", 8) != 0) {
        return 0;
    }
    p = skip_ws(p + 8);
    return strncmp(p, "<stdlib.h>", 10) == 0;
}

static int is_string_include(const char *line)
{
    const char *p = skip_ws(line);

    if (strncmp(p, "#include", 8) != 0) {
        return 0;
    }
    p = skip_ws(p + 8);
    return strncmp(p, "<string.h>", 10) == 0;
}

static int is_stdio_include(const char *line)
{
    const char *p = skip_ws(line);

    if (strncmp(p, "#include", 8) != 0) {
        return 0;
    }
    p = skip_ws(p + 8);
    return strncmp(p, "<stdio.h>", 9) == 0;
}

static int is_execinfo_include(const char *line)
{
    const char *p = skip_ws(line);

    if (strncmp(p, "#include", 8) != 0) {
        return 0;
    }
    p = skip_ws(p + 8);
    return strncmp(p, "<execinfo.h>", 12) == 0;
}

static FILE *open_cminus_include(const char *include_path)
{
    const char *lib = getenv("C_MINUS_LIB");
    FILE *fp;
    char path[512];

    if (lib != NULL && lib[0] != '\0') {
        snprintf(path, sizeof(path), "%s/%s", lib, include_path);
        fp = fopen(path, "r");
        if (fp != NULL) {
            return fp;
        }
    }
    snprintf(path, sizeof(path), "lib/%s", include_path);
    fp = fopen(path, "r");
    if (fp != NULL) {
        return fp;
    }
    return NULL;
}

static int source_has_cminus_include(FILE *fp)
{
    char line[1024];
    char include_path[256];
    int found = 0;

    rewind(fp);
    while (fgets(line, sizeof(line), fp) != NULL) {
        if (parse_cminus_include(line, include_path, sizeof(include_path))) {
            found = 1;
            break;
        }
    }
    rewind(fp);
    return found;
}

static struct Text *process_pp_line(struct Text *line)
{
    char include_path[256];
    FILE *fp;
    struct Text *out;
    const char *p = skip_ws(line->text);

    if (strncmp(p, "#define", 7) == 0) {
        text_add(g_defines, line->text);
        if (line->len == 0 || line->text[line->len - 1] != '\n') {
            text_add_ch(g_defines, '\n');
        }
        out = text_new();
        text_free(line);
        return out;
    }
    if (is_stdlib_include(line->text)) {
        g_need_stdlib_h = 1;
        out = text_new();
        text_free(line);
        return out;
    }
    if (is_string_include(line->text)) {
        g_need_string_h = 1;
        out = text_new();
        text_free(line);
        return out;
    }
    if (is_stdio_include(line->text)) {
        g_need_stdio_h = 1;
        out = text_new();
        text_free(line);
        return out;
    }
    if (is_execinfo_include(line->text)) {
        g_need_execinfo_h = 1;
        out = text_new();
        text_free(line);
        return out;
    }
    if (!parse_cminus_include(line->text, include_path, sizeof(include_path))) {
        return line;
    }
    fp = open_cminus_include(include_path);
    if (fp == NULL) {
        fprintf(stderr, "c-: include not found: %s\n", include_path);
        text_free(line);
        exit(1);
    }
    cminus_push_include(fp);
    out = text_new();
    text_free(line);
    return out;
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

static void owned_remove_from(struct Owned *owned, const char *name)
{
    int index = owned_index_in(owned, name);
    int i;
    if (index < 0) {
        return;
    }
    for (i = index; i + 1 < owned->count; i++) {
        strcpy(owned->name[i], owned->name[i + 1]);
        owned->type[i] = owned->type[i + 1];
    }
    owned->count--;
}

static void owned_remove(const char *name)
{
    owned_remove_from(&g_owned, name);
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

static int function_name_looks_owned(const char *name)
{
    size_t n = strlen(name);
    if (n >= 4 && strcmp(name + n - 4, "_new") == 0) {
        return 1;
    }
    if (strstr(name, "_new_") != NULL) {
        return 1;
    }
    return 0;
}

static int decl_has_borrow(const char *s)
{
    const char *eq = strchr(s, '=');
    size_t n = eq != NULL ? (size_t)(eq - s) : strlen(s);
    char *head = xstrndup(s, n);
    int result = text_has_word(head, "borrow");
    free(head);
    return result;
}

static int extract_move_name(const char *s, char *name)
{
    const char *p = s;
    name[0] = '\0';
    while ((p = strstr(p, "move")) != NULL) {
        if ((p == s || !is_ident((unsigned char)p[-1])) && !is_ident((unsigned char)p[4])) {
            const char *q = skip_ws(p + 4);
            const char *end;
            if (!is_ident_start((unsigned char)*q)) {
                p += 4;
                continue;
            }
            end = read_name(q, name);
            if ((size_t)(end - q) >= NAME_MAX_LEN) {
                name[0] = '\0';
                return 0;
            }
            memcpy(name, q, (size_t)(end - q));
            name[end - q] = '\0';
            return 1;
        }
        p += 4;
    }
    return 0;
}

static void remove_moved_locals(const char *s)
{
    const char *p = s;
    while ((p = strstr(p, "move")) != NULL) {
        if ((p == s || !is_ident((unsigned char)p[-1])) && !is_ident((unsigned char)p[4])) {
            char name[NAME_MAX_LEN];
            const char *q = skip_ws(p + 4);
            const char *end;
            if (is_ident_start((unsigned char)*q)) {
                end = read_name(q, name);
                if ((size_t)(end - q) < NAME_MAX_LEN) {
                    memcpy(name, q, (size_t)(end - q));
                    name[end - q] = '\0';
                    owned_remove(name);
                }
            }
        }
        p += 4;
    }
}

static const char *find_matching_paren(const char *open)
{
    const char *p = open;
    int depth = 0;

    while (*p != '\0') {
        if (*p == '"') {
            p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p == '"') {
                    break;
                }
                p++;
            }
        } else if (*p == '\'') {
            p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p == '\'') {
                    break;
                }
                p++;
            }
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

static const char *find_top_level_char(const char *start, const char *end, char ch)
{
    const char *p = start;
    int paren = 0;
    int bracket = 0;
    int brace = 0;

    while (p < end) {
        if (*p == '"') {
            p++;
            while (p < end) {
                if (*p == '\\' && p + 1 < end) {
                    p += 2;
                    continue;
                }
                if (*p == '"') {
                    break;
                }
                p++;
            }
        } else if (*p == '\'') {
            p++;
            while (p < end) {
                if (*p == '\\' && p + 1 < end) {
                    p += 2;
                    continue;
                }
                if (*p == '\'') {
                    break;
                }
                p++;
            }
        } else if (*p == '(') {
            paren++;
        } else if (*p == ')' && paren > 0) {
            paren--;
        } else if (*p == '[') {
            bracket++;
        } else if (*p == ']' && bracket > 0) {
            bracket--;
        } else if (*p == '{') {
            brace++;
        } else if (*p == '}' && brace > 0) {
            brace--;
        } else if (*p == ch && paren == 0 && bracket == 0 && brace == 0) {
            return p;
        }
        p++;
    }
    return NULL;
}

static int param_name_from_text(const char *start, const char *end, char *name)
{
    struct DeclInfo decl;
    char *tmp = xstrndup(start, (size_t)(end - start));
    int ok;

    name[0] = '\0';
    ok = parse_decl(tmp, &decl) && decl.name[0] != '\0';
    if (ok) {
        strncpy(name, decl.name, NAME_MAX_LEN - 1);
        name[NAME_MAX_LEN - 1] = '\0';
    }
    free(tmp);
    return ok;
}

static struct FunctionParams *function_params_find(const char *name)
{
    int i;
    for (i = 0; i < g_param_funcs.count; i++) {
        if (strcmp(g_param_funcs.fn[i].name, name) == 0) {
            return &g_param_funcs.fn[i];
        }
    }
    return NULL;
}

static struct FunctionParams *function_params_get(const char *name)
{
    struct FunctionParams *fn = function_params_find(name);

    if (fn != NULL) {
        return fn;
    }
    if (g_param_funcs.count >= MAX_FUNCS) {
        die("too many functions with parameter metadata");
    }
    fn = &g_param_funcs.fn[g_param_funcs.count++];
    memset(fn, 0, sizeof(*fn));
    strncpy(fn->name, name, NAME_MAX_LEN - 1);
    fn->name[NAME_MAX_LEN - 1] = '\0';
    return fn;
}

static void register_function_params(const char *s)
{
    char name[NAME_MAX_LEN];
    struct Type ret;
    const char *open;
    const char *close;
    const char *p;
    struct FunctionParams *fn;

    if (!parse_function_signature(s, name, &ret)) {
        return;
    }
    open = strchr(s, '(');
    if (open == NULL) {
        return;
    }
    close = find_matching_paren(open);
    if (close == NULL) {
        return;
    }
    if (find_top_level_char(open + 1, close, '=') == NULL) {
        return;
    }
    fn = function_params_get(name);
    fn->count = 0;
    p = open + 1;
    while (p < close) {
        const char *arg_end = find_top_level_char(p, close, ',');
        const char *eq;
        const char *param_end;
        char param_name[NAME_MAX_LEN];

        if (arg_end == NULL) {
            arg_end = close;
        }
        while (p < arg_end && isspace((unsigned char)*p)) {
            p++;
        }
        param_end = arg_end;
        while (param_end > p && isspace((unsigned char)param_end[-1])) {
            param_end--;
        }
        if (param_end > p && !(param_end - p == 4 && strncmp(p, "void", 4) == 0)) {
            eq = find_top_level_char(p, param_end, '=');
            if (eq == NULL) {
                eq = param_end;
            }
            if (fn->count >= MAX_PARAMS) {
                die("too many function parameters");
            }
            if (param_name_from_text(p, eq, param_name)) {
                const char *def_start = eq < param_end ? skip_ws(eq + 1) : param_end;
                size_t def_len = (size_t)(param_end - def_start);

                strncpy(fn->param[fn->count].name, param_name, NAME_MAX_LEN - 1);
                fn->param[fn->count].name[NAME_MAX_LEN - 1] = '\0';
                if (def_len >= DEFAULT_EXPR_MAX) {
                    def_len = DEFAULT_EXPR_MAX - 1;
                }
                memcpy(fn->param[fn->count].def, def_start, def_len);
                fn->param[fn->count].def[def_len] = '\0';
                fn->count++;
            }
        }
        p = arg_end;
        if (p < close && *p == ',') {
            p++;
        }
    }
}

static struct Text *strip_default_parameters(struct Text *in)
{
    const char *open = strchr(in->text, '(');
    const char *close;
    const char *p;
    struct Text *out;

    if (open == NULL) {
        return in;
    }
    close = find_matching_paren(open);
    if (close == NULL) {
        return in;
    }
    out = text_new();
    text_add_n(out, in->text, (size_t)(open + 1 - in->text));
    p = open + 1;
    while (p < close) {
        const char *param_end = find_top_level_char(p, close, ',');
        const char *eq;

        if (param_end == NULL) {
            param_end = close;
        }
        eq = find_top_level_char(p, param_end, '=');
        if (eq != NULL) {
            while (eq > p && isspace((unsigned char)eq[-1])) {
                eq--;
            }
            text_add_n(out, p, (size_t)(eq - p));
        } else {
            text_add_n(out, p, (size_t)(param_end - p));
        }
        if (param_end < close && *param_end == ',') {
            text_add_ch(out, ',');
        }
        p = param_end;
        if (p < close && *p == ',') {
            p++;
        }
    }
    text_add(out, close);
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    text_free(in);
    return out;
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
        {
            char name[NAME_MAX_LEN];
            const char *end = read_name(rhs + i, name);
            const char *q = end;
            if ((size_t)(end - (rhs + i)) < NAME_MAX_LEN && function_name_looks_owned(name)) {
                while (isspace((unsigned char)*q)) {
                    q++;
                }
                if (*q == '(') {
                    strcpy(func_name, name);
                    return 1;
                }
            }
        }
    }
    func_name[0] = '\0';
    return 0;
}

static int rhs_has_function_call(const char *rhs)
{
    size_t i;
    for (i = 0; rhs[i] != '\0'; i++) {
        char name[NAME_MAX_LEN];
        const char *end;
        const char *q;
        if (!is_ident_start((unsigned char)rhs[i])) {
            continue;
        }
        end = read_name(rhs + i, name);
        if (strcmp(name, "sizeof") == 0 || strcmp(name, "new") == 0 ||
            strcmp(name, "clone") == 0 || strcmp(name, "move") == 0) {
            i = (size_t)(end - rhs);
            continue;
        }
        q = end;
        while (isspace((unsigned char)*q)) {
            q++;
        }
        if (*q == '(') {
            return 1;
        }
        i = (size_t)(end - rhs);
    }
    return 0;
}

static const char *scan_balanced_brace_end(const char *s)
{
    const char *p = s;
    int depth = 0;

    if (*p != '{') {
        return NULL;
    }
    while (*p != '\0') {
        if (*p == '"') {
            p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p == '"') {
                    break;
                }
                p++;
            }
        } else if (*p == '\'') {
            p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p == '\'') {
                    break;
                }
                p++;
            }
        } else if (*p == '{') {
            depth++;
        } else if (*p == '}') {
            depth--;
            if (depth == 0) {
                return p + 1;
            }
        }
        if (*p == '\0') {
            break;
        }
        p++;
    }
    return NULL;
}

static int parse_new_expr(const char *rhs, const char **new_start, const char **new_end,
                          struct Type *type, struct Text *sizeof_type,
                          const char **init_start, const char **init_end)
{
    const char *p = skip_ws(rhs);
    const char *type_start;
    const char *base_end;
    const char *end;
    const char *brace_end;
    struct Type base;
    int ptr = 0;

    if (!starts_word(p, "new")) {
        return 0;
    }
    type_start = skip_ws(p + 3);
    if (!parse_new_type_prefix(type_start, &base_end, &base)) {
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

    {
        struct Type alloc_type = base;
        alloc_type.ptr += ptr;
        append_c_type(sizeof_type, alloc_type);
    }

    if (new_start != NULL) {
        *new_start = p;
    }
    if (new_end != NULL) {
        *new_end = end;
    }
    if (init_start != NULL) {
        *init_start = NULL;
    }
    if (init_end != NULL) {
        *init_end = NULL;
    }

    brace_end = scan_balanced_brace_end(skip_ws(end));
    if (brace_end != NULL) {
        if (new_end != NULL) {
            *new_end = brace_end;
        }
        if (init_start != NULL) {
            *init_start = skip_ws(end);
        }
        if (init_end != NULL) {
            *init_end = brace_end;
        }
    }
    return 1;
}

static int rhs_has_new_expr(const char *rhs, struct Type *type)
{
    struct Text *sizeof_type = text_new();
    int ok = parse_new_expr(rhs, NULL, NULL, type, sizeof_type, NULL, NULL);

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

static const char *scan_object_init_value_end(const char *s, const char *limit)
{
    const char *p = s;
    int paren = 0;
    int bracket = 0;
    int brace = 0;

    while (p < limit) {
        if (*p == '"') {
            p++;
            while (p < limit) {
                if (*p == '\\' && p + 1 < limit) {
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
            while (p < limit) {
                if (*p == '\\' && p + 1 < limit) {
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
        } else if (*p == ')' && paren > 0) {
            paren--;
        } else if (*p == '[') {
            bracket++;
        } else if (*p == ']' && bracket > 0) {
            bracket--;
        } else if (*p == '{') {
            brace++;
        } else if (*p == '}' && brace > 0) {
            brace--;
        } else if (*p == ',' && paren == 0 && bracket == 0 && brace == 0) {
            break;
        }
        p++;
    }
    while (p > s && isspace((unsigned char)p[-1])) {
        p--;
    }
    return p;
}

static void append_object_initializer_assignments(struct Text *out, const char *tmp,
                                                  struct Type type,
                                                  const char *init_start,
                                                  const char *init_end)
{
    const char *p = skip_ws(init_start + 1);
    const char *limit = init_end - 1;
    struct Type base = type;

    if (base.ptr > 0) {
        base.ptr--;
    }
    if (base.kind != TY_STRUCT) {
        fprintf(stderr, "c-: type error: object initializer requires a struct new expression\n");
        exit(1);
    }
    while (p < limit) {
        char field[NAME_MAX_LEN];
        const char *field_end;
        const char *colon;
        const char *value_start;
        const char *value_end;
        struct Type field_type;
        struct Type value_type;
        char *value;

        p = skip_ws(p);
        if (p >= limit) {
            break;
        }
        if (!is_ident_start((unsigned char)*p)) {
            fprintf(stderr, "c-: parse error: expected field name in object initializer\n");
            exit(1);
        }
        field_end = read_name(p, field);
        colon = skip_ws(field_end);
        if (*colon != ':') {
            fprintf(stderr, "c-: parse error: expected ':' in object initializer\n");
            exit(1);
        }
        if (!struct_field_type(base.tag, field, &field_type)) {
            fprintf(stderr, "c-: type error: unknown field '%s' in struct %s initializer\n", field, base.tag);
            exit(1);
        }
        value_start = skip_ws(colon + 1);
        value_end = scan_object_init_value_end(value_start, limit);
        if (value_end <= value_start) {
            fprintf(stderr, "c-: parse error: expected field value in object initializer\n");
            exit(1);
        }
        value = xstrndup(value_start, (size_t)(value_end - value_start));
        value_type = expr_type(value);
        check_assignment_type(field, field_type, value_type);
        text_add(out, tmp);
        text_add(out, "->");
        text_add(out, field);
        text_add(out, " = ");
        text_add_n(out, value_start, (size_t)(value_end - value_start));
        text_add(out, "; ");
        free(value);
        p = skip_ws(value_end);
        if (*p == ',') {
            p++;
        } else if (p < limit) {
            fprintf(stderr, "c-: parse error: expected ',' in object initializer\n");
            exit(1);
        }
    }
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
    const char *init_start;
    const char *init_end;
    const char *p;
    struct Type type;
    struct Text *sizeof_type = text_new();
    struct Text *out;

    new_start = NULL;
    new_end = NULL;
    init_start = NULL;
    init_end = NULL;
    for (p = in->text; *p != '\0'; p++) {
        if ((p == in->text || !is_ident((unsigned char)p[-1])) && starts_word(p, "new") &&
            parse_new_expr(p, &new_start, &new_end, &type, sizeof_type, &init_start, &init_end)) {
            break;
        }
    }
    if (new_start == NULL) {
        text_free(sizeof_type);
        return in;
    }

    out = text_new();
    text_add_n(out, in->text, (size_t)(new_start - in->text));
    if (init_start != NULL && init_end != NULL) {
        char tmp[NAME_MAX_LEN];

        snprintf(tmp, sizeof(tmp), "__right_value%d", g_right_value_id++);
        text_add(out, "({ ");
        append_c_type(out, type);
        text_add(out, " ");
        text_add(out, tmp);
        text_add(out, " = calloc(1, sizeof(");
        text_add(out, sizeof_type->text);
        text_add(out, ")); ");
        text_add(out, "if (");
        text_add(out, tmp);
        text_add(out, " != NULL) { ");
        append_object_initializer_assignments(out, tmp, type, init_start, init_end);
        text_add(out, "} ");
        text_add(out, tmp);
        text_add(out, "; })");
    } else {
        text_add(out, "calloc(1, sizeof(");
        text_add(out, sizeof_type->text);
        text_add(out, "))");
    }
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
        fprintf(stderr, "c-: invalid s string literal\n");
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
        fprintf(stderr, "c-: invalid s string literal\n");
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
    char generic_func[NAME_MAX_LEN];
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
    if (*dot != '.' && !(dot[0] == '-' && dot[1] == '>')) {
        return 0;
    }
    method_start = skip_ws(*dot == '.' ? dot + 1 : dot + 2);
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

    if (generic_method_concrete_name(sym->type.tag, method, generic_func, sizeof(generic_func))) {
        text_add(replacement, generic_func);
    } else {
        text_add(replacement, sym->type.tag);
        text_add_ch(replacement, '_');
        text_add(replacement, method);
    }
    text_add_ch(replacement, '(');
    if (*dot == '-' || sym->type.ptr > 0) {
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

static int collection_index_call(const char *name,
                                 const char *index_start,
                                 const char *index_end,
                                 struct Text *replacement)
{
    struct Symbol *sym = symbol_find(name);
    struct GenericInstance *struct_inst = NULL;
    struct GenericTemplate *struct_tmpl;
    struct GenericTemplate *func_tmpl;
    struct GenericInstance *func_inst;
    struct PayloadEnum *option_en;
    struct GenericInstance *option_inst;
    char func_name[NAME_MAX_LEN];
    char tmp[128];
    int id;

    if (sym == NULL || sym->type.kind != TY_STRUCT) {
        return 0;
    }
    struct_tmpl = generic_struct_find_by_concrete(sym->type.tag, &struct_inst);
    if (struct_tmpl == NULL || struct_inst == NULL) {
        return 0;
    }
    if (strcmp(struct_tmpl->name, "Vec") != 0 &&
        strcmp(struct_tmpl->name, "List") != 0 &&
        strcmp(struct_tmpl->name, "OwnedVec") != 0 &&
        strcmp(struct_tmpl->name, "OwnedList") != 0) {
        return 0;
    }
    option_en = payload_enum_find("__CMinusIndex");
    if (option_en == NULL) {
        return 0;
    }
    option_inst = payload_enum_instance_get(option_en, struct_inst->arg);
    if (strlen(struct_tmpl->name) + 9 >= sizeof(func_name)) {
        return 0;
    }
    strcpy(func_name, struct_tmpl->name);
    strcat(func_name, "_get_opt");
    func_tmpl = generic_find(&g_generic_funcs, func_name);
    if (func_tmpl == NULL) {
        return 0;
    }
    func_inst = generic_instance_get(func_tmpl, struct_inst->arg);
    id = g_index_id++;

    snprintf(tmp, sizeof(tmp), "({ struct %s __index_result%d = ", option_inst->concrete, id);
    text_add(replacement, tmp);
    text_add(replacement, func_inst->concrete);
    text_add_ch(replacement, '(');
    if (sym->type.ptr > 0) {
        text_add(replacement, name);
    } else {
        text_add_ch(replacement, '&');
        text_add(replacement, name);
    }
    text_add(replacement, ", ");
    text_add_n(replacement, index_start, (size_t)(index_end - index_start));
    snprintf(tmp, sizeof(tmp), "); if (__index_result%d.tag == ", id);
    text_add(replacement, tmp);
    text_add(replacement, option_inst->concrete);
    text_add(replacement, "_TAG_None) { cminus_panic(\"index out of range\", \"");
    text_add(replacement, g_input_path == NULL ? "<unknown>" : g_input_path);
    snprintf(tmp, sizeof(tmp), "\", %d); } ", yylineno);
    text_add(replacement, tmp);
    snprintf(tmp, sizeof(tmp), "__index_result%d.payload.Some; })", id);
    text_add(replacement, tmp);
    return 1;
}

static struct Text *rewrite_index_access(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    while (*p != '\0') {
        char name[NAME_MAX_LEN];
        const char *name_end;
        const char *open;
        const char *close;
        struct Text *replacement;

        if (!is_ident_start((unsigned char)*p)) {
            text_add_ch(out, *p++);
            continue;
        }
        name_end = read_name(p, name);
        open = skip_ws(name_end);
        if (*open != '[') {
            text_add_n(out, p, (size_t)(name_end - p));
            p = name_end;
            continue;
        }
        close = open + 1;
        {
            int depth = 1;
            while (*close != '\0') {
                if (*close == '[') {
                    depth++;
                } else if (*close == ']') {
                    depth--;
                    if (depth == 0) {
                        break;
                    }
                }
                close++;
            }
            if (*close != ']') {
                text_add_n(out, p, (size_t)(name_end - p));
                p = name_end;
                continue;
            }
        }
        replacement = text_new();
        if (collection_index_call(name, open + 1, close, replacement)) {
            text_add(out, replacement->text);
            p = close + 1;
            changed = 1;
        } else {
            text_add_n(out, p, (size_t)(close + 1 - p));
            p = close + 1;
        }
        text_free(replacement);
    }

    if (!changed) {
        text_free(out);
        return in;
    }
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(in);
    return out;
}

static int parse_labeled_arg(const char *start, const char *end, char *label,
                             const char **value_start, const char **value_end)
{
    const char *p = skip_ws(start);
    const char *name_end;
    const char *colon;

    label[0] = '\0';
    if (!is_ident_start((unsigned char)*p)) {
        return 0;
    }
    name_end = read_name(p, label);
    colon = skip_ws(name_end);
    if (colon >= end || *colon != ':') {
        label[0] = '\0';
        return 0;
    }
    *value_start = skip_ws(colon + 1);
    *value_end = end;
    while (*value_end > *value_start && isspace((unsigned char)(*value_end)[-1])) {
        (*value_end)--;
    }
    return 1;
}

static int param_index(struct FunctionParams *fn, const char *name)
{
    int i;
    for (i = 0; i < fn->count; i++) {
        if (strcmp(fn->param[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

static struct Text *build_parameter_call(struct FunctionParams *fn, const char *args_start, const char *args_end)
{
    struct Text *values[MAX_PARAMS];
    struct Text *out = text_new();
    const char *p = args_start;
    int positional = 0;
    int i;

    for (i = 0; i < MAX_PARAMS; i++) {
        values[i] = NULL;
    }
    while (p < args_end) {
        const char *arg_end = find_top_level_char(p, args_end, ',');
        const char *value_start;
        const char *value_end;
        char label[NAME_MAX_LEN];
        int index;

        if (arg_end == NULL) {
            arg_end = args_end;
        }
        while (p < arg_end && isspace((unsigned char)*p)) {
            p++;
        }
        value_end = arg_end;
        while (value_end > p && isspace((unsigned char)value_end[-1])) {
            value_end--;
        }
        if (value_end > p) {
            if (parse_labeled_arg(p, value_end, label, &value_start, &value_end)) {
                index = param_index(fn, label);
                if (index < 0) {
                    fprintf(stderr, "c-: unknown parameter label '%s' for function '%s'\n", label, fn->name);
                    exit(1);
                }
            } else {
                while (positional < fn->count && values[positional] != NULL) {
                    positional++;
                }
                index = positional++;
                value_start = p;
            }
            if (index >= fn->count) {
                fprintf(stderr, "c-: too many arguments for function '%s'\n", fn->name);
                exit(1);
            }
            if (values[index] != NULL) {
                fprintf(stderr, "c-: duplicate argument for parameter '%s'\n", fn->param[index].name);
                exit(1);
            }
            values[index] = text_new();
            text_add_n(values[index], value_start, (size_t)(value_end - value_start));
        }
        p = arg_end;
        if (p < args_end && *p == ',') {
            p++;
        }
    }
    for (i = 0; i < fn->count; i++) {
        if (i > 0) {
            text_add(out, ", ");
        }
        if (values[i] != NULL) {
            text_add(out, values[i]->text);
        } else if (fn->param[i].def[0] != '\0') {
            text_add(out, fn->param[i].def);
        } else {
            fprintf(stderr, "c-: missing argument for parameter '%s' in function '%s'\n",
                    fn->param[i].name, fn->name);
            exit(1);
        }
    }
    for (i = 0; i < fn->count; i++) {
        if (values[i] != NULL) {
            text_free(values[i]);
        }
    }
    return out;
}

static struct Text *rewrite_parameter_calls(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    while (*p != '\0') {
        if (is_ident_start((unsigned char)*p) && (p == in->text || !is_ident((unsigned char)p[-1]))) {
            char name[NAME_MAX_LEN];
            const char *name_end = read_name(p, name);
            const char *open = skip_ws(name_end);
            struct FunctionParams *fn = function_params_find(name);

            if (fn != NULL && *open == '(') {
                const char *close = find_matching_paren(open);
                if (close != NULL) {
                    struct Text *args = build_parameter_call(fn, open + 1, close);
                    text_add(out, name);
                    text_add_ch(out, '(');
                    text_add(out, args->text);
                    text_add_ch(out, ')');
                    text_free(args);
                    p = close + 1;
                    changed = 1;
                    continue;
                }
            }
        }
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
    const char *p;

    if (g_current_generic_kind != 0 || g_current_payload_enum) {
        return head;
    }
    head = rewrite_foreach_head(head);
    p = skip_ws(head->text);
    if (starts_word(p, "if") || starts_word(p, "else")) {
        kind = ND_IF;
    } else if (starts_word(p, "while")) {
        kind = ND_WHILE;
    } else if (starts_word(p, "do")) {
        kind = ND_DO;
    }
    check_owned_pointer_arithmetic(head->text);
    head = rewrite_generics(head);
    head = rewrite_method_calls(head);
    head = rewrite_index_access(head);
    head = rewrite_parameter_calls(head);
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
        if (in->text[i] == '"' || in->text[i] == '\'') {
            char quote = in->text[i++];
            text_add_ch(out, quote);
            while (i < in->len) {
                text_add_ch(out, in->text[i]);
                if (in->text[i] == '\\' && i + 1 < in->len) {
                    i++;
                    text_add_ch(out, in->text[i]);
                } else if (in->text[i] == quote) {
                    break;
                }
                i++;
            }
            continue;
        }
        if ((strncmp(in->text + i, "borrow", 6) == 0 &&
             (i == 0 || !is_ident((unsigned char)in->text[i - 1])) &&
             !is_ident((unsigned char)in->text[i + 6])) ||
            (strncmp(in->text + i, "owned", 5) == 0 &&
             (i == 0 || !is_ident((unsigned char)in->text[i - 1])) &&
             !is_ident((unsigned char)in->text[i + 5])) ||
            (strncmp(in->text + i, "move", 4) == 0 &&
             (i == 0 || !is_ident((unsigned char)in->text[i - 1])) &&
             !is_ident((unsigned char)in->text[i + 4]))) {
            size_t n = in->text[i] == 'b' ? 6 : (in->text[i] == 'o' ? 5 : 4);
            i += n;
            while (i < in->len && isspace((unsigned char)in->text[i])) {
                i++;
            }
            if (i < in->len) {
                i--;
            }
            continue;
        }
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
    char delete_func[NAME_MAX_LEN];

    text_add(out, indent);
    text_add(out, "if (");
    text_add(out, expr);
    text_add(out, " != NULL) {\n");
    text_add(inner, indent);
    text_add(inner, "    ");
    append_finalize_for_type(out, inner->text, expr, type);
    if (type.kind == TY_STRUCT && type.ptr > 0 &&
        generic_method_concrete_name(type.tag, "delete", delete_func, sizeof(delete_func))) {
        text_add(out, inner->text);
        text_add(out, delete_func);
        text_add_ch(out, '(');
        text_add(out, expr);
        text_add(out, ");\n");
    }
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
                    fprintf(stderr, "c-: type error: pointer arithmetic is forbidden for owned pointer '%s'\n", name);
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

    if (is_uniq_decl(all->text)) {
        if (!g_emit_uniq) {
            return uniq_extern_decl(all);
        }
        all = strip_uniq(all);
    }
    register_tags_in_text(all->text);
    if (!is_generic_decl_head(all->text)) {
        all = rewrite_generics(all);
    }
    is_func_sig = parse_function_signature(all->text, func_name, &ret);
    if (is_func_sig) {
        register_function_params(all->text);
        register_owned_function_signature(all->text);
    }
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
    if (is_func_sig) {
        all = strip_default_parameters(all);
    }
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
    int is_borrowed = 0;
    char moved_name[NAME_MAX_LEN];

    post_free_name[0] = '\0';
    owned_name[0] = '\0';
    func_name[0] = '\0';
    lhs_name[0] = '\0';
    moved_name[0] = '\0';
    post_free_type = type_unknown();
    owned_assign_type = type_unknown();
    new_type = type_unknown();
    if (g_current_generic_kind != 0 || g_current_payload_enum) {
        all->tail_return = 0;
        all->ast = ast_raw(ND_RAW, all->text);
        return all;
    }
    all = try_rewrite_auto_payload_enum_decl(all);
    register_tags_in_text(all->text);
    all = rewrite_generics(all);
    all = rewrite_payload_enum_constructors(all);
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
    if (text_has_word(all->text, "move")) {
        g_function_returns_move = 1;
        if (g_current_function_name[0] != '\0' && g_current_function_ret.ptr > 0) {
            struct Type ret_type = g_current_function_ret;
            ret_type.owned = 1;
            owned_func_add_type(g_current_function_name, ret_type);
        }
    }
    remove_moved_locals(all->text);

    if (parse_decl(all->text, &decl) && decl.is_decl && decl.name[0] != '\0' && !decl.is_function) {
        is_borrowed = decl_has_borrow(all->text);
        if (decl.has_init) {
            rhs_type = expr_type(decl.init);
            if (extract_move_name(decl.init, moved_name)) {
                if (decl.type.ptr <= 0) {
                    fprintf(stderr, "c-: type error: move result requires a pointer declaration for '%s'\n", decl.name);
                    text_free(all);
                    exit(1);
                }
                if (is_borrowed) {
                    fprintf(stderr, "c-: type error: borrow declaration cannot take ownership with move for '%s'\n", decl.name);
                    text_free(all);
                    exit(1);
                }
                decl.type.owned = 1;
                owned_add(decl.name, decl.type);
            } else if (rhs_has_s_string(decl.init)) {
                struct Text *out;
                struct Text *call;
                if (decl.type.ptr <= 0 || decl.type.kind != TY_CHAR) {
                    fprintf(stderr, "c-: type error: s string requires a char pointer declaration for '%s'\n", decl.name);
                    text_free(all);
                    exit(1);
                }
                if (is_borrowed) {
                    fprintf(stderr, "c-: type error: borrow declaration cannot take ownership of s string for '%s'\n", decl.name);
                    text_free(all);
                    exit(1);
                }
                decl.type.owned = 1;
                owned_add(decl.name, decl.type);
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
                        fprintf(stderr, "c-: type error: clone result requires a pointer declaration for '%s'\n", decl.name);
                        text_free(all);
                        exit(1);
                    }
                    if (is_borrowed) {
                        fprintf(stderr, "c-: type error: borrow declaration cannot take ownership of clone result for '%s'\n", decl.name);
                        text_free(all);
                        exit(1);
                    }
                    decl.type.owned = 1;
                    owned_add(decl.name, decl.type);
                }
            } else if (rhs_has_malloc_call(decl.init, func_name) || rhs_has_new_expr(decl.init, &new_type)) {
                if (decl.type.ptr <= 0) {
                    if (func_name[0] != '\0') {
                        fprintf(stderr, "c-: type error: malloc result requires a pointer declaration for '%s'\n", decl.name);
                    } else {
                        fprintf(stderr, "c-: type error: new result requires a pointer declaration for '%s'\n", decl.name);
                    }
                    text_free(all);
                    exit(1);
                }
                if (is_borrowed) {
                    if (func_name[0] != '\0') {
                        fprintf(stderr, "c-: type error: borrow declaration cannot take ownership of malloc result for '%s'\n", decl.name);
                    } else {
                        fprintf(stderr, "c-: type error: borrow declaration cannot take ownership of new result for '%s'\n", decl.name);
                    }
                    text_free(all);
                    exit(1);
                }
                decl.type.owned = 1;
                owned_add(decl.name, decl.type);
            } else if (!is_borrowed && decl.type.ptr > 0 && rhs_has_function_call(decl.init)) {
                decl.type.owned = 1;
                owned_add(decl.name, decl.type);
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
        all = rewrite_parameter_calls(all);
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

    if (eq >= 0 && extract_move_name(all->text + eq + 1, moved_name)) {
        if (!extract_lhs_name(all->text, eq, lhs_name)) {
            fprintf(stderr, "c-: result of move must be assigned to a pointer lvalue\n");
            text_free(all);
            exit(1);
        }
        lhs = symbol_find(lhs_name);
        lhs_type = lhs_type_before_eq(all->text, eq, lhs_name);
        if (!type_is_known(lhs_type) || lhs_type.ptr <= 0) {
            fprintf(stderr, "c-: type error: move result requires a pointer lvalue for '%s'\n", lhs_name);
            text_free(all);
            exit(1);
        }
        if (lhs != NULL) {
            int was_owned = lhs->type.owned;
            lhs->type.owned = 1;
            strcpy(owned_name, lhs_name);
            owned_assign = was_owned;
            owned_assign_type = lhs->type;
            if (owned_assign) {
                owned_assign_lhs = slice_lhs_expr(all->text, eq);
            }
        }
    } else if (eq >= 0 && rhs_has_s_string(all->text + eq + 1)) {
        if (!extract_lhs_name(all->text, eq, lhs_name) || !lhs_is_plain_name(all->text, eq, lhs_name)) {
            fprintf(stderr, "c-: type error: s string requires a plain char pointer lvalue\n");
            text_free(all);
            exit(1);
        }
        lhs = symbol_find(lhs_name);
        lhs_type = lhs_type_before_eq(all->text, eq, lhs_name);
        rhs_type = expr_type(all->text + eq + 1);
        if (lhs == NULL || lhs_type.ptr <= 0 || lhs_type.kind != TY_CHAR) {
            fprintf(stderr, "c-: type error: s string requires a char pointer lvalue for '%s'\n", lhs_name);
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
                fprintf(stderr, "c-: type error: clone result requires a pointer declaration for '%s'\n", owned_name);
                text_free(all);
                exit(1);
            }
            lhs_type = lhs != NULL ? lhs->type : type_unknown();
        } else if (extract_lhs_name(all->text, eq, lhs_name)) {
            lhs = symbol_find(lhs_name);
            lhs_type = lhs_type_before_eq(all->text, eq, lhs_name);
            if (new_type.ptr > 0 && (!type_is_known(lhs_type) || lhs_type.ptr <= 0)) {
                fprintf(stderr, "c-: type error: clone result requires a pointer lvalue for '%s'\n", lhs_name);
                text_free(all);
                exit(1);
            }
            check_assignment_type(lhs_name, lhs_type, rhs_type);
            if (new_type.ptr > 0) {
                if (lhs != NULL) {
                    int was_owned = lhs->type.owned;
                    lhs->type.owned = 1;
                    strcpy(owned_name, lhs_name);
                    owned_assign = was_owned;
                    owned_assign_type = lhs->type;
                    if (owned_assign) {
                        owned_assign_lhs = slice_lhs_expr(all->text, eq);
                    }
                } else if (lhs_type.owned) {
                    owned_assign = 1;
                    owned_assign_type = lhs_type;
                    owned_assign_lhs = slice_lhs_expr(all->text, eq);
                } else {
                    fprintf(stderr, "c-: type error: clone result requires an owned pointer lvalue for '%s'\n", lhs_name);
                    text_free(all);
                    exit(1);
                }
            }
        } else {
            fprintf(stderr, "c-: result of clone must be assigned to a matching declaration\n");
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
                fprintf(stderr, "c-: type error: malloc result requires a pointer declaration for '%s'\n", owned_name);
                text_free(all);
                exit(1);
            }
            lhs_type = lhs != NULL ? lhs->type : type_unknown();
        } else if (extract_lhs_name(all->text, eq, lhs_name)) {
            lhs = symbol_find(lhs_name);
            lhs_type = lhs_type_before_eq(all->text, eq, lhs_name);
            rhs_type = expr_type(all->text + eq + 1);
            if (!type_is_known(lhs_type) || lhs_type.ptr <= 0) {
                fprintf(stderr, "c-: type error: malloc result requires a pointer lvalue for '%s'\n", lhs_name);
                text_free(all);
                exit(1);
            }
            check_assignment_type(lhs_name, lhs_type, rhs_type);
            if (lhs != NULL) {
                int was_owned = lhs->type.owned;
                lhs->type.owned = 1;
                strcpy(owned_name, lhs_name);
                owned_assign = was_owned;
                owned_assign_type = lhs->type;
                if (owned_assign) {
                    owned_assign_lhs = slice_lhs_expr(all->text, eq);
                }
            } else if (lhs_type.owned) {
                owned_assign = 1;
                owned_assign_type = lhs_type;
                owned_assign_lhs = slice_lhs_expr(all->text, eq);
            } else {
                if (func_name[0] != '\0') {
                    fprintf(stderr, "c-: type error: malloc result requires an owned pointer lvalue for '%s'\n", lhs_name);
                } else {
                    fprintf(stderr, "c-: type error: new result requires an owned pointer lvalue for '%s'\n", lhs_name);
                }
                text_free(all);
                exit(1);
            }
        } else {
            if (func_name[0] != '\0') {
                fprintf(stderr, "c-: result of owned function '%s' must be assigned to a pointer declaration\n", func_name);
            } else {
                fprintf(stderr, "c-: result of new must be assigned to a pointer declaration\n");
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
    all = rewrite_payload_enum_constructors(all);
    all = rewrite_method_calls(all);
    all = rewrite_index_access(all);
    all = rewrite_parameter_calls(all);
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
    if (g_current_generic_kind != 0 || g_current_payload_enum) {
        all->tail_return = 1;
        return all;
    }
    check_owned_pointer_arithmetic(all->text);
    remove_moved_locals(all->text);
    all = rewrite_generics(all);
    all = rewrite_method_calls(all);
    all = rewrite_index_access(all);
    all = rewrite_parameter_calls(all);
    all = remove_percent(strip_attributes(all));
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
    char param[NAME_MAX_LEN];
    struct Type ret;

    if (g_current_payload_enum) {
        if (!parse_payload_enum_head(head->text, param, name)) {
            die("invalid payload enum");
        }
        payload_enum_add(param, name, body->text);
        out = text_new();
        g_current_payload_enum = 0;
        g_top_block_is_function = 0;
        g_in_aggregate_struct = 0;
        g_current_struct_tag[0] = '\0';
        g_skip_next_semi = 1;
        text_free(head);
        text_free(lb);
        text_free(body);
        text_free(rb);
        return out;
    }
    if (g_current_generic_kind == 1) {
        if (!parse_generic_struct_head(head->text, param, name)) {
            die("invalid generic struct");
        }
        generic_add(&g_generic_structs, param, name, head->text, body->text);
        out = text_new();
        g_current_generic_kind = 0;
        g_top_block_is_function = 0;
        g_in_aggregate_struct = 0;
        g_current_struct_tag[0] = '\0';
        g_skip_next_semi = 1;
        text_free(head);
        text_free(lb);
        text_free(body);
        text_free(rb);
        return out;
    }
    if (g_current_generic_kind == 2) {
        if (!parse_generic_function_head(head->text, param, name)) {
            die("invalid generic function");
        }
        generic_add(&g_generic_funcs, param, name, head->text, body->text);
        out = text_new();
        g_current_generic_kind = 0;
        g_in_function = 0;
        text_free(head);
        text_free(lb);
        text_free(body);
        text_free(rb);
        return out;
    }

    if (is_uniq_decl(head->text)) {
        if (!g_emit_uniq) {
            out = uniq_extern_decl(head);
            g_top_block_is_function = 0;
            g_in_function = 0;
            g_owned.count = 0;
            g_finalized_locals.count = 0;
            g_locals.count = 0;
            text_free(lb);
            text_free(body);
            text_free(rb);
            return out;
        }
        head = strip_uniq(head);
    }

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

    register_function_params(head->text);
    register_owned_function_signature(head->text);
    if (g_function_returns_move && parse_function_signature(head->text, name, &ret) && ret.ptr > 0) {
        ret.owned = 1;
        owned_func_add_type(name, ret);
    }
    head = strip_default_parameters(head);
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
    g_function_returns_move = 0;
    g_current_function_name[0] = '\0';
    g_current_function_ret = type_unknown();
    g_in_function = 0;
    return out;
}

static const char *generic_template_body_start(const char *head, char *param)
{
    const char *p = parse_generic_prefix(head, param);

    return p == NULL ? head : p;
}

static void fputs_with_trailing_newline(const char *s, FILE *out)
{
    fputs(s, out);
    if (s[0] != '\0' && s[strlen(s) - 1] != '\n') {
        fputc('\n', out);
    }
}

static void emit_generic_struct_instances(FILE *out)
{
    int i;
    int j;

    for (i = 0; i < g_generic_structs.count; i++) {
        struct GenericTemplate *tmpl = &g_generic_structs.tmpl[i];
        for (j = 0; j < tmpl->inst_count; j++) {
            char param[NAME_MAX_LEN];
            const char *head = generic_template_body_start(tmpl->head, param);
            struct Text *concrete_head;
            struct Text *concrete_body;
            if (strcmp(tmpl->inst[j].arg, tmpl->param) == 0) {
                continue;
            }
            concrete_head = replace_param_and_generics(head,
                                                       tmpl->param,
                                                       tmpl->inst[j].arg,
                                                       tmpl->name,
                                                       tmpl->inst[j].concrete);
            concrete_body = replace_param_and_generics(tmpl->body,
                                                                    tmpl->param,
                                                                    tmpl->inst[j].arg,
                                                                    tmpl->name,
                                                                    tmpl->inst[j].concrete);
            concrete_head = remove_percent(strip_attributes(concrete_head));
            concrete_body = remove_percent(strip_attributes(concrete_body));
            fputs(concrete_head->text, out);
            fputs("{", out);
            fputs_with_trailing_newline(concrete_body->text, out);
            fputs("};\n", out);
            text_free(concrete_head);
            text_free(concrete_body);
        }
    }
}

static void emit_generic_function_instances(FILE *out)
{
    int i;

    for (i = 0; i < g_generic_funcs.count; i++) {
        struct GenericTemplate *tmpl = &g_generic_funcs.tmpl[i];
        int j;
        for (j = 0; j < tmpl->inst_count; j++) {
            char param[NAME_MAX_LEN];
            const char *head = generic_template_body_start(tmpl->head, param);
            struct Text *concrete_head = replace_param_and_generics(head,
                                                                    tmpl->param,
                                                                    tmpl->inst[j].arg,
                                                                    tmpl->name,
                                                                    tmpl->inst[j].concrete);
            struct Text *concrete_body = replace_param_and_generics(tmpl->body,
                                                                    tmpl->param,
                                                                    tmpl->inst[j].arg,
                                                                    tmpl->name,
                                                                    tmpl->inst[j].concrete);
            concrete_head = remove_percent(strip_attributes(concrete_head));
            concrete_body = remove_percent(strip_attributes(concrete_body));
            concrete_body = rewrite_payload_enum_constructors(concrete_body);
            fputs(concrete_head->text, out);
            fputs("{", out);
            fputs_with_trailing_newline(concrete_body->text, out);
            fputs("}\n", out);
            text_free(concrete_head);
            text_free(concrete_body);
        }
    }
}

static int total_generic_instance_count(void)
{
    int total = 0;
    int i;

    for (i = 0; i < g_generic_structs.count; i++) {
        total += g_generic_structs.tmpl[i].inst_count;
    }
    for (i = 0; i < g_generic_funcs.count; i++) {
        total += g_generic_funcs.tmpl[i].inst_count;
    }
    for (i = 0; i < g_payload_enums.count; i++) {
        total += g_payload_enums.en[i].inst_count;
    }
    return total;
}

/*
 * Materialize a generic template instance the same way the emit functions do,
 * discarding the generated text. The point is the side effect: expanding the
 * body runs it through rewrite_generics (and the payload-enum constructor
 * rewrite), which registers any further generic instances the body needs.
 */
static void materialize_generic_instance(struct GenericTemplate *tmpl, int j, int is_func)
{
    char param[NAME_MAX_LEN];
    const char *head = generic_template_body_start(tmpl->head, param);
    struct Text *concrete_head = replace_param_and_generics(head,
                                                            tmpl->param,
                                                            tmpl->inst[j].arg,
                                                            tmpl->name,
                                                            tmpl->inst[j].concrete);
    struct Text *concrete_body = replace_param_and_generics(tmpl->body,
                                                            tmpl->param,
                                                            tmpl->inst[j].arg,
                                                            tmpl->name,
                                                            tmpl->inst[j].concrete);

    concrete_head = remove_percent(strip_attributes(concrete_head));
    concrete_body = remove_percent(strip_attributes(concrete_body));
    if (is_func) {
        concrete_body = rewrite_payload_enum_constructors(concrete_body);
    }
    text_free(concrete_head);
    text_free(concrete_body);
}

/*
 * A generic body may reference other generic instances (for example
 * OwnedVec_delete<T> calls OwnedVec_clear<T>). Those nested instances are only
 * discovered while the body is expanded, so expand every known instance
 * repeatedly until no new instance appears. After this, emission sees the full
 * set regardless of template ordering.
 */
static void close_generic_instances(void)
{
    int prev = -1;
    int guard;

    for (guard = 0; guard < 1000 && total_generic_instance_count() != prev; guard++) {
        int i;
        int j;

        prev = total_generic_instance_count();
        for (i = 0; i < g_generic_funcs.count; i++) {
            struct GenericTemplate *tmpl = &g_generic_funcs.tmpl[i];
            for (j = 0; j < tmpl->inst_count; j++) {
                materialize_generic_instance(tmpl, j, 1);
            }
        }
        for (i = 0; i < g_generic_structs.count; i++) {
            struct GenericTemplate *tmpl = &g_generic_structs.tmpl[i];
            for (j = 0; j < tmpl->inst_count; j++) {
                if (strcmp(tmpl->inst[j].arg, tmpl->param) == 0) {
                    continue;
                }
                materialize_generic_instance(tmpl, j, 0);
            }
        }
    }
}

static void emit_generic_instances(FILE *out)
{
    emit_generic_struct_instances(out);
    emit_generic_function_instances(out);
}

static void emit_payload_enum_instances(FILE *out)
{
    int i;

    for (i = 0; i < g_payload_enums.count; i++) {
        struct PayloadEnum *en = &g_payload_enums.en[i];
        int j;

        for (j = 0; j < en->inst_count; j++) {
            struct GenericInstance *inst = &en->inst[j];
            int v;

            fputs("struct ", out);
            fputs(inst->concrete, out);
            fputs("{\n    int tag;\n    union {\n", out);
            for (v = 0; v < en->variant_count; v++) {
                if (en->variant[v].has_payload) {
                    struct Text *payload = replace_param_and_generics(en->variant[v].payload,
                                                                      en->param,
                                                                      inst->arg,
                                                                      en->name,
                                                                      inst->concrete);
                    payload = remove_percent(strip_attributes(payload));
                    fputs("        ", out);
                    fputs(payload->text, out);
                    fputc(' ', out);
                    fputs(en->variant[v].name, out);
                    fputs(";\n", out);
                    text_free(payload);
                }
            }
            fputs("    } payload;\n};\n", out);

            fputs("enum {\n", out);
            for (v = 0; v < en->variant_count; v++) {
                fputs("    ", out);
                fputs(inst->concrete, out);
                fputs("_TAG_", out);
                fputs(en->variant[v].name, out);
                fputs(v + 1 == en->variant_count ? "\n" : ",\n", out);
            }
            fputs("};\n", out);

            for (v = 0; v < en->variant_count; v++) {
                struct PayloadVariant *variant = &en->variant[v];

                fputs("static __attribute__((unused)) struct ", out);
                fputs(inst->concrete, out);
                fputc(' ', out);
                fputs(inst->concrete, out);
                fputc('_', out);
                fputs(variant->name, out);
                fputc('(', out);
                if (variant->has_payload) {
                    struct Text *payload = replace_param_and_generics(variant->payload,
                                                                      en->param,
                                                                      inst->arg,
                                                                      en->name,
                                                                      inst->concrete);
                    payload = remove_percent(strip_attributes(payload));
                    fputs(payload->text, out);
                    fputs(" value", out);
                    text_free(payload);
                } else {
                    fputs("void", out);
                }
                fputs(")\n{\n    struct ", out);
                fputs(inst->concrete, out);
                fputs(" out = {0};\n    out.tag = ", out);
                fputs(inst->concrete, out);
                fputs("_TAG_", out);
                fputs(variant->name, out);
                fputs(";\n", out);
                if (variant->has_payload) {
                    fputs("    out.payload.", out);
                    fputs(variant->name, out);
                    fputs(" = value;\n", out);
                }
                fputs("    return out;\n}\n", out);

                fputs("static __attribute__((unused)) int ", out);
                fputs(inst->concrete, out);
                fputs("_is_", out);
                fputs(variant->name, out);
                fputs("(struct ", out);
                fputs(inst->concrete, out);
                fputs("* self)\n{\n    return self->tag == ", out);
                fputs(inst->concrete, out);
                fputs("_TAG_", out);
                fputs(variant->name, out);
                fputs(";\n}\n", out);

                if (variant->has_payload) {
                    struct Text *payload = replace_param_and_generics(variant->payload,
                                                                      en->param,
                                                                      inst->arg,
                                                                      en->name,
                                                                      inst->concrete);
                    payload = remove_percent(strip_attributes(payload));
                    fputs("static __attribute__((unused)) ", out);
                    fputs(payload->text, out);
                    fputc(' ', out);
                    fputs(inst->concrete, out);
                    fputs("_get_", out);
                    fputs(variant->name, out);
                    fputs("(struct ", out);
                    fputs(inst->concrete, out);
                    fputs("* self)\n{\n    return self->payload.", out);
                    fputs(variant->name, out);
                    fputs(";\n}\n", out);
                    text_free(payload);
                }
            }
        }
    }
}

static int is_uniq_decl(const char *s)
{
    const char *p = skip_leading_space(s);

    return strncmp(p, "uniq", 4) == 0 && !is_ident((unsigned char)p[4]);
}

static struct Text *strip_uniq(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();

    while (isspace((unsigned char)*p)) {
        text_add_ch(out, *p++);
    }
    if (strncmp(p, "uniq", 4) == 0 && !is_ident((unsigned char)p[4])) {
        p += 4;
        while (*p == ' ' || *p == '\t') {
            p++;
        }
    }
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_add(out, p);
    text_free(in);
    return out;
}

static struct Text *uniq_extern_decl(struct Text *in)
{
    struct Text *stripped = strip_uniq(in);
    const char *s = skip_leading_space(stripped->text);
    const char *end = strchr(s, ';');
    const char *eq = strchr(s, '=');
    struct Text *out = text_new();

    append_leading_newlines(stripped->text, out);
    if (!starts_word(s, "extern")) {
        text_add(out, "extern ");
    }
    if (eq != NULL && (end == NULL || eq < end)) {
        text_add_n(out, s, (size_t)(eq - s));
    } else if (end != NULL) {
        text_add_n(out, s, (size_t)(end - s));
    } else {
        text_add(out, s);
    }
    while (out->len > 0 && isspace((unsigned char)out->text[out->len - 1])) {
        out->text[--out->len] = '\0';
    }
    text_add(out, ";\n");
    text_free(stripped);
    return out;
}

int main(int argc, char **argv)
{
    int rc;

    if (argc != 2) {
        fputs("usage: c- input.c- > output.c\n", stderr);
        return 2;
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        perror(argv[1]);
        return 1;
    }
    g_input_path = argv[1];
    yylineno = 1;
    g_output = text_new();
    g_defines = text_new();
    g_malloc_funcs.count = 0;
    g_right_value_id = 0;
    g_need_string_h = 0;
    g_need_stdlib_h = 0;
    g_need_stdio_h = 0;
    g_need_execinfo_h = 0;
    g_need_string_typedef = 0;
    {
        const char *emit_uniq = getenv("C_MINUS_EMIT_UNIQ");
        g_emit_uniq = emit_uniq == NULL || strcmp(emit_uniq, "0") != 0;
    }
    g_generic_structs.count = 0;
    g_generic_funcs.count = 0;
    g_payload_enums.count = 0;
    g_current_generic_kind = 0;
    g_current_payload_enum = 0;
    g_foreach_id = 0;
    g_index_id = 0;
    if (!source_has_cminus_include(yyin)) {
        FILE *stdlib_fp = open_cminus_include("c-.h");
        if (stdlib_fp == NULL) {
            fputs("c-: include not found: c-.h\n", stderr);
            fclose(yyin);
            return 1;
        }
        cminus_push_include(stdlib_fp);
    }

    rc = yyparse();
    if (rc != 0) {
        fclose(yyin);
        return 1;
    }
    {
        const char *p = g_output->text;
        fputs(g_defines->text, stdout);
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
        if (g_need_stdlib_h) {
            fputs("#include <stdlib.h>\n", stdout);
        }
        if (g_need_stdio_h) {
            fputs("#include <stdio.h>\n", stdout);
        }
        if (g_need_execinfo_h) {
            fputs("#include <execinfo.h>\n", stdout);
        }
        if (g_need_string_typedef) {
            fputs("typedef char* string;\n", stdout);
        }
        close_generic_instances();
        emit_payload_enum_instances(stdout);
        emit_generic_instances(stdout);
        fputs(p, stdout);
    }
    text_free(g_output);
    fclose(yyin);
    return 0;
}
