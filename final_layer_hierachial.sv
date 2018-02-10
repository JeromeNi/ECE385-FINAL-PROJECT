module output_layer #(parameter num_pixels = 5)(input logic clk, input logic reset,input logic start,
input logic[31:0] layer_three_out,input logic [31:0] w,output logic [14:0] read_addr,
output logic done, output logic[2:0] layer_three_counter,output logic[31:0] output_layer_out);


enum logic [2:0] {WAIT,CLEAR,COMPUTE_1,COMPUTE_2,BIAS_1,BIAS_2,DONE}state,next_state;
//there should be a ROM here

logic [2:0] pixel_counter,update_counter;

logic bias;

logic Ld_units,Ld_cnt;
logic start_sig, done_sig;

assign layer_three_counter = pixel_counter;

always_ff @ (posedge clk)
begin
    if(reset)
	     pixel_counter <= {3{1'b0}};
	 else if(Ld_cnt)
	     pixel_counter <= update_counter;
end

logic [31:0] final_reg;
logic [31:0] update_final_reg;

logic [14:0] rw4_addr,update_rw4_addr;
logic Ld_addr;
always_ff @(posedge clk)
begin
    if(reset)
	     rw4_addr <= 15'b000000010111011;
	 else if(Ld_addr)
	     rw4_addr <= update_rw4_addr;
end


always_ff @(posedge clk)
begin
    if(reset)
	     state <= WAIT;
	 else
	     state <= next_state;
end

logic [31:0] final_layer;
logic [31:0] prev;

always_ff @(posedge clk)
begin
    if(reset)
        final_reg <= {32{1'b0}};
	 else if(Ld_units)			
		  final_reg <= update_final_reg;
end

always_comb
begin
    output_layer_out = /*(final_reg[31] == 1'b0)? */final_reg/*:{32{1'b0}}*/; 
end
assign prev = final_reg;

final_output_layer layer_four
(.clk,.reset,.normalized_pxl(layer_three_out), .layer_start(start_sig),.w,.prev,.bias,
.layer_one_out(final_layer),.layer_done(done_sig));

assign read_addr = rw4_addr;

always_comb
begin
    next_state = state;
    unique case(state)
	 WAIT:
	 if(start)
         next_state = CLEAR;
	 CLEAR:
	      next_state = COMPUTE_1;
	 COMPUTE_1:
	 if(done_sig == 1'b1)
	      next_state = COMPUTE_2;
	 COMPUTE_2:
	 if(pixel_counter == num_pixels -1)
	      next_state = BIAS_1;
	 else
	      next_state = COMPUTE_1;
    BIAS_1:
	 if(done_sig == 1'b1)
         next_state = BIAS_2;
	 BIAS_2:
	      next_state = DONE;
	 DONE:
	 if(~start)
	      next_state = WAIT;
	       
	 endcase
	 
    update_counter = {3{1'b0}};
	 Ld_cnt = 1'b0;
	 
    start_sig = 1'b0;
	 bias = 1'b0;
    
	 Ld_units = 1'b0;

    update_final_reg = {32{1'b0}};

    update_rw4_addr = 15'b000000010111011;
	 Ld_addr = 1'b0;
	 
	 done = 1'b0;
	 case(state)
	 WAIT:
	 begin
	 Ld_cnt = 1'b1;
	 Ld_addr = 1'b1;
	 end
	 CLEAR:
	 begin
	   Ld_units = 1'b1;
	 end
	 COMPUTE_1:
    begin
		  if(done_sig == 1'b1)
		  begin	      
		      update_final_reg = final_layer;
		      Ld_units = 1'b1;
		  end
		  
		  else
		  	   start_sig = 1'b1;
	 end
	 COMPUTE_2:
	 begin
	 
        update_counter = pixel_counter + 1;
	     Ld_cnt = 1'b1;
		  if(pixel_counter == 4)
            Ld_cnt = 1'b0;
        update_rw4_addr = rw4_addr + 1;
	     Ld_addr = 1'b1;
	 end
	 BIAS_1:
	 begin
	 if(done_sig == 1'b1)
		  begin
		      update_final_reg = final_layer;
		      Ld_units = 1'b1;
		  end
		  
		  else
		  begin
		  	   start_sig = 1'b1;
				bias = 1'b1;
		  end
	 end
	 BIAS_2:
	 begin
	     update_rw4_addr = rw4_addr + 1;
	     Ld_addr = 1'b1;
	 end
	 DONE:
	 begin
	 
	     done = 1'b1;
	 end
	 
	 endcase

	 
end

endmodule


module final_output_layer
(input logic clk,reset,input logic [31:0] normalized_pxl, input logic layer_start,
input logic [31:0] w,input logic[31:0] prev,input logic bias,
output logic[31:0] layer_one_out,output logic layer_done);

enum logic [3:0]{WAIT,WAIT_MEM,WAIT_MEM_2,COMPUTE_1,MULTIPLY_1,MULTIPLY_2,ADD,ADD_WAIT,DONE} state, next_state;

logic Ld_un;

logic [31:0] input_a,input_b,update_accu_m,hold_result,update_accu;

logic[31:0] layer_one;

multiplier multi(
		.clk,    //    clk.clk
		.areset(reset), // areset.reset
		.a(input_a),      //      a.a
		.b(input_b),      //      b.b
		.q(update_accu_m)       //      q.q
	);
	
add adder(
		.clk,    //    clk.clk
		.areset(reset), // areset.reset
		.a(input_a),      //      a.a
		.b(input_b),      //      b.b
		.q(update_accu)       //      q.q
	);
	
always_ff @(posedge clk)
begin
    if(reset)
	     state <= WAIT;
	 else
	     state <= next_state;
end


always_ff @(posedge clk)
begin
    if(reset)
	     layer_one <= {32{1'b0}};
    else if(Ld_un)
	     layer_one <= hold_result;
end
assign layer_one_out = layer_one;
always_comb
begin
    next_state = state;
	 unique case(state)
	     WAIT:
		      if(layer_start)
				    next_state = WAIT_MEM;
		  WAIT_MEM:
		          next_state = WAIT_MEM_2;
		  WAIT_MEM_2:
		  begin
		          next_state = COMPUTE_1;
					 if(bias)
					     next_state = ADD;
		  end				
		  COMPUTE_1:
				    next_state = MULTIPLY_1;
		  MULTIPLY_1:
		          next_state = MULTIPLY_2;
		  MULTIPLY_2:
		          next_state = ADD;
		  ADD:
		          next_state = ADD_WAIT;
		  ADD_WAIT:
		          next_state = DONE;
		  DONE:
		      if(~layer_start)
				    next_state = WAIT;
	 endcase

	 hold_result = {32{1'b0}};
	 Ld_un = 1'b0;

    input_a = {32{1'b0}};
	 input_b = {32{1'b0}};
	 
	 layer_done = 1'b0;
	 
	 case(state)
	     WAIT:;
		  WAIT_MEM:;
		  
		  WAIT_MEM_2:;
		  
		  COMPUTE_1:
        begin

        input_a = w;
	     input_b = normalized_pxl;
		  
		  end
		  
		  MULTIPLY_1:
		  begin
		  
		  input_a = w;
	     input_b = normalized_pxl;
		  
		  end
		  MULTIPLY_2:
		  begin
		  hold_result = update_accu_m;
		  
		  input_a = w;
	     input_b = normalized_pxl;

	     Ld_un = 1'b1;

		  end
		  ADD:
		  begin
		  input_a = prev;
		  input_b = layer_one;
		  if(bias)
		      input_b = w;
		  end
		  ADD_WAIT:
		  begin
		  input_a = prev;
		  input_b = layer_one;
		  if(bias)
		      input_b = w;
		  hold_result = update_accu;
		  Ld_un = 1'b1;
		  end	  
		  DONE:
		  begin
		  
	     layer_done = 1'b1;
		  
		  end
	 endcase
	 
end


endmodule

module sync (
	input  logic Clk, d, 
	output logic q
);

always_ff @ (posedge Clk)
begin
	q <= d;
end

endmodule
