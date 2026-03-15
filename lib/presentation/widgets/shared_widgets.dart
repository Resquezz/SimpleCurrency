import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/app_utils.dart';
import '../../data/models/rate_models.dart';
import '../../data/models/wallet_models.dart';
import '../controllers/app_controller.dart';

class StatusBadge extends StatelessWidget {
	const StatusBadge({super.key, required this.isOffline});

	final bool isOffline;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
			decoration: BoxDecoration(
				color: isOffline ? offlineFill : const Color(0xFFE9F8EF),
				borderRadius: BorderRadius.circular(999),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Container(
						width: 9,
						height: 9,
						decoration: BoxDecoration(
							color: isOffline ? offlineText : successColor,
							shape: BoxShape.circle,
						),
					),
					const SizedBox(width: 8),
					Text(
						isOffline ? 'ОФЛАЙН' : 'ОНЛАЙН',
						style: TextStyle(
							color: isOffline ? offlineText : successColor,
							fontWeight: FontWeight.w800,
							fontSize: 12,
							letterSpacing: 0.4,
						),
					),
				],
			),
		);
	}
}

class FirebaseSyncBanner extends StatelessWidget {
	const FirebaseSyncBanner({super.key, required this.enabled, required this.hasError});

	final bool enabled;
	final bool hasError;

	@override
	Widget build(BuildContext context) {
		final colors = Theme.of(context).colorScheme;
		final bg = enabled ? colors.primaryContainer : colors.surfaceContainerHighest;
		final fg = enabled ? colors.onPrimaryContainer : colors.onSurfaceVariant;
		final text = enabled
				? 'Ця плашка показує лише синхронізацію гаманця і налаштувань між вашими пристроями. На курси валют вона не впливає.'
				: hasError
						? 'Firebase недоступний. Гаманець і налаштування зберігаються лише на цьому пристрої.'
						: 'Cloud sync недоступний.';

		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
			child: Row(
				children: [
					Icon(enabled ? Icons.cloud_done_rounded : Icons.cloud_off_rounded, color: fg),
					const SizedBox(width: 12),
					Expanded(child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700))),
				],
			),
		);
	}
}

class SectionCard extends StatelessWidget {
	const SectionCard({super.key, required this.child});

	final Widget child;

	@override
	Widget build(BuildContext context) {
		return Card(child: Padding(padding: const EdgeInsets.all(22), child: child));
	}
}

class SectionLabel extends StatelessWidget {
	const SectionLabel(this.text, {super.key});

	final String text;

	@override
	Widget build(BuildContext context) {
		final muted = appMutedColor(context);
		return Text(
			text,
			style: TextStyle(color: muted, fontWeight: FontWeight.w800, letterSpacing: 0.6),
		);
	}
}

class CurrencyDropdown extends StatelessWidget {
	const CurrencyDropdown({
		super.key,
		required this.value,
		required this.codes,
		required this.codeLabelBuilder,
		required this.nameBuilder,
		required this.onChanged,
	});

	final String value;
	final List<String> codes;
	final String Function(String code) codeLabelBuilder;
	final String Function(String code) nameBuilder;
	final ValueChanged<String> onChanged;

	@override
	Widget build(BuildContext context) {
		return DropdownButtonFormField<String>(
			key: ValueKey(value),
			initialValue: codes.contains(value) ? value : codes.first,
			isExpanded: true,
			menuMaxHeight: 360,
			decoration: const InputDecoration(),
			selectedItemBuilder: (context) => codes
					.map(
						(code) => _CurrencySelectedContent(
							codeLabel: codeLabelBuilder(code),
							name: nameBuilder(code),
						),
					)
					.toList(),
			items: codes
					.map(
						(code) => DropdownMenuItem<String>(
							value: code,
							child: _CurrencyOptionContent(
								codeLabel: codeLabelBuilder(code),
								name: nameBuilder(code),
							),
						),
					)
					.toList(),
			onChanged: (value) {
				if (value != null) {
					onChanged(value);
				}
			},
		);
	}
}

class _CurrencySelectedContent extends StatelessWidget {
	const _CurrencySelectedContent({required this.codeLabel, required this.name});

	final String codeLabel;
	final String name;

	@override
	Widget build(BuildContext context) {
		final ink = appInkColor(context);
		return Text(
			'$codeLabel · $name',
			maxLines: 1,
			overflow: TextOverflow.ellipsis,
			style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ink),
		);
	}
}

class _CurrencyOptionContent extends StatelessWidget {
	const _CurrencyOptionContent({required this.codeLabel, required this.name});

	final String codeLabel;
	final String name;

	@override
	Widget build(BuildContext context) {
		final muted = appMutedColor(context);
		return Column(
			mainAxisSize: MainAxisSize.min,
			crossAxisAlignment: CrossAxisAlignment.start,
			mainAxisAlignment: MainAxisAlignment.center,
			children: [
				Text(
					codeLabel,
					maxLines: 1,
					overflow: TextOverflow.ellipsis,
					style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
				),
				const SizedBox(height: 2),
				Text(
					name,
					maxLines: 1,
					overflow: TextOverflow.ellipsis,
					style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12),
				),
			],
		);
	}
}

class RateTile extends StatelessWidget {
	const RateTile({
		super.key,
		required this.title,
		required this.subtitle,
		required this.value,
		required this.isFavorite,
		required this.onFavoriteToggle,
	});

	final String title;
	final String subtitle;
	final String value;
	final bool isFavorite;
	final VoidCallback onFavoriteToggle;

	@override
	Widget build(BuildContext context) {
		final muted = appMutedColor(context);
		return Card(
			child: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
				child: Row(
					children: [
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
									const SizedBox(height: 4),
									Text(subtitle, style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
								],
							),
						),
						const SizedBox(width: 12),
						Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
						const SizedBox(width: 8),
						IconButton(
							onPressed: onFavoriteToggle,
							icon: Icon(
								isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
								color: isFavorite ? const Color(0xFFFFB300) : muted,
							),
						),
					],
				),
			),
		);
	}
}

class QuickPairCard extends StatelessWidget {
	const QuickPairCard({
		super.key,
		required this.pair,
		required this.controller,
		required this.onRemove,
		required this.onTap,
	});

	final QuickPair pair;
	final AppController controller;
	final VoidCallback onRemove;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final muted = appMutedColor(context);
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(26),
			child: Card(
				child: Padding(
					padding: const EdgeInsets.all(18),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Row(
								children: [
									Expanded(
										child: Text(
											'${pair.from} / ${pair.to}',
											style: TextStyle(color: muted, fontWeight: FontWeight.w800),
										),
									),
									IconButton(
										onPressed: onRemove,
										visualDensity: VisualDensity.compact,
										icon: Icon(Icons.close_rounded, color: muted),
									),
								],
							),
							const SizedBox(height: 12),
							Text(
								controller.formatRate(controller.rateBetween(pair.from, pair.to)),
								style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
							),
						],
					),
				),
			),
		);
	}
}

class AnalyticsDeltaBadge extends StatelessWidget {
	const AnalyticsDeltaBadge({super.key, required this.change});

	final double change;

	@override
	Widget build(BuildContext context) {
		final isPositive = change >= 0;
		final isDark = Theme.of(context).brightness == Brightness.dark;
		final background = isPositive
				? (isDark ? const Color(0xFF173828) : const Color(0xFFEAF8F0))
				: (isDark ? const Color(0xFF3A1F24) : const Color(0xFFFFEDEC));
		final foreground = isPositive ? (isDark ? const Color(0xFF86E2AE) : successColor) : (isDark ? const Color(0xFFFFA3A3) : dangerColor);
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
			decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18)),
			child: Text(
				'${isPositive ? '↑' : '↓'} ${change.abs().toStringAsFixed(1)}%',
				style: TextStyle(fontWeight: FontWeight.w900, color: foreground, fontSize: 16),
			),
		);
	}
}

class StatsCard extends StatelessWidget {
	const StatsCard({super.key, required this.title, required this.value});

	final String title;
	final String value;

	@override
	Widget build(BuildContext context) {
		final muted = appMutedColor(context);
		return SizedBox(
			height: 118,
			child: Card(
				child: Padding(
					padding: const EdgeInsets.all(20),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(title.toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
							const Spacer(),
							Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
						],
					),
				),
			),
		);
	}
}

class CategoryChip extends StatelessWidget {
	const CategoryChip({
		super.key,
		required this.category,
		required this.selected,
		required this.onTap,
	});

	final WalletCategory category;
	final bool selected;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final fill = selected ? appSelectionSurface(context) : appFieldFillColor(context);
		final borderColor = selected ? appSelectionSurface(context) : appLineColor(context);
		final foreground = selected ? appSelectionForeground(context) : appInkColor(context);
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(22),
			child: AnimatedContainer(
				duration: const Duration(milliseconds: 160),
				padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
				decoration: BoxDecoration(
					color: fill,
					borderRadius: BorderRadius.circular(22),
					border: Border.all(color: borderColor),
				),
				child: Row(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(category.icon, color: foreground),
						const SizedBox(width: 10),
						Text(
							category.name,
							style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
						),
					],
				),
			),
		);
	}
}

class TransactionTile extends StatelessWidget {
	const TransactionTile({super.key, required this.transaction, required this.category});

	final WalletTransaction transaction;
	final WalletCategory? category;

	@override
	Widget build(BuildContext context) {
		final isIncome = transaction.kind == TransactionKind.income;
		final amountColor = isIncome ? successColor : dangerColor;
		final iconColor = category?.color ?? accentColor;
		final muted = appMutedColor(context);

		return Card(
			child: Padding(
				padding: const EdgeInsets.all(18),
				child: Row(
					children: [
						Container(
							width: 54,
							height: 54,
							decoration: BoxDecoration(
								color: iconColor.withValues(alpha: 0.18),
								borderRadius: BorderRadius.circular(18),
							),
							child: Icon(category?.icon ?? Icons.category_rounded, color: iconColor),
						),
						const SizedBox(width: 14),
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										category?.name ?? 'Категорія',
										style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
									),
									const SizedBox(height: 4),
									Text(
										formatTransactionDate(transaction.createdAt),
										style: TextStyle(color: muted, fontWeight: FontWeight.w600),
									),
								],
							),
						),
						Text(
							'${isIncome ? '+' : '-'}${formatNumber(transaction.amount)}',
							style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: amountColor),
						),
					],
				),
			),
		);
	}
}