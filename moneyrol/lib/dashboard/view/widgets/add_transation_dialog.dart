import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controller/dashboard_controller.dart';

class AddTransactionDialog extends StatefulWidget {
  @override
  _AddTransactionDialogState createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final DashboardController controller = Get.find();
  final _formKey = GlobalKey<FormState>();

  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController sourceController = TextEditingController();
  TextEditingController referenceController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool isCash = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Text('Add Normal Amount'),
      content: SizedBox(
        width: Get.width,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: controller.selectedCurrency.value.symbol,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter valid amount';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: sourceController,
                  decoration: InputDecoration(
                    labelText: 'Source (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                        Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Cash Transaction'),
                  value: isCash,
                  onChanged: (value) {
                    setState(() {
                      isCash = value;
                    });
                  },
                ),
                if (!isCash) ...[
                  SizedBox(height: 16),
                  TextFormField(
                    controller: referenceController,
                    decoration: InputDecoration(
                      labelText: 'Reference/Cheque Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              controller.addTransaction(
                amount: double.parse(amountController.text),
                date: selectedDate,
                description: descriptionController.text.isEmpty
                    ? null
                    : descriptionController.text,
                source: sourceController.text.isEmpty
                    ? null
                    : sourceController.text,
                isCash: isCash,
                referenceNumber: referenceController.text.isEmpty
                    ? null
                    : referenceController.text,
              );
              Get.back();
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
