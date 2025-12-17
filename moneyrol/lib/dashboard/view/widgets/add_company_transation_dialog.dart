import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/view/widgets/add_company_dialog.dart';

class AddCompanyTransactionDialog extends StatefulWidget {
  final TransactionType type;

  AddCompanyTransactionDialog({required this.type});

  @override
  _AddCompanyTransactionDialogState createState() =>
      _AddCompanyTransactionDialogState();
}

class _AddCompanyTransactionDialogState
    extends State<AddCompanyTransactionDialog> {
  final DashboardController controller = Get.find();
  final _formKey = GlobalKey<FormState>();

  String? selectedCompanyId;
  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController invoiceController = TextEditingController();
  TextEditingController paymentMethodController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Text(
        widget.type == TransactionType.received
            ? 'Received from Partners'
            : 'Sent to Partner',
      ),
      content: SizedBox(
        width: Get.width,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Company Dropdown
                DropdownButtonFormField<String>(
                  value: selectedCompanyId,
                  decoration: InputDecoration(
                    labelText: 'Select Partner*',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.companies.map((company) {
                    return DropdownMenuItem(
                      value: company.id,
                      child: Text(company.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCompanyId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a Partner';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount*',
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

                // Date
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
                      labelText: 'Date*',
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

                // Description
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                // Invoice Number
                TextFormField(
                  controller: invoiceController,
                  decoration: InputDecoration(
                    labelText: 'Invoice Number (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                // Payment Method
                TextFormField(
                  controller: paymentMethodController,
                  decoration: InputDecoration(
                    labelText: 'Payment Method (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
        if (selectedCompanyId == null)
          TextButton(
            onPressed: () {
              Get.back();
              showDialog(
                context: context,
                builder: (context) => AddCompanyDialog(),
              ).then((_) {
                // Reopen this dialog after adding company
                showDialog(
                  context: context,
                  builder: (context) =>
                      AddCompanyTransactionDialog(type: widget.type),
                );
              });
            },
            child: Text('Add New Partners'),
          ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() &&
                selectedCompanyId != null) {
              controller.addCompanyTransaction(
                companyId: selectedCompanyId!,
                amount: double.parse(amountController.text),
                date: selectedDate,
                type: widget.type,
                description: descriptionController.text.isEmpty
                    ? null
                    : descriptionController.text,
                invoiceNumber: invoiceController.text.isEmpty
                    ? null
                    : invoiceController.text,
                paymentMethod: paymentMethodController.text.isEmpty
                    ? null
                    : paymentMethodController.text,
              );
              Get.back();
            }
          },
          child: Text(
            widget.type == TransactionType.received
                ? 'Receive Amount'
                : 'Send Amount',
          ),
        ),
      ],
    );
  }
}
