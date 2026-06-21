// Copyright (c) 2026
// SPDX-License-Identifier: Apache-2.0

`ifndef TRANSACTION_BUS_TYPES_SVH
`define TRANSACTION_BUS_TYPES_SVH

`include "riscv_core_config.svh"
`include "riscv_isa_config.svh"

// 可复用于阶段边界的事务级子总线。valid/ready 一般属于模块或 FIFO
// 控制；只有“请求是否存在”本身有语义的 payload 才内含 valid。
typedef struct packed {
  pc_t pc;
  instr_t instr;
} fetch_bus_t;

typedef struct packed {
  reg_addr_t rs1_addr;
  reg_addr_t rs2_addr;
  reg_addr_t rd_addr;
} reg_addr_bus_t;

typedef struct packed {
  pc_t pc;
  word_t rs1_value;
  word_t rs2_value;
  word_t imm;
} exec_data_bus_t;

typedef struct packed {
  alu_op_e alu_op;
  op_a_sel_e op_a_sel;
  op_b_sel_e op_b_sel;
  branch_op_e branch_op;
  mem_cmd_e mem_cmd;
  mem_size_e mem_size;
  logic mem_sign_ext;
  wb_sel_e wb_sel;
  logic rd_write;
  logic illegal_instr;
} decode_ctrl_bus_t;

typedef struct packed {
  logic valid;
  logic write;
  mem_size_e size;
  logic sign_ext;
  word_t addr;
  // store 的原始 rs2 数据；MEM 根据 addr[1:0] 和 size 生成 CoreBus lane
  // 对齐后的 wdata/wstrb，避免把移位逻辑放在 EX 关键路径上。
  word_t wdata;
} mem_req_bus_t;

typedef struct packed {
  logic valid;
  logic error;
  word_t rdata;
} mem_rsp_bus_t;

typedef struct packed {
  // valid 表示该事务会写 rd；data_valid 表示本周期 wdata 已可用于前递。
  logic valid;
  logic data_valid;
  reg_addr_t rd_addr;
  word_t wdata;
} wb_req_bus_t;

// Redirect 只冲刷尚未进入 EX 的年轻事务；已经进入 EX 及后续阶段的
// 事务继续退休。该事务同时随 debug 总线记录分支执行结果。
typedef enum logic [2:0] {
  REDIR_NONE,
  REDIR_BRANCH,
  REDIR_JAL,
  REDIR_JALR,
  REDIR_TRAP,
  REDIR_MRET
} redirect_reason_e;

typedef struct packed {
  logic valid;
  pc_t target_pc;
  redirect_reason_e reason;
} redirect_bus_t;

`endif
