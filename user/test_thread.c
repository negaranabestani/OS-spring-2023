//
// Created by little-wolf on 10/26/23.
//
#include "kernel/types.h"
#include "kernel/riscv.h"
#include "kernel/stat.h"
#include "user/thread.h"
int thread_create(void (*function) (void *), void *arg)
{
    void *stack = malloc(PGSIZE);

    if (stack == 0)
        return -1;
    if ((uint64)stack % PGSIZE != 0)
        stack += PGSIZE - ((uint64)stack % PGSIZE);
    printf("thread creat\n");
    int v=0;
    v=clone(function, arg, stack);
    printf("thread clone\n");
    return v;
}

int thread_join(int tid)
{
    int retval;
    void *stack;
    printf("thread join\n");
    retval = join(tid, &stack);
    free(stack);
    printf("end join\n");
    return retval;
}
int arr[20];
//
void function(void *arg)
{
    int num = *((int *)arg);
    for(int i = 0; i < 5; i++)
    {
        arr[num + i] =  num;
    }
}

int main(int argc, char *argv[])
{
    int tid[4];

    int arg0 = 0;
    int arg1 = 5;
    int arg2 = 10;
    int arg3 = 15;

    tid[0] = thread_create(&function, &arg0);
    tid[1] = thread_create(&function, &arg1);
    tid[2] = thread_create(&function, &arg2);
    tid[3] = thread_create(&function, &arg3);

    for(int i = 0; i < 4; i++)
    {
        thread_join(tid[i]);
    }

    for (int i = 0; i < 20; i++)
    {
        printf("[%d] = %d\n", i, arr[i]);
    }

    return 0;
}