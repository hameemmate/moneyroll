// send_to_company_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/constants/app_constants.dart';
import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';
import 'package:moneyrol/dashboard/model/company_model.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/view/widgets/add_company_dialog.dart';

class SendToCompanyDialog extends StatefulWidget {
  final String? preSelectedCompanyId;

  const SendToCompanyDialog({super.key, this.preSelectedCompanyId});

  @override
  State<SendToCompanyDialog> createState() => _SendToCompanyDialogState();
}

class _SendToCompanyDialogState extends State<SendToCompanyDialog> {
  final DashboardController controller = Get.find();
  final _formKey = GlobalKey<FormState>();

  String? selectedCompanyId;
  String? selectedSourceCompanyId;
  SourceType selectedSourceType = SourceType.normal;
  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController invoiceController = TextEditingController();
  TextEditingController paymentMethodController = TextEditingController();
  TextEditingController deadlineController = TextEditingController();
  DateTime? selectedDeadline;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedCompanyId != null) {
      selectedCompanyId = widget.preSelectedCompanyId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      color: AppConstants.expenseColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.upload_rounded,
                      color: AppConstants.expenseColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send to Partner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        Obx(
                          () => Text(
                            'Currency: ${controller.currencySymbol}',
                            style: TextStyle(
                              fontSize: 12,
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
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTargetCompanyDropdown(),
                    const SizedBox(height: 20),
                    _buildSourceSelection(),
                    const SizedBox(height: 20),
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

              if (controller.companies.isEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton(
                    onPressed: _addNewPartner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Add Partner First',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _submitTransaction(paymentMethodController);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.expenseColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Send Amount',
                        style: TextStyle(
                          fontSize: 14,
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

  Widget _buildTargetCompanyDropdown() {
    // Get available companies (excluding the source company if partner source is selected)
    List<Company> availableCompanies = controller.companies;

    if (selectedSourceType == SourceType.company &&
        selectedSourceCompanyId != null) {
      availableCompanies = controller.companies
          .where((c) => c.id != selectedSourceCompanyId)
          .toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Send To Partner',
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
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 50),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedCompanyId,
            isExpanded: true,
            isDense: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: Icon(Icons.business_rounded, size: 20),
            ),
            style: TextStyle(fontSize: 14, color: AppConstants.textPrimary),
            dropdownColor: AppConstants.backgroundColor,
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppConstants.textSecondary,
              size: 20,
            ),
            hint: Text(
              availableCompanies.isEmpty
                  ? 'No partners available'
                  : 'Choose a partner',
              style: TextStyle(
                color: AppConstants.textSecondary.withOpacity(0.6),
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            items: availableCompanies.map((company) {
              return DropdownMenuItem<String>(
                value: company.id,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  child: Text(
                    company.name,
                    style: TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            }).toList(),
            onChanged: availableCompanies.isEmpty
                ? null
                : (value) {
                    setState(() {
                      selectedCompanyId = value;
                    });
                  },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a partner';
              }
              // Check if trying to send to the same partner from partner account
              if (selectedSourceType == SourceType.company &&
                  selectedSourceCompanyId != null &&
                  value == selectedSourceCompanyId) {
                return 'Cannot send to the same partner you are sending from';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSourceSelection() {
    // Get available source companies (excluding the target company)
    List<Company> availableSourceCompanies = controller.companies;

    if (selectedCompanyId != null) {
      availableSourceCompanies = controller.companies
          .where((c) => c.id != selectedCompanyId)
          .toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Send From',
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
        const SizedBox(height: 8),
        Column(
          children: [
            // Normal Account Option
            _buildSourceCard(
              label: 'Normal Account',
              type: SourceType.normal,
              icon: Icons.account_balance_wallet,
              balance: controller.getNormalBalance(),
              isSelected: selectedSourceType == SourceType.normal,
              onTap: () {
                setState(() {
                  selectedSourceType = SourceType.normal;
                  selectedSourceCompanyId = null;
                });
              },
            ),
            const SizedBox(height: 12),
            // Partner Account Option (only show if there are available partners)
            if (availableSourceCompanies.isNotEmpty)
              _buildPartnerSourceCard(availableSourceCompanies),
          ],
        ),
      ],
    );
  }

  Widget _buildSourceCard({
    required String label,
    required SourceType type,
    required IconData icon,
    required double balance,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.08)
              : AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : AppConstants.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppConstants.primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: balance >= 0
                    ? AppConstants.incomeColor.withOpacity(0.1)
                    : AppConstants.expenseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${controller.currencySymbol}${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: balance >= 0
                      ? AppConstants.incomeColor
                      : AppConstants.expenseColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerSourceCard(List<Company> availableCompanies) {
    final isSelected = selectedSourceType == SourceType.company;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppConstants.primaryColor.withOpacity(0.08)
            : AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.borderColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header with radio style
          InkWell(
            onTap: () {
              if (availableCompanies.isNotEmpty) {
                setState(() {
                  selectedSourceType = SourceType.company;
                  if (selectedSourceCompanyId == null &&
                      availableCompanies.isNotEmpty) {
                    selectedSourceCompanyId = availableCompanies.first.id;
                  }
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppConstants.primaryColor.withOpacity(0.1)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.business,
                      size: 20,
                      color: isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partner Account',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppConstants.primaryColor
                                : AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select partner to send from',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: AppConstants.primaryColor,
                    ),
                ],
              ),
            ),
          ),
          // Dropdown for selecting partner (only shown when this option is selected)
          if (isSelected) ...[
            const Divider(height: 1, indent: 48),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Partner',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppConstants.borderColor),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedSourceCompanyId,
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
                        'Choose a partner',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      items: availableCompanies.map((company) {
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
                        return availableCompanies.map((company) {
                          return Text(
                            company.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          );
                        }).toList();
                      },
                      onChanged: (value) {
                        setState(() {
                          selectedSourceCompanyId = value;
                          // Reset target company if it's the same as source
                          if (selectedCompanyId == value) {
                            selectedCompanyId = null;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a source partner';
                        }
                        if (value == selectedCompanyId) {
                          return 'Cannot send from and to the same partner';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: TextFormField(
            controller: amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 15, color: AppConstants.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              hintStyle: TextStyle(
                fontSize: 14,
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

              // Check if source has enough balance
              if (selectedSourceType == SourceType.normal) {
                final normalBalance = controller.getNormalBalance();
                if (amount > normalBalance) {
                  return 'Insufficient balance in normal account\nAvailable: ${controller.currencySymbol}${normalBalance.toStringAsFixed(2)}';
                }
              } else if (selectedSourceType == SourceType.company &&
                  selectedSourceCompanyId != null) {
                final companyBalance = controller.getCompanyBalance(
                  selectedSourceCompanyId!,
                );
                if (amount > companyBalance) {
                  final company = controller.companies.firstWhereOrNull(
                    (c) => c.id == selectedSourceCompanyId,
                  );
                  return 'Insufficient balance in ${company?.name ?? "partner"}\nAvailable: ${controller.currencySymbol}${companyBalance.toStringAsFixed(2)}';
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    fontSize: 13,
                    color: AppConstants.textPrimary,
                  ),
                ),
                Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    fontSize: 13,
                    color: AppConstants.textPrimary,
                  ),
                ),
                Icon(
                  Icons.access_time_rounded,
                  size: 18,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
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
                    fontSize: 13,
                    color: selectedDeadline == null
                        ? AppConstants.textSecondary
                        : AppConstants.textPrimary,
                  ),
                ),
                Icon(
                  Icons.event_rounded,
                  size: 18,
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

  void _addNewPartner() {
    Get.back();
    Future.delayed(const Duration(milliseconds: 300), () {
      showDialog(
        context: context,
        builder: (context) => AddCompanyDialog(),
      ).then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          showDialog(
            context: context,
            builder: (context) => SendToCompanyDialog(),
          );
        });
      });
    });
  }

  void _submitTransaction(TextEditingController paymentController) {
    // Additional validation before submission
    if (_formKey.currentState!.validate() && selectedCompanyId != null) {
      // Check if sending from partner account to same partner
      if (selectedSourceType == SourceType.company &&
          selectedSourceCompanyId != null &&
          selectedSourceCompanyId == selectedCompanyId) {
        Get.snackbar(
          'Invalid',
          'Cannot send money from a partner to the same partner',
          backgroundColor: AppConstants.errorColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final combinedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      controller.addCompanyTransaction(
        companyId: selectedCompanyId!,
        amount: double.parse(amountController.text.trim()),
        date: combinedDateTime,
        deadline: selectedDeadline,
        type: TransactionType.sent,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        invoiceNumber: invoiceController.text.trim().isEmpty
            ? null
            : invoiceController.text.trim(),
        paymentMethod: paymentController.text.trim().isEmpty
            ? null
            : paymentController.text.trim(),
        sourceType: selectedSourceType,
        sourceCompanyId: selectedSourceCompanyId,
      );

      Get.back();
      Get.snackbar(
        'Success',
        'Transaction added successfully',
        backgroundColor: AppConstants.successColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    invoiceController.dispose();
    paymentMethodController.dispose();
    super.dispose();
  }
}
