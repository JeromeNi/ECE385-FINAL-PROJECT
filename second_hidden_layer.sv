
module second_hidden_layer #(parameter units=7)
(input logic clk,reset,input logic [31:0] normalized_pxl, input logic layer_start,
input logic [31:0] w,input logic[31:0] prev[6:0],input logic bias,
output logic[31:0] layer_one_out[6:0],output logic[2:0] w1_addr,output logic layer_done);

enum logic [3:0]{WAIT,WAIT_MEM,WAIT_MEM_2,COMPUTE_1,MULTIPLY_1,MULTIPLY_2,ADD,ADD_WAIT,COMPUTE_2,DONE} state, next_state;

logic [2:0] unit_counter,update_unit;

logic Ld_uc,Ld_un;

logic [31:0] input_a,input_b,update_accu_m,hold_result,update_accu;

logic[31:0] layer_one[6:0];

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
	     unit_counter <= {3{1'b0}};
    else if(Ld_uc)
	     unit_counter <= update_unit;
end

always_ff @(posedge clk)
begin
    if(reset)
	      for(int i = 1; i < 7; i++)
			begin
			    layer_one[i] <= {32{1'b0}};
			end
    else if(Ld_un)
	     layer_one[unit_counter] <= hold_result;
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
		          next_state = COMPUTE_2;
		  COMPUTE_2:
		      if(unit_counter == units - 1)
				    next_state = DONE;
				else
				    next_state = WAIT_MEM;
		  DONE:
		      if(~layer_start)
				    next_state = WAIT;
	 endcase
    
	 update_unit ={3{1'b0}};
	 hold_result = {32{1'b0}};

    Ld_uc = 1'b0;
	 Ld_un = 1'b0;

    input_a = {32{1'b0}};
	 input_b = {32{1'b0}};
	 
	 layer_done = 1'b0;
	 
	 case(state)
	     WAIT:
		  Ld_uc = 1'b1;
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
		  input_a = prev[unit_counter];
		  input_b = layer_one[unit_counter];
		  if(bias)
		      input_b = w;
		  end
		  ADD_WAIT:
		  begin
		  input_a = prev[unit_counter];
		  input_b = layer_one[unit_counter];
		  if(bias)
		      input_b = w;
		  hold_result = update_accu;
		  Ld_un = 1'b1;
		  end
		  COMPUTE_2:
		  begin
		  
        update_unit = unit_counter + 1;

        if(unit_counter != 6)
            Ld_uc = 1'b1;
	 
        end		  
		  DONE:
		  begin
		  
	     layer_done = 1'b1;
		  
		  end
	 endcase
	 
end

assign w1_addr = unit_counter;	

endmodule

module third_hidden_layer #(parameter units=5)
(input logic clk,reset,input logic [31:0] normalized_pxl, input logic layer_start,
input logic [31:0] w,input logic[31:0] prev[4:0],input logic bias,
output logic[31:0] layer_one_out[4:0],output logic[2:0] w1_addr,output logic layer_done);

enum logic [3:0]{WAIT,WAIT_MEM,WAIT_MEM_2,COMPUTE_1,MULTIPLY_1,MULTIPLY_2,ADD,ADD_WAIT,COMPUTE_2,DONE} state, next_state;

logic [2:0] unit_counter,update_unit;

logic Ld_uc,Ld_un;

logic [31:0] input_a,input_b,update_accu_m,hold_result,update_accu;

logic[31:0] layer_one[4:0];

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
	     unit_counter <= {3{1'b0}};
    else if(Ld_uc)
	     unit_counter <= update_unit;
end

always_ff @(posedge clk)
begin
    if(reset)
	      for(int i = 1; i < 5; i++)
			begin
			    layer_one[i] <= {32{1'b0}};
			end
    else if(Ld_un)
	     layer_one[unit_counter] <= hold_result;
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
		          next_state = COMPUTE_2;
		  COMPUTE_2:
		      if(unit_counter == units - 1)
				    next_state = DONE;
				else
				    next_state = WAIT_MEM;
		  DONE:
		      if(~layer_start)
				    next_state = WAIT;
	 endcase
    
	 update_unit ={3{1'b0}};
	 hold_result = {32{1'b0}};

    Ld_uc = 1'b0;
	 Ld_un = 1'b0;

    input_a = {32{1'b0}};
	 input_b = {32{1'b0}};
	 
	 layer_done = 1'b0;
	 
	 case(state)
	     WAIT:
		  Ld_uc = 1'b1;
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
		  input_a = prev[unit_counter];
		  input_b = layer_one[unit_counter];
		  if(bias)
		      input_b = w;
		  end
		  ADD_WAIT:
		  begin
		  input_a = prev[unit_counter];
		  input_b = layer_one[unit_counter];
		  if(bias)
		      input_b = w;
		  hold_result = update_accu;
		  Ld_un = 1'b1;
		  end
		  COMPUTE_2:
		  begin
        update_unit = unit_counter + 1;

        if(unit_counter != 4)
            Ld_uc = 1'b1;
	 
        end		  
		  DONE:
		  begin
		  
	     layer_done = 1'b1;
		  
		  end
	 endcase
	 
end

assign w1_addr = unit_counter;	

endmodule
