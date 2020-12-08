//SW[7:0] data inputs
//KEY[2:0] function inputs

//LEDR[7:0] outputs SW[7:0] in binary
//HEX[6:0] outputs variety of things

module shifter(LEDR, SW, KEY);
    input [9:0] SW;
    input [3:0] KEY;
    output [9:0] LEDR;
    wire [7:0] LoadVal, Q;
    wire clock, Load_n, ShiftRight, ASR, reset_n;
    reg left_input;

    assign LoadVal[7:0] = SW[7:0];
    assign reset_n = SW[9];
    assign clock = KEY[0];
    assign Load_n = KEY[1];
    assign ShiftRight = KEY[2];
    assign ASR = KEY[3];

    always @(*)
    begin
	if (ASR == 1'b0)//Add 0's as input
            left_input <= 1'b0;
	else//Sign extension as input
            left_input <= Q[7];
    end

    ShifterBit s7(.load_val(LoadVal[7]), .in(left_input), .shift(ShiftRight), .load_n(Load_n), .clock(clock), .reset_n(reset_n), .out(Q[7]));
    ShifterBit s6(.load_val(LoadVal[6]), .in(Q[7]), .shift(ShiftRight), .load_n(Load_n), .clock(clock), .reset_n(reset_n), .out(Q[6]));
    ShifterBit s5(.load_val(LoadVal[5]), .in(Q[6]), .shift(ShiftRight), .load_n(Load_n), .clock(clock), .reset_n(reset_n), .out(Q[5]));
    ShifterBit s4(.load_val(LoadVal[4]), .in(Q[5]), .shift(ShiftRight), .load_n(Load_n), .clock(clock), .reset_n(reset_n), .out(Q[4]));
    ShifterBit s3(.load_val(LoadVal[3]), .in(Q[4]), .shift(ShiftRight), .load_n(Load_n), .clock(clock), .reset_n(reset_n), .out(Q[3]));
    ShifterBit s2(.load_val(LoadVal[2]), .in(Q[3]), .shift(ShiftRight), .load_n(Load_n), .clock(clock), .reset_n(reset_n), .out(Q[2]));
    ShifterBit s1(.load_val(LoadVal[1]), .in(Q[2]), .shift(ShiftRight), .load_n(Load_n), .clock(clock), .reset_n(reset_n), .out(Q[1]));
    ShifterBit s0(.load_val(LoadVal[0]), .in(Q[1]), .shift(ShiftRight), .load_n(Load_n), .clock(clock), .reset_n(reset_n), .out(Q[0]));

    assign LEDR[7:0] = Q[7:0];

endmodule


module ShifterBit(load_val, in, shift, load_n, clock, reset_n, out);
input load_val, in, shift, load_n, clock, reset_n;
output out;
wire data_from_other_mux, data_to_dff;

mux2to1 m1(.x(out), .y(in), .s(shift), .m(data_from_other_mux));
mux2to1 m2(.x(load_val), .y(data_from_other_mux), .s(load_n), .m(data_to_dff));
flipflop f0(.d(data_to_dff), .q(out), .clock(clock), .reset_n(reset_n));

endmodule

module flipflop(d, q, clock, reset_n);
    input d, clock, reset_n;
    output reg q;

    always @(posedge clock)
    begin  
        if (reset_n == 1'b0)
	    q <= 0;
        else
	    q <= d;
    end
endmodule

module mux2to1(x, y, s, m);
	input x;	//selected when s is 0
	input y;	//selected when s is 1
	input s;	//select signal
	output m;	//output
	
	assign m = s ? y : x;
endmodule
