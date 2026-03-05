import 'dart:ui';

import 'package:flutter/material.dart';

import 'clinical_theme.dart';

enum PillButtonVariant { filled, tonal, outlined }

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 18,
    this.tintColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tintColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        color: tintColor ?? Colors.white.withValues(alpha: 0.08),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: content,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.text, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.25,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.title,
    required this.valueText,
    this.subtitleText,
    this.leadingIcon,
    this.trailingWidget,
    this.onTap,
  });

  final String title;
  final String valueText;
  final String? subtitleText;
  final IconData? leadingIcon;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final stackTrailing = textScale > 1.2 && trailingWidget != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight <= 96;
        final showSubtitle = subtitleText != null && !compact;
        final shouldStackTrailing = !compact && stackTrailing;

        return GlassCard(
          onTap: onTap,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 8 : 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (leadingIcon != null) ...[
                    Icon(
                      leadingIcon,
                      size: compact ? 16 : 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!shouldStackTrailing && trailingWidget != null)
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: trailingWidget,
                      ),
                    ),
                ],
              ),
              if (shouldStackTrailing) ...[
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerRight, child: trailingWidget),
              ],
              SizedBox(height: compact ? 4 : 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      valueText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (showSubtitle) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleText!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = PillButtonVariant.filled,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case PillButtonVariant.filled:
        return FilledButton(
          onPressed: onPressed,
          child: _label(context),
        );
      case PillButtonVariant.tonal:
        return FilledButton.tonal(
          onPressed: onPressed,
          child: _label(context),
        );
      case PillButtonVariant.outlined:
        return OutlinedButton(
          onPressed: onPressed,
          child: _label(context),
        );
    }
  }

  Widget _label(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final largeText = textScale > 1.2;

    final label = Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    if (icon == null) {
      return label;
    }

    if (largeText) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 4),
          label,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(child: label),
      ],
    );
  }
}

class ClinicalBanner extends StatelessWidget {
  const ClinicalBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 22,
      padding: EdgeInsets.zero,
      tintColor: const Color(0xFF8B7CFF).withValues(alpha: 0.2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              ClinicalPalette.accent.withValues(alpha: 0.15),
              const Color(0xFFC782C4).withValues(alpha: 0.24),
            ],
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ClinicalDivider extends StatelessWidget {
  const ClinicalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.white.withValues(alpha: 0.16), height: 20);
  }
}

class RunsTrack extends StatelessWidget {
  const RunsTrack({
    super.key,
    required this.value,
    this.leftIcon = Icons.directions_run_rounded,
    this.rightIcon = Icons.monitor_heart_outlined,
  });

  final double value;
  final IconData leftIcon;
  final IconData rightIcon;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(leftIcon, color: ClinicalPalette.accentSecondary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: Theme.of(context).sliderTheme.copyWith(
                    trackHeight: 10,
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 12),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
                    activeTrackColor: const Color(0xFF59A8E8),
                  ),
              child: IgnorePointer(
                child: Slider(
                  min: 0,
                  max: 1,
                  value: clamped,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(rightIcon, color: const Color(0xFFF58D7A), size: 22),
        ],
      ),
    );
  }
}
