library ieee;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use ieee.std_logic_1164.all;

entity sdft_top is
  generic (
    g_N : integer
    );
  port (
    i_clk   : in std_ulogic;
    i_reset : in std_ulogic;

    o_axisReady : out std_ulogic;
    i_axisData  : in  std_ulogic_vector(16 - 1 downto 0);
    i_axisValid : in  std_ulogic;


    o_axisQImagData  : out std_ulogic_vector(31 downto 0);
    i_axisQImagReady : in  std_ulogic;
    o_axisQImagValid : out std_ulogic;
    o_axisQImagLast  : out std_ulogic;

    o_axisQRealData  : out std_ulogic_vector(31 downto 0);
    i_axisQRealReady : in  std_ulogic;
    o_axisQRealValid : out std_ulogic;
    o_axisQRealLast  : out std_ulogic

    );
end entity;

architecture rtl of sdft_top is
  signal s_axisDataNormalized : signed(16 - 1 downto 0);
  signal r_countValues : integer;

  signal s_axisFloatValid : std_ulogic;
  signal s_axisFloatReady : std_ulogic;
  signal s_axisFloatData  : std_ulogic_vector(31 downto 0);

  signal s_axisNewValueValid : std_ulogic;
  signal r_axisNewValueReady : std_ulogic;
  signal s_axisNewValueData  : std_ulogic_vector(31 downto 0);

  signal s_axisPreFifoValid : std_ulogic;
  signal s_axisPreFifoReady : std_ulogic;
  signal s_axisPreFifoData  : std_ulogic_vector(31 downto 0);

  signal s_axisOldValueFifoValid : std_ulogic;
  signal r_axisOldValueFifoReady : std_ulogic;
  signal s_axisOldValueFifoData  : std_ulogic_vector(31 downto 0);


  signal r_axisValid   : std_ulogic;
  signal s_axisReady   : std_ulogic;
  signal r_axisNewData : std_ulogic_vector(31 downto 0);
  signal r_axisOldData : std_ulogic_vector(31 downto 0);
begin

  -- -2048 - 2047
  s_axisDataNormalized <= signed(i_axisData) - to_signed(2048, 16);

  -- 10 fractional bits: -2 - 1.99
  -- needs a block design wrapper because xsim would otherwise crash...
  inst_fixedToFloat : entity work.fixedToFloatBD_wrapper
    port map (
      aclk    => i_clk,
      aresetn => not i_reset,

      s_axis_a_tvalid => i_axisValid,
      s_axis_a_tready => o_axisReady,
      s_axis_a_tdata  => std_ulogic_vector(s_axisDataNormalized),

      m_axis_result_tvalid => s_axisFloatValid,
      m_axis_result_tready => s_axisFloatReady,
      m_axis_result_tdata  => s_axisFloatData
      );

  inst_axisSplitNewValue : entity work.axisBroadcaster
    port map (
      aclk    => i_clk,
      aresetn => not i_reset,

      s_axis_tvalid => s_axisFloatValid,
      s_axis_tready => s_axisFloatReady,
      s_axis_tdata  => s_axisFloatData,
      s_axis_tlast  => '0',

      m_axis_tvalid(1)           => s_axisPreFifoValid,
      m_axis_tvalid(0)           => s_axisNewValueValid,
      m_axis_tready(1)           => s_axisPreFifoReady,
      m_axis_tready(0)           => r_axisNewValueReady,
      m_axis_tdata(63 downto 32) => s_axisPreFifoData,
      m_axis_tdata(31 downto 0)  => s_axisNewValueData

      );

  inst_axisFifo : entity work.axisFifo
    port map (
      s_axis_aclk    => i_clk,
      s_axis_aresetn => not i_reset,

      s_axis_tvalid => s_axisPreFifoValid,
      s_axis_tready => s_axisPreFifoReady,
      s_axis_tdata  => s_axisPreFifoData,

      m_axis_tvalid => s_axisOldValueFifoValid,
      m_axis_tready => r_axisOldValueFifoReady,
      m_axis_tdata  => s_axisOldValueFifoData
      );


  -- max freq: -1024 - 1023.99
  inst_sdft : entity work.sdft
    generic map (
      g_N => g_N
      )
    port map (
      i_clk   => i_clk,
      i_reset => i_reset,

      o_axisReady   => s_axisReady,
      i_axisNewData => r_axisNewData,
      i_axisOldData => r_axisOldData,
      i_axisValid   => r_axisValid,

      o_axisQImagData  => o_axisQImagData,
      i_axisQImagReady => i_axisQImagReady,
      o_axisQImagValid => o_axisQImagValid,
      o_axisQImagLast  => o_axisQImagLast,

      o_axisQRealData  => o_axisQRealData,
      i_axisQRealReady => i_axisQRealReady,
      o_axisQRealValid => o_axisQRealValid,
      o_axisQRealLast  => o_axisQRealLast
      );

  --vhdl-linter-parameter-next-line r_axisNewData r_axisOldData r_freqWrData
  p_reg : process(i_clk, i_reset)
  begin
    if rising_edge(i_clk) then
      if r_axisNewValueReady = '1' and s_axisNewValueValid = '1' and r_countValues < g_N then
        r_countValues <= r_countValues + 1;

        r_axisValid         <= '1';
        r_axisNewValueReady <= '0';
        r_axisOldData       <= (others => '0');  --  when r_countValues < g_N else s_axisOldValueFifoData;
        r_axisNewData       <= s_axisNewValueData;
      elsif r_axisNewValueReady and s_axisNewValueValid then
        r_countValues <= r_countValues + 1;

        r_axisNewData       <= s_axisNewValueData;
        r_axisNewValueReady <= '0';
      end if;

      if r_axisOldValueFifoReady and s_axisOldValueFifoValid then
        r_axisOldData           <= s_axisOldValueFifoData;
        r_axisOldValueFifoReady <= '0';
      end if;

      if r_axisOldValueFifoReady = '0' and r_axisNewValueReady = '0' and r_axisValid = '0' then
        r_axisValid <= '1';
      end if;

      if r_axisValid and s_axisReady then
        r_axisValid         <= '0';
        r_axisNewValueReady <= '1';
        if r_countValues >= g_N then
          r_axisOldValueFifoReady <= '1';
        end if;
      end if;

    end if;

    if i_reset then
      r_axisOldValueFifoReady <= '0';
      r_axisNewValueReady     <= '1';
      r_axisValid             <= '0';
      r_countValues           <= 0;
    end if;

  end process;

end architecture;
