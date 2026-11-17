/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Â© 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:partner/app/modules/realestate/executive/visits/bloc/executive_visits_bloc.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/executive/visit_detail/executive_visit_detail_view.dart';
import 'package:partner/app/modules/realestate/models/visit.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Executive work queue: accept â†’ check-in (geofenced, BR-08) â†’
/// complete/cancel, plus notes and follow-up scheduling.
///
/// Tabs mirror the visit lifecycle; each tab keeps its own cached page.
/// A check-in outside the visit radius surfaces the distance message.
class ExecutiveVisitsScreen extends StatelessWidget {
  const ExecutiveVisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<ExecutiveVisitsBloc>(
      create: (_) => ExecutiveVisitsBloc()..add(const ExecutiveVisitsTabSelected(executiveVisitsTabAll)),
      child: BlocBuilder<ExecutiveVisitsBloc, ExecutiveVisitsState>(
        builder: (BuildContext context, ExecutiveVisitsState state) {
          return DefaultTabController(
            length: executiveVisitsTabs.length,
            child: Scaffold(
              appBar: AppBar(title: Text(l10n.realEstateNavVisits)),
              body: Column(
                children: <Widget>[
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: executiveVisitsTabs
                        .map((ExecutiveVisitsTab t) => Tab(text: _tabLabel(l10n, t.id)))
                        .toList(),
                    onTap: (int index) => context
                        .read<ExecutiveVisitsBloc>()
                        .add(ExecutiveVisitsTabSelected(executiveVisitsTabs[index].id)),
                  ),
                  if (state.actionError.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.red.shade50,
                      child: Text(state.actionError, style: const TextStyle(color: Colors.red)),
                    ),
                  Expanded(child: _TabBody(state: state)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _tabLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case 'ASSIGNED':
      return l10n.realEstateExecAssigned;
    case 'ACCEPTED':
      return l10n.realEstateExecAccepted;
    case 'CHECK_IN':
      return l10n.realEstateExecCheckedIn;
    case 'IN_PROGRESS':
      return l10n.realEstateExecInProgress;
    case 'COMPLETED':
      return l10n.realEstateExecCompleted;
    case 'CANCELLED':
      return l10n.realEstateExecCancelled;
    default:
      return l10n.realEstateFilterAll;
  }
}

class _CheckInSheet extends StatefulWidget {
  const _CheckInSheet({required this.visit, required this.onCheckIn});

  final RealEstateVisitModel visit;
  final void Function(Position position) onCheckIn;

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  final RealEstateExecutiveRepository _repository = RealEstateExecutiveRepository();
  StreamSubscription<Position>? _subscription;
  RealEstatePropertyModel? _property;
  Position? _position;
  String? _error;
  bool _starting = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        setState(() {
          _error = l10n.realEstateExecLocationPermissionCheckIn;
          _starting = false;
        });
        return;
      }

      final String? propertyId = widget.visit.propertyId;
      if (propertyId != null && propertyId.isNotEmpty) {
        try {
          _property = await _repository.property(propertyId);
        } catch (_) {
          _property = null;
        }
      }

      final Position position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _position = position;
        _starting = false;
      });

      _subscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position position) {
        if (!mounted) return;
        setState(() => _position = position);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _starting = false;
      });
    }
  }

  double? _distanceMeters() {
    final Position? position = _position;
    final double? lat = _property?.latitude;
    final double? lng = _property?.longitude;
    if (position == null || lat == null || lng == null) return null;
    return Geolocator.distanceBetween(position.latitude, position.longitude, lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (_starting) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(l10n.realEstateExecLocating),
            ],
          ),
        ),
      );
    }

    final double? distance = _distanceMeters();
    final int radius = widget.visit.checkInRadiusMeters;
    final bool withinRadius = distance == null || distance <= radius;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.visit.property?.title ?? l10n.realEstateExecCheckIn,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))
            else if (distance == null)
              Text(l10n.realEstateExecLocationUnavailable)
            else ...<Widget>[
              Text('${l10n.realEstateExecDistance}: ${distance.toStringAsFixed(0)} m'),
              const SizedBox(height: 4),
              Text('${l10n.realEstateExecAllowedRadius}: $radius m'),
              const SizedBox(height: 8),
              Text(
                withinRadius ? l10n.realEstateExecWithinRadius : l10n.realEstateExecOutsideRadius,
                style: TextStyle(
                  color: withinRadius
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _position == null || _error != null || !withinRadius
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      widget.onCheckIn(_position!);
                    },
              icon: const Icon(Icons.my_location_outlined),
              label: Text(l10n.realEstateExecCheckIn),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.state});

  final ExecutiveVisitsState state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    switch (state.status) {
      case ExecutiveVisitsStatus.initial:
      case ExecutiveVisitsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ExecutiveVisitsStatus.failure:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.read<ExecutiveVisitsBloc>().add(const ExecutiveVisitsRefreshed()),
                child: Text(l10n.retry),
              ),
            ],
          ),
        );
      case ExecutiveVisitsStatus.loaded:
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ExecutiveVisitsBloc>().add(const ExecutiveVisitsRefreshed()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: Center(child: Text(l10n.realEstateExecNoVisitsState)),
              ),
            ),
          );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification n) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
              context.read<ExecutiveVisitsBloc>().add(const ExecutiveVisitsNextPage());
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async =>
                context.read<ExecutiveVisitsBloc>().add(const ExecutiveVisitsRefreshed()),
            child: ListView.separated(
              itemCount: state.items.length + (state.loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                if (index >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _VisitRow(
                  visit: state.items[index],
                  acting: state.actingId == state.items[index].id,
                );
              },
            ),
          ),
        );
    }
  }
}

class _VisitRow extends StatelessWidget {
  const _VisitRow({required this.visit, required this.acting});

  final RealEstateVisitModel visit;
  final bool acting;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String title = visit.property?.title ?? visit.propertyId ?? visit.id;
    final String sub =
        '${visit.status ?? '—'} · ${visit.scheduledAt?.toLocal().toString().split('.').first ?? l10n.realEstateExecUnscheduled}';

    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ExecutiveVisitDetailScreen(visitId: visit.id),
        ),
      ),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(sub),
          if (visit.notes != null && visit.notes!.isNotEmpty)
            Text('${l10n.realEstateExecNotes}: ${visit.notes}'),
        ],
      ),
      isThreeLine: true,
      trailing: acting
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : _Actions(visit: visit),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.visit});

  final RealEstateVisitModel visit;

  @override
  Widget build(BuildContext context) {
    final ExecutiveVisitsBloc bloc = context.read<ExecutiveVisitsBloc>();
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<Widget> buttons = <Widget>[];

    void snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

    if (visit.status == 'ASSIGNED') {
      buttons.add(TextButton(
        onPressed: () => bloc.add(ExecutiveVisitAccept(visit.id)),
        child: Text(l10n.realEstateExecAccept),
      ));
    }
    if (visit.status == 'ACCEPTED') {
      buttons.add(TextButton(
        onPressed: () => _openCheckIn(context, visit),
        child: Text(l10n.realEstateExecCheckIn),
      ));
    }
    if (visit.status == 'CHECK_IN' || visit.status == 'IN_PROGRESS' || visit.status == 'ACCEPTED') {
      buttons.add(TextButton(
        onPressed: () => _askNotes(context, l10n.realEstateExecCompleteVisit, (String notes) {
          bloc.add(ExecutiveVisitComplete(visit.id, notes: notes.isEmpty ? null : notes));
        }),
        child: Text(l10n.realEstateExecComplete),
      ));
    }
    if (visit.status != 'COMPLETED' && visit.status != 'CANCELLED') {
      buttons.add(TextButton(
        onPressed: () => _askNotes(context, l10n.realEstateExecCancelVisitReason, (String reason) {
          if (reason.trim().isEmpty) {
            snack(l10n.realEstateExecReasonRequiredCancel);
            return;
          }
          bloc.add(ExecutiveVisitCancel(visit.id, reason: reason.trim()));
        }),
        child: Text(l10n.realEstateDetailCancel),
      ));
    }
    buttons.add(IconButton(
      icon: const Icon(Icons.note_add_outlined),
      tooltip: l10n.realEstateExecAddNotes,
      onPressed: () => _askNotes(context, l10n.realEstateExecAddNotes, (String notes) {
        if (notes.trim().isEmpty) return;
        bloc.add(ExecutiveVisitAddNotes(visit.id, notes: notes.trim()));
      }),
    ));
    if (visit.status == 'COMPLETED' || visit.status == 'IN_PROGRESS' || visit.status == 'CHECK_IN') {
      buttons.add(IconButton(
        icon: const Icon(Icons.thumb_up_alt_outlined),
        tooltip: l10n.realEstateExecRecordInterest,
        onPressed: () => _askInterest(context, visit.id),
      ));
    }
    if (visit.leadId != null && (visit.status == 'COMPLETED' || visit.status == 'IN_PROGRESS')) {
      buttons.add(IconButton(
        icon: const Icon(Icons.schedule_outlined),
        tooltip: l10n.realEstateExecScheduleFollowUp,
        onPressed: () => _askFollowUp(context, visit.id, visit.leadId!),
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 0, children: buttons);
  }

  void _openCheckIn(BuildContext context, RealEstateVisitModel visit) {
    final ExecutiveVisitsBloc bloc = context.read<ExecutiveVisitsBloc>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _CheckInSheet(
        visit: visit,
        onCheckIn: (Position pos) {
          bloc.add(ExecutiveVisitCheckIn(visit.id, lng: pos.longitude, lat: pos.latitude));
        },
      ),
    );
  }

  void _askNotes(BuildContext context, String title, void Function(String) onSubmit) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TextEditingController c = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          maxLines: 3,
          decoration: InputDecoration(hintText: l10n.realEstateExecTypeHere),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.realEstateExecClose)),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onSubmit(c.text);
            },
            child: Text(l10n.realEstateExecSubmit),
          ),
        ],
      ),
    );
  }

  static const List<String> _followUpModes = <String>[
    'CALL',
    'WHATSAPP',
    'SMS',
    'EMAIL',
    'IN_PERSON',
  ];

  void _askInterest(BuildContext context, String visitId) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    const List<String> levels = <String>[
      'VERY_INTERESTED',
      'INTERESTED',
      'MAYBE_FOLLOW_UP',
      'NOT_INTERESTED',
      'INTERESTED_IN_OTHER_PROPERTY',
      'PURCHASE_DECISION_PENDING',
    ];
    const List<String> reasons = <String>[
      'PRICE',
      'LOCATION',
      'PROPERTY_CONDITION',
      'DOCUMENTATION',
      'NEGOTIATION',
      'ANOTHER_VISIT',
      'LOAN_REQUIRED',
      'OTHER',
    ];
    String level = levels[1];
    String reason = reasons[0];
    final TextEditingController reasonText = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setState) => AlertDialog(
          title: Text(l10n.realEstateExecRecordInterest),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButton<String>(
                  value: level,
                  isExpanded: true,
                  items: <DropdownMenuItem<String>>[
                    for (final String l in levels) DropdownMenuItem(value: l, child: Text(l, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (String? v) => setState(() => level = v ?? level),
                ),
                DropdownButton<String>(
                  value: reason,
                  isExpanded: true,
                  items: <DropdownMenuItem<String>>[
                    for (final String r in reasons) DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (String? v) => setState(() => reason = v ?? reason),
                ),
                if (reason == 'OTHER')
                  TextField(
                    controller: reasonText,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: l10n.realEstateExecReasonDetailHint,
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.realEstateExecClose)),
            FilledButton(
              onPressed: () {
                if (reason == 'OTHER' && reasonText.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.realEstateExecReasonDetailRequired)),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                context.read<ExecutiveVisitsBloc>().add(
                      ExecutiveVisitRecordInterest(
                        visitId,
                        level: level,
                        reason: reason,
                        reasonText: reasonText.text.trim().isEmpty ? null : reasonText.text.trim(),
                      ),
                    );
              },
              child: Text(l10n.realEstateExecRecord),
            ),
          ],
        ),
      ),
    );
  }

  void _askFollowUp(BuildContext context, String visitId, String leadId) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TextEditingController notes = TextEditingController();
    DateTime date = DateTime.now().add(const Duration(days: 1));
    String mode = 'CALL';
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setState) => AlertDialog(
          title: Text(l10n.realEstateExecScheduleFollowUp),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButton<String>(
                value: mode,
                items: <DropdownMenuItem<String>>[
                  for (final String m in _followUpModes) DropdownMenuItem(value: m, child: Text(m)),
                ],
                onChanged: (String? v) => setState(() => mode = v ?? mode),
              ),
              TextButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) setState(() => date = picked);
                },
                child: Text(
                  '${l10n.realEstateExecDate}: ${date.toLocal().toString().split(' ').first}',
                ),
              ),
              TextField(
                controller: notes,
                maxLines: 2,
                decoration: InputDecoration(hintText: l10n.realEstateExecNotesOptional),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.realEstateExecClose)),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.read<ExecutiveVisitsBloc>().add(
                      ExecutiveVisitScheduleFollowUp(
                        visitId,
                        leadId: leadId,
                        nextFollowUpAt: date,
                        mode: mode,
                        notes: notes.text.isEmpty ? null : notes.text,
                      ),
                    );
              },
              child: Text(l10n.realEstateExecSchedule),
            ),
          ],
        ),
      ),
    );
  }
}
