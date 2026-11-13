import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/env.dart';

class PartnerProductEditScreen extends StatefulWidget {
  const PartnerProductEditScreen({super.key, required this.repository, required this.product});

  final PartnerRepository repository;
  final Map<String, dynamic> product;

  @override
  State<PartnerProductEditScreen> createState() => _PartnerProductEditScreenState();
}

class _PartnerProductEditScreenState extends State<PartnerProductEditScreen> {
  late final TextEditingController _name = TextEditingController(text: widget.product['name']?.toString() ?? '');
  late final TextEditingController _description = TextEditingController(text: widget.product['shortDescription']?.toString() ?? '');
  final ImagePicker _picker = ImagePicker();
  late final List<String> _images = (widget.product['images'] as List? ?? const <dynamic>[]).map((dynamic value) => value.toString()).toList();
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  String _url(String path) {
    if (path.startsWith('https://') || path.startsWith('http://')) return path;
    final String base = Environments.apiBaseURL.endsWith('/') ? Environments.apiBaseURL.substring(0, Environments.apiBaseURL.length - 1) : Environments.apiBaseURL;
    return '$base/storage/${path.startsWith('/') ? path.substring(1) : path}';
  }

  Future<void> _addImages() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) => SafeArea(child: Wrap(children: <Widget>[
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Choose from gallery'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Take a photo'), onTap: () => Navigator.pop(context, ImageSource.camera)),
      ])),
    );
    if (source == null || !mounted || _images.length >= 5) return;
    try {
      final List<XFile> picked;
      if (source == ImageSource.gallery) {
        picked = await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 80);
      } else {
        final XFile? photo = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 80);
        picked = photo == null ? <XFile>[] : <XFile>[photo];
      }
      if (picked.isEmpty || !mounted) return;
      setState(() => _uploading = true);
      for (final XFile file in picked.take(5 - _images.length)) {
        final DioApiResponse response = await widget.repository.uploadProductImage(filePath: file.path, filename: file.name);
        if (!mounted) return;
        if (response.errorType == NetErrorType.none) {
          final Map<String, dynamic> body = decodeBody(response);
          final String? path = (body['path'] ?? body['fileUrl'])?.toString();
          if (path != null && path.isNotEmpty) setState(() => _images.add(path));
        }
      }
    } on Exception {
      if (mounted) _message('Could not add the selected image. Check permissions and try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final String productId = (widget.product['_id'] ?? widget.product['id'])?.toString() ?? '';
    if (productId.isEmpty || _name.text.trim().length < 2 || _saving || _uploading) return;
    setState(() => _saving = true);
    final DioApiResponse response = await widget.repository.updateProduct(productId, <String, dynamic>{
      'name': _name.text.trim(),
      'shortDescription': _description.text.trim(),
      'images': List<String>.from(_images),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (response.errorType != NetErrorType.none) {
      final dynamic data = response.response?.data;
      final String message = data is Map ? data['message']?.toString() ?? 'Product could not be updated.' : 'Product could not be updated.';
      _message(message);
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit product')),
    body: ListView(padding: const EdgeInsets.all(16), children: <Widget>[
      TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Product name', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: _description, maxLength: 300, maxLines: 3, decoration: const InputDecoration(labelText: 'Short description', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      Text('Product photos', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
        ..._images.asMap().entries.map((MapEntry<int, String> entry) => Stack(children: <Widget>[
          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(_url(entry.value), width: 92, height: 92, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 92, height: 92, color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Icon(Icons.broken_image_outlined)))),
          Positioned(right: 0, top: 0, child: IconButton.filledTonal(onPressed: _saving ? null : () => setState(() => _images.removeAt(entry.key)), icon: const Icon(Icons.close, size: 16))),
        ])),
        if (_images.length < 5) OutlinedButton.icon(onPressed: _uploading ? null : _addImages, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Add photo')),
      ]),
      if (_uploading) ...<Widget>[const SizedBox(height: 8), const LinearProgressIndicator()],
      const SizedBox(height: 24),
      FilledButton.icon(onPressed: _saving || _uploading ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: const Text('Save product')),
    ]),
  );
}
