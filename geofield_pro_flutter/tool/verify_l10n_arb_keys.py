"""
Tr / Uz / En ARB fayllarida bir xil kalitlar bor-yo'qligini tekshiradi.
ishlatish: python tool/verify_l10n_arb_keys.py
Chiqish: 0 — OK, 1 — farq
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib" / "l10n"
FILES = ["app_en.arb", "app_tr.arb", "app_uz.arb"]


def keys(path: Path) -> set[str]:
    d = json.loads(path.read_text(encoding="utf-8"))
    return {k for k in d if not k.startswith("@@")}


def main() -> int:
    loaded = {f: keys(ROOT / f) for f in FILES}
    base = loaded["app_en.arb"]
    for name, s in loaded.items():
        if s == base:
            continue
        only_base = base - s
        only_other = s - base
        print(f"Farq: {name}")
        if only_base:
            print(f"  en da bor, {name} da yo'q: {list(sorted(only_base))[:30]}")
        if only_other:
            print(f"  {name} da ortiqcha: {list(sorted(only_other))[:30]}")
        return 1
    print("ARB kalitlar u yuzma-yuz: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
