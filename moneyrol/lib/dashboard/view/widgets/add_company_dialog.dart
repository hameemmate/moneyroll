import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/dashboard_controller.dart';

class AddCompanyDialog extends StatefulWidget {
  @override
  _AddCompanyDialogState createState() => _AddCompanyDialogState();
}

class _AddCompanyDialogState extends State<AddCompanyDialog> {
  final DashboardController controller = Get.find();
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController contactPersonController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Text(
        'Add Partners',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: Get.width,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Partner Name*',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Partner name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: contactPersonController,
                  decoration: InputDecoration(
                    labelText: 'Contact Person (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              controller.addCompany(
                name: nameController.text,
                description: descriptionController.text.isEmpty
                    ? null
                    : descriptionController.text,
                contactPerson: contactPersonController.text.isEmpty
                    ? null
                    : contactPersonController.text,
                phoneNumber: phoneController.text.isEmpty
                    ? null
                    : phoneController.text,
              );
              Get.back();
            }
          },
          child: Text('Add Partner'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    contactPersonController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
