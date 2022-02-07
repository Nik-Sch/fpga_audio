library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity board_top is
  port(
    i_clk100 : in std_ulogic;
    i_nreset : in std_ulogic;

    o_pdmClk          : out std_ulogic;
    i_pdmData         : in  std_ulogic;
    o_pdmLeftNotRight : out std_ulogic;

    o_pwmDataTri : out std_ulogic;
    o_pwmEnable  : out std_ulogic
    );
end entity;

architecture rtl of board_top is
  constant c_AXIS_WIDTH  : integer := 16;
  constant c_DATA_WIDTH  : integer := 12;
  constant c_SAMPLE_RATE : integer := 24000;

  signal s_pwmData      : std_ulogic;
  signal s_axisInValid  : std_ulogic;
  signal s_axisInData   : std_ulogic_vector(c_AXIS_WIDTH - 1 downto 0);
  signal s_axisInReady  : std_ulogic;
  signal s_axisOutValid : std_ulogic;
  signal s_axisOutData  : std_ulogic_vector(c_AXIS_WIDTH - 1 downto 0);
  signal s_axisOutReady : std_ulogic;

  signal r_resetCounter : integer    := 0;
  signal r_reset        : std_ulogic := '0';
begin

  procReset : process(i_clk100, i_nreset)
  begin
    if rising_edge(i_clk100) then
      r_reset <= '0';

      if r_resetCounter < 100 then
        r_reset        <= '1';
        r_resetCounter <= r_resetCounter + 1;
      end if;

    end if;

    if not i_nreset then
      r_reset        <= '1';
      r_resetCounter <= 0;
    end if;

  end process;

  inst_pdm_to_axis : entity work.pdm_to_axis
    generic map (
      g_AXIS_WIDTH  => c_AXIS_WIDTH,
      g_DATA_WIDTH  => c_DATA_WIDTH,
      g_SAMPLE_RATE => c_SAMPLE_RATE
      )
    port map (
      i_clk100          => i_clk100,
      i_reset           => r_reset,
      o_pdmClk          => o_pdmClk,
      i_pdmData         => i_pdmData,
      o_pdmLeftNotRight => o_pdmLeftNotRight,
      i_axisReady       => s_axisInReady,
      o_axisData        => s_axisInData,
      o_axisDataValid   => s_axisInValid
      );

  inst_transform_top : entity work.transform_top
    generic map (
      g_N => 512
      )
    port map (
      i_clk   => i_clk100,
      i_reset => r_reset,

      o_axisInReady => s_axisInReady,
      i_axisInData  => s_axisInData,
      i_axisInValid => s_axisInValid,

      i_axisOutReady => s_axisOutReady,
      o_axisOutData  => s_axisOutData,
      o_axisOutValid => s_axisOutValid
      );



  o_pwmDataTri <= 'Z' when s_pwmData else '0';  -- pwm should output 'z' for high to use clean analog 3v3 pull-up

  inst_axis_to_pwm : entity work.axis_to_pwm
    generic map (
      g_AXIS_WIDTH => c_AXIS_WIDTH,
      g_DATA_WIDTH => c_DATA_WIDTH
      )
    port map (
      i_clk100        => i_clk100,
      i_reset         => r_reset,
      o_pwmData       => s_pwmData,
      o_pwmEnable     => o_pwmEnable,
      o_axisReady     => s_axisOutReady,
      i_axisData      => s_axisOutData,
      i_axisDataValid => s_axisOutValid
      );


end architecture;
