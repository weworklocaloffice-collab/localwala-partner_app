/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/models/property_document.dart';
import 'package:partner/app/modules/realestate/vendor/documents/bloc/vendor_documents_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Documents: property picker + verification-status trail.
class VendorDocumentsScreen extends StatelessWidget {
  const VendorDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<VendorDocumentsBloc>(
      create: (_) => VendorDocumentsBloc()..add(const VendorDocumentsPropertiesRequested()),
      child: BlocBuilder<VendorDocumentsBloc, VendorDocumentsState>(
        builder: (BuildContext context, VendorDocumentsState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.realEstateNavDocuments)),
            body: Builder(
              builder: (BuildContext context) {
                switch (state.status) {
                  case VendorDocumentsStatus.initial:
                  case VendorDocumentsStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case VendorDocumentsStatus.failure:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(state.message.isNotEmpty ? state.message : l10n.somethingWentWrong),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<VendorDocumentsBloc>()
                                .add(const VendorDocumentsPropertiesRequested()),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  case VendorDocumentsStatus.loaded:
                    return _DocumentsBody(state: state, l10n: l10n);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _DocumentsBody extends StatelessWidget {
  const _DocumentsBody({required this.state, required this.l10n});

  final VendorDocumentsState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DropdownButtonFormField<String>(
            initialValue: state.selectedPropertyId,
            decoration: InputDecoration(labelText: l10n.realEstateDocumentsProperty),
            items: <DropdownMenuItem<String>>[
              for (final RealEstatePropertyModel p in state.properties)
                DropdownMenuItem<String>(
                  value: p.id,
                  child: Text(p.title ?? p.propertyCode ?? p.id, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (String? id) {
              if (id != null && id.isNotEmpty) {
                context.read<VendorDocumentsBloc>().add(VendorDocumentsPropertySelected(id));
              }
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.selectedPropertyId == null
                ? Center(child: Text(l10n.realEstateDocumentsPickHint))
                : state.documents.isEmpty
                    ? Center(child: Text(l10n.realEstateDocumentsEmpty))
                    : ListView.separated(
                        itemCount: state.documents.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int index) {
                          final RealEstateDocumentModel doc = state.documents[index];
                          final bool deletable = doc.status == 'PENDING';
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.divider),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        doc.category ?? '—',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: theme.titleText,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        doc.status ?? '—',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: theme.bodyText),
                                      ),
                                    ],
                                  ),
                                ),
                                if (deletable)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => context.read<VendorDocumentsBloc>().add(
                                          VendorDocumentDeleteRequested(
                                            state.selectedPropertyId!,
                                            doc.id,
                                          ),
                                        ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
