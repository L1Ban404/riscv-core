// Copyright (c) 2026
// SPDX-License-Identifier: Apache-2.0

`ifndef PIPELINE_BUS_TYPES_SVH
`define PIPELINE_BUS_TYPES_SVH

`include "debug_bus_types.svh"

// Redirect 只冲刷尚未进入 EX 的年轻事务；已经进入 EX 及后续阶段的
// 事务继续退休。
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

// 阶段边界处随指令移动的 payload。寄存器墙/FIFO 由各 stage 内部维护。
typedef struct packed {
  fetch_bus_t fetch;
  if_debug_bus_t debug;
} if_id_bus_t;

typedef struct packed {
  fetch_bus_t fetch;
  reg_addr_bus_t reg_addr;
  exec_data_bus_t exec_data;
  decode_ctrl_bus_t ctrl;
  id_debug_bus_t debug;
} id_ex_bus_t;

typedef struct packed {
  mem_req_bus_t mem_req;
  wb_req_bus_t wb_req;
  ex_debug_bus_t debug;
} ex_mem_bus_t;

typedef struct packed {
  wb_req_bus_t wb_req;
  mem_debug_bus_t debug;
} mem_wb_bus_t;

// Forwarding unit 读取较老指令的写回请求；匹配但数据尚未有效时阻塞 EX。
typedef enum logic [1:0] {
  FWD_NONE,
  FWD_FROM_EX,
  FWD_FROM_MEM,
  FWD_FROM_WB
} forward_sel_e;

typedef struct packed {
  forward_sel_e rs1_sel;
  forward_sel_e rs2_sel;
  logic stall;
} forward_ctrl_bus_t;

typedef struct packed {
  wb_req_bus_t ex_wb;
  wb_req_bus_t mem_wb;
  wb_req_bus_t wb_wb;
} forward_src_bus_t;

`endif
