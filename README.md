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
