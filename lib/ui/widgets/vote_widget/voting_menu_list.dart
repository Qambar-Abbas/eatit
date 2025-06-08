import 'package:flutter/material.dart';

class VotingMenuList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String selectedItem;
  final void Function(String) onItemSelected;
  final double? height;

  const VotingMenuList({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onItemSelected,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height != null ? height! * 0.3 : 200),
      child: ListView(
        children: items.map((item) {
          final name = item['name'];
          return InkWell(
            onTap: () => onItemSelected(name),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: name == selectedItem ? Colors.blue.shade100 : null,
              child: Text(name, style: Theme.of(context).textTheme.bodyLarge),
            ),
          );
        }).toList(),
      ),
    );
  }
}
