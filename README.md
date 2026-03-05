# DOS TSR Debug Viewer

## Description
DOS TSR Debug Viewer is a terminate-and-stay-resident (TSR) program for DOS. It shows an information table on the top of any running application. It helps you to control CPU registers, flags, and stack contents.

## Features

- Triple Buffering: Debug Viewer based on triple-buffering mechanics to save and restore the original screen content under and above the Debug Viewer`s frame. Save buffer stores actual screen condition under the frame; Draw buffer stores current frame condition; current screen image is stored in the Video memory (VM). 

- Real-time Control: You can view current state of the registers, Flags, and Stack.

- Hotkey Trigger: You can trigger the Debug Viewer with key combinations: Ctrl+1 to open the frame & Ctrl+2 to close the frame and return to previous screen condition.

- Pure Assembly: Debug Viewer is written entirely in TASM (Turbo Assembler) to reach maximal performance and total control of the memory.

## Installation
Debug Viewer can be used on DOS only, however you can install DOSBox virtual machine to use program on other OS.

### How to buid:
Download the files or just clone the repository:
- git clone https://github.com/9kazz/task3_int

Then assembly the program:
- tasm /la main.asm
- tlink /t main.obj
- main.com

## Usage example:

                     INFORMATION         
            ╔═══════════════════════════╗
            ║    REGS   | FLAGS | STACK ║
            ║---------------------------║
            ║ ax = 000A | c = 1 | 0001<-║
            ║ bx = 0230 | p = 0 | 0002  ║
            ║ cx = FF01 | a = 0 | 1300  ║
            ║ dx = 1000 | z = 1 | 00D1  ║
            ║ si = 0021 | s = 1 | 0000  ║
            ║ di = 0D10 | t = 0 | 34F0  ║
            ║ bp = DF78 | i = 0 | FFFF  ║
            ║ sp = DAA0 | d = 1 | 0000  ║
            ║ ds = 89AF | o = 0 | 0000  ║
            ║ es = B800 |       | DAA1  ║
            ║ ss = 0100 |       | 97F0  ║
            ║ ip = 0777 |       | 0123  ║
            ║ cs = 12A0 |       | 0002  ║
            ╚═══════════════════════════╝