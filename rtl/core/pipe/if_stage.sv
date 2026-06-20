// Copyright (c) 2026
// SPDX-License-Identifier: Apache-2.0

import riscv_core_pkg::*;

`include "common_cells/registers.svh"
`include "common_cells/assertions.svh"

module if_stage #(
  // 取指前端允许同时挂起的 AXI4-Lite 读请求数。这个深度主要吸收外部
  // 指令存储器延迟，越大越能保持请求端不断流。
  parameter int unsigned FetchOutstandingDepth = 4,
  // IF -> ID 已返回指令队列深度。这个深度主要吸收 ID stage 的短暂停顿，
  // 不需要和 outstanding 请求深度相同。
  parameter int unsigned IfIdQueueDepth = 2
) (
  input logic clk_i,
  input logic rst_ni,

  // boot_pc_i 是 IF stage 内部 PC 队列的初始值。真实 PC 寄存器墙会放在
  // IF stage 内部，而不是由 riscv_core 顶层额外插入 pipeline_regs。
  input pc_t boot_pc_i,

  // redirect_i 只来自 EX stage。它表示“前端改道”，用于丢弃尚未进入 EX
  // 的年轻事务；它不负责冲刷 EX/MEM/WB 中已经有效的指令。
  input redirect_bus_t redirect_i,

  // AXI4-Lite 取指接口。IF 只使用 AR/R 通道，但边界暴露完整总线；
  // 写通道保持空闲，读请求和读响应通过内部 FIFO 解耦。
  output axi_lite_req_t imem_req_o,
  input axi_lite_resp_t imem_resp_i,

  // IF -> ID 事务通道。if_id 的寄存器墙/FIFO 属于 IF stage 内部。
  output logic if_id_valid_o,
  input logic if_id_ready_i,
  output if_id_bus_t if_id_bus_o
);

  typedef struct packed {
    pc_t pc;
    logic epoch;
  } fetch_req_t;

  // pc_q 是下一次准备发出的取指 PC。boot_pc_i 在复位释放后的第一个周期
  // 被采样，后续 PC 只由顺序取指或 redirect 更新。
  pc_t pc_q;
  pc_t pc_d;
  logic boot_pending_q;
  logic boot_pending_d;
  logic fetch_epoch_q;
  logic fetch_epoch_d;

  // AR holding register 使用 common_cells::fall_through_register。redirect 只
  // 阻止新请求进入 holding register，已经 valid 的 AXI AR 请求必须保持到
  // ar_ready，满足 AXI4-Lite valid 不能撤销的约束。
  fetch_req_t fetch_req_data;
  fetch_req_t ar_hold_data;
  logic ar_hold_ready;
  logic ar_hold_valid;
  logic fetch_req_valid;
  logic fetch_req_fire;

  // PC FIFO 由 common_cells::stream_fifo 实现，记录已经完成 AR 握手、
  // 但尚未收到 R 响应的请求 PC 及其 epoch。它使用 fall-through 模式，
  // 支持无延迟存储器在 AR 握手同周期给出对应 R 响应。redirect 翻转 epoch。
  // 这里使用 1 bit epoch 的前提是：IF 只使用单条 AXI4-Lite 读流，响应
  // 必须严格按 AR 握手顺序返回；redirect 只来自 EX，下一次 redirect 必须
  // 等新路径指令返回并进入 EX 后才可能发生。因此在 epoch 再次翻转前，
  // 更老 epoch 的响应已经按顺序被消费掉，不会和当前路径混淆。
  fetch_req_t pc_fifo_data;
  logic pc_fifo_ready;
  logic pc_fifo_valid;

  // fetch FIFO 同样使用 stream_fifo，保存已经配对完成的 {pc, instr}。
  // 它直接驱动 IF -> ID valid/ready 通道，ID stage 只消费完整 fetch 事务。
  if_id_bus_t fetch_fifo_data;
  logic fetch_fifo_ready;
  logic fetch_fifo_valid;
  logic fetch_fifo_ready_i;

  logic imem_ar_fire;
  logic imem_r_fire;
  logic fetch_fifo_push;
  logic returned_fetch_kept;

  // IF 不产生写事务，但顶层暴露完整 AXI4-Lite master 总线，因此写相关
  // 通道明确保持空闲。prot[2]=1 表示 instruction access。
  assign imem_req_o.aw.addr = '0;
  assign imem_req_o.aw.prot = 3'b100;
  assign imem_req_o.aw_valid = 1'b0;
  assign imem_req_o.w.data = '0;
  assign imem_req_o.w.strb = '0;
  assign imem_req_o.w_valid = 1'b0;
  assign imem_req_o.b_ready = 1'b0;

  // 请求生成端只决定是否把一个新 PC 分配给 AR holding register。
  // redirect 不能直接拉低 imem_req_o.ar_valid，否则会破坏 AXI valid 保持。
  assign fetch_req_valid = !boot_pending_q && !redirect_i.valid && pc_fifo_ready;
  assign fetch_req_data = '{pc: pc_q, epoch: fetch_epoch_q};
  assign fetch_req_fire = fetch_req_valid && ar_hold_ready;

  assign imem_req_o.ar.addr = ar_hold_data.pc;
  assign imem_req_o.ar.prot = 3'b100;
  assign imem_req_o.ar_valid = ar_hold_valid;
  assign imem_ar_fire = imem_req_o.ar_valid && imem_resp_i.ar_ready;

  // 返回端按 AXI4-Lite 顺序从 PC FIFO 头部取对应 PC。如果该请求 epoch
  // 与当前 epoch 不同，说明它属于 redirect 前的旧路径，只弹出不写入。
  assign returned_fetch_kept = (pc_fifo_data.epoch == fetch_epoch_q) && !redirect_i.valid;
  assign imem_req_o.r_ready = pc_fifo_valid && (!returned_fetch_kept || fetch_fifo_ready);
  assign imem_r_fire = imem_resp_i.r_valid && imem_req_o.r_ready;
  assign fetch_fifo_push = imem_r_fire && returned_fetch_kept;

  assign fetch_fifo_data.fetch.pc = pc_fifo_data.pc;
  assign fetch_fifo_data.fetch.instr = instr_t'(imem_resp_i.r.data);
  assign fetch_fifo_data.debug.fetch.pc = pc_fifo_data.pc;
  assign fetch_fifo_data.debug.fetch.instr = instr_t'(imem_resp_i.r.data);

  // fetch FIFO 在 redirect 周期同步清空；组合输出也用 redirect_i.valid 屏蔽，
  // 避免同周期把旧路径指令继续交给 ID。
  assign if_id_valid_o = !redirect_i.valid && fetch_fifo_valid;
  assign fetch_fifo_ready_i = !redirect_i.valid && if_id_ready_i;

  fall_through_register #(
    .T(fetch_req_t)
  ) u_ar_hold (
    .clk_i,
    .rst_ni,
    .clr_i(1'b0),
    .testmode_i(1'b0),
    .valid_i(fetch_req_valid),
    .ready_o(ar_hold_ready),
    .data_i(fetch_req_data),
    .valid_o(ar_hold_valid),
    .ready_i(imem_resp_i.ar_ready),
    .data_o(ar_hold_data)
  );

  stream_fifo #(
    .FALL_THROUGH(1'b1),
    .DEPTH(FetchOutstandingDepth),
    .T(fetch_req_t)
  ) u_pc_fifo (
    .clk_i,
    .rst_ni,
    .flush_i(1'b0),
    .testmode_i(1'b0),
    .usage_o(  /* unused */),
    .data_i(ar_hold_data),
    .valid_i(imem_ar_fire),
    .ready_o(pc_fifo_ready),
    .data_o(pc_fifo_data),
    .valid_o(pc_fifo_valid),
    .ready_i(imem_r_fire)
  );

  stream_fifo #(
    .FALL_THROUGH(1'b0),
    .DEPTH(IfIdQueueDepth),
    .T(if_id_bus_t)
  ) u_fetch_fifo (
    .clk_i,
    .rst_ni,
    .flush_i(redirect_i.valid),
    .testmode_i(1'b0),
    .usage_o(  /* unused */),
    .data_i(fetch_fifo_data),
    .valid_i(fetch_fifo_push),
    .ready_o(fetch_fifo_ready),
    .data_o(if_id_bus_o),
    .valid_o(fetch_fifo_valid),
    .ready_i(fetch_fifo_ready_i)
  );

  always_comb begin
    // redirect 优先于顺序取指。fetch FIFO 由 flush_i 清空；已经发出的
    // AXI 读请求留在 PC FIFO 中，后续返回时通过 epoch 判断并丢弃旧路径。
    if (redirect_i.valid) begin
      pc_d = redirect_i.target_pc;
    end else if (boot_pending_q) begin
      pc_d = boot_pc_i;
    end else if (fetch_req_fire) begin
      pc_d = pc_q + pc_t'(32'd4);
    end else begin
      pc_d = pc_q;
    end
  end

  // boot_pending_q 只用于复位释放后的第一个正常周期同步采样 boot_pc_i。
  // reset 后它为 1，下一拍无条件清 0。
  assign boot_pending_d = 1'b0;
  assign fetch_epoch_d = redirect_i.valid ? ~fetch_epoch_q : fetch_epoch_q;

  `FF(pc_q, pc_d, '0)
  `FF(boot_pending_q, boot_pending_d, 1'b1)
  `FF(fetch_epoch_q, fetch_epoch_d, 1'b0)

  // verilog_format: off
  `ASSERT_STABLE(
    ImemArStable,
    imem_req_o.ar_valid,
    imem_resp_i.ar_ready,
    imem_req_o.ar,
    '0,
    clk_i,
    !rst_ni,
    "AXI4-Lite AR payload must remain stable while valid is waiting for ready."
  )

  `ASSERT(
    ImemArValidStable,
    imem_req_o.ar_valid && !imem_resp_i.ar_ready |=> imem_req_o.ar_valid,
    clk_i,
    !rst_ni,
    "AXI4-Lite AR valid must remain asserted until ready."
  )
  // verilog_format: on

endmodule
