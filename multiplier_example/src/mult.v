`timescale 1ns / 1ps

module mult
(
    input clk,
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product
);

always @(posedge clk) begin
    product <= a * b;
end

endmodule
