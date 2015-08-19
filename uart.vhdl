library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

--
-- This module implements a RS232 UART transceiver
-- for communication with a another system (e.g. a PC) via a serial port.
--

entity UART is
    port(
        clock          : in  std_logic;
        RX             : in  std_logic;
        TX             : out std_logic;
        byte_ready     : out std_logic;
        received_byte  : out std_logic_vector(7 downto 0)
    );
end entity;

architecture controller of UART is

    type UART_FSM is (idle, receiving, stop);
    signal state : UART_FSM := idle;

begin

    --
    -- UART receiver
    --
    process(clock,RX)
        variable received_bits : integer range 0 to 8 := 0;
    begin
        if clock'event and clock='1' then

            case state is
            
                -- one start bit
                when idle =>
                    byte_ready <= '0';
                    if RX='1' then
                        state <= receiving;
                        received_bits := 0;
                        received_byte <= (others => '0');
                    end if;
                
                -- 8 data bits
                when receiving =>
                    -- shift right and concatenate
                    received_byte <= RX & received_byte(7 downto 1); 
                    received_bits := received_bits + 1;  
                    if received_bits >= 8 then
                        state <= stop;
                        byte_ready <= '1';
                    end if;
                    
                -- one stop bit
                when stop =>
                    state <= idle;

                when others =>
                    state <= idle;
            end case;

        end if;
    end process;

end controller;
