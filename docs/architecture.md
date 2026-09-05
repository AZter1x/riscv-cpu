# CPU Architecture

## Pipeline Stages

### IF — Instruction Fetch
Maintains the Program Counter. Fetches the instruction at the current PC
from instruction memory every cycle. Handles stall (freeze PC) and
branch/JALR (redirect PC).

### ID — Instruction Decode
Decodes the instruction into control signals. Reads two source registers
from the register file. Generates the sign-extended immediate via imm_gen.
Receives writeback data and writes to the register file.

### EX — Execute
Computes the ALU result. Resolves RAW hazards via 3-way forwarding muxes.
Computes branch target (PC + imm) and evaluates branch condition.
Computes JALR target (rs1 + imm). Handles AUIPC (PC + imm as ALU input A).

### MEM — Memory Access
Reads from or writes to data memory. Load instructions read here.
Store instructions write here. Non-memory instructions pass through.

### WB — Writeback
Selects between ALU result and memory read data. Writes the result
back to the register file.

## Hazard Handling

### Data Hazards (RAW)
Resolved by the forwarding unit. Compares destination registers in
EX/MEM and MEM/WB against source registers in EX. Forwards results
directly to ALU inputs, bypassing the register file.

### Load-Use Hazards
Cannot be resolved by forwarding alone. The hazard unit detects this
and stalls the pipeline for one cycle by freezing the PC and IF/ID
register and inserting a bubble into ID/EX.

### Control Hazards (Branches)
Branch decision is made in EX. If the branch is taken, the IF/ID
register is flushed (NOP inserted).

## Memory Model
Harvard architecture — separate instruction memory (imem) and data
memory (dmem). Avoids structural hazards between instruction fetch
and data memory access.