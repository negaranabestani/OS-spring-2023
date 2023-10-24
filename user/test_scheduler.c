#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/procinfo.h"

//struct procinfo info1;
void do_some() {
    // printf("here");
    int i;
    int N = 10000;
    int a[N], b[N];


    // // ,c[N];

    for (i = 0; i < N; i++) {
        a[i] = i;
        b[i] = i % 100 + 2000;
    }
    for (i = 0; i < N; i++) {
        a[i] = a[i] + b[i];
    }
    // printf("here2");
}

int
main(int argc, char **argv) {
    int fork_num = 32, pid = 23, n;

    for (n = 0; n < fork_num; n++) {
        if (pid > 0) {
            pid = fork();
        }
        if (pid < 0) {
            printf("error");
            break;
        }
        // printf("c");
        changeScheduler(pid,argv[1]);
        int i = 0, cnt = 0;
        for (i = 0; i < 1000000000; i++)
            cnt++;
        // do_some();
//            if(pid == 6){
        struct procinfo info1;
//        int id=getpid();
            printf("pid = %d",pid);
        if(pid==0){
            procinfo((uint64) & info1, getpid());
            printf("--------%d---------\n", getpid());
            printf("cpu_burst_time: %d\n", info1.cpu_burst_time);
            printf("turnaround_time: %d\n", info1.turnaround_time);
            printf("waiting_time: %d\n", info1.waiting_time);
            exit(0);
        }

//            }


    }
//    if (pid != 0) {
//        wait(0);
//    }
    for (int i = 0; i < 32; ++i) {
        wait(0);
    }
    struct procinfo info1;
    procinfo((uint64) & info1, getpid());
    printf("--------%d---------\n", getpid());
    printf("cpu_burst_time: %d\n", info1.cpu_burst_time);
    printf("turnaround_time: %d\n", info1.turnaround_time);
    printf("waiting_time: %d\n", info1.waiting_time);
    exit(0);
}