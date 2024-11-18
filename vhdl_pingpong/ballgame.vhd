library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity ballgame is
	port(	clk,reset	  :in std_logic;
			btn1,btn2,btn3:in std_logic;
			x1,x2         :out std_logic_vector(6 downto 0);
			q			  :out std_logic_vector(7 downto 0)
		);
end ballgame;

architecture Behavioral of ballgame is
	signal div  :std_logic_vector(60 downto 0);
	signal fc   :std_logic;
	
	signal in1  :integer range 0 to 1;
	signal state:integer range 0 to 16;
	
	signal play1:std_logic_vector(3 downto 0);
	signal play2:std_logic_vector(3 downto 0);
	
	signal ball :std_logic_vector(7 downto 0);
	
begin
	process(clk,reset)
	begin
		if reset='1' then
			div<=(others=>'0');	
		elsif rising_edge(clk) then
			div<=div+1;
		End if;
	end process;
	fc<=div(24);
	
	process(fc)
	begin
		if rising_edge(fc) then
			case state is
				when 16=>                  --初始狀態
					ball<="00000000";
					if btn1='1' then
						state<=0;
					elsif btn2='1' then
						state<=15;
					end if;
					
				when 0=>
					ball<="00000000";     --從左邊發球
					if btn1='1' then
						state<=1;
					end if;
					
				when 15=>                 --從右邊發球
					if btn2='1' then
						in1<=1;
						ball<="10000000";
						state<=8;
					end if;
				
				when 1=>
					if in1=0 then
						ball<="00000001";
						state<=2;
					elsif in1=1 then
						if btn1='1' then
							in1<=0;
							state<=2;
						elsif btn1='0' then
							state<=11;
						end if;
					end if;
				
				when 2=>
					if in1=0 then
						ball<="00000010";
						state<=3;
					elsif in1=1 then
						ball<="00000001";
						state<=1;
					end if;
					
				when 3=>
					if in1=0 then
						ball<="00000100";
						state<=4;
					elsif in1=1 then
						ball<="00000010";
						state<=2;
					end if;
					
				when 4=>
					if in1=0 then
						ball<="00001000";
						state<=5;
					elsif in1=1 then
						ball<="00000100";
						state<=3;
					end if;
					
				when 5=>
					if in1=0 then
						ball<="00010000";
						state<=6;
					elsif in1=1 then
						ball<="00001000";
						state<=4;
					end if;
					
					
				when 6=>
					if in1=0 then
						ball<="00100000";
						state<=7;
					elsif in1=1 then
						ball<="00010000";
						state<=5;
					end if;
					
				when 7=>
					if in1=0 then
						ball<="01000000";
						state<=8;
					elsif in1=1 then
						ball<="00100000";
						state<=6;
					end if;
				
				when 8=>
					if in1=0 then
						ball<="10000000";
						state<=9;
					elsif in1=1 then
						ball<="01000000";
						state<=7;
					end if;
					
				when 9=>
					if btn2='1' then
						in1<=1;
						state<=8;
					elsif btn2='0' then
						state<=10;
					end if;
				
				when 10=>
					ball<="00000000";
					play1<=play1+1;
					if play1="0011" then
						state<=12;
					else state<=0;
					end if;
					
				when 11=>
					ball<="00000000";
					play2<=play2+1;
					if play2="0011" then
						state<=13;
					else state<=15;
					end if;

				when 12=>
					ball<="00001111";
					if btn3='1' then
						state<=14;
					end if;
					
				when 13=>
					ball<="11110000";
					if btn3='1' then					
						state<=14;
					end if;
					
				when 14=>
					play1<="0000";
					play2<="0000";
					state<=16;
				

			end case;
		end if;
	end process;
	

	q<=ball;
	with play1 select
		x1<="1111110" when "0000",
			"0110000" when "0001",
			"1101101" when "0010",
			"1111001" when "0011",
			"1111001" when "0100",
			"1011011" when "0101",
			"1011111" when "0110",
			"1110000" when "0111",
			"1111111" when "1000",
			"1111011" when "1001",
			"0000000" when others;
	with play2 select
		x2<="1111110" when "0000",
			"0110000" when "0001",
			"1101101" when "0010",
			"1111001" when "0011",
			"1111001" when "0100",
			"1011011" when "0101",
			"1011111" when "0110",
			"1110000" when "0111",
			"1111111" when "1000",
			"1111011" when "1001",
			"0000000" when others;

end Behavioral;
