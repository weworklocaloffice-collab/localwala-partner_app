/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/executive/earnings/bloc/executive_earnings_bloc.dart';
import 'package:partner/app/modules/realestate/models/commission.dart';
import 'package:partner/app/modules/realestate/models/loan.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/models/sale.dart';
import 'package:partner/app/modules/realestate/models/settlement.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class ExecutiveEarningsScreen extends StatelessWidget {
  const ExecutiveEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<ExecutiveEarningsBloc>(
      create: (_) => ExecutiveEarningsBloc()..add(const ExecutiveEarningsLoad()),
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.realEstateExecEarnings),
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: <Widget>[
                Tab(text: l10n.realEstateExecCommissions),
                Tab(text: l10n.realEstateExecSettlements),
                Tab(text: l10n.realEstateExecLoans),
                Tab(text: l10n.realEstateExecSales),
              ],
            ),
          ),
          body: BlocBuilder<ExecutiveEarningsBloc, ExecutiveEarningsState>(
            builder: (BuildContext context, ExecutiveEarningsState state) {
              if (state.status == ExecutiveEarningsStatus.initial ||
                  state.status == ExecutiveEarningsStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == ExecutiveEarningsStatus.failure) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        state.message.isEmpty ? l10n.somethingWentWrong : state.message,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<ExecutiveEarningsBloc>().add(const ExecutiveEarningsRefreshed()),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              }
              return TabBarView(
                children: <Widget>[
                  _CommissionsTab(state: state, l10n: l10n),
                  _SettlementsTab(state: state, l10n: l10n),
                  _LoansTab(state: state, l10n: l10n),
                  _SalesTab(state: state, l10n: l10n),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CommissionsTab extends StatelessWidget {
  const _CommissionsTab({required this.state, required this.l10n});

  final ExecutiveEarningsState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final List<RealEstateCommissionModel> items =
        state.commissions?.items ?? const <RealEstateCommissionModel>[];
    if (items.isEmpty) return _Empty(text: l10n.realEstateExecCommissionsEmpty);
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<ExecutiveEarningsBloc>().add(const ExecutiveEarningsRefreshed()),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final RealEstateCommissionModel c = items[index];
          return _MoneyCard(
            title: c.commissionNo ?? c.id,
            amount: c.amount,
            status: c.status,
            lines: <String>[
              if (c.rate != null) '${l10n.realEstateExecRate}: ${c.rate}%',
              if (c.baseAmount != null)
                '${l10n.realEstateExecBaseAmount}: ${_rupees(c.baseAmount)}',
            ],
          );
        },
      ),
    );
  }
}

class _SettlementsTab extends StatelessWidget {
  const _SettlementsTab({required this.state, required this.l10n});

  final ExecutiveEarningsState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final List<RealEstateSettlementModel> items =
        state.settlements?.items ?? const <RealEstateSettlementModel>[];
    if (items.isEmpty) return _Empty(text: l10n.realEstateExecSettlementsEmpty);
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<ExecutiveEarningsBloc>().add(const ExecutiveEarningsRefreshed()),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final RealEstateSettlementModel s = items[index];
          return _MoneyCard(
            title: s.settlementNo ?? s.id,
            amount: s.net,
            status: s.status,
            lines: <String>[
              '${l10n.realEstateExecGross}: ${_rupees(s.gross)}',
              '${l10n.realEstateExecTds}: ${_rupees(s.tds)}',
              if (s.periodFrom != null || s.periodTo != null)
                '${l10n.realEstateExecPeriod}: ${_date(s.periodFrom)} - ${_date(s.periodTo)}',
              if (s.payoutReference != null && s.payoutReference!.isNotEmpty)
                '${l10n.realEstateExecPayoutReference}: ${s.payoutReference}',
            ],
          );
        },
      ),
    );
  }
}

class _LoansTab extends StatelessWidget {
  const _LoansTab({required this.state, required this.l10n});

  final ExecutiveEarningsState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final List<RealEstateLoanModel> items = state.loans?.items ?? const <RealEstateLoanModel>[];
    if (items.isEmpty) return _Empty(text: l10n.realEstateExecLoansEmpty);
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<ExecutiveEarningsBloc>().add(const ExecutiveEarningsRefreshed()),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final RealEstateLoanModel loan = items[index];
          return _MoneyCard(
            title: loan.customer?.displayName ?? loan.id,
            amount: loan.requestedAmount,
            status: loan.status,
            onTap: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (_) => _LoanDetailSheet(loanId: loan.id),
            ),
            lines: <String>[
              loan.property?.title ?? loan.property?.propertyCode ?? '',
              if (loan.tenureMonths != null)
                '${l10n.realEstateExecTenure}: ${loan.tenureMonths}',
              if (loan.applications.isNotEmpty)
                '${l10n.realEstateExecApplications}: ${loan.applications.length}',
            ],
          );
        },
      ),
    );
  }
}

class _SalesTab extends StatelessWidget {
  const _SalesTab({required this.state, required this.l10n});

  final ExecutiveEarningsState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final List<RealEstateSaleModel> items = state.sales?.items ?? const <RealEstateSaleModel>[];
    if (items.isEmpty) return _Empty(text: l10n.realEstateExecSalesEmpty);
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<ExecutiveEarningsBloc>().add(const ExecutiveEarningsRefreshed()),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final RealEstateSaleModel sale = items[index];
          return _MoneyCard(
            title: sale.saleCode ?? sale.id,
            amount: sale.saleValue,
            status: sale.status,
            onTap: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (_) => _SaleDetailSheet(saleId: sale.id),
            ),
            lines: <String>[
              sale.property?.title ?? sale.property?.propertyCode ?? '',
              sale.customer?.displayName ?? '',
              if (sale.soldAt != null)
                '${l10n.realEstateExecSoldOn}: ${_date(sale.soldAt)}',
            ],
          );
        },
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({
    required this.title,
    required this.amount,
    required this.status,
    required this.lines,
    this.onTap,
  });

  final String title;
  final double? amount;
  final String? status;
  final List<String> lines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[
        Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;
    final List<String> visible = lines.where((String l) => l.trim().isNotEmpty).toList();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: theme.titleText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  _rupees(amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: theme.titleText),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _status(status),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
            ),
            if (visible.isNotEmpty) const SizedBox(height: 6),
            ...visible.map(
              (String line) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(line, style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text));
  }
}

class _LoanDetailSheet extends StatefulWidget {
  const _LoanDetailSheet({required this.loanId});

  final String loanId;

  @override
  State<_LoanDetailSheet> createState() => _LoanDetailSheetState();
}

class _LoanDetailSheetState extends State<_LoanDetailSheet> {
  RealEstateLoanModel? _loan;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final RealEstateLoanModel? loan = await RealEstateExecutiveRepository().loan(widget.loanId);
      if (!mounted) return;
      setState(() {
        _loan = loan;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (_loading) return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
    if (_error != null) return SizedBox(height: 220, child: Center(child: Text(_error!)));
    final RealEstateLoanModel? loan = _loan;
    if (loan == null) return SizedBox(height: 200, child: Center(child: Text(l10n.realEstateExecLoanNotFound)));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(loan.customer?.displayName ?? loan.id, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(_status(loan.status)),
            const SizedBox(height: 12),
            _DetailRow(label: l10n.realEstateLeadDetailProperty, value: loan.property?.title ?? '-'),
            _DetailRow(label: l10n.realEstateExecRequestedAmount, value: _rupees(loan.requestedAmount)),
            _DetailRow(label: l10n.realEstateExecMonthlyIncome, value: _rupees(loan.monthlyIncome)),
            _DetailRow(label: l10n.realEstateExecEmployment, value: _status(loan.employment)),
            _DetailRow(label: l10n.realEstateExecTenure, value: loan.tenureMonths?.toString() ?? '-'),
            const SizedBox(height: 12),
            Text(l10n.realEstateExecApplications, style: Theme.of(context).textTheme.titleSmall),
            if (loan.applications.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.realEstateExecNoApplications),
              ),
            ...loan.applications.map(
              (RealEstateLoanApplicationModel app) => Card(
                margin: const EdgeInsets.only(top: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(app.bank?.displayName ?? app.id,
                          style: Theme.of(context).textTheme.titleSmall),
                      _DetailRow(label: l10n.realEstateCheckoutStatus, value: _status(app.status)),
                      _DetailRow(
                        label: l10n.realEstateExecSanctionedAmount,
                        value: _rupees(app.sanctionedAmount),
                      ),
                      _DetailRow(
                        label: l10n.realEstateExecDisbursedAmount,
                        value: _rupees(app.disbursedAmount),
                      ),
                      _DetailRow(
                        label: l10n.realEstateExecInterestRate,
                        value: app.interestRate == null ? '-' : '${app.interestRate}%',
                      ),
                      if (app.rejectionReason != null && app.rejectionReason!.isNotEmpty)
                        _DetailRow(
                          label: l10n.realEstateExecRejectionReason,
                          value: app.rejectionReason!,
                        ),
                      if (app.offers.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(l10n.realEstateExecOffers,
                            style: Theme.of(context).textTheme.labelLarge),
                        ...app.offers.map(
                          (RealEstateBankOfferModel offer) => _DetailRow(
                            label: '${offer.bank?.displayName ?? l10n.realEstateExecOffer} '
                                '${offer.interestRate == null ? '' : '${offer.interestRate}%'}',
                            value: _rupees(offer.loanAmount),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleDetailSheet extends StatefulWidget {
  const _SaleDetailSheet({required this.saleId});

  final String saleId;

  @override
  State<_SaleDetailSheet> createState() => _SaleDetailSheetState();
}

class _SaleDetailSheetState extends State<_SaleDetailSheet> {
  RealEstateSaleModel? _sale;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final RealEstateSaleModel? sale = await RealEstateExecutiveRepository().sale(widget.saleId);
      if (!mounted) return;
      setState(() {
        _sale = sale;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (_loading) return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
    if (_error != null) return SizedBox(height: 200, child: Center(child: Text(_error!)));
    final RealEstateSaleModel? sale = _sale;
    if (sale == null) return SizedBox(height: 180, child: Center(child: Text(l10n.realEstateExecSaleNotFound)));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(sale.saleCode ?? sale.id, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(_status(sale.status)),
            const SizedBox(height: 12),
            _DetailRow(label: l10n.realEstateLeadDetailProperty, value: sale.property?.title ?? '-'),
            _DetailRow(label: l10n.realEstateLeadDetailCustomer, value: sale.customer?.displayName ?? '-'),
            _DetailRow(label: l10n.realEstateExecSaleValue, value: _rupees(sale.saleValue)),
            _DetailRow(
              label: l10n.realEstateExecHoldPrincipal,
              value: _rupees(sale.holdPrincipalApplied),
            ),
            _DetailRow(label: l10n.realEstateExecTransaction, value: _status(sale.transactionType)),
            _DetailRow(label: l10n.realEstateExecSoldOn, value: _date(sale.soldAt)),
            if (sale.cancellationReason != null && sale.cancellationReason!.isNotEmpty)
              _DetailRow(label: l10n.realEstateExecCancellationReason, value: sale.cancellationReason!),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

String _rupees(double? amount) =>
    amount == null ? '-' : '\u20B9${formatIndianPrice(amount)}';

String _date(DateTime? date) =>
    date == null ? '-' : date.toLocal().toString().split('.').first;

String _status(String? status) {
  if (status == null || status.isEmpty) return '-';
  final String lower = status.replaceAll('_', ' ').toLowerCase();
  return lower.isEmpty ? status : '${lower[0].toUpperCase()}${lower.substring(1)}';
}
