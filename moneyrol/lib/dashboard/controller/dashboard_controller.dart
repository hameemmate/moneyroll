import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:moneyrol/constants/app_constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/model/transation_model.dart';
import 'package:moneyrol/theme/app_theme.dart';
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
  Future<void> addCompanyTransaction({
    required String companyId,
    required double amount,
    required DateTime date,
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      companyId: companyId,
      companyName: company.name,
      amount: amount,
      date: date,
      type: type,
      description: description,
      invoiceNumber: invoiceNumber,
      paymentMethod: paymentMethod,
    );

    await _companyTransactionBox.put(transaction.id, transaction);
    companyTransactions.add(transaction);
    _calculateTotalAmount();
    _showCompanyTransactionSuccessSnackbar(type, company.name);
  }

  Future<void> editCompanyTransaction({
    required String id,
    required String companyId,
    required double amount,
    required DateTime date,
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

      if (!await _requestStoragePermission()) {
        return;
      }

      final filePath = await _createBackupFile(jsonString);
      _showSuccessSnackbar('Backup saved in moneyroll folder.');
      print('Backup saved at: $filePath');
    } catch (e) {
      _showErrorSnackbar('Failed to save backup: $e');
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

  Future<bool> _requestStoragePermission() async {
    var status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      Get.snackbar("Permission Required", "Please allow storage access");
      return false;
    }
    return true;
  }

  Future<String> _createBackupFile(String jsonString) async {
    final directory = Directory('/storage/emulated/0/moneyroll');

    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'moneyroll_backup_$timestamp.json';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    await file.writeAsString(jsonString);
    return filePath;
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
            const Text(
              'Exported data files are stored in:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.backgroundColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '/storage/emulated/0/moneyroll',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppConstants.expenseColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Look for files named: moneyroll_backup_[timestamp].json',
              style: TextStyle(fontSize: 12),
            ),
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
            child: Text('OK - Proceed'),
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

  void _showCompanyTransactionSuccessSnackbar(
    TransactionType type,
    String companyName, {
    bool isUpdate = false,
  }) {
    final action = type == TransactionType.received
        ? 'received from'
        : 'sent to';
    final message = isUpdate
        ? 'Amount $action $companyName updated successfully'
        : 'Amount $action $companyName successfully';

    _showSuccessSnackbar(message);
  }
}
