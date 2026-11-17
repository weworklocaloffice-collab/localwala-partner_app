part of 'executive_notifications_bloc.dart';

abstract class ExecutiveNotificationsEvent {
  const ExecutiveNotificationsEvent();
}

class ExecutiveNotificationsLoad extends ExecutiveNotificationsEvent {
  const ExecutiveNotificationsLoad();
}

class ExecutiveNotificationsRefreshed extends ExecutiveNotificationsEvent {
  const ExecutiveNotificationsRefreshed();
}
