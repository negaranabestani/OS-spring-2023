//
// Created by little-wolf on 10/26/23.
//
#include "user/user.h"
#ifndef OS_SPRING_2023_THREAD_H
#define OS_SPRING_2023_THREAD_H

#endif //OS_SPRING_2023_THREAD_H
// Thread library definition
int thread_create(void (*function) (void *), void *arg);
int thread_join(int tid);