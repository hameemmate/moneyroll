// widgets/currency_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';

class CurrencySelectionDialog extends StatelessWidget {
  final DashboardController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Text('Select Currency'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: controller.availableCurrencies.length,
          itemBuilder: (context, index) {
            final currency = controller.availableCurrencies[index];
            final isSelected =
                controller.selectedCurrency.value.code == currency.code;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
                child: Text(
                  currency.symbol,
                  style: TextStyle(
                    fontSize: 20,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
              title: Text(currency.name),
              subtitle: Text(currency.code),
              trailing: isSelected
                  ? Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                controller.changeCurrency(currency);
                Get.back();
                Get.snackbar(
                  'Success',
                  'Currency changed to ${currency.name}',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              },
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Get.back(), child: Text('Cancel'))],
    );
  }
}
