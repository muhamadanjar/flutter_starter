import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/network_info.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class OfflineBanner extends ConsumerWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(isConnectedProvider);

    return connectivityAsync.when(
      data: (isConnected) {
        if (isConnected) return child;
        return Column(
          children: [
            _buildBanner(context),
            Expanded(child: child),
          ],
        );
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.colors.warning, const Color(0xFFE67E22)],
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.warning.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'You are offline. Some features may not be available.',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
