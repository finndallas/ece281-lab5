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
        btnL    :   in std_logic; -- clock reset
        btnC    :   in std_logic; -- fsm cycle
        -- outputs
        led     :   out std_logic_vector(15 downto 0);
        seg     :   out std_logic_vector(6 downto 0);
        an      :   out std_logic_vector(3 downto 0)
    );
end top_basys3;
 
architecture top_basys3_arch of top_basys3 is
 
    
 
    component ALU is
        Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
               i_B : in STD_LOGIC_VECTOR (7 downto 0);
               i_op : in STD_LOGIC_VECTOR (2 downto 0);
               o_result : out STD_LOGIC_VECTOR (7 downto 0);
               o_flags : out STD_LOGIC_VECTOR (3 downto 0));
    end component;
 
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component;
 
    component controller_fsm is
        Port ( i_reset : in STD_LOGIC;
               i_adv : in STD_LOGIC;
               o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
    end component;
 
    component TDM4 is
        generic ( constant k_WIDTH : natural := 4);
        Port ( i_clk : in STD_LOGIC;
               i_reset : in STD_LOGIC;
               i_D3 : in STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D2 : in STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D1 : in STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               i_D0 : in STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_data : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
               o_sel : out STD_LOGIC_VECTOR (3 downto 0));
    end component;
 
    component clock_divider is
        generic ( constant k_DIV : natural := 2);
        port (  i_clk    : in std_logic;
                i_reset  : in std_logic;
                o_clk    : out std_logic);
    end component;
 
    component twos_comp is
        port (
            i_bin: in std_logic_vector(7 downto 0);
            o_sign: out std_logic;
            o_hund: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
        );
    end component;
 
 
 --signals--
    signal w_clk : std_logic;
    signal w_clk_TDM : std_logic;
    signal w_clk_reset : std_logic;
 
    signal w_data : std_logic_vector(3 downto 0);
 
    -- FSM
    signal w_cycle : std_logic_vector(3 downto 0);
 
    -- ALU
    signal w_A, w_B : std_logic_vector(7 downto 0);
    signal w_op : std_logic_vector(2 downto 0);
    signal w_result : std_logic_vector(7 downto 0);
    signal w_flags : std_logic_vector(3 downto 0);
 
    -- Two's complement
    signal w_sign : std_logic_vector(3 downto 0);
    signal w_sign_bit : std_logic;
    signal w_bin : std_logic_vector(7 downto 0);
    signal w_hund, w_tens, w_ones : std_logic_vector(3 downto 0);
    signal w_sign_display : std_logic_vector(6 downto 0);
 
    -- Sevenseg display stuff
    signal w_seg : std_logic_vector(6 downto 0);
    signal w_sel: std_logic_vector(3 downto 0);
 
    -- MUX controlled operands
    signal w_mux_A : std_logic_vector(7 downto 0);
    signal w_mux_B : std_logic_vector(7 downto 0);
 
begin
 
 
    --instantiations--
    clock_divider_TDM_inst : clock_divider
        generic map (k_div => 50000)
        port map(
            i_clk => clk,
            i_reset => btnL,
            o_clk => w_clk_TDM
        );
 
 
    controller_fsm_inst : controller_fsm
        port map (
            i_reset => btnU,
            i_adv => btnC,
            o_cycle => w_cycle
        );
 
--    w_mux_A <= sw(7 downto 0) when w_cycle(1) = '1' else (others => '0');
--    w_mux_B <= sw(7 downto 0) when w_cycle(2) = '1' else (others => '0');
 
    ALU_inst : ALU
        port map (
            i_A => w_A,
            i_B => w_B,
            i_op => sw(2 downto 0),
            o_result => w_result,
            o_flags => led(15 downto 12)
        );
 
 
 
    twos_comp_inst : twos_comp
        port map (
            i_bin => w_bin,
            o_sign => w_sign_bit,
            o_hund => w_hund,
            o_tens => w_tens,
            o_ones => w_ones
        );
 
    w_sign <= "1111";
 
    TDM4_inst : TDM4
        port map (
            i_clk => w_clk_TDM,
            i_reset => btnU,
            i_D3 => w_sign,
            i_D2 => w_hund,
            i_D1 => w_tens,
            i_D0 => w_ones,
            o_data => w_data,
            o_sel => an
        );
 
    sevenseg_decoder_inst : sevenseg_decoder
        port map (
            i_Hex => w_data,
            o_seg_n => w_seg
        );
        
        --Concurrent statements--
        
        with w_cycle select --big blue mux
            w_bin <= w_A when "0010",
                     w_B when "0100",
                     w_result when "1000",
                     "00000000" when others;
        
        w_sign_display <= "0111111" when w_sign_bit = '1' else "1111111";
        
        with w_sel select
            seg <= w_sign_display when "0111",
                   w_seg when others;
        
        an <= w_sel;
        
        register_A : process(w_cycle(1)) --first big blue register
        begin
            if rising_edge(w_cycle(1)) then
                w_A <= sw(7 downto 0);
            end if;
        end process register_A;
        
        register_B : process(w_cycle(1)) --second big blue register
        begin
            if rising_edge(w_cycle(2)) then
                w_B <= sw(7 downto 0);
            end if;
        end process register_B;
        
        led(3 downto 0) <= w_cycle;  
        led(11 downto 4) <= (others => '0');
        
 
end top_basys3_arch;

 