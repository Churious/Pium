import 'dart:math';

import 'package:flutter/material.dart';

enum KioskMode { practice, free, real }

enum KioskStep {
  dineType,
  selectMenu,
  selectOptions,
  payment,
  complete,
}

enum DineType { dineIn, takeOut }

enum KioskMissionType {
  simpleOrder,
  optionPick,
  multiDrink,
  drinkAndDessert,
}

class KioskProduct {
  const KioskProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.category,
    this.hasDrinkOptions = false,
  });

  final String id;
  final String name;
  final int price;
  final IconData icon;
  final String category;
  final bool hasDrinkOptions;
}

const kioskCategories = ['추천', '커피', '음료', '디저트'];

const kioskProducts = [
  KioskProduct(
    id: 'set1',
    name: '아침 세트',
    price: 5900,
    icon: Icons.breakfast_dining,
    category: '추천',
  ),
  KioskProduct(
    id: 'latte',
    name: '카페 라떼',
    price: 4500,
    icon: Icons.coffee,
    category: '추천',
  ),
  KioskProduct(
    id: 'ame_hot',
    name: '아메리카노 (HOT)',
    price: 4100,
    icon: Icons.local_cafe,
    category: '커피',
    hasDrinkOptions: true,
  ),
  KioskProduct(
    id: 'ame_ice',
    name: '아메리카노 (ICE)',
    price: 4100,
    icon: Icons.ac_unit,
    category: '커피',
    hasDrinkOptions: true,
  ),
  KioskProduct(
    id: 'mocha',
    name: '카페 모카',
    price: 4800,
    icon: Icons.coffee_maker,
    category: '커피',
  ),
  KioskProduct(
    id: 'ade',
    name: '레몬 에이드',
    price: 3900,
    icon: Icons.local_bar,
    category: '음료',
  ),
  KioskProduct(
    id: 'smoothie',
    name: '딸기 스무디',
    price: 5200,
    icon: Icons.emoji_food_beverage,
    category: '음료',
  ),
  KioskProduct(
    id: 'cake',
    name: '치즈 케이크',
    price: 5500,
    icon: Icons.cake,
    category: '디저트',
  ),
  KioskProduct(
    id: 'cookie',
    name: '초코 쿠키',
    price: 2800,
    icon: Icons.cookie,
    category: '디저트',
  ),
];

KioskProduct? productById(String id) {
  for (final p in kioskProducts) {
    if (p.id == id) return p;
  }
  return null;
}

/// 음료 옵션 (아메리카노 등)
class KioskOptions {
  const KioskOptions({
    this.extraShot = false,
    this.tumbler = false,
    this.ice = '보통',
  });

  final bool extraShot;
  final bool tumbler;
  final String ice;

  static const defaultOptions = KioskOptions();

  int get priceAdjust => (extraShot ? 500 : 0) + (tumbler ? -300 : 0);

  bool matches(KioskOptions? required) {
    if (required == null) return true;
    return extraShot == required.extraShot &&
        tumbler == required.tumbler &&
        ice == required.ice;
  }

  String get summary {
    final parts = <String>[];
    if (ice != '보통') parts.add('얼음 $ice');
    if (extraShot) parts.add('샷 추가');
    if (tumbler) parts.add('텀블러');
    return parts.isEmpty ? '' : ' (${parts.join(', ')})';
  }
}

/// 장바구니 한 줄
class CartLineItem {
  CartLineItem({
    required this.product,
    this.options = KioskOptions.defaultOptions,
  }) : lineId = '${product.id}_${DateTime.now().microsecondsSinceEpoch}';

  final String lineId;
  final KioskProduct product;
  final KioskOptions options;

  int get linePrice => product.price + options.priceAdjust;

  String get displayLabel => '${product.name}${options.summary}';
}

/// 미션에 필요한 메뉴 1줄
class KioskOrderItemSpec {
  const KioskOrderItemSpec({
    required this.productId,
    this.options,
  });

  final String productId;
  final KioskOptions? options;

  KioskProduct? product() => productById(productId);
}

/// 연습·실전 공통 주문 미션
class KioskMission {
  const KioskMission({
    required this.id,
    required this.title,
    required this.orderText,
    required this.dineType,
    required this.items,
    required this.type,
  });

  final String id;
  final String title;
  final String orderText;
  final DineType dineType;
  final List<KioskOrderItemSpec> items;
  final KioskMissionType type;

  String get startSpeech => orderText;

  /// 아직 담지 않은 첫 번째 항목
  KioskOrderItemSpec? nextMissingSpec(List<CartLineItem> cart) {
    final remaining = List<KioskOrderItemSpec>.from(items);
    for (final line in cart) {
      final idx = remaining.indexWhere(
        (s) =>
            s.productId == line.product.id &&
            line.options.matches(s.options),
      );
      if (idx >= 0) remaining.removeAt(idx);
    }
    return remaining.isEmpty ? null : remaining.first;
  }

  bool isCartComplete(List<CartLineItem> cart) => nextMissingSpec(cart) == null;

  int _remainingCount(List<CartLineItem> cart) {
    final remaining = List<KioskOrderItemSpec>.from(items);
    for (final line in cart) {
      final idx = remaining.indexWhere(
        (s) =>
            s.productId == line.product.id &&
            line.options.matches(s.options),
      );
      if (idx >= 0) remaining.removeAt(idx);
    }
    return remaining.length;
  }

  bool optionsNeedDialog(KioskOptions options) =>
      options.ice != '보통' || options.extraShot || options.tumbler;

  /// 연습 모드 단계별 안내
  String practiceHint({
    required DineType? dineType,
    required List<CartLineItem> cart,
    required KioskStep step,
  }) {
    if (dineType != this.dineType) {
      return this.dineType == DineType.dineIn
          ? '지금은 [매장 식사]를 선택해 보세요.'
          : '지금은 [포장하기]를 선택해 보세요.';
    }

    final next = nextMissingSpec(cart);
    if (next != null) {
      final p = next.product();
      final cat = p?.category ?? '메뉴';
      final name = p?.name ?? '메뉴';
      if (next.options != null) {
        final opt = next.options!;
        final optParts = <String>[];
        if (opt.ice != '보통') optParts.add('얼음 [${opt.ice}]');
        if (opt.extraShot) optParts.add('[샷 추가]');
        if (opt.tumbler) optParts.add('[텀블러 할인]');
        final optHint =
            optParts.isEmpty ? '' : ' ${optParts.join(', ')}을(를) 선택하고';
        return '[$cat] 탭에서 $name 를 고른 뒤,$optHint [선택 완료]를 눌러 주세요.';
      }
      if (items.length > 1) {
        final left = _remainingCount(cart);
        return '[$cat] 탭에서 $name 를 담아 주세요. (남은 메뉴 $left개)';
      }
      return '[$cat] 탭에서 $name 를 선택해 보세요.';
    }

    if (step != KioskStep.payment && step != KioskStep.complete) {
      return '메뉴를 다 담았어요. [결제하기] → [카드 결제]를 선택해 보세요.';
    }
    return '지금은 [결제하기] → [카드 결제]를 선택해 보세요.';
  }

  /// 주문 검증 (실전 모드)
  OrderValidationResult validate({
    required DineType? dineType,
    required List<CartLineItem> cart,
  }) {
    if (dineType == null) {
      return const OrderValidationResult(
        success: false,
        message: '매장 식사 또는 포장을 먼저 선택해 주세요.',
      );
    }
    if (dineType != this.dineType) {
      return OrderValidationResult(
        success: false,
        message: this.dineType == DineType.dineIn
            ? '이번 주문은 매장 식사입니다. 포장/매장을 다시 확인해 보세요.'
            : '이번 주문은 포장입니다. 포장/매장을 다시 확인해 보세요.',
      );
    }

    final remaining = List<KioskOrderItemSpec>.from(items);
    for (final line in cart) {
      final idx = remaining.indexWhere(
        (s) =>
            s.productId == line.product.id &&
            line.options.matches(s.options),
      );
      if (idx >= 0) {
        remaining.removeAt(idx);
      }
    }

    if (remaining.isNotEmpty) {
      final missing = remaining.first.product()?.name ?? '메뉴';
      return OrderValidationResult(
        success: false,
        message: '$missing이(가) 아직 담기지 않았어요. 장바구니를 확인해 보세요.',
      );
    }

    if (cart.length > items.length) {
      return const OrderValidationResult(
        success: false,
        message: '주문과 다른 메뉴가 더 담겨 있어요. 빼기로 맞춰 주세요.',
      );
    }

    return const OrderValidationResult(success: true);
  }

  /// 실전 모드 힌트 (짧게)
  String? realHint({
    required DineType? dineType,
    required List<CartLineItem> cart,
  }) {
    if (dineType != this.dineType) {
      return this.dineType == DineType.dineIn
          ? '힌트: 매장에서 드시는 주문이에요.'
          : '힌트: 포장 주문이에요.';
    }
    final next = nextMissingSpec(cart);
    if (next == null) {
      return '힌트: 메뉴는 다 담았어요. 결제만 하면 됩니다.';
    }
    final p = next.product();
    return '힌트: ${p?.category ?? ''} 메뉴에서 ${p?.name ?? '메뉴'}를 찾아 보세요.';
  }
}

class OrderValidationResult {
  const OrderValidationResult({required this.success, this.message});

  final bool success;
  final String? message;
}

/// 옵션 창 하이라이트용
class KioskOptionsGuide {
  const KioskOptionsGuide({
    this.ice,
    this.extraShot,
    this.tumbler,
  });

  final String? ice;
  final bool? extraShot;
  final bool? tumbler;
}

final _rnd = Random();

KioskProduct _pickProduct(List<String> ids) {
  final id = ids[_rnd.nextInt(ids.length)];
  return productById(id)!;
}

KioskProduct _pickFromCategories(List<String> categories) {
  final pool =
      kioskProducts.where((p) => categories.contains(p.category)).toList();
  return pool[_rnd.nextInt(pool.length)];
}

KioskMission _simpleOrderMission() {
  final p = _pickFromCategories(['추천', '커피', '음료', '디저트']);
  final dine = _rnd.nextBool() ? DineType.dineIn : DineType.takeOut;
  final dineKo = dine == DineType.dineIn ? '매장에서' : '포장해서';
  return KioskMission(
    id: 'simple_${p.id}_${dine.name}',
    title: '기본 주문',
    orderText: '$dineKo ${p.name} 하나 주문해 주세요.',
    dineType: dine,
    items: [KioskOrderItemSpec(productId: p.id)],
    type: KioskMissionType.simpleOrder,
  );
}

KioskMission _optionPickMission() {
  final iceProduct = _pickProduct(['ame_ice', 'ame_hot']);
  final iceLevels = ['적게', '보통', '많이'];
  final ice = iceLevels[_rnd.nextInt(iceLevels.length)];
  final extraShot = _rnd.nextBool();
  final tumbler = _rnd.nextBool();
  final dine = _rnd.nextBool() ? DineType.dineIn : DineType.takeOut;
  final dineKo = dine == DineType.dineIn ? '매장에서' : '포장해서';

  final optParts = <String>[];
  if (ice != '보통') optParts.add('얼음 $ice');
  if (extraShot) optParts.add('샷 추가');
  if (tumbler) optParts.add('텀블러 할인');
  final optText = optParts.isEmpty ? '' : ' ${optParts.join(', ')}으로';

  return KioskMission(
    id: 'opt_${iceProduct.id}_$ice',
    title: '옵션 선택',
    orderText:
        '$dineKo ${iceProduct.name} 하나$optText 주문해 주세요.',
    dineType: dine,
    items: [
      KioskOrderItemSpec(
        productId: iceProduct.id,
        options: KioskOptions(
          ice: ice,
          extraShot: extraShot,
          tumbler: tumbler,
        ),
      ),
    ],
    type: KioskMissionType.optionPick,
  );
}

KioskMission _multiDrinkMission() {
  final drinks = kioskProducts
      .where((p) => p.category == '커피' || p.category == '음료')
      .toList()
    ..shuffle(_rnd);
  final a = drinks[0];
  var b = drinks[1];
  if (a.id == b.id && drinks.length > 2) b = drinks[2];
  final dine = _rnd.nextBool() ? DineType.dineIn : DineType.takeOut;
  final dineKo = dine == DineType.dineIn ? '매장에서' : '포장해서';

  return KioskMission(
    id: 'multi_${a.id}_${b.id}',
    title: '음료 여러 잔',
    orderText: '$dineKo ${a.name}랑 ${b.name} 두 잔 주문해 주세요.',
    dineType: dine,
    items: [
      KioskOrderItemSpec(productId: a.id),
      KioskOrderItemSpec(productId: b.id),
    ],
    type: KioskMissionType.multiDrink,
  );
}

KioskMission _drinkAndDessertMission() {
  final drink = _pickFromCategories(['커피', '음료']);
  final dessert = _pickFromCategories(['디저트']);
  final dine = _rnd.nextBool() ? DineType.dineIn : DineType.takeOut;
  final dineKo = dine == DineType.dineIn ? '매장에서' : '포장해서';

  return KioskMission(
    id: 'combo_${drink.id}_${dessert.id}',
    title: '음료 + 디저트',
    orderText:
        '$dineKo ${drink.name} 하나랑 ${dessert.name}도 주문해 주세요.',
    dineType: dine,
    items: [
      KioskOrderItemSpec(productId: drink.id),
      KioskOrderItemSpec(productId: dessert.id),
    ],
    type: KioskMissionType.drinkAndDessert,
  );
}

final _missionBuilders = [
  _simpleOrderMission,
  _optionPickMission,
  _multiDrinkMission,
  _drinkAndDessertMission,
  _optionPickMission,
  _multiDrinkMission,
];

/// 연습·실전용 랜덤 미션 (직전과 다른 유형 우선)
KioskMission randomKioskMission({String? excludeId}) {
  final built = _missionBuilders.map((b) => b()).toList();
  var pool = built;
  if (excludeId != null) {
    final filtered = built.where((m) => m.id != excludeId).toList();
    if (filtered.isNotEmpty) pool = filtered;
  }
  return pool[_rnd.nextInt(pool.length)];
}

/// 하위 호환 alias
KioskMission randomPracticeScenario({String? excludeId}) =>
    randomKioskMission(excludeId: excludeId);
