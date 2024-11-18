library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vga_test is
    Port (
        clk   : in STD_LOGIC;
		reset : in STD_LOGIC;
		sw1   : in std_logic; --無作用
		sw2   : in std_logic; --重製板子位置
		btn1  : in STD_LOGIC; --發球
		up1   : in STD_LOGIC; --板子1上
		down1 : in STD_LOGIC; --板子1下
		up2   : in STD_LOGIC; --板子2上
		down2 : in STD_LOGIC; --板子2下
        hsync : out STD_LOGIC;
        vsync : out STD_LOGIC;
        red   : out STD_LOGIC_VECTOR (3 downto 0);
        green : out STD_LOGIC_VECTOR (3 downto 0);
        blue  : out STD_LOGIC_VECTOR (3 downto 0)
    );
end vga_test;


architecture Behavioral of vga_test is
    -- VGA 640x480 @ 60 Hz timing parameters
    constant hRez        : integer := 640;  -- horizontal resolution
	constant h_front	 : integer := 16;   -- front porch
	constant h_pulse	 : integer := 96;   -- sync pulse
	constant h_back      : integer := 48;   -- back porch
    constant hMaxCount   : integer := 800;  -- total pixels per line

    constant vRez        : integer := 480;  -- vertical resolution
	constant v_front	 : integer := 11;   -- front porch
	constant v_pulse	 : integer := 2;   	-- sync pulse
	constant v_back      : integer := 31;   -- back porch
    constant vMaxCount   : integer := 525;  -- total lines per frame
	

    signal hCount : integer := 0;
    signal vCount : integer := 0;
	
	constant ball_r      : integer := 10;  -- 球的半徑
	constant ball_speedx : integer := 3;   -- 球水平速度
	constant ball_speedy : integer := 2;   -- 球垂直速度
	signal ball_ox       : integer := 320; -- 球的初始座標
	signal ball_oy       : integer := 240; -- 球的初始座標
	signal ball_x 		 : integer range -10 to hRez + 10;  -- 球的X座標
    signal ball_y 		 : integer range -10 to vRez + 10;  -- 球的Y座標
	signal ball_dx       : integer range -10 to 10 :=ball_speedx;	--訊號
	signal ball_dy       : integer range -10 to 10 :=ball_speedy;
	
	constant bat         : integer := 10; -- 球拍大小
	constant backbat     : integer  := 20; -- 球拍背板
	constant bat_speed   : integer := 10;  -- 球拍速度
	signal bat_ly1       : integer range 0 to vRez; --左邊球拍y1的座標
	signal bat_ly2       : integer range 0 to vRez; --左邊球拍y2的座標
	signal bat_ry1       : integer range 0 to vRez; --右邊球拍y1的座標
	signal bat_ry2       : integer range 0 to vRez; --右邊球拍y2的座標
	signal bat_dy1       : integer range -10 to 10 :=bat_speed;	--訊號
	signal bat_dy2       : integer range -10 to 10 :=bat_speed;
	signal bat_oy1       : integer := 180; -- 球拍的初始座標
	signal bat_oy2       : integer := 300; -- 球拍的初始座標
	signal upborder      : integer := 120;
	signal downborder    : integer := 360;
	
	signal score1        : integer range 0 to 3 :=0;
	signal score2        : integer range 0 to 3 :=0; 
	signal heart_y       : integer :=  20;
	signal color_r       : STD_LOGIC_VECTOR(3 downto 0);
	signal color_b       : STD_LOGIC_VECTOR(3 downto 0);
	
	type state is(initial,move_pp,move_np,move_nn,move_pn,plus1,plus2,restart);
	signal current_state:state;
	
	signal div    : STD_LOGIC_VECTOR(60 downto 0);
	signal fc     : STD_LOGIC;

begin
	process(clk)
	begin
		if reset='1' then 
			div<=(others=>'0');
		elsif rising_edge(clk) then 
			div<=div+1;
		End if;
	end process;
	fc<=div(1);
	
    process(fc)
    begin
		if reset='1' then
			hCount <= 0;
			vCount <= 0;
		end if;
        if rising_edge(fc) then
            -- Horizontal counter
            if hCount = hMaxCount - 1 then
                hCount <= 0;
                -- Vertical counter
                if vCount = vMaxCount - 1 then
                    vCount <= 0;
                else
                    vCount <= vCount + 1;
                end if;
            else
                hCount <= hCount + 1;
            end if;
        end if;
    end process;
	
	process(fc)
	begin
		if reset='1' then
			current_state <= initial;
		elsif rising_edge(fc) then
			case current_state is
				when initial =>
					ball_x <= ball_ox;
					ball_y <= ball_oy;
					score1 <= 0;
					score2 <= 0;
					if btn1 = '1' then
						current_state <= move_pp;
					end if;
				when move_pp =>
					if hCount = hMaxCount - 1 and vCount = vMaxCount - 1 then
						ball_x <= ball_x + ball_dx;	--訊號+訊號
						ball_y <= ball_y + ball_dy;
						if ball_x >= hRez-backbat and ball_y <= bat_ry2 and ball_y >= bat_ry1 then
							current_state <= move_np;
						elsif ball_x > hRez then
							current_state <= plus1;
						elsif ball_y > vRez then
							current_state <= move_pn;
						end if;
					end if;
				when move_np =>
					if hCount = hMaxCount - 1 and vCount = vMaxCount - 1 then
						ball_x <= ball_x - ball_dx;
						ball_y <= ball_y + ball_dy;
						if ball_x <= backbat and ball_y <= bat_ly2 and ball_y >= bat_ly1 then
							current_state <= move_pp;						
						elsif ball_y > vRez then
							current_state <= move_nn;
						elsif ball_x < 0 then
							current_state <= plus2;
						end if;
					end if;
				when move_nn =>
					if hCount = hMaxCount - 1 and vCount = vMaxCount - 1 then
						ball_x <= ball_x - ball_dx;
						ball_y <= ball_y - ball_dy;
						if ball_x <= backbat and ball_y <= bat_ly2 and ball_y >= bat_ly1 then
							current_state <= move_pn;
						elsif ball_y < 0 then
							current_state <= move_np;
						elsif ball_x < 0 then
							current_state <= plus2;
						end if;
					end if;
				when move_pn =>
					if hCount = hMaxCount - 1 and vCount = vMaxCount - 1 then
						ball_x <= ball_x + ball_dx;
						ball_y <= ball_y - ball_dy;
						if ball_x >= hRez-backbat and ball_y <= bat_ry2 and ball_y >= bat_ry1 then 
							current_state <= move_nn;
						elsif ball_x > hRez then
							current_state <= plus1;
						elsif ball_y < 0 then
							current_state <= move_pp;
						end if;
					end if;
				when plus1 =>
					score1 <= score1 + 1;
					current_state <= restart;
				when plus2 =>
					score2 <= score2 + 1;
					current_state <= restart;
				when restart =>
					ball_x <= ball_ox;
					ball_y <= ball_oy;
					if score1 = 3 then
						if btn1 = '1' then
							current_state <= initial;
						end if;
					elsif score2 = 3 then
						if btn1 = '1' then 
							current_state <= initial;
						end if;
					else 
						if btn1 = '1' then
							current_state <= move_nn;
						end if;
					end if;
			end case;
		end if;
	end process;
	
	process(fc)
	begin
	if sw2 = '1' then 
		bat_ly1 <= bat_oy1; bat_ry1 <= bat_oy1;
		bat_ly2 <= bat_oy2; bat_ry2 <= bat_oy2;
	end if;
	if rising_edge(fc) then
		if hCount = hMaxCount - 1 and vCount = vMaxCount - 1 and up1 = '1' then
			bat_ly1 <= bat_ly1 - bat_dy1;
			bat_ly2 <= bat_ly2 - bat_dy2;
			if bat_ly1 = 0 then 
				bat_ly1 <= 0 ;
				bat_ly2 <= upborder ;
			end if;
		elsif hCount = hMaxCount - 1 and vCount = vMaxCount - 1 and down1 = '1' then
			bat_ly1 <= bat_ly1 + bat_dy1;
			bat_ly2 <= bat_ly2 + bat_dy2;
			if bat_ly2 = vRez then
				bat_ly1 <= downborder;
				bat_ly2 <= 480;
			end if;
		end if;
		if hCount = hMaxCount - 1 and vCount = vMaxCount - 1 and up2 = '1' then
			bat_ry1 <= bat_ry1 - bat_dy1;
			bat_ry2 <= bat_ry2 - bat_dy2;
			if bat_ry1 = 0 then
				bat_ry1 <= 0;
				bat_ry2 <= upborder;
			end if;
		elsif hCount = hMaxCount - 1 and vCount = vMaxCount - 1 and down2 = '1' then
			bat_ry1 <= bat_ry1 + bat_dy1;
			bat_ry2 <= bat_ry2 + bat_dy2;
			if bat_ry2 = vRez then
				bat_ry1 <= downborder;
				bat_ry2 <= 480;
			end if;
		end if;
	end if;
	end process;	

    -- Generate synchronization signals
    hsync <= '0' when (hCount >= (hRez + h_front) and hCount < (hRez + h_front + h_pulse)) else '1';
    vsync <= '0' when (vCount >= (vRez + v_front) and vCount < (vRez + v_front + v_pulse)) else '1';
    -- Generate RGB signals
    process(hCount, vCount)
    begin
        if (hCount <= hRez and vCount <= vRez) then
            -- Horizontal stripes for RGB
			if (hCount - ball_x)**2 + (vCount - ball_y)**2 <= ball_r**2 then
				green <= "1111";
			end if;
			if (hCount <= bat and hCount >= 0 and vCount >= bat_ly1 and vCount <= bat_ly2) then 
                blue  <= "1111";
			end if;
			if (hCount >= hRez-bat and hCount <= hRez and vCount >= bat_ry1 and vCount <= bat_ry2) then
				red   <= "1111";
			end if;
			
			if score1 = 1 then
				if (vCount >= 10 and vCount <= heart_y ) and (hCount >= 20 and hCount <= 30) then
					blue  <= "1111";
				end if;
			elsif score1 = 2 then
				if (vCount >= 10 and vCount <= heart_y ) and ((hCount >= 20 and hCount <= 30) or (hCount >= 40 and hCount <= 50) )  then
					blue  <= "1111";
				end if;
			elsif score1 = 3 then
				if (vCount >= 10 and vCount <= heart_y ) and ((hCount >= 20 and hCount <= 30) or (hCount >= 40 and hCount <= 50) or (hCount >= 60 and hCount <= 70))  then
					blue  <= "1111";
				end if;
			end if;
			
			if score2 = 1 then
				if (vCount >= 10 and vCount <= heart_y ) and (hCount <= hRez - 20 and hCount >= hRez - 30) then
					red  <= "1111";
				end if;
			elsif score2 = 2 then
				if (vCount >= 10 and vCount <= heart_y ) and ((hCount <= hRez - 20 and hCount >= hRez - 30) or (hCount <= hRez - 40 and hCount >= hRez - 50) )  then
					red  <= "1111";
				end if;
			elsif score2 = 3 then
				if (vCount >= 10 and vCount <= heart_y ) and ((hCount <= hRez - 20 and hCount >= hRez - 30) or (hCount <= hRez - 40 and hCount >= hRez - 50) or (hCount <= hRez - 60 and hCount >= hRez - 70))  then
					red  <= "1111";
				end if;
			end if;
			
		else 
			red   <= "0000";
			green <= "0000";
            blue  <= "0000";
        end if;
		
    end process;
end Behavioral;