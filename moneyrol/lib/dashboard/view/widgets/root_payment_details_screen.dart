import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/model/payment_entry_model.dart';
import 'package:moneyrol/dashboard/model/transation_model.dart';
import 'package:moneyrol/dashboard/view/widgets/add_payment_dialog.dart';

class PaymentChainScreen extends StatelessWidget {
  final Transaction rootTransaction;
  final List<PaymentNode> paymentTree;

  const PaymentChainScreen({
    super.key,
    required this.rootTransaction,
    required this.paymentTree,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chain: ${rootTransaction.displayId ?? rootTransaction.description ?? 'Normal'}',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Root card summary
          _buildRootSummary(),
          const SizedBox(height: 20),
          const Text(
            'Payment Flow',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._buildTreeNodes(paymentTree, 0),
        ],
      ),
    );
  }

  Widget _buildRootSummary() {
    final controller = Get.find<DashboardController>();
    double totalSent = 0, totalReceived = 0;
    void calc(List<PaymentNode> nodes) {
      for (final node in nodes) {
        final p = node.payment;
        final isFromNormal =
            p.fromType == PartyType.normal ||
            (p.fromType == PartyType.transaction &&
                controller.transactions.any((t) => t.id == p.fromId));
        final isToNormal =
            p.toType == PartyType.normal ||
            (p.toType == PartyType.transaction &&
                controller.transactions.any((t) => t.id == p.toId));
        if (isFromNormal && !isToNormal) totalSent += p.amount;
        if (!isFromNormal && isToNormal) totalReceived += p.amount;
        calc(node.children);
      }
    }

    calc(paymentTree);
    final netFlow = totalReceived - totalSent;
    final current = controller.getCurrentAmount(rootTransaction.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rootTransaction.displayId ?? 'Normal',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Original: ${controller.formatAmount(rootTransaction.amount)}',
            ),
            Text('Current: ${controller.formatAmount(current)}'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _chip('Sent', totalSent, Colors.red),
                _chip('Received', totalReceived, Colors.green),
                _chip('Net', netFlow, netFlow >= 0 ? Colors.green : Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, double value, Color color) {
    final controller = Get.find<DashboardController>();
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            controller.formatAmount(value),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTreeNodes(List<PaymentNode> nodes, int depth) {
    final result = <Widget>[];
    for (final node in nodes) {
      result.add(_TreeNodeCard(node: node, depth: depth));
      result.addAll(_buildTreeNodes(node.children, depth + 1));
    }
    return result;
  }
}

class _TreeNodeCard extends StatelessWidget {
  final PaymentNode node;
  final int depth;

  const _TreeNodeCard({required this.node, required this.depth});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final p = node.payment;

    // Use the deadline field directly from PaymentEntry
    final isOverdue =
        p.deadline != null && p.deadline!.isBefore(DateTime.now());
    final netObligation = controller.getNetObligationForBranch(p.id);
    final showOverdue = isOverdue && netObligation > 0.01;

    final bgColor = showOverdue ? Colors.red.shade50 : Colors.grey.shade50;
    final borderColor = showOverdue
        ? Colors.red.shade300
        : Colors.grey.shade300;

    return GestureDetector(
      onTap: () => _showPaymentDetails(p),
      child: Container(
        margin: EdgeInsets.only(left: depth * 16.0, top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${p.fromName} → ${p.toName}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  controller.formatAmount(p.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _editPayment(p),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _confirmDelete(p),
                ),
              ],
            ),
            if (p.deadline != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Due: ${DateFormat('dd MMM yyyy').format(p.deadline!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: showOverdue ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDetails(PaymentEntry p) {
    Get.dialog(
      AlertDialog(
        title: Text(p.displayId ?? 'Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${p.fromName} (${p.fromType.name})'),
            Text('To: ${p.toName} (${p.toType.name})'),
            Text(
              'Amount: ${Get.find<DashboardController>().formatAmount(p.amount)}',
            ),
            Text('Date: ${DateFormat('dd MMM yyyy hh:mm a').format(p.date)}'),
            if (p.deadline != null)
              Text(
                'Deadline: ${DateFormat('dd MMM yyyy').format(p.deadline!)}',
              ),
            if (p.paymentMethod != null) Text('Method: ${p.paymentMethod}'),
            if (p.description != null) Text('Note: ${p.description}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _editPayment(PaymentEntry p) {
    Get.back();
    showDialog(
      context: Get.context!,
      builder: (_) => AddPaymentDialog(paymentToEdit: p),
    );
  }

  void _confirmDelete(PaymentEntry p) {
    final controller = Get.find<DashboardController>();
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('This may affect chain balances. Continue?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deletePayment(p.id);
              Get.back();
              Get.back();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
