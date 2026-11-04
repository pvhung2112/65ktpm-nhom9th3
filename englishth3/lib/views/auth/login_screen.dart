import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'student@english.edu.vn');
  final _passCtrl = TextEditingController(text: '123456');
  final _nameCtrl = TextEditingController(text: 'Nguyễn Văn An');
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  final AuthService _auth = AuthService();

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? error;
    if (_isSignUp) {
      error = await _auth.signUp(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
        _nameCtrl.text.trim(),
      );
    } else {
      error = await _auth.signIn(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    if (error == null) {
      widget.onLoginSuccess();
    } else {
      setState(() => _errorMessage = error);
    }
  }

  void _loginQuickAccount(String uid, String name, String email) {
    _auth.switchMockAccount(uid, name, email);
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo & Tiêu đề
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.record_voice_over, size: 48, color: Color(0xFF4F46E5)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ENGLISH AI TH3',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Luyện phát âm AI & Rèn luyện kỷ luật Streak',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),

                    if (_isSignUp) ...[
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Họ và tên',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _isSignUp ? 'ĐĂNG KÝ TÀI KHOẢN' : 'ĐĂNG NHẬP (FIREBASE)',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp ? 'Đã có tài khoản? Đăng nhập ngay' : 'Chưa có tài khoản? Đăng ký mới',
                        style: const TextStyle(color: Color(0xFF4F46E5)),
                      ),
                    ),

                    const Divider(height: 32),

                    // Đăng nhập nhanh tài khoản kiểm thử (Checklist 7)
                    const Text(
                      'Tài khoản kiểm thử nghiệm thu (Checklist 7):',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ActionChip(
                          avatar: const Text('🔥1'),
                          label: const Text('Nguyễn An (Mới)'),
                          onPressed: () => _loginQuickAccount('user_an_01', 'Nguyễn Văn An', 'an@test.com'),
                        ),
                        ActionChip(
                          avatar: const Text('🔥7'),
                          label: const Text('Trần Bình (7 ngày)'),
                          onPressed: () => _loginQuickAccount('user_binh_02', 'Trần Thị Bình', 'binh@test.com'),
                        ),
                        ActionChip(
                          avatar: const Text('🔥21'),
                          label: const Text('Lê Cường (21 ngày)'),
                          onPressed: () => _loginQuickAccount('user_cuong_03', 'Lê Hoàng Cường', 'cuong@test.com'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
