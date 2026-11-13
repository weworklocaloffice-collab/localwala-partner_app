part of 'stores_delivery_bloc.dart';

abstract class StoresDeliveryEvent {
  const StoresDeliveryEvent();
}

class StoresDeliveryLoadEvent extends StoresDeliveryEvent {
  const StoresDeliveryLoadEvent();
}
