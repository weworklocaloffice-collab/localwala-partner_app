part of 'executive_settlements_bloc.dart';

abstract class ExecutiveSettlementsEvent {
  const ExecutiveSettlementsEvent();
}

class ExecutiveSettlementsLoad extends ExecutiveSettlementsEvent {
  const ExecutiveSettlementsLoad();
}

class ExecutiveSettlementsRefreshed extends ExecutiveSettlementsEvent {
  const ExecutiveSettlementsRefreshed();
}

class ExecutiveSettlementsNextPage extends ExecutiveSettlementsEvent {
  const ExecutiveSettlementsNextPage();
}
