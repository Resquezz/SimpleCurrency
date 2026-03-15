import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/models/wallet_models.dart';
import '../controllers/app_controller.dart';
import '../widgets/dialogs.dart';
import '../widgets/shared_widgets.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final expenseBreakdown = controller.expenseBreakdown;
    final currentCategories = controller.categoriesFor(controller.selectedTransactionKind);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text('Мій гаманець', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 18),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [accentColor, Color(0xFF5156E1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Color(0x332F67E8), blurRadius: 24, offset: Offset(0, 18))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ЗАГАЛЬНИЙ БАЛАНС', style: TextStyle(color: Color(0xC9FFFFFF), fontWeight: FontWeight.w800, letterSpacing: 0.6)),
              const SizedBox(height: 14),
              Text('${controller.formatAmount(controller.totalBalance)} грн', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 180,
                  child: expenseBreakdown.isEmpty
                      ? const Center(child: Text('Ще немає витрат за місяць.'))
                      : PieChart(
                          PieChartData(
                            centerSpaceRadius: 42,
                            sectionsSpace: 3,
                            sections: expenseBreakdown.map((entry) => PieChartSectionData(value: entry.amount, color: entry.category.color, showTitle: false, radius: 20)).toList(),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: expenseBreakdown.isEmpty
                      ? const [Text('Додайте витрати, щоб побачити структуру витрат.', style: TextStyle(color: mutedText, fontWeight: FontWeight.w600))]
                      : expenseBreakdown
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 11, height: 11, decoration: BoxDecoration(color: entry.category.color, shape: BoxShape.circle)),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(entry.category.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 21),
                                    child: Text('${controller.formatAmount(entry.amount)} грн', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<TransactionKind>(
                segments: const [
                  ButtonSegment(value: TransactionKind.expense, label: Text('Витрата')),
                  ButtonSegment(value: TransactionKind.income, label: Text('Прибуток')),
                ],
                selected: {controller.selectedTransactionKind},
                onSelectionChanged: (selection) => controller.setTransactionKind(selection.first),
                showSelectedIcon: false,
                style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size.fromHeight(58))),
              ),
              const SizedBox(height: 16),
              TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Сума (UAH)')),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SectionLabel('КАТЕГОРІЯ'),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final category = await showCategoryDialog(context, kind: controller.selectedTransactionKind);
                      if (category != null) {
                        await controller.addCategory(category);
                      }
                    },
                    child: const Text('+ ДОДАТИ', style: TextStyle(fontWeight: FontWeight.w800, color: accentColor)),
                  ),
                  if (controller.selectedCategory != null)
                    TextButton(
                      onPressed: () async {
                        final edited = await showCategoryDialog(context, kind: controller.selectedTransactionKind, initial: controller.selectedCategory);
                        if (edited != null) {
                          await controller.updateCategory(edited);
                        }
                      },
                      child: const Text('РЕД.', style: TextStyle(fontWeight: FontWeight.w800, color: mutedText)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (currentCategories.isEmpty)
                const Text('Категорій ще немає. Спочатку додайте свою категорію.', style: TextStyle(color: mutedText, fontWeight: FontWeight.w600))
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: currentCategories.map((category) => CategoryChip(category: category, selected: category.id == controller.selectedCategoryId, onTap: () => controller.selectCategory(category.id))).toList(),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: inkColor, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(62), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                  onPressed: () async {
                    final result = await controller.addTransaction(_amountController.text);
                    if (!context.mounted) {
                      return;
                    }
                    if (result == null) {
                      _amountController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Транзакцію збережено.')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                    }
                  },
                  child: const Text('Зберегти транзакцію', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionLabel('ОСТАННІ ДІЇ'),
        const SizedBox(height: 12),
        if (controller.recentTransactions.isEmpty)
          const Text('Поки що тут порожньо. Додані транзакції зʼявляться в цьому списку.', style: TextStyle(color: mutedText, fontWeight: FontWeight.w600))
        else
          ...controller.recentTransactions.map((transaction) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TransactionTile(transaction: transaction, category: controller.categoryById(transaction.categoryId)))),
      ],
    );
  }
}