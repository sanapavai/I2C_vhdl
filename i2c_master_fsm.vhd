library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity i2c_master_fsm is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        start_tx    : in  std_logic;
        addr        : in  std_logic_vector(6 downto 0);
        rw          : in  std_logic;
        data_in     : in  std_logic_vector(7 downto 0);
        data_out    : out std_logic_vector(7 downto 0);
        ready       : out std_logic;
        ack_error   : out std_logic;
        
        -- Timing and Buffer Interface
        data_change : in  std_logic;
        data_sample : in  std_logic;
        clk_en      : out std_logic;
        sda_out     : out std_logic;
        sda_oe      : out std_logic;
        sda_in      : in  std_logic
    );
end entity;

architecture rtl of i2c_master_fsm is
    type t_state is (STATE_IDLE, STATE_START, STATE_ADDR, STATE_SLAVE_ACK, 
                     STATE_DATA, STATE_MASTER_ACK, STATE_STOP);
    signal state     : t_state := STATE_IDLE;
    signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal bit_cnt   : integer range 0 to 7 := 7;
begin

    process(clk, rst)
    begin
        if rst = '1' then
            state     <= STATE_IDLE;
            shift_reg <= (others => '0');
            bit_cnt   <= 7;
            clk_en    <= '0';
            sda_out   <= '1';
            sda_oe    <= '0';
            ready     <= '1';
            ack_error <= '0';
            data_out  <= (others => '0');
        elsif rising_edge(clk) then
            case state is
 
                when STATE_IDLE =>
                    ready   <= '1';
                    sda_oe  <= '0';
                    sda_out <= '1';
                    clk_en  <= '0';
                    if start_tx = '1' then
                        state     <= STATE_START;
                        ready     <= '0';
                        ack_error <= '0';
                        shift_reg <= addr & rw; -- Combine 7-bit Addr + R/W bit
                        sda_oe    <= '1';
                        sda_out   <= '1';
                    end if;

                when STATE_START =>
                    clk_en  <= '1';
                    sda_out <= '0'; -- Pull SDA Low while SCL is High (Start Condition)
                    if data_change = '1' then
                        state   <= STATE_ADDR;
                        bit_cnt <= 7;
                    end if;

                when STATE_ADDR =>
                    sda_oe  <= '1';
                    sda_out <= shift_reg(bit_cnt); 
                    if data_change = '1' then
                        if bit_cnt = 0 then
                            state <= STATE_SLAVE_ACK;
                        else
                            bit_cnt <= bit_cnt - 1;
                        end if;
                    end if;

                when STATE_SLAVE_ACK =>
                    sda_oe <= '0'; -- Release bus to listen for slave ACK
                    
                    -- Sample ACK bit safely at the stable peak center of SCL
                    if data_sample = '1' then
                        if sda_in = '1' then
                            ack_error <= '1'; -- Slave failed to pull low (NACK)
                        end if;
                    end if;
                    
                    -- Transition step-boundary locked strictly to a data change pulse
                    if data_change = '1' then
                        if sda_in = '1' then
                            state <= STATE_STOP; -- Abort sequence if NACK detected
                        else
                            shift_reg <= data_in; -- Stage payload byte safely
                            bit_cnt   <= 7;
                            state     <= STATE_DATA; -- Step forward to data frame
                        end if;
                    end if;

                when STATE_DATA =>
                    if rw = '0' then
                        sda_oe  <= '1'; -- Transmitting (Write Mode)
                        sda_out <= shift_reg(bit_cnt);
                    else
                        sda_oe  <= '0'; -- Receiving (Read Mode)
                        if data_sample = '1' then
                            shift_reg(bit_cnt) <= sda_in;
                        end if;
                    end if;

                    if data_change = '1' then
                        if bit_cnt = 0 then
                            if rw = '1' then
                                data_out <= shift_reg; -- Lock down read byte
                            end if;
                            state <= STATE_MASTER_ACK; 
                        else
                            bit_cnt <= bit_cnt - 1;
                        end if;
                    end if;

                when STATE_MASTER_ACK =>
                    if rw = '0' then
                        sda_oe <= '0'; -- Write transmission checkout phase
                        if data_sample = '1' and sda_in = '1' then
                            ack_error <= '1';
                        end if;
                    else
                        sda_oe  <= '1';
                        sda_out <= '1'; -- Signal master NACK to close read block
                    end if;
                    if data_change = '1' then
                        state <= STATE_STOP;
                    end if;

                when STATE_STOP =>
                    sda_oe  <= '1';
                    sda_out <= '0'; -- Force low during low phase transition window
                    if data_sample = '1' then
                        sda_out <= '1'; -- Release Low to High while SCL is High (Stop Condition)
                    end if;
                    if data_change = '1' then
                        clk_en <= '0';
                        state  <= STATE_IDLE;
                    end if;

                when others =>
                    state <= STATE_IDLE;
            end case;
        end if;
    end process;
end architecture;