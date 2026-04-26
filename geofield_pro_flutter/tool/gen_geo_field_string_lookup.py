#!/usr/bin/env python3
"""app_strings.dart dan GeoFieldStrings getterlari uchun switch yaratish."""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "lib", "l10n", "app_strings.dart")
OUT = os.path.join(ROOT, "lib", "utils", "geo_field_string_lookup.dart")

HEADER = """// GENERATED: tool/gen_geo_field_string_lookup.py (flutter gen-l10n keyin qayta ishga tushiring)
import 'package:geofield_pro_flutter/l10n/app_strings.dart';

/// [GeoFieldStrings] getterlari bo'yicha [key] (snake_case, ARB kaliti).
/// `trend_recommend_good` / `apparent_result_hint` — parametrlar: [GeoFieldStrings]dagi to'g'ri metodni ishlating.
String? lookupGeoFieldString(GeoFieldStrings s, String key) {
  switch (key) {
"""

FOOTER = """
    default:
      return null;
  }
}
"""


def main():
    text = open(SRC, encoding="utf-8").read()
    try:
        s0 = text.index("abstract class GeoFieldStrings {")
        s1 = text.index("\n}\n\nclass _GeoFieldStringsDelegate")
        body = text[s0 : s1 + 1]
    except ValueError as e:
        raise SystemExit(f"parse abstract class: {e}")
    getters = re.findall(r"String get (\w+);", body)
    methods = re.findall(r"String (\w+)\s*\(([^)]*)\);", body)
    with_args = {name for name, a in methods if a.strip()}
    cases = []
    for g in sorted(set(getters), key=lambda x: x):
        if g in with_args:
            continue
        cases.append(f"    case '{g}': return s.{g};")
    out = HEADER + "\n".join(cases) + "\n" + FOOTER
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(out)
    print("wrote", OUT, "cases", len(cases), "skipped methods", with_args)


if __name__ == "__main__":
    main()
