//
// Created by little-wolf on 3/25/23.
//
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc)
{
    int pticks=proctick(argc);
    printf("%d\n",pticks);
    exit(0);
}