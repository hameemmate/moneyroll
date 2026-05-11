// receive_from_record_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/constants/app_constants.dart';
import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';

class ReceiveFromRecordDialog extends StatefulWidget {
  final String recordId;
  final double availableBalance;
  final String recordLabel;

  const ReceiveFromRecordDialog({
    super.key,
    required this.recordId,
    required this.availableBalance,
    required this.recordLabel,
  });

  @override
  State<ReceiveFromRecordDialog> createState() =>
      _ReceiveFromRecordDialogState();
}

class _ReceiveFromRecordDialogState extends State<ReceiveFromRecordDialog> {
  final DashboardController ctrl = Get.find();
  final _formKey = GlobalKey<FormState>();

  String? selectedCompanyId;
  String? selectedPaymentMethod;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
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
  void dispose() {
    amountCtrl.dispose();
    descCtrl.dispose();
    invoiceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      color: AppConstants.incomeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.download_rounded,
                      color: AppConstants.incomeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receive From Record',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        Text(
                          widget.recordLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppConstants.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
              const SizedBox(height: 12),

              // Info banner (no infinity)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.incomeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppConstants.incomeColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      size: 16,
                      color: AppConstants.incomeColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Record: ${widget.recordLabel}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receive from company
                    _buildLabel('Receive From Partner', required: true),
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
                          'Select partner to receive from',
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
                      hint: 'What is this receipt for?',
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
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppConstants.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.incomeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Record Receipt'),
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

  // ... (all helper methods _buildLabel, _buildDateField, _buildTimeField,
  // _buildDeadlineField, _buildTextField, _buildPaymentMethodField,
  // _selectDate, _selectTime, _selectDeadline are the same as in PayFromRecordDialog)

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
                  DateFormat('dd MMM yyyy').format(selectedDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textPrimary,
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
                  selectedTime.format(context),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textPrimary,
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
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: AppConstants.primaryColor),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => selectedDate = d);
  }

  Future<void> _selectTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: AppConstants.primaryColor),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => selectedTime = t);
  }

  Future<void> _selectDeadline() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: AppConstants.primaryColor),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => selectedDeadline = d);
  }

  // In receive_from_record_dialog.dart - update the _submit method
  // In receive_from_record_dialog.dart - FIXED _submit method
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCompanyId == null) return;

    final company = ctrl.companies.firstWhereOrNull(
      (c) => c.id == selectedCompanyId,
    );
    if (company == null) return;

    final combinedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Get the source company from the record label
    final sourceCompanyName = widget.recordLabel.split(' → ')[0];
    final sourceCompany = ctrl.companies.firstWhereOrNull(
      (c) => c.name == sourceCompanyName,
    );

    // IMPORTANT: This is a COMPANY-TO-COMPANY receipt
    // It should NOT affect the normal account at all
    final receipt = CompanyTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      companyId: company.id,
      companyName: company.name,
      amount: double.parse(amountCtrl.text.trim()),
      date: combinedDate,
      deadLine: selectedDeadline,
      type: TransactionType.received,
      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      invoiceNumber: invoiceCtrl.text.trim().isEmpty
          ? null
          : invoiceCtrl.text.trim(),
      paymentMethod: selectedPaymentMethod,
      sourceType: SourceType.company, // ← KEEP AS COMPANY
      sourceCompanyId: sourceCompany?.id,
      sourceCompanyName: sourceCompanyName,
      recordId: widget.recordId,
    );

    await ctrl.addCompanyTransactionDirectly(receipt);

    Get.back();
    Get.snackbar(
      'Receipt Recorded',
      'Receipt recorded from ${company.name} to this record',
      backgroundColor: AppConstants.successColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}
