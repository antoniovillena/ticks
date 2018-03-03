#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef WIN32
#define stricmp strcasecmp
#endif

#define RET(n)                  \
          st+= n,               \
          mp= mem[sp++],        \
          pc= mp|= mem[sp++]<<8

FILE * ft;
unsigned char * tapbuf;

unsigned int
        wavpos= 0
      , wavlen= 0
      , mues
      ;
extern unsigned int
        v
      , intr
      , tap
      ;
extern unsigned short
        pc
      , start
      , endd
      , sp
      , mp
      , t
      , u
      , ff
      , ff_
      , fa
      , fa_
      , fb
      , fb_
      , fr
      , fr_
      , romp
      ;
extern unsigned long long
        st
      , sttap
      , stint
      , counter
      ;
extern unsigned char
        a
      , c
      , b
      , e
      , d
      , l
      , h
      , a_
      , c_
      , b_
      , e_
      , d_
      , l_
      , h_
      , xl
      , xh
      , yl
      , yh
      , i
      , r
      , rs
      , prefix
      , iff
      , im
      , w
      , halted
      ;

unsigned char ear= 255;
      
extern unsigned char * mem;

long tapcycles(void){
  mues= 1;
  wavpos!=0x20000 && (ear^= 64);
  if( wavpos>0x1f000 )
    fseek( ft, wavpos-0x20000, SEEK_CUR ),
    wavlen-= wavpos,
    wavpos= 0,
    fread(tapbuf, 1, 0x20000, ft);
  while( (tapbuf[++wavpos]^ear<<1)&0x80 && wavpos<0x20000 )
    mues+= 81;  // correct value must be 79.365, adjusted to simulate contention in Alkatraz
  if( wavlen<=wavpos )
    return 0;
  else
    return mues;
}

int in(int port){
  return port&1 ? 255 : ear;
}

void out(int port, int value){
  return;
}

int f(void){
  return  ff & 168
        | ff >> 8 & 1
        | !fr << 6
        | fb >> 8 & 2
        | (fr ^ fa ^ fb ^ fb >> 8) & 16
        | (fa & -256 
            ? 154020 >> ((fr ^ fr >> 4) & 15)
            : ((fr ^ fa) & (fr ^ fb)) >> 5) & 4;
}

void setf(int a){
  fr= ~a & 64;
  ff= a|= a<<8;
  fa= 255 & (fb= a & -129 | (a&4)<<5);
}

int main (int argc, char **argv){
  mem= (unsigned char *) malloc (0x10000);
  int size= 0;
  char * output= NULL;
  FILE * fh;
  tapbuf= (unsigned char *) malloc (0x20000);
  if( argc==1 )
    printf( "Ticks v0.16 beta, a silent Z80 emulator by Antonio Villena, 1 Jan 2016\n"
            "                            Linux port by Jose Luis Sanchez, 7 Jan 2014\n\n"
            "  ticks <input_file> [-pc X] [-start X] [-end X] [-counter X] [-output <file>]\n\n"
            "  <input_file>   File between 1 and 65536 bytes with Z80 machine code\n"
            "  -tape <file>   emulates ZX tape in port $FE from a .WAV file\n"
            "  -pc X          X in hexadecimal is the initial PC value\n"
            "  -start X       X in hexadecimal is the PC condition to start the counter\n"
            "  -end X         X in hexadecimal is the PC condition to exit\n"
            "  -counter X     X in decimal is another condition to exit\n"
            "  -int X         X in decimal are number of cycles for periodic interrupts\n"
            "  -output <file> dumps the RAM content to a 64K file\n"
            "  -romprotect    disable writes between 0000 and $3fff\n\n"
            "  Default values for -pc, -start and -end are 0000 if ommited. When the program\n"
            "exits, it'll show the number of cycles between start and end trigger in decimal\n\n"),
    exit(0);
  while (argc > 1){
    if( argv[1][0] == '-' && argv[2] )
      switch (argc--, argv++[1][1]){
        case 'p':
          pc= strtol(argv[1], NULL, 16);
          break;
        case 's':
          start= strtol(argv[1], NULL, 16);
          break;
        case 'e':
          endd= strtol(argv[1], NULL, 16);
          break;
        case 'i':
          intr= strtol(argv[1], NULL, 10);
          break;
        case 'c':
          sscanf(argv[1], "%llu", &counter);
          counter || (counter= 9e18);
          break;
        case 'o':
          output= argv[1];
          break;
        case 't':
          ft= fopen(argv[1], "rb");
          if( !ft )
            printf("\nTape file not found: %s\n", argv[1]),
            exit(-1);
          fread(tapbuf, 1, 0x20000, ft);
          memcpy(&wavlen, tapbuf+4, 4);
          wavlen+= 8;
          if( *(int*) tapbuf != 0x46464952 )
            printf("\nInvalid WAV header\n"),
            exit(-1);
          if( *(int*)(tapbuf+16) != 16 )
            printf("\nInvalid subchunk size\n"),
            exit(-1);
          if( *(int*)(tapbuf+20) != 0x10001 )
            printf("\nInvalid number of channels or compression (only Mono and PCM allowed)\n"),
            exit(-1);
          if( *(int*)(tapbuf+24) != 44100 )
            printf("\nInvalid sample rate (only 44100Hz allowed)\n"),
            exit(-1);
          if( *(int*)(tapbuf+32) != 0x80001 )
            printf("\nInvalid align or bits per sample (only 8-bits samples allowed)\n"),
            exit(-1);
          if( *(int*)(tapbuf+40)+44 != wavlen )
            printf("\nInvalid header size\n"),
            exit(-1);
          wavpos= 44;
          break;
        case 'r':
          --argv;
          ++argc;
          romp= 0x4000;
          break;
        default:
          printf("\nWrong Argument: %s\n", argv[0]);
          exit(-1);
      }
    else{
      fh= fopen(argv[1], "rb");
      if( !fh )
        printf("\nFile not found: %s\n", argv[1]),
        exit(-1);
      fseek(fh, 0, SEEK_END);
      size= ftell(fh);
      rewind(fh);
      if( size>65536 && size!=65574 )
        printf("\nIncorrect length: %d\n", size),
        exit(-1);
      else if( !stricmp(strchr(argv[1], '.'), ".sna" ) && size==49179 ){
        FILE *fk= fopen("48.rom", "rb");
        if( !fk )
          printf("\nZX Spectrum ROM file not found: 48.rom\n"),
          exit(-1);
        fread(mem, 1, 16384, fk);
        fclose(fk);
        fread(&i, 1, 1, fh);
        fread(&l_, 1, 1, fh);
        fread(&h_, 1, 1, fh);
        fread(&e_, 1, 1, fh);
        fread(&d_, 1, 1, fh);
        fread(&c_, 1, 1, fh);
        fread(&b_, 1, 1, fh);
        fread(&w, 1, 1, fh);
        setf(w);
        ff_= ff;
        fr_= fr;
        fa_= fa;
        fb_= fb;
        fread(&a_, 1, 1, fh);
        fread(&l, 1, 1, fh);
        fread(&h, 1, 1, fh);
        fread(&e, 1, 1, fh);
        fread(&d, 1, 1, fh);
        fread(&c, 1, 1, fh);
        fread(&b, 1, 1, fh);
        fread(&yl, 1, 1, fh);
        fread(&yh, 1, 1, fh);
        fread(&xl, 1, 1, fh);
        fread(&xh, 1, 1, fh);
        fread(&iff, 1, 1, fh);
        iff<<= 5;
        fread(&r, 1, 1, fh);
        rs= r&0x80;
        fread(&w, 1, 1, fh);
        setf(w);
        fread(&a, 1, 1, fh);
        fread(&sp, 2, 1, fh);
        fread(&im, 1, 1, fh);
        fread(&w, 1, 1, fh);
        fread(mem+0x4000, 1, 0xc000, fh);
        RET(0);
      }
      else if( size==65574 )
        fread(mem, 1, 65536, fh),
        fread(&w, 1, 1, fh),
        u= w,
        fread(&a, 1, 1, fh),
        fread(&c, 1, 1, fh),
        fread(&b, 1, 1, fh),
        fread(&l, 1, 1, fh),
        fread(&h, 1, 1, fh),
        fread(&pc, 2, 1, fh),
        fread(&sp, 2, 1, fh),
        fread(&i, 1, 1, fh),
        fread(&r, 1, 1, fh),
        rs= r&0x80,
        fread(&e, 1, 1, fh),
        fread(&d, 1, 1, fh),
        fread(&c_, 1, 1, fh),
        fread(&b_, 1, 1, fh),
        fread(&e_, 1, 1, fh),
        fread(&d_, 1, 1, fh),
        fread(&l_, 1, 1, fh),
        fread(&h_, 1, 1, fh),
        fread(&w, 1, 1, fh),
        setf(w),
        ff_= ff,
        fr_= fr,
        fa_= fa,
        fb_= fb,
        setf(u),
        fread(&a_, 1, 1, fh),
        fread(&yl, 1, 1, fh),
        fread(&yh, 1, 1, fh),
        fread(&xl, 1, 1, fh),
        fread(&xh, 1, 1, fh),
        fread(&iff, 1, 1, fh),
        fread(&im, 1, 1, fh),
        fread(&mp, 2, 1, fh);
      else
        fread(mem, 1, size, fh);
    }
    ++argv;
    --argc;
  }
  if( size==65574 ){
    fread(&wavpos, 4, 1, fh);
    ear= wavpos<<6 | 191;
    wavpos>>= 1;
    if( wavpos && ft )
      fseek(ft, wavlen-wavpos, SEEK_SET),
      wavlen= wavpos,
      wavpos= 0,
      fread(tapbuf, 1, 0x20000, ft);
    fread(&sttap, 4, 1, fh);
    tap= sttap;
  }
  else if( ft )
    sttap= tap= tapcycles();
  fclose(fh);
  if( !size )
    printf("File not specified or zero length\n");
  stint= intr;
  execute();
  if( tap && st>sttap )
    sttap= st+( tap= tapcycles() );
  printf("%llu %04x\n", st, mem[pc+3]|mem[pc+2]<<8|mem[pc+1]<<16|mem[pc]<<24);
  if( output ){
    fh= fopen(output, "wb+");
    if( !fh )
      printf("\nCannot create or write in file: %s\n", output),
      exit(-1);
    if( !stricmp(strchr(output, '.'), ".sna" ) )
      mem[--sp]= pc>>8,
      mem[--sp]= pc,
      fwrite(&i, 1, 1, fh),
      fwrite(&l_, 1, 1, fh),
      fwrite(&h_, 1, 1, fh),
      fwrite(&e_, 1, 1, fh),
      fwrite(&d_, 1, 1, fh),
      fwrite(&c_, 1, 1, fh),
      fwrite(&b_, 1, 1, fh),
      t= f(),
      ff= ff_,
      fr= fr_,
      fa= fa_,
      fb= fb_,
      w= f(),
      fwrite(&w, 1, 1, fh),
      fwrite(&a_, 1, 1, fh),
      fwrite(&l, 1, 1, fh),
      fwrite(&h, 1, 1, fh),
      fwrite(&e, 1, 1, fh),
      fwrite(&d, 1, 1, fh),
      fwrite(&c, 1, 1, fh),
      fwrite(&b, 1, 1, fh),
      fwrite(&yl, 1, 1, fh),
      fwrite(&yh, 1, 1, fh),
      fwrite(&xl, 1, 1, fh),
      fwrite(&xh, 1, 1, fh),
      iff>>= 5,
      fwrite(&iff, 1, 1, fh),
      r= (r&127|rs),
      fwrite(&r, 1, 1, fh),
      fwrite(&t, 1, 1, fh),
      fwrite(&a, 1, 1, fh),
      fwrite(&sp, 2, 1, fh),
      fwrite(&im, 1, 1, fh),
      fwrite(&w, 1, 1, fh),
      fwrite(mem+0x4000, 1, 0xc000, fh);
    else if ( !stricmp(strchr(output, '.'), ".scr" ) )
      fwrite(mem+0x4000, 1, 0x1b00, fh);
    else{
      fwrite(mem, 1, 65536, fh);
      w= f();
      fwrite(&w, 1, 1, fh);    // 10000 F
      fwrite(&a, 1, 1, fh);    // 10001 A
      fwrite(&c, 1, 1, fh);    // 10002 C
      fwrite(&b, 1, 1, fh);    // 10003 B
      fwrite(&l, 1, 1, fh);    // 10004 L
      fwrite(&h, 1, 1, fh);    // 10005 H
      fwrite(&pc, 2, 1, fh);   // 10006 PCl
                               // 10007 PCh
      fwrite(&sp, 2, 1, fh);   // 10008 SPl
                               // 10009 SPh
      fwrite(&i, 1, 1, fh);    // 1000a I
      r= (r&127|rs);
      fwrite(&r, 1, 1, fh);    // 1000b R
      fwrite(&e, 1, 1, fh);    // 1000c E
      fwrite(&d, 1, 1, fh);    // 1000d D
      fwrite(&c_, 1, 1, fh);   // 1000e C'
      fwrite(&b_, 1, 1, fh);   // 1000f B'
      fwrite(&e_, 1, 1, fh);   // 10010 E'
      fwrite(&d_, 1, 1, fh);   // 10011 D'
      fwrite(&l_, 1, 1, fh);   // 10012 L'
      fwrite(&h_, 1, 1, fh);   // 10013 H'
      ff= ff_;
      fr= fr_;
      fa= fa_;
      fb= fb_;
      w= f();
      fwrite(&w, 1, 1, fh);    // 10014 F'
      fwrite(&a_, 1, 1, fh);   // 10015 A'
      fwrite(&yl, 1, 1, fh);   // 10016 IYl
      fwrite(&yh, 1, 1, fh);   // 10017 IYh
      fwrite(&xl, 1, 1, fh);   // 10018 IXl
      fwrite(&xh, 1, 1, fh);   // 10019 IXh
      fwrite(&iff, 1, 1, fh);  // 1001a IFF
      fwrite(&im, 1, 1, fh);   // 1001b IM
      fwrite(&mp, 2, 1, fh);   // 1001c MEMPTRl
                               // 1001d MEMPTRh
      if( tap )
        wavlen-= wavpos,
        sttap-= st;
      wavlen= (wavlen<<1) | (ear>>6&1);
      fwrite(&wavlen, 4, 1, fh);  // 1001e wavlen
      fwrite(&sttap, 4, 1, fh);   // 10022 sttap
    }
    fclose(fh);
  }
}