import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moneyrol/constants/app_constants.dart';

import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';
import 'package:moneyrol/dashboard/model/company_model.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/model/payment_entry_model.dart';
import 'package:moneyrol/dashboard/model/transation_model.dart';
import 'package:moneyrol/dashboard/view/widgets/add_payment_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/edit_company_transation_dialog.dart';
import 'package:moneyrol/dashboard/view/widgets/edit_transation_dialog.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  final DashboardController controller = Get.find();

  static const String allCompaniesId = 'all';
  static const String normalTransactionsId = 'normal';

  // Color constants

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Transaction History',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Column(
          children: [
            _buildCompanyFilterList(),
            _buildSummaryCard(),
            Expanded(
              child: controller.selectedCompanyId.value == normalTransactionsId
                  ? _buildNormalTransactionsList(context)
                  : _buildCompanyTransactionsList(context),
            ),
            SizedBox(height: Get.width * .13),
          ],
        ),
      ),
    );
  }

  // ---------------- FILTER CHIPS ----------------

  Widget _buildCompanyFilterList() {
    return Obx(() {
      final companies = controller.companies;

      final options = [
        {'id': allCompaniesId, 'name': 'All Partners'},
        {'id': normalTransactionsId, 'name': 'Normal Income'},
        ...companies.map((c) => {'id': c.id, 'name': c.name}),
      ];

      return Container(
        height: 52,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: options.length,
          itemBuilder: (_, i) {
            final opt = options[i];
            final isSelected = controller.selectedCompanyId.value == opt['id'];

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                checkmarkColor: Colors.white,
                selectedShadowColor: Colors.green,
                label: Text(
                  opt['name'] ?? "",
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppConstants.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) =>
                    controller.selectedCompanyId.value = opt['id'] ?? "",
                selectedColor: AppConstants.primaryColor,
                backgroundColor: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // ---------------- SUMMARY CARDS ----------------

  // For the All / Normal filters we keep showing a single summary card.
  // When a specific company is selected we show TWO stacked cards:
  //   1) the company's own balance (party-centric — includes
  //      company↔company transfers that don't touch the user)
  //   2) the user's relationship with this company (Normal-perspective —
  //      only counts CTs + payments that actually moved cash between the
  //      user and this company)
  Widget _buildSummaryCard() {
    return Obx(() {
      final sel = controller.selectedCompanyId.value;
      final isNormal = sel == normalTransactionsId;
      final isAll = sel == allCompaniesId;

      if (isAll || isNormal) {
        final received = controller.getSelectedTotalReceived();
        final sent = controller.getSelectedTotalSent();
        final balance = received - sent;
        final title = isAll ? 'Total Partners Balance' : 'Total Normal Income';
        // For Normal we frame the outstanding as "Cash on hand" so the
        // user instantly sees what they still hold after sending some out.
        // For All Partners we phrase it as a net balance with partners
        // overall.
        String? outstandingLabel;
        if (isNormal) {
          outstandingLabel = balance >= 0
              ? 'Cash on hand: ${controller.formatAmount(balance)}'
              : 'Overdrawn by ${controller.formatAmount(-balance)}';
        } else {
          if (balance > 0) {
            outstandingLabel =
                'Partners owe you ${controller.formatAmount(balance)} net';
          } else if (balance < 0) {
            outstandingLabel =
                'You owe partners ${controller.formatAmount(-balance)} net';
          } else {
            outstandingLabel = 'Settled with all partners';
          }
        }
        return _summaryCard(
          title: title,
          received: received,
          sent: sent,
          balance: balance,
          sentColor: isNormal ? Colors.grey : AppConstants.errorColor,
          outstandingLabel: outstandingLabel,
        );
      }

      // Specific company → single "You ↔ company" card.
      final company = controller.companies.firstWhereOrNull((c) => c.id == sel);
      final companyName = company?.name ?? 'Company';
      final userReceived = controller.getUserReceivedFromCompany(sel);
      final userSent = controller.getUserSentToCompany(sel);
      final userNet = userReceived - userSent;

      // Make the "they owe you back" or "you owe them" reality explicit —
      // because a partner that received cash via a transfer from your
      // pool is expected to settle it back, this label removes any
      // ambiguity about which way the obligation goes.
      String outstandingLabel;
      if (userNet < 0) {
        outstandingLabel =
            '$companyName owes you ${controller.formatAmount(-userNet)} back';
      } else if (userNet > 0) {
        outstandingLabel =
            'You owe $companyName ${controller.formatAmount(userNet)}';
      } else {
        outstandingLabel = 'Settled with $companyName';
      }

      return _summaryCard(
        title: 'You ↔ $companyName',
        subtitle: 'Cash that actually moved between you and this partner',
        received: userReceived,
        sent: userSent,
        balance: userNet,
        sentColor: AppConstants.errorColor,
        outstandingLabel: outstandingLabel,
        // When userNet < 0 the partner owes the user, so flip the Net
        // chip to a "they owe you" tone (green/positive for the user)
        // and prefix the visible amount with a minus to reflect the
        // direction of obligation.
      );
    });
  }

  Widget _summaryCard({
    required String title,
    String? subtitle,
    required double received,
    required double sent,
    required double balance,
    required Color sentColor,
    String? outstandingLabel,
    bool tightTop = false,
  }) {
    // When net is negative we still want the Net chip to read as a
    // meaningful number to the user; for company filters specifically a
    // negative net means "the partner owes you money", which is good news
    // for you. So tint that chip green to communicate "this is on your
    // side of the ledger" rather than red.
    final netIsCredit = balance < 0;
    final netColor = balance == 0
        ? Colors.grey
        : (netIsCredit
            ? AppConstants.successColor
            : AppConstants.errorColor);

    return Container(
      margin: EdgeInsets.fromLTRB(16, tightTop ? 0 : 12, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              _summaryItem('Received', received, AppConstants.successColor),
              _summaryItem('Sent', sent, sentColor),
              _summaryItem('Net', balance, netColor),
            ],
          ),
          if (outstandingLabel != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: netColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: netColor.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(
                    netIsCredit
                        ? Icons.savings_rounded
                        : (balance > 0
                            ? Icons.outbound_rounded
                            : Icons.check_circle_outline_rounded),
                    size: 16,
                    color: netColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      outstandingLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: netColor,
                      ),
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

  Widget _summaryItem(String label, double amount, Color color) {
    final controller = Get.find<DashboardController>();

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppConstants.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${controller.selectedCurrency.value.symbol}'
                '${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- TRANSACTION LISTS ----------------

  Widget _buildNormalTransactionsList(BuildContext context) {
    final transactions = controller.getFilteredNormalTransactions();
    final filteredPayments = controller.getFilteredPayments();

    // Build a single chronological feed: normal-transaction cards + payment
    // cards involving Normal. Each item carries its date so we can sort the
    // combined list newest-first regardless of source.
    final items = <_HistoryItem>[
      ...transactions.map(
        (t) => _HistoryItem(
          date: t.date,
          widget: _TransactionCard(
            displayId: t.displayId,
            parentId: t.id,
            title: t.description ?? 'Cash Received',
            subtitle: t.source ?? 'No source',
            date: t.date,
            amount: t.amount,
            currentAmount: controller.getCurrentAmount(t.id),
            isPositive: true,
            extraInfo:
                '${t.isCash ? 'Cash' : 'Bank'} • Ref: ${t.referenceNumber ?? 'N/A'}',
            onEdit: () => _showEditNormalTransactionDialog(context, t),
            onDelete: () => _showDeleteConfirmation(
              context,
              () => controller.deleteTransaction(t.id),
            ),
            onPay: () => _showTxnPayChooser(
              context,
              txnId: t.id,
              txnLabel: t.displayId ?? t.description ?? 'Transaction',
            ),
          ),
        ),
      ),
      ...filteredPayments.map(
        (p) => _HistoryItem(
          date: p.date,
          widget: _PaymentCard(
            payment: p,
            // Sign convention for the Normal feed: green when money landed
            // in Normal (directly or into a normal Transaction), red when
            // it left Normal.
            isPositiveFromSelectedPartyPov: _isNormalReceive(p),
            onTap: () => _showPaymentDetails(context, p),
            onDelete: () => _showDeleteConfirmation(
              context,
              () => controller.deletePayment(p.id),
            ),
          ),
        ),
      ),
    ];

    items.sort((a, b) => b.date.compareTo(a.date));
    return _buildTransactionList(items.map((i) => i.widget).toList());
  }

  // Determines whether a payment effectively sent money INTO the user's
  // Normal pool — either directly (toType=normal) or by landing on one of
  // the user's normal Transactions.
  bool _isNormalReceive(PaymentEntry p) {
    if (p.toType == PartyType.normal) return true;
    if (p.toType == PartyType.transaction &&
        controller.transactions.any((t) => t.id == p.toId)) {
      return true;
    }
    return false;
  }

  Widget _buildCompanyTransactionsList(BuildContext context) {
    final transactions = controller.getFilteredCompanyTransactions();
    final filteredPayments = controller.getFilteredPayments();
    final selectedCompany = controller.selectedCompanyId.value;

    final items = <_HistoryItem>[
      ...transactions.map(
        (ct) => _HistoryItem(
          date: ct.date,
          widget: _TransactionCard(
            displayId: ct.displayId,
            parentId: ct.id,
            title: ct.companyName,
            subtitle: ct.description ?? 'No description',
            date: ct.date,
            amount: ct.amount,
            currentAmount: controller.getCurrentAmount(ct.id),
            isPositive: ct.type == TransactionType.received,
            extraInfo: _buildCompanyExtraInfo(ct),
            onEdit: () => _showEditCompanyTransactionDialog(context, ct),
            onDelete: () => _showDeleteConfirmation(
              context,
              () => controller.deleteCompanyTransaction(ct.id),
            ),
            onPay: () => _showTxnPayChooser(
              context,
              txnId: ct.id,
              txnLabel: ct.displayId ?? ct.companyName,
            ),
          ),
        ),
      ),
      ...filteredPayments.map((p) {
        // Sign convention for the company feed: party-centric.
        //   • When a specific company is selected, green if that company
        //     is on the "to" side of the payment (it received money),
        //     red if it's on the "from" side (it sent money). This is
        //     what you'd intuitively expect when opening "Company B" and
        //     looking at a Company A → Company B transfer.
        //   • When "All" is selected, fall back to Normal's POV: green if
        //     money landed in Normal, red otherwise. Pure company↔company
        //     payments therefore show as red in the All feed (Normal
        //     didn't gain), which is consistent with how legacy "sent"
        //     CompanyTransactions render.
        bool isPositive;
        if (selectedCompany == 'all') {
          isPositive = p.toType == PartyType.normal;
        } else {
          isPositive =
              p.toType == PartyType.company && p.toId == selectedCompany;
        }
        return _HistoryItem(
          date: p.date,
          widget: _PaymentCard(
            payment: p,
            isPositiveFromSelectedPartyPov: isPositive,
            onTap: () => _showPaymentDetails(context, p),
            onDelete: () => _showDeleteConfirmation(
              context,
              () => controller.deletePayment(p.id),
            ),
          ),
        );
      }),
    ];

    items.sort((a, b) => b.date.compareTo(a.date));
    return _buildTransactionList(items.map((i) => i.widget).toList());
  }

  // Two-direction chooser shown when the user taps the Pay icon on a
  // transaction row. Lets them either send money FROM this transaction or
  // receive money INTO it without having to flip From/To inside the dialog.
  void _showTxnPayChooser(
    BuildContext context, {
    required String txnId,
    required String txnLabel,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  txnLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.red.shade600,
                  ),
                ),
                title: const Text(
                  'Send money FROM this',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Pay out from this transaction to a partner, person, or another transaction',
                ),
                onTap: () {
                  Get.back();
                  _openPaymentDialog(
                    context,
                    fromType: PartyType.transaction,
                    fromId: txnId,
                    fromName: txnLabel,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color: Colors.green.shade700,
                  ),
                ),
                title: const Text(
                  'Pay INTO this',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Record an incoming payment posted against this transaction',
                ),
                onTap: () {
                  Get.back();
                  _openPaymentDialog(
                    context,
                    toType: PartyType.transaction,
                    toId: txnId,
                    toName: txnLabel,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openPaymentDialog(
    BuildContext context, {
    PartyType? fromType,
    String? fromId,
    String? fromName,
    PartyType? toType,
    String? toId,
    String? toName,
    String? sourcePaymentId,
    String? sourceLabel,
  }) {
    showDialog(
      context: context,
      builder: (_) => AddPaymentDialog(
        prefilledFrom: fromType == null
            ? null
            : PartySelection(
                type: fromType,
                id: fromId,
                name: fromName ?? '',
              ),
        prefilledTo: toType == null
            ? null
            : PartySelection(
                type: toType,
                id: toId,
                name: toName ?? '',
              ),
        prefilledSourcePaymentId: sourcePaymentId,
        sourceLabel: sourceLabel,
      ),
    );
  }

  // Bottom sheet shown when a payment card is tapped. Lays out every
  // attribute of the PaymentEntry and provides one-tap navigation to the
  // source party and destination party so the user can trace the full
  // route of a transfer.
  void _showPaymentDetails(BuildContext context, PaymentEntry p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.displayId ?? 'Transfer',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy • hh:mm a').format(p.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      controller.formatAmount(p.amount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _detailPartyRow(
                  label: 'From',
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.red.shade600,
                  partyType: p.fromType,
                  partyId: p.fromId,
                  partyName: p.fromName,
                ),
                const SizedBox(height: 10),
                _detailPartyRow(
                  label: 'To',
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.green.shade700,
                  partyType: p.toType,
                  partyId: p.toId,
                  partyName: p.toName,
                ),
                if ((p.paymentMethod != null && p.paymentMethod!.isNotEmpty) ||
                    (p.description != null && p.description!.isNotEmpty)) ...[
                  const SizedBox(height: 14),
                  if (p.paymentMethod != null && p.paymentMethod!.isNotEmpty)
                    _detailRow('Method', p.paymentMethod!),
                  if (p.description != null && p.description!.isNotEmpty)
                    _detailRow('Note', p.description!),
                ],
                if (p.parentRefId != null) ...[
                  const SizedBox(height: 8),
                  _detailRow('Linked to', _labelForParent(p.parentRefId!)),
                ],
                _buildChainSection(context, p),
                const SizedBox(height: 18),
                // Primary action: send another transfer sourced from this
                // one. Pre-fills From = this payment's destination party
                // (because that's where the money sits now) and chains the
                // new payment back to this one via sourcePaymentId.
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    _openPaymentDialog(
                      context,
                      fromType: p.toType,
                      fromId: p.toId,
                      fromName: p.toName,
                      sourcePaymentId: p.id,
                      sourceLabel:
                          '${p.displayId ?? 'PAY'} • ${p.fromName} → ${p.toName} (${controller.formatAmount(p.amount)})',
                    );
                  },
                  icon: const Icon(Icons.fork_right_rounded, size: 18),
                  label: const Text('Send from this'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    minimumSize: const Size.fromHeight(0),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.back();
                          showDialog(
                            context: context,
                            builder: (_) => AddPaymentDialog(paymentToEdit: p),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo.shade700,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.indigo.shade200),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.back();
                          _showDeleteConfirmation(
                            context,
                            () => controller.deletePayment(p.id),
                          );
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Renders the backward (source) and forward (children) chain for a
  // payment so the user can see where the money came from and where it
  // went onward.
  Widget _buildChainSection(BuildContext context, PaymentEntry p) {
    final source = controller.getSourceChain(p.id);
    final children = controller.getDirectChildren(p.id);
    if (source.isEmpty && children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chain',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          if (source.isNotEmpty)
            ...source.map(
              (s) => _chainRow(
                icon: Icons.subdirectory_arrow_right_rounded,
                color: Colors.grey.shade700,
                label: 'Sourced from',
                payment: s,
              ),
            ),
          _chainRow(
            icon: Icons.fiber_manual_record_rounded,
            color: Colors.indigo.shade700,
            label: 'This payment',
            payment: p,
            highlight: true,
          ),
          if (children.isNotEmpty)
            ...children.map(
              (c) => _chainRow(
                icon: Icons.call_split_rounded,
                color: Colors.green.shade700,
                label: 'Onward to',
                payment: c,
              ),
            ),
        ],
      ),
    );
  }

  Widget _chainRow({
    required IconData icon,
    required Color color,
    required String label,
    required PaymentEntry payment,
    bool highlight = false,
  }) {
    final controllerLocal = Get.find<DashboardController>();
    return InkWell(
      onTap: highlight
          ? null
          : () {
              Get.back(); // close current sheet
              _showPaymentDetails(Get.context!, payment);
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: highlight ? color.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlight ? color.withOpacity(0.4) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${payment.displayId ?? 'PAY'} • ${payment.fromName} → ${payment.toName}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              controllerLocal.formatAmount(payment.amount),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            if (!highlight) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Colors.grey.shade500,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailPartyRow({
    required String label,
    required IconData icon,
    required Color color,
    required PartyType partyType,
    required String? partyId,
    required String partyName,
  }) {
    final canNavigate = partyType != PartyType.transaction || partyId != null;
    return InkWell(
      onTap: canNavigate ? () => _navigateToParty(partyType, partyId) : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partyName.isEmpty ? '—' : partyName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _typeLabel(partyType),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (canNavigate)
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade500,
              ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(PartyType t) {
    switch (t) {
      case PartyType.normal:
        return 'Personal / Cash';
      case PartyType.company:
        return 'Partner';
      case PartyType.transaction:
        return 'Transaction';
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Resolve a parent reference id to a human-friendly label so the user
  // can recognise which transaction this payment was posted against.
  String _labelForParent(String parentId) {
    final t = controller.transactions
        .firstWhereOrNull((x) => x.id == parentId);
    if (t != null) {
      return '${t.displayId ?? 'TXN'} • ${t.description ?? 'Normal'}';
    }
    final ct = controller.companyTransactions
        .firstWhereOrNull((x) => x.id == parentId);
    if (ct != null) {
      return '${ct.displayId ?? 'COMP'} • ${ct.companyName}';
    }
    return parentId;
  }

  // Single-tap navigation to a party. Switches the filter so the user can
  // see that party's full feed immediately. For a Transaction party we
  // route to its underlying company (CompanyTransaction) or to Normal (if
  // it's a normal Transaction).
  void _navigateToParty(PartyType type, String? id) {
    if (type == PartyType.normal) {
      controller.selectedCompanyId.value = normalTransactionsId;
      return;
    }
    if (type == PartyType.company && id != null) {
      controller.selectedCompanyId.value = id;
      return;
    }
    if (type == PartyType.transaction && id != null) {
      // Normal Transaction → Normal feed
      if (controller.transactions.any((t) => t.id == id)) {
        controller.selectedCompanyId.value = normalTransactionsId;
        return;
      }
      // CompanyTransaction → that company's feed
      final ct = controller.companyTransactions
          .firstWhereOrNull((x) => x.id == id);
      if (ct != null) {
        controller.selectedCompanyId.value = ct.companyId;
      }
    }
  }

  String _buildCompanyExtraInfo(CompanyTransaction ct) {
    String base =
        'Invoice: ${ct.invoiceNumber ?? 'N/A'} • ${ct.paymentMethod ?? 'N/A'}';

    // Only sent transactions can have deadline
    if (ct.type == TransactionType.sent && ct.deadLine != null) {
      final now = DateTime.now();
      final deadline = ct.deadLine!;

      final isOverdue = deadline.isBefore(
        DateTime(now.year, now.month, now.day),
      );

      final deadlineText = DateFormat('dd MMM yyyy').format(deadline);

      if (isOverdue) {
        return '$base • ⚠ Overdue (Due $deadlineText)';
      } else {
        return '$base • Due $deadlineText';
      }
    }

    return base;
  }

  Widget _buildTransactionList(List<Widget> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add transactions to see them here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  // ---------------- DIALOG HELPERS ----------------

  void _showDeleteConfirmation(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Get.back();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditNormalTransactionDialog(
    BuildContext context,
    Transaction transaction,
  ) {
    showDialog(
      context: context,
      builder: (_) => EditTransactionDialog(transaction: transaction),
    );
  }

  void _showEditCompanyTransactionDialog(
    BuildContext context,
    CompanyTransaction transaction,
  ) {
    showDialog(
      context: context,
      builder: (_) => EditCompanyTransactionDialog(transaction: transaction),
    );
  }
}

// ================= TRANSACTION CARD =================

class _TransactionCard extends StatefulWidget {
  const _TransactionCard({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.isPositive,
    required this.onDelete,
    required this.onEdit,
    required this.extraInfo,
    this.displayId,
    this.parentId,
    this.currentAmount,
    this.onPay,
  });

  final String title;
  final String subtitle;
  final DateTime date;
  final double amount;
  final bool isPositive;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final String extraInfo;
  // New optional fields for the payment-ledger features.
  final String? displayId;
  final String? parentId;
  final double? currentAmount;
  final VoidCallback? onPay;

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.extraInfo.contains('Overdue');
    final controller = Get.find<DashboardController>();
    final amountColor = widget.isPositive
        ? Colors.green.shade600
        : Colors.red.shade600;

    // Linked payments for this transaction — full tree (direct children +
    // every chain descendant) so the user can see the entire onward path
    // (e.g. TXN → A, A → B, B → C) without leaving this card.
    final List<PaymentEntry> linkedPayments = widget.parentId == null
        ? const []
        : controller.getPaymentTreeForTransaction(widget.parentId!);
    final hasPayments = linkedPayments.isNotEmpty;

    // Show the current/remaining balance only when it actually differs from
    // the original — otherwise the row stays clean.
    final showCurrent =
        widget.currentAmount != null &&
        (widget.currentAmount! - widget.amount).abs() > 0.005;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.displayId != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          widget.displayId!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.onPay != null)
                IconButton(
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.indigo.shade600,
                  ),
                  tooltip: 'Pay / Transfer',
                  onPressed: widget.onPay,
                  splashRadius: 20,
                ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.grey.shade700),
                onPressed: widget.onEdit,
                splashRadius: 20,
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.grey.shade700),
                onPressed: widget.onDelete,
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy • hh:mm a').format(widget.date),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: amountColor.withOpacity(0.3)),
                ),
                child: Text(
                  '${widget.isPositive ? '+' : '-'}'
                  '${controller.selectedCurrency.value.symbol}'
                  '${widget.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
              ),
            ],
          ),
          if (showCurrent) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 14,
                        color: Colors.indigo.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Current balance',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    controller.formatAmount(widget.currentAmount!),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 8),
          Text(
            widget.extraInfo,
            style: TextStyle(
              fontSize: 13,
              color: isOverdue ? Colors.red.shade600 : Colors.grey.shade600,
              fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (hasPayments) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: Colors.indigo.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Linked payments (${linkedPayments.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Column(
                children: linkedPayments
                    .map(
                      (p) =>
                          _PaymentRow(payment: p, parentId: widget.parentId!),
                    )
                    .toList(),
              ),
          ],
        ],
      ),
    );
  }
}

// Single row in the linked-payments expansion. Shows direction relative to
// the parent transaction so the user instantly knows whether this payment
// added to or subtracted from the parent's balance.
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, required this.parentId});

  final PaymentEntry payment;
  final String parentId;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final isParentIncoming =
        payment.toType == PartyType.transaction && payment.toId == parentId;
    final isParentOutgoing =
        payment.fromType == PartyType.transaction && payment.fromId == parentId;
    final color = isParentIncoming
        ? Colors.green.shade700
        : (isParentOutgoing ? Colors.red.shade700 : Colors.indigo.shade700);
    final sign = isParentIncoming ? '+' : (isParentOutgoing ? '-' : '');
    // Color the row background by direction relative to this transaction:
    //   • parent is "to"  → green tint (cash flowing INTO it)
    //   • parent is "from"→ red tint (cash flowing OUT of it)
    //   • parent is neither (chain descendant) → indigo tint (downstream
    //     activity that doesn't directly move this transaction's balance)
    final bgColor = isParentIncoming
        ? Colors.green.shade50
        : (isParentOutgoing ? Colors.red.shade50 : Colors.indigo.shade50);
    final borderColor = isParentIncoming
        ? Colors.green.shade100
        : (isParentOutgoing ? Colors.red.shade100 : Colors.indigo.shade100);

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (payment.displayId != null) ...[
                Text(
                  payment.displayId!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  '${payment.fromName} → ${payment.toName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$sign${controller.formatAmount(payment.amount)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _confirmDelete(context, controller, payment.id),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${DateFormat('dd MMM yyyy • hh:mm a').format(payment.date)}'
            '${payment.paymentMethod != null ? ' • ${payment.paymentMethod}' : ''}'
            '${payment.description != null && payment.description!.isNotEmpty ? ' • ${payment.description}' : ''}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    DashboardController controller,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text(
          'Remove this linked payment? The parent transaction\'s balance will recalculate.',
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              controller.deletePayment(id);
              Get.back();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Lightweight envelope used to sort heterogeneous history rows by date
// before rendering.
class _HistoryItem {
  final DateTime date;
  final Widget widget;
  _HistoryItem({required this.date, required this.widget});
}

// Card representation of a standalone PaymentEntry in the main history
// feed. Shown alongside transaction cards so the user sees a single
// chronological view of everything that touched the selected party.
class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.isPositiveFromSelectedPartyPov,
    required this.onDelete,
    this.onTap,
  });

  final PaymentEntry payment;
  // Drives the amount color and the +/- prefix. True when the selected
  // filter party received money in this payment, false when it sent.
  final bool isPositiveFromSelectedPartyPov;
  final VoidCallback onDelete;
  // Optional tap handler — typically used to open a detail bottom sheet
  // for tracing the payment to its source / destination party.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final amountColor = isPositiveFromSelectedPartyPov
        ? Colors.green.shade600
        : Colors.red.shade600;

    // Strongly differentiate transfer cards from transaction cards. Use a
    // soft indigo-tinted background and a thicker matching border so the
    // user can scan the history feed and immediately distinguish a
    // "Transfer" (PaymentEntry) from a "Transaction" / CompanyTransaction
    // record.
    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo.shade50, Colors.indigo.shade50.withOpacity(0.4)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade100.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: Colors.indigo.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (payment.displayId != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.indigo.shade100),
                            ),
                            child: Text(
                              payment.displayId!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.indigo.shade800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          'Transfer',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo.shade700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${payment.fromName} → ${payment.toName}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.grey.shade700),
                onPressed: onDelete,
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy • hh:mm a').format(payment.date),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: amountColor.withOpacity(0.3)),
                ),
                child: Text(
                  '${isPositiveFromSelectedPartyPov ? '+' : '-'}'
                  '${controller.formatAmount(payment.amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
              ),
            ],
          ),
          if ((payment.paymentMethod != null &&
                  payment.paymentMethod!.isNotEmpty) ||
              (payment.description != null &&
                  payment.description!.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 8),
            Text(
              _buildSubLine(),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );

    // Wrap in an InkWell so the whole card is tappable when an onTap is
    // provided. Use Material so the ripple stays inside the rounded
    // rectangle.
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      ),
    );
  }

  String _buildSubLine() {
    final parts = <String>[];
    if (payment.paymentMethod != null && payment.paymentMethod!.isNotEmpty) {
      parts.add(payment.paymentMethod!);
    }
    if (payment.description != null && payment.description!.isNotEmpty) {
      parts.add(payment.description!);
    }
    return parts.join(' • ');
  }
}
