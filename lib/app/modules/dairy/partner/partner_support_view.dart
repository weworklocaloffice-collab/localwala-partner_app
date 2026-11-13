import 'dart:async';

import 'package:flutter/material.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';

class LegacyPartnerSupportScreen extends StatefulWidget {
  const LegacyPartnerSupportScreen({super.key});
  @override
  State<LegacyPartnerSupportScreen> createState() => _LegacyPartnerSupportScreenState();
}

class _LegacyPartnerSupportScreenState extends State<LegacyPartnerSupportScreen> {
  final PartnerRepository _repository = PartnerRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _tickets = <Map<String, dynamic>>[];
  String? _error;
  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final DioApiResponse response = await _repository.supportTickets();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() { _loading = false; _error = 'Support cases could not be loaded. Check your connection and try again.'; });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    final List<dynamic> raw = body['tickets'] is List ? body['tickets'] as List<dynamic> : <dynamic>[];
    setState(() { _loading = false; _tickets = raw.whereType<Map>().map((Map row) => Map<String, dynamic>.from(row)).toList(); });
  }

  Future<void> _create() async {
    final form = GlobalKey<FormState>();
    final subject = TextEditingController();
    final message = TextEditingController();
    String category = 'account';
    final bool? submit = await showDialog<bool>(context: context, builder: (BuildContext dialogContext) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
        title: const Text('Contact Dairy support'),
        content: Form(key: form, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'Category'), items: const <DropdownMenuItem<String>>[
            DropdownMenuItem(value: 'order', child: Text('Order')), DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
            DropdownMenuItem(value: 'payment', child: Text('Payment')), DropdownMenuItem(value: 'product_quality', child: Text('Product quality')),
            DropdownMenuItem(value: 'inventory', child: Text('Inventory')), DropdownMenuItem(value: 'account', child: Text('Account')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ], onChanged: (String? value) { if (value != null) setDialogState(() => category = value); }),
          TextFormField(controller: subject, decoration: const InputDecoration(labelText: 'Subject'), maxLength: 160,
            validator: (String? value) => (value?.trim().length ?? 0) < 4 ? 'Enter at least 4 characters' : null),
          TextFormField(controller: message, decoration: const InputDecoration(labelText: 'Describe the issue'), minLines: 3, maxLines: 5,
            validator: (String? value) => (value?.trim().length ?? 0) < 8 ? 'Add a little more detail' : null),
        ]))),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () { if (form.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('Submit case')),
        ],
      ),
    ));
    if (submit != true) return;
    final DioApiResponse response = await _repository.createSupportTicket(<String, dynamic>{
      'category': category, 'subject': subject.text.trim(), 'message': message.text.trim(), 'priority': 'normal',
    });
    if (!mounted) return;
    if (response.errorType == NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support case created.')));
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not create the support case. Try again.')));
    }
  }

  Future<void> _open(Map<String, dynamic> ticket) async {
    final List<dynamic> messages = ticket['messages'] is List ? ticket['messages'] as List<dynamic> : <dynamic>[];
    final TextEditingController reply = TextEditingController();
    await showDialog<void>(context: context, builder: (BuildContext dialogContext) => AlertDialog(
      title: Text('${ticket['ticketNo'] ?? 'Support case'} · ${ticket['status'] ?? ''}'),
      content: SizedBox(width: 460, child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Text(ticket['subject']?.toString() ?? ''), const Divider(),
        Flexible(child: ListView(shrinkWrap: true, children: messages.whereType<Map>().map((Map raw) {
          final Map<String, dynamic> row = Map<String, dynamic>.from(raw);
          return ListTile(title: Text(row['senderType']?.toString() ?? ''), subtitle: Text(row['body']?.toString() ?? ''));
        }).toList())),
        if (ticket['status'] != 'closed') TextField(controller: reply, decoration: const InputDecoration(labelText: 'Reply'), minLines: 1, maxLines: 3),
      ])),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
        if (ticket['status'] != 'closed') FilledButton(onPressed: () async {
          if (reply.text.trim().isEmpty) return;
          final String id = ticket['_id']?.toString() ?? ticket['id']?.toString() ?? '';
          final DioApiResponse result = await _repository.replySupportTicket(id, reply.text.trim());
          if (!dialogContext.mounted) return;
          Navigator.pop(dialogContext);
          if (result.errorType == NetErrorType.none) await _load();
        }, child: const Text('Send reply')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Support cases'), actions: <Widget>[IconButton(onPressed: _create, icon: const Icon(Icons.add), tooltip: 'Create support case')]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[Text(_error!), TextButton(onPressed: _load, child: const Text('Retry'))]))
        : RefreshIndicator(
      onRefresh: _load,
      child: _tickets.isEmpty
        ? ListView(children: const <Widget>[SizedBox(height: 160), Center(child: Text('No support cases yet.'))])
        : ListView.builder(itemCount: _tickets.length, itemBuilder: (BuildContext context, int index) {
            final Map<String, dynamic> ticket = _tickets[index];
            return Card(margin: const EdgeInsets.fromLTRB(12, 6, 12, 6), child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.support_agent_outlined)),
              title: Text('${ticket['ticketNo'] ?? ''} · ${ticket['subject'] ?? ''}'),
              subtitle: Text('${ticket['category'] ?? ''} · ${ticket['status'] ?? ''} · ${ticket['messages'] is List ? (ticket['messages'] as List).length : 0} updates'),
              trailing: const Icon(Icons.chevron_right), onTap: () => _open(ticket),
            ));
          }),
    ),
    floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: const Text('New case')),
  );
}

/// Outlet-scoped entry to the shared platform support-agent queues.
class PartnerSupportScreen extends StatefulWidget {
  const PartnerSupportScreen({super.key});

  @override
  State<PartnerSupportScreen> createState() => _PartnerSupportScreenState();
}

class _PartnerSupportScreenState extends State<PartnerSupportScreen> {
  final PartnerRepository _repository = PartnerRepository();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rooms = <Map<String, dynamic>>[];

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
    final DioApiResponse response = await _repository.supportChatList();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Dairy support is unavailable right now. Check your connection and try again.';
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    final List<dynamic> raw = body['chats'] is List ? body['chats'] as List<dynamic> : <dynamic>[];
    setState(() {
      _rooms = raw.whereType<Map>().map((Map row) => Map<String, dynamic>.from(row)).toList();
      _loading = false;
    });
  }

  Future<void> _start() async {
    final DioApiResponse response = await _repository.createSupportChat();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not start a Dairy support conversation.')));
      return;
    }
    final String roomId = decodeBody(response)['roomId']?.toString() ?? '';
    if (roomId.isEmpty) return;
    await _load();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => PartnerSupportConversationSheet(roomId: roomId, repository: _repository),
    );
    if (mounted) await _load();
  }

  Future<void> _open(Map<String, dynamic> room) async {
    final String roomId = room['_id']?.toString() ?? room['id']?.toString() ?? '';
    if (roomId.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => PartnerSupportConversationSheet(roomId: roomId, repository: _repository),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dairy support'), actions: <Widget>[
      IconButton(onPressed: _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh)),
    ]),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _start,
      icon: const Icon(Icons.support_agent),
      label: const Text('Chat with support'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Text(_error!), TextButton(onPressed: _load, child: const Text('Retry')),
              ]))
            : RefreshIndicator(
                onRefresh: _load,
                child: _rooms.isEmpty
                    ? ListView(children: const <Widget>[
                        SizedBox(height: 170),
                        Icon(Icons.support_agent_outlined, size: 42),
                        SizedBox(height: 12),
                        Center(child: Text('Start a chat with the Dairy support team.')),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 92),
                        itemCount: _rooms.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Map<String, dynamic> room = _rooms[index];
                          final Map<String, dynamic> business = room['business'] is Map
                              ? Map<String, dynamic>.from(room['business'] as Map)
                              : <String, dynamic>{};
                          return Card(margin: const EdgeInsets.fromLTRB(12, 6, 12, 6), child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.support_agent_outlined)),
                            title: Text(business['name']?.toString() ?? 'Dairy support'),
                            subtitle: Text('${room['lastMessage'] ?? 'Conversation'} · ${room['handoverState'] ?? room['status'] ?? 'open'}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _open(room),
                          ));
                        },
                      ),
              ),
  );
}

class PartnerSupportConversationSheet extends StatefulWidget {
  const PartnerSupportConversationSheet({super.key, required this.roomId, required this.repository});

  final String roomId;
  final PartnerRepository repository;

  @override
  State<PartnerSupportConversationSheet> createState() => _PartnerSupportConversationSheetState();
}

class _PartnerSupportConversationSheetState extends State<PartnerSupportConversationSheet> {
  final TextEditingController _message = TextEditingController();
  List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];
  String _handoverState = 'bot';
  String? _error;
  bool _loading = true;
  bool _sending = false;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _load();
    _poller = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    _message.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() { _loading = true; _error = null; });
    final DioApiResponse response = await widget.repository.supportChatMessages(widget.roomId);
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      if (!silent) setState(() { _loading = false; _error = 'Messages could not be loaded.'; });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    final List<dynamic> raw = body['chats'] is List ? body['chats'] as List<dynamic> : <dynamic>[];
    final Map<String, dynamic> room = body['room'] is Map ? Map<String, dynamic>.from(body['room'] as Map) : <String, dynamic>{};
    setState(() {
      _messages = raw.whereType<Map>().map((Map row) => Map<String, dynamic>.from(row)).toList();
      _handoverState = room['handoverState']?.toString() ?? _handoverState;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _send() async {
    final String text = _message.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _message.clear();
    final DioApiResponse response = await widget.repository.sendSupportChatMessage(widget.roomId, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (response.errorType != NetErrorType.none) {
      _message.text = text;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message was not sent. Try again.')));
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    _handoverState = body['handoverState']?.toString() ?? _handoverState;
    await _load(silent: true);
  }

  Future<void> _handover() async {
    final DioApiResponse response = await widget.repository.requestSupportChatHandover(widget.roomId);
    if (!mounted) return;
    if (response.errorType == NetErrorType.none) {
      final Map<String, dynamic> body = decodeBody(response);
      setState(() => _handoverState = body['assigned'] == true ? 'assigned' : 'queued');
      await _load(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.88,
    child: Column(children: <Widget>[
      ListTile(
        title: const Text('Dairy support'),
        subtitle: Text(_handoverState.replaceAll('_', ' ')),
        trailing: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
      ),
      if (_handoverState == 'bot') Align(alignment: Alignment.centerRight, child: TextButton.icon(
        onPressed: _handover, icon: const Icon(Icons.support_agent), label: const Text('Request an agent'),
      )),
      if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!)),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (BuildContext context, int index) {
                final Map<String, dynamic> row = _messages[index];
                final String role = row['senderRole']?.toString() ?? 'user';
                final bool mine = role == 'user';
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(row['message']?.toString() ?? ''),
                  ),
                );
              },
            )),
      SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Row(children: <Widget>[
          Expanded(child: TextField(controller: _message, minLines: 1, maxLines: 4,
            decoration: const InputDecoration(hintText: 'Write a message', border: OutlineInputBorder()))),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: _sending ? null : _send, icon: const Icon(Icons.send)),
        ]),
      )),
    ]),
  );
}
