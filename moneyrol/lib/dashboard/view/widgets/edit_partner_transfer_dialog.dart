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
  late TextEditingController amountController;
  late TextEditingController descriptionController;
  late TextEditingController invoiceController;
  late TextEditingController paymentMethodController;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  DateTime? selectedDeadline;

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
    paymentMethodController = TextEditingController(
      text: widget.transfer.paymentMethod ?? '',
    );
    selectedDate = widget.transfer.date;
    selectedTime = TimeOfDay.fromDateTime(widget.transfer.date);
    selectedDeadline = widget.transfer.deadLine;
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
    final availableFromCompanies = controller.companies
        .where((c) => c.id != selectedToCompanyId)
        .toList();
    final availableToCompanies = controller.companies
        .where((c) => c.id != selectedFromCompanyId)
        .toList();

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
                      fromCompanies: availableFromCompanies,
                      toCompanies: availableToCompanies,
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
                    _buildTextField(
                      controller: paymentMethodController,
                      label: 'Payment Method',
                      hint: 'Cash, Bank Transfer, etc. (optional)',
                      icon: Icons.payment_rounded,
                    ),
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

  Widget _buildTransferFlow({
    required List<Company> fromCompanies,
    required List<Company> toCompanies,
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
              /// FROM PARTNER
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

                    /// DROPDOWN
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.borderColor),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedFromCompanyId,
                        isExpanded: true,
                        isDense: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        hint: Text(
                          'Select partner',
                          style: TextStyle(color: AppConstants.textSecondary),
                        ),
                        items: fromCompanies.map((company) {
                          final balance = controller.getCompanyBalance(
                            company.id,
                          );
                          return DropdownMenuItem<String>(
                            value: company.id,
                            child: SizedBox(
                              height: 50,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    company.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppConstants.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Balance: ${controller.currencySymbol}${balance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: balance >= 0
                                          ? AppConstants.incomeColor
                                          : AppConstants.expenseColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        selectedItemBuilder: (context) {
                          return fromCompanies.map((company) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                company.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        onChanged: (value) {
                          setState(() {
                            selectedFromCompanyId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Required';
                          if (value == selectedToCompanyId) {
                            return 'Cannot transfer from and to same partner';
                          }
                          return null;
                        },
                      ),
                    ),

                    // Show current balance when a company is selected
                    // Show current balance when a company is selected
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 18),
              ),

              /// TO PARTNER
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
                      height: 45,
                      decoration: BoxDecoration(
                        color: AppConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConstants.borderColor),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedToCompanyId,
                        isExpanded: true,
                        isDense: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        hint: Text(
                          'Select partner',
                          style: TextStyle(color: AppConstants.textSecondary),
                        ),
                        items: toCompanies.map((company) {
                          return DropdownMenuItem<String>(
                            value: company.id,
                            child: SizedBox(
                              height: 40,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  company.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppConstants.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        selectedItemBuilder: (context) {
                          return toCompanies.map((company) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                company.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        onChanged: (value) {
                          setState(() {
                            selectedToCompanyId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Required';
                          if (value == selectedFromCompanyId) {
                            return 'Cannot transfer to and from same partner';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (selectedFromCompanyId != null) const SizedBox(height: 8),
          Container(
            width: double.infinity, // Use full width instead of Get.width * .9
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 14,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  // Add Expanded to prevent overflow
                  child: Text(
                    'Current Balance: ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ),
                Obx(() {
                  final balance = controller.getCompanyBalance(
                    selectedFromCompanyId!,
                  );
                  return Text(
                    '${controller.currencySymbol}${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: balance >= 0
                          ? AppConstants.incomeColor
                          : AppConstants.expenseColor,
                    ),
                  );
                }),
              ],
            ),
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

              // NEW: Check if source company has enough balance for this amount
              if (selectedFromCompanyId != null) {
                final sourceCompanyBalance = controller.getCompanyBalance(
                  selectedFromCompanyId!,
                );
                final oldAmount = widget.transfer.amount;
                final amountDifference = amount - oldAmount;

                if (amountDifference > 0 &&
                    sourceCompanyBalance < amountDifference) {
                  final fromCompany = controller.companies.firstWhereOrNull(
                    (c) => c.id == selectedFromCompanyId,
                  );
                  return 'Insufficient balance in ${fromCompany?.name ?? "source partner"}\n'
                      'Available: ${controller.currencySymbol}${sourceCompanyBalance.toStringAsFixed(2)}\n'
                      'Extra needed: ${controller.currencySymbol}${amountDifference.toStringAsFixed(2)}';
                }
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
      final oldAmount = widget.transfer.amount;
      final amountDifference = newAmount - oldAmount;

      // Get current balance of source company
      double sourceCompanyBalance = controller.getCompanyBalance(
        fromCompany.id,
      );

      if (amountDifference > 0) {
        // Amount increased - need additional balance
        if (sourceCompanyBalance < amountDifference) {
          Get.snackbar(
            'Insufficient Balance',
            '${fromCompany.name} doesn\'t have enough balance.\n'
                'Current balance: ${controller.currencySymbol}${sourceCompanyBalance.toStringAsFixed(2)}\n'
                'Additional amount needed: ${controller.currencySymbol}${amountDifference.toStringAsFixed(2)}',
            backgroundColor: AppConstants.errorColor,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
          return;
        }
      }

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
        paymentMethod: paymentMethodController.text.trim().isEmpty
            ? null
            : paymentMethodController.text.trim(),
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
          paymentMethod: paymentMethodController.text.trim().isEmpty
              ? null
              : paymentMethodController.text.trim(),
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
          paymentMethod: paymentMethodController.text.trim().isEmpty
              ? null
              : paymentMethodController.text.trim(),
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
