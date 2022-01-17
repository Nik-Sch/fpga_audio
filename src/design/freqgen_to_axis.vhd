library ieee;
use ieee.numeric_std_unsigned.all;
use ieee.std_logic_1164.all;

entity freqgen_to_axis is
  port(
    i_clk100 : in std_ulogic;
    i_reset  : in std_ulogic;

    i_axisReady     : in  std_ulogic;
    o_axisData      : out std_ulogic_vector(7 downto 0);  -- actually 7 bit data
    o_axisDataValid : out std_ulogic

    );
end entity;

architecture rtl of freqgen_to_axis is
  signal r_counter : integer;
  signal r_downNotUp : boolean;
begin

  procClkPdm : process(i_clk100, i_reset)
  begin
    if rising_edge(i_clk100) then
      o_axisDataValid <= '0';
      r_counter <= r_counter + 1;
      if r_counter > 100000 then
        r_counter <= 0;
        r_downNotUp <= not r_downNotUp;
      end if;
      if r_counter mod 783 = 0 then
        o_axisDataValid <= '1';
        o_axisData <= (o_axisData - 1) when r_downNotUp else (o_axisData + 1);
      end if;

    end if;

    if i_reset then
      o_axisDataValid <= '0';
      o_axisData <= (others => '0');
      r_counter <= 0;
      r_downNotUp <= false;
    end if;

  end process;

end architecture;
