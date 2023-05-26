#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/procinfo.h"


int
main(int argc, char **argv){

    int  i;
    int N = 10000;
    int a[N],b[N];
    
    
    // // ,c[N];

    for (i =0 ;i<N;i++){
        a[i] =i;
        b[i] = i%100 + 2000;
    }
   

    int fork_num = 5,pid,n;

    for(n =0;n<fork_num;n++){
        pid = fork();
        if(pid < 0)
            printf("error");
            // break;
        if(pid == 0 ){
            printf("p");
            wait(0);        
            }

        else{
            printf("c");
            changeScheduler(pid,argv[1]);
    
            for (i =0;i<N;i++){
                a[i]= a[i]+b[i];
            }

            struct procinfo info;
            procinfo((uint64)&info,pid);
            printf("cpu_burst_time: %d\n",info.cpu_burst_time);
            printf("turnaround_time: %d\n",info.turnaround_time);
            printf("waiting_time: %d\n",info.waiting_time);
    
    }}
    


  exit(0);
}