library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_clk_gen is
    port (
        clk         : in  std_logic; -- Main system clock (e.g., 50 MHz)
        rst         : in  std_logic; -- Active high reset
        enable      : in  std_logic; -- FSM clock run flag
        scl         : out std_logic; -- Physical I2C clock line
        data_change : out std_logic; -- Pulse to modify SDA (SCL Low)
        data_sample : out std_logic  -- Pulse to sample SDA (SCL High)
    ); 
end entity;

architecture rtl of i2c_clk_gen is
    -- Divide 50MHz down to 100kHz -> 500 total counts (125 counts per quadrant)
    signal count    : unsigned(8 downto 0) := (others => '0');
    signal quadrant : unsigned(1 downto 0) := (others => '0');
    signal scl_reg  : std_logic := '1';
begin
    scl <= scl_reg;

    process(clk, rst)
    begin
        if rst = '1' then
            count       <= (others => '0');
            quadrant    <= (others => '0');
            scl_reg     <= '1';
            data_change <= '0';
            data_sample <= '0';
        elsif rising_edge(clk) then
            data_change <= '0';
            data_sample <= '0';

            if enable = '1' then
                if count = 12 then
                    count <= (others => '0');
                    quadrant <= quadrant + 1;

                    case quadrant is
                        when "00" =>
                            scl_reg     <= '0';    -- SCL drops Low
                            data_change <= '1';    -- Safe zone to change bits
                        when "01" =>
                            scl_reg     <= '0';
                        when "10" =>
                            scl_reg     <= '1';    -- SCL drives High
                            data_sample <= '1';    -- Safe zone to read stable data
                        when "11" =>
                            scl_reg     <= '1';
                        when others => null;
                    end case;
                else
                    count <= count + 1;
                end if;
            else
                count    <= (others => '0');
                quadrant <= (others => '0');
                scl_reg  <= '1'; -- Default idle high state
            end if;
        end if;
    end process;
end architecture;
