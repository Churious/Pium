import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:pium/data/korean_regions.dart';
import 'package:pium/models/work_region_selection.dart';
import 'package:pium/services/location_service.dart';
import 'package:pium/theme/pium_colors.dart';
import 'package:pium/utils/user_messages.dart';

/// 일자리 검색용 시·도 / 시·군·구 선택 위젯.
class WorkRegionPicker extends StatelessWidget {
  const WorkRegionPicker({
    super.key,
    this.selection,
    required this.enabled,
    required this.onChanged,
    this.locationService,
  });

  final WorkRegionSelection? selection;
  final bool enabled;
  final ValueChanged<WorkRegionSelection?> onChanged;
  final LocationService? locationService;

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;
    final picked = await showModalBottomSheet<WorkRegionSelection>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _WorkRegionPickerSheet(
        initialSelection: selection,
        locationService: locationService,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final label = selection?.displayLabel ?? UserMessages.jobRegionHint;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : PiumColors.guideBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? PiumColors.navy : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                color: enabled ? PiumColors.navy : Colors.grey,
                size: 26,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  UserMessages.jobRegionTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: enabled ? PiumColors.navy : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: enabled ? () => _openPicker(context) : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: PiumColors.navy,
                side: BorderSide(
                  color: enabled ? PiumColors.navy : Colors.grey.shade400,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? (selection != null
                                ? PiumColors.navy
                                : Colors.black54)
                            : Colors.grey,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more,
                    size: 28,
                    color: enabled ? PiumColors.navy : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkRegionPickerSheet extends StatefulWidget {
  const _WorkRegionPickerSheet({
    required this.initialSelection,
    this.locationService,
  });

  final WorkRegionSelection? initialSelection;
  final LocationService? locationService;

  @override
  State<_WorkRegionPickerSheet> createState() => _WorkRegionPickerSheetState();
}

class _WorkRegionPickerSheetState extends State<_WorkRegionPickerSheet> {
  late final LocationService _locationService;
  final _searchController = TextEditingController();

  WorkRegionSelection? _draft;
  String? _viewingSido;
  String _searchQuery = '';
  bool _loadingRegions = true;
  bool _loadFailed = false;
  bool _locating = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? LocationService();
    _draft = widget.initialSelection;
    _searchController.addListener(_onSearchChanged);
    unawaited(_loadRegions());
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.trim());
  }

  Future<void> _loadRegions() async {
    try {
      await KoreanRegionsData.ensureLoaded();
      if (!mounted) return;
      setState(() {
        _loadingRegions = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingRegions = false;
        _loadFailed = true;
        _statusMessage = UserMessages.jobRegionLoadFailed;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_locating || _loadFailed) return;

    setState(() {
      _locating = true;
      _statusMessage = UserMessages.jobRegionLocating;
    });

    final location = await _locationService.getCurrentPosition();
    if (!mounted) return;

    if (!location.isSuccess) {
      setState(() {
        _locating = false;
        _statusMessage = location.message;
      });
      return;
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude!,
        location.longitude!,
      );
      if (!mounted) return;

      final parts = <String?>[];
      for (final placemark in placemarks) {
        parts.addAll([
          placemark.administrativeArea,
          placemark.locality,
          placemark.subAdministrativeArea,
          placemark.subLocality,
          placemark.thoroughfare,
        ]);
      }

      final matched = KoreanRegionsData.matchFromAddressParts(
        parts,
        fromCurrentLocation: true,
      );

      if (matched == null) {
        setState(() {
          _locating = false;
          _statusMessage = UserMessages.jobRegionLocationMatchFailed;
        });
        return;
      }

      setState(() {
        _locating = false;
        _draft = matched;
        _viewingSido = null;
        _searchController.clear();
        _statusMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _statusMessage = UserMessages.jobRegionLocationMatchFailed;
      });
    }
  }

  void _selectSido(String sido) {
    setState(() {
      _viewingSido = sido;
      _statusMessage = null;
    });
  }

  void _selectRegion(KoreanRegion region, {bool fromCurrentLocation = false}) {
    setState(() {
      _draft = region.toSelection(fromCurrentLocation: fromCurrentLocation);
      _statusMessage = null;
    });
  }

  void _confirm() {
    if (_draft == null) return;
    Navigator.of(context).pop(_draft);
  }

  List<KoreanRegion> get _searchResults {
    if (_searchQuery.isEmpty) return const [];
    return KoreanRegionsData.search(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                UserMessages.jobRegionPickTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: PiumColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                UserMessages.jobRegionPickHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                enabled: !_loadingRegions && !_loadFailed,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: UserMessages.jobRegionSearchHint,
                  hintStyle: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                  prefixIcon: const Icon(Icons.search, color: PiumColors.navy),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: PiumColors.navy, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: PiumColors.navy, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: PiumColors.tilePurple,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: (_loadingRegions || _loadFailed || _locating)
                      ? null
                      : _useCurrentLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 24),
                  label: Text(
                    _locating
                        ? UserMessages.jobRegionLocating
                        : UserMessages.jobRegionUseCurrentLocation,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PiumColors.navy,
                    side: const BorderSide(color: PiumColors.navy, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red.shade700,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(child: _buildBody()),
              if (_draft != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PiumColors.guideBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PiumColors.navy, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: PiumColors.tilePurple,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              UserMessages.jobRegionSelectedLabel,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: PiumColors.navy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _draft!.displayLabel,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: PiumColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _draft != null ? _confirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: PiumColors.tilePurple,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    UserMessages.jobRegionConfirm,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingRegions) {
      return const Center(
        child: CircularProgressIndicator(color: PiumColors.navy),
      );
    }

    if (_loadFailed) {
      return Center(
        child: Text(
          UserMessages.jobRegionLoadFailed,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
        ),
      );
    }

    if (_searchQuery.isNotEmpty) {
      return _RegionSearchResults(
        query: _searchQuery,
        results: _searchResults,
        selected: _draft,
        onSelect: _selectRegion,
      );
    }

    if (_viewingSido != null) {
      return _SigunguList(
        sido: _viewingSido!,
        selected: _draft,
        onBack: () => setState(() => _viewingSido = null),
        onSelect: _selectRegion,
      );
    }

    return _SidoGrid(
      selectedSido: _draft?.sido,
      onSelect: _selectSido,
    );
  }
}

class _SidoGrid extends StatelessWidget {
  const _SidoGrid({
    required this.selectedSido,
    required this.onSelect,
  });

  final String? selectedSido;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final sidos = KoreanRegionsData.sidoOrder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          UserMessages.jobRegionSidoTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: PiumColors.navy,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
            ),
            itemCount: sidos.length,
            itemBuilder: (context, index) {
              final sido = sidos[index];
              return _RegionChip(
                label: KoreanRegionsData.shortSidoLabel(sido),
                selected: sido == selectedSido,
                onTap: () => onSelect(sido),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SigunguList extends StatelessWidget {
  const _SigunguList({
    required this.sido,
    required this.selected,
    required this.onBack,
    required this.onSelect,
  });

  final String sido;
  final WorkRegionSelection? selected;
  final VoidCallback onBack;
  final ValueChanged<KoreanRegion> onSelect;

  @override
  Widget build(BuildContext context) {
    final regions = KoreanRegionsData.sigunguForSido(sido);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 24),
            label: const Text(
              UserMessages.jobRegionBackToSido,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: PiumColors.navy,
              side: const BorderSide(color: PiumColors.navy, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${UserMessages.jobRegionSigunguTitle} · ${KoreanRegionsData.shortSidoLabel(sido)}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: PiumColors.navy,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: regions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final region = regions[index];
              final isSelected = selected != null &&
                  selected!.sido == region.sido &&
                  selected!.sigungu == region.sigungu;
              return _RegionListTile(
                label: region.sigungu,
                selected: isSelected,
                onTap: () => onSelect(region),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RegionSearchResults extends StatelessWidget {
  const _RegionSearchResults({
    required this.query,
    required this.results,
    required this.selected,
    required this.onSelect,
  });

  final String query;
  final List<KoreanRegion> results;
  final WorkRegionSelection? selected;
  final ValueChanged<KoreanRegion> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          UserMessages.jobRegionSearchResultTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: PiumColors.navy,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: results.isEmpty
              ? Center(
                  child: Text(
                    UserMessages.jobRegionSearchEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final region = results[index];
                    final isSelected = selected != null &&
                        selected!.sido == region.sido &&
                        selected!.sigungu == region.sigungu;
                    return _RegionListTile(
                      label: region.displayLabel,
                      selected: isSelected,
                      onTap: () => onSelect(region),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? PiumColors.tilePurple : PiumColors.guideBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? PiumColors.tilePurple : PiumColors.navy,
              width: 2,
            ),
          ),
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : PiumColors.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegionListTile extends StatelessWidget {
  const _RegionListTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? PiumColors.tilePurple : PiumColors.guideBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? PiumColors.tilePurple : PiumColors.navy,
              width: 2,
            ),
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? Colors.white : PiumColors.navy,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : PiumColors.navy,
                    ),
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
