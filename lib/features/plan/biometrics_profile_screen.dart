import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/clinical_theme.dart';
import '../ui/clinical_widgets.dart';
import 'biometrics_profile.dart';

class BiometricsProfileScreen extends StatefulWidget {
  const BiometricsProfileScreen({
    super.key,
    required this.initialBiometrics,
    required this.daysPerWeek,
  });

  final Map<String, dynamic> initialBiometrics;
  final int daysPerWeek;

  @override
  State<BiometricsProfileScreen> createState() =>
      _BiometricsProfileScreenState();
}

class _BiometricsProfileScreenState extends State<BiometricsProfileScreen> {
  late final TextEditingController _ageController;
  late final TextEditingController _heightFtController;
  late final TextEditingController _heightInController;
  late final TextEditingController _weightLbController;

  String _sex = 'male';
  String _buildType = 'average';
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final parsed = BiometricsCalculator.parseInput(widget.initialBiometrics);

    _ageController = TextEditingController(
      text: parsed?.age.toString() ?? '',
    );
    _heightFtController = TextEditingController(
      text: parsed?.heightFt.toString() ?? '',
    );
    _heightInController = TextEditingController(
      text: parsed?.heightIn.toString() ?? '',
    );
    _weightLbController = TextEditingController(
      text: parsed == null
          ? ''
          : BiometricsCalculator.roundTo(parsed.weightLb, 1).toString(),
    );
    _sex = parsed?.sex ?? _sex;
    _buildType = parsed?.buildType ?? _buildType;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightFtController.dispose();
    _heightInController.dispose();
    _weightLbController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _rawInput() => <String, dynamic>{
        'age': int.tryParse(_ageController.text.trim()),
        'sex': _sex,
        'height_ft': int.tryParse(_heightFtController.text.trim()),
        'height_in': int.tryParse(_heightInController.text.trim()),
        'weight_lb': double.tryParse(_weightLbController.text.trim()),
        'build_type': _buildType,
      };

  Map<String, dynamic>? _normalizedInput() =>
      BiometricsCalculator.normalizeInputMap(_rawInput());

  Map<String, dynamic>? _previewPayload() =>
      BiometricsCalculator.computePromptPayloadFromMap(
        rawInput: _rawInput(),
        daysPerWeek: widget.daysPerWeek,
      );

  void _save() {
    final normalized = _normalizedInput();
    if (normalized == null) {
      setState(() {
        _errorText =
            'Enter valid biometrics before saving (age, sex, height, weight, build type).';
      });
      return;
    }
    Navigator.of(context).pop(normalized);
  }

  List<Widget> _previewChips(Map<String, dynamic> preview) {
    final chipTheme = Theme.of(context).chipTheme;
    final entries = <({String label, String value})>[
      (
        label: 'Body Fat',
        value: '${preview['body_fat_percent'] ?? '--'}%',
      ),
      (
        label: 'BMI',
        value: '${preview['bmi'] ?? '--'}',
      ),
      (
        label: 'BMR',
        value: '${preview['estimated_bmr_kcal'] ?? '--'} kcal',
      ),
      (
        label: 'TDEE',
        value: '${preview['estimated_tdee_kcal'] ?? '--'} kcal',
      ),
    ];
    return entries
        .map(
          (entry) => Chip(
            visualDensity: VisualDensity.compact,
            label: Text('${entry.label}: ${entry.value}'),
            labelStyle: chipTheme.labelStyle,
          ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewPayload();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Biometric Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'PROGRESSIVE OVERLOAD PLAN',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 1.1,
              color: ClinicalPalette.accentSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Biometric Profile',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture the same body-composition context used across plan intake so weekly generation can calibrate energy demand and recovery more intelligently.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ClinicalPalette.accent.withValues(alpha: 0.16),
                  ),
                  child: const Icon(Icons.monitor_weight_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Planner Context',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Valid entries are saved into plan intake and rendered into `BIOMETRICS_V1` inside the weekly AI prompt. TDEE uses ${widget.daysPerWeek} training day${widget.daysPerWeek == 1 ? '' : 's'} per week.',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(text: 'Core Inputs'),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use the same intake format as the rest of the planner. Age, sex, height, weight, and build type are all required before saving.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Age'),
                  onChanged: (_) => setState(() => _errorText = null),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _sex,
                  decoration: const InputDecoration(labelText: 'Sex'),
                  items: kBiometricsSexOptions
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child:
                              Text(BiometricsCalculator.titleCaseLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _sex = value;
                      _errorText = null;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _heightFtController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Height (ft)',
                        ),
                        onChanged: (_) => setState(() => _errorText = null),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _heightInController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Height (in)',
                        ),
                        onChanged: (_) => setState(() => _errorText = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _weightLbController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(labelText: 'Weight (lb)'),
                  onChanged: (_) => setState(() => _errorText = null),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _buildType,
                  decoration: const InputDecoration(labelText: 'Build Type'),
                  items: kBiometricsBuildTypes
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child:
                              Text(BiometricsCalculator.titleCaseLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _buildType = value;
                      _errorText = null;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(text: 'Prompt Preview'),
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'When the inputs are valid, this computed payload is what the planner can include in `BIOMETRICS_V1` for weekly generation.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                if (preview != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _previewChips(preview),
                  )
                ],
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: preview == null
                      ? Text(
                          'Enter valid fields to preview computed body fat, lean mass, BMI, BMR, and TDEE.',
                          style: theme.textTheme.bodyMedium,
                        )
                      : SelectableText(
                          const JsonEncoder.withIndent('  ').convert(preview),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            height: 1.35,
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            GlassCard(
              tintColor: theme.colorScheme.error.withValues(alpha: 0.18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryPillButton(
                  text: 'Cancel',
                  variant: PillButtonVariant.outlined,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryPillButton(
                  text: 'Save Biometrics',
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
