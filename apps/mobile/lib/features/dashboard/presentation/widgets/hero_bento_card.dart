import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/credit_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../routes/route_names.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../wallet/presentation/wallet_providers.dart';

class HeroBentoCard extends ConsumerWidget {
  const HeroBentoCard({super.key, required this.weather, required this.credits});
  final AsyncValue<WeatherSnapshot> weather;
  final int credits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.rLg,
        child: Row(
          children: [
            // Weather Section (Mini) - Primary Shade
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: weather.when(
                  data: (w) => Row(
                    children: [
                      _iconWidget(w.icon, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${w.tempC.round()}°C', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(w.condition, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.water_drop_rounded, size: 10, color: Colors.white.withOpacity(0.6)),
                                const SizedBox(width: 2),
                                Text('${w.humidity}%', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9)),
                                const SizedBox(width: 6),
                                Icon(Icons.air_rounded, size: 10, color: Colors.white.withOpacity(0.6)),
                                const SizedBox(width: 2),
                                Text('${w.windKmh.round()} km/h', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
                  error: (_, __) => Icon(Icons.cloud_off_rounded, color: Colors.white.withOpacity(0.5), size: 16),
                ),
              ),
            ),
            // Credit Section (Compact with Eye/Arrow) - Deeper Shade
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.9), // Vert plus clair très opaque
                ),
                child: CompactWallet(credits: credits),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconWidget(String iconKey, {double size = 48}) {
    final icon = switch (iconKey) {
      'sun' => Icons.wb_sunny_rounded,
      'rain' => Icons.umbrella_rounded,
      'storm' => Icons.thunderstorm_rounded,
      'fog' => Icons.foggy,
      'snow' => Icons.ac_unit_rounded,
      _ => Icons.wb_cloudy_rounded,
    };
    return Container(
      height: size + 16,
      width: size + 16,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}

class CompactWallet extends ConsumerWidget {
  const CompactWallet({super.key, required this.credits});
  final int credits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showBalance = ref.watch(showBalanceProvider);
    
    return Row(
      children: [
        IconButton(
          onPressed: () {
            final current = ref.read(showBalanceProvider);
            ref.read(showBalanceProvider.notifier).state = !current;
            if (!current) {
              ref.read(creditServiceProvider.notifier).refreshBalance();
              ref.invalidate(walletTransactionsProvider);
            }
          },
          icon: Icon(showBalance ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 16, color: Colors.white70),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SOLDE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white70)),
              Text(
                showBalance ? '$credits CR.' : '••••',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.push(Routes.wallet),
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class TtsButton extends ConsumerStatefulWidget {
  const TtsButton({super.key, required this.snapshot});
  final WeatherSnapshot snapshot;

  @override
  ConsumerState<TtsButton> createState() => _TtsButtonState();
}

class _TtsButtonState extends ConsumerState<TtsButton> {
  bool _isPlaying = false;

  Future<void> _handleSpeak() async {
    if (_isPlaying) {
      await ref.read(ttsServiceProvider).stop();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isPlaying = true);
    final lang = ref.read(settingsProvider).language;
    final l10n = AppLocalizations.of(context);
    
    final text = l10n.weatherTtsFull(
      widget.snapshot.tempC.round(),
      widget.snapshot.condition,
      widget.snapshot.humidity,
      widget.snapshot.windKmh.round(),
    );

    await ref.read(ttsServiceProvider).speak(text, lang: lang);
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _handleSpeak,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
              key: ValueKey(_isPlaying),
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
