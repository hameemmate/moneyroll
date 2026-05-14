import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/constants/app_constants.dart';

import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';
import 'package:moneyrol/dashboard/model/company_model.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/model/payment_entry_model.dart';
import 'package:moneyrol/dashboard/model/transation_model.dart';
import 'package:moneyrol/dashboard/view/widgets/add_payment_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/edit_company_transation_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/edit_transation_dialog.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  final DashboardController controller = Get.find();

  static const String allCompaniesId = 'all';
  static const String normalTransactionsId = 'normal';

  // Color constants

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

  // ---------------- FILTER CHIPS ----------------

  Widget _buildCompanyFilterList() {
    return Obx(() {
      final companies = controller.companies;

      final options = [
        {'id': allCompaniesId, 'name': 'All Partners'},
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

  // ---------------- SUMMARY CARD ----------------

  Widget _buildSummaryCard() {
    return Obx(() {
      final received = controller.getSelectedTotalReceived();
      final sent = controller.getSelectedTotalSent();
      final balance = received - sent;

      final isNormal =
          controller.selectedCompanyId.value == normalTransactionsId;

      String title;
      if (controller.selectedCompanyId.value == allCompaniesId) {
        title = 'Total Partners Balance';
      } else if (isNormal) {
        title = 'Total Normal Income';
      } else {
        final company = controller.companies.firstWhereOrNull(
          (c) => c.id == controller.selectedCompanyId.value,
        );
        title = '${company?.name ?? 'Company'} Balance';
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.textColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _summaryItem('Received', received, AppConstants.successColor),
                _summaryItem(
                  'Sent',
                  sent,
                  isNormal ? Colors.grey : AppConstants.errorColor,
                ),
                _summaryItem(
                  'Net',
                  balance,
                  balance >= 0
                      ? AppConstants.successColor
                      : AppConstants.errorColor,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _summaryItem(String label, double amount, Color color) {
    final controller = Get.find<DashboardController>();

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
                '${controller.selectedCurrency.value.symbol}'
                '${amount.toStringAsFixed(2)}',
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

  // ---------------- TRANSACTION LISTS ----------------

  Widget _buildNormalTransactionsList(BuildContext context) {
    final transactions = controller.getFilteredNormalTransactions();
    final filteredPayments = controller.getFilteredPayments();

    // Build a single chronological feed: normal-transaction cards + payment
    // cards involving Normal. Each item carries its date so we can sort the
    // combined list newest-first regardless of source.
    final items = <_HistoryItem>[
      ...transactions.map(
        (t) => _HistoryItem(
          date: t.date,
          widget: _TransactionCard(
            displayId: t.displayId,
            parentId: t.id,
            title: t.description ?? 'Cash Received',
            subtitle: t.source ?? 'No source',
            date: t.date,
            amount: t.amount,
            currentAmount: controller.getCurrentAmount(t.id),
            isPositive: true,
            extraInfo:
                '${t.isCash ? 'Cash' : 'Bank'} • Ref: ${t.referenceNumber ?? 'N/A'}',
            onEdit: () => _showEditNormalTransactionDialog(context, t),
            onDelete: () => _showDeleteConfirmation(
              context,
              () => controller.deleteTransaction(t.id),
            ),
            onPay: () => _openPayDialog(
              context,
              toType: PartyType.transaction,
              toId: t.id,
              toName: t.displayId ?? t.description ?? 'Transaction',
            ),
          ),
        ),
      ),
      ...filteredPayments.map(
        (p) => _HistoryItem(
          date: p.date,
          widget: _PaymentCard(
            payment: p,
            // Sign convention for the Normal feed: green when money landed
            // in Normal, red when it left Normal.
            isPositiveFromSelectedPartyPov: p.toType == PartyType.normal,
            onDelete: () => _showDeleteConfirmation(
              context,
              () => controller.deletePayment(p.id),
            ),
          ),
        ),
      ),
    ];

    items.sort((a, b) => b.date.compareTo(a.date));
    return _buildTransactionList(items.map((i) => i.widget).toList());
  }

  Widget _buildCompanyTransactionsList(BuildContext context) {
    final transactions = controller.getFilteredCompanyTransactions();
    final filteredPayments = controller.getFilteredPayments();
    final selectedCompany = controller.selectedCompanyId.value;

    final items = <_HistoryItem>[
      ...transactions.map(
        (ct) => _HistoryItem(
          date: ct.date,
          widget: _TransactionCard(
            displayId: ct.displayId,
            parentId: ct.id,
            title: ct.companyName,
            subtitle: ct.description ?? 'No description',
            date: ct.date,
            amount: ct.amount,
            currentAmount: controller.getCurrentAmount(ct.id),
            isPositive: ct.type == TransactionType.received,
            extraInfo: _buildCompanyExtraInfo(ct),
            onEdit: () => _showEditCompanyTransactionDialog(context, ct),
            onDelete: () => _showDeleteConfirmation(
              context,
              () => controller.deleteCompanyTransaction(ct.id),
            ),
            onPay: () => _openPayDialog(
              context,
              toType: PartyType.transaction,
              toId: ct.id,
              toName: ct.displayId ?? ct.companyName,
            ),
          ),
        ),
      ),
      ...filteredPayments.map((p) {
        // Sign convention for company feed: from the selected company's POV
        // (or Normal's POV when "all" is selected) — green if that side
        // received money, red if it sent it.
        bool isPositive;
        if (selectedCompany == 'all') {
          isPositive = p.toType == PartyType.normal;
        } else {
          // Company is "from" -> the company sent it OUT (positive in
          // user's books = received from company).
          isPositive =
              p.fromType == PartyType.company && p.fromId == selectedCompany;
        }
        return _HistoryItem(
          date: p.date,
          widget: _PaymentCard(
            payment: p,
            isPositiveFromSelectedPartyPov: isPositive,
            onDelete: () => _showDeleteConfirmation(
              context,
              () => controller.deletePayment(p.id),
            ),
          ),
        );
      }),
    ];

    items.sort((a, b) => b.date.compareTo(a.date));
    return _buildTransactionList(items.map((i) => i.widget).toList());
  }

  void _openPayDialog(
    BuildContext context, {
    required PartyType toType,
    required String? toId,
    required String toName,
  }) {
    showDialog(
      context: context,
      builder: (_) => AddPaymentDialog(
        prefilledTo: PartySelection(type: toType, id: toId, name: toName),
      ),
    );
  }

  String _buildCompanyExtraInfo(CompanyTransaction ct) {
    String base =
        'Invoice: ${ct.invoiceNumber ?? 'N/A'} • ${ct.paymentMethod ?? 'N/A'}';

    // Only sent transactions can have deadline
    if (ct.type == TransactionType.sent && ct.deadLine != null) {
      final now = DateTime.now();
      final deadline = ct.deadLine!;

      final isOverdue = deadline.isBefore(
        DateTime(now.year, now.month, now.day),
      );

      final deadlineText = DateFormat('dd MMM yyyy').format(deadline);

      if (isOverdue) {
        return '$base • ⚠ Overdue (Due $deadlineText)';
      } else {
        return '$base • Due $deadlineText';
      }
    }

    return base;
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

  // ---------------- DIALOG HELPERS ----------------

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

// ================= TRANSACTION CARD =================

class _TransactionCard extends StatefulWidget {
  const _TransactionCard({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.isPositive,
    required this.onDelete,
    required this.onEdit,
    required this.extraInfo,
    this.displayId,
    this.parentId,
    this.currentAmount,
    this.onPay,
  });

  final String title;
  final String subtitle;
  final DateTime date;
  final double amount;
  final bool isPositive;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final String extraInfo;
  // New optional fields for the payment-ledger features.
  final String? displayId;
  final String? parentId;
  final double? currentAmount;
  final VoidCallback? onPay;

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.extraInfo.contains('Overdue');
    final controller = Get.find<DashboardController>();
    final amountColor = widget.isPositive
        ? Colors.green.shade600
        : Colors.red.shade600;

    // Linked payments for this transaction (may be empty).
    final List<PaymentEntry> linkedPayments = widget.parentId == null
        ? const []
        : controller.getPaymentsForTransaction(widget.parentId!);
    final hasPayments = linkedPayments.isNotEmpty;

    // Show the current/remaining balance only when it actually differs from
    // the original — otherwise the row stays clean.
    final showCurrent =
        widget.currentAmount != null &&
        (widget.currentAmount! - widget.amount).abs() > 0.005;

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
                    if (widget.displayId != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          widget.displayId!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.onPay != null)
                IconButton(
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.indigo.shade600,
                  ),
                  tooltip: 'Pay / Transfer',
                  onPressed: widget.onPay,
                  splashRadius: 20,
                ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.grey.shade700),
                onPressed: widget.onEdit,
                splashRadius: 20,
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.grey.shade700),
                onPressed: widget.onDelete,
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy • hh:mm a').format(widget.date),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
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
                  '${widget.isPositive ? '+' : '-'}'
                  '${controller.selectedCurrency.value.symbol}'
                  '${widget.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
              ),
            ],
          ),
          if (showCurrent) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 14,
                        color: Colors.indigo.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Current balance',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    controller.formatAmount(widget.currentAmount!),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 8),
          Text(
            widget.extraInfo,
            style: TextStyle(
              fontSize: 13,
              color: isOverdue ? Colors.red.shade600 : Colors.grey.shade600,
              fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (hasPayments) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: Colors.indigo.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Linked payments (${linkedPayments.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Column(
                children: linkedPayments
                    .map(
                      (p) =>
                          _PaymentRow(payment: p, parentId: widget.parentId!),
                    )
                    .toList(),
              ),
          ],
        ],
      ),
    );
  }
}

// Single row in the linked-payments expansion. Shows direction relative to
// the parent transaction so the user instantly knows whether this payment
// added to or subtracted from the parent's balance.
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, required this.parentId});

  final PaymentEntry payment;
  final String parentId;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final isParentIncoming =
        payment.toType == PartyType.transaction && payment.toId == parentId;
    final isParentOutgoing =
        payment.fromType == PartyType.transaction && payment.fromId == parentId;
    final color = isParentIncoming
        ? Colors.green.shade700
        : (isParentOutgoing ? Colors.red.shade700 : Colors.grey.shade700);
    final sign = isParentIncoming ? '+' : (isParentOutgoing ? '-' : '');

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (payment.displayId != null) ...[
                Text(
                  payment.displayId!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  '${payment.fromName} → ${payment.toName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$sign${controller.formatAmount(payment.amount)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _confirmDelete(context, controller, payment.id),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${DateFormat('dd MMM yyyy • hh:mm a').format(payment.date)}'
            '${payment.paymentMethod != null ? ' • ${payment.paymentMethod}' : ''}'
            '${payment.description != null && payment.description!.isNotEmpty ? ' • ${payment.description}' : ''}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    DashboardController controller,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text(
          'Remove this linked payment? The parent transaction\'s balance will recalculate.',
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              controller.deletePayment(id);
              Get.back();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Lightweight envelope used to sort heterogeneous history rows by date
// before rendering.
class _HistoryItem {
  final DateTime date;
  final Widget widget;
  _HistoryItem({required this.date, required this.widget});
}

// Card representation of a standalone PaymentEntry in the main history
// feed. Shown alongside transaction cards so the user sees a single
// chronological view of everything that touched the selected party.
class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.isPositiveFromSelectedPartyPov,
    required this.onDelete,
  });

  final PaymentEntry payment;
  // Drives the amount color and the +/- prefix. True when the selected
  // filter party received money in this payment, false when it sent.
  final bool isPositiveFromSelectedPartyPov;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final amountColor = isPositiveFromSelectedPartyPov
        ? Colors.green.shade600
        : Colors.red.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Indigo border so transfer cards visually distinguish from the
        // transaction cards without being noisy.
        border: Border.all(color: Colors.indigo.shade100),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: Colors.indigo.shade700,
                ),
              ),
              const SizedBox(width: 8),
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
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.indigo.shade100),
                            ),
                            child: Text(
                              payment.displayId!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.indigo.shade800,
                                letterSpacing: 0.5,
                              ),
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
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${payment.fromName} → ${payment.toName}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.grey.shade700),
                onPressed: onDelete,
                splashRadius: 20,
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
                  fontWeight: FontWeight.w500,
                ),
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
                  '${isPositiveFromSelectedPartyPov ? '+' : '-'}'
                  '${controller.formatAmount(payment.amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
              ),
            ],
          ),
          if ((payment.paymentMethod != null &&
                  payment.paymentMethod!.isNotEmpty) ||
              (payment.description != null &&
                  payment.description!.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 8),
            Text(
              _buildSubLine(),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  String _buildSubLine() {
    final parts = <String>[];
    if (payment.paymentMethod != null && payment.paymentMethod!.isNotEmpty) {
      parts.add(payment.paymentMethod!);
    }
    if (payment.description != null && payment.description!.isNotEmpty) {
      parts.add(payment.description!);
    }
    return parts.join(' • ');
  }
}
