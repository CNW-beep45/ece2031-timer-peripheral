-- TIMER_CHANNEL
-- One timer of the SCOMP timer peripheral: registers, mode logic and a prescaler.
-- timer_peripheral.vhd instantiates four of these and handles the I/O bus.
--
-- Write registers (each write is a one-clock strobe with the value on WR_DATA):
--   CONFIG     bits 1..0: 01 stopwatch, 10 one-shot, 11 periodic, 00 reserved (ignored)
--   DURATION   ticks until expiry (0 is ignored); updated in any mode,
--              but not used by stopwatch mode
--   TIMESCALE  milliseconds per tick (0 is ignored)
--   COMMAND    bits 1..0: 00 no-op, 01 START, 10 STOP, 11 RESET
--                RESET is only accepted while stopped; it clears ELAPSED, PERIODS
--                and the partial-tick phase
--
-- Read values:
--   ELAPSED    ticks counted (periodic mode: ticks within the current period)
--   PERIODS    completed expirations (wraps 65535 -> 0); unused in stopwatch mode

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_channel is
	generic(
		CYCLES_PER_MS : positive := 10000  -- clock frequency / 1000 (10 MHz clock)
	);
	port(
		CLOCK        : in  std_logic;                      -- SCOMP clock (clk_10MHz)
		RESETN       : in  std_logic;                      -- active-low asynchronous reset
		WR_DATA      : in  std_logic_vector(15 downto 0);  -- value from SCOMP (IO_DATA)
		WR_CONFIG    : in  std_logic;                      -- write strobes, one per register
		WR_DURATION  : in  std_logic;
		WR_TIMESCALE : in  std_logic;
		WR_COMMAND   : in  std_logic;
		ELAPSED      : out std_logic_vector(15 downto 0);
		PERIODS      : out std_logic_vector(15 downto 0);
		RUNNING      : out std_logic
	);
end entity;

architecture rtl of timer_channel is

	-- Mode codes (CONFIG bits 1..0)
	constant MODE_STOPWATCH : std_logic_vector(1 downto 0) := "01";
	constant MODE_ONE_SHOT  : std_logic_vector(1 downto 0) := "10";
	constant MODE_PERIODIC  : std_logic_vector(1 downto 0) := "11";

	-- Command codes (COMMAND bits 1..0)
	constant CMD_START : std_logic_vector(1 downto 0) := "01";
	constant CMD_STOP  : std_logic_vector(1 downto 0) := "10";
	constant CMD_RESET : std_logic_vector(1 downto 0) := "11";

	-- Power-up and reset values
	constant DEFAULT_TIMESCALE : std_logic_vector(15 downto 0) := x"03E8";  -- 1000 ms

	-- Registers
	signal mode_r      : std_logic_vector(1 downto 0)  := MODE_STOPWATCH;
	signal duration_r  : unsigned(15 downto 0)         := to_unsigned(1, 16);
	signal timescale_r : std_logic_vector(15 downto 0) := DEFAULT_TIMESCALE;

	-- State
	signal elapsed_r : unsigned(15 downto 0) := (others => '0');
	signal periods_r : unsigned(15 downto 0) := (others => '0');
	signal running_r : std_logic := '0';

	-- Prescaler connections
	signal tick           : std_logic;
	signal clear_prescale : std_logic := '0';

begin

	prescaler : entity work.timer_prescaler
		generic map(
			CYCLES_PER_MS => CYCLES_PER_MS
		)
		port map(
			CLOCK     => CLOCK,
			RESETN    => RESETN,
			TIMESCALE => timescale_r,
			ENABLE    => running_r,
			CLEAR     => clear_prescale,
			TICK      => tick
		);

	process(CLOCK, RESETN)
	begin
		if RESETN = '0' then
			mode_r         <= MODE_STOPWATCH;
			duration_r     <= to_unsigned(1, 16);
			timescale_r    <= DEFAULT_TIMESCALE;
			elapsed_r      <= (others => '0');
			periods_r      <= (others => '0');
			running_r      <= '0';
			clear_prescale <= '0';

		elsif rising_edge(CLOCK) then
			clear_prescale <= '0';  -- default: clear the prescaler for one cycle only

			if tick = '1' and running_r = '1' then
				case mode_r is

					when MODE_STOPWATCH =>
						elapsed_r <= elapsed_r + 1;

					when MODE_ONE_SHOT =>
						if elapsed_r >= duration_r - 1 then
							elapsed_r <= duration_r;       -- land exactly on DURATION
							periods_r <= periods_r + 1;
							running_r <= '0';              -- one-shot stops at expiry
						else
							elapsed_r <= elapsed_r + 1;
						end if;

					when MODE_PERIODIC =>
						if elapsed_r >= duration_r - 1 then
							elapsed_r <= (others => '0');  -- next period starts at 0
							periods_r <= periods_r + 1;
						else
							elapsed_r <= elapsed_r + 1;
						end if;

					when others =>
						null;
				end case;
			end if;

			if WR_CONFIG = '1' and WR_DATA(1 downto 0) /= "00" then
				mode_r <= WR_DATA(1 downto 0);
			end if;

			if WR_DURATION = '1' and unsigned(WR_DATA) /= 0 then
				duration_r <= unsigned(WR_DATA);
			end if;

			if WR_TIMESCALE = '1' and unsigned(WR_DATA) /= 0 then
				timescale_r    <= WR_DATA;
				clear_prescale <= '1';  
			end if;

			if WR_COMMAND = '1' then
				case WR_DATA(1 downto 0) is

					when CMD_START =>
						running_r <= '1';

					when CMD_STOP =>
						running_r <= '0';

					when CMD_RESET =>
						if running_r = '0' then  -- only accepted while stopped
							elapsed_r      <= (others => '0');
							periods_r      <= (others => '0');
							clear_prescale <= '1';
						end if;

					when others =>
						null;                    -- 00 = no operation
				end case;
			end if;
		end if;
	end process;

	ELAPSED <= std_logic_vector(elapsed_r);
	PERIODS <= std_logic_vector(periods_r);
	RUNNING <= running_r;

end architecture;