#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <execinfo.h>
struct __CMinusIndex_int{
    int tag;
    union {
        int Some;
    } payload;
};
enum {
    __CMinusIndex_int_TAG_Some,
    __CMinusIndex_int_TAG_None
};
static __attribute__((unused)) struct __CMinusIndex_int __CMinusIndex_int_Some(int value)
{
    struct __CMinusIndex_int out = {0};
    out.tag = __CMinusIndex_int_TAG_Some;
    out.payload.Some = value;
    return out;
}
static __attribute__((unused)) int __CMinusIndex_int_is_Some(struct __CMinusIndex_int* self)
{
    return self->tag == __CMinusIndex_int_TAG_Some;
}
static __attribute__((unused)) int __CMinusIndex_int_get_Some(struct __CMinusIndex_int* self)
{
    return self->payload.Some;
}
static __attribute__((unused)) struct __CMinusIndex_int __CMinusIndex_int_None(void)
{
    struct __CMinusIndex_int out = {0};
    out.tag = __CMinusIndex_int_TAG_None;
    return out;
}
static __attribute__((unused)) int __CMinusIndex_int_is_None(struct __CMinusIndex_int* self)
{
    return self->tag == __CMinusIndex_int_TAG_None;
}
struct Vec_int{
    int* data;
    int len;
    int cap;
};
struct Vec_Item{
    struct Item* data;
    int len;
    int cap;
};
struct ListNode_int{
    int value;
    struct ListNode_int* next;
};
struct List_int{
    struct ListNode_int* head;
    struct ListNode_int* tail;
    int len;
};
int Vec_first_int(struct Vec_int* self){
    return self->data[0];
}
struct __CMinusIndex_int Vec_get_opt_int(struct Vec_int* self, int index){
    if (self == NULL || index < 0 || index >= self->len) {
        return __CMinusIndex_int_None();
    }
    return __CMinusIndex_int_Some(self->data[index]);
}
struct List_int* List_new_int(void){
    return calloc(1, sizeof(struct List_int));
}
void List_push_int(struct List_int* self, int value){
    struct ListNode_int* node = calloc(1, sizeof(struct ListNode_int));

    if (node == NULL) {
        abort();
    }
    node->value = value;
    if (self->tail == NULL) {
        self->head = node;
        self->tail = node;
    } else {
        self->tail->next = node;
        self->tail = node;
    }
    self->len++;
}
void List_delete_int(struct List_int* self){
    struct ListNode_int* node;

    if (self == NULL) {
        return;
    }
    node = self->head;
    while (node != NULL) {
        struct ListNode_int* next = node->next;
        free(node);
        node = next;
    }
}
int List_first_int(struct List_int* self){
    return self->head->value;
}
struct __CMinusIndex_int List_get_opt_int(struct List_int* self, int index){
    struct ListNode_int* node;
    int i;

    if (self == NULL || index < 0 || index >= self->len) {
        return __CMinusIndex_int_None();
    }
    node = self->head;
    i = 0;
    while (i < index) {
        node = node->next;
        i++;
    }
    return __CMinusIndex_int_Some(node->value);
}

void cminus_panic(const char* message, const char* file, int line)
{
    void* frames[64] = {0};
    memset(&frames, 0, sizeof(frames));

    int count = {0};
    memset(&count, 0, sizeof(count));


    fprintf(stderr, "panic: %s at %s:%d\n", message, file, line);
    count = backtrace(frames, 64);
    backtrace_symbols_fd(frames, count, 2);
    abort();
}

struct Item {
    int value;
};

static __attribute__((unused)) struct Item* Item_clone(struct Item* self)
{
    struct Item* copy = calloc(1, sizeof(struct Item));
    if (copy == NULL || self == NULL) {
        return copy;
    }
    copy->value = self->value;
    return copy;
}


int main(void)
{
    int values[3] = {0};
    memset(&values, 0, sizeof(values));

    struct Item items[2] = {0};
    memset(&items, 0, sizeof(items));

    int sum = 0;
    int item_sum = 0;
    int list_sum = 0;
    struct Vec_int nums = {0};
    memset(&nums, 0, sizeof(nums));

    struct Vec_int* nums_ptr = {0};
    memset(&nums_ptr, 0, sizeof(nums_ptr));

    struct Vec_Item item_vec = {0};
    memset(&item_vec, 0, sizeof(item_vec));

    struct List_int* list = List_new_int();

    values[0] = 1;
    values[1] = 2;
    values[2] = 3;
    items[0].value = 4;
    items[1].value = 5;
    nums.data = values;
    nums.len = 3;
    nums_ptr = &nums;
    item_vec.data = items;
    item_vec.len = 2;
    for (int __foreach0 = 0, __foreach_once0 = 0; __foreach0 < nums.len; __foreach0++) for (__foreach_once0 = 1; __foreach_once0; __foreach_once0 = 0) for (int value = nums.data[__foreach0]; __foreach_once0; __foreach_once0 = 0) {
        sum += value;
    }
    for (int __foreach1 = 0, __foreach_once1 = 0; __foreach1 < item_vec.len; __foreach1++) for (__foreach_once1 = 1; __foreach_once1; __foreach_once1 = 0) for (struct Item item = item_vec.data[__foreach1]; __foreach_once1; __foreach_once1 = 0) {
        item_sum += item.value;
    }
    List_push_int(list, 6);
    List_push_int(list, 7);
    for (struct ListNode_int* __foreach_node2 = list->head; __foreach_node2 != NULL; __foreach_node2 = __foreach_node2->next) for (int __foreach_once2 = 1; __foreach_once2; __foreach_once2 = 0) for (int value = __foreach_node2->value; __foreach_once2; __foreach_once2 = 0) {
        list_sum += value;
    }
    if (Vec_first_int(&nums) != 1) {
        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    if (({ struct __CMinusIndex_int __index_result0 = Vec_get_opt_int(&nums, 1); if (__index_result0.tag == __CMinusIndex_int_TAG_None) { cminus_panic("index out of range", "tests/generics_foreach.c-", 46); } __index_result0.payload.Some; }) != 2) {
        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    if (Vec_first_int(nums_ptr) != 1) {
        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    if (List_first_int(list) != 6) {
        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    if (({ struct __CMinusIndex_int __index_result1 = List_get_opt_int(list, 1); if (__index_result1.tag == __CMinusIndex_int_TAG_None) { cminus_panic("index out of range", "tests/generics_foreach.c-", 55); } __index_result1.payload.Some; }) != 7) {
        if (list != NULL) {
            List_delete_int(list);
            free(list);
        }

        return 1;
    }
    if (list != NULL) {
        List_delete_int(list);
        free(list);
    }

    return sum == 6 && item_sum == 9 && list_sum == 13 ? 0 : 1;
}