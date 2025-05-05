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
-- 
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnC    :   in std_logic; -- clk_reset
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(8 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;
 
architecture top_basys3_arch of top_basys3 is 
	-- declare components and signals
   -- twoscomp
        component twoscomp_decimal is
            port (
                i_binary: in std_logic_vector(7 downto 0);
                o_negative: out std_logic;
                o_hundreds: out std_logic_vector(3 downto 0);
                o_tens: out std_logic_vector(3 downto 0);
                o_ones: out std_logic_vector(3 downto 0)
            );
        end component twoscomp_decimal;
    -- controller_fsm
            component controller_fsm is
                port(
                    i_reset   : in std_logic;
                    i_adv     : in std_logic;
                    i_clk     : in std_logic;
                    o_cycle   : out std_logic_vector (3 downto 0)
                  );
            end component controller_fsm;  
    -- TDM4
                component TDM4 is
                    generic ( constant k_WIDTH : natural  := 4); 
                    Port ( i_clk        : in  STD_LOGIC;
                           i_reset        : in  STD_LOGIC;
                           i_D3         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                           i_D2         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                           i_D1         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                           i_D0         : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                           o_data       : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
                           o_sel        : out STD_LOGIC_VECTOR (3 downto 0)    
                    );
                end component TDM4;
  -- sevenSegDecoder
      component sevenSegDecoder is
                Port ( i_D : in STD_LOGIC_VECTOR (3 downto 0);
                       o_S : out STD_LOGIC_VECTOR (6 downto 0));
      end component sevenSegDecoder;
  -- clock_divider
       component clock_divider is
              generic ( constant k_DIV : natural := 2 ); 
                 port (  i_clk    : in std_logic;
                         i_reset  : in std_logic;          
                         o_clk    : out std_logic           
           );
       end component clock_divider;
  -- ALU
   component ALU is
       port ( i_op     : in STD_LOGIC_VECTOR (2 downto 0);
              i_A      : in STD_LOGIC_VECTOR (7 downto 0);
              i_B      : in STD_LOGIC_VECTOR (7 downto 0);
              o_flag   : out STD_LOGIC_VECTOR (2 downto 0);
              o_result : out STD_LOGIC_VECTOR (7 downto 0)
       );
    end component ALU;
-- a
component regA is
    Port ( i_load : in STD_LOGIC;
           i_A : in STD_LOGIC_VECTOR (7 downto 0);
           o_A : out STD_LOGIC_VECTOR (7 downto 0));
end component regA;
-- b
component regB is
     Port ( i_load : in STD_LOGIC;
            i_B : in STD_LOGIC_VECTOR (7 downto 0);
            o_B : out STD_LOGIC_VECTOR (7 downto 0));
  end component regB;
-- Signals
signal w_hundreds, w_tens, w_ones, w_sel, w_flag, w_sign, w_data, w_cycle : STD_LOGIC_VECTOR(3 downto 0);
    signal w_reset, w_clk, w_negative : STD_LOGIC;
    signal c_Sa, c_Sb, c_Sc, c_Sd, c_Se, c_Sf, c_Sg : STD_LOGIC := '0';
    signal w_A, w_B, w_result, w_Y : STD_LOGIC_VECTOR(7 downto 0);
 
begin
	-- PORT MAPS ----------------------------------------
ALU_inst: ALU
        port map (
           i_op => sw(2 downto 0),
           i_A => w_A,
           i_B => w_B,
           o_result => w_result,
           o_flag  => led(15 downto 13)
       );
        controller_fsm_inst: controller_fsm
        port map (
           i_reset => btnU,
           i_adv => btnC,
           o_cycle => w_cycle,
           i_clk => clk
        );
        clock_divider_inst: clock_divider
        generic map ( k_DIV => 50000 )
        port map (
            i_clk => clk,
            i_reset => w_reset,
            o_clk => w_clk
        );
        regA_inst: regA
        port map (
            i_A => sw(7 downto 0),
            i_load => w_cycle(0),
            o_A => w_A
        );
        regB_inst: regB
        port map (
            i_B => sw(7 downto 0),
            i_load => w_cycle(1),
            o_B => w_B
        );
        TDM4_inst: TDM4
        generic map ( k_WIDTH => 4)
        Port map ( 
            i_clk        => w_clk,
            i_reset      => '0',
            i_D3(3)      => w_negative,
            i_D3(2)      => '0',
            i_D3(1)      => w_negative,
            i_D3(0)      => '0',
            i_D2         => w_hundreds,
            i_D1         => w_tens,
            i_D0         => w_ones,
            o_data       => w_data,
            o_sel        => w_sel
         );

        twoscomp_decimal_inst: twoscomp_decimal
        port map (
            i_binary => w_Y,
            o_negative => w_negative,
            o_hundreds => w_hundreds,
            o_tens => w_tens,
            o_ones => w_ones
        );
        sevenSegDecoder_inst: sevenSegDecoder
        port map (
            i_D => w_data,
            o_S => seg
        );
        -- CONCURRENT STATEMENTS ----------------------------
        an(3 downto 0) <= x"F" when w_cycle = "0001" else
                          w_sel;
        led(3 downto 0) <= w_cycle;                     
        led(12 downto 4) <= "000000000";
        --mux
        w_Y <= w_A when w_cycle = "0010" else
               w_B when w_cycle = "0100" else
               w_result when w_cycle = "1000" else
               "00000000";
end top_basys3_arch;