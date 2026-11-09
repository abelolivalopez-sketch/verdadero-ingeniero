# ⚙️ Verdadero Ingeniero

App de entrenamiento diario para convertirte en un ingeniero mecánico completo, con especialización aeronáutica (mecánica de fluidos y CFD). **Dos horas al día, un examen al día**: el sistema adapta la dificultad a tus resultados y no te deja avanzar hasta que dominas el día.

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

**Estado del contenido:** los 455 días tienen título y objetivo; el **módulo 1 (días 1–14)** está redactado completo: teoría, taller práctico con Python, práctica y 21 preguntas por día (7 por nivel: 294 en total, 189 numéricas verificadas automáticamente; los 14 programas de los talleres se ejecutan en cada push). El resto se añade por bloques con el mismo formato (ver *Añadir contenido*).

## 🧠 Cómo funciona el entrenamiento

1. **Teoría del día** (~45 min) con fórmulas y ejemplos resueltos.
2. **Taller práctico** (~45 min): un cálculo real resuelto paso a paso con su método, el mismo cálculo programado en Python (desde el día 1, sin instalar nada: Google Colab) o en tu CAD, y un reto.
3. **Práctica** con lápiz y papel (~15 min).
4. **Examen diario** (~20 min): 15 preguntas del día repartidas según tu dificultad (Básico 7/5/3 · Intermedio 4/7/4 · Avanzado 3/5/7) + hasta 5 repasos de preguntas falladas en días anteriores.
5. **Algoritmo de progresión** (en `submit_exam`):
   - **≥ 80 %** → apruebas: se desbloquea el día siguiente y sumas racha.
   - **≥ 90 %** → además sube la dificultad.
   - **< 50 %** → baja la dificultad para consolidar y repites el día con preguntas nuevas.
   - Cada fallo entra en un **repaso espaciado** (Leitner: vuelve a los 1, 2, 4, 8 y 16 días).
6. **XP y rangos**: 10 XP × dificultad por acierto, +50 por aprobar. De *Aprendiz* a *Verdadero Ingeniero* (nivel L con 80·(L−1)² XP).
7. **Práctica**: puedes repetir cualquier día ya superado sin afectar a tu progreso (mitad de XP).

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
  chunks/                  El contenido troceado por días en SQL (generado)
  json/                    El contenido en JSON que Supabase descarga de GitHub (generado)
tools/
  build_seed.py            Valida el contenido y genera los SQL
  verify_numeric.py        Recalcula todas las respuestas numéricas
  run_workshop_code.py     Ejecuta todo el código Python de los talleres
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
   minutes: 120
   ---
   ## Teoría en Markdown
   Fórmulas en línea \( F = m a \) y en bloque \[ \sigma = \frac{M y}{I} \]
   <!-- TALLER -->
   Método paso a paso, código Python en bloques ```python y reto
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
   `d` = dificultad 1–3 (mínimo 7 preguntas por nivel), `tol` = tolerancia en %.
2. Valida y genera: `python tools/build_seed.py`, `python tools/verify_numeric.py` (añade ahí la fórmula de cada respuesta numérica) y `python tools/run_workshop_code.py`.
3. Haz commit y push a `main`.
4. En Supabase → SQL Editor ejecuta: `select private.sync_from_github();` — descarga de GitHub todo el contenido publicado y lo carga. Es idempotente.
   (Si algún día el repositorio pasa a privado, usa en su lugar los archivos `supabase/chunks/*.sql`).

## 🧪 Pruebas
- `flutter test` — lógica de la app (lectura de números, formato, rangos, modelos).
- `python tools/verify_numeric.py` — recalcula las 189 respuestas numéricas.
- `python tools/run_workshop_code.py` — ejecuta el código de todos los talleres.
- `tools/test_flow.sql` — prueba de extremo a extremo del algoritmo sobre un Postgres local.

## 🛠️ Para retocar
- El renderizado de fórmulas usa el paquete `gpt_markdown`; está aislado en `MathMarkdown` (`lib/widgets/common.dart`) por si hubiera que cambiarlo.
- Umbral de aprobado: `submit_exam` en `supabase/01_schema.sql` y `AppConfig.passThreshold`.
- Número de preguntas, repasos y reparto por dificultad: `start_daily_exam` (`c_day_questions`, `c_max_review`, `v_target`).
