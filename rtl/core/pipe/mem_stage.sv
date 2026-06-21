// Copyright (c) 2026
// SPDX-License-Identifier: Apache-2.0

import riscv_core_pkg::*;

/* verilator lint_off UNUSEDSIGNAL */
module mem_stage (
  input logic clk_i,
  input logic rst_ni,

  // EX -> MEM 事务通道。MEM stage 未来会在内部维护顺序 LSU 请求/响应队列，
  // 因此不依赖顶层额外 pipeline_regs 插入寄存器。
  input logic ex_mem_valid_i,
  output logic ex_mem_ready_o,
  input ex_mem_bus_t ex_mem_bus_i,

  // CoreBus 数据接口。每个 load/store 都使用同一条请求流，并按请求接受
  // 顺序获得响应；wstrb=0 表示读，非 0 表示写。
  output core_bus_req_t dmem_req_o,
  input core_bus_resp_t dmem_resp_i,

  // MEM 产生的写回候选，用于 load 数据返回后的前递判断。
  output wb_req_bus_t mem_wb_req_o,

  // MEM -> WB 事务通道。MEM debug 会记录访存请求和响应行为。
  output logic mem_wb_valid_o,
  input logic mem_wb_ready_i,
  output mem_wb_bus_t mem_wb_bus_o
);

  word_t aligned_store_data;
  byte_en_t store_byte_en;

  // Store lane 对齐属于 MEM 数据通路，不进入 EX 的 ALU/前递关键路径。
  // 后续实现 LSU 队列时，请求 FIFO 直接锁存这两个结果。
  always_comb begin
    case (ex_mem_bus_i.mem_req.size)
      MEM_SIZE_BYTE: begin
        aligned_store_data = ex_mem_bus_i.mem_req.wdata <<
                             (ex_mem_bus_i.mem_req.addr[1:0] * ByteW);
        store_byte_en = byte_en_t'(4'b0001 << ex_mem_bus_i.mem_req.addr[1:0]);
      end
      MEM_SIZE_HALF: begin
        aligned_store_data = ex_mem_bus_i.mem_req.wdata <<
                             (ex_mem_bus_i.mem_req.addr[1:0] * ByteW);
        store_byte_en = byte_en_t'(4'b0011 << ex_mem_bus_i.mem_req.addr[1:0]);
      end
      default: begin
        aligned_store_data = ex_mem_bus_i.mem_req.wdata;
        store_byte_en = '1;
      end
    endcase
  end

  // 占位实现：暂不发起真实数据访问，后续在此加入 LSU 状态机/FIFO。
  assign ex_mem_ready_o = mem_wb_ready_i;
  assign dmem_req_o.req.addr = {ex_mem_bus_i.mem_req.addr[XLen-1:2], 2'b00};
  assign dmem_req_o.req.wdata = aligned_store_data;
  assign dmem_req_o.req.wstrb = ex_mem_bus_i.mem_req.write ? store_byte_en : '0;
  assign dmem_req_o.req_valid = 1'b0;
  assign dmem_req_o.rsp_ready = 1'b0;
  assign mem_wb_req_o = '0;
  assign mem_wb_valid_o = 1'b0;
  assign mem_wb_bus_o = '0;

endmodule
/* verilator lint_on UNUSEDSIGNAL */
