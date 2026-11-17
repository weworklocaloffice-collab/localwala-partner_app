part of 'executive_visit_detail_bloc.dart';

abstract class ExecutiveVisitDetailEvent {
  const ExecutiveVisitDetailEvent();
}

class ExecutiveVisitDetailLoad extends ExecutiveVisitDetailEvent {
  const ExecutiveVisitDetailLoad(this.visitId);
  final String visitId;
}

class ExecutiveVisitDetailRefreshed extends ExecutiveVisitDetailEvent {
  const ExecutiveVisitDetailRefreshed(this.visitId);
  final String visitId;
}
