import 'package:flutter/material.dart';

enum KioskMode { practice, free }

enum KioskStep {
  dineType,
  selectMenu,
  selectOptions,
  payment,
  complete,
}

enum DineType { dineIn, takeOut }

class KioskProduct {
  const KioskProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.category,
    this.isHotAmericano = false,
    this.isIceAmericano = false,
  });

  final String id;
  final String name;
  final int price;
  final IconData icon;
  final String category;
  final bool isHotAmericano;
  final bool isIceAmericano;
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
    isHotAmericano: true,
  ),
  KioskProduct(
    id: 'ame_ice',
    name: '아메리카노 (ICE)',
    price: 4100,
    icon: Icons.ac_unit,
    category: '커피',
    isIceAmericano: true,
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

/// 연습 모드에서 따라 할 주문 시나리오
class KioskScenario {
  const KioskScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.dineType,
    required this.category,
    required this.productId,
    required this.requireOptions,
  });

  final String id;
  final String title;
  final String description;
  final DineType dineType;
  final String category;
  final String productId;
  final bool requireOptions;

  KioskProduct? product() {
    for (final p in kioskProducts) {
      if (p.id == productId) return p;
    }
    return null;
  }

  String missionForStep(KioskStep step) {
    final menuName = product()?.name ?? '메뉴';
    switch (step) {
      case KioskStep.dineType:
        return dineType == DineType.dineIn
            ? '지금은 [매장 식사]를 선택해 보세요.'
            : '지금은 [포장하기]를 선택해 보세요.';
      case KioskStep.selectMenu:
        return '지금은 [$category] 탭에서 $menuName 를 선택해 보세요.';
      case KioskStep.selectOptions:
        return '지금은 옵션을 확인하고 [선택 완료]를 눌러 주세요.';
      case KioskStep.payment:
        return '지금은 [결제하기] → [카드 결제]를 선택해 보세요.';
      case KioskStep.complete:
        return '주문이 완료되었습니다! 잘하셨어요!';
    }
  }

  String get startSpeech => '$title 연습을 시작합니다. $description';
}

const kioskScenarios = [
  KioskScenario(
    id: 'ame_hot',
    title: '따뜻한 아메리카노',
    description: '매장에서 드시는 뜨거운 커피를 주문해요.',
    dineType: DineType.dineIn,
    category: '커피',
    productId: 'ame_hot',
    requireOptions: true,
  ),
  KioskScenario(
    id: 'ame_ice_takeout',
    title: '아이스 아메리카노 포장',
    description: '포장해서 가져갈 시원한 커피를 주문해요.',
    dineType: DineType.takeOut,
    category: '커피',
    productId: 'ame_ice',
    requireOptions: true,
  ),
  KioskScenario(
    id: 'latte',
    title: '카페 라떼',
    description: '부드러운 우유가 들어간 커피를 주문해요.',
    dineType: DineType.dineIn,
    category: '추천',
    productId: 'latte',
    requireOptions: false,
  ),
  KioskScenario(
    id: 'ade_takeout',
    title: '레몬 에이드 포장',
    description: '상큼한 음료를 포장해서 주문해요.',
    dineType: DineType.takeOut,
    category: '음료',
    productId: 'ade',
    requireOptions: false,
  ),
  KioskScenario(
    id: 'cake',
    title: '치즈 케이크',
    description: '디저트 메뉴를 골라 주문해요.',
    dineType: DineType.dineIn,
    category: '디저트',
    productId: 'cake',
    requireOptions: false,
  ),
  KioskScenario(
    id: 'mocha',
    title: '카페 모카',
    description: '달콤한 초코 커피를 주문해요.',
    dineType: DineType.dineIn,
    category: '커피',
    productId: 'mocha',
    requireOptions: false,
  ),
];
