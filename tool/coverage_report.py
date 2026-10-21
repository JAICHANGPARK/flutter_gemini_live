import sys
import os

def analyze(target_prefix=""):
    lcov_path = "coverage/lcov.info"
    if not os.path.exists(lcov_path):
        print("coverage/lcov.info does not exist")
        return

    with open(lcov_path) as f:
        lines = f.readlines()

    current_file = None
    file_stats = {}

    for line in lines:
        line = line.strip()
        if line.startswith("SF:"):
            current_file = line[3:]
            file_stats[current_file] = {"hit": 0, "found": 0, "missing": []}
        elif line.startswith("DA:"):
            parts = line[3:].split(",")
            line_num = int(parts[0])
            count = int(parts[1])
            file_stats[current_file]["found"] += 1
            if count > 0:
                file_stats[current_file]["hit"] += 1
            else:
                file_stats[current_file]["missing"].append(line_num)

    total_hit = sum(s["hit"] for s in file_stats.values())
    total_found = sum(s["found"] for s in file_stats.values())
    overall_pct = (total_hit / total_found * 100) if total_found else 0.0
    print(f"Overall Coverage: {total_hit}/{total_found} = {overall_pct:.2f}%\n")

    sorted_files = sorted(file_stats.items(), key=lambda x: len(x[1]["missing"]), reverse=True)
    for path, data in sorted_files:
        if target_prefix and not path.startswith(target_prefix):
            continue
        missing = data["missing"]
        if missing:
            pct = data["hit"] / data["found"] * 100
            print(f"[{len(missing):3d} missing, {pct:6.2f}%] {path}")
            if len(missing) <= 25 or target_prefix:
                print(f"   Missing lines: {missing}")

if __name__ == "__main__":
    prefix = sys.argv[1] if len(sys.argv) > 1 else ""
    analyze(prefix)
