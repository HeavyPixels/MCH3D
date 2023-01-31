create_clock -name {clk_in} -period 83.3333333333333 [get_ports clk_in]
create_generated_clock -name {clk} -source [get_ports clk_in] -multiply_by 3 [get_nets clk] 