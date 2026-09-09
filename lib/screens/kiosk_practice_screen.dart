import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pium/models/kiosk_models.dart';
import 'package:pium/services/tts_service.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/utils/defer_state.dart';
import 'package:pium/widgets/step_highlight.dart';

// ─── 진입: 모드 · 연습 선택 ─────────────────────────────────────────────────

class KioskPracticeScreen extends StatefulWidget {
  const KioskPracticeScreen({super.key});

  @override
  State<KioskPracticeScreen> createState() => _KioskPracticeScreenState();
}

class _KioskPracticeScreenState extends State<KioskPracticeScreen> {
  _PickerStep _step = _PickerStep.mode;

  void _openSession({required KioskMode mode, KioskScenario? scenario}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KioskSessionScreen(mode: mode, scenario: scenario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PiumColors.guideBg,
      appBar: AppBar(
        backgroundColor: PiumColors.navy,
        foregroundColor: Colors.white,
        title: Text(
          _step == _PickerStep.mode ? '무인주문기 연습' : '연습 메뉴 고르기',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () {
            if (_step == _PickerStep.scenario) {
              setState(() => _step = _PickerStep.mode);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _step == _PickerStep.mode
          ? _ModePicker(
              onPractice: () => setState(() => _step = _PickerStep.scenario),
              onFree: () => _openSession(mode: KioskMode.free),
            )
          : _ScenarioPicker(
              onSelect: (s) =>
                  _openSession(mode: KioskMode.practice, scenario: s),
            ),
    );
  }
}

enum _PickerStep { mode, scenario }

class _ModePicker extends StatelessWidget {
  const _ModePicker({required this.onPractice, required this.onFree});

  final VoidCallback onPractice;
  final VoidCallback onFree;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '어떻게 연습할까요?',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '카페 무인주문기 사용법을 익혀 보세요.',
          style: TextStyle(fontSize: 18, height: 1.5),
        ),
        const SizedBox(height: 28),
        _ModeCard(
          icon: Icons.school_outlined,
          title: '연습 모드',
          subtitle: '따라 하며 배우기',
          description: '화면 안내를 보며 한 단계씩 주문해요.\n노란색으로 표시된 버튼을 눌러 주세요.',
          color: PiumColors.tileOrange,
          onTap: onPractice,
        ),
        const SizedBox(height: 16),
        _ModeCard(
          icon: Icons.touch_app,
          title: '자유 모드',
          subtitle: '마음대로 눌러보기',
          description: '정답 없이 자유롭게 메뉴를 골라 보세요.\n익숙해지면 연습 모드에 도전해 보세요.',
          color: PiumColors.tileTeal,
          onTap: onFree,
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 36, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 18,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 32, color: color),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(fontSize: 17, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenarioPicker extends StatelessWidget {
  const _ScenarioPicker({required this.onSelect});

  final ValueChanged<KioskScenario> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '어떤 주문을 연습할까요?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '하나를 고른 뒤, 안내에 따라 차근차근 진행해 보세요.',
          style: TextStyle(fontSize: 18, height: 1.5),
        ),
        const SizedBox(height: 20),
        ...kioskScenarios.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => onSelect(s),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border.all(color: PiumColors.navy, width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.coffee, size: 32, color: PiumColors.navy),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.description,
                              style: const TextStyle(fontSize: 17, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.play_circle_fill,
                          size: 36, color: PiumColors.tileOrange),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 키오스크 본 화면 ─────────────────────────────────────────────────────

class KioskSessionScreen extends StatefulWidget {
  const KioskSessionScreen({
    super.key,
    required this.mode,
    this.scenario,
  });

  final KioskMode mode;
  final KioskScenario? scenario;

  @override
  State<KioskSessionScreen> createState() => _KioskSessionScreenState();
}

class _KioskSessionScreenState extends State<KioskSessionScreen>
    with TickerProviderStateMixin {
  KioskStep _step = KioskStep.dineType;
  String _category = '추천';
  DineType? _dineType;
  final List<KioskProduct> _cart = [];
  bool _showIcAnimation = false;
  bool _dialogOpen = false;
  KioskProduct? _pendingProduct;

  late final AnimationController _icCtrl;

  bool get _isPractice =>
      widget.mode == KioskMode.practice && widget.scenario != null;

  KioskScenario get _scenario => widget.scenario!;

  String get _bannerText {
    if (!_isPractice) {
      return '원하는 메뉴를 마음대로 골라 보세요. 다 고르셨으면 결제하기를 누르세요.';
    }
    return _scenario.missionForStep(_step);
  }

  String get _appBarTitle {
    if (_isPractice) return '연습 · ${_scenario.title}';
    return '자유 모드 · 카페 주문';
  }

  @override
  void initState() {
    super.initState();
    _icCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _showDineModal();
      if (!mounted) return;
      if (_isPractice) {
        await PiumTts.speak(_scenario.startSpeech);
      } else {
        await PiumTts.speak(
          '자유 모드입니다. 매장 식사나 포장을 고른 뒤, 원하는 메뉴를 골라 보세요.',
        );
      }
    });
  }

  @override
  void dispose() {
    _icCtrl.stop();
    _icCtrl.dispose();
    super.dispose();
  }

  Future<T?> _showKioskDialog<T>(WidgetBuilder builder) {
    if (_dialogOpen || !mounted) return Future.value(null);
    _dialogOpen = true;
    return showDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: builder,
    ).whenComplete(() => _dialogOpen = false);
  }

  Future<void> _wrongTap() async {
    if (!_isPractice) return;
    await PiumTts.speak(
      '해당 단계의 버튼이 아닙니다. 노란색으로 빛나는 버튼을 눌러주세요.',
    );
  }

  void _onDineSelected(DineType type) {
    setState(() {
      _dineType = type;
      _step = KioskStep.selectMenu;
      _category = _isPractice ? _scenario.category : '추천';
    });
    if (_isPractice) {
      final p = _scenario.product();
      PiumTts.speak('${_scenario.category} 탭에서 ${p?.name ?? '메뉴'}를 선택해 주세요.');
    }
  }

  Future<void> _showDineModal() {
    return _showKioskDialog<void>(
      (ctx) => _DineTypeDialog(
        highlightDineIn:
            _isPractice && _scenario.dineType == DineType.dineIn && _step == KioskStep.dineType,
        highlightTakeOut:
            _isPractice && _scenario.dineType == DineType.takeOut && _step == KioskStep.dineType,
        onDineIn: () {
          if (_isPractice && _scenario.dineType != DineType.dineIn) {
            _wrongTap();
            return;
          }
          Navigator.of(ctx, rootNavigator: true).pop();
          deferState(() => _onDineSelected(DineType.dineIn));
        },
        onTakeOut: () {
          if (_isPractice && _scenario.dineType != DineType.takeOut) {
            _wrongTap();
            return;
          }
          Navigator.of(ctx, rootNavigator: true).pop();
          deferState(() => _onDineSelected(DineType.takeOut));
        },
      ),
    ).then((_) {});
  }

  void _onCategoryTap(String cat) {
    if (_isPractice &&
        _step == KioskStep.selectMenu &&
        cat != _scenario.category) {
      _wrongTap();
      return;
    }
    setState(() => _category = cat);
  }

  void _afterMenuSelected(KioskProduct p) {
    if (_isPractice && _scenario.requireOptions &&
        (p.isHotAmericano || p.isIceAmericano)) {
      setState(() {
        _cart
          ..clear()
          ..add(p);
        _step = KioskStep.selectOptions;
      });
      deferState(() => _showOptionsModal(practiceFlow: true));
    } else if (_isPractice) {
      setState(() {
        _cart
          ..clear()
          ..add(p);
        _step = KioskStep.payment;
      });
      PiumTts.speak('메뉴를 선택했어요. 이제 결제하기 버튼을 눌러 주세요.');
    }
  }

  void _onProductTap(KioskProduct p) {
    if (!_isPractice) {
      if (p.isHotAmericano || p.isIceAmericano) {
        _pendingProduct = p;
        deferState(() => _showOptionsModal(practiceFlow: false));
      } else {
        setState(() => _cart.add(p));
      }
      return;
    }

    if (_step == KioskStep.selectMenu) {
      if (p.id == _scenario.productId) {
        _afterMenuSelected(p);
      } else {
        _wrongTap();
      }
      return;
    }
    if (_step != KioskStep.complete) _wrongTap();
  }

  void _showOptionsModal({required bool practiceFlow}) {
    if (!mounted) return;
    _showKioskDialog<void>(
      (ctx) => _OptionsDialog(
        showGuide: practiceFlow,
        onConfirm: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          deferState(() {
            if (!mounted) return;
            if (practiceFlow) {
              setState(() => _step = KioskStep.payment);
              PiumTts.speak('옵션 선택이 완료되었습니다. 이제 결제하기 버튼을 눌러 주세요.');
            } else {
              final pending = _pendingProduct;
              if (pending != null) {
                setState(() {
                  _cart.add(pending);
                  _pendingProduct = null;
                });
              }
            }
          });
        },
      ),
    );
  }

  Future<void> _onPayPressed() async {
    if (!_isPractice) {
      if (_cart.isEmpty) {
        await PiumTts.speak('먼저 메뉴를 담아 주세요.');
        return;
      }
      await _showKioskDialog<void>(
        (ctx) => _PaymentDialog(
          practiceMode: false,
          onCard: () {
            Navigator.of(ctx, rootNavigator: true).pop();
            deferState(_runCardPayment);
          },
        ),
      );
      return;
    }

    if (_step != KioskStep.payment) {
      await _wrongTap();
      return;
    }
    await _showKioskDialog<void>(
      (ctx) => _PaymentDialog(
        practiceMode: true,
        onCard: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          deferState(_runCardPayment);
        },
        onWrong: _wrongTap,
      ),
    );
  }

  Future<void> _runCardPayment() async {
    if (!mounted) return;
    setState(() => _showIcAnimation = true);
    _icCtrl.repeat();
    await PiumTts.speak('IC 카드를 투입구에 끝까지 넣어주세요.');
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    _icCtrl.stop();
    _icCtrl.reset();
    setState(() {
      _showIcAnimation = false;
      _step = KioskStep.complete;
    });
    await _showReceipt();
  }

  void _onCancel() {
    _icCtrl.stop();
    if (_dialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    deferState(() {
      if (!mounted) return;
      setState(() {
        _step = KioskStep.dineType;
        _category = '추천';
        _dineType = null;
        _cart.clear();
        _showIcAnimation = false;
        _pendingProduct = null;
      });
      final msg = _isPractice
          ? '주문이 취소되었습니다. 처음부터 다시 연습해 보세요.'
          : '주문이 취소되었습니다. 다시 골라 보세요.';
      PiumTts.speak(msg);
      deferState(() {
        if (mounted) _showDineModal();
      });
    });
  }

  Future<void> _showReceipt() async {
    await PiumTts.speak(
      _isPractice
          ? '연습 주문이 완료되었습니다! 실제 매장에서도 같은 순서로 진행하시면 됩니다. 정말 잘하셨습니다!'
          : '주문이 완료되었습니다! 무인주문기 연습, 수고하셨습니다.',
    );
    if (!mounted) return;
    await _showKioskDialog<void>(
      (ctx) => _ReceiptDialog(
        items: _cart,
        dineType: _dineType ?? DineType.dineIn,
        isPractice: _isPractice,
        onClose: () => Navigator.of(ctx, rootNavigator: true).pop(),
      ),
    );
  }

  int get _total => _cart.fold(0, (s, p) => s + p.price);

  String? get _highlightCategory =>
      _isPractice && _step == KioskStep.selectMenu ? _scenario.category : null;

  bool _highlightProduct(KioskProduct p) =>
      _isPractice && _step == KioskStep.selectMenu && p.id == _scenario.productId;

  @override
  Widget build(BuildContext context) {
    final filtered =
        kioskProducts.where((p) => p.category == _category).toList();

    return Scaffold(
      backgroundColor: PiumColors.kioskBg,
      appBar: AppBar(
        backgroundColor: PiumColors.kioskPanel,
        foregroundColor: Colors.white,
        title: Text(
          _appBarTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _MissionBanner(
                text: _bannerText,
                isPractice: _isPractice,
              ),
              _CategoryTabs(
                selected: _category,
                onTap: _onCategoryTap,
                highlightCategory: _highlightCategory,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return StepHighlight(
                        key: ValueKey('kiosk-${p.id}'),
                        active: _highlightProduct(p),
                        child: _ProductCard(
                          product: p,
                          onTap: () => _onProductTap(p),
                        ),
                      );
                    },
                  ),
                ),
              ),
              _CartBar(
                cart: _cart,
                total: _total,
                onCancel: _onCancel,
                onPay: _onPayPressed,
                highlightPay: _isPractice && _step == KioskStep.payment,
              ),
            ],
          ),
          if (_showIcAnimation) _IcCardOverlay(controller: _icCtrl),
        ],
      ),
    );
  }
}

// ─── 공통 위젯 ───────────────────────────────────────────────────────────

class _MissionBanner extends StatelessWidget {
  const _MissionBanner({required this.text, required this.isPractice});

  final String text;
  final bool isPractice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: const Color(0xFF422006),
      child: Row(
        children: [
          Icon(
            isPractice ? Icons.flag : Icons.info_outline,
            color: PiumColors.pulseYellow,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isPractice ? '미션: $text' : text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.selected,
    required this.onTap,
    this.highlightCategory,
  });

  final String selected;
  final ValueChanged<String> onTap;
  final String? highlightCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PiumColors.kioskPanel,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: kioskCategories.map((c) {
          final isSelected = c == selected;
          final highlight = highlightCategory != null && c == highlightCategory;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: StepHighlight(
                active: highlight,
                borderRadius: 10,
                child: Material(
                  color: isSelected
                      ? PiumColors.kioskAccent
                      : const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => onTap(c),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final KioskProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PiumColors.kioskPanel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(product.icon, size: 44, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                product.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${product.price}원',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: PiumColors.kioskAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({
    required this.cart,
    required this.total,
    required this.onCancel,
    required this.onPay,
    required this.highlightPay,
  });

  final List<KioskProduct> cart;
  final int total;
  final VoidCallback onCancel;
  final VoidCallback onPay;
  final bool highlightPay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            cart.isEmpty
                ? '장바구니가 비어 있습니다'
                : '담은 메뉴: ${cart.map((e) => e.name).join(', ')} · $total원',
            style: const TextStyle(
              fontSize: 17,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54, width: 2),
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '주문 취소',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: StepHighlight(
                  active: highlightPay,
                  borderRadius: 12,
                  child: FilledButton(
                    onPressed: onPay,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '결제하기',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DineTypeDialog extends StatelessWidget {
  const _DineTypeDialog({
    required this.onDineIn,
    required this.onTakeOut,
    required this.highlightDineIn,
    required this.highlightTakeOut,
  });

  final VoidCallback onDineIn;
  final VoidCallback onTakeOut;
  final bool highlightDineIn;
  final bool highlightTakeOut;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '포장 여부를 선택해 주세요.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            StepHighlight(
              active: highlightDineIn,
              child: _DialogChoice(
                icon: Icons.restaurant,
                label: '매장 식사',
                onTap: onDineIn,
              ),
            ),
            const SizedBox(height: 12),
            StepHighlight(
              active: highlightTakeOut,
              child: _DialogChoice(
                icon: Icons.shopping_bag,
                label: '포장하기',
                onTap: onTakeOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogChoice extends StatelessWidget {
  const _DialogChoice({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PiumColors.guideBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: PiumColors.navy),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionsDialog extends StatefulWidget {
  const _OptionsDialog({
    required this.onConfirm,
    required this.showGuide,
  });

  final VoidCallback onConfirm;
  final bool showGuide;

  @override
  State<_OptionsDialog> createState() => _OptionsDialogState();
}

class _OptionsDialogState extends State<_OptionsDialog> {
  bool _extraShot = false;
  bool _tumbler = false;
  String _ice = '보통';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '옵션을 선택해 주세요.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _OptionTile(
              label: '샷 추가 (+500원)',
              selected: _extraShot,
              onTap: () => setState(() => _extraShot = !_extraShot),
            ),
            _OptionTile(
              label: '텀블러 할인 (-300원)',
              selected: _tumbler,
              onTap: () => setState(() => _tumbler = !_tumbler),
            ),
            const SizedBox(height: 8),
            const Text(
              '얼음 양',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['적게', '보통', '많이'].map((v) {
                final sel = _ice == v;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: StepHighlight(
                      active: widget.showGuide && v == '보통',
                      borderRadius: 10,
                      child: Material(
                        color: sel ? PiumColors.navy : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => setState(() => _ice = v),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            child: Text(
                              v,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: sel ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            StepHighlight(
              active: widget.showGuide,
              child: FilledButton(
                onPressed: widget.onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: PiumColors.navy,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text(
                  '선택 완료',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFFDBEAFE) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? PiumColors.navy : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentDialog extends StatelessWidget {
  const _PaymentDialog({
    required this.practiceMode,
    required this.onCard,
    this.onWrong,
  });

  final bool practiceMode;
  final VoidCallback onCard;
  final Future<void> Function()? onWrong;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '결제 수단을 선택해 주세요.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            StepHighlight(
              active: practiceMode,
              child: _DialogChoice(
                icon: Icons.credit_card,
                label: '카드 결제',
                onTap: onCard,
              ),
            ),
            const SizedBox(height: 12),
            _DialogChoice(
              icon: Icons.payments,
              label: '현금 결제',
              onTap: () {
                if (practiceMode) {
                  onWrong?.call();
                } else {
                  onCard();
                }
              },
            ),
            const SizedBox(height: 12),
            _DialogChoice(
              icon: Icons.qr_code,
              label: '간편 결제',
              onTap: () {
                if (practiceMode) {
                  onWrong?.call();
                } else {
                  onCard();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IcCardOverlay extends StatelessWidget {
  const _IcCardOverlay({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'IC 카드를 투입구에\n끝까지 넣어주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                final t = controller.value;
                return SizedBox(
                  width: 280,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 240,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF374151),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white54, width: 3),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 180,
                            height: 8,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, 60 - t * 100),
                        child: Container(
                          width: 160,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.credit_card,
                                  color: Colors.white, size: 36),
                              Text(
                                'IC CARD',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ReceiptDialog extends StatelessWidget {
  const _ReceiptDialog({
    required this.items,
    required this.dineType,
    required this.isPractice,
    required this.onClose,
  });

  final List<KioskProduct> items;
  final DineType dineType;
  final bool isPractice;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final total = items.fold(0, (s, p) => s + p.price);
    final orderNo = DateTime.now().millisecondsSinceEpoch % 100000;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 48, color: PiumColors.navy),
            const SizedBox(height: 12),
            const Text(
              '영수증',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '주문번호 #$orderNo',
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const Divider(height: 28, thickness: 2),
            ...items.map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('${p.price}원', style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dineType == DineType.dineIn ? '매장 식사' : '포장',
                  style: const TextStyle(fontSize: 17),
                ),
                Text(
                  '합계 $total원',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isPractice
                    ? '연습 주문이 정상적으로 접수되었습니다!\n실제 매장 키오스크와 같은 순서입니다. 정말 잘하셨습니다!'
                    : '주문이 접수되었습니다!\n자유롭게 연습해 보셨어요. 잘하셨습니다!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: Color(0xFF166534),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: onClose,
                style: FilledButton.styleFrom(backgroundColor: PiumColors.navy),
                child: const Text(
                  '확인',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
