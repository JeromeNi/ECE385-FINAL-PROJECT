module forward_propagation(input logic Clk, input logic Reset, input logic Prop_start,input logic CContinue,
input logic[7:0] input_pxl,/*input logic [11:0] write_addr,input logic write_en,*/
output logic [11:0] rd_addr_out,
output logic prop_done, output logic face_or_not,
output logic [6:0] AhexL,AhexU,BhexL,BhexU,HEX4,HEX5,HEX6,HEX7);

//there should be a ROM here for trained weights

//there should be a RAM here for downsampled image
logic [14:0] read_weight_addr;
logic [14:0] addr_2,addr_3,addr_4;
logic [31:0] data_of_weight;
logic clk,reset,prop_start,Continue;

assign clk = Clk;
/*
assign reset = ~Reset;
assign Continue = ~ CContinue;
assign prop_start = ~Prop_start;
*/
/*
sync button_sync (.Clk(clk), .d(CContinue), .q(Continue));*/
assign prop_start = Prop_start;
assign reset = Reset;
assign Continue = CContinue;

logic [14:0] addr_1_1,addr_1_2,addr_1_3,addr_1_4,addr_1_4_w,addr_1_4_b;
logic [31:0] w_1,w_2,w_3,w_4;
logic [11:0]  wr_addr,update_wr_addr;
logic wr_en_1,wr_en_2,wr_en_3,wr_en_4;
logic [11:0] rd_addr,update_rd_addr;
logic Ld_wr,Ld_rd;

logic[7:0] pxl_from_ram_1;
logic[7:0] pxl_from_ram_2;
logic[7:0] pxl_from_ram_3;
logic[7:0] pxl_from_ram_4;


/*
assign w_1 = 32'b00111101110011001100110011001101;
assign w_2 = 32'b00111101110011001100110011001101;
assign w_3 = 32'b00111101110011001100110011001101;
assign w_4 = 32'b00111101110011001100110011001101;
assign data_of_weight = 32'b00111101110011001100110011001101;
assign pxl_from_ram_1 = 8'b00000011;
assign pxl_from_ram_2 = 8'b00000001;
assign pxl_from_ram_3 = 8'b00000010;
assign pxl_from_ram_4 = 8'b00000010;
*/

rom1 rom_1 (
	.address(addr_1_1),
	.clock(clk),
	.q(w_1));

rom2 rom_2 (
	.address(addr_1_2),
	.clock(clk),
	.q(w_2));	
	
rom3 rom_3 (
	.address(addr_1_3),
	.clock(clk),
	.q(w_3));
	
rom4 rom_4 (
	.address(addr_1_4),
	.clock(clk),
	.q(w_4));

rom5 rom_5 (
	.address(read_weight_addr[7:0]),
	.clock(clk),
	.q(data_of_weight));
	
logic start_sig_1,start_sig_2,start_sig_3,start_sig_4;
logic end_sig_1,end_sig_2,end_sig_3,end_sig_4;

logic[9:0] pxl_counter_1;
logic[9:0] pxl_counter_2;
logic[9:0] pxl_counter_3;
logic[9:0] pxl_counter_4;
/*
pxl_1 p_1(
	.address(pxl_counter_1),
	.clock(clk),
	.q(pxl_from_ram_1));
	
		pxl_2 p_2(
	.address(pxl_counter_2),
	.clock(clk),
	.q(pxl_from_ram_2));
	
		pxl_3 p_3(
	.address(pxl_counter_3),
	.clock(clk),
	.q(pxl_from_ram_3));
	
		pxl_4 p_4(
	.address(pxl_counter_4),
	.clock(clk),
	.q(pxl_from_ram_4));*/
	
TT pic1(
	.data(input_pxl),
	.rdaddress(pxl_counter_1),
	.rdclock(clk),
	.wraddress(wr_addr[9:0]),
	.wrclock(clk),
	.wren(wr_en_1),
	.q(pxl_from_ram_1));
	
TT pic2(
	.data(input_pxl),
	.rdaddress(pxl_counter_2),
	.rdclock(clk),
	.wraddress(wr_addr[9:0]),
	.wrclock(clk),
	.wren(wr_en_2),
	.q(pxl_from_ram_2));
	
TT pic3(
	.data(input_pxl),
	.rdaddress(pxl_counter_3),
	.rdclock(clk),
	.wraddress(wr_addr[9:0]),
	.wrclock(clk),
	.wren(wr_en_3),
	.q(pxl_from_ram_3));
	
TT pic4(
	.data(input_pxl),
	.rdaddress(pxl_counter_4),
	.rdclock(clk),
	.wraddress(wr_addr[9:0]),
	.wrclock(clk),
	.wren(wr_en_4),
	.q(pxl_from_ram_4));

	
	
logic[4:0] layer_one_counter;
logic[2:0] layer_two_counter;
logic[2:0] layer_three_counter;

logic[31:0] layer_one_reg_out[19:0];
logic[31:0] layer_two_reg_out[6:0];
logic[31:0] layer_three_reg_out[4:0];
logic[31:0] layer_four_reg_out;

/*
logic[31:0] layer_one_reg[19:0];
logic[31:0] layer_two_reg[6:0];
logic[31:0] layer_three_reg[4:0];
logic[31:0] layer_four_reg;

logic Ld_one,Ld_two,Ld_three,Ld_four;

always_ff@(posedge clk)
begin
if(reset)
begin
    for(int i = 0; i < 20; i++)
	     layer_one_reg[i] <= {32{1'b0}};
end
else if(Ld_one)
    for(int i = 0; i < 20; i++)
	     layer_one_reg[i] <= layer_one_reg_out[i];
end

always_ff@(posedge clk)
begin
if(reset)
begin
    for(int i = 0; i < 7; i++)
	     layer_two_reg[i] <= {32{1'b0}};
end
else if(Ld_two)
    for(int i = 0; i < 7; i++)
	     layer_two_reg[i] <= layer_two_reg_out[i];
end

always_ff@(posedge clk)
begin
if(reset)
begin
    for(int i = 0; i < 5; i++)
	     layer_three_reg[i] <= {32{1'b0}};
end
else if(Ld_three)
    for(int i = 0; i < 5; i++)
	     layer_three_reg[i] <= layer_three_reg_out[i];
end

always_ff@(posedge clk)
begin
if(reset)
begin
	 layer_four_reg <= {32{1'b0}};
end
else if(Ld_four)
    layer_four_reg[i] <= layer_four_reg_out[i];
end
*/

logic [31:0]layer_one_unit;
logic [31:0]layer_two_unit;
logic [31:0]layer_three_unit;

logic bias;

paralle_first_layer hier_first(.clk, .reset,.start(start_sig_1),.pxl_1(pxl_from_ram_1),
.pxl_2(pxl_from_ram_2),.pxl_3(pxl_from_ram_3),.pxl_4(pxl_from_ram_4),
.w_1,.w_2,.w_3,.w_4,
.read_addr_1(addr_1_1),.read_addr_2(addr_1_2),.read_addr_3(addr_1_3),
.read_addr_4(addr_1_4_w),
.bias_addr(addr_1_4_b),
.pxl_counter_1,
.pxl_counter_2,
.pxl_counter_3,
.pxl_counter_4,
.layer_one_reg_out,
.bias,.done(end_sig_1));

always_comb
begin
if(bias)
    addr_1_4 = addr_1_4_b;
else
    addr_1_4 = addr_1_4_w;
end


second_layer_hierachial hier_second(.clk,.reset,.start(start_sig_2),
.layer_one_out(layer_one_unit),.w(data_of_weight),.read_addr(addr_2),
.done(end_sig_2), .layer_one_counter,.layer_two_reg_out);

third_layer_hierachial hier_third(.clk,.reset,.start(start_sig_3),
.layer_two_out(layer_two_unit),.w(data_of_weight),.read_addr(addr_3),
.done(end_sig_3), .layer_two_counter,.layer_three_reg_out);

output_layer classifier(.clk,.reset,.start(start_sig_4),
.layer_three_out(layer_three_unit),.w(data_of_weight),.read_addr(addr_4),
.done(end_sig_4), .layer_three_counter,.output_layer_out(layer_four_reg_out));

enum logic [3:0] {WAIT,READ_MEM,READ_MEM_1,WRITE_MEM,WRITE_MEM_1,LAYER_ONE,LAYER_TWO,LAYER_THREE,LAYER_FOUR,PSE_1,PSE_2} state,next_state;

always_ff@(posedge clk)
begin
if(reset)
    state <= WAIT;
else
    state <= next_state;
end


  always_ff @ (posedge clk)
  begin
  if(reset)
    wr_addr <= {12{1'b0}};
  else if(Ld_wr)
    wr_addr <= update_wr_addr;
  end
  
  always_ff @ (posedge clk)
  begin
  if(reset)
    rd_addr <= {12{1'b0}};
  else if(Ld_rd)
    rd_addr <= update_rd_addr;
  end

assign rd_addr_out = rd_addr;  
always_comb
begin
    next_state = state;
    unique case(state)
	 WAIT:
	 if(prop_start == 1'b1) 
	     next_state = READ_MEM;
	 READ_MEM:
	     next_state = READ_MEM_1;
	 READ_MEM_1:
	     next_state = WRITE_MEM;
	 WRITE_MEM:
	     next_state = WRITE_MEM_1;
	 WRITE_MEM_1:
	     if(rd_addr == 3599)
		      next_state = LAYER_ONE;
		  else
		      next_state = READ_MEM;
	 LAYER_ONE: 
	 if(end_sig_1 == 1'b1)
	     next_state = LAYER_TWO;
	 LAYER_TWO: 
	 if(end_sig_2 == 1'b1)
	     next_state = LAYER_THREE;
	 LAYER_THREE:
	 if(end_sig_3 == 1'b1)
	     next_state = LAYER_FOUR;
	 LAYER_FOUR:
	 if(end_sig_4 == 1'b1)
	     next_state = PSE_1;
	 PSE_1 : 
                if (~Continue) 
                    next_state = PSE_1;
                else 
                    next_state = PSE_2;
    PSE_2 : 
                if (Continue) 
                    next_state = PSE_2;
                else 
                    next_state = WAIT;
	 endcase
	 
	 read_weight_addr = {14{1'b0}};

    start_sig_1 = 1'b0;
	 start_sig_2 = 1'b0;
	 start_sig_3 = 1'b0;
	 start_sig_4 = 1'b0;

    layer_one_unit = {32{1'b0}};
    layer_two_unit = {32{1'b0}};
    layer_three_unit = {32{1'b0}};
	 prop_done = 1'b0;
	 face_or_not = 1'b0;
	 
	 update_wr_addr = {12{1'b0}};
    wr_en_1 = 1'b0;
	 wr_en_2 = 1'b0;
	 wr_en_3 = 1'b0;
	 wr_en_4 = 1'b0;
	 Ld_wr = 1'b0;
    update_rd_addr = {12{1'b0}};
    Ld_rd = 1'b0;
	 case(state)
	 WAIT:
	 begin
	 Ld_wr = 1'b1;
	 Ld_rd = 1'b1;
	 end
	 READ_MEM:;
	 READ_MEM_1:;
	 WRITE_MEM:
	 begin
	     if(rd_addr>=0 && rd_addr <900)
		      wr_en_1 = 1'b1;
		  else if(rd_addr>=900 && rd_addr <1800)
		      wr_en_2 = 1'b1;
		  else if(rd_addr>=1800 && rd_addr <2700)
		      wr_en_3 = 1'b1;
		  else if(rd_addr>=2700 && rd_addr <3600)
		      wr_en_4 = 1'b1;
	 end
	 WRITE_MEM_1:
	 begin
	     if(rd_addr>=0 && rd_addr <900)
		      wr_en_1 = 1'b1;
		  else if(rd_addr>=900 && rd_addr <1800)
		      wr_en_2 = 1'b1;
		  else if(rd_addr>=1800 && rd_addr <2700)
		      wr_en_3 = 1'b1;
		  else if(rd_addr>=2700 && rd_addr <3600)
		      wr_en_4 = 1'b1;
		  update_wr_addr = wr_addr + 1;
		  Ld_wr = 1'b1;
		  update_rd_addr = rd_addr + 1;
		  Ld_rd = 1'b1;
		  if(wr_addr == 899)
		  begin
		      Ld_wr = 1'b1;
				update_wr_addr ={12{1'b0}};
		  end
    end
	 LAYER_ONE:
	 begin
	 start_sig_1 = 1'b1;
	 end
	 LAYER_TWO:
	 begin
	 start_sig_2 = 1'b1;
	 layer_one_unit = layer_one_reg_out[layer_one_counter];
	 read_weight_addr = addr_2;
	 end
	 LAYER_THREE:
	 begin	 
	 start_sig_3 = 1'b1;
	 layer_two_unit = layer_two_reg_out[layer_two_counter];
	 read_weight_addr = addr_3;	 
	 end
	 LAYER_FOUR:
	 begin 
	 start_sig_4 = 1'b1;
	 layer_three_unit = layer_three_reg_out[layer_three_counter];
    read_weight_addr = addr_4;
	 end
	 PSE_1:
	 begin
	 prop_done = 1'b1;
	 if(layer_four_reg_out[31] != 1'b1)
	     face_or_not = 1'b1;
	 end
	 PSE_2:
	 begin
	 prop_done = 1'b1;
	 if(layer_four_reg_out[31] != 1'b1)
	     face_or_not = 1'b1;
	 end
	 
	 endcase

end
logic [3:0] F,A,C,E,first_four,second_four,third_four,fourth_four;

assign A = (face_or_not == 1'b1)?4'b1010:4'b0000;
assign F = (face_or_not == 1'b1)?4'b1111:4'b0000;
assign C = (face_or_not == 1'b1)?4'b1100:4'b0000;
assign E = (face_or_not == 1'b1)?4'b1110:4'b1111;
/*
assign first_four = (prop_done == 1'b1)?layer_four_reg_out[31:28]:4'b0000;
assign second_four = (prop_done == 1'b1)?layer_four_reg_out[27:24]:4'b0000;
assign third_four = (prop_done == 1'b1)?layer_four_reg_out[23:20]:4'b0000;
assign fourth_four = (prop_done == 1'b1)?layer_four_reg_out[19:16]:4'b0000;
*/

assign first_four = (prop_done == 1'b1)?layer_four_reg_out[31:28]:4'b0000;
assign second_four = (prop_done == 1'b1)?layer_four_reg_out[27:24]:4'b0000;
assign third_four = (prop_done == 1'b1)?layer_four_reg_out[23:20]:4'b0000;
assign fourth_four = (prop_done == 1'b1)?layer_four_reg_out[19:16]:4'b0000;
    HexDriver        HexAL (
                        .In0(A),
                        .Out0(AhexL) ); 
	 HexDriver        HexBL (
                        .In0(E),
                        .Out0(BhexL) ); 
	 HexDriver        HexAU (
                        .In0(F),
                        .Out0(AhexU) ); 
	 HexDriver        HexBU (
                        .In0(C),
                        .Out0(BhexU )); 
								
								
	 //When you extend to 8-bits, you will need more HEX drivers to view upper nibble of registers, for now set to 0
	 HexDriver        HexCU (
                        .In0(third_four),
                        .Out0(HEX5) );	
	 HexDriver        HexCL (
                       .In0(fourth_four),
                        .Out0(HEX4) ); 
								
	 HexDriver        HexDU (
                        .In0(first_four),
                        .Out0(HEX7) ); 
	 HexDriver        HexDL (
                        .In0(second_four),
                        .Out0(HEX6) ); 

endmodule
