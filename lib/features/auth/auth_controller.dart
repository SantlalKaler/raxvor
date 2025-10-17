import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../app/constant/string_constant.dart';
import '../../app/constants.dart';
import '../../app/providers/providers.dart';

class AuthController {
  final Ref ref;
  AuthController(this.ref);
  String? message;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      message = null;
      var value = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (value.user != null) {
        await saveUser(value.user!.email!, value.user!.uid);
      }
      message = "User created successfully";
      ref.read(authStateProvider.notifier).state = true;
      printValue(value);
      // signInSupabase();
      return null;
    } on FirebaseAuthException catch (e) {
      message = e.message;
      printValue(e);
      return e.message;
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      message = null;
      var value = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      message = "User login successfully";
      ref.read(authStateProvider.notifier).state = true;
      // signInSupabase();
      printValue(value);
      return null;
    } on FirebaseAuthException catch (e) {
      message = e.message;
      printValue(e);
      return e.message;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  Future<void> saveUser(String email, String uId) async {
    try {
      var data = await supa.Supabase.instance.client
          .from(supabaseUserTable)
          .insert({"email": email, "uid": uId})
          .select();

      printValue("Data save in supabase : ${data}");
    } catch (e) {
      printValue(e);
    }
  }
}

Future<void> signInSupabase() async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final idToken = await firebaseUser?.getIdToken();
  final response = await supa.Supabase.instance.client.auth.signInWithIdToken(
    provider: supa.OAuthProvider.google,
    idToken: idToken!,
  );

  printValue("sign in supabase : $response");
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});
