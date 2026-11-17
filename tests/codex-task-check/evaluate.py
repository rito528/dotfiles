"""Explicit live-model evaluation; never runs as part of the offline unit suite."""

import argparse
import importlib.util
import json
from pathlib import Path
import time


SOURCE = Path(__file__).resolve().parents[2] / "config/codex/task-check/task_check.py"
spec = importlib.util.spec_from_file_location("task_check_evaluation", SOURCE)
task_check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(task_check)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--codex", default="codex")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    results = []
    cases = json.loads(Path(__file__).with_name("eval_cases.json").read_text())
    for case in cases:
        started = time.monotonic()
        evidence = {
            key: value for key, value in case.items() if key not in {"name", "expected"}
        }
        evidence.setdefault("limitations", [])
        evidence["requests_incomplete"] = False
        try:
            verdict = task_check.run_judge(evidence, args.codex)
            result = {"name": case["name"], "expected": case["expected"], **verdict}
        except Exception as error:
            result = {
                "name": case["name"],
                "expected": case["expected"],
                "decision": "error",
                "error": type(error).__name__,
            }
        result["seconds"] = round(time.monotonic() - started, 2)
        results.append(result)
        args.output.write_text(json.dumps(results, ensure_ascii=False, indent=2) + "\n")
        print(json.dumps(result, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    main()
