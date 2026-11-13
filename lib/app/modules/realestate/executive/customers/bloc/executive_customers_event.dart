/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'executive_customers_bloc.dart';

abstract class ExecutiveCustomersEvent {
  const ExecutiveCustomersEvent();
}

/// Collects customers from the first pages of assigned leads.
class ExecutiveCustomersLoad extends ExecutiveCustomersEvent {
  const ExecutiveCustomersLoad();
}

/// Re-collects from page one.
class ExecutiveCustomersRefreshed extends ExecutiveCustomersEvent {
  const ExecutiveCustomersRefreshed();
}
