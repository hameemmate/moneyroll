import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/constants/app_constants.dart';
import 'package:moneyrol/dashboard/model/company_model.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/model/payment_entry_model.dart';
import 'package:moneyrol/dashboard/model/transation_model.dart';
import '../../controller/dashboard_controller.dart';

/// Unified "Transfer / Add Payment" dialog.
///
/// Lets the user record a single money movement between ANY two parties
/// (normal/personal, company/partner, or an existing transaction record).
/// One dialog therefore covers: company↔company, normal↔company,
/// transaction↔company, transaction↔transaction, etc.
///
/// Optionally pre-fill the "from" or "to" side by passing a [PartySelection]
/// — useful for the "Pay" button on a transaction row in history.
class AddPaymentDialog extends StatefulWidget {
  final PartySelection? prefilledFrom;
  final PartySelection? prefilledTo;
  // When set, the resulting PaymentEntry is linked to this prior payment
  // via sourcePaymentId. Used by the "Send from this" action on a payment
  // detail sheet to build a chained transfer.
  final String? prefilledSourcePaymentId;
  // Optional label shown in the header so the user can confirm which prior
  // payment they're chaining off of.
  final String? sourceLabel;
  // When provided the dialog runs in EDIT mode: every field is pre-filled
  // from this existing payment and Submit calls controller.editPayment
  // instead of addPayment. The PaymentEntry's id stays the same so the
  // chain (sourcePaymentId references from other payments) is preserved.
  final PaymentEntry? paymentToEdit;

  const AddPaymentDialog({
    super.key,
    this.prefilledFrom,
    this.prefilledTo,
    this.prefilledSourcePaymentId,
    this.sourceLabel,
    this.paymentToEdit,
  });

  bool get isEditing => paymentToEdit != null;

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

/// Lightweight value object describing a chosen party for a payment side.
class PartySelection {
  final PartyType type;
  final String? id;
  final String name;
  const PartySelection({required this.type, this.id, required this.name});
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final DashboardController controller = Get.find();
  final _formKey = GlobalKey<FormState>();

  // From-party state
  late PartyType _fromType;
  String? _fromId;
  String _fromName = '';

  // To-party state
  late PartyType _toType;
  String? _toId;
  String _toName = '';

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _paymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    final edit = widget.paymentToEdit;
    if (edit != null) {
      // EDIT MODE — populate every field from the existing PaymentEntry.
      _fromType = edit.fromType;
      _fromId = edit.fromId;
      _fromName = edit.fromName;
      _toType = edit.toType;
      _toId = edit.toId;
      _toName = edit.toName;
      _amountController.text = edit.amount.toString();
      _selectedDate = edit.date;
      _selectedTime = TimeOfDay.fromDateTime(edit.date);
      _paymentMethod = edit.paymentMethod ?? 'Cash';
      _descriptionController.text = edit.description ?? '';
      return;
    }
    final f = widget.prefilledFrom;
    final t = widget.prefilledTo;
    _fromType = f?.type ?? PartyType.normal;
    _fromId = f?.id;
    _fromName = f?.name ?? _defaultNameFor(_fromType);
    _toType = t?.type ?? PartyType.company;
    _toId = t?.id;
    _toName = t?.name ?? _defaultNameFor(_toType);
  }

  String _defaultNameFor(PartyType type) {
    switch (type) {
      case PartyType.normal:
        return 'Personal / Cash';
      case PartyType.company:
        return '';
      case PartyType.transaction:
        return '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppConstants.backgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: Get.height * 0.88),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (widget.prefilledSourcePaymentId != null) ...[
                  const SizedBox(height: 12),
                  _buildChainBanner(),
                ],
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildPartySection(
                        label: 'From',
                        type: _fromType,
                        selectedId: _fromId,
                        onTypeChanged: (t) => setState(() {
                          _fromType = t;
                          _fromId = null;
                          _fromName = _defaultNameFor(t);
                        }),
                        onEntitySelected: (id, name) => setState(() {
                          _fromId = id;
                          _fromName = name;
                        }),
                        accent: Colors.red.shade600,
                        icon: Icons.arrow_upward_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildArrowDivider(),
                      const SizedBox(height: 16),
                      _buildPartySection(
                        label: 'To',
                        type: _toType,
                        selectedId: _toId,
                        onTypeChanged: (t) => setState(() {
                          _toType = t;
                          _toId = null;
                          _toName = _defaultNameFor(t);
                        }),
                        onEntitySelected: (id, name) => setState(() {
                          _toId = id;
                          _toName = name;
                        }),
                        accent: Colors.green.shade600,
                        icon: Icons.arrow_downward_rounded,
                      ),
                      const SizedBox(height: 20),
                      _buildAmountField(),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildDateField()),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTimeField()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildPaymentMethodSection(),
                      const SizedBox(height: 14),
                      _buildDescriptionField(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildActionRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Small banner shown when this dialog is chaining off an existing
  // payment — confirms to the user which prior payment the new one will
  // be linked to via sourcePaymentId.
  Widget _buildChainBanner() {
    final label = widget.sourceLabel ?? widget.prefilledSourcePaymentId ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Row(
        children: [
          Icon(
            Icons.link_rounded,
            size: 16,
            color: Colors.indigo.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chained transfer — sourced from $label',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============================ HEADER ============================
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.shade600.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.swap_horiz_rounded,
            color: Colors.indigo.shade600,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEditing
                    ? 'Edit Transfer'
                    : 'Transfer / Add Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Obx(
                () => Text(
                  widget.isEditing
                      ? '${widget.paymentToEdit!.displayId ?? 'PAY'} • ${controller.currencySymbol}'
                      : 'Currency: ${controller.currencySymbol}',
                  style: TextStyle(
                    fontSize: 13,
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
    );
  }

  Widget _buildArrowDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppConstants.borderColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.arrow_downward_rounded,
            size: 18,
            color: AppConstants.textSecondary,
          ),
        ),
        Expanded(child: Divider(color: AppConstants.borderColor)),
      ],
    );
  }

  // ============================ PARTY SECTION ============================
  // The reusable "From" / "To" picker. Lets the user choose a party type
  // (normal/company/transaction) and then the specific entity for the
  // last two types.
  Widget _buildPartySection({
    required String label,
    required PartyType type,
    required String? selectedId,
    required void Function(PartyType) onTypeChanged,
    required void Function(String? id, String name) onEntitySelected,
    required Color accent,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _typeChip('Personal', PartyType.normal, type, onTypeChanged),
              _typeChip('Partner', PartyType.company, type, onTypeChanged),
              _typeChip(
                'Transaction',
                PartyType.transaction,
                type,
                onTypeChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildEntityPicker(type, selectedId, onEntitySelected),
        ],
      ),
    );
  }

  Widget _typeChip(
    String label,
    PartyType value,
    PartyType current,
    void Function(PartyType) onChange,
  ) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onChange(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppConstants.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppConstants.primaryColor
                : AppConstants.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppConstants.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEntityPicker(
    PartyType type,
    String? selectedId,
    void Function(String?, String) onSelected,
  ) {
    switch (type) {
      case PartyType.normal:
        return _entityInfoBox(
          icon: Icons.person_rounded,
          text: 'Personal / Cash',
        );
      case PartyType.company:
        return _buildCompanyDropdown(selectedId, onSelected);
      case PartyType.transaction:
        return _buildTransactionDropdown(selectedId, onSelected);
    }
  }

  Widget _entityInfoBox({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppConstants.textSecondary),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDropdown(
    String? selectedId,
    void Function(String?, String) onSelected,
  ) {
    final companies = controller.companies;
    if (companies.isEmpty) {
      return _entityInfoBox(
        icon: Icons.info_outline,
        text: 'No partners yet — add one first',
      );
    }
    return DropdownButtonFormField<String>(
      value: companies.any((c) => c.id == selectedId) ? selectedId : null,
      isExpanded: true,
      decoration: _dropdownDecoration('Select partner'),
      items: companies
          .map(
            (c) => DropdownMenuItem<String>(
              value: c.id,
              child: Text(c.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (id) {
        final c = companies.firstWhere(
          (x) => x.id == id,
          orElse: () => Company(id: '', name: ''),
        );
        if (id != null) onSelected(id, c.name);
      },
      validator: (v) => (v == null || v.isEmpty) ? 'Choose a partner' : null,
    );
  }

  Widget _buildTransactionDropdown(
    String? selectedId,
    void Function(String?, String) onSelected,
  ) {
    // Build a combined list of every transactionish thing the user can pay
    // against — both normal Transactions and CompanyTransactions.
    final items = <_TxnPickerItem>[];
    for (final t in controller.transactions) {
      items.add(
        _TxnPickerItem(
          id: t.id,
          label:
              '${t.displayId ?? 'TXN'} • ${t.description ?? 'Cash Received'} • ${controller.formatAmount(t.amount)}',
        ),
      );
    }
    for (final ct in controller.companyTransactions) {
      items.add(
        _TxnPickerItem(
          id: ct.id,
          label:
              '${ct.displayId ?? 'COMP'} • ${ct.companyName} • ${controller.formatAmount(ct.amount)} (${ct.type == TransactionType.received ? 'recv' : 'sent'})',
        ),
      );
    }
    if (items.isEmpty) {
      return _entityInfoBox(
        icon: Icons.info_outline,
        text: 'No transactions yet — add one first',
      );
    }
    final exists = items.any((i) => i.id == selectedId);
    return DropdownButtonFormField<String>(
      value: exists ? selectedId : null,
      isExpanded: true,
      decoration: _dropdownDecoration('Select transaction'),
      items: items
          .map(
            (i) => DropdownMenuItem<String>(
              value: i.id,
              child: Text(
                i.label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          )
          .toList(),
      onChanged: (id) {
        if (id == null) return;
        final picked = items.firstWhere(
          (i) => i.id == id,
          orElse: () => _TxnPickerItem(id: id, label: id),
        );
        onSelected(id, picked.label);
      },
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Choose a transaction' : null,
    );
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppConstants.textSecondary.withOpacity(0.6)),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppConstants.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppConstants.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppConstants.primaryColor),
      ),
    );
  }

  // ============================ AMOUNT / DATE / TIME ============================
  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Amount',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            Text(' *', style: TextStyle(color: AppConstants.errorColor)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: TextFormField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 15, color: AppConstants.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              hintStyle: TextStyle(
                color: AppConstants.textSecondary.withOpacity(0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              prefixIcon: Obx(
                () => Container(
                  width: 36,
                  alignment: Alignment.center,
                  child: Text(
                    controller.currencySymbol,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter amount';
              final n = double.tryParse(v.trim());
              if (n == null || n <= 0) return 'Enter a valid amount';
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
          onTap: _pickDate,
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
                Flexible(
                  child: Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppConstants.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
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
          onTap: _pickTime,
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
                  _selectedTime.format(context),
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildPaymentMethodSection() {
    final methods = ['Cash', 'Bank Transfer', 'Cheque', 'Card', 'Other'];
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: methods.map((m) {
            final selected = m == _paymentMethod;
            return GestureDetector(
              onTap: () => setState(() => _paymentMethod = m),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppConstants.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppConstants.primaryColor
                        : AppConstants.borderColor,
                  ),
                ),
                child: Text(
                  m,
                  style: TextStyle(
                    color: selected ? Colors.white : AppConstants.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
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
            controller: _descriptionController,
            style: TextStyle(fontSize: 14, color: AppConstants.textPrimary),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'What is this transfer for? (optional)',
              hintStyle: TextStyle(
                color: AppConstants.textSecondary.withOpacity(0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================ ACTIONS ============================
  Widget _buildActionRow() {
    return Row(
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
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              widget.isEditing ? 'Save Changes' : 'Record Transfer',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    // Field-level validation first.
    if (!_formKey.currentState!.validate()) return;

    // Same-party guard so we don't record meaningless self-transfers like
    // company X -> company X.
    if (_fromType == _toType &&
        _fromType != PartyType.normal &&
        _fromId != null &&
        _fromId == _toId) {
      Get.snackbar(
        'Invalid',
        'From and To cannot be the same entity',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Require an explicit entity selection for company/transaction sides.
    if (_fromType != PartyType.normal &&
        (_fromId == null || _fromId!.isEmpty)) {
      Get.snackbar(
        'Missing',
        'Choose the "From" entity',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (_toType != PartyType.normal && (_toId == null || _toId!.isEmpty)) {
      Get.snackbar(
        'Missing',
        'Choose the "To" entity',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final combinedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // If either side references an existing transaction, link the payment
    // to it via parentRefId so getCurrentAmount() picks it up. If both
    // sides reference a transaction we link to the "to" side (money in).
    String? parentRefId;
    if (_toType == PartyType.transaction) {
      parentRefId = _toId;
    } else if (_fromType == PartyType.transaction) {
      parentRefId = _fromId;
    }

    final amount = double.parse(_amountController.text.trim());
    final fromName =
        _fromName.isEmpty ? _defaultNameFor(_fromType) : _fromName;
    final toName = _toName.isEmpty ? _defaultNameFor(_toType) : _toName;
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    if (widget.isEditing) {
      // EDIT MODE — update the existing PaymentEntry in place. The dialog
      // does not let the user re-target the source link (sourcePaymentId)
      // because that's an immutable lineage attribute; editPayment in the
      // controller preserves it automatically when null is passed.
      final id = widget.paymentToEdit!.id;
      await controller.editPayment(
        id: id,
        fromType: _fromType,
        fromId: _fromId,
        fromName: fromName,
        toType: _toType,
        toId: _toId,
        toName: toName,
        amount: amount,
        date: combinedDate,
        description: description,
        paymentMethod: _paymentMethod,
        parentRefId: parentRefId,
      );
      Get.back();
      Get.snackbar(
        'Success',
        'Transfer ${widget.paymentToEdit!.displayId ?? id} updated',
        backgroundColor: AppConstants.successColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final entry = await controller.addPayment(
      fromType: _fromType,
      fromId: _fromId,
      fromName: fromName,
      toType: _toType,
      toId: _toId,
      toName: toName,
      amount: amount,
      date: combinedDate,
      description: description,
      paymentMethod: _paymentMethod,
      parentRefId: parentRefId,
      sourcePaymentId: widget.prefilledSourcePaymentId,
    );

    // Close the dialog FIRST, then show the snackbar. Doing it the other
    // way around can let Get.back() pop the snackbar instead of the dialog
    // on some GetX versions.
    Get.back();
    Get.snackbar(
      'Success',
      'Transfer ${entry.displayId} of ${controller.formatAmount(entry.amount)} recorded',
      backgroundColor: AppConstants.successColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class _TxnPickerItem {
  final String id;
  final String label;
  _TxnPickerItem({required this.id, required this.label});
}
