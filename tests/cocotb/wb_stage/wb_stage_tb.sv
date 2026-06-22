// Copyright (c) 2026
// SPDX-License-Identifier: Apache-2.0

import riscv_core_pkg::*;

module wb_stage_tb (
  input logic mem_wb_valid_i,
  output logic mem_wb_ready_o,

  input logic wb_valid_i,
  input logic wb_data_valid_i,
  input logic [4:0] wb_rd_addr_i,
  input logic [31:0] wb_wdata_i,

  input logic [31:0] fetch_pc_i,
  input logic [31:0] fetch_instr_i,
  input logic [4:0] rs1_addr_i,
  input logic [4:0] rs2_addr_i,
  input logic [4:0] rd_addr_i,
  input logic [$bits(decode_ctrl_bus_t)-1:0] ctrl_i,
  input logic redirect_valid_i,
  input logic [31:0] redirect_target_pc_i,
  input logic [2:0] redirect_reason_i,
  input logic [31:0] alu_result_i,
  input logic mem_req_valid_i,
  input logic mem_req_write_i,
  input logic [1:0] mem_req_size_i,
  input logic mem_req_sign_ext_i,
  input logic [31:0] mem_req_addr_i,
  input logic [31:0] mem_req_wdata_i,
  input logic mem_rsp_valid_i,
  input logic mem_rsp_error_i,
  input logic [31:0] mem_rsp_rdata_i,

  output logic wb_valid_o,
  output logic wb_data_valid_o,
  output logic [4:0] wb_rd_addr_o,
  output logic [31:0] wb_wdata_o,

  output logic retire_valid_o,
  output logic [31:0] retire_pc_o,
  output logic [31:0] retire_instr_o,
  output logic [4:0] retire_rs1_addr_o,
  output logic [4:0] retire_rs2_addr_o,
  output logic [4:0] retire_rd_addr_o,
  output logic [$bits(decode_ctrl_bus_t)-1:0] retire_ctrl_o,
  output logic retire_redirect_valid_o,
  output logic [31:0] retire_redirect_target_pc_o,
  output logic [2:0] retire_redirect_reason_o,
  output logic [31:0] retire_alu_result_o,
  output logic retire_mem_req_valid_o,
  output logic retire_mem_req_write_o,
  output logic [1:0] retire_mem_req_size_o,
  output logic retire_mem_req_sign_ext_o,
  output logic [31:0] retire_mem_req_addr_o,
  output logic [31:0] retire_mem_req_wdata_o,
  output logic retire_mem_rsp_valid_o,
  output logic retire_mem_rsp_error_o,
  output logic [31:0] retire_mem_rsp_rdata_o,
  output logic retire_wb_valid_o,
  output logic retire_wb_data_valid_o,
  output logic [4:0] retire_wb_rd_addr_o,
  output logic [31:0] retire_wb_wdata_o
);

  mem_wb_bus_t mem_wb_bus;
  wb_req_bus_t wb_req;
  core_debug_bus_t core_debug;

  always_comb begin
    mem_wb_bus = '0;
    mem_wb_bus.wb_req.valid = wb_valid_i;
    mem_wb_bus.wb_req.data_valid = wb_data_valid_i;
    mem_wb_bus.wb_req.rd_addr = wb_rd_addr_i;
    mem_wb_bus.wb_req.wdata = wb_wdata_i;

    mem_wb_bus.debug.ex_debug.id_debug.if_debug.fetch.pc = fetch_pc_i;
    mem_wb_bus.debug.ex_debug.id_debug.if_debug.fetch.instr = fetch_instr_i;
    mem_wb_bus.debug.ex_debug.id_debug.reg_addr.rs1_addr = rs1_addr_i;
    mem_wb_bus.debug.ex_debug.id_debug.reg_addr.rs2_addr = rs2_addr_i;
    mem_wb_bus.debug.ex_debug.id_debug.reg_addr.rd_addr = rd_addr_i;
    mem_wb_bus.debug.ex_debug.id_debug.ctrl = decode_ctrl_bus_t'(ctrl_i);
    mem_wb_bus.debug.ex_debug.redirect.valid = redirect_valid_i;
    mem_wb_bus.debug.ex_debug.redirect.target_pc = redirect_target_pc_i;
    mem_wb_bus.debug.ex_debug.redirect.reason = redirect_reason_e'(redirect_reason_i);
    mem_wb_bus.debug.ex_debug.alu_result = alu_result_i;
    mem_wb_bus.debug.mem_req.valid = mem_req_valid_i;
    mem_wb_bus.debug.mem_req.write = mem_req_write_i;
    mem_wb_bus.debug.mem_req.size = mem_size_e'(mem_req_size_i);
    mem_wb_bus.debug.mem_req.sign_ext = mem_req_sign_ext_i;
    mem_wb_bus.debug.mem_req.addr = mem_req_addr_i;
    mem_wb_bus.debug.mem_req.wdata = mem_req_wdata_i;
    mem_wb_bus.debug.mem_rsp.valid = mem_rsp_valid_i;
    mem_wb_bus.debug.mem_rsp.error = mem_rsp_error_i;
    mem_wb_bus.debug.mem_rsp.rdata = mem_rsp_rdata_i;
  end

  assign wb_valid_o = wb_req.valid;
  assign wb_data_valid_o = wb_req.data_valid;
  assign wb_rd_addr_o = wb_req.rd_addr;
  assign wb_wdata_o = wb_req.wdata;

  assign retire_valid_o = core_debug.valid;
  assign retire_pc_o = core_debug.fetch.pc;
  assign retire_instr_o = core_debug.fetch.instr;
  assign retire_rs1_addr_o = core_debug.reg_addr.rs1_addr;
  assign retire_rs2_addr_o = core_debug.reg_addr.rs2_addr;
  assign retire_rd_addr_o = core_debug.reg_addr.rd_addr;
  assign retire_ctrl_o = core_debug.ctrl;
  assign retire_redirect_valid_o = core_debug.redirect.valid;
  assign retire_redirect_target_pc_o = core_debug.redirect.target_pc;
  assign retire_redirect_reason_o = core_debug.redirect.reason;
  assign retire_alu_result_o = core_debug.alu_result;
  assign retire_mem_req_valid_o = core_debug.mem_req.valid;
  assign retire_mem_req_write_o = core_debug.mem_req.write;
  assign retire_mem_req_size_o = core_debug.mem_req.size;
  assign retire_mem_req_sign_ext_o = core_debug.mem_req.sign_ext;
  assign retire_mem_req_addr_o = core_debug.mem_req.addr;
  assign retire_mem_req_wdata_o = core_debug.mem_req.wdata;
  assign retire_mem_rsp_valid_o = core_debug.mem_rsp.valid;
  assign retire_mem_rsp_error_o = core_debug.mem_rsp.error;
  assign retire_mem_rsp_rdata_o = core_debug.mem_rsp.rdata;
  assign retire_wb_valid_o = core_debug.wb_req.valid;
  assign retire_wb_data_valid_o = core_debug.wb_req.data_valid;
  assign retire_wb_rd_addr_o = core_debug.wb_req.rd_addr;
  assign retire_wb_wdata_o = core_debug.wb_req.wdata;

  wb_stage u_dut (
    .mem_wb_valid_i,
    .mem_wb_ready_o,
    .mem_wb_bus_i(mem_wb_bus),
    .wb_req_o(wb_req),
    .core_debug_o(core_debug)
  );

endmodule
