module second_layer_hierachial#(parameter num_pixels = 20)(input logic clk, input logic reset,input logic start,
input logic[31:0] layer_one_out,input logic [31:0] w,output logic [14:0] read_addr,
output logic done, output logic[4:0] layer_one_counter,output logic[31:0] layer_two_reg_out[6:0]);


enum logic [2:0] {WAIT,CLEAR,COMPUTE_1,COMPUTE_2,BIAS_1,BIAS_2,DONE}state,next_state;
//there should be a ROM here

logic [4:0] pixel_counter,update_counter;

logic bias;

logic Ld_units,Ld_cnt;
logic start_sig, done_sig;

assign layer_one_counter = pixel_counter;

always_ff @ (posedge clk)
begin
    if(reset)
	     pixel_counter <= {5{1'b0}};
	 else if(Ld_cnt)
	     pixel_counter <= update_counter;
end

logic [31:0] layer_two_out[6:0];
logic [31:0] update_layer_two[6:0];
logic [2:0] w2_addr;
logic [14:0] rw2_addr,update_rw2_addr;
logic Ld_addr;
always_ff @(posedge clk)
begin
    if(reset)
	     rw2_addr <= {15{1'b0}};
	 else if(Ld_addr)
	     rw2_addr <= update_rw2_addr;
end


always_ff @(posedge clk)
begin
    if(reset)
	     state <= WAIT;
	 else
	     state <= next_state;
end

logic [31:0] layer_two_reg[6:0];
logic [31:0] prev[6:0];

always_ff @(posedge clk)
begin
    if(reset)
	     for(int i = 0; i < 7; i++)
		      layer_two_reg[i] <= {32{1'b0}};
	 else if(Ld_units)			
	     for(int i = 0; i < 7; i++)
		      layer_two_reg[i] <= update_layer_two[i];
end

always_comb
begin
for(int i = 0; i < 7; i++)
    layer_two_reg_out[i] = (layer_two_reg[i][31] == 1'b0)? layer_two_reg[i]:{32{1'b0}}; 
end
assign prev = layer_two_reg;

second_hidden_layer layer_two
(.clk,.reset,.normalized_pxl(layer_one_out), .layer_start(start_sig),.w, .prev,.bias,
.layer_one_out(layer_two_out),.w1_addr(w2_addr),.layer_done(done_sig));

assign read_addr = w2_addr + rw2_addr;

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
	 
    update_counter = {5{1'b0}};
	 Ld_cnt = 1'b0;
	 
    start_sig = 1'b0;
	 bias = 1'b0;
    
	 Ld_units = 1'b0;
	 for(int i = 0 ; i < 7; i++)
        update_layer_two[i] = {32{1'b0}};

    update_rw2_addr = {15{1'b0}};
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
		      for(int i = 0; i < 7; i++)
		          update_layer_two[i] = layer_two_out[i];
		      Ld_units = 1'b1;
		  end
		  
		  else
		  	   start_sig = 1'b1;
	 end
	 COMPUTE_2:
	 begin
	 
        update_counter = pixel_counter + 1;
	     Ld_cnt = 1'b1;
		  if(pixel_counter == 19)
            Ld_cnt = 1'b0;

        update_rw2_addr = rw2_addr + 7;
	     Ld_addr = 1'b1;
	 end
	 BIAS_1:
	 begin
	 if(done_sig == 1'b1)
		  begin
		      for(int i = 0; i < 7; i++)
		          update_layer_two[i] = layer_two_out[i];
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
	     update_rw2_addr = rw2_addr + 7;
	     Ld_addr = 1'b1;
	 end
	 DONE:
	 begin
	 
	     done = 1'b1;
	 end
	 
	 endcase

	 
end

endmodule
