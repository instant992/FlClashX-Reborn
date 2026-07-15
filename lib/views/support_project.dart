import 'package:flclashx/common/common.dart';
import 'package:flclashx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SupportProjectView extends StatelessWidget {
  const SupportProjectView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    return BaseScaffold(
      title: l.supportProject,
      body: Padding(
        padding: kMaterialListPadding.copyWith(top: 16, bottom: 16),
        child: generateListView(
          [
            ...generateSection(
              title: l.supportProject,
              items: [
                ListItem(
                  leading: const Icon(Icons.favorite),
                  title: Text(l.supportProjectTip),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...generateSection(
              title: l.cardNumber,
              items: [
                _CardFieldItem(
                  label: l.cardNumber,
                  value: '4242 4242 4242 4242',
                ),
                _CardFieldItem(
                  label: l.cardholderName,
                  value: 'INSTANT NINE',
                ),
                _CardFieldItem(
                  label: l.expiryDate,
                  value: '12/30',
                ),
                _CardFieldItem(
                  label: l.cvv,
                  value: '•••',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFieldItem extends StatelessWidget {
  final String label;
  final String value;

  const _CardFieldItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListItem(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontFamily: 'JetBrainsMono',
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!context.mounted) return;
              context.showNotifier(context.appLocalizations.copied);
            },
          ),
        ],
      ),
    );
  }
}
