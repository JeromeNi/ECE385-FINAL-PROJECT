module paralle_first_layer(input logic clk, input logic reset,input logic start,input logic[7:0] pxl_1,
input logic[7:0] pxl_2,input logic[7:0] pxl_3,input logic[7:0] pxl_4,
input logic[31:0] w_1,input logic[31:0] w_2,input logic [31:0] w_3,input logic [31:0] w_4,
output logic[14:0] read_addr_1,output logic[14:0] read_addr_2,output logic[14:0] read_addr_3,
output logic[14:0] read_addr_4,
output logic[14:0] bias_addr,
output logic[9:0] pxl_counter_1,
output logic[9:0] pxl_counter_2,
output logic [9:0] pxl_counter_3,
output logic [9:0] pxl_counter_4,
output logic [31:0] layer_one_reg_out[19:0],
output logic bias,output logic done);

enum logic [3:0] {WAIT,COMPUTE_1,COMPUTE_2,ADD_1,ADD_WAIT_1,ADD_2,ADD_WAIT_2,ADD_3,ADD_WAIT_3,WAIT_MEM_1,WAIT_MEM_2,BIAS_ADD,BIAS_WAIT,DONE} state,next_state;

logic [31:0] reg_one [19:0];
logic [31:0] reg_two [19:0];
logic [31:0] reg_three [19:0];
logic [31:0] reg_four [19:0];


logic [31:0] update_reg_one [19:0];
logic [31:0] update_reg_two [19:0];
logic [31:0] update_reg_three [19:0];
logic [31:0] update_reg_four [19:0];

logic Ld_1,Ld_2,Ld_3,Ld_4,Ld_cnt_f;
logic start_sig_1,start_sig_2,start_sig_3,start_sig_4;
logic end_sig_1,end_sig_2,end_sig_3,end_sig_4;

logic [31:0] input_a;
logic [31:0] input_b;
logic [31:0] update_accu_m;

logic[4:0] final_counter,update_final; 

logic [31:0] output_reg[19:0];
logic [31:0] update_output;
logic Ld_out;

first_layer_hierachial sub_one(.clk,.reset,.start(start_sig_1),
.pxl(pxl_1),.done(end_sig_1), .w(w_1), .read_addr(read_addr_1),.pxl_counter(pxl_counter_1),
.layer_one_reg_out(update_reg_one));

first_layer_hierachial sub_two(.clk,.reset,.start(start_sig_2),
.pxl(pxl_2),.done(end_sig_2), .w(w_2), .read_addr(read_addr_2),.pxl_counter(pxl_counter_2),
.layer_one_reg_out(update_reg_two));

first_layer_hierachial sub_three(.clk,.reset,.start(start_sig_3),
.pxl(pxl_3),.done(end_sig_3), .w(w_3), .read_addr(read_addr_3),.pxl_counter(pxl_counter_3),
.layer_one_reg_out(update_reg_three));

first_layer_hierachial sub_four(.clk,.reset,.start(start_sig_4),
.pxl(pxl_4),.done(end_sig_4), .w(w_4), .read_addr(read_addr_4),.pxl_counter(pxl_counter_4),
.layer_one_reg_out(update_reg_four));


add ADDER(
		.clk,    //    clk.clk
		.areset(reset), // areset.reset
		.a(input_a),      //      a.a
		.b(input_b),      //      b.b
		.q(update_accu_m)       //      q.q
	);


always_ff @ (posedge clk)
begin
    if(reset)
	     state <= WAIT;
	 else
	     state <= next_state;
end
logic [14:0] update_bias;
logic Ld_bias;

always_ff @ (posedge clk)
begin
    if(reset)
	     bias_addr <= 15'b100011001010000;
	 else if(Ld_bias)
	     bias_addr <= update_bias;
end
	  
always_ff @(posedge clk)
begin
    if(reset)
	 begin
	     for(int i = 0; i < 20; i++)
	         reg_one[i] <= {32{1'b0}};
    end
	 else if(Ld_1)
	 begin
        for(int i = 0; i < 20; i++)
		      reg_one[i] <= update_reg_one[i];
	 end
end

always_ff @(posedge clk)
begin
    if(reset)
	 begin
	     for(int i = 0; i < 20; i++)
	         output_reg[i] <= {32{1'b0}};
    end
	 else if(Ld_out)
	 begin
        output_reg[final_counter] <= update_output;
	 end
end

always_ff @(posedge clk)
begin
    if(reset)
	 begin
	     for(int i = 0; i < 20; i++)
	         reg_two[i] <= {32{1'b0}};
    end
	 else if(Ld_2)
	 begin
        for(int i = 0; i < 20; i++)
		      reg_two[i] <= update_reg_two[i];
	 end
end

always_ff @(posedge clk)
begin
    if(reset)
	 begin
	     for(int i = 0; i < 20; i++)
	         reg_three[i] <= {32{1'b0}};
    end
	 else if(Ld_3)
	 begin
        for(int i = 0; i < 20; i++)
		      reg_three[i] <= update_reg_three[i]; 
	 end
end

always_ff @(posedge clk)
begin
    if(reset)
	 begin
	     for(int i = 0; i < 20; i++)
	         reg_four[i] <= {32{1'b0}};
    end
	 else if(Ld_4)
	 begin
        for(int i = 0; i < 20; i++)
		      reg_four[i] <= update_reg_four[i];
	 end
end

always_ff @(posedge clk)
begin
    if(reset)
	 begin
	     final_counter <={5{1'b0}};
	 end
	 else if(Ld_cnt_f)
	 begin
	     final_counter <= update_final;
	 end
end

always_comb
begin
for(int i = 0; i < 20; i++)
    layer_one_reg_out[i] = (output_reg[i][31] == 1'b0)? output_reg[i]:{32{1'b0}}; 
end

always_comb
begin
    next_state = state;
    unique case(state)
	     WAIT:
		      if(start)
		          next_state = COMPUTE_1;
		  COMPUTE_1:
		      if(end_sig_1 == 1 && end_sig_2 == 1 && end_sig_3 == 1 && end_sig_4 == 1)
		          next_state = COMPUTE_2;
		  COMPUTE_2:
		      next_state = ADD_1;
		  ADD_1:
		      next_state = ADD_WAIT_1;
		  ADD_WAIT_1:
		      next_state = ADD_2;
		  ADD_2:
		      next_state = ADD_WAIT_2;
		  ADD_WAIT_2:
		      next_state = ADD_3;
		  ADD_3:
		      next_state = ADD_WAIT_3;
		  ADD_WAIT_3:
		      if(final_counter == 19)
		          next_state = WAIT_MEM_1;
			   else
				    next_state = ADD_1;
		  WAIT_MEM_1:
		      next_state = WAIT_MEM_2;
		  WAIT_MEM_2:
		      next_state = BIAS_ADD;
		  BIAS_ADD:
		      next_state = BIAS_WAIT;
		  BIAS_WAIT:
		      if(final_counter == 19)
		          next_state = DONE;
			   else
				    next_state = WAIT_MEM_1;
		  DONE:
		      if(~start)
				    next_state = WAIT;
	 endcase
	 
	 bias = 1'b0;
	 done = 1'b0;
	 
	 Ld_1 = 1'b0;
	 Ld_2 = 1'b0;
	 Ld_3 = 1'b0;
	 Ld_4 = 1'b0;
	 Ld_cnt_f = 1'b0;
	 Ld_out = 1'b0;
	 Ld_bias = 1'b0;
	 
    start_sig_1 = 1'b0;
	 start_sig_2 = 1'b0;
	 start_sig_3 = 1'b0;
	 start_sig_4 = 1'b0;
	 
	 input_a = {32{1'b0}};
    input_b = {32{1'b0}};
	 
    update_final = {5{1'b0}}; 
	 update_output = {32{1'b0}};
	 update_bias = 15'b100011001010000;
	 
	 case(state)
	 	  WAIT:
		  begin
			 Ld_cnt_f = 1'b1;
			 Ld_bias = 1'b1;
		  end
		  COMPUTE_1:
		  begin
          start_sig_1 = 1'b1;
  	       start_sig_2 = 1'b1;
	       start_sig_3 = 1'b1;
	       start_sig_4 = 1'b1;
		  end
		  COMPUTE_2:
		  begin	  
	       Ld_1 = 1'b1;
	       Ld_2 = 1'b1;
	       Ld_3 = 1'b1;
	       Ld_4 = 1'b1;
          			 
		  end
		  ADD_1:
		  begin 
	       input_a = reg_one[final_counter];
          input_b = reg_two[final_counter];
		  end
		  ADD_WAIT_1:
		  begin
		    input_a = reg_one[final_counter];
          input_b = reg_two[final_counter];
			 Ld_out = 1'b1;
			 update_output = update_accu_m;
		  end
		  ADD_2:
		  begin	 
	       input_a = output_reg[final_counter];
          input_b = reg_three[final_counter];		  
		  end
		  ADD_WAIT_2:
		  begin
	       Ld_out = 1'b1;
          input_a = output_reg[final_counter];
          input_b = reg_three[final_counter];	
          update_output = update_accu_m;		 
		  end
		  ADD_3:
		  begin
		    input_a = output_reg[final_counter];
          input_b = reg_four[final_counter];
		  end
		  ADD_WAIT_3:
        begin
		    Ld_out = 1'b1;
          input_a = output_reg[final_counter];
          input_b = reg_four[final_counter];	
          update_output = update_accu_m;
			 update_final = final_counter + 1;
			 Ld_cnt_f = 1'b1;
			 if (final_counter == 19)
			 begin
			     Ld_cnt_f = 1'b1;
				  update_final = {4{1'b0}};
			 end
		  end
		  WAIT_MEM_1:
		  begin
		      bias = 1'b1;
		  end
		  WAIT_MEM_2:
		  begin
		      bias = 1'b1;
		  end
		  BIAS_ADD:
		  begin
		     input_a = output_reg[final_counter];
			  input_b = w_4;
			  bias = 1'b1;
		  end
		  BIAS_WAIT:
        begin
		    Ld_out = 1'b1;
			 bias = 1'b1;
          input_a = output_reg[final_counter];
          input_b = w_4;
          update_output = update_accu_m;
			 update_final = final_counter + 1;
			 update_bias = bias_addr + 1;
			 Ld_bias = 1'b1;
			 Ld_cnt_f = 1'b1;
		  end
		  DONE:
		  begin
		      done = 1'b1;
		  end
	 endcase	 
end

endmodule
