//
// Created by little-wolf on 4/4/23.
//
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/sysinfo.h"
struct sysinfo info;
int main(){
//    struct sysinfo info= {
//            .uptime = 0,
//            .totalram=0,
//            .freeram=0,
//            .procs=0
//    };
//    printf("before: %p\n",&info);
    sysinfo((uint64)&info);
//    printf("after: %p\n",&info);
    printf("uptime: %f\n",info.uptime);
    printf("total ram: %d\n",info.totalram);
    printf("free ram: %d\n",info.freeram);
    printf("active processes: %d\n",info.procs);
    return 0;
}