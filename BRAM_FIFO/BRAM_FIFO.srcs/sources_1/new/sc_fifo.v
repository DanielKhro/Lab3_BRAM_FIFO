`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2026 06:39:12 PM
// Design Name: 
// Module Name: sc_fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
// Simple Dual-Port Block RAM with One Clock
// File: simple_dual_one_clock.v

module simple_dual_one_clock (clk,ena,enb,wea,addra,addrb,dia,dob);

input clk,ena,enb,wea;
input [4:0] addra,addrb;
(* ram_style = "block" *)
input [15:0] dia;
output [15:0] dob;
reg [15:0] ram [31:0];
reg [15:0] dob;

always @(posedge clk) begin
if (ena) begin
if (wea)
ram[addra] <= dia;
end
end

always @(posedge clk) begin
if (enb)
dob <= ram[addrb];
end

endmodule

module sc_fifo #(
    parameter WIDTH = 16,
    parameter DEPTH = 32,
    parameter ALMOST_EMPTY_THRESHOLD = 1,
    parameter ALMOST_FULL_THRESHOLD = DEPTH - 1,
    parameter READ_LATENCY = 1
)(
    input wire                          clk,
    input wire                          SRST,
    input wire                          write_enable,
    input wire                          read_enable,
    input wire [WIDTH-1:0]              data_in,
    output reg [$clog2(DEPTH+1)-1:0]    data_count,
    output wire                          valid,
    output wire [WIDTH-1:0]             data_out,
    output wire                         almost_full,
    output wire                         almost_empty,
    output wire                         full,
    output wire                         empty
    );
    
    localparam ADDR_WIDTH = $clog2(DEPTH);
    
    reg [ADDR_WIDTH - 1:0] write_ptr;
    reg [ADDR_WIDTH - 1:0] read_ptr;
    wire write_ok;
    wire read_ok;
    assign empty = (data_count == 0);
    assign full  = (data_count == DEPTH);
    assign almost_empty = (data_count <= ALMOST_EMPTY_THRESHOLD);
    assign almost_full  = (data_count >= ALMOST_FULL_THRESHOLD);
    assign write_ok = write_enable && !full && !SRST;
    assign read_ok  = read_enable && !empty && !SRST;
    wire [WIDTH-1:0] ram_data;
    
    simple_dual_one_clock bram_init (
        .clk (clk),
        .ena (write_ok),
        .enb (read_ok),
        .wea (write_ok),
        .addra (write_ptr),
        .addrb (read_ptr),
        .dia   (data_in),
        .dob   (ram_data)
        );
        
        always @(posedge clk or posedge SRST) begin
            if (SRST) begin
                write_ptr  <= 0;
                read_ptr   <= 0;
                data_count <= 0;
            end else begin
                if (write_ok) 
                    write_ptr <= write_ptr + 1'b1;
                if (read_ok)
                    read_ptr <= read_ptr + 1'b1; 
                if (write_ok && !read_ok)
                    data_count <= data_count + 1'b1;
                else if (!write_ok && read_ok)
                    data_count <= data_count - 1'b1;
            end
            
        end
        
    wire [WIDTH-1:0] data_pipe [0:READ_LATENCY-1];
    assign data_pipe[0] = ram_data;
        
    genvar stage;
    generate
        for (stage = 1; stage < READ_LATENCY; stage = stage + 1) begin : read_stages
        reg [WIDTH-1:0] stage_data;

        always @(posedge clk)
        stage_data <= data_pipe[stage-1];
        
            assign data_pipe[stage] = stage_data;
        end
    endgenerate
    
    assign data_out = SRST ? {WIDTH{1'b0}} : data_pipe[READ_LATENCY - 1];
    
    reg [READ_LATENCY-1:0] valid_pipe;
    integer i;

    always @(posedge clk or posedge SRST) begin
        if (SRST) begin
            valid_pipe <= 0;
        end else begin
            valid_pipe[0] <= read_ok;

            for (i = 1; i < READ_LATENCY; i = i + 1)
                valid_pipe[i] <= valid_pipe[i-1];
        end
    end
    
    assign valid = valid_pipe[READ_LATENCY-1];
        
endmodule
