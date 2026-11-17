part of 'executive_customer_detail_bloc.dart';

abstract class ExecutiveCustomerDetailEvent {
  const ExecutiveCustomerDetailEvent();
}

class ExecutiveCustomerDetailLoad extends ExecutiveCustomerDetailEvent {
  const ExecutiveCustomerDetailLoad(this.customerId);
  final String customerId;
}

class ExecutiveCustomerDetailRefreshed extends ExecutiveCustomerDetailEvent {
  const ExecutiveCustomerDetailRefreshed(this.customerId);
  final String customerId;
}
