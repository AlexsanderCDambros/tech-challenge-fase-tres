import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedType = 'expense';
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();
  XFile? _selectedImage;
  String? _receiptUrl;

  bool _isLoading = false;
  bool _isEditing = false;

  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.transaction != null;

    if (_isEditing) {
      _loadTransactionData();
    }

    _loadCategories();
  }

  void _loadTransactionData() {
    final transaction = widget.transaction!;
    _descriptionController.text = transaction.description;
    _amountController.text = transaction.amount.toStringAsFixed(2);
    _selectedType = transaction.type;
    _selectedCategory = transaction.category;
    _selectedDate = transaction.date;
    _receiptUrl = transaction.receiptUrl;
  }

  void _loadCategories() {
    _firestoreService.getCategories().listen((categories) {
      setState(() {
        _categories = categories;
        if (_categories.isNotEmpty && _selectedCategory.isEmpty) {
          _selectedCategory =
              _categories.where((cat) => cat.type == _selectedType).first.name;
        }
      });
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _storageService.pickImage();
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      _showError('Erro ao selecionar imagem: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _receiptUrl;

    setState(() => _isLoading = true);
    try {
      final url = await _storageService.uploadReceipt(_selectedImage!);
      return url;
    } catch (e) {
      _showError('Erro ao fazer upload do comprovante: $e');
      return null;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;

    if (_selectedCategory.isEmpty) {
      _showError('Por favor, selecione uma categoria');
      return false;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Por favor, insira um valor válido');
      return false;
    }

    return true;
  }

  Future<void> _saveTransaction() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      // Upload do comprovante se houver imagem selecionada
      final receiptUrl = await _uploadImage();
      if (_selectedImage != null && receiptUrl == null) {
        return; // Upload falhou
      }

      final transaction = TransactionModel(
        id: _isEditing ? widget.transaction!.id : null,
        userId: _auth.currentUser!.uid,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        date: _selectedDate,
        type: _selectedType,
        receiptUrl: receiptUrl,
      );

      if (_isEditing) {
        await _firestoreService.updateTransaction(transaction);
      } else {
        await _firestoreService.addTransaction(transaction);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Transação atualizada com sucesso!'
              : 'Transação adicionada com sucesso!'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showError('Erro ao salvar transação: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _removeReceipt() {
    setState(() {
      _selectedImage = null;
      _receiptUrl = null;
    });
  }

  List<CategoryModel> _getFilteredCategories() {
    return _categories.where((cat) => cat.type == _selectedType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Transação' : 'Nova Transação'),
        actions: [
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteTransaction,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Tipo de Transação
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tipo de Transação',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTypeButton(
                                    'Despesa',
                                    'expense',
                                    Icons.arrow_downward,
                                    Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTypeButton(
                                    'Receita',
                                    'income',
                                    Icons.arrow_upward,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Descrição
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira uma descrição';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Valor
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Valor (R\$)',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um valor';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Por favor, insira um valor válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Categoria
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Categoria',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_getFilteredCategories().isEmpty)
                              const Text('Nenhuma categoria disponível'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _getFilteredCategories().map((category) {
                                return FilterChip(
                                  label: Text(category.name),
                                  selected: _selectedCategory == category.name,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category.name;
                                    });
                                  },
                                  backgroundColor: Colors.grey[200],
                                  selectedColor: Colors.blue[100],
                                  checkmarkColor: Colors.blue,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Data
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Data',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _selectDate,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 8),
                                  Text(DateFormat('dd/MM/yyyy')
                                      .format(_selectedDate)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Comprovante
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Comprovante',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_receiptUrl != null || _selectedImage != null)
                              _buildReceiptPreview(),
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Anexar Comprovante'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedType == 'income'
                              ? Colors.green
                              : Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(
                                _isEditing
                                    ? 'Atualizar Transação'
                                    : 'Adicionar Transação',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeButton(
      String label, String type, IconData icon, Color color) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedType = type;
          // Reset category when type changes
          final filtered = _getFilteredCategories();
          if (filtered.isNotEmpty) {
            _selectedCategory = filtered.first.name;
          }
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: _selectedType == type ? color.withOpacity(0.1) : null,
        side: BorderSide(
          color: _selectedType == type ? color : Colors.grey,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _selectedType == type ? color : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: _selectedType == type ? color : Colors.grey,
              fontWeight:
                  _selectedType == type ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedImage?.name ?? 'Comprovante anexado',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_selectedImage != null)
                  FutureBuilder<String>(
                    future: _getFileSizeString(_selectedImage!),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          snapshot.data!,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      }
                      return const Text(
                        'Calculando...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    },
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _removeReceipt,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction() async {
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
      setState(() => _isLoading = true);
      try {
        await _firestoreService.deleteTransaction(widget.transaction!.id!);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação excluída com sucesso')),
        );
        Navigator.pop(context);
      } catch (e) {
        _showError('Erro ao excluir transação: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<String> _getFileSizeString(XFile file) async {
    try {
      final length = await file.length();
      final sizeInKB = length / 1024;
      return '${sizeInKB.toStringAsFixed(1)} KB';
    } catch (e) {
      return 'Tamanho indisponível';
    }
  }
}
