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


    wire hit, dirty, valid;
    wire [4:0] tag_out;
    wire [15:0] data_out, data_out_m, addr_mem;
    wire err_c, err_m, errCtrl;

    wire write_c, valid_in, ch, comp, done, enable, stall;
    wire wr_m, rd_m;
    wire [4:0] tag_in, tag_m;
    wire [7:0] index;
    wire [2:0] offset, offset_m;
    wire [15:0] data_in, data_in_m;


    cache #(0 + memtype) c0(// Outputs
                          .tag_out              (tag_out),
                          .data_out             (data_out),
                          .hit                  (hit),
                          .dirty                (dirty),
                          .valid                (valid),
                          .err                  (err_c),
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
                          .write                (write_c),
                          .valid_in             (valid_in));

    wire stall_m;
    wire [3:0] busy_mem;

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

assign addr_mem = {tag_m, index, offset_m};

cache_controller cc(
// Outputs
.comp(comp), .valid_in(valid_in), .ch(CacheHit), .done(Done), .wr_m(wr_m), .rd_m(rd_m), .errCtrl(errCtrl), 
.write_c(write_c), .enable(enable), .index(index), .offset(offset), .tag_in(tag_in), 
.stall(stall), .data_in_m(data_in_m), .tag_m(tag_m), .offset_m(offset_m), .data_in(data_in),

// Inputs
.addr(Addr), .data_out(data_out), .data_input(DataIn), .hit(hit), .valid(valid), .dirty(dirty), .Rd(Rd), .Wr(Wr), .tag_out(tag_out), 
.data_out_m(data_out_m));

assign err = err_m | err_c | errCtrl;

assign DataOut = data_out;

// How to with reg type
always @* begin
  Stall = stall;
end


endmodule // mem_system

// DUMMY LINE FOR REV CONTROL :9:
