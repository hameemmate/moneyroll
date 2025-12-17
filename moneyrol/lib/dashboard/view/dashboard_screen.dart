import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/view/widgets/add_company_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/add_company_transation_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/add_transation_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/currency_seletion_dialog.dart';
import 'package:moneyrol/theme/app_theme.dart';
import '../controller/dashboard_controller.dart';
import '../../constants/app_constants.dart';
import 'history_screen.dart';

class DashboardScreen extends StatelessWidget {
  final DashboardController controller = Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Get complete theme data
      final appTheme = AppThemes.getTheme(controller.currentTheme.value);
      final themeData = appTheme.themeData;

      return Theme(
        data: themeData,
        child: Scaffold(
          backgroundColor: appTheme.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: appTheme.primary,
            title: Text(
              'MoneyRoll',
              style: TextStyle(color: themeData.appBarTheme.foregroundColor),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.currencySymbol,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => CurrencySelectionDialog(),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.history,
                  color: themeData.appBarTheme.foregroundColor,
                ),
                onPressed: () => Get.to(() => HistoryScreen()),
              ),
              PopupMenuButton(
                icon: Icon(
                  Icons.more_vert,
                  color: themeData.appBarTheme.foregroundColor,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.save_alt, color: Colors.blue),
                      title: Text('Export Data'),
                    ),
                    value: 'export',
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.folder_open, color: Colors.green),
                      title: Text('Import Data'),
                    ),
                    value: 'import',
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(
                        Icons.currency_exchange,
                        color: Colors.amber,
                      ),
                      title: Text('Change Currency'),
                    ),
                    value: 'currency',
                  ),
                  PopupMenuItem(
                    value: 'theme',
                    child: ListTile(
                      leading: Icon(Icons.palette),
                      title: Text('Change Theme'),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'export')
                    controller.exportData();
                  else if (value == 'import')
                    controller.importData();
                  else if (value == 'currency')
                    showDialog(
                      context: context,
                      builder: (_) => CurrencySelectionDialog(),
                    );
                  else if (value == 'theme')
                    showThemeSelector();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalAmountCard(appTheme),
                  SizedBox(height: 20),
                  _buildQuickStats(appTheme),
                  SizedBox(height: 20),
                  _buildRecentTransactions(appTheme),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddOptions,
            icon: Icon(Icons.add, color: Colors.white),
            label: Text('Add', style: TextStyle(color: Colors.white)),
            backgroundColor: appTheme.primary,
          ),
        ),
      );
    });
  }

  Widget _buildTotalAmountCard(AppThemeData appTheme) {
    return Obx(() {
      return Card(
        color: appTheme.cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(24),
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
                      color: appTheme.themeData.brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey[800],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: appTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: appTheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          controller.currencySymbol,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: appTheme.primary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          controller.selectedCurrency.value.code,
                          style: TextStyle(
                            fontSize: 12,
                            color: appTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '${controller.currencySymbol}${controller.totalAmount.value.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: controller.totalAmount.value >= 0
                      ? appTheme.income
                      : appTheme.expense,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Normal',
                      controller.getNormalTransactions().length,
                      appTheme.primary,
                      appTheme.iconBackground,
                      appTheme.themeData.brightness,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Received',
                      controller.getReceivedCompanyTransactions().length,
                      appTheme.income,
                      appTheme.iconBackground,
                      appTheme.themeData.brightness,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Sent',
                      controller.getSentCompanyTransactions().length,
                      appTheme.expense,
                      appTheme.iconBackground,
                      appTheme.themeData.brightness,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatItem(
    String title,
    int count,
    Color color,
    Color iconBackground,
    Brightness brightness,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(_getIconForType(title), color: color, size: 20),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Normal':
        return Icons.attach_money;
      case 'Received':
        return Icons.download;
      case 'Sent':
        return Icons.upload;
      default:
        return Icons.money;
    }
  }

  Widget _buildQuickStats(AppThemeData appTheme) {
    return Obx(() {
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'From Partners',
              '${controller.currencySymbol}${controller.getTotalReceivedFromCompanies().toStringAsFixed(2)}',
              appTheme.income,
              Icons.arrow_downward,
              appTheme,
            ),
          ),
          SizedBox(width: Get.width * .01),
          Expanded(
            child: _buildStatCard(
              'To Partners',
              '${controller.currencySymbol}${controller.getTotalSentToCompanies().toStringAsFixed(2)}',
              appTheme.expense,
              Icons.arrow_upward,
              appTheme,
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
    AppThemeData appTheme,
  ) {
    return Card(
      color: appTheme.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: appTheme.themeData.brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(AppThemeData appTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appTheme.themeData.brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[800],
              ),
            ),
            TextButton(
              onPressed: () => Get.to(() => HistoryScreen()),
              child: Text(
                'View All',
                style: TextStyle(color: appTheme.primary),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Obx(() {
          final List<TransactionItem> allTransactions = [];

          for (var t in controller.transactions) {
            allTransactions.add(
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
            allTransactions.add(
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

          allTransactions.sort((a, b) => b.date.compareTo(a.date));
          final recentTransactions = allTransactions.take(10).toList();

          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: recentTransactions.length,
            itemBuilder: (context, index) {
              final item = recentTransactions[index];
              return Card(
                color: appTheme.cardBackground,
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.isPositive
                          ? appTheme.income.withOpacity(0.1)
                          : appTheme.expense.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.isPositive ? Icons.download : Icons.upload,
                      color: item.isPositive
                          ? appTheme.income
                          : appTheme.expense,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: appTheme.themeData.brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey[800],
                    ),
                  ),
                  subtitle: Text(
                    '${item.type} • ${item.subtitle}',
                    style: TextStyle(
                      color: appTheme.themeData.brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                  trailing: SizedBox(
                    width: Get.width * .35,
                    child: Text(
                      textAlign: TextAlign.end,
                      '${item.isPositive ? '+' : '-'}${controller.currencySymbol}${item.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: item.isPositive
                            ? appTheme.income
                            : appTheme.expense,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  void _showAddOptions() {
    final appTheme = AppThemes.getTheme(controller.currentTheme.value);

    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: appTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add a header with current currency
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: appTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add New Transaction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: appTheme.themeData.brightness == Brightness.dark
                            ? Colors.grey[300]
                            : Colors.grey[800],
                      ),
                    ),
                    Obx(
                      () => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: appTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: appTheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          controller.currencySymbol,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: appTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.attach_money, color: appTheme.primary),
                title: Text('Add Normal Amount'),
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
                leading: Icon(Icons.business, color: appTheme.income),
                title: Text('Add Partners'),
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
                leading: Icon(Icons.download, color: appTheme.income),
                title: Text('Received from Partners'),
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
                leading: Icon(Icons.upload, color: appTheme.expense),
                title: Text('Sent to Partners'),
                subtitle: Text('Add money sent to a Partner'),
                onTap: () {
                  Get.back();
                  showDialog(
                    context: context,
                    builder: (context) =>
                        AddCompanyTransactionDialog(type: TransactionType.sent),
                  );
                },
              ),
              // Option to change currency from bottom sheet
              Divider(),
              ListTile(
                leading: Icon(Icons.currency_exchange, color: Colors.amber),
                title: Text('Change Currency'),
                subtitle: Text('Select different currency symbol'),
                onTap: () {
                  Get.back();
                  showDialog(
                    context: context,
                    builder: (context) => CurrencySelectionDialog(),
                  );
                },
              ),
            ],
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

void showThemeSelector() {
  final controller = Get.find<DashboardController>();
  final currentTheme = AppThemes.getTheme(controller.currentTheme.value);

  Get.bottomSheet(
    Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentTheme.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _themeTile(
            'Blue Theme',
            Icons.water_drop,
            Colors.blue,
            () => controller.changeTheme(AppThemeType.blue),
          ),
          _themeTile(
            'Dark Theme',
            Icons.dark_mode,
            Colors.grey[800]!,
            () => controller.changeTheme(AppThemeType.dark),
          ),
          _themeTile(
            'Green Theme',
            Icons.eco,
            Colors.green,
            () => controller.changeTheme(AppThemeType.green),
          ),
          _themeTile(
            'Orange Theme',
            Icons.wb_sunny,
            Colors.orange,
            () => controller.changeTheme(AppThemeType.orange),
          ),
          _themeTile(
            'Red Theme',
            Icons.whatshot,
            Colors.red,
            () => controller.changeTheme(AppThemeType.red),
          ),
          _themeTile(
            'Purple Theme',
            Icons.brightness_5,
            Colors.purple,
            () => controller.changeTheme(AppThemeType.purple),
          ),
          _themeTile(
            'White Theme',
            Icons.light_mode,
            Colors.grey[300]!,
            () => controller.changeTheme(AppThemeType.white),
          ),
        ],
      ),
    ),
  );
}

Widget _themeTile(
  String title,
  IconData icon,
  Color iconColor,
  VoidCallback onTap,
) {
  return ListTile(
    leading: Icon(icon, color: iconColor),
    title: Text(title),
    onTap: () {
      onTap();
      Get.back();
    },
  );
}
