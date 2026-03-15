import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../controllers/app_controller.dart';
import '../widgets/shared_widgets.dart';
import 'analytics_screen.dart';
import 'converter_screen.dart';
import 'rates_screen.dart';
import 'wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller, required this.email, required this.onSignOut});

  final AppController controller;
  final String email;
  final Future<void> Function() onSignOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  static const _screenNames = ['rates', 'converter', 'analytics', 'wallet'];

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.logScreen(_screenNames[_currentIndex]));
  }

  void _selectDestination(int index) {
    setState(() => _currentIndex = index);
    unawaited(widget.controller.logScreen(_screenNames[index]));
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final pages = [
      RatesScreen(controller: controller),
      ConverterScreen(controller: controller),
      AnalyticsScreen(controller: controller),
      WalletScreen(controller: controller),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('SimpleCurrency', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(child: StatusBadge(isOffline: controller.isOffline)),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'light') {
                controller.setThemeMode(ThemeMode.light);
              } else if (value == 'dark') {
                controller.setThemeMode(ThemeMode.dark);
              } else if (value == 'system') {
                controller.setThemeMode(ThemeMode.system);
              } else if (value == 'logout') {
                await widget.onSignOut();
              }
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(value: 'system', checked: controller.themeMode == ThemeMode.system, child: const Text('Системна тема')),
              CheckedPopupMenuItem(value: 'light', checked: controller.themeMode == ThemeMode.light, child: const Text('Світла тема')),
              CheckedPopupMenuItem(value: 'dark', checked: controller.themeMode == ThemeMode.dark, child: const Text('Темна тема')),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Вийти (${widget.email})')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Icon(themeModeIcon(controller.themeMode), key: ValueKey(controller.themeMode)),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Оновити',
            onPressed: controller.isRefreshing ? null : () => unawaited(controller.refreshRates()),
            icon: controller.isRefreshing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: lineColor)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(key: ValueKey(_currentIndex), child: pages[_currentIndex]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectDestination,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.view_list_rounded), label: 'Курси'),
          NavigationDestination(icon: Icon(Icons.currency_exchange_rounded), label: 'Обмін'),
          NavigationDestination(icon: Icon(Icons.insights_rounded), label: 'Аналіз'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Гаманець'),
        ],
      ),
    );
  }
}