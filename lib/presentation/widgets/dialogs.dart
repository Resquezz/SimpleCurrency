import 'package:flutter/material.dart';

import '../../core/app_utils.dart';
import '../../data/models/rate_models.dart';
import '../../data/models/wallet_models.dart';
import 'shared_widgets.dart';

Future<QuickPair?> showQuickPairDialog({
	required BuildContext context,
	required List<String> availableCodes,
	required String initialFrom,
	required String initialTo,
	required String Function(String code) codeLabelBuilder,
	required String Function(String code) nameBuilder,
}) async {
	var from = initialFrom;
	var to = initialTo;

	return showDialog<QuickPair>(
		context: context,
		useRootNavigator: false,
		builder: (context) {
			return StatefulBuilder(
				builder: (context, setState) {
					return AlertDialog(
						shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
						title: const Text('Додати пару', style: TextStyle(fontWeight: FontWeight.w800)),
						content: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								CurrencyDropdown(
									value: from,
									codes: availableCodes,
									codeLabelBuilder: codeLabelBuilder,
									nameBuilder: nameBuilder,
									onChanged: (value) => setState(() => from = value),
								),
								const SizedBox(height: 12),
								CurrencyDropdown(
									value: to,
									codes: availableCodes,
									codeLabelBuilder: codeLabelBuilder,
									nameBuilder: nameBuilder,
									onChanged: (value) => setState(() => to = value),
								),
							],
						),
						actions: [
							TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Скасувати')),
							FilledButton(
								onPressed: from == to
										? null
										: () => Navigator.of(context).pop(
													QuickPair(
														id: '${from.toLowerCase()}-${to.toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}',
														from: from,
														to: to,
													),
												),
								child: const Text('Додати'),
							),
						],
					);
				},
			);
		},
	);
}

Future<WalletCategory?> showCategoryDialog(
	BuildContext context, {
	required TransactionKind kind,
	WalletCategory? initial,
}) async {
	return showDialog<WalletCategory>(
		context: context,
		useRootNavigator: false,
		builder: (context) => _CategoryDialog(kind: kind, initial: initial),
	);
}

class _CategoryDialog extends StatefulWidget {
	const _CategoryDialog({required this.kind, this.initial});

	final TransactionKind kind;
	final WalletCategory? initial;

	@override
	State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
	late final List<CategoryPreset> _presets = presetsForCategoryKind(widget.kind);
	late final TextEditingController _nameController = TextEditingController(text: widget.initial?.name ?? '');
	late CategoryPreset _selectedPreset = _presets.firstWhere(
		(preset) => preset.icon.codePoint == widget.initial?.iconCodePoint,
		orElse: () => _presets.first,
	);

	@override
	void dispose() {
		_nameController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			scrollable: true,
			insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
			title: Text(widget.initial == null ? 'Нова категорія' : 'Редагувати категорію'),
			content: ConstrainedBox(
				constraints: const BoxConstraints(maxWidth: 420),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						TextField(
							controller: _nameController,
							textInputAction: TextInputAction.done,
							decoration: const InputDecoration(hintText: 'Наприклад: Ліки'),
						),
						const SizedBox(height: 12),
						DropdownButtonFormField<CategoryPreset>(
							key: ValueKey(_selectedPreset.icon.codePoint),
							initialValue: _selectedPreset,
							isExpanded: true,
							menuMaxHeight: 320,
							decoration: const InputDecoration(),
							items: _presets
								.map(
									(preset) => DropdownMenuItem<CategoryPreset>(
										value: preset,
										child: Row(
											children: [
												Icon(preset.icon, color: preset.color),
												const SizedBox(width: 10),
												Expanded(
													child: Text(
														preset.label,
														maxLines: 1,
														overflow: TextOverflow.ellipsis,
													),
												),
											],
										),
									),
								)
								.toList(),
							onChanged: (value) {
								if (value != null) {
									setState(() => _selectedPreset = value);
								}
							},
						),
					],
				),
			),
			actions: [
				TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Назад')),
				FilledButton(
					onPressed: () {
						final name = _nameController.text.trim();
						if (name.isEmpty) {
							return;
						}
						FocusScope.of(context).unfocus();
						Navigator.of(context).pop(
							WalletCategory(
								id: widget.initial?.id ?? 'cat-${DateTime.now().microsecondsSinceEpoch}',
								name: name,
								kind: widget.kind,
								iconCodePoint: _selectedPreset.icon.codePoint,
								colorValue: _selectedPreset.color.toARGB32(),
							),
						);
					},
					child: const Text('OK'),
				),
			],
		);
	}
}