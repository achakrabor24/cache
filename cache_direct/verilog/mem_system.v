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
    reg write_c, valid_in, ch, comp, done, enable;
    reg wr_m, rd_m;
    wire [4:0] tag_out;
    reg [4:0]tag_in, tag_m;
    reg [7:0] index;
    reg [2:0] offset;
    reg [15:0] data_in, data_in_m;
    wire [15:0] data_out, data_out_m, addr_mem;
    wire err_c, err_m;

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

    reg err_s;
    assign err = err_m | err_c | err_s;
    wire [5:0] state;
    reg [5:0] next_state;

    wire miss;
    assign miss = ~hit | (hit & ~valid);
    assign Done = done;

    dff i_dff[5:0] (.q(state), .d(next_state), .clk(clk), .rst(rst));

    parameter IDLE = 6'h00;

    parameter compRead  = 6'd1;
    parameter compWrite = 6'd2;

    parameter accessRead0 = 6'd3;
    parameter accessRead1 = 6'd4;
    parameter accessRead2 = 6'd5;
    parameter accessRead3 = 6'd6;

    parameter WB_0 = 6'd7;
    parameter WB_1 = 6'd8;
    parameter WB_2 = 6'd9;
    parameter WB_3 = 6'd10;

    parameter memRead0 = 6'd11;
    parameter memRead1 = 6'd12;
    parameter memRead2 = 6'd13;
    parameter memRead3 = 6'd14;

    parameter accessWrite0 = 6'd15;
    parameter accessWrite1 = 6'd16;
    parameter accessWrite2 = 6'd17;
    parameter accessWrite3 = 6'd18;

    parameter wb_xxx     = 6'd29;
    parameter writeCache = 6'd30;
    parameter DONE = 6'd31;

    parameter wait_0_0 = 6'd19;
    parameter wait_0_1 = 6'd20;

    parameter wait_1_0 = 6'd21;
    parameter wait_1_1 = 6'd22;

    parameter wait_2_0 = 6'd23;
    parameter wait_2_1 = 6'd24;

    parameter wait_3_0 = 6'd25;
    parameter wait_3_1 = 6'd26;

    parameter wait_4_0 = 6'd27;
    parameter wait_4_1 = 6'd28;

    parameter ERROR = 6'd50;

    reg [2:0] offset_m;

    assign CacheHit = ch;
    assign addr_mem = {tag_m, Addr[10:3], offset_m};
    assign DataOut = data_out;

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

      case(state)
        IDLE: begin
            enable = 1'b1;
            Stall = 1'b0;
            next_state = (Rd & Wr) ? ERROR :
                       (Rd & ~Wr) ? compRead :
                       (~Rd & Wr) ? compWrite : IDLE;
        end
        compRead: begin
            enable = 1'b1;
            comp = 1'b1;
            next_state = (hit & valid) ? IDLE :
                       (miss) ? (dirty) ? accessRead0 : accessWrite0 : ERROR;
            done = (hit & valid) ? 1'b1 : 1'b0;
            ch = (hit & valid) ? 1'b1 : 1'b0;
        end
        compWrite: begin
            enable = 1'b1;
            write_c = 1'b1;
            comp = 1'b1;
            next_state = (hit & valid) ? IDLE :
                         (miss) ? (dirty) ? accessRead0 : accessWrite0 : ERROR;
            done = (hit & valid) ? 1'b1 : 1'b0;
            ch = (hit & valid);
        end
        accessRead0: begin
            // store the cache value in mem after 4 cycles
            enable = 1'b1;
            offset = 3'd0;
            tag_m = (valid) ? tag_out : Addr[15:11];
            data_in_m = data_out;
            wr_m = 1'b1;
            offset_m = 3'b00_0;
            next_state = accessRead1;
        end
        accessRead1: begin
            enable = 1'b1;
            offset = 3'b01_0;
            tag_m = (valid) ? tag_out : Addr[15:11];
            data_in_m = data_out;
            wr_m = 1'b1;
            offset_m = 3'b01_0;
            next_state = accessRead2;
        end
        accessRead2: begin
            enable = 1'b1;
            offset = 3'b10_0;
            tag_m = (valid) ? tag_out : Addr[15:11];
            data_in_m = data_out;
            wr_m = 1'b1;
            offset_m = 3'b10_0;
            next_state = accessRead3;
        end
        accessRead3: begin
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
            next_state = accessWrite0;
        end
        accessWrite0: begin
            // ask mem for data @Addr, will be available 2 cycles later
            rd_m = 1'b1;
            offset_m = 3'b00_0;
            next_state = accessWrite1;
        end
        accessWrite1: begin
            rd_m = 1'b1;
            offset_m = 3'b01_0;
            next_state = accessWrite2;
        end
        accessWrite2: begin
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

            next_state = accessWrite3;
        end
        accessWrite3: begin
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
