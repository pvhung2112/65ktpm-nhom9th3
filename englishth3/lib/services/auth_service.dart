import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, String>? _mockUser;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null || _mockUser != null;

  String get userUid => _mockUser != null ? _mockUser!['uid']! : (_auth.currentUser?.uid ?? 'guest_uid');
  String get userEmail => _mockUser != null ? _mockUser!['email']! : (_auth.currentUser?.email ?? 'guest@english.edu.vn');
  String get userDisplayName =>
      _mockUser != null ? _mockUser!['name']! : (_auth.currentUser?.displayName ?? (_auth.currentUser?.email?.split('@').first ?? 'Học viên'));

  /// Đăng nhập bằng Email & Mật khẩu qua Firebase (bắt buộc đúng 100% email & mật khẩu)
  Future<String?> signIn(String email, String password) async {
    _mockUser = null;
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      final code = e.code.toLowerCase();
      final msg = (e.message ?? '').toLowerCase();
      if (code.contains('user-not-found')) {
        return 'Tài khoản không tồn tại. Vui lòng bấm "Chưa có tài khoản? Đăng ký mới" bên dưới!';
      } else if (code.contains('wrong-password') ||
          code.contains('invalid-credential') ||
          msg.contains('credential') ||
          msg.contains('password')) {
        return 'Mật khẩu không chính xác! Mật khẩu mẫu là "123456". Hãy bấm icon con mắt để kiểm tra xem bạn có gõ nhầm không, hoặc bấm "Đăng ký mới" bên dưới.';
      } else if (code.contains('invalid-email')) {
        return 'Định dạng email không hợp lệ!';
      }
      return e.message ?? 'Đăng nhập thất bại';
    } catch (e) {
      return e.toString();
    }
  }

  /// Đăng ký tài khoản mới qua Firebase
  Future<String?> signUp(String email, String password, String displayName) async {
    _mockUser = null;
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await cred.user?.updateDisplayName(displayName.trim());
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Email này đã được đăng ký. Vui lòng chuyển sang Đăng nhập!';
      } else if (e.code == 'weak-password') {
        return 'Mật khẩu quá ngắn, vui lòng nhập ít nhất 6 ký tự!';
      }
      return e.message ?? 'Đăng ký thất bại';
    } catch (e) {
      return e.toString();
    }
  }

  /// Đổi user kiểm thử trong Testing Lab (dành cho mục 7 nghiệm thu)
  void switchMockAccount(String uid, String name, String email) {
    _mockUser = {
      'uid': uid,
      'name': name,
      'email': email,
    };
    notifyListeners();
  }

  /// Đăng xuất
  Future<void> signOut() async {
    _mockUser = null;
    await _auth.signOut();
    notifyListeners();
  }
}
