//
// Console input and output, to the uart.
// Reads are line at a time.
// Implements special input characters:
//   newline -- end of line
//   control-h -- backspace
//   control-u -- kill line
//   control-d -- end of file
//   control-p -- print process list
//

#include <stdarg.h>

#include "types.h"
#include "console.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "fs.h"
#include "file.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "proc.h"

#define BACKSPACE 0x100
#define C(x)  ((x)-'@')  // Control-x

//
// send one character to the uart.
// called by printf(), and to echo input characters,
// but not from write().
//
void
consputc(int c) {
    if (c == BACKSPACE) {
        // if the user typed backspace, overwrite with a space.
        uartputc_sync('\b');
        uartputc_sync(' ');
        uartputc_sync('\b');
    } else {
        uartputc_sync(c);
    }
}

struct {
    struct spinlock lock;

    // input
#define INPUT_BUF_SIZE 128
    char buf[INPUT_BUF_SIZE];
    uint r;  // Read index
    uint w;  // Write index
    uint e;  // Edit index
} cons;
int firstSave = 1;
char charsToBeMoved[INPUT_BUF];// temporary storage for input.buf in a certain context
int oldcmd = 0;

/*
  this struct will hold the history buffer array
  For ex:
  If 5 commands are stored. In this case:
  * 11,12,13,14,15 indices are occupied in the history table with 11 as the newest.
  * lastCommandIndex == 11
  * currentHistory ranges from 0 to 4 (i.e the displacement)
  * init(currentHistory) = -1
*/
struct {
    char bufferArr[MAX_HISTORY][INPUT_BUF]; // holds the actual command strings -
    uint lengthsArr[MAX_HISTORY]; // this will hold the length of each command string
    uint lastCommandIndex;  // the index of the last command entered to history
    int numOfCommmandsInMem; // number of history commands in mem
    int currentHistory; // holds the current history view -> displacement from the last command index
} historyBufferArray;

//char oldBuf[INPUT_BUF]; // this will hold the details of the command that we were typing before accessing the history
//uint oldBufferLength;

//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n) {
    int i;

    for (i = 0; i < n; i++) {
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
            break;
        uartputc(c);
    }

    return i;
}

//
// user read()s from the console go here.
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n) {
    uint target;
    int c;
    char cbuf;

    target = n;
    acquire(&cons.lock);
    while (n > 0) {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w) {
            if (killed(myproc())) {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

        if (c == C('D')) {  // end-of-file
            if (n < target) {
                // Save ^D for next time, to make sure
                // caller gets a 0-byte result.
                cons.r--;
            }
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
            break;

        dst++;
        --n;

        if (c == '\n') {
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);

    return target - n;
}

//
// the console input interrupt handler.
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c) {
    acquire(&cons.lock);
    uint tempIndex;
//    printf("input: %d",c);
    switch (c) {
        case C('P'):  // Print process list.
            procdump();
            break;
        case C('U'):  // Kill line.
            while (cons.e != cons.w &&
                   cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n') {
                cons.e--;
                consputc(BACKSPACE);
            }
            break;
        case C('H'): // Backspace
        case '\x7f': // Delete key
            if (cons.e != cons.w) {
                cons.e--;
                consputc(BACKSPACE);
            }
            break;
        case UP_ARROW:

//            printf("up arrow pressed\n");
            if (historyBufferArray.currentHistory >=
                0) {// current history means the oldest possible will be MAX_HISTORY-1
                eraseCurrentLineOnScreen();
                // store the currently entered command (in the terminal) to the oldbuf
//                if (historyBufferArray.currentHistory == -1)
//                    copyCharsToBeMovedToOldBuffer();
//                printf("erased screen line\n");
//                eraseContentOnInputBuffer();
//                printf("erased input buffer\n");
                tempIndex = (historyBufferArray.currentHistory) % MAX_HISTORY;
                copyBufferToScreen(historyBufferArray.bufferArr[tempIndex], historyBufferArray.lengthsArr[tempIndex]);

//                printf("print buffer to screen\n");
                // copyBufferToInputBuffer(historyBufferArray.bufferArr[tempIndex],historyBufferArray.lengthsArr[tempIndex]);
                if (historyBufferArray.currentHistory == historyBufferArray.lastCommandIndex) {
                    oldcmd = 1;
                }
                if(historyBufferArray.currentHistory==0) {
                    historyBufferArray.currentHistory=historyBufferArray.lastCommandIndex;
                }
                historyBufferArray.currentHistory--;
                historyBufferArray.currentHistory = historyBufferArray.currentHistory % MAX_HISTORY;
            }
            break;
        case DOWN_ARROW:
//            printf("down arrow pressed\n");

//            eraseContentOnInputBuffer();
            if (historyBufferArray.currentHistory != -1) {
                eraseCurrentLineOnScreen();
                tempIndex = (historyBufferArray.currentHistory) % MAX_HISTORY;
                copyBufferToScreen(historyBufferArray.bufferArr[tempIndex],
                                   historyBufferArray.lengthsArr[tempIndex]);
//                    copyBufferToInputBuffer(historyBufferArray.bufferArr[tempIndex],historyBufferArray.lengthsArr[tempIndex]);
                if (historyBufferArray.currentHistory == historyBufferArray.lastCommandIndex) {
                    oldcmd = 1;
                    historyBufferArray.currentHistory=0;
                } else {
                    historyBufferArray.currentHistory++;
                    historyBufferArray.currentHistory = historyBufferArray.currentHistory % MAX_HISTORY;
                }
            }

            break;
        default:
            if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE) {
                c = (c == '\r') ? '\n' : c;

                // echo back to the user.
                consputc(c);

                // store for consumption by consoleread().
                cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;

                if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE) {
                    if (!oldcmd)
                        savecommandtohistory();
                    // wake up consoleread() if a whole line (or end-of-file)
                    // has arrived.
                    cons.w = cons.e;
                    wakeup(&cons.r);
                    oldcmd = 0;
                }
            }
//            historyBufferArray.currentHistory = historyBufferArray.lastCommandIndex;
            break;
    }

    release(&cons.lock);
}

void
consoleinit(void) {
    initlock(&cons.lock, "cons");

    uartinit();

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    devsw[CONSOLE].write = consolewrite;
}

int isHistory() {
    char *history = "history";
    for (uint i = 0; i < 7; i++) {
        if (cons.buf[(cons.r + i) % INPUT_BUF] != history[i])
            return 0;
    }
    return 1;
}

void savecommandtohistory() {
    if (!isHistory()) {
        uint len = cons.e - cons.r - 1; // -1 to remove the last '\n' character
        if (len == 0) return; // to avoid blank commands to store in history

        if (historyBufferArray.numOfCommmandsInMem < MAX_HISTORY) {
            historyBufferArray.numOfCommmandsInMem++;
            // when we get to MAX_HISTORY commands in memory we keep on inserting to the array in a circular manner
        }
        if (!firstSave)
            historyBufferArray.lastCommandIndex = (historyBufferArray.lastCommandIndex + 1) % MAX_HISTORY;
        else
            firstSave = 0;
//    if (historyBufferArray.lastCommandIndex!=0) {
//    }

        historyBufferArray.lengthsArr[historyBufferArray.lastCommandIndex] = len;

        // do not want to save in memory the last char '/n'

        for (uint i = 0; i < len; i++) {
            historyBufferArray.bufferArr[historyBufferArray.lastCommandIndex][i] = cons.buf[(cons.r + i) % INPUT_BUF];
        }
        historyBufferArray.currentHistory = historyBufferArray.lastCommandIndex;
//        printf("saved commnad: %s,index: %d\n", historyBufferArray.bufferArr[historyBufferArray.lastCommandIndex],
//               historyBufferArray.lastCommandIndex);
    }// reseting the users history current viewed

}


/*
  this is the function that gets called by the sys_history and writes the requested command history in the buffer
*/
int history(int historyId) {
    // historyId != index of command in historyBufferArray.bufferArr
    if (historyId < 0 || historyId > MAX_HISTORY - 1)
        return 2;
    if (historyId >= historyBufferArray.numOfCommmandsInMem)
        return 1;
//    consputc(BACKSPACE);
//    eraseCurrentLineOnScreen();
//    cons.e = cons.r;
//    copyBufferToScreen(historyBufferArray.bufferArr[tempIndex],historyBufferArray.lengthsArr[tempIndex]);
//    printf("%s\n", historyBufferArray.bufferArr[tempIndex]);
    for (uint i = 0; i < historyBufferArray.numOfCommmandsInMem; i++) {
        printf("%s\n",historyBufferArray.bufferArr[i]);
    }
    printf("requested command: %s\n",historyBufferArray.bufferArr[historyId]);


//    memset(&buffer, '\0', INPUT_BUF);



//    memmove(&buffer, historyBufferArray.bufferArr[tempIndex], historyBufferArray.lengthsArr[tempIndex]);
    return 0;
}

void
eraseCurrentLineOnScreen(void) {
    int length = cons.e - cons.r - 1;
    while (length != 1) {
        if (cons.e != cons.r) {
            consputc(BACKSPACE);
            length--;
        }
    }
    cons.e = cons.r;
}

//void
//copyCharsToBeMovedToOldBuffer(void) {
//    oldBufferLength = cons.e - cons.r;
//    for (uint i = 0; i < oldBufferLength; i++) {
//        oldBuf[i] = cons.buf[(cons.r + i) % INPUT_BUF];
//    }
//}

/*
  clear input buffer
*/
//void
//eraseContentOnInputBuffer() {
//    cons.e = cons.r;
//}

/*
  print bufToPrintOnScreen on-screen
*/
void
copyBufferToScreen(char *bufToPrintOnScreen, uint length) {
    uint i = 0;
//    cons.e+=3;
//    printf("print on screen: %s",bufToPrintOnScreen);
    while (i < length) {
        consputc(bufToPrintOnScreen[i]);
        cons.buf[(cons.r + i) % INPUT_BUF] = bufToPrintOnScreen[i];
        i++;
    }
    cons.e = cons.r + length;
}

/*
  Copy bufToSaveInInput to input.buf
  Set input.e and input.rightmost
  assumes input.r == input.w == input.rightmost == input.e
*/
//void
//copyBufferToInputBuffer(char *bufToSaveInInput, uint length) {
//    for (uint i = 0; i < length; i++) {
//        cons.buf[(cons.r + i) % INPUT_BUF] = bufToSaveInInput[i];
//    }
//
//    cons.e = cons.r + length;
//}