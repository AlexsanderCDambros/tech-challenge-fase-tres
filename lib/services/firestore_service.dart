import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _userId => _auth.currentUser!.uid;

  // Transações
  CollectionReference get _transactionsRef =>
      _firestore.collection('transactions').doc(_userId).collection('user_transactions');

  // Categorias
  CollectionReference get _categoriesRef =>
      _firestore.collection('categories').doc(_userId).collection('user_categories');

  // Adicionar transação
  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionsRef.add(transaction.toMap());
  }

  // Atualizar transação
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _transactionsRef.doc(transaction.id).update(transaction.toMap());
  }

  // Deletar transação
  Future<void> deleteTransaction(String transactionId) async {
    await _transactionsRef.doc(transactionId).delete();
  }

  // Buscar transações com filtros e paginação
  Stream<List<TransactionModel>> getTransactions({
    String? category,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) {
    Query query = _transactionsRef.orderBy('date', descending: true).limit(limit);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Buscar categorias
  Stream<List<CategoryModel>> getCategories() {
    return _categoriesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Adicionar categoria padrão
  Future<void> addDefaultCategories() async {
    final defaultCategories = [
      CategoryModel(userId: _userId, name: 'Alimentação', type: 'expense', color: '#FF6B6B'),
      CategoryModel(userId: _userId, name: 'Transporte', type: 'expense', color: '#4ECDC4'),
      CategoryModel(userId: _userId, name: 'Moradia', type: 'expense', color: '#45B7D1'),
      CategoryModel(userId: _userId, name: 'Saúde', type: 'expense', color: '#96CEB4'),
      CategoryModel(userId: _userId, name: 'Lazer', type: 'expense', color: '#FFEAA7'),
      CategoryModel(userId: _userId, name: 'Salário', type: 'income', color: '#55EFC4'),
      CategoryModel(userId: _userId, name: 'Investimentos', type: 'income', color: '#74B9FF'),
      CategoryModel(userId: _userId, name: 'Freelance', type: 'income', color: '#A29BFE'),
    ];

    final existingCategories = await _categoriesRef.get();
    if (existingCategories.docs.isEmpty) {
      for (final category in defaultCategories) {
        await _categoriesRef.add(category.toMap());
      }
    }
  }
}