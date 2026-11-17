part of 'executive_loan_status_bloc.dart';

abstract class ExecutiveLoanStatusEvent {
  const ExecutiveLoanStatusEvent();
}

class ExecutiveLoanStatusLoad extends ExecutiveLoanStatusEvent {
  const ExecutiveLoanStatusLoad();
}

class ExecutiveLoanStatusRefreshed extends ExecutiveLoanStatusEvent {
  const ExecutiveLoanStatusRefreshed();
}

class ExecutiveLoanStatusNextPage extends ExecutiveLoanStatusEvent {
  const ExecutiveLoanStatusNextPage();
}
