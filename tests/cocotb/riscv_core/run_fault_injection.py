# Copyright (c) 2026
# SPDX-License-Identifier: Apache-2.0

"""Prove every RTL fault-injection mode independently trips CPU verification."""

from pathlib import Path
import os
import subprocess
import sys


FAULTS = (
    "INJECT_ALU_ADD_AS_SUB",
    "INJECT_LOAD_BYTE_SIGN_EXTEND",
    "INJECT_STORE_BYTE_LANE_ZERO",
    "INJECT_BNE_AS_BEQ",
    "INJECT_JUMP_LINK_PC",
)


def main() -> None:
    test_dir = Path(__file__).resolve().parent
    failures = []
    for fault in FAULTS:
        environment = os.environ.copy()
        environment["FAULT_INJECTION"] = fault
        result = subprocess.run(
            [sys.executable, "run_riscv_core.py"],
            cwd=test_dir,
            env=environment,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        if result.returncode == 0:
            failures.append(f"{fault}: verification unexpectedly passed")
            continue
        if "CPU core regression reported" not in result.stdout:
            failures.append(f"{fault}: failed outside the CPU verification result")
            continue
        print(f"{fault}: verification failed as expected")

    if failures:
        raise RuntimeError("\n".join(failures))


if __name__ == "__main__":
    main()
