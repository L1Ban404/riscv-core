.PHONY: test wave wave-vcd

test:
	python run_mem_stage.py

wave:
	WAVES=1 TRACE_FORMAT=fst python run_mem_stage.py

wave-vcd:
	WAVES=1 TRACE_FORMAT=vcd python run_mem_stage.py
