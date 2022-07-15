
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9f013103          	ld	sp,-1552(sp) # 800089f0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
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
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
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
    80000068:	e1c78793          	addi	a5,a5,-484 # 80005e80 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
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
    80000130:	578080e7          	jalr	1400(ra) # 800026a4 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
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
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f7e080e7          	jalr	-130(ra) # 80002152 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	43e080e7          	jalr	1086(ra) # 8000264e <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

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
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
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
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

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
    800002f6:	408080e7          	jalr	1032(ra) # 800026fa <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
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
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fe4080e7          	jalr	-28(ra) # 8000242a <wakeup>
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
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	4a078793          	addi	a5,a5,1184 # 80021918 <devsw>
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
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
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
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
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
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
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
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
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
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
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
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	b8a080e7          	jalr	-1142(ra) # 8000242a <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	826080e7          	jalr	-2010(ra) # 80002152 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	966080e7          	jalr	-1690(ra) # 8000283a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	fe4080e7          	jalr	-28(ra) # 80005ec0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	068080e7          	jalr	104(ra) # 80001f4c <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	8c6080e7          	jalr	-1850(ra) # 80002812 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	8e6080e7          	jalr	-1818(ra) # 8000283a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	f4e080e7          	jalr	-178(ra) # 80005eaa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	f5c080e7          	jalr	-164(ra) # 80005ec0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	13c080e7          	jalr	316(ra) # 800030a8 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	7cc080e7          	jalr	1996(ra) # 80003740 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	776080e7          	jalr	1910(ra) # 800046f2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	05e080e7          	jalr	94(ra) # 80005fe2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d24080e7          	jalr	-732(ra) # 80001cb0 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	e62a0a13          	addi	s4,s4,-414 # 800176d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if (pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	859d                	srai	a1,a1,0x7
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a8:	18048493          	addi	s1,s1,384
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
  {
    initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
    p->kstack = KSTACK((int)(p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000193a:	00016997          	auipc	s3,0x16
    8000193e:	d9698993          	addi	s3,s3,-618 # 800176d0 <tickslock>
    initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	879d                	srai	a5,a5,0x7
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001968:	18048493          	addi	s1,s1,384
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first)
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	fa07a783          	lw	a5,-96(a5) # 800089a0 <first.1706>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	e48080e7          	jalr	-440(ra) # 80002852 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	f807a323          	sw	zero,-122(a5) # 800089a0 <first.1706>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	c9c080e7          	jalr	-868(ra) # 800036c0 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
{
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	f5878793          	addi	a5,a5,-168 # 800089a4 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	05893683          	ld	a3,88(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6e:	6d28                	ld	a0,88(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7e:	68a8                	ld	a0,80(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	64ac                	ld	a1,72(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	b0a48493          	addi	s1,s1,-1270 # 800116d0 <proc>
    80001bce:	00016917          	auipc	s2,0x16
    80001bd2:	b0290913          	addi	s2,s2,-1278 # 800176d0 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if (p->state == UNUSED)
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bee:	18048493          	addi	s1,s1,384
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a8ad                	j	80001c72 <allocproc+0xb8>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  p->ct = ticks;
    80001c08:	00007797          	auipc	a5,0x7
    80001c0c:	4287a783          	lw	a5,1064(a5) # 80009030 <ticks>
    80001c10:	16f4ae23          	sw	a5,380(s1)
  p->priority = 60;
    80001c14:	03c00793          	li	a5,60
    80001c18:	16f4ac23          	sw	a5,376(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	ed8080e7          	jalr	-296(ra) # 80000af4 <kalloc>
    80001c24:	892a                	mv	s2,a0
    80001c26:	eca8                	sd	a0,88(s1)
    80001c28:	cd21                	beqz	a0,80001c80 <allocproc+0xc6>
  p->pagetable = proc_pagetable(p);
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	e48080e7          	jalr	-440(ra) # 80001a74 <proc_pagetable>
    80001c34:	892a                	mv	s2,a0
    80001c36:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c38:	c125                	beqz	a0,80001c98 <allocproc+0xde>
  memset(&p->context, 0, sizeof(p->context));
    80001c3a:	07000613          	li	a2,112
    80001c3e:	4581                	li	a1,0
    80001c40:	06048513          	addi	a0,s1,96
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	09c080e7          	jalr	156(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c4c:	00000797          	auipc	a5,0x0
    80001c50:	d9c78793          	addi	a5,a5,-612 # 800019e8 <forkret>
    80001c54:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c56:	60bc                	ld	a5,64(s1)
    80001c58:	6705                	lui	a4,0x1
    80001c5a:	97ba                	add	a5,a5,a4
    80001c5c:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c5e:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c62:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c66:	00007797          	auipc	a5,0x7
    80001c6a:	3ca7a783          	lw	a5,970(a5) # 80009030 <ticks>
    80001c6e:	16f4a623          	sw	a5,364(s1)
}
    80001c72:	8526                	mv	a0,s1
    80001c74:	60e2                	ld	ra,24(sp)
    80001c76:	6442                	ld	s0,16(sp)
    80001c78:	64a2                	ld	s1,8(sp)
    80001c7a:	6902                	ld	s2,0(sp)
    80001c7c:	6105                	addi	sp,sp,32
    80001c7e:	8082                	ret
    freeproc(p);
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	ee0080e7          	jalr	-288(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	00c080e7          	jalr	12(ra) # 80000c98 <release>
    return 0;
    80001c94:	84ca                	mv	s1,s2
    80001c96:	bff1                	j	80001c72 <allocproc+0xb8>
    freeproc(p);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	ec8080e7          	jalr	-312(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	ff4080e7          	jalr	-12(ra) # 80000c98 <release>
    return 0;
    80001cac:	84ca                	mv	s1,s2
    80001cae:	b7d1                	j	80001c72 <allocproc+0xb8>

0000000080001cb0 <userinit>:
{
    80001cb0:	1101                	addi	sp,sp,-32
    80001cb2:	ec06                	sd	ra,24(sp)
    80001cb4:	e822                	sd	s0,16(sp)
    80001cb6:	e426                	sd	s1,8(sp)
    80001cb8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	f00080e7          	jalr	-256(ra) # 80001bba <allocproc>
    80001cc2:	84aa                	mv	s1,a0
  initproc = p;
    80001cc4:	00007797          	auipc	a5,0x7
    80001cc8:	36a7b223          	sd	a0,868(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ccc:	03400613          	li	a2,52
    80001cd0:	00007597          	auipc	a1,0x7
    80001cd4:	ce058593          	addi	a1,a1,-800 # 800089b0 <initcode>
    80001cd8:	6928                	ld	a0,80(a0)
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	68e080e7          	jalr	1678(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001ce2:	6785                	lui	a5,0x1
    80001ce4:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ce6:	6cb8                	ld	a4,88(s1)
    80001ce8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cec:	6cb8                	ld	a4,88(s1)
    80001cee:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf0:	4641                	li	a2,16
    80001cf2:	00006597          	auipc	a1,0x6
    80001cf6:	50e58593          	addi	a1,a1,1294 # 80008200 <digits+0x1c0>
    80001cfa:	15848513          	addi	a0,s1,344
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	134080e7          	jalr	308(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d06:	00006517          	auipc	a0,0x6
    80001d0a:	50a50513          	addi	a0,a0,1290 # 80008210 <digits+0x1d0>
    80001d0e:	00002097          	auipc	ra,0x2
    80001d12:	3e0080e7          	jalr	992(ra) # 800040ee <namei>
    80001d16:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d1a:	478d                	li	a5,3
    80001d1c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d1e:	8526                	mv	a0,s1
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	f78080e7          	jalr	-136(ra) # 80000c98 <release>
}
    80001d28:	60e2                	ld	ra,24(sp)
    80001d2a:	6442                	ld	s0,16(sp)
    80001d2c:	64a2                	ld	s1,8(sp)
    80001d2e:	6105                	addi	sp,sp,32
    80001d30:	8082                	ret

0000000080001d32 <growproc>:
{
    80001d32:	1101                	addi	sp,sp,-32
    80001d34:	ec06                	sd	ra,24(sp)
    80001d36:	e822                	sd	s0,16(sp)
    80001d38:	e426                	sd	s1,8(sp)
    80001d3a:	e04a                	sd	s2,0(sp)
    80001d3c:	1000                	addi	s0,sp,32
    80001d3e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	c70080e7          	jalr	-912(ra) # 800019b0 <myproc>
    80001d48:	892a                	mv	s2,a0
  sz = p->sz;
    80001d4a:	652c                	ld	a1,72(a0)
    80001d4c:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001d50:	00904f63          	bgtz	s1,80001d6e <growproc+0x3c>
  else if (n < 0)
    80001d54:	0204cc63          	bltz	s1,80001d8c <growproc+0x5a>
  p->sz = sz;
    80001d58:	1602                	slli	a2,a2,0x20
    80001d5a:	9201                	srli	a2,a2,0x20
    80001d5c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d60:	4501                	li	a0,0
}
    80001d62:	60e2                	ld	ra,24(sp)
    80001d64:	6442                	ld	s0,16(sp)
    80001d66:	64a2                	ld	s1,8(sp)
    80001d68:	6902                	ld	s2,0(sp)
    80001d6a:	6105                	addi	sp,sp,32
    80001d6c:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d6e:	9e25                	addw	a2,a2,s1
    80001d70:	1602                	slli	a2,a2,0x20
    80001d72:	9201                	srli	a2,a2,0x20
    80001d74:	1582                	slli	a1,a1,0x20
    80001d76:	9181                	srli	a1,a1,0x20
    80001d78:	6928                	ld	a0,80(a0)
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	6a8080e7          	jalr	1704(ra) # 80001422 <uvmalloc>
    80001d82:	0005061b          	sext.w	a2,a0
    80001d86:	fa69                	bnez	a2,80001d58 <growproc+0x26>
      return -1;
    80001d88:	557d                	li	a0,-1
    80001d8a:	bfe1                	j	80001d62 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d8c:	9e25                	addw	a2,a2,s1
    80001d8e:	1602                	slli	a2,a2,0x20
    80001d90:	9201                	srli	a2,a2,0x20
    80001d92:	1582                	slli	a1,a1,0x20
    80001d94:	9181                	srli	a1,a1,0x20
    80001d96:	6928                	ld	a0,80(a0)
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	642080e7          	jalr	1602(ra) # 800013da <uvmdealloc>
    80001da0:	0005061b          	sext.w	a2,a0
    80001da4:	bf55                	j	80001d58 <growproc+0x26>

0000000080001da6 <fork>:
{
    80001da6:	7179                	addi	sp,sp,-48
    80001da8:	f406                	sd	ra,40(sp)
    80001daa:	f022                	sd	s0,32(sp)
    80001dac:	ec26                	sd	s1,24(sp)
    80001dae:	e84a                	sd	s2,16(sp)
    80001db0:	e44e                	sd	s3,8(sp)
    80001db2:	e052                	sd	s4,0(sp)
    80001db4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001db6:	00000097          	auipc	ra,0x0
    80001dba:	bfa080e7          	jalr	-1030(ra) # 800019b0 <myproc>
    80001dbe:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001dc0:	00000097          	auipc	ra,0x0
    80001dc4:	dfa080e7          	jalr	-518(ra) # 80001bba <allocproc>
    80001dc8:	12050163          	beqz	a0,80001eea <fork+0x144>
    80001dcc:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dce:	04893603          	ld	a2,72(s2)
    80001dd2:	692c                	ld	a1,80(a0)
    80001dd4:	05093503          	ld	a0,80(s2)
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	796080e7          	jalr	1942(ra) # 8000156e <uvmcopy>
    80001de0:	04054c63          	bltz	a0,80001e38 <fork+0x92>
  np->sz = p->sz;
    80001de4:	04893783          	ld	a5,72(s2)
    80001de8:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    80001dec:	0329bc23          	sd	s2,56(s3)
  *(np->trapframe) = *(p->trapframe);
    80001df0:	05893683          	ld	a3,88(s2)
    80001df4:	87b6                	mv	a5,a3
    80001df6:	0589b703          	ld	a4,88(s3)
    80001dfa:	12068693          	addi	a3,a3,288
    80001dfe:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e02:	6788                	ld	a0,8(a5)
    80001e04:	6b8c                	ld	a1,16(a5)
    80001e06:	6f90                	ld	a2,24(a5)
    80001e08:	01073023          	sd	a6,0(a4)
    80001e0c:	e708                	sd	a0,8(a4)
    80001e0e:	eb0c                	sd	a1,16(a4)
    80001e10:	ef10                	sd	a2,24(a4)
    80001e12:	02078793          	addi	a5,a5,32
    80001e16:	02070713          	addi	a4,a4,32
    80001e1a:	fed792e3          	bne	a5,a3,80001dfe <fork+0x58>
  np->mask = p->mask;
    80001e1e:	17492783          	lw	a5,372(s2)
    80001e22:	16f9aa23          	sw	a5,372(s3)
  np->trapframe->a0 = 0;
    80001e26:	0589b783          	ld	a5,88(s3)
    80001e2a:	0607b823          	sd	zero,112(a5)
    80001e2e:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80001e32:	15000a13          	li	s4,336
    80001e36:	a03d                	j	80001e64 <fork+0xbe>
    freeproc(np);
    80001e38:	854e                	mv	a0,s3
    80001e3a:	00000097          	auipc	ra,0x0
    80001e3e:	d28080e7          	jalr	-728(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e42:	854e                	mv	a0,s3
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	e54080e7          	jalr	-428(ra) # 80000c98 <release>
    return -1;
    80001e4c:	5a7d                	li	s4,-1
    80001e4e:	a069                	j	80001ed8 <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e50:	00003097          	auipc	ra,0x3
    80001e54:	934080e7          	jalr	-1740(ra) # 80004784 <filedup>
    80001e58:	009987b3          	add	a5,s3,s1
    80001e5c:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001e5e:	04a1                	addi	s1,s1,8
    80001e60:	01448763          	beq	s1,s4,80001e6e <fork+0xc8>
    if (p->ofile[i])
    80001e64:	009907b3          	add	a5,s2,s1
    80001e68:	6388                	ld	a0,0(a5)
    80001e6a:	f17d                	bnez	a0,80001e50 <fork+0xaa>
    80001e6c:	bfcd                	j	80001e5e <fork+0xb8>
  np->cwd = idup(p->cwd);
    80001e6e:	15093503          	ld	a0,336(s2)
    80001e72:	00002097          	auipc	ra,0x2
    80001e76:	a88080e7          	jalr	-1400(ra) # 800038fa <idup>
    80001e7a:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e7e:	4641                	li	a2,16
    80001e80:	15890593          	addi	a1,s2,344
    80001e84:	15898513          	addi	a0,s3,344
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	faa080e7          	jalr	-86(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e90:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e94:	854e                	mv	a0,s3
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	e02080e7          	jalr	-510(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e9e:	0000f497          	auipc	s1,0xf
    80001ea2:	41a48493          	addi	s1,s1,1050 # 800112b8 <wait_lock>
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	d3c080e7          	jalr	-708(ra) # 80000be4 <acquire>
  np->parent = p;
    80001eb0:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	de2080e7          	jalr	-542(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ebe:	854e                	mv	a0,s3
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	d24080e7          	jalr	-732(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ec8:	478d                	li	a5,3
    80001eca:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ece:	854e                	mv	a0,s3
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	dc8080e7          	jalr	-568(ra) # 80000c98 <release>
}
    80001ed8:	8552                	mv	a0,s4
    80001eda:	70a2                	ld	ra,40(sp)
    80001edc:	7402                	ld	s0,32(sp)
    80001ede:	64e2                	ld	s1,24(sp)
    80001ee0:	6942                	ld	s2,16(sp)
    80001ee2:	69a2                	ld	s3,8(sp)
    80001ee4:	6a02                	ld	s4,0(sp)
    80001ee6:	6145                	addi	sp,sp,48
    80001ee8:	8082                	ret
    return -1;
    80001eea:	5a7d                	li	s4,-1
    80001eec:	b7f5                	j	80001ed8 <fork+0x132>

0000000080001eee <update_time>:
{
    80001eee:	7179                	addi	sp,sp,-48
    80001ef0:	f406                	sd	ra,40(sp)
    80001ef2:	f022                	sd	s0,32(sp)
    80001ef4:	ec26                	sd	s1,24(sp)
    80001ef6:	e84a                	sd	s2,16(sp)
    80001ef8:	e44e                	sd	s3,8(sp)
    80001efa:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80001efc:	0000f497          	auipc	s1,0xf
    80001f00:	7d448493          	addi	s1,s1,2004 # 800116d0 <proc>
    if (p->state == RUNNING)
    80001f04:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80001f06:	00015917          	auipc	s2,0x15
    80001f0a:	7ca90913          	addi	s2,s2,1994 # 800176d0 <tickslock>
    80001f0e:	a811                	j	80001f22 <update_time+0x34>
    release(&p->lock);
    80001f10:	8526                	mv	a0,s1
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	d86080e7          	jalr	-634(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001f1a:	18048493          	addi	s1,s1,384
    80001f1e:	03248063          	beq	s1,s2,80001f3e <update_time+0x50>
    acquire(&p->lock);
    80001f22:	8526                	mv	a0,s1
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	cc0080e7          	jalr	-832(ra) # 80000be4 <acquire>
    if (p->state == RUNNING)
    80001f2c:	4c9c                	lw	a5,24(s1)
    80001f2e:	ff3791e3          	bne	a5,s3,80001f10 <update_time+0x22>
      p->rtime++;
    80001f32:	1684a783          	lw	a5,360(s1)
    80001f36:	2785                	addiw	a5,a5,1
    80001f38:	16f4a423          	sw	a5,360(s1)
    80001f3c:	bfd1                	j	80001f10 <update_time+0x22>
}
    80001f3e:	70a2                	ld	ra,40(sp)
    80001f40:	7402                	ld	s0,32(sp)
    80001f42:	64e2                	ld	s1,24(sp)
    80001f44:	6942                	ld	s2,16(sp)
    80001f46:	69a2                	ld	s3,8(sp)
    80001f48:	6145                	addi	sp,sp,48
    80001f4a:	8082                	ret

0000000080001f4c <scheduler>:
{
    80001f4c:	711d                	addi	sp,sp,-96
    80001f4e:	ec86                	sd	ra,88(sp)
    80001f50:	e8a2                	sd	s0,80(sp)
    80001f52:	e4a6                	sd	s1,72(sp)
    80001f54:	e0ca                	sd	s2,64(sp)
    80001f56:	fc4e                	sd	s3,56(sp)
    80001f58:	f852                	sd	s4,48(sp)
    80001f5a:	f456                	sd	s5,40(sp)
    80001f5c:	f05a                	sd	s6,32(sp)
    80001f5e:	ec5e                	sd	s7,24(sp)
    80001f60:	e862                	sd	s8,16(sp)
    80001f62:	e466                	sd	s9,8(sp)
    80001f64:	1080                	addi	s0,sp,96
    80001f66:	8792                	mv	a5,tp
  int id = r_tp();
    80001f68:	2781                	sext.w	a5,a5
      swtch(&c->context, &min->context);
    80001f6a:	00779c13          	slli	s8,a5,0x7
    80001f6e:	0000f717          	auipc	a4,0xf
    80001f72:	36a70713          	addi	a4,a4,874 # 800112d8 <cpus+0x8>
    80001f76:	9c3a                	add	s8,s8,a4
  struct proc *min = 0;
    80001f78:	4a01                	li	s4,0
    c->proc = 0;
    80001f7a:	079e                	slli	a5,a5,0x7
    80001f7c:	0000fb97          	auipc	s7,0xf
    80001f80:	324b8b93          	addi	s7,s7,804 # 800112a0 <pid_lock>
    80001f84:	9bbe                	add	s7,s7,a5
      if (p->state != RUNNABLE)
    80001f86:	498d                	li	s3,3
      if (p->pid > 1)
    80001f88:	4a85                	li	s5,1
    for (p = proc; p < &proc[NPROC]; p++)
    80001f8a:	00015917          	auipc	s2,0x15
    80001f8e:	74690913          	addi	s2,s2,1862 # 800176d0 <tickslock>
      min->state = RUNNING;
    80001f92:	4c91                	li	s9,4
    80001f94:	a0bd                	j	80002002 <scheduler+0xb6>
            min_time = p->ct;
    80001f96:	00078b1b          	sext.w	s6,a5
            release(&p->lock);
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	cfc080e7          	jalr	-772(ra) # 80000c98 <release>
            acquire(&min->lock);
    80001fa4:	8552                	mv	a0,s4
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	c3e080e7          	jalr	-962(ra) # 80000be4 <acquire>
            acquire(&p->lock);
    80001fae:	8526                	mv	a0,s1
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	c34080e7          	jalr	-972(ra) # 80000be4 <acquire>
    80001fb8:	8a26                	mv	s4,s1
    80001fba:	a021                	j	80001fc2 <scheduler+0x76>
          min_time = p->ct;
    80001fbc:	17c4ab03          	lw	s6,380(s1)
    80001fc0:	8a26                	mv	s4,s1
      release(&p->lock);
    80001fc2:	8526                	mv	a0,s1
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	cd4080e7          	jalr	-812(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fcc:	18048493          	addi	s1,s1,384
    80001fd0:	03248763          	beq	s1,s2,80001ffe <scheduler+0xb2>
      acquire(&p->lock);
    80001fd4:	8526                	mv	a0,s1
    80001fd6:	fffff097          	auipc	ra,0xfffff
    80001fda:	c0e080e7          	jalr	-1010(ra) # 80000be4 <acquire>
      if (p->state != RUNNABLE)
    80001fde:	4c9c                	lw	a5,24(s1)
    80001fe0:	ff3796e3          	bne	a5,s3,80001fcc <scheduler+0x80>
      if (p->pid > 1)
    80001fe4:	589c                	lw	a5,48(s1)
    80001fe6:	fcfadee3          	bge	s5,a5,80001fc2 <scheduler+0x76>
        if (min != 0)
    80001fea:	fc0a09e3          	beqz	s4,80001fbc <scheduler+0x70>
          if (p->ct < min_time)
    80001fee:	17c4a783          	lw	a5,380(s1)
    80001ff2:	000b071b          	sext.w	a4,s6
    80001ff6:	fae7e0e3          	bltu	a5,a4,80001f96 <scheduler+0x4a>
    80001ffa:	8a26                	mv	s4,s1
    80001ffc:	b7d9                	j	80001fc2 <scheduler+0x76>
    if (min_time != 0)
    80001ffe:	020b1063          	bnez	s6,8000201e <scheduler+0xd2>
    c->proc = 0;
    80002002:	020bb823          	sd	zero,48(s7)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002006:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000200a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000200e:	10079073          	csrw	sstatus,a5
    int min_time = 0;
    80002012:	4b01                	li	s6,0
    for (p = proc; p < &proc[NPROC]; p++)
    80002014:	0000f497          	auipc	s1,0xf
    80002018:	6bc48493          	addi	s1,s1,1724 # 800116d0 <proc>
    8000201c:	bf65                	j	80001fd4 <scheduler+0x88>
      min->state = RUNNING;
    8000201e:	019a2c23          	sw	s9,24(s4)
      c->proc = min;
    80002022:	034bb823          	sd	s4,48(s7)
      swtch(&c->context, &min->context);
    80002026:	060a0593          	addi	a1,s4,96
    8000202a:	8562                	mv	a0,s8
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	77c080e7          	jalr	1916(ra) # 800027a8 <swtch>
      release(&min->lock);
    80002034:	8552                	mv	a0,s4
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	c62080e7          	jalr	-926(ra) # 80000c98 <release>
    8000203e:	b7d1                	j	80002002 <scheduler+0xb6>

0000000080002040 <sched>:
{
    80002040:	7179                	addi	sp,sp,-48
    80002042:	f406                	sd	ra,40(sp)
    80002044:	f022                	sd	s0,32(sp)
    80002046:	ec26                	sd	s1,24(sp)
    80002048:	e84a                	sd	s2,16(sp)
    8000204a:	e44e                	sd	s3,8(sp)
    8000204c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	962080e7          	jalr	-1694(ra) # 800019b0 <myproc>
    80002056:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	b12080e7          	jalr	-1262(ra) # 80000b6a <holding>
    80002060:	c93d                	beqz	a0,800020d6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002062:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002064:	2781                	sext.w	a5,a5
    80002066:	079e                	slli	a5,a5,0x7
    80002068:	0000f717          	auipc	a4,0xf
    8000206c:	23870713          	addi	a4,a4,568 # 800112a0 <pid_lock>
    80002070:	97ba                	add	a5,a5,a4
    80002072:	0a87a703          	lw	a4,168(a5)
    80002076:	4785                	li	a5,1
    80002078:	06f71763          	bne	a4,a5,800020e6 <sched+0xa6>
  if (p->state == RUNNING)
    8000207c:	4c98                	lw	a4,24(s1)
    8000207e:	4791                	li	a5,4
    80002080:	06f70b63          	beq	a4,a5,800020f6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002084:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002088:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000208a:	efb5                	bnez	a5,80002106 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000208c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000208e:	0000f917          	auipc	s2,0xf
    80002092:	21290913          	addi	s2,s2,530 # 800112a0 <pid_lock>
    80002096:	2781                	sext.w	a5,a5
    80002098:	079e                	slli	a5,a5,0x7
    8000209a:	97ca                	add	a5,a5,s2
    8000209c:	0ac7a983          	lw	s3,172(a5)
    800020a0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020a2:	2781                	sext.w	a5,a5
    800020a4:	079e                	slli	a5,a5,0x7
    800020a6:	0000f597          	auipc	a1,0xf
    800020aa:	23258593          	addi	a1,a1,562 # 800112d8 <cpus+0x8>
    800020ae:	95be                	add	a1,a1,a5
    800020b0:	06048513          	addi	a0,s1,96
    800020b4:	00000097          	auipc	ra,0x0
    800020b8:	6f4080e7          	jalr	1780(ra) # 800027a8 <swtch>
    800020bc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020be:	2781                	sext.w	a5,a5
    800020c0:	079e                	slli	a5,a5,0x7
    800020c2:	97ca                	add	a5,a5,s2
    800020c4:	0b37a623          	sw	s3,172(a5)
}
    800020c8:	70a2                	ld	ra,40(sp)
    800020ca:	7402                	ld	s0,32(sp)
    800020cc:	64e2                	ld	s1,24(sp)
    800020ce:	6942                	ld	s2,16(sp)
    800020d0:	69a2                	ld	s3,8(sp)
    800020d2:	6145                	addi	sp,sp,48
    800020d4:	8082                	ret
    panic("sched p->lock");
    800020d6:	00006517          	auipc	a0,0x6
    800020da:	14250513          	addi	a0,a0,322 # 80008218 <digits+0x1d8>
    800020de:	ffffe097          	auipc	ra,0xffffe
    800020e2:	460080e7          	jalr	1120(ra) # 8000053e <panic>
    panic("sched locks");
    800020e6:	00006517          	auipc	a0,0x6
    800020ea:	14250513          	addi	a0,a0,322 # 80008228 <digits+0x1e8>
    800020ee:	ffffe097          	auipc	ra,0xffffe
    800020f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
    panic("sched running");
    800020f6:	00006517          	auipc	a0,0x6
    800020fa:	14250513          	addi	a0,a0,322 # 80008238 <digits+0x1f8>
    800020fe:	ffffe097          	auipc	ra,0xffffe
    80002102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002106:	00006517          	auipc	a0,0x6
    8000210a:	14250513          	addi	a0,a0,322 # 80008248 <digits+0x208>
    8000210e:	ffffe097          	auipc	ra,0xffffe
    80002112:	430080e7          	jalr	1072(ra) # 8000053e <panic>

0000000080002116 <yield>:
{
    80002116:	1101                	addi	sp,sp,-32
    80002118:	ec06                	sd	ra,24(sp)
    8000211a:	e822                	sd	s0,16(sp)
    8000211c:	e426                	sd	s1,8(sp)
    8000211e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002120:	00000097          	auipc	ra,0x0
    80002124:	890080e7          	jalr	-1904(ra) # 800019b0 <myproc>
    80002128:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	aba080e7          	jalr	-1350(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002132:	478d                	li	a5,3
    80002134:	cc9c                	sw	a5,24(s1)
  sched();
    80002136:	00000097          	auipc	ra,0x0
    8000213a:	f0a080e7          	jalr	-246(ra) # 80002040 <sched>
  release(&p->lock);
    8000213e:	8526                	mv	a0,s1
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b58080e7          	jalr	-1192(ra) # 80000c98 <release>
}
    80002148:	60e2                	ld	ra,24(sp)
    8000214a:	6442                	ld	s0,16(sp)
    8000214c:	64a2                	ld	s1,8(sp)
    8000214e:	6105                	addi	sp,sp,32
    80002150:	8082                	ret

0000000080002152 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002152:	7179                	addi	sp,sp,-48
    80002154:	f406                	sd	ra,40(sp)
    80002156:	f022                	sd	s0,32(sp)
    80002158:	ec26                	sd	s1,24(sp)
    8000215a:	e84a                	sd	s2,16(sp)
    8000215c:	e44e                	sd	s3,8(sp)
    8000215e:	1800                	addi	s0,sp,48
    80002160:	89aa                	mv	s3,a0
    80002162:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002164:	00000097          	auipc	ra,0x0
    80002168:	84c080e7          	jalr	-1972(ra) # 800019b0 <myproc>
    8000216c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	a76080e7          	jalr	-1418(ra) # 80000be4 <acquire>
  release(lk);
    80002176:	854a                	mv	a0,s2
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	b20080e7          	jalr	-1248(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002180:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002184:	4789                	li	a5,2
    80002186:	cc9c                	sw	a5,24(s1)

  sched();
    80002188:	00000097          	auipc	ra,0x0
    8000218c:	eb8080e7          	jalr	-328(ra) # 80002040 <sched>

  // Tidy up.
  p->chan = 0;
    80002190:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002194:	8526                	mv	a0,s1
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	b02080e7          	jalr	-1278(ra) # 80000c98 <release>
  acquire(lk);
    8000219e:	854a                	mv	a0,s2
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	a44080e7          	jalr	-1468(ra) # 80000be4 <acquire>
}
    800021a8:	70a2                	ld	ra,40(sp)
    800021aa:	7402                	ld	s0,32(sp)
    800021ac:	64e2                	ld	s1,24(sp)
    800021ae:	6942                	ld	s2,16(sp)
    800021b0:	69a2                	ld	s3,8(sp)
    800021b2:	6145                	addi	sp,sp,48
    800021b4:	8082                	ret

00000000800021b6 <wait>:
{
    800021b6:	715d                	addi	sp,sp,-80
    800021b8:	e486                	sd	ra,72(sp)
    800021ba:	e0a2                	sd	s0,64(sp)
    800021bc:	fc26                	sd	s1,56(sp)
    800021be:	f84a                	sd	s2,48(sp)
    800021c0:	f44e                	sd	s3,40(sp)
    800021c2:	f052                	sd	s4,32(sp)
    800021c4:	ec56                	sd	s5,24(sp)
    800021c6:	e85a                	sd	s6,16(sp)
    800021c8:	e45e                	sd	s7,8(sp)
    800021ca:	e062                	sd	s8,0(sp)
    800021cc:	0880                	addi	s0,sp,80
    800021ce:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	7e0080e7          	jalr	2016(ra) # 800019b0 <myproc>
    800021d8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021da:	0000f517          	auipc	a0,0xf
    800021de:	0de50513          	addi	a0,a0,222 # 800112b8 <wait_lock>
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	a02080e7          	jalr	-1534(ra) # 80000be4 <acquire>
    havekids = 0;
    800021ea:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800021ec:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    800021ee:	00015997          	auipc	s3,0x15
    800021f2:	4e298993          	addi	s3,s3,1250 # 800176d0 <tickslock>
        havekids = 1;
    800021f6:	4a85                	li	s5,1
    sleep(p, &wait_lock); //DOC: wait-sleep
    800021f8:	0000fc17          	auipc	s8,0xf
    800021fc:	0c0c0c13          	addi	s8,s8,192 # 800112b8 <wait_lock>
    havekids = 0;
    80002200:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    80002202:	0000f497          	auipc	s1,0xf
    80002206:	4ce48493          	addi	s1,s1,1230 # 800116d0 <proc>
    8000220a:	a0bd                	j	80002278 <wait+0xc2>
          pid = np->pid;
    8000220c:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002210:	000b0e63          	beqz	s6,8000222c <wait+0x76>
    80002214:	4691                	li	a3,4
    80002216:	02c48613          	addi	a2,s1,44
    8000221a:	85da                	mv	a1,s6
    8000221c:	05093503          	ld	a0,80(s2)
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	452080e7          	jalr	1106(ra) # 80001672 <copyout>
    80002228:	02054563          	bltz	a0,80002252 <wait+0x9c>
          freeproc(np);
    8000222c:	8526                	mv	a0,s1
    8000222e:	00000097          	auipc	ra,0x0
    80002232:	934080e7          	jalr	-1740(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002236:	8526                	mv	a0,s1
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	a60080e7          	jalr	-1440(ra) # 80000c98 <release>
          release(&wait_lock);
    80002240:	0000f517          	auipc	a0,0xf
    80002244:	07850513          	addi	a0,a0,120 # 800112b8 <wait_lock>
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	a50080e7          	jalr	-1456(ra) # 80000c98 <release>
          return pid;
    80002250:	a09d                	j	800022b6 <wait+0x100>
            release(&np->lock);
    80002252:	8526                	mv	a0,s1
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	a44080e7          	jalr	-1468(ra) # 80000c98 <release>
            release(&wait_lock);
    8000225c:	0000f517          	auipc	a0,0xf
    80002260:	05c50513          	addi	a0,a0,92 # 800112b8 <wait_lock>
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	a34080e7          	jalr	-1484(ra) # 80000c98 <release>
            return -1;
    8000226c:	59fd                	li	s3,-1
    8000226e:	a0a1                	j	800022b6 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    80002270:	18048493          	addi	s1,s1,384
    80002274:	03348463          	beq	s1,s3,8000229c <wait+0xe6>
      if (np->parent == p)
    80002278:	7c9c                	ld	a5,56(s1)
    8000227a:	ff279be3          	bne	a5,s2,80002270 <wait+0xba>
        acquire(&np->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	964080e7          	jalr	-1692(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    80002288:	4c9c                	lw	a5,24(s1)
    8000228a:	f94781e3          	beq	a5,s4,8000220c <wait+0x56>
        release(&np->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	a08080e7          	jalr	-1528(ra) # 80000c98 <release>
        havekids = 1;
    80002298:	8756                	mv	a4,s5
    8000229a:	bfd9                	j	80002270 <wait+0xba>
    if (!havekids || p->killed)
    8000229c:	c701                	beqz	a4,800022a4 <wait+0xee>
    8000229e:	02892783          	lw	a5,40(s2)
    800022a2:	c79d                	beqz	a5,800022d0 <wait+0x11a>
      release(&wait_lock);
    800022a4:	0000f517          	auipc	a0,0xf
    800022a8:	01450513          	addi	a0,a0,20 # 800112b8 <wait_lock>
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	9ec080e7          	jalr	-1556(ra) # 80000c98 <release>
      return -1;
    800022b4:	59fd                	li	s3,-1
}
    800022b6:	854e                	mv	a0,s3
    800022b8:	60a6                	ld	ra,72(sp)
    800022ba:	6406                	ld	s0,64(sp)
    800022bc:	74e2                	ld	s1,56(sp)
    800022be:	7942                	ld	s2,48(sp)
    800022c0:	79a2                	ld	s3,40(sp)
    800022c2:	7a02                	ld	s4,32(sp)
    800022c4:	6ae2                	ld	s5,24(sp)
    800022c6:	6b42                	ld	s6,16(sp)
    800022c8:	6ba2                	ld	s7,8(sp)
    800022ca:	6c02                	ld	s8,0(sp)
    800022cc:	6161                	addi	sp,sp,80
    800022ce:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    800022d0:	85e2                	mv	a1,s8
    800022d2:	854a                	mv	a0,s2
    800022d4:	00000097          	auipc	ra,0x0
    800022d8:	e7e080e7          	jalr	-386(ra) # 80002152 <sleep>
    havekids = 0;
    800022dc:	b715                	j	80002200 <wait+0x4a>

00000000800022de <waitx>:
{
    800022de:	711d                	addi	sp,sp,-96
    800022e0:	ec86                	sd	ra,88(sp)
    800022e2:	e8a2                	sd	s0,80(sp)
    800022e4:	e4a6                	sd	s1,72(sp)
    800022e6:	e0ca                	sd	s2,64(sp)
    800022e8:	fc4e                	sd	s3,56(sp)
    800022ea:	f852                	sd	s4,48(sp)
    800022ec:	f456                	sd	s5,40(sp)
    800022ee:	f05a                	sd	s6,32(sp)
    800022f0:	ec5e                	sd	s7,24(sp)
    800022f2:	e862                	sd	s8,16(sp)
    800022f4:	e466                	sd	s9,8(sp)
    800022f6:	e06a                	sd	s10,0(sp)
    800022f8:	1080                	addi	s0,sp,96
    800022fa:	8b2a                	mv	s6,a0
    800022fc:	8c2e                	mv	s8,a1
    800022fe:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	6b0080e7          	jalr	1712(ra) # 800019b0 <myproc>
    80002308:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000230a:	0000f517          	auipc	a0,0xf
    8000230e:	fae50513          	addi	a0,a0,-82 # 800112b8 <wait_lock>
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	8d2080e7          	jalr	-1838(ra) # 80000be4 <acquire>
    havekids = 0;
    8000231a:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    8000231c:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    8000231e:	00015997          	auipc	s3,0x15
    80002322:	3b298993          	addi	s3,s3,946 # 800176d0 <tickslock>
        havekids = 1;
    80002326:	4a85                	li	s5,1
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002328:	0000fd17          	auipc	s10,0xf
    8000232c:	f90d0d13          	addi	s10,s10,-112 # 800112b8 <wait_lock>
    havekids = 0;
    80002330:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002332:	0000f497          	auipc	s1,0xf
    80002336:	39e48493          	addi	s1,s1,926 # 800116d0 <proc>
    8000233a:	a059                	j	800023c0 <waitx+0xe2>
          pid = np->pid;
    8000233c:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002340:	1684a703          	lw	a4,360(s1)
    80002344:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002348:	16c4a783          	lw	a5,364(s1)
    8000234c:	9f3d                	addw	a4,a4,a5
    8000234e:	1704a783          	lw	a5,368(s1)
    80002352:	9f99                	subw	a5,a5,a4
    80002354:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002358:	000b0e63          	beqz	s6,80002374 <waitx+0x96>
    8000235c:	4691                	li	a3,4
    8000235e:	02c48613          	addi	a2,s1,44
    80002362:	85da                	mv	a1,s6
    80002364:	05093503          	ld	a0,80(s2)
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	30a080e7          	jalr	778(ra) # 80001672 <copyout>
    80002370:	02054563          	bltz	a0,8000239a <waitx+0xbc>
          freeproc(np);
    80002374:	8526                	mv	a0,s1
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	7ec080e7          	jalr	2028(ra) # 80001b62 <freeproc>
          release(&np->lock);
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	918080e7          	jalr	-1768(ra) # 80000c98 <release>
          release(&wait_lock);
    80002388:	0000f517          	auipc	a0,0xf
    8000238c:	f3050513          	addi	a0,a0,-208 # 800112b8 <wait_lock>
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	908080e7          	jalr	-1784(ra) # 80000c98 <release>
          return pid;
    80002398:	a09d                	j	800023fe <waitx+0x120>
            release(&np->lock);
    8000239a:	8526                	mv	a0,s1
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	8fc080e7          	jalr	-1796(ra) # 80000c98 <release>
            release(&wait_lock);
    800023a4:	0000f517          	auipc	a0,0xf
    800023a8:	f1450513          	addi	a0,a0,-236 # 800112b8 <wait_lock>
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	8ec080e7          	jalr	-1812(ra) # 80000c98 <release>
            return -1;
    800023b4:	59fd                	li	s3,-1
    800023b6:	a0a1                	j	800023fe <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800023b8:	18048493          	addi	s1,s1,384
    800023bc:	03348463          	beq	s1,s3,800023e4 <waitx+0x106>
      if (np->parent == p)
    800023c0:	7c9c                	ld	a5,56(s1)
    800023c2:	ff279be3          	bne	a5,s2,800023b8 <waitx+0xda>
        acquire(&np->lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	81c080e7          	jalr	-2020(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    800023d0:	4c9c                	lw	a5,24(s1)
    800023d2:	f74785e3          	beq	a5,s4,8000233c <waitx+0x5e>
        release(&np->lock);
    800023d6:	8526                	mv	a0,s1
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	8c0080e7          	jalr	-1856(ra) # 80000c98 <release>
        havekids = 1;
    800023e0:	8756                	mv	a4,s5
    800023e2:	bfd9                	j	800023b8 <waitx+0xda>
    if (!havekids || p->killed)
    800023e4:	c701                	beqz	a4,800023ec <waitx+0x10e>
    800023e6:	02892783          	lw	a5,40(s2)
    800023ea:	cb8d                	beqz	a5,8000241c <waitx+0x13e>
      release(&wait_lock);
    800023ec:	0000f517          	auipc	a0,0xf
    800023f0:	ecc50513          	addi	a0,a0,-308 # 800112b8 <wait_lock>
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	8a4080e7          	jalr	-1884(ra) # 80000c98 <release>
      return -1;
    800023fc:	59fd                	li	s3,-1
}
    800023fe:	854e                	mv	a0,s3
    80002400:	60e6                	ld	ra,88(sp)
    80002402:	6446                	ld	s0,80(sp)
    80002404:	64a6                	ld	s1,72(sp)
    80002406:	6906                	ld	s2,64(sp)
    80002408:	79e2                	ld	s3,56(sp)
    8000240a:	7a42                	ld	s4,48(sp)
    8000240c:	7aa2                	ld	s5,40(sp)
    8000240e:	7b02                	ld	s6,32(sp)
    80002410:	6be2                	ld	s7,24(sp)
    80002412:	6c42                	ld	s8,16(sp)
    80002414:	6ca2                	ld	s9,8(sp)
    80002416:	6d02                	ld	s10,0(sp)
    80002418:	6125                	addi	sp,sp,96
    8000241a:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000241c:	85ea                	mv	a1,s10
    8000241e:	854a                	mv	a0,s2
    80002420:	00000097          	auipc	ra,0x0
    80002424:	d32080e7          	jalr	-718(ra) # 80002152 <sleep>
    havekids = 0;
    80002428:	b721                	j	80002330 <waitx+0x52>

000000008000242a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000242a:	7139                	addi	sp,sp,-64
    8000242c:	fc06                	sd	ra,56(sp)
    8000242e:	f822                	sd	s0,48(sp)
    80002430:	f426                	sd	s1,40(sp)
    80002432:	f04a                	sd	s2,32(sp)
    80002434:	ec4e                	sd	s3,24(sp)
    80002436:	e852                	sd	s4,16(sp)
    80002438:	e456                	sd	s5,8(sp)
    8000243a:	0080                	addi	s0,sp,64
    8000243c:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000243e:	0000f497          	auipc	s1,0xf
    80002442:	29248493          	addi	s1,s1,658 # 800116d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002446:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002448:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000244a:	00015917          	auipc	s2,0x15
    8000244e:	28690913          	addi	s2,s2,646 # 800176d0 <tickslock>
    80002452:	a821                	j	8000246a <wakeup+0x40>
        p->state = RUNNABLE;
    80002454:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002458:	8526                	mv	a0,s1
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	83e080e7          	jalr	-1986(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002462:	18048493          	addi	s1,s1,384
    80002466:	03248463          	beq	s1,s2,8000248e <wakeup+0x64>
    if (p != myproc())
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	546080e7          	jalr	1350(ra) # 800019b0 <myproc>
    80002472:	fea488e3          	beq	s1,a0,80002462 <wakeup+0x38>
      acquire(&p->lock);
    80002476:	8526                	mv	a0,s1
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	76c080e7          	jalr	1900(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002480:	4c9c                	lw	a5,24(s1)
    80002482:	fd379be3          	bne	a5,s3,80002458 <wakeup+0x2e>
    80002486:	709c                	ld	a5,32(s1)
    80002488:	fd4798e3          	bne	a5,s4,80002458 <wakeup+0x2e>
    8000248c:	b7e1                	j	80002454 <wakeup+0x2a>
    }
  }
}
    8000248e:	70e2                	ld	ra,56(sp)
    80002490:	7442                	ld	s0,48(sp)
    80002492:	74a2                	ld	s1,40(sp)
    80002494:	7902                	ld	s2,32(sp)
    80002496:	69e2                	ld	s3,24(sp)
    80002498:	6a42                	ld	s4,16(sp)
    8000249a:	6aa2                	ld	s5,8(sp)
    8000249c:	6121                	addi	sp,sp,64
    8000249e:	8082                	ret

00000000800024a0 <reparent>:
{
    800024a0:	7179                	addi	sp,sp,-48
    800024a2:	f406                	sd	ra,40(sp)
    800024a4:	f022                	sd	s0,32(sp)
    800024a6:	ec26                	sd	s1,24(sp)
    800024a8:	e84a                	sd	s2,16(sp)
    800024aa:	e44e                	sd	s3,8(sp)
    800024ac:	e052                	sd	s4,0(sp)
    800024ae:	1800                	addi	s0,sp,48
    800024b0:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024b2:	0000f497          	auipc	s1,0xf
    800024b6:	21e48493          	addi	s1,s1,542 # 800116d0 <proc>
      pp->parent = initproc;
    800024ba:	00007a17          	auipc	s4,0x7
    800024be:	b6ea0a13          	addi	s4,s4,-1170 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024c2:	00015997          	auipc	s3,0x15
    800024c6:	20e98993          	addi	s3,s3,526 # 800176d0 <tickslock>
    800024ca:	a029                	j	800024d4 <reparent+0x34>
    800024cc:	18048493          	addi	s1,s1,384
    800024d0:	01348d63          	beq	s1,s3,800024ea <reparent+0x4a>
    if (pp->parent == p)
    800024d4:	7c9c                	ld	a5,56(s1)
    800024d6:	ff279be3          	bne	a5,s2,800024cc <reparent+0x2c>
      pp->parent = initproc;
    800024da:	000a3503          	ld	a0,0(s4)
    800024de:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024e0:	00000097          	auipc	ra,0x0
    800024e4:	f4a080e7          	jalr	-182(ra) # 8000242a <wakeup>
    800024e8:	b7d5                	j	800024cc <reparent+0x2c>
}
    800024ea:	70a2                	ld	ra,40(sp)
    800024ec:	7402                	ld	s0,32(sp)
    800024ee:	64e2                	ld	s1,24(sp)
    800024f0:	6942                	ld	s2,16(sp)
    800024f2:	69a2                	ld	s3,8(sp)
    800024f4:	6a02                	ld	s4,0(sp)
    800024f6:	6145                	addi	sp,sp,48
    800024f8:	8082                	ret

00000000800024fa <exit>:
{
    800024fa:	7179                	addi	sp,sp,-48
    800024fc:	f406                	sd	ra,40(sp)
    800024fe:	f022                	sd	s0,32(sp)
    80002500:	ec26                	sd	s1,24(sp)
    80002502:	e84a                	sd	s2,16(sp)
    80002504:	e44e                	sd	s3,8(sp)
    80002506:	e052                	sd	s4,0(sp)
    80002508:	1800                	addi	s0,sp,48
    8000250a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	4a4080e7          	jalr	1188(ra) # 800019b0 <myproc>
    80002514:	89aa                	mv	s3,a0
  if (p == initproc)
    80002516:	00007797          	auipc	a5,0x7
    8000251a:	b127b783          	ld	a5,-1262(a5) # 80009028 <initproc>
    8000251e:	0d050493          	addi	s1,a0,208
    80002522:	15050913          	addi	s2,a0,336
    80002526:	02a79363          	bne	a5,a0,8000254c <exit+0x52>
    panic("init exiting");
    8000252a:	00006517          	auipc	a0,0x6
    8000252e:	d3650513          	addi	a0,a0,-714 # 80008260 <digits+0x220>
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	00c080e7          	jalr	12(ra) # 8000053e <panic>
      fileclose(f);
    8000253a:	00002097          	auipc	ra,0x2
    8000253e:	29c080e7          	jalr	668(ra) # 800047d6 <fileclose>
      p->ofile[fd] = 0;
    80002542:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002546:	04a1                	addi	s1,s1,8
    80002548:	01248563          	beq	s1,s2,80002552 <exit+0x58>
    if (p->ofile[fd])
    8000254c:	6088                	ld	a0,0(s1)
    8000254e:	f575                	bnez	a0,8000253a <exit+0x40>
    80002550:	bfdd                	j	80002546 <exit+0x4c>
  begin_op();
    80002552:	00002097          	auipc	ra,0x2
    80002556:	db8080e7          	jalr	-584(ra) # 8000430a <begin_op>
  iput(p->cwd);
    8000255a:	1509b503          	ld	a0,336(s3)
    8000255e:	00001097          	auipc	ra,0x1
    80002562:	594080e7          	jalr	1428(ra) # 80003af2 <iput>
  end_op();
    80002566:	00002097          	auipc	ra,0x2
    8000256a:	e24080e7          	jalr	-476(ra) # 8000438a <end_op>
  p->cwd = 0;
    8000256e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002572:	0000f497          	auipc	s1,0xf
    80002576:	d4648493          	addi	s1,s1,-698 # 800112b8 <wait_lock>
    8000257a:	8526                	mv	a0,s1
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	668080e7          	jalr	1640(ra) # 80000be4 <acquire>
  reparent(p);
    80002584:	854e                	mv	a0,s3
    80002586:	00000097          	auipc	ra,0x0
    8000258a:	f1a080e7          	jalr	-230(ra) # 800024a0 <reparent>
  wakeup(p->parent);
    8000258e:	0389b503          	ld	a0,56(s3)
    80002592:	00000097          	auipc	ra,0x0
    80002596:	e98080e7          	jalr	-360(ra) # 8000242a <wakeup>
  acquire(&p->lock);
    8000259a:	854e                	mv	a0,s3
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	648080e7          	jalr	1608(ra) # 80000be4 <acquire>
  p->xstate = status;
    800025a4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800025a8:	4795                	li	a5,5
    800025aa:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800025ae:	00007797          	auipc	a5,0x7
    800025b2:	a827a783          	lw	a5,-1406(a5) # 80009030 <ticks>
    800025b6:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800025ba:	8526                	mv	a0,s1
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	6dc080e7          	jalr	1756(ra) # 80000c98 <release>
  sched();
    800025c4:	00000097          	auipc	ra,0x0
    800025c8:	a7c080e7          	jalr	-1412(ra) # 80002040 <sched>
  panic("zombie exit");
    800025cc:	00006517          	auipc	a0,0x6
    800025d0:	ca450513          	addi	a0,a0,-860 # 80008270 <digits+0x230>
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	f6a080e7          	jalr	-150(ra) # 8000053e <panic>

00000000800025dc <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025dc:	7179                	addi	sp,sp,-48
    800025de:	f406                	sd	ra,40(sp)
    800025e0:	f022                	sd	s0,32(sp)
    800025e2:	ec26                	sd	s1,24(sp)
    800025e4:	e84a                	sd	s2,16(sp)
    800025e6:	e44e                	sd	s3,8(sp)
    800025e8:	1800                	addi	s0,sp,48
    800025ea:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025ec:	0000f497          	auipc	s1,0xf
    800025f0:	0e448493          	addi	s1,s1,228 # 800116d0 <proc>
    800025f4:	00015997          	auipc	s3,0x15
    800025f8:	0dc98993          	addi	s3,s3,220 # 800176d0 <tickslock>
  {
    acquire(&p->lock);
    800025fc:	8526                	mv	a0,s1
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	5e6080e7          	jalr	1510(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    80002606:	589c                	lw	a5,48(s1)
    80002608:	01278d63          	beq	a5,s2,80002622 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000260c:	8526                	mv	a0,s1
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	68a080e7          	jalr	1674(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002616:	18048493          	addi	s1,s1,384
    8000261a:	ff3491e3          	bne	s1,s3,800025fc <kill+0x20>
  }
  return -1;
    8000261e:	557d                	li	a0,-1
    80002620:	a829                	j	8000263a <kill+0x5e>
      p->killed = 1;
    80002622:	4785                	li	a5,1
    80002624:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002626:	4c98                	lw	a4,24(s1)
    80002628:	4789                	li	a5,2
    8000262a:	00f70f63          	beq	a4,a5,80002648 <kill+0x6c>
      release(&p->lock);
    8000262e:	8526                	mv	a0,s1
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	668080e7          	jalr	1640(ra) # 80000c98 <release>
      return 0;
    80002638:	4501                	li	a0,0
}
    8000263a:	70a2                	ld	ra,40(sp)
    8000263c:	7402                	ld	s0,32(sp)
    8000263e:	64e2                	ld	s1,24(sp)
    80002640:	6942                	ld	s2,16(sp)
    80002642:	69a2                	ld	s3,8(sp)
    80002644:	6145                	addi	sp,sp,48
    80002646:	8082                	ret
        p->state = RUNNABLE;
    80002648:	478d                	li	a5,3
    8000264a:	cc9c                	sw	a5,24(s1)
    8000264c:	b7cd                	j	8000262e <kill+0x52>

000000008000264e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000264e:	7179                	addi	sp,sp,-48
    80002650:	f406                	sd	ra,40(sp)
    80002652:	f022                	sd	s0,32(sp)
    80002654:	ec26                	sd	s1,24(sp)
    80002656:	e84a                	sd	s2,16(sp)
    80002658:	e44e                	sd	s3,8(sp)
    8000265a:	e052                	sd	s4,0(sp)
    8000265c:	1800                	addi	s0,sp,48
    8000265e:	84aa                	mv	s1,a0
    80002660:	892e                	mv	s2,a1
    80002662:	89b2                	mv	s3,a2
    80002664:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002666:	fffff097          	auipc	ra,0xfffff
    8000266a:	34a080e7          	jalr	842(ra) # 800019b0 <myproc>
  if (user_dst)
    8000266e:	c08d                	beqz	s1,80002690 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002670:	86d2                	mv	a3,s4
    80002672:	864e                	mv	a2,s3
    80002674:	85ca                	mv	a1,s2
    80002676:	6928                	ld	a0,80(a0)
    80002678:	fffff097          	auipc	ra,0xfffff
    8000267c:	ffa080e7          	jalr	-6(ra) # 80001672 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002680:	70a2                	ld	ra,40(sp)
    80002682:	7402                	ld	s0,32(sp)
    80002684:	64e2                	ld	s1,24(sp)
    80002686:	6942                	ld	s2,16(sp)
    80002688:	69a2                	ld	s3,8(sp)
    8000268a:	6a02                	ld	s4,0(sp)
    8000268c:	6145                	addi	sp,sp,48
    8000268e:	8082                	ret
    memmove((char *)dst, src, len);
    80002690:	000a061b          	sext.w	a2,s4
    80002694:	85ce                	mv	a1,s3
    80002696:	854a                	mv	a0,s2
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	6a8080e7          	jalr	1704(ra) # 80000d40 <memmove>
    return 0;
    800026a0:	8526                	mv	a0,s1
    800026a2:	bff9                	j	80002680 <either_copyout+0x32>

00000000800026a4 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026a4:	7179                	addi	sp,sp,-48
    800026a6:	f406                	sd	ra,40(sp)
    800026a8:	f022                	sd	s0,32(sp)
    800026aa:	ec26                	sd	s1,24(sp)
    800026ac:	e84a                	sd	s2,16(sp)
    800026ae:	e44e                	sd	s3,8(sp)
    800026b0:	e052                	sd	s4,0(sp)
    800026b2:	1800                	addi	s0,sp,48
    800026b4:	892a                	mv	s2,a0
    800026b6:	84ae                	mv	s1,a1
    800026b8:	89b2                	mv	s3,a2
    800026ba:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026bc:	fffff097          	auipc	ra,0xfffff
    800026c0:	2f4080e7          	jalr	756(ra) # 800019b0 <myproc>
  if (user_src)
    800026c4:	c08d                	beqz	s1,800026e6 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800026c6:	86d2                	mv	a3,s4
    800026c8:	864e                	mv	a2,s3
    800026ca:	85ca                	mv	a1,s2
    800026cc:	6928                	ld	a0,80(a0)
    800026ce:	fffff097          	auipc	ra,0xfffff
    800026d2:	030080e7          	jalr	48(ra) # 800016fe <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800026d6:	70a2                	ld	ra,40(sp)
    800026d8:	7402                	ld	s0,32(sp)
    800026da:	64e2                	ld	s1,24(sp)
    800026dc:	6942                	ld	s2,16(sp)
    800026de:	69a2                	ld	s3,8(sp)
    800026e0:	6a02                	ld	s4,0(sp)
    800026e2:	6145                	addi	sp,sp,48
    800026e4:	8082                	ret
    memmove(dst, (char *)src, len);
    800026e6:	000a061b          	sext.w	a2,s4
    800026ea:	85ce                	mv	a1,s3
    800026ec:	854a                	mv	a0,s2
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	652080e7          	jalr	1618(ra) # 80000d40 <memmove>
    return 0;
    800026f6:	8526                	mv	a0,s1
    800026f8:	bff9                	j	800026d6 <either_copyin+0x32>

00000000800026fa <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800026fa:	715d                	addi	sp,sp,-80
    800026fc:	e486                	sd	ra,72(sp)
    800026fe:	e0a2                	sd	s0,64(sp)
    80002700:	fc26                	sd	s1,56(sp)
    80002702:	f84a                	sd	s2,48(sp)
    80002704:	f44e                	sd	s3,40(sp)
    80002706:	f052                	sd	s4,32(sp)
    80002708:	ec56                	sd	s5,24(sp)
    8000270a:	e85a                	sd	s6,16(sp)
    8000270c:	e45e                	sd	s7,8(sp)
    8000270e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002710:	00006517          	auipc	a0,0x6
    80002714:	9b850513          	addi	a0,a0,-1608 # 800080c8 <digits+0x88>
    80002718:	ffffe097          	auipc	ra,0xffffe
    8000271c:	e70080e7          	jalr	-400(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002720:	0000f497          	auipc	s1,0xf
    80002724:	10848493          	addi	s1,s1,264 # 80011828 <proc+0x158>
    80002728:	00015917          	auipc	s2,0x15
    8000272c:	10090913          	addi	s2,s2,256 # 80017828 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002730:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002732:	00006997          	auipc	s3,0x6
    80002736:	b4e98993          	addi	s3,s3,-1202 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000273a:	00006a97          	auipc	s5,0x6
    8000273e:	b4ea8a93          	addi	s5,s5,-1202 # 80008288 <digits+0x248>
    printf("\n");
    80002742:	00006a17          	auipc	s4,0x6
    80002746:	986a0a13          	addi	s4,s4,-1658 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000274a:	00006b97          	auipc	s7,0x6
    8000274e:	b76b8b93          	addi	s7,s7,-1162 # 800082c0 <states.1743>
    80002752:	a00d                	j	80002774 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002754:	ed86a583          	lw	a1,-296(a3)
    80002758:	8556                	mv	a0,s5
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	e2e080e7          	jalr	-466(ra) # 80000588 <printf>
    printf("\n");
    80002762:	8552                	mv	a0,s4
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	e24080e7          	jalr	-476(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000276c:	18048493          	addi	s1,s1,384
    80002770:	03248163          	beq	s1,s2,80002792 <procdump+0x98>
    if (p->state == UNUSED)
    80002774:	86a6                	mv	a3,s1
    80002776:	ec04a783          	lw	a5,-320(s1)
    8000277a:	dbed                	beqz	a5,8000276c <procdump+0x72>
      state = "???";
    8000277c:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000277e:	fcfb6be3          	bltu	s6,a5,80002754 <procdump+0x5a>
    80002782:	1782                	slli	a5,a5,0x20
    80002784:	9381                	srli	a5,a5,0x20
    80002786:	078e                	slli	a5,a5,0x3
    80002788:	97de                	add	a5,a5,s7
    8000278a:	6390                	ld	a2,0(a5)
    8000278c:	f661                	bnez	a2,80002754 <procdump+0x5a>
      state = "???";
    8000278e:	864e                	mv	a2,s3
    80002790:	b7d1                	j	80002754 <procdump+0x5a>
  }
}
    80002792:	60a6                	ld	ra,72(sp)
    80002794:	6406                	ld	s0,64(sp)
    80002796:	74e2                	ld	s1,56(sp)
    80002798:	7942                	ld	s2,48(sp)
    8000279a:	79a2                	ld	s3,40(sp)
    8000279c:	7a02                	ld	s4,32(sp)
    8000279e:	6ae2                	ld	s5,24(sp)
    800027a0:	6b42                	ld	s6,16(sp)
    800027a2:	6ba2                	ld	s7,8(sp)
    800027a4:	6161                	addi	sp,sp,80
    800027a6:	8082                	ret

00000000800027a8 <swtch>:
    800027a8:	00153023          	sd	ra,0(a0)
    800027ac:	00253423          	sd	sp,8(a0)
    800027b0:	e900                	sd	s0,16(a0)
    800027b2:	ed04                	sd	s1,24(a0)
    800027b4:	03253023          	sd	s2,32(a0)
    800027b8:	03353423          	sd	s3,40(a0)
    800027bc:	03453823          	sd	s4,48(a0)
    800027c0:	03553c23          	sd	s5,56(a0)
    800027c4:	05653023          	sd	s6,64(a0)
    800027c8:	05753423          	sd	s7,72(a0)
    800027cc:	05853823          	sd	s8,80(a0)
    800027d0:	05953c23          	sd	s9,88(a0)
    800027d4:	07a53023          	sd	s10,96(a0)
    800027d8:	07b53423          	sd	s11,104(a0)
    800027dc:	0005b083          	ld	ra,0(a1)
    800027e0:	0085b103          	ld	sp,8(a1)
    800027e4:	6980                	ld	s0,16(a1)
    800027e6:	6d84                	ld	s1,24(a1)
    800027e8:	0205b903          	ld	s2,32(a1)
    800027ec:	0285b983          	ld	s3,40(a1)
    800027f0:	0305ba03          	ld	s4,48(a1)
    800027f4:	0385ba83          	ld	s5,56(a1)
    800027f8:	0405bb03          	ld	s6,64(a1)
    800027fc:	0485bb83          	ld	s7,72(a1)
    80002800:	0505bc03          	ld	s8,80(a1)
    80002804:	0585bc83          	ld	s9,88(a1)
    80002808:	0605bd03          	ld	s10,96(a1)
    8000280c:	0685bd83          	ld	s11,104(a1)
    80002810:	8082                	ret

0000000080002812 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002812:	1141                	addi	sp,sp,-16
    80002814:	e406                	sd	ra,8(sp)
    80002816:	e022                	sd	s0,0(sp)
    80002818:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000281a:	00006597          	auipc	a1,0x6
    8000281e:	ad658593          	addi	a1,a1,-1322 # 800082f0 <states.1743+0x30>
    80002822:	00015517          	auipc	a0,0x15
    80002826:	eae50513          	addi	a0,a0,-338 # 800176d0 <tickslock>
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	32a080e7          	jalr	810(ra) # 80000b54 <initlock>
}
    80002832:	60a2                	ld	ra,8(sp)
    80002834:	6402                	ld	s0,0(sp)
    80002836:	0141                	addi	sp,sp,16
    80002838:	8082                	ret

000000008000283a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    8000283a:	1141                	addi	sp,sp,-16
    8000283c:	e422                	sd	s0,8(sp)
    8000283e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002840:	00003797          	auipc	a5,0x3
    80002844:	5b078793          	addi	a5,a5,1456 # 80005df0 <kernelvec>
    80002848:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000284c:	6422                	ld	s0,8(sp)
    8000284e:	0141                	addi	sp,sp,16
    80002850:	8082                	ret

0000000080002852 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002852:	1141                	addi	sp,sp,-16
    80002854:	e406                	sd	ra,8(sp)
    80002856:	e022                	sd	s0,0(sp)
    80002858:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000285a:	fffff097          	auipc	ra,0xfffff
    8000285e:	156080e7          	jalr	342(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002862:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002866:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002868:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000286c:	00004617          	auipc	a2,0x4
    80002870:	79460613          	addi	a2,a2,1940 # 80007000 <_trampoline>
    80002874:	00004697          	auipc	a3,0x4
    80002878:	78c68693          	addi	a3,a3,1932 # 80007000 <_trampoline>
    8000287c:	8e91                	sub	a3,a3,a2
    8000287e:	040007b7          	lui	a5,0x4000
    80002882:	17fd                	addi	a5,a5,-1
    80002884:	07b2                	slli	a5,a5,0xc
    80002886:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002888:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000288c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000288e:	180026f3          	csrr	a3,satp
    80002892:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002894:	6d38                	ld	a4,88(a0)
    80002896:	6134                	ld	a3,64(a0)
    80002898:	6585                	lui	a1,0x1
    8000289a:	96ae                	add	a3,a3,a1
    8000289c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000289e:	6d38                	ld	a4,88(a0)
    800028a0:	00000697          	auipc	a3,0x0
    800028a4:	14668693          	addi	a3,a3,326 # 800029e6 <usertrap>
    800028a8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800028aa:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028ac:	8692                	mv	a3,tp
    800028ae:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028b4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028b8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028bc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028c0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028c2:	6f18                	ld	a4,24(a4)
    800028c4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028c8:	692c                	ld	a1,80(a0)
    800028ca:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028cc:	00004717          	auipc	a4,0x4
    800028d0:	7c470713          	addi	a4,a4,1988 # 80007090 <userret>
    800028d4:	8f11                	sub	a4,a4,a2
    800028d6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64, uint64))fn)(TRAPFRAME, satp);
    800028d8:	577d                	li	a4,-1
    800028da:	177e                	slli	a4,a4,0x3f
    800028dc:	8dd9                	or	a1,a1,a4
    800028de:	02000537          	lui	a0,0x2000
    800028e2:	157d                	addi	a0,a0,-1
    800028e4:	0536                	slli	a0,a0,0xd
    800028e6:	9782                	jalr	a5
}
    800028e8:	60a2                	ld	ra,8(sp)
    800028ea:	6402                	ld	s0,0(sp)
    800028ec:	0141                	addi	sp,sp,16
    800028ee:	8082                	ret

00000000800028f0 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800028f0:	1101                	addi	sp,sp,-32
    800028f2:	ec06                	sd	ra,24(sp)
    800028f4:	e822                	sd	s0,16(sp)
    800028f6:	e426                	sd	s1,8(sp)
    800028f8:	e04a                	sd	s2,0(sp)
    800028fa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028fc:	00015917          	auipc	s2,0x15
    80002900:	dd490913          	addi	s2,s2,-556 # 800176d0 <tickslock>
    80002904:	854a                	mv	a0,s2
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	2de080e7          	jalr	734(ra) # 80000be4 <acquire>
  ticks++;
    8000290e:	00006497          	auipc	s1,0x6
    80002912:	72248493          	addi	s1,s1,1826 # 80009030 <ticks>
    80002916:	409c                	lw	a5,0(s1)
    80002918:	2785                	addiw	a5,a5,1
    8000291a:	c09c                	sw	a5,0(s1)
  update_time();
    8000291c:	fffff097          	auipc	ra,0xfffff
    80002920:	5d2080e7          	jalr	1490(ra) # 80001eee <update_time>
  wakeup(&ticks);
    80002924:	8526                	mv	a0,s1
    80002926:	00000097          	auipc	ra,0x0
    8000292a:	b04080e7          	jalr	-1276(ra) # 8000242a <wakeup>
  release(&tickslock);
    8000292e:	854a                	mv	a0,s2
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	368080e7          	jalr	872(ra) # 80000c98 <release>
}
    80002938:	60e2                	ld	ra,24(sp)
    8000293a:	6442                	ld	s0,16(sp)
    8000293c:	64a2                	ld	s1,8(sp)
    8000293e:	6902                	ld	s2,0(sp)
    80002940:	6105                	addi	sp,sp,32
    80002942:	8082                	ret

0000000080002944 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002944:	1101                	addi	sp,sp,-32
    80002946:	ec06                	sd	ra,24(sp)
    80002948:	e822                	sd	s0,16(sp)
    8000294a:	e426                	sd	s1,8(sp)
    8000294c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000294e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002952:	00074d63          	bltz	a4,8000296c <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002956:	57fd                	li	a5,-1
    80002958:	17fe                	slli	a5,a5,0x3f
    8000295a:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    8000295c:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    8000295e:	06f70363          	beq	a4,a5,800029c4 <devintr+0x80>
  }
}
    80002962:	60e2                	ld	ra,24(sp)
    80002964:	6442                	ld	s0,16(sp)
    80002966:	64a2                	ld	s1,8(sp)
    80002968:	6105                	addi	sp,sp,32
    8000296a:	8082                	ret
      (scause & 0xff) == 9)
    8000296c:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002970:	46a5                	li	a3,9
    80002972:	fed792e3          	bne	a5,a3,80002956 <devintr+0x12>
    int irq = plic_claim();
    80002976:	00003097          	auipc	ra,0x3
    8000297a:	582080e7          	jalr	1410(ra) # 80005ef8 <plic_claim>
    8000297e:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002980:	47a9                	li	a5,10
    80002982:	02f50763          	beq	a0,a5,800029b0 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002986:	4785                	li	a5,1
    80002988:	02f50963          	beq	a0,a5,800029ba <devintr+0x76>
    return 1;
    8000298c:	4505                	li	a0,1
    else if (irq)
    8000298e:	d8f1                	beqz	s1,80002962 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002990:	85a6                	mv	a1,s1
    80002992:	00006517          	auipc	a0,0x6
    80002996:	96650513          	addi	a0,a0,-1690 # 800082f8 <states.1743+0x38>
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	bee080e7          	jalr	-1042(ra) # 80000588 <printf>
      plic_complete(irq);
    800029a2:	8526                	mv	a0,s1
    800029a4:	00003097          	auipc	ra,0x3
    800029a8:	578080e7          	jalr	1400(ra) # 80005f1c <plic_complete>
    return 1;
    800029ac:	4505                	li	a0,1
    800029ae:	bf55                	j	80002962 <devintr+0x1e>
      uartintr();
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	ff8080e7          	jalr	-8(ra) # 800009a8 <uartintr>
    800029b8:	b7ed                	j	800029a2 <devintr+0x5e>
      virtio_disk_intr();
    800029ba:	00004097          	auipc	ra,0x4
    800029be:	a42080e7          	jalr	-1470(ra) # 800063fc <virtio_disk_intr>
    800029c2:	b7c5                	j	800029a2 <devintr+0x5e>
    if (cpuid() == 0)
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	fc0080e7          	jalr	-64(ra) # 80001984 <cpuid>
    800029cc:	c901                	beqz	a0,800029dc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029ce:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029d2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029d4:	14479073          	csrw	sip,a5
    return 2;
    800029d8:	4509                	li	a0,2
    800029da:	b761                	j	80002962 <devintr+0x1e>
      clockintr();
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	f14080e7          	jalr	-236(ra) # 800028f0 <clockintr>
    800029e4:	b7ed                	j	800029ce <devintr+0x8a>

00000000800029e6 <usertrap>:
{
    800029e6:	1101                	addi	sp,sp,-32
    800029e8:	ec06                	sd	ra,24(sp)
    800029ea:	e822                	sd	s0,16(sp)
    800029ec:	e426                	sd	s1,8(sp)
    800029ee:	e04a                	sd	s2,0(sp)
    800029f0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f2:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800029f6:	1007f793          	andi	a5,a5,256
    800029fa:	e3ad                	bnez	a5,80002a5c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029fc:	00003797          	auipc	a5,0x3
    80002a00:	3f478793          	addi	a5,a5,1012 # 80005df0 <kernelvec>
    80002a04:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a08:	fffff097          	auipc	ra,0xfffff
    80002a0c:	fa8080e7          	jalr	-88(ra) # 800019b0 <myproc>
    80002a10:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a12:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a14:	14102773          	csrr	a4,sepc
    80002a18:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a1a:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002a1e:	47a1                	li	a5,8
    80002a20:	04f71c63          	bne	a4,a5,80002a78 <usertrap+0x92>
    if (p->killed)
    80002a24:	551c                	lw	a5,40(a0)
    80002a26:	e3b9                	bnez	a5,80002a6c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a28:	6cb8                	ld	a4,88(s1)
    80002a2a:	6f1c                	ld	a5,24(a4)
    80002a2c:	0791                	addi	a5,a5,4
    80002a2e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a30:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a34:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a38:	10079073          	csrw	sstatus,a5
    syscall();
    80002a3c:	00000097          	auipc	ra,0x0
    80002a40:	2e0080e7          	jalr	736(ra) # 80002d1c <syscall>
  if (p->killed)
    80002a44:	549c                	lw	a5,40(s1)
    80002a46:	ebc1                	bnez	a5,80002ad6 <usertrap+0xf0>
  usertrapret();
    80002a48:	00000097          	auipc	ra,0x0
    80002a4c:	e0a080e7          	jalr	-502(ra) # 80002852 <usertrapret>
}
    80002a50:	60e2                	ld	ra,24(sp)
    80002a52:	6442                	ld	s0,16(sp)
    80002a54:	64a2                	ld	s1,8(sp)
    80002a56:	6902                	ld	s2,0(sp)
    80002a58:	6105                	addi	sp,sp,32
    80002a5a:	8082                	ret
    panic("usertrap: not from user mode");
    80002a5c:	00006517          	auipc	a0,0x6
    80002a60:	8bc50513          	addi	a0,a0,-1860 # 80008318 <states.1743+0x58>
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	ada080e7          	jalr	-1318(ra) # 8000053e <panic>
      exit(-1);
    80002a6c:	557d                	li	a0,-1
    80002a6e:	00000097          	auipc	ra,0x0
    80002a72:	a8c080e7          	jalr	-1396(ra) # 800024fa <exit>
    80002a76:	bf4d                	j	80002a28 <usertrap+0x42>
  else if ((which_dev = devintr()) != 0)
    80002a78:	00000097          	auipc	ra,0x0
    80002a7c:	ecc080e7          	jalr	-308(ra) # 80002944 <devintr>
    80002a80:	892a                	mv	s2,a0
    80002a82:	c501                	beqz	a0,80002a8a <usertrap+0xa4>
  if (p->killed)
    80002a84:	549c                	lw	a5,40(s1)
    80002a86:	c3a1                	beqz	a5,80002ac6 <usertrap+0xe0>
    80002a88:	a815                	j	80002abc <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a8a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a8e:	5890                	lw	a2,48(s1)
    80002a90:	00006517          	auipc	a0,0x6
    80002a94:	8a850513          	addi	a0,a0,-1880 # 80008338 <states.1743+0x78>
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	af0080e7          	jalr	-1296(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aa0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aa4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aa8:	00006517          	auipc	a0,0x6
    80002aac:	8c050513          	addi	a0,a0,-1856 # 80008368 <states.1743+0xa8>
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	ad8080e7          	jalr	-1320(ra) # 80000588 <printf>
    p->killed = 1;
    80002ab8:	4785                	li	a5,1
    80002aba:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002abc:	557d                	li	a0,-1
    80002abe:	00000097          	auipc	ra,0x0
    80002ac2:	a3c080e7          	jalr	-1476(ra) # 800024fa <exit>
  if (which_dev == 2)
    80002ac6:	4789                	li	a5,2
    80002ac8:	f8f910e3          	bne	s2,a5,80002a48 <usertrap+0x62>
    yield();
    80002acc:	fffff097          	auipc	ra,0xfffff
    80002ad0:	64a080e7          	jalr	1610(ra) # 80002116 <yield>
    80002ad4:	bf95                	j	80002a48 <usertrap+0x62>
  int which_dev = 0;
    80002ad6:	4901                	li	s2,0
    80002ad8:	b7d5                	j	80002abc <usertrap+0xd6>

0000000080002ada <kerneltrap>:
{
    80002ada:	7179                	addi	sp,sp,-48
    80002adc:	f406                	sd	ra,40(sp)
    80002ade:	f022                	sd	s0,32(sp)
    80002ae0:	ec26                	sd	s1,24(sp)
    80002ae2:	e84a                	sd	s2,16(sp)
    80002ae4:	e44e                	sd	s3,8(sp)
    80002ae6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ae8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aec:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002af0:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002af4:	1004f793          	andi	a5,s1,256
    80002af8:	cb85                	beqz	a5,80002b28 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002afa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002afe:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002b00:	ef85                	bnez	a5,80002b38 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002b02:	00000097          	auipc	ra,0x0
    80002b06:	e42080e7          	jalr	-446(ra) # 80002944 <devintr>
    80002b0a:	cd1d                	beqz	a0,80002b48 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b0c:	4789                	li	a5,2
    80002b0e:	06f50a63          	beq	a0,a5,80002b82 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b12:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b16:	10049073          	csrw	sstatus,s1
}
    80002b1a:	70a2                	ld	ra,40(sp)
    80002b1c:	7402                	ld	s0,32(sp)
    80002b1e:	64e2                	ld	s1,24(sp)
    80002b20:	6942                	ld	s2,16(sp)
    80002b22:	69a2                	ld	s3,8(sp)
    80002b24:	6145                	addi	sp,sp,48
    80002b26:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b28:	00006517          	auipc	a0,0x6
    80002b2c:	86050513          	addi	a0,a0,-1952 # 80008388 <states.1743+0xc8>
    80002b30:	ffffe097          	auipc	ra,0xffffe
    80002b34:	a0e080e7          	jalr	-1522(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b38:	00006517          	auipc	a0,0x6
    80002b3c:	87850513          	addi	a0,a0,-1928 # 800083b0 <states.1743+0xf0>
    80002b40:	ffffe097          	auipc	ra,0xffffe
    80002b44:	9fe080e7          	jalr	-1538(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b48:	85ce                	mv	a1,s3
    80002b4a:	00006517          	auipc	a0,0x6
    80002b4e:	88650513          	addi	a0,a0,-1914 # 800083d0 <states.1743+0x110>
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	a36080e7          	jalr	-1482(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b5a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b5e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b62:	00006517          	auipc	a0,0x6
    80002b66:	87e50513          	addi	a0,a0,-1922 # 800083e0 <states.1743+0x120>
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	a1e080e7          	jalr	-1506(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b72:	00006517          	auipc	a0,0x6
    80002b76:	88650513          	addi	a0,a0,-1914 # 800083f8 <states.1743+0x138>
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	9c4080e7          	jalr	-1596(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b82:	fffff097          	auipc	ra,0xfffff
    80002b86:	e2e080e7          	jalr	-466(ra) # 800019b0 <myproc>
    80002b8a:	d541                	beqz	a0,80002b12 <kerneltrap+0x38>
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	e24080e7          	jalr	-476(ra) # 800019b0 <myproc>
    80002b94:	4d18                	lw	a4,24(a0)
    80002b96:	4791                	li	a5,4
    80002b98:	f6f71de3          	bne	a4,a5,80002b12 <kerneltrap+0x38>
    yield();
    80002b9c:	fffff097          	auipc	ra,0xfffff
    80002ba0:	57a080e7          	jalr	1402(ra) # 80002116 <yield>
    80002ba4:	b7bd                	j	80002b12 <kerneltrap+0x38>

0000000080002ba6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ba6:	1101                	addi	sp,sp,-32
    80002ba8:	ec06                	sd	ra,24(sp)
    80002baa:	e822                	sd	s0,16(sp)
    80002bac:	e426                	sd	s1,8(sp)
    80002bae:	1000                	addi	s0,sp,32
    80002bb0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bb2:	fffff097          	auipc	ra,0xfffff
    80002bb6:	dfe080e7          	jalr	-514(ra) # 800019b0 <myproc>
  switch (n) {
    80002bba:	4795                	li	a5,5
    80002bbc:	0497e163          	bltu	a5,s1,80002bfe <argraw+0x58>
    80002bc0:	048a                	slli	s1,s1,0x2
    80002bc2:	00006717          	auipc	a4,0x6
    80002bc6:	92e70713          	addi	a4,a4,-1746 # 800084f0 <states.1743+0x230>
    80002bca:	94ba                	add	s1,s1,a4
    80002bcc:	409c                	lw	a5,0(s1)
    80002bce:	97ba                	add	a5,a5,a4
    80002bd0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bd2:	6d3c                	ld	a5,88(a0)
    80002bd4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bd6:	60e2                	ld	ra,24(sp)
    80002bd8:	6442                	ld	s0,16(sp)
    80002bda:	64a2                	ld	s1,8(sp)
    80002bdc:	6105                	addi	sp,sp,32
    80002bde:	8082                	ret
    return p->trapframe->a1;
    80002be0:	6d3c                	ld	a5,88(a0)
    80002be2:	7fa8                	ld	a0,120(a5)
    80002be4:	bfcd                	j	80002bd6 <argraw+0x30>
    return p->trapframe->a2;
    80002be6:	6d3c                	ld	a5,88(a0)
    80002be8:	63c8                	ld	a0,128(a5)
    80002bea:	b7f5                	j	80002bd6 <argraw+0x30>
    return p->trapframe->a3;
    80002bec:	6d3c                	ld	a5,88(a0)
    80002bee:	67c8                	ld	a0,136(a5)
    80002bf0:	b7dd                	j	80002bd6 <argraw+0x30>
    return p->trapframe->a4;
    80002bf2:	6d3c                	ld	a5,88(a0)
    80002bf4:	6bc8                	ld	a0,144(a5)
    80002bf6:	b7c5                	j	80002bd6 <argraw+0x30>
    return p->trapframe->a5;
    80002bf8:	6d3c                	ld	a5,88(a0)
    80002bfa:	6fc8                	ld	a0,152(a5)
    80002bfc:	bfe9                	j	80002bd6 <argraw+0x30>
  panic("argraw");
    80002bfe:	00006517          	auipc	a0,0x6
    80002c02:	80a50513          	addi	a0,a0,-2038 # 80008408 <states.1743+0x148>
    80002c06:	ffffe097          	auipc	ra,0xffffe
    80002c0a:	938080e7          	jalr	-1736(ra) # 8000053e <panic>

0000000080002c0e <fetchaddr>:
{
    80002c0e:	1101                	addi	sp,sp,-32
    80002c10:	ec06                	sd	ra,24(sp)
    80002c12:	e822                	sd	s0,16(sp)
    80002c14:	e426                	sd	s1,8(sp)
    80002c16:	e04a                	sd	s2,0(sp)
    80002c18:	1000                	addi	s0,sp,32
    80002c1a:	84aa                	mv	s1,a0
    80002c1c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c1e:	fffff097          	auipc	ra,0xfffff
    80002c22:	d92080e7          	jalr	-622(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c26:	653c                	ld	a5,72(a0)
    80002c28:	02f4f863          	bgeu	s1,a5,80002c58 <fetchaddr+0x4a>
    80002c2c:	00848713          	addi	a4,s1,8
    80002c30:	02e7e663          	bltu	a5,a4,80002c5c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c34:	46a1                	li	a3,8
    80002c36:	8626                	mv	a2,s1
    80002c38:	85ca                	mv	a1,s2
    80002c3a:	6928                	ld	a0,80(a0)
    80002c3c:	fffff097          	auipc	ra,0xfffff
    80002c40:	ac2080e7          	jalr	-1342(ra) # 800016fe <copyin>
    80002c44:	00a03533          	snez	a0,a0
    80002c48:	40a00533          	neg	a0,a0
}
    80002c4c:	60e2                	ld	ra,24(sp)
    80002c4e:	6442                	ld	s0,16(sp)
    80002c50:	64a2                	ld	s1,8(sp)
    80002c52:	6902                	ld	s2,0(sp)
    80002c54:	6105                	addi	sp,sp,32
    80002c56:	8082                	ret
    return -1;
    80002c58:	557d                	li	a0,-1
    80002c5a:	bfcd                	j	80002c4c <fetchaddr+0x3e>
    80002c5c:	557d                	li	a0,-1
    80002c5e:	b7fd                	j	80002c4c <fetchaddr+0x3e>

0000000080002c60 <fetchstr>:
{
    80002c60:	7179                	addi	sp,sp,-48
    80002c62:	f406                	sd	ra,40(sp)
    80002c64:	f022                	sd	s0,32(sp)
    80002c66:	ec26                	sd	s1,24(sp)
    80002c68:	e84a                	sd	s2,16(sp)
    80002c6a:	e44e                	sd	s3,8(sp)
    80002c6c:	1800                	addi	s0,sp,48
    80002c6e:	892a                	mv	s2,a0
    80002c70:	84ae                	mv	s1,a1
    80002c72:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	d3c080e7          	jalr	-708(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c7c:	86ce                	mv	a3,s3
    80002c7e:	864a                	mv	a2,s2
    80002c80:	85a6                	mv	a1,s1
    80002c82:	6928                	ld	a0,80(a0)
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	b06080e7          	jalr	-1274(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002c8c:	00054763          	bltz	a0,80002c9a <fetchstr+0x3a>
  return strlen(buf);
    80002c90:	8526                	mv	a0,s1
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	1d2080e7          	jalr	466(ra) # 80000e64 <strlen>
}
    80002c9a:	70a2                	ld	ra,40(sp)
    80002c9c:	7402                	ld	s0,32(sp)
    80002c9e:	64e2                	ld	s1,24(sp)
    80002ca0:	6942                	ld	s2,16(sp)
    80002ca2:	69a2                	ld	s3,8(sp)
    80002ca4:	6145                	addi	sp,sp,48
    80002ca6:	8082                	ret

0000000080002ca8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ca8:	1101                	addi	sp,sp,-32
    80002caa:	ec06                	sd	ra,24(sp)
    80002cac:	e822                	sd	s0,16(sp)
    80002cae:	e426                	sd	s1,8(sp)
    80002cb0:	1000                	addi	s0,sp,32
    80002cb2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	ef2080e7          	jalr	-270(ra) # 80002ba6 <argraw>
    80002cbc:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cbe:	4501                	li	a0,0
    80002cc0:	60e2                	ld	ra,24(sp)
    80002cc2:	6442                	ld	s0,16(sp)
    80002cc4:	64a2                	ld	s1,8(sp)
    80002cc6:	6105                	addi	sp,sp,32
    80002cc8:	8082                	ret

0000000080002cca <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cca:	1101                	addi	sp,sp,-32
    80002ccc:	ec06                	sd	ra,24(sp)
    80002cce:	e822                	sd	s0,16(sp)
    80002cd0:	e426                	sd	s1,8(sp)
    80002cd2:	1000                	addi	s0,sp,32
    80002cd4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cd6:	00000097          	auipc	ra,0x0
    80002cda:	ed0080e7          	jalr	-304(ra) # 80002ba6 <argraw>
    80002cde:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ce0:	4501                	li	a0,0
    80002ce2:	60e2                	ld	ra,24(sp)
    80002ce4:	6442                	ld	s0,16(sp)
    80002ce6:	64a2                	ld	s1,8(sp)
    80002ce8:	6105                	addi	sp,sp,32
    80002cea:	8082                	ret

0000000080002cec <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cec:	1101                	addi	sp,sp,-32
    80002cee:	ec06                	sd	ra,24(sp)
    80002cf0:	e822                	sd	s0,16(sp)
    80002cf2:	e426                	sd	s1,8(sp)
    80002cf4:	e04a                	sd	s2,0(sp)
    80002cf6:	1000                	addi	s0,sp,32
    80002cf8:	84ae                	mv	s1,a1
    80002cfa:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cfc:	00000097          	auipc	ra,0x0
    80002d00:	eaa080e7          	jalr	-342(ra) # 80002ba6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d04:	864a                	mv	a2,s2
    80002d06:	85a6                	mv	a1,s1
    80002d08:	00000097          	auipc	ra,0x0
    80002d0c:	f58080e7          	jalr	-168(ra) # 80002c60 <fetchstr>
}
    80002d10:	60e2                	ld	ra,24(sp)
    80002d12:	6442                	ld	s0,16(sp)
    80002d14:	64a2                	ld	s1,8(sp)
    80002d16:	6902                	ld	s2,0(sp)
    80002d18:	6105                	addi	sp,sp,32
    80002d1a:	8082                	ret

0000000080002d1c <syscall>:
[SYS_strace]   "strace",
};

void
syscall(void)
{
    80002d1c:	7179                	addi	sp,sp,-48
    80002d1e:	f406                	sd	ra,40(sp)
    80002d20:	f022                	sd	s0,32(sp)
    80002d22:	ec26                	sd	s1,24(sp)
    80002d24:	e84a                	sd	s2,16(sp)
    80002d26:	e44e                	sd	s3,8(sp)
    80002d28:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	c86080e7          	jalr	-890(ra) # 800019b0 <myproc>
    80002d32:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d34:	05853903          	ld	s2,88(a0)
    80002d38:	0a893783          	ld	a5,168(s2)
    80002d3c:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d40:	37fd                	addiw	a5,a5,-1
    80002d42:	4759                	li	a4,22
    80002d44:	04f76863          	bltu	a4,a5,80002d94 <syscall+0x78>
    80002d48:	00399713          	slli	a4,s3,0x3
    80002d4c:	00005797          	auipc	a5,0x5
    80002d50:	7bc78793          	addi	a5,a5,1980 # 80008508 <syscalls>
    80002d54:	97ba                	add	a5,a5,a4
    80002d56:	639c                	ld	a5,0(a5)
    80002d58:	cf95                	beqz	a5,80002d94 <syscall+0x78>
    p->trapframe->a0 = syscalls[num]();
    80002d5a:	9782                	jalr	a5
    80002d5c:	06a93823          	sd	a0,112(s2)
     if(p->mask & 1 << num) 
    80002d60:	1744a783          	lw	a5,372(s1)
    80002d64:	4137d7bb          	sraw	a5,a5,s3
    80002d68:	8b85                	andi	a5,a5,1
    80002d6a:	c7a1                	beqz	a5,80002db2 <syscall+0x96>
      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);
    80002d6c:	6cb8                	ld	a4,88(s1)
    80002d6e:	098e                	slli	s3,s3,0x3
    80002d70:	00005797          	auipc	a5,0x5
    80002d74:	79878793          	addi	a5,a5,1944 # 80008508 <syscalls>
    80002d78:	99be                	add	s3,s3,a5
    80002d7a:	7b34                	ld	a3,112(a4)
    80002d7c:	0c09b603          	ld	a2,192(s3)
    80002d80:	588c                	lw	a1,48(s1)
    80002d82:	00005517          	auipc	a0,0x5
    80002d86:	68e50513          	addi	a0,a0,1678 # 80008410 <states.1743+0x150>
    80002d8a:	ffffd097          	auipc	ra,0xffffd
    80002d8e:	7fe080e7          	jalr	2046(ra) # 80000588 <printf>
    80002d92:	a005                	j	80002db2 <syscall+0x96>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d94:	86ce                	mv	a3,s3
    80002d96:	15848613          	addi	a2,s1,344
    80002d9a:	588c                	lw	a1,48(s1)
    80002d9c:	00005517          	auipc	a0,0x5
    80002da0:	68c50513          	addi	a0,a0,1676 # 80008428 <states.1743+0x168>
    80002da4:	ffffd097          	auipc	ra,0xffffd
    80002da8:	7e4080e7          	jalr	2020(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dac:	6cbc                	ld	a5,88(s1)
    80002dae:	577d                	li	a4,-1
    80002db0:	fbb8                	sd	a4,112(a5)
  }
}
    80002db2:	70a2                	ld	ra,40(sp)
    80002db4:	7402                	ld	s0,32(sp)
    80002db6:	64e2                	ld	s1,24(sp)
    80002db8:	6942                	ld	s2,16(sp)
    80002dba:	69a2                	ld	s3,8(sp)
    80002dbc:	6145                	addi	sp,sp,48
    80002dbe:	8082                	ret

0000000080002dc0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002dc0:	1101                	addi	sp,sp,-32
    80002dc2:	ec06                	sd	ra,24(sp)
    80002dc4:	e822                	sd	s0,16(sp)
    80002dc6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002dc8:	fec40593          	addi	a1,s0,-20
    80002dcc:	4501                	li	a0,0
    80002dce:	00000097          	auipc	ra,0x0
    80002dd2:	eda080e7          	jalr	-294(ra) # 80002ca8 <argint>
    return -1;
    80002dd6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dd8:	00054963          	bltz	a0,80002dea <sys_exit+0x2a>
  exit(n);
    80002ddc:	fec42503          	lw	a0,-20(s0)
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	71a080e7          	jalr	1818(ra) # 800024fa <exit>
  return 0;  // not reached
    80002de8:	4781                	li	a5,0
}
    80002dea:	853e                	mv	a0,a5
    80002dec:	60e2                	ld	ra,24(sp)
    80002dee:	6442                	ld	s0,16(sp)
    80002df0:	6105                	addi	sp,sp,32
    80002df2:	8082                	ret

0000000080002df4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002df4:	1141                	addi	sp,sp,-16
    80002df6:	e406                	sd	ra,8(sp)
    80002df8:	e022                	sd	s0,0(sp)
    80002dfa:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	bb4080e7          	jalr	-1100(ra) # 800019b0 <myproc>
}
    80002e04:	5908                	lw	a0,48(a0)
    80002e06:	60a2                	ld	ra,8(sp)
    80002e08:	6402                	ld	s0,0(sp)
    80002e0a:	0141                	addi	sp,sp,16
    80002e0c:	8082                	ret

0000000080002e0e <sys_fork>:

uint64
sys_fork(void)
{
    80002e0e:	1141                	addi	sp,sp,-16
    80002e10:	e406                	sd	ra,8(sp)
    80002e12:	e022                	sd	s0,0(sp)
    80002e14:	0800                	addi	s0,sp,16
  return fork();
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	f90080e7          	jalr	-112(ra) # 80001da6 <fork>
}
    80002e1e:	60a2                	ld	ra,8(sp)
    80002e20:	6402                	ld	s0,0(sp)
    80002e22:	0141                	addi	sp,sp,16
    80002e24:	8082                	ret

0000000080002e26 <sys_wait>:

uint64
sys_wait(void)
{
    80002e26:	1101                	addi	sp,sp,-32
    80002e28:	ec06                	sd	ra,24(sp)
    80002e2a:	e822                	sd	s0,16(sp)
    80002e2c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e2e:	fe840593          	addi	a1,s0,-24
    80002e32:	4501                	li	a0,0
    80002e34:	00000097          	auipc	ra,0x0
    80002e38:	e96080e7          	jalr	-362(ra) # 80002cca <argaddr>
    80002e3c:	87aa                	mv	a5,a0
    return -1;
    80002e3e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e40:	0007c863          	bltz	a5,80002e50 <sys_wait+0x2a>
  return wait(p);
    80002e44:	fe843503          	ld	a0,-24(s0)
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	36e080e7          	jalr	878(ra) # 800021b6 <wait>
}
    80002e50:	60e2                	ld	ra,24(sp)
    80002e52:	6442                	ld	s0,16(sp)
    80002e54:	6105                	addi	sp,sp,32
    80002e56:	8082                	ret

0000000080002e58 <sys_waitx>:

uint64
sys_waitx(void)
{
    80002e58:	7139                	addi	sp,sp,-64
    80002e5a:	fc06                	sd	ra,56(sp)
    80002e5c:	f822                	sd	s0,48(sp)
    80002e5e:	f426                	sd	s1,40(sp)
    80002e60:	f04a                	sd	s2,32(sp)
    80002e62:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  if(argaddr(0, &addr) < 0)
    80002e64:	fd840593          	addi	a1,s0,-40
    80002e68:	4501                	li	a0,0
    80002e6a:	00000097          	auipc	ra,0x0
    80002e6e:	e60080e7          	jalr	-416(ra) # 80002cca <argaddr>
    return -1;
    80002e72:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0)
    80002e74:	08054063          	bltz	a0,80002ef4 <sys_waitx+0x9c>
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80002e78:	fd040593          	addi	a1,s0,-48
    80002e7c:	4505                	li	a0,1
    80002e7e:	00000097          	auipc	ra,0x0
    80002e82:	e4c080e7          	jalr	-436(ra) # 80002cca <argaddr>
    return -1;
    80002e86:	57fd                	li	a5,-1
  if(argaddr(1, &addr1) < 0) // user virtual memory
    80002e88:	06054663          	bltz	a0,80002ef4 <sys_waitx+0x9c>
  if(argaddr(2, &addr2) < 0)
    80002e8c:	fc840593          	addi	a1,s0,-56
    80002e90:	4509                	li	a0,2
    80002e92:	00000097          	auipc	ra,0x0
    80002e96:	e38080e7          	jalr	-456(ra) # 80002cca <argaddr>
    return -1;
    80002e9a:	57fd                	li	a5,-1
  if(argaddr(2, &addr2) < 0)
    80002e9c:	04054c63          	bltz	a0,80002ef4 <sys_waitx+0x9c>
  int ret = waitx(addr, &wtime, &rtime);
    80002ea0:	fc040613          	addi	a2,s0,-64
    80002ea4:	fc440593          	addi	a1,s0,-60
    80002ea8:	fd843503          	ld	a0,-40(s0)
    80002eac:	fffff097          	auipc	ra,0xfffff
    80002eb0:	432080e7          	jalr	1074(ra) # 800022de <waitx>
    80002eb4:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	afa080e7          	jalr	-1286(ra) # 800019b0 <myproc>
    80002ebe:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002ec0:	4691                	li	a3,4
    80002ec2:	fc440613          	addi	a2,s0,-60
    80002ec6:	fd043583          	ld	a1,-48(s0)
    80002eca:	6928                	ld	a0,80(a0)
    80002ecc:	ffffe097          	auipc	ra,0xffffe
    80002ed0:	7a6080e7          	jalr	1958(ra) # 80001672 <copyout>
    return -1;
    80002ed4:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002ed6:	00054f63          	bltz	a0,80002ef4 <sys_waitx+0x9c>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80002eda:	4691                	li	a3,4
    80002edc:	fc040613          	addi	a2,s0,-64
    80002ee0:	fc843583          	ld	a1,-56(s0)
    80002ee4:	68a8                	ld	a0,80(s1)
    80002ee6:	ffffe097          	auipc	ra,0xffffe
    80002eea:	78c080e7          	jalr	1932(ra) # 80001672 <copyout>
    80002eee:	00054a63          	bltz	a0,80002f02 <sys_waitx+0xaa>
    return -1;
  return ret;
    80002ef2:	87ca                	mv	a5,s2
}
    80002ef4:	853e                	mv	a0,a5
    80002ef6:	70e2                	ld	ra,56(sp)
    80002ef8:	7442                	ld	s0,48(sp)
    80002efa:	74a2                	ld	s1,40(sp)
    80002efc:	7902                	ld	s2,32(sp)
    80002efe:	6121                	addi	sp,sp,64
    80002f00:	8082                	ret
    return -1;
    80002f02:	57fd                	li	a5,-1
    80002f04:	bfc5                	j	80002ef4 <sys_waitx+0x9c>

0000000080002f06 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f06:	7179                	addi	sp,sp,-48
    80002f08:	f406                	sd	ra,40(sp)
    80002f0a:	f022                	sd	s0,32(sp)
    80002f0c:	ec26                	sd	s1,24(sp)
    80002f0e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f10:	fdc40593          	addi	a1,s0,-36
    80002f14:	4501                	li	a0,0
    80002f16:	00000097          	auipc	ra,0x0
    80002f1a:	d92080e7          	jalr	-622(ra) # 80002ca8 <argint>
    80002f1e:	87aa                	mv	a5,a0
    return -1;
    80002f20:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f22:	0207c063          	bltz	a5,80002f42 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	a8a080e7          	jalr	-1398(ra) # 800019b0 <myproc>
    80002f2e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f30:	fdc42503          	lw	a0,-36(s0)
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	dfe080e7          	jalr	-514(ra) # 80001d32 <growproc>
    80002f3c:	00054863          	bltz	a0,80002f4c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f40:	8526                	mv	a0,s1
}
    80002f42:	70a2                	ld	ra,40(sp)
    80002f44:	7402                	ld	s0,32(sp)
    80002f46:	64e2                	ld	s1,24(sp)
    80002f48:	6145                	addi	sp,sp,48
    80002f4a:	8082                	ret
    return -1;
    80002f4c:	557d                	li	a0,-1
    80002f4e:	bfd5                	j	80002f42 <sys_sbrk+0x3c>

0000000080002f50 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f50:	7139                	addi	sp,sp,-64
    80002f52:	fc06                	sd	ra,56(sp)
    80002f54:	f822                	sd	s0,48(sp)
    80002f56:	f426                	sd	s1,40(sp)
    80002f58:	f04a                	sd	s2,32(sp)
    80002f5a:	ec4e                	sd	s3,24(sp)
    80002f5c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f5e:	fcc40593          	addi	a1,s0,-52
    80002f62:	4501                	li	a0,0
    80002f64:	00000097          	auipc	ra,0x0
    80002f68:	d44080e7          	jalr	-700(ra) # 80002ca8 <argint>
    return -1;
    80002f6c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f6e:	06054563          	bltz	a0,80002fd8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f72:	00014517          	auipc	a0,0x14
    80002f76:	75e50513          	addi	a0,a0,1886 # 800176d0 <tickslock>
    80002f7a:	ffffe097          	auipc	ra,0xffffe
    80002f7e:	c6a080e7          	jalr	-918(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f82:	00006917          	auipc	s2,0x6
    80002f86:	0ae92903          	lw	s2,174(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002f8a:	fcc42783          	lw	a5,-52(s0)
    80002f8e:	cf85                	beqz	a5,80002fc6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f90:	00014997          	auipc	s3,0x14
    80002f94:	74098993          	addi	s3,s3,1856 # 800176d0 <tickslock>
    80002f98:	00006497          	auipc	s1,0x6
    80002f9c:	09848493          	addi	s1,s1,152 # 80009030 <ticks>
    if(myproc()->killed){
    80002fa0:	fffff097          	auipc	ra,0xfffff
    80002fa4:	a10080e7          	jalr	-1520(ra) # 800019b0 <myproc>
    80002fa8:	551c                	lw	a5,40(a0)
    80002faa:	ef9d                	bnez	a5,80002fe8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fac:	85ce                	mv	a1,s3
    80002fae:	8526                	mv	a0,s1
    80002fb0:	fffff097          	auipc	ra,0xfffff
    80002fb4:	1a2080e7          	jalr	418(ra) # 80002152 <sleep>
  while(ticks - ticks0 < n){
    80002fb8:	409c                	lw	a5,0(s1)
    80002fba:	412787bb          	subw	a5,a5,s2
    80002fbe:	fcc42703          	lw	a4,-52(s0)
    80002fc2:	fce7efe3          	bltu	a5,a4,80002fa0 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002fc6:	00014517          	auipc	a0,0x14
    80002fca:	70a50513          	addi	a0,a0,1802 # 800176d0 <tickslock>
    80002fce:	ffffe097          	auipc	ra,0xffffe
    80002fd2:	cca080e7          	jalr	-822(ra) # 80000c98 <release>
  return 0;
    80002fd6:	4781                	li	a5,0
}
    80002fd8:	853e                	mv	a0,a5
    80002fda:	70e2                	ld	ra,56(sp)
    80002fdc:	7442                	ld	s0,48(sp)
    80002fde:	74a2                	ld	s1,40(sp)
    80002fe0:	7902                	ld	s2,32(sp)
    80002fe2:	69e2                	ld	s3,24(sp)
    80002fe4:	6121                	addi	sp,sp,64
    80002fe6:	8082                	ret
      release(&tickslock);
    80002fe8:	00014517          	auipc	a0,0x14
    80002fec:	6e850513          	addi	a0,a0,1768 # 800176d0 <tickslock>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	ca8080e7          	jalr	-856(ra) # 80000c98 <release>
      return -1;
    80002ff8:	57fd                	li	a5,-1
    80002ffa:	bff9                	j	80002fd8 <sys_sleep+0x88>

0000000080002ffc <sys_kill>:

uint64
sys_kill(void)
{
    80002ffc:	1101                	addi	sp,sp,-32
    80002ffe:	ec06                	sd	ra,24(sp)
    80003000:	e822                	sd	s0,16(sp)
    80003002:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003004:	fec40593          	addi	a1,s0,-20
    80003008:	4501                	li	a0,0
    8000300a:	00000097          	auipc	ra,0x0
    8000300e:	c9e080e7          	jalr	-866(ra) # 80002ca8 <argint>
    80003012:	87aa                	mv	a5,a0
    return -1;
    80003014:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003016:	0007c863          	bltz	a5,80003026 <sys_kill+0x2a>
  return kill(pid);
    8000301a:	fec42503          	lw	a0,-20(s0)
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	5be080e7          	jalr	1470(ra) # 800025dc <kill>
}
    80003026:	60e2                	ld	ra,24(sp)
    80003028:	6442                	ld	s0,16(sp)
    8000302a:	6105                	addi	sp,sp,32
    8000302c:	8082                	ret

000000008000302e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000302e:	1101                	addi	sp,sp,-32
    80003030:	ec06                	sd	ra,24(sp)
    80003032:	e822                	sd	s0,16(sp)
    80003034:	e426                	sd	s1,8(sp)
    80003036:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003038:	00014517          	auipc	a0,0x14
    8000303c:	69850513          	addi	a0,a0,1688 # 800176d0 <tickslock>
    80003040:	ffffe097          	auipc	ra,0xffffe
    80003044:	ba4080e7          	jalr	-1116(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003048:	00006497          	auipc	s1,0x6
    8000304c:	fe84a483          	lw	s1,-24(s1) # 80009030 <ticks>
  release(&tickslock);
    80003050:	00014517          	auipc	a0,0x14
    80003054:	68050513          	addi	a0,a0,1664 # 800176d0 <tickslock>
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	c40080e7          	jalr	-960(ra) # 80000c98 <release>
  return xticks;
}
    80003060:	02049513          	slli	a0,s1,0x20
    80003064:	9101                	srli	a0,a0,0x20
    80003066:	60e2                	ld	ra,24(sp)
    80003068:	6442                	ld	s0,16(sp)
    8000306a:	64a2                	ld	s1,8(sp)
    8000306c:	6105                	addi	sp,sp,32
    8000306e:	8082                	ret

0000000080003070 <sys_strace>:

uint64
sys_strace() 
{
    80003070:	1101                	addi	sp,sp,-32
    80003072:	ec06                	sd	ra,24(sp)
    80003074:	e822                	sd	s0,16(sp)
    80003076:	1000                	addi	s0,sp,32
  int mask;

  if(argint(0, &mask) < 0)
    80003078:	fec40593          	addi	a1,s0,-20
    8000307c:	4501                	li	a0,0
    8000307e:	00000097          	auipc	ra,0x0
    80003082:	c2a080e7          	jalr	-982(ra) # 80002ca8 <argint>
    return -1;
    80003086:	57fd                	li	a5,-1
  if(argint(0, &mask) < 0)
    80003088:	00054b63          	bltz	a0,8000309e <sys_strace+0x2e>
  myproc()-> mask = mask;
    8000308c:	fffff097          	auipc	ra,0xfffff
    80003090:	924080e7          	jalr	-1756(ra) # 800019b0 <myproc>
    80003094:	fec42783          	lw	a5,-20(s0)
    80003098:	16f52a23          	sw	a5,372(a0)
  return 0;
    8000309c:	4781                	li	a5,0
    8000309e:	853e                	mv	a0,a5
    800030a0:	60e2                	ld	ra,24(sp)
    800030a2:	6442                	ld	s0,16(sp)
    800030a4:	6105                	addi	sp,sp,32
    800030a6:	8082                	ret

00000000800030a8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030a8:	7179                	addi	sp,sp,-48
    800030aa:	f406                	sd	ra,40(sp)
    800030ac:	f022                	sd	s0,32(sp)
    800030ae:	ec26                	sd	s1,24(sp)
    800030b0:	e84a                	sd	s2,16(sp)
    800030b2:	e44e                	sd	s3,8(sp)
    800030b4:	e052                	sd	s4,0(sp)
    800030b6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030b8:	00005597          	auipc	a1,0x5
    800030bc:	5d058593          	addi	a1,a1,1488 # 80008688 <syscall_names+0xc0>
    800030c0:	00014517          	auipc	a0,0x14
    800030c4:	62850513          	addi	a0,a0,1576 # 800176e8 <bcache>
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	a8c080e7          	jalr	-1396(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030d0:	0001c797          	auipc	a5,0x1c
    800030d4:	61878793          	addi	a5,a5,1560 # 8001f6e8 <bcache+0x8000>
    800030d8:	0001d717          	auipc	a4,0x1d
    800030dc:	87870713          	addi	a4,a4,-1928 # 8001f950 <bcache+0x8268>
    800030e0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030e4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030e8:	00014497          	auipc	s1,0x14
    800030ec:	61848493          	addi	s1,s1,1560 # 80017700 <bcache+0x18>
    b->next = bcache.head.next;
    800030f0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030f2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030f4:	00005a17          	auipc	s4,0x5
    800030f8:	59ca0a13          	addi	s4,s4,1436 # 80008690 <syscall_names+0xc8>
    b->next = bcache.head.next;
    800030fc:	2b893783          	ld	a5,696(s2)
    80003100:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003102:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003106:	85d2                	mv	a1,s4
    80003108:	01048513          	addi	a0,s1,16
    8000310c:	00001097          	auipc	ra,0x1
    80003110:	4bc080e7          	jalr	1212(ra) # 800045c8 <initsleeplock>
    bcache.head.next->prev = b;
    80003114:	2b893783          	ld	a5,696(s2)
    80003118:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000311a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000311e:	45848493          	addi	s1,s1,1112
    80003122:	fd349de3          	bne	s1,s3,800030fc <binit+0x54>
  }
}
    80003126:	70a2                	ld	ra,40(sp)
    80003128:	7402                	ld	s0,32(sp)
    8000312a:	64e2                	ld	s1,24(sp)
    8000312c:	6942                	ld	s2,16(sp)
    8000312e:	69a2                	ld	s3,8(sp)
    80003130:	6a02                	ld	s4,0(sp)
    80003132:	6145                	addi	sp,sp,48
    80003134:	8082                	ret

0000000080003136 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003136:	7179                	addi	sp,sp,-48
    80003138:	f406                	sd	ra,40(sp)
    8000313a:	f022                	sd	s0,32(sp)
    8000313c:	ec26                	sd	s1,24(sp)
    8000313e:	e84a                	sd	s2,16(sp)
    80003140:	e44e                	sd	s3,8(sp)
    80003142:	1800                	addi	s0,sp,48
    80003144:	89aa                	mv	s3,a0
    80003146:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003148:	00014517          	auipc	a0,0x14
    8000314c:	5a050513          	addi	a0,a0,1440 # 800176e8 <bcache>
    80003150:	ffffe097          	auipc	ra,0xffffe
    80003154:	a94080e7          	jalr	-1388(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003158:	0001d497          	auipc	s1,0x1d
    8000315c:	8484b483          	ld	s1,-1976(s1) # 8001f9a0 <bcache+0x82b8>
    80003160:	0001c797          	auipc	a5,0x1c
    80003164:	7f078793          	addi	a5,a5,2032 # 8001f950 <bcache+0x8268>
    80003168:	02f48f63          	beq	s1,a5,800031a6 <bread+0x70>
    8000316c:	873e                	mv	a4,a5
    8000316e:	a021                	j	80003176 <bread+0x40>
    80003170:	68a4                	ld	s1,80(s1)
    80003172:	02e48a63          	beq	s1,a4,800031a6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003176:	449c                	lw	a5,8(s1)
    80003178:	ff379ce3          	bne	a5,s3,80003170 <bread+0x3a>
    8000317c:	44dc                	lw	a5,12(s1)
    8000317e:	ff2799e3          	bne	a5,s2,80003170 <bread+0x3a>
      b->refcnt++;
    80003182:	40bc                	lw	a5,64(s1)
    80003184:	2785                	addiw	a5,a5,1
    80003186:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003188:	00014517          	auipc	a0,0x14
    8000318c:	56050513          	addi	a0,a0,1376 # 800176e8 <bcache>
    80003190:	ffffe097          	auipc	ra,0xffffe
    80003194:	b08080e7          	jalr	-1272(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003198:	01048513          	addi	a0,s1,16
    8000319c:	00001097          	auipc	ra,0x1
    800031a0:	466080e7          	jalr	1126(ra) # 80004602 <acquiresleep>
      return b;
    800031a4:	a8b9                	j	80003202 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031a6:	0001c497          	auipc	s1,0x1c
    800031aa:	7f24b483          	ld	s1,2034(s1) # 8001f998 <bcache+0x82b0>
    800031ae:	0001c797          	auipc	a5,0x1c
    800031b2:	7a278793          	addi	a5,a5,1954 # 8001f950 <bcache+0x8268>
    800031b6:	00f48863          	beq	s1,a5,800031c6 <bread+0x90>
    800031ba:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031bc:	40bc                	lw	a5,64(s1)
    800031be:	cf81                	beqz	a5,800031d6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031c0:	64a4                	ld	s1,72(s1)
    800031c2:	fee49de3          	bne	s1,a4,800031bc <bread+0x86>
  panic("bget: no buffers");
    800031c6:	00005517          	auipc	a0,0x5
    800031ca:	4d250513          	addi	a0,a0,1234 # 80008698 <syscall_names+0xd0>
    800031ce:	ffffd097          	auipc	ra,0xffffd
    800031d2:	370080e7          	jalr	880(ra) # 8000053e <panic>
      b->dev = dev;
    800031d6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800031da:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800031de:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031e2:	4785                	li	a5,1
    800031e4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031e6:	00014517          	auipc	a0,0x14
    800031ea:	50250513          	addi	a0,a0,1282 # 800176e8 <bcache>
    800031ee:	ffffe097          	auipc	ra,0xffffe
    800031f2:	aaa080e7          	jalr	-1366(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800031f6:	01048513          	addi	a0,s1,16
    800031fa:	00001097          	auipc	ra,0x1
    800031fe:	408080e7          	jalr	1032(ra) # 80004602 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003202:	409c                	lw	a5,0(s1)
    80003204:	cb89                	beqz	a5,80003216 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003206:	8526                	mv	a0,s1
    80003208:	70a2                	ld	ra,40(sp)
    8000320a:	7402                	ld	s0,32(sp)
    8000320c:	64e2                	ld	s1,24(sp)
    8000320e:	6942                	ld	s2,16(sp)
    80003210:	69a2                	ld	s3,8(sp)
    80003212:	6145                	addi	sp,sp,48
    80003214:	8082                	ret
    virtio_disk_rw(b, 0);
    80003216:	4581                	li	a1,0
    80003218:	8526                	mv	a0,s1
    8000321a:	00003097          	auipc	ra,0x3
    8000321e:	f0c080e7          	jalr	-244(ra) # 80006126 <virtio_disk_rw>
    b->valid = 1;
    80003222:	4785                	li	a5,1
    80003224:	c09c                	sw	a5,0(s1)
  return b;
    80003226:	b7c5                	j	80003206 <bread+0xd0>

0000000080003228 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003228:	1101                	addi	sp,sp,-32
    8000322a:	ec06                	sd	ra,24(sp)
    8000322c:	e822                	sd	s0,16(sp)
    8000322e:	e426                	sd	s1,8(sp)
    80003230:	1000                	addi	s0,sp,32
    80003232:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003234:	0541                	addi	a0,a0,16
    80003236:	00001097          	auipc	ra,0x1
    8000323a:	466080e7          	jalr	1126(ra) # 8000469c <holdingsleep>
    8000323e:	cd01                	beqz	a0,80003256 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003240:	4585                	li	a1,1
    80003242:	8526                	mv	a0,s1
    80003244:	00003097          	auipc	ra,0x3
    80003248:	ee2080e7          	jalr	-286(ra) # 80006126 <virtio_disk_rw>
}
    8000324c:	60e2                	ld	ra,24(sp)
    8000324e:	6442                	ld	s0,16(sp)
    80003250:	64a2                	ld	s1,8(sp)
    80003252:	6105                	addi	sp,sp,32
    80003254:	8082                	ret
    panic("bwrite");
    80003256:	00005517          	auipc	a0,0x5
    8000325a:	45a50513          	addi	a0,a0,1114 # 800086b0 <syscall_names+0xe8>
    8000325e:	ffffd097          	auipc	ra,0xffffd
    80003262:	2e0080e7          	jalr	736(ra) # 8000053e <panic>

0000000080003266 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003266:	1101                	addi	sp,sp,-32
    80003268:	ec06                	sd	ra,24(sp)
    8000326a:	e822                	sd	s0,16(sp)
    8000326c:	e426                	sd	s1,8(sp)
    8000326e:	e04a                	sd	s2,0(sp)
    80003270:	1000                	addi	s0,sp,32
    80003272:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003274:	01050913          	addi	s2,a0,16
    80003278:	854a                	mv	a0,s2
    8000327a:	00001097          	auipc	ra,0x1
    8000327e:	422080e7          	jalr	1058(ra) # 8000469c <holdingsleep>
    80003282:	c92d                	beqz	a0,800032f4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003284:	854a                	mv	a0,s2
    80003286:	00001097          	auipc	ra,0x1
    8000328a:	3d2080e7          	jalr	978(ra) # 80004658 <releasesleep>

  acquire(&bcache.lock);
    8000328e:	00014517          	auipc	a0,0x14
    80003292:	45a50513          	addi	a0,a0,1114 # 800176e8 <bcache>
    80003296:	ffffe097          	auipc	ra,0xffffe
    8000329a:	94e080e7          	jalr	-1714(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000329e:	40bc                	lw	a5,64(s1)
    800032a0:	37fd                	addiw	a5,a5,-1
    800032a2:	0007871b          	sext.w	a4,a5
    800032a6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032a8:	eb05                	bnez	a4,800032d8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032aa:	68bc                	ld	a5,80(s1)
    800032ac:	64b8                	ld	a4,72(s1)
    800032ae:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032b0:	64bc                	ld	a5,72(s1)
    800032b2:	68b8                	ld	a4,80(s1)
    800032b4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032b6:	0001c797          	auipc	a5,0x1c
    800032ba:	43278793          	addi	a5,a5,1074 # 8001f6e8 <bcache+0x8000>
    800032be:	2b87b703          	ld	a4,696(a5)
    800032c2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032c4:	0001c717          	auipc	a4,0x1c
    800032c8:	68c70713          	addi	a4,a4,1676 # 8001f950 <bcache+0x8268>
    800032cc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032ce:	2b87b703          	ld	a4,696(a5)
    800032d2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032d4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032d8:	00014517          	auipc	a0,0x14
    800032dc:	41050513          	addi	a0,a0,1040 # 800176e8 <bcache>
    800032e0:	ffffe097          	auipc	ra,0xffffe
    800032e4:	9b8080e7          	jalr	-1608(ra) # 80000c98 <release>
}
    800032e8:	60e2                	ld	ra,24(sp)
    800032ea:	6442                	ld	s0,16(sp)
    800032ec:	64a2                	ld	s1,8(sp)
    800032ee:	6902                	ld	s2,0(sp)
    800032f0:	6105                	addi	sp,sp,32
    800032f2:	8082                	ret
    panic("brelse");
    800032f4:	00005517          	auipc	a0,0x5
    800032f8:	3c450513          	addi	a0,a0,964 # 800086b8 <syscall_names+0xf0>
    800032fc:	ffffd097          	auipc	ra,0xffffd
    80003300:	242080e7          	jalr	578(ra) # 8000053e <panic>

0000000080003304 <bpin>:

void
bpin(struct buf *b) {
    80003304:	1101                	addi	sp,sp,-32
    80003306:	ec06                	sd	ra,24(sp)
    80003308:	e822                	sd	s0,16(sp)
    8000330a:	e426                	sd	s1,8(sp)
    8000330c:	1000                	addi	s0,sp,32
    8000330e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003310:	00014517          	auipc	a0,0x14
    80003314:	3d850513          	addi	a0,a0,984 # 800176e8 <bcache>
    80003318:	ffffe097          	auipc	ra,0xffffe
    8000331c:	8cc080e7          	jalr	-1844(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003320:	40bc                	lw	a5,64(s1)
    80003322:	2785                	addiw	a5,a5,1
    80003324:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003326:	00014517          	auipc	a0,0x14
    8000332a:	3c250513          	addi	a0,a0,962 # 800176e8 <bcache>
    8000332e:	ffffe097          	auipc	ra,0xffffe
    80003332:	96a080e7          	jalr	-1686(ra) # 80000c98 <release>
}
    80003336:	60e2                	ld	ra,24(sp)
    80003338:	6442                	ld	s0,16(sp)
    8000333a:	64a2                	ld	s1,8(sp)
    8000333c:	6105                	addi	sp,sp,32
    8000333e:	8082                	ret

0000000080003340 <bunpin>:

void
bunpin(struct buf *b) {
    80003340:	1101                	addi	sp,sp,-32
    80003342:	ec06                	sd	ra,24(sp)
    80003344:	e822                	sd	s0,16(sp)
    80003346:	e426                	sd	s1,8(sp)
    80003348:	1000                	addi	s0,sp,32
    8000334a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000334c:	00014517          	auipc	a0,0x14
    80003350:	39c50513          	addi	a0,a0,924 # 800176e8 <bcache>
    80003354:	ffffe097          	auipc	ra,0xffffe
    80003358:	890080e7          	jalr	-1904(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000335c:	40bc                	lw	a5,64(s1)
    8000335e:	37fd                	addiw	a5,a5,-1
    80003360:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003362:	00014517          	auipc	a0,0x14
    80003366:	38650513          	addi	a0,a0,902 # 800176e8 <bcache>
    8000336a:	ffffe097          	auipc	ra,0xffffe
    8000336e:	92e080e7          	jalr	-1746(ra) # 80000c98 <release>
}
    80003372:	60e2                	ld	ra,24(sp)
    80003374:	6442                	ld	s0,16(sp)
    80003376:	64a2                	ld	s1,8(sp)
    80003378:	6105                	addi	sp,sp,32
    8000337a:	8082                	ret

000000008000337c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000337c:	1101                	addi	sp,sp,-32
    8000337e:	ec06                	sd	ra,24(sp)
    80003380:	e822                	sd	s0,16(sp)
    80003382:	e426                	sd	s1,8(sp)
    80003384:	e04a                	sd	s2,0(sp)
    80003386:	1000                	addi	s0,sp,32
    80003388:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000338a:	00d5d59b          	srliw	a1,a1,0xd
    8000338e:	0001d797          	auipc	a5,0x1d
    80003392:	a367a783          	lw	a5,-1482(a5) # 8001fdc4 <sb+0x1c>
    80003396:	9dbd                	addw	a1,a1,a5
    80003398:	00000097          	auipc	ra,0x0
    8000339c:	d9e080e7          	jalr	-610(ra) # 80003136 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033a0:	0074f713          	andi	a4,s1,7
    800033a4:	4785                	li	a5,1
    800033a6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033aa:	14ce                	slli	s1,s1,0x33
    800033ac:	90d9                	srli	s1,s1,0x36
    800033ae:	00950733          	add	a4,a0,s1
    800033b2:	05874703          	lbu	a4,88(a4)
    800033b6:	00e7f6b3          	and	a3,a5,a4
    800033ba:	c69d                	beqz	a3,800033e8 <bfree+0x6c>
    800033bc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033be:	94aa                	add	s1,s1,a0
    800033c0:	fff7c793          	not	a5,a5
    800033c4:	8ff9                	and	a5,a5,a4
    800033c6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033ca:	00001097          	auipc	ra,0x1
    800033ce:	118080e7          	jalr	280(ra) # 800044e2 <log_write>
  brelse(bp);
    800033d2:	854a                	mv	a0,s2
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	e92080e7          	jalr	-366(ra) # 80003266 <brelse>
}
    800033dc:	60e2                	ld	ra,24(sp)
    800033de:	6442                	ld	s0,16(sp)
    800033e0:	64a2                	ld	s1,8(sp)
    800033e2:	6902                	ld	s2,0(sp)
    800033e4:	6105                	addi	sp,sp,32
    800033e6:	8082                	ret
    panic("freeing free block");
    800033e8:	00005517          	auipc	a0,0x5
    800033ec:	2d850513          	addi	a0,a0,728 # 800086c0 <syscall_names+0xf8>
    800033f0:	ffffd097          	auipc	ra,0xffffd
    800033f4:	14e080e7          	jalr	334(ra) # 8000053e <panic>

00000000800033f8 <balloc>:
{
    800033f8:	711d                	addi	sp,sp,-96
    800033fa:	ec86                	sd	ra,88(sp)
    800033fc:	e8a2                	sd	s0,80(sp)
    800033fe:	e4a6                	sd	s1,72(sp)
    80003400:	e0ca                	sd	s2,64(sp)
    80003402:	fc4e                	sd	s3,56(sp)
    80003404:	f852                	sd	s4,48(sp)
    80003406:	f456                	sd	s5,40(sp)
    80003408:	f05a                	sd	s6,32(sp)
    8000340a:	ec5e                	sd	s7,24(sp)
    8000340c:	e862                	sd	s8,16(sp)
    8000340e:	e466                	sd	s9,8(sp)
    80003410:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003412:	0001d797          	auipc	a5,0x1d
    80003416:	99a7a783          	lw	a5,-1638(a5) # 8001fdac <sb+0x4>
    8000341a:	cbd1                	beqz	a5,800034ae <balloc+0xb6>
    8000341c:	8baa                	mv	s7,a0
    8000341e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003420:	0001db17          	auipc	s6,0x1d
    80003424:	988b0b13          	addi	s6,s6,-1656 # 8001fda8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003428:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000342a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000342c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000342e:	6c89                	lui	s9,0x2
    80003430:	a831                	j	8000344c <balloc+0x54>
    brelse(bp);
    80003432:	854a                	mv	a0,s2
    80003434:	00000097          	auipc	ra,0x0
    80003438:	e32080e7          	jalr	-462(ra) # 80003266 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000343c:	015c87bb          	addw	a5,s9,s5
    80003440:	00078a9b          	sext.w	s5,a5
    80003444:	004b2703          	lw	a4,4(s6)
    80003448:	06eaf363          	bgeu	s5,a4,800034ae <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000344c:	41fad79b          	sraiw	a5,s5,0x1f
    80003450:	0137d79b          	srliw	a5,a5,0x13
    80003454:	015787bb          	addw	a5,a5,s5
    80003458:	40d7d79b          	sraiw	a5,a5,0xd
    8000345c:	01cb2583          	lw	a1,28(s6)
    80003460:	9dbd                	addw	a1,a1,a5
    80003462:	855e                	mv	a0,s7
    80003464:	00000097          	auipc	ra,0x0
    80003468:	cd2080e7          	jalr	-814(ra) # 80003136 <bread>
    8000346c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000346e:	004b2503          	lw	a0,4(s6)
    80003472:	000a849b          	sext.w	s1,s5
    80003476:	8662                	mv	a2,s8
    80003478:	faa4fde3          	bgeu	s1,a0,80003432 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000347c:	41f6579b          	sraiw	a5,a2,0x1f
    80003480:	01d7d69b          	srliw	a3,a5,0x1d
    80003484:	00c6873b          	addw	a4,a3,a2
    80003488:	00777793          	andi	a5,a4,7
    8000348c:	9f95                	subw	a5,a5,a3
    8000348e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003492:	4037571b          	sraiw	a4,a4,0x3
    80003496:	00e906b3          	add	a3,s2,a4
    8000349a:	0586c683          	lbu	a3,88(a3)
    8000349e:	00d7f5b3          	and	a1,a5,a3
    800034a2:	cd91                	beqz	a1,800034be <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a4:	2605                	addiw	a2,a2,1
    800034a6:	2485                	addiw	s1,s1,1
    800034a8:	fd4618e3          	bne	a2,s4,80003478 <balloc+0x80>
    800034ac:	b759                	j	80003432 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034ae:	00005517          	auipc	a0,0x5
    800034b2:	22a50513          	addi	a0,a0,554 # 800086d8 <syscall_names+0x110>
    800034b6:	ffffd097          	auipc	ra,0xffffd
    800034ba:	088080e7          	jalr	136(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034be:	974a                	add	a4,a4,s2
    800034c0:	8fd5                	or	a5,a5,a3
    800034c2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034c6:	854a                	mv	a0,s2
    800034c8:	00001097          	auipc	ra,0x1
    800034cc:	01a080e7          	jalr	26(ra) # 800044e2 <log_write>
        brelse(bp);
    800034d0:	854a                	mv	a0,s2
    800034d2:	00000097          	auipc	ra,0x0
    800034d6:	d94080e7          	jalr	-620(ra) # 80003266 <brelse>
  bp = bread(dev, bno);
    800034da:	85a6                	mv	a1,s1
    800034dc:	855e                	mv	a0,s7
    800034de:	00000097          	auipc	ra,0x0
    800034e2:	c58080e7          	jalr	-936(ra) # 80003136 <bread>
    800034e6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034e8:	40000613          	li	a2,1024
    800034ec:	4581                	li	a1,0
    800034ee:	05850513          	addi	a0,a0,88
    800034f2:	ffffd097          	auipc	ra,0xffffd
    800034f6:	7ee080e7          	jalr	2030(ra) # 80000ce0 <memset>
  log_write(bp);
    800034fa:	854a                	mv	a0,s2
    800034fc:	00001097          	auipc	ra,0x1
    80003500:	fe6080e7          	jalr	-26(ra) # 800044e2 <log_write>
  brelse(bp);
    80003504:	854a                	mv	a0,s2
    80003506:	00000097          	auipc	ra,0x0
    8000350a:	d60080e7          	jalr	-672(ra) # 80003266 <brelse>
}
    8000350e:	8526                	mv	a0,s1
    80003510:	60e6                	ld	ra,88(sp)
    80003512:	6446                	ld	s0,80(sp)
    80003514:	64a6                	ld	s1,72(sp)
    80003516:	6906                	ld	s2,64(sp)
    80003518:	79e2                	ld	s3,56(sp)
    8000351a:	7a42                	ld	s4,48(sp)
    8000351c:	7aa2                	ld	s5,40(sp)
    8000351e:	7b02                	ld	s6,32(sp)
    80003520:	6be2                	ld	s7,24(sp)
    80003522:	6c42                	ld	s8,16(sp)
    80003524:	6ca2                	ld	s9,8(sp)
    80003526:	6125                	addi	sp,sp,96
    80003528:	8082                	ret

000000008000352a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000352a:	7179                	addi	sp,sp,-48
    8000352c:	f406                	sd	ra,40(sp)
    8000352e:	f022                	sd	s0,32(sp)
    80003530:	ec26                	sd	s1,24(sp)
    80003532:	e84a                	sd	s2,16(sp)
    80003534:	e44e                	sd	s3,8(sp)
    80003536:	e052                	sd	s4,0(sp)
    80003538:	1800                	addi	s0,sp,48
    8000353a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000353c:	47ad                	li	a5,11
    8000353e:	04b7fe63          	bgeu	a5,a1,8000359a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003542:	ff45849b          	addiw	s1,a1,-12
    80003546:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000354a:	0ff00793          	li	a5,255
    8000354e:	0ae7e363          	bltu	a5,a4,800035f4 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003552:	08052583          	lw	a1,128(a0)
    80003556:	c5ad                	beqz	a1,800035c0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003558:	00092503          	lw	a0,0(s2)
    8000355c:	00000097          	auipc	ra,0x0
    80003560:	bda080e7          	jalr	-1062(ra) # 80003136 <bread>
    80003564:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003566:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000356a:	02049593          	slli	a1,s1,0x20
    8000356e:	9181                	srli	a1,a1,0x20
    80003570:	058a                	slli	a1,a1,0x2
    80003572:	00b784b3          	add	s1,a5,a1
    80003576:	0004a983          	lw	s3,0(s1)
    8000357a:	04098d63          	beqz	s3,800035d4 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000357e:	8552                	mv	a0,s4
    80003580:	00000097          	auipc	ra,0x0
    80003584:	ce6080e7          	jalr	-794(ra) # 80003266 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003588:	854e                	mv	a0,s3
    8000358a:	70a2                	ld	ra,40(sp)
    8000358c:	7402                	ld	s0,32(sp)
    8000358e:	64e2                	ld	s1,24(sp)
    80003590:	6942                	ld	s2,16(sp)
    80003592:	69a2                	ld	s3,8(sp)
    80003594:	6a02                	ld	s4,0(sp)
    80003596:	6145                	addi	sp,sp,48
    80003598:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000359a:	02059493          	slli	s1,a1,0x20
    8000359e:	9081                	srli	s1,s1,0x20
    800035a0:	048a                	slli	s1,s1,0x2
    800035a2:	94aa                	add	s1,s1,a0
    800035a4:	0504a983          	lw	s3,80(s1)
    800035a8:	fe0990e3          	bnez	s3,80003588 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035ac:	4108                	lw	a0,0(a0)
    800035ae:	00000097          	auipc	ra,0x0
    800035b2:	e4a080e7          	jalr	-438(ra) # 800033f8 <balloc>
    800035b6:	0005099b          	sext.w	s3,a0
    800035ba:	0534a823          	sw	s3,80(s1)
    800035be:	b7e9                	j	80003588 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035c0:	4108                	lw	a0,0(a0)
    800035c2:	00000097          	auipc	ra,0x0
    800035c6:	e36080e7          	jalr	-458(ra) # 800033f8 <balloc>
    800035ca:	0005059b          	sext.w	a1,a0
    800035ce:	08b92023          	sw	a1,128(s2)
    800035d2:	b759                	j	80003558 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035d4:	00092503          	lw	a0,0(s2)
    800035d8:	00000097          	auipc	ra,0x0
    800035dc:	e20080e7          	jalr	-480(ra) # 800033f8 <balloc>
    800035e0:	0005099b          	sext.w	s3,a0
    800035e4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800035e8:	8552                	mv	a0,s4
    800035ea:	00001097          	auipc	ra,0x1
    800035ee:	ef8080e7          	jalr	-264(ra) # 800044e2 <log_write>
    800035f2:	b771                	j	8000357e <bmap+0x54>
  panic("bmap: out of range");
    800035f4:	00005517          	auipc	a0,0x5
    800035f8:	0fc50513          	addi	a0,a0,252 # 800086f0 <syscall_names+0x128>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	f42080e7          	jalr	-190(ra) # 8000053e <panic>

0000000080003604 <iget>:
{
    80003604:	7179                	addi	sp,sp,-48
    80003606:	f406                	sd	ra,40(sp)
    80003608:	f022                	sd	s0,32(sp)
    8000360a:	ec26                	sd	s1,24(sp)
    8000360c:	e84a                	sd	s2,16(sp)
    8000360e:	e44e                	sd	s3,8(sp)
    80003610:	e052                	sd	s4,0(sp)
    80003612:	1800                	addi	s0,sp,48
    80003614:	89aa                	mv	s3,a0
    80003616:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003618:	0001c517          	auipc	a0,0x1c
    8000361c:	7b050513          	addi	a0,a0,1968 # 8001fdc8 <itable>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	5c4080e7          	jalr	1476(ra) # 80000be4 <acquire>
  empty = 0;
    80003628:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000362a:	0001c497          	auipc	s1,0x1c
    8000362e:	7b648493          	addi	s1,s1,1974 # 8001fde0 <itable+0x18>
    80003632:	0001e697          	auipc	a3,0x1e
    80003636:	23e68693          	addi	a3,a3,574 # 80021870 <log>
    8000363a:	a039                	j	80003648 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000363c:	02090b63          	beqz	s2,80003672 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003640:	08848493          	addi	s1,s1,136
    80003644:	02d48a63          	beq	s1,a3,80003678 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003648:	449c                	lw	a5,8(s1)
    8000364a:	fef059e3          	blez	a5,8000363c <iget+0x38>
    8000364e:	4098                	lw	a4,0(s1)
    80003650:	ff3716e3          	bne	a4,s3,8000363c <iget+0x38>
    80003654:	40d8                	lw	a4,4(s1)
    80003656:	ff4713e3          	bne	a4,s4,8000363c <iget+0x38>
      ip->ref++;
    8000365a:	2785                	addiw	a5,a5,1
    8000365c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000365e:	0001c517          	auipc	a0,0x1c
    80003662:	76a50513          	addi	a0,a0,1898 # 8001fdc8 <itable>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	632080e7          	jalr	1586(ra) # 80000c98 <release>
      return ip;
    8000366e:	8926                	mv	s2,s1
    80003670:	a03d                	j	8000369e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003672:	f7f9                	bnez	a5,80003640 <iget+0x3c>
    80003674:	8926                	mv	s2,s1
    80003676:	b7e9                	j	80003640 <iget+0x3c>
  if(empty == 0)
    80003678:	02090c63          	beqz	s2,800036b0 <iget+0xac>
  ip->dev = dev;
    8000367c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003680:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003684:	4785                	li	a5,1
    80003686:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000368a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000368e:	0001c517          	auipc	a0,0x1c
    80003692:	73a50513          	addi	a0,a0,1850 # 8001fdc8 <itable>
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	602080e7          	jalr	1538(ra) # 80000c98 <release>
}
    8000369e:	854a                	mv	a0,s2
    800036a0:	70a2                	ld	ra,40(sp)
    800036a2:	7402                	ld	s0,32(sp)
    800036a4:	64e2                	ld	s1,24(sp)
    800036a6:	6942                	ld	s2,16(sp)
    800036a8:	69a2                	ld	s3,8(sp)
    800036aa:	6a02                	ld	s4,0(sp)
    800036ac:	6145                	addi	sp,sp,48
    800036ae:	8082                	ret
    panic("iget: no inodes");
    800036b0:	00005517          	auipc	a0,0x5
    800036b4:	05850513          	addi	a0,a0,88 # 80008708 <syscall_names+0x140>
    800036b8:	ffffd097          	auipc	ra,0xffffd
    800036bc:	e86080e7          	jalr	-378(ra) # 8000053e <panic>

00000000800036c0 <fsinit>:
fsinit(int dev) {
    800036c0:	7179                	addi	sp,sp,-48
    800036c2:	f406                	sd	ra,40(sp)
    800036c4:	f022                	sd	s0,32(sp)
    800036c6:	ec26                	sd	s1,24(sp)
    800036c8:	e84a                	sd	s2,16(sp)
    800036ca:	e44e                	sd	s3,8(sp)
    800036cc:	1800                	addi	s0,sp,48
    800036ce:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036d0:	4585                	li	a1,1
    800036d2:	00000097          	auipc	ra,0x0
    800036d6:	a64080e7          	jalr	-1436(ra) # 80003136 <bread>
    800036da:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036dc:	0001c997          	auipc	s3,0x1c
    800036e0:	6cc98993          	addi	s3,s3,1740 # 8001fda8 <sb>
    800036e4:	02000613          	li	a2,32
    800036e8:	05850593          	addi	a1,a0,88
    800036ec:	854e                	mv	a0,s3
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	652080e7          	jalr	1618(ra) # 80000d40 <memmove>
  brelse(bp);
    800036f6:	8526                	mv	a0,s1
    800036f8:	00000097          	auipc	ra,0x0
    800036fc:	b6e080e7          	jalr	-1170(ra) # 80003266 <brelse>
  if(sb.magic != FSMAGIC)
    80003700:	0009a703          	lw	a4,0(s3)
    80003704:	102037b7          	lui	a5,0x10203
    80003708:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000370c:	02f71263          	bne	a4,a5,80003730 <fsinit+0x70>
  initlog(dev, &sb);
    80003710:	0001c597          	auipc	a1,0x1c
    80003714:	69858593          	addi	a1,a1,1688 # 8001fda8 <sb>
    80003718:	854a                	mv	a0,s2
    8000371a:	00001097          	auipc	ra,0x1
    8000371e:	b4c080e7          	jalr	-1204(ra) # 80004266 <initlog>
}
    80003722:	70a2                	ld	ra,40(sp)
    80003724:	7402                	ld	s0,32(sp)
    80003726:	64e2                	ld	s1,24(sp)
    80003728:	6942                	ld	s2,16(sp)
    8000372a:	69a2                	ld	s3,8(sp)
    8000372c:	6145                	addi	sp,sp,48
    8000372e:	8082                	ret
    panic("invalid file system");
    80003730:	00005517          	auipc	a0,0x5
    80003734:	fe850513          	addi	a0,a0,-24 # 80008718 <syscall_names+0x150>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	e06080e7          	jalr	-506(ra) # 8000053e <panic>

0000000080003740 <iinit>:
{
    80003740:	7179                	addi	sp,sp,-48
    80003742:	f406                	sd	ra,40(sp)
    80003744:	f022                	sd	s0,32(sp)
    80003746:	ec26                	sd	s1,24(sp)
    80003748:	e84a                	sd	s2,16(sp)
    8000374a:	e44e                	sd	s3,8(sp)
    8000374c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000374e:	00005597          	auipc	a1,0x5
    80003752:	fe258593          	addi	a1,a1,-30 # 80008730 <syscall_names+0x168>
    80003756:	0001c517          	auipc	a0,0x1c
    8000375a:	67250513          	addi	a0,a0,1650 # 8001fdc8 <itable>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	3f6080e7          	jalr	1014(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003766:	0001c497          	auipc	s1,0x1c
    8000376a:	68a48493          	addi	s1,s1,1674 # 8001fdf0 <itable+0x28>
    8000376e:	0001e997          	auipc	s3,0x1e
    80003772:	11298993          	addi	s3,s3,274 # 80021880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003776:	00005917          	auipc	s2,0x5
    8000377a:	fc290913          	addi	s2,s2,-62 # 80008738 <syscall_names+0x170>
    8000377e:	85ca                	mv	a1,s2
    80003780:	8526                	mv	a0,s1
    80003782:	00001097          	auipc	ra,0x1
    80003786:	e46080e7          	jalr	-442(ra) # 800045c8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000378a:	08848493          	addi	s1,s1,136
    8000378e:	ff3498e3          	bne	s1,s3,8000377e <iinit+0x3e>
}
    80003792:	70a2                	ld	ra,40(sp)
    80003794:	7402                	ld	s0,32(sp)
    80003796:	64e2                	ld	s1,24(sp)
    80003798:	6942                	ld	s2,16(sp)
    8000379a:	69a2                	ld	s3,8(sp)
    8000379c:	6145                	addi	sp,sp,48
    8000379e:	8082                	ret

00000000800037a0 <ialloc>:
{
    800037a0:	715d                	addi	sp,sp,-80
    800037a2:	e486                	sd	ra,72(sp)
    800037a4:	e0a2                	sd	s0,64(sp)
    800037a6:	fc26                	sd	s1,56(sp)
    800037a8:	f84a                	sd	s2,48(sp)
    800037aa:	f44e                	sd	s3,40(sp)
    800037ac:	f052                	sd	s4,32(sp)
    800037ae:	ec56                	sd	s5,24(sp)
    800037b0:	e85a                	sd	s6,16(sp)
    800037b2:	e45e                	sd	s7,8(sp)
    800037b4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037b6:	0001c717          	auipc	a4,0x1c
    800037ba:	5fe72703          	lw	a4,1534(a4) # 8001fdb4 <sb+0xc>
    800037be:	4785                	li	a5,1
    800037c0:	04e7fa63          	bgeu	a5,a4,80003814 <ialloc+0x74>
    800037c4:	8aaa                	mv	s5,a0
    800037c6:	8bae                	mv	s7,a1
    800037c8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037ca:	0001ca17          	auipc	s4,0x1c
    800037ce:	5dea0a13          	addi	s4,s4,1502 # 8001fda8 <sb>
    800037d2:	00048b1b          	sext.w	s6,s1
    800037d6:	0044d593          	srli	a1,s1,0x4
    800037da:	018a2783          	lw	a5,24(s4)
    800037de:	9dbd                	addw	a1,a1,a5
    800037e0:	8556                	mv	a0,s5
    800037e2:	00000097          	auipc	ra,0x0
    800037e6:	954080e7          	jalr	-1708(ra) # 80003136 <bread>
    800037ea:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037ec:	05850993          	addi	s3,a0,88
    800037f0:	00f4f793          	andi	a5,s1,15
    800037f4:	079a                	slli	a5,a5,0x6
    800037f6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037f8:	00099783          	lh	a5,0(s3)
    800037fc:	c785                	beqz	a5,80003824 <ialloc+0x84>
    brelse(bp);
    800037fe:	00000097          	auipc	ra,0x0
    80003802:	a68080e7          	jalr	-1432(ra) # 80003266 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003806:	0485                	addi	s1,s1,1
    80003808:	00ca2703          	lw	a4,12(s4)
    8000380c:	0004879b          	sext.w	a5,s1
    80003810:	fce7e1e3          	bltu	a5,a4,800037d2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003814:	00005517          	auipc	a0,0x5
    80003818:	f2c50513          	addi	a0,a0,-212 # 80008740 <syscall_names+0x178>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	d22080e7          	jalr	-734(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003824:	04000613          	li	a2,64
    80003828:	4581                	li	a1,0
    8000382a:	854e                	mv	a0,s3
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	4b4080e7          	jalr	1204(ra) # 80000ce0 <memset>
      dip->type = type;
    80003834:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003838:	854a                	mv	a0,s2
    8000383a:	00001097          	auipc	ra,0x1
    8000383e:	ca8080e7          	jalr	-856(ra) # 800044e2 <log_write>
      brelse(bp);
    80003842:	854a                	mv	a0,s2
    80003844:	00000097          	auipc	ra,0x0
    80003848:	a22080e7          	jalr	-1502(ra) # 80003266 <brelse>
      return iget(dev, inum);
    8000384c:	85da                	mv	a1,s6
    8000384e:	8556                	mv	a0,s5
    80003850:	00000097          	auipc	ra,0x0
    80003854:	db4080e7          	jalr	-588(ra) # 80003604 <iget>
}
    80003858:	60a6                	ld	ra,72(sp)
    8000385a:	6406                	ld	s0,64(sp)
    8000385c:	74e2                	ld	s1,56(sp)
    8000385e:	7942                	ld	s2,48(sp)
    80003860:	79a2                	ld	s3,40(sp)
    80003862:	7a02                	ld	s4,32(sp)
    80003864:	6ae2                	ld	s5,24(sp)
    80003866:	6b42                	ld	s6,16(sp)
    80003868:	6ba2                	ld	s7,8(sp)
    8000386a:	6161                	addi	sp,sp,80
    8000386c:	8082                	ret

000000008000386e <iupdate>:
{
    8000386e:	1101                	addi	sp,sp,-32
    80003870:	ec06                	sd	ra,24(sp)
    80003872:	e822                	sd	s0,16(sp)
    80003874:	e426                	sd	s1,8(sp)
    80003876:	e04a                	sd	s2,0(sp)
    80003878:	1000                	addi	s0,sp,32
    8000387a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000387c:	415c                	lw	a5,4(a0)
    8000387e:	0047d79b          	srliw	a5,a5,0x4
    80003882:	0001c597          	auipc	a1,0x1c
    80003886:	53e5a583          	lw	a1,1342(a1) # 8001fdc0 <sb+0x18>
    8000388a:	9dbd                	addw	a1,a1,a5
    8000388c:	4108                	lw	a0,0(a0)
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	8a8080e7          	jalr	-1880(ra) # 80003136 <bread>
    80003896:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003898:	05850793          	addi	a5,a0,88
    8000389c:	40c8                	lw	a0,4(s1)
    8000389e:	893d                	andi	a0,a0,15
    800038a0:	051a                	slli	a0,a0,0x6
    800038a2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038a4:	04449703          	lh	a4,68(s1)
    800038a8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038ac:	04649703          	lh	a4,70(s1)
    800038b0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038b4:	04849703          	lh	a4,72(s1)
    800038b8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038bc:	04a49703          	lh	a4,74(s1)
    800038c0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038c4:	44f8                	lw	a4,76(s1)
    800038c6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038c8:	03400613          	li	a2,52
    800038cc:	05048593          	addi	a1,s1,80
    800038d0:	0531                	addi	a0,a0,12
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	46e080e7          	jalr	1134(ra) # 80000d40 <memmove>
  log_write(bp);
    800038da:	854a                	mv	a0,s2
    800038dc:	00001097          	auipc	ra,0x1
    800038e0:	c06080e7          	jalr	-1018(ra) # 800044e2 <log_write>
  brelse(bp);
    800038e4:	854a                	mv	a0,s2
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	980080e7          	jalr	-1664(ra) # 80003266 <brelse>
}
    800038ee:	60e2                	ld	ra,24(sp)
    800038f0:	6442                	ld	s0,16(sp)
    800038f2:	64a2                	ld	s1,8(sp)
    800038f4:	6902                	ld	s2,0(sp)
    800038f6:	6105                	addi	sp,sp,32
    800038f8:	8082                	ret

00000000800038fa <idup>:
{
    800038fa:	1101                	addi	sp,sp,-32
    800038fc:	ec06                	sd	ra,24(sp)
    800038fe:	e822                	sd	s0,16(sp)
    80003900:	e426                	sd	s1,8(sp)
    80003902:	1000                	addi	s0,sp,32
    80003904:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003906:	0001c517          	auipc	a0,0x1c
    8000390a:	4c250513          	addi	a0,a0,1218 # 8001fdc8 <itable>
    8000390e:	ffffd097          	auipc	ra,0xffffd
    80003912:	2d6080e7          	jalr	726(ra) # 80000be4 <acquire>
  ip->ref++;
    80003916:	449c                	lw	a5,8(s1)
    80003918:	2785                	addiw	a5,a5,1
    8000391a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000391c:	0001c517          	auipc	a0,0x1c
    80003920:	4ac50513          	addi	a0,a0,1196 # 8001fdc8 <itable>
    80003924:	ffffd097          	auipc	ra,0xffffd
    80003928:	374080e7          	jalr	884(ra) # 80000c98 <release>
}
    8000392c:	8526                	mv	a0,s1
    8000392e:	60e2                	ld	ra,24(sp)
    80003930:	6442                	ld	s0,16(sp)
    80003932:	64a2                	ld	s1,8(sp)
    80003934:	6105                	addi	sp,sp,32
    80003936:	8082                	ret

0000000080003938 <ilock>:
{
    80003938:	1101                	addi	sp,sp,-32
    8000393a:	ec06                	sd	ra,24(sp)
    8000393c:	e822                	sd	s0,16(sp)
    8000393e:	e426                	sd	s1,8(sp)
    80003940:	e04a                	sd	s2,0(sp)
    80003942:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003944:	c115                	beqz	a0,80003968 <ilock+0x30>
    80003946:	84aa                	mv	s1,a0
    80003948:	451c                	lw	a5,8(a0)
    8000394a:	00f05f63          	blez	a5,80003968 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000394e:	0541                	addi	a0,a0,16
    80003950:	00001097          	auipc	ra,0x1
    80003954:	cb2080e7          	jalr	-846(ra) # 80004602 <acquiresleep>
  if(ip->valid == 0){
    80003958:	40bc                	lw	a5,64(s1)
    8000395a:	cf99                	beqz	a5,80003978 <ilock+0x40>
}
    8000395c:	60e2                	ld	ra,24(sp)
    8000395e:	6442                	ld	s0,16(sp)
    80003960:	64a2                	ld	s1,8(sp)
    80003962:	6902                	ld	s2,0(sp)
    80003964:	6105                	addi	sp,sp,32
    80003966:	8082                	ret
    panic("ilock");
    80003968:	00005517          	auipc	a0,0x5
    8000396c:	df050513          	addi	a0,a0,-528 # 80008758 <syscall_names+0x190>
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	bce080e7          	jalr	-1074(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003978:	40dc                	lw	a5,4(s1)
    8000397a:	0047d79b          	srliw	a5,a5,0x4
    8000397e:	0001c597          	auipc	a1,0x1c
    80003982:	4425a583          	lw	a1,1090(a1) # 8001fdc0 <sb+0x18>
    80003986:	9dbd                	addw	a1,a1,a5
    80003988:	4088                	lw	a0,0(s1)
    8000398a:	fffff097          	auipc	ra,0xfffff
    8000398e:	7ac080e7          	jalr	1964(ra) # 80003136 <bread>
    80003992:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003994:	05850593          	addi	a1,a0,88
    80003998:	40dc                	lw	a5,4(s1)
    8000399a:	8bbd                	andi	a5,a5,15
    8000399c:	079a                	slli	a5,a5,0x6
    8000399e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039a0:	00059783          	lh	a5,0(a1)
    800039a4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039a8:	00259783          	lh	a5,2(a1)
    800039ac:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039b0:	00459783          	lh	a5,4(a1)
    800039b4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039b8:	00659783          	lh	a5,6(a1)
    800039bc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039c0:	459c                	lw	a5,8(a1)
    800039c2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039c4:	03400613          	li	a2,52
    800039c8:	05b1                	addi	a1,a1,12
    800039ca:	05048513          	addi	a0,s1,80
    800039ce:	ffffd097          	auipc	ra,0xffffd
    800039d2:	372080e7          	jalr	882(ra) # 80000d40 <memmove>
    brelse(bp);
    800039d6:	854a                	mv	a0,s2
    800039d8:	00000097          	auipc	ra,0x0
    800039dc:	88e080e7          	jalr	-1906(ra) # 80003266 <brelse>
    ip->valid = 1;
    800039e0:	4785                	li	a5,1
    800039e2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039e4:	04449783          	lh	a5,68(s1)
    800039e8:	fbb5                	bnez	a5,8000395c <ilock+0x24>
      panic("ilock: no type");
    800039ea:	00005517          	auipc	a0,0x5
    800039ee:	d7650513          	addi	a0,a0,-650 # 80008760 <syscall_names+0x198>
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	b4c080e7          	jalr	-1204(ra) # 8000053e <panic>

00000000800039fa <iunlock>:
{
    800039fa:	1101                	addi	sp,sp,-32
    800039fc:	ec06                	sd	ra,24(sp)
    800039fe:	e822                	sd	s0,16(sp)
    80003a00:	e426                	sd	s1,8(sp)
    80003a02:	e04a                	sd	s2,0(sp)
    80003a04:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a06:	c905                	beqz	a0,80003a36 <iunlock+0x3c>
    80003a08:	84aa                	mv	s1,a0
    80003a0a:	01050913          	addi	s2,a0,16
    80003a0e:	854a                	mv	a0,s2
    80003a10:	00001097          	auipc	ra,0x1
    80003a14:	c8c080e7          	jalr	-884(ra) # 8000469c <holdingsleep>
    80003a18:	cd19                	beqz	a0,80003a36 <iunlock+0x3c>
    80003a1a:	449c                	lw	a5,8(s1)
    80003a1c:	00f05d63          	blez	a5,80003a36 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a20:	854a                	mv	a0,s2
    80003a22:	00001097          	auipc	ra,0x1
    80003a26:	c36080e7          	jalr	-970(ra) # 80004658 <releasesleep>
}
    80003a2a:	60e2                	ld	ra,24(sp)
    80003a2c:	6442                	ld	s0,16(sp)
    80003a2e:	64a2                	ld	s1,8(sp)
    80003a30:	6902                	ld	s2,0(sp)
    80003a32:	6105                	addi	sp,sp,32
    80003a34:	8082                	ret
    panic("iunlock");
    80003a36:	00005517          	auipc	a0,0x5
    80003a3a:	d3a50513          	addi	a0,a0,-710 # 80008770 <syscall_names+0x1a8>
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	b00080e7          	jalr	-1280(ra) # 8000053e <panic>

0000000080003a46 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a46:	7179                	addi	sp,sp,-48
    80003a48:	f406                	sd	ra,40(sp)
    80003a4a:	f022                	sd	s0,32(sp)
    80003a4c:	ec26                	sd	s1,24(sp)
    80003a4e:	e84a                	sd	s2,16(sp)
    80003a50:	e44e                	sd	s3,8(sp)
    80003a52:	e052                	sd	s4,0(sp)
    80003a54:	1800                	addi	s0,sp,48
    80003a56:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a58:	05050493          	addi	s1,a0,80
    80003a5c:	08050913          	addi	s2,a0,128
    80003a60:	a021                	j	80003a68 <itrunc+0x22>
    80003a62:	0491                	addi	s1,s1,4
    80003a64:	01248d63          	beq	s1,s2,80003a7e <itrunc+0x38>
    if(ip->addrs[i]){
    80003a68:	408c                	lw	a1,0(s1)
    80003a6a:	dde5                	beqz	a1,80003a62 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a6c:	0009a503          	lw	a0,0(s3)
    80003a70:	00000097          	auipc	ra,0x0
    80003a74:	90c080e7          	jalr	-1780(ra) # 8000337c <bfree>
      ip->addrs[i] = 0;
    80003a78:	0004a023          	sw	zero,0(s1)
    80003a7c:	b7dd                	j	80003a62 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a7e:	0809a583          	lw	a1,128(s3)
    80003a82:	e185                	bnez	a1,80003aa2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a84:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a88:	854e                	mv	a0,s3
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	de4080e7          	jalr	-540(ra) # 8000386e <iupdate>
}
    80003a92:	70a2                	ld	ra,40(sp)
    80003a94:	7402                	ld	s0,32(sp)
    80003a96:	64e2                	ld	s1,24(sp)
    80003a98:	6942                	ld	s2,16(sp)
    80003a9a:	69a2                	ld	s3,8(sp)
    80003a9c:	6a02                	ld	s4,0(sp)
    80003a9e:	6145                	addi	sp,sp,48
    80003aa0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003aa2:	0009a503          	lw	a0,0(s3)
    80003aa6:	fffff097          	auipc	ra,0xfffff
    80003aaa:	690080e7          	jalr	1680(ra) # 80003136 <bread>
    80003aae:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ab0:	05850493          	addi	s1,a0,88
    80003ab4:	45850913          	addi	s2,a0,1112
    80003ab8:	a811                	j	80003acc <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003aba:	0009a503          	lw	a0,0(s3)
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	8be080e7          	jalr	-1858(ra) # 8000337c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ac6:	0491                	addi	s1,s1,4
    80003ac8:	01248563          	beq	s1,s2,80003ad2 <itrunc+0x8c>
      if(a[j])
    80003acc:	408c                	lw	a1,0(s1)
    80003ace:	dde5                	beqz	a1,80003ac6 <itrunc+0x80>
    80003ad0:	b7ed                	j	80003aba <itrunc+0x74>
    brelse(bp);
    80003ad2:	8552                	mv	a0,s4
    80003ad4:	fffff097          	auipc	ra,0xfffff
    80003ad8:	792080e7          	jalr	1938(ra) # 80003266 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003adc:	0809a583          	lw	a1,128(s3)
    80003ae0:	0009a503          	lw	a0,0(s3)
    80003ae4:	00000097          	auipc	ra,0x0
    80003ae8:	898080e7          	jalr	-1896(ra) # 8000337c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003aec:	0809a023          	sw	zero,128(s3)
    80003af0:	bf51                	j	80003a84 <itrunc+0x3e>

0000000080003af2 <iput>:
{
    80003af2:	1101                	addi	sp,sp,-32
    80003af4:	ec06                	sd	ra,24(sp)
    80003af6:	e822                	sd	s0,16(sp)
    80003af8:	e426                	sd	s1,8(sp)
    80003afa:	e04a                	sd	s2,0(sp)
    80003afc:	1000                	addi	s0,sp,32
    80003afe:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b00:	0001c517          	auipc	a0,0x1c
    80003b04:	2c850513          	addi	a0,a0,712 # 8001fdc8 <itable>
    80003b08:	ffffd097          	auipc	ra,0xffffd
    80003b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b10:	4498                	lw	a4,8(s1)
    80003b12:	4785                	li	a5,1
    80003b14:	02f70363          	beq	a4,a5,80003b3a <iput+0x48>
  ip->ref--;
    80003b18:	449c                	lw	a5,8(s1)
    80003b1a:	37fd                	addiw	a5,a5,-1
    80003b1c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b1e:	0001c517          	auipc	a0,0x1c
    80003b22:	2aa50513          	addi	a0,a0,682 # 8001fdc8 <itable>
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	172080e7          	jalr	370(ra) # 80000c98 <release>
}
    80003b2e:	60e2                	ld	ra,24(sp)
    80003b30:	6442                	ld	s0,16(sp)
    80003b32:	64a2                	ld	s1,8(sp)
    80003b34:	6902                	ld	s2,0(sp)
    80003b36:	6105                	addi	sp,sp,32
    80003b38:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b3a:	40bc                	lw	a5,64(s1)
    80003b3c:	dff1                	beqz	a5,80003b18 <iput+0x26>
    80003b3e:	04a49783          	lh	a5,74(s1)
    80003b42:	fbf9                	bnez	a5,80003b18 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b44:	01048913          	addi	s2,s1,16
    80003b48:	854a                	mv	a0,s2
    80003b4a:	00001097          	auipc	ra,0x1
    80003b4e:	ab8080e7          	jalr	-1352(ra) # 80004602 <acquiresleep>
    release(&itable.lock);
    80003b52:	0001c517          	auipc	a0,0x1c
    80003b56:	27650513          	addi	a0,a0,630 # 8001fdc8 <itable>
    80003b5a:	ffffd097          	auipc	ra,0xffffd
    80003b5e:	13e080e7          	jalr	318(ra) # 80000c98 <release>
    itrunc(ip);
    80003b62:	8526                	mv	a0,s1
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	ee2080e7          	jalr	-286(ra) # 80003a46 <itrunc>
    ip->type = 0;
    80003b6c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b70:	8526                	mv	a0,s1
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	cfc080e7          	jalr	-772(ra) # 8000386e <iupdate>
    ip->valid = 0;
    80003b7a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b7e:	854a                	mv	a0,s2
    80003b80:	00001097          	auipc	ra,0x1
    80003b84:	ad8080e7          	jalr	-1320(ra) # 80004658 <releasesleep>
    acquire(&itable.lock);
    80003b88:	0001c517          	auipc	a0,0x1c
    80003b8c:	24050513          	addi	a0,a0,576 # 8001fdc8 <itable>
    80003b90:	ffffd097          	auipc	ra,0xffffd
    80003b94:	054080e7          	jalr	84(ra) # 80000be4 <acquire>
    80003b98:	b741                	j	80003b18 <iput+0x26>

0000000080003b9a <iunlockput>:
{
    80003b9a:	1101                	addi	sp,sp,-32
    80003b9c:	ec06                	sd	ra,24(sp)
    80003b9e:	e822                	sd	s0,16(sp)
    80003ba0:	e426                	sd	s1,8(sp)
    80003ba2:	1000                	addi	s0,sp,32
    80003ba4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	e54080e7          	jalr	-428(ra) # 800039fa <iunlock>
  iput(ip);
    80003bae:	8526                	mv	a0,s1
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	f42080e7          	jalr	-190(ra) # 80003af2 <iput>
}
    80003bb8:	60e2                	ld	ra,24(sp)
    80003bba:	6442                	ld	s0,16(sp)
    80003bbc:	64a2                	ld	s1,8(sp)
    80003bbe:	6105                	addi	sp,sp,32
    80003bc0:	8082                	ret

0000000080003bc2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bc2:	1141                	addi	sp,sp,-16
    80003bc4:	e422                	sd	s0,8(sp)
    80003bc6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bc8:	411c                	lw	a5,0(a0)
    80003bca:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bcc:	415c                	lw	a5,4(a0)
    80003bce:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bd0:	04451783          	lh	a5,68(a0)
    80003bd4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bd8:	04a51783          	lh	a5,74(a0)
    80003bdc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003be0:	04c56783          	lwu	a5,76(a0)
    80003be4:	e99c                	sd	a5,16(a1)
}
    80003be6:	6422                	ld	s0,8(sp)
    80003be8:	0141                	addi	sp,sp,16
    80003bea:	8082                	ret

0000000080003bec <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bec:	457c                	lw	a5,76(a0)
    80003bee:	0ed7e963          	bltu	a5,a3,80003ce0 <readi+0xf4>
{
    80003bf2:	7159                	addi	sp,sp,-112
    80003bf4:	f486                	sd	ra,104(sp)
    80003bf6:	f0a2                	sd	s0,96(sp)
    80003bf8:	eca6                	sd	s1,88(sp)
    80003bfa:	e8ca                	sd	s2,80(sp)
    80003bfc:	e4ce                	sd	s3,72(sp)
    80003bfe:	e0d2                	sd	s4,64(sp)
    80003c00:	fc56                	sd	s5,56(sp)
    80003c02:	f85a                	sd	s6,48(sp)
    80003c04:	f45e                	sd	s7,40(sp)
    80003c06:	f062                	sd	s8,32(sp)
    80003c08:	ec66                	sd	s9,24(sp)
    80003c0a:	e86a                	sd	s10,16(sp)
    80003c0c:	e46e                	sd	s11,8(sp)
    80003c0e:	1880                	addi	s0,sp,112
    80003c10:	8baa                	mv	s7,a0
    80003c12:	8c2e                	mv	s8,a1
    80003c14:	8ab2                	mv	s5,a2
    80003c16:	84b6                	mv	s1,a3
    80003c18:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c1a:	9f35                	addw	a4,a4,a3
    return 0;
    80003c1c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c1e:	0ad76063          	bltu	a4,a3,80003cbe <readi+0xd2>
  if(off + n > ip->size)
    80003c22:	00e7f463          	bgeu	a5,a4,80003c2a <readi+0x3e>
    n = ip->size - off;
    80003c26:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c2a:	0a0b0963          	beqz	s6,80003cdc <readi+0xf0>
    80003c2e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c30:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c34:	5cfd                	li	s9,-1
    80003c36:	a82d                	j	80003c70 <readi+0x84>
    80003c38:	020a1d93          	slli	s11,s4,0x20
    80003c3c:	020ddd93          	srli	s11,s11,0x20
    80003c40:	05890613          	addi	a2,s2,88
    80003c44:	86ee                	mv	a3,s11
    80003c46:	963a                	add	a2,a2,a4
    80003c48:	85d6                	mv	a1,s5
    80003c4a:	8562                	mv	a0,s8
    80003c4c:	fffff097          	auipc	ra,0xfffff
    80003c50:	a02080e7          	jalr	-1534(ra) # 8000264e <either_copyout>
    80003c54:	05950d63          	beq	a0,s9,80003cae <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c58:	854a                	mv	a0,s2
    80003c5a:	fffff097          	auipc	ra,0xfffff
    80003c5e:	60c080e7          	jalr	1548(ra) # 80003266 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c62:	013a09bb          	addw	s3,s4,s3
    80003c66:	009a04bb          	addw	s1,s4,s1
    80003c6a:	9aee                	add	s5,s5,s11
    80003c6c:	0569f763          	bgeu	s3,s6,80003cba <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c70:	000ba903          	lw	s2,0(s7)
    80003c74:	00a4d59b          	srliw	a1,s1,0xa
    80003c78:	855e                	mv	a0,s7
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	8b0080e7          	jalr	-1872(ra) # 8000352a <bmap>
    80003c82:	0005059b          	sext.w	a1,a0
    80003c86:	854a                	mv	a0,s2
    80003c88:	fffff097          	auipc	ra,0xfffff
    80003c8c:	4ae080e7          	jalr	1198(ra) # 80003136 <bread>
    80003c90:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c92:	3ff4f713          	andi	a4,s1,1023
    80003c96:	40ed07bb          	subw	a5,s10,a4
    80003c9a:	413b06bb          	subw	a3,s6,s3
    80003c9e:	8a3e                	mv	s4,a5
    80003ca0:	2781                	sext.w	a5,a5
    80003ca2:	0006861b          	sext.w	a2,a3
    80003ca6:	f8f679e3          	bgeu	a2,a5,80003c38 <readi+0x4c>
    80003caa:	8a36                	mv	s4,a3
    80003cac:	b771                	j	80003c38 <readi+0x4c>
      brelse(bp);
    80003cae:	854a                	mv	a0,s2
    80003cb0:	fffff097          	auipc	ra,0xfffff
    80003cb4:	5b6080e7          	jalr	1462(ra) # 80003266 <brelse>
      tot = -1;
    80003cb8:	59fd                	li	s3,-1
  }
  return tot;
    80003cba:	0009851b          	sext.w	a0,s3
}
    80003cbe:	70a6                	ld	ra,104(sp)
    80003cc0:	7406                	ld	s0,96(sp)
    80003cc2:	64e6                	ld	s1,88(sp)
    80003cc4:	6946                	ld	s2,80(sp)
    80003cc6:	69a6                	ld	s3,72(sp)
    80003cc8:	6a06                	ld	s4,64(sp)
    80003cca:	7ae2                	ld	s5,56(sp)
    80003ccc:	7b42                	ld	s6,48(sp)
    80003cce:	7ba2                	ld	s7,40(sp)
    80003cd0:	7c02                	ld	s8,32(sp)
    80003cd2:	6ce2                	ld	s9,24(sp)
    80003cd4:	6d42                	ld	s10,16(sp)
    80003cd6:	6da2                	ld	s11,8(sp)
    80003cd8:	6165                	addi	sp,sp,112
    80003cda:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cdc:	89da                	mv	s3,s6
    80003cde:	bff1                	j	80003cba <readi+0xce>
    return 0;
    80003ce0:	4501                	li	a0,0
}
    80003ce2:	8082                	ret

0000000080003ce4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ce4:	457c                	lw	a5,76(a0)
    80003ce6:	10d7e863          	bltu	a5,a3,80003df6 <writei+0x112>
{
    80003cea:	7159                	addi	sp,sp,-112
    80003cec:	f486                	sd	ra,104(sp)
    80003cee:	f0a2                	sd	s0,96(sp)
    80003cf0:	eca6                	sd	s1,88(sp)
    80003cf2:	e8ca                	sd	s2,80(sp)
    80003cf4:	e4ce                	sd	s3,72(sp)
    80003cf6:	e0d2                	sd	s4,64(sp)
    80003cf8:	fc56                	sd	s5,56(sp)
    80003cfa:	f85a                	sd	s6,48(sp)
    80003cfc:	f45e                	sd	s7,40(sp)
    80003cfe:	f062                	sd	s8,32(sp)
    80003d00:	ec66                	sd	s9,24(sp)
    80003d02:	e86a                	sd	s10,16(sp)
    80003d04:	e46e                	sd	s11,8(sp)
    80003d06:	1880                	addi	s0,sp,112
    80003d08:	8b2a                	mv	s6,a0
    80003d0a:	8c2e                	mv	s8,a1
    80003d0c:	8ab2                	mv	s5,a2
    80003d0e:	8936                	mv	s2,a3
    80003d10:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d12:	00e687bb          	addw	a5,a3,a4
    80003d16:	0ed7e263          	bltu	a5,a3,80003dfa <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d1a:	00043737          	lui	a4,0x43
    80003d1e:	0ef76063          	bltu	a4,a5,80003dfe <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d22:	0c0b8863          	beqz	s7,80003df2 <writei+0x10e>
    80003d26:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d28:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d2c:	5cfd                	li	s9,-1
    80003d2e:	a091                	j	80003d72 <writei+0x8e>
    80003d30:	02099d93          	slli	s11,s3,0x20
    80003d34:	020ddd93          	srli	s11,s11,0x20
    80003d38:	05848513          	addi	a0,s1,88
    80003d3c:	86ee                	mv	a3,s11
    80003d3e:	8656                	mv	a2,s5
    80003d40:	85e2                	mv	a1,s8
    80003d42:	953a                	add	a0,a0,a4
    80003d44:	fffff097          	auipc	ra,0xfffff
    80003d48:	960080e7          	jalr	-1696(ra) # 800026a4 <either_copyin>
    80003d4c:	07950263          	beq	a0,s9,80003db0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d50:	8526                	mv	a0,s1
    80003d52:	00000097          	auipc	ra,0x0
    80003d56:	790080e7          	jalr	1936(ra) # 800044e2 <log_write>
    brelse(bp);
    80003d5a:	8526                	mv	a0,s1
    80003d5c:	fffff097          	auipc	ra,0xfffff
    80003d60:	50a080e7          	jalr	1290(ra) # 80003266 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d64:	01498a3b          	addw	s4,s3,s4
    80003d68:	0129893b          	addw	s2,s3,s2
    80003d6c:	9aee                	add	s5,s5,s11
    80003d6e:	057a7663          	bgeu	s4,s7,80003dba <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d72:	000b2483          	lw	s1,0(s6)
    80003d76:	00a9559b          	srliw	a1,s2,0xa
    80003d7a:	855a                	mv	a0,s6
    80003d7c:	fffff097          	auipc	ra,0xfffff
    80003d80:	7ae080e7          	jalr	1966(ra) # 8000352a <bmap>
    80003d84:	0005059b          	sext.w	a1,a0
    80003d88:	8526                	mv	a0,s1
    80003d8a:	fffff097          	auipc	ra,0xfffff
    80003d8e:	3ac080e7          	jalr	940(ra) # 80003136 <bread>
    80003d92:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d94:	3ff97713          	andi	a4,s2,1023
    80003d98:	40ed07bb          	subw	a5,s10,a4
    80003d9c:	414b86bb          	subw	a3,s7,s4
    80003da0:	89be                	mv	s3,a5
    80003da2:	2781                	sext.w	a5,a5
    80003da4:	0006861b          	sext.w	a2,a3
    80003da8:	f8f674e3          	bgeu	a2,a5,80003d30 <writei+0x4c>
    80003dac:	89b6                	mv	s3,a3
    80003dae:	b749                	j	80003d30 <writei+0x4c>
      brelse(bp);
    80003db0:	8526                	mv	a0,s1
    80003db2:	fffff097          	auipc	ra,0xfffff
    80003db6:	4b4080e7          	jalr	1204(ra) # 80003266 <brelse>
  }

  if(off > ip->size)
    80003dba:	04cb2783          	lw	a5,76(s6)
    80003dbe:	0127f463          	bgeu	a5,s2,80003dc6 <writei+0xe2>
    ip->size = off;
    80003dc2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003dc6:	855a                	mv	a0,s6
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	aa6080e7          	jalr	-1370(ra) # 8000386e <iupdate>

  return tot;
    80003dd0:	000a051b          	sext.w	a0,s4
}
    80003dd4:	70a6                	ld	ra,104(sp)
    80003dd6:	7406                	ld	s0,96(sp)
    80003dd8:	64e6                	ld	s1,88(sp)
    80003dda:	6946                	ld	s2,80(sp)
    80003ddc:	69a6                	ld	s3,72(sp)
    80003dde:	6a06                	ld	s4,64(sp)
    80003de0:	7ae2                	ld	s5,56(sp)
    80003de2:	7b42                	ld	s6,48(sp)
    80003de4:	7ba2                	ld	s7,40(sp)
    80003de6:	7c02                	ld	s8,32(sp)
    80003de8:	6ce2                	ld	s9,24(sp)
    80003dea:	6d42                	ld	s10,16(sp)
    80003dec:	6da2                	ld	s11,8(sp)
    80003dee:	6165                	addi	sp,sp,112
    80003df0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003df2:	8a5e                	mv	s4,s7
    80003df4:	bfc9                	j	80003dc6 <writei+0xe2>
    return -1;
    80003df6:	557d                	li	a0,-1
}
    80003df8:	8082                	ret
    return -1;
    80003dfa:	557d                	li	a0,-1
    80003dfc:	bfe1                	j	80003dd4 <writei+0xf0>
    return -1;
    80003dfe:	557d                	li	a0,-1
    80003e00:	bfd1                	j	80003dd4 <writei+0xf0>

0000000080003e02 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e02:	1141                	addi	sp,sp,-16
    80003e04:	e406                	sd	ra,8(sp)
    80003e06:	e022                	sd	s0,0(sp)
    80003e08:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e0a:	4639                	li	a2,14
    80003e0c:	ffffd097          	auipc	ra,0xffffd
    80003e10:	fac080e7          	jalr	-84(ra) # 80000db8 <strncmp>
}
    80003e14:	60a2                	ld	ra,8(sp)
    80003e16:	6402                	ld	s0,0(sp)
    80003e18:	0141                	addi	sp,sp,16
    80003e1a:	8082                	ret

0000000080003e1c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e1c:	7139                	addi	sp,sp,-64
    80003e1e:	fc06                	sd	ra,56(sp)
    80003e20:	f822                	sd	s0,48(sp)
    80003e22:	f426                	sd	s1,40(sp)
    80003e24:	f04a                	sd	s2,32(sp)
    80003e26:	ec4e                	sd	s3,24(sp)
    80003e28:	e852                	sd	s4,16(sp)
    80003e2a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e2c:	04451703          	lh	a4,68(a0)
    80003e30:	4785                	li	a5,1
    80003e32:	00f71a63          	bne	a4,a5,80003e46 <dirlookup+0x2a>
    80003e36:	892a                	mv	s2,a0
    80003e38:	89ae                	mv	s3,a1
    80003e3a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e3c:	457c                	lw	a5,76(a0)
    80003e3e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e40:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e42:	e79d                	bnez	a5,80003e70 <dirlookup+0x54>
    80003e44:	a8a5                	j	80003ebc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e46:	00005517          	auipc	a0,0x5
    80003e4a:	93250513          	addi	a0,a0,-1742 # 80008778 <syscall_names+0x1b0>
    80003e4e:	ffffc097          	auipc	ra,0xffffc
    80003e52:	6f0080e7          	jalr	1776(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e56:	00005517          	auipc	a0,0x5
    80003e5a:	93a50513          	addi	a0,a0,-1734 # 80008790 <syscall_names+0x1c8>
    80003e5e:	ffffc097          	auipc	ra,0xffffc
    80003e62:	6e0080e7          	jalr	1760(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e66:	24c1                	addiw	s1,s1,16
    80003e68:	04c92783          	lw	a5,76(s2)
    80003e6c:	04f4f763          	bgeu	s1,a5,80003eba <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e70:	4741                	li	a4,16
    80003e72:	86a6                	mv	a3,s1
    80003e74:	fc040613          	addi	a2,s0,-64
    80003e78:	4581                	li	a1,0
    80003e7a:	854a                	mv	a0,s2
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	d70080e7          	jalr	-656(ra) # 80003bec <readi>
    80003e84:	47c1                	li	a5,16
    80003e86:	fcf518e3          	bne	a0,a5,80003e56 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e8a:	fc045783          	lhu	a5,-64(s0)
    80003e8e:	dfe1                	beqz	a5,80003e66 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e90:	fc240593          	addi	a1,s0,-62
    80003e94:	854e                	mv	a0,s3
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	f6c080e7          	jalr	-148(ra) # 80003e02 <namecmp>
    80003e9e:	f561                	bnez	a0,80003e66 <dirlookup+0x4a>
      if(poff)
    80003ea0:	000a0463          	beqz	s4,80003ea8 <dirlookup+0x8c>
        *poff = off;
    80003ea4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ea8:	fc045583          	lhu	a1,-64(s0)
    80003eac:	00092503          	lw	a0,0(s2)
    80003eb0:	fffff097          	auipc	ra,0xfffff
    80003eb4:	754080e7          	jalr	1876(ra) # 80003604 <iget>
    80003eb8:	a011                	j	80003ebc <dirlookup+0xa0>
  return 0;
    80003eba:	4501                	li	a0,0
}
    80003ebc:	70e2                	ld	ra,56(sp)
    80003ebe:	7442                	ld	s0,48(sp)
    80003ec0:	74a2                	ld	s1,40(sp)
    80003ec2:	7902                	ld	s2,32(sp)
    80003ec4:	69e2                	ld	s3,24(sp)
    80003ec6:	6a42                	ld	s4,16(sp)
    80003ec8:	6121                	addi	sp,sp,64
    80003eca:	8082                	ret

0000000080003ecc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ecc:	711d                	addi	sp,sp,-96
    80003ece:	ec86                	sd	ra,88(sp)
    80003ed0:	e8a2                	sd	s0,80(sp)
    80003ed2:	e4a6                	sd	s1,72(sp)
    80003ed4:	e0ca                	sd	s2,64(sp)
    80003ed6:	fc4e                	sd	s3,56(sp)
    80003ed8:	f852                	sd	s4,48(sp)
    80003eda:	f456                	sd	s5,40(sp)
    80003edc:	f05a                	sd	s6,32(sp)
    80003ede:	ec5e                	sd	s7,24(sp)
    80003ee0:	e862                	sd	s8,16(sp)
    80003ee2:	e466                	sd	s9,8(sp)
    80003ee4:	1080                	addi	s0,sp,96
    80003ee6:	84aa                	mv	s1,a0
    80003ee8:	8b2e                	mv	s6,a1
    80003eea:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003eec:	00054703          	lbu	a4,0(a0)
    80003ef0:	02f00793          	li	a5,47
    80003ef4:	02f70363          	beq	a4,a5,80003f1a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ef8:	ffffe097          	auipc	ra,0xffffe
    80003efc:	ab8080e7          	jalr	-1352(ra) # 800019b0 <myproc>
    80003f00:	15053503          	ld	a0,336(a0)
    80003f04:	00000097          	auipc	ra,0x0
    80003f08:	9f6080e7          	jalr	-1546(ra) # 800038fa <idup>
    80003f0c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f0e:	02f00913          	li	s2,47
  len = path - s;
    80003f12:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f14:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f16:	4c05                	li	s8,1
    80003f18:	a865                	j	80003fd0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f1a:	4585                	li	a1,1
    80003f1c:	4505                	li	a0,1
    80003f1e:	fffff097          	auipc	ra,0xfffff
    80003f22:	6e6080e7          	jalr	1766(ra) # 80003604 <iget>
    80003f26:	89aa                	mv	s3,a0
    80003f28:	b7dd                	j	80003f0e <namex+0x42>
      iunlockput(ip);
    80003f2a:	854e                	mv	a0,s3
    80003f2c:	00000097          	auipc	ra,0x0
    80003f30:	c6e080e7          	jalr	-914(ra) # 80003b9a <iunlockput>
      return 0;
    80003f34:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f36:	854e                	mv	a0,s3
    80003f38:	60e6                	ld	ra,88(sp)
    80003f3a:	6446                	ld	s0,80(sp)
    80003f3c:	64a6                	ld	s1,72(sp)
    80003f3e:	6906                	ld	s2,64(sp)
    80003f40:	79e2                	ld	s3,56(sp)
    80003f42:	7a42                	ld	s4,48(sp)
    80003f44:	7aa2                	ld	s5,40(sp)
    80003f46:	7b02                	ld	s6,32(sp)
    80003f48:	6be2                	ld	s7,24(sp)
    80003f4a:	6c42                	ld	s8,16(sp)
    80003f4c:	6ca2                	ld	s9,8(sp)
    80003f4e:	6125                	addi	sp,sp,96
    80003f50:	8082                	ret
      iunlock(ip);
    80003f52:	854e                	mv	a0,s3
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	aa6080e7          	jalr	-1370(ra) # 800039fa <iunlock>
      return ip;
    80003f5c:	bfe9                	j	80003f36 <namex+0x6a>
      iunlockput(ip);
    80003f5e:	854e                	mv	a0,s3
    80003f60:	00000097          	auipc	ra,0x0
    80003f64:	c3a080e7          	jalr	-966(ra) # 80003b9a <iunlockput>
      return 0;
    80003f68:	89d2                	mv	s3,s4
    80003f6a:	b7f1                	j	80003f36 <namex+0x6a>
  len = path - s;
    80003f6c:	40b48633          	sub	a2,s1,a1
    80003f70:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f74:	094cd463          	bge	s9,s4,80003ffc <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f78:	4639                	li	a2,14
    80003f7a:	8556                	mv	a0,s5
    80003f7c:	ffffd097          	auipc	ra,0xffffd
    80003f80:	dc4080e7          	jalr	-572(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003f84:	0004c783          	lbu	a5,0(s1)
    80003f88:	01279763          	bne	a5,s2,80003f96 <namex+0xca>
    path++;
    80003f8c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f8e:	0004c783          	lbu	a5,0(s1)
    80003f92:	ff278de3          	beq	a5,s2,80003f8c <namex+0xc0>
    ilock(ip);
    80003f96:	854e                	mv	a0,s3
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	9a0080e7          	jalr	-1632(ra) # 80003938 <ilock>
    if(ip->type != T_DIR){
    80003fa0:	04499783          	lh	a5,68(s3)
    80003fa4:	f98793e3          	bne	a5,s8,80003f2a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fa8:	000b0563          	beqz	s6,80003fb2 <namex+0xe6>
    80003fac:	0004c783          	lbu	a5,0(s1)
    80003fb0:	d3cd                	beqz	a5,80003f52 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fb2:	865e                	mv	a2,s7
    80003fb4:	85d6                	mv	a1,s5
    80003fb6:	854e                	mv	a0,s3
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	e64080e7          	jalr	-412(ra) # 80003e1c <dirlookup>
    80003fc0:	8a2a                	mv	s4,a0
    80003fc2:	dd51                	beqz	a0,80003f5e <namex+0x92>
    iunlockput(ip);
    80003fc4:	854e                	mv	a0,s3
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	bd4080e7          	jalr	-1068(ra) # 80003b9a <iunlockput>
    ip = next;
    80003fce:	89d2                	mv	s3,s4
  while(*path == '/')
    80003fd0:	0004c783          	lbu	a5,0(s1)
    80003fd4:	05279763          	bne	a5,s2,80004022 <namex+0x156>
    path++;
    80003fd8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fda:	0004c783          	lbu	a5,0(s1)
    80003fde:	ff278de3          	beq	a5,s2,80003fd8 <namex+0x10c>
  if(*path == 0)
    80003fe2:	c79d                	beqz	a5,80004010 <namex+0x144>
    path++;
    80003fe4:	85a6                	mv	a1,s1
  len = path - s;
    80003fe6:	8a5e                	mv	s4,s7
    80003fe8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003fea:	01278963          	beq	a5,s2,80003ffc <namex+0x130>
    80003fee:	dfbd                	beqz	a5,80003f6c <namex+0xa0>
    path++;
    80003ff0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ff2:	0004c783          	lbu	a5,0(s1)
    80003ff6:	ff279ce3          	bne	a5,s2,80003fee <namex+0x122>
    80003ffa:	bf8d                	j	80003f6c <namex+0xa0>
    memmove(name, s, len);
    80003ffc:	2601                	sext.w	a2,a2
    80003ffe:	8556                	mv	a0,s5
    80004000:	ffffd097          	auipc	ra,0xffffd
    80004004:	d40080e7          	jalr	-704(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004008:	9a56                	add	s4,s4,s5
    8000400a:	000a0023          	sb	zero,0(s4)
    8000400e:	bf9d                	j	80003f84 <namex+0xb8>
  if(nameiparent){
    80004010:	f20b03e3          	beqz	s6,80003f36 <namex+0x6a>
    iput(ip);
    80004014:	854e                	mv	a0,s3
    80004016:	00000097          	auipc	ra,0x0
    8000401a:	adc080e7          	jalr	-1316(ra) # 80003af2 <iput>
    return 0;
    8000401e:	4981                	li	s3,0
    80004020:	bf19                	j	80003f36 <namex+0x6a>
  if(*path == 0)
    80004022:	d7fd                	beqz	a5,80004010 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004024:	0004c783          	lbu	a5,0(s1)
    80004028:	85a6                	mv	a1,s1
    8000402a:	b7d1                	j	80003fee <namex+0x122>

000000008000402c <dirlink>:
{
    8000402c:	7139                	addi	sp,sp,-64
    8000402e:	fc06                	sd	ra,56(sp)
    80004030:	f822                	sd	s0,48(sp)
    80004032:	f426                	sd	s1,40(sp)
    80004034:	f04a                	sd	s2,32(sp)
    80004036:	ec4e                	sd	s3,24(sp)
    80004038:	e852                	sd	s4,16(sp)
    8000403a:	0080                	addi	s0,sp,64
    8000403c:	892a                	mv	s2,a0
    8000403e:	8a2e                	mv	s4,a1
    80004040:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004042:	4601                	li	a2,0
    80004044:	00000097          	auipc	ra,0x0
    80004048:	dd8080e7          	jalr	-552(ra) # 80003e1c <dirlookup>
    8000404c:	e93d                	bnez	a0,800040c2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000404e:	04c92483          	lw	s1,76(s2)
    80004052:	c49d                	beqz	s1,80004080 <dirlink+0x54>
    80004054:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004056:	4741                	li	a4,16
    80004058:	86a6                	mv	a3,s1
    8000405a:	fc040613          	addi	a2,s0,-64
    8000405e:	4581                	li	a1,0
    80004060:	854a                	mv	a0,s2
    80004062:	00000097          	auipc	ra,0x0
    80004066:	b8a080e7          	jalr	-1142(ra) # 80003bec <readi>
    8000406a:	47c1                	li	a5,16
    8000406c:	06f51163          	bne	a0,a5,800040ce <dirlink+0xa2>
    if(de.inum == 0)
    80004070:	fc045783          	lhu	a5,-64(s0)
    80004074:	c791                	beqz	a5,80004080 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004076:	24c1                	addiw	s1,s1,16
    80004078:	04c92783          	lw	a5,76(s2)
    8000407c:	fcf4ede3          	bltu	s1,a5,80004056 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004080:	4639                	li	a2,14
    80004082:	85d2                	mv	a1,s4
    80004084:	fc240513          	addi	a0,s0,-62
    80004088:	ffffd097          	auipc	ra,0xffffd
    8000408c:	d6c080e7          	jalr	-660(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004090:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004094:	4741                	li	a4,16
    80004096:	86a6                	mv	a3,s1
    80004098:	fc040613          	addi	a2,s0,-64
    8000409c:	4581                	li	a1,0
    8000409e:	854a                	mv	a0,s2
    800040a0:	00000097          	auipc	ra,0x0
    800040a4:	c44080e7          	jalr	-956(ra) # 80003ce4 <writei>
    800040a8:	872a                	mv	a4,a0
    800040aa:	47c1                	li	a5,16
  return 0;
    800040ac:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ae:	02f71863          	bne	a4,a5,800040de <dirlink+0xb2>
}
    800040b2:	70e2                	ld	ra,56(sp)
    800040b4:	7442                	ld	s0,48(sp)
    800040b6:	74a2                	ld	s1,40(sp)
    800040b8:	7902                	ld	s2,32(sp)
    800040ba:	69e2                	ld	s3,24(sp)
    800040bc:	6a42                	ld	s4,16(sp)
    800040be:	6121                	addi	sp,sp,64
    800040c0:	8082                	ret
    iput(ip);
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	a30080e7          	jalr	-1488(ra) # 80003af2 <iput>
    return -1;
    800040ca:	557d                	li	a0,-1
    800040cc:	b7dd                	j	800040b2 <dirlink+0x86>
      panic("dirlink read");
    800040ce:	00004517          	auipc	a0,0x4
    800040d2:	6d250513          	addi	a0,a0,1746 # 800087a0 <syscall_names+0x1d8>
    800040d6:	ffffc097          	auipc	ra,0xffffc
    800040da:	468080e7          	jalr	1128(ra) # 8000053e <panic>
    panic("dirlink");
    800040de:	00004517          	auipc	a0,0x4
    800040e2:	7ca50513          	addi	a0,a0,1994 # 800088a8 <syscall_names+0x2e0>
    800040e6:	ffffc097          	auipc	ra,0xffffc
    800040ea:	458080e7          	jalr	1112(ra) # 8000053e <panic>

00000000800040ee <namei>:

struct inode*
namei(char *path)
{
    800040ee:	1101                	addi	sp,sp,-32
    800040f0:	ec06                	sd	ra,24(sp)
    800040f2:	e822                	sd	s0,16(sp)
    800040f4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040f6:	fe040613          	addi	a2,s0,-32
    800040fa:	4581                	li	a1,0
    800040fc:	00000097          	auipc	ra,0x0
    80004100:	dd0080e7          	jalr	-560(ra) # 80003ecc <namex>
}
    80004104:	60e2                	ld	ra,24(sp)
    80004106:	6442                	ld	s0,16(sp)
    80004108:	6105                	addi	sp,sp,32
    8000410a:	8082                	ret

000000008000410c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000410c:	1141                	addi	sp,sp,-16
    8000410e:	e406                	sd	ra,8(sp)
    80004110:	e022                	sd	s0,0(sp)
    80004112:	0800                	addi	s0,sp,16
    80004114:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004116:	4585                	li	a1,1
    80004118:	00000097          	auipc	ra,0x0
    8000411c:	db4080e7          	jalr	-588(ra) # 80003ecc <namex>
}
    80004120:	60a2                	ld	ra,8(sp)
    80004122:	6402                	ld	s0,0(sp)
    80004124:	0141                	addi	sp,sp,16
    80004126:	8082                	ret

0000000080004128 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004128:	1101                	addi	sp,sp,-32
    8000412a:	ec06                	sd	ra,24(sp)
    8000412c:	e822                	sd	s0,16(sp)
    8000412e:	e426                	sd	s1,8(sp)
    80004130:	e04a                	sd	s2,0(sp)
    80004132:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004134:	0001d917          	auipc	s2,0x1d
    80004138:	73c90913          	addi	s2,s2,1852 # 80021870 <log>
    8000413c:	01892583          	lw	a1,24(s2)
    80004140:	02892503          	lw	a0,40(s2)
    80004144:	fffff097          	auipc	ra,0xfffff
    80004148:	ff2080e7          	jalr	-14(ra) # 80003136 <bread>
    8000414c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000414e:	02c92683          	lw	a3,44(s2)
    80004152:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004154:	02d05763          	blez	a3,80004182 <write_head+0x5a>
    80004158:	0001d797          	auipc	a5,0x1d
    8000415c:	74878793          	addi	a5,a5,1864 # 800218a0 <log+0x30>
    80004160:	05c50713          	addi	a4,a0,92
    80004164:	36fd                	addiw	a3,a3,-1
    80004166:	1682                	slli	a3,a3,0x20
    80004168:	9281                	srli	a3,a3,0x20
    8000416a:	068a                	slli	a3,a3,0x2
    8000416c:	0001d617          	auipc	a2,0x1d
    80004170:	73860613          	addi	a2,a2,1848 # 800218a4 <log+0x34>
    80004174:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004176:	4390                	lw	a2,0(a5)
    80004178:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000417a:	0791                	addi	a5,a5,4
    8000417c:	0711                	addi	a4,a4,4
    8000417e:	fed79ce3          	bne	a5,a3,80004176 <write_head+0x4e>
  }
  bwrite(buf);
    80004182:	8526                	mv	a0,s1
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	0a4080e7          	jalr	164(ra) # 80003228 <bwrite>
  brelse(buf);
    8000418c:	8526                	mv	a0,s1
    8000418e:	fffff097          	auipc	ra,0xfffff
    80004192:	0d8080e7          	jalr	216(ra) # 80003266 <brelse>
}
    80004196:	60e2                	ld	ra,24(sp)
    80004198:	6442                	ld	s0,16(sp)
    8000419a:	64a2                	ld	s1,8(sp)
    8000419c:	6902                	ld	s2,0(sp)
    8000419e:	6105                	addi	sp,sp,32
    800041a0:	8082                	ret

00000000800041a2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a2:	0001d797          	auipc	a5,0x1d
    800041a6:	6fa7a783          	lw	a5,1786(a5) # 8002189c <log+0x2c>
    800041aa:	0af05d63          	blez	a5,80004264 <install_trans+0xc2>
{
    800041ae:	7139                	addi	sp,sp,-64
    800041b0:	fc06                	sd	ra,56(sp)
    800041b2:	f822                	sd	s0,48(sp)
    800041b4:	f426                	sd	s1,40(sp)
    800041b6:	f04a                	sd	s2,32(sp)
    800041b8:	ec4e                	sd	s3,24(sp)
    800041ba:	e852                	sd	s4,16(sp)
    800041bc:	e456                	sd	s5,8(sp)
    800041be:	e05a                	sd	s6,0(sp)
    800041c0:	0080                	addi	s0,sp,64
    800041c2:	8b2a                	mv	s6,a0
    800041c4:	0001da97          	auipc	s5,0x1d
    800041c8:	6dca8a93          	addi	s5,s5,1756 # 800218a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041cc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041ce:	0001d997          	auipc	s3,0x1d
    800041d2:	6a298993          	addi	s3,s3,1698 # 80021870 <log>
    800041d6:	a035                	j	80004202 <install_trans+0x60>
      bunpin(dbuf);
    800041d8:	8526                	mv	a0,s1
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	166080e7          	jalr	358(ra) # 80003340 <bunpin>
    brelse(lbuf);
    800041e2:	854a                	mv	a0,s2
    800041e4:	fffff097          	auipc	ra,0xfffff
    800041e8:	082080e7          	jalr	130(ra) # 80003266 <brelse>
    brelse(dbuf);
    800041ec:	8526                	mv	a0,s1
    800041ee:	fffff097          	auipc	ra,0xfffff
    800041f2:	078080e7          	jalr	120(ra) # 80003266 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041f6:	2a05                	addiw	s4,s4,1
    800041f8:	0a91                	addi	s5,s5,4
    800041fa:	02c9a783          	lw	a5,44(s3)
    800041fe:	04fa5963          	bge	s4,a5,80004250 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004202:	0189a583          	lw	a1,24(s3)
    80004206:	014585bb          	addw	a1,a1,s4
    8000420a:	2585                	addiw	a1,a1,1
    8000420c:	0289a503          	lw	a0,40(s3)
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	f26080e7          	jalr	-218(ra) # 80003136 <bread>
    80004218:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000421a:	000aa583          	lw	a1,0(s5)
    8000421e:	0289a503          	lw	a0,40(s3)
    80004222:	fffff097          	auipc	ra,0xfffff
    80004226:	f14080e7          	jalr	-236(ra) # 80003136 <bread>
    8000422a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000422c:	40000613          	li	a2,1024
    80004230:	05890593          	addi	a1,s2,88
    80004234:	05850513          	addi	a0,a0,88
    80004238:	ffffd097          	auipc	ra,0xffffd
    8000423c:	b08080e7          	jalr	-1272(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004240:	8526                	mv	a0,s1
    80004242:	fffff097          	auipc	ra,0xfffff
    80004246:	fe6080e7          	jalr	-26(ra) # 80003228 <bwrite>
    if(recovering == 0)
    8000424a:	f80b1ce3          	bnez	s6,800041e2 <install_trans+0x40>
    8000424e:	b769                	j	800041d8 <install_trans+0x36>
}
    80004250:	70e2                	ld	ra,56(sp)
    80004252:	7442                	ld	s0,48(sp)
    80004254:	74a2                	ld	s1,40(sp)
    80004256:	7902                	ld	s2,32(sp)
    80004258:	69e2                	ld	s3,24(sp)
    8000425a:	6a42                	ld	s4,16(sp)
    8000425c:	6aa2                	ld	s5,8(sp)
    8000425e:	6b02                	ld	s6,0(sp)
    80004260:	6121                	addi	sp,sp,64
    80004262:	8082                	ret
    80004264:	8082                	ret

0000000080004266 <initlog>:
{
    80004266:	7179                	addi	sp,sp,-48
    80004268:	f406                	sd	ra,40(sp)
    8000426a:	f022                	sd	s0,32(sp)
    8000426c:	ec26                	sd	s1,24(sp)
    8000426e:	e84a                	sd	s2,16(sp)
    80004270:	e44e                	sd	s3,8(sp)
    80004272:	1800                	addi	s0,sp,48
    80004274:	892a                	mv	s2,a0
    80004276:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004278:	0001d497          	auipc	s1,0x1d
    8000427c:	5f848493          	addi	s1,s1,1528 # 80021870 <log>
    80004280:	00004597          	auipc	a1,0x4
    80004284:	53058593          	addi	a1,a1,1328 # 800087b0 <syscall_names+0x1e8>
    80004288:	8526                	mv	a0,s1
    8000428a:	ffffd097          	auipc	ra,0xffffd
    8000428e:	8ca080e7          	jalr	-1846(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004292:	0149a583          	lw	a1,20(s3)
    80004296:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004298:	0109a783          	lw	a5,16(s3)
    8000429c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000429e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042a2:	854a                	mv	a0,s2
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	e92080e7          	jalr	-366(ra) # 80003136 <bread>
  log.lh.n = lh->n;
    800042ac:	4d3c                	lw	a5,88(a0)
    800042ae:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042b0:	02f05563          	blez	a5,800042da <initlog+0x74>
    800042b4:	05c50713          	addi	a4,a0,92
    800042b8:	0001d697          	auipc	a3,0x1d
    800042bc:	5e868693          	addi	a3,a3,1512 # 800218a0 <log+0x30>
    800042c0:	37fd                	addiw	a5,a5,-1
    800042c2:	1782                	slli	a5,a5,0x20
    800042c4:	9381                	srli	a5,a5,0x20
    800042c6:	078a                	slli	a5,a5,0x2
    800042c8:	06050613          	addi	a2,a0,96
    800042cc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800042ce:	4310                	lw	a2,0(a4)
    800042d0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800042d2:	0711                	addi	a4,a4,4
    800042d4:	0691                	addi	a3,a3,4
    800042d6:	fef71ce3          	bne	a4,a5,800042ce <initlog+0x68>
  brelse(buf);
    800042da:	fffff097          	auipc	ra,0xfffff
    800042de:	f8c080e7          	jalr	-116(ra) # 80003266 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042e2:	4505                	li	a0,1
    800042e4:	00000097          	auipc	ra,0x0
    800042e8:	ebe080e7          	jalr	-322(ra) # 800041a2 <install_trans>
  log.lh.n = 0;
    800042ec:	0001d797          	auipc	a5,0x1d
    800042f0:	5a07a823          	sw	zero,1456(a5) # 8002189c <log+0x2c>
  write_head(); // clear the log
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	e34080e7          	jalr	-460(ra) # 80004128 <write_head>
}
    800042fc:	70a2                	ld	ra,40(sp)
    800042fe:	7402                	ld	s0,32(sp)
    80004300:	64e2                	ld	s1,24(sp)
    80004302:	6942                	ld	s2,16(sp)
    80004304:	69a2                	ld	s3,8(sp)
    80004306:	6145                	addi	sp,sp,48
    80004308:	8082                	ret

000000008000430a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000430a:	1101                	addi	sp,sp,-32
    8000430c:	ec06                	sd	ra,24(sp)
    8000430e:	e822                	sd	s0,16(sp)
    80004310:	e426                	sd	s1,8(sp)
    80004312:	e04a                	sd	s2,0(sp)
    80004314:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004316:	0001d517          	auipc	a0,0x1d
    8000431a:	55a50513          	addi	a0,a0,1370 # 80021870 <log>
    8000431e:	ffffd097          	auipc	ra,0xffffd
    80004322:	8c6080e7          	jalr	-1850(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004326:	0001d497          	auipc	s1,0x1d
    8000432a:	54a48493          	addi	s1,s1,1354 # 80021870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000432e:	4979                	li	s2,30
    80004330:	a039                	j	8000433e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004332:	85a6                	mv	a1,s1
    80004334:	8526                	mv	a0,s1
    80004336:	ffffe097          	auipc	ra,0xffffe
    8000433a:	e1c080e7          	jalr	-484(ra) # 80002152 <sleep>
    if(log.committing){
    8000433e:	50dc                	lw	a5,36(s1)
    80004340:	fbed                	bnez	a5,80004332 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004342:	509c                	lw	a5,32(s1)
    80004344:	0017871b          	addiw	a4,a5,1
    80004348:	0007069b          	sext.w	a3,a4
    8000434c:	0027179b          	slliw	a5,a4,0x2
    80004350:	9fb9                	addw	a5,a5,a4
    80004352:	0017979b          	slliw	a5,a5,0x1
    80004356:	54d8                	lw	a4,44(s1)
    80004358:	9fb9                	addw	a5,a5,a4
    8000435a:	00f95963          	bge	s2,a5,8000436c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000435e:	85a6                	mv	a1,s1
    80004360:	8526                	mv	a0,s1
    80004362:	ffffe097          	auipc	ra,0xffffe
    80004366:	df0080e7          	jalr	-528(ra) # 80002152 <sleep>
    8000436a:	bfd1                	j	8000433e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000436c:	0001d517          	auipc	a0,0x1d
    80004370:	50450513          	addi	a0,a0,1284 # 80021870 <log>
    80004374:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	922080e7          	jalr	-1758(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000437e:	60e2                	ld	ra,24(sp)
    80004380:	6442                	ld	s0,16(sp)
    80004382:	64a2                	ld	s1,8(sp)
    80004384:	6902                	ld	s2,0(sp)
    80004386:	6105                	addi	sp,sp,32
    80004388:	8082                	ret

000000008000438a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000438a:	7139                	addi	sp,sp,-64
    8000438c:	fc06                	sd	ra,56(sp)
    8000438e:	f822                	sd	s0,48(sp)
    80004390:	f426                	sd	s1,40(sp)
    80004392:	f04a                	sd	s2,32(sp)
    80004394:	ec4e                	sd	s3,24(sp)
    80004396:	e852                	sd	s4,16(sp)
    80004398:	e456                	sd	s5,8(sp)
    8000439a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000439c:	0001d497          	auipc	s1,0x1d
    800043a0:	4d448493          	addi	s1,s1,1236 # 80021870 <log>
    800043a4:	8526                	mv	a0,s1
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	83e080e7          	jalr	-1986(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800043ae:	509c                	lw	a5,32(s1)
    800043b0:	37fd                	addiw	a5,a5,-1
    800043b2:	0007891b          	sext.w	s2,a5
    800043b6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043b8:	50dc                	lw	a5,36(s1)
    800043ba:	efb9                	bnez	a5,80004418 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043bc:	06091663          	bnez	s2,80004428 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043c0:	0001d497          	auipc	s1,0x1d
    800043c4:	4b048493          	addi	s1,s1,1200 # 80021870 <log>
    800043c8:	4785                	li	a5,1
    800043ca:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043cc:	8526                	mv	a0,s1
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	8ca080e7          	jalr	-1846(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043d6:	54dc                	lw	a5,44(s1)
    800043d8:	06f04763          	bgtz	a5,80004446 <end_op+0xbc>
    acquire(&log.lock);
    800043dc:	0001d497          	auipc	s1,0x1d
    800043e0:	49448493          	addi	s1,s1,1172 # 80021870 <log>
    800043e4:	8526                	mv	a0,s1
    800043e6:	ffffc097          	auipc	ra,0xffffc
    800043ea:	7fe080e7          	jalr	2046(ra) # 80000be4 <acquire>
    log.committing = 0;
    800043ee:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043f2:	8526                	mv	a0,s1
    800043f4:	ffffe097          	auipc	ra,0xffffe
    800043f8:	036080e7          	jalr	54(ra) # 8000242a <wakeup>
    release(&log.lock);
    800043fc:	8526                	mv	a0,s1
    800043fe:	ffffd097          	auipc	ra,0xffffd
    80004402:	89a080e7          	jalr	-1894(ra) # 80000c98 <release>
}
    80004406:	70e2                	ld	ra,56(sp)
    80004408:	7442                	ld	s0,48(sp)
    8000440a:	74a2                	ld	s1,40(sp)
    8000440c:	7902                	ld	s2,32(sp)
    8000440e:	69e2                	ld	s3,24(sp)
    80004410:	6a42                	ld	s4,16(sp)
    80004412:	6aa2                	ld	s5,8(sp)
    80004414:	6121                	addi	sp,sp,64
    80004416:	8082                	ret
    panic("log.committing");
    80004418:	00004517          	auipc	a0,0x4
    8000441c:	3a050513          	addi	a0,a0,928 # 800087b8 <syscall_names+0x1f0>
    80004420:	ffffc097          	auipc	ra,0xffffc
    80004424:	11e080e7          	jalr	286(ra) # 8000053e <panic>
    wakeup(&log);
    80004428:	0001d497          	auipc	s1,0x1d
    8000442c:	44848493          	addi	s1,s1,1096 # 80021870 <log>
    80004430:	8526                	mv	a0,s1
    80004432:	ffffe097          	auipc	ra,0xffffe
    80004436:	ff8080e7          	jalr	-8(ra) # 8000242a <wakeup>
  release(&log.lock);
    8000443a:	8526                	mv	a0,s1
    8000443c:	ffffd097          	auipc	ra,0xffffd
    80004440:	85c080e7          	jalr	-1956(ra) # 80000c98 <release>
  if(do_commit){
    80004444:	b7c9                	j	80004406 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004446:	0001da97          	auipc	s5,0x1d
    8000444a:	45aa8a93          	addi	s5,s5,1114 # 800218a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000444e:	0001da17          	auipc	s4,0x1d
    80004452:	422a0a13          	addi	s4,s4,1058 # 80021870 <log>
    80004456:	018a2583          	lw	a1,24(s4)
    8000445a:	012585bb          	addw	a1,a1,s2
    8000445e:	2585                	addiw	a1,a1,1
    80004460:	028a2503          	lw	a0,40(s4)
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	cd2080e7          	jalr	-814(ra) # 80003136 <bread>
    8000446c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000446e:	000aa583          	lw	a1,0(s5)
    80004472:	028a2503          	lw	a0,40(s4)
    80004476:	fffff097          	auipc	ra,0xfffff
    8000447a:	cc0080e7          	jalr	-832(ra) # 80003136 <bread>
    8000447e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004480:	40000613          	li	a2,1024
    80004484:	05850593          	addi	a1,a0,88
    80004488:	05848513          	addi	a0,s1,88
    8000448c:	ffffd097          	auipc	ra,0xffffd
    80004490:	8b4080e7          	jalr	-1868(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004494:	8526                	mv	a0,s1
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	d92080e7          	jalr	-622(ra) # 80003228 <bwrite>
    brelse(from);
    8000449e:	854e                	mv	a0,s3
    800044a0:	fffff097          	auipc	ra,0xfffff
    800044a4:	dc6080e7          	jalr	-570(ra) # 80003266 <brelse>
    brelse(to);
    800044a8:	8526                	mv	a0,s1
    800044aa:	fffff097          	auipc	ra,0xfffff
    800044ae:	dbc080e7          	jalr	-580(ra) # 80003266 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b2:	2905                	addiw	s2,s2,1
    800044b4:	0a91                	addi	s5,s5,4
    800044b6:	02ca2783          	lw	a5,44(s4)
    800044ba:	f8f94ee3          	blt	s2,a5,80004456 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044be:	00000097          	auipc	ra,0x0
    800044c2:	c6a080e7          	jalr	-918(ra) # 80004128 <write_head>
    install_trans(0); // Now install writes to home locations
    800044c6:	4501                	li	a0,0
    800044c8:	00000097          	auipc	ra,0x0
    800044cc:	cda080e7          	jalr	-806(ra) # 800041a2 <install_trans>
    log.lh.n = 0;
    800044d0:	0001d797          	auipc	a5,0x1d
    800044d4:	3c07a623          	sw	zero,972(a5) # 8002189c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044d8:	00000097          	auipc	ra,0x0
    800044dc:	c50080e7          	jalr	-944(ra) # 80004128 <write_head>
    800044e0:	bdf5                	j	800043dc <end_op+0x52>

00000000800044e2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044e2:	1101                	addi	sp,sp,-32
    800044e4:	ec06                	sd	ra,24(sp)
    800044e6:	e822                	sd	s0,16(sp)
    800044e8:	e426                	sd	s1,8(sp)
    800044ea:	e04a                	sd	s2,0(sp)
    800044ec:	1000                	addi	s0,sp,32
    800044ee:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044f0:	0001d917          	auipc	s2,0x1d
    800044f4:	38090913          	addi	s2,s2,896 # 80021870 <log>
    800044f8:	854a                	mv	a0,s2
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	6ea080e7          	jalr	1770(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004502:	02c92603          	lw	a2,44(s2)
    80004506:	47f5                	li	a5,29
    80004508:	06c7c563          	blt	a5,a2,80004572 <log_write+0x90>
    8000450c:	0001d797          	auipc	a5,0x1d
    80004510:	3807a783          	lw	a5,896(a5) # 8002188c <log+0x1c>
    80004514:	37fd                	addiw	a5,a5,-1
    80004516:	04f65e63          	bge	a2,a5,80004572 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000451a:	0001d797          	auipc	a5,0x1d
    8000451e:	3767a783          	lw	a5,886(a5) # 80021890 <log+0x20>
    80004522:	06f05063          	blez	a5,80004582 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004526:	4781                	li	a5,0
    80004528:	06c05563          	blez	a2,80004592 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000452c:	44cc                	lw	a1,12(s1)
    8000452e:	0001d717          	auipc	a4,0x1d
    80004532:	37270713          	addi	a4,a4,882 # 800218a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004536:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004538:	4314                	lw	a3,0(a4)
    8000453a:	04b68c63          	beq	a3,a1,80004592 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000453e:	2785                	addiw	a5,a5,1
    80004540:	0711                	addi	a4,a4,4
    80004542:	fef61be3          	bne	a2,a5,80004538 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004546:	0621                	addi	a2,a2,8
    80004548:	060a                	slli	a2,a2,0x2
    8000454a:	0001d797          	auipc	a5,0x1d
    8000454e:	32678793          	addi	a5,a5,806 # 80021870 <log>
    80004552:	963e                	add	a2,a2,a5
    80004554:	44dc                	lw	a5,12(s1)
    80004556:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004558:	8526                	mv	a0,s1
    8000455a:	fffff097          	auipc	ra,0xfffff
    8000455e:	daa080e7          	jalr	-598(ra) # 80003304 <bpin>
    log.lh.n++;
    80004562:	0001d717          	auipc	a4,0x1d
    80004566:	30e70713          	addi	a4,a4,782 # 80021870 <log>
    8000456a:	575c                	lw	a5,44(a4)
    8000456c:	2785                	addiw	a5,a5,1
    8000456e:	d75c                	sw	a5,44(a4)
    80004570:	a835                	j	800045ac <log_write+0xca>
    panic("too big a transaction");
    80004572:	00004517          	auipc	a0,0x4
    80004576:	25650513          	addi	a0,a0,598 # 800087c8 <syscall_names+0x200>
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	fc4080e7          	jalr	-60(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004582:	00004517          	auipc	a0,0x4
    80004586:	25e50513          	addi	a0,a0,606 # 800087e0 <syscall_names+0x218>
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	fb4080e7          	jalr	-76(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004592:	00878713          	addi	a4,a5,8
    80004596:	00271693          	slli	a3,a4,0x2
    8000459a:	0001d717          	auipc	a4,0x1d
    8000459e:	2d670713          	addi	a4,a4,726 # 80021870 <log>
    800045a2:	9736                	add	a4,a4,a3
    800045a4:	44d4                	lw	a3,12(s1)
    800045a6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045a8:	faf608e3          	beq	a2,a5,80004558 <log_write+0x76>
  }
  release(&log.lock);
    800045ac:	0001d517          	auipc	a0,0x1d
    800045b0:	2c450513          	addi	a0,a0,708 # 80021870 <log>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	6e4080e7          	jalr	1764(ra) # 80000c98 <release>
}
    800045bc:	60e2                	ld	ra,24(sp)
    800045be:	6442                	ld	s0,16(sp)
    800045c0:	64a2                	ld	s1,8(sp)
    800045c2:	6902                	ld	s2,0(sp)
    800045c4:	6105                	addi	sp,sp,32
    800045c6:	8082                	ret

00000000800045c8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045c8:	1101                	addi	sp,sp,-32
    800045ca:	ec06                	sd	ra,24(sp)
    800045cc:	e822                	sd	s0,16(sp)
    800045ce:	e426                	sd	s1,8(sp)
    800045d0:	e04a                	sd	s2,0(sp)
    800045d2:	1000                	addi	s0,sp,32
    800045d4:	84aa                	mv	s1,a0
    800045d6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045d8:	00004597          	auipc	a1,0x4
    800045dc:	22858593          	addi	a1,a1,552 # 80008800 <syscall_names+0x238>
    800045e0:	0521                	addi	a0,a0,8
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	572080e7          	jalr	1394(ra) # 80000b54 <initlock>
  lk->name = name;
    800045ea:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045ee:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045f2:	0204a423          	sw	zero,40(s1)
}
    800045f6:	60e2                	ld	ra,24(sp)
    800045f8:	6442                	ld	s0,16(sp)
    800045fa:	64a2                	ld	s1,8(sp)
    800045fc:	6902                	ld	s2,0(sp)
    800045fe:	6105                	addi	sp,sp,32
    80004600:	8082                	ret

0000000080004602 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004602:	1101                	addi	sp,sp,-32
    80004604:	ec06                	sd	ra,24(sp)
    80004606:	e822                	sd	s0,16(sp)
    80004608:	e426                	sd	s1,8(sp)
    8000460a:	e04a                	sd	s2,0(sp)
    8000460c:	1000                	addi	s0,sp,32
    8000460e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004610:	00850913          	addi	s2,a0,8
    80004614:	854a                	mv	a0,s2
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	5ce080e7          	jalr	1486(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000461e:	409c                	lw	a5,0(s1)
    80004620:	cb89                	beqz	a5,80004632 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004622:	85ca                	mv	a1,s2
    80004624:	8526                	mv	a0,s1
    80004626:	ffffe097          	auipc	ra,0xffffe
    8000462a:	b2c080e7          	jalr	-1236(ra) # 80002152 <sleep>
  while (lk->locked) {
    8000462e:	409c                	lw	a5,0(s1)
    80004630:	fbed                	bnez	a5,80004622 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004632:	4785                	li	a5,1
    80004634:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004636:	ffffd097          	auipc	ra,0xffffd
    8000463a:	37a080e7          	jalr	890(ra) # 800019b0 <myproc>
    8000463e:	591c                	lw	a5,48(a0)
    80004640:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004642:	854a                	mv	a0,s2
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	654080e7          	jalr	1620(ra) # 80000c98 <release>
}
    8000464c:	60e2                	ld	ra,24(sp)
    8000464e:	6442                	ld	s0,16(sp)
    80004650:	64a2                	ld	s1,8(sp)
    80004652:	6902                	ld	s2,0(sp)
    80004654:	6105                	addi	sp,sp,32
    80004656:	8082                	ret

0000000080004658 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004658:	1101                	addi	sp,sp,-32
    8000465a:	ec06                	sd	ra,24(sp)
    8000465c:	e822                	sd	s0,16(sp)
    8000465e:	e426                	sd	s1,8(sp)
    80004660:	e04a                	sd	s2,0(sp)
    80004662:	1000                	addi	s0,sp,32
    80004664:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004666:	00850913          	addi	s2,a0,8
    8000466a:	854a                	mv	a0,s2
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	578080e7          	jalr	1400(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004674:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004678:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000467c:	8526                	mv	a0,s1
    8000467e:	ffffe097          	auipc	ra,0xffffe
    80004682:	dac080e7          	jalr	-596(ra) # 8000242a <wakeup>
  release(&lk->lk);
    80004686:	854a                	mv	a0,s2
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	610080e7          	jalr	1552(ra) # 80000c98 <release>
}
    80004690:	60e2                	ld	ra,24(sp)
    80004692:	6442                	ld	s0,16(sp)
    80004694:	64a2                	ld	s1,8(sp)
    80004696:	6902                	ld	s2,0(sp)
    80004698:	6105                	addi	sp,sp,32
    8000469a:	8082                	ret

000000008000469c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000469c:	7179                	addi	sp,sp,-48
    8000469e:	f406                	sd	ra,40(sp)
    800046a0:	f022                	sd	s0,32(sp)
    800046a2:	ec26                	sd	s1,24(sp)
    800046a4:	e84a                	sd	s2,16(sp)
    800046a6:	e44e                	sd	s3,8(sp)
    800046a8:	1800                	addi	s0,sp,48
    800046aa:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046ac:	00850913          	addi	s2,a0,8
    800046b0:	854a                	mv	a0,s2
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	532080e7          	jalr	1330(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046ba:	409c                	lw	a5,0(s1)
    800046bc:	ef99                	bnez	a5,800046da <holdingsleep+0x3e>
    800046be:	4481                	li	s1,0
  release(&lk->lk);
    800046c0:	854a                	mv	a0,s2
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	5d6080e7          	jalr	1494(ra) # 80000c98 <release>
  return r;
}
    800046ca:	8526                	mv	a0,s1
    800046cc:	70a2                	ld	ra,40(sp)
    800046ce:	7402                	ld	s0,32(sp)
    800046d0:	64e2                	ld	s1,24(sp)
    800046d2:	6942                	ld	s2,16(sp)
    800046d4:	69a2                	ld	s3,8(sp)
    800046d6:	6145                	addi	sp,sp,48
    800046d8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046da:	0284a983          	lw	s3,40(s1)
    800046de:	ffffd097          	auipc	ra,0xffffd
    800046e2:	2d2080e7          	jalr	722(ra) # 800019b0 <myproc>
    800046e6:	5904                	lw	s1,48(a0)
    800046e8:	413484b3          	sub	s1,s1,s3
    800046ec:	0014b493          	seqz	s1,s1
    800046f0:	bfc1                	j	800046c0 <holdingsleep+0x24>

00000000800046f2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046f2:	1141                	addi	sp,sp,-16
    800046f4:	e406                	sd	ra,8(sp)
    800046f6:	e022                	sd	s0,0(sp)
    800046f8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046fa:	00004597          	auipc	a1,0x4
    800046fe:	11658593          	addi	a1,a1,278 # 80008810 <syscall_names+0x248>
    80004702:	0001d517          	auipc	a0,0x1d
    80004706:	2b650513          	addi	a0,a0,694 # 800219b8 <ftable>
    8000470a:	ffffc097          	auipc	ra,0xffffc
    8000470e:	44a080e7          	jalr	1098(ra) # 80000b54 <initlock>
}
    80004712:	60a2                	ld	ra,8(sp)
    80004714:	6402                	ld	s0,0(sp)
    80004716:	0141                	addi	sp,sp,16
    80004718:	8082                	ret

000000008000471a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000471a:	1101                	addi	sp,sp,-32
    8000471c:	ec06                	sd	ra,24(sp)
    8000471e:	e822                	sd	s0,16(sp)
    80004720:	e426                	sd	s1,8(sp)
    80004722:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004724:	0001d517          	auipc	a0,0x1d
    80004728:	29450513          	addi	a0,a0,660 # 800219b8 <ftable>
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	4b8080e7          	jalr	1208(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004734:	0001d497          	auipc	s1,0x1d
    80004738:	29c48493          	addi	s1,s1,668 # 800219d0 <ftable+0x18>
    8000473c:	0001e717          	auipc	a4,0x1e
    80004740:	23470713          	addi	a4,a4,564 # 80022970 <ftable+0xfb8>
    if(f->ref == 0){
    80004744:	40dc                	lw	a5,4(s1)
    80004746:	cf99                	beqz	a5,80004764 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004748:	02848493          	addi	s1,s1,40
    8000474c:	fee49ce3          	bne	s1,a4,80004744 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004750:	0001d517          	auipc	a0,0x1d
    80004754:	26850513          	addi	a0,a0,616 # 800219b8 <ftable>
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	540080e7          	jalr	1344(ra) # 80000c98 <release>
  return 0;
    80004760:	4481                	li	s1,0
    80004762:	a819                	j	80004778 <filealloc+0x5e>
      f->ref = 1;
    80004764:	4785                	li	a5,1
    80004766:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004768:	0001d517          	auipc	a0,0x1d
    8000476c:	25050513          	addi	a0,a0,592 # 800219b8 <ftable>
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	528080e7          	jalr	1320(ra) # 80000c98 <release>
}
    80004778:	8526                	mv	a0,s1
    8000477a:	60e2                	ld	ra,24(sp)
    8000477c:	6442                	ld	s0,16(sp)
    8000477e:	64a2                	ld	s1,8(sp)
    80004780:	6105                	addi	sp,sp,32
    80004782:	8082                	ret

0000000080004784 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004784:	1101                	addi	sp,sp,-32
    80004786:	ec06                	sd	ra,24(sp)
    80004788:	e822                	sd	s0,16(sp)
    8000478a:	e426                	sd	s1,8(sp)
    8000478c:	1000                	addi	s0,sp,32
    8000478e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004790:	0001d517          	auipc	a0,0x1d
    80004794:	22850513          	addi	a0,a0,552 # 800219b8 <ftable>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	44c080e7          	jalr	1100(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047a0:	40dc                	lw	a5,4(s1)
    800047a2:	02f05263          	blez	a5,800047c6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047a6:	2785                	addiw	a5,a5,1
    800047a8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047aa:	0001d517          	auipc	a0,0x1d
    800047ae:	20e50513          	addi	a0,a0,526 # 800219b8 <ftable>
    800047b2:	ffffc097          	auipc	ra,0xffffc
    800047b6:	4e6080e7          	jalr	1254(ra) # 80000c98 <release>
  return f;
}
    800047ba:	8526                	mv	a0,s1
    800047bc:	60e2                	ld	ra,24(sp)
    800047be:	6442                	ld	s0,16(sp)
    800047c0:	64a2                	ld	s1,8(sp)
    800047c2:	6105                	addi	sp,sp,32
    800047c4:	8082                	ret
    panic("filedup");
    800047c6:	00004517          	auipc	a0,0x4
    800047ca:	05250513          	addi	a0,a0,82 # 80008818 <syscall_names+0x250>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	d70080e7          	jalr	-656(ra) # 8000053e <panic>

00000000800047d6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047d6:	7139                	addi	sp,sp,-64
    800047d8:	fc06                	sd	ra,56(sp)
    800047da:	f822                	sd	s0,48(sp)
    800047dc:	f426                	sd	s1,40(sp)
    800047de:	f04a                	sd	s2,32(sp)
    800047e0:	ec4e                	sd	s3,24(sp)
    800047e2:	e852                	sd	s4,16(sp)
    800047e4:	e456                	sd	s5,8(sp)
    800047e6:	0080                	addi	s0,sp,64
    800047e8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047ea:	0001d517          	auipc	a0,0x1d
    800047ee:	1ce50513          	addi	a0,a0,462 # 800219b8 <ftable>
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	3f2080e7          	jalr	1010(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047fa:	40dc                	lw	a5,4(s1)
    800047fc:	06f05163          	blez	a5,8000485e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004800:	37fd                	addiw	a5,a5,-1
    80004802:	0007871b          	sext.w	a4,a5
    80004806:	c0dc                	sw	a5,4(s1)
    80004808:	06e04363          	bgtz	a4,8000486e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000480c:	0004a903          	lw	s2,0(s1)
    80004810:	0094ca83          	lbu	s5,9(s1)
    80004814:	0104ba03          	ld	s4,16(s1)
    80004818:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000481c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004820:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004824:	0001d517          	auipc	a0,0x1d
    80004828:	19450513          	addi	a0,a0,404 # 800219b8 <ftable>
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	46c080e7          	jalr	1132(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004834:	4785                	li	a5,1
    80004836:	04f90d63          	beq	s2,a5,80004890 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000483a:	3979                	addiw	s2,s2,-2
    8000483c:	4785                	li	a5,1
    8000483e:	0527e063          	bltu	a5,s2,8000487e <fileclose+0xa8>
    begin_op();
    80004842:	00000097          	auipc	ra,0x0
    80004846:	ac8080e7          	jalr	-1336(ra) # 8000430a <begin_op>
    iput(ff.ip);
    8000484a:	854e                	mv	a0,s3
    8000484c:	fffff097          	auipc	ra,0xfffff
    80004850:	2a6080e7          	jalr	678(ra) # 80003af2 <iput>
    end_op();
    80004854:	00000097          	auipc	ra,0x0
    80004858:	b36080e7          	jalr	-1226(ra) # 8000438a <end_op>
    8000485c:	a00d                	j	8000487e <fileclose+0xa8>
    panic("fileclose");
    8000485e:	00004517          	auipc	a0,0x4
    80004862:	fc250513          	addi	a0,a0,-62 # 80008820 <syscall_names+0x258>
    80004866:	ffffc097          	auipc	ra,0xffffc
    8000486a:	cd8080e7          	jalr	-808(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000486e:	0001d517          	auipc	a0,0x1d
    80004872:	14a50513          	addi	a0,a0,330 # 800219b8 <ftable>
    80004876:	ffffc097          	auipc	ra,0xffffc
    8000487a:	422080e7          	jalr	1058(ra) # 80000c98 <release>
  }
}
    8000487e:	70e2                	ld	ra,56(sp)
    80004880:	7442                	ld	s0,48(sp)
    80004882:	74a2                	ld	s1,40(sp)
    80004884:	7902                	ld	s2,32(sp)
    80004886:	69e2                	ld	s3,24(sp)
    80004888:	6a42                	ld	s4,16(sp)
    8000488a:	6aa2                	ld	s5,8(sp)
    8000488c:	6121                	addi	sp,sp,64
    8000488e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004890:	85d6                	mv	a1,s5
    80004892:	8552                	mv	a0,s4
    80004894:	00000097          	auipc	ra,0x0
    80004898:	34c080e7          	jalr	844(ra) # 80004be0 <pipeclose>
    8000489c:	b7cd                	j	8000487e <fileclose+0xa8>

000000008000489e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000489e:	715d                	addi	sp,sp,-80
    800048a0:	e486                	sd	ra,72(sp)
    800048a2:	e0a2                	sd	s0,64(sp)
    800048a4:	fc26                	sd	s1,56(sp)
    800048a6:	f84a                	sd	s2,48(sp)
    800048a8:	f44e                	sd	s3,40(sp)
    800048aa:	0880                	addi	s0,sp,80
    800048ac:	84aa                	mv	s1,a0
    800048ae:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048b0:	ffffd097          	auipc	ra,0xffffd
    800048b4:	100080e7          	jalr	256(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048b8:	409c                	lw	a5,0(s1)
    800048ba:	37f9                	addiw	a5,a5,-2
    800048bc:	4705                	li	a4,1
    800048be:	04f76763          	bltu	a4,a5,8000490c <filestat+0x6e>
    800048c2:	892a                	mv	s2,a0
    ilock(f->ip);
    800048c4:	6c88                	ld	a0,24(s1)
    800048c6:	fffff097          	auipc	ra,0xfffff
    800048ca:	072080e7          	jalr	114(ra) # 80003938 <ilock>
    stati(f->ip, &st);
    800048ce:	fb840593          	addi	a1,s0,-72
    800048d2:	6c88                	ld	a0,24(s1)
    800048d4:	fffff097          	auipc	ra,0xfffff
    800048d8:	2ee080e7          	jalr	750(ra) # 80003bc2 <stati>
    iunlock(f->ip);
    800048dc:	6c88                	ld	a0,24(s1)
    800048de:	fffff097          	auipc	ra,0xfffff
    800048e2:	11c080e7          	jalr	284(ra) # 800039fa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048e6:	46e1                	li	a3,24
    800048e8:	fb840613          	addi	a2,s0,-72
    800048ec:	85ce                	mv	a1,s3
    800048ee:	05093503          	ld	a0,80(s2)
    800048f2:	ffffd097          	auipc	ra,0xffffd
    800048f6:	d80080e7          	jalr	-640(ra) # 80001672 <copyout>
    800048fa:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048fe:	60a6                	ld	ra,72(sp)
    80004900:	6406                	ld	s0,64(sp)
    80004902:	74e2                	ld	s1,56(sp)
    80004904:	7942                	ld	s2,48(sp)
    80004906:	79a2                	ld	s3,40(sp)
    80004908:	6161                	addi	sp,sp,80
    8000490a:	8082                	ret
  return -1;
    8000490c:	557d                	li	a0,-1
    8000490e:	bfc5                	j	800048fe <filestat+0x60>

0000000080004910 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004910:	7179                	addi	sp,sp,-48
    80004912:	f406                	sd	ra,40(sp)
    80004914:	f022                	sd	s0,32(sp)
    80004916:	ec26                	sd	s1,24(sp)
    80004918:	e84a                	sd	s2,16(sp)
    8000491a:	e44e                	sd	s3,8(sp)
    8000491c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000491e:	00854783          	lbu	a5,8(a0)
    80004922:	c3d5                	beqz	a5,800049c6 <fileread+0xb6>
    80004924:	84aa                	mv	s1,a0
    80004926:	89ae                	mv	s3,a1
    80004928:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000492a:	411c                	lw	a5,0(a0)
    8000492c:	4705                	li	a4,1
    8000492e:	04e78963          	beq	a5,a4,80004980 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004932:	470d                	li	a4,3
    80004934:	04e78d63          	beq	a5,a4,8000498e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004938:	4709                	li	a4,2
    8000493a:	06e79e63          	bne	a5,a4,800049b6 <fileread+0xa6>
    ilock(f->ip);
    8000493e:	6d08                	ld	a0,24(a0)
    80004940:	fffff097          	auipc	ra,0xfffff
    80004944:	ff8080e7          	jalr	-8(ra) # 80003938 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004948:	874a                	mv	a4,s2
    8000494a:	5094                	lw	a3,32(s1)
    8000494c:	864e                	mv	a2,s3
    8000494e:	4585                	li	a1,1
    80004950:	6c88                	ld	a0,24(s1)
    80004952:	fffff097          	auipc	ra,0xfffff
    80004956:	29a080e7          	jalr	666(ra) # 80003bec <readi>
    8000495a:	892a                	mv	s2,a0
    8000495c:	00a05563          	blez	a0,80004966 <fileread+0x56>
      f->off += r;
    80004960:	509c                	lw	a5,32(s1)
    80004962:	9fa9                	addw	a5,a5,a0
    80004964:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004966:	6c88                	ld	a0,24(s1)
    80004968:	fffff097          	auipc	ra,0xfffff
    8000496c:	092080e7          	jalr	146(ra) # 800039fa <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004970:	854a                	mv	a0,s2
    80004972:	70a2                	ld	ra,40(sp)
    80004974:	7402                	ld	s0,32(sp)
    80004976:	64e2                	ld	s1,24(sp)
    80004978:	6942                	ld	s2,16(sp)
    8000497a:	69a2                	ld	s3,8(sp)
    8000497c:	6145                	addi	sp,sp,48
    8000497e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004980:	6908                	ld	a0,16(a0)
    80004982:	00000097          	auipc	ra,0x0
    80004986:	3c8080e7          	jalr	968(ra) # 80004d4a <piperead>
    8000498a:	892a                	mv	s2,a0
    8000498c:	b7d5                	j	80004970 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000498e:	02451783          	lh	a5,36(a0)
    80004992:	03079693          	slli	a3,a5,0x30
    80004996:	92c1                	srli	a3,a3,0x30
    80004998:	4725                	li	a4,9
    8000499a:	02d76863          	bltu	a4,a3,800049ca <fileread+0xba>
    8000499e:	0792                	slli	a5,a5,0x4
    800049a0:	0001d717          	auipc	a4,0x1d
    800049a4:	f7870713          	addi	a4,a4,-136 # 80021918 <devsw>
    800049a8:	97ba                	add	a5,a5,a4
    800049aa:	639c                	ld	a5,0(a5)
    800049ac:	c38d                	beqz	a5,800049ce <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049ae:	4505                	li	a0,1
    800049b0:	9782                	jalr	a5
    800049b2:	892a                	mv	s2,a0
    800049b4:	bf75                	j	80004970 <fileread+0x60>
    panic("fileread");
    800049b6:	00004517          	auipc	a0,0x4
    800049ba:	e7a50513          	addi	a0,a0,-390 # 80008830 <syscall_names+0x268>
    800049be:	ffffc097          	auipc	ra,0xffffc
    800049c2:	b80080e7          	jalr	-1152(ra) # 8000053e <panic>
    return -1;
    800049c6:	597d                	li	s2,-1
    800049c8:	b765                	j	80004970 <fileread+0x60>
      return -1;
    800049ca:	597d                	li	s2,-1
    800049cc:	b755                	j	80004970 <fileread+0x60>
    800049ce:	597d                	li	s2,-1
    800049d0:	b745                	j	80004970 <fileread+0x60>

00000000800049d2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049d2:	715d                	addi	sp,sp,-80
    800049d4:	e486                	sd	ra,72(sp)
    800049d6:	e0a2                	sd	s0,64(sp)
    800049d8:	fc26                	sd	s1,56(sp)
    800049da:	f84a                	sd	s2,48(sp)
    800049dc:	f44e                	sd	s3,40(sp)
    800049de:	f052                	sd	s4,32(sp)
    800049e0:	ec56                	sd	s5,24(sp)
    800049e2:	e85a                	sd	s6,16(sp)
    800049e4:	e45e                	sd	s7,8(sp)
    800049e6:	e062                	sd	s8,0(sp)
    800049e8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049ea:	00954783          	lbu	a5,9(a0)
    800049ee:	10078663          	beqz	a5,80004afa <filewrite+0x128>
    800049f2:	892a                	mv	s2,a0
    800049f4:	8aae                	mv	s5,a1
    800049f6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049f8:	411c                	lw	a5,0(a0)
    800049fa:	4705                	li	a4,1
    800049fc:	02e78263          	beq	a5,a4,80004a20 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a00:	470d                	li	a4,3
    80004a02:	02e78663          	beq	a5,a4,80004a2e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a06:	4709                	li	a4,2
    80004a08:	0ee79163          	bne	a5,a4,80004aea <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a0c:	0ac05d63          	blez	a2,80004ac6 <filewrite+0xf4>
    int i = 0;
    80004a10:	4981                	li	s3,0
    80004a12:	6b05                	lui	s6,0x1
    80004a14:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a18:	6b85                	lui	s7,0x1
    80004a1a:	c00b8b9b          	addiw	s7,s7,-1024
    80004a1e:	a861                	j	80004ab6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a20:	6908                	ld	a0,16(a0)
    80004a22:	00000097          	auipc	ra,0x0
    80004a26:	22e080e7          	jalr	558(ra) # 80004c50 <pipewrite>
    80004a2a:	8a2a                	mv	s4,a0
    80004a2c:	a045                	j	80004acc <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a2e:	02451783          	lh	a5,36(a0)
    80004a32:	03079693          	slli	a3,a5,0x30
    80004a36:	92c1                	srli	a3,a3,0x30
    80004a38:	4725                	li	a4,9
    80004a3a:	0cd76263          	bltu	a4,a3,80004afe <filewrite+0x12c>
    80004a3e:	0792                	slli	a5,a5,0x4
    80004a40:	0001d717          	auipc	a4,0x1d
    80004a44:	ed870713          	addi	a4,a4,-296 # 80021918 <devsw>
    80004a48:	97ba                	add	a5,a5,a4
    80004a4a:	679c                	ld	a5,8(a5)
    80004a4c:	cbdd                	beqz	a5,80004b02 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a4e:	4505                	li	a0,1
    80004a50:	9782                	jalr	a5
    80004a52:	8a2a                	mv	s4,a0
    80004a54:	a8a5                	j	80004acc <filewrite+0xfa>
    80004a56:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a5a:	00000097          	auipc	ra,0x0
    80004a5e:	8b0080e7          	jalr	-1872(ra) # 8000430a <begin_op>
      ilock(f->ip);
    80004a62:	01893503          	ld	a0,24(s2)
    80004a66:	fffff097          	auipc	ra,0xfffff
    80004a6a:	ed2080e7          	jalr	-302(ra) # 80003938 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a6e:	8762                	mv	a4,s8
    80004a70:	02092683          	lw	a3,32(s2)
    80004a74:	01598633          	add	a2,s3,s5
    80004a78:	4585                	li	a1,1
    80004a7a:	01893503          	ld	a0,24(s2)
    80004a7e:	fffff097          	auipc	ra,0xfffff
    80004a82:	266080e7          	jalr	614(ra) # 80003ce4 <writei>
    80004a86:	84aa                	mv	s1,a0
    80004a88:	00a05763          	blez	a0,80004a96 <filewrite+0xc4>
        f->off += r;
    80004a8c:	02092783          	lw	a5,32(s2)
    80004a90:	9fa9                	addw	a5,a5,a0
    80004a92:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a96:	01893503          	ld	a0,24(s2)
    80004a9a:	fffff097          	auipc	ra,0xfffff
    80004a9e:	f60080e7          	jalr	-160(ra) # 800039fa <iunlock>
      end_op();
    80004aa2:	00000097          	auipc	ra,0x0
    80004aa6:	8e8080e7          	jalr	-1816(ra) # 8000438a <end_op>

      if(r != n1){
    80004aaa:	009c1f63          	bne	s8,s1,80004ac8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004aae:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ab2:	0149db63          	bge	s3,s4,80004ac8 <filewrite+0xf6>
      int n1 = n - i;
    80004ab6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004aba:	84be                	mv	s1,a5
    80004abc:	2781                	sext.w	a5,a5
    80004abe:	f8fb5ce3          	bge	s6,a5,80004a56 <filewrite+0x84>
    80004ac2:	84de                	mv	s1,s7
    80004ac4:	bf49                	j	80004a56 <filewrite+0x84>
    int i = 0;
    80004ac6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ac8:	013a1f63          	bne	s4,s3,80004ae6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004acc:	8552                	mv	a0,s4
    80004ace:	60a6                	ld	ra,72(sp)
    80004ad0:	6406                	ld	s0,64(sp)
    80004ad2:	74e2                	ld	s1,56(sp)
    80004ad4:	7942                	ld	s2,48(sp)
    80004ad6:	79a2                	ld	s3,40(sp)
    80004ad8:	7a02                	ld	s4,32(sp)
    80004ada:	6ae2                	ld	s5,24(sp)
    80004adc:	6b42                	ld	s6,16(sp)
    80004ade:	6ba2                	ld	s7,8(sp)
    80004ae0:	6c02                	ld	s8,0(sp)
    80004ae2:	6161                	addi	sp,sp,80
    80004ae4:	8082                	ret
    ret = (i == n ? n : -1);
    80004ae6:	5a7d                	li	s4,-1
    80004ae8:	b7d5                	j	80004acc <filewrite+0xfa>
    panic("filewrite");
    80004aea:	00004517          	auipc	a0,0x4
    80004aee:	d5650513          	addi	a0,a0,-682 # 80008840 <syscall_names+0x278>
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	a4c080e7          	jalr	-1460(ra) # 8000053e <panic>
    return -1;
    80004afa:	5a7d                	li	s4,-1
    80004afc:	bfc1                	j	80004acc <filewrite+0xfa>
      return -1;
    80004afe:	5a7d                	li	s4,-1
    80004b00:	b7f1                	j	80004acc <filewrite+0xfa>
    80004b02:	5a7d                	li	s4,-1
    80004b04:	b7e1                	j	80004acc <filewrite+0xfa>

0000000080004b06 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b06:	7179                	addi	sp,sp,-48
    80004b08:	f406                	sd	ra,40(sp)
    80004b0a:	f022                	sd	s0,32(sp)
    80004b0c:	ec26                	sd	s1,24(sp)
    80004b0e:	e84a                	sd	s2,16(sp)
    80004b10:	e44e                	sd	s3,8(sp)
    80004b12:	e052                	sd	s4,0(sp)
    80004b14:	1800                	addi	s0,sp,48
    80004b16:	84aa                	mv	s1,a0
    80004b18:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b1a:	0005b023          	sd	zero,0(a1)
    80004b1e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b22:	00000097          	auipc	ra,0x0
    80004b26:	bf8080e7          	jalr	-1032(ra) # 8000471a <filealloc>
    80004b2a:	e088                	sd	a0,0(s1)
    80004b2c:	c551                	beqz	a0,80004bb8 <pipealloc+0xb2>
    80004b2e:	00000097          	auipc	ra,0x0
    80004b32:	bec080e7          	jalr	-1044(ra) # 8000471a <filealloc>
    80004b36:	00aa3023          	sd	a0,0(s4)
    80004b3a:	c92d                	beqz	a0,80004bac <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	fb8080e7          	jalr	-72(ra) # 80000af4 <kalloc>
    80004b44:	892a                	mv	s2,a0
    80004b46:	c125                	beqz	a0,80004ba6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b48:	4985                	li	s3,1
    80004b4a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b4e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b52:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b56:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b5a:	00004597          	auipc	a1,0x4
    80004b5e:	90658593          	addi	a1,a1,-1786 # 80008460 <states.1743+0x1a0>
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	ff2080e7          	jalr	-14(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004b6a:	609c                	ld	a5,0(s1)
    80004b6c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b70:	609c                	ld	a5,0(s1)
    80004b72:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b76:	609c                	ld	a5,0(s1)
    80004b78:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b7c:	609c                	ld	a5,0(s1)
    80004b7e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b82:	000a3783          	ld	a5,0(s4)
    80004b86:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b8a:	000a3783          	ld	a5,0(s4)
    80004b8e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b92:	000a3783          	ld	a5,0(s4)
    80004b96:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b9a:	000a3783          	ld	a5,0(s4)
    80004b9e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ba2:	4501                	li	a0,0
    80004ba4:	a025                	j	80004bcc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ba6:	6088                	ld	a0,0(s1)
    80004ba8:	e501                	bnez	a0,80004bb0 <pipealloc+0xaa>
    80004baa:	a039                	j	80004bb8 <pipealloc+0xb2>
    80004bac:	6088                	ld	a0,0(s1)
    80004bae:	c51d                	beqz	a0,80004bdc <pipealloc+0xd6>
    fileclose(*f0);
    80004bb0:	00000097          	auipc	ra,0x0
    80004bb4:	c26080e7          	jalr	-986(ra) # 800047d6 <fileclose>
  if(*f1)
    80004bb8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bbc:	557d                	li	a0,-1
  if(*f1)
    80004bbe:	c799                	beqz	a5,80004bcc <pipealloc+0xc6>
    fileclose(*f1);
    80004bc0:	853e                	mv	a0,a5
    80004bc2:	00000097          	auipc	ra,0x0
    80004bc6:	c14080e7          	jalr	-1004(ra) # 800047d6 <fileclose>
  return -1;
    80004bca:	557d                	li	a0,-1
}
    80004bcc:	70a2                	ld	ra,40(sp)
    80004bce:	7402                	ld	s0,32(sp)
    80004bd0:	64e2                	ld	s1,24(sp)
    80004bd2:	6942                	ld	s2,16(sp)
    80004bd4:	69a2                	ld	s3,8(sp)
    80004bd6:	6a02                	ld	s4,0(sp)
    80004bd8:	6145                	addi	sp,sp,48
    80004bda:	8082                	ret
  return -1;
    80004bdc:	557d                	li	a0,-1
    80004bde:	b7fd                	j	80004bcc <pipealloc+0xc6>

0000000080004be0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004be0:	1101                	addi	sp,sp,-32
    80004be2:	ec06                	sd	ra,24(sp)
    80004be4:	e822                	sd	s0,16(sp)
    80004be6:	e426                	sd	s1,8(sp)
    80004be8:	e04a                	sd	s2,0(sp)
    80004bea:	1000                	addi	s0,sp,32
    80004bec:	84aa                	mv	s1,a0
    80004bee:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bf0:	ffffc097          	auipc	ra,0xffffc
    80004bf4:	ff4080e7          	jalr	-12(ra) # 80000be4 <acquire>
  if(writable){
    80004bf8:	02090d63          	beqz	s2,80004c32 <pipeclose+0x52>
    pi->writeopen = 0;
    80004bfc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c00:	21848513          	addi	a0,s1,536
    80004c04:	ffffe097          	auipc	ra,0xffffe
    80004c08:	826080e7          	jalr	-2010(ra) # 8000242a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c0c:	2204b783          	ld	a5,544(s1)
    80004c10:	eb95                	bnez	a5,80004c44 <pipeclose+0x64>
    release(&pi->lock);
    80004c12:	8526                	mv	a0,s1
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	084080e7          	jalr	132(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004c1c:	8526                	mv	a0,s1
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	dda080e7          	jalr	-550(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004c26:	60e2                	ld	ra,24(sp)
    80004c28:	6442                	ld	s0,16(sp)
    80004c2a:	64a2                	ld	s1,8(sp)
    80004c2c:	6902                	ld	s2,0(sp)
    80004c2e:	6105                	addi	sp,sp,32
    80004c30:	8082                	ret
    pi->readopen = 0;
    80004c32:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c36:	21c48513          	addi	a0,s1,540
    80004c3a:	ffffd097          	auipc	ra,0xffffd
    80004c3e:	7f0080e7          	jalr	2032(ra) # 8000242a <wakeup>
    80004c42:	b7e9                	j	80004c0c <pipeclose+0x2c>
    release(&pi->lock);
    80004c44:	8526                	mv	a0,s1
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	052080e7          	jalr	82(ra) # 80000c98 <release>
}
    80004c4e:	bfe1                	j	80004c26 <pipeclose+0x46>

0000000080004c50 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c50:	7159                	addi	sp,sp,-112
    80004c52:	f486                	sd	ra,104(sp)
    80004c54:	f0a2                	sd	s0,96(sp)
    80004c56:	eca6                	sd	s1,88(sp)
    80004c58:	e8ca                	sd	s2,80(sp)
    80004c5a:	e4ce                	sd	s3,72(sp)
    80004c5c:	e0d2                	sd	s4,64(sp)
    80004c5e:	fc56                	sd	s5,56(sp)
    80004c60:	f85a                	sd	s6,48(sp)
    80004c62:	f45e                	sd	s7,40(sp)
    80004c64:	f062                	sd	s8,32(sp)
    80004c66:	ec66                	sd	s9,24(sp)
    80004c68:	1880                	addi	s0,sp,112
    80004c6a:	84aa                	mv	s1,a0
    80004c6c:	8aae                	mv	s5,a1
    80004c6e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c70:	ffffd097          	auipc	ra,0xffffd
    80004c74:	d40080e7          	jalr	-704(ra) # 800019b0 <myproc>
    80004c78:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c7a:	8526                	mv	a0,s1
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	f68080e7          	jalr	-152(ra) # 80000be4 <acquire>
  while(i < n){
    80004c84:	0d405163          	blez	s4,80004d46 <pipewrite+0xf6>
    80004c88:	8ba6                	mv	s7,s1
  int i = 0;
    80004c8a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c8c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c8e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c92:	21c48c13          	addi	s8,s1,540
    80004c96:	a08d                	j	80004cf8 <pipewrite+0xa8>
      release(&pi->lock);
    80004c98:	8526                	mv	a0,s1
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	ffe080e7          	jalr	-2(ra) # 80000c98 <release>
      return -1;
    80004ca2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ca4:	854a                	mv	a0,s2
    80004ca6:	70a6                	ld	ra,104(sp)
    80004ca8:	7406                	ld	s0,96(sp)
    80004caa:	64e6                	ld	s1,88(sp)
    80004cac:	6946                	ld	s2,80(sp)
    80004cae:	69a6                	ld	s3,72(sp)
    80004cb0:	6a06                	ld	s4,64(sp)
    80004cb2:	7ae2                	ld	s5,56(sp)
    80004cb4:	7b42                	ld	s6,48(sp)
    80004cb6:	7ba2                	ld	s7,40(sp)
    80004cb8:	7c02                	ld	s8,32(sp)
    80004cba:	6ce2                	ld	s9,24(sp)
    80004cbc:	6165                	addi	sp,sp,112
    80004cbe:	8082                	ret
      wakeup(&pi->nread);
    80004cc0:	8566                	mv	a0,s9
    80004cc2:	ffffd097          	auipc	ra,0xffffd
    80004cc6:	768080e7          	jalr	1896(ra) # 8000242a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cca:	85de                	mv	a1,s7
    80004ccc:	8562                	mv	a0,s8
    80004cce:	ffffd097          	auipc	ra,0xffffd
    80004cd2:	484080e7          	jalr	1156(ra) # 80002152 <sleep>
    80004cd6:	a839                	j	80004cf4 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cd8:	21c4a783          	lw	a5,540(s1)
    80004cdc:	0017871b          	addiw	a4,a5,1
    80004ce0:	20e4ae23          	sw	a4,540(s1)
    80004ce4:	1ff7f793          	andi	a5,a5,511
    80004ce8:	97a6                	add	a5,a5,s1
    80004cea:	f9f44703          	lbu	a4,-97(s0)
    80004cee:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cf2:	2905                	addiw	s2,s2,1
  while(i < n){
    80004cf4:	03495d63          	bge	s2,s4,80004d2e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004cf8:	2204a783          	lw	a5,544(s1)
    80004cfc:	dfd1                	beqz	a5,80004c98 <pipewrite+0x48>
    80004cfe:	0289a783          	lw	a5,40(s3)
    80004d02:	fbd9                	bnez	a5,80004c98 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d04:	2184a783          	lw	a5,536(s1)
    80004d08:	21c4a703          	lw	a4,540(s1)
    80004d0c:	2007879b          	addiw	a5,a5,512
    80004d10:	faf708e3          	beq	a4,a5,80004cc0 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d14:	4685                	li	a3,1
    80004d16:	01590633          	add	a2,s2,s5
    80004d1a:	f9f40593          	addi	a1,s0,-97
    80004d1e:	0509b503          	ld	a0,80(s3)
    80004d22:	ffffd097          	auipc	ra,0xffffd
    80004d26:	9dc080e7          	jalr	-1572(ra) # 800016fe <copyin>
    80004d2a:	fb6517e3          	bne	a0,s6,80004cd8 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d2e:	21848513          	addi	a0,s1,536
    80004d32:	ffffd097          	auipc	ra,0xffffd
    80004d36:	6f8080e7          	jalr	1784(ra) # 8000242a <wakeup>
  release(&pi->lock);
    80004d3a:	8526                	mv	a0,s1
    80004d3c:	ffffc097          	auipc	ra,0xffffc
    80004d40:	f5c080e7          	jalr	-164(ra) # 80000c98 <release>
  return i;
    80004d44:	b785                	j	80004ca4 <pipewrite+0x54>
  int i = 0;
    80004d46:	4901                	li	s2,0
    80004d48:	b7dd                	j	80004d2e <pipewrite+0xde>

0000000080004d4a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d4a:	715d                	addi	sp,sp,-80
    80004d4c:	e486                	sd	ra,72(sp)
    80004d4e:	e0a2                	sd	s0,64(sp)
    80004d50:	fc26                	sd	s1,56(sp)
    80004d52:	f84a                	sd	s2,48(sp)
    80004d54:	f44e                	sd	s3,40(sp)
    80004d56:	f052                	sd	s4,32(sp)
    80004d58:	ec56                	sd	s5,24(sp)
    80004d5a:	e85a                	sd	s6,16(sp)
    80004d5c:	0880                	addi	s0,sp,80
    80004d5e:	84aa                	mv	s1,a0
    80004d60:	892e                	mv	s2,a1
    80004d62:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d64:	ffffd097          	auipc	ra,0xffffd
    80004d68:	c4c080e7          	jalr	-948(ra) # 800019b0 <myproc>
    80004d6c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d6e:	8b26                	mv	s6,s1
    80004d70:	8526                	mv	a0,s1
    80004d72:	ffffc097          	auipc	ra,0xffffc
    80004d76:	e72080e7          	jalr	-398(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d7a:	2184a703          	lw	a4,536(s1)
    80004d7e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d82:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d86:	02f71463          	bne	a4,a5,80004dae <piperead+0x64>
    80004d8a:	2244a783          	lw	a5,548(s1)
    80004d8e:	c385                	beqz	a5,80004dae <piperead+0x64>
    if(pr->killed){
    80004d90:	028a2783          	lw	a5,40(s4)
    80004d94:	ebc1                	bnez	a5,80004e24 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d96:	85da                	mv	a1,s6
    80004d98:	854e                	mv	a0,s3
    80004d9a:	ffffd097          	auipc	ra,0xffffd
    80004d9e:	3b8080e7          	jalr	952(ra) # 80002152 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004da2:	2184a703          	lw	a4,536(s1)
    80004da6:	21c4a783          	lw	a5,540(s1)
    80004daa:	fef700e3          	beq	a4,a5,80004d8a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dae:	09505263          	blez	s5,80004e32 <piperead+0xe8>
    80004db2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004db4:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004db6:	2184a783          	lw	a5,536(s1)
    80004dba:	21c4a703          	lw	a4,540(s1)
    80004dbe:	02f70d63          	beq	a4,a5,80004df8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dc2:	0017871b          	addiw	a4,a5,1
    80004dc6:	20e4ac23          	sw	a4,536(s1)
    80004dca:	1ff7f793          	andi	a5,a5,511
    80004dce:	97a6                	add	a5,a5,s1
    80004dd0:	0187c783          	lbu	a5,24(a5)
    80004dd4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dd8:	4685                	li	a3,1
    80004dda:	fbf40613          	addi	a2,s0,-65
    80004dde:	85ca                	mv	a1,s2
    80004de0:	050a3503          	ld	a0,80(s4)
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	88e080e7          	jalr	-1906(ra) # 80001672 <copyout>
    80004dec:	01650663          	beq	a0,s6,80004df8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004df0:	2985                	addiw	s3,s3,1
    80004df2:	0905                	addi	s2,s2,1
    80004df4:	fd3a91e3          	bne	s5,s3,80004db6 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004df8:	21c48513          	addi	a0,s1,540
    80004dfc:	ffffd097          	auipc	ra,0xffffd
    80004e00:	62e080e7          	jalr	1582(ra) # 8000242a <wakeup>
  release(&pi->lock);
    80004e04:	8526                	mv	a0,s1
    80004e06:	ffffc097          	auipc	ra,0xffffc
    80004e0a:	e92080e7          	jalr	-366(ra) # 80000c98 <release>
  return i;
}
    80004e0e:	854e                	mv	a0,s3
    80004e10:	60a6                	ld	ra,72(sp)
    80004e12:	6406                	ld	s0,64(sp)
    80004e14:	74e2                	ld	s1,56(sp)
    80004e16:	7942                	ld	s2,48(sp)
    80004e18:	79a2                	ld	s3,40(sp)
    80004e1a:	7a02                	ld	s4,32(sp)
    80004e1c:	6ae2                	ld	s5,24(sp)
    80004e1e:	6b42                	ld	s6,16(sp)
    80004e20:	6161                	addi	sp,sp,80
    80004e22:	8082                	ret
      release(&pi->lock);
    80004e24:	8526                	mv	a0,s1
    80004e26:	ffffc097          	auipc	ra,0xffffc
    80004e2a:	e72080e7          	jalr	-398(ra) # 80000c98 <release>
      return -1;
    80004e2e:	59fd                	li	s3,-1
    80004e30:	bff9                	j	80004e0e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e32:	4981                	li	s3,0
    80004e34:	b7d1                	j	80004df8 <piperead+0xae>

0000000080004e36 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e36:	df010113          	addi	sp,sp,-528
    80004e3a:	20113423          	sd	ra,520(sp)
    80004e3e:	20813023          	sd	s0,512(sp)
    80004e42:	ffa6                	sd	s1,504(sp)
    80004e44:	fbca                	sd	s2,496(sp)
    80004e46:	f7ce                	sd	s3,488(sp)
    80004e48:	f3d2                	sd	s4,480(sp)
    80004e4a:	efd6                	sd	s5,472(sp)
    80004e4c:	ebda                	sd	s6,464(sp)
    80004e4e:	e7de                	sd	s7,456(sp)
    80004e50:	e3e2                	sd	s8,448(sp)
    80004e52:	ff66                	sd	s9,440(sp)
    80004e54:	fb6a                	sd	s10,432(sp)
    80004e56:	f76e                	sd	s11,424(sp)
    80004e58:	0c00                	addi	s0,sp,528
    80004e5a:	84aa                	mv	s1,a0
    80004e5c:	dea43c23          	sd	a0,-520(s0)
    80004e60:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e64:	ffffd097          	auipc	ra,0xffffd
    80004e68:	b4c080e7          	jalr	-1204(ra) # 800019b0 <myproc>
    80004e6c:	892a                	mv	s2,a0

  begin_op();
    80004e6e:	fffff097          	auipc	ra,0xfffff
    80004e72:	49c080e7          	jalr	1180(ra) # 8000430a <begin_op>

  if((ip = namei(path)) == 0){
    80004e76:	8526                	mv	a0,s1
    80004e78:	fffff097          	auipc	ra,0xfffff
    80004e7c:	276080e7          	jalr	630(ra) # 800040ee <namei>
    80004e80:	c92d                	beqz	a0,80004ef2 <exec+0xbc>
    80004e82:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e84:	fffff097          	auipc	ra,0xfffff
    80004e88:	ab4080e7          	jalr	-1356(ra) # 80003938 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e8c:	04000713          	li	a4,64
    80004e90:	4681                	li	a3,0
    80004e92:	e5040613          	addi	a2,s0,-432
    80004e96:	4581                	li	a1,0
    80004e98:	8526                	mv	a0,s1
    80004e9a:	fffff097          	auipc	ra,0xfffff
    80004e9e:	d52080e7          	jalr	-686(ra) # 80003bec <readi>
    80004ea2:	04000793          	li	a5,64
    80004ea6:	00f51a63          	bne	a0,a5,80004eba <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004eaa:	e5042703          	lw	a4,-432(s0)
    80004eae:	464c47b7          	lui	a5,0x464c4
    80004eb2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004eb6:	04f70463          	beq	a4,a5,80004efe <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004eba:	8526                	mv	a0,s1
    80004ebc:	fffff097          	auipc	ra,0xfffff
    80004ec0:	cde080e7          	jalr	-802(ra) # 80003b9a <iunlockput>
    end_op();
    80004ec4:	fffff097          	auipc	ra,0xfffff
    80004ec8:	4c6080e7          	jalr	1222(ra) # 8000438a <end_op>
  }
  return -1;
    80004ecc:	557d                	li	a0,-1
}
    80004ece:	20813083          	ld	ra,520(sp)
    80004ed2:	20013403          	ld	s0,512(sp)
    80004ed6:	74fe                	ld	s1,504(sp)
    80004ed8:	795e                	ld	s2,496(sp)
    80004eda:	79be                	ld	s3,488(sp)
    80004edc:	7a1e                	ld	s4,480(sp)
    80004ede:	6afe                	ld	s5,472(sp)
    80004ee0:	6b5e                	ld	s6,464(sp)
    80004ee2:	6bbe                	ld	s7,456(sp)
    80004ee4:	6c1e                	ld	s8,448(sp)
    80004ee6:	7cfa                	ld	s9,440(sp)
    80004ee8:	7d5a                	ld	s10,432(sp)
    80004eea:	7dba                	ld	s11,424(sp)
    80004eec:	21010113          	addi	sp,sp,528
    80004ef0:	8082                	ret
    end_op();
    80004ef2:	fffff097          	auipc	ra,0xfffff
    80004ef6:	498080e7          	jalr	1176(ra) # 8000438a <end_op>
    return -1;
    80004efa:	557d                	li	a0,-1
    80004efc:	bfc9                	j	80004ece <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004efe:	854a                	mv	a0,s2
    80004f00:	ffffd097          	auipc	ra,0xffffd
    80004f04:	b74080e7          	jalr	-1164(ra) # 80001a74 <proc_pagetable>
    80004f08:	8baa                	mv	s7,a0
    80004f0a:	d945                	beqz	a0,80004eba <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f0c:	e7042983          	lw	s3,-400(s0)
    80004f10:	e8845783          	lhu	a5,-376(s0)
    80004f14:	c7ad                	beqz	a5,80004f7e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f16:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f18:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004f1a:	6c85                	lui	s9,0x1
    80004f1c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f20:	def43823          	sd	a5,-528(s0)
    80004f24:	a42d                	j	8000514e <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f26:	00004517          	auipc	a0,0x4
    80004f2a:	92a50513          	addi	a0,a0,-1750 # 80008850 <syscall_names+0x288>
    80004f2e:	ffffb097          	auipc	ra,0xffffb
    80004f32:	610080e7          	jalr	1552(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f36:	8756                	mv	a4,s5
    80004f38:	012d86bb          	addw	a3,s11,s2
    80004f3c:	4581                	li	a1,0
    80004f3e:	8526                	mv	a0,s1
    80004f40:	fffff097          	auipc	ra,0xfffff
    80004f44:	cac080e7          	jalr	-852(ra) # 80003bec <readi>
    80004f48:	2501                	sext.w	a0,a0
    80004f4a:	1aaa9963          	bne	s5,a0,800050fc <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f4e:	6785                	lui	a5,0x1
    80004f50:	0127893b          	addw	s2,a5,s2
    80004f54:	77fd                	lui	a5,0xfffff
    80004f56:	01478a3b          	addw	s4,a5,s4
    80004f5a:	1f897163          	bgeu	s2,s8,8000513c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f5e:	02091593          	slli	a1,s2,0x20
    80004f62:	9181                	srli	a1,a1,0x20
    80004f64:	95ea                	add	a1,a1,s10
    80004f66:	855e                	mv	a0,s7
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	106080e7          	jalr	262(ra) # 8000106e <walkaddr>
    80004f70:	862a                	mv	a2,a0
    if(pa == 0)
    80004f72:	d955                	beqz	a0,80004f26 <exec+0xf0>
      n = PGSIZE;
    80004f74:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f76:	fd9a70e3          	bgeu	s4,s9,80004f36 <exec+0x100>
      n = sz - i;
    80004f7a:	8ad2                	mv	s5,s4
    80004f7c:	bf6d                	j	80004f36 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f7e:	4901                	li	s2,0
  iunlockput(ip);
    80004f80:	8526                	mv	a0,s1
    80004f82:	fffff097          	auipc	ra,0xfffff
    80004f86:	c18080e7          	jalr	-1000(ra) # 80003b9a <iunlockput>
  end_op();
    80004f8a:	fffff097          	auipc	ra,0xfffff
    80004f8e:	400080e7          	jalr	1024(ra) # 8000438a <end_op>
  p = myproc();
    80004f92:	ffffd097          	auipc	ra,0xffffd
    80004f96:	a1e080e7          	jalr	-1506(ra) # 800019b0 <myproc>
    80004f9a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f9c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004fa0:	6785                	lui	a5,0x1
    80004fa2:	17fd                	addi	a5,a5,-1
    80004fa4:	993e                	add	s2,s2,a5
    80004fa6:	757d                	lui	a0,0xfffff
    80004fa8:	00a977b3          	and	a5,s2,a0
    80004fac:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fb0:	6609                	lui	a2,0x2
    80004fb2:	963e                	add	a2,a2,a5
    80004fb4:	85be                	mv	a1,a5
    80004fb6:	855e                	mv	a0,s7
    80004fb8:	ffffc097          	auipc	ra,0xffffc
    80004fbc:	46a080e7          	jalr	1130(ra) # 80001422 <uvmalloc>
    80004fc0:	8b2a                	mv	s6,a0
  ip = 0;
    80004fc2:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fc4:	12050c63          	beqz	a0,800050fc <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fc8:	75f9                	lui	a1,0xffffe
    80004fca:	95aa                	add	a1,a1,a0
    80004fcc:	855e                	mv	a0,s7
    80004fce:	ffffc097          	auipc	ra,0xffffc
    80004fd2:	672080e7          	jalr	1650(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fd6:	7c7d                	lui	s8,0xfffff
    80004fd8:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fda:	e0043783          	ld	a5,-512(s0)
    80004fde:	6388                	ld	a0,0(a5)
    80004fe0:	c535                	beqz	a0,8000504c <exec+0x216>
    80004fe2:	e9040993          	addi	s3,s0,-368
    80004fe6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004fea:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	e78080e7          	jalr	-392(ra) # 80000e64 <strlen>
    80004ff4:	2505                	addiw	a0,a0,1
    80004ff6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ffa:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ffe:	13896363          	bltu	s2,s8,80005124 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005002:	e0043d83          	ld	s11,-512(s0)
    80005006:	000dba03          	ld	s4,0(s11)
    8000500a:	8552                	mv	a0,s4
    8000500c:	ffffc097          	auipc	ra,0xffffc
    80005010:	e58080e7          	jalr	-424(ra) # 80000e64 <strlen>
    80005014:	0015069b          	addiw	a3,a0,1
    80005018:	8652                	mv	a2,s4
    8000501a:	85ca                	mv	a1,s2
    8000501c:	855e                	mv	a0,s7
    8000501e:	ffffc097          	auipc	ra,0xffffc
    80005022:	654080e7          	jalr	1620(ra) # 80001672 <copyout>
    80005026:	10054363          	bltz	a0,8000512c <exec+0x2f6>
    ustack[argc] = sp;
    8000502a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000502e:	0485                	addi	s1,s1,1
    80005030:	008d8793          	addi	a5,s11,8
    80005034:	e0f43023          	sd	a5,-512(s0)
    80005038:	008db503          	ld	a0,8(s11)
    8000503c:	c911                	beqz	a0,80005050 <exec+0x21a>
    if(argc >= MAXARG)
    8000503e:	09a1                	addi	s3,s3,8
    80005040:	fb3c96e3          	bne	s9,s3,80004fec <exec+0x1b6>
  sz = sz1;
    80005044:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005048:	4481                	li	s1,0
    8000504a:	a84d                	j	800050fc <exec+0x2c6>
  sp = sz;
    8000504c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000504e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005050:	00349793          	slli	a5,s1,0x3
    80005054:	f9040713          	addi	a4,s0,-112
    80005058:	97ba                	add	a5,a5,a4
    8000505a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000505e:	00148693          	addi	a3,s1,1
    80005062:	068e                	slli	a3,a3,0x3
    80005064:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005068:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000506c:	01897663          	bgeu	s2,s8,80005078 <exec+0x242>
  sz = sz1;
    80005070:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005074:	4481                	li	s1,0
    80005076:	a059                	j	800050fc <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005078:	e9040613          	addi	a2,s0,-368
    8000507c:	85ca                	mv	a1,s2
    8000507e:	855e                	mv	a0,s7
    80005080:	ffffc097          	auipc	ra,0xffffc
    80005084:	5f2080e7          	jalr	1522(ra) # 80001672 <copyout>
    80005088:	0a054663          	bltz	a0,80005134 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000508c:	058ab783          	ld	a5,88(s5)
    80005090:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005094:	df843783          	ld	a5,-520(s0)
    80005098:	0007c703          	lbu	a4,0(a5)
    8000509c:	cf11                	beqz	a4,800050b8 <exec+0x282>
    8000509e:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050a0:	02f00693          	li	a3,47
    800050a4:	a039                	j	800050b2 <exec+0x27c>
      last = s+1;
    800050a6:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050aa:	0785                	addi	a5,a5,1
    800050ac:	fff7c703          	lbu	a4,-1(a5)
    800050b0:	c701                	beqz	a4,800050b8 <exec+0x282>
    if(*s == '/')
    800050b2:	fed71ce3          	bne	a4,a3,800050aa <exec+0x274>
    800050b6:	bfc5                	j	800050a6 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800050b8:	4641                	li	a2,16
    800050ba:	df843583          	ld	a1,-520(s0)
    800050be:	158a8513          	addi	a0,s5,344
    800050c2:	ffffc097          	auipc	ra,0xffffc
    800050c6:	d70080e7          	jalr	-656(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800050ca:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800050ce:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800050d2:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050d6:	058ab783          	ld	a5,88(s5)
    800050da:	e6843703          	ld	a4,-408(s0)
    800050de:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050e0:	058ab783          	ld	a5,88(s5)
    800050e4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050e8:	85ea                	mv	a1,s10
    800050ea:	ffffd097          	auipc	ra,0xffffd
    800050ee:	a26080e7          	jalr	-1498(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050f2:	0004851b          	sext.w	a0,s1
    800050f6:	bbe1                	j	80004ece <exec+0x98>
    800050f8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800050fc:	e0843583          	ld	a1,-504(s0)
    80005100:	855e                	mv	a0,s7
    80005102:	ffffd097          	auipc	ra,0xffffd
    80005106:	a0e080e7          	jalr	-1522(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    8000510a:	da0498e3          	bnez	s1,80004eba <exec+0x84>
  return -1;
    8000510e:	557d                	li	a0,-1
    80005110:	bb7d                	j	80004ece <exec+0x98>
    80005112:	e1243423          	sd	s2,-504(s0)
    80005116:	b7dd                	j	800050fc <exec+0x2c6>
    80005118:	e1243423          	sd	s2,-504(s0)
    8000511c:	b7c5                	j	800050fc <exec+0x2c6>
    8000511e:	e1243423          	sd	s2,-504(s0)
    80005122:	bfe9                	j	800050fc <exec+0x2c6>
  sz = sz1;
    80005124:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005128:	4481                	li	s1,0
    8000512a:	bfc9                	j	800050fc <exec+0x2c6>
  sz = sz1;
    8000512c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005130:	4481                	li	s1,0
    80005132:	b7e9                	j	800050fc <exec+0x2c6>
  sz = sz1;
    80005134:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005138:	4481                	li	s1,0
    8000513a:	b7c9                	j	800050fc <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000513c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005140:	2b05                	addiw	s6,s6,1
    80005142:	0389899b          	addiw	s3,s3,56
    80005146:	e8845783          	lhu	a5,-376(s0)
    8000514a:	e2fb5be3          	bge	s6,a5,80004f80 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000514e:	2981                	sext.w	s3,s3
    80005150:	03800713          	li	a4,56
    80005154:	86ce                	mv	a3,s3
    80005156:	e1840613          	addi	a2,s0,-488
    8000515a:	4581                	li	a1,0
    8000515c:	8526                	mv	a0,s1
    8000515e:	fffff097          	auipc	ra,0xfffff
    80005162:	a8e080e7          	jalr	-1394(ra) # 80003bec <readi>
    80005166:	03800793          	li	a5,56
    8000516a:	f8f517e3          	bne	a0,a5,800050f8 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000516e:	e1842783          	lw	a5,-488(s0)
    80005172:	4705                	li	a4,1
    80005174:	fce796e3          	bne	a5,a4,80005140 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005178:	e4043603          	ld	a2,-448(s0)
    8000517c:	e3843783          	ld	a5,-456(s0)
    80005180:	f8f669e3          	bltu	a2,a5,80005112 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005184:	e2843783          	ld	a5,-472(s0)
    80005188:	963e                	add	a2,a2,a5
    8000518a:	f8f667e3          	bltu	a2,a5,80005118 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000518e:	85ca                	mv	a1,s2
    80005190:	855e                	mv	a0,s7
    80005192:	ffffc097          	auipc	ra,0xffffc
    80005196:	290080e7          	jalr	656(ra) # 80001422 <uvmalloc>
    8000519a:	e0a43423          	sd	a0,-504(s0)
    8000519e:	d141                	beqz	a0,8000511e <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800051a0:	e2843d03          	ld	s10,-472(s0)
    800051a4:	df043783          	ld	a5,-528(s0)
    800051a8:	00fd77b3          	and	a5,s10,a5
    800051ac:	fba1                	bnez	a5,800050fc <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051ae:	e2042d83          	lw	s11,-480(s0)
    800051b2:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051b6:	f80c03e3          	beqz	s8,8000513c <exec+0x306>
    800051ba:	8a62                	mv	s4,s8
    800051bc:	4901                	li	s2,0
    800051be:	b345                	j	80004f5e <exec+0x128>

00000000800051c0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051c0:	7179                	addi	sp,sp,-48
    800051c2:	f406                	sd	ra,40(sp)
    800051c4:	f022                	sd	s0,32(sp)
    800051c6:	ec26                	sd	s1,24(sp)
    800051c8:	e84a                	sd	s2,16(sp)
    800051ca:	1800                	addi	s0,sp,48
    800051cc:	892e                	mv	s2,a1
    800051ce:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051d0:	fdc40593          	addi	a1,s0,-36
    800051d4:	ffffe097          	auipc	ra,0xffffe
    800051d8:	ad4080e7          	jalr	-1324(ra) # 80002ca8 <argint>
    800051dc:	04054063          	bltz	a0,8000521c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051e0:	fdc42703          	lw	a4,-36(s0)
    800051e4:	47bd                	li	a5,15
    800051e6:	02e7ed63          	bltu	a5,a4,80005220 <argfd+0x60>
    800051ea:	ffffc097          	auipc	ra,0xffffc
    800051ee:	7c6080e7          	jalr	1990(ra) # 800019b0 <myproc>
    800051f2:	fdc42703          	lw	a4,-36(s0)
    800051f6:	01a70793          	addi	a5,a4,26
    800051fa:	078e                	slli	a5,a5,0x3
    800051fc:	953e                	add	a0,a0,a5
    800051fe:	611c                	ld	a5,0(a0)
    80005200:	c395                	beqz	a5,80005224 <argfd+0x64>
    return -1;
  if(pfd)
    80005202:	00090463          	beqz	s2,8000520a <argfd+0x4a>
    *pfd = fd;
    80005206:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000520a:	4501                	li	a0,0
  if(pf)
    8000520c:	c091                	beqz	s1,80005210 <argfd+0x50>
    *pf = f;
    8000520e:	e09c                	sd	a5,0(s1)
}
    80005210:	70a2                	ld	ra,40(sp)
    80005212:	7402                	ld	s0,32(sp)
    80005214:	64e2                	ld	s1,24(sp)
    80005216:	6942                	ld	s2,16(sp)
    80005218:	6145                	addi	sp,sp,48
    8000521a:	8082                	ret
    return -1;
    8000521c:	557d                	li	a0,-1
    8000521e:	bfcd                	j	80005210 <argfd+0x50>
    return -1;
    80005220:	557d                	li	a0,-1
    80005222:	b7fd                	j	80005210 <argfd+0x50>
    80005224:	557d                	li	a0,-1
    80005226:	b7ed                	j	80005210 <argfd+0x50>

0000000080005228 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005228:	1101                	addi	sp,sp,-32
    8000522a:	ec06                	sd	ra,24(sp)
    8000522c:	e822                	sd	s0,16(sp)
    8000522e:	e426                	sd	s1,8(sp)
    80005230:	1000                	addi	s0,sp,32
    80005232:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005234:	ffffc097          	auipc	ra,0xffffc
    80005238:	77c080e7          	jalr	1916(ra) # 800019b0 <myproc>
    8000523c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000523e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005242:	4501                	li	a0,0
    80005244:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005246:	6398                	ld	a4,0(a5)
    80005248:	cb19                	beqz	a4,8000525e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000524a:	2505                	addiw	a0,a0,1
    8000524c:	07a1                	addi	a5,a5,8
    8000524e:	fed51ce3          	bne	a0,a3,80005246 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005252:	557d                	li	a0,-1
}
    80005254:	60e2                	ld	ra,24(sp)
    80005256:	6442                	ld	s0,16(sp)
    80005258:	64a2                	ld	s1,8(sp)
    8000525a:	6105                	addi	sp,sp,32
    8000525c:	8082                	ret
      p->ofile[fd] = f;
    8000525e:	01a50793          	addi	a5,a0,26
    80005262:	078e                	slli	a5,a5,0x3
    80005264:	963e                	add	a2,a2,a5
    80005266:	e204                	sd	s1,0(a2)
      return fd;
    80005268:	b7f5                	j	80005254 <fdalloc+0x2c>

000000008000526a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000526a:	715d                	addi	sp,sp,-80
    8000526c:	e486                	sd	ra,72(sp)
    8000526e:	e0a2                	sd	s0,64(sp)
    80005270:	fc26                	sd	s1,56(sp)
    80005272:	f84a                	sd	s2,48(sp)
    80005274:	f44e                	sd	s3,40(sp)
    80005276:	f052                	sd	s4,32(sp)
    80005278:	ec56                	sd	s5,24(sp)
    8000527a:	0880                	addi	s0,sp,80
    8000527c:	89ae                	mv	s3,a1
    8000527e:	8ab2                	mv	s5,a2
    80005280:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005282:	fb040593          	addi	a1,s0,-80
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	e86080e7          	jalr	-378(ra) # 8000410c <nameiparent>
    8000528e:	892a                	mv	s2,a0
    80005290:	12050f63          	beqz	a0,800053ce <create+0x164>
    return 0;

  ilock(dp);
    80005294:	ffffe097          	auipc	ra,0xffffe
    80005298:	6a4080e7          	jalr	1700(ra) # 80003938 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000529c:	4601                	li	a2,0
    8000529e:	fb040593          	addi	a1,s0,-80
    800052a2:	854a                	mv	a0,s2
    800052a4:	fffff097          	auipc	ra,0xfffff
    800052a8:	b78080e7          	jalr	-1160(ra) # 80003e1c <dirlookup>
    800052ac:	84aa                	mv	s1,a0
    800052ae:	c921                	beqz	a0,800052fe <create+0x94>
    iunlockput(dp);
    800052b0:	854a                	mv	a0,s2
    800052b2:	fffff097          	auipc	ra,0xfffff
    800052b6:	8e8080e7          	jalr	-1816(ra) # 80003b9a <iunlockput>
    ilock(ip);
    800052ba:	8526                	mv	a0,s1
    800052bc:	ffffe097          	auipc	ra,0xffffe
    800052c0:	67c080e7          	jalr	1660(ra) # 80003938 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052c4:	2981                	sext.w	s3,s3
    800052c6:	4789                	li	a5,2
    800052c8:	02f99463          	bne	s3,a5,800052f0 <create+0x86>
    800052cc:	0444d783          	lhu	a5,68(s1)
    800052d0:	37f9                	addiw	a5,a5,-2
    800052d2:	17c2                	slli	a5,a5,0x30
    800052d4:	93c1                	srli	a5,a5,0x30
    800052d6:	4705                	li	a4,1
    800052d8:	00f76c63          	bltu	a4,a5,800052f0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052dc:	8526                	mv	a0,s1
    800052de:	60a6                	ld	ra,72(sp)
    800052e0:	6406                	ld	s0,64(sp)
    800052e2:	74e2                	ld	s1,56(sp)
    800052e4:	7942                	ld	s2,48(sp)
    800052e6:	79a2                	ld	s3,40(sp)
    800052e8:	7a02                	ld	s4,32(sp)
    800052ea:	6ae2                	ld	s5,24(sp)
    800052ec:	6161                	addi	sp,sp,80
    800052ee:	8082                	ret
    iunlockput(ip);
    800052f0:	8526                	mv	a0,s1
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	8a8080e7          	jalr	-1880(ra) # 80003b9a <iunlockput>
    return 0;
    800052fa:	4481                	li	s1,0
    800052fc:	b7c5                	j	800052dc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052fe:	85ce                	mv	a1,s3
    80005300:	00092503          	lw	a0,0(s2)
    80005304:	ffffe097          	auipc	ra,0xffffe
    80005308:	49c080e7          	jalr	1180(ra) # 800037a0 <ialloc>
    8000530c:	84aa                	mv	s1,a0
    8000530e:	c529                	beqz	a0,80005358 <create+0xee>
  ilock(ip);
    80005310:	ffffe097          	auipc	ra,0xffffe
    80005314:	628080e7          	jalr	1576(ra) # 80003938 <ilock>
  ip->major = major;
    80005318:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000531c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005320:	4785                	li	a5,1
    80005322:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005326:	8526                	mv	a0,s1
    80005328:	ffffe097          	auipc	ra,0xffffe
    8000532c:	546080e7          	jalr	1350(ra) # 8000386e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005330:	2981                	sext.w	s3,s3
    80005332:	4785                	li	a5,1
    80005334:	02f98a63          	beq	s3,a5,80005368 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005338:	40d0                	lw	a2,4(s1)
    8000533a:	fb040593          	addi	a1,s0,-80
    8000533e:	854a                	mv	a0,s2
    80005340:	fffff097          	auipc	ra,0xfffff
    80005344:	cec080e7          	jalr	-788(ra) # 8000402c <dirlink>
    80005348:	06054b63          	bltz	a0,800053be <create+0x154>
  iunlockput(dp);
    8000534c:	854a                	mv	a0,s2
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	84c080e7          	jalr	-1972(ra) # 80003b9a <iunlockput>
  return ip;
    80005356:	b759                	j	800052dc <create+0x72>
    panic("create: ialloc");
    80005358:	00003517          	auipc	a0,0x3
    8000535c:	51850513          	addi	a0,a0,1304 # 80008870 <syscall_names+0x2a8>
    80005360:	ffffb097          	auipc	ra,0xffffb
    80005364:	1de080e7          	jalr	478(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005368:	04a95783          	lhu	a5,74(s2)
    8000536c:	2785                	addiw	a5,a5,1
    8000536e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005372:	854a                	mv	a0,s2
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	4fa080e7          	jalr	1274(ra) # 8000386e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000537c:	40d0                	lw	a2,4(s1)
    8000537e:	00003597          	auipc	a1,0x3
    80005382:	50258593          	addi	a1,a1,1282 # 80008880 <syscall_names+0x2b8>
    80005386:	8526                	mv	a0,s1
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	ca4080e7          	jalr	-860(ra) # 8000402c <dirlink>
    80005390:	00054f63          	bltz	a0,800053ae <create+0x144>
    80005394:	00492603          	lw	a2,4(s2)
    80005398:	00003597          	auipc	a1,0x3
    8000539c:	4f058593          	addi	a1,a1,1264 # 80008888 <syscall_names+0x2c0>
    800053a0:	8526                	mv	a0,s1
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	c8a080e7          	jalr	-886(ra) # 8000402c <dirlink>
    800053aa:	f80557e3          	bgez	a0,80005338 <create+0xce>
      panic("create dots");
    800053ae:	00003517          	auipc	a0,0x3
    800053b2:	4e250513          	addi	a0,a0,1250 # 80008890 <syscall_names+0x2c8>
    800053b6:	ffffb097          	auipc	ra,0xffffb
    800053ba:	188080e7          	jalr	392(ra) # 8000053e <panic>
    panic("create: dirlink");
    800053be:	00003517          	auipc	a0,0x3
    800053c2:	4e250513          	addi	a0,a0,1250 # 800088a0 <syscall_names+0x2d8>
    800053c6:	ffffb097          	auipc	ra,0xffffb
    800053ca:	178080e7          	jalr	376(ra) # 8000053e <panic>
    return 0;
    800053ce:	84aa                	mv	s1,a0
    800053d0:	b731                	j	800052dc <create+0x72>

00000000800053d2 <sys_dup>:
{
    800053d2:	7179                	addi	sp,sp,-48
    800053d4:	f406                	sd	ra,40(sp)
    800053d6:	f022                	sd	s0,32(sp)
    800053d8:	ec26                	sd	s1,24(sp)
    800053da:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053dc:	fd840613          	addi	a2,s0,-40
    800053e0:	4581                	li	a1,0
    800053e2:	4501                	li	a0,0
    800053e4:	00000097          	auipc	ra,0x0
    800053e8:	ddc080e7          	jalr	-548(ra) # 800051c0 <argfd>
    return -1;
    800053ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053ee:	02054363          	bltz	a0,80005414 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053f2:	fd843503          	ld	a0,-40(s0)
    800053f6:	00000097          	auipc	ra,0x0
    800053fa:	e32080e7          	jalr	-462(ra) # 80005228 <fdalloc>
    800053fe:	84aa                	mv	s1,a0
    return -1;
    80005400:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005402:	00054963          	bltz	a0,80005414 <sys_dup+0x42>
  filedup(f);
    80005406:	fd843503          	ld	a0,-40(s0)
    8000540a:	fffff097          	auipc	ra,0xfffff
    8000540e:	37a080e7          	jalr	890(ra) # 80004784 <filedup>
  return fd;
    80005412:	87a6                	mv	a5,s1
}
    80005414:	853e                	mv	a0,a5
    80005416:	70a2                	ld	ra,40(sp)
    80005418:	7402                	ld	s0,32(sp)
    8000541a:	64e2                	ld	s1,24(sp)
    8000541c:	6145                	addi	sp,sp,48
    8000541e:	8082                	ret

0000000080005420 <sys_read>:
{
    80005420:	7179                	addi	sp,sp,-48
    80005422:	f406                	sd	ra,40(sp)
    80005424:	f022                	sd	s0,32(sp)
    80005426:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005428:	fe840613          	addi	a2,s0,-24
    8000542c:	4581                	li	a1,0
    8000542e:	4501                	li	a0,0
    80005430:	00000097          	auipc	ra,0x0
    80005434:	d90080e7          	jalr	-624(ra) # 800051c0 <argfd>
    return -1;
    80005438:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000543a:	04054163          	bltz	a0,8000547c <sys_read+0x5c>
    8000543e:	fe440593          	addi	a1,s0,-28
    80005442:	4509                	li	a0,2
    80005444:	ffffe097          	auipc	ra,0xffffe
    80005448:	864080e7          	jalr	-1948(ra) # 80002ca8 <argint>
    return -1;
    8000544c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000544e:	02054763          	bltz	a0,8000547c <sys_read+0x5c>
    80005452:	fd840593          	addi	a1,s0,-40
    80005456:	4505                	li	a0,1
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	872080e7          	jalr	-1934(ra) # 80002cca <argaddr>
    return -1;
    80005460:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005462:	00054d63          	bltz	a0,8000547c <sys_read+0x5c>
  return fileread(f, p, n);
    80005466:	fe442603          	lw	a2,-28(s0)
    8000546a:	fd843583          	ld	a1,-40(s0)
    8000546e:	fe843503          	ld	a0,-24(s0)
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	49e080e7          	jalr	1182(ra) # 80004910 <fileread>
    8000547a:	87aa                	mv	a5,a0
}
    8000547c:	853e                	mv	a0,a5
    8000547e:	70a2                	ld	ra,40(sp)
    80005480:	7402                	ld	s0,32(sp)
    80005482:	6145                	addi	sp,sp,48
    80005484:	8082                	ret

0000000080005486 <sys_write>:
{
    80005486:	7179                	addi	sp,sp,-48
    80005488:	f406                	sd	ra,40(sp)
    8000548a:	f022                	sd	s0,32(sp)
    8000548c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000548e:	fe840613          	addi	a2,s0,-24
    80005492:	4581                	li	a1,0
    80005494:	4501                	li	a0,0
    80005496:	00000097          	auipc	ra,0x0
    8000549a:	d2a080e7          	jalr	-726(ra) # 800051c0 <argfd>
    return -1;
    8000549e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a0:	04054163          	bltz	a0,800054e2 <sys_write+0x5c>
    800054a4:	fe440593          	addi	a1,s0,-28
    800054a8:	4509                	li	a0,2
    800054aa:	ffffd097          	auipc	ra,0xffffd
    800054ae:	7fe080e7          	jalr	2046(ra) # 80002ca8 <argint>
    return -1;
    800054b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b4:	02054763          	bltz	a0,800054e2 <sys_write+0x5c>
    800054b8:	fd840593          	addi	a1,s0,-40
    800054bc:	4505                	li	a0,1
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	80c080e7          	jalr	-2036(ra) # 80002cca <argaddr>
    return -1;
    800054c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c8:	00054d63          	bltz	a0,800054e2 <sys_write+0x5c>
  return filewrite(f, p, n);
    800054cc:	fe442603          	lw	a2,-28(s0)
    800054d0:	fd843583          	ld	a1,-40(s0)
    800054d4:	fe843503          	ld	a0,-24(s0)
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	4fa080e7          	jalr	1274(ra) # 800049d2 <filewrite>
    800054e0:	87aa                	mv	a5,a0
}
    800054e2:	853e                	mv	a0,a5
    800054e4:	70a2                	ld	ra,40(sp)
    800054e6:	7402                	ld	s0,32(sp)
    800054e8:	6145                	addi	sp,sp,48
    800054ea:	8082                	ret

00000000800054ec <sys_close>:
{
    800054ec:	1101                	addi	sp,sp,-32
    800054ee:	ec06                	sd	ra,24(sp)
    800054f0:	e822                	sd	s0,16(sp)
    800054f2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054f4:	fe040613          	addi	a2,s0,-32
    800054f8:	fec40593          	addi	a1,s0,-20
    800054fc:	4501                	li	a0,0
    800054fe:	00000097          	auipc	ra,0x0
    80005502:	cc2080e7          	jalr	-830(ra) # 800051c0 <argfd>
    return -1;
    80005506:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005508:	02054463          	bltz	a0,80005530 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000550c:	ffffc097          	auipc	ra,0xffffc
    80005510:	4a4080e7          	jalr	1188(ra) # 800019b0 <myproc>
    80005514:	fec42783          	lw	a5,-20(s0)
    80005518:	07e9                	addi	a5,a5,26
    8000551a:	078e                	slli	a5,a5,0x3
    8000551c:	97aa                	add	a5,a5,a0
    8000551e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005522:	fe043503          	ld	a0,-32(s0)
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	2b0080e7          	jalr	688(ra) # 800047d6 <fileclose>
  return 0;
    8000552e:	4781                	li	a5,0
}
    80005530:	853e                	mv	a0,a5
    80005532:	60e2                	ld	ra,24(sp)
    80005534:	6442                	ld	s0,16(sp)
    80005536:	6105                	addi	sp,sp,32
    80005538:	8082                	ret

000000008000553a <sys_fstat>:
{
    8000553a:	1101                	addi	sp,sp,-32
    8000553c:	ec06                	sd	ra,24(sp)
    8000553e:	e822                	sd	s0,16(sp)
    80005540:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005542:	fe840613          	addi	a2,s0,-24
    80005546:	4581                	li	a1,0
    80005548:	4501                	li	a0,0
    8000554a:	00000097          	auipc	ra,0x0
    8000554e:	c76080e7          	jalr	-906(ra) # 800051c0 <argfd>
    return -1;
    80005552:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005554:	02054563          	bltz	a0,8000557e <sys_fstat+0x44>
    80005558:	fe040593          	addi	a1,s0,-32
    8000555c:	4505                	li	a0,1
    8000555e:	ffffd097          	auipc	ra,0xffffd
    80005562:	76c080e7          	jalr	1900(ra) # 80002cca <argaddr>
    return -1;
    80005566:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005568:	00054b63          	bltz	a0,8000557e <sys_fstat+0x44>
  return filestat(f, st);
    8000556c:	fe043583          	ld	a1,-32(s0)
    80005570:	fe843503          	ld	a0,-24(s0)
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	32a080e7          	jalr	810(ra) # 8000489e <filestat>
    8000557c:	87aa                	mv	a5,a0
}
    8000557e:	853e                	mv	a0,a5
    80005580:	60e2                	ld	ra,24(sp)
    80005582:	6442                	ld	s0,16(sp)
    80005584:	6105                	addi	sp,sp,32
    80005586:	8082                	ret

0000000080005588 <sys_link>:
{
    80005588:	7169                	addi	sp,sp,-304
    8000558a:	f606                	sd	ra,296(sp)
    8000558c:	f222                	sd	s0,288(sp)
    8000558e:	ee26                	sd	s1,280(sp)
    80005590:	ea4a                	sd	s2,272(sp)
    80005592:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005594:	08000613          	li	a2,128
    80005598:	ed040593          	addi	a1,s0,-304
    8000559c:	4501                	li	a0,0
    8000559e:	ffffd097          	auipc	ra,0xffffd
    800055a2:	74e080e7          	jalr	1870(ra) # 80002cec <argstr>
    return -1;
    800055a6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055a8:	10054e63          	bltz	a0,800056c4 <sys_link+0x13c>
    800055ac:	08000613          	li	a2,128
    800055b0:	f5040593          	addi	a1,s0,-176
    800055b4:	4505                	li	a0,1
    800055b6:	ffffd097          	auipc	ra,0xffffd
    800055ba:	736080e7          	jalr	1846(ra) # 80002cec <argstr>
    return -1;
    800055be:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055c0:	10054263          	bltz	a0,800056c4 <sys_link+0x13c>
  begin_op();
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	d46080e7          	jalr	-698(ra) # 8000430a <begin_op>
  if((ip = namei(old)) == 0){
    800055cc:	ed040513          	addi	a0,s0,-304
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	b1e080e7          	jalr	-1250(ra) # 800040ee <namei>
    800055d8:	84aa                	mv	s1,a0
    800055da:	c551                	beqz	a0,80005666 <sys_link+0xde>
  ilock(ip);
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	35c080e7          	jalr	860(ra) # 80003938 <ilock>
  if(ip->type == T_DIR){
    800055e4:	04449703          	lh	a4,68(s1)
    800055e8:	4785                	li	a5,1
    800055ea:	08f70463          	beq	a4,a5,80005672 <sys_link+0xea>
  ip->nlink++;
    800055ee:	04a4d783          	lhu	a5,74(s1)
    800055f2:	2785                	addiw	a5,a5,1
    800055f4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055f8:	8526                	mv	a0,s1
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	274080e7          	jalr	628(ra) # 8000386e <iupdate>
  iunlock(ip);
    80005602:	8526                	mv	a0,s1
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	3f6080e7          	jalr	1014(ra) # 800039fa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000560c:	fd040593          	addi	a1,s0,-48
    80005610:	f5040513          	addi	a0,s0,-176
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	af8080e7          	jalr	-1288(ra) # 8000410c <nameiparent>
    8000561c:	892a                	mv	s2,a0
    8000561e:	c935                	beqz	a0,80005692 <sys_link+0x10a>
  ilock(dp);
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	318080e7          	jalr	792(ra) # 80003938 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005628:	00092703          	lw	a4,0(s2)
    8000562c:	409c                	lw	a5,0(s1)
    8000562e:	04f71d63          	bne	a4,a5,80005688 <sys_link+0x100>
    80005632:	40d0                	lw	a2,4(s1)
    80005634:	fd040593          	addi	a1,s0,-48
    80005638:	854a                	mv	a0,s2
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	9f2080e7          	jalr	-1550(ra) # 8000402c <dirlink>
    80005642:	04054363          	bltz	a0,80005688 <sys_link+0x100>
  iunlockput(dp);
    80005646:	854a                	mv	a0,s2
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	552080e7          	jalr	1362(ra) # 80003b9a <iunlockput>
  iput(ip);
    80005650:	8526                	mv	a0,s1
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	4a0080e7          	jalr	1184(ra) # 80003af2 <iput>
  end_op();
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	d30080e7          	jalr	-720(ra) # 8000438a <end_op>
  return 0;
    80005662:	4781                	li	a5,0
    80005664:	a085                	j	800056c4 <sys_link+0x13c>
    end_op();
    80005666:	fffff097          	auipc	ra,0xfffff
    8000566a:	d24080e7          	jalr	-732(ra) # 8000438a <end_op>
    return -1;
    8000566e:	57fd                	li	a5,-1
    80005670:	a891                	j	800056c4 <sys_link+0x13c>
    iunlockput(ip);
    80005672:	8526                	mv	a0,s1
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	526080e7          	jalr	1318(ra) # 80003b9a <iunlockput>
    end_op();
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	d0e080e7          	jalr	-754(ra) # 8000438a <end_op>
    return -1;
    80005684:	57fd                	li	a5,-1
    80005686:	a83d                	j	800056c4 <sys_link+0x13c>
    iunlockput(dp);
    80005688:	854a                	mv	a0,s2
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	510080e7          	jalr	1296(ra) # 80003b9a <iunlockput>
  ilock(ip);
    80005692:	8526                	mv	a0,s1
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	2a4080e7          	jalr	676(ra) # 80003938 <ilock>
  ip->nlink--;
    8000569c:	04a4d783          	lhu	a5,74(s1)
    800056a0:	37fd                	addiw	a5,a5,-1
    800056a2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056a6:	8526                	mv	a0,s1
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	1c6080e7          	jalr	454(ra) # 8000386e <iupdate>
  iunlockput(ip);
    800056b0:	8526                	mv	a0,s1
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	4e8080e7          	jalr	1256(ra) # 80003b9a <iunlockput>
  end_op();
    800056ba:	fffff097          	auipc	ra,0xfffff
    800056be:	cd0080e7          	jalr	-816(ra) # 8000438a <end_op>
  return -1;
    800056c2:	57fd                	li	a5,-1
}
    800056c4:	853e                	mv	a0,a5
    800056c6:	70b2                	ld	ra,296(sp)
    800056c8:	7412                	ld	s0,288(sp)
    800056ca:	64f2                	ld	s1,280(sp)
    800056cc:	6952                	ld	s2,272(sp)
    800056ce:	6155                	addi	sp,sp,304
    800056d0:	8082                	ret

00000000800056d2 <sys_unlink>:
{
    800056d2:	7151                	addi	sp,sp,-240
    800056d4:	f586                	sd	ra,232(sp)
    800056d6:	f1a2                	sd	s0,224(sp)
    800056d8:	eda6                	sd	s1,216(sp)
    800056da:	e9ca                	sd	s2,208(sp)
    800056dc:	e5ce                	sd	s3,200(sp)
    800056de:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056e0:	08000613          	li	a2,128
    800056e4:	f3040593          	addi	a1,s0,-208
    800056e8:	4501                	li	a0,0
    800056ea:	ffffd097          	auipc	ra,0xffffd
    800056ee:	602080e7          	jalr	1538(ra) # 80002cec <argstr>
    800056f2:	18054163          	bltz	a0,80005874 <sys_unlink+0x1a2>
  begin_op();
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	c14080e7          	jalr	-1004(ra) # 8000430a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056fe:	fb040593          	addi	a1,s0,-80
    80005702:	f3040513          	addi	a0,s0,-208
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	a06080e7          	jalr	-1530(ra) # 8000410c <nameiparent>
    8000570e:	84aa                	mv	s1,a0
    80005710:	c979                	beqz	a0,800057e6 <sys_unlink+0x114>
  ilock(dp);
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	226080e7          	jalr	550(ra) # 80003938 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000571a:	00003597          	auipc	a1,0x3
    8000571e:	16658593          	addi	a1,a1,358 # 80008880 <syscall_names+0x2b8>
    80005722:	fb040513          	addi	a0,s0,-80
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	6dc080e7          	jalr	1756(ra) # 80003e02 <namecmp>
    8000572e:	14050a63          	beqz	a0,80005882 <sys_unlink+0x1b0>
    80005732:	00003597          	auipc	a1,0x3
    80005736:	15658593          	addi	a1,a1,342 # 80008888 <syscall_names+0x2c0>
    8000573a:	fb040513          	addi	a0,s0,-80
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	6c4080e7          	jalr	1732(ra) # 80003e02 <namecmp>
    80005746:	12050e63          	beqz	a0,80005882 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000574a:	f2c40613          	addi	a2,s0,-212
    8000574e:	fb040593          	addi	a1,s0,-80
    80005752:	8526                	mv	a0,s1
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	6c8080e7          	jalr	1736(ra) # 80003e1c <dirlookup>
    8000575c:	892a                	mv	s2,a0
    8000575e:	12050263          	beqz	a0,80005882 <sys_unlink+0x1b0>
  ilock(ip);
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	1d6080e7          	jalr	470(ra) # 80003938 <ilock>
  if(ip->nlink < 1)
    8000576a:	04a91783          	lh	a5,74(s2)
    8000576e:	08f05263          	blez	a5,800057f2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005772:	04491703          	lh	a4,68(s2)
    80005776:	4785                	li	a5,1
    80005778:	08f70563          	beq	a4,a5,80005802 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000577c:	4641                	li	a2,16
    8000577e:	4581                	li	a1,0
    80005780:	fc040513          	addi	a0,s0,-64
    80005784:	ffffb097          	auipc	ra,0xffffb
    80005788:	55c080e7          	jalr	1372(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000578c:	4741                	li	a4,16
    8000578e:	f2c42683          	lw	a3,-212(s0)
    80005792:	fc040613          	addi	a2,s0,-64
    80005796:	4581                	li	a1,0
    80005798:	8526                	mv	a0,s1
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	54a080e7          	jalr	1354(ra) # 80003ce4 <writei>
    800057a2:	47c1                	li	a5,16
    800057a4:	0af51563          	bne	a0,a5,8000584e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057a8:	04491703          	lh	a4,68(s2)
    800057ac:	4785                	li	a5,1
    800057ae:	0af70863          	beq	a4,a5,8000585e <sys_unlink+0x18c>
  iunlockput(dp);
    800057b2:	8526                	mv	a0,s1
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	3e6080e7          	jalr	998(ra) # 80003b9a <iunlockput>
  ip->nlink--;
    800057bc:	04a95783          	lhu	a5,74(s2)
    800057c0:	37fd                	addiw	a5,a5,-1
    800057c2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057c6:	854a                	mv	a0,s2
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	0a6080e7          	jalr	166(ra) # 8000386e <iupdate>
  iunlockput(ip);
    800057d0:	854a                	mv	a0,s2
    800057d2:	ffffe097          	auipc	ra,0xffffe
    800057d6:	3c8080e7          	jalr	968(ra) # 80003b9a <iunlockput>
  end_op();
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	bb0080e7          	jalr	-1104(ra) # 8000438a <end_op>
  return 0;
    800057e2:	4501                	li	a0,0
    800057e4:	a84d                	j	80005896 <sys_unlink+0x1c4>
    end_op();
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	ba4080e7          	jalr	-1116(ra) # 8000438a <end_op>
    return -1;
    800057ee:	557d                	li	a0,-1
    800057f0:	a05d                	j	80005896 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057f2:	00003517          	auipc	a0,0x3
    800057f6:	0be50513          	addi	a0,a0,190 # 800088b0 <syscall_names+0x2e8>
    800057fa:	ffffb097          	auipc	ra,0xffffb
    800057fe:	d44080e7          	jalr	-700(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005802:	04c92703          	lw	a4,76(s2)
    80005806:	02000793          	li	a5,32
    8000580a:	f6e7f9e3          	bgeu	a5,a4,8000577c <sys_unlink+0xaa>
    8000580e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005812:	4741                	li	a4,16
    80005814:	86ce                	mv	a3,s3
    80005816:	f1840613          	addi	a2,s0,-232
    8000581a:	4581                	li	a1,0
    8000581c:	854a                	mv	a0,s2
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	3ce080e7          	jalr	974(ra) # 80003bec <readi>
    80005826:	47c1                	li	a5,16
    80005828:	00f51b63          	bne	a0,a5,8000583e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000582c:	f1845783          	lhu	a5,-232(s0)
    80005830:	e7a1                	bnez	a5,80005878 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005832:	29c1                	addiw	s3,s3,16
    80005834:	04c92783          	lw	a5,76(s2)
    80005838:	fcf9ede3          	bltu	s3,a5,80005812 <sys_unlink+0x140>
    8000583c:	b781                	j	8000577c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000583e:	00003517          	auipc	a0,0x3
    80005842:	08a50513          	addi	a0,a0,138 # 800088c8 <syscall_names+0x300>
    80005846:	ffffb097          	auipc	ra,0xffffb
    8000584a:	cf8080e7          	jalr	-776(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000584e:	00003517          	auipc	a0,0x3
    80005852:	09250513          	addi	a0,a0,146 # 800088e0 <syscall_names+0x318>
    80005856:	ffffb097          	auipc	ra,0xffffb
    8000585a:	ce8080e7          	jalr	-792(ra) # 8000053e <panic>
    dp->nlink--;
    8000585e:	04a4d783          	lhu	a5,74(s1)
    80005862:	37fd                	addiw	a5,a5,-1
    80005864:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005868:	8526                	mv	a0,s1
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	004080e7          	jalr	4(ra) # 8000386e <iupdate>
    80005872:	b781                	j	800057b2 <sys_unlink+0xe0>
    return -1;
    80005874:	557d                	li	a0,-1
    80005876:	a005                	j	80005896 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005878:	854a                	mv	a0,s2
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	320080e7          	jalr	800(ra) # 80003b9a <iunlockput>
  iunlockput(dp);
    80005882:	8526                	mv	a0,s1
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	316080e7          	jalr	790(ra) # 80003b9a <iunlockput>
  end_op();
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	afe080e7          	jalr	-1282(ra) # 8000438a <end_op>
  return -1;
    80005894:	557d                	li	a0,-1
}
    80005896:	70ae                	ld	ra,232(sp)
    80005898:	740e                	ld	s0,224(sp)
    8000589a:	64ee                	ld	s1,216(sp)
    8000589c:	694e                	ld	s2,208(sp)
    8000589e:	69ae                	ld	s3,200(sp)
    800058a0:	616d                	addi	sp,sp,240
    800058a2:	8082                	ret

00000000800058a4 <sys_open>:

uint64
sys_open(void)
{
    800058a4:	7131                	addi	sp,sp,-192
    800058a6:	fd06                	sd	ra,184(sp)
    800058a8:	f922                	sd	s0,176(sp)
    800058aa:	f526                	sd	s1,168(sp)
    800058ac:	f14a                	sd	s2,160(sp)
    800058ae:	ed4e                	sd	s3,152(sp)
    800058b0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058b2:	08000613          	li	a2,128
    800058b6:	f5040593          	addi	a1,s0,-176
    800058ba:	4501                	li	a0,0
    800058bc:	ffffd097          	auipc	ra,0xffffd
    800058c0:	430080e7          	jalr	1072(ra) # 80002cec <argstr>
    return -1;
    800058c4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058c6:	0c054163          	bltz	a0,80005988 <sys_open+0xe4>
    800058ca:	f4c40593          	addi	a1,s0,-180
    800058ce:	4505                	li	a0,1
    800058d0:	ffffd097          	auipc	ra,0xffffd
    800058d4:	3d8080e7          	jalr	984(ra) # 80002ca8 <argint>
    800058d8:	0a054863          	bltz	a0,80005988 <sys_open+0xe4>

  begin_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	a2e080e7          	jalr	-1490(ra) # 8000430a <begin_op>

  if(omode & O_CREATE){
    800058e4:	f4c42783          	lw	a5,-180(s0)
    800058e8:	2007f793          	andi	a5,a5,512
    800058ec:	cbdd                	beqz	a5,800059a2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058ee:	4681                	li	a3,0
    800058f0:	4601                	li	a2,0
    800058f2:	4589                	li	a1,2
    800058f4:	f5040513          	addi	a0,s0,-176
    800058f8:	00000097          	auipc	ra,0x0
    800058fc:	972080e7          	jalr	-1678(ra) # 8000526a <create>
    80005900:	892a                	mv	s2,a0
    if(ip == 0){
    80005902:	c959                	beqz	a0,80005998 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005904:	04491703          	lh	a4,68(s2)
    80005908:	478d                	li	a5,3
    8000590a:	00f71763          	bne	a4,a5,80005918 <sys_open+0x74>
    8000590e:	04695703          	lhu	a4,70(s2)
    80005912:	47a5                	li	a5,9
    80005914:	0ce7ec63          	bltu	a5,a4,800059ec <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	e02080e7          	jalr	-510(ra) # 8000471a <filealloc>
    80005920:	89aa                	mv	s3,a0
    80005922:	10050263          	beqz	a0,80005a26 <sys_open+0x182>
    80005926:	00000097          	auipc	ra,0x0
    8000592a:	902080e7          	jalr	-1790(ra) # 80005228 <fdalloc>
    8000592e:	84aa                	mv	s1,a0
    80005930:	0e054663          	bltz	a0,80005a1c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005934:	04491703          	lh	a4,68(s2)
    80005938:	478d                	li	a5,3
    8000593a:	0cf70463          	beq	a4,a5,80005a02 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000593e:	4789                	li	a5,2
    80005940:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005944:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005948:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000594c:	f4c42783          	lw	a5,-180(s0)
    80005950:	0017c713          	xori	a4,a5,1
    80005954:	8b05                	andi	a4,a4,1
    80005956:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000595a:	0037f713          	andi	a4,a5,3
    8000595e:	00e03733          	snez	a4,a4
    80005962:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005966:	4007f793          	andi	a5,a5,1024
    8000596a:	c791                	beqz	a5,80005976 <sys_open+0xd2>
    8000596c:	04491703          	lh	a4,68(s2)
    80005970:	4789                	li	a5,2
    80005972:	08f70f63          	beq	a4,a5,80005a10 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005976:	854a                	mv	a0,s2
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	082080e7          	jalr	130(ra) # 800039fa <iunlock>
  end_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	a0a080e7          	jalr	-1526(ra) # 8000438a <end_op>

  return fd;
}
    80005988:	8526                	mv	a0,s1
    8000598a:	70ea                	ld	ra,184(sp)
    8000598c:	744a                	ld	s0,176(sp)
    8000598e:	74aa                	ld	s1,168(sp)
    80005990:	790a                	ld	s2,160(sp)
    80005992:	69ea                	ld	s3,152(sp)
    80005994:	6129                	addi	sp,sp,192
    80005996:	8082                	ret
      end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	9f2080e7          	jalr	-1550(ra) # 8000438a <end_op>
      return -1;
    800059a0:	b7e5                	j	80005988 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059a2:	f5040513          	addi	a0,s0,-176
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	748080e7          	jalr	1864(ra) # 800040ee <namei>
    800059ae:	892a                	mv	s2,a0
    800059b0:	c905                	beqz	a0,800059e0 <sys_open+0x13c>
    ilock(ip);
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	f86080e7          	jalr	-122(ra) # 80003938 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059ba:	04491703          	lh	a4,68(s2)
    800059be:	4785                	li	a5,1
    800059c0:	f4f712e3          	bne	a4,a5,80005904 <sys_open+0x60>
    800059c4:	f4c42783          	lw	a5,-180(s0)
    800059c8:	dba1                	beqz	a5,80005918 <sys_open+0x74>
      iunlockput(ip);
    800059ca:	854a                	mv	a0,s2
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	1ce080e7          	jalr	462(ra) # 80003b9a <iunlockput>
      end_op();
    800059d4:	fffff097          	auipc	ra,0xfffff
    800059d8:	9b6080e7          	jalr	-1610(ra) # 8000438a <end_op>
      return -1;
    800059dc:	54fd                	li	s1,-1
    800059de:	b76d                	j	80005988 <sys_open+0xe4>
      end_op();
    800059e0:	fffff097          	auipc	ra,0xfffff
    800059e4:	9aa080e7          	jalr	-1622(ra) # 8000438a <end_op>
      return -1;
    800059e8:	54fd                	li	s1,-1
    800059ea:	bf79                	j	80005988 <sys_open+0xe4>
    iunlockput(ip);
    800059ec:	854a                	mv	a0,s2
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	1ac080e7          	jalr	428(ra) # 80003b9a <iunlockput>
    end_op();
    800059f6:	fffff097          	auipc	ra,0xfffff
    800059fa:	994080e7          	jalr	-1644(ra) # 8000438a <end_op>
    return -1;
    800059fe:	54fd                	li	s1,-1
    80005a00:	b761                	j	80005988 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a02:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a06:	04691783          	lh	a5,70(s2)
    80005a0a:	02f99223          	sh	a5,36(s3)
    80005a0e:	bf2d                	j	80005948 <sys_open+0xa4>
    itrunc(ip);
    80005a10:	854a                	mv	a0,s2
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	034080e7          	jalr	52(ra) # 80003a46 <itrunc>
    80005a1a:	bfb1                	j	80005976 <sys_open+0xd2>
      fileclose(f);
    80005a1c:	854e                	mv	a0,s3
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	db8080e7          	jalr	-584(ra) # 800047d6 <fileclose>
    iunlockput(ip);
    80005a26:	854a                	mv	a0,s2
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	172080e7          	jalr	370(ra) # 80003b9a <iunlockput>
    end_op();
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	95a080e7          	jalr	-1702(ra) # 8000438a <end_op>
    return -1;
    80005a38:	54fd                	li	s1,-1
    80005a3a:	b7b9                	j	80005988 <sys_open+0xe4>

0000000080005a3c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a3c:	7175                	addi	sp,sp,-144
    80005a3e:	e506                	sd	ra,136(sp)
    80005a40:	e122                	sd	s0,128(sp)
    80005a42:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a44:	fffff097          	auipc	ra,0xfffff
    80005a48:	8c6080e7          	jalr	-1850(ra) # 8000430a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a4c:	08000613          	li	a2,128
    80005a50:	f7040593          	addi	a1,s0,-144
    80005a54:	4501                	li	a0,0
    80005a56:	ffffd097          	auipc	ra,0xffffd
    80005a5a:	296080e7          	jalr	662(ra) # 80002cec <argstr>
    80005a5e:	02054963          	bltz	a0,80005a90 <sys_mkdir+0x54>
    80005a62:	4681                	li	a3,0
    80005a64:	4601                	li	a2,0
    80005a66:	4585                	li	a1,1
    80005a68:	f7040513          	addi	a0,s0,-144
    80005a6c:	fffff097          	auipc	ra,0xfffff
    80005a70:	7fe080e7          	jalr	2046(ra) # 8000526a <create>
    80005a74:	cd11                	beqz	a0,80005a90 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	124080e7          	jalr	292(ra) # 80003b9a <iunlockput>
  end_op();
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	90c080e7          	jalr	-1780(ra) # 8000438a <end_op>
  return 0;
    80005a86:	4501                	li	a0,0
}
    80005a88:	60aa                	ld	ra,136(sp)
    80005a8a:	640a                	ld	s0,128(sp)
    80005a8c:	6149                	addi	sp,sp,144
    80005a8e:	8082                	ret
    end_op();
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	8fa080e7          	jalr	-1798(ra) # 8000438a <end_op>
    return -1;
    80005a98:	557d                	li	a0,-1
    80005a9a:	b7fd                	j	80005a88 <sys_mkdir+0x4c>

0000000080005a9c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a9c:	7135                	addi	sp,sp,-160
    80005a9e:	ed06                	sd	ra,152(sp)
    80005aa0:	e922                	sd	s0,144(sp)
    80005aa2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	866080e7          	jalr	-1946(ra) # 8000430a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aac:	08000613          	li	a2,128
    80005ab0:	f7040593          	addi	a1,s0,-144
    80005ab4:	4501                	li	a0,0
    80005ab6:	ffffd097          	auipc	ra,0xffffd
    80005aba:	236080e7          	jalr	566(ra) # 80002cec <argstr>
    80005abe:	04054a63          	bltz	a0,80005b12 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005ac2:	f6c40593          	addi	a1,s0,-148
    80005ac6:	4505                	li	a0,1
    80005ac8:	ffffd097          	auipc	ra,0xffffd
    80005acc:	1e0080e7          	jalr	480(ra) # 80002ca8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ad0:	04054163          	bltz	a0,80005b12 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ad4:	f6840593          	addi	a1,s0,-152
    80005ad8:	4509                	li	a0,2
    80005ada:	ffffd097          	auipc	ra,0xffffd
    80005ade:	1ce080e7          	jalr	462(ra) # 80002ca8 <argint>
     argint(1, &major) < 0 ||
    80005ae2:	02054863          	bltz	a0,80005b12 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ae6:	f6841683          	lh	a3,-152(s0)
    80005aea:	f6c41603          	lh	a2,-148(s0)
    80005aee:	458d                	li	a1,3
    80005af0:	f7040513          	addi	a0,s0,-144
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	776080e7          	jalr	1910(ra) # 8000526a <create>
     argint(2, &minor) < 0 ||
    80005afc:	c919                	beqz	a0,80005b12 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	09c080e7          	jalr	156(ra) # 80003b9a <iunlockput>
  end_op();
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	884080e7          	jalr	-1916(ra) # 8000438a <end_op>
  return 0;
    80005b0e:	4501                	li	a0,0
    80005b10:	a031                	j	80005b1c <sys_mknod+0x80>
    end_op();
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	878080e7          	jalr	-1928(ra) # 8000438a <end_op>
    return -1;
    80005b1a:	557d                	li	a0,-1
}
    80005b1c:	60ea                	ld	ra,152(sp)
    80005b1e:	644a                	ld	s0,144(sp)
    80005b20:	610d                	addi	sp,sp,160
    80005b22:	8082                	ret

0000000080005b24 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b24:	7135                	addi	sp,sp,-160
    80005b26:	ed06                	sd	ra,152(sp)
    80005b28:	e922                	sd	s0,144(sp)
    80005b2a:	e526                	sd	s1,136(sp)
    80005b2c:	e14a                	sd	s2,128(sp)
    80005b2e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b30:	ffffc097          	auipc	ra,0xffffc
    80005b34:	e80080e7          	jalr	-384(ra) # 800019b0 <myproc>
    80005b38:	892a                	mv	s2,a0
  
  begin_op();
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	7d0080e7          	jalr	2000(ra) # 8000430a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b42:	08000613          	li	a2,128
    80005b46:	f6040593          	addi	a1,s0,-160
    80005b4a:	4501                	li	a0,0
    80005b4c:	ffffd097          	auipc	ra,0xffffd
    80005b50:	1a0080e7          	jalr	416(ra) # 80002cec <argstr>
    80005b54:	04054b63          	bltz	a0,80005baa <sys_chdir+0x86>
    80005b58:	f6040513          	addi	a0,s0,-160
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	592080e7          	jalr	1426(ra) # 800040ee <namei>
    80005b64:	84aa                	mv	s1,a0
    80005b66:	c131                	beqz	a0,80005baa <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	dd0080e7          	jalr	-560(ra) # 80003938 <ilock>
  if(ip->type != T_DIR){
    80005b70:	04449703          	lh	a4,68(s1)
    80005b74:	4785                	li	a5,1
    80005b76:	04f71063          	bne	a4,a5,80005bb6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b7a:	8526                	mv	a0,s1
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	e7e080e7          	jalr	-386(ra) # 800039fa <iunlock>
  iput(p->cwd);
    80005b84:	15093503          	ld	a0,336(s2)
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	f6a080e7          	jalr	-150(ra) # 80003af2 <iput>
  end_op();
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	7fa080e7          	jalr	2042(ra) # 8000438a <end_op>
  p->cwd = ip;
    80005b98:	14993823          	sd	s1,336(s2)
  return 0;
    80005b9c:	4501                	li	a0,0
}
    80005b9e:	60ea                	ld	ra,152(sp)
    80005ba0:	644a                	ld	s0,144(sp)
    80005ba2:	64aa                	ld	s1,136(sp)
    80005ba4:	690a                	ld	s2,128(sp)
    80005ba6:	610d                	addi	sp,sp,160
    80005ba8:	8082                	ret
    end_op();
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	7e0080e7          	jalr	2016(ra) # 8000438a <end_op>
    return -1;
    80005bb2:	557d                	li	a0,-1
    80005bb4:	b7ed                	j	80005b9e <sys_chdir+0x7a>
    iunlockput(ip);
    80005bb6:	8526                	mv	a0,s1
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	fe2080e7          	jalr	-30(ra) # 80003b9a <iunlockput>
    end_op();
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	7ca080e7          	jalr	1994(ra) # 8000438a <end_op>
    return -1;
    80005bc8:	557d                	li	a0,-1
    80005bca:	bfd1                	j	80005b9e <sys_chdir+0x7a>

0000000080005bcc <sys_exec>:

uint64
sys_exec(void)
{
    80005bcc:	7145                	addi	sp,sp,-464
    80005bce:	e786                	sd	ra,456(sp)
    80005bd0:	e3a2                	sd	s0,448(sp)
    80005bd2:	ff26                	sd	s1,440(sp)
    80005bd4:	fb4a                	sd	s2,432(sp)
    80005bd6:	f74e                	sd	s3,424(sp)
    80005bd8:	f352                	sd	s4,416(sp)
    80005bda:	ef56                	sd	s5,408(sp)
    80005bdc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bde:	08000613          	li	a2,128
    80005be2:	f4040593          	addi	a1,s0,-192
    80005be6:	4501                	li	a0,0
    80005be8:	ffffd097          	auipc	ra,0xffffd
    80005bec:	104080e7          	jalr	260(ra) # 80002cec <argstr>
    return -1;
    80005bf0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bf2:	0c054a63          	bltz	a0,80005cc6 <sys_exec+0xfa>
    80005bf6:	e3840593          	addi	a1,s0,-456
    80005bfa:	4505                	li	a0,1
    80005bfc:	ffffd097          	auipc	ra,0xffffd
    80005c00:	0ce080e7          	jalr	206(ra) # 80002cca <argaddr>
    80005c04:	0c054163          	bltz	a0,80005cc6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c08:	10000613          	li	a2,256
    80005c0c:	4581                	li	a1,0
    80005c0e:	e4040513          	addi	a0,s0,-448
    80005c12:	ffffb097          	auipc	ra,0xffffb
    80005c16:	0ce080e7          	jalr	206(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c1a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c1e:	89a6                	mv	s3,s1
    80005c20:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c22:	02000a13          	li	s4,32
    80005c26:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c2a:	00391513          	slli	a0,s2,0x3
    80005c2e:	e3040593          	addi	a1,s0,-464
    80005c32:	e3843783          	ld	a5,-456(s0)
    80005c36:	953e                	add	a0,a0,a5
    80005c38:	ffffd097          	auipc	ra,0xffffd
    80005c3c:	fd6080e7          	jalr	-42(ra) # 80002c0e <fetchaddr>
    80005c40:	02054a63          	bltz	a0,80005c74 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c44:	e3043783          	ld	a5,-464(s0)
    80005c48:	c3b9                	beqz	a5,80005c8e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c4a:	ffffb097          	auipc	ra,0xffffb
    80005c4e:	eaa080e7          	jalr	-342(ra) # 80000af4 <kalloc>
    80005c52:	85aa                	mv	a1,a0
    80005c54:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c58:	cd11                	beqz	a0,80005c74 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c5a:	6605                	lui	a2,0x1
    80005c5c:	e3043503          	ld	a0,-464(s0)
    80005c60:	ffffd097          	auipc	ra,0xffffd
    80005c64:	000080e7          	jalr	ra # 80002c60 <fetchstr>
    80005c68:	00054663          	bltz	a0,80005c74 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c6c:	0905                	addi	s2,s2,1
    80005c6e:	09a1                	addi	s3,s3,8
    80005c70:	fb491be3          	bne	s2,s4,80005c26 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c74:	10048913          	addi	s2,s1,256
    80005c78:	6088                	ld	a0,0(s1)
    80005c7a:	c529                	beqz	a0,80005cc4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c7c:	ffffb097          	auipc	ra,0xffffb
    80005c80:	d7c080e7          	jalr	-644(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c84:	04a1                	addi	s1,s1,8
    80005c86:	ff2499e3          	bne	s1,s2,80005c78 <sys_exec+0xac>
  return -1;
    80005c8a:	597d                	li	s2,-1
    80005c8c:	a82d                	j	80005cc6 <sys_exec+0xfa>
      argv[i] = 0;
    80005c8e:	0a8e                	slli	s5,s5,0x3
    80005c90:	fc040793          	addi	a5,s0,-64
    80005c94:	9abe                	add	s5,s5,a5
    80005c96:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c9a:	e4040593          	addi	a1,s0,-448
    80005c9e:	f4040513          	addi	a0,s0,-192
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	194080e7          	jalr	404(ra) # 80004e36 <exec>
    80005caa:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cac:	10048993          	addi	s3,s1,256
    80005cb0:	6088                	ld	a0,0(s1)
    80005cb2:	c911                	beqz	a0,80005cc6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005cb4:	ffffb097          	auipc	ra,0xffffb
    80005cb8:	d44080e7          	jalr	-700(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cbc:	04a1                	addi	s1,s1,8
    80005cbe:	ff3499e3          	bne	s1,s3,80005cb0 <sys_exec+0xe4>
    80005cc2:	a011                	j	80005cc6 <sys_exec+0xfa>
  return -1;
    80005cc4:	597d                	li	s2,-1
}
    80005cc6:	854a                	mv	a0,s2
    80005cc8:	60be                	ld	ra,456(sp)
    80005cca:	641e                	ld	s0,448(sp)
    80005ccc:	74fa                	ld	s1,440(sp)
    80005cce:	795a                	ld	s2,432(sp)
    80005cd0:	79ba                	ld	s3,424(sp)
    80005cd2:	7a1a                	ld	s4,416(sp)
    80005cd4:	6afa                	ld	s5,408(sp)
    80005cd6:	6179                	addi	sp,sp,464
    80005cd8:	8082                	ret

0000000080005cda <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cda:	7139                	addi	sp,sp,-64
    80005cdc:	fc06                	sd	ra,56(sp)
    80005cde:	f822                	sd	s0,48(sp)
    80005ce0:	f426                	sd	s1,40(sp)
    80005ce2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ce4:	ffffc097          	auipc	ra,0xffffc
    80005ce8:	ccc080e7          	jalr	-820(ra) # 800019b0 <myproc>
    80005cec:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005cee:	fd840593          	addi	a1,s0,-40
    80005cf2:	4501                	li	a0,0
    80005cf4:	ffffd097          	auipc	ra,0xffffd
    80005cf8:	fd6080e7          	jalr	-42(ra) # 80002cca <argaddr>
    return -1;
    80005cfc:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005cfe:	0e054063          	bltz	a0,80005dde <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d02:	fc840593          	addi	a1,s0,-56
    80005d06:	fd040513          	addi	a0,s0,-48
    80005d0a:	fffff097          	auipc	ra,0xfffff
    80005d0e:	dfc080e7          	jalr	-516(ra) # 80004b06 <pipealloc>
    return -1;
    80005d12:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d14:	0c054563          	bltz	a0,80005dde <sys_pipe+0x104>
  fd0 = -1;
    80005d18:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d1c:	fd043503          	ld	a0,-48(s0)
    80005d20:	fffff097          	auipc	ra,0xfffff
    80005d24:	508080e7          	jalr	1288(ra) # 80005228 <fdalloc>
    80005d28:	fca42223          	sw	a0,-60(s0)
    80005d2c:	08054c63          	bltz	a0,80005dc4 <sys_pipe+0xea>
    80005d30:	fc843503          	ld	a0,-56(s0)
    80005d34:	fffff097          	auipc	ra,0xfffff
    80005d38:	4f4080e7          	jalr	1268(ra) # 80005228 <fdalloc>
    80005d3c:	fca42023          	sw	a0,-64(s0)
    80005d40:	06054863          	bltz	a0,80005db0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d44:	4691                	li	a3,4
    80005d46:	fc440613          	addi	a2,s0,-60
    80005d4a:	fd843583          	ld	a1,-40(s0)
    80005d4e:	68a8                	ld	a0,80(s1)
    80005d50:	ffffc097          	auipc	ra,0xffffc
    80005d54:	922080e7          	jalr	-1758(ra) # 80001672 <copyout>
    80005d58:	02054063          	bltz	a0,80005d78 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d5c:	4691                	li	a3,4
    80005d5e:	fc040613          	addi	a2,s0,-64
    80005d62:	fd843583          	ld	a1,-40(s0)
    80005d66:	0591                	addi	a1,a1,4
    80005d68:	68a8                	ld	a0,80(s1)
    80005d6a:	ffffc097          	auipc	ra,0xffffc
    80005d6e:	908080e7          	jalr	-1784(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d72:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d74:	06055563          	bgez	a0,80005dde <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d78:	fc442783          	lw	a5,-60(s0)
    80005d7c:	07e9                	addi	a5,a5,26
    80005d7e:	078e                	slli	a5,a5,0x3
    80005d80:	97a6                	add	a5,a5,s1
    80005d82:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d86:	fc042503          	lw	a0,-64(s0)
    80005d8a:	0569                	addi	a0,a0,26
    80005d8c:	050e                	slli	a0,a0,0x3
    80005d8e:	9526                	add	a0,a0,s1
    80005d90:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d94:	fd043503          	ld	a0,-48(s0)
    80005d98:	fffff097          	auipc	ra,0xfffff
    80005d9c:	a3e080e7          	jalr	-1474(ra) # 800047d6 <fileclose>
    fileclose(wf);
    80005da0:	fc843503          	ld	a0,-56(s0)
    80005da4:	fffff097          	auipc	ra,0xfffff
    80005da8:	a32080e7          	jalr	-1486(ra) # 800047d6 <fileclose>
    return -1;
    80005dac:	57fd                	li	a5,-1
    80005dae:	a805                	j	80005dde <sys_pipe+0x104>
    if(fd0 >= 0)
    80005db0:	fc442783          	lw	a5,-60(s0)
    80005db4:	0007c863          	bltz	a5,80005dc4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005db8:	01a78513          	addi	a0,a5,26
    80005dbc:	050e                	slli	a0,a0,0x3
    80005dbe:	9526                	add	a0,a0,s1
    80005dc0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005dc4:	fd043503          	ld	a0,-48(s0)
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	a0e080e7          	jalr	-1522(ra) # 800047d6 <fileclose>
    fileclose(wf);
    80005dd0:	fc843503          	ld	a0,-56(s0)
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	a02080e7          	jalr	-1534(ra) # 800047d6 <fileclose>
    return -1;
    80005ddc:	57fd                	li	a5,-1
}
    80005dde:	853e                	mv	a0,a5
    80005de0:	70e2                	ld	ra,56(sp)
    80005de2:	7442                	ld	s0,48(sp)
    80005de4:	74a2                	ld	s1,40(sp)
    80005de6:	6121                	addi	sp,sp,64
    80005de8:	8082                	ret
    80005dea:	0000                	unimp
    80005dec:	0000                	unimp
	...

0000000080005df0 <kernelvec>:
    80005df0:	7111                	addi	sp,sp,-256
    80005df2:	e006                	sd	ra,0(sp)
    80005df4:	e40a                	sd	sp,8(sp)
    80005df6:	e80e                	sd	gp,16(sp)
    80005df8:	ec12                	sd	tp,24(sp)
    80005dfa:	f016                	sd	t0,32(sp)
    80005dfc:	f41a                	sd	t1,40(sp)
    80005dfe:	f81e                	sd	t2,48(sp)
    80005e00:	fc22                	sd	s0,56(sp)
    80005e02:	e0a6                	sd	s1,64(sp)
    80005e04:	e4aa                	sd	a0,72(sp)
    80005e06:	e8ae                	sd	a1,80(sp)
    80005e08:	ecb2                	sd	a2,88(sp)
    80005e0a:	f0b6                	sd	a3,96(sp)
    80005e0c:	f4ba                	sd	a4,104(sp)
    80005e0e:	f8be                	sd	a5,112(sp)
    80005e10:	fcc2                	sd	a6,120(sp)
    80005e12:	e146                	sd	a7,128(sp)
    80005e14:	e54a                	sd	s2,136(sp)
    80005e16:	e94e                	sd	s3,144(sp)
    80005e18:	ed52                	sd	s4,152(sp)
    80005e1a:	f156                	sd	s5,160(sp)
    80005e1c:	f55a                	sd	s6,168(sp)
    80005e1e:	f95e                	sd	s7,176(sp)
    80005e20:	fd62                	sd	s8,184(sp)
    80005e22:	e1e6                	sd	s9,192(sp)
    80005e24:	e5ea                	sd	s10,200(sp)
    80005e26:	e9ee                	sd	s11,208(sp)
    80005e28:	edf2                	sd	t3,216(sp)
    80005e2a:	f1f6                	sd	t4,224(sp)
    80005e2c:	f5fa                	sd	t5,232(sp)
    80005e2e:	f9fe                	sd	t6,240(sp)
    80005e30:	cabfc0ef          	jal	ra,80002ada <kerneltrap>
    80005e34:	6082                	ld	ra,0(sp)
    80005e36:	6122                	ld	sp,8(sp)
    80005e38:	61c2                	ld	gp,16(sp)
    80005e3a:	7282                	ld	t0,32(sp)
    80005e3c:	7322                	ld	t1,40(sp)
    80005e3e:	73c2                	ld	t2,48(sp)
    80005e40:	7462                	ld	s0,56(sp)
    80005e42:	6486                	ld	s1,64(sp)
    80005e44:	6526                	ld	a0,72(sp)
    80005e46:	65c6                	ld	a1,80(sp)
    80005e48:	6666                	ld	a2,88(sp)
    80005e4a:	7686                	ld	a3,96(sp)
    80005e4c:	7726                	ld	a4,104(sp)
    80005e4e:	77c6                	ld	a5,112(sp)
    80005e50:	7866                	ld	a6,120(sp)
    80005e52:	688a                	ld	a7,128(sp)
    80005e54:	692a                	ld	s2,136(sp)
    80005e56:	69ca                	ld	s3,144(sp)
    80005e58:	6a6a                	ld	s4,152(sp)
    80005e5a:	7a8a                	ld	s5,160(sp)
    80005e5c:	7b2a                	ld	s6,168(sp)
    80005e5e:	7bca                	ld	s7,176(sp)
    80005e60:	7c6a                	ld	s8,184(sp)
    80005e62:	6c8e                	ld	s9,192(sp)
    80005e64:	6d2e                	ld	s10,200(sp)
    80005e66:	6dce                	ld	s11,208(sp)
    80005e68:	6e6e                	ld	t3,216(sp)
    80005e6a:	7e8e                	ld	t4,224(sp)
    80005e6c:	7f2e                	ld	t5,232(sp)
    80005e6e:	7fce                	ld	t6,240(sp)
    80005e70:	6111                	addi	sp,sp,256
    80005e72:	10200073          	sret
    80005e76:	00000013          	nop
    80005e7a:	00000013          	nop
    80005e7e:	0001                	nop

0000000080005e80 <timervec>:
    80005e80:	34051573          	csrrw	a0,mscratch,a0
    80005e84:	e10c                	sd	a1,0(a0)
    80005e86:	e510                	sd	a2,8(a0)
    80005e88:	e914                	sd	a3,16(a0)
    80005e8a:	6d0c                	ld	a1,24(a0)
    80005e8c:	7110                	ld	a2,32(a0)
    80005e8e:	6194                	ld	a3,0(a1)
    80005e90:	96b2                	add	a3,a3,a2
    80005e92:	e194                	sd	a3,0(a1)
    80005e94:	4589                	li	a1,2
    80005e96:	14459073          	csrw	sip,a1
    80005e9a:	6914                	ld	a3,16(a0)
    80005e9c:	6510                	ld	a2,8(a0)
    80005e9e:	610c                	ld	a1,0(a0)
    80005ea0:	34051573          	csrrw	a0,mscratch,a0
    80005ea4:	30200073          	mret
	...

0000000080005eaa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eaa:	1141                	addi	sp,sp,-16
    80005eac:	e422                	sd	s0,8(sp)
    80005eae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005eb0:	0c0007b7          	lui	a5,0xc000
    80005eb4:	4705                	li	a4,1
    80005eb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005eb8:	c3d8                	sw	a4,4(a5)
}
    80005eba:	6422                	ld	s0,8(sp)
    80005ebc:	0141                	addi	sp,sp,16
    80005ebe:	8082                	ret

0000000080005ec0 <plicinithart>:

void
plicinithart(void)
{
    80005ec0:	1141                	addi	sp,sp,-16
    80005ec2:	e406                	sd	ra,8(sp)
    80005ec4:	e022                	sd	s0,0(sp)
    80005ec6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	abc080e7          	jalr	-1348(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ed0:	0085171b          	slliw	a4,a0,0x8
    80005ed4:	0c0027b7          	lui	a5,0xc002
    80005ed8:	97ba                	add	a5,a5,a4
    80005eda:	40200713          	li	a4,1026
    80005ede:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ee2:	00d5151b          	slliw	a0,a0,0xd
    80005ee6:	0c2017b7          	lui	a5,0xc201
    80005eea:	953e                	add	a0,a0,a5
    80005eec:	00052023          	sw	zero,0(a0)
}
    80005ef0:	60a2                	ld	ra,8(sp)
    80005ef2:	6402                	ld	s0,0(sp)
    80005ef4:	0141                	addi	sp,sp,16
    80005ef6:	8082                	ret

0000000080005ef8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ef8:	1141                	addi	sp,sp,-16
    80005efa:	e406                	sd	ra,8(sp)
    80005efc:	e022                	sd	s0,0(sp)
    80005efe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f00:	ffffc097          	auipc	ra,0xffffc
    80005f04:	a84080e7          	jalr	-1404(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f08:	00d5179b          	slliw	a5,a0,0xd
    80005f0c:	0c201537          	lui	a0,0xc201
    80005f10:	953e                	add	a0,a0,a5
  return irq;
}
    80005f12:	4148                	lw	a0,4(a0)
    80005f14:	60a2                	ld	ra,8(sp)
    80005f16:	6402                	ld	s0,0(sp)
    80005f18:	0141                	addi	sp,sp,16
    80005f1a:	8082                	ret

0000000080005f1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f1c:	1101                	addi	sp,sp,-32
    80005f1e:	ec06                	sd	ra,24(sp)
    80005f20:	e822                	sd	s0,16(sp)
    80005f22:	e426                	sd	s1,8(sp)
    80005f24:	1000                	addi	s0,sp,32
    80005f26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	a5c080e7          	jalr	-1444(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f30:	00d5151b          	slliw	a0,a0,0xd
    80005f34:	0c2017b7          	lui	a5,0xc201
    80005f38:	97aa                	add	a5,a5,a0
    80005f3a:	c3c4                	sw	s1,4(a5)
}
    80005f3c:	60e2                	ld	ra,24(sp)
    80005f3e:	6442                	ld	s0,16(sp)
    80005f40:	64a2                	ld	s1,8(sp)
    80005f42:	6105                	addi	sp,sp,32
    80005f44:	8082                	ret

0000000080005f46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f46:	1141                	addi	sp,sp,-16
    80005f48:	e406                	sd	ra,8(sp)
    80005f4a:	e022                	sd	s0,0(sp)
    80005f4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f4e:	479d                	li	a5,7
    80005f50:	06a7c963          	blt	a5,a0,80005fc2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f54:	0001d797          	auipc	a5,0x1d
    80005f58:	0ac78793          	addi	a5,a5,172 # 80023000 <disk>
    80005f5c:	00a78733          	add	a4,a5,a0
    80005f60:	6789                	lui	a5,0x2
    80005f62:	97ba                	add	a5,a5,a4
    80005f64:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f68:	e7ad                	bnez	a5,80005fd2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f6a:	00451793          	slli	a5,a0,0x4
    80005f6e:	0001f717          	auipc	a4,0x1f
    80005f72:	09270713          	addi	a4,a4,146 # 80025000 <disk+0x2000>
    80005f76:	6314                	ld	a3,0(a4)
    80005f78:	96be                	add	a3,a3,a5
    80005f7a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f7e:	6314                	ld	a3,0(a4)
    80005f80:	96be                	add	a3,a3,a5
    80005f82:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f86:	6314                	ld	a3,0(a4)
    80005f88:	96be                	add	a3,a3,a5
    80005f8a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f8e:	6318                	ld	a4,0(a4)
    80005f90:	97ba                	add	a5,a5,a4
    80005f92:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f96:	0001d797          	auipc	a5,0x1d
    80005f9a:	06a78793          	addi	a5,a5,106 # 80023000 <disk>
    80005f9e:	97aa                	add	a5,a5,a0
    80005fa0:	6509                	lui	a0,0x2
    80005fa2:	953e                	add	a0,a0,a5
    80005fa4:	4785                	li	a5,1
    80005fa6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005faa:	0001f517          	auipc	a0,0x1f
    80005fae:	06e50513          	addi	a0,a0,110 # 80025018 <disk+0x2018>
    80005fb2:	ffffc097          	auipc	ra,0xffffc
    80005fb6:	478080e7          	jalr	1144(ra) # 8000242a <wakeup>
}
    80005fba:	60a2                	ld	ra,8(sp)
    80005fbc:	6402                	ld	s0,0(sp)
    80005fbe:	0141                	addi	sp,sp,16
    80005fc0:	8082                	ret
    panic("free_desc 1");
    80005fc2:	00003517          	auipc	a0,0x3
    80005fc6:	92e50513          	addi	a0,a0,-1746 # 800088f0 <syscall_names+0x328>
    80005fca:	ffffa097          	auipc	ra,0xffffa
    80005fce:	574080e7          	jalr	1396(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005fd2:	00003517          	auipc	a0,0x3
    80005fd6:	92e50513          	addi	a0,a0,-1746 # 80008900 <syscall_names+0x338>
    80005fda:	ffffa097          	auipc	ra,0xffffa
    80005fde:	564080e7          	jalr	1380(ra) # 8000053e <panic>

0000000080005fe2 <virtio_disk_init>:
{
    80005fe2:	1101                	addi	sp,sp,-32
    80005fe4:	ec06                	sd	ra,24(sp)
    80005fe6:	e822                	sd	s0,16(sp)
    80005fe8:	e426                	sd	s1,8(sp)
    80005fea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fec:	00003597          	auipc	a1,0x3
    80005ff0:	92458593          	addi	a1,a1,-1756 # 80008910 <syscall_names+0x348>
    80005ff4:	0001f517          	auipc	a0,0x1f
    80005ff8:	13450513          	addi	a0,a0,308 # 80025128 <disk+0x2128>
    80005ffc:	ffffb097          	auipc	ra,0xffffb
    80006000:	b58080e7          	jalr	-1192(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006004:	100017b7          	lui	a5,0x10001
    80006008:	4398                	lw	a4,0(a5)
    8000600a:	2701                	sext.w	a4,a4
    8000600c:	747277b7          	lui	a5,0x74727
    80006010:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006014:	0ef71163          	bne	a4,a5,800060f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006018:	100017b7          	lui	a5,0x10001
    8000601c:	43dc                	lw	a5,4(a5)
    8000601e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006020:	4705                	li	a4,1
    80006022:	0ce79a63          	bne	a5,a4,800060f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006026:	100017b7          	lui	a5,0x10001
    8000602a:	479c                	lw	a5,8(a5)
    8000602c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000602e:	4709                	li	a4,2
    80006030:	0ce79363          	bne	a5,a4,800060f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006034:	100017b7          	lui	a5,0x10001
    80006038:	47d8                	lw	a4,12(a5)
    8000603a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000603c:	554d47b7          	lui	a5,0x554d4
    80006040:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006044:	0af71963          	bne	a4,a5,800060f6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006048:	100017b7          	lui	a5,0x10001
    8000604c:	4705                	li	a4,1
    8000604e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006050:	470d                	li	a4,3
    80006052:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006054:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006056:	c7ffe737          	lui	a4,0xc7ffe
    8000605a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000605e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006060:	2701                	sext.w	a4,a4
    80006062:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006064:	472d                	li	a4,11
    80006066:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006068:	473d                	li	a4,15
    8000606a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000606c:	6705                	lui	a4,0x1
    8000606e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006070:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006074:	5bdc                	lw	a5,52(a5)
    80006076:	2781                	sext.w	a5,a5
  if(max == 0)
    80006078:	c7d9                	beqz	a5,80006106 <virtio_disk_init+0x124>
  if(max < NUM)
    8000607a:	471d                	li	a4,7
    8000607c:	08f77d63          	bgeu	a4,a5,80006116 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006080:	100014b7          	lui	s1,0x10001
    80006084:	47a1                	li	a5,8
    80006086:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006088:	6609                	lui	a2,0x2
    8000608a:	4581                	li	a1,0
    8000608c:	0001d517          	auipc	a0,0x1d
    80006090:	f7450513          	addi	a0,a0,-140 # 80023000 <disk>
    80006094:	ffffb097          	auipc	ra,0xffffb
    80006098:	c4c080e7          	jalr	-948(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000609c:	0001d717          	auipc	a4,0x1d
    800060a0:	f6470713          	addi	a4,a4,-156 # 80023000 <disk>
    800060a4:	00c75793          	srli	a5,a4,0xc
    800060a8:	2781                	sext.w	a5,a5
    800060aa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800060ac:	0001f797          	auipc	a5,0x1f
    800060b0:	f5478793          	addi	a5,a5,-172 # 80025000 <disk+0x2000>
    800060b4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800060b6:	0001d717          	auipc	a4,0x1d
    800060ba:	fca70713          	addi	a4,a4,-54 # 80023080 <disk+0x80>
    800060be:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800060c0:	0001e717          	auipc	a4,0x1e
    800060c4:	f4070713          	addi	a4,a4,-192 # 80024000 <disk+0x1000>
    800060c8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060ca:	4705                	li	a4,1
    800060cc:	00e78c23          	sb	a4,24(a5)
    800060d0:	00e78ca3          	sb	a4,25(a5)
    800060d4:	00e78d23          	sb	a4,26(a5)
    800060d8:	00e78da3          	sb	a4,27(a5)
    800060dc:	00e78e23          	sb	a4,28(a5)
    800060e0:	00e78ea3          	sb	a4,29(a5)
    800060e4:	00e78f23          	sb	a4,30(a5)
    800060e8:	00e78fa3          	sb	a4,31(a5)
}
    800060ec:	60e2                	ld	ra,24(sp)
    800060ee:	6442                	ld	s0,16(sp)
    800060f0:	64a2                	ld	s1,8(sp)
    800060f2:	6105                	addi	sp,sp,32
    800060f4:	8082                	ret
    panic("could not find virtio disk");
    800060f6:	00003517          	auipc	a0,0x3
    800060fa:	82a50513          	addi	a0,a0,-2006 # 80008920 <syscall_names+0x358>
    800060fe:	ffffa097          	auipc	ra,0xffffa
    80006102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006106:	00003517          	auipc	a0,0x3
    8000610a:	83a50513          	addi	a0,a0,-1990 # 80008940 <syscall_names+0x378>
    8000610e:	ffffa097          	auipc	ra,0xffffa
    80006112:	430080e7          	jalr	1072(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006116:	00003517          	auipc	a0,0x3
    8000611a:	84a50513          	addi	a0,a0,-1974 # 80008960 <syscall_names+0x398>
    8000611e:	ffffa097          	auipc	ra,0xffffa
    80006122:	420080e7          	jalr	1056(ra) # 8000053e <panic>

0000000080006126 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006126:	7159                	addi	sp,sp,-112
    80006128:	f486                	sd	ra,104(sp)
    8000612a:	f0a2                	sd	s0,96(sp)
    8000612c:	eca6                	sd	s1,88(sp)
    8000612e:	e8ca                	sd	s2,80(sp)
    80006130:	e4ce                	sd	s3,72(sp)
    80006132:	e0d2                	sd	s4,64(sp)
    80006134:	fc56                	sd	s5,56(sp)
    80006136:	f85a                	sd	s6,48(sp)
    80006138:	f45e                	sd	s7,40(sp)
    8000613a:	f062                	sd	s8,32(sp)
    8000613c:	ec66                	sd	s9,24(sp)
    8000613e:	e86a                	sd	s10,16(sp)
    80006140:	1880                	addi	s0,sp,112
    80006142:	892a                	mv	s2,a0
    80006144:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006146:	00c52c83          	lw	s9,12(a0)
    8000614a:	001c9c9b          	slliw	s9,s9,0x1
    8000614e:	1c82                	slli	s9,s9,0x20
    80006150:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006154:	0001f517          	auipc	a0,0x1f
    80006158:	fd450513          	addi	a0,a0,-44 # 80025128 <disk+0x2128>
    8000615c:	ffffb097          	auipc	ra,0xffffb
    80006160:	a88080e7          	jalr	-1400(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006164:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006166:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006168:	0001db97          	auipc	s7,0x1d
    8000616c:	e98b8b93          	addi	s7,s7,-360 # 80023000 <disk>
    80006170:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006172:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006174:	8a4e                	mv	s4,s3
    80006176:	a051                	j	800061fa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006178:	00fb86b3          	add	a3,s7,a5
    8000617c:	96da                	add	a3,a3,s6
    8000617e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006182:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006184:	0207c563          	bltz	a5,800061ae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006188:	2485                	addiw	s1,s1,1
    8000618a:	0711                	addi	a4,a4,4
    8000618c:	25548063          	beq	s1,s5,800063cc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006190:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006192:	0001f697          	auipc	a3,0x1f
    80006196:	e8668693          	addi	a3,a3,-378 # 80025018 <disk+0x2018>
    8000619a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000619c:	0006c583          	lbu	a1,0(a3)
    800061a0:	fde1                	bnez	a1,80006178 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061a2:	2785                	addiw	a5,a5,1
    800061a4:	0685                	addi	a3,a3,1
    800061a6:	ff879be3          	bne	a5,s8,8000619c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061aa:	57fd                	li	a5,-1
    800061ac:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061ae:	02905a63          	blez	s1,800061e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061b2:	f9042503          	lw	a0,-112(s0)
    800061b6:	00000097          	auipc	ra,0x0
    800061ba:	d90080e7          	jalr	-624(ra) # 80005f46 <free_desc>
      for(int j = 0; j < i; j++)
    800061be:	4785                	li	a5,1
    800061c0:	0297d163          	bge	a5,s1,800061e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061c4:	f9442503          	lw	a0,-108(s0)
    800061c8:	00000097          	auipc	ra,0x0
    800061cc:	d7e080e7          	jalr	-642(ra) # 80005f46 <free_desc>
      for(int j = 0; j < i; j++)
    800061d0:	4789                	li	a5,2
    800061d2:	0097d863          	bge	a5,s1,800061e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061d6:	f9842503          	lw	a0,-104(s0)
    800061da:	00000097          	auipc	ra,0x0
    800061de:	d6c080e7          	jalr	-660(ra) # 80005f46 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061e2:	0001f597          	auipc	a1,0x1f
    800061e6:	f4658593          	addi	a1,a1,-186 # 80025128 <disk+0x2128>
    800061ea:	0001f517          	auipc	a0,0x1f
    800061ee:	e2e50513          	addi	a0,a0,-466 # 80025018 <disk+0x2018>
    800061f2:	ffffc097          	auipc	ra,0xffffc
    800061f6:	f60080e7          	jalr	-160(ra) # 80002152 <sleep>
  for(int i = 0; i < 3; i++){
    800061fa:	f9040713          	addi	a4,s0,-112
    800061fe:	84ce                	mv	s1,s3
    80006200:	bf41                	j	80006190 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006202:	20058713          	addi	a4,a1,512
    80006206:	00471693          	slli	a3,a4,0x4
    8000620a:	0001d717          	auipc	a4,0x1d
    8000620e:	df670713          	addi	a4,a4,-522 # 80023000 <disk>
    80006212:	9736                	add	a4,a4,a3
    80006214:	4685                	li	a3,1
    80006216:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000621a:	20058713          	addi	a4,a1,512
    8000621e:	00471693          	slli	a3,a4,0x4
    80006222:	0001d717          	auipc	a4,0x1d
    80006226:	dde70713          	addi	a4,a4,-546 # 80023000 <disk>
    8000622a:	9736                	add	a4,a4,a3
    8000622c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006230:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006234:	7679                	lui	a2,0xffffe
    80006236:	963e                	add	a2,a2,a5
    80006238:	0001f697          	auipc	a3,0x1f
    8000623c:	dc868693          	addi	a3,a3,-568 # 80025000 <disk+0x2000>
    80006240:	6298                	ld	a4,0(a3)
    80006242:	9732                	add	a4,a4,a2
    80006244:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006246:	6298                	ld	a4,0(a3)
    80006248:	9732                	add	a4,a4,a2
    8000624a:	4541                	li	a0,16
    8000624c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000624e:	6298                	ld	a4,0(a3)
    80006250:	9732                	add	a4,a4,a2
    80006252:	4505                	li	a0,1
    80006254:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006258:	f9442703          	lw	a4,-108(s0)
    8000625c:	6288                	ld	a0,0(a3)
    8000625e:	962a                	add	a2,a2,a0
    80006260:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006264:	0712                	slli	a4,a4,0x4
    80006266:	6290                	ld	a2,0(a3)
    80006268:	963a                	add	a2,a2,a4
    8000626a:	05890513          	addi	a0,s2,88
    8000626e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006270:	6294                	ld	a3,0(a3)
    80006272:	96ba                	add	a3,a3,a4
    80006274:	40000613          	li	a2,1024
    80006278:	c690                	sw	a2,8(a3)
  if(write)
    8000627a:	140d0063          	beqz	s10,800063ba <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000627e:	0001f697          	auipc	a3,0x1f
    80006282:	d826b683          	ld	a3,-638(a3) # 80025000 <disk+0x2000>
    80006286:	96ba                	add	a3,a3,a4
    80006288:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000628c:	0001d817          	auipc	a6,0x1d
    80006290:	d7480813          	addi	a6,a6,-652 # 80023000 <disk>
    80006294:	0001f517          	auipc	a0,0x1f
    80006298:	d6c50513          	addi	a0,a0,-660 # 80025000 <disk+0x2000>
    8000629c:	6114                	ld	a3,0(a0)
    8000629e:	96ba                	add	a3,a3,a4
    800062a0:	00c6d603          	lhu	a2,12(a3)
    800062a4:	00166613          	ori	a2,a2,1
    800062a8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062ac:	f9842683          	lw	a3,-104(s0)
    800062b0:	6110                	ld	a2,0(a0)
    800062b2:	9732                	add	a4,a4,a2
    800062b4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062b8:	20058613          	addi	a2,a1,512
    800062bc:	0612                	slli	a2,a2,0x4
    800062be:	9642                	add	a2,a2,a6
    800062c0:	577d                	li	a4,-1
    800062c2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062c6:	00469713          	slli	a4,a3,0x4
    800062ca:	6114                	ld	a3,0(a0)
    800062cc:	96ba                	add	a3,a3,a4
    800062ce:	03078793          	addi	a5,a5,48
    800062d2:	97c2                	add	a5,a5,a6
    800062d4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800062d6:	611c                	ld	a5,0(a0)
    800062d8:	97ba                	add	a5,a5,a4
    800062da:	4685                	li	a3,1
    800062dc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062de:	611c                	ld	a5,0(a0)
    800062e0:	97ba                	add	a5,a5,a4
    800062e2:	4809                	li	a6,2
    800062e4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800062e8:	611c                	ld	a5,0(a0)
    800062ea:	973e                	add	a4,a4,a5
    800062ec:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062f0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800062f4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062f8:	6518                	ld	a4,8(a0)
    800062fa:	00275783          	lhu	a5,2(a4)
    800062fe:	8b9d                	andi	a5,a5,7
    80006300:	0786                	slli	a5,a5,0x1
    80006302:	97ba                	add	a5,a5,a4
    80006304:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006308:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000630c:	6518                	ld	a4,8(a0)
    8000630e:	00275783          	lhu	a5,2(a4)
    80006312:	2785                	addiw	a5,a5,1
    80006314:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006318:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000631c:	100017b7          	lui	a5,0x10001
    80006320:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006324:	00492703          	lw	a4,4(s2)
    80006328:	4785                	li	a5,1
    8000632a:	02f71163          	bne	a4,a5,8000634c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000632e:	0001f997          	auipc	s3,0x1f
    80006332:	dfa98993          	addi	s3,s3,-518 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006336:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006338:	85ce                	mv	a1,s3
    8000633a:	854a                	mv	a0,s2
    8000633c:	ffffc097          	auipc	ra,0xffffc
    80006340:	e16080e7          	jalr	-490(ra) # 80002152 <sleep>
  while(b->disk == 1) {
    80006344:	00492783          	lw	a5,4(s2)
    80006348:	fe9788e3          	beq	a5,s1,80006338 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000634c:	f9042903          	lw	s2,-112(s0)
    80006350:	20090793          	addi	a5,s2,512
    80006354:	00479713          	slli	a4,a5,0x4
    80006358:	0001d797          	auipc	a5,0x1d
    8000635c:	ca878793          	addi	a5,a5,-856 # 80023000 <disk>
    80006360:	97ba                	add	a5,a5,a4
    80006362:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006366:	0001f997          	auipc	s3,0x1f
    8000636a:	c9a98993          	addi	s3,s3,-870 # 80025000 <disk+0x2000>
    8000636e:	00491713          	slli	a4,s2,0x4
    80006372:	0009b783          	ld	a5,0(s3)
    80006376:	97ba                	add	a5,a5,a4
    80006378:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000637c:	854a                	mv	a0,s2
    8000637e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006382:	00000097          	auipc	ra,0x0
    80006386:	bc4080e7          	jalr	-1084(ra) # 80005f46 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000638a:	8885                	andi	s1,s1,1
    8000638c:	f0ed                	bnez	s1,8000636e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000638e:	0001f517          	auipc	a0,0x1f
    80006392:	d9a50513          	addi	a0,a0,-614 # 80025128 <disk+0x2128>
    80006396:	ffffb097          	auipc	ra,0xffffb
    8000639a:	902080e7          	jalr	-1790(ra) # 80000c98 <release>
}
    8000639e:	70a6                	ld	ra,104(sp)
    800063a0:	7406                	ld	s0,96(sp)
    800063a2:	64e6                	ld	s1,88(sp)
    800063a4:	6946                	ld	s2,80(sp)
    800063a6:	69a6                	ld	s3,72(sp)
    800063a8:	6a06                	ld	s4,64(sp)
    800063aa:	7ae2                	ld	s5,56(sp)
    800063ac:	7b42                	ld	s6,48(sp)
    800063ae:	7ba2                	ld	s7,40(sp)
    800063b0:	7c02                	ld	s8,32(sp)
    800063b2:	6ce2                	ld	s9,24(sp)
    800063b4:	6d42                	ld	s10,16(sp)
    800063b6:	6165                	addi	sp,sp,112
    800063b8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063ba:	0001f697          	auipc	a3,0x1f
    800063be:	c466b683          	ld	a3,-954(a3) # 80025000 <disk+0x2000>
    800063c2:	96ba                	add	a3,a3,a4
    800063c4:	4609                	li	a2,2
    800063c6:	00c69623          	sh	a2,12(a3)
    800063ca:	b5c9                	j	8000628c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063cc:	f9042583          	lw	a1,-112(s0)
    800063d0:	20058793          	addi	a5,a1,512
    800063d4:	0792                	slli	a5,a5,0x4
    800063d6:	0001d517          	auipc	a0,0x1d
    800063da:	cd250513          	addi	a0,a0,-814 # 800230a8 <disk+0xa8>
    800063de:	953e                	add	a0,a0,a5
  if(write)
    800063e0:	e20d11e3          	bnez	s10,80006202 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800063e4:	20058713          	addi	a4,a1,512
    800063e8:	00471693          	slli	a3,a4,0x4
    800063ec:	0001d717          	auipc	a4,0x1d
    800063f0:	c1470713          	addi	a4,a4,-1004 # 80023000 <disk>
    800063f4:	9736                	add	a4,a4,a3
    800063f6:	0a072423          	sw	zero,168(a4)
    800063fa:	b505                	j	8000621a <virtio_disk_rw+0xf4>

00000000800063fc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063fc:	1101                	addi	sp,sp,-32
    800063fe:	ec06                	sd	ra,24(sp)
    80006400:	e822                	sd	s0,16(sp)
    80006402:	e426                	sd	s1,8(sp)
    80006404:	e04a                	sd	s2,0(sp)
    80006406:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006408:	0001f517          	auipc	a0,0x1f
    8000640c:	d2050513          	addi	a0,a0,-736 # 80025128 <disk+0x2128>
    80006410:	ffffa097          	auipc	ra,0xffffa
    80006414:	7d4080e7          	jalr	2004(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006418:	10001737          	lui	a4,0x10001
    8000641c:	533c                	lw	a5,96(a4)
    8000641e:	8b8d                	andi	a5,a5,3
    80006420:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006422:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006426:	0001f797          	auipc	a5,0x1f
    8000642a:	bda78793          	addi	a5,a5,-1062 # 80025000 <disk+0x2000>
    8000642e:	6b94                	ld	a3,16(a5)
    80006430:	0207d703          	lhu	a4,32(a5)
    80006434:	0026d783          	lhu	a5,2(a3)
    80006438:	06f70163          	beq	a4,a5,8000649a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000643c:	0001d917          	auipc	s2,0x1d
    80006440:	bc490913          	addi	s2,s2,-1084 # 80023000 <disk>
    80006444:	0001f497          	auipc	s1,0x1f
    80006448:	bbc48493          	addi	s1,s1,-1092 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000644c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006450:	6898                	ld	a4,16(s1)
    80006452:	0204d783          	lhu	a5,32(s1)
    80006456:	8b9d                	andi	a5,a5,7
    80006458:	078e                	slli	a5,a5,0x3
    8000645a:	97ba                	add	a5,a5,a4
    8000645c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000645e:	20078713          	addi	a4,a5,512
    80006462:	0712                	slli	a4,a4,0x4
    80006464:	974a                	add	a4,a4,s2
    80006466:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000646a:	e731                	bnez	a4,800064b6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000646c:	20078793          	addi	a5,a5,512
    80006470:	0792                	slli	a5,a5,0x4
    80006472:	97ca                	add	a5,a5,s2
    80006474:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006476:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000647a:	ffffc097          	auipc	ra,0xffffc
    8000647e:	fb0080e7          	jalr	-80(ra) # 8000242a <wakeup>

    disk.used_idx += 1;
    80006482:	0204d783          	lhu	a5,32(s1)
    80006486:	2785                	addiw	a5,a5,1
    80006488:	17c2                	slli	a5,a5,0x30
    8000648a:	93c1                	srli	a5,a5,0x30
    8000648c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006490:	6898                	ld	a4,16(s1)
    80006492:	00275703          	lhu	a4,2(a4)
    80006496:	faf71be3          	bne	a4,a5,8000644c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000649a:	0001f517          	auipc	a0,0x1f
    8000649e:	c8e50513          	addi	a0,a0,-882 # 80025128 <disk+0x2128>
    800064a2:	ffffa097          	auipc	ra,0xffffa
    800064a6:	7f6080e7          	jalr	2038(ra) # 80000c98 <release>
}
    800064aa:	60e2                	ld	ra,24(sp)
    800064ac:	6442                	ld	s0,16(sp)
    800064ae:	64a2                	ld	s1,8(sp)
    800064b0:	6902                	ld	s2,0(sp)
    800064b2:	6105                	addi	sp,sp,32
    800064b4:	8082                	ret
      panic("virtio_disk_intr status");
    800064b6:	00002517          	auipc	a0,0x2
    800064ba:	4ca50513          	addi	a0,a0,1226 # 80008980 <syscall_names+0x3b8>
    800064be:	ffffa097          	auipc	ra,0xffffa
    800064c2:	080080e7          	jalr	128(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
