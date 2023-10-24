#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
//
// Created by little-wolf on 10/5/23.
//
//char *buff;
int
main(int argc, char *argv[])
{
    return history(atoi(argv[1]));
}
