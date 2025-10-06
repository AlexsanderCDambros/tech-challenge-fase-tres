import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    if (_auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      });
    } else {
      _firestoreService.addDefaultCategories();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Financeiro'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final transactions = snapshot.data ?? [];
          final chartData = _prepareChartData(transactions);
          final summary = _calculateSummary(transactions);

          return AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, (1 - _fadeAnimation.value) * 20),
                  child: child,
                ),
              );
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resumo Financeiro
                  _buildFinancialSummary(summary),
                  const SizedBox(height: 24),
                  
                  // Gráfico de Despesas por Categoria
                  _buildCategoryChart(chartData['expense'] ?? []),
                  const SizedBox(height: 24),
                  
                  // Gráfico de Barras - Receitas vs Despesas
                  _buildBarChart(transactions),
                  const SizedBox(height: 24),
                  
                  // Últimas Transações
                  _buildRecentTransactions(transactions),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando dashboard...'),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(Map<String, double> summary) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Resumo Financeiro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Receitas', summary['income'] ?? 0, Colors.green),
                _buildSummaryItem('Despesas', summary['expense'] ?? 0, Colors.red),
                _buildSummaryItem('Saldo', summary['balance'] ?? 0, 
                    summary['balance']! >= 0 ? Colors.blue : Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, double value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          'R\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart(List<ChartData> data) {
    final total = data.fold(0.0, (sum, item) => sum + item.y);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Despesas por Categoria',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (data.isEmpty)
              const Text('Nenhuma despesa registrada'),
              
            ...data.map((item) => _buildCategoryItem(item, total)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(ChartData data, double total) {
    final percentage = total > 0 ? (data.y / total * 100) : 0;
    final color = _getCategoryColor(data.x);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.x,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                'R\$${data.y.toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 8,
                child: LinearProgressIndicator(
                  value: total > 0 ? data.y / total : 0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<TransactionModel> transactions) {
    final monthlyData = _prepareMonthlyData(transactions);
    final maxValue = monthlyData.fold(0.0, (max, item) => 
      item.income > max ? item.income : (item.expense > max ? item.expense : max)
    );

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receitas vs Despesas (Mensal)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthlyData.map((data) => 
                  _buildBarChartItem(data, maxValue)
                ).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: monthlyData.map((data) => 
                SizedBox(
                  width: 40,
                  child: Text(
                    data.month,
                    style: TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                )
              ).toList(),
            ),
            const SizedBox(height: 16),
            _buildChartLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartItem(MonthlyData data, double maxValue) {
    final incomeHeight = maxValue > 0 ? (data.income / maxValue * 120) : 0;
    final expenseHeight = maxValue > 0 ? (data.expense / maxValue * 120) : 0;
    
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Barra de receitas
              Container(
                width: 12,
                height: incomeHeight.toDouble(),
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Barra de despesas
              Container(
                width: 12,
                height: expenseHeight.toDouble(),
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'R\$${data.income.toInt()}',
            style: TextStyle(fontSize: 8, color: Colors.green),
          ),
          Text(
            'R\$${data.expense.toInt()}',
            style: TextStyle(fontSize: 8, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Receitas', Colors.green),
        const SizedBox(width: 16),
        _buildLegendItem('Despesas', Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(List<TransactionModel> transactions) {
    final recentTransactions = transactions.take(5).toList();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Últimas Transações',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (transactions.length > 5)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/transacoes');
                    },
                    child: const Text('Ver Todas'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (recentTransactions.isEmpty)
              const Center(
                child: Text(
                  'Nenhuma transação recente',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              
            ...recentTransactions.map((transaction) => 
              _buildTransactionItem(transaction)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: transaction.type == 'income' 
                  ? Colors.green.withOpacity(0.1) 
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              transaction.type == 'income' 
                  ? Icons.arrow_upward 
                  : Icons.arrow_downward,
              color: transaction.type == 'income' ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${transaction.category} • ${DateFormat('dd/MM/yyyy').format(transaction.date)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'R\$${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: transaction.type == 'income' ? Colors.green : Colors.red,
                  fontSize: 14,
                ),
              ),
              Text(
                transaction.type == 'income' ? 'Receita' : 'Despesa',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    
    final index = category.hashCode % colors.length;
    return colors[index];
  }

  Map<String, List<ChartData>> _prepareChartData(List<TransactionModel> transactions) {
    final expenseByCategory = <String, double>{};
    
    for (final transaction in transactions) {
      if (transaction.type == 'expense') {
        expenseByCategory[transaction.category] = 
            (expenseByCategory[transaction.category] ?? 0) + transaction.amount;
      }
    }
    
    final expenseData = expenseByCategory.entries
        .map((entry) => ChartData(entry.key, entry.value))
        .toList();

    return {'expense': expenseData};
  }

  Map<String, double> _calculateSummary(List<TransactionModel> transactions) {
    double income = 0;
    double expense = 0;
    
    for (final transaction in transactions) {
      if (transaction.type == 'income') {
        income += transaction.amount;
      } else {
        expense += transaction.amount;
      }
    }
    
    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  List<MonthlyData> _prepareMonthlyData(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final monthlyData = <MonthlyData>[];
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthKey = DateFormat('MMM').format(month);
      
      double monthlyIncome = 0;
      double monthlyExpense = 0;
      
      for (final transaction in transactions) {
        if (transaction.date.year == month.year && transaction.date.month == month.month) {
          if (transaction.type == 'income') {
            monthlyIncome += transaction.amount;
          } else {
            monthlyExpense += transaction.amount;
          }
        }
      }
      
      monthlyData.add(MonthlyData(monthKey, monthlyIncome, monthlyExpense));
    }
    
    return monthlyData;
  }
}

// Classes auxiliares para os gráficos
class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}

class MonthlyData {
  final String month;
  final double income;
  final double expense;

  MonthlyData(this.month, this.income, this.expense);
}