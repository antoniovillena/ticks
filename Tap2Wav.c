#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef __DMC__
  #define strcasecmp stricmp
#endif
unsigned char in[0x10000], precalc[0x200000];
char *ext, filename[40];
unsigned char rem= 0, inibit= 0, channel_type= 1, mod;
FILE *fi, *fo;
int i, j, k, l, m, tlength, ind= 0;
unsigned short length, frequency= 44100;

void outbits( short val ){
  for ( m= 0; m<val; m++ ){
    precalc[ind++]= inibit ? 0x40 : 0xc0;
    if( channel_type==2 )
      precalc[ind++]= inibit ? 0x40 : 0xc0;
    else if( channel_type==6 )
      precalc[ind++]= inibit ? 0xc0 : 0x40;
  }
  if( ind>0xff000 )
    fwrite( precalc, 1, ind, fo ),
    ind= 0;
  inibit^= 1;
}

void obgen( int nor ){
  outbits( (nor+rem)/mod );
  rem= (nor+rem)%mod;
}

int main(int argc, char* argv[]){
  if( argc==1 )
    printf("\n"
    "Tap2Wav v0.01, ZX Spectrum .TAP to .WAV file converter, 7 May 2014\n\n"
    "  Tap2Wav [<frequency>] [<channel_type>] <input_file> [<output_file>]\n\n"
    "  <frequency>    Sample frequency, 44100 or 48000. Default is 44100\n"
    "  <channel_type> Possible values are: mono (default), stereo or stereoinv\n"
    "  <input_file>   Input TAP file\n"
    "  <output_file>  Output WAV file\n\n"),
    exit(0);
  while( 1 )
    if( !strcasecmp(argv[1], "mono") || !strcasecmp(argv[1], "44100") )
      ++argv, --argc;
    else if( !strcasecmp(argv[1], "stereo") )
      channel_type= 2, ++argv, --argc;
    else if( !strcasecmp(argv[1], "stereoinv") )
      channel_type= 6, ++argv, --argc;
    else if( !strcasecmp(argv[1], "48000") )
      frequency= 48000, ++argv, --argc;
    else
      break;
  mod= 7056000/frequency;
  fi= fopen(argv[1], "rb");
  if( !fi )
    printf("\nInput file not found: %s\n", argv[1]),
    exit(-1);
  fseek(fi, 0, SEEK_END);
  tlength= ftell(fi);
  fseek(fi, 0, SEEK_SET);
  if( argc==2 )
    strcpy(filename, argv[1]),
    ext= strchr(filename, '.'),
    ext[0]= 0,
    strcat(filename, ".wav");
  else if( argc==3 )
    strcpy(filename, argv[2]);
  else
    printf("\nInvalid number of parameters\n"),
    exit(-1);
  fo= fopen(filename, "wb+");
  if( !fo )
    printf("\nCannot create output file: %s\n", filename),
    exit(-1);
  memset(in, 0, 44);
  memset(precalc, 128, 0x200000);
  *(int*)in= 0x46464952;
  *(int*)(in+8)= 0x45564157;
  *(int*)(in+12)= 0x20746d66;
  *(char*)(in+16)= 0x10;
  *(char*)(in+20)= 0x01;
  *(char*)(in+22)= *(char*)(in+32)= channel_type&3;
  *(short*)(in+24)= frequency;
  *(int*)(in+28)= frequency*(channel_type&3);
  *(char*)(in+34)= 8;
  *(int*)(in+36)= 0x61746164;
  fwrite(in, 1, 44, fo);
  while ( tlength ){
    fread(&length, 1, 2, fi);
    fread(in, 1, length, fi);
    tlength-= 2+length;
    i= *in>>7&1 ? 3223 : 8063;
    while( i-- )
      obgen( 2168*2 );
    obgen( 667*2 );
    obgen( 735*2 );
    for ( i= 0; i<length; i++ )
      for( k= 0, j= in[i]; k<8; k++, j<<= 1 )
        obgen( l= 1710 << ((j & 0x80)>>7) ),
        obgen( l );
    obgen( l );
    fwrite( precalc, 1, ind, fo );
    rem= ind= 0;
    fwrite( precalc+0x100000, 1, frequency*(channel_type&3)*( *in ? 2 : 1 ), fo );
  }
  i= ftell(fo)-8;
  fseek(fo, 4, SEEK_SET);
  fwrite(&i, 4, 1, fo);
  i-= 36;
  fseek(fo, 40, SEEK_SET);
  fwrite(&i, 4, 1, fo);
  fclose(fo);
  printf("\nFile %s generated successfully\n", filename);
}