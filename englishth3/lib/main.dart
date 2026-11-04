import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/firebase_options.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'views/auth/login_screen.dart';
import 'views/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Main] Firebase Core khởi tạo thành công!');
  } catch (e) {
    debugPrint('[Main Warning] Lỗi khởi tạo Firebase (chạy chế độ fallback): $e');
  }

  // 2. Khởi tạo Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    debugPrint('[Main] Supabase khởi tạo thành công!');
  } catch (e) {
    debugPrint('[Main Warning] Lỗi khởi tạo Supabase: $e');
  }

  // 3. Khởi tạo Thông Báo Nhắc Nhở Hàng Ngày
  await NotificationService().init();

  runApp(const EnglishTH3App());
}

class EnglishTH3App extends StatefulWidget {
  const EnglishTH3App({super.key});

  @override
  State<EnglishTH3App> createState() => _EnglishTH3AppState();
}

class _EnglishTH3AppState extends State<EnglishTH3App> {
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _auth.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English AI TH3',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          primary: const Color(0xFF4F46E5),
        ),
        useMaterial3: true,
        fontFamily: 'Segoe UI',
      ),
      home: _auth.isAuthenticated
          ? DashboardScreen(onLogout: () => setState(() {}))
          : LoginScreen(onLoginSuccess: () => setState(() {})),
    );
  }
}
