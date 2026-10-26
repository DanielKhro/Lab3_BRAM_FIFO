`timescale 1ns / 1ps

module tb_mult();

parameter CLK_PERIOD = 20;
parameter NUM_PAIRS = 20;

reg clk;
reg [7:0] a;
reg [7:0] b;
wire [15:0] product;

integer errors = 0;
integer i;
integer raw_fd;
integer results_fd;
reg [15:0] expected;

reg [7:0] file_data [0:2*NUM_PAIRS-1];

mult UUT (
    .clk(clk),
    .a(a),
    .b(b),
    .product(product)
);

initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
end

initial begin
    raw_fd = $fopen("test_results.txt");
    results_fd = raw_fd | 1;
    $readmemh("input_data.txt", file_data);
    a = 0;
    b = 0;
    #(CLK_PERIOD);

    for (i = 0; i < NUM_PAIRS; i = i + 1) begin
        a = file_data[2 * i];
        b = file_data[2 * i + 1];
        expected = a * b;
        #(CLK_PERIOD);
        if (product !== expected) begin
            errors = errors + 1;
            $fdisplay(results_fd, "[%0t] FAIL: a=%0d b=%0d product=%0d expected=%0d", $time, a, b, product, expected);
        end
    end

    #(2 * CLK_PERIOD);
    if (errors == 0) begin
        $fdisplay(results_fd, "TEST PASSED");
    end else begin
        $fdisplay(results_fd, "TEST FAILED: %0d errors", errors);
    end
    $fclose(raw_fd);
    $finish;
end

endmodule
