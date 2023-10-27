//
// Created by little-wolf on 10/26/23.
//
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
int thread_create(void (*function) (void *), void *arg)
{
    void *stack = malloc(PGSIZE);

    if (stack == 0)
        return -1;
    if ((uint64)stack % PGSIZE != 0)
        stack += PGSIZE - ((uint64)stack % PGSIZE);

    return clone(function, arg, stack);
}

int thread_join(int tid)
{
    int retval;
    void *stack;
    retval = join(tid, &stack);
    free(stack);
    return retval;
}