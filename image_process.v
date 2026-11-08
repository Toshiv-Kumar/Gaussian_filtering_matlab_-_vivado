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
// Do check in few iterations if implementation is working or not?

// Task can only be created in a module/function/another_task; They are local to that thing
// Task run at simulation time and not compilation time whereas generate runs at compile time so generate cannot be used in tasks
// For that reason only generate cannot come inside function/task/always/initial as after they run, only then generate can expand but generate is only aalowed to expand in compile time. Generate lies in module only
// Tasks cannot create hardware, only modules can. Hence Task cannot have timing constructs like posedge/always/@, it executes in 0 simulation time
// Task are simulation- runtimed and are only allowed to be used in functions/always/initial
// output logic dependent on input and present state(mealy), it is moore here though. Can be seq or comb.
module image_process #(
    parameter c = 8,
    parameter r = 8, // We know this before hand.
    parameter data_width = 8,
    parameter pad_c = c + 2, // 10
    parameter pad_r = r +2,
    parameter kernel_size = 3 
    
)(
    input wire clk,
    input wire rst,
    output reg output_image_produced, // It is a flag
    output [data_width-1:0]part_image,
    output sum_part
);
	reg [data_width-1:0]kernel_sum;
	reg [3:0] i, j;  // Sized appropriately
	reg [3:0] n, m;
	reg [1:0] p, o;  // Only need 0-2
	reg zero_padding_done;
	reg [data_width-1:0] I [0:r-1][0:c-1];
	reg [data_width-1:0] K [0:kernel_size-1][0:kernel_size-1];
	always @(posedge clk) begin // Initializing Image matrix
		if ( rst == 1'b1) begin
				//kernel_sum <= 8'd16;
		        I[0][0] <= 8'd100; I[0][1] <= 8'd200; I[0][2] <= 8'd50; I[0][3] <= 8'd75; 
		        I[0][4] <= 8'd25; I[0][5] <= 8'd125; I[0][6] <= 8'd175; I[0][7] <= 8'd225; 
		        I[1][0] <= 8'd30;  I[1][1] <= 8'd60;  I[1][2] <= 8'd90;  I[1][3] <= 8'd120; 
		        I[1][4] <= 8'd150; I[1][5] <= 8'd180; I[1][6] <= 8'd210; I[1][7] <= 8'd240; 
		        I[2][0] <= 8'd15;  I[2][1] <= 8'd45;  I[2][2] <= 8'd75;  I[2][3] <= 8'd105; 
		        I[2][4] <= 8'd135; I[2][5] <= 8'd165; I[2][6] <= 8'd195; I[2][7] <= 8'd225; 
		        I[3][0] <= 8'd5;   I[3][1] <= 8'd10;  I[3][2] <= 8'd20;  I[3][3] <= 8'd30; 
		        I[3][4] <= 8'd40;  I[3][5] <= 8'd50;  I[3][6] <= 8'd60;  I[3][7] <= 8'd70; 
		        I[4][0] <= 8'd80;  I[4][1] <= 8'd90;  I[4][2] <= 8'd100; I[4][3] <= 8'd110; 
		        I[4][4] <= 8'd120; I[4][5] <= 8'd130; I[4][6] <= 8'd140; I[4][7] <= 8'd150; 
		        I[5][0] <= 8'd160; I[5][1] <= 8'd170; I[5][2] <= 8'd180; I[5][3] <= 8'd190; 
		        I[5][4] <= 8'd200; I[5][5] <= 8'd210; I[5][6] <= 8'd220; I[5][7] <= 8'd230; 
		        I[6][0] <= 8'd5;   I[6][1] <= 8'd15;  I[6][2] <= 8'd25;  I[6][3] <= 8'd35; 
		        I[6][4] <= 8'd45;  I[6][5] <= 8'd55;  I[6][6] <= 8'd65;  I[6][7] <= 8'd75; 
		        I[7][0] <= 8'd255; I[7][1] <= 8'd240; I[7][2] <= 8'd225; I[7][3] <= 8'd210; 
		        I[7][4] <= 8'd195; I[7][5] <= 8'd180; I[7][6] <= 8'd165; I[7][7] <= 8'd150;
		        
		        K[0][0] <= #1 8'd1; K[0][1] <= #1 8'd2; K[0][2] <= #1 8'd1;
		        K[1][0] <= #1 8'd2; K[1][1] <= #1 8'd4; K[1][2] <= #1 8'd2;
		        K[2][0] <= #1 8'd1; K[2][1] <= #1 8'd2; K[2][2] <= #1 8'd1;

		            
		        
		        
		end
		
	end
	
	reg [data_width-1:0] pad_I [0:pad_r-1][0:pad_c-1];
	
	always @(posedge clk) begin // To initialize the Image to padded version
		if (rst == 1'b1) begin
		zero_padding_done <= #1 1'b0;
		end
		else if (zero_padding_done == 1'b0 && output_image_produced == 1'b0) begin
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
			zero_padding_done <= #1 1'b1;
		end
	end
	
	
	reg done_var_line_buff; // This is the flag for the initial right shift operation to fill the line buffer.
	// We wait for the line buff to get filled before starting MAC operation.
	
	

	// Filling the line buffer by shifting
	reg [data_width-1:0] line_buff [0:(3*pad_c) -1]; // 0 to 389(390) and 0 to 15(16 bits)


	
	
	    always @(posedge clk) begin // Initial filling of line buffer operation. The right shift operation(like shift register) is done after 2 more always blocks that is happenning in sync with this block
	    	if (rst == 1'b1) begin
	    		n <= #1 kernel_size-1;
	    		m <= #1 pad_c-1;
	    		done_var_line_buff <= #1 1'b0;
	    	end
	        else if (done_var_line_buff == 1'b0 && zero_padding_done == 1'b1 && output_image_produced == 1'b0) begin
	        	if (m>=0 && (m!=4'd15)) begin	
	        		line_buff[0] <= #1 pad_I[n][m];
	        		m <= #1 m-1;
	        		if (m == 0 && n ==0) begin
	        			done_var_line_buff <= #1 1'b1;
	        		end
	        		end
	        	else if(m == 4'd15 ) begin // -1 in unsigned is 15(1111) as it wraps arounds
	        		line_buff[0] <=  #1 pad_I[n-1][pad_c-1];
	        		m <= #1 pad_c-2;
	        		n <= #1 n-1;
	        	end
	        	
	        end
	    end
	    
	wire insert_shift_buff_allowed;
	reg [3:0]insert_buff_row; // this is used to pick values from image matrix at the fixed 3,8(arbitrary for intuition) postion in line buffer.
	reg [3:0]insert_buff_col; // modify its parameter widths
	
	//  This variable is used to skip the 2 0(padded) values when they reach the centre of computation (border columns invalid stage is skipped)
	 assign insert_shift_buff_allowed = (insert_buff_col == (pad_c-1) || insert_buff_col == (pad_c-2))? 1'b0:1'b1;
	 // Don't get confused, get a pen and paper and just dry run a line buffer. When we are inserting a new value at 3,8 postion from the image matrix.
	 // If that is at pad_c-1 or pad_c-2 postion then we encounter 0 0 at the centre of computation and we need to skip them.
	 // The shifting automatically happens and we just implement the ignoring part in the ouput = sum block
	 
	 
	 
	 
	 reg [19:0]sum; // The reason why it is 20 bits is given in my notepad.
	 reg [4:0]d;
	 assign sum_part = sum[19] & sum[18] & sum[17] & sum[16] & sum[15] & 
	                   sum[14] & sum[13] & sum[12] & sum[11] & 
	                   sum[10] & sum[9] & sum[8];

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
	     for(d = 19; d>=8 ;d= d-1) begin
	     	sum[d] = sum[d];
	     end
	 end

	 reg [3:0]row_image_index; // These indexes are used to place values in the output image matrix directly
	 reg [3:0]col_image_index;
	 reg [data_width-1:0] output_I [0:r-1][0:c-1];
	 assign part_image = output_I[row_image_index][col_image_index];
	 
	 always @(posedge clk) begin // Done just to shift index for output matrix and put the mac computed value into output matrix
	 	if (rst == 1'b1) begin
	 		output_image_produced <= #1 1'b0;

	 		row_image_index <= #1 1'b0;
	 		col_image_index <= #1 1'b0;
	 	end
	 	else if( done_var_line_buff == 1'b1 && zero_padding_done == 1'b1 && insert_shift_buff_allowed == 1'b1 && output_image_produced == 1'b0) begin
	 		output_I[row_image_index][col_image_index] <= #1 sum[7:0];
	 		if ( row_image_index == r-1 && col_image_index == c-1) output_image_produced <= #1 1'b1;

	 		if (col_image_index < c-1) begin
	 			col_image_index <= #1  col_image_index+1;
	 		end
	 		else begin
	 			col_image_index <= #1 4'd0;
	 			row_image_index <= #1 row_image_index +1;
	 		end
	 		
	 		
	 		
	 	end
	 end
	 
	 integer shift_idx;
	 always @(posedge clk) begin  // this block includes initial shifing right to fill the line buffer and later shifting left for mac operation
	     if (rst == 1'b1) begin
	         // Reset
	     end
	     else if (done_var_line_buff == 1'b0 && zero_padding_done == 1'b1 && output_image_produced == 1'b0) begin
	         // Shift right (fill mode)
	         for (shift_idx = (3*pad_c)-1; shift_idx >= 1; shift_idx = shift_idx - 1) begin
	             line_buff[shift_idx] <= #1 line_buff[shift_idx-1];
	         end
	     end
	     else if (done_var_line_buff == 1'b1 && zero_padding_done == 1'b1 && output_image_produced == 1'b0) begin
	         // Shift left (compute mode)
	         for (shift_idx = 0; shift_idx <= (3*pad_c)-2; shift_idx = shift_idx + 1) begin
	             line_buff[shift_idx] <= #1 line_buff[shift_idx+1];
	         end
	     end
	 end

	 // Multi driven net issue arises here due to line_buff variable. Try to fix it for synthesis
	     always @(posedge clk) begin // Entire block just to place a new value in the line_buffer
	     	if(rst == 1'b1) begin
	     		insert_buff_row <= #1 kernel_size;
	     		insert_buff_col <= #1 4'd0;
	     	end
	     	
	     	else if (done_var_line_buff == 1'b1 && zero_padding_done == 1'b1 && output_image_produced == 1'b0) begin
	     		
	     		 if (insert_buff_row <= pad_r-1 && insert_buff_col <= pad_c-1 ) begin
	    	     	line_buff[(3*pad_c)-1] <= #1 pad_I[insert_buff_row][insert_buff_col];
	    	     end
	    	     
	    	     if(insert_buff_col < pad_c-1) insert_buff_col <= #1 insert_buff_col +1;
	    	     else begin
	    	     	insert_buff_col <= #1  1'b0;
	    	     	insert_buff_row <= #1 insert_buff_row + 1;
	    	     
	    	     end
	    	end
	     end

endmodule
