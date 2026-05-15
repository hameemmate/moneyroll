import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/constants/app_constants.dart';
import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';

import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/model/payment_entry_model.dart';
import 'package:moneyrol/dashboard/model/transation_model.dart';
import 'package:moneyrol/dashboard/view/widgets/add_payment_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/edit_company_transation_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/edit_transation_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/root_payment_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DashboardController controller = Get.find();
  bool _summaryExpanded = true; // collapsed state

  static const String normalTransactionsId = 'normal';

  @override
  void initState() {
    super.initState();
    // Set default filter to 'normal' if it's still 'all' from previous sessions
    if (controller.selectedCompanyId.value == 'all') {
      controller.selectedCompanyId.value = normalTransactionsId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Transaction History',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Column(
          children: [
            _buildCompanyFilterList(),
            _buildSummaryCard(),
            Expanded(
              child: controller.selectedCompanyId.value == normalTransactionsId
                  ? _buildNormalTransactionsList(context)
                  : _buildCompanyTransactionsList(context),
            ),
            SizedBox(height: Get.width * .13),
          ],
        ),
      ),
    );
  }

  // ---------------- FILTER CHIPS (All Partners removed) ----------------
  Widget _buildCompanyFilterList() {
    return Obx(() {
      final companies = controller.companies;
      final options = [
        {'id': normalTransactionsId, 'name': 'Normal Income'},
        ...companies.map((c) => {'id': c.id, 'name': c.name}),
      ];
      return Container(
        height: 52,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: options.length,
          itemBuilder: (_, i) {
            final opt = options[i];
            final isSelected = controller.selectedCompanyId.value == opt['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                checkmarkColor: Colors.white,
                selectedShadowColor: Colors.green,
                label: Text(
                  opt['name'] ?? "",
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppConstants.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) =>
                    controller.selectedCompanyId.value = opt['id'] ?? "",
                selectedColor: AppConstants.primaryColor,
                backgroundColor: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // ---------------- SUMMARY CARD (collapsible) ----------------
  Widget _buildSummaryCard() {
    return Obx(() {
      final sel = controller.selectedCompanyId.value;
      final isNormal = sel == normalTransactionsId;
      final isAll = sel == 'all'; // kept for safety, but never selected now

      // Use the same UI for both Normal and Company, but collapsible
      return Column(
        children: [
          // Header row with expand/collapse button
          GestureDetector(
            onTap: () => setState(() => _summaryExpanded = !_summaryExpanded),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _summaryExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppConstants.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _summaryExpanded ? 'Hide summary' : 'Show summary',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_summaryExpanded)
            isNormal
                ? _buildNormalSummaryCard()
                : _buildCompanySummaryCard(sel, isAll),
        ],
      );
    });
  }

  // Normal summary card (existing layout)
  Widget _buildNormalSummaryCard() {
    final externalIncome = controller.transactions.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );
    final cashOnHand = controller.totalAmount.value;

    double totalSentToPartners = 0.0;
    double totalReceivedFromPartners = 0.0;
    for (final p in controller.payments) {
      final root = controller.getRootNormalTransaction(p);
      if (root == null) continue;
      final isFromNormal =
          p.fromType == PartyType.normal ||
          (p.fromType == PartyType.transaction &&
              controller.transactions.any((t) => t.id == p.fromId));
      final isToNormal =
          p.toType == PartyType.normal ||
          (p.toType == PartyType.transaction &&
              controller.transactions.any((t) => t.id == p.toId));
      if (isFromNormal && !isToNormal) totalSentToPartners += p.amount;
      if (!isFromNormal && isToNormal) totalReceivedFromPartners += p.amount;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Normal Income',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _summaryItem(
                'External Income',
                externalIncome,
                AppConstants.successColor,
              ),
              _summaryItem(
                'Sent to Partners',
                totalSentToPartners,
                AppConstants.errorColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryItem(
                'Received from Partners',
                totalReceivedFromPartners,
                AppConstants.successColor,
              ),
              _summaryItem(
                'Cash on Hand',
                cashOnHand,
                cashOnHand >= 0
                    ? AppConstants.successColor
                    : AppConstants.errorColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cashOnHand >= 0
                  ? AppConstants.successColor.withOpacity(0.08)
                  : AppConstants.errorColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cashOnHand >= 0
                    ? AppConstants.successColor.withOpacity(0.25)
                    : AppConstants.errorColor.withOpacity(0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  cashOnHand >= 0
                      ? Icons.account_balance_wallet
                      : Icons.warning_amber,
                  size: 16,
                  color: cashOnHand >= 0
                      ? AppConstants.successColor
                      : AppConstants.errorColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cashOnHand >= 0
                        ? '💰 Available to spend: ${controller.formatAmount(cashOnHand)}'
                        : '⚠️ Overdrawn by ${controller.formatAmount(-cashOnHand)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cashOnHand >= 0
                          ? AppConstants.successColor
                          : AppConstants.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Company summary card (specific company)
  Widget _buildCompanySummaryCard(String sel, bool isAll) {
    final company = controller.companies.firstWhereOrNull((c) => c.id == sel);
    final companyName = company?.name ?? 'Company';
    final netObligation = controller.getCompanyNetObligation(sel);

    if (netObligation <= 0) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You ↔ $companyName',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All transfers including chains',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Settled – No money to return',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You ↔ $companyName',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All transfers including chains',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '💰 To receive',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  controller.formatAmount(netObligation),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Reusable summary item (same as before)
  Widget _summaryItem(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppConstants.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${controller.selectedCurrency.value.symbol}${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- The rest of your methods remain unchanged ----------------
  // (keep _buildNormalTransactionsList, _buildCompanyTransactionsList,
  //  _buildTransactionList, _showTxnPayChooser, _openPaymentDialog,
  //  _showPaymentDetails, _detailRow, _buildChainSection, _chainRow,
  //  _detailPartyRow, _typeLabel, _labelForParent, _navigateToParty,
  //  _showDeleteConfirmation, _showEditNormalTransactionDialog,
  //  _showEditCompanyTransactionDialog, and the helper classes)

  // ---------------- NORMAL TRANSACTIONS LIST (only root cards) ----------------
  Widget _buildNormalTransactionsList(BuildContext context) {
    final rootTransactions = controller.transactions.toList();
    rootTransactions.sort((a, b) => b.date.compareTo(a.date));

    final items = rootTransactions.map((t) {
      final tree = controller.getPaymentTree(t.id);
      return _HistoryItem(
        date: t.date,
        widget: _RootTransactionCard(
          transaction: t,
          paymentTree: tree,
          onEdit: () => _showEditNormalTransactionDialog(context, t),
          onDelete: () => _showDeleteConfirmation(
            context,
            () => controller.deleteTransaction(t.id),
          ),
          onPay: () => _showTxnPayChooser(
            context,
            txnId: t.id,
            txnLabel: t.displayId ?? t.description ?? 'Transaction',
          ),
        ),
      );
    }).toList();

    items.sort((a, b) => b.date.compareTo(a.date));
    return _buildTransactionList(items.map((i) => i.widget).toList());
  }

  // ---------------- COMPANY TRANSACTIONS LIST ----------------
  Widget _buildCompanyTransactionsList(BuildContext context) {
    final selectedCompany = controller.selectedCompanyId.value;
    final allPayments = controller.payments;

    final relevantPayments = allPayments.where((p) {
      if (p.fromType == PartyType.company && p.fromId == selectedCompany)
        return true;
      if (p.toType == PartyType.company && p.toId == selectedCompany)
        return true;
      return false;
    }).toList();

    final legacyTransactions = controller.companyTransactions
        .where((ct) => ct.companyId == selectedCompany)
        .toList();

    final items = <_HistoryItem>[];

    for (final ct in legacyTransactions) {
      items.add(
        _HistoryItem(
          date: ct.date,
          widget: _LegacyCompanyTransactionCard(
            transaction: ct,
            onEdit: () => _showEditCompanyTransactionDialog(context, ct),
            onDelete: () => _showDeleteConfirmation(
              context,
              () => controller.deleteCompanyTransaction(ct.id),
            ),
            onPay: () => _showTxnPayChooser(
              context,
              txnId: ct.id,
              txnLabel: ct.displayId ?? ct.companyName,
            ),
          ),
        ),
      );
    }

    for (final p in relevantPayments) {
      final subTree = controller.getPaymentTree(p.id);
      final rootNormal = controller.getRootNormalTransaction(p);
      items.add(
        _HistoryItem(
          date: p.date,
          widget: _CompanyPaymentCard(
            payment: p,
            subTree: subTree,
            rootNormal: rootNormal,
            onTap: () => _showPaymentDetails(context, p),
            onDelete: () => _showDeleteConfirmation(
              context,
              () => controller.deletePayment(p.id),
            ),
          ),
        ),
      );
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return _buildTransactionList(items.map((i) => i.widget).toList());
  }

  Widget _buildTransactionList(List<Widget> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add transactions to see them here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  // ---------------- HELPER DIALOGS ----------------
  void _showTxnPayChooser(
    BuildContext context, {
    required String txnId,
    required String txnLabel,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  txnLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.red.shade600,
                  ),
                ),
                title: const Text(
                  'Send money FROM this',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Pay out from this transaction to a partner, person, or another transaction',
                ),
                onTap: () {
                  Get.back();
                  _openPaymentDialog(
                    context,
                    fromType: PartyType.transaction,
                    fromId: txnId,
                    fromName: txnLabel,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color: Colors.green.shade700,
                  ),
                ),
                title: const Text(
                  'Pay INTO this',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Record an incoming payment posted against this transaction',
                ),
                onTap: () {
                  Get.back();
                  _openPaymentDialog(
                    context,
                    toType: PartyType.transaction,
                    toId: txnId,
                    toName: txnLabel,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openPaymentDialog(
    BuildContext context, {
    PartyType? fromType,
    String? fromId,
    String? fromName,
    PartyType? toType,
    String? toId,
    String? toName,
    String? sourcePaymentId,
    String? sourceLabel,
  }) {
    showDialog(
      context: context,
      builder: (_) => AddPaymentDialog(
        prefilledFrom: fromType == null
            ? null
            : PartySelection(type: fromType, id: fromId, name: fromName ?? ''),
        prefilledTo: toType == null
            ? null
            : PartySelection(type: toType, id: toId, name: toName ?? ''),
        prefilledSourcePaymentId: sourcePaymentId,
        sourceLabel: sourceLabel,
      ),
    );
  }

  void _showPaymentDetails(BuildContext context, PaymentEntry p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.displayId ?? 'Transfer',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy • hh:mm a').format(p.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      controller.formatAmount(p.amount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _detailPartyRow(
                  label: 'From',
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.red.shade600,
                  partyType: p.fromType,
                  partyId: p.fromId,
                  partyName: p.fromName,
                ),
                const SizedBox(height: 10),
                _detailPartyRow(
                  label: 'To',
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.green.shade700,
                  partyType: p.toType,
                  partyId: p.toId,
                  partyName: p.toName,
                ),
                if ((p.paymentMethod != null && p.paymentMethod!.isNotEmpty) ||
                    (p.description != null && p.description!.isNotEmpty)) ...[
                  const SizedBox(height: 14),
                  if (p.paymentMethod != null && p.paymentMethod!.isNotEmpty)
                    _detailRow('Method', p.paymentMethod!),
                  if (p.description != null && p.description!.isNotEmpty)
                    _detailRow('Note', p.description!),
                ],
                if (p.parentRefId != null) ...[
                  const SizedBox(height: 8),
                  _detailRow('Linked to', _labelForParent(p.parentRefId!)),
                ],
                if (p.deadline != null) ...[
                  const SizedBox(height: 8),
                  _detailRow(
                    'Deadline',
                    DateFormat('dd MMM yyyy').format(p.deadline!),
                    highlight: p.deadline!.isBefore(DateTime.now()),
                  ),
                ],
                _buildChainSection(context, p),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    _openPaymentDialog(
                      context,
                      fromType: p.toType,
                      fromId: p.toId,
                      fromName: p.toName,
                      sourcePaymentId: p.id,
                      sourceLabel:
                          '${p.displayId ?? 'PAY'} • ${p.fromName} → ${p.toName} (${controller.formatAmount(p.amount)})',
                    );
                  },
                  icon: const Icon(Icons.fork_right_rounded, size: 18),
                  label: const Text('Send from this'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    minimumSize: const Size.fromHeight(0),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.back();
                          showDialog(
                            context: context,
                            builder: (_) => AddPaymentDialog(paymentToEdit: p),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.indigo.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.back();
                          _showDeleteConfirmation(
                            context,
                            () => controller.deletePayment(p.id),
                          );
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: highlight ? Colors.red.shade700 : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: highlight ? Colors.red.shade700 : null,
                fontWeight: highlight ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChainSection(BuildContext context, PaymentEntry p) {
    final source = controller.getSourceChain(p.id);
    final children = controller.getDirectChildren(p.id);
    if (source.isEmpty && children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chain',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          if (source.isNotEmpty)
            ...source.map(
              (s) => _chainRow(
                icon: Icons.subdirectory_arrow_right_rounded,
                color: Colors.grey.shade700,
                label: 'Sourced from',
                payment: s,
              ),
            ),
          _chainRow(
            icon: Icons.fiber_manual_record_rounded,
            color: Colors.indigo.shade700,
            label: 'This payment',
            payment: p,
            highlight: true,
          ),
          if (children.isNotEmpty)
            ...children.map(
              (c) => _chainRow(
                icon: Icons.call_split_rounded,
                color: Colors.green.shade700,
                label: 'Onward to',
                payment: c,
              ),
            ),
        ],
      ),
    );
  }

  Widget _chainRow({
    required IconData icon,
    required Color color,
    required String label,
    required PaymentEntry payment,
    bool highlight = false,
  }) {
    final controllerLocal = Get.find<DashboardController>();
    return InkWell(
      onTap: highlight
          ? null
          : () {
              Get.back();
              _showPaymentDetails(Get.context!, payment);
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: highlight ? color.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlight ? color.withOpacity(0.4) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${payment.displayId ?? 'PAY'} • ${payment.fromName} → ${payment.toName}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              controllerLocal.formatAmount(payment.amount),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            if (!highlight) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Colors.grey.shade500,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailPartyRow({
    required String label,
    required IconData icon,
    required Color color,
    required PartyType partyType,
    required String? partyId,
    required String partyName,
  }) {
    final canNavigate = partyType != PartyType.transaction || partyId != null;
    return InkWell(
      onTap: canNavigate ? () => _navigateToParty(partyType, partyId) : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partyName.isEmpty ? '—' : partyName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _typeLabel(partyType),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (canNavigate)
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  String _typeLabel(PartyType t) {
    switch (t) {
      case PartyType.normal:
        return 'Personal / Cash';
      case PartyType.company:
        return 'Partner';
      case PartyType.transaction:
        return 'Transaction';
    }
  }

  String _labelForParent(String parentId) {
    final t = controller.transactions.firstWhereOrNull((x) => x.id == parentId);
    if (t != null) {
      return '${t.displayId ?? 'TXN'} • ${t.description ?? 'Normal'}';
    }
    final ct = controller.companyTransactions.firstWhereOrNull(
      (x) => x.id == parentId,
    );
    if (ct != null) {
      return '${ct.displayId ?? 'COMP'} • ${ct.companyName}';
    }
    return parentId;
  }

  void _navigateToParty(PartyType type, String? id) {
    if (type == PartyType.normal) {
      controller.selectedCompanyId.value = normalTransactionsId;
      return;
    }
    if (type == PartyType.company && id != null) {
      controller.selectedCompanyId.value = id;
      return;
    }
    if (type == PartyType.transaction && id != null) {
      if (controller.transactions.any((t) => t.id == id)) {
        controller.selectedCompanyId.value = normalTransactionsId;
        return;
      }
      final ct = controller.companyTransactions.firstWhereOrNull(
        (x) => x.id == id,
      );
      if (ct != null) {
        controller.selectedCompanyId.value = ct.companyId;
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Get.back();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditNormalTransactionDialog(
    BuildContext context,
    Transaction transaction,
  ) {
    showDialog(
      context: context,
      builder: (_) => EditTransactionDialog(transaction: transaction),
    );
  }

  void _showEditCompanyTransactionDialog(
    BuildContext context,
    CompanyTransaction transaction,
  ) {
    showDialog(
      context: context,
      builder: (_) => EditCompanyTransactionDialog(transaction: transaction),
    );
  }
}

// ================= LEGACY COMPANY TRANSACTION CARD =================
class _LegacyCompanyTransactionCard extends StatelessWidget {
  final CompanyTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPay;

  const _LegacyCompanyTransactionCard({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final isReceived = transaction.type == TransactionType.received;
    final amountColor = isReceived
        ? Colors.green.shade600
        : Colors.red.shade600;
    final sign = isReceived ? '+' : '-';
    final isOverdue =
        (transaction.type == TransactionType.sent &&
        transaction.deadLine != null &&
        transaction.deadLine!.isBefore(DateTime.now()));
    final netOwed = controller.getCompanyNetObligation(transaction.companyId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (transaction.displayId != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          transaction.displayId!,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      transaction.companyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.description ?? 'No description',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.swap_horiz_rounded,
                  color: Colors.indigo.shade600,
                ),
                onPressed: onPay,
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.grey.shade700),
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.grey.shade700),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy • hh:mm a').format(transaction.date),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: amountColor.withOpacity(0.3)),
                ),
                child: Text(
                  '$sign${controller.formatAmount(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
              ),
            ],
          ),
          if (transaction.type == TransactionType.sent &&
              transaction.deadLine != null) ...[
            const SizedBox(height: 8),
            Text(
              'Due: ${DateFormat('dd MMM yyyy').format(transaction.deadLine!)}',
              style: TextStyle(
                fontSize: 12,
                color: isOverdue ? Colors.red.shade700 : Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (netOwed > 0.01) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 14,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  'Owes: ${controller.formatAmount(netOwed)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ================= COMPANY PAYMENT CARD =================
class _CompanyPaymentCard extends StatelessWidget {
  final PaymentEntry payment;
  final List<PaymentNode> subTree;
  final Transaction? rootNormal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CompanyPaymentCard({
    required this.payment,
    required this.subTree,
    this.rootNormal,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final isChained = payment.sourcePaymentId != null;
    final hasChildren = subTree.isNotEmpty;
    final netOwed = controller.getNetObligationForBranch(payment.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isChained
            ? LinearGradient(
                colors: [Colors.amber.shade50, Colors.amber.shade100],
              )
            : LinearGradient(
                colors: [
                  Colors.indigo.shade50,
                  Colors.indigo.shade50.withOpacity(0.4),
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isChained ? Colors.amber.shade400 : Colors.indigo.shade200,
          width: isChained ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (payment.displayId != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    payment.displayId!,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                'Transfer',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                              if (isChained) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.link_rounded,
                                  size: 12,
                                  color: Colors.amber.shade700,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${payment.fromName} → ${payment.toName}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (rootNormal != null)
                            Text(
                              'Root: ${rootNormal!.displayId ?? rootNormal!.description ?? 'Normal'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          if (netOwed > 0.01) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 14,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Owes: ${controller.formatAmount(netOwed)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.grey.shade700),
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy • hh:mm a').format(payment.date),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      controller.formatAmount(payment.amount),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (hasChildren) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 4),
                  _PaymentTreeViewWithActions(
                    nodes: subTree,
                    depth: 1,
                    rootTransactionId: payment.id,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= ROOT TRANSACTION CARD =================
class _RootTransactionCard extends StatefulWidget {
  final Transaction transaction;
  final List<PaymentNode> paymentTree;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPay;

  const _RootTransactionCard({
    required this.transaction,
    required this.paymentTree,
    required this.onEdit,
    required this.onDelete,
    required this.onPay,
  });

  @override
  State<_RootTransactionCard> createState() => _RootTransactionCardState();
}

class _RootTransactionCardState extends State<_RootTransactionCard> {
  bool _expanded = false;

  Map<String, double> _computeTotals() {
    double totalSent = 0.0;
    double totalReceived = 0.0;

    void traverse(List<PaymentNode> nodes) {
      for (final node in nodes) {
        final p = node.payment;
        final isFromNormal =
            p.fromType == PartyType.normal ||
            (p.fromType == PartyType.transaction &&
                Get.find<DashboardController>().transactions.any(
                  (t) => t.id == p.fromId,
                ));
        final isToNormal =
            p.toType == PartyType.normal ||
            (p.toType == PartyType.transaction &&
                Get.find<DashboardController>().transactions.any(
                  (t) => t.id == p.toId,
                ));

        if (isFromNormal && !isToNormal) totalSent += p.amount;
        if (!isFromNormal && isToNormal) totalReceived += p.amount;

        traverse(node.children);
      }
    }

    traverse(widget.paymentTree);
    return {'sent': totalSent, 'received': totalReceived};
  }

  bool _hasOverdueBranch(List<PaymentNode> nodes) {
    for (final node in nodes) {
      final p = node.payment;
      final isOverdue =
          p.deadline != null && p.deadline!.isBefore(DateTime.now());
      if (isOverdue) {
        final netObligation = Get.find<DashboardController>()
            .getNetObligationForBranch(p.id);
        if (netObligation > 0.01) return true;
      }
      if (_hasOverdueBranch(node.children)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final hasTree = widget.paymentTree.isNotEmpty;
    final amountColor = Colors.green.shade600;
    final totals = _computeTotals();
    final totalSent = totals['sent']!;
    final totalReceived = totals['received']!;
    final netFlow = totalReceived - totalSent;
    final currentAmount = controller.getCurrentAmount(widget.transaction.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.transaction.displayId != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.transaction.displayId!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (_hasOverdueBranch(widget.paymentTree))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 12,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Overdue',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.transaction.description ?? 'Cash Received',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.transaction.source ?? 'No source',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.swap_horiz_rounded,
                  color: Colors.indigo.shade600,
                ),
                onPressed: widget.onPay,
                tooltip: 'Pay / Transfer',
              ),
              IconButton(
                icon: Icon(
                  Icons.account_tree_rounded,
                  color: Colors.green.shade700,
                ),
                onPressed: () => Get.to(
                  () => PaymentChainScreen(
                    rootTransaction: widget.transaction,
                    paymentTree: widget.paymentTree,
                  ),
                ),
                tooltip: 'View full chain',
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.grey.shade700),
                onPressed: widget.onEdit,
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.grey.shade700),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat(
                  'dd MMM yyyy • hh:mm a',
                ).format(widget.transaction.date),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: amountColor.withOpacity(0.3)),
                ),
                child: Text(
                  '+${controller.formatAmount(widget.transaction.amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statChip('Total Sent', totalSent, Colors.red.shade600),
                    _statChip(
                      'Total Received',
                      totalReceived,
                      Colors.green.shade600,
                    ),
                    _statChip(
                      'Net Flow',
                      netFlow,
                      netFlow >= 0
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                      prefix: netFlow >= 0 ? '+' : '',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 16,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Current balance: ${controller.formatAmount(currentAmount)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // New: per‑company breakdown
          if (controller
              .getNetOwedPerCompanyFromRoot(widget.transaction.id)
              .isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Amounts owed to you:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: controller
                      .getNetOwedPerCompanyFromRoot(widget.transaction.id)
                      .entries
                      .map((entry) {
                        final company = controller.companies.firstWhereOrNull(
                          (c) => c.id == entry.key,
                        );
                        final companyName = company?.name ?? entry.key;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '$companyName: ${controller.formatAmount(entry.value)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Text(
            'Cash: ${widget.transaction.isCash ? 'Yes' : 'No'} • Ref: ${widget.transaction.referenceNumber ?? 'N/A'}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          if (hasTree) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.indigo.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Payment tree (${_countNodes(widget.paymentTree)})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (_expanded)
              _PaymentTreeViewWithActions(
                nodes: widget.paymentTree,
                depth: 0,
                rootTransactionId: widget.transaction.id,
              ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(
    String label,
    double value,
    Color color, {
    String prefix = '',
  }) {
    final controller = Get.find<DashboardController>();
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$prefix${controller.formatAmount(value)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  int _countNodes(List<PaymentNode> nodes) {
    int count = nodes.length;
    for (final n in nodes) count += _countNodes(n.children);
    return count;
  }
}

// ================= TAPPABLE PAYMENT NODE (with deadline) =================
class _TappablePaymentNode extends StatelessWidget {
  final PaymentNode node;
  final int depth;
  final String rootTransactionId;

  const _TappablePaymentNode({
    required this.node,
    required this.depth,
    required this.rootTransactionId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final payment = node.payment;
    final isOverdue =
        payment.deadline != null && payment.deadline!.isBefore(DateTime.now());
    final netObligation = controller.getNetObligationForBranch(payment.id);
    final showDueBadge = isOverdue && netObligation > 0.01;

    Color cardColor = Colors.white;
    if (showDueBadge) cardColor = Colors.red.shade50;

    return Container(
      margin: EdgeInsets.only(left: depth * 16.0, top: 8),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _showPaymentDetails(context, payment),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: showDueBadge
                    ? Colors.red.shade300
                    : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${payment.fromName} → ${payment.toName}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      controller.formatAmount(payment.amount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(payment.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (showDueBadge)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 12,
                              color: Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Due',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentDetails(BuildContext context, PaymentEntry payment) {
    final controller = Get.find<DashboardController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      payment.displayId ?? 'Transfer',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _detailRow('From', payment.fromName),
                _detailRow('To', payment.toName),
                _detailRow('Amount', controller.formatAmount(payment.amount)),
                _detailRow(
                  'Date',
                  DateFormat('dd MMM yyyy • hh:mm a').format(payment.date),
                ),
                if (payment.deadline != null)
                  _detailRow(
                    'Deadline',
                    DateFormat('dd MMM yyyy').format(payment.deadline!),
                  ),
                if (payment.description != null &&
                    payment.description!.isNotEmpty)
                  _detailRow('Description', payment.description!),
                if (payment.paymentMethod != null &&
                    payment.paymentMethod!.isNotEmpty)
                  _detailRow('Method', payment.paymentMethod!),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.back();
                          showDialog(
                            context: context,
                            builder: (_) =>
                                AddPaymentDialog(paymentToEdit: payment),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.back();
                          _confirmDelete(context, payment);
                        },
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, PaymentEntry payment) {
    final controller = Get.find<DashboardController>();
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Payment'),
        content: Text(
          'Delete ${payment.displayId ?? 'this payment'}? This may affect chain balances.',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deletePayment(payment.id);
              Get.back();
              Get.back(); // close bottom sheet if open
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ================= TREE VIEW WITH ACTIONS (scrollable) =================
class _PaymentTreeViewWithActions extends StatelessWidget {
  final List<PaymentNode> nodes;
  final int depth;
  final String rootTransactionId;

  const _PaymentTreeViewWithActions({
    required this.nodes,
    required this.depth,
    required this.rootTransactionId,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: Get.height * 0.5),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: nodes.map((node) => _buildNode(node)).toList(),
        ),
      ),
    );
  }

  Widget _buildNode(PaymentNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TappablePaymentNode(
          node: node,
          depth: depth,
          rootTransactionId: rootTransactionId,
        ),
        if (node.children.isNotEmpty)
          _PaymentTreeViewWithActions(
            nodes: node.children,
            depth: depth + 1,
            rootTransactionId: rootTransactionId,
          ),
      ],
    );
  }
}

// Helper class for date sorting
class _HistoryItem {
  final DateTime date;
  final Widget widget;
  _HistoryItem({required this.date, required this.widget});
}
