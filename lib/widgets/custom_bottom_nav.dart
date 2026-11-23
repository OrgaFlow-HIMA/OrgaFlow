import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class DashboardNavItem {
  final String label;
  final IconData icon;

  const DashboardNavItem({required this.label, required this.icon});
}

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<DashboardNavItem> items;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  static const double _navHeight = 110;
  static const double _circleSize = 56;
  static const double _circleTop = 6;
  static const double _horizontalPadding = 20;

  int get _currentIndex {
    if (widget.items.isEmpty) return 0;

    return widget.selectedIndex.clamp(0, widget.items.length - 1);
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _animation = AlwaysStoppedAnimation(_currentIndex.toDouble());
  }

  @override
  void didUpdateWidget(covariant CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.items.isEmpty) {
      _controller.stop();
      return;
    }

    final indexChanged = oldWidget.selectedIndex != widget.selectedIndex;

    final itemCountChanged = oldWidget.items.length != widget.items.length;

    if (indexChanged || itemCountChanged) {
      final begin = _animation.value.clamp(
        0.0,
        (widget.items.length - 1).toDouble(),
      );

      final end = _currentIndex.toDouble();

      _animation = Tween<double>(begin: begin, end: end).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
      );

      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: _navHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth =
              constraints.maxWidth - (_horizontalPadding * 2);

          final itemWidth = availableWidth / widget.items.length;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final currentPosition = _animation.value;

              // Titik tengah item berdasarkan area navigasi
              // yang sudah menggunakan horizontal padding.
              final centerX =
                  _horizontalPadding + (currentPosition + 0.5) * itemWidth;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background putih dan tonjolan aktif.
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ActiveNavPainter(
                        centerX: centerX,
                        circleRadius: _circleSize / 2,
                      ),
                    ),
                  ),

                  // Item navigasi.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _horizontalPadding,
                    ),
                    child: Row(
                      children: List.generate(widget.items.length, (index) {
                        final item = widget.items[index];
                        final isSelected = index == _currentIndex;

                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (!isSelected) {
                                widget.onItemSelected(index);
                              }
                            },
                            child: SizedBox(
                              height: _navHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const SizedBox(height: 20),

                                  if (isSelected)
                                    const SizedBox(height: 24)
                                  else
                                    Icon(
                                      item.icon,
                                      color: AppTheme.textSecondary,
                                      size: 24,
                                    ),

                                  const SizedBox(height: 4),

                                  Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primaryBlue
                                          : AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),

                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Circle biru aktif.
                  Positioned(
                    left: centerX - (_circleSize / 2),
                    top: _circleTop,
                    child: IgnorePointer(
                      child: Container(
                        width: _circleSize,
                        height: _circleSize,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.items[_currentIndex].icon,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ======================================================
// CUSTOM PAINTER: NAVBAR DENGAN TONJOLAN CIRCLE AKTIF
// ======================================================

class ActiveNavPainter extends CustomPainter {
  final double centerX;
  final double circleRadius;

  const ActiveNavPainter({required this.centerX, this.circleRadius = 28});

  @override
  void paint(Canvas canvas, Size size) {
    const bumpHeight = 20.0;
    const bumpWidthExtra = 16.0;

    final bumpWidth = circleRadius + bumpWidthExtra;

    // Posisi awal dan akhir tonjolan.
    final leftBump = centerX - bumpWidth;
    final rightBump = centerX + bumpWidth;

    final path = Path();

    // Sisi kiri atas.
    path.moveTo(0, bumpHeight);
    path.lineTo(leftBump, bumpHeight);

    // Lengkungan naik.
    path.cubicTo(
      leftBump + bumpWidth * 0.45,
      bumpHeight,
      centerX - circleRadius * 1.1,
      0,
      centerX,
      0,
    );

    // Lengkungan turun.
    path.cubicTo(
      centerX + circleRadius * 1.1,
      0,
      rightBump - bumpWidth * 0.45,
      bumpHeight,
      rightBump,
      bumpHeight,
    );

    // Sisi kanan atas.
    path.lineTo(size.width, bumpHeight);

    // Sisi kanan dan bawah.
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..color = AppTheme.surface
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Shadow mengikuti bentuk navbar.
    canvas.drawShadow(path, Colors.black.withOpacity(0.08), 12, false);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ActiveNavPainter oldDelegate) {
    return oldDelegate.centerX != centerX ||
        oldDelegate.circleRadius != circleRadius;
  }
}
