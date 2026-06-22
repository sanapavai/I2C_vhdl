library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_slave_model is
    generic (
        SLAVE_ADDR : std_logic_vector(6 downto 0) := "1011010"
    );
    port (
        scl          : in    std_logic;
        sda          : inout std_logic;
        rst          : in    std_logic;
        captured_reg : out   std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of i2c_slave_model is

    signal shift_reg    : std_logic_vector(7 downto 0) := (others => '0');
    signal internal_reg : std_logic_vector(7 downto 0) := (others => '0');

    signal bit_count    : integer range 0 to 17 := 0;
    signal addr_match   : std_logic := '0';
    signal rw_bit       : std_logic := '0';

    signal sda_drv      : std_logic := '1';
    signal tx_shift_reg : std_logic_vector(7 downto 0) := (others => '0');

begin

    captured_reg <= internal_reg;

    sda <= '0' when sda_drv = '0' else 'Z';

    ----------------------------------------------------------------
    -- RECEIVE DATA
    ----------------------------------------------------------------
    process(scl, rst)
    begin
        if rst = '1' then
            bit_count    <= 0;
            shift_reg    <= (others => '0');
            addr_match   <= '0';
            rw_bit       <= '0';

        elsif rising_edge(scl) then

            if bit_count < 8 then
    if sda = '0' then
        shift_reg <= shift_reg(6 downto 0) & '0';
    else
        shift_reg <= shift_reg(6 downto 0) & '1';
    end if;
                bit_count <= bit_count + 1;

            elsif bit_count = 8 then

                if shift_reg(7 downto 1) = SLAVE_ADDR then
                    addr_match <= '1';
                else
                    addr_match <= '0';
                end if;

                rw_bit    <= shift_reg(0);
                bit_count <= bit_count + 1;

            elsif bit_count > 8 and bit_count < 17 then

                if sda = '0' then
        shift_reg <= shift_reg(6 downto 0) & '0';
    else
        shift_reg <= shift_reg(6 downto 0) & '1';
    end if;
                bit_count <= bit_count + 1;

            elsif bit_count = 17 then

                if addr_match = '1' and rw_bit = '0' then
                    internal_reg <= shift_reg;
                end if;

                bit_count <= 0;

            end if;

        end if;
    end process;

    ----------------------------------------------------------------
    -- ACK GENERATION
    ----------------------------------------------------------------
    process(scl, rst)
    begin
        if rst = '1' then
            sda_drv <= '1';

        elsif falling_edge(scl) then

            if bit_count = 8 then

                if shift_reg(7 downto 1) = SLAVE_ADDR then
                    sda_drv <= '0';
                else
                    sda_drv <= '1';
                end if;

            elsif bit_count = 17 then

                if addr_match = '1' then
                    sda_drv <= '0';
                else
                    sda_drv <= '1';
                end if;

            else
                sda_drv <= '1';
            end if;

        end if;
    end process;

end architecture;
