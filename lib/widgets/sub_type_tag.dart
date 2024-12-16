import 'package:flutter/material.dart';
import '../extensions/string_extension.dart';

class SubTypeTag extends StatelessWidget {
  final String? subType;

  const SubTypeTag({
    super.key,
    this.subType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: _getTagColor(subType),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        subType != null ? subType!.capitalize() : 'Others',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getTagColor(String? subType) {
    switch (subType) {
      case 'needs':
        return Colors.green[900]!;
      case 'wants':
        return Colors.blue[900]!;
      case 'savings':
        return Colors.yellow[900]!;
      default:
        return Colors.blueGrey[900]!;
    }
  }
}
