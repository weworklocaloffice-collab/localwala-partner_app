/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'executive_earnings_bloc.dart';

abstract class ExecutiveEarningsEvent {
  const ExecutiveEarningsEvent();
}

class ExecutiveEarningsLoad extends ExecutiveEarningsEvent {
  const ExecutiveEarningsLoad();
}

class ExecutiveEarningsRefreshed extends ExecutiveEarningsEvent {
  const ExecutiveEarningsRefreshed();
}
