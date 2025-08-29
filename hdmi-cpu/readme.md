# HDMI Test

The test outputs 1280x720 60Hz HDMI test pattern.

- Use Tang Nano 20k (GW2AR-18) or 9k (GW1NR-9) board.
- Download GOWIN FPGA Dedigner (Education build is ok).
- Open appropriate *.gprj file.
- In **Project -> Configuration -> Synthesize -> Verilog Language** set **System Verilog 2017**.
- Run synthesis (two green circular arrows icon at rightmost in the toolbar).
- Connect your board to USB.
- Upload bitstream: **Tools -> Programmer**, **SRAM Program** (default).
- Connect HDMI display to the board.