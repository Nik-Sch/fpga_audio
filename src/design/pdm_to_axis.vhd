library ieee;
use ieee.numeric_std_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity pdm_to_axis is
  generic (
    g_AXIS_WIDTH : integer := 16;
    g_DATA_WIDTH : integer := 12;
    g_SAMPLE_RATE : integer := 24000
    );
  port (
    i_clk100 : in std_ulogic;
    i_reset  : in std_ulogic;

    o_pdmClk          : out std_ulogic;
    i_pdmData         : in  std_ulogic;
    o_pdmLeftNotRight : out std_ulogic;

    i_axisReady     : in  std_ulogic;
    o_axisData      : out std_ulogic_vector(g_AXIS_WIDTH - 1 downto 0);
    o_axisDataValid : out std_ulogic

    );
end entity;

architecture rtl of pdm_to_axis is
  constant c_PDM_FREQ : integer := 3 * 1000 * 1000; -- 3MHz
  constant c_MAX_ACCUMULATOR_VALUE : integer := 2 ** g_DATA_WIDTH;
  constant c_ACCUMULATOR_COUNT : integer := integer(ceil(real(g_SAMPLE_RATE) / (real(c_PDM_FREQ) / real(c_MAX_ACCUMULATOR_VALUE))));
  constant c_MAX_COUNTER_VALUE : integer := integer(ceil(real(c_PDM_FREQ) * real(c_ACCUMULATOR_COUNT) / real(g_SAMPLE_RATE)));
  constant c_DELAY_PER_ACCUMULATOR : integer := integer(ceil(real(c_PDM_FREQ) / real(g_SAMPLE_RATE)));

  type t_accumulator is array(c_ACCUMULATOR_COUNT - 1 downto 0) of std_logic_vector(g_DATA_WIDTH - 1 downto 0);
  signal r_pdmAcc              : t_accumulator;
  type t_counter is array(c_ACCUMULATOR_COUNT - 1 downto 0) of integer;
  signal r_pdmCounter          : t_counter;
  signal r_pdmData             : std_ulogic_vector(16 - 1 downto 0);
  signal s_pdmDataReady        : std_ulogic;


  signal r_pdmDataValid     : std_ulogic;
  signal s_pdmClkCounter    : std_ulogic_vector(1 downto 0);
  signal s_pdmClkPreCounter : std_ulogic;
begin

  --vhdl-linter-parameter-next-line r_pdmAcc r_pdmCounter
  procClkPdm : process(o_pdmClk, i_reset)
  begin
    if rising_edge(o_pdmClk) then

      if r_pdmDataValid and s_pdmDataReady then
        r_pdmDataValid <= '0';
      end if;

      for i in 0 to c_ACCUMULATOR_COUNT - 1 loop
        r_pdmCounter(i) <= r_pdmCounter(i) + 1;
        if r_pdmCounter(i) < c_MAX_ACCUMULATOR_VALUE then     -- accumulate
          if i_pdmData then
            r_pdmAcc(i) <= r_pdmAcc(i) + 1;
          end if;
        elsif r_pdmCounter(i) < c_MAX_COUNTER_VALUE then  -- count finished, sent to fifo
          if not r_pdmDataValid then
            r_pdmData(r_pdmAcc(i)'range) <= r_pdmAcc(i);
            r_pdmDataValid             <= '1';
          end if;
        else                               -- reset counter
          r_pdmCounter(i) <= 0;
          r_pdmAcc(i)     <= (others => '0');
        end if;
      end loop;  -- end for identifier

    end if;

    if i_reset then
      r_pdmData <= (others => '0');
      for i in 0 to c_ACCUMULATOR_COUNT - 1 loop
        r_pdmAcc(i)     <= (others => '0');
        r_pdmCounter(i) <= c_MAX_COUNTER_VALUE - (i * c_DELAY_PER_ACCUMULATOR);
      end loop;
      r_pdmDataValid <= '0';
    end if;
  end process;

  inst_pdmClkWiz : entity work.pdmClkWiz
    port map (
      clk_in1 => i_clk100,
      reset   => i_reset,

      pdmClk => s_pdmClkPreCounter
      );

  o_pdmClk          <= s_pdmClkCounter(1);
  o_pdmLeftNotRight <= '0';             -- rising edge

  --vhdl-linter-parameter-next-line s_pdmClkCounter
  procClkPdmPreCounter : process(s_pdmClkPreCounter)
  begin
    if rising_edge(s_pdmClkPreCounter) then
      s_pdmClkCounter <= s_pdmClkCounter + 1;
    end if;
  end process;

  inst_micFifo : entity work.micFifo
    port map (
      wr_rst_busy   => open,
      rd_rst_busy   => open,
      s_aclk        => o_pdmClk,
      s_aresetn     => not i_reset,
      m_aclk        => i_clk100,
      s_axis_tvalid => r_pdmDataValid,
      s_axis_tready => s_pdmDataReady,
      s_axis_tdata  => r_pdmData,

      m_axis_tvalid => o_axisDataValid,
      m_axis_tready => i_axisReady,
      m_axis_tdata  => o_axisData
      );

end architecture;
