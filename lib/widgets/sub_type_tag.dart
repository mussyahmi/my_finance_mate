import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import '../extensions/string_extension.dart';

class SubTypeTag extends StatefulWidget {
  final String? subType;

  const SubTypeTag({
    super.key,
    this.subType,
  });

  @override
  State<SubTypeTag> createState() => _SubTypeTagState();
}

class _SubTypeTagState extends State<SubTypeTag> {
  AdaptiveThemeMode? _savedThemeMode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAsync(context);
  }

  Future<void> _initAsync(BuildContext context) async {
    AdaptiveThemeMode? adaptiveThemeMode = await AdaptiveTheme.getThemeMode();

    setState(() {
      _savedThemeMode = adaptiveThemeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: _getTagColor(widget.subType),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        widget.subType != null ? widget.subType!.capitalize() : 'Others',
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
        return _savedThemeMode == AdaptiveThemeMode.dark
            ? Colors.green[900]!
            : Colors.green[600]!;
      case 'wants':
        return _savedThemeMode == AdaptiveThemeMode.dark
            ? Colors.blue[900]!
            : Colors.blue[600]!;
      case 'savings':
        return _savedThemeMode == AdaptiveThemeMode.dark
            ? Colors.yellow[900]!
            : Colors.yellow[600]!;
      default:
        return _savedThemeMode == AdaptiveThemeMode.dark
            ? Colors.blueGrey[900]!
            : Colors.blueGrey[600]!;
    }
  }
}
