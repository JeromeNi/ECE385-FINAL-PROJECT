module first_layer_hierachial#(parameter num_pixels = 900)(input logic clk, input logic reset,input logic start,
input logic[7:0] pxl,output logic done, input logic[31:0] w, output logic[14:0] read_addr,output logic[9:0] pxl_counter,output logic[31:0] layer_one_reg_out[19:0]);


enum logic [3:0] {WAIT,CLEAR,READ_MEM,WAIT_MEM,CONVERT,MULTIPLY,MULTIPLY_WAIT_1,MULTIPLY_WAIT_2,COMPUTE_1,COMPUTE_2,DONE}state,next_state;

logic [31:0] floating_pxl,input_a,input_b,update_normalized;
logic [31:0] normalized;
logic [9:0] pixel_counter,update_counter;

converter to_float(
		.clk,    //    clk.clk
		.areset(reset), // areset.reset
		.a(input_a[15:0]),      //      a.a
		.q(floating_pxl));
		
multiplier my_mult(
		.clk,    //    clk.clk
		.areset(reset), // areset.reset
		.a(input_a),      //      a.a
		.b(input_b),      //      b.b
		.q(normalized)       //      q.q
	);
	//00111011 10000000 00000000 00000000 
/*
add_mult adder(
		.clk,    //    clk.clk
		.areset(reset), // areset.reset
		.a(input_a),      //      a.a
		.b(input_b),      //      b.b
		.q(z)       //      q.q
	);
*/
logic[31:0] normalized_pxl;

logic Ld_pxl,Ld_units,Ld_cnt;
logic start_sig, done_sig;




assign pxl_counter = pixel_counter;

always_ff @ (posedge clk)
begin
    if(reset)
	     pixel_counter <= {10{1'b0}};
	 else if(Ld_cnt)
	     pixel_counter <= update_counter;
end

always_ff @ (posedge clk)
begin
    if(reset)
	     normalized_pxl <= {32{1'b0}};
	 else if(Ld_pxl)
	     normalized_pxl <= update_normalized;
end

logic [31:0] layer_one_out[19:0];
logic [31:0] update_layer_one[19:0];
logic [4:0] w1_addr;
logic [14:0] rw1_addr,update_rw1_addr;
logic Ld_addr;

always_ff @(posedge clk)
begin
    if(reset)
	     rw1_addr <= {15{1'b0}};
	 else if(Ld_addr)
	     rw1_addr <= update_rw1_addr;
end

assign read_addr = rw1_addr + w1_addr;
always_ff @(posedge clk)
begin
    if(reset)
	     state <= WAIT;
	 else
	     state <= next_state;
end

logic [31:0] layer_one_reg[19:0];
logic [31:0] prev[19:0];

always_ff @(posedge clk)
begin
    if(reset)
	     for(int i = 0; i < 20; i++)
		      layer_one_reg[i] <= {32{1'b0}};
	 else if(Ld_units)			
	     for(int i = 0; i < 20; i++)
		      layer_one_reg[i] <= update_layer_one[i];
end
always_comb
begin
for(int i = 0; i < 20; i++)
    layer_one_reg_out[i] = layer_one_reg[i];
	 
end
assign prev = layer_one_reg;

first_hidden_layer layer_one
(.clk,.reset,.normalized_pxl, .layer_start(start_sig),.w, .prev,
.layer_one_out(layer_one_out),.w1_addr,.layer_done(done_sig));

always_comb
begin
    next_state = state;
    unique case(state)
	 WAIT:
	 if(start)
         next_state = CLEAR;
	 CLEAR:
	     next_state = READ_MEM;
	 READ_MEM:
	      next_state = WAIT_MEM;
	 WAIT_MEM:
	      next_state = CONVERT;
	 CONVERT:
	      next_state = MULTIPLY;
	 MULTIPLY:
	      next_state = MULTIPLY_WAIT_1;
	 MULTIPLY_WAIT_1:
	      next_state = MULTIPLY_WAIT_2;
	 MULTIPLY_WAIT_2:
	      next_state = COMPUTE_1;
	 COMPUTE_1:
	 if(done_sig == 1'b1)
	      next_state = COMPUTE_2;
	 COMPUTE_2:
	 if(pixel_counter == num_pixels -1)
	      next_state = DONE;
	 else
	      next_state = READ_MEM;
	 DONE:
	 if(~start)
	      next_state = WAIT;
	       
	 endcase

    input_a = {32{1'b0}};
	 input_b = {32{1'b0}};
	 update_normalized = {32{1'b0}};
	 Ld_pxl = 1'b0;
	 
    update_counter = {10{1'b0}};
	 Ld_cnt = 1'b0;
	 
    start_sig = 1'b0;
    
	 Ld_units = 1'b0;
	 for(int i = 0 ; i < 20; i++)
        update_layer_one[i] = {32{1'b0}};

    update_rw1_addr = {15{1'b0}};
	 Ld_addr = 1'b0;
	 
	 done = 1'b0;
	 case(state)
	 WAIT:
	 begin
    Ld_cnt = 1'b1;
	 Ld_addr = 1'b1;
	 end
	 READ_MEM:;
    WAIT_MEM:;
	 CLEAR:
	 begin
	   Ld_units = 1'b1;
	 end
	 CONVERT:
	 begin
	     input_a = {{24{1'b0}},pxl};
		  Ld_pxl = 1'b1;
		  update_normalized = floating_pxl;
	 end
	 MULTIPLY:
	 begin
	     input_a = normalized_pxl;
	     input_b = 32'b00111011100000001000000010000001;
	 end
	 MULTIPLY_WAIT_1:
	 begin
	     input_a = normalized_pxl;
	     input_b = 32'b00111011100000000000000000000000;
	 end
	 MULTIPLY_WAIT_2:
	 begin
	     input_a = normalized_pxl;
	     input_b = 32'b00111011100000000000000000000000;
		  update_normalized = normalized;
		  Ld_pxl = 1'b1;
	 end
	 COMPUTE_1:
    begin
		  if(done_sig == 1'b1)
		  begin
		      for(int i = 0; i < 20; i++)
		          update_layer_one[i] = layer_one_out[i];
		      Ld_units = 1'b1;
		  end
		  
		  else
		  	   start_sig = 1'b1;
	 end
	 COMPUTE_2:
	 begin
	 
        update_counter = pixel_counter + 1;
	     Ld_cnt = 1'b1;
		  if(pixel_counter == 899)
            Ld_cnt = 1'b0;

        update_rw1_addr = rw1_addr + 20;
	     Ld_addr = 1'b1;
	 end
	 DONE:
	 begin
	 
	     done = 1'b1;
	 end
	 
	 endcase

	 
end

endmodule
