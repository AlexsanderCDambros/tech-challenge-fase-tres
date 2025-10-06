import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tech_challenge_fase_tres/models/transaction_model.dart';

import 'routes.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/inicio_screen.dart';
import 'screens/transacoes_screen.dart';
import 'screens/add_edit_transaction_screen.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: Routes.login,
      routes: {
        Routes.login: (context) => const LoginScreen(),
        Routes.registro: (context) => const RegisterScrenn(),
        Routes.inicio: (context) => const InicioScreen(),
        Routes.transacoes: (context) => const TransacoesScreen(),
        '/add-transaction': (context) {
          final transaction = ModalRoute.of(context)!.settings.arguments as TransactionModel?;
          return AddEditTransactionScreen(transaction: transaction);
        },
      }
    );
  }
}