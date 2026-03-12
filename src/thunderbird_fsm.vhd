--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm.vhd
--| AUTHOR(S)     : Capt Phillip Warner, Capt Dan Johnson
--| CREATED       : 03/2017 Last modified 06/25/2020
--| DESCRIPTION   : This file implements the ECE 281 Lab 2 Thunderbird tail lights
--|					FSM using enumerated types.  This was used to create the
--|					erroneous sim for GR1
--|
--|					Inputs:  i_clk 	 --> 100 MHz clock from FPGA
--|                          i_left  --> left turn signal
--|                          i_right --> right turn signal
--|                          i_reset --> FSM reset
--|
--|					Outputs:  o_lights_L (2:0) --> 3-bit left turn signal lights
--|					          o_lights_R (2:0) --> 3-bit right turn signal lights
--|
--|					Upon reset, the FSM by defaults has all lights off.
--|					Left ON - pattern of increasing lights to left
--|						(OFF, LA, LA/LB, LA/LB/LC, repeat)
--|					Right ON - pattern of increasing lights to right
--|						(OFF, RA, RA/RB, RA/RB/RC, repeat)
--|					L and R ON - hazard lights (OFF, ALL ON, repeat)
--|					A is LSB of lights output and C is MSB.
--|					Once a pattern starts, it finishes back at OFF before it 
--|					can be changed by the inputs
--|					
--|
--|                 Binary State Encoding key
--|                 --------------------
--|                  State | Encoding
--|                 --------------------
--|                  OFF   |000 
--|                  ON    |001 
--|                  R1    |010 
--|                  R2    |011 
--|                  R3    |100 
--|                  L1    |101 
--|                  L2    |110 
--|                  L3    |111 
--|                 --------------------
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : None
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
 
entity thunderbird_fsm is
    port (
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0); -- LA is LSB
        o_lights_R      : out   std_logic_vector(2 downto 0);  -- RA is LSB
        -- trying to add states to waveform
        o_current       : out std_logic_vector(2 downto 0);
        o_next          : out std_logic_vector(2 downto 0)
    );
end thunderbird_fsm;

architecture thunderbird_fsm_arch of thunderbird_fsm is 
    
    signal f_Q : std_logic_vector(2 downto 0) := "000";
    signal f_Qn : std_logic_vector(2 downto 0) := "000";
    
    
    
-- CONSTANTS ------------------------------------------------------------------

begin
    o_current <= f_Q;
    o_next <= f_Qn;
	-- CONCURRENT STATEMENTS --------------------------------------------------------	
	-- Next State Logic
    f_Qn(0) <=
            (NOT f_Q(2) AND NOT f_Q(1) AND NOT f_Q(0) AND i_right AND i_left) OR 
            (NOT f_Q(2) AND NOT f_Q(1) AND NOT f_Q(0) AND i_left and NOT i_right) OR
            (NOT f_Q(2) AND f_Q(1) AND NOT f_Q(0)) OR
            (f_Q(2) AND f_Q(1) AND NOT f_Q(0));
    
    
    f_Qn(1) <=
            (NOT f_Q(2) AND NOT f_Q(1) AND NOT f_Q(0) AND i_right AND NOT i_left) OR 
            (NOT f_Q(2) AND f_Q(1) AND NOT f_Q(0)) OR 
            (f_Q(2) AND NOT f_Q(1) AND f_Q(0)) OR 
            (f_Q(2) AND f_Q(1) AND NOT f_Q(0));
    
    
    f_Qn(2) <=
            (NOT f_Q(2) AND NOT f_Q(1) AND NOT f_Q(0) AND NOT i_right AND i_left) OR
            (NOT f_Q(2) AND f_Q(1) AND f_Q(0)) OR 
            (f_Q(2) AND NOT f_Q(1) AND f_Q(0)) OR 
            (f_Q(2) AND f_Q(1) AND NOT f_Q(0));
            
    -- Output Logic
    o_lights_L <= "000" when f_Q = "000" else
              "111" when f_Q = "001" else
              "000" when f_Q = "010" else
              "000" when f_Q = "011" else
              "000" when f_Q = "100" else
              "001" when f_Q = "101" else
              "011" when f_Q = "110" else
              "111";

    o_lights_R <= "000" when f_Q = "000" else
                  "111" when f_Q = "001" else
                  "001" when f_Q = "010" else
                  "011" when f_Q = "011" else
                  "111" when f_Q = "100" else
                  "000" when f_Q = "101" else
                  "000" when f_Q = "110" else
                  "000";
    ---------------------------------------------------------------------------------
	
	-- PROCESSES --------------------------------------------------------------------
    register_proc : process (i_clk, i_reset)
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' then
                f_Q <= "000";
            else 
                f_Q <= f_Qn;
            end if;
        end if;
    end process register_proc;
	-----------------------------------------------------					   
				  
end thunderbird_fsm_arch;