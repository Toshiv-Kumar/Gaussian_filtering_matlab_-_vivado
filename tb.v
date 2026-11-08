`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.02.2026 23:54:19
// Design Name: 
// Module Name: TB
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


module TB();
parameter data_width = 8;
reg clk;
reg rst;
wire output_image_produced;
wire [data_width-1:0]part_image_tb;
wire sum_part;
image_process dut(.sum_part(sum_part),.part_image(part_image_tb),.clk(clk), .rst(rst), .output_image_produced(output_image_produced));


always #5 clk = ~clk;
initial begin
    clk = 1'b0;
    rst = 1'b0;  
    #1
    rst = 1'b1;  
    #5 rst = 1'b0; 
end
	
	
	initial begin
		
		#1200 $finish;
	end
endmodule
