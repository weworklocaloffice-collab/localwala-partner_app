part of 'executive_holds_bloc.dart';

abstract class ExecutiveHoldsEvent {
  const ExecutiveHoldsEvent();
}

class ExecutiveHoldsLoad extends ExecutiveHoldsEvent {
  const ExecutiveHoldsLoad();
}

class ExecutiveHoldsRefreshed extends ExecutiveHoldsEvent {
  const ExecutiveHoldsRefreshed();
}

class ExecutiveHoldsNextPage extends ExecutiveHoldsEvent {
  const ExecutiveHoldsNextPage();
}
