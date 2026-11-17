part of 'executive_lead_detail_bloc.dart';

abstract class ExecutiveLeadDetailEvent {
  const ExecutiveLeadDetailEvent();
}

class ExecutiveLeadDetailLoad extends ExecutiveLeadDetailEvent {
  const ExecutiveLeadDetailLoad(this.leadId);
  final String leadId;
}

class ExecutiveLeadDetailRefreshed extends ExecutiveLeadDetailEvent {
  const ExecutiveLeadDetailRefreshed(this.leadId);
  final String leadId;
}
