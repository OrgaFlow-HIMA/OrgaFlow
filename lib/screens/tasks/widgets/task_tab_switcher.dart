import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class TaskTabSwitcher extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final int todoCount;
  final int doneCount;
  final String todoLabel;
  final String doneLabel;

  const TaskTabSwitcher({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.todoCount,
    required this.doneCount,
    this.todoLabel = 'Perlu Dikerjakan',
    this.doneLabel = 'Selesai',
  });

  @override
  Widget build(BuildContext context) {
    final labels = [todoLabel, doneLabel];
    final counts = [todoCount, doneCount];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / labels.length;

        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: (selectedIndex * tabWidth) + 4,
                top: 4,
                bottom: 4,
                width: tabWidth - 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (i) {
                  final isSelected = selectedIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTabChanged(i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                          child: Text(
                            '${labels[i]} (${counts[i]})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
