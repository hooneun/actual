import 'package:actual/product/model/product_model.dart';
import 'package:actual/user/model/basket_item_model.dart';
import 'package:actual/user/model/patch_basket_body.dart';
import 'package:actual/user/repository/user_me_repository.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

final basketProvider =
    StateNotifierProvider<BasketProvider, List<BasketItemModel>>((ref) {
  final repository = ref.watch(userMeRepositoryProvider);

  return BasketProvider(repository: repository);
});

class BasketProvider extends StateNotifier<List<BasketItemModel>> {
  final UserMeRepository repository;
  final updateBasketDebounce = Debouncer(
    const Duration(seconds: 1),
    initialValue: null,
    checkEquality: false,
  );

  BasketProvider({
    required this.repository,
  }) : super([]) {
    updateBasketDebounce.values.listen((event) {
      patchBasket();
    });
  }

  int get totalPrice => state.fold<int>(
        0,
        (p, n) => p + (n.product.price * n.count),
      );

  Future<void> patchBasket() async {
    print(
      PatchBasketBody(
        basket: state
            .map(
              (e) => PatchBasketBodyBasket(
                productId: e.product.id,
                count: e.count,
              ),
            )
            .toList(),
      ).toJson(),
    );
    repository.patchBasket(
      body: PatchBasketBody(
        basket: state
            .map(
              (e) => PatchBasketBodyBasket(
                productId: e.product.id,
                count: e.count,
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> addToBasket({
    required ProductModel product,
  }) async {
    // 요청을 먼저 보내고 응답이 오면 캐시로 업데이트 했었다.
    // 하지만. 장바구니는 후 요청을 한다.

    // 1) 장바구니에 상품이 없다면 장바구니에 상품을 추가한다.
    // 2) 이미 장바구니에 들어 있다면 장바구니에 있는 값을 +1 한다.
    final exists =
        state.firstWhereOrNull((e) => e.product.id == product.id) != null;

    if (exists) {
      state = state
          .map(
            (e) =>
                e.product.id == product.id ? e.copyWith(count: e.count + 1) : e,
          )
          .toList();
    } else {
      state = [
        ...state,
        BasketItemModel(product: product, count: 1),
      ];
    }

    // Optimistic Response (긍정적 응답)
    // 응답이 성공을 가정하고 상태를 먼저 업데이트한다.

    updateBasketDebounce.setValue(null);
  }

  Future<void> removeFromBasket({
    required ProductModel product,
    bool isDelete = false, // true 면 카운트와 상관없이 삭제
  }) async {
    // 1) 장바구니에 상품이 존재할 경우
    // 1. 상품의 카운트가 1보다 크면 - 1
    // 2. 상품의 카운트가 1이면 삭제
    // 2) 상품이 존재하지 않을 경우
    // 즉시 함수 반환

    final exists =
        state.firstWhereOrNull((e) => e.product.id == product.id) != null;

    if (!exists) {
      return;
    }

    final existingProduct = state.firstWhere((e) => e.product.id == product.id);

    if (existingProduct.count == 1 || isDelete) {
      state = state.where((e) => e.product.id != product.id).toList();
    } else {
      state = state
          .map((e) =>
              e.product.id == product.id ? e.copyWith(count: e.count - 1) : e)
          .toList();
    }

    updateBasketDebounce.setValue(null);
  }
}
