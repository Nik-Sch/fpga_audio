library ieee;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use ieee.std_logic_1164.all;

entity sidft is
  generic (
    g_N : integer
    );
  port (
    i_clk   : in std_ulogic;
    i_reset : in std_ulogic;

    -- ignore the imaginary data
    i_axisImagData  : in  std_ulogic_vector(31 downto 0);
    o_axisImagReady : out std_ulogic;
    i_axisImagValid : in  std_ulogic;
    i_axisImagLast  : in  std_ulogic;

    i_axisRealData  : in  std_ulogic_vector(31 downto 0);
    o_axisRealReady : out std_ulogic;
    i_axisRealValid : in  std_ulogic;
    i_axisRealLast  : in  std_ulogic;

    i_axisReady : in  std_ulogic;
    o_axisData  : out std_ulogic_vector(15 downto 0);
    o_axisValid : out std_ulogic

    );
end entity;

architecture rtl of sidft is
  signal r_output : std_ulogic;

  signal s_axisDataTmp : std_ulogic_vector(35 downto 0);
  signal r_accumulator : signed(35 downto 0);
  signal r_timeValue   : signed(35 downto 0);

  signal s_axisFixedDataExtended : signed(35 downto 0);
  signal s_axisFixedData         : std_ulogic_vector(31 downto 0);
  signal s_axisFixedReady        : std_ulogic;
  signal s_axisFixedValid        : std_ulogic;
  signal s_axisFixedLast         : std_ulogic;
begin

  -- max freq: -1024 - 1023.99
  -- result max is +/- 2*N
  inst_floatToFixed : entity work.floatToFixed
    port map (
      aclk            => i_clk,
      aresetn         => not i_reset,
      s_axis_a_tvalid => i_axisRealValid,
      s_axis_a_tready => o_axisRealReady,
      s_axis_a_tdata  => i_axisRealData,
      s_axis_a_tlast  => i_axisRealLast,

      m_axis_result_tvalid => s_axisFixedValid,
      m_axis_result_tready => s_axisFixedReady,
      m_axis_result_tdata  => s_axisFixedData,
      m_axis_result_tlast  => s_axisFixedLast
      );

  -- 15 int bits + 21 fraction bits
  -- s_axisFixedDataExtended(35 downto 32) <= (others => s_axisFixedData(31));
  s_axisFixedDataExtended  <= resize(signed(s_axisFixedData), 36);

  -- result is in range +/- 2*512 + 1024 -> 0 - 2047 -> 11 int bits
  -- add 1024 << 21 (fraction bits) = 0x8000_0000
  -- pwm expects 12 bit data

  s_axisDataTmp <= std_ulogic_vector(unsigned(r_timeValue + 36sx"8000_0000"));
  o_axisData(11 downto 0) <= s_axisDataTmp(31 downto 20);

  o_axisImagReady  <= '1';
  s_axisFixedReady <= '1';

  --vhdl-linter-parameter-next-line o_axisData r_timeValue
  p_reg : process(i_clk, i_reset)
  begin
    if rising_edge(i_clk) then
      o_axisData(15 downto 12) <= (others => '0');
      if s_axisFixedReady and s_axisFixedValid then
        r_accumulator <= r_accumulator + s_axisFixedDataExtended;
        if s_axisFixedLast then
          r_output <= '1';              -- add last entry
        end if;
      end if;

      if r_output and not o_axisValid then
        r_output <= '0';

        o_axisValid   <= '1';
        r_timeValue   <= r_accumulator;
        r_accumulator <= (others => '0');
      end if;

      if o_axisValid and i_axisReady then
        o_axisValid <= '0';
      end if;
    end if;

    if i_reset then
      o_axisValid   <= '0';
      r_output      <= '0';
      r_accumulator <= (others => '0');
    end if;
  end process;

end architecture;
