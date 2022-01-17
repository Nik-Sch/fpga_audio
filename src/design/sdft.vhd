library ieee;
use ieee.numeric_std_unsigned.all;
use ieee.std_logic_1164.all;

entity sdft is
  generic (
    g_N : integer
    );
  port (
    i_clk   : in std_ulogic;
    i_reset : in std_ulogic;

    o_axisReady   : out std_ulogic;
    i_axisNewData : in  std_ulogic_vector(32 - 1 downto 0);
    i_axisOldData : in  std_ulogic_vector(32 - 1 downto 0);
    i_axisValid   : in  std_ulogic;

    o_qAddress       : out std_ulogic_vector(9 - 1 downto 0);
    o_axisQImagData  : out std_ulogic_vector(31 downto 0);
    i_axisQImagReady : in  std_ulogic;
    o_axisQImagValid : out std_ulogic;

    o_axisQRealData  : out std_ulogic_vector(31 downto 0);
    i_axisQRealReady : in  std_ulogic;
    o_axisQRealValid : out std_ulogic

    );
end entity;

architecture rtl of sdft is
  signal s_expRdData    : std_ulogic_vector(64 - 1 downto 0);
  signal r_startStage   : std_ulogic;
  signal s_freqRdData   : std_ulogic_vector(64 - 1 downto 0);
  signal s_nStdLogicVec : std_ulogic_vector(9 - 1 downto 0);
  signal r_qWrAddr      : std_ulogic_vector(9 - 1 downto 0);
  signal r_qWrEn        : std_ulogic;
  signal r_qWrData      : std_ulogic_vector(64 - 1 downto 0);


  signal r_axisNewValueValid : std_ulogic;
  signal s_axisNewValueReady : std_ulogic;
  signal r_axisNewValueData  : std_ulogic_vector(32 - 1 downto 0);

  signal r_axisOldValueValid : std_ulogic;
  signal s_axisOldValueReady : std_ulogic;
  signal r_axisOldValueData  : std_ulogic_vector(32 - 1 downto 0);

  signal s_axisExpImagData  : std_logic_vector(31 downto 0);
  signal s_axisExpImagReady : std_logic;
  signal r_axisExpImagValid : std_logic;
  signal s_axisExpRealData  : std_logic_vector(31 downto 0);
  signal s_axisExpRealReady : std_logic;
  signal r_axisExpRealValid : std_logic;

  signal s_axisOldFreqImagData  : std_logic_vector(31 downto 0);
  signal s_axisOldFreqImagReady : std_logic;
  signal r_axisOldFreqImagValid : std_logic;
  signal s_axisOldFreqRealData  : std_logic_vector(31 downto 0);
  signal s_axisOldFreqRealReady : std_logic;
  signal r_axisOldFreqRealValid : std_logic;

  signal s_axisQImagData  : std_logic_vector(31 downto 0);
  signal s_axisQImagReady : std_logic;
  signal s_axisQImagValid : std_logic;
  signal s_axisQRealData  : std_logic_vector(31 downto 0);
  signal s_axisQRealReady : std_logic;
  signal s_axisQRealValid : std_logic;

  signal s_axisQImagBramData  : std_logic_vector(31 downto 0);
  signal r_axisQImagBramReady : std_logic;
  signal s_axisQImagBramValid : std_logic;
  signal s_axisQRealBramData  : std_logic_vector(31 downto 0);
  signal r_axisQRealBramReady : std_logic;
  signal s_axisQRealBramValid : std_logic;

  signal r_n : integer;
begin

  inst_sdft_stage_wrapper : entity work.sdft_stage_wrapper
    port map (
      aclk    => i_clk,
      aresetn => not i_reset,

      s_axis_expImag_tdata  => s_axisExpImagData,
      s_axis_expImag_tready => s_axisExpImagReady,
      s_axis_expImag_tvalid => r_axisExpImagValid,

      s_axis_expReal_tdata  => s_axisExpRealData,
      s_axis_expReal_tready => s_axisExpRealReady,
      s_axis_expReal_tvalid => r_axisExpRealValid,

      s_axis_newTime_tdata  => r_axisNewValueData,
      s_axis_newTime_tready => s_axisNewValueReady,
      s_axis_newTime_tvalid => r_axisNewValueValid,

      s_axis_oldFreqImag_tdata  => s_axisOldFreqImagData,
      s_axis_oldFreqImag_tready => s_axisOldFreqImagReady,
      s_axis_oldFreqImag_tvalid => r_axisOldFreqImagValid,

      s_axis_oldFreqReal_tdata  => s_axisOldFreqRealData,
      s_axis_oldFreqReal_tready => s_axisOldFreqRealReady,
      s_axis_oldFreqReal_tvalid => r_axisOldFreqRealValid,

      s_axis_oldTime_tdata  => r_axisOldValueData,
      s_axis_oldTime_tready => s_axisOldValueReady,
      s_axis_oldTime_tvalid => r_axisOldValueValid,


      m_axis_qImag_tdata  => s_axisQImagData,
      m_axis_qImag_tready => s_axisQImagReady,
      m_axis_qImag_tvalid => s_axisQImagValid,

      m_axis_qReal_tdata  => s_axisQRealData,
      m_axis_qReal_tready => s_axisQRealReady,
      m_axis_qReal_tvalid => s_axisQRealValid
      );

  inst_axisSplitQReal : entity work.axisBroadcaster
    port map (
      aclk    => i_clk,
      aresetn => not i_reset,

      s_axis_tvalid => s_axisQRealValid,
      s_axis_tready => s_axisQRealReady,
      s_axis_tdata  => s_axisQRealData,

      m_axis_tvalid(0)           => o_axisQrealValid,
      m_axis_tvalid(1)           => s_axisQRealBramValid,
      m_axis_tready(0)           => i_axisQrealReady,
      m_axis_tready(1)           => r_axisQRealBramReady,
      m_axis_tdata(31 downto 0)  => o_axisQrealData,
      m_axis_tdata(63 downto 32) => s_axisQRealBramData

      );

  inst_axisSplitQImag : entity work.axisBroadcaster
    port map (
      aclk    => i_clk,
      aresetn => not i_reset,

      s_axis_tvalid => s_axisQImagValid,
      s_axis_tready => s_axisQImagReady,
      s_axis_tdata  => s_axisQImagData,

      m_axis_tvalid(0)           => o_axisQImagValid,
      m_axis_tvalid(1)           => s_axisQImagBramValid,
      m_axis_tready(0)           => i_axisQImagReady,
      m_axis_tready(1)           => r_axisQImagBramReady,
      m_axis_tdata(31 downto 0)  => o_axisQImagData,
      m_axis_tdata(63 downto 32) => s_axisQImagBramData

      );

  inst_frequencyRam : entity work.frequencyRam
    port map (
      clka  => i_clk,
      wea   => r_qWrEn,
      addra => r_qWrAddr,
      dina  => r_qWrData,

      clkb  => i_clk,
      addrb => s_nStdLogicVec,
      doutb => s_freqRdData
      );

  s_nStdLogicVec        <= to_stdulogicvector(r_n, s_nStdLogicVec'length);
  s_axisOldFreqRealData <= s_freqRdData(63 downto 32);
  s_axisOldFreqImagData <= s_freqRdData(31 downto 0);

  inst_expRom : entity work.eRom
    port map (
      clka  => i_clk,
      addra => s_nStdLogicVec,
      douta => s_expRdData
      );

  s_axisExpRealData <= s_expRdData(63 downto 32);
  s_axisExpImagData <= s_expRdData(31 downto 0);

  --vhdl-linter-parameter-next-line r_qWrData
  p_reg : process(i_clk, i_reset)
  begin
    if rising_edge(i_clk) then
      r_qWrEn <= '0';

      -- wait for result
      if r_axisQRealBramReady and s_axisQRealBramValid then
        r_axisQRealBramReady    <= '0';
        r_qWrData(63 downto 32) <= s_axisQRealBramData;
      end if;

      if r_axisQImagBramReady and s_axisQImagBramValid then
        r_axisQImagBramReady   <= '0';
        r_qWrData(31 downto 0) <= s_axisQImagBramData;
      end if;

      -- result finished
      -- -> store in ram
      -- -> if n < N: start new calculation
      -- -> if n == N: accept new input
      if r_axisQRealBramReady = '0' and r_axisQImagBramReady = '0' then
        r_qWrAddr            <= to_stdulogicvector(r_n, r_qWrAddr'length);
        o_qAddress           <= to_stdulogicvector(r_n, r_qWrAddr'length);
        r_qWrEn              <= '1';
        r_axisQRealBramReady <= '1';
        r_axisQImagBramReady <= '1';

        if r_n <= g_N then
          r_n          <= r_n + 1;
          r_startStage <= '1';          -- 1 cycle delay for ram access
        else
          o_axisReady <= '1';
        end if;
      end if;

      if o_axisReady and i_axisValid then
        o_axisReady        <= '0';
        r_axisNewValueData <= i_axisNewData;
        r_axisOldValueData <= i_axisOldData;
        r_n                <= 0;
        r_startStage       <= '1';
      end if;

      if r_startStage then
        r_startStage           <= '0';
        r_axisOldFreqRealValid <= '1';
        r_axisOldFreqImagValid <= '1';
        r_axisExpRealValid     <= '1';
        r_axisExpImagValid     <= '1';
        r_axisNewValueValid    <= '1';
        r_axisOldValueValid    <= '1';
      end if;

      -- new/old data, exp and oldFreq handshakes

      if r_axisNewValueValid and s_axisNewValueReady then
        r_axisNewValueValid <= '0';
      end if;

      if r_axisOldValueValid and s_axisOldValueReady then
        r_axisOldValueValid <= '0';
      end if;
      if r_axisOldFreqRealValid and s_axisOldFreqRealReady then
        r_axisOldFreqRealValid <= '0';
      end if;

      if r_axisOldFreqImagValid and s_axisOldFreqImagReady then
        r_axisOldFreqImagValid <= '0';
      end if;

      if r_axisExpRealValid and s_axisExpRealReady then
        r_axisExpRealValid <= '0';
      end if;

      if r_axisExpImagValid and s_axisExpImagReady then
        r_axisExpImagValid <= '0';
      end if;

    end if;

    if i_reset then
      o_axisReady          <= '1';
      r_axisQRealBramReady <= '1';
      r_axisQImagBramReady <= '1';

      r_axisOldValueData     <= (others => '0');
      r_axisOldValueValid    <= '0';
      r_axisNewValueData     <= (others => '0');
      r_axisNewValueValid    <= '0';
      r_axisOldFreqRealValid <= '0';
      r_axisOldFreqImagValid <= '0';
      r_axisExpRealValid     <= '0';
      r_axisExpImagValid     <= '0';
      r_startStage           <= '0';
      r_n                    <= 0;
      r_qWrAddr              <= (others => '0');
      r_qWrEn                <= '0';
    end if;

  end process;

end architecture;
