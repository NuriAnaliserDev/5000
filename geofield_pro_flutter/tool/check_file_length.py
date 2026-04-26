"""
lib/ ichidagi .dart fayllarining qator sonini tekshiradi (standart: 2000).
Ishlatish: python tool/check_file_length.py [max_lines]
Chiqish: 0 yoki 1
"""

from __future__ import annotations

import sys
from pathlib import Path

DEFAULT_MAX = 2000


def main() -> int:
    max_lines = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_MAX
    proj = Path(__file__).resolve().parent.parent
    root = proj / "lib"
    bad: list[tuple[str, int]] = []
    for p in sorted(root.rglob("*.dart")):
        n = sum(1 for _ in p.open(encoding="utf-8"))
        if n > max_lines:
            bad.append((str(p.relative_to(proj)), n))
    if not bad:
        print(f"OK: barcha lib/*.dart fayllar {max_lines} qatordan oshmaydi.")
        return 0
    print(f"Oshib ketgan fayllar (>{max_lines} qator):")
    for path, n in sorted(bad, key=lambda x: -x[1]):
        print(f"  {n:5d}  {path}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
