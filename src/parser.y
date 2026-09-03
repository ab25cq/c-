%{
#include <ctype.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern FILE *yyin;
extern int yylineno;

#define NAME_MAX_LEN 64
#define MAX_OWNED 128
#define MAX_FUNCS 512
#define MAX_SYMBOLS 256
#define MAX_TAGS 128
#define MAX_FINALIZERS 128
#define MAX_FIELDS 64
#define MAX_PARAMS 32
#define MAX_GENERIC_TEMPLATES 512
#define MAX_GENERIC_INSTANCES 512
#define MAX_ENUM_VARIANTS 64
#define DEFAULT_EXPR_MAX 256
#define MAX_SAFETY_LOWERINGS 256
#define MAX_SAFE_LOCAL_ARRAY_BYTES (64UL * 1024UL)

struct Text {
    char *text;
    size_t len;
    size_t cap;
    int tail_return;
    struct Node *ast;
};

enum TypeKind {
    TY_UNKNOWN,
    TY_GENERIC,
    TY_VOID,
    TY_CHAR,
    TY_SHORT,
    TY_INT,
    TY_LONG,
    TY_FLOAT,
    TY_DOUBLE,
    TY_STRUCT,
    TY_UNION,
    TY_ENUM,
    TY_BITFLAGS,
    TY_TYPEDEF,
    TY_FUNCTION,
    TY_TYPE_CONSTRUCTOR
};

struct Type {
    enum TypeKind kind;
    struct Type *base;
    int ptr;
    int owned;
    int raw_ptr;
    int is_array;
    int array_len;
    int size;
    int align;
    char tag[NAME_MAX_LEN];
    char applied_name[NAME_MAX_LEN];
    char applied_args[DEFAULT_EXPR_MAX];
};

struct Owned {
    char name[MAX_OWNED][NAME_MAX_LEN];
    struct Type type[MAX_OWNED];
    int count;
};

struct MovedLocals {
    char name[MAX_OWNED][NAME_MAX_LEN];
    int count;
};

struct BorrowLinks {
    char borrower[MAX_OWNED][NAME_MAX_LEN];
    char owner[MAX_OWNED][NAME_MAX_LEN];
    int dead[MAX_OWNED];
    int stack_owner[MAX_OWNED];
    int count;
};

struct PendingSemantics {
    int active;
    int is_return;
    int is_assignment;
    int owned;
    int borrowed;
    int stack_owner;
    int dead;
    char target[NAME_MAX_LEN];
    char owner[NAME_MAX_LEN];
    char move_source[NAME_MAX_LEN];
};

struct OwnedField {
    char name[NAME_MAX_LEN];
    struct Type type;
    int is_array;
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

struct BitflagDecl {
    char name[NAME_MAX_LEN];
    char base[NAME_MAX_LEN];
};

struct BitflagDecls {
    struct BitflagDecl flag[MAX_TAGS];
    int count;
};

struct LinkerSymbols {
    char name[MAX_TAGS][NAME_MAX_LEN];
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
    ND_FUNCDEF,
    ND_FUNCDECL,
    ND_PARAM,
    ND_RETURN_TYPE,
    ND_TYPEDEF,
    ND_TYPE_PARAM,
    ND_TYPE,
    ND_TYPE_ARGUMENT,
    ND_FIELD,
    ND_ARRAY_DIMENSION,
    ND_ENUM_MEMBER,
    ND_OWNERSHIP,
    ND_LIFETIME,
    ND_MOVE_TRANSFER,
    ND_IF,
    ND_WHILE,
    ND_FOR,
    ND_SWITCH,
    ND_DO,
    ND_GOTO,
    ND_BREAK,
    ND_CONTINUE,
    ND_STATIC_ASSERT,
    ND_LABEL,
    ND_CASE,
    ND_DEFAULT,
    ND_STRUCTDEF,
    ND_UNIONDEF,
    ND_ENUMDEF,
    ND_PP,
    ND_CLEANUP,
    ND_EXPANSION,
    ND_DIRECTIVE,
    ND_GENERIC_STRUCT,
    ND_GENERIC_PROTO,
    ND_GENERIC_FUNCTION,
    ND_GENERIC_STRUCT_TEMPLATE,
    ND_GENERIC_FUNCTION_TEMPLATE,
    ND_PAYLOAD_ENUM_TEMPLATE,
    ND_PAYLOAD_VARIANT,
    ND_BITFLAGSDEF,
    ND_BITFLAG_MEMBER,
    ND_UNSAFE,
    ND_INLINE_C,
    ND_RUNTIME_PRELUDE,
    ND_PAYLOAD_HELPERS,
    ND_DEFAULT_MACRO,
    ND_TRANSLATION_UNIT,
    ND_SOURCE_PREFIX,
    ND_SOURCE_BODY,
    ND_S_STRING,
    ND_RAW
};

struct SafetyExprNode;

struct Obj {
    struct Obj *next;
    char name[NAME_MAX_LEN];
    struct Type *ty;
    int is_local;
    int is_param;
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
    struct Node *params;
    struct Node *return_type;
    struct Node *type_params;
    struct Node *type_node;
    struct Node *type_args;
    struct Node *dimensions;
    struct Node *ownership;
    struct Node *lifetime;
    struct Node *move_transfer;
    struct Node *cond;
    struct Node *then;
    struct Node *els;
    struct Type *ty;
    struct Obj *var;
    struct SafetyExprNode *expr;
    struct SafetyExprNode *init_expr;
    struct SafetyExprNode *inc_expr;
    char name[NAME_MAX_LEN];
    char type_name[NAME_MAX_LEN];
    char *open_tok;
    char *body_tok;
    char *close_tok;
    char *tok;
    int stack_owner;
    int caller_owner;
    int dead;
    int runtime_checked;
    int array_len;
    long enum_value;
    int has_enum_value;
};

struct AggregateAst {
    char tag[NAME_MAX_LEN];
    struct Node *node;
};

struct AggregateAsts {
    struct AggregateAst item[MAX_GENERIC_TEMPLATES];
    int count;
};

enum SafetyExprKind {
    SAFETY_EXPR_IDENTIFIER,
    SAFETY_EXPR_LITERAL,
    SAFETY_EXPR_GROUP,
    SAFETY_EXPR_GENERIC,
    SAFETY_EXPR_MOVE,
    SAFETY_EXPR_UNARY,
    SAFETY_EXPR_UNARY_ADDRESS,
    SAFETY_EXPR_UNARY_DEREF,
    SAFETY_EXPR_CAST,
    SAFETY_EXPR_SIZEOF,
    SAFETY_EXPR_ALIGNOF,
    SAFETY_EXPR_STATEMENT,
    SAFETY_EXPR_INITIALIZER,
    SAFETY_EXPR_OFFSETOF,
    SAFETY_EXPR_CALL,
    SAFETY_EXPR_INDEX,
    SAFETY_EXPR_MEMBER,
    SAFETY_EXPR_BINARY,
    SAFETY_EXPR_UPDATE,
    SAFETY_EXPR_CONDITIONAL,
    SAFETY_EXPR_FIXED_INDEX,
    SAFETY_EXPR_RAW_DECAY,
    SAFETY_EXPR_UNSAFE_CALL
};

enum SafetyUnknownReason {
    SAFETY_UNKNOWN_NONE,
    SAFETY_UNKNOWN_UNCLASSIFIED,
    SAFETY_UNKNOWN_UNRESOLVED_SYMBOL,
    SAFETY_UNKNOWN_UNRESOLVED_CALL_RETURN,
    SAFETY_UNKNOWN_TARGET_SIZE,
    SAFETY_UNKNOWN_CONTEXTUAL_LITERAL,
    SAFETY_UNKNOWN_MEMBER_TYPE,
    SAFETY_UNKNOWN_SYMBOLIC_GENERIC,
    SAFETY_UNKNOWN_STATEMENT_RESULT,
    SAFETY_UNKNOWN_CONTEXTUAL_INITIALIZER,
    SAFETY_UNKNOWN_OPERAND_TYPE
};

struct SafetyExprNode {
    enum SafetyExprKind kind;
    struct Type type;
    struct Type function_return_type;
    char name[NAME_MAX_LEN];
    char type_name[NAME_MAX_LEN];
    char generic_arg[NAME_MAX_LEN];
    char op[8];
    const char *start;
    const char *end;
    struct SafetyExprNode *lhs;
    struct SafetyExprNode *rhs;
    struct SafetyExprNode *child;
    struct SafetyExprNode *next;
    long integer;
    int has_constant_integer;
    int postfix;
    int statement_result;
    int symbol_is_global;
    enum SafetyUnknownReason unknown_reason;
};

struct Funcs {
    char name[MAX_FUNCS][NAME_MAX_LEN];
    struct Type ret[MAX_FUNCS];
    int is_alloc_attr[MAX_FUNCS];
    int count;
};

struct ParamInfo {
    char name[NAME_MAX_LEN];
    char def[DEFAULT_EXPR_MAX];
    struct Type type;
    int borrowed;
    int owned;
};

struct FunctionParams {
    char name[NAME_MAX_LEN];
    struct Type ret;
    struct ParamInfo param[MAX_PARAMS];
    int count;
    int has_defaults;
    int is_unsafe;
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

struct TypedefAlias {
    char name[NAME_MAX_LEN];
    struct Type type;
};

struct TypedefAliases {
    struct TypedefAlias alias[MAX_SYMBOLS];
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
    int emitted;
};

struct GenericTemplate {
    char param[NAME_MAX_LEN];
    char name[NAME_MAX_LEN];
    char head[DEFAULT_EXPR_MAX * 2];
    char *body;
    struct Node *ast;
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
    struct Node *ast;
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
static struct Node *g_consumed_directives;
static struct Node *g_generated_artifacts;
static struct Node *g_template_nodes;
static struct Text *g_thread_owned_helpers;
static char g_thread_owned_entries[MAX_FUNCS][NAME_MAX_LEN];
static int g_thread_owned_entry_count;
static int g_thread_owned_helper_id;
static struct Owned g_owned;
static struct Owned g_finalized_locals;
static struct MovedLocals g_moved_locals;
static struct BorrowLinks g_borrow_links;
static struct PendingSemantics g_pending_semantics;
static struct AggregateAsts g_aggregate_asts;
static struct Funcs g_malloc_funcs;
static struct FunctionParamTable g_param_funcs;
static struct Symbols g_globals;
static struct Symbols g_locals;
static struct TypedefAliases g_typedefs;
static struct Tags g_tags;
static struct GenericTemplates g_generic_structs;
static struct GenericTemplates g_generic_funcs;
static struct PayloadEnums g_payload_enums;
static struct StructFinalizers g_struct_finalizers;
static struct StructClones g_struct_clones;
static struct BitflagDecls g_bitflags;
static struct LinkerSymbols g_linker_symbols;
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
static int g_current_generic_kind;
static char g_current_generic_param[NAME_MAX_LEN];
static int g_current_payload_enum;
static int g_foreach_id;
static int g_index_id;
static int g_need_stdio_h;
static int g_need_execinfo_h;
static int g_need_pthread_h;
static int g_need_sched_h;
static int g_unsafe_depth;
static int g_bare_metal;
static int g_no_heap;
static int g_c_compat;
static int g_emit_uniq;
static int g_function_returns_move;
static int g_current_function_interrupt;
static int g_current_function_naked;
static int g_current_bitflags;
static char g_current_bitflags_name[NAME_MAX_LEN];
static char g_current_bitflags_base[NAME_MAX_LEN];
static int g_current_struct_mmio;
static int g_dump_typed_ast;
static char g_current_function_name[NAME_MAX_LEN];
static struct Type g_current_function_ret;
static int g_current_function_stack_guard;
static const char *g_input_path;

int yylex(void);
void cminus_push_include(FILE *fp, int unsafe);
int cminus_include_depth(void);
void cminus_unsafe_push(void);
void cminus_unsafe_pop(void);
static void yyerror(const char *msg);

static void die(const char *msg);
static void *xmalloc(size_t size);
static struct Text *text_new(void);
static void text_add_n(struct Text *n, const char *p, size_t len);
static void text_add(struct Text *n, const char *p);
static void text_add_ch(struct Text *n, char c);
static struct Text *text_join(struct Text *a, struct Text *b);
static struct Text *text_join3(struct Text *a, struct Text *b, struct Text *c);
static void text_free(struct Text *n);
static struct Node *ast_new(enum NodeKind kind, const char *tok);
static struct Node *ast_append(struct Node *head, struct Node *node);
static struct Node *ast_raw(enum NodeKind kind, const char *tok);
static struct Node *ast_block(struct Node *body);
static struct Node *ast_function(const char *head, struct Node *body);
static struct Node *ast_function_declaration(const char *head);
static struct Node *ast_function_parameters(const char *name);
static struct Node *ast_return_type(struct Type type);
static struct Node *ast_type_parameters(const char *parameters);
static struct Node *ast_type_node(struct Type type);
static struct Node *ast_type_arguments(const char *arguments);
static struct Node *ast_enum_members(const char *body, struct Type enum_type);
static void aggregate_ast_add(const char *tag, struct Node *node);
static struct Node *aggregate_ast_find(const char *tag);
static void ast_attach_semantics(struct Node *node);
static struct Node *ast_control(const char *head, const char *open,
                                const char *body_text, const char *close,
                                struct Node *body);
static void validate_safe_typed_ast(const struct Node *node);
static void validate_safe_control_ast(const struct Node *node);
static void ast_emit_node(struct Text *out, const struct Node *node);
static void emit_ast_output(FILE *out, const struct Node *node);
static struct Text *finalize_typed_label(struct Text *in, enum NodeKind kind);
static struct Text *finalize_typed_block(struct Text *lb, struct Text *body,
                                         struct Text *rb);
static struct Text *finalize_typed_raw(struct Text *in, enum NodeKind kind);
static struct Node *ast_aggregate(const char *head, const char *open,
                                  const char *body_text, const char *close,
                                  struct Node *body);
static struct Text *finalize_typed_statement(struct Text *in, enum NodeKind fallback);
static void dump_typed_ast(FILE *out, const struct Node *node, int depth);
static void ast_final_resolve_nodes(struct Node *node);
static void ast_final_register_functions(struct Node *node);
static void emit_generated_text(FILE *out, enum NodeKind kind,
                                const char *name, struct Text *text);
static void emit_generated_text_ast(FILE *out, enum NodeKind kind,
                                    const char *name, struct Text *text,
                                    struct Node *body);
static struct Text *read_generated_stream(FILE *stream);
static struct Type *type_copy(struct Type type);
static struct Type type_make(enum TypeKind kind, int ptr, const char *tag);
static void type_set_application(struct Type *type, const char *name,
                                 const char *arguments);
static struct Type type_unknown(void);
static struct Obj *obj_new(const char *name, struct Type type, int is_local, int is_function);
static void tag_add(enum TypeKind kind, const char *name);
static void symbol_add(const char *name, struct Type type);
struct DeclInfo;
static void register_function_params(const char *s);
static void register_function_param_symbols(const char *s);
static void register_owned_parameter_cleanup(const char *function_name);
static void begin_function(void);
static void begin_top_block(struct Text *head);
static int source_has_cminus_include(FILE *fp);
static struct Text *process_pp_line(struct Text *line);
static struct Text *consume_pp_line(struct Text *line);
static struct Text *process_standalone_semi(struct Text *semi);
static struct Text *finish_top_block(struct Text *head, struct Text *lb, struct Text *body, struct Text *rb);
static struct Text *finish_c_compat_braced_decl(struct Text *head, struct Text *lb, struct Text *body, struct Text *rb, struct Text *suffix, struct Text *semi);
static struct Text *process_statement(struct Text *stmt, struct Text *semi);
static struct Text *process_return(struct Text *ret, struct Text *expr, struct Text *semi);
static char *extract_return_value_expr(const char *stmt);
static struct Text *process_external_decl(struct Text *decl, struct Text *semi);
static struct Text *process_control_head(struct Text *head);
static int find_assignment(const char *s);
static int parse_function_signature(const char *s, char *name, struct Type *ret);
static struct FunctionParams *function_params_find(const char *name);
static int param_index(struct FunctionParams *fn, const char *name);
static struct Symbol *symbol_find_or_current_param(const char *name);
static int malloc_func_index(const char *name);
static void owned_func_add_type(const char *name, struct Type ret);
static void owned_func_add_type_ex(const char *name, struct Type ret, int is_alloc_attr);
static void append_indent_from(const char *s, struct Text *out);
static void append_leading_newlines(const char *s, struct Text *out);
static int rhs_has_malloc_call(const char *rhs, char *func_name);
static int rhs_is_single_owned_return_call(const char *rhs);
static struct Text *rewrite_owned_return_rvalues(struct Text *in, const char *original);
static int text_has_s_string(const char *text);
static int rhs_has_function_call(const char *rhs);
static enum TypeKind keyword_type(const char *word);
static int type_same_unowned(struct Type a, struct Type b);
static int rhs_has_new_expr(const char *rhs, struct Type *type);
static int rhs_has_clone_expr(const char *rhs, struct Type *type);
static int head_function_name(const char *head, char *name);
static int function_needs_stack_guard(const char *name);
static int function_signature_is_internal(const char *head);
static void check_casts(const char *text);
static struct Type expr_type(const char *s);
static int decl_has_borrow(const char *s);
static int extract_move_name(const char *s, char *name);
static int extract_direct_move_name(const char *s, char *name);
static void remove_moved_locals(const char *s);
static const char *find_top_level_char(const char *start, const char *end, char ch);
static void moved_local_add(const char *name);
static void moved_local_remove(const char *name);
static void check_moved_local_use(const char *stmt);
static void check_owned_call_arguments(const char *stmt);
static void borrow_link_add(const char *borrower, const char *owner);
static void borrow_link_remove_borrower(const char *borrower);
static void borrow_links_invalidate_owner(const char *owner);
static void check_dead_borrow_use(const char *stmt);
static void check_borrow_escape_return(const char *stmt);
static int extract_direct_borrow_owner(const char *expr, char *owner);
static int extract_safe_reference_borrow_owner(const char *expr, char *owner);
static void pending_semantics_clear(void);
static void pending_semantics_capture_statement(const char *statement);
static void pending_semantics_capture_return(const char *statement);
static int word_occurs_after_first_token(const char *stmt, const char *word);
static void check_null_assignment(const char *stmt);
static struct Text *rewrite_optional_null_assignment(struct Text *in);
static struct Text *rewrite_optional_null_return(struct Text *in);
static void check_null_arguments(const char *stmt);
static void check_span_stack_array_bounds(const char *stmt);
static void check_safe_heap_calls(const char *stmt);
static void check_safe_reference_raw_inputs(const char *stmt);
static void check_safe_raw_field_access(const char *stmt);
static void check_safe_c_function_calls(const char *stmt);
static void check_safe_array_index_access(const char *stmt);
static struct SafetyExprNode *safety_parse_range(const char *start, const char *end);
static struct SafetyExprNode *safety_parse_forest_range(const char *start,
                                                        const char *end);
static struct SafetyExprNode *safety_parse_forest(const char *stmt);
static void safety_expr_free(struct SafetyExprNode *node);
static void safety_expr_bind_identifier(struct SafetyExprNode *expr,
                                        const char *name,
                                        struct Type type);
static const struct SafetyExprNode *safety_strip_groups(const struct SafetyExprNode *node);
static int safety_ast_plain_identifier(const char *start, const char *end, char *name);
static int safety_ast_move_identifier(const char *start, const char *end, char *name);
static int safety_ast_borrow_root(const char *start, const char *end, char *owner);
static int safety_ast_reference_borrow_owner(const char *expr, char *owner);
static struct Type safety_ast_expr_type(const char *expr);
static int safety_ast_has_generic_start(const struct SafetyExprNode *node, const char *start);
static const char *skip_safe_deref_trivia(const char *p);
static struct Text *rewrite_inferred_array_from_calls(struct Text *in);
static void register_unsafe_metadata(const char *body);
static void emit_generic_default_macro(FILE *out, const char *func_name, struct FunctionParams *fn);
static void emit_generic_default_undef(FILE *out, const char *func_name, struct FunctionParams *fn);
static int range_contains_text(const char *start, const char *end, const char *needle);
static struct Text *rewrite_os_attributes(struct Text *in);
static struct Text *rewrite_compile_time_os_ops(struct Text *in);
static int parse_linker_symbol_decl(const char *s, char *name);
static struct Text *rewrite_linker_symbol_decl(struct Text *in);
static struct Text *rewrite_linker_address_ops(struct Text *in);
static struct Text *rewrite_alignment_calls(struct Text *in);
static struct Text *rewrite_mmio_field_decl(struct Text *in, struct DeclInfo *decl);
static struct Text *strip_mmio_modifier(struct Text *in);
static struct Text *strip_attributes(struct Text *in);
static struct Text *remove_percent(struct Text *in);
static int function_decl_has_interrupt(const char *s);
static int function_decl_has_naked(const char *s);
static void validate_interrupt_function_head(const char *s);
static struct Text *rewrite_interrupt_function_head(struct Text *in);
static void check_safe_pointer_deref(const char *stmt);
static int is_unsafe_head(const char *s);
static int is_inline_c_head(const char *s);
static void begin_stmt_block(struct Text *head);
static struct Text *finish_stmt_block(struct Text *head, struct Text *lb, struct Text *body, struct Text *rb);
static int struct_field_type(const char *tag, const char *field, struct Type *type);
static struct StructFinalizer *struct_clone_find(const char *tag);
static struct StructFinalizer *struct_clone_get(const char *tag);
static struct Text *add_zero_initializer(struct Text *in);
static struct Text *rewrite_new_expressions(struct Text *in);
static struct Text *rewrite_clone_expressions(struct Text *in);
static struct Text *rewrite_method_calls(struct Text *in);
static struct Text *rewrite_auto_field_access(struct Text *in);
static struct Text *rewrite_index_access(struct Text *in);
static struct Text *rewrite_span_operators(struct Text *in);
static struct Text *rewrite_sizeof_types(struct Text *in);
static struct Text *rewrite_division_checks(struct Text *in);
static struct Text *rewrite_parameter_calls(struct Text *in);
static struct Text *rewrite_safe_reference_decl(struct Text *in);
static void check_safe_pointer_decl(const char *s);
static struct Text *rewrite_generics(struct Text *in);
static void append_indent_from(const char *s, struct Text *out);
static void append_leading_newlines(const char *s, struct Text *out);
static struct Text *rewrite_foreach_head(struct Text *head);
static const char *matching_paren(const char *open);
static const char *skip_divisor_expr(const char *p);
static int is_generic_decl_head(const char *s);
static int parse_generic_struct_head(const char *s, char *param, char *name);
static int parse_generic_function_head(const char *s, char *param, char *name);
static int parse_generic_angle_arg(const char *p, char *arg, const char **after);
static struct GenericInstance *generic_instance_get(struct GenericTemplate *tmpl, const char *arg);
static int parse_payload_enum_head(const char *s, char *param, char *name);
static int parse_bitflags_head(const char *s, char *name, char *base);
static struct Text *emit_bitflags_decl(const char *name, const char *base, const char *body);
static int bitflags_const_type(const char *name, struct Type *type);
static int bitflags_expr_type(const char *expr, struct Type *type);
static void emit_payload_enum_instances(FILE *out);
static struct Text *rewrite_payload_enum_constructors(struct Text *in);
static struct Text *try_rewrite_auto_payload_enum_decl(struct Text *in);
static int is_uniq_decl(const char *s);
static struct Text *strip_uniq(struct Text *in);
static struct Text *uniq_extern_decl(struct Text *in);
static const char *generic_template_body_start(const char *head, char *param);
static int clone_uses_managed_heap(const char *tag);
static void append_struct_clone_name(struct Text *out, const char *tag);
static void append_struct_clone_definition(struct Text *out, struct StructFinalizer *clone);
static void append_finalize_for_type(struct Text *out, const char *indent, const char *expr, struct Type type);
static void append_release_pointer(struct Text *out, const char *indent, const char *expr, struct Type type);
static struct Text *prepend_owned_assignment_release(struct Text *stmt, const char *original, const char *lhs_expr, struct Type type);
static struct Text *rewrite_returns_with_stack_leave(struct Text *in);
static void append_zero_clear_after_decl(struct Text *stmt, const char *original, const char *name);
static int starts_word(const char *s, const char *word);
static const char *skip_ws(const char *s);
%}

%code requires {
struct Text;
struct DeclInfo;
}

%union {
    struct Text *node;
}

%token <node> IDENT NUMBER STRING_LITERAL CHAR_LITERAL PP_LINE RETURN CASE DEFAULT KEYWORD OP
%token <node> LBRACE RBRACE LPAREN RPAREN LBRACKET RBRACKET LT GT SEMI COMMA COLON EQUAL PERCENT OTHER

%type <node> translation_unit external_item top_seq top_part token token_no_comma
%type <node> paren_group paren_items paren_part bracket_group bracket_items bracket_part
%type <node> angle_group angle_items angle_part
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
        { $$ = finalize_typed_raw(process_pp_line($1), ND_PP); }
    | SEMI
        { $$ = process_standalone_semi($1); }
    | top_seq SEMI
        { $$ = finalize_typed_statement(process_external_decl($1, $2), ND_DECL); }
    | top_seq LBRACE compound_items RBRACE top_seq SEMI
        { $$ = finish_c_compat_braced_decl($1, $2, $3, $4, $5, $6); }
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
    | angle_group
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
        { $$ = finalize_typed_raw(process_pp_line($1), ND_PP); }
    | SEMI
        { $$ = $1; }
    | return_statement
        { $$ = $1; }
    | stmt_seq SEMI
        { $$ = finalize_typed_statement(process_statement($1, $2), ND_EXPR_STMT); }
    | stmt_seq COMMA
        { $$ = text_join($1, $2); $$->tail_return = 0; }
    | IDENT COLON
        { $$ = finalize_typed_label(text_join($1, $2), ND_LABEL); $$->tail_return = 0; }
    | DEFAULT COLON
        { $$ = finalize_typed_label(text_join($1, $2), ND_DEFAULT); $$->tail_return = 0; }
    | CASE stmt_seq COLON
        { $$ = finalize_typed_label(text_join3($1, $2, $3), ND_CASE); $$->tail_return = 0; }
    | LBRACE compound_items RBRACE
        { $$ = finalize_typed_block($1, $2, $3); $$->tail_return = 0; }
    | stmt_seq LBRACE
        { begin_stmt_block($1); }
      compound_items RBRACE
        { $$ = finish_stmt_block($1, $2, $4, $5); $$->tail_return = 0; }
    ;

return_statement
    : RETURN SEMI
        { $$ = finalize_typed_statement(process_return($1, text_new(), $2), ND_RETURN); }
    | RETURN stmt_seq SEMI
        { $$ = finalize_typed_statement(process_return($1, $2, $3), ND_RETURN); }
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
    | angle_group
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
    | SEMI
        { $$ = $1; }
    | paren_group
        { $$ = $1; }
    | bracket_group
        { $$ = $1; }
    | angle_group
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
    | SEMI
        { $$ = $1; }
    | paren_group
        { $$ = $1; }
    | bracket_group
        { $$ = $1; }
    | angle_group
        { $$ = $1; }
    ;

angle_group
    : LT angle_items GT
        { $$ = text_join3($1, $2, $3); }
    ;

angle_items
    : /* empty */
        { $$ = text_new(); }
    | angle_items angle_part
        { $$ = text_join($1, $2); }
    ;

angle_part
    : token
        { $$ = $1; }
    | SEMI
        { $$ = $1; }
    | paren_group
        { $$ = $1; }
    | bracket_group
        { $$ = $1; }
    | angle_group
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
    | LT
        { $$ = $1; }
    | GT
        { $$ = $1; }
    | COMMA
        { $$ = $1; }
    | COLON
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
    | LT
        { $$ = $1; }
    | GT
        { $$ = $1; }
    | COLON
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

static int current_generic_parameter_named(const char *name)
{
    const char *p = g_current_generic_param;

    while (*p != '\0') {
        const char *start;
        const char *end;

        while (*p == ',' || isspace((unsigned char)*p)) {
            p++;
        }
        start = p;
        while (*p != '\0' && *p != ',') {
            p++;
        }
        end = p;
        while (end > start && isspace((unsigned char)end[-1])) {
            end--;
        }
        if ((size_t)(end - start) == strlen(name) &&
            strncmp(start, name, (size_t)(end - start)) == 0) {
            return 1;
        }
    }
    return 0;
}

static int generic_argument_uses_current_parameter(const char *arg)
{
    const char *p = arg;

    while (*p != '\0') {
        if (is_ident_start((unsigned char)*p)) {
            char name[NAME_MAX_LEN];

            p = read_name(p, name);
            if (current_generic_parameter_named(name)) {
                return 1;
            }
        } else {
            p++;
        }
    }
    return 0;
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

static int parse_bitflags_head(const char *s, char *name, char *base)
{
    const char *p = skip_ws(s);
    const char *name_end;
    const char *colon;
    const char *end;

    name[0] = '\0';
    base[0] = '\0';
    if (!starts_word(p, "bitflags")) {
        return 0;
    }
    p = skip_ws(p + 8);
    if (!is_ident_start((unsigned char)*p)) {
        return 0;
    }
    name_end = read_name(p, name);
    colon = skip_ws(name_end);
    if (*colon != ':') {
        return 0;
    }
    p = skip_ws(colon + 1);
    end = p + strlen(p);
    while (end > p && isspace((unsigned char)end[-1])) {
        end--;
    }
    if (end <= p || (size_t)(end - p) >= NAME_MAX_LEN) {
        return 0;
    }
    copy_trimmed(base, NAME_MAX_LEN, p, end);
    return name[0] != '\0' && base[0] != '\0';
}

static int bitflags_find(const char *name)
{
    int i;

    for (i = 0; i < g_bitflags.count; i++) {
        if (strcmp(g_bitflags.flag[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

static void bitflags_add(const char *name, const char *base)
{
    int index;

    if (name[0] == '\0') {
        return;
    }
    index = bitflags_find(name);
    if (index >= 0) {
        strncpy(g_bitflags.flag[index].base, base, NAME_MAX_LEN - 1);
        g_bitflags.flag[index].base[NAME_MAX_LEN - 1] = '\0';
        return;
    }
    if (g_bitflags.count >= MAX_TAGS) {
        die("too many bitflags");
    }
    strncpy(g_bitflags.flag[g_bitflags.count].name, name, NAME_MAX_LEN - 1);
    g_bitflags.flag[g_bitflags.count].name[NAME_MAX_LEN - 1] = '\0';
    strncpy(g_bitflags.flag[g_bitflags.count].base, base, NAME_MAX_LEN - 1);
    g_bitflags.flag[g_bitflags.count].base[NAME_MAX_LEN - 1] = '\0';
    g_bitflags.count++;
}

static int bitflags_const_type(const char *name, struct Type *type)
{
    int i;

    for (i = 0; i < g_bitflags.count; i++) {
        size_t n = strlen(g_bitflags.flag[i].name);
        if (strncmp(name, g_bitflags.flag[i].name, n) == 0 && name[n] == '_') {
            *type = type_make(TY_BITFLAGS, 0, g_bitflags.flag[i].name);
            return 1;
        }
    }
    return 0;
}

static int bitflags_expr_type(const char *expr, struct Type *type)
{
    const char *p = expr;
    struct Type found = type_unknown();
    int saw = 0;

    while (*p != '\0') {
        char name[NAME_MAX_LEN];
        const char *end;
        struct Type current;

        if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            p++;
            continue;
        }
        end = read_name(p, name);
        if (bitflags_const_type(name, &current)) {
            if (!saw) {
                found = current;
                saw = 1;
            } else if (!type_same_unowned(found, current)) {
                fprintf(stderr, "c-: type error: cannot mix different bitflags in expression at %s:%d\n",
                        g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
                exit(1);
            }
        }
        p = end;
    }
    if (saw) {
        *type = found;
        return 1;
    }
    return 0;
}

static struct Text *emit_bitflags_decl(const char *name, const char *base, const char *body)
{
    const char *p = body;
    struct Text *out = text_new();
    struct Node *bitflags_ast = ast_new(ND_BITFLAGSDEF, NULL);

    strncpy(bitflags_ast->name, name, NAME_MAX_LEN - 1);
    bitflags_ast->name[NAME_MAX_LEN - 1] = '\0';
    strncpy(bitflags_ast->type_name, base, NAME_MAX_LEN - 1);
    bitflags_ast->type_name[NAME_MAX_LEN - 1] = '\0';
    bitflags_ast->ty = type_copy(type_make(TY_BITFLAGS, 0, name));

    text_add(out, "\ntypedef ");
    text_add(out, base);
    text_add_ch(out, ' ');
    text_add(out, name);
    text_add(out, ";\nenum {\n");
    while (*p != '\0') {
        char variant[NAME_MAX_LEN];
        const char *variant_start;
        const char *name_end;
        const char *eq;
        const char *value_start;
        const char *value_end;

        p = skip_ws(p);
        if (*p == ',') {
            p++;
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            p++;
            continue;
        }
        variant_start = p;
        name_end = read_name(p, variant);
        eq = skip_ws(name_end);
        if (*eq != '=') {
            fprintf(stderr, "c-: type error: bitflags variants require explicit values at %s:%d\n",
                    g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
        value_start = skip_ws(eq + 1);
        value_end = value_start;
        while (*value_end != '\0' && *value_end != ',') {
            value_end++;
        }
        while (value_end > value_start && isspace((unsigned char)value_end[-1])) {
            value_end--;
        }
        text_add(out, "    ");
        text_add(out, name);
        text_add_ch(out, '_');
        text_add(out, variant);
        text_add(out, " = ");
        text_add_n(out, value_start, (size_t)(value_end - value_start));
        text_add(out, ",\n");
        {
            char *member_text = xstrndup(variant_start,
                                         (size_t)(value_end - variant_start));
            struct Node *member = ast_new(ND_BITFLAG_MEMBER, member_text);
            const char *member_eq = strchr(member->tok, '=');

            free(member_text);
            strncpy(member->name, variant, NAME_MAX_LEN - 1);
            member->name[NAME_MAX_LEN - 1] = '\0';
            member->ty = type_copy(type_make(TY_BITFLAGS, 0, name));
            if (member_eq != NULL) {
                member->expr = safety_parse_range(member_eq + 1,
                                                  member->tok + strlen(member->tok));
            }
            bitflags_ast->body = ast_append(bitflags_ast->body, member);
        }
        p = value_end;
        while (*p != '\0' && *p != ',') {
            p++;
        }
    }
    text_add(out, "};\n");
    bitflags_ast->tok = xstrdup(out->text);
    out->ast = bitflags_ast;
    return out;
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
    const char *p;

    copy_trimmed(clean_arg, sizeof(clean_arg), arg, arg + strlen(arg));
    if (clean_arg[0] == '\0') {
        strcpy(clean_arg, "void");
    }
    p = skip_ws(clean_arg);
    if (is_ident_start((unsigned char)*p)) {
        char generic_name[NAME_MAX_LEN];
        char nested_arg[NAME_MAX_LEN];
        const char *name_end = read_name(p, generic_name);
        const char *after;
        struct GenericTemplate *tmpl = generic_find(&g_generic_structs, generic_name);

        if (tmpl != NULL && parse_generic_angle_arg(name_end, nested_arg, &after) &&
            *skip_ws(after) == '\0') {
            struct GenericInstance *nested = generic_instance_get(tmpl, nested_arg);
            if (strlen(nested->concrete) + 8 > sizeof(clean_arg)) {
                die("nested generic type name is too long");
            }
            strcpy(clean_arg, "struct ");
            strcat(clean_arg, nested->concrete);
        }
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

static void payload_enum_add(const char *param, const char *name, const char *body,
                             struct Node *ast)
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
    en->ast = ast;
    g_template_nodes = ast_append(g_template_nodes, ast);

    while (*p != '\0') {
        char variant[NAME_MAX_LEN];
        char payload[NAME_MAX_LEN];
        const char *variant_start;
        const char *name_end;
        const char *q;
        struct Node *variant_ast;

        p = skip_ws(p);
        if (*p == ',') {
            p++;
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            p++;
            continue;
        }
        variant_start = p;
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
        {
            char *variant_text = xstrndup(variant_start,
                                          (size_t)(p - variant_start));

            variant_ast = ast_new(ND_PAYLOAD_VARIANT, variant_text);
            free(variant_text);
        }
        strncpy(variant_ast->name, variant, NAME_MAX_LEN - 1);
        variant_ast->name[NAME_MAX_LEN - 1] = '\0';
        if (payload[0] != '\0') {
            struct Type payload_type = type_unknown();
            enum TypeKind kind = keyword_type(payload);

            strncpy(variant_ast->type_name, payload, NAME_MAX_LEN - 1);
            variant_ast->type_name[NAME_MAX_LEN - 1] = '\0';
            if (kind != TY_UNKNOWN) {
                payload_type = type_make(kind, 0, NULL);
            } else {
                strncpy(payload_type.tag, payload, NAME_MAX_LEN - 1);
                payload_type.tag[NAME_MAX_LEN - 1] = '\0';
            }
            variant_ast->ty = type_copy(payload_type);
        }
        ast->body = ast_append(ast->body, variant_ast);
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
    (void)type;
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
                                           const char *body,
                                           struct Node *ast)
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
    tmpl->ast = ast;
    g_template_nodes = ast_append(g_template_nodes, ast);
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
    int i;

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
                if (strcmp(arg, "string") == 0) {
                    strncpy(arg, "char*", NAME_MAX_LEN - 1);
                    arg[NAME_MAX_LEN - 1] = '\0';
                } else if (strncmp(arg, "string", 6) == 0) {
                    const char *q = skip_ws(arg + 6);
                    if (*q == '*') {
                        char normalized[NAME_MAX_LEN];
                        snprintf(normalized, sizeof(normalized), "char*%s", q);
                        strncpy(arg, normalized, NAME_MAX_LEN - 1);
                        arg[NAME_MAX_LEN - 1] = '\0';
                    }
                } else if (is_ident_start((unsigned char)arg[0]) &&
                    strchr(arg, '*') == NULL && strchr(arg, ' ') == NULL &&
                    strchr(arg, '<') == NULL && strchr(arg, ',') == NULL &&
                    keyword_type(arg) == TY_UNKNOWN) {
                    for (i = 0; i < g_tags.count; i++) {
                        if (g_tags.tag[i].kind == TY_STRUCT && strcmp(g_tags.tag[i].name, arg) == 0) {
                            char normalized[NAME_MAX_LEN];
                            snprintf(normalized, sizeof(normalized), "struct %s*", arg);
                            strncpy(arg, normalized, NAME_MAX_LEN - 1);
                            arg[NAME_MAX_LEN - 1] = '\0';
                            break;
                        }
                    }
                }
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
    t.raw_ptr = 0;
    t.is_array = 0;
    t.array_len = 0;
    t.size = 0;
    t.align = 1;
    t.tag[0] = '\0';
    t.applied_name[0] = '\0';
    t.applied_args[0] = '\0';
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
    case TY_BITFLAGS:
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

static void type_set_application(struct Type *type, const char *name,
                                 const char *arguments)
{
    if (type == NULL || name == NULL || arguments == NULL) {
        return;
    }
    if (strlen(name) >= sizeof(type->applied_name) ||
        strlen(arguments) >= sizeof(type->applied_args)) {
        die("generic type application is too long");
    }
    strcpy(type->applied_name, name);
    strcpy(type->applied_args, arguments);
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

static int type_is_string_like(struct Type t)
{
    return t.kind == TY_CHAR && t.ptr == 1;
}

static const char *type_kind_name(enum TypeKind kind)
{
    switch (kind) {
    case TY_VOID:
        return "void";
    case TY_GENERIC:
        return "generic";
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
    case TY_BITFLAGS:
        return "bitflags";
    case TY_TYPEDEF:
        return "typedef";
    case TY_FUNCTION:
        return "function";
    case TY_TYPE_CONSTRUCTOR:
        return "type-constructor";
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

    if (t.kind == TY_FUNCTION) {
        char return_text[NAME_MAX_LEN * 2];

        if (t.base == NULL) {
            snprintf(buf, size, "fn()->unknown");
        } else {
            type_to_string(*t.base, return_text, sizeof(return_text));
            snprintf(buf, size, "fn()->%s", return_text);
        }
        return;
    }
    if (t.kind == TY_TYPE_CONSTRUCTOR) {
        snprintf(buf, size, "type %s", t.tag);
        return;
    }
    if (t.kind == TY_BITFLAGS || t.kind == TY_GENERIC || t.kind == TY_TYPEDEF) {
        snprintf(buf, size, "%s%s", t.tag, stars);
    } else if (t.kind == TY_STRUCT || t.kind == TY_UNION || t.kind == TY_ENUM) {
        snprintf(buf, size, "%s %s%s", type_kind_name(t.kind), t.tag, stars);
    } else {
        snprintf(buf, size, "%s%s", type_kind_name(t.kind), stars);
    }
    off = strlen(buf);
    if (t.owned && off + 1 < size) {
        buf[off] = '%';
        buf[off + 1] = '\0';
        off++;
    }
    if (t.raw_ptr && off + 4 < size) {
        strcpy(buf + off, " raw");
    }
}

static void append_c_type(struct Text *out, struct Type t)
{
    int i;

    if (t.kind == TY_GENERIC || t.kind == TY_TYPEDEF ||
        t.kind == TY_TYPE_CONSTRUCTOR) {
        text_add(out, t.tag);
    } else if (t.kind == TY_STRUCT || t.kind == TY_UNION || t.kind == TY_ENUM) {
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
    if (a.kind == TY_FUNCTION) {
        return a.base != NULL && b.base != NULL &&
            type_same_unowned(*a.base, *b.base);
    }
    if (a.kind == TY_STRUCT || a.kind == TY_UNION || a.kind == TY_ENUM ||
        a.kind == TY_BITFLAGS || a.kind == TY_GENERIC || a.kind == TY_TYPEDEF ||
        a.kind == TY_TYPE_CONSTRUCTOR) {
        return strcmp(a.tag, b.tag) == 0;
    }
    return 1;
}

static int type_compatible(struct Type lhs, struct Type rhs)
{
    if (!type_is_known(lhs) || !type_is_known(rhs)) {
        return 1;
    }
    if (lhs.kind == TY_TYPEDEF || rhs.kind == TY_TYPEDEF) {
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

static enum TypeKind tag_kind_find(const char *name)
{
    int i;

    for (i = 0; i < g_tags.count; i++) {
        if (strcmp(g_tags.tag[i].name, name) == 0) {
            return g_tags.tag[i].kind;
        }
    }
    return TY_UNKNOWN;
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
        if (type.applied_name[0] == '\0' && old->type.applied_name[0] != '\0') {
            strcpy(type.applied_name, old->type.applied_name);
            strcpy(type.applied_args, old->type.applied_args);
        }
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

static void symbol_add_param_to(struct Symbols *symbols, const char *name, struct Type type)
{
    struct Symbol *sym;

    symbol_add_to(symbols, name, type);
    sym = symbol_find_in(symbols, name);
    if (sym != NULL && sym->var != NULL) {
        sym->var->is_param = 1;
    }
}

static void symbol_add(const char *name, struct Type type)
{
    if (g_in_function) {
        symbol_add_to(&g_locals, name, type);
    } else {
        symbol_add_to(&g_globals, name, type);
    }
}

static struct TypedefAlias *typedef_alias_find(const char *name)
{
    int i;

    for (i = g_typedefs.count - 1; i >= 0; i--) {
        if (strcmp(g_typedefs.alias[i].name, name) == 0) {
            return &g_typedefs.alias[i];
        }
    }
    return NULL;
}

static void typedef_alias_add(const char *name, struct Type type)
{
    struct TypedefAlias *existing = typedef_alias_find(name);
    struct TypedefAlias *alias;

    if (existing != NULL) {
        existing->type = type;
        return;
    }
    if (g_typedefs.count >= MAX_SYMBOLS) {
        die("too many typedef names");
    }
    alias = &g_typedefs.alias[g_typedefs.count++];
    strncpy(alias->name, name, NAME_MAX_LEN - 1);
    alias->name[NAME_MAX_LEN - 1] = '\0';
    alias->type = type;
}

static void typedef_alias_add_opaque(const char *name)
{
    typedef_alias_add(name, type_make(TY_TYPEDEF, 0, name));
}

static int skip_decl_word(const char *word)
{
    static const char *words[] = {
        "auto", "extern", "register", "static", "typedef", "const", "volatile",
        "restrict", "inline", "signed", "unsigned", "_Atomic", "uniq", "borrow", "owned",
        "interrupt", "mmio", "ref", "mut", "CMINUS_THREAD_LOCAL", NULL
    };
    int i;
    for (i = 0; words[i] != NULL; i++) {
        if (strcmp(word, words[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

static int os_attribute_name(const char *word)
{
    return strcmp(word, "section") == 0 ||
        strcmp(word, "aligned") == 0 ||
        strcmp(word, "packed") == 0 ||
        strcmp(word, "used") == 0 ||
        strcmp(word, "naked") == 0 ||
        strcmp(word, "no_return") == 0 ||
        strcmp(word, "weak") == 0 ||
        strcmp(word, "export") == 0;
}

static const char *skip_os_attribute(const char *p, const char *word)
{
    const char *q = skip_ws(p);
    const char *close;

    if (strcmp(word, "section") == 0 || strcmp(word, "aligned") == 0) {
        if (*q != '(') {
            fprintf(stderr, "c-: type error: %s requires an argument at %s:%d\n",
                    word, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
        close = matching_paren(q);
        if (close == NULL) {
            fprintf(stderr, "c-: type error: unterminated %s attribute at %s:%d\n",
                    word, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
        return skip_ws(close + 1);
    }
    return q;
}

static int os_attribute_can_start_decl(const char *word, const char *next)
{
    if (strcmp(word, "section") == 0 || strcmp(word, "aligned") == 0) {
        return *skip_ws(next) == '(';
    }
    next = skip_ws(next);
    return is_ident_start((unsigned char)*next);
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
    int is_typedef;
    int has_init;
    int is_array;
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
    int saw_borrow = 0;
    int saw_ref = 0;

    tag[0] = '\0';
    while (is_ident_start((unsigned char)*p)) {
        const char *next = read_name(p, word);
        if (os_attribute_name(word) && os_attribute_can_start_decl(word, next)) {
            p = skip_os_attribute(next, word);
            continue;
        }
        if (!skip_decl_word(word)) {
            break;
        }
        if (strcmp(word, "borrow") == 0) {
            saw_borrow = 1;
        } else if (strcmp(word, "owned") == 0) {
            saw_borrow = 0;
        } else if (strcmp(word, "ref") == 0) {
            saw_ref = 1;
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
        if (parse_generic_angle_arg(next, arg, &after) &&
            generic_argument_uses_current_parameter(arg)) {
            if (strlen(word) + strlen(arg) + 3 > sizeof(tag)) {
                die("generic type name is too long");
            }
            strcpy(tag, word);
            strcat(tag, "<");
            strcat(tag, arg);
            strcat(tag, ">");
            *base_end = after;
            *type = type_make(TY_GENERIC, 0, tag);
            type_set_application(type, word, arg);
            if (strcmp(word, "Box") == 0) {
                type->ptr = 1;
                type->owned = 1;
            } else if (saw_ref) {
                type->ptr = 1;
            }
            return 1;
        }
        if (strcmp(word, "Box") == 0 && parse_generic_angle_arg(next, arg, &after)) {
            const char *arg_start = skip_ws(arg);
            const char *arg_end;

            if (starts_word(arg_start, "struct")) {
                arg_start = skip_ws(arg_start + 6);
            }
            if (!is_ident_start((unsigned char)*arg_start)) {
                return 0;
            }
            arg_end = read_name(arg_start, tag);
            arg_end = skip_ws(arg_end);
            if (*arg_end == '*') {
                arg_end = skip_ws(arg_end + 1);
            }
            if (*arg_end != '\0') {
                fprintf(stderr, "c-: type error: Box<T> currently requires a concrete user struct type\n");
                exit(1);
            }
            *base_end = after;
            *type = type_make(TY_STRUCT, 1, tag);
            type_set_application(type, word, arg);
            type->owned = 1;
            type->raw_ptr = 0;
            return 1;
        }
        if (strcmp(word, "string") == 0) {
            *base_end = next;
            *type = type_make(TY_CHAR, 1, NULL);
            type->owned = !saw_borrow;
            return 1;
        }
        if (bitflags_find(word) >= 0) {
            *base_end = next;
            *type = type_make(TY_BITFLAGS, 0, word);
            return 1;
        }
        if (tmpl != NULL && parse_generic_angle_arg(next, arg, &after)) {
            struct GenericInstance *inst = generic_instance_get(tmpl, arg);
            *base_end = after;
            *type = type_make(TY_STRUCT, 0, inst->concrete);
            type_set_application(type, word, arg);
            if (saw_ref) {
                type->ptr = 1;
            }
            return 1;
        }
        {
            struct PayloadEnum *payload_en = payload_enum_find(word);
            if (payload_en != NULL && parse_generic_angle_arg(next, arg, &after)) {
                struct GenericInstance *inst = payload_enum_instance_get(payload_en, arg);
                *base_end = after;
                *type = type_make(TY_STRUCT, 0, inst->concrete);
                type_set_application(type, word, arg);
                if (saw_ref) {
                    type->ptr = 1;
                }
                return 1;
            }
        }
        if (current_generic_parameter_named(word)) {
            *base_end = next;
            *type = type_make(TY_GENERIC, 0, word);
            if (saw_ref) {
                type->ptr = 1;
            }
            return 1;
        }
        kind = keyword_type(word);
        if (kind == TY_UNKNOWN) {
            struct TypedefAlias *alias = typedef_alias_find(word);
            int i;

            if (alias != NULL) {
                *base_end = next;
                *type = alias->type;
                if (saw_ref) {
                    type->ptr++;
                }
                return 1;
            }
            for (i = 0; i < g_tags.count; i++) {
                if (strcmp(g_tags.tag[i].name, word) == 0) {
                    *base_end = next;
                    *type = type_make(g_tags.tag[i].kind, 0, word);
                    if (saw_ref) {
                        type->ptr = 1;
                    }
                    return 1;
                }
            }
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
    if (saw_ref) {
        type->ptr = 1;
    }
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
    if (has_decl_word_before(s, s + strlen(s), "typedef")) {
        return 0;
    }
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
    if (g_unsafe_depth > 0 && ret->ptr > 0 && !ret->owned) {
        ret->raw_ptr = 1;
    }
    return 1;
}

static int parse_function_pointer_decl(const char *base_end,
                                       const char *limit,
                                       struct Type return_type,
                                       struct DeclInfo *decl)
{
    const char *open;

    for (open = base_end; open < limit; open++) {
        const char *star;
        const char *name_end;
        const char *close;
        const char *params;
        char name[NAME_MAX_LEN];

        if (*open != '(') continue;
        star = skip_ws(open + 1);
        if (star >= limit || *star != '*') continue;
        star = skip_ws(star + 1);
        if (star >= limit || !is_ident_start((unsigned char)*star)) continue;
        name_end = read_name(star, name);
        close = skip_ws(name_end);
        if (close >= limit || *close != ')') continue;
        params = skip_ws(close + 1);
        if (params >= limit || *params != '(') continue;
        if ((size_t)(name_end - star) >= sizeof(decl->name)) return 0;

        memcpy(decl->name, star, (size_t)(name_end - star));
        decl->name[name_end - star] = '\0';
        decl->type = type_make(TY_FUNCTION, 0, NULL);
        decl->type.base = type_copy(return_type);
        decl->is_decl = 1;
        return 1;
    }
    return 0;
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
    int array_len = 0;
    struct Type base_type;

    memset(decl, 0, sizeof(*decl));
    decl->type = type_unknown();
    decl->is_typedef = has_decl_word_before(p, p + strlen(p), "typedef");

    (void)word;
    if (!parse_base_type_prefix(p, &base_end, &base_type)) {
        return 0;
    }
    if (base_type.applied_name[0] != '\0' && *skip_ws(base_end) == '(') {
        return 0;
    }
    eq = find_assignment(s);
    limit = s + strlen(s);
    if (eq >= 0) {
        limit = s + eq;
        decl->has_init = 1;
        decl->init = s + eq + 1;
    }
    if (parse_function_pointer_decl(base_end, limit, base_type, decl)) {
        return 1;
    }
    for (scan = base_end; scan < limit; scan++) {
        if (*scan == '[') {
            const char *len_start = skip_ws(scan + 1);
            char *len_end;
            long len;

            decl->is_array = 1;
            if (isdigit((unsigned char)*len_start)) {
                len = strtol(len_start, &len_end, 10);
                len_end = (char*)skip_ws(len_end);
                if (*len_end == ']' && len > 0 && len <= 2147483647L) {
                    array_len = (int)len;
                }
            }
            while (scan < limit && *scan != ']') {
                scan++;
            }
            continue;
        }
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
    if (decl->is_typedef) {
        ptr = 0;
        for (scan = base_end; scan < name_start; scan++) {
            if (*scan == '*') ptr++;
        }
    }
    memcpy(decl->name, name_start, (size_t)(name_end - name_start));
    decl->name[name_end - name_start] = '\0';
    decl->type = base_type;
    decl->type.ptr += ptr;
    if (decl->is_array) {
        decl->type.is_array = 1;
        decl->type.array_len = array_len;
    }
    decl->type.owned = base_type.owned || strchr(base_end, '%') != NULL ||
        has_decl_word_before(s, name_start, "owned");
    if (g_unsafe_depth > 0 && decl->type.ptr > 0 && !decl->type.owned) {
        decl->type.raw_ptr = 1;
    }
    scan = skip_ws(name_end);
    if (*scan == '(' && eq < 0) {
        decl->is_function = 1;
    }
    decl->is_decl = 1;
    return 1;
}

void cminus_process_braced_initializer(const char *text)
{
    struct DeclInfo decl;

    if (parse_decl(text, &decl) && decl.is_decl && decl.name[0] != '\0' &&
        !decl.is_function) {
        symbol_add(decl.name, decl.type);
    }
    if (g_unsafe_depth > 0) {
        return;
    }
    check_safe_pointer_deref(text);
    check_casts(text);
    check_safe_heap_calls(text);
    check_safe_c_function_calls(text);
    check_safe_raw_field_access(text);
    check_safe_array_index_access(text);
}

static const char *find_decl_name_pos(const char *s, const char *name)
{
    const char *p = s;
    size_t n = strlen(name);

    while ((p = strstr(p, name)) != NULL) {
        if ((p == s || !is_ident((unsigned char)p[-1])) &&
            !is_ident((unsigned char)p[n])) {
            return p;
        }
        p += n;
    }
    return NULL;
}

static int pointer_token_before(const char *start, const char *end)
{
    const char *p;

    for (p = start; p < end && *p != '\0'; p++) {
        if (*p == '*' || *p == '%') {
            return 1;
        }
    }
    return 0;
}

static int is_safe_reference_type(struct Type type)
{
    if (type.tag[0] != '\0' && strncmp(type.tag, "__CMinusIndex", 13) == 0) {
        return 0;
    }
    if (strcmp(type.tag, "Optional") == 0 || strncmp(type.tag, "Optional_", 9) == 0 ||
        strcmp(type.tag, "Ref") == 0 || strncmp(type.tag, "Ref_", 4) == 0 ||
        strcmp(type.tag, "Span") == 0 || strncmp(type.tag, "Span_", 5) == 0 ||
        strcmp(type.tag, "FixedVec") == 0 || strncmp(type.tag, "FixedVec_", 9) == 0 ||
        strcmp(type.tag, "RingBuffer") == 0 || strncmp(type.tag, "RingBuffer_", 11) == 0 ||
        strcmp(type.tag, "Register") == 0 || strncmp(type.tag, "Register_", 9) == 0 ||
        strcmp(type.tag, "Atomic") == 0 || strncmp(type.tag, "Atomic_", 7) == 0 ||
        strcmp(type.tag, "Volatile") == 0 || strncmp(type.tag, "Volatile_", 9) == 0 ||
        strcmp(type.tag, "StaticCell") == 0 || strncmp(type.tag, "StaticCell_", 11) == 0 ||
        strcmp(type.tag, "Bitmap") == 0 ||
        strcmp(type.tag, "Critical") == 0 ||
        strcmp(type.tag, "Thread") == 0 ||
        strcmp(type.tag, "Mutex") == 0 ||
        strcmp(type.tag, "Cond") == 0) {
        return 0;
    }
    return type.kind == TY_STRUCT;
}

static int type_is_runtime_resource_value(struct Type type)
{
    return type.kind == TY_STRUCT && type.ptr == 0 &&
        (strcmp(type.tag, "Thread") == 0 ||
         strcmp(type.tag, "Mutex") == 0 ||
         strcmp(type.tag, "Cond") == 0 ||
         strcmp(type.tag, "Critical") == 0);
}

static int is_heap_collection_type(struct Type type)
{
    return strncmp(type.tag, "Vec_", 4) == 0 ||
           strncmp(type.tag, "List_", 5) == 0 ||
           strncmp(type.tag, "Map_", 4) == 0 ||
           strncmp(type.tag, "OwnedVec_", 9) == 0 ||
           strncmp(type.tag, "OwnedList_", 10) == 0 ||
           strncmp(type.tag, "OwnedMap_", 9) == 0 ||
           strncmp(type.tag, "Iterator_", 9) == 0;
}

static int is_heap_payload_enum_type(struct Type type)
{
    int i;
    int j;

    for (i = 0; i < g_payload_enums.count; i++) {
        struct PayloadEnum *en = &g_payload_enums.en[i];

        if (strcmp(en->name, "Optional") == 0 || strcmp(en->name, "__CMinusIndex") == 0) {
            continue;
        }
        for (j = 0; j < en->inst_count; j++) {
            if (strcmp(en->inst[j].concrete, type.tag) == 0) {
                return 1;
            }
        }
    }
    return 0;
}

static int type_is_stored_safe_reference(struct Type type)
{
    if (type.kind != TY_STRUCT || type.tag[0] == '\0') {
        return 0;
    }
    return strcmp(type.tag, "Ref") == 0 ||
           strcmp(type.tag, "Span") == 0 ||
           strncmp(type.tag, "Ref_", 4) == 0 ||
           strncmp(type.tag, "Span_", 5) == 0 ||
           (strncmp(type.tag, "Optional_", 9) == 0 &&
            (strstr(type.tag + 9, "Ref_") != NULL ||
             strstr(type.tag + 9, "Span_") != NULL));
}

static int type_is_heap_container_with_safe_reference(struct Type type)
{
    const char *tag = type.tag;
    int heap_container;

    if (type.kind != TY_STRUCT || tag[0] == '\0') {
        return 0;
    }
    heap_container = strncmp(tag, "Vec_", 4) == 0 ||
        strncmp(tag, "List_", 5) == 0 ||
        strncmp(tag, "Map_", 4) == 0 ||
        strncmp(tag, "OwnedVec_", 9) == 0 ||
        strncmp(tag, "OwnedList_", 10) == 0 ||
        strncmp(tag, "OwnedMap_", 9) == 0;
    return heap_container &&
        (strstr(tag, "Ref_") != NULL || strstr(tag, "Span_") != NULL);
}

static const char *find_string_decl_keyword(const char *base, int *borrowed)
{
    const char *p = skip_ws(base);
    char word[NAME_MAX_LEN];

    *borrowed = 0;
    while (is_ident_start((unsigned char)*p)) {
        const char *next = read_name(p, word);
        if (strcmp(word, "borrow") == 0) {
            *borrowed = 1;
        } else if (strcmp(word, "owned") == 0) {
            *borrowed = 0;
        } else if (strcmp(word, "string") == 0) {
            return p;
        } else if (!skip_decl_word(word)) {
            return NULL;
        }
        p = skip_ws(next);
    }
    return NULL;
}

static struct Text *rewrite_string_decl_text(struct Text *in, const char *base_start, const char *string_start, int borrowed)
{
    struct Text *out = text_new();
    const char *p = base_start;
    int have_prefix = 0;

    text_add_n(out, in->text, (size_t)(base_start - in->text));
    while (p < string_start) {
        if (isspace((unsigned char)*p)) {
            text_add_ch(out, *p++);
            continue;
        }
        if (is_ident_start((unsigned char)*p)) {
            char word[NAME_MAX_LEN];
            const char *next = read_name(p, word);
            if (strcmp(word, "borrow") == 0 || strcmp(word, "owned") == 0) {
                p = next;
                while (p < string_start && isspace((unsigned char)*p)) {
                    p++;
                }
                continue;
            }
            text_add_n(out, p, (size_t)(next - p));
            have_prefix = 1;
            p = next;
            continue;
        }
        text_add_ch(out, *p++);
        have_prefix = 1;
    }
    if (have_prefix && out->len > 0 && !isspace((unsigned char)out->text[out->len - 1])) {
        text_add_ch(out, ' ');
    }
    text_add(out, borrowed ? "borrow char*" : "owned char*");
    p = string_start + 6;
    text_add(out, p);
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(in);
    return out;
}

static struct Text *insert_pointer_before_name(struct Text *in, const char *name_pos)
{
    struct Text *out = text_new();

    text_add_n(out, in->text, (size_t)(name_pos - in->text));
    text_add_ch(out, '*');
    text_add(out, name_pos);
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(in);
    return out;
}

static struct Text *rewrite_bare_struct_reference_decl(struct Text *in, const char *base_start, const char *base_end, const char *name_pos, struct Type type)
{
    struct Text *out = text_new();
    const char *kind = type_kind_name(type.kind);

    text_add_n(out, in->text, (size_t)(base_start - in->text));
    text_add(out, kind);
    text_add_ch(out, ' ');
    text_add(out, type.tag);
    text_add_n(out, base_end, (size_t)(name_pos - base_end));
    text_add_ch(out, '*');
    text_add(out, name_pos);
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(in);
    return out;
}

static struct Text *rewrite_shared_struct_reference_decl(struct Text *in, const char *base_start, const char *base_end, const char *name_pos, struct Type type)
{
    struct Text *out = text_new();
    const char *kind = type_kind_name(type.kind);

    text_add_n(out, in->text, (size_t)(base_start - in->text));
    text_add(out, "const ");
    text_add(out, kind);
    text_add_ch(out, ' ');
    text_add(out, type.tag);
    text_add_n(out, base_end, (size_t)(name_pos - base_end));
    text_add_ch(out, '*');
    text_add(out, name_pos);
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(in);
    return out;
}

static struct Text *rewrite_box_struct_decl(struct Text *in, const char *base_start, const char *base_end, const char *name_pos, struct Type type)
{
    struct Text *out = text_new();
    const char *kind = type_kind_name(type.kind);

    text_add_n(out, in->text, (size_t)(base_start - in->text));
    text_add(out, "owned ");
    text_add(out, kind);
    text_add_ch(out, ' ');
    text_add(out, type.tag);
    text_add_n(out, base_end, (size_t)(name_pos - base_end));
    text_add_ch(out, '*');
    text_add(out, name_pos);
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(in);
    return out;
}

static struct Text *rewrite_stack_struct_value_decl(struct Text *in, const char *base_start, const char *base_end, const char *name_pos, struct Type type)
{
    struct Text *out = text_new();
    const char *kind = type_kind_name(type.kind);

    text_add_n(out, in->text, (size_t)(base_start - in->text));
    if (has_decl_word_before(in->text, name_pos, "owned")) {
        text_add(out, "owned ");
    }
    text_add(out, kind);
    text_add_ch(out, ' ');
    text_add(out, type.tag);
    text_add_n(out, base_end, (size_t)(name_pos - base_end));
    text_add(out, name_pos);
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(in);
    return out;
}

static struct Text *rewrite_critical_value_decl(struct Text *in, const char *base_start, const char *base_end, const char *name_pos)
{
    struct Type type = type_make(TY_STRUCT, 0, "Critical");

    return rewrite_stack_struct_value_decl(in, base_start, base_end, name_pos, type);
}

static struct Text *rewrite_safe_reference_params(struct Text *in)
{
    const char *open = strchr(in->text, '(');
    const char *close;
    const char *cursor;
    struct Text *out;

    if (open == NULL) {
        return in;
    }
    close = matching_paren(open);
    if (close == NULL) {
        return in;
    }
    out = text_new();
    text_add_n(out, in->text, (size_t)(open + 1 - in->text));
    cursor = open + 1;
    while (cursor < close) {
        const char *part_start = cursor;
        const char *part_end = cursor;
        int depth = 0;
        struct Text *part;

        while (part_end < close) {
            if (*part_end == '(' || *part_end == '[' || *part_end == '<') {
                depth++;
            } else if ((*part_end == ')' || *part_end == ']' || *part_end == '>') && depth > 0) {
                depth--;
            } else if (*part_end == ',' && depth == 0) {
                break;
            }
            part_end++;
        }
        part = text_new();
        text_add_n(part, part_start, (size_t)(part_end - part_start));
        part = rewrite_safe_reference_decl(part);
        text_add(out, part->text);
        text_free(part);
        if (part_end < close && *part_end == ',') {
            text_add_ch(out, ',');
            part_end++;
        }
        cursor = part_end;
    }
    text_add(out, close);
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(in);
    return out;
}

static void check_safe_pointer_decl(const char *s)
{
    struct DeclInfo decl;
    const char *name_pos;

    if (g_c_compat && g_unsafe_depth == 0) {
        return;
    }
    if (g_unsafe_depth > 0) {
        return;
    }
    if (!parse_decl(s, &decl) || !decl.is_decl || decl.name[0] == '\0') {
        return;
    }
    name_pos = find_decl_name_pos(s, decl.name);
    if (name_pos == NULL) {
        return;
    }
    if (pointer_token_before(s, name_pos)) {
        fprintf(stderr, "c-: type error: pointer declarations are only allowed inside unsafe; use Box<T> for ownership, ref T/mut ref T for parameters, or Ref/Span/Optional and checked collections\n");
        exit(1);
    }
}

static struct Text *rewrite_safe_reference_decl(struct Text *in)
{
    struct DeclInfo decl;
    const char *base = skip_ws(in->text);
    const char *base_end;
    struct Type base_type;
    const char *name_pos;
    const char *string_start;
    int string_borrowed;
    int explicit_ref;
    int mutable_ref;
    int explicit_box;
    char func_name[NAME_MAX_LEN];
    struct Type ret_type;

    if (g_c_compat && g_unsafe_depth == 0) {
        return in;
    }
    if (g_unsafe_depth > 0) {
        return in;
    }
    if (starts_word(base, "stack")) {
        fprintf(stderr, "c-: type error: 'stack Type name' syntax has been removed at %s:%d; use 'Type name'\n",
                g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    if (parse_function_signature(in->text, func_name, &ret_type)) {
        string_start = find_string_decl_keyword(base, &string_borrowed);
        if (string_start != NULL) {
            in = rewrite_string_decl_text(in, base, string_start, string_borrowed);
            return rewrite_safe_reference_params(in);
        }
        if (ret_type.kind == TY_STRUCT && ret_type.tag[0] != '\0') {
            name_pos = find_decl_name_pos(in->text, func_name);
            if (name_pos == NULL) {
                return in;
            }
            explicit_ref = has_decl_word_before(in->text, name_pos, "ref");
            mutable_ref = has_decl_word_before(in->text, name_pos, "mut");
            explicit_box = has_decl_word_before(in->text, name_pos, "Box");
            if (mutable_ref && !explicit_ref) {
                fprintf(stderr, "c-: type error: 'mut' must be followed by 'ref' in safe declarations\n");
                exit(1);
            }
            if (pointer_token_before(in->text, name_pos)) {
                fprintf(stderr, "c-: type error: pointer declarations are only allowed inside unsafe; use Box<T> for ownership, ref T/mut ref T for parameters, or Ref/Span/Optional and checked collections\n");
                exit(1);
            }
            if (parse_base_type_prefix(base, &base_end, &base_type) &&
                base_type.tag[0] != '\0' &&
                !starts_word(base, "struct") &&
                !starts_word(base, "union") &&
                !starts_word(base, "enum")) {
                if (explicit_ref) {
                    in = mutable_ref
                        ? rewrite_bare_struct_reference_decl(in, base, base_end, name_pos, base_type)
                        : rewrite_shared_struct_reference_decl(in, base, base_end, name_pos, base_type);
                } else if (explicit_box) {
                    in = rewrite_box_struct_decl(in, base, base_end, name_pos, base_type);
                } else if (is_heap_collection_type(base_type) || is_heap_payload_enum_type(base_type)) {
                    in = rewrite_bare_struct_reference_decl(in, base, base_end, name_pos, base_type);
                } else if (ret_type.ptr == 0 && is_safe_reference_type(ret_type)) {
                    in = rewrite_stack_struct_value_decl(in, base, base_end, name_pos, base_type);
                }
            } else if (ret_type.ptr == 0 &&
                       (is_heap_collection_type(ret_type) || is_heap_payload_enum_type(ret_type))) {
                in = insert_pointer_before_name(in, name_pos);
            } else if (explicit_ref || explicit_box) {
                in = insert_pointer_before_name(in, name_pos);
            }
        }
        return rewrite_safe_reference_params(in);
    }
    if (!parse_decl(in->text, &decl) || !decl.is_decl || decl.name[0] == '\0' || decl.is_array) {
        return in;
    }
    name_pos = find_decl_name_pos(in->text, decl.name);
    if (name_pos == NULL) {
        return in;
    }
    explicit_ref = has_decl_word_before(in->text, name_pos, "ref");
    mutable_ref = has_decl_word_before(in->text, name_pos, "mut");
    explicit_box = has_decl_word_before(in->text, name_pos, "Box");
    if (mutable_ref && !explicit_ref) {
        fprintf(stderr, "c-: type error: 'mut' must be followed by 'ref' in safe declarations\n");
        exit(1);
    }
    if (explicit_ref || explicit_box) {
        if (parse_base_type_prefix(base, &base_end, &base_type) &&
            base_type.tag[0] != '\0' &&
            !starts_word(base, "struct") &&
            !starts_word(base, "union") &&
            !starts_word(base, "enum")) {
            if (explicit_ref && !mutable_ref) {
                return rewrite_shared_struct_reference_decl(in, base, base_end, name_pos, base_type);
            }
            if (explicit_box) {
                return rewrite_box_struct_decl(in, base, base_end, name_pos, base_type);
            }
            return rewrite_bare_struct_reference_decl(in, base, base_end, name_pos, base_type);
        }
        return insert_pointer_before_name(in, name_pos);
    }
    if (pointer_token_before(in->text, name_pos)) {
        fprintf(stderr, "c-: type error: pointer declarations are only allowed inside unsafe; use Box<T> for ownership, ref T/mut ref T for parameters, or Ref/Span/Optional and checked collections\n");
        exit(1);
    }
    string_start = find_string_decl_keyword(base, &string_borrowed);
    if (string_start != NULL) {
        return rewrite_string_decl_text(in, base, string_start, string_borrowed);
    }
    if (decl.type.ptr == 0 && decl.type.kind == TY_STRUCT && strcmp(decl.type.tag, "Critical") == 0 &&
        parse_base_type_prefix(base, &base_end, &base_type) &&
        strcmp(base_type.tag, "Critical") == 0 &&
        !starts_word(base, "struct")) {
        return rewrite_critical_value_decl(in, base, base_end, name_pos);
    }
    if (decl.type.ptr == 0 && is_safe_reference_type(decl.type)) {
        if (parse_base_type_prefix(base, &base_end, &base_type) &&
            base_type.tag[0] != '\0' &&
            !starts_word(base, "struct") &&
            !starts_word(base, "union") &&
            !starts_word(base, "enum")) {
            if (is_heap_collection_type(base_type) || is_heap_payload_enum_type(base_type)) {
                return rewrite_bare_struct_reference_decl(in, base, base_end, name_pos, base_type);
            }
            return rewrite_stack_struct_value_decl(in, base, base_end, name_pos, base_type);
        }
        if (is_heap_collection_type(decl.type) || is_heap_payload_enum_type(decl.type)) {
            return insert_pointer_before_name(in, name_pos);
        }
        return in;
    }
    return in;
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
            if (owner_end > s) {
                char *owner_expr = xstrndup(s, (size_t)(owner_end - s));
                struct Type owner_type = expr_type(owner_expr);
                free(owner_expr);
                if (owner_type.kind == TY_STRUCT &&
                    struct_field_type(owner_type.tag, name, &field_type)) {
                    return field_type;
                }
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
    sym = symbol_find_or_current_param(name);
    if (sym == NULL) {
        return type_unknown();
    }
    t = sym->type;
    while (deref > 0 && t.ptr > 0) {
        t.ptr--;
        deref--;
    }
    if (t.ptr == 0) {
        t.raw_ptr = 0;
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
    if (bitflags_expr_type(p, &t)) {
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
                if (t.ptr == 0) {
                    t.raw_ptr = 0;
                }
                t.owned = 0;
                return t;
            }
        }
        return type_unknown();
    }
    if (is_ident_start((unsigned char)*p)) {
        const char *end = read_name(p, name);
        p = skip_ws(end);
        sym = symbol_find_or_current_param(name);
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
                struct FunctionParams *fn = function_params_find(name);
                if (fn != NULL) {
                    return fn->ret;
                }
                if (malloc_func_index(name) >= 0) {
                    return g_malloc_funcs.ret[malloc_func_index(name)];
                }
                return type_unknown();
            }
            return t;
        }
        if (bitflags_const_type(name, &t)) {
            return t;
        }
        if (*p == '(') {
            struct FunctionParams *fn = function_params_find(name);
            if (fn != NULL) {
                return fn->ret;
            }
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
    if (g_unsafe_depth == 0 && (lhs.raw_ptr || rhs.raw_ptr)) {
        fprintf(stderr, "c-: type error: raw pointer taint cannot cross safe assignment in %s; use unsafe or convert to a managed safe type\n",
                what);
        exit(1);
    }
    if (!type_compatible(lhs, rhs)) {
        type_error(what, lhs, rhs);
    }
}

static int looks_like_aggregate_head(const char *s)
{
    const char *p = skip_ws(s);
    char word[NAME_MAX_LEN];
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
    struct SafetyExprNode *safety_forest = safety_parse_forest(in->text);

    while (*p != '\0') {
        if (is_ident_start((unsigned char)*p)) {
            char name[NAME_MAX_LEN];
            char arg[NAME_MAX_LEN];
            const char *name_end = read_name(p, name);
            const char *after;
            const char *member;
            struct GenericTemplate *struct_tmpl = generic_find(&g_generic_structs, name);
            struct PayloadEnum *payload_en = payload_enum_find(name);
            int generic_expr_site = safety_ast_has_generic_start(safety_forest, p);

            if (struct_tmpl != NULL && parse_generic_angle_arg(name_end, arg, &after)) {
                if (strcmp(arg, struct_tmpl->param) == 0) {
                    text_add_n(out, p, (size_t)(after - p));
                    p = after;
                    continue;
                }
                member = skip_ws(after);
                if (*member == '.' && generic_expr_site) {
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
		                                register_function_params(concrete_head->text);
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
            if (payload_en != NULL && parse_generic_angle_arg(name_end, arg, &after)) {
                member = skip_ws(after);
                if (*member != '.') {
                    struct GenericInstance *inst = payload_enum_instance_get(payload_en, arg);
                    text_add(out, "struct ");
                    text_add(out, inst->concrete);
                    p = after;
                    continue;
                }
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
            int generic_expr_site = safety_ast_has_generic_start(safety_forest, p);

            if (tmpl != NULL && parse_generic_angle_arg(name_end, arg, &after)) {
                struct GenericInstance *inst = generic_instance_get(tmpl, arg);
                char func_param[NAME_MAX_LEN];
                const char *func_head = generic_template_body_start(tmpl->head, func_param);
                struct Text *concrete_head = replace_param_and_generics(func_head,
                                                                        tmpl->param,
                                                                        arg,
                                                                        tmpl->name,
                                                                        inst->concrete);
                register_function_params(concrete_head->text);
                text_free(concrete_head);
                call = skip_ws(after);
                if (*call == '(') {
                    if (!generic_expr_site) {
                        text_add_n(out, p, (size_t)(after - p));
                        p = after;
                        continue;
                    }
                    text_add(out, inst->concrete);
                    text_add_n(out, after, (size_t)(call - after));
                    p = call;
                    continue;
                }
                text_add(out, inst->concrete);
                p = after;
                continue;
            }
        }
        text_add_ch(out, *p++);
    }
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    safety_expr_free(safety_forest);
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
    if (strcmp(type_text->text, "string") == 0) {
        struct Text *normalized = text_new();
        text_add(normalized, "char*");
        text_free(type_text);
        type_text = normalized;
    }
    {
        const char *type_end;
        struct Type foreach_type;

        if (parse_base_type_prefix(type_text->text, &type_end, &foreach_type) &&
            *skip_ws(type_end) == '\0' &&
            foreach_type.ptr == 0 && is_safe_reference_type(foreach_type)) {
            struct Text *normalized = text_new();
            foreach_type.ptr++;
            append_c_type(normalized, foreach_type);
            text_free(type_text);
            type_text = normalized;
        }
    }

    id = g_foreach_id++;
    strcpy(data_op, ".");
    collection_sym = symbol_find_or_current_param(collection);
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

static void aggregate_ast_add(const char *tag, struct Node *node)
{
    int i;

    if (tag == NULL || tag[0] == '\0' || node == NULL) {
        return;
    }
    for (i = g_aggregate_asts.count - 1; i >= 0; i--) {
        if (strcmp(g_aggregate_asts.item[i].tag, tag) == 0) {
            g_aggregate_asts.item[i].node = node;
            return;
        }
    }
    if (g_aggregate_asts.count >= MAX_GENERIC_TEMPLATES) {
        die("too many aggregate AST definitions");
    }
    strncpy(g_aggregate_asts.item[g_aggregate_asts.count].tag,
            tag, NAME_MAX_LEN - 1);
    g_aggregate_asts.item[g_aggregate_asts.count].tag[NAME_MAX_LEN - 1] = '\0';
    g_aggregate_asts.item[g_aggregate_asts.count].node = node;
    g_aggregate_asts.count++;
}

static struct Node *aggregate_ast_find(const char *tag)
{
    int i;

    for (i = g_aggregate_asts.count - 1; i >= 0; i--) {
        if (strcmp(g_aggregate_asts.item[i].tag, tag) == 0) {
            return g_aggregate_asts.item[i].node;
        }
    }
    return NULL;
}

static int payload_generated_field_type(const char *tag, const char *field,
                                        struct Type *type)
{
    int i;

    for (i = 0; i < g_payload_enums.count; i++) {
        struct PayloadEnum *en = &g_payload_enums.en[i];
        int j;

        for (j = 0; j < en->inst_count; j++) {
            struct GenericInstance *inst = &en->inst[j];
            struct Text *payload_tag = text_new();
            int is_payload;

            text_add(payload_tag, inst->concrete);
            text_add(payload_tag, "_payload");
            is_payload = strcmp(tag, payload_tag->text) == 0;
            if (strcmp(tag, inst->concrete) == 0) {
                if (strcmp(field, "tag") == 0) {
                    *type = type_make(TY_INT, 0, NULL);
                    text_free(payload_tag);
                    return 1;
                }
                if (strcmp(field, "origin_kind") == 0 ||
                    strcmp(field, "origin_stack_id") == 0) {
                    *type = type_make(TY_LONG, 0, NULL);
                    text_free(payload_tag);
                    return 1;
                }
                if (strcmp(field, "payload") == 0 &&
                    payload_tag->len < NAME_MAX_LEN) {
                    *type = type_make(TY_STRUCT, 0, payload_tag->text);
                    text_free(payload_tag);
                    return 1;
                }
            } else if (is_payload) {
                struct PayloadVariant *variant =
                    payload_enum_variant_find(en, field);

                if (variant != NULL && variant->has_payload) {
                    struct Text *payload = replace_param_and_generics(
                        variant->payload, en->param, inst->arg,
                        en->name, inst->concrete);
                    struct Text *decl_text = text_new();
                    struct DeclInfo decl;

                    payload = remove_percent(strip_attributes(payload));
                    text_add(decl_text, payload->text);
                    text_add(decl_text, " value;");
                    if (parse_decl(decl_text->text, &decl) &&
                        decl.name[0] != '\0') {
                        *type = decl.type;
                        text_free(payload);
                        text_free(decl_text);
                        text_free(payload_tag);
                        return 1;
                    }
                    text_free(payload);
                    text_free(decl_text);
                }
            }
            text_free(payload_tag);
        }
    }
    return 0;
}

static int payload_generated_constant_type(const char *name,
                                           struct Type *type)
{
    int i;

    for (i = 0; i < g_payload_enums.count; i++) {
        struct PayloadEnum *en = &g_payload_enums.en[i];
        int j;

        for (j = 0; j < en->inst_count; j++) {
            int v;

            for (v = 0; v < en->variant_count; v++) {
                struct Text *constant = text_new();
                int match;

                text_add(constant, en->inst[j].concrete);
                text_add(constant, "_TAG_");
                text_add(constant, en->variant[v].name);
                match = strcmp(name, constant->text) == 0;
                text_free(constant);
                if (match) {
                    *type = type_make(TY_INT, 0, NULL);
                    return 1;
                }
            }
        }
    }
    return 0;
}

static int struct_field_type(const char *tag, const char *field, struct Type *type)
{
    struct Node *aggregate = aggregate_ast_find(tag);
    struct StructFinalizer *fin = struct_finalizer_find(tag);
    struct StructFinalizer *clone = struct_clone_find(tag);
    int i;

    if (aggregate != NULL) {
        struct Node *member;

        for (member = aggregate->body; member != NULL; member = member->next) {
            if (member->kind == ND_FIELD && member->ty != NULL &&
                strcmp(member->name, field) == 0) {
                *type = *member->ty;
                return 1;
            }
        }
    }

    if (payload_generated_field_type(tag, field, type)) {
        return 1;
    }

    if (strncmp(tag, "Ref_", 4) == 0) {
        if (strcmp(field, "data") == 0) {
            *type = type_make(TY_INT, 1, "");
            return 1;
        }
        if (strcmp(field, "origin_kind") == 0 ||
            strcmp(field, "origin_stack_id") == 0) {
            *type = type_make(TY_LONG, 0, "");
            return 1;
        }
    }
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
                type->is_array = clone->fields[i].is_array;
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

static void struct_clone_add_field(const char *tag, const char *field, struct Type type, int is_array)
{
    struct StructFinalizer *clone = struct_clone_get(tag);
    int i;

    if (field[0] == '\0') {
        return;
    }
    for (i = 0; i < clone->count; i++) {
        if (strcmp(clone->fields[i].name, field) == 0) {
            clone->fields[i].type = type;
            clone->fields[i].is_array = is_array;
            return;
        }
    }
    if (clone->count >= MAX_FIELDS) {
        die("too many fields in one struct clone");
    }
    strncpy(clone->fields[clone->count].name, field, NAME_MAX_LEN - 1);
    clone->fields[clone->count].name[NAME_MAX_LEN - 1] = '\0';
    clone->fields[clone->count].type = type;
    clone->fields[clone->count].is_array = is_array;
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
    g_moved_locals.count = 0;
    g_borrow_links.count = 0;
    g_locals.count = 0;
    g_function_returns_move = 0;
    g_current_function_name[0] = '\0';
    g_current_function_ret = type_unknown();
    g_current_function_stack_guard = 0;
    g_current_function_interrupt = 0;
    g_current_function_naked = 0;
    g_in_function = 1;
}

static void begin_top_block(struct Text *head)
{
    const char *head_start = skip_ws(head->text);
    char name[NAME_MAX_LEN];
    char param[NAME_MAX_LEN];
    struct Type ret;
    register_tags_in_text(head->text);
    g_current_generic_kind = 0;
    g_current_generic_param[0] = '\0';
    g_current_payload_enum = 0;
    g_current_bitflags = 0;
    g_current_bitflags_name[0] = '\0';
    g_current_bitflags_base[0] = '\0';
    g_current_struct_mmio = 0;
    if (is_unsafe_head(head->text) || is_inline_c_head(head->text)) {
        cminus_unsafe_push();
        g_top_block_is_function = 0;
        g_in_function = 0;
        g_in_aggregate_struct = 0;
        g_current_struct_tag[0] = '\0';
        return;
    }
    if (!g_c_compat && starts_word(head_start, "union")) {
        fprintf(stderr, "c-: type error: unions are only allowed inside unsafe at %s:%d; use a tagged enum in safe mode\n",
                g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    if (!g_c_compat && strstr(head->text, "...") != NULL &&
        !function_signature_is_internal(head->text)) {
        fprintf(stderr, "c-: type error: variadic functions are only allowed inside unsafe at %s:%d; expose a typed safe wrapper\n",
                g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    if (parse_bitflags_head(head->text, name, param)) {
        g_current_bitflags = 1;
        strncpy(g_current_bitflags_name, name, NAME_MAX_LEN - 1);
        g_current_bitflags_name[NAME_MAX_LEN - 1] = '\0';
        strncpy(g_current_bitflags_base, param, NAME_MAX_LEN - 1);
        g_current_bitflags_base[NAME_MAX_LEN - 1] = '\0';
        bitflags_add(name, param);
        g_top_block_is_function = 0;
        g_in_function = 0;
    } else if (parse_payload_enum_head(head->text, param, name)) {
        g_current_payload_enum = 1;
        strncpy(g_current_generic_param, param, NAME_MAX_LEN - 1);
        g_current_generic_param[NAME_MAX_LEN - 1] = '\0';
        g_top_block_is_function = 0;
        g_in_function = 0;
    } else if (parse_generic_struct_head(head->text, param, name)) {
        g_current_generic_kind = 1;
        strncpy(g_current_generic_param, param, NAME_MAX_LEN - 1);
        g_current_generic_param[NAME_MAX_LEN - 1] = '\0';
        g_top_block_is_function = 0;
    } else if (parse_generic_function_head(head->text, param, name)) {
        g_current_generic_kind = 2;
        strncpy(g_current_generic_param, param, NAME_MAX_LEN - 1);
        g_current_generic_param[NAME_MAX_LEN - 1] = '\0';
        g_top_block_is_function = 1;
    } else {
        g_top_block_is_function = parse_function_signature(head->text, name, &ret) || !looks_like_aggregate_head(head->text);
    }
    g_in_aggregate_struct = 0;
    g_current_struct_tag[0] = '\0';
    if (g_current_bitflags) {
        g_in_function = 0;
    } else if (g_current_payload_enum) {
        g_in_function = 0;
    } else if (g_current_generic_kind == 1) {
        g_in_function = 0;
    } else if (g_top_block_is_function) {
        const char *function_head = head->text;

        if (g_current_generic_kind == 2) {
            const char *generic_head = parse_generic_prefix(head->text, param);

            if (generic_head != NULL) {
                function_head = generic_head;
            }
        }
        begin_function();
        validate_interrupt_function_head(function_head);
        g_current_function_interrupt = function_decl_has_interrupt(function_head);
        g_current_function_naked = function_decl_has_naked(function_head);
        if (parse_function_signature(function_head, name, &ret)) {
            struct Text *normalized_head = text_new();
            text_add(normalized_head, function_head);
            if (g_current_generic_kind != 2) {
                normalized_head = rewrite_generics(normalized_head);
                normalized_head = rewrite_safe_reference_decl(normalized_head);
            }
            strncpy(g_current_function_name, name, NAME_MAX_LEN - 1);
            g_current_function_name[NAME_MAX_LEN - 1] = '\0';
            if (parse_function_signature(normalized_head->text, name, &ret)) {
                g_current_function_ret = ret;
            } else {
                g_current_function_ret = type_unknown();
            }
            register_function_params(normalized_head->text);
            if (head_function_name(normalized_head->text, name) &&
                !function_signature_is_internal(normalized_head->text)) {
                register_function_param_symbols(normalized_head->text);
                register_owned_parameter_cleanup(name);
            }
            text_free(normalized_head);
        }
        g_current_function_stack_guard = !g_current_function_interrupt &&
            !g_current_function_naked &&
            !function_signature_is_internal(function_head);
    } else if (parse_struct_head(head->text, name)) {
        const char *struct_name_pos = find_decl_name_pos(head->text, name);
        g_in_aggregate_struct = 1;
        g_current_struct_mmio = struct_name_pos != NULL &&
            has_decl_word_before(head->text, struct_name_pos, "mmio");
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

static int is_pthread_include(const char *line)
{
    const char *p = skip_ws(line);

    if (strncmp(p, "#include", 8) != 0) {
        return 0;
    }
    p = skip_ws(p + 8);
    return strncmp(p, "<pthread.h>", 11) == 0;
}

static int is_sched_include(const char *line)
{
    const char *p = skip_ws(line);

    if (strncmp(p, "#include", 8) != 0) {
        return 0;
    }
    p = skip_ws(p + 8);
    return strncmp(p, "<sched.h>", 9) == 0;
}

static int is_cbare_include(const char *line)
{
    const char *p = skip_ws(line);

    if (strncmp(p, "#include", 8) != 0) {
        return 0;
    }
    p = skip_ws(p + 8);
    return strncmp(p, "<c-bare.h>", 10) == 0;
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

static struct Text *consume_pp_line(struct Text *line)
{
    struct Node *node = ast_new(ND_DIRECTIVE, line->text);
    const char *p = skip_ws(node->tok);
    struct Text *out = text_new();

    if (*p == '#') {
        char directive[NAME_MAX_LEN];

        p = skip_ws(p + 1);
        if (is_ident_start((unsigned char)*p)) {
            const char *end = read_name(p, directive);

            strncpy(node->name, directive, NAME_MAX_LEN - 1);
            node->name[NAME_MAX_LEN - 1] = '\0';
            if (strcmp(directive, "define") == 0) {
                char macro[NAME_MAX_LEN];
                const char *macro_start = skip_ws(end);

                if (is_ident_start((unsigned char)*macro_start)) {
                    read_name(macro_start, macro);
                    strncat(node->name, " ", NAME_MAX_LEN - strlen(node->name) - 1);
                    strncat(node->name, macro, NAME_MAX_LEN - strlen(node->name) - 1);
                }
            }
        }
    }
    g_consumed_directives = ast_append(g_consumed_directives, node);
    text_free(line);
    return out;
}

static struct Text *process_pp_line(struct Text *line)
{
    char include_path[256];
    FILE *fp;
    const char *p = skip_ws(line->text);

    if (g_c_compat && !g_bare_metal && cminus_include_depth() == 0) {
        if (parse_cminus_include(line->text, include_path, sizeof(include_path))) {
            fp = open_cminus_include(include_path);
            if (fp == NULL) {
                fprintf(stderr, "c-: include not found: %s\n", include_path);
                text_free(line);
                exit(1);
            }
            cminus_push_include(fp, 1);
            return consume_pp_line(line);
        }
        return line;
    }
    if (strncmp(p, "#define CMINUS_THREAD_LOCAL", 27) == 0 && g_bare_metal) {
        text_add(g_defines, "#define CMINUS_THREAD_LOCAL\n");
        return consume_pp_line(line);
    }
    if (strncmp(p, "#define", 7) == 0) {
        text_add(g_defines, line->text);
        if (line->len == 0 || line->text[line->len - 1] != '\n') {
            text_add_ch(g_defines, '\n');
        }
        return consume_pp_line(line);
    }
    if (is_stdlib_include(line->text)) {
        g_need_stdlib_h = 1;
        return consume_pp_line(line);
    }
    if (is_string_include(line->text)) {
        g_need_string_h = 1;
        return consume_pp_line(line);
    }
    if (is_stdio_include(line->text)) {
        g_need_stdio_h = 1;
        return consume_pp_line(line);
    }
    if (is_execinfo_include(line->text)) {
        g_need_execinfo_h = 1;
        return consume_pp_line(line);
    }
    if (is_pthread_include(line->text)) {
        g_need_pthread_h = 1;
        return consume_pp_line(line);
    }
    if (is_sched_include(line->text)) {
        g_need_sched_h = 1;
        return consume_pp_line(line);
    }
    /*
     * <c-bare.h> is the freestanding runtime. It is inlined by -bare, so an
     * explicit include is redundant; drop it either way so it never leaks into
     * the output as an unresolved system include.
     */
    if (is_cbare_include(line->text)) {
        return consume_pp_line(line);
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
    cminus_push_include(fp, 1);
    return consume_pp_line(line);
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

static int moved_local_index(const char *name)
{
    int i;

    for (i = 0; i < g_moved_locals.count; i++) {
        if (strcmp(g_moved_locals.name[i], name) == 0) {
            return i;
        }
    }
    return -1;
}

static void moved_local_add(const char *name)
{
    if (name[0] == '\0' || moved_local_index(name) >= 0) {
        return;
    }
    if (g_moved_locals.count >= MAX_OWNED) {
        die("too many moved locals in one function");
    }
    strncpy(g_moved_locals.name[g_moved_locals.count], name, NAME_MAX_LEN - 1);
    g_moved_locals.name[g_moved_locals.count][NAME_MAX_LEN - 1] = '\0';
    g_moved_locals.count++;
}

static void moved_local_remove(const char *name)
{
    int index = moved_local_index(name);
    int i;

    if (index < 0) {
        return;
    }
    for (i = index; i + 1 < g_moved_locals.count; i++) {
        strcpy(g_moved_locals.name[i], g_moved_locals.name[i + 1]);
    }
    g_moved_locals.count--;
}

static int borrow_link_index(const char *borrower)
{
    int i;

    for (i = 0; i < g_borrow_links.count; i++) {
        if (strcmp(g_borrow_links.borrower[i], borrower) == 0) {
            return i;
        }
    }
    return -1;
}

static int owner_is_tracked_owned(const char *owner)
{
    struct Symbol *sym;

    if (owner[0] == '\0') {
        return 0;
    }
    if (owned_index_in(&g_owned, owner) >= 0) {
        return 1;
    }
    sym = symbol_find(owner);
    return sym != NULL && sym->type.ptr > 0 && sym->type.owned;
}

static int owner_is_local_stack(const char *owner)
{
    struct Symbol *sym;

    if (owner[0] == '\0' || owned_index_in(&g_owned, owner) >= 0) {
        return 0;
    }
    sym = symbol_find(owner);
    return sym != NULL && sym->var != NULL && sym->var->is_local && !sym->var->is_param && !sym->type.owned;
}

static void borrow_link_remove_borrower(const char *borrower)
{
    int index = borrow_link_index(borrower);
    int i;

    if (index < 0) {
        return;
    }
    for (i = index; i + 1 < g_borrow_links.count; i++) {
        strcpy(g_borrow_links.borrower[i], g_borrow_links.borrower[i + 1]);
        strcpy(g_borrow_links.owner[i], g_borrow_links.owner[i + 1]);
        g_borrow_links.dead[i] = g_borrow_links.dead[i + 1];
        g_borrow_links.stack_owner[i] = g_borrow_links.stack_owner[i + 1];
    }
    g_borrow_links.count--;
}

static void borrow_link_add(const char *borrower, const char *owner)
{
    int index;

    if (borrower[0] == '\0' || owner[0] == '\0' || strcmp(borrower, owner) == 0) {
        return;
    }
    if (!owner_is_tracked_owned(owner) && !owner_is_local_stack(owner)) {
        return;
    }
    index = borrow_link_index(borrower);
    if (index < 0) {
        if (g_borrow_links.count >= MAX_OWNED) {
            die("too many borrow links in one function");
        }
        index = g_borrow_links.count++;
    }
    strncpy(g_borrow_links.borrower[index], borrower, NAME_MAX_LEN - 1);
    g_borrow_links.borrower[index][NAME_MAX_LEN - 1] = '\0';
    strncpy(g_borrow_links.owner[index], owner, NAME_MAX_LEN - 1);
    g_borrow_links.owner[index][NAME_MAX_LEN - 1] = '\0';
    g_borrow_links.dead[index] = 0;
    g_borrow_links.stack_owner[index] = owner_is_local_stack(owner);
}

static void borrow_links_invalidate_owner(const char *owner)
{
    int i;

    if (owner[0] == '\0') {
        return;
    }
    for (i = 0; i < g_borrow_links.count; i++) {
        if (strcmp(g_borrow_links.owner[i], owner) == 0) {
            g_borrow_links.dead[i] = 1;
        }
    }
}

static void check_dead_borrow_use(const char *stmt)
{
    int i;

    if (g_unsafe_depth > 0) {
        return;
    }
    for (i = 0; i < g_borrow_links.count; i++) {
        if (g_borrow_links.dead[i] &&
            word_occurs_after_first_token(stmt, g_borrow_links.borrower[i])) {
            fprintf(stderr, "c-: type error: borrowed value '%s' is used after owner '%s' was released at %s:%d\n",
                    g_borrow_links.borrower[i], g_borrow_links.owner[i],
                    g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
    }
}

static void check_borrow_escape_return(const char *stmt)
{
    int i;
    char owner[NAME_MAX_LEN];
    const char *expr;

    if (g_unsafe_depth > 0) {
        return;
    }
    expr = skip_ws(stmt);
    if (starts_word(expr, "return")) {
        expr = skip_ws(expr + 6);
    }
    if (extract_safe_reference_borrow_owner(expr, owner) &&
        (owner_is_local_stack(owner) || owner_is_tracked_owned(owner))) {
        fprintf(stderr, "c-: type error: value '%s' cannot escape through returned safe reference at %s:%d\n",
                owner, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    for (i = 0; i < g_borrow_links.count; i++) {
        const char *p = expr;
        size_t n = strlen(g_borrow_links.borrower[i]);

        if ((g_borrow_links.stack_owner[i] || owner_is_tracked_owned(g_borrow_links.owner[i])) && n > 0 &&
            strncmp(p, g_borrow_links.borrower[i], n) == 0 &&
            !is_ident((unsigned char)p[n])) {
            p = skip_ws(p + n);
            if (*p != ';' && *p != '\0') {
                continue;
            }
            fprintf(stderr, "c-: type error: borrowed value '%s' from '%s' cannot be returned at %s:%d\n",
                    g_borrow_links.borrower[i], g_borrow_links.owner[i],
                    g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
    }
}

static int extract_direct_borrow_owner(const char *expr, char *owner)
{
    return safety_ast_borrow_root(expr, expr + strlen(expr), owner);
}

static int extract_safe_reference_borrow_owner(const char *expr, char *owner)
{
    return safety_ast_reference_borrow_owner(expr, owner);
}

static int word_occurs_after_first_token(const char *stmt, const char *word)
{
    const char *p = skip_ws(stmt);
    size_t n = strlen(word);

    if (is_ident_start((unsigned char)*p)) {
        char first[NAME_MAX_LEN];
        const char *end = read_name(p, first);
        const char *after = skip_ws(end);

        /* Reassignment revives a moved variable.  Only skip a plain lhs;
         * member/index access still reads the moved object and must fail. */
        if (strcmp(first, word) == 0 && *after == '=' && after[1] != '=') {
            p = after + 1;
        }
    }

    while ((p = strstr(p, word)) != NULL) {
        if ((p == stmt || (!is_ident((unsigned char)p[-1]) && p[-1] != '.' && p[-1] != '>')) &&
            !is_ident((unsigned char)p[n])) {
            const char *q = p;

            while (q > stmt && isspace((unsigned char)q[-1])) {
                q--;
            }
            if (q >= stmt + 4 &&
                strncmp(q - 4, "move", 4) == 0 &&
                (q - 4 == stmt || !is_ident((unsigned char)q[-5]))) {
                p += n;
                continue;
            }
            return 1;
        }
        p += n;
    }
    return 0;
}

static void check_moved_local_use(const char *stmt)
{
    int i;
    char moved[NAME_MAX_LEN];

    if (g_unsafe_depth > 0) {
        return;
    }
    check_owned_call_arguments(stmt);
    if (extract_move_name(stmt, moved) && moved_local_index(moved) >= 0) {
        fprintf(stderr, "c-: type error: use of moved value '%s' at %s:%d\n",
                moved, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    for (i = 0; i < g_moved_locals.count; i++) {
        if (word_occurs_after_first_token(stmt, g_moved_locals.name[i])) {
            fprintf(stderr, "c-: type error: use of moved value '%s' at %s:%d\n",
                    g_moved_locals.name[i], g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
    }
}

static void check_owned_call_expression(struct SafetyExprNode *expr)
{
    for (; expr != NULL; expr = expr->next) {
        if (expr->kind == SAFETY_EXPR_CALL) {
            const struct SafetyExprNode *callee = safety_strip_groups(expr->lhs);
            struct FunctionParams *fn = NULL;

            while (callee != NULL && callee->kind == SAFETY_EXPR_GENERIC) {
                callee = safety_strip_groups(callee->lhs);
            }
            if (callee != NULL && callee->kind == SAFETY_EXPR_IDENTIFIER) {
                fn = function_params_find(callee->name);
            }
            if (fn != NULL) {
                const struct SafetyExprNode *argument = expr->child;
                int index = 0;

                for (; argument != NULL; argument = argument->next, index++) {
                    const struct SafetyExprNode *value =
                        safety_strip_groups(argument);
                    int moved = value != NULL &&
                        value->kind == SAFETY_EXPR_MOVE;
                    int owned_rvalue = value != NULL &&
                        value->kind != SAFETY_EXPR_IDENTIFIER &&
                        value->kind != SAFETY_EXPR_MEMBER &&
                        value->kind != SAFETY_EXPR_INDEX &&
                        value->kind != SAFETY_EXPR_FIXED_INDEX &&
                        (value->type.ptr == 0 || value->type.owned);

                    if (!owned_rvalue && argument->start != NULL &&
                        argument->end != NULL && argument->end > argument->start) {
                        char *argument_text = xstrndup(
                            argument->start,
                            (size_t)(argument->end - argument->start));
                        struct Type produced_type;
                        const char *argument_value = skip_ws(argument_text);

                        owned_rvalue =
                            starts_word(argument_value, "new") ||
                            starts_word(argument_value, "clone") ||
                            rhs_has_new_expr(argument_text, &produced_type) ||
                            rhs_has_clone_expr(argument_text, &produced_type) ||
                            rhs_is_single_owned_return_call(argument_text) ||
                            text_has_s_string(argument_text);
                        free(argument_text);
                    }

                    if (index < fn->count && fn->param[index].owned &&
                        !moved && !owned_rvalue) {
                        fprintf(stderr,
                                "c-: ownership error: call to '%s' parameter %d takes ownership; pass 'move value' at %s:%d\n",
                                callee->name, index + 1,
                                g_input_path == NULL ? "<unknown>" : g_input_path,
                                yylineno);
                        exit(1);
                    }
                }
            }
        }
        check_owned_call_expression(expr->lhs);
        check_owned_call_expression(expr->rhs);
        check_owned_call_expression(expr->child);
    }
}

static void check_owned_call_arguments(const char *stmt)
{
    struct SafetyExprNode *forest = safety_parse_forest(stmt);

    check_owned_call_expression(forest);
    safety_expr_free(forest);
}

static int rhs_is_null_literal(const char *rhs)
{
    const char *p = skip_ws(rhs);

    if (starts_word(p, "NULL")) {
        p = skip_ws(p + 4);
        return *p == '\0' || *p == ';';
    }
    if (starts_word(p, "null")) {
        p = skip_ws(p + 4);
        return *p == '\0' || *p == ';';
    }
    return 0;
}

static int type_is_optional(struct Type type)
{
    struct GenericInstance *inst = NULL;
    struct GenericTemplate *tmpl;
    int i;
    int j;

    if (type.kind != TY_STRUCT) {
        return 0;
    }
    tmpl = generic_struct_find_by_concrete(type.tag, &inst);
    if (tmpl != NULL && inst != NULL && strcmp(tmpl->name, "Optional") == 0) {
        return 1;
    }
    for (i = 0; i < g_payload_enums.count; i++) {
        struct PayloadEnum *en = &g_payload_enums.en[i];

        if (strcmp(en->name, "Optional") != 0) {
            continue;
        }
        for (j = 0; j < en->inst_count; j++) {
            if (strcmp(en->inst[j].concrete, type.tag) == 0) {
                return 1;
            }
        }
    }
    return 0;
}

static void check_null_assignment(const char *stmt)
{
    int eq;
    char lhs_name[NAME_MAX_LEN];
    struct DeclInfo decl;
    struct Type lhs_type;

    if (g_unsafe_depth > 0) {
        return;
    }
    eq = find_assignment(stmt);
    if (eq < 0 || !rhs_is_null_literal(stmt + eq + 1)) {
        return;
    }
    if (parse_decl(stmt, &decl) && decl.is_decl && decl.name[0] != '\0') {
        lhs_type = decl.type;
    } else {
        if (!extract_lhs_name(stmt, eq, lhs_name)) {
            return;
        }
        if (moved_local_index(lhs_name) >= 0) {
            moved_local_remove(lhs_name);
            return;
        }
        lhs_type = lhs_type_before_eq(stmt, eq, lhs_name);
    }
    if (!type_is_optional(lhs_type)) {
        fprintf(stderr, "c-: type error: NULL is only allowed for Optional in safe mode at %s:%d; use Optional<T>.None()\n",
                g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
}

static void append_optional_none_expr(struct Text *out, struct Type type)
{
    text_add(out, type.tag);
    text_add(out, "_None()");
}

static struct Text *rewrite_optional_null_assignment(struct Text *in)
{
    int eq = find_assignment(in->text);
    char lhs_name[NAME_MAX_LEN];
    struct DeclInfo decl;
    struct Type lhs_type;
    struct Text *out;

    if (g_unsafe_depth > 0 || eq < 0 || !rhs_is_null_literal(in->text + eq + 1)) {
        return in;
    }
    if (parse_decl(in->text, &decl) && decl.is_decl && decl.name[0] != '\0') {
        lhs_type = decl.type;
    } else {
        if (!extract_lhs_name(in->text, eq, lhs_name)) {
            return in;
        }
        lhs_type = lhs_type_before_eq(in->text, eq, lhs_name);
    }
    if (!type_is_optional(lhs_type)) {
        return in;
    }
    out = text_new();
    text_add_n(out, in->text, (size_t)(eq + 1));
    text_add_ch(out, ' ');
    append_optional_none_expr(out, lhs_type);
    text_add(out, ";");
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(in);
    return out;
}

static struct Text *rewrite_optional_null_return(struct Text *in)
{
    const char *p = skip_ws(in->text);
    const char *expr;
    struct Text *out;

    if (g_unsafe_depth > 0 || !starts_word(p, "return") || !type_is_optional(g_current_function_ret)) {
        return in;
    }
    expr = skip_ws(p + 6);
    if (!rhs_is_null_literal(expr)) {
        return in;
    }
    out = text_new();
    append_leading_newlines(in->text, out);
    append_indent_from(in->text, out);
    text_add(out, "return ");
    append_optional_none_expr(out, g_current_function_ret);
    text_add(out, ";");
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(in);
    return out;
}

static int token_is_control_keyword(const char *name)
{
    return strcmp(name, "if") == 0 ||
        strcmp(name, "while") == 0 ||
        strcmp(name, "for") == 0 ||
        strcmp(name, "switch") == 0 ||
        strcmp(name, "return") == 0 ||
        strcmp(name, "sizeof") == 0;
}

static int args_contain_top_level_null(const char *start, const char *end)
{
    const char *p = start;

    while (p < end) {
        const char *arg_end = find_top_level_char(p, end, ',');
        const char *q;
        const char *r;

        if (arg_end == NULL) {
            arg_end = end;
        }
        q = skip_ws(p);
        r = arg_end;
        while (r > q && isspace((unsigned char)r[-1])) {
            r--;
        }
        if ((r - q == 4 && strncmp(q, "NULL", 4) == 0) ||
            (r - q == 4 && strncmp(q, "null", 4) == 0)) {
            return 1;
        }
        p = arg_end;
        if (p < end && *p == ',') {
            p++;
        }
    }
    return 0;
}

static void check_null_arguments(const char *stmt)
{
    const char *p = stmt;

    if (g_unsafe_depth > 0) {
        return;
    }
    while (*p != '\0') {
        char name[NAME_MAX_LEN];
        const char *name_end;
        const char *open;
        const char *close;

        if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            p++;
            continue;
        }
        name_end = read_name(p, name);
        open = skip_ws(name_end);
        if (*open != '(' || token_is_control_keyword(name)) {
            p = name_end;
            continue;
        }
        close = matching_paren(open);
        if (close == NULL) {
            return;
        }
        if (args_contain_top_level_null(open + 1, close)) {
            fprintf(stderr, "c-: type error: NULL function argument is only allowed for Optional in safe mode at %s:%d\n",
                    g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
        p = close + 1;
    }
}

static int parse_int_literal_arg(const char *start, const char *end, long *value)
{
    const char *p = skip_ws(start);
    char *tail;
    long v;

    while (end > p && isspace((unsigned char)end[-1])) {
        end--;
    }
    if (p >= end || (!isdigit((unsigned char)*p) && *p != '+')) {
        return 0;
    }
    v = strtol(p, &tail, 10);
    tail = (char*)skip_ws(tail);
    if (tail != end) {
        return 0;
    }
    *value = v;
    return 1;
}

static int parse_array_expr_arg(const char *start, const char *end, char *label, struct Type *type, int *is_local)
{
    const char *p = skip_ws(start);
    const char *name_end;
    char name[NAME_MAX_LEN];
    struct Symbol *sym;
    struct Type current;

    while (end > p && isspace((unsigned char)end[-1])) {
        end--;
    }
    if (!is_ident_start((unsigned char)*p)) {
        return 0;
    }
    name_end = read_name(p, name);
    sym = symbol_find_or_current_param(name);
    if (sym == NULL) {
        return 0;
    }
    current = sym->type;
    if (is_local != NULL) {
        *is_local = sym->var != NULL && sym->var->is_local && !sym->var->is_param;
    }
    if (label != NULL) {
        strncpy(label, name, NAME_MAX_LEN - 1);
        label[NAME_MAX_LEN - 1] = '\0';
    }
    p = name_end;
    while (p < end && isspace((unsigned char)*p)) {
        p++;
    }
    while (p < end && (*p == '.' || (p[0] == '-' && p[1] == '>'))) {
        const char *field_start = skip_ws(*p == '.' ? p + 1 : p + 2);
        const char *field_end;
        char field[NAME_MAX_LEN];
        size_t used;

        if (!is_ident_start((unsigned char)*field_start)) {
            return 0;
        }
        field_end = read_name(field_start, field);
        if (current.kind != TY_STRUCT || !struct_field_type(current.tag, field, &current)) {
            return 0;
        }
        if (label != NULL) {
            used = strlen(label);
            if (used + 1 < NAME_MAX_LEN) {
                if (p[0] == '-' && p[1] == '>') {
                    label[used++] = '-';
                    if (used + 1 < NAME_MAX_LEN) {
                        label[used++] = '>';
                    }
                } else {
                    label[used++] = '.';
                }
                label[used] = '\0';
                strncat(label, field, NAME_MAX_LEN - used - 1);
            }
        }
        p = field_end;
        while (p < end && isspace((unsigned char)*p)) {
            p++;
        }
    }
    if (p != end || !current.is_array) {
        return 0;
    }
    if (type != NULL) {
        *type = current;
    }
    return 1;
}

static int parse_sizeof_array_arg(const char *start, const char *end, char *label, struct Type *type)
{
    const char *p = skip_ws(start);
    const char *open;
    const char *close;

    while (end > p && isspace((unsigned char)end[-1])) {
        end--;
    }
    if (!starts_word(p, "sizeof")) {
        return 0;
    }
    open = skip_ws(p + 6);
    if (*open != '(') {
        return 0;
    }
    close = matching_paren(open);
    if (close == NULL || close + 1 != end) {
        return 0;
    }
    return parse_array_expr_arg(open + 1, close, label, type, NULL);
}

static int parse_local_stack_lvalue_arg(const char *start, const char *end, char *label);

static int parse_sizeof_local_lvalue_arg(const char *start, const char *end, char *label)
{
    const char *p = skip_ws(start);
    const char *open;
    const char *close;

    while (end > p && isspace((unsigned char)end[-1])) {
        end--;
    }
    if (!starts_word(p, "sizeof")) {
        return 0;
    }
    open = skip_ws(p + 6);
    if (*open != '(') {
        return 0;
    }
    close = matching_paren(open);
    if (close == NULL || close + 1 != end) {
        return 0;
    }
    return parse_local_stack_lvalue_arg(open + 1, close, label);
}

static void check_span_stack_array_call(const char *func_name, const char *args_start, const char *args_end)
{
    const char *arg1_end = find_top_level_char(args_start, args_end, ',');
    const char *arg2_start;
    const char *arg2_end;
    char array_label[NAME_MAX_LEN];
    char sizeof_label[NAME_MAX_LEN];
    struct Type array_type;
    struct Type sizeof_type;
    long value;
    int is_bytes;
    long max_bytes;
    int is_local = 0;

    if (arg1_end == NULL) {
        return;
    }
    arg2_start = arg1_end + 1;
    arg2_end = find_top_level_char(arg2_start, args_end, ',');
    if (arg2_end == NULL) {
        arg2_end = args_end;
    }
    if (!parse_array_expr_arg(args_start, arg1_end, array_label, &array_type, &is_local)) {
        return;
    }
    if (strchr(array_label, '.') == NULL && strstr(array_label, "->") == NULL && !is_local) {
        return;
    }
    is_bytes = strncmp(func_name, "Span_from_bytes_", 16) == 0 ||
        strncmp(func_name, "Span_map_from_", 14) == 0 ||
        strncmp(func_name, "RingBuffer_from_bytes_", 22) == 0 ||
        strcmp(func_name, "Bitmap_from_bytes") == 0;
    if (is_bytes && parse_sizeof_array_arg(arg2_start, arg2_end, sizeof_label, &sizeof_type)) {
        if (strcmp(sizeof_label, array_label) == 0 && sizeof_type.array_len == array_type.array_len) {
            return;
        }
    }
    if (!parse_int_literal_arg(arg2_start, arg2_end, &value)) {
        return;
    }
    if (strcmp(func_name, "Bitmap_from") == 0) {
        max_bytes = (long)array_type.array_len * (long)(array_type.size > 0 ? array_type.size : 1) * 8L;
        if (value > max_bytes) {
            fprintf(stderr, "c-: type error: Bitmap.from bit length %ld exceeds array '%s' capacity %ld bits at %s:%d\n",
                    value, array_label, max_bytes, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
    } else if (strcmp(func_name, "Bitmap_from_words") == 0) {
        if (value > array_type.array_len) {
            fprintf(stderr, "c-: type error: Bitmap.from_words length %ld exceeds array '%s' length %d at %s:%d\n",
                    value, array_label, array_type.array_len, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
    } else if (is_bytes) {
        max_bytes = (long)array_type.array_len * (long)(array_type.size > 0 ? array_type.size : 1);
        if (value > max_bytes) {
            fprintf(stderr, "c-: type error: buffer from_bytes length %ld exceeds array '%s' size %ld bytes at %s:%d\n",
                    value, array_label, max_bytes, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
    } else if (value > array_type.array_len) {
        fprintf(stderr, "c-: type error: buffer from length %ld exceeds array '%s' length %d at %s:%d\n",
                value, array_label, array_type.array_len, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
}

static int is_bounded_array_output_call(const char *name)
{
    return strncmp(name, "RingBuffer_drain_to_span_", 25) == 0 ||
        strncmp(name, "List_to_span_", 13) == 0 ||
        strncmp(name, "Map_keys_to_span_", 17) == 0 ||
        strncmp(name, "Map_values_to_span_", 19) == 0;
}

static void check_span_stack_array_bounds(const char *stmt)
{
    const char *p = stmt;

    if (g_unsafe_depth > 0) {
        return;
    }
    while (*p != '\0') {
        char name[NAME_MAX_LEN];
        const char *name_end;
        const char *open;
        const char *close;

        if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            p++;
            continue;
        }
        name_end = read_name(p, name);
        open = skip_ws(name_end);
        if (*open == '(' && is_bounded_array_output_call(name)) {
            const char *arg1_end;
            const char *arg2_end;
            const char *arg3_end;
            char array_label[NAME_MAX_LEN];
            struct Type array_type;
            long cap;

            close = matching_paren(open);
            if (close == NULL) {
                return;
            }
            arg1_end = find_top_level_char(open + 1, close, ',');
            arg2_end = arg1_end == NULL ? NULL : find_top_level_char(arg1_end + 1, close, ',');
            arg3_end = arg2_end == NULL ? NULL : find_top_level_char(arg2_end + 1, close, ',');
            if (arg1_end != NULL && arg2_end != NULL && arg3_end == NULL &&
                parse_array_expr_arg(arg1_end + 1, arg2_end, array_label, &array_type, NULL)) {
                if (!parse_int_literal_arg(arg2_end + 1, close, &cap)) {
                    fprintf(stderr, "c-: type error: variable output capacity for fixed array '%s' is not allowed in safe mode at %s:%d; create a Span first\n",
                            array_label, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
                    exit(1);
                }
                if (cap < 0 || cap > array_type.array_len) {
                    fprintf(stderr, "c-: type error: output capacity %ld exceeds array '%s' length %d at %s:%d\n",
                            cap, array_label, array_type.array_len,
                            g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
                    exit(1);
                }
            }
            p = close + 1;
            continue;
        }
        if (*open == '(' &&
            (strncmp(name, "Span_from_", 10) == 0 || strncmp(name, "Span_from_bytes_", 16) == 0 ||
             strncmp(name, "Span_map_from_", 14) == 0 ||
             strncmp(name, "RingBuffer_from_", 16) == 0 || strncmp(name, "RingBuffer_from_bytes_", 22) == 0 ||
             strcmp(name, "Bitmap_from") == 0 || strcmp(name, "Bitmap_from_words") == 0 ||
             strcmp(name, "Bitmap_from_bytes") == 0)) {
            close = matching_paren(open);
            if (close == NULL) {
                return;
            }
            check_span_stack_array_call(name, open + 1, close);
            p = close + 1;
            continue;
        }
        p = name_end;
    }
}

static int is_stack_lifetime_from_call(const char *name)
{
    return strncmp(name, "Ref_from_", 9) == 0 ||
        strncmp(name, "Span_from_", 10) == 0 ||
        strncmp(name, "Span_from_bytes_", 16) == 0 ||
        strncmp(name, "Span_map_from_", 14) == 0 ||
        strncmp(name, "FixedVec_from_", 14) == 0 ||
        strncmp(name, "FixedVec_from_bytes_", 20) == 0 ||
        strncmp(name, "RingBuffer_from_", 16) == 0 ||
        strncmp(name, "RingBuffer_from_bytes_", 22) == 0 ||
        strcmp(name, "Bitmap_from") == 0 ||
        strcmp(name, "Bitmap_from_words") == 0 ||
        strcmp(name, "Bitmap_from_bytes") == 0;
}

static int parse_local_stack_lvalue_arg(const char *start, const char *end, char *label)
{
    const char *p = skip_ws(start);
    const char *name_end;
    char name[NAME_MAX_LEN];
    struct Symbol *sym;
    struct Type current;

    while (end > p && isspace((unsigned char)end[-1])) {
        end--;
    }
    if (!is_ident_start((unsigned char)*p)) {
        return 0;
    }
    name_end = read_name(p, name);
    sym = symbol_find(name);
    if (sym == NULL || sym->var == NULL || !sym->var->is_local || sym->var->is_param) {
        return 0;
    }
    current = sym->type;
    strncpy(label, name, NAME_MAX_LEN - 1);
    label[NAME_MAX_LEN - 1] = '\0';
    p = skip_ws(name_end);
    while (p < end && *p == '.') {
        const char *field_start = skip_ws(p + 1);
        const char *field_end;
        char field[NAME_MAX_LEN];
        size_t used;

        if (!is_ident_start((unsigned char)*field_start)) {
            return 0;
        }
        field_end = read_name(field_start, field);
        if (current.kind != TY_STRUCT || !struct_field_type(current.tag, field, &current)) {
            return 0;
        }
        used = strlen(label);
        if (used + 1 < NAME_MAX_LEN) {
            label[used++] = '.';
            label[used] = '\0';
            strncat(label, field, NAME_MAX_LEN - used - 1);
        }
        p = skip_ws(field_end);
    }
    return p == end;
}

static int stack_lifetime_note_arg(const char *func_name, const char *args_start, const char *args_end, char *expr, int *needs_address)
{
    const char *arg1_end = find_top_level_char(args_start, args_end, ',');
    const char *first_end = arg1_end == NULL ? args_end : arg1_end;
    const char *arg2_start = arg1_end == NULL ? NULL : arg1_end + 1;
    const char *arg2_end = NULL;
    char label[NAME_MAX_LEN];
    char sizeof_label[NAME_MAX_LEN];
    struct Type array_type;
    int is_local = 0;
    int is_bytes_call;

    if (needs_address != NULL) {
        *needs_address = 0;
    }
    if (arg2_start != NULL) {
        arg2_end = find_top_level_char(arg2_start, args_end, ',');
        if (arg2_end == NULL) {
            arg2_end = args_end;
        }
    }
    if (strncmp(func_name, "Ref_from_", 9) == 0) {
        const char *p = skip_ws(args_start);

        if (*p != '&') {
            return 0;
        }
        if (!parse_local_stack_lvalue_arg(p + 1, first_end, label)) {
            return 0;
        }
        if (strstr(label, "->") != NULL) {
            return 0;
        }
        snprintf(expr, NAME_MAX_LEN, "%s", label);
        if (needs_address != NULL) {
            *needs_address = 1;
        }
        return 1;
    }
    is_bytes_call = strncmp(func_name, "Span_from_bytes_", 16) == 0 ||
        strncmp(func_name, "Span_map_from_", 14) == 0 ||
        strncmp(func_name, "FixedVec_from_bytes_", 20) == 0 ||
        strncmp(func_name, "RingBuffer_from_bytes_", 22) == 0 ||
        strcmp(func_name, "Bitmap_from_bytes") == 0;
    if (!parse_array_expr_arg(args_start, first_end, label, &array_type, &is_local) || !is_local) {
        if (!parse_local_stack_lvalue_arg(args_start, first_end, label)) {
            return 0;
        }
        if (is_bytes_call && arg2_start != NULL &&
            parse_sizeof_local_lvalue_arg(arg2_start, arg2_end, sizeof_label) &&
            strcmp(label, sizeof_label) != 0) {
            return 0;
        }
    }
    if (strstr(label, "->") != NULL) {
        return 0;
    }
    (void)array_type;
    snprintf(expr, NAME_MAX_LEN, "%s", label);
    return 1;
}

static struct Text *rewrite_stack_lifetime_from_calls(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    while (*p != '\0') {
        char name[NAME_MAX_LEN];
        const char *name_end;
        const char *open;
        const char *close;
        char note_expr[NAME_MAX_LEN];
        int needs_address = 0;

        if (*p == '"' || *p == '\'') {
            char quote = *p;
            text_add_ch(out, *p++);
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    text_add_ch(out, *p++);
                    text_add_ch(out, *p++);
                    continue;
                }
                text_add_ch(out, *p);
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            text_add_ch(out, *p++);
            continue;
        }
        name_end = read_name(p, name);
        open = skip_ws(name_end);
        if (*open != '(' || !is_stack_lifetime_from_call(name)) {
            text_add_n(out, p, (size_t)(name_end - p));
            p = name_end;
            continue;
        }
        close = matching_paren(open);
        if (close == NULL) {
            text_add_n(out, p, (size_t)(name_end - p));
            p = name_end;
            continue;
        }
        if (!stack_lifetime_note_arg(name, open + 1, close, note_expr, &needs_address)) {
            text_add_n(out, p, (size_t)(close + 1 - p));
            p = close + 1;
            continue;
        }
        text_add(out, "({ cminus_stack_note_caller_range(");
        if (needs_address) {
            text_add_ch(out, '&');
        }
        text_add(out, note_expr);
        text_add(out, ", sizeof(");
        text_add(out, note_expr);
        text_add(out, ")); ");
        text_add_n(out, p, (size_t)(close + 1 - p));
        text_add(out, "; })");
        p = close + 1;
        changed = 1;
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

static struct Text *rewrite_inferred_array_from_calls(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    while (*p != '\0') {
        char name[NAME_MAX_LEN];
        const char *name_end;
        const char *open;
        const char *close;
        struct Type array_type;
        char array_label[NAME_MAX_LEN];
        int is_from;
        int is_from_bytes;

        if (*p == '"' || *p == '\'') {
            char quote = *p;
            text_add_ch(out, *p++);
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    text_add_ch(out, *p++);
                    text_add_ch(out, *p++);
                    continue;
                }
                text_add_ch(out, *p);
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            text_add_ch(out, *p++);
            continue;
        }
        name_end = read_name(p, name);
        open = skip_ws(name_end);
        is_from = strncmp(name, "Span_from_", 10) == 0 ||
            strncmp(name, "FixedVec_from_", 14) == 0 ||
            strncmp(name, "RingBuffer_from_", 16) == 0 ||
            strcmp(name, "Bitmap_from") == 0 ||
            strcmp(name, "Bitmap_from_words") == 0;
        is_from_bytes = strncmp(name, "Span_from_bytes_", 16) == 0 ||
            strncmp(name, "Span_map_from_", 14) == 0 ||
            strncmp(name, "FixedVec_from_bytes_", 20) == 0 ||
            strncmp(name, "RingBuffer_from_bytes_", 22) == 0 ||
            strcmp(name, "Bitmap_from_bytes") == 0;
        if (*open != '(' || (!is_from && !is_from_bytes)) {
            text_add_n(out, p, (size_t)(name_end - p));
            p = name_end;
            continue;
        }
        close = matching_paren(open);
        if (close == NULL) {
            text_add_n(out, p, (size_t)(name_end - p));
            p = name_end;
            continue;
        }
        if (strncmp(name, "Span_map_from_", 14) == 0) {
            const char *arg1_end = find_top_level_char(open + 1, close, ',');

            if (arg1_end != NULL &&
                find_top_level_char(arg1_end + 1, close, ',') == NULL &&
                parse_array_expr_arg(open + 1, arg1_end, array_label, &array_type, NULL)) {
                (void)array_type;
                text_add_n(out, p, (size_t)(arg1_end - p));
                text_add(out, ", sizeof(");
                text_add(out, array_label);
                text_add_ch(out, ')');
                text_add_n(out, arg1_end, (size_t)(close + 1 - arg1_end));
                p = close + 1;
                changed = 1;
                continue;
            }
        }
        if (find_top_level_char(open + 1, close, ',') == NULL &&
            parse_array_expr_arg(open + 1, close, array_label, &array_type, NULL)) {
            char tmp[64];

            text_add_n(out, p, (size_t)(close - p));
            if (strcmp(name, "Bitmap_from") == 0) {
                text_add(out, ", (int)(sizeof(");
                text_add(out, array_label);
                text_add(out, ") * 8)");
            } else if (is_from_bytes) {
                text_add(out, ", sizeof(");
                text_add(out, array_label);
                text_add_ch(out, ')');
            } else if (array_type.array_len > 0) {
                snprintf(tmp, sizeof(tmp), ", %d", array_type.array_len);
                text_add(out, tmp);
            } else if (array_type.size == 1) {
                text_add(out, ", (int)sizeof(");
                text_add(out, array_label);
                text_add_ch(out, ')');
            } else if (array_type.size == 2 || array_type.size == 4 || array_type.size == 8) {
                int shift = array_type.size == 2 ? 1 : (array_type.size == 4 ? 2 : 3);
                snprintf(tmp, sizeof(tmp), ", (int)(sizeof(");
                text_add(out, tmp);
                text_add(out, array_label);
                snprintf(tmp, sizeof(tmp), ") >> %d)", shift);
                text_add(out, tmp);
            } else {
                text_add(out, ", (int)(sizeof(");
                text_add(out, array_label);
                text_add(out, ") / sizeof((");
                text_add(out, array_label);
                text_add(out, ")[0]))");
            }
            text_add_ch(out, ')');
            p = close + 1;
            changed = 1;
            continue;
        }
        text_add_n(out, p, (size_t)(close + 1 - p));
        p = close + 1;
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

static const char *skip_safe_trivia_backward(const char *start, const char *p)
{
    while (p > start) {
        while (p > start && isspace((unsigned char)p[-1])) {
            p--;
        }
        if (p - start >= 2 && p[-2] == '*' && p[-1] == '/') {
            const char *q = p - 2;

            while (q - start >= 2 && !(q[-2] == '/' && q[-1] == '*')) {
                q--;
            }
            if (q - start < 2) {
                break;
            }
            p = q - 2;
            continue;
        }
        break;
    }
    return p;
}

static int direct_grouping_parens_before(const char *stmt, const char *expr)
{
    const char *p = expr;
    int count = 0;

    while (p > stmt) {
        const char *open;
        const char *before;

        p = skip_safe_trivia_backward(stmt, p);
        if (p == stmt || p[-1] != '(') {
            break;
        }
        open = p - 1;
        before = skip_safe_trivia_backward(stmt, open);
        if (before > stmt && (is_ident((unsigned char)before[-1]) ||
                              before[-1] == ')' || before[-1] == ']')) {
            const char *word = before;

            while (word > stmt && is_ident((unsigned char)word[-1])) {
                word--;
            }
            if ((size_t)(before - word) != 6 || strncmp(word, "return", 6) != 0) {
                break;
            }
        }
        count++;
        p = open;
    }
    return count;
}

struct SafetyExprParser {
    const char *source;
    const char *cursor;
    const char *end;
    int allow_initializer;
};

static const char *safety_skip_trivia(struct SafetyExprParser *parser, const char *p)
{
    while (p < parser->end) {
        if (isspace((unsigned char)*p)) {
            p++;
            continue;
        }
        if (p + 1 < parser->end && p[0] == '/' && p[1] == '*') {
            p += 2;
            while (p + 1 < parser->end && !(p[0] == '*' && p[1] == '/')) {
                p++;
            }
            if (p + 1 < parser->end) {
                p += 2;
            }
            continue;
        }
        if (p + 1 < parser->end && p[0] == '/' && p[1] == '/') {
            p += 2;
            while (p < parser->end && *p != '\n') {
                p++;
            }
            continue;
        }
        break;
    }
    return p;
}

static struct SafetyExprNode *safety_expr_new(enum SafetyExprKind kind,
                                               const char *start,
                                               const char *end)
{
    struct SafetyExprNode *node = xmalloc(sizeof(*node));
    char *text;

    memset(node, 0, sizeof(*node));
    node->kind = kind;
    node->start = start;
    node->end = end;
    node->type = type_unknown();
    node->unknown_reason = SAFETY_UNKNOWN_UNCLASSIFIED;
    if (start != NULL && end != NULL && end > start) {
        text = xstrndup(start, (size_t)(end - start));
        node->type = expr_type(text);
        free(text);
    }
    return node;
}

static void safety_expr_free(struct SafetyExprNode *node)
{
    while (node != NULL) {
        struct SafetyExprNode *next = node->next;
        safety_expr_free(node->lhs);
        safety_expr_free(node->rhs);
        safety_expr_free(node->child);
        free(node);
        node = next;
    }
}

static int safety_binary_operator(const char *p, const char *end,
                                  char op[4], int *precedence)
{
    static const struct {
        const char *op;
        int precedence;
    } operators[] = {
        {",", 1},
        {"<<=", 2}, {">>=", 2},
        {"=", 2}, {"+=", 2}, {"-=", 2}, {"*=", 2}, {"/=", 2}, {"%=", 2},
        {"&=", 2}, {"|=", 2}, {"^=", 2},
        {"?", 2}, {"||", 3}, {"&&", 4}, {"|", 5}, {"^", 6}, {"&", 7},
        {"==", 8}, {"!=", 8}, {"<", 9}, {">", 9}, {"<=", 9}, {">=", 9},
        {"<<", 10}, {">>", 10}, {"+", 11}, {"-", 11}, {"*", 12},
        {"/", 12}, {"%", 12}, {NULL, 0}
    };
    int i;

    for (i = 0; operators[i].op != NULL; i++) {
        size_t len = strlen(operators[i].op);
        if (p + len <= end && strncmp(p, operators[i].op, len) == 0) {
            if (len == 1 && ((p[0] == '<' && p + 1 < end && p[1] == '<') ||
                             (p[0] == '>' && p + 1 < end && p[1] == '>') ||
                             (p[0] == '&' && p + 1 < end && p[1] == '&') ||
                             (p[0] == '|' && p + 1 < end && p[1] == '|') ||
                             (p[0] == '-' && p + 1 < end && p[1] == '>') ||
                             (p + 1 < end && p[1] == '='))) {
                continue;
            }
            memcpy(op, operators[i].op, len);
            op[len] = '\0';
            *precedence = operators[i].precedence;
            return (int)len;
        }
    }
    return 0;
}

static struct SafetyExprNode *safety_parse_expression(struct SafetyExprParser *parser,
                                                       int min_precedence);
static const char *safety_matching_paren(struct SafetyExprParser *parser,
                                         const char *open);

static const char *safety_matching_generic_close(struct SafetyExprParser *parser,
                                                  const char *open)
{
    const char *p = open;
    int depth = 0;

    while (p < parser->end) {
        if (*p == '<') {
            depth++;
        } else if (*p == '>') {
            depth--;
            if (depth == 0) {
                const char *after = safety_skip_trivia(parser, p + 1);
                return (*after == '.' || *after == '(') ? p : NULL;
            }
        } else if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (p < parser->end) {
                if (*p == '\\' && p + 1 < parser->end) {
                    p += 2;
                    continue;
                }
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        p++;
    }
    return NULL;
}

static const char *safety_matching_brace(struct SafetyExprParser *parser,
                                         const char *open)
{
    const char *p = open;
    int depth = 0;

    while (p < parser->end) {
        if (*p == '{') {
            depth++;
        } else if (*p == '}') {
            depth--;
            if (depth == 0) return p;
        } else if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (p < parser->end) {
                if (*p == '\\' && p + 1 < parser->end) {
                    p += 2;
                    continue;
                }
                if (*p == quote) break;
                p++;
            }
        } else if (p + 1 < parser->end && p[0] == '/' && p[1] == '*') {
            p += 2;
            while (p + 1 < parser->end && !(p[0] == '*' && p[1] == '/')) p++;
            if (p + 1 < parser->end) p++;
        } else if (p + 1 < parser->end && p[0] == '/' && p[1] == '/') {
            p += 2;
            while (p < parser->end && *p != '\n') p++;
            continue;
        }
        p++;
    }
    return NULL;
}

static void safety_statement_result_bounds(const char *start, const char *end,
                                           const char **result_start,
                                           const char **result_end)
{
    const char *p = start;
    const char *boundary = start;
    int paren = 0;
    int bracket = 0;
    int brace = 0;

    *result_start = NULL;
    *result_end = NULL;
    while (p < end) {
        if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (p < end) {
                if (*p == '\\' && p + 1 < end) {
                    p += 2;
                    continue;
                }
                if (*p++ == quote) break;
            }
            continue;
        }
        if (p + 1 < end && p[0] == '/' && p[1] == '*') {
            p += 2;
            while (p + 1 < end && !(p[0] == '*' && p[1] == '/')) p++;
            if (p + 1 < end) p += 2;
            continue;
        }
        if (p + 1 < end && p[0] == '/' && p[1] == '/') {
            p += 2;
            while (p < end && *p != '\n') p++;
            continue;
        }
        if (*p == '(') paren++;
        else if (*p == ')' && paren > 0) paren--;
        else if (*p == '[') bracket++;
        else if (*p == ']' && bracket > 0) bracket--;
        else if (*p == '{') brace++;
        else if (*p == '}' && brace > 0) {
            brace--;
            if (brace == 0 && paren == 0 && bracket == 0) boundary = p + 1;
        } else if (*p == ';' && paren == 0 && bracket == 0 && brace == 0) {
            const char *candidate = boundary;

            while (candidate < p && isspace((unsigned char)*candidate)) candidate++;
            if (candidate < p) {
                *result_start = candidate;
                *result_end = p;
            }
            boundary = p + 1;
        }
        p++;
    }
}

static struct SafetyExprNode *safety_mark_statement_result(
    struct SafetyExprNode *node, const char *start, const char *end)
{
    struct SafetyExprNode *found;

    for (; node != NULL; node = node->next) {
        found = safety_mark_statement_result(node->lhs, start, end);
        if (found != NULL) return found;
        found = safety_mark_statement_result(node->rhs, start, end);
        if (found != NULL) return found;
        found = safety_mark_statement_result(node->child, start, end);
        if (found != NULL) return found;
        if (node->start == start && node->end == end) {
            node->statement_result = 1;
            return node;
        }
    }
    return NULL;
}

static void safety_statement_bind_declarations(struct SafetyExprNode *forest,
                                               const char *start,
                                               const char *end)
{
    const char *piece = start;

    while (piece < end) {
        const char *semi = find_top_level_char(piece, end, ';');
        struct DeclInfo decl;
        char *text;

        if (semi == NULL) break;
        text = xstrndup(piece, (size_t)(semi + 1 - piece));
        if (parse_decl(text, &decl) && decl.is_decl && !decl.is_typedef &&
            !decl.is_function && decl.name[0] != '\0') {
            safety_expr_bind_identifier(forest, decl.name, decl.type);
        }
        free(text);
        piece = semi + 1;
    }
}

static int safety_builtin_return_type(const char *name, struct Type *type)
{
    if (strcmp(name, "cminus_checked_int_add") == 0 ||
        strcmp(name, "cminus_checked_int_sub") == 0 ||
        strcmp(name, "cminus_checked_int_mul") == 0 ||
        strcmp(name, "cminus_checked_int_add_impl") == 0 ||
        strcmp(name, "cminus_checked_int_sub_impl") == 0 ||
        strcmp(name, "cminus_checked_int_mul_impl") == 0 ||
        strcmp(name, "strcmp") == 0 || strcmp(name, "memcmp") == 0 ||
        strcmp(name, "printf") == 0 || strcmp(name, "fprintf") == 0 ||
        strcmp(name, "vsnprintf") == 0 ||
        strcmp(name, "backtrace") == 0 ||
        strncmp(name, "pthread_", 8) == 0 ||
        strcmp(name, "sched_yield") == 0 ||
        strcmp(name, "__atomic_compare_exchange_n") == 0 ||
        strcmp(name, "__builtin_add_overflow") == 0 ||
        strcmp(name, "__builtin_sub_overflow") == 0 ||
        strcmp(name, "__builtin_mul_overflow") == 0) {
        *type = type_make(TY_INT, 0, NULL);
        return 1;
    }
    if (strcmp(name, "cminus_checked_size_add") == 0 ||
        strcmp(name, "cminus_checked_size_mul") == 0 ||
        strcmp(name, "cminus_checked_size_add_impl") == 0 ||
        strcmp(name, "cminus_checked_size_mul_impl") == 0 ||
        strcmp(name, "strlen") == 0 || strcmp(name, "cminus_string_len") == 0) {
        *type = type_make(TY_TYPEDEF, 0, "size_t");
        return 1;
    }
    if (strcmp(name, "cminus_gc_free") == 0 || strcmp(name, "free") == 0 ||
        strcmp(name, "abort") == 0 || strcmp(name, "cminus_panic") == 0 ||
        strcmp(name, "backtrace_symbols_fd") == 0 ||
        strcmp(name, "__atomic_store_n") == 0 ||
        strcmp(name, "__builtin_va_start") == 0 ||
        strcmp(name, "__builtin_va_copy") == 0 ||
        strcmp(name, "__builtin_va_end") == 0) {
        *type = type_make(TY_VOID, 0, NULL);
        return 1;
    }
    if (strcmp(name, "__atomic_load_n") == 0 ||
        strcmp(name, "__atomic_exchange_n") == 0 ||
        strcmp(name, "__atomic_fetch_add") == 0 ||
        strcmp(name, "__atomic_fetch_sub") == 0 ||
        strcmp(name, "__atomic_fetch_or") == 0 ||
        strcmp(name, "__atomic_fetch_and") == 0 ||
        strcmp(name, "__atomic_fetch_xor") == 0) {
        *type = type_make(TY_GENERIC, 0, "atomic-value");
        return 1;
    }
    if (strcmp(name, "__cminus_mod_ul") == 0) {
        *type = type_make(TY_LONG, 0, NULL);
        return 1;
    }
    if (strcmp(name, "fopen") == 0) {
        *type = type_make(TY_TYPEDEF, 1, "FILE");
        type->raw_ptr = 1;
        return 1;
    }
    if (strcmp(name, "cminus_gc_calloc") == 0) {
        *type = type_make(TY_VOID, 1, NULL);
        type->owned = 1;
        return 1;
    }
    if (strcmp(name, "memcpy") == 0 || strcmp(name, "memset") == 0 ||
        strcmp(name, "calloc") == 0) {
        *type = type_make(TY_VOID, 1, NULL);
        type->raw_ptr = 1;
        return 1;
    }
    return 0;
}

static void safety_resolve_identifier_node(struct SafetyExprNode *node)
{
    struct FunctionParams *fn;
    struct Type resolved;
    struct Symbol *symbol;
    struct Symbol *local_symbol;
    struct Symbol *global_symbol;

    if (node == NULL || node->kind != SAFETY_EXPR_IDENTIFIER) return;
    local_symbol = g_in_function ? symbol_find_in(&g_locals, node->name) : NULL;
    global_symbol = symbol_find_in(&g_globals, node->name);
    node->symbol_is_global = local_symbol == NULL && global_symbol != NULL &&
        global_symbol->var != NULL;
    if (type_is_known(node->type)) return;
    symbol = symbol_find_or_current_param(node->name);
    if (symbol != NULL) {
        node->type = symbol->type;
        return;
    }
    if (bitflags_const_type(node->name, &resolved)) {
        node->type = resolved;
        return;
    }
    if (payload_generated_constant_type(node->name, &resolved)) {
        node->type = resolved;
        return;
    }
    if (generic_find(&g_generic_structs, node->name) != NULL) {
        node->type = type_make(TY_TYPE_CONSTRUCTOR, 0, node->name);
        return;
    }
    fn = function_params_find(node->name);
    if (fn != NULL) {
        node->type = type_make(TY_FUNCTION, 0, NULL);
        node->type.base = &fn->ret;
    } else if (safety_builtin_return_type(node->name, &resolved)) {
        node->function_return_type = resolved;
        node->type = type_make(TY_FUNCTION, 0, NULL);
        node->type.base = &node->function_return_type;
    } else if (strcmp(node->name, "__LINE__") == 0 ||
               strncmp(node->name, "__ATOMIC_", 9) == 0) {
        node->type = type_make(TY_INT, 0, NULL);
    } else if (strcmp(node->name, "__FILE__") == 0 ||
               strcmp(node->name, "__func__") == 0) {
        node->type = type_make(TY_CHAR, 1, NULL);
    } else if (strcmp(node->name, "stderr") == 0) {
        node->type = type_make(TY_TYPEDEF, 1, "FILE");
        node->type.raw_ptr = 1;
    } else if (strcmp(node->name, "__CMINUS_GC_MAGIC") == 0 ||
               strcmp(node->name, "__CMINUS_STACK_NOTE_WINDOW") == 0 ||
               strcmp(node->name, "CMINUS_MAX_STACK_DEPTH") == 0 ||
               strcmp(node->name, "CMINUS_MAX_STACK_BYTES") == 0 ||
               strcmp(node->name, "CMINUS_MAX_ALLOCATION") == 0) {
        node->type = type_make(TY_LONG, 0, NULL);
    } else if (strncmp(node->name, "__cminus_return", 15) == 0 &&
               isdigit((unsigned char)node->name[15]) &&
               type_is_known(g_current_function_ret)) {
        node->type = g_current_function_ret;
    }
}

static struct SafetyExprNode *safety_parse_primary(struct SafetyExprParser *parser)
{
    const char *start;
    struct SafetyExprNode *node;

    parser->cursor = safety_skip_trivia(parser, parser->cursor);
    start = parser->cursor;
    if (start >= parser->end) {
        return NULL;
    }
    if (*start == '{' && parser->allow_initializer) {
        const char *close_brace = safety_matching_brace(parser, start);
        struct SafetyExprParser inner;
        const char *tail;

        if (close_brace == NULL) return NULL;
        node = safety_expr_new(SAFETY_EXPR_INITIALIZER, start, close_brace + 1);
        inner.source = start + 1;
        inner.cursor = start + 1;
        inner.end = close_brace;
        inner.allow_initializer = 1;
        tail = safety_skip_trivia(&inner, inner.cursor);
        if (tail < close_brace) {
            inner.cursor = tail;
            node->child = safety_parse_expression(&inner, 1);
            tail = safety_skip_trivia(&inner, inner.cursor);
            if (node->child == NULL || tail != close_brace) {
                safety_expr_free(node);
                parser->cursor = close_brace + 1;
                return NULL;
            }
        }
        parser->cursor = close_brace + 1;
    } else if (is_ident_start((unsigned char)*start)) {
        char parsed_name[NAME_MAX_LEN];
        const char *end = read_name(start, parsed_name);
        size_t len;
        if (end > parser->end) {
            end = parser->end;
        }
        parser->cursor = end;
        node = safety_expr_new(SAFETY_EXPR_IDENTIFIER, start, end);
        len = (size_t)(end - start);
        if (len >= NAME_MAX_LEN) {
            len = NAME_MAX_LEN - 1;
        }
        memcpy(node->name, start, len);
        node->name[len] = '\0';
        safety_resolve_identifier_node(node);
    } else if (*start == '(' &&
               *safety_skip_trivia(parser, start + 1) == '{') {
        const char *open_brace = safety_skip_trivia(parser, start + 1);
        const char *close_brace = safety_matching_brace(parser, open_brace);
        const char *close_paren = close_brace == NULL ? NULL :
            safety_skip_trivia(parser, close_brace + 1);

        if (close_brace == NULL || close_paren >= parser->end ||
            *close_paren != ')') {
            parser->cursor++;
            return safety_expr_new(SAFETY_EXPR_LITERAL, start, parser->cursor);
        }
        node = safety_expr_new(SAFETY_EXPR_STATEMENT, start, close_paren + 1);
        node->child = safety_parse_forest_range(open_brace + 1, close_brace);
        safety_statement_bind_declarations(node->child, open_brace + 1,
                                           close_brace);
        {
            const char *result_start;
            const char *result_end;
            struct SafetyExprNode *result;

            safety_statement_result_bounds(open_brace + 1, close_brace,
                                           &result_start, &result_end);
            result = result_start == NULL ? NULL :
                safety_mark_statement_result(node->child, result_start, result_end);
            if (result != NULL) node->type = result->type;
        }
        parser->cursor = close_paren + 1;
    } else if (*start == '(') {
        parser->cursor = start + 1;
        node = safety_expr_new(SAFETY_EXPR_GROUP, start, start + 1);
        node->lhs = safety_parse_expression(parser, 1);
        parser->cursor = safety_skip_trivia(parser, parser->cursor);
        if (parser->cursor < parser->end && *parser->cursor == ')') {
            parser->cursor++;
        }
        node->end = parser->cursor;
        if (node->lhs != NULL) {
            node->type = node->lhs->type;
        }
    } else if (*start == '"' || *start == '\'') {
        char quote = *start;
        const char *p = start + 1;
        while (p < parser->end) {
            if (*p == '\\' && p + 1 < parser->end) {
                p += 2;
                continue;
            }
            if (*p++ == quote) {
                break;
            }
        }
        parser->cursor = p;
        node = safety_expr_new(SAFETY_EXPR_LITERAL, start, p);
    } else if (isdigit((unsigned char)*start)) {
        char *literal;
        char *literal_end;
        const char *p = start;
        while (p < parser->end && (isalnum((unsigned char)*p) || *p == '.' || *p == '_')) {
            p++;
        }
        parser->cursor = p;
        node = safety_expr_new(SAFETY_EXPR_LITERAL, start, p);
        literal = xstrndup(start, (size_t)(p - start));
        node->integer = strtol(literal, &literal_end, 0);
        node->has_constant_integer = literal_end != literal;
        free(literal);
    } else {
        parser->cursor++;
        return safety_expr_new(SAFETY_EXPR_LITERAL, start, parser->cursor);
    }

    for (;;) {
        const char *postfix = safety_skip_trivia(parser, parser->cursor);
        if (postfix >= parser->end) {
            break;
        }
        if (*postfix == '<' &&
            (node->kind == SAFETY_EXPR_IDENTIFIER || node->kind == SAFETY_EXPR_MEMBER)) {
            const char *close = safety_matching_generic_close(parser, postfix);
            if (close != NULL) {
                struct SafetyExprNode *generic = safety_expr_new(SAFETY_EXPR_GENERIC,
                                                                  node->start, close + 1);
                const char *arg_start = safety_skip_trivia(parser, postfix + 1);
                const char *arg_end = close;
                size_t len;
                while (arg_end > arg_start && isspace((unsigned char)arg_end[-1])) {
                    arg_end--;
                }
                generic->lhs = node;
                len = (size_t)(arg_end - arg_start);
                if (len >= sizeof(generic->generic_arg)) {
                    len = sizeof(generic->generic_arg) - 1;
                }
                memcpy(generic->generic_arg, arg_start, len);
                generic->generic_arg[len] = '\0';
                generic->type = node->type;
                parser->cursor = close + 1;
                node = generic;
                continue;
            }
        }
        if (*postfix == '(') {
            if (node->kind == SAFETY_EXPR_IDENTIFIER &&
                token_is_control_keyword(node->name)) {
                break;
            }
            if (node->kind == SAFETY_EXPR_IDENTIFIER &&
                (strcmp(node->name, "__builtin_offsetof") == 0 ||
                 strcmp(node->name, "offsetof") == 0)) {
                const char *close = safety_matching_paren(parser, postfix);
                const char *comma = close == NULL ? NULL :
                    find_top_level_char(postfix + 1, close, ',');

                if (close != NULL && comma != NULL) {
                    struct SafetyExprNode *offset =
                        safety_expr_new(SAFETY_EXPR_OFFSETOF,
                                        node->start, close + 1);
                    const char *type_start = safety_skip_trivia(parser, postfix + 1);
                    const char *type_end = comma;
                    const char *field_start = safety_skip_trivia(parser, comma + 1);
                    const char *field_end = close;
                    size_t len;

                    while (type_end > type_start &&
                           isspace((unsigned char)type_end[-1])) type_end--;
                    while (field_end > field_start &&
                           isspace((unsigned char)field_end[-1])) field_end--;
                    len = (size_t)(type_end - type_start);
                    if (len >= sizeof(offset->type_name)) len = sizeof(offset->type_name) - 1;
                    memcpy(offset->type_name, type_start, len);
                    offset->type_name[len] = '\0';
                    len = (size_t)(field_end - field_start);
                    if (len >= sizeof(offset->name)) len = sizeof(offset->name) - 1;
                    memcpy(offset->name, field_start, len);
                    offset->name[len] = '\0';
                    offset->type = type_make(TY_TYPEDEF, 0, "size_t");
                    safety_expr_free(node);
                    parser->cursor = close + 1;
                    node = offset;
                    continue;
                }
            }
            struct SafetyExprNode *call = safety_expr_new(SAFETY_EXPR_CALL, node->start, postfix + 1);
            struct SafetyExprNode **arg = &call->child;
            parser->cursor = postfix + 1;
            parser->cursor = safety_skip_trivia(parser, parser->cursor);
            while (parser->cursor < parser->end && *parser->cursor != ')') {
                struct SafetyExprNode *value = safety_parse_expression(parser, 2);
                if (value == NULL) {
                    parser->cursor++;
                    continue;
                }
                *arg = value;
                while ((*arg)->next != NULL) {
                    arg = &(*arg)->next;
                }
                arg = &(*arg)->next;
                parser->cursor = safety_skip_trivia(parser, parser->cursor);
                if (parser->cursor < parser->end && *parser->cursor == ',') {
                    parser->cursor++;
                    continue;
                }
                break;
            }
            if (parser->cursor < parser->end && *parser->cursor == ')') {
                parser->cursor++;
            }
            call->lhs = node;
            call->end = parser->cursor;
            {
                const struct SafetyExprNode *callee = call->lhs;
                struct FunctionParams *fn = NULL;
                while (callee != NULL &&
                       (callee->kind == SAFETY_EXPR_GROUP || callee->kind == SAFETY_EXPR_GENERIC)) {
                    callee = callee->lhs;
                }
                if (callee != NULL && callee->kind == SAFETY_EXPR_IDENTIFIER) {
                    fn = function_params_find(callee->name);
                    if (fn != NULL) {
                        call->type = fn->ret;
                    } else if (malloc_func_index(callee->name) >= 0) {
                        call->type = g_malloc_funcs.ret[malloc_func_index(callee->name)];
                    }
                }
                if (!type_is_known(call->type) && callee != NULL &&
                    callee->type.kind == TY_FUNCTION && callee->type.base != NULL) {
                    call->type = *callee->type.base;
                }
            }
            node = call;
            continue;
        }
        if (*postfix == '[') {
            struct SafetyExprNode *index = safety_expr_new(SAFETY_EXPR_INDEX, node->start, postfix + 1);
            parser->cursor = postfix + 1;
            index->lhs = node;
            index->rhs = safety_parse_expression(parser, 1);
            parser->cursor = safety_skip_trivia(parser, parser->cursor);
            if (parser->cursor < parser->end && *parser->cursor == ']') {
                parser->cursor++;
            }
            index->end = parser->cursor;
            index->type = node->type;
            index->type.is_array = 0;
            index->type.array_len = 0;
            if (index->type.ptr > 0) {
                index->type.ptr--;
                if (index->type.ptr == 0) {
                    index->type.raw_ptr = 0;
                }
            }
            node = index;
            continue;
        }
        if (*postfix == '.' || (postfix + 1 < parser->end && postfix[0] == '-' && postfix[1] == '>')) {
            const char *field_start = safety_skip_trivia(parser, postfix + (*postfix == '.' ? 1 : 2));
            const char *field_end;
            struct SafetyExprNode *member;
            size_t len;
            if (field_start >= parser->end || !is_ident_start((unsigned char)*field_start)) {
                break;
            }
            {
                char parsed_field[NAME_MAX_LEN];
                field_end = read_name(field_start, parsed_field);
            }
            member = safety_expr_new(SAFETY_EXPR_MEMBER, node->start, field_end);
            member->lhs = node;
            strcpy(member->op, *postfix == '.' ? "." : "->");
            len = (size_t)(field_end - field_start);
            if (len >= NAME_MAX_LEN) {
                len = NAME_MAX_LEN - 1;
            }
            memcpy(member->name, field_start, len);
            member->name[len] = '\0';
            if (node->type.kind == TY_STRUCT) {
                struct Type field_type;
                if (struct_field_type(node->type.tag, member->name, &field_type)) {
                    member->type = field_type;
                }
            }
            parser->cursor = field_end;
            node = member;
            continue;
        }
        if (postfix + 1 < parser->end &&
            ((postfix[0] == '+' && postfix[1] == '+') ||
             (postfix[0] == '-' && postfix[1] == '-'))) {
            struct SafetyExprNode *update =
                safety_expr_new(SAFETY_EXPR_UPDATE, node->start, postfix + 2);

            update->lhs = node;
            update->type = node->type;
            update->postfix = 1;
            memcpy(update->op, postfix, 2);
            update->op[2] = '\0';
            parser->cursor = postfix + 2;
            node = update;
            continue;
        }
        break;
    }
    return node;
}

static int safety_parse_type_range(const char *start, const char *end,
                                   struct Type *type,
                                   char type_name[NAME_MAX_LEN])
{
    char *text;
    const char *base_end;
    const char *tail;
    size_t len;
    int parsed;

    while (start < end && isspace((unsigned char)*start)) start++;
    while (end > start && isspace((unsigned char)end[-1])) end--;
    if (start == end) {
        return 0;
    }
    len = (size_t)(end - start);
    if (len >= NAME_MAX_LEN) {
        return 0;
    }
    memcpy(type_name, start, len);
    type_name[len] = '\0';
    text = xstrndup(start, len);
    parsed = parse_base_type_prefix(text, &base_end, type);
    if (parsed) {
        tail = skip_ws(base_end);
        if (*tail == '<') {
            int angle = 0;

            do {
                if (*tail == '<') angle++;
                else if (*tail == '>') angle--;
                tail++;
            } while (*tail != '\0' && angle > 0);
            if (angle != 0) parsed = 0;
            tail = skip_ws(tail);
        }
        while (*tail == '*' || *tail == '%') {
            if (*tail == '*') {
                type->ptr++;
            } else {
                type->owned = 1;
            }
            tail = skip_ws(tail + 1);
        }
        parsed = parsed && *tail == '\0';
    } else {
        char alias[NAME_MAX_LEN];
        const char *alias_end = read_name(text, alias);

        tail = skip_ws(alias_end);
        parsed = is_ident_start((unsigned char)text[0]) &&
            strlen(alias) > 2 && strcmp(alias + strlen(alias) - 2, "_t") == 0;
        while (parsed && *tail == '*') {
            type->ptr++;
            tail = skip_ws(tail + 1);
        }
        parsed = parsed && *tail == '\0';
    }
    free(text);
    if (!parsed) {
        type_name[0] = '\0';
    }
    return parsed;
}

static const char *safety_matching_paren(struct SafetyExprParser *parser,
                                         const char *open)
{
    const char *p = open;
    int depth = 0;

    while (p < parser->end) {
        if (*p == '(') {
            depth++;
        } else if (*p == ')') {
            depth--;
            if (depth == 0) return p;
        } else if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (p < parser->end) {
                if (*p == '\\' && p + 1 < parser->end) {
                    p += 2;
                    continue;
                }
                if (*p == quote) break;
                p++;
            }
        }
        p++;
    }
    return NULL;
}

static struct SafetyExprNode *safety_parse_unary(struct SafetyExprParser *parser)
{
    const char *start = safety_skip_trivia(parser, parser->cursor);
    enum SafetyExprKind kind;
    struct SafetyExprNode *node;

    parser->cursor = start;
    if (start < parser->end && *start == '(') {
        const char *close = safety_matching_paren(parser, start);
        struct Type cast_type = type_unknown();
        char cast_name[NAME_MAX_LEN];

        if (close != NULL &&
            safety_parse_type_range(start + 1, close, &cast_type, cast_name)) {
            parser->cursor = close + 1;
            node = safety_expr_new(SAFETY_EXPR_CAST, start, parser->cursor);
            strncpy(node->type_name, cast_name, NAME_MAX_LEN - 1);
            node->type_name[NAME_MAX_LEN - 1] = '\0';
            node->lhs = safety_parse_unary(parser);
            node->end = node->lhs == NULL ? parser->cursor : node->lhs->end;
            node->type = cast_type;
            return node;
        }
    }
    if (start < parser->end &&
        (starts_word(start, "sizeof") || starts_word(start, "_Alignof") ||
         starts_word(start, "__alignof__"))) {
        int is_gnu_alignof = starts_word(start, "__alignof__");
        int is_alignof = is_gnu_alignof || starts_word(start, "_Alignof");
        const char *after_word = start +
            (is_gnu_alignof ? strlen("__alignof__") : (is_alignof ? 8 : 6));
        const char *operand_start = safety_skip_trivia(parser, after_word);

        node = safety_expr_new(is_alignof ? SAFETY_EXPR_ALIGNOF : SAFETY_EXPR_SIZEOF,
                               start, operand_start);
        strcpy(node->op, is_alignof ? "_Alignof" : "sizeof");
        /* The representation width is target-dependent, but the C result type
           is always the opaque typedef size_t. */
        node->type = type_make(TY_TYPEDEF, 0, "size_t");
        if (operand_start < parser->end && *operand_start == '(') {
            const char *close = safety_matching_paren(parser, operand_start);
            struct Type queried_type = type_unknown();
            char queried_name[NAME_MAX_LEN];

            if (close != NULL && safety_parse_type_range(operand_start + 1, close,
                                                         &queried_type, queried_name)) {
                strncpy(node->type_name, queried_name, NAME_MAX_LEN - 1);
                node->type_name[NAME_MAX_LEN - 1] = '\0';
                parser->cursor = close + 1;
            } else {
                parser->cursor = operand_start + 1;
                node->lhs = safety_parse_expression(parser, 1);
                parser->cursor = safety_skip_trivia(parser, parser->cursor);
                if (parser->cursor < parser->end && *parser->cursor == ')') {
                    parser->cursor++;
                }
            }
        } else {
            parser->cursor = operand_start;
            node->lhs = safety_parse_unary(parser);
        }
        node->end = parser->cursor;
        return node;
    }
    if (start + 1 < parser->end &&
        ((start[0] == '+' && start[1] == '+') ||
         (start[0] == '-' && start[1] == '-'))) {
        parser->cursor = start + 2;
        node = safety_expr_new(SAFETY_EXPR_UPDATE, start, parser->cursor);
        memcpy(node->op, start, 2);
        node->op[2] = '\0';
        node->lhs = safety_parse_unary(parser);
        node->end = node->lhs == NULL ? parser->cursor : node->lhs->end;
        if (node->lhs != NULL) {
            node->type = node->lhs->type;
        }
        return node;
    }
    if (start < parser->end && starts_word(start, "move")) {
        const char *after = safety_skip_trivia(parser, start + 4);
        if (after > start + 4) {
            parser->cursor = after;
            node = safety_expr_new(SAFETY_EXPR_MOVE, start, after);
            strcpy(node->op, "move");
            node->lhs = safety_parse_unary(parser);
            node->end = node->lhs == NULL ? parser->cursor : node->lhs->end;
            if (node->lhs != NULL) {
                node->type = node->lhs->type;
                node->type.owned = 1;
            }
            return node;
        }
    }
    if (start >= parser->end ||
        (*start != '&' && *start != '*' && *start != '+' && *start != '-' &&
         *start != '!' && *start != '~')) {
        return safety_parse_primary(parser);
    }
    if (start + 1 < parser->end && start[1] == *start) {
        return safety_parse_primary(parser);
    }
    kind = *start == '&' ? SAFETY_EXPR_UNARY_ADDRESS :
        (*start == '*' ? SAFETY_EXPR_UNARY_DEREF : SAFETY_EXPR_UNARY);
    parser->cursor++;
    node = safety_expr_new(kind, start, parser->cursor);
    node->op[0] = *start;
    node->op[1] = '\0';
    node->lhs = safety_parse_unary(parser);
    node->end = node->lhs == NULL ? parser->cursor : node->lhs->end;
    if (node->lhs != NULL) {
        node->type = node->lhs->type;
        if (kind == SAFETY_EXPR_UNARY_ADDRESS) {
            node->type.ptr++;
            node->type.owned = 0;
        } else if (kind == SAFETY_EXPR_UNARY_DEREF && node->type.ptr > 0) {
            node->type.ptr--;
            node->type.owned = 0;
            if (node->type.ptr == 0) {
                node->type.raw_ptr = 0;
            }
        }
    }
    return node;
}

static struct SafetyExprNode *safety_parse_expression(struct SafetyExprParser *parser,
                                                       int min_precedence)
{
    struct SafetyExprNode *lhs = safety_parse_unary(parser);

    if (lhs != NULL && lhs->kind == SAFETY_EXPR_IDENTIFIER &&
        token_is_control_keyword(lhs->name)) {
        return lhs;
    }

    while (lhs != NULL) {
        const char *operator_start = safety_skip_trivia(parser, parser->cursor);
        char op[4];
        int precedence;
        int op_len = safety_binary_operator(operator_start, parser->end, op, &precedence);
        struct SafetyExprNode *rhs;
        struct SafetyExprNode *binary;
        if (op_len == 0 || precedence < min_precedence) {
            break;
        }
        parser->cursor = operator_start + op_len;
        if (strcmp(op, "?") == 0) {
            struct SafetyExprNode *then_value = safety_parse_expression(parser, 1);
            struct SafetyExprNode *else_value;
            parser->cursor = safety_skip_trivia(parser, parser->cursor);
            if (then_value == NULL || parser->cursor >= parser->end || *parser->cursor != ':') {
                safety_expr_free(then_value);
                parser->cursor = operator_start;
                break;
            }
            parser->cursor++;
            else_value = safety_parse_expression(parser, precedence);
            if (else_value == NULL) {
                safety_expr_free(then_value);
                parser->cursor = operator_start;
                break;
            }
            binary = safety_expr_new(SAFETY_EXPR_CONDITIONAL, lhs->start, else_value->end);
            strcpy(binary->op, "?:");
            binary->lhs = lhs;
            binary->rhs = then_value;
            binary->child = else_value;
            binary->type = type_is_known(then_value->type) ? then_value->type : else_value->type;
            lhs = binary;
            continue;
        }
        rhs = safety_parse_expression(parser, precedence + (precedence == 1 ? 0 : 1));
        if (rhs == NULL) {
            parser->cursor = operator_start;
            break;
        }
        binary = safety_expr_new(SAFETY_EXPR_BINARY, lhs->start, rhs->end);
        strcpy(binary->op, op);
        binary->lhs = lhs;
        binary->rhs = rhs;
        if (strcmp(op, "==") == 0 || strcmp(op, "!=") == 0 ||
            strcmp(op, "<") == 0 || strcmp(op, ">") == 0 ||
            strcmp(op, "<=") == 0 || strcmp(op, ">=") == 0 ||
            strcmp(op, "&&") == 0 || strcmp(op, "||") == 0) {
            binary->type = type_make(TY_INT, 0, NULL);
        } else if (type_is_known(lhs->type)) {
            binary->type = lhs->type;
        } else {
            binary->type = rhs->type;
        }
        lhs = binary;
    }
    return lhs;
}

static void safety_classify_unknown_types(struct SafetyExprNode *node)
{
    for (; node != NULL; node = node->next) {
        safety_classify_unknown_types(node->lhs);
        safety_classify_unknown_types(node->rhs);
        safety_classify_unknown_types(node->child);
        if (type_is_known(node->type)) {
            node->unknown_reason = SAFETY_UNKNOWN_NONE;
            continue;
        }
        switch (node->kind) {
        case SAFETY_EXPR_IDENTIFIER:
            node->unknown_reason = strcmp(node->name, "NULL") == 0 ?
                SAFETY_UNKNOWN_CONTEXTUAL_LITERAL :
                SAFETY_UNKNOWN_UNRESOLVED_SYMBOL;
            break;
        case SAFETY_EXPR_LITERAL:
            node->unknown_reason = SAFETY_UNKNOWN_CONTEXTUAL_LITERAL;
            break;
        case SAFETY_EXPR_CALL:
        case SAFETY_EXPR_UNSAFE_CALL:
            node->unknown_reason = SAFETY_UNKNOWN_UNRESOLVED_CALL_RETURN;
            break;
        case SAFETY_EXPR_SIZEOF:
        case SAFETY_EXPR_ALIGNOF:
        case SAFETY_EXPR_OFFSETOF:
            node->unknown_reason = SAFETY_UNKNOWN_TARGET_SIZE;
            break;
        case SAFETY_EXPR_MEMBER:
            node->unknown_reason = SAFETY_UNKNOWN_MEMBER_TYPE;
            break;
        case SAFETY_EXPR_GENERIC:
            node->unknown_reason = SAFETY_UNKNOWN_SYMBOLIC_GENERIC;
            break;
        case SAFETY_EXPR_STATEMENT:
            node->unknown_reason = SAFETY_UNKNOWN_STATEMENT_RESULT;
            break;
        case SAFETY_EXPR_INITIALIZER:
            node->unknown_reason = SAFETY_UNKNOWN_CONTEXTUAL_INITIALIZER;
            break;
        default:
            node->unknown_reason = SAFETY_UNKNOWN_OPERAND_TYPE;
            break;
        }
    }
}

static int safety_forest_syntax_only(const struct SafetyExprNode *node)
{
    if (node == NULL) return 0;
    if (node->kind == SAFETY_EXPR_IDENTIFIER &&
        (token_is_control_keyword(node->name) ||
         strcmp(node->name, "struct") == 0 ||
         strcmp(node->name, "union") == 0 ||
         strcmp(node->name, "enum") == 0)) {
        return 1;
    }
    return node->kind == SAFETY_EXPR_LITERAL &&
        !type_is_known(node->type) && node->end == node->start + 1 &&
        strchr("{};,", *node->start) != NULL;
}

static struct SafetyExprNode *safety_parse_forest_range(const char *start,
                                                        const char *end)
{
    struct SafetyExprParser parser;
    struct SafetyExprNode *head = NULL;
    struct SafetyExprNode **tail = &head;

    parser.source = start;
    parser.cursor = start;
    parser.end = end;
    parser.allow_initializer = 0;
    while (parser.cursor < parser.end) {
        const char *before;
        struct SafetyExprNode *node;
        parser.cursor = safety_skip_trivia(&parser, parser.cursor);
        if (parser.cursor >= parser.end) {
            break;
        }
        before = parser.cursor;

        /* A GNU statement expression contains declarations as well as value
           expressions.  Preserve the initializer expression in the typed
           forest, but do not misclassify its type spelling and declarator as
           unresolved value symbols. */
        {
            const char *semi = find_top_level_char(before, parser.end, ';');
            struct DeclInfo decl;
            char *text;

            if (semi != NULL) {
                text = xstrndup(before, (size_t)(semi + 1 - before));
                if (parse_decl(text, &decl) && decl.is_decl &&
                    !decl.is_function && decl.name[0] != '\0' &&
                    (decl.has_init ||
                     memchr(before, '(', (size_t)(semi - before)) == NULL)) {
                    if (decl.has_init && decl.init != NULL) {
                        size_t init_offset = (size_t)(decl.init - text);
                        node = safety_parse_range(before + init_offset, semi);
                        if (node == NULL) {
                            node = safety_parse_forest_range(before + init_offset,
                                                             semi);
                        }
                        if (node != NULL) {
                            *tail = node;
                            while ((*tail)->next != NULL) {
                                tail = &(*tail)->next;
                            }
                            tail = &(*tail)->next;
                        }
                    }
                    parser.cursor = semi + 1;
                    free(text);
                    continue;
                }
                free(text);
            }
        }
        node = safety_parse_expression(&parser, 1);
        if (safety_forest_syntax_only(node)) {
            safety_expr_free(node);
            node = NULL;
        }
        if (node != NULL) {
            *tail = node;
            while ((*tail)->next != NULL) {
                tail = &(*tail)->next;
            }
            tail = &(*tail)->next;
        }
        if (parser.cursor <= before) {
            parser.cursor = before + 1;
        }
    }
    safety_classify_unknown_types(head);
    return head;
}

static struct SafetyExprNode *safety_parse_forest(const char *stmt)
{
    return safety_parse_forest_range(stmt, stmt + strlen(stmt));
}

static struct SafetyExprNode *safety_parse_range(const char *start, const char *end)
{
    struct SafetyExprParser parser;
    struct SafetyExprNode *node;
    const char *tail;

    while (end > start && (isspace((unsigned char)end[-1]) || end[-1] == ';')) {
        end--;
    }
    parser.source = start;
    parser.cursor = start;
    parser.end = end;
    parser.allow_initializer = 1;
    node = safety_parse_expression(&parser, 1);
    tail = safety_skip_trivia(&parser, parser.cursor);
    if (node == NULL || tail != end) {
        safety_expr_free(node);
        return NULL;
    }
    safety_classify_unknown_types(node);
    return node;
}

static int safety_expr_is_assignment(const struct SafetyExprNode *expr)
{
    const struct SafetyExprNode *root = expr;

    while (root != NULL && root->kind == SAFETY_EXPR_GROUP) {
        root = root->lhs;
    }
    return root != NULL &&
        (root->kind == SAFETY_EXPR_UPDATE ||
         (root->kind == SAFETY_EXPR_BINARY &&
          (strcmp(root->op, "=") == 0 || strcmp(root->op, "+=") == 0 ||
           strcmp(root->op, "-=") == 0 || strcmp(root->op, "*=") == 0 ||
           strcmp(root->op, "/=") == 0 || strcmp(root->op, "%=") == 0 ||
           strcmp(root->op, "&=") == 0 || strcmp(root->op, "|=") == 0 ||
           strcmp(root->op, "^=") == 0 || strcmp(root->op, "<<=") == 0 ||
           strcmp(root->op, ">>=") == 0)));
}

static void ast_resolve_generated_return(struct SafetyExprNode *expr)
{
    if (expr != NULL && expr->kind == SAFETY_EXPR_IDENTIFIER &&
        strncmp(expr->name, "__cminus_return", 15) == 0 &&
        isdigit((unsigned char)expr->name[15]) &&
        type_is_known(g_current_function_ret)) {
        expr->type = g_current_function_ret;
        expr->unknown_reason = SAFETY_UNKNOWN_NONE;
    }
}

static const char *ast_skip_leading_gnu_attributes(const char *text)
{
    const char *p = skip_ws(text);

    while (starts_word(p, "__attribute__")) {
        const char *open = skip_ws(p + strlen("__attribute__"));
        const char *close;

        if (*open != '(' || (close = matching_paren(open)) == NULL) break;
        p = skip_ws(close + 1);
    }
    return p;
}

static struct Node *ast_typed_statement(enum NodeKind fallback, const char *text)
{
    struct Node *node = ast_new(fallback, text);
    struct DeclInfo decl;
    const char *typed_text = ast_skip_leading_gnu_attributes(node->tok);
    const char *p = typed_text;
    const char *end = node->tok + strlen(node->tok);

    if (starts_word(p, "goto")) {
        const char *target = skip_ws(p + 4);
        char name[NAME_MAX_LEN];
        const char *tail;

        if (is_ident_start((unsigned char)*target)) {
            tail = read_name(target, name);
            tail = skip_ws(tail);
            if (*tail == ';') {
                tail = skip_ws(tail + 1);
            }
            if (*tail == '\0') {
                node->kind = ND_GOTO;
                strncpy(node->name, name, NAME_MAX_LEN - 1);
                node->name[NAME_MAX_LEN - 1] = '\0';
                return node;
            }
        }
    }
    if (starts_word(p, "break")) {
        const char *tail = skip_ws(p + 5);

        if (*tail == ';') tail = skip_ws(tail + 1);
        if (*tail == '\0') {
            node->kind = ND_BREAK;
            return node;
        }
    }
    if (starts_word(p, "continue")) {
        const char *tail = skip_ws(p + 8);

        if (*tail == ';') tail = skip_ws(tail + 1);
        if (*tail == '\0') {
            node->kind = ND_CONTINUE;
            return node;
        }
    }
    if (starts_word(p, "while")) {
        const char *open = strchr(p, '(');
        const char *close = open == NULL ? NULL : matching_paren(open);
        const char *tail = close == NULL ? p : skip_ws(close + 1);

        if (*tail == ';') tail = skip_ws(tail + 1);
        if (open != NULL && close != NULL && *tail == '\0') {
            node->kind = ND_WHILE;
            node->expr = safety_parse_range(open + 1, close);
            if (node->expr != NULL) node->ty = type_copy(node->expr->type);
            return node;
        }
    }
    if (starts_word(p, "_Static_assert") || starts_word(p, "static_assert")) {
        const char *open = strchr(p, '(');
        const char *close = open == NULL ? NULL : matching_paren(open);
        const char *comma = close == NULL ? NULL :
            find_top_level_char(open + 1, close, ',');

        node->kind = ND_STATIC_ASSERT;
        if (open != NULL && close != NULL && comma != NULL) {
            node->expr = safety_parse_range(open + 1, comma);
            if (node->expr != NULL) node->ty = type_copy(node->expr->type);
        }
        return node;
    }

    if (fallback == ND_DECL) {
        struct Type ret;
        char function_name[NAME_MAX_LEN];

        if (parse_function_signature(typed_text, function_name, &ret)) {
            struct Symbol *symbol = symbol_find(function_name);

            node->kind = ND_FUNCDECL;
            node->ty = type_copy(ret);
            node->return_type = ast_return_type(ret);
            node->var = symbol == NULL ? NULL : symbol->var;
            strncpy(node->name, function_name, NAME_MAX_LEN - 1);
            node->name[NAME_MAX_LEN - 1] = '\0';
            node->params = ast_function_parameters(function_name);
            return node;
        }
    }

    if (parse_decl(typed_text, &decl) && decl.is_decl && decl.name[0] != '\0') {
        struct Symbol *symbol;

        node->kind = decl.is_typedef ? ND_TYPEDEF :
            (decl.is_function ? ND_FUNCDECL : ND_DECL);
        node->ty = type_copy(decl.type);
        symbol = symbol_find(decl.name);
        if (!decl.is_function && symbol != NULL &&
            symbol->type.kind == decl.type.kind &&
            symbol->type.ptr == decl.type.ptr &&
            symbol->type.is_array == decl.type.is_array &&
            (!decl.type.is_array ||
             symbol->type.array_len == decl.type.array_len) &&
            strcmp(symbol->type.tag, decl.type.tag) == 0) {
            node->ty = type_copy(symbol->type);
        }
        if (!decl.is_function) {
            node->type_node = ast_type_node(*node->ty);
        }
        node->var = symbol == NULL ? NULL : symbol->var;
        strncpy(node->name, decl.name, NAME_MAX_LEN - 1);
        node->name[NAME_MAX_LEN - 1] = '\0';
        if (decl.is_function) {
            struct Type ret;
            char function_name[NAME_MAX_LEN];

            if (parse_function_signature(typed_text, function_name, &ret)) {
                node->ty = type_copy(ret);
                node->return_type = ast_return_type(ret);
                strncpy(node->name, function_name, NAME_MAX_LEN - 1);
                node->name[NAME_MAX_LEN - 1] = '\0';
                node->params = ast_function_parameters(function_name);
            }
        }
        if (decl.has_init && decl.init != NULL) {
            node->expr = safety_parse_range(decl.init, end);
            if (node->expr != NULL &&
                node->expr->kind == SAFETY_EXPR_INITIALIZER) {
                node->expr->type = decl.type;
            }
        }
        ast_attach_semantics(node);
        return node;
    }
    if (starts_word(p, "return")) {
        const char *value = skip_ws(p + 6);

        node->kind = ND_RETURN;
        if (*value != ';' && *value != '\0') {
            node->expr = safety_parse_range(value, end);
            if (node->expr != NULL) {
                ast_resolve_generated_return(node->expr);
                node->ty = type_copy(node->expr->type);
            }
        }
        ast_attach_semantics(node);
        return node;
    }
    if (fallback == ND_RETURN) {
        const char *scan = p;
        const char *last_return = NULL;

        while ((scan = strstr(scan, "return")) != NULL) {
            if ((scan == node->tok || !is_ident((unsigned char)scan[-1])) &&
                !is_ident((unsigned char)scan[6])) {
                last_return = scan;
            }
            scan += 6;
        }
        if (last_return != NULL) {
            const char *value = skip_ws(last_return + 6);

            node->kind = ND_RETURN;
            if (last_return > node->tok) {
                char *cleanup = xstrndup(node->tok,
                                         (size_t)(last_return - node->tok));

                node->lhs = ast_new(ND_CLEANUP, cleanup);
                free(cleanup);
            }
            if (*value != ';' && *value != '\0') {
                node->expr = safety_parse_range(value, end);
                if (node->expr != NULL) {
                    ast_resolve_generated_return(node->expr);
                    node->ty = type_copy(node->expr->type);
                }
            }
            ast_attach_semantics(node);
            return node;
        }
    }
    node->expr = safety_parse_range(p, end);
    if (node->expr != NULL) {
        node->kind = safety_expr_is_assignment(node->expr) ? ND_ASSIGN : ND_EXPR_STMT;
        node->ty = type_copy(node->expr->type);
    }
    ast_attach_semantics(node);
    return node;
}

static struct Node *ast_typed_output(enum NodeKind fallback, const char *text)
{
    const char *p;
    const char *segment;
    int paren = 0;
    int bracket = 0;
    int brace = 0;
    int count = 0;
    struct Node *parent;
    struct Node *body = NULL;

    if (fallback == ND_RETURN) {
        return ast_typed_statement(fallback, text);
    }
    p = text;
    while (*p != '\0') {
        if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (p[0] == '/' && p[1] == '*') {
            p += 2;
            while (p[0] != '\0' && !(p[0] == '*' && p[1] == '/')) p++;
            if (p[0] != '\0') p += 2;
            continue;
        }
        if (p[0] == '/' && p[1] == '/') {
            p += 2;
            while (*p != '\0' && *p != '\n') p++;
            continue;
        }
        if (*p == '(') paren++;
        else if (*p == ')' && paren > 0) paren--;
        else if (*p == '[') bracket++;
        else if (*p == ']' && bracket > 0) bracket--;
        else if (*p == '{') brace++;
        else if (*p == '}' && brace > 0) brace--;
        else if (*p == ';' && paren == 0 && bracket == 0 && brace == 0) count++;
        p++;
    }
    if (count <= 1) {
        return ast_typed_statement(fallback, text);
    }
    parent = ast_new(ND_EXPANSION, text);
    segment = text;
    p = text;
    paren = bracket = brace = 0;
    while (*p != '\0') {
        const char *end = NULL;

        if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p++ == quote) break;
            }
            continue;
        }
        if (p[0] == '/' && p[1] == '*') {
            p += 2;
            while (p[0] != '\0' && !(p[0] == '*' && p[1] == '/')) p++;
            if (p[0] != '\0') p += 2;
            continue;
        }
        if (p[0] == '/' && p[1] == '/') {
            p += 2;
            while (*p != '\0' && *p != '\n') p++;
            continue;
        }
        if (*p == '(') paren++;
        else if (*p == ')' && paren > 0) paren--;
        else if (*p == '[') bracket++;
        else if (*p == ']' && bracket > 0) bracket--;
        else if (*p == '{') brace++;
        else if (*p == '}' && brace > 0) brace--;
        else if (*p == ';' && paren == 0 && bracket == 0 && brace == 0) end = p + 1;
        p++;
        if (end != NULL) {
            char *piece = xstrndup(segment, (size_t)(end - segment));
            struct Node *child = ast_typed_statement(body == NULL ? fallback : ND_EXPR_STMT,
                                                     piece);

            body = ast_append(body, child);
            free(piece);
            segment = end;
        }
    }
    if (*skip_ws(segment) != '\0') {
        struct Node *cleanup = ast_new(ND_CLEANUP, segment);

        body = ast_append(body, cleanup);
    }
    parent->body = body;
    if (body != NULL && body->ty != NULL) {
        parent->ty = type_copy(*body->ty);
    }
    return parent;
}

static void ast_emit_statement(struct Text *out, const struct Node *node)
{
    const char *start;
    const char *end;

    if (node == NULL || node->tok == NULL) {
        return;
    }
    start = node->tok;
    end = start + strlen(start);
    if (node->expr == NULL || node->expr->start < start || node->expr->end > end ||
        node->expr->start > node->expr->end) {
        text_add(out, start);
        return;
    }
    text_add_n(out, start, (size_t)(node->expr->start - start));
    text_add_n(out, node->expr->start, (size_t)(node->expr->end - node->expr->start));
    text_add(out, node->expr->end);
}

static struct Text *finalize_typed_statement(struct Text *in, enum NodeKind fallback)
{
    struct Node *node;
    struct Text *out;

    if (in == NULL || in->len == 0) {
        return in;
    }
    node = ast_typed_output(fallback, in->text);
    validate_safe_typed_ast(node);
    pending_semantics_clear();
    out = text_new();
    out->tail_return = in->tail_return;
    out->ast = node;
    ast_emit_statement(out, node);
    in->ast = NULL;
    text_free(in);
    return out;
}

static struct Text *ast_normalize_function_head(const char *head)
{
    struct Text *normalized = text_new();
    const char *p = head;

    while (*p != '\0') {
        if (starts_word(p, "__attribute__")) {
            const char *open = skip_ws(p + strlen("__attribute__"));
            const char *close = *open == '(' ? matching_paren(open) : NULL;

            if (close != NULL) {
                p = close + 1;
                continue;
            }
        }
        text_add_ch(normalized, *p++);
    }
    return normalized;
}

static struct Node *ast_function(const char *head, struct Node *body)
{
    struct Node *node = ast_new(ND_FUNCDEF, head);
    struct Text *normalized = ast_normalize_function_head(head);
    struct Type ret;
    char name[NAME_MAX_LEN];

    node->body = body;
    if (parse_function_signature(normalized->text, name, &ret)) {
        struct Symbol *symbol = symbol_find(name);

        node->ty = type_copy(ret);
        node->return_type = ast_return_type(ret);
        node->var = symbol == NULL ? NULL : symbol->var;
        strncpy(node->name, name, NAME_MAX_LEN - 1);
        node->name[NAME_MAX_LEN - 1] = '\0';
        node->params = ast_function_parameters(name);
    }
    text_free(normalized);
    return node;
}

static struct Node *ast_function_parameters(const char *name)
{
    struct FunctionParams *fn = function_params_find(name);
    struct Node *params = NULL;
    int i;

    if (fn == NULL) {
        return NULL;
    }
    for (i = 0; i < fn->count; i++) {
        struct Node *param = ast_new(ND_PARAM, NULL);

        strncpy(param->name, fn->param[i].name, NAME_MAX_LEN - 1);
        param->name[NAME_MAX_LEN - 1] = '\0';
        param->ty = type_copy(fn->param[i].type);
        param->type_node = ast_type_node(fn->param[i].type);
        if (fn->param[i].borrowed) {
            param->ownership = ast_new(ND_OWNERSHIP, NULL);
            strcpy(param->ownership->name, "borrowed");
            param->lifetime = ast_new(ND_LIFETIME, NULL);
            strcpy(param->lifetime->type_name, "caller");
            param->lifetime->caller_owner = 1;
        } else if (fn->param[i].type.owned) {
            param->ownership = ast_new(ND_OWNERSHIP, NULL);
            strcpy(param->ownership->name, "owned");
        }
        if (fn->param[i].def[0] != '\0') {
            param->expr = safety_parse_range(
                fn->param[i].def,
                fn->param[i].def + strlen(fn->param[i].def));
        }
        params = ast_append(params, param);
    }
    return params;
}

static struct Node *ast_return_type(struct Type type)
{
    struct Node *node = ast_new(ND_RETURN_TYPE, NULL);

    node->ty = type_copy(type);
    node->type_args = ast_type_arguments(type.applied_args);
    if (type.is_array) {
        node->dimensions = ast_new(ND_ARRAY_DIMENSION, NULL);
        node->dimensions->array_len = type.array_len;
    }
    return node;
}

static struct Node *ast_type_node(struct Type type)
{
    struct Node *node = ast_new(ND_TYPE, NULL);

    node->ty = type_copy(type);
    node->type_args = ast_type_arguments(type.applied_args);
    if (type.is_array) {
        node->dimensions = ast_new(ND_ARRAY_DIMENSION, NULL);
        node->dimensions->array_len = type.array_len;
    }
    return node;
}

static void ast_attach_semantics(struct Node *node)
{
    int matches = 0;
    int owned = node->ty != NULL && node->ty->owned;

    if (g_pending_semantics.active) {
        if (node->kind == ND_DECL && node->name[0] != '\0' &&
            strcmp(node->name, g_pending_semantics.target) == 0) {
            matches = 1;
        } else if (node->kind == ND_ASSIGN && g_pending_semantics.is_assignment) {
            matches = 1;
        } else if (node->kind == ND_RETURN && g_pending_semantics.is_return) {
            matches = 1;
        }
    }
    if (matches && g_pending_semantics.borrowed) {
        node->ownership = ast_new(ND_OWNERSHIP, NULL);
        strcpy(node->ownership->name, "borrowed");
    } else if (owned || (matches && g_pending_semantics.owned)) {
        node->ownership = ast_new(ND_OWNERSHIP, NULL);
        strcpy(node->ownership->name, "owned");
    }
    if (matches && g_pending_semantics.owner[0] != '\0') {
        node->lifetime = ast_new(ND_LIFETIME, NULL);
        strcpy(node->lifetime->type_name, g_pending_semantics.owner);
        node->lifetime->stack_owner = g_pending_semantics.stack_owner;
        node->lifetime->dead = g_pending_semantics.dead;
        node->lifetime->runtime_checked = g_pending_semantics.stack_owner;
    }
    if (matches && g_pending_semantics.move_source[0] != '\0') {
        node->move_transfer = ast_new(ND_MOVE_TRANSFER, NULL);
        strcpy(node->move_transfer->type_name,
               g_pending_semantics.move_source);
    }
}

static struct Node *ast_type_arguments(const char *arguments)
{
    struct Node *head = NULL;
    const char *start;
    const char *p;
    int angle = 0;
    int paren = 0;
    int bracket = 0;

    if (arguments == NULL || *skip_ws(arguments) == '\0') {
        return NULL;
    }
    start = arguments;
    for (p = arguments;; p++) {
        int at_end = *p == '\0';
        int separator = *p == ',' && angle == 0 && paren == 0 && bracket == 0;

        if (at_end || separator) {
            const char *piece_start = start;
            const char *piece_end = p;
            char spelling[DEFAULT_EXPR_MAX];
            struct Type argument_type = type_unknown();
            const char *base_end;
            struct Node *node;
            size_t len;

            while (piece_start < piece_end && isspace((unsigned char)*piece_start)) {
                piece_start++;
            }
            while (piece_end > piece_start &&
                   isspace((unsigned char)piece_end[-1])) {
                piece_end--;
            }
            len = (size_t)(piece_end - piece_start);
            if (len >= sizeof(spelling)) {
                die("generic type argument is too long");
            }
            memcpy(spelling, piece_start, len);
            spelling[len] = '\0';
            if (len > 0) {
                if (parse_base_type_prefix(spelling, &base_end, &argument_type)) {
                    const char *tail;

                    for (tail = base_end; *tail != '\0'; tail++) {
                        if (*tail == '*') argument_type.ptr++;
                        else if (*tail == '%') argument_type.owned = 1;
                    }
                } else {
                    argument_type = type_make(TY_GENERIC, 0, spelling);
                }
                node = ast_new(ND_TYPE_ARGUMENT, NULL);
                node->ty = type_copy(argument_type);
                strncpy(node->type_name, spelling, NAME_MAX_LEN - 1);
                node->type_name[NAME_MAX_LEN - 1] = '\0';
                node->type_args = ast_type_arguments(argument_type.applied_args);
                head = ast_append(head, node);
            }
            if (at_end) {
                break;
            }
            start = p + 1;
            continue;
        }
        if (*p == '<') angle++;
        else if (*p == '>' && angle > 0) angle--;
        else if (*p == '(') paren++;
        else if (*p == ')' && paren > 0) paren--;
        else if (*p == '[') bracket++;
        else if (*p == ']' && bracket > 0) bracket--;
    }
    return head;
}

static struct Node *ast_type_parameters(const char *parameters)
{
    struct Node *head = NULL;
    const char *p = parameters;

    while (p != NULL && *p != '\0') {
        const char *start;
        const char *end;
        char name[NAME_MAX_LEN];
        size_t len;
        struct Node *node;

        while (*p == ',' || isspace((unsigned char)*p)) {
            p++;
        }
        start = p;
        while (*p != '\0' && *p != ',') {
            p++;
        }
        end = p;
        while (end > start && isspace((unsigned char)end[-1])) {
            end--;
        }
        len = (size_t)(end - start);
        if (len == 0) {
            continue;
        }
        if (len >= sizeof(name)) {
            die("generic type parameter name is too long");
        }
        memcpy(name, start, len);
        name[len] = '\0';
        node = ast_new(ND_TYPE_PARAM, NULL);
        strncpy(node->name, name, NAME_MAX_LEN - 1);
        node->name[NAME_MAX_LEN - 1] = '\0';
        node->ty = type_copy(type_make(TY_GENERIC, 0, name));
        head = ast_append(head, node);
    }
    return head;
}

static struct Node *ast_function_declaration(const char *head)
{
    struct Node *node = ast_new(ND_FUNCDECL, head);
    struct Type ret;
    char name[NAME_MAX_LEN];

    if (parse_function_signature(head, name, &ret)) {
        struct Symbol *symbol = symbol_find(name);

        node->ty = type_copy(ret);
        node->return_type = ast_return_type(ret);
        node->var = symbol == NULL ? NULL : symbol->var;
        strncpy(node->name, name, NAME_MAX_LEN - 1);
        node->name[NAME_MAX_LEN - 1] = '\0';
        node->params = ast_function_parameters(name);
    }
    return node;
}

static enum NodeKind ast_control_kind(const char *head)
{
    const char *p = skip_ws(head);

    if (starts_word(p, "else")) {
        p = skip_ws(p + 4);
        if (!starts_word(p, "if")) {
            return ND_IF;
        }
    }
    if (starts_word(p, "if")) return ND_IF;
    if (starts_word(p, "while")) return ND_WHILE;
    if (starts_word(p, "for")) return ND_FOR;
    if (starts_word(p, "switch")) return ND_SWITCH;
    if (starts_word(p, "do")) return ND_DO;
    return ND_RAW;
}

static void safety_expr_bind_identifier(struct SafetyExprNode *expr,
                                        const char *name,
                                        struct Type type)
{
    for (; expr != NULL; expr = expr->next) {
        safety_expr_bind_identifier(expr->lhs, name, type);
        safety_expr_bind_identifier(expr->rhs, name, type);
        safety_expr_bind_identifier(expr->child, name, type);
        if (expr->kind == SAFETY_EXPR_IDENTIFIER &&
            strcmp(expr->name, name) == 0 && !type_is_known(expr->type)) {
            expr->type = type;
        }
        if (expr->kind == SAFETY_EXPR_UPDATE && expr->lhs != NULL &&
            type_is_known(expr->lhs->type)) {
            expr->type = expr->lhs->type;
        }
    }
}

static struct Node *ast_control(const char *head, const char *open_tok,
                                const char *body_text, const char *close_tok,
                                struct Node *body)
{
    struct Node *node = ast_new(ast_control_kind(head), head);
    const char *p = skip_ws(node->tok);
    const char *open;
    const char *close;

    node->open_tok = xstrdup(open_tok);
    node->body_tok = xstrdup(body_text);
    node->close_tok = xstrdup(close_tok);
    node->body = body;
    if (starts_word(p, "else")) {
        p = skip_ws(p + 4);
    }
    open = strchr(p, '(');
    close = open == NULL ? NULL : matching_paren(open);
    if (open == NULL || close == NULL) {
        return node;
    }
    if (starts_word(p, "for")) {
        const char *first = find_top_level_char(open + 1, close, ';');
        const char *second = first == NULL ? NULL : find_top_level_char(first + 1, close, ';');

        if (first != NULL && second != NULL) {
            char *init = xstrndup(open + 1, (size_t)(first - open - 1));

            if (*skip_ws(init) != '\0') {
                node->lhs = ast_typed_statement(ND_EXPR_STMT, init);
            }
            free(init);
            if (*skip_ws(first + 1) != ';') {
                node->expr = safety_parse_range(first + 1, second);
            }
            if (*skip_ws(second + 1) != ')') {
                node->inc_expr = safety_parse_range(second + 1, close);
            }
            if (node->lhs != NULL && node->lhs->kind == ND_DECL &&
                node->lhs->ty != NULL && node->lhs->name[0] != '\0') {
                safety_expr_bind_identifier(node->expr, node->lhs->name,
                                            *node->lhs->ty);
                safety_expr_bind_identifier(node->inc_expr, node->lhs->name,
                                            *node->lhs->ty);
            }
        }
    } else {
        node->expr = safety_parse_range(open + 1, close);
    }
    if (node->expr != NULL) {
        node->ty = type_copy(node->expr->type);
    }
    return node;
}

static int safe_typed_ast_validation_enabled(void)
{
    return g_unsafe_depth == 0 && !g_c_compat &&
        g_current_generic_kind == 0 && !g_current_payload_enum;
}

static void fail_incomplete_safe_ast(const char *what)
{
    fprintf(stderr,
            "c-: type error: safe-mode typed AST cannot represent %s at %s:%d; "
            "wrap intentional C in unsafe or inline c\n",
            what, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
    exit(1);
}

static int return_has_value(const char *text)
{
    const char *p = skip_ws(text == NULL ? "" : text);
    const char *value;

    if (!starts_word(p, "return")) {
        const char *last = NULL;
        const char *scan = p;

        while ((scan = strstr(scan, "return")) != NULL) {
            if ((scan == p || !is_ident((unsigned char)scan[-1])) &&
                !is_ident((unsigned char)scan[6])) {
                last = scan;
            }
            scan += 6;
        }
        if (last == NULL) return 0;
        p = last;
    }
    value = skip_ws(p + 6);
    return *value != ';' && *value != '\0';
}

static void validate_safe_expression_unknowns(const struct SafetyExprNode *expr)
{
    for (; expr != NULL; expr = expr->next) {
        if (!type_is_known(expr->type) &&
            (expr->unknown_reason == SAFETY_UNKNOWN_NONE ||
             expr->unknown_reason == SAFETY_UNKNOWN_UNCLASSIFIED)) {
            fail_incomplete_safe_ast("an expression with an unclassified unknown type");
        }
        validate_safe_expression_unknowns(expr->lhs);
        validate_safe_expression_unknowns(expr->rhs);
        validate_safe_expression_unknowns(expr->child);
    }
}

static void validate_safe_typed_ast(const struct Node *node)
{
    if (!safe_typed_ast_validation_enabled()) return;
    for (; node != NULL; node = node->next) {
        validate_safe_expression_unknowns(node->expr);
        validate_safe_expression_unknowns(node->inc_expr);
        if ((node->kind == ND_EXPR_STMT || node->kind == ND_ASSIGN) &&
            node->expr == NULL) {
            fail_incomplete_safe_ast("an expression statement");
        }
        if (node->kind == ND_DECL) {
            struct DeclInfo decl;

            if (parse_decl(ast_skip_leading_gnu_attributes(node->tok), &decl) &&
                decl.is_decl &&
                decl.has_init && node->expr == NULL) {
                fail_incomplete_safe_ast("a declaration initializer");
            }
        }
        if (node->kind == ND_RETURN && node->expr == NULL &&
            return_has_value(node->tok)) {
            fail_incomplete_safe_ast("a return expression");
        }
        if (node->kind == ND_CASE && node->expr == NULL) {
            fail_incomplete_safe_ast("a case expression");
        }
        if (node->kind == ND_STATIC_ASSERT && node->expr == NULL) {
            fail_incomplete_safe_ast("a static assertion condition");
        }
        if (node->kind == ND_WHILE && node->expr == NULL) {
            fail_incomplete_safe_ast("a while condition");
        }
        if (node->kind == ND_EXPANSION) {
            validate_safe_typed_ast(node->body);
        }
    }
}

static int for_has_condition(const char *text)
{
    const char *open = strchr(text == NULL ? "" : text, '(');
    const char *close = open == NULL ? NULL : matching_paren(open);
    const char *first;
    const char *second;

    if (open == NULL || close == NULL) return 1;
    first = find_top_level_char(open + 1, close, ';');
    second = first == NULL ? NULL : find_top_level_char(first + 1, close, ';');
    if (first == NULL || second == NULL) return 1;
    return skip_ws(first + 1) != second;
}

static void validate_safe_control_ast(const struct Node *node)
{
    const char *p;

    if (!safe_typed_ast_validation_enabled() || node == NULL) return;
    p = skip_ws(node->tok == NULL ? "" : node->tok);
    if (node->kind == ND_IF && node->expr == NULL) {
        if (starts_word(p, "else") &&
            !starts_word(skip_ws(p + 4), "if")) {
            return;
        }
        fail_incomplete_safe_ast("an if condition");
    }
    if ((node->kind == ND_WHILE || node->kind == ND_SWITCH) &&
        node->expr == NULL) {
        fail_incomplete_safe_ast(node->kind == ND_WHILE ?
                                 "a while condition" : "a switch expression");
    }
    if (node->kind == ND_FOR) {
        if (node->lhs != NULL) validate_safe_typed_ast(node->lhs);
        if (for_has_condition(node->tok) && node->expr == NULL) {
            fail_incomplete_safe_ast("a for condition");
        }
        if (node->inc_expr == NULL) {
            const char *open = strchr(node->tok == NULL ? "" : node->tok, '(');
            const char *close = open == NULL ? NULL : matching_paren(open);
            const char *first = (open == NULL || close == NULL) ? NULL :
                find_top_level_char(open + 1, close, ';');
            const char *second = first == NULL ? NULL :
                find_top_level_char(first + 1, close, ';');

            if (second != NULL && skip_ws(second + 1) != close) {
                fail_incomplete_safe_ast("a for increment expression");
            }
        }
    }
}

static void ast_emit_node(struct Text *out, const struct Node *node)
{
    for (; node != NULL; node = node->next) {
        if (node->open_tok != NULL && node->body_tok != NULL &&
            node->close_tok != NULL) {
            if (node->tok != NULL) {
                text_add(out, node->tok);
            }
            text_add(out, node->open_tok);
            text_add(out, node->body_tok);
            text_add(out, node->close_tok);
        } else {
            ast_emit_statement(out, node);
        }
    }
}

static struct Text *finalize_typed_label(struct Text *in, enum NodeKind kind)
{
    struct Node *node;
    struct Text *out;
    const char *p;

    if (in == NULL) {
        return NULL;
    }
    node = ast_new(kind, in->text);
    p = skip_ws(node->tok);
    if (kind == ND_LABEL && is_ident_start((unsigned char)*p)) {
        const char *end;
        char name[NAME_MAX_LEN];

        end = read_name(p, name);
        (void)end;
        strncpy(node->name, name, NAME_MAX_LEN - 1);
        node->name[NAME_MAX_LEN - 1] = '\0';
    } else if (kind == ND_CASE && starts_word(p, "case")) {
        const char *value = skip_ws(p + 4);
        const char *colon = strrchr(value, ':');

        if (colon != NULL) {
            node->expr = safety_parse_range(value, colon);
            if (node->expr != NULL) {
                node->ty = type_copy(node->expr->type);
            }
        }
    }
    validate_safe_typed_ast(node);
    out = text_new();
    out->tail_return = in->tail_return;
    out->ast = node;
    ast_emit_node(out, node);
    in->ast = NULL;
    text_free(in);
    return out;
}

static struct Text *finalize_typed_block(struct Text *lb, struct Text *body,
                                         struct Text *rb)
{
    struct Node *node = ast_block(body->ast);
    struct Text *out = text_new();

    node->open_tok = xstrdup(lb->text);
    node->body_tok = xstrdup(body->text);
    node->close_tok = xstrdup(rb->text);
    out->ast = node;
    ast_emit_node(out, node);
    body->ast = NULL;
    text_free(lb);
    text_free(body);
    text_free(rb);
    return out;
}

static struct Text *finalize_typed_raw(struct Text *in, enum NodeKind kind)
{
    struct Node *node;
    struct Text *out;
    const char *p;

    if (in == NULL || in->len == 0) {
        return in;
    }
    p = skip_ws(in->text);
    if (kind == ND_PP && starts_word(p, "typedef") && strstr(p, "(*") != NULL) {
        struct DeclInfo decl;

        if (parse_decl(p, &decl) && decl.is_typedef && decl.name[0] != '\0') {
            typedef_alias_add(decl.name, decl.type);
            return finalize_typed_statement(in, ND_DECL);
        }
    }
    node = ast_new(kind, in->text);
    out = text_new();
    out->tail_return = in->tail_return;
    out->ast = node;
    ast_emit_node(out, node);
    in->ast = NULL;
    text_free(in);
    return out;
}

static const char *skip_enum_trivia(const char *p, const char *end)
{
    for (;;) {
        while (p < end && isspace((unsigned char)*p)) p++;
        if (p + 1 < end && p[0] == '/' && p[1] == '*') {
            p += 2;
            while (p + 1 < end && !(p[0] == '*' && p[1] == '/')) p++;
            if (p + 1 < end) p += 2;
            continue;
        }
        if (p + 1 < end && p[0] == '/' && p[1] == '/') {
            p += 2;
            while (p < end && *p != '\n') p++;
            continue;
        }
        return p;
    }
}

static int ast_constant_integer(const struct SafetyExprNode *expr, long *value)
{
    long lhs;
    long rhs;

    if (expr == NULL) return 0;
    if (expr->kind == SAFETY_EXPR_LITERAL && expr->has_constant_integer) {
        *value = expr->integer;
        return 1;
    }
    if (expr->kind == SAFETY_EXPR_GROUP) {
        return ast_constant_integer(expr->lhs, value);
    }
    if (expr->kind == SAFETY_EXPR_CAST) {
        return ast_constant_integer(expr->lhs, value);
    }
    if (expr->kind == SAFETY_EXPR_UNARY &&
        ast_constant_integer(expr->lhs, &lhs)) {
        if (strcmp(expr->op, "+") == 0) *value = lhs;
        else if (strcmp(expr->op, "-") == 0) *value = (long)(0UL - (unsigned long)lhs);
        else if (strcmp(expr->op, "!") == 0) *value = !lhs;
        else if (strcmp(expr->op, "~") == 0) *value = ~lhs;
        else return 0;
        return 1;
    }
    if (expr->kind == SAFETY_EXPR_CONDITIONAL) {
        if (!ast_constant_integer(expr->lhs, &lhs)) return 0;
        return ast_constant_integer(lhs ? expr->rhs : expr->child, value);
    }
    if (expr->kind != SAFETY_EXPR_BINARY ||
        !ast_constant_integer(expr->lhs, &lhs) ||
        !ast_constant_integer(expr->rhs, &rhs)) return 0;
    if (strcmp(expr->op, "+") == 0) *value = (long)((unsigned long)lhs + (unsigned long)rhs);
    else if (strcmp(expr->op, "-") == 0) *value = (long)((unsigned long)lhs - (unsigned long)rhs);
    else if (strcmp(expr->op, "*") == 0) *value = (long)((unsigned long)lhs * (unsigned long)rhs);
    else if (strcmp(expr->op, "/") == 0 && rhs != 0 && !(lhs == LONG_MIN && rhs == -1)) *value = lhs / rhs;
    else if (strcmp(expr->op, "%") == 0 && rhs != 0 && !(lhs == LONG_MIN && rhs == -1)) *value = lhs % rhs;
    else if (strcmp(expr->op, "<<") == 0 && rhs >= 0 && rhs < (long)(sizeof(long) * 8)) *value = (long)((unsigned long)lhs << rhs);
    else if (strcmp(expr->op, ">>") == 0 && rhs >= 0 && rhs < (long)(sizeof(long) * 8)) *value = lhs >> rhs;
    else if (strcmp(expr->op, "&") == 0) *value = lhs & rhs;
    else if (strcmp(expr->op, "|") == 0) *value = lhs | rhs;
    else if (strcmp(expr->op, "^") == 0) *value = lhs ^ rhs;
    else if (strcmp(expr->op, "==") == 0) *value = lhs == rhs;
    else if (strcmp(expr->op, "!=") == 0) *value = lhs != rhs;
    else if (strcmp(expr->op, "<") == 0) *value = lhs < rhs;
    else if (strcmp(expr->op, ">") == 0) *value = lhs > rhs;
    else if (strcmp(expr->op, "<=") == 0) *value = lhs <= rhs;
    else if (strcmp(expr->op, ">=") == 0) *value = lhs >= rhs;
    else if (strcmp(expr->op, "&&") == 0) *value = lhs && rhs;
    else if (strcmp(expr->op, "||") == 0) *value = lhs || rhs;
    else return 0;
    return 1;
}

static struct Node *ast_enum_members(const char *body, struct Type enum_type)
{
    struct Node *members = NULL;
    const char *p = body;
    const char *end = body + strlen(body);
    long next_value = 0;
    int next_known = 1;

    while (p < end) {
        const char *piece_end = find_top_level_char(p, end, ',');
        const char *name_end;
        const char *value;
        struct Node *member;
        char name[NAME_MAX_LEN];

        if (piece_end == NULL) piece_end = end;
        p = skip_enum_trivia(p, piece_end);
        if (p >= piece_end || !is_ident_start((unsigned char)*p)) {
            p = piece_end < end ? piece_end + 1 : end;
            continue;
        }
        name_end = read_name(p, name);
        member = ast_new(ND_ENUM_MEMBER, NULL);
        strncpy(member->name, name, NAME_MAX_LEN - 1);
        member->name[NAME_MAX_LEN - 1] = '\0';
        member->ty = type_copy(enum_type);
        symbol_add_to(&g_globals, name, enum_type);
        value = skip_enum_trivia(name_end, piece_end);
        if (value < piece_end && *value == '=') {
            const char *value_start = skip_enum_trivia(value + 1, piece_end);
            const char *value_end = piece_end;

            while (value_end > value_start &&
                   isspace((unsigned char)value_end[-1])) value_end--;
            member->expr = safety_parse_range(value_start, value_end);
            if (ast_constant_integer(member->expr, &member->enum_value)) {
                member->has_enum_value = 1;
                next_value = member->enum_value + 1;
                next_known = 1;
            } else {
                next_known = 0;
            }
        } else if (next_known) {
            member->enum_value = next_value++;
            member->has_enum_value = 1;
        }
        members = ast_append(members, member);
        p = piece_end < end ? piece_end + 1 : end;
    }
    return members;
}

static struct Node *ast_aggregate(const char *head, const char *open_tok,
                                  const char *body_text, const char *close_tok,
                                  struct Node *body)
{
    const char *p = head;
    enum NodeKind kind = ND_RAW;
    enum TypeKind type_kind = TY_UNKNOWN;
    char tag[NAME_MAX_LEN];
    struct Node *node;

    tag[0] = '\0';
    while (strchr(head, '(') == NULL && *p != '\0') {
        char word[NAME_MAX_LEN];
        const char *end;

        if (!is_ident_start((unsigned char)*p)) {
            p++;
            continue;
        }
        end = read_name(p, word);
        if (strcmp(word, "struct") == 0 || strcmp(word, "union") == 0 ||
            strcmp(word, "enum") == 0) {
            const char *name_start = skip_ws(end);

            kind = strcmp(word, "struct") == 0 ? ND_STRUCTDEF :
                (strcmp(word, "union") == 0 ? ND_UNIONDEF : ND_ENUMDEF);
            type_kind = strcmp(word, "struct") == 0 ? TY_STRUCT :
                (strcmp(word, "union") == 0 ? TY_UNION : TY_ENUM);
            if (is_ident_start((unsigned char)*name_start)) {
                read_name(name_start, tag);
            }
            break;
        }
        p = end;
    }
    node = ast_new(kind, head);
    node->open_tok = xstrdup(open_tok);
    node->body_tok = xstrdup(body_text);
    node->close_tok = xstrdup(close_tok);
    node->body = body;
    if (kind == ND_ENUMDEF) {
        node->body = ast_enum_members(body_text,
                                      type_make(TY_ENUM, 0, tag));
    }
    if (kind == ND_STRUCTDEF || kind == ND_UNIONDEF) {
        struct Node *member;
        struct StructFinalizer *registered =
            tag[0] == '\0' ? NULL : struct_clone_find(tag);

        for (member = body; member != NULL; member = member->next) {
            if (member->kind == ND_DECL) {
                member->kind = ND_FIELD;
            }
            if (member->kind == ND_FIELD && registered != NULL) {
                int i;

                for (i = 0; i < registered->count; i++) {
                    if (strcmp(registered->fields[i].name, member->name) == 0) {
                        member->ty = type_copy(registered->fields[i].type);
                        member->type_node = ast_type_node(registered->fields[i].type);
                        break;
                    }
                }
            }
        }
    }
    if (tag[0] != '\0') {
        strncpy(node->name, tag, NAME_MAX_LEN - 1);
        node->name[NAME_MAX_LEN - 1] = '\0';
        node->ty = type_copy(type_make(type_kind, 0, tag));
        if (kind == ND_STRUCTDEF || kind == ND_UNIONDEF) {
            aggregate_ast_add(tag, node);
        }
    }
    return node;
}

static const char *ast_kind_name(enum NodeKind kind)
{
    switch (kind) {
    case ND_BLOCK: return "block";
    case ND_EXPR_STMT: return "expression";
    case ND_RETURN: return "return";
    case ND_DECL: return "declaration";
    case ND_ASSIGN: return "assignment";
    case ND_FUNCDEF: return "function";
    case ND_FUNCDECL: return "function-declaration";
    case ND_PARAM: return "parameter";
    case ND_RETURN_TYPE: return "return-type";
    case ND_TYPEDEF: return "typedef";
    case ND_TYPE_PARAM: return "type-parameter";
    case ND_TYPE: return "type";
    case ND_TYPE_ARGUMENT: return "type-argument";
    case ND_FIELD: return "field";
    case ND_ARRAY_DIMENSION: return "array-dimension";
    case ND_ENUM_MEMBER: return "enum-member";
    case ND_OWNERSHIP: return "ownership";
    case ND_LIFETIME: return "lifetime";
    case ND_MOVE_TRANSFER: return "move-transfer";
    case ND_IF: return "if";
    case ND_WHILE: return "while";
    case ND_FOR: return "for";
    case ND_SWITCH: return "switch";
    case ND_DO: return "do";
    case ND_GOTO: return "goto";
    case ND_BREAK: return "break";
    case ND_CONTINUE: return "continue";
    case ND_STATIC_ASSERT: return "static-assert";
    case ND_LABEL: return "label";
    case ND_CASE: return "case";
    case ND_DEFAULT: return "default";
    case ND_STRUCTDEF: return "struct";
    case ND_UNIONDEF: return "union";
    case ND_ENUMDEF: return "enum";
    case ND_PP: return "preprocessor";
    case ND_CLEANUP: return "cleanup";
    case ND_EXPANSION: return "expansion";
    case ND_DIRECTIVE: return "directive";
    case ND_GENERIC_STRUCT: return "generic-struct";
    case ND_GENERIC_PROTO: return "generic-prototype";
    case ND_GENERIC_FUNCTION: return "generic-function";
    case ND_GENERIC_STRUCT_TEMPLATE: return "generic-struct-template";
    case ND_GENERIC_FUNCTION_TEMPLATE: return "generic-function-template";
    case ND_PAYLOAD_ENUM_TEMPLATE: return "payload-enum-template";
    case ND_PAYLOAD_VARIANT: return "payload-variant";
    case ND_BITFLAGSDEF: return "bitflags";
    case ND_BITFLAG_MEMBER: return "bitflag-member";
    case ND_UNSAFE: return "unsafe";
    case ND_INLINE_C: return "inline-c";
    case ND_RUNTIME_PRELUDE: return "runtime-prelude";
    case ND_PAYLOAD_HELPERS: return "payload-helpers";
    case ND_DEFAULT_MACRO: return "default-macro";
    case ND_TRANSLATION_UNIT: return "translation-unit";
    case ND_SOURCE_PREFIX: return "source-prefix";
    case ND_SOURCE_BODY: return "source-body";
    case ND_S_STRING: return "s-string";
    case ND_RAW: return "raw";
    default: return "node";
    }
}

static const char *safety_expr_kind_name(enum SafetyExprKind kind)
{
    switch (kind) {
    case SAFETY_EXPR_IDENTIFIER: return "identifier";
    case SAFETY_EXPR_LITERAL: return "literal";
    case SAFETY_EXPR_GROUP: return "group";
    case SAFETY_EXPR_GENERIC: return "generic";
    case SAFETY_EXPR_MOVE: return "move";
    case SAFETY_EXPR_UNARY: return "unary";
    case SAFETY_EXPR_UNARY_ADDRESS: return "address";
    case SAFETY_EXPR_UNARY_DEREF: return "dereference";
    case SAFETY_EXPR_CAST: return "cast";
    case SAFETY_EXPR_SIZEOF: return "sizeof";
    case SAFETY_EXPR_ALIGNOF: return "alignof";
    case SAFETY_EXPR_STATEMENT: return "statement-expression";
    case SAFETY_EXPR_INITIALIZER: return "initializer-list";
    case SAFETY_EXPR_OFFSETOF: return "offsetof";
    case SAFETY_EXPR_CALL: return "call";
    case SAFETY_EXPR_INDEX: return "index";
    case SAFETY_EXPR_MEMBER: return "member";
    case SAFETY_EXPR_BINARY: return "binary";
    case SAFETY_EXPR_UPDATE: return "update";
    case SAFETY_EXPR_CONDITIONAL: return "conditional";
    case SAFETY_EXPR_FIXED_INDEX: return "fixed-index";
    case SAFETY_EXPR_RAW_DECAY: return "raw-decay";
    case SAFETY_EXPR_UNSAFE_CALL: return "unsafe-call";
    }
    return "unknown";
}

static const char *safety_unknown_reason_name(enum SafetyUnknownReason reason)
{
    switch (reason) {
    case SAFETY_UNKNOWN_UNRESOLVED_SYMBOL: return "unresolved-symbol";
    case SAFETY_UNKNOWN_UNRESOLVED_CALL_RETURN: return "unresolved-call-return";
    case SAFETY_UNKNOWN_TARGET_SIZE: return "target-dependent-size";
    case SAFETY_UNKNOWN_CONTEXTUAL_LITERAL: return "contextual-literal";
    case SAFETY_UNKNOWN_MEMBER_TYPE: return "unresolved-member-type";
    case SAFETY_UNKNOWN_SYMBOLIC_GENERIC: return "symbolic-generic";
    case SAFETY_UNKNOWN_STATEMENT_RESULT: return "unresolved-statement-result";
    case SAFETY_UNKNOWN_CONTEXTUAL_INITIALIZER: return "contextual-initializer";
    case SAFETY_UNKNOWN_OPERAND_TYPE: return "unknown-operand-type";
    case SAFETY_UNKNOWN_NONE: return "none";
    case SAFETY_UNKNOWN_UNCLASSIFIED: return "unclassified";
    }
    return "unclassified";
}

static int safety_resolve_atomic_call(struct SafetyExprNode *call,
                                      struct SafetyExprNode *callee)
{
    struct Type result;

    if (call == NULL || callee == NULL ||
        callee->kind != SAFETY_EXPR_IDENTIFIER || call->child == NULL ||
        (strcmp(callee->name, "__atomic_load_n") != 0 &&
         strcmp(callee->name, "__atomic_exchange_n") != 0 &&
         strcmp(callee->name, "__atomic_fetch_add") != 0 &&
         strcmp(callee->name, "__atomic_fetch_sub") != 0 &&
         strcmp(callee->name, "__atomic_fetch_or") != 0 &&
         strcmp(callee->name, "__atomic_fetch_and") != 0 &&
         strcmp(callee->name, "__atomic_fetch_xor") != 0)) {
        return 0;
    }
    result = call->child->type;
    if (!type_is_known(result) || result.ptr <= 0) return 0;
    result.ptr--;
    result.owned = 0;
    if (result.ptr == 0) result.raw_ptr = 0;
    call->type = result;
    callee->function_return_type = result;
    callee->type = type_make(TY_FUNCTION, 0, NULL);
    callee->type.base = &callee->function_return_type;
    return 1;
}

static int safety_contextualize_null(struct SafetyExprNode *expr,
                                     struct Type context)
{
    if (expr == NULL || !type_is_known(context)) return 0;
    if (expr->kind == SAFETY_EXPR_IDENTIFIER &&
        strcmp(expr->name, "NULL") == 0 && !type_is_known(expr->type)) {
        context.owned = 0;
        expr->type = context;
        expr->unknown_reason = SAFETY_UNKNOWN_NONE;
        return 1;
    }
    if ((expr->kind == SAFETY_EXPR_GROUP ||
         expr->kind == SAFETY_EXPR_MOVE) && expr->lhs != NULL &&
        safety_contextualize_null(expr->lhs, context)) {
        expr->type = expr->lhs->type;
        expr->unknown_reason = SAFETY_UNKNOWN_NONE;
        return 1;
    }
    return 0;
}

static void safety_contextualize_call_nulls(struct SafetyExprNode *call,
                                            struct SafetyExprNode *callee)
{
    struct FunctionParams *fn = NULL;
    struct SafetyExprNode *arg;
    int index = 0;

    if (callee != NULL && callee->kind == SAFETY_EXPR_IDENTIFIER) {
        fn = function_params_find(callee->name);
    }
    for (arg = call->child; arg != NULL; arg = arg->next, index++) {
        struct Type expected = type_unknown();

        if (fn != NULL && index < fn->count) {
            expected = fn->param[index].type;
        } else if (callee != NULL &&
                   callee->kind == SAFETY_EXPR_IDENTIFIER && index == 1 &&
                   strcmp(callee->name, "pthread_create") == 0) {
            expected = type_make(TY_TYPEDEF, 1, "pthread_attr_t");
            expected.raw_ptr = 1;
        } else if (callee != NULL &&
                   callee->kind == SAFETY_EXPR_IDENTIFIER && index == 1 &&
                   strcmp(callee->name, "pthread_join") == 0) {
            expected = type_make(TY_VOID, 2, NULL);
            expected.raw_ptr = 1;
        } else if (callee != NULL &&
                   callee->kind == SAFETY_EXPR_IDENTIFIER && index == 1 &&
                   strcmp(callee->name, "pthread_mutex_init") == 0) {
            expected = type_make(TY_TYPEDEF, 1, "pthread_mutexattr_t");
            expected.raw_ptr = 1;
        } else if (callee != NULL &&
                   callee->kind == SAFETY_EXPR_IDENTIFIER && index == 1 &&
                   strcmp(callee->name, "pthread_cond_init") == 0) {
            expected = type_make(TY_TYPEDEF, 1, "pthread_condattr_t");
            expected.raw_ptr = 1;
        } else if (callee != NULL &&
                   callee->kind == SAFETY_EXPR_IDENTIFIER && index == 0 &&
                   (strcmp(callee->name, "vsnprintf") == 0 ||
                    strcmp(callee->name, "memcpy") == 0 ||
                    strcmp(callee->name, "memset") == 0 ||
                    strcmp(callee->name, "free") == 0 ||
                    strcmp(callee->name, "cminus_gc_free") == 0)) {
            expected = type_make(TY_VOID, 1, NULL);
            expected.raw_ptr = 1;
        }
        safety_contextualize_null(arg, expected);
    }
}

static int safety_resolve_generic_method_member(struct SafetyExprNode *member)
{
    struct SafetyExprNode *generic;
    struct SafetyExprNode *base;
    struct FunctionParams *fn;
    struct Text *function_name;

    if (member == NULL || member->kind != SAFETY_EXPR_MEMBER ||
        member->lhs == NULL || member->lhs->kind != SAFETY_EXPR_GENERIC) {
        return 0;
    }
    generic = member->lhs;
    base = generic->lhs;
    if (base == NULL || base->kind != SAFETY_EXPR_IDENTIFIER) return 0;
    function_name = text_new();
    text_add(function_name, base->name);
    text_add_ch(function_name, '_');
    text_add(function_name, member->name);
    fn = function_params_find(function_name->text);
    text_free(function_name);
    if (fn == NULL) return 0;
    member->function_return_type = fn->ret;
    member->type = type_make(TY_FUNCTION, 0, NULL);
    member->type.base = &member->function_return_type;
    return 1;
}

static int safety_find_statement_result_type(struct SafetyExprNode *expr,
                                             struct Type *type)
{
    for (; expr != NULL; expr = expr->next) {
        if (expr->statement_result && type_is_known(expr->type)) {
            *type = expr->type;
            return 1;
        }
        if (safety_find_statement_result_type(expr->lhs, type) ||
            safety_find_statement_result_type(expr->rhs, type) ||
            safety_find_statement_result_type(expr->child, type)) {
            return 1;
        }
    }
    return 0;
}

static void safety_final_resolve_expression(struct SafetyExprNode *expr)
{
    struct SafetyExprNode *head = expr;

    for (; expr != NULL; expr = expr->next) {
        struct SafetyExprNode *callee;

        safety_final_resolve_expression(expr->lhs);
        safety_final_resolve_expression(expr->rhs);
        safety_final_resolve_expression(expr->child);
        if (expr->kind == SAFETY_EXPR_IDENTIFIER) {
            safety_resolve_identifier_node(expr);
        } else if (expr->kind == SAFETY_EXPR_GENERIC && expr->lhs != NULL &&
                   expr->lhs->type.kind == TY_TYPE_CONSTRUCTOR) {
            expr->type = expr->lhs->type;
        } else if (expr->kind == SAFETY_EXPR_CALL) {
            callee = expr->lhs;
            while (callee != NULL &&
                   (callee->kind == SAFETY_EXPR_GROUP ||
                    callee->kind == SAFETY_EXPR_GENERIC)) {
                callee = callee->lhs;
            }
            safety_contextualize_call_nulls(expr, callee);
            if (safety_resolve_atomic_call(expr, callee)) {
                /* The GCC atomic value builtins return the pointee type of
                   their first argument. */
            } else if (callee != NULL && callee->type.kind == TY_FUNCTION &&
                callee->type.base != NULL) {
                expr->type = *callee->type.base;
            }
        } else if (expr->kind == SAFETY_EXPR_MEMBER &&
                   safety_resolve_generic_method_member(expr)) {
            /* Symbolic Type<T>.method calls use the generic function
               template signature until a concrete instance is available. */
        } else if (expr->kind == SAFETY_EXPR_MEMBER && expr->lhs != NULL &&
                   expr->lhs->type.kind == TY_STRUCT) {
            struct Type field_type;

            if (struct_field_type(expr->lhs->type.tag, expr->name, &field_type)) {
                expr->type = field_type;
            }
        } else if ((expr->kind == SAFETY_EXPR_INDEX ||
                    expr->kind == SAFETY_EXPR_FIXED_INDEX) && expr->lhs != NULL &&
                   type_is_known(expr->lhs->type)) {
            expr->type = expr->lhs->type;
            expr->type.is_array = 0;
            expr->type.array_len = 0;
            if (expr->type.ptr > 0) expr->type.ptr--;
            if (expr->type.ptr == 0) expr->type.raw_ptr = 0;
        } else if (expr->kind == SAFETY_EXPR_GROUP && expr->lhs != NULL) {
            expr->type = expr->lhs->type;
        } else if (expr->kind == SAFETY_EXPR_STATEMENT) {
            struct Type result;

            if (safety_find_statement_result_type(expr->child, &result)) {
                expr->type = result;
            }
        } else if ((expr->kind == SAFETY_EXPR_UPDATE ||
                    expr->kind == SAFETY_EXPR_UNARY) && expr->lhs != NULL) {
            expr->type = expr->lhs->type;
        } else if (expr->kind == SAFETY_EXPR_UNARY_ADDRESS && expr->lhs != NULL) {
            expr->type = expr->lhs->type;
            expr->type.ptr++;
            expr->type.owned = 0;
        } else if (expr->kind == SAFETY_EXPR_UNARY_DEREF && expr->lhs != NULL &&
                   expr->lhs->type.ptr > 0) {
            expr->type = expr->lhs->type;
            expr->type.ptr--;
            expr->type.owned = 0;
            if (expr->type.ptr == 0) expr->type.raw_ptr = 0;
        } else if (expr->kind == SAFETY_EXPR_BINARY) {
            if (expr->lhs != NULL && expr->rhs != NULL) {
                safety_contextualize_null(expr->lhs, expr->rhs->type);
                safety_contextualize_null(expr->rhs, expr->lhs->type);
            }
            if (strcmp(expr->op, "==") == 0 || strcmp(expr->op, "!=") == 0 ||
                strcmp(expr->op, "<") == 0 || strcmp(expr->op, ">") == 0 ||
                strcmp(expr->op, "<=") == 0 || strcmp(expr->op, ">=") == 0 ||
                strcmp(expr->op, "&&") == 0 || strcmp(expr->op, "||") == 0) {
                expr->type = type_make(TY_INT, 0, NULL);
            } else if (expr->lhs != NULL && type_is_known(expr->lhs->type)) {
                expr->type = expr->lhs->type;
            } else if (expr->rhs != NULL && type_is_known(expr->rhs->type)) {
                expr->type = expr->rhs->type;
            }
        } else if (expr->kind == SAFETY_EXPR_CONDITIONAL && expr->rhs != NULL &&
                   expr->child != NULL) {
            safety_contextualize_null(expr->rhs, expr->child->type);
            safety_contextualize_null(expr->child, expr->rhs->type);
            expr->type = type_is_known(expr->rhs->type) ?
                expr->rhs->type : expr->child->type;
        }
    }
    safety_classify_unknown_types(head);
}

static void ast_final_add_local(const char *name, struct Type type)
{
    struct Symbol *symbol;

    if (name == NULL || name[0] == '\0') return;
    symbol = symbol_find_in(&g_locals, name);
    if (symbol != NULL) {
        symbol->type = type;
        return;
    }
    if (g_locals.count >= MAX_SYMBOLS) die("too many final AST local symbols");
    symbol = &g_locals.sym[g_locals.count++];
    memset(symbol, 0, sizeof(*symbol));
    strncpy(symbol->name, name, NAME_MAX_LEN - 1);
    symbol->name[NAME_MAX_LEN - 1] = '\0';
    symbol->type = type;
}

static void ast_final_add_for_head_locals(const char *head)
{
    const char *p = head;

    while (p != NULL && *p != '\0') {
        if (starts_word(p, "for")) {
            const char *open = skip_ws(p + 3);
            const char *close = *open == '(' ? matching_paren(open) : NULL;
            const char *semi = close == NULL ? NULL :
                find_top_level_char(open + 1, close, ';');

            if (semi != NULL) {
                char *initializer = xstrndup(open + 1,
                                             (size_t)(semi - open - 1));
                struct DeclInfo decl;

                if (parse_decl(initializer, &decl) && decl.is_decl &&
                    decl.name[0] != '\0') {
                    ast_final_add_local(decl.name, decl.type);
                }
                free(initializer);
            }
            p = close == NULL ? p + 3 : close + 1;
            continue;
        }
        p++;
    }
}

static void ast_final_resolve_function(struct Node *function)
{
    struct Symbols saved_locals = g_locals;
    struct Type saved_return = g_current_function_ret;
    char saved_name[NAME_MAX_LEN];
    struct Node *param;
    int saved_in_function = g_in_function;

    strncpy(saved_name, g_current_function_name, NAME_MAX_LEN - 1);
    saved_name[NAME_MAX_LEN - 1] = '\0';
    g_locals.count = 0;
    g_in_function = 1;
    strncpy(g_current_function_name, function->name, NAME_MAX_LEN - 1);
    g_current_function_name[NAME_MAX_LEN - 1] = '\0';
    g_current_function_ret = function->ty == NULL ? type_unknown() : *function->ty;
    for (param = function->params; param != NULL; param = param->next) {
        if (param->ty != NULL) ast_final_add_local(param->name, *param->ty);
    }
    ast_final_resolve_nodes(function->body);
    g_locals = saved_locals;
    g_in_function = saved_in_function;
    g_current_function_ret = saved_return;
    strncpy(g_current_function_name, saved_name, NAME_MAX_LEN - 1);
    g_current_function_name[NAME_MAX_LEN - 1] = '\0';
}

static void ast_final_register_functions(struct Node *node)
{
    for (; node != NULL; node = node->next) {
        if (node->kind == ND_FUNCDEF && node->name[0] != '\0' &&
            function_params_find(node->name) == NULL) {
            struct Text *normalized = ast_normalize_function_head(node->tok);

            register_function_params(normalized->text);
            text_free(normalized);
            node->params = ast_function_parameters(node->name);
        }
        ast_final_register_functions(node->lhs);
        ast_final_register_functions(node->body);
    }
}

static void ast_final_register_macro_constants(struct Node *node)
{
    for (; node != NULL; node = node->next) {
        if ((node->kind == ND_DIRECTIVE || node->kind == ND_PP) &&
            node->tok != NULL) {
            const char *p = skip_ws(node->tok);

            if (*p == '#') p = skip_ws(p + 1);
            if (starts_word(p, "define")) {
                const char *name_start = skip_ws(p + 6);

                if (is_ident_start((unsigned char)*name_start)) {
                    char name[NAME_MAX_LEN];
                    const char *name_end = read_name(name_start, name);

                    /* A '(' immediately after the name denotes a function-like
                       macro, not a typed constant value. */
                    if (*name_end != '(') {
                        const char *value = skip_ws(name_end);
                        const char *end = node->tok + strlen(node->tok);
                        struct SafetyExprNode *expr =
                            safety_parse_range(value, end);

                        if (expr != NULL && type_is_known(expr->type)) {
                            struct Symbol *existing =
                                symbol_find_in(&g_globals, name);

                            if (existing == NULL) {
                                symbol_add_to(&g_globals, name, expr->type);
                                existing = symbol_find_in(&g_globals, name);
                                if (existing != NULL) {
                                    existing->var = NULL;
                                }
                            }
                        }
                        safety_expr_free(expr);
                    }
                }
            }
        }
        ast_final_register_macro_constants(node->lhs);
        ast_final_register_macro_constants(node->body);
    }
}

static void safety_contextualize_default_symbols(struct SafetyExprNode *expr,
                                                 struct Type expected)
{
    for (; expr != NULL; expr = expr->next) {
        if (expr->kind == SAFETY_EXPR_IDENTIFIER &&
            !type_is_known(expr->type)) {
            expr->type = expected;
            expr->unknown_reason = SAFETY_UNKNOWN_NONE;
        }
        safety_contextualize_default_symbols(expr->lhs, expected);
        safety_contextualize_default_symbols(expr->rhs, expected);
        safety_contextualize_default_symbols(expr->child, expected);
    }
}

static void ast_final_resolve_nodes(struct Node *node)
{
    for (; node != NULL; node = node->next) {
        if (node->kind == ND_FUNCDEF ||
            node->kind == ND_GENERIC_FUNCTION_TEMPLATE) {
            ast_final_resolve_function(node);
            continue;
        }
        if (node->kind == ND_FOR && node->lhs != NULL) {
            ast_final_resolve_nodes(node->lhs);
        }
        if (node->kind == ND_FOR && node->tok != NULL) {
            ast_final_add_for_head_locals(node->tok);
        }
        if (node->kind == ND_FUNCDECL) {
            struct Node *param;

            for (param = node->params; param != NULL; param = param->next) {
                safety_final_resolve_expression(param->expr);
                if (param->expr != NULL && param->ty != NULL) {
                    safety_contextualize_default_symbols(param->expr,
                                                         *param->ty);
                    safety_final_resolve_expression(param->expr);
                }
            }
        }
        safety_final_resolve_expression(node->expr);
        safety_final_resolve_expression(node->inc_expr);
        if (node->expr != NULL && node->kind == ND_DECL && node->ty != NULL) {
            safety_contextualize_null(node->expr, *node->ty);
        } else if (node->expr != NULL && node->kind == ND_RETURN &&
                   type_is_known(g_current_function_ret)) {
            safety_contextualize_null(node->expr, g_current_function_ret);
        }
        if (g_in_function && node->kind == ND_DECL && node->ty != NULL) {
            ast_final_add_local(node->name, *node->ty);
        }
        ast_final_resolve_nodes(node->body);
    }
}

struct ThreadSafetyContext {
    struct Node *root;
    const char *entry;
    char stack[MAX_FUNCS][NAME_MAX_LEN];
    int depth;
};

static int type_is_atomic_value(struct Type type)
{
    struct GenericInstance *instance = NULL;
    struct GenericTemplate *template;

    if (type.kind != TY_STRUCT || type.ptr != 0) {
        return 0;
    }
    if (strcmp(type.applied_name, "Atomic") == 0) {
        return 1;
    }
    template = generic_struct_find_by_concrete(type.tag, &instance);
    return template != NULL && instance != NULL &&
        strcmp(template->name, "Atomic") == 0;
}

static int atomic_payload_type(struct Type atomic, struct Type *payload)
{
    struct GenericInstance *instance = NULL;
    struct GenericTemplate *template;
    const char *argument = NULL;
    char type_name[NAME_MAX_LEN];

    if (!type_is_atomic_value(atomic)) {
        return 0;
    }
    if (strcmp(atomic.applied_name, "Atomic") == 0 &&
        atomic.applied_args[0] != '\0') {
        argument = atomic.applied_args;
    } else {
        template = generic_struct_find_by_concrete(atomic.tag, &instance);
        if (template != NULL && instance != NULL) {
            argument = instance->arg;
        }
    }
    return argument != NULL &&
        safety_parse_type_range(argument, argument + strlen(argument),
                                payload, type_name);
}

static int type_is_thread_atomic(struct Type type)
{
    struct Type payload = type_unknown();

    if (!atomic_payload_type(type, &payload) || payload.ptr != 0 ||
        payload.raw_ptr || payload.owned || payload.is_array) {
        return 0;
    }
    return payload.kind == TY_CHAR || payload.kind == TY_SHORT ||
        payload.kind == TY_INT || payload.kind == TY_LONG ||
        payload.kind == TY_ENUM || payload.kind == TY_BITFLAGS;
}

static int type_is_thread_sync_global(struct Type type)
{
    if (type.kind != TY_STRUCT || type.ptr != 0) {
        return 0;
    }
    if (strcmp(type.tag, "Mutex") == 0 || strcmp(type.tag, "Cond") == 0) {
        return 1;
    }
    return type_is_thread_atomic(type);
}

static int thread_identifier_is_constant(struct Node *node, const char *name)
{
    for (; node != NULL; node = node->next) {
        if ((node->kind == ND_ENUM_MEMBER ||
             node->kind == ND_BITFLAG_MEMBER ||
             node->kind == ND_DIRECTIVE || node->kind == ND_PP) &&
            strcmp(node->name, name) == 0) {
            return 1;
        }
        if (thread_identifier_is_constant(node->lhs, name) ||
            thread_identifier_is_constant(node->body, name)) {
            return 1;
        }
    }
    return 0;
}

static struct Node *thread_find_function(struct Node *node, const char *name)
{
    struct Node *found;

    for (; node != NULL; node = node->next) {
        if (node->kind == ND_FUNCDEF && strcmp(node->name, name) == 0) {
            return node;
        }
        found = thread_find_function(node->lhs, name);
        if (found != NULL) {
            return found;
        }
        found = thread_find_function(node->body, name);
        if (found != NULL) {
            return found;
        }
    }
    return NULL;
}

static int thread_safety_stack_contains(struct ThreadSafetyContext *context,
                                        const char *name)
{
    int i;

    for (i = 0; i < context->depth; i++) {
        if (strcmp(context->stack[i], name) == 0) {
            return 1;
        }
    }
    return 0;
}

static int thread_call_is_trusted_runtime(const char *name)
{
    return function_signature_is_internal(name) ||
        strncmp(name, "__builtin_", 10) == 0 ||
        strncmp(name, "Thread_", 7) == 0 ||
        strncmp(name, "Mutex_", 6) == 0 ||
        strncmp(name, "Cond_", 5) == 0 ||
        strcmp(name, "memset") == 0 || strcmp(name, "memcpy") == 0;
}

static void thread_analyze_function(struct ThreadSafetyContext *context,
                                    struct Node *function);

static void thread_analyze_expression(struct ThreadSafetyContext *context,
                                      struct SafetyExprNode *expr)
{
    for (; expr != NULL; expr = expr->next) {
        if (expr->kind == SAFETY_EXPR_IDENTIFIER && expr->symbol_is_global &&
            expr->type.kind != TY_FUNCTION &&
            !type_is_thread_sync_global(expr->type) &&
            !thread_identifier_is_constant(context->root, expr->name)) {
            if (type_is_atomic_value(expr->type)) {
                fprintf(stderr,
                        "c-: thread safety error: global Atomic value '%s' has a non-Sync payload; safe Atomic<T> requires a non-pointer integer, enum, or bitflags payload\n",
                        expr->name);
                exit(1);
            }
            fprintf(stderr,
                    "c-: thread safety error: Thread.spawn entry '%s' accesses ordinary global '%s'; use Atomic<T> or move the state into a later Send-capable thread argument\n",
                    context->entry, expr->name);
            exit(1);
        }
        if (expr->kind == SAFETY_EXPR_CALL) {
            struct SafetyExprNode *callee = expr->lhs;

            if (callee == NULL || callee->kind != SAFETY_EXPR_IDENTIFIER) {
                fprintf(stderr,
                        "c-: thread safety error: Thread.spawn entry '%s' uses an indirect call that cannot be proven thread-safe\n",
                        context->entry);
                exit(1);
            }
            if (!thread_call_is_trusted_runtime(callee->name)) {
                struct Node *called =
                    thread_find_function(context->root, callee->name);

                if (called == NULL) {
                    fprintf(stderr,
                            "c-: thread safety error: Thread.spawn entry '%s' calls '%s' without a visible safe definition\n",
                            context->entry, callee->name);
                    exit(1);
                }
                thread_analyze_function(context, called);
            }
        }
        thread_analyze_expression(context, expr->lhs);
        thread_analyze_expression(context, expr->rhs);
        thread_analyze_expression(context, expr->child);
    }
}

static void thread_analyze_nodes(struct ThreadSafetyContext *context,
                                 struct Node *node)
{
    for (; node != NULL; node = node->next) {
        thread_analyze_expression(context, node->expr);
        thread_analyze_expression(context, node->inc_expr);
        thread_analyze_nodes(context, node->lhs);
        thread_analyze_nodes(context, node->body);
    }
}

static void thread_analyze_function(struct ThreadSafetyContext *context,
                                    struct Node *function)
{
    if (function == NULL || function->name[0] == '\0' ||
        thread_safety_stack_contains(context, function->name)) {
        return;
    }
    if (context->depth >= MAX_FUNCS) {
        die("thread safety call graph is too deep");
    }
    strncpy(context->stack[context->depth], function->name, NAME_MAX_LEN - 1);
    context->stack[context->depth][NAME_MAX_LEN - 1] = '\0';
    context->depth++;
    thread_analyze_nodes(context, function->body);
    context->depth--;
}

static void thread_validate_spawn_expression(struct Node *root,
                                             struct SafetyExprNode *expr)
{
    for (; expr != NULL; expr = expr->next) {
        if (expr->kind == SAFETY_EXPR_CALL && expr->lhs != NULL &&
            expr->lhs->kind == SAFETY_EXPR_IDENTIFIER &&
            strcmp(expr->lhs->name, "Thread_spawn") == 0) {
            struct SafetyExprNode *argument = expr->child;
            struct ThreadSafetyContext context;
            struct Node *entry;

            if (argument == NULL || argument->kind != SAFETY_EXPR_IDENTIFIER) {
                fprintf(stderr,
                        "c-: thread safety error: Thread.spawn requires a directly named entry function in safe mode\n");
                exit(1);
            }
            entry = thread_find_function(root, argument->name);
            if (entry == NULL) {
                fprintf(stderr,
                        "c-: thread safety error: Thread.spawn entry '%s' has no visible safe definition\n",
                        argument->name);
                exit(1);
            }
            memset(&context, 0, sizeof(context));
            context.root = root;
            context.entry = argument->name;
            thread_analyze_function(&context, entry);
        }
        thread_validate_spawn_expression(root, expr->lhs);
        thread_validate_spawn_expression(root, expr->rhs);
        thread_validate_spawn_expression(root, expr->child);
    }
}

static void validate_thread_spawn_safety(struct Node *root, struct Node *node)
{
    int top = root == node;
    int i;

    for (; node != NULL; node = node->next) {
        thread_validate_spawn_expression(root, node->expr);
        thread_validate_spawn_expression(root, node->inc_expr);
        validate_thread_spawn_safety(root, node->lhs);
        validate_thread_spawn_safety(root, node->body);
    }
    if (top) {
        for (i = 0; i < g_thread_owned_entry_count; i++) {
            struct ThreadSafetyContext context;
            struct Node *entry = thread_find_function(
                root, g_thread_owned_entries[i]);

            if (entry == NULL) {
                fprintf(stderr,
                        "c-: thread safety error: Thread.spawn worker '%s' has no visible safe definition\n",
                        g_thread_owned_entries[i]);
                exit(1);
            }
            memset(&context, 0, sizeof(context));
            context.root = root;
            context.entry = g_thread_owned_entries[i];
            thread_analyze_function(&context, entry);
        }
    }
}

static void dump_typed_expression(FILE *out,
                                  const struct SafetyExprNode *expr,
                                  int depth,
                                  const char *role)
{
    for (; expr != NULL; expr = expr->next) {
        const char *lhs_role = "lhs";
        const char *rhs_role = "rhs";
        const char *child_role = "child";
        int i;

        if (expr->kind == SAFETY_EXPR_CALL) {
            lhs_role = "callee";
            child_role = "argument";
        } else if (expr->kind == SAFETY_EXPR_INDEX ||
                   expr->kind == SAFETY_EXPR_FIXED_INDEX) {
            lhs_role = "receiver";
            rhs_role = "index";
        } else if (expr->kind == SAFETY_EXPR_MEMBER) {
            lhs_role = "receiver";
        } else if (expr->kind == SAFETY_EXPR_GROUP) {
            lhs_role = "inner";
        } else if (expr->kind == SAFETY_EXPR_UPDATE) {
            lhs_role = "operand";
        } else if (expr->kind == SAFETY_EXPR_UNARY ||
                   expr->kind == SAFETY_EXPR_UNARY_ADDRESS ||
                   expr->kind == SAFETY_EXPR_UNARY_DEREF ||
                   expr->kind == SAFETY_EXPR_CAST ||
                   expr->kind == SAFETY_EXPR_SIZEOF ||
                   expr->kind == SAFETY_EXPR_ALIGNOF) {
            lhs_role = "operand";
        } else if (expr->kind == SAFETY_EXPR_STATEMENT) {
            child_role = "body-expression";
        } else if (expr->kind == SAFETY_EXPR_CONDITIONAL) {
            lhs_role = "condition";
            rhs_role = "then";
            child_role = "else";
        }
        for (i = 0; i < depth; i++) {
            fputs("  ", out);
        }
        fprintf(out, "%s %s", role, safety_expr_kind_name(expr->kind));
        if (expr->name[0] != '\0') {
            fprintf(out, " name=%s", expr->name);
        }
        if (expr->generic_arg[0] != '\0') {
            fprintf(out, " generic=%s", expr->generic_arg);
        }
        if (expr->type_name[0] != '\0') {
            fprintf(out, " target=\"%s\"", expr->type_name);
        }
        if (expr->op[0] != '\0') {
            fprintf(out, " op=%s", expr->op);
        }
        if (expr->kind == SAFETY_EXPR_UPDATE) {
            fprintf(out, " form=%s", expr->postfix ? "postfix" : "prefix");
        }
        if (expr->statement_result) {
            fputs(" result=yes", out);
        }
        if (expr->has_constant_integer) {
            fprintf(out, " value=%ld", expr->integer);
        }
        if (type_is_known(expr->type)) {
            char type_text[NAME_MAX_LEN * 2];

            type_to_string(expr->type, type_text, sizeof(type_text));
            fprintf(out, " type=%s", type_text);
        } else {
            fprintf(out, " type=unknown reason=%s",
                    safety_unknown_reason_name(expr->unknown_reason));
        }
        fputc('\n', out);
        if (expr->lhs != NULL) {
            dump_typed_expression(out, expr->lhs, depth + 1, lhs_role);
        }
        if (expr->rhs != NULL) {
            dump_typed_expression(out, expr->rhs, depth + 1, rhs_role);
        }
        if (expr->child != NULL) {
            dump_typed_expression(out, expr->child, depth + 1, child_role);
        }
    }
}

static void dump_typed_ast(FILE *out, const struct Node *node, int depth)
{
    for (; node != NULL; node = node->next) {
        int i;

        for (i = 0; i < depth; i++) {
            fputs("  ", out);
        }
        fputs(ast_kind_name(node->kind), out);
        if (node->name[0] != '\0') {
            fprintf(out, " %s", node->name);
        }
        if (node->kind == ND_PAYLOAD_VARIANT && node->type_name[0] != '\0') {
            fprintf(out, " type=%s", node->type_name);
        }
        if (node->kind == ND_PAYLOAD_ENUM_TEMPLATE && node->type_name[0] != '\0') {
            fprintf(out, " parameter=%s", node->type_name);
        }
        if (node->kind == ND_BITFLAGSDEF && node->type_name[0] != '\0') {
            fprintf(out, " base=%s", node->type_name);
        }
        if (node->kind == ND_LIFETIME) {
            fprintf(out, " owner=%s storage=%s state=%s",
                    node->type_name,
                    node->caller_owner ? "caller" :
                        (node->stack_owner ? "stack" : "owned"),
                    node->dead ? "dead" : "live");
            if (node->runtime_checked) {
                fputs(" runtime-check=yes", out);
            }
        }
        if (node->kind == ND_MOVE_TRANSFER) {
            fprintf(out, " source=%s", node->type_name);
        }
        if (node->kind == ND_ARRAY_DIMENSION) {
            if (node->array_len > 0) {
                fprintf(out, " length=%d", node->array_len);
            } else {
                fputs(" length=unknown", out);
            }
        }
        if (node->kind == ND_ENUM_MEMBER && node->has_enum_value) {
            fprintf(out, " value=%ld", node->enum_value);
        }
        if ((node->kind == ND_PARAM || node->kind == ND_RETURN_TYPE ||
             node->kind == ND_TYPEDEF ||
             node->kind == ND_TYPE_PARAM || node->kind == ND_TYPE ||
             node->kind == ND_TYPE_ARGUMENT || node->kind == ND_ENUM_MEMBER) &&
            node->ty != NULL) {
            char type_text[NAME_MAX_LEN * 2];

            type_to_string(*node->ty, type_text, sizeof(type_text));
            fprintf(out, " type=%s", type_text);
            if (node->kind == ND_TYPE_ARGUMENT && node->type_name[0] != '\0' &&
                strcmp(node->type_name, type_text) != 0) {
                fprintf(out, " source=\"%s\"", node->type_name);
            }
            if (node->ty->applied_name[0] != '\0') {
                fprintf(out, " application=%s", node->ty->applied_name);
            }
        }
        if (node->kind == ND_PARAM && node->expr != NULL) {
            fprintf(out, " default=%s", safety_expr_kind_name(node->expr->kind));
        } else if (node->expr != NULL) {
            fprintf(out, " expression=%s", safety_expr_kind_name(node->expr->kind));
        }
        if (node->lhs != NULL && node->kind == ND_FOR) {
            fprintf(out, " initializer=%s", ast_kind_name(node->lhs->kind));
        }
        if (node->inc_expr != NULL) {
            fprintf(out, " increment=%s", safety_expr_kind_name(node->inc_expr->kind));
        }
        fputc('\n', out);
        if (node->type_node != NULL) {
            dump_typed_ast(out, node->type_node, depth + 1);
        }
        if (node->type_args != NULL) {
            dump_typed_ast(out, node->type_args, depth + 1);
        }
        if (node->dimensions != NULL) {
            dump_typed_ast(out, node->dimensions, depth + 1);
        }
        if (node->ownership != NULL) {
            dump_typed_ast(out, node->ownership, depth + 1);
        }
        if (node->lifetime != NULL) {
            dump_typed_ast(out, node->lifetime, depth + 1);
        }
        if (node->move_transfer != NULL) {
            dump_typed_ast(out, node->move_transfer, depth + 1);
        }
        if (node->expr != NULL) {
            dump_typed_expression(out, node->expr, depth + 1, "expr");
        }
        if (node->inc_expr != NULL) {
            dump_typed_expression(out, node->inc_expr, depth + 1, "increment-expr");
        }
        if (node->type_params != NULL) {
            dump_typed_ast(out, node->type_params, depth + 1);
        }
        if (node->return_type != NULL) {
            dump_typed_ast(out, node->return_type, depth + 1);
        }
        if (node->params != NULL) {
            dump_typed_ast(out, node->params, depth + 1);
        }
        if (node->body != NULL) {
            dump_typed_ast(out, node->body, depth + 1);
        }
        if (node->kind == ND_RETURN && node->lhs != NULL) {
            dump_typed_ast(out, node->lhs, depth + 1);
        }
    }
}

static void emit_generated_text(FILE *out, enum NodeKind kind,
                                const char *name, struct Text *text)
{
    emit_generated_text_ast(out, kind, name, text, NULL);
}

static void emit_generated_text_ast(FILE *out, enum NodeKind kind,
                                    const char *name, struct Text *text,
                                    struct Node *body)
{
    struct Node *node;

    if (text == NULL || text->len == 0) {
        text_free(text);
        return;
    }
    node = ast_new(kind, text->text);
    if (name != NULL) {
        strncpy(node->name, name, NAME_MAX_LEN - 1);
        node->name[NAME_MAX_LEN - 1] = '\0';
    }
    node->body = body;
    g_generated_artifacts = ast_append(g_generated_artifacts, node);
    fputs(node->tok, out);
    text_free(text);
}

static void emit_ast_output(FILE *out, const struct Node *node)
{
    struct Text *rendered = text_new();

    ast_emit_node(rendered, node);
    fputs(rendered->text, out);
    text_free(rendered);
}

static struct Text *read_generated_stream(FILE *stream)
{
    struct Text *text = text_new();
    char buffer[4096];
    size_t count;

    if (fflush(stream) != 0 || fseek(stream, 0, SEEK_SET) != 0) {
        die("cannot rewind generated output stream");
    }
    while ((count = fread(buffer, 1, sizeof(buffer), stream)) > 0) {
        text_add_n(text, buffer, count);
    }
    if (ferror(stream)) {
        die("cannot read generated output stream");
    }
    return text;
}

static const struct SafetyExprNode *safety_strip_groups(const struct SafetyExprNode *node)
{
    while (node != NULL && node->kind == SAFETY_EXPR_GROUP) {
        node = node->lhs;
    }
    return node;
}

static int safety_ast_plain_identifier(const char *start, const char *end, char *name)
{
    struct SafetyExprNode *tree = safety_parse_range(start, end);
    const struct SafetyExprNode *node = safety_strip_groups(tree);
    int result = node != NULL && node->kind == SAFETY_EXPR_IDENTIFIER;

    name[0] = '\0';
    if (result) {
        strncpy(name, node->name, NAME_MAX_LEN - 1);
        name[NAME_MAX_LEN - 1] = '\0';
    }
    safety_expr_free(tree);
    return result;
}

static int safety_ast_move_identifier(const char *start, const char *end, char *name)
{
    char *text = xstrndup(start, (size_t)(end - start));
    struct SafetyExprNode *tree = safety_parse_forest(text);
    const struct SafetyExprNode *found = NULL;
    const struct SafetyExprNode *stack[256];
    int count = 0;
    int result = 0;

    name[0] = '\0';
    if (tree != NULL) {
        stack[count++] = tree;
    }
    while (count > 0 && found == NULL) {
        const struct SafetyExprNode *node = stack[--count];
        for (; node != NULL && found == NULL; node = node->next) {
            const struct SafetyExprNode *value;
            if (node->kind == SAFETY_EXPR_MOVE) {
                value = safety_strip_groups(node->lhs);
                if (value != NULL && value->kind == SAFETY_EXPR_IDENTIFIER) {
                    found = value;
                    break;
                }
            }
            if (count + 3 < (int)(sizeof(stack) / sizeof(stack[0]))) {
                if (node->lhs != NULL) stack[count++] = node->lhs;
                if (node->rhs != NULL) stack[count++] = node->rhs;
                if (node->child != NULL) stack[count++] = node->child;
            }
        }
    }
    if (found != NULL) {
        strncpy(name, found->name, NAME_MAX_LEN - 1);
        name[NAME_MAX_LEN - 1] = '\0';
        result = 1;
    }
    safety_expr_free(tree);
    free(text);
    return result;
}

static int safety_ast_borrow_root(const char *start, const char *end, char *owner)
{
    struct SafetyExprNode *tree = safety_parse_range(start, end);
    const struct SafetyExprNode *node = safety_strip_groups(tree);
    int result = 0;

    owner[0] = '\0';
    if (node != NULL && node->kind == SAFETY_EXPR_UNARY_ADDRESS) {
        node = safety_strip_groups(node->lhs);
    }
    while (node != NULL && node->kind == SAFETY_EXPR_MEMBER) {
        node = safety_strip_groups(node->lhs);
    }
    if (node != NULL && node->kind == SAFETY_EXPR_IDENTIFIER) {
        strncpy(owner, node->name, NAME_MAX_LEN - 1);
        owner[NAME_MAX_LEN - 1] = '\0';
        result = 1;
    }
    safety_expr_free(tree);
    return result;
}

static struct Type safety_ast_expr_type(const char *expr)
{
    struct SafetyExprNode *tree = safety_parse_range(expr, expr + strlen(expr));
    const struct SafetyExprNode *root = safety_strip_groups(tree);
    struct Type type;

    if (root != NULL && type_is_known(root->type)) {
        type = root->type;
        safety_expr_free(tree);
        return type;
    }
    safety_expr_free(tree);
    return expr_type(expr);
}

static const struct SafetyExprNode *safety_unwrap_group(const struct SafetyExprNode *node)
{
    while (node != NULL && node->kind == SAFETY_EXPR_GROUP) {
        node = node->lhs;
    }
    while (node != NULL && node->kind == SAFETY_EXPR_BINARY && strcmp(node->op, ",") == 0) {
        node = safety_unwrap_group(node->rhs);
    }
    return node;
}

static int safety_callee_name(const struct SafetyExprNode *call, char name[NAME_MAX_LEN])
{
    const struct SafetyExprNode *callee;
    if (call == NULL || call->kind != SAFETY_EXPR_CALL) {
        return 0;
    }
    callee = safety_unwrap_group(call->lhs);
    while (callee != NULL && callee->kind == SAFETY_EXPR_GENERIC) {
        callee = safety_unwrap_group(callee->lhs);
    }
    if (callee == NULL || callee->kind != SAFETY_EXPR_IDENTIFIER) {
        return 0;
    }
    strncpy(name, callee->name, NAME_MAX_LEN - 1);
    name[NAME_MAX_LEN - 1] = '\0';
    return 1;
}

typedef void (*SafetyExprVisitor)(const struct SafetyExprNode *node,
                                  const struct SafetyExprNode *parent,
                                  void *context);

static void safety_expr_walk(const struct SafetyExprNode *node,
                             const struct SafetyExprNode *parent,
                             SafetyExprVisitor visitor,
                             void *context)
{
    for (; node != NULL; node = node->next) {
        visitor(node, parent, context);
        safety_expr_walk(node->lhs, node, visitor, context);
        safety_expr_walk(node->rhs, node, visitor, context);
        safety_expr_walk(node->child, node, visitor, context);
    }
}

static int safety_call_method_parts(const struct SafetyExprNode *call,
                                    char receiver[NAME_MAX_LEN],
                                    char method[NAME_MAX_LEN],
                                    char generic_arg[NAME_MAX_LEN])
{
    const struct SafetyExprNode *callee;
    const struct SafetyExprNode *base;

    receiver[0] = '\0';
    method[0] = '\0';
    generic_arg[0] = '\0';
    if (call == NULL || call->kind != SAFETY_EXPR_CALL) {
        return 0;
    }
    callee = safety_unwrap_group(call->lhs);
    if (callee == NULL || callee->kind != SAFETY_EXPR_MEMBER) {
        return 0;
    }
    strncpy(method, callee->name, NAME_MAX_LEN - 1);
    method[NAME_MAX_LEN - 1] = '\0';
    base = safety_unwrap_group(callee->lhs);
    if (base != NULL && base->kind == SAFETY_EXPR_GENERIC) {
        strncpy(generic_arg, base->generic_arg, NAME_MAX_LEN - 1);
        generic_arg[NAME_MAX_LEN - 1] = '\0';
        base = safety_unwrap_group(base->lhs);
    }
    if (base == NULL || base->kind != SAFETY_EXPR_IDENTIFIER) {
        return 0;
    }
    strncpy(receiver, base->name, NAME_MAX_LEN - 1);
    receiver[NAME_MAX_LEN - 1] = '\0';
    return 1;
}

static int safety_node_borrow_root(const struct SafetyExprNode *node,
                                   char owner[NAME_MAX_LEN])
{
    node = safety_strip_groups(node);
    if (node != NULL && node->kind == SAFETY_EXPR_UNARY_ADDRESS) {
        node = safety_strip_groups(node->lhs);
    }
    while (node != NULL && node->kind == SAFETY_EXPR_MEMBER) {
        node = safety_strip_groups(node->lhs);
    }
    if (node == NULL || node->kind != SAFETY_EXPR_IDENTIFIER) {
        return 0;
    }
    strncpy(owner, node->name, NAME_MAX_LEN - 1);
    owner[NAME_MAX_LEN - 1] = '\0';
    return 1;
}

struct SafetyReferenceBorrowContext {
    char owner[NAME_MAX_LEN];
    int found;
};

static void find_reference_borrow_node(const struct SafetyExprNode *node,
                                       const struct SafetyExprNode *parent,
                                       void *opaque)
{
    struct SafetyReferenceBorrowContext *context = opaque;
    char call_name[NAME_MAX_LEN];
    char receiver[NAME_MAX_LEN];
    char method[NAME_MAX_LEN];
    char generic_arg[NAME_MAX_LEN];
    int constructor = 0;
    (void)parent;

    if (context->found || node->kind != SAFETY_EXPR_CALL || node->child == NULL) {
        return;
    }
    if (safety_callee_name(node, call_name)) {
        constructor = strncmp(call_name, "Ref_from_", 9) == 0 ||
            strncmp(call_name, "Span_from_", 10) == 0 ||
            strncmp(call_name, "Span_from_bytes_", 16) == 0 ||
            strncmp(call_name, "Span_map_from_", 14) == 0 ||
            strncmp(call_name, "RingBuffer_from_", 16) == 0 ||
            strncmp(call_name, "RingBuffer_from_bytes_", 22) == 0 ||
            strcmp(call_name, "Bitmap_from") == 0 ||
            strcmp(call_name, "Bitmap_from_words") == 0 ||
            strcmp(call_name, "Bitmap_from_bytes") == 0;
    } else if (safety_call_method_parts(node, receiver, method, generic_arg)) {
        constructor = (strcmp(receiver, "Ref") == 0 && strcmp(method, "from") == 0) ||
            (strcmp(receiver, "Span") == 0 &&
             (strcmp(method, "from") == 0 || strcmp(method, "from_bytes") == 0 ||
              strcmp(method, "map_from") == 0)) ||
            (strcmp(receiver, "RingBuffer") == 0 &&
             (strcmp(method, "from") == 0 || strcmp(method, "from_bytes") == 0));
    }
    if (constructor && safety_node_borrow_root(node->child, context->owner)) {
        context->found = 1;
    }
}

static int safety_ast_reference_borrow_owner(const char *expr, char *owner)
{
    struct SafetyExprNode *forest = safety_parse_forest(expr);
    struct SafetyReferenceBorrowContext context;

    memset(&context, 0, sizeof(context));
    safety_expr_walk(forest, NULL, find_reference_borrow_node, &context);
    owner[0] = '\0';
    if (context.found) {
        strncpy(owner, context.owner, NAME_MAX_LEN - 1);
        owner[NAME_MAX_LEN - 1] = '\0';
    }
    safety_expr_free(forest);
    return context.found;
}

static int is_checked_array_constructor(const char *name)
{
    return strncmp(name, "Span_from_", 10) == 0 ||
        strncmp(name, "Span_from_bytes_", 16) == 0 ||
        strncmp(name, "Span_map_from_", 14) == 0 ||
        strncmp(name, "FixedVec_from_", 14) == 0 ||
        strncmp(name, "FixedVec_from_bytes_", 20) == 0 ||
        strncmp(name, "RingBuffer_from_", 16) == 0 ||
        strncmp(name, "RingBuffer_from_bytes_", 22) == 0 ||
        strcmp(name, "Bitmap_from") == 0 ||
        strcmp(name, "Bitmap_from_words") == 0 ||
        strcmp(name, "Bitmap_from_bytes") == 0;
}

static int fixed_array_use_is_checked_context(const char *stmt, const char *expr)
{
    const char *before = skip_safe_trivia_backward(stmt, expr);
    const char *name_end;
    const char *name_start;
    char name[NAME_MAX_LEN];

    if (before == stmt || before[-1] != '(') {
        const char *call = stmt;

        while (*call != '\0') {
            if (is_ident_start((unsigned char)*call)) {
                char call_name[NAME_MAX_LEN];
                const char *name_end = read_name(call, call_name);

                if (is_bounded_array_output_call(call_name)) {
                    const char *open = skip_ws(name_end);
                    const char *close = *open == '(' ? matching_paren(open) : NULL;
                    const char *arg1_end = close == NULL ? NULL : find_top_level_char(open + 1, close, ',');
                    const char *arg2_start = arg1_end == NULL ? NULL : skip_ws(arg1_end + 1);

                    if (arg2_start == expr) {
                        return 1;
                    }
                }
                call = name_end;
            } else {
                call++;
            }
        }
        return 0;
    }
    before = skip_safe_trivia_backward(stmt, before - 1);
    name_end = before;
    while (before > stmt && is_ident((unsigned char)before[-1])) {
        before--;
    }
    name_start = before;
    if (name_start == name_end || (size_t)(name_end - name_start) >= sizeof(name)) {
        return 0;
    }
    memcpy(name, name_start, (size_t)(name_end - name_start));
    name[name_end - name_start] = '\0';
    return strcmp(name, "sizeof") == 0 || strcmp(name, "_Alignof") == 0 ||
        strcmp(name, "__alignof__") == 0 ||
        strcmp(name, "addr_of") == 0 ||
        strcmp(name, "cminus_stack_note_caller_range") == 0 ||
        is_checked_array_constructor(name);
}

static void validate_fixed_array_index_node(struct SafetyExprNode *node)
{
    if (!node->has_constant_integer) {
        fprintf(stderr, "c-: type error: variable index into fixed array '%s' is not allowed in safe mode at %s:%d; create a Span with Span<T>.from(%s) and index the Span\n",
                node->name, g_input_path == NULL ? "<unknown>" : g_input_path,
                yylineno, node->name);
        exit(1);
    }
    if (node->integer < 0 || node->integer >= node->type.array_len) {
        fprintf(stderr, "c-: type error: array index %ld is out of range for '%s' length %d at %s:%d\n",
                node->integer, node->name, node->type.array_len,
                g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
}

struct SafetyArrayValidationContext {
    const char *stmt;
    struct DeclInfo decl;
    int is_array_decl;
    const char *initializer;
};

static void validate_safe_array_ast_node(const struct SafetyExprNode *node,
                                         const struct SafetyExprNode *parent,
                                         void *opaque)
{
    struct SafetyArrayValidationContext *context = opaque;
    const struct SafetyExprNode *receiver;
    struct Type array_type;
    struct SafetyExprNode checked;
    char array_label[NAME_MAX_LEN];
    long index = 0;

    if (node->kind != SAFETY_EXPR_INDEX || node->lhs == NULL || node->rhs == NULL) {
        return;
    }
    receiver = safety_unwrap_group(node->lhs);
    if (context->is_array_decl &&
        (context->initializer == NULL || node->start < context->initializer) &&
        node->lhs->kind == SAFETY_EXPR_IDENTIFIER &&
        strcmp(node->lhs->name, context->decl.name) == 0) {
        return;
    }
    {
        const struct SafetyExprNode *syntactic_receiver = node->lhs;
        const struct SafetyExprNode *comma_value;
        while (syntactic_receiver != NULL && syntactic_receiver->kind == SAFETY_EXPR_GROUP) {
            syntactic_receiver = syntactic_receiver->lhs;
        }
        if (syntactic_receiver != NULL && syntactic_receiver->kind == SAFETY_EXPR_BINARY &&
            strcmp(syntactic_receiver->op, ",") == 0) {
            comma_value = safety_unwrap_group(syntactic_receiver->rhs);
            if (comma_value != NULL && comma_value->type.is_array) {
                size_t label_len = (size_t)(comma_value->end - comma_value->start);
                if (label_len >= sizeof(array_label)) {
                    label_len = sizeof(array_label) - 1;
                }
                memcpy(array_label, comma_value->start, label_len);
                array_label[label_len] = '\0';
                fprintf(stderr, "c-: type error: fixed array '%s' cannot decay to a raw pointer in safe mode at %s:%d; create a Span with Span<T>.from(%s)\n",
                        array_label, g_input_path == NULL ? "<unknown>" : g_input_path,
                        yylineno, array_label);
                exit(1);
            }
        }
    }
    if (receiver == NULL) {
        return;
    }
    array_type = receiver->type;
    if (!array_type.is_array || array_type.array_len <= 0) {
        if (!parse_array_expr_arg(receiver->start, receiver->end,
                                  array_label, &array_type, NULL)) {
            return;
        }
    } else {
        size_t label_len = (size_t)(receiver->end - receiver->start);
        if (label_len >= sizeof(array_label)) {
            label_len = sizeof(array_label) - 1;
        }
        memcpy(array_label, receiver->start, label_len);
        array_label[label_len] = '\0';
    }
    if (parent != NULL && parent->kind == SAFETY_EXPR_UNARY_ADDRESS &&
        parent->lhs == node) {
        fprintf(stderr, "c-: type error: taking the raw address of fixed array '%s' element is only allowed inside unsafe at %s:%d; use Span or Ref on a standalone value\n",
                array_label, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    memset(&checked, 0, sizeof(checked));
    checked.kind = SAFETY_EXPR_FIXED_INDEX;
    checked.type = array_type;
    strncpy(checked.name, array_label, NAME_MAX_LEN - 1);
    checked.name[NAME_MAX_LEN - 1] = '\0';
    checked.has_constant_integer = parse_int_literal_arg(node->rhs->start,
                                                          node->rhs->end,
                                                          &index);
    checked.integer = index;
    validate_fixed_array_index_node(&checked);
}

static void check_safe_array_index_access(const char *stmt)
{
    const char *p = stmt;
    struct DeclInfo decl;
    int is_array_decl;
    struct SafetyExprNode *forest;
    struct SafetyArrayValidationContext context;

    if (g_unsafe_depth > 0) {
        return;
    }
    memset(&decl, 0, sizeof(decl));
    is_array_decl = parse_decl(stmt, &decl) && decl.is_decl && decl.is_array;
    memset(&context, 0, sizeof(context));
    context.stmt = stmt;
    context.decl = decl;
    context.is_array_decl = is_array_decl;
    context.initializer = strchr(stmt, '=');
    forest = safety_parse_forest(stmt);
    safety_expr_walk(forest, NULL, validate_safe_array_ast_node, &context);
    safety_expr_free(forest);
    while (*p != '\0') {
        char name[NAME_MAX_LEN];
        const char *name_end;
        const char *scan;
        const char *array_end;
        const char *open;
        const char *close;
        struct Type array_type;
        char array_label[NAME_MAX_LEN];
        int grouping_parens;

        if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            p++;
            continue;
        }
        name_end = read_name(p, name);
        if (is_array_decl && strcmp(name, decl.name) == 0) {
            p = name_end;
            continue;
        }
        scan = name_end;
        while (1) {
            const char *dot = skip_ws(scan);
            if (*dot == '.' || (dot[0] == '-' && dot[1] == '>')) {
                const char *field_start = skip_ws(*dot == '.' ? dot + 1 : dot + 2);
                const char *field_end;

                if (!is_ident_start((unsigned char)*field_start)) {
                    break;
                }
                field_end = read_name(field_start, name);
                scan = field_end;
                continue;
            }
            break;
        }
        array_end = scan;
        open = skip_safe_deref_trivia(scan);
        grouping_parens = direct_grouping_parens_before(stmt, p);
        while (grouping_parens > 0 && *open == ')') {
            open = skip_safe_deref_trivia(open + 1);
            grouping_parens--;
        }
        if (*open != '[') {
            if (parse_array_expr_arg(p, array_end, array_label, &array_type, NULL) &&
                !fixed_array_use_is_checked_context(stmt, p)) {
                fprintf(stderr, "c-: type error: fixed array '%s' cannot decay to a raw pointer in safe mode at %s:%d; create a Span with Span<T>.from(%s)\n",
                        array_label, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno, array_label);
                exit(1);
            }
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
        }
        if (*close != ']') {
            return;
        }
        p = close + 1;
    }
}

static int is_raw_heap_builtin(const char *name)
{
    return strcmp(name, "malloc") == 0 ||
        strcmp(name, "calloc") == 0 ||
        strcmp(name, "realloc") == 0 ||
        strcmp(name, "free") == 0 ||
        strcmp(name, "strdup") == 0;
}

static void validate_safe_heap_call_node(const struct SafetyExprNode *node,
                                         const struct SafetyExprNode *parent,
                                         void *context)
{
    char name[NAME_MAX_LEN];
    int func_index;
    (void)parent;
    (void)context;

    if (!safety_callee_name(node, name)) {
        return;
    }
    if (is_raw_heap_builtin(name)) {
        fprintf(stderr, "c-: type error: raw heap function '%s' is only allowed inside unsafe; use managed new/clone/s\"\" in safe mode at %s:%d\n",
                name, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    func_index = malloc_func_index(name);
    if (func_index >= 0 && g_malloc_funcs.is_alloc_attr[func_index]) {
        fprintf(stderr, "c-: type error: alloc-attributed function '%s' is only allowed inside unsafe; use managed new/clone/s\"\" in safe mode at %s:%d\n",
                name, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
}

static void check_safe_heap_calls(const char *stmt)
{
    struct SafetyExprNode *forest;

    if (g_unsafe_depth > 0) {
        return;
    }
    forest = safety_parse_forest(stmt);
    safety_expr_walk(forest, NULL, validate_safe_heap_call_node, NULL);
    safety_expr_free(forest);
}

static int interrupt_params_are_void_or_empty(const char *s)
{
    const char *open = strchr(s, '(');
    const char *close;
    const char *p;
    const char *end;

    if (open == NULL) {
        return 0;
    }
    close = matching_paren(open);
    if (close == NULL) {
        return 0;
    }
    p = skip_ws(open + 1);
    end = close;
    while (end > p && isspace((unsigned char)end[-1])) {
        end--;
    }
    return p == end || ((size_t)(end - p) == 4 && strncmp(p, "void", 4) == 0);
}

static int function_decl_has_interrupt(const char *s)
{
    char name[NAME_MAX_LEN];
    struct Type ret;
    const char *name_pos;

    if (!parse_function_signature(s, name, &ret)) {
        return 0;
    }
    name_pos = find_decl_name_pos(s, name);
    return name_pos != NULL && has_decl_word_before(s, name_pos, "interrupt");
}

static int function_decl_has_naked(const char *s)
{
    char name[NAME_MAX_LEN];
    struct Type ret;
    const char *name_pos;

    if (!parse_function_signature(s, name, &ret)) {
        return 0;
    }
    name_pos = find_decl_name_pos(s, name);
    return name_pos != NULL && has_decl_word_before(s, name_pos, "naked");
}

static void validate_interrupt_function_head(const char *s)
{
    char name[NAME_MAX_LEN];
    struct Type ret;

    if (!function_decl_has_interrupt(s)) {
        return;
    }
    if (!parse_function_signature(s, name, &ret) ||
        ret.kind != TY_VOID || ret.ptr != 0 ||
        !interrupt_params_are_void_or_empty(s)) {
        fprintf(stderr, "c-: type error: interrupt functions must be `interrupt void name(void)` at %s:%d\n",
                g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
}

static struct Text *rewrite_interrupt_function_head(struct Text *in)
{
    char name[NAME_MAX_LEN];
    struct Type ret;
    const char *name_pos;
    const char *p;
    struct Text *out;
    int changed = 0;

    if (!parse_function_signature(in->text, name, &ret)) {
        return in;
    }
    name_pos = find_decl_name_pos(in->text, name);
    if (name_pos == NULL || !has_decl_word_before(in->text, name_pos, "interrupt")) {
        return in;
    }
    validate_interrupt_function_head(in->text);
    out = text_new();
    text_add(out, "__attribute__((interrupt)) ");
    p = in->text;
    while (*p != '\0') {
        if (!changed && starts_word(p, "interrupt")) {
            p = skip_ws(p + 9);
            changed = 1;
            continue;
        }
        text_add_ch(out, *p++);
    }
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(in);
    return out;
}

static int name_is_no_heap_collection_constructor(const char *name)
{
    return strncmp(name, "Vec_new_", 8) == 0 ||
        strncmp(name, "List_new_", 9) == 0 ||
        strncmp(name, "Map_new_", 8) == 0 ||
        strncmp(name, "OwnedVec_new_", 13) == 0 ||
        strncmp(name, "OwnedList_new_", 14) == 0 ||
        strncmp(name, "OwnedMap_new_", 13) == 0;
}

static int source_has_collection_new_syntax(const char *stmt)
{
    const char *p = stmt;

    while (*p != '\0') {
        char name[NAME_MAX_LEN];
        const char *name_end;
        const char *q;

        if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            p++;
            continue;
        }
        name_end = read_name(p, name);
        if (strcmp(name, "Vec") != 0 && strcmp(name, "List") != 0 &&
            strcmp(name, "Map") != 0 && strcmp(name, "OwnedVec") != 0 &&
            strcmp(name, "OwnedList") != 0 && strcmp(name, "OwnedMap") != 0) {
            p = name_end;
            continue;
        }
        q = skip_ws(name_end);
        if (*q == '<') {
            int depth = 1;
            q++;
            while (*q != '\0' && depth > 0) {
                if (*q == '<') {
                    depth++;
                } else if (*q == '>') {
                    depth--;
                }
                q++;
            }
        }
        q = skip_ws(q);
        if (*q == '.') {
            char method[NAME_MAX_LEN];
            const char *method_end;

            q = skip_ws(q + 1);
            if (is_ident_start((unsigned char)*q)) {
                method_end = read_name(q, method);
                if (strcmp(method, "new") == 0 && *skip_ws(method_end) == '(') {
                    return 1;
                }
            }
        }
        p = name_end;
    }
    return 0;
}

static int stmt_has_word_call_or_token(const char *stmt, const char *word)
{
    const char *p = stmt;
    size_t n = strlen(word);

    while ((p = strstr(p, word)) != NULL) {
        if ((p == stmt || !is_ident((unsigned char)p[-1])) &&
            !is_ident((unsigned char)p[n])) {
            return 1;
        }
        p += n;
    }
    return 0;
}

static int source_has_heap_new_token(const char *stmt)
{
    const char *p = stmt;

    while (*p != '\0') {
        if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (!starts_word(p, "new")) {
            p++;
            continue;
        }
        {
            const char *q = skip_ws(p + 3);
            const char *name_end;
            const char *after;
            char name[NAME_MAX_LEN];

            if (!is_ident_start((unsigned char)*q)) {
                return 1;
            }
            name_end = read_name(q, name);
            if (strcmp(name, "Optional") == 0 &&
                parse_generic_angle_arg(name_end, name, &after)) {
                const char *member = skip_ws(after);
                if (*member == '.') {
                    const char *variant_start = skip_ws(member + 1);
                    const char *variant_end;

                    if (is_ident_start((unsigned char)*variant_start)) {
                        variant_end = read_name(variant_start, name);
                        if (*skip_ws(variant_end) == '(') {
                            p = variant_end;
                            continue;
                        }
                    }
                }
            }
            return 1;
        }
    }
    return 0;
}

static void check_no_heap_safe_expr(const char *stmt)
{
    const char *p = stmt;
    const char *mode = g_current_function_interrupt ? "interrupt" :
        (g_current_function_naked ? "naked" : "no-heap");

    if (!g_no_heap && !g_current_function_interrupt && !g_current_function_naked) {
        return;
    }
    if (g_unsafe_depth > 0 && !g_current_function_interrupt && !g_current_function_naked) {
        return;
    }
    if (text_has_s_string(stmt)) {
        fprintf(stderr, "c-: type error: s strings allocate managed heap and are not allowed in %s functions at %s:%d\n",
                mode, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    if (source_has_heap_new_token(stmt) || stmt_has_word_call_or_token(stmt, "clone") ||
        source_has_collection_new_syntax(stmt)) {
        fprintf(stderr, "c-: type error: managed heap allocation is not allowed in %s functions at %s:%d; use value structs, fixed arrays, Span, FixedVec, RingBuffer, or Register\n",
                mode, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    while (*p != '\0') {
        char name[NAME_MAX_LEN];
        const char *name_end;
        const char *open;

        if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            p++;
            continue;
        }
        name_end = read_name(p, name);
        open = skip_ws(name_end);
        if (*open == '(' &&
            (name_is_no_heap_collection_constructor(name) ||
             strcmp(name, "cminus_gc_malloc") == 0 ||
             strcmp(name, "cminus_gc_calloc") == 0 ||
             strcmp(name, "cminus_gc_realloc") == 0 ||
             strcmp(name, "cminus_string_format") == 0)) {
            fprintf(stderr, "c-: type error: managed heap allocation is not allowed in %s functions at %s:%d; use value structs, fixed arrays, Span, FixedVec, RingBuffer, or Register\n",
                    mode, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
        p = name_end;
    }
}

static int is_safe_banned_c_function(const char *name)
{
    static const char *funcs[] = {
        "strlen", "strcmp", "strncmp", "strcpy", "strncpy", "strcat", "strncat",
        "strdup", "strstr", "strchr", "strrchr",
        "memcpy", "memmove", "memset", "memcmp",
        "fopen", "freopen", "fclose", "fread", "fwrite", "fflush",
        NULL
    };
    int i;

    for (i = 0; funcs[i] != NULL; i++) {
        if (strcmp(name, funcs[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

static int is_safe_banned_register_function(const char *name)
{
    return strncmp(name, "Register_from_addr_", 19) == 0 ||
           strncmp(name, "Volatile_from_addr_", 19) == 0;
}

static void validate_safe_c_call_node(const struct SafetyExprNode *node,
                                      const struct SafetyExprNode *parent,
                                      void *context)
{
    char name[NAME_MAX_LEN];
    (void)parent;
    (void)context;

    if (node->kind == SAFETY_EXPR_IDENTIFIER &&
        (strcmp(node->name, "__asm__") == 0 || strcmp(node->name, "asm") == 0)) {
        fprintf(stderr, "c-: type error: inline assembly can only be used inside unsafe at %s:%d\n",
                g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    if (!safety_callee_name(node, name)) {
        return;
    }
    if (is_safe_banned_c_function(name)) {
        fprintf(stderr, "c-: type error: C function '%s' can only be called inside unsafe; use a C- safe wrapper such as string methods or xfopen at %s:%d\n",
                name, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    if (is_safe_banned_register_function(name)) {
        fprintf(stderr, "c-: type error: from_addr can only be called inside unsafe at %s:%d; wrap raw address creation in unsafe and expose a safe Register or Volatile value\n",
                g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
}

static void check_safe_c_function_calls(const char *stmt)
{
    struct SafetyExprNode *forest;

    if (g_unsafe_depth > 0) {
        return;
    }
    forest = safety_parse_forest(stmt);
    safety_expr_walk(forest, NULL, validate_safe_c_call_node, NULL);
    safety_expr_free(forest);
}

static int expr_starts_with_address_of(const char *expr)
{
    const char *p = skip_ws(expr);

    return *p == '&';
}

static int expr_is_managed_constructor(const char *expr)
{
    struct Type unused;
    const char *p = skip_ws(expr);

    return rhs_has_new_expr(p, &unused) ||
        rhs_has_clone_expr(p, &unused) ||
        text_has_s_string(p);
}

struct SafetyRawPointerContext {
    int found;
};

static void find_raw_pointer_symbol_node(const struct SafetyExprNode *node,
                                         const struct SafetyExprNode *parent,
                                         void *opaque)
{
    struct SafetyRawPointerContext *context = opaque;
    struct Symbol *sym;
    (void)parent;

    if (context->found || node->kind != SAFETY_EXPR_IDENTIFIER) {
        return;
    }
    sym = symbol_find_or_current_param(node->name);
    if (sym != NULL && sym->type.raw_ptr) {
        context->found = 1;
    }
}

static int expr_is_raw_pointer_input(const char *start, const char *end)
{
    struct SafetyExprNode *tree;
    const struct SafetyExprNode *root;
    struct SafetyRawPointerContext context;
    int raw;

    while (start < end && isspace((unsigned char)*start)) {
        start++;
    }
    while (end > start && isspace((unsigned char)end[-1])) {
        end--;
    }
    if (start >= end || expr_starts_with_address_of(start) || expr_is_managed_constructor(start)) {
        return 0;
    }
    tree = safety_parse_range(start, end);
    if (tree == NULL) {
        return 0;
    }
    root = safety_strip_groups(tree);
    if (root != NULL && root->kind == SAFETY_EXPR_UNARY_ADDRESS) {
        safety_expr_free(tree);
        return 0;
    }
    memset(&context, 0, sizeof(context));
    safety_expr_walk(tree, NULL, find_raw_pointer_symbol_node, &context);
    raw = (root != NULL && root->type.raw_ptr) || context.found;
    if (root != NULL && root->type.is_array) {
        raw = 0;
    }
    safety_expr_free(tree);
    return raw;
}

static void check_raw_pointer_arg_error(const char *kind)
{
    fprintf(stderr, "c-: type error: raw pointer cannot be stored in %s in safe mode; use managed new/clone/s\"\" or unsafe\n",
            kind);
    exit(1);
}

static void check_safe_reference_raw_inputs(const char *stmt)
{
    const char *p = stmt;

    if (g_unsafe_depth > 0) {
        return;
    }
    while (*p != '\0') {
        char name[NAME_MAX_LEN];
        const char *name_end;
        const char *open;
        const char *close;
        const char *arg_end;

        if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            p++;
            continue;
        }
        name_end = read_name(p, name);
        open = skip_ws(name_end);
        if (*open != '(') {
            p = name_end;
            continue;
        }
        close = matching_paren(open);
        if (close == NULL) {
            return;
        }
        arg_end = find_top_level_char(open + 1, close, ',');
        if (arg_end == NULL) {
            arg_end = close;
        }
        if (strncmp(name, "Ref_from_", 9) == 0) {
            if (expr_is_raw_pointer_input(open + 1, arg_end)) {
                check_raw_pointer_arg_error("Ref");
            }
        } else if (strncmp(name, "Span_from_", 10) == 0 ||
                   strncmp(name, "Span_from_bytes_", 16) == 0 ||
                   strncmp(name, "RingBuffer_from_", 16) == 0 ||
                   strncmp(name, "RingBuffer_from_bytes_", 22) == 0 ||
                   strcmp(name, "Bitmap_from") == 0 ||
                   strcmp(name, "Bitmap_from_words") == 0 ||
                   strcmp(name, "Bitmap_from_bytes") == 0) {
            if (expr_is_raw_pointer_input(open + 1, arg_end)) {
                check_raw_pointer_arg_error(strncmp(name, "RingBuffer_", 11) == 0 ? "RingBuffer" :
                                            (strncmp(name, "Bitmap_", 7) == 0 ? "Bitmap" : "Span"));
            }
        } else if (strncmp(name, "Optional_", 9) == 0 && strstr(name, "_ptr_") != NULL &&
                   strstr(name, "_Some") != NULL) {
            if (expr_is_raw_pointer_input(open + 1, arg_end)) {
                check_raw_pointer_arg_error("Optional");
            }
        }
        p = close + 1;
    }
}

static void check_safe_raw_field_access(const char *stmt)
{
    const char *p = stmt;

    if (g_unsafe_depth > 0) {
        return;
    }
    while (*p != '\0') {
        char name[NAME_MAX_LEN];
        const char *name_end;
        const char *scan;
        const char *dot;
        struct Symbol *sym;
        struct Type current;

        if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            p++;
            continue;
        }
        name_end = read_name(p, name);
        sym = symbol_find(name);
        if (sym == NULL || sym->type.kind != TY_STRUCT) {
            p = name_end;
            continue;
        }
        current = sym->type;
        scan = name_end;
        dot = skip_ws(scan);
        while (*dot == '.' || (dot[0] == '-' && dot[1] == '>')) {
            const char *field_start = skip_ws(*dot == '.' ? dot + 1 : dot + 2);
            const char *field_end;
            const char *after_field;
            char field[NAME_MAX_LEN];
            struct Type field_type;

            if (!is_ident_start((unsigned char)*field_start)) {
                break;
            }
            field_end = read_name(field_start, field);
            after_field = skip_ws(field_end);
            if (*after_field == '(' || *after_field == '<') {
                break;
            }
            if (current.kind != TY_STRUCT ||
                !struct_field_type(current.tag, field, &field_type)) {
                break;
            }
            if (field_type.raw_ptr) {
                fprintf(stderr, "c-: type error: raw pointer field '%s.%s' cannot be accessed in safe mode at %s:%d; use unsafe or expose a managed safe API\n",
                        current.tag, field, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
                exit(1);
            }
            current = field_type;
            scan = field_end;
            dot = skip_ws(scan);
        }
        p = scan;
    }
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

static void owned_func_add_type_ex(const char *name, struct Type ret, int is_alloc_attr)
{
    int index = malloc_func_index(name);
    if (name[0] == '\0') {
        return;
    }
    if (index >= 0) {
        g_malloc_funcs.ret[index] = ret;
        if (is_alloc_attr) {
            g_malloc_funcs.is_alloc_attr[index] = 1;
        }
        return;
    }
    if (g_malloc_funcs.count >= MAX_FUNCS) {
        die("too many malloc attributed functions");
    }
    strncpy(g_malloc_funcs.name[g_malloc_funcs.count], name, NAME_MAX_LEN - 1);
    g_malloc_funcs.name[g_malloc_funcs.count][NAME_MAX_LEN - 1] = '\0';
    g_malloc_funcs.ret[g_malloc_funcs.count] = ret;
    g_malloc_funcs.is_alloc_attr[g_malloc_funcs.count] = is_alloc_attr;
    g_malloc_funcs.count++;
}

static void owned_func_add_type(const char *name, struct Type ret)
{
    owned_func_add_type_ex(name, ret, 0);
}

static void register_builtin_owned_functions(void)
{
    return;
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

static int text_has_malloc_attribute(const char *s)
{
    const char *p = s;

    while ((p = strstr(p, "__attribute__")) != NULL) {
        const char *open = skip_ws(p + 13);
        const char *close;

        if (*open != '(') {
            p += 13;
            continue;
        }
        close = matching_paren(open);
        if (close == NULL) {
            return 0;
        }
        if (range_contains_text(open, close, "malloc")) {
            return 1;
        }
        p = close + 1;
    }
    return 0;
}

static void register_malloc_attribute_function(const char *s)
{
    char name[NAME_MAX_LEN];
    struct Type ret;

    if (!text_has_malloc_attribute(s)) {
        return;
    }
    if (!parse_function_signature(s, name, &ret)) {
        return;
    }
    if (ret.ptr <= 0) {
        ret = type_make(TY_VOID, 1, NULL);
    }
    ret.owned = 1;
    owned_func_add_type_ex(name, ret, 1);
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

static void pending_semantics_clear(void)
{
    memset(&g_pending_semantics, 0, sizeof(g_pending_semantics));
}

static void pending_semantics_capture_statement(const char *statement)
{
    struct DeclInfo decl;
    int eq;
    char owner[NAME_MAX_LEN];
    char move_source[NAME_MAX_LEN];

    pending_semantics_clear();
    owner[0] = '\0';
    move_source[0] = '\0';
    eq = find_assignment(statement);
    if (parse_decl(statement, &decl) && decl.is_decl &&
        decl.name[0] != '\0' && !decl.is_function) {
        g_pending_semantics.active = 1;
        g_pending_semantics.owned = decl.type.owned;
        g_pending_semantics.borrowed = decl_has_borrow(statement);
        strcpy(g_pending_semantics.target, decl.name);
        if (decl.has_init && decl.init != NULL) {
            if (extract_direct_move_name(decl.init, move_source)) {
                strcpy(g_pending_semantics.move_source, move_source);
                g_pending_semantics.owned = 1;
            }
            if ((g_pending_semantics.borrowed &&
                 extract_direct_borrow_owner(decl.init, owner)) ||
                extract_safe_reference_borrow_owner(decl.init, owner)) {
                strcpy(g_pending_semantics.owner, owner);
                g_pending_semantics.borrowed = 1;
                g_pending_semantics.stack_owner = owner_is_local_stack(owner);
            }
        }
        return;
    }
    if (eq >= 0 && extract_direct_move_name(statement + eq + 1, move_source)) {
        char target[NAME_MAX_LEN];

        target[0] = '\0';
        if (extract_lhs_name(statement, eq, target)) {
            g_pending_semantics.active = 1;
            g_pending_semantics.is_assignment = 1;
            g_pending_semantics.owned = 1;
            strcpy(g_pending_semantics.target, target);
            strcpy(g_pending_semantics.move_source, move_source);
        }
    }
}

static void pending_semantics_capture_return(const char *statement)
{
    char move_source[NAME_MAX_LEN];

    pending_semantics_clear();
    if (extract_move_name(statement, move_source)) {
        g_pending_semantics.active = 1;
        g_pending_semantics.is_return = 1;
        g_pending_semantics.owned = 1;
        strcpy(g_pending_semantics.move_source, move_source);
    }
}

static int extract_move_name(const char *s, char *name)
{
    return safety_ast_move_identifier(s, s + strlen(s), name);
}

static int extract_direct_move_name(const char *s, char *name)
{
    struct SafetyExprNode *tree = safety_parse_range(s, s + strlen(s));
    const struct SafetyExprNode *node = safety_strip_groups(tree);
    const struct SafetyExprNode *value = NULL;
    int result = 0;

    name[0] = '\0';
    if (node != NULL && node->kind == SAFETY_EXPR_MOVE && node->next == NULL) {
        value = safety_strip_groups(node->lhs);
        if (value != NULL && value->kind == SAFETY_EXPR_IDENTIFIER) {
            strncpy(name, value->name, NAME_MAX_LEN - 1);
            name[NAME_MAX_LEN - 1] = '\0';
            result = 1;
        }
    }
    safety_expr_free(tree);
    return result;
}

static int extract_plain_name_expr(const char *s, char *name)
{
    return safety_ast_plain_identifier(s, s + strlen(s), name);
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
                    borrow_links_invalidate_owner(name);
                    owned_remove(name);
                    owned_remove_from(&g_finalized_locals, name);
                    moved_local_add(name);
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
        if (p + 1 < end && p[0] == '/' && p[1] == '*') {
            p += 2;
            while (p + 1 < end && !(p[0] == '*' && p[1] == '/')) p++;
            if (p + 1 < end) p++;
        } else if (p + 1 < end && p[0] == '/' && p[1] == '/') {
            p += 2;
            while (p < end && *p != '\n') p++;
            continue;
        } else if (*p == '"') {
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

static const char *find_parameter_comma(const char *start, const char *end)
{
    const char *p = start;
    int paren = 0;
    int bracket = 0;
    int brace = 0;
    int angle = 0;
    int in_default = 0;

    while (p < end) {
        if (p + 1 < end && p[0] == '/' && p[1] == '*') {
            p += 2;
            while (p + 1 < end && !(p[0] == '*' && p[1] == '/')) p++;
            if (p + 1 < end) p++;
        } else if (p + 1 < end && p[0] == '/' && p[1] == '/') {
            p += 2;
            while (p < end && *p != '\n') p++;
            continue;
        } else if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (p < end) {
                if (*p == '\\' && p + 1 < end) {
                    p += 2;
                    continue;
                }
                if (*p == quote) break;
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
        } else if (!in_default && *p == '<' && paren == 0 &&
                   bracket == 0 && brace == 0) {
            angle++;
        } else if (!in_default && *p == '>' && angle > 0 && paren == 0 &&
                   bracket == 0 && brace == 0) {
            angle--;
        } else if (*p == '=' && paren == 0 && bracket == 0 && brace == 0 &&
                   angle == 0) {
            in_default = 1;
        } else if (*p == ',' && paren == 0 && bracket == 0 && brace == 0 &&
                   angle == 0) {
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

static void register_generated_function_return(const char *name,
                                               struct Type ret)
{
    struct FunctionParams *fn = function_params_get(name);

    fn->ret = ret;
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
    fn = function_params_get(name);
    fn->count = 0;
    fn->has_defaults = 0;
    fn->is_unsafe = g_unsafe_depth > 0;
    fn->ret = ret;
    p = open + 1;
    while (p < close) {
        const char *arg_end = find_parameter_comma(p, close);
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
                struct DeclInfo decl;
                char *param_decl = xstrndup(p, (size_t)(eq - p));

                if (eq < param_end) {
                    fn->has_defaults = 1;
                }
                strncpy(fn->param[fn->count].name, param_name, NAME_MAX_LEN - 1);
                fn->param[fn->count].name[NAME_MAX_LEN - 1] = '\0';
                fn->param[fn->count].type = type_unknown();
                fn->param[fn->count].borrowed = 0;
                fn->param[fn->count].owned = 0;
                if (parse_decl(param_decl, &decl) && decl.name[0] != '\0') {
                    if (decl_has_borrow(param_decl)) {
                        decl.type.owned = 0;
                    }
                    fn->param[fn->count].borrowed =
                        decl_has_borrow(param_decl) || text_has_word(param_decl, "ref");
                    fn->param[fn->count].owned =
                        !fn->param[fn->count].borrowed &&
                        (decl.type.owned || text_has_word(param_decl, "owned"));
                    if (fn->param[fn->count].owned) {
                        decl.type.owned = 1;
                    }
                    fn->param[fn->count].type = decl.type;
                    if (g_unsafe_depth == 0 &&
                        type_is_runtime_resource_value(decl.type)) {
                        fprintf(stderr,
                                "c-: type error: runtime resource parameter '%s' must use ref or mut ref in safe mode\n",
                                param_name);
                        free(param_decl);
                        exit(1);
                    }
                    if (g_unsafe_depth == 0 && decl.type.ptr == 0 &&
                        type_has_finalizer(decl.type) &&
                        !fn->param[fn->count].owned) {
                        fprintf(stderr,
                                "c-: type error: owning struct parameter '%s' must use ref or mut ref in safe mode; clone explicitly when an independent value is required\n",
                                param_name);
                        free(param_decl);
                        exit(1);
                    }
                }
                if (def_len >= DEFAULT_EXPR_MAX) {
                    def_len = DEFAULT_EXPR_MAX - 1;
                }
                memcpy(fn->param[fn->count].def, def_start, def_len);
                fn->param[fn->count].def[def_len] = '\0';
                free(param_decl);
                fn->count++;
            }
        }
        p = arg_end;
        if (p < close && *p == ',') {
            p++;
        }
    }
}

static void register_function_param_symbols(const char *s)
{
    char name[NAME_MAX_LEN];
    struct Type ret;
    const char *open;
    const char *close;
    const char *p;

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
    p = open + 1;
    while (p < close) {
        const char *arg_end = find_parameter_comma(p, close);
        const char *param_end;
        const char *eq;
        struct DeclInfo decl;
        char *tmp;

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
            tmp = xstrndup(p, (size_t)(eq - p));
            if (parse_decl(tmp, &decl) && decl.name[0] != '\0') {
                if (decl_has_borrow(tmp)) {
                    decl.type.owned = 0;
                }
                symbol_add_param_to(&g_locals, decl.name, decl.type);
            }
            free(tmp);
        }
        p = arg_end;
        if (p < close && *p == ',') {
            p++;
        }
    }
}

static void register_owned_parameter_cleanup(const char *function_name)
{
    struct FunctionParams *fn = function_params_find(function_name);
    int i;

    if (fn == NULL) {
        return;
    }
    for (i = 0; i < fn->count; i++) {
        if (!fn->param[i].owned) {
            continue;
        }
        if (fn->param[i].type.ptr > 0) {
            owned_add(fn->param[i].name, fn->param[i].type);
        } else if (type_has_finalizer(fn->param[i].type)) {
            finalized_local_add(fn->param[i].name, fn->param[i].type);
        }
    }
}

static const char *unsafe_matching_brace(const char *open)
{
    const char *p = open;
    int depth = 0;

    while (*p != '\0') {
        if (*p == '"' || *p == '\'') {
            char quote = *p++;
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    p += 2;
                    continue;
                }
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (*p == '{') {
            depth++;
        } else if (*p == '}') {
            depth--;
            if (depth == 0) {
                return p;
            }
        }
        p++;
    }
    return NULL;
}

static void register_unsafe_struct_fields(const char *body)
{
    const char *p = body;

    while ((p = strstr(p, "struct")) != NULL) {
        char tag[NAME_MAX_LEN];
        const char *name_start;
        const char *name_end;
        const char *open;
        const char *close;
        const char *field_start;

        if ((p > body && is_ident((unsigned char)p[-1])) || is_ident((unsigned char)p[6])) {
            p += 6;
            continue;
        }
        name_start = skip_ws(p + 6);
        if (!is_ident_start((unsigned char)*name_start)) {
            p += 6;
            continue;
        }
        name_end = read_name(name_start, tag);
        open = skip_ws(name_end);
        if (*open != '{') {
            p = name_end;
            continue;
        }
        close = unsafe_matching_brace(open);
        if (close == NULL) {
            return;
        }
        tag_add(TY_STRUCT, tag);
        field_start = open + 1;
        while (field_start < close) {
            const char *semi = find_top_level_char(field_start, close, ';');
            char *field_text;
            struct DeclInfo decl;

            if (semi == NULL) {
                break;
            }
            field_text = xstrndup(field_start, (size_t)(semi - field_start + 1));
            if (parse_decl(field_text, &decl) && decl.is_decl && decl.name[0] != '\0' && !decl.is_function) {
                struct_clone_add_field(tag, decl.name, decl.type, decl.is_array);
                if (decl.type.owned || type_has_finalizer(decl.type)) {
                    struct_finalizer_add_field(tag, decl.name, decl.type);
                }
            }
            free(field_text);
            field_start = semi + 1;
        }
        p = close + 1;
    }
}

static void register_unsafe_function_heads(const char *body)
{
    const char *p = body;

    while ((p = strchr(p, '{')) != NULL) {
        const char *line_start = p;
        const char *line_end = p;
        char *head;
        char name[NAME_MAX_LEN];
        struct Type ret;

        while (line_start > body && line_start[-1] != '\n' && line_start[-1] != '}' && line_start[-1] != ';') {
            line_start--;
        }
        while (line_start < line_end && isspace((unsigned char)*line_start)) {
            line_start++;
        }
        if (line_start == line_end && line_start > body) {
            line_end = line_start - 1;
            while (line_end > body && isspace((unsigned char)line_end[-1])) {
                line_end--;
            }
            line_start = line_end;
            while (line_start > body && line_start[-1] != '\n' && line_start[-1] != '}' && line_start[-1] != ';') {
                line_start--;
            }
        }
        head = xstrndup(line_start, (size_t)(line_end - line_start));
        if (parse_function_signature(head, name, &ret)) {
            register_function_params(head);
            register_owned_function_signature(head);
            register_malloc_attribute_function(head);
        }
        free(head);
        p++;
    }
}

static void register_unsafe_function_decls(const char *body)
{
    const char *segment = body;
    const char *p = body;
    int brace_depth = 0;

    while (*p != '\0') {
        if (*p == '{') {
            brace_depth++;
        } else if (*p == '}' && brace_depth > 0) {
            brace_depth--;
            if (brace_depth == 0) {
                segment = p + 1;
            }
        } else if (*p == ';' && brace_depth == 0) {
            char *decl = xstrndup(segment, (size_t)(p + 1 - segment));
            char name[NAME_MAX_LEN];
            struct Type ret;

            if (parse_function_signature(decl, name, &ret)) {
                register_function_params(decl);
                register_owned_function_signature(decl);
                register_malloc_attribute_function(decl);
            }
            free(decl);
            segment = p + 1;
        }
        p++;
    }
}

static void register_unsafe_metadata(const char *body)
{
    register_unsafe_struct_fields(body);
    register_unsafe_function_heads(body);
    register_unsafe_function_decls(body);
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
        const char *param_end = find_parameter_comma(p, close);
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

static int function_params_trailing_default_start(struct FunctionParams *fn)
{
    int i;

    if (fn == NULL || fn->count < 1 || fn->param[fn->count - 1].def[0] == '\0') {
        return -1;
    }
    i = fn->count - 1;
    while (i > 0 && fn->param[i - 1].def[0] != '\0') {
        i--;
    }
    return i;
}

static void emit_macro_param_list(FILE *out, struct FunctionParams *fn, int count)
{
    int i;

    for (i = 0; i < count; i++) {
        if (i != 0) {
            fputs(", ", out);
        }
        fputs(fn->param[i].name[0] != '\0' ? fn->param[i].name : "arg", out);
    }
}

static void emit_generic_default_macro_direct(FILE *out, const char *func_name, struct FunctionParams *fn)
{
    int i;
    int n;
    int start;
    int argc;

    start = function_params_trailing_default_start(fn);
    if (start < 0) {
        return;
    }
    n = fn->count;
    fprintf(out, "#define __CMINUS_DEFAULT_SELECT_%s(", func_name);
    for (i = 0; i < n; i++) {
        fprintf(out, "_%d, ", i + 1);
    }
    fprintf(out, "NAME, ...) NAME\n");
    for (argc = start; argc <= n; argc++) {
        fprintf(out, "#define __CMINUS_DEFAULT_%s_%d(", func_name, argc);
        emit_macro_param_list(out, fn, argc);
        fprintf(out, ") %s(", func_name);
        for (i = 0; i < n; i++) {
            if (i != 0) {
                fputs(", ", out);
            }
            if (i < argc) {
                fputs(fn->param[i].name[0] != '\0' ? fn->param[i].name : "arg", out);
            } else {
                fputs(fn->param[i].def, out);
            }
        }
        fputs(")\n", out);
    }
    fprintf(out, "#define %s(...) __CMINUS_DEFAULT_SELECT_%s(__VA_ARGS__", func_name, func_name);
    for (argc = n; argc >= start; argc--) {
        fprintf(out, ", __CMINUS_DEFAULT_%s_%d", func_name, argc);
    }
    fputs(")(__VA_ARGS__)\n", out);
}

static void emit_generic_default_undef_direct(FILE *out, const char *func_name, struct FunctionParams *fn)
{
    if (function_params_trailing_default_start(fn) >= 0) {
        fprintf(out, "#undef %s\n", func_name);
    }
}

static void emit_generic_default_macro(FILE *out, const char *func_name,
                                       struct FunctionParams *fn)
{
    FILE *stream;
    struct Text *generated;

    if (function_params_trailing_default_start(fn) < 0) {
        return;
    }
    stream = tmpfile();
    if (stream == NULL) {
        die("cannot create default macro output stream");
    }
    emit_generic_default_macro_direct(stream, func_name, fn);
    generated = read_generated_stream(stream);
    fclose(stream);
    emit_generated_text(out, ND_DEFAULT_MACRO, func_name, generated);
}

static void emit_generic_default_undef(FILE *out, const char *func_name,
                                       struct FunctionParams *fn)
{
    FILE *stream;
    struct Text *generated;

    if (function_params_trailing_default_start(fn) < 0) {
        return;
    }
    stream = tmpfile();
    if (stream == NULL) {
        die("cannot create default undef output stream");
    }
    emit_generic_default_undef_direct(stream, func_name, fn);
    generated = read_generated_stream(stream);
    fclose(stream);
    emit_generated_text(out, ND_DEFAULT_MACRO, func_name, generated);
}

static int range_contains_text(const char *start, const char *end, const char *needle)
{
    size_t needle_len = strlen(needle);
    const char *p;

    if (needle_len == 0) {
        return 1;
    }
    for (p = start; p + needle_len <= end; p++) {
        if (strncmp(p, needle, needle_len) == 0) {
            return 1;
        }
    }
    return 0;
}

static struct Text *rewrite_os_attributes(struct Text *in)
{
    const char *p = in->text;
    const char *body_start;
    struct Text *attrs;
    struct Text *out;
    int count = 0;

    while (isspace((unsigned char)*p)) {
        p++;
    }
    body_start = p;
    attrs = text_new();
    while (is_ident_start((unsigned char)*p)) {
        char word[NAME_MAX_LEN];
        const char *name_end = read_name(p, word);
        const char *next = skip_ws(name_end);

        if (!os_attribute_name(word) || !os_attribute_can_start_decl(word, name_end)) {
            break;
        }
        if (count > 0) {
            text_add(attrs, ", ");
        }
        if (strcmp(word, "section") == 0 || strcmp(word, "aligned") == 0) {
            const char *close;
            if (*next != '(') {
                fprintf(stderr, "c-: type error: %s requires an argument at %s:%d\n",
                        word, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
                exit(1);
            }
            close = matching_paren(next);
            if (close == NULL) {
                fprintf(stderr, "c-: type error: unterminated %s attribute at %s:%d\n",
                        word, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
                exit(1);
            }
            text_add(attrs, word);
            text_add_n(attrs, next, (size_t)(close + 1 - next));
            p = skip_ws(close + 1);
        } else {
            if (strcmp(word, "no_return") == 0) {
                text_add(attrs, "noreturn");
            } else if (strcmp(word, "export") == 0) {
                text_add(attrs, "used, externally_visible");
            } else {
                text_add(attrs, word);
            }
            p = next;
        }
        count++;
    }
    if (count == 0) {
        text_free(attrs);
        return in;
    }
    out = text_new();
    text_add_n(out, in->text, (size_t)(body_start - in->text));
    text_add(out, "__attribute__((");
    text_add(out, attrs->text);
    text_add(out, ")) ");
    text_add(out, p);
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(attrs);
    text_free(in);
    return out;
}

static struct Text *rewrite_compile_time_os_ops(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    out->tail_return = in->tail_return;
    out->ast = in->ast;
    while (*p != '\0') {
        if (*p == '"' || *p == '\'') {
            char quote = *p;
            text_add_ch(out, *p++);
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    text_add_ch(out, *p++);
                    text_add_ch(out, *p++);
                    continue;
                }
                text_add_ch(out, *p);
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (starts_word(p, "static_assert")) {
            const char *next = skip_ws(p + 13);
            if (*next == '(') {
                text_add(out, "_Static_assert");
                p += 13;
                changed = 1;
                continue;
            }
        }
        if (starts_word(p, "offset_of")) {
            const char *next = skip_ws(p + 9);
            if (*next == '(') {
                const char *close = matching_paren(next);
                const char *comma;

                if (close == NULL) {
                    fprintf(stderr, "c-: type error: unterminated offset_of at %s:%d\n",
                            g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
                    exit(1);
                }
                comma = find_top_level_char(next + 1, close, ',');
                if (comma != NULL) {
                    char type_name[NAME_MAX_LEN];
                    const char *type_start = skip_ws(next + 1);
                    const char *type_end = comma;
                    int i;
                    int known_struct = 0;

                    while (type_end > type_start && isspace((unsigned char)type_end[-1])) {
                        type_end--;
                    }
                    if (type_end > type_start &&
                        (size_t)(type_end - type_start) < sizeof(type_name) &&
                        is_ident_start((unsigned char)*type_start)) {
                        const char *read_end = read_name(type_start, type_name);
                        if (read_end == type_end) {
                            for (i = 0; i < g_tags.count; i++) {
                                if (g_tags.tag[i].kind == TY_STRUCT &&
                                    strcmp(g_tags.tag[i].name, type_name) == 0) {
                                    known_struct = 1;
                                    break;
                                }
                            }
                        }
                    }
                    text_add(out, "__builtin_offsetof(");
                    if (known_struct) {
                        text_add(out, "struct ");
                    }
                    text_add_n(out, type_start, (size_t)(type_end - type_start));
                    text_add(out, ",");
                    text_add_n(out, comma + 1, (size_t)(close - comma - 1));
                    text_add_ch(out, ')');
                    p = close + 1;
                } else {
                    text_add(out, "__builtin_offsetof");
                    p += 9;
                }
                changed = 1;
                continue;
            }
        }
        text_add_ch(out, *p++);
    }
    if (!changed) {
        out->ast = NULL;
        text_free(out);
        return in;
    }
    in->ast = NULL;
    text_free(in);
    return out;
}

static int linker_symbol_index(const char *name)
{
    int i;

    for (i = 0; i < g_linker_symbols.count; i++) {
        if (strcmp(g_linker_symbols.name[i], name) == 0) {
            return i;
        }
    }
    return -1;
}

static void linker_symbol_add(const char *name)
{
    if (name[0] == '\0' || linker_symbol_index(name) >= 0) {
        return;
    }
    if (g_linker_symbols.count >= MAX_TAGS) {
        die("too many linker symbols");
    }
    strncpy(g_linker_symbols.name[g_linker_symbols.count], name, NAME_MAX_LEN - 1);
    g_linker_symbols.name[g_linker_symbols.count][NAME_MAX_LEN - 1] = '\0';
    g_linker_symbols.count++;
}

static int parse_linker_symbol_decl(const char *s, char *name)
{
    const char *p = skip_ws(s);
    const char *end;

    name[0] = '\0';
    if (!starts_word(p, "linker_symbol")) {
        return 0;
    }
    p = skip_ws(p + 13);
    if (!is_ident_start((unsigned char)*p)) {
        fprintf(stderr, "c-: type error: linker_symbol requires a symbol name at %s:%d\n",
                g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    end = read_name(p, name);
    if (*skip_ws(end) != ';') {
        fprintf(stderr, "c-: type error: linker_symbol syntax is `linker_symbol name;` at %s:%d\n",
                g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    return 1;
}

static struct Text *rewrite_linker_symbol_decl(struct Text *in)
{
    char name[NAME_MAX_LEN];
    struct Text *out;

    if (!parse_linker_symbol_decl(in->text, name)) {
        return in;
    }
    linker_symbol_add(name);
    out = text_new();
    text_add(out, "\nextern char ");
    text_add(out, name);
    text_add(out, "[];\n");
    out->tail_return = in->tail_return;
    out->ast = ast_raw(ND_DECL, out->text);
    text_free(in);
    return out;
}

static struct Text *rewrite_linker_address_ops(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    out->tail_return = in->tail_return;
    out->ast = in->ast;
    while (*p != '\0') {
        if (*p == '"' || *p == '\'') {
            char quote = *p;
            text_add_ch(out, *p++);
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    text_add_ch(out, *p++);
                    text_add_ch(out, *p++);
                    continue;
                }
                text_add_ch(out, *p);
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (starts_word(p, "addr_of")) {
            const char *open = skip_ws(p + 7);
            const char *close;
            const char *name_start;
            const char *name_end;
            char name[NAME_MAX_LEN];

            if (*open != '(') {
                text_add_ch(out, *p++);
                continue;
            }
            close = matching_paren(open);
            if (close == NULL) {
                fprintf(stderr, "c-: type error: unterminated addr_of at %s:%d\n",
                        g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
                exit(1);
            }
            name_start = skip_ws(open + 1);
            name_end = close;
            while (name_end > name_start && isspace((unsigned char)name_end[-1])) {
                name_end--;
            }
            if (name_end <= name_start ||
                (size_t)(name_end - name_start) >= NAME_MAX_LEN ||
                !is_ident_start((unsigned char)*name_start) ||
                read_name(name_start, name) != name_end) {
                fprintf(stderr, "c-: type error: addr_of expects one linker symbol name at %s:%d\n",
                        g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
                exit(1);
            }
            if (linker_symbol_index(name) < 0) {
                fprintf(stderr, "c-: type error: addr_of(%s) requires `linker_symbol %s;` first at %s:%d\n",
                        name, name, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
                exit(1);
            }
            text_add(out, "((unsigned long)(");
            text_add(out, name);
            text_add(out, "))");
            p = close + 1;
            changed = 1;
            continue;
        }
        text_add_ch(out, *p++);
    }
    if (!changed) {
        out->ast = NULL;
        text_free(out);
        return in;
    }
    in->ast = NULL;
    text_free(in);
    return out;
}

static struct Text *rewrite_alignment_calls(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    out->tail_return = in->tail_return;
    out->ast = in->ast;
    while (*p != '\0') {
        if (*p == '"' || *p == '\'') {
            char quote = *p;
            text_add_ch(out, *p++);
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    text_add_ch(out, *p++);
                    text_add_ch(out, *p++);
                    continue;
                }
                text_add_ch(out, *p);
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (starts_word(p, "align_up") || starts_word(p, "align_down") || starts_word(p, "is_aligned")) {
            char name[NAME_MAX_LEN];
            const char *name_end = read_name(p, name);
            const char *open = skip_ws(name_end);
            const char *close;
            const char *comma;
            char tmp[64];

            if (*open != '(') {
                text_add_n(out, p, (size_t)(name_end - p));
                p = name_end;
                continue;
            }
            close = matching_paren(open);
            if (close == NULL) {
                fprintf(stderr, "c-: type error: unterminated %s call at %s:%d\n",
                        name, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
                exit(1);
            }
            comma = find_top_level_char(open + 1, close, ',');
            if (comma == NULL) {
                fprintf(stderr, "c-: type error: %s expects two arguments at %s:%d\n",
                        name, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
                exit(1);
            }
            if (strcmp(name, "align_up") == 0) {
                text_add(out, "cminus_align_up_impl");
            } else if (strcmp(name, "align_down") == 0) {
                text_add(out, "cminus_align_down_impl");
            } else {
                text_add(out, "cminus_is_aligned_impl");
            }
            text_add_ch(out, '(');
            text_add(out, "(unsigned long)(");
            text_add_n(out, open + 1, (size_t)(comma - open - 1));
            text_add(out, "), (unsigned long)(");
            text_add_n(out, comma + 1, (size_t)(close - comma - 1));
            text_add(out, "), \"");
            text_add(out, g_input_path == NULL ? "<unknown>" : g_input_path);
            text_add(out, "\", ");
            snprintf(tmp, sizeof(tmp), "%d", yylineno);
            text_add(out, tmp);
            text_add_ch(out, ')');
            p = close + 1;
            changed = 1;
            continue;
        }
        text_add_ch(out, *p++);
    }
    if (!changed) {
        out->ast = NULL;
        text_free(out);
        return in;
    }
    in->ast = NULL;
    text_free(in);
    return out;
}

static struct Text *rewrite_mmio_field_decl(struct Text *in, struct DeclInfo *decl)
{
    const char *start = skip_ws(in->text);
    const char *name_pos;
    const char *type_end;
    const char *after_name;
    struct Text *out;

    if (decl == NULL || !decl->is_decl || decl->is_function || decl->name[0] == '\0') {
        return in;
    }
    if (decl->type.kind == TY_STRUCT &&
        (strcmp(decl->type.tag, "Register") == 0 || strncmp(decl->type.tag, "Register_", 9) == 0)) {
        return in;
    }
    if (decl->is_array || decl->type.ptr > 0) {
        fprintf(stderr, "c-: type error: mmio struct fields must be scalar register values at %s:%d; use Register<T> explicitly for unusual layouts\n",
                g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    if (!(decl->type.kind == TY_CHAR || decl->type.kind == TY_SHORT ||
          decl->type.kind == TY_INT || decl->type.kind == TY_LONG ||
          decl->type.kind == TY_ENUM || decl->type.kind == TY_BITFLAGS)) {
        fprintf(stderr, "c-: type error: mmio struct field '%s' must use an integer, enum, or bitflags type at %s:%d\n",
                decl->name, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    name_pos = find_decl_name_pos(in->text, decl->name);
    if (name_pos == NULL) {
        return in;
    }
    type_end = name_pos;
    while (type_end > start && isspace((unsigned char)type_end[-1])) {
        type_end--;
    }
    after_name = skip_ws(name_pos + strlen(decl->name));
    if (*after_name != ';' && *after_name != '\0') {
        fprintf(stderr, "c-: type error: mmio struct fields cannot have initializers or declarator suffixes at %s:%d\n",
                g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
        exit(1);
    }
    out = text_new();
    text_add_n(out, in->text, (size_t)(start - in->text));
    text_add(out, "Register<");
    text_add_n(out, start, (size_t)(type_end - start));
    text_add(out, "> ");
    text_add(out, decl->name);
    text_add(out, ";");
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    in->ast = NULL;
    text_free(in);
    out = rewrite_generics(out);
    return out;
}

static struct Text *strip_mmio_modifier(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    while (*p != '\0') {
        if (starts_word(p, "mmio")) {
            const char *next = skip_ws(p + 4);
            text_add(out, next);
            changed = 1;
            break;
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

static struct Text *strip_attributes(struct Text *in)
{
    struct Text *out = text_new();
    size_t i = 0;
    out->ast = in->ast;
    while (i < in->len) {
        if (strncmp(in->text + i, "__attribute__", 13) == 0) {
            size_t j = i + 13;
            size_t attr_start = i;
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
                if (range_contains_text(in->text + attr_start, in->text + j, "unused") ||
                    range_contains_text(in->text + attr_start, in->text + j, "interrupt") ||
                    range_contains_text(in->text + attr_start, in->text + j, "section") ||
                    range_contains_text(in->text + attr_start, in->text + j, "aligned") ||
                    range_contains_text(in->text + attr_start, in->text + j, "packed") ||
                    range_contains_text(in->text + attr_start, in->text + j, "used") ||
                    range_contains_text(in->text + attr_start, in->text + j, "naked") ||
                    range_contains_text(in->text + attr_start, in->text + j, "noreturn") ||
                    range_contains_text(in->text + attr_start, in->text + j, "weak") ||
                    range_contains_text(in->text + attr_start, in->text + j, "externally_visible")) {
                    text_add_n(out, in->text + attr_start, j - attr_start);
                }
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

struct SafetyOwnedCallContext {
    const struct SafetyExprNode *call;
    char name[NAME_MAX_LEN];
    int registered_only;
};

static void find_owned_call_node(const struct SafetyExprNode *node,
                                 const struct SafetyExprNode *parent,
                                 void *opaque)
{
    struct SafetyOwnedCallContext *context = opaque;
    char name[NAME_MAX_LEN];
    int index;
    (void)parent;

    if (node->kind != SAFETY_EXPR_CALL || !safety_callee_name(node, name)) {
        return;
    }
    index = malloc_func_index(name);
    if (index < 0 && (context->registered_only || !function_name_looks_owned(name))) {
        return;
    }
    if (context->call == NULL || node->start < context->call->start) {
        context->call = node;
        strncpy(context->name, name, NAME_MAX_LEN - 1);
        context->name[NAME_MAX_LEN - 1] = '\0';
    }
}

static int rhs_has_malloc_call(const char *rhs, char *func_name)
{
    struct SafetyExprNode *forest = safety_parse_forest(rhs);
    struct SafetyOwnedCallContext context;

    memset(&context, 0, sizeof(context));
    safety_expr_walk(forest, NULL, find_owned_call_node, &context);
    func_name[0] = '\0';
    if (context.call != NULL) {
        strncpy(func_name, context.name, NAME_MAX_LEN - 1);
        func_name[NAME_MAX_LEN - 1] = '\0';
    }
    safety_expr_free(forest);
    return context.call != NULL;
}

static const char *scan_call_end(const char *open)
{
    const char *p = open;
    int depth = 0;

    if (*p != '(') {
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
        } else if (*p == '(') {
            depth++;
        } else if (*p == ')') {
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

static int find_owned_return_call(const char *s, const char **call_start, const char **call_end,
                                  struct Type *type)
{
    struct SafetyExprNode *forest = safety_parse_forest(s);
    struct SafetyOwnedCallContext context;
    int index;

    memset(&context, 0, sizeof(context));
    context.registered_only = 1;
    safety_expr_walk(forest, NULL, find_owned_call_node, &context);
    if (context.call == NULL) {
        safety_expr_free(forest);
        return 0;
    }
    if (call_start != NULL) {
        *call_start = context.call->start;
    }
    if (call_end != NULL) {
        *call_end = context.call->end;
    }
    index = malloc_func_index(context.name);
    if (type != NULL && index >= 0) {
        *type = g_malloc_funcs.ret[index];
    }
    safety_expr_free(forest);
    return 1;
}

static int rhs_is_single_owned_return_call(const char *rhs)
{
    const char *start;
    const char *end;
    const char *p = skip_ws(rhs);
    char name[NAME_MAX_LEN];
    const char *name_end;
    const char *q;

    if (!find_owned_return_call(rhs, &start, &end, NULL) || start != p) {
        if (!is_ident_start((unsigned char)*p)) {
            return 0;
        }
        name_end = read_name(p, name);
        if (!function_name_looks_owned(name)) {
            return 0;
        }
        q = skip_ws(name_end);
        if (*q != '(') {
            return 0;
        }
        end = scan_call_end(q);
        if (end == NULL) {
            return 0;
        }
        end = skip_ws(end);
        if (*end == ';') {
            end = skip_ws(end + 1);
        }
        return *end == '\0';
    }
    end = skip_ws(end);
    if (*end == ';') {
        end = skip_ws(end + 1);
    }
    return *end == '\0';
}

static struct Text *rewrite_owned_return_rvalues(struct Text *in, const char *original)
{
    struct Text *prefix = text_new();
    struct Text *body = text_new();
    struct Text *suffix = text_new();
    struct Text *out;
    struct Text *indent = text_new();
    const char *p = in->text;
    int changed = 0;

    append_indent_from(original, indent);
    while (*p != '\0') {
        const char *start;
        const char *end;
        struct Type type;
        char tmp[NAME_MAX_LEN];

        if (!find_owned_return_call(p, &start, &end, &type)) {
            text_add(body, p);
            break;
        }
        snprintf(tmp, sizeof(tmp), "__right_value%d", g_right_value_id++);
        text_add_n(body, p, (size_t)(start - p));
        text_add(body, tmp);

        text_add(prefix, indent->text);
        append_c_type(prefix, type);
        text_add_ch(prefix, ' ');
        text_add(prefix, tmp);
        text_add(prefix, " = ");
        text_add_n(prefix, start, (size_t)(end - start));
        text_add(prefix, ";\n");

        append_release_pointer(suffix, indent->text, tmp, type);

        p = end;
        changed = 1;
    }

    if (!changed) {
        text_free(prefix);
        text_free(body);
        text_free(suffix);
        text_free(indent);
        return in;
    }

    out = text_new();
    text_add_ch(out, '\n');
    text_add(out, prefix->text);
    text_add(out, body->text);
    text_add_ch(out, '\n');
    text_add(out, suffix->text);
    out->tail_return = in->tail_return;
    out->ast = in->ast;

    text_free(prefix);
    text_free(body);
    text_free(suffix);
    text_free(indent);
    text_free(in);
    return out;
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
    if (base.kind != TY_STRUCT || ptr != 0) {
        fprintf(stderr, "c-: type error: new is only allowed for struct types\n");
        exit(1);
    }
    *type = base;
    type->ptr += ptr + 1;
    type->owned = 1;
    type->raw_ptr = 0;

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
            text_add(out, clone_uses_managed_heap(base.tag) ? " = cminus_gc_calloc(strlen(" : " = calloc(strlen(");
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
            text_add(out, clone_uses_managed_heap(base.tag) ? " = cminus_gc_calloc(1, sizeof(" : " = calloc(1, sizeof(");
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
    source_type = safety_ast_expr_type(tmp);
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
        type->raw_ptr = 0;
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
        value_type = safety_ast_expr_type(value);
        check_assignment_type(field, field_type, value_type);
        text_add(out, tmp);
        text_add(out, "->");
        text_add(out, field);
        text_add(out, " = ");
        if (text_has_s_string(value)) {
            text_add(out, "move ");
        }
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
        text_add(out, " = cminus_gc_calloc(1, sizeof(");
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
        text_add(out, "cminus_gc_calloc(1, sizeof(");
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

static int s_string_is_in_new_initializer(const char *stmt_start, const char *s_start)
{
    const char *p;
    const char *last_new = NULL;
    const char *last_lbrace = NULL;
    const char *last_rbrace = NULL;
    int paren = 0;
    int bracket = 0;

    for (p = stmt_start; p < s_start; p++) {
        if (*p == '(') {
            paren++;
        } else if (*p == ')' && paren > 0) {
            paren--;
        } else if (*p == '[') {
            bracket++;
        } else if (*p == ']' && bracket > 0) {
            bracket--;
        }
        if (paren != 0 || bracket != 0) {
            continue;
        }
        if (starts_word(p, "new")) {
            last_new = p;
        } else if (*p == '{') {
            last_lbrace = p;
        } else if (*p == '}') {
            last_rbrace = p;
        } else if (*p == ';') {
            last_new = NULL;
            last_lbrace = NULL;
            last_rbrace = NULL;
        }
    }
    return last_new != NULL && last_lbrace != NULL && last_new < last_lbrace &&
        (last_rbrace == NULL || last_rbrace < last_lbrace);
}

static int s_string_is_push_argument(const char *stmt_start, const char *s_start)
{
    const char *p;
    const char *open = NULL;
    const char *name_end;
    const char *name_start;
    char name[NAME_MAX_LEN];

    for (p = stmt_start; p < s_start; p++) {
        if (*p == '(') {
            open = p;
        } else if (*p == ';') {
            open = NULL;
        }
    }
    if (open == NULL) {
        return 0;
    }
    name_end = open;
    while (name_end > stmt_start && isspace((unsigned char)name_end[-1])) {
        name_end--;
    }
    name_start = name_end;
    while (name_start > stmt_start &&
           (is_ident((unsigned char)name_start[-1]) || name_start[-1] == '.')) {
        name_start--;
    }
    if (name_start == name_end || (size_t)(name_end - name_start) >= sizeof(name)) {
        return 0;
    }
    memcpy(name, name_start, (size_t)(name_end - name_start));
    name[name_end - name_start] = '\0';
    return strcmp(name, "push") == 0 ||
        strstr(name, ".push") != NULL ||
        strstr(name, "_push_") != NULL ||
        strstr(name, "_push_front_") != NULL ||
        strstr(name, "_set_") != NULL;
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

static struct Text *build_s_string_format_statement(const char *lhs_name, const char *rhs, const char *original)
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
    text_add(stmt, lhs_name);
    text_add(stmt, " = cminus_string_format(");
    text_add(stmt, fmt->text);
    text_add(stmt, args->text);
    text_add(stmt, ");");
    stmt->ast = ast_raw(ND_S_STRING, stmt->text);

    text_free(indent);
    text_free(fmt);
    text_free(args);
    return stmt;
}

static void append_s_string_format_for_quote(struct Text *out, const char *name, const char *quote, const char *indent)
{
    struct Text *fmt = text_new();
    struct Text *args = text_new();

    if (!build_s_format(quote, fmt, args)) {
        fprintf(stderr, "c-: invalid s string literal\n");
        exit(1);
    }
    text_add(out, indent);
    text_add(out, name);
    text_add(out, " = cminus_string_format(");
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
        int moved = 0;
        int escapes_to_object_initializer = s_string_is_in_new_initializer(leading_end, s_start);
        int escapes_to_push = s_string_is_push_argument(leading_end, s_start);
        const char *move_end = s_start;
        const char *move_start;

        while (move_end > cursor && isspace((unsigned char)move_end[-1])) {
            move_end--;
        }
        move_start = move_end;
        while (move_start > cursor && is_ident((unsigned char)move_start[-1])) {
            move_start--;
        }
        if (move_end - move_start == 4 && strncmp(move_start, "move", 4) == 0 &&
            (move_start == cursor || !is_ident((unsigned char)move_start[-1]))) {
            moved = 1;
        }
        snprintf(tmp, sizeof(tmp), "__right_value%d", g_right_value_id++);
        if (moved) {
            text_add_n(rewritten, cursor, (size_t)(move_start - cursor));
        } else {
            text_add_n(rewritten, cursor, (size_t)(s_start - cursor));
        }
        text_add(rewritten, tmp);

        text_add(prefix, indent->text);
        text_add(prefix, "char* ");
        text_add(prefix, tmp);
        text_add(prefix, " = NULL;\n");
        append_s_string_format_for_quote(prefix, tmp, quote_start, indent->text);

        if (!moved && !escapes_to_object_initializer && !escapes_to_push) {
            text_add(suffix, "\n");
            text_add(suffix, indent->text);
            text_add(suffix, "cminus_gc_free(");
            text_add(suffix, tmp);
            text_add(suffix, ");");
        }

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

    if (*s == 's' && s[1] == '"') {
        receiver_end = scan_string_end(s + 1);
    } else if (*s == '"') {
        receiver_end = scan_string_end(s);
    } else {
        return 0;
    }
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

    if (strcmp(method, "len") == 0) {
        text_add(replacement, "cminus_string_len");
    } else if (strcmp(method, "is_empty") == 0) {
        text_add(replacement, "cminus_string_is_empty");
    } else if (strcmp(method, "cmp") == 0) {
        text_add(replacement, "cminus_string_cmp");
    } else if (strcmp(method, "eq") == 0) {
        text_add(replacement, "cminus_string_eq");
    } else if (strcmp(method, "contains") == 0) {
        text_add(replacement, "cminus_string_contains");
    } else if (strcmp(method, "starts_with") == 0) {
        text_add(replacement, "cminus_string_starts_with");
    } else if (strcmp(method, "ends_with") == 0) {
        text_add(replacement, "cminus_string_ends_with");
    } else if (strcmp(method, "strcmp") == 0) {
        text_add(replacement, "cminus_string_cmp");
    } else {
        return 0;
    }
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

static int try_rewrite_critical_static_method(const char *s, const char **end, struct Text *replacement)
{
    const char *p = s;
    const char *dot;
    const char *method_start;
    const char *method_end;
    const char *open;
    const char *close;
    char method[NAME_MAX_LEN];

    if (!starts_word(p, "Critical")) {
        return 0;
    }
    dot = skip_ws(p + 8);
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
    if (strcmp(method, "enter") != 0) {
        return 0;
    }
    text_add(replacement, "Critical_enter(");
    if (close > open + 1) {
        text_add_n(replacement, open + 1, (size_t)(close - open - 1));
    }
    text_add_ch(replacement, ')');
    *end = close + 1;
    return 1;
}

static int try_rewrite_bitmap_static_method(const char *s, const char **end, struct Text *replacement)
{
    const char *p = s;
    const char *dot;
    const char *method_start;
    const char *method_end;
    const char *open;
    const char *close;
    char method[NAME_MAX_LEN];

    if (!starts_word(p, "Bitmap")) {
        return 0;
    }
    dot = skip_ws(p + 6);
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
    if (strcmp(method, "from") == 0) {
        text_add(replacement, "Bitmap_from(");
    } else if (strcmp(method, "from_words") == 0) {
        text_add(replacement, "Bitmap_from_words(");
    } else if (strcmp(method, "from_bytes") == 0) {
        text_add(replacement, "Bitmap_from_bytes(");
    } else {
        return 0;
    }
    if (close > open + 1) {
        text_add_n(replacement, open + 1, (size_t)(close - open - 1));
    }
    text_add_ch(replacement, ')');
    *end = close + 1;
    return 1;
}

struct ThreadSendContext {
    char visiting[MAX_FINALIZERS][NAME_MAX_LEN];
    int count;
};

static int thread_send_tag_has_reference(const char *tag)
{
    return strcmp(tag, "Ref") == 0 || strcmp(tag, "Span") == 0 ||
        strncmp(tag, "Ref_", 4) == 0 ||
        strncmp(tag, "Span_", 5) == 0 ||
        strstr(tag, "_Ref_") != NULL || strstr(tag, "_Span_") != NULL;
}

static int thread_send_tag_is_intrinsically_local(const char *tag)
{
    return strcmp(tag, "FixedVec") == 0 ||
        strncmp(tag, "FixedVec_", 9) == 0 ||
        strcmp(tag, "RingBuffer") == 0 ||
        strncmp(tag, "RingBuffer_", 11) == 0 ||
        strcmp(tag, "Bitmap") == 0 ||
        strcmp(tag, "Register") == 0 ||
        strncmp(tag, "Register_", 9) == 0 ||
        strcmp(tag, "Volatile") == 0 ||
        strncmp(tag, "Volatile_", 9) == 0 ||
        strcmp(tag, "StaticCell") == 0 ||
        strncmp(tag, "StaticCell_", 11) == 0 ||
        strcmp(tag, "Critical") == 0 || strcmp(tag, "Thread") == 0 ||
        strcmp(tag, "Mutex") == 0 || strcmp(tag, "Cond") == 0;
}

static int thread_send_context_contains(struct ThreadSendContext *context,
                                        const char *tag)
{
    int i;

    for (i = 0; i < context->count; i++) {
        if (strcmp(context->visiting[i], tag) == 0) {
            return 1;
        }
    }
    return 0;
}

static int type_is_thread_send_recursive(struct Type type,
                                         struct ThreadSendContext *context)
{
    struct StructFinalizer *fields;
    struct Type value;
    int i;

    if (!type_is_known(type) || type.raw_ptr ||
        type.kind == TY_VOID || type.kind == TY_FUNCTION ||
        type.kind == TY_UNION || type.kind == TY_GENERIC ||
        type.kind == TY_TYPEDEF || type.kind == TY_TYPE_CONSTRUCTOR ||
        type_is_stored_safe_reference(type) ||
        type_is_heap_container_with_safe_reference(type) ||
        type_is_runtime_resource_value(type)) {
        return 0;
    }
    if (type.kind == TY_STRUCT &&
        (thread_send_tag_has_reference(type.tag) ||
         thread_send_tag_is_intrinsically_local(type.tag))) {
        return 0;
    }
    if (type.ptr > 0) {
        if (!type.owned) {
            return 0;
        }
        value = type;
        value.ptr--;
        value.owned = 0;
        value.raw_ptr = 0;
        return type_is_thread_send_recursive(value, context);
    }
    if (type.kind != TY_STRUCT) {
        return 1;
    }
    if (thread_send_context_contains(context, type.tag)) {
        return 1;
    }
    if (context->count >= MAX_FINALIZERS) {
        die("Send type graph is too deep");
    }
    strncpy(context->visiting[context->count], type.tag, NAME_MAX_LEN - 1);
    context->visiting[context->count][NAME_MAX_LEN - 1] = '\0';
    context->count++;
    fields = struct_clone_find(type.tag);
    if (fields != NULL) {
        for (i = 0; i < fields->count; i++) {
            if (!type_is_thread_send_recursive(fields->fields[i].type,
                                               context)) {
                context->count--;
                return 0;
            }
        }
    }
    context->count--;
    return 1;
}

static int type_is_thread_send_capture(struct Type type)
{
    struct ThreadSendContext context;

    if (type.is_array || (type.ptr > 0 && !type.owned)) {
        return 0;
    }
    memset(&context, 0, sizeof(context));
    return type_is_thread_send_recursive(type, &context);
}

static int try_rewrite_thread_static_method(const char *s, const char **end, struct Text *replacement)
{
    const char *dot;
    const char *method_start;
    const char *method_end;
    const char *open;
    const char *close;
    const char *type_end;
    char type[NAME_MAX_LEN];
    char method[NAME_MAX_LEN];

    if (!starts_word(s, "Thread") && !starts_word(s, "Mutex") && !starts_word(s, "Cond")) {
        return 0;
    }
    type_end = read_name(s, type);
    dot = skip_ws(type_end);
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
    if (strcmp(type, "Thread") == 0 && strcmp(method, "spawn") == 0) {
        const char *comma = find_parameter_comma(open + 1, close);

        if (comma != NULL) {
            const char *argument_start = open + 1;
            char argument[MAX_PARAMS + 1][DEFAULT_EXPR_MAX];
            char capture_name[MAX_PARAMS][NAME_MAX_LEN];
            struct Symbol *capture[MAX_PARAMS];
            char worker_name[NAME_MAX_LEN];
            char helper_name[NAME_MAX_LEN];
            char spawn_name[NAME_MAX_LEN];
            char context_name[NAME_MAX_LEN];
            struct FunctionParams *worker;
            int argument_count = 0;
            int capture_count;
            int helper_id;
            int i;
            int j;

            while (argument_start < close) {
                const char *separator =
                    find_parameter_comma(argument_start, close);
                const char *argument_end = separator == NULL ? close : separator;

                if (argument_count >= MAX_PARAMS + 1) {
                    die("too many Thread.spawn arguments");
                }
                copy_trimmed(argument[argument_count], DEFAULT_EXPR_MAX,
                             argument_start, argument_end);
                argument_count++;
                if (separator == NULL) {
                    break;
                }
                argument_start = separator + 1;
            }
            capture_count = argument_count - 1;
            if (capture_count <= 0 || capture_count > MAX_PARAMS) {
                fprintf(stderr,
                        "c-: type error: Thread.spawn accepts worker or one or more moved values followed by worker\n");
                exit(1);
            }
            if (!extract_plain_name_expr(argument[argument_count - 1],
                                         worker_name)) {
                fprintf(stderr,
                        "c-: thread safety error: Thread.spawn requires a directly named worker function\n");
                exit(1);
            }
            for (i = 0; i < capture_count; i++) {
                if (!extract_plain_name_expr(argument[i], capture_name[i]) ||
                    moved_local_index(capture_name[i]) < 0) {
                    fprintf(stderr,
                            "c-: ownership error: Thread.spawn capture %d requires 'move value'\n",
                            i + 1);
                    exit(1);
                }
                for (j = 0; j < i; j++) {
                    if (strcmp(capture_name[j], capture_name[i]) == 0) {
                        fprintf(stderr,
                                "c-: ownership error: Thread.spawn cannot move '%s' more than once\n",
                                capture_name[i]);
                        exit(1);
                    }
                }
                capture[i] = symbol_find(capture_name[i]);
                if (capture[i] == NULL) {
                    fprintf(stderr,
                            "c-: type error: Thread.spawn capture '%s' is not a visible local variable\n",
                            capture_name[i]);
                    exit(1);
                }
                if (!type_is_thread_send_capture(capture[i]->type)) {
                    char type_text[NAME_MAX_LEN * 2];
                    type_to_string(capture[i]->type, type_text,
                                   sizeof(type_text));
                    fprintf(stderr,
                            "c-: thread safety error: moved value '%s' of type '%s' is not Send; use an owned Box/string without Ref, Span, raw pointers, or runtime resources\n",
                            capture_name[i], type_text);
                    exit(1);
                }
            }
            worker = function_params_find(worker_name);
            if (worker == NULL) {
                fprintf(stderr,
                        "c-: thread safety error: Thread.spawn worker '%s' needs a visible safe declaration\n",
                        worker_name);
                exit(1);
            }
            if (worker->is_unsafe || worker->ret.kind != TY_INT ||
                worker->ret.ptr != 0 || worker->count != capture_count) {
                fprintf(stderr,
                        "c-: thread safety error: worker '%s' must be a safe 'int' function with %d owned parameter%s matching the moved values\n",
                        worker_name, capture_count,
                        capture_count == 1 ? "" : "s");
                exit(1);
            }
            for (i = 0; i < capture_count; i++) {
                if (!worker->param[i].owned || worker->param[i].borrowed ||
                    !type_same_unowned(capture[i]->type,
                                       worker->param[i].type)) {
                    char capture_type_text[NAME_MAX_LEN * 2];
                    char parameter_type_text[NAME_MAX_LEN * 2];
                    type_to_string(capture[i]->type, capture_type_text,
                                   sizeof(capture_type_text));
                    type_to_string(worker->param[i].type,
                                   parameter_type_text,
                                   sizeof(parameter_type_text));
                    fprintf(stderr,
                            "c-: thread safety error: worker '%s' parameter %d must be owned and match moved value '%s' (capture '%s', parameter '%s', owned %s)\n",
                            worker_name, i + 1, capture_name[i],
                            capture_type_text, parameter_type_text,
                            worker->param[i].owned ? "yes" : "no");
                    exit(1);
                }
            }
            if (g_thread_owned_helper_id >= MAX_FUNCS ||
                g_thread_owned_entry_count >= MAX_FUNCS) {
                die("too many owned Thread.spawn calls");
            }
            helper_id = g_thread_owned_helper_id++;
            snprintf(helper_name, sizeof(helper_name),
                     "__cminus_thread_owned_entry_%d",
                     helper_id);
            text_add(g_defines, "static int ");
            text_add(g_defines, helper_name);
            text_add(g_defines, "(void* __cminus_raw);\n");
            if (capture_count == 1 && capture[0]->type.ptr > 0) {
                text_add(g_thread_owned_helpers, "static int ");
                text_add(g_thread_owned_helpers, helper_name);
                text_add(g_thread_owned_helpers,
                         "(void* __cminus_raw)\n{\n    return ");
                text_add(g_thread_owned_helpers, worker_name);
                text_add(g_thread_owned_helpers, "((");
                append_c_type(g_thread_owned_helpers, worker->param[0].type);
                text_add(g_thread_owned_helpers, ")__cminus_raw);\n}\n");
            } else {
                snprintf(spawn_name, sizeof(spawn_name),
                         "__cminus_thread_owned_spawn_%d", helper_id);
                snprintf(context_name, sizeof(context_name),
                         "__CMinusThreadOwnedContext_%d", helper_id);
                text_add(g_defines, "struct Thread;\nstatic struct Thread ");
                text_add(g_defines, spawn_name);
                text_add_ch(g_defines, '(');
                for (i = 0; i < capture_count; i++) {
                    if (i > 0) text_add(g_defines, ", ");
                    text_add(g_defines, "void*");
                }
                text_add(g_defines, ");\n");

                text_add(g_thread_owned_helpers, "struct ");
                text_add(g_thread_owned_helpers, context_name);
                text_add(g_thread_owned_helpers, " {\n");
                for (i = 0; i < capture_count; i++) {
                    char index_text[32];
                    snprintf(index_text, sizeof(index_text), "%d", i);
                    text_add(g_thread_owned_helpers, "    ");
                    append_c_type(g_thread_owned_helpers, capture[i]->type);
                    text_add(g_thread_owned_helpers, " value_");
                    text_add(g_thread_owned_helpers, index_text);
                    text_add(g_thread_owned_helpers, ";\n");
                }
                text_add(g_thread_owned_helpers, "};\nstatic int ");
                text_add(g_thread_owned_helpers, helper_name);
                text_add(g_thread_owned_helpers,
                         "(void* __cminus_raw)\n{\n    struct ");
                text_add(g_thread_owned_helpers, context_name);
                text_add(g_thread_owned_helpers,
                         "* __cminus_context = (struct ");
                text_add(g_thread_owned_helpers, context_name);
                text_add(g_thread_owned_helpers,
                         "*)__cminus_raw;\n");
                for (i = 0; i < capture_count; i++) {
                    char index_text[32];
                    snprintf(index_text, sizeof(index_text), "%d", i);
                    text_add(g_thread_owned_helpers, "    ");
                    append_c_type(g_thread_owned_helpers, capture[i]->type);
                    text_add(g_thread_owned_helpers, " __cminus_value_");
                    text_add(g_thread_owned_helpers, index_text);
                    text_add(g_thread_owned_helpers,
                             " = __cminus_context->value_");
                    text_add(g_thread_owned_helpers, index_text);
                    text_add(g_thread_owned_helpers, ";\n");
                }
                text_add(g_thread_owned_helpers,
                         "    cminus_gc_free(__cminus_context);\n    return ");
                text_add(g_thread_owned_helpers, worker_name);
                text_add_ch(g_thread_owned_helpers, '(');
                for (i = 0; i < capture_count; i++) {
                    char index_text[32];
                    snprintf(index_text, sizeof(index_text), "%d", i);
                    if (i > 0) text_add(g_thread_owned_helpers, ", ");
                    text_add(g_thread_owned_helpers, "__cminus_value_");
                    text_add(g_thread_owned_helpers, index_text);
                }
                text_add(g_thread_owned_helpers, ");\n}\nstatic struct Thread ");
                text_add(g_thread_owned_helpers, spawn_name);
                text_add_ch(g_thread_owned_helpers, '(');
                for (i = 0; i < capture_count; i++) {
                    char index_text[32];
                    snprintf(index_text, sizeof(index_text), "%d", i);
                    if (i > 0) text_add(g_thread_owned_helpers, ", ");
                    text_add(g_thread_owned_helpers, "void* value_");
                    text_add(g_thread_owned_helpers, index_text);
                }
                text_add(g_thread_owned_helpers, ")\n{\n    struct ");
                text_add(g_thread_owned_helpers, context_name);
                text_add(g_thread_owned_helpers, "* context = cminus_gc_calloc(1, sizeof(struct ");
                text_add(g_thread_owned_helpers, context_name);
                text_add(g_thread_owned_helpers, "));\n");
                for (i = 0; i < capture_count; i++) {
                    char index_text[32];
                    snprintf(index_text, sizeof(index_text), "%d", i);
                    text_add(g_thread_owned_helpers, "    context->value_");
                    text_add(g_thread_owned_helpers, index_text);
                    if (capture[i]->type.ptr > 0) {
                        text_add(g_thread_owned_helpers, " = (");
                        append_c_type(g_thread_owned_helpers,
                                      capture[i]->type);
                        text_add(g_thread_owned_helpers, ")value_");
                    } else {
                        text_add(g_thread_owned_helpers, " = *(");
                        append_c_type(g_thread_owned_helpers,
                                      capture[i]->type);
                        text_add(g_thread_owned_helpers, "*)value_");
                    }
                    text_add(g_thread_owned_helpers, index_text);
                    text_add(g_thread_owned_helpers, ";\n");
                }
                text_add(g_thread_owned_helpers,
                         "    return Thread_spawn_context(context, ");
                text_add(g_thread_owned_helpers, helper_name);
                text_add(g_thread_owned_helpers, ");\n}\n");
            }
            strncpy(g_thread_owned_entries[g_thread_owned_entry_count],
                    worker_name, NAME_MAX_LEN - 1);
            g_thread_owned_entries[g_thread_owned_entry_count][NAME_MAX_LEN - 1] = '\0';
            g_thread_owned_entry_count++;

            if (capture_count == 1 && capture[0]->type.ptr > 0) {
                text_add(replacement, "Thread_spawn_context((void*)");
                text_add(replacement, capture_name[0]);
                text_add(replacement, ", ");
                text_add(replacement, helper_name);
            } else {
                text_add(replacement, spawn_name);
                text_add_ch(replacement, '(');
                for (i = 0; i < capture_count; i++) {
                    if (i > 0) text_add(replacement, ", ");
                    if (capture[i]->type.ptr > 0) {
                        text_add(replacement, "(void*)");
                    } else {
                        text_add(replacement, "(void*)&");
                    }
                    text_add(replacement, capture_name[i]);
                }
            }
            text_add_ch(replacement, ')');
            *end = close + 1;
            return 1;
        }
        text_add(replacement, "Thread_spawn(");
    } else if (strcmp(type, "Thread") == 0 && strcmp(method, "yield") == 0) {
        text_add(replacement, "Thread_yield(");
    } else if (strcmp(type, "Mutex") == 0 && strcmp(method, "init") == 0) {
        text_add(replacement, "Mutex_init(");
    } else if (strcmp(type, "Cond") == 0 && strcmp(method, "init") == 0) {
        text_add(replacement, "Cond_init(");
    } else {
        return 0;
    }
    if (close > open + 1) {
        text_add_n(replacement, open + 1, (size_t)(close - open - 1));
    }
    text_add_ch(replacement, ')');
    *end = close + 1;
    return 1;
}

static int try_rewrite_string_symbol_method(const char *s, const char **end, struct Text *replacement)
{
    const char *name_end;
    const char *dot;
    const char *method_start;
    const char *method_end;
    const char *open;
    const char *close;
    char name[NAME_MAX_LEN];
    char method[NAME_MAX_LEN];
    struct Symbol *sym;

    if (!is_ident_start((unsigned char)*s)) {
        return 0;
    }
    name_end = read_name(s, name);
    sym = symbol_find(name);
    if (sym == NULL || !type_is_string_like(sym->type)) {
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
    if (strcmp(method, "len") == 0) {
        text_add(replacement, "cminus_string_len");
    } else if (strcmp(method, "is_empty") == 0) {
        text_add(replacement, "cminus_string_is_empty");
    } else if (strcmp(method, "cmp") == 0) {
        text_add(replacement, "cminus_string_cmp");
    } else if (strcmp(method, "eq") == 0) {
        text_add(replacement, "cminus_string_eq");
    } else if (strcmp(method, "contains") == 0) {
        text_add(replacement, "cminus_string_contains");
    } else if (strcmp(method, "starts_with") == 0) {
        text_add(replacement, "cminus_string_starts_with");
    } else if (strcmp(method, "ends_with") == 0) {
        text_add(replacement, "cminus_string_ends_with");
    } else if (strcmp(method, "strcmp") == 0) {
        text_add(replacement, "cminus_string_cmp");
    } else {
        return 0;
    }
    text_add_ch(replacement, '(');
    text_add_n(replacement, s, (size_t)(name_end - s));
    if (close > open + 1) {
        text_add(replacement, ", ");
        text_add_n(replacement, open + 1, (size_t)(close - open - 1));
    }
    text_add_ch(replacement, ')');
    *end = close + 1;
    return 1;
}

static int append_string_method_name(struct Text *replacement, const char *method)
{
    if (strcmp(method, "len") == 0) {
        text_add(replacement, "cminus_string_len");
    } else if (strcmp(method, "is_empty") == 0) {
        text_add(replacement, "cminus_string_is_empty");
    } else if (strcmp(method, "cmp") == 0) {
        text_add(replacement, "cminus_string_cmp");
    } else if (strcmp(method, "eq") == 0) {
        text_add(replacement, "cminus_string_eq");
    } else if (strcmp(method, "contains") == 0) {
        text_add(replacement, "cminus_string_contains");
    } else if (strcmp(method, "starts_with") == 0) {
        text_add(replacement, "cminus_string_starts_with");
    } else if (strcmp(method, "ends_with") == 0) {
        text_add(replacement, "cminus_string_ends_with");
    } else if (strcmp(method, "strcmp") == 0) {
        text_add(replacement, "cminus_string_cmp");
    } else {
        return 0;
    }
    return 1;
}

static int try_rewrite_string_expr_method(const char *s, const char **end, struct Text *replacement)
{
    const char *name_end;
    const char *dot;
    char name[NAME_MAX_LEN];
    struct Symbol *sym;
    struct Type current;

    if (!is_ident_start((unsigned char)*s)) {
        return 0;
    }
    name_end = read_name(s, name);
    sym = symbol_find(name);
    if (sym == NULL) {
        return 0;
    }
    current = sym->type;
    dot = skip_ws(name_end);
    while (*dot == '.' || (dot[0] == '-' && dot[1] == '>')) {
        const char *field_start = skip_ws(*dot == '.' ? dot + 1 : dot + 2);
        const char *field_end;
        const char *after_field;
        char field[NAME_MAX_LEN];
        struct Type field_type;

        if (!is_ident_start((unsigned char)*field_start)) {
            return 0;
        }
        field_end = read_name(field_start, field);
        after_field = skip_ws(field_end);
        if (type_is_string_like(current)) {
            const char *close;

            if (*after_field != '(') {
                return 0;
            }
            close = matching_paren(after_field);
            if (close == NULL) {
                return 0;
            }
            if (!append_string_method_name(replacement, field)) {
                return 0;
            }
            text_add_ch(replacement, '(');
            text_add_n(replacement, s, (size_t)(dot - s));
            if (close > after_field + 1) {
                text_add(replacement, ", ");
                text_add_n(replacement, after_field + 1, (size_t)(close - after_field - 1));
            }
            text_add_ch(replacement, ')');
            *end = close + 1;
            return 1;
        }
        if (current.kind != TY_STRUCT || *after_field == '(' ||
            !struct_field_type(current.tag, field, &field_type)) {
            return 0;
        }
        current = field_type;
        dot = skip_ws(field_end);
    }
    return 0;
}

static void append_auto_field_expr(struct Text *out, const char *start, const char *end)
{
    const char *p = start;
    const char *name_end;
    char name[NAME_MAX_LEN];
    struct Symbol *sym;
    struct Type current;

    p = skip_ws(p);
    if (!is_ident_start((unsigned char)*p)) {
        text_add_n(out, start, (size_t)(end - start));
        return;
    }
    name_end = read_name(p, name);
    sym = symbol_find_or_current_param(name);
    if (sym == NULL || sym->type.kind != TY_STRUCT) {
        text_add_n(out, start, (size_t)(end - start));
        return;
    }
    text_add_n(out, start, (size_t)(name_end - start));
    current = sym->type;
    p = skip_ws(name_end);
    while (p < end && (*p == '.' || (p[0] == '-' && p[1] == '>'))) {
        const char *field_start = skip_ws(*p == '.' ? p + 1 : p + 2);
        const char *field_end;
        char field[NAME_MAX_LEN];
        struct Type field_type;

        if (!is_ident_start((unsigned char)*field_start)) {
            text_add_n(out, p, (size_t)(end - p));
            return;
        }
        field_end = read_name(field_start, field);
        if (current.kind != TY_STRUCT ||
            !struct_field_type(current.tag, field, &field_type)) {
            text_add_n(out, p, (size_t)(end - p));
            return;
        }
        if (current.ptr > 0 || (p[0] == '-' && p[1] == '>')) {
            text_add(out, "->");
        } else {
            text_add_ch(out, '.');
        }
        text_add_n(out, field_start, (size_t)(field_end - field_start));
        current = field_type;
        p = skip_ws(field_end);
    }
    if (p < end) {
        text_add_n(out, p, (size_t)(end - p));
    }
}

static int try_rewrite_struct_method(const char *s, const char **end, struct Text *replacement)
{
    const char *p;
    const char *receiver_end;
    const char *name_end;
    const char *dot;
    const char *method_start;
    const char *method_end;
    const char *open;
    const char *close;
    char obj[NAME_MAX_LEN];
    char field[NAME_MAX_LEN];
    char method[NAME_MAX_LEN];
    char generic_func[NAME_MAX_LEN];
    struct Symbol *sym;
    struct Type recv_type;
    int chained = 0;

    if (!is_ident_start((unsigned char)*s)) {
        return 0;
    }
    name_end = read_name(s, obj);
    sym = symbol_find_or_current_param(obj);
    if (sym == NULL || sym->type.kind != TY_STRUCT) {
        return 0;
    }
    recv_type = sym->type;
    p = name_end;
    dot = skip_ws(p);
    while (*dot == '.' || (dot[0] == '-' && dot[1] == '>')) {
        const char *field_start = skip_ws(*dot == '.' ? dot + 1 : dot + 2);
        const char *field_end;
        const char *after_field;

        if (!is_ident_start((unsigned char)*field_start)) {
            return 0;
        }
        field_end = read_name(field_start, field);
        after_field = skip_ws(field_end);
        if (*after_field == '(') {
            strncpy(method, field, NAME_MAX_LEN - 1);
            method[NAME_MAX_LEN - 1] = '\0';
            method_start = field_start;
            method_end = field_end;
            open = after_field;
            receiver_end = dot;
            goto found_method;
        }
        if (recv_type.kind != TY_STRUCT || !struct_field_type(recv_type.tag, field, &recv_type)) {
            return 0;
        }
        p = field_end;
        dot = skip_ws(p);
        chained = 1;
    }
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
    receiver_end = dot;
found_method:
    close = matching_paren(open);
    if (close == NULL) {
        return 0;
    }

    if (generic_method_concrete_name(recv_type.tag, method, generic_func, sizeof(generic_func))) {
        text_add(replacement, generic_func);
    } else {
        text_add(replacement, recv_type.tag);
        text_add_ch(replacement, '_');
        text_add(replacement, method);
    }
    text_add_ch(replacement, '(');
    if (recv_type.ptr > 0 || (!chained && *dot == '-')) {
        append_auto_field_expr(replacement, s, receiver_end);
    } else {
        text_add_ch(replacement, '&');
        if (chained) {
            text_add_ch(replacement, '(');
            append_auto_field_expr(replacement, s, receiver_end);
            text_add_ch(replacement, ')');
        } else {
            append_auto_field_expr(replacement, s, receiver_end);
        }
    }
    if (close > open + 1) {
        text_add(replacement, ", ");
        text_add_n(replacement, open + 1, (size_t)(close - open - 1));
    }
    text_add_ch(replacement, ')');
    *end = close + 1;
    return 1;
}

static int safety_ast_has_generic_start(const struct SafetyExprNode *node,
                                        const char *start)
{
    for (; node != NULL; node = node->next) {
        if (node->kind == SAFETY_EXPR_GENERIC && node->start == start) {
            return 1;
        }
        if (safety_ast_has_generic_start(node->lhs, start) ||
            safety_ast_has_generic_start(node->rhs, start) ||
            safety_ast_has_generic_start(node->child, start)) {
            return 1;
        }
    }
    return 0;
}

struct SafetyLoweringSite {
    const char *start;
    const char *end;
    char *replacement;
};

struct SafetyLoweringPlan {
    struct SafetyLoweringSite site[MAX_SAFETY_LOWERINGS];
    int count;
};

static int try_rewrite_method_node(const struct SafetyExprNode *node,
                                   const char **end,
                                   struct Text *replacement)
{
    const struct SafetyExprNode *callee;

    if (node == NULL || node->kind != SAFETY_EXPR_CALL) {
        return 0;
    }
    callee = safety_unwrap_group(node->lhs);
    if (callee == NULL || callee->kind != SAFETY_EXPR_MEMBER) {
        return 0;
    }
    return try_rewrite_string_method(node->start, end, replacement) ||
        try_rewrite_critical_static_method(node->start, end, replacement) ||
        try_rewrite_bitmap_static_method(node->start, end, replacement) ||
        try_rewrite_thread_static_method(node->start, end, replacement) ||
        try_rewrite_string_expr_method(node->start, end, replacement) ||
        try_rewrite_string_symbol_method(node->start, end, replacement) ||
        try_rewrite_struct_method(node->start, end, replacement);
}

static void collect_method_lowering_sites(const struct SafetyExprNode *node,
                                          struct SafetyLoweringPlan *plan)
{
    for (; node != NULL; node = node->next) {
        if (node->kind == SAFETY_EXPR_CALL) {
            struct Text *replacement = text_new();
            const char *end = NULL;

            if (try_rewrite_method_node(node, &end, replacement) &&
                end != NULL && end > node->start) {
                if (plan->count >= MAX_SAFETY_LOWERINGS) {
                    text_free(replacement);
                    die("too many AST lowering sites in one expression");
                }
                struct SafetyLoweringSite *site = &plan->site[plan->count++];
                site->start = node->start;
                site->end = end;
                site->replacement = xstrdup(replacement->text);
            }
            text_free(replacement);
        }
        collect_method_lowering_sites(node->lhs, plan);
        collect_method_lowering_sites(node->rhs, plan);
        collect_method_lowering_sites(node->child, plan);
    }
}

static void collect_s_string_method_sites(const char *source,
                                          struct SafetyLoweringPlan *plan)
{
    const char *p = source;

    while (*p != '\0') {
        if (p[0] == 's' && p[1] == '"') {
            struct Text *replacement = text_new();
            const char *end = NULL;
            if (try_rewrite_string_method(p, &end, replacement) && end != NULL) {
                if (plan->count >= MAX_SAFETY_LOWERINGS) {
                    text_free(replacement);
                    die("too many AST lowering sites in one expression");
                }
                struct SafetyLoweringSite *site = &plan->site[plan->count++];
                site->start = p;
                site->end = end;
                site->replacement = xstrdup(replacement->text);
                p = end;
                text_free(replacement);
                continue;
            }
            text_free(replacement);
        }
        p++;
    }
}

static void sort_lowering_sites(struct SafetyLoweringPlan *plan)
{
    int i;
    int j;

    for (i = 1; i < plan->count; i++) {
        struct SafetyLoweringSite value = plan->site[i];
        j = i;
        while (j > 0 &&
               (plan->site[j - 1].start > value.start ||
                (plan->site[j - 1].start == value.start &&
                 plan->site[j - 1].end < value.end))) {
            plan->site[j] = plan->site[j - 1];
            j--;
        }
        plan->site[j] = value;
    }
}

static void free_lowering_plan(struct SafetyLoweringPlan *plan)
{
    int i;
    for (i = 0; i < plan->count; i++) {
        free(plan->site[i].replacement);
    }
    plan->count = 0;
}

static struct Text *rewrite_method_calls(struct Text *in)
{
    const char *cursor = in->text;
    struct Text *out = text_new();
    struct SafetyExprNode *forest = safety_parse_forest(in->text);
    struct SafetyLoweringPlan plan;
    int i;
    int changed = 0;

    memset(&plan, 0, sizeof(plan));
    collect_method_lowering_sites(forest, &plan);
    collect_s_string_method_sites(in->text, &plan);
    sort_lowering_sites(&plan);
    for (i = 0; i < plan.count; i++) {
        struct SafetyLoweringSite *site = &plan.site[i];
        if (site->start < cursor || site->end <= site->start) {
            continue;
        }
        text_add_n(out, cursor, (size_t)(site->start - cursor));
        text_add(out, site->replacement);
        cursor = site->end;
        changed = 1;
    }
    text_add(out, cursor);

    if (!changed) {
        free_lowering_plan(&plan);
        safety_expr_free(forest);
        text_free(out);
        return in;
    }
    free_lowering_plan(&plan);
    safety_expr_free(forest);
    out->tail_return = in->tail_return;
    out->ast = in->ast;
    text_free(in);
    return rewrite_method_calls(out);
}

static int skip_unknown_field_error_for_tag(const char *tag)
{
    return strncmp(tag, "__CMinus", 8) == 0 ||
        strncmp(tag, "Vec_", 4) == 0 ||
        strncmp(tag, "List_", 5) == 0 ||
        strncmp(tag, "Map_", 4) == 0 ||
        strncmp(tag, "FixedVec_", 9) == 0 ||
        strncmp(tag, "Span_", 5) == 0 ||
        strncmp(tag, "Ref_", 4) == 0 ||
        strncmp(tag, "Optional_", 9) == 0 ||
        strncmp(tag, "OwnedVec_", 9) == 0 ||
        strncmp(tag, "OwnedList_", 10) == 0 ||
        strncmp(tag, "OwnedMap_", 9) == 0;
}

static struct Text *rewrite_auto_field_access(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    while (*p != '\0') {
        char name[NAME_MAX_LEN];
        const char *name_end;
        const char *scan;
        const char *dot;
        struct Symbol *sym;
        struct Type current;

        if (*p == '"' || *p == '\'') {
            char quote = *p;
            text_add_ch(out, *p++);
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    text_add_ch(out, *p++);
                    text_add_ch(out, *p++);
                    continue;
                }
                text_add_ch(out, *p);
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            text_add_ch(out, *p++);
            continue;
        }
        name_end = read_name(p, name);
        sym = symbol_find(name);
        if (sym == NULL || sym->type.kind != TY_STRUCT) {
            text_add_n(out, p, (size_t)(name_end - p));
            p = name_end;
            continue;
        }
        current = sym->type;
        scan = name_end;
        dot = skip_ws(scan);
        if (*dot != '.' && !(dot[0] == '-' && dot[1] == '>')) {
            text_add_n(out, p, (size_t)(name_end - p));
            p = name_end;
            continue;
        }
        text_add_n(out, p, (size_t)(name_end - p));
        while (*dot == '.' || (dot[0] == '-' && dot[1] == '>')) {
            const char *field_start = skip_ws(*dot == '.' ? dot + 1 : dot + 2);
            const char *field_end;
            const char *after_field;
            char field[NAME_MAX_LEN];
            struct Type field_type;

            text_add_n(out, scan, (size_t)(dot - scan));
            if (!is_ident_start((unsigned char)*field_start)) {
                text_add_n(out, dot, (size_t)((*dot == '.') ? 1 : 2));
                scan = (*dot == '.') ? dot + 1 : dot + 2;
                break;
            }
            field_end = read_name(field_start, field);
            after_field = skip_ws(field_end);
            if (*after_field == '(' || *after_field == '<') {
                text_add_n(out, dot, (size_t)(field_end - dot));
                scan = field_end;
                break;
            }
            if (current.kind != TY_STRUCT ||
                !struct_field_type(current.tag, field, &field_type)) {
                if (current.kind == TY_STRUCT && current.tag[0] != '\0' &&
                    !skip_unknown_field_error_for_tag(current.tag)) {
                    fprintf(stderr, "c-: type error: unknown field '%s' in struct %s\n", field, current.tag);
                    exit(1);
                }
                text_add_n(out, dot, (size_t)(field_end - dot));
                scan = field_end;
                break;
            }
            text_add(out, current.ptr > 0 ? "->" : ".");
            text_add_n(out, field_start, (size_t)(field_end - field_start));
            if ((*dot == '.' && current.ptr > 0) ||
                (dot[0] == '-' && dot[1] == '>' && current.ptr == 0)) {
                changed = 1;
            }
            current = field_type;
            scan = field_end;
            dot = skip_ws(scan);
        }
        p = scan;
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

static void append_collection_receiver(struct Text *out,
                                       struct Type receiver_type,
                                       const char *receiver_start,
                                       const char *receiver_end)
{
    if (receiver_type.ptr > 0) {
        text_add_n(out, receiver_start, (size_t)(receiver_end - receiver_start));
    } else {
        text_add_ch(out, '&');
        text_add_ch(out, '(');
        text_add_n(out, receiver_start, (size_t)(receiver_end - receiver_start));
        text_add_ch(out, ')');
    }
}

static int collection_index_call_expr(struct Type receiver_type,
                                      const char *receiver_start,
                                      const char *receiver_end,
                                      const char *index_start,
                                      const char *index_end,
                                      struct Text *replacement)
{
    struct GenericInstance *struct_inst = NULL;
    struct GenericTemplate *struct_tmpl;
    struct GenericTemplate *func_tmpl;
    struct GenericInstance *func_inst;
    struct PayloadEnum *option_en;
    struct GenericInstance *option_inst;
    char func_name[NAME_MAX_LEN];
    char tmp[128];
    int id;

    if (receiver_type.kind != TY_STRUCT) {
        return 0;
    }
    struct_tmpl = generic_struct_find_by_concrete(receiver_type.tag, &struct_inst);
    if (struct_tmpl == NULL || struct_inst == NULL) {
        return 0;
    }
    if (strcmp(struct_tmpl->name, "Span") == 0) {
        struct GenericTemplate *ptr_tmpl = generic_find(&g_generic_funcs, "Span_ptr_at");
        struct GenericInstance *ptr_inst;

        if (ptr_tmpl == NULL) {
            return 0;
        }
        ptr_inst = generic_instance_get(ptr_tmpl, struct_inst->arg);
        text_add(replacement, "(*");
        text_add(replacement, ptr_inst->concrete);
        text_add_ch(replacement, '(');
        append_collection_receiver(replacement, receiver_type, receiver_start, receiver_end);
        text_add(replacement, ", ");
        text_add_n(replacement, index_start, (size_t)(index_end - index_start));
        text_add(replacement, ", \"");
        text_add(replacement, g_input_path == NULL ? "<unknown>" : g_input_path);
        snprintf(tmp, sizeof(tmp), "\", %d))", yylineno);
        text_add(replacement, tmp);
        return 1;
    }
    if (strcmp(struct_tmpl->name, "Vec") != 0 &&
        strcmp(struct_tmpl->name, "List") != 0 &&
        strcmp(struct_tmpl->name, "FixedVec") != 0 &&
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
    append_collection_receiver(replacement, receiver_type, receiver_start, receiver_end);
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

static int collection_index_call(const char *name,
                                 const char *index_start,
                                 const char *index_end,
                                 struct Text *replacement)
{
    struct Symbol *sym = symbol_find(name);

    if (sym == NULL) {
        return 0;
    }
    return collection_index_call_expr(sym->type, name, name + strlen(name),
                                      index_start, index_end, replacement);
}

static int parse_field_receiver(const char *s,
                                const char **receiver_end,
                                struct Type *receiver_type)
{
    const char *p;
    const char *dot;
    char name[NAME_MAX_LEN];
    char field[NAME_MAX_LEN];
    struct Symbol *sym;

    if (!is_ident_start((unsigned char)*s)) {
        return 0;
    }
    p = read_name(s, name);
    sym = symbol_find(name);
    if (sym == NULL || sym->type.kind != TY_STRUCT) {
        return 0;
    }
    *receiver_type = sym->type;
    dot = skip_ws(p);
    while (*dot == '.' || (dot[0] == '-' && dot[1] == '>')) {
        const char *field_start = skip_ws(*dot == '.' ? dot + 1 : dot + 2);
        const char *field_end;
        const char *after_field;

        if (!is_ident_start((unsigned char)*field_start)) {
            return 0;
        }
        field_end = read_name(field_start, field);
        after_field = skip_ws(field_end);
        if (receiver_type->kind != TY_STRUCT ||
            !struct_field_type(receiver_type->tag, field, receiver_type)) {
            return 0;
        }
        if (*after_field == '[') {
            *receiver_end = field_end;
            return 1;
        }
        p = field_end;
        dot = skip_ws(p);
    }
    return 0;
}

static struct Text *rewrite_index_access(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    while (*p != '\0') {
        char name[NAME_MAX_LEN];
        const char *name_end;
        const char *receiver_start;
        const char *receiver_end;
        const char *open;
        const char *close;
        struct Type receiver_type;
        struct Text *replacement;

        if (*p == '"' || *p == '\'') {
            char quote = *p;
            text_add_ch(out, *p++);
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    text_add_ch(out, *p++);
                    text_add_ch(out, *p++);
                    continue;
                }
                if (*p == quote) {
                    text_add_ch(out, *p++);
                    break;
                }
                text_add_ch(out, *p++);
            }
            continue;
        }
        if (!is_ident_start((unsigned char)*p)) {
            text_add_ch(out, *p++);
            continue;
        }
        name_end = read_name(p, name);
        open = skip_ws(name_end);
        if (*open != '[') {
            if (!parse_field_receiver(p, &receiver_end, &receiver_type)) {
                text_add_n(out, p, (size_t)(name_end - p));
                p = name_end;
                continue;
            }
            receiver_start = p;
            open = skip_ws(receiver_end);
        } else {
            struct Symbol *sym = symbol_find(name);

            receiver_start = p;
            receiver_end = name_end;
            receiver_type = sym != NULL ? sym->type : type_unknown();
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
        if (collection_index_call_expr(receiver_type, receiver_start, receiver_end,
                                       open + 1, close, replacement)) {
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

static int span_symbol_info(const char *name,
                            struct Symbol **sym_out,
                            struct GenericInstance **inst_out)
{
    struct Symbol *sym = symbol_find(name);
    struct GenericInstance *inst = NULL;
    struct GenericTemplate *tmpl;

    if (sym == NULL || sym->type.kind != TY_STRUCT) {
        return 0;
    }
    tmpl = generic_struct_find_by_concrete(sym->type.tag, &inst);
    if (tmpl == NULL || inst == NULL || strcmp(tmpl->name, "Span") != 0) {
        return 0;
    }
    if (sym_out != NULL) {
        *sym_out = sym;
    }
    if (inst_out != NULL) {
        *inst_out = inst;
    }
    return 1;
}

static int previous_allows_unary(const char *start, const char *p)
{
    while (p > start && isspace((unsigned char)p[-1])) {
        p--;
    }
    if (p == start) {
        return 1;
    }
    return strchr("(=,{[!?:;+-*/%&|^~<>", p[-1]) != NULL;
}

static void append_span_receiver(struct Text *out, const char *name, struct Symbol *sym)
{
    if (sym->type.ptr > 0) {
        text_add(out, name);
    } else {
        text_add_ch(out, '&');
        text_add(out, name);
    }
}

static int span_offset_replacement(const char *name,
                                   const char *expr_start,
                                   const char *expr_end,
                                   int negative,
                                   struct Text *replacement)
{
    struct Symbol *sym = NULL;
    struct GenericInstance *inst = NULL;
    struct GenericTemplate *func_tmpl;
    struct GenericInstance *func_inst;
    char tmp[128];

    if (!span_symbol_info(name, &sym, &inst)) {
        return 0;
    }
    func_tmpl = generic_find(&g_generic_funcs, "Span_offset");
    if (func_tmpl == NULL) {
        return 0;
    }
    func_inst = generic_instance_get(func_tmpl, inst->arg);
    text_add(replacement, func_inst->concrete);
    text_add_ch(replacement, '(');
    append_span_receiver(replacement, name, sym);
    text_add(replacement, ", ");
    if (negative) {
        text_add(replacement, "-(");
        text_add_n(replacement, expr_start, (size_t)(expr_end - expr_start));
        text_add_ch(replacement, ')');
    } else {
        text_add_n(replacement, expr_start, (size_t)(expr_end - expr_start));
    }
    text_add(replacement, ", \"");
    text_add(replacement, g_input_path == NULL ? "<unknown>" : g_input_path);
    snprintf(tmp, sizeof(tmp), "\", %d)", yylineno);
    text_add(replacement, tmp);
    return 1;
}

static int span_deref_replacement(const char *name, struct Text *replacement)
{
    return collection_index_call(name, "0", "0" + 1, replacement);
}

static int span_incdec_replacement(const char *name, int delta, struct Text *replacement)
{
    char delta_buf[16];

    snprintf(delta_buf, sizeof(delta_buf), "%d", delta);
    text_add(replacement, name);
    text_add(replacement, " = ");
    return span_offset_replacement(name, delta_buf, delta_buf + strlen(delta_buf), 0, replacement);
}

static struct Text *rewrite_span_operators(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    while (*p != '\0') {
        if (*p == '"' || *p == '\'') {
            char quote = *p;
            text_add_ch(out, *p++);
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    text_add_ch(out, *p++);
                    text_add_ch(out, *p++);
                    continue;
                }
                if (*p == quote) {
                    text_add_ch(out, *p++);
                    break;
                }
                text_add_ch(out, *p++);
            }
            continue;
        }
        if (*p == '*' && previous_allows_unary(in->text, p)) {
            const char *name_start = skip_ws(p + 1);
            if (is_ident_start((unsigned char)*name_start)) {
                char name[NAME_MAX_LEN];
                const char *name_end = read_name(name_start, name);
                struct Text *replacement = text_new();

                if (span_deref_replacement(name, replacement)) {
                    text_add(out, replacement->text);
                    p = name_end;
                    changed = 1;
                    text_free(replacement);
                    continue;
                }
                text_free(replacement);
            }
        }
        if (is_ident_start((unsigned char)*p)) {
            char name[NAME_MAX_LEN];
            const char *name_end = read_name(p, name);
            const char *op = skip_ws(name_end);

            if ((*op == '+' || *op == '-') && op[1] == *op) {
                struct Text *replacement = text_new();

                if (span_incdec_replacement(name, *op == '+' ? 1 : -1, replacement)) {
                    text_add(out, replacement->text);
                    p = op + 2;
                    changed = 1;
                    text_free(replacement);
                    continue;
                }
                text_free(replacement);
            }
            if ((*op == '+' || *op == '-') && op[1] != *op && !(op[0] == '-' && op[1] == '>')) {
                const char *expr_start = skip_ws(op + 1);
                const char *expr_end = skip_divisor_expr(expr_start);
                struct Text *replacement = text_new();

                if (expr_end > expr_start &&
                    span_offset_replacement(name, expr_start, expr_end, *op == '-', replacement)) {
                    text_add(out, replacement->text);
                    p = expr_end;
                    changed = 1;
                    text_free(replacement);
                    continue;
                }
                text_free(replacement);
            }
            text_add_n(out, p, (size_t)(name_end - p));
            p = name_end;
            continue;
        }
        if ((*p == '+' || *p == '-') && p[1] == *p) {
            const char *name_start = skip_ws(p + 2);

            if (is_ident_start((unsigned char)*name_start)) {
                char name[NAME_MAX_LEN];
                const char *name_end = read_name(name_start, name);
                struct Text *replacement = text_new();

                if (span_incdec_replacement(name, *p == '+' ? 1 : -1, replacement)) {
                    text_add(out, replacement->text);
                    p = name_end;
                    changed = 1;
                    text_free(replacement);
                    continue;
                }
                text_free(replacement);
            }
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

static struct Text *rewrite_sizeof_types(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    while (*p != '\0') {
        if (*p == '"' || *p == '\'') {
            char quote = *p;
            text_add_ch(out, *p++);
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    text_add_ch(out, *p++);
                    text_add_ch(out, *p++);
                    continue;
                }
                if (*p == quote) {
                    text_add_ch(out, *p++);
                    break;
                }
                text_add_ch(out, *p++);
            }
            continue;
        }
        if (*p == '/' && p[1] == '/') {
            text_add(out, p);
            break;
        }
        if (*p == '/' && p[1] == '*') {
            text_add_ch(out, *p++);
            text_add_ch(out, *p++);
            while (*p != '\0') {
                if (*p == '*' && p[1] == '/') {
                    text_add_ch(out, *p++);
                    text_add_ch(out, *p++);
                    break;
                }
                text_add_ch(out, *p++);
            }
            continue;
        }
        if ((p == in->text || !is_ident((unsigned char)p[-1])) && starts_word(p, "sizeof")) {
            const char *open = skip_ws(p + 6);

            if (*open == '(') {
                const char *close = matching_paren(open);
                const char *inner;
                const char *inner_end;
                char name[NAME_MAX_LEN];
                enum TypeKind kind;

                if (close != NULL) {
                    inner = skip_ws(open + 1);
                    inner_end = close;
                    while (inner_end > inner && isspace((unsigned char)inner_end[-1])) {
                        inner_end--;
                    }
                    if (is_ident_start((unsigned char)*inner) &&
                        read_name(inner, name) == inner_end &&
                        (kind = tag_kind_find(name)) != TY_UNKNOWN) {
                        text_add(out, "sizeof(");
                        text_add(out, type_kind_name(kind));
                        text_add_ch(out, ' ');
                        text_add(out, name);
                        text_add_ch(out, ')');
                        p = close + 1;
                        changed = 1;
                        continue;
                    }
                }
            }
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

static const char *skip_divisor_primary(const char *p)
{
    const char *start;

    p = skip_ws(p);
    while (*p == '+' || *p == '-' || *p == '!' || *p == '~' || *p == '*' || *p == '&') {
        p++;
        p = skip_ws(p);
    }
    if (*p == '(') {
        const char *close = matching_paren(p);
        return close == NULL ? p + 1 : close + 1;
    }
    start = p;
    if (is_ident_start((unsigned char)*p)) {
        char name[NAME_MAX_LEN];
        p = read_name(p, name);
        if (*skip_ws(p) == '(') {
            const char *open = skip_ws(p);
            const char *close = matching_paren(open);
            if (close != NULL) {
                p = close + 1;
            }
        }
    } else if (isdigit((unsigned char)*p) || *p == '.') {
        while (isalnum((unsigned char)*p) || *p == '.' || *p == '_' || *p == 'x' || *p == 'X') {
            p++;
        }
    } else if (*p != '\0') {
        p++;
    }
    if (p == start && *p != '\0') {
        p++;
    }
    return p;
}

static const char *skip_divisor_expr(const char *p)
{
    p = skip_divisor_primary(p);
    for (;;) {
        const char *q = skip_ws(p);
        if (q[0] == '-' && q[1] == '>' && is_ident_start((unsigned char)q[2])) {
            char name[NAME_MAX_LEN];
            p = read_name(q + 2, name);
            continue;
        }
        if (*q == '.' && is_ident_start((unsigned char)q[1])) {
            char name[NAME_MAX_LEN];
            p = read_name(q + 1, name);
            continue;
        }
        if (*q == '[') {
            int depth = 1;
            q++;
            while (*q != '\0' && depth > 0) {
                if (*q == '"' || *q == '\'') {
                    char quote = *q++;
                    while (*q != '\0') {
                        if (*q == '\\' && q[1] != '\0') {
                            q += 2;
                            continue;
                        }
                        if (*q++ == quote) {
                            break;
                        }
                    }
                    continue;
                }
                if (*q == '[') {
                    depth++;
                } else if (*q == ']') {
                    depth--;
                }
                q++;
            }
            p = q;
            continue;
        }
        if (*q == '(') {
            const char *close = matching_paren(q);
            if (close == NULL) {
                return p;
            }
            p = close + 1;
            continue;
        }
        return p;
    }
}

static struct Text *rewrite_division_checks(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    if (strncmp(g_current_function_name, "cminus_", 7) == 0 ||
        strncmp(g_current_function_name, "__cminus", 8) == 0 ||
        strncmp(g_current_function_name, "__CMinus", 8) == 0) {
        text_free(out);
        return in;
    }
    while (*p != '\0') {
        if (*p == '"' || *p == '\'') {
            char quote = *p;
            text_add_ch(out, *p++);
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    text_add_ch(out, *p++);
                    text_add_ch(out, *p++);
                    continue;
                }
                if (*p == quote) {
                    text_add_ch(out, *p++);
                    break;
                }
                text_add_ch(out, *p++);
            }
            continue;
        }
        if (*p == '/' && p[1] == '/') {
            text_add(out, p);
            break;
        }
        if (*p == '/' && p[1] == '*') {
            text_add_ch(out, *p++);
            text_add_ch(out, *p++);
            while (*p != '\0') {
                if (*p == '*' && p[1] == '/') {
                    text_add_ch(out, *p++);
                    text_add_ch(out, *p++);
                    break;
                }
                text_add_ch(out, *p++);
            }
            continue;
        }
        if ((*p == '/' || *p == '%') && p[1] != '=') {
            const char *divisor_start = skip_ws(p + 1);
            const char *divisor_end = skip_divisor_expr(divisor_start);
            int id;
            char tmp[128];

            if (divisor_end <= divisor_start) {
                text_add_ch(out, *p++);
                continue;
            }
            id = g_right_value_id++;
            text_add_ch(out, *p);
            text_add(out, " ({ __auto_type ");
            snprintf(tmp, sizeof(tmp), "__divisor%d", id);
            text_add(out, tmp);
            text_add(out, " = (");
            text_add_n(out, divisor_start, (size_t)(divisor_end - divisor_start));
            text_add(out, "); if (");
            text_add(out, tmp);
            text_add(out, " == 0) { cminus_panic(\"division by zero\", \"");
            text_add(out, g_input_path == NULL ? "<unknown>" : g_input_path);
            snprintf(tmp, sizeof(tmp), "\", %d); } __divisor%d; })", yylineno, id);
            text_add(out, tmp);
            p = divisor_end;
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

static struct Symbol *symbol_find_or_current_param(const char *name)
{
    struct Symbol *sym = symbol_find(name);
    static struct Symbol param_sym;
    struct FunctionParams *fn;
    int pindex;

    if (sym != NULL || g_current_function_name[0] == '\0') {
        return sym;
    }
    fn = function_params_find(g_current_function_name);
    if (fn == NULL) {
        return NULL;
    }
    pindex = param_index(fn, name);
    if (pindex < 0) {
        return NULL;
    }
    memset(&param_sym, 0, sizeof(param_sym));
    strncpy(param_sym.name, name, NAME_MAX_LEN - 1);
    param_sym.name[NAME_MAX_LEN - 1] = '\0';
    param_sym.type = fn->param[pindex].type;
    return &param_sym;
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
            if (g_unsafe_depth == 0 && expr_is_raw_pointer_input(values[i]->text, values[i]->text + values[i]->len)) {
                fprintf(stderr, "c-: type error: raw pointer taint cannot be passed to function '%s' in safe mode; use unsafe or a managed safe wrapper\n",
                        fn->name);
                exit(1);
            }
            if (rhs_is_null_literal(values[i]->text)) {
                if (!type_is_optional(fn->param[i].type)) {
                    fprintf(stderr, "c-: type error: NULL argument for parameter '%s' in function '%s' is only allowed for Optional in safe mode\n",
                            fn->param[i].name, fn->name);
                    exit(1);
                }
                append_optional_none_expr(out, fn->param[i].type);
            } else {
                text_add(out, values[i]->text);
            }
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

static int args_contain_raw_pointer_input(const char *args_start, const char *args_end)
{
    const char *p = args_start;

    while (p < args_end) {
        const char *arg_end = find_top_level_char(p, args_end, ',');
        if (arg_end == NULL) {
            arg_end = args_end;
        }
        if (expr_is_raw_pointer_input(p, arg_end)) {
            return 1;
        }
        p = arg_end;
        if (p < args_end && *p == ',') {
            p++;
        }
    }
    return 0;
}

static int is_safe_stdlib_function_name(const char *name)
{
    static const char *prefixes[] = {
        "Vec_", "List_", "Map_", "OwnedVec_", "OwnedList_", "OwnedMap_",
        "Optional_", "Ref_", "Span_", "FixedVec_", "RingBuffer_",
        "Bitmap_", "Register_", "Volatile_", "StaticCell_", "Atomic_",
        "Critical_", "Iterator_", NULL
    };
    int i;

    for (i = 0; prefixes[i] != NULL; i++) {
        if (strncmp(name, prefixes[i], strlen(prefixes[i])) == 0) {
            return 1;
        }
    }
    return 0;
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
                    if (g_unsafe_depth == 0 && fn->is_unsafe &&
                        strncmp(name, "cminus_", 7) != 0 &&
                        strncmp(name, "__cminus", 8) != 0 &&
                        !is_safe_stdlib_function_name(name)) {
                        fprintf(stderr, "c-: type error: unsafe function '%s' can only be called inside unsafe\n",
                                name);
                        exit(1);
                    }
                    if (!fn->has_defaults && !args_contain_top_level_null(open + 1, close) &&
                        !args_contain_raw_pointer_input(open + 1, close)) {
                        text_add_n(out, p, (size_t)(close + 1 - p));
                        p = close + 1;
                        continue;
                    }
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
        append_s_string_format_for_quote(prefix, tmp, quote_start, "");
        if (prefix->len > 0 && prefix->text[prefix->len - 1] == '\n') {
            prefix->text[--prefix->len] = '\0';
            text_add_ch(prefix, ' ');
        }
        text_add(suffix, "cminus_gc_free(");
        text_add(suffix, tmp);
        text_add(suffix, "); ");
        cursor = after;
        count++;
    }
    text_add_n(rewritten, cursor, (size_t)(end - cursor));
    cursor = rewritten->text;
    {
        struct Text *owned_rewritten = text_new();
        while (*cursor != '\0') {
            const char *call_start;
            const char *call_end;
            struct Type type;
            char tmp[NAME_MAX_LEN];

            if (!find_owned_return_call(cursor, &call_start, &call_end, &type)) {
                text_add(owned_rewritten, cursor);
                break;
            }
            snprintf(tmp, sizeof(tmp), "__right_value%d", g_right_value_id++);
            text_add_n(owned_rewritten, cursor, (size_t)(call_start - cursor));
            text_add(owned_rewritten, tmp);

            append_c_type(prefix, type);
            text_add_ch(prefix, ' ');
            text_add(prefix, tmp);
            text_add(prefix, " = ");
            text_add_n(prefix, call_start, (size_t)(call_end - call_start));
            text_add(prefix, "; ");

            append_release_pointer(suffix, "", tmp, type);

            cursor = call_end;
            count++;
        }
        text_free(rewritten);
        rewritten = owned_rewritten;
    }
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
    text_add(out, " = (");
    text_add(out, rewritten->text);
    text_add(out, ") != 0; ");
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
    char func_name[NAME_MAX_LEN];

    if (!text_has_s_string(head->text) && !rhs_has_malloc_call(head->text, func_name)) {
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
    if (g_c_compat && g_unsafe_depth == 0) {
        head->ast = ast_raw(kind, head->text);
        return head;
    }
    check_safe_pointer_deref(head->text);
    check_casts(head->text);
    check_safe_heap_calls(head->text);
    check_no_heap_safe_expr(head->text);
    check_safe_raw_field_access(head->text);
    check_moved_local_use(head->text);
    check_dead_borrow_use(head->text);
    head = rewrite_generics(head);
    check_safe_pointer_decl(head->text);
    head = rewrite_method_calls(head);
    head = rewrite_inferred_array_from_calls(head);
    check_safe_c_function_calls(head->text);
    check_no_heap_safe_expr(head->text);
    check_safe_reference_raw_inputs(head->text);
    check_safe_raw_field_access(head->text);
    check_safe_array_index_access(head->text);
    head = rewrite_auto_field_access(head);
    head = rewrite_span_operators(head);
    head = rewrite_sizeof_types(head);
    head = rewrite_index_access(head);
    head = rewrite_parameter_calls(head);
    check_safe_reference_raw_inputs(head->text);
    check_null_arguments(head->text);
    head = rewrite_division_checks(head);
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
        text_add_ch(out, in->text[i]);
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

static void append_stack_leave(struct Text *out, const char *indent)
{
    text_add(out, indent);
    text_add(out, "cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);\n");
}

static void append_stack_enter(struct Text *out, const char *indent)
{
    text_add(out, indent);
    text_add(out, "char __cminus_stack_anchor;\n");
    text_add(out, indent);
    text_add(out, "size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);\n");
}

static struct Text *rewrite_returns_with_stack_leave(struct Text *in)
{
    const char *p = in->text;
    struct Text *out = text_new();
    int changed = 0;

    while (*p != '\0') {
        if (*p == '"' || *p == '\'') {
            char quote = *p;
            text_add_ch(out, *p++);
            while (*p != '\0') {
                if (*p == '\\' && p[1] != '\0') {
                    text_add_ch(out, *p++);
                    text_add_ch(out, *p++);
                    continue;
                }
                text_add_ch(out, *p);
                if (*p++ == quote) {
                    break;
                }
            }
            continue;
        }
        if (starts_word(p, "return")) {
            text_add(out, "cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);\n    ");
            text_add(out, "return");
            p += 6;
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
    text_free(in);
    return out;
}

static int clone_uses_managed_heap(const char *tag)
{
    return strncmp(tag, "__CMinus", 8) != 0;
}

static int payload_type_has_pointer(const char *payload)
{
    return payload != NULL && strchr(payload, '*') != NULL;
}

static int head_function_name(const char *head, char *name)
{
    const char *open = strrchr(head, '(');
    const char *p;
    const char *end;

    if (open == NULL) {
        return 0;
    }
    p = open;
    while (p > head && isspace((unsigned char)p[-1])) {
        p--;
    }
    end = p;
    while (p > head && is_ident((unsigned char)p[-1])) {
        p--;
    }
    if (p == end) {
        return 0;
    }
    if ((size_t)(end - p) >= NAME_MAX_LEN) {
        return 0;
    }
    memcpy(name, p, (size_t)(end - p));
    name[end - p] = '\0';
    return 1;
}

static int function_signature_is_internal(const char *head)
{
    static const char *needles[] = {
        "__cminus_",
        "__CMinus",
        "__addvsi3(",
        "__subvsi3(",
        "__mulvsi3(",
        "__addvdi3(",
        "__subvdi3(",
        "__mulvdi3(",
        "cminus_",
        "Ref_",
        "Span_",
        "FixedVec_",
        "RingBuffer_",
        "Register_",
        "Atomic_",
        "Volatile_",
        "StaticCell_",
        "Bitmap_",
        "Critical_",
        "Iterator_",
        "Vec_",
        "VecIterator_",
        "List_",
        "ListIterator_",
        "Map_",
        "OwnedVec_",
        "OwnedList_",
        "OwnedMap_",
        "__CMinusIndex_",
        "Optional_",
        NULL
    };
    int i;

    for (i = 0; needles[i] != NULL; i++) {
        if (strstr(head, needles[i]) != NULL) {
            return 1;
        }
    }
    return 0;
}

static int type_is_nonowning_value_view(struct Type type)
{
    return type.kind == TY_STRUCT && type.ptr == 0 &&
        (strcmp(type.tag, "Ref") == 0 ||
         strncmp(type.tag, "Ref_", 4) == 0 ||
         strncmp(type.tag, "Optional_", 9) == 0 ||
         strcmp(type.tag, "Register") == 0 ||
         strncmp(type.tag, "Register_", 9) == 0 ||
         strcmp(type.tag, "Atomic") == 0 ||
         strncmp(type.tag, "Atomic_", 7) == 0 ||
         strcmp(type.tag, "Volatile") == 0 ||
         strncmp(type.tag, "Volatile_", 9) == 0 ||
         strcmp(type.tag, "StaticCell") == 0 ||
         strncmp(type.tag, "StaticCell_", 11) == 0 ||
         strcmp(type.tag, "Bitmap") == 0 ||
         strcmp(type.tag, "Critical") == 0 ||
         strcmp(type.tag, "Thread") == 0 ||
         strcmp(type.tag, "Mutex") == 0 ||
         strcmp(type.tag, "Cond") == 0 ||
         strcmp(type.tag, "Span") == 0 ||
         strncmp(type.tag, "Span_", 5) == 0 ||
         strcmp(type.tag, "FixedVec") == 0 ||
         strncmp(type.tag, "FixedVec_", 9) == 0 ||
         strcmp(type.tag, "RingBuffer") == 0 ||
         strncmp(type.tag, "RingBuffer_", 11) == 0);
}

static int parse_cast_type_prefix(const char *s, const char *end, const char **after)
{
    const char *p = skip_ws(s);
    const char *base_end;
    struct Type type;

    if (!parse_new_type_prefix(p, &base_end, &type)) {
        return 0;
    }
    p = base_end;
    while (p < end && (*p == '*' || *p == '%')) {
        p++;
    }
    while (p < end && isspace((unsigned char)*p)) {
        p++;
    }
    if (after != NULL) {
        *after = p;
    }
    return p == end;
}

static int paren_is_type_query_arg(const char *start, const char *open)
{
    const char *end = open;
    const char *word;
    size_t len;

    while (end > start && isspace((unsigned char)end[-1])) {
        end--;
    }
    word = end;
    while (word > start && is_ident((unsigned char)word[-1])) {
        word--;
    }
    if (word == end) {
        return 0;
    }
    len = (size_t)(end - word);
    if (word > start && is_ident((unsigned char)word[-1])) {
        return 0;
    }
    return (len == 6 && strncmp(word, "sizeof", 6) == 0) ||
        (len == 8 && strncmp(word, "_Alignof", 8) == 0) ||
        (len == 7 && strncmp(word, "alignof", 7) == 0);
}

static void check_casts(const char *text)
{
    const char *p = text;
    int in_str = 0;
    int in_chr = 0;

    if (g_unsafe_depth > 0) {
        return;
    }
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
        if (*p == '/' && p[1] == '/') {
            break;
        }
        if (*p == '/' && p[1] == '*') {
            p += 2;
            while (*p != '\0' && !(*p == '*' && p[1] == '/')) {
                p++;
            }
            if (*p != '\0') {
                p += 2;
            }
            continue;
        }
        if (*p == '(') {
            const char *close = matching_paren(p);
            const char *after;
            const char *q;
            int reject = 0;

            if (close != NULL) {
                q = p + 1;
                while (q < close) {
                    if (*q == '.' || *q == '[' || *q == ']' || *q == '{' || *q == '}' || *q == ';') {
                        reject = 1;
                        break;
                    }
                    q++;
                }
            }
            if (close != NULL && !reject && !paren_is_type_query_arg(text, p) &&
                parse_cast_type_prefix(p + 1, close, &after) && after == close) {
                fprintf(stderr, "c-: type error: cast is only allowed inside unsafe near `");
                fwrite(p, 1, (size_t)(close - p + 1), stderr);
                fprintf(stderr, "`\n");
                exit(1);
            }
        }
        p++;
    }
}

static int function_needs_stack_guard(const char *name)
{
    static const char *skip_prefixes[] = {
        "__cminus_",
        "cminus_",
        "Ref_",
        "Span_",
        "FixedVec_",
        "RingBuffer_",
        "Register_",
        "Atomic_",
        "Volatile_",
        "StaticCell_",
        "Bitmap_",
        "Critical_",
        "Vec_",
        "List_",
        "Map_",
        "OwnedVec_",
        "OwnedList_",
        "OwnedMap_",
        "__CMinusIndex_",
        "Optional_",
        NULL
    };
    int i;

    if (name == NULL || name[0] == '\0') {
        return 1;
    }
    for (i = 0; skip_prefixes[i] != NULL; i++) {
        size_t n = strlen(skip_prefixes[i]);
        if (strncmp(name, skip_prefixes[i], n) == 0) {
            return 0;
        }
    }
    return 1;
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
    text_add(out, "cminus_gc_free(");
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

static void append_struct_clone_field(struct Text *out, struct Type type, const char *field_name, int index, int is_array)
{
    struct Text *expr = text_new();

    text_add(expr, "self->");
    text_add(expr, field_name);
    if (is_array) {
        text_add(out, "    memcpy(copy->");
        text_add(out, field_name);
        text_add(out, ", ");
        text_add(out, expr->text);
        text_add(out, ", sizeof(copy->");
        text_add(out, field_name);
        text_add(out, "));\n");
    } else if (type_is_nonowning_value_view(type)) {
        text_add(out, "    copy->");
        text_add(out, field_name);
        text_add(out, " = ");
        text_add(out, expr->text);
        text_add(out, ";\n");
    } else if (type.kind == TY_STRUCT && type.ptr == 0) {
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
            text_add(out, clone_uses_managed_heap(type.tag) ? "            cminus_gc_free(" : "            free(");
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
            text_add(out, clone_uses_managed_heap(type.tag) ? " = cminus_gc_calloc(strlen(" : " = calloc(strlen(");
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
            text_add(out, clone_uses_managed_heap(type.tag) ? "cminus_gc_calloc(1, sizeof(" : "calloc(1, sizeof(");
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
    text_add(out, "* copy = ");
    text_add(out, clone_uses_managed_heap(clone->tag) ? "cminus_gc_calloc(1, sizeof(struct " : "calloc(1, sizeof(struct ");
    text_add(out, clone->tag);
    text_add(out, "));\n");
    text_add(out, "    if (copy == NULL || self == NULL) {\n");
    text_add(out, "        return copy;\n");
    text_add(out, "    }\n");
    for (i = 0; i < clone->count; i++) {
        append_struct_clone_field(out, clone->fields[i].type, clone->fields[i].name, i, clone->fields[i].is_array);
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
    struct Text *normalized_lhs = text_new();
    char tmp[NAME_MAX_LEN];

    snprintf(tmp, sizeof(tmp), "__owned_old%d", g_right_value_id++);
    text_add(normalized_lhs, lhs_expr);
    normalized_lhs = rewrite_auto_field_access(normalized_lhs);
    append_indent_from(original, indent);
    text_add(out, indent->text);
    text_add(out, "void* ");
    text_add(out, tmp);
    text_add(out, " = ");
    text_add(out, normalized_lhs->text);
    text_add(out, ";\n");
    text_add(out, stmt->text);
    text_add_ch(out, '\n');
    append_release_pointer(out, indent->text, tmp, type);
    text_add_ch(out, '\n');
    out->tail_return = stmt->tail_return;
    out->ast = stmt->ast;
    text_free(indent);
    text_free(normalized_lhs);
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

static const char *skip_safe_deref_trivia(const char *p)
{
    while (1) {
        p = skip_ws(p);
        if (p[0] == '/' && p[1] == '*') {
            const char *close = strstr(p + 2, "*/");

            if (close == NULL) {
                return p;
            }
            p = close + 2;
            continue;
        }
        if (p[0] == '/' && p[1] == '/') {
            const char *newline = strchr(p + 2, '\n');

            if (newline == NULL) {
                return p + strlen(p);
            }
            p = newline + 1;
            continue;
        }
        return p;
    }
}

static int safety_identifier_is_span(const struct SafetyExprNode *node)
{
    const struct SafetyExprNode *base = safety_unwrap_group(node);
    struct Symbol *sym;
    struct GenericInstance *inst = NULL;
    struct GenericTemplate *tmpl = NULL;

    if (base == NULL || base->kind != SAFETY_EXPR_IDENTIFIER) {
        return 0;
    }
    sym = symbol_find_or_current_param(base->name);
    if (sym == NULL) {
        return 0;
    }
    if (sym->type.kind == TY_STRUCT) {
        tmpl = generic_struct_find_by_concrete(sym->type.tag, &inst);
    }
    return (tmpl != NULL && strcmp(tmpl->name, "Span") == 0) ||
        strncmp(sym->type.tag, "Span_", 5) == 0 ||
        strcmp(sym->type.tag, "Span") == 0;
}

static int safety_node_is_raw_pointer(const struct SafetyExprNode *node, char name[NAME_MAX_LEN])
{
    const struct SafetyExprNode *base = safety_unwrap_group(node);
    struct Symbol *sym;

    while (base != NULL && base->kind == SAFETY_EXPR_MEMBER) {
        base = safety_unwrap_group(base->lhs);
    }
    if (base == NULL || base->kind != SAFETY_EXPR_IDENTIFIER) {
        return 0;
    }
    sym = symbol_find_or_current_param(base->name);
    if (sym == NULL || !sym->type.raw_ptr) {
        return 0;
    }
    strncpy(name, base->name, NAME_MAX_LEN - 1);
    name[NAME_MAX_LEN - 1] = '\0';
    return 1;
}

static void validate_safe_deref_node(const struct SafetyExprNode *node,
                                     const struct SafetyExprNode *parent,
                                     void *context)
{
    char name[NAME_MAX_LEN];
    (void)parent;
    (void)context;

    if (node->kind == SAFETY_EXPR_UNARY_DEREF) {
        const struct SafetyExprNode *operand = safety_unwrap_group(node->lhs);
        if (safety_identifier_is_span(operand)) {
            return;
        }
        if (operand != NULL && operand->kind == SAFETY_EXPR_IDENTIFIER) {
            fprintf(stderr, "c-: type error: pointer dereference is only allowed inside unsafe for expression near '%s'\n",
                    operand->name);
        } else {
            fprintf(stderr, "c-: type error: pointer dereference is only allowed inside unsafe\n");
        }
        exit(1);
    }
    if (node->kind == SAFETY_EXPR_INDEX &&
        safety_node_is_raw_pointer(node->lhs, name)) {
        fprintf(stderr, "c-: type error: raw pointer dereference is only allowed inside unsafe for pointer '%s'\n",
                name);
        exit(1);
    }
    if (node->kind == SAFETY_EXPR_MEMBER && strcmp(node->op, "->") == 0 &&
        safety_node_is_raw_pointer(node->lhs, name)) {
        fprintf(stderr, "c-: type error: raw pointer dereference is only allowed inside unsafe for pointer '%s'\n",
                name);
        exit(1);
    }
}

static void check_safe_pointer_deref(const char *stmt)
{
    struct SafetyExprNode *forest;

    if (g_unsafe_depth > 0) {
        return;
    }
    forest = safety_parse_forest(stmt);
    safety_expr_walk(forest, NULL, validate_safe_deref_node, NULL);
    safety_expr_free(forest);
}

static int is_unsafe_head(const char *s)
{
    const char *p = skip_ws(s);

    return strncmp(p, "unsafe", 6) == 0 && !is_ident((unsigned char)p[6]) &&
        *skip_ws(p + 6) == '\0';
}

static int is_inline_c_head(const char *s)
{
    const char *p = skip_ws(s);
    const char *q;

    if (strncmp(p, "inline", 6) != 0 || is_ident((unsigned char)p[6])) {
        return 0;
    }
    q = skip_ws(p + 6);
    return q != p + 6 &&
        strncmp(q, "c", 1) == 0 && !is_ident((unsigned char)q[1]) &&
        *skip_ws(q + 1) == '\0';
}

void cminus_unsafe_push(void)
{
    g_unsafe_depth++;
}

void cminus_unsafe_pop(void)
{
    if (g_unsafe_depth > 0) {
        g_unsafe_depth--;
    }
}

static struct Text *wrap_transparent_boundary(struct Text *body,
                                              enum NodeKind kind)
{
    struct Node *node = ast_new(kind, body->text);
    struct Text *out = text_new();

    node->body = body->ast;
    out->ast = node;
    ast_emit_node(out, node);
    body->ast = NULL;
    text_free(body);
    return out;
}

static struct Text *normalize_raw_c_block_body(struct Text *body)
{
    struct Text *out = text_new();
    struct Node *node;

    if (body->len > 0 && body->text[0] != '\n') {
        text_add_ch(out, '\n');
    }
    text_add(out, body->text);
    if (out->len > 0 && out->text[out->len - 1] != '\n') {
        text_add_ch(out, '\n');
    }
    node = ast_new(ND_INLINE_C, out->text);
    out->ast = node;
    body->ast = NULL;
    text_free(body);
    return out;
}

static void begin_stmt_block(struct Text *head)
{
    if (is_unsafe_head(head->text) || is_inline_c_head(head->text)) {
        g_unsafe_depth++;
    }
}

static struct Text *finish_stmt_block(struct Text *head, struct Text *lb, struct Text *body, struct Text *rb)
{
    struct Text *out;
    struct Type function_ret;
    char function_name[NAME_MAX_LEN];

    if (is_unsafe_head(head->text)) {
        struct Text *joined;

        register_unsafe_metadata(body->text);
        joined = text_join3(lb, body, rb);
        out = wrap_transparent_boundary(joined, ND_UNSAFE);
        if (g_unsafe_depth > 0) {
            g_unsafe_depth--;
        }
        text_free(head);
        return out;
    }
    if (is_inline_c_head(head->text)) {
        out = normalize_raw_c_block_body(body);
        if (g_unsafe_depth > 0) {
            g_unsafe_depth--;
        }
        text_free(head);
        text_free(lb);
        text_free(rb);
        return out;
    }
    /* A top-level unsafe boundary is parsed with the compound-item grammar.
       Recover function definitions here instead of treating their braces as
       an opaque aggregate block.  Their bodies remain under ND_UNSAFE, while
       the final AST pass can rebuild parameter and local scopes normally. */
    if (g_unsafe_depth > 0 &&
        parse_function_signature(head->text, function_name, &function_ret)) {
        struct Node *function_ast;

        register_function_params(head->text);
        function_ast = ast_function(head->text, body->ast);
        body->ast = NULL;
        out = text_join3(head, lb, body);
        out = text_join(out, rb);
        out->ast = function_ast;
        return out;
    }
    head = process_control_head(head);
    {
        struct Node *control;

        if (ast_control_kind(head->text) == ND_RAW) {
            control = ast_aggregate(head->text, lb->text, body->text,
                                    rb->text, body->ast);
        } else {
            control = ast_control(head->text, lb->text, body->text,
                                  rb->text, body->ast);
            validate_safe_control_ast(control);
        }

        out = text_new();
        out->ast = control;
        ast_emit_node(out, control);
        head->ast = NULL;
        body->ast = NULL;
        text_free(head);
        text_free(lb);
        text_free(body);
        text_free(rb);
    }
    return out;
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

    all = rewrite_linker_symbol_decl(all);
    if (parse_linker_symbol_decl(all->text, func_name)) {
        return all;
    }
    if (is_uniq_decl(all->text)) {
        if (!g_emit_uniq) {
            return uniq_extern_decl(all);
        }
        all = strip_uniq(all);
    }
    register_tags_in_text(all->text);
    if (!is_generic_decl_head(all->text)) {
        all = rewrite_generics(all);
        all = rewrite_safe_reference_decl(all);
    }
    memset(&info, 0, sizeof(info));
    if (parse_decl(all->text, &info) && info.is_typedef &&
        info.name[0] != '\0') {
        typedef_alias_add(info.name, info.type);
    }
    is_func_sig = parse_function_signature(all->text, func_name, &ret);
    if (is_func_sig) {
        if (g_unsafe_depth == 0 && !g_c_compat &&
            text_has_word(all->text, "extern") &&
            !function_signature_is_internal(all->text)) {
            fprintf(stderr, "c-: type error: extern functions must be declared inside unsafe at %s:%d; expose a checked safe wrapper after validating all inputs and outputs\n",
                    g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
        if (g_unsafe_depth == 0 && !g_c_compat && strstr(all->text, "...") != NULL &&
            !function_signature_is_internal(all->text)) {
            fprintf(stderr, "c-: type error: variadic functions are only allowed inside unsafe at %s:%d; expose a typed safe wrapper\n",
                    g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
        validate_interrupt_function_head(all->text);
        register_function_params(all->text);
        register_owned_function_signature(all->text);
        register_malloc_attribute_function(all->text);
    }
    if (!is_func_sig && parse_decl(all->text, &info) && info.name[0] != '\0' &&
        !info.is_function && !info.is_typedef) {
        if (g_unsafe_depth == 0 && type_is_atomic_value(info.type) &&
            !type_is_thread_atomic(info.type)) {
            fprintf(stderr, "c-: type error: Atomic value '%s' requires a non-pointer integer, enum, or bitflags payload in safe mode at %s:%d\n",
                    info.name, g_input_path == NULL ? "<unknown>" : g_input_path,
                    yylineno);
            exit(1);
        }
        if (g_unsafe_depth == 0 && type_is_stored_safe_reference(info.type)) {
            fprintf(stderr, "c-: type error: Ref/Span values cannot be stored in safe global '%s' at %s:%d; store owned/static data and create the reference locally\n",
                    info.name, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
        symbol_add_to(&g_globals, info.name, info.type);
    }
    if (info.is_typedef && info.name[0] != '\0') {
        struct Node *typedef_node = ast_new(ND_TYPEDEF, all->text);

        strncpy(typedef_node->name, info.name, NAME_MAX_LEN - 1);
        typedef_node->name[NAME_MAX_LEN - 1] = '\0';
        typedef_node->ty = type_copy(info.type);
        typedef_node->type_node = ast_type_node(info.type);
        all->ast = typedef_node;
    } else {
        all->ast = ast_raw(ND_DECL, all->text);
    }
    if (is_func_sig) {
        all = strip_default_parameters(all);
        all = rewrite_interrupt_function_head(all);
    }
    all = rewrite_os_attributes(all);
    all = rewrite_sizeof_types(all);
    all = rewrite_compile_time_os_ops(all);
    all = rewrite_linker_address_ops(all);
    all = rewrite_alignment_calls(all);
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
    int owned_rvalue_call = 0;
    int is_borrowed = 0;
    char moved_name[NAME_MAX_LEN];
    char borrow_owner[NAME_MAX_LEN];

    post_free_name[0] = '\0';
    owned_name[0] = '\0';
    func_name[0] = '\0';
    lhs_name[0] = '\0';
    moved_name[0] = '\0';
    borrow_owner[0] = '\0';
    post_free_type = type_unknown();
    owned_assign_type = type_unknown();
    new_type = type_unknown();
    pending_semantics_capture_statement(all->text);
    if (g_current_generic_kind != 0 || g_current_payload_enum) {
        all->tail_return = 0;
        all->ast = ast_raw(ND_RAW, all->text);
        return all;
    }
    if (parse_decl(all->text, &decl) && decl.is_decl &&
        decl.name[0] != '\0' && !decl.is_function &&
        decl.type.applied_name[0] != '\0') {
        symbol_add(decl.name, decl.type);
    }
    if (g_c_compat && g_unsafe_depth == 0 && g_in_function) {
        if (parse_decl(all->text, &decl) && decl.is_decl && decl.name[0] != '\0' && !decl.is_function) {
            symbol_add(decl.name, decl.type);
        }
        all->tail_return = 0;
        all->ast = ast_raw(eq >= 0 ? ND_ASSIGN : ND_EXPR_STMT, all->text);
        all = rewrite_os_attributes(all);
        all = rewrite_sizeof_types(all);
        all = rewrite_compile_time_os_ops(all);
        all = rewrite_linker_address_ops(all);
        all = rewrite_alignment_calls(all);
        return remove_percent(all);
    }
    all = try_rewrite_auto_payload_enum_decl(all);
    register_tags_in_text(all->text);
    all = rewrite_generics(all);
    all = rewrite_safe_reference_decl(all);
    eq = find_assignment(all->text);
    register_tags_in_text(all->text);
    all = rewrite_payload_enum_constructors(all);
    all = rewrite_optional_null_assignment(all);
    eq = find_assignment(all->text);
    if (g_unsafe_depth == 0 && eq >= 0) {
        char resource_source[NAME_MAX_LEN];
        struct Symbol *source_symbol = NULL;
        struct Type destination_type = type_unknown();
        const char *rhs = all->text + eq + 1;

        if (extract_plain_name_expr(rhs, resource_source)) {
            source_symbol = symbol_find(resource_source);
        }
        if (source_symbol != NULL &&
            (type_is_runtime_resource_value(source_symbol->type) ||
             (source_symbol->type.ptr == 0 &&
              type_has_finalizer(source_symbol->type)))) {
            struct DeclInfo resource_decl;

            if (parse_decl(all->text, &resource_decl) &&
                resource_decl.is_decl && resource_decl.name[0] != '\0') {
                destination_type = resource_decl.type;
            } else if (extract_lhs_name(all->text, eq, lhs_name)) {
                destination_type = lhs_type_before_eq(all->text, eq, lhs_name);
            }
            if (type_is_runtime_resource_value(destination_type)) {
                fprintf(stderr,
                        "c-: type error: runtime resource '%s' cannot be copied in safe mode; initialize a fresh resource or pass it by ref\n",
                        resource_source);
                text_free(all);
                exit(1);
            }
            if (source_symbol->type.ptr == 0 &&
                type_has_finalizer(source_symbol->type) &&
                destination_type.ptr == 0 &&
                type_has_finalizer(destination_type)) {
                fprintf(stderr,
                        "c-: type error: owning struct '%s' cannot be copied in safe mode; use clone for an independent value or pass it by ref\n",
                        resource_source);
                text_free(all);
                exit(1);
            }
        }
    }
    if (!g_in_function) {
        if (g_in_aggregate_struct && g_current_struct_mmio &&
            parse_decl(all->text, &decl) && decl.is_decl && decl.name[0] != '\0' && !decl.is_function) {
            all = rewrite_mmio_field_decl(all, &decl);
        }
        if (g_in_aggregate_struct && g_current_struct_tag[0] != '\0' &&
            parse_decl(all->text, &decl) && decl.is_decl && decl.name[0] != '\0' &&
            decl.type.ptr >= 0) {
            if (g_unsafe_depth == 0 && type_is_atomic_value(decl.type) &&
                !type_is_thread_atomic(decl.type)) {
                fprintf(stderr, "c-: type error: Atomic field '%s.%s' requires a non-pointer integer, enum, or bitflags payload in safe mode at %s:%d\n",
                        g_current_struct_tag, decl.name,
                        g_input_path == NULL ? "<unknown>" : g_input_path,
                        yylineno);
                exit(1);
            }
            if (g_unsafe_depth == 0 && type_is_stored_safe_reference(decl.type)) {
                fprintf(stderr, "c-: type error: Ref/Span fields are not allowed in safe structs for field '%s.%s' at %s:%d; keep safe references local or store owned data\n",
                        g_current_struct_tag, decl.name, g_input_path ? g_input_path : "<stdin>", yylineno);
                exit(1);
            }
            if (g_unsafe_depth == 0 && type_is_runtime_resource_value(decl.type)) {
                fprintf(stderr, "c-: type error: runtime resource fields are not allowed in safe structs for field '%s.%s' at %s:%d; keep the resource in a local/global variable and pass it by ref until move semantics are available\n",
                        g_current_struct_tag, decl.name,
                        g_input_path ? g_input_path : "<stdin>", yylineno);
                exit(1);
            }
            struct_clone_add_field(g_current_struct_tag, decl.name, decl.type, decl.is_array);
            if (decl.type.owned || type_has_finalizer(decl.type)) {
                struct_finalizer_add_field(g_current_struct_tag, decl.name, decl.type);
            }
        }
        all->tail_return = 0;
        all->ast = ast_raw(ND_RAW, all->text);
        all = rewrite_os_attributes(all);
        all = rewrite_sizeof_types(all);
        all = rewrite_compile_time_os_ops(all);
        all = rewrite_linker_address_ops(all);
        all = rewrite_alignment_calls(all);
        return remove_percent(strip_attributes(all));
    }
    check_null_assignment(all->text);
    if (parse_decl(all->text, &decl) && decl.is_decl && decl.name[0] != '\0' && !decl.is_function) {
        if (g_unsafe_depth == 0 && type_is_atomic_value(decl.type) &&
            !type_is_thread_atomic(decl.type)) {
            fprintf(stderr, "c-: type error: Atomic value '%s' requires a non-pointer integer, enum, or bitflags payload in safe mode at %s:%d\n",
                    decl.name, g_input_path == NULL ? "<unknown>" : g_input_path,
                    yylineno);
            exit(1);
        }
        if (g_unsafe_depth == 0 && decl.is_array && decl.type.array_len <= 0) {
            fprintf(stderr, "c-: type error: variable-length or unsized array '%s' is only allowed inside unsafe at %s:%d; use a fixed array or checked collection\n",
                    decl.name, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
        if (g_unsafe_depth == 0 && decl.is_array && decl.type.array_len > 0 &&
            decl.type.size > 0 &&
            (unsigned long)decl.type.array_len >
                MAX_SAFE_LOCAL_ARRAY_BYTES / (unsigned long)decl.type.size) {
            fprintf(stderr, "c-: type error: local array '%s' exceeds the safe stack object limit of %lu bytes at %s:%d; use Box or a checked heap collection\n",
                    decl.name, (unsigned long)MAX_SAFE_LOCAL_ARRAY_BYTES,
                    g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
        if (g_unsafe_depth == 0 && type_is_heap_container_with_safe_reference(decl.type)) {
            fprintf(stderr, "c-: type error: heap container '%s' cannot store Ref/Span values in safe mode at %s:%d; store owned values instead\n",
                    decl.name, g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
        moved_local_remove(decl.name);
        borrow_link_remove_borrower(decl.name);
    }
    check_moved_local_use(all->text);
    if (eq >= 0 && extract_lhs_name(all->text, eq, lhs_name)) {
        moved_local_remove(lhs_name);
        borrow_link_remove_borrower(lhs_name);
    }
    check_dead_borrow_use(all->text);
    check_safe_pointer_deref(all->text);
    check_casts(all->text);
    check_safe_heap_calls(all->text);
    check_no_heap_safe_expr(all->text);
    check_safe_raw_field_access(all->text);
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
        if (is_borrowed) {
            decl.type.owned = 0;
        }
        if (decl.has_init) {
            char alias_owner[NAME_MAX_LEN];

            if (!is_borrowed && !extract_direct_move_name(decl.init, moved_name) &&
                extract_plain_name_expr(decl.init, alias_owner) &&
                owner_is_tracked_owned(alias_owner)) {
                fprintf(stderr, "c-: type error: owned value '%s' cannot be aliased by '%s' at %s:%d; use move or declare an explicit borrow\n",
                        alias_owner, decl.name,
                        g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
                exit(1);
            }
            rhs_type = safety_ast_expr_type(decl.init);
            if ((is_borrowed && extract_direct_borrow_owner(decl.init, borrow_owner)) ||
                (is_safe_reference_type(decl.type) &&
                 extract_safe_reference_borrow_owner(decl.init, borrow_owner))) {
                borrow_link_add(decl.name, borrow_owner);
            }
            if (extract_direct_move_name(decl.init, moved_name)) {
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
                call = build_s_string_format_statement(decl.name, decl.init, all->text);
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
            } else if (rhs_has_malloc_call(decl.init, func_name) &&
                       !rhs_is_single_owned_return_call(decl.init) &&
                       !rhs_has_new_expr(decl.init, &new_type)) {
                if (decl.type.owned) {
                    fprintf(stderr, "c-: type error: owned declaration cannot bind an offset owned result for '%s'\n", decl.name);
                    text_free(all);
                    exit(1);
                }
                owned_rvalue_call = 1;
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
            }
            check_assignment_type(decl.name, decl.type, rhs_type);
        }
        if (decl.type.owned && decl.type.ptr > 0 && decl.type.kind == TY_STRUCT) {
            owned_add(decl.name, decl.type);
        }
        symbol_add(decl.name, decl.type);
        if (decl.type.ptr == 0 && type_has_finalizer(decl.type)) {
            finalized_local_add(decl.name, decl.type);
        }
        all->tail_return = 0;
        all->ast = ast_raw(ND_DECL, all->text);
        all = rewrite_os_attributes(all);
        all = remove_percent(strip_attributes(all));
        all = rewrite_method_calls(all);
        all = rewrite_inferred_array_from_calls(all);
        all = rewrite_stack_lifetime_from_calls(all);
        check_safe_c_function_calls(all->text);
        check_no_heap_safe_expr(all->text);
        check_safe_reference_raw_inputs(all->text);
        check_safe_raw_field_access(all->text);
        check_safe_array_index_access(all->text);
        check_span_stack_array_bounds(all->text);
        all = rewrite_auto_field_access(all);
        all = rewrite_parameter_calls(all);
        check_safe_reference_raw_inputs(all->text);
        check_null_arguments(all->text);
        all = rewrite_span_operators(all);
        all = rewrite_sizeof_types(all);
        all = rewrite_compile_time_os_ops(all);
        all = rewrite_linker_address_ops(all);
        all = rewrite_alignment_calls(all);
        all = rewrite_index_access(all);
        all = rewrite_division_checks(all);
        all = rewrite_control_condition(all);
        all = rewrite_s_string_temporaries(all);
        all = rewrite_clone_expressions(all);
        all = rewrite_new_expressions(all);
        if (owned_rvalue_call) {
            all = rewrite_owned_return_rvalues(all, all->text);
        }
        if (!decl.has_init) {
            all = add_zero_initializer(all);
            append_zero_clear_after_decl(all, all->text, decl.name);
        }
        if (post_free) {
            append_free_after_statement(all, all->text, post_free_name, post_free_type);
        }
        return all;
    }

    if (eq >= 0 && !extract_direct_move_name(all->text + eq + 1, moved_name)) {
        char alias_owner[NAME_MAX_LEN];

        if (extract_plain_name_expr(all->text + eq + 1, alias_owner) &&
            owner_is_tracked_owned(alias_owner) &&
            extract_lhs_name(all->text, eq, lhs_name)) {
            lhs_type = lhs_type_before_eq(all->text, eq, lhs_name);
            if (lhs_type.ptr > 0) {
                fprintf(stderr, "c-: type error: owned value '%s' cannot be assigned by alias to '%s' at %s:%d; use move\n",
                        alias_owner, lhs_name,
                        g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
                exit(1);
            }
        }
    }

    if (eq >= 0 && extract_direct_move_name(all->text + eq + 1, moved_name)) {
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
        borrow_links_invalidate_owner(moved_name);
    } else if (eq >= 0 && rhs_has_s_string(all->text + eq + 1)) {
        char *lhs_expr;

        if (!extract_lhs_name(all->text, eq, lhs_name)) {
            fprintf(stderr, "c-: type error: s string requires a char pointer lvalue\n");
            text_free(all);
            exit(1);
        }
        lhs_expr = slice_lhs_expr(all->text, eq);
        lhs = symbol_find(lhs_name);
        lhs_type = lhs_type_before_eq(all->text, eq, lhs_name);
        rhs_type = safety_ast_expr_type(all->text + eq + 1);
        if (!type_is_known(lhs_type) || lhs_type.ptr <= 0 || lhs_type.kind != TY_CHAR) {
            fprintf(stderr, "c-: type error: s string requires a char pointer lvalue for '%s'\n", lhs_name);
            free(lhs_expr);
            text_free(all);
            exit(1);
        }
        check_assignment_type(lhs_name, lhs_type, rhs_type);
        if (lhs != NULL && lhs->type.owned) {
            owned_add(lhs_name, lhs->type);
            owned_assign = 1;
            owned_assign_type = lhs->type;
            owned_assign_lhs = xstrdup(lhs_expr);
        } else if (lhs_type.owned) {
            owned_assign = 1;
            owned_assign_type = lhs_type;
            owned_assign_lhs = xstrdup(lhs_expr);
        } else {
            post_free = 1;
            strcpy(post_free_name, lhs_name);
            post_free_type = lhs_type;
        }
        all = build_s_string_format_statement(lhs_expr, all->text + eq + 1, all->text);
        free(lhs_expr);
        if (owned_assign) {
            all = prepend_owned_assignment_release(all, all->text, owned_assign_lhs, owned_assign_type);
            if (extract_direct_borrow_owner(owned_assign_lhs, borrow_owner)) {
                borrow_links_invalidate_owner(borrow_owner);
            }
            free(owned_assign_lhs);
            owned_assign_lhs = NULL;
        }
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
    } else if (eq >= 0 && rhs_has_malloc_call(all->text + eq + 1, func_name) &&
               !rhs_is_single_owned_return_call(all->text + eq + 1) &&
               !rhs_has_new_expr(all->text + eq + 1, &new_type)) {
        if (extract_lhs_name(all->text, eq, lhs_name)) {
            lhs_type = lhs_type_before_eq(all->text, eq, lhs_name);
            rhs_type = safety_ast_expr_type(all->text + eq + 1);
            check_assignment_type(lhs_name, lhs_type, rhs_type);
            owned_rvalue_call = 1;
        } else {
            owned_rvalue_call = 1;
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
            rhs_type = safety_ast_expr_type(all->text + eq + 1);
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
            rhs_type = safety_ast_expr_type(all->text + eq + 1);
            check_assignment_type(lhs_name, lhs_type, rhs_type);
            if (!lhs->type.owned &&
                (extract_direct_borrow_owner(all->text + eq + 1, borrow_owner) ||
                 (is_safe_reference_type(lhs->type) &&
                  extract_safe_reference_borrow_owner(all->text + eq + 1, borrow_owner)))) {
                borrow_link_add(lhs_name, borrow_owner);
            }
        }
    } else if (eq < 0 && rhs_has_malloc_call(all->text, func_name)) {
        owned_rvalue_call = 1;
    }
    all->tail_return = 0;
    all->ast = ast_raw(eq >= 0 ? ND_ASSIGN : ND_EXPR_STMT, all->text);
    all = rewrite_os_attributes(all);
    all = remove_percent(strip_attributes(all));
    all = rewrite_payload_enum_constructors(all);
    all = rewrite_method_calls(all);
    all = rewrite_inferred_array_from_calls(all);
    all = rewrite_stack_lifetime_from_calls(all);
    check_safe_c_function_calls(all->text);
    check_no_heap_safe_expr(all->text);
    check_safe_reference_raw_inputs(all->text);
    check_safe_raw_field_access(all->text);
    check_safe_array_index_access(all->text);
    check_span_stack_array_bounds(all->text);
    all = rewrite_auto_field_access(all);
    all = rewrite_span_operators(all);
    all = rewrite_sizeof_types(all);
    all = rewrite_compile_time_os_ops(all);
    all = rewrite_linker_address_ops(all);
    all = rewrite_alignment_calls(all);
    all = rewrite_index_access(all);
    all = rewrite_parameter_calls(all);
    check_safe_reference_raw_inputs(all->text);
    check_null_arguments(all->text);
    all = rewrite_division_checks(all);
    all = rewrite_clone_expressions(all);
    all = rewrite_control_condition(all);
    all = rewrite_s_string_temporaries(all);
    all = rewrite_new_expressions(all);
    if (owned_rvalue_call) {
        all = rewrite_owned_return_rvalues(all, all->text);
    }
    if (owned_assign) {
        all = prepend_owned_assignment_release(all, all->text, owned_assign_lhs, owned_assign_type);
        if (extract_direct_borrow_owner(owned_assign_lhs, borrow_owner)) {
            borrow_links_invalidate_owner(borrow_owner);
        }
        free(owned_assign_lhs);
        owned_assign_lhs = NULL;
    }
    if (post_free) {
        append_free_after_statement(all, all->text, post_free_name, post_free_type);
    }
    return all;
}

static int detach_plain_return_owner(const char *s)
{
    char *expr = extract_return_value_expr(s);
    char name[NAME_MAX_LEN];
    int detached = 0;

    if (expr == NULL) {
        return 0;
    }
    if ((extract_plain_name_expr(expr, name) || extract_move_name(expr, name)) &&
        (owned_index_in(&g_owned, name) >= 0 ||
         owned_index_in(&g_finalized_locals, name) >= 0)) {
        owned_remove_from(&g_owned, name);
        owned_remove_from(&g_finalized_locals, name);
        moved_local_add(name);
        detached = 1;
    }
    free(expr);
    return detached;
}

static char *extract_return_value_expr(const char *stmt)
{
    const char *p = skip_ws(stmt);
    const char *expr_start;
    const char *expr_end;

    if (!starts_word(p, "return")) {
        return NULL;
    }
    expr_start = skip_ws(p + 6);
    expr_end = expr_start + strlen(expr_start);
    while (expr_end > expr_start && isspace((unsigned char)expr_end[-1])) {
        expr_end--;
    }
    if (expr_end > expr_start && expr_end[-1] == ';') {
        expr_end--;
    }
    while (expr_end > expr_start && isspace((unsigned char)expr_end[-1])) {
        expr_end--;
    }
    if (expr_end <= expr_start) {
        return NULL;
    }
    return xstrndup(expr_start, (size_t)(expr_end - expr_start));
}

static struct Text *process_return(struct Text *ret, struct Text *expr, struct Text *semi)
{
    struct Text *all = text_join3(ret, expr, semi);
    pending_semantics_capture_return(all->text);
    all->ast = ast_raw(ND_RETURN, all->text);
    if (g_current_generic_kind != 0 || g_current_payload_enum) {
        all->tail_return = 1;
        return all;
    }
    if (g_c_compat && g_unsafe_depth == 0) {
        all->tail_return = 1;
        return all;
    }
    check_safe_pointer_deref(all->text);
    check_casts(all->text);
    check_safe_heap_calls(all->text);
    check_no_heap_safe_expr(all->text);
    check_safe_raw_field_access(all->text);
    check_moved_local_use(all->text);
    check_dead_borrow_use(all->text);
    check_borrow_escape_return(all->text);
    remove_moved_locals(all->text);
    all = rewrite_generics(all);
    all = rewrite_payload_enum_constructors(all);
    all = rewrite_optional_null_return(all);
    {
        const char *p = skip_ws(all->text);
        const char *expr_start = starts_word(p, "return") ? skip_ws(p + 6) : NULL;

        if (expr_start != NULL && rhs_is_null_literal(expr_start) &&
            g_current_function_name[0] != '\0' &&
            strncmp(g_current_function_name, "__cminus", 8) != 0 &&
            strncmp(g_current_function_name, "cminus_", 7) != 0) {
            fprintf(stderr, "c-: type error: return NULL is only allowed for Optional in safe mode at %s:%d; use Optional<T>.None()\n",
                    g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            exit(1);
        }
        if (expr_start != NULL && g_unsafe_depth == 0) {
            const char *expr_end = expr_start + strlen(expr_start);
            char *expr_text;
            struct Type return_type;

            while (expr_end > expr_start && isspace((unsigned char)expr_end[-1])) {
                expr_end--;
            }
            if (expr_end > expr_start && expr_end[-1] == ';') {
                expr_end--;
            }
            while (expr_end > expr_start && isspace((unsigned char)expr_end[-1])) {
                expr_end--;
            }
            expr_text = xstrndup(expr_start, (size_t)(expr_end - expr_start));
            return_type = safety_ast_expr_type(expr_text);
            free(expr_text);
            if (return_type.raw_ptr) {
                fprintf(stderr, "c-: type error: raw pointer taint cannot be returned from safe function '%s'; use unsafe or a managed safe wrapper\n",
                        g_current_function_name);
                exit(1);
            }
        }
    }
    all = rewrite_method_calls(all);
    all = rewrite_inferred_array_from_calls(all);
    all = rewrite_stack_lifetime_from_calls(all);
    check_safe_c_function_calls(all->text);
    check_safe_reference_raw_inputs(all->text);
    check_safe_raw_field_access(all->text);
    check_safe_array_index_access(all->text);
    check_span_stack_array_bounds(all->text);
    all = rewrite_auto_field_access(all);
    all = rewrite_span_operators(all);
    all = rewrite_sizeof_types(all);
    all = rewrite_compile_time_os_ops(all);
    all = rewrite_linker_address_ops(all);
    all = rewrite_alignment_calls(all);
    all = rewrite_index_access(all);
    all = rewrite_parameter_calls(all);
    check_safe_reference_raw_inputs(all->text);
    check_null_arguments(all->text);
    all = rewrite_division_checks(all);
    all = remove_percent(strip_attributes(all));
    {
        int detached_return_owner = detach_plain_return_owner(all->text);

        if (g_unsafe_depth == 0 && g_current_function_ret.ptr == 0 &&
            type_has_finalizer(g_current_function_ret) &&
            !detached_return_owner) {
            fprintf(stderr, "c-: type error: an owning struct return must transfer a plain local value at %s:%d; assign the result to a local first\n",
                    g_input_path == NULL ? "<unknown>" : g_input_path, yylineno);
            text_free(all);
            exit(1);
        }
    }
    if (g_owned.count > 0 || g_finalized_locals.count > 0) {
        struct Text *out = text_new();
        struct Text *indent = text_new();
        char *return_expr = extract_return_value_expr(all->text);
        append_leading_newlines(all->text, out);
        append_indent_from(all->text, indent);
        if (return_expr != NULL) {
            char tmp[64];

            snprintf(tmp, sizeof(tmp), "__cminus_return%d", g_right_value_id++);
            text_add(out, indent->text);
            text_add(out, "__typeof__((");
            text_add(out, return_expr);
            text_add(out, ")) ");
            text_add(out, tmp);
            text_add(out, " = (");
            text_add(out, return_expr);
            text_add(out, ");\n");
            emit_frees(out, indent->text);
            if (g_current_function_stack_guard) {
                append_stack_leave(out, indent->text);
            }
            text_add(out, indent->text);
            text_add(out, "return ");
            text_add(out, tmp);
            text_add(out, ";");
            free(return_expr);
            out->tail_return = 1;
            out->ast = ast_raw(ND_RETURN, out->text);
            text_free(indent);
            text_free(all);
            return out;
        }
        free(return_expr);
        emit_frees(out, indent->text);
        if (g_current_function_stack_guard) {
            append_stack_leave(out, indent->text);
        }
        text_add(out, indent->text);
        text_add(out, skip_leading_space(all->text));
        out->tail_return = 1;
        out->ast = ast_raw(ND_RETURN, out->text);
        text_free(indent);
        text_free(all);
        return out;
    }
    {
        struct Text *out = text_new();
        struct Text *indent = text_new();
        char *return_expr = extract_return_value_expr(all->text);

        append_leading_newlines(all->text, out);
        append_indent_from(all->text, indent);
        if (return_expr != NULL && g_current_function_stack_guard) {
            char tmp[64];

            snprintf(tmp, sizeof(tmp), "__cminus_return%d", g_right_value_id++);
            text_add(out, indent->text);
            text_add(out, "__typeof__((");
            text_add(out, return_expr);
            text_add(out, ")) ");
            text_add(out, tmp);
            text_add(out, " = (");
            text_add(out, return_expr);
            text_add(out, ");\n");
            append_stack_leave(out, indent->text);
            text_add(out, indent->text);
            text_add(out, "return ");
            text_add(out, tmp);
            text_add(out, ";");
            free(return_expr);
            out->tail_return = 1;
            out->ast = ast_raw(ND_RETURN, out->text);
            text_free(indent);
            text_free(all);
            return out;
        }
        free(return_expr);
        if (g_current_function_stack_guard) {
            append_stack_leave(out, indent->text);
        }
        text_add(out, indent->text);
        text_add(out, skip_leading_space(all->text));
        out->tail_return = 1;
        out->ast = ast_raw(ND_RETURN, out->text);
        text_free(indent);
        text_free(all);
        return out;
    }
}

static struct Text *finish_c_compat_braced_decl(struct Text *head, struct Text *lb, struct Text *body, struct Text *rb, struct Text *suffix, struct Text *semi)
{
    struct Text *out = text_join3(head, lb, body);

    out = text_join(out, rb);
    out = text_join(out, suffix);
    out = text_join(out, semi);
    out->ast = ast_raw(ND_EXPR_STMT, out->text);
    return out;
}

static struct Text *finish_top_block(struct Text *head, struct Text *lb, struct Text *body, struct Text *rb)
{
    struct Text *out;
    struct Node *body_ast = body->ast;
    char name[NAME_MAX_LEN];
    char param[NAME_MAX_LEN];
    struct Type ret;

    if (is_unsafe_head(head->text)) {
        register_unsafe_metadata(body->text);
        cminus_unsafe_pop();
        out = wrap_transparent_boundary(body, ND_UNSAFE);
        text_free(head);
        text_free(lb);
        text_free(rb);
        g_top_block_is_function = 0;
        g_in_function = 0;
        return out;
    }
    if (is_inline_c_head(head->text)) {
        cminus_unsafe_pop();
        out = normalize_raw_c_block_body(body);
        text_free(head);
        text_free(lb);
        text_free(rb);
        g_top_block_is_function = 0;
        g_in_function = 0;
        return out;
    }

    if (g_current_bitflags) {
        bitflags_add(g_current_bitflags_name, g_current_bitflags_base);
        out = emit_bitflags_decl(g_current_bitflags_name, g_current_bitflags_base, body->text);
        g_current_bitflags = 0;
        g_top_block_is_function = 0;
        g_in_aggregate_struct = 0;
        g_current_struct_tag[0] = '\0';
        g_current_bitflags_name[0] = '\0';
        g_current_bitflags_base[0] = '\0';
        g_skip_next_semi = 1;
        text_free(head);
        text_free(lb);
        text_free(body);
        text_free(rb);
        return out;
    }

    if (g_current_payload_enum) {
        struct Node *template_ast;

        if (!parse_payload_enum_head(head->text, param, name)) {
            die("invalid payload enum");
        }
        template_ast = ast_new(ND_PAYLOAD_ENUM_TEMPLATE, head->text);
        strncpy(template_ast->name, name, NAME_MAX_LEN - 1);
        template_ast->name[NAME_MAX_LEN - 1] = '\0';
        strncpy(template_ast->type_name, param, NAME_MAX_LEN - 1);
        template_ast->type_name[NAME_MAX_LEN - 1] = '\0';
        template_ast->type_params = ast_type_parameters(param);
        payload_enum_add(param, name, body->text, template_ast);
        out = text_new();
        g_current_payload_enum = 0;
        g_current_generic_param[0] = '\0';
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
        struct Node *template_ast;

        if (!parse_generic_struct_head(head->text, param, name)) {
            die("invalid generic struct");
        }
        template_ast = ast_aggregate(head->text, lb->text, body->text,
                                     rb->text, body_ast);
        template_ast->kind = ND_GENERIC_STRUCT_TEMPLATE;
        strncpy(template_ast->name, name, NAME_MAX_LEN - 1);
        template_ast->name[NAME_MAX_LEN - 1] = '\0';
        template_ast->type_params = ast_type_parameters(param);
        generic_add(&g_generic_structs, param, name, head->text, body->text,
                    template_ast);
        out = text_new();
        g_current_generic_kind = 0;
        g_current_generic_param[0] = '\0';
        g_top_block_is_function = 0;
        g_in_aggregate_struct = 0;
        g_current_struct_tag[0] = '\0';
        g_skip_next_semi = 1;
        body->ast = NULL;
        text_free(head);
        text_free(lb);
        text_free(body);
        text_free(rb);
        return out;
    }
    if (g_current_generic_kind == 2) {
        struct Node *template_ast;
        const char *signature_head;

        if (!parse_generic_function_head(head->text, param, name)) {
            die("invalid generic function");
        }
        signature_head = parse_generic_prefix(head->text, param);
        template_ast = ast_function(signature_head == NULL ? head->text : signature_head,
                                    body_ast);
        template_ast->kind = ND_GENERIC_FUNCTION_TEMPLATE;
        strncpy(template_ast->name, name, NAME_MAX_LEN - 1);
        template_ast->name[NAME_MAX_LEN - 1] = '\0';
        template_ast->type_params = ast_type_parameters(param);
        generic_add(&g_generic_funcs, param, name, head->text, body->text,
                    template_ast);
        out = text_new();
        g_current_generic_kind = 0;
        g_current_generic_param[0] = '\0';
        g_in_function = 0;
        body->ast = NULL;
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
            g_moved_locals.count = 0;
            g_borrow_links.count = 0;
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
        struct Node *aggregate_ast;
        register_tags_in_text(head->text);
        head = strip_mmio_modifier(head);
        aggregate_ast = ast_aggregate(head->text, lb->text, body->text,
                                      rb->text, body_ast);
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
        out->ast = aggregate_ast;
        g_top_block_is_function = 0;
        g_in_aggregate_struct = 0;
        g_current_struct_mmio = 0;
        g_current_struct_tag[0] = '\0';
        return out;
    }

    if (g_c_compat && g_unsafe_depth == 0) {
        struct Node *function_ast = ast_function(head->text, body_ast);

        out = text_join3(head, lb, body);
        out = text_join(out, rb);
        out->ast = function_ast;
        g_owned.count = 0;
        g_finalized_locals.count = 0;
        g_moved_locals.count = 0;
        g_borrow_links.count = 0;
        g_locals.count = 0;
        g_function_returns_move = 0;
        g_current_function_name[0] = '\0';
        g_current_function_ret = type_unknown();
        g_current_function_interrupt = 0;
        g_current_function_naked = 0;
        g_in_function = 0;
        return out;
    }

    head = rewrite_generics(head);
    head = rewrite_safe_reference_decl(head);
    validate_interrupt_function_head(head->text);
    register_function_params(head->text);
    register_owned_function_signature(head->text);
    register_malloc_attribute_function(head->text);
    if (g_function_returns_move && parse_function_signature(head->text, name, &ret) && ret.ptr > 0) {
        ret.owned = 1;
        owned_func_add_type(name, ret);
    }
    head = strip_default_parameters(head);
    head = rewrite_interrupt_function_head(head);
    head = rewrite_os_attributes(head);
    head = remove_percent(strip_attributes(head));
    {
        struct Text *prologue = text_new();
        struct Node *function_ast = ast_function(head->text, body_ast);
        int body_tail_return = body->tail_return;
        if (g_current_function_stack_guard) {
            append_stack_enter(prologue, "    ");
        }
        out = text_join3(head, lb, prologue);
        out = text_join(out, body);
        if ((g_owned.count > 0 || g_finalized_locals.count > 0) && !body_tail_return) {
            const char *last = out->len > 0 ? out->text + out->len - 1 : out->text;
            if (out->len == 0 || *last != '\n') {
                text_add_ch(out, '\n');
            }
            emit_frees(out, "    ");
        }
        if (!body_tail_return && g_current_function_stack_guard) {
            append_stack_leave(out, "    ");
        }
        out->ast = function_ast;
    }
    out = text_join(out, rb);
    g_owned.count = 0;
    g_finalized_locals.count = 0;
    g_moved_locals.count = 0;
    g_borrow_links.count = 0;
    g_locals.count = 0;
    g_function_returns_move = 0;
    g_current_function_name[0] = '\0';
    g_current_function_ret = type_unknown();
    g_current_function_interrupt = 0;
    g_current_function_naked = 0;
    g_in_function = 0;
    return out;
}

static const char *generic_template_body_start(const char *head, char *param)
{
    const char *p = parse_generic_prefix(head, param);

    return p == NULL ? head : p;
}

static char *generic_concrete_ast_text(const char *text,
                                       struct GenericTemplate *tmpl,
                                       struct GenericInstance *inst)
{
    struct Text *rewritten;
    char *result;

    if (text == NULL) {
        return NULL;
    }
    rewritten = replace_param_and_generics(text, tmpl->param, inst->arg,
                                           tmpl->name, inst->concrete);
    rewritten = remove_percent(strip_attributes(rewritten));
    result = xstrdup(rewritten->text);
    text_free(rewritten);
    return result;
}

static struct Node *clone_concrete_generic_ast(const struct Node *source,
                                               struct GenericTemplate *tmpl,
                                               struct GenericInstance *inst)
{
    struct Node *head = NULL;

    for (; source != NULL; source = source->next) {
        char *tok = generic_concrete_ast_text(source->tok, tmpl, inst);
        struct Node *body = clone_concrete_generic_ast(source->body, tmpl, inst);
        struct Node *node;

        switch (source->kind) {
        case ND_DECL:
        case ND_FIELD:
        case ND_ASSIGN:
        case ND_EXPR_STMT:
        case ND_RETURN:
            node = ast_typed_statement(source->kind, tok == NULL ? "" : tok);
            if (body != NULL) {
                node->body = body;
            }
            if (source->kind == ND_FIELD) {
                node->kind = ND_FIELD;
            }
            break;
        case ND_IF:
        case ND_WHILE:
        case ND_FOR:
        case ND_SWITCH:
        case ND_DO:
            node = ast_control(tok == NULL ? "" : tok,
                               source->open_tok == NULL ? "" : source->open_tok,
                               source->body_tok == NULL ? "" : source->body_tok,
                               source->close_tok == NULL ? "" : source->close_tok,
                               body);
            break;
        case ND_BLOCK:
            node = ast_block(body);
            node->open_tok = xstrdup(source->open_tok);
            node->body_tok = xstrdup(source->body_tok);
            node->close_tok = xstrdup(source->close_tok);
            break;
        default:
            node = ast_new(source->kind, tok);
            node->body = body;
            if (source->ty != NULL) {
                node->ty = type_copy(*source->ty);
            }
            if (source->expr != NULL && tok != NULL) {
                node->expr = safety_parse_range(node->tok,
                                                node->tok + strlen(node->tok));
            }
            break;
        }
        if (node->name[0] == '\0' && source->name[0] != '\0') {
            strncpy(node->name, source->name, NAME_MAX_LEN - 1);
            node->name[NAME_MAX_LEN - 1] = '\0';
        }
        if (source->type_name[0] != '\0') {
            strncpy(node->type_name, source->type_name, NAME_MAX_LEN - 1);
            node->type_name[NAME_MAX_LEN - 1] = '\0';
        }
        if (g_in_function && node->kind == ND_DECL && node->ty != NULL &&
            node->name[0] != '\0') {
            symbol_add_to(&g_locals, node->name, *node->ty);
            node->var = symbol_find(node->name) == NULL ? NULL :
                symbol_find(node->name)->var;
        }
        head = ast_append(head, node);
        free(tok);
    }
    return head;
}

static struct Node *clone_concrete_generic_function_ast(
    const struct Node *source, const char *function_head,
    struct GenericTemplate *tmpl, struct GenericInstance *inst)
{
    struct Symbols saved_locals = g_locals;
    struct VarScope *saved_var_scope = g_var_scope;
    struct Type saved_return = g_current_function_ret;
    char saved_name[NAME_MAX_LEN];
    char name[NAME_MAX_LEN];
    struct Type ret;
    int saved_in_function = g_in_function;
    struct Node *result;

    strncpy(saved_name, g_current_function_name, NAME_MAX_LEN - 1);
    saved_name[NAME_MAX_LEN - 1] = '\0';
    g_locals.count = 0;
    g_in_function = 1;
    g_current_function_name[0] = '\0';
    g_current_function_ret = type_unknown();
    if (parse_function_signature(function_head, name, &ret)) {
        strncpy(g_current_function_name, name, NAME_MAX_LEN - 1);
        g_current_function_name[NAME_MAX_LEN - 1] = '\0';
        g_current_function_ret = ret;
        register_function_params(function_head);
        register_function_param_symbols(function_head);
    }
    result = clone_concrete_generic_ast(source, tmpl, inst);
    g_locals = saved_locals;
    g_var_scope = saved_var_scope;
    g_in_function = saved_in_function;
    g_current_function_ret = saved_return;
    strncpy(g_current_function_name, saved_name, NAME_MAX_LEN - 1);
    g_current_function_name[NAME_MAX_LEN - 1] = '\0';
    return result;
}

static void emit_generic_struct_instance(FILE *out,
                                         struct GenericTemplate *tmpl,
                                         struct GenericInstance *inst)
{
    char param[NAME_MAX_LEN];
    const char *head;
    struct Text *concrete_head;
    struct Text *concrete_body;
    struct Text *generated;
    struct Node *generated_ast;

    if (inst->emitted || strcmp(inst->arg, tmpl->param) == 0) {
        return;
    }
    head = generic_template_body_start(tmpl->head, param);
    concrete_head = replace_param_and_generics(head,
                                               tmpl->param,
                                               inst->arg,
                                               tmpl->name,
                                               inst->concrete);
    concrete_body = replace_param_and_generics(tmpl->body,
                                               tmpl->param,
                                               inst->arg,
                                               tmpl->name,
                                               inst->concrete);
    concrete_head = remove_percent(strip_attributes(concrete_head));
    concrete_body = remove_percent(strip_attributes(concrete_body));
    generated = text_new();
    text_add(generated, concrete_head->text);
    text_add(generated, "{");
    text_add(generated, concrete_body->text);
    if (concrete_body->len > 0 && concrete_body->text[concrete_body->len - 1] != '\n') {
        text_add_ch(generated, '\n');
    }
    text_add(generated, "};\n");
    generated_ast = ast_aggregate(concrete_head->text, "{",
                                  concrete_body->text, "};\n",
                                  clone_concrete_generic_ast(tmpl->ast->body,
                                                             tmpl, inst));
    emit_generated_text_ast(out, ND_GENERIC_STRUCT, inst->concrete,
                            generated, generated_ast);
    inst->emitted = 1;
    text_free(concrete_head);
    text_free(concrete_body);
}

static void emit_payload_enum_generic_dependencies(FILE *out)
{
    int i;

    for (i = 0; i < g_payload_enums.count; i++) {
        struct PayloadEnum *en = &g_payload_enums.en[i];
        int j;

        for (j = 0; j < en->inst_count; j++) {
            const char *p = skip_ws(en->inst[j].arg);
            char concrete[NAME_MAX_LEN];
            struct GenericInstance *dependency = NULL;
            struct GenericTemplate *tmpl;

            if (!starts_word(p, "struct")) {
                continue;
            }
            p = skip_ws(p + 6);
            if (!is_ident_start((unsigned char)*p)) {
                continue;
            }
            read_name(p, concrete);
            tmpl = generic_struct_find_by_concrete(concrete, &dependency);
            if (tmpl != NULL && dependency != NULL) {
                emit_generic_struct_instance(out, tmpl, dependency);
            }
        }
    }
}

static void emit_generic_struct_instances(FILE *out)
{
    int i;
    int j;

    for (i = 0; i < g_generic_structs.count; i++) {
        struct GenericTemplate *tmpl = &g_generic_structs.tmpl[i];
        for (j = 0; j < tmpl->inst_count; j++) {
            emit_generic_struct_instance(out, tmpl, &tmpl->inst[j]);
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
            char func_name[NAME_MAX_LEN];
            const char *head = generic_template_body_start(tmpl->head, param);
            struct Text *concrete_head = replace_param_and_generics(head,
                                                                    tmpl->param,
                                                                    tmpl->inst[j].arg,
                                                                    tmpl->name,
                                                                    tmpl->inst[j].concrete);
            struct Text *generated;
            struct Node *generated_ast;
            struct Text *concrete_body = replace_param_and_generics(tmpl->body,
                                                                    tmpl->param,
                                                                    tmpl->inst[j].arg,
                                                                    tmpl->name,
                                                                    tmpl->inst[j].concrete);
            struct FunctionParams *fn = NULL;
            if (head_function_name(concrete_head->text, func_name)) {
                register_function_params(concrete_head->text);
                fn = function_params_find(func_name);
                emit_generic_default_undef(out, func_name, fn);
            }
            concrete_head = strip_default_parameters(concrete_head);
            concrete_head = remove_percent(strip_attributes(concrete_head));
            concrete_body = remove_percent(strip_attributes(concrete_body));
            concrete_body = rewrite_parameter_calls(concrete_body);
            concrete_body = rewrite_payload_enum_constructors(concrete_body);
            generated = text_new();
            text_add(generated, concrete_head->text);
            text_add(generated, "{");
            if (head_function_name(concrete_head->text, func_name) &&
                function_needs_stack_guard(func_name) &&
                strstr(concrete_head->text, "Iterator_next_") == NULL &&
                strstr(concrete_head->text, "VecIterator_next_") == NULL &&
                strstr(concrete_head->text, "ListIterator_next_") == NULL) {
                text_add(generated, "    char __cminus_stack_anchor;\n    size_t __cminus_stack_id = cminus_stack_enter_impl(__FILE__, __LINE__, &__cminus_stack_anchor);\n");
                concrete_body = rewrite_returns_with_stack_leave(concrete_body);
            } else {
                func_name[0] = '\0';
            }
            text_add(generated, concrete_body->text);
            if (concrete_body->len > 0 && concrete_body->text[concrete_body->len - 1] != '\n') {
                text_add_ch(generated, '\n');
            }
            if (func_name[0] != '\0') {
                text_add(generated, "    cminus_stack_leave_impl(__cminus_stack_id, __FILE__, __LINE__);\n");
            }
            text_add(generated, "}\n");
            generated_ast = ast_function(
                concrete_head->text,
                clone_concrete_generic_function_ast(tmpl->ast->body,
                                                     concrete_head->text,
                                                     tmpl, &tmpl->inst[j]));
            emit_generated_text_ast(out, ND_GENERIC_FUNCTION,
                                    tmpl->inst[j].concrete, generated,
                                    generated_ast);
            text_free(concrete_head);
            text_free(concrete_body);
        }
    }
}

static void emit_generic_function_prototypes(FILE *out)
{
    int i;

    for (i = 0; i < g_generic_funcs.count; i++) {
        struct GenericTemplate *tmpl = &g_generic_funcs.tmpl[i];
        int j;
        for (j = 0; j < tmpl->inst_count; j++) {
            char param[NAME_MAX_LEN];
            char func_name[NAME_MAX_LEN];
            const char *head = generic_template_body_start(tmpl->head, param);
            struct Text *concrete_head = replace_param_and_generics(head,
                                                                    tmpl->param,
                                                                    tmpl->inst[j].arg,
                                                                    tmpl->name,
                                                                    tmpl->inst[j].concrete);
            struct Text *generated;
            struct Node *generated_ast;
            register_function_params(concrete_head->text);
            if (head_function_name(concrete_head->text, func_name)) {
                emit_generic_default_macro(out, func_name, function_params_find(func_name));
            }
            concrete_head = strip_default_parameters(concrete_head);
            concrete_head = remove_percent(strip_attributes(concrete_head));
            generated = text_new();
            text_add(generated, concrete_head->text);
            text_add(generated, ";\n");
            generated_ast = ast_function_declaration(concrete_head->text);
            emit_generated_text_ast(out, ND_GENERIC_PROTO,
                                    tmpl->inst[j].concrete, generated,
                                    generated_ast);
            text_free(concrete_head);
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

    register_function_params(concrete_head->text);
    concrete_head = strip_default_parameters(concrete_head);
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

static void emit_payload_enum_instances_direct(FILE *out)
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
            fputs("{\n    int tag;\n    unsigned long origin_kind;\n    unsigned long origin_stack_id;\n    union {\n", out);
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
                int pointer_enum = strcmp(en->name, "__CMinusIndex") != 0 &&
                    strcmp(en->name, "Optional") != 0;
                struct Type constructor_type =
                    type_make(TY_STRUCT, pointer_enum ? 1 : 0, inst->concrete);
                struct Text *helper_name = text_new();

                if (pointer_enum) constructor_type.owned = 1;
                text_add(helper_name, inst->concrete);
                text_add_ch(helper_name, '_');
                text_add(helper_name, variant->name);
                register_generated_function_return(helper_name->text,
                                                   constructor_type);
                text_free(helper_name);
                helper_name = text_new();
                text_add(helper_name, inst->concrete);
                text_add(helper_name, "_is_");
                text_add(helper_name, variant->name);
                register_generated_function_return(
                    helper_name->text, type_make(TY_INT, 0, NULL));
                text_free(helper_name);

                fputs("static __attribute__((unused)) struct ", out);
                fputs(inst->concrete, out);
                if (pointer_enum) {
                    fputc('*', out);
                }
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
                if (pointer_enum) {
                    fputs("* out = cminus_gc_calloc(1, sizeof(struct ", out);
                    fputs(inst->concrete, out);
                    fputs("));\n    out->tag = ", out);
                } else {
                    fputs(" out = {0};\n    out.tag = ", out);
                }
                fputs(inst->concrete, out);
                fputs("_TAG_", out);
                fputs(variant->name, out);
                fputs(";\n", out);
                if (variant->has_payload) {
                    struct Text *payload = replace_param_and_generics(variant->payload,
                                                                      en->param,
                                                                      inst->arg,
                                                                      en->name,
                                                                      inst->concrete);
                    payload = remove_percent(strip_attributes(payload));
                    if (payload_type_has_pointer(payload->text)) {
                        if (pointer_enum) {
                            fputs("    out->origin_kind = cminus_ptr_classify((void*)value, &out->origin_stack_id);\n", out);
                        } else {
                            fputs("    out.origin_kind = cminus_ptr_classify((void*)value, &out.origin_stack_id);\n", out);
                        }
                    } else {
                        if (pointer_enum) {
                            fputs("    out->origin_kind = 0UL;\n    out->origin_stack_id = 0UL;\n", out);
                        } else {
                            fputs("    out.origin_kind = 0UL;\n    out.origin_stack_id = 0UL;\n", out);
                        }
                    }
                    text_free(payload);
                    fputs(pointer_enum ? "    out->payload." : "    out.payload.", out);
                    fputs(variant->name, out);
                    fputs(" = value;\n", out);
                } else {
                    if (pointer_enum) {
                        fputs("    out->origin_kind = 0UL;\n    out->origin_stack_id = 0UL;\n", out);
                    } else {
                        fputs("    out.origin_kind = 0UL;\n    out.origin_stack_id = 0UL;\n", out);
                    }
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
                    struct Text *payload_decl;
                    struct DeclInfo payload_info;

                    payload = remove_percent(strip_attributes(payload));
                    payload_decl = text_new();
                    text_add(payload_decl, payload->text);
                    text_add(payload_decl, " value;");
                    if (parse_decl(payload_decl->text, &payload_info) &&
                        payload_info.name[0] != '\0') {
                        helper_name = text_new();
                        text_add(helper_name, inst->concrete);
                        text_add(helper_name, "_get_");
                        text_add(helper_name, variant->name);
                        register_generated_function_return(helper_name->text,
                                                           payload_info.type);
                        text_free(helper_name);
                    }
                    text_free(payload_decl);
                    fputs("static __attribute__((unused)) ", out);
                    fputs(payload->text, out);
                    fputc(' ', out);
                    fputs(inst->concrete, out);
                    fputs("_get_", out);
                    fputs(variant->name, out);
                    fputs("(struct ", out);
                    fputs(inst->concrete, out);
                    fputs("* self)\n{\n", out);
                    if (payload_type_has_pointer(payload->text)) {
                        fputs("    cminus_ptr_require_alive((void*)self->payload.", out);
                        fputs(variant->name, out);
                        fputs(", self->origin_kind, self->origin_stack_id, __FILE__, __LINE__);\n", out);
                    }
                    fputs("    return self->payload.", out);
                    fputs(variant->name, out);
                    fputs(";\n}\n", out);
                    text_free(payload);
                }
            }
        }
    }
}

static void emit_payload_enum_instances(FILE *out)
{
    FILE *stream = tmpfile();
    struct Text *generated;

    if (stream == NULL) {
        die("cannot create payload-enum generation stream");
    }
    emit_payload_enum_instances_direct(stream);
    generated = read_generated_stream(stream);
    fclose(stream);
    emit_generated_text(out, ND_PAYLOAD_HELPERS, "payload-enums", generated);
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

/*
 * In -bare mode the generated file must not pull in libc. Inline the bare
 * runtime (lib/c-bare.h) at the top of the output so the result is a single,
 * self-contained source the user can drop onto a board next to their putchar.
 */
static struct Text *build_bare_prelude(void)
{
    FILE *fp = open_cminus_include("c-bare.h");
    char buf[4096];
    size_t n;
    struct Text *text = text_new();

    if (fp == NULL) {
        fputs("c-: bare runtime not found: c-bare.h\n", stderr);
        exit(1);
    }
    while ((n = fread(buf, 1, sizeof(buf), fp)) > 0) {
        text_add_n(text, buf, n);
    }
    fclose(fp);
    return text;
}

int main(int argc, char **argv)
{
    int rc;
    int i;
    const char *input_path = NULL;
    struct Node *translation_unit = NULL;

    g_bare_metal = 0;
    g_no_heap = 0;
    g_c_compat = 0;
    g_dump_typed_ast = 0;
    for (i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-bare") == 0) {
            g_bare_metal = 1;
        } else if (strcmp(argv[i], "-no-heap") == 0) {
            g_no_heap = 1;
        } else if (strcmp(argv[i], "-c-compat") == 0 || strcmp(argv[i], "--c-compat") == 0) {
            g_c_compat = 1;
        } else if (strcmp(argv[i], "--dump-typed-ast") == 0) {
            g_dump_typed_ast = 1;
        } else if (input_path == NULL) {
            input_path = argv[i];
        } else {
            fputs("usage: c- [-bare] [-no-heap] [-c-compat] [--dump-typed-ast] input.c- > output.c\n", stderr);
            return 2;
        }
    }
    if (input_path == NULL) {
        fputs("usage: c- [-bare] [-no-heap] [-c-compat] [--dump-typed-ast] input.c- > output.c\n", stderr);
        return 2;
    }

    yyin = fopen(input_path, "r");
    if (yyin == NULL) {
        perror(input_path);
        return 1;
    }
    g_input_path = input_path;
    yylineno = 1;
    g_output = text_new();
    g_defines = text_new();
    g_thread_owned_helpers = text_new();
    g_thread_owned_entry_count = 0;
    g_thread_owned_helper_id = 0;
    g_consumed_directives = NULL;
    g_generated_artifacts = NULL;
    g_template_nodes = NULL;
    text_add(g_defines, "void cminus_panic(const char* message, const char* file, int line);\n");
    text_add(g_defines, "int cminus_ptr_classify(void* mem, unsigned long* stack_id_out);\n");
    text_add(g_defines, "void cminus_ptr_require_alive(void* mem, unsigned long kind, unsigned long stack_id, const char* file, int line);\n");
    text_add(g_defines, "__SIZE_TYPE__ cminus_stack_enter_impl(const char* file, int line, void* anchor);\n");
    text_add(g_defines, "void cminus_stack_leave_impl(__SIZE_TYPE__ id, const char* file, int line);\n");
    text_add(g_defines, "void* cminus_gc_calloc_impl(__SIZE_TYPE__ count, __SIZE_TYPE__ size, const char* file, int line);\n");
    text_add(g_defines, "void cminus_gc_free_impl(void* mem, const char* file, int line);\n");
    g_malloc_funcs.count = 0;
    g_typedefs.count = 0;
    typedef_alias_add_opaque("size_t");
    typedef_alias_add_opaque("ptrdiff_t");
    typedef_alias_add_opaque("intptr_t");
    typedef_alias_add_opaque("uintptr_t");
    typedef_alias_add_opaque("pthread_t");
    typedef_alias_add_opaque("pthread_mutex_t");
    typedef_alias_add_opaque("pthread_cond_t");
    typedef_alias_add_opaque("__builtin_va_list");
    typedef_alias_add_opaque("__SIZE_TYPE__");
    typedef_alias_add_opaque("__auto_type");
    register_builtin_owned_functions();
    g_right_value_id = 0;
    g_need_string_h = 0;
    g_need_stdlib_h = 0;
    g_need_stdio_h = 0;
    g_need_execinfo_h = 0;
    g_need_pthread_h = 0;
    g_need_sched_h = 0;
    {
        const char *emit_uniq = getenv("C_MINUS_EMIT_UNIQ");
        g_emit_uniq = emit_uniq == NULL || strcmp(emit_uniq, "0") != 0;
    }
    g_generic_structs.count = 0;
    g_generic_funcs.count = 0;
    g_payload_enums.count = 0;
    g_current_generic_kind = 0;
    g_current_generic_param[0] = '\0';
    g_current_payload_enum = 0;
    g_foreach_id = 0;
    g_index_id = 0;
    g_unsafe_depth = 0;
    if (!source_has_cminus_include(yyin)) {
        FILE *stdlib_fp = open_cminus_include("c-.h");
        if (stdlib_fp == NULL) {
            fputs("c-: include not found: c-.h\n", stderr);
            fclose(yyin);
            return 1;
        }
        cminus_push_include(stdlib_fp, 1);
    }

    rc = yyparse();
    if (rc != 0) {
        fclose(yyin);
        return 1;
    }
    {
        const char *p = g_output->text;
        struct Text *prefix_text = text_new();
        struct Text *source_text;
        struct Node *prefix_node = NULL;
        struct Node *source_node;

        emit_generated_text(stdout, ND_RUNTIME_PRELUDE, "declarations", g_defines);
        g_defines = NULL;
        while (strncmp(p, "#define", 7) == 0) {
            const char *nl = strchr(p, '\n');
            if (nl == NULL) {
                text_add(prefix_text, p);
                p += strlen(p);
                break;
            }
            text_add_n(prefix_text, p, (size_t)(nl + 1 - p));
            p = nl + 1;
        }
        if (prefix_text->len > 0) {
            prefix_node = ast_new(ND_SOURCE_PREFIX, prefix_text->text);
            strncpy(prefix_node->name, "leading-defines", NAME_MAX_LEN - 1);
            emit_ast_output(stdout, prefix_node);
        }
        text_free(prefix_text);
        if (g_bare_metal) {
            emit_generated_text(stdout, ND_RUNTIME_PRELUDE, "bare-runtime",
                                build_bare_prelude());
        } else {
            struct Text *includes = text_new();

            if (g_need_string_h) {
                text_add(includes, "#include <string.h>\n");
            }
            if (g_need_stdlib_h) {
                text_add(includes, "#include <stdlib.h>\n");
            }
            if (g_need_stdio_h) {
                text_add(includes, "#include <stdio.h>\n");
            }
            if (g_need_execinfo_h) {
                text_add(includes, "#include <execinfo.h>\n");
            }
            if (g_need_pthread_h) {
                text_add(includes, "#include <pthread.h>\n");
            }
            if (g_need_sched_h) {
                text_add(includes, "#include <sched.h>\n");
            }
            emit_generated_text(stdout, ND_RUNTIME_PRELUDE, "system-includes",
                                includes);
        }
        close_generic_instances();
        {
            struct GenericTemplate *span_ptr_at = generic_find(&g_generic_funcs, "Span_ptr_at");
            struct GenericTemplate *span_offset = generic_find(&g_generic_funcs, "Span_offset");
            if ((span_ptr_at != NULL && span_ptr_at->inst_count > 0) ||
                (span_offset != NULL && span_offset->inst_count > 0)) {
                struct Text *panic_decl = text_new();

                text_add(panic_decl, "void cminus_panic(const char* message, const char* file, int line);\n");
                emit_generated_text(stdout, ND_RUNTIME_PRELUDE,
                                    "generic-panic-declaration", panic_decl);
            }
        }
        emit_payload_enum_generic_dependencies(stdout);
        emit_payload_enum_instances(stdout);
        emit_generic_struct_instances(stdout);
        emit_generic_function_prototypes(stdout);
        source_text = text_new();
        text_add(source_text, p);
        if (source_text->len > 0 && source_text->text[source_text->len - 1] != '\n') {
            text_add_ch(source_text, '\n');
        }
        source_node = ast_new(ND_SOURCE_BODY, source_text->text);
        strncpy(source_node->name, "source", NAME_MAX_LEN - 1);
        source_node->body = g_output->ast;
        emit_ast_output(stdout, source_node);
        text_free(source_text);
        if (g_thread_owned_helpers->len > 0) {
            emit_generated_text(stdout, ND_EXPANSION,
                                "owned-thread-helpers",
                                g_thread_owned_helpers);
        } else {
            text_free(g_thread_owned_helpers);
        }
        g_thread_owned_helpers = NULL;
        emit_generic_function_instances(stdout);

        translation_unit = ast_new(ND_TRANSLATION_UNIT, NULL);
        if (prefix_node != NULL) {
            prefix_node->next = source_node;
            translation_unit->body = prefix_node;
        } else {
            translation_unit->body = source_node;
        }
    }
    ast_final_register_functions(translation_unit);
    ast_final_register_macro_constants(g_consumed_directives);
    ast_final_register_macro_constants(translation_unit);
    ast_final_register_functions(g_generated_artifacts);
    ast_final_resolve_nodes(translation_unit);
    ast_final_resolve_nodes(g_generated_artifacts);
    ast_final_resolve_nodes(g_template_nodes);
    validate_thread_spawn_safety(translation_unit, translation_unit);
    if (g_dump_typed_ast) {
        dump_typed_ast(stderr, g_consumed_directives, 0);
        dump_typed_ast(stderr, g_template_nodes, 0);
        dump_typed_ast(stderr, translation_unit, 0);
        dump_typed_ast(stderr, g_generated_artifacts, 0);
    }
    text_free(g_output);
    fclose(yyin);
    return 0;
}
