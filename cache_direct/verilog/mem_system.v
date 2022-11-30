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


    // Internal signals
    wire write_cache, valid_in, ch, comp, done, enable, stall, stall_mem, write_mem, read_mem, errCache, errMem, errCtrl, hit, dirty, valid;
    wire [4:0] tag_out, tag_in, tag_mem;
    wire [7:0] index;
    wire [2:0] offset, offset_mem;
    wire [15:0] data_in, data_in_mem, data_from_cache, data_out_mem, addr_mem;
    wire [3:0] busy_mem;


    cache #(0 + memtype) c0(// Outputs
                          .tag_out              (tag_out),
                          .data_out             (data_from_cache),
                          .hit                  (hit),
                          .dirty                (dirty),
                          .valid                (valid),
                          .err                  (errCache),
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
                          .write                (write_cache),
                          .valid_in             (valid_in));


    four_bank_mem fb0(// Outputs
                     .data_out          (data_out_mem),
                     .stall             (stall_mem),
                     .busy              (busy_mem),
                     .err               (errMem),
                     // Inputs
                     .clk               (clk),
                     .rst               (rst),
                     .createdump        (createdump),
                     .addr              (addr_mem),
                     .data_in           (data_in_mem),
                     .wr                (write_mem),
                     .rd                (read_mem));



assign addr_mem = {tag_mem, index, offset_mem};

cache_controller cc(
// Outputs
.comp(comp), .valid_in(valid_in), .cache_hit(CacheHit), .done(Done), .wr_m(write_mem), .rd_m(read_mem), .errCtrl(errCtrl), 
.write_c(write_cache), .enable(enable), .index(index), .offset(offset), .tag_in(tag_in), 
.stall(stall), .data_in_m(data_in_mem), .tag_m(tag_mem), .offset_m(offset_mem), .data_in(data_in),

// Inputs
.addr(Addr), .data_out(data_from_cache), .data_input(DataIn), .hit(hit), .valid(valid), .dirty(dirty), .Rd(Rd), .Wr(Wr), .tag_out(tag_out), 
.data_out_m(data_out_mem));

assign err = errMem | errCache | errCtrl;

assign DataOut = data_from_cache;

// How to with output wire type and in this module reg type
always @* begin
  Stall = stall;
end


endmodule // mem_system

// DUMMY LINE FOR REV CONTROL :9:
