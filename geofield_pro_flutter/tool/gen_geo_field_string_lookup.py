#!/usr/bin/env python3
"""app_strings.dart dan GeoFieldStrings getterlari uchun switch (bir necha `part` fayllar)."""
import os
import re
import glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "lib", "l10n", "app_strings.dart")
OUT_MAIN = os.path.join(ROOT, "lib", "utils", "geo_field_string_lookup.dart")
OUT_PART_DIR = os.path.join(ROOT, "lib", "utils")

HEADER_MAIN = """// GENERATED: tool/gen_geo_field_string_lookup.py (flutter gen-l10n keyin qayta ishga tushiring)
import 'package:geofield_pro_flutter/l10n/app_strings.dart';
"""

CHUNK_SIZE = 160


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

    chunks = [
        cases[i : i + CHUNK_SIZE] for i in range(0, len(cases), CHUNK_SIZE)
    ]
    if not chunks:
        chunks = [[]]

    # Eski part fayllarni tozalash
    for p in glob.glob(
        os.path.join(OUT_PART_DIR, "geo_field_string_lookup_*.dart")
    ):
        os.remove(p)

    parts_decl = "\n".join(
        f"part 'geo_field_string_lookup_{i}.dart';" for i in range(len(chunks))
    )

    dispatch_lines = ["String? lookupGeoFieldString(GeoFieldStrings s, String key) {"]
    for i in range(len(chunks)):
        dispatch_lines.append(f"  final chunk{i} = _lookupGeoFieldChunk{i}(s, key);")
        dispatch_lines.append(f"  if (chunk{i} != null) return chunk{i};")
    dispatch_lines.append("  return null;")
    dispatch_lines.append("}")

    main_src = (
        HEADER_MAIN
        + "\n"
        + parts_decl
        + "\n\n"
        + "\n".join(dispatch_lines)
        + "\n"
    )
    with open(OUT_MAIN, "w", encoding="utf-8") as f:
        f.write(main_src)

    for i, chunk in enumerate(chunks):
        inner = "\n".join(chunk) if chunk else ""
        part_src = (
            "part of 'geo_field_string_lookup.dart';\n\n"
            f"String? _lookupGeoFieldChunk{i}(GeoFieldStrings s, String key) {{\n"
            "  switch (key) {\n"
            f"{inner}\n"
            "    default:\n"
            "      return null;\n"
            "  }\n"
            "}\n"
        )
        part_path = os.path.join(OUT_PART_DIR, f"geo_field_string_lookup_{i}.dart")
        with open(part_path, "w", encoding="utf-8") as f:
            f.write(part_src)

    print(
        "wrote",
        OUT_MAIN,
        "chunks",
        len(chunks),
        "cases",
        len(cases),
        "skipped methods",
        with_args,
    )


if __name__ == "__main__":
    main()
