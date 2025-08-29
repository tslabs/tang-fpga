
module cpu
(
  input wire clk,
  input wire res,

  output wire [31:0] a,
  input wire [17:0] din,
  output wire [17:0] dout,
  output wire wr
);

  // instr class
  localparam I_LL = 2'b00;
  localparam I_LH = 2'b01;
  localparam I_RI = 2'b10;
  localparam I_RR = 2'b11;

  // instr op
  localparam OP_LD    = 4'd0;
  localparam OP_ADD   = 4'd1;
  localparam OP_SUB   = 4'd2;
  localparam OP_AND   = 4'd3;
  localparam OP_OR    = 4'd4;
  localparam OP_XOR   = 4'd5;
  localparam OP_TST   = 4'd6;
  localparam OP_CP    = 4'd7;
  localparam OP_MUL   = 4'd8;
  localparam OP_DIV   = 4'd9;
  localparam OP_RD    = 4'd10;
  localparam OP_WR    = 4'd11;
  localparam OP_SH    = 4'd12;
  localparam OP_13    = 4'd13;
  localparam OP_14    = 4'd14;
  localparam OP_MISC  = 4'd15;

  // shift op
  localparam SH_RL  = 3'd0;
  localparam SH_RLC = 3'd1;
  localparam SH_SL0 = 3'd2;
  localparam SH_SL1 = 3'd3;
  localparam SH_RR  = 3'd4;
  localparam SH_RRC = 3'd5;
  localparam SH_SRU = 3'd6;
  localparam SH_SRS = 3'd7;

  // misc instr
  localparam IM_SKIP = 8'b11111110;
  localparam IM_RSEL = 8'b11111111;

  // register aliases
 `define pc   r[15]
 `define r    r[i[11:8]]
 `define rd   r[i[11:8]]
 `define rs   r[i[7:4]]
 `define ra   r[i[3:0]]
 `define cls  i[17:16]
 `define op   i[15:12]
 `define sh   i[7:5]
 `define imm8 i[7:0]
 `define imm5 i[4:0]

  reg [31:0] r[0:15];   // register file
  reg c, z;
  reg [3:0] r_pfx;      // register load prefix

  wire [17:0] i = din;

  reg di_valid = 1'b0;
  wire [17:0] d = 18'b0;

  assign a = `pc;
  assign dout = d;
  assign wr = 1'b0;

  always @(posedge clk)
  begin
    if (res)
    begin
      `pc <= 0;
      r_pfx <= 0;
      di_valid = 0;
    end

    else
    begin
      di_valid <= 1'b1;
      `pc <= `pc + 32'b1;

      if (di_valid)
        case (`cls)
          I_LL:
          begin
            r[r_pfx][15:0] <= i[15:0];  // load lower half of a register
            r[r_pfx][31:16] <= 0;       // null higer half
          end

          I_LH:
            r[r_pfx][31:16] <= i[15:0]; // load higer half of a register

          I_RI:
          begin
            r_pfx <= 0;   // reset reg prefix

            case (`op)
              OP_LD   : `r <= `imm8;
              OP_ADD  : `r <= `r + `imm8;
              OP_SUB  : `r <= `r - `imm8;
              OP_AND  : `r <= `r & `imm8;
              OP_OR   : `r <= `r | `imm8;
              OP_XOR  : `r <= `r ^ `imm8;
              OP_TST  : z <= ~|{`r[7:0] & `imm8};

              OP_SH:
                case (`sh)
                  SH_RL : begin `r <= {`r[30:0], c}; c <= `r[31]; end
                  SH_RLC: begin `r <= {`r[30:0], `r[31]}; c <= `r[31]; end
                  SH_SL0: begin `r <= {`r[30:0], 1'b0}; c <= `r[31]; end
                  SH_SL1: begin `r <= {`r[30:0], 1'b1}; c <= `r[31]; end
                  SH_RR : begin `r <= {c, `r[31:1]}; c <= `r[0]; end
                  SH_RRC: begin `r <= {`r[0], `r[31:1]}; c <= `r[0]; end
                  SH_SRU: begin `r <= {1'b0, `r[31:1]}; c <= `r[0]; end
                  SH_SRS: begin `r <= {`r[31], `r[31:1]}; c <= `r[0]; end
                endcase // case (`sh)
            endcase // case (`op)
          end

          I_RR:
          begin
            r_pfx <= 0;   // reset reg prefix

            case (`op)
              OP_LD   : `rd <= `rs;
              OP_ADD  : `rd <= `rs + `ra;
              OP_SUB  : `rd <= `rs - `ra;
              OP_AND  : `rd <= `rs & `ra;
              OP_OR   : `rd <= `rs | `ra;
              OP_XOR  : `rd <= `rs ^ `ra;
              OP_TST  : z <= ~|{`rs & `ra};

              OP_SH:
                case (`sh)
                  SH_RL : begin `rd <= {`rs[30:0], c}; c <= `rs[31]; end
                  SH_RLC: begin `rd <= {`rs[30:0], `rs[31]}; c <= `rs[31]; end
                  SH_SL0: begin `rd <= {`rs[30:0], 1'b0}; c <= `rs[31]; end
                  SH_SL1: begin `rd <= {`rs[30:0], 1'b1}; c <= `rs[31]; end
                  SH_RR : begin `rd <= {c, `rs[31:1]}; c <= `rs[0]; end
                  SH_RRC: begin `rd <= {`rs[0], `rs[31:1]}; c <= `rs[0]; end
                  SH_SRU: begin `rd <= {1'b0, `rs[31:1]}; c <= `rs[0]; end
                  SH_SRS: begin `rd <= {`rs[31], `rs[31:1]}; c <= `rs[0]; end
                endcase  // case (`sh)

              OP_MISC:
                case (i[11:4])
                  IM_RSEL:
                    r_pfx <= i[3:0];  // set LL, LH prefix

                  IM_SKIP:
                    ;
                endcase // case (i[11:4])
            endcase  // case (`op)
          end
        endcase  // case (`cls)
    end
  end

endmodule