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
parameter c = 8;
parameter r = 8; // We know this before hand.
parameter data_width = 8;

reg clk;
reg rst;
reg start_tb;
reg [data_width-1:0]input_image_part;
reg [data_width-1:0] I [0:r-1][0:c-1];
reg input_valid_tb;
reg [3:0]cindex=0;
reg [3:0]rindex=0;
wire output_image_produced;
wire [data_width-1:0]part_image_tb;
wire sum_part;
FSM_image dut(.input_valid(input_valid_tb),.input_image_part(input_image_part), .sum_part(sum_part),.part_image(part_image_tb),.start(start_tb),.clk(clk), .rst(rst), .output_image_produced(output_image_produced));


always #5 clk = ~clk;
initial begin
I[0][0] = 8'd100; I[0][1] = 8'd200; I[0][2] = 8'd50; I[0][3] = 8'd75; 
I[0][4] = 8'd25; I[0][5] = 8'd125; I[0][6] = 8'd175; I[0][7] = 8'd225; 

I[1][0] = 8'd30;  I[1][1] = 8'd60;  I[1][2] = 8'd90;  I[1][3] = 8'd120; 
I[1][4] = 8'd150; I[1][5] = 8'd180; I[1][6] = 8'd210; I[1][7] = 8'd240; 

I[2][0] = 8'd15;  I[2][1] = 8'd45;  I[2][2] = 8'd75;  I[2][3] = 8'd105; 
I[2][4] = 8'd135; I[2][5] = 8'd165; I[2][6] = 8'd195; I[2][7] = 8'd225; 

I[3][0] = 8'd5;   I[3][1] = 8'd10;  I[3][2] = 8'd20;  I[3][3] = 8'd30; 
I[3][4] = 8'd40;  I[3][5] = 8'd50;  I[3][6] = 8'd60;  I[3][7] = 8'd70; 

I[4][0] = 8'd80;  I[4][1] = 8'd90;  I[4][2] = 8'd100; I[4][3] = 8'd110; 
I[4][4] = 8'd120; I[4][5] = 8'd130; I[4][6] = 8'd140; I[4][7] = 8'd150; 

I[5][0] = 8'd160; I[5][1] = 8'd170; I[5][2] = 8'd180; I[5][3] = 8'd190; 
I[5][4] = 8'd200; I[5][5] = 8'd210; I[5][6] = 8'd220; I[5][7] = 8'd230; 

I[6][0] = 8'd5;   I[6][1] = 8'd15;  I[6][2] = 8'd25;  I[6][3] = 8'd35; 
I[6][4] = 8'd45;  I[6][5] = 8'd55;  I[6][6] = 8'd65;  I[6][7] = 8'd75; 

I[7][0] = 8'd255; I[7][1] = 8'd240; I[7][2] = 8'd225; I[7][3] = 8'd210; 
I[7][4] = 8'd195; I[7][5] = 8'd180; I[7][6] = 8'd165; I[7][7] = 8'd150;

	start_tb = 1'b0;
    clk = 1'b0;
    rst = 1'b0;  
    #1
    rst = 1'b1;  
    #5 rst = 1'b0; 
    cindex = 4'b0000;
    rindex = 4'b0000;
    #5
    input_valid_tb = 1'b1;
	repeat(64) begin
	
			input_image_part =  I[rindex][cindex];
			if (cindex < c-1) begin
			cindex =   cindex+1;
				end
			else begin
				cindex =  4'd0;
				rindex =  rindex +1;
			end		
		@(negedge clk);

end
	input_valid_tb = 1'b0;
    start_tb = 1'b1;
    // the output image was successfully produced after 1756ns or 1.756us
    #2002 rst = 1'b1; 
    #10 rst = 1'b0;
end
	
	
	initial begin
		
		#4000 $finish;
	end
endmodule
