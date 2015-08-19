library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

--
-- This module implements a virtual JTAG slave,
-- which intercepts the communication between
-- a JTAG programmer and it's intended tap,
-- in order to make it available for processing or
-- to forward it to a developer for inspection.
--

entity JTAG_TAP is
    port(
        TCLK : in std_logic;
        TRST : in std_logic;
        TMS  : in std_logic;
        TDI  : in std_logic;
        TDO  : in std_logic
    );
end entity;

architecture follower of JTAG_TAP is
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
        
    -- current state
    signal state : JTAG_FSM := test_logic_reset;
begin

    --
    -- JTAG state machine follower
    --
    process(TRST,TCLK,TMS)
    begin
        -- flip-flop
        if TCLK'event and TCLK='1' then

            -- synchronous reset
            if TRST='1' then
                state <= test_logic_reset; 
            else

                case state is
                    when test_logic_reset =>
                        if TMS='0' then
                            state <= run_test_idle;
                        end if;
                        
                    when run_test_idle =>
                        if TMS='1' then
                            state <= select_DR_scan;
                        end if;

                    --
                    -- data register actions
                    --

                    when select_DR_scan =>
                        if TMS='0' then
                            state <= capture_DR;
                        else
                            state <= select_IR_scan;
                        end if;

                    when capture_DR =>
                        if TMS='0' then
                            state <= shift_DR;
                        else
                            state <= exit1_DR;
                        end if;

                    when shift_DR =>
                        if TMS='1' then
                            state <= exit1_DR;
                        end if;

                    when exit1_DR =>
                        if TMS='0' then
                            state <= pause_DR;
                        else
                            state <= update_DR;
                        end if;

                    when pause_DR =>
                        if TMS='1' then
                            state <= exit2_DR;
                        end if;

                    when exit2_DR =>
                        if TMS='0' then
                            state <= shift_DR;
                        else
                            state <= update_DR;
                        end if;

                    when update_DR =>
                        if TMS='0' then
                            state <= run_test_idle;
                        else
                            state <= select_DR_scan;
                        end if;
                    
                    --
                    -- instruction register actions
                    --
                    
                    when select_IR_scan =>
                        if TMS='0' then
                            state <= capture_IR;
                        else
                            state <= test_logic_reset;
                        end if;

                    when capture_IR =>
                        if TMS='0' then
                            state <= shift_IR;
                        else
                            state <= exit1_IR;
                        end if;

                    when shift_IR =>
                        if TMS='1' then
                            state <= exit1_IR;
                        end if;

                    when exit1_IR =>
                        if TMS='0' then
                            state <= pause_IR;
                        else
                            state <= update_IR;
                        end if;

                    when pause_IR =>
                        if TMS='1' then
                            state <= exit2_IR;
                        end if;

                    when exit2_IR =>
                        if TMS='0' then
                            state <= shift_IR;
                        else
                            state <= update_IR;
                        end if;

                    when update_IR =>
                        if TMS='0' then
                            state <= run_test_idle;
                        else
                            state <= select_DR_scan;
                        end if;

                end case;

            end if;

        end if;
    end process;

end follower;
