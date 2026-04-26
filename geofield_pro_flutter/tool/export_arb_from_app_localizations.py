#!/usr/bin/env python3
"""One-off: app_localizations.dart ichidagi uz/en/tr maplardan app_*.arb fayllar yaratish."""
import json
import re
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "lib", "utils", "app_localizations.dart")

# Placeholder kalitlar (trend_recommend_good, apparent_result_hint, apparent_true_dip emas; ularda { } bor)
_PLACEHOLDER_KEYS = {
    "trend_recommend_good": ["dir"],
    "apparent_result_hint": ["trueDip", "apparent"],
}


def parse_map_block(lines, open_idx):
    """'uz': { bilan boshlanadigan qator indeksi. Balans 0 bo'lganda yopilgan."""
    depth = 0
    for j in range(open_idx, len(lines)):
        line = lines[j]
        depth += line.count("{") - line.count("}")
        if depth == 0 and j > open_idx:
            body = lines[open_idx + 1 : j]
            return _parse_entries(body), j + 1
    return None, 0


def _parse_entries(body_lines):
    """Oddiy 'key': 'value', qatorlarini yig'ish (ichki ' — \\' orqali)."""
    result = {}
    # Join va pattern
    text = "\n".join(body_lines)
    # 'key': '...'  — value ichida ' bo'lsa \'
    pattern = re.compile(
        r"^\s*'((?:\\.|[^'\\])*)':\s*'((?:\\.|[^'\\])*)'\s*,?\s*$", re.MULTILINE
    )
    for m in pattern.finditer(text):
        k = m.group(1).replace("\\'", "'")
        v = m.group(2).replace("\\'", "'").replace("\\n", "\n")
        result[k] = v
    return result


def load_maps():
    with open(SRC, encoding="utf-8") as f:
        lines = f.readlines()
    out = {}
    for lang in ("uz", "en", "tr"):
        for i, line in enumerate(lines):
            if re.match(rf"^\s*'{lang}':\s*{{\s*$", line):
                m, nxt = parse_map_block(lines, i)
                if m:
                    out[lang] = m
                break
    return out


def to_arb(lang_code, data, keys_order, uz, en, tr):
    """Barcha kalitlar: bo'sh qatorlarni tillar o'rtasida to'ldiradi."""
    o = {f"@@locale": lang_code}
    for k in keys_order:
        a, b, c = uz.get(k), en.get(k), tr.get(k)
        if k == "save_label":
            if lang_code == "uz":
                val = a or b or c or uz.get("save") or en.get("save")
            elif lang_code == "en":
                val = b or a or c or en.get("save")
            else:
                val = c or b or a or tr.get("save") or en.get("save")
        else:
            if lang_code == "uz":
                val = a or b or c
            elif lang_code == "en":
                val = b or a or c
            else:
                val = c or b or a
        if not val:
            val = f"__MISSING__{k}"
        o[k] = val
        meta = _PLACEHOLDER_KEYS.get(k)
        if meta:
            o["@" + k] = {
                "description": k,
                "placeholders": {p: {"type": "String"} for p in meta},
            }
    return o


def main():
    maps = load_maps()
    if len(maps) != 3:
        raise SystemExit(f"3 ta til kutiladi, topildi: {list(maps.keys())}")
    uz, en, tr = maps["uz"], maps["en"], maps["tr"]
    all_keys = sorted(set(uz) | set(en) | set(tr) | {"save_label"}, key=lambda x: x)
    print("uz keys:", len(uz), "en keys:", len(en), "tr keys:", len(tr), "union:", len(all_keys))
    l10n = os.path.join(ROOT, "lib", "l10n")
    os.makedirs(l10n, exist_ok=True)
    for code, m in [("en", en), ("uz", uz), ("tr", tr)]:
        arb = to_arb(code, m, all_keys, uz, en, tr)
        path = os.path.join(l10n, f"app_{code}.arb")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(arb, f, ensure_ascii=False, indent=2)
        print("wrote", path, "size", len(arb))


if __name__ == "__main__":
    main()
