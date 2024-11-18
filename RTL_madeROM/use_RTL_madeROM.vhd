library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity use_RTL_madeROM is
    Port (
        clk   : in STD_LOGIC;
		reset : in STD_LOGIC;
		sw1   : in STD_LOGIC;
        hsync : out STD_LOGIC;
        vsync : out STD_LOGIC;
        red   : out STD_LOGIC_VECTOR (3 downto 0);
        green : out STD_LOGIC_VECTOR (3 downto 0);
        blue  : out STD_LOGIC_VECTOR (3 downto 0)
    );
end use_RTL_madeROM;

architecture Behavioral of use_RTL_madeROM is

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
	
	component blk_mem_gen_0 IS
	PORT (
		clka  : IN STD_LOGIC;
		ena   : IN STD_LOGIC;
		wea   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
		addra : IN integer range 0 to 135999;
		dina  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
	END component;
	
	signal block_out : STD_LOGIC_VECTOR(7 downto 0);
	signal addr      : integer range 0 to 135999;
	signal data_in   : STD_LOGIC_VECTOR(7 downto 0);
	
	component my_rom is
	generic (
    data_depth : integer    :=  136000;
    data_bits  : integer    :=   8
	);
	port
	(
		wclk  : in std_logic;
		wen   : in std_logic;
		waddr : in integer range 0 to data_depth-1;
		wdata : in std_logic_vector(data_bits-1 downto 0);

		rclk  : in std_logic;
		raddr : in integer range 0 to data_depth-1;
		rdata : out std_logic_vector(data_bits-1 downto 0)
	);
	end component;
	
	signal w_addr : integer range 0 to 135999;
	signal w_data : STD_LOGIC_VECTOR(7 downto 0);
	signal r_addr : integer range 0 to 135999;
	signal r_data : STD_LOGIC_VECTOR(7 downto 0);
begin

	my_block_ram : blk_mem_gen_0 --對應component
	Port map(
		clka  => fc,
		wea   => "0",
		ena   => '1',
		addra => addr,
		dina  => data_in,
		douta => block_out
		);
	
	my_RTL_rom : my_rom
	Port map(
		wclk  => fc,
		wen   => '1',
		waddr => w_addr,
		wdata => w_data,
		
		rclk  => fc,
		raddr => r_addr,
		rdata => r_data
		);
	
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
	
	process(hCount, vCount, reset, fc) --寫入資料
	begin
		if reset = '1' then
			addr   <= 0;
			w_addr <= 0;
		elsif rising_edge(fc) then
			if (hCount <= hRez and vCount <= vRez) then
				if(hCount >= 0 and hCount <= 399 and vCount >= 0 and vCount <= 339) then
					addr   <= addr + 1;
					w_addr <= w_addr + 1;
					w_data <= block_out(7 downto 0);	
				elsif (hCount = 400 and vCount = 340) then
					addr   <= 0;
					w_addr <= 0;
				end if;
			end if;
		end if;
	end process;
	
    -- Generate RGB signals
    process(hCount, vCount, fc, reset)
    begin	
		if reset = '1' then
			r_addr  <= 0;	
        elsif rising_edge(fc) then
			if (hCount <= hRez and vCount <= vRez) then
				if (hCount >= 0 and hCount <= 399 and vCount >= 0 and vCount <= 339) then
					r_addr <= r_addr + 1;
					red    <=  "1111" - r_data(7 downto 4); 
					green  <=  "1111" - r_data(7 downto 4);
					blue   <=  "1111" - r_data(7 downto 4);
				elsif (hCount = 400 and vCount = 340) then
					r_addr  <= 0;
				else
					red   <= "0000"; 
					green <= "0000";
					blue  <= "0000";
				end if;
			end if;
		end if;
    end process;

end Behavioral;