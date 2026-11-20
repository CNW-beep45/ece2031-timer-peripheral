;   SPECIFICATION FROM PROJECT DOCUMENT
; 
;   TIM  Mode       Planned Behavior                 Check result
;   0    ONE-SHOT   runs for SW7..SW0 seconds        LED9 turns on when it expires
;   1    PERIODIC   repeats every 250 ms             LED0 toggles every period
;   2    PERIODIC   repeats every 1 s                LED2 toggles every period
;   3    STOPWATCH  measures total elapsed time      Hex0 shows elapsed seconds (decimal)
;
; How to use:
;   1. Set SW7..SW0 to the one-shot duration in seconds (binary, 0 to 255).
;   2. Flip SW9 on. All four timers start together.
;      SW7..SW0 are read at the moment SW9 turns on.
;   3. Flip SW9 off to stop all four timers (the displays freeze).
;      Flip SW9 on again to restart from zero with a new duration.
;
; Extra: Hex1 shows the one-shot ELAPSED seconds (hex), so you can watch it
; count up to the duration. A duration of 0 turns LED9 on right away.
;
; Timescale choices (timescale = milliseconds per tick):
;   Timer 0: 1000 ms per tick, so DURATION = seconds from the switches
;   Timer 1: 1 ms per tick, DURATION = 250
;   Timer 2: 1 ms per tick, DURATION = 1000
;   Timer 3: 1000 ms per tick, so ELAPSED = seconds

ORG 0

Init:
	LOADI  0
	OUT    LEDs
	OUT    Hex0
	OUT    Hex1

	; Timer 0: one-shot, 1s/tick
	LOADI  ModeOneShot
	OUT    T0_Config
	LOADI  MsPerSecond
	OUT    T0_Timescale

	; Timer 1: periodic, 250ms period
	LOADI  ModePeriodic
	OUT    T1_Config
	LOADI  1
	OUT    T1_Timescale
	LOADI  250
	OUT    T1_Duration

	; Timer 2: periodic, 1s period
	LOADI  ModePeriodic
	OUT    T2_Config
	LOADI  1
	OUT    T2_Timescale
	LOADI  1000
	OUT    T2_Duration

	; Timer 3: stopwatch, 1s per tick
	LOADI  ModeStopwatch
	OUT    T3_Config
	LOADI  MsPerSecond
	OUT    T3_Timescale

; Wait for SW9 to be flipped on
WaitOff:
	IN     Switches
	AND    Bit9
	JNZ    WaitOff

WaitOn:
	IN     Switches
	AND    Bit9
	JZERO  WaitOn

; SW9 on
StartAll:
	LOADI  CmdReset      
	OUT    T0_Command
	OUT    T1_Command
	OUT    T2_Command
	OUT    T3_Command

	IN     Switches
	AND    LowByte       ; SW7-SW0 = one-shot duration in seconds
	STORE  Duration
	OUT    T0_Duration   ; 0 val ignored

	LOADI  CmdStart
	OUT    T1_Command
	OUT    T2_Command
	OUT    T3_Command
	LOAD   Duration
	JZERO  MainLoop      ; 0 duration - dont start one-shot
	LOADI  CmdStart
	OUT    T0_Command

MainLoop:
	IN     Switches      ; stop when SW9 turned off
	AND    Bit9
	JZERO  StopAll

	IN     T1_Periods
	AND    Bit0
	STORE  LedVal

	IN     T2_Periods
	AND    Bit0
	SHIFT  2
	OR     LedVal
	STORE  LedVal

	IN     T0_Periods
	JNZ    OneShotDone
	LOAD   Duration
	JNZ    ShowLeds

OneShotDone:
	LOAD   LedVal
	OR     Bit9
	STORE  LedVal

ShowLeds:
	LOAD   LedVal
	OUT    LEDs

	IN     T0_Elapsed
	OUT    Hex1

	IN     T3_Elapsed
	CALL   ToBCD
	OUT    Hex0

	JUMP   MainLoop

StopAll:
	LOADI  CmdStop
	OUT    T0_Command
	OUT    T1_Command
	OUT    T2_Command
	OUT    T3_Command
	JUMP   WaitOn

; ToBCD converts AC 0-65535 to 4 BCD digits in AC so val displays decimal
ToBCD:
	STORE  BinVal
	LOADI  0
	STORE  BcdVal

BcdHigh:                 ; 32768 to 65535 look negative to SCOMP: subtract
	LOAD   BinVal        ; 10000 is unsigned wrap until val is positive
	JPOS   BcdWrap
	JZERO  BcdWrap
	SUB    D10000
	STORE  BinVal
	JUMP   BcdHigh

BcdWrap:
	LOAD   BinVal
	SUB    D10000
	JNEG   BcdThou
	STORE  BinVal
	JUMP   BcdWrap

BcdThou:                 ; thousands
	LOAD   BinVal
	SUB    D1000
	JNEG   BcdHund
	STORE  BinVal
	LOAD   BcdVal
	ADD    Bcd1000
	STORE  BcdVal
	JUMP   BcdThou

BcdHund:                 ; hundreds
	LOAD   BinVal
	SUB    D100
	JNEG   BcdTens
	STORE  BinVal
	LOAD   BcdVal
	ADD    Bcd100
	STORE  BcdVal
	JUMP   BcdHund

BcdTens:                 ; tens
	LOAD   BinVal
	SUB    D10
	JNEG   BcdOnes
	STORE  BinVal
	LOAD   BcdVal
	ADD    Bcd10
	STORE  BcdVal
	JUMP   BcdTens

BcdOnes:                 ; ones
	LOAD   BcdVal
	ADD    BinVal
	RETURN

; Variables
Duration:  DW 0          ; one-shot duration seconds
LedVal:    DW 0          ; LED pattern
BinVal:    DW 0          ; ToBCD working val
BcdVal:    DW 0          ; ToBCD result

; Constants
Bit0:      DW &B0000000001
Bit9:      DW &B1000000000
LowByte:   DW &H00FF
D10000:    DW 10000
D1000:     DW 1000
D100:      DW 100
D10:       DW 10
Bcd1000:   DW &H1000
Bcd100:    DW &H0100
Bcd10:     DW &H0010

; Timer peripheral
ModeStopwatch: EQU 1     ; CONFIG 01
ModeOneShot:   EQU 2     ; CONFIG 10
ModePeriodic:  EQU 3     ; CONFIG 11
CmdStart:      EQU 1     ; COMMAND 01
CmdStop:       EQU 2     ; COMMAND 10
CmdReset:      EQU 3     ; COMMAND 11
MsPerSecond:   EQU 1000  ; TIMESCALE for 1s/tick

; I/O
Switches:      EQU &H000
LEDs:          EQU &H001
Hex0:          EQU &H004
Hex1:          EQU &H005

T0_Config:     EQU &H070
T0_Elapsed:    EQU &H070
T0_Duration:   EQU &H071
T0_Periods:    EQU &H071
T0_Timescale:  EQU &H072
T0_Command:    EQU &H073

T1_Config:     EQU &H074
T1_Elapsed:    EQU &H074
T1_Duration:   EQU &H075
T1_Periods:    EQU &H075
T1_Timescale:  EQU &H076
T1_Command:    EQU &H077

T2_Config:     EQU &H078
T2_Elapsed:    EQU &H078
T2_Duration:   EQU &H079
T2_Periods:    EQU &H079
T2_Timescale:  EQU &H07A
T2_Command:    EQU &H07B

T3_Config:     EQU &H07C
T3_Elapsed:    EQU &H07C
T3_Duration:   EQU &H07D
T3_Periods:    EQU &H07D
T3_Timescale:  EQU &H07E
T3_Command:    EQU &H07F
