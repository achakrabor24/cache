/* $Author: karu $ */
/* $LastChangedDate: 2009-04-24 09:28:13 -0500 (Fri, 24 Apr 2009) $ */
/* $Rev: 77 $ */

module mem_system(/*AUTOARG*/
   // Outputs
   DataOut, Done, Stall, CacheHit, err, 
   // Inputs
   Addr, DataIn, Rd, Wr, createdump, clk, rst
   );
   
   input [15:0] Addr;
   input [15:0] DataIn;
   input        Rd;
   input        Wr;
   input        createdump;
   input        clk;
   input        rst;
   
   output [15:0] DataOut;
   output Done;
   output reg Stall;
   output CacheHit;
   output err;

   /* data_mem = 1, inst_mem = 0 *
    * needed for cache parameter */
   parameter memtype = 0;
   wire hit1, hit2, dirty1, dirty2, valid1, valid2, err_c1, err_c2;                                                     
   wire dirty, valid;
   reg write_c, valid_in, ch, comp, done, enable;
   wire write_c1, write_c2;
   reg wr_m, rd_m;
   wire [4:0] tag_out1, tag_out2, tag_out;
   reg [4:0]tag_in, tag_m;
   reg [7:0] index;
   reg [2:0] offset;
   reg [15:0] data_in, data_in_m;
   wire [15:0] data_out1, data_out2, data_out_m, addr_mem;
   wire err_m, err_c;
   
   cache #(0 + memtype) c0(// Outputs
                          .tag_out              (tag_out1),
                          .data_out             (data_out1),
                          .hit                  (hit1),
                          .dirty                (dirty1),
                          .valid                (valid1),
                          .err                  (err_c1),
                          // Inputs
                          .enable               (enable),
                          .clk                  (clk),
                          .rst                  (rst),
                          .createdump           (createdump),
                          .tag_in               (tag_in),
                          .index                (index),
                          .offset               (offset),
                          .data_in              (data_in),
                          .comp                 (comp),
                          .write                (write_c1),
                          .valid_in             (valid_in));
   cache #(2 + memtype) c1(// Outputs
                          .tag_out              (tag_out2),
                          .data_out             (data_out2),
                          .hit                  (hit2),
                          .dirty                (dirty2),
                          .valid                (valid2),
                          .err                  (err_c2),
                          // Inputs
                          .enable               (enable),
                          .clk                  (clk),
                          .rst                  (rst),
                          .createdump           (createdump),
                          .tag_in               (tag_in),
                          .index                (index),
                          .offset               (offset),
                          .data_in              (data_in),
                          .comp                 (comp),
                          .write                (write_c2),
                          .valid_in             (valid_in));

   wire stall_m;
   wire[3:0] busy_mem;

   four_bank_mem mem(// Outputs
                     .data_out          (data_out_m),
                     .stall             (stall_m),
                     .busy              (busy_mem),
                     .err               (err_m),
                     // Inputs
                     .clk               (clk),
                     .rst               (rst),
                     .createdump        (createdump),
                     .addr              (addr_mem),
                     .data_in           (data_in_m),
                     .wr                (wr_m),
                     .rd                (rd_m));
   
   // your code here
   wire hit;
   assign hit = (hit1 & valid1) | (hit2 & valid2);
   assign err_c = err_c2 | err_c1;

   reg err_s;
   assign err = err_m | err_c | err_s;

   wire [5:0] state;
   reg [5:0] next_state;
   wire miss;
 
   assign miss = ~hit;
   assign Done = done;

   dff i_dff[5:0] (.q(state), .d(next_state), .clk(clk), .rst(rst));
   
   wire [15:0] data_out;
   reg victim;
   wire victimway, victimway_in;
   reg invert;
   wire accessVictim, accessVictim_in;

   assign valid = valid1 | valid2;
 
   assign data_out = hit ? hit1 ? data_out1 : data_out2 :
                       comp ? victim ? data_out2 : data_out1 :
                       accessVictim ? data_out2 : data_out1;
 
   assign tag_out = hit ? hit1 ? tag_out1 : tag_out2 :
                       comp ? victim ? tag_out2 : tag_out1 :
                       accessVictim ? tag_out2 : tag_out1;
 
   assign dirty = hit ? hit1 ? dirty1 : dirty2 :
                       comp ? victim ? dirty2 : dirty1 :
                       accessVictim ? dirty2 : dirty1;
 
   assign write_c1 = hit1 ? write_c : comp ? 1'b0 : accessVictim ? 1'b0 : write_c;
   assign write_c2 = hit2 ? write_c : comp ? 1'b0 : ~accessVictim ? 1'b0 : write_c;
 
    // FSM States
   parameter IDLE = 6'h00;

   parameter CompareRead  = 6'd1;
   parameter CompareWrite = 6'd2;

   parameter AccessRead0 = 6'd3;
   parameter AccessRead1 = 6'd4;
   parameter AccessRead2 = 6'd5;
   parameter AccessRead3 = 6'd6;
   
   parameter AccessWrite0 = 6'd7;
   parameter AccessWrite1 = 6'd9;
   parameter AccessWrite2 = 6'd10;
   parameter AccessWrite3 = 6'd11;

   parameter wait_0_0 = 6'd12;
   parameter wait_0_1 = 6'd13;
   parameter wait_1_0 = 6'd14;
   parameter wait_1_1 = 6'd15;
   parameter wait_2_0 = 6'd16;
   parameter wait_2_1 = 6'd17;
   parameter wait_3_0 = 6'd18;
   parameter wait_3_1 = 6'd19;
   parameter wait_4_0 = 6'd20;
   parameter wait_4_1 = 6'd21;
   parameter ERROR = 6'd50;

   reg [2:0] offset_m;
 
   assign CacheHit = ch;
   assign addr_mem = {tag_m, Addr[10:3], offset_m};
   assign DataOut = data_out;
   assign victimway_in = invert ? ~victimway : victimway;
   assign accessVictim_in = comp ? victim : accessVictim;
 
   dff vic (.q(victimway), .d(victimway_in), .clk(clk), .rst(rst));
   dff avic (.q(accessVictim), .d(accessVictim_in), .clk(clk), .rst(rst));
 
   always @(*) begin

      next_state = state;
      valid_in = 1'b0;
      err_s = 1'b0;
      done = 1'b0;
      comp = 1'b0;
      write_c = 1'b0;
      enable = 1'b0;
      tag_in = Addr[15:11];
      index = Addr[10:3];
      offset = Addr[2:0];
      offset_m = 3'd0;
      Stall = 1'b1;
      tag_m = Addr[15:11];
      wr_m = 1'b0;
      rd_m = 1'b0;
      data_in_m = data_out;
      data_in = DataIn;
      ch = 1'b0;
      invert = 1'b0;
      victim = (~hit1 & hit2) | (valid1 & ~valid2) ? 1'b1 :
               (hit1 & ~hit2) ? 1'b0 : (valid1 & valid2) ? victimway : 1'b0;
 
      case(state)
         IDLE: begin
             enable = 1'b1;
             Stall = 1'b0;
             next_state = (Rd & Wr) ? ERROR :
                        (Rd & ~Wr) ? CompareRead :
                        (~Rd & Wr) ? CompareWrite : IDLE;
         end
         CompareRead: begin
             enable = 1'b1;
             comp = 1'b1;
             next_state = (hit & valid) ? IDLE :
                        (miss) ? (dirty) ? AccessRead0 : AccessWrite0 : ERROR;
             done = (hit & valid) ? 1'b1 : 1'b0;
             ch = (hit & valid) ? 1'b1 : 1'b0;
             invert = ch;
         end
         CompareWrite: begin
             enable = 1'b1;
             write_c = 1'b1;
             comp = 1'b1;
             next_state = (hit & valid) ? IDLE :
                          (miss) ? (dirty) ? AccessRead0 : AccessWrite0 : ERROR;
             done = (hit & valid) ? 1'b1 : 1'b0;
             ch = (hit & valid);
             invert = ch;
         end
         AccessRead0: begin
             // store the cache value in mem after 4 cycles
             enable = 1'b1;
             offset = 3'd0;
             tag_m = (valid) ? tag_out : Addr[15:11];
             data_in_m = data_out;
             wr_m = 1'b1;
             offset_m = 3'b00_0;
             next_state = AccessRead1;
         end
         AccessRead1: begin
             enable = 1'b1;
             offset = 3'b01_0;
             tag_m = (valid) ? tag_out : Addr[15:11];
             data_in_m = data_out;
             wr_m = 1'b1;
             offset_m = 3'b01_0;
             next_state = AccessRead2;
         end
         AccessRead2: begin
             enable = 1'b1;
             offset = 3'b10_0;
             tag_m = (valid) ? tag_out : Addr[15:11];
             data_in_m = data_out;
             wr_m = 1'b1;
             offset_m = 3'b10_0;
             next_state = AccessRead3;
         end
         AccessRead3: begin
             enable = 1'b1;
             offset = 3'b11_0;
             tag_m = (valid) ? tag_out : Addr[15:11];
             data_in_m = data_out;
             wr_m = 1'b1;
             offset_m = 3'b11_0;
             next_state = wait_0_0;
         end
         wait_0_0: begin                                                                                                  
             next_state = wait_0_1;
         end
         wait_0_1: begin
             next_state = wait_1_0;
         end
         wait_1_0: begin
             next_state = wait_1_1;
         end
         wait_1_1: begin
             next_state = wait_2_0;
         end
         wait_2_0: begin
             next_state = AccessWrite0;
         end     
         AccessWrite0: begin
             // ask mem for data @Addr, will be available 2 cycles later
             rd_m = 1'b1;
             offset_m = 3'b00_0;
             next_state = AccessWrite1;
         end     
         AccessWrite1: begin
             rd_m = 1'b1;
             offset_m = 3'b01_0;
             next_state = AccessWrite2;
         end     
         AccessWrite2: begin
             rd_m = 1'b1;
             offset_m = 3'b10_0;
 
             ///////////////////
             ////   Cache   //// 
             ///////////////////
             enable = 1'b1;
             offset = 3'b00_0;
             write_c = 1'b1;
             valid_in = 1'b1;
             data_in = data_out_m;                                                                                            
 
             next_state = AccessWrite3;
         end 
         AccessWrite3: begin
             rd_m = 1'b1;
             offset_m = 3'b11_0;
 
             ///////////////////
             ////   Cache   ////
             ///////////////////
             enable = 1'b1;
             offset = 3'b01_0;
             write_c = 1'b1;
             valid_in = 1'b1;
             data_in = data_out_m;
         
             next_state = wait_2_1;
         end 
         wait_2_1: begin
             ///////////////////
             ////   Cache   ////
             ///////////////////
             enable = 1'b1;
             offset = 3'b10_0;
             write_c = 1'b1;
             valid_in = 1'b1;
             data_in = data_out_m;
             next_state = wait_3_0;
         end 
         wait_3_0: begin
             ///////////////////
             ////   Cache   ////
             ///////////////////
             enable = 1'b1;
             offset = 3'b11_0;
             write_c = 1'b1;
             valid_in = 1'b1;
             data_in = data_out_m;
             next_state = Wr ? wait_4_0 : wait_3_1;
         end
         wait_3_1: begin
             ///////////////////
             ////   Cache   ////
             ///////////////////
             enable = 1'b1;
             done = 1'b1;
             next_state = IDLE;
         end
         wait_4_0: begin
             ///////////////////
             ////   Cache   ////
             ///////////////////
             enable = 1'b1;
             write_c = 1'b1;
             comp = 1'b1;
             valid_in = 1'b1;
             next_state = wait_3_1;
         end
         default: err_s = 1'b1;
       endcase
     end

endmodule // mem_system

   


// DUMMY LINE FOR REV CONTROL :9:
