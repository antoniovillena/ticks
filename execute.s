
        .equ    fast,   1

.data
.global st, sttap, stint, counter, mem, v, intr, tap, pc, start, endd
.global sp, mp, t, u, ff, ff_, fa, fa_, fb, fb_, fr, fr_    
.global a, c, b, e, d, l, h, a_, c_, b_, e_, d_, l_, h_
.global xl, xh, yl, yh, i, r, rs, prefix, iff, im, w, halted

        .align
st:     .word   0
sthi:   .word   0
sttap:  .quad   0
stint:  .quad   0
counter:.quad   100000000
v:      .word   0
intr:   .word   0
tap:    .word   0
mem:    .word   0
ff:     .short  0
pc:     .short  0
fa:     .short  0
sp:     .short  0
fb:     .short  0
c:      .byte   0
b:      .byte   0
fr:     .short  0
e:      .byte   0
d:      .byte   0
mp:     .short  0
l:      .byte   0
h:      .byte   0
prefix: .byte   0
rs:     .byte   0
r:      .byte   0
a:      .byte   0
start:  .short  0
xl:     .byte   0
xh:     .byte   0
dummy2: .byte   0
i:      .byte   0
yl:     .byte   0
yh:     .byte   0
t:      .short  0
u:      .short  0
fa_:    .short  0
fb_:    .short  0
ff_:    .short  0
fr_:    .short  0
c_:     .byte   0
b_:     .byte   0
e_:     .byte   0
d_:     .byte   0
dummy1: .short  0
l_:     .byte   0
h_:     .byte   0
endd:   .short  0
a_:     .byte   0
im:     .byte   0
iff:    .byte   0
halted: .byte   0
w:      .byte   0

        .equ    ost,      -44
        .equ    osthi,    4+ost
        .equ    osttap,   4+osthi
        .equ    ostint,   8+osttap
        .equ    ocounter, 8+ostint
        .equ    ov,       8+ocounter
        .equ    ointr,    4+ov
        .equ    otap,     4+ointr
        .equ    omem,     4+otap
        .equ    off,      4+omem
        .equ    opc,      2+off
        .equ    ofa,      2+opc
        .equ    osp,      2+ofa
        .equ    ofb,      2+osp
        .equ    oc,       2+ofb
        .equ    ob,       1+oc
        .equ    ofr,      1+ob
        .equ    oe,       2+ofr
        .equ    od,       1+oe
        .equ    omp,      1+od
        .equ    ol,       2+omp
        .equ    oh,       1+ol
        .equ    oprefix,  1+oh
        .equ    ors,      1+oprefix
        .equ    or,       1+ors
        .equ    oa,       1+or
        .equ    ostart,   1+oa
        .equ    oxl,      2+ostart
        .equ    oxh,      1+oxl
        .equ    odummy2,  1+oxh
        .equ    oi,       1+odummy2
        .equ    oyl,      1+oi
        .equ    oyh,      1+oyl
        .equ    ot,       1+oyh
        .equ    ou,       2+ot
        .equ    ofa_,     2+ou
        .equ    ofb_,     2+ofa_
        .equ    off_,     2+ofb_
        .equ    ofr_,     2+off_
        .equ    oc_,      2+ofr_
        .equ    ob_,      1+oc_
        .equ    oe_,      1+ob_
        .equ    od_,      1+oe_
        .equ    odummy1,  1+od_
        .equ    ol_,      2+odummy1
        .equ    oh_,      1+ol_
        .equ    oendd,    1+oh_
        .equ    oa_,      2+oendd
        .equ    oim,      1+oa_
        .equ    oiff,     1+im
        .equ    ohalted,  1+oiff
        .equ    ow,       1+ohalted

        punt    .req      r0
        mem     .req      r1
        stlo    .req      r2
        pcff    .req      r3
        spfa    .req      r4
        bcfb    .req      r5
        defr    .req      r6
        hlmp    .req      r7
        arvpref .req      r8
        ixstart .req      r9
        iyi     .req      r12

      .macro    TIME  cycles
        adds    stlo, stlo, #\cycles
        blcs    insth
      .endm

      .macro    PREFIX0
      .if fast==0
        bic     arvpref, #0xff
      .endif
        b       salida
      .endm

      .macro    PREFIX1
      .if fast==0
        bic     arvpref, #0xff
        add     arvpref, arvpref, #1
      .endif
        b       salida
      .endm

      .macro    PREFIX2
      .if fast==0
        orr     arvpref, #0xff
      .endif
        b       salida
      .endm

      .macro    LDRRIM  regis
        TIME    10
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00020000
        pkhbt   \regis, \regis, lr, lsl #16
        PREFIX0
      .endm

      .macro    LDRIM   regis, ofs
        TIME    7
        bic     \regis, #0x00ff0000 << \ofs
        ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        orr     \regis, lr, lsl #16+\ofs
        PREFIX0
      .endm

      .macro    LDRRPNN regis, cycl
        TIME    \cycl
        ldr     lr, [mem, pcff, lsr #16]
        mov     lr, lr, lsl #16
        ldr     r11, [mem, lr, lsr #16]
        pkhbt   \regis, \regis, r11, lsl #16
        add     pcff, #0x00020000
        add     lr, #0x00010000
        pkhtb   hlmp, hlmp, lr, asr #16
        PREFIX0
      .endm

      .macro    LDPNNRR regis, cycl
        TIME    \cycl
        ldr     lr, [mem, pcff, lsr #16]
        uxtah   r11, mem, lr
        mov     r10, \regis, lsr #16
        strh    r10, [r11]
        add     pcff, #0x00020000
        add     lr, #0x00000001
        pkhtb   hlmp, hlmp, lr
      .endm

      .macro    LDXX    dst, ofd, src, ofs
        TIME    4
        bic     \dst, #0x00ff0000 << \ofd
        and     lr, \src, #0x00ff0000 << \ofs
      .if \ofs-\ofd==-8
        orr     \dst, lr, ror #24
      .else
        orr     \dst, lr, ror #\ofs-\ofd
      .endif
        PREFIX0
      .endm

      .macro    INC     regis, ofs
        TIME    4
      .if \ofs==0
        and     lr, \regis, #0x00ff0000
        pkhtb   spfa, spfa, lr, asr #16
      .else
        mov     lr, \regis, lsr #24
        pkhtb   spfa, spfa, lr
      .endif
        mov     lr, #0x00000001
        pkhtb   bcfb, bcfb, lr
        uadd8   lr, lr, spfa
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        and     r11, pcff, #0x00000100
        orr     lr, r11
        pkhtb   pcff, pcff, lr
        PREFIX0
      .endm

      .macro    DEC     regis, ofs
        TIME    4
      .if \ofs==0
        and     lr, \regis, #0x00ff0000
        pkhtb   spfa, spfa, lr, asr #16
      .else
        mov     lr, \regis, lsr #24
        pkhtb   spfa, spfa, lr
      .endif
        mov     lr, #0xffff00ff
        pkhtb   bcfb, bcfb, lr, asr #16
        uadd8   lr, lr, spfa
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        and     r11, pcff, #0x00000100
        orr     lr, r11
        pkhtb   pcff, pcff, lr
        PREFIX0
      .endm

      .macro    INCPI   regis
        TIME    19
        add     r11, lr, \regis, lsr #16
        ldrb    lr, [mem, r11]
        pkhtb   spfa, spfa, lr
        mov     lr, #0x00000001
        pkhtb   bcfb, bcfb, lr
        add     lr, spfa
        strb    lr, [mem, r11]
        uxtb    lr, lr
        pkhtb   defr, defr, lr
        and     r11, pcff, #0x00000100
        orr     lr, r11
        pkhtb   pcff, pcff, lr
        PREFIX0
      .endm

      .macro    DECPI   regis
        TIME    19
        add     r11, lr, \regis, lsr #16
        ldrb    lr, [mem, r11]
        pkhtb   spfa, spfa, lr
        mov     lr, #0xffffffff
        pkhtb   bcfb, bcfb, lr
        add     lr, spfa
        strb    lr, [mem, r11]
        uxtb    lr, lr
        pkhtb   defr, defr, lr
        and     r11, pcff, #0x00000100
        orr     lr, r11
        pkhtb   pcff, pcff, lr
        PREFIX0
      .endm

      .macro    XADD    regis, ofs, cycl
        TIME    \cycl
        mov     r11, arvpref, lsr #24
        pkhtb   spfa, spfa, r11
    .if \ofs==0
        and     lr, \regis, #0x00ff0000
        pkhtb   bcfb, bcfb, lr, asr #16
    .else
      .if \ofs<24
        mov     lr, \regis, lsr #24
      .endif
        pkhtb   bcfb, bcfb, lr
    .endif
        add     lr, spfa, bcfb
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        pkhtb   defr, defr, lr
        PREFIX0
      .endm

      .macro    XADC    regis, ofs, cycl
        TIME    \cycl
        mov     r11, arvpref, lsr #24
        pkhtb   spfa, spfa, r11
    .if \ofs==0
        and     lr, \regis, #0x00ff0000
        pkhtb   bcfb, bcfb, lr, asr #16
    .else
      .if \ofs<24
        mov     lr, \regis, lsr #24
      .endif
        pkhtb   bcfb, bcfb, lr
    .endif
        movs    lr, pcff, lsl #24
        adc     lr, spfa, bcfb
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        pkhtb   defr, defr, lr
        PREFIX0
      .endm

      .macro    XSUB    regis, ofs, cycl
        TIME    \cycl
        mov     r11, arvpref, lsr #24
        pkhtb   spfa, spfa, r11
      .if \ofs<24
        uxtb    lr, \regis, ror #16+\ofs
      .endif
        mvn     lr, lr
        pkhtb   bcfb, bcfb, lr
        add     lr, r11
        add     lr, #0x00000001
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        pkhtb   defr, defr, lr
        PREFIX0
      .endm

      .macro    XSBC    regis, ofs, cycl
        TIME    \cycl
        mov     r11, arvpref, lsr #24
        pkhtb   spfa, spfa, r11
      .if \ofs<24
        uxtb    lr, \regis, ror #16+\ofs
      .endif
        mvn     lr, lr
        pkhtb   bcfb, bcfb, lr
        eor     lr, pcff, #0x00000100
        movs    lr, lr, lsl #24
        adc     lr, spfa, bcfb
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        pkhtb   defr, defr, lr
        PREFIX0
      .endm

      .macro    XAND    regis, ofs, cycl
        TIME    \cycl
    .if \ofs==24
        mov     r10, #0xffffff00
        orr     lr, r10
        and     arvpref, lr, ror #8
    .else
      .if \ofs==0
        mov     lr, #0xff00ffff
        orr     lr, \regis
        and     arvpref, lr, ror #24
      .else
        mov     lr, #0x00ffffff
        orr     lr, \regis
        and     arvpref, lr
      .endif
    .endif
        mov     lr, arvpref, lsr #24
        pkhtb   bcfb, bcfb, lr, asr #16
        pkhtb   defr, defr, lr
        pkhtb   pcff, pcff, lr
        mvn     lr, lr
        pkhtb   spfa, spfa, lr
        PREFIX0
      .endm

      .macro    XOR     regis, ofs, cycl
        TIME    \cycl
      .if \ofs==24
        eor     arvpref, lr, lsl #24
      .else
        and     lr, \regis, #0x00ff0000 << \ofs
        eor     arvpref, lr, lsl #8-\ofs
      .endif
        mov     lr, arvpref, lsr #24
        pkhtb   defr, defr, lr
        pkhtb   pcff, pcff, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        PREFIX0
      .endm

      .macro    OR      regis, ofs, cycl
        TIME    \cycl
      .if \ofs==24
        orr     arvpref, lr, lsl #24
      .else
        and     lr, \regis, #0x00ff0000 << \ofs
        orr     arvpref, lr, lsl #8-\ofs
      .endif
        mov     lr, arvpref, lsr #24
        pkhtb   defr, defr, lr
        pkhtb   pcff, pcff, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        PREFIX0
      .endm

      .macro    CP      regis, ofs, cycl
        TIME    \cycl
        mov     r11, arvpref, lsr #24
        pkhtb   spfa, spfa, r11
    .if \ofs==24
        mvn     r11, lr
        pkhtb   bcfb, bcfb, r11
        sub     r10, spfa, lr
        and     r11, r10, #0x000000ff
        pkhtb   defr, defr, r11
        eor     r10, lr
        and     r10, #0xffffffd7
        eor     r10, lr
    .else
      .if \ofs==0
        and     lr, \regis, #0x00ff0000
        mvn     r11, lr, asr #16
        pkhtb   bcfb, bcfb, r11
        sub     r10, spfa, lr, asr #16
        and     r11, r10, #0x000000ff
        pkhtb   defr, defr, r11
        eor     r10, lr, lsr #16
        and     r10, #0xffffffd7
        eor     r10, lr, lsr #16
      .else
        mov     lr, \regis, lsr #24
        mvn     r11, lr
        pkhtb   bcfb, bcfb, r11
        sub     r10, spfa, lr
        and     r11, r10, #0x000000ff
        pkhtb   defr, defr, r11
        eor     r10, lr
        and     r10, #0xffffffd7
        eor     r10, lr
      .endif
    .endif
        pkhtb   pcff, pcff, r10
        PREFIX0
      .endm

      .macro    INCW    regis
        TIME    6
        add     \regis, #0x00010000
        PREFIX0
      .endm

      .macro    DECW    regis
        TIME    6
        sub     \regis, #0x00010000
        PREFIX0
      .endm

      .macro    CALLC
        beq     callnn
        TIME    10
        add     pcff, #0x00020000
        PREFIX0
      .endm

      .macro    CALLCI
        bne     callnn
        TIME    10
        add     pcff, #0x00020000
        PREFIX0
      .endm

      .macro    JPC
        beq     jpcc
        TIME    10
        add     pcff, #0x00020000
        PREFIX0
      .endm

      .macro    JPCI
        bne     jpcc
        TIME    10
        add     pcff, #0x00020000
        PREFIX0
      .endm

      .macro    RETC
        beq     ret11
        TIME    5
        PREFIX0
      .endm

      .macro    RETCI
        bne     ret11
        TIME    5
        PREFIX0
      .endm

      .macro    LDRP    src, dst, ofs
        TIME    7
        mov     r11, \src, lsr #16
        ldrb    lr, [mem, r11]
        bic     \dst, #0x00ff0000 << \ofs
        orr     \dst, \dst, lr, lsl #16+\ofs
        add     r11, #1 
        pkhtb   hlmp, hlmp, r11
        PREFIX0
      .endm

      .macro    LDRPI   src, dst, ofs
        TIME    15
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, \src, lr, lsl #16
        ldrb    lr, [mem, lr, lsr #16]
        bic     \dst, #0x00ff0000 << \ofs
        orr     \dst, lr, lsl #16+\ofs
        PREFIX0
      .endm

      .macro    LDPR    src, dst, ofs
        TIME    7
        mov     lr, \dst, lsr #16+\ofs
        strb    lr, [mem, \src, lsr #16]
        mov     lr, #0x00010000
        uadd8   lr, lr, \src
        pkhtb   hlmp, hlmp, lr, asr #16
        PREFIX0
      .endm

      .macro    LDPRI   src, dst, ofs
        TIME    15
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, \src, lr, lsl #16
        mov     r11, \dst, lsr #16+\ofs
        strb    r11, [mem, lr, lsr #16]
        PREFIX0
      .endm

      .macro    LDPIM   src
        TIME    15
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00020000
        mov     r11, lr, lsr #8
        sxtb    lr, lr
        add     lr, \src, lr, lsl #16
        strb    r11, [mem, lr, lsr #16]
        PREFIX0
      .endm

      .macro    RET     cycl
        TIME    \cycl
        ldr     lr, [mem, spfa, lsr #16]
        add     spfa, #0x00020000
        pkhtb   hlmp, hlmp, lr
        pkhbt   pcff, pcff, lr, lsl #16
      .endm

      .macro    JRC
        beq     jrnn
        TIME    7
        add     pcff, #0x00010000
        PREFIX0
      .endm

      .macro    JRCI
        bne     jrnn
        TIME    7
        add     pcff, #0x00010000
        PREFIX0
      .endm

      .macro    PUS     regis
        TIME    11
        sub     spfa, #0x00020000
        mov     lr, spfa, lsr #16
        mov     r11, \regis, lsr #16
        strh    r11, [mem, lr]
        PREFIX0
      .endm

      .macro    POPP    regis
        TIME    10
        ldr     lr, [mem, spfa, lsr #16]
        pkhbt   \regis, \regis, lr, lsl #16
        add     spfa, #0x00020000
      .endm

      .macro    RLC     regis, ofs
        TIME    8
        uxtb    lr, \regis, ror #16+\ofs
        add     lr, lr, lr, lsl #8
        pkhtb   pcff, pcff, lr, asr #7
        uxtb    lr, pcff
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        orr     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        b       salida
      .endm

      .macro    RLCX    regis, ofs
        add     lr, r10, r10, lsl #8
        pkhtb   pcff, pcff, lr, asr #7
        uxtb    lr, pcff
        pkhtb   defr, defr, lr
      .if \regis!=arvpref || \ofs!=0
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
      .endif
        orr     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, r11]
        TIME    8
        b       salida
      .endm

      .macro    RRC     regis, ofs
        TIME    8
      .if \ofs==0
        uxtb    lr, \regis, ror #16
        movs    lr, lr, lsr #1
      .else
        movs    lr, \regis, lsr #25
      .endif
        orrcs   lr, #0x00000180
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        orr     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        b       salida
      .endm

      .macro    RRCX    regis, ofs
        movs    lr, r10, lsr #1
        orrcs   lr, #0x00000180
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
      .if \regis!=arvpref || \ofs!=0
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
      .endif
        pkhtb   defr, defr, lr
        orr     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, r11]
        TIME    8
        b       salida
      .endm

      .macro    RL      regis, ofs
        TIME    8
        movs    lr, pcff, lsl #24
        uxtb    lr, \regis, ror #16+\ofs
        adc     lr, lr
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        b       salida
      .endm

      .macro    RLX    regis, ofs
        movs    lr, pcff, lsl #24
        adc     lr, r10, r10
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        pkhtb   defr, defr, lr
      .if \regis!=arvpref || \ofs!=0
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
      .endif
        orr     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, r11]
        TIME    8
        b       salida
      .endm

      .macro    RR      regis, ofs
        TIME    8
        uxtb    lr, \regis, ror #16+\ofs
        add     lr, lr, lr, lsl #9
        and     r10, pcff, #0x00000100
        orr     lr, r10
        pkhtb   pcff, pcff, lr, asr #1
        uxtb    lr, pcff
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        b       salida
      .endm

      .macro    RRX    regis, ofs
        add     lr, r10, r10, lsl #9
        tst     pcff, #0x00000100
        orrne   lr, #0x00000100
        pkhtb   pcff, pcff, lr, asr #1
        uxtb    lr, pcff
        pkhtb   defr, defr, lr
      .if \regis!=arvpref || \ofs!=0
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
      .endif
        orr     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, r11]
        TIME    8
        b       salida
      .endm

      .macro    SLA     regis, ofs
        TIME    8
        uxtb    lr, \regis, ror #16+\ofs
        mov     lr, lr, lsl #1
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        b       salida
      .endm

      .macro    SLAX    regis, ofs
        mov     lr, r10, lsl #1
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        pkhtb   defr, defr, lr
      .if \regis!=arvpref || \ofs!=0
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
      .endif
        orr     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, r11]
        TIME    8
        b       salida
      .endm

      .macro    SRA     regis, ofs
        TIME    8
        uxtb    lr, \regis, ror #16+\ofs
        add     lr, lr, lr, lsl #9
        tst     lr, #0x00000080
        orrne   lr, #0x00000100
        pkhtb   pcff, pcff, lr, asr #1
        uxtb    lr, pcff
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        b       salida
      .endm

      .macro    SRAX    regis, ofs
        add     lr, r10, r10, lsl #9
        tst     lr, #0x00000080
        orrne   lr, #0x00000100
        pkhtb   pcff, pcff, lr, asr #1
        uxtb    lr, pcff
        pkhtb   defr, defr, lr
      .if \regis!=arvpref || \ofs!=0
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
      .endif
        orr     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, r11]
        TIME    8
        b       salida
      .endm

      .macro    SLL     regis, ofs
        TIME    8
        uxtb    lr, \regis, ror #16+\ofs
        mov     lr, lr, lsl #1
        orr     lr, #0x00000001
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        b       salida
      .endm

      .macro    SLLX    regis, ofs
        mov     lr, r10, lsl #1
        orr     lr, #0x00000001
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        pkhtb   defr, defr, lr
      .if \regis!=arvpref || \ofs!=0
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
      .endif
        orr     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, r11]
        TIME    8
        b       salida
      .endm

      .macro    SRL     regis, ofs
        TIME    8
        uxtb    lr, \regis, ror #16+\ofs
        add     lr, lr, lr, lsl #9
        pkhtb   pcff, pcff, lr, asr #1
        uxtb    lr, pcff
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        b       salida
      .endm

      .macro    SRLX    regis, ofs
        add     lr, r10, r10, lsl #9
        orr     lr, #0x00000001
        pkhtb   pcff, pcff, lr, asr #1
        uxtb    lr, pcff
        pkhtb   defr, defr, lr
      .if \regis!=arvpref || \ofs!=0
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, lr, lsl #16+\ofs
      .endif
        orr     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, r11]
        TIME    8
        b       salida
      .endm

      .macro    BIT     const, regis, ofs
        TIME    8
        mov     lr, \regis, lsr #16+\ofs
        and     r11, lr, #\const
        pkhtb   defr, defr, r11
        and     lr, #0x00000028
        orr     lr, r11
        bic     pcff, #0x000000ff
        uxtab   pcff, pcff, lr
        mvn     r11, r11
        pkhtb   spfa, spfa, r11
        pkhtb   bcfb, bcfb, lr, asr #16
        b       salida
      .endm

      .macro    BITHL   const
        TIME    12
        ldrb    r10, [mem, hlmp, lsr #16]
        and     r10, #\const
        eor     lr, r10, hlmp, lsr #8
        and     lr, #0xffffffd7
        eor     lr, hlmp, lsr #8
        bic     pcff, #0x000000ff
        uxtab   pcff, pcff, lr
        pkhtb   defr, defr, r10
        mvn     lr, r10
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, r10, asr #16
        b       salida
      .endm

      .macro    RES     const, regis, ofs
        TIME    8
      .if \ofs==0
        and     \regis, #0xff00ffff | \const<<16
      .else
        and     \regis, #0x00ffffff | \const<<24
      .endif
        b       salida
      .endm

      .macro    RESHL   const
        TIME    15
        ldrb    lr, [mem, hlmp, lsr #16]
        and     lr, #\const
        strb    lr, [mem, hlmp, lsr #16]
        b       salida
      .endm

      .macro    RESXD   const, regis, ofs
        and     r10, #\const
        strb    r10, [mem, r11]
      .if \regis!=arvpref || \ofs!=0
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, r10, lsl #16+\ofs
      .endif
        TIME    8
        b       salida
      .endm

      .macro    SET     const, regis, ofs
        TIME    8
        orr     \regis, #\const<<(16+\ofs)
        b       salida
      .endm

      .macro    SETHL   const
        TIME    15
        ldrb    lr, [mem, hlmp, lsr #16]
        orr     lr, #\const
        strb    lr, [mem, hlmp, lsr #16]
        b       salida
      .endm

      .macro    SETXD   const, regis, ofs
        orr     r10, #\const
        strb    r10, [mem, r11]
      .if \regis!=arvpref || \ofs!=0
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, r10, lsl #16+\ofs
      .endif
        TIME    8
        b       salida
      .endm

      .macro    BITI    const
        TIME    5
        and     r10, #\const
        eor     lr, r10, hlmp, lsr #8
        and     lr, #0xffffffd7
        eor     lr, hlmp, lsr #8
        bic     pcff, #0x000000ff
        uxtab   pcff, pcff, lr
        pkhtb   defr, defr, r10
        mvn     lr, r10
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, r10, asr #16
        b       salida
      .endm

      .macro    EXSPI   regis
        TIME    19
        add     r10, mem, spfa, lsr #16
        mov     lr, \regis, lsr #16
        swpb    r11, lr, [r10]
        mov     lr, \regis, lsr #24
        add     r10, #1
        swpb    lr, lr, [r10]
        orr     lr, r11, lr, lsl #8
        pkhbt   \regis, \regis, lr, lsl #16
        pkhtb   hlmp, hlmp, lr
      .endm

      .macro    ADDRRRR dst, src
        TIME    11
        mov     lr, \src, lsr #16
        add     lr, \dst, lsr #16
        and     r11, lr, #0x00012800
        and     r10, pcff, #0x00000080
        orr     r10, r11, lsr #8
        pkhtb   pcff, pcff, r10
        eor     r11, defr, spfa
        eor     r10, \dst, \src
        eor     r10, lr, lsl #16
        eor     r11, r10, lsr #24
        and     r11, #0x00000010
        and     r10, bcfb, #0x00000080
        orr     r11, r10
        pkhtb   bcfb, bcfb, r11
        add     r11, \dst, #0x00010000
        pkhtb   hlmp, hlmp, r11, asr #16
        pkhbt   \dst, \dst, lr, lsl #16
        PREFIX0
      .endm

      .macro    ADCHLRR regis
        TIME    15
        movs    lr, pcff, lsl #24
        mov     r11, hlmp, lsr #16
        mov     r10, \regis, lsr #16
        adc     lr, r11, r10
        pkhtb   pcff, pcff, lr, asr #8
        pkhtb   spfa, spfa, r11, asr #8
        pkhtb   bcfb, bcfb, r10, asr #8
        add     r11, #1
        pkhbt   hlmp, r11, lr, lsl #16
        rev     lr, hlmp
        pkhtb   defr, defr, lr
        b       salida
      .endm

      .macro    SBCHLRR regis
        TIME    15
        eor     lr, pcff, #0x00000100
        movs    lr, lr, lsl #24
        mov     r11, hlmp, lsr #16
        sbc     lr, r11, \regis, lsr #16
        pkhtb   pcff, pcff, lr, asr #8
        pkhtb   spfa, spfa, r11, asr #8
        mvn     r10, \regis, lsr #24
        pkhtb   bcfb, bcfb, r10
        add     r11, #1
        pkhbt   hlmp, r11, lr, lsl #16
        rev     lr, hlmp
        pkhtb   defr, defr, lr
        b       salida
      .endm

      .macro    RST     addr
        TIME    11
        mov     lr, pcff, lsr #16
      .if \addr==0
        uxth    pcff, pcff
      .else
        mov     r11, #\addr
        pkhbt   pcff, pcff, r11, lsl #16
      .endif
        pkhtb   hlmp, hlmp, pcff, asr #16
        sub     spfa, #0x00020000
        mov     r11, spfa, lsr #16
        strh    lr, [mem, r11]
        PREFIX0
      .endm

      .macro    INR     regis, ofs
        TIME    12
        push    {r0-r3, r12}
        mov     r0, bcfb, lsr #16
        add     r11, r0, #0x00000001
        pkhtb   hlmp, hlmp, r11
        bl      in
      .if \regis!=arvpref || \ofs!=0
        bic     \regis, #0x00ff0000 << \ofs
        orr     \regis, r0, lsl #16+\ofs
      .endif
        pkhtb   defr, defr, r0
        bic     pcff, #0x000000ff
        orr     pcff, r0
        orr     r0, #0x00000100
        pkhtb   spfa, spfa, r0
        pkhtb   bcfb, bcfb, r0, asr #16
        pop     {r0-r3, r12}
        b       salida
      .endm

      .macro    OUTR    regis, ofs
        TIME    12
        push    {r0-r3, r12}
        mov     r0, bcfb, lsr #16
        add     r11, r0, #0x00000001
        pkhtb   hlmp, hlmp, r11
      .if \regis!=arvpref || \ofs!=0
        uxtb    r1, \regis, ror #16+\ofs
      .else
        mov     r1, #0x00000000
      .endif
        bl      out
        pop     {r0-r3, r12}
        b       salida
      .endm

/*      r0      punt
        r1      mem
        r2      stlo
        r3      pc | ff
        r4      sp | fa
        r5      bc | fb
        r6      de | fr
        r7      hl | mp
        r8      ar | r7 halted_3 iff_2 im : prefix
        r9      ix | start
        r12     iy | i : intr tap
*/

.text
.global execute
execute:push    {r4-r12, lr}
        ldr     punt, _mem
        ldr     stlo, [punt, #ost]
        ldm     punt, {mem, pcff, spfa, bcfb, defr, hlmp, arvpref, ixstart, iyi}
        ldr     lr, [punt, #ointr]
        tst     lr, lr
        orrne   iyi, #0x00000002
        ldr     lr, [punt, #otap]
        tst     lr, lr
        orrne   iyi, #0x00000001
        ldr     lr, [punt, #oim]      @ halted | iff im    0000000h i0000000 000000mm
        add     lr, lr, lsr #13
        uxtb    lr, lr
        orr     arvpref, lr, lsl #8
exec1:  ldrh    lr, [punt, #ostart]     @if( pc==start )
        cmp     lr, pcff, lsr #16       @  st= 0,
        bne     exec2                   @  stint= intr,
        mov     r11, #0x00000000        @  sttap= tap;
        str     r11, [punt, #osthi]
        ldr     r10, [punt, #ointr]
        strd    r10, [punt, #ostint]
        ldr     r10, [punt, #otap]
        strd    r10, [punt, #osttap]
exec2:  movs    lr, iyi, lsl #30
        beq     exec6
        bpl     exec5     
        ldrd    r10, [punt, #ostint]    @if( intr && st>stint && !prefix )
        ldr     lr, [punt, #osthi]
        cmp     r10, stlo
        sbcs    r11, lr
        bcs     exec5
      .if fast==0
        tst     arvpref, #0x000000ff
        bne     exec5
      .endif
        ldr     r10, [punt, #ointr]      @stint= st+intr
        adds    r10, stlo
        adc     r11, lr, #0x00000000
        strd    r10, [punt, #ostint]
        tst     arvpref, #0x00000400
        beq     exec5
        bic     arvpref, #0x00000400
        tst     arvpref, #0x00000800
        bicne   arvpref, #0x00000800
        addne   pcff, #0x00010000
        mov     r11, pcff, lsr #16
        sub     spfa, #0x00020000
        mov     r10, spfa, lsr #16
        strh    r11, [mem, r10]
        mov     r11, #0x00010000
        uadd8   arvpref, arvpref, r11
        movs    r11, arvpref, lsl #22
        beq     exec3
        bmi     exec4
        adds    stlo, #0x00000001
        blcs    insth
exec3:  mov     r11, #0x00380000
        pkhbt   pcff, pcff, r11
        adds    stlo, #0x0000000c
        blcs    insth
        b       exec5
exec4:  and     r11, iyi, #0x0000ff00
        orr     r11, #0x000000ff
        ldrh    r10, [mem, r11]
        pkhbt   pcff, pcff, r10, lsl #16
        adds    stlo, #0x00000013
        blcs    insth
exec5:  tst     iyi, #0x00000001
        beq     exec6
        ldrd    r10, [punt, #osttap]    @if( tap && st>sttap )
        ldr     lr, [punt, #osthi]
        cmp     r10, stlo
        sbcs    r11, lr
        bcs     exec6
        push    {r0-r3, r12}            @sttap= st+( tap= tapcycles() )
        mov     r11, lr
        bl      tapcycles
        mov     r10, r0
        pop     {r0-r3, r12}
        adds    r10, stlo
        adc     r11, #0x00000000
        strd    r10, [punt, #osttap]
exec6:  mov     lr, #0x00010000
        uadd8   arvpref, arvpref, lr
        ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        ldr     pc, [pc, lr, lsl #2]
_mem:   .word   mem
      .if fast==0
        .word   nop           @ 00 NOP
        .word   ldbcnn        @ 01 LD BC,nn
        .word   ldbca         @ 02 LD (BC),A
        .word   incbc         @ 03 INC BC
        .word   incb          @ 04 INC B
        .word   decb          @ 05 DEC B
        .word   ldbn          @ 06 LD B,n
        .word   rlca          @ 07 RLCA
        .word   exafaf        @ 08 EX AF,AF
        .word   addxxbc       @ 09 ADD HL,BC
        .word   ldabc         @ 0a LD A,(BC)
        .word   decbc         @ 0b DEC BC
        .word   incc          @ 0c INC C
        .word   decc          @ 0d DEC C
        .word   ldcn          @ 0e LD C,n
        .word   rrca          @ 0f RRCA
        .word   djnz          @ 10 DJNZ
        .word   lddenn        @ 11 LD DE,nn
        .word   lddea         @ 12 LD (DE),A
        .word   incde         @ 13 INC DE
        .word   incd          @ 14 INC D
        .word   decd          @ 15 DEC D
        .word   lddn          @ 16 LD D,n
        .word   rla           @ 17 RLA
        .word   jr            @ 18 JR
        .word   addxxde       @ 19 ADD HL,DE
        .word   ldade         @ 1a LD A,(DE)
        .word   decde         @ 1b DEC DE
        .word   ince          @ 1c INC E
        .word   dece          @ 1d DEC E
        .word   lden          @ 1e LD E,n
        .word   rra           @ 1f RRA
        .word   jrnz          @ 20 JR NZ,s8
        .word   ldxxnn        @ 21 LD HL,nn
        .word   ldpnnxx       @ 22 LD (nn),HL
        .word   inchlx        @ 23 INC HL
        .word   inchx         @ 24 INC H
        .word   dechx         @ 25 DEC H
        .word   lxhn          @ 26 LD H,n
        .word   daa           @ 27 DAA
        .word   jrz           @ 28 JR Z,s8
        .word   addxxxx       @ 29 ADD HL,HL
        .word   ldxxpnn       @ 2a LD HL,(nn)
        .word   dechlx        @ 2b DEC HL
        .word   inclx         @ 2c INC L
        .word   declx         @ 2d DEC L
        .word   lxln          @ 2e LD L,n
        .word   cpl           @ 2f CPL
        .word   jrnc          @ 30 JR NC,s8
        .word   ldspnn        @ 31 LD SP,nn
        .word   ldnna         @ 32 LD (nn),A
        .word   incsp         @ 33 INC SP
        .word   incpxx        @ 34 INC (HL)
        .word   decpxx        @ 35 DEC (HL)
        .word   ldxxn         @ 36 LD (HL),n
        .word   scf           @ 37 SCF
        .word   jrc           @ 38 JR C,s8
        .word   addxxsp       @ 39 ADD HL,SP
        .word   ldann         @ 3a LD A,(nn)
        .word   decsp         @ 3b DEC SP
        .word   inca          @ 3c INC A
        .word   deca          @ 3d DEC A
        .word   ldan          @ 3e LD A,n
        .word   ccf           @ 3f CCF
        .word   nop           @ 40 LD B,B
        .word   ldbc          @ 41 LD B,C
        .word   ldbd          @ 42 LD B,D
        .word   ldbe          @ 43 LD B,E
        .word   lxbh          @ 44 LD B,H
        .word   lxbl          @ 45 LD B,L
        .word   lxbhl         @ 46 LD B,(HL)
        .word   ldba          @ 47 LD B,A
        .word   ldcb          @ 48 LD C,B
        .word   nop           @ 49 LD C,C
        .word   ldcd          @ 4a LD C,D
        .word   ldce          @ 4b LD C,E
        .word   lxch          @ 4c LD C,H
        .word   lxcl          @ 4d LD C,L
        .word   lxchl         @ 4e LD C,(HL)
        .word   ldca          @ 4f LD C,A
        .word   lddb          @ 50 LD D,B
        .word   lddc          @ 51 LD D,C
        .word   nop           @ 52 LD D,D
        .word   ldde          @ 53 LD D,E
        .word   lxdh          @ 54 LD D,H
        .word   lxdl          @ 55 LD D,L
        .word   lxdhl         @ 56 LD D,(HL)
        .word   ldda          @ 57 LD D,A
        .word   ldeb          @ 58 LD E,B
        .word   ldec          @ 59 LD E,C
        .word   lded          @ 5a LD E,D
        .word   nop           @ 5b LD E,E
        .word   lxeh          @ 5c LD E,H
        .word   lxel          @ 5d LD E,L
        .word   lxehl         @ 5e LD E,(HL)
        .word   ldea          @ 5f LD E,A
        .word   lxhb          @ 60 LD H,B
        .word   lxhc          @ 61 LD H,C
        .word   lxhd          @ 62 LD H,D
        .word   lxhe          @ 63 LD H,E
        .word   nop           @ 64 LD H,H
        .word   lxhl          @ 65 LD H,L
        .word   lxhhl         @ 66 LD H,(HL)
        .word   lxha          @ 67 LD H,A
        .word   lxlb          @ 68 LD L,B
        .word   lxlc          @ 69 LD L,C
        .word   lxld          @ 6a LD L,D
        .word   lxle          @ 6b LD L,E
        .word   lxlh          @ 6c LD L,H
        .word   nop           @ 6d LD L,L
        .word   lxlhl         @ 6e LD L,(HL)
        .word   lxla          @ 6f LD L,A
        .word   ldxxb         @ 70 LD (HL),B
        .word   ldxxc         @ 71 LD (HL),C
        .word   ldxxd         @ 72 LD (HL),D
        .word   ldxxe         @ 73 LD (HL),E
        .word   ldxxh         @ 74 LD (HL),H
        .word   ldxxl         @ 75 LD (HL),L
        .word   halt          @ 76 HALT
        .word   ldxxa         @ 77 LD (HL),A
        .word   ldab          @ 78 LD A,B
        .word   ldac          @ 79 LD A,C
        .word   ldad          @ 7a LD A,D
        .word   ldae          @ 7b LD A,E
        .word   lxah          @ 7c LD A,H
        .word   lxal          @ 7d LD A,L
        .word   lxahl         @ 7e LD A,(HL)
        .word   nop           @ 7f LD A,A
        .word   addab         @ 80 ADD A,B
        .word   addac         @ 81 ADD A,C
        .word   addad         @ 82 ADD A,D
        .word   addae         @ 83 ADD A,E
        .word   addxh         @ 84 ADD A,H
        .word   addxl         @ 85 ADD A,L
        .word   addaxx        @ 86 ADD A,(HL)
        .word   addaa         @ 87 ADD A,A
        .word   adcab         @ 88 ADC A,B
        .word   adcac         @ 89 ADC A,C
        .word   adcad         @ 8a ADC A,D
        .word   adcae         @ 8b ADC A,E
        .word   adcahx        @ 8c ADC A,H
        .word   adcalx        @ 8d ADC A,L
        .word   adcaxx        @ 8e ADC A,(HL)
        .word   adcaa         @ 8f ADC A,A
        .word   subb          @ 90 SUB B
        .word   subc          @ 91 SUB C
        .word   subd          @ 92 SUB D
        .word   sube          @ 93 SUB E
        .word   subhx         @ 94 SUB H
        .word   sublx         @ 95 SUB L
        .word   subxx         @ 96 SUB (HL)
        .word   suba          @ 97 SUB A
        .word   sbcab         @ 98 SBC A,B
        .word   sbcac         @ 99 SBC A,C
        .word   sbcad         @ 9a SBC A,D
        .word   sbcae         @ 9b SBC A,E
        .word   sbcahx        @ 9c SBC A,H
        .word   sbcalx        @ 9d SBC A,L
        .word   sbcaxx        @ 9e SBC A,(HL)
        .word   sbcaa         @ 9f SBC A,A
        .word   andb          @ a0 AND B
        .word   andc          @ a1 AND C
        .word   andd          @ a2 AND D
        .word   ande          @ a3 AND E
        .word   andhx         @ a4 AND H
        .word   andlx         @ a5 AND L
        .word   andxx         @ a6 AND (HL)
        .word   anda          @ a7 AND A
        .word   xorb          @ a8 XOR B
        .word   xorc          @ a9 XOR C
        .word   xord          @ aa XOR D
        .word   xore          @ ab XOR E
        .word   xorhx         @ ac XOR H
        .word   xorlx         @ ad XOR L
        .word   xorxx         @ ae XOR (HL)
        .word   xora          @ af XOR A
        .word   orb           @ b0 OR B
        .word   orc           @ b1 OR C
        .word   ord           @ b2 OR D
        .word   ore           @ b3 OR E
        .word   orhx          @ b4 OR H
        .word   orlx          @ b5 OR L
        .word   orxx          @ b6 OR (HL)
        .word   ora           @ b7 OR A
        .word   cpb           @ b8 CP B
        .word   cpc           @ b9 CP C
        .word   cp_d          @ ba CP D
        .word   cpe           @ bb CP E
        .word   cphx          @ bc CP H
        .word   cplx          @ bd CP L
        .word   cpxx          @ be CP (HL)
        .word   cpa           @ bf CP A
        .word   retnz         @ c0 RET NZ
        .word   popbc         @ c1 POP BC
        .word   jpnz          @ c2 JP NZ
        .word   jpnn          @ c3 JP nn
        .word   callnz        @ c4 CALL NZ
        .word   pushbc        @ c5 PUSH BC
        .word   addan         @ c6 ADD A,n
        .word   rst00         @ c7 RST 0x00
        .word   retz          @ c8 RET Z
        .word   ret10         @ c9 RET
        .word   jpz           @ ca JP Z
        .word   opcb          @ cb op cb
        .word   callz         @ cc CALL Z
        .word   callnn        @ cd CALL NN
        .word   adcan         @ ce ADC A,n
        .word   rst08         @ cf RST 0x08
        .word   retnc         @ d0 RET NC
        .word   popde         @ d1 POP DE
        .word   jpnc          @ d2 JP NC
        .word   outna         @ d3 OUT (n),A
        .word   callnc        @ d4 CALL NC
        .word   pushde        @ d5 PUSH DE
        .word   subn          @ d6 SUB n
        .word   rst10         @ d7 RST 0x10
        .word   retc          @ d8 RET C
        .word   exx           @ d9 EXX
        .word   jpc           @ da JP C
        .word   inan          @ db IN A,(n)
        .word   callc         @ dc CALL C
        .word   opdd          @ dd OP dd
        .word   sbcan         @ de SBC A,n
        .word   rst18         @ df RST 0x18
        .word   retpo         @ e0 RET PO
        .word   popxx         @ e1 POP HL
        .word   jppo          @ e2 JP PO
        .word   exspxx        @ e3 EX (SP),HL
        .word   callpo        @ e4 CALL PO
        .word   pushxx        @ e5 PUSH HL
        .word   andan         @ e6 AND A,n
        .word   rst20         @ e7 RST 0x20
        .word   retpe         @ e8 RET PE
        .word   jpxx          @ e9 JP (HL)
        .word   jppe          @ ea JP PE
        .word   exdehl        @ eb EX DE,HL
        .word   callpe        @ ec CALL PE
        .word   oped          @ ed op ed
        .word   xoran         @ ee XOR A,n
        .word   rst28         @ ef RST 0x28
        .word   retp          @ f0 RET P
        .word   popaf         @ f1 POP AF
        .word   jpp           @ f2 JP P
        .word   di            @ f3 DI
        .word   callp         @ f4 CALL P
        .word   pushaf        @ f5 PUSH AF
        .word   oran          @ f6 OR A,n
        .word   rst30         @ f7 RST 0x30
        .word   retm          @ f8 RET M
        .word   ldspxx        @ f9 LD SP,HL
        .word   jpm           @ fa JP M
        .word   ei            @ fb EI
        .word   callm         @ fc CALL M
        .word   opfd          @ fd op fd
        .word   cpan          @ fe CP A,n
        .word   rst38         @ ff RST 0x38
      .else
        .word   nop           @ 00 NOP
        .word   ldbcnn        @ 01 LD BC,nn
        .word   ldbca         @ 02 LD (BC),A
        .word   incbc         @ 03 INC BC
        .word   incb          @ 04 INC B
        .word   decb          @ 05 DEC B
        .word   ldbn          @ 06 LD B,n
        .word   rlca          @ 07 RLCA
        .word   exafaf        @ 08 EX AF,AF
        .word   addhlbc       @ 09 ADD HL,BC
        .word   ldabc         @ 0a LD A,(BC)
        .word   decbc         @ 0b DEC BC
        .word   incc          @ 0c INC C
        .word   decc          @ 0d DEC C
        .word   ldcn          @ 0e LD C,n
        .word   rrca          @ 0f RRCA
        .word   djnz          @ 10 DJNZ
        .word   lddenn        @ 11 LD DE,nn
        .word   lddea         @ 12 LD (DE),A
        .word   incde         @ 13 INC DE
        .word   incd          @ 14 INC D
        .word   decd          @ 15 DEC D
        .word   lddn          @ 16 LD D,n
        .word   rla           @ 17 RLA
        .word   jr            @ 18 JR
        .word   addhlde       @ 19 ADD HL,DE
        .word   ldade         @ 1a LD A,(DE)
        .word   decde         @ 1b DEC DE
        .word   ince          @ 1c INC E
        .word   dece          @ 1d DEC E
        .word   lden          @ 1e LD E,n
        .word   rra           @ 1f RRA
        .word   jrnz          @ 20 JR NZ,s8
        .word   ldhlnn        @ 21 LD HL,nn
        .word   ldpnnhl       @ 22 LD (nn),HL
        .word   inchl         @ 23 INC HL
        .word   inch          @ 24 INC H
        .word   dech          @ 25 DEC H
        .word   ldhn          @ 26 LD H,n
        .word   daa           @ 27 DAA
        .word   jrz           @ 28 JR Z,s8
        .word   addhlhl       @ 29 ADD HL,HL
        .word   ldhlpnn       @ 2a LD HL,(nn)
        .word   dechl         @ 2b DEC HL
        .word   incl          @ 2c INC L
        .word   decl          @ 2d DEC L
        .word   ldln          @ 2e LD L,n
        .word   cpl           @ 2f CPL
        .word   jrnc          @ 30 JR NC,s8
        .word   ldspnn        @ 31 LD SP,nn
        .word   ldnna         @ 32 LD (nn),A
        .word   incsp         @ 33 INC SP
        .word   incphl        @ 34 INC (HL)
        .word   decphl        @ 35 DEC (HL)
        .word   ldhln         @ 36 LD (HL),n
        .word   scf           @ 37 SCF
        .word   jrc           @ 38 JR C,s8
        .word   addhlsp       @ 39 ADD HL,SP
        .word   ldann         @ 3a LD A,(nn)
        .word   decsp         @ 3b DEC SP
        .word   inca          @ 3c INC A
        .word   deca          @ 3d DEC A
        .word   ldan          @ 3e LD A,n
        .word   ccf           @ 3f CCF
        .word   nop           @ 40 LD B,B
        .word   ldbc          @ 41 LD B,C
        .word   ldbd          @ 42 LD B,D
        .word   ldbe          @ 43 LD B,E
        .word   ldbh          @ 44 LD B,H
        .word   ldbl          @ 45 LD B,L
        .word   ldbhl         @ 46 LD B,(HL)
        .word   ldba          @ 47 LD B,A
        .word   ldcb          @ 48 LD C,B
        .word   nop           @ 49 LD C,C
        .word   ldcd          @ 4a LD C,D
        .word   ldce          @ 4b LD C,E
        .word   ldch          @ 4c LD C,H
        .word   ldcl          @ 4d LD C,L
        .word   ldchl         @ 4e LD C,(HL)
        .word   ldca          @ 4f LD C,A
        .word   lddb          @ 50 LD D,B
        .word   lddc          @ 51 LD D,C
        .word   nop           @ 52 LD D,D
        .word   ldde          @ 53 LD D,E
        .word   lddh          @ 54 LD D,H
        .word   lddl          @ 55 LD D,L
        .word   lddhl         @ 56 LD D,(HL)
        .word   ldda          @ 57 LD D,A
        .word   ldeb          @ 58 LD E,B
        .word   ldec          @ 59 LD E,C
        .word   lded          @ 5a LD E,D
        .word   nop           @ 5b LD E,E
        .word   ldeh          @ 5c LD E,H
        .word   ldel          @ 5d LD E,L
        .word   ldehl         @ 5e LD E,(HL)
        .word   ldea          @ 5f LD E,A
        .word   ldhb          @ 60 LD H,B
        .word   ldhc          @ 61 LD H,C
        .word   ldhd          @ 62 LD H,D
        .word   ldhe          @ 63 LD H,E
        .word   nop           @ 64 LD H,H
        .word   ldhl          @ 65 LD H,L
        .word   ldhhl         @ 66 LD H,(HL)
        .word   ldha          @ 67 LD H,A
        .word   ldlb          @ 68 LD L,B
        .word   ldlc          @ 69 LD L,C
        .word   ldld          @ 6a LD L,D
        .word   ldle          @ 6b LD L,E
        .word   ldlh          @ 6c LD L,H
        .word   nop           @ 6d LD L,L
        .word   ldlhl         @ 6e LD L,(HL)
        .word   ldla          @ 6f LD L,A
        .word   ldhlb         @ 70 LD (HL),B
        .word   ldhlc         @ 71 LD (HL),C
        .word   ldhld         @ 72 LD (HL),D
        .word   ldhle         @ 73 LD (HL),E
        .word   ldhlh         @ 74 LD (HL),H
        .word   ldhll         @ 75 LD (HL),L
        .word   halt          @ 76 HALT
        .word   ldhla         @ 77 LD (HL),A
        .word   ldab          @ 78 LD A,B
        .word   ldac          @ 79 LD A,C
        .word   ldad          @ 7a LD A,D
        .word   ldae          @ 7b LD A,E
        .word   ldah          @ 7c LD A,H
        .word   ldal          @ 7d LD A,L
        .word   ldahl         @ 7e LD A,(HL)
        .word   nop           @ 7f LD A,A
        .word   addab         @ 80 ADD A,B
        .word   addac         @ 81 ADD A,C
        .word   addad         @ 82 ADD A,D
        .word   addae         @ 83 ADD A,E
        .word   addah         @ 84 ADD A,H
        .word   addal         @ 85 ADD A,L
        .word   addahl        @ 86 ADD A,(HL)
        .word   addaa         @ 87 ADD A,A
        .word   adcab         @ 88 ADC A,B
        .word   adcac         @ 89 ADC A,C
        .word   adcad         @ 8a ADC A,D
        .word   adcae         @ 8b ADC A,E
        .word   adcah         @ 8c ADC A,H
        .word   adcal         @ 8d ADC A,L
        .word   adcahl        @ 8e ADC A,(HL)
        .word   adcaa         @ 8f ADC A,A
        .word   subb          @ 90 SUB B
        .word   subc          @ 91 SUB C
        .word   subd          @ 92 SUB D
        .word   sube          @ 93 SUB E
        .word   subh          @ 94 SUB H
        .word   subl          @ 95 SUB L
        .word   subhl         @ 96 SUB (HL)
        .word   suba          @ 97 SUB A
        .word   sbcab         @ 98 SBC A,B
        .word   sbcac         @ 99 SBC A,C
        .word   sbcad         @ 9a SBC A,D
        .word   sbcae         @ 9b SBC A,E
        .word   sbcah         @ 9c SBC A,H
        .word   sbcal         @ 9d SBC A,L
        .word   sbcahl        @ 9e SBC A,(HL)
        .word   sbcaa         @ 9f SBC A,A
        .word   andb          @ a0 AND B
        .word   andc          @ a1 AND C
        .word   andd          @ a2 AND D
        .word   ande          @ a3 AND E
        .word   andh          @ a4 AND H
        .word   andl          @ a5 AND L
        .word   andhl         @ a6 AND (HL)
        .word   anda          @ a7 AND A
        .word   xorb          @ a8 XOR B
        .word   xorc          @ a9 XOR C
        .word   xord          @ aa XOR D
        .word   xore          @ ab XOR E
        .word   xorh          @ ac XOR H
        .word   xorl          @ ad XOR L
        .word   xorhl         @ ae XOR (HL)
        .word   xora          @ af XOR A
        .word   orb           @ b0 OR B
        .word   orc           @ b1 OR C
        .word   ord           @ b2 OR D
        .word   ore           @ b3 OR E
        .word   orh           @ b4 OR H
        .word   orl           @ b5 OR L
        .word   orhl          @ b6 OR (HL)
        .word   ora           @ b7 OR A
        .word   cpb           @ b8 CP B
        .word   cpc           @ b9 CP C
        .word   cp_d          @ ba CP D
        .word   cpe           @ bb CP E
        .word   cph           @ bc CP H
        .word   cp_l          @ bd CP L
        .word   cphl          @ be CP (HL)
        .word   cpa           @ bf CP A
        .word   retnz         @ c0 RET NZ
        .word   popbc         @ c1 POP BC
        .word   jpnz          @ c2 JP NZ
        .word   jpnn          @ c3 JP nn
        .word   callnz        @ c4 CALL NZ
        .word   pushbc        @ c5 PUSH BC
        .word   addan         @ c6 ADD A,n
        .word   rst00         @ c7 RST 0x00
        .word   retz          @ c8 RET Z
        .word   ret10         @ c9 RET
        .word   jpz           @ ca JP Z
        .word   opcb          @ cb op cb
        .word   callz         @ cc CALL Z
        .word   callnn        @ cd CALL NN
        .word   adcan         @ ce ADC A,n
        .word   rst08         @ cf RST 0x08
        .word   retnc         @ d0 RET NC
        .word   popde         @ d1 POP DE
        .word   jpnc          @ d2 JP NC
        .word   outna         @ d3 OUT (n),A
        .word   callnc        @ d4 CALL NC
        .word   pushde        @ d5 PUSH DE
        .word   subn          @ d6 SUB n
        .word   rst10         @ d7 RST 0x10
        .word   retc          @ d8 RET C
        .word   exx           @ d9 EXX
        .word   jpc           @ da JP C
        .word   inan          @ db IN A,(n)
        .word   callc         @ dc CALL C
        .word   opdd          @ dd OP dd
        .word   sbcan         @ de SBC A,n
        .word   rst18         @ df RST 0x18
        .word   retpo         @ e0 RET PO
        .word   pophl         @ e1 POP HL
        .word   jppo          @ e2 JP PO
        .word   exsphl        @ e3 EX (SP),HL
        .word   callpo        @ e4 CALL PO
        .word   pushhl        @ e5 PUSH HL
        .word   andan         @ e6 AND A,n
        .word   rst20         @ e7 RST 0x20
        .word   retpe         @ e8 RET PE
        .word   jphl          @ e9 JP (HL)
        .word   jppe          @ ea JP PE
        .word   exdehl        @ eb EX DE,HL
        .word   callpe        @ ec CALL PE
        .word   oped          @ ed op ed
        .word   xoran         @ ee XOR A,n
        .word   rst28         @ ef RST 0x28
        .word   retp          @ f0 RET P
        .word   popaf         @ f1 POP AF
        .word   jpp           @ f2 JP P
        .word   di            @ f3 DI
        .word   callp         @ f4 CALL P
        .word   pushaf        @ f5 PUSH AF
        .word   oran          @ f6 OR A,n
        .word   rst30         @ f7 RST 0x30
        .word   retm          @ f8 RET M
        .word   ldsphl        @ f9 LD SP,HL
        .word   jpm           @ fa JP M
        .word   ei            @ fb EI
        .word   callm         @ fc CALL M
        .word   opfd          @ fd op fd
        .word   cpan          @ fe CP A,n
        .word   rst38         @ ff RST 0x38
      .endif

nop:    TIME    4
        PREFIX0

opdd:   TIME    4
      .if fast==0
        PREFIX1
      .else
        mov     lr, #0x00010000
        uadd8   arvpref, arvpref, lr
        ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        ldr     pc, [pc, lr, lsl #2]
        .word   0
        .word   nop           @ 00 NOP
        .word   ldbcnn        @ 01 LD BC,nn
        .word   ldbca         @ 02 LD (BC),A
        .word   incbc         @ 03 INC BC
        .word   incb          @ 04 INC B
        .word   decb          @ 05 DEC B
        .word   ldbn          @ 06 LD B,n
        .word   rlca          @ 07 RLCA
        .word   exafaf        @ 08 EX AF,AF
        .word   addixbc       @ 09 ADD IX,BC
        .word   ldabc         @ 0a LD A,(BC)
        .word   decbc         @ 0b DEC BC
        .word   incc          @ 0c INC C
        .word   decc          @ 0d DEC C
        .word   ldcn          @ 0e LD C,n
        .word   rrca          @ 0f RRCA
        .word   djnz          @ 10 DJNZ
        .word   lddenn        @ 11 LD DE,nn
        .word   lddea         @ 12 LD (DE),A
        .word   incde         @ 13 INC DE
        .word   incd          @ 14 INC D
        .word   decd          @ 15 DEC D
        .word   lddn          @ 16 LD D,n
        .word   rla           @ 17 RLA
        .word   jr            @ 18 JR
        .word   addiyde       @ 19 ADD IY,DE
        .word   ldade         @ 1a LD A,(DE)
        .word   decde         @ 1b DEC DE
        .word   ince          @ 1c INC E
        .word   dece          @ 1d DEC E
        .word   lden          @ 1e LD E,n
        .word   rra           @ 1f RRA
        .word   jrnz          @ 20 JR NZ,s8
        .word   ldixnn        @ 21 LD IX,nn
        .word   ldpnnix       @ 22 LD (nn),IX
        .word   incix         @ 23 INC IX
        .word   incixh        @ 24 INC IXh
        .word   decixh        @ 25 DEC IXh
        .word   ldixhn        @ 26 LD IXh,n
        .word   daa           @ 27 DAA
        .word   jrz           @ 28 JR Z,s8
        .word   addixix       @ 29 ADD IX,IX
        .word   ldixpnn       @ 2a LD IX,(nn)
        .word   decix         @ 2b DEC IX
        .word   incixl        @ 2c INC IXl
        .word   decixl        @ 2d DEC IXl
        .word   ldixln        @ 2e LD IXl,n
        .word   cpl           @ 2f CPL
        .word   jrnc          @ 30 JR NC,s8
        .word   ldspnn        @ 31 LD SP,nn
        .word   ldnna         @ 32 LD (nn),A
        .word   incsp         @ 33 INC SP
        .word   incpix        @ 34 INC (IX+d)
        .word   decpix        @ 35 DEC (IX+d)
        .word   ldixn         @ 36 LD (IX+d),n
        .word   scf           @ 37 SCF
        .word   jrc           @ 38 JR C,s8
        .word   addixsp       @ 39 ADD IX,SP
        .word   ldann         @ 3a LD A,(nn)
        .word   decsp         @ 3b DEC SP
        .word   inca          @ 3c INC A
        .word   deca          @ 3d DEC A
        .word   ldan          @ 3e LD A,n
        .word   ccf           @ 3f CCF
        .word   nop           @ 40 LD B,B
        .word   ldbc          @ 41 LD B,C
        .word   ldbd          @ 42 LD B,D
        .word   ldbe          @ 43 LD B,E
        .word   ldbixh        @ 44 LD B,IXh
        .word   ldbixl        @ 45 LD B,IXl
        .word   ldbix         @ 46 LD B,(IX+d)
        .word   ldba          @ 47 LD B,A
        .word   ldcb          @ 48 LD C,B
        .word   nop           @ 49 LD C,C
        .word   ldcd          @ 4a LD C,D
        .word   ldce          @ 4b LD C,E
        .word   ldcixh        @ 4c LD C,IXh
        .word   ldcixl        @ 4d LD C,IXl
        .word   ldcix         @ 4e LD C,(IX+d)
        .word   ldca          @ 4f LD C,A
        .word   lddb          @ 50 LD D,B
        .word   lddc          @ 51 LD D,C
        .word   nop           @ 52 LD D,D
        .word   ldde          @ 53 LD D,E
        .word   lddixh        @ 54 LD D,IXh
        .word   lddixl        @ 55 LD D,IXl
        .word   lddix         @ 56 LD D,(IX+d)
        .word   ldda          @ 57 LD D,A
        .word   ldeb          @ 58 LD E,B
        .word   ldec          @ 59 LD E,C
        .word   lded          @ 5a LD E,D
        .word   nop           @ 5b LD E,E
        .word   ldeixh        @ 5c LD E,IXh
        .word   ldeixl        @ 5d LD E,IXl
        .word   ldeix         @ 5e LD E,(IX+d)
        .word   ldea          @ 5f LD E,A
        .word   ldixhb        @ 60 LD IXh,B
        .word   ldixhc        @ 61 LD IXh,C
        .word   ldixhd        @ 62 LD IXh,D
        .word   ldixhe        @ 63 LD IXh,E
        .word   nop           @ 64 LD IXh,IXh
        .word   ldxhxl        @ 65 LD IXh,IXl
        .word   ldhix         @ 66 LD H,(IX+d)
        .word   ldixha        @ 67 LD IXh,A
        .word   ldixlb        @ 68 LD IXl,B
        .word   ldixlc        @ 69 LD IXl,C
        .word   ldixld        @ 6a LD IXl,D
        .word   ldixle        @ 6b LD IXl,E
        .word   ldxlxh        @ 6c LD IXl,IXh
        .word   nop           @ 6d LD IXl,IXl
        .word   ldlix         @ 6e LD L,(IX+d)
        .word   ldixla        @ 6f LD IXl,A
        .word   ldixb         @ 70 LD (IX+d),B
        .word   ldixc         @ 71 LD (IX+d),C
        .word   ldixd         @ 72 LD (IX+d),D
        .word   ldixe         @ 73 LD (IX+d),E
        .word   ldixh         @ 74 LD (IX+d),H
        .word   ldixl         @ 75 LD (IX+d),L
        .word   halt          @ 76 HALT
        .word   ldixa         @ 77 LD (IX+d),A
        .word   ldab          @ 78 LD A,B
        .word   ldac          @ 79 LD A,C
        .word   ldad          @ 7a LD A,D
        .word   ldae          @ 7b LD A,E
        .word   ldaixh        @ 7c LD A,IXh
        .word   ldaixl        @ 7d LD A,IXl
        .word   ldaix         @ 7e LD A,(IX+d)
        .word   nop           @ 7f LD A,A
        .word   addab         @ 80 ADD A,B
        .word   addac         @ 81 ADD A,C
        .word   addad         @ 82 ADD A,D
        .word   addae         @ 83 ADD A,E
        .word   addaxh        @ 84 ADD A,IXh
        .word   addaxl        @ 85 ADD A,IXl
        .word   addaix        @ 86 ADD A,(IX+d)
        .word   addaa         @ 87 ADD A,A
        .word   adcab         @ 88 ADC A,B
        .word   adcac         @ 89 ADC A,C
        .word   adcad         @ 8a ADC A,D
        .word   adcae         @ 8b ADC A,E
        .word   adcaxh        @ 8c ADC A,IXh
        .word   adcaxl        @ 8d ADC A,IXl
        .word   adcaix        @ 8e ADC A,(IX+d)
        .word   adcaa         @ 8f ADC A,A
        .word   subb          @ 90 SUB B
        .word   subc          @ 91 SUB C
        .word   subd          @ 92 SUB D
        .word   sube          @ 93 SUB E
        .word   subxh         @ 94 SUB IXh
        .word   subxl         @ 95 SUB IXl
        .word   subix         @ 96 SUB (IX+d)
        .word   suba          @ 97 SUB A
        .word   sbcab         @ 98 SBC A,B
        .word   sbcac         @ 99 SBC A,C
        .word   sbcad         @ 9a SBC A,D
        .word   sbcae         @ 9b SBC A,E
        .word   sbcaxh        @ 9c SBC A,IXh
        .word   sbcaxl        @ 9d SBC A,IXl
        .word   sbcaix        @ 9e SBC A,(IX+d)
        .word   sbcaa         @ 9f SBC A,A
        .word   andb          @ a0 AND B
        .word   andc          @ a1 AND C
        .word   andd          @ a2 AND D
        .word   ande          @ a3 AND E
        .word   andxh         @ a4 AND IXh
        .word   andxl         @ a5 AND IXl
        .word   andix         @ a6 AND (IX+d)
        .word   anda          @ a7 AND A
        .word   xorb          @ a8 XOR B
        .word   xorc          @ a9 XOR C
        .word   xord          @ aa XOR D
        .word   xore          @ ab XOR E
        .word   xorxh         @ ac XOR IXh
        .word   xorxl         @ ad XOR IXl
        .word   xorix         @ ae XOR (IX+d)
        .word   xora          @ af XOR A
        .word   orb           @ b0 OR B
        .word   orc           @ b1 OR C
        .word   ord           @ b2 OR D
        .word   ore           @ b3 OR E
        .word   orxh          @ b4 OR IXh
        .word   orxl          @ b5 OR IXl
        .word   orix          @ b6 OR (IX+d)
        .word   ora           @ b7 OR A
        .word   cpb           @ b8 CP B
        .word   cpc           @ b9 CP C
        .word   cp_d          @ ba CP D
        .word   cpe           @ bb CP E
        .word   cpxh          @ bc CP IXh
        .word   cpxl          @ bd CP IXl
        .word   cpix          @ be CP (IX+d)
        .word   cpa           @ bf CP A
        .word   retnz         @ c0 RET NZ
        .word   popbc         @ c1 POP BC
        .word   jpnz          @ c2 JP NZ
        .word   jpnn          @ c3 JP nn
        .word   callnz        @ c4 CALL NZ
        .word   pushbc        @ c5 PUSH BC
        .word   addan         @ c6 ADD A,n
        .word   rst00         @ c7 RST 0x00
        .word   retz          @ c8 RET Z
        .word   ret10         @ c9 RET
        .word   jpz           @ ca JP Z
        .word   opddcb        @ cb op cb
        .word   callz         @ cc CALL Z
        .word   callnn        @ cd CALL NN
        .word   adcan         @ ce ADC A,n
        .word   rst08         @ cf RST 0x08
        .word   retnc         @ d0 RET NC
        .word   popde         @ d1 POP DE
        .word   jpnc          @ d2 JP NC
        .word   outna         @ d3 OUT (n),A
        .word   callnc        @ d4 CALL NC
        .word   pushde        @ d5 PUSH DE
        .word   subn          @ d6 SUB n
        .word   rst10         @ d7 RST 0x10
        .word   retc          @ d8 RET C
        .word   exx           @ d9 EXX
        .word   jpc           @ da JP C
        .word   inan          @ db IN A,(n)
        .word   callc         @ dc CALL C
        .word   opdd          @ dd OP dd
        .word   sbcan         @ de SBC A,n
        .word   rst18         @ df RST 0x18
        .word   retpo         @ e0 RET PO
        .word   popix         @ e1 POP IX
        .word   jppo          @ e2 JP PO
        .word   exspix        @ e3 EX (SP),IX
        .word   callpo        @ e4 CALL PO
        .word   pushix        @ e5 PUSH IX
        .word   andan         @ e6 AND A,n
        .word   rst20         @ e7 RST 0x20
        .word   retpe         @ e8 RET PE
        .word   jpix          @ e9 JP (IX)
        .word   jppe          @ ea JP PE
        .word   exdehl        @ eb EX DE,HL
        .word   callpe        @ ec CALL PE
        .word   oped          @ ed op ed
        .word   xoran         @ ee XOR A,n
        .word   rst28         @ ef RST 0x28
        .word   retp          @ f0 RET P
        .word   popaf         @ f1 POP AF
        .word   jpp           @ f2 JP P
        .word   di            @ f3 DI
        .word   callp         @ f4 CALL P
        .word   pushaf        @ f5 PUSH AF
        .word   oran          @ f6 OR A,n
        .word   rst30         @ f7 RST 0x30
        .word   retm          @ f8 RET M
        .word   ldspix        @ f9 LD SP,IX
        .word   jpm           @ fa JP M
        .word   ei            @ fb EI
        .word   callm         @ fc CALL M
        .word   opfd          @ fd op fd
        .word   cpan          @ fe CP A,n
        .word   rst38         @ ff RST 0x38
      .endif

opfd:   TIME    4
      .if fast==0
        PREFIX2
      .else
        mov     lr, #0x00010000
        uadd8   arvpref, arvpref, lr
        ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        ldr     pc, [pc, lr, lsl #2]
        .word   0
        .word   nop           @ 00 NOP
        .word   ldbcnn        @ 01 LD BC,nn
        .word   ldbca         @ 02 LD (BC),A
        .word   incbc         @ 03 INC BC
        .word   incb          @ 04 INC B
        .word   decb          @ 05 DEC B
        .word   ldbn          @ 06 LD B,n
        .word   rlca          @ 07 RLCA
        .word   exafaf        @ 08 EX AF,AF
        .word   addiybc       @ 09 ADD IY,BC
        .word   ldabc         @ 0a LD A,(BC)
        .word   decbc         @ 0b DEC BC
        .word   incc          @ 0c INC C
        .word   decc          @ 0d DEC C
        .word   ldcn          @ 0e LD C,n
        .word   rrca          @ 0f RRCA
        .word   djnz          @ 10 DJNZ
        .word   lddenn        @ 11 LD DE,nn
        .word   lddea         @ 12 LD (DE),A
        .word   incde         @ 13 INC DE
        .word   incd          @ 14 INC D
        .word   decd          @ 15 DEC D
        .word   lddn          @ 16 LD D,n
        .word   rla           @ 17 RLA
        .word   jr            @ 18 JR
        .word   addiyde       @ 19 ADD IY,DE
        .word   ldade         @ 1a LD A,(DE)
        .word   decde         @ 1b DEC DE
        .word   ince          @ 1c INC E
        .word   dece          @ 1d DEC E
        .word   lden          @ 1e LD E,n
        .word   rra           @ 1f RRA
        .word   jrnz          @ 20 JR NZ,s8
        .word   ldiynn        @ 21 LD IY,nn
        .word   ldpnniy       @ 22 LD (nn),IY
        .word   inciy         @ 23 INC IY
        .word   inciyh        @ 24 INC IYh
        .word   deciyh        @ 25 DEC IYh
        .word   ldiyhn        @ 26 LD IYh,n
        .word   daa           @ 27 DAA
        .word   jrz           @ 28 JR Z,s8
        .word   addiyiy       @ 29 ADD IY,IY
        .word   ldiypnn       @ 2a LD IY,(nn)
        .word   deciy         @ 2b DEC IY
        .word   inciyl        @ 2c INC IYl
        .word   deciyl        @ 2d DEC IYl
        .word   ldiyln        @ 2e LD IYl,n
        .word   cpl           @ 2f CPL
        .word   jrnc          @ 30 JR NC,s8
        .word   ldspnn        @ 31 LD SP,nn
        .word   ldnna         @ 32 LD (nn),A
        .word   incsp         @ 33 INC SP
        .word   incpiy        @ 34 INC (IY+d)
        .word   decpiy        @ 35 DEC (IY+d)
        .word   ldiyn         @ 36 LD (IY+d),n
        .word   scf           @ 37 SCF
        .word   jrc           @ 38 JR C,s8
        .word   addiysp       @ 39 ADD IY,SP
        .word   ldann         @ 3a LD A,(nn)
        .word   decsp         @ 3b DEC SP
        .word   inca          @ 3c INC A
        .word   deca          @ 3d DEC A
        .word   ldan          @ 3e LD A,n
        .word   ccf           @ 3f CCF
        .word   nop           @ 40 LD B,B
        .word   ldbc          @ 41 LD B,C
        .word   ldbd          @ 42 LD B,D
        .word   ldbe          @ 43 LD B,E
        .word   ldbiyh        @ 44 LD B,IYh
        .word   ldbiyl        @ 45 LD B,IYl
        .word   ldbiy         @ 46 LD B,(IY+d)
        .word   ldba          @ 47 LD B,A
        .word   ldcb          @ 48 LD C,B
        .word   nop           @ 49 LD C,C
        .word   ldcd          @ 4a LD C,D
        .word   ldce          @ 4b LD C,E
        .word   ldciyh        @ 4c LD C,IYh
        .word   ldciyl        @ 4d LD C,IYl
        .word   ldciy         @ 4e LD C,(IY+d)
        .word   ldca          @ 4f LD C,A
        .word   lddb          @ 50 LD D,B
        .word   lddc          @ 51 LD D,C
        .word   nop           @ 52 LD D,D
        .word   ldde          @ 53 LD D,E
        .word   lddiyh        @ 54 LD D,IYh
        .word   lddiyl        @ 55 LD D,IYl
        .word   lddiy         @ 56 LD D,(IY+d)
        .word   ldda          @ 57 LD D,A
        .word   ldeb          @ 58 LD E,B
        .word   ldec          @ 59 LD E,C
        .word   lded          @ 5a LD E,D
        .word   nop           @ 5b LD E,E
        .word   ldeiyh        @ 5c LD E,IYh
        .word   ldeiyl        @ 5d LD E,IYl
        .word   ldeiy         @ 5e LD E,(IY+d)
        .word   ldea          @ 5f LD E,A
        .word   ldiyhb        @ 60 LD IYh,B
        .word   ldiyhc        @ 61 LD IYh,C
        .word   ldiyhd        @ 62 LD IYh,D
        .word   ldiyhe        @ 63 LD IYh,E
        .word   nop           @ 64 LD IYh,IYh
        .word   ldyhyl        @ 65 LD IYh,IYl
        .word   ldhiy         @ 66 LD H,(IY+d)
        .word   ldiyha        @ 67 LD IYh,A
        .word   ldiylb        @ 68 LD IYl,B
        .word   ldiylc        @ 69 LD IYl,C
        .word   ldiyld        @ 6a LD IYl,D
        .word   ldiyle        @ 6b LD IYl,E
        .word   ldylyh        @ 6c LD IYl,IYh
        .word   nop           @ 6d LD IYl,IYl
        .word   ldliy         @ 6e LD L,(IY+d)
        .word   ldiyla        @ 6f LD IYl,A
        .word   ldiyb         @ 70 LD (IY+d),B
        .word   ldiyc         @ 71 LD (IY+d),C
        .word   ldiyd         @ 72 LD (IY+d),D
        .word   ldiye         @ 73 LD (IY+d),E
        .word   ldiyh         @ 74 LD (IY+d),H
        .word   ldiyl         @ 75 LD (IY+d),L
        .word   halt          @ 76 HALT
        .word   ldiya         @ 77 LD (IY+d),A
        .word   ldab          @ 78 LD A,B
        .word   ldac          @ 79 LD A,C
        .word   ldad          @ 7a LD A,D
        .word   ldae          @ 7b LD A,E
        .word   ldaiyh        @ 7c LD A,IYh
        .word   ldaiyl        @ 7d LD A,IYl
        .word   ldaiy         @ 7e LD A,(IY+d)
        .word   nop           @ 7f LD A,A
        .word   addab         @ 80 ADD A,B
        .word   addac         @ 81 ADD A,C
        .word   addad         @ 82 ADD A,D
        .word   addae         @ 83 ADD A,E
        .word   addayh        @ 84 ADD A,IYh
        .word   addayl        @ 85 ADD A,IYl
        .word   addaiy        @ 86 ADD A,(IY+d)
        .word   addaa         @ 87 ADD A,A
        .word   adcab         @ 88 ADC A,B
        .word   adcac         @ 89 ADC A,C
        .word   adcad         @ 8a ADC A,D
        .word   adcae         @ 8b ADC A,E
        .word   adcayh        @ 8c ADC A,IYh
        .word   adcayl        @ 8d ADC A,IYl
        .word   adcaiy        @ 8e ADC A,(IY+d)
        .word   adcaa         @ 8f ADC A,A
        .word   subb          @ 90 SUB B
        .word   subc          @ 91 SUB C
        .word   subd          @ 92 SUB D
        .word   sube          @ 93 SUB E
        .word   subyh         @ 94 SUB IYh
        .word   subyl         @ 95 SUB IYl
        .word   subiy         @ 96 SUB (IY+d)
        .word   suba          @ 97 SUB A
        .word   sbcab         @ 98 SBC A,B
        .word   sbcac         @ 99 SBC A,C
        .word   sbcad         @ 9a SBC A,D
        .word   sbcae         @ 9b SBC A,E
        .word   sbcayh        @ 9c SBC A,IYh
        .word   sbcayl        @ 9d SBC A,IYl
        .word   sbcaiy        @ 9e SBC A,(IY+d)
        .word   sbcaa         @ 9f SBC A,A
        .word   andb          @ a0 AND B
        .word   andc          @ a1 AND C
        .word   andd          @ a2 AND D
        .word   ande          @ a3 AND E
        .word   andyh         @ a4 AND IYh
        .word   andyl         @ a5 AND IYl
        .word   andiy         @ a6 AND (IY+d)
        .word   anda          @ a7 AND A
        .word   xorb          @ a8 XOR B
        .word   xorc          @ a9 XOR C
        .word   xord          @ aa XOR D
        .word   xore          @ ab XOR E
        .word   xoryh         @ ac XOR IYh
        .word   xoryl         @ ad XOR IYl
        .word   xoriy         @ ae XOR (IY+d)
        .word   xora          @ af XOR A
        .word   orb           @ b0 OR B
        .word   orc           @ b1 OR C
        .word   ord           @ b2 OR D
        .word   ore           @ b3 OR E
        .word   oryh          @ b4 OR IYh
        .word   oryl          @ b5 OR IYl
        .word   oriy          @ b6 OR (IY+d)
        .word   ora           @ b7 OR A
        .word   cpb           @ b8 CP B
        .word   cpc           @ b9 CP C
        .word   cp_d          @ ba CP D
        .word   cpe           @ bb CP E
        .word   cpyh          @ bc CP IYh
        .word   cpyl          @ bd CP IYl
        .word   cpiy          @ be CP (IY+d)
        .word   cpa           @ bf CP A
        .word   retnz         @ c0 RET NZ
        .word   popbc         @ c1 POP BC
        .word   jpnz          @ c2 JP NZ
        .word   jpnn          @ c3 JP nn
        .word   callnz        @ c4 CALL NZ
        .word   pushbc        @ c5 PUSH BC
        .word   addan         @ c6 ADD A,n
        .word   rst00         @ c7 RST 0x00
        .word   retz          @ c8 RET Z
        .word   ret10         @ c9 RET
        .word   jpz           @ ca JP Z
        .word   opfdcb        @ cb op cb
        .word   callz         @ cc CALL Z
        .word   callnn        @ cd CALL NN
        .word   adcan         @ ce ADC A,n
        .word   rst08         @ cf RST 0x08
        .word   retnc         @ d0 RET NC
        .word   popde         @ d1 POP DE
        .word   jpnc          @ d2 JP NC
        .word   outna         @ d3 OUT (n),A
        .word   callnc        @ d4 CALL NC
        .word   pushde        @ d5 PUSH DE
        .word   subn          @ d6 SUB n
        .word   rst10         @ d7 RST 0x10
        .word   retc          @ d8 RET C
        .word   exx           @ d9 EXX
        .word   jpc           @ da JP C
        .word   inan          @ db IN A,(n)
        .word   callc         @ dc CALL C
        .word   opdd          @ dd OP dd
        .word   sbcan         @ de SBC A,n
        .word   rst18         @ df RST 0x18
        .word   retpo         @ e0 RET PO
        .word   popiy         @ e1 POP IY
        .word   jppo          @ e2 JP PO
        .word   exspiy        @ e3 EX (SP),IY
        .word   callpo        @ e4 CALL PO
        .word   pushiy        @ e5 PUSH IY
        .word   andan         @ e6 AND A,n
        .word   rst20         @ e7 RST 0x20
        .word   retpe         @ e8 RET PE
        .word   jpiy          @ e9 JP (IY)
        .word   jppe          @ ea JP PE
        .word   exdehl        @ eb EX DE,HL
        .word   callpe        @ ec CALL PE
        .word   oped          @ ed op ed
        .word   xoran         @ ee XOR A,n
        .word   rst28         @ ef RST 0x28
        .word   retp          @ f0 RET P
        .word   popaf         @ f1 POP AF
        .word   jpp           @ f2 JP P
        .word   di            @ f3 DI
        .word   callp         @ f4 CALL P
        .word   pushaf        @ f5 PUSH AF
        .word   oran          @ f6 OR A,n
        .word   rst30         @ f7 RST 0x30
        .word   retm          @ f8 RET M
        .word   ldspiy        @ f9 LD SP,IY
        .word   jpm           @ fa JP M
        .word   ei            @ fb EI
        .word   callm         @ fc CALL M
        .word   opfd          @ fd op fd
        .word   cpan          @ fe CP A,n
        .word   rst38         @ ff RST 0x38
      .endif

daa:    TIME    4
        and     lr, pcff, #0x00000100
        mov     r11, #0x00000000
        mov     r10, arvpref, lsr #24
        orr     r10, lr
        cmp     r10, #0x00000099
        movhi   r11, #0x00000160
        and     r10, #0x0000000f
        eor     lr, defr, spfa
        eor     lr, bcfb
        eor     lr, bcfb, lsr #8
        and     lr, #0x00000010
        orr     lr, r10
        cmp     lr, #0x00000009
        addhi   r11, #0x00000006
        mov     r10, arvpref, lsr #24
        pkhtb   spfa, spfa, r10
        orr     spfa, #0x00000100
        tst     bcfb, #0x00000200
        mov     lr, r11
        mvnne   lr, r11
        pkhtb   bcfb, bcfb, lr
        subne   arvpref, r11, lsl #24
        addeq   arvpref, r11, lsl #24
        mov     lr, arvpref, lsr #24
        pkhtb   defr, defr, lr
        and     r11, #0x00000100
        orr     lr, r11
        pkhtb   pcff, pcff, lr
        PREFIX0

cpl:    TIME    4
        eor     arvpref, #0xff000000
        mov     lr, arvpref, lsr #24
        eor     lr, pcff
        and     lr, #0x00000028
        eor     pcff, lr
        orr     bcfb, #0x0000007f
        orr     bcfb, #0x0000ff00
        mvn     lr, defr
        eor     lr, spfa
        and     lr, #0x00000010
        eor     spfa, lr
        PREFIX0

rlca:   TIME    4
        uxtb    lr, arvpref, ror #24
        add     lr, lr, lr, lsl #8
        pkhtb   pcff, pcff, lr, asr #7
        uxtb    lr, pcff
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        pkhtb   defr, defr, lr
        orr     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
/*        mov     lr, arvpref, lsr #24
        add     lr, lr, lr, lsl #8
        mov     r11, lr, lsr #7
        bic     arvpref, #0xff000000
        orr     arvpref, r11, lsl #24
        eor     r11, pcff
        and     r11, #0x00000128
        eor     pcff, r11
        eor     lr, spfa, defr
        and     lr, #0x00000010
        and     r11, bcfb, #0x00000080
        orr     lr, r11
        pkhtb   bcfb, bcfb, lr*/
        PREFIX0

rrca:   TIME    4
        movs    lr, arvpref, lsr #25
        orrcs   lr, #0x00000180
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        eor     lr, pcff
        and     lr, #0x00000128
        eor     pcff, lr
        eor     lr, spfa, defr
        and     lr, #0x00000010
        and     r11, bcfb, #0x00000080
        orr     lr, r11
        pkhtb   bcfb, bcfb, lr
        PREFIX0

rla:    TIME    4
        movs    lr, pcff, lsl #24
        uxtb    lr, arvpref, ror #24
        adc     lr, lr
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
/*        mov     lr, arvpref, lsr #24
        movs    r11, pcff, lsr #9
        adc     lr, lr
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        eor     lr, pcff
        and     lr, #0x00000128
        eor     pcff, lr
        eor     lr, spfa, defr
        and     lr, #0x00000010
        and     r11, bcfb, #0x00000080
        orr     lr, r11
        pkhtb   bcfb, bcfb, lr*/
        PREFIX0

rra:    TIME    4
        mov     lr, arvpref, lsr #24
        add     lr, lr, lr, lsl #9
        and     r11, pcff, #0x00000100
        orr     lr, r11
        mov     lr, lr, lsr #1
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        and     lr, #0x00000128
        and     r11, pcff, #0x000000d7
        orr     lr, r11
        pkhtb   pcff, pcff, lr
        eor     lr, spfa, defr
        and     lr, #0x00000010
        and     r11, bcfb, #0x00000080
        orr     lr, r11
        pkhtb   bcfb, bcfb, lr
        PREFIX0

outna:  TIME    11
        ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        push    {r0-r3, r12}
        mov     r1, arvpref, lsr #24
        orr     r0, lr, r1, lsl #8
        mov     r11, #0x00000001
        uadd8   r11, r11, r0
        pkhtb   hlmp, hlmp, r11
        bl      out
        pop     {r0-r3, r12}
        PREFIX0

inan:   TIME    11
        ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        mov     r11, arvpref, lsr #24
        push    {r0-r3, r12}
        orr     r0, lr, r11, lsl #8
        add     r11, r0, #0x00000001
        pkhtb   hlmp, hlmp, r11
        bl      in
        bic     arvpref, #0xff000000
        orr     arvpref, r0, lsl #24
        pop     {r0-r3, r12}
        PREFIX0

djnz:   sub     bcfb, #0x01000000
        tst     bcfb, #0xff000000
        beq     djnz2
        TIME    13
        ldr     lr, [mem, pcff, lsr #16]
        sxtb    lr, lr
        add     pcff, lr, lsl #16
        add     pcff, #0x00010000
        pkhtb   hlmp, hlmp, pcff, asr #16
        PREFIX0
djnz2:  TIME    8
        add     pcff, #0x00010000
        PREFIX0

ei:     TIME    4
        orr     arvpref, #0x00000400
        PREFIX0

di:     TIME    4
        and     arvpref, #0xfffffbff
        PREFIX0

ldbcnn: LDRRIM  bcfb
lddenn: LDRRIM  defr
ldspnn: LDRRIM  spfa

      .if fast==0
ldxxn:  movs    lr, arvpref, lsl #24
        beq     ldhln
        bmi     ldiyn
      .endif
ldixn:  LDPIM   ixstart
ldiyn:  LDPIM   iyi
ldhln:  TIME    10
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        strb    lr, [mem, hlmp, lsr #16]
        PREFIX0

      .if fast==0
ldxxnn: movs    lr, arvpref, lsl #24
        beq     ldhlnn
        bmi     ldiynn
      .endif
ldixnn: LDRRIM  ixstart
ldiynn: LDRRIM  iyi
ldhlnn: LDRRIM  hlmp

      .if fast==0
jpxx:   TIME    4
        movs    lr, arvpref, lsl #24
        beq     jphl
        bmi     jpiy
      .endif
jpix:   pkhbt   pcff, pcff, ixstart
        PREFIX0
jpiy:   pkhbt   pcff, pcff, iyi
        PREFIX0
jphl:   pkhbt   pcff, pcff, hlmp
        PREFIX0

      .if fast==0
ldspxx: TIME    4
        movs    lr, arvpref, lsl #24
        beq     ldsphl
        bmi     ldspiy
      .endif
ldspix: pkhbt   spfa, spfa, ixstart
        PREFIX0
ldspiy: pkhbt   spfa, spfa, iyi
        PREFIX0
ldsphl: pkhbt   spfa, spfa, hlmp
        PREFIX0

      .if fast==0
ldxxpnn:movs    lr, arvpref, lsl #24
        beq     ldhlpnn
        bmi     ldiypnn
      .endif
ldixpnn:LDRRPNN ixstart, 16
        PREFIX0
ldiypnn:LDRRPNN iyi, 16
        PREFIX0
ldhlpnn:LDRRPNN hlmp, 16
        PREFIX0

ldbcpnn:LDRRPNN bcfb, 20
        b       salida
lddepnn:LDRRPNN defr, 20
        b       salida
ldxepnn:LDRRPNN hlmp, 20
        b       salida
ldsppnn:LDRRPNN spfa, 20
        b       salida

      .if fast==0
ldpnnxx:movs    lr, arvpref, lsl #24
        beq     ldpnnhl
        bmi     ldpnniy
      .endif
ldpnnix:LDPNNRR ixstart, 16
        PREFIX0
ldpnniy:LDPNNRR iyi, 16
        PREFIX0
ldpnnhl:LDPNNRR hlmp, 16
        PREFIX0

ldpnnbc:LDPNNRR bcfb, 20
        b       salida
ldpnnde:LDPNNRR defr, 20
        b       salida
ldpnnxe:LDPNNRR hlmp, 20
        b       salida
ldpnnsp:LDPNNRR spfa, 20
        b       salida

      .if fast==0
addxxbc:movs    lr, arvpref, lsl #24
        beq     addhlbc
        bmi     addiybc
      .endif
addixbc:ADDRRRR ixstart, bcfb
addiybc:ADDRRRR iyi, bcfb
addhlbc:ADDRRRR hlmp, bcfb

      .if fast==0
addxxde:movs    lr, arvpref, lsl #24
        beq     addhlde
        bmi     addiyde
      .endif
addixde:ADDRRRR ixstart, defr
addiyde:ADDRRRR iyi, defr
addhlde:ADDRRRR hlmp, defr

      .if fast==0
addxxxx:movs    lr, arvpref, lsl #24
        beq     addhlhl
        bmi     addiyiy
      .endif
addixix:ADDRRRR ixstart, ixstart
addiyiy:ADDRRRR iyi, iyi
addhlhl:ADDRRRR hlmp, hlmp

      .if fast==0
addxxsp:movs    lr, arvpref, lsl #24
        beq     addhlsp
        bmi     addiysp
      .endif
addixsp:ADDRRRR ixstart, spfa
addiysp:ADDRRRR iyi, spfa
addhlsp:ADDRRRR hlmp, spfa

callnn: TIME    17
        mov     r11, pcff, lsr #16
        ldrh    lr, [mem, r11]
        add     r11, r11, #2
        pkhbt   pcff, pcff, lr, lsl #16
        pkhtb   hlmp, hlmp, lr
        sub     spfa, #0x00020000
        mov     r10, spfa, lsr #16
        strh    r11, [mem, r10]
        PREFIX0

callz:  movs    lr, defr, lsl #16
        CALLC

callnz: movs    lr, defr, lsl #16
        CALLCI

callnc: tst     pcff, #0x00000100
        CALLC

callc:  tst     pcff, #0x00000100
        CALLCI

callp:  tst     pcff, #0x00000080
        CALLC

callm:  tst     pcff, #0x00000080
        CALLCI

ret11:  RET     11
        PREFIX0

ret10:  RET     10
        PREFIX0

retz:   movs    lr, defr, lsl #16
        RETC

retnz:  movs    lr, defr, lsl #16
        RETCI

retnc:  tst     pcff, #0x00000100
        RETC

retc:   tst     pcff, #0x00000100
        RETCI

retp:   tst     pcff, #0x00000080
        RETC

retm:   tst     pcff, #0x00000080
        RETCI

jr:     TIME    12
        ldr     lr, [mem, pcff, lsr #16]
        sxtb    lr, lr
        add     pcff, lr, lsl #16
        add     pcff, #0x00010000
        pkhtb   hlmp, hlmp, pcff, asr #16
        PREFIX0

jrnc:   tst     pcff, #0x00000100
        JRC
jrnn:   TIME    12
        ldr     lr, [mem, pcff, lsr #16]
        sxtb    lr, lr
        add     pcff, lr, lsl #16
        add     pcff, #0x00010000
        PREFIX0

jrc:    tst     pcff, #0x00000100
        JRCI

jrz:    movs    lr, defr, lsl #16
        JRC

jrnz:   movs    lr, defr, lsl #16
        JRCI

jpnn:   TIME    10
        ldr     lr, [mem, pcff, lsr #16]
        pkhbt   pcff, pcff, lr, lsl #16
        pkhtb   hlmp, hlmp, lr
        PREFIX0

jpcc:   TIME    10
        ldr     lr, [mem, pcff, lsr #16]
        pkhbt   pcff, pcff, lr, lsl #16
        PREFIX0

jpz:    movs    lr, defr, lsl #16
        JPC
jpnz:   movs    lr, defr, lsl #16
        JPCI
jpnc:   tst     pcff, #0x00000100
        JPC
jpc:    tst     pcff, #0x00000100
        JPCI
jpp:    tst     pcff, #0x00000080
        JPC
jpm:    tst     pcff, #0x00000080
        JPCI

ldbn:   LDRIM   bcfb, 8
ldcn:   LDRIM   bcfb, 0
lddn:   LDRIM   defr, 8
lden:   LDRIM   defr, 0

      .if fast==0
lxhn:   movs    lr, arvpref, lsl #24
        beq     ldhn
        bmi     ldiyhn
      .endif
ldixhn: LDRIM   ixstart, 8
ldiyhn: LDRIM   iyi, 8
ldhn:   LDRIM   hlmp, 8

      .if fast==0
lxln:   movs    lr, arvpref, lsl #24
        beq     ldln
        bmi     ldiyln
      .endif
ldixln: LDRIM   ixstart, 0
ldiyln: LDRIM   iyi, 0
ldln:   LDRIM   hlmp, 0

ldan:   LDRIM   arvpref, 8

ldann:  TIME    13
        ldr     lr, [mem, pcff, lsr #16]
        mov     lr, lr, lsl #16
        ldrb    r11, [mem, lr, lsr #16]
        bic     arvpref, #0xff000000
        orr     arvpref, r11, lsl #24
        add     pcff, #0x00020000
        add     lr, #0x00010000
        pkhtb   hlmp, hlmp, lr, asr #16
        PREFIX0

ldnna:  TIME    13
        ldr     lr, [mem, pcff, lsr #16]
        mov     lr, lr, lsl #16
        mov     r11, arvpref, lsr #24
        strb    r11, [mem, lr, lsr #16]
        add     pcff, #0x00020000
        add     lr, #0x00010000
        and     lr, #0x00ff0000
        orr     lr, r11, lsl #24
        pkhtb   hlmp, hlmp, lr, asr #16
        PREFIX0

ldbc:   LDXX    bcfb, 8, bcfb, 0
ldbd:   LDXX    bcfb, 8, defr, 8
ldbe:   LDXX    bcfb, 8, defr, 0
      .if fast==0
lxbh:   movs    lr, arvpref, lsl #24
        beq     ldbh
        bmi     ldbiyh
      .endif
ldbixh: LDXX    bcfb, 8, ixstart, 8
ldbiyh: LDXX    bcfb, 8, iyi, 8
ldbh:   LDXX    bcfb, 8, hlmp, 8

      .if fast==0
lxbl:   movs    lr, arvpref, lsl #24
        beq     ldbl
        bmi     ldbiyl
      .endif
ldbixl: LDXX    bcfb, 8, ixstart, 0
ldbiyl: LDXX    bcfb, 8, iyi, 0
ldbl:   LDXX    bcfb, 8, hlmp, 0

ldba:   LDXX    bcfb, 8, arvpref, 8
ldcb:   LDXX    bcfb, 0, bcfb, 8
ldcd:   LDXX    bcfb, 0, defr, 8
ldce:   LDXX    bcfb, 0, defr, 0

      .if fast==0
lxch:   movs    lr, arvpref, lsl #24
        beq     ldch
        bmi     ldciyh
      .endif
ldcixh: LDXX    bcfb, 0, ixstart, 8
ldciyh: LDXX    bcfb, 0, iyi, 8
ldch:   LDXX    bcfb, 0, hlmp, 8

      .if fast==0
lxcl:   movs    lr, arvpref, lsl #24
        beq     ldcl
        bmi     ldciyl
      .endif
ldcixl: LDXX    bcfb, 0, ixstart, 0
ldciyl: LDXX    bcfb, 0, iyi, 0
ldcl:   LDXX    bcfb, 0, hlmp, 0

ldca:   LDXX    bcfb, 0, arvpref, 8
lddb:   LDXX    defr, 8, bcfb, 8
lddc:   LDXX    defr, 8, bcfb, 0
ldde:   LDXX    defr, 8, defr, 0

      .if fast==0
lxdh:   movs    lr, arvpref, lsl #24
        beq     lddh
        bmi     lddiyh
      .endif
lddixh: LDXX    defr, 8, ixstart, 8
lddiyh: LDXX    defr, 8, iyi, 8
lddh:   LDXX    defr, 8, hlmp, 8

      .if fast==0
lxdl:   movs    lr, arvpref, lsl #24
        beq     lddl
        bmi     lddiyl
      .endif
lddixl: LDXX    defr, 8, ixstart, 0
lddiyl: LDXX    defr, 8, iyi, 0
lddl:   LDXX    defr, 8, hlmp, 0

ldda:   LDXX    defr, 8, arvpref, 8
ldeb:   LDXX    defr, 0, bcfb, 8
ldec:   LDXX    defr, 0, bcfb, 0
lded:   LDXX    defr, 0, defr, 8

      .if fast==0
lxeh:   movs    lr, arvpref, lsl #24
        beq     ldeh
        bmi     ldeiyh
      .endif
ldeixh: LDXX    defr, 0, ixstart, 8
ldeiyh: LDXX    defr, 0, iyi, 8
ldeh:   LDXX    defr, 0, hlmp, 8

      .if fast==0
lxel:   movs    lr, arvpref, lsl #24
        beq     ldel
        bmi     ldeiyl
      .endif
ldeixl: LDXX    defr, 0, ixstart, 0
ldeiyl: LDXX    defr, 0, iyi, 0
ldel:   LDXX    defr, 0, hlmp, 0

ldea:   LDXX    defr, 0, arvpref, 8

      .if fast==0
lxhb:   movs    lr, arvpref, lsl #24
        beq     ldhb
        bmi     ldiyhb
      .endif
ldixhb: LDXX    ixstart, 8, bcfb, 8
ldiyhb: LDXX    iyi, 8, bcfb, 8
ldhb:   LDXX    hlmp, 8, bcfb, 8

      .if fast==0
lxhc:   movs    lr, arvpref, lsl #24
        beq     ldhc
        bmi     ldiyhc
      .endif
ldixhc: LDXX    ixstart, 8, bcfb, 0
ldiyhc: LDXX    iyi, 8, bcfb, 0
ldhc:   LDXX    hlmp, 8, bcfb, 0

      .if fast==0
lxhd:   movs    lr, arvpref, lsl #24
        beq     ldhd
        bmi     ldiyhd
      .endif
ldixhd: LDXX    ixstart, 8, defr, 8
ldiyhd: LDXX    iyi, 8, defr, 8
ldhd:   LDXX    hlmp, 8, defr, 8

      .if fast==0
lxhe:   movs    lr, arvpref, lsl #24
        beq     ldhe
        bmi     ldiyhe
      .endif
ldixhe: LDXX    ixstart, 8, defr, 0
ldiyhe: LDXX    iyi, 8, defr, 0
ldhe:   LDXX    hlmp, 8, defr, 0

      .if fast==0
lxhl:   movs    lr, arvpref, lsl #24
        beq     ldhl
        bmi     ldyhyl
      .endif
ldxhxl: LDXX    ixstart, 8, ixstart, 0
ldyhyl: LDXX    iyi, 8, iyi, 0
ldhl:   LDXX    hlmp, 8, hlmp, 0

      .if fast==0
lxha:   movs    lr, arvpref, lsl #24
        beq     ldha
        bmi     ldiyha
      .endif
ldixha: LDXX    ixstart, 8, arvpref, 8
ldiyha: LDXX    iyi, 8, arvpref, 8
ldha:   LDXX    hlmp, 8, arvpref, 8

      .if fast==0
lxlb:   movs    lr, arvpref, lsl #24
        beq     ldlb
        bmi     ldiylb
      .endif
ldixlb: LDXX    ixstart, 0, bcfb, 8
ldiylb: LDXX    iyi, 0, bcfb, 8
ldlb:   LDXX    hlmp, 0, bcfb, 8

      .if fast==0
lxlc:   movs    lr, arvpref, lsl #24
        beq     ldlc
        bmi     ldiylc
      .endif
ldixlc: LDXX    ixstart, 0, bcfb, 0
ldiylc: LDXX    iyi, 0, bcfb, 0
ldlc:   LDXX    hlmp, 0, bcfb, 0

      .if fast==0
lxld:   movs    lr, arvpref, lsl #24
        beq     ldld
        bmi     ldiyld
      .endif
ldixld: LDXX    ixstart, 0, defr, 8
ldiyld: LDXX    iyi, 0, defr, 8
ldld:   LDXX    hlmp, 0, defr, 8

      .if fast==0
lxle:   movs    lr, arvpref, lsl #24
        beq     ldle
        bmi     ldiyle
      .endif
ldixle: LDXX    ixstart, 0, defr, 0
ldiyle: LDXX    iyi, 0, defr, 0
ldle:   LDXX    hlmp, 0, defr, 0

      .if fast==0
lxlh:   movs    lr, arvpref, lsl #24
        beq     ldlh
        bmi     ldylyh
      .endif
ldxlxh: LDXX    ixstart, 0, ixstart, 8
ldylyh: LDXX    iyi, 0, iyi, 8
ldlh:   LDXX    hlmp, 0, hlmp, 8

      .if fast==0
lxla:   movs    lr, arvpref, lsl #24
        beq     ldla
        bmi     ldiyla
      .endif
ldixla: LDXX    ixstart, 0, arvpref, 8
ldiyla: LDXX    iyi, 0, arvpref, 8
ldla:   LDXX    hlmp, 0, arvpref, 8

ldab:   LDXX    arvpref, 8, bcfb, 8
ldac:   LDXX    arvpref, 8, bcfb, 0
ldad:   LDXX    arvpref, 8, defr, 8
ldae:   LDXX    arvpref, 8, defr, 0

      .if fast==0
lxah:   movs    lr, arvpref, lsl #24
        beq     ldah
        bmi     ldaiyh
      .endif
ldaixh: LDXX    arvpref, 8, ixstart, 8
ldaiyh: LDXX    arvpref, 8, iyi, 8
ldah:   LDXX    arvpref, 8, hlmp, 8

      .if fast==0
lxal:   movs    lr, arvpref, lsl #24
        beq     ldal
        bmi     ldaiyl
      .endif
ldaixl: LDXX    arvpref, 8, ixstart, 0
ldaiyl: LDXX    arvpref, 8, iyi, 0
ldal:   LDXX    arvpref, 8, hlmp, 0

inca:   INC     arvpref, 8
incb:   INC     bcfb, 8
incc:   INC     bcfb, 0
incd:   INC     defr, 8
ince:   INC     defr, 0

      .if fast==0
inchx:  movs    lr, arvpref, lsl #24
        beq     inch
        bmi     inciyh
      .endif
incixh: INC     ixstart, 8
inciyh: INC     iyi, 8
inch:   INC     hlmp, 8

      .if fast==0
inclx:  movs    lr, arvpref, lsl #24
        beq     incl
        bmi     inciyl
      .endif
incixl: INC     ixstart, 0
inciyl: INC     iyi, 0
incl:   INC     hlmp, 0

      .if fast==0
incpxx: movs    lr, arvpref, lsl #24
        beq     incphl
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        bmi     incpiy
incpix: INCPI   ixstart
incpiy: INCPI   iyi
      .else
incpix: ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        INCPI   ixstart
incpiy: ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        INCPI   iyi
      .endif
incphl: TIME    11
        ldrb    lr, [mem, hlmp, lsr #16]
        pkhtb   spfa, spfa, lr
        mov     lr, #0x00000001
        pkhtb   bcfb, bcfb, lr
        add     lr, spfa
        strb    lr, [mem, hlmp, lsr #16]
        uxtb    lr, lr
        pkhtb   defr, defr, lr
        and     r11, pcff, #0x00000100
        orr     lr, r11
        pkhtb   pcff, pcff, lr
        PREFIX0

      .if fast==0
decpxx: movs    lr, arvpref, lsl #24
        beq     decphl
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        bmi     decpiy
decpix: DECPI   ixstart
decpiy: DECPI   iyi
      .else
decpix: ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        DECPI   ixstart
decpiy: ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        DECPI   iyi
      .endif
decphl: TIME    11
        ldrb    lr, [mem, hlmp, lsr #16]
        pkhtb   spfa, spfa, lr
        mov     lr, #0xffffffff
        pkhtb   bcfb, bcfb, lr
        add     lr, spfa
        strb    lr, [mem, hlmp, lsr #16]
        uxtb    lr, lr
        pkhtb   defr, defr, lr
        and     r11, pcff, #0x00000100
        orr     lr, r11
        pkhtb   pcff, pcff, lr
        PREFIX0

deca:   DEC     arvpref, 8
decb:   DEC     bcfb, 8
decc:   DEC     bcfb, 0
decd:   DEC     defr, 8
dece:   DEC     defr, 0

      .if fast==0
dechx:  movs    lr, arvpref, lsl #24
        beq     dech
        bmi     deciyh
      .endif
decixh: DEC     ixstart, 8
deciyh: DEC     iyi, 8
dech:   DEC     hlmp, 8

      .if fast==0
declx:  movs    lr, arvpref, lsl #24
        beq     decl
        bmi     deciyl
      .endif
decixl: DEC     ixstart, 0
deciyl: DEC     iyi, 0
decl:   DEC     hlmp, 0

rst00:  RST     0x00
rst08:  RST     0x18
rst10:  RST     0x10
rst18:  RST     0x18
rst20:  RST     0x20
rst28:  RST     0x28
rst30:  RST     0x30
rst38:  RST     0x38

addab:  XADD    bcfb, 8, 4
addac:  XADD    bcfb, 0, 4
addad:  XADD    defr, 8, 4
addae:  XADD    defr, 0, 4

      .if fast==0
addxh:  movs    lr, arvpref, lsl #24
        beq     addah
        bmi     addayh
      .endif
addaxh: XADD    ixstart, 8, 4
addayh: XADD    iyi, 8, 4
addah:  XADD    hlmp, 8, 4

      .if fast==0
addxl:  movs    lr, arvpref, lsl #24
        beq     addal
        bmi     addayl
      .endif
addaxl: XADD    ixstart, 0, 4
addayl: XADD    iyi, 0, 4
addal:  XADD    hlmp, 0, 4

      .if fast==0
addaxx: movs    lr, arvpref, lsl #24
        beq     addahl
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        bmi     addaiy
addaix: add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        XADD    lr, 24, 7
addaiy: add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        XADD    lr, 24, 7
      .else
addaix: ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        XADD    lr, 24, 7
addaiy: ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        XADD    lr, 24, 7
      .endif
addahl: ldrb    lr, [mem, hlmp, lsr #16]
        XADD    lr, 24, 7

addan:  ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        XADD    lr, 24, 7

addaa:  TIME    4
        mov     lr, arvpref, lsr #24
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr
        mov     lr, lr, lsl #1
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr  @ importante
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        pkhtb   defr, defr, lr
        PREFIX0

adcab:  XADC    bcfb, 8, 4
adcac:  XADC    bcfb, 0, 4
adcad:  XADC    defr, 8, 4
adcae:  XADC    defr, 0, 4

      .if fast==0
adcahx: movs    lr, arvpref, lsl #24
        beq     adcah
        bmi     adcayh
      .endif
adcaxh: XADC    ixstart, 8, 4
adcayh: XADC    iyi, 8, 4
adcah:  XADC    hlmp, 8, 4

      .if fast==0
adcalx: movs    lr, arvpref, lsl #24
        beq     adcal
        bmi     adcayl
      .endif
adcaxl: XADC    ixstart, 0, 4
adcayl: XADC    iyi, 0, 4
adcal:  XADC    hlmp, 0, 4

      .if fast==0
adcaxx: movs    lr, arvpref, lsl #24
        beq     adcahl
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        bmi     adcaiy
adcaix: add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        XADC    lr, 24, 7
adcaiy: add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        XADC    lr, 24, 7
      .else
adcaix: ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        XADC    lr, 24, 7
adcaiy: ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        XADC    lr, 24, 7
      .endif
adcahl: ldrb    lr, [mem, hlmp, lsr #16]
        XADC    lr, 24, 7

adcan:  ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        XADC    lr, 24, 7

adcaa:  TIME    4
        mov     lr, arvpref, lsr #24
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr
        movs    r11, pcff, lsr #9
        adc     lr, lr, lr
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr  @ importante
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        pkhtb   defr, defr, lr
        PREFIX0

subb:   XSUB    bcfb, 8, 4
subc:   XSUB    bcfb, 0, 4
subd:   XSUB    defr, 8, 4
sube:   XSUB    defr, 0, 4

      .if fast==0
subhx:  movs    lr, arvpref, lsl #24
        beq     subh
        bmi     subyh
      .endif
subxh:  XSUB    ixstart, 8, 4
subyh:  XSUB    iyi, 8, 4
subh:   XSUB    hlmp, 8, 4

      .if fast==0
sublx:  movs    lr, arvpref, lsl #24
        beq     subl
        bmi     subyl
      .endif
subxl:  XSUB    ixstart, 0, 4
subyl:  XSUB    iyi, 0, 4
subl:   XSUB    hlmp, 0, 4

      .if fast==0
subxx:  movs    lr, arvpref, lsl #24
        beq     subhl
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        bmi     subiy
subix:  add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        XSUB    lr, 24, 7
subiy:  add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        XSUB    lr, 24, 7
      .else
subix:  ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        XSUB    lr, 24, 7
subiy:  ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        XSUB    lr, 24, 7
      .endif
subhl:  ldrb    lr, [mem, hlmp, lsr #16]
        XSUB    lr, 24, 7

subn:   ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        XSUB    lr, 24, 7

suba:   TIME    4
        mov     lr, arvpref, lsr #24
        pkhtb   spfa, spfa, lr
        mvn     r11, lr
        pkhtb   bcfb, bcfb, r11
        bic     arvpref, #0xff000000
        pkhtb   pcff, pcff, lr, asr #16
        pkhtb   defr, defr, lr, asr #16
        PREFIX0

sbcab:  XSBC    bcfb, 8, 4
sbcac:  XSBC    bcfb, 0, 4
sbcad:  XSBC    defr, 8, 4
sbcae:  XSBC    defr, 0, 4

      .if fast==0
sbcahx: movs    lr, arvpref, lsl #24
        beq     sbcah
        bmi     sbcayh
      .endif
sbcaxh: XSBC    ixstart, 8, 4
sbcayh: XSBC    iyi, 8, 4
sbcah:  XSBC    hlmp, 8, 4

      .if fast==0
sbcalx: movs    lr, arvpref, lsl #24
        beq     sbcal
        bmi     sbcayl
      .endif
sbcaxl: XSBC    ixstart, 0, 4
sbcayl: XSBC    iyi, 0, 4
sbcal:  XSBC    hlmp, 0, 4

      .if fast==0
sbcaxx: movs    lr, arvpref, lsl #24
        beq     sbcahl
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        bmi     sbcaiy
sbcaix: add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        XSBC    lr, 24, 7
sbcaiy: add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        XSBC    lr, 24, 7
      .else
sbcaix: ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        XSBC    lr, 24, 7
sbcaiy: ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        XSBC    lr, 24, 7
      .endif
sbcahl: ldrb    lr, [mem, hlmp, lsr #16]
        XSBC    lr, 24, 7

sbcan:  ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        XSBC    lr, 24, 7

sbcaa:  TIME    4
        mov     lr, arvpref, lsr #24
        pkhtb   spfa, spfa, lr
        mvn     r11, lr
        pkhtb   bcfb, bcfb, r11
        eor     lr, pcff, #0x00000100
        movs    lr, lr, lsl #24
        sbc     lr, lr
        pkhtb   pcff, pcff, lr
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        pkhtb   defr, defr, lr
        PREFIX0

andb:   XAND    bcfb, 8, 4
andc:   XAND    bcfb, 0, 4
andd:   XAND    defr, 8, 4
ande:   XAND    defr, 0, 4

      .if fast==0
andhx:  movs    lr, arvpref, lsl #24
        beq     andh
        bmi     andyh
      .endif
andxh:  XAND    ixstart, 8, 4
andyh:  XAND    iyi, 8, 4
andh:   XAND    hlmp, 8, 4

      .if fast==0
andlx:  movs    lr, arvpref, lsl #24
        beq     andl
        bmi     andyl
      .endif
andxl:  XAND    ixstart, 0, 4
andyl:  XAND    iyi, 0, 4
andl:   XAND    hlmp, 0, 4

      .if fast==0
andxx:  movs    lr, arvpref, lsl #24
        beq     andhl
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        bmi     andiy
andix:  add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        XAND    lr, 24, 7
andiy:  add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        XAND    lr, 24, 7
      .else
andix:  ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        XAND    lr, 24, 7
andiy:  ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        XAND    lr, 24, 7
      .endif
andhl:  ldrb    lr, [mem, hlmp, lsr #16]
        XAND    lr, 24, 7

andan:  ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        XAND    lr, 24, 7

anda:   TIME    4
        mov     lr, arvpref, lsr #24
        pkhtb   bcfb, bcfb, lr, asr #16
        pkhtb   defr, defr, lr
        pkhtb   pcff, pcff, lr
        mvn     lr, lr
        pkhtb   spfa, spfa, lr
        PREFIX0

xorb:   XOR     bcfb, 8, 4
xorc:   XOR     bcfb, 0, 4
xord:   XOR     defr, 8, 4
xore:   XOR     defr, 0, 4

      .if fast==0
xorhx:  movs    lr, arvpref, lsl #24
        beq     xorh
        bmi     xoryh
      .endif
xorxh:  XOR     ixstart, 8, 4
xoryh:  XOR     iyi, 8, 4
xorh:   XOR     hlmp, 8, 4

      .if fast==0
xorlx:  movs    lr, arvpref, lsl #24
        beq     xorl
        bmi     xoryl
      .endif
xorxl:  XOR     ixstart, 0, 4
xoryl:  XOR     iyi, 0, 4
xorl:   XOR     hlmp, 0, 4

      .if fast==0
xorxx:  movs    lr, arvpref, lsl #24
        beq     xorhl
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        bmi     xoriy
xorix:  add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        XOR     lr, 24, 7
xoriy:  add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        XOR     lr, 24, 7
      .else
xorix:  ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        XOR     lr, 24, 7
xoriy:  ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        XOR     lr, 24, 7
      .endif
xorhl:  ldrb    lr, [mem, hlmp, lsr #16]
        XOR     lr, 24, 7

xoran:  ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        XOR     lr, 24, 7

xora:   TIME    4
        mov     lr, #0x00000100
        pkhtb   bcfb, bcfb, lr, asr #16
        pkhtb   defr, defr, lr, asr #16
        pkhtb   pcff, pcff, lr, asr #16
        bic     arvpref, #0xff000000
        pkhtb   spfa, spfa, lr
        PREFIX0

orb:    OR      bcfb, 8, 4
orc:    OR      bcfb, 0, 4
ord:    OR      defr, 8, 4
ore:    OR      defr, 0, 4

      .if fast==0
orhx:   movs    lr, arvpref, lsl #24
        beq     orh
        bmi     oryh
      .endif
orxh:   OR      ixstart, 8, 4
oryh:   OR      iyi, 8, 4
orh:    OR      hlmp, 8, 4

      .if fast==0
orlx:   movs    lr, arvpref, lsl #24
        beq     orl
        bmi     oryl
      .endif
orxl:   OR      ixstart, 0, 4
oryl:   OR      iyi, 0, 4
orl:    OR      hlmp, 0, 4

      .if fast==0
orxx:   movs    lr, arvpref, lsl #24
        beq     orhl
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        bmi     oriy
orix:   add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        OR      lr, 24, 7
oriy:   add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        OR      lr, 24, 7
      .else
orix:   ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        OR      lr, 24, 7
oriy:   ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        OR      lr, 24, 7
      .endif
orhl:   ldrb    lr, [mem, hlmp, lsr #16]
        OR      lr, 24, 7

oran:   ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        OR      lr, 24, 7

ora:    TIME    4
        mov     lr, arvpref, lsr #24
        pkhtb   defr, defr, lr
        pkhtb   pcff, pcff, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        PREFIX0

cpb:    CP      bcfb, 8, 4
cpc:    CP      bcfb, 0, 4
cp_d:   CP      defr, 8, 4
cpe:    CP      defr, 0, 4

      .if fast==0
cphx:   movs    lr, arvpref, lsl #24
        beq     cph
        bmi     cpyh
      .endif
cpxh:   CP      ixstart, 8, 4
cpyh:   CP      iyi, 8, 4
cph:    CP      hlmp, 8, 4

      .if fast==0
cplx:   movs    lr, arvpref, lsl #24
        beq     cp_l
        bmi     cpyl
      .endif
cpxl:   CP      ixstart, 0, 4
cpyl:   CP      iyi, 0, 4
cp_l:   CP      hlmp, 0, 4

cpan:   ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        CP      lr, 24, 7

      .if fast==0
cpxx:   movs    lr, arvpref, lsl #24
        beq     cphl
        ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        bmi     cpiy
cpix:   add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        CP      lr, 24, 7
cpiy:   add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        CP      lr, 24, 7
      .else
cpix:   ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, ixstart, lsr #16
        ldrb    lr, [mem, lr]
        CP      lr, 24, 7
cpiy:   ldr     lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        sxtb    lr, lr
        add     lr, iyi, lsr #16
        ldrb    lr, [mem, lr]
        CP      lr, 24, 7
      .endif
cphl:   ldrb    lr, [mem, hlmp, lsr #16]
        CP      lr, 24, 7

cpa:    TIME    4
        mov     lr, arvpref, lsr #24
        pkhtb   defr, defr, lr, asr #16
        pkhtb   spfa, spfa, lr
        mvn     r11, lr
        pkhtb   bcfb, bcfb, r11
        and     lr, #0x00000028
        pkhtb   pcff, pcff, lr
        PREFIX0

scf:    TIME    4
        and     lr, bcfb, #0x00000080
        eor     r11, defr, spfa
        and     r11, #0x00000010
        orr     lr, r11
        pkhtb   bcfb, bcfb, lr
        and     lr, arvpref, #0x28000000
        and     r11, pcff, #0x00000080
        orr     r11, lr, lsr #24
        orr     r11, #0x00000100
        pkhtb   pcff, pcff, r11
        PREFIX0

ccf:    TIME    4
        and     lr, bcfb, #0x00000080
        eor     r11, defr, spfa
        eor     r11, pcff, lsr #4
        and     r11, #0x00000010
        orr     lr, r11
        pkhtb   bcfb, bcfb, lr
        and     lr, arvpref, #0x28000000
        and     r11, pcff, #0x00000180
        orr     r11, lr, lsr #24
        eor     r11, #0x00000100
        pkhtb   pcff, pcff, r11
        PREFIX0

      .if fast==0
lxbhl:  movs    lr, arvpref, lsl #24
        beq     ldbhl
        bmi     ldbiy
      .endif
ldbix:  LDRPI   ixstart, bcfb, 8
ldbiy:  LDRPI   iyi, bcfb, 8
ldbhl:  LDRP    hlmp, bcfb, 8

      .if fast==0
lxchl:  movs    lr, arvpref, lsl #24
        beq     ldchl
        bmi     ldciy
      .endif
ldcix:  LDRPI   ixstart, bcfb, 0
ldciy:  LDRPI   iyi, bcfb, 0
ldchl:  LDRP    hlmp, bcfb, 0

      .if fast==0
lxdhl:  movs    lr, arvpref, lsl #24
        beq     lddhl
        bmi     lddiy
      .endif
lddix:  LDRPI   ixstart, defr, 8
lddiy:  LDRPI   iyi, defr, 8
lddhl:  LDRP    hlmp, defr, 8

      .if fast==0
lxehl:  movs    lr, arvpref, lsl #24
        beq     ldehl
        bmi     ldeiy
      .endif
ldeix:  LDRPI   ixstart, defr, 0
ldeiy:  LDRPI   iyi, defr, 0
ldehl:  LDRP    hlmp, defr, 0

      .if fast==0
lxhhl:  movs    lr, arvpref, lsl #24
        beq     ldhhl
        bmi     ldhiy
      .endif
ldhix:  LDRPI   ixstart, hlmp, 8
ldhiy:  LDRPI   iyi, hlmp, 8
ldhhl:  LDRP    hlmp, hlmp, 8

      .if fast==0
lxlhl:  movs    lr, arvpref, lsl #24
        beq     ldlhl
        bmi     ldliy
      .endif
ldlix:  LDRPI   ixstart, hlmp, 0
ldliy:  LDRPI   iyi, hlmp, 0
ldlhl:  LDRP    hlmp, hlmp, 0

      .if fast==0
lxahl:  movs    lr, arvpref, lsl #24
        beq     ldahl
        bmi     ldaiy
      .endif
ldaix:  LDRPI   ixstart, arvpref, 8
ldaiy:  LDRPI   iyi, arvpref, 8
ldahl:  LDRP    hlmp, arvpref, 8

ldabc:  LDRP    bcfb, arvpref, 8
ldade:  LDRP    defr, arvpref, 8

ldbca:  LDPR    bcfb, arvpref, 8
lddea:  LDPR    defr, arvpref, 8

      .if fast==0
ldxxb:  movs    lr, arvpref, lsl #24
        beq     ldhlb
        bmi     ldiyb
      .endif
ldixb:  LDPRI   ixstart, bcfb, 8
ldiyb:  LDPRI   iyi, bcfb, 8
ldhlb:  LDPR    hlmp, bcfb, 8

      .if fast==0
ldxxc:  movs    lr, arvpref, lsl #24
        beq     ldhlc
        bmi     ldiyc
      .endif
ldixc:  LDPRI   ixstart, bcfb, 0
ldiyc:  LDPRI   iyi, bcfb, 0
ldhlc:  LDPR    hlmp, bcfb, 0

      .if fast==0
ldxxd:  movs    lr, arvpref, lsl #24
        beq     ldhld
        bmi     ldiyd
      .endif
ldixd:  LDPRI   ixstart, defr, 8
ldiyd:  LDPRI   iyi, defr, 8
ldhld:  LDPR    hlmp, defr, 8

      .if fast==0
ldxxe:  movs    lr, arvpref, lsl #24
        beq     ldhle
        bmi     ldiye
      .endif
ldixe:  LDPRI   ixstart, defr, 0
ldiye:  LDPRI   iyi, defr, 0
ldhle:  LDPR    hlmp, defr, 0

      .if fast==0
ldxxh:  movs    lr, arvpref, lsl #24
        beq     ldhlh
        bmi     ldiyh
      .endif
ldixh:  LDPRI   ixstart, hlmp, 8
ldiyh:  LDPRI   iyi, hlmp, 8
ldhlh:  LDPR    hlmp, hlmp, 8

      .if fast==0
ldxxl:  movs    lr, arvpref, lsl #24
        beq     ldhll
        bmi     ldiyl
      .endif
ldixl:  LDPRI   ixstart, hlmp, 0
ldiyl:  LDPRI   iyi, hlmp, 0
ldhll:  LDPR    hlmp, hlmp, 0

halt:   TIME    4
        orr     arvpref, #0x00000800
        sub     pcff, #0x00010000
        PREFIX0

      .if fast==0
ldxxa:  movs    lr, arvpref, lsl #24
        beq     ldhla
        bmi     ldiya
      .endif
ldixa:  LDPRI   ixstart, arvpref, 8
ldiya:  LDPRI   iyi, arvpref, 8
ldhla:  LDPR    hlmp, arvpref, 8

incbc:  INCW    bcfb
incde:  INCW    defr
incsp:  INCW    spfa

      .if fast==0
inchlx: movs    lr, arvpref, lsl #24
        beq     inchl
        bmi     inciy
      .endif
incix:  INCW    ixstart
inciy:  INCW    iyi
inchl:  INCW    hlmp

decbc:  DECW    bcfb
decde:  DECW    defr
decsp:  DECW    spfa

      .if fast==0
dechlx: movs    lr, arvpref, lsl #24
        beq     dechl
        bmi     deciy
      .endif
decix:  DECW    ixstart
deciy:  DECW    iyi
dechl:  DECW    hlmp

pushaf: and     lr, arvpref, #0xff000000
        and     r11, pcff, #0x000000a8
        orr     r11, lr, r11, lsl #16
        movs    lr, pcff, lsr #9
        orrcs   r11, #0x00010000
        movs    lr, bcfb, lsr #10
        orrcs   r11, #0x00020000
        movs    lr, defr, lsl #16
        orreq   r11, #0x00400000
        eor     lr, defr, spfa
        eor     r10, bcfb, bcfb, lsr #8
        eor     lr, r10
        movs    lr, lr, lsr #5
        orrcs   r11, #0x00100000
        tst     spfa, #0x00000100
        beq     over5
        ldr     lr, cb34
        eor     r10, defr, defr, lsr #4
        tst     lr, lr, ror r10
        orrmi   r11, #0x00040000
        PUS     r11
over5:  eor     lr, spfa, defr
        eor     r10, bcfb, defr
        and     lr, r10
        movs    lr, lr, lsr #8
        orrcs   r11, #0x00040000
        PUS     r11

pushbc: PUS     bcfb
pushde: PUS     defr

      .if fast==0
pushxx: movs    lr, arvpref, lsl #24
        beq     pushhl
        bmi     pushiy
      .endif
pushix: PUS     ixstart
pushiy: PUS     iyi
pushhl: PUS     hlmp

popaf:  TIME    10
        ldr     lr, [mem, spfa, lsr #16]
        add     spfa, #0x00020000
        rev16   lr, lr
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        uxtb    lr, lr, ror #8
        mvn     r11, lr
        and     r11, #0x00000040
        pkhtb   defr, defr, r11
        orr     lr, lr, lr, lsl #8
        pkhtb   pcff, pcff, lr
        and     r11, lr, #0x00000004
        eor     lr, r11, lsl #5
        and     lr, #0xffffff7f
        eor     lr, r11, lsl #5
        pkhtb   bcfb, bcfb, lr
        uxtb    lr, lr
        pkhtb   spfa, spfa, lr
        PREFIX0

popbc:  POPP    bcfb
        PREFIX0

popde:  POPP    defr
        PREFIX0

      .if fast==0
popxx:  movs    lr, arvpref, lsl #24
        beq     pophl
        bmi     popiy
      .endif
popix:  POPP    ixstart
        PREFIX0
popiy:  POPP    iyi
        PREFIX0
pophl:  POPP    hlmp
        PREFIX0

      .if fast==0
exspxx: movs    lr, arvpref, lsl #24
        beq     exsphl
        bmi     exspiy
      .endif
exspix: EXSPI   ixstart
        PREFIX0
exspiy: EXSPI   iyi
        PREFIX0
exsphl: EXSPI   hlmp
        PREFIX0

exafaf: TIME    4
        mov     lr, arvpref, lsr #24
        add     r11, punt, #oa_
        swpb    lr, lr, [r11]
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        pkhbt   r11, spfa, bcfb, lsl #16
        add     lr, punt, #ofa_
        swp     r11, r11, [lr]
        pkhtb   spfa, spfa, r11
        pkhtb   bcfb, bcfb, r11, asr #16
        pkhbt   r11, pcff, defr, lsl #16
        add     lr, punt, #off_
        swp     r11, r11, [lr]
        pkhtb   pcff, pcff, r11
        pkhtb   defr, defr, r11, asr #16
        PREFIX0

exdehl: TIME    4
        mov     lr, hlmp
        pkhbt   hlmp, hlmp, defr
        pkhbt   defr, defr, lr
        PREFIX0

exx:    TIME    4
        pkhtb   r10, defr, bcfb, asr #16
        add     lr, punt, #oc_
        swp     r10, r10, [lr]
        pkhtb   defr, r10, defr
        pkhbt   bcfb, bcfb, r10, lsl #16
        add     lr, #4
        swp     r10, hlmp, [lr]
        pkhbt   hlmp, hlmp, r10
        PREFIX0

callpo: tst     spfa, #0x00000100
        beq     over1
        ldr     r11, cb34
        eor     lr, defr, defr, lsr #4
        tst     r11, r11, ror lr
        bmi     callnn
        TIME    10
        add     pcff, #0x00020000
        PREFIX0
over1:  eor     lr, spfa, defr
        eor     r11, bcfb, defr
        and     lr, r11
        tst     lr, #0x80
        CALLC

callpe: tst     spfa, #0x00000100
        beq     over2
        ldr     r11, cb34
        eor     lr, defr, defr, lsr #4
        tst     r11, r11, ror lr
        bpl     callnn
        TIME    10
        add     pcff, #0x00020000
        PREFIX0
over2:  eor     lr, spfa, defr
        eor     r11, bcfb, defr
        and     lr, r11
        tst     lr, #0x80
        CALLCI

retpo:  tst     spfa, #0x00000100
        beq     over3
        ldr     r11, cb34
        eor     lr, defr, defr, lsr #4
        tst     r11, r11, ror lr
        bmi     ret11
        TIME    5
        PREFIX0
over3:  eor     lr, spfa, defr
        eor     r11, bcfb, defr
        and     lr, r11
        tst     lr, #0x80
        RETC

retpe:  tst     spfa, #0x00000100
        beq     over4
        ldr     r11, cb34
        eor     lr, defr, defr, lsr #4
        tst     r11, r11, ror lr
        bpl     ret11
        TIME    5
        PREFIX0
over4:  eor     lr, spfa, defr
        eor     r11, bcfb, defr
        and     lr, r11
        tst     lr, #0x80
        RETCI

jppo:   tst     spfa, #0x00000100
        beq     over6
        ldr     r11, cb34
        eor     lr, defr, defr, lsr #4
        tst     r11, r11, ror lr
        bmi     jpnn
        TIME    10
        add     pcff, #0x00020000
        PREFIX0
over6:  eor     lr, spfa, defr
        eor     r11, bcfb, defr
        and     lr, r11
        tst     lr, #0x80
        JPC

jppe:   tst     spfa, #0x00000100
        beq     over7
        ldr     r11, cb34
        eor     lr, defr, defr, lsr #4
        tst     r11, r11, ror lr
        bpl     jpnn
        TIME    10
        add     pcff, #0x00020000
        PREFIX0
over7:  eor     lr, spfa, defr
        eor     r11, bcfb, defr
        and     lr, r11
        tst     lr, #0x80
        JPCI

oped:   mov     lr, #0x00010000
        uadd8   arvpref, arvpref, lr
        bic     arvpref, #0xff
        ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        ldr     pc, [pc, lr, lsl #2]
cb34:   .word   0xcb34cb34
        .word   nop8          @ 00 NOP8
        .word   nop8          @ 01 NOP8
        .word   nop8          @ 02 NOP8
        .word   nop8          @ 03 NOP8
        .word   nop8          @ 04 NOP8
        .word   nop8          @ 05 NOP8
        .word   nop8          @ 06 NOP8
        .word   nop8          @ 07 NOP8
        .word   nop8          @ 08 NOP8
        .word   nop8          @ 09 NOP8
        .word   nop8          @ 0a NOP8
        .word   nop8          @ 0b NOP8
        .word   nop8          @ 0c NOP8
        .word   nop8          @ 0d NOP8
        .word   nop8          @ 0e NOP8
        .word   nop8          @ 0f NOP8
        .word   nop8          @ 10 NOP8
        .word   nop8          @ 11 NOP8
        .word   nop8          @ 12 NOP8
        .word   nop8          @ 13 NOP8
        .word   nop8          @ 14 NOP8
        .word   nop8          @ 15 NOP8
        .word   nop8          @ 16 NOP8
        .word   nop8          @ 17 NOP8
        .word   nop8          @ 18 NOP8
        .word   nop8          @ 19 NOP8
        .word   nop8          @ 1a NOP8
        .word   nop8          @ 1b NOP8
        .word   nop8          @ 1c NOP8
        .word   nop8          @ 1d NOP8
        .word   nop8          @ 1e NOP8
        .word   nop8          @ 1f NOP8
        .word   nop8          @ 20 NOP8
        .word   nop8          @ 21 NOP8
        .word   nop8          @ 22 NOP8
        .word   nop8          @ 23 NOP8
        .word   nop8          @ 24 NOP8
        .word   nop8          @ 25 NOP8
        .word   nop8          @ 26 NOP8
        .word   nop8          @ 27 NOP8
        .word   nop8          @ 28 NOP8
        .word   nop8          @ 29 NOP8
        .word   nop8          @ 2a NOP8
        .word   nop8          @ 2b NOP8
        .word   nop8          @ 2c NOP8
        .word   nop8          @ 2d NOP8
        .word   nop8          @ 2e NOP8
        .word   nop8          @ 2f NOP8
        .word   nop8          @ 30 NOP8
        .word   nop8          @ 31 NOP8
        .word   nop8          @ 32 NOP8
        .word   nop8          @ 33 NOP8
        .word   nop8          @ 34 NOP8
        .word   nop8          @ 35 NOP8
        .word   nop8          @ 36 NOP8
        .word   nop8          @ 37 NOP8
        .word   nop8          @ 38 NOP8
        .word   nop8          @ 39 NOP8
        .word   nop8          @ 3a NOP8
        .word   nop8          @ 3b NOP8
        .word   nop8          @ 3c NOP8
        .word   nop8          @ 3d NOP8
        .word   nop8          @ 3e NOP8
        .word   nop8          @ 3f NOP8
        .word   inbc          @ 40 IN B,(C)
        .word   outcb         @ 41 OUT (C),B
        .word   sbchlbc       @ 42 SBC HL,BC
        .word   ldpnnbc       @ 43 LD (NN),BC
        .word   neg           @ 44 NEG
        .word   ret14         @ 45 RETN
        .word   im0           @ 46 IM 0
        .word   ldia          @ 47 LD I,A
        .word   in_cc         @ 48 IN C,(C)
        .word   outcc         @ 49 OUT (C),C
        .word   adchlbc       @ 4a ADC HL,BC
        .word   ldbcpnn       @ 4b LD BC,(NN)
        .word   neg           @ 4c NEG
        .word   ret14         @ 4d RETI
        .word   im0           @ 4e IM 0
        .word   ldra          @ 4f LD R,A
        .word   indc          @ 50 IN D,(C)
        .word   outcd         @ 51 OUT (C),D
        .word   sbchlde       @ 52 SBC HL,DE
        .word   ldpnnde       @ 53 LD (NN),DE
        .word   neg           @ 54 NEG
        .word   ret14         @ 55 RETN
        .word   im1           @ 56 IM 1
        .word   ldai          @ 57 LD A,I
        .word   inec          @ 58 IN E,(C)
        .word   outce         @ 59 OUT (C),E
        .word   adchlde       @ 5a ADC HL,DE
        .word   lddepnn       @ 5b LD DE,(NN)
        .word   neg           @ 5c NEG
        .word   ret14         @ 5d RETI
        .word   im2           @ 5e IM 2
        .word   ldar          @ 5f LD A,R
        .word   inhc          @ 60 IN H,(C)
        .word   outch         @ 61 OUT (C),H
        .word   sbchlhl       @ 62 SBC HL,HL
        .word   ldpnnxe       @ 63 LD (NN),HL
        .word   neg           @ 64 NEG
        .word   ret14         @ 65 RETN
        .word   im0           @ 66 IM 0
        .word   rrd           @ 67 RRD
        .word   inlc          @ 68 IN L,(C)
        .word   outcl         @ 69 OUT (C),L
        .word   adchlhl       @ 6a ADC HL,HL
        .word   ldxepnn       @ 6b LD HL,(NN)
        .word   neg           @ 6c NEG
        .word   ret14         @ 6d RETI
        .word   im0           @ 6e IM 0
        .word   rld           @ 6f RLD
        .word   inxc          @ 70 IN X,(C)
        .word   outcx         @ 71 OUT (C),X
        .word   sbchlsp       @ 72 SBC HL,SP
        .word   ldpnnsp       @ 73 LD (NN),SP
        .word   neg           @ 74 NEG
        .word   ret14         @ 75 RETN
        .word   im1           @ 76 IM 1
        .word   nop8          @ 77 NOP
        .word   inac          @ 78 IN A,(C)
        .word   outca         @ 79 OUT (C),A
        .word   adchlsp       @ 7a ADC HL,SP
        .word   ldsppnn       @ 7b LD SP,(NN)
        .word   neg           @ 7c NEG
        .word   ret14         @ 7d RETI
        .word   im2           @ 7e IM 2
        .word   nop8          @ 7f NOP8
        .word   nop8          @ 80 NOP8
        .word   nop8          @ 81 NOP8
        .word   nop8          @ 82 NOP8
        .word   nop8          @ 83 NOP8
        .word   nop8          @ 84 NOP8
        .word   nop8          @ 85 NOP8
        .word   nop8          @ 86 NOP8
        .word   nop8          @ 87 NOP8
        .word   nop8          @ 88 NOP8
        .word   nop8          @ 89 NOP8
        .word   nop8          @ 8a NOP8
        .word   nop8          @ 8b NOP8
        .word   nop8          @ 8c NOP8
        .word   nop8          @ 8d NOP8
        .word   nop8          @ 8e NOP8
        .word   nop8          @ 8f NOP8
        .word   nop8          @ 90 NOP8
        .word   nop8          @ 91 NOP8
        .word   nop8          @ 92 NOP8
        .word   nop8          @ 93 NOP8
        .word   nop8          @ 94 NOP8
        .word   nop8          @ 95 NOP8
        .word   nop8          @ 96 NOP8
        .word   nop8          @ 97 NOP8
        .word   nop8          @ 98 NOP8
        .word   nop8          @ 99 NOP8
        .word   nop8          @ 9a NOP8
        .word   nop8          @ 9b NOP8
        .word   nop8          @ 9c NOP8
        .word   nop8          @ 9d NOP8
        .word   nop8          @ 9e NOP8
        .word   nop8          @ 9f NOP8
        .word   ldi           @ a0 LDI
        .word   cpi           @ a1 CPI
        .word   ini           @ a2 INI
        .word   outi          @ a3 OUTI
        .word   nop8          @ a4 NOP8
        .word   nop8          @ a5 NOP8
        .word   nop8          @ a6 NOP8
        .word   nop8          @ a7 NOP8
        .word   ldd           @ a8 LDD
        .word   cpd           @ a9 CPD
        .word   ind           @ aa IND
        .word   outd          @ ab OUTD
        .word   nop8          @ ac NOP8
        .word   nop8          @ ad NOP8
        .word   nop8          @ ae NOP8
        .word   nop8          @ af NOP8
        .word   ldir          @ b0 LDIR
        .word   cpir          @ b1 CPIR
        .word   inir          @ b2 INIR
        .word   otir          @ b3 OTIR
        .word   nop8          @ b4 NOP8
        .word   nop8          @ b5 NOP8
        .word   nop8          @ b6 NOP8
        .word   nop8          @ b7 NOP8
        .word   lddr          @ b8 LDDR
        .word   cpdr          @ b9 CPDR
        .word   indr          @ ba INDR
        .word   otdr          @ bb OTDR
        .word   nop8          @ bc NOP8
        .word   nop8          @ bd NOP8
        .word   nop8          @ be NOP8
        .word   nop8          @ bf NOP8
        .word   nop8          @ c0 NOP8
        .word   nop8          @ c1 NOP8
        .word   nop8          @ c2 NOP8
        .word   nop8          @ c3 NOP8
        .word   nop8          @ c4 NOP8
        .word   nop8          @ c5 NOP8
        .word   nop8          @ c6 NOP8
        .word   nop8          @ c7 NOP8
        .word   nop8          @ c8 NOP8
        .word   nop8          @ c9 NOP8
        .word   nop8          @ ca NOP8
        .word   nop8          @ cb NOP8
        .word   nop8          @ cc NOP8
        .word   nop8          @ cd NOP8
        .word   nop8          @ ce NOP8
        .word   nop8          @ cf NOP8
        .word   nop8          @ d0 NOP8
        .word   nop8          @ d1 NOP8
        .word   nop8          @ d2 NOP8
        .word   nop8          @ d3 NOP8
        .word   nop8          @ d4 NOP8
        .word   nop8          @ d5 NOP8
        .word   nop8          @ d6 NOP8
        .word   nop8          @ d7 NOP8
        .word   nop8          @ d8 NOP8
        .word   nop8          @ d9 NOP8
        .word   nop8          @ da NOP8
        .word   nop8          @ db NOP8
        .word   nop8          @ dc NOP8
        .word   nop8          @ dd NOP8
        .word   nop8          @ de NOP8
        .word   nop8          @ df NOP8
        .word   nop8          @ e0 NOP8
        .word   nop8          @ e1 NOP8
        .word   nop8          @ e2 NOP8
        .word   nop8          @ e3 NOP8
        .word   nop8          @ e4 NOP8
        .word   nop8          @ e5 NOP8
        .word   nop8          @ e6 NOP8
        .word   nop8          @ e7 NOP8
        .word   nop8          @ e8 NOP8
        .word   nop8          @ e9 NOP8
        .word   nop8          @ ea NOP8
        .word   nop8          @ eb NOP8
        .word   nop8          @ ec NOP8
        .word   nop8          @ ed NOP8
        .word   nop8          @ ee NOP8
        .word   nop8          @ ef NOP8
        .word   nop8          @ f0 NOP8
        .word   nop8          @ f1 NOP8
        .word   nop8          @ f2 NOP8
        .word   nop8          @ f3 NOP8
        .word   nop8          @ f4 NOP8
        .word   nop8          @ f5 NOP8
        .word   nop8          @ f6 NOP8
        .word   nop8          @ f7 NOP8
        .word   nop8          @ f8 NOP8
        .word   nop8          @ f9 NOP8
        .word   nop8          @ fa NOP8
        .word   nop8          @ fb NOP8
        .word   nop8          @ fc NOP8
        .word   nop8          @ fd NOP8
        .word   nop8          @ fe NOP8
        .word   nop8          @ ff NOP8

nop8:   TIME    8
        PREFIX0

adchlbc:ADCHLRR bcfb
adchlde:ADCHLRR defr
adchlhl:ADCHLRR hlmp
adchlsp:ADCHLRR spfa

sbchlbc:SBCHLRR bcfb
sbchlde:SBCHLRR defr
sbchlhl:SBCHLRR hlmp
sbchlsp:SBCHLRR spfa

ldi:    TIME    16
        ldrb    lr, [mem, hlmp, lsr #16]
        strb    lr, [mem, defr, lsr #16]
        mov     r11, #0x00010000
        add     hlmp, r11
        add     defr, r11
        sub     bcfb, r11
        movs    r10, defr, lsl #16
        pkhtbne defr, defr, r11, asr #16
        add     lr, arvpref, lsr #24
        and     lr, #0b00001010
        add     lr, lr, lsl #4
        eor     lr, pcff
        and     lr, #40
        eor     pcff, lr
        pkhtb   spfa, spfa, lr, asr #8
        movs    lr, bcfb, lsr #16
        eorne   spfa, #0x00000080
        pkhbt   bcfb, spfa, lr, lsl #16
        b       salida

ldd:    TIME    16
        ldrb    lr, [mem, hlmp, lsr #16]
        strb    lr, [mem, defr, lsr #16]
        mov     r11, #0x00010000
        sub     hlmp, r11
        sub     defr, r11
        sub     bcfb, r11
        movs    r10, defr, lsl #16
        pkhtbne defr, defr, r11, asr #16
        add     lr, arvpref, lsr #24
        and     lr, #0b00001010
        add     lr, lr, lsl #4
        eor     lr, pcff
        and     lr, #40
        eor     pcff, lr
        pkhtb   spfa, spfa, lr, asr #8
        movs    lr, bcfb, lsr #16
        eorne   spfa, #0x00000080
        pkhbt   bcfb, spfa, lr, lsl #16
        b       salida

cpi:    TIME    16
        ldrb    lr, [mem, hlmp, lsr #16]
        rsb     r11, lr, arvpref, lsr #24
        uxtb    r11, r11
        mov     r10, #0x00000001
        orr     r10, #0x00010000
        uadd16  hlmp, hlmp, r10
        sub     bcfb, #0x00010000
        and     r10, r11, #0x0000007f
        orr     r10, r11, lsr #7
        pkhtb   defr, defr, r10
        orr     r10, lr, #0x00000080
        mvn     r10, r10
        pkhtb   bcfb, bcfb, r10
        mov     r10, arvpref, lsr #24
        and     r10, #0x0000007f
        pkhtb   spfa, spfa, r10
        movs    r10, bcfb, lsr #16
        orrne   bcfb, #0x00000080
        orrne   spfa, #0x00000080
        bic     pcff, #0x000000ff
        and     r10, r11, #0x000000d7
        uxtab   pcff, pcff, r10
        eor     r10, r11, lr
        eor     r10, arvpref, lsr #24
        tst     r10,  #0x00000010
        subne   r11,  #0x00000001
        tst     r11,  #0x00000008
        orrne   pcff, #0x00000008
        tst     r11,  #0x00000002
        orrne   pcff, #0x00000020
        b       salida

cpir:   TIME    16
        ldrb    lr, [mem, hlmp, lsr #16]
        rsb     r11, lr, arvpref, lsr #24
        uxtb    r11, r11
        mov     r10, #0x00000001
        orr     r10, #0x00010000
        uadd16  hlmp, hlmp, r10
        sub     bcfb, #0x00010000
        and     r10, r11, #0x0000007f
        orr     r10, r11, lsr #7
        pkhtb   defr, defr, r10
        orr     r10, lr, #0x00000080
        mvn     r10, r10
        pkhtb   bcfb, bcfb, r10
        mov     r10, arvpref, lsr #24
        and     r10, #0x0000007f
        pkhtb   spfa, spfa, r10
        movs    r10, bcfb, lsr #16
        beq     cpdr3
        orr     bcfb, #0x00000080
        orr     spfa, #0x00000080
        orrs    r11, r11
        beq     cpdr3
        TIME    5
        sub     pcff, #0x00010000
        pkhtb   hlmp, hlmp, pcff, asr #16
        sub     pcff, #0x00010000
cpdr3:  bic     pcff, #0x000000ff
        and     r10, r11, #0x000000d7
        uxtab   pcff, pcff, r10
        eor     r10, r11, lr
        eor     r10, arvpref, lsr #24
        tst     r10,  #0x00000010
        subne   r11,  #0x00000001
        tst     r11,  #0x00000008
        orrne   pcff, #0x00000008
        tst     r11,  #0x00000002
        orrne   pcff, #0x00000020
        b       salida

cpd:    TIME    16
        ldrb    lr, [mem, hlmp, lsr #16]
        rsb     r11, lr, arvpref, lsr #24
        uxtb    r11, r11
        mov     r10, #0x00000001
        orr     r10, #0x00010000
        usub16  hlmp, hlmp, r10
        sub     bcfb, #0x00010000
        and     r10, r11, #0x0000007f
        orr     r10, r11, lsr #7
        pkhtb   defr, defr, r10
        orr     r10, lr, #0x00000080
        mvn     r10, r10
        pkhtb   bcfb, bcfb, r10
        mov     r10, arvpref, lsr #24
        and     r10, #0x0000007f
        pkhtb   spfa, spfa, r10
        movs    r10, bcfb, lsr #16
        orrne   bcfb, #0x00000080
        orrne   spfa, #0x00000080
        bic     pcff, #0x000000ff
        and     r10, r11, #0x000000d7
        uxtab   pcff, pcff, r10
        eor     r10, r11, lr
        eor     r10, arvpref, lsr #24
        tst     r10,  #0x00000010
        subne   r11,  #0x00000001
        tst     r11,  #0x00000008
        orrne   pcff, #0x00000008
        tst     r11,  #0x00000002
        orrne   pcff, #0x00000020
        b       salida

cpdr:   TIME    16
        ldrb    lr, [mem, hlmp, lsr #16]
        rsb     r11, lr, arvpref, lsr #24
        uxtb    r11, r11
        mov     r10, #0x00000001
        orr     r10, #0x00010000
        usub16  hlmp, hlmp, r10
        sub     bcfb, #0x00010000
        and     r10, r11, #0x0000007f
        orr     r10, r11, lsr #7
        pkhtb   defr, defr, r10
        orr     r10, lr, #0x00000080
        mvn     r10, r10
        pkhtb   bcfb, bcfb, r10
        mov     r10, arvpref, lsr #24
        and     r10, #0x0000007f
        pkhtb   spfa, spfa, r10
        movs    r10, bcfb, lsr #16
        beq     cpdr2
        orr     bcfb, #0x00000080
        orr     spfa, #0x00000080
        orrs    r11, r11
        beq     cpdr2
        TIME    5
        sub     pcff, #0x00010000
        pkhtb   hlmp, hlmp, pcff, asr #16
        sub     pcff, #0x00010000
cpdr2:  bic     pcff, #0x000000ff
        and     r10, r11, #0x000000d7
        uxtab   pcff, pcff, r10
        eor     r10, r11, lr
        eor     r10, arvpref, lsr #24
        tst     r10,  #0x00000010
        subne   r11,  #0x00000001
        tst     r11,  #0x00000008
        orrne   pcff, #0x00000008
        tst     r11,  #0x00000002
        orrne   pcff, #0x00000020
        b       salida

ldir:   TIME    16
        ldrb    lr, [mem, hlmp, lsr #16]
        strb    lr, [mem, defr, lsr #16]
        mov     r11, #0x00010000
        add     hlmp, r11
        add     defr, r11
        sub     bcfb, r11
        movs    r10, defr, lsl #24
        pkhtbne defr, defr, r11, asr #16
        add     lr, arvpref, lsr #24
        and     lr, #0b00001010
        add     lr, lr, lsl #4
        eor     lr, pcff
        and     lr, #40
        eor     pcff, lr
        pkhtb   spfa, spfa, lr, asr #8
        movs    lr, bcfb, lsr #16
        beq     ldir2
        eor     spfa, #0x00000080
        sub     pcff, #0x00010000
        pkhtb   hlmp, hlmp, pcff, asr #16
        sub     pcff, #0x00010000
        TIME    5
ldir2:  pkhbt   bcfb, spfa, lr, lsl #16
        b       salida

lddr:   TIME    16
        ldrb    lr, [mem, hlmp, lsr #16]
        strb    lr, [mem, defr, lsr #16]
        mov     r11, #0x00010000
        sub     hlmp, r11
        sub     defr, r11
        sub     bcfb, r11
        movs    r10, defr, lsl #24
        pkhtbne defr, defr, r11, asr #16
        add     lr, arvpref, lsr #24
        and     lr, #0b00001010
        add     lr, lr, lsl #4
        eor     lr, pcff
        and     lr, #40
        eor     pcff, lr
        pkhtb   spfa, spfa, lr, asr #8
        movs    lr, bcfb, lsr #16
        beq     lddr2
        eor     spfa, #0x00000080
        sub     pcff, #0x00010000
        pkhtb   hlmp, hlmp, pcff, asr #16
        sub     pcff, #0x00010000
        TIME    5
lddr2:  pkhbt   bcfb, spfa, lr, lsl #16
        b       salida

ini:    TIME    16
        push    {r0-r3, r12}
        mov     r0, bcfb, lsr #16
        add     r1, r0, #0x00000001
        pkhtb   hlmp, hlmp, r1
        bl      in
        strb    r0, [mem, hlmp, lsr #16]
        add     hlmp, #0x00010000
        add     r1, bcfb, #0x00010000
        uxtab   r1, r0, r1, ror #24
        sub     bcfb, #0x01000000
        and     r11, r1, #0x00000007
        mov     r3, bcfb, lsr #24
        eor     r2, r11, r3
        and     r1, #0x00000100
        orr     r11, r1, r3
        pkhtb   defr, defr, r3
        eor     r3, defr, #0x00000080
        pkhtb   spfa, spfa, r3
        ldr     lr, cb34
        eor     r3, r2, r2, lsr #4
        eor     r3, bcfb, lsr #24
        tst     lr, lr, ror r3
        orrmi   r1, #0x00000800
        and     r0, #0x00000080
        mov     r0, r0, lsl #6
        orr     r0, r1
        pkhtb   bcfb, bcfb, r0, asr #4
        pop     {r0-r3, r12}
        pkhtb   pcff, pcff, r11
        b       salida

ind:    TIME    16
        push    {r0-r3, r12}
        mov     r0, bcfb, lsr #16
        sub     r1, r0, #0x00000001
        pkhtb   hlmp, hlmp, r1
        bl      in
        strb    r0, [mem, hlmp, lsr #16]
        sub     hlmp, #0x00010000
        sub     r1, bcfb, #0x00010000
        uxtab   r1, r0, r1, ror #24
        sub     bcfb, #0x01000000
        and     r11, r1, #0x00000007
        mov     r3, bcfb, lsr #24
        eor     r2, r11, r3
        and     r1, #0x00000100
        orr     r11, r1, r3
        pkhtb   defr, defr, r3
        eor     r3, defr, #0x00000080
        pkhtb   spfa, spfa, r3
        ldr     lr, cb34
        eor     r3, r2, r2, lsr #4
        eor     r3, bcfb, lsr #24
        tst     lr, lr, ror r3
        orrmi   r1, #0x00000800
        and     r0, #0x00000080
        mov     r0, r0, lsl #6
        orr     r0, r1
        pkhtb   bcfb, bcfb, r0, asr #4
        pop     {r0-r3, r12}
        pkhtb   pcff, pcff, r11
        b       salida

inir:   TIME    16
        mov     r10, stlo
        push    {r0-r3, r12}
        mov     r0, bcfb, lsr #16
        add     r1, r0, #0x00000001
        pkhtb   hlmp, hlmp, r1
        bl      in
        strb    r0, [mem, hlmp, lsr #16]
        add     hlmp, #0x00010000
        add     r1, bcfb, #0x00010000
        uxtab   r1, r0, r1, ror #24
        sub     bcfb, #0x01000000
        tst     bcfb, #0xff000000
        beq     inir2
        sub     pcff, #0x00010000
        pkhtb   hlmp, hlmp, pcff, asr #16
        sub     pcff, #0x00010000
        adds    r10, #0x00000005
        blcs    insth
inir2:  and     r11, r1, #0x00000007
        mov     r3, bcfb, lsr #24
        eor     r2, r11, r3
        and     r1, #0x00000100
        orr     r11, r1, r3
        pkhtb   defr, defr, r3
        eor     r3, defr, #0x00000080
        pkhtb   spfa, spfa, r3
        ldr     lr, cb34
        eor     r3, r2, r2, lsr #4
        eor     r3, bcfb, lsr #24
        tst     lr, lr, ror r3
        orrmi   r1, #0x00000800
        and     r0, #0x00000080
        mov     r0, r0, lsl #6
        orr     r0, r1
        pkhtb   bcfb, bcfb, r0, asr #4
        pop     {r0-r3, r12}
        pkhtb   pcff, pcff, r11
        mov     stlo, r10
        b       salida

indr:   TIME    16
        mov     r10, stlo
        push    {r0-r3, r12}
        mov     r0, bcfb, lsr #16
        sub     r1, r0, #0x00000001
        pkhtb   hlmp, hlmp, r1
        bl      in
        strb    r0, [mem, hlmp, lsr #16]
        sub     hlmp, #0x00010000
        sub     r1, bcfb, #0x00010000
        uxtab   r1, r0, r1, ror #24
        sub     bcfb, #0x01000000
        tst     bcfb, #0xff000000
        beq     indr2
        sub     pcff, #0x00010000
        pkhtb   hlmp, hlmp, pcff, asr #16
        sub     pcff, #0x00010000
        adds    r10, #0x00000005
        blcs    insth
indr2:  and     r11, r1, #0x00000007
        mov     r3, bcfb, lsr #24
        eor     r2, r11, r3
        and     r1, #0x00000100
        orr     r11, r1, r3
        pkhtb   defr, defr, r3
        eor     r3, defr, #0x00000080
        pkhtb   spfa, spfa, r3
        ldr     lr, cb34
        eor     r3, r2, r2, lsr #4
        eor     r3, bcfb, lsr #24
        tst     lr, lr, ror r3
        orrmi   r1, #0x00000800
        and     r0, #0x00000080
        mov     r0, r0, lsl #6
        orr     r0, r1
        pkhtb   bcfb, bcfb, r0, asr #4
        pop     {r0-r3, r12}
        pkhtb   pcff, pcff, r11
        mov     stlo, r10
        b       salida

outi:   TIME    16
        push    {r0-r3, r12}
        sub     bcfb, #0x01000000
        mov     r0, bcfb, lsr #16
        add     r1, r0, #0x00000001
        pkhtb   hlmp, hlmp, r1
        ldrb    r1, [mem, hlmp, lsr #16]
        bl      out
        add     hlmp, #0x00010000
        and     r2, hlmp, #0x00ff0000
        add     r0, r1, r2, lsr #16
        and     r11, r0, #0x00000007
        mov     r3, bcfb, lsr #24
        eor     r2, r11, r3
        and     r0, #0x00000100
        orr     r11, r0, r3
        pkhtb   defr, defr, r3
        eor     r3, defr, #0x00000080
        pkhtb   spfa, spfa, r3
        ldr     lr, cb34
        eor     r3, r2, r2, lsr #4
        eor     r3, bcfb, lsr #24
        tst     lr, lr, ror r3
        orrmi   r0, #0x00000800
        and     r1, #0x00000080
        mov     r1, r1, lsl #6
        orr     r1, r0
        pkhtb   bcfb, bcfb, r1, asr #4
        pop     {r0-r3, r12}
        pkhtb   pcff, pcff, r11
        b       salida

outd:   TIME    16
        push    {r0-r3, r12}
        sub     bcfb, #0x01000000
        mov     r0, bcfb, lsr #16
        sub     r1, r0, #0x00000001
        pkhtb   hlmp, hlmp, r1
        ldrb    r1, [mem, hlmp, lsr #16]
        bl      out
        sub     hlmp, #0x00010000
        and     r2, hlmp, #0x00ff0000
        add     r0, r1, r2, lsr #16
        and     r11, r0, #0x00000007
        mov     r3, bcfb, lsr #24
        eor     r2, r11, r3
        and     r0, #0x00000100
        orr     r11, r0, r3
        pkhtb   defr, defr, r3
        eor     r3, defr, #0x00000080
        pkhtb   spfa, spfa, r3
        ldr     lr, cb34
        eor     r3, r2, r2, lsr #4
        eor     r3, bcfb, lsr #24
        tst     lr, lr, ror r3
        orrmi   r0, #0x00000800
        and     r1, #0x00000080
        mov     r1, r1, lsl #6
        orr     r1, r0
        pkhtb   bcfb, bcfb, r1, asr #4
        pop     {r0-r3, r12}
        pkhtb   pcff, pcff, r11
        b       salida

otir:   TIME    16
        mov     r10, stlo
        push    {r0-r3, r12}
        sub     bcfb, #0x01000000
        mov     r0, bcfb, lsr #16
        add     r1, r0, #0x00000001
        pkhtb   hlmp, hlmp, r1
        ldrb    r1, [mem, hlmp, lsr #16]
        bl      out
        add     hlmp, #0x00010000
        and     r2, hlmp, #0x00ff0000
        add     r0, r1, r2, lsr #16
        tst     bcfb, #0xff000000
        beq     otir2
        sub     pcff, #0x00010000
        pkhtb   hlmp, hlmp, pcff, asr #16
        sub     pcff, #0x00010000
        adds    r10, #0x00000005
        blcs    insth
otir2:  and     r11, r0, #0x00000007
        mov     r3, bcfb, lsr #24
        eor     r2, r11, r3
        and     r0, #0x00000100
        orr     r11, r0, r3
        pkhtb   defr, defr, r3
        eor     r3, defr, #0x00000080
        pkhtb   spfa, spfa, r3
        ldr     lr, cb34
        eor     r3, r2, r2, lsr #4
        eor     r3, bcfb, lsr #24
        tst     lr, lr, ror r3
        orrmi   r0, #0x00000800
        and     r1, #0x00000080
        mov     r1, r1, lsl #6
        orr     r1, r0
        pkhtb   bcfb, bcfb, r1, asr #4
        pop     {r0-r3, r12}
        pkhtb   pcff, pcff, r11
        mov     stlo, r10
        b       salida

otdr:   TIME    16
        mov     r10, stlo
        push    {r0-r3, r12}
        sub     bcfb, #0x01000000
        mov     r0, bcfb, lsr #16
        sub     r1, r0, #0x00000001
        pkhtb   hlmp, hlmp, r1
        ldrb    r1, [mem, hlmp, lsr #16]
        bl      out
        sub     hlmp, #0x00010000
        and     r2, hlmp, #0x00ff0000
        add     r0, r1, r2, lsr #16
        and     r11, r0, #0x00000007
        mov     r3, bcfb, lsr #24
        eor     r2, r11, r3
        and     r0, #0x00000100
        tst     bcfb, #0xff000000
        beq     otdr2
        sub     pcff, #0x00010000
        pkhtb   hlmp, hlmp, pcff, asr #16
        sub     pcff, #0x00010000
        adds    r10, #0x00000005
        blcs    insth
otdr2:  orr     r11, r0, r3
        pkhtb   defr, defr, r3
        eor     r3, defr, #0x00000080
        pkhtb   spfa, spfa, r3
        ldr     lr, cb34
        eor     r3, r2, r2, lsr #4
        eor     r3, bcfb, lsr #24
        tst     lr, lr, ror r3
        orrmi   r0, #0x00000800
        and     r1, #0x00000080
        mov     r1, r1, lsl #6
        orr     r1, r0
        pkhtb   bcfb, bcfb, r1, asr #4
        pop     {r0-r3, r12}
        pkhtb   pcff, pcff, r11
        mov     stlo, r10
        b       salida

neg:    TIME    8
        mvn     lr, arvpref, lsr #24
        pkhtb   bcfb, bcfb, lr
        add     lr, #0x00000001
        pkhtb   pcff, pcff, lr
        bic     arvpref, #0xff000000
        orr     arvpref, lr, lsl #24
        uxtb    lr, lr
        pkhtb   defr, defr, lr
        pkhtb   spfa, spfa, lr, asr #16
        b       salida

inbc:   INR     bcfb, 8
in_cc:  INR     bcfb, 0
indc:   INR     defr, 8
inec:   INR     defr, 0
inhc:   INR     hlmp, 8
inlc:   INR     hlmp, 0
inxc:   INR     arvpref, 0
inac:   INR     arvpref, 8

outcb:  OUTR    bcfb, 8
outcc:  OUTR    bcfb, 0
outcd:  OUTR    defr, 8
outce:  OUTR    defr, 0
outch:  OUTR    hlmp, 8
outcl:  OUTR    hlmp, 0
outcx:  OUTR    arvpref, 0
outca:  OUTR    arvpref, 8

ret14:  RET     14
        b       salida

im0:    TIME    8
        bic     arvpref, #0x00000300
        b       salida

im1:    TIME    8
        bic     arvpref, #0x00000200
        orr     arvpref, #0x00000100
        b       salida

im2:    TIME    8
        bic     arvpref, #0x00000100
        orr     arvpref, #0x00000200
        b       salida

ldai:   TIME    9
        bic     arvpref, #0xff000000
        ands    lr, iyi, #0x0000ff00
        orr     arvpref, lr, ror #16
        bic     pcff, #0x000000ff
        orr     pcff, lr, lsr #8
        orrne   lr, #0x00010000
        pkhtb   defr, defr, lr, asr #16
        and     lr, arvpref, #0x00000400
        pkhtb   spfa, spfa, lr, asr #3
        pkhtb   bcfb, bcfb, lr, asr #3
        b       salida

ldia:   TIME    9
        bic     iyi, #0x0000ff00
        and     lr, arvpref, #0xff000000
        orr     iyi, lr, ror #16
        b       salida

ldar:   TIME    9
        bic     arvpref, #0xff000000
        and     lr, arvpref, #0x007f0000
        and     r11, arvpref, #0x00008000
        orrs    lr, r11, lsl #8
        orr     arvpref, lr, ror #24
        bic     pcff, #0x000000ff
        orr     pcff, lr, lsr #16
        orrne   lr, #0x01000000
        pkhtb   defr, defr, lr, asr #24
        and     lr, arvpref, #0x00000400
        pkhtb   spfa, spfa, lr, asr #3
        pkhtb   bcfb, bcfb, lr, asr #3
        b       salida

ldra:   TIME    9
        bic     arvpref, #0x00ff0000
        bic     arvpref, #0x00008000
        ands    lr, arvpref, #0xff000000
        orr     arvpref, lr, ror #8
        orrmi   arvpref, #0x00008000
        b       salida

rrd:    TIME    18
        ldrb    lr, [mem, hlmp, lsr #16]
        mov     r11, arvpref, lsr #24
        orr     lr, r11, lsl #8
        eor     arvpref, lr, lsl #24
        and     arvpref, #0xf0ffffff
        eor     arvpref, lr, lsl #24
        mov     r11, arvpref, lsr #24
        pkhtb   defr, defr, r11
        bic     pcff, #0x000000ff
        orr     pcff, r11
        orr     r11, #0x00000100
        pkhtb   spfa, spfa, r11
        pkhtb   bcfb, bcfb, r11, asr #16
        mov     lr, lr, lsr #4
        strb    lr, [mem, hlmp, lsr #16]
        add     lr, hlmp, #0x00010000
        pkhtb   hlmp, hlmp, lr, asr #16
        b       salida

rld:    TIME    18
        ldrb    lr, [mem, hlmp, lsr #16]
        and     r11, arvpref, #0x0f000000
        mov     lr, lr, lsl #4
        orr     lr, r11, lsr #24
        eor     arvpref, lr, lsl #16
        and     arvpref, #0xf0ffffff
        eor     arvpref, lr, lsl #16
        mov     r11, arvpref, lsr #24
        pkhtb   defr, defr, r11
        bic     pcff, #0x000000ff
        orr     pcff, r11
        orr     r11, #0x00000100
        pkhtb   spfa, spfa, r11
        pkhtb   bcfb, bcfb, r11, asr #16
        strb    lr, [mem, hlmp, lsr #16]
        add     lr, hlmp, #0x00010000
        pkhtb   hlmp, hlmp, lr, asr #16
        b       salida

opcb:   movs    lr, arvpref, lsl #24
        bne     opxdcb
        mov     lr, #0x00010000
        uadd8   arvpref, arvpref, lr
        ldrb    lr, [mem, pcff, lsr #16]
        add     pcff, #0x00010000
        ldr     pc, [pc, lr, lsl #2]
        .word   0             @ relleno
        .word   rlc_b         @ 00 RLC B
        .word   rlc_c         @ 01 RLC C
        .word   rlc_d         @ 02 RLC D
        .word   rlc_e         @ 03 RLC E
        .word   rlc_h         @ 04 RLC H
        .word   rlc_l         @ 05 RLC L
        .word   rlc_hl        @ 06 RLC (HL)
        .word   rlc_a         @ 07 RLC A
        .word   rrc_b         @ 08 RRC B
        .word   rrc_c         @ 09 RRC C
        .word   rrc_d         @ 0a RRC D
        .word   rrc_e         @ 0b RRC E
        .word   rrc_h         @ 0c RRC H
        .word   rrc_l         @ 0d RRC L
        .word   rrc_hl        @ 0e RRC (HL)
        .word   rrc_a         @ 0f RRC A
        .word   rl_b          @ 10 RL B
        .word   rl_c          @ 11 RL C
        .word   rl_d          @ 12 RL D
        .word   rl_e          @ 13 RL E
        .word   rl_h          @ 14 RL H
        .word   rl_l          @ 15 RL L
        .word   rl_hl         @ 16 RL (HL)
        .word   rl_a          @ 17 RL A
        .word   rr_b          @ 18 RR B
        .word   rr_c          @ 19 RR C
        .word   rr_d          @ 1a RR D
        .word   rr_e          @ 1b RR E
        .word   rr_h          @ 1c RR H
        .word   rr_l          @ 1d RR L
        .word   rr_hl         @ 1e RR (HL)
        .word   rr_a          @ 1f RR A
        .word   sla_b         @ 20 SLA B
        .word   sla_c         @ 21 SLA C
        .word   sla_d         @ 22 SLA D
        .word   sla_e         @ 23 SLA E
        .word   sla_h         @ 24 SLA H
        .word   sla_l         @ 25 SLA L
        .word   sla_hl        @ 26 SLA (HL)
        .word   sla_a         @ 27 SLA A
        .word   sra_b         @ 28 SRA B
        .word   sra_c         @ 29 SRA C
        .word   sra_d         @ 2a SRA D
        .word   sra_e         @ 2b SRA E
        .word   sra_h         @ 2c SRA H
        .word   sra_l         @ 2d SRA L
        .word   sra_hl        @ 2e SRA (HL)
        .word   sra_a         @ 2f SRA A
        .word   sll_b         @ 30 SLL B
        .word   sll_c         @ 31 SLL C
        .word   sll_d         @ 32 SLL D
        .word   sll_e         @ 33 SLL E
        .word   sll_h         @ 34 SLL H
        .word   sll_l         @ 35 SLL L
        .word   sll_hl        @ 36 SLL (HL)
        .word   sll_a         @ 37 SLL A
        .word   srl_b         @ 38 SRL B
        .word   srl_c         @ 39 SRL C
        .word   srl_d         @ 3a SRL D
        .word   srl_e         @ 3b SRL E
        .word   srl_h         @ 3c SRL H
        .word   srl_l         @ 3d SRL L
        .word   srl_hl        @ 3e SRL (HL)
        .word   srl_a         @ 3f SRL A
        .word   bit0b         @ 40 BIT 0,B
        .word   bit0c         @ 41 BIT 0,C
        .word   bit0d         @ 42 BIT 0,D
        .word   bit0e         @ 43 BIT 0,E
        .word   bit0h         @ 44 BIT 0,H
        .word   bit0l         @ 45 BIT 0,L
        .word   bit0hl        @ 46 BIT 0,(HL)
        .word   bit0a         @ 47 BIT 0,A
        .word   bit1b         @ 48 BIT 1,B
        .word   bit1c         @ 49 BIT 1,C
        .word   bit1d         @ 4a BIT 1,D
        .word   bit1e         @ 4b BIT 1,E
        .word   bit1h         @ 4c BIT 1,H
        .word   bit1l         @ 4d BIT 1,L
        .word   bit1hl        @ 4e BIT 1,(HL)
        .word   bit1a         @ 4f BIT 1,A
        .word   bit2b         @ 50 BIT 2,B
        .word   bit2c         @ 51 BIT 2,C
        .word   bit2d         @ 52 BIT 2,D
        .word   bit2e         @ 53 BIT 2,E
        .word   bit2h         @ 54 BIT 2,H
        .word   bit2l         @ 55 BIT 2,L
        .word   bit2hl        @ 56 BIT 2,(HL)
        .word   bit2a         @ 57 BIT 2,A
        .word   bit3b         @ 58 BIT 3,B
        .word   bit3c         @ 59 BIT 3,C
        .word   bit3d         @ 5a BIT 3,D
        .word   bit3e         @ 5b BIT 3,E
        .word   bit3h         @ 5c BIT 3,H
        .word   bit3l         @ 5d BIT 3,L
        .word   bit3hl        @ 5e BIT 3,(HL)
        .word   bit3a         @ 5f BIT 3,A
        .word   bit4b         @ 60 BIT 4,B
        .word   bit4c         @ 61 BIT 4,C
        .word   bit4d         @ 62 BIT 4,D
        .word   bit4e         @ 63 BIT 4,E
        .word   bit4h         @ 64 BIT 4,H
        .word   bit4l         @ 65 BIT 4,L
        .word   bit4hl        @ 66 BIT 4,(HL)
        .word   bit4a         @ 67 BIT 4,A
        .word   bit5b         @ 68 BIT 5,B
        .word   bit5c         @ 69 BIT 5,C
        .word   bit5d         @ 6a BIT 5,D
        .word   bit5e         @ 6b BIT 5,E
        .word   bit5h         @ 6c BIT 5,H
        .word   bit5l         @ 6d BIT 5,L
        .word   bit5hl        @ 6e BIT 5,(HL)
        .word   bit5a         @ 6f BIT 5,A
        .word   bit6b         @ 70 BIT 6,B
        .word   bit6c         @ 71 BIT 6,C
        .word   bit6d         @ 72 BIT 6,D
        .word   bit6e         @ 73 BIT 6,E
        .word   bit6h         @ 74 BIT 6,H
        .word   bit6l         @ 75 BIT 6,L
        .word   bit6hl        @ 76 BIT 6,(HL)
        .word   bit6a         @ 77 BIT 6,A
        .word   bit7b         @ 78 BIT 7,B
        .word   bit7c         @ 79 BIT 7,C
        .word   bit7d         @ 7a BIT 7,D
        .word   bit7e         @ 7b BIT 7,E
        .word   bit7h         @ 7c BIT 7,H
        .word   bit7l         @ 7d BIT 7,L
        .word   bit7hl        @ 7e BIT 7,(HL)
        .word   bit7a         @ 7f BIT 7,A
        .word   res0b         @ 80 RES 0,B
        .word   res0c         @ 81 RES 0,C
        .word   res0d         @ 82 RES 0,D
        .word   res0e         @ 83 RES 0,E
        .word   res0h         @ 84 RES 0,H
        .word   res0l         @ 85 RES 0,L
        .word   res0hl        @ 86 RES 0,(HL)
        .word   res0a         @ 87 RES 0,A
        .word   res1b         @ 88 RES 1,B
        .word   res1c         @ 89 RES 1,C
        .word   res1d         @ 8a RES 1,D
        .word   res1e         @ 8b RES 1,E
        .word   res1h         @ 8c RES 1,H
        .word   res1l         @ 8d RES 1,L
        .word   res1hl        @ 8e RES 1,(HL)
        .word   res1a         @ 8f RES 1,A
        .word   res2b         @ 90 RES 2,B
        .word   res2c         @ 91 RES 2,C
        .word   res2d         @ 92 RES 2,D
        .word   res2e         @ 93 RES 2,E
        .word   res2h         @ 94 RES 2,H
        .word   res2l         @ 95 RES 2,L
        .word   res2hl        @ 96 RES 2,(HL)
        .word   res2a         @ 97 RES 2,A
        .word   res3b         @ 98 RES 3,B
        .word   res3c         @ 99 RES 3,C
        .word   res3d         @ 9a RES 3,D
        .word   res3e         @ 9b RES 3,E
        .word   res3h         @ 9c RES 3,H
        .word   res3l         @ 9d RES 3,L
        .word   res3hl        @ 9e RES 3,(HL)
        .word   res3a         @ 9f RES 3,A
        .word   res4b         @ a0 RES 4,B
        .word   res4c         @ a1 RES 4,C
        .word   res4d         @ a2 RES 4,D
        .word   res4e         @ a3 RES 4,E
        .word   res4h         @ a4 RES 4,H
        .word   res4l         @ a5 RES 4,L
        .word   res4hl        @ a6 RES 4,(HL)
        .word   res4a         @ a7 RES 4,A
        .word   res5b         @ a8 RES 5,B
        .word   res5c         @ a9 RES 5,C
        .word   res5d         @ aa RES 5,D
        .word   res5e         @ ab RES 5,E
        .word   res5h         @ ac RES 5,H
        .word   res5l         @ ad RES 5,L
        .word   res5hl        @ ae RES 5,(HL)
        .word   res5a         @ af RES 5,A
        .word   res6b         @ b0 RES 6,B
        .word   res6c         @ b1 RES 6,C
        .word   res6d         @ b2 RES 6,D
        .word   res6e         @ b3 RES 6,E
        .word   res6h         @ b4 RES 6,H
        .word   res6l         @ b5 RES 6,L
        .word   res6hl        @ b6 RES 6,(HL)
        .word   res6a         @ b7 RES 6,A
        .word   res7b         @ b8 RES 7,B
        .word   res7c         @ b9 RES 7,C
        .word   res7d         @ ba RES 7,D
        .word   res7e         @ bb RES 7,E
        .word   res7h         @ bc RES 7,H
        .word   res7l         @ bd RES 7,L
        .word   res7hl        @ be RES 7,(HL)
        .word   res7a         @ bf RES 7,A
        .word   set0b         @ c0 SET 0,B
        .word   set0c         @ c1 SET 0,C
        .word   set0d         @ c2 SET 0,D
        .word   set0e         @ c3 SET 0,E
        .word   set0h         @ c4 SET 0,H
        .word   set0l         @ c5 SET 0,L
        .word   set0hl        @ c6 SET 0,(HL)
        .word   set0a         @ c7 SET 0,A
        .word   set1b         @ c8 SET 1,B
        .word   set1c         @ c9 SET 1,C
        .word   set1d         @ ca SET 1,D
        .word   set1e         @ cb SET 1,E
        .word   set1h         @ cc SET 1,H
        .word   set1l         @ cd SET 1,L
        .word   set1hl        @ ce SET 1,(HL)
        .word   set1a         @ cf SET 1,A
        .word   set2b         @ d0 SET 2,B
        .word   set2c         @ d1 SET 2,C
        .word   set2d         @ d2 SET 2,D
        .word   set2e         @ d3 SET 2,E
        .word   set2h         @ d4 SET 2,H
        .word   set2l         @ d5 SET 2,L
        .word   set2hl        @ d6 SET 2,(HL)
        .word   set2a         @ d7 SET 2,A
        .word   set3b         @ d8 SET 3,B
        .word   set3c         @ d9 SET 3,C
        .word   set3d         @ da SET 3,D
        .word   set3e         @ db SET 3,E
        .word   set3h         @ dc SET 3,H
        .word   set3l         @ dd SET 3,L
        .word   set3hl        @ de SET 3,(HL)
        .word   set3a         @ df SET 3,A
        .word   set4b         @ e0 SET 4,B
        .word   set4c         @ e1 SET 4,C
        .word   set4d         @ e2 SET 4,D
        .word   set4e         @ e3 SET 4,E
        .word   set4h         @ e4 SET 4,H
        .word   set4l         @ e5 SET 4,L
        .word   set4hl        @ e6 SET 4,(HL)
        .word   set4a         @ e7 SET 4,A
        .word   set5b         @ e8 SET 5,B
        .word   set5c         @ e9 SET 5,C
        .word   set5d         @ ea SET 5,D
        .word   set5e         @ eb SET 5,E
        .word   set5h         @ ec SET 5,H
        .word   set5l         @ ed SET 5,L
        .word   set5hl        @ ee SET 5,(HL)
        .word   set5a         @ ef SET 5,A
        .word   set6b         @ f0 SET 6,B
        .word   set6c         @ f1 SET 6,C
        .word   set6d         @ f2 SET 6,D
        .word   set6e         @ f3 SET 6,E
        .word   set6h         @ f4 SET 6,H
        .word   set6l         @ f5 SET 6,L
        .word   set6hl        @ f6 SET 6,(HL)
        .word   set6a         @ f7 SET 6,A
        .word   set7b         @ f8 SET 7,B
        .word   set7c         @ f9 SET 7,C
        .word   set7d         @ fa SET 7,D
        .word   set7e         @ fb SET 7,E
        .word   set7h         @ fc SET 7,H
        .word   set7l         @ fd SET 7,L
        .word   set7hl        @ fe SET 7,(HL)
        .word   set7a         @ ff SET 7,A

rlc_b:  RLC     bcfb, 8
rlc_c:  RLC     bcfb, 0
rlc_d:  RLC     defr, 8
rlc_e:  RLC     defr, 0
rlc_h:  RLC     hlmp, 8
rlc_l:  RLC     hlmp, 0
rlc_hl: TIME    15
        ldrb    lr, [mem, hlmp, lsr #16]
        add     lr, lr, lr, lsl #8
        pkhtb   pcff, pcff, lr, asr #7
        uxtb    lr, pcff
        pkhtb   defr, defr, lr
        orr     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, hlmp, lsr #16]
        b       salida
rlc_a:  RLC     arvpref, 8
rrc_b:  RRC     bcfb, 8
rrc_c:  RRC     bcfb, 0
rrc_d:  RRC     defr, 8
rrc_e:  RRC     defr, 0
rrc_h:  RRC     hlmp, 8
rrc_l:  RRC     hlmp, 0
rrc_hl: TIME    15
        ldrb    lr, [mem, hlmp, lsr #16]
        movs    lr, lr, lsr #1
        orrcs   lr, #0x00000180
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        pkhtb   defr, defr, lr
        orr     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, hlmp, lsr #16]
        b       salida
rrc_a:  RRC     arvpref, 8
rl_b:   RL      bcfb, 8
rl_c:   RL      bcfb, 0
rl_d:   RL      defr, 8
rl_e:   RL      defr, 0
rl_h:   RL      hlmp, 8
rl_l:   RL      hlmp, 0
rl_hl:  TIME    15
        movs    lr, pcff, lsl #24
        ldrb    lr, [mem, hlmp, lsr #16]
        adc     lr, lr
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, hlmp, lsr #16]
        b       salida
rl_a:   RL      arvpref, 8
rr_b:   RR      bcfb, 8
rr_c:   RR      bcfb, 0
rr_d:   RR      defr, 8
rr_e:   RR      defr, 0
rr_h:   RR      hlmp, 8
rr_l:   RR      hlmp, 0
rr_hl:  TIME    15
        ldrb    lr, [mem, hlmp, lsr #16]
        add     lr, lr, lr, lsl #9
        and     r10, pcff, #0x00000100
        orr     lr, r10
        pkhtb   pcff, pcff, lr, asr #1
        uxtb    lr, pcff
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, hlmp, lsr #16]
        b       salida
rr_a:   RR      arvpref, 8
sla_b:  SLA     bcfb, 8
sla_c:  SLA     bcfb, 0
sla_d:  SLA     defr, 8
sla_e:  SLA     defr, 0
sla_h:  SLA     hlmp, 8
sla_l:  SLA     hlmp, 0
sla_hl: TIME    15
        ldrb    lr, [mem, hlmp, lsr #16]
        mov     lr, lr, lsl #1
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, hlmp, lsr #16]
        b       salida
sla_a:  SLA     arvpref, 8
sra_b:  SRA     bcfb, 8
sra_c:  SRA     bcfb, 0
sra_d:  SRA     defr, 8
sra_e:  SRA     defr, 0
sra_h:  SRA     hlmp, 8
sra_l:  SRA     hlmp, 0
sra_hl: TIME    15
        ldrb    lr, [mem, hlmp, lsr #16]
        add     lr, lr, lr, lsl #9
        tst     lr, #0x00000080
        orrne   lr, #0x00000100
        pkhtb   pcff, pcff, lr, asr #1
        uxtb    lr, pcff
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, hlmp, lsr #16]
        b       salida
sra_a:  SRA     arvpref, 8
sll_b:  SLL     bcfb, 8
sll_c:  SLL     bcfb, 0
sll_d:  SLL     defr, 8
sll_e:  SLL     defr, 0
sll_h:  SLL     hlmp, 8
sll_l:  SLL     hlmp, 0
sll_hl: TIME    15
        ldrb    lr, [mem, hlmp, lsr #16]
        mov     lr, lr, lsl #1
        orr     lr, #0x00000001
        pkhtb   pcff, pcff, lr
        uxtb    lr, lr
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, hlmp, lsr #16]
        b       salida
sll_a:  SLL     arvpref, 8
srl_b:  SRL     bcfb, 8
srl_c:  SRL     bcfb, 0
srl_d:  SRL     defr, 8
srl_e:  SRL     defr, 0
srl_h:  SRL     hlmp, 8
srl_l:  SRL     hlmp, 0
srl_hl: TIME    15
        ldrb    lr, [mem, hlmp, lsr #16]
        add     lr, lr, lr, lsl #9
        pkhtb   pcff, pcff, lr, asr #1
        uxtb    lr, pcff
        pkhtb   defr, defr, lr
        add     lr, #0x00000100
        pkhtb   spfa, spfa, lr
        pkhtb   bcfb, bcfb, lr, asr #16
        strb    lr, [mem, hlmp, lsr #16]
        b       salida
srl_a:  SRL     arvpref, 8

bit0b:  BIT     0x01, bcfb, 8
bit0c:  BIT     0x01, bcfb, 0
bit0d:  BIT     0x01, defr, 8
bit0e:  BIT     0x01, defr, 0
bit0h:  BIT     0x01, hlmp, 8
bit0l:  BIT     0x01, hlmp, 0
bit0hl: BITHL   0x01
bit0a:  BIT     0x01, arvpref, 8
bit1b:  BIT     0x02, bcfb, 8
bit1c:  BIT     0x02, bcfb, 0
bit1d:  BIT     0x02, defr, 8
bit1e:  BIT     0x02, defr, 0
bit1h:  BIT     0x02, hlmp, 8
bit1l:  BIT     0x02, hlmp, 0
bit1hl: BITHL   0x02
bit1a:  BIT     0x02, arvpref, 8
bit2b:  BIT     0x04, bcfb, 8
bit2c:  BIT     0x04, bcfb, 0
bit2d:  BIT     0x04, defr, 8
bit2e:  BIT     0x04, defr, 0
bit2h:  BIT     0x04, hlmp, 8
bit2l:  BIT     0x04, hlmp, 0
bit2hl: BITHL   0x04
bit2a:  BIT     0x04, arvpref, 8
bit3b:  BIT     0x08, bcfb, 8
bit3c:  BIT     0x08, bcfb, 0
bit3d:  BIT     0x08, defr, 8
bit3e:  BIT     0x08, defr, 0
bit3h:  BIT     0x08, hlmp, 8
bit3l:  BIT     0x08, hlmp, 0
bit3hl: BITHL   0x08
bit3a:  BIT     0x08, arvpref, 8
bit4b:  BIT     0x10, bcfb, 8
bit4c:  BIT     0x10, bcfb, 0
bit4d:  BIT     0x10, defr, 8
bit4e:  BIT     0x10, defr, 0
bit4h:  BIT     0x10, hlmp, 8
bit4l:  BIT     0x10, hlmp, 0
bit4hl: BITHL   0x10
bit4a:  BIT     0x10, arvpref, 8
bit5b:  BIT     0x20, bcfb, 8
bit5c:  BIT     0x20, bcfb, 0
bit5d:  BIT     0x20, defr, 8
bit5e:  BIT     0x20, defr, 0
bit5h:  BIT     0x20, hlmp, 8
bit5l:  BIT     0x20, hlmp, 0
bit5hl: BITHL   0x20
bit5a:  BIT     0x20, arvpref, 8
bit6b:  BIT     0x40, bcfb, 8
bit6c:  BIT     0x40, bcfb, 0
bit6d:  BIT     0x40, defr, 8
bit6e:  BIT     0x40, defr, 0
bit6h:  BIT     0x40, hlmp, 8
bit6l:  BIT     0x40, hlmp, 0
bit6hl: BITHL   0x40
bit6a:  BIT     0x40, arvpref, 8
bit7b:  BIT     0x80, bcfb, 8
bit7c:  BIT     0x80, bcfb, 0
bit7d:  BIT     0x80, defr, 8
bit7e:  BIT     0x80, defr, 0
bit7h:  BIT     0x80, hlmp, 8
bit7l:  BIT     0x80, hlmp, 0
bit7hl: BITHL   0x80
bit7a:  BIT     0x80, arvpref, 8

res0b:  RES     0xfe, bcfb, 8
res0c:  RES     0xfe, bcfb, 0
res0d:  RES     0xfe, defr, 8
res0e:  RES     0xfe, defr, 0
res0h:  RES     0xfe, hlmp, 8
res0l:  RES     0xfe, hlmp, 0
res0hl: RESHL   0xfe
res0a:  RES     0xfe, arvpref, 8
res1b:  RES     0xfd, bcfb, 8
res1c:  RES     0xfd, bcfb, 0
res1d:  RES     0xfd, defr, 8
res1e:  RES     0xfd, defr, 0
res1h:  RES     0xfd, hlmp, 8
res1l:  RES     0xfd, hlmp, 0
res1hl: RESHL   0xfd
res1a:  RES     0xfd, arvpref, 8
res2b:  RES     0xfb, bcfb, 8
res2c:  RES     0xfb, bcfb, 0
res2d:  RES     0xfb, defr, 8
res2e:  RES     0xfb, defr, 0
res2h:  RES     0xfb, hlmp, 8
res2l:  RES     0xfb, hlmp, 0
res2hl: RESHL   0xfb
res2a:  RES     0xfb, arvpref, 8
res3b:  RES     0xf7, bcfb, 8
res3c:  RES     0xf7, bcfb, 0
res3d:  RES     0xf7, defr, 8
res3e:  RES     0xf7, defr, 0
res3h:  RES     0xf7, hlmp, 8
res3l:  RES     0xf7, hlmp, 0
res3hl: RESHL   0xf7
res3a:  RES     0xf7, arvpref, 8
res4b:  RES     0xef, bcfb, 8
res4c:  RES     0xef, bcfb, 0
res4d:  RES     0xef, defr, 8
res4e:  RES     0xef, defr, 0
res4h:  RES     0xef, hlmp, 8
res4l:  RES     0xef, hlmp, 0
res4hl: RESHL   0xef
res4a:  RES     0xef, arvpref, 8
res5b:  RES     0xdf, bcfb, 8
res5c:  RES     0xdf, bcfb, 0
res5d:  RES     0xdf, defr, 8
res5e:  RES     0xdf, defr, 0
res5h:  RES     0xdf, hlmp, 8
res5l:  RES     0xdf, hlmp, 0
res5hl: RESHL   0xdf
res5a:  RES     0xdf, arvpref, 8
res6b:  RES     0xbf, bcfb, 8
res6c:  RES     0xbf, bcfb, 0
res6d:  RES     0xbf, defr, 8
res6e:  RES     0xbf, defr, 0
res6h:  RES     0xbf, hlmp, 8
res6l:  RES     0xbf, hlmp, 0
res6hl: RESHL   0xbf
res6a:  RES     0xbf, arvpref, 8
res7b:  RES     0x7f, bcfb, 8
res7c:  RES     0x7f, bcfb, 0
res7d:  RES     0x7f, defr, 8
res7e:  RES     0x7f, defr, 0
res7h:  RES     0x7f, hlmp, 8
res7l:  RES     0x7f, hlmp, 0
res7hl: RESHL   0x7f
res7a:  RES     0x7f, arvpref, 8

set0b:  SET     0x01, bcfb, 8
set0c:  SET     0x01, bcfb, 0
set0d:  SET     0x01, defr, 8
set0e:  SET     0x01, defr, 0
set0h:  SET     0x01, hlmp, 8
set0l:  SET     0x01, hlmp, 0
set0hl: SETHL   0x01
set0a:  SET     0x01, arvpref, 8
set1b:  SET     0x02, bcfb, 8
set1c:  SET     0x02, bcfb, 0
set1d:  SET     0x02, defr, 8
set1e:  SET     0x02, defr, 0
set1h:  SET     0x02, hlmp, 8
set1l:  SET     0x02, hlmp, 0
set1hl: SETHL   0x02
set1a:  SET     0x02, arvpref, 8
set2b:  SET     0x04, bcfb, 8
set2c:  SET     0x04, bcfb, 0
set2d:  SET     0x04, defr, 8
set2e:  SET     0x04, defr, 0
set2h:  SET     0x04, hlmp, 8
set2l:  SET     0x04, hlmp, 0
set2hl: SETHL   0x04
set2a:  SET     0x04, arvpref, 8
set3b:  SET     0x08, bcfb, 8
set3c:  SET     0x08, bcfb, 0
set3d:  SET     0x08, defr, 8
set3e:  SET     0x08, defr, 0
set3h:  SET     0x08, hlmp, 8
set3l:  SET     0x08, hlmp, 0
set3hl: SETHL   0x08
set3a:  SET     0x08, arvpref, 8
set4b:  SET     0x10, bcfb, 8
set4c:  SET     0x10, bcfb, 0
set4d:  SET     0x10, defr, 8
set4e:  SET     0x10, defr, 0
set4h:  SET     0x10, hlmp, 8
set4l:  SET     0x10, hlmp, 0
set4hl: SETHL   0x10
set4a:  SET     0x10, arvpref, 8
set5b:  SET     0x20, bcfb, 8
set5c:  SET     0x20, bcfb, 0
set5d:  SET     0x20, defr, 8
set5e:  SET     0x20, defr, 0
set5h:  SET     0x20, hlmp, 8
set5l:  SET     0x20, hlmp, 0
set5hl: SETHL   0x20
set5a:  SET     0x20, arvpref, 8
set6b:  SET     0x40, bcfb, 8
set6c:  SET     0x40, bcfb, 0
set6d:  SET     0x40, defr, 8
set6e:  SET     0x40, defr, 0
set6h:  SET     0x40, hlmp, 8
set6l:  SET     0x40, hlmp, 0
set6hl: SETHL   0x40
set6a:  SET     0x40, arvpref, 8
set7b:  SET     0x80, bcfb, 8
set7c:  SET     0x80, bcfb, 0
set7d:  SET     0x80, defr, 8
set7e:  SET     0x80, defr, 0
set7h:  SET     0x80, hlmp, 8
set7l:  SET     0x80, hlmp, 0
set7hl: SETHL   0x80
set7a:  SET     0x80, arvpref, 8

@--------------------------------

b_rlcx: RLCX    bcfb, 8
c_rlcx: RLCX    bcfb, 0
d_rlcx: RLCX    defr, 8
e_rlcx: RLCX    defr, 0
h_rlcx: RLCX    hlmp, 8
l_rlcx: RLCX    hlmp, 0
rlcx:   RLCX    arvpref, 0
a_rlcx: RLCX    arvpref, 8
b_rrcx: RRCX    bcfb, 8
c_rrcx: RRCX    bcfb, 0
d_rrcx: RRCX    defr, 8
e_rrcx: RRCX    defr, 0
h_rrcx: RRCX    hlmp, 8
l_rrcx: RRCX    hlmp, 0
rrcx:   RRCX    arvpref, 0
a_rrcx: RRCX    arvpref, 8
b_rlx:  RLX     bcfb, 8
c_rlx:  RLX     bcfb, 0
d_rlx:  RLX     defr, 8
e_rlx:  RLX     defr, 0
h_rlx:  RLX     hlmp, 8
l_rlx:  RLX     hlmp, 0
rlx:    RLX     arvpref, 0
a_rlx:  RLX     arvpref, 8
b_rrx:  RRX     bcfb, 8
c_rrx:  RRX     bcfb, 0
d_rrx:  RRX     defr, 8
e_rrx:  RRX     defr, 0
h_rrx:  RRX     hlmp, 8
l_rrx:  RRX     hlmp, 0
rrx:    RRX     arvpref, 0
a_rrx:  RRX     arvpref, 8
b_slax: SLAX    bcfb, 8
c_slax: SLAX    bcfb, 0
d_slax: SLAX    defr, 8
e_slax: SLAX    defr, 0
h_slax: SLAX    hlmp, 8
l_slax: SLAX    hlmp, 0
slax:   SLAX    arvpref, 0
a_slax: SLAX    arvpref, 8
b_srax: SRAX    bcfb, 8
c_srax: SRAX    bcfb, 0
d_srax: SRAX    defr, 8
e_srax: SRAX    defr, 0
h_srax: SRAX    hlmp, 8
l_srax: SRAX    hlmp, 0
srax:   SRAX    arvpref, 0
a_srax: SRAX    arvpref, 8
b_sllx: SLLX    bcfb, 8
c_sllx: SLLX    bcfb, 0
d_sllx: SLLX    defr, 8
e_sllx: SLLX    defr, 0
h_sllx: SLLX    hlmp, 8
l_sllx: SLLX    hlmp, 0
sllx:   SLLX    arvpref, 0
a_sllx: SLLX    arvpref, 8
b_srlx: SRLX    bcfb, 8
c_srlx: SRLX    bcfb, 0
d_srlx: SRLX    defr, 8
e_srlx: SRLX    defr, 0
h_srlx: SRLX    hlmp, 8
l_srlx: SRLX    hlmp, 0
srlx:   SRLX    arvpref, 0
a_srlx: SRLX    arvpref, 8
biti0:  BITI    0x01
biti1:  BITI    0x02
biti2:  BITI    0x04
biti3:  BITI    0x08
biti4:  BITI    0x10
biti5:  BITI    0x20
biti6:  BITI    0x40
biti7:  BITI    0x80
b_res0x:RESXD   0xfffffffe, bcfb, 8
c_res0x:RESXD   0xfffffffe, bcfb, 0
d_res0x:RESXD   0xfffffffe, defr, 8
e_res0x:RESXD   0xfffffffe, defr, 0
h_res0x:RESXD   0xfffffffe, hlmp, 8
l_res0x:RESXD   0xfffffffe, hlmp, 0
res0x:  RESXD   0xfffffffe, arvpref, 0
a_res0x:RESXD   0xfffffffe, arvpref, 8
b_res1x:RESXD   0xfffffffd, bcfb, 8
c_res1x:RESXD   0xfffffffd, bcfb, 0
d_res1x:RESXD   0xfffffffd, defr, 8
e_res1x:RESXD   0xfffffffd, defr, 0
h_res1x:RESXD   0xfffffffd, hlmp, 8
l_res1x:RESXD   0xfffffffd, hlmp, 0
res1x:  RESXD   0xfffffffd, arvpref, 0
a_res1x:RESXD   0xfffffffd, arvpref, 8
b_res2x:RESXD   0xfffffffb, bcfb, 8
c_res2x:RESXD   0xfffffffb, bcfb, 0
d_res2x:RESXD   0xfffffffb, defr, 8
e_res2x:RESXD   0xfffffffb, defr, 0
h_res2x:RESXD   0xfffffffb, hlmp, 8
l_res2x:RESXD   0xfffffffb, hlmp, 0
res2x:  RESXD   0xfffffffb, arvpref, 0
a_res2x:RESXD   0xfffffffb, arvpref, 8
b_res3x:RESXD   0xfffffff7, bcfb, 8
c_res3x:RESXD   0xfffffff7, bcfb, 0
d_res3x:RESXD   0xfffffff7, defr, 8
e_res3x:RESXD   0xfffffff7, defr, 0
h_res3x:RESXD   0xfffffff7, hlmp, 8
l_res3x:RESXD   0xfffffff7, hlmp, 0
res3x:  RESXD   0xfffffff7, arvpref, 0
a_res3x:RESXD   0xfffffff7, arvpref, 8
b_res4x:RESXD   0xffffffef, bcfb, 8
c_res4x:RESXD   0xffffffef, bcfb, 0
d_res4x:RESXD   0xffffffef, defr, 8
e_res4x:RESXD   0xffffffef, defr, 0
h_res4x:RESXD   0xffffffef, hlmp, 8
l_res4x:RESXD   0xffffffef, hlmp, 0
res4x:  RESXD   0xffffffef, arvpref, 0
a_res4x:RESXD   0xffffffef, arvpref, 8
b_res5x:RESXD   0xffffffdf, bcfb, 8
c_res5x:RESXD   0xffffffdf, bcfb, 0
d_res5x:RESXD   0xffffffdf, defr, 8
e_res5x:RESXD   0xffffffdf, defr, 0
h_res5x:RESXD   0xffffffdf, hlmp, 8
l_res5x:RESXD   0xffffffdf, hlmp, 0
res5x:  RESXD   0xffffffdf, arvpref, 0
a_res5x:RESXD   0xffffffdf, arvpref, 8
b_res6x:RESXD   0xffffffbf, bcfb, 8
c_res6x:RESXD   0xffffffbf, bcfb, 0
d_res6x:RESXD   0xffffffbf, defr, 8
e_res6x:RESXD   0xffffffbf, defr, 0
h_res6x:RESXD   0xffffffbf, hlmp, 8
l_res6x:RESXD   0xffffffbf, hlmp, 0
res6x:  RESXD   0xffffffbf, arvpref, 0
a_res6x:RESXD   0xffffffbf, arvpref, 8
b_res7x:RESXD   0xffffff7f, bcfb, 8
c_res7x:RESXD   0xffffff7f, bcfb, 0
d_res7x:RESXD   0xffffff7f, defr, 8
e_res7x:RESXD   0xffffff7f, defr, 0
h_res7x:RESXD   0xffffff7f, hlmp, 8
l_res7x:RESXD   0xffffff7f, hlmp, 0
res7x:  RESXD   0xffffff7f, arvpref, 0
a_res7x:RESXD   0xffffff7f, arvpref, 8
b_set0x:SETXD   0x01, bcfb, 8
c_set0x:SETXD   0x01, bcfb, 0
d_set0x:SETXD   0x01, defr, 8
e_set0x:SETXD   0x01, defr, 0
h_set0x:SETXD   0x01, hlmp, 8
l_set0x:SETXD   0x01, hlmp, 0
set0x:  SETXD   0x01, arvpref, 0
a_set0x:SETXD   0x01, arvpref, 8
b_set1x:SETXD   0x02, bcfb, 8
c_set1x:SETXD   0x02, bcfb, 0
d_set1x:SETXD   0x02, defr, 8
e_set1x:SETXD   0x02, defr, 0
h_set1x:SETXD   0x02, hlmp, 8
l_set1x:SETXD   0x02, hlmp, 0
set1x:  SETXD   0x02, arvpref, 0
a_set1x:SETXD   0x02, arvpref, 8
b_set2x:SETXD   0x04, bcfb, 8
c_set2x:SETXD   0x04, bcfb, 0
d_set2x:SETXD   0x04, defr, 8
e_set2x:SETXD   0x04, defr, 0
h_set2x:SETXD   0x04, hlmp, 8
l_set2x:SETXD   0x04, hlmp, 0
set2x:  SETXD   0x04, arvpref, 0
a_set2x:SETXD   0x04, arvpref, 8
b_set3x:SETXD   0x08, bcfb, 8
c_set3x:SETXD   0x08, bcfb, 0
d_set3x:SETXD   0x08, defr, 8
e_set3x:SETXD   0x08, defr, 0
h_set3x:SETXD   0x08, hlmp, 8
l_set3x:SETXD   0x08, hlmp, 0
set3x:  SETXD   0x08, arvpref, 0
a_set3x:SETXD   0x08, arvpref, 8
b_set4x:SETXD   0x10, bcfb, 8
c_set4x:SETXD   0x10, bcfb, 0
d_set4x:SETXD   0x10, defr, 8
e_set4x:SETXD   0x10, defr, 0
h_set4x:SETXD   0x10, hlmp, 8
l_set4x:SETXD   0x10, hlmp, 0
set4x:  SETXD   0x10, arvpref, 0
a_set4x:SETXD   0x10, arvpref, 8
b_set5x:SETXD   0x20, bcfb, 8
c_set5x:SETXD   0x20, bcfb, 0
d_set5x:SETXD   0x20, defr, 8
e_set5x:SETXD   0x20, defr, 0
h_set5x:SETXD   0x20, hlmp, 8
l_set5x:SETXD   0x20, hlmp, 0
set5x:  SETXD   0x20, arvpref, 0
a_set5x:SETXD   0x20, arvpref, 8
b_set6x:SETXD   0x40, bcfb, 8
c_set6x:SETXD   0x40, bcfb, 0
d_set6x:SETXD   0x40, defr, 8
e_set6x:SETXD   0x40, defr, 0
h_set6x:SETXD   0x40, hlmp, 8
l_set6x:SETXD   0x40, hlmp, 0
set6x:  SETXD   0x40, arvpref, 0
a_set6x:SETXD   0x40, arvpref, 8
b_set7x:SETXD   0x80, bcfb, 8
c_set7x:SETXD   0x80, bcfb, 0
d_set7x:SETXD   0x80, defr, 8
e_set7x:SETXD   0x80, defr, 0
h_set7x:SETXD   0x80, hlmp, 8
l_set7x:SETXD   0x80, hlmp, 0
set7x:  SETXD   0x80, arvpref, 0
a_set7x:SETXD   0x80, arvpref, 8

opxdcb: bmi     opfdcb
opddcb: TIME    11
        ldr     lr, [mem, pcff, lsr #16]
        sxtb    r11, lr
        add     r11, ixstart, lsr #16
        b       contcb
opfdcb: TIME    11
        ldr     lr, [mem, pcff, lsr #16]
        sxtb    r11, lr
        add     r11, iyi, lsr #16
contcb: bic     arvpref, #0xff
        pkhtb   hlmp, hlmp, r11
        ldrb    r10, [mem, r11]
        uxtb    lr, lr, ror #8
        add     pcff, #0x00020000
        ldr     pc, [pc, lr, lsl #2]
c18003: .word   0x00018003
        .word   b_rlcx        @ 00 LD B,RLC (IX+d) // LD B,RLC (IY+d)
        .word   c_rlcx        @ 01 LD C,RLC (IX+d) // LD C,RLC (IY+d)
        .word   d_rlcx        @ 02 LD D,RLC (IX+d) // LD D,RLC (IY+d)
        .word   e_rlcx        @ 03 LD E,RLC (IX+d) // LD E,RLC (IY+d)
        .word   h_rlcx        @ 04 LD H,RLC (IX+d) // LD H,RLC (IY+d)
        .word   l_rlcx        @ 05 LD L,RLC (IX+d) // LD L,RLC (IY+d)
        .word   rlcx          @ 06 RLC (IX+d) // RLC (IY+d)
        .word   a_rlcx        @ 07 LD A,RLC (IX+d) // LD A,RLC (IY+d)
        .word   b_rrcx        @ 08 LD B,RRC (IX+d) // LD B,RRC (IY+d)
        .word   c_rrcx        @ 09 LD C,RRC (IX+d) // LD C,RRC (IY+d)
        .word   d_rrcx        @ 0a LD D,RRC (IX+d) // LD D,RRC (IY+d)
        .word   e_rrcx        @ 0b LD E,RRC (IX+d) // LD E,RRC (IY+d)
        .word   h_rrcx        @ 0c LD H,RRC (IX+d) // LD H,RRC (IY+d)
        .word   l_rrcx        @ 0d LD L,RRC (IX+d) // LD L,RRC (IY+d)
        .word   rrcx          @ 0e RRC (IX+d) // RRC (IY+d)
        .word   a_rrcx        @ 0f LD A,RRC (IX+d) // LD A,RRC (IY+d)
        .word   b_rlx         @ 10 LD B,RL (IX+d) // LD B,RL (IY+d)
        .word   c_rlx         @ 11 LD C,RL (IX+d) // LD C,RL (IY+d)
        .word   d_rlx         @ 12 LD D,RL (IX+d) // LD D,RL (IY+d)
        .word   e_rlx         @ 13 LD E,RL (IX+d) // LD E,RL (IY+d)
        .word   h_rlx         @ 14 LD H,RL (IX+d) // LD H,RL (IY+d)
        .word   l_rlx         @ 15 LD L,RL (IX+d) // LD L,RL (IY+d)
        .word   rlx           @ 16 RL (IX+d) // RL (IY+d)
        .word   a_rlx         @ 17 LD A,RL (IX+d) // LD A,RL (IY+d)
        .word   b_rrx         @ 18 LD B,RR (IX+d) // LD B,RR (IY+d)
        .word   c_rrx         @ 19 LD C,RR (IX+d) // LD C,RR (IY+d)
        .word   d_rrx         @ 1a LD D,RR (IX+d) // LD D,RR (IY+d)
        .word   e_rrx         @ 1b LD E,RR (IX+d) // LD E,RR (IY+d)
        .word   h_rrx         @ 1c LD H,RR (IX+d) // LD H,RR (IY+d)
        .word   l_rrx         @ 1d LD L,RR (IX+d) // LD L,RR (IY+d)
        .word   rrx           @ 1e RR (IX+d) // RR (IY+d)
        .word   a_rrx         @ 1f LD A,RR (IX+d) // LD A,RR (IY+d)
        .word   b_slax        @ 20 LD B,SLA (IX+d) // LD B,SLA (IY+d)
        .word   c_slax        @ 21 LD C,SLA (IX+d) // LD C,SLA (IY+d)
        .word   d_slax        @ 22 LD D,SLA (IX+d) // LD D,SLA (IY+d)
        .word   e_slax        @ 23 LD E,SLA (IX+d) // LD E,SLA (IY+d)
        .word   h_slax        @ 24 LD H,SLA (IX+d) // LD H,SLA (IY+d)
        .word   l_slax        @ 25 LD L,SLA (IX+d) // LD L,SLA (IY+d)
        .word   slax          @ 26 SLA (IX+d) // SLA (IY+d)
        .word   a_slax        @ 27 LD A,SLA (IX+d) // LD A,SLA (IY+d)
        .word   b_srax        @ 28 LD B,SRA (IX+d) // LD B,SRA (IY+d)
        .word   c_srax        @ 29 LD C,SRA (IX+d) // LD C,SRA (IY+d)
        .word   d_srax        @ 2a LD D,SRA (IX+d) // LD D,SRA (IY+d)
        .word   e_srax        @ 2b LD E,SRA (IX+d) // LD E,SRA (IY+d)
        .word   h_srax        @ 2c LD H,SRA (IX+d) // LD H,SRA (IY+d)
        .word   l_srax        @ 2d LD L,SRA (IX+d) // LD L,SRA (IY+d)
        .word   srax          @ 2e SRA (IX+d) // SRA (IY+d)
        .word   a_srax        @ 2f LD A,SRA (IX+d) // LD A,SRA (IY+d)
        .word   b_sllx        @ 30 LD B,SLL (IX+d) // LD B,SLL (IY+d)
        .word   c_sllx        @ 31 LD C,SLL (IX+d) // LD C,SLL (IY+d)
        .word   d_sllx        @ 32 LD D,SLL (IX+d) // LD D,SLL (IY+d)
        .word   e_sllx        @ 33 LD E,SLL (IX+d) // LD E,SLL (IY+d)
        .word   h_sllx        @ 34 LD H,SLL (IX+d) // LD H,SLL (IY+d)
        .word   l_sllx        @ 35 LD L,SLL (IX+d) // LD L,SLL (IY+d)
        .word   sllx          @ 36 SLL (IX+d) // SLL (IY+d)
        .word   a_sllx        @ 37 LD A,SLL (IX+d) // LD A,SLL (IY+d)
        .word   b_srlx        @ 38 LD B,SRL (IX+d) // LD B,SRL (IY+d)
        .word   c_srlx        @ 39 LD C,SRL (IX+d) // LD C,SRL (IY+d)
        .word   d_srlx        @ 3a LD D,SRL (IX+d) // LD D,SRL (IY+d)
        .word   e_srlx        @ 3b LD E,SRL (IX+d) // LD E,SRL (IY+d)
        .word   h_srlx        @ 3c LD H,SRL (IX+d) // LD H,SRL (IY+d)
        .word   l_srlx        @ 3d LD L,SRL (IX+d) // LD L,SRL (IY+d)
        .word   srlx          @ 3e SRL (IX+d) // SRL (IY+d)
        .word   a_srlx        @ 3f LD A,SRL (IX+d) // LD A,SRL (IY+d)
        .word   biti0         @ 40 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti0         @ 41 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti0         @ 42 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti0         @ 43 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti0         @ 44 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti0         @ 45 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti0         @ 46 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti0         @ 47 BIT 0,(IX+d) // BIT 0,(IY+d)
        .word   biti1         @ 48 BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti1         @ 49 BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti1         @ 4a BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti1         @ 4b BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti1         @ 4c BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti1         @ 4d BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti1         @ 4e BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti1         @ 4f BIT 1,(IX+d) // BIT 1,(IY+d)
        .word   biti2         @ 50 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti2         @ 51 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti2         @ 52 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti2         @ 53 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti2         @ 54 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti2         @ 55 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti2         @ 56 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti2         @ 57 BIT 2,(IX+d) // BIT 2,(IY+d)
        .word   biti3         @ 58 BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti3         @ 59 BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti3         @ 5a BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti3         @ 5b BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti3         @ 5c BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti3         @ 5d BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti3         @ 5e BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti3         @ 5f BIT 3,(IX+d) // BIT 3,(IY+d)
        .word   biti4         @ 60 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti4         @ 61 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti4         @ 62 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti4         @ 63 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti4         @ 64 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti4         @ 65 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti4         @ 66 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti4         @ 67 BIT 4,(IX+d) // BIT 4,(IY+d)
        .word   biti5         @ 68 BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti5         @ 69 BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti5         @ 6a BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti5         @ 6b BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti5         @ 6c BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti5         @ 6d BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti5         @ 6e BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti5         @ 6f BIT 5,(IX+d) // BIT 5,(IY+d)
        .word   biti6         @ 70 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti6         @ 71 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti6         @ 72 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti6         @ 73 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti6         @ 74 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti6         @ 75 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti6         @ 76 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti6         @ 77 BIT 6,(IX+d) // BIT 6,(IY+d)
        .word   biti7         @ 78 BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   biti7         @ 79 BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   biti7         @ 7a BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   biti7         @ 7b BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   biti7         @ 7c BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   biti7         @ 7d BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   biti7         @ 7e BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   biti7         @ 7f BIT 7,(IX+d) // BIT 7,(IY+d)
        .word   b_res0x       @ 80 LD B,RES 0,(IX+d) // LD B,RES 0,(IY+d)
        .word   c_res0x       @ 81 LD C,RES 0,(IX+d) // LD C,RES 0,(IY+d)
        .word   d_res0x       @ 82 LD D,RES 0,(IX+d) // LD D,RES 0,(IY+d)
        .word   e_res0x       @ 83 LD E,RES 0,(IX+d) // LD E,RES 0,(IY+d)
        .word   h_res0x       @ 84 LD H,RES 0,(IX+d) // LD H,RES 0,(IY+d)
        .word   l_res0x       @ 85 LD L,RES 0,(IX+d) // LD L,RES 0,(IY+d)
        .word   res0x         @ 86 RES 0,(IX+d) // RES 0,(IY+d)
        .word   a_res0x       @ 87 LD A,RES 0,(IX+d) // LD A,RES 0,(IY+d)
        .word   b_res1x       @ 88 LD B,RES 1,(IX+d) // LD B,RES 1,(IY+d)
        .word   c_res1x       @ 89 LD C,RES 1,(IX+d) // LD C,RES 1,(IY+d)
        .word   d_res1x       @ 8a LD D,RES 1,(IX+d) // LD D,RES 1,(IY+d)
        .word   e_res1x       @ 8b LD E,RES 1,(IX+d) // LD E,RES 1,(IY+d)
        .word   h_res1x       @ 8c LD H,RES 1,(IX+d) // LD H,RES 1,(IY+d)
        .word   l_res1x       @ 8d LD L,RES 1,(IX+d) // LD L,RES 1,(IY+d)
        .word   res1x         @ 8e RES 1,(IX+d) // RES 1,(IY+d)
        .word   a_res1x       @ 8f LD A,RES 1,(IX+d) // LD A,RES 1,(IY+d)
        .word   b_res2x       @ 90 LD B,RES 2,(IX+d) // LD B,RES 2,(IY+d)
        .word   c_res2x       @ 91 LD C,RES 2,(IX+d) // LD C,RES 2,(IY+d)
        .word   d_res2x       @ 92 LD D,RES 2,(IX+d) // LD D,RES 2,(IY+d)
        .word   e_res2x       @ 93 LD E,RES 2,(IX+d) // LD E,RES 2,(IY+d)
        .word   h_res2x       @ 94 LD H,RES 2,(IX+d) // LD H,RES 2,(IY+d)
        .word   l_res2x       @ 95 LD L,RES 2,(IX+d) // LD L,RES 2,(IY+d)
        .word   res2x         @ 96 RES 2,(IX+d) // RES 2,(IY+d)
        .word   a_res2x       @ 97 LD A,RES 2,(IX+d) // LD A,RES 2,(IY+d)
        .word   b_res3x       @ 98 LD B,RES 3,(IX+d) // LD B,RES 3,(IY+d)
        .word   c_res3x       @ 99 LD C,RES 3,(IX+d) // LD C,RES 3,(IY+d)
        .word   d_res3x       @ 9a LD D,RES 3,(IX+d) // LD D,RES 3,(IY+d)
        .word   e_res3x       @ 9b LD E,RES 3,(IX+d) // LD E,RES 3,(IY+d)
        .word   h_res3x       @ 9c LD H,RES 3,(IX+d) // LD H,RES 3,(IY+d)
        .word   l_res3x       @ 9d LD L,RES 3,(IX+d) // LD L,RES 3,(IY+d)
        .word   res3x         @ 9e RES 3,(IX+d) // RES 3,(IY+d)
        .word   a_res3x       @ 9f LD A,RES 3,(IX+d) // LD A,RES 3,(IY+d)
        .word   b_res4x       @ a0 LD B,RES 4,(IX+d) // LD B,RES 4,(IY+d)
        .word   c_res4x       @ a1 LD C,RES 4,(IX+d) // LD C,RES 4,(IY+d)
        .word   d_res4x       @ a2 LD D,RES 4,(IX+d) // LD D,RES 4,(IY+d)
        .word   e_res4x       @ a3 LD E,RES 4,(IX+d) // LD E,RES 4,(IY+d)
        .word   h_res4x       @ a4 LD H,RES 4,(IX+d) // LD H,RES 4,(IY+d)
        .word   l_res4x       @ a5 LD L,RES 4,(IX+d) // LD L,RES 4,(IY+d)
        .word   res4x         @ a6 RES 4,(IX+d) // RES 4,(IY+d)
        .word   a_res4x       @ a7 LD A,RES 4,(IX+d) // LD A,RES 4,(IY+d)
        .word   b_res5x       @ a8 LD B,RES 5,(IX+d) // LD B,RES 5,(IY+d)
        .word   c_res5x       @ a9 LD C,RES 5,(IX+d) // LD C,RES 5,(IY+d)
        .word   d_res5x       @ aa LD D,RES 5,(IX+d) // LD D,RES 5,(IY+d)
        .word   e_res5x       @ ab LD E,RES 5,(IX+d) // LD E,RES 5,(IY+d)
        .word   h_res5x       @ ac LD H,RES 5,(IX+d) // LD H,RES 5,(IY+d)
        .word   l_res5x       @ ad LD L,RES 5,(IX+d) // LD L,RES 5,(IY+d)
        .word   res5x         @ ae RES 5,(IX+d) // RES 5,(IY+d)
        .word   a_res5x       @ af LD A,RES 5,(IX+d) // LD A,RES 5,(IY+d)
        .word   b_res6x       @ b0 LD B,RES 6,(IX+d) // LD B,RES 6,(IY+d)
        .word   c_res6x       @ b1 LD C,RES 6,(IX+d) // LD C,RES 6,(IY+d)
        .word   d_res6x       @ b2 LD D,RES 6,(IX+d) // LD D,RES 6,(IY+d)
        .word   e_res6x       @ b3 LD E,RES 6,(IX+d) // LD E,RES 6,(IY+d)
        .word   h_res6x       @ b4 LD H,RES 6,(IX+d) // LD H,RES 6,(IY+d)
        .word   l_res6x       @ b5 LD L,RES 6,(IX+d) // LD L,RES 6,(IY+d)
        .word   res6x         @ b6 RES 6,(IX+d) // RES 6,(IY+d)
        .word   a_res6x       @ b7 LD A,RES 6,(IX+d) // LD A,RES 6,(IY+d)
        .word   b_res7x       @ b8 LD B,RES 7,(IX+d) // LD B,RES 7,(IY+d)
        .word   c_res7x       @ b9 LD C,RES 7,(IX+d) // LD C,RES 7,(IY+d)
        .word   d_res7x       @ ba LD D,RES 7,(IX+d) // LD D,RES 7,(IY+d)
        .word   e_res7x       @ bb LD E,RES 7,(IX+d) // LD E,RES 7,(IY+d)
        .word   h_res7x       @ bc LD H,RES 7,(IX+d) // LD H,RES 7,(IY+d)
        .word   l_res7x       @ bd LD L,RES 7,(IX+d) // LD L,RES 7,(IY+d)
        .word   res7x         @ be RES 7,(IX+d) // RES 7,(IY+d)
        .word   a_res7x       @ bf LD A,RES 7,(IX+d) // LD A,RES 7,(IY+d)
        .word   b_set0x       @ c0 LD B,SET 0,(IX+d) // LD B,SET 0,(IY+d)
        .word   c_set0x       @ c1 LD C,SET 0,(IX+d) // LD C,SET 0,(IY+d)
        .word   d_set0x       @ c2 LD D,SET 0,(IX+d) // LD D,SET 0,(IY+d)
        .word   e_set0x       @ c3 LD E,SET 0,(IX+d) // LD E,SET 0,(IY+d)
        .word   h_set0x       @ c4 LD H,SET 0,(IX+d) // LD H,SET 0,(IY+d)
        .word   l_set0x       @ c5 LD L,SET 0,(IX+d) // LD L,SET 0,(IY+d)
        .word   set0x         @ c6 SET 0,(IX+d) // SET 0,(IY+d)
        .word   a_set0x       @ c7 LD A,SET 0,(IX+d) // LD A,SET 0,(IY+d)
        .word   b_set1x       @ c8 LD B,SET 1,(IX+d) // LD B,SET 1,(IY+d)
        .word   c_set1x       @ c9 LD C,SET 1,(IX+d) // LD C,SET 1,(IY+d)
        .word   d_set1x       @ ca LD D,SET 1,(IX+d) // LD D,SET 1,(IY+d)
        .word   e_set1x       @ cb LD E,SET 1,(IX+d) // LD E,SET 1,(IY+d)
        .word   h_set1x       @ cc LD H,SET 1,(IX+d) // LD H,SET 1,(IY+d)
        .word   l_set1x       @ cd LD L,SET 1,(IX+d) // LD L,SET 1,(IY+d)
        .word   set1x         @ ce SET 1,(IX+d) // SET 1,(IY+d)
        .word   a_set1x       @ cf LD A,SET 1,(IX+d) // LD A,SET 1,(IY+d)
        .word   b_set2x       @ d0 LD B,SET 2,(IX+d) // LD B,SET 2,(IY+d)
        .word   c_set2x       @ d1 LD C,SET 2,(IX+d) // LD C,SET 2,(IY+d)
        .word   d_set2x       @ d2 LD D,SET 2,(IX+d) // LD D,SET 2,(IY+d)
        .word   e_set2x       @ d3 LD E,SET 2,(IX+d) // LD E,SET 2,(IY+d)
        .word   h_set2x       @ d4 LD H,SET 2,(IX+d) // LD H,SET 2,(IY+d)
        .word   l_set2x       @ d5 LD L,SET 2,(IX+d) // LD L,SET 2,(IY+d)
        .word   set2x         @ d6 SET 2,(IX+d) // SET 2,(IY+d)
        .word   a_set2x       @ d7 LD A,SET 2,(IX+d) // LD A,SET 2,(IY+d)
        .word   b_set3x       @ d8 LD B,SET 3,(IX+d) // LD B,SET 3,(IY+d)
        .word   c_set3x       @ d9 LD C,SET 3,(IX+d) // LD C,SET 3,(IY+d)
        .word   d_set3x       @ da LD D,SET 3,(IX+d) // LD D,SET 3,(IY+d)
        .word   e_set3x       @ db LD E,SET 3,(IX+d) // LD E,SET 3,(IY+d)
        .word   h_set3x       @ dc LD H,SET 3,(IX+d) // LD H,SET 3,(IY+d)
        .word   l_set3x       @ dd LD L,SET 3,(IX+d) // LD L,SET 3,(IY+d)
        .word   set3x         @ de SET 3,(IX+d) // SET 3,(IY+d)
        .word   a_set3x       @ df LD A,SET 3,(IX+d) // LD A,SET 3,(IY+d)
        .word   b_set4x       @ e0 LD B,SET 4,(IX+d) // LD B,SET 4,(IY+d)
        .word   c_set4x       @ e1 LD C,SET 4,(IX+d) // LD C,SET 4,(IY+d)
        .word   d_set4x       @ e2 LD D,SET 4,(IX+d) // LD D,SET 4,(IY+d)
        .word   e_set4x       @ e3 LD E,SET 4,(IX+d) // LD E,SET 4,(IY+d)
        .word   h_set4x       @ e4 LD H,SET 4,(IX+d) // LD H,SET 4,(IY+d)
        .word   l_set4x       @ e5 LD L,SET 4,(IX+d) // LD L,SET 4,(IY+d)
        .word   set4x         @ e6 SET 4,(IX+d) // SET 4,(IY+d)
        .word   a_set4x       @ e7 LD A,SET 4,(IX+d) // LD A,SET 4,(IY+d)
        .word   b_set5x       @ e8 LD B,SET 5,(IX+d) // LD B,SET 5,(IY+d)
        .word   c_set5x       @ e9 LD C,SET 5,(IX+d) // LD C,SET 5,(IY+d)
        .word   d_set5x       @ ea LD D,SET 5,(IX+d) // LD D,SET 5,(IY+d)
        .word   e_set5x       @ eb LD E,SET 5,(IX+d) // LD E,SET 5,(IY+d)
        .word   h_set5x       @ ec LD H,SET 5,(IX+d) // LD H,SET 5,(IY+d)
        .word   l_set5x       @ ed LD L,SET 5,(IX+d) // LD L,SET 5,(IY+d)
        .word   set5x         @ ee SET 5,(IX+d) // SET 5,(IY+d)
        .word   a_set5x       @ ef LD A,SET 5,(IX+d) // LD A,SET 5,(IY+d)
        .word   b_set6x       @ f0 LD B,SET 6,(IX+d) // LD B,SET 6,(IY+d)
        .word   c_set6x       @ f1 LD C,SET 6,(IX+d) // LD C,SET 6,(IY+d)
        .word   d_set6x       @ f2 LD D,SET 6,(IX+d) // LD D,SET 6,(IY+d)
        .word   e_set6x       @ f3 LD E,SET 6,(IX+d) // LD E,SET 6,(IY+d)
        .word   h_set6x       @ f4 LD H,SET 6,(IX+d) // LD H,SET 6,(IY+d)
        .word   l_set6x       @ f5 LD L,SET 6,(IX+d) // LD L,SET 6,(IY+d)
        .word   set6x         @ f6 SET 6,(IX+d) // SET 6,(IY+d)
        .word   a_set6x       @ f7 LD A,SET 6,(IX+d) // LD A,SET 6,(IY+d)
        .word   b_set7x       @ f8 LD B,SET 7,(IX+d) // LD B,SET 7,(IY+d)
        .word   c_set7x       @ f9 LD C,SET 7,(IX+d) // LD C,SET 7,(IY+d)
        .word   d_set7x       @ fa LD D,SET 7,(IX+d) // LD D,SET 7,(IY+d)
        .word   e_set7x       @ fb LD E,SET 7,(IX+d) // LD E,SET 7,(IY+d)
        .word   h_set7x       @ fc LD H,SET 7,(IX+d) // LD H,SET 7,(IY+d)
        .word   l_set7x       @ fd LD L,SET 7,(IX+d) // LD L,SET 7,(IY+d)
        .word   set7x         @ fe SET 7,(IX+d) // SET 7,(IY+d)
        .word   a_set7x       @ ff LD A,SET 7,(IX+d) // LD A,SET 7,(IY+d)

salida: ldrh    lr, [punt, #oendd]
        cmp     lr, pcff, lsr #16
        beq     exec11
        ldrd    r10, [punt, #ocounter]
        ldr     lr, [punt, #osthi]
        cmp     stlo, r10
        sbcs    lr, lr, r11
        bcc     exec1
exec11: 
      .if fast==0
        movs    lr, arvpref, lsl #24
        bne     exec1
      .endif
        str     stlo, [punt, #ost]
        uxtb    lr, arvpref, ror #8
        add     lr, lr, lsl #13
        ldr     r11, c18003
        and     lr, r11
        str     lr, [punt, #oim]
        and     arvpref, #0xffff80ff
        stm     punt, {mem, pcff, spfa, bcfb, defr, hlmp, arvpref, ixstart, iyi}
        pop     {r4-r12, lr}
        bx      lr

insth:  ldr     r11, [punt, #osthi]
        add     r11, r11, #1
        str     r11, [punt, #osthi]
        bx      lr
