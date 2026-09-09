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
  void _openSession({required KioskMode mode}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KioskSessionScreen(mode: mode),
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
        title: const Text(
          '무인주문기 연습',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _ModePicker(
        onPractice: () => _openSession(mode: KioskMode.practice),
        onReal: () => _openSession(mode: KioskMode.real),
        onFree: () => _openSession(mode: KioskMode.free),
      ),
    );
  }
}

class _ModePicker extends StatelessWidget {
  const _ModePicker({
    required this.onPractice,
    required this.onReal,
    required this.onFree,
  });

  final VoidCallback onPractice;
  final VoidCallback onReal;
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
          description: '옵션 선택, 여러 메뉴 담기 등\n노란 안내를 보며 따라 해요.',
          color: PiumColors.tileOrange,
          onTap: onPractice,
        ),
        const SizedBox(height: 16),
        _ModeCard(
          icon: Icons.emoji_events_outlined,
          title: '도전 모드',
          subtitle: '도움 없이 주문해 보기',
          description: '주문만 보고 천천히 직접 주문해 보세요.\n연습 후에 도전해 보세요.',
          color: const Color(0xFF7C3AED),
          onTap: onReal,
        ),
        const SizedBox(height: 16),
        _ModeCard(
          icon: Icons.touch_app,
          title: '자유 모드',
          subtitle: '자유롭게 연습하기',
          description: '정답 없이 자유롭게 메뉴를 골라 보세요.\n익숙해지면 도전 모드에도 도전해 보세요.',
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

// ─── 키오스크 본 화면 ─────────────────────────────────────────────────────

class KioskSessionScreen extends StatefulWidget {
  const KioskSessionScreen({
    super.key,
    required this.mode,
  });

  final KioskMode mode;

  @override
  State<KioskSessionScreen> createState() => _KioskSessionScreenState();
}

class _KioskSessionScreenState extends State<KioskSessionScreen> {
  KioskStep _step = KioskStep.dineType;
  String _category = '추천';
  DineType? _dineType;
  final List<CartLineItem> _cart = [];
  bool _showCardPayment = false;
  bool _dialogOpen = false;
  KioskProduct? _pendingProduct;
  KioskOrderItemSpec? _pendingSpec;
  KioskMission? _currentMission;
  int _completedRounds = 0;
  int _realHintsUsed = 0;

  bool get _isPractice => widget.mode == KioskMode.practice;
  bool get _isReal => widget.mode == KioskMode.real;
  bool get _isGuided => _isPractice;
  bool get _hasMission => _isPractice || _isReal;

  KioskMission get _mission => _currentMission!;

  String get _bannerText {
    if (_isPractice) {
      return _mission.practiceHint(
        dineType: _dineType,
        cart: _cart,
        step: _step,
      );
    }
    if (_isReal) return _mission.orderText;
    return '원하는 메뉴를 자유롭게 골라 보세요. 다 고르셨으면 결제하기를 누르세요.';
  }

  String get _appBarTitle {
    if (_isPractice) return '연습 · ${_mission.title}';
    if (_isReal) return '도전 · 주문하기';
    return '자유 모드 · 카페 주문';
  }

  @override
  void initState() {
    super.initState();
    if (_hasMission) {
      _currentMission = randomKioskMission();
    }
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _showDineModal();
      if (!mounted) return;
      if (_isPractice) {
        await PiumTts.speak('연습 모드입니다. ${_mission.startSpeech}');
      } else if (_isReal) {
        await PiumTts.speak('도전 모드입니다. ${_mission.orderText}');
      } else {
        await PiumTts.speak(
          '자유 모드입니다. 매장 식사나 포장을 고른 뒤, 원하는 메뉴를 골라 보세요.',
        );
      }
    });
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
    if (!_isGuided) return;
    await PiumTts.speak(
      '해당 단계의 버튼이 아닙니다. 노란색으로 빛나는 버튼을 눌러주세요.',
    );
  }

  void _syncPracticeStep() {
    if (!_isPractice) return;
    setState(() {
      if (_mission.isCartComplete(_cart) && _dineType == _mission.dineType) {
        _step = KioskStep.payment;
      } else {
        _step = KioskStep.selectMenu;
      }
    });
  }

  void _onDineSelected(DineType type) {
    setState(() {
      _dineType = type;
      _step = KioskStep.selectMenu;
      if (_hasMission) {
        _category =
            _mission.nextMissingSpec(_cart)?.product()?.menuCategory ?? '추천';
      } else {
        _category = '추천';
      }
    });
    if (_isPractice) {
      PiumTts.speak(_mission.practiceHint(
        dineType: _dineType,
        cart: _cart,
        step: _step,
      ));
    }
  }

  Future<void> _showDineModal() {
    return _showKioskDialog<void>(
      (ctx) => _DineTypeDialog(
        highlightDineIn: _isPractice &&
            _mission.dineType == DineType.dineIn &&
            _dineType != DineType.dineIn,
        highlightTakeOut: _isPractice &&
            _mission.dineType == DineType.takeOut &&
            _dineType != DineType.takeOut,
        onDineIn: () {
          if (_isPractice && _mission.dineType != DineType.dineIn) {
            _wrongTap();
            return;
          }
          Navigator.of(ctx, rootNavigator: true).pop();
          deferState(() => _onDineSelected(DineType.dineIn));
        },
        onTakeOut: () {
          if (_isPractice && _mission.dineType != DineType.takeOut) {
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
    if (_isPractice) {
      final nextCat = _mission.nextMissingSpec(_cart)?.product()?.menuCategory;
      if (nextCat != null && cat != nextCat) {
        _wrongTap();
        return;
      }
    }
    setState(() => _category = cat);
  }

  void _addOrIncrementLine(KioskProduct p, KioskOptions options) {
    final normalized = p.clampOptions(options);
    final idx = _cart.indexWhere(
      (line) =>
          line.product.id == p.id &&
          line.options.sameAs(
            normalized,
            compareDrinkOptions: p.hasDrinkOptions,
          ),
    );
    setState(() {
      if (idx >= 0) {
        _cart[idx].quantity++;
      } else {
        _cart.add(CartLineItem(product: p, options: normalized));
      }
    });
  }

  void _onCartLineIncrease(int index) {
    if (index < 0 || index >= _cart.length) return;
    setState(() => _cart[index].quantity++);
    if (_isPractice) _syncPracticeStep();
  }

  void _onCartLineDecrease(int index) {
    if (index < 0 || index >= _cart.length) return;
    final name = _cart[index].displayLabel;
    setState(() {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
    });
    if (_isPractice) _syncPracticeStep();
    PiumTts.speak('$name 수량을 줄였습니다.');
  }

  KioskOptionsGuide? _optionsGuideFor(
    KioskProduct product,
    KioskOptions? required,
  ) {
    if (required == null) return null;
    return KioskOptionsGuide(
      temperature: product.supportsHotAndCold ? required.temperature : null,
      ice: required.isIced && required.ice != '보통' ? required.ice : null,
      extraShot: required.extraShot ? true : null,
      tumbler: required.tumbler ? true : null,
    );
  }

  void _onProductTap(KioskProduct p) {
    if (_isPractice) {
      final next = _mission.nextMissingSpec(_cart);
      if (next == null || next.productId != p.id) {
        _wrongTap();
        return;
      }
      final reqOpts = next.options ?? KioskOptions.defaultOptions;
      if (p.hasDrinkOptions && _mission.optionsNeedDialog(reqOpts, p)) {
        _pendingProduct = p;
        _pendingSpec = next;
        deferState(
          () => _showOptionsModal(
            guided: true,
            requiredOptions: reqOpts,
          ),
        );
        return;
      }
      _addOrIncrementLine(p, reqOpts);
      PiumTts.speak('${p.name}을(를) 담았습니다.');
      _syncPracticeStep();
      return;
    }

    if (p.hasDrinkOptions) {
      _pendingProduct = p;
      _pendingSpec = null;
      deferState(() => _showOptionsModal(guided: false));
      return;
    }

    _addOrIncrementLine(p, KioskOptions.defaultOptions);
    PiumTts.speak('${p.name}을(를) 담았습니다.');
  }

  void _onOptionsCancel({required bool guided}) {
    deferState(() {
      if (!mounted) return;
      setState(() {
        _pendingProduct = null;
        _pendingSpec = null;
        if (guided) _step = KioskStep.selectMenu;
      });
      PiumTts.speak('옵션 선택을 취소했습니다. 메뉴를 다시 골라 보세요.');
    });
  }

  void _showOptionsModal({
    required bool guided,
    KioskOptions? requiredOptions,
  }) {
    if (!mounted) return;
    final pending = _pendingProduct;
    final guide = guided && pending != null
        ? _optionsGuideFor(pending, requiredOptions)
        : null;
    _showKioskDialog<void>(
      (ctx) => _OptionsDialog(
        guide: guide,
        supportsHotAndCold: pending?.supportsHotAndCold ?? false,
        supportsExtraShot: pending?.supportsExtraShot ?? false,
        onConfirm: (options) {
          Navigator.of(ctx, rootNavigator: true).pop();
          deferState(() {
            if (!mounted) return;
            final pending = _pendingProduct;
            if (pending == null) return;

            final normalized = pending.clampOptions(options);
            if (guided &&
                requiredOptions != null &&
                !normalized.matches(
                  requiredOptions,
                  compareDrinkOptions: pending.hasDrinkOptions,
                )) {
              PiumTts.speak('안내에 맞게 옵션을 선택해 주세요.');
              _pendingProduct = pending;
              _pendingSpec = _pendingSpec;
              _showOptionsModal(
                guided: true,
                requiredOptions: requiredOptions,
              );
              return;
            }

            _addOrIncrementLine(pending, normalized);
            PiumTts.speak(
              '${pending.name}${normalized.summaryFor(hasDrinkOptions: pending.hasDrinkOptions)}을(를) 담았습니다.',
            );
            _pendingProduct = null;
            _pendingSpec = null;
            if (guided) _syncPracticeStep();
          });
        },
        onCancel: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          _onOptionsCancel(guided: guided);
        },
      ),
    );
  }

  Future<void> _useRealHint() async {
    if (_realHintsUsed >= 2) {
      await PiumTts.speak('힌트는 두 번까지만 사용할 수 있어요.');
      return;
    }
    setState(() => _realHintsUsed++);
    final hint = _mission.realHint(dineType: _dineType, cart: _cart);
    await PiumTts.speak(hint ?? '주문문을 다시 읽어 보세요.');
  }

  Future<void> _replayOrderText() async {
    await PiumTts.speak(_mission.orderText);
  }

  Future<void> _onPayPressed() async {
    if (_cart.isEmpty) {
      await PiumTts.speak('먼저 메뉴를 담아 주세요.');
      return;
    }

    if (_isReal) {
      final result = _mission.validate(dineType: _dineType, cart: _cart);
      if (!result.success) {
        await PiumTts.speak(result.message ?? '주문을 다시 확인해 주세요.');
        return;
      }
    }

    if (_isPractice) {
      if (_step != KioskStep.payment) {
        await _wrongTap();
        return;
      }
      if (!_mission.isCartComplete(_cart)) {
        await PiumTts.speak('아직 담아야 할 메뉴가 남아 있어요.');
        setState(() => _step = KioskStep.selectMenu);
        return;
      }
    }

    _startCardPayment();
  }

  Future<void> _startCardPayment() async {
    if (!mounted) return;
    setState(() => _showCardPayment = true);
    await PiumTts.speak(
      '카드를 아래에서 위로 끌어 올려, 리더기에 끝까지 넣어 주세요.',
    );
  }

  Future<void> _completeCardPayment() async {
    if (!mounted) return;
    setState(() {
      _showCardPayment = false;
      _step = KioskStep.complete;
    });
    if (_isReal) {
      await PiumTts.speak(
        '맞았어요! 주문을 정확히 하셨어요. 결제도 완료되었습니다.',
      );
    } else {
      await PiumTts.speak('결제가 완료되었습니다.');
    }
    await _showReceipt();
  }

  void _cancelCardPayment() {
    setState(() => _showCardPayment = false);
    PiumTts.speak('결제를 취소했습니다.');
  }

  void _onCancel() {
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
        _showCardPayment = false;
        _pendingProduct = null;
      });
      final msg = _isPractice
          ? '처음부터 다시 연습해 보세요.'
          : _isReal
              ? '처음부터 다시 해 보세요.'
              : '처음부터 다시 골라 보세요.';
      PiumTts.speak(msg);
      deferState(() {
        if (mounted) _showDineModal();
      });
    });
  }

  Future<void> _startRandomMission() async {
    final previousId = _currentMission?.id;
    setState(() {
      _currentMission = randomKioskMission(excludeId: previousId);
      _step = KioskStep.dineType;
      _category = '추천';
      _dineType = null;
      _cart.clear();
      _showCardPayment = false;
      _pendingProduct = null;
      _pendingSpec = null;
      _realHintsUsed = 0;
    });
    await _showDineModal();
    if (!mounted) return;
    final intro = _isReal ? '새로운 도전 주문입니다.' : '새로운 연습입니다.';
    await PiumTts.speak('$intro ${_mission.startSpeech}');
  }

  Future<void> _finishMissionSession() async {
    final count = _completedRounds;
    final label = _isReal ? '도전' : '연습';
    await PiumTts.speak(
      count <= 1
          ? '$label 주문 과정을 끝냈어요.'
          : '$label $count번의 주문 과정을 끝냈어요.',
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showMissionContinueChoice() async {
    final label = _isReal ? '도전' : '연습';
    await PiumTts.speak(
      '다른 주문도 $label해 보시겠어요? 더 하기 또는 끝내기를 선택해 주세요.',
    );
    if (!mounted) return;
    await _showKioskDialog<void>(
      (ctx) => _PracticeContinueDialog(
        completedCount: _completedRounds,
        isReal: _isReal,
        onContinue: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          deferState(_startRandomMission);
        },
        onStop: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          deferState(_finishMissionSession);
        },
      ),
    );
  }

  Future<void> _showReceipt() async {
    if (_hasMission) {
      setState(() => _completedRounds++);
    }
    if (!_isReal) {
      await PiumTts.speak(
        _isPractice
            ? '연습 주문이 완료되었습니다.'
            : '주문이 완료되었습니다. 무인주문기 연습, 수고하셨습니다.',
      );
    }
    if (!mounted) return;
    await _showKioskDialog<void>(
      (ctx) => _ReceiptDialog(
        items: _cart,
        dineType: _dineType ?? DineType.dineIn,
        isPractice: _isPractice,
        isReal: _isReal,
        onClose: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          deferState(() {
            if (!mounted) return;
            if (_hasMission) {
              _showMissionContinueChoice();
            }
          });
        },
      ),
    );
  }

  int get _total => _cart.fold(0, (s, line) => s + line.linePrice);

  String? get _highlightCategory {
    if (!_isPractice) return null;
    if (_dineType != _mission.dineType) return null;
    return _mission.nextMissingSpec(_cart)?.product()?.menuCategory;
  }

  bool _highlightProduct(KioskProduct p) {
    if (!_isPractice) return false;
    if (_dineType != _mission.dineType) return false;
    return _mission.nextMissingSpec(_cart)?.productId == p.id;
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        kioskProducts.where((p) => p.isInCategory(_category)).toList();

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
        actions: [
          if (_isReal)
            IconButton(
              icon: const Icon(Icons.volume_up, size: 28),
              tooltip: '주문 다시 듣기',
              onPressed: _replayOrderText,
            ),
          if (_isReal)
            IconButton(
              icon: const Icon(Icons.lightbulb_outline, size: 28),
              tooltip: '힌트',
              onPressed: _useRealHint,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _MissionBanner(
                text: _bannerText,
                mode: widget.mode,
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
                onLineIncrease: _onCartLineIncrease,
                onLineDecrease: _onCartLineDecrease,
                onPay: _onPayPressed,
                highlightPay: _isPractice &&
                    _step == KioskStep.payment &&
                    _mission.isCartComplete(_cart),
              ),
            ],
          ),
          if (_showCardPayment)
            _CardDragPaymentOverlay(
              showGuide: _isPractice,
              onComplete: _completeCardPayment,
              onCancel: _cancelCardPayment,
            ),
        ],
      ),
    );
  }
}

// ─── 공통 위젯 ───────────────────────────────────────────────────────────

class _MissionBanner extends StatelessWidget {
  const _MissionBanner({required this.text, required this.mode});

  final String text;
  final KioskMode mode;

  @override
  Widget build(BuildContext context) {
    final prefix = switch (mode) {
      KioskMode.practice => '미션: ',
      KioskMode.real => '주문: ',
      KioskMode.free => '',
    };
    final icon = switch (mode) {
      KioskMode.practice => Icons.flag,
      KioskMode.real => Icons.receipt_long,
      KioskMode.free => Icons.info_outline,
    };
    final bg = mode == KioskMode.real
        ? const Color(0xFF312E81)
        : const Color(0xFF422006);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: bg,
      child: Row(
        children: [
          Icon(icon, color: PiumColors.pulseYellow, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$prefix$text',
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
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(product.icon, size: 44, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                product.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onPressed,
    this.compact = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 44.0 : 52.0;
    return Material(
      color: PiumColors.kioskAccent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: compact ? 24 : 28, color: Colors.black),
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
    required this.onLineIncrease,
    required this.onLineDecrease,
    required this.onPay,
    required this.highlightPay,
  });

  final List<CartLineItem> cart;
  final int total;
  final VoidCallback onCancel;
  final ValueChanged<int> onLineIncrease;
  final ValueChanged<int> onLineDecrease;
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
          if (cart.isEmpty)
            const Text(
              '장바구니가 비어 있습니다',
              style: TextStyle(
                fontSize: 17,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            const Text(
              '담은 메뉴',
              style: TextStyle(
                fontSize: 17,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 168),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cart.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = cart[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.displayLabel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            Text(
                              '${item.linePrice}원',
                              style: const TextStyle(
                                fontSize: 17,
                                color: PiumColors.kioskAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _QtyButton(
                              icon: Icons.remove,
                              compact: true,
                              onPressed: () => onLineDecrease(index),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            _QtyButton(
                              icon: Icons.add,
                              compact: true,
                              onPressed: () => onLineIncrease(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '합계 $total원',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: Row(
              children: [
                Expanded(
                  child: _KioskBarButton(
                    label: '처음부터',
                    outlined: true,
                    onPressed: onCancel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StepHighlight(
                    active: highlightPay,
                    borderRadius: 12,
                    child: _KioskBarButton(
                      label: '결제하기',
                      filled: true,
                      onPressed: onPay,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 하단·다이얼로그 공통 — 높이·글자 크기 통일
class _KioskBarButton extends StatelessWidget {
  const _KioskBarButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.filled = false,
    this.onLightBackground = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool outlined;
  final bool filled;
  final bool onLightBackground;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFEA580C),
          minimumSize: const Size(double.infinity, 56),
          shape: shape,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }
    final fg = onLightBackground ? PiumColors.navy : Colors.white;
    final border = onLightBackground ? PiumColors.navy : Colors.white54;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        side: BorderSide(color: border, width: 2),
        minimumSize: const Size(double.infinity, 56),
        shape: shape,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    required this.onCancel,
    required this.supportsHotAndCold,
    required this.supportsExtraShot,
    this.guide,
  });

  final ValueChanged<KioskOptions> onConfirm;
  final VoidCallback onCancel;
  final bool supportsHotAndCold;
  final bool supportsExtraShot;
  final KioskOptionsGuide? guide;

  @override
  State<_OptionsDialog> createState() => _OptionsDialogState();
}

class _OptionsDialogState extends State<_OptionsDialog> {
  late DrinkTemperature _temperature;
  bool _extraShot = false;
  bool _tumbler = false;
  String _ice = '보통';

  @override
  void initState() {
    super.initState();
    _temperature = widget.supportsHotAndCold
        ? DrinkTemperature.hot
        : DrinkTemperature.ice;
  }

  bool get _showIceOptions =>
      _temperature == DrinkTemperature.ice || !widget.supportsHotAndCold;

  KioskOptions get _selected => KioskOptions(
        temperature: _temperature,
        extraShot: _extraShot,
        tumbler: _tumbler,
        ice: _ice,
      );

  @override
  Widget build(BuildContext context) {
    final g = widget.guide;
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
            if (widget.supportsHotAndCold) ...[
              const Text(
                '온도',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TemperatureChip(
                      label: '따뜻하게',
                      selected: _temperature == DrinkTemperature.hot,
                      highlight: g?.temperature == DrinkTemperature.hot &&
                          _temperature != DrinkTemperature.hot,
                      onTap: () =>
                          setState(() => _temperature = DrinkTemperature.hot),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TemperatureChip(
                      label: '차갑게',
                      selected: _temperature == DrinkTemperature.ice,
                      highlight: g?.temperature == DrinkTemperature.ice &&
                          _temperature != DrinkTemperature.ice,
                      onTap: () =>
                          setState(() => _temperature = DrinkTemperature.ice),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (widget.supportsExtraShot)
              StepHighlight(
                active: g?.extraShot == true && !_extraShot,
                borderRadius: 10,
                child: _OptionTile(
                  label: '커피 진하게 (+500원)',
                  selected: _extraShot,
                  onTap: () => setState(() => _extraShot = !_extraShot),
                ),
              ),
            StepHighlight(
              active: g?.tumbler == true && !_tumbler,
              borderRadius: 10,
              child: _OptionTile(
                label: '개인 컵 할인 (-300원)',
                selected: _tumbler,
                onTap: () => setState(() => _tumbler = !_tumbler),
              ),
            ),
            if (_showIceOptions) ...[
              const SizedBox(height: 8),
              const Text(
                '얼음 양',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['적게', '보통', '많이'].map((v) {
                  final sel = _ice == v;
                  final highlight = g?.ice != null && g!.ice == v && !sel;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: StepHighlight(
                        active: highlight,
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
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PiumColors.navy,
                      side: const BorderSide(color: PiumColors.navy, width: 2),
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StepHighlight(
                    active: g != null,
                    borderRadius: 12,
                    child: SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: () => widget.onConfirm(_selected),
                        style: FilledButton.styleFrom(
                          backgroundColor: PiumColors.navy,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '완료',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TemperatureChip extends StatelessWidget {
  const _TemperatureChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.highlight = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return StepHighlight(
      active: highlight,
      borderRadius: 10,
      child: Material(
        color: selected ? PiumColors.navy : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Colors.black,
              ),
            ),
          ),
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

class _CardDragPaymentOverlay extends StatefulWidget {
  const _CardDragPaymentOverlay({
    required this.onComplete,
    required this.onCancel,
    required this.showGuide,
  });

  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final bool showGuide;

  @override
  State<_CardDragPaymentOverlay> createState() =>
      _CardDragPaymentOverlayState();
}

class _CardDragPaymentOverlayState extends State<_CardDragPaymentOverlay> {
  double _insertProgress = 0;
  bool _done = false;

  static const _travel = 200.0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (_done) return;
    setState(() {
      _insertProgress =
          (_insertProgress - details.delta.dy / _travel).clamp(0.0, 1.0);
      if (_insertProgress >= 0.92) {
        _done = true;
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nearDone = _insertProgress >= 0.7;
    return Material(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              '카드를 리더기에 넣어 주세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nearDone ? '거의 다 됐어요!' : '카드를 아래에서 위로 끌어 올리세요',
              style: TextStyle(
                fontSize: 18,
                color: nearDone ? PiumColors.pulseYellow : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 340,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 0,
                        left: 30,
                        child: StepHighlight(
                          active: widget.showGuide,
                          borderRadius: 14,
                          child: _CardReaderSlot(highlight: nearDone),
                        ),
                      ),
                      Positioned(
                        top: 90 + (1 - _insertProgress) * _travel,
                        left: 50,
                        child: GestureDetector(
                          onVerticalDragUpdate: _onDragUpdate,
                          child: _DraggablePaymentCard(
                            insertProgress: _insertProgress,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '결제 취소',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardReaderSlot extends StatelessWidget {
  const _CardReaderSlot({required this.highlight});

  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? PiumColors.pulseYellow : Colors.white54,
          width: highlight ? 4 : 3,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              '카드 투입구',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 190,
            height: 10,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraggablePaymentCard extends StatelessWidget {
  const _DraggablePaymentCard({required this.insertProgress});

  final double insertProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.drag_handle,
              color: Colors.white.withValues(alpha: 0.8), size: 28),
          const SizedBox(height: 6),
          const Icon(Icons.credit_card, color: Colors.white, size: 40),
          const SizedBox(height: 6),
          Text(
            insertProgress >= 0.5 ? '계속 밀어 넣기' : '끌어 올리기',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeContinueDialog extends StatelessWidget {
  const _PracticeContinueDialog({
    required this.completedCount,
    required this.onContinue,
    required this.onStop,
    this.isReal = false,
  });

  final int completedCount;
  final VoidCallback onContinue;
  final VoidCallback onStop;
  final bool isReal;

  @override
  Widget build(BuildContext context) {
    final label = isReal ? '도전' : '연습';
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isReal ? Icons.emoji_events : Icons.celebration,
              size: 52,
              color: isReal ? const Color(0xFF7C3AED) : PiumColors.tileOrange,
            ),
            const SizedBox(height: 14),
            Text(
              isReal ? '도전 성공!' : '주문 과정을 끝냈어요',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isReal
                  ? (completedCount <= 1
                      ? '주문을 맞게 하셨어요.\n다른 주문도 도전해 볼까요?'
                      : '지금까지 $completedCount번 맞췄어요.\n다른 주문도 더 도전해 볼까요?')
                  : (completedCount <= 1
                      ? '무인주문기 $label을 마쳤어요.\n다른 주문도 $label해 볼까요?'
                      : '지금까지 $completedCount번 $label했어요.\n다른 주문도 더 해 볼까요?'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
            const SizedBox(height: 24),
            _KioskBarButton(
              label: '더 하기',
              filled: true,
              onPressed: onContinue,
            ),
            const SizedBox(height: 10),
            _KioskBarButton(
              label: '끝내기',
              outlined: true,
              onLightBackground: true,
              onPressed: onStop,
            ),
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
    required this.isReal,
    required this.onClose,
  });

  final List<CartLineItem> items;
  final DineType dineType;
  final bool isPractice;
  final bool isReal;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final total = items.fold(0, (s, line) => s + line.linePrice);
    final orderNo = DateTime.now().millisecondsSinceEpoch % 100000;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isReal ? Icons.emoji_events : Icons.receipt_long,
              size: 48,
              color: isReal ? const Color(0xFF7C3AED) : PiumColors.navy,
            ),
            const SizedBox(height: 12),
            Text(
              isReal ? '맞았어요!' : '영수증',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '주문번호 #$orderNo',
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const Divider(height: 28, thickness: 2),
            ...items.map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        line.displayLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${line.linePrice}원',
                      style: const TextStyle(fontSize: 18),
                    ),
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
                isReal
                    ? '정답이에요! 주문을 맞게 하셨어요.'
                    : isPractice
                        ? '연습 주문이 접수되었습니다.\n실제 매장 키오스크와 같은 순서예요.'
                        : '주문이 접수되었습니다.\n자유롭게 연습해 보셨어요.',
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
