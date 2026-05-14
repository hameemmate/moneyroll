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

  // Computes the user's net total as the sum of each transaction's CURRENT
  // amount (so payments linked to a parent automatically adjust the parent's
  // contribution), plus the net effect of every payment on the "Normal"
  // (personal/cash) side.
  //
  // Worked examples — all net out correctly with this formula:
  //
  //   • Txn X (Normal income ₹1000), then payment X → Normal ₹300:
  //     getCurrentAmount(X) = ₹700; Normal-side: +₹300; total = ₹1000 ✓
  //
  //   • Payment Company A → Normal ₹200 (no parent):
  //     no txn change; Normal-side: +₹200; total += ₹200 ✓
  //
  //   • Payment Company A → Company B (no Normal involved):
  //     no txn change; no Normal-side; total unchanged ✓
  //
  //   • Payment Normal → Txn Y (received CT of ₹1000):
  //     getCurrentAmount(Y) = ₹1200 (Y is "to"); Normal-side: -₹200;
  //     contribution to total = +₹1200 - ₹200 = +₹1000 ✓
  void _calculateTotalAmount() {
    double total = 0;

    // Each Normal transaction contributes its CURRENT amount (positive).
    for (var t in transactions) {
      total += getCurrentAmount(t.id);
    }

    // Each Company transaction contributes its CURRENT amount, signed by type.
    for (var ct in companyTransactions) {
      final current = getCurrentAmount(ct.id);
      if (ct.type == TransactionType.received) {
        total += current;
      } else {
        total -= current;
      }
    }

    // Apply the Normal-side effect of every payment. Payments linked to a
    // parent transaction are already reflected via getCurrentAmount above
    // for the transaction side; this loop adds the corresponding Normal
    // side so reallocations net out and pure Company→Normal / Normal→
    // Company payments still move the total.
    for (var p in payments) {
      if (p.toType == PartyType.normal) total += p.amount;
      if (p.fromType == PartyType.normal) total -= p.amount;
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
    String? sourcePaymentId,
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
      sourcePaymentId: sourcePaymentId,
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
    String? sourcePaymentId,
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
      // Preserve existing chain link if caller didn't override it.
      sourcePaymentId: sourcePaymentId ?? existing.sourcePaymentId,
    );
    await _paymentEntryBox.put(id, entry);
    final idx = payments.indexWhere((p) => p.id == id);
    if (idx != -1) payments[idx] = entry;
    _calculateTotalAmount();
    // Snackbar shown by caller.
  }

  // ==================== Payment Chain Traversal ====================
  //
  // PaymentEntries can be linked into a chain via sourcePaymentId so we can
  // model "from this ₹30 onward to that company, then onward again, …".
  // These helpers walk the chain in either direction and stay safe against
  // accidental cycles (depth-limited / visited-set).

  /// Returns the source chain for a payment, root-first. For example, given
  /// PAY-0003 sourced from PAY-0002 sourced from PAY-0001, calling this on
  /// PAY-0003 returns [PAY-0001, PAY-0002] (PAY-0003 itself is NOT
  /// included).
  List<PaymentEntry> getSourceChain(String paymentId) {
    final chain = <PaymentEntry>[];
    final visited = <String>{paymentId};
    final start = payments.firstWhereOrNull((p) => p.id == paymentId);
    if (start == null) return chain;

    String? cursor = start.sourcePaymentId;
    while (cursor != null && !visited.contains(cursor) && chain.length < 64) {
      visited.add(cursor);
      final next = payments.firstWhereOrNull((p) => p.id == cursor);
      if (next == null) break;
      chain.insert(0, next); // prepend so result reads root-first
      cursor = next.sourcePaymentId;
    }
    return chain;
  }

  /// Direct children: payments that were sourced FROM this one (one hop).
  List<PaymentEntry> getDirectChildren(String paymentId) {
    final list = payments
        .where((p) => p.sourcePaymentId == paymentId)
        .toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
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

  /// Returns the FULL tree of payments anchored at a transaction — direct
  /// children (parentRefId == parentId) plus every chain descendant reached
  /// by following sourcePaymentId forward. Flattened and sorted newest
  /// first.
  ///
  /// Used by the transaction card's "Linked payments" expansion so the
  /// user can see the complete onward trail (e.g. TXN → A, A → B, B → C)
  /// in one place instead of tapping detail sheets one by one.
  List<PaymentEntry> getPaymentTreeForTransaction(String parentId) {
    final direct = payments.where((p) => p.parentRefId == parentId).toList();
    final all = <PaymentEntry>[...direct];
    final visited = direct.map((p) => p.id).toSet();
    final queue = <PaymentEntry>[...direct];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final children = payments.where((p) => p.sourcePaymentId == current.id);
      for (final c in children) {
        if (visited.add(c.id)) {
          all.add(c);
          queue.add(c);
        }
      }
    }

    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
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

  /// Returns the *current* amount for a parent transaction by applying every
  /// payment that touches it on either side.
  ///
  /// IMPORTANT: we scan **all** payments — not just those whose `parentRefId`
  /// matches — because a payment between two transactions can only attach
  /// `parentRefId` to one side. If we filtered by `parentRefId` here, the
  /// other transaction's balance would never update. So the source of truth
  /// for balance is "is this transaction on the to/from side of any payment".
  ///
  ///   • when this txn is the **TO** side → money coming IN, add.
  ///   • when this txn is the **FROM** side → money going OUT, subtract.
  double getCurrentAmount(String parentId) {
    double net = _originalAmountOf(parentId);
    for (final p in payments) {
      final isParentTo =
          p.toType == PartyType.transaction && p.toId == parentId;
      final isParentFrom =
          p.fromType == PartyType.transaction && p.fromId == parentId;
      if (isParentTo) {
        net += p.amount;
      } else if (isParentFrom) {
        net -= p.amount;
      }
    }
    return net;
  }

  /// Sum of payments flowing INTO this transaction (regardless of which
  /// side `parentRefId` points to).
  double getTotalReceivedForTransaction(String parentId) {
    return payments
        .where((p) => p.toType == PartyType.transaction && p.toId == parentId)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  /// Sum of payments flowing OUT OF this transaction.
  double getTotalSentFromTransaction(String parentId) {
    return payments
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

  // Returns payments that should appear in the history list for the current
  // filter:
  //   • all     → every payment
  //   • normal  → payments where Normal/personal is on either side
  //   • <company id> → payments where that company is on either side
  //
  // Always sorted newest first. The history merges these with normal /
  // company transactions and sorts the combined list by date so the user
  // sees a single chronological feed of everything that touched the
  // selected party.
  List<PaymentEntry> getFilteredPayments() {
    Iterable<PaymentEntry> source;
    final sel = selectedCompanyId.value;
    if (sel == 'all') {
      source = payments;
    } else if (sel == 'normal') {
      // Normal's feed shows only payments that DIRECTLY touch the Normal
      // pool — either party is Normal, or party is a normal Transaction
      // (which is part of Normal). Downstream chain descendants like
      // A→B→C are NOT listed here as separate cards; the user can still
      // trace them by tapping the originating payment's detail sheet,
      // which surfaces the source/forward chain in one tap.
      //
      // We also DE-DUPLICATE: if a payment is already shown nested under
      // a normal Transaction (via parentRefId), we skip it here so it
      // doesn't appear twice (once nested, once as a top-level card).
      final normalTxnIds = transactions.map((t) => t.id).toSet();
      source = payments.where((p) {
        if (p.parentRefId != null &&
            normalTxnIds.contains(p.parentRefId)) {
          return false;
        }
        return p.fromType == PartyType.normal ||
            p.toType == PartyType.normal ||
            (p.fromType == PartyType.transaction &&
                normalTxnIds.contains(p.fromId)) ||
            (p.toType == PartyType.transaction &&
                normalTxnIds.contains(p.toId));
      });
    } else {
      source = payments.where(
        (p) =>
            (p.fromType == PartyType.company && p.fromId == sel) ||
            (p.toType == PartyType.company && p.toId == sel),
      );
    }
    final list = source.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // Returns "received" for the currently selected filter:
  // - Normal: user's own income (normal transactions) plus any payment that
  //   landed in the Normal/personal side.
  // - Specific company: legacy received CompanyTransactions for that
  //   company, plus any payment where that company is the "from" party
  //   (money flowed OUT of the company → into the user's books).
  // - All partners: aggregated equivalent across every company.
  // Returns "Received" for the currently selected filter, expressed from
  // that selected party's own point of view.
  //
  //   • Normal     → money that landed in the user's personal cash (normal
  //                  transactions are inflows, plus any payment whose "to"
  //                  side is Normal).
  //   • All        → user-side aggregate: every received CompanyTransaction
  //                  across all partners + every payment with a company on
  //                  the "from" side (because that's money flowing INTO the
  //                  user's books).
  //   • <companyX> → party-centric: every CompanyTransaction of type
  //                  `sent` for X (user sent → company received) + every
  //                  payment with X on the "to" side. Critically, NEVER
  //                  touches the Normal account — it only describes what
  //                  the *company* received.
  double getSelectedTotalReceived() {
    final sel = selectedCompanyId.value;

    if (sel == 'normal') {
      // Normal's cash pool = direct Normal + every normal Transaction.
      // We count as "received":
      //   • original amounts of all normal Transactions, AND
      //   • payments arriving in Normal from OUTSIDE the Normal pool.
      // We deliberately exclude payments where BOTH sides resolve to
      // Normal (e.g. TXN-0001 → TXN-0002) because that's an internal
      // reallocation — no money actually entered Normal.
      final baseNormalIncome = transactions.fold(
        0.0,
        (sum, t) => sum + t.amount,
      );
      final normalTxnIds = transactions.map((t) => t.id).toSet();
      bool isFromNormalSide(PaymentEntry p) =>
          p.fromType == PartyType.normal ||
          (p.fromType == PartyType.transaction &&
              normalTxnIds.contains(p.fromId));
      bool isToNormalSide(PaymentEntry p) =>
          p.toType == PartyType.normal ||
          (p.toType == PartyType.transaction &&
              normalTxnIds.contains(p.toId));
      final paymentsIntoNormal = payments
          .where((p) => isToNormalSide(p) && !isFromNormalSide(p))
          .fold(0.0, (sum, p) => sum + p.amount);
      return baseNormalIncome + paymentsIntoNormal;
    }

    if (sel == 'all') {
      final base = companyTransactions
          .where((ct) => ct.type == TransactionType.received)
          .fold(0.0, (sum, ct) => sum + ct.amount);
      final paymentInflows = payments
          .where((p) => p.fromType == PartyType.company)
          .fold(0.0, (sum, p) => sum + p.amount);
      return base + paymentInflows;
    }

    // Specific company — show *its* received amount.
    // Legacy CT type=sent means user sent to this company, so from the
    // company's POV it was the receiving party.
    final baseCompanyReceived = companyTransactions
        .where((ct) => ct.companyId == sel && ct.type == TransactionType.sent)
        .fold(0.0, (sum, ct) => sum + ct.amount);
    // Every payment with the company on the "to" side is also inbound.
    final paymentsIntoCompany = payments
        .where((p) => p.toType == PartyType.company && p.toId == sel)
        .fold(0.0, (sum, p) => sum + p.amount);
    return baseCompanyReceived + paymentsIntoCompany;
  }

  // Returns "Sent" for the currently selected filter, again from that
  // selected party's own point of view.
  //
  //   • Normal     → money that left the user's personal cash via payments.
  //   • All        → user-side aggregate: every sent CompanyTransaction +
  //                  every payment with a company on the "to" side.
  //   • <companyX> → party-centric: every CompanyTransaction of type
  //                  `received` for X (user received → company sent) +
  //                  every payment with X on the "from" side. Doesn't
  //                  touch Normal's books.
  double getSelectedTotalSent() {
    final sel = selectedCompanyId.value;

    if (sel == 'normal') {
      // Symmetric to the Received branch — count payments that LEFT
      // Normal's pool for somewhere outside it. Internal moves between
      // two normal-side parties don't contribute.
      final normalTxnIds = transactions.map((t) => t.id).toSet();
      bool isFromNormalSide(PaymentEntry p) =>
          p.fromType == PartyType.normal ||
          (p.fromType == PartyType.transaction &&
              normalTxnIds.contains(p.fromId));
      bool isToNormalSide(PaymentEntry p) =>
          p.toType == PartyType.normal ||
          (p.toType == PartyType.transaction &&
              normalTxnIds.contains(p.toId));
      return payments
          .where((p) => isFromNormalSide(p) && !isToNormalSide(p))
          .fold(0.0, (sum, p) => sum + p.amount);
    }

    if (sel == 'all') {
      final base = companyTransactions
          .where((ct) => ct.type == TransactionType.sent)
          .fold(0.0, (sum, ct) => sum + ct.amount);
      final paymentOutflows = payments
          .where((p) => p.toType == PartyType.company)
          .fold(0.0, (sum, p) => sum + p.amount);
      return base + paymentOutflows;
    }

    // Specific company — show *its* sent amount.
    final baseCompanySent = companyTransactions
        .where(
          (ct) => ct.companyId == sel && ct.type == TransactionType.received,
        )
        .fold(0.0, (sum, ct) => sum + ct.amount);
    final paymentsFromCompany = payments
        .where((p) => p.fromType == PartyType.company && p.fromId == sel)
        .fold(0.0, (sum, p) => sum + p.amount);
    return baseCompanySent + paymentsFromCompany;
  }

  // ==================== User ↔ Company Relationship ====================
  //
  // These give the slice of activity that involves only the user's Normal
  // account and a specific company — i.e. the "what's between me and this
  // partner" view. Company↔company transfers that don't touch Normal are
  // intentionally excluded so the numbers reflect only user-relevant cash
  // movement.

  // Money the user (Normal) received from this company. Includes:
  //   • legacy "received" CompanyTransactions for the company, AND
  //   • payments routed from this company INTO Normal — where "into
  //     Normal" means direct (toType == normal) OR into one of the user's
  //     normal Transactions (toType == transaction AND toId ∈ normalTxnIds),
  //     because a normal Transaction is part of Normal's cash pool.
  double getUserReceivedFromCompany(String companyId) {
    final base = companyTransactions
        .where(
          (ct) =>
              ct.companyId == companyId && ct.type == TransactionType.received,
        )
        .fold(0.0, (sum, ct) => sum + ct.amount);
    final normalTxnIds = transactions.map((t) => t.id).toSet();
    final payIn = payments.where((p) {
      final fromIsCompany =
          p.fromType == PartyType.company && p.fromId == companyId;
      final toIsNormalSide = p.toType == PartyType.normal ||
          (p.toType == PartyType.transaction &&
              normalTxnIds.contains(p.toId));
      return fromIsCompany && toIsNormalSide;
    }).fold(0.0, (sum, p) => sum + p.amount);
    return base + payIn;
  }

  // Money the user (Normal) sent to this company. Includes:
  //   • legacy "sent" CompanyTransactions, AND
  //   • payments routed from Normal (or any normal Transaction, which is
  //     part of Normal's pool) INTO this company.
  double getUserSentToCompany(String companyId) {
    final base = companyTransactions
        .where(
          (ct) => ct.companyId == companyId && ct.type == TransactionType.sent,
        )
        .fold(0.0, (sum, ct) => sum + ct.amount);
    final normalTxnIds = transactions.map((t) => t.id).toSet();
    final payOut = payments.where((p) {
      final fromIsNormalSide = p.fromType == PartyType.normal ||
          (p.fromType == PartyType.transaction &&
              normalTxnIds.contains(p.fromId));
      final toIsCompany =
          p.toType == PartyType.company && p.toId == companyId;
      return fromIsNormalSide && toIsCompany;
    }).fold(0.0, (sum, p) => sum + p.amount);
    return base + payOut;
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

  // Total received FROM partners across all companies — includes payments
  // where any company sits on the "from" side of the movement.
  double getTotalReceivedFromCompanies() {
    final base = companyTransactions
        .where((ct) => ct.type == TransactionType.received)
        .fold(0.0, (sum, ct) => sum + ct.amount);
    final paymentInflows = payments
        .where((p) => p.fromType == PartyType.company)
        .fold(0.0, (sum, p) => sum + p.amount);
    return base + paymentInflows;
  }

  // Total sent TO partners across all companies — includes payments where
  // any company sits on the "to" side.
  double getTotalSentToCompanies() {
    final base = companyTransactions
        .where((ct) => ct.type == TransactionType.sent)
        .fold(0.0, (sum, ct) => sum + ct.amount);
    final paymentOutflows = payments
        .where((p) => p.toType == PartyType.company)
        .fold(0.0, (sum, p) => sum + p.amount);
    return base + paymentOutflows;
  }

  // Net balance for a single company from the user's POV. Positive means
  // the company owes the user (user has sent more than received); negative
  // means the user owes the company.
  double getCompanyBalance(String companyId) {
    final received = companyTransactions
        .where(
          (ct) =>
              ct.companyId == companyId && ct.type == TransactionType.received,
        )
        .fold(0.0, (sum, ct) => sum + ct.amount);
    final sent = companyTransactions
        .where(
          (ct) => ct.companyId == companyId && ct.type == TransactionType.sent,
        )
        .fold(0.0, (sum, ct) => sum + ct.amount);
    final paymentInflows = payments
        .where((p) => p.fromType == PartyType.company && p.fromId == companyId)
        .fold(0.0, (sum, p) => sum + p.amount);
    final paymentOutflows = payments
        .where((p) => p.toType == PartyType.company && p.toId == companyId)
        .fold(0.0, (sum, p) => sum + p.amount);
    // sent + paymentOutflows = money flowed INTO the company (from user's
    // ledger). received + paymentInflows = money flowed OUT of the company.
    return (sent + paymentOutflows) - (received + paymentInflows);
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
