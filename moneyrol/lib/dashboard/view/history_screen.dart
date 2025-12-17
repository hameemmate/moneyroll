import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';
import 'package:moneyrol/dashboard/model/company_model.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/model/transation_model.dart';
import 'package:moneyrol/dashboard/view/widgets/edit_company_transation_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/edit_transation_dialog.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  final DashboardController controller = Get.find();

  static const String allCompaniesId = 'all';
  static const String normalTransactionsId = 'normal';

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(title: const Text('Transaction History')),
        body: Column(
          children: [
            _buildCompanyFilterList(),
            _buildSummaryCard(),
            Expanded(
              child: controller.selectedCompanyId.value == normalTransactionsId
                  ? _buildNormalTransactionsList(context)
                  : _buildCompanyTransactionsList(context),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- FILTER CHIPS ----------------

  Widget _buildCompanyFilterList() {
    return Obx(() {
      final theme = Get.theme;
      final companies = controller.companies;

      final options = [
        {'id': allCompaniesId, 'name': 'All Partners'},
        {'id': normalTransactionsId, 'name': 'Normal Income'},
        ...companies.map((c) => {'id': c.id, 'name': c.name}),
      ];

      return SizedBox(
        height: 52,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: options.length,
          itemBuilder: (_, i) {
            final opt = options[i];
            final isSelected = controller.selectedCompanyId.value == opt['id'];

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: isSelected
                    ? theme.primaryColor
                    : theme.colorScheme.surfaceVariant,
                label: Text(
                  opt['name'] ?? "",
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.textTheme.bodyMedium?.color,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onPressed: () =>
                    controller.selectedCompanyId.value = opt['id'] ?? "",
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
      final theme = Get.theme;

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

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  _summaryItem(
                    'Received',
                    received,
                    theme.colorScheme.secondary,
                  ),
                  _summaryItem(
                    'Sent',
                    sent,
                    isNormal ? theme.disabledColor : theme.colorScheme.error,
                  ),
                  _summaryItem(
                    'Net',
                    balance,
                    balance >= 0
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.error,
                  ),
                ],
              ),
            ],
          ),
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
          Text(label, style: Get.theme.textTheme.bodySmall),
          const SizedBox(height: 8),

          // Amount container (NO OVERFLOW EVER)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${controller.selectedCurrency.value.symbol}'
                '${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18, // base size
                  fontWeight: FontWeight.bold,
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

    return _buildTransactionList(
      transactions.map((t) {
        return _TransactionCard(
          title: t.description ?? 'Cash Received',
          subtitle: t.source ?? 'No source',
          date: t.date,
          amount: t.amount,
          isPositive: true,
          extraInfo:
              '${t.isCash ? 'Cash' : 'Bank'} • Ref: ${t.referenceNumber ?? 'N/A'}',
          onEdit: () => _showEditNormalTransactionDialog(context, t),
          onDelete: () => _showDeleteConfirmation(
            context,
            () => controller.deleteTransaction(t.id),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompanyTransactionsList(BuildContext context) {
    final transactions = controller.getFilteredCompanyTransactions();

    return _buildTransactionList(
      transactions.map((ct) {
        return _TransactionCard(
          title: ct.companyName,
          subtitle: ct.description ?? 'No description',
          date: ct.date,
          amount: ct.amount,
          isPositive: ct.type == TransactionType.received,
          extraInfo:
              'Invoice: ${ct.invoiceNumber ?? 'N/A'} • ${ct.paymentMethod ?? 'N/A'}',
          onEdit: () => _showEditCompanyTransactionDialog(context, ct),
          onDelete: () => _showDeleteConfirmation(
            context,
            () => controller.deleteCompanyTransaction(ct.id),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionList(List<Widget> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Get.theme.iconTheme.color?.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No transactions found',
              style: Get.theme.textTheme.bodyMedium,
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
          'Are you sure you want to delete this transaction?',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              onConfirm();
              Get.back();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Get.theme.colorScheme.error),
            ),
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

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.isPositive,
    required this.onDelete,
    required this.onEdit,
    required this.extraInfo,
  });

  final String title;
  final String subtitle;
  final DateTime date;
  final double amount;
  final bool isPositive;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final String extraInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Get.theme;
    final controller = Get.find<DashboardController>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: theme.primaryColor),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: theme.colorScheme.error),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy • hh:mm a').format(date),
                  style: theme.textTheme.bodySmall,
                ),
                IntrinsicWidth(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (isPositive
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.error)
                              .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${isPositive ? '+' : '-'}'
                        '${controller.selectedCurrency.value.symbol}'
                        '${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18, // safe base size
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 6),
            Text(extraInfo, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
