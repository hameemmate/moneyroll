// partner_to_partner_transfers_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/constants/app_constants.dart';
import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/view/widgets/company_wise/company_tranfer_record_details_screen.dart';
import 'package:moneyrol/dashboard/view/widgets/company_wise/edit_partner_transfer_dialog.dart';

class PartnerToPartnerTransfersScreen extends StatelessWidget {
  PartnerToPartnerTransfersScreen({super.key});

  final DashboardController controller = Get.find();
  final RxString selectedCompanyId = 'all'.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Partner to Partner Transfers',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppConstants.cardColor,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(() => _buildCompanyFilterList()),
          Expanded(
            child: Obx(() {
              final transfers = _getFilteredTransfers();

              if (transfers.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  _buildSummaryCard(transfers),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: transfers.length,
                      itemBuilder: (context, index) {
                        final transfer = transfers[index];
                        return _TransferCard(
                          transfer: transfer,
                          onEdit: () =>
                              _showEditTransferDialog(context, transfer),
                          onDelete: () =>
                              _showDeleteConfirmation(context, transfer),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ==================== FILTER LIST ====================
  // ==================== FILTER LIST ====================
  Widget _buildCompanyFilterList() {
    // Get only root transfers
    final rootTransfers = controller.getCompanyToCompanyTransactions();

    // Get all unique companies involved in root transfers
    final involvedCompanies = <String, String>{};
    for (var transfer in rootTransfers) {
      involvedCompanies[transfer.companyId] = transfer.companyName;
      if (transfer.sourceCompanyId != null) {
        involvedCompanies[transfer.sourceCompanyId!] =
            transfer.sourceCompanyName ?? 'Unknown';
      }
    }

    // Build filter options
    final options = [
      {'id': 'all', 'name': 'All Partners'},
      ...involvedCompanies.entries.map(
        (entry) => {'id': entry.key, 'name': entry.value},
      ),
    ];

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        border: Border(
          bottom: BorderSide(color: AppConstants.borderColor, width: 1),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: options.length,
        itemBuilder: (_, i) {
          final opt = options[i];

          return Obx(() {
            final isSelected = selectedCompanyId.value == opt['id'];

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                showCheckmark: true,
                checkmarkColor: Colors.white,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (opt['id'] == 'all')
                      Icon(
                        Icons.people,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : AppConstants.primaryColor,
                      )
                    else
                      Icon(
                        Icons.business,
                        size: 14,
                        color: isSelected
                            ? Colors.white
                            : AppConstants.primaryColor,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      opt['name'] ?? "",
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppConstants.textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) {
                  selectedCompanyId.value = opt['id'] ?? "";
                },
                selectedColor: AppConstants.primaryColor,
                backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  // ==================== FILTER LOGIC ====================
  List<CompanyTransaction> _getFilteredTransfers() {
    // Get only root transfers (not payments from records)
    final allTransfers = controller.getCompanyToCompanyTransactions();

    if (selectedCompanyId.value == 'all') {
      allTransfers.sort((a, b) => b.date.compareTo(a.date));
      return allTransfers;
    }

    final filtered = allTransfers.where((transfer) {
      return transfer.companyId == selectedCompanyId.value ||
          transfer.sourceCompanyId == selectedCompanyId.value;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  // ==================== SUMMARY STATS ====================
  double _getTotalTransferred(List<CompanyTransaction> transfers) {
    return transfers.fold(0.0, (sum, t) => sum + t.amount);
  }

  double _getAverageTransfer(List<CompanyTransaction> transfers) {
    return transfers.isNotEmpty
        ? _getTotalTransferred(transfers) / transfers.length
        : 0.0;
  }

  double _getLargestTransfer(List<CompanyTransaction> transfers) {
    if (transfers.isEmpty) return 0.0;
    return transfers.map((t) => t.amount).reduce((a, b) => a > b ? a : b);
  }

  // ==================== UI COMPONENTS ====================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.swap_horiz,
              size: 64,
              color: AppConstants.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Partner to Partner Transfers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you transfer money between partners,\nit will appear here',
            style: TextStyle(fontSize: 14, color: AppConstants.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<CompanyTransaction> transfers) {
    final totalTransferred = _getTotalTransferred(transfers);
    final averageTransfer = _getAverageTransfer(transfers);
    final largestTransfer = _getLargestTransfer(transfers);
    final isFiltered = selectedCompanyId.value != 'all';
    final selectedCompany = controller.companies.firstWhereOrNull(
      (c) => c.id == selectedCompanyId.value,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor.withOpacity(0.05),
            AppConstants.primaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.swap_horiz,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFiltered
                          ? 'Partner Transfer Summary'
                          : 'Total Transferred',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(
                      () => Text(
                        '${controller.currencySymbol}${totalTransferred.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Number of Transfers',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transfers.length}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isFiltered && selectedCompany != null) ...[
            const SizedBox(height: 12),
            Divider(color: AppConstants.borderColor),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Received',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.incomeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Obx(
                          () => Text(
                            '${controller.currencySymbol}${_getIncomingAmount(transfers, selectedCompany.id).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.incomeColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Sent',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.expenseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Obx(
                          () => Text(
                            '${controller.currencySymbol}${_getOutgoingAmount(transfers, selectedCompany.id).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.expenseColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Net',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Obx(() {
                          final net =
                              _getIncomingAmount(
                                transfers,
                                selectedCompany.id,
                              ) -
                              _getOutgoingAmount(transfers, selectedCompany.id);
                          return Text(
                            '${controller.currencySymbol}${net.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: net >= 0
                                  ? AppConstants.incomeColor
                                  : AppConstants.expenseColor,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Divider(color: AppConstants.borderColor),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Average Transfer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () => Text(
                          '${controller.currencySymbol}${averageTransfer.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Largest Transfer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () => Text(
                          '${controller.currencySymbol}${largestTransfer.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  double _getIncomingAmount(
    List<CompanyTransaction> transfers,
    String companyId,
  ) {
    return transfers
        .where((t) => t.companyId == companyId)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _getOutgoingAmount(
    List<CompanyTransaction> transfers,
    String companyId,
  ) {
    return transfers
        .where((t) => t.sourceCompanyId == companyId)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: Row(
          children: [
            Icon(Icons.swap_horiz, color: AppConstants.primaryColor),
            const SizedBox(width: 8),
            const Text(
              'About Partner Transfers',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Partner to Partner transfers allow you to:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Transfer money between partners'),
            _buildBulletPoint(
              'Track money movement without affecting normal account',
            ),
            _buildBulletPoint('Add deadlines for repayments'),
            _buildBulletPoint('Keep detailed records with invoices'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Tip:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Use the filter chips above to view transfers for specific partners.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Got it')),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: AppConstants.primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _showEditTransferDialog(
    BuildContext context,
    CompanyTransaction transfer,
  ) {
    showDialog(
      context: context,
      builder: (_) => EditPartnerTransferDialog(transfer: transfer),
    ).then((_) {
      controller.refreshData();
    });
  }

  void _showDeleteConfirmation(
    BuildContext context,
    CompanyTransaction transfer,
  ) {
    final controller = Get.find<DashboardController>();

    // Check if this transfer has any linked payments/receipts
    final recordId = transfer.recordId ?? transfer.id;
    final linkedPayments = controller.getPaymentsFromRecord(recordId);
    final linkedReceipts = controller.getReceiptsFromRecord(recordId);
    final hasLinkedTransactions =
        linkedPayments.isNotEmpty || linkedReceipts.isNotEmpty;

    final linkedCount = linkedPayments.length + linkedReceipts.length;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        title: const Text('Delete Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this transfer?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${transfer.sourceCompanyName} → ${transfer.companyName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      'Amount: ${controller.currencySymbol}${transfer.amount.toStringAsFixed(2)}',
                    ),
                  ),
                  if (transfer.description != null) ...[
                    const SizedBox(height: 4),
                    Text('Description: ${transfer.description}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (hasLinkedTransactions) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppConstants.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppConstants.errorColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Linked Transactions Found!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.errorColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This record has $linkedCount transaction(s) linked to it:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.errorColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (linkedPayments.isNotEmpty)
                      Text(
                        '• ${linkedPayments.length} payment(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppConstants.errorColor,
                        ),
                      ),
                    if (linkedReceipts.isNotEmpty)
                      Text(
                        '• ${linkedReceipts.length} receipt(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppConstants.errorColor,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Deleting this record will also delete ALL linked transactions.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteCompanyTransaction(transfer.id);
              Get.back();
              Get.snackbar(
                'Deleted',
                hasLinkedTransactions
                    ? 'Transfer and $linkedCount linked transaction(s) deleted successfully'
                    : 'Transfer deleted successfully',
                backgroundColor: AppConstants.errorColor,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ================= TRANSFER CARD =================
class _TransferCard extends StatelessWidget {
  const _TransferCard({
    required this.transfer,
    required this.onEdit,
    required this.onDelete,
  });

  final CompanyTransaction transfer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final isOverdue =
        transfer.deadLine != null &&
        transfer.deadLine!.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? AppConstants.errorColor : AppConstants.borderColor,
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TransferRecordDetailSheet(rootTransfer: transfer),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? AppConstants.errorColor.withOpacity(0.1)
                            : AppConstants.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.swap_horiz,
                        color: isOverdue
                            ? AppConstants.errorColor
                            : AppConstants.primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${transfer.sourceCompanyName ?? "Unknown"} → ${transfer.companyName}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: AppConstants.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy • hh:mm a',
                                ).format(transfer.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppConstants.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.expenseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppConstants.expenseColor.withOpacity(0.3),
                            ),
                          ),
                          child: Obx(
                            () => Text(
                              '-${controller.currencySymbol}${transfer.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppConstants.expenseColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 10,
                                  color: AppConstants.errorColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Overdue',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppConstants.errorColor,
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
                if (transfer.description != null ||
                    transfer.invoiceNumber != null ||
                    transfer.paymentMethod != null ||
                    transfer.deadLine != null) ...[
                  const SizedBox(height: 12),
                  Divider(color: AppConstants.borderColor),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (transfer.description != null)
                        _buildInfoChip(
                          Icons.description,
                          transfer.description!,
                        ),
                      if (transfer.invoiceNumber != null)
                        _buildInfoChip(
                          Icons.receipt,
                          'Inv: ${transfer.invoiceNumber}',
                        ),
                      if (transfer.paymentMethod != null)
                        _buildInfoChip(Icons.payment, transfer.paymentMethod!),
                      if (transfer.deadLine != null)
                        _buildDeadlineChip(transfer.deadLine!),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit,
                        size: 18,
                        color: AppConstants.textSecondary,
                      ),
                      label: Text(
                        'Edit',
                        style: TextStyle(color: AppConstants.textSecondary),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete,
                        size: 18,
                        color: AppConstants.errorColor,
                      ),
                      label: Text(
                        'Delete',
                        style: TextStyle(color: AppConstants.errorColor),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppConstants.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppConstants.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineChip(DateTime deadline) {
    final isOverdue = deadline.isBefore(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppConstants.errorColor.withOpacity(0.1)
            : AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.event,
            size: 14,
            color: isOverdue
                ? AppConstants.errorColor
                : AppConstants.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            isOverdue
                ? 'Due: ${DateFormat('dd MMM yyyy').format(deadline)}'
                : 'Deadline: ${DateFormat('dd MMM yyyy').format(deadline)}',
            style: TextStyle(
              fontSize: 12,
              color: isOverdue
                  ? AppConstants.errorColor
                  : AppConstants.primaryColor,
              fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransferDetails(BuildContext context) {
    final controller = Get.find<DashboardController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConstants.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swap_horiz,
                    color: AppConstants.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transfer Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(transfer.date),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('From', transfer.sourceCompanyName ?? 'Unknown'),
            _buildDetailRow('To', transfer.companyName),
            _buildDetailRow(
              'Amount',
              '${controller.currencySymbol}${transfer.amount.toStringAsFixed(2)}',
              isAmount: true,
            ),
            if (transfer.description != null)
              _buildDetailRow('Description', transfer.description!),
            if (transfer.invoiceNumber != null)
              _buildDetailRow('Invoice Number', transfer.invoiceNumber!),
            if (transfer.paymentMethod != null)
              _buildDetailRow('Payment Method', transfer.paymentMethod!),
            if (transfer.deadLine != null) ...[
              const Divider(),
              _buildDetailRow(
                'Deadline',
                DateFormat('dd MMM yyyy').format(transfer.deadLine!),
                isDeadline: true,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppConstants.borderColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isAmount = false,
    bool isDeadline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isAmount ? FontWeight.w800 : FontWeight.normal,
                color: isAmount
                    ? AppConstants.expenseColor
                    : isDeadline &&
                          transfer.deadLine != null &&
                          transfer.deadLine!.isBefore(DateTime.now())
                    ? AppConstants.errorColor
                    : AppConstants.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
