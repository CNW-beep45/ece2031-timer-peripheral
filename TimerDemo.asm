ORG 0 
Start:
  LOADI 0 
  OUT   Hex0
  OUT   Hex1

StartWait:
  IN    Switches
  AND   One 
  JZERO StartTimers
  JUMP  StartWait

StartTimers: 
  LOAD  OneMS
  OUT   TimeScale0
  LOAD  TwoMS
  OUT   TimeScale1
  LOAD  Config
  OUT   ConElap0
  OUT   ConElap1
  LOAD  Start
  OUT   Command0
  OUT   Command1

StopWhenT2Hits10:
  IN    Elap0
  OUT   Hex0
  IN    Elap1
  OUT   Hex1
  SUB   Ten
  JZERO StopTimers
  JUMP  StopWhenT2Hits10

StopTimers:
  LOAD  Stop
  OUT   Command0
  OUT   Command1
  JUMP  EndLoop:

EndLoop:
  JUMP  EndLoop

; Useful constants
Config:     DW  1 
OneMS:      DW  1000 
TwoMS:      DW  2000 
Start:      DW  1
Stop:       DW  2 
Reset:      DW  3 
One:        DW  1
Ten:        DW  10



; IO address constants
Switches:   EQU 000 
LEDs:       EQU 001 
Hex0:       EQU 004 
Hex1:       EQU 005

; Timer 1 
ConElap0:    EQU &H70
DurComp0:    EQU &H71 
TimeScale0:  EQU &H72
Command0:    EQU &H73

; Timer 2 
ConElap1:    EQU &H74 
DurComp1:    EQU &H75 
TimeScale1:  EQU &H76 
Command1:    EQU &H77 

; Timer 3 
ConElap2:    EQU &H78 
DurComp2:    EQU &H79 
TimeScale2:  EQU &H7A 
Command2:    EQU &H7B 

; Timer 4
ConElap3:    EQU &H7C 
DurComp3:    EQU &H7D 
TimeScale3:  EQU &H7E 
Command3:    EQU &H7F 

