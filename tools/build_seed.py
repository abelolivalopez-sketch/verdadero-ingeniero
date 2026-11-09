#!/usr/bin/env python3
"""
Genera el SQL de carga de contenido a partir de:
  content/roadmap.yaml      → fases, módulos y todos los días (título + objetivo)
  content/days/day_XXX.md   → teoría, práctica y banco de preguntas de cada día

Uso:
  python3 tools/build_seed.py            # genera supabase/02_seed.sql y supabase/00_setup_completo.sql
  python3 tools/build_seed.py --check    # solo valida el contenido

Formato de un día (content/days/day_001.md):

  ---
  day: 1
  minutes: 60
  ---
  # Teoría en Markdown, fórmulas con \\( inline \\) y \\[ bloque \\]
  <!-- PRACTICA -->
  Ejercicios guiados...
  <!-- PREGUNTAS -->
  ### Q d=1 mcq
  Enunciado
  - [ ] opción incorrecta
  - [x] opción correcta
  > Explicación
  ### Q d=2 num tol=1 unit="m/s"
  Enunciado
  = 25
  > Explicación
"""
import json
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
OUT_DIR = ROOT / "supabase"
TAG = "$vi$"


def q(s):
    """Literal SQL con dollar-quoting (no hay que escapar comillas ni barras)."""
    if s is None:
        return "null"
    s = str(s)
    if TAG in s:
        raise ValueError("El texto contiene el delimitador $vi$")
    return f"{TAG}{s}{TAG}"


def arr(items):
    return "array[" + ", ".join(q(i) for i in items) + "]::text[]" if items else "'{}'::text[]"


def load_roadmap():
    data = yaml.safe_load((CONTENT / "roadmap.yaml").read_text(encoding="utf-8"))
    days, modules = [], []
    n = 0
    for pos, m in enumerate(data["modules"], start=1):
        start = n + 1
        for line in m["days"]:
            title, objective = [p.strip() for p in line.split("|", 1)]
            n += 1
            days.append({"day": n, "module": m["id"], "title": title, "objective": objective})
        modules.append({**m, "position": pos, "day_start": start, "day_end": n})
    if n % 7:
        raise SystemExit(f"ERROR: el plan tiene {n} días; debe ser múltiplo de 7")
    return data["phases"], modules, days


HEADER_RE = re.compile(r"^### Q\b(.*)$")
ATTR_RE = re.compile(r'(\w+)=("([^"]*)"|\S+)')


def parse_header(rest):
    attrs, flags = {}, set()
    for m in ATTR_RE.finditer(rest):
        attrs[m.group(1)] = m.group(3) if m.group(3) is not None else m.group(2)
    leftover = ATTR_RE.sub("", rest).split()
    flags.update(leftover)
    return attrs, flags


def parse_questions(block, day, errors):
    questions, cur = [], None
    for line in block.splitlines():
        h = HEADER_RE.match(line)
        if h:
            if cur:
                questions.append(cur)
            attrs, flags = parse_header(h.group(1))
            cur = {"attrs": attrs, "flags": flags, "prompt": [], "options": [], "correct": [],
                   "value": None, "expl": []}
            continue
        if cur is None:
            continue
        s = line.rstrip()
        if s.startswith("- [ ] ") or s.startswith("- [x] ") or s.startswith("- [X] "):
            if s[3].lower() == "x":
                cur["correct"].append(len(cur["options"]))
            cur["options"].append(s[6:].strip())
        elif s.startswith("= ") and not cur["options"]:
            cur["value"] = s[2:].strip()
        elif s.startswith(">"):
            cur["expl"].append(s[1:].lstrip() if len(s) > 1 else "")
        elif cur["expl"]:
            cur["expl"].append(s)
        else:
            cur["prompt"].append(s)
    if cur:
        questions.append(cur)

    out = []
    for i, c in enumerate(questions, start=1):
        key = f"D{day:03d}-Q{i:02d}"
        where = f"{key}"
        try:
            d = int(c["attrs"].get("d", "0"))
        except ValueError:
            d = 0
        if d not in (1, 2, 3):
            errors.append(f"{where}: dificultad d= debe ser 1, 2 o 3")
        qtype = "numeric" if "num" in c["flags"] else "mcq"
        prompt = "\n".join(c["prompt"]).strip()
        expl = "\n".join(c["expl"]).strip()
        if not prompt:
            errors.append(f"{where}: enunciado vacío")
        if not expl:
            errors.append(f"{where}: falta explicación")
        item = {"key": key, "day": day, "d": d, "qtype": qtype, "prompt": prompt, "expl": expl,
                "options": None, "correct": None, "value": None,
                "tol": float(c["attrs"].get("tol", 2)), "unit": c["attrs"].get("unit")}
        if qtype == "mcq":
            if not (2 <= len(c["options"]) <= 6):
                errors.append(f"{where}: una MCQ necesita entre 2 y 6 opciones")
            if len(c["correct"]) != 1:
                errors.append(f"{where}: debe haber exactamente una opción [x]")
            item["options"] = c["options"]
            item["correct"] = c["correct"][0] if c["correct"] else 0
        else:
            try:
                item["value"] = float(c["value"])
            except (TypeError, ValueError):
                errors.append(f"{where}: respuesta numérica '= valor' ausente o no válida")
        out.append(item)
    return out


def load_days(errors):
    result = {}
    for path in sorted((CONTENT / "days").glob("day_*.md")):
        text = path.read_text(encoding="utf-8")
        m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
        if not m:
            errors.append(f"{path.name}: falta la cabecera ---")
            continue
        meta = yaml.safe_load(m.group(1)) or {}
        day = int(meta["day"])
        rest = text[m.end():]
        parts = re.split(r"^<!--\s*(PRACTICA|PREGUNTAS)\s*-->\s*$", rest, flags=re.M)
        body, practice, qblock = parts[0].strip(), None, ""
        for tag, chunk in zip(parts[1::2], parts[2::2]):
            if tag == "PRACTICA":
                practice = chunk.strip()
            else:
                qblock = chunk
        qs = parse_questions(qblock, day, errors)
        per_level = {lvl: sum(1 for x in qs if x["d"] == lvl) for lvl in (1, 2, 3)}
        if min(per_level.values()) < 5:
            errors.append(f"{path.name}: se recomiendan ≥5 preguntas por nivel, hay {per_level}")
        result[day] = {"minutes": int(meta.get("minutes", 60)), "body": body,
                       "practice": practice, "questions": qs}
    return result


def catalog_json(phases, modules, days):
    return {
        "phases": [{"id": p["id"], "title": p["title"], "description": p.get("description")} for p in phases],
        "modules": [{"id": m["id"], "phase": m["phase"], "position": m["position"], "title": m["title"],
                     "description": m.get("description"), "day_start": m["day_start"], "day_end": m["day_end"],
                     "color": m.get("color", "#4FD1FF"), "tools": m.get("tools", [])} for m in modules],
        "days": [{"d": d["day"], "m": d["module"], "t": d["title"], "o": d["objective"]} for d in days],
    }


def day_json(day, c):
    qs = []
    for x in c["questions"]:
        item = {"k": x["key"], "d": x["d"], "t": x["qtype"], "p": x["prompt"], "e": x["expl"], "tol": x["tol"]}
        if x["options"] is not None:
            item["o"] = x["options"]
            item["c"] = x["correct"]
        if x["value"] is not None:
            item["v"] = x["value"]
        if x["unit"]:
            item["u"] = x["unit"]
        qs.append(item)
    return {"day": day, "minutes": c["minutes"], "body": c["body"], "practice": c["practice"], "questions": qs}


def js(obj):
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"))


def build_statements(phases, modules, days, content):
    """Lista de (nombre, sentencia SQL). Cada sentencia es independiente."""
    out = [("catalogo", f"select private.upsert_catalog({q(js(catalog_json(phases, modules, days)))}::jsonb);")]
    for day in sorted(content):
        out.append((f"dia_{day:03d}", f"select private.upsert_day({q(js(day_json(day, content[day])))}::jsonb);"))
    return out


def build_sql(statements):
    L = ["-- GENERADO AUTOMÁTICAMENTE por tools/build_seed.py · no editar a mano",
         "-- Contenido del programa Verdadero Ingeniero. Idempotente: se puede ejecutar varias veces.",
         "begin;", ""]
    for name, sql in statements:
        L.append(f"-- {name}")
        L.append(sql)
        L.append("")
    L.append("commit;")
    return "\n".join(L) + "\n"


def main():
    errors = []
    phases, modules, days = load_roadmap()
    content = load_days(errors)
    total_q = sum(len(c["questions"]) for c in content.values())
    print(f"Plan: {len(days)} días · {len(modules)} módulos · {len(content)} días redactados · {total_q} preguntas")
    if errors:
        print("\n".join("  ✗ " + e for e in errors))
        sys.exit(1)
    if "--check" in sys.argv:
        print("Contenido válido.")
        return
    statements = build_statements(phases, modules, days, content)
    seed = build_sql(statements)
    (OUT_DIR / "02_seed.sql").write_text(seed, encoding="utf-8")
    chunks = OUT_DIR / "chunks"
    chunks.mkdir(exist_ok=True)
    for old in chunks.glob("*.sql"):
        old.unlink()
    for name, sql in statements:
        (chunks / f"{name}.sql").write_text(sql + "\n", encoding="utf-8")
    schema = (OUT_DIR / "01_schema.sql").read_text(encoding="utf-8")
    (OUT_DIR / "00_setup_completo.sql").write_text(
        "-- VERDADERO INGENIERO · instalación completa (esquema + contenido)\n"
        "-- Pégalo entero en Supabase → SQL Editor → Run.\n\n" + schema + "\n\n" + seed, encoding="utf-8")
    print("Generados: supabase/02_seed.sql, supabase/00_setup_completo.sql y supabase/chunks/*.sql")


if __name__ == "__main__":
    main()
