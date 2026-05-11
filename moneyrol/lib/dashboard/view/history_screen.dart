import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/constants/app_constants.dart';

import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';
import 'package:moneyrol/dashboard/model/company_model.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/model/transation_model.dart';
import 'package:moneyrol/dashboard/view/partner_to_partner_transfer_screen.dart';
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
            ' History',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton.icon(
                onPressed: () {
                  Get.to(() => PartnerToPartnerTransfersScreen());
                },
                icon: Icon(
                  Icons.swap_horiz,
                  color: AppConstants.cardColor,
                  size: 18,
                ),
                label: Text(
                  'Partner to Partner',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.backgroundColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  backgroundColor: AppConstants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
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
    final transactions = controller.getFilteredCompanyTransactions().where((
      ct,
    ) {
      // Skip auto-generated entries
      if (ct.id.endsWith('_received')) return false;

      // For History screen, only show transactions that involve normal account
      // EXCLUDE all company-to-company transactions (sourceType == company)
      if (ct.sourceType == SourceType.company) {
        return false; // Company-to-company transfers go to PartnerToPartnerTransfersScreen
      }

      return true;
    }).toList();

    return _buildTransactionList(
      transactions.map((ct) {
        final isReceived = ct.type == TransactionType.received;
        return _TransactionCard(
          title: isReceived
              ? 'Received from ${ct.companyName}'
              : 'Sent to ${ct.companyName}',
          subtitle:
              ct.description ??
              (isReceived ? 'Income received' : 'Payment sent'),
          date: ct.date,
          amount: ct.amount,
          isPositive: isReceived,
          extraInfo: _buildCompanyExtraInfo(ct),
          onEdit: () => _showEditCompanyTransactionDialog(context, ct),
          onDelete: () => _showDeleteConfirmation(
            context,
            () => controller.deleteCompanyTransaction(ct.id),
          ),
        );
      }).toList(),
    );
  }

  // Update the _buildCompanyExtraInfo method in HistoryScreen
  String _buildCompanyExtraInfo(CompanyTransaction ct) {
    String sourceInfo = '';

    if (ct.type == TransactionType.sent) {
      // This is money going OUT from normal account to partner
      sourceInfo = 'From: Normal Account → Partner • ';
    } else if (ct.type == TransactionType.received) {
      // This is money coming IN from partner to normal account
      if (ct.sourceType == SourceType.normal) {
        sourceInfo = 'From: Partner → Normal Account • ';
      } else {
        sourceInfo = 'Received from Partner • ';
      }
    }

    String base =
        '$sourceInfo'
        'Invoice: ${ct.invoiceNumber ?? 'N/A'} • '
        '${ct.paymentMethod ?? 'N/A'}';

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
    final isOverdue = extraInfo.contains('Overdue');
    final controller = Get.find<DashboardController>();
    final amountColor = isPositive
        ? Colors.green.shade600
        : Colors.red.shade600;

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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
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
              IconButton(
                icon: Icon(Icons.edit, color: Colors.grey.shade700),
                onPressed: onEdit,
                splashRadius: 20,
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.grey.shade700),
                onPressed: onDelete,
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy • hh:mm a').format(date),
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
                  '${isPositive ? '+' : '-'}'
                  '${controller.selectedCurrency.value.symbol}'
                  '${amount.toStringAsFixed(2)}',
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
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 8),

          Text(
            extraInfo,
            style: TextStyle(
              fontSize: 13,
              color: isOverdue ? Colors.red.shade600 : Colors.grey.shade600,
              fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
