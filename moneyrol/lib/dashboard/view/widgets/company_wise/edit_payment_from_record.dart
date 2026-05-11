// edit_payment_from_record_dialog.dart (with delete button)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/constants/app_constants.dart';
import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';

class EditPaymentFromRecordDialog extends StatefulWidget {
  final CompanyTransaction transaction;
  final String recordId;

  const EditPaymentFromRecordDialog({
    super.key,
    required this.transaction,
    required this.recordId,
  });

  @override
  State<EditPaymentFromRecordDialog> createState() =>
      _EditPaymentFromRecordDialogState();
}

class _EditPaymentFromRecordDialogState
    extends State<EditPaymentFromRecordDialog> {
  final DashboardController ctrl = Get.find();
  final _formKey = GlobalKey<FormState>();

  String? selectedCompanyId;
  String? selectedPaymentMethod;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  DateTime? selectedDeadline;

  final amountCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final invoiceCtrl = TextEditingController();

  final List<Map<String, dynamic>> paymentMethods = [
    {'name': 'Cash', 'icon': Icons.money_rounded},
    {'name': 'Card', 'icon': Icons.credit_card_rounded},
    {'name': 'Bank Transfer', 'icon': Icons.account_balance_rounded},
  ];

  @override
  void initState() {
    super.initState();
    selectedCompanyId = widget.transaction.companyId;
    selectedPaymentMethod = widget.transaction.paymentMethod;
    selectedDate = widget.transaction.date;
    selectedTime = TimeOfDay.fromDateTime(widget.transaction.date);
    selectedDeadline = widget.transaction.deadLine;

    amountCtrl.text = widget.transaction.amount.toString();
    descCtrl.text = widget.transaction.description ?? '';
    invoiceCtrl.text = widget.transaction.invoiceNumber ?? '';
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    descCtrl.dispose();
    invoiceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSent = widget.transaction.type == TransactionType.sent;
    final Color themeColor = isSent
        ? AppConstants.expenseColor
        : AppConstants.incomeColor;
    final String action = isSent ? 'Edit Payment' : 'Edit Receipt';
    final String buttonText = isSent ? 'Update Payment' : 'Update Receipt';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppConstants.backgroundColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: themeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      action,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textPrimary,
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
              const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Partner
                    _buildLabel(
                      isSent ? 'Pay To Partner' : 'Receive From Partner',
                      required: true,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppConstants.borderColor),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedCompanyId,
                        isExpanded: true,
                        isDense: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          prefixIcon: Icon(Icons.business_rounded, size: 18),
                        ),
                        hint: Text(
                          isSent
                              ? 'Select partner to pay'
                              : 'Select partner to receive from',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppConstants.textSecondary.withOpacity(0.6),
                          ),
                        ),
                        items: ctrl.companies.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => selectedCompanyId = v),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Select partner' : null,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Amount
                    _buildLabel('Amount', required: true),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppConstants.borderColor),
                      ),
                      child: TextFormField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: AppConstants.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter amount',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: AppConstants.textSecondary.withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          prefixIcon: Obx(
                            () => Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                ctrl.currencySymbol,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter amount';
                          final a = double.tryParse(v);
                          if (a == null || a <= 0) return 'Invalid amount';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date & Time
                    Row(
                      children: [
                        Expanded(child: _buildDateField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTimeField()),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Deadline
                    _buildDeadlineField(),
                    const SizedBox(height: 14),

                    // Description
                    _buildTextField(
                      controller: descCtrl,
                      label: 'Description (Optional)',
                      hint: isSent
                          ? 'What is this payment for?'
                          : 'What is this receipt for?',
                      icon: Icons.description_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),

                    // Invoice
                    _buildTextField(
                      controller: invoiceCtrl,
                      label: 'Invoice Number (Optional)',
                      hint: 'Enter invoice number',
                      icon: Icons.receipt_long_rounded,
                    ),
                    const SizedBox(height: 14),

                    // Payment method
                    _buildPaymentMethodField(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons Row with Delete Button
              Row(
                children: [
                  // Delete Button
                  const SizedBox(width: 12),
                  // Cancel Button
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
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppConstants.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Update Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(buttonText),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppConstants.errorColor),
                    foregroundColor: AppConstants.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppConstants.errorColor,
            ),
          ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? DateFormat('dd MMM yyyy').format(selectedDate!)
                      : 'Select date',
                  style: TextStyle(
                    fontSize: 12,
                    color: selectedDate != null
                        ? AppConstants.textPrimary
                        : AppConstants.textSecondary,
                  ),
                ),
                Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: AppConstants.textSecondary,
                ),
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
        Text(
          'Time',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _selectTime,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedTime != null
                      ? selectedTime!.format(context)
                      : 'Select time',
                  style: TextStyle(
                    fontSize: 12,
                    color: selectedTime != null
                        ? AppConstants.textPrimary
                        : AppConstants.textSecondary,
                  ),
                ),
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppConstants.textSecondary,
                ),
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
        Text(
          'Deadline (Optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _selectDeadline,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDeadline == null
                      ? 'Select deadline'
                      : DateFormat('dd MMM yyyy').format(selectedDeadline!),
                  style: TextStyle(
                    fontSize: 12,
                    color: selectedDeadline == null
                        ? AppConstants.textSecondary
                        : AppConstants.textPrimary,
                  ),
                ),
                Icon(
                  Icons.event_rounded,
                  size: 16,
                  color: AppConstants.textSecondary,
                ),
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(fontSize: 14, color: AppConstants.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13,
                color: AppConstants.textSecondary.withOpacity(0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              prefixIcon: Icon(
                icon,
                size: 18,
                color: AppConstants.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedPaymentMethod,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              prefixIcon: Icon(Icons.payment_rounded, size: 18),
            ),
            hint: Text(
              'Select payment method',
              style: TextStyle(
                fontSize: 13,
                color: AppConstants.textSecondary.withOpacity(0.6),
              ),
            ),
            items: paymentMethods.map((m) {
              return DropdownMenuItem<String>(
                value: m['name'],
                child: Row(
                  children: [
                    Icon(m['icon'], color: AppConstants.primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Text(m['name'], style: const TextStyle(fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) => setState(() => selectedPaymentMethod = v),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime initialDate = selectedDate ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: AppConstants.primaryColor),
        ),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() => selectedDate = d);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay initialTime = selectedTime ?? TimeOfDay.now();
    final t = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: AppConstants.primaryColor),
        ),
        child: child!,
      ),
    );
    if (t != null) {
      setState(() => selectedTime = t);
    }
  }

  Future<void> _selectDeadline() async {
    final DateTime initialDeadline = selectedDeadline ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initialDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: AppConstants.primaryColor),
        ),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() => selectedDeadline = d);
    }
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await Get.dialog<bool>(
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

    if (confirm == true) {
      await ctrl.deleteCompanyTransaction(widget.transaction.id);
      Get.back(result: true); // Close dialog and return true
      Get.snackbar(
        'Deleted',
        'Transaction has been deleted successfully',
        backgroundColor: AppConstants.errorColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final String? companyId = selectedCompanyId;
    final DateTime? date = selectedDate;
    final TimeOfDay? time = selectedTime;

    if (companyId == null) {
      _showError('Please select a partner');
      return;
    }

    if (date == null) {
      _showError('Please select a date');
      return;
    }

    if (time == null) {
      _showError('Please select a time');
      return;
    }

    final company = ctrl.companies.firstWhereOrNull((c) => c.id == companyId);
    if (company == null) {
      _showError('Selected partner not found');
      return;
    }

    final String amountText = amountCtrl.text.trim();
    if (amountText.isEmpty) {
      _showError('Please enter an amount');
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    final DateTime combinedDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final String? description = descCtrl.text.trim().isEmpty
        ? null
        : descCtrl.text.trim();
    final String? invoiceNumber = invoiceCtrl.text.trim().isEmpty
        ? null
        : invoiceCtrl.text.trim();

    final updatedTransaction = CompanyTransaction(
      id: widget.transaction.id,
      companyId: company.id,
      companyName: company.name,
      amount: amount,
      date: combinedDate,
      deadLine: selectedDeadline,
      type: widget.transaction.type,
      description: description,
      invoiceNumber: invoiceNumber,
      paymentMethod: selectedPaymentMethod,
      sourceType: widget.transaction.sourceType,
      sourceCompanyId: widget.transaction.sourceCompanyId,
      sourceCompanyName: widget.transaction.sourceCompanyName,
      recordId: widget.recordId,
    );

    await ctrl.updateCompanyTransaction(updatedTransaction);

    Get.back(result: true);
    _showSuccess('Transaction updated successfully');
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: AppConstants.errorColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: AppConstants.successColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}
