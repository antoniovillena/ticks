Basically it is a Z80 processor emulator that does not show anything on the screen or read anything on the keyboard, simply executes instructions and counts the time that has elapsed.

It's called ticks, and for now these are the parameters that it accepts:

ticks <input_file> [-pc xxxx] [-start xxxx] [-end xxxx] [-output <file>]

The input file is mandatory, must occupy between 1 and 65536 bytes and contains the binary code that will be stored in memory. The memory is all RAM and unpaged.

-pc xxxx. It is to tell you what the first instruction to execute will be. It must go in hexadecimal and if we omit this parameter by default, the instruction 0000 is executed, the equivalent to a RESET.

-start xxxx. This is where the chronometer will start, or will be reset, when the PC reaches this value, also in hexadecimal. If the execution does not pass through this point, the start of the execution will be taken as the starting point.

-end xxxx. When the PC reaches this value (in hexadecimal) the execution will be stopped and the program will be exited, showing the number of cycles that have passed since the chronometer was started.

-output <file>. Snapshot file with all 64K memory and cpu state (registers).
