import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:moneyrol/constants/app_constants.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/model/transation_model.dart';
import '../model/company_model.dart';
import '../model/currency_model.dart';
import '../../constants/hive_constants.dart';

class DashboardController extends GetxController {
  // ==================== Hive Box Instances ====================
  final Box<Company> _companyBox = Hive.box<Company>(HiveConstants.companyBox);
  final Box<Transaction> _transactionBox = Hive.box<Transaction>(
    HiveConstants.transactionBox,
  );
  final Box<CompanyTransaction> _companyTransactionBox =
      Hive.box<CompanyTransaction>(HiveConstants.companyTransactionBox);
  final Box<Currency> _currencyBox = Hive.box<Currency>(
    HiveConstants.currencyBox,
  );
  final Box _settingsBox = Hive.box(HiveConstants.settingsBox);

  // ==================== Observable Variables ====================
  final RxList<Company> companies = <Company>[].obs;
  final RxList<Transaction> transactions = <Transaction>[].obs;
  final RxList<CompanyTransaction> companyTransactions =
      <CompanyTransaction>[].obs;
  final RxDouble totalAmount = 0.0.obs;
  final Rx<Currency> selectedCurrency = Currency(
    symbol: '₹',
    code: 'INR',
    name: 'Indian Rupee',
    imagePath: 'assets/images/rupee.png',
  ).obs;
  final RxString selectedCompanyId = 'all'.obs;

  // ==================== Constants & Configuration ====================
  List<Currency> availableCurrencies = [
    Currency(
      symbol: '₹',
      code: 'INR',
      name: 'Indian Rupee',
      imagePath: 'assets/images/rupee.png',
    ),
    Currency(
      symbol: '\$',
      code: 'USD',
      name: 'US Dollar',
      imagePath: 'assets/images/dollar.png',
    ),
    Currency(
      symbol: 'د.إ',
      code: 'AED',
      name: 'UAE Dirham',
      imagePath: 'assets/images/dirham.png',
    ),
    Currency(
      symbol: '€',
      code: 'EUR',
      name: 'Euro',
      imagePath: 'assets/images/euro.png',
    ),
    Currency(
      symbol: '£',
      code: 'GBP',
      name: 'British Pound',
      imagePath: 'assets/images/pound.png',
    ),
  ];

  // ==================== Lifecycle Methods ====================
  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  void _initializeApp() {
    _initializeCurrency();
    _loadAllData();
    _calculateTotalAmount();
  }

  // ==================== Currency Management ====================
  void _initializeCurrency() {
    final savedCurrency = _currencyBox.get('selected_currency');
    if (savedCurrency != null) {
      selectedCurrency.value = savedCurrency;
    } else {
      _setDefaultCurrency();
    }
  }

  void _setDefaultCurrency() {
    selectedCurrency.value = availableCurrencies[0];
    _currencyBox.put('selected_currency', availableCurrencies[0]);
  }

  Future<void> changeCurrency(Currency newCurrency) async {
    selectedCurrency.value = newCurrency;
    await _currencyBox.put('selected_currency', newCurrency);
    update();
  }

  String get currencySymbol => selectedCurrency.value.symbol;

  String formatAmount(double amount) {
    return '${selectedCurrency.value.symbol}${amount.toStringAsFixed(2)}';
  }

  // ==================== Data Loading Methods ====================
  void _loadAllData() {
    companies.value = _companyBox.values.toList();
    transactions.value = _transactionBox.values.toList();
    companyTransactions.value = _companyTransactionBox.values.toList();
  }

  void _calculateTotalAmount() {
    double total = 0;

    // Add normal transactions
    for (var transaction in transactions) {
      total += transaction.amount;
    }

    // Add company transactions
    for (var ct in companyTransactions) {
      if (ct.type == TransactionType.received) {
        total += ct.amount;
      } else {
        total -= ct.amount;
      }
    }

    totalAmount.value = total;
  }

  void refreshData() {
    _loadAllData();
    _calculateTotalAmount();
    update();
  }

  // ==================== Transaction CRUD Operations ====================
  Future<void> addTransaction({
    required double amount,
    required DateTime date,
    String? description,
    String? source,
    bool isCash = true,
    String? referenceNumber,
  }) async {
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      date: date,
      description: description,
      source: source,
      isCash: isCash,
      referenceNumber: referenceNumber,
    );

    await _transactionBox.put(transaction.id, transaction);
    transactions.add(transaction);
    _calculateTotalAmount();
    _showSuccessSnackbar('Transaction added successfully');
  }

  Future<void> editTransaction({
    required String id,
    required double amount,
    required DateTime date,
    String? description,
    String? source,
    bool isCash = true,
    String? referenceNumber,
  }) async {
    final transaction = Transaction(
      id: id,
      amount: amount,
      date: date,
      description: description,
      source: source,
      isCash: isCash,
      referenceNumber: referenceNumber,
    );

    await _transactionBox.put(id, transaction);
    _updateTransactionInList(transaction);
    _calculateTotalAmount();
    _showSuccessSnackbar('Transaction updated successfully');
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionBox.delete(id);
    transactions.removeWhere((t) => t.id == id);
    _calculateTotalAmount();
  }

  void _updateTransactionInList(Transaction transaction) {
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;
    }
  }

  // ==================== Company CRUD Operations ====================
  Future<void> addCompany({
    required String name,
    String? description,
    String? contactPerson,
    String? phoneNumber,
  }) async {
    final company = Company(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      contactPerson: contactPerson,
      phoneNumber: phoneNumber,
    );

    await _companyBox.put(company.id, company);
    companies.add(company);
    _showSuccessSnackbar('Company added successfully');
  }

  // ==================== Company Transaction CRUD Operations ====================

  Future<void> editCompanyTransaction({
    required String id,
    required String companyId,
    required double amount,
    required DateTime date,
    DateTime? deadline,
    required TransactionType type,
    String? description,
    String? invoiceNumber,
    String? paymentMethod,
  }) async {
    final company = _companyBox.get(companyId);
    if (company == null) {
      _showErrorSnackbar('Company not found');
      return;
    }

    final transaction = CompanyTransaction(
      id: id,
      companyId: companyId,
      companyName: company.name,
      amount: amount,
      date: date,
      deadLine: deadline,
      type: type,
      description: description,
      invoiceNumber: invoiceNumber,
      paymentMethod: paymentMethod,
    );

    await _companyTransactionBox.put(id, transaction);
    _updateCompanyTransactionInList(transaction);
    _calculateTotalAmount();
    _showCompanyTransactionSuccessSnackbar(type, company.name, isUpdate: true);
  }

  Future<void> deleteCompanyTransaction(String id) async {
    await _companyTransactionBox.delete(id);
    companyTransactions.removeWhere((ct) => ct.id == id);
    _calculateTotalAmount();
  }

  void _updateCompanyTransactionInList(CompanyTransaction transaction) {
    final index = companyTransactions.indexWhere(
      (ct) => ct.id == transaction.id,
    );
    if (index != -1) {
      companyTransactions[index] = transaction;
    }
  }

  // ==================== Filter Methods ====================
  List<CompanyTransaction> getFilteredCompanyTransactions() {
    if (selectedCompanyId.value == 'normal') return [];

    final allCompanyTransactions = companyTransactions.toList();

    if (selectedCompanyId.value == 'all') {
      allCompanyTransactions.sort((a, b) => b.date.compareTo(a.date));
      return allCompanyTransactions;
    }

    final filtered = allCompanyTransactions
        .where((ct) => ct.companyId == selectedCompanyId.value)
        .toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  List<Transaction> getFilteredNormalTransactions() {
    if (selectedCompanyId.value == 'normal') {
      final normalTransactions = transactions.toList();
      normalTransactions.sort((a, b) => b.date.compareTo(a.date));
      return normalTransactions;
    }
    return [];
  }

  double getSelectedTotalReceived() {
    if (selectedCompanyId.value == 'normal') {
      return transactions.fold(0.0, (sum, t) => sum + t.amount);
    }

    final targetTransactions = selectedCompanyId.value == 'all'
        ? companyTransactions
        : companyTransactions.where(
            (ct) => ct.companyId == selectedCompanyId.value,
          );

    return targetTransactions
        .where((ct) => ct.type == TransactionType.received)
        .fold(0.0, (sum, ct) => sum + ct.amount);
  }

  double getSelectedTotalSent() {
    if (selectedCompanyId.value == 'normal') {
      return 0.0;
    }

    final targetTransactions = selectedCompanyId.value == 'all'
        ? companyTransactions
        : companyTransactions.where(
            (ct) => ct.companyId == selectedCompanyId.value,
          );

    return targetTransactions
        .where((ct) => ct.type == TransactionType.sent)
        .fold(0.0, (sum, ct) => sum + ct.amount);
  }

  // ==================== Data Export/Import Methods ====================
  Future<void> exportData() async {
    try {
      final exportData = _prepareExportData();
      final jsonString = jsonEncode(exportData);

      // Convert string to bytes - THIS IS THE KEY FIX
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: Platform.isIOS ? 'Save to Files' : 'Save Backup',
        fileName: 'moneyroll_backup_$timestamp.json',
        allowedExtensions: ['json'],
        lockParentWindow: true,
        bytes: bytes,
      );

      if (outputFile != null) {
        _showSuccessSnackbar('Backup saved successfully');
        print('Backup saved at: $outputFile');
      } else {
        _showErrorSnackbar('Backup cancelled');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to save backup: ${e.toString()}');
    }
  }

  Map<String, dynamic> _prepareExportData() {
    return {
      'companies': companies.map((c) => c.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'companyTransactions': companyTransactions
          .map((ct) => ct.toJson())
          .toList(),
      'currency': selectedCurrency.value.toJson(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importData() async {
    try {
      // Show confirmation dialog before import
      final bool? proceed = await _showImportConfirmationDialog();

      if (proceed != true) {
        return; // User cancelled
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        // Show loading indicator
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        final contents = await File(result.files.single.path!).readAsString();
        final Map<String, dynamic> data = jsonDecode(contents);

        await _clearExistingData();
        await _importDataFromMap(data);

        _loadAllData();
        _calculateTotalAmount();

        // Close loading dialog
        Get.back();

        _showSuccessSnackbar('Data imported successfully');
      }
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) Get.back();
      _showErrorSnackbar('Failed to import data: $e');
    }
  }

  // ==================== Dialog Helper Methods ====================
  Future<bool?> _showImportConfirmationDialog() async {
    return await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please note:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. This will replace ALL existing data with imported data.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 4),
            const Text('2. Make sure you have a backup before proceeding.'),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            // Updated section:
            const Text(
              'Where to find backup files:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.backgroundColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Backup files can be saved anywhere on your device',
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Look in your Downloads folder or Files app',
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• File name format: moneyroll_backup_[timestamp].json',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.expenseColor,
              foregroundColor: AppConstants.backgroundColor,
            ),
            child: const Text('OK - Proceed'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _clearExistingData() async {
    await _companyBox.clear();
    await _transactionBox.clear();
    await _companyTransactionBox.clear();
  }

  Future<void> _importDataFromMap(Map<String, dynamic> data) async {
    if (data['companies'] != null) {
      for (var companyData in data['companies']) {
        final company = Company.fromJson(companyData);
        await _companyBox.put(company.id, company);
      }
    }

    if (data['transactions'] != null) {
      for (var transactionData in data['transactions']) {
        final transaction = Transaction.fromJson(transactionData);
        await _transactionBox.put(transaction.id, transaction);
      }
    }

    if (data['companyTransactions'] != null) {
      for (var ctData in data['companyTransactions']) {
        final ct = CompanyTransaction.fromJson(ctData);
        await _companyTransactionBox.put(ct.id, ct);
      }
    }

    if (data['currency'] != null) {
      final currency = Currency.fromJson(data['currency']);
      await changeCurrency(currency);
    }
  }

  // ==================== Getter Methods ====================
  List<Transaction> getNormalTransactions() {
    return transactions.toList();
  }

  List<CompanyTransaction> getReceivedCompanyTransactions() {
    return companyTransactions
        .where((ct) => ct.type == TransactionType.received)
        .toList();
  }

  List<CompanyTransaction> getSentCompanyTransactions() {
    return companyTransactions
        .where((ct) => ct.type == TransactionType.sent)
        .toList();
  }

  double getTotalReceivedFromCompanies() {
    return companyTransactions
        .where((ct) => ct.type == TransactionType.received)
        .fold(0.0, (sum, ct) => sum + ct.amount);
  }

  double getTotalSentToCompanies() {
    return companyTransactions
        .where((ct) => ct.type == TransactionType.sent)
        .fold(0.0, (sum, ct) => sum + ct.amount);
  }

  // ==================== Helper Methods ====================
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // dashboard_controller.dart - ADD THESE METHODS

  // Add this method to check if a transaction can be sent
  bool canSendMoney({
    required double amount,
    required SourceType sourceType,
    String? sourceCompanyId,
  }) {
    if (sourceType == SourceType.normal) {
      // Check normal transactions balance
      double normalBalance = 0;
      for (var transaction in transactions) {
        normalBalance += transaction.amount;
      }
      // Add total received from companies minus sent
      normalBalance += getTotalReceivedFromCompanies();
      normalBalance -= getTotalSentToCompanies();

      return normalBalance >= amount;
    } else if (sourceType == SourceType.company && sourceCompanyId != null) {
      // Check specific company balance
      double companyBalance = 0;

      // Calculate company's net balance
      for (var ct in companyTransactions) {
        if (ct.companyId == sourceCompanyId) {
          if (ct.type == TransactionType.received) {
            companyBalance += ct.amount;
          } else {
            companyBalance -= ct.amount;
          }
        }
        // Also track transactions where this company is the source
        if (ct.sourceCompanyId == sourceCompanyId &&
            ct.type == TransactionType.sent) {
          companyBalance -= ct.amount;
        }
      }

      return companyBalance >= amount;
    }
    return false;
  }

  // Get company balance
  double getCompanyBalance(String companyId) {
    double balance = 0;

    for (var ct in companyTransactions) {
      if (ct.companyId == companyId) {
        if (ct.type == TransactionType.received) {
          balance += ct.amount;
        } else {
          balance -= ct.amount;
        }
      }
      // Track outgoing from this company
      if (ct.sourceCompanyId == companyId && ct.type == TransactionType.sent) {
        balance -= ct.amount;
      }
    }

    return balance;
  }

  // Get normal account balance
  double getNormalBalance() {
    double balance = 0;

    for (var transaction in transactions) {
      balance += transaction.amount;
    }

    for (var ct in companyTransactions) {
      if (ct.type == TransactionType.received) {
        balance += ct.amount;
      } else if (ct.type == TransactionType.sent) {
        if (ct.sourceType == SourceType.normal) {
          balance -= ct.amount;
        }
      }
    }

    return balance;
  }

  // UPDATED: Add Company Transaction with source tracking
  Future<void> addCompanyTransaction({
    required String companyId,
    required double amount,
    required DateTime date,
    required TransactionType type,
    DateTime? deadline,
    String? description,
    String? invoiceNumber,
    String? paymentMethod,
    SourceType sourceType = SourceType.normal,
    String? sourceCompanyId,
  }) async {
    final company = _companyBox.get(companyId);
    if (company == null) {
      _showErrorSnackbar('Company not found');
      return;
    }

    // For sent transactions, check if source has enough money
    if (type == TransactionType.sent) {
      if (!canSendMoney(
        amount: amount,
        sourceType: sourceType,
        sourceCompanyId: sourceCompanyId,
      )) {
        _showErrorSnackbar('Insufficient balance in source account');
        return;
      }
    }

    String? sourceCompanyName;
    if (sourceType == SourceType.company && sourceCompanyId != null) {
      final sourceCompany = _companyBox.get(sourceCompanyId);
      sourceCompanyName = sourceCompany?.name;
    }

    final transaction = CompanyTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      companyId: companyId,
      companyName: company.name,
      amount: amount,
      date: date,
      deadLine: deadline,
      type: type,
      description: description,
      invoiceNumber: invoiceNumber,
      paymentMethod: paymentMethod,
      sourceType: sourceType,
      sourceCompanyId: sourceCompanyId,
      sourceCompanyName: sourceCompanyName,
    );

    await _companyTransactionBox.put(transaction.id, transaction);
    companyTransactions.add(transaction);
    _calculateTotalAmount();

    final sourceText = sourceType == SourceType.company
        ? 'from ${sourceCompanyName ?? "company"}'
        : 'from normal account';

    _showCompanyTransactionSuccessSnackbar(
      type,
      company.name,
      isUpdate: false,
      sourceText: sourceText,
    );
  }

  // Get company-to-company transactions
  List<CompanyTransaction> getCompanyToCompanyTransactions() {
    return companyTransactions
        .where(
          (ct) =>
              ct.type == TransactionType.sent &&
              ct.sourceType == SourceType.company &&
              ct.sourceCompanyId != null,
        )
        .toList();
  }

  // Get transactions from a specific source company
  List<CompanyTransaction> getTransactionsFromCompany(String companyId) {
    return companyTransactions
        .where(
          (ct) =>
              ct.sourceCompanyId == companyId &&
              ct.type == TransactionType.sent,
        )
        .toList();
  }

  void _showCompanyTransactionSuccessSnackbar(
    TransactionType type,
    String companyName, {
    bool isUpdate = false,
    String sourceText = '',
  }) {
    final action = type == TransactionType.received
        ? 'received from'
        : 'sent to';

    String message;
    if (type == TransactionType.sent && sourceText.isNotEmpty) {
      message = isUpdate
          ? 'Amount $action $companyName updated $sourceText'
          : 'Amount $action $companyName $sourceText successfully';
    } else {
      message = isUpdate
          ? 'Amount $action $companyName updated successfully'
          : 'Amount $action $companyName successfully';
    }

    _showSuccessSnackbar(message);
  }
}
