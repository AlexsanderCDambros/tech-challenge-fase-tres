import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? currentCategory;
  final String? currentType;
  final DateTime? currentStartDate;
  final DateTime? currentEndDate;
  final Function({
    String? category,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) onApplyFilters;
  final VoidCallback onClearFilters;

  const FilterBottomSheet({
    super.key,
    this.currentCategory,
    this.currentType,
    this.currentStartDate,
    this.currentEndDate,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedCategory;
  String? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _categories = [
    'Alimentação', 'Transporte', 'Moradia', 'Saúde', 'Lazer', 
    'Salário', 'Investimentos', 'Freelance'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.currentCategory;
    _selectedType = widget.currentType;
    _startDate = widget.currentStartDate;
    _endDate = widget.currentEndDate;
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _applyFilters() {
    widget.onApplyFilters(
      category: _selectedCategory,
      type: _selectedType,
      startDate: _startDate,
      endDate: _endDate,
    );
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedType = null;
      _startDate = null;
      _endDate = null;
    });
    widget.onClearFilters();
    Navigator.pop(context);
  }

  bool get _hasChanges {
    return _selectedCategory != widget.currentCategory ||
           _selectedType != widget.currentType ||
           _startDate != widget.currentStartDate ||
           _endDate != widget.currentEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Filtrar Transações',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Tipo de Transação
          const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: const Text('Todas'),
                  selected: _selectedType == null,
                  onSelected: (selected) {
                    setState(() => _selectedType = null);
                  },
                ),
              ),
              Expanded(
                child: FilterChip(
                  label: const Text('Receitas'),
                  selected: _selectedType == 'income',
                  onSelected: (selected) {
                    setState(() => _selectedType = 'income');
                  },
                ),
              ),
              Expanded(
                child: FilterChip(
                  label: const Text('Despesas'),
                  selected: _selectedType == 'expense',
                  onSelected: (selected) {
                    setState(() => _selectedType = 'expense');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Categoria
          const Text('Categoria:', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              return FilterChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          // Período
          const Text('Período:', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _selectStartDate,
                  child: Text(
                    _startDate != null
                        ? DateFormat('dd/MM/yyyy').format(_startDate!)
                        : 'Data Inicial',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _selectEndDate,
                  child: Text(
                    _endDate != null
                        ? DateFormat('dd/MM/yyyy').format(_endDate!)
                        : 'Data Final',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _hasChanges ? _applyFilters : null,
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}