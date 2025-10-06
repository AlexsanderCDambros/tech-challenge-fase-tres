import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tech_challenge_fase_tres/app_font_size.dart';
import 'package:tech_challenge_fase_tres/app_spacing.dart';
import 'package:tech_challenge_fase_tres/routes.dart';

import '../app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Entrar na aplicação',
                  style: TextStyle(
                    fontSize: AppFontSize.extraLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(
                      Icons.email
                    )
                  ),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(
                      Icons.lock
                    )
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: _entrar,
                  child: const Text('Entrar'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/registro');
                  }, 
                  child: Text('Criar uma conta')
                )
             ],
            ),
          ),
        ),
      )
    );
  }

  _entrar() async {
    try {
      bool ehValido = _validarCampos();

      if (!ehValido) {
        setState(() {});
        return;
      }

      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.inicio);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message!;
      });
    }
  }

  bool _validarCampos() {
    if (_emailController.text.isEmpty) {
      _errorMessage = 'Por favor, preencha email.';
      return false;
    }
    if (_passwordController.text.isEmpty) {
      _errorMessage = 'Por favor, preencha senha.';
      return false;
    }
    return true;
  }
}