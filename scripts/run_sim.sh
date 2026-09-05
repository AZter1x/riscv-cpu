#!/bin/bash
# scripts/run_sim.sh
vvp sim/tb_top
gtkwave sim/cpu.vcd &