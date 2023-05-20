#derive_pll_clocks
#derive_clock_uncertainty

#create_clock -name clock50 -period 20.000 [get_ports {clock50}]
create_clock -name audioCk -period  0.250 [get_registers ${topmodule}ep|audio|aCount[0]]
#create_generated_clock -name spiCk -source [get_ports {clock50}] -divide_by 4 [get_registers {substitute_mcu:controller|spi_controller:spi|sck}]

set sdram_clk "${topmodule}pll32|altpll_component|auto_generated|pll1|clk[0]"

set_clock_groups -asynchronous -group [get_clocks ${topmodule}pll32|altpll_component|auto_generated|pll1|clk[0]] -group [get_clocks ${topmodule}pll56|altpll_component|auto_generated|pll1|clk[0]] -group [get_clocks audioCk] -group [get_clocks spiclk]

# set_false_path -from {ear*}
# set_false_path -from {joy*}
# set_false_path -from {ps2*}
# set_false_path -from {sdc*}
# set_false_path -from {dram*}
# set_false_path -from {sram*}

# set_false_path -to   {dsg*}
# set_false_path -to   {i2s*}
# set_false_path -to   {joy*}
# set_false_path -to   {led}
# set_false_path -to   {ps2*}
# set_false_path -to   {rgb*}
# set_false_path -to   {sdc*}
# set_false_path -to   {stm}
# set_false_path -to   {dram*}
# set_false_path -to   {sync*}


set_input_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports $RAM_CLK] -max 6.4 [get_ports  ${RAM_IN}]
set_input_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports $RAM_CLK] -min 3.2 [get_ports  ${RAM_IN}]

set_output_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports $RAM_CLK] -max 1.5 [get_ports ${RAM_OUT}]
set_output_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports $RAM_CLK] -min -0.8 [get_ports ${RAM_OUT}]

set_false_path -to [get_ports ${FALSE_OUT}]
set_false_path -from [get_ports ${FALSE_IN}]

set_multicycle_path -to ${VGA_OUT} -setup 3
set_multicycle_path -to ${VGA_OUT} -hold 2

