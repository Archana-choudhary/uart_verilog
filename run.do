# QuestaSim / ModelSim script. Run with:  do run.do
quit -sim
if {[file exists work]} { vdel -lib work -all }
vlib work
vlog uart_tx.v uart_rx.v uart_hello.v tb_hello.v
vsim -voptargs=+acc work.tb_hello

# Names for the state values
radix define sender_states {
    2'b00 "LOAD",
    2'b01 "WAIT_BUSY",
    2'b10 "WAIT_DONE",
    2'b11 "PAUSE",
    -default hex
}
radix define tx_states {
    2'b00 "IDLE",
    2'b01 "START",
    2'b10 "DATA",
    2'b11 "STOP",
    -default hex
}

# Waveforms
add wave -divider {Clock / Reset}
add wave sim:/tb_hello/clk
add wave sim:/tb_hello/rst

add wave -divider {Serial line}
add wave sim:/tb_hello/line

add wave -divider {Receiver}
add wave -radix ascii sim:/tb_hello/rx_data
add wave sim:/tb_hello/valid

add wave -divider {Message sender}
add wave -radix sender_states sim:/tb_hello/DUT/state
add wave -radix unsigned      sim:/tb_hello/DUT/idx

add wave -divider {Transmitter}
add wave -radix tx_states     sim:/tb_hello/DUT/TX/state
add wave sim:/tb_hello/DUT/TX/busy

run -all
wave zoom full

