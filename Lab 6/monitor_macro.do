force -freeze sim:/monitor/reset 1'h1 0
force -freeze sim:/monitor/c_switches 6'b011101 0
force -freeze sim:/monitor/sys_clk 1 0, 0 {10 ns} -r 20

run 50

force -freeze sim:/monitor/reset 1'h0 0

run 15750