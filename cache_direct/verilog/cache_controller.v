module cache_controller(
// Outputs
comp, valid_in, cache_hit, done, enable, wr_m, rd_m, errCtrl, write_c, stall, 
index, offset, tag_in, data_in_m, data_in, tag_m, offset_m,

// Inputs
addr, data_out, data_input, hit, valid, dirty, Rd, Wr, tag_out, data_out_m
);

output reg [15:0] data_in_m, data_in;
output reg comp, valid_in, cache_hit, done, enable, wr_m, rd_m, errCtrl, write_c, stall;
output reg [7:0] index;
output reg [2:0] offset, offset_m;
output reg [4:0] tag_in, tag_m;

input wire [15:0] addr, data_out, data_input, data_out_m;
input wire [4:0] tag_out;
input wire hit, valid, dirty, Rd, Wr;

wire miss;
wire [5:0] state;
reg [5:0] next_state;

assign miss = ~hit | (hit & ~valid);

// All the cases
parameter IDLE = 4'h0;
parameter CompareRead  = 4'h1;
parameter CompareWrite = 4'h2;
parameter AccessRead0 = 4'h3;
parameter AccessRead1 = 4'h4;
parameter AccessRead2 = 4'h5;
parameter AccessRead3 = 4'h6;
parameter AccessWrite0 = 4'h7;
parameter AccessWrite1 = 4'h8;
parameter AccessWrite2 = 4'h9;
parameter AccessWrite3 = 4'hA;
parameter Wait0 = 4'hB;
parameter Wait1 = 4'hC;
parameter Wait2 = 4'hD;
parameter Wait3 = 4'hE;
parameter Wait4 = 4'hF;
parameter Wait5 = 5'h10;
parameter Wait6 = 5'h11;
parameter Wait7 = 5'h12;
parameter Wait8 = 5'h13;
parameter DONE = 5'h14;
parameter ERROR = 5'h15;

dff dff0[5:0](.q(state), .d(next_state), .clk(clk), .rst(rst));

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
        cache_hit = 1'b0;

      case(state)
        IDLE: begin
            enable = 1'b1;
            stall = 1'b0;
            next_state = (Rd & Wr) ? ERROR : (Rd & ~Wr) ? CompareRead : (~Rd & Wr) ? CompareWrite : IDLE;
        end
        CompareRead: begin
            enable = 1'b1;
            comp = 1'b1;
            next_state = (hit & valid) ? IDLE : (miss) ? (dirty) ? AccessRead0 : AccessWrite0 : ERROR;
            done = (hit & valid) ? 1'b1 : 1'b0;
            cache_hit = (hit & valid) ? 1'b1 : 1'b0;
        end
        CompareWrite: begin
            enable = 1'b1;
            write_c = 1'b1;
            comp = 1'b1;
            next_state = (hit & valid) ? IDLE : (miss) ? (dirty) ? AccessRead0 : AccessWrite0 : ERROR;
            done = (hit & valid) ? 1'b1 : 1'b0;
            cache_hit = (hit & valid);
        end
        AccessRead0: begin
            enable = 1'b1;
            offset = 3'd0;
            tag_m = (valid) ? tag_out : addr[15:11];
            data_in_m = data_out;
            wr_m = 1'b1;
            offset_m = 3'b00_0;
            next_state = AccessRead1;
        end
        AccessRead1: begin
            enable = 1'b1;
            offset = 3'b01_0;
            tag_m = (valid) ? tag_out : addr[15:11];
            data_in_m = data_out;
            wr_m = 1'b1;
            offset_m = 3'b01_0;
            next_state = AccessRead2;
        end
        AccessRead2: begin
            enable = 1'b1;
            offset = 3'b10_0;
            tag_m = (valid) ? tag_out : addr[15:11];
            data_in_m = data_out;
            wr_m = 1'b1;
            offset_m = 3'b10_0;
            next_state = AccessRead3;
        end
        AccessRead3: begin
            enable = 1'b1;
            offset = 3'b11_0;
            tag_m = (valid) ? tag_out : addr[15:11];
            data_in_m = data_out;
            wr_m = 1'b1;
            offset_m = 3'b11_0;
            next_state = Wait0;
        end
        Wait0: begin
            next_state = Wait1;
        end
        Wait1: begin
            next_state = Wait2;
        end
        Wait2: begin
            next_state = Wait3;
        end
        Wait3: begin
            next_state = Wait4;
        end
        Wait4: begin
            next_state = AccessWrite0;
        end
        AccessWrite0: begin
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
            enable = 1'b1;
            offset = 3'b01_0;
            write_c = 1'b1;
            valid_in = 1'b1;
            data_in = data_out_m;
            next_state = Wait5;
        end
        Wait5: begin
            enable = 1'b1;
            offset = 3'b10_0;
            write_c = 1'b1;
            valid_in = 1'b1;
            data_in = data_out_m;
            next_state = Wait6;
        end
        Wait6: begin
            enable = 1'b1;
            offset = 3'b11_0;
            write_c = 1'b1;
            valid_in = 1'b1;
            data_in = data_out_m;
            next_state = Wr ?  Wait8 : Wait7;
        end
        Wait7: begin
            enable = 1'b1;
            done = 1'b1;
            next_state = IDLE;
        end
        Wait8: begin
            enable = 1'b1;
            write_c = 1'b1;
            comp = 1'b1;
            valid_in = 1'b1;
            next_state = Wait7;
        end
        default: errCtrl = 1'b1;
      endcase
    end



endmodule
