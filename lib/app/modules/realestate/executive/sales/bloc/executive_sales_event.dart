part of 'executive_sales_bloc.dart';

abstract class ExecutiveSalesEvent {
  const ExecutiveSalesEvent();
}

class ExecutiveSalesLoad extends ExecutiveSalesEvent {
  const ExecutiveSalesLoad();
}

class ExecutiveSalesRefreshed extends ExecutiveSalesEvent {
  const ExecutiveSalesRefreshed();
}

class ExecutiveSalesNextPage extends ExecutiveSalesEvent {
  const ExecutiveSalesNextPage();
}
