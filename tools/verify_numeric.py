#!/usr/bin/env python3
"""Recalcula de forma independiente las respuestas numéricas del banco de preguntas
y comprueba que coinciden con las del contenido (dentro de la mitad de la tolerancia)."""
import cmath
import math as m
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
import build_seed as b  # noqa: E402

r, d2r = m.radians, m.degrees
g = 9.81


def crane(boom_deg, cy, w):
    bx, by = 10 * m.cos(r(boom_deg)), 10 * m.sin(r(boom_deg))
    dx, dy = -bx, cy - by
    L = m.hypot(dx, dy)
    A = np.array([[dx / L, m.cos(r(boom_deg))], [dy / L, m.sin(r(boom_deg))]])
    return np.linalg.solve(A, [0, w])


def cables(a1, a2, w):
    A = np.array([[-m.cos(r(a1)), m.cos(r(a2))], [m.sin(r(a1)), m.sin(r(a2))]])
    return np.linalg.solve(A, [0, w])


u = np.array([3, 4, -6]) / m.sqrt(61)
F1 = 350 * np.array([2, 3, 6]) / 7
F2 = 260 * np.array([12, -4, -3]) / 13
Fd9 = np.array([120, -60, 80])
M10 = np.cross([0.5, 0, 0.2], [0, 300, -100])
M14 = np.cross([2, 6, -1.5], [120, 0, -40])
W7 = 3300 * 0.45359 * g / 1000

EXPECTED = {
    "D001-Q03": 90 / 3.6, "D001-Q05": 2.5 * 100, "D001-Q07": 30 * 6894.76 / 1000, "D001-Q09": 150 * 735.5 / 1000,
    "D001-Q11": 1.2 * 20 * 0.3 / 1.8e-5, "D001-Q14": 100 * 4.448, "D001-Q15": 12000 / 40,
    "D002-Q03": 0.3 / 10 * 100, "D002-Q06": 1.0, "D002-Q07": 5, "D002-Q09": 3000 * 2 * m.pi / 60,
    "D002-Q11": 78.5 / (m.pi * 2.0 ** 2 / 4 * 3.2), "D002-Q12": 0.2 + 2 * 0.5 + 0.3,
    "D002-Q13": m.sqrt(0.2 ** 2 + 1 + 0.3 ** 2), "D002-Q15": 0.5 * 70000 * 75 ** 2 / 1e6,
    "D003-Q02": 6, "D003-Q04": 58, "D003-Q06": 12 - 12 * 2 / 6,
    "D003-Q07": min(np.roots([4.905, -20, 15])), "D003-Q10": np.linalg.solve([[2, 3], [4, -1]], [13, 5])[1],
    "D003-Q11": np.linalg.solve([[1, 1, 1], [2, -1, 1], [1, 2, -1]], [6, 3, 2])[2],
    "D003-Q13": 1.1117 + 0.3 * (1.0066 - 1.1117), "D003-Q14": np.linalg.det([[3, 2], [1, -4]]),
    "D003-Q15": (1.1 ** 5 - 1) * 100,
    "D004-Q03": 100 * m.exp(-1), "D004-Q06": 10 * m.log(2), "D004-Q07": 12 * (1 - m.exp(-2)), "D004-Q09": 20,
    "D004-Q10": m.log(50) / m.log(2), "D004-Q11": 101.325 * m.exp(-10 / 8.4),
    "D004-Q12": 10 / m.log(2) * m.log(180 / 30), "D004-Q14": 100, "D004-Q15": m.log(8) / m.log(4),
    "D005-Q01": m.pi, "D005-Q03": d2r(1), "D005-Q05": 1500 * 2 * m.pi / 60, "D005-Q06": 0.5 * r(120),
    "D005-Q08": (r(5) - m.sin(r(5))) / m.sin(r(5)) * 100, "D005-Q10": 2 * m.pi / 314.16,
    "D005-Q11": m.sin(r(75)), "D005-Q13": 400 * 2 * m.pi / 60 * 5, "D005-Q14": 5, "D005-Q15": d2r(m.atan2(4, 3)),
    "D006-Q01": 200 * m.cos(r(30)), "D006-Q03": 10, "D006-Q05": 500 * m.sin(r(60)), "D006-Q06": 500,
    "D006-Q07": m.sqrt(25 + 49 - 70 * m.cos(r(60))), "D006-Q08": 50 * g * m.cos(r(20)),
    "D006-Q10": abs(300 + 400 * cmath.exp(1j * r(60))), "D006-Q11": cables(30, 45, 1000)[1],
    "D006-Q12": cables(30, 45, 1000)[0], "D006-Q13": d2r(cmath.phase(300 + 400 * cmath.exp(1j * r(60)))),
    "D006-Q15": 8 * m.sin(r(40)) / m.sin(r(65)),
    "D007-Q01": 3300 * 0.45359, "D007-Q03": 10 * m.cos(r(50)), "D007-Q05": 9490 / 9.81,
    "D007-Q06": m.hypot(10 * m.cos(r(50)), 12 - 10 * m.sin(r(50))),
    "D007-Q07": d2r(m.atan((12 - 10 * m.sin(r(50))) / (10 * m.cos(r(50))))), "D007-Q08": 9490 / 400,
    "D007-Q10": m.sqrt(4 * 23.73 / m.pi), "D007-Q11": crane(50, 12, 15)[0], "D007-Q12": crane(50, 12, 15)[1],
    "D007-Q13": crane(50, 12, W7)[0], "D007-Q14": 3,
    "D008-Q01": 5, "D008-Q02": 7, "D008-Q06": 5, "D008-Q07": d2r(m.acos(6 / 7)), "D008-Q08": 500 * u[0],
    "D008-Q10": np.linalg.norm([60, 80, 80]), "D008-Q11": 500 * u[2], "D008-Q12": np.linalg.norm(F1 + F2),
    "D008-Q13": 2, "D008-Q14": m.hypot(230, 20), "D008-Q15": d2r(m.atan(20 / 230)),
    "D009-Q01": np.dot([1, 2, 3], [4, -5, 6]), "D009-Q03": 50, "D009-Q05": 20 * m.cos(r(60)), "D009-Q06": 60,
    "D009-Q07": 7 / m.sqrt(2), "D009-Q08": np.dot([30, 40, -20], [2, 0, 1]), "D009-Q10": -2,
    "D009-Q11": np.dot(Fd9, [2, -1, 2]) / 3,
    "D009-Q12": d2r(m.acos(np.dot(Fd9, [2, -1, 2]) / 3 / np.linalg.norm(Fd9))),
    "D009-Q13": 120e3 * 70 * m.cos(r(8)) / 1e6, "D009-Q15": 2 * g * 4,
    "D010-Q02": 60, "D010-Q04": 12, "D010-Q07": np.linalg.norm(np.cross([2, 1, 0], [0, 0, -500])),
    "D010-Q08": 150 * 0.25 * m.sin(r(60)), "D010-Q09": 6, "D010-Q11": np.linalg.norm(M10),
    "D010-Q12": np.dot(M10, [1, 1, 0]) / m.sqrt(2), "D010-Q13": np.linalg.norm(M10) / m.hypot(300, 100),
    "D010-Q15": np.dot([1, 0, 0], np.cross([1, 2, 0], [0, 1, 3])),
    "D011-Q02": 5, "D011-Q07": d2r(cmath.phase(-1 + 1j)), "D011-Q09": 10, "D011-Q11": ((1 + 1j) ** 8).real,
    "D011-Q12": 2 * m.cos(r(120)), "D011-Q13": (cmath.rect(2, r(30)) * cmath.rect(3, r(45))).real,
    "D011-Q15": abs(1 / (1 + 2j)),
    "D012-Q02": 2 * m.pi * 50 * 0.1, "D012-Q04": 50, "D012-Q06": 1 / (2 * m.pi * 50 * 1e-4),
    "D012-Q07": abs(10 + 10j), "D012-Q08": 230 / 50, "D012-Q10": abs(6 - 8j),
    "D012-Q11": 1 / (2 * m.pi * m.sqrt(0.05 * 200e-6)), "D012-Q12": m.sqrt(800 / 2) / (2 * m.pi),
    "D012-Q13": -d2r(cmath.phase(20 - 1j / (2 * m.pi * 50 * 1e-4))), "D012-Q15": abs(8 + 6j),
    "D013-Q01": 5, "D013-Q03": 2 * m.cos(r(60)), "D013-Q06": 135, "D013-Q07": 4 / 3, "D013-Q09": -1,
    "D013-Q10": 4, "D013-Q11": 1 / m.sqrt(1 + 1 / 4 + 1 / 9), "D013-Q12": 10 * m.sin(r(60)) * m.cos(r(30)),
    "D013-Q13": 2, "D013-Q14": 2, "D013-Q15": 60,
    "D014-Q01": 20, "D014-Q03": 3, "D014-Q05": 3, "D014-Q06": 4, "D014-Q07": 4700 * 220e-6,
    "D014-Q08": abs((1 + 1j) * (2 - 1j)), "D014-Q09": m.sqrt(9 + 16 - 24 * m.cos(r(120))),
    "D014-Q11": np.linalg.norm(M14), "D014-Q12": M14[2], "D014-Q13": 1000 * 2 * 0.05 / 1e-3,
    "D014-Q14": 30 / m.log(4),
}

# ---- Preguntas de los talleres (versión 2 h/día) ----
_A0 = np.array([0, 0, 10.0])
_Bs = [np.array([4, 0, 0.0]), np.array([-2, 3, 0.0]), np.array([-2, -3, 0.0])]
_Rm = sum(T * (B - _A0) / np.linalg.norm(B - _A0) for T, B in zip([1000, 800, 800], _Bs))
_n13 = np.cross([100, 0, 20], [0, 80, 10])
_r14 = np.array([2, 6, -1.5])
EXPECTED.update({
    "D001-Q17": 3 * 25.4, "D001-Q18": 101325 / 1e5, "D001-Q20": 1.225 * 10 * 0.15 / 1.81e-5,
    "D002-Q17": 0.1 / 50 * 100, "D002-Q18": 1 + 2 + 3,
    "D002-Q20": 42.4 / (m.pi * 20 ** 2 / 4 * 50) * 1000, "D002-Q21": 0.03 * m.pi / 6 * 10 ** 3,
    "D003-Q16": (10 * 2 + 6 * 5) / 8, "D003-Q18": 16 - (10 * 2 + 6 * 5) / 8, "D003-Q19": max(np.roots([1, -5, 6])),
    "D003-Q20": np.linalg.solve([[2, 1, -1], [-3, -1, 2], [-2, 1, 2]], [8, -11, -3])[2],
    "D004-Q17": m.exp(-3) * 100, "D004-Q18": m.log(4.85 / 1.21) / m.log(2), "D004-Q20": 2 * 0.0121 / (1.2 * 0.05),
    "D004-Q21": 2.2 * m.log(100),
    "D005-Q16": 2700 * 2 * m.pi / 60, "D005-Q18": 2700 * 2 * m.pi / 60 * 0.9, "D005-Q19": 2700 * 2 * m.pi / 60 * 0.9 / 340,
    "D005-Q20": 60 * 0.85 * 340 / (m.pi * 1.8),
    "D006-Q17": 1200 * m.sin(r(20)), "D006-Q18": cables(20, 30, 200)[1], "D006-Q20": cables(20, 30, 200)[0],
    "D006-Q21": 50 * g / (2 * m.sin(r(2))),
    "D007-Q16": 2000 * 0.45359, "D007-Q18": crane(40, 10, 15)[0], "D007-Q19": m.sqrt(4 * 12410 / (m.pi * 400)),
    "D007-Q20": crane(70, 12, 15)[0],
    "D008-Q17": 0.8, "D008-Q18": _Rm[0], "D008-Q19": np.linalg.norm(_Rm),
    "D008-Q20": 2 * 800 * 2 / np.linalg.norm(_Bs[1] - _A0) / (4 / np.linalg.norm(_Bs[0] - _A0)),
    "D009-Q17": np.dot([2, 2, 1], [1, 0, 3]), "D009-Q18": np.dot([-3, 1, 0], [10, 5, 2]),
    "D009-Q20": -np.dot(np.array([0, 0, -1.5 * g]) + np.array([-1.2, 0, -0.6]), [4, 0, 2]),
    "D009-Q21": d2r(m.atan2(2, 4)),
    "D010-Q17": np.cross([1, 0, 0], [0, 1, 0])[2], "D010-Q18": np.cross([0.17, 0.05, 0], [0, 0, -700])[1],
    "D010-Q19": np.linalg.norm(np.cross([0.17, 0.05, 0], [0, 0, -700])),
    "D010-Q20": np.linalg.norm(np.cross([2, 1, 0], [0, 0, -500]) + np.cross([0, 2, 1], [100, 0, 0])),
    "D011-Q17": d2r(cmath.phase(1j)), "D011-Q18": max(np.roots([1, 2, 5]).imag),
    "D011-Q20": max(np.roots([1, 2, 3, 10]).real),
    "D012-Q16": 8 / (2 * m.sqrt(800 * 2)), "D012-Q18": 1 / (2 * 0.1), "D012-Q19": 40 / 800 * 1000,
    "D012-Q20": 40 / abs(800 - 2 * 25 ** 2 + 1j * 8 * 25) * 1000,
    "D013-Q17": m.hypot(100, 20), "D013-Q18": d2r(m.acos(_n13[2] / np.linalg.norm(_n13))),
    "D013-Q19": np.dot(_n13, [50, 40, 60]) / np.linalg.norm(_n13), "D013-Q20": (-_n13[0] * 50 - _n13[1] * 40) / _n13[2],
    "D014-Q17": 2.5 * 40, "D014-Q18": np.linalg.norm(np.cross(_r14, [30, 0, -40])),
    "D014-Q19": np.linalg.norm(np.cross(_r14, [-40, 0, -100])), "D014-Q21": np.cross(_r14, [-40, 0, -100])[2],
})


def main():
    errors = []
    content = b.load_days(errors)
    bad, checked, missing = 0, 0, []
    for day in sorted(content):
        for x in content[day]["questions"]:
            if x["qtype"] != "numeric":
                continue
            if x["key"] not in EXPECTED:
                missing.append(x["key"])
                continue
            exp = float(EXPECTED[x["key"]])
            checked += 1
            rel = abs(x["value"] - exp) / max(abs(exp), 1e-12) * 100
            if rel > x["tol"] / 2:
                bad += 1
                print(f"✗ {x['key']}: contenido={x['value']}  recalculado={exp:.6g}  (desvío {rel:.3f} %, tol {x['tol']} %)")
    print(f"Comprobadas {checked} respuestas numéricas · {bad} discrepancias · sin verificar: {missing or 'ninguna'}")
    sys.exit(1 if bad or missing else 0)


if __name__ == "__main__":
    main()
