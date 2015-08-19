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
        
        UART_RX : in std_logic;
        -- B10: PIO0_14
        UART_TX : out std_logic;
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

    -- import UART module
    component UART
        port(
            clock          : in  std_logic;
            RX             : in  std_logic;
            TX             : out std_logic;
            byte_ready     : out std_logic;
            received_byte  : out std_logic_vector(7 downto 0)
        );
    end component;

    -- signals for UART usage
    signal UART_clock           : std_logic := '0';
    signal UART_byte_ready      : std_logic := '0';
    signal UART_received_byte   : std_logic_vector(7 downto 0) := (others => '0');

    -- import JTAG module
    component JTAG_TAP
        port(
            TCLK : in std_logic;
            TRST : in std_logic;
            TMS  : in std_logic;
            TDI  : in std_logic;
            TDO  : in std_logic
        );
    end component;

begin

    --
    -- Create an instance of a serial port
    --
    UART0 : UART port map(
        clock           => UART_clock,
        RX              => UART_RX,
        TX              => UART_TX,
        byte_ready      => UART_byte_ready,
        received_byte   => UART_received_byte
        );

    --
    -- Clock divider for UART:
    -- 115200bps/Hz
    --
    process(clock, UART_clock)
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
    -- Output received byte to LEDs
    --
    process(UART_byte_ready, UART_received_byte)
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

end main;
