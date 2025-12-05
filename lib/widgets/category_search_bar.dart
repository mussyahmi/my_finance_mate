import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/cycle.dart';

class CategorySearchBar extends StatefulWidget {
  const CategorySearchBar({
    super.key,
    required this.cycle,
    required this.searchController,
    required this.searchQueryNotifier,
  });

  final Cycle cycle;
  final TextEditingController searchController;
  final ValueNotifier<String> searchQueryNotifier;

  @override
  State<CategorySearchBar> createState() => _CategorySearchBarState();
}

class _CategorySearchBarState extends State<CategorySearchBar> {
  late String _currentText;

  @override
  void initState() {
    super.initState();
    _currentText = widget.searchController.text;
    widget.searchController.addListener(_updateText);
  }

  void _updateText() {
    setState(() {
      _currentText = widget.searchController.text;
    });
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_updateText);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: EdgeInsets.only(
          left: 16,
          top: 16,
          right: widget.cycle.isLastCycle ? 90 : 16,
          bottom: 16),
      child: TextField(
        controller: widget.searchController,
        decoration: InputDecoration(
          hintText: 'Search categories...',
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: const Icon(CupertinoIcons.clear_circled),
            style: IconButton.styleFrom(
              foregroundColor: _currentText.isEmpty ? Colors.transparent : null,
            ),
            onPressed: () {
              widget.searchController.clear();
              widget.searchQueryNotifier.value = '';
            },
          ),
        ),
        style: const TextStyle(fontSize: 16),
        textAlignVertical: TextAlignVertical.center,
        textAlign: TextAlign.start,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          widget.searchQueryNotifier.value = value;
        },
      ),
    );
  }
}
