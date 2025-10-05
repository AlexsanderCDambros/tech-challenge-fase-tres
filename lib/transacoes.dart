import 'package:flutter/material.dart';

class TransacoesPage extends StatelessWidget {
  const TransacoesPage({super.key});

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