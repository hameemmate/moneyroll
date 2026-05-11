import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/constants/app_constants.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/view/about_app_screen.dart';
import 'package:moneyrol/dashboard/view/over_due_transation_list.dart';
import 'package:moneyrol/dashboard/view/partner_to_partner_transfer_screen.dart';
import 'package:moneyrol/dashboard/view/widgets/add_company_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/add_company_transation_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/add_transation_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/company_wise/company_tranfer_record_details_screen.dart';
import 'package:moneyrol/dashboard/view/widgets/currency_seletion_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/company_wise/sent_to_company_dialog.dart';
import '../controller/dashboard_controller.dart';
import 'history_screen.dart';

class DashboardScreen extends StatelessWidget {
  final DashboardController controller = Get.put(DashboardController());
  final RxString selectedHomePartnerId = ''.obs; // '' = none selected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'MoneyRoll',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {
              Get.to(AboutScreen());
            },
            icon: Icon(Icons.info),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Obx(
                  () => Text(
                    controller.currencySymbol,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => CurrencySelectionDialog(),
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.history, color: Colors.grey.shade700),
            onPressed: () => Get.to(() => HistoryScreen()),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.save_alt, color: Colors.grey.shade700),
                  title: Text('Export Data'),
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.folder_open, color: Colors.grey.shade700),
                  title: Text('Import Data'),
                ),
              ),
              PopupMenuItem(
                value: 'currency',
                child: ListTile(
                  leading: Icon(
                    Icons.currency_exchange,
                    color: Colors.grey.shade700,
                  ),
                  title: Text('Change Currency'),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'export')
                controller.exportData();
              else if (value == 'import')
                controller.importData();
              else if (value == 'currency') {
                showDialog(
                  context: context,
                  builder: (_) => CurrencySelectionDialog(),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTotalAmountCard(),
              const SizedBox(height: 20),
              _buildQuickStats(),
              const SizedBox(height: 20),
              _buildRecentTransactions(),
              const SizedBox(height: 20),
              OverdueTransactionsList(controller: controller),
              SizedBox(height: Get.width * .2),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptions,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add', style: TextStyle(color: Colors.white)),
        backgroundColor: AppConstants.primaryColor,
        elevation: 2,
      ),
    );
  }

  Widget _buildTotalAmountCard() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConstants.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Obx(
                    () => Row(
                      children: [
                        Text(
                          controller.currencySymbol,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          controller.selectedCurrency.value.code,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${controller.currencySymbol}${controller.totalAmount.value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: controller.totalAmount.value >= 0
                    ? AppConstants.incomeColor
                    : AppConstants.expenseColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Normal',
                    controller.getNormalTransactions().length,
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Received',
                    controller.getReceivedCompanyTransactions().length,
                    Icons.download,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Sent',
                    controller.getSentCompanyTransactions().length,
                    Icons.upload,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String title, int count, IconData icon) {
    final iconColor = title == 'Normal'
        ? Colors.blue.shade600
        : title == 'Received'
        ? AppConstants.incomeColor
        : AppConstants.expenseColor;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withOpacity(0.3)),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: AppConstants.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: iconColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Obx(() {
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'From Partners',
              '${controller.currencySymbol}${controller.getTotalReceivedFromCompanies().toStringAsFixed(2)}',
              AppConstants.incomeColor,
              Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'To Partners',
              '${controller.currencySymbol}${controller.getTotalSentToCompanies().toStringAsFixed(2)}',
              AppConstants.expenseColor,
              Icons.arrow_upward,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            return GestureDetector(
              onTap: () {
                controller.showCompanyView.toggle();
              },
              child: Container(
                height: Get.width * .1,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      alignment: controller.showCompanyView.value
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: Get.width * .45,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              'Individual',
                              style: TextStyle(
                                fontSize: 12,
                                color: controller.showCompanyView.value
                                    ? AppConstants.textSecondary
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Partners',
                              style: TextStyle(
                                fontSize: 12,
                                color: controller.showCompanyView.value
                                    ? Colors.white
                                    : AppConstants.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                controller.showCompanyView.value
                    ? 'Partner Transfers'
                    : 'Individual Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  !controller.showCompanyView.value
                      ? Get.to(HistoryScreen())
                      : Get.to(PartnerToPartnerTransfersScreen());
                },
                child: Text(
                  "Show All",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          controller.showCompanyView.value
              ? _buildPartnerTransfersList()
              : _buildIndividualList(),
        ],
      ),
    );
  }

  Widget _buildIndividualList() {
    final List<TransactionItem> items = [];

    for (var t in controller.transactions) {
      items.add(
        TransactionItem(
          type: 'Normal',
          title: t.description ?? 'Cash Received',
          subtitle: DateFormat('dd MMM yyyy').format(t.date),
          amount: t.amount,
          isPositive: true,
          date: t.date,
        ),
      );
    }

    for (var ct in controller.companyTransactions) {
      if (ct.sourceType == SourceType.company) continue;
      items.add(
        TransactionItem(
          type: ct.type == TransactionType.received ? 'Received' : 'Sent',
          title: ct.companyName,
          subtitle: DateFormat('dd MMM yyyy').format(ct.date),
          amount: ct.amount,
          isPositive: ct.type == TransactionType.received,
          date: ct.date,
        ),
      );
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    final recent = items.take(10).toList();

    if (recent.isEmpty) return _buildEmptyState();
    return _buildTransactionListView(recent);
  }

  Widget _buildPartnerTransfersList() {
    final transfers =
        controller.companyTransactions
            .where(
              (ct) =>
                  ct.sourceType == SourceType.company &&
                  ct.type == TransactionType.sent,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    if (transfers.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transfers.take(10).length,
      itemBuilder: (context, index) {
        final ct = transfers[index];

        // Determine if this is a payment FROM a record
        // A payment is "from record" if:
        // 1. It has a recordId that is NOT the same as its own ID (links to another record)
        // 2. OR it has a recordId that exists as a company transaction
        final bool isFromRecord =
            ct.recordId != null &&
            ct.recordId!.isNotEmpty &&
            ct.recordId != ct.id;

        // Get display names
        final String fromName = ct.sourceCompanyName ?? 'Unknown';
        final String toName = ct.companyName;

        // Create different subtitle based on type
        String subtitle;
        IconData leadingIcon;
        String badgeText;
        Color badgeColor;

        if (isFromRecord) {
          // This is a payment made FROM an existing transfer record
          subtitle =
              '📁 From Record • ${DateFormat('dd MMM yyyy').format(ct.date)}';
          leadingIcon = Icons.folder_special_rounded;
          badgeText = 'From Record';
          badgeColor = Colors.purple;
        } else {
          // This is a direct company-to-company transfer
          subtitle =
              'Direct Transfer • ${DateFormat('dd MMM yyyy').format(ct.date)}';
          leadingIcon = Icons.swap_horiz;
          badgeText = 'Direct';
          badgeColor = Colors.orange;
        }

        // Add extra info if available
        if (ct.description != null && ct.description!.isNotEmpty) {
          subtitle = '$subtitle\n${ct.description}';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Icon(leadingIcon, color: Colors.orange, size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '$fromName → $toName',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      color: badgeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppConstants.textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: SizedBox(
              width: 110,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${controller.currencySymbol}${ct.amount.toStringAsFixed(2)}',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  if (ct.paymentMethod != null)
                    Text(
                      ct.paymentMethod!,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () {
              // For direct transfers, show the transfer detail sheet
              // For payments from record, also show the detail sheet
              Get.bottomSheet(
                TransferRecordDetailSheet(rootTransfer: ct),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionListView(List<TransactionItem> items) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final amountColor = item.isPositive
            ? AppConstants.incomeColor
            : AppConstants.expenseColor;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: amountColor.withOpacity(0.3)),
              ),
              child: Icon(
                item.isPositive ? Icons.download : Icons.upload,
                color: amountColor,
                size: 20,
              ),
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            subtitle: Text(
              '${item.type} • ${item.subtitle}',
              style: TextStyle(fontSize: 14, color: AppConstants.textSecondary),
            ),
            trailing: SizedBox(
              width: 110,
              child: Text(
                '${item.isPositive ? '+' : '-'}${controller.currencySymbol}${item.amount.toStringAsFixed(2)}',
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your first transaction to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // Update the _showAddOptions method in DashboardScreen
  void _showAddOptions() {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: AppConstants.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (same as before)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppConstants.borderColor),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add New Transaction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      Obx(
                        () => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            controller.currencySymbol,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.attach_money,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  title: Text(
                    'Add Normal Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  subtitle: Text('Add money received (not from Partners)'),
                  onTap: () {
                    Get.back();
                    showDialog(
                      context: context,
                      builder: (context) => AddTransactionDialog(),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade600.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.business, color: Colors.purple.shade600),
                  ),
                  title: Text(
                    'Add Partners',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  subtitle: Text('Add new Partners'),
                  onTap: () {
                    Get.back();
                    showDialog(
                      context: context,
                      builder: (context) => AddCompanyDialog(),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.incomeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.download,
                      color: AppConstants.incomeColor,
                    ),
                  ),
                  title: Text(
                    'Received from Partners',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  subtitle: Text('Add money received from a Partner'),
                  onTap: () {
                    Get.back();
                    showDialog(
                      context: context,
                      builder: (context) => AddCompanyTransactionDialog(
                        type: TransactionType.received,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.expenseColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.upload, color: AppConstants.expenseColor),
                  ),
                  title: Text(
                    'Send to Partners',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  subtitle: Text('Send money to a Partner'),
                  onTap: () {
                    Get.back();
                    showDialog(
                      context: context,
                      builder: (context) => SendToCompanyDialog(),
                    );
                  },
                ),
                // NEW: Partner to Partner Transfer option
                // if (controller.companies.length >= 2)
                //   ListTile(
                //     leading: Container(
                //       padding: const EdgeInsets.all(8),
                //       decoration: BoxDecoration(
                //         color: Colors.purple.withOpacity(0.1),
                //         shape: BoxShape.circle,
                //       ),
                //       child: Icon(Icons.swap_horiz, color: Colors.purple),
                //     ),
                //     title: Text(
                //       'Partner to Partner Transfer',
                //       style: TextStyle(
                //         fontWeight: FontWeight.w600,
                //         color: AppConstants.textPrimary,
                //       ),
                //     ),
                //     subtitle: Text('Transfer money between Partners'),
                //     onTap: () {
                //       Get.back();
                //       showDialog(
                //         context: context,
                //         builder: (context) => SendToCompanyDialog(),
                //       );
                //     },
                //   ),
                const Divider(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.currency_exchange,
                      color: Colors.amber,
                    ),
                  ),
                  title: Text(
                    'Change Currency',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  subtitle: const Text('Select different currency symbol'),
                  onTap: () {
                    Get.back();
                    showDialog(
                      context: context,
                      builder: (context) => CurrencySelectionDialog(),
                    );
                  },
                ),
                SizedBox(height: Get.width * .15),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Helper class for displaying transactions in the dashboard
class TransactionItem {
  final String type;
  final String title;
  final String subtitle;
  final double amount;
  final bool isPositive;
  final DateTime date;

  TransactionItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPositive,
    required this.date,
  });
}
