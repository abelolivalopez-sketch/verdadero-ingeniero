import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// Acceso a Supabase. Toda la lógica de exámenes vive en el servidor (RPC):
/// el cliente nunca recibe las soluciones antes de entregar.
class Repo {
  static SupabaseClient get _c => Supabase.instance.client;

  static User? get user => _c.auth.currentUser;

  // ---------------------------------------------------------------- auth
  static Future<void> signIn(String email, String password) =>
      _c.auth.signInWithPassword(email: email, password: password);

  /// Devuelve true si la sesión queda iniciada; false si hay que confirmar el email.
  static Future<bool> signUp(String email, String password, String name) async {
    final res = await _c.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': name},
    );
    return res.session != null;
  }

  static Future<void> signOut() => _c.auth.signOut();

  // ---------------------------------------------------------------- panel
  static Future<Dashboard> dashboard() async {
    final r = await _c.rpc('get_dashboard');
    return Dashboard.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // ---------------------------------------------------------------- catálogo
  static Future<List<Phase>> phases() async {
    final r = await _c.from('phases').select().order('id');
    return (r as List).map((e) => Phase.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<List<ModuleInfo>> modules() async {
    final r = await _c.from('modules').select().order('position');
    return (r as List).map((e) => ModuleInfo.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<List<DaySummary>> days() async {
    final r = await _c
        .from('daily_content')
        .select('day_number, module_id, title, objective, is_ready')
        .order('day_number');
    return (r as List).map((e) => DaySummary.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<DayContent> day(int dayNumber) async {
    final r = await _c.from('daily_content').select().eq('day_number', dayNumber).single();
    return DayContent.fromJson(Map<String, dynamic>.from(r));
  }

  // ---------------------------------------------------------------- exámenes
  /// [day] = null → examen diario del día actual. Un día anterior → práctica.
  static Future<Exam> startExam({int? day}) async {
    final r = await _c.rpc('start_daily_exam', params: {'p_day': day});
    return Exam.fromJson(Map<String, dynamic>.from(r as Map));
  }

  static Future<ExamResult> submitExam(String examId, List<Map<String, dynamic>> answers) async {
    final r = await _c.rpc('submit_exam', params: {'p_exam_id': examId, 'p_answers': answers});
    return ExamResult.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // ---------------------------------------------------------------- progreso
  static Future<List<HistoryEntry>> history({int limit = 100}) async {
    final r = await _c
        .from('exam_history')
        .select('id, day_number, mode, score, passed, xp_earned, level_change, difficulty_level, completed_at')
        .order('started_at', ascending: false)
        .limit(limit);
    return (r as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((e) => e['completed_at'] != null)
        .map(HistoryEntry.fromJson)
        .toList();
  }

  static Future<List<ModuleStat>> moduleStats() async {
    final r = await _c.rpc('get_module_stats');
    return (r as List).map((e) => ModuleStat.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<void> updateDisplayName(String name) async {
    final uid = user?.id;
    if (uid == null) return;
    await _c.from('profiles').update({'display_name': name}).eq('id', uid);
  }

  // ---------------------------------------------------------------- errores
  /// Traduce los errores del servidor a mensajes para el usuario.
  static String friendlyError(Object e) {
    final msg = e is PostgrestException
        ? e.message
        : e is AuthException
            ? e.message
            : e.toString();
    if (msg.contains('content_pending')) {
      return 'El temario de este día todavía no está cargado. Repasa días anteriores desde el Mapa.';
    }
    if (msg.contains('day_locked')) return 'Ese día aún está bloqueado: supera primero los anteriores.';
    if (msg.contains('program_completed')) return '¡Has completado el programa entero!';
    if (msg.contains('exam_already_submitted')) return 'Este examen ya se entregó.';
    if (msg.contains('exam_not_found')) return 'No se encontró el examen. Vuelve a empezarlo.';
    if (msg.contains('Invalid login credentials')) return 'Email o contraseña incorrectos.';
    if (msg.contains('Email not confirmed')) return 'Confirma tu email (revisa tu bandeja de entrada) y vuelve a entrar.';
    if (msg.contains('User already registered')) return 'Ya existe una cuenta con ese email. Inicia sesión.';
    if (msg.contains('Password should be')) return 'La contraseña debe tener al menos 6 caracteres.';
    if (msg.contains('SocketException') || msg.contains('Failed host lookup') || msg.contains('ClientException')) {
      return 'Sin conexión con el servidor. Comprueba tu internet.';
    }
    return msg;
  }
}
