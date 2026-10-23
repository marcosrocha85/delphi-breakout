"""Compare E5/E6 exported pixels; requires Pillow, never modifies the images."""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops


def compare(before, after):
    results = []

    def check(name, region, box=None):
        with Image.open(before / name) as source, Image.open(after / name) as target:
            left, right = source.convert("RGB"), target.convert("RGB")
            if left.size != right.size:
                raise ValueError(f"Different image dimensions: {name}")
            if box is not None:
                left, right = left.crop(box), right.crop(box)
            same = ImageChops.difference(left, right).getbbox() is None
            results.append({"frame": name, "region": region, "box": box,
                            "identical": same})

    # Fixed collision/render fixtures can be compared across the entire frame.
    for name in ["paddle-100.png", "fade-half.png", "level-1-complete.png",
                 "level-2-complete.png", "level-3-complete.png"]:
        check(name, "full frame")
    # Ready boards use a time-derived seed. Compare the changed UI regions;
    # differences in randomly selected brick classes are outside this experiment.
    for scale in [100, 125, 150, 200]:
        name = f"scale-{scale}.png"
        with Image.open(before / name) as frame:
            width = frame.width
        for region, top, bottom in [("HUD", 435, 453), ("message", 216, 240)]:
            check(name, region, (0, round(top * scale / 100), width,
                                 round(bottom * scale / 100)))
    return {"checks": len(results),
            "failures": sum(not row["identical"] for row in results),
            "comparisons": results}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("before", type=Path)
    parser.add_argument("after", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    report = compare(args.before, args.after)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"{report['checks']} pixel comparisons; {report['failures']} differences")
    raise SystemExit(1 if report["failures"] else 0)
