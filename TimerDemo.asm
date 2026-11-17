; Timer peripheral test: one-shot mode on timer 0
; Turn on switch 0 to start a 5 second one-shot timer. The hex display shows
; ELAPSED (1, 2, 3, 4, 5), then the program stops when the timer expires.
; Press KEY0 to reset and run it again.

ORG 0

Start:
	LOADI  0010            ; debug: show 0 on the hex display at start
	OUT    Hex0
	LOADI  2            ; mode 10 = one-shot
	OUT    T0_Config
	LOADI  10            ; expire after 5 ticks
	OUT    T0_Duration
	LOADI  100         ; 1000 ms per tick, so one tick = 1 second
	OUT    T0_Timescale

WaitSwitch:
	IN     Switches     ; wait here until switch 0 is turned on
	AND    Bit0
	JZERO  WaitSwitch

	LOADI  0
	OUT    Hex0
	LOADI  3            ; RESET (timer is stopped, so it is accepted)
	OUT    T0_Command
	LOADI  1            ; START
	OUT    T0_Command

Wait:
	IN     T0_Elapsed   ; show the tick count on the hex display
	OUT    Hex0
	IN     T0_Periods   ; becomes 1 when the one-shot expires
	JZERO  Wait         ; not expired yet, keep polling

Done:
	IN     T0_Elapsed   ; ELAPSED holds at DURATION (5) after expiry
	OUT    Hex0
	IN     T0_Periods   ; PERIODS = 1: the timer reached its duration
	OUT    Hex1
	JUMP   Done         ; stop here

; Useful values
Bit0:          DW &B0000000001

; I/O addresses
Switches:      EQU &H000
Hex0:          EQU &H004
Hex1:          EQU &H005
T0_Config:     EQU &H070    ; write: mode      read: ELAPSED
T0_Elapsed:    EQU &H070
T0_Duration:   EQU &H071    ; write: duration  read: PERIODS
T0_Periods:    EQU &H071
T0_Timescale:  EQU &H072
T0_Command:    EQU &H073