// transfer_record_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/constants/app_constants.dart';
import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/view/widgets/company_wise/company_pay_from_record_screen.dart';
import 'package:moneyrol/dashboard/view/widgets/company_wise/edit_payment_from_record.dart';
import 'package:moneyrol/dashboard/view/widgets/company_wise/reciever_from_company_record_screen.dart';

class TransferRecordDetailSheet extends StatelessWidget {
  final CompanyTransaction rootTransfer;

  const TransferRecordDetailSheet({super.key, required this.rootTransfer});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DashboardController>();

    return SafeArea(
      top: false,
      bottom: true,
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) {
          return Container(
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.folder_special_rounded,
                          color: AppConstants.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transfer Record',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                            Text(
                              '${rootTransfer.sourceCompanyName ?? "?"} → ${rootTransfer.companyName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: AppConstants.textSecondary,
                        ),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Main content
                Expanded(
                  child: Obx(() {
                    final recordId = rootTransfer.recordId ?? rootTransfer.id;
                    final payments = ctrl.getPaymentsFromRecord(recordId);
                    final receipts = ctrl.getReceiptsFromRecord(recordId);
                    final originAmount = rootTransfer.amount;
                    final totalPaid = payments.fold(
                      0.0,
                      (s, p) => s + p.amount,
                    );
                    final totalReceived = receipts.fold(
                      0.0,
                      (s, r) => s + r.amount,
                    );
                    final remaining = originAmount - totalPaid;

                    return ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Balance Card
                        _buildBalanceCard(
                          ctrl,
                          originAmount,
                          totalPaid,
                          totalReceived,
                          remaining,
                        ),
                        const SizedBox(height: 16),

                        // Origin Transfer Section
                        _sectionLabel('Origin Transfer'),
                        const SizedBox(height: 8),
                        _buildOriginCard(ctrl),
                        const SizedBox(height: 20),

                        // Payments Section
                        Row(
                          children: [
                            _sectionLabel('Payments From This Record'),
                            const Spacer(),
                            Text(
                              '${payments.length} payment${payments.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (payments.isEmpty)
                          _buildEmptyPayments('payments')
                        else
                          ...payments.map(
                            (p) => _buildPaymentCard(ctrl, p, 'sent', recordId),
                          ),
                        const SizedBox(height: 20),

                        // Receipts Section
                        Row(
                          children: [
                            _sectionLabel('Receipts From This Record'),
                            const Spacer(),
                            Text(
                              '${receipts.length} receipt${receipts.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (receipts.isEmpty)
                          _buildEmptyPayments('receipts')
                        else
                          ...receipts.map(
                            (r) => _buildPaymentCard(
                              ctrl,
                              r,
                              'received',
                              recordId,
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showPayDialog(
                                  context,
                                  recordId,
                                  remaining,
                                  ctrl,
                                ),
                                icon: const Icon(Icons.send_rounded, size: 18),
                                label: const Text('Pay From Record'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.expenseColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _showReceiveDialog(context, recordId, ctrl),
                                icon: const Icon(
                                  Icons.download_rounded,
                                  size: 18,
                                ),
                                label: const Text('Receive From Record'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.incomeColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Status Message
                        _buildStatusMessage(ctrl, remaining),
                        const SizedBox(height: 24),
                      ],
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppConstants.textSecondary,
      letterSpacing: 0.4,
    ),
  );

  Widget _buildBalanceCard(
    DashboardController ctrl,
    double origin,
    double paid,
    double received,
    double remaining,
  ) {
    final double pct = origin > 0 ? (paid / origin).clamp(0.0, 1.0) : 0.0;
    final bool isOverpaid = remaining < 0;
    final double displayRemaining = remaining < 0 ? 0 : remaining;
    final double overpaidAmount = isOverpaid ? remaining.abs() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor.withOpacity(0.07),
            AppConstants.primaryColor.withOpacity(0.14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _balanceStat(
                  ctrl,
                  'Record Amount',
                  origin,
                  AppConstants.primaryColor,
                  Icons.account_balance_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: AppConstants.borderColor),
              Expanded(
                child: _balanceStat(
                  ctrl,
                  'Total Paid',
                  paid,
                  AppConstants.expenseColor,
                  Icons.arrow_upward_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: AppConstants.borderColor),
              Expanded(
                child: _balanceStat(
                  ctrl,
                  'Total Received',
                  received,
                  AppConstants.incomeColor,
                  Icons.arrow_downward_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: AppConstants.borderColor),
              Expanded(
                child: _balanceStat(
                  ctrl,
                  isOverpaid ? 'Overpaid' : 'Remaining',
                  isOverpaid ? overpaidAmount : displayRemaining,
                  isOverpaid
                      ? AppConstants.errorColor
                      : AppConstants.incomeColor,
                  isOverpaid ? Icons.warning_rounded : Icons.wallet_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppConstants.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverpaid
                    ? AppConstants.errorColor
                    : pct >= 1.0
                    ? AppConstants.errorColor
                    : AppConstants.expenseColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(pct * 100).toStringAsFixed(0)}% used',
                style: TextStyle(
                  fontSize: 11,
                  color: AppConstants.textSecondary,
                ),
              ),
              Text(
                isOverpaid
                    ? 'Overpaid by ${ctrl.currencySymbol}${overpaidAmount.toStringAsFixed(2)}'
                    : pct >= 1.0
                    ? 'Fully utilized'
                    : 'Balance available',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOverpaid
                      ? AppConstants.errorColor
                      : pct >= 1.0
                      ? AppConstants.errorColor
                      : AppConstants.incomeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceStat(
    DashboardController ctrl,
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppConstants.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Obx(
          () => Text(
            '${ctrl.currencySymbol}${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOriginCard(DashboardController ctrl) {
    final hasLinkedTransactions =
        ctrl
            .getPaymentsFromRecord(rootTransfer.recordId ?? rootTransfer.id)
            .isNotEmpty ||
        ctrl
            .getReceiptsFromRecord(rootTransfer.recordId ?? rootTransfer.id)
            .isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: AppConstants.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rootTransfer.sourceCompanyName ?? "?"} → ${rootTransfer.companyName}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy • hh:mm a').format(rootTransfer.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppConstants.textSecondary,
                  ),
                ),
                if (rootTransfer.description != null)
                  Text(
                    rootTransfer.description!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Original Record • ${DateFormat('dd MMM yyyy').format(rootTransfer.date)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${ctrl.currencySymbol}${rootTransfer.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ),
              // Only show delete button if there are no linked transactions
              if (!hasLinkedTransactions) const SizedBox(width: 8),
              if (!hasLinkedTransactions)
                InkWell(
                  onTap: () => _deleteRootTransfer(ctrl),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.errorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppConstants.errorColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPayments(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            type == 'payments' ? Icons.send_rounded : Icons.download_rounded,
            size: 40,
            color: AppConstants.borderColor,
          ),
          const SizedBox(height: 10),
          Text(
            type == 'payments'
                ? 'No payments from this record yet'
                : 'No receipts from this record yet',
            style: TextStyle(fontSize: 13, color: AppConstants.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
    DashboardController ctrl,
    CompanyTransaction transaction,
    String type,
    String recordId,
  ) {
    final bool isSent = type == 'sent';
    final bool isRootTransfer = transaction.id == recordId;

    // For root transfer, make it non-editable/non-deletable
    if (isRootTransfer) {
      return _buildRootTransferCard(ctrl, transaction);
    }

    final Color color = isSent
        ? AppConstants.expenseColor
        : AppConstants.incomeColor;
    final IconData icon = isSent
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final String prefix = isSent ? '-' : '+';
    final String action = isSent ? 'Paid to' : 'Received from';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Dismissible(
        key: Key(transaction.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          return await _showDeleteConfirmationDialog();
        },
        onDismissed: (direction) async {
          await ctrl.deleteCompanyTransaction(transaction.id);
          Get.snackbar(
            'Deleted',
            '$action ${transaction.companyName} has been deleted',
            backgroundColor: AppConstants.errorColor,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        },
        child: InkWell(
          onTap: () => _showEditDialog(transaction, recordId, ctrl),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$action ${transaction.companyName}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          'dd MMM yyyy • hh:mm a',
                        ).format(transaction.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      if (transaction.description != null)
                        Text(
                          transaction.description!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppConstants.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (transaction.invoiceNumber != null)
                            _miniChip(
                              Icons.receipt_rounded,
                              'Inv: ${transaction.invoiceNumber}',
                            ),
                          if (transaction.paymentMethod != null)
                            _miniChip(
                              Icons.payment,
                              transaction.paymentMethod!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          '$prefix${ctrl.currencySymbol}${transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppConstants.textSecondary,
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

  // Add this method to show root transfer as a non-editable card
  Widget _buildRootTransferCard(
    DashboardController ctrl,
    CompanyTransaction transaction,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppConstants.cardColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_special_rounded,
                color: AppConstants.primaryColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original Transfer Record',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.sourceCompanyName ?? "?"} → ${transaction.companyName}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'dd MMM yyyy • hh:mm a',
                    ).format(transaction.date),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${ctrl.currencySymbol}${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppConstants.textSecondary),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppConstants.textSecondary),
          ),
        ],
      ),
    );
  }

  // In TransferRecordDetailSheet - update the delete for root transfer
  // Add this method to handle root transfer deletion

  Future<void> _deleteRootTransfer(DashboardController ctrl) async {
    final bool? confirmed = await _showDeleteConfirmationDialog();

    if (confirmed == true) {
      // Check if there are linked transactions
      final recordId = rootTransfer.recordId ?? rootTransfer.id;
      final linkedTransactions = ctrl.getPaymentsFromRecord(recordId);
      final hasLinked = linkedTransactions.isNotEmpty;

      await ctrl.deleteCompanyTransaction(rootTransfer.id);

      Get.back(); // Close the detail sheet
      Get.snackbar(
        'Deleted',
        hasLinked
            ? 'Record and ${linkedTransactions.length} linked transaction(s) deleted'
            : 'Record deleted successfully',
        backgroundColor: AppConstants.errorColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _buildStatusMessage(DashboardController ctrl, double remaining) {
    final bool isOverpaid = remaining < 0;
    final double absRemaining = remaining.abs();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverpaid
            ? AppConstants.errorColor.withOpacity(0.1)
            : AppConstants.incomeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOverpaid
              ? AppConstants.errorColor.withOpacity(0.3)
              : AppConstants.incomeColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverpaid ? Icons.warning_rounded : Icons.info_rounded,
            size: 16,
            color: isOverpaid
                ? AppConstants.errorColor
                : AppConstants.incomeColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(
              () => Text(
                isOverpaid
                    ? 'Record balance is negative: ${ctrl.currencySymbol}${absRemaining.toStringAsFixed(2)} overpaid'
                    : 'Record balance available: ${ctrl.currencySymbol}${remaining.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isOverpaid
                      ? AppConstants.errorColor
                      : AppConstants.incomeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    CompanyTransaction transaction,
    String recordId,
    DashboardController ctrl,
  ) async {
    final result = await Get.dialog(
      EditPaymentFromRecordDialog(transaction: transaction, recordId: recordId),
      barrierDismissible: false,
    );

    if (result == true) {
      ctrl.refreshData();
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
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

  void _showPayDialog(
    BuildContext context,
    String recordId,
    double remaining,
    DashboardController ctrl,
  ) {
    showDialog(
      context: context,
      builder: (_) => PayFromRecordDialog(
        recordId: recordId,
        availableBalance: remaining,
        recordLabel:
            '${rootTransfer.sourceCompanyName ?? "?"} → ${rootTransfer.companyName}',
      ),
    );
  }

  void _showReceiveDialog(
    BuildContext context,
    String recordId,
    DashboardController ctrl,
  ) {
    showDialog(
      context: context,
      builder: (_) => ReceiveFromRecordDialog(
        recordId: recordId,
        availableBalance: 0,
        recordLabel:
            '${rootTransfer.sourceCompanyName ?? "?"} → ${rootTransfer.companyName}',
      ),
    );
  }
}
