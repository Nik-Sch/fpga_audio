library ieee;
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

    -- for test
    o_freqWrReal : out std_ulogic_vector(32 - 1 downto 0);
    o_freqWrImag : out std_ulogic_vector(32 - 1 downto 0);
    o_freqWrAddr : out std_ulogic_vector(9 - 1 downto 0);
    o_freqWrEn   : out std_ulogic

    );
end entity;

architecture rtl of sdft_top is
  signal r_freqWrData : std_ulogic_vector(64 - 1 downto 0);
  signal s_freqWrAddr : std_ulogic_vector(9 - 1 downto 0);
  signal r_freqWrEn   : std_ulogic;

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

  signal s_axisQImagData  : std_ulogic_vector(31 downto 0);
  signal r_axisQImagReady : std_ulogic;
  signal s_axisQImagValid : std_ulogic;

  signal s_axisQRealData  : std_ulogic_vector(31 downto 0);
  signal r_axisQRealReady : std_ulogic;
  signal s_axisQRealValid : std_ulogic;
begin

  inst_fixedToFloat : entity work.fixedToFloat
    port map (
      aclk    => i_clk,
      aresetn => not i_reset,

      s_axis_a_tvalid => i_axisValid,
      s_axis_a_tready => o_axisReady,
      s_axis_a_tdata(15 downto 0)  => i_axisData,
      s_axis_a_tdata(31 downto 16)  => (others => '0'),

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

      m_axis_tvalid(1)           => s_axisPreFifoValid,
      m_axis_tvalid(0)          => s_axisNewValueValid,
      m_axis_tready(1)           => s_axisPreFifoReady,
      m_axis_tready(0)          => r_axisNewValueReady,
      m_axis_tdata(63 downto 32) => s_axisPreFifoData,
      m_axis_tdata(31 downto 0) => s_axisNewValueData

      );

  inst_axisFifo : entity work.axisFifo
    port map (
      s_axis_aresetn => i_clk,
      s_axis_aclk    => not i_reset,

      s_axis_tvalid => s_axisPreFifoValid,
      s_axis_tready => s_axisPreFifoReady,
      s_axis_tdata  => s_axisPreFifoData,

      m_axis_tvalid => s_axisOldValueFifoValid,
      m_axis_tready => r_axisOldValueFifoReady,
      m_axis_tdata  => s_axisOldValueFifoData
      );


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

      o_qAddress       => s_freqWrAddr,
      o_axisQImagData  => s_axisQImagData,
      i_axisQImagReady => r_axisQImagReady,
      o_axisQImagValid => s_axisQImagValid,

      o_axisQRealData  => s_axisQRealData,
      i_axisQRealReady => r_axisQRealReady,
      o_axisQRealValid => s_axisQRealValid
      );


  inst_frequencyRam : entity work.frequencyRam
    port map (
      clka  => i_clk,
      wea   => r_freqWrEn,
      addra => s_freqWrAddr,
      dina  => r_freqWrData,

      clkb  => i_clk,
      addrb => (others => '0'),
      doutb => open
      );

  o_freqWrEn   <= r_freqWrEn;
  o_freqWrAddr <= s_freqWrAddr;
  o_freqWrReal <= r_freqWrData(63 downto 32);
  o_freqWrImag <= r_freqWrData(31 downto 0);

  --vhdl-linter-parameter-next-line r_axisNewData r_axisOldData r_freqWrData
  p_reg : process(i_clk, i_reset)
  begin
    if rising_edge(i_clk) then
      r_freqWrEn <= '0';

      -- wait for result
      if r_axisQRealReady and s_axisQRealValid then
        r_axisQRealReady           <= '0';
        r_freqWrData(63 downto 32) <= s_axisQRealData;
      end if;

      if r_axisQImagReady and s_axisQImagValid then
        r_axisQImagReady          <= '0';
        r_freqWrData(31 downto 0) <= s_axisQImagData;
      end if;

      if r_axisQRealReady = '0' and r_axisQImagReady = '0' then
        r_freqWrEn       <= '1';
        r_axisQRealReady <= '1';
        r_axisQImagReady <= '1';
      end if;


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
      r_axisQRealReady        <= '1';
      r_axisQImagReady        <= '1';
      r_freqWrEn              <= '0';
      r_axisOldValueFifoReady <= '0';
      r_axisNewValueReady     <= '1';
      r_axisValid             <= '0';
      r_countValues           <= 0;
    end if;

  end process;

end architecture;
