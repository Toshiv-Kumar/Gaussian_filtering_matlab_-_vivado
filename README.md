Write all points given by gpt in synth checklist


dual line buffers (BRAM or shift RAM) to be used later
when scaling to a bigger image-: then don't forget to modifyi,j,m,n,o,p,d loop vars,  sum parameter's width. Scale if else statements-:"(m!=4'd15)) of line_buff_shift" Also scale row and col image_index too. Same for insert_buff_row and insert_buff_col. Sum var, Mac operation and. Also when scaling change the >> 4 to whichever kernel_sum you are trying to divide by and the combinational mac always block if kernel filter size or type are changed along with size of kernel and its og declaration. Sum bit's size is 16bits(8*2) +4 extra bits as 9 terms are added and we assume worst case when kernel value is 255 and image value is 255 too.
Change if conditions of next state deciding block if image declaration method later changes.
Operations:
No need of fsm, just use if else and multiple always blocks to minimize the number of clock cycles.
Declare non padded image 8*8. FSM state
Make the input matrix as padded. FSM state
Wait for the line buffer to get filled. FSM State
Do mac operation(comb) and store in output matrix(sequential) entirely scrammed up in one line only and skip the invalid border cols by assign separate statement by if statement.
Shift that line buff and place a new value in it. 5th and 6th point in single fsm state.
3rd point line buff, 6th point line buff in single always block for multi driven net issue.



Learnings:(Put some of these in synth checklist)-check reset in all blocks 1 or 0
Verilog synthesizer creates temporary registers larger registers capable of storing bigger sized value during expression evaluation, even if the operands are of smaller size
2. Always block can't be inside an initial block
3. A design is not synthesizable if it has no output or input ports or 1 of them not present.
4. Initial values for registers may not be synthesizable in all fpgas
5. If generate statement is used to generate copies of an always block then that design fails and it is not allowed as that causes the issue of multi driven net.
6. For loop in sequential block creates parallel hardware that assigns concurrently so don't do sum = sum + something as that will fail through for loop. got a good understanding about sequential/combinational logic inside for loop of a always(clk) block. Revise again from Verilog for fpga notes
7. Task can only be created in a module/function/another_task; They are local to that thing
Task run at simulation time and not compilation time whereas generate runs at compile time so generate cannot be used in tasks
For that reason only generate cannot come inside function/task/always/initial as after they run, only then generate can expand but generate is only aalowed to expand in compile time. Generate lies in module only
Tasks cannot create hardware, only modules can. Hence Task cannot have timing constructs like posedge/always/@, it executes in 0 simulation time
Task are simulation- runtimed and are only allowed to be used in functions/always/initial.
8. It is better to implement everything by fsm instead of done variables for every stage of your logic as that most probably helps in 3 things. One is structured code, 2nd is multi driven net issue eliminated(ouput logic in single always clk block with things separated by if else(non fsm) or case for fsm design) and third is that it is better to use idle state to replace what I did by using the synchronous reset as it is not necessary that the user will remember to press reset everytime and also make sure that after rst is pressed, your design should run from starting again even after one completion for both fsm and non-fsm approaches.
9. For a bigger sequential FSM, there may not be clear inputs and outputs. But an unconventional approach will work. For example, in this design I implemented Next state logic using (always @(ps , inputs)) and the output logic using always @(posedge clk)(as it is all sequential output) and case(ps) internally as moore machine depends on present state only.

FSM RTL version:
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
	
	always @(posedge clk) begin // output logic dependent on input and present state(mealy), it is moore here though. Can be seq or comb.
		if (rst == 1'b1) begin
	    		n <= #1 kernel_size-1;
				m <= #1 pad_c-1;
			 	row_image_index <= #1 1'b0;
				col_image_index <= #1 1'b0;
	     		insert_buff_row <= #1 kernel_size;
				insert_buff_col <= #1 4'd0;
				output_image_produced <= #1 1'b0;

		end
		else begin
		case(ps)
			idle: begin
	
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

Testbench part:
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
reg start_tb;
wire output_image_produced;
wire [data_width-1:0]part_image_tb;
wire sum_part;
FSM_image dut(.sum_part(sum_part),.part_image(part_image_tb),.start(start_tb),.clk(clk), .rst(rst), .output_image_produced(output_image_produced));


always #5 clk = ~clk;
initial begin
	start_tb = 1'b0;
    clk = 1'b0;
    rst = 1'b0;
    #1
    rst = 1'b1;
    #5 rst = 1'b0; start_tb = 1'b1;
    #1302 rst = 1'b1;
    #10 rst = 1'b0;
end
	
	
	initial begin
	
		#2500 $finish;
	end
endmodule
