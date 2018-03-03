#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define RET(n)                  \
          st+= n,               \
          mp= mem[sp++],        \
          pc= mp|= mem[sp++]<<8

#define LDRIM(r)                \
          st+= 7,               \
          r= mem[pc++]

#define LDRRIM(a, b)            \
          st+= 10,              \
          b= mem[pc++],         \
          a= mem[pc++]

#define LDRP(a, b, r)           \
          st+= 7,               \
          r= mem[mp= b|a<<8],   \
          ++mp

#define LDRPI(a, b, r)          \
          st+= 15,              \
          r= mem[((mem[pc++]^128)-128+(b|a<<8))&65535]

#define LDPR(a, b, r)           \
          st+= 7,               \
          t= b|a<<8,            \
          t>=romp && (mem[t]= r), \
          mp= b+1&255 | a<<8

#define LDPRI(a, b, r)          \
          st+= 15,              \
          t= ((mem[pc++]^128)-128+(b|a<<8))&65535, \
          t>=romp && (mem[t]= r)

#define LDRR(a, b, n)           \
          st+= n,               \
          a= b

#define LDPNNRR(a, b, n)        \
          st+= n,               \
          t= mem[pc++],         \
          t|= mem[pc++]<<8,     \
          mp= t+1,              \
          t>=romp && (mem[t]= b), \
          mp>=romp && (mem[mp]= a)

#define LDPIN(a, b)             \
          st+= 15,              \
          t= mem[pc++],         \
          t= ((t^128)-128+(b|a<<8))&65535, \
          t>=romp && (mem[t]= mem[pc]), \
          pc++

#define INCW(a, b)              \
          st+= 6,               \
          ++b || a++

#define DECW(a, b)              \
          st+= 6,               \
          b-- || a--

#define INC(r)                  \
          st+= 4,               \
          ff= ff&256            \
            | (fr= r= (fa= r)+(fb= 1))

#define DEC(r)                  \
          st+= 4,               \
          ff= ff&256            \
            | (fr= r= (fa= r)+(fb= -1))

#define INCPI(a, b)             \
          st+= 19,              \
          fa= mem[t= (mem[pc++]^128)-128+(b|a<<8)], \
          ff= ff&256            \
            | (fr= fa+(fb=1)&255), \
          t>=romp && (mem[t]= fr)

#define DECPI(a, b)             \
          st+= 19,              \
          fa= mem[t= (mem[pc++]^128)-128+(b|a<<8)], \
          ff= ff&256            \
            | (fr= fa+(fb=-1)&255), \
          t>=romp && (mem[t]= fr)

#define ADDRRRR(a, b, c, d)     \
          st+= 11,              \
          v= b+d+               \
           ( a+c << 8 ),        \
          ff= ff    & 128       \
            | v>>8  & 296,      \
          fb= fb&128            \
            | (v>>8^a^c^fr^fa)&16, \
          mp= b+1+( a<<8 ),     \
          a= v>>8,              \
          b= v

#define JRCI(c)                 \
          if(c)                 \
            st+= 12,            \
            pc+= (mem[pc]^128)-127; \
          else                  \
            st+= 7,             \
            pc++

#define JRC(c)                  \
          if(c)                 \
            st+= 7,             \
            pc++;               \
          else                  \
            st+= 12,            \
            pc+= (mem[pc]^128)-127

#define LDRRPNN(a, b, n)        \
          st+= n,               \
          t= mem[pc++],         \
          b= mem[t|= mem[pc++]<<8], \
          a= mem[mp= t+1]

#define ADDISP(a, b)            \
          st+= 11,              \
          v= sp+(b|a<<8),       \
          ff= ff  &128          \
            | v>>8&296,         \
          fb= fb&128            \
            | (v>>8^sp>>8^a^fr^fa)&16, \
          mp= b+1+(a<<8),       \
          a= v>>8,              \
          b= v

#define ADD(b, n)               \
          st+= n,               \
          fr= a= (ff= (fa= a)+(fb= b))

#define ADC(b, n)               \
          st+= n,               \
          fr= a= (ff= (fa= a)+(fb= b)+(ff>>8&1))

#define SUB(b, n)               \
          st+= n,               \
          fr= a= (ff= (fa= a)+(fb= ~b)+1)

#define SBC(b, n)               \
          st+= n,               \
          fr= a= (ff= (fa= a)+(fb= ~b)+(ff>>8&1^1))

#define AND(b, n)               \
          st+= n,               \
          fa= ~(a= ff= fr= a&b),\
          fb= 0

#define XOR(b, n)               \
          st+= n,               \
          fa= 256               \
            | (ff= fr= a^= b),  \
          fb= 0

#define OR(b, n)                \
          st+= n,               \
          fa= 256               \
            | (ff= fr= a|= b),  \
          fb= 0

#define CP(b, n)                \
          st+= n,               \
          fr= (fa= a)-b,        \
          fb= ~b,               \
          ff= fr  & -41         \
            | b   &  40,        \
          fr&= 255

#define RETC(c)                 \
          if(c)                 \
            st+= 5;             \
          else                  \
            st+= 11,            \
            mp= mem[sp++],      \
            pc= mp|= mem[sp++]<<8

#define RETCI(c)                \
          if(c)                 \
            st+= 11,            \
            mp= mem[sp++],      \
            pc= mp|= mem[sp++]<<8;\
          else                  \
            st+= 5

#define PUSH(a, b)              \
          st+= 11,              \
          --sp>=romp && (mem[sp]= a), \
          --sp>=romp && (mem[sp]= b)

#define POP(a, b)               \
          st+= 10,              \
          b= mem[sp++],         \
          a= mem[sp++]

#define JPC(c)                  \
          st+= 10;              \
          if(c)                 \
            pc+= 2;             \
          else                  \
            pc= mem[pc] | mem[pc+1]<<8

#define JPCI(c)                 \
          st+= 10;              \
          if(c)                 \
            pc= mem[pc] | mem[pc+1]<<8; \
          else                  \
            pc+= 2

#define CALLC(c)                \
          if(c)                 \
            st+= 10,            \
            pc+= 2;             \
          else                  \
            st+= 17,            \
            t= pc+2,            \
            mp= pc= mem[pc] | mem[pc+1]<<8, \
            --sp>=romp && (mem[sp]= t>>8), \
            --sp>=romp && (mem[sp]= t)

#define CALLCI(c)               \
          if(c)                 \
            st+= 17,            \
            t= pc+2,            \
            mp= pc= mem[pc] | mem[pc+1]<<8, \
            --sp>=romp && (mem[sp]= t>>8), \
            --sp>=romp && (mem[sp]= t); \
          else                  \
            st+= 10,            \
            pc+= 2

#define RST(n)                  \
          st+= 11,              \
          --sp>=romp && (mem[sp]= pc>>8), \
          --sp>=romp && (mem[sp]= pc), \
          mp= pc= n

#define EXSPI(a, b)             \
          st+= 19,              \
          t= mem[sp],           \
          sp>=romp && (mem[sp]= b), \
          b= t,                 \
          t= mem[sp+1],           \
          sp+1>=romp && (mem[sp+1]= a), \
          a= t,                 \
          mp= b | a<<8

#define RLC(r)                  \
          st+= 8,               \
          ff= r*257>>7,         \
          fa= 256               \
            | (fr= r= ff),      \
          fb= 0

#define RRC(r)                  \
          st+= 8,               \
          ff=  r >> 1           \
              | ((r&1)+1 ^ 1)<<7, \
          fa= 256               \
            | (fr= r= ff),      \
          fb= 0

#define RL(r)                   \
          st+= 8,               \
          ff= r << 1            \
            | ff >> 8 & 1,      \
          fa= 256               \
            | (fr= r= ff),      \
          fb= 0

#define RR(r)                   \
          st+= 8,               \
          ff= (r*513 | ff&256)>>1, \
          fa= 256               \
            | (fr= r= ff),      \
          fb= 0

#define SLA(r)                  \
          st+= 8,               \
          ff= r<<1,             \
          fa= 256               \
            | (fr= r= ff),      \
          fb= 0

#define SRA(r)                  \
          st+= 8,               \
          ff= (r*513+128^128)>>1, \
          fa= 256               \
            | (fr= r= ff),      \
          fb= 0

#define SLL(r)                  \
          st+= 8,               \
          ff= r<<1 | 1,         \
          fa= 256               \
            | (fr= r= ff),      \
          fb= 0

#define SRL(r)                  \
          st+= 8,               \
          ff= r*513 >> 1,       \
          fa= 256               \
            | (fr= r= ff),      \
          fb= 0

#define BIT(n, r)               \
          st+= 8,               \
          ff= ff  & -256        \
            | r   &   40        \
            | (fr= r & n),      \
          fa= ~fr,              \
          fb= 0

#define BITHL(n)                \
          st+= 12,              \
          t= mem[l | h<<8],     \
          ff= ff    & -256      \
            | mp>>8 &   40      \
            | -41   & (t&= n),  \
          fa= ~(fr= t),         \
          fb= 0

#define BITI(n)                 \
          st+= 5,               \
          ff= ff    & -256      \
            | mp>>8 &   40      \
            | -41   & (w&= n),  \
          fa= ~(fr= w),         \
          fb= 0

#define RES(n, r)               \
          st+= 8,               \
          r&= n

#define RESHL(n)                \
          st+= 15,              \
          w= mem[t= l|h<<8] & n,\
          t>=romp && (mem[t]= w)

#define SET(n, r)               \
          st+= 8,               \
          r|= n

#define SETHL(n)                \
          st+= 15,              \
          w= mem[t= l|h<<8] | n,\
          t>=romp && (mem[t]= w)

#define INR(r)                  \
          st+= 12,              \
          r= in(mp= b<<8 | c),  \
          ++mp,                 \
          ff= ff & -256         \
            | (fr= r),          \
          fa= r | 256,          \
          fb= 0

#define OUTR(r)                 \
          st+= 12,              \
          out(mp= c | b<<8, r), \
          ++mp

#define SBCHLRR(a, b)           \
          st+= 15,              \
          v= l-b+(h-a<<8)-(ff>>8&1),\
          mp= l+1+(h<<8),       \
          ff= v>>8,             \
          fa= h,                \
          fb= ~a,               \
          h= ff,                \
          l= v,                 \
          fr= h|l<<8

#define ADCHLRR(a, b)           \
          st+= 15,              \
          v= l+b+(h+a<<8)+(ff>>8&1),\
          mp= l+1+(h<<8),       \
          ff= v>>8,             \
          fa= h,                \
          fb= a,                \
          h= ff,                \
          l= v,                 \
          fr= h|l<<8

unsigned int
        v
      , intr= 0
      , tap= 0
      ;
unsigned short
        pc= 0
      , start= 0
      , endd= 0
      , sp= 0
      , mp= 0
      , t= 0
      , u= 0
      , ff= 0
      , ff_= 0
      , fa= 0
      , fa_= 0
      , fb= 0
      , fb_= 0
      , fr= 0
      , fr_= 0
      , romp= 0
      ;
unsigned long long
        st= 0
      , sttap
      , stint
      , counter= 1e8
      ;
unsigned char
        a= 0
      , c= 0
      , b= 0
      , e= 0
      , d= 0
      , l= 0
      , h= 0
      , a_= 0
      , c_= 0
      , b_= 0
      , e_= 0
      , d_= 0
      , l_= 0
      , h_= 0
      , xl= 0
      , xh= 0
      , yl= 0
      , yh= 0
      , i= 0
      , r= 0
      , rs= 0
      , prefix= 0
      , iff= 0
      , im= 0
      , w= 0
      , halted= 0
      ;

unsigned char * mem;

void execute(void){
do{
  if( pc==start )
    st= 0,
    stint= intr,
    sttap= tap;
  if( intr && st>stint && !prefix ){
    stint= st+intr;
    if( iff ){
      halted && (pc++, halted= 0);
      iff= 0;
      --sp>=romp && (mem[sp]= pc>>8);
      --sp>=romp && (mem[sp]= pc);
      r++;
      switch( im ){
        case 1:
          st++;
        case 0: 
          pc= 56;
          st+= 12;
          break;
        default:
          pc= mem[t= 255 | i << 8];
          pc|= mem[++t] << 8;
          st+= 19;
      }
    }
  }
  if( tap && st>sttap )
    sttap= st+( tap= tapcycles() );
  r++;
// printf("pc=%04X, [pc]=%02X, bc=%04X, de=%04X, hl=%04X, af=%04X, ix=%04X, iy=%04X\n",
//         pc, mem[pc], c|b<<8, e|d<<8, l|h<<8, f()|a<<8, xl|xh<<8, yl|yh<<8);
  switch( mem[pc++] ){
    case 0x00: // NOP
    case 0x40: // LD B,B
    case 0x49: // LD C,C
    case 0x52: // LD D,D
    case 0x5b: // LD E,E
    case 0x64: // LD H,H
    case 0x6d: // LD L,L
    case 0x7f: // LD A,A
      st+= 4;
      prefix=0;break;
    case 0x76: // HALT
      st+= 4;
      halted= 1;
      pc--;
      prefix=0;break;
    case 0x01: // LD BC,nn
      LDRRIM(b, c);
      prefix=0;break;
    case 0x11: // LD DE,nn
      LDRRIM(d, e);
      prefix=0;break;
    case 0x21: // LD HL,nn // LD IX,nn // LD IY,nn
      if( !prefix )
        LDRRIM(h, l);
      else if( !--prefix )
        LDRRIM(xh, xl);
      else
        --prefix,
        LDRRIM(yh, yl);
      break;
    case 0x31: // LD SP,nn
      st+= 10;
      sp= mem[pc++];
      sp|= mem[pc++]<<8;
      prefix=0;break;
    case 0x02: // LD (BC),A
      LDPR(b, c, a);
      prefix=0;break;
    case 0x12: // LD (DE),A
      LDPR(d, e, a);
      prefix=0;break;
    case 0x0a: // LD A,(BC)
      LDRP(b, c, a);
      prefix=0;break;
    case 0x1a: // LD A,(DE)
      LDRP(d, e, a);
      prefix=0;break;
    case 0x22: // LD (nn),HL // LD (nn),IX // LD (nn),IY
      if( !prefix )
        LDPNNRR(h, l, 16);
      else if( !--prefix )
        LDPNNRR(xh, xl, 16);
      else
        --prefix,
        LDPNNRR(yh, yl, 16);
      break;
    case 0x32: // LD (nn),A
      st+= 13;
      t= mem[pc++];
      t|= mem[pc++]<<8;
      t>=romp && (mem[t]= a);
      mp= t+1 & 255
        | a<<8;
      prefix=0;break;
    case 0x2a: // LD HL,(nn) // LD IX,(nn) // LD IY,(nn)
      if( !prefix )
        LDRRPNN(h, l, 16);
      else if( !--prefix )
        LDRRPNN(xh, xl, 16);
      else
        --prefix,
        LDRRPNN(yh, yl, 16);
      break;
    case 0x3a: // LD A,(nn)
      st+= 13;
      mp= mem[pc++];
      a= mem[mp|= mem[pc++]<<8];
      ++mp;
      prefix=0;break;
    case 0x03: // INC BC
      INCW(b, c);
      prefix=0;break;
      break;
    case 0x13: // INC DE
      INCW(d, e);
      prefix=0;break;
    case 0x23: // INC HL // INC IX // INC IY
      if( !prefix )
        INCW(h, l);
      else if( !--prefix )
        INCW(xh, xl);
      else
        --prefix,
        INCW(yh, yl);
      break;
    case 0x33: // INC SP
      st+= 6;
      sp++;
      prefix=0;break;
    case 0x0b: // DEC BC
      DECW(b, c);
      prefix=0;break;
    case 0x1b: // DEC DE
      DECW(d, e);
      prefix=0;break;
    case 0x2b: // DEC HL // DEC IX // DEC IY
      if( !prefix )
        DECW(h, l);
      else if( !--prefix )
        DECW(xh, xl);
      else
        --prefix,
        DECW(yh, yl);
      break;
    case 0x3b: // DEC SP
      st+= 6;
      sp--;
      prefix=0;break;
    case 0x04: // INC B
      INC(b);
      prefix=0;break;
      break;
    case 0x0c: // INC C
      INC(c);
      prefix=0;break;
    case 0x14: // INC D
      INC(d);
      prefix=0;break;
    case 0x1c: // INC E
      INC(e);
      prefix=0;break;
    case 0x24: // INC H // INC IXh // INC IYh
      if( !prefix )
        INC(h);
      else if( !--prefix )
        INC(xh);
      else
        --prefix,
        INC(yh);
      break;
    case 0x2c: // INC L // INC IXl // INC IYl
      if( !prefix )
        INC(l);
      else if( !--prefix )
        INC(xl);
      else
        --prefix,
        INC(yl);
      break;
    case 0x34: // INC (HL) // INC (IX+d) // INC (IY+d)
      if( !prefix )
        st+= 11,
        fa= mem[t= l | h<<8],
        ff= ff&256
          | (fr= fa+(fb=1)&255),
        t>=romp && (mem[t]= fr);
      else if( !--prefix )
        INCPI(xh, xl);
      else
        --prefix,
        INCPI(yh, yl);
      break;
    case 0x3c: // INC A
      INC(a);
      prefix=0;break;
    case 0x05: // DEC B
      DEC(b);
      prefix=0;break;
    case 0x0d: // DEC C
      DEC(c);
      prefix=0;break;
    case 0x15: // DEC D
      DEC(d);
      prefix=0;break;
    case 0x1d: // DEC E
      DEC(e);
      prefix=0;break;
    case 0x25: // DEC H // DEC IXh // DEC IYh
      if( !prefix )
        DEC(h);
      else if( !--prefix )
        DEC(xh);
      else
        --prefix,
        DEC(yh);
      break;
    case 0x2d: // DEC L // DEC IXl // DEC IYl
      if( !prefix )
        DEC(l);
      else if( !--prefix )
        DEC(xl);
      else
        --prefix,
        DEC(yl);
      break;
    case 0x35: // DEC (HL) // DEC (IX+d) // DEC (IY+d)
      if( !prefix )
        st+= 11,
        fa= mem[t= l | h<<8],
        ff= ff&256
          | (fr= fa+(fb=-1)&255),
        t>=romp && (mem[t]= fr);
      else if( !--prefix )
        DECPI(xh, xl);
      else
        --prefix,
        DECPI(yh, yl);
      break;
    case 0x3d: // DEC A
      DEC(a);
      prefix=0;break;
    case 0x06: // LD B,n
      LDRIM(b);
      prefix=0;break;
    case 0x0e: // LD C,n
      LDRIM(c);
      prefix=0;break;
    case 0x16: // LD D,n
      LDRIM(d);
      prefix=0;break;
    case 0x1e: // LD E,n
      LDRIM(e);
      prefix=0;break;
    case 0x26: // LD H,n // LD IXh,n // LD IYh,n
      if( !prefix )
        LDRIM(h);
      else if( !--prefix )
        LDRIM(xh);
      else
        --prefix,
        LDRIM(yh);
      break;
    case 0x2e: // LD L,n // LD IXl,n // LD IYl,n
      if( !prefix )
        LDRIM(l);
      else if( !--prefix )
        LDRIM(xl);
      else
        --prefix,
        LDRIM(yl);
      break;
    case 0x36: // LD (HL),n // LD (IX+d),n // LD (IY+d),n
      if( !prefix )
        st+= 10,
        t= l|h<<8,
        t>=romp && (mem[t]= mem[pc]),
        pc++;
      else if( !--prefix )
        LDPIN(xh, xl);
      else
        --prefix,
        LDPIN(yh, yl);
      break;
    case 0x3e: // LD A,n
      LDRIM(a);
      prefix=0;break;
    case 0x07: // RLCA
      st+= 4;
      a= t= a*257>>7;
      ff= ff&215
        | t &296;
      fb= fb      &128
        | (fa^fr) & 16;
      prefix=0;break;
    case 0x0f: // RRCA
      st+= 4;
      a= t= a>>1
          | ((a&1)+1^1)<<7;
      ff= ff&215
        | t &296;
      fb= fb      &128
        | (fa^fr) & 16;
      prefix=0;break;
    case 0x17: // RLA
      st+= 4;
      a= t= a<<1
          | ff>>8 & 1;
      ff= ff&215
        | t &296;
      fb= fb      & 128
        | (fa^fr) &  16;
      prefix=0;break;
    case 0x1f: // RRA
      st+= 4;
      a= t= (a*513 | ff&256)>>1;
      ff= ff&215
        | t &296;
      fb= fb      &128
        | (fa^fr) & 16;
      prefix=0;break;
    case 0x09: // ADD HL,BC // ADD IX,BC // ADD IY,BC
      if( !prefix )
        ADDRRRR(h, l, b, c);
      else if( !--prefix )
        ADDRRRR(xh, xl, b, c);
      else
        --prefix,
        ADDRRRR(yh, yl, b, c);
      break;
    case 0x19: // ADD HL,DE // ADD IX,DE // ADD IY,DE
      if( !prefix )
        ADDRRRR(h, l, d, e);
      else if( !--prefix )
        ADDRRRR(xh, xl, d, e);
      else
        --prefix,
        ADDRRRR(yh, yl, d, e);
      break;
    case 0x29: // ADD HL,HL // ADD IX,IX // ADD IY,IY
      if( !prefix )
        ADDRRRR(h, l, h, l);
      else if( !--prefix )
        ADDRRRR(xh, xl, xh, xl);
      else
        --prefix,
        ADDRRRR(yh, yl, yh, yl);
      break;
    case 0x39: // ADD HL,SP // ADD IX,SP // ADD IY,SP
      if( !prefix )
        ADDISP(h, l);
      else if( !--prefix )
        ADDISP(xh, xl);
      else
        --prefix,
        ADDISP(yh, yl);
      break;
    case 0x18: // JR
      st+= 12;
      mp= pc+= (mem[pc]^128)-127;
      prefix=0;break;
    case 0x20: // JR NZ,s8
      JRCI(fr);
      prefix=0;break;
    case 0x28: // JR Z,s8
      JRC(fr);
      prefix=0;break;
    case 0x30: // JR NC,s8
      JRC(ff&256);
      prefix=0;break;
    case 0x38: // JR C,s8
      JRCI(ff&256);
      prefix=0;break;
    case 0x08: // EX AF,AF'
      st+= 4;
      t  =  a_;
      a_ =  a;
      a  =  t;
      t  =  ff_;
      ff_=  ff;
      ff =  t;
      t  =  fr_;
      fr_=  fr;
      fr =  t;
      t  =  fa_;
      fa_=  fa;
      fa =  t;
      t  =  fb_;
      fb_=  fb;
      fb =  t;
      prefix=0;break;
    case 0x10: // DJNZ
      if( --b )
        st+= 13,
        mp= pc+= (mem[pc]^128)-127;
      else
        st+= 8,
        pc++;
      prefix=0;break;
    case 0x27: // DAA
      st+= 4;
      t= (fr^fa^fb^fb>>8) & 16;
      u= 0;
      (a | ff&256)>153 && (u= 352);
      (a&15 | t)>9 && (u+= 6);
      fa= a|256;
      if( fb&512 )
        a-= u,
        fb= ~u;
      else
        a+= fb= u;
      ff= (fr= a)
        | u&256;
      prefix=0;break;
    case 0x2f: // CPL
      st+= 4;
      ff= ff      &-41
        | (a^=255)& 40;
      fb|= -129;
      fa=  fa & -17
        | ~fr &  16; 
      prefix=0;break;
    case 0x37: // SCF
      st+= 4;
      fb= fb      &128
        | (fr^fa) & 16;
      ff= 256
        | ff  &128
        | a   & 40;
      prefix=0;break;
    case 0x3f: // CCF
      st+= 4;
      fb= fb            &128
        | (ff>>4^fr^fa) & 16;
      ff= ~ff & 256
        | ff  & 128
        | a   &  40;
      prefix=0;break;
    case 0x41: // LD B,C
      LDRR(b, c, 4);
      prefix=0;break;
    case 0x42: // LD B,D
      LDRR(b, d, 4);
      prefix=0;break;
    case 0x43: // LD B,E
      LDRR(b, e, 4);
      prefix=0;break;
    case 0x44: // LD B,H // LD B,IXh // LD B,IYh
      if( !prefix )
        LDRR(b, h, 4);
      else if( !--prefix )
        LDRR(b, xh, 4);
      else
        --prefix,
        LDRR(b, yh, 4);
      break;
    case 0x45: // LD B,L // LD B,IXl // LD B,IYl
      if( !prefix )
        LDRR(b, l, 4);
      else if( !--prefix )
        LDRR(b, xl, 4);
      else
        --prefix,
        LDRR(b, yl, 4);
      break;
    case 0x46: // LD B,(HL) // LD B,(IX+d) // LD B,(IY+d)
      if( !prefix )
        LDRP(h, l, b);
      else if( !--prefix )
        LDRPI(xh, xl, b);
      else
        --prefix,
        LDRPI(yh, yl, b);
      break;
    case 0x47: // LD B,A
      LDRR(b, a, 4);
      prefix=0;break;
    case 0x48: // LD C,B
      LDRR(c, b, 4);
      prefix=0;break;
    case 0x4a: // LD C,D
      LDRR(c, d, 4);
      prefix=0;break;
    case 0x4b: // LD C,E
      LDRR(c, e, 4);
      prefix=0;break;
    case 0x4c: // LD C,H // LD C,IXh // LD C,IYh
      if( !prefix )
        LDRR(c, h, 4);
      else if( !--prefix )
        LDRR(c, xh, 4);
      else
        --prefix,
        LDRR(c, yh, 4);
      break;
    case 0x4d: // LD C,L // LD C,IXl // LD C,IYl
      if( !prefix )
        LDRR(c, l, 4);
      else if( !--prefix )
        LDRR(c, xl, 4);
      else
        --prefix,
        LDRR(c, yl, 4);
      break;
    case 0x4e: // LD C,(HL) // LD C,(IX+d) // LD C,(IY+d)
      if( !prefix )
        LDRP(h, l, c);
      else if( !--prefix )
        LDRPI(xh, xl, c);
      else
        --prefix,
        LDRPI(yh, yl, c);
      break;
    case 0x4f: // LD C,A
      LDRR(c, a, 4);
      prefix=0;break;
    case 0x50: // LD D,B
      LDRR(d, b, 4);
      prefix=0;break;
    case 0x51: // LD D,C
      LDRR(d, c, 4);
      prefix=0;break;
    case 0x53: // LD D,E
      LDRR(d, e, 4);
      prefix=0;break;
    case 0x54: // LD D,H // LD D,IXh // LD D,IYh
      if( !prefix )
        LDRR(d, h, 4);
      else if( !--prefix )
        LDRR(d, xh, 4);
      else
        --prefix,
        LDRR(d, yh, 4);
      break;
    case 0x55: // LD D,L // LD D,IXl // LD D,IYl
      if( !prefix )
        LDRR(d, l, 4);
      else if( !--prefix )
        LDRR(d, xl, 4);
      else
        --prefix,
        LDRR(d, yl, 4);
      break;
    case 0x56: // LD D,(HL) // LD D,(IX+d) // LD D,(IY+d)
      if( !prefix )
        LDRP(h, l, d);
      else if( !--prefix )
        LDRPI(xh, xl, d);
      else
        --prefix,
        LDRPI(yh, yl, d);
      break;
    case 0x57: // LD D,A
      LDRR(d, a, 4);
      prefix=0;break;
    case 0x58: // LD E,B
      LDRR(e, b, 4);
      prefix=0;break;
    case 0x59: // LD E,C
      LDRR(e, c, 4);
      prefix=0;break;
    case 0x5a: // LD E,D
      LDRR(e, d, 4);
      prefix=0;break;
    case 0x5c: // LD E,H // LD E,IXh // LD E,IYh
      if( !prefix )
        LDRR(e, h, 4);
      else if( !--prefix )
        LDRR(e, xh, 4);
      else
        --prefix,
        LDRR(e, yh, 4);
      break;
    case 0x5d: // LD E,L // LD E,IXl // LD E,IYl
      if( !prefix )
        LDRR(e, l, 4);
      else if( !--prefix )
        LDRR(e, xl, 4);
      else
        --prefix,
        LDRR(e, yl, 4);
      break;
    case 0x5e: // LD E,(HL) // LD E,(IX+d) // LD E,(IY+d)
      if( !prefix )
        LDRP(h, l, e);
      else if( !--prefix )
        LDRPI(xh, xl, e);
      else
        --prefix,
        LDRPI(yh, yl, e);
      break;
    case 0x5f: // LD E,A
      LDRR(e, a, 4);
      prefix=0;break;
    case 0x60: // LD H,B // LD IXh,B // LD IYh,B
      if( !prefix )
        LDRR(h, b, 4);
      else if( !--prefix )
        LDRR(xh, b, 4);
      else
        --prefix,
        LDRR(yh, b, 4);
      break;
    case 0x61: // LD H,C // LD IXh,C // LD IYh,C
      if( !prefix )
        LDRR(h, c, 4);
      else if( !--prefix )
        LDRR(xh, c, 4);
      else
        --prefix,
        LDRR(yh, c, 4);
      break;
    case 0x62: // LD H,D // LD IXh,D // LD IYh,D
      if( !prefix )
        LDRR(h, d, 4);
      else if( !--prefix )
        LDRR(xh, d, 4);
      else
        --prefix,
        LDRR(yh, d, 4);
      break;
    case 0x63: // LD H,E // LD IXh,E // LD IYh,E
      if( !prefix )
        LDRR(h, e, 4);
      else if( !--prefix )
        LDRR(xh, e, 4);
      else
        --prefix,
        LDRR(yh, e, 4);
      break;
    case 0x65: // LD H,L // LD IXh,IXl // LD IYh,IYl
      if( !prefix )
        LDRR(h, l, 4);
      else if( !--prefix )
        LDRR(xh, xl, 4);
      else
        --prefix,
        LDRR(yh, yl, 4);
      break;
    case 0x66: // LD H,(HL) // LD H,(IX+d) // LD H,(IY+d)
      if( !prefix )
        LDRP(h, l, h);
      else if( !--prefix )
        LDRPI(xh, xl, h);
      else
        --prefix,
        LDRPI(yh, yl, h);
      break;
    case 0x67: // LD H,A // LD IXh,A // LD IYh,A
      if( !prefix )
        LDRR(h, a, 4);
      else if( !--prefix )
        LDRR(xh, a, 4);
      else
        --prefix,
        LDRR(yh, a, 4);
      break;
    case 0x68: // LD L,B // LD IXl,B // LD IYl,B
      if( !prefix )
        LDRR(l, b, 4);
      else if( !--prefix )
        LDRR(xl, b, 4);
      else
        --prefix,
        LDRR(yl, b, 4);
      break;
    case 0x69: // LD L,C // LD IXl,C // LD IYl,C
      if( !prefix )
        LDRR(l, c, 4);
      else if( !--prefix )
        LDRR(xl, c, 4);
      else
        --prefix,
        LDRR(yl, c, 4);
      break;
    case 0x6a: // LD L,D // LD IXl,D // LD IYl,D
      if( !prefix )
        LDRR(l, d, 4);
      else if( !--prefix )
        LDRR(xl, d, 4);
      else
        --prefix,
        LDRR(yl, d, 4);
      break;
    case 0x6b: // LD L,E // LD IXl,E // LD IYl,E
      if( !prefix )
        LDRR(l, e, 4);
      else if( !--prefix )
        LDRR(xl, e, 4);
      else
        --prefix,
        LDRR(yl, e, 4);
      break;
    case 0x6c: // LD L,H // LD IXl,IXh // LD IYl,IYh
      if( !prefix )
        LDRR(l, h, 4);
      else if( !--prefix )
        LDRR(xl, xh, 4);
      else
        --prefix,
        LDRR(yl, yh, 4);
      break;
    case 0x6e: // LD L,(HL) // LD L,(IX+d) // LD L,(IY+d)
      if( !prefix )
        LDRP(h, l, l);
      else if( !--prefix )
        LDRPI(xh, xl, l);
      else
        --prefix,
        LDRPI(yh, yl, l);
      break;
    case 0x6f: // LD L,A // LD IXl,A // LD IYl,A
      if( !prefix )
        LDRR(l, a, 4);
      else if( !--prefix )
        LDRR(xl, a, 4);
      else
        --prefix,
        LDRR(yl, a, 4);
      break;
    case 0x70: // LD (HL),B // LD (IX+d),B // LD (IY+d),B
      if( !prefix )
        LDPR(h, l, b);
      else if( !--prefix )
        LDPRI(xh, xl, b);
      else
        --prefix,
        LDPRI(yh, yl, b);
      break;
    case 0x71: // LD (HL),C // LD (IX+d),C // LD (IY+d),C
      if( !prefix )
        LDPR(h, l, c);
      else if( !--prefix )
        LDPRI(xh, xl, c);
      else
        --prefix,
        LDPRI(yh, yl, c);
      break;
    case 0x72: // LD (HL),D // LD (IX+d),D // LD (IY+d),D
      if( !prefix )
        LDPR(h, l, d);
      else if( !--prefix )
        LDPRI(xh, xl, d);
      else
        --prefix,
        LDPRI(yh, yl, d);
      break;
    case 0x73: // LD (HL),E // LD (IX+d),E // LD (IY+d),E
      if( !prefix )
        LDPR(h, l, e);
      else if( !--prefix )
        LDPRI(xh, xl, e);
      else
        --prefix,
        LDPRI(yh, yl, e);
      break;
    case 0x74: // LD (HL),H // LD (IX+d),H // LD (IY+d),H
      if( !prefix )
        LDPR(h, l, h);
      else if( !--prefix )
        LDPRI(xh, xl, h);
      else
        --prefix,
        LDPRI(yh, yl, h);
      break;
    case 0x75: // LD (HL),L // LD (IX+d),L // LD (IY+d),L
      if( !prefix )
        LDPR(h, l, l);
      else if( !--prefix )
        LDPRI(xh, xl, l);
      else
        --prefix,
        LDPRI(yh, yl, l);
      break;
    case 0x77: // LD (HL),A // LD (IX+d),A // LD (IY+d),A
      if( !prefix )
        LDPR(h, l, a);
      else if( !--prefix )
        LDPRI(xh, xl, a);
      else
        --prefix,
        LDPRI(yh, yl, a);
      break;
    case 0x78: // LD A,B
      LDRR(a, b, 4);
      prefix=0;break;
    case 0x79: // LD A,C
      LDRR(a, c, 4);
      prefix=0;break;
    case 0x7a: // LD A,D
      LDRR(a, d, 4);
      prefix=0;break;
    case 0x7b: // LD A,E
      LDRR(a, e, 4);
      prefix=0;break;
    case 0x7c: // LD A,H // LD A,IXh // LD A,IYh
      if( !prefix )
        LDRR(a, h, 4);
      else if( !--prefix )
        LDRR(a, xh, 4);
      else
        --prefix,
        LDRR(a, yh, 4);
      break;
    case 0x7d: // LD A,L // LD A,IXl // LD A,IYl
      if( !prefix )
        LDRR(a, l, 4);
      else if( !--prefix )
        LDRR(a, xl, 4);
      else
        --prefix,
        LDRR(a, yl, 4);
      break;
    case 0x7e: // LD A,(HL) // LD A,(IX+d) // LD A,(IY+d)
      if( !prefix )
        LDRP(h, l, a);
      else if( !--prefix )
        LDRPI(xh, xl, a);
      else
        --prefix,
        LDRPI(yh, yl, a);
      break;
    case 0x80: // ADD A,B
      ADD(b, 4);
      prefix=0;break;
    case 0x81: // ADD A,C
      ADD(c, 4);
      prefix=0;break;
    case 0x82: // ADD A,D
      ADD(d, 4);
      prefix=0;break;
    case 0x83: // ADD A,E
      ADD(e, 4);
      prefix=0;break;
    case 0x84: // ADD A,H // ADD A,IXh // ADD A,IYh
      if( !prefix )
        ADD(h, 4);
      else if( !--prefix )
        ADD(xh, 4);
      else
        --prefix,
        ADD(yh, 4);
      break;
    case 0x85: // ADD A,L // ADD A,IXl // ADD A,IYl
      if( !prefix )
        ADD(l, 4);
      else if( !--prefix )
        ADD(xl, 4);
      else
        --prefix,
        ADD(yl, 4);
      break;
    case 0x86: // ADD A,(HL) // ADD A,(IX+d) // ADD A,(IY+d)
      if( !prefix )
        ADD(mem[l|h<<8], 7);
      else if( !--prefix )
        ADD(mem[((mem[pc++]^128)-128+(xl|xh<<8))&65535], 7);
      else
        --prefix,
        ADD(mem[((mem[pc++]^128)-128+(yl|yh<<8))&65535], 7);
      break;
    case 0x87: // ADD A,A
      st+= 4;
      fr= a= (ff= 2*(fa= fb= a));
      prefix=0;break;
    case 0x88: // ADC A,B
      ADC(b, 4);
      prefix=0;break;
    case 0x89: // ADC A,C
      ADC(c, 4);
      prefix=0;break;
    case 0x8a: // ADC A,D
      ADC(d, 4);
      prefix=0;break;
    case 0x8b: // ADC A,E
      ADC(e, 4);
      prefix=0;break;
    case 0x8c: // ADC A,H // ADC A,IXh // ADC A,IYh
      if( !prefix )
        ADC(h, 4);
      else if( !--prefix )
        ADC(xh, 4);
      else
        --prefix,
        ADC(yh, 4);
      break;
    case 0x8d: // ADC A,L // ADC A,IXl // ADC A,IYl
      if( !prefix )
        ADC(l, 4);
      else if( !--prefix )
        ADC(xl, 4);
      else
        --prefix,
        ADC(yl, 4);
      break;
    case 0x8e: // ADC A,(HL) // ADC A,(IX+d) // ADC A,(IY+d)
      if( !prefix )
        ADC(mem[l|h<<8], 7);
      else if( !--prefix )
        ADC(mem[((mem[pc++]^128)-128+(xl|xh<<8))&65535], 7);
      else
        --prefix,
        ADC(mem[((mem[pc++]^128)-128+(yl|yh<<8))&65535], 7);
      break;
    case 0x8f: // ADC A,A
      st+= 4;
      fr= a= (ff= 2*(fa= fb= a)+(ff>>8&1));
      prefix=0;break;
    case 0x90: // SUB B
      SUB(b, 4);
      prefix=0;break;
    case 0x91: // SUB C
      SUB(c, 4);
      prefix=0;break;
    case 0x92: // SUB D
      SUB(d, 4);
      prefix=0;break;
    case 0x93: // SUB E
      SUB(e, 4);
      prefix=0;break;
    case 0x94: // SUB H // SUB IXh // SUB IYh
      if( !prefix )
        SUB(h, 4);
      else if( !--prefix )
        SUB(xh, 4);
      else
        --prefix,
        SUB(yh, 4);
      break;
    case 0x95: // SUB L // SUB IXl // SUB IYl
      if( !prefix )
        SUB(l, 4);
      else if( !--prefix )
        SUB(xl, 4);
      else
        --prefix,
        SUB(yl, 4);
      break;
    case 0x96: // SUB (HL) // SUB (IX+d) // SUB (IY+d)
      if( !prefix )
        SUB(mem[l|h<<8], 7);
      else if( !--prefix )
        SUB(mem[((mem[pc++]^128)-128+(xl|xh<<8))&65535], 7);
      else
        --prefix,
        SUB(mem[((mem[pc++]^128)-128+(yl|yh<<8))&65535], 7);
      break;
    case 0x97: // SUB A
      st+= 4;
      fb= ~(fa= a);
      fr= a= ff= 0;
      prefix=0;break;
    case 0x98: // SBC A,B
      SBC(b, 4);
      prefix=0;break;
    case 0x99: // SBC A,C
      SBC(c, 4);
      prefix=0;break;
    case 0x9a: // SBC A,D
      SBC(d, 4);
      prefix=0;break;
    case 0x9b: // SBC A,E
      SBC(e, 4);
      prefix=0;break;
    case 0x9c: // SBC A,H // SBC A,IXh // SBC A,IYh
      if( !prefix )
        SBC(h, 4);
      else if( !--prefix )
        SBC(xh, 4);
      else
        --prefix,
        SBC(yh, 4);
      break;
    case 0x9d: // SBC A,L // SBC A,IXl // SBC A,IYl
      if( !prefix )
        SBC(l, 4);
      else if( !--prefix )
        SBC(xl, 4);
      else
        --prefix,
        SBC(yl, 4);
      break;
    case 0x9e: // SBC A,(HL) // SBC A,(IX+d) // SBC A,(IY+d)
      if( !prefix )
        SBC(mem[l|h<<8], 7);
      else if( !--prefix )
        SBC(mem[((mem[pc++]^128)-128+(xl|xh<<8))&65535], 7);
      else
        --prefix,
        SBC(mem[((mem[pc++]^128)-128+(yl|yh<<8))&65535], 7);
      break;
    case 0x9f: // SBC A,A
      st+= 4;
      fb= ~(fa= a);
      fr= a= (ff= (ff&256)/-256);
      prefix=0;break;
    case 0xa0: // AND B
      AND(b, 4);
      prefix=0;break;
    case 0xa1: // AND C
      AND(c, 4);
      prefix=0;break;
    case 0xa2: // AND D
      AND(d, 4);
      prefix=0;break;
    case 0xa3: // AND E
      AND(e, 4);
      prefix=0;break;
    case 0xa4: // AND H // AND IXh // AND IYh
      if( !prefix )
        AND(h, 4);
      else if( !--prefix )
        AND(xh, 4);
      else
        --prefix,
        AND(yh, 4);
      break;
    case 0xa5: // AND L // AND IXl // AND IYl
      if( !prefix )
        AND(l, 4);
      else if( !--prefix )
        AND(xl, 4);
      else
        --prefix,
        AND(yl, 4);
      break;
    case 0xa6: // AND (HL) // AND (IX+d) // AND (IY+d)
      if( !prefix )
        AND(mem[l|h<<8], 7);
      else if( !--prefix )
        AND(mem[((mem[pc++]^128)-128+(xl|xh<<8))&65535], 7);
      else
        --prefix,
        AND(mem[((mem[pc++]^128)-128+(yl|yh<<8))&65535], 7);
      break;
    case 0xa7: // AND A
      st+= 4;
      fa= ~(ff= fr= a);
      fb= 0;
      prefix=0;break;
    case 0xa8: // XOR B
      XOR(b, 4);
      prefix=0;break;
    case 0xa9: // XOR C
      XOR(c, 4);
      prefix=0;break;
    case 0xaa: // XOR D
      XOR(d, 4);
      prefix=0;break;
    case 0xab: // XOR E
      XOR(e, 4);
      prefix=0;break;
    case 0xac: // XOR H // XOR IXh // XOR IYh
      if( !prefix )
        XOR(h, 4);
      else if( !--prefix )
        XOR(xh, 4);
      else
        --prefix,
        XOR(yh, 4);
      break;
    case 0xad: // XOR L // XOR IXl // XOR IYl
      if( !prefix )
        XOR(l, 4);
      else if( !--prefix )
        XOR(xl, 4);
      else
        --prefix,
        XOR(yl, 4);
      break;
    case 0xae: // XOR (HL) // XOR (IX+d) // XOR (IY+d)
      if( !prefix )
        XOR(mem[l|h<<8], 7);
      else if( !--prefix )
        XOR(mem[((mem[pc++]^128)-128+(xl|xh<<8))&65535], 7);
      else
        --prefix,
        XOR(mem[((mem[pc++]^128)-128+(yl|yh<<8))&65535], 7);
      break;
    case 0xaf: // XOR A
      st+= 4;
      a= ff= fr= fb= 0;
      fa= 256;
      prefix=0;break;
    case 0xb0: // OR B
      OR(b, 4);
      prefix=0;break;
    case 0xb1: // OR C
      OR(c, 4);
      prefix=0;break;
    case 0xb2: // OR D
      OR(d, 4);
      prefix=0;break;
    case 0xb3: // OR E
      OR(e, 4);
      prefix=0;break;
    case 0xb4: // OR H // OR IXh // OR IYh
      if( !prefix )
        OR(h, 4);
      else if( !--prefix )
        OR(xh, 4);
      else
        --prefix,
        OR(yh, 4);
      break;
    case 0xb5: // OR L // OR IXl // OR IYl
      if( !prefix )
        OR(l, 4);
      else if( !--prefix )
        OR(xl, 4);
      else
        --prefix,
        OR(yl, 4);
      break;
    case 0xb6: // OR (HL) // OR (IX+d) // OR (IY+d)
      if( !prefix )
        OR(mem[l|h<<8], 7);
      else if( !--prefix )
        OR(mem[((mem[pc++]^128)-128+(xl|xh<<8))&65535], 7);
      else
        --prefix,
        OR(mem[((mem[pc++]^128)-128+(yl|yh<<8))&65535], 7);
      break;
    case 0xb7: // OR A
      st+= 4;
      fa= 256
        | (ff= fr= a);
      fb= 0;
      prefix=0;break;
    case 0xb8: // CP B
      CP(b, 4);
      prefix=0;break;
    case 0xb9: // CP C
      CP(c, 4);
      prefix=0;break;
    case 0xba: // CP D
      CP(d, 4);
      prefix=0;break;
    case 0xbb: // CP E
      CP(e, 4);
      prefix=0;break;
    case 0xbc: // CP H // CP IXh // CP IYh
      if( !prefix )
        CP(h, 4);
      else if( !--prefix )
        CP(xh, 4);
      else
        --prefix,
        CP(yh, 4);
      break;
    case 0xbd: // CP L // CP IXl // CP IYl
      if( !prefix )
        CP(l, 4);
      else if( !--prefix )
        CP(xl, 4);
      else
        --prefix,
        CP(yl, 4);
      break;
    case 0xbe: // CP (HL) // CP (IX+d) // CP (IY+d)
      if( !prefix )
        w= mem[l|h<<8],
        CP(w, 7);
      else if( !--prefix )
        w= mem[((mem[pc++]^128)-128+(xl|xh<<8))&65535],
        CP(w, 7);
      else
        --prefix,
        w= mem[((mem[pc++]^128)-128+(yl|yh<<8))&65535],
        CP(w, 7);
      break;
    case 0xbf: // CP A
      st+= 4;
      fr= 0;
      fb= ~(fa= a);
      ff= a&40;
      prefix=0;break;
    case 0xc9: // RET
      RET(10);
      prefix=0;break;
    case 0xc0: // RET NZ
      RETCI(fr);
      prefix=0;break;
    case 0xc8: // RET Z
      RETC(fr);
      prefix=0;break;
    case 0xd0: // RET NC
      RETC(ff&256);
      prefix=0;break;
    case 0xd8: // RET C
      RETCI(ff&256);
      prefix=0;break;
    case 0xe0: // RET PO
      RETC(fa&256?38505>>((fr^fr>>4)&15)&1:(fr^fa)&(fr^fb)&128);
      prefix=0;break;
    case 0xe8: // RET PE
      RETCI(fa&256?38505>>((fr^fr>>4)&15)&1:(fr^fa)&(fr^fb)&128);
      prefix=0;break;
    case 0xf0: // RET P
      RETC(ff&128);
      prefix=0;break;
    case 0xf8: // RET M
      RETCI(ff&128);
      prefix=0;break;
    case 0xc1: // POP BC
      POP(b, c);
      prefix=0;break;
    case 0xd1: // POP DE
      POP(d, e);
      prefix=0;break;
    case 0xe1: // POP HL // POP IX // POP IY
      if( !prefix )
        POP(h, l);
      else if( !--prefix )
        POP(xh, xl);
      else
        --prefix,
        POP(yh, yl);
      break;
    case 0xf1: // POP AF
      st+= 10;
      setf(mem[sp++]);
      a= mem[sp++];
      prefix=0;break;
    case 0xc5: // PUSH BC
      PUSH(b, c);
      prefix=0;break;
    case 0xd5: // PUSH DE
      PUSH(d, e);
      prefix=0;break;
    case 0xe5: // PUSH HL // PUSH IX // PUSH IY
      if( !prefix )
        PUSH(h, l);
      else if( !--prefix )
        PUSH(xh, xl);
      else
        --prefix,
        PUSH(yh, yl);
      break;
    case 0xf5: // PUSH AF
      PUSH(a, f());
      prefix=0;break;
    case 0xc3: // JP nn
      st+= 10;
      mp= pc= mem[pc] | mem[pc+1]<<8;
      prefix=0;break;
    case 0xc2: // JP NZ
      JPCI(fr);
      prefix=0;break;
    case 0xca: // JP Z
      JPC(fr);
      prefix=0;break;
    case 0xd2: // JP NC
      JPC(ff&256);
      prefix=0;break;
    case 0xda: // JP C
      JPCI(ff&256);
      prefix=0;break;
    case 0xe2: // JP PO
      JPC(fa&256?38505>>((fr^fr>>4)&15)&1:(fr^fa)&(fr^fb)&128);
      prefix=0;break;
    case 0xea: // JP PE
      JPCI(fa&256?38505>>((fr^fr>>4)&15)&1:(fr^fa)&(fr^fb)&128);
      prefix=0;break;
    case 0xf2: // JP P
      JPC(ff&128);
      prefix=0;break;
    case 0xfa: // JP M
      JPCI(ff&128);
      prefix=0;break;
    case 0xcd: // CALL nn
      st+= 17;
      t= pc+2;
      mp= pc= mem[pc] | mem[pc+1]<<8;
      --sp>=romp && (mem[sp]= t>>8);
      --sp>=romp && (mem[sp]= t);
      prefix=0;break;
    case 0xc4: // CALL NZ
      CALLCI(fr);
      prefix=0;break;
    case 0xcc: // CALL Z
      CALLC(fr);
      prefix=0;break;
    case 0xd4: // CALL NC
      CALLC(ff&256);
      prefix=0;break;
    case 0xdc: // CALL C
      CALLCI(ff&256);
      prefix=0;break;
    case 0xe4: // CALL PO
      CALLC(fa&256?38505>>((fr^fr>>4)&15)&1:(fr^fa)&(fr^fb)&128);
      prefix=0;break;
    case 0xec: // CALL PE
      CALLCI(fa&256?38505>>((fr^fr>>4)&15)&1:(fr^fa)&(fr^fb)&128);
      prefix=0;break;
    case 0xf4: // CALL P
      CALLC(ff&128);
      prefix=0;break;
    case 0xfc: // CALL M
      CALLCI(ff&128);
      prefix=0;break;
    case 0xc6: // ADD A,n
      ADD(mem[pc++], 7);
      prefix=0;break;
    case 0xce: // ADC A,n
      ADC(mem[pc++], 7);
      prefix=0;break;
    case 0xd6: // SUB n
      SUB(mem[pc++], 7);
      prefix=0;break;
    case 0xde: // SBC A,n
      SBC(mem[pc++], 7);
      prefix=0;break;
    case 0xe6: // AND n
      AND(mem[pc++], 7);
      prefix=0;break;
    case 0xee: // XOR A,n
      XOR(mem[pc++], 7);
      prefix=0;break;
    case 0xf6: // OR n
      OR(mem[pc++], 7);
      prefix=0;break;
    case 0xfe: // CP A,n
      w= mem[pc++];
      CP(w, 7);
      prefix=0;break;
    case 0xc7: // RST 0x00
      RST(0);
      prefix=0;break;
    case 0xcf: // RST 0x08
      RST(8);
      prefix=0;break;
    case 0xd7: // RST 0x10
      RST(0x10);
      prefix=0;break;
    case 0xdf: // RST 0x18
      RST(0x18);
      prefix=0;break;
    case 0xe7: // RST 0x20
      RST(0x20);
      prefix=0;break;
    case 0xef: // RST 0x28
      RST(0x28);
      prefix=0;break;
    case 0xf7: // RST 0x30
      RST(0x30);
      prefix=0;break;
    case 0xff: // RST 0x38
      RST(0x38);
      prefix=0;break;
    case 0xd3: // OUT (n),A
      st+= 11;
      out(mp= mem[pc++] | a<<8, a);
      mp= mp&65280
        | ++mp;
      prefix=0;break;
    case 0xdb: // IN A,(n)
      st+= 11;
      a= in(mp= mem[pc++] | a<<8);
      ++mp;
      prefix=0;break;
    case 0xf3: // DI
      st+= 4;
      iff= 0;
      prefix=0;break;
    case 0xfb: // EI
      st+= 4;
      iff= 0x80;
      prefix=0;break;
    case 0xeb: // EX DE,HL
      st+= 4;
      t= d;
      d= h;
      h= t;
      t= e;
      e= l;
      l= t;
      prefix=0;break;
    case 0xd9: // EXX
      st+= 4;
      t = b;
      b = b_;
      b_= t;
      t = c;
      c = c_;
      c_= t;
      t = d;
      d = d_;
      d_= t;
      t = e;
      e = e_;
      e_= t;
      t = h;
      h = h_;
      h_= t;
      t = l;
      l = l_;
      l_= t;
      prefix=0;break;
    case 0xe3: // EX (SP),HL // EX (SP),IX // EX (SP),IY
      if( !prefix )
        EXSPI(h, l);
      else if( !--prefix )
        EXSPI(xh, xl);
      else
        --prefix,
        EXSPI(yh, yl);
      break;
    case 0xe9: // JP (HL)
      st+= 4;
      if( !prefix )
        pc= l | h<<8;
      else if( !--prefix )
        pc= xl | xh<<8;
      else
        --prefix,
        pc= yl | yh<<8;
      break;
    case 0xf9: // LD SP,HL
      st+= 4;
      if( !prefix )
        sp= l | h<<8;
      else if( !--prefix )
        sp= xl | xh<<8;
      else
        --prefix,
        sp= yl | yh<<8;
      break;
    case 0xdd: // OP DD
      st+= 4;
      prefix=1;break;
    case 0xfd: // OP FD
      st+= 4;
      prefix=2;break;
    case 0xcb: // OP CB
      if( !prefix )
        switch( r++, mem[pc++] ){
          case 0x00:  RLC(b); break;                       // RLC B
          case 0x01:  RLC(c); break;                       // RLC C
          case 0x02:  RLC(d); break;                       // RLC D
          case 0x03:  RLC(e); break;                       // RLC E
          case 0x04:  RLC(h); break;                       // RLC H
          case 0x05:  RLC(l); break;                       // RLC L
          case 0x06:  st+= 7;                              // RLC (HL)
                      t= l|h<<8;
                      u= mem[t];
                      RLC(u);
                      t>=romp && (mem[t]= u); break;
          case 0x07:  RLC(a); break;                       // RLC A
          case 0x08:  RRC(b); break;                       // RRC B
          case 0x09:  RRC(c); break;                       // RRC C
          case 0x0a:  RRC(d); break;                       // RRC D
          case 0x0b:  RRC(e); break;                       // RRC E
          case 0x0c:  RRC(h); break;                       // RRC H
          case 0x0d:  RRC(l); break;                       // RRC L
          case 0x0e:  st+= 7;                              // RRC (HL)
                      t= l|h<<8;
                      u= mem[t];
                      RRC(u);
                      t>=romp && (mem[t]= u); break;
          case 0x0f:  RRC(a); break;                       // RRC A
          case 0x10:  RL(b); break;                        // RL B
          case 0x11:  RL(c); break;                        // RL C
          case 0x12:  RL(d); break;                        // RL D
          case 0x13:  RL(e); break;                        // RL E
          case 0x14:  RL(h); break;                        // RL H
          case 0x15:  RL(l); break;                        // RL L
          case 0x16:  st+= 7;                              // RL (HL)
                      t= l|h<<8;
                      u= mem[t];
                      RL(u);
                      t>=romp && (mem[t]= u); break;
          case 0x17:  RL(a); break;                        // RL A
          case 0x18:  RR(b); break;                        // RR B
          case 0x19:  RR(c); break;                        // RR C
          case 0x1a:  RR(d); break;                        // RR D
          case 0x1b:  RR(e); break;                        // RR E
          case 0x1c:  RR(h); break;                        // RR H
          case 0x1d:  RR(l); break;                        // RR L
          case 0x1e:  st+= 7;                              // RR (HL)
                      t= l|h<<8;
                      u= mem[t];
                      RR(u);
                      t>=romp && (mem[t]= u); break;
          case 0x1f:  RR(a); break;                        // RR A
          case 0x20:  SLA(b); break;                       // SLA B
          case 0x21:  SLA(c); break;                       // SLA C
          case 0x22:  SLA(d); break;                       // SLA D
          case 0x23:  SLA(e); break;                       // SLA E
          case 0x24:  SLA(h); break;                       // SLA H
          case 0x25:  SLA(l); break;                       // SLA L
          case 0x26:  st+= 7;                              // SLA (HL)
                      t= l|h<<8;
                      u= mem[t];
                      SLA(u);
                      t>=romp && (mem[t]= u); break;
          case 0x27:  SLA(a); break;                       // SLA A
          case 0x28:  SRA(b); break;                       // SRA B
          case 0x29:  SRA(c); break;                       // SRA C
          case 0x2a:  SRA(d); break;                       // SRA D
          case 0x2b:  SRA(e); break;                       // SRA E
          case 0x2c:  SRA(h); break;                       // SRA H
          case 0x2d:  SRA(l); break;                       // SRA L
          case 0x2e:  st+= 7;                              // SRA (HL)
                      t= l|h<<8;
                      u= mem[t];
                      SRA(u);
                      t>=romp && (mem[t]= u); break;
          case 0x2f:  SRA(a); break;                       // SRA A
          case 0x30:  SLL(b); break;                       // SLL B
          case 0x31:  SLL(c); break;                       // SLL C
          case 0x32:  SLL(d); break;                       // SLL D
          case 0x33:  SLL(e); break;                       // SLL E
          case 0x34:  SLL(h); break;                       // SLL H
          case 0x35:  SLL(l); break;                       // SLL L
          case 0x36:  st+= 7;                              // SLL (HL)
                      t= l|h<<8;
                      u= mem[t];
                      SLL(u);
                      t>=romp && (mem[t]= u); break;
          case 0x37:  SLL(a); break;                       // SLL A
          case 0x38:  SRL(b); break;                       // SRL B
          case 0x39:  SRL(c); break;                       // SRL C
          case 0x3a:  SRL(d); break;                       // SRL D
          case 0x3b:  SRL(e); break;                       // SRL E
          case 0x3c:  SRL(h); break;                       // SRL H
          case 0x3d:  SRL(l); break;                       // SRL L
          case 0x3e:  st+= 7;                              // SRL (HL)
                      t= l|h<<8;
                      u= mem[t];
                      SRL(u);
                      t>=romp && (mem[t]= u); break;
          case 0x3f:  SRL(a); break;                       // SRL A
          case 0x40:  BIT(1, b); break;                    // BIT 0,B
          case 0x41:  BIT(1, c); break;                    // BIT 0,C
          case 0x42:  BIT(1, d); break;                    // BIT 0,D
          case 0x43:  BIT(1, e); break;                    // BIT 0,E
          case 0x44:  BIT(1, h); break;                    // BIT 0,H
          case 0x45:  BIT(1, l); break;                    // BIT 0,L
          case 0x46:  BITHL(1); break;                     // BIT 0,(HL)
          case 0x47:  BIT(1, a); break;                    // BIT 0,A
          case 0x48:  BIT(2, b); break;                    // BIT 1,B
          case 0x49:  BIT(2, c); break;                    // BIT 1,C
          case 0x4a:  BIT(2, d); break;                    // BIT 1,D
          case 0x4b:  BIT(2, e); break;                    // BIT 1,E
          case 0x4c:  BIT(2, h); break;                    // BIT 1,H
          case 0x4d:  BIT(2, l); break;                    // BIT 1,L
          case 0x4e:  BITHL(2); break;                     // BIT 1,(HL)
          case 0x4f:  BIT(2, a); break;                    // BIT 1,A
          case 0x50:  BIT(4, b); break;                    // BIT 2,B
          case 0x51:  BIT(4, c); break;                    // BIT 2,C
          case 0x52:  BIT(4, d); break;                    // BIT 2,D
          case 0x53:  BIT(4, e); break;                    // BIT 2,E
          case 0x54:  BIT(4, h); break;                    // BIT 2,H
          case 0x55:  BIT(4, l); break;                    // BIT 2,L
          case 0x56:  BITHL(4); break;                     // BIT 2,(HL)
          case 0x57:  BIT(4, a); break;                    // BIT 2,A
          case 0x58:  BIT(8, b); break;                    // BIT 3,B
          case 0x59:  BIT(8, c); break;                    // BIT 3,C
          case 0x5a:  BIT(8, d); break;                    // BIT 3,D
          case 0x5b:  BIT(8, e); break;                    // BIT 3,E
          case 0x5c:  BIT(8, h); break;                    // BIT 3,H
          case 0x5d:  BIT(8, l); break;                    // BIT 3,L
          case 0x5e:  BITHL(8); break;                     // BIT 3,(HL)
          case 0x5f:  BIT(8, a); break;                    // BIT 3,A
          case 0x60:  BIT(16, b); break;                   // BIT 4,B
          case 0x61:  BIT(16, c); break;                   // BIT 4,C
          case 0x62:  BIT(16, d); break;                   // BIT 4,D
          case 0x63:  BIT(16, e); break;                   // BIT 4,E
          case 0x64:  BIT(16, h); break;                   // BIT 4,H
          case 0x65:  BIT(16, l); break;                   // BIT 4,L
          case 0x66:  BITHL(16); break;                    // BIT 4,(HL)
          case 0x67:  BIT(16, a); break;                   // BIT 4,A
          case 0x68:  BIT(32, b); break;                   // BIT 5,B
          case 0x69:  BIT(32, c); break;                   // BIT 5,C
          case 0x6a:  BIT(32, d); break;                   // BIT 5,D
          case 0x6b:  BIT(32, e); break;                   // BIT 5,E
          case 0x6c:  BIT(32, h); break;                   // BIT 5,H
          case 0x6d:  BIT(32, l); break;                   // BIT 5,L
          case 0x6e:  BITHL(32); break;                    // BIT 5,(HL)
          case 0x6f:  BIT(32, a); break;                   // BIT 5,A
          case 0x70:  BIT(64, b); break;                   // BIT 6,B
          case 0x71:  BIT(64, c); break;                   // BIT 6,C
          case 0x72:  BIT(64, d); break;                   // BIT 6,D
          case 0x73:  BIT(64, e); break;                   // BIT 6,E
          case 0x74:  BIT(64, h); break;                   // BIT 6,H
          case 0x75:  BIT(64, l); break;                   // BIT 6,L
          case 0x76:  BITHL(64); break;                    // BIT 6,(HL)
          case 0x77:  BIT(64, a); break;                   // BIT 6,A
          case 0x78:  BIT(128, b); break;                  // BIT 7,B
          case 0x79:  BIT(128, c); break;                  // BIT 7,C
          case 0x7a:  BIT(128, d); break;                  // BIT 7,D
          case 0x7b:  BIT(128, e); break;                  // BIT 7,E
          case 0x7c:  BIT(128, h); break;                  // BIT 7,H
          case 0x7d:  BIT(128, l); break;                  // BIT 7,L
          case 0x7e:  BITHL(128); break;                   // BIT 7,(HL)
          case 0x7f:  BIT(128, a); break;                  // BIT 7,A
          case 0x80:  RES(254, b); break;                  // RES 0,B
          case 0x81:  RES(254, c); break;                  // RES 0,C
          case 0x82:  RES(254, d); break;                  // RES 0,D
          case 0x83:  RES(254, e); break;                  // RES 0,E
          case 0x84:  RES(254, h); break;                  // RES 0,H
          case 0x85:  RES(254, l); break;                  // RES 0,L
          case 0x86:  RESHL(254); break;                   // RES 0,(HL)
          case 0x87:  RES(254, a); break;                  // RES 0,A
          case 0x88:  RES(253, b); break;                  // RES 1,B
          case 0x89:  RES(253, c); break;                  // RES 1,C
          case 0x8a:  RES(253, d); break;                  // RES 1,D
          case 0x8b:  RES(253, e); break;                  // RES 1,E
          case 0x8c:  RES(253, h); break;                  // RES 1,H
          case 0x8d:  RES(253, l); break;                  // RES 1,L
          case 0x8e:  RESHL(253); break;                   // RES 1,(HL)
          case 0x8f:  RES(253, a); break;                  // RES 1,A
          case 0x90:  RES(251, b); break;                  // RES 2,B
          case 0x91:  RES(251, c); break;                  // RES 2,C
          case 0x92:  RES(251, d); break;                  // RES 2,D
          case 0x93:  RES(251, e); break;                  // RES 2,E
          case 0x94:  RES(251, h); break;                  // RES 2,H
          case 0x95:  RES(251, l); break;                  // RES 2,L
          case 0x96:  RESHL(251); break;                   // RES 2,(HL)
          case 0x97:  RES(251, a); break;                  // RES 2,A
          case 0x98:  RES(247, b); break;                  // RES 3,B
          case 0x99:  RES(247, c); break;                  // RES 3,C
          case 0x9a:  RES(247, d); break;                  // RES 3,D
          case 0x9b:  RES(247, e); break;                  // RES 3,E
          case 0x9c:  RES(247, h); break;                  // RES 3,H
          case 0x9d:  RES(247, l); break;                  // RES 3,L
          case 0x9e:  RESHL(247); break;                   // RES 3,(HL)
          case 0x9f:  RES(247, a); break;                  // RES 3,A
          case 0xa0:  RES(239, b); break;                  // RES 4,B
          case 0xa1:  RES(239, c); break;                  // RES 4,C
          case 0xa2:  RES(239, d); break;                  // RES 4,D
          case 0xa3:  RES(239, e); break;                  // RES 4,E
          case 0xa4:  RES(239, h); break;                  // RES 4,H
          case 0xa5:  RES(239, l); break;                  // RES 4,L
          case 0xa6:  RESHL(239); break;                   // RES 4,(HL)
          case 0xa7:  RES(239, a); break;                  // RES 4,A
          case 0xa8:  RES(223, b); break;                  // RES 5,B
          case 0xa9:  RES(223, c); break;                  // RES 5,C
          case 0xaa:  RES(223, d); break;                  // RES 5,D
          case 0xab:  RES(223, e); break;                  // RES 5,E
          case 0xac:  RES(223, h); break;                  // RES 5,H
          case 0xad:  RES(223, l); break;                  // RES 5,L
          case 0xae:  RESHL(223); break;                   // RES 5,(HL)
          case 0xaf:  RES(223, a); break;                  // RES 5,A
          case 0xb0:  RES(191, b); break;                  // RES 6,B
          case 0xb1:  RES(191, c); break;                  // RES 6,C
          case 0xb2:  RES(191, d); break;                  // RES 6,D
          case 0xb3:  RES(191, e); break;                  // RES 6,E
          case 0xb4:  RES(191, h); break;                  // RES 6,H
          case 0xb5:  RES(191, l); break;                  // RES 6,L
          case 0xb6:  RESHL(191); break;                   // RES 6,(HL)
          case 0xb7:  RES(191, a); break;                  // RES 6,A
          case 0xb8:  RES(127, b); break;                  // RES 7,B
          case 0xb9:  RES(127, c); break;                  // RES 7,C
          case 0xba:  RES(127, d); break;                  // RES 7,D
          case 0xbb:  RES(127, e); break;                  // RES 7,E
          case 0xbc:  RES(127, h); break;                  // RES 7,H
          case 0xbd:  RES(127, l); break;                  // RES 7,L
          case 0xbe:  RESHL(127); break;                   // RES 7,(HL)
          case 0xbf:  RES(127, a); break;                  // RES 7,A
          case 0xc0:  SET(1, b); break;                    // SET 0,B
          case 0xc1:  SET(1, c); break;                    // SET 0,C
          case 0xc2:  SET(1, d); break;                    // SET 0,D
          case 0xc3:  SET(1, e); break;                    // SET 0,E
          case 0xc4:  SET(1, h); break;                    // SET 0,H
          case 0xc5:  SET(1, l); break;                    // SET 0,L
          case 0xc6:  SETHL(1); break;                     // SET 0,(HL)
          case 0xc7:  SET(1, a); break;                    // SET 0,A
          case 0xc8:  SET(2, b); break;                    // SET 1,B
          case 0xc9:  SET(2, c); break;                    // SET 1,C
          case 0xca:  SET(2, d); break;                    // SET 1,D
          case 0xcb:  SET(2, e); break;                    // SET 1,E
          case 0xcc:  SET(2, h); break;                    // SET 1,H
          case 0xcd:  SET(2, l); break;                    // SET 1,L
          case 0xce:  SETHL(2); break;                     // SET 1,(HL)
          case 0xcf:  SET(2, a); break;                    // SET 1,A
          case 0xd0:  SET(4, b); break;                    // SET 2,B
          case 0xd1:  SET(4, c); break;                    // SET 2,C
          case 0xd2:  SET(4, d); break;                    // SET 2,D
          case 0xd3:  SET(4, e); break;                    // SET 2,E
          case 0xd4:  SET(4, h); break;                    // SET 2,H
          case 0xd5:  SET(4, l); break;                    // SET 2,L
          case 0xd6:  SETHL(4); break;                     // SET 2,(HL)
          case 0xd7:  SET(4, a); break;                    // SET 2,A
          case 0xd8:  SET(8, b); break;                    // SET 3,B
          case 0xd9:  SET(8, c); break;                    // SET 3,C
          case 0xda:  SET(8, d); break;                    // SET 3,D
          case 0xdb:  SET(8, e); break;                    // SET 3,E
          case 0xdc:  SET(8, h); break;                    // SET 3,H
          case 0xdd:  SET(8, l); break;                    // SET 3,L
          case 0xde:  SETHL(8); break;                     // SET 3,(HL)
          case 0xdf:  SET(8, a); break;                    // SET 3,A
          case 0xe0:  SET(16, b); break;                   // SET 4,B
          case 0xe1:  SET(16, c); break;                   // SET 4,C
          case 0xe2:  SET(16, d); break;                   // SET 4,D
          case 0xe3:  SET(16, e); break;                   // SET 4,E
          case 0xe4:  SET(16, h); break;                   // SET 4,H
          case 0xe5:  SET(16, l); break;                   // SET 4,L
          case 0xe6:  SETHL(16); break;                    // SET 4,(HL)
          case 0xe7:  SET(16, a); break;                   // SET 4,A
          case 0xe8:  SET(32, b); break;                   // SET 5,B
          case 0xe9:  SET(32, c); break;                   // SET 5,C
          case 0xea:  SET(32, d); break;                   // SET 5,D
          case 0xeb:  SET(32, e); break;                   // SET 5,E
          case 0xec:  SET(32, h); break;                   // SET 5,H
          case 0xed:  SET(32, l); break;                   // SET 5,L
          case 0xee:  SETHL(32); break;                    // SET 5,(HL)
          case 0xef:  SET(32, a); break;                   // SET 5,A
          case 0xf0:  SET(64, b); break;                   // SET 6,B
          case 0xf1:  SET(64, c); break;                   // SET 6,C
          case 0xf2:  SET(64, d); break;                   // SET 6,D
          case 0xf3:  SET(64, e); break;                   // SET 6,E
          case 0xf4:  SET(64, h); break;                   // SET 6,H
          case 0xf5:  SET(64, l); break;                   // SET 6,L
          case 0xf6:  SETHL(64); break;                    // SET 6,(HL)
          case 0xf7:  SET(64, a); break;                   // SET 6,A
          case 0xf8:  SET(128, b); break;                  // SET 7,B
          case 0xf9:  SET(128, c); break;                  // SET 7,C
          case 0xfa:  SET(128, d); break;                  // SET 7,D
          case 0xfb:  SET(128, e); break;                  // SET 7,E
          case 0xfc:  SET(128, h); break;                  // SET 7,H
          case 0xfd:  SET(128, l); break;                  // SET 7,L
          case 0xfe:  SETHL(128); break;                   // SET 7,(HL)
          case 0xff:  SET(128, a); break;                  // SET 7,A
        }
      else{
        st+= 11;
        if( !--prefix )
          w= mem[mp= ((mem[pc++]^128)-128+(xl|xh<<8))];
        else
          --prefix,
          w= mem[mp= ((mem[pc++]^128)-128+(yl|yh<<8))];
        switch( mem[pc++] ){
          case 0x00: RLC(w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,RLC (IX+d) // LD B,RLC (IY+d)
          case 0x01: RLC(w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,RLC (IX+d) // LD C,RLC (IY+d)
          case 0x02: RLC(w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,RLC (IX+d) // LD D,RLC (IY+d)
          case 0x03: RLC(w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,RLC (IX+d) // LD E,RLC (IY+d)
          case 0x04: RLC(w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,RLC (IX+d) // LD H,RLC (IY+d)
          case 0x05: RLC(w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,RLC (IX+d) // LD L,RLC (IY+d)
          case 0x06: RLC(w);       mp>=romp && (mem[mp]= w); break; // RLC (IX+d) // RLC (IY+d)
          case 0x07: RLC(w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,RLC (IX+d) // LD A,RLC (IY+d)
          case 0x08: RRC(w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,RRC (IX+d) // LD B,RRC (IY+d)
          case 0x09: RRC(w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,RRC (IX+d) // LD C,RRC (IY+d)
          case 0x0a: RRC(w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,RRC (IX+d) // LD D,RRC (IY+d)
          case 0x0b: RRC(w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,RRC (IX+d) // LD E,RRC (IY+d)
          case 0x0c: RRC(w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,RRC (IX+d) // LD H,RRC (IY+d)
          case 0x0d: RRC(w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,RRC (IX+d) // LD L,RRC (IY+d)
          case 0x0e: RRC(w);       mp>=romp && (mem[mp]= w); break; // RRC (IX+d) // RRC (IY+d)
          case 0x0f: RRC(w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,RRC (IX+d) // LD A,RRC (IY+d)
          case 0x10: RL(w);  b= w; mp>=romp && (mem[mp]= w); break; // LD B,RL (IX+d) // LD B,RL (IY+d)
          case 0x11: RL(w);  c= w; mp>=romp && (mem[mp]= w); break; // LD C,RL (IX+d) // LD C,RL (IY+d)
          case 0x12: RL(w);  d= w; mp>=romp && (mem[mp]= w); break; // LD D,RL (IX+d) // LD D,RL (IY+d)
          case 0x13: RL(w);  e= w; mp>=romp && (mem[mp]= w); break; // LD E,RL (IX+d) // LD E,RL (IY+d)
          case 0x14: RL(w);  h= w; mp>=romp && (mem[mp]= w); break; // LD H,RL (IX+d) // LD H,RL (IY+d)
          case 0x15: RL(w);  l= w; mp>=romp && (mem[mp]= w); break; // LD L,RL (IX+d) // LD L,RL (IY+d)
          case 0x16: RL(w);        mp>=romp && (mem[mp]= w); break; // RL (IX+d) // RL (IY+d)
          case 0x17: RL(w);  a= w; mp>=romp && (mem[mp]= w); break; // LD A,RL (IX+d) // LD A,RL (IY+d)
          case 0x18: RR(w);  b= w; mp>=romp && (mem[mp]= w); break; // LD B,RR (IX+d) // LD B,RR (IY+d)
          case 0x19: RR(w);  c= w; mp>=romp && (mem[mp]= w); break; // LD C,RR (IX+d) // LD C,RR (IY+d)
          case 0x1a: RR(w);  d= w; mp>=romp && (mem[mp]= w); break; // LD D,RR (IX+d) // LD D,RR (IY+d)
          case 0x1b: RR(w);  e= w; mp>=romp && (mem[mp]= w); break; // LD E,RR (IX+d) // LD E,RR (IY+d)
          case 0x1c: RR(w);  h= w; mp>=romp && (mem[mp]= w); break; // LD H,RR (IX+d) // LD H,RR (IY+d)
          case 0x1d: RR(w);  l= w; mp>=romp && (mem[mp]= w); break; // LD L,RR (IX+d) // LD L,RR (IY+d)
          case 0x1e: RR(w);        mp>=romp && (mem[mp]= w); break; // RR (IX+d) // RR (IY+d)
          case 0x1f: RR(w);  a= w; mp>=romp && (mem[mp]= w); break; // LD A,RR (IX+d) // LD A,RR (IY+d)
          case 0x20: SLA(w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,SLA (IX+d) // LD B,SLA (IY+d)
          case 0x21: SLA(w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,SLA (IX+d) // LD C,SLA (IY+d)
          case 0x22: SLA(w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,SLA (IX+d) // LD D,SLA (IY+d)
          case 0x23: SLA(w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,SLA (IX+d) // LD E,SLA (IY+d)
          case 0x24: SLA(w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,SLA (IX+d) // LD H,SLA (IY+d)
          case 0x25: SLA(w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,SLA (IX+d) // LD L,SLA (IY+d)
          case 0x26: SLA(w);       mp>=romp && (mem[mp]= w); break; // SLA (IX+d) // SLA (IY+d)
          case 0x27: SLA(w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,SLA (IX+d) // LD A,SLA (IY+d)
          case 0x28: SRA(w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,SRA (IX+d) // LD B,SRA (IY+d)
          case 0x29: SRA(w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,SRA (IX+d) // LD C,SRA (IY+d)
          case 0x2a: SRA(w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,SRA (IX+d) // LD D,SRA (IY+d)
          case 0x2b: SRA(w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,SRA (IX+d) // LD E,SRA (IY+d)
          case 0x2c: SRA(w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,SRA (IX+d) // LD H,SRA (IY+d)
          case 0x2d: SRA(w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,SRA (IX+d) // LD L,SRA (IY+d)
          case 0x2e: SRA(w);       mp>=romp && (mem[mp]= w); break; // SRA (IX+d) // SRA (IY+d)
          case 0x2f: SRA(w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,SRA (IX+d) // LD A,SRA (IY+d)
          case 0x30: SLL(w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,SLL (IX+d) // LD B,SLL (IY+d)
          case 0x31: SLL(w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,SLL (IX+d) // LD C,SLL (IY+d)
          case 0x32: SLL(w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,SLL (IX+d) // LD D,SLL (IY+d)
          case 0x33: SLL(w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,SLL (IX+d) // LD E,SLL (IY+d)
          case 0x34: SLL(w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,SLL (IX+d) // LD H,SLL (IY+d)
          case 0x35: SLL(w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,SLL (IX+d) // LD L,SLL (IY+d)
          case 0x36: SLL(w);       mp>=romp && (mem[mp]= w); break; // SLL (IX+d) // SLL (IY+d)
          case 0x37: SLL(w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,SLL (IX+d) // LD A,SLL (IY+d)
          case 0x38: SRL(w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,SRL (IX+d) // LD B,SRL (IY+d)
          case 0x39: SRL(w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,SRL (IX+d) // LD C,SRL (IY+d)
          case 0x3a: SRL(w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,SRL (IX+d) // LD D,SRL (IY+d)
          case 0x3b: SRL(w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,SRL (IX+d) // LD E,SRL (IY+d)
          case 0x3c: SRL(w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,SRL (IX+d) // LD H,SRL (IY+d)
          case 0x3d: SRL(w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,SRL (IX+d) // LD L,SRL (IY+d)
          case 0x3e: SRL(w);       mp>=romp && (mem[mp]= w); break; // SRL (IX+d) // SRL (IY+d)
          case 0x3f: SRL(w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,SRL (IX+d) // LD A,SRL (IY+d)
          case 0x40: case 0x41: case 0x42: case 0x43:      // BIT 0,(IX+d) // BIT 0,(IY+d)
          case 0x44: case 0x45: case 0x46: case 0x47:
                     BITI(1); break;
          case 0x48: case 0x49: case 0x4a: case 0x4b:      // BIT 1,(IX+d) // BIT 1,(IY+d)
          case 0x4c: case 0x4d: case 0x4e: case 0x4f:
                     BITI(2); break;
          case 0x50: case 0x51: case 0x52: case 0x53:      // BIT 2,(IX+d) // BIT 2,(IY+d)
          case 0x54: case 0x55: case 0x56: case 0x57:
                     BITI(4); break;
          case 0x58: case 0x59: case 0x5a: case 0x5b:      // BIT 3,(IX+d) // BIT 3,(IY+d)
          case 0x5c: case 0x5d: case 0x5e: case 0x5f:
                     BITI(8); break;
          case 0x60: case 0x61: case 0x62: case 0x63:      // BIT 4,(IX+d) // BIT 4,(IY+d)
          case 0x64: case 0x65: case 0x66: case 0x67:
                     BITI(16); break;
          case 0x68: case 0x69: case 0x6a: case 0x6b:      // BIT 5,(IX+d) // BIT 5,(IY+d)
          case 0x6c: case 0x6d: case 0x6e: case 0x6f:
                     BITI(32); break;
          case 0x70: case 0x71: case 0x72: case 0x73:      // BIT 6,(IX+d) // BIT 6,(IY+d)
          case 0x74: case 0x75: case 0x76: case 0x77:
                     BITI(64); break;
          case 0x78: case 0x79: case 0x7a: case 0x7b:      // BIT 7,(IX+d) // BIT 7,(IY+d)
          case 0x7c: case 0x7d: case 0x7e: case 0x7f:
                     BITI(128); break;
          case 0x80: RES(254, w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,RES 0,(IX+d) // LD B,RES 0,(IY+d)
          case 0x81: RES(254, w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,RES 0,(IX+d) // LD C,RES 0,(IY+d)
          case 0x82: RES(254, w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,RES 0,(IX+d) // LD D,RES 0,(IY+d)
          case 0x83: RES(254, w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,RES 0,(IX+d) // LD E,RES 0,(IY+d)
          case 0x84: RES(254, w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,RES 0,(IX+d) // LD H,RES 0,(IY+d)
          case 0x85: RES(254, w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,RES 0,(IX+d) // LD L,RES 0,(IY+d)
          case 0x86: RES(254, w);       mp>=romp && (mem[mp]= w); break; // RES 0,(IX+d) // RES 0,(IY+d)
          case 0x87: RES(254, w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,RES 0,(IX+d) // LD A,RES 0,(IY+d)
          case 0x88: RES(253, w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,RES 1,(IX+d) // LD B,RES 1,(IY+d)
          case 0x89: RES(253, w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,RES 1,(IX+d) // LD C,RES 1,(IY+d)
          case 0x8a: RES(253, w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,RES 1,(IX+d) // LD D,RES 1,(IY+d)
          case 0x8b: RES(253, w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,RES 1,(IX+d) // LD E,RES 1,(IY+d)
          case 0x8c: RES(253, w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,RES 1,(IX+d) // LD H,RES 1,(IY+d)
          case 0x8d: RES(253, w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,RES 1,(IX+d) // LD L,RES 1,(IY+d)
          case 0x8e: RES(253, w);       mp>=romp && (mem[mp]= w); break; // RES 1,(IX+d) // RES 1,(IY+d)
          case 0x8f: RES(253, w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,RES 1,(IX+d) // LD A,RES 1,(IY+d)
          case 0x90: RES(251, w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,RES 2,(IX+d) // LD B,RES 2,(IY+d)
          case 0x91: RES(251, w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,RES 2,(IX+d) // LD C,RES 2,(IY+d)
          case 0x92: RES(251, w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,RES 2,(IX+d) // LD D,RES 2,(IY+d)
          case 0x93: RES(251, w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,RES 2,(IX+d) // LD E,RES 2,(IY+d)
          case 0x94: RES(251, w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,RES 2,(IX+d) // LD H,RES 2,(IY+d)
          case 0x95: RES(251, w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,RES 2,(IX+d) // LD L,RES 2,(IY+d)
          case 0x96: RES(251, w);       mp>=romp && (mem[mp]= w); break; // RES 2,(IX+d) // RES 2,(IY+d)
          case 0x97: RES(251, w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,RES 2,(IX+d) // LD A,RES 2,(IY+d)
          case 0x98: RES(247, w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,RES 3,(IX+d) // LD B,RES 3,(IY+d)
          case 0x99: RES(247, w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,RES 3,(IX+d) // LD C,RES 3,(IY+d)
          case 0x9a: RES(247, w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,RES 3,(IX+d) // LD D,RES 3,(IY+d)
          case 0x9b: RES(247, w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,RES 3,(IX+d) // LD E,RES 3,(IY+d)
          case 0x9c: RES(247, w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,RES 3,(IX+d) // LD H,RES 3,(IY+d)
          case 0x9d: RES(247, w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,RES 3,(IX+d) // LD L,RES 3,(IY+d)
          case 0x9e: RES(247, w);       mp>=romp && (mem[mp]= w); break; // RES 3,(IX+d) // RES 3,(IY+d)
          case 0x9f: RES(247, w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,RES 3,(IX+d) // LD A,RES 3,(IY+d)
          case 0xa0: RES(239, w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,RES 4,(IX+d) // LD B,RES 4,(IY+d)
          case 0xa1: RES(239, w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,RES 4,(IX+d) // LD C,RES 4,(IY+d)
          case 0xa2: RES(239, w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,RES 4,(IX+d) // LD D,RES 4,(IY+d)
          case 0xa3: RES(239, w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,RES 4,(IX+d) // LD E,RES 4,(IY+d)
          case 0xa4: RES(239, w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,RES 4,(IX+d) // LD H,RES 4,(IY+d)
          case 0xa5: RES(239, w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,RES 4,(IX+d) // LD L,RES 4,(IY+d)
          case 0xa6: RES(239, w);       mp>=romp && (mem[mp]= w); break; // RES 4,(IX+d) // RES 4,(IY+d)
          case 0xa7: RES(239, w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,RES 4,(IX+d) // LD A,RES 4,(IY+d)
          case 0xa8: RES(223, w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,RES 5,(IX+d) // LD B,RES 5,(IY+d)
          case 0xa9: RES(223, w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,RES 5,(IX+d) // LD C,RES 5,(IY+d)
          case 0xaa: RES(223, w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,RES 5,(IX+d) // LD D,RES 5,(IY+d)
          case 0xab: RES(223, w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,RES 5,(IX+d) // LD E,RES 5,(IY+d)
          case 0xac: RES(223, w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,RES 5,(IX+d) // LD H,RES 5,(IY+d)
          case 0xad: RES(223, w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,RES 5,(IX+d) // LD L,RES 5,(IY+d)
          case 0xae: RES(223, w);       mp>=romp && (mem[mp]= w); break; // RES 5,(IX+d) // RES 5,(IY+d)
          case 0xaf: RES(223, w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,RES 5,(IX+d) // LD A,RES 5,(IY+d)
          case 0xb0: RES(191, w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,RES 6,(IX+d) // LD B,RES 6,(IY+d)
          case 0xb1: RES(191, w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,RES 6,(IX+d) // LD C,RES 6,(IY+d)
          case 0xb2: RES(191, w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,RES 6,(IX+d) // LD D,RES 6,(IY+d)
          case 0xb3: RES(191, w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,RES 6,(IX+d) // LD E,RES 6,(IY+d)
          case 0xb4: RES(191, w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,RES 6,(IX+d) // LD H,RES 6,(IY+d)
          case 0xb5: RES(191, w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,RES 6,(IX+d) // LD L,RES 6,(IY+d)
          case 0xb6: RES(191, w);       mp>=romp && (mem[mp]= w); break; // RES 6,(IX+d) // RES 6,(IY+d)
          case 0xb7: RES(191, w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,RES 6,(IX+d) // LD A,RES 6,(IY+d)
          case 0xb8: RES(127, w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,RES 7,(IX+d) // LD B,RES 7,(IY+d)
          case 0xb9: RES(127, w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,RES 7,(IX+d) // LD C,RES 7,(IY+d)
          case 0xba: RES(127, w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,RES 7,(IX+d) // LD D,RES 7,(IY+d)
          case 0xbb: RES(127, w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,RES 7,(IX+d) // LD E,RES 7,(IY+d)
          case 0xbc: RES(127, w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,RES 7,(IX+d) // LD H,RES 7,(IY+d)
          case 0xbd: RES(127, w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,RES 7,(IX+d) // LD L,RES 7,(IY+d)
          case 0xbe: RES(127, w);       mp>=romp && (mem[mp]= w); break; // RES 7,(IX+d) // RES 7,(IY+d)
          case 0xbf: RES(127, w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,RES 7,(IX+d) // LD A,RES 7,(IY+d)
          case 0xc0: SET(1, w);   b= w; mp>=romp && (mem[mp]= w); break; // LD B,SET 0,(IX+d) // LD B,SET 0,(IY+d)
          case 0xc1: SET(1, w);   c= w; mp>=romp && (mem[mp]= w); break; // LD C,SET 0,(IX+d) // LD C,SET 0,(IY+d)
          case 0xc2: SET(1, w);   d= w; mp>=romp && (mem[mp]= w); break; // LD D,SET 0,(IX+d) // LD D,SET 0,(IY+d)
          case 0xc3: SET(1, w);   e= w; mp>=romp && (mem[mp]= w); break; // LD E,SET 0,(IX+d) // LD E,SET 0,(IY+d)
          case 0xc4: SET(1, w);   h= w; mp>=romp && (mem[mp]= w); break; // LD H,SET 0,(IX+d) // LD H,SET 0,(IY+d)
          case 0xc5: SET(1, w);   l= w; mp>=romp && (mem[mp]= w); break; // LD L,SET 0,(IX+d) // LD L,SET 0,(IY+d)
          case 0xc6: SET(1, w);         mp>=romp && (mem[mp]= w); break; // SET 0,(IX+d) // SET 0,(IY+d)
          case 0xc7: SET(1, w);   a= w; mp>=romp && (mem[mp]= w); break; // LD A,SET 0,(IX+d) // LD A,SET 0,(IY+d)
          case 0xc8: SET(2, w);   b= w; mp>=romp && (mem[mp]= w); break; // LD B,SET 1,(IX+d) // LD B,SET 1,(IY+d)
          case 0xc9: SET(2, w);   c= w; mp>=romp && (mem[mp]= w); break; // LD C,SET 1,(IX+d) // LD C,SET 1,(IY+d)
          case 0xca: SET(2, w);   d= w; mp>=romp && (mem[mp]= w); break; // LD D,SET 1,(IX+d) // LD D,SET 1,(IY+d)
          case 0xcb: SET(2, w);   e= w; mp>=romp && (mem[mp]= w); break; // LD E,SET 1,(IX+d) // LD E,SET 1,(IY+d)
          case 0xcc: SET(2, w);   h= w; mp>=romp && (mem[mp]= w); break; // LD H,SET 1,(IX+d) // LD H,SET 1,(IY+d)
          case 0xcd: SET(2, w);   l= w; mp>=romp && (mem[mp]= w); break; // LD L,SET 1,(IX+d) // LD L,SET 1,(IY+d)
          case 0xce: SET(2, w);         mp>=romp && (mem[mp]= w); break; // SET 1,(IX+d) // SET 1,(IY+d)
          case 0xcf: SET(2, w);   a= w; mp>=romp && (mem[mp]= w); break; // LD A,SET 1,(IX+d) // LD A,SET 1,(IY+d)
          case 0xd0: SET(4, w);   b= w; mp>=romp && (mem[mp]= w); break; // LD B,SET 2,(IX+d) // LD B,SET 2,(IY+d)
          case 0xd1: SET(4, w);   c= w; mp>=romp && (mem[mp]= w); break; // LD C,SET 2,(IX+d) // LD C,SET 2,(IY+d)
          case 0xd2: SET(4, w);   d= w; mp>=romp && (mem[mp]= w); break; // LD D,SET 2,(IX+d) // LD D,SET 2,(IY+d)
          case 0xd3: SET(4, w);   e= w; mp>=romp && (mem[mp]= w); break; // LD E,SET 2,(IX+d) // LD E,SET 2,(IY+d)
          case 0xd4: SET(4, w);   h= w; mp>=romp && (mem[mp]= w); break; // LD H,SET 2,(IX+d) // LD H,SET 2,(IY+d)
          case 0xd5: SET(4, w);   l= w; mp>=romp && (mem[mp]= w); break; // LD L,SET 2,(IX+d) // LD L,SET 2,(IY+d)
          case 0xd6: SET(4, w);         mp>=romp && (mem[mp]= w); break; // SET 2,(IX+d) // SET 2,(IY+d)
          case 0xd7: SET(4, w);   a= w; mp>=romp && (mem[mp]= w); break; // LD A,SET 2,(IX+d) // LD A,SET 2,(IY+d)
          case 0xd8: SET(8, w);   b= w; mp>=romp && (mem[mp]= w); break; // LD B,SET 3,(IX+d) // LD B,SET 3,(IY+d)
          case 0xd9: SET(8, w);   c= w; mp>=romp && (mem[mp]= w); break; // LD C,SET 3,(IX+d) // LD C,SET 3,(IY+d)
          case 0xda: SET(8, w);   d= w; mp>=romp && (mem[mp]= w); break; // LD D,SET 3,(IX+d) // LD D,SET 3,(IY+d)
          case 0xdb: SET(8, w);   e= w; mp>=romp && (mem[mp]= w); break; // LD E,SET 3,(IX+d) // LD E,SET 3,(IY+d)
          case 0xdc: SET(8, w);   h= w; mp>=romp && (mem[mp]= w); break; // LD H,SET 3,(IX+d) // LD H,SET 3,(IY+d)
          case 0xdd: SET(8, w);   l= w; mp>=romp && (mem[mp]= w); break; // LD L,SET 3,(IX+d) // LD L,SET 3,(IY+d)
          case 0xde: SET(8, w);         mp>=romp && (mem[mp]= w); break; // SET 3,(IX+d) // SET 3,(IY+d)
          case 0xdf: SET(8, w);   a= w; mp>=romp && (mem[mp]= w); break; // LD A,SET 3,(IX+d) // LD A,SET 3,(IY+d)
          case 0xe0: SET(16, w);  b= w; mp>=romp && (mem[mp]= w); break; // LD B,SET 4,(IX+d) // LD B,SET 4,(IY+d)
          case 0xe1: SET(16, w);  c= w; mp>=romp && (mem[mp]= w); break; // LD C,SET 4,(IX+d) // LD C,SET 4,(IY+d)
          case 0xe2: SET(16, w);  d= w; mp>=romp && (mem[mp]= w); break; // LD D,SET 4,(IX+d) // LD D,SET 4,(IY+d)
          case 0xe3: SET(16, w);  e= w; mp>=romp && (mem[mp]= w); break; // LD E,SET 4,(IX+d) // LD E,SET 4,(IY+d)
          case 0xe4: SET(16, w);  h= w; mp>=romp && (mem[mp]= w); break; // LD H,SET 4,(IX+d) // LD H,SET 4,(IY+d)
          case 0xe5: SET(16, w);  l= w; mp>=romp && (mem[mp]= w); break; // LD L,SET 4,(IX+d) // LD L,SET 4,(IY+d)
          case 0xe6: SET(16, w);        mp>=romp && (mem[mp]= w); break; // SET 4,(IX+d) // SET 4,(IY+d)
          case 0xe7: SET(16, w);  a= w; mp>=romp && (mem[mp]= w); break; // LD A,SET 4,(IX+d) // LD A,SET 4,(IY+d)
          case 0xe8: SET(32, w);  b= w; mp>=romp && (mem[mp]= w); break; // LD B,SET 5,(IX+d) // LD B,SET 5,(IY+d)
          case 0xe9: SET(32, w);  c= w; mp>=romp && (mem[mp]= w); break; // LD C,SET 5,(IX+d) // LD C,SET 5,(IY+d)
          case 0xea: SET(32, w);  d= w; mp>=romp && (mem[mp]= w); break; // LD D,SET 5,(IX+d) // LD D,SET 5,(IY+d)
          case 0xeb: SET(32, w);  e= w; mp>=romp && (mem[mp]= w); break; // LD E,SET 5,(IX+d) // LD E,SET 5,(IY+d)
          case 0xec: SET(32, w);  h= w; mp>=romp && (mem[mp]= w); break; // LD H,SET 5,(IX+d) // LD H,SET 5,(IY+d)
          case 0xed: SET(32, w);  l= w; mp>=romp && (mem[mp]= w); break; // LD L,SET 5,(IX+d) // LD L,SET 5,(IY+d)
          case 0xee: SET(32, w);        mp>=romp && (mem[mp]= w); break; // SET 5,(IX+d) // SET 5,(IY+d)
          case 0xef: SET(32, w);  a= w; mp>=romp && (mem[mp]= w); break; // LD A,SET 5,(IX+d) // LD A,SET 5,(IY+d)
          case 0xf0: SET(64, w);  b= w; mp>=romp && (mem[mp]= w); break; // LD B,SET 6,(IX+d) // LD B,SET 6,(IY+d)
          case 0xf1: SET(64, w);  c= w; mp>=romp && (mem[mp]= w); break; // LD C,SET 6,(IX+d) // LD C,SET 6,(IY+d)
          case 0xf2: SET(64, w);  d= w; mp>=romp && (mem[mp]= w); break; // LD D,SET 6,(IX+d) // LD D,SET 6,(IY+d)
          case 0xf3: SET(64, w);  e= w; mp>=romp && (mem[mp]= w); break; // LD E,SET 6,(IX+d) // LD E,SET 6,(IY+d)
          case 0xf4: SET(64, w);  h= w; mp>=romp && (mem[mp]= w); break; // LD H,SET 6,(IX+d) // LD H,SET 6,(IY+d)
          case 0xf5: SET(64, w);  l= w; mp>=romp && (mem[mp]= w); break; // LD L,SET 6,(IX+d) // LD L,SET 6,(IY+d)
          case 0xf6: SET(64, w);        mp>=romp && (mem[mp]= w); break; // SET 6,(IX+d) // SET 6,(IY+d)
          case 0xf7: SET(64, w);  a= w; mp>=romp && (mem[mp]= w); break; // LD A,SET 6,(IX+d) // LD A,SET 6,(IY+d)
          case 0xf8: SET(128, w); b= w; mp>=romp && (mem[mp]= w); break; // LD B,SET 7,(IX+d) // LD B,SET 7,(IY+d)
          case 0xf9: SET(128, w); c= w; mp>=romp && (mem[mp]= w); break; // LD C,SET 7,(IX+d) // LD C,SET 7,(IY+d)
          case 0xfa: SET(128, w); d= w; mp>=romp && (mem[mp]= w); break; // LD D,SET 7,(IX+d) // LD D,SET 7,(IY+d)
          case 0xfb: SET(128, w); e= w; mp>=romp && (mem[mp]= w); break; // LD E,SET 7,(IX+d) // LD E,SET 7,(IY+d)
          case 0xfc: SET(128, w); h= w; mp>=romp && (mem[mp]= w); break; // LD H,SET 7,(IX+d) // LD H,SET 7,(IY+d)
          case 0xfd: SET(128, w); l= w; mp>=romp && (mem[mp]= w); break; // LD L,SET 7,(IX+d) // LD L,SET 7,(IY+d)
          case 0xfe: SET(128, w);       mp>=romp && (mem[mp]= w); break; // SET 7,(IX+d) // SET 7,(IY+d)
          case 0xff: SET(128, w); a= w; mp>=romp && (mem[mp]= w); break; // LD A,SET 7,(IX+d) // LD A,SET 7,(IY+d)
        }
      }
      break;
    case 0xed: // OP ED
      r++;
      switch( mem[pc++] ){
        case 0x00: case 0x01: case 0x02: case 0x03:        // NOP
        case 0x04: case 0x05: case 0x06: case 0x07:
        case 0x08: case 0x09: case 0x0a: case 0x0b:
        case 0x0c: case 0x0d: case 0x0e: case 0x0f:
        case 0x10: case 0x11: case 0x12: case 0x13:
        case 0x14: case 0x15: case 0x16: case 0x17:
        case 0x18: case 0x19: case 0x1a: case 0x1b:
        case 0x1c: case 0x1d: case 0x1e: case 0x1f:
        case 0x20: case 0x21: case 0x22: case 0x23:
        case 0x24: case 0x25: case 0x26: case 0x27:
        case 0x28: case 0x29: case 0x2a: case 0x2b:
        case 0x2c: case 0x2d: case 0x2e: case 0x2f:
        case 0x30: case 0x31: case 0x32: case 0x33:
        case 0x34: case 0x35: case 0x36: case 0x37:
        case 0x38: case 0x39: case 0x3a: case 0x3b:
        case 0x3c: case 0x3d: case 0x3e: case 0x3f:
        case 0x77: case 0x7f:
        case 0x80: case 0x81: case 0x82: case 0x83:
        case 0x84: case 0x85: case 0x86: case 0x87:
        case 0x88: case 0x89: case 0x8a: case 0x8b:
        case 0x8c: case 0x8d: case 0x8e: case 0x8f:
        case 0x90: case 0x91: case 0x92: case 0x93:
        case 0x94: case 0x95: case 0x96: case 0x97:
        case 0x98: case 0x99: case 0x9a: case 0x9b:
        case 0x9c: case 0x9d: case 0x9e: case 0x9f:
        case 0xa4: case 0xa5: case 0xa6: case 0xa7:
        case 0xac: case 0xad: case 0xae: case 0xaf:
        case 0xb4: case 0xb5: case 0xb6: case 0xb7:
        case 0xbc: case 0xbd: case 0xbe: case 0xbf:
        case 0xc0: case 0xc1: case 0xc2: case 0xc3:
        case 0xc4: case 0xc5: case 0xc6: case 0xc7:
        case 0xc8: case 0xc9: case 0xca: case 0xcb:
        case 0xcc: case 0xcd: case 0xce: case 0xcf:
        case 0xd0: case 0xd1: case 0xd2: case 0xd3:
        case 0xd4: case 0xd5: case 0xd6: case 0xd7:
        case 0xd8: case 0xd9: case 0xda: case 0xdb:
        case 0xdc: case 0xdd: case 0xde: case 0xdf:
        case 0xe0: case 0xe1: case 0xe2: case 0xe3:
        case 0xe4: case 0xe5: case 0xe6: case 0xe7:
        case 0xe8: case 0xe9: case 0xea: case 0xeb:
        case 0xec: case 0xed: case 0xee: case 0xef:
        case 0xf0: case 0xf1: case 0xf2: case 0xf3:
        case 0xf4: case 0xf5: case 0xf6: case 0xf7:
        case 0xf8: case 0xf9: case 0xfa: case 0xfb:
        case 0xfc: case 0xfd: case 0xfe: case 0xff:
          st+= 8; break;
        case 0x40: INR(b); break;                          // IN B,(C)
        case 0x48: INR(c); break;                          // IN C,(C)
        case 0x50: INR(d); break;                          // IN D,(C)
        case 0x58: INR(e); break;                          // IN E,(C)
        case 0x60: INR(h); break;                          // IN H,(C)
        case 0x68: INR(l); break;                          // IN L,(C)
        case 0x70: INR(t); break;                          // IN X,(C)
        case 0x78: INR(a); break;                          // IN A,(C)
        case 0x41: OUTR(b); break;                         // OUT (C),B
        case 0x49: OUTR(c); break;                         // OUT (C),C
        case 0x51: OUTR(d); break;                         // OUT (C),D
        case 0x59: OUTR(e); break;                         // OUT (C),E
        case 0x61: OUTR(h); break;                         // OUT (C),H
        case 0x69: OUTR(l); break;                         // OUT (C),L
        case 0x71: OUTR(0); break;                         // OUT (C),X
        case 0x79: OUTR(a); break;                         // OUT (C),A
        case 0x42: SBCHLRR(b, c); break;                   // SBC HL,BC
        case 0x52: SBCHLRR(d, e); break;                   // SBC HL,DE
        case 0x62: SBCHLRR(h, l); break;                   // SBC HL,HL
        case 0x72: st+= 15;                                // SBC HL,SP
                   v= (mp= l|h<<8)-sp-(ff>>8&1);
                   ++mp;
                   ff= v>>8;
                   fa= h;
                   fb= ~sp>>8;
                   h= ff;
                   l= v;
                   fr= h | l<<8; break;
        case 0x4a: ADCHLRR(b, c); break;                   // ADC HL,BC
        case 0x5a: ADCHLRR(d, e); break;                   // ADC HL,DE
        case 0x6a: ADCHLRR(h, l); break;                   // ADC HL,HL
        case 0x7a: st+= 15;                                // ADC HL,SP
                   v= (mp= l|h<<8)+sp+(ff>>8&1);
                   ++mp;
                   ff= v>>8;
                   fa= h;
                   fb= sp>>8;
                   h= ff;
                   l= v;
                   fr= h | l<<8; break;
        case 0x43: LDPNNRR(b, c, 20); break;               // LD (NN),BC
        case 0x53: LDPNNRR(d, e, 20); break;               // LD (NN),DE
        case 0x63: LDPNNRR(h, l, 20); break;               // LD (NN),HL
        case 0x73: st+= 20;                                // LD (NN),SP
                   mp= mem[pc++];
                   mp|= mem[pc++]<<8;
                   mp>=romp && (mem[mp]= sp);
                   ++mp>=romp && (mem[mp]= sp>>8); break;
        case 0x4b: LDRRPNN(b, c, 20); break;               // LD BC,(NN)
        case 0x5b: LDRRPNN(d, e, 20); break;               // LD DE,(NN)
        case 0x6b: LDRRPNN(h, l, 20); break;               // LD HL,(NN)
        case 0x7b: st+= 20;                                // LD SP,(NN)
                   t= mem[pc++];
                   sp= mem[t|= mem[pc++]<<8];
                   sp|= mem[mp= t+1] << 8; break;
        case 0x44: case 0x4c: case 0x54: case 0x5c:        // NEG
        case 0x64: case 0x6c: case 0x74: case 0x7c:
                   st+= 8;
                   fr= a= (ff= (fb= ~a)+1);
                   fa= 0; break;
        case 0x45: case 0x4d: case 0x55: case 0x5d:        // RETI // RETN
        case 0x65: case 0x6d: case 0x75: case 0x7d:
                   RET(14); break;
        case 0x46: case 0x4e: case 0x66: case 0x6e:        // IM 0
                   st+= 8; im= 0; break;
        case 0x56: case 0x76:                              // IM 1
                   st+= 8; im= 1; break;
        case 0x5e: case 0x7e:                              // IM 2
                   st+= 8; im= 2; break;
        case 0x47: LDRR(i, a, 9); break;                   // LD I,A
        case 0x4f: LDRR(r, a, 9); rs= r&0x80; break;       // LD R,A
        case 0x57: st+= 9;                                 // LD A,I
                   ff=  ff&-256
                      | (a= i);
                   fr= !!a;
                   fa= fb= iff; break;
        case 0x5f: st+= 9;                                 // LD A,R
                   ff=  ff&-256
                      | (a= (r&127|rs));
                   fr= !!a;
                   fa= fb= iff; break;
        case 0x67: st+= 18;                                // RRD
                   t= mem[mp= l|h<<8]
                    | a<<8;
                   a= a &240
                    | t & 15;
                   ff=  ff&-256
                      | (fr= a);
                   fa= a|256;
                   fb= 0;
                   mp++>=romp && (mem[mp-1]= t>>4); break;
        case 0x6f: st+= 18;                                // RLD
                   t= mem[mp= l|h<<8]<<4
                    | a&15;
                   a= a &240
                    | t>>8;
                   ff=  ff&-256
                      | (fr= a);
                   fa= a|256;
                   fb= 0;
                   mp++>=romp && (mem[mp-1]= t); break;
        case 0xa0: st+= 16;                                // LDI
                   t= mem[l | h<<8];
                   (e|d<<8)>=romp && (mem[e | d<<8]= t);
                   ++l || h++;
                   ++e || d++;
                   c-- || b--;
                   fr && (fr= 1);
                   t+= a;
                   ff=  ff    & -41
                      | t     &   8
                      | t<<4  &  32;
                   fa= 0;
                   b|c && (fa= 128);
                   fb= fa; break;
        case 0xa8: st+= 16;                                // LDD
                   t= mem[l | h<<8];
                   (e|d<<8)>=romp && (mem[e | d<<8]= t);
                   l-- || h--;
                   e-- || d--;
                   c-- || b--;
                   fr && (fr= 1);
                   t+= a;
                   ff=  ff    & -41
                      | t     &   8
                      | t<<4  &  32;
                   fa= 0;
                   b|c && (fa= 128);
                   fb= fa; break;
        case 0xb0: st+= 16;                                // LDIR
                   t= mem[l | h<<8];
                   (e|d<<8)>=romp && (mem[e | d<<8]= t);
                   ++l || h++;
                   ++e || d++;
                   c-- || b--;
                   fr && (fr= 1);
                   t+= a;
                   ff=  ff    & -41
                      | t     &   8
                      | t<<4  &  32;
                   fa= 0;
                   b|c && ( fa= 128,
                            st+= 5,
                            mp= --pc,
                            --pc);
                   fb= fa; break;
        case 0xb8: st+= 16;                                // LDDR
                   t= mem[l | h<<8];
                   (e|d<<8)>=romp && (mem[e | d<<8]= t);
                   l-- || h--;
                   e-- || d--;
                   c-- || b--;
                   fr && (fr= 1);
                   t+= a;
                   ff=  ff    & -41
                      | t     &   8
                      | t<<4  &  32;
                   fa= 0;
                   b|c && ( fa= 128,
                            st+= 5,
                            mp= --pc,
                            --pc);
                   fb= fa; break;
        case 0xa1: st+= 16;                                // CPI
                   w= a-(t= mem[l|h<<8]);
                   ++l || h++;
                   c-- || b--;
                   ++mp;
                   fr=  w & 127
                      | w>>7;
                   fb= ~(t|128);
                   fa= a&127;
                   b|c && ( fa|= 128,
                            fb|= 128);
                   ff=  ff  & -256
                      | w   &  -41;
                  (w^t^a) & 16 && w--;
                  ff|= w<<4 & 32
                     | w    &  8; break;
        case 0xa9: st+= 16;                                // CPD
                   w= a-(t= mem[l|h<<8]);
                   l-- || h--;
                   c-- || b--;
                   --mp;
                   fr=  w & 127
                      | w>>7;
                   fb= ~(t|128);
                   fa= a&127;
                   b|c && ( fa|= 128,
                            fb|= 128);
                   ff=  ff  & -256
                      | w   &  -41;
                  (w^t^a) & 16 && w--;
                  ff|= w<<4 & 32
                     | w    &  8; break;
        case 0xb1: st+= 16;                                // CPIR
                   w= a-(t= mem[l|h<<8]);
                   ++l || h++;
                   c-- || b--;
                   ++mp;
                   fr=  w & 127
                      | w>>7;
                   fb= ~(t|128);
                   fa= a&127;
                   b|c && ( fa|= 128,
                            fb|= 128,
                            w && (st+= 5, mp=--pc, --pc));
                   ff=  ff  & -256
                      | w   &  -41;
                  (w^t^a) & 16 && w--;
                  ff|= w<<4 & 32
                     | w    &  8; break;
        case 0xb9: st+= 16;                                // CPDR
                   w= a-(t= mem[l|h<<8]);
                   l-- || h--;
                   c-- || b--;
                   --mp;
                   fr=  w & 127
                      | w>>7;
                   fb= ~(t|128);
                   fa= a&127;
                   b|c && ( fa|= 128,
                            fb|= 128,
                            w && (st+= 5, mp=--pc, --pc));
                   ff=  ff  & -256
                      | w   &  -41;
                  (w^t^a) & 16 && w--;
                  ff|= w<<4 & 32
                     | w    &  8; break;
        case 0xa2: st+= 16;                                // INI
                   t= in(mp= c | b<<8);
                   (l|h<<8)>=romp && (mem[l | h<<8]= t);
                   ++l || h++;
                   ++mp;
                   u= t+(c+1&255);
                   --b;
                   fb= u&7^b;
                   ff= b | (u&= 256);
                   fa= (fr= b)^128;
                   fb=  (4928640>>((fb^fb>>4)&15)^b)&128
                      | u>>4
                      | (t&128)<<2; break;
        case 0xaa: st+= 16;                                // IND
                   t= in(mp= c | b<<8);
                   (l|h<<8)>=romp && (mem[l | h<<8]= t);
                   l-- || h--;
                   --mp;
                   u= t+(c-1&255);
                   --b;
                   fb= u&7^b;
                   ff= b | (u&= 256);
                   fa= (fr= b)^128;
                   fb=  (4928640>>((fb^fb>>4)&15)^b)&128
                      | u>>4
                      | (t&128)<<2; break;
        case 0xb2: st+= 16;                                // INIR
                   t= in(mp= c | b<<8);
                   (l|h<<8)>=romp && (mem[l | h<<8]= t);
                   ++l || h++;
                   ++mp;
                   u= t+(c+1&255);
                   --b && (st+= 5, mp= --pc, --pc);
                   fb= u&7^b;
                   ff= b | (u&= 256);
                   fa= (fr= b)^128;
                   fb=  (4928640>>((fb^fb>>4)&15)^b)&128
                      | u>>4
                      | (t&128)<<2; break;
        case 0xba: st+= 16;                                // INDR
                   t= in(mp= c | b<<8);
                   (l|h<<8)>=romp && (mem[l | h<<8]= t);
                   l-- || h--;
                   --mp;
                   u= t+(c-1&255);
                   --b && (st+= 5, mp= --pc, --pc);
                   fb= u&7^b;
                   ff= b | (u&= 256);
                   fa= (fr= b)^128;
                   fb=  (4928640>>((fb^fb>>4)&15)^b)&128
                      | u>>4
                      | (t&128)<<2; break;
        case 0xa3: st+= 16;                                // OUTI
                   --b;
                   out( mp= c | b<<8,
                        t= mem[l | h<<8]);
                   ++mp;
                   ++l || h++;
                   u= t+l;
                   fb= u&7^b;
                   ff= b | (u&= 256);
                   fa= (fr= b)^128;
                   fb=  (4928640>>((fb^fb>>4)&15)^b)&128
                      | u>>4
                      | (t&128)<<2; break;
        case 0xab: st+= 16;                                // OUTD
                   --b;
                   out( mp= c | b<<8,
                        t= mem[l | h<<8]);
                   --mp;
                   l-- || h--;
                   u= t+l;
                   fb= u&7^b;
                   ff= b | (u&= 256);
                   fa= (fr= b)^128;
                   fb=  (4928640>>((fb^fb>>4)&15)^b)&128
                      | u>>4
                      | (t&128)<<2; break;
        case 0xb3: st+= 16;                                // OTIR
                   --b;
                   out( mp= c | b<<8,
                        t= mem[l | h<<8]);
                   ++mp;
                   ++l || h++;
                   u= t+l;
                   b && (st+= 5, mp= --pc, --pc);
                   fb= u&7^b;
                   ff= b | (u&= 256);
                   fa= (fr= b)^128;
                   fb=  (4928640>>((fb^fb>>4)&15)^b)&128
                      | u>>4
                      | (t&128)<<2; break;
        case 0xbb: st+= 16;                                // OTDR
                   --b;
                   out( mp= c | b<<8,
                        t= mem[l | h<<8]);
                   --mp;
                   l-- || h--;
                   u= t+l;
                   b && (st+= 5, mp= --pc, --pc);
                   fb= u&7^b;
                   ff= b | (u&= 256);
                   fa= (fr= b)^128;
                   fb=  (4928640>>((fb^fb>>4)&15)^b)&128
                      | u>>4
                      | (t&128)<<2; break;
      }
      prefix=0;//break;
  }
} while ( pc != endd && st < counter || prefix );
}
