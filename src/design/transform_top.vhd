library ieee;
use ieee.numeric_std_unsigned.all;
use ieee.std_logic_1164.all;

entity transform_top is
  generic (
    g_N : integer
    );
  port (
    i_clk   : in std_ulogic;
    i_reset : in std_ulogic;


    o_axisInReady : out std_ulogic;
    i_axisInData  : in  std_ulogic_vector(16 - 1 downto 0);
    i_axisInValid : in  std_ulogic;

    i_axisOutReady : in  std_ulogic;
    o_axisOutData  : out std_ulogic_vector(15 downto 0);
    o_axisOutValid : out std_ulogic

    );
end entity;

architecture rtl of transform_top is
  signal s_axisImagData  : std_ulogic_vector(31 downto 0);
  signal s_axisImagReady : std_ulogic;
  signal s_axisImagValid : std_ulogic;
  signal s_axisImagLast  : std_ulogic;
  signal s_axisRealData  : std_ulogic_vector(31 downto 0);
  signal s_axisRealReady : std_ulogic;
  signal s_axisRealValid : std_ulogic;
  signal s_axisRealLast  : std_ulogic;
begin

  inst_sdft_top : entity work.sdft_top
    generic map (
      g_N => g_N
      )
    port map (
      i_clk       => i_clk,
      i_reset     => i_reset,
      o_axisReady => o_axisInReady,
      i_axisData  => i_axisInData,
      i_axisValid => i_axisInValid,

      o_axisQImagData  => s_axisImagData,
      i_axisQImagReady => s_axisImagReady,
      o_axisQImagValid => s_axisImagValid,
      o_axisQImagLast  => s_axisImagLast,
      o_axisQRealData  => s_axisRealData,
      i_axisQRealReady => s_axisRealReady,
      o_axisQRealValid => s_axisRealValid,
      o_axisQRealLast  => s_axisRealLast
      );
inst_sidft : entity work.sidft
generic map (
  g_N => g_N
)
port map (
  i_clk           => i_clk,
  i_reset         => i_reset,

  i_axisImagData  => s_axisImagData,
  o_axisImagReady => s_axisImagReady,
  i_axisImagValid => s_axisImagValid,
  i_axisImagLast  => s_axisImagLast,
  i_axisRealData  => s_axisRealData,
  o_axisRealReady => s_axisRealReady,
  i_axisRealValid => s_axisRealValid,
  i_axisRealLast  => s_axisRealLast,

  i_axisReady     => i_axisOutReady,
  o_axisData      => o_axisOutData,
  o_axisValid     => o_axisOutValid
);


end architecture;
