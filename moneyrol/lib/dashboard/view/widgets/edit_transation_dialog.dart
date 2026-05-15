import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/constants/app_constants.dart';
import 'package:moneyrol/dashboard/model/transation_model.dart';
import '../../controller/dashboard_controller.dart';

class EditTransactionDialog extends StatefulWidget {
  final Transaction transaction;

  EditTransactionDialog({required this.transaction});

  @override
  _EditTransactionDialogState createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  final DashboardController controller = Get.find();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController amountController;
  late TextEditingController descriptionController;
  late TextEditingController sourceController;
  late TextEditingController referenceController;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late bool isCash;
  DateTime? rootDeadline;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    descriptionController = TextEditingController(
      text: widget.transaction.description ?? '',
    );
    sourceController = TextEditingController(
      text: widget.transaction.source ?? '',
    );
    referenceController = TextEditingController(
      text: widget.transaction.referenceNumber ?? '',
    );
    selectedDate = widget.transaction.date;
    selectedTime = TimeOfDay.fromDateTime(widget.transaction.date);
    isCash = widget.transaction.isCash;
    rootDeadline = widget.transaction.deadline;
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    sourceController.dispose();
    referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Transaction',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Obx(
                          () => Text(
                            'Currency: ${controller.currencySymbol}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppConstants.textSecondary,
                            ),
                          ),
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
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Amount
                    _buildAmountField(),
                    const SizedBox(height: 16),

                    // Date and Time
                    Row(
                      children: [
                        Expanded(child: _buildDateField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTimeField()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildTextField(
                      controller: descriptionController,
                      label: 'Description',
                      hint: 'What is this for? (optional)',
                      icon: Icons.description_rounded,
                    ),
                    const SizedBox(height: 16),

                    // Source
                    _buildTextField(
                      controller: sourceController,
                      label: 'Source',
                      hint: 'Where did it come from? (optional)',
                      icon: Icons.source_rounded,
                    ),
                    const SizedBox(height: 16),

                    // Payment Type
                    _buildPaymentTypeSection(),
                    const SizedBox(height: 16),

                    // Reference Number (if not cash)
                    if (!isCash) _buildReferenceField(),
                    if (!isCash) const SizedBox(height: 16),

                    // Tree-wide deadline (optional). Same purpose as in
                    // the add dialog — inherited by branches that don't
                    // set their own.
                    _buildRootDeadlineField(),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: AppConstants.borderColor),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: Get.width * .03,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Update Transaction',
                        style: TextStyle(
                          fontSize: Get.width * .03,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Amount',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.errorColor,
              ),
            ),
          ],
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
            style: TextStyle(fontSize: 16, color: AppConstants.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              hintStyle: TextStyle(
                color: AppConstants.textSecondary.withOpacity(0.6),
              ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.primaryColor,
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
        Text(
          'Date',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
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
                Text(
                  DateFormat('dd MMM yyyy').format(selectedDate),
                  style: TextStyle(
                    fontSize: Get.width * .03,
                    color: AppConstants.textPrimary,
                  ),
                ),
                Icon(
                  size: Get.width * .04,
                  Icons.calendar_month_rounded,
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
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
                  style: TextStyle(
                    fontSize: Get.width * .03,
                    color: AppConstants.textPrimary,
                  ),
                ),
                Icon(
                  size: Get.width * .04,
                  Icons.access_time_rounded,
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
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(fontSize: 16, color: AppConstants.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppConstants.textSecondary.withOpacity(0.6),
              ),
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

  Widget _buildPaymentTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.money_rounded,
                      size: 18,
                      color: isCash ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cash',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isCash
                            ? Colors.white
                            : AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
                selected: isCash,
                onSelected: (selected) {
                  setState(() {
                    isCash = selected;
                  });
                },
                selectedColor: Colors.blue.shade600,
                backgroundColor: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      size: 18,
                      color: !isCash ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Bank',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: !isCash
                            ? Colors.white
                            : AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
                selected: !isCash,
                onSelected: (selected) {
                  setState(() {
                    isCash = !selected;
                  });
                },
                selectedColor: Colors.blue.shade600,
                backgroundColor: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRootDeadlineField() {
    final hasDeadline = rootDeadline != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tree-wide deadline',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(optional)',
              style: TextStyle(fontSize: 11, color: AppConstants.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        rootDeadline ??
                        DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(
                      const Duration(days: 365 * 10),
                    ),
                  );
                  if (picked != null) {
                    setState(() => rootDeadline = picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          hasDeadline
                              ? DateFormat('dd MMM yyyy').format(rootDeadline!)
                              : 'No deadline',
                          style: TextStyle(
                            fontSize: 14,
                            color: hasDeadline
                                ? AppConstants.textPrimary
                                : AppConstants.textSecondary.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.event_outlined,
                        size: 18,
                        color: AppConstants.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasDeadline) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() => rootDeadline = null),
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppConstants.textSecondary,
                ),
                visualDensity: VisualDensity.compact,
                tooltip: 'Clear deadline',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildReferenceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reference Number',
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
          child: TextFormField(
            controller: referenceController,
            style: TextStyle(fontSize: 16, color: AppConstants.textPrimary),
            decoration: InputDecoration(
              hintText: 'Cheque/Transaction number (optional)',
              hintStyle: TextStyle(
                color: AppConstants.textSecondary.withOpacity(0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(
                Icons.numbers_rounded,
                color: AppConstants.textSecondary,
              ),
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

  void _updateTransaction() {
    if (_formKey.currentState!.validate()) {
      // Combine date and time
      final combinedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      controller.editTransaction(
        id: widget.transaction.id,
        amount: double.parse(amountController.text.trim()),
        date: combinedDateTime,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        source: sourceController.text.trim().isEmpty
            ? null
            : sourceController.text.trim(),
        isCash: isCash,
        referenceNumber: referenceController.text.trim().isEmpty
            ? null
            : referenceController.text.trim(),
        // deadline: rootDeadline,
      );

      Get.back();

      // Show success message
      Get.snackbar(
        'Updated',
        'Transaction updated successfully',
        backgroundColor: AppConstants.successColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
