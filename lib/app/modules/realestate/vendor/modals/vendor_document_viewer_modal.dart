import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorDocumentViewerModal {
  static Future<void> show(BuildContext context, {required String url, String? title}) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title ?? 'Document'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open document'),
              onPressed: () async {
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
