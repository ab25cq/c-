#include <pthread.h>

int cminus_test_pthread_create(pthread_t* thread,
                               const pthread_attr_t* attributes,
                               void* (*entry)(void*),
                               void* argument)
{
    (void)thread;
    (void)attributes;
    (void)entry;
    (void)argument;
    return 11;
}
