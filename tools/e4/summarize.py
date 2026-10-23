"""Summarize the E3 baseline and the two E4 timer trials (standard library only)."""
import csv
import json
import math
from pathlib import Path
from statistics import median
import sys


def rows(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def stats(values):
    values = sorted(values)
    if not values:
        raise ValueError("Empty measurement sample")
    return {"count": len(values), "median": median(values),
            "p95": values[math.ceil(.95 * len(values)) - 1], "max": max(values)}


def summarize(folder):
    ticks = rows(folder / "timer.csv")
    resources = rows(folder / "resources.csv")
    paints = rows(folder / "paint.csv") if (folder / "paint.csv").exists() else []
    result = {}
    for phase, name in [("0", "without_debug"), ("1", "with_debug")]:
        ts = [row for row in ticks if row["phase"] == phase]
        ps = [row for row in paints if row["phase"] == phase]
        first = next(row for row in resources if row["phase"] == name + "_start")
        last = next(row for row in resources if row["phase"] == name + "_end")
        seconds = (float(last["time_ms"]) - float(first["time_ms"])) / 1000
        data = {
            "duration_seconds": seconds,
            "timer_interval_ms": stats([float(row["interval_ms"]) for row in ts if float(row["interval_ms"]) > 0]),
            "handler_ms": stats([float(row["handler_ms"]) for row in ts]),
            "cpu_percent_one_core": (float(last["cpu_ms"]) - float(first["cpu_ms"])) / (seconds * 10),
            "resources_start": first, "resources_end": last,
        }
        if ps:
            data["paints_per_second"] = len(ps) / seconds
            for key in ["interval_ms", "draw_ms", "present_ms", "total_ms"]:
                data["paint_" + key] = stats([float(row[key]) for row in ps
                    if key != "interval_ms" or float(row[key]) > 0])
        result[name] = data
    return result


if __name__ == "__main__":
    if len(sys.argv) != 5:
        raise SystemExit("Usage: summarize.py <before> <canvas16> <canvas15> <output.json>")
    report = {name: summarize(Path(folder)) for name, folder in
              zip(["before", "after", "timer15"], sys.argv[1:4])}
    Path(sys.argv[4]).write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
