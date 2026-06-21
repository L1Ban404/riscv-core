// Copyright (c) 2026
// SPDX-License-Identifier: Apache-2.0

`include "common_cells/assertions.svh"

// 小深度、全条目可观察的顺序 FIFO。流接口与 common_cells::stream_fifo
// 保持一致，data_all_o/valid_all_o 额外暴露已经存入寄存器阵列的所有条目。
// ready_o 在满且同周期 pop 时仍然成立，允许无气泡 pop/push。
module peek_fifo #(
  parameter bit FallThrough = 1'b0,
  parameter int unsigned Depth = 2,
  parameter type T = logic,
  parameter int unsigned PtrW = (Depth > 1) ? $clog2(Depth) : 1,
  parameter int unsigned CountW = (Depth > 1) ? $clog2(Depth + 1) : 1
) (
  input logic clk_i,
  input logic rst_ni,
  input logic flush_i,
  input logic testmode_i,
  output logic [CountW-1:0] usage_o,

  input T data_i,
  input logic valid_i,
  output logic ready_o,

  output T data_o,
  output logic valid_o,
  input logic ready_i,

  output T data_all_o [Depth],
  output logic [Depth-1:0] valid_all_o
);

  T mem_q [Depth];
  logic [Depth-1:0] slot_valid_q;
  logic [PtrW-1:0] read_ptr_q;
  logic [PtrW-1:0] write_ptr_q;
  logic [CountW-1:0] count_q;

  logic stored_valid;
  logic push;
  logic pop;
  logic bypass_pop;

  function automatic logic [PtrW-1:0] next_ptr(input logic [PtrW-1:0] ptr);
    if (ptr == PtrW'(Depth - 1))
      return '0;
    return ptr + PtrW'(1);
  endfunction

  assign stored_valid = (count_q != '0);
  assign valid_o = stored_valid || (FallThrough && valid_i);
  assign data_o = stored_valid ? mem_q[read_ptr_q] : data_i;

  assign pop = valid_o && ready_i;
  assign ready_o = (count_q < CountW'(Depth)) || (stored_valid && ready_i);
  assign push = valid_i && ready_o;
  assign bypass_pop = FallThrough && !stored_valid && push && pop;

  assign usage_o = count_q;
  assign data_all_o = mem_q;
  assign valid_all_o = slot_valid_q;

  // testmode_i 与寄存器实现的 FIFO 无关，仅用于保持和 stream_fifo 相同的
  // 调用接口。
  logic unused_testmode;
  assign unused_testmode = testmode_i;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      mem_q <= '{default: T'('0)};
      slot_valid_q <= '0;
      read_ptr_q <= '0;
      write_ptr_q <= '0;
      count_q <= '0;
    end else if (flush_i) begin
      slot_valid_q <= '0;
      read_ptr_q <= '0;
      write_ptr_q <= '0;
      count_q <= '0;
    end else begin
      if (pop && stored_valid) begin
        slot_valid_q[read_ptr_q] <= 1'b0;
        read_ptr_q <= next_ptr(read_ptr_q);
      end

      if (push && !bypass_pop) begin
        mem_q[write_ptr_q] <= data_i;
        slot_valid_q[write_ptr_q] <= 1'b1;
        write_ptr_q <= next_ptr(write_ptr_q);
      end

      case ({push && !bypass_pop, pop && stored_valid})
        2'b10: count_q <= count_q + CountW'(1);
        2'b01: count_q <= count_q - CountW'(1);
        default: count_q <= count_q;
      endcase
    end
  end

  // verilog_format: off
  `ASSERT_INIT(PeekFifoDepthValid, Depth > 0, "Depth must be greater than zero.")
  `ASSERT(PeekFifoCountValid, count_q <= CountW'(Depth), clk_i, !rst_ni,
          "FIFO usage must not exceed Depth.")
  `ASSERT(PeekFifoSlotCountValid, $countones(slot_valid_q) == count_q,
          clk_i, !rst_ni, "FIFO slot valid bits must match usage.")
  // verilog_format: on

endmodule
