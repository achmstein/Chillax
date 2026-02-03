import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import '../models/localized_text.dart';
import 'app_text.dart';

/// A widget that provides text fields for both English and Arabic input
/// with a clean, compact UI design.
class LocalizedTextField extends StatelessWidget {
  final String label;
  final TextEditingController enController;
  final TextEditingController arController;
  final String? enHint;
  final String? arHint;
  final bool isMultiline;
  final int maxLines;
  final bool isRequired;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;

  const LocalizedTextField({
    super.key,
    required this.label,
    required this.enController,
    required this.arController,
    this.enHint,
    this.arHint,
    this.isMultiline = false,
    this.maxLines = 1,
    this.isRequired = false,
    this.inputFormatters,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        AppText(
          isRequired ? '$label *' : label,
          style: theme.typography.sm.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // English field
        _LanguageTextField(
          controller: enController,
          languageCode: 'EN',
          hint: enHint,
          isMultiline: isMultiline,
          maxLines: maxLines,
          textDirection: TextDirection.ltr,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
        ),
        const SizedBox(height: 8),

        // Arabic field
        _LanguageTextField(
          controller: arController,
          languageCode: 'AR',
          hint: arHint,
          isMultiline: isMultiline,
          maxLines: maxLines,
          textDirection: TextDirection.rtl,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
        ),
      ],
    );
  }
}

class _LanguageTextField extends StatelessWidget {
  final TextEditingController controller;
  final String languageCode;
  final String? hint;
  final bool isMultiline;
  final int maxLines;
  final TextDirection textDirection;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;

  const _LanguageTextField({
    required this.controller,
    required this.languageCode,
    this.hint,
    required this.isMultiline,
    required this.maxLines,
    required this.textDirection,
    this.inputFormatters,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Row(
      crossAxisAlignment:
          isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Language badge
        Container(
          width: 32,
          height: 24,
          margin: EdgeInsets.only(top: isMultiline ? 10 : 0),
          decoration: BoxDecoration(
            color: theme.colors.secondary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: AppText(
              languageCode,
              style: theme.typography.xs.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colors.secondaryForeground,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Text field
        Expanded(
          child: isMultiline
              ? FTextField.multiline(
                  control: FTextFieldControl.managed(controller: controller),
                  hint: hint,
                  minLines: 2,
                  maxLines: maxLines,
                  textDirection: textDirection,
                )
              : FTextField(
                  control: FTextFieldControl.managed(controller: controller),
                  hint: hint,
                  textDirection: textDirection,
                  inputFormatters: inputFormatters,
                  keyboardType: keyboardType,
                ),
        ),
      ],
    );
  }
}

/// Extension to easily create LocalizedText from controller values
extension LocalizedTextControllers on LocalizedTextField {
  static LocalizedText getValue(
    TextEditingController enController,
    TextEditingController arController,
  ) {
    final en = enController.text.trim();
    final ar = arController.text.trim();
    return LocalizedText(
      en: en,
      ar: ar.isNotEmpty ? ar : null,
    );
  }

  static LocalizedText? getValueOrNull(
    TextEditingController enController,
    TextEditingController arController,
  ) {
    final en = enController.text.trim();
    if (en.isEmpty) return null;
    final ar = arController.text.trim();
    return LocalizedText(
      en: en,
      ar: ar.isNotEmpty ? ar : null,
    );
  }
}
