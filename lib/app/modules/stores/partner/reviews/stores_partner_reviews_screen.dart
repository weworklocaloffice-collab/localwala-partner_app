import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:flutter/material.dart';

class StoresPartnerReviewsScreen extends StatefulWidget {
  const StoresPartnerReviewsScreen({super.key});
  @override
  State<StoresPartnerReviewsScreen> createState() => _StoresPartnerReviewsScreenState();
}

class _StoresPartnerReviewsScreenState extends State<StoresPartnerReviewsScreen> {
  StoresPartnerRepository? _repo;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _repo = StoresPartnerRepository();
    _load();
  }

  Future<void> _load() async {
    final StoresPartnerRepository r = _repo ?? StoresPartnerRepository();
    try {
      final Map<String, dynamic> body = await r.listReviews();
      if (!mounted) return;
      setState(() {
        _rows = (body['items'] ?? body['results'] ?? body['reviews'] ?? const <dynamic>[])
            .whereType<Map>()
            .map((Map<dynamic, dynamic> m) => Map<String, dynamic>.from(m))
            .toList();
        _loading = false;
        _error = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.storesTitleReviews)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _rows.isEmpty
                  ? Center(child: Text(l10n.storesNoReviews))
                  : ListView.separated(
                      itemCount: _rows.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> r = _rows[index];
                        return ListTile(
                          leading: const Icon(Icons.rate_review_outlined),
                          title: Text('${r['title'] ?? AppLocalizations.of(context)!.storesReview}'),
                          subtitle: Text('${r['comment'] ?? ''}'),
                          trailing: Text('${r['rating'] ?? ''} ★'),
                        );
                      },
                    ),
    );
  }
}
