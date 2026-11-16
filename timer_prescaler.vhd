-- TIMER_PRESCALER
-- Gives a one-clock-cycle TICK pulse every TIMESCALE milliseconds.
-- Runs on the SCOMP clock (clk_10MHz), so there is no clock-domain crossing.
--
-- CYCLES_PER_MS = clock frequency / 1000   (10 MHz -> 10000)
-- ENABLE high counts, ENABLE low pauses. CLEAR restarts the count and gives no tick.
-- A TIMESCALE of 0 behaves like 1 (a tick every millisecond).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_prescaler is
	generic(
		CYCLES_PER_MS : positive := 10000
	);
	port(
		CLOCK     : in  std_logic;
		RESETN    : in  std_logic;                      
		TIMESCALE : in  std_logic_vector(15 downto 0);  -- milliseconds per tick
		ENABLE    : in  std_logic;
		CLEAR     : in  std_logic;
		TICK      : out std_logic
	);
end entity;

architecture rtl of timer_prescaler is
	signal cycle_count : integer range 0 to CYCLES_PER_MS - 1;  -- clock cycles within 1 ms
	signal ms_count    : unsigned(15 downto 0);                  -- whole ms since the last tick
begin
	process(CLOCK, RESETN)
	begin
		if RESETN = '0' then
			cycle_count <= 0;
			ms_count    <= (others => '0');
			TICK        <= '0';

		elsif rising_edge(CLOCK) then
			TICK <= '0';  -- default: the tick lasts one clock cycle

			if CLEAR = '1' then
				cycle_count <= 0;
				ms_count    <= (others => '0');

			elsif ENABLE = '1' then
				if cycle_count < CYCLES_PER_MS - 1 then
					cycle_count <= cycle_count + 1;
				else
					-- one millisecond has passed
					cycle_count <= 0;
					if ms_count + 1 >= unsigned(TIMESCALE) then
						ms_count <= (others => '0');
						TICK     <= '1';
					else
						ms_count <= ms_count + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
end architecture;