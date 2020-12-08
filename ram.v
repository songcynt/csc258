// SW[3:0] data inputs
// SW[8:4] address inputs
// SW[9] write enable input
// KEY[0] clock input

// show address on hex 5 and 4
// show input data on hex2
// show data output of memory on hex 0

//`include "ram32x4.v"

module ram(SW, KEY, HEX0, HEX2, HEX4, HEX5);
	input [9:0] SW;
	input [3:0] KEY;
	
	output [6:0] HEX0, HEX2, HEX4, HEX5;
	
	wire [4:0] address;
	wire [3:0] datain;
	wire wren;
	wire clk;
	
	wire [3:0] address1;
	wire [3:0] dataout;
	
	
	assign address = SW[8:4];
	assign datain = SW[3:0];
	assign wren = SW[9];
	assign clk = KEY[0];
	
	
	ram32x4 r0 (
		.address(address),
		.clock(clk),
		.data(datain),
		.wren(wren),
		.q(dataout)
	);
	
	// show data output of memory on hex 0
	hex_decoder h0(
		.hex_digit(dataout),
		.segments(HEX0)
	);
	
	
	// show input data on hex2
	hex_decoder h2 (
		.hex_digit(datain),
		.segments(HEX2)
	);
	
	// show [3:0] address on hex 4
	hex_decoder h4(
		.hex_digit(address[3:0]),
		.segments(HEX4)
	);
	
	//show [4] address on hex 5
	assign address1[3:1] = 3'b000;
	assign address1[0] = address[4];
	
	hex_decoder h5(
		.hex_digit(address1),
		.segments(HEX5)
	);

	
endmodule


// decoder
module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule