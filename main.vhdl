library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity JTAG_sniffer is
    port(
        clock_12MHz: in std_logic;
        -- J3: PIO3_26
        
        TCLK : in std_logic;
        TRST : in std_logic;
        TMS  : in std_logic;
        TDI  : in std_logic;
        TDO  : in std_logic
    );
end entity;

architecture main of JTAG_sniffer is

    -- JTAG state machine
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

    -- state machine follower
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
