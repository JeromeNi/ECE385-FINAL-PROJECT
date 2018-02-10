module third_layer_hierachial#(parameter num_pixels = 7)(input logic clk, input logic reset,input logic start,
input logic[31:0] layer_two_out,input logic [31:0] w,output logic [14:0] read_addr,
output logic done, output logic[2:0] layer_two_counter,output logic[31:0] layer_three_reg_out[4:0]);


enum logic [2:0] {WAIT,CLEAR,COMPUTE_1,COMPUTE_2,BIAS_1,BIAS_2,DONE}state,next_state;
//there should be a ROM here

logic [2:0] pixel_counter,update_counter;

logic bias;

logic Ld_units,Ld_cnt;
logic start_sig, done_sig;

assign layer_two_counter = pixel_counter;

always_ff @ (posedge clk)
begin
    if(reset)
	     pixel_counter <= {3{1'b0}};
	 else if(Ld_cnt)
	     pixel_counter <= update_counter;
end

logic [31:0] layer_three_out[4:0];
logic [31:0] update_layer_three[4:0];
logic [2:0] w3_addr;
logic [14:0] rw3_addr,update_rw3_addr;
logic Ld_addr;
always_ff @(posedge clk)
begin
    if(reset)
	     rw3_addr <= 15'b000000010010011;
	 else if(Ld_addr)
	     rw3_addr <= update_rw3_addr;
end


always_ff @(posedge clk)
begin
    if(reset)
	     state <= WAIT;
	 else
	     state <= next_state;
end

logic [31:0] layer_three_reg[4:0];
logic [31:0] prev[4:0];

always_ff @(posedge clk)
begin
    if(reset)
	     for(int i = 0; i < 5; i++)
		      layer_three_reg[i] <= {32{1'b0}};
	 else if(Ld_units)			
	     for(int i = 0; i < 5; i++)
		      layer_three_reg[i] <= update_layer_three[i];
end

always_comb
begin
for(int i = 0; i < 5; i++)
    layer_three_reg_out[i] = (layer_three_reg[i][31] == 1'b0)? layer_three_reg[i]:{32{1'b0}}; 
end
assign prev = layer_three_reg;

third_hidden_layer layer_three
(.clk,.reset,.normalized_pxl(layer_two_out), .layer_start(start_sig),.w,.prev,.bias,
.layer_one_out(layer_three_out),.w1_addr(w3_addr),.layer_done(done_sig));

assign read_addr = w3_addr + rw3_addr;

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
	 for(int i = 0 ; i < 5; i++)
        update_layer_three[i] = {32{1'b0}};

    update_rw3_addr = 15'b000000010010011;
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
		      for(int i = 0; i < 5; i++)
		          update_layer_three[i] = layer_three_out[i];
		      Ld_units = 1'b1;
		  end
		  
		  else
		  	   start_sig = 1'b1;
	 end
	 COMPUTE_2:
	 begin
	 
        update_counter = pixel_counter + 1;
	     Ld_cnt = 1'b1;
        if(pixel_counter == 6)
            Ld_cnt = 1'b0;
        update_rw3_addr = rw3_addr + 5;
	     Ld_addr = 1'b1;
	 end
	 BIAS_1:
	 begin
	 if(done_sig == 1'b1)
		  begin
		      for(int i = 0; i < 5; i++)
		          update_layer_three[i] = layer_three_out[i];
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
	     update_rw3_addr = rw3_addr + 5;
	     Ld_addr = 1'b1;
	 end
	 DONE:
	 begin
	 
	     done = 1'b1;
	 end
	 
	 endcase

	 
end

endmodule
