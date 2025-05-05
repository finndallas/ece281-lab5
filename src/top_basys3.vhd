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


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
	-- singal
    signal w_clk : std_logic;
    signal w_clk_TDM : std_logic;
    signal w_clk_reset : std_logic;
    signal w_elevator_reset  : std_logic;
    signal w_1stelevator : std_logic_vector (3 downto 0);
    signal w_2ndelevator : std_logic_vector (3 downto 0);
    signal w_data : std_logic_vector (3 downto 0);
    
    --components
 component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
	

  
begin
	-- PORT MAPS ----------------------------------------
--generic map

	   clock_divider_TDM_inst : clock_divider
	   -- its 60Hz*4 = 240 then convert to k_div, its 4 bc 4 displaus
	   	generic map (k_div => 208333)

	     port map(
	     --in
	     i_clk => clk,
	     --out
	     i_reset => w_clk_reset,
	     o_clk => w_clk_TDM
	     );
	
	   clock_divider_inst : clock_divider
	   generic map (k_div => 25000000) --ranbdolph told me this speed
	     port map(
	     --in
	     i_clk => clk,
	     --out
	     i_reset => w_clk_reset,
	     o_clk => w_clk
	     );    
	
       elevator_controller_inst :  elevator_controller_fsm
          port map(
          --in
            i_clk => w_clk,
            i_reset => w_elevator_reset,
            is_stopped => sw(0),
            go_up_down => sw(1),
            --out
            o_floor => w_1stelevator
            );
            
		 elevator_controller_2_inst :  elevator_controller_fsm
          port map(
          --in
            i_clk => w_clk,
            i_reset => w_elevator_reset,
            is_stopped => sw(14),
            go_up_down => sw(15),
            --out
            o_floor => w_2ndelevator
            
            );
            
		sevenseg_decoder_inst : sevenseg_decoder
		  port map(
		  i_Hex => w_data,
		  o_seg_n => seg
		  );
		  
		  TDM4_inst : TDM4
        Port map ( 
            i_clk => w_clk_TDM,
            i_reset => btnU,
            i_D3 => "1111",
            i_D2 => w_2ndelevator,
            i_D1 => "1111",
            i_D0 => w_1stelevator,
            o_data => w_data,
            o_sel => an
	   );
	
	
	-- CONCURRENT STATEMENTS ----------------------------
	
	
	
end top_basys3_arch;
