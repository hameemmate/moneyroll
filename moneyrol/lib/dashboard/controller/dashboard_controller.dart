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
import 'package:moneyrol/dashboard/model/payment_entry_model.dart';
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
  final Box<PaymentEntry> _paymentEntryBox = Hive.box<PaymentEntry>(
    HiveConstants.paymentEntryBox,
  );
  final Box _settingsBox = Hive.box(HiveConstants.settingsBox);

  // ==================== Observable Variables ====================
  final RxList<Company> companies = <Company>[].obs;
  final RxList<Transaction> transactions = <Transaction>[].obs;
  final RxList<CompanyTransaction> companyTransactions =
      <CompanyTransaction>[].obs;
  final RxList<PaymentEntry> payments = <PaymentEntry>[].obs;
  final RxDouble totalAmount = 0.0.obs;
  final Rx<Currency> selectedCurrency = Currency(
    symbol: '₹',
    code: 'INR',
    name: 'Indian Rupee',
    imagePath: 'assets/images/rupee.png',
  ).obs;
  final RxString selectedCompanyId = 'all'.obs;

  // ==================== Display-ID Counter Keys (in settings box) ====================
  static const String _kTxnCounter = 'counter_txn';
  static const String _kCompCounter = 'counter_comp';
  static const String _kPayCounter = 'counter_pay';

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
    _backfillDisplayIds();
    _calculateTotalAmount();
  }

  // ==================== Display-ID Generation ====================
  // Atomic-ish counter increment using Hive settings box.
  int _nextCounter(String key) {
    final int current = (_settingsBox.get(key) as int?) ?? 0;
    final int next = current + 1;
    _settingsBox.put(key, next);
    return next;
  }

  String _formatId(String prefix, int n) =>
      '$prefix-${n.toString().padLeft(4, '0')}';

  String generateTxnDisplayId() => _formatId('TXN', _nextCounter(_kTxnCounter));
  String generateCompanyTxnDisplayId() =>
      _formatId('COMP', _nextCounter(_kCompCounter));
  String generatePaymentDisplayId() =>
      _formatId('PAY', _nextCounter(_kPayCounter));

  // One-time pass that gives any pre-existing record without a displayId
  // a freshly minted one, so older data also shows readable IDs.
  void _backfillDisplayIds() {
    bool changed = false;

    for (final t in _transactionBox.values.toList()) {
      if (t.displayId == null || t.displayId!.isEmpty) {
        final updated = t.copyWith(displayId: generateTxnDisplayId());
        _transactionBox.put(updated.id, updated);
        changed = true;
      }
    }

    for (final ct in _companyTransactionBox.values.toList()) {
      if (ct.displayId == null || ct.displayId!.isEmpty) {
        final updated = ct.copyWith(displayId: generateCompanyTxnDisplayId());
        _companyTransactionBox.put(updated.id, updated);
        changed = true;
      }
    }

    if (changed) {
      transactions.value = _transactionBox.values.toList();
      companyTransactions.value = _companyTransactionBox.values.toList();
    }
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
    payments.value = _paymentEntryBox.values.toList();
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
      displayId: generateTxnDisplayId(),
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
    // Snackbar is shown by the calling dialog so we don't double-fire here.
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
    // Preserve existing displayId so editing doesn't break the readable id.
    final existing = _transactionBox.get(id);
    final transaction = Transaction(
      id: id,
      displayId: existing?.displayId ?? generateTxnDisplayId(),
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
    // Snackbar shown by caller — see addTransaction note.
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionBox.delete(id);
    transactions.removeWhere((t) => t.id == id);
    // Cascade-delete any payments linked to this transaction (so balances
    // stay correct and history doesn't show orphan references).
    await _deletePaymentsReferencing(id);
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
    // Snackbar shown by caller.
  }

  // ==================== Company Transaction CRUD Operations ====================
  Future<void> addCompanyTransaction({
    required String companyId,
    required double amount,
    required DateTime date,
    required TransactionType type,
    DateTime? deadline,
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
      displayId: generateCompanyTxnDisplayId(),
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

    await _companyTransactionBox.put(transaction.id, transaction);
    companyTransactions.add(transaction);
    _calculateTotalAmount();
    // Snackbar shown by caller.
  }

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
    final existing = _companyTransactionBox.get(id);

    final transaction = CompanyTransaction(
      id: id,
      displayId: existing?.displayId ?? generateCompanyTxnDisplayId(),
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
    // Snackbar shown by caller.
  }

  Future<void> deleteCompanyTransaction(String id) async {
    await _companyTransactionBox.delete(id);
    companyTransactions.removeWhere((ct) => ct.id == id);
    await _deletePaymentsReferencing(id);
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

  // ==================== Payment Ledger CRUD ====================
  //
  // A PaymentEntry describes a single money movement from one party
  // (normal / company / transaction) to another. Use this for ALL scenarios:
  // - personal -> company
  // - company -> personal
  // - transaction -> partner
  // - partner   -> transaction
  // - transaction -> transaction
  // - company   -> company
  //
  // Optionally set [parentRefId] to attach the payment to an existing
  // Transaction or CompanyTransaction record. The parent's "current amount"
  // is then derived from `getCurrentAmount(parentRefId)`.

  Future<PaymentEntry> addPayment({
    required PartyType fromType,
    String? fromId,
    required String fromName,
    required PartyType toType,
    String? toId,
    required String toName,
    required double amount,
    required DateTime date,
    String? description,
    String? paymentMethod,
    String? parentRefId,
  }) async {
    final entry = PaymentEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      displayId: generatePaymentDisplayId(),
      fromType: fromType,
      fromId: fromId,
      fromName: fromName,
      toType: toType,
      toId: toId,
      toName: toName,
      amount: amount,
      date: date,
      description: description,
      paymentMethod: paymentMethod,
      parentRefId: parentRefId,
    );

    await _paymentEntryBox.put(entry.id, entry);
    payments.add(entry);
    _calculateTotalAmount();
    // Snackbar shown by caller.
    return entry;
  }

  Future<void> editPayment({
    required String id,
    required PartyType fromType,
    String? fromId,
    required String fromName,
    required PartyType toType,
    String? toId,
    required String toName,
    required double amount,
    required DateTime date,
    String? description,
    String? paymentMethod,
    String? parentRefId,
  }) async {
    final existing = _paymentEntryBox.get(id);
    if (existing == null) {
      _showErrorSnackbar('Payment not found');
      return;
    }
    final entry = PaymentEntry(
      id: id,
      displayId: existing.displayId ?? generatePaymentDisplayId(),
      fromType: fromType,
      fromId: fromId,
      fromName: fromName,
      toType: toType,
      toId: toId,
      toName: toName,
      amount: amount,
      date: date,
      description: description,
      paymentMethod: paymentMethod,
      parentRefId: parentRefId,
    );
    await _paymentEntryBox.put(id, entry);
    final idx = payments.indexWhere((p) => p.id == id);
    if (idx != -1) payments[idx] = entry;
    _calculateTotalAmount();
    // Snackbar shown by caller.
  }

  Future<void> deletePayment(String id) async {
    await _paymentEntryBox.delete(id);
    payments.removeWhere((p) => p.id == id);
    _calculateTotalAmount();
  }

  Future<void> _deletePaymentsReferencing(String parentId) async {
    final toRemove = _paymentEntryBox.values
        .where((p) => p.parentRefId == parentId)
        .map((p) => p.id)
        .toList();
    for (final pid in toRemove) {
      await _paymentEntryBox.delete(pid);
    }
    payments.removeWhere((p) => toRemove.contains(p.id));
  }

  // ==================== Payment Ledger Queries ====================

  /// All payments linked to a particular transaction (Transaction or
  /// CompanyTransaction) via [parentRefId], sorted newest first.
  List<PaymentEntry> getPaymentsForTransaction(String parentId) {
    final list = payments.where((p) => p.parentRefId == parentId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// All payments where a given company is on either side, sorted newest first.
  List<PaymentEntry> getPaymentsForCompany(String companyId) {
    final list = payments
        .where(
          (p) =>
              (p.fromType == PartyType.company && p.fromId == companyId) ||
              (p.toType == PartyType.company && p.toId == companyId),
        )
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// All payments involving the "normal" / personal party on either side.
  List<PaymentEntry> getPaymentsForNormal() {
    final list = payments
        .where(
          (p) => p.fromType == PartyType.normal || p.toType == PartyType.normal,
        )
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Returns the *current* amount for a parent transaction by applying all
  /// linked payments to its original amount.
  ///
  /// Convention: when the parent is referenced as the **TO** party of a
  /// payment, money is coming IN -> add. When referenced as the **FROM**
  /// party, money is going OUT -> subtract. Payments that merely list the
  /// parent's id as `parentRefId` (without being on either side) are treated
  /// as informational and don't alter the balance.
  double getCurrentAmount(String parentId) {
    final original = _originalAmountOf(parentId);
    final linked = getPaymentsForTransaction(parentId);

    double net = original;
    for (final p in linked) {
      final isParentTo =
          p.toType == PartyType.transaction && p.toId == parentId;
      final isParentFrom =
          p.fromType == PartyType.transaction && p.fromId == parentId;

      if (isParentTo) {
        net += p.amount;
      } else if (isParentFrom) {
        net -= p.amount;
      }
      // else: payment is linked for context only — no balance impact.
    }
    return net;
  }

  /// Sum of payments flowing INTO the parent transaction.
  double getTotalReceivedForTransaction(String parentId) {
    return getPaymentsForTransaction(parentId)
        .where((p) => p.toType == PartyType.transaction && p.toId == parentId)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  /// Sum of payments flowing OUT OF the parent transaction.
  double getTotalSentFromTransaction(String parentId) {
    return getPaymentsForTransaction(parentId)
        .where(
          (p) => p.fromType == PartyType.transaction && p.fromId == parentId,
        )
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  double _originalAmountOf(String parentId) {
    final t = _transactionBox.get(parentId);
    if (t != null) return t.amount;
    final ct = _companyTransactionBox.get(parentId);
    if (ct != null) return ct.amount;
    return 0.0;
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
      'payments': payments.map((p) => p.toJson()).toList(),
      'counters': {
        'txn': _settingsBox.get(_kTxnCounter) ?? 0,
        'comp': _settingsBox.get(_kCompCounter) ?? 0,
        'pay': _settingsBox.get(_kPayCounter) ?? 0,
      },
      'currency': selectedCurrency.value.toJson(),
      'exportDate': DateTime.now().toIso8601String(),
      'schemaVersion': 2,
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
        _backfillDisplayIds();
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
    await _paymentEntryBox.clear();
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

    if (data['payments'] != null) {
      for (var pData in data['payments']) {
        final p = PaymentEntry.fromJson(pData);
        await _paymentEntryBox.put(p.id, p);
      }
    }

    if (data['counters'] != null) {
      final counters = Map<String, dynamic>.from(data['counters']);
      if (counters['txn'] != null) {
        await _settingsBox.put(_kTxnCounter, counters['txn']);
      }
      if (counters['comp'] != null) {
        await _settingsBox.put(_kCompCounter, counters['comp']);
      }
      if (counters['pay'] != null) {
        await _settingsBox.put(_kPayCounter, counters['pay']);
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
