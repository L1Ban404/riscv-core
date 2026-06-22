# Copyright (c) 2026
# SPDX-License-Identifier: Apache-2.0

from pathlib import Path
import os
import xml.etree.ElementTree as ET

from cocotb_tools.runner import get_runner


VERILATOR_BUILD_ARGS = [
    "-Wno-IMPORTSTAR",
]


def env_flag(name: str, default: bool = False) -> bool:
    value = os.environ.get(name)
    if value is None:
        return default
    return value.lower() in ("1", "true", "yes", "on")


def test_wb_stage():
    repo_root = Path(__file__).resolve().parents[3]
    build_dir = repo_root / "build/cocotb/wb_stage"
    runner = get_runner("verilator")
    waves = env_flag("WAVES")
    trace_format = os.environ.get("TRACE_FORMAT", "fst").lower()
    if trace_format not in ("fst", "vcd"):
        raise ValueError("TRACE_FORMAT must be 'fst' or 'vcd'")
    if not waves:
        os.environ.pop("WAVES", None)

    build_args = list(VERILATOR_BUILD_ARGS)
    if waves:
        build_args.append("--trace-structs")
    if waves and trace_format == "fst":
        build_args.append("--trace-fst")

    runner.build(
        sources=[
            repo_root / "rtl/include/riscv_core_pkg.sv",
            repo_root / "rtl/core/pipe/wb_stage.sv",
            repo_root / "tests/cocotb/wb_stage/wb_stage_tb.sv",
        ],
        includes=[repo_root / "rtl/include"],
        hdl_toplevel="wb_stage_tb",
        build_dir=build_dir,
        build_args=build_args,
        always=True,
        waves=waves,
    )

    test_args = []
    if waves:
        test_args.extend(["--trace-file", str(build_dir / f"dump.{trace_format}")])

    results_xml = build_dir / "results.xml"
    runner.test(
        hdl_toplevel="wb_stage_tb",
        test_module="test_wb_stage",
        build_dir=build_dir,
        test_dir=repo_root / "tests/cocotb/wb_stage",
        results_xml=results_xml,
        test_args=test_args,
        waves=waves,
    )

    results = ET.parse(results_xml).getroot()
    failures = results.findall(".//failure") + results.findall(".//error")
    if failures:
        raise RuntimeError(f"WB Stage regression reported {len(failures)} failure(s)")


if __name__ == "__main__":
    test_wb_stage()
