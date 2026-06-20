// Copyright (c) 2026
// SPDX-License-Identifier: Apache-2.0

`ifndef RISCV_CORE_CONFIG_SVH
`define RISCV_CORE_CONFIG_SVH

// 当前核心以 RV32I 作为第一阶段目标，因此 XLen/ILen 先固定为 32。
// 后续如果扩展到 RV64，可以优先从这些参数和基础类型开始收敛修改面。
parameter int unsigned XLen = 32;
parameter int unsigned ILen = 32;
parameter int unsigned RegAddrW = 5;
parameter int unsigned ByteW = 8;
parameter int unsigned StrbW = XLen / ByteW;

localparam logic [RegAddrW-1:0] ZeroReg = '0;

typedef logic [XLen-1:0] word_t;
typedef logic [ILen-1:0] instr_t;
typedef logic [XLen-1:0] pc_t;
typedef logic [RegAddrW-1:0] reg_addr_t;
typedef logic [StrbW-1:0] byte_en_t;

`endif
