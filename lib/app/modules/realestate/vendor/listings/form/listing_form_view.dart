/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partner/app/modules/realestate/models/geo_option.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/models/property_category.dart';
import 'package:partner/app/modules/realestate/vendor/listings/form/bloc/listing_form_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Create/edit a vendor listing.
///
/// Sections in order: basics → category → category-driven specs →
/// amenities → location (city cascade + coordinates) → photos → save.
/// Text basics live in controllers here; everything selectable or
/// asynchronous lives in the bloc. Coordinates come from GPS or manual
/// entry — the maps key is not provisioned, so there is no map picker.
class ListingFormScreen extends StatefulWidget {
  const ListingFormScreen({super.key, this.property});

  /// Set for edit; null for create.
  final RealEstatePropertyModel? property;

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _address;
  late final TextEditingController _pincode;
  late final TextEditingController _mapAddress;
  late final TextEditingController _project;
  late final TextEditingController _builder;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late String _transaction;
  late bool _priceOnRequest;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final RealEstatePropertyModel? p = widget.property;
    _title = TextEditingController(text: p?.title ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p?.price?.toStringAsFixed(0) ?? '');
    _address = TextEditingController(text: p?.addressLine ?? '');
    _pincode = TextEditingController(text: p?.pincode ?? '');
    _mapAddress = TextEditingController(text: p?.mapAddress ?? '');
    _project = TextEditingController(text: p?.projectName ?? '');
    _builder = TextEditingController(text: p?.builderName ?? '');
    _lat = TextEditingController(text: p?.latitude?.toString() ?? '');
    _lng = TextEditingController(text: p?.longitude?.toString() ?? '');
    _transaction = p?.transactionType ?? 'BUY';
    _priceOnRequest = p?.priceOnRequest ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _address.dispose();
    _pincode.dispose();
    _mapAddress.dispose();
    _project.dispose();
    _builder.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are off')));
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission needed to pin')));
      return;
    }
    try {
      final Position position = await Geolocator.getCurrentPosition();
      if (!context.mounted) return;
      _lat.text = position.latitude.toString();
      _lng.text = position.longitude.toString();
      context.read<ListingFormBloc>().add(
            ListingFormCoordsChanged(lat: position.latitude, lng: position.longitude),
          );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
      return;
    }
  }

  Future<void> _pickPhotos(BuildContext context, int remaining) async {
    if (remaining <= 0) return;
    final List<XFile> files = await _picker.pickMultiImage();
    if (!context.mounted) return;
    final ListingFormBloc bloc = context.read<ListingFormBloc>();
    for (final XFile file in files.take(remaining)) {
      bloc.add(ListingFormMediaPicked(file));
    }
  }

  void _pushCoords(BuildContext context) {
    final double? lat = double.tryParse(_lat.text.trim());
    final double? lng = double.tryParse(_lng.text.trim());
    if (lat == null || lng == null) return;
    context.read<ListingFormBloc>().add(ListingFormCoordsChanged(lat: lat, lng: lng));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool isEdit = widget.property != null;

    return BlocProvider<ListingFormBloc>(
      create: (_) => ListingFormBloc()..add(ListingFormLoadRequested(property: widget.property)),
      child: BlocConsumer<ListingFormBloc, ListingFormState>(
        listenWhen: (ListingFormState previous, ListingFormState current) =>
            previous.status != current.status || previous.message != current.message,
        listener: (BuildContext context, ListingFormState state) {
          if (state.status == ListingFormStatus.success) {
            Navigator.of(context).pop(true);
          } else if (state.message.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (BuildContext context, ListingFormState state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(isEdit ? l10n.realEstateFormEditListing : l10n.realEstateFormNewListing),
            ),
            body: Builder(
              builder: (BuildContext context) {
                switch (state.status) {
                  case ListingFormStatus.initial:
                  case ListingFormStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case ListingFormStatus.failure:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<ListingFormBloc>()
                                .add(ListingFormLoadRequested(property: widget.property)),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  case ListingFormStatus.ready:
                  case ListingFormStatus.submitting:
                  case ListingFormStatus.success:
                    return _FormBody(
                      state: state,
                      l10n: l10n,
                      title: _title,
                      description: _description,
                      price: _price,
                      address: _address,
                      pincode: _pincode,
                      mapAddress: _mapAddress,
                      project: _project,
                      builder: _builder,
                      lat: _lat,
                      lng: _lng,
                      transaction: _transaction,
                      priceOnRequest: _priceOnRequest,
                      onTransaction: (String v) => setState(() => _transaction = v),
                      onPriceOnRequest: (bool v) => setState(() => _priceOnRequest = v),
                      onUseMyLocation: () => _useMyLocation(context),
                      onCoordsEdited: () => _pushCoords(context),
                      onPickPhotos: () => _pickPhotos(
                        context,
                        20 - state.mediaUrls.length - state.uploading,
                      ),
                    );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.state,
    required this.l10n,
    required this.title,
    required this.description,
    required this.price,
    required this.address,
    required this.pincode,
    required this.mapAddress,
    required this.project,
    required this.builder,
    required this.lat,
    required this.lng,
    required this.transaction,
    required this.priceOnRequest,
    required this.onTransaction,
    required this.onPriceOnRequest,
    required this.onUseMyLocation,
    required this.onCoordsEdited,
    required this.onPickPhotos,
  });

  final ListingFormState state;
  final AppLocalizations l10n;
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController price;
  final TextEditingController address;
  final TextEditingController pincode;
  final TextEditingController mapAddress;
  final TextEditingController project;
  final TextEditingController builder;
  final TextEditingController lat;
  final TextEditingController lng;
  final String transaction;
  final bool priceOnRequest;
  final ValueChanged<String> onTransaction;
  final ValueChanged<bool> onPriceOnRequest;
  final VoidCallback onUseMyLocation;
  final VoidCallback onCoordsEdited;
  final VoidCallback onPickPhotos;

  @override
  Widget build(BuildContext context) {
    final ListingFormBloc bloc = context.read<ListingFormBloc>();
    final List<String> allowed = state.selectedCategory?.transactionTypes.isNotEmpty == true
        ? state.selectedCategory!.transactionTypes
        : const <String>['BUY', 'RENT'];
    final String effectiveTransaction =
        allowed.contains(transaction) ? transaction : allowed.first;
    final List<SpecFieldDescriptor> fields = specFieldsOf(state.selectedCategory?.specSchema);
    final bool submitting = state.status == ListingFormStatus.submitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.realEstateFormTitle),
          ),
          const SizedBox(height: 12),
          Text(l10n.realEstateFormTransaction, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: <ButtonSegment<String>>[
              if (allowed.contains('BUY')) ButtonSegment<String>(value: 'BUY', label: Text(l10n.realEstateFormBuy)),
              if (allowed.contains('RENT')) ButtonSegment<String>(value: 'RENT', label: Text(l10n.realEstateFormRent)),
            ],
            selected: <String>{effectiveTransaction},
            onSelectionChanged: (Set<String> v) => onTransaction(v.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.realEstateFormPrice, prefixText: '₹ '),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.realEstateFormPriceOnRequest),
            value: priceOnRequest,
            onChanged: onPriceOnRequest,
          ),
          TextField(
            controller: description,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.realEstateFormDescription),
          ),
          const SizedBox(height: 12),
          TextField(controller: project, decoration: InputDecoration(labelText: l10n.realEstateFormProject)),
          const SizedBox(height: 12),
          TextField(controller: builder, decoration: InputDecoration(labelText: l10n.realEstateFormBuilder)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: state.selectedCategory?.key,
            decoration: InputDecoration(labelText: l10n.realEstateFormCategory),
            items: state.categories
                .map((RealEstateCategoryModel c) => DropdownMenuItem<String>(
                      value: c.key,
                      child: Text(c.name ?? c.key ?? ''),
                    ))
                .toList(),
            onChanged: (String? key) {
              if (key != null && key.isNotEmpty) bloc.add(ListingFormCategorySelected(key));
            },
          ),
          if (fields.isNotEmpty) ...<Widget>[
            const SizedBox(height: 20),
            Text(l10n.realEstateFormSpecs, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final SpecFieldDescriptor field in fields) ...<Widget>[
              _SpecField(field: field, value: state.specs[field.key]),
              const SizedBox(height: 12),
            ],
          ],
          if ((state.selectedCategory?.amenityOptions.isNotEmpty ?? false)) ...<Widget>[
            const SizedBox(height: 8),
            Text(l10n.realEstateFormAmenities, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String option in state.selectedCategory!.amenityOptions)
                  FilterChip(
                    label: Text(option),
                    selected: state.amenities.contains(option),
                    onSelected: (_) => bloc.add(ListingFormAmenityToggled(option)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: state.selectedCityId,
            decoration: InputDecoration(labelText: l10n.realEstateFormCity),
            items: state.cities
                .map((RealEstateGeoOption c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.name),
                    ))
                .toList(),
            onChanged: (String? id) => bloc.add(ListingFormCitySelected(id)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: state.selectedLocalityId,
            decoration: InputDecoration(labelText: l10n.realEstateFormLocality),
            items: state.localities
                .map((RealEstateGeoOption c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.name),
                    ))
                .toList(),
            onChanged: (String? id) => bloc.add(ListingFormLocalitySelected(id)),
          ),
          const SizedBox(height: 12),
          TextField(controller: address, decoration: InputDecoration(labelText: l10n.realEstateFormAddress)),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: pincode,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.realEstateFormPincode),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(controller: mapAddress, decoration: InputDecoration(labelText: l10n.realEstateFormLandmark)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: lat,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(labelText: l10n.realEstateFormLatitude),
                  onChanged: (_) => onCoordsEdited(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: lng,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(labelText: l10n.realEstateFormLongitude),
                  onChanged: (_) => onCoordsEdited(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onUseMyLocation,
            icon: const Icon(Icons.my_location_outlined),
            label: Text(l10n.realEstateFormUseMyLocation),
          ),
          if (state.hasCoords)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${state.lat}, ${state.lng}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 20),
          Text(l10n.realEstateFormMedia, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _MediaStrip(state: state, onPickPhotos: onPickPhotos),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: submitting
                ? null
                : () => bloc.add(ListingFormSubmitted(ListingFormBasics(
                      title: title.text,
                      description: description.text,
                      transactionType: effectiveTransaction,
                      price: double.tryParse(price.text.trim()),
                      priceOnRequest: priceOnRequest,
                      addressLine: address.text,
                      pincode: pincode.text,
                      mapAddress: mapAddress.text,
                      projectName: project.text,
                      builderName: builder.text,
                    ))),
            child: submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.realEstateFormSave),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SpecField extends StatelessWidget {
  const _SpecField({required this.field, required this.value});

  final SpecFieldDescriptor field;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final ListingFormBloc bloc = context.read<ListingFormBloc>();
    final String label = field.required ? '${field.label} *' : field.label;

    switch (field.type) {
      case 'NUMBER':
        return _SpecText(
          fieldKey: field.key,
          label: label,
          initial: value?.toString() ?? '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        );
      case 'TEXT':
        return _SpecText(fieldKey: field.key, label: label, initial: value?.toString() ?? '', maxLines: 3);
      case 'ENUM':
        return DropdownButtonFormField<String>(
          initialValue: value?.toString() != null && field.options.contains(value.toString())
              ? value.toString()
              : null,
          decoration: InputDecoration(labelText: label),
          items: <DropdownMenuItem<String>>[
            if (!field.required)
              const DropdownMenuItem<String>(child: Text('—')),
            for (final String option in field.options)
              DropdownMenuItem<String>(value: option, child: Text(option)),
          ],
          onChanged: (String? v) => bloc.add(ListingFormSpecChanged(key: field.key, value: v)),
        );
      case 'BOOLEAN':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: value == true,
          onChanged: (bool v) => bloc.add(ListingFormSpecChanged(key: field.key, value: v)),
        );
      case 'DATE':
        return Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && context.mounted) {
                    context.read<ListingFormBloc>().add(ListingFormSpecChanged(
                          key: field.key,
                          value: picked.toIso8601String().split('T').first,
                        ));
                  }
                },
                child: Text(value?.toString().split('T').first ?? label),
              ),
            ),
            if (!field.required && value != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => bloc.add(ListingFormSpecChanged(key: field.key, value: null)),
              ),
          ],
        );
      case 'STRING':
      default:
        return _SpecText(fieldKey: field.key, label: label, initial: value?.toString() ?? '');
    }
  }
}

class _SpecText extends StatefulWidget {
  const _SpecText({
    required this.fieldKey,
    required this.label,
    required this.initial,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String fieldKey;
  final String label;
  final String initial;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  State<_SpecText> createState() => _SpecTextState();
}

class _SpecTextState extends State<_SpecText> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      decoration: InputDecoration(labelText: widget.label),
      onChanged: (String text) => context.read<ListingFormBloc>().add(
            ListingFormSpecChanged(key: widget.fieldKey, value: text.isEmpty ? null : text),
          ),
    );
  }
}

class _MediaStrip extends StatelessWidget {
  const _MediaStrip({required this.state, required this.onPickPhotos});

  final ListingFormState state;
  final VoidCallback onPickPhotos;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.mediaUrls.length + state.uploading + 1,
            separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return _AddTile(onTap: onPickPhotos, label: l10n.realEstateFormAddPhotos);
              }
              final int mediaIndex = index - 1;
              if (mediaIndex >= state.mediaUrls.length) {
                return Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              final String url = state.mediaUrls[mediaIndex];
              return Stack(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      resolveMediaUrl(url),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 96,
                        height: 96,
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: InkWell(
                      onTap: () => context
                          .read<ListingFormBloc>()
                          .add(ListingFormMediaRemoved(mediaIndex)),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  if (mediaIndex == 0)
                    Positioned(
                      bottom: 2,
                      left: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.realEstateFormCover,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.add_a_photo_outlined),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
