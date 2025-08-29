//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.03 Education 
//Created Time: 2025-08-14 19:17:54
// create_clock -name input_27mhz_pin4 -period 37.037 -waveform {0 18.518} [get_ports {I_clk}]
create_clock -name pixel_clock -period 13.468 -waveform {0 6.734} [get_nets {pix_clk}]
