library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity VGA_Controller is
    Port (
        clk   : in STD_LOGIC;
		reset : in STD_LOGIC;
        hsync : out STD_LOGIC;
        vsync : out STD_LOGIC;
        red   : out STD_LOGIC_VECTOR (3 downto 0);
        green : out STD_LOGIC_VECTOR (3 downto 0);
        blue  : out STD_LOGIC_VECTOR (3 downto 0)
    );
end VGA_Controller;

architecture Behavioral of VGA_Controller is

    -- VGA 640x480 @ 60 Hz timing parameters
    constant hRez        : integer := 640;  -- horizontal resolution
    constant hStartSync  : integer := 656;  -- start of horizontal sync pulse
    constant hEndSync    : integer := 752;  -- end of horizontal sync pulse
    constant hMaxCount   : integer := 800;  -- total pixels per line

    constant vRez        : integer := 480;  -- vertical resolution
    constant vStartSync  : integer := 490;  -- start of vertical sync pulse
    constant vEndSync    : integer := 492;  -- end of vertical sync pulse
    constant vMaxCount   : integer := 525;  -- total lines per frame

    signal hCount : integer := 0;
    signal vCount : integer := 0;
	
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

    -- Generate synchronization signals
    hsync <= '0' when (hCount >= hStartSync and hCount < hEndSync) else '1';
    vsync <= '0' when (vCount >= vStartSync and vCount < vEndSync) else '1';

    -- Generate RGB signals
    process(hCount, vCount)
    begin		
        if (hCount < hRez and vCount < vRez) then
            -- Horizontal stripes for RGB
            if (hCount < hRez / 3) then
                red <= "1111";  -- Red stripe
                green <= "0000";
                blue <= "0000";
            elsif (hCount < 2 * hRez / 3) then
                red <= "0000";
                green <= "1111";  -- Green stripe
                blue <= "0000";
            else
                red <= "0000";
                green <= "0000";
                blue <= "1111";  -- Blue stripe
            end if;
        end if;
    end process;

end Behavioral;