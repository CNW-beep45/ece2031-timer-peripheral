# SCOMP Timer Peripheral

ECE 2031 project: a timer peripheral for SCOMP on the DE10-Standard (10 MHz SCOMP clock).

## Overview

Four independent timers at I/O addresses 0x70 to 0x7F. Each timer runs in one of three modes:

- Stopwatch: counts ticks continuously
- One-shot: counts to a duration, then stops
- Periodic: counts to a duration, repeats, and counts completed periods

SCOMP has no interrupts, so software polls the elapsed ticks and completed periods.

## Address map

Address: 0x70 - 0x7f

| Offset | OUT (write)                  | IN (read)         |
|--------|------------------------------|-------------------|
| +0     | CONFIG (01 stopwatch, 10 one-shot, 11 periodic) | ELAPSED (ticks) |
| +1     | DURATION (ticks)             | PERIODS (completed periods) |
| +2     | TIMESCALE (ms per tick)      | reads 0           |
| +3     | COMMAND (01 start, 10 stop, 11 reset) | reads 0  |

RESET is only accepted while the timer is stopped.

## Files
 
- `timer_prescaler.vhd`: turns the 10 MHz clock into one-clock ticks every TIMESCALE ms
- `timer_channel.vhd`: one timer (registers, modes, commands)
- `timer_peripheral.vhd`: four timers, address decode and the tri-state I/O bus
- `timer_peripheral.bsf`: Quartus symbol for the peripheral
- `SCOMP_System.bdf`: system diagram with the timer block already wired in
- `SCOMP.qsf`: Quartus settings that list the new files


## Setup
 
These files go on top of the Lab 8 SCOMP  project.
 
1. Clone this repo and download it.
2. Copy `timer_prescaler.vhd`, `timer_channel.vhd`, `timer_peripheral.vhd` and `timer_peripheral.bsf` into your project folder.
3. Copy `SCOMP_System.bdf` and `SCOMP.qsf` into the same folder and replace the originals.
4. Open `SCOMP_System.bdf` and check the `timer_peripheral` block is connected:
   | Pin | Net |
   |-----|-----|
   | CLOCK | `clk_10MHz` |
   | RESETN | `resetn` |
   | IO_ADDR[10..0] | `IO_ADDR[10..0]` |
   | IO_READ | `IO_READ` |
   | IO_WRITE | `IO_WRITE` |
   | IO_DATA[15..0] | `IO_DATA[15..0]` |
5. Right-click the block and check `CYCLES_PER_MS` is 10000.

### Notes
 
- Only `timer_peripheral` needs a block in the BDF. The channel and prescaler are used inside it.
- timescale start as 1 as 1 ms so 1 sec would be 1000 as the timescale input
