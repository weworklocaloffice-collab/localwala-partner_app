import 'package:flutter/material.dart';

class VendorGalleryModal {
  static Future<void> show(BuildContext context, {required List<String> images, int initialIndex = 0}) {
    return showDialog<void>(
      context: context,
      builder: (_) => _GalleryDialog(images: images, initialIndex: initialIndex),
    );
  }
}

class _GalleryDialog extends StatefulWidget {
  const _GalleryDialog({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_GalleryDialog> createState() => _GalleryDialogState();
}

class _GalleryDialogState extends State<_GalleryDialog> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          itemBuilder: (BuildContext context, int index) {
            return Image.network(widget.images[index], fit: BoxFit.contain);
          },
        ),
      ),
    );
  }
}
