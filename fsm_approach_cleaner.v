`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.02.2026 19:06:41
// Design Name: 
// Module Name: image_process
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

// ask sir, about the 128*128 registers or even more given that fpga does not have that many resources
// One option is BRAM but wait for his responce
// Do check in few iterations if implementation is working or not
// Also ask how it is shifting exactly the line buffer the 24 initial iterations?

// Task can only be created in a module/function/another_task; They are local to that thing
// Task run at simulation time and not compilation time whereas generate runs at compile time so generate cannot be used in tasks
// For that reason only generate cannot come inside function/task/always/initial as after they run, only then generate can expand but generate is only aalowed to expand in compile time. Generate lies in module only
// Tasks cannot create hardware, only modules can. Hence Task cannot have timing constructs like posedge/always/@, it executes in 0 simulation time
// Task are simulation- runtimed and are only allowed to be used in functions/always/initial
module FSM_image #(
    parameter c = 8,
    parameter r = 8, // We know this before hand.
    parameter data_width = 8,
    parameter pad_c = c + 2, // 10
    parameter pad_r = r +2,
    parameter kernel_size = 3,
    parameter idle = 0, 
    parameter pad = 1, 
    parameter line_buff_fill = 2, 
    parameter mac_and_shift = 3, 
    parameter done = 4  
)(

	input wire [data_width-1:0]input_image_part,
	input wire input_valid,
	input wire start,
    input wire clk,
    input wire rst,
    output reg output_image_produced, // It is a flag
    output [data_width-1:0]part_image,
    output sum_part
);
	//reg [data_width-1:0]kernel_sum; might need it if kernel changed.
	reg [3:0] i, j;  // Sized appropriately
	reg [3:0] n, m;
	//reg [1:0] p, o;  // Only need 0-2
	//reg zero_padding_done;
	reg [data_width-1:0] I [0:r-1][0:c-1];
	reg [data_width-1:0] K [0:kernel_size-1][0:kernel_size-1];
	reg [data_width-1:0] pad_I [0:pad_r-1][0:pad_c-1];
	// reg done_var_line_buff; // This is the flag for the initial right shift operation to fill the line buffer.
		// We wait for the line buff to get filled before starting MAC operation.
		
		
	
		// Filling the line buffer by shifting
	reg [data_width-1:0] line_buff [0:(3*pad_c) -1]; // 0 to 389(390) and 0 to 15(16 bits)
	wire insert_shift_buff_allowed;
	reg [3:0]insert_buff_row; // this is used to pick values from pad image matrix at the fixed 3,8(arbitrary for intuition) postion in line buffer.
	reg [3:0]insert_buff_col; // modify its parameter widths
		
	reg [19:0]sum; // The reason why it is 20 bits is given in my notepad.
	 reg [4:0]d;
	reg [3:0]row_image_index; // These indexes are used to place values in the output image matrix directly
	reg [3:0]col_image_index;
	reg [3:0]rindex; // These indexes are used to place values in the output image matrix directly
	reg [3:0]cindex;
	reg [data_width-1:0] output_I [0:r-1][0:c-1];
	integer shift_idx;
	
	reg [2:0]ps; reg [2:0]ns;
	
	assign part_image = output_I[row_image_index][col_image_index];
	assign sum_part = sum[19] & sum[18] & sum[17] & sum[16] & sum[15] & 
		                   sum[14] & sum[13] & sum[12] & sum[11] & 
		                   sum[10] & sum[9] & sum[8];
		          
		//  This variable is used to skip the 2 0(padded) values when they reach the centre of computation (border columns invalid stage is skipped)
		assign insert_shift_buff_allowed = (insert_buff_col == (pad_c-1) || insert_buff_col == (pad_c-2))? 1'b0:1'b1;
		// Don't get confused, get a pen and paper and just dry run a line buffer. When we are inserting a new value at 3,8 postion from the image matrix.
		// If that is at pad_c-1 or pad_c-2 postion then we encounter 0 0 at the centre of computation and we need to skip them.
		// The shifting automatically happens and we just implement the ignoring part in the ouput = sum block

	always @(posedge clk) begin // Initializing Image matrix
		if (rst == 1'b1) begin
			ps <= #1 idle;

		end
		else begin
			ps <= #1 ns;
		end
		
	end
	
	 // MAC and shift operation
	// --- DSP FRIENDLY MAC ---
	always @(*) begin
	    sum = (
	        (K[0][0] * line_buff[0]) +
	        (K[0][1] * line_buff[1]) +
	        (K[0][2] * line_buff[2]) +
	        (K[1][0] * line_buff[pad_c]) +
	        (K[1][1] * line_buff[pad_c+1]) +
	        (K[1][2] * line_buff[pad_c+2]) +
	        (K[2][0] * line_buff[2*pad_c]) +
	        (K[2][1] * line_buff[2*pad_c+1]) +
	        (K[2][2] * line_buff[2*pad_c+2])
	    ) >> 4;
	    for(d = 19; d>=8 ;d= d-1) begin // Did this to prevent synthesizer from eliminating the disconnected 
	    	sum[d] = sum[d];
	    end
	end
	
	always @(ps or start or m or n or row_image_index or col_image_index) begin	// next state logic depends on input(internal vars changing) and ps always
		case(ps)
			idle: begin if(start == 1'b1) begin ns = pad; end else begin ns = idle; end end
			pad: begin ns = line_buff_fill; end
			
			line_buff_fill: begin 	if (m == 0 && n ==0) begin ns = mac_and_shift; end 
									else begin  ns = line_buff_fill; end
			end
			mac_and_shift: begin 
				if ( row_image_index == r-1 && col_image_index == c-1) ns = done;
				else ns = mac_and_shift;
			end
			done: begin ns = done; end
			
			default: begin ns = idle; end
		endcase
			end
	
	always @(posedge clk) begin // mealy machine. Can be seq or comb.
		if (rst == 1'b1) begin 
	    		n <= #1 kernel_size-1;
				m <= #1 pad_c-1;		     
			 	row_image_index <= #1 1'b0;
				col_image_index <= #1 1'b0;
	     		insert_buff_row <= #1 kernel_size;
				insert_buff_col <= #1 4'd0;
				output_image_produced <= #1 1'b0;
				rindex <= #1 4'b0000;
				cindex <= #1 4'b0000;

		end
		else begin
		case(ps)
			idle: begin 
				if(input_valid == 1'b1) begin
						I[rindex][cindex] <= #1 input_image_part;
						
				 		if (cindex < c-1) begin
							cindex <= #1  cindex+1;
						end
						else begin
							cindex <= #1 4'd0;
							rindex <= #1 rindex +1;
						end
						
					
				
				end
		        
		        K[0][0] <= #1 8'd1; K[0][1] <= #1 8'd2; K[0][2] <= #1 8'd1;
		        K[1][0] <= #1 8'd2; K[1][1] <= #1 8'd4; K[1][2] <= #1 8'd2;
		        K[2][0] <= #1 8'd1; K[2][1] <= #1 8'd2; K[2][2] <= #1 8'd1;
		 end
			pad: begin 
				for ( i = 0; i < pad_r ; i = i+1) begin
				  for (j = 0; j< pad_c ; j = j+1) begin
					if ((i>=1) && (i <= (pad_r-2)) && (j >= 1) && (j <= (pad_c - 2))) begin
						pad_I[i][j] <= #1 I[i - 1][j - 1];
					end
					else begin
						pad_I[i][j] <= #1 {data_width{1'b0}};
					end
				  end
				end

			end
			line_buff_fill: begin // Initial filling of line buffer operation.
	        	if (m>=0 && (m!=4'd15)) begin	
					line_buff[0] <= #1 pad_I[n][m];
					m <= #1 m-1;

				end
	        	else if(m == 4'd15 ) begin // -1 in unsigned is 15(1111) as it wraps arounds
					line_buff[0] <=  #1 pad_I[n-1][pad_c-1];
					m <= #1 pad_c-2;
					n <= #1 n-1;
				end
				// Shift right (fill mode)
	         	for (shift_idx = (3*pad_c)-1; shift_idx >= 1; shift_idx = shift_idx - 1) begin
				    line_buff[shift_idx] <= #1 line_buff[shift_idx-1];
				end								
		 	end
			mac_and_shift: begin 
				if (insert_shift_buff_allowed == 1'b1) begin //MAC is optional(invalid skip) but shift will necessarily happen here
					output_I[row_image_index][col_image_index] <= #1 sum[7:0];
			 		if (col_image_index < c-1) begin
						col_image_index <= #1  col_image_index+1;
					end
					else begin
						col_image_index <= #1 4'd0;
						row_image_index <= #1 row_image_index +1;
					end
					
				end
				// Shift left for compute (Happens always)
			    for (shift_idx = 0; shift_idx <= (3*pad_c)-2; shift_idx = shift_idx + 1) begin
					line_buff[shift_idx] <= #1 line_buff[shift_idx+1];
				end
				
				// Entire block just to place a new value in the line_buffer (happens always)
	     		 if (insert_buff_row <= pad_r-1 && insert_buff_col <= pad_c-1 ) begin
	    	     	line_buff[(3*pad_c)-1] <= #1 pad_I[insert_buff_row][insert_buff_col];
	    	     end
	    	     
	    	     if(insert_buff_col < pad_c-1) insert_buff_col <= #1 insert_buff_col +1;
	    	     else begin
	    	     	insert_buff_col <= #1  1'b0;
	    	     	insert_buff_row <= #1 insert_buff_row + 1;
	    	     
	    	     end

				
			
			end
			done: begin  // Is there any power saving technique that we can apply to shut this hardware off after it reaches this done state?
				output_image_produced <= #1 1'b1;

			end
			default: begin 
			end
		endcase
		
		end
	end
		

	
endmodule
