
module video_top
(
    input             I_clk        , //27Mhz
    input             I_rst_n      ,
    output            O_tmds_clk_p ,
    output            O_tmds_clk_n ,
    output     [2:0]  O_tmds_data_p,//{r,g,b}
    output     [2:0]  O_tmds_data_n,
    output     [5:0]  leds,
    input      [1:0]  key
);

//--------------------------
wire        tp0_vs_in  ;
wire        tp0_hs_in  ;
wire        tp0_de_in ;
wire [ 7:0] tp0_data_r/*synthesis syn_keep=1*/;
wire [ 7:0] tp0_data_g/*synthesis syn_keep=1*/;
wire [ 7:0] tp0_data_b/*synthesis syn_keep=1*/;

reg         vs_r;
reg  [9:0]  cnt_vs;
wire test;

`ifdef TANG_NANO_20K
wire key_a = key[0];
wire key_b = key[1];
`else
wire key_a = !key[0];
wire key_b = !key[1];
`endif

//===================================================
// Clock buffer

assign gw_gnd = 1'b0;

wire clkout;      // 371.25
wire clkoutp;     // 27
wire clkoutd;     // 185.625
wire clkoutd3;    // 123.75
wire oscout;      // 125

wire clk27 = clkoutp;
wire led_clk = clkoutp;
wire serial_clk = clkout;
wire heat_clk = oscout;
wire pix_clk;
wire hdmi4_rst_n;
wire pll_lock;

OSC osc_inst
(
  .OSCOUT(oscout)
);

defparam osc_inst.FREQ_DIV = 2;
`ifdef TANG_NANO_20K
  defparam osc_inst.DEVICE = "GW2AR-18C";
`else
  defparam osc_inst.DEVICE = "GW1NR-9C";
`endif

`ifdef TANG_NANO_20K
wire clk27d;

DHCEN dhcen
(
  .CLKIN(I_clk),
  .CLKOUT(clk27d),
  .CE(1'b0)
);
`else
wire clk27d = I_clk;
`endif

rPLL rpll_inst
(
    .CLKIN(clk27d),
    .CLKOUT(clkout),
    .CLKOUTP(clkoutp),
    .CLKOUTD(clkoutd),
    .CLKOUTD3(clkoutd3),
    .LOCK(pll_lock),
    .RESET(gw_gnd),
    .RESET_P(gw_gnd),
    .CLKFB(gw_gnd),
    .FBDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .IDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .ODSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .PSDA({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .DUTYDA({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FDLY({gw_gnd,gw_gnd,gw_gnd,gw_gnd})
);

defparam rpll_inst.FCLKIN = "27";
defparam rpll_inst.DYN_IDIV_SEL = "false";
defparam rpll_inst.IDIV_SEL = 3;
defparam rpll_inst.DYN_FBDIV_SEL = "false";
defparam rpll_inst.FBDIV_SEL = 54;
defparam rpll_inst.DYN_ODIV_SEL = "false";
defparam rpll_inst.ODIV_SEL = 2;
defparam rpll_inst.PSDA_SEL = "0000";
defparam rpll_inst.DYN_DA_EN = "false";
defparam rpll_inst.DUTYDA_SEL = "1000";
defparam rpll_inst.CLKOUT_FT_DIR = 1'b1;
defparam rpll_inst.CLKOUTP_FT_DIR = 1'b1;
defparam rpll_inst.CLKOUT_DLY_STEP = 0;
defparam rpll_inst.CLKOUTP_DLY_STEP = 0;
defparam rpll_inst.CLKFB_SEL = "internal";
defparam rpll_inst.CLKOUT_BYPASS = "false";
defparam rpll_inst.CLKOUTP_BYPASS = "true";
defparam rpll_inst.CLKOUTD_BYPASS = "false";
defparam rpll_inst.DYN_SDIV_SEL = 2;
defparam rpll_inst.CLKOUTD_SRC = "CLKOUT";
defparam rpll_inst.CLKOUTD3_SRC = "CLKOUT";
`ifdef TANG_NANO_20K
  defparam rpll_inst.DEVICE = "GW2AR-18C";
`else
  defparam rpll_inst.DEVICE = "GW1NR-9C";
`endif

CLKDIV u_clkdiv
(
 .RESETN(hdmi4_rst_n),
 .HCLKIN(serial_clk),
 .CLKOUT(pix_clk),    // serial_clk / 5
 .CALIB (1'b1)
);

defparam u_clkdiv.DIV_MODE="5";
defparam u_clkdiv.GSREN="false";

//===================================================
// CPU test
wire [31:0] cpu_a;
wire [17:0] cpu_di;
wire [17:0] cpu_do;
wire cpu_wr;

cpu cpu
(
  .clk  (clk27),
  .res  (!I_rst_n),
  .a    (cpu_a),
  .din  (cpu_di),
  .dout (cpu_do),
  .wr   (cpu_wr)
);

DPX9B dpx9b_inst_0
(
    .CLKA(clk27),
    .RESETA(!I_rst_n),
    .ADA({cpu_a[9:0],4'b0011}),
    .DIA(cpu_do),
    .DOA(cpu_di),
    .WREA(cpu_wr),
    .OCEA(1'b1),
    .CEA(1'b1),
    .BLKSELA(3'b0),

    .CLKB(clk27),
    .RESETB(!I_rst_n),
    .ADB(14'b0),
    .DIB(18'b0),
    .DOB(),
    .WREB(1'b0),
    .OCEB(1'b1),
    .CEB(1'b1),
    .BLKSELB(3'b0)
);

defparam dpx9b_inst_0.READ_MODE0 = 1'b0;
defparam dpx9b_inst_0.READ_MODE1 = 1'b0;
defparam dpx9b_inst_0.WRITE_MODE0 = 2'b00;
defparam dpx9b_inst_0.WRITE_MODE1 = 2'b00;
defparam dpx9b_inst_0.BIT_WIDTH_0 = 18;
defparam dpx9b_inst_0.BIT_WIDTH_1 = 18;
defparam dpx9b_inst_0.BLK_SEL_0 = 3'b000;
defparam dpx9b_inst_0.BLK_SEL_1 = 3'b000;
defparam dpx9b_inst_0.RESET_MODE = "SYNC";

//===================================================
//LED test

assign leds = ~(led_on << led_cnt);

reg [31:0] run_cnt = 32'd0;
reg [2:0] led_cnt = 3'b0;
reg led_ph = 1'b0;
reg led_on;

always @(posedge led_clk)
begin
  led_on <= run_cnt < 32'd1000000;

  if (run_cnt < 32'd1250000)
    run_cnt <= run_cnt + 32'd1;
  else
  begin
    run_cnt <= 32'd0;

    if (!led_ph)
      if (led_cnt == 3'd5)
      begin
        led_cnt <= led_cnt - 3'd1;
        led_ph <= 1'b1;
      end
      else
        led_cnt <= led_cnt + 3'd1;

    else
      if (led_cnt == 3'd0)
      begin
        led_cnt <= led_cnt + 3'd1;
        led_ph <= 1'b0;
      end
      else
        led_cnt <= led_cnt - 3'd1;
  end
end

//===========================================================================
//testpattern

wire [11:0] v_cnt;
wire [11:0] h_cnt;
reg [2:0] mode;

always @(posedge pix_clk)
  if (key_a && key_b)
    mode <= 3'd3;
  else if (key_a)
    mode <= 3'd1;
  else if (key_b)
    mode <= 3'd0;
  else if (v_cnt < 144 + 25)
    mode <= 3'd1;
  else if (v_cnt < 288 + 25)
    mode <= 3'd2;
  else if (v_cnt < 432 + 25)
    mode <= 3'd3;
  else if (v_cnt < 576 + 25)
    mode <= 3'd0;
  else
    mode <= 3'd1;

testpattern testpattern_inst
(
    .I_pxl_clk   (pix_clk            ),//pixel clock
    .I_rst_n     (hdmi4_rst_n        ),//low active
    .I_mode      (mode               ),//data select
    // .I_single_r  ({8{test}}          ),
    // .I_single_g  ({8{test}}          ),
    // .I_single_b  ({8{test}}          ),                  //800x600    //1024x768   //1280x720
    .I_single_r  (8'd0               ),
    .I_single_g  (8'd255             ),
    .I_single_b  (8'd0               ),                  //800x600    //1024x768   //1280x720
    .I_h_total   (12'd1650           ),//hor total time  // 12'd1056  // 12'd1344  // 12'd1650
    .I_h_sync    (12'd40             ),//hor sync time   // 12'd128   // 12'd136   // 12'd40
    .I_h_bporch  (12'd220            ),//hor back porch  // 12'd88    // 12'd160   // 12'd220
    .I_h_res     (12'd1280           ),//hor resolution  // 12'd800   // 12'd1024  // 12'd1280
    .I_v_total   (12'd750            ),//ver total time  // 12'd628   // 12'd806   // 12'd750
    .I_v_sync    (12'd5              ),//ver sync time   // 12'd4     // 12'd6     // 12'd5
    .I_v_bporch  (12'd20             ),//ver back porch  // 12'd23    // 12'd29    // 12'd20
    .I_v_res     (12'd720            ),//ver resolution  // 12'd600   // 12'd768   // 12'd720
    .I_hs_pol    (1'b1               ),//HS polarity , 0:negative polarity，1：positive polarity
    .I_vs_pol    (1'b1               ),//VS polarity , 0:negative polarity，1：positive polarity
    .O_de        (tp0_de_in          ),
    .O_hs        (tp0_hs_in          ),
    .O_vs        (tp0_vs_in          ),
    .O_data_r    (tp0_data_r         ),
    .O_data_g    (tp0_data_g         ),
    .O_data_b    (tp0_data_b         ),
    .H_cnt       (h_cnt              ),
    .V_cnt       (v_cnt              )
);

always@(posedge pix_clk)
  vs_r <= tp0_vs_in;

always @(posedge pix_clk or negedge hdmi4_rst_n)
  if (!hdmi4_rst_n)
    cnt_vs <= 0;
  else if (vs_r && !tp0_vs_in) // vs24 falling edge
    cnt_vs <= cnt_vs + 1'b1;

//==============================================================================
//TMDS TX(HDMI4)

assign hdmi4_rst_n = I_rst_n & pll_lock;

DVI_TX_Top DVI_TX_Top_inst
(
    .I_rst_n       (hdmi4_rst_n   ),  //asynchronous reset, low active
    .I_serial_clk  (serial_clk    ),
    .I_rgb_clk     (pix_clk       ),  //pixel clock
    .I_rgb_vs      (tp0_vs_in     ),
    .I_rgb_hs      (tp0_hs_in     ),
    .I_rgb_de      (tp0_de_in     ),
    .I_rgb_r       (  tp0_data_r ),  //tp0_data_r
    .I_rgb_g       (  tp0_data_g  ),
    .I_rgb_b       (  tp0_data_b  ),
    .O_tmds_clk_p  (O_tmds_clk_p  ),
    .O_tmds_clk_n  (O_tmds_clk_n  ),
    .O_tmds_data_p (O_tmds_data_p ),  //{r,g,b}
    .O_tmds_data_n (O_tmds_data_n )
);

//===================================================
// Heater test

localparam int NUM = 256;
localparam int WID = 32;

reg [WID - 1:0] x[0:NUM - 1];

int i;

initial
  for (i = 0; i < NUM; i++)
    x[i] = i * 100003;

reg sum;
reg [1:0] sum_r;
assign test = sum_r[1];

always @(posedge pix_clk)
  sum_r <= {sum_r[0], sum};

always_comb
begin
  sum = 0;
  
  for (int i = 0; i < NUM; i++)
    for (int j = 0; j < (WID - 1); j++)
      sum = sum ^ x[i][j];
end

always @(posedge heat_clk)
  for (int i = 0; i < NUM; i++)
    x[i] <= (x[i] ^ (x[i] << 13)) ^ ((x[i] ^ (x[i] << 13)) >> 17) ^ (((x[i] ^ (x[i] << 13)) ^ ((x[i] ^ (x[i] << 13)) >> 17)) << 5);

endmodule

`ifdef TANG_NANO_20K
`else
`endif

