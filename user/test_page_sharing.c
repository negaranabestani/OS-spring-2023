#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/procinfo.h"
#include "kernel/param.h"

int
main(int argc, char **argv) {
    printf("allocate 2/3 memory\n");

    char *p;
    uint nu = 2/3*(128*1024*1024);

    if(nu < 4096)
        nu = 4096;

    p = sbrk(nu);
    if(p == (char*)-1)
        return -1;

    printf("allocate is done\n");

    fork();

    printf("done!\n");
    return 0;
}