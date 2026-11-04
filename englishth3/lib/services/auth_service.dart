import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null || _mockUser != null;

  // Hỗ trợ Mock User phục vụ chấm điểm & kiểm thử tức thì (Checklist 7)
  Map<String, String>? _mockUser;
  Map<String, String>? get mockUser => _mockUser;

  String get userUid => _mockUser != null ? _mockUser!['uid']! : (_auth.currentUser?.uid ?? 'guest_uid');
  String get userEmail => _mockUser != null ? _mockUser!['email']! : (_auth.currentUser?.email ?? 'hocvien@english.edu.vn');
  String get userDisplayName => _mockUser != null ? _mockUser!['name']! : (_auth.currentUser?.displayName ?? 'Học viên');

  /// Đăng nhập bằng Email & Mật khẩu qua Firebase
  Future<String?> signIn(String email, String password) async {
    try {
      _mockUser = null;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Đăng nhập thất bại';
    } catch (e) {
      return e.toString();
    }
  }

  /// Đăng ký tài khoản mới qua Firebase
  Future<String?> signUp(String email, String password, String displayName) async {
    try {
      _mockUser = null;
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(displayName);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Đăng ký thất bại';
    } catch (e) {
      return e.toString();
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    _mockUser = null;
    await _auth.signOut();
    notifyListeners();
  }

  /// Chuyển đổi nhanh các tài khoản kiểm thử mẫu (Checklist 7)
  void switchMockAccount(String uid, String name, String email) {
    _mockUser = {
      'uid': uid,
      'name': name,
      'email': email,
    };
    notifyListeners();
  }
}

