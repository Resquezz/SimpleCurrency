import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../controllers/app_controller.dart';
import '../widgets/dialogs.dart';
import '../widgets/shared_widgets.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.controller.converterAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outputFill = appFieldFillColor(context);
    final controller = widget.controller;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        SectionCard(
          child: Column(
            children: [
              const Align(alignment: Alignment.centerLeft, child: SectionLabel('Віддаю')),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CurrencyDropdown(
                      value: controller.convertFrom,
                      codes: controller.availableCodes,
                      codeLabelBuilder: controller.currencyOptionLabel,
                      nameBuilder: controller.currencyName,
                      onChanged: controller.setConvertFrom,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      textAlign: TextAlign.end,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      decoration: const InputDecoration(hintText: '100'),
                      onChanged: controller.setConverterAmount,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [accentColor, Color(0xFF5D7BFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: Color(0x332F67E8), blurRadius: 18, offset: Offset(0, 10))],
                ),
                child: IconButton(onPressed: controller.swapCurrencies, icon: const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 28)),
              ),
              const SizedBox(height: 24),
              const Align(alignment: Alignment.centerLeft, child: SectionLabel('Отримую')),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CurrencyDropdown(
                      value: controller.convertTo,
                      codes: controller.availableCodes,
                      codeLabelBuilder: controller.currencyOptionLabel,
                      nameBuilder: controller.currencyName,
                      onChanged: controller.setConvertTo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      decoration: BoxDecoration(color: outputFill, borderRadius: BorderRadius.circular(22)),
                      child: Text(controller.formatAmount(controller.convertedAmount), textAlign: TextAlign.end, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accentColor)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const SectionLabel('ШВИДКІ ПАРИ'),
            const Spacer(),
            TextButton(
              onPressed: () async {
                final pair = await showQuickPairDialog(
                  context: context,
                  availableCodes: controller.availableCodes,
                  initialFrom: controller.convertFrom,
                  initialTo: controller.convertTo,
                  codeLabelBuilder: controller.currencyOptionLabel,
                  nameBuilder: controller.currencyName,
                );
                if (pair != null) {
                  controller.addQuickPair(pair);
                }
              },
              child: const Text('+ ДОДАТИ', style: TextStyle(fontWeight: FontWeight.w800, color: accentColor)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.quickPairs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.32,
          ),
          itemBuilder: (context, index) {
            final pair = controller.quickPairs[index];
            return QuickPairCard(
              pair: pair,
              controller: controller,
              onRemove: () => controller.removeQuickPair(pair.id),
              onTap: () => controller.setConversionPair(pair.from, pair.to),
            );
          },
        ),
      ],
    );
  }
}