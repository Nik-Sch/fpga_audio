library ieee;
use ieee.numeric_std_unsigned.all;
use ieee.std_logic_1164.all;

entity axis_to_pwm is
  generic (
    g_AXIS_WIDTH : integer := 16;
    g_DATA_WIDTH : integer := 12
    );
  port (
    i_clk100 : in std_ulogic;
    i_reset  : in std_ulogic;

    o_pwmData   : out std_ulogic;
    o_pwmEnable : out std_ulogic;

    o_axisReady     : out std_ulogic;
    i_axisData      : in  std_ulogic_vector(g_AXIS_WIDTH - 1 downto 0);  -- actually 12 bit data
    i_axisDataValid : in  std_ulogic

    );
end entity;

architecture rtl of axis_to_pwm is
  signal r_newData : std_ulogic_vector(g_DATA_WIDTH - 1 downto 0);
  signal r_counter : std_ulogic_vector(g_DATA_WIDTH - 1 downto 0);
  signal r_data    : std_ulogic_vector(g_DATA_WIDTH - 1 downto 0);
begin

  o_axisReady <= '1';

  procClk : process(i_clk100, i_reset)
  begin
    if rising_edge(i_clk100) then

      r_counter <= r_counter + 1;

      o_pwmData   <= '1' when r_counter < r_data else '0';
      o_pwmEnable <= '1';

      if o_axisReady and i_axisDataValid then
        r_newData <= i_axisData(r_newData'left downto 0);
      end if;

      if r_counter = (r_counter'left downto 0 => '1') then
        r_data <= r_newData;
      end if;
    end if;

    if i_reset then
      o_pwmEnable <= '0';
      r_counter   <= (others => '0');
      r_data      <= (others => '0');
      r_newData   <= (others => '0');
      o_pwmData   <= '0';
    end if;

  end process;

end architecture;
