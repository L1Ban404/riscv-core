-I rtl/include
-I third_party/ip/common_cells/include
--top riscv_core
rtl/include/riscv_core_pkg.sv
third_party/ip/common_cells/src/fifo_v3.sv
third_party/ip/common_cells/src/stream_fifo.sv
third_party/ip/common_cells/src/fall_through_register.sv
rtl/core/riscv_core.sv
rtl/core/pipe/if_stage.sv
rtl/core/pipe/id_stage.sv
rtl/core/pipe/ex_stage.sv
rtl/core/pipe/mem_stage.sv
rtl/core/pipe/wb_stage.sv
rtl/core/units/alu.sv
rtl/core/units/decoder.sv
rtl/core/units/imm_gen.sv
rtl/core/units/regfile.sv
