// DIDACTIC: CurrencyField — numeric input widget specialized for money values
//
// Purpose:
// - Provide a user-friendly input for currency values with proper formatting
//   and validation.
//
// Contract:
// - Inputs: initial numeric value and onChanged callback.
// - Outputs: numeric value (double) in the expected minor units or decimal.
//
// Notes:
// - Keep formatting/localization concerns in the widget; parsing/validation
//   should remain deterministic for the controller to rely on.

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class CurrencyField extends StatelessWidget {
  const CurrencyField({super.key, required this.controller, this.label = 'Preço', this.errorText});
  final TextEditingController controller;
  final String label;
  final String? errorText;

  String _format(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.isEmpty) return '';
    final cents = int.parse(value);
    final intPart = (cents / 100).floor();
    final frac = (cents % 100).toString().padLeft(2, '0');
    return '$intPart,$frac';
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
      decoration: InputDecoration(labelText: label, prefixText: 'R\$ ', errorText: errorText),
      onChanged: (v) {
        final sel = controller.selection;
        final formatted = _format(v);
        controller.value = TextEditingValue(text: formatted, selection: sel.copyWith(baseOffset: formatted.length, extentOffset: formatted.length));
      },
    );
  }
}
