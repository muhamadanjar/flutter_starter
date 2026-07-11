import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A single slide in an [AppBannerCarousel].
///
/// Navigation is the caller's responsibility via [onTap] so this widget
/// stays free of router dependencies.
class BannerItem {
  const BannerItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.gradient,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// Optional gradient colors; defaults to a primary-based gradient.
  final List<Color>? gradient;

  final VoidCallback? onTap;
}

/// Shared banner carousel with a smooth page indicator.
///
/// Auto-plays through [items] every [autoPlayInterval]; the timer pauses
/// while the user is dragging and resumes afterwards.
class AppBannerCarousel extends StatefulWidget {
  const AppBannerCarousel({
    super.key,
    required this.items,
    this.height = 160,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 5),
  });

  final List<BannerItem> items;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;

  @override
  State<AppBannerCarousel> createState() => _AppBannerCarouselState();
}

class _AppBannerCarouselState extends State<AppBannerCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    if (!widget.autoPlay || widget.items.length < 2) return;
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!_controller.hasClients) return;
      final current = _controller.page?.round() ?? 0;
      final next = (current + 1) % widget.items.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoPlay() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: Listener(
            onPointerDown: (_) => _stopAutoPlay(),
            onPointerUp: (_) => _startAutoPlay(),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.items.length,
              itemBuilder: (context, index) =>
                  _BannerSlide(item: widget.items[index]),
            ),
          ),
        ),
        if (widget.items.length > 1) ...[
          const SizedBox(height: 12),
          SmoothPageIndicator(
            controller: _controller,
            count: widget.items.length,
            effect: WormEffect(
              dotHeight: 8,
              dotWidth: 8,
              spacing: 8,
              activeDotColor: context.colors.primary,
              dotColor: context.colors.divider,
            ),
          ),
        ],
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.item});

  final BannerItem item;

  @override
  Widget build(BuildContext context) {
    final colors = item.gradient ??
        [
          context.colors.primary,
          context.colors.primary.withValues(alpha: 0.7),
        ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: InkWell(
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTypography.headlineSmall
                              .copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.subtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    item.icon,
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
