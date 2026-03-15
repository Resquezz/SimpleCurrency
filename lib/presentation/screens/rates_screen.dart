import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../controllers/app_controller.dart';
import '../widgets/shared_widgets.dart';

class RatesScreen extends StatelessWidget {
  const RatesScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final line = appLineColor(context);
    final chipFill = appFieldFillColor(context);
    final selectedFill = appSelectionSurface(context);
    final selectedFg = appSelectionForeground(context);
    final ink = appInkColor(context);
    final muted = appMutedColor(context);
    final snapshot = controller.snapshot;
    if (snapshot == null) {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(child: Text('Не вдалося завантажити курси.'));
    }
    final codes = controller.availableCodes;
    final visibleCodes = [
      ...controller.favoriteCurrencies.where((code) => code != controller.baseCurrency && codes.contains(code)),
      ...codes.where((code) => code != controller.baseCurrency && !controller.favoriteCurrencies.contains(code)),
    ];
    final favoriteCodes = controller.favoriteCurrencies.where(codes.contains).toList(growable: false);

    return RefreshIndicator(
      onRefresh: controller.refreshRates,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('БАЗОВА ВАЛЮТА'),
                const SizedBox(height: 14),
                CurrencyDropdown(
                  value: controller.baseCurrency,
                  codes: codes,
                  codeLabelBuilder: controller.currencyOptionLabel,
                  nameBuilder: controller.currencyName,
                  onChanged: controller.setBaseCurrency,
                ),
                const SizedBox(height: 14),
                Text('Оновлено ${snapshot.formattedUpdatedAt}', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (controller.favoriteCurrencies.isNotEmpty) ...[
            Row(
              children: [
                const SectionLabel('ОБРАНЕ'),
                const Spacer(),
                Text('${controller.favoriteCurrencies.length} валют', style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 20) / 3;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: favoriteCodes
                      .map(
                        (code) => SizedBox(
                          width: itemWidth,
                          child: ChoiceChip(
                            label: Align(
                              alignment: Alignment.center,
                              child: Text(
                                controller.currencyLabel(code),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            selected: code == controller.baseCurrency,
                            showCheckmark: false,
                            onSelected: (_) => controller.setBaseCurrency(code),
                            backgroundColor: chipFill,
                            selectedColor: selectedFill,
                            side: BorderSide(color: line),
                            labelStyle: TextStyle(color: code == controller.baseCurrency ? selectedFg : ink, fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 18),
          ],
          ...visibleCodes.map(
            (code) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: RateTile(
                title: controller.currencyLabel(code),
                subtitle: controller.currencyName(code),
                value: controller.formatRate(controller.rateBetween(controller.baseCurrency, code)),
                isFavorite: controller.favoriteCurrencies.contains(code),
                onFavoriteToggle: () => controller.toggleFavoriteCurrency(code),
              ),
            ),
          ),
        ],
      ),
    );
  }
}