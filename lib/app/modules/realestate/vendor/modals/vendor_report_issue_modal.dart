import 'package:flutter/material.dart';

class VendorReportIssueModal {
  static Future<String?> show(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report an issue'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Describe the issue'),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Submit')),
        ],
      ),
    );
  }
}
