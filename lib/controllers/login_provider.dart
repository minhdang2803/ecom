import 'package:ecom/controllers/base_provider.dart';
import 'package:ecom/utils/shared_preference.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/exception.dart';

class LoginProvider extends BaseProvider {
  final formKey = GlobalKey<FormState>();

  bool isPop = false;
  bool isCancel = false;
  bool isPassword = true;
  bool isVarified = false;
  bool isFirstTimeCheck = true;

  final googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _user;
  GoogleSignInAccount? get user => _user;
  set setAccount(GoogleSignInAccount account) {
    _user = account;
  }

  Future loginbyGoogle() async {
    try {
      isCancel = false;
      isPop = false;
      setStatus(ViewState.loading, notify: true);
      final googleUser = await googleSignIn.signIn().catchError((error) {
        setStatus(ViewState.fail, notify: true);
        setErrorMessage('Google account is not exist', notify: true);
      });
      _user = googleUser;
      if (googleUser == null) {
        setStatus(ViewState.fail, notify: true);
        setErrorMessage('Google account is not exist', notify: true);
        return;
      } else {
        _user = googleUser;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        SharedPref.instance.setBool('isLoggedIn', true);
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      setStatus(ViewState.done, notify: true);
    } on PlatformException catch (exception) {
      setStatus(ViewState.fail, notify: true);
      if (exception.message ==
          'com.google.android.gms.common.api.ApiException: 16:') {
        setErrorMessage('No Google accounts found!', notify: true);
      } else {
        setErrorMessage(exception.message!, notify: true);
      }
    } on FirebaseAuthException catch (exception) {
      setStatus(ViewState.fail, notify: true);
      setErrorMessage(exception.code, notify: true);
    } on RemoteException catch (exception) {
      setStatus(ViewState.fail, notify: true);
      setErrorMessage(exception.errorMessage, notify: true);
    } finally {}
  }

  Future logoutGoogle() async {
    setStatus(ViewState.none, notify: true);
    FirebaseAuth.instance.signOut();

    if (FirebaseAuth.instance.currentUser != null) {
      await googleSignIn.disconnect();
    }
  }

  Future loginbyEmail({required String email, required String password}) async {
    try {
      isCancel = false;
      isPop = false;
      setStatus(ViewState.loading, notify: true);

      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      )
          .whenComplete(() async {
        SharedPref.instance.setBool('isLoggedIn', true);
      });
      if (!FirebaseAuth.instance.currentUser!.emailVerified) {
        setErrorMessage('Google account is not verified', notify: true);
        setStatus(ViewState.fail, notify: true);
        return;
      }
      setStatus(ViewState.done, notify: true);
    } on PlatformException catch (exception) {
      setStatus(ViewState.fail, notify: true);
      if (exception.message ==
          'com.google.android.gms.common.api.ApiException: 16:') {
        setErrorMessage('No Google accounts found!', notify: true);
      } else {
        setErrorMessage(exception.message!, notify: true);
      }
    } on FirebaseAuthException catch (exception) {
      setStatus(ViewState.fail, notify: true);
      setErrorMessage(exception.code, notify: true);
    } on RemoteException catch (exception) {
      setStatus(ViewState.fail, notify: true);
      setErrorMessage(exception.errorMessage, notify: true);
    } finally {}
  }
}
