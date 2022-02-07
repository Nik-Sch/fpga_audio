module transform_tb;

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
  logic axisInReady;
  logic [15:0] axisInData = 0;
  logic axisInValid = 0;
  logic axisOutReady;
  logic [15:0] axisOutData = 0;
  logic axisOutValid = 0;

  // clock gen
  always #(10/2) clk = ~clk;
  initial begin
    clk = 1;
  end

  transform_top #(
    .g_N(512)
  ) i_dut (
    .i_clk       (clk),
    .i_reset     (reset),

    .o_axisInReady (axisInReady),
    .i_axisInData  (axisInData),
    .i_axisInValid (axisInValid),

    .i_axisOutReady (axisOutReady),
    .o_axisOutData  (axisOutData),
    .o_axisOutValid (axisOutValid)
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
      axisInData[11:0] = testData.data[i];
      axisInValid = 1;
      while (!axisInReady) begin
        @(negedge clk);
      end
      @(negedge clk);
    end
  end

  // write to file
  initial begin
    int outFD;
    @(negedge reset);
    outFD = $fopen("out.data", "w");
    axisOutReady = 1;

    for (int i = 0; i < $size(testData.data); i += 1) begin
      while (!axisOutValid) begin
        @(negedge clk);
      end
      $fwrite(outFD, "%g,", axisOutData);
      @(negedge clk);
    end

    $fclose(outFD);
  end

endmodule