"""Summarize the E0 observation logs using the Python standard library."""

import csv
import json
import math
import statistics
import sys
from pathlib import Path


def rows(path):
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def percentile95(values):
    ordered = sorted(values)
    return ordered[math.floor((len(ordered) - 1) * 0.95)]


def summarize(folder):
    ticks = rows(folder / "timer.csv")
    resources = rows(folder / "resources.csv")
    scenarios = {row["scenario"]: row for row in rows(folder / "scenarios.csv")}
    output = {"method": "instrumented legacy event handlers; not a rendering FPS measurement", "phases": []}
    for phase, name in [("0", "without_debug"), ("1", "with_debug")]:
        samples = [row for row in ticks if row["phase"] == phase]
        intervals = [float(row["interval_ms"]) for row in samples if float(row["interval_ms"]) > 0]
        costs = [float(row["handler_ms"]) for row in samples]
        assert len(samples) > 10 and len(intervals) == len(samples) - 1
        start = next(row for row in resources if row["phase"] == name + "_start")
        end = next(row for row in resources if row["phase"] == name + "_end")
        elapsed = float(end["time_ms"]) - float(start["time_ms"])
        cpu = float(end["cpu_ms"]) - float(start["cpu_ms"])
        memory = [int(row["working_set_bytes"]) for row in resources
                  if float(start["time_ms"]) <= float(row["time_ms"]) <= float(end["time_ms"])]
        output["phases"].append({
            "name": name, "samples": len(samples), "duration_ms": elapsed,
            "mean_interval_ms": statistics.mean(intervals),
            "median_interval_ms": statistics.median(intervals),
            "p95_interval_ms": percentile95(intervals), "max_interval_ms": max(intervals),
            "updates_per_second": 1000 / statistics.mean(intervals),
            "mean_handler_ms": statistics.mean(costs), "p95_handler_ms": percentile95(costs),
            "cpu_one_core_percent": cpu / elapsed * 100,
            "working_set_min_mib": min(memory) / 1024**2,
            "working_set_max_mib": max(memory) / 1024**2,
            "handles_start": int(start["handles"]), "handles_end": int(end["handles"]),
            "gdi_start": int(start["gdi_objects"]), "gdi_end": int(end["gdi_objects"]),
            "user_start": int(start["user_objects"]), "user_end": int(end["user_objects"]),
        })

    def integer(scenario, key):
        return int(scenarios[scenario][key])

    observations = {
        "initial_96_bricks_three_lives": integer("initial", "bricks") == 96 and integer("initial", "lives_width") == 45,
        "paddle_left_dx_dy": [integer("paddle_region_0", key) for key in ("dx", "dy")],
        "paddle_center_dx_dy": [integer("paddle_region_1", key) for key in ("dx", "dy")],
        "paddle_right_dx_dy": [integer("paddle_region_2", key) for key in ("dx", "dy")],
        "brick_top_destroyed_continues_down": integer("brick_top_downward", "bricks") == 0 and integer("brick_top_downward", "dy") > 0,
        "pause_stops_timer": scenarios["pause_f3"]["timer_enabled"] == "False",
        "space_during_pause_relaunches": scenarios["space_while_paused"]["timer_enabled"] == "True" and integer("space_while_paused", "ball_y") == 395,
        "space_during_pause_leaves_message_visible": scenarios["space_while_paused"]["message_visible"] == "True",
        "immediate_f3_after_launch_ignored": scenarios["f3_immediately_after_launch"]["timer_enabled"] == "True",
        "f3_resume_preserves_position": integer("resume_f3", "dx") == 0 and integer("resume_f3", "dy") == 0,
        "deactivate_handler_pauses": scenarios["deactivate_handler"]["timer_enabled"] == "False",
        "lives_width_after_each_fall": [integer("lose_life_" + str(i), "lives_width") for i in range(1, 4)],
        "extra_motion_after_life_loss": [integer("lose_life_1", key) for key in ("dx", "dy")],
        "click_does_not_launch_at_game_over": scenarios["click_at_game_over"]["timer_enabled"] == "False",
        "f1_moves_after_game_over": integer("f1_at_game_over", "ball_y") != integer("click_at_game_over", "ball_y"),
        "f2_restores_96_bricks_three_lives": integer("restart_f2", "bricks") == 96 and integer("restart_f2", "lives_width") == 45,
    }
    assert observations["pause_stops_timer"], "The pause scenario did not enter pause; check harness build/reload."
    assert observations["paddle_left_dx_dy"] == [-15, -15]
    assert observations["paddle_center_dx_dy"] in ([5, -5], [-5, -5])
    assert observations["paddle_right_dx_dy"] == [15, -15]
    output["observations"] = observations
    (folder / "summary.json").write_text(json.dumps(output, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(output, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    folder = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[2] / "docs/evidencias/e0-2026-10-22"
    summarize(folder)
