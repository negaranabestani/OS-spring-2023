#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/procinfo.h"
#include "kernel/param.h"

int
main(int argc, char **argv) {
    char *p;
    uint nu = 128*1024*1024;
    if(nu < 4096)
        nu = 4096;
    p = sbrk(nu/3*2);
    if(p == (char*)-1)
        return 0;
    fork();
    printf("done!");
    exit(0);
}