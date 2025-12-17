import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';

class EditCompanyTransactionDialog extends StatefulWidget {
  final CompanyTransaction transaction;

  EditCompanyTransactionDialog({required this.transaction});

  @override
  _EditCompanyTransactionDialogState createState() =>
      _EditCompanyTransactionDialogState();
}

class _EditCompanyTransactionDialogState
    extends State<EditCompanyTransactionDialog> {
  final DashboardController controller = Get.find();
  final _formKey = GlobalKey<FormState>();

  late String? selectedCompanyId;
  late TextEditingController amountController;
  late TextEditingController descriptionController;
  late TextEditingController invoiceController;
  late TextEditingController paymentMethodController;
  late DateTime selectedDate;
  late TransactionType selectedType;

  @override
  void initState() {
    super.initState();
    selectedCompanyId = widget.transaction.companyId;
    amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    descriptionController = TextEditingController(
      text: widget.transaction.description ?? '',
    );
    invoiceController = TextEditingController(
      text: widget.transaction.invoiceNumber ?? '',
    );
    paymentMethodController = TextEditingController(
      text: widget.transaction.paymentMethod ?? '',
    );
    selectedDate = widget.transaction.date;
    selectedType = widget.transaction.type;
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    invoiceController.dispose();
    paymentMethodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Text(
        selectedType == TransactionType.received
            ? 'Edit Received Transaction'
            : 'Edit Sent Transaction',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Company Dropdown (Read-only since we can't change company)
              DropdownButtonFormField<String>(
                value: selectedCompanyId,
                decoration: InputDecoration(
                  labelText: 'Partner',
                  border: OutlineInputBorder(),
                ),
                items: controller.companies.map((company) {
                  return DropdownMenuItem(
                    value: company.id,
                    child: Text(company.name),
                  );
                }).toList(),
                onChanged: null, // Disabled for editing
                validator: (value) {
                  if (value == null) {
                    return 'Please select a Partner';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Transaction Type Toggle
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text('Received'),
                      selected: selectedType == TransactionType.received,
                      onSelected: (selected) {
                        setState(() {
                          selectedType = TransactionType.received;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text('Sent'),
                      selected: selectedType == TransactionType.sent,
                      onSelected: (selected) {
                        setState(() {
                          selectedType = TransactionType.sent;
                        });
                      },
                    ),
                  ),
                ],
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
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() &&
                selectedCompanyId != null) {
              controller.editCompanyTransaction(
                id: widget.transaction.id,
                companyId: selectedCompanyId!,
                amount: double.parse(amountController.text),
                date: selectedDate,
                type: selectedType,
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
          child: Text('Update'),
        ),
      ],
    );
  }
}
