import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TransacoesPage extends StatefulWidget {
  const TransacoesPage({super.key});

  @override
  State<TransacoesPage> createState() => _TransacoesPageState();
}

class _TransacoesPageState extends State<TransacoesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    if (_auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tech challenge 3'),
      ),
      body: Center(
        child: Text(
          'Transações',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}