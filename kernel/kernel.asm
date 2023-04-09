
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a2010113          	addi	sp,sp,-1504 # 80008a20 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	88e70713          	addi	a4,a4,-1906 # 800088e0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	c6c78793          	addi	a5,a5,-916 # 80005cd0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdcaaf>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e1678793          	addi	a5,a5,-490 # 80000ec4 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3d2080e7          	jalr	978(ra) # 800024fe <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	89650513          	addi	a0,a0,-1898 # 80010a20 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a90080e7          	jalr	-1392(ra) # 80000c22 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	88648493          	addi	s1,s1,-1914 # 80010a20 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	91690913          	addi	s2,s2,-1770 # 80010ab8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	838080e7          	jalr	-1992(ra) # 800019f8 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	180080e7          	jalr	384(ra) # 80002348 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	eca080e7          	jalr	-310(ra) # 800020a0 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	296080e7          	jalr	662(ra) # 800024a8 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00010517          	auipc	a0,0x10
    8000022a:	7fa50513          	addi	a0,a0,2042 # 80010a20 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	aa8080e7          	jalr	-1368(ra) # 80000cd6 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00010517          	auipc	a0,0x10
    80000240:	7e450513          	addi	a0,a0,2020 # 80010a20 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a92080e7          	jalr	-1390(ra) # 80000cd6 <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	84f72323          	sw	a5,-1978(a4) # 80010ab8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	75450513          	addi	a0,a0,1876 # 80010a20 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	94e080e7          	jalr	-1714(ra) # 80000c22 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	262080e7          	jalr	610(ra) # 80002554 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	72650513          	addi	a0,a0,1830 # 80010a20 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9d4080e7          	jalr	-1580(ra) # 80000cd6 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	70270713          	addi	a4,a4,1794 # 80010a20 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	6d878793          	addi	a5,a5,1752 # 80010a20 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7427a783          	lw	a5,1858(a5) # 80010ab8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	69670713          	addi	a4,a4,1686 # 80010a20 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	68648493          	addi	s1,s1,1670 # 80010a20 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	64a70713          	addi	a4,a4,1610 # 80010a20 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6cf72a23          	sw	a5,1748(a4) # 80010ac0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	60e78793          	addi	a5,a5,1550 # 80010a20 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	68c7a323          	sw	a2,1670(a5) # 80010abc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	67a50513          	addi	a0,a0,1658 # 80010ab8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	cbe080e7          	jalr	-834(ra) # 80002104 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5c050513          	addi	a0,a0,1472 # 80010a20 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	72a080e7          	jalr	1834(ra) # 80000b92 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	74078793          	addi	a5,a5,1856 # 80020bb8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5807ab23          	sw	zero,1430(a5) # 80010ae0 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	32f72123          	sw	a5,802(a4) # 800088a0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	526dad83          	lw	s11,1318(s11) # 80010ae0 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	4d050513          	addi	a0,a0,1232 # 80010ac8 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	622080e7          	jalr	1570(ra) # 80000c22 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	37250513          	addi	a0,a0,882 # 80010ac8 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	578080e7          	jalr	1400(ra) # 80000cd6 <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	35648493          	addi	s1,s1,854 # 80010ac8 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	40e080e7          	jalr	1038(ra) # 80000b92 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	31650513          	addi	a0,a0,790 # 80010ae8 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	3b8080e7          	jalr	952(ra) # 80000b92 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	3e0080e7          	jalr	992(ra) # 80000bd6 <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0a27a783          	lw	a5,162(a5) # 800088a0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	452080e7          	jalr	1106(ra) # 80000c76 <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0727b783          	ld	a5,114(a5) # 800088a8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	07273703          	ld	a4,114(a4) # 800088b0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	288a0a13          	addi	s4,s4,648 # 80010ae8 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	04048493          	addi	s1,s1,64 # 800088a8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	04098993          	addi	s3,s3,64 # 800088b0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	872080e7          	jalr	-1934(ra) # 80002104 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	21a50513          	addi	a0,a0,538 # 80010ae8 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	34c080e7          	jalr	844(ra) # 80000c22 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	fc27a783          	lw	a5,-62(a5) # 800088a0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	fc873703          	ld	a4,-56(a4) # 800088b0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	fb87b783          	ld	a5,-72(a5) # 800088a8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	1ec98993          	addi	s3,s3,492 # 80010ae8 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fa448493          	addi	s1,s1,-92 # 800088a8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fa490913          	addi	s2,s2,-92 # 800088b0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	784080e7          	jalr	1924(ra) # 800020a0 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1b648493          	addi	s1,s1,438 # 80010ae8 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	f6e7b523          	sd	a4,-150(a5) # 800088b0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	37e080e7          	jalr	894(ra) # 80000cd6 <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	12c48493          	addi	s1,s1,300 # 80010ae8 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	25c080e7          	jalr	604(ra) # 80000c22 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2fe080e7          	jalr	766(ra) # 80000cd6 <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00021797          	auipc	a5,0x21
    80000a02:	35278793          	addi	a5,a5,850 # 80021d50 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	308080e7          	jalr	776(ra) # 80000d1e <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	10290913          	addi	s2,s2,258 # 80010b20 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1fa080e7          	jalr	506(ra) # 80000c22 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	29a080e7          	jalr	666(ra) # 80000cd6 <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	06650513          	addi	a0,a0,102 # 80010b20 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	0d0080e7          	jalr	208(ra) # 80000b92 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	28250513          	addi	a0,a0,642 # 80021d50 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	03048493          	addi	s1,s1,48 # 80010b20 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	128080e7          	jalr	296(ra) # 80000c22 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	01850513          	addi	a0,a0,24 # 80010b20 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	1c4080e7          	jalr	452(ra) # 80000cd6 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1fe080e7          	jalr	510(ra) # 80000d1e <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	fec50513          	addi	a0,a0,-20 # 80010b20 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	19a080e7          	jalr	410(ra) # 80000cd6 <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <calculate_free_ram>:
int calculate_free_ram(){
    80000b46:	1101                	addi	sp,sp,-32
    80000b48:	ec06                	sd	ra,24(sp)
    80000b4a:	e822                	sd	s0,16(sp)
    80000b4c:	e426                	sd	s1,8(sp)
    80000b4e:	1000                	addi	s0,sp,32
    int free_bytes=0;
    acquire(&kmem.lock);
    80000b50:	00010497          	auipc	s1,0x10
    80000b54:	fd048493          	addi	s1,s1,-48 # 80010b20 <kmem>
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	0c8080e7          	jalr	200(ra) # 80000c22 <acquire>
    struct run *page=kmem.freelist;
    while (page->next!=0){
    80000b62:	6c9c                	ld	a5,24(s1)
    80000b64:	639c                	ld	a5,0(a5)
    80000b66:	c785                	beqz	a5,80000b8e <calculate_free_ram+0x48>
    int free_bytes=0;
    80000b68:	4481                	li	s1,0
        free_bytes+=PGSIZE;
    80000b6a:	6705                	lui	a4,0x1
    80000b6c:	9cb9                	addw	s1,s1,a4
    while (page->next!=0){
    80000b6e:	639c                	ld	a5,0(a5)
    80000b70:	fff5                	bnez	a5,80000b6c <calculate_free_ram+0x26>
        page=page->next;
    }
    release(&kmem.lock);
    80000b72:	00010517          	auipc	a0,0x10
    80000b76:	fae50513          	addi	a0,a0,-82 # 80010b20 <kmem>
    80000b7a:	00000097          	auipc	ra,0x0
    80000b7e:	15c080e7          	jalr	348(ra) # 80000cd6 <release>
    return free_bytes;
    80000b82:	8526                	mv	a0,s1
    80000b84:	60e2                	ld	ra,24(sp)
    80000b86:	6442                	ld	s0,16(sp)
    80000b88:	64a2                	ld	s1,8(sp)
    80000b8a:	6105                	addi	sp,sp,32
    80000b8c:	8082                	ret
    int free_bytes=0;
    80000b8e:	4481                	li	s1,0
    80000b90:	b7cd                	j	80000b72 <calculate_free_ram+0x2c>

0000000080000b92 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b92:	1141                	addi	sp,sp,-16
    80000b94:	e422                	sd	s0,8(sp)
    80000b96:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b98:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b9a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b9e:	00053823          	sd	zero,16(a0)
}
    80000ba2:	6422                	ld	s0,8(sp)
    80000ba4:	0141                	addi	sp,sp,16
    80000ba6:	8082                	ret

0000000080000ba8 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	411c                	lw	a5,0(a0)
    80000baa:	e399                	bnez	a5,80000bb0 <holding+0x8>
    80000bac:	4501                	li	a0,0
  return r;
}
    80000bae:	8082                	ret
{
    80000bb0:	1101                	addi	sp,sp,-32
    80000bb2:	ec06                	sd	ra,24(sp)
    80000bb4:	e822                	sd	s0,16(sp)
    80000bb6:	e426                	sd	s1,8(sp)
    80000bb8:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bba:	6904                	ld	s1,16(a0)
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e20080e7          	jalr	-480(ra) # 800019dc <mycpu>
    80000bc4:	40a48533          	sub	a0,s1,a0
    80000bc8:	00153513          	seqz	a0,a0
}
    80000bcc:	60e2                	ld	ra,24(sp)
    80000bce:	6442                	ld	s0,16(sp)
    80000bd0:	64a2                	ld	s1,8(sp)
    80000bd2:	6105                	addi	sp,sp,32
    80000bd4:	8082                	ret

0000000080000bd6 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000be0:	100024f3          	csrr	s1,sstatus
    80000be4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000be8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bea:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bee:	00001097          	auipc	ra,0x1
    80000bf2:	dee080e7          	jalr	-530(ra) # 800019dc <mycpu>
    80000bf6:	5d3c                	lw	a5,120(a0)
    80000bf8:	cf89                	beqz	a5,80000c12 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bfa:	00001097          	auipc	ra,0x1
    80000bfe:	de2080e7          	jalr	-542(ra) # 800019dc <mycpu>
    80000c02:	5d3c                	lw	a5,120(a0)
    80000c04:	2785                	addiw	a5,a5,1
    80000c06:	dd3c                	sw	a5,120(a0)
}
    80000c08:	60e2                	ld	ra,24(sp)
    80000c0a:	6442                	ld	s0,16(sp)
    80000c0c:	64a2                	ld	s1,8(sp)
    80000c0e:	6105                	addi	sp,sp,32
    80000c10:	8082                	ret
    mycpu()->intena = old;
    80000c12:	00001097          	auipc	ra,0x1
    80000c16:	dca080e7          	jalr	-566(ra) # 800019dc <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c1a:	8085                	srli	s1,s1,0x1
    80000c1c:	8885                	andi	s1,s1,1
    80000c1e:	dd64                	sw	s1,124(a0)
    80000c20:	bfe9                	j	80000bfa <push_off+0x24>

0000000080000c22 <acquire>:
{
    80000c22:	1101                	addi	sp,sp,-32
    80000c24:	ec06                	sd	ra,24(sp)
    80000c26:	e822                	sd	s0,16(sp)
    80000c28:	e426                	sd	s1,8(sp)
    80000c2a:	1000                	addi	s0,sp,32
    80000c2c:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c2e:	00000097          	auipc	ra,0x0
    80000c32:	fa8080e7          	jalr	-88(ra) # 80000bd6 <push_off>
  if(holding(lk))
    80000c36:	8526                	mv	a0,s1
    80000c38:	00000097          	auipc	ra,0x0
    80000c3c:	f70080e7          	jalr	-144(ra) # 80000ba8 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c40:	4705                	li	a4,1
  if(holding(lk))
    80000c42:	e115                	bnez	a0,80000c66 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c44:	87ba                	mv	a5,a4
    80000c46:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c4a:	2781                	sext.w	a5,a5
    80000c4c:	ffe5                	bnez	a5,80000c44 <acquire+0x22>
  __sync_synchronize();
    80000c4e:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c52:	00001097          	auipc	ra,0x1
    80000c56:	d8a080e7          	jalr	-630(ra) # 800019dc <mycpu>
    80000c5a:	e888                	sd	a0,16(s1)
}
    80000c5c:	60e2                	ld	ra,24(sp)
    80000c5e:	6442                	ld	s0,16(sp)
    80000c60:	64a2                	ld	s1,8(sp)
    80000c62:	6105                	addi	sp,sp,32
    80000c64:	8082                	ret
    panic("acquire");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	40a50513          	addi	a0,a0,1034 # 80008070 <digits+0x30>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8d0080e7          	jalr	-1840(ra) # 8000053e <panic>

0000000080000c76 <pop_off>:

void
pop_off(void)
{
    80000c76:	1141                	addi	sp,sp,-16
    80000c78:	e406                	sd	ra,8(sp)
    80000c7a:	e022                	sd	s0,0(sp)
    80000c7c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c7e:	00001097          	auipc	ra,0x1
    80000c82:	d5e080e7          	jalr	-674(ra) # 800019dc <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c8a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c8c:	e78d                	bnez	a5,80000cb6 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c8e:	5d3c                	lw	a5,120(a0)
    80000c90:	02f05b63          	blez	a5,80000cc6 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c94:	37fd                	addiw	a5,a5,-1
    80000c96:	0007871b          	sext.w	a4,a5
    80000c9a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c9c:	eb09                	bnez	a4,80000cae <pop_off+0x38>
    80000c9e:	5d7c                	lw	a5,124(a0)
    80000ca0:	c799                	beqz	a5,80000cae <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ca2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ca6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000caa:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cae:	60a2                	ld	ra,8(sp)
    80000cb0:	6402                	ld	s0,0(sp)
    80000cb2:	0141                	addi	sp,sp,16
    80000cb4:	8082                	ret
    panic("pop_off - interruptible");
    80000cb6:	00007517          	auipc	a0,0x7
    80000cba:	3c250513          	addi	a0,a0,962 # 80008078 <digits+0x38>
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	880080e7          	jalr	-1920(ra) # 8000053e <panic>
    panic("pop_off");
    80000cc6:	00007517          	auipc	a0,0x7
    80000cca:	3ca50513          	addi	a0,a0,970 # 80008090 <digits+0x50>
    80000cce:	00000097          	auipc	ra,0x0
    80000cd2:	870080e7          	jalr	-1936(ra) # 8000053e <panic>

0000000080000cd6 <release>:
{
    80000cd6:	1101                	addi	sp,sp,-32
    80000cd8:	ec06                	sd	ra,24(sp)
    80000cda:	e822                	sd	s0,16(sp)
    80000cdc:	e426                	sd	s1,8(sp)
    80000cde:	1000                	addi	s0,sp,32
    80000ce0:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ce2:	00000097          	auipc	ra,0x0
    80000ce6:	ec6080e7          	jalr	-314(ra) # 80000ba8 <holding>
    80000cea:	c115                	beqz	a0,80000d0e <release+0x38>
  lk->cpu = 0;
    80000cec:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cf0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cf4:	0f50000f          	fence	iorw,ow
    80000cf8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cfc:	00000097          	auipc	ra,0x0
    80000d00:	f7a080e7          	jalr	-134(ra) # 80000c76 <pop_off>
}
    80000d04:	60e2                	ld	ra,24(sp)
    80000d06:	6442                	ld	s0,16(sp)
    80000d08:	64a2                	ld	s1,8(sp)
    80000d0a:	6105                	addi	sp,sp,32
    80000d0c:	8082                	ret
    panic("release");
    80000d0e:	00007517          	auipc	a0,0x7
    80000d12:	38a50513          	addi	a0,a0,906 # 80008098 <digits+0x58>
    80000d16:	00000097          	auipc	ra,0x0
    80000d1a:	828080e7          	jalr	-2008(ra) # 8000053e <panic>

0000000080000d1e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d1e:	1141                	addi	sp,sp,-16
    80000d20:	e422                	sd	s0,8(sp)
    80000d22:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d24:	ca19                	beqz	a2,80000d3a <memset+0x1c>
    80000d26:	87aa                	mv	a5,a0
    80000d28:	1602                	slli	a2,a2,0x20
    80000d2a:	9201                	srli	a2,a2,0x20
    80000d2c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d30:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d34:	0785                	addi	a5,a5,1
    80000d36:	fee79de3          	bne	a5,a4,80000d30 <memset+0x12>
  }
  return dst;
}
    80000d3a:	6422                	ld	s0,8(sp)
    80000d3c:	0141                	addi	sp,sp,16
    80000d3e:	8082                	ret

0000000080000d40 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d46:	ca05                	beqz	a2,80000d76 <memcmp+0x36>
    80000d48:	fff6069b          	addiw	a3,a2,-1
    80000d4c:	1682                	slli	a3,a3,0x20
    80000d4e:	9281                	srli	a3,a3,0x20
    80000d50:	0685                	addi	a3,a3,1
    80000d52:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d54:	00054783          	lbu	a5,0(a0)
    80000d58:	0005c703          	lbu	a4,0(a1)
    80000d5c:	00e79863          	bne	a5,a4,80000d6c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d60:	0505                	addi	a0,a0,1
    80000d62:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d64:	fed518e3          	bne	a0,a3,80000d54 <memcmp+0x14>
  }

  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	a019                	j	80000d70 <memcmp+0x30>
      return *s1 - *s2;
    80000d6c:	40e7853b          	subw	a0,a5,a4
}
    80000d70:	6422                	ld	s0,8(sp)
    80000d72:	0141                	addi	sp,sp,16
    80000d74:	8082                	ret
  return 0;
    80000d76:	4501                	li	a0,0
    80000d78:	bfe5                	j	80000d70 <memcmp+0x30>

0000000080000d7a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d7a:	1141                	addi	sp,sp,-16
    80000d7c:	e422                	sd	s0,8(sp)
    80000d7e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d80:	c205                	beqz	a2,80000da0 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d82:	02a5e263          	bltu	a1,a0,80000da6 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d86:	1602                	slli	a2,a2,0x20
    80000d88:	9201                	srli	a2,a2,0x20
    80000d8a:	00c587b3          	add	a5,a1,a2
{
    80000d8e:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d90:	0585                	addi	a1,a1,1
    80000d92:	0705                	addi	a4,a4,1
    80000d94:	fff5c683          	lbu	a3,-1(a1)
    80000d98:	fed70fa3          	sb	a3,-1(a4) # fff <_entry-0x7ffff001>
    while(n-- > 0)
    80000d9c:	fef59ae3          	bne	a1,a5,80000d90 <memmove+0x16>

  return dst;
}
    80000da0:	6422                	ld	s0,8(sp)
    80000da2:	0141                	addi	sp,sp,16
    80000da4:	8082                	ret
  if(s < d && s + n > d){
    80000da6:	02061693          	slli	a3,a2,0x20
    80000daa:	9281                	srli	a3,a3,0x20
    80000dac:	00d58733          	add	a4,a1,a3
    80000db0:	fce57be3          	bgeu	a0,a4,80000d86 <memmove+0xc>
    d += n;
    80000db4:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000db6:	fff6079b          	addiw	a5,a2,-1
    80000dba:	1782                	slli	a5,a5,0x20
    80000dbc:	9381                	srli	a5,a5,0x20
    80000dbe:	fff7c793          	not	a5,a5
    80000dc2:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dc4:	177d                	addi	a4,a4,-1
    80000dc6:	16fd                	addi	a3,a3,-1
    80000dc8:	00074603          	lbu	a2,0(a4)
    80000dcc:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dd0:	fee79ae3          	bne	a5,a4,80000dc4 <memmove+0x4a>
    80000dd4:	b7f1                	j	80000da0 <memmove+0x26>

0000000080000dd6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd6:	1141                	addi	sp,sp,-16
    80000dd8:	e406                	sd	ra,8(sp)
    80000dda:	e022                	sd	s0,0(sp)
    80000ddc:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dde:	00000097          	auipc	ra,0x0
    80000de2:	f9c080e7          	jalr	-100(ra) # 80000d7a <memmove>
}
    80000de6:	60a2                	ld	ra,8(sp)
    80000de8:	6402                	ld	s0,0(sp)
    80000dea:	0141                	addi	sp,sp,16
    80000dec:	8082                	ret

0000000080000dee <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dee:	1141                	addi	sp,sp,-16
    80000df0:	e422                	sd	s0,8(sp)
    80000df2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000df4:	ce11                	beqz	a2,80000e10 <strncmp+0x22>
    80000df6:	00054783          	lbu	a5,0(a0)
    80000dfa:	cf89                	beqz	a5,80000e14 <strncmp+0x26>
    80000dfc:	0005c703          	lbu	a4,0(a1)
    80000e00:	00f71a63          	bne	a4,a5,80000e14 <strncmp+0x26>
    n--, p++, q++;
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	0505                	addi	a0,a0,1
    80000e08:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e0a:	f675                	bnez	a2,80000df6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e0c:	4501                	li	a0,0
    80000e0e:	a809                	j	80000e20 <strncmp+0x32>
    80000e10:	4501                	li	a0,0
    80000e12:	a039                	j	80000e20 <strncmp+0x32>
  if(n == 0)
    80000e14:	ca09                	beqz	a2,80000e26 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e16:	00054503          	lbu	a0,0(a0)
    80000e1a:	0005c783          	lbu	a5,0(a1)
    80000e1e:	9d1d                	subw	a0,a0,a5
}
    80000e20:	6422                	ld	s0,8(sp)
    80000e22:	0141                	addi	sp,sp,16
    80000e24:	8082                	ret
    return 0;
    80000e26:	4501                	li	a0,0
    80000e28:	bfe5                	j	80000e20 <strncmp+0x32>

0000000080000e2a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e2a:	1141                	addi	sp,sp,-16
    80000e2c:	e422                	sd	s0,8(sp)
    80000e2e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e30:	872a                	mv	a4,a0
    80000e32:	8832                	mv	a6,a2
    80000e34:	367d                	addiw	a2,a2,-1
    80000e36:	01005963          	blez	a6,80000e48 <strncpy+0x1e>
    80000e3a:	0705                	addi	a4,a4,1
    80000e3c:	0005c783          	lbu	a5,0(a1)
    80000e40:	fef70fa3          	sb	a5,-1(a4)
    80000e44:	0585                	addi	a1,a1,1
    80000e46:	f7f5                	bnez	a5,80000e32 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e48:	86ba                	mv	a3,a4
    80000e4a:	00c05c63          	blez	a2,80000e62 <strncpy+0x38>
    *s++ = 0;
    80000e4e:	0685                	addi	a3,a3,1
    80000e50:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e54:	fff6c793          	not	a5,a3
    80000e58:	9fb9                	addw	a5,a5,a4
    80000e5a:	010787bb          	addw	a5,a5,a6
    80000e5e:	fef048e3          	bgtz	a5,80000e4e <strncpy+0x24>
  return os;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret

0000000080000e68 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e68:	1141                	addi	sp,sp,-16
    80000e6a:	e422                	sd	s0,8(sp)
    80000e6c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e6e:	02c05363          	blez	a2,80000e94 <safestrcpy+0x2c>
    80000e72:	fff6069b          	addiw	a3,a2,-1
    80000e76:	1682                	slli	a3,a3,0x20
    80000e78:	9281                	srli	a3,a3,0x20
    80000e7a:	96ae                	add	a3,a3,a1
    80000e7c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e7e:	00d58963          	beq	a1,a3,80000e90 <safestrcpy+0x28>
    80000e82:	0585                	addi	a1,a1,1
    80000e84:	0785                	addi	a5,a5,1
    80000e86:	fff5c703          	lbu	a4,-1(a1)
    80000e8a:	fee78fa3          	sb	a4,-1(a5)
    80000e8e:	fb65                	bnez	a4,80000e7e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e90:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e94:	6422                	ld	s0,8(sp)
    80000e96:	0141                	addi	sp,sp,16
    80000e98:	8082                	ret

0000000080000e9a <strlen>:

int
strlen(const char *s)
{
    80000e9a:	1141                	addi	sp,sp,-16
    80000e9c:	e422                	sd	s0,8(sp)
    80000e9e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ea0:	00054783          	lbu	a5,0(a0)
    80000ea4:	cf91                	beqz	a5,80000ec0 <strlen+0x26>
    80000ea6:	0505                	addi	a0,a0,1
    80000ea8:	87aa                	mv	a5,a0
    80000eaa:	4685                	li	a3,1
    80000eac:	9e89                	subw	a3,a3,a0
    80000eae:	00f6853b          	addw	a0,a3,a5
    80000eb2:	0785                	addi	a5,a5,1
    80000eb4:	fff7c703          	lbu	a4,-1(a5)
    80000eb8:	fb7d                	bnez	a4,80000eae <strlen+0x14>
    ;
  return n;
}
    80000eba:	6422                	ld	s0,8(sp)
    80000ebc:	0141                	addi	sp,sp,16
    80000ebe:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ec0:	4501                	li	a0,0
    80000ec2:	bfe5                	j	80000eba <strlen+0x20>

0000000080000ec4 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ec4:	1141                	addi	sp,sp,-16
    80000ec6:	e406                	sd	ra,8(sp)
    80000ec8:	e022                	sd	s0,0(sp)
    80000eca:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ecc:	00001097          	auipc	ra,0x1
    80000ed0:	b00080e7          	jalr	-1280(ra) # 800019cc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ed4:	00008717          	auipc	a4,0x8
    80000ed8:	9e470713          	addi	a4,a4,-1564 # 800088b8 <started>
  if(cpuid() == 0){
    80000edc:	c139                	beqz	a0,80000f22 <main+0x5e>
    while(started == 0)
    80000ede:	431c                	lw	a5,0(a4)
    80000ee0:	2781                	sext.w	a5,a5
    80000ee2:	dff5                	beqz	a5,80000ede <main+0x1a>
      ;
    __sync_synchronize();
    80000ee4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee8:	00001097          	auipc	ra,0x1
    80000eec:	ae4080e7          	jalr	-1308(ra) # 800019cc <cpuid>
    80000ef0:	85aa                	mv	a1,a0
    80000ef2:	00007517          	auipc	a0,0x7
    80000ef6:	1c650513          	addi	a0,a0,454 # 800080b8 <digits+0x78>
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	68e080e7          	jalr	1678(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000f02:	00000097          	auipc	ra,0x0
    80000f06:	0d8080e7          	jalr	216(ra) # 80000fda <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f0a:	00002097          	auipc	ra,0x2
    80000f0e:	84e080e7          	jalr	-1970(ra) # 80002758 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f12:	00005097          	auipc	ra,0x5
    80000f16:	dfe080e7          	jalr	-514(ra) # 80005d10 <plicinithart>
  }

  scheduler();        
    80000f1a:	00001097          	auipc	ra,0x1
    80000f1e:	fd4080e7          	jalr	-44(ra) # 80001eee <scheduler>
    consoleinit();
    80000f22:	fffff097          	auipc	ra,0xfffff
    80000f26:	52e080e7          	jalr	1326(ra) # 80000450 <consoleinit>
    printfinit();
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	83e080e7          	jalr	-1986(ra) # 80000768 <printfinit>
    printf("\n");
    80000f32:	00007517          	auipc	a0,0x7
    80000f36:	19650513          	addi	a0,a0,406 # 800080c8 <digits+0x88>
    80000f3a:	fffff097          	auipc	ra,0xfffff
    80000f3e:	64e080e7          	jalr	1614(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f42:	00007517          	auipc	a0,0x7
    80000f46:	15e50513          	addi	a0,a0,350 # 800080a0 <digits+0x60>
    80000f4a:	fffff097          	auipc	ra,0xfffff
    80000f4e:	63e080e7          	jalr	1598(ra) # 80000588 <printf>
    printf("\n");
    80000f52:	00007517          	auipc	a0,0x7
    80000f56:	17650513          	addi	a0,a0,374 # 800080c8 <digits+0x88>
    80000f5a:	fffff097          	auipc	ra,0xfffff
    80000f5e:	62e080e7          	jalr	1582(ra) # 80000588 <printf>
    kinit();         // physical page allocator //free all the pages of physical memory from the address after kernel to phystop
    80000f62:	00000097          	auipc	ra,0x0
    80000f66:	b48080e7          	jalr	-1208(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table// making a direct map
    80000f6a:	00000097          	auipc	ra,0x0
    80000f6e:	326080e7          	jalr	806(ra) # 80001290 <kvminit>
    kvminithart();   // turn on paging
    80000f72:	00000097          	auipc	ra,0x0
    80000f76:	068080e7          	jalr	104(ra) # 80000fda <kvminithart>
    procinit();      // process table
    80000f7a:	00001097          	auipc	ra,0x1
    80000f7e:	99e080e7          	jalr	-1634(ra) # 80001918 <procinit>
    trapinit();      // trap vectors
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	7ae080e7          	jalr	1966(ra) # 80002730 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f8a:	00001097          	auipc	ra,0x1
    80000f8e:	7ce080e7          	jalr	1998(ra) # 80002758 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f92:	00005097          	auipc	ra,0x5
    80000f96:	d68080e7          	jalr	-664(ra) # 80005cfa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f9a:	00005097          	auipc	ra,0x5
    80000f9e:	d76080e7          	jalr	-650(ra) # 80005d10 <plicinithart>
    binit();         // buffer cache
    80000fa2:	00002097          	auipc	ra,0x2
    80000fa6:	f1c080e7          	jalr	-228(ra) # 80002ebe <binit>
    iinit();         // inode table
    80000faa:	00002097          	auipc	ra,0x2
    80000fae:	5c0080e7          	jalr	1472(ra) # 8000356a <iinit>
    fileinit();      // file table
    80000fb2:	00003097          	auipc	ra,0x3
    80000fb6:	55e080e7          	jalr	1374(ra) # 80004510 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fba:	00005097          	auipc	ra,0x5
    80000fbe:	e5e080e7          	jalr	-418(ra) # 80005e18 <virtio_disk_init>
    userinit();      // first user process
    80000fc2:	00001097          	auipc	ra,0x1
    80000fc6:	d0e080e7          	jalr	-754(ra) # 80001cd0 <userinit>
    __sync_synchronize();
    80000fca:	0ff0000f          	fence
    started = 1;
    80000fce:	4785                	li	a5,1
    80000fd0:	00008717          	auipc	a4,0x8
    80000fd4:	8ef72423          	sw	a5,-1816(a4) # 800088b8 <started>
    80000fd8:	b789                	j	80000f1a <main+0x56>

0000000080000fda <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fda:	1141                	addi	sp,sp,-16
    80000fdc:	e422                	sd	s0,8(sp)
    80000fde:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fe0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe4:	00008797          	auipc	a5,0x8
    80000fe8:	8dc7b783          	ld	a5,-1828(a5) # 800088c0 <kernel_pagetable>
    80000fec:	83b1                	srli	a5,a5,0xc
    80000fee:	577d                	li	a4,-1
    80000ff0:	177e                	slli	a4,a4,0x3f
    80000ff2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000ff8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000ffc:	6422                	ld	s0,8(sp)
    80000ffe:	0141                	addi	sp,sp,16
    80001000:	8082                	ret

0000000080001002 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001002:	7139                	addi	sp,sp,-64
    80001004:	fc06                	sd	ra,56(sp)
    80001006:	f822                	sd	s0,48(sp)
    80001008:	f426                	sd	s1,40(sp)
    8000100a:	f04a                	sd	s2,32(sp)
    8000100c:	ec4e                	sd	s3,24(sp)
    8000100e:	e852                	sd	s4,16(sp)
    80001010:	e456                	sd	s5,8(sp)
    80001012:	e05a                	sd	s6,0(sp)
    80001014:	0080                	addi	s0,sp,64
    80001016:	84aa                	mv	s1,a0
    80001018:	89ae                	mv	s3,a1
    8000101a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000101c:	57fd                	li	a5,-1
    8000101e:	83e9                	srli	a5,a5,0x1a
    80001020:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001022:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001024:	04b7f263          	bgeu	a5,a1,80001068 <walk+0x66>
    panic("walk");
    80001028:	00007517          	auipc	a0,0x7
    8000102c:	0a850513          	addi	a0,a0,168 # 800080d0 <digits+0x90>
    80001030:	fffff097          	auipc	ra,0xfffff
    80001034:	50e080e7          	jalr	1294(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001038:	060a8663          	beqz	s5,800010a4 <walk+0xa2>
    8000103c:	00000097          	auipc	ra,0x0
    80001040:	aaa080e7          	jalr	-1366(ra) # 80000ae6 <kalloc>
    80001044:	84aa                	mv	s1,a0
    80001046:	c529                	beqz	a0,80001090 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001048:	6605                	lui	a2,0x1
    8000104a:	4581                	li	a1,0
    8000104c:	00000097          	auipc	ra,0x0
    80001050:	cd2080e7          	jalr	-814(ra) # 80000d1e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001054:	00c4d793          	srli	a5,s1,0xc
    80001058:	07aa                	slli	a5,a5,0xa
    8000105a:	0017e793          	ori	a5,a5,1
    8000105e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001062:	3a5d                	addiw	s4,s4,-9
    80001064:	036a0063          	beq	s4,s6,80001084 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001068:	0149d933          	srl	s2,s3,s4
    8000106c:	1ff97913          	andi	s2,s2,511
    80001070:	090e                	slli	s2,s2,0x3
    80001072:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001074:	00093483          	ld	s1,0(s2)
    80001078:	0014f793          	andi	a5,s1,1
    8000107c:	dfd5                	beqz	a5,80001038 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000107e:	80a9                	srli	s1,s1,0xa
    80001080:	04b2                	slli	s1,s1,0xc
    80001082:	b7c5                	j	80001062 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001084:	00c9d513          	srli	a0,s3,0xc
    80001088:	1ff57513          	andi	a0,a0,511
    8000108c:	050e                	slli	a0,a0,0x3
    8000108e:	9526                	add	a0,a0,s1
}
    80001090:	70e2                	ld	ra,56(sp)
    80001092:	7442                	ld	s0,48(sp)
    80001094:	74a2                	ld	s1,40(sp)
    80001096:	7902                	ld	s2,32(sp)
    80001098:	69e2                	ld	s3,24(sp)
    8000109a:	6a42                	ld	s4,16(sp)
    8000109c:	6aa2                	ld	s5,8(sp)
    8000109e:	6b02                	ld	s6,0(sp)
    800010a0:	6121                	addi	sp,sp,64
    800010a2:	8082                	ret
        return 0;
    800010a4:	4501                	li	a0,0
    800010a6:	b7ed                	j	80001090 <walk+0x8e>

00000000800010a8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010a8:	57fd                	li	a5,-1
    800010aa:	83e9                	srli	a5,a5,0x1a
    800010ac:	00b7f463          	bgeu	a5,a1,800010b4 <walkaddr+0xc>
    return 0;
    800010b0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b2:	8082                	ret
{
    800010b4:	1141                	addi	sp,sp,-16
    800010b6:	e406                	sd	ra,8(sp)
    800010b8:	e022                	sd	s0,0(sp)
    800010ba:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010bc:	4601                	li	a2,0
    800010be:	00000097          	auipc	ra,0x0
    800010c2:	f44080e7          	jalr	-188(ra) # 80001002 <walk>
  if(pte == 0)
    800010c6:	c105                	beqz	a0,800010e6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010c8:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010ca:	0117f693          	andi	a3,a5,17
    800010ce:	4745                	li	a4,17
    return 0;
    800010d0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d2:	00e68663          	beq	a3,a4,800010de <walkaddr+0x36>
}
    800010d6:	60a2                	ld	ra,8(sp)
    800010d8:	6402                	ld	s0,0(sp)
    800010da:	0141                	addi	sp,sp,16
    800010dc:	8082                	ret
  pa = PTE2PA(*pte);
    800010de:	00a7d513          	srli	a0,a5,0xa
    800010e2:	0532                	slli	a0,a0,0xc
  return pa;
    800010e4:	bfcd                	j	800010d6 <walkaddr+0x2e>
    return 0;
    800010e6:	4501                	li	a0,0
    800010e8:	b7fd                	j	800010d6 <walkaddr+0x2e>

00000000800010ea <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ea:	715d                	addi	sp,sp,-80
    800010ec:	e486                	sd	ra,72(sp)
    800010ee:	e0a2                	sd	s0,64(sp)
    800010f0:	fc26                	sd	s1,56(sp)
    800010f2:	f84a                	sd	s2,48(sp)
    800010f4:	f44e                	sd	s3,40(sp)
    800010f6:	f052                	sd	s4,32(sp)
    800010f8:	ec56                	sd	s5,24(sp)
    800010fa:	e85a                	sd	s6,16(sp)
    800010fc:	e45e                	sd	s7,8(sp)
    800010fe:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001100:	c639                	beqz	a2,8000114e <mappages+0x64>
    80001102:	8aaa                	mv	s5,a0
    80001104:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001106:	77fd                	lui	a5,0xfffff
    80001108:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    8000110c:	15fd                	addi	a1,a1,-1
    8000110e:	00c589b3          	add	s3,a1,a2
    80001112:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001116:	8952                	mv	s2,s4
    80001118:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000111c:	6b85                	lui	s7,0x1
    8000111e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001122:	4605                	li	a2,1
    80001124:	85ca                	mv	a1,s2
    80001126:	8556                	mv	a0,s5
    80001128:	00000097          	auipc	ra,0x0
    8000112c:	eda080e7          	jalr	-294(ra) # 80001002 <walk>
    80001130:	cd1d                	beqz	a0,8000116e <mappages+0x84>
    if(*pte & PTE_V)
    80001132:	611c                	ld	a5,0(a0)
    80001134:	8b85                	andi	a5,a5,1
    80001136:	e785                	bnez	a5,8000115e <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001138:	80b1                	srli	s1,s1,0xc
    8000113a:	04aa                	slli	s1,s1,0xa
    8000113c:	0164e4b3          	or	s1,s1,s6
    80001140:	0014e493          	ori	s1,s1,1
    80001144:	e104                	sd	s1,0(a0)
    if(a == last)
    80001146:	05390063          	beq	s2,s3,80001186 <mappages+0x9c>
    a += PGSIZE;
    8000114a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114c:	bfc9                	j	8000111e <mappages+0x34>
    panic("mappages: size");
    8000114e:	00007517          	auipc	a0,0x7
    80001152:	f8a50513          	addi	a0,a0,-118 # 800080d8 <digits+0x98>
    80001156:	fffff097          	auipc	ra,0xfffff
    8000115a:	3e8080e7          	jalr	1000(ra) # 8000053e <panic>
      panic("mappages: remap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f8a50513          	addi	a0,a0,-118 # 800080e8 <digits+0xa8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>
      return -1;
    8000116e:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001170:	60a6                	ld	ra,72(sp)
    80001172:	6406                	ld	s0,64(sp)
    80001174:	74e2                	ld	s1,56(sp)
    80001176:	7942                	ld	s2,48(sp)
    80001178:	79a2                	ld	s3,40(sp)
    8000117a:	7a02                	ld	s4,32(sp)
    8000117c:	6ae2                	ld	s5,24(sp)
    8000117e:	6b42                	ld	s6,16(sp)
    80001180:	6ba2                	ld	s7,8(sp)
    80001182:	6161                	addi	sp,sp,80
    80001184:	8082                	ret
  return 0;
    80001186:	4501                	li	a0,0
    80001188:	b7e5                	j	80001170 <mappages+0x86>

000000008000118a <kvmmap>:
{
    8000118a:	1141                	addi	sp,sp,-16
    8000118c:	e406                	sd	ra,8(sp)
    8000118e:	e022                	sd	s0,0(sp)
    80001190:	0800                	addi	s0,sp,16
    80001192:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001194:	86b2                	mv	a3,a2
    80001196:	863e                	mv	a2,a5
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	f52080e7          	jalr	-174(ra) # 800010ea <mappages>
    800011a0:	e509                	bnez	a0,800011aa <kvmmap+0x20>
}
    800011a2:	60a2                	ld	ra,8(sp)
    800011a4:	6402                	ld	s0,0(sp)
    800011a6:	0141                	addi	sp,sp,16
    800011a8:	8082                	ret
    panic("kvmmap");
    800011aa:	00007517          	auipc	a0,0x7
    800011ae:	f4e50513          	addi	a0,a0,-178 # 800080f8 <digits+0xb8>
    800011b2:	fffff097          	auipc	ra,0xfffff
    800011b6:	38c080e7          	jalr	908(ra) # 8000053e <panic>

00000000800011ba <kvmmake>:
{
    800011ba:	1101                	addi	sp,sp,-32
    800011bc:	ec06                	sd	ra,24(sp)
    800011be:	e822                	sd	s0,16(sp)
    800011c0:	e426                	sd	s1,8(sp)
    800011c2:	e04a                	sd	s2,0(sp)
    800011c4:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	920080e7          	jalr	-1760(ra) # 80000ae6 <kalloc>
    800011ce:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011d0:	6605                	lui	a2,0x1
    800011d2:	4581                	li	a1,0
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	b4a080e7          	jalr	-1206(ra) # 80000d1e <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011dc:	4719                	li	a4,6
    800011de:	6685                	lui	a3,0x1
    800011e0:	10000637          	lui	a2,0x10000
    800011e4:	100005b7          	lui	a1,0x10000
    800011e8:	8526                	mv	a0,s1
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	fa0080e7          	jalr	-96(ra) # 8000118a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011f2:	4719                	li	a4,6
    800011f4:	6685                	lui	a3,0x1
    800011f6:	10001637          	lui	a2,0x10001
    800011fa:	100015b7          	lui	a1,0x10001
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f8a080e7          	jalr	-118(ra) # 8000118a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	004006b7          	lui	a3,0x400
    8000120e:	0c000637          	lui	a2,0xc000
    80001212:	0c0005b7          	lui	a1,0xc000
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f72080e7          	jalr	-142(ra) # 8000118a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001220:	00007917          	auipc	s2,0x7
    80001224:	de090913          	addi	s2,s2,-544 # 80008000 <etext>
    80001228:	4729                	li	a4,10
    8000122a:	80007697          	auipc	a3,0x80007
    8000122e:	dd668693          	addi	a3,a3,-554 # 8000 <_entry-0x7fff8000>
    80001232:	4605                	li	a2,1
    80001234:	067e                	slli	a2,a2,0x1f
    80001236:	85b2                	mv	a1,a2
    80001238:	8526                	mv	a0,s1
    8000123a:	00000097          	auipc	ra,0x0
    8000123e:	f50080e7          	jalr	-176(ra) # 8000118a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001242:	4719                	li	a4,6
    80001244:	46c5                	li	a3,17
    80001246:	06ee                	slli	a3,a3,0x1b
    80001248:	412686b3          	sub	a3,a3,s2
    8000124c:	864a                	mv	a2,s2
    8000124e:	85ca                	mv	a1,s2
    80001250:	8526                	mv	a0,s1
    80001252:	00000097          	auipc	ra,0x0
    80001256:	f38080e7          	jalr	-200(ra) # 8000118a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000125a:	4729                	li	a4,10
    8000125c:	6685                	lui	a3,0x1
    8000125e:	00006617          	auipc	a2,0x6
    80001262:	da260613          	addi	a2,a2,-606 # 80007000 <_trampoline>
    80001266:	040005b7          	lui	a1,0x4000
    8000126a:	15fd                	addi	a1,a1,-1
    8000126c:	05b2                	slli	a1,a1,0xc
    8000126e:	8526                	mv	a0,s1
    80001270:	00000097          	auipc	ra,0x0
    80001274:	f1a080e7          	jalr	-230(ra) # 8000118a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001278:	8526                	mv	a0,s1
    8000127a:	00000097          	auipc	ra,0x0
    8000127e:	608080e7          	jalr	1544(ra) # 80001882 <proc_mapstacks>
}
    80001282:	8526                	mv	a0,s1
    80001284:	60e2                	ld	ra,24(sp)
    80001286:	6442                	ld	s0,16(sp)
    80001288:	64a2                	ld	s1,8(sp)
    8000128a:	6902                	ld	s2,0(sp)
    8000128c:	6105                	addi	sp,sp,32
    8000128e:	8082                	ret

0000000080001290 <kvminit>:
{
    80001290:	1141                	addi	sp,sp,-16
    80001292:	e406                	sd	ra,8(sp)
    80001294:	e022                	sd	s0,0(sp)
    80001296:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001298:	00000097          	auipc	ra,0x0
    8000129c:	f22080e7          	jalr	-222(ra) # 800011ba <kvmmake>
    800012a0:	00007797          	auipc	a5,0x7
    800012a4:	62a7b023          	sd	a0,1568(a5) # 800088c0 <kernel_pagetable>
}
    800012a8:	60a2                	ld	ra,8(sp)
    800012aa:	6402                	ld	s0,0(sp)
    800012ac:	0141                	addi	sp,sp,16
    800012ae:	8082                	ret

00000000800012b0 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012b0:	715d                	addi	sp,sp,-80
    800012b2:	e486                	sd	ra,72(sp)
    800012b4:	e0a2                	sd	s0,64(sp)
    800012b6:	fc26                	sd	s1,56(sp)
    800012b8:	f84a                	sd	s2,48(sp)
    800012ba:	f44e                	sd	s3,40(sp)
    800012bc:	f052                	sd	s4,32(sp)
    800012be:	ec56                	sd	s5,24(sp)
    800012c0:	e85a                	sd	s6,16(sp)
    800012c2:	e45e                	sd	s7,8(sp)
    800012c4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c6:	03459793          	slli	a5,a1,0x34
    800012ca:	e795                	bnez	a5,800012f6 <uvmunmap+0x46>
    800012cc:	8a2a                	mv	s4,a0
    800012ce:	892e                	mv	s2,a1
    800012d0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d2:	0632                	slli	a2,a2,0xc
    800012d4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012d8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012da:	6b05                	lui	s6,0x1
    800012dc:	0735e263          	bltu	a1,s3,80001340 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012e0:	60a6                	ld	ra,72(sp)
    800012e2:	6406                	ld	s0,64(sp)
    800012e4:	74e2                	ld	s1,56(sp)
    800012e6:	7942                	ld	s2,48(sp)
    800012e8:	79a2                	ld	s3,40(sp)
    800012ea:	7a02                	ld	s4,32(sp)
    800012ec:	6ae2                	ld	s5,24(sp)
    800012ee:	6b42                	ld	s6,16(sp)
    800012f0:	6ba2                	ld	s7,8(sp)
    800012f2:	6161                	addi	sp,sp,80
    800012f4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e0a50513          	addi	a0,a0,-502 # 80008100 <digits+0xc0>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	240080e7          	jalr	576(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    80001306:	00007517          	auipc	a0,0x7
    8000130a:	e1250513          	addi	a0,a0,-494 # 80008118 <digits+0xd8>
    8000130e:	fffff097          	auipc	ra,0xfffff
    80001312:	230080e7          	jalr	560(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001316:	00007517          	auipc	a0,0x7
    8000131a:	e1250513          	addi	a0,a0,-494 # 80008128 <digits+0xe8>
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	220080e7          	jalr	544(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    80001326:	00007517          	auipc	a0,0x7
    8000132a:	e1a50513          	addi	a0,a0,-486 # 80008140 <digits+0x100>
    8000132e:	fffff097          	auipc	ra,0xfffff
    80001332:	210080e7          	jalr	528(ra) # 8000053e <panic>
    *pte = 0;
    80001336:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000133a:	995a                	add	s2,s2,s6
    8000133c:	fb3972e3          	bgeu	s2,s3,800012e0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001340:	4601                	li	a2,0
    80001342:	85ca                	mv	a1,s2
    80001344:	8552                	mv	a0,s4
    80001346:	00000097          	auipc	ra,0x0
    8000134a:	cbc080e7          	jalr	-836(ra) # 80001002 <walk>
    8000134e:	84aa                	mv	s1,a0
    80001350:	d95d                	beqz	a0,80001306 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001352:	6108                	ld	a0,0(a0)
    80001354:	00157793          	andi	a5,a0,1
    80001358:	dfdd                	beqz	a5,80001316 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000135a:	3ff57793          	andi	a5,a0,1023
    8000135e:	fd7784e3          	beq	a5,s7,80001326 <uvmunmap+0x76>
    if(do_free){
    80001362:	fc0a8ae3          	beqz	s5,80001336 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001366:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001368:	0532                	slli	a0,a0,0xc
    8000136a:	fffff097          	auipc	ra,0xfffff
    8000136e:	680080e7          	jalr	1664(ra) # 800009ea <kfree>
    80001372:	b7d1                	j	80001336 <uvmunmap+0x86>

0000000080001374 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001374:	1101                	addi	sp,sp,-32
    80001376:	ec06                	sd	ra,24(sp)
    80001378:	e822                	sd	s0,16(sp)
    8000137a:	e426                	sd	s1,8(sp)
    8000137c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000137e:	fffff097          	auipc	ra,0xfffff
    80001382:	768080e7          	jalr	1896(ra) # 80000ae6 <kalloc>
    80001386:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001388:	c519                	beqz	a0,80001396 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000138a:	6605                	lui	a2,0x1
    8000138c:	4581                	li	a1,0
    8000138e:	00000097          	auipc	ra,0x0
    80001392:	990080e7          	jalr	-1648(ra) # 80000d1e <memset>
  return pagetable;
}
    80001396:	8526                	mv	a0,s1
    80001398:	60e2                	ld	ra,24(sp)
    8000139a:	6442                	ld	s0,16(sp)
    8000139c:	64a2                	ld	s1,8(sp)
    8000139e:	6105                	addi	sp,sp,32
    800013a0:	8082                	ret

00000000800013a2 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013a2:	7179                	addi	sp,sp,-48
    800013a4:	f406                	sd	ra,40(sp)
    800013a6:	f022                	sd	s0,32(sp)
    800013a8:	ec26                	sd	s1,24(sp)
    800013aa:	e84a                	sd	s2,16(sp)
    800013ac:	e44e                	sd	s3,8(sp)
    800013ae:	e052                	sd	s4,0(sp)
    800013b0:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013b2:	6785                	lui	a5,0x1
    800013b4:	04f67863          	bgeu	a2,a5,80001404 <uvmfirst+0x62>
    800013b8:	8a2a                	mv	s4,a0
    800013ba:	89ae                	mv	s3,a1
    800013bc:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013be:	fffff097          	auipc	ra,0xfffff
    800013c2:	728080e7          	jalr	1832(ra) # 80000ae6 <kalloc>
    800013c6:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013c8:	6605                	lui	a2,0x1
    800013ca:	4581                	li	a1,0
    800013cc:	00000097          	auipc	ra,0x0
    800013d0:	952080e7          	jalr	-1710(ra) # 80000d1e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013d4:	4779                	li	a4,30
    800013d6:	86ca                	mv	a3,s2
    800013d8:	6605                	lui	a2,0x1
    800013da:	4581                	li	a1,0
    800013dc:	8552                	mv	a0,s4
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	d0c080e7          	jalr	-756(ra) # 800010ea <mappages>
  memmove(mem, src, sz);
    800013e6:	8626                	mv	a2,s1
    800013e8:	85ce                	mv	a1,s3
    800013ea:	854a                	mv	a0,s2
    800013ec:	00000097          	auipc	ra,0x0
    800013f0:	98e080e7          	jalr	-1650(ra) # 80000d7a <memmove>
}
    800013f4:	70a2                	ld	ra,40(sp)
    800013f6:	7402                	ld	s0,32(sp)
    800013f8:	64e2                	ld	s1,24(sp)
    800013fa:	6942                	ld	s2,16(sp)
    800013fc:	69a2                	ld	s3,8(sp)
    800013fe:	6a02                	ld	s4,0(sp)
    80001400:	6145                	addi	sp,sp,48
    80001402:	8082                	ret
    panic("uvmfirst: more than a page");
    80001404:	00007517          	auipc	a0,0x7
    80001408:	d5450513          	addi	a0,a0,-684 # 80008158 <digits+0x118>
    8000140c:	fffff097          	auipc	ra,0xfffff
    80001410:	132080e7          	jalr	306(ra) # 8000053e <panic>

0000000080001414 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001414:	1101                	addi	sp,sp,-32
    80001416:	ec06                	sd	ra,24(sp)
    80001418:	e822                	sd	s0,16(sp)
    8000141a:	e426                	sd	s1,8(sp)
    8000141c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000141e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001420:	00b67d63          	bgeu	a2,a1,8000143a <uvmdealloc+0x26>
    80001424:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001426:	6785                	lui	a5,0x1
    80001428:	17fd                	addi	a5,a5,-1
    8000142a:	00f60733          	add	a4,a2,a5
    8000142e:	767d                	lui	a2,0xfffff
    80001430:	8f71                	and	a4,a4,a2
    80001432:	97ae                	add	a5,a5,a1
    80001434:	8ff1                	and	a5,a5,a2
    80001436:	00f76863          	bltu	a4,a5,80001446 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000143a:	8526                	mv	a0,s1
    8000143c:	60e2                	ld	ra,24(sp)
    8000143e:	6442                	ld	s0,16(sp)
    80001440:	64a2                	ld	s1,8(sp)
    80001442:	6105                	addi	sp,sp,32
    80001444:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001446:	8f99                	sub	a5,a5,a4
    80001448:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000144a:	4685                	li	a3,1
    8000144c:	0007861b          	sext.w	a2,a5
    80001450:	85ba                	mv	a1,a4
    80001452:	00000097          	auipc	ra,0x0
    80001456:	e5e080e7          	jalr	-418(ra) # 800012b0 <uvmunmap>
    8000145a:	b7c5                	j	8000143a <uvmdealloc+0x26>

000000008000145c <uvmalloc>:
  if(newsz < oldsz)
    8000145c:	0ab66563          	bltu	a2,a1,80001506 <uvmalloc+0xaa>
{
    80001460:	7139                	addi	sp,sp,-64
    80001462:	fc06                	sd	ra,56(sp)
    80001464:	f822                	sd	s0,48(sp)
    80001466:	f426                	sd	s1,40(sp)
    80001468:	f04a                	sd	s2,32(sp)
    8000146a:	ec4e                	sd	s3,24(sp)
    8000146c:	e852                	sd	s4,16(sp)
    8000146e:	e456                	sd	s5,8(sp)
    80001470:	e05a                	sd	s6,0(sp)
    80001472:	0080                	addi	s0,sp,64
    80001474:	8aaa                	mv	s5,a0
    80001476:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001478:	6985                	lui	s3,0x1
    8000147a:	19fd                	addi	s3,s3,-1
    8000147c:	95ce                	add	a1,a1,s3
    8000147e:	79fd                	lui	s3,0xfffff
    80001480:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001484:	08c9f363          	bgeu	s3,a2,8000150a <uvmalloc+0xae>
    80001488:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000148a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	658080e7          	jalr	1624(ra) # 80000ae6 <kalloc>
    80001496:	84aa                	mv	s1,a0
    if(mem == 0){
    80001498:	c51d                	beqz	a0,800014c6 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000149a:	6605                	lui	a2,0x1
    8000149c:	4581                	li	a1,0
    8000149e:	00000097          	auipc	ra,0x0
    800014a2:	880080e7          	jalr	-1920(ra) # 80000d1e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014a6:	875a                	mv	a4,s6
    800014a8:	86a6                	mv	a3,s1
    800014aa:	6605                	lui	a2,0x1
    800014ac:	85ca                	mv	a1,s2
    800014ae:	8556                	mv	a0,s5
    800014b0:	00000097          	auipc	ra,0x0
    800014b4:	c3a080e7          	jalr	-966(ra) # 800010ea <mappages>
    800014b8:	e90d                	bnez	a0,800014ea <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ba:	6785                	lui	a5,0x1
    800014bc:	993e                	add	s2,s2,a5
    800014be:	fd4968e3          	bltu	s2,s4,8000148e <uvmalloc+0x32>
  return newsz;
    800014c2:	8552                	mv	a0,s4
    800014c4:	a809                	j	800014d6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014c6:	864e                	mv	a2,s3
    800014c8:	85ca                	mv	a1,s2
    800014ca:	8556                	mv	a0,s5
    800014cc:	00000097          	auipc	ra,0x0
    800014d0:	f48080e7          	jalr	-184(ra) # 80001414 <uvmdealloc>
      return 0;
    800014d4:	4501                	li	a0,0
}
    800014d6:	70e2                	ld	ra,56(sp)
    800014d8:	7442                	ld	s0,48(sp)
    800014da:	74a2                	ld	s1,40(sp)
    800014dc:	7902                	ld	s2,32(sp)
    800014de:	69e2                	ld	s3,24(sp)
    800014e0:	6a42                	ld	s4,16(sp)
    800014e2:	6aa2                	ld	s5,8(sp)
    800014e4:	6b02                	ld	s6,0(sp)
    800014e6:	6121                	addi	sp,sp,64
    800014e8:	8082                	ret
      kfree(mem);
    800014ea:	8526                	mv	a0,s1
    800014ec:	fffff097          	auipc	ra,0xfffff
    800014f0:	4fe080e7          	jalr	1278(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014f4:	864e                	mv	a2,s3
    800014f6:	85ca                	mv	a1,s2
    800014f8:	8556                	mv	a0,s5
    800014fa:	00000097          	auipc	ra,0x0
    800014fe:	f1a080e7          	jalr	-230(ra) # 80001414 <uvmdealloc>
      return 0;
    80001502:	4501                	li	a0,0
    80001504:	bfc9                	j	800014d6 <uvmalloc+0x7a>
    return oldsz;
    80001506:	852e                	mv	a0,a1
}
    80001508:	8082                	ret
  return newsz;
    8000150a:	8532                	mv	a0,a2
    8000150c:	b7e9                	j	800014d6 <uvmalloc+0x7a>

000000008000150e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000150e:	7179                	addi	sp,sp,-48
    80001510:	f406                	sd	ra,40(sp)
    80001512:	f022                	sd	s0,32(sp)
    80001514:	ec26                	sd	s1,24(sp)
    80001516:	e84a                	sd	s2,16(sp)
    80001518:	e44e                	sd	s3,8(sp)
    8000151a:	e052                	sd	s4,0(sp)
    8000151c:	1800                	addi	s0,sp,48
    8000151e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001520:	84aa                	mv	s1,a0
    80001522:	6905                	lui	s2,0x1
    80001524:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001526:	4985                	li	s3,1
    80001528:	a821                	j	80001540 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000152a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000152c:	0532                	slli	a0,a0,0xc
    8000152e:	00000097          	auipc	ra,0x0
    80001532:	fe0080e7          	jalr	-32(ra) # 8000150e <freewalk>
      pagetable[i] = 0;
    80001536:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000153a:	04a1                	addi	s1,s1,8
    8000153c:	03248163          	beq	s1,s2,8000155e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001540:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001542:	00f57793          	andi	a5,a0,15
    80001546:	ff3782e3          	beq	a5,s3,8000152a <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000154a:	8905                	andi	a0,a0,1
    8000154c:	d57d                	beqz	a0,8000153a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000154e:	00007517          	auipc	a0,0x7
    80001552:	c2a50513          	addi	a0,a0,-982 # 80008178 <digits+0x138>
    80001556:	fffff097          	auipc	ra,0xfffff
    8000155a:	fe8080e7          	jalr	-24(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000155e:	8552                	mv	a0,s4
    80001560:	fffff097          	auipc	ra,0xfffff
    80001564:	48a080e7          	jalr	1162(ra) # 800009ea <kfree>
}
    80001568:	70a2                	ld	ra,40(sp)
    8000156a:	7402                	ld	s0,32(sp)
    8000156c:	64e2                	ld	s1,24(sp)
    8000156e:	6942                	ld	s2,16(sp)
    80001570:	69a2                	ld	s3,8(sp)
    80001572:	6a02                	ld	s4,0(sp)
    80001574:	6145                	addi	sp,sp,48
    80001576:	8082                	ret

0000000080001578 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001578:	1101                	addi	sp,sp,-32
    8000157a:	ec06                	sd	ra,24(sp)
    8000157c:	e822                	sd	s0,16(sp)
    8000157e:	e426                	sd	s1,8(sp)
    80001580:	1000                	addi	s0,sp,32
    80001582:	84aa                	mv	s1,a0
  if(sz > 0)
    80001584:	e999                	bnez	a1,8000159a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001586:	8526                	mv	a0,s1
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	f86080e7          	jalr	-122(ra) # 8000150e <freewalk>
}
    80001590:	60e2                	ld	ra,24(sp)
    80001592:	6442                	ld	s0,16(sp)
    80001594:	64a2                	ld	s1,8(sp)
    80001596:	6105                	addi	sp,sp,32
    80001598:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000159a:	6605                	lui	a2,0x1
    8000159c:	167d                	addi	a2,a2,-1
    8000159e:	962e                	add	a2,a2,a1
    800015a0:	4685                	li	a3,1
    800015a2:	8231                	srli	a2,a2,0xc
    800015a4:	4581                	li	a1,0
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	d0a080e7          	jalr	-758(ra) # 800012b0 <uvmunmap>
    800015ae:	bfe1                	j	80001586 <uvmfree+0xe>

00000000800015b0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015b0:	c679                	beqz	a2,8000167e <uvmcopy+0xce>
{
    800015b2:	715d                	addi	sp,sp,-80
    800015b4:	e486                	sd	ra,72(sp)
    800015b6:	e0a2                	sd	s0,64(sp)
    800015b8:	fc26                	sd	s1,56(sp)
    800015ba:	f84a                	sd	s2,48(sp)
    800015bc:	f44e                	sd	s3,40(sp)
    800015be:	f052                	sd	s4,32(sp)
    800015c0:	ec56                	sd	s5,24(sp)
    800015c2:	e85a                	sd	s6,16(sp)
    800015c4:	e45e                	sd	s7,8(sp)
    800015c6:	0880                	addi	s0,sp,80
    800015c8:	8b2a                	mv	s6,a0
    800015ca:	8aae                	mv	s5,a1
    800015cc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015ce:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015d0:	4601                	li	a2,0
    800015d2:	85ce                	mv	a1,s3
    800015d4:	855a                	mv	a0,s6
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	a2c080e7          	jalr	-1492(ra) # 80001002 <walk>
    800015de:	c531                	beqz	a0,8000162a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015e0:	6118                	ld	a4,0(a0)
    800015e2:	00177793          	andi	a5,a4,1
    800015e6:	cbb1                	beqz	a5,8000163a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015e8:	00a75593          	srli	a1,a4,0xa
    800015ec:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015f0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	4f2080e7          	jalr	1266(ra) # 80000ae6 <kalloc>
    800015fc:	892a                	mv	s2,a0
    800015fe:	c939                	beqz	a0,80001654 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001600:	6605                	lui	a2,0x1
    80001602:	85de                	mv	a1,s7
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	776080e7          	jalr	1910(ra) # 80000d7a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000160c:	8726                	mv	a4,s1
    8000160e:	86ca                	mv	a3,s2
    80001610:	6605                	lui	a2,0x1
    80001612:	85ce                	mv	a1,s3
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	ad4080e7          	jalr	-1324(ra) # 800010ea <mappages>
    8000161e:	e515                	bnez	a0,8000164a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001620:	6785                	lui	a5,0x1
    80001622:	99be                	add	s3,s3,a5
    80001624:	fb49e6e3          	bltu	s3,s4,800015d0 <uvmcopy+0x20>
    80001628:	a081                	j	80001668 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000162a:	00007517          	auipc	a0,0x7
    8000162e:	b5e50513          	addi	a0,a0,-1186 # 80008188 <digits+0x148>
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	f0c080e7          	jalr	-244(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000163a:	00007517          	auipc	a0,0x7
    8000163e:	b6e50513          	addi	a0,a0,-1170 # 800081a8 <digits+0x168>
    80001642:	fffff097          	auipc	ra,0xfffff
    80001646:	efc080e7          	jalr	-260(ra) # 8000053e <panic>
      kfree(mem);
    8000164a:	854a                	mv	a0,s2
    8000164c:	fffff097          	auipc	ra,0xfffff
    80001650:	39e080e7          	jalr	926(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001654:	4685                	li	a3,1
    80001656:	00c9d613          	srli	a2,s3,0xc
    8000165a:	4581                	li	a1,0
    8000165c:	8556                	mv	a0,s5
    8000165e:	00000097          	auipc	ra,0x0
    80001662:	c52080e7          	jalr	-942(ra) # 800012b0 <uvmunmap>
  return -1;
    80001666:	557d                	li	a0,-1
}
    80001668:	60a6                	ld	ra,72(sp)
    8000166a:	6406                	ld	s0,64(sp)
    8000166c:	74e2                	ld	s1,56(sp)
    8000166e:	7942                	ld	s2,48(sp)
    80001670:	79a2                	ld	s3,40(sp)
    80001672:	7a02                	ld	s4,32(sp)
    80001674:	6ae2                	ld	s5,24(sp)
    80001676:	6b42                	ld	s6,16(sp)
    80001678:	6ba2                	ld	s7,8(sp)
    8000167a:	6161                	addi	sp,sp,80
    8000167c:	8082                	ret
  return 0;
    8000167e:	4501                	li	a0,0
}
    80001680:	8082                	ret

0000000080001682 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001682:	1141                	addi	sp,sp,-16
    80001684:	e406                	sd	ra,8(sp)
    80001686:	e022                	sd	s0,0(sp)
    80001688:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000168a:	4601                	li	a2,0
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	976080e7          	jalr	-1674(ra) # 80001002 <walk>
  if(pte == 0)
    80001694:	c901                	beqz	a0,800016a4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001696:	611c                	ld	a5,0(a0)
    80001698:	9bbd                	andi	a5,a5,-17
    8000169a:	e11c                	sd	a5,0(a0)
}
    8000169c:	60a2                	ld	ra,8(sp)
    8000169e:	6402                	ld	s0,0(sp)
    800016a0:	0141                	addi	sp,sp,16
    800016a2:	8082                	ret
    panic("uvmclear");
    800016a4:	00007517          	auipc	a0,0x7
    800016a8:	b2450513          	addi	a0,a0,-1244 # 800081c8 <digits+0x188>
    800016ac:	fffff097          	auipc	ra,0xfffff
    800016b0:	e92080e7          	jalr	-366(ra) # 8000053e <panic>

00000000800016b4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016b4:	c6bd                	beqz	a3,80001722 <copyout+0x6e>
{
    800016b6:	715d                	addi	sp,sp,-80
    800016b8:	e486                	sd	ra,72(sp)
    800016ba:	e0a2                	sd	s0,64(sp)
    800016bc:	fc26                	sd	s1,56(sp)
    800016be:	f84a                	sd	s2,48(sp)
    800016c0:	f44e                	sd	s3,40(sp)
    800016c2:	f052                	sd	s4,32(sp)
    800016c4:	ec56                	sd	s5,24(sp)
    800016c6:	e85a                	sd	s6,16(sp)
    800016c8:	e45e                	sd	s7,8(sp)
    800016ca:	e062                	sd	s8,0(sp)
    800016cc:	0880                	addi	s0,sp,80
    800016ce:	8b2a                	mv	s6,a0
    800016d0:	8c2e                	mv	s8,a1
    800016d2:	8a32                	mv	s4,a2
    800016d4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016d6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016d8:	6a85                	lui	s5,0x1
    800016da:	a015                	j	800016fe <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016dc:	9562                	add	a0,a0,s8
    800016de:	0004861b          	sext.w	a2,s1
    800016e2:	85d2                	mv	a1,s4
    800016e4:	41250533          	sub	a0,a0,s2
    800016e8:	fffff097          	auipc	ra,0xfffff
    800016ec:	692080e7          	jalr	1682(ra) # 80000d7a <memmove>

    len -= n;
    800016f0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016f4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016f6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016fa:	02098263          	beqz	s3,8000171e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016fe:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001702:	85ca                	mv	a1,s2
    80001704:	855a                	mv	a0,s6
    80001706:	00000097          	auipc	ra,0x0
    8000170a:	9a2080e7          	jalr	-1630(ra) # 800010a8 <walkaddr>
    if(pa0 == 0)
    8000170e:	cd01                	beqz	a0,80001726 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001710:	418904b3          	sub	s1,s2,s8
    80001714:	94d6                	add	s1,s1,s5
    if(n > len)
    80001716:	fc99f3e3          	bgeu	s3,s1,800016dc <copyout+0x28>
    8000171a:	84ce                	mv	s1,s3
    8000171c:	b7c1                	j	800016dc <copyout+0x28>
  }
  return 0;
    8000171e:	4501                	li	a0,0
    80001720:	a021                	j	80001728 <copyout+0x74>
    80001722:	4501                	li	a0,0
}
    80001724:	8082                	ret
      return -1;
    80001726:	557d                	li	a0,-1
}
    80001728:	60a6                	ld	ra,72(sp)
    8000172a:	6406                	ld	s0,64(sp)
    8000172c:	74e2                	ld	s1,56(sp)
    8000172e:	7942                	ld	s2,48(sp)
    80001730:	79a2                	ld	s3,40(sp)
    80001732:	7a02                	ld	s4,32(sp)
    80001734:	6ae2                	ld	s5,24(sp)
    80001736:	6b42                	ld	s6,16(sp)
    80001738:	6ba2                	ld	s7,8(sp)
    8000173a:	6c02                	ld	s8,0(sp)
    8000173c:	6161                	addi	sp,sp,80
    8000173e:	8082                	ret

0000000080001740 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001740:	caa5                	beqz	a3,800017b0 <copyin+0x70>
{
    80001742:	715d                	addi	sp,sp,-80
    80001744:	e486                	sd	ra,72(sp)
    80001746:	e0a2                	sd	s0,64(sp)
    80001748:	fc26                	sd	s1,56(sp)
    8000174a:	f84a                	sd	s2,48(sp)
    8000174c:	f44e                	sd	s3,40(sp)
    8000174e:	f052                	sd	s4,32(sp)
    80001750:	ec56                	sd	s5,24(sp)
    80001752:	e85a                	sd	s6,16(sp)
    80001754:	e45e                	sd	s7,8(sp)
    80001756:	e062                	sd	s8,0(sp)
    80001758:	0880                	addi	s0,sp,80
    8000175a:	8b2a                	mv	s6,a0
    8000175c:	8a2e                	mv	s4,a1
    8000175e:	8c32                	mv	s8,a2
    80001760:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001762:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001764:	6a85                	lui	s5,0x1
    80001766:	a01d                	j	8000178c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001768:	018505b3          	add	a1,a0,s8
    8000176c:	0004861b          	sext.w	a2,s1
    80001770:	412585b3          	sub	a1,a1,s2
    80001774:	8552                	mv	a0,s4
    80001776:	fffff097          	auipc	ra,0xfffff
    8000177a:	604080e7          	jalr	1540(ra) # 80000d7a <memmove>

    len -= n;
    8000177e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001782:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001784:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001788:	02098263          	beqz	s3,800017ac <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000178c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001790:	85ca                	mv	a1,s2
    80001792:	855a                	mv	a0,s6
    80001794:	00000097          	auipc	ra,0x0
    80001798:	914080e7          	jalr	-1772(ra) # 800010a8 <walkaddr>
    if(pa0 == 0)
    8000179c:	cd01                	beqz	a0,800017b4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000179e:	418904b3          	sub	s1,s2,s8
    800017a2:	94d6                	add	s1,s1,s5
    if(n > len)
    800017a4:	fc99f2e3          	bgeu	s3,s1,80001768 <copyin+0x28>
    800017a8:	84ce                	mv	s1,s3
    800017aa:	bf7d                	j	80001768 <copyin+0x28>
  }
  return 0;
    800017ac:	4501                	li	a0,0
    800017ae:	a021                	j	800017b6 <copyin+0x76>
    800017b0:	4501                	li	a0,0
}
    800017b2:	8082                	ret
      return -1;
    800017b4:	557d                	li	a0,-1
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6c02                	ld	s8,0(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret

00000000800017ce <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017ce:	c6c5                	beqz	a3,80001876 <copyinstr+0xa8>
{
    800017d0:	715d                	addi	sp,sp,-80
    800017d2:	e486                	sd	ra,72(sp)
    800017d4:	e0a2                	sd	s0,64(sp)
    800017d6:	fc26                	sd	s1,56(sp)
    800017d8:	f84a                	sd	s2,48(sp)
    800017da:	f44e                	sd	s3,40(sp)
    800017dc:	f052                	sd	s4,32(sp)
    800017de:	ec56                	sd	s5,24(sp)
    800017e0:	e85a                	sd	s6,16(sp)
    800017e2:	e45e                	sd	s7,8(sp)
    800017e4:	0880                	addi	s0,sp,80
    800017e6:	8a2a                	mv	s4,a0
    800017e8:	8b2e                	mv	s6,a1
    800017ea:	8bb2                	mv	s7,a2
    800017ec:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017ee:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017f0:	6985                	lui	s3,0x1
    800017f2:	a035                	j	8000181e <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017f4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017f8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017fa:	0017b793          	seqz	a5,a5
    800017fe:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001802:	60a6                	ld	ra,72(sp)
    80001804:	6406                	ld	s0,64(sp)
    80001806:	74e2                	ld	s1,56(sp)
    80001808:	7942                	ld	s2,48(sp)
    8000180a:	79a2                	ld	s3,40(sp)
    8000180c:	7a02                	ld	s4,32(sp)
    8000180e:	6ae2                	ld	s5,24(sp)
    80001810:	6b42                	ld	s6,16(sp)
    80001812:	6ba2                	ld	s7,8(sp)
    80001814:	6161                	addi	sp,sp,80
    80001816:	8082                	ret
    srcva = va0 + PGSIZE;
    80001818:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000181c:	c8a9                	beqz	s1,8000186e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000181e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001822:	85ca                	mv	a1,s2
    80001824:	8552                	mv	a0,s4
    80001826:	00000097          	auipc	ra,0x0
    8000182a:	882080e7          	jalr	-1918(ra) # 800010a8 <walkaddr>
    if(pa0 == 0)
    8000182e:	c131                	beqz	a0,80001872 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001830:	41790833          	sub	a6,s2,s7
    80001834:	984e                	add	a6,a6,s3
    if(n > max)
    80001836:	0104f363          	bgeu	s1,a6,8000183c <copyinstr+0x6e>
    8000183a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000183c:	955e                	add	a0,a0,s7
    8000183e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001842:	fc080be3          	beqz	a6,80001818 <copyinstr+0x4a>
    80001846:	985a                	add	a6,a6,s6
    80001848:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000184a:	41650633          	sub	a2,a0,s6
    8000184e:	14fd                	addi	s1,s1,-1
    80001850:	9b26                	add	s6,s6,s1
    80001852:	00f60733          	add	a4,a2,a5
    80001856:	00074703          	lbu	a4,0(a4)
    8000185a:	df49                	beqz	a4,800017f4 <copyinstr+0x26>
        *dst = *p;
    8000185c:	00e78023          	sb	a4,0(a5)
      --max;
    80001860:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001864:	0785                	addi	a5,a5,1
    while(n > 0){
    80001866:	ff0796e3          	bne	a5,a6,80001852 <copyinstr+0x84>
      dst++;
    8000186a:	8b42                	mv	s6,a6
    8000186c:	b775                	j	80001818 <copyinstr+0x4a>
    8000186e:	4781                	li	a5,0
    80001870:	b769                	j	800017fa <copyinstr+0x2c>
      return -1;
    80001872:	557d                	li	a0,-1
    80001874:	b779                	j	80001802 <copyinstr+0x34>
  int got_null = 0;
    80001876:	4781                	li	a5,0
  if(got_null){
    80001878:	0017b793          	seqz	a5,a5
    8000187c:	40f00533          	neg	a0,a5
}
    80001880:	8082                	ret

0000000080001882 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001882:	7139                	addi	sp,sp,-64
    80001884:	fc06                	sd	ra,56(sp)
    80001886:	f822                	sd	s0,48(sp)
    80001888:	f426                	sd	s1,40(sp)
    8000188a:	f04a                	sd	s2,32(sp)
    8000188c:	ec4e                	sd	s3,24(sp)
    8000188e:	e852                	sd	s4,16(sp)
    80001890:	e456                	sd	s5,8(sp)
    80001892:	e05a                	sd	s6,0(sp)
    80001894:	0080                	addi	s0,sp,64
    80001896:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001898:	0000f497          	auipc	s1,0xf
    8000189c:	6d848493          	addi	s1,s1,1752 # 80010f70 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018a0:	8b26                	mv	s6,s1
    800018a2:	00006a97          	auipc	s5,0x6
    800018a6:	75ea8a93          	addi	s5,s5,1886 # 80008000 <etext>
    800018aa:	04000937          	lui	s2,0x4000
    800018ae:	197d                	addi	s2,s2,-1
    800018b0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b2:	00015a17          	auipc	s4,0x15
    800018b6:	0bea0a13          	addi	s4,s4,190 # 80016970 <tickslock>
    char *pa = kalloc();
    800018ba:	fffff097          	auipc	ra,0xfffff
    800018be:	22c080e7          	jalr	556(ra) # 80000ae6 <kalloc>
    800018c2:	862a                	mv	a2,a0
    if(pa == 0)
    800018c4:	c131                	beqz	a0,80001908 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018c6:	416485b3          	sub	a1,s1,s6
    800018ca:	858d                	srai	a1,a1,0x3
    800018cc:	000ab783          	ld	a5,0(s5)
    800018d0:	02f585b3          	mul	a1,a1,a5
    800018d4:	2585                	addiw	a1,a1,1
    800018d6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018da:	4719                	li	a4,6
    800018dc:	6685                	lui	a3,0x1
    800018de:	40b905b3          	sub	a1,s2,a1
    800018e2:	854e                	mv	a0,s3
    800018e4:	00000097          	auipc	ra,0x0
    800018e8:	8a6080e7          	jalr	-1882(ra) # 8000118a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ec:	16848493          	addi	s1,s1,360
    800018f0:	fd4495e3          	bne	s1,s4,800018ba <proc_mapstacks+0x38>
  }
}
    800018f4:	70e2                	ld	ra,56(sp)
    800018f6:	7442                	ld	s0,48(sp)
    800018f8:	74a2                	ld	s1,40(sp)
    800018fa:	7902                	ld	s2,32(sp)
    800018fc:	69e2                	ld	s3,24(sp)
    800018fe:	6a42                	ld	s4,16(sp)
    80001900:	6aa2                	ld	s5,8(sp)
    80001902:	6b02                	ld	s6,0(sp)
    80001904:	6121                	addi	sp,sp,64
    80001906:	8082                	ret
      panic("kalloc");
    80001908:	00007517          	auipc	a0,0x7
    8000190c:	8d050513          	addi	a0,a0,-1840 # 800081d8 <digits+0x198>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	c2e080e7          	jalr	-978(ra) # 8000053e <panic>

0000000080001918 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001918:	7139                	addi	sp,sp,-64
    8000191a:	fc06                	sd	ra,56(sp)
    8000191c:	f822                	sd	s0,48(sp)
    8000191e:	f426                	sd	s1,40(sp)
    80001920:	f04a                	sd	s2,32(sp)
    80001922:	ec4e                	sd	s3,24(sp)
    80001924:	e852                	sd	s4,16(sp)
    80001926:	e456                	sd	s5,8(sp)
    80001928:	e05a                	sd	s6,0(sp)
    8000192a:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000192c:	00007597          	auipc	a1,0x7
    80001930:	8b458593          	addi	a1,a1,-1868 # 800081e0 <digits+0x1a0>
    80001934:	0000f517          	auipc	a0,0xf
    80001938:	20c50513          	addi	a0,a0,524 # 80010b40 <pid_lock>
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	256080e7          	jalr	598(ra) # 80000b92 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001944:	00007597          	auipc	a1,0x7
    80001948:	8a458593          	addi	a1,a1,-1884 # 800081e8 <digits+0x1a8>
    8000194c:	0000f517          	auipc	a0,0xf
    80001950:	20c50513          	addi	a0,a0,524 # 80010b58 <wait_lock>
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	23e080e7          	jalr	574(ra) # 80000b92 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195c:	0000f497          	auipc	s1,0xf
    80001960:	61448493          	addi	s1,s1,1556 # 80010f70 <proc>
      initlock(&p->lock, "proc");
    80001964:	00007b17          	auipc	s6,0x7
    80001968:	894b0b13          	addi	s6,s6,-1900 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000196c:	8aa6                	mv	s5,s1
    8000196e:	00006a17          	auipc	s4,0x6
    80001972:	692a0a13          	addi	s4,s4,1682 # 80008000 <etext>
    80001976:	04000937          	lui	s2,0x4000
    8000197a:	197d                	addi	s2,s2,-1
    8000197c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197e:	00015997          	auipc	s3,0x15
    80001982:	ff298993          	addi	s3,s3,-14 # 80016970 <tickslock>
      initlock(&p->lock, "proc");
    80001986:	85da                	mv	a1,s6
    80001988:	8526                	mv	a0,s1
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	208080e7          	jalr	520(ra) # 80000b92 <initlock>
      p->state = UNUSED;
    80001992:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001996:	415487b3          	sub	a5,s1,s5
    8000199a:	878d                	srai	a5,a5,0x3
    8000199c:	000a3703          	ld	a4,0(s4)
    800019a0:	02e787b3          	mul	a5,a5,a4
    800019a4:	2785                	addiw	a5,a5,1
    800019a6:	00d7979b          	slliw	a5,a5,0xd
    800019aa:	40f907b3          	sub	a5,s2,a5
    800019ae:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019b0:	16848493          	addi	s1,s1,360
    800019b4:	fd3499e3          	bne	s1,s3,80001986 <procinit+0x6e>
  }
}
    800019b8:	70e2                	ld	ra,56(sp)
    800019ba:	7442                	ld	s0,48(sp)
    800019bc:	74a2                	ld	s1,40(sp)
    800019be:	7902                	ld	s2,32(sp)
    800019c0:	69e2                	ld	s3,24(sp)
    800019c2:	6a42                	ld	s4,16(sp)
    800019c4:	6aa2                	ld	s5,8(sp)
    800019c6:	6b02                	ld	s6,0(sp)
    800019c8:	6121                	addi	sp,sp,64
    800019ca:	8082                	ret

00000000800019cc <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019cc:	1141                	addi	sp,sp,-16
    800019ce:	e422                	sd	s0,8(sp)
    800019d0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019d2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019d4:	2501                	sext.w	a0,a0
    800019d6:	6422                	ld	s0,8(sp)
    800019d8:	0141                	addi	sp,sp,16
    800019da:	8082                	ret

00000000800019dc <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019dc:	1141                	addi	sp,sp,-16
    800019de:	e422                	sd	s0,8(sp)
    800019e0:	0800                	addi	s0,sp,16
    800019e2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019e4:	2781                	sext.w	a5,a5
    800019e6:	079e                	slli	a5,a5,0x7
  return c;
}
    800019e8:	0000f517          	auipc	a0,0xf
    800019ec:	18850513          	addi	a0,a0,392 # 80010b70 <cpus>
    800019f0:	953e                	add	a0,a0,a5
    800019f2:	6422                	ld	s0,8(sp)
    800019f4:	0141                	addi	sp,sp,16
    800019f6:	8082                	ret

00000000800019f8 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019f8:	1101                	addi	sp,sp,-32
    800019fa:	ec06                	sd	ra,24(sp)
    800019fc:	e822                	sd	s0,16(sp)
    800019fe:	e426                	sd	s1,8(sp)
    80001a00:	1000                	addi	s0,sp,32
  push_off();
    80001a02:	fffff097          	auipc	ra,0xfffff
    80001a06:	1d4080e7          	jalr	468(ra) # 80000bd6 <push_off>
    80001a0a:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a0c:	2781                	sext.w	a5,a5
    80001a0e:	079e                	slli	a5,a5,0x7
    80001a10:	0000f717          	auipc	a4,0xf
    80001a14:	13070713          	addi	a4,a4,304 # 80010b40 <pid_lock>
    80001a18:	97ba                	add	a5,a5,a4
    80001a1a:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	25a080e7          	jalr	602(ra) # 80000c76 <pop_off>
  return p;
}
    80001a24:	8526                	mv	a0,s1
    80001a26:	60e2                	ld	ra,24(sp)
    80001a28:	6442                	ld	s0,16(sp)
    80001a2a:	64a2                	ld	s1,8(sp)
    80001a2c:	6105                	addi	sp,sp,32
    80001a2e:	8082                	ret

0000000080001a30 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a30:	1141                	addi	sp,sp,-16
    80001a32:	e406                	sd	ra,8(sp)
    80001a34:	e022                	sd	s0,0(sp)
    80001a36:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a38:	00000097          	auipc	ra,0x0
    80001a3c:	fc0080e7          	jalr	-64(ra) # 800019f8 <myproc>
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	296080e7          	jalr	662(ra) # 80000cd6 <release>

  if (first) {
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e087a783          	lw	a5,-504(a5) # 80008850 <first.1>
    80001a50:	eb89                	bnez	a5,80001a62 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a52:	00001097          	auipc	ra,0x1
    80001a56:	d1e080e7          	jalr	-738(ra) # 80002770 <usertrapret>
}
    80001a5a:	60a2                	ld	ra,8(sp)
    80001a5c:	6402                	ld	s0,0(sp)
    80001a5e:	0141                	addi	sp,sp,16
    80001a60:	8082                	ret
    first = 0;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	de07a723          	sw	zero,-530(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001a6a:	4505                	li	a0,1
    80001a6c:	00002097          	auipc	ra,0x2
    80001a70:	a7e080e7          	jalr	-1410(ra) # 800034ea <fsinit>
    80001a74:	bff9                	j	80001a52 <forkret+0x22>

0000000080001a76 <allocpid>:
{
    80001a76:	1101                	addi	sp,sp,-32
    80001a78:	ec06                	sd	ra,24(sp)
    80001a7a:	e822                	sd	s0,16(sp)
    80001a7c:	e426                	sd	s1,8(sp)
    80001a7e:	e04a                	sd	s2,0(sp)
    80001a80:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a82:	0000f917          	auipc	s2,0xf
    80001a86:	0be90913          	addi	s2,s2,190 # 80010b40 <pid_lock>
    80001a8a:	854a                	mv	a0,s2
    80001a8c:	fffff097          	auipc	ra,0xfffff
    80001a90:	196080e7          	jalr	406(ra) # 80000c22 <acquire>
  pid = nextpid;
    80001a94:	00007797          	auipc	a5,0x7
    80001a98:	dc078793          	addi	a5,a5,-576 # 80008854 <nextpid>
    80001a9c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a9e:	0014871b          	addiw	a4,s1,1
    80001aa2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aa4:	854a                	mv	a0,s2
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	230080e7          	jalr	560(ra) # 80000cd6 <release>
}
    80001aae:	8526                	mv	a0,s1
    80001ab0:	60e2                	ld	ra,24(sp)
    80001ab2:	6442                	ld	s0,16(sp)
    80001ab4:	64a2                	ld	s1,8(sp)
    80001ab6:	6902                	ld	s2,0(sp)
    80001ab8:	6105                	addi	sp,sp,32
    80001aba:	8082                	ret

0000000080001abc <proc_pagetable>:
{
    80001abc:	1101                	addi	sp,sp,-32
    80001abe:	ec06                	sd	ra,24(sp)
    80001ac0:	e822                	sd	s0,16(sp)
    80001ac2:	e426                	sd	s1,8(sp)
    80001ac4:	e04a                	sd	s2,0(sp)
    80001ac6:	1000                	addi	s0,sp,32
    80001ac8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aca:	00000097          	auipc	ra,0x0
    80001ace:	8aa080e7          	jalr	-1878(ra) # 80001374 <uvmcreate>
    80001ad2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ad4:	c121                	beqz	a0,80001b14 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ad6:	4729                	li	a4,10
    80001ad8:	00005697          	auipc	a3,0x5
    80001adc:	52868693          	addi	a3,a3,1320 # 80007000 <_trampoline>
    80001ae0:	6605                	lui	a2,0x1
    80001ae2:	040005b7          	lui	a1,0x4000
    80001ae6:	15fd                	addi	a1,a1,-1
    80001ae8:	05b2                	slli	a1,a1,0xc
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	600080e7          	jalr	1536(ra) # 800010ea <mappages>
    80001af2:	02054863          	bltz	a0,80001b22 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001af6:	4719                	li	a4,6
    80001af8:	05893683          	ld	a3,88(s2)
    80001afc:	6605                	lui	a2,0x1
    80001afe:	020005b7          	lui	a1,0x2000
    80001b02:	15fd                	addi	a1,a1,-1
    80001b04:	05b6                	slli	a1,a1,0xd
    80001b06:	8526                	mv	a0,s1
    80001b08:	fffff097          	auipc	ra,0xfffff
    80001b0c:	5e2080e7          	jalr	1506(ra) # 800010ea <mappages>
    80001b10:	02054163          	bltz	a0,80001b32 <proc_pagetable+0x76>
}
    80001b14:	8526                	mv	a0,s1
    80001b16:	60e2                	ld	ra,24(sp)
    80001b18:	6442                	ld	s0,16(sp)
    80001b1a:	64a2                	ld	s1,8(sp)
    80001b1c:	6902                	ld	s2,0(sp)
    80001b1e:	6105                	addi	sp,sp,32
    80001b20:	8082                	ret
    uvmfree(pagetable, 0);
    80001b22:	4581                	li	a1,0
    80001b24:	8526                	mv	a0,s1
    80001b26:	00000097          	auipc	ra,0x0
    80001b2a:	a52080e7          	jalr	-1454(ra) # 80001578 <uvmfree>
    return 0;
    80001b2e:	4481                	li	s1,0
    80001b30:	b7d5                	j	80001b14 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b32:	4681                	li	a3,0
    80001b34:	4605                	li	a2,1
    80001b36:	040005b7          	lui	a1,0x4000
    80001b3a:	15fd                	addi	a1,a1,-1
    80001b3c:	05b2                	slli	a1,a1,0xc
    80001b3e:	8526                	mv	a0,s1
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	770080e7          	jalr	1904(ra) # 800012b0 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b48:	4581                	li	a1,0
    80001b4a:	8526                	mv	a0,s1
    80001b4c:	00000097          	auipc	ra,0x0
    80001b50:	a2c080e7          	jalr	-1492(ra) # 80001578 <uvmfree>
    return 0;
    80001b54:	4481                	li	s1,0
    80001b56:	bf7d                	j	80001b14 <proc_pagetable+0x58>

0000000080001b58 <proc_freepagetable>:
{
    80001b58:	1101                	addi	sp,sp,-32
    80001b5a:	ec06                	sd	ra,24(sp)
    80001b5c:	e822                	sd	s0,16(sp)
    80001b5e:	e426                	sd	s1,8(sp)
    80001b60:	e04a                	sd	s2,0(sp)
    80001b62:	1000                	addi	s0,sp,32
    80001b64:	84aa                	mv	s1,a0
    80001b66:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b68:	4681                	li	a3,0
    80001b6a:	4605                	li	a2,1
    80001b6c:	040005b7          	lui	a1,0x4000
    80001b70:	15fd                	addi	a1,a1,-1
    80001b72:	05b2                	slli	a1,a1,0xc
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	73c080e7          	jalr	1852(ra) # 800012b0 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b7c:	4681                	li	a3,0
    80001b7e:	4605                	li	a2,1
    80001b80:	020005b7          	lui	a1,0x2000
    80001b84:	15fd                	addi	a1,a1,-1
    80001b86:	05b6                	slli	a1,a1,0xd
    80001b88:	8526                	mv	a0,s1
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	726080e7          	jalr	1830(ra) # 800012b0 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b92:	85ca                	mv	a1,s2
    80001b94:	8526                	mv	a0,s1
    80001b96:	00000097          	auipc	ra,0x0
    80001b9a:	9e2080e7          	jalr	-1566(ra) # 80001578 <uvmfree>
}
    80001b9e:	60e2                	ld	ra,24(sp)
    80001ba0:	6442                	ld	s0,16(sp)
    80001ba2:	64a2                	ld	s1,8(sp)
    80001ba4:	6902                	ld	s2,0(sp)
    80001ba6:	6105                	addi	sp,sp,32
    80001ba8:	8082                	ret

0000000080001baa <freeproc>:
{
    80001baa:	1101                	addi	sp,sp,-32
    80001bac:	ec06                	sd	ra,24(sp)
    80001bae:	e822                	sd	s0,16(sp)
    80001bb0:	e426                	sd	s1,8(sp)
    80001bb2:	1000                	addi	s0,sp,32
    80001bb4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bb6:	6d28                	ld	a0,88(a0)
    80001bb8:	c509                	beqz	a0,80001bc2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	e30080e7          	jalr	-464(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001bc2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bc6:	68a8                	ld	a0,80(s1)
    80001bc8:	c511                	beqz	a0,80001bd4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bca:	64ac                	ld	a1,72(s1)
    80001bcc:	00000097          	auipc	ra,0x0
    80001bd0:	f8c080e7          	jalr	-116(ra) # 80001b58 <proc_freepagetable>
  p->pagetable = 0;
    80001bd4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bd8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bdc:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001be0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001be4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001be8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bec:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bf0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bf4:	0004ac23          	sw	zero,24(s1)
}
    80001bf8:	60e2                	ld	ra,24(sp)
    80001bfa:	6442                	ld	s0,16(sp)
    80001bfc:	64a2                	ld	s1,8(sp)
    80001bfe:	6105                	addi	sp,sp,32
    80001c00:	8082                	ret

0000000080001c02 <allocproc>:
{
    80001c02:	1101                	addi	sp,sp,-32
    80001c04:	ec06                	sd	ra,24(sp)
    80001c06:	e822                	sd	s0,16(sp)
    80001c08:	e426                	sd	s1,8(sp)
    80001c0a:	e04a                	sd	s2,0(sp)
    80001c0c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0e:	0000f497          	auipc	s1,0xf
    80001c12:	36248493          	addi	s1,s1,866 # 80010f70 <proc>
    80001c16:	00015917          	auipc	s2,0x15
    80001c1a:	d5a90913          	addi	s2,s2,-678 # 80016970 <tickslock>
    acquire(&p->lock);
    80001c1e:	8526                	mv	a0,s1
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	002080e7          	jalr	2(ra) # 80000c22 <acquire>
    if(p->state == UNUSED) {
    80001c28:	4c9c                	lw	a5,24(s1)
    80001c2a:	cf81                	beqz	a5,80001c42 <allocproc+0x40>
      release(&p->lock);
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	0a8080e7          	jalr	168(ra) # 80000cd6 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c36:	16848493          	addi	s1,s1,360
    80001c3a:	ff2492e3          	bne	s1,s2,80001c1e <allocproc+0x1c>
  return 0;
    80001c3e:	4481                	li	s1,0
    80001c40:	a889                	j	80001c92 <allocproc+0x90>
  p->pid = allocpid();
    80001c42:	00000097          	auipc	ra,0x0
    80001c46:	e34080e7          	jalr	-460(ra) # 80001a76 <allocpid>
    80001c4a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c4c:	4785                	li	a5,1
    80001c4e:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	e96080e7          	jalr	-362(ra) # 80000ae6 <kalloc>
    80001c58:	892a                	mv	s2,a0
    80001c5a:	eca8                	sd	a0,88(s1)
    80001c5c:	c131                	beqz	a0,80001ca0 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	e5c080e7          	jalr	-420(ra) # 80001abc <proc_pagetable>
    80001c68:	892a                	mv	s2,a0
    80001c6a:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c6c:	c531                	beqz	a0,80001cb8 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c6e:	07000613          	li	a2,112
    80001c72:	4581                	li	a1,0
    80001c74:	06048513          	addi	a0,s1,96
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	0a6080e7          	jalr	166(ra) # 80000d1e <memset>
  p->context.ra = (uint64)forkret;
    80001c80:	00000797          	auipc	a5,0x0
    80001c84:	db078793          	addi	a5,a5,-592 # 80001a30 <forkret>
    80001c88:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c8a:	60bc                	ld	a5,64(s1)
    80001c8c:	6705                	lui	a4,0x1
    80001c8e:	97ba                	add	a5,a5,a4
    80001c90:	f4bc                	sd	a5,104(s1)
}
    80001c92:	8526                	mv	a0,s1
    80001c94:	60e2                	ld	ra,24(sp)
    80001c96:	6442                	ld	s0,16(sp)
    80001c98:	64a2                	ld	s1,8(sp)
    80001c9a:	6902                	ld	s2,0(sp)
    80001c9c:	6105                	addi	sp,sp,32
    80001c9e:	8082                	ret
    freeproc(p);
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	f08080e7          	jalr	-248(ra) # 80001baa <freeproc>
    release(&p->lock);
    80001caa:	8526                	mv	a0,s1
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	02a080e7          	jalr	42(ra) # 80000cd6 <release>
    return 0;
    80001cb4:	84ca                	mv	s1,s2
    80001cb6:	bff1                	j	80001c92 <allocproc+0x90>
    freeproc(p);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	ef0080e7          	jalr	-272(ra) # 80001baa <freeproc>
    release(&p->lock);
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	012080e7          	jalr	18(ra) # 80000cd6 <release>
    return 0;
    80001ccc:	84ca                	mv	s1,s2
    80001cce:	b7d1                	j	80001c92 <allocproc+0x90>

0000000080001cd0 <userinit>:
{
    80001cd0:	1101                	addi	sp,sp,-32
    80001cd2:	ec06                	sd	ra,24(sp)
    80001cd4:	e822                	sd	s0,16(sp)
    80001cd6:	e426                	sd	s1,8(sp)
    80001cd8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cda:	00000097          	auipc	ra,0x0
    80001cde:	f28080e7          	jalr	-216(ra) # 80001c02 <allocproc>
    80001ce2:	84aa                	mv	s1,a0
  initproc = p;
    80001ce4:	00007797          	auipc	a5,0x7
    80001ce8:	bea7b223          	sd	a0,-1052(a5) # 800088c8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cec:	03400613          	li	a2,52
    80001cf0:	00007597          	auipc	a1,0x7
    80001cf4:	b7058593          	addi	a1,a1,-1168 # 80008860 <initcode>
    80001cf8:	6928                	ld	a0,80(a0)
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	6a8080e7          	jalr	1704(ra) # 800013a2 <uvmfirst>
  p->sz = PGSIZE;
    80001d02:	6785                	lui	a5,0x1
    80001d04:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d06:	6cb8                	ld	a4,88(s1)
    80001d08:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d0c:	6cb8                	ld	a4,88(s1)
    80001d0e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d10:	4641                	li	a2,16
    80001d12:	00006597          	auipc	a1,0x6
    80001d16:	4ee58593          	addi	a1,a1,1262 # 80008200 <digits+0x1c0>
    80001d1a:	15848513          	addi	a0,s1,344
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	14a080e7          	jalr	330(ra) # 80000e68 <safestrcpy>
  p->cwd = namei("/");
    80001d26:	00006517          	auipc	a0,0x6
    80001d2a:	4ea50513          	addi	a0,a0,1258 # 80008210 <digits+0x1d0>
    80001d2e:	00002097          	auipc	ra,0x2
    80001d32:	1de080e7          	jalr	478(ra) # 80003f0c <namei>
    80001d36:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d3a:	478d                	li	a5,3
    80001d3c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d3e:	8526                	mv	a0,s1
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	f96080e7          	jalr	-106(ra) # 80000cd6 <release>
}
    80001d48:	60e2                	ld	ra,24(sp)
    80001d4a:	6442                	ld	s0,16(sp)
    80001d4c:	64a2                	ld	s1,8(sp)
    80001d4e:	6105                	addi	sp,sp,32
    80001d50:	8082                	ret

0000000080001d52 <growproc>:
{
    80001d52:	1101                	addi	sp,sp,-32
    80001d54:	ec06                	sd	ra,24(sp)
    80001d56:	e822                	sd	s0,16(sp)
    80001d58:	e426                	sd	s1,8(sp)
    80001d5a:	e04a                	sd	s2,0(sp)
    80001d5c:	1000                	addi	s0,sp,32
    80001d5e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d60:	00000097          	auipc	ra,0x0
    80001d64:	c98080e7          	jalr	-872(ra) # 800019f8 <myproc>
    80001d68:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d6a:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d6c:	01204c63          	bgtz	s2,80001d84 <growproc+0x32>
  } else if(n < 0){
    80001d70:	02094663          	bltz	s2,80001d9c <growproc+0x4a>
  p->sz = sz;
    80001d74:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d76:	4501                	li	a0,0
}
    80001d78:	60e2                	ld	ra,24(sp)
    80001d7a:	6442                	ld	s0,16(sp)
    80001d7c:	64a2                	ld	s1,8(sp)
    80001d7e:	6902                	ld	s2,0(sp)
    80001d80:	6105                	addi	sp,sp,32
    80001d82:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d84:	4691                	li	a3,4
    80001d86:	00b90633          	add	a2,s2,a1
    80001d8a:	6928                	ld	a0,80(a0)
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	6d0080e7          	jalr	1744(ra) # 8000145c <uvmalloc>
    80001d94:	85aa                	mv	a1,a0
    80001d96:	fd79                	bnez	a0,80001d74 <growproc+0x22>
      return -1;
    80001d98:	557d                	li	a0,-1
    80001d9a:	bff9                	j	80001d78 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d9c:	00b90633          	add	a2,s2,a1
    80001da0:	6928                	ld	a0,80(a0)
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	672080e7          	jalr	1650(ra) # 80001414 <uvmdealloc>
    80001daa:	85aa                	mv	a1,a0
    80001dac:	b7e1                	j	80001d74 <growproc+0x22>

0000000080001dae <fork>:
{
    80001dae:	7139                	addi	sp,sp,-64
    80001db0:	fc06                	sd	ra,56(sp)
    80001db2:	f822                	sd	s0,48(sp)
    80001db4:	f426                	sd	s1,40(sp)
    80001db6:	f04a                	sd	s2,32(sp)
    80001db8:	ec4e                	sd	s3,24(sp)
    80001dba:	e852                	sd	s4,16(sp)
    80001dbc:	e456                	sd	s5,8(sp)
    80001dbe:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dc0:	00000097          	auipc	ra,0x0
    80001dc4:	c38080e7          	jalr	-968(ra) # 800019f8 <myproc>
    80001dc8:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dca:	00000097          	auipc	ra,0x0
    80001dce:	e38080e7          	jalr	-456(ra) # 80001c02 <allocproc>
    80001dd2:	10050c63          	beqz	a0,80001eea <fork+0x13c>
    80001dd6:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dd8:	048ab603          	ld	a2,72(s5)
    80001ddc:	692c                	ld	a1,80(a0)
    80001dde:	050ab503          	ld	a0,80(s5)
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	7ce080e7          	jalr	1998(ra) # 800015b0 <uvmcopy>
    80001dea:	04054863          	bltz	a0,80001e3a <fork+0x8c>
  np->sz = p->sz;
    80001dee:	048ab783          	ld	a5,72(s5)
    80001df2:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001df6:	058ab683          	ld	a3,88(s5)
    80001dfa:	87b6                	mv	a5,a3
    80001dfc:	058a3703          	ld	a4,88(s4)
    80001e00:	12068693          	addi	a3,a3,288
    80001e04:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e08:	6788                	ld	a0,8(a5)
    80001e0a:	6b8c                	ld	a1,16(a5)
    80001e0c:	6f90                	ld	a2,24(a5)
    80001e0e:	01073023          	sd	a6,0(a4)
    80001e12:	e708                	sd	a0,8(a4)
    80001e14:	eb0c                	sd	a1,16(a4)
    80001e16:	ef10                	sd	a2,24(a4)
    80001e18:	02078793          	addi	a5,a5,32
    80001e1c:	02070713          	addi	a4,a4,32
    80001e20:	fed792e3          	bne	a5,a3,80001e04 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e24:	058a3783          	ld	a5,88(s4)
    80001e28:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e2c:	0d0a8493          	addi	s1,s5,208
    80001e30:	0d0a0913          	addi	s2,s4,208
    80001e34:	150a8993          	addi	s3,s5,336
    80001e38:	a00d                	j	80001e5a <fork+0xac>
    freeproc(np);
    80001e3a:	8552                	mv	a0,s4
    80001e3c:	00000097          	auipc	ra,0x0
    80001e40:	d6e080e7          	jalr	-658(ra) # 80001baa <freeproc>
    release(&np->lock);
    80001e44:	8552                	mv	a0,s4
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	e90080e7          	jalr	-368(ra) # 80000cd6 <release>
    return -1;
    80001e4e:	597d                	li	s2,-1
    80001e50:	a059                	j	80001ed6 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e52:	04a1                	addi	s1,s1,8
    80001e54:	0921                	addi	s2,s2,8
    80001e56:	01348b63          	beq	s1,s3,80001e6c <fork+0xbe>
    if(p->ofile[i])
    80001e5a:	6088                	ld	a0,0(s1)
    80001e5c:	d97d                	beqz	a0,80001e52 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e5e:	00002097          	auipc	ra,0x2
    80001e62:	744080e7          	jalr	1860(ra) # 800045a2 <filedup>
    80001e66:	00a93023          	sd	a0,0(s2)
    80001e6a:	b7e5                	j	80001e52 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e6c:	150ab503          	ld	a0,336(s5)
    80001e70:	00002097          	auipc	ra,0x2
    80001e74:	8b8080e7          	jalr	-1864(ra) # 80003728 <idup>
    80001e78:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e7c:	4641                	li	a2,16
    80001e7e:	158a8593          	addi	a1,s5,344
    80001e82:	158a0513          	addi	a0,s4,344
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	fe2080e7          	jalr	-30(ra) # 80000e68 <safestrcpy>
  pid = np->pid;
    80001e8e:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e92:	8552                	mv	a0,s4
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	e42080e7          	jalr	-446(ra) # 80000cd6 <release>
  acquire(&wait_lock);
    80001e9c:	0000f497          	auipc	s1,0xf
    80001ea0:	cbc48493          	addi	s1,s1,-836 # 80010b58 <wait_lock>
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	d7c080e7          	jalr	-644(ra) # 80000c22 <acquire>
  np->parent = p;
    80001eae:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	e22080e7          	jalr	-478(ra) # 80000cd6 <release>
  acquire(&np->lock);
    80001ebc:	8552                	mv	a0,s4
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	d64080e7          	jalr	-668(ra) # 80000c22 <acquire>
  np->state = RUNNABLE;
    80001ec6:	478d                	li	a5,3
    80001ec8:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ecc:	8552                	mv	a0,s4
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	e08080e7          	jalr	-504(ra) # 80000cd6 <release>
}
    80001ed6:	854a                	mv	a0,s2
    80001ed8:	70e2                	ld	ra,56(sp)
    80001eda:	7442                	ld	s0,48(sp)
    80001edc:	74a2                	ld	s1,40(sp)
    80001ede:	7902                	ld	s2,32(sp)
    80001ee0:	69e2                	ld	s3,24(sp)
    80001ee2:	6a42                	ld	s4,16(sp)
    80001ee4:	6aa2                	ld	s5,8(sp)
    80001ee6:	6121                	addi	sp,sp,64
    80001ee8:	8082                	ret
    return -1;
    80001eea:	597d                	li	s2,-1
    80001eec:	b7ed                	j	80001ed6 <fork+0x128>

0000000080001eee <scheduler>:
{
    80001eee:	7139                	addi	sp,sp,-64
    80001ef0:	fc06                	sd	ra,56(sp)
    80001ef2:	f822                	sd	s0,48(sp)
    80001ef4:	f426                	sd	s1,40(sp)
    80001ef6:	f04a                	sd	s2,32(sp)
    80001ef8:	ec4e                	sd	s3,24(sp)
    80001efa:	e852                	sd	s4,16(sp)
    80001efc:	e456                	sd	s5,8(sp)
    80001efe:	e05a                	sd	s6,0(sp)
    80001f00:	0080                	addi	s0,sp,64
    80001f02:	8792                	mv	a5,tp
  int id = r_tp();
    80001f04:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f06:	00779a93          	slli	s5,a5,0x7
    80001f0a:	0000f717          	auipc	a4,0xf
    80001f0e:	c3670713          	addi	a4,a4,-970 # 80010b40 <pid_lock>
    80001f12:	9756                	add	a4,a4,s5
    80001f14:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f18:	0000f717          	auipc	a4,0xf
    80001f1c:	c6070713          	addi	a4,a4,-928 # 80010b78 <cpus+0x8>
    80001f20:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f22:	498d                	li	s3,3
        p->state = RUNNING;
    80001f24:	4b11                	li	s6,4
        c->proc = p;
    80001f26:	079e                	slli	a5,a5,0x7
    80001f28:	0000fa17          	auipc	s4,0xf
    80001f2c:	c18a0a13          	addi	s4,s4,-1000 # 80010b40 <pid_lock>
    80001f30:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f32:	00015917          	auipc	s2,0x15
    80001f36:	a3e90913          	addi	s2,s2,-1474 # 80016970 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f3e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f42:	10079073          	csrw	sstatus,a5
    80001f46:	0000f497          	auipc	s1,0xf
    80001f4a:	02a48493          	addi	s1,s1,42 # 80010f70 <proc>
    80001f4e:	a811                	j	80001f62 <scheduler+0x74>
      release(&p->lock);
    80001f50:	8526                	mv	a0,s1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	d84080e7          	jalr	-636(ra) # 80000cd6 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f5a:	16848493          	addi	s1,s1,360
    80001f5e:	fd248ee3          	beq	s1,s2,80001f3a <scheduler+0x4c>
      acquire(&p->lock);
    80001f62:	8526                	mv	a0,s1
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	cbe080e7          	jalr	-834(ra) # 80000c22 <acquire>
      if(p->state == RUNNABLE) {
    80001f6c:	4c9c                	lw	a5,24(s1)
    80001f6e:	ff3791e3          	bne	a5,s3,80001f50 <scheduler+0x62>
        p->state = RUNNING;
    80001f72:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f76:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f7a:	06048593          	addi	a1,s1,96
    80001f7e:	8556                	mv	a0,s5
    80001f80:	00000097          	auipc	ra,0x0
    80001f84:	746080e7          	jalr	1862(ra) # 800026c6 <swtch>
        c->proc = 0;
    80001f88:	020a3823          	sd	zero,48(s4)
    80001f8c:	b7d1                	j	80001f50 <scheduler+0x62>

0000000080001f8e <sched>:
{
    80001f8e:	7179                	addi	sp,sp,-48
    80001f90:	f406                	sd	ra,40(sp)
    80001f92:	f022                	sd	s0,32(sp)
    80001f94:	ec26                	sd	s1,24(sp)
    80001f96:	e84a                	sd	s2,16(sp)
    80001f98:	e44e                	sd	s3,8(sp)
    80001f9a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f9c:	00000097          	auipc	ra,0x0
    80001fa0:	a5c080e7          	jalr	-1444(ra) # 800019f8 <myproc>
    80001fa4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	c02080e7          	jalr	-1022(ra) # 80000ba8 <holding>
    80001fae:	c93d                	beqz	a0,80002024 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb0:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fb2:	2781                	sext.w	a5,a5
    80001fb4:	079e                	slli	a5,a5,0x7
    80001fb6:	0000f717          	auipc	a4,0xf
    80001fba:	b8a70713          	addi	a4,a4,-1142 # 80010b40 <pid_lock>
    80001fbe:	97ba                	add	a5,a5,a4
    80001fc0:	0a87a703          	lw	a4,168(a5)
    80001fc4:	4785                	li	a5,1
    80001fc6:	06f71763          	bne	a4,a5,80002034 <sched+0xa6>
  if(p->state == RUNNING)
    80001fca:	4c98                	lw	a4,24(s1)
    80001fcc:	4791                	li	a5,4
    80001fce:	06f70b63          	beq	a4,a5,80002044 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fd6:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fd8:	efb5                	bnez	a5,80002054 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fda:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fdc:	0000f917          	auipc	s2,0xf
    80001fe0:	b6490913          	addi	s2,s2,-1180 # 80010b40 <pid_lock>
    80001fe4:	2781                	sext.w	a5,a5
    80001fe6:	079e                	slli	a5,a5,0x7
    80001fe8:	97ca                	add	a5,a5,s2
    80001fea:	0ac7a983          	lw	s3,172(a5)
    80001fee:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001ff0:	2781                	sext.w	a5,a5
    80001ff2:	079e                	slli	a5,a5,0x7
    80001ff4:	0000f597          	auipc	a1,0xf
    80001ff8:	b8458593          	addi	a1,a1,-1148 # 80010b78 <cpus+0x8>
    80001ffc:	95be                	add	a1,a1,a5
    80001ffe:	06048513          	addi	a0,s1,96
    80002002:	00000097          	auipc	ra,0x0
    80002006:	6c4080e7          	jalr	1732(ra) # 800026c6 <swtch>
    8000200a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	97ca                	add	a5,a5,s2
    80002012:	0b37a623          	sw	s3,172(a5)
}
    80002016:	70a2                	ld	ra,40(sp)
    80002018:	7402                	ld	s0,32(sp)
    8000201a:	64e2                	ld	s1,24(sp)
    8000201c:	6942                	ld	s2,16(sp)
    8000201e:	69a2                	ld	s3,8(sp)
    80002020:	6145                	addi	sp,sp,48
    80002022:	8082                	ret
    panic("sched p->lock");
    80002024:	00006517          	auipc	a0,0x6
    80002028:	1f450513          	addi	a0,a0,500 # 80008218 <digits+0x1d8>
    8000202c:	ffffe097          	auipc	ra,0xffffe
    80002030:	512080e7          	jalr	1298(ra) # 8000053e <panic>
    panic("sched locks");
    80002034:	00006517          	auipc	a0,0x6
    80002038:	1f450513          	addi	a0,a0,500 # 80008228 <digits+0x1e8>
    8000203c:	ffffe097          	auipc	ra,0xffffe
    80002040:	502080e7          	jalr	1282(ra) # 8000053e <panic>
    panic("sched running");
    80002044:	00006517          	auipc	a0,0x6
    80002048:	1f450513          	addi	a0,a0,500 # 80008238 <digits+0x1f8>
    8000204c:	ffffe097          	auipc	ra,0xffffe
    80002050:	4f2080e7          	jalr	1266(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002054:	00006517          	auipc	a0,0x6
    80002058:	1f450513          	addi	a0,a0,500 # 80008248 <digits+0x208>
    8000205c:	ffffe097          	auipc	ra,0xffffe
    80002060:	4e2080e7          	jalr	1250(ra) # 8000053e <panic>

0000000080002064 <yield>:
{
    80002064:	1101                	addi	sp,sp,-32
    80002066:	ec06                	sd	ra,24(sp)
    80002068:	e822                	sd	s0,16(sp)
    8000206a:	e426                	sd	s1,8(sp)
    8000206c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	98a080e7          	jalr	-1654(ra) # 800019f8 <myproc>
    80002076:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	baa080e7          	jalr	-1110(ra) # 80000c22 <acquire>
  p->state = RUNNABLE;
    80002080:	478d                	li	a5,3
    80002082:	cc9c                	sw	a5,24(s1)
  sched();
    80002084:	00000097          	auipc	ra,0x0
    80002088:	f0a080e7          	jalr	-246(ra) # 80001f8e <sched>
  release(&p->lock);
    8000208c:	8526                	mv	a0,s1
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	c48080e7          	jalr	-952(ra) # 80000cd6 <release>
}
    80002096:	60e2                	ld	ra,24(sp)
    80002098:	6442                	ld	s0,16(sp)
    8000209a:	64a2                	ld	s1,8(sp)
    8000209c:	6105                	addi	sp,sp,32
    8000209e:	8082                	ret

00000000800020a0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020a0:	7179                	addi	sp,sp,-48
    800020a2:	f406                	sd	ra,40(sp)
    800020a4:	f022                	sd	s0,32(sp)
    800020a6:	ec26                	sd	s1,24(sp)
    800020a8:	e84a                	sd	s2,16(sp)
    800020aa:	e44e                	sd	s3,8(sp)
    800020ac:	1800                	addi	s0,sp,48
    800020ae:	89aa                	mv	s3,a0
    800020b0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020b2:	00000097          	auipc	ra,0x0
    800020b6:	946080e7          	jalr	-1722(ra) # 800019f8 <myproc>
    800020ba:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	b66080e7          	jalr	-1178(ra) # 80000c22 <acquire>
  release(lk);
    800020c4:	854a                	mv	a0,s2
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	c10080e7          	jalr	-1008(ra) # 80000cd6 <release>

  // Go to sleep.
  p->chan = chan;
    800020ce:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020d2:	4789                	li	a5,2
    800020d4:	cc9c                	sw	a5,24(s1)

  sched();
    800020d6:	00000097          	auipc	ra,0x0
    800020da:	eb8080e7          	jalr	-328(ra) # 80001f8e <sched>

  // Tidy up.
  p->chan = 0;
    800020de:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	bf2080e7          	jalr	-1038(ra) # 80000cd6 <release>
  acquire(lk);
    800020ec:	854a                	mv	a0,s2
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	b34080e7          	jalr	-1228(ra) # 80000c22 <acquire>
}
    800020f6:	70a2                	ld	ra,40(sp)
    800020f8:	7402                	ld	s0,32(sp)
    800020fa:	64e2                	ld	s1,24(sp)
    800020fc:	6942                	ld	s2,16(sp)
    800020fe:	69a2                	ld	s3,8(sp)
    80002100:	6145                	addi	sp,sp,48
    80002102:	8082                	ret

0000000080002104 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002104:	7139                	addi	sp,sp,-64
    80002106:	fc06                	sd	ra,56(sp)
    80002108:	f822                	sd	s0,48(sp)
    8000210a:	f426                	sd	s1,40(sp)
    8000210c:	f04a                	sd	s2,32(sp)
    8000210e:	ec4e                	sd	s3,24(sp)
    80002110:	e852                	sd	s4,16(sp)
    80002112:	e456                	sd	s5,8(sp)
    80002114:	0080                	addi	s0,sp,64
    80002116:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002118:	0000f497          	auipc	s1,0xf
    8000211c:	e5848493          	addi	s1,s1,-424 # 80010f70 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002120:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002122:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002124:	00015917          	auipc	s2,0x15
    80002128:	84c90913          	addi	s2,s2,-1972 # 80016970 <tickslock>
    8000212c:	a811                	j	80002140 <wakeup+0x3c>
      }
      release(&p->lock);
    8000212e:	8526                	mv	a0,s1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	ba6080e7          	jalr	-1114(ra) # 80000cd6 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002138:	16848493          	addi	s1,s1,360
    8000213c:	03248663          	beq	s1,s2,80002168 <wakeup+0x64>
    if(p != myproc()){
    80002140:	00000097          	auipc	ra,0x0
    80002144:	8b8080e7          	jalr	-1864(ra) # 800019f8 <myproc>
    80002148:	fea488e3          	beq	s1,a0,80002138 <wakeup+0x34>
      acquire(&p->lock);
    8000214c:	8526                	mv	a0,s1
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	ad4080e7          	jalr	-1324(ra) # 80000c22 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002156:	4c9c                	lw	a5,24(s1)
    80002158:	fd379be3          	bne	a5,s3,8000212e <wakeup+0x2a>
    8000215c:	709c                	ld	a5,32(s1)
    8000215e:	fd4798e3          	bne	a5,s4,8000212e <wakeup+0x2a>
        p->state = RUNNABLE;
    80002162:	0154ac23          	sw	s5,24(s1)
    80002166:	b7e1                	j	8000212e <wakeup+0x2a>
    }
  }
}
    80002168:	70e2                	ld	ra,56(sp)
    8000216a:	7442                	ld	s0,48(sp)
    8000216c:	74a2                	ld	s1,40(sp)
    8000216e:	7902                	ld	s2,32(sp)
    80002170:	69e2                	ld	s3,24(sp)
    80002172:	6a42                	ld	s4,16(sp)
    80002174:	6aa2                	ld	s5,8(sp)
    80002176:	6121                	addi	sp,sp,64
    80002178:	8082                	ret

000000008000217a <reparent>:
{
    8000217a:	7179                	addi	sp,sp,-48
    8000217c:	f406                	sd	ra,40(sp)
    8000217e:	f022                	sd	s0,32(sp)
    80002180:	ec26                	sd	s1,24(sp)
    80002182:	e84a                	sd	s2,16(sp)
    80002184:	e44e                	sd	s3,8(sp)
    80002186:	e052                	sd	s4,0(sp)
    80002188:	1800                	addi	s0,sp,48
    8000218a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000218c:	0000f497          	auipc	s1,0xf
    80002190:	de448493          	addi	s1,s1,-540 # 80010f70 <proc>
      pp->parent = initproc;
    80002194:	00006a17          	auipc	s4,0x6
    80002198:	734a0a13          	addi	s4,s4,1844 # 800088c8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000219c:	00014997          	auipc	s3,0x14
    800021a0:	7d498993          	addi	s3,s3,2004 # 80016970 <tickslock>
    800021a4:	a029                	j	800021ae <reparent+0x34>
    800021a6:	16848493          	addi	s1,s1,360
    800021aa:	01348d63          	beq	s1,s3,800021c4 <reparent+0x4a>
    if(pp->parent == p){
    800021ae:	7c9c                	ld	a5,56(s1)
    800021b0:	ff279be3          	bne	a5,s2,800021a6 <reparent+0x2c>
      pp->parent = initproc;
    800021b4:	000a3503          	ld	a0,0(s4)
    800021b8:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021ba:	00000097          	auipc	ra,0x0
    800021be:	f4a080e7          	jalr	-182(ra) # 80002104 <wakeup>
    800021c2:	b7d5                	j	800021a6 <reparent+0x2c>
}
    800021c4:	70a2                	ld	ra,40(sp)
    800021c6:	7402                	ld	s0,32(sp)
    800021c8:	64e2                	ld	s1,24(sp)
    800021ca:	6942                	ld	s2,16(sp)
    800021cc:	69a2                	ld	s3,8(sp)
    800021ce:	6a02                	ld	s4,0(sp)
    800021d0:	6145                	addi	sp,sp,48
    800021d2:	8082                	ret

00000000800021d4 <exit>:
{
    800021d4:	7179                	addi	sp,sp,-48
    800021d6:	f406                	sd	ra,40(sp)
    800021d8:	f022                	sd	s0,32(sp)
    800021da:	ec26                	sd	s1,24(sp)
    800021dc:	e84a                	sd	s2,16(sp)
    800021de:	e44e                	sd	s3,8(sp)
    800021e0:	e052                	sd	s4,0(sp)
    800021e2:	1800                	addi	s0,sp,48
    800021e4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021e6:	00000097          	auipc	ra,0x0
    800021ea:	812080e7          	jalr	-2030(ra) # 800019f8 <myproc>
    800021ee:	89aa                	mv	s3,a0
  if(p == initproc)
    800021f0:	00006797          	auipc	a5,0x6
    800021f4:	6d87b783          	ld	a5,1752(a5) # 800088c8 <initproc>
    800021f8:	0d050493          	addi	s1,a0,208
    800021fc:	15050913          	addi	s2,a0,336
    80002200:	02a79363          	bne	a5,a0,80002226 <exit+0x52>
    panic("init exiting");
    80002204:	00006517          	auipc	a0,0x6
    80002208:	05c50513          	addi	a0,a0,92 # 80008260 <digits+0x220>
    8000220c:	ffffe097          	auipc	ra,0xffffe
    80002210:	332080e7          	jalr	818(ra) # 8000053e <panic>
      fileclose(f);
    80002214:	00002097          	auipc	ra,0x2
    80002218:	3e0080e7          	jalr	992(ra) # 800045f4 <fileclose>
      p->ofile[fd] = 0;
    8000221c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002220:	04a1                	addi	s1,s1,8
    80002222:	01248563          	beq	s1,s2,8000222c <exit+0x58>
    if(p->ofile[fd]){
    80002226:	6088                	ld	a0,0(s1)
    80002228:	f575                	bnez	a0,80002214 <exit+0x40>
    8000222a:	bfdd                	j	80002220 <exit+0x4c>
  begin_op();
    8000222c:	00002097          	auipc	ra,0x2
    80002230:	efc080e7          	jalr	-260(ra) # 80004128 <begin_op>
  iput(p->cwd);
    80002234:	1509b503          	ld	a0,336(s3)
    80002238:	00001097          	auipc	ra,0x1
    8000223c:	6e8080e7          	jalr	1768(ra) # 80003920 <iput>
  end_op();
    80002240:	00002097          	auipc	ra,0x2
    80002244:	f68080e7          	jalr	-152(ra) # 800041a8 <end_op>
  p->cwd = 0;
    80002248:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000224c:	0000f497          	auipc	s1,0xf
    80002250:	90c48493          	addi	s1,s1,-1780 # 80010b58 <wait_lock>
    80002254:	8526                	mv	a0,s1
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	9cc080e7          	jalr	-1588(ra) # 80000c22 <acquire>
  reparent(p);
    8000225e:	854e                	mv	a0,s3
    80002260:	00000097          	auipc	ra,0x0
    80002264:	f1a080e7          	jalr	-230(ra) # 8000217a <reparent>
  wakeup(p->parent);
    80002268:	0389b503          	ld	a0,56(s3)
    8000226c:	00000097          	auipc	ra,0x0
    80002270:	e98080e7          	jalr	-360(ra) # 80002104 <wakeup>
  acquire(&p->lock);
    80002274:	854e                	mv	a0,s3
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	9ac080e7          	jalr	-1620(ra) # 80000c22 <acquire>
  p->xstate = status;
    8000227e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002282:	4795                	li	a5,5
    80002284:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002288:	8526                	mv	a0,s1
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	a4c080e7          	jalr	-1460(ra) # 80000cd6 <release>
  sched();
    80002292:	00000097          	auipc	ra,0x0
    80002296:	cfc080e7          	jalr	-772(ra) # 80001f8e <sched>
  panic("zombie exit");
    8000229a:	00006517          	auipc	a0,0x6
    8000229e:	fd650513          	addi	a0,a0,-42 # 80008270 <digits+0x230>
    800022a2:	ffffe097          	auipc	ra,0xffffe
    800022a6:	29c080e7          	jalr	668(ra) # 8000053e <panic>

00000000800022aa <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022aa:	7179                	addi	sp,sp,-48
    800022ac:	f406                	sd	ra,40(sp)
    800022ae:	f022                	sd	s0,32(sp)
    800022b0:	ec26                	sd	s1,24(sp)
    800022b2:	e84a                	sd	s2,16(sp)
    800022b4:	e44e                	sd	s3,8(sp)
    800022b6:	1800                	addi	s0,sp,48
    800022b8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022ba:	0000f497          	auipc	s1,0xf
    800022be:	cb648493          	addi	s1,s1,-842 # 80010f70 <proc>
    800022c2:	00014997          	auipc	s3,0x14
    800022c6:	6ae98993          	addi	s3,s3,1710 # 80016970 <tickslock>
    acquire(&p->lock);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	956080e7          	jalr	-1706(ra) # 80000c22 <acquire>
    if(p->pid == pid){
    800022d4:	589c                	lw	a5,48(s1)
    800022d6:	01278d63          	beq	a5,s2,800022f0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022da:	8526                	mv	a0,s1
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	9fa080e7          	jalr	-1542(ra) # 80000cd6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022e4:	16848493          	addi	s1,s1,360
    800022e8:	ff3491e3          	bne	s1,s3,800022ca <kill+0x20>
  }
  return -1;
    800022ec:	557d                	li	a0,-1
    800022ee:	a829                	j	80002308 <kill+0x5e>
      p->killed = 1;
    800022f0:	4785                	li	a5,1
    800022f2:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022f4:	4c98                	lw	a4,24(s1)
    800022f6:	4789                	li	a5,2
    800022f8:	00f70f63          	beq	a4,a5,80002316 <kill+0x6c>
      release(&p->lock);
    800022fc:	8526                	mv	a0,s1
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	9d8080e7          	jalr	-1576(ra) # 80000cd6 <release>
      return 0;
    80002306:	4501                	li	a0,0
}
    80002308:	70a2                	ld	ra,40(sp)
    8000230a:	7402                	ld	s0,32(sp)
    8000230c:	64e2                	ld	s1,24(sp)
    8000230e:	6942                	ld	s2,16(sp)
    80002310:	69a2                	ld	s3,8(sp)
    80002312:	6145                	addi	sp,sp,48
    80002314:	8082                	ret
        p->state = RUNNABLE;
    80002316:	478d                	li	a5,3
    80002318:	cc9c                	sw	a5,24(s1)
    8000231a:	b7cd                	j	800022fc <kill+0x52>

000000008000231c <setkilled>:

void
setkilled(struct proc *p)
{
    8000231c:	1101                	addi	sp,sp,-32
    8000231e:	ec06                	sd	ra,24(sp)
    80002320:	e822                	sd	s0,16(sp)
    80002322:	e426                	sd	s1,8(sp)
    80002324:	1000                	addi	s0,sp,32
    80002326:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	8fa080e7          	jalr	-1798(ra) # 80000c22 <acquire>
  p->killed = 1;
    80002330:	4785                	li	a5,1
    80002332:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	9a0080e7          	jalr	-1632(ra) # 80000cd6 <release>
}
    8000233e:	60e2                	ld	ra,24(sp)
    80002340:	6442                	ld	s0,16(sp)
    80002342:	64a2                	ld	s1,8(sp)
    80002344:	6105                	addi	sp,sp,32
    80002346:	8082                	ret

0000000080002348 <killed>:

int
killed(struct proc *p)
{
    80002348:	1101                	addi	sp,sp,-32
    8000234a:	ec06                	sd	ra,24(sp)
    8000234c:	e822                	sd	s0,16(sp)
    8000234e:	e426                	sd	s1,8(sp)
    80002350:	e04a                	sd	s2,0(sp)
    80002352:	1000                	addi	s0,sp,32
    80002354:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	8cc080e7          	jalr	-1844(ra) # 80000c22 <acquire>
  k = p->killed;
    8000235e:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	972080e7          	jalr	-1678(ra) # 80000cd6 <release>
  return k;
}
    8000236c:	854a                	mv	a0,s2
    8000236e:	60e2                	ld	ra,24(sp)
    80002370:	6442                	ld	s0,16(sp)
    80002372:	64a2                	ld	s1,8(sp)
    80002374:	6902                	ld	s2,0(sp)
    80002376:	6105                	addi	sp,sp,32
    80002378:	8082                	ret

000000008000237a <wait>:
{
    8000237a:	715d                	addi	sp,sp,-80
    8000237c:	e486                	sd	ra,72(sp)
    8000237e:	e0a2                	sd	s0,64(sp)
    80002380:	fc26                	sd	s1,56(sp)
    80002382:	f84a                	sd	s2,48(sp)
    80002384:	f44e                	sd	s3,40(sp)
    80002386:	f052                	sd	s4,32(sp)
    80002388:	ec56                	sd	s5,24(sp)
    8000238a:	e85a                	sd	s6,16(sp)
    8000238c:	e45e                	sd	s7,8(sp)
    8000238e:	e062                	sd	s8,0(sp)
    80002390:	0880                	addi	s0,sp,80
    80002392:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	664080e7          	jalr	1636(ra) # 800019f8 <myproc>
    8000239c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000239e:	0000e517          	auipc	a0,0xe
    800023a2:	7ba50513          	addi	a0,a0,1978 # 80010b58 <wait_lock>
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	87c080e7          	jalr	-1924(ra) # 80000c22 <acquire>
    havekids = 0;
    800023ae:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023b0:	4a15                	li	s4,5
        havekids = 1;
    800023b2:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023b4:	00014997          	auipc	s3,0x14
    800023b8:	5bc98993          	addi	s3,s3,1468 # 80016970 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023bc:	0000ec17          	auipc	s8,0xe
    800023c0:	79cc0c13          	addi	s8,s8,1948 # 80010b58 <wait_lock>
    havekids = 0;
    800023c4:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023c6:	0000f497          	auipc	s1,0xf
    800023ca:	baa48493          	addi	s1,s1,-1110 # 80010f70 <proc>
    800023ce:	a0bd                	j	8000243c <wait+0xc2>
          pid = pp->pid;
    800023d0:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023d4:	000b0e63          	beqz	s6,800023f0 <wait+0x76>
    800023d8:	4691                	li	a3,4
    800023da:	02c48613          	addi	a2,s1,44
    800023de:	85da                	mv	a1,s6
    800023e0:	05093503          	ld	a0,80(s2)
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	2d0080e7          	jalr	720(ra) # 800016b4 <copyout>
    800023ec:	02054563          	bltz	a0,80002416 <wait+0x9c>
          freeproc(pp);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	7b8080e7          	jalr	1976(ra) # 80001baa <freeproc>
          release(&pp->lock);
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	8da080e7          	jalr	-1830(ra) # 80000cd6 <release>
          release(&wait_lock);
    80002404:	0000e517          	auipc	a0,0xe
    80002408:	75450513          	addi	a0,a0,1876 # 80010b58 <wait_lock>
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	8ca080e7          	jalr	-1846(ra) # 80000cd6 <release>
          return pid;
    80002414:	a0b5                	j	80002480 <wait+0x106>
            release(&pp->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	8be080e7          	jalr	-1858(ra) # 80000cd6 <release>
            release(&wait_lock);
    80002420:	0000e517          	auipc	a0,0xe
    80002424:	73850513          	addi	a0,a0,1848 # 80010b58 <wait_lock>
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	8ae080e7          	jalr	-1874(ra) # 80000cd6 <release>
            return -1;
    80002430:	59fd                	li	s3,-1
    80002432:	a0b9                	j	80002480 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002434:	16848493          	addi	s1,s1,360
    80002438:	03348463          	beq	s1,s3,80002460 <wait+0xe6>
      if(pp->parent == p){
    8000243c:	7c9c                	ld	a5,56(s1)
    8000243e:	ff279be3          	bne	a5,s2,80002434 <wait+0xba>
        acquire(&pp->lock);
    80002442:	8526                	mv	a0,s1
    80002444:	ffffe097          	auipc	ra,0xffffe
    80002448:	7de080e7          	jalr	2014(ra) # 80000c22 <acquire>
        if(pp->state == ZOMBIE){
    8000244c:	4c9c                	lw	a5,24(s1)
    8000244e:	f94781e3          	beq	a5,s4,800023d0 <wait+0x56>
        release(&pp->lock);
    80002452:	8526                	mv	a0,s1
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	882080e7          	jalr	-1918(ra) # 80000cd6 <release>
        havekids = 1;
    8000245c:	8756                	mv	a4,s5
    8000245e:	bfd9                	j	80002434 <wait+0xba>
    if(!havekids || killed(p)){
    80002460:	c719                	beqz	a4,8000246e <wait+0xf4>
    80002462:	854a                	mv	a0,s2
    80002464:	00000097          	auipc	ra,0x0
    80002468:	ee4080e7          	jalr	-284(ra) # 80002348 <killed>
    8000246c:	c51d                	beqz	a0,8000249a <wait+0x120>
      release(&wait_lock);
    8000246e:	0000e517          	auipc	a0,0xe
    80002472:	6ea50513          	addi	a0,a0,1770 # 80010b58 <wait_lock>
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	860080e7          	jalr	-1952(ra) # 80000cd6 <release>
      return -1;
    8000247e:	59fd                	li	s3,-1
}
    80002480:	854e                	mv	a0,s3
    80002482:	60a6                	ld	ra,72(sp)
    80002484:	6406                	ld	s0,64(sp)
    80002486:	74e2                	ld	s1,56(sp)
    80002488:	7942                	ld	s2,48(sp)
    8000248a:	79a2                	ld	s3,40(sp)
    8000248c:	7a02                	ld	s4,32(sp)
    8000248e:	6ae2                	ld	s5,24(sp)
    80002490:	6b42                	ld	s6,16(sp)
    80002492:	6ba2                	ld	s7,8(sp)
    80002494:	6c02                	ld	s8,0(sp)
    80002496:	6161                	addi	sp,sp,80
    80002498:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000249a:	85e2                	mv	a1,s8
    8000249c:	854a                	mv	a0,s2
    8000249e:	00000097          	auipc	ra,0x0
    800024a2:	c02080e7          	jalr	-1022(ra) # 800020a0 <sleep>
    havekids = 0;
    800024a6:	bf39                	j	800023c4 <wait+0x4a>

00000000800024a8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024a8:	7179                	addi	sp,sp,-48
    800024aa:	f406                	sd	ra,40(sp)
    800024ac:	f022                	sd	s0,32(sp)
    800024ae:	ec26                	sd	s1,24(sp)
    800024b0:	e84a                	sd	s2,16(sp)
    800024b2:	e44e                	sd	s3,8(sp)
    800024b4:	e052                	sd	s4,0(sp)
    800024b6:	1800                	addi	s0,sp,48
    800024b8:	84aa                	mv	s1,a0
    800024ba:	892e                	mv	s2,a1
    800024bc:	89b2                	mv	s3,a2
    800024be:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	538080e7          	jalr	1336(ra) # 800019f8 <myproc>
  if(user_dst){
    800024c8:	c08d                	beqz	s1,800024ea <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024ca:	86d2                	mv	a3,s4
    800024cc:	864e                	mv	a2,s3
    800024ce:	85ca                	mv	a1,s2
    800024d0:	6928                	ld	a0,80(a0)
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	1e2080e7          	jalr	482(ra) # 800016b4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024da:	70a2                	ld	ra,40(sp)
    800024dc:	7402                	ld	s0,32(sp)
    800024de:	64e2                	ld	s1,24(sp)
    800024e0:	6942                	ld	s2,16(sp)
    800024e2:	69a2                	ld	s3,8(sp)
    800024e4:	6a02                	ld	s4,0(sp)
    800024e6:	6145                	addi	sp,sp,48
    800024e8:	8082                	ret
    memmove((char *)dst, src, len);
    800024ea:	000a061b          	sext.w	a2,s4
    800024ee:	85ce                	mv	a1,s3
    800024f0:	854a                	mv	a0,s2
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	888080e7          	jalr	-1912(ra) # 80000d7a <memmove>
    return 0;
    800024fa:	8526                	mv	a0,s1
    800024fc:	bff9                	j	800024da <either_copyout+0x32>

00000000800024fe <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024fe:	7179                	addi	sp,sp,-48
    80002500:	f406                	sd	ra,40(sp)
    80002502:	f022                	sd	s0,32(sp)
    80002504:	ec26                	sd	s1,24(sp)
    80002506:	e84a                	sd	s2,16(sp)
    80002508:	e44e                	sd	s3,8(sp)
    8000250a:	e052                	sd	s4,0(sp)
    8000250c:	1800                	addi	s0,sp,48
    8000250e:	892a                	mv	s2,a0
    80002510:	84ae                	mv	s1,a1
    80002512:	89b2                	mv	s3,a2
    80002514:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	4e2080e7          	jalr	1250(ra) # 800019f8 <myproc>
  if(user_src){
    8000251e:	c08d                	beqz	s1,80002540 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002520:	86d2                	mv	a3,s4
    80002522:	864e                	mv	a2,s3
    80002524:	85ca                	mv	a1,s2
    80002526:	6928                	ld	a0,80(a0)
    80002528:	fffff097          	auipc	ra,0xfffff
    8000252c:	218080e7          	jalr	536(ra) # 80001740 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002530:	70a2                	ld	ra,40(sp)
    80002532:	7402                	ld	s0,32(sp)
    80002534:	64e2                	ld	s1,24(sp)
    80002536:	6942                	ld	s2,16(sp)
    80002538:	69a2                	ld	s3,8(sp)
    8000253a:	6a02                	ld	s4,0(sp)
    8000253c:	6145                	addi	sp,sp,48
    8000253e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002540:	000a061b          	sext.w	a2,s4
    80002544:	85ce                	mv	a1,s3
    80002546:	854a                	mv	a0,s2
    80002548:	fffff097          	auipc	ra,0xfffff
    8000254c:	832080e7          	jalr	-1998(ra) # 80000d7a <memmove>
    return 0;
    80002550:	8526                	mv	a0,s1
    80002552:	bff9                	j	80002530 <either_copyin+0x32>

0000000080002554 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002554:	715d                	addi	sp,sp,-80
    80002556:	e486                	sd	ra,72(sp)
    80002558:	e0a2                	sd	s0,64(sp)
    8000255a:	fc26                	sd	s1,56(sp)
    8000255c:	f84a                	sd	s2,48(sp)
    8000255e:	f44e                	sd	s3,40(sp)
    80002560:	f052                	sd	s4,32(sp)
    80002562:	ec56                	sd	s5,24(sp)
    80002564:	e85a                	sd	s6,16(sp)
    80002566:	e45e                	sd	s7,8(sp)
    80002568:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000256a:	00006517          	auipc	a0,0x6
    8000256e:	b5e50513          	addi	a0,a0,-1186 # 800080c8 <digits+0x88>
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	016080e7          	jalr	22(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257a:	0000f497          	auipc	s1,0xf
    8000257e:	b4e48493          	addi	s1,s1,-1202 # 800110c8 <proc+0x158>
    80002582:	00014917          	auipc	s2,0x14
    80002586:	54690913          	addi	s2,s2,1350 # 80016ac8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000258c:	00006997          	auipc	s3,0x6
    80002590:	cf498993          	addi	s3,s3,-780 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002594:	00006a97          	auipc	s5,0x6
    80002598:	cf4a8a93          	addi	s5,s5,-780 # 80008288 <digits+0x248>
    printf("\n");
    8000259c:	00006a17          	auipc	s4,0x6
    800025a0:	b2ca0a13          	addi	s4,s4,-1236 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a4:	00006b97          	auipc	s7,0x6
    800025a8:	d24b8b93          	addi	s7,s7,-732 # 800082c8 <states.0>
    800025ac:	a00d                	j	800025ce <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025ae:	ed86a583          	lw	a1,-296(a3)
    800025b2:	8556                	mv	a0,s5
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	fd4080e7          	jalr	-44(ra) # 80000588 <printf>
    printf("\n");
    800025bc:	8552                	mv	a0,s4
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	fca080e7          	jalr	-54(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c6:	16848493          	addi	s1,s1,360
    800025ca:	03248163          	beq	s1,s2,800025ec <procdump+0x98>
    if(p->state == UNUSED)
    800025ce:	86a6                	mv	a3,s1
    800025d0:	ec04a783          	lw	a5,-320(s1)
    800025d4:	dbed                	beqz	a5,800025c6 <procdump+0x72>
      state = "???";
    800025d6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d8:	fcfb6be3          	bltu	s6,a5,800025ae <procdump+0x5a>
    800025dc:	1782                	slli	a5,a5,0x20
    800025de:	9381                	srli	a5,a5,0x20
    800025e0:	078e                	slli	a5,a5,0x3
    800025e2:	97de                	add	a5,a5,s7
    800025e4:	6390                	ld	a2,0(a5)
    800025e6:	f661                	bnez	a2,800025ae <procdump+0x5a>
      state = "???";
    800025e8:	864e                	mv	a2,s3
    800025ea:	b7d1                	j	800025ae <procdump+0x5a>
  }
}
    800025ec:	60a6                	ld	ra,72(sp)
    800025ee:	6406                	ld	s0,64(sp)
    800025f0:	74e2                	ld	s1,56(sp)
    800025f2:	7942                	ld	s2,48(sp)
    800025f4:	79a2                	ld	s3,40(sp)
    800025f6:	7a02                	ld	s4,32(sp)
    800025f8:	6ae2                	ld	s5,24(sp)
    800025fa:	6b42                	ld	s6,16(sp)
    800025fc:	6ba2                	ld	s7,8(sp)
    800025fe:	6161                	addi	sp,sp,80
    80002600:	8082                	ret

0000000080002602 <find_active_proc>:
//    printf("free ram: %d\n",uinfo.freeram);
//    printf("active processes: %d\n",uinfo.procs);
    return 0;
}

int find_active_proc() {
    80002602:	7179                	addi	sp,sp,-48
    80002604:	f406                	sd	ra,40(sp)
    80002606:	f022                	sd	s0,32(sp)
    80002608:	ec26                	sd	s1,24(sp)
    8000260a:	e84a                	sd	s2,16(sp)
    8000260c:	e44e                	sd	s3,8(sp)
    8000260e:	1800                	addi	s0,sp,48
    int counter = 0;
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++) {
    80002610:	0000f497          	auipc	s1,0xf
    80002614:	96048493          	addi	s1,s1,-1696 # 80010f70 <proc>
    int counter = 0;
    80002618:	4901                	li	s2,0
    for (p = proc; p < &proc[NPROC]; p++) {
    8000261a:	00014997          	auipc	s3,0x14
    8000261e:	35698993          	addi	s3,s3,854 # 80016970 <tickslock>
    80002622:	a811                	j	80002636 <find_active_proc+0x34>
        acquire(&p->lock);
        if (p->state != UNUSED) {
            counter++;
        }
        release(&p->lock);
    80002624:	8526                	mv	a0,s1
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	6b0080e7          	jalr	1712(ra) # 80000cd6 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    8000262e:	16848493          	addi	s1,s1,360
    80002632:	01348b63          	beq	s1,s3,80002648 <find_active_proc+0x46>
        acquire(&p->lock);
    80002636:	8526                	mv	a0,s1
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	5ea080e7          	jalr	1514(ra) # 80000c22 <acquire>
        if (p->state != UNUSED) {
    80002640:	4c9c                	lw	a5,24(s1)
    80002642:	d3ed                	beqz	a5,80002624 <find_active_proc+0x22>
            counter++;
    80002644:	2905                	addiw	s2,s2,1
    80002646:	bff9                	j	80002624 <find_active_proc+0x22>
    }
    return counter;
}
    80002648:	854a                	mv	a0,s2
    8000264a:	70a2                	ld	ra,40(sp)
    8000264c:	7402                	ld	s0,32(sp)
    8000264e:	64e2                	ld	s1,24(sp)
    80002650:	6942                	ld	s2,16(sp)
    80002652:	69a2                	ld	s3,8(sp)
    80002654:	6145                	addi	sp,sp,48
    80002656:	8082                	ret

0000000080002658 <sysinfo>:
int sysinfo(uint64 uinfo) {
    80002658:	7139                	addi	sp,sp,-64
    8000265a:	fc06                	sd	ra,56(sp)
    8000265c:	f822                	sd	s0,48(sp)
    8000265e:	f426                	sd	s1,40(sp)
    80002660:	0080                	addi	s0,sp,64
    80002662:	84aa                	mv	s1,a0
    info.uptime = uptime;
    80002664:	00006797          	auipc	a5,0x6
    80002668:	26c7a783          	lw	a5,620(a5) # 800088d0 <ticks>
    8000266c:	00989737          	lui	a4,0x989
    80002670:	6807071b          	addiw	a4,a4,1664
    80002674:	02e7d7bb          	divuw	a5,a5,a4
    80002678:	fcf43023          	sd	a5,-64(s0)
    info.procs = find_active_proc();
    8000267c:	00000097          	auipc	ra,0x0
    80002680:	f86080e7          	jalr	-122(ra) # 80002602 <find_active_proc>
    80002684:	fca41c23          	sh	a0,-40(s0)
    info.freeram = calculate_free_ram();
    80002688:	ffffe097          	auipc	ra,0xffffe
    8000268c:	4be080e7          	jalr	1214(ra) # 80000b46 <calculate_free_ram>
    80002690:	fca43823          	sd	a0,-48(s0)
    info.totalram = PHYSTOP - KERNBASE;
    80002694:	080007b7          	lui	a5,0x8000
    80002698:	fcf43423          	sd	a5,-56(s0)
    if (copyout(myproc()->pagetable, uinfo, (char *) &info, sizeof(struct sysinfo)) < 0) {
    8000269c:	fffff097          	auipc	ra,0xfffff
    800026a0:	35c080e7          	jalr	860(ra) # 800019f8 <myproc>
    800026a4:	02000693          	li	a3,32
    800026a8:	fc040613          	addi	a2,s0,-64
    800026ac:	85a6                	mv	a1,s1
    800026ae:	6928                	ld	a0,80(a0)
    800026b0:	fffff097          	auipc	ra,0xfffff
    800026b4:	004080e7          	jalr	4(ra) # 800016b4 <copyout>
}
    800026b8:	41f5551b          	sraiw	a0,a0,0x1f
    800026bc:	70e2                	ld	ra,56(sp)
    800026be:	7442                	ld	s0,48(sp)
    800026c0:	74a2                	ld	s1,40(sp)
    800026c2:	6121                	addi	sp,sp,64
    800026c4:	8082                	ret

00000000800026c6 <swtch>:
    800026c6:	00153023          	sd	ra,0(a0)
    800026ca:	00253423          	sd	sp,8(a0)
    800026ce:	e900                	sd	s0,16(a0)
    800026d0:	ed04                	sd	s1,24(a0)
    800026d2:	03253023          	sd	s2,32(a0)
    800026d6:	03353423          	sd	s3,40(a0)
    800026da:	03453823          	sd	s4,48(a0)
    800026de:	03553c23          	sd	s5,56(a0)
    800026e2:	05653023          	sd	s6,64(a0)
    800026e6:	05753423          	sd	s7,72(a0)
    800026ea:	05853823          	sd	s8,80(a0)
    800026ee:	05953c23          	sd	s9,88(a0)
    800026f2:	07a53023          	sd	s10,96(a0)
    800026f6:	07b53423          	sd	s11,104(a0)
    800026fa:	0005b083          	ld	ra,0(a1)
    800026fe:	0085b103          	ld	sp,8(a1)
    80002702:	6980                	ld	s0,16(a1)
    80002704:	6d84                	ld	s1,24(a1)
    80002706:	0205b903          	ld	s2,32(a1)
    8000270a:	0285b983          	ld	s3,40(a1)
    8000270e:	0305ba03          	ld	s4,48(a1)
    80002712:	0385ba83          	ld	s5,56(a1)
    80002716:	0405bb03          	ld	s6,64(a1)
    8000271a:	0485bb83          	ld	s7,72(a1)
    8000271e:	0505bc03          	ld	s8,80(a1)
    80002722:	0585bc83          	ld	s9,88(a1)
    80002726:	0605bd03          	ld	s10,96(a1)
    8000272a:	0685bd83          	ld	s11,104(a1)
    8000272e:	8082                	ret

0000000080002730 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002730:	1141                	addi	sp,sp,-16
    80002732:	e406                	sd	ra,8(sp)
    80002734:	e022                	sd	s0,0(sp)
    80002736:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002738:	00006597          	auipc	a1,0x6
    8000273c:	bc058593          	addi	a1,a1,-1088 # 800082f8 <states.0+0x30>
    80002740:	00014517          	auipc	a0,0x14
    80002744:	23050513          	addi	a0,a0,560 # 80016970 <tickslock>
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	44a080e7          	jalr	1098(ra) # 80000b92 <initlock>
}
    80002750:	60a2                	ld	ra,8(sp)
    80002752:	6402                	ld	s0,0(sp)
    80002754:	0141                	addi	sp,sp,16
    80002756:	8082                	ret

0000000080002758 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002758:	1141                	addi	sp,sp,-16
    8000275a:	e422                	sd	s0,8(sp)
    8000275c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000275e:	00003797          	auipc	a5,0x3
    80002762:	4e278793          	addi	a5,a5,1250 # 80005c40 <kernelvec>
    80002766:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000276a:	6422                	ld	s0,8(sp)
    8000276c:	0141                	addi	sp,sp,16
    8000276e:	8082                	ret

0000000080002770 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002770:	1141                	addi	sp,sp,-16
    80002772:	e406                	sd	ra,8(sp)
    80002774:	e022                	sd	s0,0(sp)
    80002776:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002778:	fffff097          	auipc	ra,0xfffff
    8000277c:	280080e7          	jalr	640(ra) # 800019f8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002780:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002784:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002786:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000278a:	00005617          	auipc	a2,0x5
    8000278e:	87660613          	addi	a2,a2,-1930 # 80007000 <_trampoline>
    80002792:	00005697          	auipc	a3,0x5
    80002796:	86e68693          	addi	a3,a3,-1938 # 80007000 <_trampoline>
    8000279a:	8e91                	sub	a3,a3,a2
    8000279c:	040007b7          	lui	a5,0x4000
    800027a0:	17fd                	addi	a5,a5,-1
    800027a2:	07b2                	slli	a5,a5,0xc
    800027a4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027a6:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027aa:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027ac:	180026f3          	csrr	a3,satp
    800027b0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027b2:	6d38                	ld	a4,88(a0)
    800027b4:	6134                	ld	a3,64(a0)
    800027b6:	6585                	lui	a1,0x1
    800027b8:	96ae                	add	a3,a3,a1
    800027ba:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027bc:	6d38                	ld	a4,88(a0)
    800027be:	00000697          	auipc	a3,0x0
    800027c2:	13068693          	addi	a3,a3,304 # 800028ee <usertrap>
    800027c6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027c8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027ca:	8692                	mv	a3,tp
    800027cc:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ce:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027d2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027d6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027da:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027de:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027e0:	6f18                	ld	a4,24(a4)
    800027e2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027e6:	6928                	ld	a0,80(a0)
    800027e8:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800027ea:	00005717          	auipc	a4,0x5
    800027ee:	8b270713          	addi	a4,a4,-1870 # 8000709c <userret>
    800027f2:	8f11                	sub	a4,a4,a2
    800027f4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800027f6:	577d                	li	a4,-1
    800027f8:	177e                	slli	a4,a4,0x3f
    800027fa:	8d59                	or	a0,a0,a4
    800027fc:	9782                	jalr	a5
}
    800027fe:	60a2                	ld	ra,8(sp)
    80002800:	6402                	ld	s0,0(sp)
    80002802:	0141                	addi	sp,sp,16
    80002804:	8082                	ret

0000000080002806 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002806:	1101                	addi	sp,sp,-32
    80002808:	ec06                	sd	ra,24(sp)
    8000280a:	e822                	sd	s0,16(sp)
    8000280c:	e426                	sd	s1,8(sp)
    8000280e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002810:	00014497          	auipc	s1,0x14
    80002814:	16048493          	addi	s1,s1,352 # 80016970 <tickslock>
    80002818:	8526                	mv	a0,s1
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	408080e7          	jalr	1032(ra) # 80000c22 <acquire>
  ticks++;
    80002822:	00006517          	auipc	a0,0x6
    80002826:	0ae50513          	addi	a0,a0,174 # 800088d0 <ticks>
    8000282a:	411c                	lw	a5,0(a0)
    8000282c:	2785                	addiw	a5,a5,1
    8000282e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002830:	00000097          	auipc	ra,0x0
    80002834:	8d4080e7          	jalr	-1836(ra) # 80002104 <wakeup>
  release(&tickslock);
    80002838:	8526                	mv	a0,s1
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	49c080e7          	jalr	1180(ra) # 80000cd6 <release>
}
    80002842:	60e2                	ld	ra,24(sp)
    80002844:	6442                	ld	s0,16(sp)
    80002846:	64a2                	ld	s1,8(sp)
    80002848:	6105                	addi	sp,sp,32
    8000284a:	8082                	ret

000000008000284c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000284c:	1101                	addi	sp,sp,-32
    8000284e:	ec06                	sd	ra,24(sp)
    80002850:	e822                	sd	s0,16(sp)
    80002852:	e426                	sd	s1,8(sp)
    80002854:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002856:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000285a:	00074d63          	bltz	a4,80002874 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000285e:	57fd                	li	a5,-1
    80002860:	17fe                	slli	a5,a5,0x3f
    80002862:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002864:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002866:	06f70363          	beq	a4,a5,800028cc <devintr+0x80>
  }
}
    8000286a:	60e2                	ld	ra,24(sp)
    8000286c:	6442                	ld	s0,16(sp)
    8000286e:	64a2                	ld	s1,8(sp)
    80002870:	6105                	addi	sp,sp,32
    80002872:	8082                	ret
     (scause & 0xff) == 9){
    80002874:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002878:	46a5                	li	a3,9
    8000287a:	fed792e3          	bne	a5,a3,8000285e <devintr+0x12>
    int irq = plic_claim();
    8000287e:	00003097          	auipc	ra,0x3
    80002882:	4ca080e7          	jalr	1226(ra) # 80005d48 <plic_claim>
    80002886:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002888:	47a9                	li	a5,10
    8000288a:	02f50763          	beq	a0,a5,800028b8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000288e:	4785                	li	a5,1
    80002890:	02f50963          	beq	a0,a5,800028c2 <devintr+0x76>
    return 1;
    80002894:	4505                	li	a0,1
    } else if(irq){
    80002896:	d8f1                	beqz	s1,8000286a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002898:	85a6                	mv	a1,s1
    8000289a:	00006517          	auipc	a0,0x6
    8000289e:	a6650513          	addi	a0,a0,-1434 # 80008300 <states.0+0x38>
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	ce6080e7          	jalr	-794(ra) # 80000588 <printf>
      plic_complete(irq);
    800028aa:	8526                	mv	a0,s1
    800028ac:	00003097          	auipc	ra,0x3
    800028b0:	4c0080e7          	jalr	1216(ra) # 80005d6c <plic_complete>
    return 1;
    800028b4:	4505                	li	a0,1
    800028b6:	bf55                	j	8000286a <devintr+0x1e>
      uartintr();
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	0e2080e7          	jalr	226(ra) # 8000099a <uartintr>
    800028c0:	b7ed                	j	800028aa <devintr+0x5e>
      virtio_disk_intr();
    800028c2:	00004097          	auipc	ra,0x4
    800028c6:	976080e7          	jalr	-1674(ra) # 80006238 <virtio_disk_intr>
    800028ca:	b7c5                	j	800028aa <devintr+0x5e>
    if(cpuid() == 0){
    800028cc:	fffff097          	auipc	ra,0xfffff
    800028d0:	100080e7          	jalr	256(ra) # 800019cc <cpuid>
    800028d4:	c901                	beqz	a0,800028e4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028d6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028da:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028dc:	14479073          	csrw	sip,a5
    return 2;
    800028e0:	4509                	li	a0,2
    800028e2:	b761                	j	8000286a <devintr+0x1e>
      clockintr();
    800028e4:	00000097          	auipc	ra,0x0
    800028e8:	f22080e7          	jalr	-222(ra) # 80002806 <clockintr>
    800028ec:	b7ed                	j	800028d6 <devintr+0x8a>

00000000800028ee <usertrap>:
{
    800028ee:	1101                	addi	sp,sp,-32
    800028f0:	ec06                	sd	ra,24(sp)
    800028f2:	e822                	sd	s0,16(sp)
    800028f4:	e426                	sd	s1,8(sp)
    800028f6:	e04a                	sd	s2,0(sp)
    800028f8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fa:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028fe:	1007f793          	andi	a5,a5,256
    80002902:	e3b1                	bnez	a5,80002946 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002904:	00003797          	auipc	a5,0x3
    80002908:	33c78793          	addi	a5,a5,828 # 80005c40 <kernelvec>
    8000290c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002910:	fffff097          	auipc	ra,0xfffff
    80002914:	0e8080e7          	jalr	232(ra) # 800019f8 <myproc>
    80002918:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000291a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000291c:	14102773          	csrr	a4,sepc
    80002920:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002922:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002926:	47a1                	li	a5,8
    80002928:	02f70763          	beq	a4,a5,80002956 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000292c:	00000097          	auipc	ra,0x0
    80002930:	f20080e7          	jalr	-224(ra) # 8000284c <devintr>
    80002934:	892a                	mv	s2,a0
    80002936:	c151                	beqz	a0,800029ba <usertrap+0xcc>
  if(killed(p))
    80002938:	8526                	mv	a0,s1
    8000293a:	00000097          	auipc	ra,0x0
    8000293e:	a0e080e7          	jalr	-1522(ra) # 80002348 <killed>
    80002942:	c929                	beqz	a0,80002994 <usertrap+0xa6>
    80002944:	a099                	j	8000298a <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002946:	00006517          	auipc	a0,0x6
    8000294a:	9da50513          	addi	a0,a0,-1574 # 80008320 <states.0+0x58>
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	bf0080e7          	jalr	-1040(ra) # 8000053e <panic>
    if(killed(p))
    80002956:	00000097          	auipc	ra,0x0
    8000295a:	9f2080e7          	jalr	-1550(ra) # 80002348 <killed>
    8000295e:	e921                	bnez	a0,800029ae <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002960:	6cb8                	ld	a4,88(s1)
    80002962:	6f1c                	ld	a5,24(a4)
    80002964:	0791                	addi	a5,a5,4
    80002966:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002968:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000296c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002970:	10079073          	csrw	sstatus,a5
    syscall();
    80002974:	00000097          	auipc	ra,0x0
    80002978:	2d4080e7          	jalr	724(ra) # 80002c48 <syscall>
  if(killed(p))
    8000297c:	8526                	mv	a0,s1
    8000297e:	00000097          	auipc	ra,0x0
    80002982:	9ca080e7          	jalr	-1590(ra) # 80002348 <killed>
    80002986:	c911                	beqz	a0,8000299a <usertrap+0xac>
    80002988:	4901                	li	s2,0
    exit(-1);
    8000298a:	557d                	li	a0,-1
    8000298c:	00000097          	auipc	ra,0x0
    80002990:	848080e7          	jalr	-1976(ra) # 800021d4 <exit>
  if(which_dev == 2)
    80002994:	4789                	li	a5,2
    80002996:	04f90f63          	beq	s2,a5,800029f4 <usertrap+0x106>
  usertrapret();
    8000299a:	00000097          	auipc	ra,0x0
    8000299e:	dd6080e7          	jalr	-554(ra) # 80002770 <usertrapret>
}
    800029a2:	60e2                	ld	ra,24(sp)
    800029a4:	6442                	ld	s0,16(sp)
    800029a6:	64a2                	ld	s1,8(sp)
    800029a8:	6902                	ld	s2,0(sp)
    800029aa:	6105                	addi	sp,sp,32
    800029ac:	8082                	ret
      exit(-1);
    800029ae:	557d                	li	a0,-1
    800029b0:	00000097          	auipc	ra,0x0
    800029b4:	824080e7          	jalr	-2012(ra) # 800021d4 <exit>
    800029b8:	b765                	j	80002960 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ba:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029be:	5890                	lw	a2,48(s1)
    800029c0:	00006517          	auipc	a0,0x6
    800029c4:	98050513          	addi	a0,a0,-1664 # 80008340 <states.0+0x78>
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	bc0080e7          	jalr	-1088(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029d0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029d4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029d8:	00006517          	auipc	a0,0x6
    800029dc:	99850513          	addi	a0,a0,-1640 # 80008370 <states.0+0xa8>
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	ba8080e7          	jalr	-1112(ra) # 80000588 <printf>
    setkilled(p);
    800029e8:	8526                	mv	a0,s1
    800029ea:	00000097          	auipc	ra,0x0
    800029ee:	932080e7          	jalr	-1742(ra) # 8000231c <setkilled>
    800029f2:	b769                	j	8000297c <usertrap+0x8e>
    yield();
    800029f4:	fffff097          	auipc	ra,0xfffff
    800029f8:	670080e7          	jalr	1648(ra) # 80002064 <yield>
    800029fc:	bf79                	j	8000299a <usertrap+0xac>

00000000800029fe <kerneltrap>:
{
    800029fe:	7179                	addi	sp,sp,-48
    80002a00:	f406                	sd	ra,40(sp)
    80002a02:	f022                	sd	s0,32(sp)
    80002a04:	ec26                	sd	s1,24(sp)
    80002a06:	e84a                	sd	s2,16(sp)
    80002a08:	e44e                	sd	s3,8(sp)
    80002a0a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a0c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a10:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a14:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a18:	1004f793          	andi	a5,s1,256
    80002a1c:	cb85                	beqz	a5,80002a4c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a1e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a22:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a24:	ef85                	bnez	a5,80002a5c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a26:	00000097          	auipc	ra,0x0
    80002a2a:	e26080e7          	jalr	-474(ra) # 8000284c <devintr>
    80002a2e:	cd1d                	beqz	a0,80002a6c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a30:	4789                	li	a5,2
    80002a32:	06f50a63          	beq	a0,a5,80002aa6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a36:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a3a:	10049073          	csrw	sstatus,s1
}
    80002a3e:	70a2                	ld	ra,40(sp)
    80002a40:	7402                	ld	s0,32(sp)
    80002a42:	64e2                	ld	s1,24(sp)
    80002a44:	6942                	ld	s2,16(sp)
    80002a46:	69a2                	ld	s3,8(sp)
    80002a48:	6145                	addi	sp,sp,48
    80002a4a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a4c:	00006517          	auipc	a0,0x6
    80002a50:	94450513          	addi	a0,a0,-1724 # 80008390 <states.0+0xc8>
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	aea080e7          	jalr	-1302(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a5c:	00006517          	auipc	a0,0x6
    80002a60:	95c50513          	addi	a0,a0,-1700 # 800083b8 <states.0+0xf0>
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	ada080e7          	jalr	-1318(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a6c:	85ce                	mv	a1,s3
    80002a6e:	00006517          	auipc	a0,0x6
    80002a72:	96a50513          	addi	a0,a0,-1686 # 800083d8 <states.0+0x110>
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	b12080e7          	jalr	-1262(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a7e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a82:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a86:	00006517          	auipc	a0,0x6
    80002a8a:	96250513          	addi	a0,a0,-1694 # 800083e8 <states.0+0x120>
    80002a8e:	ffffe097          	auipc	ra,0xffffe
    80002a92:	afa080e7          	jalr	-1286(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a96:	00006517          	auipc	a0,0x6
    80002a9a:	96a50513          	addi	a0,a0,-1686 # 80008400 <states.0+0x138>
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	aa0080e7          	jalr	-1376(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002aa6:	fffff097          	auipc	ra,0xfffff
    80002aaa:	f52080e7          	jalr	-174(ra) # 800019f8 <myproc>
    80002aae:	d541                	beqz	a0,80002a36 <kerneltrap+0x38>
    80002ab0:	fffff097          	auipc	ra,0xfffff
    80002ab4:	f48080e7          	jalr	-184(ra) # 800019f8 <myproc>
    80002ab8:	4d18                	lw	a4,24(a0)
    80002aba:	4791                	li	a5,4
    80002abc:	f6f71de3          	bne	a4,a5,80002a36 <kerneltrap+0x38>
    yield();
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	5a4080e7          	jalr	1444(ra) # 80002064 <yield>
    80002ac8:	b7bd                	j	80002a36 <kerneltrap+0x38>

0000000080002aca <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002aca:	1101                	addi	sp,sp,-32
    80002acc:	ec06                	sd	ra,24(sp)
    80002ace:	e822                	sd	s0,16(sp)
    80002ad0:	e426                	sd	s1,8(sp)
    80002ad2:	1000                	addi	s0,sp,32
    80002ad4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	f22080e7          	jalr	-222(ra) # 800019f8 <myproc>
  switch (n) {
    80002ade:	4795                	li	a5,5
    80002ae0:	0497e163          	bltu	a5,s1,80002b22 <argraw+0x58>
    80002ae4:	048a                	slli	s1,s1,0x2
    80002ae6:	00006717          	auipc	a4,0x6
    80002aea:	95270713          	addi	a4,a4,-1710 # 80008438 <states.0+0x170>
    80002aee:	94ba                	add	s1,s1,a4
    80002af0:	409c                	lw	a5,0(s1)
    80002af2:	97ba                	add	a5,a5,a4
    80002af4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002af6:	6d3c                	ld	a5,88(a0)
    80002af8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002afa:	60e2                	ld	ra,24(sp)
    80002afc:	6442                	ld	s0,16(sp)
    80002afe:	64a2                	ld	s1,8(sp)
    80002b00:	6105                	addi	sp,sp,32
    80002b02:	8082                	ret
    return p->trapframe->a1;
    80002b04:	6d3c                	ld	a5,88(a0)
    80002b06:	7fa8                	ld	a0,120(a5)
    80002b08:	bfcd                	j	80002afa <argraw+0x30>
    return p->trapframe->a2;
    80002b0a:	6d3c                	ld	a5,88(a0)
    80002b0c:	63c8                	ld	a0,128(a5)
    80002b0e:	b7f5                	j	80002afa <argraw+0x30>
    return p->trapframe->a3;
    80002b10:	6d3c                	ld	a5,88(a0)
    80002b12:	67c8                	ld	a0,136(a5)
    80002b14:	b7dd                	j	80002afa <argraw+0x30>
    return p->trapframe->a4;
    80002b16:	6d3c                	ld	a5,88(a0)
    80002b18:	6bc8                	ld	a0,144(a5)
    80002b1a:	b7c5                	j	80002afa <argraw+0x30>
    return p->trapframe->a5;
    80002b1c:	6d3c                	ld	a5,88(a0)
    80002b1e:	6fc8                	ld	a0,152(a5)
    80002b20:	bfe9                	j	80002afa <argraw+0x30>
  panic("argraw");
    80002b22:	00006517          	auipc	a0,0x6
    80002b26:	8ee50513          	addi	a0,a0,-1810 # 80008410 <states.0+0x148>
    80002b2a:	ffffe097          	auipc	ra,0xffffe
    80002b2e:	a14080e7          	jalr	-1516(ra) # 8000053e <panic>

0000000080002b32 <fetchaddr>:
{
    80002b32:	1101                	addi	sp,sp,-32
    80002b34:	ec06                	sd	ra,24(sp)
    80002b36:	e822                	sd	s0,16(sp)
    80002b38:	e426                	sd	s1,8(sp)
    80002b3a:	e04a                	sd	s2,0(sp)
    80002b3c:	1000                	addi	s0,sp,32
    80002b3e:	84aa                	mv	s1,a0
    80002b40:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b42:	fffff097          	auipc	ra,0xfffff
    80002b46:	eb6080e7          	jalr	-330(ra) # 800019f8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b4a:	653c                	ld	a5,72(a0)
    80002b4c:	02f4f863          	bgeu	s1,a5,80002b7c <fetchaddr+0x4a>
    80002b50:	00848713          	addi	a4,s1,8
    80002b54:	02e7e663          	bltu	a5,a4,80002b80 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b58:	46a1                	li	a3,8
    80002b5a:	8626                	mv	a2,s1
    80002b5c:	85ca                	mv	a1,s2
    80002b5e:	6928                	ld	a0,80(a0)
    80002b60:	fffff097          	auipc	ra,0xfffff
    80002b64:	be0080e7          	jalr	-1056(ra) # 80001740 <copyin>
    80002b68:	00a03533          	snez	a0,a0
    80002b6c:	40a00533          	neg	a0,a0
}
    80002b70:	60e2                	ld	ra,24(sp)
    80002b72:	6442                	ld	s0,16(sp)
    80002b74:	64a2                	ld	s1,8(sp)
    80002b76:	6902                	ld	s2,0(sp)
    80002b78:	6105                	addi	sp,sp,32
    80002b7a:	8082                	ret
    return -1;
    80002b7c:	557d                	li	a0,-1
    80002b7e:	bfcd                	j	80002b70 <fetchaddr+0x3e>
    80002b80:	557d                	li	a0,-1
    80002b82:	b7fd                	j	80002b70 <fetchaddr+0x3e>

0000000080002b84 <fetchstr>:
{
    80002b84:	7179                	addi	sp,sp,-48
    80002b86:	f406                	sd	ra,40(sp)
    80002b88:	f022                	sd	s0,32(sp)
    80002b8a:	ec26                	sd	s1,24(sp)
    80002b8c:	e84a                	sd	s2,16(sp)
    80002b8e:	e44e                	sd	s3,8(sp)
    80002b90:	1800                	addi	s0,sp,48
    80002b92:	892a                	mv	s2,a0
    80002b94:	84ae                	mv	s1,a1
    80002b96:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b98:	fffff097          	auipc	ra,0xfffff
    80002b9c:	e60080e7          	jalr	-416(ra) # 800019f8 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ba0:	86ce                	mv	a3,s3
    80002ba2:	864a                	mv	a2,s2
    80002ba4:	85a6                	mv	a1,s1
    80002ba6:	6928                	ld	a0,80(a0)
    80002ba8:	fffff097          	auipc	ra,0xfffff
    80002bac:	c26080e7          	jalr	-986(ra) # 800017ce <copyinstr>
    80002bb0:	00054e63          	bltz	a0,80002bcc <fetchstr+0x48>
  return strlen(buf);
    80002bb4:	8526                	mv	a0,s1
    80002bb6:	ffffe097          	auipc	ra,0xffffe
    80002bba:	2e4080e7          	jalr	740(ra) # 80000e9a <strlen>
}
    80002bbe:	70a2                	ld	ra,40(sp)
    80002bc0:	7402                	ld	s0,32(sp)
    80002bc2:	64e2                	ld	s1,24(sp)
    80002bc4:	6942                	ld	s2,16(sp)
    80002bc6:	69a2                	ld	s3,8(sp)
    80002bc8:	6145                	addi	sp,sp,48
    80002bca:	8082                	ret
    return -1;
    80002bcc:	557d                	li	a0,-1
    80002bce:	bfc5                	j	80002bbe <fetchstr+0x3a>

0000000080002bd0 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002bd0:	1101                	addi	sp,sp,-32
    80002bd2:	ec06                	sd	ra,24(sp)
    80002bd4:	e822                	sd	s0,16(sp)
    80002bd6:	e426                	sd	s1,8(sp)
    80002bd8:	1000                	addi	s0,sp,32
    80002bda:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bdc:	00000097          	auipc	ra,0x0
    80002be0:	eee080e7          	jalr	-274(ra) # 80002aca <argraw>
    80002be4:	c088                	sw	a0,0(s1)
}
    80002be6:	60e2                	ld	ra,24(sp)
    80002be8:	6442                	ld	s0,16(sp)
    80002bea:	64a2                	ld	s1,8(sp)
    80002bec:	6105                	addi	sp,sp,32
    80002bee:	8082                	ret

0000000080002bf0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002bf0:	1101                	addi	sp,sp,-32
    80002bf2:	ec06                	sd	ra,24(sp)
    80002bf4:	e822                	sd	s0,16(sp)
    80002bf6:	e426                	sd	s1,8(sp)
    80002bf8:	1000                	addi	s0,sp,32
    80002bfa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bfc:	00000097          	auipc	ra,0x0
    80002c00:	ece080e7          	jalr	-306(ra) # 80002aca <argraw>
    80002c04:	e088                	sd	a0,0(s1)
}
    80002c06:	60e2                	ld	ra,24(sp)
    80002c08:	6442                	ld	s0,16(sp)
    80002c0a:	64a2                	ld	s1,8(sp)
    80002c0c:	6105                	addi	sp,sp,32
    80002c0e:	8082                	ret

0000000080002c10 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c10:	7179                	addi	sp,sp,-48
    80002c12:	f406                	sd	ra,40(sp)
    80002c14:	f022                	sd	s0,32(sp)
    80002c16:	ec26                	sd	s1,24(sp)
    80002c18:	e84a                	sd	s2,16(sp)
    80002c1a:	1800                	addi	s0,sp,48
    80002c1c:	84ae                	mv	s1,a1
    80002c1e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c20:	fd840593          	addi	a1,s0,-40
    80002c24:	00000097          	auipc	ra,0x0
    80002c28:	fcc080e7          	jalr	-52(ra) # 80002bf0 <argaddr>
  return fetchstr(addr, buf, max);
    80002c2c:	864a                	mv	a2,s2
    80002c2e:	85a6                	mv	a1,s1
    80002c30:	fd843503          	ld	a0,-40(s0)
    80002c34:	00000097          	auipc	ra,0x0
    80002c38:	f50080e7          	jalr	-176(ra) # 80002b84 <fetchstr>
}
    80002c3c:	70a2                	ld	ra,40(sp)
    80002c3e:	7402                	ld	s0,32(sp)
    80002c40:	64e2                	ld	s1,24(sp)
    80002c42:	6942                	ld	s2,16(sp)
    80002c44:	6145                	addi	sp,sp,48
    80002c46:	8082                	ret

0000000080002c48 <syscall>:
[SYS_sysinfo]   sys_sysinfo,
};

void
syscall(void)
{
    80002c48:	1101                	addi	sp,sp,-32
    80002c4a:	ec06                	sd	ra,24(sp)
    80002c4c:	e822                	sd	s0,16(sp)
    80002c4e:	e426                	sd	s1,8(sp)
    80002c50:	e04a                	sd	s2,0(sp)
    80002c52:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c54:	fffff097          	auipc	ra,0xfffff
    80002c58:	da4080e7          	jalr	-604(ra) # 800019f8 <myproc>
    80002c5c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c5e:	05853903          	ld	s2,88(a0)
    80002c62:	0a893783          	ld	a5,168(s2)
    80002c66:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c6a:	37fd                	addiw	a5,a5,-1
    80002c6c:	4755                	li	a4,21
    80002c6e:	00f76f63          	bltu	a4,a5,80002c8c <syscall+0x44>
    80002c72:	00369713          	slli	a4,a3,0x3
    80002c76:	00005797          	auipc	a5,0x5
    80002c7a:	7da78793          	addi	a5,a5,2010 # 80008450 <syscalls>
    80002c7e:	97ba                	add	a5,a5,a4
    80002c80:	639c                	ld	a5,0(a5)
    80002c82:	c789                	beqz	a5,80002c8c <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c84:	9782                	jalr	a5
    80002c86:	06a93823          	sd	a0,112(s2)
    80002c8a:	a839                	j	80002ca8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c8c:	15848613          	addi	a2,s1,344
    80002c90:	588c                	lw	a1,48(s1)
    80002c92:	00005517          	auipc	a0,0x5
    80002c96:	78650513          	addi	a0,a0,1926 # 80008418 <states.0+0x150>
    80002c9a:	ffffe097          	auipc	ra,0xffffe
    80002c9e:	8ee080e7          	jalr	-1810(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ca2:	6cbc                	ld	a5,88(s1)
    80002ca4:	577d                	li	a4,-1
    80002ca6:	fbb8                	sd	a4,112(a5)
  }
}
    80002ca8:	60e2                	ld	ra,24(sp)
    80002caa:	6442                	ld	s0,16(sp)
    80002cac:	64a2                	ld	s1,8(sp)
    80002cae:	6902                	ld	s2,0(sp)
    80002cb0:	6105                	addi	sp,sp,32
    80002cb2:	8082                	ret

0000000080002cb4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"
#include "sysinfo.h"

uint64
sys_exit(void) {
    80002cb4:	1101                	addi	sp,sp,-32
    80002cb6:	ec06                	sd	ra,24(sp)
    80002cb8:	e822                	sd	s0,16(sp)
    80002cba:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    80002cbc:	fec40593          	addi	a1,s0,-20
    80002cc0:	4501                	li	a0,0
    80002cc2:	00000097          	auipc	ra,0x0
    80002cc6:	f0e080e7          	jalr	-242(ra) # 80002bd0 <argint>
    exit(n);
    80002cca:	fec42503          	lw	a0,-20(s0)
    80002cce:	fffff097          	auipc	ra,0xfffff
    80002cd2:	506080e7          	jalr	1286(ra) # 800021d4 <exit>
    return 0;  // not reached
}
    80002cd6:	4501                	li	a0,0
    80002cd8:	60e2                	ld	ra,24(sp)
    80002cda:	6442                	ld	s0,16(sp)
    80002cdc:	6105                	addi	sp,sp,32
    80002cde:	8082                	ret

0000000080002ce0 <sys_getpid>:

uint64
sys_getpid(void) {
    80002ce0:	1141                	addi	sp,sp,-16
    80002ce2:	e406                	sd	ra,8(sp)
    80002ce4:	e022                	sd	s0,0(sp)
    80002ce6:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80002ce8:	fffff097          	auipc	ra,0xfffff
    80002cec:	d10080e7          	jalr	-752(ra) # 800019f8 <myproc>
}
    80002cf0:	5908                	lw	a0,48(a0)
    80002cf2:	60a2                	ld	ra,8(sp)
    80002cf4:	6402                	ld	s0,0(sp)
    80002cf6:	0141                	addi	sp,sp,16
    80002cf8:	8082                	ret

0000000080002cfa <sys_fork>:

uint64
sys_fork(void) {
    80002cfa:	1141                	addi	sp,sp,-16
    80002cfc:	e406                	sd	ra,8(sp)
    80002cfe:	e022                	sd	s0,0(sp)
    80002d00:	0800                	addi	s0,sp,16
    return fork();
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	0ac080e7          	jalr	172(ra) # 80001dae <fork>
}
    80002d0a:	60a2                	ld	ra,8(sp)
    80002d0c:	6402                	ld	s0,0(sp)
    80002d0e:	0141                	addi	sp,sp,16
    80002d10:	8082                	ret

0000000080002d12 <sys_wait>:

uint64
sys_wait(void) {
    80002d12:	1101                	addi	sp,sp,-32
    80002d14:	ec06                	sd	ra,24(sp)
    80002d16:	e822                	sd	s0,16(sp)
    80002d18:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80002d1a:	fe840593          	addi	a1,s0,-24
    80002d1e:	4501                	li	a0,0
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	ed0080e7          	jalr	-304(ra) # 80002bf0 <argaddr>
    return wait(p);
    80002d28:	fe843503          	ld	a0,-24(s0)
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	64e080e7          	jalr	1614(ra) # 8000237a <wait>
}
    80002d34:	60e2                	ld	ra,24(sp)
    80002d36:	6442                	ld	s0,16(sp)
    80002d38:	6105                	addi	sp,sp,32
    80002d3a:	8082                	ret

0000000080002d3c <sys_sbrk>:

uint64
sys_sbrk(void) {
    80002d3c:	7179                	addi	sp,sp,-48
    80002d3e:	f406                	sd	ra,40(sp)
    80002d40:	f022                	sd	s0,32(sp)
    80002d42:	ec26                	sd	s1,24(sp)
    80002d44:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80002d46:	fdc40593          	addi	a1,s0,-36
    80002d4a:	4501                	li	a0,0
    80002d4c:	00000097          	auipc	ra,0x0
    80002d50:	e84080e7          	jalr	-380(ra) # 80002bd0 <argint>
    addr = myproc()->sz;
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	ca4080e7          	jalr	-860(ra) # 800019f8 <myproc>
    80002d5c:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    80002d5e:	fdc42503          	lw	a0,-36(s0)
    80002d62:	fffff097          	auipc	ra,0xfffff
    80002d66:	ff0080e7          	jalr	-16(ra) # 80001d52 <growproc>
    80002d6a:	00054863          	bltz	a0,80002d7a <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    80002d6e:	8526                	mv	a0,s1
    80002d70:	70a2                	ld	ra,40(sp)
    80002d72:	7402                	ld	s0,32(sp)
    80002d74:	64e2                	ld	s1,24(sp)
    80002d76:	6145                	addi	sp,sp,48
    80002d78:	8082                	ret
        return -1;
    80002d7a:	54fd                	li	s1,-1
    80002d7c:	bfcd                	j	80002d6e <sys_sbrk+0x32>

0000000080002d7e <sys_sleep>:

uint64
sys_sleep(void) {
    80002d7e:	7139                	addi	sp,sp,-64
    80002d80:	fc06                	sd	ra,56(sp)
    80002d82:	f822                	sd	s0,48(sp)
    80002d84:	f426                	sd	s1,40(sp)
    80002d86:	f04a                	sd	s2,32(sp)
    80002d88:	ec4e                	sd	s3,24(sp)
    80002d8a:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    80002d8c:	fcc40593          	addi	a1,s0,-52
    80002d90:	4501                	li	a0,0
    80002d92:	00000097          	auipc	ra,0x0
    80002d96:	e3e080e7          	jalr	-450(ra) # 80002bd0 <argint>
    acquire(&tickslock);
    80002d9a:	00014517          	auipc	a0,0x14
    80002d9e:	bd650513          	addi	a0,a0,-1066 # 80016970 <tickslock>
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	e80080e7          	jalr	-384(ra) # 80000c22 <acquire>
    ticks0 = ticks;
    80002daa:	00006917          	auipc	s2,0x6
    80002dae:	b2692903          	lw	s2,-1242(s2) # 800088d0 <ticks>
    while (ticks - ticks0 < n) {
    80002db2:	fcc42783          	lw	a5,-52(s0)
    80002db6:	cf9d                	beqz	a5,80002df4 <sys_sleep+0x76>
        if (killed(myproc())) {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    80002db8:	00014997          	auipc	s3,0x14
    80002dbc:	bb898993          	addi	s3,s3,-1096 # 80016970 <tickslock>
    80002dc0:	00006497          	auipc	s1,0x6
    80002dc4:	b1048493          	addi	s1,s1,-1264 # 800088d0 <ticks>
        if (killed(myproc())) {
    80002dc8:	fffff097          	auipc	ra,0xfffff
    80002dcc:	c30080e7          	jalr	-976(ra) # 800019f8 <myproc>
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	578080e7          	jalr	1400(ra) # 80002348 <killed>
    80002dd8:	ed15                	bnez	a0,80002e14 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    80002dda:	85ce                	mv	a1,s3
    80002ddc:	8526                	mv	a0,s1
    80002dde:	fffff097          	auipc	ra,0xfffff
    80002de2:	2c2080e7          	jalr	706(ra) # 800020a0 <sleep>
    while (ticks - ticks0 < n) {
    80002de6:	409c                	lw	a5,0(s1)
    80002de8:	412787bb          	subw	a5,a5,s2
    80002dec:	fcc42703          	lw	a4,-52(s0)
    80002df0:	fce7ece3          	bltu	a5,a4,80002dc8 <sys_sleep+0x4a>
    }
    release(&tickslock);
    80002df4:	00014517          	auipc	a0,0x14
    80002df8:	b7c50513          	addi	a0,a0,-1156 # 80016970 <tickslock>
    80002dfc:	ffffe097          	auipc	ra,0xffffe
    80002e00:	eda080e7          	jalr	-294(ra) # 80000cd6 <release>
    return 0;
    80002e04:	4501                	li	a0,0
}
    80002e06:	70e2                	ld	ra,56(sp)
    80002e08:	7442                	ld	s0,48(sp)
    80002e0a:	74a2                	ld	s1,40(sp)
    80002e0c:	7902                	ld	s2,32(sp)
    80002e0e:	69e2                	ld	s3,24(sp)
    80002e10:	6121                	addi	sp,sp,64
    80002e12:	8082                	ret
            release(&tickslock);
    80002e14:	00014517          	auipc	a0,0x14
    80002e18:	b5c50513          	addi	a0,a0,-1188 # 80016970 <tickslock>
    80002e1c:	ffffe097          	auipc	ra,0xffffe
    80002e20:	eba080e7          	jalr	-326(ra) # 80000cd6 <release>
            return -1;
    80002e24:	557d                	li	a0,-1
    80002e26:	b7c5                	j	80002e06 <sys_sleep+0x88>

0000000080002e28 <sys_kill>:

uint64
sys_kill(void) {
    80002e28:	1101                	addi	sp,sp,-32
    80002e2a:	ec06                	sd	ra,24(sp)
    80002e2c:	e822                	sd	s0,16(sp)
    80002e2e:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    80002e30:	fec40593          	addi	a1,s0,-20
    80002e34:	4501                	li	a0,0
    80002e36:	00000097          	auipc	ra,0x0
    80002e3a:	d9a080e7          	jalr	-614(ra) # 80002bd0 <argint>
    return kill(pid);
    80002e3e:	fec42503          	lw	a0,-20(s0)
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	468080e7          	jalr	1128(ra) # 800022aa <kill>
}
    80002e4a:	60e2                	ld	ra,24(sp)
    80002e4c:	6442                	ld	s0,16(sp)
    80002e4e:	6105                	addi	sp,sp,32
    80002e50:	8082                	ret

0000000080002e52 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void) {
    80002e52:	1101                	addi	sp,sp,-32
    80002e54:	ec06                	sd	ra,24(sp)
    80002e56:	e822                	sd	s0,16(sp)
    80002e58:	e426                	sd	s1,8(sp)
    80002e5a:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    80002e5c:	00014517          	auipc	a0,0x14
    80002e60:	b1450513          	addi	a0,a0,-1260 # 80016970 <tickslock>
    80002e64:	ffffe097          	auipc	ra,0xffffe
    80002e68:	dbe080e7          	jalr	-578(ra) # 80000c22 <acquire>
    xticks = ticks;
    80002e6c:	00006497          	auipc	s1,0x6
    80002e70:	a644a483          	lw	s1,-1436(s1) # 800088d0 <ticks>
    release(&tickslock);
    80002e74:	00014517          	auipc	a0,0x14
    80002e78:	afc50513          	addi	a0,a0,-1284 # 80016970 <tickslock>
    80002e7c:	ffffe097          	auipc	ra,0xffffe
    80002e80:	e5a080e7          	jalr	-422(ra) # 80000cd6 <release>
    return xticks;
}
    80002e84:	02049513          	slli	a0,s1,0x20
    80002e88:	9101                	srli	a0,a0,0x20
    80002e8a:	60e2                	ld	ra,24(sp)
    80002e8c:	6442                	ld	s0,16(sp)
    80002e8e:	64a2                	ld	s1,8(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret

0000000080002e94 <sys_sysinfo>:

uint64 sys_sysinfo(void) {
    80002e94:	1101                	addi	sp,sp,-32
    80002e96:	ec06                	sd	ra,24(sp)
    80002e98:	e822                	sd	s0,16(sp)
    80002e9a:	1000                	addi	s0,sp,32
//    struct sysinfo *info;
    uint64 info;
    argaddr(0, &info);
    80002e9c:	fe840593          	addi	a1,s0,-24
    80002ea0:	4501                	li	a0,0
    80002ea2:	00000097          	auipc	ra,0x0
    80002ea6:	d4e080e7          	jalr	-690(ra) # 80002bf0 <argaddr>
//    printf("sys_sysinfo\n");
    if(info<0)
        return -1;
    int ret = sysinfo(info);
    80002eaa:	fe843503          	ld	a0,-24(s0)
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	7aa080e7          	jalr	1962(ra) # 80002658 <sysinfo>
//    if (copyout(myproc()->pagetable, uinfo, (char *) info, sizeof(struct sysinfo)) < 0) {
//        return -1;
//    }
    return ret;

    80002eb6:	60e2                	ld	ra,24(sp)
    80002eb8:	6442                	ld	s0,16(sp)
    80002eba:	6105                	addi	sp,sp,32
    80002ebc:	8082                	ret

0000000080002ebe <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ebe:	7179                	addi	sp,sp,-48
    80002ec0:	f406                	sd	ra,40(sp)
    80002ec2:	f022                	sd	s0,32(sp)
    80002ec4:	ec26                	sd	s1,24(sp)
    80002ec6:	e84a                	sd	s2,16(sp)
    80002ec8:	e44e                	sd	s3,8(sp)
    80002eca:	e052                	sd	s4,0(sp)
    80002ecc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ece:	00005597          	auipc	a1,0x5
    80002ed2:	63a58593          	addi	a1,a1,1594 # 80008508 <syscalls+0xb8>
    80002ed6:	00014517          	auipc	a0,0x14
    80002eda:	ab250513          	addi	a0,a0,-1358 # 80016988 <bcache>
    80002ede:	ffffe097          	auipc	ra,0xffffe
    80002ee2:	cb4080e7          	jalr	-844(ra) # 80000b92 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ee6:	0001c797          	auipc	a5,0x1c
    80002eea:	aa278793          	addi	a5,a5,-1374 # 8001e988 <bcache+0x8000>
    80002eee:	0001c717          	auipc	a4,0x1c
    80002ef2:	d0270713          	addi	a4,a4,-766 # 8001ebf0 <bcache+0x8268>
    80002ef6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002efa:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002efe:	00014497          	auipc	s1,0x14
    80002f02:	aa248493          	addi	s1,s1,-1374 # 800169a0 <bcache+0x18>
    b->next = bcache.head.next;
    80002f06:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f08:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f0a:	00005a17          	auipc	s4,0x5
    80002f0e:	606a0a13          	addi	s4,s4,1542 # 80008510 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002f12:	2b893783          	ld	a5,696(s2)
    80002f16:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f18:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f1c:	85d2                	mv	a1,s4
    80002f1e:	01048513          	addi	a0,s1,16
    80002f22:	00001097          	auipc	ra,0x1
    80002f26:	4c4080e7          	jalr	1220(ra) # 800043e6 <initsleeplock>
    bcache.head.next->prev = b;
    80002f2a:	2b893783          	ld	a5,696(s2)
    80002f2e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f30:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f34:	45848493          	addi	s1,s1,1112
    80002f38:	fd349de3          	bne	s1,s3,80002f12 <binit+0x54>
  }
}
    80002f3c:	70a2                	ld	ra,40(sp)
    80002f3e:	7402                	ld	s0,32(sp)
    80002f40:	64e2                	ld	s1,24(sp)
    80002f42:	6942                	ld	s2,16(sp)
    80002f44:	69a2                	ld	s3,8(sp)
    80002f46:	6a02                	ld	s4,0(sp)
    80002f48:	6145                	addi	sp,sp,48
    80002f4a:	8082                	ret

0000000080002f4c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f4c:	7179                	addi	sp,sp,-48
    80002f4e:	f406                	sd	ra,40(sp)
    80002f50:	f022                	sd	s0,32(sp)
    80002f52:	ec26                	sd	s1,24(sp)
    80002f54:	e84a                	sd	s2,16(sp)
    80002f56:	e44e                	sd	s3,8(sp)
    80002f58:	1800                	addi	s0,sp,48
    80002f5a:	892a                	mv	s2,a0
    80002f5c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f5e:	00014517          	auipc	a0,0x14
    80002f62:	a2a50513          	addi	a0,a0,-1494 # 80016988 <bcache>
    80002f66:	ffffe097          	auipc	ra,0xffffe
    80002f6a:	cbc080e7          	jalr	-836(ra) # 80000c22 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f6e:	0001c497          	auipc	s1,0x1c
    80002f72:	cd24b483          	ld	s1,-814(s1) # 8001ec40 <bcache+0x82b8>
    80002f76:	0001c797          	auipc	a5,0x1c
    80002f7a:	c7a78793          	addi	a5,a5,-902 # 8001ebf0 <bcache+0x8268>
    80002f7e:	02f48f63          	beq	s1,a5,80002fbc <bread+0x70>
    80002f82:	873e                	mv	a4,a5
    80002f84:	a021                	j	80002f8c <bread+0x40>
    80002f86:	68a4                	ld	s1,80(s1)
    80002f88:	02e48a63          	beq	s1,a4,80002fbc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f8c:	449c                	lw	a5,8(s1)
    80002f8e:	ff279ce3          	bne	a5,s2,80002f86 <bread+0x3a>
    80002f92:	44dc                	lw	a5,12(s1)
    80002f94:	ff3799e3          	bne	a5,s3,80002f86 <bread+0x3a>
      b->refcnt++;
    80002f98:	40bc                	lw	a5,64(s1)
    80002f9a:	2785                	addiw	a5,a5,1
    80002f9c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f9e:	00014517          	auipc	a0,0x14
    80002fa2:	9ea50513          	addi	a0,a0,-1558 # 80016988 <bcache>
    80002fa6:	ffffe097          	auipc	ra,0xffffe
    80002faa:	d30080e7          	jalr	-720(ra) # 80000cd6 <release>
      acquiresleep(&b->lock);
    80002fae:	01048513          	addi	a0,s1,16
    80002fb2:	00001097          	auipc	ra,0x1
    80002fb6:	46e080e7          	jalr	1134(ra) # 80004420 <acquiresleep>
      return b;
    80002fba:	a8b9                	j	80003018 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fbc:	0001c497          	auipc	s1,0x1c
    80002fc0:	c7c4b483          	ld	s1,-900(s1) # 8001ec38 <bcache+0x82b0>
    80002fc4:	0001c797          	auipc	a5,0x1c
    80002fc8:	c2c78793          	addi	a5,a5,-980 # 8001ebf0 <bcache+0x8268>
    80002fcc:	00f48863          	beq	s1,a5,80002fdc <bread+0x90>
    80002fd0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fd2:	40bc                	lw	a5,64(s1)
    80002fd4:	cf81                	beqz	a5,80002fec <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fd6:	64a4                	ld	s1,72(s1)
    80002fd8:	fee49de3          	bne	s1,a4,80002fd2 <bread+0x86>
  panic("bget: no buffers");
    80002fdc:	00005517          	auipc	a0,0x5
    80002fe0:	53c50513          	addi	a0,a0,1340 # 80008518 <syscalls+0xc8>
    80002fe4:	ffffd097          	auipc	ra,0xffffd
    80002fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
      b->dev = dev;
    80002fec:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002ff0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002ff4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ff8:	4785                	li	a5,1
    80002ffa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ffc:	00014517          	auipc	a0,0x14
    80003000:	98c50513          	addi	a0,a0,-1652 # 80016988 <bcache>
    80003004:	ffffe097          	auipc	ra,0xffffe
    80003008:	cd2080e7          	jalr	-814(ra) # 80000cd6 <release>
      acquiresleep(&b->lock);
    8000300c:	01048513          	addi	a0,s1,16
    80003010:	00001097          	auipc	ra,0x1
    80003014:	410080e7          	jalr	1040(ra) # 80004420 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003018:	409c                	lw	a5,0(s1)
    8000301a:	cb89                	beqz	a5,8000302c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000301c:	8526                	mv	a0,s1
    8000301e:	70a2                	ld	ra,40(sp)
    80003020:	7402                	ld	s0,32(sp)
    80003022:	64e2                	ld	s1,24(sp)
    80003024:	6942                	ld	s2,16(sp)
    80003026:	69a2                	ld	s3,8(sp)
    80003028:	6145                	addi	sp,sp,48
    8000302a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000302c:	4581                	li	a1,0
    8000302e:	8526                	mv	a0,s1
    80003030:	00003097          	auipc	ra,0x3
    80003034:	fd4080e7          	jalr	-44(ra) # 80006004 <virtio_disk_rw>
    b->valid = 1;
    80003038:	4785                	li	a5,1
    8000303a:	c09c                	sw	a5,0(s1)
  return b;
    8000303c:	b7c5                	j	8000301c <bread+0xd0>

000000008000303e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000303e:	1101                	addi	sp,sp,-32
    80003040:	ec06                	sd	ra,24(sp)
    80003042:	e822                	sd	s0,16(sp)
    80003044:	e426                	sd	s1,8(sp)
    80003046:	1000                	addi	s0,sp,32
    80003048:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000304a:	0541                	addi	a0,a0,16
    8000304c:	00001097          	auipc	ra,0x1
    80003050:	46e080e7          	jalr	1134(ra) # 800044ba <holdingsleep>
    80003054:	cd01                	beqz	a0,8000306c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003056:	4585                	li	a1,1
    80003058:	8526                	mv	a0,s1
    8000305a:	00003097          	auipc	ra,0x3
    8000305e:	faa080e7          	jalr	-86(ra) # 80006004 <virtio_disk_rw>
}
    80003062:	60e2                	ld	ra,24(sp)
    80003064:	6442                	ld	s0,16(sp)
    80003066:	64a2                	ld	s1,8(sp)
    80003068:	6105                	addi	sp,sp,32
    8000306a:	8082                	ret
    panic("bwrite");
    8000306c:	00005517          	auipc	a0,0x5
    80003070:	4c450513          	addi	a0,a0,1220 # 80008530 <syscalls+0xe0>
    80003074:	ffffd097          	auipc	ra,0xffffd
    80003078:	4ca080e7          	jalr	1226(ra) # 8000053e <panic>

000000008000307c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000307c:	1101                	addi	sp,sp,-32
    8000307e:	ec06                	sd	ra,24(sp)
    80003080:	e822                	sd	s0,16(sp)
    80003082:	e426                	sd	s1,8(sp)
    80003084:	e04a                	sd	s2,0(sp)
    80003086:	1000                	addi	s0,sp,32
    80003088:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000308a:	01050913          	addi	s2,a0,16
    8000308e:	854a                	mv	a0,s2
    80003090:	00001097          	auipc	ra,0x1
    80003094:	42a080e7          	jalr	1066(ra) # 800044ba <holdingsleep>
    80003098:	c92d                	beqz	a0,8000310a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000309a:	854a                	mv	a0,s2
    8000309c:	00001097          	auipc	ra,0x1
    800030a0:	3da080e7          	jalr	986(ra) # 80004476 <releasesleep>

  acquire(&bcache.lock);
    800030a4:	00014517          	auipc	a0,0x14
    800030a8:	8e450513          	addi	a0,a0,-1820 # 80016988 <bcache>
    800030ac:	ffffe097          	auipc	ra,0xffffe
    800030b0:	b76080e7          	jalr	-1162(ra) # 80000c22 <acquire>
  b->refcnt--;
    800030b4:	40bc                	lw	a5,64(s1)
    800030b6:	37fd                	addiw	a5,a5,-1
    800030b8:	0007871b          	sext.w	a4,a5
    800030bc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030be:	eb05                	bnez	a4,800030ee <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030c0:	68bc                	ld	a5,80(s1)
    800030c2:	64b8                	ld	a4,72(s1)
    800030c4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030c6:	64bc                	ld	a5,72(s1)
    800030c8:	68b8                	ld	a4,80(s1)
    800030ca:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030cc:	0001c797          	auipc	a5,0x1c
    800030d0:	8bc78793          	addi	a5,a5,-1860 # 8001e988 <bcache+0x8000>
    800030d4:	2b87b703          	ld	a4,696(a5)
    800030d8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030da:	0001c717          	auipc	a4,0x1c
    800030de:	b1670713          	addi	a4,a4,-1258 # 8001ebf0 <bcache+0x8268>
    800030e2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030e4:	2b87b703          	ld	a4,696(a5)
    800030e8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030ea:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030ee:	00014517          	auipc	a0,0x14
    800030f2:	89a50513          	addi	a0,a0,-1894 # 80016988 <bcache>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	be0080e7          	jalr	-1056(ra) # 80000cd6 <release>
}
    800030fe:	60e2                	ld	ra,24(sp)
    80003100:	6442                	ld	s0,16(sp)
    80003102:	64a2                	ld	s1,8(sp)
    80003104:	6902                	ld	s2,0(sp)
    80003106:	6105                	addi	sp,sp,32
    80003108:	8082                	ret
    panic("brelse");
    8000310a:	00005517          	auipc	a0,0x5
    8000310e:	42e50513          	addi	a0,a0,1070 # 80008538 <syscalls+0xe8>
    80003112:	ffffd097          	auipc	ra,0xffffd
    80003116:	42c080e7          	jalr	1068(ra) # 8000053e <panic>

000000008000311a <bpin>:

void
bpin(struct buf *b) {
    8000311a:	1101                	addi	sp,sp,-32
    8000311c:	ec06                	sd	ra,24(sp)
    8000311e:	e822                	sd	s0,16(sp)
    80003120:	e426                	sd	s1,8(sp)
    80003122:	1000                	addi	s0,sp,32
    80003124:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003126:	00014517          	auipc	a0,0x14
    8000312a:	86250513          	addi	a0,a0,-1950 # 80016988 <bcache>
    8000312e:	ffffe097          	auipc	ra,0xffffe
    80003132:	af4080e7          	jalr	-1292(ra) # 80000c22 <acquire>
  b->refcnt++;
    80003136:	40bc                	lw	a5,64(s1)
    80003138:	2785                	addiw	a5,a5,1
    8000313a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000313c:	00014517          	auipc	a0,0x14
    80003140:	84c50513          	addi	a0,a0,-1972 # 80016988 <bcache>
    80003144:	ffffe097          	auipc	ra,0xffffe
    80003148:	b92080e7          	jalr	-1134(ra) # 80000cd6 <release>
}
    8000314c:	60e2                	ld	ra,24(sp)
    8000314e:	6442                	ld	s0,16(sp)
    80003150:	64a2                	ld	s1,8(sp)
    80003152:	6105                	addi	sp,sp,32
    80003154:	8082                	ret

0000000080003156 <bunpin>:

void
bunpin(struct buf *b) {
    80003156:	1101                	addi	sp,sp,-32
    80003158:	ec06                	sd	ra,24(sp)
    8000315a:	e822                	sd	s0,16(sp)
    8000315c:	e426                	sd	s1,8(sp)
    8000315e:	1000                	addi	s0,sp,32
    80003160:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003162:	00014517          	auipc	a0,0x14
    80003166:	82650513          	addi	a0,a0,-2010 # 80016988 <bcache>
    8000316a:	ffffe097          	auipc	ra,0xffffe
    8000316e:	ab8080e7          	jalr	-1352(ra) # 80000c22 <acquire>
  b->refcnt--;
    80003172:	40bc                	lw	a5,64(s1)
    80003174:	37fd                	addiw	a5,a5,-1
    80003176:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003178:	00014517          	auipc	a0,0x14
    8000317c:	81050513          	addi	a0,a0,-2032 # 80016988 <bcache>
    80003180:	ffffe097          	auipc	ra,0xffffe
    80003184:	b56080e7          	jalr	-1194(ra) # 80000cd6 <release>
}
    80003188:	60e2                	ld	ra,24(sp)
    8000318a:	6442                	ld	s0,16(sp)
    8000318c:	64a2                	ld	s1,8(sp)
    8000318e:	6105                	addi	sp,sp,32
    80003190:	8082                	ret

0000000080003192 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003192:	1101                	addi	sp,sp,-32
    80003194:	ec06                	sd	ra,24(sp)
    80003196:	e822                	sd	s0,16(sp)
    80003198:	e426                	sd	s1,8(sp)
    8000319a:	e04a                	sd	s2,0(sp)
    8000319c:	1000                	addi	s0,sp,32
    8000319e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031a0:	00d5d59b          	srliw	a1,a1,0xd
    800031a4:	0001c797          	auipc	a5,0x1c
    800031a8:	ec07a783          	lw	a5,-320(a5) # 8001f064 <sb+0x1c>
    800031ac:	9dbd                	addw	a1,a1,a5
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	d9e080e7          	jalr	-610(ra) # 80002f4c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031b6:	0074f713          	andi	a4,s1,7
    800031ba:	4785                	li	a5,1
    800031bc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031c0:	14ce                	slli	s1,s1,0x33
    800031c2:	90d9                	srli	s1,s1,0x36
    800031c4:	00950733          	add	a4,a0,s1
    800031c8:	05874703          	lbu	a4,88(a4)
    800031cc:	00e7f6b3          	and	a3,a5,a4
    800031d0:	c69d                	beqz	a3,800031fe <bfree+0x6c>
    800031d2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031d4:	94aa                	add	s1,s1,a0
    800031d6:	fff7c793          	not	a5,a5
    800031da:	8ff9                	and	a5,a5,a4
    800031dc:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031e0:	00001097          	auipc	ra,0x1
    800031e4:	120080e7          	jalr	288(ra) # 80004300 <log_write>
  brelse(bp);
    800031e8:	854a                	mv	a0,s2
    800031ea:	00000097          	auipc	ra,0x0
    800031ee:	e92080e7          	jalr	-366(ra) # 8000307c <brelse>
}
    800031f2:	60e2                	ld	ra,24(sp)
    800031f4:	6442                	ld	s0,16(sp)
    800031f6:	64a2                	ld	s1,8(sp)
    800031f8:	6902                	ld	s2,0(sp)
    800031fa:	6105                	addi	sp,sp,32
    800031fc:	8082                	ret
    panic("freeing free block");
    800031fe:	00005517          	auipc	a0,0x5
    80003202:	34250513          	addi	a0,a0,834 # 80008540 <syscalls+0xf0>
    80003206:	ffffd097          	auipc	ra,0xffffd
    8000320a:	338080e7          	jalr	824(ra) # 8000053e <panic>

000000008000320e <balloc>:
{
    8000320e:	711d                	addi	sp,sp,-96
    80003210:	ec86                	sd	ra,88(sp)
    80003212:	e8a2                	sd	s0,80(sp)
    80003214:	e4a6                	sd	s1,72(sp)
    80003216:	e0ca                	sd	s2,64(sp)
    80003218:	fc4e                	sd	s3,56(sp)
    8000321a:	f852                	sd	s4,48(sp)
    8000321c:	f456                	sd	s5,40(sp)
    8000321e:	f05a                	sd	s6,32(sp)
    80003220:	ec5e                	sd	s7,24(sp)
    80003222:	e862                	sd	s8,16(sp)
    80003224:	e466                	sd	s9,8(sp)
    80003226:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003228:	0001c797          	auipc	a5,0x1c
    8000322c:	e247a783          	lw	a5,-476(a5) # 8001f04c <sb+0x4>
    80003230:	10078163          	beqz	a5,80003332 <balloc+0x124>
    80003234:	8baa                	mv	s7,a0
    80003236:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003238:	0001cb17          	auipc	s6,0x1c
    8000323c:	e10b0b13          	addi	s6,s6,-496 # 8001f048 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003240:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003242:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003244:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003246:	6c89                	lui	s9,0x2
    80003248:	a061                	j	800032d0 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000324a:	974a                	add	a4,a4,s2
    8000324c:	8fd5                	or	a5,a5,a3
    8000324e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003252:	854a                	mv	a0,s2
    80003254:	00001097          	auipc	ra,0x1
    80003258:	0ac080e7          	jalr	172(ra) # 80004300 <log_write>
        brelse(bp);
    8000325c:	854a                	mv	a0,s2
    8000325e:	00000097          	auipc	ra,0x0
    80003262:	e1e080e7          	jalr	-482(ra) # 8000307c <brelse>
  bp = bread(dev, bno);
    80003266:	85a6                	mv	a1,s1
    80003268:	855e                	mv	a0,s7
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	ce2080e7          	jalr	-798(ra) # 80002f4c <bread>
    80003272:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003274:	40000613          	li	a2,1024
    80003278:	4581                	li	a1,0
    8000327a:	05850513          	addi	a0,a0,88
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	aa0080e7          	jalr	-1376(ra) # 80000d1e <memset>
  log_write(bp);
    80003286:	854a                	mv	a0,s2
    80003288:	00001097          	auipc	ra,0x1
    8000328c:	078080e7          	jalr	120(ra) # 80004300 <log_write>
  brelse(bp);
    80003290:	854a                	mv	a0,s2
    80003292:	00000097          	auipc	ra,0x0
    80003296:	dea080e7          	jalr	-534(ra) # 8000307c <brelse>
}
    8000329a:	8526                	mv	a0,s1
    8000329c:	60e6                	ld	ra,88(sp)
    8000329e:	6446                	ld	s0,80(sp)
    800032a0:	64a6                	ld	s1,72(sp)
    800032a2:	6906                	ld	s2,64(sp)
    800032a4:	79e2                	ld	s3,56(sp)
    800032a6:	7a42                	ld	s4,48(sp)
    800032a8:	7aa2                	ld	s5,40(sp)
    800032aa:	7b02                	ld	s6,32(sp)
    800032ac:	6be2                	ld	s7,24(sp)
    800032ae:	6c42                	ld	s8,16(sp)
    800032b0:	6ca2                	ld	s9,8(sp)
    800032b2:	6125                	addi	sp,sp,96
    800032b4:	8082                	ret
    brelse(bp);
    800032b6:	854a                	mv	a0,s2
    800032b8:	00000097          	auipc	ra,0x0
    800032bc:	dc4080e7          	jalr	-572(ra) # 8000307c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032c0:	015c87bb          	addw	a5,s9,s5
    800032c4:	00078a9b          	sext.w	s5,a5
    800032c8:	004b2703          	lw	a4,4(s6)
    800032cc:	06eaf363          	bgeu	s5,a4,80003332 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800032d0:	41fad79b          	sraiw	a5,s5,0x1f
    800032d4:	0137d79b          	srliw	a5,a5,0x13
    800032d8:	015787bb          	addw	a5,a5,s5
    800032dc:	40d7d79b          	sraiw	a5,a5,0xd
    800032e0:	01cb2583          	lw	a1,28(s6)
    800032e4:	9dbd                	addw	a1,a1,a5
    800032e6:	855e                	mv	a0,s7
    800032e8:	00000097          	auipc	ra,0x0
    800032ec:	c64080e7          	jalr	-924(ra) # 80002f4c <bread>
    800032f0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032f2:	004b2503          	lw	a0,4(s6)
    800032f6:	000a849b          	sext.w	s1,s5
    800032fa:	8662                	mv	a2,s8
    800032fc:	faa4fde3          	bgeu	s1,a0,800032b6 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003300:	41f6579b          	sraiw	a5,a2,0x1f
    80003304:	01d7d69b          	srliw	a3,a5,0x1d
    80003308:	00c6873b          	addw	a4,a3,a2
    8000330c:	00777793          	andi	a5,a4,7
    80003310:	9f95                	subw	a5,a5,a3
    80003312:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003316:	4037571b          	sraiw	a4,a4,0x3
    8000331a:	00e906b3          	add	a3,s2,a4
    8000331e:	0586c683          	lbu	a3,88(a3)
    80003322:	00d7f5b3          	and	a1,a5,a3
    80003326:	d195                	beqz	a1,8000324a <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003328:	2605                	addiw	a2,a2,1
    8000332a:	2485                	addiw	s1,s1,1
    8000332c:	fd4618e3          	bne	a2,s4,800032fc <balloc+0xee>
    80003330:	b759                	j	800032b6 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003332:	00005517          	auipc	a0,0x5
    80003336:	22650513          	addi	a0,a0,550 # 80008558 <syscalls+0x108>
    8000333a:	ffffd097          	auipc	ra,0xffffd
    8000333e:	24e080e7          	jalr	590(ra) # 80000588 <printf>
  return 0;
    80003342:	4481                	li	s1,0
    80003344:	bf99                	j	8000329a <balloc+0x8c>

0000000080003346 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003346:	7179                	addi	sp,sp,-48
    80003348:	f406                	sd	ra,40(sp)
    8000334a:	f022                	sd	s0,32(sp)
    8000334c:	ec26                	sd	s1,24(sp)
    8000334e:	e84a                	sd	s2,16(sp)
    80003350:	e44e                	sd	s3,8(sp)
    80003352:	e052                	sd	s4,0(sp)
    80003354:	1800                	addi	s0,sp,48
    80003356:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003358:	47ad                	li	a5,11
    8000335a:	02b7e763          	bltu	a5,a1,80003388 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000335e:	02059493          	slli	s1,a1,0x20
    80003362:	9081                	srli	s1,s1,0x20
    80003364:	048a                	slli	s1,s1,0x2
    80003366:	94aa                	add	s1,s1,a0
    80003368:	0504a903          	lw	s2,80(s1)
    8000336c:	06091e63          	bnez	s2,800033e8 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003370:	4108                	lw	a0,0(a0)
    80003372:	00000097          	auipc	ra,0x0
    80003376:	e9c080e7          	jalr	-356(ra) # 8000320e <balloc>
    8000337a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000337e:	06090563          	beqz	s2,800033e8 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003382:	0524a823          	sw	s2,80(s1)
    80003386:	a08d                	j	800033e8 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003388:	ff45849b          	addiw	s1,a1,-12
    8000338c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003390:	0ff00793          	li	a5,255
    80003394:	08e7e563          	bltu	a5,a4,8000341e <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003398:	08052903          	lw	s2,128(a0)
    8000339c:	00091d63          	bnez	s2,800033b6 <bmap+0x70>
      addr = balloc(ip->dev);
    800033a0:	4108                	lw	a0,0(a0)
    800033a2:	00000097          	auipc	ra,0x0
    800033a6:	e6c080e7          	jalr	-404(ra) # 8000320e <balloc>
    800033aa:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033ae:	02090d63          	beqz	s2,800033e8 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033b2:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800033b6:	85ca                	mv	a1,s2
    800033b8:	0009a503          	lw	a0,0(s3)
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	b90080e7          	jalr	-1136(ra) # 80002f4c <bread>
    800033c4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033c6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033ca:	02049593          	slli	a1,s1,0x20
    800033ce:	9181                	srli	a1,a1,0x20
    800033d0:	058a                	slli	a1,a1,0x2
    800033d2:	00b784b3          	add	s1,a5,a1
    800033d6:	0004a903          	lw	s2,0(s1)
    800033da:	02090063          	beqz	s2,800033fa <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033de:	8552                	mv	a0,s4
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	c9c080e7          	jalr	-868(ra) # 8000307c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033e8:	854a                	mv	a0,s2
    800033ea:	70a2                	ld	ra,40(sp)
    800033ec:	7402                	ld	s0,32(sp)
    800033ee:	64e2                	ld	s1,24(sp)
    800033f0:	6942                	ld	s2,16(sp)
    800033f2:	69a2                	ld	s3,8(sp)
    800033f4:	6a02                	ld	s4,0(sp)
    800033f6:	6145                	addi	sp,sp,48
    800033f8:	8082                	ret
      addr = balloc(ip->dev);
    800033fa:	0009a503          	lw	a0,0(s3)
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	e10080e7          	jalr	-496(ra) # 8000320e <balloc>
    80003406:	0005091b          	sext.w	s2,a0
      if(addr){
    8000340a:	fc090ae3          	beqz	s2,800033de <bmap+0x98>
        a[bn] = addr;
    8000340e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003412:	8552                	mv	a0,s4
    80003414:	00001097          	auipc	ra,0x1
    80003418:	eec080e7          	jalr	-276(ra) # 80004300 <log_write>
    8000341c:	b7c9                	j	800033de <bmap+0x98>
  panic("bmap: out of range");
    8000341e:	00005517          	auipc	a0,0x5
    80003422:	15250513          	addi	a0,a0,338 # 80008570 <syscalls+0x120>
    80003426:	ffffd097          	auipc	ra,0xffffd
    8000342a:	118080e7          	jalr	280(ra) # 8000053e <panic>

000000008000342e <iget>:
{
    8000342e:	7179                	addi	sp,sp,-48
    80003430:	f406                	sd	ra,40(sp)
    80003432:	f022                	sd	s0,32(sp)
    80003434:	ec26                	sd	s1,24(sp)
    80003436:	e84a                	sd	s2,16(sp)
    80003438:	e44e                	sd	s3,8(sp)
    8000343a:	e052                	sd	s4,0(sp)
    8000343c:	1800                	addi	s0,sp,48
    8000343e:	89aa                	mv	s3,a0
    80003440:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003442:	0001c517          	auipc	a0,0x1c
    80003446:	c2650513          	addi	a0,a0,-986 # 8001f068 <itable>
    8000344a:	ffffd097          	auipc	ra,0xffffd
    8000344e:	7d8080e7          	jalr	2008(ra) # 80000c22 <acquire>
  empty = 0;
    80003452:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003454:	0001c497          	auipc	s1,0x1c
    80003458:	c2c48493          	addi	s1,s1,-980 # 8001f080 <itable+0x18>
    8000345c:	0001d697          	auipc	a3,0x1d
    80003460:	6b468693          	addi	a3,a3,1716 # 80020b10 <log>
    80003464:	a039                	j	80003472 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003466:	02090b63          	beqz	s2,8000349c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000346a:	08848493          	addi	s1,s1,136
    8000346e:	02d48a63          	beq	s1,a3,800034a2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003472:	449c                	lw	a5,8(s1)
    80003474:	fef059e3          	blez	a5,80003466 <iget+0x38>
    80003478:	4098                	lw	a4,0(s1)
    8000347a:	ff3716e3          	bne	a4,s3,80003466 <iget+0x38>
    8000347e:	40d8                	lw	a4,4(s1)
    80003480:	ff4713e3          	bne	a4,s4,80003466 <iget+0x38>
      ip->ref++;
    80003484:	2785                	addiw	a5,a5,1
    80003486:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003488:	0001c517          	auipc	a0,0x1c
    8000348c:	be050513          	addi	a0,a0,-1056 # 8001f068 <itable>
    80003490:	ffffe097          	auipc	ra,0xffffe
    80003494:	846080e7          	jalr	-1978(ra) # 80000cd6 <release>
      return ip;
    80003498:	8926                	mv	s2,s1
    8000349a:	a03d                	j	800034c8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000349c:	f7f9                	bnez	a5,8000346a <iget+0x3c>
    8000349e:	8926                	mv	s2,s1
    800034a0:	b7e9                	j	8000346a <iget+0x3c>
  if(empty == 0)
    800034a2:	02090c63          	beqz	s2,800034da <iget+0xac>
  ip->dev = dev;
    800034a6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034aa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034ae:	4785                	li	a5,1
    800034b0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034b4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034b8:	0001c517          	auipc	a0,0x1c
    800034bc:	bb050513          	addi	a0,a0,-1104 # 8001f068 <itable>
    800034c0:	ffffe097          	auipc	ra,0xffffe
    800034c4:	816080e7          	jalr	-2026(ra) # 80000cd6 <release>
}
    800034c8:	854a                	mv	a0,s2
    800034ca:	70a2                	ld	ra,40(sp)
    800034cc:	7402                	ld	s0,32(sp)
    800034ce:	64e2                	ld	s1,24(sp)
    800034d0:	6942                	ld	s2,16(sp)
    800034d2:	69a2                	ld	s3,8(sp)
    800034d4:	6a02                	ld	s4,0(sp)
    800034d6:	6145                	addi	sp,sp,48
    800034d8:	8082                	ret
    panic("iget: no inodes");
    800034da:	00005517          	auipc	a0,0x5
    800034de:	0ae50513          	addi	a0,a0,174 # 80008588 <syscalls+0x138>
    800034e2:	ffffd097          	auipc	ra,0xffffd
    800034e6:	05c080e7          	jalr	92(ra) # 8000053e <panic>

00000000800034ea <fsinit>:
fsinit(int dev) {
    800034ea:	7179                	addi	sp,sp,-48
    800034ec:	f406                	sd	ra,40(sp)
    800034ee:	f022                	sd	s0,32(sp)
    800034f0:	ec26                	sd	s1,24(sp)
    800034f2:	e84a                	sd	s2,16(sp)
    800034f4:	e44e                	sd	s3,8(sp)
    800034f6:	1800                	addi	s0,sp,48
    800034f8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034fa:	4585                	li	a1,1
    800034fc:	00000097          	auipc	ra,0x0
    80003500:	a50080e7          	jalr	-1456(ra) # 80002f4c <bread>
    80003504:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003506:	0001c997          	auipc	s3,0x1c
    8000350a:	b4298993          	addi	s3,s3,-1214 # 8001f048 <sb>
    8000350e:	02000613          	li	a2,32
    80003512:	05850593          	addi	a1,a0,88
    80003516:	854e                	mv	a0,s3
    80003518:	ffffe097          	auipc	ra,0xffffe
    8000351c:	862080e7          	jalr	-1950(ra) # 80000d7a <memmove>
  brelse(bp);
    80003520:	8526                	mv	a0,s1
    80003522:	00000097          	auipc	ra,0x0
    80003526:	b5a080e7          	jalr	-1190(ra) # 8000307c <brelse>
  if(sb.magic != FSMAGIC)
    8000352a:	0009a703          	lw	a4,0(s3)
    8000352e:	102037b7          	lui	a5,0x10203
    80003532:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003536:	02f71263          	bne	a4,a5,8000355a <fsinit+0x70>
  initlog(dev, &sb);
    8000353a:	0001c597          	auipc	a1,0x1c
    8000353e:	b0e58593          	addi	a1,a1,-1266 # 8001f048 <sb>
    80003542:	854a                	mv	a0,s2
    80003544:	00001097          	auipc	ra,0x1
    80003548:	b40080e7          	jalr	-1216(ra) # 80004084 <initlog>
}
    8000354c:	70a2                	ld	ra,40(sp)
    8000354e:	7402                	ld	s0,32(sp)
    80003550:	64e2                	ld	s1,24(sp)
    80003552:	6942                	ld	s2,16(sp)
    80003554:	69a2                	ld	s3,8(sp)
    80003556:	6145                	addi	sp,sp,48
    80003558:	8082                	ret
    panic("invalid file system");
    8000355a:	00005517          	auipc	a0,0x5
    8000355e:	03e50513          	addi	a0,a0,62 # 80008598 <syscalls+0x148>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	fdc080e7          	jalr	-36(ra) # 8000053e <panic>

000000008000356a <iinit>:
{
    8000356a:	7179                	addi	sp,sp,-48
    8000356c:	f406                	sd	ra,40(sp)
    8000356e:	f022                	sd	s0,32(sp)
    80003570:	ec26                	sd	s1,24(sp)
    80003572:	e84a                	sd	s2,16(sp)
    80003574:	e44e                	sd	s3,8(sp)
    80003576:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003578:	00005597          	auipc	a1,0x5
    8000357c:	03858593          	addi	a1,a1,56 # 800085b0 <syscalls+0x160>
    80003580:	0001c517          	auipc	a0,0x1c
    80003584:	ae850513          	addi	a0,a0,-1304 # 8001f068 <itable>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	60a080e7          	jalr	1546(ra) # 80000b92 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003590:	0001c497          	auipc	s1,0x1c
    80003594:	b0048493          	addi	s1,s1,-1280 # 8001f090 <itable+0x28>
    80003598:	0001d997          	auipc	s3,0x1d
    8000359c:	58898993          	addi	s3,s3,1416 # 80020b20 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035a0:	00005917          	auipc	s2,0x5
    800035a4:	01890913          	addi	s2,s2,24 # 800085b8 <syscalls+0x168>
    800035a8:	85ca                	mv	a1,s2
    800035aa:	8526                	mv	a0,s1
    800035ac:	00001097          	auipc	ra,0x1
    800035b0:	e3a080e7          	jalr	-454(ra) # 800043e6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035b4:	08848493          	addi	s1,s1,136
    800035b8:	ff3498e3          	bne	s1,s3,800035a8 <iinit+0x3e>
}
    800035bc:	70a2                	ld	ra,40(sp)
    800035be:	7402                	ld	s0,32(sp)
    800035c0:	64e2                	ld	s1,24(sp)
    800035c2:	6942                	ld	s2,16(sp)
    800035c4:	69a2                	ld	s3,8(sp)
    800035c6:	6145                	addi	sp,sp,48
    800035c8:	8082                	ret

00000000800035ca <ialloc>:
{
    800035ca:	715d                	addi	sp,sp,-80
    800035cc:	e486                	sd	ra,72(sp)
    800035ce:	e0a2                	sd	s0,64(sp)
    800035d0:	fc26                	sd	s1,56(sp)
    800035d2:	f84a                	sd	s2,48(sp)
    800035d4:	f44e                	sd	s3,40(sp)
    800035d6:	f052                	sd	s4,32(sp)
    800035d8:	ec56                	sd	s5,24(sp)
    800035da:	e85a                	sd	s6,16(sp)
    800035dc:	e45e                	sd	s7,8(sp)
    800035de:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035e0:	0001c717          	auipc	a4,0x1c
    800035e4:	a7472703          	lw	a4,-1420(a4) # 8001f054 <sb+0xc>
    800035e8:	4785                	li	a5,1
    800035ea:	04e7fa63          	bgeu	a5,a4,8000363e <ialloc+0x74>
    800035ee:	8aaa                	mv	s5,a0
    800035f0:	8bae                	mv	s7,a1
    800035f2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035f4:	0001ca17          	auipc	s4,0x1c
    800035f8:	a54a0a13          	addi	s4,s4,-1452 # 8001f048 <sb>
    800035fc:	00048b1b          	sext.w	s6,s1
    80003600:	0044d793          	srli	a5,s1,0x4
    80003604:	018a2583          	lw	a1,24(s4)
    80003608:	9dbd                	addw	a1,a1,a5
    8000360a:	8556                	mv	a0,s5
    8000360c:	00000097          	auipc	ra,0x0
    80003610:	940080e7          	jalr	-1728(ra) # 80002f4c <bread>
    80003614:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003616:	05850993          	addi	s3,a0,88
    8000361a:	00f4f793          	andi	a5,s1,15
    8000361e:	079a                	slli	a5,a5,0x6
    80003620:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003622:	00099783          	lh	a5,0(s3)
    80003626:	c3a1                	beqz	a5,80003666 <ialloc+0x9c>
    brelse(bp);
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	a54080e7          	jalr	-1452(ra) # 8000307c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003630:	0485                	addi	s1,s1,1
    80003632:	00ca2703          	lw	a4,12(s4)
    80003636:	0004879b          	sext.w	a5,s1
    8000363a:	fce7e1e3          	bltu	a5,a4,800035fc <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000363e:	00005517          	auipc	a0,0x5
    80003642:	f8250513          	addi	a0,a0,-126 # 800085c0 <syscalls+0x170>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	f42080e7          	jalr	-190(ra) # 80000588 <printf>
  return 0;
    8000364e:	4501                	li	a0,0
}
    80003650:	60a6                	ld	ra,72(sp)
    80003652:	6406                	ld	s0,64(sp)
    80003654:	74e2                	ld	s1,56(sp)
    80003656:	7942                	ld	s2,48(sp)
    80003658:	79a2                	ld	s3,40(sp)
    8000365a:	7a02                	ld	s4,32(sp)
    8000365c:	6ae2                	ld	s5,24(sp)
    8000365e:	6b42                	ld	s6,16(sp)
    80003660:	6ba2                	ld	s7,8(sp)
    80003662:	6161                	addi	sp,sp,80
    80003664:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003666:	04000613          	li	a2,64
    8000366a:	4581                	li	a1,0
    8000366c:	854e                	mv	a0,s3
    8000366e:	ffffd097          	auipc	ra,0xffffd
    80003672:	6b0080e7          	jalr	1712(ra) # 80000d1e <memset>
      dip->type = type;
    80003676:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000367a:	854a                	mv	a0,s2
    8000367c:	00001097          	auipc	ra,0x1
    80003680:	c84080e7          	jalr	-892(ra) # 80004300 <log_write>
      brelse(bp);
    80003684:	854a                	mv	a0,s2
    80003686:	00000097          	auipc	ra,0x0
    8000368a:	9f6080e7          	jalr	-1546(ra) # 8000307c <brelse>
      return iget(dev, inum);
    8000368e:	85da                	mv	a1,s6
    80003690:	8556                	mv	a0,s5
    80003692:	00000097          	auipc	ra,0x0
    80003696:	d9c080e7          	jalr	-612(ra) # 8000342e <iget>
    8000369a:	bf5d                	j	80003650 <ialloc+0x86>

000000008000369c <iupdate>:
{
    8000369c:	1101                	addi	sp,sp,-32
    8000369e:	ec06                	sd	ra,24(sp)
    800036a0:	e822                	sd	s0,16(sp)
    800036a2:	e426                	sd	s1,8(sp)
    800036a4:	e04a                	sd	s2,0(sp)
    800036a6:	1000                	addi	s0,sp,32
    800036a8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036aa:	415c                	lw	a5,4(a0)
    800036ac:	0047d79b          	srliw	a5,a5,0x4
    800036b0:	0001c597          	auipc	a1,0x1c
    800036b4:	9b05a583          	lw	a1,-1616(a1) # 8001f060 <sb+0x18>
    800036b8:	9dbd                	addw	a1,a1,a5
    800036ba:	4108                	lw	a0,0(a0)
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	890080e7          	jalr	-1904(ra) # 80002f4c <bread>
    800036c4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036c6:	05850793          	addi	a5,a0,88
    800036ca:	40c8                	lw	a0,4(s1)
    800036cc:	893d                	andi	a0,a0,15
    800036ce:	051a                	slli	a0,a0,0x6
    800036d0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036d2:	04449703          	lh	a4,68(s1)
    800036d6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036da:	04649703          	lh	a4,70(s1)
    800036de:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036e2:	04849703          	lh	a4,72(s1)
    800036e6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036ea:	04a49703          	lh	a4,74(s1)
    800036ee:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036f2:	44f8                	lw	a4,76(s1)
    800036f4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036f6:	03400613          	li	a2,52
    800036fa:	05048593          	addi	a1,s1,80
    800036fe:	0531                	addi	a0,a0,12
    80003700:	ffffd097          	auipc	ra,0xffffd
    80003704:	67a080e7          	jalr	1658(ra) # 80000d7a <memmove>
  log_write(bp);
    80003708:	854a                	mv	a0,s2
    8000370a:	00001097          	auipc	ra,0x1
    8000370e:	bf6080e7          	jalr	-1034(ra) # 80004300 <log_write>
  brelse(bp);
    80003712:	854a                	mv	a0,s2
    80003714:	00000097          	auipc	ra,0x0
    80003718:	968080e7          	jalr	-1688(ra) # 8000307c <brelse>
}
    8000371c:	60e2                	ld	ra,24(sp)
    8000371e:	6442                	ld	s0,16(sp)
    80003720:	64a2                	ld	s1,8(sp)
    80003722:	6902                	ld	s2,0(sp)
    80003724:	6105                	addi	sp,sp,32
    80003726:	8082                	ret

0000000080003728 <idup>:
{
    80003728:	1101                	addi	sp,sp,-32
    8000372a:	ec06                	sd	ra,24(sp)
    8000372c:	e822                	sd	s0,16(sp)
    8000372e:	e426                	sd	s1,8(sp)
    80003730:	1000                	addi	s0,sp,32
    80003732:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003734:	0001c517          	auipc	a0,0x1c
    80003738:	93450513          	addi	a0,a0,-1740 # 8001f068 <itable>
    8000373c:	ffffd097          	auipc	ra,0xffffd
    80003740:	4e6080e7          	jalr	1254(ra) # 80000c22 <acquire>
  ip->ref++;
    80003744:	449c                	lw	a5,8(s1)
    80003746:	2785                	addiw	a5,a5,1
    80003748:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000374a:	0001c517          	auipc	a0,0x1c
    8000374e:	91e50513          	addi	a0,a0,-1762 # 8001f068 <itable>
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	584080e7          	jalr	1412(ra) # 80000cd6 <release>
}
    8000375a:	8526                	mv	a0,s1
    8000375c:	60e2                	ld	ra,24(sp)
    8000375e:	6442                	ld	s0,16(sp)
    80003760:	64a2                	ld	s1,8(sp)
    80003762:	6105                	addi	sp,sp,32
    80003764:	8082                	ret

0000000080003766 <ilock>:
{
    80003766:	1101                	addi	sp,sp,-32
    80003768:	ec06                	sd	ra,24(sp)
    8000376a:	e822                	sd	s0,16(sp)
    8000376c:	e426                	sd	s1,8(sp)
    8000376e:	e04a                	sd	s2,0(sp)
    80003770:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003772:	c115                	beqz	a0,80003796 <ilock+0x30>
    80003774:	84aa                	mv	s1,a0
    80003776:	451c                	lw	a5,8(a0)
    80003778:	00f05f63          	blez	a5,80003796 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000377c:	0541                	addi	a0,a0,16
    8000377e:	00001097          	auipc	ra,0x1
    80003782:	ca2080e7          	jalr	-862(ra) # 80004420 <acquiresleep>
  if(ip->valid == 0){
    80003786:	40bc                	lw	a5,64(s1)
    80003788:	cf99                	beqz	a5,800037a6 <ilock+0x40>
}
    8000378a:	60e2                	ld	ra,24(sp)
    8000378c:	6442                	ld	s0,16(sp)
    8000378e:	64a2                	ld	s1,8(sp)
    80003790:	6902                	ld	s2,0(sp)
    80003792:	6105                	addi	sp,sp,32
    80003794:	8082                	ret
    panic("ilock");
    80003796:	00005517          	auipc	a0,0x5
    8000379a:	e4250513          	addi	a0,a0,-446 # 800085d8 <syscalls+0x188>
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	da0080e7          	jalr	-608(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037a6:	40dc                	lw	a5,4(s1)
    800037a8:	0047d79b          	srliw	a5,a5,0x4
    800037ac:	0001c597          	auipc	a1,0x1c
    800037b0:	8b45a583          	lw	a1,-1868(a1) # 8001f060 <sb+0x18>
    800037b4:	9dbd                	addw	a1,a1,a5
    800037b6:	4088                	lw	a0,0(s1)
    800037b8:	fffff097          	auipc	ra,0xfffff
    800037bc:	794080e7          	jalr	1940(ra) # 80002f4c <bread>
    800037c0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037c2:	05850593          	addi	a1,a0,88
    800037c6:	40dc                	lw	a5,4(s1)
    800037c8:	8bbd                	andi	a5,a5,15
    800037ca:	079a                	slli	a5,a5,0x6
    800037cc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037ce:	00059783          	lh	a5,0(a1)
    800037d2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037d6:	00259783          	lh	a5,2(a1)
    800037da:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037de:	00459783          	lh	a5,4(a1)
    800037e2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037e6:	00659783          	lh	a5,6(a1)
    800037ea:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037ee:	459c                	lw	a5,8(a1)
    800037f0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037f2:	03400613          	li	a2,52
    800037f6:	05b1                	addi	a1,a1,12
    800037f8:	05048513          	addi	a0,s1,80
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	57e080e7          	jalr	1406(ra) # 80000d7a <memmove>
    brelse(bp);
    80003804:	854a                	mv	a0,s2
    80003806:	00000097          	auipc	ra,0x0
    8000380a:	876080e7          	jalr	-1930(ra) # 8000307c <brelse>
    ip->valid = 1;
    8000380e:	4785                	li	a5,1
    80003810:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003812:	04449783          	lh	a5,68(s1)
    80003816:	fbb5                	bnez	a5,8000378a <ilock+0x24>
      panic("ilock: no type");
    80003818:	00005517          	auipc	a0,0x5
    8000381c:	dc850513          	addi	a0,a0,-568 # 800085e0 <syscalls+0x190>
    80003820:	ffffd097          	auipc	ra,0xffffd
    80003824:	d1e080e7          	jalr	-738(ra) # 8000053e <panic>

0000000080003828 <iunlock>:
{
    80003828:	1101                	addi	sp,sp,-32
    8000382a:	ec06                	sd	ra,24(sp)
    8000382c:	e822                	sd	s0,16(sp)
    8000382e:	e426                	sd	s1,8(sp)
    80003830:	e04a                	sd	s2,0(sp)
    80003832:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003834:	c905                	beqz	a0,80003864 <iunlock+0x3c>
    80003836:	84aa                	mv	s1,a0
    80003838:	01050913          	addi	s2,a0,16
    8000383c:	854a                	mv	a0,s2
    8000383e:	00001097          	auipc	ra,0x1
    80003842:	c7c080e7          	jalr	-900(ra) # 800044ba <holdingsleep>
    80003846:	cd19                	beqz	a0,80003864 <iunlock+0x3c>
    80003848:	449c                	lw	a5,8(s1)
    8000384a:	00f05d63          	blez	a5,80003864 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000384e:	854a                	mv	a0,s2
    80003850:	00001097          	auipc	ra,0x1
    80003854:	c26080e7          	jalr	-986(ra) # 80004476 <releasesleep>
}
    80003858:	60e2                	ld	ra,24(sp)
    8000385a:	6442                	ld	s0,16(sp)
    8000385c:	64a2                	ld	s1,8(sp)
    8000385e:	6902                	ld	s2,0(sp)
    80003860:	6105                	addi	sp,sp,32
    80003862:	8082                	ret
    panic("iunlock");
    80003864:	00005517          	auipc	a0,0x5
    80003868:	d8c50513          	addi	a0,a0,-628 # 800085f0 <syscalls+0x1a0>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	cd2080e7          	jalr	-814(ra) # 8000053e <panic>

0000000080003874 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003874:	7179                	addi	sp,sp,-48
    80003876:	f406                	sd	ra,40(sp)
    80003878:	f022                	sd	s0,32(sp)
    8000387a:	ec26                	sd	s1,24(sp)
    8000387c:	e84a                	sd	s2,16(sp)
    8000387e:	e44e                	sd	s3,8(sp)
    80003880:	e052                	sd	s4,0(sp)
    80003882:	1800                	addi	s0,sp,48
    80003884:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003886:	05050493          	addi	s1,a0,80
    8000388a:	08050913          	addi	s2,a0,128
    8000388e:	a021                	j	80003896 <itrunc+0x22>
    80003890:	0491                	addi	s1,s1,4
    80003892:	01248d63          	beq	s1,s2,800038ac <itrunc+0x38>
    if(ip->addrs[i]){
    80003896:	408c                	lw	a1,0(s1)
    80003898:	dde5                	beqz	a1,80003890 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000389a:	0009a503          	lw	a0,0(s3)
    8000389e:	00000097          	auipc	ra,0x0
    800038a2:	8f4080e7          	jalr	-1804(ra) # 80003192 <bfree>
      ip->addrs[i] = 0;
    800038a6:	0004a023          	sw	zero,0(s1)
    800038aa:	b7dd                	j	80003890 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038ac:	0809a583          	lw	a1,128(s3)
    800038b0:	e185                	bnez	a1,800038d0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038b2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038b6:	854e                	mv	a0,s3
    800038b8:	00000097          	auipc	ra,0x0
    800038bc:	de4080e7          	jalr	-540(ra) # 8000369c <iupdate>
}
    800038c0:	70a2                	ld	ra,40(sp)
    800038c2:	7402                	ld	s0,32(sp)
    800038c4:	64e2                	ld	s1,24(sp)
    800038c6:	6942                	ld	s2,16(sp)
    800038c8:	69a2                	ld	s3,8(sp)
    800038ca:	6a02                	ld	s4,0(sp)
    800038cc:	6145                	addi	sp,sp,48
    800038ce:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038d0:	0009a503          	lw	a0,0(s3)
    800038d4:	fffff097          	auipc	ra,0xfffff
    800038d8:	678080e7          	jalr	1656(ra) # 80002f4c <bread>
    800038dc:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038de:	05850493          	addi	s1,a0,88
    800038e2:	45850913          	addi	s2,a0,1112
    800038e6:	a021                	j	800038ee <itrunc+0x7a>
    800038e8:	0491                	addi	s1,s1,4
    800038ea:	01248b63          	beq	s1,s2,80003900 <itrunc+0x8c>
      if(a[j])
    800038ee:	408c                	lw	a1,0(s1)
    800038f0:	dde5                	beqz	a1,800038e8 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038f2:	0009a503          	lw	a0,0(s3)
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	89c080e7          	jalr	-1892(ra) # 80003192 <bfree>
    800038fe:	b7ed                	j	800038e8 <itrunc+0x74>
    brelse(bp);
    80003900:	8552                	mv	a0,s4
    80003902:	fffff097          	auipc	ra,0xfffff
    80003906:	77a080e7          	jalr	1914(ra) # 8000307c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000390a:	0809a583          	lw	a1,128(s3)
    8000390e:	0009a503          	lw	a0,0(s3)
    80003912:	00000097          	auipc	ra,0x0
    80003916:	880080e7          	jalr	-1920(ra) # 80003192 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000391a:	0809a023          	sw	zero,128(s3)
    8000391e:	bf51                	j	800038b2 <itrunc+0x3e>

0000000080003920 <iput>:
{
    80003920:	1101                	addi	sp,sp,-32
    80003922:	ec06                	sd	ra,24(sp)
    80003924:	e822                	sd	s0,16(sp)
    80003926:	e426                	sd	s1,8(sp)
    80003928:	e04a                	sd	s2,0(sp)
    8000392a:	1000                	addi	s0,sp,32
    8000392c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000392e:	0001b517          	auipc	a0,0x1b
    80003932:	73a50513          	addi	a0,a0,1850 # 8001f068 <itable>
    80003936:	ffffd097          	auipc	ra,0xffffd
    8000393a:	2ec080e7          	jalr	748(ra) # 80000c22 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000393e:	4498                	lw	a4,8(s1)
    80003940:	4785                	li	a5,1
    80003942:	02f70363          	beq	a4,a5,80003968 <iput+0x48>
  ip->ref--;
    80003946:	449c                	lw	a5,8(s1)
    80003948:	37fd                	addiw	a5,a5,-1
    8000394a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000394c:	0001b517          	auipc	a0,0x1b
    80003950:	71c50513          	addi	a0,a0,1820 # 8001f068 <itable>
    80003954:	ffffd097          	auipc	ra,0xffffd
    80003958:	382080e7          	jalr	898(ra) # 80000cd6 <release>
}
    8000395c:	60e2                	ld	ra,24(sp)
    8000395e:	6442                	ld	s0,16(sp)
    80003960:	64a2                	ld	s1,8(sp)
    80003962:	6902                	ld	s2,0(sp)
    80003964:	6105                	addi	sp,sp,32
    80003966:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003968:	40bc                	lw	a5,64(s1)
    8000396a:	dff1                	beqz	a5,80003946 <iput+0x26>
    8000396c:	04a49783          	lh	a5,74(s1)
    80003970:	fbf9                	bnez	a5,80003946 <iput+0x26>
    acquiresleep(&ip->lock);
    80003972:	01048913          	addi	s2,s1,16
    80003976:	854a                	mv	a0,s2
    80003978:	00001097          	auipc	ra,0x1
    8000397c:	aa8080e7          	jalr	-1368(ra) # 80004420 <acquiresleep>
    release(&itable.lock);
    80003980:	0001b517          	auipc	a0,0x1b
    80003984:	6e850513          	addi	a0,a0,1768 # 8001f068 <itable>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	34e080e7          	jalr	846(ra) # 80000cd6 <release>
    itrunc(ip);
    80003990:	8526                	mv	a0,s1
    80003992:	00000097          	auipc	ra,0x0
    80003996:	ee2080e7          	jalr	-286(ra) # 80003874 <itrunc>
    ip->type = 0;
    8000399a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000399e:	8526                	mv	a0,s1
    800039a0:	00000097          	auipc	ra,0x0
    800039a4:	cfc080e7          	jalr	-772(ra) # 8000369c <iupdate>
    ip->valid = 0;
    800039a8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039ac:	854a                	mv	a0,s2
    800039ae:	00001097          	auipc	ra,0x1
    800039b2:	ac8080e7          	jalr	-1336(ra) # 80004476 <releasesleep>
    acquire(&itable.lock);
    800039b6:	0001b517          	auipc	a0,0x1b
    800039ba:	6b250513          	addi	a0,a0,1714 # 8001f068 <itable>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	264080e7          	jalr	612(ra) # 80000c22 <acquire>
    800039c6:	b741                	j	80003946 <iput+0x26>

00000000800039c8 <iunlockput>:
{
    800039c8:	1101                	addi	sp,sp,-32
    800039ca:	ec06                	sd	ra,24(sp)
    800039cc:	e822                	sd	s0,16(sp)
    800039ce:	e426                	sd	s1,8(sp)
    800039d0:	1000                	addi	s0,sp,32
    800039d2:	84aa                	mv	s1,a0
  iunlock(ip);
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	e54080e7          	jalr	-428(ra) # 80003828 <iunlock>
  iput(ip);
    800039dc:	8526                	mv	a0,s1
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	f42080e7          	jalr	-190(ra) # 80003920 <iput>
}
    800039e6:	60e2                	ld	ra,24(sp)
    800039e8:	6442                	ld	s0,16(sp)
    800039ea:	64a2                	ld	s1,8(sp)
    800039ec:	6105                	addi	sp,sp,32
    800039ee:	8082                	ret

00000000800039f0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039f0:	1141                	addi	sp,sp,-16
    800039f2:	e422                	sd	s0,8(sp)
    800039f4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039f6:	411c                	lw	a5,0(a0)
    800039f8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039fa:	415c                	lw	a5,4(a0)
    800039fc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039fe:	04451783          	lh	a5,68(a0)
    80003a02:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a06:	04a51783          	lh	a5,74(a0)
    80003a0a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a0e:	04c56783          	lwu	a5,76(a0)
    80003a12:	e99c                	sd	a5,16(a1)
}
    80003a14:	6422                	ld	s0,8(sp)
    80003a16:	0141                	addi	sp,sp,16
    80003a18:	8082                	ret

0000000080003a1a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a1a:	457c                	lw	a5,76(a0)
    80003a1c:	0ed7e963          	bltu	a5,a3,80003b0e <readi+0xf4>
{
    80003a20:	7159                	addi	sp,sp,-112
    80003a22:	f486                	sd	ra,104(sp)
    80003a24:	f0a2                	sd	s0,96(sp)
    80003a26:	eca6                	sd	s1,88(sp)
    80003a28:	e8ca                	sd	s2,80(sp)
    80003a2a:	e4ce                	sd	s3,72(sp)
    80003a2c:	e0d2                	sd	s4,64(sp)
    80003a2e:	fc56                	sd	s5,56(sp)
    80003a30:	f85a                	sd	s6,48(sp)
    80003a32:	f45e                	sd	s7,40(sp)
    80003a34:	f062                	sd	s8,32(sp)
    80003a36:	ec66                	sd	s9,24(sp)
    80003a38:	e86a                	sd	s10,16(sp)
    80003a3a:	e46e                	sd	s11,8(sp)
    80003a3c:	1880                	addi	s0,sp,112
    80003a3e:	8b2a                	mv	s6,a0
    80003a40:	8bae                	mv	s7,a1
    80003a42:	8a32                	mv	s4,a2
    80003a44:	84b6                	mv	s1,a3
    80003a46:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a48:	9f35                	addw	a4,a4,a3
    return 0;
    80003a4a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a4c:	0ad76063          	bltu	a4,a3,80003aec <readi+0xd2>
  if(off + n > ip->size)
    80003a50:	00e7f463          	bgeu	a5,a4,80003a58 <readi+0x3e>
    n = ip->size - off;
    80003a54:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a58:	0a0a8963          	beqz	s5,80003b0a <readi+0xf0>
    80003a5c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a5e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a62:	5c7d                	li	s8,-1
    80003a64:	a82d                	j	80003a9e <readi+0x84>
    80003a66:	020d1d93          	slli	s11,s10,0x20
    80003a6a:	020ddd93          	srli	s11,s11,0x20
    80003a6e:	05890793          	addi	a5,s2,88
    80003a72:	86ee                	mv	a3,s11
    80003a74:	963e                	add	a2,a2,a5
    80003a76:	85d2                	mv	a1,s4
    80003a78:	855e                	mv	a0,s7
    80003a7a:	fffff097          	auipc	ra,0xfffff
    80003a7e:	a2e080e7          	jalr	-1490(ra) # 800024a8 <either_copyout>
    80003a82:	05850d63          	beq	a0,s8,80003adc <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a86:	854a                	mv	a0,s2
    80003a88:	fffff097          	auipc	ra,0xfffff
    80003a8c:	5f4080e7          	jalr	1524(ra) # 8000307c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a90:	013d09bb          	addw	s3,s10,s3
    80003a94:	009d04bb          	addw	s1,s10,s1
    80003a98:	9a6e                	add	s4,s4,s11
    80003a9a:	0559f763          	bgeu	s3,s5,80003ae8 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a9e:	00a4d59b          	srliw	a1,s1,0xa
    80003aa2:	855a                	mv	a0,s6
    80003aa4:	00000097          	auipc	ra,0x0
    80003aa8:	8a2080e7          	jalr	-1886(ra) # 80003346 <bmap>
    80003aac:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ab0:	cd85                	beqz	a1,80003ae8 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003ab2:	000b2503          	lw	a0,0(s6)
    80003ab6:	fffff097          	auipc	ra,0xfffff
    80003aba:	496080e7          	jalr	1174(ra) # 80002f4c <bread>
    80003abe:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac0:	3ff4f613          	andi	a2,s1,1023
    80003ac4:	40cc87bb          	subw	a5,s9,a2
    80003ac8:	413a873b          	subw	a4,s5,s3
    80003acc:	8d3e                	mv	s10,a5
    80003ace:	2781                	sext.w	a5,a5
    80003ad0:	0007069b          	sext.w	a3,a4
    80003ad4:	f8f6f9e3          	bgeu	a3,a5,80003a66 <readi+0x4c>
    80003ad8:	8d3a                	mv	s10,a4
    80003ada:	b771                	j	80003a66 <readi+0x4c>
      brelse(bp);
    80003adc:	854a                	mv	a0,s2
    80003ade:	fffff097          	auipc	ra,0xfffff
    80003ae2:	59e080e7          	jalr	1438(ra) # 8000307c <brelse>
      tot = -1;
    80003ae6:	59fd                	li	s3,-1
  }
  return tot;
    80003ae8:	0009851b          	sext.w	a0,s3
}
    80003aec:	70a6                	ld	ra,104(sp)
    80003aee:	7406                	ld	s0,96(sp)
    80003af0:	64e6                	ld	s1,88(sp)
    80003af2:	6946                	ld	s2,80(sp)
    80003af4:	69a6                	ld	s3,72(sp)
    80003af6:	6a06                	ld	s4,64(sp)
    80003af8:	7ae2                	ld	s5,56(sp)
    80003afa:	7b42                	ld	s6,48(sp)
    80003afc:	7ba2                	ld	s7,40(sp)
    80003afe:	7c02                	ld	s8,32(sp)
    80003b00:	6ce2                	ld	s9,24(sp)
    80003b02:	6d42                	ld	s10,16(sp)
    80003b04:	6da2                	ld	s11,8(sp)
    80003b06:	6165                	addi	sp,sp,112
    80003b08:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b0a:	89d6                	mv	s3,s5
    80003b0c:	bff1                	j	80003ae8 <readi+0xce>
    return 0;
    80003b0e:	4501                	li	a0,0
}
    80003b10:	8082                	ret

0000000080003b12 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b12:	457c                	lw	a5,76(a0)
    80003b14:	10d7e863          	bltu	a5,a3,80003c24 <writei+0x112>
{
    80003b18:	7159                	addi	sp,sp,-112
    80003b1a:	f486                	sd	ra,104(sp)
    80003b1c:	f0a2                	sd	s0,96(sp)
    80003b1e:	eca6                	sd	s1,88(sp)
    80003b20:	e8ca                	sd	s2,80(sp)
    80003b22:	e4ce                	sd	s3,72(sp)
    80003b24:	e0d2                	sd	s4,64(sp)
    80003b26:	fc56                	sd	s5,56(sp)
    80003b28:	f85a                	sd	s6,48(sp)
    80003b2a:	f45e                	sd	s7,40(sp)
    80003b2c:	f062                	sd	s8,32(sp)
    80003b2e:	ec66                	sd	s9,24(sp)
    80003b30:	e86a                	sd	s10,16(sp)
    80003b32:	e46e                	sd	s11,8(sp)
    80003b34:	1880                	addi	s0,sp,112
    80003b36:	8aaa                	mv	s5,a0
    80003b38:	8bae                	mv	s7,a1
    80003b3a:	8a32                	mv	s4,a2
    80003b3c:	8936                	mv	s2,a3
    80003b3e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b40:	00e687bb          	addw	a5,a3,a4
    80003b44:	0ed7e263          	bltu	a5,a3,80003c28 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b48:	00043737          	lui	a4,0x43
    80003b4c:	0ef76063          	bltu	a4,a5,80003c2c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b50:	0c0b0863          	beqz	s6,80003c20 <writei+0x10e>
    80003b54:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b56:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b5a:	5c7d                	li	s8,-1
    80003b5c:	a091                	j	80003ba0 <writei+0x8e>
    80003b5e:	020d1d93          	slli	s11,s10,0x20
    80003b62:	020ddd93          	srli	s11,s11,0x20
    80003b66:	05848793          	addi	a5,s1,88
    80003b6a:	86ee                	mv	a3,s11
    80003b6c:	8652                	mv	a2,s4
    80003b6e:	85de                	mv	a1,s7
    80003b70:	953e                	add	a0,a0,a5
    80003b72:	fffff097          	auipc	ra,0xfffff
    80003b76:	98c080e7          	jalr	-1652(ra) # 800024fe <either_copyin>
    80003b7a:	07850263          	beq	a0,s8,80003bde <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b7e:	8526                	mv	a0,s1
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	780080e7          	jalr	1920(ra) # 80004300 <log_write>
    brelse(bp);
    80003b88:	8526                	mv	a0,s1
    80003b8a:	fffff097          	auipc	ra,0xfffff
    80003b8e:	4f2080e7          	jalr	1266(ra) # 8000307c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b92:	013d09bb          	addw	s3,s10,s3
    80003b96:	012d093b          	addw	s2,s10,s2
    80003b9a:	9a6e                	add	s4,s4,s11
    80003b9c:	0569f663          	bgeu	s3,s6,80003be8 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003ba0:	00a9559b          	srliw	a1,s2,0xa
    80003ba4:	8556                	mv	a0,s5
    80003ba6:	fffff097          	auipc	ra,0xfffff
    80003baa:	7a0080e7          	jalr	1952(ra) # 80003346 <bmap>
    80003bae:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bb2:	c99d                	beqz	a1,80003be8 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003bb4:	000aa503          	lw	a0,0(s5)
    80003bb8:	fffff097          	auipc	ra,0xfffff
    80003bbc:	394080e7          	jalr	916(ra) # 80002f4c <bread>
    80003bc0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bc2:	3ff97513          	andi	a0,s2,1023
    80003bc6:	40ac87bb          	subw	a5,s9,a0
    80003bca:	413b073b          	subw	a4,s6,s3
    80003bce:	8d3e                	mv	s10,a5
    80003bd0:	2781                	sext.w	a5,a5
    80003bd2:	0007069b          	sext.w	a3,a4
    80003bd6:	f8f6f4e3          	bgeu	a3,a5,80003b5e <writei+0x4c>
    80003bda:	8d3a                	mv	s10,a4
    80003bdc:	b749                	j	80003b5e <writei+0x4c>
      brelse(bp);
    80003bde:	8526                	mv	a0,s1
    80003be0:	fffff097          	auipc	ra,0xfffff
    80003be4:	49c080e7          	jalr	1180(ra) # 8000307c <brelse>
  }

  if(off > ip->size)
    80003be8:	04caa783          	lw	a5,76(s5)
    80003bec:	0127f463          	bgeu	a5,s2,80003bf4 <writei+0xe2>
    ip->size = off;
    80003bf0:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bf4:	8556                	mv	a0,s5
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	aa6080e7          	jalr	-1370(ra) # 8000369c <iupdate>

  return tot;
    80003bfe:	0009851b          	sext.w	a0,s3
}
    80003c02:	70a6                	ld	ra,104(sp)
    80003c04:	7406                	ld	s0,96(sp)
    80003c06:	64e6                	ld	s1,88(sp)
    80003c08:	6946                	ld	s2,80(sp)
    80003c0a:	69a6                	ld	s3,72(sp)
    80003c0c:	6a06                	ld	s4,64(sp)
    80003c0e:	7ae2                	ld	s5,56(sp)
    80003c10:	7b42                	ld	s6,48(sp)
    80003c12:	7ba2                	ld	s7,40(sp)
    80003c14:	7c02                	ld	s8,32(sp)
    80003c16:	6ce2                	ld	s9,24(sp)
    80003c18:	6d42                	ld	s10,16(sp)
    80003c1a:	6da2                	ld	s11,8(sp)
    80003c1c:	6165                	addi	sp,sp,112
    80003c1e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c20:	89da                	mv	s3,s6
    80003c22:	bfc9                	j	80003bf4 <writei+0xe2>
    return -1;
    80003c24:	557d                	li	a0,-1
}
    80003c26:	8082                	ret
    return -1;
    80003c28:	557d                	li	a0,-1
    80003c2a:	bfe1                	j	80003c02 <writei+0xf0>
    return -1;
    80003c2c:	557d                	li	a0,-1
    80003c2e:	bfd1                	j	80003c02 <writei+0xf0>

0000000080003c30 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c30:	1141                	addi	sp,sp,-16
    80003c32:	e406                	sd	ra,8(sp)
    80003c34:	e022                	sd	s0,0(sp)
    80003c36:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c38:	4639                	li	a2,14
    80003c3a:	ffffd097          	auipc	ra,0xffffd
    80003c3e:	1b4080e7          	jalr	436(ra) # 80000dee <strncmp>
}
    80003c42:	60a2                	ld	ra,8(sp)
    80003c44:	6402                	ld	s0,0(sp)
    80003c46:	0141                	addi	sp,sp,16
    80003c48:	8082                	ret

0000000080003c4a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c4a:	7139                	addi	sp,sp,-64
    80003c4c:	fc06                	sd	ra,56(sp)
    80003c4e:	f822                	sd	s0,48(sp)
    80003c50:	f426                	sd	s1,40(sp)
    80003c52:	f04a                	sd	s2,32(sp)
    80003c54:	ec4e                	sd	s3,24(sp)
    80003c56:	e852                	sd	s4,16(sp)
    80003c58:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c5a:	04451703          	lh	a4,68(a0)
    80003c5e:	4785                	li	a5,1
    80003c60:	00f71a63          	bne	a4,a5,80003c74 <dirlookup+0x2a>
    80003c64:	892a                	mv	s2,a0
    80003c66:	89ae                	mv	s3,a1
    80003c68:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c6a:	457c                	lw	a5,76(a0)
    80003c6c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c6e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c70:	e79d                	bnez	a5,80003c9e <dirlookup+0x54>
    80003c72:	a8a5                	j	80003cea <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c74:	00005517          	auipc	a0,0x5
    80003c78:	98450513          	addi	a0,a0,-1660 # 800085f8 <syscalls+0x1a8>
    80003c7c:	ffffd097          	auipc	ra,0xffffd
    80003c80:	8c2080e7          	jalr	-1854(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c84:	00005517          	auipc	a0,0x5
    80003c88:	98c50513          	addi	a0,a0,-1652 # 80008610 <syscalls+0x1c0>
    80003c8c:	ffffd097          	auipc	ra,0xffffd
    80003c90:	8b2080e7          	jalr	-1870(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c94:	24c1                	addiw	s1,s1,16
    80003c96:	04c92783          	lw	a5,76(s2)
    80003c9a:	04f4f763          	bgeu	s1,a5,80003ce8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c9e:	4741                	li	a4,16
    80003ca0:	86a6                	mv	a3,s1
    80003ca2:	fc040613          	addi	a2,s0,-64
    80003ca6:	4581                	li	a1,0
    80003ca8:	854a                	mv	a0,s2
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	d70080e7          	jalr	-656(ra) # 80003a1a <readi>
    80003cb2:	47c1                	li	a5,16
    80003cb4:	fcf518e3          	bne	a0,a5,80003c84 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cb8:	fc045783          	lhu	a5,-64(s0)
    80003cbc:	dfe1                	beqz	a5,80003c94 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cbe:	fc240593          	addi	a1,s0,-62
    80003cc2:	854e                	mv	a0,s3
    80003cc4:	00000097          	auipc	ra,0x0
    80003cc8:	f6c080e7          	jalr	-148(ra) # 80003c30 <namecmp>
    80003ccc:	f561                	bnez	a0,80003c94 <dirlookup+0x4a>
      if(poff)
    80003cce:	000a0463          	beqz	s4,80003cd6 <dirlookup+0x8c>
        *poff = off;
    80003cd2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cd6:	fc045583          	lhu	a1,-64(s0)
    80003cda:	00092503          	lw	a0,0(s2)
    80003cde:	fffff097          	auipc	ra,0xfffff
    80003ce2:	750080e7          	jalr	1872(ra) # 8000342e <iget>
    80003ce6:	a011                	j	80003cea <dirlookup+0xa0>
  return 0;
    80003ce8:	4501                	li	a0,0
}
    80003cea:	70e2                	ld	ra,56(sp)
    80003cec:	7442                	ld	s0,48(sp)
    80003cee:	74a2                	ld	s1,40(sp)
    80003cf0:	7902                	ld	s2,32(sp)
    80003cf2:	69e2                	ld	s3,24(sp)
    80003cf4:	6a42                	ld	s4,16(sp)
    80003cf6:	6121                	addi	sp,sp,64
    80003cf8:	8082                	ret

0000000080003cfa <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cfa:	711d                	addi	sp,sp,-96
    80003cfc:	ec86                	sd	ra,88(sp)
    80003cfe:	e8a2                	sd	s0,80(sp)
    80003d00:	e4a6                	sd	s1,72(sp)
    80003d02:	e0ca                	sd	s2,64(sp)
    80003d04:	fc4e                	sd	s3,56(sp)
    80003d06:	f852                	sd	s4,48(sp)
    80003d08:	f456                	sd	s5,40(sp)
    80003d0a:	f05a                	sd	s6,32(sp)
    80003d0c:	ec5e                	sd	s7,24(sp)
    80003d0e:	e862                	sd	s8,16(sp)
    80003d10:	e466                	sd	s9,8(sp)
    80003d12:	1080                	addi	s0,sp,96
    80003d14:	84aa                	mv	s1,a0
    80003d16:	8aae                	mv	s5,a1
    80003d18:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d1a:	00054703          	lbu	a4,0(a0)
    80003d1e:	02f00793          	li	a5,47
    80003d22:	02f70363          	beq	a4,a5,80003d48 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d26:	ffffe097          	auipc	ra,0xffffe
    80003d2a:	cd2080e7          	jalr	-814(ra) # 800019f8 <myproc>
    80003d2e:	15053503          	ld	a0,336(a0)
    80003d32:	00000097          	auipc	ra,0x0
    80003d36:	9f6080e7          	jalr	-1546(ra) # 80003728 <idup>
    80003d3a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d3c:	02f00913          	li	s2,47
  len = path - s;
    80003d40:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003d42:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d44:	4b85                	li	s7,1
    80003d46:	a865                	j	80003dfe <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d48:	4585                	li	a1,1
    80003d4a:	4505                	li	a0,1
    80003d4c:	fffff097          	auipc	ra,0xfffff
    80003d50:	6e2080e7          	jalr	1762(ra) # 8000342e <iget>
    80003d54:	89aa                	mv	s3,a0
    80003d56:	b7dd                	j	80003d3c <namex+0x42>
      iunlockput(ip);
    80003d58:	854e                	mv	a0,s3
    80003d5a:	00000097          	auipc	ra,0x0
    80003d5e:	c6e080e7          	jalr	-914(ra) # 800039c8 <iunlockput>
      return 0;
    80003d62:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d64:	854e                	mv	a0,s3
    80003d66:	60e6                	ld	ra,88(sp)
    80003d68:	6446                	ld	s0,80(sp)
    80003d6a:	64a6                	ld	s1,72(sp)
    80003d6c:	6906                	ld	s2,64(sp)
    80003d6e:	79e2                	ld	s3,56(sp)
    80003d70:	7a42                	ld	s4,48(sp)
    80003d72:	7aa2                	ld	s5,40(sp)
    80003d74:	7b02                	ld	s6,32(sp)
    80003d76:	6be2                	ld	s7,24(sp)
    80003d78:	6c42                	ld	s8,16(sp)
    80003d7a:	6ca2                	ld	s9,8(sp)
    80003d7c:	6125                	addi	sp,sp,96
    80003d7e:	8082                	ret
      iunlock(ip);
    80003d80:	854e                	mv	a0,s3
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	aa6080e7          	jalr	-1370(ra) # 80003828 <iunlock>
      return ip;
    80003d8a:	bfe9                	j	80003d64 <namex+0x6a>
      iunlockput(ip);
    80003d8c:	854e                	mv	a0,s3
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	c3a080e7          	jalr	-966(ra) # 800039c8 <iunlockput>
      return 0;
    80003d96:	89e6                	mv	s3,s9
    80003d98:	b7f1                	j	80003d64 <namex+0x6a>
  len = path - s;
    80003d9a:	40b48633          	sub	a2,s1,a1
    80003d9e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003da2:	099c5463          	bge	s8,s9,80003e2a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003da6:	4639                	li	a2,14
    80003da8:	8552                	mv	a0,s4
    80003daa:	ffffd097          	auipc	ra,0xffffd
    80003dae:	fd0080e7          	jalr	-48(ra) # 80000d7a <memmove>
  while(*path == '/')
    80003db2:	0004c783          	lbu	a5,0(s1)
    80003db6:	01279763          	bne	a5,s2,80003dc4 <namex+0xca>
    path++;
    80003dba:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dbc:	0004c783          	lbu	a5,0(s1)
    80003dc0:	ff278de3          	beq	a5,s2,80003dba <namex+0xc0>
    ilock(ip);
    80003dc4:	854e                	mv	a0,s3
    80003dc6:	00000097          	auipc	ra,0x0
    80003dca:	9a0080e7          	jalr	-1632(ra) # 80003766 <ilock>
    if(ip->type != T_DIR){
    80003dce:	04499783          	lh	a5,68(s3)
    80003dd2:	f97793e3          	bne	a5,s7,80003d58 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dd6:	000a8563          	beqz	s5,80003de0 <namex+0xe6>
    80003dda:	0004c783          	lbu	a5,0(s1)
    80003dde:	d3cd                	beqz	a5,80003d80 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003de0:	865a                	mv	a2,s6
    80003de2:	85d2                	mv	a1,s4
    80003de4:	854e                	mv	a0,s3
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	e64080e7          	jalr	-412(ra) # 80003c4a <dirlookup>
    80003dee:	8caa                	mv	s9,a0
    80003df0:	dd51                	beqz	a0,80003d8c <namex+0x92>
    iunlockput(ip);
    80003df2:	854e                	mv	a0,s3
    80003df4:	00000097          	auipc	ra,0x0
    80003df8:	bd4080e7          	jalr	-1068(ra) # 800039c8 <iunlockput>
    ip = next;
    80003dfc:	89e6                	mv	s3,s9
  while(*path == '/')
    80003dfe:	0004c783          	lbu	a5,0(s1)
    80003e02:	05279763          	bne	a5,s2,80003e50 <namex+0x156>
    path++;
    80003e06:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e08:	0004c783          	lbu	a5,0(s1)
    80003e0c:	ff278de3          	beq	a5,s2,80003e06 <namex+0x10c>
  if(*path == 0)
    80003e10:	c79d                	beqz	a5,80003e3e <namex+0x144>
    path++;
    80003e12:	85a6                	mv	a1,s1
  len = path - s;
    80003e14:	8cda                	mv	s9,s6
    80003e16:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003e18:	01278963          	beq	a5,s2,80003e2a <namex+0x130>
    80003e1c:	dfbd                	beqz	a5,80003d9a <namex+0xa0>
    path++;
    80003e1e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e20:	0004c783          	lbu	a5,0(s1)
    80003e24:	ff279ce3          	bne	a5,s2,80003e1c <namex+0x122>
    80003e28:	bf8d                	j	80003d9a <namex+0xa0>
    memmove(name, s, len);
    80003e2a:	2601                	sext.w	a2,a2
    80003e2c:	8552                	mv	a0,s4
    80003e2e:	ffffd097          	auipc	ra,0xffffd
    80003e32:	f4c080e7          	jalr	-180(ra) # 80000d7a <memmove>
    name[len] = 0;
    80003e36:	9cd2                	add	s9,s9,s4
    80003e38:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e3c:	bf9d                	j	80003db2 <namex+0xb8>
  if(nameiparent){
    80003e3e:	f20a83e3          	beqz	s5,80003d64 <namex+0x6a>
    iput(ip);
    80003e42:	854e                	mv	a0,s3
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	adc080e7          	jalr	-1316(ra) # 80003920 <iput>
    return 0;
    80003e4c:	4981                	li	s3,0
    80003e4e:	bf19                	j	80003d64 <namex+0x6a>
  if(*path == 0)
    80003e50:	d7fd                	beqz	a5,80003e3e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e52:	0004c783          	lbu	a5,0(s1)
    80003e56:	85a6                	mv	a1,s1
    80003e58:	b7d1                	j	80003e1c <namex+0x122>

0000000080003e5a <dirlink>:
{
    80003e5a:	7139                	addi	sp,sp,-64
    80003e5c:	fc06                	sd	ra,56(sp)
    80003e5e:	f822                	sd	s0,48(sp)
    80003e60:	f426                	sd	s1,40(sp)
    80003e62:	f04a                	sd	s2,32(sp)
    80003e64:	ec4e                	sd	s3,24(sp)
    80003e66:	e852                	sd	s4,16(sp)
    80003e68:	0080                	addi	s0,sp,64
    80003e6a:	892a                	mv	s2,a0
    80003e6c:	8a2e                	mv	s4,a1
    80003e6e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e70:	4601                	li	a2,0
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	dd8080e7          	jalr	-552(ra) # 80003c4a <dirlookup>
    80003e7a:	e93d                	bnez	a0,80003ef0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e7c:	04c92483          	lw	s1,76(s2)
    80003e80:	c49d                	beqz	s1,80003eae <dirlink+0x54>
    80003e82:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e84:	4741                	li	a4,16
    80003e86:	86a6                	mv	a3,s1
    80003e88:	fc040613          	addi	a2,s0,-64
    80003e8c:	4581                	li	a1,0
    80003e8e:	854a                	mv	a0,s2
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	b8a080e7          	jalr	-1142(ra) # 80003a1a <readi>
    80003e98:	47c1                	li	a5,16
    80003e9a:	06f51163          	bne	a0,a5,80003efc <dirlink+0xa2>
    if(de.inum == 0)
    80003e9e:	fc045783          	lhu	a5,-64(s0)
    80003ea2:	c791                	beqz	a5,80003eae <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ea4:	24c1                	addiw	s1,s1,16
    80003ea6:	04c92783          	lw	a5,76(s2)
    80003eaa:	fcf4ede3          	bltu	s1,a5,80003e84 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003eae:	4639                	li	a2,14
    80003eb0:	85d2                	mv	a1,s4
    80003eb2:	fc240513          	addi	a0,s0,-62
    80003eb6:	ffffd097          	auipc	ra,0xffffd
    80003eba:	f74080e7          	jalr	-140(ra) # 80000e2a <strncpy>
  de.inum = inum;
    80003ebe:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ec2:	4741                	li	a4,16
    80003ec4:	86a6                	mv	a3,s1
    80003ec6:	fc040613          	addi	a2,s0,-64
    80003eca:	4581                	li	a1,0
    80003ecc:	854a                	mv	a0,s2
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	c44080e7          	jalr	-956(ra) # 80003b12 <writei>
    80003ed6:	1541                	addi	a0,a0,-16
    80003ed8:	00a03533          	snez	a0,a0
    80003edc:	40a00533          	neg	a0,a0
}
    80003ee0:	70e2                	ld	ra,56(sp)
    80003ee2:	7442                	ld	s0,48(sp)
    80003ee4:	74a2                	ld	s1,40(sp)
    80003ee6:	7902                	ld	s2,32(sp)
    80003ee8:	69e2                	ld	s3,24(sp)
    80003eea:	6a42                	ld	s4,16(sp)
    80003eec:	6121                	addi	sp,sp,64
    80003eee:	8082                	ret
    iput(ip);
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	a30080e7          	jalr	-1488(ra) # 80003920 <iput>
    return -1;
    80003ef8:	557d                	li	a0,-1
    80003efa:	b7dd                	j	80003ee0 <dirlink+0x86>
      panic("dirlink read");
    80003efc:	00004517          	auipc	a0,0x4
    80003f00:	72450513          	addi	a0,a0,1828 # 80008620 <syscalls+0x1d0>
    80003f04:	ffffc097          	auipc	ra,0xffffc
    80003f08:	63a080e7          	jalr	1594(ra) # 8000053e <panic>

0000000080003f0c <namei>:

struct inode*
namei(char *path)
{
    80003f0c:	1101                	addi	sp,sp,-32
    80003f0e:	ec06                	sd	ra,24(sp)
    80003f10:	e822                	sd	s0,16(sp)
    80003f12:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f14:	fe040613          	addi	a2,s0,-32
    80003f18:	4581                	li	a1,0
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	de0080e7          	jalr	-544(ra) # 80003cfa <namex>
}
    80003f22:	60e2                	ld	ra,24(sp)
    80003f24:	6442                	ld	s0,16(sp)
    80003f26:	6105                	addi	sp,sp,32
    80003f28:	8082                	ret

0000000080003f2a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f2a:	1141                	addi	sp,sp,-16
    80003f2c:	e406                	sd	ra,8(sp)
    80003f2e:	e022                	sd	s0,0(sp)
    80003f30:	0800                	addi	s0,sp,16
    80003f32:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f34:	4585                	li	a1,1
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	dc4080e7          	jalr	-572(ra) # 80003cfa <namex>
}
    80003f3e:	60a2                	ld	ra,8(sp)
    80003f40:	6402                	ld	s0,0(sp)
    80003f42:	0141                	addi	sp,sp,16
    80003f44:	8082                	ret

0000000080003f46 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f46:	1101                	addi	sp,sp,-32
    80003f48:	ec06                	sd	ra,24(sp)
    80003f4a:	e822                	sd	s0,16(sp)
    80003f4c:	e426                	sd	s1,8(sp)
    80003f4e:	e04a                	sd	s2,0(sp)
    80003f50:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f52:	0001d917          	auipc	s2,0x1d
    80003f56:	bbe90913          	addi	s2,s2,-1090 # 80020b10 <log>
    80003f5a:	01892583          	lw	a1,24(s2)
    80003f5e:	02892503          	lw	a0,40(s2)
    80003f62:	fffff097          	auipc	ra,0xfffff
    80003f66:	fea080e7          	jalr	-22(ra) # 80002f4c <bread>
    80003f6a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f6c:	02c92683          	lw	a3,44(s2)
    80003f70:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f72:	02d05763          	blez	a3,80003fa0 <write_head+0x5a>
    80003f76:	0001d797          	auipc	a5,0x1d
    80003f7a:	bca78793          	addi	a5,a5,-1078 # 80020b40 <log+0x30>
    80003f7e:	05c50713          	addi	a4,a0,92
    80003f82:	36fd                	addiw	a3,a3,-1
    80003f84:	1682                	slli	a3,a3,0x20
    80003f86:	9281                	srli	a3,a3,0x20
    80003f88:	068a                	slli	a3,a3,0x2
    80003f8a:	0001d617          	auipc	a2,0x1d
    80003f8e:	bba60613          	addi	a2,a2,-1094 # 80020b44 <log+0x34>
    80003f92:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f94:	4390                	lw	a2,0(a5)
    80003f96:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f98:	0791                	addi	a5,a5,4
    80003f9a:	0711                	addi	a4,a4,4
    80003f9c:	fed79ce3          	bne	a5,a3,80003f94 <write_head+0x4e>
  }
  bwrite(buf);
    80003fa0:	8526                	mv	a0,s1
    80003fa2:	fffff097          	auipc	ra,0xfffff
    80003fa6:	09c080e7          	jalr	156(ra) # 8000303e <bwrite>
  brelse(buf);
    80003faa:	8526                	mv	a0,s1
    80003fac:	fffff097          	auipc	ra,0xfffff
    80003fb0:	0d0080e7          	jalr	208(ra) # 8000307c <brelse>
}
    80003fb4:	60e2                	ld	ra,24(sp)
    80003fb6:	6442                	ld	s0,16(sp)
    80003fb8:	64a2                	ld	s1,8(sp)
    80003fba:	6902                	ld	s2,0(sp)
    80003fbc:	6105                	addi	sp,sp,32
    80003fbe:	8082                	ret

0000000080003fc0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fc0:	0001d797          	auipc	a5,0x1d
    80003fc4:	b7c7a783          	lw	a5,-1156(a5) # 80020b3c <log+0x2c>
    80003fc8:	0af05d63          	blez	a5,80004082 <install_trans+0xc2>
{
    80003fcc:	7139                	addi	sp,sp,-64
    80003fce:	fc06                	sd	ra,56(sp)
    80003fd0:	f822                	sd	s0,48(sp)
    80003fd2:	f426                	sd	s1,40(sp)
    80003fd4:	f04a                	sd	s2,32(sp)
    80003fd6:	ec4e                	sd	s3,24(sp)
    80003fd8:	e852                	sd	s4,16(sp)
    80003fda:	e456                	sd	s5,8(sp)
    80003fdc:	e05a                	sd	s6,0(sp)
    80003fde:	0080                	addi	s0,sp,64
    80003fe0:	8b2a                	mv	s6,a0
    80003fe2:	0001da97          	auipc	s5,0x1d
    80003fe6:	b5ea8a93          	addi	s5,s5,-1186 # 80020b40 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fea:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fec:	0001d997          	auipc	s3,0x1d
    80003ff0:	b2498993          	addi	s3,s3,-1244 # 80020b10 <log>
    80003ff4:	a00d                	j	80004016 <install_trans+0x56>
    brelse(lbuf);
    80003ff6:	854a                	mv	a0,s2
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	084080e7          	jalr	132(ra) # 8000307c <brelse>
    brelse(dbuf);
    80004000:	8526                	mv	a0,s1
    80004002:	fffff097          	auipc	ra,0xfffff
    80004006:	07a080e7          	jalr	122(ra) # 8000307c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000400a:	2a05                	addiw	s4,s4,1
    8000400c:	0a91                	addi	s5,s5,4
    8000400e:	02c9a783          	lw	a5,44(s3)
    80004012:	04fa5e63          	bge	s4,a5,8000406e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004016:	0189a583          	lw	a1,24(s3)
    8000401a:	014585bb          	addw	a1,a1,s4
    8000401e:	2585                	addiw	a1,a1,1
    80004020:	0289a503          	lw	a0,40(s3)
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	f28080e7          	jalr	-216(ra) # 80002f4c <bread>
    8000402c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000402e:	000aa583          	lw	a1,0(s5)
    80004032:	0289a503          	lw	a0,40(s3)
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	f16080e7          	jalr	-234(ra) # 80002f4c <bread>
    8000403e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004040:	40000613          	li	a2,1024
    80004044:	05890593          	addi	a1,s2,88
    80004048:	05850513          	addi	a0,a0,88
    8000404c:	ffffd097          	auipc	ra,0xffffd
    80004050:	d2e080e7          	jalr	-722(ra) # 80000d7a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004054:	8526                	mv	a0,s1
    80004056:	fffff097          	auipc	ra,0xfffff
    8000405a:	fe8080e7          	jalr	-24(ra) # 8000303e <bwrite>
    if(recovering == 0)
    8000405e:	f80b1ce3          	bnez	s6,80003ff6 <install_trans+0x36>
      bunpin(dbuf);
    80004062:	8526                	mv	a0,s1
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	0f2080e7          	jalr	242(ra) # 80003156 <bunpin>
    8000406c:	b769                	j	80003ff6 <install_trans+0x36>
}
    8000406e:	70e2                	ld	ra,56(sp)
    80004070:	7442                	ld	s0,48(sp)
    80004072:	74a2                	ld	s1,40(sp)
    80004074:	7902                	ld	s2,32(sp)
    80004076:	69e2                	ld	s3,24(sp)
    80004078:	6a42                	ld	s4,16(sp)
    8000407a:	6aa2                	ld	s5,8(sp)
    8000407c:	6b02                	ld	s6,0(sp)
    8000407e:	6121                	addi	sp,sp,64
    80004080:	8082                	ret
    80004082:	8082                	ret

0000000080004084 <initlog>:
{
    80004084:	7179                	addi	sp,sp,-48
    80004086:	f406                	sd	ra,40(sp)
    80004088:	f022                	sd	s0,32(sp)
    8000408a:	ec26                	sd	s1,24(sp)
    8000408c:	e84a                	sd	s2,16(sp)
    8000408e:	e44e                	sd	s3,8(sp)
    80004090:	1800                	addi	s0,sp,48
    80004092:	892a                	mv	s2,a0
    80004094:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004096:	0001d497          	auipc	s1,0x1d
    8000409a:	a7a48493          	addi	s1,s1,-1414 # 80020b10 <log>
    8000409e:	00004597          	auipc	a1,0x4
    800040a2:	59258593          	addi	a1,a1,1426 # 80008630 <syscalls+0x1e0>
    800040a6:	8526                	mv	a0,s1
    800040a8:	ffffd097          	auipc	ra,0xffffd
    800040ac:	aea080e7          	jalr	-1302(ra) # 80000b92 <initlock>
  log.start = sb->logstart;
    800040b0:	0149a583          	lw	a1,20(s3)
    800040b4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040b6:	0109a783          	lw	a5,16(s3)
    800040ba:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040bc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040c0:	854a                	mv	a0,s2
    800040c2:	fffff097          	auipc	ra,0xfffff
    800040c6:	e8a080e7          	jalr	-374(ra) # 80002f4c <bread>
  log.lh.n = lh->n;
    800040ca:	4d34                	lw	a3,88(a0)
    800040cc:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040ce:	02d05563          	blez	a3,800040f8 <initlog+0x74>
    800040d2:	05c50793          	addi	a5,a0,92
    800040d6:	0001d717          	auipc	a4,0x1d
    800040da:	a6a70713          	addi	a4,a4,-1430 # 80020b40 <log+0x30>
    800040de:	36fd                	addiw	a3,a3,-1
    800040e0:	1682                	slli	a3,a3,0x20
    800040e2:	9281                	srli	a3,a3,0x20
    800040e4:	068a                	slli	a3,a3,0x2
    800040e6:	06050613          	addi	a2,a0,96
    800040ea:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800040ec:	4390                	lw	a2,0(a5)
    800040ee:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040f0:	0791                	addi	a5,a5,4
    800040f2:	0711                	addi	a4,a4,4
    800040f4:	fed79ce3          	bne	a5,a3,800040ec <initlog+0x68>
  brelse(buf);
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	f84080e7          	jalr	-124(ra) # 8000307c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004100:	4505                	li	a0,1
    80004102:	00000097          	auipc	ra,0x0
    80004106:	ebe080e7          	jalr	-322(ra) # 80003fc0 <install_trans>
  log.lh.n = 0;
    8000410a:	0001d797          	auipc	a5,0x1d
    8000410e:	a207a923          	sw	zero,-1486(a5) # 80020b3c <log+0x2c>
  write_head(); // clear the log
    80004112:	00000097          	auipc	ra,0x0
    80004116:	e34080e7          	jalr	-460(ra) # 80003f46 <write_head>
}
    8000411a:	70a2                	ld	ra,40(sp)
    8000411c:	7402                	ld	s0,32(sp)
    8000411e:	64e2                	ld	s1,24(sp)
    80004120:	6942                	ld	s2,16(sp)
    80004122:	69a2                	ld	s3,8(sp)
    80004124:	6145                	addi	sp,sp,48
    80004126:	8082                	ret

0000000080004128 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004128:	1101                	addi	sp,sp,-32
    8000412a:	ec06                	sd	ra,24(sp)
    8000412c:	e822                	sd	s0,16(sp)
    8000412e:	e426                	sd	s1,8(sp)
    80004130:	e04a                	sd	s2,0(sp)
    80004132:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004134:	0001d517          	auipc	a0,0x1d
    80004138:	9dc50513          	addi	a0,a0,-1572 # 80020b10 <log>
    8000413c:	ffffd097          	auipc	ra,0xffffd
    80004140:	ae6080e7          	jalr	-1306(ra) # 80000c22 <acquire>
  while(1){
    if(log.committing){
    80004144:	0001d497          	auipc	s1,0x1d
    80004148:	9cc48493          	addi	s1,s1,-1588 # 80020b10 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000414c:	4979                	li	s2,30
    8000414e:	a039                	j	8000415c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004150:	85a6                	mv	a1,s1
    80004152:	8526                	mv	a0,s1
    80004154:	ffffe097          	auipc	ra,0xffffe
    80004158:	f4c080e7          	jalr	-180(ra) # 800020a0 <sleep>
    if(log.committing){
    8000415c:	50dc                	lw	a5,36(s1)
    8000415e:	fbed                	bnez	a5,80004150 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004160:	509c                	lw	a5,32(s1)
    80004162:	0017871b          	addiw	a4,a5,1
    80004166:	0007069b          	sext.w	a3,a4
    8000416a:	0027179b          	slliw	a5,a4,0x2
    8000416e:	9fb9                	addw	a5,a5,a4
    80004170:	0017979b          	slliw	a5,a5,0x1
    80004174:	54d8                	lw	a4,44(s1)
    80004176:	9fb9                	addw	a5,a5,a4
    80004178:	00f95963          	bge	s2,a5,8000418a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000417c:	85a6                	mv	a1,s1
    8000417e:	8526                	mv	a0,s1
    80004180:	ffffe097          	auipc	ra,0xffffe
    80004184:	f20080e7          	jalr	-224(ra) # 800020a0 <sleep>
    80004188:	bfd1                	j	8000415c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000418a:	0001d517          	auipc	a0,0x1d
    8000418e:	98650513          	addi	a0,a0,-1658 # 80020b10 <log>
    80004192:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004194:	ffffd097          	auipc	ra,0xffffd
    80004198:	b42080e7          	jalr	-1214(ra) # 80000cd6 <release>
      break;
    }
  }
}
    8000419c:	60e2                	ld	ra,24(sp)
    8000419e:	6442                	ld	s0,16(sp)
    800041a0:	64a2                	ld	s1,8(sp)
    800041a2:	6902                	ld	s2,0(sp)
    800041a4:	6105                	addi	sp,sp,32
    800041a6:	8082                	ret

00000000800041a8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041a8:	7139                	addi	sp,sp,-64
    800041aa:	fc06                	sd	ra,56(sp)
    800041ac:	f822                	sd	s0,48(sp)
    800041ae:	f426                	sd	s1,40(sp)
    800041b0:	f04a                	sd	s2,32(sp)
    800041b2:	ec4e                	sd	s3,24(sp)
    800041b4:	e852                	sd	s4,16(sp)
    800041b6:	e456                	sd	s5,8(sp)
    800041b8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041ba:	0001d497          	auipc	s1,0x1d
    800041be:	95648493          	addi	s1,s1,-1706 # 80020b10 <log>
    800041c2:	8526                	mv	a0,s1
    800041c4:	ffffd097          	auipc	ra,0xffffd
    800041c8:	a5e080e7          	jalr	-1442(ra) # 80000c22 <acquire>
  log.outstanding -= 1;
    800041cc:	509c                	lw	a5,32(s1)
    800041ce:	37fd                	addiw	a5,a5,-1
    800041d0:	0007891b          	sext.w	s2,a5
    800041d4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041d6:	50dc                	lw	a5,36(s1)
    800041d8:	e7b9                	bnez	a5,80004226 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041da:	04091e63          	bnez	s2,80004236 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800041de:	0001d497          	auipc	s1,0x1d
    800041e2:	93248493          	addi	s1,s1,-1742 # 80020b10 <log>
    800041e6:	4785                	li	a5,1
    800041e8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041ea:	8526                	mv	a0,s1
    800041ec:	ffffd097          	auipc	ra,0xffffd
    800041f0:	aea080e7          	jalr	-1302(ra) # 80000cd6 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041f4:	54dc                	lw	a5,44(s1)
    800041f6:	06f04763          	bgtz	a5,80004264 <end_op+0xbc>
    acquire(&log.lock);
    800041fa:	0001d497          	auipc	s1,0x1d
    800041fe:	91648493          	addi	s1,s1,-1770 # 80020b10 <log>
    80004202:	8526                	mv	a0,s1
    80004204:	ffffd097          	auipc	ra,0xffffd
    80004208:	a1e080e7          	jalr	-1506(ra) # 80000c22 <acquire>
    log.committing = 0;
    8000420c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004210:	8526                	mv	a0,s1
    80004212:	ffffe097          	auipc	ra,0xffffe
    80004216:	ef2080e7          	jalr	-270(ra) # 80002104 <wakeup>
    release(&log.lock);
    8000421a:	8526                	mv	a0,s1
    8000421c:	ffffd097          	auipc	ra,0xffffd
    80004220:	aba080e7          	jalr	-1350(ra) # 80000cd6 <release>
}
    80004224:	a03d                	j	80004252 <end_op+0xaa>
    panic("log.committing");
    80004226:	00004517          	auipc	a0,0x4
    8000422a:	41250513          	addi	a0,a0,1042 # 80008638 <syscalls+0x1e8>
    8000422e:	ffffc097          	auipc	ra,0xffffc
    80004232:	310080e7          	jalr	784(ra) # 8000053e <panic>
    wakeup(&log);
    80004236:	0001d497          	auipc	s1,0x1d
    8000423a:	8da48493          	addi	s1,s1,-1830 # 80020b10 <log>
    8000423e:	8526                	mv	a0,s1
    80004240:	ffffe097          	auipc	ra,0xffffe
    80004244:	ec4080e7          	jalr	-316(ra) # 80002104 <wakeup>
  release(&log.lock);
    80004248:	8526                	mv	a0,s1
    8000424a:	ffffd097          	auipc	ra,0xffffd
    8000424e:	a8c080e7          	jalr	-1396(ra) # 80000cd6 <release>
}
    80004252:	70e2                	ld	ra,56(sp)
    80004254:	7442                	ld	s0,48(sp)
    80004256:	74a2                	ld	s1,40(sp)
    80004258:	7902                	ld	s2,32(sp)
    8000425a:	69e2                	ld	s3,24(sp)
    8000425c:	6a42                	ld	s4,16(sp)
    8000425e:	6aa2                	ld	s5,8(sp)
    80004260:	6121                	addi	sp,sp,64
    80004262:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004264:	0001da97          	auipc	s5,0x1d
    80004268:	8dca8a93          	addi	s5,s5,-1828 # 80020b40 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000426c:	0001da17          	auipc	s4,0x1d
    80004270:	8a4a0a13          	addi	s4,s4,-1884 # 80020b10 <log>
    80004274:	018a2583          	lw	a1,24(s4)
    80004278:	012585bb          	addw	a1,a1,s2
    8000427c:	2585                	addiw	a1,a1,1
    8000427e:	028a2503          	lw	a0,40(s4)
    80004282:	fffff097          	auipc	ra,0xfffff
    80004286:	cca080e7          	jalr	-822(ra) # 80002f4c <bread>
    8000428a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000428c:	000aa583          	lw	a1,0(s5)
    80004290:	028a2503          	lw	a0,40(s4)
    80004294:	fffff097          	auipc	ra,0xfffff
    80004298:	cb8080e7          	jalr	-840(ra) # 80002f4c <bread>
    8000429c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000429e:	40000613          	li	a2,1024
    800042a2:	05850593          	addi	a1,a0,88
    800042a6:	05848513          	addi	a0,s1,88
    800042aa:	ffffd097          	auipc	ra,0xffffd
    800042ae:	ad0080e7          	jalr	-1328(ra) # 80000d7a <memmove>
    bwrite(to);  // write the log
    800042b2:	8526                	mv	a0,s1
    800042b4:	fffff097          	auipc	ra,0xfffff
    800042b8:	d8a080e7          	jalr	-630(ra) # 8000303e <bwrite>
    brelse(from);
    800042bc:	854e                	mv	a0,s3
    800042be:	fffff097          	auipc	ra,0xfffff
    800042c2:	dbe080e7          	jalr	-578(ra) # 8000307c <brelse>
    brelse(to);
    800042c6:	8526                	mv	a0,s1
    800042c8:	fffff097          	auipc	ra,0xfffff
    800042cc:	db4080e7          	jalr	-588(ra) # 8000307c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042d0:	2905                	addiw	s2,s2,1
    800042d2:	0a91                	addi	s5,s5,4
    800042d4:	02ca2783          	lw	a5,44(s4)
    800042d8:	f8f94ee3          	blt	s2,a5,80004274 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042dc:	00000097          	auipc	ra,0x0
    800042e0:	c6a080e7          	jalr	-918(ra) # 80003f46 <write_head>
    install_trans(0); // Now install writes to home locations
    800042e4:	4501                	li	a0,0
    800042e6:	00000097          	auipc	ra,0x0
    800042ea:	cda080e7          	jalr	-806(ra) # 80003fc0 <install_trans>
    log.lh.n = 0;
    800042ee:	0001d797          	auipc	a5,0x1d
    800042f2:	8407a723          	sw	zero,-1970(a5) # 80020b3c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042f6:	00000097          	auipc	ra,0x0
    800042fa:	c50080e7          	jalr	-944(ra) # 80003f46 <write_head>
    800042fe:	bdf5                	j	800041fa <end_op+0x52>

0000000080004300 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004300:	1101                	addi	sp,sp,-32
    80004302:	ec06                	sd	ra,24(sp)
    80004304:	e822                	sd	s0,16(sp)
    80004306:	e426                	sd	s1,8(sp)
    80004308:	e04a                	sd	s2,0(sp)
    8000430a:	1000                	addi	s0,sp,32
    8000430c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000430e:	0001d917          	auipc	s2,0x1d
    80004312:	80290913          	addi	s2,s2,-2046 # 80020b10 <log>
    80004316:	854a                	mv	a0,s2
    80004318:	ffffd097          	auipc	ra,0xffffd
    8000431c:	90a080e7          	jalr	-1782(ra) # 80000c22 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004320:	02c92603          	lw	a2,44(s2)
    80004324:	47f5                	li	a5,29
    80004326:	06c7c563          	blt	a5,a2,80004390 <log_write+0x90>
    8000432a:	0001d797          	auipc	a5,0x1d
    8000432e:	8027a783          	lw	a5,-2046(a5) # 80020b2c <log+0x1c>
    80004332:	37fd                	addiw	a5,a5,-1
    80004334:	04f65e63          	bge	a2,a5,80004390 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004338:	0001c797          	auipc	a5,0x1c
    8000433c:	7f87a783          	lw	a5,2040(a5) # 80020b30 <log+0x20>
    80004340:	06f05063          	blez	a5,800043a0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004344:	4781                	li	a5,0
    80004346:	06c05563          	blez	a2,800043b0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000434a:	44cc                	lw	a1,12(s1)
    8000434c:	0001c717          	auipc	a4,0x1c
    80004350:	7f470713          	addi	a4,a4,2036 # 80020b40 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004354:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004356:	4314                	lw	a3,0(a4)
    80004358:	04b68c63          	beq	a3,a1,800043b0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000435c:	2785                	addiw	a5,a5,1
    8000435e:	0711                	addi	a4,a4,4
    80004360:	fef61be3          	bne	a2,a5,80004356 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004364:	0621                	addi	a2,a2,8
    80004366:	060a                	slli	a2,a2,0x2
    80004368:	0001c797          	auipc	a5,0x1c
    8000436c:	7a878793          	addi	a5,a5,1960 # 80020b10 <log>
    80004370:	963e                	add	a2,a2,a5
    80004372:	44dc                	lw	a5,12(s1)
    80004374:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004376:	8526                	mv	a0,s1
    80004378:	fffff097          	auipc	ra,0xfffff
    8000437c:	da2080e7          	jalr	-606(ra) # 8000311a <bpin>
    log.lh.n++;
    80004380:	0001c717          	auipc	a4,0x1c
    80004384:	79070713          	addi	a4,a4,1936 # 80020b10 <log>
    80004388:	575c                	lw	a5,44(a4)
    8000438a:	2785                	addiw	a5,a5,1
    8000438c:	d75c                	sw	a5,44(a4)
    8000438e:	a835                	j	800043ca <log_write+0xca>
    panic("too big a transaction");
    80004390:	00004517          	auipc	a0,0x4
    80004394:	2b850513          	addi	a0,a0,696 # 80008648 <syscalls+0x1f8>
    80004398:	ffffc097          	auipc	ra,0xffffc
    8000439c:	1a6080e7          	jalr	422(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800043a0:	00004517          	auipc	a0,0x4
    800043a4:	2c050513          	addi	a0,a0,704 # 80008660 <syscalls+0x210>
    800043a8:	ffffc097          	auipc	ra,0xffffc
    800043ac:	196080e7          	jalr	406(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800043b0:	00878713          	addi	a4,a5,8
    800043b4:	00271693          	slli	a3,a4,0x2
    800043b8:	0001c717          	auipc	a4,0x1c
    800043bc:	75870713          	addi	a4,a4,1880 # 80020b10 <log>
    800043c0:	9736                	add	a4,a4,a3
    800043c2:	44d4                	lw	a3,12(s1)
    800043c4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043c6:	faf608e3          	beq	a2,a5,80004376 <log_write+0x76>
  }
  release(&log.lock);
    800043ca:	0001c517          	auipc	a0,0x1c
    800043ce:	74650513          	addi	a0,a0,1862 # 80020b10 <log>
    800043d2:	ffffd097          	auipc	ra,0xffffd
    800043d6:	904080e7          	jalr	-1788(ra) # 80000cd6 <release>
}
    800043da:	60e2                	ld	ra,24(sp)
    800043dc:	6442                	ld	s0,16(sp)
    800043de:	64a2                	ld	s1,8(sp)
    800043e0:	6902                	ld	s2,0(sp)
    800043e2:	6105                	addi	sp,sp,32
    800043e4:	8082                	ret

00000000800043e6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043e6:	1101                	addi	sp,sp,-32
    800043e8:	ec06                	sd	ra,24(sp)
    800043ea:	e822                	sd	s0,16(sp)
    800043ec:	e426                	sd	s1,8(sp)
    800043ee:	e04a                	sd	s2,0(sp)
    800043f0:	1000                	addi	s0,sp,32
    800043f2:	84aa                	mv	s1,a0
    800043f4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043f6:	00004597          	auipc	a1,0x4
    800043fa:	28a58593          	addi	a1,a1,650 # 80008680 <syscalls+0x230>
    800043fe:	0521                	addi	a0,a0,8
    80004400:	ffffc097          	auipc	ra,0xffffc
    80004404:	792080e7          	jalr	1938(ra) # 80000b92 <initlock>
  lk->name = name;
    80004408:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000440c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004410:	0204a423          	sw	zero,40(s1)
}
    80004414:	60e2                	ld	ra,24(sp)
    80004416:	6442                	ld	s0,16(sp)
    80004418:	64a2                	ld	s1,8(sp)
    8000441a:	6902                	ld	s2,0(sp)
    8000441c:	6105                	addi	sp,sp,32
    8000441e:	8082                	ret

0000000080004420 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004420:	1101                	addi	sp,sp,-32
    80004422:	ec06                	sd	ra,24(sp)
    80004424:	e822                	sd	s0,16(sp)
    80004426:	e426                	sd	s1,8(sp)
    80004428:	e04a                	sd	s2,0(sp)
    8000442a:	1000                	addi	s0,sp,32
    8000442c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000442e:	00850913          	addi	s2,a0,8
    80004432:	854a                	mv	a0,s2
    80004434:	ffffc097          	auipc	ra,0xffffc
    80004438:	7ee080e7          	jalr	2030(ra) # 80000c22 <acquire>
  while (lk->locked) {
    8000443c:	409c                	lw	a5,0(s1)
    8000443e:	cb89                	beqz	a5,80004450 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004440:	85ca                	mv	a1,s2
    80004442:	8526                	mv	a0,s1
    80004444:	ffffe097          	auipc	ra,0xffffe
    80004448:	c5c080e7          	jalr	-932(ra) # 800020a0 <sleep>
  while (lk->locked) {
    8000444c:	409c                	lw	a5,0(s1)
    8000444e:	fbed                	bnez	a5,80004440 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004450:	4785                	li	a5,1
    80004452:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004454:	ffffd097          	auipc	ra,0xffffd
    80004458:	5a4080e7          	jalr	1444(ra) # 800019f8 <myproc>
    8000445c:	591c                	lw	a5,48(a0)
    8000445e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004460:	854a                	mv	a0,s2
    80004462:	ffffd097          	auipc	ra,0xffffd
    80004466:	874080e7          	jalr	-1932(ra) # 80000cd6 <release>
}
    8000446a:	60e2                	ld	ra,24(sp)
    8000446c:	6442                	ld	s0,16(sp)
    8000446e:	64a2                	ld	s1,8(sp)
    80004470:	6902                	ld	s2,0(sp)
    80004472:	6105                	addi	sp,sp,32
    80004474:	8082                	ret

0000000080004476 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004476:	1101                	addi	sp,sp,-32
    80004478:	ec06                	sd	ra,24(sp)
    8000447a:	e822                	sd	s0,16(sp)
    8000447c:	e426                	sd	s1,8(sp)
    8000447e:	e04a                	sd	s2,0(sp)
    80004480:	1000                	addi	s0,sp,32
    80004482:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004484:	00850913          	addi	s2,a0,8
    80004488:	854a                	mv	a0,s2
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	798080e7          	jalr	1944(ra) # 80000c22 <acquire>
  lk->locked = 0;
    80004492:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004496:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000449a:	8526                	mv	a0,s1
    8000449c:	ffffe097          	auipc	ra,0xffffe
    800044a0:	c68080e7          	jalr	-920(ra) # 80002104 <wakeup>
  release(&lk->lk);
    800044a4:	854a                	mv	a0,s2
    800044a6:	ffffd097          	auipc	ra,0xffffd
    800044aa:	830080e7          	jalr	-2000(ra) # 80000cd6 <release>
}
    800044ae:	60e2                	ld	ra,24(sp)
    800044b0:	6442                	ld	s0,16(sp)
    800044b2:	64a2                	ld	s1,8(sp)
    800044b4:	6902                	ld	s2,0(sp)
    800044b6:	6105                	addi	sp,sp,32
    800044b8:	8082                	ret

00000000800044ba <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044ba:	7179                	addi	sp,sp,-48
    800044bc:	f406                	sd	ra,40(sp)
    800044be:	f022                	sd	s0,32(sp)
    800044c0:	ec26                	sd	s1,24(sp)
    800044c2:	e84a                	sd	s2,16(sp)
    800044c4:	e44e                	sd	s3,8(sp)
    800044c6:	1800                	addi	s0,sp,48
    800044c8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044ca:	00850913          	addi	s2,a0,8
    800044ce:	854a                	mv	a0,s2
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	752080e7          	jalr	1874(ra) # 80000c22 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044d8:	409c                	lw	a5,0(s1)
    800044da:	ef99                	bnez	a5,800044f8 <holdingsleep+0x3e>
    800044dc:	4481                	li	s1,0
  release(&lk->lk);
    800044de:	854a                	mv	a0,s2
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	7f6080e7          	jalr	2038(ra) # 80000cd6 <release>
  return r;
}
    800044e8:	8526                	mv	a0,s1
    800044ea:	70a2                	ld	ra,40(sp)
    800044ec:	7402                	ld	s0,32(sp)
    800044ee:	64e2                	ld	s1,24(sp)
    800044f0:	6942                	ld	s2,16(sp)
    800044f2:	69a2                	ld	s3,8(sp)
    800044f4:	6145                	addi	sp,sp,48
    800044f6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044f8:	0284a983          	lw	s3,40(s1)
    800044fc:	ffffd097          	auipc	ra,0xffffd
    80004500:	4fc080e7          	jalr	1276(ra) # 800019f8 <myproc>
    80004504:	5904                	lw	s1,48(a0)
    80004506:	413484b3          	sub	s1,s1,s3
    8000450a:	0014b493          	seqz	s1,s1
    8000450e:	bfc1                	j	800044de <holdingsleep+0x24>

0000000080004510 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004510:	1141                	addi	sp,sp,-16
    80004512:	e406                	sd	ra,8(sp)
    80004514:	e022                	sd	s0,0(sp)
    80004516:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004518:	00004597          	auipc	a1,0x4
    8000451c:	17858593          	addi	a1,a1,376 # 80008690 <syscalls+0x240>
    80004520:	0001c517          	auipc	a0,0x1c
    80004524:	73850513          	addi	a0,a0,1848 # 80020c58 <ftable>
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	66a080e7          	jalr	1642(ra) # 80000b92 <initlock>
}
    80004530:	60a2                	ld	ra,8(sp)
    80004532:	6402                	ld	s0,0(sp)
    80004534:	0141                	addi	sp,sp,16
    80004536:	8082                	ret

0000000080004538 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004538:	1101                	addi	sp,sp,-32
    8000453a:	ec06                	sd	ra,24(sp)
    8000453c:	e822                	sd	s0,16(sp)
    8000453e:	e426                	sd	s1,8(sp)
    80004540:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004542:	0001c517          	auipc	a0,0x1c
    80004546:	71650513          	addi	a0,a0,1814 # 80020c58 <ftable>
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	6d8080e7          	jalr	1752(ra) # 80000c22 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004552:	0001c497          	auipc	s1,0x1c
    80004556:	71e48493          	addi	s1,s1,1822 # 80020c70 <ftable+0x18>
    8000455a:	0001d717          	auipc	a4,0x1d
    8000455e:	6b670713          	addi	a4,a4,1718 # 80021c10 <disk>
    if(f->ref == 0){
    80004562:	40dc                	lw	a5,4(s1)
    80004564:	cf99                	beqz	a5,80004582 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004566:	02848493          	addi	s1,s1,40
    8000456a:	fee49ce3          	bne	s1,a4,80004562 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000456e:	0001c517          	auipc	a0,0x1c
    80004572:	6ea50513          	addi	a0,a0,1770 # 80020c58 <ftable>
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	760080e7          	jalr	1888(ra) # 80000cd6 <release>
  return 0;
    8000457e:	4481                	li	s1,0
    80004580:	a819                	j	80004596 <filealloc+0x5e>
      f->ref = 1;
    80004582:	4785                	li	a5,1
    80004584:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004586:	0001c517          	auipc	a0,0x1c
    8000458a:	6d250513          	addi	a0,a0,1746 # 80020c58 <ftable>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	748080e7          	jalr	1864(ra) # 80000cd6 <release>
}
    80004596:	8526                	mv	a0,s1
    80004598:	60e2                	ld	ra,24(sp)
    8000459a:	6442                	ld	s0,16(sp)
    8000459c:	64a2                	ld	s1,8(sp)
    8000459e:	6105                	addi	sp,sp,32
    800045a0:	8082                	ret

00000000800045a2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045a2:	1101                	addi	sp,sp,-32
    800045a4:	ec06                	sd	ra,24(sp)
    800045a6:	e822                	sd	s0,16(sp)
    800045a8:	e426                	sd	s1,8(sp)
    800045aa:	1000                	addi	s0,sp,32
    800045ac:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045ae:	0001c517          	auipc	a0,0x1c
    800045b2:	6aa50513          	addi	a0,a0,1706 # 80020c58 <ftable>
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	66c080e7          	jalr	1644(ra) # 80000c22 <acquire>
  if(f->ref < 1)
    800045be:	40dc                	lw	a5,4(s1)
    800045c0:	02f05263          	blez	a5,800045e4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045c4:	2785                	addiw	a5,a5,1
    800045c6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045c8:	0001c517          	auipc	a0,0x1c
    800045cc:	69050513          	addi	a0,a0,1680 # 80020c58 <ftable>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	706080e7          	jalr	1798(ra) # 80000cd6 <release>
  return f;
}
    800045d8:	8526                	mv	a0,s1
    800045da:	60e2                	ld	ra,24(sp)
    800045dc:	6442                	ld	s0,16(sp)
    800045de:	64a2                	ld	s1,8(sp)
    800045e0:	6105                	addi	sp,sp,32
    800045e2:	8082                	ret
    panic("filedup");
    800045e4:	00004517          	auipc	a0,0x4
    800045e8:	0b450513          	addi	a0,a0,180 # 80008698 <syscalls+0x248>
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	f52080e7          	jalr	-174(ra) # 8000053e <panic>

00000000800045f4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045f4:	7139                	addi	sp,sp,-64
    800045f6:	fc06                	sd	ra,56(sp)
    800045f8:	f822                	sd	s0,48(sp)
    800045fa:	f426                	sd	s1,40(sp)
    800045fc:	f04a                	sd	s2,32(sp)
    800045fe:	ec4e                	sd	s3,24(sp)
    80004600:	e852                	sd	s4,16(sp)
    80004602:	e456                	sd	s5,8(sp)
    80004604:	0080                	addi	s0,sp,64
    80004606:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004608:	0001c517          	auipc	a0,0x1c
    8000460c:	65050513          	addi	a0,a0,1616 # 80020c58 <ftable>
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	612080e7          	jalr	1554(ra) # 80000c22 <acquire>
  if(f->ref < 1)
    80004618:	40dc                	lw	a5,4(s1)
    8000461a:	06f05163          	blez	a5,8000467c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000461e:	37fd                	addiw	a5,a5,-1
    80004620:	0007871b          	sext.w	a4,a5
    80004624:	c0dc                	sw	a5,4(s1)
    80004626:	06e04363          	bgtz	a4,8000468c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000462a:	0004a903          	lw	s2,0(s1)
    8000462e:	0094ca83          	lbu	s5,9(s1)
    80004632:	0104ba03          	ld	s4,16(s1)
    80004636:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000463a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000463e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004642:	0001c517          	auipc	a0,0x1c
    80004646:	61650513          	addi	a0,a0,1558 # 80020c58 <ftable>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	68c080e7          	jalr	1676(ra) # 80000cd6 <release>

  if(ff.type == FD_PIPE){
    80004652:	4785                	li	a5,1
    80004654:	04f90d63          	beq	s2,a5,800046ae <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004658:	3979                	addiw	s2,s2,-2
    8000465a:	4785                	li	a5,1
    8000465c:	0527e063          	bltu	a5,s2,8000469c <fileclose+0xa8>
    begin_op();
    80004660:	00000097          	auipc	ra,0x0
    80004664:	ac8080e7          	jalr	-1336(ra) # 80004128 <begin_op>
    iput(ff.ip);
    80004668:	854e                	mv	a0,s3
    8000466a:	fffff097          	auipc	ra,0xfffff
    8000466e:	2b6080e7          	jalr	694(ra) # 80003920 <iput>
    end_op();
    80004672:	00000097          	auipc	ra,0x0
    80004676:	b36080e7          	jalr	-1226(ra) # 800041a8 <end_op>
    8000467a:	a00d                	j	8000469c <fileclose+0xa8>
    panic("fileclose");
    8000467c:	00004517          	auipc	a0,0x4
    80004680:	02450513          	addi	a0,a0,36 # 800086a0 <syscalls+0x250>
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	eba080e7          	jalr	-326(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000468c:	0001c517          	auipc	a0,0x1c
    80004690:	5cc50513          	addi	a0,a0,1484 # 80020c58 <ftable>
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	642080e7          	jalr	1602(ra) # 80000cd6 <release>
  }
}
    8000469c:	70e2                	ld	ra,56(sp)
    8000469e:	7442                	ld	s0,48(sp)
    800046a0:	74a2                	ld	s1,40(sp)
    800046a2:	7902                	ld	s2,32(sp)
    800046a4:	69e2                	ld	s3,24(sp)
    800046a6:	6a42                	ld	s4,16(sp)
    800046a8:	6aa2                	ld	s5,8(sp)
    800046aa:	6121                	addi	sp,sp,64
    800046ac:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046ae:	85d6                	mv	a1,s5
    800046b0:	8552                	mv	a0,s4
    800046b2:	00000097          	auipc	ra,0x0
    800046b6:	34c080e7          	jalr	844(ra) # 800049fe <pipeclose>
    800046ba:	b7cd                	j	8000469c <fileclose+0xa8>

00000000800046bc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046bc:	715d                	addi	sp,sp,-80
    800046be:	e486                	sd	ra,72(sp)
    800046c0:	e0a2                	sd	s0,64(sp)
    800046c2:	fc26                	sd	s1,56(sp)
    800046c4:	f84a                	sd	s2,48(sp)
    800046c6:	f44e                	sd	s3,40(sp)
    800046c8:	0880                	addi	s0,sp,80
    800046ca:	84aa                	mv	s1,a0
    800046cc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046ce:	ffffd097          	auipc	ra,0xffffd
    800046d2:	32a080e7          	jalr	810(ra) # 800019f8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046d6:	409c                	lw	a5,0(s1)
    800046d8:	37f9                	addiw	a5,a5,-2
    800046da:	4705                	li	a4,1
    800046dc:	04f76763          	bltu	a4,a5,8000472a <filestat+0x6e>
    800046e0:	892a                	mv	s2,a0
    ilock(f->ip);
    800046e2:	6c88                	ld	a0,24(s1)
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	082080e7          	jalr	130(ra) # 80003766 <ilock>
    stati(f->ip, &st);
    800046ec:	fb840593          	addi	a1,s0,-72
    800046f0:	6c88                	ld	a0,24(s1)
    800046f2:	fffff097          	auipc	ra,0xfffff
    800046f6:	2fe080e7          	jalr	766(ra) # 800039f0 <stati>
    iunlock(f->ip);
    800046fa:	6c88                	ld	a0,24(s1)
    800046fc:	fffff097          	auipc	ra,0xfffff
    80004700:	12c080e7          	jalr	300(ra) # 80003828 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004704:	46e1                	li	a3,24
    80004706:	fb840613          	addi	a2,s0,-72
    8000470a:	85ce                	mv	a1,s3
    8000470c:	05093503          	ld	a0,80(s2)
    80004710:	ffffd097          	auipc	ra,0xffffd
    80004714:	fa4080e7          	jalr	-92(ra) # 800016b4 <copyout>
    80004718:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000471c:	60a6                	ld	ra,72(sp)
    8000471e:	6406                	ld	s0,64(sp)
    80004720:	74e2                	ld	s1,56(sp)
    80004722:	7942                	ld	s2,48(sp)
    80004724:	79a2                	ld	s3,40(sp)
    80004726:	6161                	addi	sp,sp,80
    80004728:	8082                	ret
  return -1;
    8000472a:	557d                	li	a0,-1
    8000472c:	bfc5                	j	8000471c <filestat+0x60>

000000008000472e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000472e:	7179                	addi	sp,sp,-48
    80004730:	f406                	sd	ra,40(sp)
    80004732:	f022                	sd	s0,32(sp)
    80004734:	ec26                	sd	s1,24(sp)
    80004736:	e84a                	sd	s2,16(sp)
    80004738:	e44e                	sd	s3,8(sp)
    8000473a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000473c:	00854783          	lbu	a5,8(a0)
    80004740:	c3d5                	beqz	a5,800047e4 <fileread+0xb6>
    80004742:	84aa                	mv	s1,a0
    80004744:	89ae                	mv	s3,a1
    80004746:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004748:	411c                	lw	a5,0(a0)
    8000474a:	4705                	li	a4,1
    8000474c:	04e78963          	beq	a5,a4,8000479e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004750:	470d                	li	a4,3
    80004752:	04e78d63          	beq	a5,a4,800047ac <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004756:	4709                	li	a4,2
    80004758:	06e79e63          	bne	a5,a4,800047d4 <fileread+0xa6>
    ilock(f->ip);
    8000475c:	6d08                	ld	a0,24(a0)
    8000475e:	fffff097          	auipc	ra,0xfffff
    80004762:	008080e7          	jalr	8(ra) # 80003766 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004766:	874a                	mv	a4,s2
    80004768:	5094                	lw	a3,32(s1)
    8000476a:	864e                	mv	a2,s3
    8000476c:	4585                	li	a1,1
    8000476e:	6c88                	ld	a0,24(s1)
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	2aa080e7          	jalr	682(ra) # 80003a1a <readi>
    80004778:	892a                	mv	s2,a0
    8000477a:	00a05563          	blez	a0,80004784 <fileread+0x56>
      f->off += r;
    8000477e:	509c                	lw	a5,32(s1)
    80004780:	9fa9                	addw	a5,a5,a0
    80004782:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004784:	6c88                	ld	a0,24(s1)
    80004786:	fffff097          	auipc	ra,0xfffff
    8000478a:	0a2080e7          	jalr	162(ra) # 80003828 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000478e:	854a                	mv	a0,s2
    80004790:	70a2                	ld	ra,40(sp)
    80004792:	7402                	ld	s0,32(sp)
    80004794:	64e2                	ld	s1,24(sp)
    80004796:	6942                	ld	s2,16(sp)
    80004798:	69a2                	ld	s3,8(sp)
    8000479a:	6145                	addi	sp,sp,48
    8000479c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000479e:	6908                	ld	a0,16(a0)
    800047a0:	00000097          	auipc	ra,0x0
    800047a4:	3c6080e7          	jalr	966(ra) # 80004b66 <piperead>
    800047a8:	892a                	mv	s2,a0
    800047aa:	b7d5                	j	8000478e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047ac:	02451783          	lh	a5,36(a0)
    800047b0:	03079693          	slli	a3,a5,0x30
    800047b4:	92c1                	srli	a3,a3,0x30
    800047b6:	4725                	li	a4,9
    800047b8:	02d76863          	bltu	a4,a3,800047e8 <fileread+0xba>
    800047bc:	0792                	slli	a5,a5,0x4
    800047be:	0001c717          	auipc	a4,0x1c
    800047c2:	3fa70713          	addi	a4,a4,1018 # 80020bb8 <devsw>
    800047c6:	97ba                	add	a5,a5,a4
    800047c8:	639c                	ld	a5,0(a5)
    800047ca:	c38d                	beqz	a5,800047ec <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047cc:	4505                	li	a0,1
    800047ce:	9782                	jalr	a5
    800047d0:	892a                	mv	s2,a0
    800047d2:	bf75                	j	8000478e <fileread+0x60>
    panic("fileread");
    800047d4:	00004517          	auipc	a0,0x4
    800047d8:	edc50513          	addi	a0,a0,-292 # 800086b0 <syscalls+0x260>
    800047dc:	ffffc097          	auipc	ra,0xffffc
    800047e0:	d62080e7          	jalr	-670(ra) # 8000053e <panic>
    return -1;
    800047e4:	597d                	li	s2,-1
    800047e6:	b765                	j	8000478e <fileread+0x60>
      return -1;
    800047e8:	597d                	li	s2,-1
    800047ea:	b755                	j	8000478e <fileread+0x60>
    800047ec:	597d                	li	s2,-1
    800047ee:	b745                	j	8000478e <fileread+0x60>

00000000800047f0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047f0:	715d                	addi	sp,sp,-80
    800047f2:	e486                	sd	ra,72(sp)
    800047f4:	e0a2                	sd	s0,64(sp)
    800047f6:	fc26                	sd	s1,56(sp)
    800047f8:	f84a                	sd	s2,48(sp)
    800047fa:	f44e                	sd	s3,40(sp)
    800047fc:	f052                	sd	s4,32(sp)
    800047fe:	ec56                	sd	s5,24(sp)
    80004800:	e85a                	sd	s6,16(sp)
    80004802:	e45e                	sd	s7,8(sp)
    80004804:	e062                	sd	s8,0(sp)
    80004806:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004808:	00954783          	lbu	a5,9(a0)
    8000480c:	10078663          	beqz	a5,80004918 <filewrite+0x128>
    80004810:	892a                	mv	s2,a0
    80004812:	8aae                	mv	s5,a1
    80004814:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004816:	411c                	lw	a5,0(a0)
    80004818:	4705                	li	a4,1
    8000481a:	02e78263          	beq	a5,a4,8000483e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000481e:	470d                	li	a4,3
    80004820:	02e78663          	beq	a5,a4,8000484c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004824:	4709                	li	a4,2
    80004826:	0ee79163          	bne	a5,a4,80004908 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000482a:	0ac05d63          	blez	a2,800048e4 <filewrite+0xf4>
    int i = 0;
    8000482e:	4981                	li	s3,0
    80004830:	6b05                	lui	s6,0x1
    80004832:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004836:	6b85                	lui	s7,0x1
    80004838:	c00b8b9b          	addiw	s7,s7,-1024
    8000483c:	a861                	j	800048d4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000483e:	6908                	ld	a0,16(a0)
    80004840:	00000097          	auipc	ra,0x0
    80004844:	22e080e7          	jalr	558(ra) # 80004a6e <pipewrite>
    80004848:	8a2a                	mv	s4,a0
    8000484a:	a045                	j	800048ea <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000484c:	02451783          	lh	a5,36(a0)
    80004850:	03079693          	slli	a3,a5,0x30
    80004854:	92c1                	srli	a3,a3,0x30
    80004856:	4725                	li	a4,9
    80004858:	0cd76263          	bltu	a4,a3,8000491c <filewrite+0x12c>
    8000485c:	0792                	slli	a5,a5,0x4
    8000485e:	0001c717          	auipc	a4,0x1c
    80004862:	35a70713          	addi	a4,a4,858 # 80020bb8 <devsw>
    80004866:	97ba                	add	a5,a5,a4
    80004868:	679c                	ld	a5,8(a5)
    8000486a:	cbdd                	beqz	a5,80004920 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000486c:	4505                	li	a0,1
    8000486e:	9782                	jalr	a5
    80004870:	8a2a                	mv	s4,a0
    80004872:	a8a5                	j	800048ea <filewrite+0xfa>
    80004874:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	8b0080e7          	jalr	-1872(ra) # 80004128 <begin_op>
      ilock(f->ip);
    80004880:	01893503          	ld	a0,24(s2)
    80004884:	fffff097          	auipc	ra,0xfffff
    80004888:	ee2080e7          	jalr	-286(ra) # 80003766 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000488c:	8762                	mv	a4,s8
    8000488e:	02092683          	lw	a3,32(s2)
    80004892:	01598633          	add	a2,s3,s5
    80004896:	4585                	li	a1,1
    80004898:	01893503          	ld	a0,24(s2)
    8000489c:	fffff097          	auipc	ra,0xfffff
    800048a0:	276080e7          	jalr	630(ra) # 80003b12 <writei>
    800048a4:	84aa                	mv	s1,a0
    800048a6:	00a05763          	blez	a0,800048b4 <filewrite+0xc4>
        f->off += r;
    800048aa:	02092783          	lw	a5,32(s2)
    800048ae:	9fa9                	addw	a5,a5,a0
    800048b0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048b4:	01893503          	ld	a0,24(s2)
    800048b8:	fffff097          	auipc	ra,0xfffff
    800048bc:	f70080e7          	jalr	-144(ra) # 80003828 <iunlock>
      end_op();
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	8e8080e7          	jalr	-1816(ra) # 800041a8 <end_op>

      if(r != n1){
    800048c8:	009c1f63          	bne	s8,s1,800048e6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048cc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048d0:	0149db63          	bge	s3,s4,800048e6 <filewrite+0xf6>
      int n1 = n - i;
    800048d4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048d8:	84be                	mv	s1,a5
    800048da:	2781                	sext.w	a5,a5
    800048dc:	f8fb5ce3          	bge	s6,a5,80004874 <filewrite+0x84>
    800048e0:	84de                	mv	s1,s7
    800048e2:	bf49                	j	80004874 <filewrite+0x84>
    int i = 0;
    800048e4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048e6:	013a1f63          	bne	s4,s3,80004904 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048ea:	8552                	mv	a0,s4
    800048ec:	60a6                	ld	ra,72(sp)
    800048ee:	6406                	ld	s0,64(sp)
    800048f0:	74e2                	ld	s1,56(sp)
    800048f2:	7942                	ld	s2,48(sp)
    800048f4:	79a2                	ld	s3,40(sp)
    800048f6:	7a02                	ld	s4,32(sp)
    800048f8:	6ae2                	ld	s5,24(sp)
    800048fa:	6b42                	ld	s6,16(sp)
    800048fc:	6ba2                	ld	s7,8(sp)
    800048fe:	6c02                	ld	s8,0(sp)
    80004900:	6161                	addi	sp,sp,80
    80004902:	8082                	ret
    ret = (i == n ? n : -1);
    80004904:	5a7d                	li	s4,-1
    80004906:	b7d5                	j	800048ea <filewrite+0xfa>
    panic("filewrite");
    80004908:	00004517          	auipc	a0,0x4
    8000490c:	db850513          	addi	a0,a0,-584 # 800086c0 <syscalls+0x270>
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	c2e080e7          	jalr	-978(ra) # 8000053e <panic>
    return -1;
    80004918:	5a7d                	li	s4,-1
    8000491a:	bfc1                	j	800048ea <filewrite+0xfa>
      return -1;
    8000491c:	5a7d                	li	s4,-1
    8000491e:	b7f1                	j	800048ea <filewrite+0xfa>
    80004920:	5a7d                	li	s4,-1
    80004922:	b7e1                	j	800048ea <filewrite+0xfa>

0000000080004924 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004924:	7179                	addi	sp,sp,-48
    80004926:	f406                	sd	ra,40(sp)
    80004928:	f022                	sd	s0,32(sp)
    8000492a:	ec26                	sd	s1,24(sp)
    8000492c:	e84a                	sd	s2,16(sp)
    8000492e:	e44e                	sd	s3,8(sp)
    80004930:	e052                	sd	s4,0(sp)
    80004932:	1800                	addi	s0,sp,48
    80004934:	84aa                	mv	s1,a0
    80004936:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004938:	0005b023          	sd	zero,0(a1)
    8000493c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004940:	00000097          	auipc	ra,0x0
    80004944:	bf8080e7          	jalr	-1032(ra) # 80004538 <filealloc>
    80004948:	e088                	sd	a0,0(s1)
    8000494a:	c551                	beqz	a0,800049d6 <pipealloc+0xb2>
    8000494c:	00000097          	auipc	ra,0x0
    80004950:	bec080e7          	jalr	-1044(ra) # 80004538 <filealloc>
    80004954:	00aa3023          	sd	a0,0(s4)
    80004958:	c92d                	beqz	a0,800049ca <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000495a:	ffffc097          	auipc	ra,0xffffc
    8000495e:	18c080e7          	jalr	396(ra) # 80000ae6 <kalloc>
    80004962:	892a                	mv	s2,a0
    80004964:	c125                	beqz	a0,800049c4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004966:	4985                	li	s3,1
    80004968:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000496c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004970:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004974:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004978:	00004597          	auipc	a1,0x4
    8000497c:	d5858593          	addi	a1,a1,-680 # 800086d0 <syscalls+0x280>
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	212080e7          	jalr	530(ra) # 80000b92 <initlock>
  (*f0)->type = FD_PIPE;
    80004988:	609c                	ld	a5,0(s1)
    8000498a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000498e:	609c                	ld	a5,0(s1)
    80004990:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004994:	609c                	ld	a5,0(s1)
    80004996:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000499a:	609c                	ld	a5,0(s1)
    8000499c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049a0:	000a3783          	ld	a5,0(s4)
    800049a4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049a8:	000a3783          	ld	a5,0(s4)
    800049ac:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049b0:	000a3783          	ld	a5,0(s4)
    800049b4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049b8:	000a3783          	ld	a5,0(s4)
    800049bc:	0127b823          	sd	s2,16(a5)
  return 0;
    800049c0:	4501                	li	a0,0
    800049c2:	a025                	j	800049ea <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049c4:	6088                	ld	a0,0(s1)
    800049c6:	e501                	bnez	a0,800049ce <pipealloc+0xaa>
    800049c8:	a039                	j	800049d6 <pipealloc+0xb2>
    800049ca:	6088                	ld	a0,0(s1)
    800049cc:	c51d                	beqz	a0,800049fa <pipealloc+0xd6>
    fileclose(*f0);
    800049ce:	00000097          	auipc	ra,0x0
    800049d2:	c26080e7          	jalr	-986(ra) # 800045f4 <fileclose>
  if(*f1)
    800049d6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049da:	557d                	li	a0,-1
  if(*f1)
    800049dc:	c799                	beqz	a5,800049ea <pipealloc+0xc6>
    fileclose(*f1);
    800049de:	853e                	mv	a0,a5
    800049e0:	00000097          	auipc	ra,0x0
    800049e4:	c14080e7          	jalr	-1004(ra) # 800045f4 <fileclose>
  return -1;
    800049e8:	557d                	li	a0,-1
}
    800049ea:	70a2                	ld	ra,40(sp)
    800049ec:	7402                	ld	s0,32(sp)
    800049ee:	64e2                	ld	s1,24(sp)
    800049f0:	6942                	ld	s2,16(sp)
    800049f2:	69a2                	ld	s3,8(sp)
    800049f4:	6a02                	ld	s4,0(sp)
    800049f6:	6145                	addi	sp,sp,48
    800049f8:	8082                	ret
  return -1;
    800049fa:	557d                	li	a0,-1
    800049fc:	b7fd                	j	800049ea <pipealloc+0xc6>

00000000800049fe <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049fe:	1101                	addi	sp,sp,-32
    80004a00:	ec06                	sd	ra,24(sp)
    80004a02:	e822                	sd	s0,16(sp)
    80004a04:	e426                	sd	s1,8(sp)
    80004a06:	e04a                	sd	s2,0(sp)
    80004a08:	1000                	addi	s0,sp,32
    80004a0a:	84aa                	mv	s1,a0
    80004a0c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	214080e7          	jalr	532(ra) # 80000c22 <acquire>
  if(writable){
    80004a16:	02090d63          	beqz	s2,80004a50 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a1a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a1e:	21848513          	addi	a0,s1,536
    80004a22:	ffffd097          	auipc	ra,0xffffd
    80004a26:	6e2080e7          	jalr	1762(ra) # 80002104 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a2a:	2204b783          	ld	a5,544(s1)
    80004a2e:	eb95                	bnez	a5,80004a62 <pipeclose+0x64>
    release(&pi->lock);
    80004a30:	8526                	mv	a0,s1
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	2a4080e7          	jalr	676(ra) # 80000cd6 <release>
    kfree((char*)pi);
    80004a3a:	8526                	mv	a0,s1
    80004a3c:	ffffc097          	auipc	ra,0xffffc
    80004a40:	fae080e7          	jalr	-82(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004a44:	60e2                	ld	ra,24(sp)
    80004a46:	6442                	ld	s0,16(sp)
    80004a48:	64a2                	ld	s1,8(sp)
    80004a4a:	6902                	ld	s2,0(sp)
    80004a4c:	6105                	addi	sp,sp,32
    80004a4e:	8082                	ret
    pi->readopen = 0;
    80004a50:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a54:	21c48513          	addi	a0,s1,540
    80004a58:	ffffd097          	auipc	ra,0xffffd
    80004a5c:	6ac080e7          	jalr	1708(ra) # 80002104 <wakeup>
    80004a60:	b7e9                	j	80004a2a <pipeclose+0x2c>
    release(&pi->lock);
    80004a62:	8526                	mv	a0,s1
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	272080e7          	jalr	626(ra) # 80000cd6 <release>
}
    80004a6c:	bfe1                	j	80004a44 <pipeclose+0x46>

0000000080004a6e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a6e:	711d                	addi	sp,sp,-96
    80004a70:	ec86                	sd	ra,88(sp)
    80004a72:	e8a2                	sd	s0,80(sp)
    80004a74:	e4a6                	sd	s1,72(sp)
    80004a76:	e0ca                	sd	s2,64(sp)
    80004a78:	fc4e                	sd	s3,56(sp)
    80004a7a:	f852                	sd	s4,48(sp)
    80004a7c:	f456                	sd	s5,40(sp)
    80004a7e:	f05a                	sd	s6,32(sp)
    80004a80:	ec5e                	sd	s7,24(sp)
    80004a82:	e862                	sd	s8,16(sp)
    80004a84:	1080                	addi	s0,sp,96
    80004a86:	84aa                	mv	s1,a0
    80004a88:	8aae                	mv	s5,a1
    80004a8a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a8c:	ffffd097          	auipc	ra,0xffffd
    80004a90:	f6c080e7          	jalr	-148(ra) # 800019f8 <myproc>
    80004a94:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a96:	8526                	mv	a0,s1
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	18a080e7          	jalr	394(ra) # 80000c22 <acquire>
  while(i < n){
    80004aa0:	0b405663          	blez	s4,80004b4c <pipewrite+0xde>
  int i = 0;
    80004aa4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aa6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004aa8:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004aac:	21c48b93          	addi	s7,s1,540
    80004ab0:	a089                	j	80004af2 <pipewrite+0x84>
      release(&pi->lock);
    80004ab2:	8526                	mv	a0,s1
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	222080e7          	jalr	546(ra) # 80000cd6 <release>
      return -1;
    80004abc:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004abe:	854a                	mv	a0,s2
    80004ac0:	60e6                	ld	ra,88(sp)
    80004ac2:	6446                	ld	s0,80(sp)
    80004ac4:	64a6                	ld	s1,72(sp)
    80004ac6:	6906                	ld	s2,64(sp)
    80004ac8:	79e2                	ld	s3,56(sp)
    80004aca:	7a42                	ld	s4,48(sp)
    80004acc:	7aa2                	ld	s5,40(sp)
    80004ace:	7b02                	ld	s6,32(sp)
    80004ad0:	6be2                	ld	s7,24(sp)
    80004ad2:	6c42                	ld	s8,16(sp)
    80004ad4:	6125                	addi	sp,sp,96
    80004ad6:	8082                	ret
      wakeup(&pi->nread);
    80004ad8:	8562                	mv	a0,s8
    80004ada:	ffffd097          	auipc	ra,0xffffd
    80004ade:	62a080e7          	jalr	1578(ra) # 80002104 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ae2:	85a6                	mv	a1,s1
    80004ae4:	855e                	mv	a0,s7
    80004ae6:	ffffd097          	auipc	ra,0xffffd
    80004aea:	5ba080e7          	jalr	1466(ra) # 800020a0 <sleep>
  while(i < n){
    80004aee:	07495063          	bge	s2,s4,80004b4e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004af2:	2204a783          	lw	a5,544(s1)
    80004af6:	dfd5                	beqz	a5,80004ab2 <pipewrite+0x44>
    80004af8:	854e                	mv	a0,s3
    80004afa:	ffffe097          	auipc	ra,0xffffe
    80004afe:	84e080e7          	jalr	-1970(ra) # 80002348 <killed>
    80004b02:	f945                	bnez	a0,80004ab2 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b04:	2184a783          	lw	a5,536(s1)
    80004b08:	21c4a703          	lw	a4,540(s1)
    80004b0c:	2007879b          	addiw	a5,a5,512
    80004b10:	fcf704e3          	beq	a4,a5,80004ad8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b14:	4685                	li	a3,1
    80004b16:	01590633          	add	a2,s2,s5
    80004b1a:	faf40593          	addi	a1,s0,-81
    80004b1e:	0509b503          	ld	a0,80(s3)
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	c1e080e7          	jalr	-994(ra) # 80001740 <copyin>
    80004b2a:	03650263          	beq	a0,s6,80004b4e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b2e:	21c4a783          	lw	a5,540(s1)
    80004b32:	0017871b          	addiw	a4,a5,1
    80004b36:	20e4ae23          	sw	a4,540(s1)
    80004b3a:	1ff7f793          	andi	a5,a5,511
    80004b3e:	97a6                	add	a5,a5,s1
    80004b40:	faf44703          	lbu	a4,-81(s0)
    80004b44:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b48:	2905                	addiw	s2,s2,1
    80004b4a:	b755                	j	80004aee <pipewrite+0x80>
  int i = 0;
    80004b4c:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b4e:	21848513          	addi	a0,s1,536
    80004b52:	ffffd097          	auipc	ra,0xffffd
    80004b56:	5b2080e7          	jalr	1458(ra) # 80002104 <wakeup>
  release(&pi->lock);
    80004b5a:	8526                	mv	a0,s1
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	17a080e7          	jalr	378(ra) # 80000cd6 <release>
  return i;
    80004b64:	bfa9                	j	80004abe <pipewrite+0x50>

0000000080004b66 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b66:	715d                	addi	sp,sp,-80
    80004b68:	e486                	sd	ra,72(sp)
    80004b6a:	e0a2                	sd	s0,64(sp)
    80004b6c:	fc26                	sd	s1,56(sp)
    80004b6e:	f84a                	sd	s2,48(sp)
    80004b70:	f44e                	sd	s3,40(sp)
    80004b72:	f052                	sd	s4,32(sp)
    80004b74:	ec56                	sd	s5,24(sp)
    80004b76:	e85a                	sd	s6,16(sp)
    80004b78:	0880                	addi	s0,sp,80
    80004b7a:	84aa                	mv	s1,a0
    80004b7c:	892e                	mv	s2,a1
    80004b7e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b80:	ffffd097          	auipc	ra,0xffffd
    80004b84:	e78080e7          	jalr	-392(ra) # 800019f8 <myproc>
    80004b88:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b8a:	8526                	mv	a0,s1
    80004b8c:	ffffc097          	auipc	ra,0xffffc
    80004b90:	096080e7          	jalr	150(ra) # 80000c22 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b94:	2184a703          	lw	a4,536(s1)
    80004b98:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b9c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ba0:	02f71763          	bne	a4,a5,80004bce <piperead+0x68>
    80004ba4:	2244a783          	lw	a5,548(s1)
    80004ba8:	c39d                	beqz	a5,80004bce <piperead+0x68>
    if(killed(pr)){
    80004baa:	8552                	mv	a0,s4
    80004bac:	ffffd097          	auipc	ra,0xffffd
    80004bb0:	79c080e7          	jalr	1948(ra) # 80002348 <killed>
    80004bb4:	e941                	bnez	a0,80004c44 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bb6:	85a6                	mv	a1,s1
    80004bb8:	854e                	mv	a0,s3
    80004bba:	ffffd097          	auipc	ra,0xffffd
    80004bbe:	4e6080e7          	jalr	1254(ra) # 800020a0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bc2:	2184a703          	lw	a4,536(s1)
    80004bc6:	21c4a783          	lw	a5,540(s1)
    80004bca:	fcf70de3          	beq	a4,a5,80004ba4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bce:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bd0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bd2:	05505363          	blez	s5,80004c18 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004bd6:	2184a783          	lw	a5,536(s1)
    80004bda:	21c4a703          	lw	a4,540(s1)
    80004bde:	02f70d63          	beq	a4,a5,80004c18 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004be2:	0017871b          	addiw	a4,a5,1
    80004be6:	20e4ac23          	sw	a4,536(s1)
    80004bea:	1ff7f793          	andi	a5,a5,511
    80004bee:	97a6                	add	a5,a5,s1
    80004bf0:	0187c783          	lbu	a5,24(a5)
    80004bf4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bf8:	4685                	li	a3,1
    80004bfa:	fbf40613          	addi	a2,s0,-65
    80004bfe:	85ca                	mv	a1,s2
    80004c00:	050a3503          	ld	a0,80(s4)
    80004c04:	ffffd097          	auipc	ra,0xffffd
    80004c08:	ab0080e7          	jalr	-1360(ra) # 800016b4 <copyout>
    80004c0c:	01650663          	beq	a0,s6,80004c18 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c10:	2985                	addiw	s3,s3,1
    80004c12:	0905                	addi	s2,s2,1
    80004c14:	fd3a91e3          	bne	s5,s3,80004bd6 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c18:	21c48513          	addi	a0,s1,540
    80004c1c:	ffffd097          	auipc	ra,0xffffd
    80004c20:	4e8080e7          	jalr	1256(ra) # 80002104 <wakeup>
  release(&pi->lock);
    80004c24:	8526                	mv	a0,s1
    80004c26:	ffffc097          	auipc	ra,0xffffc
    80004c2a:	0b0080e7          	jalr	176(ra) # 80000cd6 <release>
  return i;
}
    80004c2e:	854e                	mv	a0,s3
    80004c30:	60a6                	ld	ra,72(sp)
    80004c32:	6406                	ld	s0,64(sp)
    80004c34:	74e2                	ld	s1,56(sp)
    80004c36:	7942                	ld	s2,48(sp)
    80004c38:	79a2                	ld	s3,40(sp)
    80004c3a:	7a02                	ld	s4,32(sp)
    80004c3c:	6ae2                	ld	s5,24(sp)
    80004c3e:	6b42                	ld	s6,16(sp)
    80004c40:	6161                	addi	sp,sp,80
    80004c42:	8082                	ret
      release(&pi->lock);
    80004c44:	8526                	mv	a0,s1
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	090080e7          	jalr	144(ra) # 80000cd6 <release>
      return -1;
    80004c4e:	59fd                	li	s3,-1
    80004c50:	bff9                	j	80004c2e <piperead+0xc8>

0000000080004c52 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c52:	1141                	addi	sp,sp,-16
    80004c54:	e422                	sd	s0,8(sp)
    80004c56:	0800                	addi	s0,sp,16
    80004c58:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c5a:	8905                	andi	a0,a0,1
    80004c5c:	c111                	beqz	a0,80004c60 <flags2perm+0xe>
      perm = PTE_X;
    80004c5e:	4521                	li	a0,8
    if(flags & 0x2)
    80004c60:	8b89                	andi	a5,a5,2
    80004c62:	c399                	beqz	a5,80004c68 <flags2perm+0x16>
      perm |= PTE_W;
    80004c64:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c68:	6422                	ld	s0,8(sp)
    80004c6a:	0141                	addi	sp,sp,16
    80004c6c:	8082                	ret

0000000080004c6e <exec>:

int
exec(char *path, char **argv)
{
    80004c6e:	de010113          	addi	sp,sp,-544
    80004c72:	20113c23          	sd	ra,536(sp)
    80004c76:	20813823          	sd	s0,528(sp)
    80004c7a:	20913423          	sd	s1,520(sp)
    80004c7e:	21213023          	sd	s2,512(sp)
    80004c82:	ffce                	sd	s3,504(sp)
    80004c84:	fbd2                	sd	s4,496(sp)
    80004c86:	f7d6                	sd	s5,488(sp)
    80004c88:	f3da                	sd	s6,480(sp)
    80004c8a:	efde                	sd	s7,472(sp)
    80004c8c:	ebe2                	sd	s8,464(sp)
    80004c8e:	e7e6                	sd	s9,456(sp)
    80004c90:	e3ea                	sd	s10,448(sp)
    80004c92:	ff6e                	sd	s11,440(sp)
    80004c94:	1400                	addi	s0,sp,544
    80004c96:	892a                	mv	s2,a0
    80004c98:	dea43423          	sd	a0,-536(s0)
    80004c9c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ca0:	ffffd097          	auipc	ra,0xffffd
    80004ca4:	d58080e7          	jalr	-680(ra) # 800019f8 <myproc>
    80004ca8:	84aa                	mv	s1,a0

  begin_op();
    80004caa:	fffff097          	auipc	ra,0xfffff
    80004cae:	47e080e7          	jalr	1150(ra) # 80004128 <begin_op>

  if((ip = namei(path)) == 0){
    80004cb2:	854a                	mv	a0,s2
    80004cb4:	fffff097          	auipc	ra,0xfffff
    80004cb8:	258080e7          	jalr	600(ra) # 80003f0c <namei>
    80004cbc:	c93d                	beqz	a0,80004d32 <exec+0xc4>
    80004cbe:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cc0:	fffff097          	auipc	ra,0xfffff
    80004cc4:	aa6080e7          	jalr	-1370(ra) # 80003766 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cc8:	04000713          	li	a4,64
    80004ccc:	4681                	li	a3,0
    80004cce:	e5040613          	addi	a2,s0,-432
    80004cd2:	4581                	li	a1,0
    80004cd4:	8556                	mv	a0,s5
    80004cd6:	fffff097          	auipc	ra,0xfffff
    80004cda:	d44080e7          	jalr	-700(ra) # 80003a1a <readi>
    80004cde:	04000793          	li	a5,64
    80004ce2:	00f51a63          	bne	a0,a5,80004cf6 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004ce6:	e5042703          	lw	a4,-432(s0)
    80004cea:	464c47b7          	lui	a5,0x464c4
    80004cee:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cf2:	04f70663          	beq	a4,a5,80004d3e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cf6:	8556                	mv	a0,s5
    80004cf8:	fffff097          	auipc	ra,0xfffff
    80004cfc:	cd0080e7          	jalr	-816(ra) # 800039c8 <iunlockput>
    end_op();
    80004d00:	fffff097          	auipc	ra,0xfffff
    80004d04:	4a8080e7          	jalr	1192(ra) # 800041a8 <end_op>
  }
  return -1;
    80004d08:	557d                	li	a0,-1
}
    80004d0a:	21813083          	ld	ra,536(sp)
    80004d0e:	21013403          	ld	s0,528(sp)
    80004d12:	20813483          	ld	s1,520(sp)
    80004d16:	20013903          	ld	s2,512(sp)
    80004d1a:	79fe                	ld	s3,504(sp)
    80004d1c:	7a5e                	ld	s4,496(sp)
    80004d1e:	7abe                	ld	s5,488(sp)
    80004d20:	7b1e                	ld	s6,480(sp)
    80004d22:	6bfe                	ld	s7,472(sp)
    80004d24:	6c5e                	ld	s8,464(sp)
    80004d26:	6cbe                	ld	s9,456(sp)
    80004d28:	6d1e                	ld	s10,448(sp)
    80004d2a:	7dfa                	ld	s11,440(sp)
    80004d2c:	22010113          	addi	sp,sp,544
    80004d30:	8082                	ret
    end_op();
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	476080e7          	jalr	1142(ra) # 800041a8 <end_op>
    return -1;
    80004d3a:	557d                	li	a0,-1
    80004d3c:	b7f9                	j	80004d0a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d3e:	8526                	mv	a0,s1
    80004d40:	ffffd097          	auipc	ra,0xffffd
    80004d44:	d7c080e7          	jalr	-644(ra) # 80001abc <proc_pagetable>
    80004d48:	8b2a                	mv	s6,a0
    80004d4a:	d555                	beqz	a0,80004cf6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d4c:	e7042783          	lw	a5,-400(s0)
    80004d50:	e8845703          	lhu	a4,-376(s0)
    80004d54:	c735                	beqz	a4,80004dc0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d56:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d58:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d5c:	6a05                	lui	s4,0x1
    80004d5e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d62:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d66:	6d85                	lui	s11,0x1
    80004d68:	7d7d                	lui	s10,0xfffff
    80004d6a:	a481                	j	80004faa <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d6c:	00004517          	auipc	a0,0x4
    80004d70:	96c50513          	addi	a0,a0,-1684 # 800086d8 <syscalls+0x288>
    80004d74:	ffffb097          	auipc	ra,0xffffb
    80004d78:	7ca080e7          	jalr	1994(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d7c:	874a                	mv	a4,s2
    80004d7e:	009c86bb          	addw	a3,s9,s1
    80004d82:	4581                	li	a1,0
    80004d84:	8556                	mv	a0,s5
    80004d86:	fffff097          	auipc	ra,0xfffff
    80004d8a:	c94080e7          	jalr	-876(ra) # 80003a1a <readi>
    80004d8e:	2501                	sext.w	a0,a0
    80004d90:	1aa91a63          	bne	s2,a0,80004f44 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d94:	009d84bb          	addw	s1,s11,s1
    80004d98:	013d09bb          	addw	s3,s10,s3
    80004d9c:	1f74f763          	bgeu	s1,s7,80004f8a <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004da0:	02049593          	slli	a1,s1,0x20
    80004da4:	9181                	srli	a1,a1,0x20
    80004da6:	95e2                	add	a1,a1,s8
    80004da8:	855a                	mv	a0,s6
    80004daa:	ffffc097          	auipc	ra,0xffffc
    80004dae:	2fe080e7          	jalr	766(ra) # 800010a8 <walkaddr>
    80004db2:	862a                	mv	a2,a0
    if(pa == 0)
    80004db4:	dd45                	beqz	a0,80004d6c <exec+0xfe>
      n = PGSIZE;
    80004db6:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004db8:	fd49f2e3          	bgeu	s3,s4,80004d7c <exec+0x10e>
      n = sz - i;
    80004dbc:	894e                	mv	s2,s3
    80004dbe:	bf7d                	j	80004d7c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dc0:	4901                	li	s2,0
  iunlockput(ip);
    80004dc2:	8556                	mv	a0,s5
    80004dc4:	fffff097          	auipc	ra,0xfffff
    80004dc8:	c04080e7          	jalr	-1020(ra) # 800039c8 <iunlockput>
  end_op();
    80004dcc:	fffff097          	auipc	ra,0xfffff
    80004dd0:	3dc080e7          	jalr	988(ra) # 800041a8 <end_op>
  p = myproc();
    80004dd4:	ffffd097          	auipc	ra,0xffffd
    80004dd8:	c24080e7          	jalr	-988(ra) # 800019f8 <myproc>
    80004ddc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004dde:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004de2:	6785                	lui	a5,0x1
    80004de4:	17fd                	addi	a5,a5,-1
    80004de6:	993e                	add	s2,s2,a5
    80004de8:	77fd                	lui	a5,0xfffff
    80004dea:	00f977b3          	and	a5,s2,a5
    80004dee:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004df2:	4691                	li	a3,4
    80004df4:	6609                	lui	a2,0x2
    80004df6:	963e                	add	a2,a2,a5
    80004df8:	85be                	mv	a1,a5
    80004dfa:	855a                	mv	a0,s6
    80004dfc:	ffffc097          	auipc	ra,0xffffc
    80004e00:	660080e7          	jalr	1632(ra) # 8000145c <uvmalloc>
    80004e04:	8c2a                	mv	s8,a0
  ip = 0;
    80004e06:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e08:	12050e63          	beqz	a0,80004f44 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e0c:	75f9                	lui	a1,0xffffe
    80004e0e:	95aa                	add	a1,a1,a0
    80004e10:	855a                	mv	a0,s6
    80004e12:	ffffd097          	auipc	ra,0xffffd
    80004e16:	870080e7          	jalr	-1936(ra) # 80001682 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e1a:	7afd                	lui	s5,0xfffff
    80004e1c:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e1e:	df043783          	ld	a5,-528(s0)
    80004e22:	6388                	ld	a0,0(a5)
    80004e24:	c925                	beqz	a0,80004e94 <exec+0x226>
    80004e26:	e9040993          	addi	s3,s0,-368
    80004e2a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e2e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e30:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e32:	ffffc097          	auipc	ra,0xffffc
    80004e36:	068080e7          	jalr	104(ra) # 80000e9a <strlen>
    80004e3a:	0015079b          	addiw	a5,a0,1
    80004e3e:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e42:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e46:	13596663          	bltu	s2,s5,80004f72 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e4a:	df043d83          	ld	s11,-528(s0)
    80004e4e:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e52:	8552                	mv	a0,s4
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	046080e7          	jalr	70(ra) # 80000e9a <strlen>
    80004e5c:	0015069b          	addiw	a3,a0,1
    80004e60:	8652                	mv	a2,s4
    80004e62:	85ca                	mv	a1,s2
    80004e64:	855a                	mv	a0,s6
    80004e66:	ffffd097          	auipc	ra,0xffffd
    80004e6a:	84e080e7          	jalr	-1970(ra) # 800016b4 <copyout>
    80004e6e:	10054663          	bltz	a0,80004f7a <exec+0x30c>
    ustack[argc] = sp;
    80004e72:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e76:	0485                	addi	s1,s1,1
    80004e78:	008d8793          	addi	a5,s11,8
    80004e7c:	def43823          	sd	a5,-528(s0)
    80004e80:	008db503          	ld	a0,8(s11)
    80004e84:	c911                	beqz	a0,80004e98 <exec+0x22a>
    if(argc >= MAXARG)
    80004e86:	09a1                	addi	s3,s3,8
    80004e88:	fb3c95e3          	bne	s9,s3,80004e32 <exec+0x1c4>
  sz = sz1;
    80004e8c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e90:	4a81                	li	s5,0
    80004e92:	a84d                	j	80004f44 <exec+0x2d6>
  sp = sz;
    80004e94:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e96:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e98:	00349793          	slli	a5,s1,0x3
    80004e9c:	f9040713          	addi	a4,s0,-112
    80004ea0:	97ba                	add	a5,a5,a4
    80004ea2:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdd1b0>
  sp -= (argc+1) * sizeof(uint64);
    80004ea6:	00148693          	addi	a3,s1,1
    80004eaa:	068e                	slli	a3,a3,0x3
    80004eac:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004eb0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004eb4:	01597663          	bgeu	s2,s5,80004ec0 <exec+0x252>
  sz = sz1;
    80004eb8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ebc:	4a81                	li	s5,0
    80004ebe:	a059                	j	80004f44 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ec0:	e9040613          	addi	a2,s0,-368
    80004ec4:	85ca                	mv	a1,s2
    80004ec6:	855a                	mv	a0,s6
    80004ec8:	ffffc097          	auipc	ra,0xffffc
    80004ecc:	7ec080e7          	jalr	2028(ra) # 800016b4 <copyout>
    80004ed0:	0a054963          	bltz	a0,80004f82 <exec+0x314>
  p->trapframe->a1 = sp;
    80004ed4:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004ed8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004edc:	de843783          	ld	a5,-536(s0)
    80004ee0:	0007c703          	lbu	a4,0(a5)
    80004ee4:	cf11                	beqz	a4,80004f00 <exec+0x292>
    80004ee6:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ee8:	02f00693          	li	a3,47
    80004eec:	a039                	j	80004efa <exec+0x28c>
      last = s+1;
    80004eee:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004ef2:	0785                	addi	a5,a5,1
    80004ef4:	fff7c703          	lbu	a4,-1(a5)
    80004ef8:	c701                	beqz	a4,80004f00 <exec+0x292>
    if(*s == '/')
    80004efa:	fed71ce3          	bne	a4,a3,80004ef2 <exec+0x284>
    80004efe:	bfc5                	j	80004eee <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f00:	4641                	li	a2,16
    80004f02:	de843583          	ld	a1,-536(s0)
    80004f06:	158b8513          	addi	a0,s7,344
    80004f0a:	ffffc097          	auipc	ra,0xffffc
    80004f0e:	f5e080e7          	jalr	-162(ra) # 80000e68 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f12:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f16:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f1a:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f1e:	058bb783          	ld	a5,88(s7)
    80004f22:	e6843703          	ld	a4,-408(s0)
    80004f26:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f28:	058bb783          	ld	a5,88(s7)
    80004f2c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f30:	85ea                	mv	a1,s10
    80004f32:	ffffd097          	auipc	ra,0xffffd
    80004f36:	c26080e7          	jalr	-986(ra) # 80001b58 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f3a:	0004851b          	sext.w	a0,s1
    80004f3e:	b3f1                	j	80004d0a <exec+0x9c>
    80004f40:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f44:	df843583          	ld	a1,-520(s0)
    80004f48:	855a                	mv	a0,s6
    80004f4a:	ffffd097          	auipc	ra,0xffffd
    80004f4e:	c0e080e7          	jalr	-1010(ra) # 80001b58 <proc_freepagetable>
  if(ip){
    80004f52:	da0a92e3          	bnez	s5,80004cf6 <exec+0x88>
  return -1;
    80004f56:	557d                	li	a0,-1
    80004f58:	bb4d                	j	80004d0a <exec+0x9c>
    80004f5a:	df243c23          	sd	s2,-520(s0)
    80004f5e:	b7dd                	j	80004f44 <exec+0x2d6>
    80004f60:	df243c23          	sd	s2,-520(s0)
    80004f64:	b7c5                	j	80004f44 <exec+0x2d6>
    80004f66:	df243c23          	sd	s2,-520(s0)
    80004f6a:	bfe9                	j	80004f44 <exec+0x2d6>
    80004f6c:	df243c23          	sd	s2,-520(s0)
    80004f70:	bfd1                	j	80004f44 <exec+0x2d6>
  sz = sz1;
    80004f72:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f76:	4a81                	li	s5,0
    80004f78:	b7f1                	j	80004f44 <exec+0x2d6>
  sz = sz1;
    80004f7a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f7e:	4a81                	li	s5,0
    80004f80:	b7d1                	j	80004f44 <exec+0x2d6>
  sz = sz1;
    80004f82:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f86:	4a81                	li	s5,0
    80004f88:	bf75                	j	80004f44 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f8a:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f8e:	e0843783          	ld	a5,-504(s0)
    80004f92:	0017869b          	addiw	a3,a5,1
    80004f96:	e0d43423          	sd	a3,-504(s0)
    80004f9a:	e0043783          	ld	a5,-512(s0)
    80004f9e:	0387879b          	addiw	a5,a5,56
    80004fa2:	e8845703          	lhu	a4,-376(s0)
    80004fa6:	e0e6dee3          	bge	a3,a4,80004dc2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004faa:	2781                	sext.w	a5,a5
    80004fac:	e0f43023          	sd	a5,-512(s0)
    80004fb0:	03800713          	li	a4,56
    80004fb4:	86be                	mv	a3,a5
    80004fb6:	e1840613          	addi	a2,s0,-488
    80004fba:	4581                	li	a1,0
    80004fbc:	8556                	mv	a0,s5
    80004fbe:	fffff097          	auipc	ra,0xfffff
    80004fc2:	a5c080e7          	jalr	-1444(ra) # 80003a1a <readi>
    80004fc6:	03800793          	li	a5,56
    80004fca:	f6f51be3          	bne	a0,a5,80004f40 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80004fce:	e1842783          	lw	a5,-488(s0)
    80004fd2:	4705                	li	a4,1
    80004fd4:	fae79de3          	bne	a5,a4,80004f8e <exec+0x320>
    if(ph.memsz < ph.filesz)
    80004fd8:	e4043483          	ld	s1,-448(s0)
    80004fdc:	e3843783          	ld	a5,-456(s0)
    80004fe0:	f6f4ede3          	bltu	s1,a5,80004f5a <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fe4:	e2843783          	ld	a5,-472(s0)
    80004fe8:	94be                	add	s1,s1,a5
    80004fea:	f6f4ebe3          	bltu	s1,a5,80004f60 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80004fee:	de043703          	ld	a4,-544(s0)
    80004ff2:	8ff9                	and	a5,a5,a4
    80004ff4:	fbad                	bnez	a5,80004f66 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ff6:	e1c42503          	lw	a0,-484(s0)
    80004ffa:	00000097          	auipc	ra,0x0
    80004ffe:	c58080e7          	jalr	-936(ra) # 80004c52 <flags2perm>
    80005002:	86aa                	mv	a3,a0
    80005004:	8626                	mv	a2,s1
    80005006:	85ca                	mv	a1,s2
    80005008:	855a                	mv	a0,s6
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	452080e7          	jalr	1106(ra) # 8000145c <uvmalloc>
    80005012:	dea43c23          	sd	a0,-520(s0)
    80005016:	d939                	beqz	a0,80004f6c <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005018:	e2843c03          	ld	s8,-472(s0)
    8000501c:	e2042c83          	lw	s9,-480(s0)
    80005020:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005024:	f60b83e3          	beqz	s7,80004f8a <exec+0x31c>
    80005028:	89de                	mv	s3,s7
    8000502a:	4481                	li	s1,0
    8000502c:	bb95                	j	80004da0 <exec+0x132>

000000008000502e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000502e:	7179                	addi	sp,sp,-48
    80005030:	f406                	sd	ra,40(sp)
    80005032:	f022                	sd	s0,32(sp)
    80005034:	ec26                	sd	s1,24(sp)
    80005036:	e84a                	sd	s2,16(sp)
    80005038:	1800                	addi	s0,sp,48
    8000503a:	892e                	mv	s2,a1
    8000503c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000503e:	fdc40593          	addi	a1,s0,-36
    80005042:	ffffe097          	auipc	ra,0xffffe
    80005046:	b8e080e7          	jalr	-1138(ra) # 80002bd0 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000504a:	fdc42703          	lw	a4,-36(s0)
    8000504e:	47bd                	li	a5,15
    80005050:	02e7eb63          	bltu	a5,a4,80005086 <argfd+0x58>
    80005054:	ffffd097          	auipc	ra,0xffffd
    80005058:	9a4080e7          	jalr	-1628(ra) # 800019f8 <myproc>
    8000505c:	fdc42703          	lw	a4,-36(s0)
    80005060:	01a70793          	addi	a5,a4,26
    80005064:	078e                	slli	a5,a5,0x3
    80005066:	953e                	add	a0,a0,a5
    80005068:	611c                	ld	a5,0(a0)
    8000506a:	c385                	beqz	a5,8000508a <argfd+0x5c>
    return -1;
  if(pfd)
    8000506c:	00090463          	beqz	s2,80005074 <argfd+0x46>
    *pfd = fd;
    80005070:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005074:	4501                	li	a0,0
  if(pf)
    80005076:	c091                	beqz	s1,8000507a <argfd+0x4c>
    *pf = f;
    80005078:	e09c                	sd	a5,0(s1)
}
    8000507a:	70a2                	ld	ra,40(sp)
    8000507c:	7402                	ld	s0,32(sp)
    8000507e:	64e2                	ld	s1,24(sp)
    80005080:	6942                	ld	s2,16(sp)
    80005082:	6145                	addi	sp,sp,48
    80005084:	8082                	ret
    return -1;
    80005086:	557d                	li	a0,-1
    80005088:	bfcd                	j	8000507a <argfd+0x4c>
    8000508a:	557d                	li	a0,-1
    8000508c:	b7fd                	j	8000507a <argfd+0x4c>

000000008000508e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000508e:	1101                	addi	sp,sp,-32
    80005090:	ec06                	sd	ra,24(sp)
    80005092:	e822                	sd	s0,16(sp)
    80005094:	e426                	sd	s1,8(sp)
    80005096:	1000                	addi	s0,sp,32
    80005098:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000509a:	ffffd097          	auipc	ra,0xffffd
    8000509e:	95e080e7          	jalr	-1698(ra) # 800019f8 <myproc>
    800050a2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050a4:	0d050793          	addi	a5,a0,208
    800050a8:	4501                	li	a0,0
    800050aa:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050ac:	6398                	ld	a4,0(a5)
    800050ae:	cb19                	beqz	a4,800050c4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050b0:	2505                	addiw	a0,a0,1
    800050b2:	07a1                	addi	a5,a5,8
    800050b4:	fed51ce3          	bne	a0,a3,800050ac <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050b8:	557d                	li	a0,-1
}
    800050ba:	60e2                	ld	ra,24(sp)
    800050bc:	6442                	ld	s0,16(sp)
    800050be:	64a2                	ld	s1,8(sp)
    800050c0:	6105                	addi	sp,sp,32
    800050c2:	8082                	ret
      p->ofile[fd] = f;
    800050c4:	01a50793          	addi	a5,a0,26
    800050c8:	078e                	slli	a5,a5,0x3
    800050ca:	963e                	add	a2,a2,a5
    800050cc:	e204                	sd	s1,0(a2)
      return fd;
    800050ce:	b7f5                	j	800050ba <fdalloc+0x2c>

00000000800050d0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050d0:	715d                	addi	sp,sp,-80
    800050d2:	e486                	sd	ra,72(sp)
    800050d4:	e0a2                	sd	s0,64(sp)
    800050d6:	fc26                	sd	s1,56(sp)
    800050d8:	f84a                	sd	s2,48(sp)
    800050da:	f44e                	sd	s3,40(sp)
    800050dc:	f052                	sd	s4,32(sp)
    800050de:	ec56                	sd	s5,24(sp)
    800050e0:	e85a                	sd	s6,16(sp)
    800050e2:	0880                	addi	s0,sp,80
    800050e4:	8b2e                	mv	s6,a1
    800050e6:	89b2                	mv	s3,a2
    800050e8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050ea:	fb040593          	addi	a1,s0,-80
    800050ee:	fffff097          	auipc	ra,0xfffff
    800050f2:	e3c080e7          	jalr	-452(ra) # 80003f2a <nameiparent>
    800050f6:	84aa                	mv	s1,a0
    800050f8:	14050f63          	beqz	a0,80005256 <create+0x186>
    return 0;

  ilock(dp);
    800050fc:	ffffe097          	auipc	ra,0xffffe
    80005100:	66a080e7          	jalr	1642(ra) # 80003766 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005104:	4601                	li	a2,0
    80005106:	fb040593          	addi	a1,s0,-80
    8000510a:	8526                	mv	a0,s1
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	b3e080e7          	jalr	-1218(ra) # 80003c4a <dirlookup>
    80005114:	8aaa                	mv	s5,a0
    80005116:	c931                	beqz	a0,8000516a <create+0x9a>
    iunlockput(dp);
    80005118:	8526                	mv	a0,s1
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	8ae080e7          	jalr	-1874(ra) # 800039c8 <iunlockput>
    ilock(ip);
    80005122:	8556                	mv	a0,s5
    80005124:	ffffe097          	auipc	ra,0xffffe
    80005128:	642080e7          	jalr	1602(ra) # 80003766 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000512c:	000b059b          	sext.w	a1,s6
    80005130:	4789                	li	a5,2
    80005132:	02f59563          	bne	a1,a5,8000515c <create+0x8c>
    80005136:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd2f4>
    8000513a:	37f9                	addiw	a5,a5,-2
    8000513c:	17c2                	slli	a5,a5,0x30
    8000513e:	93c1                	srli	a5,a5,0x30
    80005140:	4705                	li	a4,1
    80005142:	00f76d63          	bltu	a4,a5,8000515c <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005146:	8556                	mv	a0,s5
    80005148:	60a6                	ld	ra,72(sp)
    8000514a:	6406                	ld	s0,64(sp)
    8000514c:	74e2                	ld	s1,56(sp)
    8000514e:	7942                	ld	s2,48(sp)
    80005150:	79a2                	ld	s3,40(sp)
    80005152:	7a02                	ld	s4,32(sp)
    80005154:	6ae2                	ld	s5,24(sp)
    80005156:	6b42                	ld	s6,16(sp)
    80005158:	6161                	addi	sp,sp,80
    8000515a:	8082                	ret
    iunlockput(ip);
    8000515c:	8556                	mv	a0,s5
    8000515e:	fffff097          	auipc	ra,0xfffff
    80005162:	86a080e7          	jalr	-1942(ra) # 800039c8 <iunlockput>
    return 0;
    80005166:	4a81                	li	s5,0
    80005168:	bff9                	j	80005146 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000516a:	85da                	mv	a1,s6
    8000516c:	4088                	lw	a0,0(s1)
    8000516e:	ffffe097          	auipc	ra,0xffffe
    80005172:	45c080e7          	jalr	1116(ra) # 800035ca <ialloc>
    80005176:	8a2a                	mv	s4,a0
    80005178:	c539                	beqz	a0,800051c6 <create+0xf6>
  ilock(ip);
    8000517a:	ffffe097          	auipc	ra,0xffffe
    8000517e:	5ec080e7          	jalr	1516(ra) # 80003766 <ilock>
  ip->major = major;
    80005182:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005186:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000518a:	4905                	li	s2,1
    8000518c:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005190:	8552                	mv	a0,s4
    80005192:	ffffe097          	auipc	ra,0xffffe
    80005196:	50a080e7          	jalr	1290(ra) # 8000369c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000519a:	000b059b          	sext.w	a1,s6
    8000519e:	03258b63          	beq	a1,s2,800051d4 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800051a2:	004a2603          	lw	a2,4(s4)
    800051a6:	fb040593          	addi	a1,s0,-80
    800051aa:	8526                	mv	a0,s1
    800051ac:	fffff097          	auipc	ra,0xfffff
    800051b0:	cae080e7          	jalr	-850(ra) # 80003e5a <dirlink>
    800051b4:	06054f63          	bltz	a0,80005232 <create+0x162>
  iunlockput(dp);
    800051b8:	8526                	mv	a0,s1
    800051ba:	fffff097          	auipc	ra,0xfffff
    800051be:	80e080e7          	jalr	-2034(ra) # 800039c8 <iunlockput>
  return ip;
    800051c2:	8ad2                	mv	s5,s4
    800051c4:	b749                	j	80005146 <create+0x76>
    iunlockput(dp);
    800051c6:	8526                	mv	a0,s1
    800051c8:	fffff097          	auipc	ra,0xfffff
    800051cc:	800080e7          	jalr	-2048(ra) # 800039c8 <iunlockput>
    return 0;
    800051d0:	8ad2                	mv	s5,s4
    800051d2:	bf95                	j	80005146 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051d4:	004a2603          	lw	a2,4(s4)
    800051d8:	00003597          	auipc	a1,0x3
    800051dc:	52058593          	addi	a1,a1,1312 # 800086f8 <syscalls+0x2a8>
    800051e0:	8552                	mv	a0,s4
    800051e2:	fffff097          	auipc	ra,0xfffff
    800051e6:	c78080e7          	jalr	-904(ra) # 80003e5a <dirlink>
    800051ea:	04054463          	bltz	a0,80005232 <create+0x162>
    800051ee:	40d0                	lw	a2,4(s1)
    800051f0:	00003597          	auipc	a1,0x3
    800051f4:	51058593          	addi	a1,a1,1296 # 80008700 <syscalls+0x2b0>
    800051f8:	8552                	mv	a0,s4
    800051fa:	fffff097          	auipc	ra,0xfffff
    800051fe:	c60080e7          	jalr	-928(ra) # 80003e5a <dirlink>
    80005202:	02054863          	bltz	a0,80005232 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005206:	004a2603          	lw	a2,4(s4)
    8000520a:	fb040593          	addi	a1,s0,-80
    8000520e:	8526                	mv	a0,s1
    80005210:	fffff097          	auipc	ra,0xfffff
    80005214:	c4a080e7          	jalr	-950(ra) # 80003e5a <dirlink>
    80005218:	00054d63          	bltz	a0,80005232 <create+0x162>
    dp->nlink++;  // for ".."
    8000521c:	04a4d783          	lhu	a5,74(s1)
    80005220:	2785                	addiw	a5,a5,1
    80005222:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005226:	8526                	mv	a0,s1
    80005228:	ffffe097          	auipc	ra,0xffffe
    8000522c:	474080e7          	jalr	1140(ra) # 8000369c <iupdate>
    80005230:	b761                	j	800051b8 <create+0xe8>
  ip->nlink = 0;
    80005232:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005236:	8552                	mv	a0,s4
    80005238:	ffffe097          	auipc	ra,0xffffe
    8000523c:	464080e7          	jalr	1124(ra) # 8000369c <iupdate>
  iunlockput(ip);
    80005240:	8552                	mv	a0,s4
    80005242:	ffffe097          	auipc	ra,0xffffe
    80005246:	786080e7          	jalr	1926(ra) # 800039c8 <iunlockput>
  iunlockput(dp);
    8000524a:	8526                	mv	a0,s1
    8000524c:	ffffe097          	auipc	ra,0xffffe
    80005250:	77c080e7          	jalr	1916(ra) # 800039c8 <iunlockput>
  return 0;
    80005254:	bdcd                	j	80005146 <create+0x76>
    return 0;
    80005256:	8aaa                	mv	s5,a0
    80005258:	b5fd                	j	80005146 <create+0x76>

000000008000525a <sys_dup>:
{
    8000525a:	7179                	addi	sp,sp,-48
    8000525c:	f406                	sd	ra,40(sp)
    8000525e:	f022                	sd	s0,32(sp)
    80005260:	ec26                	sd	s1,24(sp)
    80005262:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005264:	fd840613          	addi	a2,s0,-40
    80005268:	4581                	li	a1,0
    8000526a:	4501                	li	a0,0
    8000526c:	00000097          	auipc	ra,0x0
    80005270:	dc2080e7          	jalr	-574(ra) # 8000502e <argfd>
    return -1;
    80005274:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005276:	02054363          	bltz	a0,8000529c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000527a:	fd843503          	ld	a0,-40(s0)
    8000527e:	00000097          	auipc	ra,0x0
    80005282:	e10080e7          	jalr	-496(ra) # 8000508e <fdalloc>
    80005286:	84aa                	mv	s1,a0
    return -1;
    80005288:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000528a:	00054963          	bltz	a0,8000529c <sys_dup+0x42>
  filedup(f);
    8000528e:	fd843503          	ld	a0,-40(s0)
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	310080e7          	jalr	784(ra) # 800045a2 <filedup>
  return fd;
    8000529a:	87a6                	mv	a5,s1
}
    8000529c:	853e                	mv	a0,a5
    8000529e:	70a2                	ld	ra,40(sp)
    800052a0:	7402                	ld	s0,32(sp)
    800052a2:	64e2                	ld	s1,24(sp)
    800052a4:	6145                	addi	sp,sp,48
    800052a6:	8082                	ret

00000000800052a8 <sys_read>:
{
    800052a8:	7179                	addi	sp,sp,-48
    800052aa:	f406                	sd	ra,40(sp)
    800052ac:	f022                	sd	s0,32(sp)
    800052ae:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052b0:	fd840593          	addi	a1,s0,-40
    800052b4:	4505                	li	a0,1
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	93a080e7          	jalr	-1734(ra) # 80002bf0 <argaddr>
  argint(2, &n);
    800052be:	fe440593          	addi	a1,s0,-28
    800052c2:	4509                	li	a0,2
    800052c4:	ffffe097          	auipc	ra,0xffffe
    800052c8:	90c080e7          	jalr	-1780(ra) # 80002bd0 <argint>
  if(argfd(0, 0, &f) < 0)
    800052cc:	fe840613          	addi	a2,s0,-24
    800052d0:	4581                	li	a1,0
    800052d2:	4501                	li	a0,0
    800052d4:	00000097          	auipc	ra,0x0
    800052d8:	d5a080e7          	jalr	-678(ra) # 8000502e <argfd>
    800052dc:	87aa                	mv	a5,a0
    return -1;
    800052de:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052e0:	0007cc63          	bltz	a5,800052f8 <sys_read+0x50>
  return fileread(f, p, n);
    800052e4:	fe442603          	lw	a2,-28(s0)
    800052e8:	fd843583          	ld	a1,-40(s0)
    800052ec:	fe843503          	ld	a0,-24(s0)
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	43e080e7          	jalr	1086(ra) # 8000472e <fileread>
}
    800052f8:	70a2                	ld	ra,40(sp)
    800052fa:	7402                	ld	s0,32(sp)
    800052fc:	6145                	addi	sp,sp,48
    800052fe:	8082                	ret

0000000080005300 <sys_write>:
{
    80005300:	7179                	addi	sp,sp,-48
    80005302:	f406                	sd	ra,40(sp)
    80005304:	f022                	sd	s0,32(sp)
    80005306:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005308:	fd840593          	addi	a1,s0,-40
    8000530c:	4505                	li	a0,1
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	8e2080e7          	jalr	-1822(ra) # 80002bf0 <argaddr>
  argint(2, &n);
    80005316:	fe440593          	addi	a1,s0,-28
    8000531a:	4509                	li	a0,2
    8000531c:	ffffe097          	auipc	ra,0xffffe
    80005320:	8b4080e7          	jalr	-1868(ra) # 80002bd0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005324:	fe840613          	addi	a2,s0,-24
    80005328:	4581                	li	a1,0
    8000532a:	4501                	li	a0,0
    8000532c:	00000097          	auipc	ra,0x0
    80005330:	d02080e7          	jalr	-766(ra) # 8000502e <argfd>
    80005334:	87aa                	mv	a5,a0
    return -1;
    80005336:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005338:	0007cc63          	bltz	a5,80005350 <sys_write+0x50>
  return filewrite(f, p, n);
    8000533c:	fe442603          	lw	a2,-28(s0)
    80005340:	fd843583          	ld	a1,-40(s0)
    80005344:	fe843503          	ld	a0,-24(s0)
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	4a8080e7          	jalr	1192(ra) # 800047f0 <filewrite>
}
    80005350:	70a2                	ld	ra,40(sp)
    80005352:	7402                	ld	s0,32(sp)
    80005354:	6145                	addi	sp,sp,48
    80005356:	8082                	ret

0000000080005358 <sys_close>:
{
    80005358:	1101                	addi	sp,sp,-32
    8000535a:	ec06                	sd	ra,24(sp)
    8000535c:	e822                	sd	s0,16(sp)
    8000535e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005360:	fe040613          	addi	a2,s0,-32
    80005364:	fec40593          	addi	a1,s0,-20
    80005368:	4501                	li	a0,0
    8000536a:	00000097          	auipc	ra,0x0
    8000536e:	cc4080e7          	jalr	-828(ra) # 8000502e <argfd>
    return -1;
    80005372:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005374:	02054463          	bltz	a0,8000539c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005378:	ffffc097          	auipc	ra,0xffffc
    8000537c:	680080e7          	jalr	1664(ra) # 800019f8 <myproc>
    80005380:	fec42783          	lw	a5,-20(s0)
    80005384:	07e9                	addi	a5,a5,26
    80005386:	078e                	slli	a5,a5,0x3
    80005388:	97aa                	add	a5,a5,a0
    8000538a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000538e:	fe043503          	ld	a0,-32(s0)
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	262080e7          	jalr	610(ra) # 800045f4 <fileclose>
  return 0;
    8000539a:	4781                	li	a5,0
}
    8000539c:	853e                	mv	a0,a5
    8000539e:	60e2                	ld	ra,24(sp)
    800053a0:	6442                	ld	s0,16(sp)
    800053a2:	6105                	addi	sp,sp,32
    800053a4:	8082                	ret

00000000800053a6 <sys_fstat>:
{
    800053a6:	1101                	addi	sp,sp,-32
    800053a8:	ec06                	sd	ra,24(sp)
    800053aa:	e822                	sd	s0,16(sp)
    800053ac:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053ae:	fe040593          	addi	a1,s0,-32
    800053b2:	4505                	li	a0,1
    800053b4:	ffffe097          	auipc	ra,0xffffe
    800053b8:	83c080e7          	jalr	-1988(ra) # 80002bf0 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053bc:	fe840613          	addi	a2,s0,-24
    800053c0:	4581                	li	a1,0
    800053c2:	4501                	li	a0,0
    800053c4:	00000097          	auipc	ra,0x0
    800053c8:	c6a080e7          	jalr	-918(ra) # 8000502e <argfd>
    800053cc:	87aa                	mv	a5,a0
    return -1;
    800053ce:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053d0:	0007ca63          	bltz	a5,800053e4 <sys_fstat+0x3e>
  return filestat(f, st);
    800053d4:	fe043583          	ld	a1,-32(s0)
    800053d8:	fe843503          	ld	a0,-24(s0)
    800053dc:	fffff097          	auipc	ra,0xfffff
    800053e0:	2e0080e7          	jalr	736(ra) # 800046bc <filestat>
}
    800053e4:	60e2                	ld	ra,24(sp)
    800053e6:	6442                	ld	s0,16(sp)
    800053e8:	6105                	addi	sp,sp,32
    800053ea:	8082                	ret

00000000800053ec <sys_link>:
{
    800053ec:	7169                	addi	sp,sp,-304
    800053ee:	f606                	sd	ra,296(sp)
    800053f0:	f222                	sd	s0,288(sp)
    800053f2:	ee26                	sd	s1,280(sp)
    800053f4:	ea4a                	sd	s2,272(sp)
    800053f6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053f8:	08000613          	li	a2,128
    800053fc:	ed040593          	addi	a1,s0,-304
    80005400:	4501                	li	a0,0
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	80e080e7          	jalr	-2034(ra) # 80002c10 <argstr>
    return -1;
    8000540a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000540c:	10054e63          	bltz	a0,80005528 <sys_link+0x13c>
    80005410:	08000613          	li	a2,128
    80005414:	f5040593          	addi	a1,s0,-176
    80005418:	4505                	li	a0,1
    8000541a:	ffffd097          	auipc	ra,0xffffd
    8000541e:	7f6080e7          	jalr	2038(ra) # 80002c10 <argstr>
    return -1;
    80005422:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005424:	10054263          	bltz	a0,80005528 <sys_link+0x13c>
  begin_op();
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	d00080e7          	jalr	-768(ra) # 80004128 <begin_op>
  if((ip = namei(old)) == 0){
    80005430:	ed040513          	addi	a0,s0,-304
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	ad8080e7          	jalr	-1320(ra) # 80003f0c <namei>
    8000543c:	84aa                	mv	s1,a0
    8000543e:	c551                	beqz	a0,800054ca <sys_link+0xde>
  ilock(ip);
    80005440:	ffffe097          	auipc	ra,0xffffe
    80005444:	326080e7          	jalr	806(ra) # 80003766 <ilock>
  if(ip->type == T_DIR){
    80005448:	04449703          	lh	a4,68(s1)
    8000544c:	4785                	li	a5,1
    8000544e:	08f70463          	beq	a4,a5,800054d6 <sys_link+0xea>
  ip->nlink++;
    80005452:	04a4d783          	lhu	a5,74(s1)
    80005456:	2785                	addiw	a5,a5,1
    80005458:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000545c:	8526                	mv	a0,s1
    8000545e:	ffffe097          	auipc	ra,0xffffe
    80005462:	23e080e7          	jalr	574(ra) # 8000369c <iupdate>
  iunlock(ip);
    80005466:	8526                	mv	a0,s1
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	3c0080e7          	jalr	960(ra) # 80003828 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005470:	fd040593          	addi	a1,s0,-48
    80005474:	f5040513          	addi	a0,s0,-176
    80005478:	fffff097          	auipc	ra,0xfffff
    8000547c:	ab2080e7          	jalr	-1358(ra) # 80003f2a <nameiparent>
    80005480:	892a                	mv	s2,a0
    80005482:	c935                	beqz	a0,800054f6 <sys_link+0x10a>
  ilock(dp);
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	2e2080e7          	jalr	738(ra) # 80003766 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000548c:	00092703          	lw	a4,0(s2)
    80005490:	409c                	lw	a5,0(s1)
    80005492:	04f71d63          	bne	a4,a5,800054ec <sys_link+0x100>
    80005496:	40d0                	lw	a2,4(s1)
    80005498:	fd040593          	addi	a1,s0,-48
    8000549c:	854a                	mv	a0,s2
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	9bc080e7          	jalr	-1604(ra) # 80003e5a <dirlink>
    800054a6:	04054363          	bltz	a0,800054ec <sys_link+0x100>
  iunlockput(dp);
    800054aa:	854a                	mv	a0,s2
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	51c080e7          	jalr	1308(ra) # 800039c8 <iunlockput>
  iput(ip);
    800054b4:	8526                	mv	a0,s1
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	46a080e7          	jalr	1130(ra) # 80003920 <iput>
  end_op();
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	cea080e7          	jalr	-790(ra) # 800041a8 <end_op>
  return 0;
    800054c6:	4781                	li	a5,0
    800054c8:	a085                	j	80005528 <sys_link+0x13c>
    end_op();
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	cde080e7          	jalr	-802(ra) # 800041a8 <end_op>
    return -1;
    800054d2:	57fd                	li	a5,-1
    800054d4:	a891                	j	80005528 <sys_link+0x13c>
    iunlockput(ip);
    800054d6:	8526                	mv	a0,s1
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	4f0080e7          	jalr	1264(ra) # 800039c8 <iunlockput>
    end_op();
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	cc8080e7          	jalr	-824(ra) # 800041a8 <end_op>
    return -1;
    800054e8:	57fd                	li	a5,-1
    800054ea:	a83d                	j	80005528 <sys_link+0x13c>
    iunlockput(dp);
    800054ec:	854a                	mv	a0,s2
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	4da080e7          	jalr	1242(ra) # 800039c8 <iunlockput>
  ilock(ip);
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	26e080e7          	jalr	622(ra) # 80003766 <ilock>
  ip->nlink--;
    80005500:	04a4d783          	lhu	a5,74(s1)
    80005504:	37fd                	addiw	a5,a5,-1
    80005506:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	190080e7          	jalr	400(ra) # 8000369c <iupdate>
  iunlockput(ip);
    80005514:	8526                	mv	a0,s1
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	4b2080e7          	jalr	1202(ra) # 800039c8 <iunlockput>
  end_op();
    8000551e:	fffff097          	auipc	ra,0xfffff
    80005522:	c8a080e7          	jalr	-886(ra) # 800041a8 <end_op>
  return -1;
    80005526:	57fd                	li	a5,-1
}
    80005528:	853e                	mv	a0,a5
    8000552a:	70b2                	ld	ra,296(sp)
    8000552c:	7412                	ld	s0,288(sp)
    8000552e:	64f2                	ld	s1,280(sp)
    80005530:	6952                	ld	s2,272(sp)
    80005532:	6155                	addi	sp,sp,304
    80005534:	8082                	ret

0000000080005536 <sys_unlink>:
{
    80005536:	7151                	addi	sp,sp,-240
    80005538:	f586                	sd	ra,232(sp)
    8000553a:	f1a2                	sd	s0,224(sp)
    8000553c:	eda6                	sd	s1,216(sp)
    8000553e:	e9ca                	sd	s2,208(sp)
    80005540:	e5ce                	sd	s3,200(sp)
    80005542:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005544:	08000613          	li	a2,128
    80005548:	f3040593          	addi	a1,s0,-208
    8000554c:	4501                	li	a0,0
    8000554e:	ffffd097          	auipc	ra,0xffffd
    80005552:	6c2080e7          	jalr	1730(ra) # 80002c10 <argstr>
    80005556:	18054163          	bltz	a0,800056d8 <sys_unlink+0x1a2>
  begin_op();
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	bce080e7          	jalr	-1074(ra) # 80004128 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005562:	fb040593          	addi	a1,s0,-80
    80005566:	f3040513          	addi	a0,s0,-208
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	9c0080e7          	jalr	-1600(ra) # 80003f2a <nameiparent>
    80005572:	84aa                	mv	s1,a0
    80005574:	c979                	beqz	a0,8000564a <sys_unlink+0x114>
  ilock(dp);
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	1f0080e7          	jalr	496(ra) # 80003766 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000557e:	00003597          	auipc	a1,0x3
    80005582:	17a58593          	addi	a1,a1,378 # 800086f8 <syscalls+0x2a8>
    80005586:	fb040513          	addi	a0,s0,-80
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	6a6080e7          	jalr	1702(ra) # 80003c30 <namecmp>
    80005592:	14050a63          	beqz	a0,800056e6 <sys_unlink+0x1b0>
    80005596:	00003597          	auipc	a1,0x3
    8000559a:	16a58593          	addi	a1,a1,362 # 80008700 <syscalls+0x2b0>
    8000559e:	fb040513          	addi	a0,s0,-80
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	68e080e7          	jalr	1678(ra) # 80003c30 <namecmp>
    800055aa:	12050e63          	beqz	a0,800056e6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055ae:	f2c40613          	addi	a2,s0,-212
    800055b2:	fb040593          	addi	a1,s0,-80
    800055b6:	8526                	mv	a0,s1
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	692080e7          	jalr	1682(ra) # 80003c4a <dirlookup>
    800055c0:	892a                	mv	s2,a0
    800055c2:	12050263          	beqz	a0,800056e6 <sys_unlink+0x1b0>
  ilock(ip);
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	1a0080e7          	jalr	416(ra) # 80003766 <ilock>
  if(ip->nlink < 1)
    800055ce:	04a91783          	lh	a5,74(s2)
    800055d2:	08f05263          	blez	a5,80005656 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055d6:	04491703          	lh	a4,68(s2)
    800055da:	4785                	li	a5,1
    800055dc:	08f70563          	beq	a4,a5,80005666 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055e0:	4641                	li	a2,16
    800055e2:	4581                	li	a1,0
    800055e4:	fc040513          	addi	a0,s0,-64
    800055e8:	ffffb097          	auipc	ra,0xffffb
    800055ec:	736080e7          	jalr	1846(ra) # 80000d1e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055f0:	4741                	li	a4,16
    800055f2:	f2c42683          	lw	a3,-212(s0)
    800055f6:	fc040613          	addi	a2,s0,-64
    800055fa:	4581                	li	a1,0
    800055fc:	8526                	mv	a0,s1
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	514080e7          	jalr	1300(ra) # 80003b12 <writei>
    80005606:	47c1                	li	a5,16
    80005608:	0af51563          	bne	a0,a5,800056b2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000560c:	04491703          	lh	a4,68(s2)
    80005610:	4785                	li	a5,1
    80005612:	0af70863          	beq	a4,a5,800056c2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005616:	8526                	mv	a0,s1
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	3b0080e7          	jalr	944(ra) # 800039c8 <iunlockput>
  ip->nlink--;
    80005620:	04a95783          	lhu	a5,74(s2)
    80005624:	37fd                	addiw	a5,a5,-1
    80005626:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000562a:	854a                	mv	a0,s2
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	070080e7          	jalr	112(ra) # 8000369c <iupdate>
  iunlockput(ip);
    80005634:	854a                	mv	a0,s2
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	392080e7          	jalr	914(ra) # 800039c8 <iunlockput>
  end_op();
    8000563e:	fffff097          	auipc	ra,0xfffff
    80005642:	b6a080e7          	jalr	-1174(ra) # 800041a8 <end_op>
  return 0;
    80005646:	4501                	li	a0,0
    80005648:	a84d                	j	800056fa <sys_unlink+0x1c4>
    end_op();
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	b5e080e7          	jalr	-1186(ra) # 800041a8 <end_op>
    return -1;
    80005652:	557d                	li	a0,-1
    80005654:	a05d                	j	800056fa <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005656:	00003517          	auipc	a0,0x3
    8000565a:	0b250513          	addi	a0,a0,178 # 80008708 <syscalls+0x2b8>
    8000565e:	ffffb097          	auipc	ra,0xffffb
    80005662:	ee0080e7          	jalr	-288(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005666:	04c92703          	lw	a4,76(s2)
    8000566a:	02000793          	li	a5,32
    8000566e:	f6e7f9e3          	bgeu	a5,a4,800055e0 <sys_unlink+0xaa>
    80005672:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005676:	4741                	li	a4,16
    80005678:	86ce                	mv	a3,s3
    8000567a:	f1840613          	addi	a2,s0,-232
    8000567e:	4581                	li	a1,0
    80005680:	854a                	mv	a0,s2
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	398080e7          	jalr	920(ra) # 80003a1a <readi>
    8000568a:	47c1                	li	a5,16
    8000568c:	00f51b63          	bne	a0,a5,800056a2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005690:	f1845783          	lhu	a5,-232(s0)
    80005694:	e7a1                	bnez	a5,800056dc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005696:	29c1                	addiw	s3,s3,16
    80005698:	04c92783          	lw	a5,76(s2)
    8000569c:	fcf9ede3          	bltu	s3,a5,80005676 <sys_unlink+0x140>
    800056a0:	b781                	j	800055e0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056a2:	00003517          	auipc	a0,0x3
    800056a6:	07e50513          	addi	a0,a0,126 # 80008720 <syscalls+0x2d0>
    800056aa:	ffffb097          	auipc	ra,0xffffb
    800056ae:	e94080e7          	jalr	-364(ra) # 8000053e <panic>
    panic("unlink: writei");
    800056b2:	00003517          	auipc	a0,0x3
    800056b6:	08650513          	addi	a0,a0,134 # 80008738 <syscalls+0x2e8>
    800056ba:	ffffb097          	auipc	ra,0xffffb
    800056be:	e84080e7          	jalr	-380(ra) # 8000053e <panic>
    dp->nlink--;
    800056c2:	04a4d783          	lhu	a5,74(s1)
    800056c6:	37fd                	addiw	a5,a5,-1
    800056c8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056cc:	8526                	mv	a0,s1
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	fce080e7          	jalr	-50(ra) # 8000369c <iupdate>
    800056d6:	b781                	j	80005616 <sys_unlink+0xe0>
    return -1;
    800056d8:	557d                	li	a0,-1
    800056da:	a005                	j	800056fa <sys_unlink+0x1c4>
    iunlockput(ip);
    800056dc:	854a                	mv	a0,s2
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	2ea080e7          	jalr	746(ra) # 800039c8 <iunlockput>
  iunlockput(dp);
    800056e6:	8526                	mv	a0,s1
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	2e0080e7          	jalr	736(ra) # 800039c8 <iunlockput>
  end_op();
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	ab8080e7          	jalr	-1352(ra) # 800041a8 <end_op>
  return -1;
    800056f8:	557d                	li	a0,-1
}
    800056fa:	70ae                	ld	ra,232(sp)
    800056fc:	740e                	ld	s0,224(sp)
    800056fe:	64ee                	ld	s1,216(sp)
    80005700:	694e                	ld	s2,208(sp)
    80005702:	69ae                	ld	s3,200(sp)
    80005704:	616d                	addi	sp,sp,240
    80005706:	8082                	ret

0000000080005708 <sys_open>:

uint64
sys_open(void)
{
    80005708:	7131                	addi	sp,sp,-192
    8000570a:	fd06                	sd	ra,184(sp)
    8000570c:	f922                	sd	s0,176(sp)
    8000570e:	f526                	sd	s1,168(sp)
    80005710:	f14a                	sd	s2,160(sp)
    80005712:	ed4e                	sd	s3,152(sp)
    80005714:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005716:	f4c40593          	addi	a1,s0,-180
    8000571a:	4505                	li	a0,1
    8000571c:	ffffd097          	auipc	ra,0xffffd
    80005720:	4b4080e7          	jalr	1204(ra) # 80002bd0 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005724:	08000613          	li	a2,128
    80005728:	f5040593          	addi	a1,s0,-176
    8000572c:	4501                	li	a0,0
    8000572e:	ffffd097          	auipc	ra,0xffffd
    80005732:	4e2080e7          	jalr	1250(ra) # 80002c10 <argstr>
    80005736:	87aa                	mv	a5,a0
    return -1;
    80005738:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000573a:	0a07c963          	bltz	a5,800057ec <sys_open+0xe4>

  begin_op();
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	9ea080e7          	jalr	-1558(ra) # 80004128 <begin_op>

  if(omode & O_CREATE){
    80005746:	f4c42783          	lw	a5,-180(s0)
    8000574a:	2007f793          	andi	a5,a5,512
    8000574e:	cfc5                	beqz	a5,80005806 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005750:	4681                	li	a3,0
    80005752:	4601                	li	a2,0
    80005754:	4589                	li	a1,2
    80005756:	f5040513          	addi	a0,s0,-176
    8000575a:	00000097          	auipc	ra,0x0
    8000575e:	976080e7          	jalr	-1674(ra) # 800050d0 <create>
    80005762:	84aa                	mv	s1,a0
    if(ip == 0){
    80005764:	c959                	beqz	a0,800057fa <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005766:	04449703          	lh	a4,68(s1)
    8000576a:	478d                	li	a5,3
    8000576c:	00f71763          	bne	a4,a5,8000577a <sys_open+0x72>
    80005770:	0464d703          	lhu	a4,70(s1)
    80005774:	47a5                	li	a5,9
    80005776:	0ce7ed63          	bltu	a5,a4,80005850 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	dbe080e7          	jalr	-578(ra) # 80004538 <filealloc>
    80005782:	89aa                	mv	s3,a0
    80005784:	10050363          	beqz	a0,8000588a <sys_open+0x182>
    80005788:	00000097          	auipc	ra,0x0
    8000578c:	906080e7          	jalr	-1786(ra) # 8000508e <fdalloc>
    80005790:	892a                	mv	s2,a0
    80005792:	0e054763          	bltz	a0,80005880 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005796:	04449703          	lh	a4,68(s1)
    8000579a:	478d                	li	a5,3
    8000579c:	0cf70563          	beq	a4,a5,80005866 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057a0:	4789                	li	a5,2
    800057a2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057a6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057aa:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057ae:	f4c42783          	lw	a5,-180(s0)
    800057b2:	0017c713          	xori	a4,a5,1
    800057b6:	8b05                	andi	a4,a4,1
    800057b8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057bc:	0037f713          	andi	a4,a5,3
    800057c0:	00e03733          	snez	a4,a4
    800057c4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057c8:	4007f793          	andi	a5,a5,1024
    800057cc:	c791                	beqz	a5,800057d8 <sys_open+0xd0>
    800057ce:	04449703          	lh	a4,68(s1)
    800057d2:	4789                	li	a5,2
    800057d4:	0af70063          	beq	a4,a5,80005874 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	04e080e7          	jalr	78(ra) # 80003828 <iunlock>
  end_op();
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	9c6080e7          	jalr	-1594(ra) # 800041a8 <end_op>

  return fd;
    800057ea:	854a                	mv	a0,s2
}
    800057ec:	70ea                	ld	ra,184(sp)
    800057ee:	744a                	ld	s0,176(sp)
    800057f0:	74aa                	ld	s1,168(sp)
    800057f2:	790a                	ld	s2,160(sp)
    800057f4:	69ea                	ld	s3,152(sp)
    800057f6:	6129                	addi	sp,sp,192
    800057f8:	8082                	ret
      end_op();
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	9ae080e7          	jalr	-1618(ra) # 800041a8 <end_op>
      return -1;
    80005802:	557d                	li	a0,-1
    80005804:	b7e5                	j	800057ec <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005806:	f5040513          	addi	a0,s0,-176
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	702080e7          	jalr	1794(ra) # 80003f0c <namei>
    80005812:	84aa                	mv	s1,a0
    80005814:	c905                	beqz	a0,80005844 <sys_open+0x13c>
    ilock(ip);
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	f50080e7          	jalr	-176(ra) # 80003766 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000581e:	04449703          	lh	a4,68(s1)
    80005822:	4785                	li	a5,1
    80005824:	f4f711e3          	bne	a4,a5,80005766 <sys_open+0x5e>
    80005828:	f4c42783          	lw	a5,-180(s0)
    8000582c:	d7b9                	beqz	a5,8000577a <sys_open+0x72>
      iunlockput(ip);
    8000582e:	8526                	mv	a0,s1
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	198080e7          	jalr	408(ra) # 800039c8 <iunlockput>
      end_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	970080e7          	jalr	-1680(ra) # 800041a8 <end_op>
      return -1;
    80005840:	557d                	li	a0,-1
    80005842:	b76d                	j	800057ec <sys_open+0xe4>
      end_op();
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	964080e7          	jalr	-1692(ra) # 800041a8 <end_op>
      return -1;
    8000584c:	557d                	li	a0,-1
    8000584e:	bf79                	j	800057ec <sys_open+0xe4>
    iunlockput(ip);
    80005850:	8526                	mv	a0,s1
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	176080e7          	jalr	374(ra) # 800039c8 <iunlockput>
    end_op();
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	94e080e7          	jalr	-1714(ra) # 800041a8 <end_op>
    return -1;
    80005862:	557d                	li	a0,-1
    80005864:	b761                	j	800057ec <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005866:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000586a:	04649783          	lh	a5,70(s1)
    8000586e:	02f99223          	sh	a5,36(s3)
    80005872:	bf25                	j	800057aa <sys_open+0xa2>
    itrunc(ip);
    80005874:	8526                	mv	a0,s1
    80005876:	ffffe097          	auipc	ra,0xffffe
    8000587a:	ffe080e7          	jalr	-2(ra) # 80003874 <itrunc>
    8000587e:	bfa9                	j	800057d8 <sys_open+0xd0>
      fileclose(f);
    80005880:	854e                	mv	a0,s3
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	d72080e7          	jalr	-654(ra) # 800045f4 <fileclose>
    iunlockput(ip);
    8000588a:	8526                	mv	a0,s1
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	13c080e7          	jalr	316(ra) # 800039c8 <iunlockput>
    end_op();
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	914080e7          	jalr	-1772(ra) # 800041a8 <end_op>
    return -1;
    8000589c:	557d                	li	a0,-1
    8000589e:	b7b9                	j	800057ec <sys_open+0xe4>

00000000800058a0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058a0:	7175                	addi	sp,sp,-144
    800058a2:	e506                	sd	ra,136(sp)
    800058a4:	e122                	sd	s0,128(sp)
    800058a6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	880080e7          	jalr	-1920(ra) # 80004128 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058b0:	08000613          	li	a2,128
    800058b4:	f7040593          	addi	a1,s0,-144
    800058b8:	4501                	li	a0,0
    800058ba:	ffffd097          	auipc	ra,0xffffd
    800058be:	356080e7          	jalr	854(ra) # 80002c10 <argstr>
    800058c2:	02054963          	bltz	a0,800058f4 <sys_mkdir+0x54>
    800058c6:	4681                	li	a3,0
    800058c8:	4601                	li	a2,0
    800058ca:	4585                	li	a1,1
    800058cc:	f7040513          	addi	a0,s0,-144
    800058d0:	00000097          	auipc	ra,0x0
    800058d4:	800080e7          	jalr	-2048(ra) # 800050d0 <create>
    800058d8:	cd11                	beqz	a0,800058f4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	0ee080e7          	jalr	238(ra) # 800039c8 <iunlockput>
  end_op();
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	8c6080e7          	jalr	-1850(ra) # 800041a8 <end_op>
  return 0;
    800058ea:	4501                	li	a0,0
}
    800058ec:	60aa                	ld	ra,136(sp)
    800058ee:	640a                	ld	s0,128(sp)
    800058f0:	6149                	addi	sp,sp,144
    800058f2:	8082                	ret
    end_op();
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	8b4080e7          	jalr	-1868(ra) # 800041a8 <end_op>
    return -1;
    800058fc:	557d                	li	a0,-1
    800058fe:	b7fd                	j	800058ec <sys_mkdir+0x4c>

0000000080005900 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005900:	7135                	addi	sp,sp,-160
    80005902:	ed06                	sd	ra,152(sp)
    80005904:	e922                	sd	s0,144(sp)
    80005906:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	820080e7          	jalr	-2016(ra) # 80004128 <begin_op>
  argint(1, &major);
    80005910:	f6c40593          	addi	a1,s0,-148
    80005914:	4505                	li	a0,1
    80005916:	ffffd097          	auipc	ra,0xffffd
    8000591a:	2ba080e7          	jalr	698(ra) # 80002bd0 <argint>
  argint(2, &minor);
    8000591e:	f6840593          	addi	a1,s0,-152
    80005922:	4509                	li	a0,2
    80005924:	ffffd097          	auipc	ra,0xffffd
    80005928:	2ac080e7          	jalr	684(ra) # 80002bd0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000592c:	08000613          	li	a2,128
    80005930:	f7040593          	addi	a1,s0,-144
    80005934:	4501                	li	a0,0
    80005936:	ffffd097          	auipc	ra,0xffffd
    8000593a:	2da080e7          	jalr	730(ra) # 80002c10 <argstr>
    8000593e:	02054b63          	bltz	a0,80005974 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005942:	f6841683          	lh	a3,-152(s0)
    80005946:	f6c41603          	lh	a2,-148(s0)
    8000594a:	458d                	li	a1,3
    8000594c:	f7040513          	addi	a0,s0,-144
    80005950:	fffff097          	auipc	ra,0xfffff
    80005954:	780080e7          	jalr	1920(ra) # 800050d0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005958:	cd11                	beqz	a0,80005974 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	06e080e7          	jalr	110(ra) # 800039c8 <iunlockput>
  end_op();
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	846080e7          	jalr	-1978(ra) # 800041a8 <end_op>
  return 0;
    8000596a:	4501                	li	a0,0
}
    8000596c:	60ea                	ld	ra,152(sp)
    8000596e:	644a                	ld	s0,144(sp)
    80005970:	610d                	addi	sp,sp,160
    80005972:	8082                	ret
    end_op();
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	834080e7          	jalr	-1996(ra) # 800041a8 <end_op>
    return -1;
    8000597c:	557d                	li	a0,-1
    8000597e:	b7fd                	j	8000596c <sys_mknod+0x6c>

0000000080005980 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005980:	7135                	addi	sp,sp,-160
    80005982:	ed06                	sd	ra,152(sp)
    80005984:	e922                	sd	s0,144(sp)
    80005986:	e526                	sd	s1,136(sp)
    80005988:	e14a                	sd	s2,128(sp)
    8000598a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000598c:	ffffc097          	auipc	ra,0xffffc
    80005990:	06c080e7          	jalr	108(ra) # 800019f8 <myproc>
    80005994:	892a                	mv	s2,a0
  
  begin_op();
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	792080e7          	jalr	1938(ra) # 80004128 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000599e:	08000613          	li	a2,128
    800059a2:	f6040593          	addi	a1,s0,-160
    800059a6:	4501                	li	a0,0
    800059a8:	ffffd097          	auipc	ra,0xffffd
    800059ac:	268080e7          	jalr	616(ra) # 80002c10 <argstr>
    800059b0:	04054b63          	bltz	a0,80005a06 <sys_chdir+0x86>
    800059b4:	f6040513          	addi	a0,s0,-160
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	554080e7          	jalr	1364(ra) # 80003f0c <namei>
    800059c0:	84aa                	mv	s1,a0
    800059c2:	c131                	beqz	a0,80005a06 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	da2080e7          	jalr	-606(ra) # 80003766 <ilock>
  if(ip->type != T_DIR){
    800059cc:	04449703          	lh	a4,68(s1)
    800059d0:	4785                	li	a5,1
    800059d2:	04f71063          	bne	a4,a5,80005a12 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059d6:	8526                	mv	a0,s1
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	e50080e7          	jalr	-432(ra) # 80003828 <iunlock>
  iput(p->cwd);
    800059e0:	15093503          	ld	a0,336(s2)
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	f3c080e7          	jalr	-196(ra) # 80003920 <iput>
  end_op();
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	7bc080e7          	jalr	1980(ra) # 800041a8 <end_op>
  p->cwd = ip;
    800059f4:	14993823          	sd	s1,336(s2)
  return 0;
    800059f8:	4501                	li	a0,0
}
    800059fa:	60ea                	ld	ra,152(sp)
    800059fc:	644a                	ld	s0,144(sp)
    800059fe:	64aa                	ld	s1,136(sp)
    80005a00:	690a                	ld	s2,128(sp)
    80005a02:	610d                	addi	sp,sp,160
    80005a04:	8082                	ret
    end_op();
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	7a2080e7          	jalr	1954(ra) # 800041a8 <end_op>
    return -1;
    80005a0e:	557d                	li	a0,-1
    80005a10:	b7ed                	j	800059fa <sys_chdir+0x7a>
    iunlockput(ip);
    80005a12:	8526                	mv	a0,s1
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	fb4080e7          	jalr	-76(ra) # 800039c8 <iunlockput>
    end_op();
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	78c080e7          	jalr	1932(ra) # 800041a8 <end_op>
    return -1;
    80005a24:	557d                	li	a0,-1
    80005a26:	bfd1                	j	800059fa <sys_chdir+0x7a>

0000000080005a28 <sys_exec>:

uint64
sys_exec(void)
{
    80005a28:	7145                	addi	sp,sp,-464
    80005a2a:	e786                	sd	ra,456(sp)
    80005a2c:	e3a2                	sd	s0,448(sp)
    80005a2e:	ff26                	sd	s1,440(sp)
    80005a30:	fb4a                	sd	s2,432(sp)
    80005a32:	f74e                	sd	s3,424(sp)
    80005a34:	f352                	sd	s4,416(sp)
    80005a36:	ef56                	sd	s5,408(sp)
    80005a38:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a3a:	e3840593          	addi	a1,s0,-456
    80005a3e:	4505                	li	a0,1
    80005a40:	ffffd097          	auipc	ra,0xffffd
    80005a44:	1b0080e7          	jalr	432(ra) # 80002bf0 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a48:	08000613          	li	a2,128
    80005a4c:	f4040593          	addi	a1,s0,-192
    80005a50:	4501                	li	a0,0
    80005a52:	ffffd097          	auipc	ra,0xffffd
    80005a56:	1be080e7          	jalr	446(ra) # 80002c10 <argstr>
    80005a5a:	87aa                	mv	a5,a0
    return -1;
    80005a5c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a5e:	0c07c263          	bltz	a5,80005b22 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a62:	10000613          	li	a2,256
    80005a66:	4581                	li	a1,0
    80005a68:	e4040513          	addi	a0,s0,-448
    80005a6c:	ffffb097          	auipc	ra,0xffffb
    80005a70:	2b2080e7          	jalr	690(ra) # 80000d1e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a74:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a78:	89a6                	mv	s3,s1
    80005a7a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a7c:	02000a13          	li	s4,32
    80005a80:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a84:	00391793          	slli	a5,s2,0x3
    80005a88:	e3040593          	addi	a1,s0,-464
    80005a8c:	e3843503          	ld	a0,-456(s0)
    80005a90:	953e                	add	a0,a0,a5
    80005a92:	ffffd097          	auipc	ra,0xffffd
    80005a96:	0a0080e7          	jalr	160(ra) # 80002b32 <fetchaddr>
    80005a9a:	02054a63          	bltz	a0,80005ace <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005a9e:	e3043783          	ld	a5,-464(s0)
    80005aa2:	c3b9                	beqz	a5,80005ae8 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005aa4:	ffffb097          	auipc	ra,0xffffb
    80005aa8:	042080e7          	jalr	66(ra) # 80000ae6 <kalloc>
    80005aac:	85aa                	mv	a1,a0
    80005aae:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ab2:	cd11                	beqz	a0,80005ace <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ab4:	6605                	lui	a2,0x1
    80005ab6:	e3043503          	ld	a0,-464(s0)
    80005aba:	ffffd097          	auipc	ra,0xffffd
    80005abe:	0ca080e7          	jalr	202(ra) # 80002b84 <fetchstr>
    80005ac2:	00054663          	bltz	a0,80005ace <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005ac6:	0905                	addi	s2,s2,1
    80005ac8:	09a1                	addi	s3,s3,8
    80005aca:	fb491be3          	bne	s2,s4,80005a80 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ace:	10048913          	addi	s2,s1,256
    80005ad2:	6088                	ld	a0,0(s1)
    80005ad4:	c531                	beqz	a0,80005b20 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ad6:	ffffb097          	auipc	ra,0xffffb
    80005ada:	f14080e7          	jalr	-236(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ade:	04a1                	addi	s1,s1,8
    80005ae0:	ff2499e3          	bne	s1,s2,80005ad2 <sys_exec+0xaa>
  return -1;
    80005ae4:	557d                	li	a0,-1
    80005ae6:	a835                	j	80005b22 <sys_exec+0xfa>
      argv[i] = 0;
    80005ae8:	0a8e                	slli	s5,s5,0x3
    80005aea:	fc040793          	addi	a5,s0,-64
    80005aee:	9abe                	add	s5,s5,a5
    80005af0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005af4:	e4040593          	addi	a1,s0,-448
    80005af8:	f4040513          	addi	a0,s0,-192
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	172080e7          	jalr	370(ra) # 80004c6e <exec>
    80005b04:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b06:	10048993          	addi	s3,s1,256
    80005b0a:	6088                	ld	a0,0(s1)
    80005b0c:	c901                	beqz	a0,80005b1c <sys_exec+0xf4>
    kfree(argv[i]);
    80005b0e:	ffffb097          	auipc	ra,0xffffb
    80005b12:	edc080e7          	jalr	-292(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b16:	04a1                	addi	s1,s1,8
    80005b18:	ff3499e3          	bne	s1,s3,80005b0a <sys_exec+0xe2>
  return ret;
    80005b1c:	854a                	mv	a0,s2
    80005b1e:	a011                	j	80005b22 <sys_exec+0xfa>
  return -1;
    80005b20:	557d                	li	a0,-1
}
    80005b22:	60be                	ld	ra,456(sp)
    80005b24:	641e                	ld	s0,448(sp)
    80005b26:	74fa                	ld	s1,440(sp)
    80005b28:	795a                	ld	s2,432(sp)
    80005b2a:	79ba                	ld	s3,424(sp)
    80005b2c:	7a1a                	ld	s4,416(sp)
    80005b2e:	6afa                	ld	s5,408(sp)
    80005b30:	6179                	addi	sp,sp,464
    80005b32:	8082                	ret

0000000080005b34 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b34:	7139                	addi	sp,sp,-64
    80005b36:	fc06                	sd	ra,56(sp)
    80005b38:	f822                	sd	s0,48(sp)
    80005b3a:	f426                	sd	s1,40(sp)
    80005b3c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b3e:	ffffc097          	auipc	ra,0xffffc
    80005b42:	eba080e7          	jalr	-326(ra) # 800019f8 <myproc>
    80005b46:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b48:	fd840593          	addi	a1,s0,-40
    80005b4c:	4501                	li	a0,0
    80005b4e:	ffffd097          	auipc	ra,0xffffd
    80005b52:	0a2080e7          	jalr	162(ra) # 80002bf0 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b56:	fc840593          	addi	a1,s0,-56
    80005b5a:	fd040513          	addi	a0,s0,-48
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	dc6080e7          	jalr	-570(ra) # 80004924 <pipealloc>
    return -1;
    80005b66:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b68:	0c054463          	bltz	a0,80005c30 <sys_pipe+0xfc>
  fd0 = -1;
    80005b6c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b70:	fd043503          	ld	a0,-48(s0)
    80005b74:	fffff097          	auipc	ra,0xfffff
    80005b78:	51a080e7          	jalr	1306(ra) # 8000508e <fdalloc>
    80005b7c:	fca42223          	sw	a0,-60(s0)
    80005b80:	08054b63          	bltz	a0,80005c16 <sys_pipe+0xe2>
    80005b84:	fc843503          	ld	a0,-56(s0)
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	506080e7          	jalr	1286(ra) # 8000508e <fdalloc>
    80005b90:	fca42023          	sw	a0,-64(s0)
    80005b94:	06054863          	bltz	a0,80005c04 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b98:	4691                	li	a3,4
    80005b9a:	fc440613          	addi	a2,s0,-60
    80005b9e:	fd843583          	ld	a1,-40(s0)
    80005ba2:	68a8                	ld	a0,80(s1)
    80005ba4:	ffffc097          	auipc	ra,0xffffc
    80005ba8:	b10080e7          	jalr	-1264(ra) # 800016b4 <copyout>
    80005bac:	02054063          	bltz	a0,80005bcc <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bb0:	4691                	li	a3,4
    80005bb2:	fc040613          	addi	a2,s0,-64
    80005bb6:	fd843583          	ld	a1,-40(s0)
    80005bba:	0591                	addi	a1,a1,4
    80005bbc:	68a8                	ld	a0,80(s1)
    80005bbe:	ffffc097          	auipc	ra,0xffffc
    80005bc2:	af6080e7          	jalr	-1290(ra) # 800016b4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bc6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bc8:	06055463          	bgez	a0,80005c30 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005bcc:	fc442783          	lw	a5,-60(s0)
    80005bd0:	07e9                	addi	a5,a5,26
    80005bd2:	078e                	slli	a5,a5,0x3
    80005bd4:	97a6                	add	a5,a5,s1
    80005bd6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bda:	fc042503          	lw	a0,-64(s0)
    80005bde:	0569                	addi	a0,a0,26
    80005be0:	050e                	slli	a0,a0,0x3
    80005be2:	94aa                	add	s1,s1,a0
    80005be4:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005be8:	fd043503          	ld	a0,-48(s0)
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	a08080e7          	jalr	-1528(ra) # 800045f4 <fileclose>
    fileclose(wf);
    80005bf4:	fc843503          	ld	a0,-56(s0)
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	9fc080e7          	jalr	-1540(ra) # 800045f4 <fileclose>
    return -1;
    80005c00:	57fd                	li	a5,-1
    80005c02:	a03d                	j	80005c30 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c04:	fc442783          	lw	a5,-60(s0)
    80005c08:	0007c763          	bltz	a5,80005c16 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c0c:	07e9                	addi	a5,a5,26
    80005c0e:	078e                	slli	a5,a5,0x3
    80005c10:	94be                	add	s1,s1,a5
    80005c12:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c16:	fd043503          	ld	a0,-48(s0)
    80005c1a:	fffff097          	auipc	ra,0xfffff
    80005c1e:	9da080e7          	jalr	-1574(ra) # 800045f4 <fileclose>
    fileclose(wf);
    80005c22:	fc843503          	ld	a0,-56(s0)
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	9ce080e7          	jalr	-1586(ra) # 800045f4 <fileclose>
    return -1;
    80005c2e:	57fd                	li	a5,-1
}
    80005c30:	853e                	mv	a0,a5
    80005c32:	70e2                	ld	ra,56(sp)
    80005c34:	7442                	ld	s0,48(sp)
    80005c36:	74a2                	ld	s1,40(sp)
    80005c38:	6121                	addi	sp,sp,64
    80005c3a:	8082                	ret
    80005c3c:	0000                	unimp
	...

0000000080005c40 <kernelvec>:
    80005c40:	7111                	addi	sp,sp,-256
    80005c42:	e006                	sd	ra,0(sp)
    80005c44:	e40a                	sd	sp,8(sp)
    80005c46:	e80e                	sd	gp,16(sp)
    80005c48:	ec12                	sd	tp,24(sp)
    80005c4a:	f016                	sd	t0,32(sp)
    80005c4c:	f41a                	sd	t1,40(sp)
    80005c4e:	f81e                	sd	t2,48(sp)
    80005c50:	fc22                	sd	s0,56(sp)
    80005c52:	e0a6                	sd	s1,64(sp)
    80005c54:	e4aa                	sd	a0,72(sp)
    80005c56:	e8ae                	sd	a1,80(sp)
    80005c58:	ecb2                	sd	a2,88(sp)
    80005c5a:	f0b6                	sd	a3,96(sp)
    80005c5c:	f4ba                	sd	a4,104(sp)
    80005c5e:	f8be                	sd	a5,112(sp)
    80005c60:	fcc2                	sd	a6,120(sp)
    80005c62:	e146                	sd	a7,128(sp)
    80005c64:	e54a                	sd	s2,136(sp)
    80005c66:	e94e                	sd	s3,144(sp)
    80005c68:	ed52                	sd	s4,152(sp)
    80005c6a:	f156                	sd	s5,160(sp)
    80005c6c:	f55a                	sd	s6,168(sp)
    80005c6e:	f95e                	sd	s7,176(sp)
    80005c70:	fd62                	sd	s8,184(sp)
    80005c72:	e1e6                	sd	s9,192(sp)
    80005c74:	e5ea                	sd	s10,200(sp)
    80005c76:	e9ee                	sd	s11,208(sp)
    80005c78:	edf2                	sd	t3,216(sp)
    80005c7a:	f1f6                	sd	t4,224(sp)
    80005c7c:	f5fa                	sd	t5,232(sp)
    80005c7e:	f9fe                	sd	t6,240(sp)
    80005c80:	d7ffc0ef          	jal	ra,800029fe <kerneltrap>
    80005c84:	6082                	ld	ra,0(sp)
    80005c86:	6122                	ld	sp,8(sp)
    80005c88:	61c2                	ld	gp,16(sp)
    80005c8a:	7282                	ld	t0,32(sp)
    80005c8c:	7322                	ld	t1,40(sp)
    80005c8e:	73c2                	ld	t2,48(sp)
    80005c90:	7462                	ld	s0,56(sp)
    80005c92:	6486                	ld	s1,64(sp)
    80005c94:	6526                	ld	a0,72(sp)
    80005c96:	65c6                	ld	a1,80(sp)
    80005c98:	6666                	ld	a2,88(sp)
    80005c9a:	7686                	ld	a3,96(sp)
    80005c9c:	7726                	ld	a4,104(sp)
    80005c9e:	77c6                	ld	a5,112(sp)
    80005ca0:	7866                	ld	a6,120(sp)
    80005ca2:	688a                	ld	a7,128(sp)
    80005ca4:	692a                	ld	s2,136(sp)
    80005ca6:	69ca                	ld	s3,144(sp)
    80005ca8:	6a6a                	ld	s4,152(sp)
    80005caa:	7a8a                	ld	s5,160(sp)
    80005cac:	7b2a                	ld	s6,168(sp)
    80005cae:	7bca                	ld	s7,176(sp)
    80005cb0:	7c6a                	ld	s8,184(sp)
    80005cb2:	6c8e                	ld	s9,192(sp)
    80005cb4:	6d2e                	ld	s10,200(sp)
    80005cb6:	6dce                	ld	s11,208(sp)
    80005cb8:	6e6e                	ld	t3,216(sp)
    80005cba:	7e8e                	ld	t4,224(sp)
    80005cbc:	7f2e                	ld	t5,232(sp)
    80005cbe:	7fce                	ld	t6,240(sp)
    80005cc0:	6111                	addi	sp,sp,256
    80005cc2:	10200073          	sret
    80005cc6:	00000013          	nop
    80005cca:	00000013          	nop
    80005cce:	0001                	nop

0000000080005cd0 <timervec>:
    80005cd0:	34051573          	csrrw	a0,mscratch,a0
    80005cd4:	e10c                	sd	a1,0(a0)
    80005cd6:	e510                	sd	a2,8(a0)
    80005cd8:	e914                	sd	a3,16(a0)
    80005cda:	6d0c                	ld	a1,24(a0)
    80005cdc:	7110                	ld	a2,32(a0)
    80005cde:	6194                	ld	a3,0(a1)
    80005ce0:	96b2                	add	a3,a3,a2
    80005ce2:	e194                	sd	a3,0(a1)
    80005ce4:	4589                	li	a1,2
    80005ce6:	14459073          	csrw	sip,a1
    80005cea:	6914                	ld	a3,16(a0)
    80005cec:	6510                	ld	a2,8(a0)
    80005cee:	610c                	ld	a1,0(a0)
    80005cf0:	34051573          	csrrw	a0,mscratch,a0
    80005cf4:	30200073          	mret
	...

0000000080005cfa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cfa:	1141                	addi	sp,sp,-16
    80005cfc:	e422                	sd	s0,8(sp)
    80005cfe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d00:	0c0007b7          	lui	a5,0xc000
    80005d04:	4705                	li	a4,1
    80005d06:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d08:	c3d8                	sw	a4,4(a5)
}
    80005d0a:	6422                	ld	s0,8(sp)
    80005d0c:	0141                	addi	sp,sp,16
    80005d0e:	8082                	ret

0000000080005d10 <plicinithart>:

void
plicinithart(void)
{
    80005d10:	1141                	addi	sp,sp,-16
    80005d12:	e406                	sd	ra,8(sp)
    80005d14:	e022                	sd	s0,0(sp)
    80005d16:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d18:	ffffc097          	auipc	ra,0xffffc
    80005d1c:	cb4080e7          	jalr	-844(ra) # 800019cc <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d20:	0085171b          	slliw	a4,a0,0x8
    80005d24:	0c0027b7          	lui	a5,0xc002
    80005d28:	97ba                	add	a5,a5,a4
    80005d2a:	40200713          	li	a4,1026
    80005d2e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d32:	00d5151b          	slliw	a0,a0,0xd
    80005d36:	0c2017b7          	lui	a5,0xc201
    80005d3a:	953e                	add	a0,a0,a5
    80005d3c:	00052023          	sw	zero,0(a0)
}
    80005d40:	60a2                	ld	ra,8(sp)
    80005d42:	6402                	ld	s0,0(sp)
    80005d44:	0141                	addi	sp,sp,16
    80005d46:	8082                	ret

0000000080005d48 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d48:	1141                	addi	sp,sp,-16
    80005d4a:	e406                	sd	ra,8(sp)
    80005d4c:	e022                	sd	s0,0(sp)
    80005d4e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d50:	ffffc097          	auipc	ra,0xffffc
    80005d54:	c7c080e7          	jalr	-900(ra) # 800019cc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d58:	00d5179b          	slliw	a5,a0,0xd
    80005d5c:	0c201537          	lui	a0,0xc201
    80005d60:	953e                	add	a0,a0,a5
  return irq;
}
    80005d62:	4148                	lw	a0,4(a0)
    80005d64:	60a2                	ld	ra,8(sp)
    80005d66:	6402                	ld	s0,0(sp)
    80005d68:	0141                	addi	sp,sp,16
    80005d6a:	8082                	ret

0000000080005d6c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d6c:	1101                	addi	sp,sp,-32
    80005d6e:	ec06                	sd	ra,24(sp)
    80005d70:	e822                	sd	s0,16(sp)
    80005d72:	e426                	sd	s1,8(sp)
    80005d74:	1000                	addi	s0,sp,32
    80005d76:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d78:	ffffc097          	auipc	ra,0xffffc
    80005d7c:	c54080e7          	jalr	-940(ra) # 800019cc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d80:	00d5151b          	slliw	a0,a0,0xd
    80005d84:	0c2017b7          	lui	a5,0xc201
    80005d88:	97aa                	add	a5,a5,a0
    80005d8a:	c3c4                	sw	s1,4(a5)
}
    80005d8c:	60e2                	ld	ra,24(sp)
    80005d8e:	6442                	ld	s0,16(sp)
    80005d90:	64a2                	ld	s1,8(sp)
    80005d92:	6105                	addi	sp,sp,32
    80005d94:	8082                	ret

0000000080005d96 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d96:	1141                	addi	sp,sp,-16
    80005d98:	e406                	sd	ra,8(sp)
    80005d9a:	e022                	sd	s0,0(sp)
    80005d9c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d9e:	479d                	li	a5,7
    80005da0:	04a7cc63          	blt	a5,a0,80005df8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005da4:	0001c797          	auipc	a5,0x1c
    80005da8:	e6c78793          	addi	a5,a5,-404 # 80021c10 <disk>
    80005dac:	97aa                	add	a5,a5,a0
    80005dae:	0187c783          	lbu	a5,24(a5)
    80005db2:	ebb9                	bnez	a5,80005e08 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005db4:	00451613          	slli	a2,a0,0x4
    80005db8:	0001c797          	auipc	a5,0x1c
    80005dbc:	e5878793          	addi	a5,a5,-424 # 80021c10 <disk>
    80005dc0:	6394                	ld	a3,0(a5)
    80005dc2:	96b2                	add	a3,a3,a2
    80005dc4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005dc8:	6398                	ld	a4,0(a5)
    80005dca:	9732                	add	a4,a4,a2
    80005dcc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005dd0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005dd4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005dd8:	953e                	add	a0,a0,a5
    80005dda:	4785                	li	a5,1
    80005ddc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005de0:	0001c517          	auipc	a0,0x1c
    80005de4:	e4850513          	addi	a0,a0,-440 # 80021c28 <disk+0x18>
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	31c080e7          	jalr	796(ra) # 80002104 <wakeup>
}
    80005df0:	60a2                	ld	ra,8(sp)
    80005df2:	6402                	ld	s0,0(sp)
    80005df4:	0141                	addi	sp,sp,16
    80005df6:	8082                	ret
    panic("free_desc 1");
    80005df8:	00003517          	auipc	a0,0x3
    80005dfc:	95050513          	addi	a0,a0,-1712 # 80008748 <syscalls+0x2f8>
    80005e00:	ffffa097          	auipc	ra,0xffffa
    80005e04:	73e080e7          	jalr	1854(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005e08:	00003517          	auipc	a0,0x3
    80005e0c:	95050513          	addi	a0,a0,-1712 # 80008758 <syscalls+0x308>
    80005e10:	ffffa097          	auipc	ra,0xffffa
    80005e14:	72e080e7          	jalr	1838(ra) # 8000053e <panic>

0000000080005e18 <virtio_disk_init>:
{
    80005e18:	1101                	addi	sp,sp,-32
    80005e1a:	ec06                	sd	ra,24(sp)
    80005e1c:	e822                	sd	s0,16(sp)
    80005e1e:	e426                	sd	s1,8(sp)
    80005e20:	e04a                	sd	s2,0(sp)
    80005e22:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e24:	00003597          	auipc	a1,0x3
    80005e28:	94458593          	addi	a1,a1,-1724 # 80008768 <syscalls+0x318>
    80005e2c:	0001c517          	auipc	a0,0x1c
    80005e30:	f0c50513          	addi	a0,a0,-244 # 80021d38 <disk+0x128>
    80005e34:	ffffb097          	auipc	ra,0xffffb
    80005e38:	d5e080e7          	jalr	-674(ra) # 80000b92 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e3c:	100017b7          	lui	a5,0x10001
    80005e40:	4398                	lw	a4,0(a5)
    80005e42:	2701                	sext.w	a4,a4
    80005e44:	747277b7          	lui	a5,0x74727
    80005e48:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e4c:	14f71c63          	bne	a4,a5,80005fa4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e50:	100017b7          	lui	a5,0x10001
    80005e54:	43dc                	lw	a5,4(a5)
    80005e56:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e58:	4709                	li	a4,2
    80005e5a:	14e79563          	bne	a5,a4,80005fa4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e5e:	100017b7          	lui	a5,0x10001
    80005e62:	479c                	lw	a5,8(a5)
    80005e64:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e66:	12e79f63          	bne	a5,a4,80005fa4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e6a:	100017b7          	lui	a5,0x10001
    80005e6e:	47d8                	lw	a4,12(a5)
    80005e70:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e72:	554d47b7          	lui	a5,0x554d4
    80005e76:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e7a:	12f71563          	bne	a4,a5,80005fa4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e7e:	100017b7          	lui	a5,0x10001
    80005e82:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e86:	4705                	li	a4,1
    80005e88:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8a:	470d                	li	a4,3
    80005e8c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e8e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e90:	c7ffe737          	lui	a4,0xc7ffe
    80005e94:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdca0f>
    80005e98:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e9a:	2701                	sext.w	a4,a4
    80005e9c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e9e:	472d                	li	a4,11
    80005ea0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ea2:	5bbc                	lw	a5,112(a5)
    80005ea4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ea8:	8ba1                	andi	a5,a5,8
    80005eaa:	10078563          	beqz	a5,80005fb4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005eae:	100017b7          	lui	a5,0x10001
    80005eb2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005eb6:	43fc                	lw	a5,68(a5)
    80005eb8:	2781                	sext.w	a5,a5
    80005eba:	10079563          	bnez	a5,80005fc4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ebe:	100017b7          	lui	a5,0x10001
    80005ec2:	5bdc                	lw	a5,52(a5)
    80005ec4:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ec6:	10078763          	beqz	a5,80005fd4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    80005eca:	471d                	li	a4,7
    80005ecc:	10f77c63          	bgeu	a4,a5,80005fe4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80005ed0:	ffffb097          	auipc	ra,0xffffb
    80005ed4:	c16080e7          	jalr	-1002(ra) # 80000ae6 <kalloc>
    80005ed8:	0001c497          	auipc	s1,0x1c
    80005edc:	d3848493          	addi	s1,s1,-712 # 80021c10 <disk>
    80005ee0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005ee2:	ffffb097          	auipc	ra,0xffffb
    80005ee6:	c04080e7          	jalr	-1020(ra) # 80000ae6 <kalloc>
    80005eea:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005eec:	ffffb097          	auipc	ra,0xffffb
    80005ef0:	bfa080e7          	jalr	-1030(ra) # 80000ae6 <kalloc>
    80005ef4:	87aa                	mv	a5,a0
    80005ef6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005ef8:	6088                	ld	a0,0(s1)
    80005efa:	cd6d                	beqz	a0,80005ff4 <virtio_disk_init+0x1dc>
    80005efc:	0001c717          	auipc	a4,0x1c
    80005f00:	d1c73703          	ld	a4,-740(a4) # 80021c18 <disk+0x8>
    80005f04:	cb65                	beqz	a4,80005ff4 <virtio_disk_init+0x1dc>
    80005f06:	c7fd                	beqz	a5,80005ff4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80005f08:	6605                	lui	a2,0x1
    80005f0a:	4581                	li	a1,0
    80005f0c:	ffffb097          	auipc	ra,0xffffb
    80005f10:	e12080e7          	jalr	-494(ra) # 80000d1e <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f14:	0001c497          	auipc	s1,0x1c
    80005f18:	cfc48493          	addi	s1,s1,-772 # 80021c10 <disk>
    80005f1c:	6605                	lui	a2,0x1
    80005f1e:	4581                	li	a1,0
    80005f20:	6488                	ld	a0,8(s1)
    80005f22:	ffffb097          	auipc	ra,0xffffb
    80005f26:	dfc080e7          	jalr	-516(ra) # 80000d1e <memset>
  memset(disk.used, 0, PGSIZE);
    80005f2a:	6605                	lui	a2,0x1
    80005f2c:	4581                	li	a1,0
    80005f2e:	6888                	ld	a0,16(s1)
    80005f30:	ffffb097          	auipc	ra,0xffffb
    80005f34:	dee080e7          	jalr	-530(ra) # 80000d1e <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f38:	100017b7          	lui	a5,0x10001
    80005f3c:	4721                	li	a4,8
    80005f3e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f40:	4098                	lw	a4,0(s1)
    80005f42:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f46:	40d8                	lw	a4,4(s1)
    80005f48:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f4c:	6498                	ld	a4,8(s1)
    80005f4e:	0007069b          	sext.w	a3,a4
    80005f52:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f56:	9701                	srai	a4,a4,0x20
    80005f58:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f5c:	6898                	ld	a4,16(s1)
    80005f5e:	0007069b          	sext.w	a3,a4
    80005f62:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f66:	9701                	srai	a4,a4,0x20
    80005f68:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f6c:	4705                	li	a4,1
    80005f6e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f70:	00e48c23          	sb	a4,24(s1)
    80005f74:	00e48ca3          	sb	a4,25(s1)
    80005f78:	00e48d23          	sb	a4,26(s1)
    80005f7c:	00e48da3          	sb	a4,27(s1)
    80005f80:	00e48e23          	sb	a4,28(s1)
    80005f84:	00e48ea3          	sb	a4,29(s1)
    80005f88:	00e48f23          	sb	a4,30(s1)
    80005f8c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f90:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f94:	0727a823          	sw	s2,112(a5)
}
    80005f98:	60e2                	ld	ra,24(sp)
    80005f9a:	6442                	ld	s0,16(sp)
    80005f9c:	64a2                	ld	s1,8(sp)
    80005f9e:	6902                	ld	s2,0(sp)
    80005fa0:	6105                	addi	sp,sp,32
    80005fa2:	8082                	ret
    panic("could not find virtio disk");
    80005fa4:	00002517          	auipc	a0,0x2
    80005fa8:	7d450513          	addi	a0,a0,2004 # 80008778 <syscalls+0x328>
    80005fac:	ffffa097          	auipc	ra,0xffffa
    80005fb0:	592080e7          	jalr	1426(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80005fb4:	00002517          	auipc	a0,0x2
    80005fb8:	7e450513          	addi	a0,a0,2020 # 80008798 <syscalls+0x348>
    80005fbc:	ffffa097          	auipc	ra,0xffffa
    80005fc0:	582080e7          	jalr	1410(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80005fc4:	00002517          	auipc	a0,0x2
    80005fc8:	7f450513          	addi	a0,a0,2036 # 800087b8 <syscalls+0x368>
    80005fcc:	ffffa097          	auipc	ra,0xffffa
    80005fd0:	572080e7          	jalr	1394(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005fd4:	00003517          	auipc	a0,0x3
    80005fd8:	80450513          	addi	a0,a0,-2044 # 800087d8 <syscalls+0x388>
    80005fdc:	ffffa097          	auipc	ra,0xffffa
    80005fe0:	562080e7          	jalr	1378(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005fe4:	00003517          	auipc	a0,0x3
    80005fe8:	81450513          	addi	a0,a0,-2028 # 800087f8 <syscalls+0x3a8>
    80005fec:	ffffa097          	auipc	ra,0xffffa
    80005ff0:	552080e7          	jalr	1362(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80005ff4:	00003517          	auipc	a0,0x3
    80005ff8:	82450513          	addi	a0,a0,-2012 # 80008818 <syscalls+0x3c8>
    80005ffc:	ffffa097          	auipc	ra,0xffffa
    80006000:	542080e7          	jalr	1346(ra) # 8000053e <panic>

0000000080006004 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006004:	7119                	addi	sp,sp,-128
    80006006:	fc86                	sd	ra,120(sp)
    80006008:	f8a2                	sd	s0,112(sp)
    8000600a:	f4a6                	sd	s1,104(sp)
    8000600c:	f0ca                	sd	s2,96(sp)
    8000600e:	ecce                	sd	s3,88(sp)
    80006010:	e8d2                	sd	s4,80(sp)
    80006012:	e4d6                	sd	s5,72(sp)
    80006014:	e0da                	sd	s6,64(sp)
    80006016:	fc5e                	sd	s7,56(sp)
    80006018:	f862                	sd	s8,48(sp)
    8000601a:	f466                	sd	s9,40(sp)
    8000601c:	f06a                	sd	s10,32(sp)
    8000601e:	ec6e                	sd	s11,24(sp)
    80006020:	0100                	addi	s0,sp,128
    80006022:	8aaa                	mv	s5,a0
    80006024:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006026:	00c52d03          	lw	s10,12(a0)
    8000602a:	001d1d1b          	slliw	s10,s10,0x1
    8000602e:	1d02                	slli	s10,s10,0x20
    80006030:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006034:	0001c517          	auipc	a0,0x1c
    80006038:	d0450513          	addi	a0,a0,-764 # 80021d38 <disk+0x128>
    8000603c:	ffffb097          	auipc	ra,0xffffb
    80006040:	be6080e7          	jalr	-1050(ra) # 80000c22 <acquire>
  for(int i = 0; i < 3; i++){
    80006044:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006046:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006048:	0001cb97          	auipc	s7,0x1c
    8000604c:	bc8b8b93          	addi	s7,s7,-1080 # 80021c10 <disk>
  for(int i = 0; i < 3; i++){
    80006050:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006052:	0001cc97          	auipc	s9,0x1c
    80006056:	ce6c8c93          	addi	s9,s9,-794 # 80021d38 <disk+0x128>
    8000605a:	a08d                	j	800060bc <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000605c:	00fb8733          	add	a4,s7,a5
    80006060:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006064:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006066:	0207c563          	bltz	a5,80006090 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000606a:	2905                	addiw	s2,s2,1
    8000606c:	0611                	addi	a2,a2,4
    8000606e:	05690c63          	beq	s2,s6,800060c6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006072:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006074:	0001c717          	auipc	a4,0x1c
    80006078:	b9c70713          	addi	a4,a4,-1124 # 80021c10 <disk>
    8000607c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000607e:	01874683          	lbu	a3,24(a4)
    80006082:	fee9                	bnez	a3,8000605c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006084:	2785                	addiw	a5,a5,1
    80006086:	0705                	addi	a4,a4,1
    80006088:	fe979be3          	bne	a5,s1,8000607e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000608c:	57fd                	li	a5,-1
    8000608e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006090:	01205d63          	blez	s2,800060aa <virtio_disk_rw+0xa6>
    80006094:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006096:	000a2503          	lw	a0,0(s4)
    8000609a:	00000097          	auipc	ra,0x0
    8000609e:	cfc080e7          	jalr	-772(ra) # 80005d96 <free_desc>
      for(int j = 0; j < i; j++)
    800060a2:	2d85                	addiw	s11,s11,1
    800060a4:	0a11                	addi	s4,s4,4
    800060a6:	ffb918e3          	bne	s2,s11,80006096 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060aa:	85e6                	mv	a1,s9
    800060ac:	0001c517          	auipc	a0,0x1c
    800060b0:	b7c50513          	addi	a0,a0,-1156 # 80021c28 <disk+0x18>
    800060b4:	ffffc097          	auipc	ra,0xffffc
    800060b8:	fec080e7          	jalr	-20(ra) # 800020a0 <sleep>
  for(int i = 0; i < 3; i++){
    800060bc:	f8040a13          	addi	s4,s0,-128
{
    800060c0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800060c2:	894e                	mv	s2,s3
    800060c4:	b77d                	j	80006072 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060c6:	f8042583          	lw	a1,-128(s0)
    800060ca:	00a58793          	addi	a5,a1,10
    800060ce:	0792                	slli	a5,a5,0x4

  if(write)
    800060d0:	0001c617          	auipc	a2,0x1c
    800060d4:	b4060613          	addi	a2,a2,-1216 # 80021c10 <disk>
    800060d8:	00f60733          	add	a4,a2,a5
    800060dc:	018036b3          	snez	a3,s8
    800060e0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800060e2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800060e6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060ea:	f6078693          	addi	a3,a5,-160
    800060ee:	6218                	ld	a4,0(a2)
    800060f0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060f2:	00878513          	addi	a0,a5,8
    800060f6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800060f8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060fa:	6208                	ld	a0,0(a2)
    800060fc:	96aa                	add	a3,a3,a0
    800060fe:	4741                	li	a4,16
    80006100:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006102:	4705                	li	a4,1
    80006104:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006108:	f8442703          	lw	a4,-124(s0)
    8000610c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006110:	0712                	slli	a4,a4,0x4
    80006112:	953a                	add	a0,a0,a4
    80006114:	058a8693          	addi	a3,s5,88
    80006118:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000611a:	6208                	ld	a0,0(a2)
    8000611c:	972a                	add	a4,a4,a0
    8000611e:	40000693          	li	a3,1024
    80006122:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006124:	001c3c13          	seqz	s8,s8
    80006128:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000612a:	001c6c13          	ori	s8,s8,1
    8000612e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006132:	f8842603          	lw	a2,-120(s0)
    80006136:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000613a:	0001c697          	auipc	a3,0x1c
    8000613e:	ad668693          	addi	a3,a3,-1322 # 80021c10 <disk>
    80006142:	00258713          	addi	a4,a1,2
    80006146:	0712                	slli	a4,a4,0x4
    80006148:	9736                	add	a4,a4,a3
    8000614a:	587d                	li	a6,-1
    8000614c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006150:	0612                	slli	a2,a2,0x4
    80006152:	9532                	add	a0,a0,a2
    80006154:	f9078793          	addi	a5,a5,-112
    80006158:	97b6                	add	a5,a5,a3
    8000615a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000615c:	629c                	ld	a5,0(a3)
    8000615e:	97b2                	add	a5,a5,a2
    80006160:	4605                	li	a2,1
    80006162:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006164:	4509                	li	a0,2
    80006166:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000616a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000616e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006172:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006176:	6698                	ld	a4,8(a3)
    80006178:	00275783          	lhu	a5,2(a4)
    8000617c:	8b9d                	andi	a5,a5,7
    8000617e:	0786                	slli	a5,a5,0x1
    80006180:	97ba                	add	a5,a5,a4
    80006182:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006186:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000618a:	6698                	ld	a4,8(a3)
    8000618c:	00275783          	lhu	a5,2(a4)
    80006190:	2785                	addiw	a5,a5,1
    80006192:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006196:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000619a:	100017b7          	lui	a5,0x10001
    8000619e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061a2:	004aa783          	lw	a5,4(s5)
    800061a6:	02c79163          	bne	a5,a2,800061c8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800061aa:	0001c917          	auipc	s2,0x1c
    800061ae:	b8e90913          	addi	s2,s2,-1138 # 80021d38 <disk+0x128>
  while(b->disk == 1) {
    800061b2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061b4:	85ca                	mv	a1,s2
    800061b6:	8556                	mv	a0,s5
    800061b8:	ffffc097          	auipc	ra,0xffffc
    800061bc:	ee8080e7          	jalr	-280(ra) # 800020a0 <sleep>
  while(b->disk == 1) {
    800061c0:	004aa783          	lw	a5,4(s5)
    800061c4:	fe9788e3          	beq	a5,s1,800061b4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800061c8:	f8042903          	lw	s2,-128(s0)
    800061cc:	00290793          	addi	a5,s2,2
    800061d0:	00479713          	slli	a4,a5,0x4
    800061d4:	0001c797          	auipc	a5,0x1c
    800061d8:	a3c78793          	addi	a5,a5,-1476 # 80021c10 <disk>
    800061dc:	97ba                	add	a5,a5,a4
    800061de:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800061e2:	0001c997          	auipc	s3,0x1c
    800061e6:	a2e98993          	addi	s3,s3,-1490 # 80021c10 <disk>
    800061ea:	00491713          	slli	a4,s2,0x4
    800061ee:	0009b783          	ld	a5,0(s3)
    800061f2:	97ba                	add	a5,a5,a4
    800061f4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061f8:	854a                	mv	a0,s2
    800061fa:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061fe:	00000097          	auipc	ra,0x0
    80006202:	b98080e7          	jalr	-1128(ra) # 80005d96 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006206:	8885                	andi	s1,s1,1
    80006208:	f0ed                	bnez	s1,800061ea <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000620a:	0001c517          	auipc	a0,0x1c
    8000620e:	b2e50513          	addi	a0,a0,-1234 # 80021d38 <disk+0x128>
    80006212:	ffffb097          	auipc	ra,0xffffb
    80006216:	ac4080e7          	jalr	-1340(ra) # 80000cd6 <release>
}
    8000621a:	70e6                	ld	ra,120(sp)
    8000621c:	7446                	ld	s0,112(sp)
    8000621e:	74a6                	ld	s1,104(sp)
    80006220:	7906                	ld	s2,96(sp)
    80006222:	69e6                	ld	s3,88(sp)
    80006224:	6a46                	ld	s4,80(sp)
    80006226:	6aa6                	ld	s5,72(sp)
    80006228:	6b06                	ld	s6,64(sp)
    8000622a:	7be2                	ld	s7,56(sp)
    8000622c:	7c42                	ld	s8,48(sp)
    8000622e:	7ca2                	ld	s9,40(sp)
    80006230:	7d02                	ld	s10,32(sp)
    80006232:	6de2                	ld	s11,24(sp)
    80006234:	6109                	addi	sp,sp,128
    80006236:	8082                	ret

0000000080006238 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006238:	1101                	addi	sp,sp,-32
    8000623a:	ec06                	sd	ra,24(sp)
    8000623c:	e822                	sd	s0,16(sp)
    8000623e:	e426                	sd	s1,8(sp)
    80006240:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006242:	0001c497          	auipc	s1,0x1c
    80006246:	9ce48493          	addi	s1,s1,-1586 # 80021c10 <disk>
    8000624a:	0001c517          	auipc	a0,0x1c
    8000624e:	aee50513          	addi	a0,a0,-1298 # 80021d38 <disk+0x128>
    80006252:	ffffb097          	auipc	ra,0xffffb
    80006256:	9d0080e7          	jalr	-1584(ra) # 80000c22 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000625a:	10001737          	lui	a4,0x10001
    8000625e:	533c                	lw	a5,96(a4)
    80006260:	8b8d                	andi	a5,a5,3
    80006262:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006264:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006268:	689c                	ld	a5,16(s1)
    8000626a:	0204d703          	lhu	a4,32(s1)
    8000626e:	0027d783          	lhu	a5,2(a5)
    80006272:	04f70863          	beq	a4,a5,800062c2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006276:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000627a:	6898                	ld	a4,16(s1)
    8000627c:	0204d783          	lhu	a5,32(s1)
    80006280:	8b9d                	andi	a5,a5,7
    80006282:	078e                	slli	a5,a5,0x3
    80006284:	97ba                	add	a5,a5,a4
    80006286:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006288:	00278713          	addi	a4,a5,2
    8000628c:	0712                	slli	a4,a4,0x4
    8000628e:	9726                	add	a4,a4,s1
    80006290:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006294:	e721                	bnez	a4,800062dc <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006296:	0789                	addi	a5,a5,2
    80006298:	0792                	slli	a5,a5,0x4
    8000629a:	97a6                	add	a5,a5,s1
    8000629c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000629e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062a2:	ffffc097          	auipc	ra,0xffffc
    800062a6:	e62080e7          	jalr	-414(ra) # 80002104 <wakeup>

    disk.used_idx += 1;
    800062aa:	0204d783          	lhu	a5,32(s1)
    800062ae:	2785                	addiw	a5,a5,1
    800062b0:	17c2                	slli	a5,a5,0x30
    800062b2:	93c1                	srli	a5,a5,0x30
    800062b4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062b8:	6898                	ld	a4,16(s1)
    800062ba:	00275703          	lhu	a4,2(a4)
    800062be:	faf71ce3          	bne	a4,a5,80006276 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800062c2:	0001c517          	auipc	a0,0x1c
    800062c6:	a7650513          	addi	a0,a0,-1418 # 80021d38 <disk+0x128>
    800062ca:	ffffb097          	auipc	ra,0xffffb
    800062ce:	a0c080e7          	jalr	-1524(ra) # 80000cd6 <release>
}
    800062d2:	60e2                	ld	ra,24(sp)
    800062d4:	6442                	ld	s0,16(sp)
    800062d6:	64a2                	ld	s1,8(sp)
    800062d8:	6105                	addi	sp,sp,32
    800062da:	8082                	ret
      panic("virtio_disk_intr status");
    800062dc:	00002517          	auipc	a0,0x2
    800062e0:	55450513          	addi	a0,a0,1364 # 80008830 <syscalls+0x3e0>
    800062e4:	ffffa097          	auipc	ra,0xffffa
    800062e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
