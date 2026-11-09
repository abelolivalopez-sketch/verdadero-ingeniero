/// Configuración de conexión con Supabase.
///
/// La clave "anon" es pública por diseño: la seguridad la garantizan las
/// políticas RLS y las funciones del servidor (las soluciones de los exámenes
/// nunca llegan al cliente antes de entregar).
///
/// Puedes sobreescribir ambos valores al compilar:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qtmlecztkaxmyjfgdgtm.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF0bWxlY3p0a2F4bXlqZmdkZ3RtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQyMTQ5NDcsImV4cCI6MjEwOTc5MDk0N30.N_9TgfTN6MU2PHuA252FAXJkXCIZ9985hz7FXwFgmCk',
  );

  /// Porcentaje mínimo para aprobar un examen (debe coincidir con el servidor).
  static const passThreshold = 80;
}
