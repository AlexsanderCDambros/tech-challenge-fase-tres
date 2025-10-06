import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_item.dart';
import '../widgets/filter_bottom_sheet.dart';

class TransacoesScreen extends StatefulWidget {
  const TransacoesScreen({super.key});

  @override
  State<TransacoesScreen> createState() => _TransacoesScreenState();
}

class _TransacoesScreenState extends State<TransacoesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  
  // Filtros
  String? _selectedCategory;
  String? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Paginação
  final int _limit = 15;
  bool _hasMore = true;
  final List<TransactionModel> _transactions = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _scrollController.addListener(_onScroll);
  }

  void _checkAuth() {
    if (_auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      _loadMoreTransactions();
    }
  }

  void _loadMoreTransactions() {
    if (!_hasMore) return;
    
    // Na implementação real, você carregaria mais dados do Firestore
    // Por enquanto, vamos simular o fim dos dados após 45 itens
    if (_transactions.length >= 45) {
      setState(() {
        _hasMore = false;
      });
    }
  }

  void _applyFilters({
    String? category,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    setState(() {
      _selectedCategory = category;
      _selectedType = type;
      _startDate = startDate;
      _endDate = endDate;
      _transactions.clear();
      _hasMore = true;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedType = null;
      _startDate = null;
      _endDate = null;
      _transactions.clear();
      _hasMore = true;
    });
  }

  void _navigateToAddTransaction() {
    Navigator.pushNamed(context, '/add-transaction');
  }

  void _editTransaction(TransactionModel transaction) {
    Navigator.pushNamed(
      context, 
      '/add-transaction',
      arguments: transaction,
    );
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta transação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteTransaction(transaction.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação excluída com sucesso')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir transação: $e')),
        );
      }
    }
  }

  bool _hasActiveFilters() {
    return _selectedCategory != null || 
           _selectedType != null || 
           _startDate != null || 
           _endDate != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de filtros ativos
          if (_hasActiveFilters()) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _buildFilterSummary(),
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: _clearFilters,
                  ),
                ],
              ),
            ),
          ],
          
          // Lista de transações
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _firestoreService.getTransactions(
                category: _selectedCategory,
                type: _selectedType,
                startDate: _startDate,
                endDate: _endDate,
                limit: _limit,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingList();
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                final transactions = snapshot.data ?? [];
                _updateTransactionList(transactions);

                if (transactions.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: transactions.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == transactions.length) {
                      return _buildLoadingMore();
                    }
                    
                    final transaction = transactions[index];
                    return TransactionItem(
                      transaction: transaction,
                      onTap: () => _editTransaction(transaction),
                      onDelete: () => _deleteTransaction(transaction),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => const TransactionItemShimmer(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma transação encontrada',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Limpar filtros'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMore() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  String _buildFilterSummary() {
    final filters = <String>[];
    
    if (_selectedType != null) {
      filters.add(_selectedType == 'income' ? 'Receitas' : 'Despesas');
    }
    
    if (_selectedCategory != null) {
      filters.add('Categoria: $_selectedCategory');
    }
    
    if (_startDate != null || _endDate != null) {
      final startStr = _startDate != null 
          ? DateFormat('dd/MM/yyyy').format(_startDate!)
          : 'Início';
      final endStr = _endDate != null 
          ? DateFormat('dd/MM/yyyy').format(_endDate!)
          : 'Fim';
      filters.add('Período: $startStr - $endStr');
    }
    
    return 'Filtros: ${filters.join(', ')}';
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterBottomSheet(
        currentCategory: _selectedCategory,
        currentType: _selectedType,
        currentStartDate: _startDate,
        currentEndDate: _endDate,
        onApplyFilters: _applyFilters,
        onClearFilters: _clearFilters,
      ),
    );
  }

  void _updateTransactionList(List<TransactionModel> newTransactions) {
    // Atualiza a lista mantendo a referência para preservar o estado
    if (_transactions.length != newTransactions.length) {
      _transactions
        ..clear()
        ..addAll(newTransactions);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}