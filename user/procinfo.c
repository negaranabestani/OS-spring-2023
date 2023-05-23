//
// Created by little-wolf on 4/4/23.
//
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/procinfo.h"
struct procinfo info;
int main(int argc){
    procinfo((uint64)&info,argc);
//    printf("after: %p\n",&info);
    printf("cpu_burst_time: %d\n",info.cpu_burst_time);
    printf("turnaround_time: %d\n",info.turnaround_time);
    printf("waiting_time: %d\n",info.waiting_time);

    return 0;
}