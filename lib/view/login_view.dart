// lib/view/login_view.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_view.dart';
import '../main.dart';
import 'password_reset_view.dart';

class SignInView extends StatefulWidget {
  @override
  _SignInViewState createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String _errorMessage = '';

  Future<void> _signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Navigate to home if successful
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DiaryLogWrapper()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        final regex = RegExp(r'\[([^)]+)\]');
        final match = regex.firstMatch(e.message ?? '');
        String extractedError = match?.group(1) ?? 'Invalid email';

        // Making the first letter uppercase and the rest lowercase,
        // and replacing underscores with spaces
        _errorMessage = extractedError.toLowerCase().replaceAll('_', ' ');
        _errorMessage =
            _errorMessage[0].toUpperCase() + _errorMessage.substring(1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _signIn,
              child: const Text('Sign In'),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_errorMessage,
                    style: const TextStyle(color: Colors.black)),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => SignUpView()),
                );
              },
              child: const Text('Don’t have an account? Sign up'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PasswordResetView()),
                );
              },
              child: const Text('Forgot Password? Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
