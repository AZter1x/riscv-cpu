#!/bin/bash
# scripts/compile.sh
mkdir -p sim
iverilog -o sim/tb_top \
  rtl/alu/alu.v \
  rtl/core/alu_control.v \
  rtl/mem/imem.v \
  rtl/mem/dmem.v \
  rtl/core/fetch.v \
  rtl/core/decode.v \
  rtl/core/execute.v \
  rtl/core/memory.v \
  rtl/core/writeback.v \
  rtl/core/pipeline_regs.v \
  rtl/core/hazard_unit.v \
  rtl/core/forwarding_unit.v \
  rtl/core/top.v \
  tb/tb_top.v

echo "Compile done. Run: vvp sim/tb_top"