#!/usr/bin/env python3
"""Import every generated Yoga 3.2.1 layout fixture without executing C++.

Usage: python3 Scripts/import-yoga-fixtures.py /path/to/yoga-v3.2.1
Unknown statements fail the import so upstream coverage cannot silently shrink.
"""
import json
import re
import sys
from pathlib import Path

source = Path(sys.argv[1])
fixtures = []
for path in sorted((source / "tests/generated").glob("*.cpp")):
    text = path.read_text()
    for match in re.finditer(r"TEST\(YogaTest,\s*(\w+)\)\s*\{(.*?)^\}", text, re.S | re.M):
        name, body = match.groups()
        operations = []
        skipped = False
        for raw in body.splitlines():
            line = raw.strip()
            if not line or line.startswith("//"):
                continue
            if line == "GTEST_SKIP();":
                skipped = True
                continue
            if line == "YGConfigRef config = YGConfigNew();" or re.fullmatch(r"YG(?:NodeFreeRecursive|ConfigFree)\(\w+\);", line):
                continue
            if m := re.fullmatch(r"YGNodeRef (\w+) = YGNodeNewWithConfig\(config\);", line):
                operations.append(["new", m[1]])
            elif m := re.fullmatch(r'YGNodeSetContext\((\w+), \(void\*\)(".*")\);', line):
                operations.append(["text", m[1], json.loads(m[2])])
            elif m := re.fullmatch(r"YGNodeSetMeasureFunc\((\w+), &facebook::yoga::test::IntrinsicSizeMeasure\);", line):
                operations.append(["measure", m[1]])
            elif m := re.fullmatch(r"YGNodeStyleSet(\w+)\((.*)\);", line):
                operations.append(["style", m[1], *[x.strip() for x in m[2].split(",")]])
            elif m := re.fullmatch(r"YGNodeInsertChild\((\w+), (\w+), (\d+)\);", line):
                operations.append(["insert", *m.groups()])
            elif m := re.fullmatch(r"YGNodeCalculateLayout\((.*)\);", line):
                operations.append(["layout", *[x.strip() for x in m[1].split(",")]])
            elif m := re.fullmatch(r"ASSERT_FLOAT_EQ\((.*), YGNodeLayoutGet(\w+)\((\w+)\)\);", line):
                operations.append(["expect", m[3], m[2], m[1]])
            else:
                raise ValueError(f"{path.name}/{name}: unrecognized statement: {line}")
        fixtures.append({"name": name, "source": path.name, "upstreamSkipped": skipped, "operations": operations})

expected = sum(len(re.findall(r"TEST\(", p.read_text())) for p in (source / "tests/generated").glob("*.cpp"))
assert len(fixtures) == expected, (len(fixtures), expected)
destination = Path(__file__).resolve().parents[1] / "Tests/YogaTests/Fixtures/yoga-3.2.1.json"
destination.write_text(json.dumps(fixtures, separators=(",", ":")) + "\n")
print(f"Imported all {len(fixtures)} fixtures into {destination}")
