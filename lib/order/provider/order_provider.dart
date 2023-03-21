import 'package:actual/order/model/order_model.dart';
import 'package:actual/user/provider/basket_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final orderProvider =
    StateNotifierProvider<OrderStateNotifier, List<OrderModel>>(
  (ref) {
    return OrderStateNotifier(ref: ref);
  },
);

class OrderStateNotifier extends StateNotifier<List<OrderModel>> {
  final Ref ref;

  OrderStateNotifier({
    required this.ref,
  }) : super([]);

  Future<void> postOrder() async {
    final state = ref.read(basketProvider);
  }
}
