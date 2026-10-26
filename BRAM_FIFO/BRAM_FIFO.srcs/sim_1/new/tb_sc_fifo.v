`timescale 1ns / 1ps


module tb_sc_fifo;
    localparam WIDTH = 16;
    localparam DEPTH = 32;
    localparam READ_LATENCY = 8;

    reg clk = 1'b0;
    always #10 clk = ~clk;  // 20 ns period = 50 MHz

    reg SRST;
    reg write_enable;
    reg read_enable;
    reg [WIDTH-1:0] data_in;

    wire [$clog2(DEPTH+1)-1:0] data_count;
    wire valid;
    wire [WIDTH-1:0] data_out;
    wire almost_full, almost_empty, full, empty;

    sc_fifo #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH),
        .ALMOST_EMPTY_THRESHOLD(1),
        .ALMOST_FULL_THRESHOLD(DEPTH-1),
        .READ_LATENCY(READ_LATENCY)
    ) dut (
        .clk(clk),
        .SRST(SRST),
        .write_enable(write_enable),
        .read_enable(read_enable),
        .data_in(data_in),
        .data_count(data_count),
        .valid(valid),
        .data_out(data_out),
        .almost_full(almost_full),
        .almost_empty(almost_empty),
        .full(full),
        .empty(empty)
    );

    // Reference FIFO and expected read pipeline.
    reg [WIDTH-1:0] expected_mem [0:DEPTH-1];
    reg [WIDTH-1:0] expected_data [0:READ_LATENCY-1];
    reg [READ_LATENCY-1:0] expected_valid;
    integer expected_write_ptr;
    integer expected_read_ptr;
    integer expected_count;
    integer cycles;
    integer n;
    reg [WIDTH-1:0] file_data [0:DEPTH+3];

    task check_outputs;
        begin
            if (data_count !== expected_count ||
                empty !== (expected_count == 0) ||
                full !== (expected_count == DEPTH) ||
                almost_empty !== (expected_count <= 1) ||
                almost_full !== (expected_count >= DEPTH-1)) begin
                $display("FAIL cycle %0d: count=%0d expected=%0d, empty=%b full=%b almost_empty=%b almost_full=%b",
                         cycles, data_count, expected_count,
                         empty, full, almost_empty, almost_full);
                $fatal(1, "FIFO count or status flag mismatch");
            end

            if (valid !== expected_valid[READ_LATENCY-1]) begin
                $display("FAIL cycle %0d: valid=%b expected=%b",
                         cycles, valid, expected_valid[READ_LATENCY-1]);
                $fatal(1, "FIFO valid mismatch");
            end

            if (expected_valid[READ_LATENCY-1] &&
                data_out !== expected_data[READ_LATENCY-1]) begin
                $display("FAIL cycle %0d: data_out=%h expected=%h",
                         cycles, data_out, expected_data[READ_LATENCY-1]);
                $fatal(1, "FIFO read data mismatch");
            end

            // Check that data_out is zero while reset is asserted.
            if (SRST && data_out !== {WIDTH{1'b0}}) begin
                $display("FAIL: data_out=%h during reset; expected zero",
                         data_out);
                $fatal(1, "FIFO reset output mismatch");
            end
        end
    endtask

    // Apply one clock cycle of inputs and compare against the reference FIFO.
    task step;
        input request_write;
        input request_read;
        input [WIDTH-1:0] value;
        reg accepted_write;
        reg accepted_read;
        reg [WIDTH-1:0] popped_value;
        integer j;
        begin
            @(negedge clk);
            write_enable = request_write;
            read_enable = request_read;
            data_in = value;

            accepted_write = request_write && (expected_count < DEPTH);
            accepted_read = request_read && (expected_count > 0);

            popped_value = {WIDTH{1'b0}};
            if (accepted_read)
                popped_value = expected_mem[expected_read_ptr];

            for (j = READ_LATENCY-1; j > 0; j = j - 1) begin
                expected_valid[j] = expected_valid[j-1];
                expected_data[j] = expected_data[j-1];
            end
            expected_valid[0] = accepted_read;
            expected_data[0] = popped_value;

            if (accepted_write) begin
                expected_mem[expected_write_ptr] = value;
                expected_write_ptr =
                    (expected_write_ptr + 1) % DEPTH;
            end

            if (accepted_read)
                expected_read_ptr =
                    (expected_read_ptr + 1) % DEPTH;

            if (accepted_write && !accepted_read)
                expected_count = expected_count + 1;
            else if (accepted_read && !accepted_write)
                expected_count = expected_count - 1;

            @(posedge clk);
            #1;  
            cycles = cycles + 1;
            check_outputs;
        end
    endtask

    task reset_fifo;
        begin
            @(negedge clk);
            write_enable = 1'b0;
            read_enable = 1'b0;
            SRST = 1'b1;

            expected_write_ptr = 0;
            expected_read_ptr = 0;
            expected_count = 0;
            expected_valid = {READ_LATENCY{1'b0}};

            #1;  
            check_outputs;

            @(posedge clk);
            #1;
            check_outputs;

            @(negedge clk);
            SRST = 1'b0;
        end
    endtask

    initial begin
        SRST = 1'b0;
        write_enable = 1'b0;
        read_enable = 1'b0;
        data_in = {WIDTH{1'b0}};

        expected_write_ptr = 0;
        expected_read_ptr = 0;
        expected_count = 0;
        expected_valid = {READ_LATENCY{1'b0}};
        cycles = 0;
        
        $readmemh("input_data.txt", file_data);
        for (n = 0; n < DEPTH+4; n = n + 1)
            if (^file_data[n] === 1'bx)
                $fatal(1, "Missing or invalid input_data.txt word %0d", n);
        
        reset_fifo;

        // Disabled operations and an attempted read while empty.
        step(0, 0, 16'h1234);
        step(0, 1, 16'h0000);

        // All ones, all zeros, and alternating patterns.
        step(1, 0, file_data[0]);
        step(0, 0, 16'h0000);
        step(0, 1, 16'h0000);

        step(1, 0, file_data[1]);
        step(0, 1, 16'h0000);

        step(1, 0, file_data[2]);
        step(1, 0, file_data[3]);
        step(0, 1, 16'h0000);
        step(0, 1, 16'h0000);
        step(0, 1, 16'h0000);  // Ignored because FIFO is empty.

        // Fill every FIFO location with a different value.
        for (n = 0; n < DEPTH; n = n + 1)
            step(1, 0, file_data[n+4]);

        step(1, 0, 16'hDEAD);  // Full: write is ignored.
        step(1, 1, 16'hBEEF);  // Full: only read is accepted.
        step(1, 1, 16'hCAFE);  // Partly full: both are accepted.

        // Read back every remaining value.
        for (n = 0; n < DEPTH-1; n = n + 1)
            step(0, 1, 16'h0000);

        step(1, 1, 16'hABCD);  // Empty: only write is accepted.
        step(0, 1, 16'h0000);

        // Another full write/read cycle checks pointer wraparound.
        for (n = 0; n < DEPTH; n = n + 1)
            step(1, 0, 16'h2000 + n);

        for (n = 0; n < DEPTH; n = n + 1)
            step(0, 1, 16'h0000);

        // Assert reset after a nonzero output and with a word queued.
        step(1, 0, 16'hF00F);
        step(0, 1, 16'h0000);
        step(1, 0, 16'h0F0F);
        reset_fifo;

        step(0, 1, 16'h0000);  // Pre-reset word cannot be read.

        $display("PASS: %0d checked clock cycles; WIDTH=%0d DEPTH=%0d READ_LATENCY=%0d",
                 cycles, WIDTH, DEPTH, READ_LATENCY);
        $finish;
    end
endmodule