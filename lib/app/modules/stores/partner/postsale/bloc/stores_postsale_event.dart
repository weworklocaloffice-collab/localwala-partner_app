part of 'stores_postsale_bloc.dart';

abstract class StoresPostSaleEvent {
  const StoresPostSaleEvent();
}

class StoresPostSaleLoadEvent extends StoresPostSaleEvent {
  const StoresPostSaleLoadEvent();
}
