/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'executive_leads_bloc.dart';

abstract class ExecutiveLeadsEvent {
  const ExecutiveLeadsEvent();
}

/// Loads the first page of assigned leads.
class ExecutiveLeadsLoad extends ExecutiveLeadsEvent {
  const ExecutiveLeadsLoad();
}

/// Appends the next page, if any remains.
class ExecutiveLeadsNextPage extends ExecutiveLeadsEvent {
  const ExecutiveLeadsNextPage();
}

/// Reloads from page one.
class ExecutiveLeadsRefreshed extends ExecutiveLeadsEvent {
  const ExecutiveLeadsRefreshed();
}
