-- TIMER_PERIODIC_PERIPHERAL (file: timer_peripheral.vhd)
-- SCOMP I/O peripheral with four timers at 0x70 to 0x7F, four addresses per timer.
-- Same ports as TIMER.vhd, so its symbol drops into SCOMP_System.bdf the same way.
--
-- Address = 0x70 + 4 * timer + offset
--   IO_ADDR(10..4) = "0000111"   selects the 0x70 to 0x7F block
--   IO_ADDR(3..2)                selects the timer (0 to 3)
--   IO_ADDR(1..0)                is the offset
--
--   Offset   OUT (write)                      IN (read)
--   +0       CONFIG (mode, bits 1..0)         ELAPSED (ticks)
--   +1       DURATION (ticks)                 PERIODS (completed periods)
--   +2       TIMESCALE (ms per tick)          reads 0 (unused)
--   +3       COMMAND (bits 1..0)              reads 0 (unused)
--
-- Reads are driven only while IO_READ is high at an address in the block; otherwise
-- the bus is left high-impedance for the other peripherals. Writes are taken from
-- IO_DATA while IO_WRITE is high. See timer_channel.vhd for the register behavior.

library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity timer_peripheral is
	generic(
		CYCLES_PER_MS : positive := 10000  -- clock frequency / 1000 (10 MHz clock)
	);
	port(
		CLOCK    : in    std_logic;                      -- SCOMP clock (clk_10MHz)
		RESETN   : in    std_logic;
		IO_ADDR  : in    std_logic_vector(10 downto 0);
		IO_READ  : in    std_logic;
		IO_WRITE : in    std_logic;
		IO_DATA  : inout std_logic_vector(15 downto 0)
	);
end entity;

architecture rtl of timer_peripheral is

	constant NUM_TIMERS : natural := 4;

	type word_array is array (0 to NUM_TIMERS - 1) of std_logic_vector(15 downto 0);

	-- Address decode
	signal block_sel : std_logic;
	signal timer_idx : integer range 0 to NUM_TIMERS - 1;
	signal offset    : std_logic_vector(1 downto 0);

	-- Per-timer write strobes (one bit per timer)
	signal write_hit    : std_logic_vector(NUM_TIMERS - 1 downto 0);
	signal wr_config    : std_logic_vector(NUM_TIMERS - 1 downto 0);
	signal wr_duration  : std_logic_vector(NUM_TIMERS - 1 downto 0);
	signal wr_timescale : std_logic_vector(NUM_TIMERS - 1 downto 0);
	signal wr_command   : std_logic_vector(NUM_TIMERS - 1 downto 0);

	-- Per-timer read values
	signal elapsed : word_array;
	signal periods : word_array;

	-- Read path
	signal read_value : std_logic_vector(15 downto 0);
	signal drive_en   : std_logic;

begin

	block_sel <= '1' when IO_ADDR(10 downto 4) = "0000111" else '0';
	timer_idx <= to_integer(unsigned(IO_ADDR(3 downto 2)));
	offset    <= IO_ADDR(1 downto 0);

	-- One timer channel per timer, each with its own write strobes
	timers : for i in 0 to NUM_TIMERS - 1 generate

		write_hit(i) <= '1' when (block_sel = '1' and IO_WRITE = '1' and timer_idx = i) else '0';

		wr_config(i)    <= '1' when (write_hit(i) = '1' and offset = "00") else '0';
		wr_duration(i)  <= '1' when (write_hit(i) = '1' and offset = "01") else '0';
		wr_timescale(i) <= '1' when (write_hit(i) = '1' and offset = "10") else '0';
		wr_command(i)   <= '1' when (write_hit(i) = '1' and offset = "11") else '0';

		channel : entity work.timer_channel
			generic map(
				CYCLES_PER_MS => CYCLES_PER_MS
			)
			port map(
				CLOCK        => CLOCK,
				RESETN       => RESETN,
				WR_DATA      => IO_DATA,
				WR_CONFIG    => wr_config(i),
				WR_DURATION  => wr_duration(i),
				WR_TIMESCALE => wr_timescale(i),
				WR_COMMAND   => wr_command(i),
				ELAPSED      => elapsed(i),
				PERIODS      => periods(i),
				RUNNING      => open
			);
	end generate;

	-- Read value for the addressed timer: offset 0 = elapsed, 1 = periods, others = 0
	read_value <= elapsed(timer_idx) when offset = "00" else
	              periods(timer_idx) when offset = "01" else
	              (others => '0');

	-- Drive IO_DATA only during an IN at one of our addresses
	drive_en <= block_sel and IO_READ;

	io_bus : lpm_bustri
		generic map(
			lpm_width => 16
		)
		port map(
			data     => read_value,
			enabledt => drive_en,
			tridata  => IO_DATA
		);

end architecture;