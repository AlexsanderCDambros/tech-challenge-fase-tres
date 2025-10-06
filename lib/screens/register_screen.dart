import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tech_challenge_fase_tres/routes.dart';

import '../app_colors.dart';
import '../app_spacing.dart';

class RegisterScrenn extends StatefulWidget {
  const RegisterScrenn({super.key});

  @override
  State<RegisterScrenn> createState() => _RegisterScrennState();
}

class _RegisterScrennState extends State<RegisterScrenn> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Cadastrar usuário'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
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
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirmar a senha',
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
              onPressed: _registrar,
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  _registrar() async{
    try {
      bool ehValido = _validarCampos();

      if (!ehValido) {
        setState(() {});
        return;
      }

      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.login);
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
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      _errorMessage = 'Por favor, preencha senha e a confirmação da senha.';
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _errorMessage = 'Por favor, a senha deve ser igual a confirmação da senha.';
      return false;
    }
    return true;
  }
}