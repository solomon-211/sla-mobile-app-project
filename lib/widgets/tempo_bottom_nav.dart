import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One destination in [TempoBottomNav].
class TempoNavItem {
  const TempoNavItem({
    required this.icon,
    required this.label,
    required this.tabIndex,
  });

  final IconData icon;
  final String label;
  final int tabIndex;
}

/// Floating pill navigation bar. The active item is a moss pill with icon
/// and label; inactive items show the icon only.
class TempoBottomNav extends StatelessWidget {
  const TempoBottomNav({
    super.key,
    required this.items,
    required this.currentTab,
    required this.onSelectTab,
    this.dark = false,
  });

  final List<TempoNavItem> items;
  final int currentTab;
  final ValueChanged<int> onSelectTab;

  /// Slightly lighter pill with a border, used on the dark dashboard.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkNav : AppColors.ink,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark ? AppColors.darkNavBorder : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x66000000) : const Color(0x40121512),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [for (final item in items) _buildItem(item)],
      ),
    );
  }

  Widget _buildItem(TempoNavItem item) {
    final tab = item.tabIndex;
    final selected = tab == currentTab;

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.moss : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSelectTab(tab),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: selected
                    ? const EdgeInsets.fromLTRB(16, 0, 20, 0)
                    : const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: selected ? 20 : 22,
                      color: selected
                          ? AppColors.onMoss
                          : AppColors.textSoftDark,
                    ),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: AppText.manrope(
                          14,
                          weight: FontWeight.w800,
                          color: AppColors.onMoss,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
