#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/procinfo.h"


void do_some(){
    // printf("here");
    int  i;
    int N = 10000;
    int a[N],b[N];
    
    
    // // ,c[N];

    for (i =0 ;i<N;i++){
        a[i] =i;
        b[i] = i%100 + 2000;
    }
    for (i =0;i<N;i++){
                a[i]= a[i]+b[i];
    }
    // printf("here2");
}
int
main(int argc, char **argv){

    
   

    int fork_num = 5,pid,n;

    for(n =0;n<fork_num;n++){
        pid = fork();
        if(pid < 0){
            printf("error");
            break;}
        else{
            // printf("c");
            // changeScheduler(pid,argv[1]);
            int i= 0,cnt=0;
            for(i=0;i<1000000000;i++)
                cnt++;
            // do_some();
            if(pid == 6){
                struct procinfo info;
            procinfo((uint64)&info,pid);
            printf("cpu_burst_time: %d\n",info.cpu_burst_time);
            printf("turnaround_time: %d\n",info.turnaround_time);
            printf("waiting_time: %d\n",info.waiting_time);
            }
            
    
    }}
    


  exit(0);
}