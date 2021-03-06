module sdft_tb;

  `define PI 3.14159265358979323846264338327950288419716939937510582097494459230781640628620899862

  parameter integer testFs = 24000;
  parameter integer testF1 = 600;
  parameter integer testF2 = 10000;
  parameter real testTime = 0.085;

  typedef struct {
    logic signed [11:0] data[$rtoi(testFs*testTime-1):0];
    } t_testData;

  function t_testData createTestData();
    t_testData result;

    for (int i = 0; i < testFs * testTime; i++) begin
      result.data[i] = $rtoi((1 << 12) * ($sin(2*`PI*testF1*i/testFs) + $cos(2*`PI*testF2*i/testFs) + 2) / 4);
    end
    return result;
  endfunction;


  logic clk;
  logic reset;
  logic axisReady;
  logic [15:0] axisData = 0;
  logic axisValid = 0;
  logic[31:0] freqWrReal;
  logic[31:0] freqWrImag;
  logic[8:0] freqWrAddr = 0;
  logic freqWrEn = 0;

  // clock gen
  always #(10/2) clk = ~clk;
  initial begin
    clk = 1;
  end

  sdft_top #(
    .g_N(512)
  ) i_dut (
    .i_clk       (clk),
    .i_reset     (reset),

    .o_axisReady (axisReady),
    .i_axisData  (axisData),
    .i_axisValid (axisValid),

    .o_freqWrReal(freqWrReal),
    .o_freqWrImag(freqWrImag),
    .o_freqWrAddr(freqWrAddr),
    .o_freqWrEn  (freqWrEn)
  );

  t_testData testData;

  // stimuli
  initial begin
    reset = 1;
    repeat(10) begin
      @(negedge clk);
    end
    reset = 0;
    repeat(5) begin
      @(negedge clk);
    end

    testData = createTestData();
    for (int i = 0; i < $size(testData.data); i += 1) begin
      axisData[11:0] = testData.data[i];
      axisValid = 1;
      while (!axisReady) begin
        @(negedge clk);
      end
      @(negedge clk);
    end
  end

  // write to file
  initial begin
    int realFD;
    int imagFD;
    @(negedge reset);
    realFD = $fopen("real.data", "w");
    imagFD = $fopen("complex.data", "w");

    for (int i = 0; i < $size(testData.data); i += 1) begin
      for (int n = 0; n < 512; n += 1) begin
        while (!freqWrEn) begin
          @(negedge clk);
        end
        if (n != freqWrAddr) begin
          $display("t=%0d, n=%0d, wr address is wrong: %0d @%01t", i, n, freqWrAddr, $time);
          $finish();
        end else begin
          $display("t=%0d, n=%0d wrote %f+j%f @%01t", i, n, $bitstoshortreal(freqWrReal), $bitstoshortreal(freqWrImag), $time);
        end
        $fwrite(realFD, "%g,", $bitstoshortreal(freqWrReal));
        $fwrite(imagFD, "%g,", $bitstoshortreal(freqWrImag));
        @(negedge clk);
      end
        $fwrite(realFD, "\n");
        $fwrite(imagFD, "\n");
    end

    $fclose(realFD);
    $fclose(imagFD);
  end

endmodule