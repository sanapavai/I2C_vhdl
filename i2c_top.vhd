library ieee;
use ieee.std_logic_1164.all;

entity i2c_top is
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
        
        -- Physical Outside Connections
        scl       : out   std_logic;
        sda       : inout std_logic
    );
end entity;

architecture structural of i2c_top is
    -- Signals connecting components together
    signal data_change : std_logic;
    signal data_sample : std_logic;
    signal clk_en      : std_logic;
    signal sda_out     : std_logic;
    signal sda_oe      : std_logic;
    signal sda_in      : std_logic;
begin

    -- Instantiate Clock Generator
    clk_gen_i : entity work.i2c_clk_gen
        port map (
            clk         => clk,
            rst         => rst,
            enable      => clk_en,
            scl         => scl,
            data_change => data_change,
            data_sample => data_sample
        );

    -- Instantiate Open-Drain I/O Buffer
    io_buf_i : entity work.i2c_io_buffer
        port map (
            sda_pin => sda,
            sda_out => sda_out,
            sda_oe  => sda_oe,
            sda_in  => sda_in 
        );

    -- Instantiate Protocol Engine FSM
    fsm_i : entity work.i2c_master_fsm
        port map (
            clk         => clk,
            rst         => rst,
            start_tx    => start_tx,
            addr        => addr,
            rw          => rw,
            data_in     => data_in,
            data_out    => data_out,
            ready       => ready,
            ack_error   => ack_error,
            data_change => data_change,
            data_sample => data_sample,
            clk_en      => clk_en,
            sda_out     => sda_out,
            sda_oe      => sda_oe,
            sda_in      => sda_in
        );

end architecture;