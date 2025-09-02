import 'package:flutter/material.dart';
import '../../core/theme/color_schemes.dart';

class EventFilterChips extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onSelected;

  const EventFilterChips({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  Widget _buildChip(
      int index, String label, bool selected, void Function() onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.transparent,
      selectedColor: AppColorSchemes.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: selected
            ? AppColorSchemes.primaryColor
            : AppColorSchemes.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected
              ? AppColorSchemes.primaryColor
              : AppColorSchemes.borderColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChip(0, 'All Events', selectedIndex == 0, () => onSelected(0)),
        const SizedBox(width: 8),
        _buildChip(1, 'This Week', selectedIndex == 1, () => onSelected(1)),
        const SizedBox(width: 8),
        _buildChip(2, 'This Month', selectedIndex == 2, () => onSelected(2)),
        const SizedBox(width: 8),
        _buildChip(3, 'My Events', selectedIndex == 3, () => onSelected(3)),
      ],
    );
  }
}
