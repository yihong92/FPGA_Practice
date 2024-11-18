library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;


entity I2C_practice is

	port(
		clk    		: in std_logic;
		reset  		: in std_logic;
		SCL    		: inout std_logic;
		SDA         : inout std_logic;
		sw1         : in std_logic;	--control led
		sw2   	    : in std_logic;	--control led
		sw3 	    : in std_logic;	--control led
		sw4         : in std_logic;	--control led
		RW          : in std_logic; --'0' write '1' read
		btn_start   : in std_logic; --start
		re_idle     : in std_logic;
		btn_tansmit : in std_logic; --tansmit
		sw5         : in std_logic; --master or slave
		led         : out std_logic_vector(7 downto 0)
		);
end I2C_practice;

architecture Behavioral of I2C_practice is
	signal addr    : std_logic_vector(6 downto 0);  --slave address
	signal addr_rw : std_logic_vector(7 downto 0);  
	signal ack     : std_logic;
	signal data_mw : std_logic_vector(7 downto 0);  --master data write
	signal data_mr : std_logic_vector(7 downto 0);  --master data read
	
	signal addr_s  : std_logic_vector(7 downto 0);  --slave address
	signal data_sr : std_logic_vector(7 downto 0);  --slave data read
	signal data_sw : std_logic_vector(7 downto 0);  --slave data write
	
	signal sda_ena_n : std_logic;
	signal scl_ena   : std_logic;
	signal sda_s     : std_logic;
	
	
	type state_type is (idle, master, address, wr, no_ack, rd, ack_mw, ack_mr, slave, s_address, ack_saddr
	                    , srd, swr, ack_sr, ack_sw, select_ms, ack_addr_w, ack_addr_r );
	signal state : state_type;
	
	
	signal mcount : integer := 0;
	signal scount : integer := 0;
	signal ena    : integer := 0;
	signal error  : integer := 0;
	signal correct: integer := 0;
	signal wena   : integer := 0;
	signal rena   : integer := 0;	
	
	signal q     : std_logic_vector(7 downto 0);
	
	signal div    : STD_LOGIC_VECTOR(60 downto 0);
	signal fc     : STD_LOGIC;
	
begin
	process(clk, reset, sw1, sw2, sw3, sw4) 
	begin
		if reset = '1' then
			q <= "00000000";
		elsif rising_edge(clk) then 
			if sw1 = '1' then
				q <= "11110001";
			elsif sw2 = '1' then
				q <= "00110000";
			elsif sw3 = '1' then
				q <= "00001100";
			elsif sw4 = '1' then
				q <= "00000011";
			else 
				q <= "00001111";
			end if;
		end if;
	end process;
	
	SCL <= '0' WHEN (scl_ena = '1' AND fc = '0') ELSE 'Z';  --fc
	SDA <= '0' WHEN sda_ena_n = '0' ELSE 'Z';
	addr      <= "1110001";
				
	process(reset, clk, btn_start, SCL, sw5, btn_tansmit, RW)
	begin
		if reset = '1' then
			state  <= idle;
		elsif rising_edge(clk) then
			case state is
				when idle =>
					if btn_start = '1' then
						state <= select_ms;
					else 
						state <= idle;
					end if;
				
				when select_ms =>  
					if sw5 = '1' then
						state <= master;
					elsif sw5 = '0'then 
						state <= slave;
					end if;
					
				when master =>
					if ena = 1 then
						state <= address;
					end if;
					
				when address =>
					if ena = 0 and wena = 1 then
						state <= ack_addr_w;
					elsif ena = 0 and rena = 1 then
						state <= ack_addr_r;
					else
						if SCL = '0' then
							state <= address;
						end if;
					end if;
					
				when ack_addr_w =>
					if ena = 1 and correct = 1 then
						state <= wr;
					end if;
												
				when wr =>
					if ena = 0 then
						state <= ack_mw;
					else
						if SCL = '0' then
							state <= wr;
						end if;
					end if;	
					
				when ack_mw =>
					if correct = 1 then
						state <= idle;
					end if;	
					
				when ack_addr_r =>
					if ena = 1 and correct = 1 then
						state <= rd;
					end if;
					
				when rd =>
					if ena = 0 then
						state <= ack_mr;
					else 
						if SCL = '0' then
							state <= rd;
						end if;
					end if;	
				
				when ack_mr =>
					if correct = 1 then
						state <= idle;
					elsif error = 1 then 
						state <= no_ack;
					end if;	
				
				when no_ack =>
					if re_idle = '1' then
						state <= idle;
					end if;	

				when slave =>
					if ena = 1 then
						state <= s_address;
					end if;
			
				when s_address =>
					if ena = 0 and correct = 1 then 
						state <= ack_saddr;
					elsif error = 1 then
						state <= no_ack;
					else 
						if SCL = '0' then
							state <= s_address;
						end if;
					end if;	
					
				when ack_saddr =>
					if addr_s(0) = '0' then
						if ena = 1 then
							state <= srd;
						end if;
					elsif addr_s(0) = '1' then
						if ena = 1 then
							state <= swr;
						end if;
					end if;
									
				when srd =>
					if ena = 0 then
						state <= ack_sr;
					else 
						if SCL = '0' then
							state <= srd;
						end if;
					end if;
					
				when swr =>
					if ena = 0 then
						state <= ack_sw;
					else
						if SCL = '0' then
							state <= swr;
						end if;
					end if;
					
				when ack_sr =>
					if correct = 1 then
						state <= idle;
					elsif error = 1 then
						state <= no_ack;
					end if;
					
				when ack_sw =>
					if correct = 1 then
						state <= idle;
					end if;
					
			end case;
		end if;
	end process;

	process(fc, reset, sda_s, SCL, RW, btn_start, btn_tansmit, sw5) -- fc
	begin
		if reset = '1' then
			scl_ena   <= '0';
		    sda_ena_n <= '1';
			data_sr   <= "00000000";
			data_mr   <= "00000000";
			mcount    <= 8;
			scount    <= 8;
			ena       <= 0;
			correct   <= 0;
			error     <= 0;
			addr_rw   <= addr & RW;
			wena      <= 0;
			rena      <= 0;
			data_sw   <= q;
			data_mw   <= q;
			led       <= "00000000";
			
		elsif rising_edge(fc) then --fc
			case state is
				when idle =>
					scl_ena   <= '0';
					sda_ena_n <= '1';
					data_sr   <= "00000000";
					data_mr   <= "00000000";
					mcount    <= 8;
					scount    <= 8;
					ena       <= 0;
					addr_rw   <= addr & RW;
					correct   <= 0;
					error     <= 0;
					wena      <= 0;
					rena      <= 0;
					data_sw   <= q;
					data_mw   <= q;
					
				when select_ms => 

				when master =>
					led       <= "10000000";
					if btn_tansmit = '1' then
						sda_ena_n <= '0';  --condition start
						scl_ena   <= '1';
						ena       <= 1;
					end if;
										
				when address =>
					if mcount = 0 then
						ena       <= 0;
						sda_ena_n <= '1';
						led       <= "00000010";
						mcount    <= 8;
						if RW = '0' then
							if sda_s = '0' then
								wena      <= 1;
							end if;
						elsif RW = '1' then
							rena      <= 1;
						end if;
					else
						sda_ena_n <= addr_rw(mcount-1);
						mcount    <= mcount - 1;
					end if;
					
				when ack_addr_w =>
						sda_ena_n <= data_mw(mcount-1);
						mcount    <= mcount - 1;
						correct   <= 1;
						ena       <= 1;
						led <= "00000100";
					
				when wr =>
					sda_ena_n <= data_mw(mcount-1);
					mcount    <= mcount - 1;
					if mcount = 1 then
						ena       <= 0;
						correct   <= 0;
						led <= "00001000";
					end if;
	
				when ack_mw =>
					if sda_s = '0' then
						correct <= 1 ;
						sda_ena_n <= '1';
						scl_ena   <= '0';
						led <= "00000000";
					end if;
					
				when ack_addr_r =>
					if sda_s = '0' then
						ena     <= 1;
						correct <= 1;
						led <= "00001000";
					end if;
				
				when rd =>
					data_mr(mcount-1) <= sda_s;
					mcount            <= mcount - 1;
					if mcount = 1 then
						ena    <= 0;
						correct<= 0;
						sda_ena_n <= '0'; 
						led <="00100000";
					end if;

				when ack_mr =>
					if (data_mr = data_sw) then
						sda_ena_n <= '1';
						scl_ena   <= '0';
						correct   <= 1;
						led <= data_mr;
					else 
						error     <= 1;
					end if;
					
				when no_ack =>
					led <= data_mr;
					
				when slave =>
					led       <= "00000001";
					sda_ena_n <= '1';
					if SCL = '0' then
						ena <= 1;
					end if;
										
				when s_address =>						
					addr_s(scount - 1) <= sda_s;
					scount             <= scount - 1;
					if scount = 1 then
						scount    <= 8;
						led <= "00000010";
						if (addr_s(7 downto 1) = addr) then
							sda_ena_n <= '0';
							ena       <= 0;
							correct   <= 1;
						else
							sda_ena_n <= '1';
							error <= 1;
						end if;
					end if;

				when ack_saddr =>
					if addr_s(0) = '0' then
							sda_ena_n <= '1';
							ena       <= 1;
							led <= "00000100";
					elsif addr_s(0) = '1' then
							ena       <= 1;
							led <= addr_s;
					end if;

														
				when srd =>
					data_sr(scount-1) <= sda_s;
					scount            <= scount - 1;
					if scount = 1 then
						ena       <= 0;
						led <= "00001000";
						correct         <= 0;
						sda_ena_n <= '0'; 
					end if;
								
				when swr =>
					sda_ena_n <= data_sw(scount - 1);
					scount    <= scount - 1;
					if scount = 1 then
						ena       <= 0;
						correct   <= 0;
						led<= "00010000";
					end if;
					
					
				when ack_sr =>
					if (data_sr = data_mw) then
						sda_ena_n <= '1';
						led       <= data_sr;
						correct   <= 1;
					else 
						error <= 1;
					end if;
				
				when ack_sw =>
					sda_ena_n <= '1';
					if sda_s = '0' then
						correct   <= 1 ;
						
						led<= "00000000";
					end if;
				
			end case;
		end if;
	end process;
	process(clk, reset) 
	begin
		if reset='1' then 
			div<=(others=>'0');
		elsif rising_edge(clk) then 
			div<=div+1;
		End if;
	end process;
	fc<=div(23);				
	
	sda_s <= '0' WHEN SDA = '0' ELSE '1';
end Behavioral;