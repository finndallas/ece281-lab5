----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
 
 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
 
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
 
entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0)); --one hot
end controller_fsm;
 
architecture FSM of controller_fsm is
 
    signal   f_sel  : unsigned(1 downto 0):= "00";
 
begin
    controller_proc : process(i_adv, i_reset)
	begin
		if i_reset = '1' then
			f_sel <= "00";
		elsif i_adv = '1' then
			f_sel <= f_sel + 1;
		end if;
	end process controller_proc;
 
 
    o_cycle <= "0001" when f_sel = "00" else
               "0010" when f_sel = "01" else
               "0010" when f_sel = "10" else
               "0010" when f_sel = "11" else
               "0001";
 
end FSM;