library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity my_rom is
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
    rdata :out std_logic_vector(data_bits-1 downto 0)
);
end my_rom;
architecture rtl of my_rom is

----------------------------------------
type type_bram is array (integer range 0 to data_depth-1) of std_logic_vector(data_bits-1 downto 0);
signal my_rom : type_bram;

---------------------------------------- ---------------------------------------- ----------------------------------------
begin
---------------------------------------- ---------------------------------------- ----------------------------------------
process (wclk)
begin
if rising_edge(wclk) then
    if (wen = '1') then
        my_rom(waddr) <= wdata;
    end if;
end if;
end process;
----------------------------------------
process (rclk)
begin
if rising_edge(rclk) then
      rdata <= my_rom(raddr);
end if;
end process;
--rdata <= my_rom(raddr);
---------------------------------------- ---------------------------------------- ----------------------------------------
end rtl;