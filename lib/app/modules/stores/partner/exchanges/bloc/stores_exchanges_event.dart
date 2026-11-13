part of 'stores_exchanges_bloc.dart';

abstract class StoresExchangesEvent {
  const StoresExchangesEvent();
}

class StoresExchangesLoadEvent extends StoresExchangesEvent {
  const StoresExchangesLoadEvent();
}
