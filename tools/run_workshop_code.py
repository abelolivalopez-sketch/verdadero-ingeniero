#!/usr/bin/env python3
"""Ejecuta todos los bloques de código Python de las secciones TALLER y comprueba que funcionan.

Uso: python3 tools/run_workshop_code.py [--show]   (--show imprime la salida de cada bloque)
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CODE_RE = re.compile(r"```python\n(.*?)```", re.S)


def workshop_section(text):
    m = re.search(r"^<!--\s*TALLER\s*-->\s*$(.*?)^<!--\s*(PRACTICA|PREGUNTAS)\s*-->", text, re.S | re.M)
    return m.group(1) if m else ""


def main():
    show = "--show" in sys.argv
    failures, total = 0, 0
    for path in sorted((ROOT / "content" / "days").glob("day_*.md")):
        for i, code in enumerate(CODE_RE.findall(workshop_section(path.read_text(encoding="utf-8"))), start=1):
            total += 1
            with tempfile.TemporaryDirectory() as tmp:
                script = Path(tmp) / "taller.py"
                script.write_text(code, encoding="utf-8")
                res = subprocess.run([sys.executable, "-I", str(script)], cwd=tmp, capture_output=True,
                                     text=True, timeout=120)
            ok = res.returncode == 0
            failures += not ok
            print(f"{'✔' if ok else '✗'} {path.name} bloque {i}")
            if show or not ok:
                print("   " + (res.stdout + res.stderr).strip().replace("\n", "\n   "))
    print(f"{total} bloques ejecutados · {failures} con error")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
