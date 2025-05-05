----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;
 
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
 
entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0); --ALU control
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;
 
architecture Behavioral of ALU is
 
    signal sum, or_op, and_op, b_new, result : std_logic_vector(7 downto 0);
begin
 
    or_op <= i_A or i_B; --result of or
    and_op <= i_A and i_B; --result of and
    b_new <= (not i_B) when (i_op(0) = '1') else --flip i_B and get the sum if need to subtract
             i_B;
    result <= sum when ((i_op = "000") or (i_op = "001")) else --mux to select the result
              and_op when (i_op = "010") else
              or_op when (i_op = "011") else
              sum;
    o_result <= result;
    --NZCV
    o_flags(3) <= result(7); --N flag
    o_flags(2) <= not (result(0) or result(1) or result(2) or result(3) or result(4) or result(5) or result(6) or result(7)); --Z flag
    o_flags(0) <= (not i_op(1)) and (sum(7) xor i_A(7)) and (not (i_op(0) xor i_A(7) xor i_B(7))); --V flag

 
end Behavioral;