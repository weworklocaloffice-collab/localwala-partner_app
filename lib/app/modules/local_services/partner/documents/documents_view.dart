/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/env.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Provider documents screen: upload verification documents and track their
/// review status. Verification itself is an admin action.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  static const List<String> _kinds = <String>[
    'id_proof',
    'address_proof',
    'license',
    'insurance',
    'certification',
    'other',
  ];

  bool _loading = true;
  bool _uploading = false;
  String? _error;
  List<dynamic> _documents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final DioApiResponse response = await _repository.documents();
      final Map<String, dynamic> body = decodeBody(response);
      setState(() {
        _documents = body['results'] ?? body['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String _resolveFileUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final String base = Environments.apiBaseURL;
    return '$base/storage/${path.replaceFirst(RegExp(r'^/+'), '')}';
  }

  String _humanize(String value) {
    if (value.isEmpty) return 'Document';
    final String spaced = value.replaceAll('_', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  String _formatDate(dynamic value) {
    final DateTime? parsed =
        DateTime.tryParse('${value ?? ''}')?.toLocal();
    if (parsed == null) return '';
    final String month = parsed.month.toString().padLeft(2, '0');
    final String day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }

  Color _statusColor(String status, ColorScheme colors) {
    switch (status) {
      case 'verified':
        return colors.primary;
      case 'rejected':
        return colors.error;
      default:
        return colors.tertiary;
    }
  }

  Future<void> _openFile(String path) async {
    final Uri uri = Uri.parse(_resolveFileUrl(path));
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _upload() async {
    final _PendingDocument? pending = await showDialog<_PendingDocument>(
      context: context,
      builder: (BuildContext dialogContext) {
        String kind = _kinds.first;
        PlatformFile? file;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final AppLocalizations? l10n = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(l10n?.ls_upload_document ?? 'Upload document'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: kind,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.ls_document_type ?? 'Document type',
                      border: const OutlineInputBorder(),
                    ),
                    items: _kinds
                        .map(
                          (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(_humanize(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value != null) setDialogState(() => kind = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      TextButton.icon(
                        onPressed: () async {
                          final FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: <String>[
                              'pdf',
                              'jpg',
                              'jpeg',
                              'png',
                              'webp',
                            ],
                          );
                          if (!dialogContext.mounted) return;
                          if (result != null && result.files.single.path != null) {
                            setDialogState(() => file = result.files.single);
                          }
                        },
                        icon: const Icon(Icons.attach_file),
                        label: Text(l10n?.ls_choose_file ?? 'Choose file'),
                      ),
                      if (file != null)
                        Expanded(
                          child: Text(
                            file!.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(l10n?.ls_cancel ?? 'Cancel'),
                ),
                FilledButton(
                  onPressed: file == null
                      ? null
                      : () => Navigator.of(dialogContext).pop(
                            _PendingDocument(
                              kind: kind,
                              path: file!.path!,
                              name: file!.name,
                            ),
                          ),
                  child: Text(l10n?.ls_upload ?? 'Upload'),
                ),
              ],
            );
          },
        );
      },
    );
    if (pending == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final DioApiResponse uploaded = await _repository.uploadDocumentFile(
        filePath: pending.path,
        filename: pending.name,
      );
      final Map<String, dynamic> body = decodeBody(uploaded);
      final String path = '${body['path'] ?? body['fileUrl'] ?? ''}';
      if (path.isEmpty) {
        throw Exception('Upload did not return a file path');
      }
      await _repository.uploadDocument(<String, dynamic>{
        'kind': pending.kind,
        'fileUrl': path,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.ls_document_submitted ?? 'Document submitted for verification')),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.ls_upload_failed(e) ?? 'Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.ls_documents_title ?? 'Documents'),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context)?.ls_refresh ?? 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _load, child: Text(l10n?.ls_retry ?? 'Retry')),
                ],
              ),
            )
          : Column(
              children: <Widget>[
                if (_uploading) const LinearProgressIndicator(),
                Expanded(
                  child: _documents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(Icons.folder_open, size: 48),
                              const SizedBox(height: 12),
                              Text(l10n?.ls_no_documents ?? 'No documents uploaded yet'),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _uploading ? null : _upload,
                                icon: const Icon(Icons.upload_file),
                                label: Text(l10n?.ls_upload_document ?? 'Upload document'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                            itemCount: _documents.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Map<String, dynamic> doc =
                                  (_documents[index] as Map)
                                      .cast<String, dynamic>();
                              final String status =
                                  '${doc['status'] ?? 'pending'}';
                              final String fileUrl =
                                  '${doc['fileUrl'] ?? ''}';
                              final String rejectReason =
                                  '${doc['rejectReason'] ?? ''}';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.description_outlined,
                                  ),
                                  title: Text(_humanize('${doc['kind'] ?? ''}')),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        '${AppLocalizations.of(context)?.ls_status ?? 'Status'}: ${_humanize(status)}'
                                        '${_formatDate(doc['createdAt']).isEmpty ? '' : ' · ${_formatDate(doc['createdAt'])}'}',
                                      ),
                                      if (status == 'rejected' &&
                                          rejectReason.isNotEmpty)
                                        Text(
                                          '${AppLocalizations.of(context)?.ls_reason ?? 'Reason'}: $rejectReason',
                                          style: TextStyle(
                                            color: colors.error,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Chip(
                                        label: Text(_humanize(status)),
                                        labelStyle: TextStyle(
                                          fontSize: 11,
                                          color: _statusColor(status, colors),
                                        ),
                                        side: BorderSide(
                                          color: _statusColor(status, colors),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      if (fileUrl.isNotEmpty)
                                        IconButton(
                                          onPressed: () => _openFile(fileUrl),
                                          icon: const Icon(
                                            Icons.open_in_new,
                                            size: 18,
                                          ),
                                          tooltip: AppLocalizations.of(context)?.ls_open_file ?? 'Open file',
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: _loading || _error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _uploading ? null : _upload,
              icon: const Icon(Icons.upload_file),
              label: Text(AppLocalizations.of(context)?.ls_upload ?? 'Upload'),
            ),
    );
  }
}

class _PendingDocument {
  const _PendingDocument({
    required this.kind,
    required this.path,
    required this.name,
  });

  final String kind;
  final String path;
  final String name;
}
