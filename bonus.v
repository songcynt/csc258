// Part 2 skeleton

module bonus
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn, ldx, ldy;
	

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    // Instansiate datapath
	 
	 datapath d0(
		.clk(CLOCK_50),
		.resetn(resetn),
		.inputx(ldx),
		.inputy(ldy),
		.colour_in(SW[9:7]),
		.coordinates(SW[6:0]),
		.colour_out(colour),
		.x_out(x),
		.y_out(y)
	 );

    // Instansiate FSM control
    control c0(
		.clk(CLOCK_50),
		.resetn(resetn),
		.go(~KEY[1]),
		.load(~KEY[3]),
		.inputx(ldx),
		.inputy(ldy),
		.plot(writeEn)
	 );
    
endmodule


//fsm that controls the implemented datapath
module control(clk, resetn, go, load, 
	inputx, inputy, plot);
	
	input clk, resetn, go, load;
	output reg inputx, inputy, plot;
	
	reg [3:0] current_state, next_state; 
	
    localparam  S_LOAD_X        = 4'd0,
                S_LOAD_X_WAIT   = 4'd1,
                S_LOAD_Y        = 4'd2,
                S_LOAD_Y_WAIT   = 4'd3,
                S_PLOT          = 4'd4;
					 
	// Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD_X: next_state = load ? S_LOAD_X_WAIT : S_LOAD_X;
                S_LOAD_X_WAIT: next_state = load ? S_LOAD_X_WAIT : S_LOAD_Y;
                S_LOAD_Y: next_state = go ? S_LOAD_Y_WAIT : S_LOAD_Y;
                S_LOAD_Y_WAIT: next_state = go ? S_LOAD_Y_WAIT : S_PLOT;
                S_PLOT: next_state = load ? S_LOAD_X : S_PLOT;
            default:     next_state = S_LOAD_X;
        endcase
    end // state_table
	 
	 always @(*)
    begin: enable_signals
		inputx = 1'b0;
		inputy = 1'b0;
		plot = 1'b0;
		case (current_state)
			S_LOAD_X: begin
				inputx = 1'b1;
				inputy = 1'b0;
				end
			S_LOAD_X_WAIT: begin
				inputx = 1'b1;
				inputy = 1'b0;
				end
			S_LOAD_Y: begin
				inputx = 1'b0;
				inputy = 1'b1;
				end
			S_LOAD_Y_WAIT: begin
				inputy = 1'b0;
				inputy = 1'b1;
				end
			S_PLOT: begin
				plot = 1'b1;
				end
		endcase
	 end
	 
	 
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_X;
        else
            current_state <= next_state;
    end // state_FFS
	
endmodule

// contains arithmetic circuitry and registers, controlled by FSM, that produce the xy values that are fed into vga
module datapath(clk, resetn, 
	inputx, inputy, 
	colour_in, coordinates,
	colour_out, x_out, y_out);

	input clk, resetn, inputx, inputy;
	input [2:0] colour_in;
	input [6:0] coordinates;
	
	output [2:0] colour_out;
	output [7:0] x_out;
	output [6:0] y_out;
	
	reg [2:0] colour;
	reg [7:0] x;
	reg [6:0] y;
	reg [3:0] counter;
	
	reg [19:0] delay_counter; // 0 to 833333
	reg [3:0] frame_counter; //0 to 15
	
	reg dirx; // 0 = left, 1 = right
	reg diry; // 0 = up, 1 = down
	
	always@(posedge clk)
	begin
		if (!resetn) begin
			delay_counter <= 20'd0;
		end
		else begin
			if (delay_counter >= 20'd833333) begin
				delay_counter <= 20'd0;
			end
			else begin
				delay_counter <= delay_counter + 1'b1;
			end
		end
	end
	
	always@(posedge clk)
	begin
		if (!resetn) begin
			frame_counter <= 4'd0;
		end
		else begin
			if (frame_counter == 4'b1111) begin
				frame_counter <= 4'b0000;
			end
			else begin
				if (delay_counter == 20'd833333) begin
				frame_counter <= frame_counter + 1'b1;
				end
			end
		end
	end
	
	always@(posedge clk) begin
		if (x == 8'd0 && dirx == 1'b0)
			dirx <= 1'b1;
		if (y == 7'd0 && diry == 1'b0)
			diry <= 1'b1;
			
		if (x == 8'd127 && dirx == 1'b1)
			dirx <= 1'b0;
			
		if (y == 7'd119 && diry == 1'b1)
			diry <= 1'b0;
			
	end
	
	always @ (posedge clk) begin
        if (!resetn) begin
            colour <= 3'd0; 
            x <= 8'd0; 
            y <= 7'd0; 
        end
        else begin
				colour <= colour_in;
				
				if (frame_counter == 4'b1110)
					colour <= 3'b000;
				
				if (frame_counter == 4'b1111) begin
					if (dirx)
						x <= x + 1'b1;
					else
						x <= x - 1'b1;
						
					if (diry)
						y <= y + 1'b1;
					else y <= y - 1'b1;
				end
			end
		  
    end
	 
	 always @ (posedge clk) begin
        if (!resetn) begin
            counter <= 4'b0000;
        end
        else begin
            if (counter == 4'b1111)
					counter <= 4'b0000;
				else
					counter <= counter + 1'b1;
        end
    end

	 assign colour_out = colour;
	 assign x_out = x + counter[1:0];
	 assign y_out = y + counter[3:2];

endmodule
