import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleSignInInitialization;
  static const _googleServerClientId =
      '1038782973898-gfdrfai5944kg84lq7soonlpvppgikr6.apps.googleusercontent.com';

  Future<void> signUp({required String email, required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageForCode(error.code));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageForCode(error.code));
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageForCode(error.code));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _googleSignInInitialization ??= _googleSignIn.initialize(
        serverClientId: _googleServerClientId,
      );
      await _googleSignInInitialization;

      final googleUser = await _googleSignIn.authenticate();
      final googleAuthentication = googleUser.authentication;
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(['email']);

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuthentication.idToken,
        accessToken: authorization?.accessToken,
      );
      await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_messageForCode(error.code));
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthServiceException('ยกเลิกการเข้าสู่ระบบด้วย Google');
      }
      throw AuthServiceException(
        'ไม่สามารถเข้าสู่ระบบด้วย Google ได้ '
        '(${error.code.name}: ${error.description ?? 'ไม่มีรายละเอียดจาก Google'})',
      );
    }
  }

  String _messageForCode(String code) {
    return switch (code) {
      'email-already-in-use' => 'อีเมลนี้มีบัญชีผู้ใช้แล้ว',
      'invalid-email' => 'รูปแบบอีเมลไม่ถูกต้อง',
      'weak-password' => 'รหัสผ่านไม่ปลอดภัย กรุณาตั้งรหัสผ่านที่คาดเดายากขึ้น',
      'user-not-found' => 'ไม่พบบัญชีผู้ใช้นี้',
      'wrong-password' => 'รหัสผ่านไม่ถูกต้อง',
      'invalid-credential' => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
      'account-exists-with-different-credential' =>
        'อีเมลนี้มีบัญชีที่ใช้วิธีเข้าสู่ระบบอื่นอยู่แล้ว',
      'user-disabled' => 'บัญชีนี้ถูกระงับการใช้งาน',
      'operation-not-allowed' => 'ยังไม่ได้เปิดใช้งานวิธีเข้าสู่ระบบนี้',
      'web-context-cancelled' => 'ยกเลิกการยืนยันตัวตนกับ Google',
      'web-storage-unsupported' =>
        'อุปกรณ์หรือแอปนี้ไม่รองรับพื้นที่จัดเก็บที่จำเป็นสำหรับ Google Sign-In',
      'too-many-requests' =>
        'มีการลองเข้าสู่ระบบหลายครั้งเกินไป กรุณารอสักครู่แล้วลองใหม่',
      'network-request-failed' => 'เชื่อมต่อไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต',
      'requires-recent-login' => 'กรุณาเข้าสู่ระบบใหม่แล้วลองอีกครั้ง',
      _ =>
        'เกิดข้อผิดพลาดในการยืนยันตัวตน (รหัส: $code) กรุณาตรวจสอบการตั้งค่าแล้วลองใหม่',
    };
  }
}
