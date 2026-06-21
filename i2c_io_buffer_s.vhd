library ieee;
use ieee.std_logic_1164.all;

entity i2c_io_buffer is
port (
sda_pin : inout std_logic; -- Physical I2C SDA pin
sda_out : in std_logic; -- Data from internal FSM
sda_oe : in std_logic; -- FSM Output Enable (1 = Drive, 0 = Release)
sda_in : out std_logic -- Loopback input data to FSM
);
end entity;

architecture rtl of i2c_io_buffer is
begin
-- If output is enabled and we want to write a 0, drive it low.
-- If we want to write a 1 or listen, float the pin ('Z')
sda_pin <= '0' when (sda_oe = '1' and sda_out = '0') else 'Z';

-- Continuously read the actual hardware state back into the FPGA
sda_in  <= sda_pin;


end architecture;