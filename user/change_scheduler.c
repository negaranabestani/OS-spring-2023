#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char **argv)
{

 changeScheduler(atoi(argv[1]),argv[2]);

  exit(0);
}