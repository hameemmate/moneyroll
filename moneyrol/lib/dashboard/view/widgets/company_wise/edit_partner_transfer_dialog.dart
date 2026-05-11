// edit_partner_transfer_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/constants/app_constants.dart';
import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';
import 'package:moneyrol/dashboard/model/company_model.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';

class EditPartnerTransferDialog extends StatefulWidget {
  final CompanyTransaction transfer;

  const EditPartnerTransferDialog({super.key, required this.transfer});

  @override
  State<EditPartnerTransferDialog> createState() =>
      _EditPartnerTransferDialogState();
}

class _EditPartnerTransferDialogState extends State<EditPartnerTransferDialog> {
  final DashboardController controller = Get.find();
  final _formKey = GlobalKey<FormState>();

  late String? selectedFromCompanyId;
  late String? selectedToCompanyId;
  late String? selectedPaymentMethod;
  late TextEditingController amountController;
  late TextEditingController descriptionController;
  late TextEditingController invoiceController;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  DateTime? selectedDeadline;

  // Payment method options
  final List<Map<String, dynamic>> paymentMethods = [
    {'name': 'Cash', 'icon': Icons.money_rounded},
    {'name': 'Card', 'icon': Icons.credit_card_rounded},
    {'name': 'Bank Transfer', 'icon': Icons.account_balance_rounded},
  ];

  @override
  void initState() {
    super.initState();
    selectedFromCompanyId = widget.transfer.sourceCompanyId;
    selectedToCompanyId = widget.transfer.companyId;
    amountController = TextEditingController(
      text: widget.transfer.amount.toString(),
    );
    descriptionController = TextEditingController(
      text: widget.transfer.description ?? '',
    );
    invoiceController = TextEditingController(
      text: widget.transfer.invoiceNumber ?? '',
    );
    selectedPaymentMethod = widget.transfer.paymentMethod;
    selectedDate = widget.transfer.date;
    selectedTime = TimeOfDay.fromDateTime(widget.transfer.date);
    selectedDeadline = widget.transfer.deadLine;
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    invoiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fromCompany = controller.companies.firstWhereOrNull(
      (c) => c.id == selectedFromCompanyId,
    );
    final toCompany = controller.companies.firstWhereOrNull(
      (c) => c.id == selectedToCompanyId,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppConstants.backgroundColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Edit Partner Transfer',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppConstants.textSecondary),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTransferFlow(
                      fromCompanyName: fromCompany?.name ?? 'Unknown',
                      toCompanyName: toCompany?.name ?? 'Unknown',
                    ),
                    const SizedBox(height: 24),
                    _buildAmountField(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDateField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTimeField()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDeadlineField(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: descriptionController,
                      label: 'Description',
                      hint: 'Enter description (optional)',
                      icon: Icons.description_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: invoiceController,
                      label: 'Invoice Number',
                      hint: 'Invoice number (optional)',
                      icon: Icons.receipt_long_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentMethodField(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: AppConstants.borderColor),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Update Transfer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedPaymentMethod,
            isExpanded: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(
                Icons.payment_rounded,
                color: AppConstants.textSecondary,
              ),
            ),
            style: TextStyle(fontSize: 16, color: AppConstants.textPrimary),
            dropdownColor: AppConstants.backgroundColor,
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppConstants.textSecondary,
            ),
            hint: Text(
              'Select payment method',
              style: TextStyle(
                color: AppConstants.textSecondary.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            items: paymentMethods.map((method) {
              return DropdownMenuItem<String>(
                value: method['name'],
                child: Row(
                  children: [
                    Icon(
                      method['icon'],
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      method['name'],
                      style: TextStyle(
                        fontSize: 16,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPaymentMethod = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransferFlow({
    required String fromCompanyName,
    required String toCompanyName,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// FROM PARTNER (Read-only)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From Partner',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.business_rounded,
                            size: 18,
                            color: AppConstants.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fromCompanyName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppConstants.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: AppConstants.textSecondary.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 18),
              ),

              /// TO PARTNER (Read-only)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To Partner',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.business_rounded,
                            size: 18,
                            color: AppConstants.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              toCompanyName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppConstants.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: AppConstants.textSecondary.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: TextFormField(
            controller: amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Obx(
                () => Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    controller.currencySymbol,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter amount';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              // Removed balance validation - allow any amount
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: Get.width * .18,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      DateFormat('dd MMM yyyy').format(selectedDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                Icon(Icons.calendar_month, color: AppConstants.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _selectTime,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedTime.format(context),
                  style: const TextStyle(fontSize: 14),
                ),
                Icon(Icons.access_time, color: AppConstants.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deadline (Optional)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _selectDeadline,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDeadline == null
                      ? 'Select deadline date'
                      : DateFormat('dd MMM yyyy').format(selectedDeadline!),
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedDeadline == null
                        ? AppConstants.textSecondary
                        : AppConstants.textPrimary,
                  ),
                ),
                Icon(Icons.event, color: AppConstants.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(icon, color: AppConstants.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: AppConstants.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: AppConstants.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: AppConstants.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        selectedDeadline = date;
      });
    }
  }

  Future<void> _updateTransfer() async {
    if (_formKey.currentState!.validate() &&
        selectedFromCompanyId != null &&
        selectedToCompanyId != null) {
      // Check if trying to transfer to the same company
      if (selectedFromCompanyId == selectedToCompanyId) {
        Get.snackbar(
          'Invalid',
          'Cannot transfer to the same partner',
          backgroundColor: AppConstants.errorColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final fromCompany = controller.companies.firstWhere(
        (c) => c.id == selectedFromCompanyId,
      );
      final toCompany = controller.companies.firstWhere(
        (c) => c.id == selectedToCompanyId,
      );

      final newAmount = double.parse(amountController.text.trim());
      // Removed balance check - allow any amount

      final combinedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // Find the associated received transaction
      final receivedTransaction = controller.companyTransactions
          .firstWhereOrNull(
            (t) =>
                t.type == TransactionType.received &&
                t.sourceCompanyId == widget.transfer.sourceCompanyId &&
                t.companyId == widget.transfer.companyId &&
                t.amount == widget.transfer.amount,
          );

      // Update the sent transaction
      final updatedSentTransaction = CompanyTransaction(
        id: widget.transfer.id,
        companyId: toCompany.id,
        companyName: toCompany.name,
        amount: newAmount,
        date: combinedDateTime,
        deadLine: selectedDeadline,
        type: TransactionType.sent,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        invoiceNumber: invoiceController.text.trim().isEmpty
            ? null
            : invoiceController.text.trim(),
        paymentMethod: selectedPaymentMethod,
        sourceType: SourceType.company,
        sourceCompanyId: fromCompany.id,
        sourceCompanyName: fromCompany.name,
      );

      // Update or create the received transaction
      if (receivedTransaction != null) {
        // Update existing received transaction
        final updatedReceivedTransaction = CompanyTransaction(
          id: receivedTransaction.id,
          companyId: toCompany.id,
          companyName: toCompany.name,
          amount: newAmount,
          date: combinedDateTime,
          deadLine: selectedDeadline,
          type: TransactionType.received,
          description: descriptionController.text.trim().isEmpty
              ? "Received from ${fromCompany.name}"
              : descriptionController.text.trim(),
          invoiceNumber: invoiceController.text.trim().isEmpty
              ? null
              : invoiceController.text.trim(),
          paymentMethod: selectedPaymentMethod,
          sourceType: SourceType.company,
          sourceCompanyId: fromCompany.id,
          sourceCompanyName: fromCompany.name,
        );
        await controller.updateCompanyTransaction(updatedReceivedTransaction);
      } else {
        // Create new received transaction
        final newReceivedTransaction = CompanyTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString() + "_received",
          companyId: toCompany.id,
          companyName: toCompany.name,
          amount: newAmount,
          date: combinedDateTime,
          deadLine: selectedDeadline,
          type: TransactionType.received,
          description: descriptionController.text.trim().isEmpty
              ? "Received from ${fromCompany.name}"
              : descriptionController.text.trim(),
          invoiceNumber: invoiceController.text.trim().isEmpty
              ? null
              : invoiceController.text.trim(),
          paymentMethod: selectedPaymentMethod,
          sourceType: SourceType.company,
          sourceCompanyId: fromCompany.id,
          sourceCompanyName: fromCompany.name,
        );
        await controller.addCompanyTransactionDirectly(newReceivedTransaction);
      }

      // Update the sent transaction
      await controller.updateCompanyTransaction(updatedSentTransaction);

      Get.back();

      Get.snackbar(
        'Updated',
        'Partner transfer updated successfully',
        backgroundColor: AppConstants.successColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
