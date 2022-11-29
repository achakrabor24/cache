module cache_controller(
// Outputs
comp, valid_in, ch, done, enable, wr_m, rd_m, errCtrl, write_c, stall, 
index, offset, tag_in, data_in_m, data_in, tag_m, offset_m,

// Inputs
addr, data_out, data_input, hit, valid, dirty, Rd, Wr, tag_out, data_out_m
);

output reg [15:0] data_in_m, data_in;
output reg comp, valid_in, ch, done, enable, wr_m, rd_m, errCtrl, write_c, stall;
output reg [7:0] index;
output reg [2:0] offset, offset_m;
output reg [4:0] tag_in, tag_m;

input wire [15:0] addr, data_out, data_input, data_out_m;
input wire [4:0] tag_out;
input wire hit, valid, dirty, Rd, Wr;

// reg [2:0] offset_m;
// reg [4:0] tag_m;

wire miss;
wire [5:0] state;
reg [5:0] next_state;

/*
reg [15:0] addr_mem, data_in;
reg comp, write, valid_in, ch, done, enable, wr_m, rd_m, errCtrl, write_c, stall;
reg [7:0] index;
reg [2:0] offset;
reg [4:0] tag_in;
*/

dff dff0[5:0] (.q(state), .d(next_state), .clk(clk), .rst(rst));

assign miss = ~hit | (hit & ~valid);

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

always @(*) begin

        next_state = state;
        valid_in = 1'b0;
        errCtrl = 1'b0;
        done = 1'b0;
        comp = 1'b0;
        write_c = 1'b0;
        enable = 1'b0;
        tag_in = addr[15:11];
        index = addr[10:3];
        offset = addr[2:0];
        offset_m = 3'd0;
        stall = 1'b1;
        tag_m = addr[15:11];
        wr_m = 1'b0;
        rd_m = 1'b0;
        data_in_m = data_out;
        data_in = data_input;
        ch = 1'b0;

      case(state)
        IDLE: begin
            enable = 1'b1;
            stall = 1'b0;
            next_state = (Rd & Wr) ? ERROR : (Rd & ~Wr) ? compRead : (~Rd & Wr) ? compWrite : IDLE;
        end
        compRead: begin
            enable = 1'b1;
            comp = 1'b1;
            next_state = (hit & valid) ? IDLE : (miss) ? (dirty) ? accessRead0 : accessWrite0 : ERROR;
            done = (hit & valid) ? 1'b1 : 1'b0;
            ch = (hit & valid) ? 1'b1 : 1'b0;
        end
        compWrite: begin
            enable = 1'b1;
            write_c = 1'b1;
            comp = 1'b1;
            next_state = (hit & valid) ? IDLE : (miss) ? (dirty) ? accessRead0 : accessWrite0 : ERROR;
            done = (hit & valid) ? 1'b1 : 1'b0;
            ch = (hit & valid);
        end
        accessRead0: begin
            enable = 1'b1;
            offset = 3'd0;
            tag_m = (valid) ? tag_out : addr[15:11];
            data_in_m = data_out;
            wr_m = 1'b1;
            offset_m = 3'b00_0;
            next_state = accessRead1;
        end
        accessRead1: begin
            enable = 1'b1;
            offset = 3'b01_0;
            tag_m = (valid) ? tag_out : addr[15:11];
            data_in_m = data_out;
            wr_m = 1'b1;
            offset_m = 3'b01_0;
            next_state = accessRead2;
        end
        accessRead2: begin
            enable = 1'b1;
            offset = 3'b10_0;
            tag_m = (valid) ? tag_out : addr[15:11];
            data_in_m = data_out;
            wr_m = 1'b1;
            offset_m = 3'b10_0;
            next_state = accessRead3;
        end
        accessRead3: begin
            enable = 1'b1;
            offset = 3'b11_0;
            tag_m = (valid) ? tag_out : addr[15:11];
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
            enable = 1'b1;
            offset = 3'b01_0;
            write_c = 1'b1;
            valid_in = 1'b1;
            data_in = data_out_m;

            next_state = wait_2_1;
        end
        wait_2_1: begin
            enable = 1'b1;
            offset = 3'b10_0;
            write_c = 1'b1;
            valid_in = 1'b1;
            data_in = data_out_m;
            next_state = wait_3_0;
        end
        wait_3_0: begin
            enable = 1'b1;
            offset = 3'b11_0;
            write_c = 1'b1;
            valid_in = 1'b1;
            data_in = data_out_m;
            next_state = Wr ? wait_4_0 : wait_3_1;
        end
        wait_3_1: begin
            enable = 1'b1;
            done = 1'b1;
            next_state = IDLE;
        end
        wait_4_0: begin
            enable = 1'b1;
            write_c = 1'b1;
            comp = 1'b1;
            valid_in = 1'b1;
            next_state = wait_3_1;
        end
        default: errCtrl = 1'b1;
      endcase
    end


/*
assign comp_out = comp;
assign valid_in_out = valid_in;
assign ch_out = ch;
assign done_out = done;
assign wr_m_out = wr_m;
assign rd_m_out = rd_m;
assign errCtrl_out = errCtrl;
assign write_c_out = write_c;
assign addr_mem_out = addr_mem;
assign enable_out = enable;
assign index_out = index;
assign offset_out = offset;
assign tag_in_out = tag_in;
assign stall_out = stall;
*/

endmodule