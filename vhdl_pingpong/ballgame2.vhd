library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;



entity ballgame2 is
	port(	clk,reset          :in std_logic;
			btn1,btn2,btn3,btn4:in std_logic;
			x1,x2              :out std_logic_vector(6 downto 0);
			q                  :out std_logic_vector(7 downto 0)
		);
end ballgame2;

architecture Behavioral of ballgame2 is

	type state is(initial,sel,ball_r,ball_l,play1score,play2score,p1win,p2win);
	signal div  		:std_logic_vector(60 downto 0);--除頻使用的信號
	signal fc   		:std_logic;
	
	signal score1,score2:std_logic_vector(3 downto 0);
	signal ball 		:std_logic_vector(7 downto 0);
	signal current_state:state;
	
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
	
	move:process(fc,reset)
	begin
		if reset='1' then          --reset
			current_state<=initial;
		elsif rising_edge(fc) then
			case current_state is
				when initial   =>  --初始
					score1<="0000";
					score2<="0000";
					ball<="00000000";
					if btn3='1' then
						current_state<=sel;
					end if;
				when sel       =>  --選擇誰發球
					ball<=score2&score1;
					if    btn1='1' then
						ball<="00000001";
						current_state<=ball_r;
					elsif btn2='1' then
						ball<="10000000";
						current_state<=ball_l;
					end if;
				when ball_r    =>  --右移與判斷是否有無接球
					ball<=ball(6 downto 0)&ball(7);	
					if ball="10000000" then
						if    btn2='1' then
							ball<="10000000";
							current_state<=ball_l;
						elsif btn2='0' then
							ball<="00000000";
							current_state<=play1score;
						end if;
					end if;
				when ball_l    =>  --左移與判斷是否有無接球
					ball<=ball(0)&ball(7 downto 1);
					if ball="00000001" then
						if    btn1='1' then
							ball<="00000001";
							current_state<=ball_r;
						elsif btn1='0' then
							ball<="00000000";
							current_state<=play2score;
						end if;
					end if;
				when play1score=>  --play1得分
					score1<=score1+1;
					if score1="0011" then
						current_state<=p1win;
					else current_state<=sel;
					end if;
				when play2score=>  --play2得分
					score2<=score2+1;
					if score2="0011" then
						current_state<=p2win;
					else current_state<=sel;
					end if;
				when p1win     =>  --play1 win
					ball<="00000001";
					if btn4='1' then
						current_state<=initial;
					end if;
				when p2win     =>  --play2 win
					ball<="10000000";
					if btn4='1' then
						current_state<=initial;
					end if;
			end case;
		end if;
	end process move;
	q<=ball;
	with score1 select
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
	with score2 select
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
