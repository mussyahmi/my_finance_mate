import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import '../extensions/string_extension.dart';

class Tag extends StatefulWidget {
  final String? title;
  final bool? simpleMode;

  const Tag({
    super.key,
    this.title,
    this.simpleMode,
  });

  @override
  State<Tag> createState() => _TagState();
}

class _TagState extends State<Tag> {
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
      width:
          widget.simpleMode != null && widget.simpleMode == true ? 20.0 : 50.0,
      height:
          widget.simpleMode != null && widget.simpleMode == true ? 20.0 : 20.0,
      decoration: BoxDecoration(
        color: _getBackgroundColor(widget.title),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Text(
          widget.simpleMode != null && widget.simpleMode == true
              ? widget.title != null
                  ? widget.title!.capitalize().substring(0, 1)
                  : '0'
              : widget.title != null
                  ? widget.title!.capitalize()
                  : 'Others',
          style: TextStyle(
            color: _getTextColor(widget.title),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(String? title) {
    switch (title) {
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
      case 'active':
        return Colors.green[100]!;
      case 'expired':
        return Colors.red[100]!;
      default:
        return _savedThemeMode == AdaptiveThemeMode.dark
            ? Colors.blueGrey[900]!
            : Colors.blueGrey[600]!;
    }
  }

  Color _getTextColor(String? title) {
    switch (title) {
      case 'active':
        return Colors.green[900]!;
      case 'expired':
        return Colors.red[900]!;
      default:
        return Colors.white;
    }
  }
}
