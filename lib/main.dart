import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tech_challenge_fase_tres/register_screen.dart';

import 'inicio.dart';
import 'routes.dart';
import 'transacoes.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tech Challenge 3',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: Routes.registro,
      routes: {
        Routes.registro: (context) => RegisterScrenn(),
        Routes.inicio: (context) => InicioPage(),
        Routes.transacoes: (context) => TransacoesPage(),
      }
    );
  }
}