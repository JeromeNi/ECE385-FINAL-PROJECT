module testbench();

timeunit 10ns;	// Half clock cycle at 50 MHz
			// This is the amount of time represented by #1 
timeprecision 1ns;

// These signals are internal because the processor will be 
// instantiated as a submodule in testbench.

logic Clk;
logic Reset;
logic Prop_start;
logic CContinue;/*
logic[7:0] input_pxl;
logic [11:0] write_addr;
logic write_en;
*/
logic prop_done;
logic face_or_not;
logic [6:0] AhexL,AhexU,BhexL,BhexU,HEX4,HEX5,HEX6,HEX7;
logic[7:0] input_pxl;/*input logic [11:0] write_addr,input logic write_en,*/
logic [11:0] rd_addr_out;

		 
forward_propagation m0(.*);
logic [14:0] address;

// Toggle the clock
// #1 means wait for a delay of 1 timeunit
always begin : CLOCK_GENERATION
#1 Clk = ~Clk;
end

initial begin: CLOCK_INITIALIZATION
    Clk = 0;
end 
logic [31:0] internal_unit_1,internal_unit_2,internal_unit_3,internal_unit_4;
logic error_end,error_start;
logic [14:0] addr_1,addr_2,addr_3,addr_4;
logic [31:0] data1,data2,data3,data4;
logic [31:0] pxll;
logic [9:0] pxl_count;
logic [7:0] rpxl;
logic [31:0] w_4;
logic [11:0] wr_addr;
logic en_1,en_2,en_3,en_4;
always @ *
begin:INITERAL_SIG_MONITOR
	     internal_unit_1 = m0.layer_one_reg_out[19];
		  internal_unit_2 = m0.layer_two_reg_out[6];
		  internal_unit_3 = m0.layer_three_reg_out[4];
        internal_unit_4 = m0.layer_four_reg_out;
		  error_end = m0.end_sig_1;
		  error_start = m0.start_sig_1;
		  address = m0.read_weight_addr;
		  addr_1 = m0.addr_1_1;
		  addr_2 = m0.addr_1_2;
		  addr_3 = m0.addr_1_3;
		  addr_4 = m0.addr_1_4;
		  data1 = m0.w_1;
		  data2 = m0.w_2;
		  data3 = m0.w_3;
		  data4 = m0.w_4;
		  pxll = m0.hier_first.sub_one.normalized_pxl;
		  pxl_count = m0.pxl_counter_1;
		  rpxl = m0.pxl_from_ram_1;
		  en_1 = m0.wr_en_1;
		  en_2 = m0.wr_en_2;
		  en_3 = m0.wr_en_3;
		  en_4 = m0.wr_en_4;
		  wr_addr = m0.wr_addr;
end

// Testing begins here
// The initial block is not synthesizable
// Everything happens sequentially inside an initial block
// as in a software program
initial begin: TEST_VECTORS
Reset = 1;		// Toggle Rest

#2 Reset = 0;
   Prop_start = 1'b1;
	//CContinue = 1'b1;


	
end


endmodule
