import 'package:firebase_auth/firebase_auth.dart';

/// Provides authentication operations wrapping [FirebaseAuth].
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream that emits the current [User] whenever the auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the currently signed-in user, or null if no user is signed in.
  User? get currentUser => _auth.currentUser;

  /// Signs in with [email] and [password].
  ///
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Creates a new account with [email] and [password].
  ///
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Translates [FirebaseAuthException] error codes into user-friendly
  /// Portuguese messages.
  static String translateError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nenhum usuário encontrado com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta. Tente novamente.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'Endereço de e-mail inválido.';
      case 'user-disabled':
        return 'Esta conta foi desabilitada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Erro de rede. Verifique sua conexão.';
      default:
        return 'Ocorreu um erro. Tente novamente.';
    }
  }
}
