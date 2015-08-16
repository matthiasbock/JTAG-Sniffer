library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity JTAGsniffer is
    port(
        --
        -- Onboard quartz
        -- Frequency: 12MHz
        --
    
        clock: in std_logic;
        -- J3: PIO3_26
        
        --
        -- Onboard red LEDs
        -- Required voltage: 3.3V ?
        --

        LED0 : out std_logic;
        -- B5: PIO0_39
        LED1 : out std_logic;
        -- B4: PIO0_41
        LED2 : out std_logic;
        -- A2: PIO0_42
        LED3 : out std_logic;
        -- A1: PIO0_44
        LED4 : out std_logic;
        -- C5: PIO0_45
        LED5 : out std_logic;
        -- C4: PIO0_46
        LED6 : out std_logic;
        -- B3: PIO0_47
        LED7 : out std_logic;
        -- C3: PIO0_51

        --
        -- RS232 via FTDI-2232
        -- Voltage level: 3.3V
        -- Baud: 115200bps 8N1
        --
        
        RX : in std_logic;
        -- B10: PIO0_14
        TX : out std_logic;
        -- B12: PIO0_13

        --
        -- JTAG tap
        -- Input signal voltage: 1.2V
        --
        
        TCLK : in std_logic;
        TRST : in std_logic;
        TMS  : in std_logic;
        TDI  : in std_logic;
        TDO  : in std_logic
    );
end entity;

architecture main of JTAGsniffer is

    --
    -- RS232 signals
    --
    signal UART_clock : std_logic := '0';
    type UART_FSM is (idle, receiving, stop);
    signal UART_state : UART_FSM := idle;
    signal UART_received_byte : std_logic_vector(7 downto 0) := (others => '0');
    signal UART_byte_ready : std_logic := '0';
    

    --
    -- JTAG state machine
    --
    type JTAG_FSM is (
        test_logic_reset,
        run_test_idle,

        select_DR_scan,
        capture_DR,
        shift_DR,
        exit1_DR,
        pause_DR,
        exit2_DR,
        update_DR,
        
        select_IR_scan,
        capture_IR,
        shift_IR,
        exit1_IR,
        pause_IR,
        exit2_IR,
        update_IR
        );
    signal JTAG_state : JTAG_FSM := test_logic_reset;

begin

    --
    -- Clock divider for UART
    --
    process(clock, RX)
        variable counter : integer range 0 to 104167 := 0;
    begin
        if clock'event and clock='1' then
            if counter = 104167 then
                UART_clock <= '1';
                counter := 0; 
            else
                if counter = 52083 then
                    UART_clock <= '0';
                end if;
                counter := counter + 1;
            end if;
        end if;
    end process;

    --
    -- UART receiver
    --
    process(UART_clock, RX)
        variable UART_received_bits : integer range 0 to 7 := 0;
    begin
        if UART_clock'event and UART_clock='1' then

            case UART_state is
            
                -- one start bit
                when idle =>
                    UART_byte_ready <= '0';
                    if RX='1' then
                        UART_state <= receiving;
                        UART_received_bits := 0;
                        UART_received_byte <= (others => '0');
                    end if;
                
                -- 8 data bits
                when receiving =>
                    -- shift right and concatenate
                    UART_received_byte <= RX & UART_received_byte(7 downto 1); 
                    UART_received_bits := UART_received_bits + 1;  
                    if UART_received_bits >= 8 then
                        UART_state <= stop;
                        UART_byte_ready <= '1';
                    end if;
                    
                -- one stop bit
                when stop =>
                    UART_state <= idle;

            end case;

        end if;
    end process;

    --
    -- Output received UART byte to LEDs
    --
    process(UART_byte_ready)
    begin
        if UART_byte_ready'event and UART_byte_ready='1' then
            LED0 <= UART_received_byte(0);
            LED1 <= UART_received_byte(1);
            LED2 <= UART_received_byte(2);
            LED3 <= UART_received_byte(3);
            LED4 <= UART_received_byte(4);
            LED5 <= UART_received_byte(5);
            LED6 <= UART_received_byte(6);
            LED7 <= UART_received_byte(7);
        end if;
    end process;

    --
    -- JTAG state machine follower
    --
    process(TRST,TCLK,TMS)
    begin
        -- flip-flop
        if TCLK'event and TCLK='1' then

            -- synchronous reset
            if TRST='1' then
                JTAG_state <= test_logic_reset; 
            else

                case JTAG_state is
                    when test_logic_reset =>
                        if TMS='0' then
                            JTAG_state <= run_test_idle;
                        end if;
                        
                    when run_test_idle =>
                        if TMS='1' then
                            JTAG_state <= select_DR_scan;
                        end if;

                    --
                    -- data register actions
                    --

                    when select_DR_scan =>
                        if TMS='0' then
                            JTAG_state <= capture_DR;
                        else
                            JTAG_state <= select_IR_scan;
                        end if;

                    when capture_DR =>
                        if TMS='0' then
                            JTAG_state <= shift_DR;
                        else
                            JTAG_state <= exit1_DR;
                        end if;

                    when shift_DR =>
                        if TMS='1' then
                            JTAG_state <= exit1_DR;
                        end if;

                    when exit1_DR =>
                        if TMS='0' then
                            JTAG_state <= pause_DR;
                        else
                            JTAG_state <= update_DR;
                        end if;

                    when pause_DR =>
                        if TMS='1' then
                            JTAG_state <= exit2_DR;
                        end if;

                    when exit2_DR =>
                        if TMS='0' then
                            JTAG_state <= shift_DR;
                        else
                            JTAG_state <= update_DR;
                        end if;

                    when update_DR =>
                        if TMS='0' then
                            JTAG_state <= run_test_idle;
                        else
                            JTAG_state <= select_DR_scan;
                        end if;
                    
                    --
                    -- instruction register actions
                    --
                    
                    when select_IR_scan =>
                        if TMS='0' then
                            JTAG_state <= capture_IR;
                        else
                            JTAG_state <= test_logic_reset;
                        end if;

                    when capture_IR =>
                        if TMS='0' then
                            JTAG_state <= shift_IR;
                        else
                            JTAG_state <= exit1_IR;
                        end if;

                    when shift_IR =>
                        if TMS='1' then
                            JTAG_state <= exit1_IR;
                        end if;

                    when exit1_IR =>
                        if TMS='0' then
                            JTAG_state <= pause_IR;
                        else
                            JTAG_state <= update_IR;
                        end if;

                    when pause_IR =>
                        if TMS='1' then
                            JTAG_state <= exit2_IR;
                        end if;

                    when exit2_IR =>
                        if TMS='0' then
                            JTAG_state <= shift_IR;
                        else
                            JTAG_state <= update_IR;
                        end if;

                    when update_IR =>
                        if TMS='0' then
                            JTAG_state <= run_test_idle;
                        else
                            JTAG_state <= select_DR_scan;
                        end if;

                end case;

            end if;

        end if;
    end process;

end main;
