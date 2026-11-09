import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  runApp(const VerdaderoIngenieroApp());
}

class VerdaderoIngenieroApp extends StatelessWidget {
  const VerdaderoIngenieroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Verdadero Ingeniero',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AuthGate(),
    );
  }
}

/// Muestra el login o la app según haya sesión.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session == null) return const AuthScreen();
        return HomeShell(key: ValueKey(session.user.id));
      },
    );
  }
}
