import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class VendorShareListingModal {
  static Future<void> show(BuildContext context, {required String title, required String url}) async {
    await SharePlus.instance.share(ShareParams(text: '$title\n$url', subject: title));
  }
}
