# Copyright (c) 2026
# SPDX-License-Identifier: Apache-2.0

.PHONY: test test-faults wave wave-vcd

test:
	python run_riscv_core.py

test-faults:
	python run_fault_injection.py

wave:
	WAVES=1 TRACE_FORMAT=fst python run_riscv_core.py

wave-vcd:
	WAVES=1 TRACE_FORMAT=vcd python run_riscv_core.py
