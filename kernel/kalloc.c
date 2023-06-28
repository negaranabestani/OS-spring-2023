// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

void krefinit(void *start, void *end);

void deckref(void *pa);

uint64 refindex(void *pa);

extern char end[]; // first address after kernel.
// defined by kernel.ld.

struct run {
    struct run *next;
};

struct {
    struct spinlock lock;
    struct run *freelist;
} kmem;
struct {
    struct spinlock lock;
    uint64 ref[(PHYSTOP - KERNBASE) / PGSIZE];
} kref;

void
kinit() {
    initlock(&kmem.lock, "kmem");
    initlock(&kref.lock, "kref");
    freerange(end, (void *) PHYSTOP);
    krefinit(end, (void *) PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end) {
    char *p;
    p = (char *) PGROUNDUP((uint64) pa_start);
    for (; p + PGSIZE <= (char *) pa_end; p += PGSIZE) {
        kfree(p);
    }
}

void krefinit(void *start, void *end) {
    char *p;
    p = (char *) PGROUNDUP((uint64) start);
    for (; p + PGSIZE <= (char *) end; p += PGSIZE)
        kref.ref[refindex((void *)p)] = 0;
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa) {
    struct run *r;

    if (((uint64) pa % PGSIZE) != 0 || (char *) pa < end || (uint64) pa >= PHYSTOP)
        panic("kfree");

    acquire(&kref.lock);
    if (kref.ref[refindex(pa)] > 1)
        kref.ref[refindex(pa)] = kref.ref[refindex(pa)] - 1;
    else {
        kref.ref[refindex(pa)] = kref.ref[refindex(pa)] - 1;
        // Fill with junk to catch dangling refs.
        memset(pa, 1, PGSIZE);

        r = (struct run *) pa;

        acquire(&kmem.lock);
        r->next = kmem.freelist;
        kmem.freelist = r;
        release(&kmem.lock);
    }
    release(&kref.lock);
}

uint64 refindex(void *pa) {
    return (PGROUNDDOWN((uint64) pa) - (uint64) end) / PGSIZE;
}

void inckref(void *pa) {
    acquire(&kref.lock);
    kref.ref[refindex(pa)] = kref.ref[refindex(pa)] + 1;
    release(&kref.lock);
}

void deckref(void *pa) {
    acquire(&kref.lock);
    kref.ref[refindex(pa)] = kref.ref[refindex(pa)] - 1;
    release(&kref.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void) {
    struct run *r;

    acquire(&kref.lock);
    acquire(&kmem.lock);
    r = kmem.freelist;
    if (r) {
        kmem.freelist = r->next;
        kref.ref[refindex(r)] = kref.ref[refindex(r)] + 1;
    }
    release(&kmem.lock);
    release(&kref.lock);

    if (r)
        memset((char *) r, 5, PGSIZE); // fill with junk
    return (void *) r;
}

int calculate_free_ram() {
    int free_bytes = 0;
    acquire(&kmem.lock);
    struct run *page = kmem.freelist;
    while (page->next != 0) {
        free_bytes += PGSIZE;
        page = page->next;
    }
    release(&kmem.lock);
    return free_bytes;
}