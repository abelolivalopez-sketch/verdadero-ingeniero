# ⚙️ Verdadero Ingeniero

App de entrenamiento diario para convertirte en un ingeniero mecánico completo, con especialización aeronáutica (mecánica de fluidos y CFD). **Una hora al día, un examen al día**: el sistema adapta la dificultad a tus resultados y no te deja avanzar hasta que dominas el día.

- **Plataformas:** Android, iOS, Windows y web (un solo código Flutter).
- **Backend:** Supabase (PostgreSQL + autenticación). Toda la corrección se hace en el servidor: la app nunca recibe las soluciones antes de entregar.
- **Programa:** 455 días (15 meses · 65 semanas) en 5 fases y 24 módulos.

---

## 📚 El programa

| Fase | Módulos | Días |
|---|---|---|
| **1 · Fundamentos** | M01 Matemáticas del ingeniero · M02 Cálculo · M03 Álgebra lineal · M04 Cálculo vectorial · M05 Ecuaciones diferenciales · M06 Programación para ingenieros y métodos numéricos | 1–98 |
| **2 · Mecánica del ingeniero** | M07 Mecánica general: Estática · M08 Mecánica general: Dinámica · **M09 Teoría de máquinas y mecanismos** (movimiento relativo, Coriolis, levas, engranajes, trenes epicicloidales, volantes, equilibrado) · **M10 Elasticidad y resistencia de materiales** · M11 Materiales y fabricación · M12 Termodinámica y calor · **M13 Motores y máquinas de fluidos** · M14 Diseño de máquinas y CAD (SolidWorks, CATIA V5) · M15 Elementos finitos · **M16 Obras, montajes y proyectos** | 99–294 |
| **3 · Eléctrica, electrónica y mecatrónica** | M17 Electricidad · M18 Electrónica · M19 Mecatrónica (Arduino, Raspberry Pi, sensores, actuadores, ROS 2) · M20 Control | 295–357 |
| **4 · Aeronáutica: fluidos y CFD** | M21 Mecánica de fluidos · M22 Aerodinámica y mecánica de vuelo · M23 CFD (OpenFOAM, Fluent, mallado, turbulencia, validación) | 358–441 |
| **5 · Proyecto final** | M24 Proyecto integrador: diseño, cálculo, CAD, CFD, MEF, instrumentación, fabricación y defensa | 442–455 |

Cada 7 días hay un **día de integración** (problema real que mezcla todo lo de la semana). El plan completo, día a día, está en [`content/roadmap.yaml`](content/roadmap.yaml).

**Estado del contenido:** los 455 días tienen título y objetivo; el **módulo 1 (días 1–14)** está redactado completo: teoría, práctica guiada y 15 preguntas por día (5 por nivel, 210 en total, 135 de ellas numéricas y verificadas automáticamente). El resto se añade por bloques con el mismo formato (ver *Añadir contenido*).

## 🧠 Cómo funciona el entrenamiento

1. **Teoría del día** (~40 min) con fórmulas, ejemplos resueltos y práctica con lápiz y papel.
2. **Examen diario**: 10 preguntas del día repartidas según tu dificultad (Básico 5/3/2 · Intermedio 2/5/3 · Avanzado 1/4/5) + hasta 3 repasos de preguntas falladas en días anteriores.
3. **Algoritmo de progresión** (en `submit_exam`):
   - **≥ 80 %** → apruebas: se desbloquea el día siguiente y sumas racha.
   - **≥ 90 %** → además sube la dificultad.
   - **< 50 %** → baja la dificultad para consolidar y repites el día con preguntas nuevas.
   - Cada fallo entra en un **repaso espaciado** (Leitner: vuelve a los 1, 2, 4, 8 y 16 días).
4. **XP y rangos**: 10 XP × dificultad por acierto, +50 por aprobar. De *Aprendiz* a *Verdadero Ingeniero*.
5. **Práctica**: puedes repetir cualquier día ya superado sin afectar a tu progreso (mitad de XP).

## 🗂️ Estructura del repositorio

```
lib/                       App Flutter
  main.dart                Arranque y control de sesión
  config.dart              URL y clave pública de Supabase
  data/                    Modelos, acceso a Supabase, rangos, utilidades
  screens/                 Hoy, Lección, Examen, Resultado, Programa, Progreso, Perfil, Login
  widgets/common.dart      Componentes visuales y el renderizador Markdown + LaTeX
content/
  roadmap.yaml             Plan de 455 días (fases, módulos, títulos y objetivos)
  days/day_XXX.md          Lecciones completas con su banco de preguntas
supabase/
  00_setup_completo.sql    Instalación completa (esquema + contenido) en un solo archivo
  01_schema.sql            Tablas, seguridad RLS y funciones del servidor
  02_seed.sql              Contenido (generado)
  chunks/                  El contenido troceado por días (generado)
tools/
  build_seed.py            Valida el contenido y genera los SQL
  verify_numeric.py        Recalcula todas las respuestas numéricas
  setup_platforms.sh/.ps1  Crea las carpetas android/ios/web/windows
  test_flow.sql            Prueba completa del algoritmo de exámenes
.github/workflows/build.yml  Compila APK, web y Windows en cada push
```

## 🚀 Puesta en marcha

### Opción A · Sin instalar nada: descarga la app compilada
Cada push a `main` compila la app en GitHub. Ve a la pestaña **Actions** del repositorio → última ejecución → **Artifacts**:
- `verdadero-ingeniero-android-apk` → instálalo en tu móvil (permite "orígenes desconocidos").
- `verdadero-ingeniero-windows` → descomprime y ejecuta `verdadero_ingeniero.exe`.
- `verdadero-ingeniero-web` → súbelo a cualquier hosting estático.

### Opción B · Desarrollo en tu ordenador
1. Instala [Flutter](https://docs.flutter.dev/get-started/install) (canal estable) y, para Android, Android Studio.
2. En la carpeta del proyecto:
   ```powershell
   ./tools/setup_platforms.ps1      # Windows (PowerShell)
   bash tools/setup_platforms.sh    # macOS / Linux
   ```
3. Ejecuta: `flutter run -d windows`, `flutter run -d chrome` o con el móvil conectado `flutter run`.
4. APK para el móvil: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.

### Base de datos (Supabase)
El proyecto **verdadero-ingeniero** (región París) ya está configurado en `lib/config.dart`. Si algún día necesitas recrearlo en otro proyecto:
1. Supabase → **SQL Editor** → pega el contenido de `supabase/00_setup_completo.sql` → **Run**.
2. Cambia la URL y la clave *anon* en `lib/config.dart`.
3. Recomendado para uso personal: **Authentication → Sign In / Providers → Email → desactiva "Confirm email"**, así entras nada más registrarte.

> Las funciones `private.*` y la tabla `questions` no son accesibles desde la app: las soluciones solo salen del servidor al corregir.

## ✍️ Añadir contenido

1. Crea `content/days/day_015.md` siguiendo el formato de los existentes:
   ```markdown
   ---
   day: 15
   minutes: 60
   ---
   ## Teoría en Markdown
   Fórmulas en línea \( F = m a \) y en bloque \[ \sigma = \frac{M y}{I} \]
   <!-- PRACTICA -->
   Ejercicios con soluciones...
   <!-- PREGUNTAS -->
   ### Q d=1 mcq
   Enunciado
   - [ ] opción incorrecta
   - [x] opción correcta
   > Explicación
   ### Q d=2 num tol=1 unit="kN"
   Enunciado
   = 12.5
   > Explicación
   ```
   `d` = dificultad 1–3 (mínimo 5 preguntas por nivel), `tol` = tolerancia en %.
2. Valida y genera: `python tools/build_seed.py` (añade la fórmula de cada respuesta numérica a `tools/verify_numeric.py` y ejecútalo).
3. Carga en Supabase el archivo `supabase/chunks/dia_015.sql` (SQL Editor → Run). Es idempotente: puedes reejecutarlo al corregir algo.

## 🧪 Pruebas
- `flutter test` — lógica de la app (lectura de números, formato, rangos, modelos).
- `python tools/verify_numeric.py` — recalcula las 135 respuestas numéricas.
- `tools/test_flow.sql` — prueba de extremo a extremo del algoritmo sobre un Postgres local.

## 🛠️ Para retocar
- El renderizado de fórmulas usa el paquete `gpt_markdown`; está aislado en `MathMarkdown` (`lib/widgets/common.dart`) por si hubiera que cambiarlo.
- Umbral de aprobado: `submit_exam` en `supabase/01_schema.sql` y `AppConfig.passThreshold`.
- Número de preguntas y reparto por dificultad: `start_daily_exam` (`c_day_questions`, `v_target`).
