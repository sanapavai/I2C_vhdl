library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_top_tb is
end entity;

architecture sim of i2c_top_tb is

    -- Component Declaration for the Unit Under Test (UUT) Master
    component i2c_top is
        port (
            clk       : in    std_logic;
            rst       : in    std_logic;
            start_tx  : in    std_logic;
            addr      : in    std_logic_vector(6 downto 0);
            rw        : in    std_logic;
            data_in   : in    std_logic_vector(7 downto 0);
            data_out  : out   std_logic_vector(7 downto 0);
            ready     : out   std_logic;
            ack_error : out   std_logic;
            scl       : out   std_logic;
            sda       : inout std_logic
        );
    end component;

    -- Testbench Signals
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal start_tx  : std_logic := '0';
    signal addr      : std_logic_vector(6 downto 0) := (others => '0');
    signal rw        : std_logic := '0';
    signal data_in   : std_logic_vector(7 downto 0) := (others => '0');
    signal data_out  : std_logic_vector(7 downto 0);
    signal ready     : std_logic;
    signal ack_error : std_logic;
    
    -- Physical Bus Lines
    signal scl       : std_logic;
    signal sda       : std_logic := 'H'; -- Weak pull-up modeling

    -- Slave Internal Register Telemetry Tracking Signals
    signal slave1_data : std_logic_vector(7 downto 0);
    signal slave2_data : std_logic_vector(7 downto 0);
    signal slave3_data : std_logic_vector(7 downto 0);

    -- Clock Period Definition (50 MHz Main System Clock)
    constant CLK_PERIOD : time := 20 ns;

begin

    -- 1. Instantiate the Master Chip (UUT)
    uut: i2c_top
        port map (
            clk       => clk,
            rst       => rst,
            start_tx  => start_tx,
            addr      => addr,
            rw        => rw,
            data_in   => data_in,
            data_out  => data_out,
            ready     => ready,
            ack_error => ack_error,
            scl       => scl,
            sda       => sda
        );

    -- 2. Connect Slave Device 1 (Address: 0x15)
    slave_1: entity work.i2c_slave_model
        generic map ( SLAVE_ADDR => "0010101" ) -- 0x15
        port map (
            scl          => scl,
            sda          => sda,
            rst          => rst,
            captured_reg => slave1_data
        );

    -- 3. Connect Slave Device 2 (Address: 0x3C)
    slave_2: entity work.i2c_slave_model
        generic map ( SLAVE_ADDR => "0111100" ) -- 0x3C
        port map (
            scl          => scl,
            sda          => sda,
            rst          => rst,
            captured_reg => slave2_data
        );

    -- 4. Connect Slave Device 3 (Address: 0x5A)
    slave_3: entity work.i2c_slave_model
        generic map ( SLAVE_ADDR => "1011010" ) -- 0x5A
        port map (
            scl          => scl,
            sda          => sda,
            rst          => rst,
            captured_reg => slave3_data
        );

    -- 5. Main System Clock Generator Process
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- 6. Master Command Sequence Stimulus Process
        -- Hold reset state initially
        -- 6. Master Command Sequence Stimulus Process
        -- Inside your testbench stimulus process:
stim_proc: process
begin
    -- 1. Hold initial setup conditions while Reset is active
    rst      <= '1';
    start_tx <= '0';
    addr     <= "1011010";   -- Address: 0x5A
    rw       <= '0';         -- Mode: Write
    data_in  <= "11010011";  -- Data: 0xD3
    wait for 100 ns;         -- Give it breathing room to settle
    
    -- 2. Release Reset cleanly
    rst      <= '0';
    wait for 100 ns;         -- Wait for synchronization lock
    
    -- 3. Pulse start_tx High for a full clock cycle to start the FSM
    start_tx <= '1';
    wait for 40 ns;          -- Assumes a 25MHz master system clock period
    start_tx <= '0';         -- Clear the start pulse immediately
    
    -- 4. Let it run! Leave the simulation active to see the data frame phase
 -- Wait until write completes
wait until ready = '1';

wait for 200 ns;

-------------------------------------------------
-- READ BACK FROM SAME SLAVE
-------------------------------------------------
addr <= "1011010";
rw   <= '1';

start_tx <= '1';
wait for 40 ns;
start_tx <= '0';

-- Wait until read completes
wait until ready = '1';

wait for 500 ns;

wait;
end process;
end architecture;
